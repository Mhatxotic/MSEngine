/* == PCM.HPP ============================================================== **
** ######################################################################### **
** ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## **
** ######################################################################### **
** ## This module defines a class that can load sound files and then      ## **
** ## can optionally be sent to openal for playback.                      ## **
** ######################################################################### **
** ========================================================================= */
#pragma once                           // Only one incursion allowed
/* ------------------------------------------------------------------------- */
namespace IPcm {                       // Start of private module namespace
/* -- Dependencies --------------------------------------------------------- */
using namespace IAsset::P;             using namespace IASync::P;
using namespace ICollector::P;         using namespace IError::P;
using namespace IEvtMain::P;           using namespace IFileMap::P;
using namespace IIdent::P;             using namespace ILuaUtil::P;
using namespace IMemory::P;            using namespace IPcmFormat::P;
using namespace IPcmLib::P;            using namespace IStd::P;
using namespace ISysUtil::P;
/* ------------------------------------------------------------------------- */
namespace P {                          // Start of public module namespace
/* == Pcm collector and member class ======================================= */
CTOR_BEGIN_ASYNC_DUO(Pcms, Pcm, CLHelperUnsafe, ICHelperUnsafe),
  /* -- Base classes ------------------------------------------------------- */
  public Ident,                        // Pcm file name
  public AsyncLoaderPcm,               // For loading Pcm's off main-thread
  public Lockable,                     // Lua garbage collector instruction
  public PcmData                       // Pcm data
{ /* -- Split a stereo waveform into two seperate channels --------- */ public:
  void Split(void)
  { // If pcm data only is single channel, we don't need to split channels.
    if(GetChannels() == 1) return;
    // If the right channel was already filled then we don't need to do it
    if(!aPcmR.MemIsEmpty()) return;
    // Move pcm file data to a temporary array
    const Memory aTemp{ StdMove(aPcmL) };
    // Initialise buffers, half the size since we're only splitting
    aPcmL.MemInitBlank(aTemp.MemSize()/2);
    aPcmR.MemInitBlank(aPcmL.MemSize());
    // Iterate through the samples
    for(size_t stIndex = 0,
               stSubIndex = 0,
               stBytes = GetBytes(),
               stStep = GetChannels() * stBytes;
               stIndex < aTemp.MemSize();
               stIndex += stStep,
               stSubIndex += stBytes)
    { // De-interleave into seperate channels
      aPcmL.MemWrite(stSubIndex, aTemp.MemRead(stIndex, stBytes), stBytes);
      aPcmR.MemWrite(stSubIndex, aTemp.MemRead(stIndex + stBytes, stBytes),
        stBytes);
    }
  }
  /* -- Split a stereo waveform and set allocation size -------------------- */
  void SplitAndSetAlloc(void)
  { // Split audio into two channels if audio in stereo
    Split();
    // Set allocated size
    SetAlloc(aPcmL.MemSize() + aPcmR.MemSize());
  }
  /* -- Load sample from memory -------------------------------------------- */
  void AsyncReady(FileMap &fmData)
  { // Force load a certain type of audio (for speed?) but in Async mode,
    // force detection doesn't really matter as much, but overall, still
    // needed if speed is absolutely neccesary.
    if     (FlagIsSet(PL_FCE_WAV)) PcmLoadFile(PFMT_WAV, fmData, *this);
    else if(FlagIsSet(PL_FCE_CAF)) PcmLoadFile(PFMT_CAF, fmData, *this);
    else if(FlagIsSet(PL_FCE_OGG)) PcmLoadFile(PFMT_OGG, fmData, *this);
    else if(FlagIsSet(PL_FCE_MP3)) PcmLoadFile(PFMT_MP3, fmData, *this);
    // Auto detection of pcm audio
    else PcmLoadFile(fmData, *this);
    // Split into two channels if audio in stereo
    SplitAndSetAlloc();
  }
  /* -- Reload data -------------------------------------------------------- */
  void ReloadData(void)
  { // Load the file from disk or archive
    FileMap fmData{ AssetExtract(IdentGet()) };
    // Reset memory usage to zero
    SetAlloc(0);
    // Run codecs and filters on it
    AsyncReady(fmData);
  }
  /* -- Load pcm from memory asynchronously -------------------------------- */
  void InitAsyncArray(lua_State*const lS)
  { // Need 6 parameters (class pointer was already pushed onto the stack);
    LuaUtilCheckParams(lS, 7);
    // Get and check parameters
    const string strFile{ LuaUtilGetCppStrNE(lS, 1, "Identifier") };
    Asset &mbSrc = *LuaUtilGetPtr<Asset>(lS, 2, "Asset");
    FlagReset(LuaUtilGetFlags(lS, 3, PL_MASK, "Flags"));
    LuaUtilCheckFuncs(lS, 4, "ErrorFunc", 5, "ProgressFunc", 6, "SuccessFunc");
    // Is dynamic because it was not loaded from disk
    SetDynamic();
    // Load sample from memory asynchronously
    AsyncInitArray(lS, strFile, "pcmarray", StdMove(mbSrc));
  }
  /* -- Load pcm from file asynchronously ---------------------------------- */
  void InitAsyncFile(lua_State*const lS)
  { // Need 5 parameters (class pointer was already pushed onto the stack);
    LuaUtilCheckParams(lS, 6);
    // Get and check parameters
    const string strFile{ LuaUtilGetCppFile(lS, 1, "File") };
    FlagReset(LuaUtilGetFlags(lS, 2, PL_MASK, "Flags"));
    LuaUtilCheckFuncs(lS, 3, "ErrorFunc", 4, "ProgressFunc", 5, "SuccessFunc");
    // Load sample from file asynchronously
    AsyncInitFile(lS, strFile, "pcmfile");
  }
  /* -- Init from file ----------------------------------------------------- */
  void InitFile(const string &strFile, const PcmFlagsConst &pfcFlags)
  { // Set the loading flags
    FlagReset(pfcFlags);
    // Load the file normally
    SyncInitFileSafe(strFile);
  }
  /* -- Init from array ---------------------------------------------------- */
  void InitArray(const string &strName, Memory &&mbSrc,
    const PcmFlagsConst &pfcFlags)
  { // Is dynamic because it was not loaded from disk
    SetDynamic();
    // Set the loading flags
    FlagReset(pfcFlags);
    // Load the array normally
    SyncInitArray(strName, StdMove(mbSrc));
  }
  /* -- Load audio file from raw memory ------------------------------------ */
  void InitRaw(const string &strName, Memory &&mbSrc,
    const unsigned int uiNRate, const PcmChannelType pctNChannels,
    const PcmBitType pbtNBits)
  { // Calculate actual memory size required for raw data
    const size_t stExpected = uiNRate * pctNChannels * pbtNBits;
    if(mbSrc.MemSize() != stExpected)
      XC("Expected size versus actual size mismatch!",
         "Identifier", strName,      "Rate",   uiNRate,
         "Channels",   pctNChannels, "Bits",   pbtNBits,
         "Expected",   stExpected,   "Actual", mbSrc.MemSize());
    // Set members
    IdentSet(strName);
    SetDynamic();
    aPcmL.MemSwap(StdMove(mbSrc));
    SetRate(uiNRate);
    SetChannels(pctNChannels);
    SetBits(pbtNBits);
    // Check that format is supported in OpenAL
    if(!ParseOALFormat())
      XC("Format not supported by audio driver!",
         "Identifier", IdentGet(),
         "Channels",   GetChannels(), "Bits", GetBits());
    // Split audio into two channels if audio in stereo
    SplitAndSetAlloc();
    // Load succeeded so register the block
    CollectorRegister();
  }
  /* ----------------------------------------------------------------------- */
  void SwapPcm(Pcm &pcmRef)
  { // Swap datas
    IdentSwap(pcmRef);
    LockSwap(pcmRef);
    CollectorSwapRegistration(pcmRef);
    PcmDataSwap(pcmRef);
  }
  /* -- Constructor -------------------------------------------------------- */
  Pcm(void) :                          // Default onstructor
    /* -- Initialisers ----------------------------------------------------- */
    ICHelperPcm{ cPcms },              // Initially unregistered
    IdentCSlave{ cParent->CtrNext() }, // Initialise identification number
    AsyncLoaderPcm{ *this, this,       // Setup async loader with this class
      EMC_MP_PCM }                     // ...and the event id for this class
    /* -- No code ---------------------------------------------------------- */
    { }
  /* -- Constructor -------------------------------------------------------- */
  Pcm(                                 // Constructor to MOVE from other object
    /* -- Parameters ------------------------------------------------------- */
    Pcm &&pcmOther                     // Other Pcm reference to swap with
    ): /* -- Initialisation of members ------------------------------------- */
    Pcm()                              // Default initialisation of members
    /* -- Swap members with other class ------------------------------------ */
    { SwapPcm(pcmOther); }
  /* -- Destructor (override) ---------------------------------------------- */
  ~Pcm(void) { AsyncCancel(); }
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(Pcm)                 // Disable copy constructor and operator
};/* -- End-of-collector --------------------------------------------------- */
CTOR_END_ASYNC_NOFUNCS(Pcms, PCM)      // Finish collector class
/* ------------------------------------------------------------------------- */
}                                      // End of public module namespace
/* ------------------------------------------------------------------------- */
}                                      // End of private module namespace
/* == EoF =========================================================== EoF == */

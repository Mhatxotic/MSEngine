/* == OAL.HPP ============================================================== */
/* ######################################################################### */
/* ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## */
/* ######################################################################### */
/* ## Because OpenAL is LGPL, we're not really allowed to statically link ## */
/* ## OpenAL libraries, however, there is a technical workaround that we  ## */
/* ## can still use the static lib if we provide a facility to load if an ## */
/* ## external version of OpenAL.dll is available. So thats why this      ## */
/* ## class exists, so we can create a pointer to all the functions we    ## */
/* ## will use in AL and switch between them.                             ## */
/* ######################################################################### */
/* ========================================================================= */
#pragma once                           // Only one incursion allowed
/* ------------------------------------------------------------------------- */
namespace IfOal {                      // Start of module namespace
/* -- Includes ------------------------------------------------------------- */
using namespace Lib::OpenAL;           // Using openal library functions
using namespace IfFlags;               // Using flags namespace
using namespace IfIdent;               // Using identification namespace
using namespace IfLog;                 // Using logging namespace
using namespace IfMemory;              // Using memory namespace
/* -- GL error checking wrapper macros ------------------------------------- */
#define ALEX(EF,F,M,...)  { F; EF(M, ## __VA_ARGS__); }
#define ALL(F,M,...)      ALEX(cOal->CheckLogError, F, M, ## __VA_ARGS__)
#define AL(F,M,...)       ALEX(cOal->CheckExceptError, F, M, ## __VA_ARGS__)
#define ALC(M,...)        ALEX(cOal->CheckExceptError, , M, ## __VA_ARGS__)
/* -- Typedefs ------------------------------------------------------------- */
typedef vector<ALuint>   ALUIntVector; // A vector of ALuint's
/* -- OpenAL flags---------------------------------------------------------- */
BUILD_FLAGS(Oal,
  /* --------------------------------------------------------------------- */
  // No flags                          Device has been initialised?
  AFL_NONE               {0x00000000}, AFL_INITDEVICE         {0x00000004},
  // Context has been initialised?     Device was reset to set parameters
  AFL_INITCONTEXT        {0x00000008}, AFL_INITRESET          {0x00000010},
  // Context has been made current?    OpenAL fully initialised
  AFL_CONTEXTCURRENT     {0x00000020}, AFL_INITIALISED        {0x00000040},
  // Can play 32-bit float audio?      Have ALC_ENUMERATE_ALL_EXT?
  AFL_HAVE32FPPB         {0x00000080}, AFL_HAVEENUMEXT        {0x00000100},
  // Have infinite sources?
  AFL_INFINITESOURCES    {0x00000200}
);/* == Oal class ========================================================== */
static class Oal final :
  /* -- Base classes ------------------------------------------------------- */
  public OalFlags                      // OpenAL flags
{ /* -- Defines ------------------------------------------------------------ */
#define IAL(F,M,...) ALEX(CheckExceptError, F, M, ## __VA_ARGS__)
#define IALC(M,...) ALEX(CheckExceptError, , M, ## __VA_ARGS__)
  /* ----------------------------------------------------------------------- */
  const IdMap<ALenum> imOALCodes;      // OpenAL codes
  const IdMap<>       imOGGCodes;      // Ogg codes
  /* ----------------------------------------------------------------------- */
  ALuint           uiMaxStereoSources; // Maximum number of stereo sources
  ALuint           uiMaxMonoSources;   // Maximum number of mono sources
  /* ----------------------------------------------------------------------- */
  ALCdevice       *alcDevice;          // OpenAL device
  ALCcontext      *alcContext;         // OpenAL context
  /* -- Public Variables ------------------------------------------- */ public:
  ALenum           eQuery;             // Device query extension
  /* -- DeInitialise (private from destructor) -------------------- */ private:
  void DoDeInit(void)
  { // De-initialising
    SetInitialised(false);
    // De-init context and device if they're not gone already. The audio
    // class should be responsible for this, but just incase.
    DeInitContext();
    DeInitDevice();
  }
  /* -- Return error status ---------------------------------------- */ public:
  ALenum GetError(void) const { return alGetError(); }
  bool HaveError(void) const { return GetError() != AL_NO_ERROR; }
  bool HaveNoError(void) const { return !HaveError(); }
  /* -- AL error logger ---------------------------------------------------- */
  template<typename ...Args>
    void CheckLogError(const char*const cpFormat, const Args... vaArgs) const
  { // While there are OpenAL errors
    for(ALenum alError = alGetError();
               alError != AL_NO_ERROR;
               alError = alGetError())
    cLog->LogWarningExSafe("AL call failed: $ ($/$$).",
      Format(cpFormat, vaArgs...), GetALErr(alError), hex, alError);
  }
  /* -- AL error handler --------------------------------------------------- */
  template<typename ...Args>
    void CheckExceptError(const char*const cpFormat,
      const Args... vaArgs) const
  { // If there is no error then return
    const ALenum alError = alGetError();
    if(alError == GL_NO_ERROR) return;
    // Raise exception with error details
    XC(cpFormat, "Code", alError, "Reason", GetALErr(alError), vaArgs...);
  }
  /* -- Upload data to audio device ---------------------------------------- */
  void BufferData(const ALuint uiBuffer, const ALenum eFormat,
    const ALvoid*const vpData, const ALsizei stSize, const ALsizei stFrequency)
      { alBufferData(uiBuffer, eFormat, vpData, stSize, stFrequency); }
  /* -- Upload data to audio device ---------------------------------------- */
  void BufferData(const ALuint uiBuffer, const ALenum eFormat,
    const DataConst &dcData, const ALsizei stFrequency)
      { BufferData(uiBuffer, eFormat, dcData.Ptr<ALvoid>(),
          dcData.Size<ALsizei>(), stFrequency); }
  /* -- Queue specified buffer count into source --------------------------- */
  void QueueBuffers(const ALuint uiSource,
    const ALsizei stCount, ALuint*const uipBuffer) const
      { alSourceQueueBuffers(uiSource, stCount, uipBuffer); }
  /* -- Queue one buffer count into source --------------------------------- */
  void QueueBuffer(const ALuint uiSource, ALuint uiBuffer) const
    { QueueBuffers(uiSource, 1, &uiBuffer); }
  /* -- Unqueue specified buffer count from source and place into buffers -- */
  void UnQueueBuffers(const ALuint uiSource,
    const ALsizei stCount, ALuint*const uipBuffer) const
      { alSourceUnqueueBuffers(uiSource, stCount, uipBuffer); }
  /* -- Unqueue one buffer from source and place into buffers -------------- */
  void UnQueueBuffer(const ALuint uiSource, ALuint &uiBuffer) const
    { UnQueueBuffers(uiSource, 1, &uiBuffer); }
  /* -- Unqueue one buffer from source and return it ----------------------- */
  ALuint UnQueueBuffer(const ALuint uiSource) const
    { ALuint uiBuffer; UnQueueBuffer(uiSource, uiBuffer); return uiBuffer; }
  /* -- Set source value as float ------------------------------------------ */
  void SetSourceFloat(const ALuint uiSource, const ALenum eWhat,
    const ALfloat fValue) const
      { alSourcef(uiSource, eWhat, fValue); }
  /* -- Get source value as float ------------------------------------------ */
  void GetSourceFloat(const ALuint uiSource, const ALenum eWhat,
    ALfloat *fDestValue) const
      { alGetSourcef(uiSource, eWhat, fDestValue); }
  /* -- Set source value as int -------------------------------------------- */
  void SetSourceInt(const ALuint uiSource, const ALenum eWhat,
    const ALint iValue) const
      { alSourcei(uiSource, eWhat, iValue); }
  /* -- Get source value as int -------------------------------------------- */
  void GetSourceInt(const ALuint uiSource, const ALenum eWhat,
    ALint *iDestValue) const
      { alGetSourcei(uiSource, eWhat, iDestValue); }
  /* -- Get source value as a float vector --------------------------------- */
  void GetSourceVector(const ALuint uiSource, const ALenum eWhat,
    ALfloat *fDX, ALfloat *fDY, ALfloat *fDZ) const
      { alGetSource3f(uiSource, eWhat, fDX, fDY, fDZ); }
  /* -- Set source value as a float vector --------------------------------- */
  void SetSourceVector(const ALuint uiSource, const ALenum eWhat,
    const ALfloat fDX, const ALfloat fDY, const ALfloat fDZ) const
      { alSource3f(uiSource, eWhat, fDX, fDY, fDZ); }
  /* -- Stop a source from playing ----------------------------------------- */
  void StopSource(const ALuint uiSource) const
    { alSourceStop(uiSource); }
  /* -- Play a source ------------------------------------------------------ */
  void PlaySource(const ALuint uiSource) const
    { alSourcePlay(uiSource); }
  /* -- Play more than one source simultaniously --------------------------- */
  template<class ArrayType>void PlaySources(const ArrayType &atArray)
    { alSourcePlayv(static_cast<ALsizei>(atArray.size()), atArray.data()); }
  /* -- Create multiple sources -------------------------------------------- */
  void CreateSources(const ALsizei stCount, ALuint*const uipSource) const
    { alGenSources(stCount, uipSource); }
  /* -- Create one source and place it in the specified buffer ------------- */
  void CreateSource(ALuint &uiSourceRef) const
    { CreateSources(1, &uiSourceRef); }
  /* -- Create and return a source ----------------------------------------- */
  ALuint CreateSource(void) const
    { ALuint uiSource; CreateSource(uiSource); return uiSource; }
  /* -- Delete multiple sources -------------------------------------------- */
  void DeleteSources(const ALsizei stCount, ALuint*const uipSource) const
    { alDeleteSources(stCount, uipSource); }
  /* -- Delete multiple sources -------------------------------------------- */
  template<class List>void DeleteSources(List &tList) const
    { DeleteSources(static_cast<ALsizei>(tList.size()), tList.data()); }
  /* -- Delete one source -------------------------------------------------- */
  void DeleteSource(ALuint &uiSourceRef) const
    { DeleteSources(1, &uiSourceRef); }
  /* -- Create multiple buffers -------------------------------------------- */
  void CreateBuffers(const ALsizei stCount, ALuint*const uipBuffer) const
    { alGenBuffers(stCount, uipBuffer); }
  /* -- Create multiple buffers -------------------------------------------- */
  template<class List>void CreateBuffers(List &tList) const
    { CreateBuffers(static_cast<ALsizei>(tList.size()), tList.data()); }
  /* -- Create one buffer and place it in the specified variable ----------- */
  void CreateBuffer(ALuint &uiBuffer) const
    { CreateBuffers(1, &uiBuffer); }
  /* -- Create and return a buffer ----------------------------------------- */
  ALuint CreateBuffer(void) const
    { ALuint uiBuffer; CreateBuffer(uiBuffer); return uiBuffer; }
  /* -- Delete multiple buffers -------------------------------------------- */
  void DeleteBuffers(const ALsizei stCount, ALuint*const uipBuffer) const
    { alDeleteBuffers(stCount, uipBuffer); }
  /* -- Delete multiple sources -------------------------------------------- */
  template<class List>void DeleteBuffers(List &tList) const
    { DeleteBuffers(static_cast<ALsizei>(tList.size()), tList.data()); }
  /* -- Delete one buffer -------------------------------------------------- */
  void DeleteBuffer(ALuint &uiBufferRef) const
    { DeleteBuffers(1, &uiBufferRef); }
  /* -- Get buffer parameter as integer ------------------------------------ */
  void GetBufferInt(const ALuint uiBId, const ALenum eId, ALint *iDest) const
    { alGetBufferi(uiBId, eId, iDest); }
  /* -- Get buffer information --------------------------------------------- */
  template<typename IntType=ALint>
    IntType GetBufferInt(const ALuint uiBId, const ALenum eId) const
      { ALint iV; GetBufferInt(uiBId, eId, &iV);
        return static_cast<IntType>(iV); }
  /* -- Set distance model ------------------------------------------------- */
  void SetDistanceModel(const ALenum eModel) const
    { alDistanceModel(eModel); }
  /* -- Set listener vector ------------------------------------------------ */
  void SetListenerVector(const ALenum eParam, const ALfloat fX,
    const ALfloat fY, const ALfloat fZ) const
      { alListener3f(eParam, fX, fY, fZ); }
  /* -- Set listener position ---------------------------------------------- */
  void SetListenerPosition(const ALfloat fX, const ALfloat fY,
    const ALfloat fZ) const
      { SetListenerVector(AL_POSITION, fX, fY, fZ); }
  /* -- Set listener velocity ---------------------------------------------- */
  void SetListenerVelocity(const ALfloat fX, const ALfloat fY,
    const ALfloat fZ) const
      { SetListenerVector(AL_VELOCITY, fX, fY, fZ); }
  /* -- Set listener velocity ---------------------------------------------- */
  void SetListenerVectors(const ALenum eParam, const ALfloat *fpVectors) const
    { alListenerfv(eParam, fpVectors); }
  /* -- Set listener orientation ------------------------------------------- */
  void SetListenerOrientation(const ALfloat *fpVectors) const
    { SetListenerVectors(AL_ORIENTATION, fpVectors); }
  /* -- Is extension present ----------------------------------------------- */
  bool HaveExtension(const char*const cpEnum) const
    { return alIsExtensionPresent(cpEnum) != AL_FALSE; }
  bool HaveCExtension(const char*const cpEnum, ALCdevice*const alcDev) const
    { return alcIsExtensionPresent(alcDev, cpEnum) != AL_FALSE; }
  bool HaveCExtension(const char*const cpEnum) const
    { return HaveCExtension(cpEnum, alcDevice); }
  bool HaveNCExtension(const char*const cpEnum) const
    { return HaveCExtension(cpEnum, nullptr); }
  /* -- Detect enumeration method ------------------------------------------ */
  void DetectEnumerationMethod(void)
  { // Get if we have ALC_ENUMERATE_ALL_EXT
    if(HaveNCExtension("ALC_ENUMERATE_ALL_EXT"))
    { // Set that we have the extension
      FlagSet(AFL_HAVEENUMEXT);
      // Set extended device query extension
      eQuery = ALC_ALL_DEVICES_SPECIFIER;
    } // Set standarded device query extension
    else eQuery = ALC_DEVICE_SPECIFIER;
  }
  /* == Convert bitrate and channels to an openal useful identifier ======== */
  static bool GetOALType(const ALuint uiChannels, const ALuint uiBits,
    ALenum &eFormat, ALenum &eSFormat)
  { // Compare channels
    switch(uiChannels)
    { // MONO: 1 channel
      case 1:
      { // Compare bit count
        switch(uiBits)
        { // 8-bits per sample (Integer)
          case  8: eFormat = eSFormat = AL_FORMAT_MONO8; return true;
          // 16-bits per sample (Integer)
          case 16: eFormat = eSFormat = AL_FORMAT_MONO16; return true;
          // 32-bits per sample (Float)
          case 32: eFormat = eSFormat = AL_FORMAT_MONO_FLOAT32; return true;
          // Unknown
          default: return false;
        }
      } // STEREO: 2 channels
      case 2:
      { // Compare bit count
        switch(uiBits)
        { // 8-bits per sample (Integer)
          case  8: eFormat = AL_FORMAT_STEREO8;
                   eSFormat = AL_FORMAT_MONO8;
                   return true;
          // 16-bits per sample (Integer)
          case 16: eFormat = AL_FORMAT_STEREO16;
                   eSFormat = AL_FORMAT_MONO16;
                   return true;
          // 32-bits per sample (Float)
          case 32: eFormat = AL_FORMAT_STEREO_FLOAT32;
                   eSFormat = AL_FORMAT_MONO_FLOAT32;
                   return true;
          // Unknown
          default: return false;
        }
      } // Unknown
      default: return false;
    }
  }
  /* -- Report floating point playback to other classes -------------------- */
  bool Have32FPPB(void) const { return FlagIsSet(AFL_HAVE32FPPB); }
  /* -- Get openAL string -------------------------------------------------- */
  template<typename T=ALchar>const T*GetString(const ALenum eId) const
  { // Get the variable and throw error if occured
    const ALchar*const ucpStr = alGetString(eId);
    IALC("Get string failed!", "Index", eId);
    // Sanity check actual string
    if(!ucpStr || !*ucpStr)
      XC("Invalid string returned!", "Index", eId, "String", ucpStr);
    // Return result
    return reinterpret_cast<const T*>(ucpStr);
  }
  /* -- Get context openAL string ------------------------------------------ */
  template<typename T=ALchar>const T*GetCString(ALCdevice*const alcDev,
    const ALenum eId) const
  { // Get the variable and throw error if occured
    const ALchar*const ucpStr = alcGetString(alcDev, eId);
    IALC("Get context string failed!", "Context", !!alcDev, "Index", eId);
    // Sanity check actual string
    if(!ucpStr || !*ucpStr)
      XC("Invalid context string returned!", "Index", eId, "String", ucpStr);
    // Return result
    return reinterpret_cast<const T*>(ucpStr);
  }
  /* -- Get context openAL string ------------------------------------------ */
  template<typename T=ALchar>const T*GetCString(const ALenum eId) const
    { return GetCString<T>(alcDevice, eId); }
  /* -- Get nullptr context openAL string ---------------------------------- */
  template<typename T=ALchar>const T*GetNCString(const ALenum eId) const
    { return reinterpret_cast<const T*>(alcGetString(nullptr, eId)); }
  /* -- Get openAL int array ----------------------------------------------- */
  template<size_t stCount, class A=array<ALCint,stCount>>
    const A GetIntegerArray(const ALenum eId) const
  { // Create array to return
    A aData;
    // Get specified value for enum and store it
    IAL(alcGetIntegerv(alcDevice, eId, sizeof(A), aData.data()),
      "Get integer array failed!", "Index", eId, "Count", stCount);
    // Return array
    return aData;
  }
  /* -- Get openAL int ----------------------------------------------------- */
  template<typename T=ALCint>T GetInteger(const ALenum eId) const
    { return static_cast<T>(GetIntegerArray<1>(eId)[0]); }
  /* -- Convert PCM format identifier to short identifier string ----------- */
  const string GetALFormat(const ALenum eFormat) const
  { // Compare format
    switch(eFormat)
    { case AL_FORMAT_STEREO_FLOAT32 : return "SF32"; // 32-Bit Float Stereo
      case AL_FORMAT_MONO_FLOAT32   : return "MF32"; // 32-Bit Float Mono
      case AL_FORMAT_MONO16         : return "MI16"; // 16-Bit Integer Mono
      case AL_FORMAT_STEREO16       : return "SI16"; // 16-Bit Integer Stereo
      case AL_FORMAT_MONO8          : return "MI08"; // 8-Bit Integer Mono
      case AL_FORMAT_STEREO8        : return "SI08"; // 8-Bit Integer Stereo
      default                       : return ToHex(eFormat, 4); // Unknown
    }
  }
  /* -- Get source counts -------------------------------------------------- */
  ALuint GetMaxMonoSources(void) const { return uiMaxMonoSources; }
  ALuint GetMaxStereoSources(void) const { return uiMaxStereoSources; }
  /* -- Get current playback device ---------------------------------------- */
  const char *GetPlaybackDevice(void) const
  { // Bail if no device
    if(!alcDevice) return "<Not Initialised>";
    // Appropriate extension available? Return device name
    return GetCString(HaveCExtension("ALC_ENUMERATE_ALL_EXT") != AL_FALSE ?
      ALC_ALL_DEVICES_SPECIFIER : ALC_DEVICE_SPECIFIER);
  }
  /* -- Return version information --------------------------------- */ public:
  const string GetVersion(void) const
    { return Append(GetInteger(ALC_MAJOR_VERSION), '.',
                    GetInteger(ALC_MINOR_VERSION)); }
  /* -- Load AL capabilities ----------------------------------------------- */
  void DetectCapabilities(void)
  { // Set if we have 32-bit floating-point playback
    if(alIsExtensionPresent("AL_EXT_FLOAT32")) FlagSet(AFL_HAVE32FPPB);
    else FlagClear(AFL_HAVE32FPPB);
    // Get maximum number of sources (dynamic on Apple implementation).
    uiMaxMonoSources =
      GetInteger<decltype(uiMaxMonoSources)>(ALC_MONO_SOURCES);
    uiMaxStereoSources =
      GetInteger<decltype(uiMaxStereoSources)>(ALC_STEREO_SOURCES);
    // Zero mono sources?
    if(!uiMaxMonoSources)
    { // Zero stereo sources?
      if(!uiMaxStereoSources)
      { // Set infinite sources flag
        FlagSet(AFL_INFINITESOURCES);
        // Set arbitrary amounts
        uiMaxMonoSources = 255;
        uiMaxStereoSources = 1;
      } // Failed because no stereo sources
      else XC("No mono source support on this device!");
    } // Zero stereo sources? Failed because no mono sources
    else if(!uiMaxStereoSources)
      XC("No stereo source support on this device!");
  }
  /* --------------------------------------------------------------- */ public:
  template<typename IntType>const string &GetOggErr(const IntType itCode) const
    { return imOGGCodes.Get(static_cast<unsigned int>(itCode)); }
  /* ----------------------------------------------------------------------- */
  template<typename IntType>const string &GetALErr(const IntType itCode) const
    { return imOALCodes.Get(static_cast<ALenum>(itCode)); }
  /* -- AL is initialised? ------------------------------------------------- */
  bool IsInitialised(void) const { return alcDevice && alcContext; }
  void SetInitialised(const bool bS)
  { // Sanity checks. Make sure we don't init when initialised and vice versa
    if(bS && FlagIsSet(AFL_INITIALISED)) XC("AL was already initialised!");
    else if(!bS && FlagIsClear(AFL_INITIALISED)) return;
    // Deinitialised?
    if(!bS)
    { // Log as de-initialised
      cLog->LogInfoSafe("OAL set to de-initialised.");
      // Return cleared flag
      return FlagClear(AFL_INITIALISED);
    } // Detect capabilities
    DetectCapabilities();
    // Show change in state
    cLog->LogInfoExSafe("OAL version $ initialised with capabilities 0x$$...\n"
                "- Device: $.",
      GetVersion(), hex, FlagGet(), GetPlaybackDevice());
    // Set the flag
    FlagSet(AFL_INITIALISED);
    // Return if debug logging not enabled
    if(!cLog->HasLevel(LH_DEBUG)) return;
    // Build extensions list
    const Token tlExtensions{ GetString(AL_EXTENSIONS), cCommon->Space() };
    // Build sorted list of extensions and log them all
    map<const string,const size_t> mExts;
    for(size_t stI = 0; stI < tlExtensions.size(); ++stI)
      mExts.insert({ StdMove(tlExtensions[stI]), stI });
    // Log device info and basic capabilities
    cLog->LogNLCDebugExSafe(
      "- Head related transfer function: $.\n"
      "- Floating-point playback: $.\n"
      "- Maximum mono sources: $.\n"
      "- Maximum stereo sources: $.\n"
      "- Have ext.device enumerator: $.\n"
      "- Extensions count: $.",
        TrueOrFalse(FlagIsClear(AFL_INITRESET)),
        TrueOrFalse(Have32FPPB()),
        uiMaxMonoSources,
        uiMaxStereoSources,
        TrueOrFalse(FlagIsSet(AFL_HAVEENUMEXT)),
        tlExtensions.size());
    // Log extensions if debug is enabled
    for(const auto &mI : mExts)
      cLog->LogNLCDebugExSafe("- Have extension '$' (#$).",
        mI.first, mI.second);
  }
  /* -- Make context current ----------------------------------------------- */
  void SetContext(void)
  { // Bail if no context or device
    if(!alcDevice || !alcContext) return;
    // Make stored context current
    alcMakeContextCurrent(alcContext);
    // Context set
    FlagSet(AFL_CONTEXTCURRENT);
  }
  /* -- Clear context ------------------------------------------------------ */
  void ClearContext(void)
  { // Clear context
    alcMakeContextCurrent(nullptr);
    // Context cleared
    FlagClear(AFL_CONTEXTCURRENT);
  }
  /* -- ReInitialise device with HRTF disabled ----------------------------- */
  bool DisableHRTF(void)
  {  // Ignore if audio is already reset
    if(FlagIsSet(AFL_INITRESET)) return true;
    // Reset with HRTF disabled
    const array<const ALCint,3> alciAttrs{ ALC_HRTF_SOFT, ALC_FALSE, 0 };
    if(alcResetDeviceSOFT(alcDevice, alciAttrs.data()) != AL_TRUE)
      return false;
    // Init reset successful
    FlagSet(AFL_INITRESET);
    // Return success
    return true;
  }
  /* -- Initialise device -------------------------------------------------- */
  bool InitDevice(const char *cpDevice)
  { // Bail if already initialised
    if(alcDevice) return false;
    // Get the device and return failure if it fails
    alcDevice = alcOpenDevice(cpDevice);
    if(!alcDevice) return false;
    FlagSet(AFL_INITDEVICE);
    // Succeeded
    return true;
  }
  /* -- DeInitialise device ------------------------------------------------ */
  bool DeInitDevice(void)
  { // Bail if no context
    if(!alcDevice) return false;
    // Close device and nullify handle
    alcCloseDevice(alcDevice);
    alcDevice = nullptr;
    // Clear flag
    FlagClear(AFL_INITDEVICE);
    // Succeeded
    return true;
  }
  /* -- Initialise context ------------------------------------------------- */
  bool InitContext(void)
  { // Bail if already initialised
    if(alcContext) return false;
    // Get the device and return failure if failed
    alcContext = alcCreateContext(alcDevice, nullptr);
    if(!alcContext) return false;
    // Set device initialised
    FlagSet(AFL_INITCONTEXT);
    // Succeeded
    return true;
  }
  /* -- DeInitialise context ----------------------------------------------- */
  bool DeInitContext(void)
  { // Bail if no context
    if(!alcContext) return false;
    // Close context
    ClearContext();
    // Destroy context and nullify handle
    alcDestroyContext(alcContext);
    alcContext = nullptr;
    // Clear flag
    FlagClear(AFL_INITCONTEXT);
    // Succeeded
    return true;
  }
  /* -- DeInitialise ------------------------------------------------------- */
  void DeInit(void)
  { // De-init context and evice
    DoDeInit();
    // Refresh variables and make the external dll flag persist
    FlagReset(AFL_NONE);
    eQuery = AL_NONE;
    uiMaxStereoSources = 0;
    uiMaxMonoSources = numeric_limits<ALuint>::max();
  }
  /* -- Destructor --------------------------------------------------------- */
  DTORHELPER(~Oal, DoDeInit())
  /* -- Constructor -------------------------------------------------------- */
  Oal(void) :
    /* -- Initialisers ----------------------------------------------------- */
    OalFlags{ AFL_NONE },
    /* -- Const members ---------------------------------------------------- */
    imOALCodes{{
      IDMAPSTR(AL_NO_ERROR),           IDMAPSTR(AL_INVALID_NAME),
      IDMAPSTR(AL_INVALID_ENUM),       IDMAPSTR(AL_INVALID_VALUE),
      IDMAPSTR(AL_INVALID_OPERATION),  IDMAPSTR(AL_OUT_OF_MEMORY)
    }, "AL_UNKNOWN" },
    imOGGCodes{{
      IDMAPSTR(OV_EOF),                IDMAPSTR(OV_HOLE),
      IDMAPSTR(OV_FALSE),              IDMAPSTR(OV_EREAD),
      IDMAPSTR(OV_EFAULT),             IDMAPSTR(OV_EIMPL),
      IDMAPSTR(OV_EINVAL),             IDMAPSTR(OV_ENOTVORBIS),
      IDMAPSTR(OV_EBADHEADER),         IDMAPSTR(OV_EVERSION),
      IDMAPSTR(OV_ENOTAUDIO),          IDMAPSTR(OV_EBADPACKET),
      IDMAPSTR(OV_EBADLINK),           IDMAPSTR(OV_ENOSEEK)
    }, "OV_UNKNOWN" },
    /* -- Initialisers ----------------------------------------------------- */
    uiMaxStereoSources(0),
    uiMaxMonoSources(numeric_limits<ALuint>::max()),
    alcDevice(nullptr),
    alcContext(nullptr),
    eQuery(AL_NONE)
    /* -- No code ---------------------------------------------------------- */
    { }
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(Oal)                 // Do not need copy constructors
  /* -- Undefines ---------------------------------------------------------- */
#undef IAL                             //  "
#undef IALC                            //  "
  /* ----------------------------------------------------------------------- */
} *cOal = nullptr;                     // Pointer to static class
/* ------------------------------------------------------------------------- */
};                                     // End of module namespace
/* == EoF =========================================================== EoF == */

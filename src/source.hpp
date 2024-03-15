/* == SOURCE.HPP =========================================================== */
/* ######################################################################### */
/* ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## */
/* ######################################################################### */
/* ## This module defines a class that can be used to play and manage     ## */
/* ## buffers in OpenAL. All sources are managed here too so we will      ## */
/* ## manage the collector list with concurrency locks instead of the     ## */
/* ## ICHelper class. The Lockable class is also used for a different     ## */
/* ## reason to all the other interfaces to stop the source from being    ## */
/* ## deleted while it is in use by the engine and not OpenAL.            ## */
/* ######################################################################### */
/* ========================================================================= */
#pragma once                           // Only one incursion allowed
/* ------------------------------------------------------------------------- */
namespace IfSource {                   // Start of module namespace
/* -- Includes ------------------------------------------------------------- */
using namespace IfOal;                 // Using oal namespace
using namespace IfLuaUtil;             // Using luautil namespace
/* -- Source collector class for collector data and custom variables ------- */
BEGIN_COLLECTOREX(Sources, Source, CLHelperSafe, /* Build collector/member   */
/* ------------------------------------------------------------------------- */
typedef atomic<ALfloat> SafeALFloat;   /* Multi-threaded AL float           */\
/* ------------------------------------------------------------------------- */
SafeALFloat        fGVolume;           /* Global volume multiplier          */\
SafeALFloat        fMVolume;           /* Stream volume multiplier          */\
SafeALFloat        fVVolume;           /* Video volume multiplier           */\
SafeALFloat        fSVolume;           /* Sample volume multiplier          */\
);/* ----------------------------------------------------------------------- */
BEGIN_MEMBERCLASS(Sources, Source, ICHelperSafe),
  /* -- Base classes ------------------------------------------------------- */
  public Lockable                      // Lua garbage collector instruction
{ /* -- Private variables -------------------------------------------------- */
  ALuint           uiId;               // Source id
  bool             bExternal;          // Ignore class in audio thread?
  /* -- Get/set source float ----------------------------------------------- */
  void SetSourceFloat(const ALenum eP, const ALfloat fV) const
    { AL(cOal->SetSourceFloat(uiId, eP, fV), "Set source float failed!",
        "Index", uiId, "Param", eP, "Value", fV); }
  ALfloat GetSourceFloat(const ALenum eP) const
  { // Make, store and return requested float parameter
    ALfloat fValue;
    AL(cOal->GetSourceFloat(uiId, eP, &fValue),
      "Get source float failed!", "Index", uiId, "Param", eP);
    return fValue;
  }
  /* -- set source integer ------------------------------------------------- */
  void SetSourceInt(const ALenum eParam, const ALint iValue) const
  { // Set the integer value and check for error
    AL(cOal->SetSourceInt(uiId, eParam, iValue),
      "Set source integer failed!",
      "Index", uiId, "Param", eParam, "Value", iValue);
  }
  /* -- Get source integer ------------------------------------------------- */
  template<typename IntType=ALint>
    const IntType GetSourceInt(const ALenum eParam) const
  { // Store result into this integer
    ALint iValue;
    // Get the value
    AL(cOal->GetSourceInt(uiId, eParam, &iValue),
      "Get source integer failed!", "Index", uiId, "Param", eParam);
    // Return casted value
    return static_cast<IntType>(iValue);
  }
  /* -- Get/set source triple-float -------------------------------- */
  void GetSource3Float(const ALenum eP,
    ALfloat &fX, ALfloat &fY, ALfloat &fZ) const
      { AL(cOal->GetSourceVector(uiId, eP, &fX, &fY, &fZ),
           "Get source vector failed!",
           "Index", uiId, "Param", eP, "X", fX, "Y", fY, "Z", fZ); }
  void SetSource3Float(const ALenum eP,
    const ALfloat fX, const ALfloat fY, const ALfloat fZ) const
      { AL(cOal->SetSourceVector(uiId, eP, fX, fY, fZ),
          "Set source vector failed!",
          "Index", uiId, "Param", eP, "X", fX, "Y", fY, "Z", fZ); }
  /* -- Reset parameters ------------------------------------------- */ public:
  void Init(void)
  { ClearBuffer();        SetPosition(0, 0, 0);
    SetVelocity(0, 0, 0); SetDirection(0, 0, 0); SetRollOff(0.0);
    SetRefDist(0.5);      SetMaxDist(1);         SetGain(1);
    SetMinGain(0);        SetMaxGain(1);         SetPitch(1);
    SetRelative(false);   SetLooping(false);
  }
  /* -- Reset parameters --------------------------------------------------- */
  void ReInit(void) { Init(); SetExternal(true); }
  /* -- Unlock a source so it can be recycled ------------------------------ */
  void Unlock(void)
  { // Clear the attached buffer
    ClearBuffer();
    // Unlock the source so it can be recycled by the audio thread
    SetExternal(false);
  }
  /* -- Get/set externally managed source ---------------------------------- */
  bool GetExternal(void) const { return bExternal; }
  void SetExternal(const bool bState) { bExternal = bState; }
  /* -- Get/set elapsed time ----------------------------------------------- */
  ALfloat GetElapsed(void) const { return GetSourceFloat(AL_SEC_OFFSET); }
  void SetElapsed(const ALfloat fSeconds) const
    { SetSourceFloat(AL_SEC_OFFSET, fSeconds); }
  /* -- Get/set gain ------------------------------------------------------- */
  ALfloat GetGain(void) const { return GetSourceFloat(AL_GAIN); }
  void SetGain(const ALfloat fGain) const { SetSourceFloat(AL_GAIN, fGain); }
  /* -- Get/set minimum gain ----------------------------------------------- */
  ALfloat GetMinGain(void) const { return GetSourceFloat(AL_MIN_GAIN); }
  void SetMinGain(const ALfloat fMinGain) const
    { SetSourceFloat(AL_MIN_GAIN, fMinGain); }
  /* -- Get/set maximum gain ----------------------------------------------- */
  ALfloat GetMaxGain(void) const { return GetSourceFloat(AL_MAX_GAIN); }
  void SetMaxGain(const ALfloat fMaxGain) const
    { SetSourceFloat(AL_MAX_GAIN, fMaxGain); }
  /* -- Get/set pitch ------------------------------------------------------ */
  ALfloat GetPitch(void) const { return GetSourceFloat(AL_PITCH); }
  void SetPitch(const ALfloat fPitch) const
    { SetSourceFloat(AL_PITCH, fPitch); }
  /* -- Get/set reference distance ----------------------------------------- */
  ALfloat GetRefDist(void) const
    { return GetSourceFloat(AL_REFERENCE_DISTANCE); }
  void SetRefDist(const ALfloat fRefDist) const
    { SetSourceFloat(AL_REFERENCE_DISTANCE, fRefDist); }
  /* -- Get/set roll off --------------------------------------------------- */
  ALfloat GetRollOff(void) const { return GetSourceFloat(AL_ROLLOFF_FACTOR); }
  void SetRollOff(const ALfloat fRollOff) const
    { SetSourceFloat(AL_ROLLOFF_FACTOR, fRollOff); }
  /* -- Get/set maximum distance ------------------------------------------- */
  ALfloat GetMaxDist(void) const
    { return GetSourceFloat(AL_MAX_DISTANCE); }
  void SetMaxDist(const ALfloat fMaxDist) const
    { SetSourceFloat(AL_MAX_DISTANCE, fMaxDist); }
  /* -- Get/set looping ---------------------------------------------------- */
  bool GetLooping(void) const
    { return GetSourceInt<ALuint>(AL_LOOPING) == AL_TRUE; }
  void SetLooping(const bool bLooping) const
    { SetSourceInt(AL_LOOPING, bLooping ? AL_TRUE : AL_FALSE); }
  /* -- Get/set relative --------------------------------------------------- */
  bool GetRelative(void) const
    { return GetSourceInt<ALuint>(AL_SOURCE_RELATIVE) == AL_TRUE; }
  void SetRelative(const ALenum bRelative) const
    { SetSourceInt(AL_SOURCE_RELATIVE, bRelative ? AL_TRUE : AL_FALSE); }
  /* -- Get/set direction -------------------------------------------------- */
  void GetDirection(ALfloat &fX, ALfloat &fY, ALfloat &fZ) const
    { GetSource3Float(AL_DIRECTION, fX, fY, fZ); }
  void SetDirection(const ALfloat fX, const ALfloat fY, const ALfloat fZ) const
    { SetSource3Float(AL_DIRECTION, fX, fY, fZ); }
  /* -- Get/set position --------------------------------------------------- */
  void GetPosition(ALfloat &fX, ALfloat &fY, ALfloat &fZ) const
    { GetSource3Float(AL_POSITION, fX, fY, fZ); }
  void SetPosition(const ALfloat fX, const ALfloat fY, const ALfloat fZ) const
    { SetSource3Float(AL_POSITION, fX, fY, fZ); }
  /* -- Get/set velocity --------------------------------------------------- */
  void GetVelocity(ALfloat &fX, ALfloat &fY, ALfloat &fZ) const
    { GetSource3Float(AL_VELOCITY, fX, fY, fZ); }
  void SetVelocity(const ALfloat fX, const ALfloat fY,
    const ALfloat fZ) const { SetSource3Float(AL_VELOCITY, fX, fY, fZ); }
  /* -- Get source id ------------------------------------------------------ */
  ALuint GetSource(void) const { return uiId; }
  /* -- Get/set/clear buffer id -------------------------------------------- */
  ALuint GetBuffer(void) const { return GetSourceInt<ALuint>(AL_BUFFER); }
  void SetBuffer(const ALint iBufferId) const
    { SetSourceInt(AL_BUFFER, iBufferId); }
  void ClearBuffer(void) { SetBuffer(0); }
  /* -- Get* --------------------------------------------------------------- */
  ALenum GetState(void) const { return GetSourceInt<ALenum>(AL_SOURCE_STATE); }
  ALsizei GetBuffersProcessed(void) const
    { return GetSourceInt<ALsizei>(AL_BUFFERS_PROCESSED); }
  ALsizei GetBuffersQueued(void) const
    { return GetSourceInt<ALsizei>(AL_BUFFERS_QUEUED); }
  ALsizei GetBuffersTotal(void) const
    { return GetBuffersProcessed() + GetBuffersQueued(); }
  ALuint GetType(void) const { return GetSourceInt<ALuint>(AL_SOURCE_TYPE); }
  /* -- QueueBuffers ----------------------------------------------- */
  void QueueBuffers(ALuint *puiBuffers, const ALsizei stCount) const
  { // Queue buffers
    AL(cOal->QueueBuffers(uiId, stCount, puiBuffers),
      "Queue buffers failed on source!",
      "Index", uiId, "Buffers", puiBuffers, "Count", stCount);
  }
  /* -- Queue one buffer --------------------------------------------------- */
  void QueueBuffer(const ALuint uiBuffer) const
  { // Queue buffers
    AL(cOal->QueueBuffer(uiId, uiBuffer),
      "Queue one buffer failed on source!",
      "Index", uiId, "Buffer", uiBuffer);
  }
  /* -- UnQueueBuffers ----------------------------------------------------- */
  void UnQueueBuffers(ALuint *puiBuffers, const ALsizei stCount) const
  { // UnQueue buffers
    ALL(cOal->UnQueueBuffers(uiId, stCount, puiBuffers),
      "Source unqueue on $ failed with buffers $($)!",
      uiId, puiBuffers, stCount);
  }
  /* -- UnQueueBuffer ------------------------------------------------------ */
  void UnQueueBuffer(ALuint uiBuffer) const
  { // UnQueue buffers
    ALL(cOal->UnQueueBuffer(uiId, uiBuffer),
      "Source unqueue on $ failed with buffer $!", uiId, uiBuffer);
  }
  /* -- UnQueue one buffer ------------------------------------------------- */
  ALuint UnQueueBuffer(void) { return cOal->UnQueueBuffer(uiId); }
  /* -- UnQueueAlLBuffers -------------------------------------------------- */
  void UnQueueAllBuffers(void)
  { // Get number of buffers and if we have some to unqueue?
    if(const ALsizei stBuffersProcessed = GetBuffersProcessed())
    { // Create memory for these buffers and get the pointer to its memory.
      // This function shouldn't be repeatedly called so it should be ok.
      // Don't change this from () to {}.
      ALUIntVector vBuffers(static_cast<size_t>(stBuffersProcessed));
      // Unqueue the buffers
      UnQueueBuffers(vBuffers.data(), stBuffersProcessed);
    }
  }
  /* -- StopAndUnQueueAlLBuffers ------------------------------------------- */
  void StopAndUnQueueAllBuffers(void)
  { // Stop the playback
    Stop();
    // Unqueue all the buffers
    UnQueueAllBuffers();
  }
  /* -- UnQueueAndDeleteAllBuffers ----------------------------------------- */
  void UnQueueAndDeleteAllBuffers(void)
  { // Clear the buffer from the source. Apple AL needs this or
    // alDeleteBuffers() returns AL_INVALID_OPERATION.
    ClearBuffer();
    // Get number of buffers and if we have some to unqueue?
    if(const ALsizei stBuffersProcessed = GetBuffersProcessed())
    { // Create memory for these buffers and get the pointer to its memory.
      // This function shouldn't be repeatedly called so it should be ok.
      // Don't change this from () to {}.
      ALUIntVector vBuffers(static_cast<size_t>(stBuffersProcessed));
      // Unqueue the buffers
      UnQueueBuffers(vBuffers.data(), stBuffersProcessed);
      // Delete the buffers
      ALL(cOal->DeleteBuffers(stBuffersProcessed, vBuffers.data()),
        "Source delete $ buffers failed at $!",
          stBuffersProcessed, vBuffers.data());
    }
  }
  /* -- StopUnQueueAndDeleteAllBuffers ------------------------------------- */
  void StopUnQueueAndDeleteAllBuffers(void)
  { // Stop playback
    Stop();
    // Unqueue and delete all buffers
    UnQueueAndDeleteAllBuffers();
  }
  /* -- Stop ------------------------------------------------------- */
  bool Stop(void)
  { // If source already stopped? return!
    if(IsStopped()) return false;
    // Stop it
    AL(cOal->StopSource(uiId), "Source failed to stop!", "Id", uiId);
    // Sucesss
    return true;
  }
  /* -- IsStopped -------------------------------------------------- */
  bool IsStopped(void) const { return GetState() == AL_STOPPED; }
  /* -- IsPlaying -------------------------------------------------- */
  bool IsPlaying(void) const { return GetState() == AL_PLAYING; }
  /* -- Play ------------------------------------------------------- */
  void Play(void)
  { // If playing return
    if(IsPlaying()) return;
    // Play the source
    AL(cOal->PlaySource(uiId), "Play failed on source!", "Index", uiId);
  }
  /* -- Constructor default locked for immediate async usage --------------- */
  explicit Source(const bool bLocked=true) :
    /* -- Initialisers ----------------------------------------------------- */
    ICHelperSource{ *cSources, this }, // Register in Sources list
    IdentCSlave{ cParent.CtrNext() },  // Initialise identification number
    uiId(cOal->CreateSource()),        // Initialise a new source from OpenAL
    bExternal(bLocked)                 // Set source managed flag
    /* -- Check for CreateSource error or initialise ----------------------- */
    { // Generate source
      ALC("Error generating al source id!");
      // Reset source parameters and set as
      Init();
    }
  /* -- Destructor --------------------------------------------------------- */
  ~Source(void)
  { // Delete the sourcess if id allocated
    if(uiId) ALL(cOal->DeleteSource(uiId), "Source failed to delete $!", uiId);
  }
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(Source)              // Supress copy constructor for safety
};/* -- End ---------------------------------------------------------------- */
END_COLLECTOREX(Sources,,,,fGVolume(0), fMVolume(0), fVVolume(0), fSVolume(0))
/* -- Stop (multiple buffers) ---------------------------------------------- */
static unsigned int SourceStop(const ALUIntVector &uiBuffers)
{ // Done if no buffers
  if(uiBuffers.empty()) return 0;
  // Buffers closed counter
  unsigned int uiStopped = 0;
  // Iterate through sources
  for(Source *sCptr : *cSources)
  { // Get reference
    Source &sCref = *sCptr;
    // Ignore if locked stream or no sour
    if(sCref.GetExternal()) continue;
    // Get sources buffer id and ignore if it is not set
    if(const ALuint uiSB = sCref.GetBuffer())
    { // Find a matching buffer and skip if source doesn't have this buffer id
      if(StdFindIf(par_unseq, uiBuffers.cbegin(), uiBuffers.cend(),
        [uiSB](const ALuint &uiB) { return uiSB == uiB; }) == uiBuffers.cend())
          continue;
      // Stop buffer and add to stopped counter if succeeded
      if(sCref.Stop()) ++uiStopped;
      // Clear the buffer from the source so the buffer can unload
      sCref.ClearBuffer();
    } // Else buffer id not acquired
  } // Else return stopped buffers
  return uiStopped;
}
/* == Manage sources (from audio thread) =================================== */
static Source *SourceGetFree(void)
{ // Iterate through available sources
  for(Source*const sCptr : *cSources)
  { // Get reference to source class then set next class
    Source &sCref = *sCptr;
    // Is a locked stream? Then it's active and locked!
    if(sCref.GetExternal() || sCref.IsPlaying()) continue;
    // Reset source
    sCref.ReInit();
    // Return the source
    return sCptr;
  } // Couldn't find one
  return nullptr;
}
/* == Returns if we can make a new source ================================== */
static bool SourceCanMakeNew(void)
  { return cSources->size() < cOal->GetMaxMonoSources(); }
/* == Get a source using Lua to allocate it ================================ */
static Source *SourceGetFromLua(lua_State*const lS)
{ // Try to get an idle source and pass it to Lua if found
  if(Source*const soNew = SourceGetFree())
    return ClassReuse<Source>(lS, "Source", soNew);
  // Else try to make a new one if we can
  return SourceCanMakeNew() ? ClassCreate<Source>(lS, "Source") : nullptr;
}
/* == Manage sources ======================================================= */
static Source *GetSource(void)
{ // Try to get an idle source and return it if possible
  if(Source*const soNew = SourceGetFree()) return soNew;
  // Else return a brand new source
  return SourceCanMakeNew() ? new Source : nullptr;
}
/* == SourceAlloc ========================================================== */
static void SourceAlloc(const size_t stCount)
{ // Set the value we can actually use
  const size_t stUsable = Clamp(stCount, 0, cOal->GetMaxMonoSources());
  // Get size and return if no new static sources needed to be created
  const size_t stSize = cSources->size();
  if(stSize >= stUsable) return;
  // Create new sources until we've reached the maximum and mark as usable
  for(size_t stI = stSize; stI < stUsable; ++stI) new Source(false);
  // Log count
  cLog->LogDebugExSafe("Audio added new sources [$:$$].",
    cSources->size(), hex, cOal->GetError());
}
/* == Set number of sources ================================================ */
static CVarReturn SourceSetCount(const size_t stCount)
{ // Ignore if not initialised
  if(!cOal->IsInitialised()) return ACCEPT;
  // Reallocate the sources
  SourceAlloc(stCount);
  // Success
  return ACCEPT;
}
/* ------------------------------------------------------------------------- */
};                                     // End of module namespace
/* == EoF =========================================================== EoF == */

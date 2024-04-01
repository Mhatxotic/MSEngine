/* == TIMER.HPP ============================================================ **
** ######################################################################### **
** ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## **
** ######################################################################### **
** ## This class is the engine timer manager.                             ## **
** ######################################################################### **
** ========================================================================= */
#pragma once                           // Only one incursion allowed
/* ------------------------------------------------------------------------- */
namespace ITimer {                     // Start of private module namespace
/* -- Dependencies --------------------------------------------------------- */
using namespace IClock::P;             using namespace ICVarDef::P;
/* ------------------------------------------------------------------------- */
namespace P {                          // Start of public module namespace
/* ------------------------------------------------------------------------- */
static class Timer final               // Members initially private
{ /* -- Limits ------------------------------------------------------------- */
  static const uint64_t uqIntvMin =    2000000, // Minimum interval
                        uqIntvMax = 1000000000; // Maximum interval
  /* -- Variables ---------------------------------------------------------- */
  ClkTimePoint     ctStart,            // Start of frame time
                   ctTimeOut,          // Time script times out
                   ctEnd;              // End of frame time
  ClkDuration      cdLoop,             // Loop duration
                   cdFrame,            // Frame duration
                   cdAcc,              // Accumulator duration
                   cdLimit,            // Frame limit
                   cdDelay,            // Delay duration
                   cdDelayPst,         // Persistent delay duration
                   cdTimeOut;          // Frame timeout duration
  uint64_t         qTriggers,          // Number of frame timeout checks
                   qTicks;             // Number of ticks processed this sec
  bool             bWait;              // Force wait?
  /* -- Set engine tick rate --------------------------------------- */ public:
  void TimerSetInterval(const uint64_t uqInterval)
    { cdLimit = nanoseconds{ uqInterval }; }
  /* -- Get minimum maximum interval value --------------------------------- */
  uint64_t TimerGetMinInterval(void) { return uqIntvMin; }
  uint64_t TimerGetMaxInterval(void) { return uqIntvMax; }
  /* -- Set global target fps ---------------------------------------------- */
  CVarReturn TimerTickRateModified(const uint64_t uqInterval)
    { return CVarSimpleSetIntNLGE(cdLimit, nanoseconds{ uqInterval},
        nanoseconds{ TimerGetMinInterval() },
        nanoseconds{ TimerGetMaxInterval() }); }
  /* -- Update delay as double --------------------------------------------- */
  void TimerUpdateDelay(const unsigned int uiNewDelay)
    { cdDelay = milliseconds{ uiNewDelay }; }
  /* -- Forces a delay internally if delay is disabled --------------------- */
  void TimerSetDelayIfZero(void)
    { if(cdDelay != seconds{0}) TimerUpdateDelay(1); }
  /* -- Restore saved persistent delay timer ------------------------------- */
  void TimerRestoreDelay(void) { cdDelay = cdDelayPst; }
  /* -- TimerSetDelay ------------------------------------------------------ */
  CVarReturn TimerSetDelay(const unsigned int uiNewDelay)
  { // Ignore if set over one second, any sort of app would not be usable with
    // over one second delay, so might as well cap it
    if(uiNewDelay > 1000) return DENY;
    // Set new delay
    TimerUpdateDelay(uiNewDelay);
    // Update persistent delay
    cdDelayPst = cdDelay;
    // Success
    return ACCEPT;
  }
  /* -- Get start time ----------------------------------------------------- */
  const ClkTimePoint TimerGetStartTime(void) const { return ctStart; }
  /* -- Do time calculations ----------------------------------------------- */
  void TimerCalculateTime(void)
  { // Set end time
    ctEnd = cmHiRes.GetTime();
    // Get duration we had to wait since end of last game loop
    cdLoop = ctEnd - ctStart;
    // Set new start time
    ctStart = ctEnd;
    // Set new timeout time
    ctTimeOut = ctEnd + cdTimeOut;
  }
  /* -- Thread suspense by duration ---------------------------------------- */
  void TimerSuspend(const ClkDuration cdAmount)
    { ::std::this_thread::sleep_for(cdAmount); }
  /* -- Thread suspense by integer ----------------------------------------- */
  void TimerSuspend(const unsigned int uiMilliseconds)
    { TimerSuspend(milliseconds(uiMilliseconds)); }
  /* -- Thread suspense by one millisecond --------------------------------- */
  void TimerSuspend(void) { TimerSuspend(1); }
  /* -- Thread suspense by requested duration ------------------------------ */
  void TimerSuspendRequested(void) { TimerSuspend(cdDelay); }
  /* -- Force wait if delay is disabled (cFboCore->Render()) --------------- */
  void TimerForceWait(void)
    { if(cdDelay == seconds(0)) bWait = true; }
  /* -- Calculate time elapsed since c++ ----------------------------------- */
  void TimerUpdateBot(void)
  { // Sleep if theres a delay
    TimerSuspendRequested();
    // Calculate current time using stl
    TimerCalculateTime();
    // Frame time is loop time since theres no accumulator
    cdFrame = cdLoop;
    // Increment ticks
    ++qTicks;
  }
  /* -- Calculate time elapsed since end of last loop ---------------------- */
  void TimerUpdateInteractiveInterim(void)
  { // Calculate frame time
    TimerCalculateTime();
    // Increase accumulator by frame time
    cdAcc += cdLoop;
  }
  /* -- Calculate time elapsed since end of last frame --------------------- */
  void TimerUpdateInteractive(void)
  { // Calculate frame time
    TimerUpdateInteractiveInterim();
    // Store grand frame time
    cdFrame = cdLoop;
  }
  /* -- Should execute a game tick? ---------------------------------------- */
  bool TimerShouldTick(void)
  { // Frame limit not reached?
    if(cdAcc < cdLimit)
    { // Force if we're forced to wait
      if(bWait) TimerSuspend();
      // Or wait a little bit if we can
      else TimerSuspendRequested();
      // Suspend engine thread for the requested delay
      return false;
    } // Reduce accumulator
    cdAcc -= cdLimit;
    // Increase number of ticks rendered
    ++qTicks;
    // We are no longer forced to wait
    bWait = false;
    // Tick loop should render a frame
    return true;
  }
  /* -- Should not execute a game tick? ------------------------------------ */
  bool TimerShouldNotTick(void) { return !TimerShouldTick(); }
  /* -- Reset counters and re-initialise start and end time ---------------- */
  void TimerCatchup(void)
  { // Reset accumulator and duration
    cdAcc = cdLoop = cdFrame = seconds{ 0 };
    // Update new start and end time
    ctStart = ctEnd = cmHiRes.GetTime();
  }
  /* -- TimerSetDelay ------------------------------------------------------ */
  CVarReturn TimerSetTimeOut(const unsigned int uiTimeOut)
    { return CVarSimpleSetIntNL(cdTimeOut,
        seconds{ uiTimeOut }, seconds{ 1 }); }
  /* -- Return if script timer timed out ----------------------------------- */
  bool TimerIsTimedOut(void)
    { ++qTriggers; return cmHiRes.GetTime() >= ctTimeOut; }
  /* -- Return how many times the script trigger was checked --------------- */
  uint64_t TimerGetTriggers(void) const { return qTriggers; }
  /* -- Return the current script timeout ---------------------------------- */
  double TimerGetTimeOut(void) const
    { return ClockDurationToDouble(cdTimeOut); }
  /* -- Return the current engine target tick time ------------------------- */
  double TimerGetLimit(void) const { return ClockDurationToDouble(cdLimit); }
  /* -- Return the current accumulated frame time -------------------------- */
  double TimerGetAccumulator(void) const
    { return ClockDurationToDouble(cdAcc); }
  /* -- Return the duration of the last frame ------------------------------ */
  double TimerGetDuration(void) const
    { return ClockDurationToDouble(cdFrame); }
  /* -- Return the frames per second based on the last frame --------------- */
  double TimerGetFPS(void) const { return 1.0 / TimerGetDuration(); }
  /* -- Return the target frames per second -------------------------------- */
  double TimerGetFPSLimit(void) const { return 1.0 / TimerGetLimit(); }
  /* -- Get the number of engine ticks processed --------------------------- */
  uint64_t TimerGetTicks(void) const { return qTicks; }
  /* -- Get the current suspend time --------------------------------------- */
  double TimerGetDelay(void) const
    { return ClockDurationToDouble(cdDelay); }
  /* -- Get the current tick start time ------------------------------------ */
  double TimerGetStart(void) const
    { return ClockDurationToDouble(ctStart.time_since_epoch()); }
  /* -- Reset the delay and timer ------------------------------------------ */
  void TimerReset(const bool bIdle)
  { // Restore delay timer since we let Lua modify it
    TimerRestoreDelay();
    // Force a suspend when leaving sandbox if suspend is disabled
    if(bIdle) TimerSetDelayIfZero();
    // Reset timer
    TimerCatchup();
  }
  /* -- Default constructors ----------------------------------------------- */
  Timer(void) :                        // No parameters
    /* --------------------------------------------------------------------- */
    ctStart{ milliseconds{0} },        // Init start of frame time
    ctTimeOut{ ctStart },              // Init time script times out
    ctEnd{ ctStart },                  // Init end of frame time
    cdLoop{ milliseconds{0} },         // Init loop duration
    cdFrame{ cdLoop },                 // Init frame duration
    cdAcc{ cdLoop },                   // Init accumulator duration
    cdLimit{ cdLoop },                 // Init frame limit
    cdDelay{ cdLoop },                 // Init delay duration
    cdDelayPst{ cdLoop },              // Init persistent delay duration
    cdTimeOut{ cdLoop },               // Init frame timeout duration
    qTriggers(0),                      // Init number of frame timeout checks
    qTicks(0),                         // Init no. of ticks processed this sec
    bWait(false)                       // Init force wait?
    /* -- No code ---------------------------------------------------------- */
    { }
} /* ----------------------------------------------------------------------- */
*cTimer = nullptr;                     // Pointer to static class
/* ------------------------------------------------------------------------- */
}                                      // End of public module namespace
/* ------------------------------------------------------------------------- */
}                                      // End of private module namespace
/* == EoF =========================================================== EoF == */

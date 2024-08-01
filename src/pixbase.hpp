/* == PIXBASE.HPP ========================================================== **
** ######################################################################### **
** ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## **
** ######################################################################### **
** ## This is a POSIX specific module that handles unhandled exceptions   ## **
** ## and writes debugging information to disk to help resolve bugs.      ## **
** ## Since we support MacOS and Linux, we can support both systems very  ## **
** ## simply with POSIX compatible calls.                                 ## **
** ######################################################################### **
** ========================================================================= */
#pragma once                           // Only one incursion allowed
/* -- Signals to support --------------------------------------------------- */
static array<pair<const int,void(*)(int)>,14>iaSignals{ {
  { SIGABRT, nullptr }, { SIGBUS,  nullptr },
  { SIGFPE,  nullptr }, { SIGHUP,  nullptr }, { SIGILL,  nullptr },
  { SIGINT,  nullptr }, { SIGPIPE, nullptr }, { SIGQUIT, nullptr },
  { SIGSEGV, nullptr }, { SIGSYS,  nullptr }, { SIGTERM, nullptr },
  { SIGTRAP, nullptr }, { SIGXCPU, nullptr }, { SIGXFSZ, nullptr },
} };
/* -- SIGSEGV workaround when still in System() constructor ---------------- */
static bool bSysBaseDataReady = false; // Is the data ready?
/* -- We'll put all these calls in a namespace ----------------------------- */
class SysBase :                        // Safe exception handler namespace
  /* -- Base classes ------------------------------------------------------- */
  public SysVersion,                   // Version information class
  public Ident                         // Mutex name
{ /* ----------------------------------------------------------------------- */
  typedef map<const int, struct rlimit> ResourceLimit; // Modifyable
  ResourceLimit    rLimits;            // Resource limits database
  /* ----------------------------------------------------------------------- */
  enum ExitState { ES_SAFE, ES_UNSAFE, ES_CRITICAL }; // Signal exit types
  /* --------------------------------------------------------------- */ public:
  int DoDeleteGlobalMutex(const char*const cpName)
    { return shm_unlink(cpName); }
  /* ----------------------------------------------------------------------- */
  int DoDeleteGlobalMutex(void)
  { // Return if data not ready to prevent SIGSEGV during System() construction
    if(!bSysBaseDataReady) return 0;
    // Data no longer ready
    bSysBaseDataReady = false;
    // Return result of deleting the mutex
    return DoDeleteGlobalMutex(IdentGet().c_str());
  }
  /* ----------------------------------------------------------------------- */
  void DeleteGlobalMutex(const string_view &strvTitle)
  { // Create the semaphore and if the creation failed? Put in log that another
    // instance of this application is running
    if(DoDeleteGlobalMutex(strvTitle.data()) == -1)
      cLog->LogWarningExSafe("SysMutex could not delete old mutex '$': $",
        strvTitle, SysError());
    // Creation succeeded so put success in log
    else cLog->LogWarningExSafe("SysMutex deleted old mutex '$'.", strvTitle);
  }
  /* ----------------------------------------------------------------------- */
  void DeleteGlobalMutex(void) { DoDeleteGlobalMutex(IdentGet().data()); }
  /* ----------------------------------------------------------------------- */
  bool InitGlobalMutex(const string_view &strvTitle)
  { // Ignore if semaphore already created
    if(strvTitle.empty() || IdentIsSet()) return false;
    // Set a flag to say that the mutex is ready because the function to
    // delete the shared object can still be called when an signal is sent
    // during System() construction. This makes sure that the shared object is
    // not attempted to be deleted.
    bSysBaseDataReady = true;
    // Create the semaphore and if the creation failed?
    if(shm_open(strvTitle.data(), O_CREAT | O_EXCL, 0) == -1)
    { // If it was because it already exists?
      if(StdIsError(EEXIST) || StdIsError(EACCES))
      { // Put in log that another instance of this application is running
        cLog->LogWarningSafe(
         "System detected another instance of this application running.");
        // Execution may not continue
        return false;
      } // Report error
      cLog->LogWarningExSafe("System failed to setup global mutex: $!",
        SysError());
    } // Set mutex title
    IdentSet(strvTitle);
    // Execution can continue
    return true;
  }
  /* ----------------------------------------------------------------------- */
  void DebugFunction(Statistic &staData, const char*const cpStack,
    const void*const vpStack) const
  { // Information about the object
    Dl_info diData;
    // Tokenise the stack after removing duplicate whitespaces. Note that objc
    // calls will have spaces in them.
    const Token tokData{ StrCompact(cpStack), cCommon->Space() };
    // Need some extra work on Apple
#if defined(MACOS)
    // The last two tokens should always be a + and a number which we will
    // grab.
    switch(tokData.size())
    { // Not enough data?
      case  0: staData.Data(cCommon->Unspec()).Data(cCommon->Unspec());
               break;
      case  1: staData.Data(tokData.front()).Data(cCommon->Unspec());
               break;
      case  2: staData.Data(tokData[1]).Data(cCommon->Unspec());
               break;
      case  3: staData.Data(tokData[1]).Data(tokData[2]);
               break;
      case  4: staData.Data(tokData[1]).Data(tokData[3]);
               break;
      case  5: staData.Data(tokData[1])
                      .DataA(tokData[3], ' ', tokData[4]);
               break;
      // Expected amount for a C/C++ call. Just show the + amount
      default: staData.Data(tokData[1])
                      .DataA(tokData[2], '+', tokData.back());
               break;
    } // Get information about the item and if failed?
    if(!dladdr(vpStack, &diData))
    { // Just add unknown and try the next function level
      staData.Data(cCommon->Unspec());
      return;
    } // Running on Linux?
#else
    // Get information about the item and if failed?
    if(!dladdr(vpStack, &diData))
    { // Just add what the second value was and return
      staData.Data(tokData[1]);
      return;
    }
#endif
    // Buffer for allcated mrmory
    int iStatus = 0;
    // Demangle the name and check result and compare status. We need to
    // free the string after so we'll let unique_ptr do it for us. For some
    // reason, GCC on Linux doesn't like decltype(free) but void(void*) works.
    if(unique_ptr<char, function<void(void*)>>
      uPtr{ abi::__cxa_demangle(diData.dli_sname,
        nullptr, nullptr, &iStatus), free })
          staData.Data(uPtr.get());
    // What is the return code for this call?
    else switch(iStatus)
    { // Memory error?
      case -1: staData.DataF("<MAE:$>", tokData[1]); break;
      // Not a valid name?
      case -2: staData.Data(diData.dli_sname); break;
      // Invalid argument?
      case -3: staData.DataF("<IA:$>", tokData[1]); break;
      // Success (impossible) or unknown?
      default: staData.DataF("<$:$>", iStatus, tokData[1]); break;
    }
  }
  /* ----------------------------------------------------------------------- */
  void DumpStack(ostringstream &osS) const
  { // Create array to hold stack pointers
    array<void*, 256> vaArray;
    // Get the number of stack frames that can fit in the array and if can?
    if(const int iSize = backtrace(vaArray.data(),
      sizeof(vaArray) / sizeof(vaArray[0])))
    { // Get stack trace. For some reason, GCC on Linux doesn't like
      // decltype(free) but void(void*) works.
      if(unique_ptr<char*, function<void(void*)>> uStack{
        backtrace_symbols(vaArray.data(), iSize), free })
      { // Convert entries to size_t
        const size_t stSize = static_cast<size_t>(iSize);
        // Setup table formatter
        Statistic staData;
        staData.Header("#")
        // MacOS shows extra information with 'backtrace_symbols()'
        // 'STACKID MODULE ADDRESS FUNCTION' as opposite to 'STACKID FUNCTION'
        // on Linux systems.
#if defined(MACOS)
               .Header("Module").Header("Address")
#endif
               .Header("Function", false)
        // Reserve specified number of rows in output table
               .Reserve(stSize);
        // Write pointer address and name
        for(size_t stI = 0; stI < stSize; ++stI)
        { // Add ID
          staData.DataN(stI);
          // Add others
          DebugFunction(staData, uStack.get()[stI], vaArray[stI]);
        } // We got a stack trace
        osS << ", stack trace:-\n";
        // Build output into string stream
        staData.Finish(osS);
        // Footer
        osS << stSize << " calls.\n";
        // Done
        return;
      }
    } // Problem generating backtrace.
    osS << '.';
  }
  /* ----------------------------------------------------------------------- */
  void DumpMods(ostringstream &osS)
  { // Ignore if no mods
    if(empty()) return;
    // Add mods header
    osS << "\nShared objects:-\n"
           "================\n";
    // Prepare headers
    Statistic staData;
    staData.Header("DESCRIPTION").Header("VERSION", false)
           .Header("VENDOR", false).Header("MODULE", false)
           .Reserve(size());
    // list modules
    for(const auto &mD : *this)
    { // Get mod data
      const SysModuleData &smdData = mD.second;
      staData.Data(smdData.GetDesc()).Data(smdData.GetVersion())
             .Data(smdData.GetVendor()).Data(smdData.GetFull());
    } // Finished enumeration of modules
    osS << staData.Finish();
  }
  /* ----------------------------------------------------------------------- */
  ExitState DebugMessage(const char*const cpSignal, const char*const cpExtra)
  { // Build filename
    const string strFileName{ cCmdLine ?
      StrAppend(cCmdLine->GetCArgs()[0], ".dbg") : "/tmp/msengine-crash.txt" };
    // Begin message
    ostringstream osS;
    osS << "Received signal 'SIG" << cpSignal << "' at "
        << cmSys.FormatTime();
    // Dump the stack
    DumpStack(osS);
    // Add extra information if set
    if(*cpExtra) osS << cCommon->Lf() << cpExtra << cCommon->Lf();
    // Print it to stderr
    fputs(osS.str().c_str(), stderr);
    // Dump mods to log
    DumpMods(osS);
    // Add trace header
    osS << "\nLog trace:-\n"
           "===========\n";
    // Now add the buffer lines
    cLog->GetBufferLines(osS);
    // Write the output and close the log
    const string strMsg{ StrAppend(osS.str(), '\n') };
    // Message box string
    ostringstream osTS;
    osTS << "Received signal SIG" << cpSignal << " at " << cmSys.FormatTime()
         << ". This means that the engine must now terminate and we apologise "
            "for the inconvenience with the loss of any unsaved progress. ";
    // Create the debug log and exit if failed
    if(FStream fOut{ StdMove(strFileName), FM_W_T })
    { // Write to crash output file
      fOut.FStreamWriteString(strMsg);
      // We wrote the crash log
      osTS << "Please submit the crash dump file at '" << fOut.IdentGet()
           << "' to us so that we may investigate further and resolve the "
              "problem so it does not reoccur again.";
    } // Exit write log failure? We wrote the crash log
    else osTS << "We unfortunately could not write an error log to '"
              << fOut.IdentGet() << "' because " << fOut.FStreamGetErrStr()
              << '!';
    // Finish string
    osTS << " Please press the button to terminate.";
    // Show message box
    SysMessage("Critical error!", osTS.str(), MB_ICONSTOP);
    // Send requested exit code
    return ES_CRITICAL;
  }
  /* ----------------------------------------------------------------------- */
  ExitState DebugMessage(const char*const cpSignal)
    { return DebugMessage(cpSignal, cCommon->CBlank()); }
  /* ----------------------------------------------------------------------- */
  ExitState ConditionalExit(const string &strName, unsigned int &uiAttempts)
  { // If events system is available?
    if(cEvtMain)
    { // Maximum number of attempts so repeated attempts eventually just
      // make the engine quit immediately.
      static const unsigned int uiMaxAttempts = 5;
      // Incrememnt attempts and if there are not too many attempts?
      if(++uiAttempts < uiMaxAttempts)
      { // Log that we're trying to shut down
        cLog->LogNLCErrorExSafe("System got $ signal $ of $, shutting down...",
          strName, uiAttempts, uiMaxAttempts);
        // Send clean shutdown event to engine
        return ES_SAFE;
      } // Log immediate shutdown because too many attempts
      cLog->LogNLCErrorExSafe("System got $ $ signals so terminating now...",
        uiMaxAttempts, strName);
    } // No attempts required so log generic exit message
    else cLog->LogNLCErrorExSafe("System got $ signal so terminating now...",
      strName);
    // Unsafe shutdown
    return ES_UNSAFE;
  }
  /* ----------------------------------------------------------------------- */
  ExitState HandleSignalSafe(const int iSignal)
  { // Which signal
    switch(iSignal)
    { // The signal is usually initiated by the process itself when it calls
      // abort function of the C Standard Library, but it can be sent to the
      // process from outside like any other signal.
      case SIGABRT: return DebugMessage("ABRT (Aborted)");
      // Sent when we cause a bus error. The conditions that lead to the signal
      // being sent are, for example, incorrect memory access alignment or
      // non-existent physical address.
      case SIGBUS: return DebugMessage("BUS (Bus error)");
      // Sent when we execute an erroneous arithmetic operation, such as
      // division by zero (the name "FPE", standing for floating-point
      // exception, is a misnomer as the signal covers integer-arithmetic
      // errors as well).
      case SIGFPE: return DebugMessage("FPE (Floating-point exception)");
      // Sent by our controlling terminal when a user wishes to interrupt the
      // process. This is typically initiated by pressing Ctrl-C, but on some
      // systems, the "delete" character or "break" key can be used.
      case SIGINT:
      { // Number of sigint's processed
        static unsigned int uiSigIntCount = 0;
        // Perform conditional exit
        return ConditionalExit("interrupt", uiSigIntCount);
      } // Incorrect machine code. Apparently, this instruction can't be
      // caught but we'll include it just incase some systems can.
      case SIGILL: return DebugMessage("ILL (Illegal instruction)",
        // Add extra information
        "This illegal instruction exception usually indicates that this "
        BUILD_TARGET " compiled binary is NOT compatible with your "
        "operating system and/or central processing unit. "
#if defined(X64)                       // Special message for 64-bit system?
# if defined(MACOS)                    // Apple target?
#  if defined(RISC)                    // Arm64 target?
        "Since you are running the 64-bit ARM version of this binary, "
        "please consider trying the 64-bit Intel version instead."
#  elif defined(CISC)                  // x86-64 target?
        "Since you are running the 64-bit Intel version of this binary, "
        "please consider trying the 64-bit ARM version instead."
#  endif                               // Arch target check
# elif defined(WINDOWS)                // Windows target?
        "Since you are running the 64-bit version of this binary, please "
        "consider trying the 32-bit version instead."
# endif                                // OS target check
#elif defined(X86)                     // X86 target?
        "Since you are running the 32-bit version of this binary, you may "
        "need to upgrade your operating system and/or central processing "
        "unit. If you originally tried the 64-bit version and you still got "
        "the the same error then you may need to report this issue as a bug."
#endif                                 // Bit target check
        );
      // Sent when we attempt to write to a pipe without a process connected
      // to the other end.
      case SIGPIPE: return DebugMessage("PIPE (Broken pipe)");
      // Sent by our controlling terminal when the user requests that the
      // process quit and perform a core dump.
      case SIGQUIT: return DebugMessage("QUIT (Quit from keyboard)");
      // Sent when we make an invalid virtual memory reference, or
      // segmentation fault, i.e. when it performs a segmentation violation.
      case SIGSEGV: return DebugMessage("SEGV (Segmentation fault)");
      // Sent when we pass a bad argument to a system call. In practice, this
      // kind of signal is rarely encountered since applications rely on
      // libraries (e.g. libc) to make the call for them.
      case SIGSYS: return DebugMessage("SYS (Illegal system call)");
      // Sent when our controlling terminal is closed. It was originally
      // designed to notify the process of a serial line drop (a hangup). In
      // modern systems, this signal usually means that the controlling
      // pseudo or virtual terminal has been closed. Many daemons will reload
      // their configuration files and reopen their logfiles instead of
      // exiting when receiving this signal. nohup is a command to make a
      // command ignore the signal.
      case SIGHUP:
      { // Number of sighup's processed
        static unsigned int uiSigHangUp = 0;
        // Perform conditional exit
        return ConditionalExit("hang up", uiSigHangUp);
      } // Sent to request our termination. Unlike the SIGKILL signal, it can
      // be caught and interpreted or ignored by the process. This allows the
      // process to perform nice termination releasing resources and saving
      // state if appropriate. SIGINT is nearly identical to SIGTERM.
      case SIGTERM:
      { // Number of sighup's processed
        static unsigned int uiSigTerm = 0;
        // Perform conditional exit
        return ConditionalExit("termination", uiSigTerm);
      } // Sent when an exception (or trap) occurs: a condition that a debugger
      // has requested to be informed of — for example, when a particular
      // function is executed, or when a particular variable changes value.
      case SIGTRAP: return DebugMessage("TRAP (Breakpoint)");
      // Sent when we have used up the CPU for a duration that exceeds a
      // certain predetermined user-settable value. The arrival of a SIGXCPU
      // signal provides the receiving process a chance to quickly save any
      // intermediate results and to exit gracefully, before it is terminated
      // by the operating system using the SIGKILL signal.
      case SIGXCPU: return DebugMessage("XCPU (Processor time threshold)");
      // Sent when we grow a file larger than the maximum allowed size.
      case SIGXFSZ: return DebugMessage("XFSZ (File size threshold)");
      // Unrecognised signal?
      default: return DebugMessage(StrFormat("UNKNOWN<$>", iSignal).c_str());
    }
  }
  /* ----------------------------------------------------------------------- */
  static void HandleSignalStatic(int);
  void HandleSignal(const int iSignal) try
  { // Handle signal and get result
    switch(HandleSignalSafe(iSignal))
    { // Exit safely? Send shutdown to engine and do nothing else
      case ES_SAFE: cEvtMain->RequestQuit(); return;
      // Exit unsafely? Delete mutex and send safe shutdown
      case ES_UNSAFE: DoDeleteGlobalMutex(); exit(-1);
      // Exit unsafely and immediately? Delete mutex and shutdown now!
      case ES_CRITICAL: DoDeleteGlobalMutex(); _exit(-2);
    }
  } // Exception occured so just exit now
  catch(const exception&) { _exit(-3); }
  /* -- Set socket timeout ----------------------------------------- */ public:
  int SetSocketTimeout(const int iFd, const double dRTime,
    const double dWTime)
  { // Calculate timeout in milliseconds
    struct timeval                     // Sec, USec
      tRT{ static_cast<int>(dRTime), static_cast<int>(dRTime*1000)%1000 },
      tWT{ static_cast<int>(dWTime), static_cast<int>(dWTime*1000)%1000 };
    // Set socket options and get result
    return (setsockopt(iFd, SOL_SOCKET, SO_RCVTIMEO,
              reinterpret_cast<void*>(&tRT), sizeof(tRT)) < 0 ? 1 : 0) |
           (setsockopt(iFd, SOL_SOCKET, SO_SNDTIMEO,
              reinterpret_cast<void*>(&tWT), sizeof(tWT)) < 0 ? 2 : 0);
  }
  /* ----------------------------------------------------------------------- */
  SysBase(SysModMap &&smmMap, const size_t stI) :
    /* -- Initialisers ----------------------------------------------------- */
    SysVersion{                        // Initialise version info class
      StdMove(smmMap), stI },          // Move sent mod list into ours
    rLimits{{                          // Limits data
#if !defined(MACOS)                    // Not all resources supported
      { RLIMIT_LOCKS,  { 0, 0 } },     { RLIMIT_MSGQUEUE,   { 0, 0 } },
      { RLIMIT_NICE,   { 0, 0 } },     { RLIMIT_RTPRIO,     { 0, 0 } },
      { RLIMIT_RTTIME, { 0, 0 } },     { RLIMIT_SIGPENDING, { 0, 0 } },
#endif                                 // Mac check
      { RLIMIT_AS,     { 0, 0 } },     { RLIMIT_CORE,       { 0, 0 } },
      { RLIMIT_CPU,    { 0, 0 } },     { RLIMIT_DATA,       { 0, 0 } },
      { RLIMIT_FSIZE,  { 0, 0 } },     { RLIMIT_MEMLOCK,    { 0, 0 } },
      { RLIMIT_NOFILE, { 0, 0 } },     { RLIMIT_NPROC,      { 0, 0 } },
      { RLIMIT_RSS,    { 0, 0 } },     { RLIMIT_STACK,      { 0, 0 } }
    }}
    /* -- ------------------------------------------------------------------ */
  { // Now install all those signal handlers
    for(auto &aSignal : iaSignals)
    { // Set the signal and check for error
      aSignal.second = signal(aSignal.first, HandleSignalStatic);
      if(aSignal.second == SIG_ERR)
        XCL("Failed to install signal handler!", "Id", aSignal.first);
    } // Increase resource limits we can change so the engine can do more
    for(auto &aResource : rLimits)
    { // Get the limit for this resource
      if(!getrlimit(aResource.first, &aResource.second))
      { // Ignore if value doesn't need to change
        if(aResource.second.rlim_cur >= aResource.second.rlim_max) continue;
        // Set maximum allowed and if failed?
        const rlim_t rtOld = aResource.second.rlim_cur;
        aResource.second.rlim_cur = aResource.second.rlim_max;
        if(setrlimit(aResource.first, &aResource.second))
        { // Restore original value
          aResource.second.rlim_cur = rtOld;
          // Log a message
          cLog->LogWarningExSafe(
            "System failed to set resource limit $<0x$$$> from $<0x$$$> to "
            "$<0x$$$>: $!",
            aResource.first, hex, aResource.first, dec, rtOld, hex, rtOld, dec,
            aResource.second.rlim_max, hex, aResource.second.rlim_max, dec,
            SysError());
        }
      } // Failed to get limit so log the error and why
      else cLog->LogWarningExSafe(
        "System failed to get limit for resource $<0x$$$>: $!",
        aResource.first, hex, aResource.first, dec, SysError());
    }
  }
  /* ----------------------------------------------------------------------- */
  ~SysBase(void) noexcept(true)
  { // Uninstall safe signals
    for(auto &aSignal : iaSignals)
      if(signal(aSignal.first, aSignal.second) == SIG_ERR && cLog)
        cLog->LogWarningExSafe("Failed to restore signal $ handler! $.",
          aSignal.first, StrFromErrNo());
    // Delete global mutex
    DeleteGlobalMutex();
  }
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(SysBase)             // Suppress copy constructor for safety
};/* ----------------------------------------------------------------------- */
#define MSENGINE_SYSBASE_CALLBACKS() \
  void SysBase::SysBase::HandleSignalStatic(int iSignal) \
    { cSystem->HandleSignal(iSignal); }
/* == EoF =========================================================== EoF == */

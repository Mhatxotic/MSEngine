/* == SYSCORE.HPP ========================================================== */
/* ######################################################################### */
/* ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## */
/* ######################################################################### */
/* ## This is the header to the system class which allows the engine to   ## */
/* ## interface with the operating system. Since all operating systems    ## */
/* ## are different, we need to have seperate modules for them because    ## */
/* ## they will be huge amounts of different code to work properly!       ## */
/* ######################################################################### */
/* ========================================================================= */
#pragma once                           // Only one incursion allowed
/* ------------------------------------------------------------------------- */
namespace IfSystem {                   // Start of module namespace
/* -- Includes ------------------------------------------------------------- */
using namespace IfEvtMain;             // Using event namespace
using namespace IfConDef;              // Using condef namespace
using namespace IfArgs;                // Using arguments namespace
/* == System module data =================================================== */
/* ######################################################################### */
/* ## Information about a module.                                         ## */
/* ######################################################################### */
/* ------------------------------------------------------------------------- */
class SysModuleData :                  // Members initially private
  /* -- Base classes ------------------------------------------------------- */
  private PathSplit                    // Path parts to mod name
{ /* -- Variables ---------------------------------------------------------- */
  const unsigned int uiMajor, uiMinor, // Major and minor version of module
                  uiBuild, uiRevision; // Build and revision version of module
  const string     strVendor,          // Vendor of module
                   strDesc,            // Description of module
                   strComments,        // Comments of module
                   strVersion;         // Version as string
  /* --------------------------------------------------------------- */ public:
  const string &GetDrive(void) const { return strDrive; }
  const string &GetDir(void) const { return strDir; }
  const string &GetFile(void) const { return strFile; }
  const string &GetExt(void) const { return strExt; }
  const string &GetFileExt(void) const { return strFileExt; }
  const string &GetFull(void) const { return strFull; }
  const string &GetLoc(void) const { return strLoc; }
  unsigned int GetMajor(void) const { return uiMajor; }
  unsigned int GetMinor(void) const { return uiMinor; }
  unsigned int GetBuild(void) const { return uiBuild; }
  unsigned int GetRevision(void) const { return uiRevision; }
  const string &GetVendor(void) const { return strVendor; }
  const string &GetDesc(void) const { return strDesc; }
  const string &GetComments(void) const { return strComments; }
  const string &GetVersion(void) const { return strVersion; }
  /* -- Move constructor --------------------------------------------------- */
  SysModuleData(SysModuleData &&smdO) :
    /* -- Initialisers ----------------------------------------------------- */
    PathSplit{ StdMove(smdO) },                 // Copy filename
    uiMajor(smdO.GetMajor()),                   // Copy major version
    uiMinor(smdO.GetMinor()),                   // Copy minor version
    uiBuild(smdO.GetBuild()),                   // Copy build version
    uiRevision(smdO.GetRevision()),             // Copy revision version
    strVendor{ StdMove(smdO.GetVendor()) },     // Move vendor string
    strDesc{ StdMove(smdO.GetDesc()) },         // Move description string
    strComments{ StdMove(smdO.GetComments()) }, // Move comments string
    strVersion{ StdMove(smdO.GetVersion()) }    // Move version string
    /* -- No code ---------------------------------------------------------- */
    { }
  /* -- Initialise all members contructor ---------------------------------- */
  explicit SysModuleData(const string &strF, const unsigned int uiMa,
    const unsigned int uiMi, const unsigned int uiBu, const unsigned int uiRe,
    string &&strVen, string &&strDe, string &&strCo, string &&strVer) :
    /* -- Initialisers ----------------------------------------------------- */
    PathSplit{ strF },                 // Copy filename
    uiMajor(uiMa),                     // Copy major version
    uiMinor(uiMi),                     // Copy minor version
    uiBuild(uiBu),                     // Copy build version
    uiRevision(uiRe),                  // Copy revision version
    strVendor{ StdMove(strVen) },      // Move vendor string
    strDesc{ StdMove(strDe) },         // Move description string
    strComments{ StdMove(strCo) },     // Move comments string
    strVersion{ StdMove(strVer) }      // Move version string
    /* -- No code ---------------------------------------------------------- */
    { }
  /* -- Initialise filename only constructor ------------------------------- */
  explicit SysModuleData(const string &strF) :
    /* -- Initialisers ----------------------------------------------------- */
    PathSplit{ strF },                 // Initialise path parts
    uiMajor(0),                        // Major version not initialised yet
    uiMinor(0),                        // Minor version not initialised yet
    uiBuild(0),                        // Build version not initialised yet
    uiRevision(0)                      // Revision not initialised yet
    /* -- No code ---------------------------------------------------------- */
    { }
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(SysModuleData)       // Disable copy constructor and operator
};/* ----------------------------------------------------------------------- */
/* == System modules ======================================================= */
/* ######################################################################### */
/* ## Storage for all the modules loaded to this executable.              ## */
/* ######################################################################### */
/* ------------------------------------------------------------------------- */
typedef map<const size_t,const SysModuleData> SysModList; // Map of mod datas
/* ------------------------------------------------------------------------- */
struct SysModules :
  /* -- Base classes ------------------------------------------------------- */
  public SysModList                    // System module list
{ /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(SysModules)          // Disable copy constructor and operator
  /* -- Dump module list --------------------------------------------------- */
  CVarReturn DumpModuleList(const unsigned int uiShow)
  { // No modules? Return okay
    if(!uiShow || empty()) return ACCEPT;
    // Print how many modules we are enumerating
    cLog->LogNLCInfoExSafe("System enumerating $ modules...", size());
    // For each shared module, print the data for it to log
    for(const auto &mD : *this)
    { // Get mod data and pathsplit data
      const SysModuleData &smdData = mD.second;
      // Log the module data
      cLog->LogNLCInfoExSafe("- $ <$> '$' by '$' from '$'.",
        smdData.GetFileExt(), smdData.GetVersion(),
        smdData.GetDesc().empty() ? cCommon->Unknown() : smdData.GetDesc(),
        smdData.GetVendor().empty() ? cCommon->Unknown() : smdData.GetVendor(),
        smdData.GetLoc());
    } // Done
    return ACCEPT;
  }
  /* -- Move constructor ---------------------------------------- */ protected:
  SysModules(SysModules &&smOther) :
    /* -- Initialisers ----------------------------------------------------- */
    SysModList{ StdMove(smOther) }
    /* -- No code ---------------------------------------------------------- */
    { }
  /* -- Init from SysModList ----------------------------------------------- */
  explicit SysModules(SysModList &&smlOther) :
    /* -- Initialisers ----------------------------------------------------- */
    SysModList{ StdMove(smlOther) }
    /* -- No code ---------------------------------------------------------- */
    { }
};/* ----------------------------------------------------------------------- */
/* == System version ======================================================= */
/* ######################################################################### */
/* ## Information about the engine executable and modules loaded.         ## */
/* ######################################################################### */
/* ------------------------------------------------------------------------- */
class SysVersion :
  /* -- Base classes ------------------------------------------------------- */
  public SysModules                    // System modules
{ /* ----------------------------------------------------------------------- */
  const SysModuleData &smdEng;         // Engine executable information
  /* --------------------------------------------------------------- */ public:
  DELETECOPYCTORS(SysVersion)          // Disable copy constructor and operator
  /* -- Access to engine version data -------------------------------------- */
  const char      *ENGBuildType(void) const { return BUILD_TYPE_LABEL; }
  const char      *ENGCompiled(void)  const { return VER_DATE; }
  const char      *ENGCompiler(void)  const { return COMPILER_NAME; }
  const char      *ENGCompVer(void)   const { return COMPILER_VERSION; }
  const char      *ENGTarget(void)    const { return BUILD_TARGET; }
  const string    &ENGAuthor(void)    const { return smdEng.GetVendor(); }
  const string    &ENGComments(void)  const { return smdEng.GetComments(); }
  const string    &ENGDir(void)       const { return smdEng.GetDir(); }
  const string    &ENGDrive(void)     const { return smdEng.GetDrive(); }
  const string    &ENGExt(void)       const { return smdEng.GetExt(); }
  const string    &ENGFile(void)      const { return smdEng.GetFile(); }
  const string    &ENGFileExt(void)   const { return smdEng.GetFileExt(); }
  const string    &ENGFull(void)      const { return smdEng.GetFull(); }
  const string    &ENGLoc(void)       const { return smdEng.GetLoc(); }
  const string    &ENGName(void)      const { return smdEng.GetDesc(); }
  const string    &ENGVersion(void)   const { return smdEng.GetVersion(); }
  unsigned int     ENGBits(void)      const { return (sizeof(void*)*8); }
  unsigned int     ENGBuild(void)     const { return smdEng.GetBuild(); }
  unsigned int     ENGMajor(void)     const { return smdEng.GetMajor(); }
  unsigned int     ENGMinor(void)     const { return smdEng.GetMinor(); }
  unsigned int     ENGRevision(void)  const { return smdEng.GetRevision(); }
  /* -- Find executable module info and return reference to it -- */ protected:
  const SysModuleData &FindBaseModuleInfo(const size_t stId) const
  { // Find the module, we stored it as a zero, if not found?
    const SysModList &smlData = *this;
    const auto smlitItem{ smlData.find(stId) };
    if(smlitItem == smlData.cend())
      XC("Failed to locate executable information!",
         "Length", smlData.size(), "Instance", stId);
    // Return version data
    return smlitItem->second;
  }
  /* -- Move constructor r ------------------------------------------------- */
  SysVersion(SysVersion &&svOther) :
    /* -- Initialisers ----------------------------------------------------- */
    SysModules{ StdMove(svOther) },   // Move other version information
    smdEng{ StdMove(svOther.smdEng) } // Move engine exetuable information
    /* -- No code ---------------------------------------------------------- */
    { }
  /* -- Init from SysModList ----------------------------------------------- */
  SysVersion(SysModList &&smlOther, const size_t stI) :
    /* -- Initialisers ----------------------------------------------------- */
    SysModules{ StdMove(smlOther) },           // Move system modules list
    smdEng{ StdMove(FindBaseModuleInfo(stI)) } // Move engine executable info
    /* -- No code ---------------------------------------------------------- */
    { }
};/* ----------------------------------------------------------------------- */
/* == System common ======================================================== */
/* ######################################################################### */
/* ## The operating specific modules populate their data inside this      ## */
/* ## class to maintain a common access for operating system information. ## */
/* ######################################################################### */
/* ------------------------------------------------------------------------- */
class SysCommon                        // Common system structs and funcs
{ /* -- Typedefs ------------------------------------------------ */ protected:
  const struct ExeData                 // Executable data
  { /* --------------------------------------------------------------------- */
    const unsigned int ulHeaderSum;    // Executable checksum in header
    const unsigned int ulCheckSum;     // Executable actual checksum
    const bool         bExeIsModified; // True if executable is modified
    const bool         bExeIsBundled;  // True if executable is bundled
  } /* --------------------------------------------------------------------- */
  exeData;                             // Physical executable data
  /* ----------------------------------------------------------------------- */
  const struct OSData                  // Operating system data
  { /* --------------------------------------------------------------------- */
    const string       strName;        // Os name (e.g. Windows)
    const string       strNameEx;      // Os host (e.g. Wine)
    const unsigned int uiMajor;        // Os major version
    const unsigned int uiMinor;        // Os minor version
    const unsigned int uiBuild;        // Os build number
    const unsigned int uiBits;         // Os bit version
    const string       strLocale;      // Os locale
    const bool         bIsAdmin;       // Os user has elevated privileges
    const bool         bIsAdminDef;    // Os uses admin accounts by default
    const StdTimeT     ttExpiry;       // Os expiry time
    const bool         bIsExpired;     // Os has reached end-of-life?
  } /* --------------------------------------------------------------------- */
  osData;                              // Operating system data
  /* ----------------------------------------------------------------------- */
  const struct CPUData                 // Processor data
  { /* --------------------------------------------------------------------- */
    const string       sVendorId;      // VendorIdentifier
    const string       sProcessorName; // ProcessorNameString
    const string       sIdentifier;    // Identifier
    const size_t       stCpuCount;     // Cpu count
    const unsigned int ulSpeed;        // ~MHz
    const unsigned int ulFeatureSet;   // FeatureSet
    const unsigned int ulPlatformId;   // Platform ID
  } /* --------------------------------------------------------------------- */
  cpuData;                             // System processor data
  /* ----------------------------------------------------------------------- */
  struct CPUUseData                    // Processor usage data
  { /* --------------------------------------------------------------------- */
    double         fdProcess;          // Process cpu usage
    double         fdSystem;           // System cpu usage
    /* -- Default constructor ---------------------------------------------- */
    CPUUseData(void) :
      /* -- Initialisers --------------------------------------------------- */
      fdProcess(0.0),                  // Zero process cpu usage
      fdSystem(0.0)                    // Zero system cpu usage
      /* -- No code -------------------------------------------------------- */
      { }
  } /* --------------------------------------------------------------------- */
  cpuUData;                            // Processor usage data
  /* ----------------------------------------------------------------------- */
  struct MemData                       // Processor data
  { /* --------------------------------------------------------------------- */
    uint64_t       qMTotal;            // 64-bit memory total
    uint64_t       qMFree;             // 64-bit memory free
    uint64_t       qMUsed;             // 64-bit memory used
    size_t         stMFree;            // 32-bit memory free
    double         dMLoad;             // Ram use in %
    size_t         stMProcUse;         // Process memory usage
    size_t         stMProcPeak;        // Peak process memory usage
    /* -- Default constructor ---------------------------------------------- */
    MemData(void) :
      /* -- Initialisers --------------------------------------------------- */
      qMTotal(0),                      // Zero total memory
      qMFree(0),                       // Zero free memory
      qMUsed(0),                       // Zero used memory
      stMFree(0),                      // Zero 32-bit free memory
      dMLoad(0.0),                     // Zero memory usage percentage
      stMProcUse(0),                   // Zero process usage
      stMProcPeak(0)                   // Zero process peak usage
      /* -- No code -------------------------------------------------------- */
      { }
  } /* --------------------------------------------------------------------- */
  memData;                             // Memory data
  /* --------------------------------------------------------------- */ public:
  bool EXEModified(void) const { return exeData.bExeIsModified; }
  unsigned int EXEHeaderSum(void) const { return exeData.ulHeaderSum; }
  unsigned int EXECheckSum(void) const { return exeData.ulCheckSum; }
  bool EXEBundled(void) const { return exeData.bExeIsBundled; }
  /* ----------------------------------------------------------------------- */
  const string &OSName(void) const { return osData.strName; }
  const string &OSNameEx(void) const { return osData.strNameEx; }
  bool IsOSNameExSet(void) const { return !OSNameEx().empty(); }
  unsigned int OSMajor(void) const { return osData.uiMajor; }
  unsigned int OSMinor(void) const { return osData.uiMinor; }
  unsigned int OSBuild(void) const { return osData.uiBuild; }
  unsigned int OSBits(void) const { return osData.uiBits; }
  const string &OSLocale(void) const { return osData.strLocale; }
  bool OSIsAdmin(void) const { return osData.bIsAdmin; }
  bool OSIsAdminDefault(void) const { return osData.bIsAdminDef; }
  StdTimeT OSExpiry(void) const { return osData.ttExpiry; }
  bool OSExpired(void) const { return osData.bIsExpired; }
  /* ----------------------------------------------------------------------- */
  const string &CPUVendor(void) const { return cpuData.sVendorId; }
  const string &CPUName(void) const { return cpuData.sProcessorName; }
  const string &CPUIdentifier(void) const { return cpuData.sIdentifier; }
  size_t CPUCount(void) const { return cpuData.stCpuCount; }
  unsigned int CPUSpeed(void) const { return cpuData.ulSpeed; }
  unsigned int CPUFeatures(void) const { return cpuData.ulFeatureSet; }
  unsigned int CPUPlatform(void) const { return cpuData.ulPlatformId; }
  double CPUUsage(void) const { return cpuUData.fdProcess; }
  double CPUUsageSystem(void) const { return cpuUData.fdSystem; }
  /* ----------------------------------------------------------------------- */
  uint64_t RAMTotal(void) const { return memData.qMTotal; }
  double RAMTotalMegs(void) const
    { return static_cast<double>(RAMTotal()) / 1048576; }
  uint64_t RAMFree(void) const { return memData.qMFree; }
  double RAMFreeMegs(void) const
    { return static_cast<double>(RAMFree()) / 1048576; }
  uint64_t RAMUsed(void) const { return memData.qMUsed; }
  size_t RAMFree32(void) const { return memData.stMFree; }
  double RAMFree32Megs(void) const
    { return static_cast<double>(RAMFree32()) / 1048576; }
  double RAMLoad(void) const { return memData.dMLoad; }
  size_t RAMProcUse(void) const { return memData.stMProcUse; }
  double RAMProcUseMegs(void) const
    { return static_cast<double>(RAMProcUse()) / 1048576; }
  size_t RAMProcPeak(void) const { return memData.stMProcPeak; }
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(SysCommon)           // Disable copy constructor and operator
  /* -- Constructor --------------------------------------------- */ protected:
  SysCommon(ExeData &&edExe, OSData &&osdOS, CPUData &&cpudCPU) :
    /* -- Initialisers ----------------------------------------------------- */
    exeData{ StdMove(edExe) },          // Move executable data
    osData{ StdMove(osdOS) },           // Move operating system data
    cpuData{ StdMove(cpudCPU) }         // Move processor data
    /* -- No code ---------------------------------------------------------- */
    { }
};/* ----------------------------------------------------------------------- */
/* == SysPipeBase class ==================================================== */
/* ######################################################################### */
/* ## Base class for SysPipe                                              ## */
/* ######################################################################### */
/* == System pipe base class ===========================================-=== */
class SysPipeBase :
  /* -- Base classes ------------------------------------------------------- */
  public Ident                         // Name of the pipe
{ /* ----------------------------------------------------------------------- */
  int64_t          qwExitCode;         // Process exit code
  /* -- Set status code ----------------------------------------- */ protected:
  void SysPipeBaseSetStatus(const int64_t qwNewCode)
    { qwExitCode = qwNewCode; }
  /* -- Return status code ----------------------------------------- */ public:
  int64_t SysPipeBaseGetStatus(void) const { return qwExitCode; }
  /* -- Constructor with init ---------------------------------------------- */
  SysPipeBase(void) :
    /* -- Initialisers ----------------------------------------------------- */
    qwExitCode(127)                    // Standard exit code
    /* -- No code ---------------------------------------------------------- */
    { }
};/* -- End ---------------------------------------------------------------- */
/* == SysConBase class ===================================================== */
/* ######################################################################### */
/* ## Base class for SysCon                                               ## */
/* ######################################################################### */
/* -- Typedefs ------------------------------------------------------------- */
BUILD_FLAGS(SysCon,                    // Console flags classes
  /* ----------------------------------------------------------------------- */
  // No settings?                      Cursor is visible?
  SCO_NONE               {0x00000000}, SCO_CURVISIBLE         {0x00000001},
  // Cursor is in insert mode?         Exit requested?
  SCO_CURINSERT          {0x00000002}, SCO_EXIT               {0x00000004}
);/* ----------------------------------------------------------------------- */
class SysConBase :
  /* -- Base classes ------------------------------------------------------- */
  protected SysConFlags                // Flags settings
{ /* -- Typedefs --------------------------------------------------- */ public:
  enum KeyType { KT_NONE, KT_KEY, KT_CHAR }; // GetKey return types
  /* -- For handling CTRL_CLOSE_EVENT --------------------------- */ protected:
  condition_variable cvExit;           // Exit condition variable
  mutex            mExit;              // Exit mutex
  /* -- Handle CTRL_CLOSE_EVENT ------------------------------------ */ public:
  bool SysConIsClosing(void) const { return FlagIsSet(SCO_EXIT); }
  bool SysConIsNotClosing(void) const { return !SysConIsClosing(); }
  void SysConCanCloseNow(void) { cvExit.notify_one(); }
  /* -- Constructor --------------------------------------------- */ protected:
  SysConBase(void) :
    /* -- Initialisers ----------------------------------------------------- */
    SysConFlags{ SCO_NONE }            // Current flags
    /* -- No code ---------------------------------------------------------- */
    { }
};/* ----------------------------------------------------------------------- */
/* == Includes ============================================================= */
/* ######################################################################### */
/* ## Here we include data for the specific operating system.             ## */
/* ######################################################################### */
/* ------------------------------------------------------------------------- */
#if defined(WINDOWS)                   // Using windows?
# include "syswin.hpp"                 // Include windows system core
#elif defined(MACOS)                   // Using mac?
# include "sysmac.hpp"                 // Include MacOS system core
#elif defined(LINUX)                   // Using linux?
# include "sysnix.hpp"                 // Include Linux system core
#endif                                 // Done checking OS
/* ------------------------------------------------------------------------- */
/* ######################################################################### */
/* ## The actual system class which we build using all the other classes  ## */
/* ## we already defined above.                                           ## */
/* ######################################################################### */
/* ------------------------------------------------------------------------- */
static class System final :            // The main system class
  /* -- Base classes ------------------------------------------------------- */
  public SysBase::SysCore              // Defined in 'sys*.hpp' headers
{ /* -- Private typedefs --------------------------------------------------- */
  typedef IdList<8> ModeList;          // List of possible combinations
  /* ----------------------------------------------------------------------- */
  const ModeList   mList;              // Modes list
  CoreFlags        cfMode;             // Requested core subsystem flags
  ClockInterval<CoreClock> tdhCPU;     // For getting cpu usage
  const size_t     stProcessId;        // Readable process id
  const size_t     stThreadId;         // Readable thread id
  /* ----------------------------------------------------------------------- */
  terminate_handler  thHandler;        // Old C++ termination handler
  unexpected_handler uhHandler;        // Old C++ unexpected handler
  /* ----------------------------------------------------------------------- */
  const string     strRoamingDir;      // Roaming directory
  /* -- Show message box with window handle (thiscall) --------------------- */
  unsigned int SysMsgTerm(const int iExitCode, const string &strMessage) const
    { SysMsgEx(strMessage, "An unexpected error has occurred and the engine "
        "must now terminate! We apologise for the inconvenience!");
      _exit(iExitCode); }
  /* -- Default handler for std::unexpected -------------------------------- */
  static void UnexpectedHandler(void);
  static void TerminateHandler(void);
  /* -- Return readable process and thread id ---------------------- */ public:
  size_t GetReadablePid(void) const { return stProcessId; }
  size_t GetReadableTid(void) const { return stThreadId; }
  /* -- Update CPU usage information --------------------------------------- */
  void UpdateCPUUsage(void)
    { if(tdhCPU.CITriggerStrict()) UpdateCPUUsageData(); }
  /* -- Update and return process CPU usage -------------------------------- */
  double UpdateAndGetCPUUsage(void)
    { UpdateCPUUsage(); return CPUUsage(); }
  /* -- Update and return system CPU usage --------------------------------- */
  double UpdateAndGetCPUUsageSystem(void)
    { UpdateCPUUsage(); return CPUUsageSystem(); }
  /* -- Show message box with window handle (thiscall) --------------------- */
  unsigned int SysMsgEx(const string &strReason, const string &strMessage,
    unsigned int uiFlags = MB_ICONSTOP) const
      { return SysMessage(GetWindowHandle(), Append(ENGName(), ' ', strReason),
          strMessage, uiFlags); }
  /* -- Update minimum RAM ------------------------------------------------- */
  CVarReturn SetMinRAM(const uint64_t qwMinValue)
  { // If we're to check for minimum memory free
    if(const size_t stMemory = IntOrMax<size_t>(qwMinValue))
    { // Store duration of fill here later
      double fdDuration;
      // Update memory usage data
      UpdateMemoryUsageData();
      // Take away current process memory usage. We'll do a underflow check
      // because utilities like valgrind can mess with this.
      const size_t stActualMemory =
        RAMProcUse() > stMemory ? stMemory : stMemory - RAMProcUse();
      { // Memory block for data
        Memory mbData;
        // Try to allocate the memory and if succeeded
        try { mbData.InitBlank(stActualMemory); }
        // Allocation failed?
        catch(const exception &e)
        { // Throw memory error
          XC("There is not enough system memory available. Close any "
            "running applications consuming it and try running again!",
            "Error",   e,          "Available", RAMFree(),
            "Total",   RAMTotal(), "Required",  stMemory,
            "Percent", MakePercentage(RAMFree(), RAMTotal()),
            "Needed",  stMemory - RAMFree());
        } // Initialise the memory and record time spent
        const ClockChrono<CoreClock> tpStart;
        mbData.Fill();
        fdDuration = tpStart.CCDeltaToDouble();
      } // Show result of test in log
      cLog->LogInfoExSafe("System heap init of $ ($+$) in $ ($/s).",
        ToBytesStr(stMemory), ToBytesStr(RAMProcUse()),
        ToBytesStr(stActualMemory), ToShortDuration(fdDuration),
          ToBytesStr(static_cast<uint64_t>(1.0 / fdDuration * stMemory)));
    } // Success
    return ACCEPT;
  }
  /* -- Restore old unexpected and termination handlers -------------------- */
  ~System(void) { set_unexpected(uhHandler); set_terminate(thHandler); }
  /* -- Set/Get GUI mode status -------------------------------------------- */
  CVarReturn SetCoreFlags(const unsigned int uiNGM)
  { // Failed if bad value
    if(uiNGM > CF_MASK) return DENY;
    // Set new value
    cfMode.FlagReset(static_cast<CoreFlags>(uiNGM));
    // Accepted
    return ACCEPT;
  }
  /* -- Set throw error on executable checksum mismatch -------------------- */
  CVarReturn CheckChecksumModified(const bool bEnabled)
  { // Ignore if we don't care that executabe checksum was modified
    if(!bEnabled || !EXEModified()) return ACCEPT;
    // Throw error
    XC("This software has been modified! Please re-acquire and/or "
       "re-install a fresh version of this software and try again!",
       "Path",     ENGFull(),
       "Expected", EXECheckSum(),
       "Actual",   EXEHeaderSum());
  }
  /* -- Set throw error if debugger is attached ---------------------------- */
  CVarReturn CheckDebuggerDetected(const bool bEnabled)
  { // Ignore if we don't care that a debugger is attached to the process
    if(!bEnabled || !DebuggerRunning()) return ACCEPT;
    // Throw error
    XC("There is a debugger attached to this software. Please "
       "close the offending debugger that is hooking onto this application "
       "and try running the application again");
  }
  /* -- Set working directory ---------------------------------------------- */
  CVarReturn SetWorkDir(const string &strP, string &strV)
  { // Set current directory to the startup directory as we want to honour the
    // users choice of relative directory.
    cCmdLine->SetStartupCWD();
    // If targeting Apple systems?
#if defined(MACOS)
    // Working directory
    string strWorkDir;
    // No directory specified?
    if(strP.empty())
    { // Build app bundle directory suffix and if we're calling from it from
      // the application bundle? Use the MacOS/../Resources directory instead.
      if(EXEBundled())
        strWorkDir = StdMove(PathSplit{
          Append(ENGLoc(), "../Resources"), true }.strFull);
      // Use executable working directory
      else strWorkDir = ENGLoc();
    } // Directory specified so use that and build full path for it
    else strWorkDir = StdMove(PathSplit{ strP, true }.strFull);
#else
    // Build directory
    string strWorkDir{ strP.empty() ? ENGLoc() :
      StdMove(PathSplit{ strP, true }.strFull) };
#endif
    // Set the directory and if failed? Throw the error
    if(!DirSetCWD(strWorkDir))
      XCL("Failed to set working directory!", "Directory", strWorkDir);
    // We are changing the value ourselves...
    strV = StdMove(strWorkDir);
    // ...so make sure the cvar system knows
    return ACCEPT_HANDLED;
  }
  /* -- Set throw error on elevated priviliedges --------------------------- */
  CVarReturn CheckAdminModified(const unsigned int uiMode)
  { // Valid modes allowed
    enum Mode { AM_OK,                 // [0] Running as admin is okay?
                AM_NOTOK,              // [1] Running as admin is not okay?
                AM_NOTOKIFMODERNOS };  // [2] As above but not if OS is modern?
    // Check mode
    switch(static_cast<Mode>(uiMode))
    { // Return if OS uses admin as default for accounts else fall through
      case AM_NOTOKIFMODERNOS: if(OSIsAdminDefault()) return ACCEPT;
                               [[fallthrough]];
      // Break to error if running as admin else fall through to accept
      case AM_NOTOK: if(OSIsAdmin()) break;
                     [[fallthrough]];
      // Don't care if running as admin.
      case AM_OK: return ACCEPT;
      // Unknown parameter
      default: return DENY;
    }// Throw error
    XC("You are running this software with elevated privileges which can be "
       "dangerous and thus has been blocked on request by the guest. Please "
       "restart this software with reduced privileges.");
  }
  /* ----------------------------------------------------------------------- */
  const CoreFlagsConst GetCoreFlags(void) const { return cfMode; }
  bool IsCoreFlagsHave(const CoreFlagsConst cfFlags) const
    { return !cfFlags || GetCoreFlags().FlagIsSet(cfFlags); }
  bool IsGraphicalMode(void) const
    { return GetCoreFlags().FlagIsSet(CF_VIDEO); }
  bool IsNotGraphicalMode(void) const { return !IsGraphicalMode(); }
  bool IsTextMode(void) const
    { return GetCoreFlags().FlagIsSet(CF_TERMINAL); }
  bool IsNotTextMode(void) const { return !IsTextMode(); }
  bool IsAudioMode(void) const
    { return GetCoreFlags().FlagIsSet(CF_AUDIO); }
  bool IsNotAudioMode(void) const { return !IsAudioMode(); }
  /* -- Return users roaming directory ------------------------------------- */
  const string &GetRoamingDir(void) const { return strRoamingDir; }
  /* ----------------------------------------------------------------------- */
  const string &GetCoreFlagsString(const CoreFlagsConst cfFlags) const
    { return mList.Get(cfFlags); }
  /* ----------------------------------------------------------------------- */
  const string &GetCoreFlagsString(void) const
    { return GetCoreFlagsString(GetCoreFlags()); }
  /* -- Default error handler ---------------------------------------------- */
  static void CriticalHandler[[noreturn]](const char*const cpMessage)
  { // Show message box with error
    cLog->LogNLCErrorExSafe("Critical error: $!", cpMessage);
    // Abort and crash
    abort();
  }
  /* -- Default constructor ------------------------------------------------ */
  System(void) :
  /* -- Initialisers ----------------------------------------------------- */
    mList{{                            // Initialise mode strings list
      "nothing",                       // [0<    0>] (nothing)
      "text",                          // [1<    1>] (text)
      "audio",                         // [2<    2>] (audio)
      "text+audio",                    // [3<  1|2>] (text+audio)
      "video",                         // [4<    4>] (video)
      "text+video",                    // [5<  1|4>] (video+text)
      "audio+video",                   // [6<  2|4>] (video+audio)
      "text+audio+video",              // [7<1|2|4>] (text+audio+video)
    }},                                // Mode strings list initialised
    cfMode(CF_MASK),                   // Guimode initially set by cvars
    tdhCPU{ seconds{ 1 } },            // Cpu refresh time is one seconds
    stProcessId(GetPid<size_t>()),     // Init readable proceess id
    stThreadId(GetTid<size_t>()),      // Init readable thread id
    thHandler(set_terminate(           // Store current termination handler
      TerminateHandler)),              // " Use our termination handler
    uhHandler(set_unexpected(          // Store current unexpected handler
      UnexpectedHandler)),             // " Use our unexpected handler
    strRoamingDir{                     // Set user roaming directory
      PSplitBackToForwardSlashes(      // Convert backward slashes to forward
        BuildRoamingDir()) }           // Get roaming directory from system
  /* -- Code --------------------------------------------------------------- */
  { // Update cpu and memory usage data
    UpdateCPUUsage();
    UpdateMemoryUsageData();
    // Log information about the environment
    cLog->LogNLCInfoExSafe("$ v$.$.$.$ ($) for $.\n"
       "+ Executable is $.\n"
       "+ Created at $ with $ v$.\n"
       "+ Checksum $ with $<0x$$$> expecting $<0x$$$>.\n"
       "+ Working directory is $.\n"
       "+ Persistent directory is $.\n"
       "+ Process id is $<0x$$$> with main thread id of $<0x$$$>.\n"
       "+ Priority is $<0x$$$> with affinity $<0x$$$> and mask $<0x$$$>.\n"
       "+ Processor is $ <$ x $ MHz>.\n"
       "+ Type is $<0x$$$>.\n"
       "+ Memory has $ with $ free and $ Initial.\n"
       "+ System is $ v$.$.$ ($-bit) in $$.\n"
       "+ Expire$ at $.\n"
       "+ Uptime is $.\n"
       "+ Clock is $.\n"
       "+ UTC clock is $.\n"
       "+ Admin is $ and Bundled is $.",
      ENGName(), ENGMajor(), ENGMinor(), ENGBuild(), ENGRevision(),
        ENGBuildType(), ENGTarget(),
      ENGFull(), ENGCompiled(), ENGCompiler(), ENGCompVer(),
      EXEModified() ? "failed" : "verified",
        exeData.ulHeaderSum, hex, exeData.ulHeaderSum, dec,
        exeData.ulCheckSum, hex, exeData.ulCheckSum, dec,
      cCmdLine->GetStartupCWD(),
      GetRoamingDir(),
      GetReadablePid(), hex, GetReadablePid(), dec,
        GetReadableTid(), hex, GetReadableTid(), dec,
        GetPriority(), hex, GetPriority(), dec,
        GetAffinity(false), hex, GetAffinity(false), dec,
        GetAffinity(true), hex, GetAffinity(true), dec,
      CPUName(), CPUCount(), CPUSpeed(),
        CPUIdentifier(), hex, CPUFeatures(), dec,
      ToBytesStr(RAMTotal()), ToBytesStr(RAMFree()), ToBytesStr(RAMProcUse()),
      OSName(), OSMajor(), OSMinor(), OSBuild(), OSBits(), OSLocale(),
        IsOSNameExSet() ? Append(" via ", OSNameEx()) : cCommon->Blank(),
      OSExpired() ? "d" : "s", FormatTimeTT(OSExpiry()),
      cmHiRes.ToDurationLongString(),
      cmSys.FormatTime(), cmSys.FormatTimeUTC(),
      TrueOrFalse(OSIsAdmin()), TrueOrFalse(EXEBundled()));
  }
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(System)              // Disable copy constructor and operator
  /* ----------------------------------------------------------------------- */
} *cSystem = nullptr;                  // Pointer to static class
/* -- Default handler for std::unexpected ---------------------------------- */
void System::UnexpectedHandler(void)
  { cSystem->SysMsgTerm(-1, "An unhandled exception has occurred!"); }
/* -- Default handler for std::terminate ----------------------------------- */
void System::TerminateHandler(void)
  { cSystem->SysMsgTerm(-2, "Abnormal program termination!"); }
/* -- Pre-defined SysBase callbacks that require access to cSystem global -- */
MSENGINE_SYSBASE_CALLBACKS();          // Parse requested SysBase callbacks
#undef MSENGINE_SYSBASE_CALLBACKS      // Done with this
/* -- Pre-defined SysCon callbacks that require access to cSystem global --- */
MSENGINE_SYSCON_CALLBACKS();           // Parse requested SysCon callbacks
#undef MSENGINE_SYSCON_CALLBACKS       // Done with this
/* ------------------------------------------------------------------------- */
};                                     // End of module namespace
/* == EoF =========================================================== EoF == */

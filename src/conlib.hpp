/* == CONLIB.HPP =========================================================== **
** ######################################################################### **
** ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## **
** ######################################################################### **
** ## This module is included inside the main procedure in 'core.cpp' and ## **
** ## handles all the default console cvars. Make sure to update the      ## **
** ## 'ConCmdEnums' enum scope if you modify the order, remove or add     ## **
** ## new console commands.                                               ## **
** ######################################################################### **
** ========================================================================= */
#pragma once                           // Only one incursion allowed
/* ========================================================================= */
const ConCmdStaticList ccslList{{      // Default console commands list
/* ========================================================================= */
// ! archives
// ? Lists archive objects that are loaded into the game engine.
/* ------------------------------------------------------------------------- */
{ "archives", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Get reference to assets collector class and lock it so it's not changed
const LockGuard lgAssetsSync{ cArchives->CollectorGetMutex() };
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("F").Header("D").Header("T").Header("U")
      .Header("FILENAME", false).Reserve(cArchives->size());
// Total resources
uint64_t uqResources = 0;
// Walk through archives
for(const Archive*const aPtr : *cArchives)
{ // Get reference to class and
  const Archive &aRef = *aPtr;
  sTable.DataN(aRef.CtrGet()).DataN(aRef.GetFileList().size())
        .DataN(aRef.GetDirList().size()).DataN(aRef.GetTotal())
        .DataN(aRef.GetInUse()).Data(aRef.IdentGet());
  // Add to resources total
  uqResources += aRef.GetFileList().size();
} // Show count
cConsole->AddLineF("$$ and $.", sTable.Finish(),
  StrCPluraliseNum(cArchives->size(), "archive", "archives"),
  StrCPluraliseNum(uqResources, "resource", "resources"));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'archives' function
/* ========================================================================= */
// ! areset
// ? Resets the audio interface.
/* ------------------------------------------------------------------------- */
{ "areset", 1, 1, CFL_AUDIO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Reset the audio subsystem and print result of the reset call
cConsole->AddLineA("Audio subsystem reset ",
  cAudio->ReInit() ? "requested." : "failed.");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'areset' function
/* ========================================================================= */
// ! assets
// ? Lists assets that are loaded into the game engine.
/* ------------------------------------------------------------------------- */
{ "assets", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Get reference to arrays collector class and lock it so it's not changed
const LockGuard lgAssetsSync{ cAssets->CollectorGetMutex() };
// Size of all blocks
size_t stTotal = 0;
// Number of bytes to show
const size_t stCount = 16;
// Preview of block and reserve memory for it
string strHex; strHex.reserve(stCount * 3);
string strAscii; strAscii.reserve(stCount);
// Memory data
Statistic sTable;
sTable.Header("ID").Header("BYTES").Header("PREVIEW", false)
      .Header("ASCII", false).Reserve(cAssets->size());
// Walk mask list and add size of it
for(const Asset *aPtr : *cAssets)
{ // Get reference to class
  const Asset &aRef = *aPtr;
  // Set preview size
  const size_t stMax = UtilMinimum(aRef.MemSize(), stCount);
  // Set id and size
  sTable.DataN(aRef.CtrGet()).DataN(aRef.MemSize());
  // Clear preview strings
  strHex.clear();
  strAscii.clear();
  // Show first sixteen bytes
  for(size_t stIndex = 0; stIndex < stMax; ++stIndex)
  { // Get character
    const unsigned int uiChar =
      static_cast<unsigned int>(aRef.MemReadInt<uint8_t>(stIndex));
    // Add hex of block
    strHex += StrHexFromInt(uiChar, 2) + ' ';
    // Put a dot if character is invalid
    if(uiChar < ' ') { strAscii += '.'; continue; }
    // Encode the character
    UtfAppend(uiChar, strAscii);
  } // Add padding for characters that don't exist
  for(size_t stIndex = stMax; stIndex < stCount; ++stIndex)
    { strHex += ".. "; strAscii += ' '; }
  // Remove space on hex
  strHex.pop_back();
  // Write line to log
  sTable.Data(strHex).Data(strAscii);
  // Add size of this array to the total size of all arrays
  stTotal += aRef.MemSize();
} // Number of items in buffer. We're not showing data in release mode.
cConsole->AddLineF("$$ totalling $.", sTable.Finish(),
  StrCPluraliseNum(cAssets->size(), "block", "blocks"),
  StrCPluraliseNum(stTotal, "byte", "bytes"));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'assets' function
/* ========================================================================= */
// ! audins
// ? Lists available audio input devices (unused by engine right now).
/* ------------------------------------------------------------------------- */
{ "audins", 1, 1, CFL_AUDIO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Ignore if no audio subsystem initialised
if(!cOal->IsInitialised()) return cConsole->AddLine("Audio not initialised.");
// Data for device output
Statistic sTable;
sTable.Header("ID").Header("INPUT DEVICE", false)
      .Reserve(cAudio->GetNumCaptureDevices());
// list audio devices
size_t stDeviceId = 0;
for(const string &strName : cAudio->GetCTDevices())
  sTable.DataN(stDeviceId++).Data(strName);
// Output devices
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(stDeviceId, "device.", "devices."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'audins' function
/* ========================================================================= */
// ! audio
// ? Shows information about the currently loaded audio device.
/* ------------------------------------------------------------------------- */
{ "audio", 1, 1, CFL_AUDIO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Write information about current audio device
cConsole->AddLineF(
   "Library: OpenAL $; Flags: $ (0x$$$).\n"
   "Playback: $.\n"
   "Sources: $ allocated (Max $ Stereo; $ Mono).",
  cOal->GetVersion(),
  StrFromEvalTokens({
    { cOal->FlagIsSet(AFL_INITCONTEXT),     'C' },
    { cOal->FlagIsSet(AFL_INITDEVICE),      'D' },
    { cOal->FlagIsSet(AFL_HAVE32FPPB),      'F' },
    { cOal->FlagIsSet(AFL_INITIALISED),     'I' },
    { cOal->FlagIsSet(AFL_INFINITESOURCES), 'S' },
    { cOal->FlagIsSet(AFL_HAVEENUMEXT),     'X' },
  }),
  hex, cOal->FlagGet(), dec,
  cOal->GetPlaybackDevice(),
  cSources->size(), cOal->GetMaxStereoSources(), cOal->GetMaxMonoSources());
/* ------------------------------------------------------------------------- */
} },                                   // End of 'audio' function
/* ========================================================================= */
// ! audouts
// ? Lists available audio output devices.
/* ------------------------------------------------------------------------- */
{ "audouts", 1, 1, CFL_AUDIO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Ignore if no audio subsystem initialised
if(!cOal->IsInitialised()) return cConsole->AddLine("Audio not initialised.");
// Data for device output
Statistic sTable;
sTable.Header("ID").Header("OUTPUT DEVICE", false)
      .Reserve(cAudio->GetNumPlaybackDevices());
// list audio devices
size_t stDeviceId = 0;
for(const string &strName : cAudio->GetPBDevices())
  sTable.DataN(stDeviceId++).Data(strName);
// Output devices
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(stDeviceId, "device.", "devices."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'audouts' function
/* ========================================================================= */
// ! bins
// ? Lists currently loaded bin objects.
/* ------------------------------------------------------------------------- */
{ "bins", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("WIDTH").Header("HEIGHT").Header("OCCUPANCY").Header("TOTL")
      .Header("USED").Header("FREE").Reserve(cBins->size());
// Walk through textures classes
for(const Bin*const bPtr : *cBins)
{ // Get reference to class and write its data to the table
  const Bin &bRef = *bPtr;
  sTable.DataN(bRef.DimGetWidth()).DataN(bRef.DimGetHeight())
        .DataN(bRef.Occupancy(), 7).DataN(bRef.Total()).DataN(bRef.Used())
        .DataN(bRef.Free());
} // Log counts
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cBins->size(), "bin.", "bins."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'bins' function
/* ========================================================================= */
// ! certs
// ? Lists currently loaded X509 certificates which are populated by the
// ? 'net_castore' cvar on startup.
/* ------------------------------------------------------------------------- */
{ "certs", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Make a table to automatically format our data neatly
Statistic sTable;
sTable.Header("X").Header("FILE", false).Header("C", false)
      .Header("CN", false).Reserve(cSockets->size());
// Walk shader list
for(const Certs::X509Pair &xPair : cSockets->GetCertList())
{ // Put if expired and the filename on disk
  sTable.Data(StrFromBoolYN(CertIsExpired(xPair.second))).Data(xPair.first);
  // Split subject key/value pairs. We couldn't split the data if empty
  const ParserConst<>
    pSubject{ CertGetSubject(xPair), cCommon->FSlash(), '=' };
  if(pSubject.empty()) { sTable.Data("??").Data("<No sub>"); continue; }
  // Print country and certificate name
  const StrStrMapConstIt iC{ pSubject.find("C") }, iCN{ pSubject.find("CN") };
  sTable.Data(iC == pSubject.cend() ? "--" : CryptURLDecode(iC->second))
        .Data(iCN == pSubject.cend() ?
          cCommon->Unspec() : CryptURLDecode(iCN->second));
} // Print output and number of shaders listed
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cSockets->GetCertListSize(),
    "root certificate.", "root certificates."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'certs' function
/* ========================================================================= */
// ! cla
// ? Lists all command-line arguments sent to the process.
/* ------------------------------------------------------------------------- */
{ "cla", 1, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Get list of environment variables
const StrVector &svArgs = cCmdLine->GetArgList();
// If parameter was specified?
if(aArgs.size() > 1)
{ // Convert parmeter to number
  const size_t stArg = StrToNum<size_t>(aArgs[1]);
  if(stArg >= svArgs.size())
    return cConsole->AddLine("Command line argument index invalid!");
  // Print it and return
  return cConsole->AddLine(svArgs[stArg]);
} // Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("ARGUMENT", false).Reserve(svArgs.size());
// Walk through environment variables add them to the statistic object
size_t stCount = 0;
for(const string &strArg : svArgs) sTable.DataN(stCount++).Data(strArg);
// Log counts
cConsole->AddLineA(sTable.Finish(), StrCPluraliseNum(stCount,
  "command line argument.",  "command line arguments."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'cla' function
/* ========================================================================= */
// ! clh
// ? Flushes the historic use of commands entered into the console.
/* ------------------------------------------------------------------------- */
{ "clh", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
cConsole->ClearHistory();
/* ------------------------------------------------------------------------- */
} },                                   // End of 'clh' function
/* ========================================================================= */
// ! cls
// ? Flushes the console output buffer.
/* ------------------------------------------------------------------------- */
{ "cls", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
cConsole->Flush();
/* ------------------------------------------------------------------------- */
} },                                   // End of 'cls' function
/* ========================================================================= */
// ! cmds
// ? Shows all the available console commands. You can optionally specify
// ? an argument to partially match the beginning of each command.
/* ------------------------------------------------------------------------- */
{ "cmds", 1, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Build commands list and if commands were matched? Print them all
string strMatched;
if(const size_t stMatched = CommandsBuildList(cConsole->GetCmdsList(),
     aArgs.size() > 1 ? aArgs[1] : cCommon->Blank(), strMatched))
  cConsole->AddLineF("$:$.", StrCPluraliseNum(stMatched,
    "matching command", "matching commands"), strMatched);
// No commands matched
else cConsole->AddLineF("No match from $.",
  StrCPluraliseNum(cConsole->GetCmdsList().size(), "command", "commands"));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'cmds' function
/* ========================================================================= */
// ! con
// ? No explanation yet.
/* ========================================================================= */
{ "con", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Write console status
cConsole->AddLineF("Console flags are currently 0x$$$ ($).\n"
                    "- Output lines: $ (Maximum: $).\n"
                    "- Input commands: $ (Maximum: $).\n"
                    "- Engine commands: $.",
  hex, cConsole->FlagGet(), dec, StrFromEvalTokens({
    { cConsole->FlagIsSet(CF_CANTDISABLE), 'D' },
    { cConsole->FlagIsSet(CF_IGNOREKEY),   'K' },
    { cConsole->FlagIsSet(CF_AUTOSCROLL),  'A' },
    { cConsole->FlagIsSet(CF_AUTOCOPYCVAR),'C' },
    { cConsole->FlagIsSet(CF_INSERT),      'I' },
    { cConsole->FlagIsSet(CF_ENABLED),     'E' }
  }),
  cConsole->GetOutputCount(), cConsole->GetOutputMaximum(),
  cConsole->GetInputCount(), cConsole->GetInputMaximum(),
  cConsole->GetCmdsList().size());
/* ------------------------------------------------------------------------- */
} },                                   // End of 'con' function
/* ========================================================================= */
// ! conlog
// ? No explanation yet.
/* ========================================================================= */
{ "conlog", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Copy all the console lines to log and report how many lines we copied
cConsole->AddLineA(StrCPluraliseNum(cConsole->ToLog(), "line", "lines"),
  " copied to log.");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'conlog' function
/* ========================================================================= */
// ! cpu
// ? No explanation yet.
/* ========================================================================= */
{ "cpu", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Update cpu usage times
cSystem->UpdateCPUUsage();
// Write detected processor information
cConsole->AddLineF(
  "$$x$MHz/$ (FMS:$;$;$); Load: $% ($%).\n"
  "Start: $; Last: $; Limit: $; Accu: $.\n"
  "Mode: $ ($); TimeOut: $ ($x$); Ticks: $.\n"
  "FPS: $/s ($/s); Eff: $%; Delay: $/s.",
    fixed, cSystem->CPUCount(), cSystem->CPUSpeed(), cSystem->CPUName(),
      cSystem->CPUFamily(), cSystem->CPUModel(), cSystem->CPUStepping(),
      cSystem->CPUUsage(), cSystem->CPUUsageSystem(),
    cTimer->TimerGetStart(), cTimer->TimerGetDuration(),
      cTimer->TimerGetLimit(), cTimer->TimerGetAccumulator(),
    cSystem->GetCoreFlags(), cSystem->GetCoreFlagsString(),
      cTimer->TimerGetTimeOut(), cTimer->TimerGetTriggers(),
      cLua->GetOpsInterval(), cTimer->TimerGetTicks(),
    cTimer->TimerGetFPS(), cTimer->TimerGetFPSLimit(),
      UtilMakePercentage(cTimer->TimerGetFPS(), cTimer->TimerGetFPSLimit()),
      cTimer->TimerGetDelay());
/* ------------------------------------------------------------------------- */
} },                                   // End of 'cpu' function
/* ========================================================================= */
// ! crash
// ? No explanation yet.
/* ========================================================================= */
{ "crash", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
System::CriticalHandler("Requested operation");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'crash' function
/* ========================================================================= */
// ! credits
// ? No explanation yet.
/* ========================================================================= */
{ "credits", 1, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Do we have a parameter?
if(aArgs.size() > 1)
{  // Get index and show decompressed text for it or invalid
  const size_t stIndex = StrToNum<size_t>(aArgs[1]);
  return cConsole->AddLine(stIndex >= cCredits->CreditGetItemCount() ?
    "The specified credit index is invalid!" :
    cCredits->CreditGetItemText(static_cast<CreditEnums>(stIndex)));
} // Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("NAME", false).Header("VERSION")
      .Header("AUTHOR", false).Reserve(cCredits->CreditGetItemCount());
// For each item, show library information
for(const CreditLib &clRef : *cCredits)
  sTable.DataN(clRef.GetID()).Data(clRef.GetName()).Data(clRef.GetVersion())
        .DataA(clRef.IsCopyright() ?
    "\xC2\xA9 " : cCommon->Blank(), clRef.GetAuthor());
// Show number of libs
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cCredits->CreditGetItemCount(),
    "third-party library.", "third-party libraries."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'credits' function
/* ========================================================================= */
// ! cvars
// ? No explanation yet.
/* ========================================================================= */
{ "cvars", 1, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
cConsole->AddLine(VariablesMakeList(cCVars->GetVarList(),
  aArgs.size() > 1 ? aArgs[1] : cCommon->Blank()));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'cvars' function
/* ========================================================================= */
// ! cvclr
// ? No explanation yet.
/* ========================================================================= */
{ "cvclr", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
cConsole->AddLineA(StrCPluraliseNum(cCVars->Clean(),
  "cvar", "cvars"), " purged.");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'cvclr' function
/* ========================================================================= */
// ! cvload
// ? No explanation yet.
/* ========================================================================= */
{ "cvload", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
cConsole->AddLineA(StrCPluraliseNum(cCVars->LoadFromDatabase(),
  "cvar", "cvars"), " reloaded.");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'cvload' function
/* ========================================================================= */
// ! cvnpk
// ? No explanation yet.
/* ========================================================================= */
{ "cvnpk", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Create the private key and if succeeded? Show the result
if(cSql->CreatePrivateKey())
  cConsole->AddLineF("New private key set and $ variables re-encoded!",
    cCVars->MarkAllEncodedVarsAsCommit());
// Else failed so show the error
else cConsole->AddLine("Failed to create new private key!");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'cvnpk' function
/* ========================================================================= */
// ! cvpend
// ? No explanation yet.
/* ========================================================================= */
{ "cvpend", 1, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
cConsole->AddLine(VariablesMakeList(cCVars->GetInitialVarList(),
  aArgs.size() > 1 ? aArgs[1] : cCommon->Blank()));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'cvpend' function
/* ========================================================================= */
// ! cvsave
// ? No explanation yet.
/* ========================================================================= */
{ "cvsave", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
cConsole->AddLineA(StrCPluraliseNum(cCVars->Save(), "cvar", "cvars"),
  " commited.");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'cvsave' function
/* ========================================================================= */
// ! dir
// ? No explanation yet.
/* ========================================================================= */
{ "dir", 1, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Make and checkfilename
const string &strVal = aArgs.size() > 1 ? aArgs[1] : ".";
const ValidResult vrResult = DirValidName(strVal);
if(vrResult != VR_OK)
  return cConsole->AddLineF("Cannot check directory '$': $!",
    strVal, cDirBase->VNRtoStr(vrResult));
// Enumerate local directories on disk
const Dir dPath{ StdMove(strVal) };
// Set directory and get directories and files
const string &strDir = aArgs.size() > 1 ? aArgs[1] : cCommon->Blank();
// Directory data we are enumerating
struct Item { const uint64_t uqSize;
              const unsigned int uiId;
              const string &strArc; };
typedef pair<const string, const Item> StrItemPair;
typedef map<StrItemPair::first_type, StrItemPair::second_type> StrItemList;
StrItemList silDirs, silFiles;
// Get reference to assets collector class and lock it so it's not changed
const LockGuard lgArchivesSync{ cArchives->CollectorGetMutex() };
// Iterate through the list
for(const Archive*const aPtr : *cArchives)
{ // Get reference to class
  const Archive &aRef = *aPtr;
  // Goto next archive if directory specified and is not found
  const StrUIntMap &suimDirs = aRef.GetDirList();
  if(!strDir.empty() && !suimDirs.contains(strDir)) continue;
  // Enumerate directories
  for(const StrUIntMapPair &suimpPair : suimDirs)
  { // Skip directory if start of directory does not match
    if(strDir != suimpPair.first.substr(0, strDir.length())) continue;
    // Get filename, and continue again if it is a sub-directory/file
    string strName{ StrTrim(suimpPair.first.substr(strDir.length()), '/') };
    if(strName.find('/') != string::npos) continue;
    // Add to directory list and increment directory count
    silDirs.insert({ StdMove(strName),
      { StdMaxUInt64, suimpPair.second, aRef.IdentGet() } });
  } // Enumerate all files in archive
  const StrUIntMap &suimFiles = aRef.GetFileList();
  for(const StrUIntMapPair &suimpPair : suimFiles)
  { // Skip file if start of directory does not match
    if(strDir != suimpPair.first.substr(0, strDir.length())) continue;
    // Get filename, and continue again if it is a sub-directory/file
    string strName{ StrTrim(suimpPair.first.substr(strDir.length()), '/') };
    if(strName.find('/') != string::npos) continue;
    // Add to file list and increment total bytes and file count
    const uint64_t uqSize = aRef.GetSize(suimpPair.second);
    silFiles.insert({ StdMove(strName),
      { uqSize, suimpPair.second, aRef.IdentGet() } });
  }
} // Enumerate local directories and add each entry to file list
for(const DirEntMapPair &dempPair : dPath.GetDirs())
  silDirs.insert({ StdMove(dempPair.first),
    { StdMaxUInt64, StdMaxUInt, {} } });
// Enumerate local files
for(const DirEntMapPair &dempPair : dPath.GetFiles())
{ // Add to file list and increment byte and file count
  const DirItem &diFile = dempPair.second;
  silFiles.insert({ StdMove(dempPair.first),
    { diFile.Size(), StdMaxUInt, {} } });
} // Directory name and disk name strings
const string strDirName{"<DIR>"}, strDiskName{"<DISK>"};
// Prepare data table for archive display
Statistic sTable;
sTable.Header("SIZE").Header().Header("ID").Header("ARCHIVE", false)
      .Header("FILENAME", false).Reserve(silDirs.size() + silFiles.size());
// For each directory we found
for(const StrItemPair &sipPair : silDirs)
{ // Get item data
  const Item &itData = sipPair.second;
  // Add directory tag and blank cell
  sTable.Data(strDirName).Data();
  // If this is a file on disk?
  if(itData.uiId == StdMaxUInt) sTable.Data().Data(strDiskName);
  // Is from archive?
  else sTable.DataN(itData.uiId).Data(itData.strArc);
  // Add directory name
  sTable.Data(StdMove(sipPair.first));
} // Files and directories and total bytes matched
uint64_t qwBytes = 0;
// For each file we found
for(const StrItemPair &sipPair : silFiles)
{ // Get item data
  const Item &itData = sipPair.second;
  // Add size and humann readable size
  sTable.DataN(itData.uqSize).Data(StrToBytes(itData.uqSize));
  // If this is a file on disk?
  if(itData.uiId == StdMaxUInt) sTable.Data().Data(strDiskName);
  // Is from archive?
  else sTable.DataN(itData.uiId).Data(itData.strArc);
  // Add file name
  sTable.Data(StdMove(sipPair.first));
  // Add to file size
  qwBytes += itData.uqSize;
} // Show summary
cConsole->AddLineF("$$ and $ totalling $ ($) in $.",
  sTable.Finish(),
  StrCPluraliseNum(silFiles.size(), "files", "files"),
  StrCPluraliseNum(silDirs.size(), "dir", "dirs"),
  StrCPluraliseNum(qwBytes, "byte", "bytes"),
  StrToBytes(qwBytes),
  StrCPluraliseNum(cArchives->size(), "archive", "archives"));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'dir' function
/* ========================================================================= */
// ! env
// ? No explanation yet.
/* ========================================================================= */
{ "env", 1, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Get list of environment variables
const StrStrMap &ssmEnv = cCmdLine->GetEnvList();
// If parameter was specified?
if(aArgs.size() > 1)
{ // Get parameter name and find it
  const StrStrMapConstIt &ssmciVar = ssmEnv.find(aArgs[1]);
  if(ssmciVar == ssmEnv.cend())
    return cConsole->AddLine("Environment variable not found!");
  // Print it and return
  cConsole->AddLineA(ssmciVar->first, '=', ssmciVar->second);
  return;
} // Text table class to help us write neat output
Statistic sTable;
sTable.Header("VARIABLE").Header("VALUE", false).Reserve(ssmEnv.size());
// Walk through environment variables add them to the statistic object
for(const StrStrMapPair &ssmpVar : ssmEnv)
  sTable.Data(ssmpVar.first).Data(ssmpVar.second);
// Log counts
cConsole->AddLineA(sTable.Finish(), StrCPluraliseNum(ssmEnv.size(),
  "environment variable.", "environment variables."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'env' function
/* ========================================================================= */
// ! events
// ? No explanation yet.
/* ========================================================================= */
{ "events", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Log event counts
cConsole->AddLineF("$ and $.",
  StrCPluraliseNum(cEvtMain->SizeSafe(), "engine event", "engine events"),
  StrCPluraliseNum(cEvtWin->SizeSafe(), "window event", "window events"));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'events' function
/* ========================================================================= */
// ! fbos
// ? No explanation yet.
/* ========================================================================= */
{ "fbos", 1, 1, CFL_VIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
const function ShowFboInfo{ [](const Fbo &fRef, Statistic &sTable,
  size_t &stTriangles, size_t &stCommands)
{ // Add to totals
  stTriangles += fRef.FboGetTris();
  stCommands += fRef.FboGetCmds();
  // Show FBO status
  sTable.DataN(fRef.CtrGet()).DataN(fRef.uiFBO).DataN(fRef.uiFBOtex)
       .Data(StrFromEvalTokens({
          { fRef.FboIsTransparencyEnabled(), 'A' },
          { fRef.FboIsClearEnabled(),        'C' },
       }))
       .DataN(fRef.FboGetFilter()).DataN(fRef.DimGetWidth())
       .DataN(fRef.DimGetHeight()).DataN(fRef.ffcStage.GetCoLeft())
       .DataN(fRef.ffcStage.GetCoTop()).DataN(fRef.ffcStage.GetCoRight())
       .DataN(fRef.ffcStage.GetCoBottom()).DataN(fRef.FboGetTris())
       .DataN(fRef.FboGetCmds()).DataN(fRef.FboGetTrisReserved())
       .DataN(fRef.FboGetCmdsReserved()).Data(fRef.IdentGet());
} };
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("FI").Header("TI").Header("FL").Header("FT")
      .Header("SIZW").Header("SIZH").Header("STX1").Header("STY1")
      .Header("STX2").Header("STY2").Header("TRIS").Header("CMDS")
      .Header("TRES").Header("CRES").Header("IDENTIFIER", false)
      .Reserve(2 + cFbos->size());
// Total triangles and commands
size_t stTriangles = 0, stCommands = 0;
// Show primary fbos info
ShowFboInfo(cFboCore->fboMain, sTable, stTriangles, stCommands);
ShowFboInfo(cFboCore->fboConsole, sTable, stTriangles, stCommands);
// Enumerate fbo and video classes and show their infos
for(const Fbo*const fPtr : *cFbos)
  ShowFboInfo(*fPtr, sTable, stTriangles, stCommands);
for(const Video*const vPtr : *cVideos)
  ShowFboInfo(*vPtr, sTable, stTriangles, stCommands);
// Log counts
cConsole->AddLineF("$$ totalling $ and $.", sTable.Finish(),
  StrCPluraliseNum(2 + cFbos->size(), "framebuffer", "framebuffers"),
  StrCPluraliseNum(stTriangles, "triangle", "triangles"),
  StrCPluraliseNum(stCommands, "command", "commands"));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'fbos' function
/* ========================================================================= */
// ! files
// ? No explanation yet.
/* ========================================================================= */
{ "files", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("FLAG").Header("FD").Header("ERRNO")
      .Header("POSITION").Header("LENGTH").Header("FILENAME", false)
      .Reserve(cFiles->size());
// Walk through textures classes
for(File*const fPtr : *cFiles)
{ // Get reference to class and write its data to the table
  File &fRef = *fPtr;
  sTable.DataN(fRef.CtrGet()).Data(StrFromEvalTokens({
    { fRef.FStreamOpened(),    'O' }, { fRef.FStreamFErrorSafe(), 'E' },
    { fRef.FStreamIsEOFSafe(), 'X' }
  })).DataN(fRef.FStreamGetIDSafe()).DataN(fRef.FStreamGetErrNo())
     .DataN(fRef.FStreamTellSafe()).DataN(fRef.FStreamSizeSafe())
     .Data(fRef.IdentGet());
} // Log counts
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cFiles->size(), "file.", "files."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'files' function
/* ========================================================================= */
// ! find
// ? No explanation yet.
/* ========================================================================= */
{ "find", 2, 0, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Find text in console backlog and if not found, show message
cConsole->FindText(StrImplode(aArgs, 1));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'find' function
/* ========================================================================= */
// ! fonts
// ? No explanation yet.
/* ========================================================================= */
{ "fonts", 1, 1, CFL_VIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
const function ShowFontInfo{ [](Statistic &sTable, const Font &fRef)
  { sTable.DataN(fRef.CtrGet())
          .DataC(fRef.FlagIsSet(FF_FLOORADVANCE) ? 'F' :
                (fRef.FlagIsSet(FF_CEILADVANCE)  ? 'C' :
                (fRef.FlagIsSet(FF_ROUNDADVANCE) ? 'R' : '-')))
          .Data(StrFromEvalTokens({
            { fRef.FlagIsSet(FF_USEGLYPHSIZE), 'S' },
            { fRef.FlagIsSet(FF_STROKETYPE2),  'A' }
          }))
          .DataN(fRef.GetCharScale(), 6).DataN(fRef.GetTexOccupancy(), 6)
          .DataN(fRef.GetCharCount()).Data(fRef.IdentGet()); }
}; // Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("R").Header("FLAG").Header("SCALE")
      .Header("TEXOCPCY").Header("CC").Header("NAME", false)
      .Reserve(1 + cFonts->size());
// Include console font
ShowFontInfo(sTable, cConGraphics->GetFontRef());
// Walk through textures classes
for(const Font*const fPtr : *cFonts) ShowFontInfo(sTable, *fPtr);
// Log counts including the static console font class
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cFonts->size() + 1, "font.", "fonts."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'fonts' function
/* ========================================================================= */
// ! ftfs
// ? No explanation yet.
/* ========================================================================= */
{ "ftfs", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Get reference to fonts collector class and lock it so it's not changed
const LockGuard lgFtfsSync{ cFtfs->CollectorGetMutex() };
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("GLYPH").Header("FW").Header("FH").Header("DW")
      .Header("DH").Header("STYLE", false).Header("FAMILY", false)
      .Header("FILENAME", false).Reserve(cFtfs->size());
// Walk through textures classes
for(const Ftf*const fPtr : *cFtfs)
{ // Get reference to class and write its data to the table
  const Ftf &fRef = *fPtr;
  sTable.DataN(fRef.CtrGet()).DataN(fRef.GetGlyphCount())
        .DataN(fRef.DimGetWidth(),0).DataN(fRef.DimGetHeight(),0)
        .DataN(fRef.diDPI.DimGetWidth()).DataN(fRef.diDPI.DimGetHeight())
        .Data(fRef.GetStyle()).Data(fRef.GetFamily())
        .Data(fRef.IdentGet());
} // Log counts
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cFtfs->size(), "ftf.", "ftfs."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'ftfs' function
/* ========================================================================= */
// ! gpu
// ? No explanation yet.
/* ========================================================================= */
{ "gpu", 1, 1, CFL_VIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Write opengl rendering stats
cConsole->AddLineF(
  "Renderer: $ on $.\n"
  "Version: $ by $.\n"
  "$" // Memory (optional)
  "Window: $x$ ($) @ $x$ (*$x$); DFlags: 0x$$.\n"
  "- State: $$ ($); Max: $^2; Viewport: $x$ ($).\n"
  "- Matrix: $x$ ($); Total: $x$ ($).\n"
  "- Stage: $,$,$,$; Fbo: $x$; OFlags: 0x$$.\n"
  "- Polygons: $$/$; Commands: $/$.\n"
  "FPS: $$/s ($/s); Eff: $%; Limit: $.",
  cOgl->GetRenderer(), cDisplay->GetMonitorName(),
  cOgl->GetVersion(), cOgl->GetVendor(),
  cOgl->FlagIsSet(GFL_HAVEMEM) ?
    StrFormat("Memory: $ mBytes ($ mBytes available).\n",
      cOgl->GetVRAMTotal() / 1048576, cOgl->GetVRAMFree() / 1048576) :
    cCommon->Blank(),
  cInput->GetWindowWidth(), cInput->GetWindowHeight(),
    StrFromRatio(cInput->GetWindowWidth(), cInput->GetWindowHeight()),
    cDisplay->GetWindowPosX(), cDisplay->GetWindowPosY(),
    cDisplay->GetWindowScaleWidth(), cDisplay->GetWindowScaleHeight(),
    hex, cDisplay->FlagGet(),
  dec, cDisplay->GetFSType(), cDisplay->GetFSTypeString(),
  cOgl->MaxTexSize(), cFboCore->DimGetWidth(), cFboCore->DimGetHeight(),
    StrFromRatio(cFboCore->DimGetWidth(), cFboCore->DimGetHeight()),
    cFboCore->GetMatrixWidth(), cFboCore->GetMatrixHeight(),
    StrFromRatio(cFboCore->GetMatrixWidth(), cFboCore->GetMatrixHeight()),
    cFboCore->fboMain.GetCoRight(), cFboCore->fboMain.GetCoBottom(),
    StrFromRatio(cFboCore->fboMain.GetCoRight(),
      cFboCore->fboMain.GetCoBottom()),
  cFboCore->fboMain.ffcStage.GetCoLeft(),
    cFboCore->fboMain.ffcStage.GetCoTop(),
    cFboCore->fboMain.ffcStage.GetCoRight(),
    cFboCore->fboMain.ffcStage.GetCoBottom(),
    cFboCore->fboMain.DimGetWidth(), cFboCore->fboMain.DimGetHeight(),
    hex, cOgl->FlagGet(),
  dec, cFboCore->fboMain.FboGetTris(),
    cFboCore->fboMain.FboGetTrisReserved(),
    cFboCore->fboMain.FboGetCmds(),
    cFboCore->fboMain.FboGetCmdsReserved(),
  fixed, cFboCore->dRTFPS, cDisplay->GetRefreshRate(),
  UtilMakePercentage(cFboCore->dRTFPS, cDisplay->GetRefreshRate()),
  cOgl->GetLimit());
/* ------------------------------------------------------------------------- */
} },                                   // End of 'gpu' function
/* ========================================================================= */
// ! images
// ? No explanation yet.
/* ========================================================================= */
{ "images", 1, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Get reference to images collector class and lock it so it's not changed
const LockGuard lgImagesSync{ cImages->CollectorGetMutex() };
// If we have more than one parameter?
if(aArgs.size() == 2)
{ // Get slot data and return if it is a bad slot
  const size_t stId = StrToNum<size_t>(aArgs[1]);
  if(stId >= cImages->size()) return cConsole->AddLine("Invalid image id!");
  const Image &iRef = **next(cImages->cbegin(), static_cast<ssize_t>(stId));
  // Text table class to help us write neat output
  Statistic sTable;
  sTable.Header("SIZX").Header("SIZY").Header("SIZE")
        .Reserve(iRef.GetSlotCount());
  // For each slot
  for(const ImageSlot &imdD : iRef.GetSlotsConst())
    sTable.DataN(imdD.DimGetWidth()).DataN(imdD.DimGetHeight())
          .DataN(imdD.MemSize());
  // Log texture counts
  cConsole->AddLineF("$$ in $.", sTable.Finish(),
    StrCPluraliseNum(iRef.GetSlotCount(), "slot", "slots"), iRef.IdentGet());
  // Done
  return;
} // Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("FLAGS", false).Header("SIZW").Header("SIZH")
      .Header("BI").Header("B").Header("S").Header("ALLOC")
      .Header("TYPE", false).Header("NAME", false).Reserve(cImages->size());
// Walk through textures classes
for(const Image*const iPtr : *cImages)
{ // Get reference to class and write its data to the table
  const Image &iRef = *iPtr;
  sTable.DataN(iRef.CtrGet()).Data(StrFromEvalTokens({
    { iRef.IsDynamic(),          'Y' }, { iRef.IsNotDynamic(),       'S' },
    { iRef.IsPurposeFont(),      'F' }, { iRef.IsPurposeImage(),     'I' },
    { iRef.IsPurposeTexture(),   'X' }, { iRef.IsLoadAsDDS(),        'D' },
    { iRef.IsLoadAsGIF(),        'G' }, { iRef.IsLoadAsJPG(),        'J' },
    { iRef.IsLoadAsPNG(),        'P' }, { iRef.IsConvertAtlas(),     'A' },
    { iRef.IsActiveAtlas(),      'a' }, { iRef.IsConvertReverse(),   'E' },
    { iRef.IsActiveReverse(),    'e' }, { iRef.IsConvertRGB(),       'H' },
    { iRef.IsActiveRGB(),        'h' }, { iRef.IsConvertRGBA(),      'D' },
    { iRef.IsActiveRGBA(),       'd' }, { iRef.IsConvertBGROrder(),  'W' },
    { iRef.IsActiveBGROrder(),   'w' }, { iRef.IsConvertBinary(),    'N' },
    { iRef.IsActiveBinary(),     'n' }, { iRef.IsConvertGPUCompat(), 'O' },
    { iRef.IsActiveGPUCompat(),  'o' }, { iRef.IsConvertRGBOrder(),  'B' },
    { iRef.IsActiveRGBOrder(),   'b' }, { iRef.IsCompressed(),       'C' },
    { iRef.IsPalette(),          'L' }, { iRef.IsMipmaps(),          'M' },
    { iRef.IsReversed(),         'R' }
  })).DataN(iRef.DimGetWidth()).DataN(iRef.DimGetHeight())
     .DataN(iRef.GetBitsPerPixel()).DataN(iRef.GetBytesPerPixel())
     .DataN(iRef.GetSlotCount()).DataN(iRef.GetAlloc())
     .DataN(ImageGetPixelFormat(iRef.GetPixelType()))
     .Data(iRef.IdentGet());
} // Log texture counts
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cImages->size(), "image.", "images."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'images' function
/* ========================================================================= */
// ! imgfmts
// ? No explanation yet.
/* ========================================================================= */
{ "imgfmts", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("FL").Header("EXT").Header("NAME", false)
      .Reserve(cImageLibs->size());
// For each plugin
for(const ImageLib*const ilPtr : *cImageLibs)
{ // Get reference to class and write its data to the table
  const ImageLib &ilRef = *ilPtr;
  sTable.DataN(ilRef.CtrGet()).Data(StrFromEvalTokens({
    { ilRef.HaveLoader(), 'L' }, { ilRef.HaveSaver(),  'S' }
  })).Data(ilRef.GetExt()).Data(ilRef.GetName());
} // Log total plugins
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cImageLibs->size(), "format.", "formats."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'imgfmts' function
/* ========================================================================= */
// ! input
// ? No explanation yet.
/* ========================================================================= */
{ "input", 1, 1, CFL_VIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Get joysticks data
const JoyList &jlList = cInput->GetConstJoyList();
// Joysticks connected
size_t stCount = 0;
// Make a table to automatically format our data neatly
Statistic sTable;
sTable.Header("ID").Header("FL").Header("AX").Header("BT")
      .Header("NAME", false).Reserve(jlList.size());
// For each joystick
for(const JoyInfo &jiRef : jlList)
{ // Ignore if not connected
  if(jiRef.IsDisconnected()) continue;
  // Store data
  sTable.DataN(jiRef.GetId()).DataH(jiRef.FlagGet())
        .DataN(jiRef.GetAxisCount()).DataN(jiRef.GetButtonCount())
        .Data(jiRef.IdentGet());
  // Connected
  ++stCount;
} // Print totals
cConsole->AddLineF("$$ ($ supported).", sTable.Finish(),
  StrCPluraliseNum(stCount, "input", "inputs"), jlList.size());
/* ------------------------------------------------------------------------- */
} },                                   // End of 'input' function
/* ========================================================================= */
// ! jsons
// ? No explanation yet.
/* ========================================================================= */
{ "jsons", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Get reference to jsons collector class and lock it so it's not changed
const LockGuard lgJsonsSync{ cJsons->CollectorGetMutex() };
// Print totals
cConsole->AddLineA(StrCPluraliseNum(cJsons->size(), "json.", "jsons."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'jsons' function
/* ========================================================================= */
// ! lcalc
// ? No explanation yet.
/* ========================================================================= */
{ "lcalc", 2, 0, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
cConsole->AddLine(cLua->CompileStringAndReturnResult(
  StrFormat("return $", StrImplode(aArgs, 1))));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lcalc' function
/* ========================================================================= */
// ! lcmds
// ? No explanation yet.
/* ========================================================================= */
{ "lcmds", 1, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Build LUA commands list and if commands were matched? Print them all
string strMatched;
if(const size_t stMatched = CommandsBuildList(cCommands->lcmMap,
     aArgs.size() > 1 ? aArgs[1] : cCommon->Blank(), strMatched))
  cConsole->AddLineF("$:$.", StrCPluraliseNum(stMatched,
    "matching LUA command", "matching LUA commands"), strMatched);
// No LUA commands matched
else cConsole->AddLineF("No match from $.",
  StrCPluraliseNum(cConsole->GetCmdsList().size(),
    "LUA command", "LUAa commands"));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lcmds' function
/* ========================================================================= */
// ! lend
// ? No explanation yet.
/* ========================================================================= */
{ "lend", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Re-init lua and inform user of the result
cConsole->AddLine(cLua->TryEventOrForce(EMC_LUA_END) ?
  "Bypassing guest end routine and going stand-by!" :
  "Asking guest to end execution and going stand-by.");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lend' function
/* ========================================================================= */
// ! lexec
// ? No explanation yet.
/* ========================================================================= */
{ "lexec", 2, 0, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
cConsole->AddLine(cLua->CompileStringAndReturnResult(StrImplode(aArgs, 1)));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lexec' function
/* ========================================================================= */
// ! lfuncs
// ? No explanation yet.
/* ========================================================================= */
{ "lfuncs", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Get reference to luarefs collector class and lock it so it's not changed
const LockGuard lgLuaRefsSync(cLuaFuncs->CollectorGetMutex());
// Make a table to automatically format our data neatly
Statistic sTable;
sTable.Header("ID").Header("FLAGS").Header("DATA", false).Header("MID")
      .Header("SID").Header("NAME", false).Reserve(cLuaFuncs->size());
// Walk Lua function list
for(const LuaFunc*const lfPtr : *cLuaFuncs)
{ // Get Lua function
  const LuaFunc &lfRef = *lfPtr;
  // Put on stack
  lfRef.LuaFuncPushFunc();
  // Print totals info
  sTable.DataN(lfRef.CtrGet())
        .Data(LuaUtilGetStackTokens(cLuaFuncs->LuaRefGetState(), -1))
        .Data(LuaUtilGetStackType(cLuaFuncs->LuaRefGetState(), -1))
        .DataN(lfRef.LuaFuncGet()).DataN(lfRef.LuaFuncGetSaved())
        .Data(lfRef.IdentGet());
  // Remove what we pushed
  LuaUtilRmStack(cLuaFuncs->LuaRefGetState());
} // Number of items in buffer
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cLuaFuncs->size(), "function.", "functions."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lfuncs' function
/* ========================================================================= */
// ! lg
// ? No explanation yet.
/* ========================================================================= */
{ "lg", 1, 0, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Get lua state
lua_State*const lS = cLua->GetState();
// Save stack position and restore it when this function call completes. We
// do this because we could write any number of values to the stack
// depending on how many child variables the user specifies. This simple
// class creation simplifies the cleanup process.
const LuaStackSaver lssSaved{ lS };
// We need free items on the stack, leave empty if not
if(!LuaUtilIsStackAvail(lS, aArgs.size()))
  return cConsole->AddLine("Too many path components!");
// Get iterator to second argument. First is actually the command name. The
// second argument in this instance is the root table name in globals.
// Store if we have arguments and if we have them?
StrVectorConstIt svciIt{ aArgs.cbegin() + 1 };
if(svciIt != aArgs.cend())
{ // Get root table
  const string &strRoot = *svciIt;
  if(strRoot.empty()) return cConsole->AddLine("Empty table name!");
  // Push variable specified on command line and if it's not a table?
  // Tell user the table is invalid and return
  LuaUtilGetGlobal(lS, strRoot.c_str());
  if(!LuaUtilIsTable(lS, -1))
    return cConsole->AddLineF("Table '$' $!", strRoot,
      LuaUtilIsNil(lS, -1) ? "does not exist" : "is not valid");
  // Save index so we can keep recursing the same table and check if each
  // remaining argument is a table until we reach no more arguments.
  for(const int iIndex = LuaUtilStackSize(lS); ++svciIt != aArgs.cend();)
  { // Get name of parameter and if it's empty? Return empty sub-table
    const string &strParam = *svciIt;
    if(strParam.empty()) return cConsole->AddLine("Empty sub-table name!");
    // ...and if its a valid number?
    if(StrIsInt(strParam))
    { // Get value by index and keep searching for more tables
      LuaUtilGetRefEx(lS, -1, StrToNum<lua_Integer>(strParam));
      if(LuaUtilIsTable(lS, -1)) continue;
      // Restore where we were in the stack
      LuaUtilPruneStack(lS, iIndex);
    } // Find subtable. It must be a table
    LuaUtilGetField(lS, -1, strParam.c_str());
    if(LuaUtilIsTable(lS, -1)) continue;
    // Tell user the table is invalid and return
    return cConsole->AddLineF("Sub-table '$' $!", strParam,
      LuaUtilIsNil(lS, -1) ? "does not exist" : "is not valid");
  }
} // Push global namspace and throw error if it is invalid
else lua_pushglobaltable(lS);
// Items for sorting (Name, Value, Tokens)
typedef pair<const string,const StrStrMapPair> StrStrPairMapPair;
typedef map<StrStrPairMapPair::first_type,
            StrStrPairMapPair::second_type> StrStrPairMap;
StrStrPairMap ssmpmMap;
// Make sure theres two elements
for(LuaUtilPushNil(lS); lua_next(lS, -2); LuaUtilRmStack(lS))
{ // Index is an integer? Create item info struct and add to list
  if(LuaUtilIsInteger(lS, -2))
    ssmpmMap.insert({ StrFromNum(LuaUtilToInt(lS, -2)),
      { LuaUtilGetStackType(lS, -1), LuaUtilGetStackTokens(lS, -1) } });
  // For everything else. Create item info struct and add to list
  else ssmpmMap.insert({ lua_tostring(lS, -2),
    { LuaUtilGetStackType(lS, -1), LuaUtilGetStackTokens(lS, -1) } });
} // Build string to output
Statistic sTable;
sTable.Header("FLAGS").Header("NAME", false).Header("VALUE", false)
      .Reserve(ssmpmMap.size());
for(const StrStrPairMapPair &sspmpPair : ssmpmMap)
  sTable.Data(sspmpPair.second.second).Data(sspmpPair.first)
        .Data(sspmpPair.second.first);
// Print number of items
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(ssmpmMap.size(), "item.", "items."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lg' function
/* ========================================================================= */
// ! lgc
// ? No explanation yet.
/* ========================================================================= */
{ "lgc", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Free data and get bytes freed, if there are any? Report them
if(const size_t stT = cLua->GarbageCollect())
  cConsole->AddLineF("$ bytes ($) freed.", stT, StrToBytes(stT));
// No unreferenced objects were freed
else cConsole->AddLine("No unreferenced memory!");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lgc' function
/* ========================================================================= */
// ! log
// ? No explanation yet.
/* ========================================================================= */
{ "log", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Colours for log levels
typedef array<const Colour, LH_MAX> LogLevelColours;
const LogLevelColours llcLookup{
  COLOUR_LBLUE  /* LH_CRITICAL */, COLOUR_LRED   /* LH_ERROR    */,
  COLOUR_YELLOW /* LH_WARNING  */, COLOUR_WHITE  /* LH_INFO     */,
  COLOUR_LGRAY  /* LH_DEBUG    */
};
// Get reference to log class and lock it so it's not changed
const LockGuard lgLogSync{ cLog->GetMutex() };
// For each log line. Add the line to console buffer
for(const LogLine &llRef : *cLog)
  cConsole->AddLineF(llcLookup[llRef.lhlLevel], "[$$$] $",
    fixed, setprecision(6), llRef.dTime, llRef.strLine);
// Number of items in buffer
cConsole->AddLineA(StrCPluraliseNum(cLog->size(), "line.", "lines."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'log' function
/* ========================================================================= */
// ! logclr
// ? No explanation yet.
/* ========================================================================= */
{ "logclr", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Lock access to the log
const LockGuard lgLogSync{ cLog->GetMutex() };
// Ignore if not empty
if(cLog->empty()) return cConsole->AddLine("No log lines to clear!");
// Get log lines count
const size_t stCount = cLog->size();
// Clear the log
cLog->Clear();
// Say we cleared it
cConsole->AddLineA(StrCPluraliseNum(stCount,
  "log line cleared.", "log lines cleared."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'logclr' function
/* ========================================================================= */
// ! lpause
// ? Requests to pause the engine.
/* ========================================================================= */
{ "lpause", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
cLua->RequestPause(true);
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lpause' function
/* ========================================================================= */
// ! lreset
// ? No explanation yet.
/* ========================================================================= */
{ "lreset", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Re-init lua and inform user of the result
cConsole->AddLine(cLua->TryEventOrForce(EMC_LUA_REINIT) ?
  "Bypassing guest end routine and restarting execution!" :
  "Asking guest to end execution and restarting execution.");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lreset' function
/* ========================================================================= */
// ! lresume
// ? No explanation yet.
/* ========================================================================= */
{ "lresume", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
cEvtMain->Add(EMC_LUA_RESUME);
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lresume' function
/* ========================================================================= */
// ! lstack
// ? No explanation yet.
/* ========================================================================= */
{ "lstack", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Get lua state
lua_State*const lS = cLua->GetState();
// Get number of items in stack
const int iCount = LuaUtilStackSize(lS);
// Setup output spreadsheet
Statistic sTable;
sTable.Header("ID").Header("FLAGS").Header("NAME", false).Header("VALUE")
      .Reserve(static_cast<size_t>(iCount));
// Enumerate each stack element (1 is the first item)
for(int iIndex = 1; iIndex <= iCount; ++iIndex)
  sTable.DataN(iIndex)
        .Data(LuaUtilGetStackTokens(lS, iIndex))
        .DataN(-(iCount - (iIndex + 1)))
        .Data(LuaUtilGetStackType(lS, iIndex));
// Print number of element
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(iCount, "element.", "elements."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lstack' function
/* ========================================================================= */
// ! lvars
// ? No explanation yet.
/* ========================================================================= */
{ "lvars", 1, 0, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
cConsole->AddLine(VariablesMakeList(cVariables->lcvmMap,
  aArgs.size() > 1 ? aArgs[1] : cCommon->Blank()));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'lvars' function
/* ========================================================================= */
// ! masks
// ? No explanation yet.
/* ========================================================================= */
{ "masks", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("WIDTH").Header("HEIGHT").Header("TOTAL")
      .Header("ALLOC").Header("NAME", false).Reserve(cMasks->size());
// Walk mask list
for(const Mask*const mPtr : *cMasks)
{ // Get reference to class and write its data to the table
  const Mask &mRef = *mPtr;
  sTable.DataN(mRef.CtrGet()).DataN(mRef.DimGetWidth())
        .DataN(mRef.DimGetHeight()).DataN(mRef.size()).DataN(mRef.GetAlloc())
        .Data(mRef.IdentGet());
} // Output data
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cMasks->size(), "mask.", "masks."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'masks' function
/* ========================================================================= */
// ! mem
// ? No explanation yet.
/* ========================================================================= */
{ "mem", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Update counters
cSystem->UpdateMemoryUsageData();
// Precalculate lua and sql usage.
const size_t stUsage = LuaUtilGetUsage(cLua->GetState()),
             stSqlUse = cSql->HeapUsed();
// Report lua and sql memory usage
Statistic sTable;
sTable.Header("BYTES", true).Header()
      .Header("COMPONENT", false).DupeHeader()
      .Reserve(6)
      .DataN(stUsage).DataB(stUsage).Data("Lua usage")
      .DataN(stSqlUse).DataB(stSqlUse).Data("Sqlite usage")
// Print rest of information
      .DataN(cSystem->RAMProcUse()).DataB(cSystem->RAMProcUse())
      .Data("Process usage")
      .DataN(cSystem->RAMProcPeak()).DataB(cSystem->RAMProcPeak())
      .Data ("Process peak usage")
// Using 32-bits?
#if defined(X86)
// The engine can allocate up to 4GB in a 32-bit process
      .DataN(cSystem->RAMFree32()).DataB(cSystem->RAMFree32())
      .Data("Engine available").DataN(cSystem->RAMFree())
      .DataB(cSystem->RAMFree()).Data("System free")
#else
// Using 64-bits? Show 64-bit specific data
      .DataN(cSystem->RAMFree()).DataB(cSystem->RAMFree()).Data("System free")
#endif
// Report system memory info
      .DataN(cSystem->RAMUsed()).DataB(cSystem->RAMUsed())
      .Data("System usage").DataN(cSystem->RAMTotal())
      .DataB(cSystem->RAMTotal()).Data("System total");
// If have video memory reporting?
if(cOgl->FlagIsSet(GFL_HAVEMEM))
{ // Get VRAM info
  const uint64_t uqAvail = cOgl->GetVRAMFree(),
                 uqTotal = cOgl->GetVRAMTotal(),
                 uqUsed = uqTotal - uqAvail;
  // Report system memory info
  sTable.DataN(uqAvail).DataB(uqAvail).Data("Renderer free")
        .DataN(uqUsed).DataB(uqUsed).Data("Renderer usage")
        .DataN(uqTotal).DataB(uqTotal).Data("Renderer total");
} // Output all the data we built up
cConsole->AddLine(sTable.Finish(false));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'mem' function
/* ========================================================================= */
// ! mlist
// ? No explanation yet.
/* ========================================================================= */
{ "mlist", 1, 1, CFL_VIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Header (to be printed twice)
Statistic sTable;
sTable.Header("ID").Header("A").Header("POSX").Header("POSY").Header("HORI")
      .Header("VERT").Header("RATIO").Header("RD").Header("GD").Header("BD")
      .Header("TD").Header("HTZ").Header("DWIN").Header("DHIN").Header("SIZE")
      .Header("NAME", false).Reserve(cDisplay->GetMonitorsCount());
// Walk the monitors list
for(const GlFWMonitor &gfwmRef : cDisplay->GetMonitors())
{ // Get reference to class and write its data to the table
  const GlFWRes &gfwrRef = *gfwmRef.Primary();
  sTable.DataN(gfwmRef.Index())
        .Data(StrFromBoolYN(&gfwmRef == cDisplay->GetSelectedMonitor()))
        .DataN(gfwmRef.CoordGetX()).DataN(gfwmRef.CoordGetY())
        .DataN(gfwrRef.Width()).DataN(gfwrRef.Height())
        .Data(StrFromRatio(gfwrRef.Width(), gfwrRef.Height()))
        .DataN(gfwrRef.Red()).DataN(gfwrRef.Green()).DataN(gfwrRef.Blue())
        .DataN(gfwrRef.Depth()).DataN(gfwrRef.Refresh())
        .DataN(gfwmRef.WidthInch(), 1).DataN(gfwmRef.HeightInch(), 1)
        .DataN(gfwmRef.DiagonalInch(), 1).Data(gfwmRef.Name());
} // Write total monitors found
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cDisplay->GetMonitorsCount(), "monitor", "monitors"),
    " detected.");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'mlist' function
/* ========================================================================= */
// ! mods
// ? No explanation yet.
/* ========================================================================= */
{ "mods", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Make a table to automatically format our data neatly
Statistic sTable;
sTable.Header("DESCRIPTION").Header("VERSION", false).Header("VENDOR", false)
      .Header("MODULE", false).Reserve(cSystem->size());
 // Re-enumerate modules
cSystem->EnumModules();
// list modules
for(const SysModMapPair &smmpPair : *cSystem)
{ // Get reference to class and write its data to the table
  const SysModuleData &smdRef = smmpPair.second;
  sTable.Data(smdRef.GetDesc()).Data(smdRef.GetVersion())
        .Data(smdRef.GetVendor()).Data(smdRef.GetFull());
} // Finished enumeration of modules
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cSystem->size(), "module.", "modules."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'mods' function
/* ========================================================================= */
// ! objs
// ? No explanation yet.
/* ========================================================================= */
{ "objs", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Typedefs for building memory usage data
struct MemoryUsageItem{ const string_view &strName; size_t stCount, stBytes; }
  muiTotal{ cCommon->Blank(), 0, 0 };
typedef list<MemoryUsageItem> MemoryUsageItems;
// Helper macros so there is not as much spam
#define MSS(x) { c ## x ## s->IdentGet(), \
                 c ## x ## s->CollectorCount(), \
                 c ## x ## s->CollectorCount() * sizeof(x) }
// Build memory usage items database
const MemoryUsageItems muiList{ {
  MSS(Archive),  MSS(Asset),    MSS(Bin),     MSS(Clip),    MSS(Command),
  MSS(Fbo),      MSS(File),     MSS(Font),    MSS(Ftf),     MSS(Image),
  MSS(ImageLib), MSS(Json),     MSS(LuaFunc), MSS(Mask),    MSS(Palette),
  MSS(Pcm),      MSS(PcmLib),   MSS(Sample),  MSS(Shader),  MSS(Socket),
  MSS(Source),   MSS(SShot),    MSS(Stat),    MSS(Stream),  MSS(Texture),
  MSS(Thread),   MSS(Variable), MSS(Video)
} };
// Done with these macros
#undef MSS
#undef MSSEX
// Prepare statistics data
Statistic stData;
stData.Header("TYPE").Header("#").Header("STACK").Header().DupeHeader(2)
      .Reserve(10);
// Add entries
for(const MemoryUsageItem &muiRef : muiList)
{ // Add sizes to total
  muiTotal.stCount += muiRef.stCount;
  muiTotal.stBytes += muiRef.stBytes;
  // Add data to table
  stData.Data(muiRef.strName).DataN(muiRef.stCount).DataN(muiRef.stBytes)
        .DataF("($)", StrToBytes(muiRef.stBytes, 0));
} // Display output to user
cConsole->AddLineF("$$ totalling $ ($).", stData.Finish(),
  StrCPluraliseNum(muiTotal.stCount, "object", "objects"),
  StrCPluraliseNum(muiTotal.stBytes, "byte", "bytes"),
  StrToBytes(muiTotal.stBytes, 0));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'objs' function
/* ========================================================================= */
// ! oglext
// ? No explanation yet.
/* ========================================================================= */
{ "oglext", 2, 2, CFL_VIDEO, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Get extension name and output if the extension is supported
const string &strExtName = aArgs[1];
cConsole->AddLineF(
  "Extension '$' is$ supported by the selected graphics device.",
    strExtName, cOgl->HaveExtension(strExtName.c_str()) ?
      cCommon->Blank() : " NOT");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'oglext' function
/* ========================================================================= */
// ! oglfunc
// ? No explanation yet.
/* ========================================================================= */
{ "oglfunc", 2, 2, CFL_VIDEO, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Get function name and output if the function is supported
const string &strFunction = aArgs[1];
cConsole->AddLineF(
  "Function '$' is$ supported by the selected graphics device.",
    strFunction, GlFWProcExists(strFunction.c_str()) ?
      cCommon->Blank() : " NOT");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'oglfunc' function
/* ========================================================================= */
// ! palettes
// ? No explanation yet.
/* ========================================================================= */
{ "palettes", 2, 2, CFL_VIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Print totals
cConsole->AddLineA(StrCPluraliseNum(cPalettes->size(),
  "palette.", "palettes."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'palettes' function
/* ========================================================================= */
// ! pcmfmts
// ? No explanation yet.
/* ========================================================================= */
{ "pcmfmts", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("FL").Header("EXT").Header("NAME", false)
      .Reserve(cPcmLibs->size());
// For each plugin
for(const PcmLib*const plPtr : *cPcmLibs)
{ // Get reference to class and write its data to the table
  const PcmLib &plRef = *plPtr;
  sTable.DataN(plRef.CtrGet()).Data(StrFromEvalTokens({
    { plRef.HaveLoader(), 'L' }, { plRef.HaveSaver(),  'S' }
  })).Data(plRef.GetExt()).Data(plRef.GetName());
} // Log total plugins
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cPcmLibs->size(), "format.", "formats."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'pcmfmts' function
/* ========================================================================= */
// ! pcms
// ? No explanation yet.
/* ========================================================================= */
{ "pcms", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Get reference to pcms collector class and lock it so it's not changed
const LockGuard lgPcmsSync{ cPcms->CollectorGetMutex() };
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("FLAGS", false).Header("RATE")
      .Header("C").Header("BT").Header("B").Header("PFMT").Header("ALLOC")
      .Header("NAME", false).Reserve(cPcms->size());
// Walk through textures classes
for(const Pcm*const pPtr : *cPcms)
{ // Get reference to class and write its data to the table
  const Pcm &pRef = *pPtr;
  sTable.DataN(pRef.CtrGet()).Data(StrFromEvalTokens({
    { pRef.IsDynamic(),           'Y' }, { pRef.IsNotDynamic(),        'S' },
    { pRef.FlagIsSet(PL_FCE_WAV), 'W' }, { pRef.FlagIsSet(PL_FCE_CAF), 'C' },
    { pRef.FlagIsSet(PL_FCE_OGG), 'O' }, { pRef.FlagIsSet(PL_FCE_MP3), 'M' }
  })).DataN(pRef.GetRate()).DataN(pRef.GetChannels()).DataN(pRef.GetBits())
     .DataN(pRef.GetBytes()).DataH(pRef.GetFormat(),4)
     .DataN(pRef.GetAlloc()).Data(pRef.IdentGet());
} // Log texture counts
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cPcms->size(), "pcm.", "pcms."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'pcms' function
/* ========================================================================= */
// ! quit
// ? No explanation yet.
/* ========================================================================= */
{ "quit", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Quit the engine and inform user of the result
cConsole->AddLine(cLua->TryEventOrForce(EMC_QUIT) ?
  "Bypassing guest end routine and terminating engine!" :
  "Asking guest to end execution and terminating engine.");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'quit' function
/* ========================================================================= */
// ! restart
// ? No explanation yet.
/* ========================================================================= */
{ "restart", 1, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Restart the process and inform user of the result
cConsole->AddLine(aArgs.size() == 2 ?
  (cLua->TryEventOrForce(EMC_QUIT_RESTART_NP) ?
    "Bypassing guest end routine and restarting engine with no args!" :
    "Asking guest to end execution and restarting engine with no args.") :
  (cLua->TryEventOrForce(EMC_QUIT_RESTART) ?
    "Bypassing guest end routine and restarting engine!" :
    "Asking guest to end execution and restarting engine."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'restart' function
/* ========================================================================= */
// ! samples
// ? No explanation yet.
/* ========================================================================= */
{ "samples", 1, 1, CFL_AUDIO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Make a table to automatically format our data neatly
Statistic sTable;
sTable.Header("ID").Header("BID").Header("NAME", false)
      .Reserve(cSamples->size());
// Walk sample object list
for(const Sample*const sPtr : *cSamples)
{ // Get reference to class and write its data to the table
  const Sample &sRef = *sPtr;
  sTable.DataN(sRef.CtrGet()).DataN(sRef.uivNames.front())
        .Data(sRef.IdentGet());
} // Number of items in buffer
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cSamples->size(), "sample.", "samples."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'samples' function
/* ========================================================================= */
// ! shaders
// ? No explanation yet.
/* ========================================================================= */
{ "shaders", 1, 2, CFL_VIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Make a table to automatically format our data neatly
Statistic sTable;
sTable.Header("ID").Header("PID").Header("L").Header("C").Header("SID")
      .Header("TYPE").Header("CODE").Header("NAME", false)
      .Reserve(cShaders->size() * 3);
// Shader count
size_t stShaders = 0;
// Walk shader list
for(const Shader*const sPtr : *cShaders)
{ // Get reference to class
  const Shader &sRef = *sPtr;
  // Store shader information
  sTable.DataN(sRef.CtrGet()).DataN(sRef.GetProgramId())
        .Data(StrFromBoolYN(sRef.IsLinked())).DataN(sRef.size())
        .Data().Data().Data().Data();
  // For each shader item, add data for each shader
  for(const ShaderCell &scRef : sRef)
    sTable.Data().Data().Data().Data().DataN(scRef.GetHandle())
          .DataH(scRef.GetType()).DataN(scRef.GetCodeLength())
          .Data(scRef.IdentGet());
  // Increment number of shaders
  stShaders = stShaders + sRef.size();
} // Print output and number of shaders listed
cConsole->AddLineF("$$ and $.", sTable.Finish(),
  StrCPluraliseNum(cShaders->size(), "program", "programs"),
  StrCPluraliseNum(stShaders, "shader", "shaders"));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'shaders' function
/* ========================================================================= */
// ! shot
// ? No explanation yet.
/* ========================================================================= */
{ "shot", 1, 1, CFL_VIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
LuaUtilClassCreate<SShot>(cLua->GetState(), *cSShots)->DumpMain();
// Although SShot is asynchronous, theres no way to clean up the stack so
// we'll just delete it straight away.
LuaUtilRmStack(cLua->GetState(), 1);
/* ------------------------------------------------------------------------- */
} },                                   // End of 'shot' function
/* ========================================================================= */
// ! sockets
// ? No explanation yet.
/* ========================================================================= */
{ "sockets", 1, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Id specified?
if(aArgs.size() == 2)
{ // Parse the specified id
  const unsigned int uiId = StrToNum<unsigned int>(aArgs[1]);
  // For each socket. Try to find the FD specified and return the class
  // if we can't find, tell the console we could not find it.
  const SocketsItConst sicIt{ SocketFind(uiId) };
  if(sicIt == cSockets->cend())
    return cConsole->AddLine("The specified socket id was not matched.");
  // Get reference to socket
  const Socket &sRef = **sicIt;
  // Get socket flags
  const SocketFlagsConst sfcFlags{ sRef.FlagGet() };
  // Tokens for status
  const string strStatus
      ((sfcFlags.FlagIsSet(SS_CLOSEDBYCLIENT)) ? "ClientClosed"
    : ((sfcFlags.FlagIsSet(SS_CLOSEDBYSERVER)) ? "ServerClosed"
    : ((sfcFlags.FlagIsSet(SS_STANDBY))        ? "Disconnected"
    : ((sfcFlags.FlagIsSet(SS_DISCONNECTING))  ? "Disconnecting"
    : ((sfcFlags.FlagIsSet(SS_DOWNLOADING))    ? "Downloading"
    : ((sfcFlags.FlagIsSet(SS_REPLYWAIT))      ? "ReplyWait"
    : ((sfcFlags.FlagIsSet(SS_SENDREQUEST))    ? "SendRequest"
    : ((sfcFlags.FlagIsSet(SS_CONNECTED))      ? "Connected"
    : ((sfcFlags.FlagIsSet(SS_CONNECTING))     ? "Connecting"
    : ((sfcFlags.FlagIsSet(SS_INITIALISING))   ? "Initialising"
    :                                  "Unknown"))))))))));
  // If the socket is not connected?
  if(sfcFlags.FlagIsClear(SS_CONNECTED))
    return cConsole->AddLineF("Status for socket $...\n"
      "- Status: $; Flags: 0x$$; Error: $$; Descriptor: $ (0x$$).\n"
      "- Address: $; Port: $$; IP: $.\n"
      "- Encryption: $; Last: $.",
        uiId,
        strStatus, hex, sfcFlags.FlagGet(), dec, sRef.GetError(),
          sRef.GetFD(), hex, sRef.GetFD(),
        sRef.GetAddress(), dec, sRef.GetPort(), sRef.GetIPAddress(),
        StrFromBoolTF(sRef.IsSecure()), StrIsBlank(sRef.GetCipher()));
   // Use disconnect time or connect time
  const double dConnect = sfcFlags.FlagIsSet(SS_STANDBY) ?
    ClockTimePointRangeToClampedDouble(sRef.GetTDisconnected(),
      sRef.GetTConnected()) :
    cmHiRes.TimePointToClampedDouble(sRef.GetTConnected()),
  // Set connected to connection time
  dInitial = ClockTimePointRangeToClampedDouble(sRef.GetTConnected(),
    sRef.GetTConnect());
  // Write connected information
  return cConsole->AddLineF("Status for socket $...\n"
    "- Status: $; Flags: 0x$$; Error: $$; Descriptor: $ (0x$$).\n"
    "- Address: $; Port: $$; IP: $.\n"
    "- Real host: $.\n"
    "- RX Queue: $; Packets: $; Bytes: $ ($); Last: $ ago.\n"
    "- TX Queue: $; Packets: $; Bytes: $ ($); Last: $ ago.\n"
    "- Encryption: $; Last: $.\n"
    "- Total Time: $; Connected: $; Initial: $.",
    uiId,
    strStatus, hex, sfcFlags.FlagGet(), dec, sRef.GetError(),
      sRef.GetFD(), hex, sRef.GetFD(),
    sRef.GetAddress(), dec, sRef.GetPort(), sRef.GetIPAddress(),
    StrIsBlank(sRef.GetRealHost(), "<Unresolved>"),
    sRef.GetRXQCount(), sRef.GetRXpkt(), sRef.GetRX(),
      StrToBytes(sRef.GetRX()),
      StrShortFromDuration(cmHiRes.TimePointToClampedDouble(sRef.GetTRead())),
    sRef.GetTXQCount(), sRef.GetTXpkt(), sRef.GetTX(),
      StrToBytes(sRef.GetTX()),
      StrShortFromDuration(
        cmHiRes.TimePointToClampedDouble(sRef.GetTWrite())),
    StrFromBoolTF(sRef.IsSecure()), StrIsBlank(sRef.GetCipher()),
    StrShortFromDuration(dConnect + dInitial),
      StrShortFromDuration(dConnect), StrShortFromDuration(dInitial));
} // Make neatly formatted table
Statistic sTable;
sTable.Header("ID").Header("FLAGS").Header("IP").Header("PORT")
      .Header("ADDRESS", false).Reserve(cSockets->size());
// Walk through sockets
for(const Socket*const sPtr : *cSockets)
{ // Get reference to class and socket flags
  const Socket &sRef = *sPtr;
  const SocketFlagsConst sfcFlags{ sRef.FlagGet() };
  // Show status
  sTable.DataN(sRef.CtrGet()).Data(StrFromEvalTokens({
    { sfcFlags.FlagIsSet(SS_INITIALISING),   'I' },
    { sfcFlags.FlagIsSet(SS_ENCRYPTION),     'X' },
    { sfcFlags.FlagIsSet(SS_CONNECTING),     'T' },
    { sfcFlags.FlagIsSet(SS_CONNECTED),      'O' },
    { sfcFlags.FlagIsSet(SS_SENDREQUEST),    'H' },
    { sfcFlags.FlagIsSet(SS_REPLYWAIT),      'R' },
    { sfcFlags.FlagIsSet(SS_DOWNLOADING),    'D' },
    { sfcFlags.FlagIsSet(SS_DISCONNECTING),  'N' },
    { sfcFlags.FlagIsSet(SS_STANDBY),        'B' },
    { sRef.GetError() != 0,                  'E' },
    { sfcFlags.FlagIsSet(SS_CLOSEDBYSERVER), 'S' },
    { sfcFlags.FlagIsSet(SS_CLOSEDBYCLIENT), 'C' } }
  )).Data(sRef.GetIPAddress()).DataN(sRef.GetPort()).Data(sRef.GetAddress());
} // Show result
cConsole->AddLineF("$$ ($ connected).\n"
  "Total RX Packets: $; Bytes: $ ($).\n"
  "Total TX Packets: $; Bytes: $ ($).",
  sTable.Finish(), StrCPluraliseNum(cSockets->size(), "socket", "sockets"),
  cSockets->stConnected.load(),
  cSockets->qRXp.load(), cSockets->qRX.load(),
    StrToBytes(cSockets->qRX.load()),
  cSockets->qTXp.load(), cSockets->qTX.load(),
    StrToBytes(cSockets->qTX.load()));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'sockets' function
/* ========================================================================= */
// ! sockreset
// ? No explanation yet.
/* ========================================================================= */
{ "sockreset", 2, 2, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Get parameter and if user requested to close all connections? Close all
// the sockets and report how many we closed and return
const string &strId = aArgs[1];
if(strId == "*")
  return cConsole->AddLineA(StrCPluraliseNum(SocketReset(),
    "connection", "connections"), " closed.");
// Parse the specified id. Try to find the FD specified and return the class
const unsigned int uiId = StrToNum<unsigned int>(strId);
const SocketsItConst sicIt{ SocketFind(uiId) };
// Report if socket was not matched, or the result of disconnection.
if(sicIt == cSockets->cend())
  cConsole->AddLine("The specified socket id was not matched!");
else cConsole->AddLineF("Connection $ $ closed.",
  uiId, ((*sicIt)->SendDisconnect() ? "has been" : "is already"));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'sockreset' function
/* ========================================================================= */
// ! sources
// ? No explanation yet.
/* ========================================================================= */
{ "sources", 1, 1, CFL_AUDIO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Get reference to sources collector class and lock it so it's not changed
const LockGuard lgSourcesSync{ cSources->CollectorGetMutex() };
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("SID").Header("FLAG").Header("S")
      .Header("T").Header("BQ").Header("BP").Header("BI").Header("GAIN")
      .Header("GAINMIN").Header("GAINMAX").Header("PITCH").Header("REFDIST")
      .Header("MAXDIST", false).Reserve(cSources->size());
// Walk through sources
for(const Source*const sPtr : *cSources)
{ // Get reference to class
  const Source &sRef = *sPtr;
  // Get source play state and type
  const ALenum alState = sRef.GetState();
  const ALuint uiType = sRef.GetType();
  // Add data to text table
  sTable.DataN(sRef.CtrGet()).DataN(sRef.GetSource())
        .Data(StrFromEvalTokens({
          { sRef.LockIsSet(),    'L' }, { sRef.GetExternal(),   'X' },
          { !!sRef.GetLooping(), 'O' }, { !!sRef.GetRelative(), 'R' },
        }))
        .DataC(alState == AL_INITIAL ? 'I' : (alState == AL_PLAYING ? 'P' :
              (alState == AL_PAUSED  ? 'H' : (alState == AL_STOPPED ? 'S' :
                                      '?'))))
        .DataC(uiType == AL_UNDETERMINED ? 'U' : (uiType == AL_STATIC ? 'T' :
              (uiType == AL_STREAMING    ? 'S' : '?')))
        .DataN(sRef.GetBuffersQueued()).DataN(sRef.GetBuffersProcessed())
        .DataN(sRef.GetBuffer())       .DataN(sRef.GetGain(), 6)
        .DataN(sRef.GetMinGain(), 6)   .DataN(sRef.GetMaxGain(), 6)
        .DataN(sRef.GetPitch(), 6)     .DataN(sRef.GetRefDist(), 6)
        .DataN(sRef.GetMaxDist(), 6);
} // Show total
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cSources->size(), "source.", "sources."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'sources' function
/* ========================================================================= */
// ! sqlcheck
// ? No explanation yet.
/* ========================================================================= */
{ "sqlcheck", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Don't continue if theres a transaction in progress
if(cSql->Active()) return cConsole->AddLine("Sql transaction already active!");
// Compact the database and print the reason if failed
cConsole->AddLine(cSql->CheckIntegrity() ?
  "UDB check has passed!" : cSql->GetErrorStr());
// Reset sql transaction because it will leave arrays registered
cSql->Reset();
/* ------------------------------------------------------------------------- */
} },                                   // End of 'sqlcheck' function
/* ========================================================================= */
// ! sqldefrag
// ? No explanation yet.
/* ========================================================================= */
{ "sqldefrag", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Don't continue if theres a transaction in progress
if(cSql->Active()) return cConsole->AddLine("Sql transaction already active!");
// Get current size
const uint64_t uqBefore = cSql->Size();
// Do the defrag and say why if failed
if(cSql->Optimise()) return cConsole->AddLine(cSql->GetErrorStr());
// Get elapsed time (don't move this, or ->Reset() clears the duration).
const double dT = cSql->Time();
// Clear up result as it allocates arrays
cSql->Reset();
// Get new size in bytes
const uint64_t qAfter = cSql->Size();
// Set changed bytes
const int64_t qChange = static_cast<int64_t>(qAfter - uqBefore);
// Get change percentile
const double dPC = -100.0 + UtilMakePercentage(qAfter, uqBefore);
// Write summary
cConsole->AddLine(qChange ?
  // If udb did change?
  StrFormat("UDB changed $B ($; $$$%) to $B ($) from $B ($) in $.",
    qChange, StrToBytes(-qChange,0), setprecision(2), fixed, dPC, qAfter,
    StrToBytes(qAfter,0), uqBefore, StrToBytes(uqBefore,0),
    StrShortFromDuration(dT)) :
  // Udb did not change so show the result
  StrFormat("UDB unchanged at $B ($) in $.",
    qAfter, StrToBytes(qAfter,0), StrShortFromDuration(dT)));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'sqldefrag' function
/* ========================================================================= */
// ! sqlend
// ? No explanation yet.
/* ========================================================================= */
{ "sqlend", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Don't continue if theres a transaction in progress
if(!cSql->Active()) return cConsole->AddLine("Sql transaction not active!");
// End transaction
cConsole->AddLineF("Sql transaction$ ended.",
  cSql->End() == SQLITE_OK ? cCommon->Blank() : " NOT");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'sqlend' function
/* ========================================================================= */
// ! sqlexec
// ? No explanation yet.
/* ========================================================================= */
{ "sqlexec", 2, 0, CFL_NONE, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Don't continue if theres a transaction in progress
if(cSql->Active()) return cConsole->AddLine("Sql transaction already active!");
// Execute the string and catch exceptions
if(cSql->ExecuteAndSuccess(StrImplode(aArgs, 1)))
{ // Get records and if we did not have any?
  const SqlResult &srRef = cSql->GetRecords();
  if(srRef.empty())
  { // If we should show the rows affected. This is sloppy but sqllite
    // doesn't support resetting sqlite3_changes result yet :(
    const string &strFirst = StrToLowCaseRef(UtilToNonConst(aArgs[1]));
    // Show rows affected if we have them
    if(strFirst == "insert" || strFirst == "update" || strFirst == "delete")
      cConsole->AddLineF("$ affected in $.",
        StrCPluraliseNum(cSql->Affected(), "record", "records"),
          cSql->TimeStr());
    // Show time
    else if(cSql->Time() > 0)
      cConsole->AddLineF("Query time was $.", cSql->TimeStr());
  } // Results were returned?
  else
  { // Data for output
    Statistic sTable;
    sTable.Header("R#").Header("C#").Header("SIZE").Header("KEY", false)
          .Header("T").Header("VALUE", false)
          .Reserve(srRef.size() * srRef.front().size());
    // Record id
    size_t stRecordId = 0;
    // For each record, print the column and value of each record.
    for(const SqlRecordsMap &srmRef : srRef)
    { // Column id
      size_t stColumnId = 0;
      // For each column in the record
      for(const SqlRecordsMapPair &srmpRef : srmRef)
      { // Get reference to the record data
        const SqlData &sdRef = srmpRef.second;
        // Add row, column id, size and key name
        sTable.DataN(stRecordId).DataN(stColumnId++)
              .DataN(sdRef.MemSize()).Data(srmpRef.first);
        // What type is it?
        switch(sdRef.iType)
        { // 64-bit integer?
          case SQLITE_INTEGER:
          { // Get integer
            const sqlite3_int64 qwVal = sdRef.MemReadInt<sqlite3_int64>();
            // StrFormat and store in spreadsheet
            sTable.Data("I").DataF("$ (0x$$)", qwVal, hex, qwVal);
            // Done
            break;
          } // 64-bit IEEE float?
          case SQLITE_FLOAT:
            sTable.Data("F").DataN(sdRef.MemReadInt<double>()); break;
          // Raw data? Just write number of bytes
          case SQLITE_BLOB: sTable.Data("B").Data("<Blob>"); break;
          // Text?
          case SQLITE_TEXT: sTable.Data("T")
                                  .Data(sdRef.MemToString()); break;
          // No data
          case SQLITE_NULL: sTable.Data("N").Data("<Null>"); break;
          // Unknown type (impossible)
          default: sTable.Data("?")
                         .DataF("<Type $[0x$$]>",
                           sdRef.iType, hex, sdRef.iType);
                   break;
        }
      } // Increase record number
      stRecordId++;
    } // Show number of records matched and rows affected
    cConsole->AddLineA(sTable.Finish(), StrFormat("$ matched in $.",
      StrCPluraliseNum(stRecordId, "record", "records"), cSql->TimeStr()));
  }
} // Error occured?
else cConsole->AddLineF("Query took $ with $<$>: $!", cSql->TimeStr(),
  cSql->GetErrorAsIdString(), cSql->GetError(), cSql->GetErrorStr());
// Reset sql transaction because it will leave arrays registered
cSql->Reset();
/* ------------------------------------------------------------------------- */
} },                                   // End of 'sqlexec' function
/* ========================================================================= */
// ! stopall
// ? No explanation yet.
/* ========================================================================= */
{ "stopall", 1, 1, CFL_AUDIO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Tell audio to stop all sounds from playing
cAudio->Stop();
// Log event count
cConsole->AddLine("Stopping all sounds from playing.");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'stopall' function
/* ========================================================================= */
// ! streams
// ? No explanation yet.
/* ========================================================================= */
{ "streams", 1, 1, CFL_AUDIO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Synchronise the streams collector list
const LockGuard lgStreamsSync{ cStreams->CollectorGetMutex() };
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("L").Header("LENGTH").Header("TIME").Header()
      .Header("SAMPLE").Header().Header("LOOP").Header("VOL").Header("C")
      .Header("RATE").Header("TYPE").Header("BRU").Header("BRN").Header("BRL")
      .Header("BRW").Header("NAME", false).Reserve(cStreams->size());
// Walk through sources
for(Stream*const sPtr : *cStreams)
{ // Get reference to class and write its data to the table
  Stream &sRef = *sPtr;
  sTable.DataN(sRef.CtrGet()).Data(StrFromBoolYN(sRef.LuaRefIsSet()))
        .DataN(sRef.GetOggBytes()).DataN(sRef.GetElapsedSafe(), 1)
        .DataN(sRef.GetDurationSafe(), 1).DataN(sRef.GetPositionSafe())
        .DataN(sRef.GetSamplesSafe())
        .Data(sRef.GetLoop() == -1 ? "INF" : StrFromNum(sRef.GetLoop()))
        .DataN(sRef.GetVolume(), 2).DataN(sRef.GetChannels())
        .DataN(sRef.GetRate()).Data(sRef.GetFormatName())
        .DataN(sRef.GetBitRateUpper()).DataN(sRef.GetBitRateNominal())
        .DataN(sRef.GetBitRateLower()).DataN(sRef.GetBitRateWindow())
        .Data(sRef.IdentGet());
} // Show stream classes count
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cStreams->size(), "stream.", "streams."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'streams' function
/* ========================================================================= */
// ! system
// ? No explanation yet.
/* ========================================================================= */
{ "system", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Print OS stats
cConsole->AddLineF("$-bit $ version $.$ build $ locale $.",
  cSystem->OSBits(), cSystem->OSName(), cSystem->OSMajor(), cSystem->OSMinor(),
  cSystem->OSBuild(), cSystem->OSLocale());
/* ------------------------------------------------------------------------- */
} },                                   // End of 'system' function
/* ========================================================================= */
// ! textures
// ? No explanation yet.
/* ========================================================================= */
{ "textures", 1, 1, CFL_VIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
const function ShowTextureInfo{ [](Statistic &sTable, const Texture &tRef)
{ // Add data to table
  sTable.DataN(tRef.CtrGet()).Data(StrFromBoolYN(tRef.FlagIsSet(TF_DELETE)))
        .DataN(tRef.GetSubCount()).DataN(tRef.GetMipmaps())
        .DataN(tRef.GetTexFilter()).DataN(tRef.GetTileCount())
        .DataN(tRef.GetTileWidth()).DataN(tRef.GetTileHeight())
        .DataN(tRef.GetPaddingWidth(), 0).DataN(tRef.GetPaddingHeight(), 0)
        .Data(tRef.IdentGet());
} };
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("D").Header("SC").Header("MM").Header("TF")
      .Header("TLT").Header("TSSX").Header("TSSY").Header("TSPX")
      .Header("TSPY").Header("IDENTIFIER", false)
      .Reserve(2 + cFonts->size() + cTextures->size());
// Include console texture and font
ShowTextureInfo(sTable, cConGraphics->GetTextureRef());
ShowTextureInfo(sTable, cConGraphics->GetFontRef());
// Walk through font textures and textures classes
for(const Font*const fPtr : *cFonts) ShowTextureInfo(sTable, *fPtr);
for(const Texture*const tPtr : *cTextures) ShowTextureInfo(sTable, *tPtr);
// Log texture counts (+ 2 for the console texture and font)
cConsole->AddLineA(sTable.Finish(), StrCPluraliseNum(cTextures->size() +
  cFonts->size() + 2, "texture.", "textures."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'textures' function
/* ========================================================================= */
// ! threads
// ? No explanation yet.
/* ========================================================================= */
{ "threads", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Make a table to automatically format our data neatly
Statistic sTable;
sTable.Header("ID").Header("FLAG").Header("P").Header("EC").Header("STTIME")
      .Header("ENTIME").Header("UPTIME").Header("IDENTIFIER", false)
      .Reserve(cThreads->size());
// For each thread pointer
for(const Thread*const tPtr : *cThreads)
{ // Get reference to class and write its data to the table
  const Thread &tRef = *tPtr;
  sTable.DataN(tRef.CtrGet()).Data(StrFromEvalTokens({
    { tRef.ThreadHaveCallback(), 'C' },
    { tRef.ThreadIsParamSet(),   'P' }, { tRef.ThreadIsRunning(),    'R' },
    { tRef.ThreadShouldExit(),   'T' }, { tRef.ThreadIsException(),  'E' },
    { tRef.ThreadIsJoinable(),   'J' }, { tRef.ThreadIsExited(),     'X' },
  })).DataN(tRef.ThreadGetPerf()).DataN(tRef.ThreadGetExitCode())
     .Data(StrShortFromDuration(cLog->
       CCDeltaToClampedDouble(tRef.ThreadGetStartTime())))
     .Data(StrShortFromDuration(cLog->
       CCDeltaToClampedDouble(tRef.ThreadGetEndTime())))
     .Data(StrShortFromDuration(tRef.ThreadIsRunning()
        ? cmHiRes.TimePointToClampedDouble(tRef.ThreadGetStartTime())
        : ClockTimePointRangeToClampedDouble(tRef.ThreadGetEndTime(),
            tRef.ThreadGetStartTime())))
     .Data(tRef.IdentGet());
} // Show number of threads
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cThreads->size(), "thread (", "threads ("),
  ThreadGetRunning(), " running).");
/* ------------------------------------------------------------------------- */
} },                                   // End of 'threads' function
/* ========================================================================= */
// ! time
// ? No explanation yet.
/* ========================================================================= */
{ "time", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
// Timestamp to use
const char*const cpFmt = "%a %b %d %H:%M:%S %Y %z";
// Get current time
const StdTimeT tTime = cmSys.GetTimeS();
// Check if timezone's are different, if they are the same? Show local time
if(StrFromTimeTT(tTime, "%z") == StrFromTimeTTUTC(tTime, "%z"))
  cConsole->AddLineF("Local and universal time is $.",
    StrFromTimeTTUTC(tTime, cpFmt));
// Write current local and universal system time
else cConsole->AddLineF("Local time is $.\nUniversal time is $.",
    StrFromTimeTT(tTime, cpFmt), StrFromTimeTTUTC(tTime, cpFmt));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'time' function
/* ========================================================================= */
// ! version
// ? No explanation yet.
/* ========================================================================= */
{ "version", 1, 1, CFL_NONE, [](const Args &){
/* ------------------------------------------------------------------------- */
cConsole->PrintVersion();
/* ------------------------------------------------------------------------- */
} },                                   // End of 'version' function
/* ========================================================================= */
// ! videos
// ? No explanation yet.
/* ========================================================================= */
{ "videos", 1, 1, CFL_AUDIOVIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
// Get reference to videos collector class and lock it so it's not changed
const LockGuard lgVideosSync{ cVideos->CollectorGetMutex() };
// Text table class to help us write neat output
Statistic sTable;
sTable.Header("ID").Header("FLAGS").Header("PCMF").Header("P").Header("C")
      .Header("FRMW").Header("FRMH").Header("PICW").Header("PICH")
      .Header("OX").Header("OY").Header("FPS").Header("TIME").Header("FD")
      .Header("FR").Header("FL").Header("AVD").Header("LEN")
      .Header("NAME", false).Reserve(cVideos->size());;
// Walk through textures classes
for(const Video*const vPtr : *cVideos)
{ // Get reference to class and write its data to the table
  const Video &vRef = *vPtr;
  sTable.DataN(vRef.CtrGet())
    .Data(StrFromEvalTokens({
      { vRef.LuaRefIsSet(),       'L' }, { vRef.IsSourceAvailable(), 'A' },
      { vRef.FlagIsSet(FL_FILTER),'F' }, { vRef.GetKeyed(),          'K' },
      { vRef.FlagIsSet(FL_PLAY),  'P' }, { vRef.FlagIsSet(FL_STOP),  'S' },
      { vRef.FlagIsSet(FL_THEORA),'T' }, { vRef.FlagIsSet(FL_VORBIS),'V' },
    }))
    .Data(vRef.GetFormatAsIdentifier()).DataH(vRef.GetPixelFormat(),4)
    .DataN(vRef.GetColourSpace())      .DataN(vRef.GetFrameWidth())
    .DataN(vRef.GetFrameHeight())      .DataN(vRef.GetWidth())
    .DataN(vRef.GetHeight())           .DataN(vRef.GetOriginX())
    .DataN(vRef.GetOriginY())          .DataN(vRef.GetFPS(), 2)
    .DataN(vRef.GetVideoTime(), 3)     .DataN(vRef.GetFrame())
    .DataN(vRef.GetFrames())           .DataN(vRef.GetFramesSkipped())
    .DataN(vRef.GetDrift(), 2)         .DataN(vRef.GetLength())
    .Data(vRef.IdentGet());
} // Log counts
cConsole->AddLineA(sTable.Finish(),
  StrCPluraliseNum(cVideos->size(), "video.", "videos."));
/* ------------------------------------------------------------------------- */
} },                                   // End of 'videos' function
/* ========================================================================= */
// ! vmlist
// ? No explanation yet.
/* ========================================================================= */
{ "vmlist", 1, 2, CFL_VIDEO, [](const Args &aArgs){
/* ------------------------------------------------------------------------- */
// Monitor number and return if invalid
const size_t stMonitorSelected =
  aArgs.size() == 1 ? 0 : StrToNum<size_t>(aArgs[1]);
if(stMonitorSelected >= cDisplay->GetMonitorsCount())
  return cConsole->AddLineF("Invalid monitor $ specified!",
    stMonitorSelected);
// Header (to be printed twice)
Statistic sTable;
sTable.Header("VM#").Header("A").Header("HORI").Header("VERT")
      .Header("CD").Header("HTZ").Header("RD").Header("GD").Header("BD")
      .Header("RATIO ", false);
// Get selected monitor and add extra headers if more than one mode
const GlFWMonitor &gfwmRef = cDisplay->GetMonitors()[stMonitorSelected];
if(gfwmRef.size() > 1)
  sTable.DupeHeader().Reserve(cDisplay->GetMonitorsCount() / 2);
else sTable.Reserve(1);
// Write each resolution to the table
for(const GlFWRes &gfwrRef : gfwmRef)
  sTable.DataN(gfwrRef.Index())
        .Data(StrFromBoolYN(&gfwrRef == gfwmRef.Primary()))
        .DataN(gfwrRef.Width()).DataN(gfwrRef.Height()).DataN(gfwrRef.Depth())
        .DataN(gfwrRef.Refresh()).DataN(gfwrRef.Red()).DataN(gfwrRef.Green())
        .DataN(gfwrRef.Blue())
        .Data(StrFromRatio(gfwrRef.Width(), gfwrRef.Height()));
// Print number of video modes
cConsole->AddLineF("$$ supported on monitor #$ ($).", sTable.Finish(),
  StrCPluraliseNum(gfwmRef.size(), "mode", "modes"), stMonitorSelected,
  gfwmRef.Name());
/* ------------------------------------------------------------------------- */
} },                                   // End of 'vmlist' function
/* ========================================================================= */
// ! vreset
// ? No explanation yet.
/* ========================================================================= */
{ "vreset", 1, 1, CFL_VIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
cEvtMain->RequestQuitThread();
/* ------------------------------------------------------------------------- */
} },                                   // End of 'vreset' function
/* ========================================================================= */
// ! wreset
// ? No explanation yet.
/* ========================================================================= */
{ "wreset", 1, 1, CFL_VIDEO, [](const Args &){
/* ------------------------------------------------------------------------- */
cDisplay->RequestReposition();
/* ------------------------------------------------------------------------- */
} },                                   // End of 'wreset' function
/* ========================================================================= */
} };                                   // End of console commands list
/* == EoF =========================================================== EoF == */

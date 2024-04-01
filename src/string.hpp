/* == STRING.HPP =========================================================== **
** ######################################################################### **
** ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## **
** ######################################################################### **
** ## Miscaelennias string utility functions.                             ## **
** ######################################################################### **
** ========================================================================= */
#pragma once                           // Only one incursion allowed
/* ------------------------------------------------------------------------- */
namespace IString {                    // Start of private module namespace
/* ------------------------------------------------------------------------- */
using namespace IStd::P;               using namespace IUtf;
/* ------------------------------------------------------------------------- */
namespace P {                          // Start of public module namespace
/* -- Common class with common objects ------------------------------------- */
static const class Common final        // Members initially private
{ /* -- Private variables -------------------------------------------------- */
  const string     strTrue,            // C++ string as "true"
                   strFalse,           // C++ string as "false"
                   strEquals,          // C++ string as "="
                   strNOne,            // C++ string as "-1"
                   strZero,            // C++ string as "0"
                   strOne,             // C++ string as "1"
                   strSpace,           // C++ string with whitespace
                   strEllipsis,        // C++ string for "..."
                   strBlank,           // Empty c++ string
                   strCr,              // Carriage return c++ string
                   strLf,              // Linefeed c++ string
                   strCrLf,            // CR and LF c++ string
                   strCrLf2,           // Double CR and LF c++ string
                   strLfCr,            // LF and CR c++ string
                   strFSlash,          // C++ string as forward-slash '/'
                   strUnspec,          // C++ string as "<Unspecified>"
                   strNull;            // C++ string as "<NullPtr>"
  const char*const cpBlank;            // Blank C-String
  const locale     lLocaleCurrent;     // Current locale
  /* --------------------------------------------------------------- */ public:
  const locale &Locale(void) const { return lLocaleCurrent; }
  /* ----------------------------------------------------------------------- */
  const string &Blank(void) const { return strBlank; }
  const char *CBlank(void) const { return cpBlank; }
  /* ----------------------------------------------------------------------- */
  const string &Tru(void) const { return strTrue; }
  /* ----------------------------------------------------------------------- */
  const string &Fals(void) const { return strFalse; }
  /* ----------------------------------------------------------------------- */
  const string &Equals(void) const { return strEquals; }
  /* ----------------------------------------------------------------------- */
  const string &NOne(void) const { return strNOne; }
  /* ----------------------------------------------------------------------- */
  const string &Zero(void) const { return strZero; }
  /* ----------------------------------------------------------------------- */
  const string &One(void) const { return strOne; }
  /* ----------------------------------------------------------------------- */
  const string &Cr(void) const { return strCr; }
  /* ----------------------------------------------------------------------- */
  const string &Lf(void) const { return strLf; }
  /* ----------------------------------------------------------------------- */
  const string &CrLf(void) const { return strCrLf; }
  /* ----------------------------------------------------------------------- */
  const string &CrLf2(void) const { return strCrLf2; }
  /* ----------------------------------------------------------------------- */
  const string &LfCr(void) const { return strLfCr; }
  /* ----------------------------------------------------------------------- */
  const string &Space(void) const { return strSpace; }
  /* ----------------------------------------------------------------------- */
  const string &Ellipsis(void) const { return strEllipsis; }
  /* ----------------------------------------------------------------------- */
  const string &FSlash(void) const { return strFSlash; }
  /* ----------------------------------------------------------------------- */
  const string &Unspec(void) const { return strUnspec; }
  /* ----------------------------------------------------------------------- */
  const string &Null(void) const { return strNull; }
  /* -- Default Constructor ------------------------------------------------ */
  Common(void) :                       // No parameters
    /* -- Initialisers ----------------------------------------------------- */
    strTrue{ "true" },                 strFalse{ "false" },
    strEquals{ "=" },                  strNOne{ "-1" },
    strZero{ "0" },                    strOne{ "1" },
    strSpace{ " " },                   strEllipsis{ "..." },
    strCr{ "\r" },                     strLf{ "\n" },
    strCrLf{ strCr + strLf },          strCrLf2{ strCrLf + strCrLf },
    strLfCr{ strLf + strCr },          strFSlash{ "/" },
    strUnspec{ "<Unspecified>" },      strNull{ "<NullPtr>" },
    cpBlank(strBlank.c_str()),         lLocaleCurrent{ strBlank }
    /* -- No code ---------------------------------------------------------- */
    { }
} /* ----------------------------------------------------------------------- */
*cCommon;                              // Assigned in main function
/* -- Some helpful globals so not to repeat anything ----------------------- */
static const char*const cpTimeFormat = "%a %b %d %H:%M:%S %Y %z";
/* -- Append final parameter (uses copy elision) --------------------------- */
static void StrAppendHelper(ostringstream&) { }
/* -- Append a parameter (uses copy elision) ------------------------------- */
template<typename AnyType, typename ...VarArgs>
  static void StrAppendHelper(ostringstream &osS, const AnyType &atVal,
    const VarArgs &...vatArgs)
      { osS << atVal; StrAppendHelper(osS, vatArgs...); }
/* -- Append main function ------------------------------------------------- */
template<typename ...VarArgs>
  static const string StrAppend(const VarArgs &...vaVars)
{ // Theres no need to call this if theres no parameters
  static_assert(sizeof...(VarArgs) > 0, "Not enough parameters!");
  // Stream to write to
  ostringstream osS;
  // Build string
  StrAppendHelper(osS, vaVars...);
  // Return string
  return osS.str();
}
/* -- Append with formatted numbers ---------------------------------------- */
template<typename ...VarArgs>
  static const string StrAppendImbue(const VarArgs &...vaVars)
{ // Theres no need to call this if theres no parameters
  static_assert(sizeof...(VarArgs) > 0, "Not enough parameters!");
  // Stream to write to
  ostringstream osS;
  // Imbue current locale
  osS.imbue(cCommon->Locale());
  // Build string
  StrAppendHelper(osS, vaVars...);
  // Return appended string
  return osS.str();
}
/* -- Append final parameter (uses copy elision) --------------------------- */
static void StrFormatHelper(ostringstream &osS, const char *cpPos)
  { if(*cpPos) osS << cpPos; }
/* -- Process any value ------------------------------------------------- -- */
template<typename AnyType, typename ...VarArgs>
  static void StrFormatHelper(ostringstream &osS, const char *cpPos,
    const AnyType &atVal, const VarArgs &...vaVars)
{ // Find the mark that will be replaced by this parameter and if we
  // find the character?
  if(const char*const cpNewPos = strchr(cpPos, '$'))
  { // How far did we find the new position
    switch(const size_t stNum = static_cast<size_t>(cpNewPos - cpPos))
    { // One character? Just copy one character and move ahead two to skip
      // over the '$' we just processed.
      case 1: osS << *cpPos; cpPos += 2; break;
      // More than one character? Copy characters and stride over the '$'
      // we just processed. Better than storing single characters.
      default: osS << StdMove(string{ cpPos, stNum });
               cpPos += stNum + 1;
               break;
      // Did not move? This can happen at the start of the string. Just
      // move over the first '$'.
      case 0: ++cpPos; break;
    } // Push the value we are supposed to replace the matched '$' with.
    osS << atVal;
    // Process more parameters if we can.
    StrFormatHelper(osS, cpPos, vaVars...);
  } // Return the rest of the string.
  else StrFormatHelper(osS, cpPos);
}
/* -- Prepare message from c-string format --------------------------------- */
template<typename ...VarArgs>
  static const string StrFormat(const char*const cpFmt,
    const VarArgs &...vaVars)
{ // Theres no need to call this if theres no parameters
  static_assert(sizeof...(VarArgs) > 0, "Not enough parameters!");
  // Return if string empty of invalid
  if(UtfIsCStringNotValid(cpFmt)) return {};
  // Stream to write to
  ostringstream osS;
  // Format the text
  StrFormatHelper(osS, cpFmt, vaVars...);
  // Return formated text
  return osS.str();
}
/* == Format a number ====================================================== */
template<typename IntType>
  static const string StrReadableFromNum(const IntType itVal,
    const int iPrec=0)
      { return StdMove(StrAppendImbue(fixed, setprecision(iPrec), itVal)); }
/* -- Trim specified characters from string -------------------------------- */
static const string StrTrim(const string &strStr, const char cChar)
{ // Return empty string if source string is empty
  if(strStr.empty()) return strStr;
  // Calculate starting misoccurance of character. Return original if not found
  const size_t stBegin = strStr.find_first_not_of(cChar);
  if(stBegin == string::npos) return strStr;
  // Calculate ending misoccurance of character then copy and return the string
  return strStr.substr(stBegin, strStr.find_last_not_of(cChar) - stBegin + 1);
}
/* -- Convert integer to string with padding and precision ----------------- */
template<typename IntType>static const string StrFromNum(const IntType itV,
  const int iW=0, const int iPrecision=numeric_limits<IntType>::digits10)
    { return StdMove(StrAppend(setw(iW), fixed,
        setprecision(iPrecision), itV)); }
/* -- Quickly convert numbered string to integer --------------------------- */
template<typename IntType=int64_t>
  static const IntType StrToNum(const string &strValue)
{ // Put value into input string stream
  istringstream isS{ strValue };
  // Push value into integer
  if constexpr(is_enum_v<IntType>)
  { // Underlying value of the enum type to store into
    underlying_type_t<IntType> utN;
    // Store the value
    isS >> utN;
    // Return converting it back to the original type (no performance loss)
    return static_cast<IntType>(utN);
  } // Value is not enum type?
  else
  { // Value to store into
    IntType itN;
    // Store the value
    isS >> itN;
    // Return the value
    return itN;
  }
}
/* -- Quickly convert hex string to integer ------------------------------== */
template<typename IntType=int64_t>
  static const IntType StrHexToInt(const string &strValue)
{ // Value to store into
  IntType itN;
  // Put value into input string stream
  istringstream isS{ strValue };
  // Push value into integer
  isS >> hex >> itN;
  // Return result
  return itN;
}
/* -- Convert hex to string with zero padding ------------------------------ */
template<typename IntType>
  static const string StrHexFromInt(const IntType itVal, const int iPrec=0)
    { return StdMove(StrAppend(setfill('0'), hex, setw(iPrec), itVal)); }
/* -- Return if specified string has numbers ------------------------------- */
static bool StrIsAlpha(const string &strValue)
  { return StdAllOf(par_unseq, strValue.cbegin(), strValue.cend(),
      [](const char cValue) { return isalpha(static_cast<int>(cValue)); }); }
/* -- Return if specified string has numbers ------------------------------- */
static bool StrIsAlphaNum(const string &strValue)
  { return StdAllOf(par_unseq, strValue.cbegin(), strValue.cend(),
      [](const char cValue) { return isalnum(static_cast<int>(cValue)); }); }
/* -- Return if specified string is a valid integer ------------------------ */
template<typename IntType=int64_t>static bool StrIsInt(const string &strValue)
{ // Get string stream
  istringstream isS{ strValue };
  // Test with string stream
  IntType itV; isS >> noskipws >> itV;
  // Return if succeeded
  return isS.eof() && !isS.fail();
}
/* -- Return if specified string is a valid float -------------------------- */
static bool StrIsFloat(const string &strValue)
  { return StrIsInt<double>(strValue); }
/* -- Return true if string is a value number to the power of 2 ------------ */
static bool StrIsNumPOW2(const string &strValue)
  { return !strValue.empty() &&
      StdIntIsPOW2(StdAbsolute(StrToNum(strValue))); }
/* -- Convert error number to string --------------------------------------- */
static const string StrFromErrNo(const int iErrNo=errno)
{ // Buffer to store error message into
  string strErr; strErr.resize(128);
  // Windows?
#if defined(WINDOWS)
  // 'https://msdn.microsoft.com/en-us/library/51sah927.aspx' says:
  // "Your string message can be, at most, 94 characters long."
  if(strerror_s(const_cast<char*>(strErr.c_str()), strErr.capacity(), iErrNo))
    strErr.assign(StrAppend("Error ", iErrNo));
  // OSX?
#elif defined(MACOS)
  // Grab the error result and if failed? Just put in the error number continue
  if(strerror_r(iErrNo, const_cast<char*>(strErr.c_str()), strErr.capacity()))
    strErr.assign(StrAppend("Error ", iErrNo));
  // Linux?
#elif defined(LINUX)
  // Grab the error result and if failed? Set a error and continue
  const char*const cpResult =
    strerror_r(iErrNo, const_cast<char*>(strErr.c_str()), strErr.capacity());
  if(!cpResult) strErr = StrAppend("Error ", iErrNo);
  // We got a message but if was not put in our buffer just return as is
  else if(cpResult != strErr.c_str()) return cpResult;
#endif
  // Resize and compact the buffer
  strErr.resize(strlen(strErr.c_str()));
  strErr.shrink_to_fit();
  // Have to do this because the string is still actually 94 bytes long
  return strErr;
}
/* -- Helper plugin for C runtime errno checking --------------------------- */
struct ErrorPluginStandard final
{ /* -- Exception class helper macro for C runtime errors ------------------ */
#define XCL(r,...) throw Error<ErrorPluginStandard>(r, ## __VA_ARGS__)
  /* -- Constructor to add C runtime error code ---------------------------- */
  explicit ErrorPluginStandard(ostringstream &osS)
    { osS << "\n+ Reason<" << StdGetError() << "> = \""
          << StrFromErrNo() << "\"."; }
};/* ----------------------------------------------------------------------- */
/* -- Convert special formatted string to unix timestamp ------------------- */
static StdTimeT StrParseTime2(const string &strS)
{ // Time structure
  StdTMStruct tData;
  // Scan timestamp into time structure (Don't care about day name). We'll
  // store the timezone in tm_isdst and we'll optimise this by storing the
  // month string in the actual month integer var (4 or 8 bytes so safe).
  // Fmt: %3s %3s %02d %02d:%02d:%02d %05d %04d
  // Test example to just quickly copy and paste in the engine...
  // lexec 'Console.Write(Util.ParseTime2("Mon Mar 14 00:00:00 -0800 2017"));'
  istringstream isS{ strS };
  isS >> get_time(&tData, "%a %b %d %T");
  if(isS.fail()) return 0;
  isS >> tData.tm_wday;
  isS >> get_time(&tData, "%Y");
  if(isS.fail()) return 0;
  // No daylight savings
  tData.tm_isdst = 0;
  // Return timestamp and adjust for specified timezone if neccesary
  return StdMkTime(&tData) + (!tData.tm_wday ? 0 : ((tData.tm_wday < 0 ?
    ((tData.tm_wday % 100) * 60) : -((tData.tm_wday % 100) * 60)) +
    ((tData.tm_wday / 100) * 3600)));
}
/* -- Convert ISO 8601 string to unix timestamp ---------------------------- */
static StdTimeT StrParseTime(const string &strS,
  const char*const cpF="%Y-%m-%dT%TZ")
{ // Time structure
  StdTMStruct tData;
  // Create static input stringstream (safe and fast in c++11)
  istringstream isS{ strS };
  // Scan timestamp into time structure
  isS >> get_time(&tData, cpF);
  if(isS.fail()) return 0;
  // Fill in other useless junk in the struct
  tData.tm_isdst = 0;
  // Return timestamp
  return StdMkTime(&tData);
}
/* -- Convert writable reference string to uppercase ----------------------- */
static string &StrToUpCaseRef(string &strStr)
{ // If string is not empty
  if(!strStr.empty())
    StdTransform(par_unseq, strStr.begin(), strStr.end(),
      strStr.begin(), [](char cChar)->char
        { return static_cast<char>(toupper(static_cast<int>(cChar))); });
  // Return output
  return strStr;
}
/* -- Convert writable referenced string to lowercase ---------------------- */
static string &StrToLowCaseRef(string &strStr)
{ // If string is not empty
  if(!strStr.empty())
    StdTransform(par_unseq, strStr.begin(), strStr.end(),
      strStr.begin(), [](char cChar)->char
        { return static_cast<char>(tolower(static_cast<int>(cChar))); });
  // Return output
  return strStr;
}
/* -- Basic multiple replace of text in string ----------------------------- */
template<class ListType=StrPairList>
  static string &StrReplaceEx(string &strDest, const ListType &ltList)
{ // Return original string if empty
  if(strDest.empty() || ltList.empty()) return strDest;
  // Current index to scan
  size_t stPos = 0;
  // Repeat...
  do
  { // Enumerate each occurence to find...
    for(const auto &spItem : ltList)
    { // Get string to find
      const string &strWhat = spItem.first;
      // Last cut position and current character index
      if(strncmp(strDest.c_str()+stPos, strWhat.data(), strWhat.length()))
        continue;
      // Get string to replace with
      const string &strWith = spItem.second;
      // Replace the occurence with the specified text
      strDest.replace(stPos, strWhat.length(), strWith);
      // Go forward so we can search for the next occurence
      stPos += strWith.length();
      // Start again
      goto NextCharacter;
    } // Occurences not found
    ++stPos;
    // Occurence found
    NextCharacter:;
  } // ...until no more characters left
  while(stPos < strDest.length());
  // Return the string we build
  return strDest;
}
/* -- Basic replace of text in string -------------------------------------- */
static string &StrReplace(string &strStr, const char cWhat, const char cWith)
{ // Return original string if empty
  if(strStr.empty()) return strStr;
  // For each occurence of 'strWhat' with 'strWith'.
  for(size_t stPos  = strStr.find(cWhat, 0);
             stPos != string::npos;
             stPos  = strStr.find(cWhat, stPos)) strStr[stPos++] = cWith;
  // Return string
  return strStr;
}
/* -- Basic replace of text in string -------------------------------------- */
static string StrReplace(const string &strStr, const char cWhat,
  const char cWith)
    { string strDst{ strStr }; return StrReplace(strDst, cWhat, cWith); }
/* ------------------------------------------------------------------------- */
static string &StrReplace(string &strDest, const string &strWhat,
  const string &strWith)
{ // Return original string if empty
  if(strDest.empty()) return strDest;
  // For each occurence of 'strWhat' with 'strWith'.
  for(size_t stPos  = strDest.find(strWhat,0);
             stPos != string::npos;
             stPos  = strDest.find(strWhat, stPos))
  { // Replace occurence
    strDest.replace(stPos, strWhat.length(), strWith);
    // Push position forward so we don't risk infinite loop
    stPos += strWith.length();
  } // Return string
  return strDest;
}
/* -- Basic replace of text in string -------------------------------------- */
static string StrReplace(const string &strIn, const string &strWhat,
  const string &strWith)
    { string strOut{ strIn }; return StrReplace(strOut, strWhat, strWith); }
/* -- Replace all occurences of whitespace with plus ----------------------- */
static const string StrUrlEncodeSpaces(const string &strText)
  { return StrReplace(strText, ' ', '+'); }
/* ------------------------------------------------------------------------- */
static const string &StrIsBlank(const string &strIn, const string &strAlt)
  { return strIn.empty() ? strAlt : strIn; }
/* ------------------------------------------------------------------------- */
static const string &StrIsBlank(const string &strIn)
  { return StrIsBlank(strIn, cCommon->Blank()); }
/* ------------------------------------------------------------------------- */
template<typename T>static const char *StrCPluralise(const T tCount,
  const char*const cpSingular, const char*const cpPlural)
    { return tCount == 1 ? cpSingular : cpPlural; }
/* ------------------------------------------------------------------------- */
template<typename T>static const string StrPluraliseNum(const T tCount,
  const char*const cpSingular, const char*const cpPlural)
   { return StdMove(StrAppend(tCount, ' ',
       StdMove(StrCPluralise(tCount, cpSingular, cpPlural)))); }
/* ------------------------------------------------------------------------- */
template<typename T>static const string StrPluraliseNumEx(const T tCount,
  const char*const cpSingular, const char*const cpPlural)
   { return StdMove(StrAppend(StrReadableFromNum(tCount), ' ',
       StdMove(StrCPluralise(tCount, cpSingular, cpPlural)))); }
/* -- Convert time to long duration ---------------------------------------- */
static const string StrLongFromDuration(const StdTimeT tDuration,
  unsigned int uiCompMax = StdMaxUInt)
{ // Time buffer
  StdTMStruct tD;
  // Lets convert the duration as a time then it will be properly formated
  // in terms of leap years, proper days in a month etc.
  StdGMTime(&tD, &tDuration);
  // Output string
  ostringstream osS;
  // If failed? Manually do it
  if(tD.tm_year == -1)
  { // Clear years and months since we can't realiably calculate that.
    tD.tm_year = tD.tm_mon = 0;
    // Set days, hours, minutes and seconds
    tD.tm_mday = static_cast<int>(tDuration / 86400);
    tD.tm_hour = static_cast<int>(tDuration / 3600 % 24);
    tD.tm_min = static_cast<int>(tDuration / 60 % 60);
    tD.tm_sec = static_cast<int>(tDuration % 60);
  } // Succeeded, subtract 70 as it returns as years past 1900.
  else tD.tm_year -= 70;
  // Add years?
  if(tD.tm_year && uiCompMax > 0)
  { // Do add years
    osS << StrPluraliseNum(tD.tm_year, "year", "years");
    --uiCompMax;
  } // Add months?
  if(tD.tm_mon && uiCompMax > 0)
  { // Do add months
    osS << (osS.tellp() ? cCommon->Space() : cCommon->Blank())
        << StrPluraliseNum(tD.tm_mon, "month", "months");
    --uiCompMax;
  } // Add days? (removing the added 1)
  if(--tD.tm_mday && uiCompMax > 0)
  { // Do add days
    osS << (osS.tellp() ? cCommon->Space() : cCommon->Blank())
        << StrPluraliseNum(tD.tm_mday, "day", "days");
    --uiCompMax;
  } // Add hours?
  if(tD.tm_hour && uiCompMax > 0)
  { // Do add hours
    osS << (osS.tellp() ? cCommon->Space() : cCommon->Blank())
        << StrPluraliseNum(tD.tm_hour, "hour", "hours");
    --uiCompMax;
  } // Add Minutes?
  if(tD.tm_min && uiCompMax > 0)
  { // Do add minutes
    osS << (osS.tellp() ? cCommon->Space() : cCommon->Blank())
        << StrPluraliseNum(tD.tm_min, "min", "mins");
    --uiCompMax;
  } // Check seconds
  if((tD.tm_sec || !tDuration) && uiCompMax > 0)
    osS << (osS.tellp() ? cCommon->Space() : cCommon->Blank())
        << StrPluraliseNum(tD.tm_sec, "sec", "secs");
  // Return string
  return osS.str();
}
/* ------------------------------------------------------------------------- */
static const char *StrGetPositionSuffix(const uint64_t qPosition)
{ // Get value as base 100
  const uint64_t qVb100 = qPosition % 100;
  // Number not in teens? Compare value as base 10 instead
  if(qVb100 <= 10 || qVb100 >= 20) switch(qPosition % 10)
  { case 1: return "st"; case 2: return "nd"; case 3: return "rd";
    default: break;
  } // Everything else is 'th'
  return "th";
} /* -- Get position of number as a string --------------------------------- */
static const string StrFromPosition(const uint64_t qPosition)
  { return StrAppend(qPosition, StrGetPositionSuffix(qPosition)); }
/* -- Capitalise a string -------------------------------------------------- */
static const string StrCapitalise(const string &strStr)
{ // Capitalise first character if string not nullptr or empty
  if(strStr.empty()) return strStr;
  // Duplicate the string anad uppercase the first character
  string strNew{ strStr };
  strNew[0] = static_cast<char>(toupper(strStr.front()));
  // Return provided string
  return strNew;
}
/* -- Evaluate a list of booleans and return a character value ------------- */
static const string
  StrFromEvalTokens(const vector<pair<const bool,const char>> &etData)
    { return etData.empty() ? cCommon->Blank() :
      accumulate(etData.cbegin(), etData.cend(), cCommon->Blank(),
        [](const string &strOut, const auto &bcpPair)
          { return bcpPair.first ? StrAppend(strOut,
            bcpPair.second) : strOut; }); }
/* -- Convert time to short duration --------------------------------------- */
static const string StrShortFromDuration(const double dDuration,
  const int iPrecision=6)
{ // Output string
  ostringstream osS;
  // Get duration ceiled and if negative?
  double dInt, dFrac = modf(dDuration, &dInt);
  if(dInt < 0)
  { // Set negative symbol and negate the duration
    osS << '-';
    dInt = -dInt;
    dFrac = -dFrac;
  } // Set floating point precision with zero fill
  osS << fixed << setfill('0') << setprecision(0);
  // Have days?
  if(dInt >= 86400)
    osS <<            floor(dInt/86400)          << ':'
        << setw(2) << fmod(floor(dInt/3600), 24) << ':'
        << setw(2) << fmod(floor(dInt/60),   60) << ':' << setw(2);
  // No days, but hours?
  else if(dInt >= 3600)
    osS <<            fmod(floor(dInt/3600), 24) << ':'
        << setw(2) << fmod(floor(dInt/60),   60) << ':' << setw(2);
  // No hours, but minutes?
  else if(dInt >= 60)
    osS << fmod(floor(dInt/60), 60) << ':' << setw(2);
  // No minutes so no zero padding
  else osS << setw(0);
  // On the seconds part, we have a problem where having a precision
  // of zero is causing stringstream to round so we'll just convert it to an
  // int instead to fix it.
  osS << fmod(dInt, 60);
  if(iPrecision > 0)
    osS << '.' << setw(iPrecision) <<
      static_cast<unsigned int>(fabs(dFrac) * pow(10.0, iPrecision));
  // Return string
  return osS.str();
}
/* -- Return true of false ------------------------------------------------- */
static const string &StrFromBoolTF(const bool bCondition)
  { return bCondition ? cCommon->Tru() : cCommon->Fals(); }
static const char *StrFromBoolYN(const bool bCondition)
  { return bCondition ? "X" : "-"; }
/* -- Count occurence of string -------------------------------------------- */
static size_t StrCountOccurences(const string &strStr, const string &strWhat)
{ // Zero if string is empty
  if(strStr.empty() || strWhat.empty()) return 0;
  // Matching occurences
  size_t stCount = 0;
  // Find occurences
  for(size_t stIndex = strStr.find(strWhat);
             stIndex != string::npos;
             stIndex = strStr.find(strWhat, stIndex + 1)) ++stCount;
  // Return occurences
  return stCount;
}
/* -- Get return character format of text string --------------------------- */
static const string StrGetReturnFormat(const string &strIn)
{ // String is not empty?
  if(!strIn.empty())
  { // Enumerate each character...
    for(string::const_iterator ciC{ strIn.cbegin() };
                               ciC != strIn.cend();
                             ++ciC)
    { // Test character
      switch(*ciC)
      { // Carriage-return found
        case '\r':
          return find(ciC, strIn.cend(), '\n') != strIn.cend() ?
             cCommon->CrLf() : cCommon->Cr();
        // Line-feed found
        case '\n':
          return find(ciC, strIn.cend(), '\r') != strIn.cend() ?
             cCommon->LfCr() : cCommon->Lf();
        // Anything else is ignored
        default: break;
      }
    } // Nothing found
  } // Return blank string
  return {};
}
/* -- Implode a stringdeque to a single string ----------------------------- */
template<typename DequeType>
  static const string StrImplode(const DequeType &dtL,
    const string &strSep=cCommon->Space())
{ // Done if empty or begin position is invalid
  if(dtL.empty()) return {};
  // Create output only string stream which stays cached (safe in c++11)
  ostringstream osS;
  // Build command string from vector (this and next line don't seem optimal)
  const typename DequeType::const_iterator
    dtitLastButOne{ prev(dtL.cend(), 1) };
  copy(dtL.cbegin(), dtitLastButOne,
    ostream_iterator<string>{ osS, strSep.c_str() });
  osS << *dtitLastButOne;
  // Done
  return osS.str();
}
/* -- Converts the key/value pairs to a stringvector ----------------------- */
static const string ImplodeMap(const StrNCStrMap &ssmSrc,
  const string &strLineSep=cCommon->Space(),
  const string &strKeyValSep=cCommon->Equals(),
  const string &strValEncaps="\"")
{ // Done if empty
  if(ssmSrc.empty()) return {};
  // Make string vector to implode and reserve memory for items.
  // Insert each value in the map with the appropriate seperators.
  StrVector svRet; svRet.reserve(ssmSrc.size());
  transform(ssmSrc.cbegin(), ssmSrc.cend(), back_inserter(svRet),
    [&strKeyValSep, &strValEncaps](const auto &vIter)
      { return StdMove(StrAppend(vIter.first, strKeyValSep,
          strValEncaps, vIter.second, strValEncaps)); });
  // Return vector imploded into a string
  return StrImplode(svRet, strLineSep);
} /* -- Implode a stringdeque to a single string --------------------------- */
template<typename AnyArray>
  static const string StrImplode(const AnyArray aArray,
    const size_t &stBegin=0, const string &strSep=cCommon->Space())
{ // Done if empty or begin position is invalid
  if(aArray.empty() || stBegin >= aArray.size()) return {};
  // If we have only one item, just return its string
  if(aArray.size()-stBegin == 1) return aArray[stBegin];
  // Create output only string stream which stays cached (safe in c++11)
  ostringstream osS;
  // Build command string from vector
  copy(next(aArray.cbegin(), static_cast<ssize_t>(stBegin)),
    prev(aArray.cend(), 1), ostream_iterator<string>(osS, strSep.c_str()));
  // Add last item without a separator
  osS << aArray.back();
  // Done
  return osS.str();
}
/* ------------------------------------------------------------------------- */
template<typename AnyType>
  static const string StrPrefixPosNeg(const AnyType atVal,
    const int iPrecision)
      { return StdMove(StrAppend(showpos, fixed, setprecision(iPrecision),
          atVal)); }
/* ------------------------------------------------------------------------- */
template<typename AnyType>
  static const string StrPrefixPosNegReadable(const AnyType atVal,
    const int iPrecision)
      { return StdMove(StrAppendImbue(showpos, fixed, setprecision(iPrecision),
          atVal)); }
/* ------------------------------------------------------------------------- */
template<typename OutType, typename InType, class SuffixClass>
  static OutType StrToReadableSuffix(const InType itValue,
    const char**const cpSuffix, int &iPrecision, const SuffixClass &scLookup,
    const char*const cpDefault)
{ // Check types
  static_assert(is_floating_point_v<OutType>, "OutType not floating point!");
  static_assert(is_integral_v<InType>, "InType not integral!");
  // Value to return
  OutType otReturn;
  // Discover the best measurement to show by testing each unit from the
  // lookup table to see if it is divisible and if it is not?
  if(!any_of(scLookup.cbegin(), scLookup.cend(),
    [&otReturn, itValue, &cpSuffix](const auto &aItem)
  { // Calculate best measurement to show
    if(itValue < aItem.vValue) return false;
    // Set suffix that was sent
    *cpSuffix = aItem.cpSuf;
    otReturn = static_cast<OutType>(itValue) / aItem.vValue;
    // Success
    return true;
  }))
  { // Not found any matches so precision will now be zero
    iPrecision = 0;
    // Suffix is default suffix
    *cpSuffix = cpDefault;
    // Convert the input value to the output value
    otReturn = static_cast<OutType>(itValue);
  } // Return result
  return otReturn;
}
/* ------------------------------------------------------------------------- */
template<typename OutType, typename InType, class SuffixClass>
  static OutType StrToReadableSuffix(const InType itValue,
    const char**const cpSuffix, int &iPrecision, const SuffixClass &scLookup)
{ return StrToReadableSuffix<OutType, InType, SuffixClass>(itValue,
    cpSuffix, iPrecision, scLookup, cCommon->CBlank()); }
/* ------------------------------------------------------------------------- */
template<typename IntType>
  static double StrToBytesHelper(const IntType itBytes,
    const char**const cpSuffix, int &iPrecision)
{ // A test to perform
  struct ByteValue { const IntType vValue; const char*const cpSuf; };
  // If input value is 64-bit?
  if constexpr(sizeof(IntType) == sizeof(uint64_t))
  { // Tests lookup table. This is all we can fit in a 64-bit integer
    static const array<const ByteValue,6> bvLookup{ {
      { 0x1000000000000000, "EB" }, { 0x0004000000000000, "PB" },
      { 0x0000010000000000, "TB" }, { 0x0000000040000000, "GB" },
      { 0x0000000000100000, "MB" }, { 0x0000000000000400, "KB" }
    } };
    // Return result
    return StrToReadableSuffix<double>(itBytes,
      cpSuffix, iPrecision, bvLookup, "B");
  } // If input value is 32-bit?
  if constexpr(sizeof(IntType) == sizeof(uint32_t))
  { // Tests lookup table. This is all we can fit in a 32-bit integer
    static const array<const ByteValue,3> bvLookup{ {
      { 0x40000000, "GB" }, { 0x00100000, "MB" }, { 0x00000400, "KB" }
    } };
    // Return result
    return StrToReadableSuffix<double>(itBytes,
      cpSuffix, iPrecision, bvLookup, "B");
  } // If input value is 16-bit?
  if constexpr(sizeof(IntType) == sizeof(uint16_t))
  { // Tests lookup table. This is all we can fit in a 16-bit integer
    static const array<const ByteValue,1> bvLookup{ { { 0x0400, "KB" } } };
    // Return result
    return StrToReadableSuffix<double>(itBytes,
      cpSuffix, iPrecision, bvLookup, "B");
  } // Input value is not 64, 32 nor 16 bit? Use a empty table
  static const array<const ByteValue,0> bvLookup{ { } };
  // Show error
  return StrToReadableSuffix<double>(itBytes,
    cpSuffix, iPrecision, bvLookup, "B");
}
/* ------------------------------------------------------------------------- */
template<typename IntType>
  static const string StrToBytes(const IntType itBytes, int iPrecision=2)
{ // Process a human readable value for the specified number of bytes
  const char *cpSuffix = nullptr;
  const double dVal =
    StrToBytesHelper<IntType>(itBytes, &cpSuffix, iPrecision);
  // Move the stringstreams output string into the return value.
  return StrAppend(fixed, setprecision(iPrecision), dVal, cpSuffix);
}
/* ------------------------------------------------------------------------- */
template<typename IntType>
  static const string StrToReadableBytes(const IntType itBytes,
  int iPrecision=2)
{ // Process a human readable value for the specified number of bytes
  const char *cpSuffix = nullptr;
  const double dVal =
    StrToBytesHelper<IntType>(itBytes, &cpSuffix, iPrecision);
  // Move the stringstreams output string into the return value.
  return StrAppendImbue(fixed, setprecision(iPrecision), dVal, cpSuffix);
}
/* ------------------------------------------------------------------------- */
template<typename IntType>
  static double StrToReadableBitsHelper(const IntType itBits,
    const char**const cpSuffix, int &iPrecision)
{ // A test to perform
  struct BitValue { const IntType vValue; const char*const cpSuf; };
  // If input value is 64-bit?
  if constexpr(sizeof(IntType) == sizeof(uint64_t))
  { // Tests lookup table. This is all we can fit in a 64-bit integer.
    static const array<const BitValue,6> bvLookup{ {
      { 1000000000000000000, "Eb" }, { 1000000000000000, "Pb" },
      {       1000000000000, "Tb" }, {       1000000000, "Gb" },
      {             1000000, "Mb" }, {             1000, "Kb" },
    } };
    // Return result
    return StrToReadableSuffix<double>(itBits,
      cpSuffix, iPrecision, bvLookup, "b");
  } // If input value is 32-bit?
  if constexpr(sizeof(IntType) == sizeof(uint32_t))
  { // Tests lookup table. This is all we can fit in a 32-bit integer.
    static const array<const BitValue,3> bvLookup{ {
      { 1000000000, "Gb" }, { 1000000, "Mb" }, { 1000, "Kb" },
    } };
    // Return result
    return StrToReadableSuffix<double>(itBits,
      cpSuffix, iPrecision, bvLookup, "b");
  } // If input value is 16-bit?
  if constexpr(sizeof(IntType) == sizeof(uint16_t))
  { // Tests lookup table. This is all we can fit in a 16-bit integer.
    static const array<const BitValue,6> bvLookup{ { { 1000, "Kb" } } };
    // Return result
    return StrToReadableSuffix<double>(itBits,
      cpSuffix, iPrecision, bvLookup, "b");
  } // Input value is not 64, 32 nor 16 bit? Use a empty table
  static const array<const BitValue,0> bvLookup{ { } };
  // Show error
  return StrToReadableSuffix<double>(itBits,
    cpSuffix, iPrecision, bvLookup, "b");
}
/* ------------------------------------------------------------------------- */
template<typename IntType>
  static const string StrToBits(const IntType itBits, int iPrecision=2)
{ // Process a human readable value for the specified number of bits
  const char *cpSuffix = nullptr;
  const double dVal =
    StrToReadableBitsHelper<IntType>(itBits, &cpSuffix, iPrecision);
  // Move the stringstreams output string into the return value.
  return StrAppend(fixed, setprecision(iPrecision), dVal, cpSuffix);
}
/* ------------------------------------------------------------------------- */
template<typename IntType>
  static const string StrToReadableBits(const IntType itBits, int iPrecision)
{ // Process a human readable value for the specified number of bits
  const char *cpSuffix = nullptr;
  const double dVal =
    StrToReadableBitsHelper<IntType>(itBits, &cpSuffix, iPrecision);
  // Move the stringstreams output string into the return value.
  return StrAppendImbue(fixed, setprecision(iPrecision), dVal, cpSuffix);
}
/* ------------------------------------------------------------------------- */
template<typename IntType>
  static double StrToReadableHelper(const IntType itValue,
    const char**const cpSuffix, int &iPrecision)
{ // A test to perform
  struct Value { const IntType vValue; const char*const cpSuf; };
  // If input value is 64-bit?
  if constexpr(sizeof(IntType) == sizeof(uint64_t))
  { // Tests lookup table. This is all we can fit in a 64-bit integer.
    static const array<const Value,4> vLookup{ {
      { 1000000000000, "T" }, { 1000000000, "B" },
      { 1000000,       "M" }, { 1000,       "K" }
    } };
    // Return result
    return StrToReadableSuffix<double>(itValue, cpSuffix, iPrecision, vLookup);
  } // If input value is 32-bit?
  if constexpr(sizeof(IntType) == sizeof(uint32_t))
  { // Tests lookup table. This is all we can fit in a 64-bit integer.
    static const array<const Value,3> vLookup{ {
      { 1000000000, "B" }, { 1000000, "M" }, { 1000, "K" }
    } };
    // Return result
    return StrToReadableSuffix<double>(itValue, cpSuffix, iPrecision, vLookup);
  } // If input value is 16-bit?
  if constexpr(sizeof(IntType) == sizeof(uint16_t))
  { // Tests lookup table. This is all we can fit in a 64-bit integer.
    static const array<const Value,1> vLookup{ { { 1000, "K" } } };
    // Return result
    return StrToReadableSuffix<double>(itValue, cpSuffix, iPrecision, vLookup);
  } // Input value is not 64, 32 nor 16 bit? Use a empty table
  static const array<const Value,0> vLookup{ { } };
  // Show error
  return StrToReadableSuffix<double>(itValue, cpSuffix, iPrecision, vLookup);
}
/* ------------------------------------------------------------------------- */
template<typename IntType>
  static const string StrToGrouped(const IntType itValue, int iPrecision=2)
{ // Process a human readable value for the specified number of bits
  const char *cpSuffix = nullptr;
  const double dVal =
    StrToReadableHelper<IntType>(itValue, &cpSuffix, iPrecision);
  // Move the stringstreams output string into the return value.
  return StrAppend(fixed, setprecision(iPrecision), dVal, cpSuffix);
}
/* ------------------------------------------------------------------------- */
template<typename IntType>
  static const string StrToReadableGrouped(const IntType itValue,
    int iPrecision)
{ // Process a human readable value for the specified number of bits
  const char *cpSuffix = nullptr;
  const double dVal =
    StrToReadableHelper<IntType>(itValue, &cpSuffix, iPrecision);
  // Move the FORMATTED stringstreams output string into the return value.
  return StrAppendImbue(fixed, setprecision(iPrecision), dVal, cpSuffix);
}
/* ------------------------------------------------------------------------- */
static size_t StrFindCharForwards(const string &strS, size_t stStart,
  const size_t stEnd, const char cpChar)
{ // Until we've reached the limit
  while(stStart < stEnd && stStart != string::npos)
  { // Return position if we find the character
    if(strS[stStart] == cpChar) return stStart;
    // Goto next index and try again
    ++stStart;
  } // Failed so return so
  return string::npos;
}
/* ------------------------------------------------------------------------- */
static size_t StrFindCharBackwards[[maybe_unused]](const string &strS,
  size_t stStart, const size_t stEnd, const char cpChar)
{ // Until we've reached the limit
  while(stStart >= stEnd && stStart != string::npos)
  { // Return position if we find the character
    if(strS[stStart] == cpChar) return stStart;
    // Goto next index and try again
    --stStart;
  } // Failed so return so
  return string::npos;
}
/* ------------------------------------------------------------------------- */
static size_t StrFindCharNotForwards[[maybe_unused]](const string &strS,
  size_t stStart, const size_t stEnd, const char cpChar)
{ // Until we've reached the limit
  while(stStart < stEnd && stStart != string::npos)
  { // Return position if we find the character
    if(strS[stStart] != cpChar) return stStart;
    // Goto next index and try again
    ++stStart;
  } // Failed so return so
  return string::npos;
}
/* ------------------------------------------------------------------------- */
static size_t StrFindCharNotForwards(const string &strS, size_t stStart,
  const size_t stEnd)
{ // Until we've reached the limit
  while(stStart < stEnd && stStart != string::npos)
  { // Return position if we find a non-control character
    if(strS[stStart] > ' ') return stStart;
    // We could not match any character
    ++stStart;
  } // Failed so return so
  return string::npos;
}
/* ------------------------------------------------------------------------- */
static size_t StrFindCharNotBackwards[[maybe_unused]](const string &strS,
  size_t stStart, const size_t stEnd, const char cpChar)
{ // Until we've reached the limit
  while(stStart >= stEnd && stStart != string::npos)
  { // Return position if we find the character
    if(strS[stStart] != cpChar) return stStart;
    // Goto next index and try again
    --stStart;
  } // Failed so return so
  return string::npos;
}
/* ------------------------------------------------------------------------- */
static size_t StrFindCharNotBackwards(const string &strS, size_t stStart,
  const size_t stEnd)
{ // Until we've reached the limit
  while(stStart >= stEnd && stStart != string::npos)
  { // Return position if we find a non-control character
    if(strS[stStart] > ' ') return stStart;
    // We could not match any character
    --stStart;
  } // Failed so return so
  return string::npos;
}
/* -- Do convert the specified structure to string ------------------------= */
static const string StrFromTimeTM(const StdTMStruct &tmData,
  const char*const cpF) { return StrAppend(put_time(&tmData, cpF)); }
/* -- Convert specified timestamp to string -------------------------------- */
static const string StrFromTimeTT(const StdTimeT ttTimestamp,
  const char*const cpFormat = cpTimeFormat)
{ // Convert it to local time in a structure
  StdTMStruct tmData; StdLocalTime(&tmData, &ttTimestamp);
  // Do the parse and return the string
  return StrFromTimeTM(tmData, cpFormat);
}
/* -- Remove suffixing carriage return and line feed ----------------------- */
static string &StrChop(string &strStr)
{ // Error message should have a carriage return/line feed so remove it
  while(!strStr.empty() && (strStr.back() == '\r' || strStr.back() == '\n'))
    strStr.pop_back();
  // Return string
  return strStr;
}
/* -- Convert specified timestamp to string (UTC) -------------------------- */
static const string StrFromTimeTTUTC(const StdTimeT ttTimestamp,
  const char*const cpFormat = cpTimeFormat)
{ // Convert it to local time
  StdTMStruct tmData; StdGMTime(&tmData, &ttTimestamp);
  // Do the parse and return the string
  return StrFromTimeTM(tmData, cpFormat);
}
/* ------------------------------------------------------------------------- */
template<typename FloatType>
  static const string StrFromRatio(const FloatType ftAntecedent,
    const FloatType ftConsequent)
{ // Convert to double if neccesary
  const double dAntecedent = static_cast<double>(ftAntecedent),
               dConsequent = static_cast<double>(ftConsequent);
  // Return if invalid number or the below loop can infinitely enumerate
  if(dAntecedent <= 0.0 || dConsequent <= 0.0) return "N/A";
  // Divisor to use
  double dDivisor;
  // Loop until common denominator found
  for(double dNumerator = dAntecedent, dDenominator = dConsequent; ; )
  { // Find the lowest numerator and break if we find it
    dNumerator = fmod(dNumerator, dDenominator);
    if(dNumerator == 0.0) { dDivisor = dDenominator; break; }
    // Find the lowest denominator and break if we find it
    dDenominator = fmod(dDenominator, dNumerator);
    if(dDenominator == 0.0) { dDivisor = dNumerator; break; }
  } // Return lowest numerator and denominator
  return StrAppend(fixed, setprecision(0), ceil(dAntecedent / dDivisor), ':',
    ceil(dConsequent / dDivisor));
}
/* -- Convert list to exploded string -------------------------------------- */
template<class ListType>string StrExplodeEx(const ListType &lType,
  const string &strSep, const string &strLast)
{ // String to return
  ostringstream ossOut;
  // What is the size of this string
  switch(lType.size())
  { // Empty list? Just break to return empty string
    case 0: break;
    // Only one? Just return the string directly
    case 1: return *lType.cbegin();
    // Two? Return a simple appendage.
    case 2: ossOut << *lType.cbegin() << strLast << *lType.crbegin(); break;
    // More than two? Write the first item first
    default: ossOut << *lType.cbegin();
             // Write the rest but one prefixed with the separator
             StdForEach(seq,
               next(lType.cbegin(), 1), next(lType.crbegin(), 1).base(),
                 [&ossOut, &strSep](const auto &strStr)
                   { ossOut << strSep << strStr; });
             // and now append the last separator and string from list
             ossOut << strLast << *lType.crbegin();
             // Done
             break;
  } // Return the compacted string
  return ossOut.str();
}
/* -- Convert string to lower case ----------------------------------------- */
static const string StrToLowCase[[maybe_unused]](const string &strSrc)
{ // Create memory for destination string and copy the string over
  string strDst; strDst.resize(strSrc.length());
  for(size_t stI = 0; stI < strSrc.size(); ++stI)
    strDst[stI] = static_cast<char>(tolower(static_cast<int>(strSrc[stI])));
  // Return copied string
  return strDst;
}
/* -- Convert string to upper case ----------------------------------------- */
static const string StrToUpCase[[maybe_unused]](const string &strSrc)
{ // Create memory for destination string and copy the string over
  string strDst; strDst.resize(strSrc.length());
  for(size_t stI = 0; stI < strSrc.size(); ++stI)
    strDst[stI] = static_cast<char>(toupper(static_cast<int>(strSrc[stI])));
  // Return copied string
  return strDst;
}
/* -- Compact a string removing leading, trailing and duplicate spaces ----- */
static string &StrCompactRef(string &strStr, const char cToken=' ')
{ // Enumerate every whitespace character until end-of-string
  for(auto itC{ strStr.begin() }; itC != strStr.end(); )
  { // Not a whitespace?
    if(*itC != cToken)
    { // Skip non-whitespace characters until end of string
      while(++itC != strStr.end())
        // If is a whitespace go forward again and go back to for loop
        if(*itC == cToken) { ++itC; break; }
    } // Erase whitespace
    else itC = strStr.erase(itC);
  } // Remove trailing whitespace if there is one
  if(!strStr.empty() && strStr.back() == cToken) strStr.pop_back();
  // Return string
  return strStr;
}
/* -- Compact a c-string removing duplicate spaces ------------------------- */
static const string StrCompact(const char*cpStr)
{ // Ignore if empty
  if(UtfIsCStringNotValid(cpStr)) return {};
  // Convert to string, compact it and return it
  string strOut{ cpStr };
  StrCompactRef(strOut);
  return strOut;
}
/* ------------------------------------------------------------------------- */
}                                      // End of public module namespace
/* ------------------------------------------------------------------------- */
}                                      // End of private module namespace
/* == EoF =========================================================== EoF == */

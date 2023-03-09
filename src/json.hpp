/* == JSON.HPP ============================================================= **
** ######################################################################### **
** ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## **
** ######################################################################### **
** ## This module defines a class that allows JSON encoding or decoding   ## **
** ## to performed.                                                       ## **
** ######################################################################### **
** ========================================================================= */
#pragma once                           // Only one incursion allowed
/* ------------------------------------------------------------------------- */
namespace IJson {                      // Start of private module namespace
/* -- Dependencies --------------------------------------------------------- */
using namespace IAsset::P;             using namespace IASync::P;
using namespace ICollector::P;         using namespace IError::P;
using namespace IEvtMain::P;           using namespace IFileMap::P;
using namespace IFStream::P;           using namespace IIdent::P;
using namespace ILuaLib::P;            using namespace ILuaUtil::P;
using namespace IMemory::P;            using namespace IStd::P;
using namespace ISysUtil::P;           using namespace IUtil::P;
using namespace Lib::RapidJson;
/* ------------------------------------------------------------------------- */
using Lib::RapidJson::Value;
/* ------------------------------------------------------------------------- */
namespace P {                          // Start of public module namespace
/* == Json object collector and member class =============================== */
CTOR_BEGIN_ASYNC_DUO(Jsons, Json, CLHelperUnsafe, ICHelperUnsafe),
  /* -- Base classes ------------------------------------------------------- */
  public Ident,                        // Json code file name
  public AsyncLoaderJson,              // Asynchronous loading of Json object
  public Lockable,                     // Lua garbage collector instruction
  private Document                     // RapidJson document class
{ /* -- Build a json string from lua string ----------------------- */ private:
  Value ToStr(lua_State*const lS, const int iId)
  { // Get string and length from LUA
    size_t stStr; const char*const cpStr = LuaUtilToLString(lS, iId, stStr);
    // Return as a json string. Unfortunately, ALL strings from LUA are
    // volatile so we need to copy the string.
    return { cpStr, static_cast<SizeType>(stStr), GetAllocator() };
  }
  /* -- Handle type value -------------------------------------------------- */
  template<typename Value>
    static void ProcessValueType(lua_State*const lS, const Value &vValue)
  { // What type is the value?
    switch(vValue.GetType())
    { // Json entry is a number type?
      case kNumberType:
        // Actually an integer or a number type?
        if(vValue.IsInt()) LuaUtilPushInt(lS, vValue.GetInt());
        else LuaUtilPushNum(lS, vValue.GetDouble());
        break;
      // Json entry is a string type?
      case kStringType:
        LuaUtilPushLStr(lS, vValue.GetString(), vValue.GetStringLength());
        break;
      // Json entry is a boolean type?
      case kTrueType:
        LuaUtilPushBool(lS, true);
        break;
      case kFalseType:
        LuaUtilPushBool(lS, false);
        break;
      // Json entry is an array[] type?
      case kArrayType:
        ToTableArray(lS, vValue);
        break;
      // Json entry is an object{} type?
      case kObjectType:
        ToTableObject(lS, vValue);
        break;
      // Json entry is a null type?
      case kNullType: [[fallthrough]];
      // Unknown type?
      default:
        LuaUtilPushNil(lS);
        break;
    }
  }
  /* -- Convert LUA table to rapidjson::Value ---------------------- */ public:
  Value ParseTable(lua_State*const lS, const int iId, const int iObjId)
  { // Check table
    LuaUtilCheckTable(lS, iId);
    // Test: lexec Console.Write(Json.Table({ }):StrFromNum());
    // Get size of table and if we have length then we need to create an array
    if(const lua_Integer liLen =
      UtilIntOrMax<lua_Integer>(LuaUtilGetSize(lS, iId)))
    {  // Set this value is array
      Value rjvRoot{ kArrayType };
      // We need one more free item on the stack, leave empty if not
      if(!LuaUtilIsStackAvail(lS, UtilIntOrMax<int>(liLen))) return rjvRoot;
      // Until end of table
      for(lua_Integer lI = 1; lI <= liLen; ++lI)
      { // Get first item
        LuaUtilGetRefEx(lS, iId, lI);
        // Append value if a string. Lua will convert any valid numbered
        // string to a number if this is not checked before integral checks.
        // Test with: lexec Console.Write(Json.Table({1,2,'3'}):ToHRString());
        switch(lua_type(lS, -1))
        { // Variable is a number
          case LUA_TNUMBER:
            if(LuaUtilIsInteger(lS, -1))
              rjvRoot.PushBack(Value().
                SetInt64(LuaUtilToInt(lS, -1)), GetAllocator());
            else rjvRoot.PushBack(LuaUtilToNum(lS, -1), GetAllocator());
            break;
          // Variable is a boolean
          case LUA_TBOOLEAN: rjvRoot.PushBack(LuaUtilToBool(lS, -1),
            GetAllocator()); break;
          // Variable is a table
          case LUA_TTABLE: rjvRoot.PushBack(ParseTable(lS, -1, -2),
            GetAllocator()); break;
          // Unknown or a string, just add a string
          case LUA_TSTRING:
          default: rjvRoot.PushBack(ToStr(lS, -1), GetAllocator()); break;
        } // Remove the last item
        LuaUtilRmStack(lS);
      } // Return new object
      return rjvRoot;
    } // Set this value as object
    Value rjvRoot{ kObjectType };
    // Save stack position so it can be restored on completion or exception
    const LuaStackSaver lSS{ lS };
    // We need two more free item on the stack, leave empty if not
    if(!LuaUtilIsStackAvail(lS, 2)) return rjvRoot;
    // Push nil value
    // Walk through all the object members
    for(LuaUtilPushNil(lS); lua_next(lS, iObjId); LuaUtilRmStack(lS))
    { // Get keyname
      Value vKey{ ToStr(lS, -2) };
      // Set the key->value for the LUA variable
      switch(lua_type(lS, -1))
      { // Variable is a number
        case LUA_TNUMBER:
          if(LuaUtilIsInteger(lS, -1))
            rjvRoot.AddMember(vKey,
              Value().SetInt64(LuaUtilToInt(lS, -1)),
              GetAllocator());
          else
            rjvRoot.AddMember(vKey, LuaUtilToNum(lS, -1), GetAllocator());
          break;
        // Variable is a boolean
        case LUA_TBOOLEAN:
          rjvRoot.AddMember(vKey, LuaUtilToBool(lS, -1), GetAllocator());
          break;
        // Variable is a table
        case LUA_TTABLE: rjvRoot.AddMember(vKey,
          ParseTable(lS, -1, -2), GetAllocator()); break;
        // Unknown or a string, just add as string
        case LUA_TSTRING:
        default: rjvRoot.AddMember(vKey, ToStr(lS, -1), GetAllocator());
          break;
      }
    } // Return new object
    return rjvRoot;
  }
  /* -- Convert json value to lua object table and put it on stack --------- */
  static void ToTableObject(lua_State*const lS, const Value &rjvVal)
  { // Create the table, we're creating non-indexed key/value pairs
    LuaUtilPushTable(lS, 0, rjvVal.MemberCount());
    // We need two more free item on the stack, leave empty if not
    if(!LuaUtilIsStackAvail(lS, 2)) return;
    // For each table item
    for(const auto &rjvRef : rjvVal.GetObject())
    { // What type is the value?
      ProcessValueType(lS, rjvRef.value);
      // Push key name
      LuaUtilSetField(lS, -2, rjvRef.name.GetString());
    }
  }
  /* -- Convert json value to lua array table and put it on stack ---------- */
  static void ToTableArray(lua_State*const lS, const Value &rjvVal)
  { // Create the table, we're creating a indexed/value array
    LuaUtilPushTable(lS, rjvVal.Size());
    // We need two more free items on the stack, leave empty if not
    if(rjvVal.Empty() || !LuaUtilIsStackAvail(lS, 2)) return;
    // Index id
    lua_Integer liId = 0;
    // For each table item
    for(const auto &rjvRef : rjvVal.GetArray())
    { // Table index
      LuaUtilPushInt(lS, ++liId);
      // What type is the value?
      ProcessValueType(lS, rjvRef);
      // Push key pair as integer table
      LuaUtilSetRaw(lS, -3);
    }
  }
  /* -- Convert json value to lua table and put it on stack ---------------- */
  void ToLuaTable(lua_State*const lS)
  { // Get value
    const Value &rjvVal =
      reinterpret_cast<const Value&>(static_cast<const Document&>(*this));
     // What type is the value?
    switch(rjvVal.GetType())
    { // Indexed array
      case kArrayType: ToTableArray(lS, rjvVal); break;
      // Key/value object
      case kObjectType: ToTableObject(lS, rjvVal); break;
      // Unacceptable
      default: XC("Json value not array or object!",
        "Type", rjvVal.GetType());
    }
  }
  /* ----------------------------------------------------------------------- */
  typedef Writer<StringBuffer, UTF8<>, UTF8<>> RJCompactWriter;
  typedef PrettyWriter<StringBuffer, UTF8<>, UTF8<>> RJPrettyWriter;
  /* ----------------------------------------------------------------------- */
  template<typename WriterType>const string StrFromNum(void) const
  { // Output buffer
    StringBuffer rsbOut;
    WriterType rwWriter{ rsbOut };
    Accept(rwWriter);
    return { rsbOut.GetString(), rsbOut.GetSize() };
  }
  /* ----------------------------------------------------------------------- */
  template<typename T>int ToFile(const string &strFile) const
    { return FStream{ strFile, FM_W_T }.
        FStreamWriteStringSafe(StrFromNum<T>()) ? 0 : StdGetError(); }
  /* ----------------------------------------------------------------------- */
  void AsyncReady(FileMap &fmData)
  { // Parse the string and return if succeeded
    const ParseResult prData{
      Parse<0>(fmData.MemPtr<char>(), fmData.MemSize()) };
    if(!prData) XC(GetParseError_En(prData.Code()),
      "Identifier", fmData.IdentGet(), "Size", fmData.MemSize(),
      "JsonSize",   prData.Offset());
  }
  /* -- Load json from file asynchronously --------------------------------- */
  void InitAsyncFile(lua_State*const lS)
  { // Must have 4 parameters (including the class pointer)
    LuaUtilCheckParams(lS, 5);
    // Check and get parameters
    const string strName{ LuaUtilGetCppFile(lS, 1) };
    LuaUtilCheckFunc(lS, 2, 3, 4);
    // Init the specified string as a file asynchronously
    AsyncInitFile(lS, strName, "jsonfile");
  }
  /* -- Load json from string asynchronously ------------------------------- */
  void InitAsyncString(lua_State*const lS)
  { // Must have 5 parameters (including the class pointer)
    LuaUtilCheckParams(lS, 6);
    // Check and get parameters
    const string strN{ LuaUtilGetCppStrNE(lS, 1) };
    Memory mData{ LuaUtilGetMBfromLStr(lS, 2) };
    LuaUtilCheckFunc(lS, 3, 4, 5);
    // Init the specified string as an array asynchronously
    AsyncInitArray(lS, strN, "jsonstring", mData);
  }
  /* -- Init from LUA string ----------------------------------------------- */
  void InitString(lua_State*const lS)
  { // Need three parameters...
    //   1: identifier
    //   2: string to convert
    //   3: the userdata object that contains a pointer to this class
    LuaUtilCheckParams(lS, 3);
    // Get name and code to parse
    IdentSet(LuaUtilGetCppStr(lS, 1));
    // Init file as array
    Memory mbData{ LuaUtilGetMBfromLStr(lS, 2) };
    SyncInitArray(IdentGet(), mbData);
  }
  /* -- Parse the table into a value --------------------------------------- */
  void InitFromTable(lua_State*const lS) { ParseTable(lS, 1, 1).Swap(*this); }
  /* ----------------------------------------------------------------------- */
  ~Json(void) { AsyncCancel(); }
  /* ----------------------------------------------------------------------- */
  Json(void) :
    /* -- Initialisers ----------------------------------------------------- */
    ICHelperJson{ cJsons },            // Initialise collector
    IdentCSlave{ cParent->CtrNext() }, // Initialise identification number
    AsyncLoaderJson{ *this, this,      // Initialise async loader with this
      EMC_MP_JSON }                    // ...and the event id
    /* -- No code ---------------------------------------------------------- */
    { }
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(Json)                // Suppress default functions for safety
};/* -- End ---------------------------------------------------------------- */
CTOR_END_ASYNC_NOFUNCS(Jsons, Json, JSON, JSON) // Finish collector class
/* ------------------------------------------------------------------------- */
}                                      // End of public module namespace
/* ------------------------------------------------------------------------- */
}                                      // End of private module namespace
/* == EoF =========================================================== EoF == */

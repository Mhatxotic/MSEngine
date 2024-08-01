/* == LUADEF.HPP =========================================================== **
** ######################################################################### **
** ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## **
** ######################################################################### **
** ## Some definitions specific to Lua.                                   ## **
** ######################################################################### **
** ========================================================================= */
#pragma once                           // Only one incursion allowed
/* == LuaDef interface namespace =========================================== */
namespace ILuaDef {                    // Start of module namespace
/* == Typedefs ============================================================= */
struct LuaKeyInt                       // Lua key/value pairs C
{ /* ----------------------------------------------------------------------- */
  const char*const  cpName;            // Name of const table
  const lua_Integer liValue;           // Integer value for this const
};/* ----------------------------------------------------------------------- */
struct LuaTable                        // Lua table as C
{ /* ----------------------------------------------------------------------- */
  const char*const      cpName;        // Name of const table
  const LuaKeyInt*const kiList;        // Key value list
  const int             iCount;        // Number of items in this list
};/* ----------------------------------------------------------------------- */
};                                     // End of module namespace
/* == LibLua interface namespace =========================================== */
namespace ILuaLib {                    // Start of private module namespace
/* ------------------------------------------------------------------------- */
using namespace ICVarDef::P;           using namespace ILuaDef;
/* ------------------------------------------------------------------------- */
namespace P {                          // Start of public module namespace
/* -- Lua API class namespace ids ------------------------------------------ */
enum LuaClassId : size_t {
  /* ----------------------------------------------------------------------- */
  LMT_ARCHIVE,  LMT_ASSET,    LMT_BIN,     LMT_CLIP,   LMT_COMMAND,    // 00-04
  LMT_FBO,      LMT_FILE,     LMT_FONT,    LMT_FTF,    LMT_IMAGE,      // 05-09
  LMT_IMAGELIB, LMT_JSON,     LMT_LUAFUNC, LMT_MASK,   LMT_PALETTE,    // 10-14
  LMT_PCM,      LMT_PCMLIB,   LMT_SAMPLE,  LMT_SHADER, LMT_SSHOT,      // 15-19
  LMT_STAT,     LMT_SOCKET,   LMT_SOURCE,  LMT_STREAM, LMT_THREAD,     // 20-24
  LMT_TEXTURE,  LMT_VARIABLE, LMT_VIDEO,                               // 25-27
  /* ----------------------------------------------------------------------- */
  LMT_CLASSES,                         // Maximum number of classes
  /* ----------------------------------------------------------------------- */
  LMT_TOTAL = LMT_CLASSES + 1,         // Absolute total namespaces [31]
};/* -- LUA class reference ids (referenced in collect.hpp) ---------------- */
typedef array<int, LMT_CLASSES> LuaLibClassIdReferences;
static LuaLibClassIdReferences llcirAPI;
/* -- Information about a LUA API namespace -------------------------------- */
struct LuaLibStatic
{ /* ----------------------------------------------------------------------- */
  const LuaClassId     lciId;          // Unique class id (see above)
  const string_view   &strvName;       // Name of library
  const CoreFlagsConst cfcRequired;    // Required core flags to register
  const luaL_Reg*const libList;        // Library functions
  const int            iLLCount;       // Size of library functions
  const luaL_Reg*const libmfList;      // Member library functions
  const int            iLLMFCount;     // Size of member library functions
  const lua_CFunction  lcfpDestroy;    // Destruction function
  const LuaTable*const lkiList;        // Table of key/values to define
  const int            iLLKICount;     // Size of member library functions
};/* -- Lua API namespace descriptor list (ref'd in collect, lua, lualib) -- */
typedef array<const LuaLibStatic, LMT_TOTAL> LuaLibStaticArray;
extern const LuaLibStaticArray llsaAPI;
/* ------------------------------------------------------------------------- */
}                                      // End of public module namespace
/* ------------------------------------------------------------------------- */
}                                      // End of private module namespace
/* == EoF =========================================================== EoF == */

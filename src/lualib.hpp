/* == LUALIB.HPP =========================================================== **
** ######################################################################### **
** ## Mhatxotic Engine          (c) Mhatxotic Design, All Rights Reserved ## **
** ######################################################################### **
** ## This file defines the complete LUA API that interfaces with the     ## **
** ## game engine. The guest will be able to use this functions when      ## **
** ## writing scripts for their software.                                 ## **
** ##                                                                     ## **
** ## To define a function, begin with use of the llfuncbegin/end macros  ## **
** ## to use multiple lines of code and llfunc(ex) to define a function   ## **
** ## in a single line. The 'ex' signifies returning number of params.    ## **
** ######################################################################### **
** ------------------------------------------------------------------------- */
#pragma once                           // Only one incursion allowed
/* ------------------------------------------------------------------------- */
namespace ILuaLib {                    // Start of private module namespace
/* -- Dependencies --------------------------------------------------------- */
using namespace ICVarDef::P;           using namespace ILuaUtil::P;
/* ------------------------------------------------------------------------- */
namespace P {                          // Start of public module namespace
/* -- Macros to simplify creating lualib functions ------------------------- */
#define LLFUNCBEGIN(n)         static int Cb ## n(lua_State*const lS) {
#define LLFUNCBEGINTMPL(n)     template<typename IntType>LLFUNCBEGIN(n)
#define LLFUNCEND              LLFUNCENDEX(0)
#define LLFUNCENDEX(x)         (void)(lS); return x; }
#define LLFUNCTMPL(n,x,...)    LLFUNCBEGINTMPL(n) __VA_ARGS__; LLFUNCENDEX(x)
#define LLFUNC(n,x,...)        LLFUNCBEGIN(n) __VA_ARGS__; LLFUNCENDEX(x)
/* -- Macros to simplify definition of lualib reg func structures ---------- */
#define LLRSBEGIN              static const luaL_Reg llrStatics[]{
#define LLRSCONST(n)           { #n, lkiConsts ## n, ArrayLen(lkiConsts ## n) }
#define LLRSCONSTBEGIN         static const LuaTable ltConsts[]{
#define LLRSCONSTEND           { nullptr, nullptr, 0 } };
#define LLRSEND                { nullptr, nullptr } };
#define LLRSFUNC(n)            { #n, Cb ## n }
#define LLRSFUNCEX(n,f)        { #n, Cb ## f }
#define LLRSKTBEGIN(n)         static const LuaKeyInt lkiConsts ## n[]{
#define LLRSKTEND              { nullptr, 0 } };
#define LLRSKTITEM(p,n)        LLRSKTITEMEX2(#n, p ## n)
#define LLRSKTITEMEX(p,n,u)    LLRSKTITEMEX2(#n, p ## n ## u)
#define LLRSKTITEMEX2(k,v)     { k, static_cast<lua_Integer>(v) }
#define LLRSMFBEGIN            static const luaL_Reg llrMethods[]{
/* -- Get length of an array ignoring the final NULL entry ----------------- */
template<typename IntType=int, typename AnyType, IntType itSize>
  constexpr int ArrayLen(AnyType (&)[itSize]) { return itSize - 1; };
/* -- Dependencies --------------------------------------------------------- */
#include "llcommon.hpp"                // Common helper classes (always first)
/* -- API includes --------------------------------------------------------- */
#include "llarchive.hpp"               // Archive namespace and methods
#include "llasset.hpp"                 // Asset namespace and methods
#include "llaudio.hpp"                 // Audio namespace and methods
#include "llbin.hpp"                   // Bin namespace and methods
#include "llclip.hpp"                  // Clipboard namespace and methods
#include "llcmd.hpp"                   // Command namespace and methods
#include "llcore.hpp"                  // Core namespace and methods
#include "lldisplay.hpp"               // Display namespace and methods
#include "llfbo.hpp"                   // Fbo namespace and methods
#include "llfile.hpp"                  // File namespace and methods
#include "llfont.hpp"                  // Font namespace and methods
#include "llftf.hpp"                   // Ftf namespace and methods
#include "llimage.hpp"                 // Image namespace and methods
#include "llinput.hpp"                 // Input namespace and methods
#include "lljson.hpp"                  // Json namespace and methods
#include "llmask.hpp"                  // Mask namespace and methods
#include "llpcm.hpp"                   // Pcm namespace and methods
#include "llsource.hpp"                // Source namespace and methods
#include "llsample.hpp"                // Sample namespace and methods
#include "llsocket.hpp"                // Socket namespace and methods
#include "llsql.hpp"                   // Sql namespace and methods
#include "llsshot.hpp"                 // SShot namespace and methods
#include "llstat.hpp"                  // Stat namespace and methods
#include "llstream.hpp"                // Stream namespace and methods
#include "lltexture.hpp"               // Texture namespace and methods
#include "llpalette.hpp"               // Palette namespace and methods
#include "llutil.hpp"                  // Util namespace and methods
#include "llvar.hpp"                   // Variable namespace and methods
#include "llvideo.hpp"                 // Video namespace and methods
/* -- Done with these macros ----------------------------------------------- */
#undef LLRSMFBEGIN
#undef LLRSKTITEMEX2
#undef LLRSKTITEMEX
#undef LLRSKTITEM
#undef LLRSKTEND
#undef LLRSKTBEGIN
#undef LLRSFUNCEX
#undef LLRSFUNC
#undef LLRSEND
#undef LLRSCONSTEND
#undef LLRSCONSTBEGIN
#undef LLRSCONST
#undef LLRSBEGIN
#undef LLFUNCTMPL
#undef LLFUNCENDEX
#undef LLFUNCEND
#undef LLFUNCBEGINTMPL
#undef LLFUNCBEGIN
#undef LLFUNC
/* ========================================================================= **
** ######################################################################### **
** ## LUA GLOBAL CLASS STRUCTURE                                          ## **
** ######################################################################### **
** -- Key ------------------------------------------------------------------ **
** v (variable) = The fully qualified name of the array to use.              **
** n (name)     = The name of the namespace.                                 **
** t (type)     = The variable type (Statics, Methods or Consts).            **
** l (level)    = The required core flags. See cvardef.hpp->CoreFlags.       **
** m (methods)  = Method function list. LLMETHODS(name) or LLNOMETHODS.      **
** c (consts)   = Const key/value list. LLCONSTS(name) or LLNOCONSTS.        **
** -- Helps build the pointer to the list and the length of the list ------- */
#define LLPTRLENEX(v)   v, ArrayLen(v)
#define LLPTRLEN(n,t)   LLPTRLENEX(LL ## n::l ## t)
/* -- Helps define the list of static, methods and consts ------------------ */
#define LLSTATICS(n)    LLPTRLEN(n, lrStatics)
#define LLMETHODS(n)    LLPTRLEN(n, lrMethods), \
  static_cast<lua_CFunction>(LL ## n::CbDestroy)
#define LLNOMETHODS()   nullptr, 0, nullptr
#define LLCONSTS(n)     LLPTRLEN(n, tConsts)
#define LLNOCONSTS()    nullptr, 0
#define LLITEM(t,n,l,m,c) { LMT_ ## t, #n, CFL_ ## l, LLSTATICS(n), m, c }
#define LLSXX(n,l)      LLITEM(CLASSES, n, l, LLNOMETHODS(), LLNOCONSTS())
#define LLSMX(n,l,t)    LLITEM(t, n, l, LLMETHODS(n), LLNOCONSTS())
#define LLSXC(n,l)      LLITEM(CLASSES, n, l, LLNOMETHODS(), LLCONSTS(n))
#define LLSMC(n,l,t)    LLITEM(t, n, l, LLMETHODS(n), LLCONSTS(n))
/* -- Define the engine api list loaded at startup ------------------------- */
const LuaLibStaticArray llsaAPI{
{ /* -- Use the above macros to define namespaces -------------------------- **
  ** WARNING: Make sure to update 'LuaLibStaticArray' count in luadef.hpp if **
  ** the total number of elements in this list changes.                      **
  ** ----------------------------------------------------------------------- */
  LLSMX(Archive, NONE, ARCHIVE),       LLSMC(Asset, NONE, ASSET),
  LLSXX(Audio, AUDIO),                 LLSMX(Bin, NONE, BIN),
  LLSMX(Clip, VIDEO, CLIP),            LLSXC(Core, NONE),
  LLSMX(Command, NONE, COMMAND),       LLSXC(Display, VIDEO),
  LLSMC(Fbo, VIDEO, FBO),              LLSMC(File, NONE, FILE),
  LLSMC(Font, VIDEO, FONT),            LLSMX(Ftf, NONE, FTF),
  LLSMC(Image, NONE, IMAGE),           LLSXC(Input, VIDEO),
  LLSMX(Json, NONE, JSON),             LLSMX(Mask, NONE, MASK),
  LLSMX(Palette, VIDEO, PALETTE),      LLSMC(Pcm, NONE, PCM),
  LLSMX(Sample, AUDIO, SAMPLE),        LLSMX(SShot, VIDEO, SSHOT),
  LLSMX(Stat, NONE, STAT),             LLSMC(Socket, NONE, SOCKET),
  LLSMX(Source, AUDIO, SOURCE),        LLSXC(Sql, NONE),
  LLSMC(Stream, AUDIO, STREAM),        LLSMX(Texture, VIDEO, TEXTURE),
  LLSXX(Util, NONE),                   LLSMC(Variable, NONE, VARIABLE),
  LLSMC(Video, AUDIOVIDEO, VIDEO),
}};/* -- Done with these macros -------------------------------------------- */
#undef LLSMC
#undef LLSXC
#undef LLSMX
#undef LLSXX
#undef LLITEM
#undef LLNOMETHODS
#undef LLNOCONSTS
#undef LLCONSTS
#undef LLMETHODS
#undef LLSTATICS
#undef LLPTRLEN
#undef LLPTRLENEX
/* ------------------------------------------------------------------------- */
}                                      // End of public module namespace
/* ------------------------------------------------------------------------- */
}                                      // End of private module namespace
/* == EoF =========================================================== EoF == */

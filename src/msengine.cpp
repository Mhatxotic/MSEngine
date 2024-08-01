/* == MSENGINE.CPP ========================================================= */
/* ######################################################################### */
/* ##*@@****@@**@@@@@@*******@@@@@**@@@@@@***@@@@@*@@@@@@*@@@@@@***@@@@@**## */
/* ##*@@@@@@@@*@@*******@@**@@***@@*@@***@@*@@*******@@***@@***@@*@@***@@*## */
/* ##*@@*@@*@@**@@@@@**@@@@*@@@@****@@***@@*@@*@@@***@@***@@***@@*@@@@****## */
/* ##*@@****@@******@@**@@**@@***@@*@@***@@*@@***@@**@@***@@***@@*@@***@@*## */
/* ##*@@****@@*@@@@@@********@@@@@**@@***@@**@@@@@*@@@@@@*@@***@@**@@@@@**## */
/* ######################################################################### */
/* ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## */
/* ######################################################################### */
/* ## This the file that handles the inclusing of engine subsystems in a  ## */
/* ## tidy namespace and handles the main entry point.                    ## */
/* ######################################################################### */
/* ========================================================================= */
#include "setup.hpp"                   // Setup the compilation environment
/* ------------------------------------------------------------------------- */
namespace E {                          // Start of engine namespace
/* ------------------------------------------------------------------------- */
#include "msengine.hpp"                // Engine version information header
#include "stdtypes.hpp"                // Engine STL types used header
#include "flags.hpp"                   // Flags helper utility header
#include "utf.hpp"                     // UTF strings utility header
#include "std.hpp"                     // StdLib function helpers header
#include "string.hpp"                  // String utilities header
#include "url.hpp"                     // Url parsing library
#include "error.hpp"                   // Error handling utility header
#include "token.hpp"                   // String tokenisation utility header
#include "parser.hpp"                  // String parsing utility header
#include "psplit.hpp"                  // Path handling utilities header
#include "ident.hpp"                   // Identifier utility header
#include "dir.hpp"                     // Directory handling utility header
#include "util.hpp"                    // Miscellenious utilities header
#include "sysutil.hpp"                 // System utilities header
#include "cvardef.hpp"                 // CVar definitions header
#include "clock.hpp"                   // Clock utilities header
#include "timer.hpp"                   // Timing utilities header
#include "args.hpp"                    // Arguments handling header
#include "cmdline.hpp"                 // Command-line class header
#include "memory.hpp"                  // Memory management utilities header
#include "fstream.hpp"                 // File IO utility header
#include "log.hpp"                     // Logging helper class header
#include "collect.hpp"                 // Class collector utility header
#include "stat.hpp"                    // Statistic utility class header
#include "thread.hpp"                  // Thread helper class header
#include "evtcore.hpp"                 // Thread-safe event system core header
#include "evtmain.hpp"                 // Main engine events system header
#include "glfwutil.hpp"                // GLFW utility class header
#include "evtwin.hpp"                  // Window thread events system header
#include "glfwcrsr.hpp"                // GLFW cursor class header
#include "glfwwin.hpp"                 // GLFW window class header
#include "glfw.hpp"                    // GLFW utilities header
#include "dim.hpp"                     // Data grouping classes header
#include "glfwmon.hpp"                 // GLFW monitor class header
#include "condef.hpp"                  // Console definitions header
#include "syscore.hpp"                 // Operating system interface header
#include "filemap.hpp"                 // Virtual file IO interface
#include "luadef.hpp"                  // Lua definitions header
#include "luautil.hpp"                 // Lua utility functions header
#include "luaref.hpp"                  // Lua reference helper class header
#include "luaevent.hpp"                // Lua event helper class header
#include "luafunc.hpp"                 // Lua callback helper class header
#include "async.hpp"                   // Async file loading class header
#include "crypt.hpp"                   // Cryptography utilities header
#include "uuid.hpp"                    // UuId parsing header
#include "codec.hpp"                   // Codec classes header
#include "credits.hpp"                 // Credits handling class header
#include "archive.hpp"                 // Archive handling class header
#include "asset.hpp"                   // Asset handling class header
#include "sql.hpp"                     // SQL database management header
#include "cert.hpp"                    // X509 certificate store class header
#include "cvar.hpp"                    // CVar item header
#include "luacode.hpp"                 // Lua code subsystem header
#include "cvars.hpp"                   // CVars management class header
#include "lua.hpp"                     // Lua core subsystem header
#include "socket.hpp"                  // Socket handling class header
#include "console.hpp"                 // Console handling header
#include "oal.hpp"                     // OpenAL audio header
#include "pcmdef.hpp"                  // Pcm definitions header
#include "pcmlib.hpp"                  // Pcm codecs handling header
#include "pcmfmt.hpp"                  // Pcm format support plugins header
#include "pcm.hpp"                     // Pcm loader class header
#include "fbodef.hpp"                  // Frambuffer object definitions header
#include "texdef.hpp"                  // Texture data definitions header
#include "ogl.hpp"                     // OpenGL graphics management header
#include "imagedef.hpp"                // Image data definitions header
#include "imagelib.hpp"                // Image codecs handling header
#include "imagefmt.hpp"                // Image format support plugins header
#include "bin.hpp"                     // Bin packing class header
#include "image.hpp"                   // Image load and save handling header
#include "shader.hpp"                  // OpenGL Shader handling header
#include "shaders.hpp"                 // Actual shaders core
#include "fboitem.hpp"                 // Frame buffer object item class header
#include "fbo.hpp"                     // Frame buffer object class header
#include "fbocore.hpp"                 // Core frame buffer object class header
#include "sshot.hpp"                   // Screenshot handling class header
#include "texture.hpp"                 // Texture handling class header
#include "palette.hpp"                 // Palette handling class header
#include "ft.hpp"                      // Freetype base class
#include "ftf.hpp"                     // Freetype font handling class header
#include "font.hpp"                    // Font loading and printing header
#include "file.hpp"                    // FStream+FileMap class header
#include "clip.hpp"                    // Clipboard class header
#include "congraph.hpp"                // Console rendering class header
#include "input.hpp"                   // Input handling class header
#include "display.hpp"                 // Window handling class header
#include "mask.hpp"                    // BitMask system header
#include "source.hpp"                  // Audio source class header
#include "stream.hpp"                  // Audio stream class header
#include "sample.hpp"                  // Audio sample class header
#include "video.hpp"                   // Theora video playback class header
#include "audio.hpp"                   // Audio base management class header
#include "json.hpp"                    // Json handling class header
#include "luavar.hpp"                  // Lua variable class
#include "luacmd.hpp"                  // Lua console command class
#include "core.hpp"                    // Core class header
#include "lualib.hpp"                  // Lua lua function api library
/* ------------------------------------------------------------------------- */
};                                     // End of engine namespace
/* == The main entry point ================================================= */
int ENTRYFUNC                          // Macro defined in 'setup.hpp'
{ // Create and run the engine and return its exit result
  return E::ICore::P::Core{}.CoreMain(__argc, __wargv, _wenviron);
}
/* == End-of-File ========================================================== */

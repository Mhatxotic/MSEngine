/* == FONT.HPP ============================================================= **
** ######################################################################### **
** ## Mhatxotic Engine          (c) Mhatxotic Design, All Rights Reserved ## **
** ######################################################################### **
** ## This module allows loading and drawing of beautifully rendered      ## **
** ## fonts using the FreeType library. There is a lot of code in this    ## **
** ## class so it is split apart into different font*.hpp files and will  ## **
** ## be included inline and the rest of the code in this file is related ## **
** ## to initialisation of the actual font and public metadata retrieval. ## **
** ######################################################################### **
** ========================================================================= */
#pragma once                           // Only one incursion allowed
/* ------------------------------------------------------------------------- */
namespace IFont {                      // Start of private namespace
/* -- Dependencies --------------------------------------------------------- */
using namespace IAsset::P;             using namespace IBin::P;
using namespace ICollector::P;         using namespace IDim;
using namespace IError::P;             using namespace IFboDef::P;
using namespace IFileMap::P;           using namespace IFreeType::P;
using namespace IFtf::P;               using namespace IImageDef::P;
using namespace ILog::P;               using namespace ILuaLib::P;
using namespace IMemory::P;            using namespace IOgl::P;
using namespace IParser::P;            using namespace IPSplit::P;
using namespace IStd::P;               using namespace IString::P;
using namespace ISysUtil::P;           using namespace ITexDef::P;
using namespace ITexture::P;           using namespace IToken::P;
using namespace IUtf;                  using namespace IUtil::P;
using namespace Lib::FreeType;         using namespace Lib::OS::GlFW;
/* ------------------------------------------------------------------------- */
namespace P {                          // Start of public namespace
/* == Font collector class for collector data and custom variables ========= */
CTOR_BEGIN_NOBB(Fonts, Font, CLHelperUnsafe)
/* == Font Variables Class ================================================= */
// Only put vars used in the Font class in here. This is an optimisation so
// we do not have to initialise all these variables more than once as we have
// more than one constructor in the main Font class.
/* ------------------------------------------------------------------------- */
class FontBase :                       // Members initially private
  /* -- Base classes ------------------------------------------------------- */
  public Texture                       // Texture class
{ /* -- Protected typedefs -------------------------------------- */ protected:
  typedef Rectangle<GLfloat> RectFloat;// Rectangle of GLfloats
  /* ----------------------------------------------------------------------- */
  class Glyph :                        // Members initially private
    /* -- Dependencies ----------------------------------------------------- */
    public DimFloat,                   // Dimension of floats
    public RectFloat                   // Glyph bounding co-ordinates
  { /* --------------------------------------------------------------------- */
    bool           bLoaded;            // 0=ft unloaded or 1=ft loaded
    GLfloat        fAdvance;           // Width, height and advance of glyph
    /* -- Returns character advance -------------------------------- */ public:
    GLfloat GlyphGetAdvance(void) const { return fAdvance; }
    /* -- Sets character advance ------------------------------------------- */
    void GlyphSetAdvance(const GLfloat fNewAdv) { fAdvance = fNewAdv; }
    /* -- Returns if this glyph has been loaded ---------------------------- */
    bool GlyphIsLoaded(void) const { return bLoaded; }
    /* -- Set glyph as loaded ---------------------------------------------- */
    void GlyphSetLoaded(void) { bLoaded = true; }
    /* -- Constructor that initialises all members ------------------------- */
    Glyph(const GLfloat fWidth,        // Width of glyph in pixels for opengl
          const GLfloat fHeight,       // Height of glyph in pixels for opengl
          const bool    bNLoaded,      // Is the glyph loaded?
          const GLfloat fNAdvance,     // Specified glyph advance in pixels
          const GLfloat fX1,           // Top-left co-ordinate of glyph
          const GLfloat fY1,           // Bottom-left co-ordinate of glyph
          const GLfloat fX2,           // Top-right co-ordinate of glyph
          const GLfloat fY2) :         // Bottom-right co-ordinate of glyph
      /* -- Initialisers --------------------------------------------------- */
      DimFloat{ fWidth, fHeight },     // Initialise glpyh size
      RectFloat{ fX1, fY1, fX2, fY2 }, // Init adjustment co-ordinates
      bLoaded(bNLoaded),               // Init specified loaded value
      fAdvance(fNAdvance)              // Init specified advance value
      /* -- No code -------------------------------------------------------- */
      { }
    /* -- Default Constructor ---------------------------------------------- */
    Glyph(void) :                      // No arguments
      /* -- Initialisers --------------------------------------------------- */
      DimFloat{ },                     // Initialise default dimensions
      RectFloat{ },                    // Initialise default rectangle
      bLoaded(false),                  // Character not loaded yet
      fAdvance(0.0f)                   // Character advance value
      /* -- No code -------------------------------------------------------- */
      { }
  };/* -- Variables -------------------------------------------------------- */
  typedef vector<Glyph> GlyphVector;   // Vector of Glyphs
  typedef Pack<GLint> IntPack;         // Bin pack using GLint
  typedef IntPack::Rect IntPackRect;   // Bin pack rectangle
  typedef Rectangle<GLuint> RectUint;  // Reload glyph size
  /* --------------------------------------------------------------- */ public:
  GlyphVector      gvData;             // Glyph and outline data
  DimFloat         dfScale,            // Scaled font width and height
                   dfFont;             // Requested font size for OpenGL
  size_t           stMultiplier;       // 1 if no outline, 2 if outline
  GLfloat          fCharSpacing,       // Character spacing adjustment
                   fCharSpacingScale,  // Character spacing scaled size
                   fLineSpacing,       // Text line spacing
                   fLineSpacingHeight, // Height of line spacing plus height
                   fGSize,             // Scaled font texture glyph size
                   fScale,             // Font scale
                   fGPad, fGPadScaled; // Glyph position adjustment
  Texture         *tGlyphs;            // Texture for print calls only
  FboItem          fiOutline;          // Outline colour
  OglFilterEnum    ofeFilter;          // Selected texture filter
  GLuint           uiPadding;          // Padding after each glyph
  /* -- Freetype handles --------------------------------------------------- */
  IntPack          ipData;             // FT packed characters in image
  Ftf              ftfData;            // FT font data
  FT_ULong         ulDefaultChar;      // Default fallback character
  /* -- Reload texture parameters ------------------------------------------ */
  enum RTCmd { RT_NONE, RT_FULL, RT_PARTIAL } rtCmd; // Reload texture command
  RectUint         rRedraw;            // Reload cordinates and dimensions
  /* -- Default constructor ------------------------------------------------ */
  FontBase(void) :                     // No parameters
    /* --------------------------------------------------------------------- */
    Texture{ true },                   stMultiplier(1),
    fCharSpacing(0.0f),                fCharSpacingScale(0.0f),
    fLineSpacing(0.0f),                fLineSpacingHeight(0.0f),
    fGSize(0.0f),                      fScale(0.0f),
    fGPad(0.0f),                       fGPadScaled(0.0f),
    tGlyphs(nullptr),                  fiOutline{ 0xFF000000 },
    ofeFilter(OF_N_N),                 uiPadding(0),
    ulDefaultChar('?'),                rtCmd(RT_NONE),
    rRedraw{
      numeric_limits<GLuint>::max(),
      numeric_limits<GLuint>::max(),
      0, 0 }
    /* --------------------------------------------------------------------- */
    { }
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(FontBase)            // Suppress default functions for safety
};/* ----------------------------------------------------------------------- */
/* == Font Class (which inherits a Texture) ================================ */
CTOR_MEM_BEGIN(Fonts, Font, ICHelperUnsafe, /* n/a */),
  /* -- Base classes ------------------------------------------------------- */
  public FontBase                      // Font variables class
{  /* -- Convert co-ordinates to absolute position ------------------------- */
  static size_t CoordsToAbsolute(const size_t stPosX, const size_t stPosY,
    const size_t stWidth, const size_t stBytesPerColumn=1)
  { return ((stPosY * stWidth) + stPosX) * stBytesPerColumn; }
  /* -- Stroker functors for DoInitFTChar() -------------------------------- */
#include "fontglph.hpp"                // Include glyph loading members inline
#include "fontblit.hpp"                // Include glyph blitting members inline
  /* -- Check if texture reload required -------------------------- */ private:
  void CheckReloadTexture(void)
  { // Check reload command
    switch(rtCmd)
    { // No reload so just return
      case RT_NONE: return;
      // Full reload
      case RT_FULL:
      { // Reset reload command incase of error
        rtCmd = RT_NONE;
        // Full reload of texture
        ReloadTexture();
        // Log that we reuploaded the texture
        cLog->LogDebugExSafe("Font '$' full texture reload (S:$,$).",
          IdentGet(), DimGetWidth(), DimGetHeight());
        // Done
        return;
      } // Partial reload
      case RT_PARTIAL:
      { // Reset reload command incase of error
        rtCmd = RT_NONE;
        // Calculate position to read from in buffer
        const size_t stRTPos = CoordsToAbsolute(rRedraw.RectGetX1(),
          rRedraw.RectGetY1(), DimGetWidth(), 2);
        // Calculate position in buffer to read from
        const GLubyte*const ucpSrc =
          GetSlots().front().MemRead<GLubyte>(stRTPos, DimGetWidth());
        // Update partial texture
        UpdateEx(GetSubName(),
          rRedraw.RectGetX1<GLint>(), rRedraw.RectGetY1<GLint>(),
          static_cast<GLsizei>(rRedraw.RectGetX2() - rRedraw.RectGetX1()),
          static_cast<GLsizei>(rRedraw.RectGetY2() - rRedraw.RectGetY1()),
          GetPixelType(), ucpSrc, DimGetWidth<GLsizei>());
        // Log that we partially reuploaded the texture
        cLog->LogDebugExSafe("Font '$' partial re-upload (B:$,$,$,$;P:$).",
          IdentGet(), rRedraw.RectGetX1(), rRedraw.RectGetY1(),
          rRedraw.RectGetX2(), rRedraw.RectGetY2(), stRTPos);
        // Reset range parameters
        rRedraw.RectSetTopLeft(numeric_limits<GLuint>::max());
        rRedraw.RectSetBottomRight(0);
        // Done
        return;
      }
    }
  }
  /* -- Set glyph size --------------------------------------------- */ public:
  void SetGlyphSize(const GLfloat fSize)
    { fGSize = fSize; UpdateGlyphPaddingTimesScale(); }
  /* -- Get character count ------------------------------------------------ */
  size_t GetCharCount(void) const { return gvData.size() / stMultiplier; }
  /* -- Get character scale ------------------------------------------------ */
  GLfloat GetCharScale(void) const { return fScale; }
  /* -- Get bin occupancy -------------------------------------------------- */
  double GetTexOccupancy(void) const { return ipData.Occupancy(); }
  /* -- Get below baseline height of specified character ------------------- */
  GLfloat GetBaselineBelow(const unsigned int uiChar)
  { // Now get character info and return data
    const Glyph &gRef = gvData[CheckGlyph(uiChar)];
    return (gRef.RectGetY2() - gRef.DimGetHeight()) * fScale;
  }
  /* -- Set line spacing of the font --------------------------------------- */
  void SetLineSpacing(const GLfloat fNewLineSpacing)
  { // Set line spacing
    fLineSpacing = fNewLineSpacing;
    // Update line spacing plus height
    UpdateHeightPlusLineSpacing();
  }
  /* -- Set new glyph Y padding and the new scaling value ------------------ */
  void SetGlyphPadding(const GLfloat fNewGPad)
  { // Set new glyph padding
    fGPad = fNewGPad;
    // Update glyph padding times scale
    UpdateGlyphPaddingTimesScale();
  }
  /* -- Set character spacing of the font ---------------------------------- */
  void SetCharSpacing(const GLfloat fNewCharSpacing)
  { // Update character spacing value
    fCharSpacing = fNewCharSpacing;
    // Update new character spacing times scale value
    UpdateCharSpacingTimesScale();
  }
  /* -- Set size of the font ----------------------------------------------- */
  void SetSize(const GLfloat fNScale)
  { // Set scale
    fScale = UtilClamp(fNScale, 0.0f, 1024.0f);
    // Update scaled dimensions
    dfScale.DimSet(dfTile.DimGetWidth() * fScale,
                   dfTile.DimGetHeight() * fScale);
    // Update glyph size
    SetGlyphSize(dfScale.DimGetHeight());
    // Update frequently used values
    UpdateCharSpacingTimesScale();
    UpdateHeightPlusLineSpacing();
  }
  /* -- Do initialise specified freetype character range ------------------- */
  void InitFTCharRange(const size_t stStart, const size_t stEnd)
  { // Ignore if not a freetype font.
    if(!ftfData.IsLoaded()) return;
    // Log pre-cache progress
    cLog->LogDebugExSafe("Font '$' pre-caching character range $ to $...",
      IdentGet(), stStart, stEnd);
    // Load the specified character range
    DoInitFTCharRangeApplyStroker<HandleGlyphFunc::FreeType>(stStart, stEnd);
    // Check if any textures need reloading
    CheckReloadTexture();
    // Log success
    cLog->LogDebugExSafe(
      "Font '$' finished pre-caching character range $ to $.",
      IdentGet(), stStart, stEnd);
  }
  /* -- Do initialise all freetype characters in specified string ---------- */
  void InitFTCharString(const GLubyte*const ucpPtr)
  { // Ignore if string not valid or font not loaded
    if(UtfIsCStringNotValid(ucpPtr) || !ftfData.IsLoaded()) return;
    // Do load string characters
    DoInitFTCharStringApplyStroker<HandleGlyphFunc::FreeType>(ucpPtr);
    // Check if any textures need reloading
    CheckReloadTexture();
  }
  /* -- Do initialise freetype font ---------------------------------------- */
  void InitFTFont(Ftf &_ftfData, const GLuint uiISize, const GLuint _uiPadding,
    const OglFilterEnum _ofeFilter, const ImageFlagsConst &ffFlags)
  { // Make sure padding isn't negative. We use int because it is optimal for
    // use with the BinPack routines.
    if(UtilIntWillOverflow<int>(uiPadding))
      XC("Invalid padding size!",
         "Identifier", IdentGet(), "Requested",  _uiPadding);
    // Show that we're loading the file
    cLog->LogDebugExSafe("Font loading '$' (IS:$;P:$;F:$;FL:$$)...",
      _ftfData.IdentGet(), uiISize, _uiPadding, _ofeFilter, hex,
      ffFlags.FlagGet());
    // If source and destination ftf class are not the same?
    if(&ftfData != &_ftfData)
    { // Assign freetype font data
      ftfData.SwapFtf(_ftfData);
      // The ftf passed in the arguments is usually still allocated by LUA
      // and will still be registered, so lets put a note in the image to show
      // that this function has nicked this font class.
      _ftfData.IdentSetEx("!FON!$!", ftfData.IdentGet());
    }
    // Set initial font size. Since the font size is a float we should round
    // to next whole number so there is enough space.
    duiTile.DimSet(static_cast<unsigned int>(ceil(ftfData.DimGetWidth())),
                  static_cast<unsigned int>(ceil(ftfData.DimGetHeight())));
    // Update tile size as GLfloat for opengl
    dfTile.DimSet(duiTile.DimGetWidth<GLfloat>(),
                  duiTile.DimGetHeight<GLfloat>());
    // Initialise other data
    dfFont.DimSet(ftfData);
    uiPadding = _uiPadding;
    ofeFilter = _ofeFilter;
    FlagSet(ffFlags);
    // Image now being used in a Font class
    ClearPurposeImage();
    SetPurposeFont();
    // Outline characters will be stored one after the opaque characters
    // thus doubling the size of the glyph data/texture coord lists. The
    // multiplier is already 1 by default so this just makes it equal 2.
    if(ftfData.IsOutline()) stMultiplier = 2;
    // Set default scaled font size and line spacing adjust
    SetSize(1.0f);
    // Set initial size of image. The image size starts here and can
    // automatically grow by the power of 2 if more space is needed.
    DimSet(uiISize ? uiISize :
      GetMaxTexSizeFromBounds(0, 0, duiTile.DimGetWidth(),
        duiTile.DimGetHeight(), 1));
    // Check if texture size is valid
    if(DimGetWidth() > cOgl->MaxTexSize() ||
       duiTile.DimGetWidth() > cOgl->MaxTexSize())
      XC("Texture dimensions for font not supported by graphics processor!",
         "Identifier", IdentGet(),          "Requested",  uiISize,
         "Width",      DimGetWidth(),       "Height",     DimGetHeight(),
         "TileWidth",  duiTile.DimGetWidth(),
         "TileHeight", duiTile.DimGetHeight(),
         "Maximum",    cOgl->MaxTexSize());
    // Estimate how many glyphs we're fitting in here to prevent unnecessary
    // alocations
    const size_t stGColumns = DimGetWidth() / duiTile.DimGetWidth(),
                 stGRows = DimGetHeight() / duiTile.DimGetHeight(),
                 stGTotal = UtilNearestPow2<size_t>(stGColumns * stGRows);
    // Init bin packer so we can tightly pack glyphs together. We're trying to
    // guess the size of the rlFree and rlUsed structs are too.
    ipData.Init(DimGetWidth(), DimGetHeight(), stGTotal, stGTotal);
    // Initialise texture image. Remember it needs to be cleared as the
    // parts that are padding will not be written to 'ever' and that would
    // cause display artifacts
    Memory mPixels{ DimGetWidth() * DimGetHeight() * 2 };
    mPixels.MemFill<uint16_t>(0x00FF);
    InitRaw(ftfData.IdentGet(), mPixels, DimGetWidth(), DimGetHeight(),
      BD_GRAYALPHA);
    // Initialise image in GL. This class is responsible for updating the
    // texture tile co-ords set.
    InitImage(*this, duiTile.DimGetWidth(), duiTile.DimGetHeight(),
      uiPadding, uiPadding, ofeFilter, false);
    // Make enough space for initial tex coords set
    clTiles.resize(1);
    // Show that we've loaded the file
    cLog->LogInfoExSafe("Font '$' loaded FT font (IS:$;P:$;F:$;FL:$$)...",
      ftfData.IdentGet(), uiISize, uiPadding, ofeFilter, hex,
      ffFlags.FlagGet());
  }
  /* -- Init as a pre-rendered font ---------------------------------------- */
  void InitFont(Image &imSrc)
  { // Get filename from image and use it as an id for the font
    IdentSet(imSrc.IdentGet());
    // Show filename
    cLog->LogDebugExSafe("Font loading '$' from bitmap.", IdentGet());
    // Strip path name, build manifest  file name and open it
    const PathSplit psFont{ IdentGet() };
    const string strManfiest{
      StrAppend(psFont.strLoc, psFont.strFile, ".txt") };
    const FileMap fC{ AssetExtract(strManfiest) };
    // Convert whole file data to a string
    const string strBuffer{ fC.MemToString() };
    if(strBuffer.size() < 3)
      XC("Index file is possibly corrupted!",
         "Identifier", IdentGet(), "Manfiest", strManfiest);
    // Get format of CR/LF in buffer. Throw error if not found
    const string strTokens{ StrGetReturnFormat(strBuffer) };
    if(strTokens.empty())
      XC("Index file format not detected!",
         "Identifier",   IdentGet(), "Manfiest", strManfiest,
         "BufferLength", strBuffer.length());
    // Split variables and throw error if there are no vars
    const ParserConst<> pManifest{ strBuffer, strTokens, '=' };
    if(!pManifest.size())
      XC("No metadata in index file!",
         "Identifier", IdentGet(), "Manfiest", strManfiest);
    // Get number of characters and offset.
    const unsigned int
      uiCharCount = StrToNum<unsigned int>(pManifest.ParserGet("range")),
      uiCharOffset = StrToNum<unsigned int>(pManifest.ParserGet("rangestart"));
    if(!uiCharCount)
      XC("Invalid character count in metadata!",
         "Identifier", IdentGet(),   "Manfiest", strManfiest,
         "Offset",     uiCharOffset, "Count",    uiCharCount);
    const unsigned int uiCharEnd = uiCharOffset + uiCharCount;
    // Set and check default character and if it's a number
    const string strDefaultChar{ pManifest.ParserGet("default") };
    if(strDefaultChar.empty())
      XC("Empty default character index in metadata!",
         "Identifier", IdentGet());
    // Check if it's a literal number as prefixed by a hash sign? Convert as a
    // literal number else convert as an a literal character then verify it is
    // in the specified range.
    ulDefaultChar =
      (strDefaultChar.length() > 1 && strDefaultChar.front() == '#') ?
        StrToNum<unsigned int>(strDefaultChar.substr(1)) :
        UtfDecoder{ strDefaultChar }.Next();
    if(ulDefaultChar < uiCharOffset || ulDefaultChar >= uiCharEnd)
      XC("Default character index in metadata out of range!",
         "Identifier", IdentGet(),     "Index",   strManfiest,
         "Value",      strDefaultChar, "Default", ulDefaultChar,
         "Minimum",    uiCharOffset,   "Maximum", uiCharEnd,
         "Count",      uiCharCount);
    // Get filter
    ofeFilter = static_cast<OglFilterEnum>(
      StrToNum<size_t>(pManifest.ParserGet("filter")));
    if(ofeFilter >= OF_MAX)
      XC("Invalid filter index specified in font metadata!",
         "Identifier", IdentGet(), "Filter", ofeFilter);
    // Look for widths and throw if there are none then report them in log
    const string strWidths{ pManifest.ParserGet("width") };
    if(strWidths.empty())
      XC("No widths found in metadata!",
         "Identifier", IdentGet(), "Manfiest", strManfiest);
    cLog->LogDebugExSafe("- Widths: $.", strWidths);
    // Break apart the widths and throw if there are none
    const StrVector svList{ StdMove(Token{ strWidths, cCommon->Space() }) };
    if(svList.size() != uiCharCount)
      XC("Unexpected number of widths detected in metadata!",
         "Identifier", IdentGet(),  "Index",  strManfiest,
         "Expect",     uiCharCount, "Actual", svList.size());
    // Reserve memory for all the requested character space
    gvData.reserve(uiCharEnd);
    // Add the starting unused characters
    gvData.resize(uiCharOffset);
    // Read size of tile. Texture init will clamp this if needed.
    const unsigned int
      uiTW = StrToNum<unsigned int>(pManifest.ParserGet("tilewidth")),
      uiTH = StrToNum<unsigned int>(pManifest.ParserGet("tileheight"));
    // Convert to float as we need a float version of this in the next loop
    const GLfloat fW = static_cast<GLfloat>(uiTW),
                  fH = static_cast<GLfloat>(uiTH);
    // Add the characters the manifest file cares about
    transform(svList.cbegin(), svList.cend(), back_inserter(gvData),
      [fW, fH](const string &strWidth)->const Glyph{
        return { fW,fH, true, StrToNum<GLfloat>(strWidth), 0.0f, 0.0f, fW,fH };
      });
    // Now we have the default character we can fill all the unused slots with
    // the default characters data.
    const unsigned int uiCharOffsetM1 = uiCharOffset-1;
    const Glyph &gRef = gvData[ulDefaultChar];
    StdFill(par_unseq, gvData.begin(), gvData.begin() + uiCharOffsetM1, gRef);
    StdFill(par_unseq, gvData.begin() + uiCharEnd, gvData.end(), gRef);
    // Initialise memory for texture tile co-ordinates
    clTiles.resize(1);
    CoordList &clFirst = clTiles.front();
    clFirst.reserve(uiCharEnd);
    clFirst.resize(uiCharOffset);
    // Get extra tile padding dimensions. Also clamped by texture class
    const unsigned int
      uiPX = StrToNum<unsigned int>(pManifest.ParserGet("tilespacingwidth")),
      uiPY = StrToNum<unsigned int>(pManifest.ParserGet("tilespacingheight"));
    // Init texture with custom parameters and generate tileset
    InitImage(imSrc, uiTW, uiTH, uiPX, uiPY, ofeFilter);
    // Initialise the uninitialised texcoords with the default character that
    // was initialised using InitImage
    const CoordData &cdRef = clFirst[ulDefaultChar];
    StdFill(par_unseq, clFirst.begin(),
                       clFirst.begin() + uiCharOffsetM1, cdRef);
    StdFill(par_unseq, clFirst.begin() + uiCharEnd, clFirst.end(), cdRef);
    // Initialise font scale
    SetSize(StrToNum<GLfloat>(pManifest.ParserGet("scale")));
    // Show that we've loaded the file
    cLog->LogInfoExSafe("Font '$' loaded from bitmap (T:$x$;F:$).",
      IdentGet(), uiTW, uiTH, ofeFilter);
  }
  /* -- Constructor (Initialisation then registration) --------------------- */
  Font(void) :                         // No parameters
    /* -- Initialisers ----------------------------------------------------- */
    ICHelperFont{ cFonts, this }       // Initially registered
    /* --------------------------------------------------------------------- */
    { }                                // Do nothing else
  /* -- Constructor (without registration) --------------------------------- */
  explicit Font(const bool) :          // Dummy parameter
    /* -- Initialisers ----------------------------------------------------- */
    ICHelperFont{ cFonts }             // Initially unregistered
    /* --------------------------------------------------------------------- */
    { }                                // Do nothing else
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(Font)                // Suppress default functions for safety
};/* ----------------------------------------------------------------------- */
CTOR_END_NOINITS(Fonts, Font, FONT)    // End of collector class
/* -- DeInit Font Textures ------------------------------------------------- */
static void FontDeInitTextures(void)
{ // Ignore if no fonts
  if(cFonts->empty()) return;
  // De-init all the font textures and log pre/post deinit
  cLog->LogDebugExSafe("Fonts de-initialising $ objects...", cFonts->size());
  for(Font*const fCptr : *cFonts) fCptr->DeInit();
  cLog->LogInfoExSafe("Fonts de-initialising $ objects.", cFonts->size());
}
/* -- Reload Font Textures ------------------------------------------------- */
static void FontReInitTextures(void)
{ // Ignore if no fonts
  if(cFonts->empty()) return;
  // Re-init all the font textures and log pre/post init
  cLog->LogDebugExSafe("Fonts re-initialising $ objects...", cFonts->size());
  for(Font*const fCptr : *cFonts) fCptr->ReloadTexture();
  cLog->LogInfoExSafe("Fonts re-initialising $ objects.", cFonts->size());
}
/* ------------------------------------------------------------------------- */
}                                      // End of public module namespace
/* ------------------------------------------------------------------------- */
}                                      // End of private module namespace
/* == EoF =========================================================== EoF == */

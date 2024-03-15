/* == PIXCON.HPP =========================================================== **
** ######################################################################### **
** ## MS-ENGINE              Copyright (c) MS-Design, All Rights Reserved ## **
** ######################################################################### **
** ## This is a POSIX specific module that handles text only mode output  ## **
** ## which is needed by the engines bot mode and uses ncurses. Since we  ## **
** ## support MacOS and Linux, we can support both systems very simply    ## **
** ## with POSIX compatible calls.                                        ## **
** ######################################################################### **
** ========================================================================= */
#pragma once                           // Only one incursion allowed
/* == Includes ============================================================= **
** Because ncurses shares function names with STL, we need to put it all the **
** Curses API in it's own namespace to prevent ambiguity problems.           **
** ------------------------------------------------------------------------- */
namespace ICurses {                    // Start of Curses interface
#ifdef MACOS                           // Using MacOS? (Built-in is buggy)
# include <curses/curses.h>            // Using our static curses library
#else                                  // Using Linux? (Built-in is OK)
# include <ncurses.h>                  // Using Curses for fancy term effects
#endif                                 // End of POSIX OS detection
}                                      // End of Curses interface
/* == Console Class ======================================================== */
class SysCon :                         // All members initially private
  /* -- Base classes ------------------------------------------------------- */
  public SysBase,                      // Defined in 'sys(nix/mac).hpp'
  public SysConBase,                   // Defined in 'syscore.hpp'
  private IHelper,                     // Allow access to windows console
  private DimCoInt                     // Console drawing position & dimensions
{  /* -- Typedefs ---------------------------------------------------------- */
  typedef ICurses::attr_t attr_t;      // NCurses alias
  typedef Coordinates<int> CoordInt;   // Cordinates typedef
  typedef Dimensions<int> DimInt;      // Dimension typedef
  /* -- Console data ------------------------------------------------------- */
  __sighandler_t   fpSignal;           // Old signal handler
  attr_t           aColour;            // Current colour
  attr_t           aColourSaved;       // Saved colour
  /* -- Co-ordinates and limits -------------------------------------------- */
  size_t           stPalette;          // Palette colours count
  size_t           stPairs;            // Pairs count
  CoordInt         ciCursor;           // Cursor position
  DimInt           diSizeM1, diSizeM2; // Console bounds minus 1 and 2
  int              iCursor;            // Current cursor setting
  /* -- Storing original palette ------------------------------------------- */
  typedef array<short,3>             ShortTri;
  typedef array<ShortTri,COLOUR_MAX> ColourTable;
  typedef array<short,2>             ShortPair;
  typedef vector<ShortPair>          PairTable;
  ColourTable      ctPalette;          // Saved colour palette
  PairTable        ptPairs;            // Saved colour pairs
  /* -- Signal handler ----------------------------------------------------- */
  // Please do remember that this call could happen in any thread!
  static void OnTerminalResized(int) { cEvtMain->Add(EMC_CON_RESIZE); }
  /* -- Do set a character at the current position ------------------------- */
  void DoSetChar(const unsigned int uiChar)
  { // Include curses namespace
    using namespace ICurses;
    const cchar_t ccChar{ aColour, { static_cast<wchar_t>(uiChar) }, 0 };
    // Print character and get result
    switch(const int iResult = add_wch(&ccChar))
    { // If failed?
      default:
        // If it was because we tried to write the bottom-right most character?
        // Then ignore reporting because MacOS is returning error for this but
        // actually changing the colour for us. So that's obviously a bug!
        if(CoordGetX() != diSizeM1.DimGetWidth() ||
           CoordGetY() != diSizeM1.DimGetHeight())
          cLog->LogWarningExSafe(
            "SysCon set character failed! (C:$<$$>;A:$$<$$>;P:$$x$;R:$)",
            uiChar, hex, uiChar, dec, aColour, hex, aColour, dec, CoordGetX(),
            CoordGetY(), iResult);
        // Fall through to break
        [[fallthrough]];
      // Succeeded?
      case OK: break;
    }
  }
  /* -- Redraw screen and check for error ---------------------------------- */
  void CommitScreen(void)
  { // Commit all settings and buffer
    switch(const int iResult = ICurses::refresh())
    { // Unknown result?
      default:
        // Log the result
        cLog->LogWarningExSafe("SysCon refresh result $!", iResult);
        // Fall through to break
        [[fallthrough]];
      // Success? Break
      case OK: break;
    }
  }
  /* -- Set maximum console line length ---------------------------- */ public:
  CVarReturn RowsModified(const size_t stRows)
  { // Deny if out of range. The maximum value is a SHORT from Win32 API.
    if(stRows < 25 || UtilIntWillOverflow<int>(stRows)) return DENY;
    // Value allowed
    return ACCEPT;
  }
  /* -- Set maximum console line length ------------------------------------ */
  CVarReturn ColsModified(const size_t stCols)
  { // Deny if out of range. The maximum value is a SHORT from Win32 API.
    if(stCols < 80 || UtilIntWillOverflow<int>(stCols)) return DENY;
    // Value allowed
    return ACCEPT;
  }
  /* -- Return console window handle --------------------------------------- */
  void *GetHandle(void) { return nullptr; }
  /* -- Check for and update size ------------------------------------------ */
  void CheckAndUpdateSize(void)
  { // Include curses namespace
    using namespace ICurses;
    // am just going to put this here just incase.
    if(isendwin()) return;
    // Update size of terminal window
    int iNewW, iNewH; getmaxyx(stdscr, iNewH, iNewW);
    // Ignore if not changed
    if(iNewW == DimGetWidth() && iNewH == DimGetHeight()) return;
    // Log the new size
    cLog->LogDebugExSafe("SysCon resized from $x$ to $x$.",
      iNewW, iNewH, DimGetWidth(), DimGetHeight());
    // Update size
    DimSet(iNewW, iNewH);
    diSizeM1.DimSet(DimGetWidth()-1, DimGetHeight()-1);
    diSizeM2.DimSet(DimGetWidth()-2, DimGetHeight()-2);
    // Update cursor position if invalid
    if(ciCursor.CoordGetX() >= DimGetWidth())
      ciCursor.CoordSetX(diSizeM1.DimGetWidth());
    if(ciCursor.CoordGetY() >= DimGetHeight())
      ciCursor.CoordSetY(diSizeM1.DimGetHeight());
    // Refresh the window which stops failures of other routines
    CommitScreen();
  }
  /* -- Check keys ------------------------------------------------- */ public:
  KeyType GetKey(int &iKey, int &iMods)
  { // Include curses namespace
    using namespace ICurses;
    // signify function keys but we don't care about them at the moment.
    wint_t wChar = 0;
    switch(const int iResult = get_wch(&wChar))
    { // If no key is waiting then return no key
      case ERR: return KT_NONE;
      // If it's a normal key?
      case OK:
        // Check key
        switch(wChar)
        { // Home key pressed? (Not mapped by default)
          case 1: iMods = 0; iKey = GLFW_KEY_HOME; break;
          // End key pressed? (Not mapped by default)
          case 5: iMods = 0; iKey = GLFW_KEY_END; break;
          // Escape key pressed?
          case 27: iMods = 0; iKey = GLFW_KEY_ESCAPE; break;
          // Return key pressed?
          case '\r': case '\n': iMods = 0; iKey = GLFW_KEY_ENTER; break;
          // Backspace key pressed?
          case '\b': case 127: iMods = 0; iKey = GLFW_KEY_BACKSPACE; break;
          // Tab key pressed?
          case '\t': iMods = 0; iKey = GLFW_KEY_TAB; break;
          // Other key?
          default:
            // Ignore other control keys
            if(wChar < ' ') return KT_NONE;
            // Set key
            iKey = static_cast<int>(wChar);
            // No mods on plain keys
            iMods = 0;
            // Return whether it is an valid key or not
            return KT_CHAR;
        } // Treated as virtual key
        return KT_KEY;
      // Is a function key?
      case KEY_CODE_YES:
        // Test key
        switch(wChar)
        { // Control+Home pressed?
          case 537: /* MacOS14 \033[1;5H */ case 535: /* Ubuntu default */
            iMods = GLFW_MOD_CONTROL; iKey = GLFW_KEY_HOME; break;
          // Control+End pressed?
          case 532: /* MacOS14 \033[1;5F */ case 530: /* Ubuntu default */
            iMods = GLFW_MOD_CONTROL; iKey = GLFW_KEY_END; break;
          // Control+PageUp pressed?
          case 557: /* MacOS14 \033[5;5~ */ case 555: /* Ubuntu default */
            iMods = GLFW_MOD_CONTROL; iKey = GLFW_KEY_PAGE_UP; break;
          // Control+PageDown pressed?
          case 552: /* MacOS14 \033[6;5~ */ case 550: /* Ubuntu default */
            iMods = GLFW_MOD_CONTROL; iKey = GLFW_KEY_PAGE_DOWN; break;
          // Control+Delete (MacOS KB) or Insert (PC KB) pressed?
          case 515: case KEY_IC: iMods = 0; iKey = GLFW_KEY_INSERT; break;
          // Trivial keys pressed?
          case KEY_BACKSPACE : iMods = 0; iKey = GLFW_KEY_BACKSPACE; break;
          case KEY_ENTER     : iMods = 0; iKey = GLFW_KEY_ENTER; break;
          case KEY_HOME      : iMods = 0; iKey = GLFW_KEY_HOME; break;
          case KEY_END       : iMods = 0; iKey = GLFW_KEY_END; break;
          case KEY_PPAGE     : iMods = 0; iKey = GLFW_KEY_PAGE_UP; break;
          case KEY_NPAGE     : iMods = 0; iKey = GLFW_KEY_PAGE_DOWN; break;
          case KEY_UP        : iMods = 0; iKey = GLFW_KEY_UP; break;
          case KEY_DOWN      : iMods = 0; iKey = GLFW_KEY_DOWN; break;
          case KEY_LEFT      : iMods = 0; iKey = GLFW_KEY_LEFT; break;
          case KEY_RIGHT     : iMods = 0; iKey = GLFW_KEY_RIGHT; break;
          case KEY_DC        : iMods = 0; iKey = GLFW_KEY_DELETE; break;
          // Resized terminal? Send event that the terminal resized.
          case KEY_RESIZE    : OnTerminalResized(0); return KT_NONE;
          // Unknown key
          default:
            // Report it
            cLog->LogDebugExSafe(
              "SysCon ignoring $ scan code $ (H:0x$$;O:$$).",
              wChar >= KEY_MAX ? "invalid" : "unsupported", wChar,
              hex, wChar, oct, wChar);
            // Done
            return KT_NONE;
        } // Treated as virtual key
        return KT_KEY;
      // Unknown error
      default: XC("Unknown error reading input!", "Error", iResult);
    }
  }
  /* -- Commit argument for curs_set() ------------------------------------- */
  void CommitCursor(void)
  { // Change it and save new cursor setting
    switch(const int iResult = ICurses::curs_set(iCursor))
    { // Anything else report in log?
      default: cLog->LogWarningExSafe("SysCon set cursor type to $ result $!",
                 iCursor, iResult);
               // Fall through to break
               [[fallthrough]];
      // Break if cursor set was ok
      case 0: case 1: case 2: break;
    }
  }
  /* -- Update argument for curs_set() ------------------------------------- */
  void UpdateCursorId(void)
    { iCursor = FlagIsSet(SCO_CURVISIBLE) ?
        (FlagIsSet(SCO_CURINSERT) ? 2 : 1) : 0; }
  /* -- Set colour --------------------------------------------------------- */
  void SetColour(const size_t stColour)
  { // Include curses namespace for use of COLOR_PAIR
    using namespace ICurses;
    aColour = static_cast<attr_t>(COLOR_PAIR(stColour % stPairs));
  }
  /* -- Set cursor size ---------------------------------------------------- */
  void SetCursorMode(const bool bInsert)
  { // Set insert cursor setting, update and commit it
    FlagSetOrClear(SCO_CURINSERT, bInsert);
    UpdateCursorId();
    CommitCursor();
  }
  /* -- Set cursor visibility state ---------------------------------------- */
  void SetCursorVisibility(const bool bEnabled)
    { FlagSetOrClear(SCO_CURVISIBLE, bEnabled); UpdateCursorId(); }
  /* -- Set cursor position ------------------------------------------------ */
  void SetCursor(const int iNX, const int iNY) { CoordSet(iNX, iNY); }
  /* -- Commit buffer ------------------------------------------------------ */
  void CommitBuffer(void)
  { // Include curses namespace
    using namespace ICurses;
    switch(const int iResult =
      move(ciCursor.CoordGetY(), ciCursor.CoordGetX()))
    { // Unknown result
      default:
      { // Show error
        cLog->LogWarningExSafe("SysCon move cursor to $x$ result $!",
          ciCursor.CoordGetX(), ciCursor.CoordGetY(), iResult);
        // Fall through to break
        [[fallthrough]];
      } // Success? Break
      case OK: break;
    } // Commit cursor if not changed
    CommitCursor();
    // Commit all settings and buffer
    CommitScreen();
  }
  /* -- Set a character at the current position ---------------------------- */
  void SetChar(const unsigned int uiChar=' ')
  { // Include curses namespace
    using namespace ICurses;
    switch(const int iResult = move(CoordGetY(), CoordGetX()))
    { // If successful?
      case OK:
        // If size of unsigned int isn't equal to wchar_t? We will need to
        // check for overflow and print a '?' if so.
        if constexpr(sizeof(uiChar) != sizeof(wchar_t))
          DoSetChar(uiChar > numeric_limits<wchar_t>::max() ? '?' : uiChar);
        // Size is equal to wchar_t?
        else DoSetChar(uiChar);
        // Done
        break;
      // Failed so write error to log
      default: cLog->LogWarningExSafe(
        "SysCon move cursor failed! (C:$<$$>;A:$$<$$>;P:$$x$;R:$)",
          uiChar, hex, uiChar, dec, aColour, hex, aColour, dec, CoordGetX(),
          CoordGetY(), iResult);
        // Done
        break;
    }
  }
  /* -- Set a character at the specified screen buffer position ------------ */
  void SetCharPos(const int iNX, const int iNY, const unsigned int uiC=' ')
    { SetCursor(iNX, iNY); SetChar(uiC); }
  /* -- Do set characters until we reach the maximum ----------------------- */
  void ClearLine(const int iMax)
    { for(; CoordGetX() < iMax; CoordIncX()) SetChar(); }
  void ClearLine(void) { ClearLine(DimGetWidth()); }
  /* -- Save and restore colour -------------------------------------------- */
  void PushColour(void) { aColourSaved = aColour; }
  void PopColour(void) { aColour = aColourSaved; }
  /* -- Distance ----------------------------------------------------------- */
  unsigned int Distance(const unsigned int uiD1, const unsigned int uiD2)
  { // Calculate deltas of components
    const unsigned int
      uiDeltaR = ((uiD1 & 0x00FF0000) >> 16) - ((uiD2 & 0x00FF0000) >> 16),
      uiDeltaG = ((uiD1 & 0x0000FF00) >>  8) - ((uiD2 & 0x0000FF00) >>  8),
      uiDeltaB =  (uiD1 & 0x000000FF)        -  (uiD2 & 0x000000FF);
    // Return distance
    return uiDeltaR * uiDeltaR + uiDeltaG * uiDeltaG + uiDeltaB * uiDeltaB;
  }
  /* -- Set colour as integer helper function ------------------------------ */
  void SetColourInteger(const unsigned int uiColour, const size_t stShift,
    const size_t stXOR)
  { // Minimum distance between colour and closest colour
    unsigned int uiMinDist = Distance(uiColour, uiNDXtoRGB[0]);
    // Prepare first colour
    size_t stChosen = 0;
    // Walk through available colours
    for(size_t stIndex = 1; stIndex < stPalette; ++stIndex)
    { // Get current distance between specified colour and colour in pallette
      unsigned int uiCurDist = Distance(uiColour, uiNDXtoRGB[stIndex]);
      // Ignore the entry if is not near the minimum
      if(uiCurDist >= uiMinDist) continue;
      // Update new selected colour and chosen index
      uiMinDist = uiCurDist;
      stChosen = stIndex;
    } // Set chosen colour
    SetColour((stChosen << stShift) + stXOR);
  }
  /* -- Set foreground colour as int --------------------------------------- */
  void SetForegroundInteger(const unsigned int uiColour)
    { SetColourInteger(uiColour, 0, 0); }
  /* -- Set background colour as int --------------------------------------- */
  void SetBackgroundInteger(const unsigned int uiColour)
    { SetColourInteger(uiColour, 7, 128); }
  /* -- Handle print control character ------------------------------------- */
  void HandlePrintControl(UtfDecoder &utfStr, const bool bSimulation)
  { // Get next character
    switch(utfStr.Next())
    { // Colour selection
      case 'c':
      { // Scan for the hexadecimal value and if we found it? Set Tint if not
        // simulation and we read 8 bytes
        unsigned int uiCol;
        if(utfStr.ScanValue(uiCol) == 8 && !bSimulation)
          SetForegroundInteger(uiCol);
        // Done
        break;
      } // Outline colour selection
      case 'o':
      { // Scan for the hexadecimal value and if we found it? Set Tint if not
        // simulation and we read 8 bytes
        unsigned int uiCol;
        if(utfStr.ScanValue(uiCol) == 8 && !bSimulation)
          SetBackgroundInteger(uiCol);
        // Done
        break;
      } // Reset colour
      case 'r': if(!bSimulation) PopColour(); break;
      // Print glyph? Ignore texture and skip the next value and break
      case 't': utfStr.SkipValue(); break;
      // Invalid control character.
      default: break;
    }
  }
  /* -- Locate a supported character while checking if word can be printed - */
  bool PrintGetWord(UtfDecoder &utfStr, int iXp, const int iWi)
  { // Save position because we're not drawing anything
    const unsigned char *ucpPtr = utfStr.GetCPtr();
    // Until null character. Which control token?
    while(const unsigned int uiChar = utfStr.Next()) switch(uiChar)
    { // Carriage return or space char? Restore position and return no wrap
      case '\n': case ' ': utfStr.SetCPtr(ucpPtr); return false;
      // Other control character? Handle print control characters
      case '\r': HandlePrintControl(utfStr, true); break;
      // Normal character
      default:
        // Printing next character would exceed wrap width?
        if(1 + iXp >= iWi)
        { // Restore position
          utfStr.SetCPtr(ucpPtr);
          // Wrap to next position
          return true;
        } // Move X along
        ++iXp;
        // Done
        break;
    } // Restore position
    utfStr.SetCPtr(ucpPtr);
    // No wrap occured and caller should not Y adjust
    return false;
  }
  /* -- Handle return on print --------------------------------------------- */
  void HandleReturnSimulated(UtfDecoder &utfStr, int &iXp, int &iYp,
    const int iIn)
  { // Go down own line and set indentation
    iXp = iIn;
    ++iYp;
    // Discard further spaces and return string minus one space
    utfStr.Ignore(' ');
  }
  /* -- If co-ordinates are in valid range to draw ------------------------- */
  bool ValidY(const int iYp)
    { return iYp >= 1 && iYp <= diSizeM1.DimGetHeight(); }
  /* -- Handle return on print --------------------------------------------- */
  void HandleReturn(UtfDecoder &utfStr, const int iIn)
  { // If we can draw on this Y? Clear up till the end
    if(ValidY(CoordGetY())) ClearLine();
    // If we can draw on the next line too? Clear up to indentation
    CoordIncY();
    if(ValidY(CoordGetY())) { CoordSetX(0); ClearLine(iIn); }
    // We cann't draw on the next line? Just set new indentation position
    else CoordSetX(iIn);
    // Discard further spaces and return string minus one space
    utfStr.Ignore(' ');
  }
  /* -- Write data upwards and wrapping (same as what Char::* does) -------- */
  int WriteLineWU(UtfDecoder &&utfStr)
  { // Check the string is valid
    if(!utfStr.Valid()) return 1;
    // Save current colour
    PushColour();
    // Indent
    const int iIndent = 1;
    // Simulated cursor position
    int iXp = 0, iYp = 1;
    // Until null character, which character?
    while(const unsigned int uiChar = utfStr.Next()) switch(uiChar)
    { // Carriage return?
      case '\n': HandleReturnSimulated(utfStr, iXp, iYp, iIndent); break;
      // Other control character? Handle print control characters
      case '\r': HandlePrintControl(utfStr, true); break;
      // Whitespace character?
      case ' ':
      { // Move X position along and ignore if the space character processed
        // went over the limit OR Check if the draw length of the next word
        // would go off the limit and if either did? Handle the return!
        if(++iXp + 1 > DimGetWidth() ||
           PrintGetWord(utfStr, iXp, DimGetWidth()))
          HandleReturnSimulated(utfStr, iXp, iYp, iIndent);
        // Done
        break;
      } // Normal character
      default:
      { // Printing next character would exceed wrap width? Wrap and indent
        if(iXp + 1 > DimGetWidth())
          HandleReturnSimulated(utfStr, iXp, iYp, iIndent);
        // No exceed, move X position forward
        iXp += 1;
        // Done
        break;
      }
    } // Restore previous colour incase it was changed
    PopColour();
    // Reset the iterator on the utf string.
    utfStr.Reset();
    // Set actual cursor position
    CoordSet(0, CoordGetY() - iYp);
    // Record original X and Y position
    const int iXO = CoordGetX() + iIndent;
    // Until null character, which character?
    while(const unsigned int uiChar = utfStr.Next()) switch(uiChar)
    { // Carriage return?
      case '\n': HandleReturn(utfStr, iXO); break;
      // Other control character? Handle print control characters
      case '\r': HandlePrintControl(utfStr, false); break;
      // Whitespace character?
      case ' ':
      { // Do the print if we can
        if(ValidY(CoordGetY())) SetChar(uiChar);
        // Move the next X position
        CoordIncX();
        // Ignore if the space character processed went over the limit OR
        // Check if the draw length of the next word would go off the limit
        // and if either did? Handle the wrapping
        if(CoordGetX() + 1 > DimGetWidth() ||
           PrintGetWord(utfStr, CoordGetX(), DimGetWidth()))
          HandleReturn(utfStr, iXO);
        // Done
        break;
      } // Normal character
      default:
      { // Printing next character would exceed wrap width?
        if(CoordGetX() + 1 > DimGetWidth())
        { // Handle the wrapping
          HandleReturn(utfStr, iXO);
          // If we can print the character? Print the character
          if(ValidY(CoordGetY())) SetChar(uiChar);
        } // Wouldn't wrap so if we can print the character? Print the char
        else if(ValidY(CoordGetY())) SetChar(uiChar);
        // Move along the X position
        CoordIncX();
        // Done
        break;
      }
    } // Clear the rest of the line
    if(ValidY(CoordGetY())) ClearLine();
    // Restore colour
    PopColour();
    // Return height of printed text
    return iYp;
  }
  /* -- Write data --------------------------------------------------------- */
  void WriteLine(UtfDecoder &&utfString, const int iMax, const bool bClrEOL)
  { // For each character index in the buffer
    while(const unsigned int uiChar = utfString.Next())
    { // Compare character
      switch(uiChar)
      { // Carriage return? (impossible).
        case '\n': break;
        // Is a control character?
        case '\r': HandlePrintControl(utfString, false); break;
        // Get pointer to character ata
        default : SetChar(uiChar); CoordIncX(); break;
      } // Increase position in screen buffer and break if at end of string/buf
      if(CoordGetX() >= iMax) break;
    } // Now we need to clear old characters up to the end of line
    if(bClrEOL) ClearLine();
  }
  /* -- Redraw status input text ------------------------------------------- */
  void RedrawInputBar(const string &strIL, const string &strIR)
  { // Set cursor position
    SetCursor(0, diSizeM1.DimGetHeight());
    // Set input bar colour
    SetColour(79);
    // Clear the line with the above colour
    ClearLine();
    // Length of left part of text
    CoordSetX(1);
    // Left string length
    int iLen;
    // Have left side text?
    if(!strIL.empty())
    { // Put left text in a UTF container
      UtfDecoder utfString{ strIL };
      // Set length
      iLen = static_cast<int>(utfString.Length());
      // Reset at scrolled position
      utfString.Reset(strIL.c_str() +
        abs(UtilMaximum(0, iLen - diSizeM2.DimGetWidth())));
      // Draw start of input text
      WriteLine(StdMove(utfString), diSizeM1.DimGetWidth(), false);
    } // Left size of text is zero long
    else iLen = 0;
    // Have right side of text and have characters left on screen to spare?
    if(!strIR.empty() && iLen < diSizeM2.DimGetWidth())
    { // Set cursor position
      SetCursor(1 + iLen, diSizeM1.DimGetHeight());
      // Reset again and write the string
      WriteLine(UtfDecoder(strIR), diSizeM1.DimGetWidth(), false);
    } // Actually set cursor position
    ciCursor.CoordSet(UtilMinimum(diSizeM1.DimGetWidth(), 1 + iLen),
                                  diSizeM1.DimGetHeight());
    // Cursor is visible
    SetCursorVisibility(true);
  }
  /* -- Set a space at the specified X position ---------------------------- */
  void SetWhitespace(const int iPos=0)
  { // Set start position
    CoordSetX(iPos);
    // Set the whitespace
    SetChar();
    // Move on
    CoordIncX();
  }
  /* -- Redraw a status bar ------------------------------------------------ */
  void RedrawStatus(const int iSY, const string &strL, const string &strR)
  { // Reset drawing row
    SetCursor(0, iSY);
    // Set colour
    SetColour(31);
    // Get length of left and right part of string
    UtfDecoder utfL{ strL }, utfR{ strR };
    const int iL = static_cast<int>(utfL.Length()),
              iLC = static_cast<int>(UtilMinimum(iL, diSizeM2.DimGetWidth())),
              iR = static_cast<int>(utfR.Length()),
              iRC = static_cast<int>(UtilMinimum(iR, diSizeM2.DimGetWidth()));
    // If we have left status text length?
    if(iLC)
    { // If the right text would not completely obscure the left text?
      if(iRC < diSizeM2.DimGetWidth())
      { // Set start position, clear the character and move forward
        SetWhitespace();
        // Reset left text position
        utfL.Reset();
        // Put string in a container and draw the string with left align
        WriteLine(StdMove(utfL), CoordGetX()+iLC, false);
        // If there is no right text we can just clear to the end of line
        if(!iRC) return ClearLine();
      } // No length of left text? Set initial position.
      else CoordSetX(1);
    } // If there is no right next
    else if(!iRC)
    { // Select start of line
      CoordSetX(0);
      // Clear to end of line
      return ClearLine();
    } // No length of left text and have right text? Set starting whitespace.
    else SetWhitespace();
    // Both texts can only share 'iWm2' characters so they need to share
    // this limited space. If there is enough space for both?
    const int iTotal = UtilMinimum(diSizeM2.DimGetWidth(), iLC + iRC);
    if(iTotal < diSizeM2.DimGetWidth())
    { // Get position to write at
      const int iSpaces = diSizeM2.DimGetWidth() - iTotal,
                   iEnd = CoordGetX() + iSpaces;
      // Repeat writing spaces until we've reached the end position
      do { SetChar(); CoordIncX(); } while(CoordGetX() < iEnd);
    } // We didn't need to draw any spaces? Set final whitespace.
    else SetWhitespace(diSizeM2.DimGetWidth() - iRC);
    // Reset right string position
    utfR.Reset();
    // Write the line and clear the rest
    WriteLine(StdMove(utfR), CoordGetX()+iRC, true);
  }
  /* -- Redraw bottom status bar ------------------------------------------- */
  void RedrawStatusBar(const string &strSL, const string &strSR)
  { // Redraw the status bar
    RedrawStatus(diSizeM1.DimGetHeight(), strSL, strSR);
    // Set cursor position on commit
    ciCursor.CoordSet(diSizeM1.DimGetWidth(), diSizeM1.DimGetHeight());
    // No input bar so hide cursor
    SetCursorVisibility(false);
  }
  /* -- Redraw title status bar -------------------------------------------- */
  void RedrawTitleBar(const string &strTL, const string &strTR)
    { RedrawStatus(0, strTL, strTR); }
  /* -- Redraw console buffer ---------------------------------------------- */
  void RedrawBuffer(const ConLines &cL, const ConLinesConstRevIt &lS)
  { // Reset cursor position to top left of drawing area
    SetCursor(0, diSizeM1.DimGetHeight());
    // Set default text colour
    SetColour(15);
    // Draw until we go off the top of the screen
    for(ConLinesConstRevIt lL{ lS };
                           lL != cL.rend() && ValidY(CoordGetY());
                         ++lL)
    { // Get structure
      const ConLine &lD = *lL;
      // Convert RGB colour to Win32 console id colour
      SetColour(lD.cColour);
      // Put text in a utf container and write the data. Note: Although
      // CoordGetY() could go effectively negative and we're not using a signed
      // value we can make sure we don't access any OOB memory by just checking
      // that the co-ordinates while drawing, we don't have to worry about the
      // integer wrapping at all we are not drawing.
      CoordDecY(WriteLineWU(UtfDecoder{ lD.strLine }) - 1);
    } // Clear extra lines we didn't draw too
    while(CoordGetY() > 1) { CoordSetX(0); CoordDecY(); ClearLine(); }
  }
  /* -- Update size (from event) ------------------------------------------- */
  void OnResize(void)
  { // Include curses namespace
    using namespace ICurses;
    CheckAndUpdateSize();
    // De-initialise ncurses
    switch(const int iResult = endwin())
    { // Break if OK
      case OK: break;
      // Any other value
      default: XC("Failed to de-initialise ncurses!", "Code", iResult);
    } // Re-initialise ncurses
    if(!initscr()) XC("Failed to re-initialise ncurses!");
  }
  /* -- DeInitialise ------------------------------------------------------- */
  void SysConDeInit(void)
  { // Include curses namespace
    using namespace ICurses;
    if(IHNotDeInitialise()) return;
    // System console is de-initialising
    cLog->LogDebugSafe("SysCon de-initialising...");
    // Install old signal handler
    if(fpSignal) signal(SIGWINCH, fpSignal);
    // If we have a context?
    if(stdscr)
    { // If we can use colour?
      if(can_change_color())
      { // Make sure we initialise all the pairs
        for(size_t stIndex = 1; stIndex < stPairs; ++stIndex)
        { // Get saved palette entry
          ShortPair &spEntry = ptPairs[stIndex];
          // Restore pair entry
          init_pair(static_cast<short>(stIndex), spEntry[0], spEntry[1]);
        } // For each palette entry
        for(size_t stIndex = 1; stIndex < stPalette; ++stIndex)
        { // Get saved palette entry
          ShortTri &stEntry = ctPalette[stIndex];
          // Restore palette entry
          init_color(static_cast<short>(stIndex),
            stEntry[0], stEntry[1], stEntry[2]);
        }
      } // Restore terminal settings
      endwin();
    } // System console is de-initialised
    cLog->LogDebugSafe("SysCon de-initialised!");
  }
  /* -- Initialise --------------------------------------------------------- */
  void SysConInit(const char*const, const size_t, const size_t, const bool)
  { // Include curses namespace
    using namespace ICurses;
    IHInitialise();
    // System console is initialising
    cLog->LogDebugSafe("SysCon initialising...");
    // Set locale
    if(const char*const cpLocale = setlocale(LC_ALL, cCommon->CBlank()))
      { cLog->LogDebugExSafe("SysCon initialised locale to $.", cpLocale); }
    else XCL("Failed to initialse default locale!");
    // Init ncurses
    if(!initscr()) XC("Failed to initialise terminal window!");
    // No newlines on writing output
    if(nonl() == ERR) XC("Failed to disable newline mode!");
    // No delay to getch() please
    if(nodelay(stdscr, true) == ERR) XC("Failed to enable nodelay mode!");
    // Disable ctrl+c?
    if(cbreak() == ERR) XC("Failed to set cbreak mode!");
    // Disable echo
    if(noecho() == ERR) XC("Failed to disable echo!");
    // Enable raw mode
    if(raw() == ERR) XC("Failed to set raw mode!");
    // Disable interrupt flush
    if(intrflush(stdscr, FALSE) == ERR)
      XC("Failed to disable interrupt flush!");
    // Enable special keys
    if(keypad(stdscr, TRUE) == ERR) XC("Failed to enable special keys!");
    // If we can use colour?
    if(can_change_color())
    { // Using colour
      if(start_color() == ERR) XC("Failed to initialise colours!");
      // For each colour in OUR palette...
      for(stPalette = 0; stPalette < COLOUR_MAX; ++stPalette)
      { // Get saved palette entry
        ShortTri &stEntry = ctPalette[stPalette];
        // Narrow the id
        const short sPalette = static_cast<short>(stPalette);
        // Save old colour so we can restore it
        if(color_content(sPalette,
          &stEntry[0], &stEntry[1], &stEntry[2]) == ERR)
            stEntry[0] = stEntry[1] = stEntry[2] = -1;
        // Grab the colour required by the engine
        unsigned int uiRGB = uiNDXtoRGB[stPalette];
        // Calculate new value based on our required colour.
        const short sR = static_cast<short>(static_cast<double>
            (((uiRGB & 0xFF0000) >> 16)) / 0xFF * 1000),
                    sG = static_cast<short>(static_cast<double>
            (((uiRGB & 0x00FF00) >>  8)) / 0xFF * 1000),
                    sB = static_cast<short>(static_cast<double>
            ( (uiRGB & 0x0000FF)       ) / 0xFF * 1000);
        // Feed the RGB to set the palette colours and if failed just break
        // because we don't really know how many colours the terminal supports.
        if(init_color(sPalette, sR, sG, sB) == ERR) continue;
      } // If we loaded colours?
      if(stPalette > 0)
      { // Get maximum supported colours
        const size_t stPairsMaxSupported = static_cast<size_t>(COLOR_PAIRS);
        // Create number of pairs we need. We only need COLOUR_MAX squared so
        // we dont need to load the reset if there are any.
        if(const size_t stPairsMax =
          UtilMinimum<size_t>(stPairsMaxSupported, COLOUR_MAX*COLOUR_MAX))
        { // Size palette array to save colours
          ptPairs.resize(stPairsMax);
          // For each background colour we support. Ignore the first entry.
          for(stPairs = 1; stPairs < stPairsMax; ++stPairs)
          { // Save old foreground and background palette entry
            ShortPair &spEntry = ptPairs[stPalette];
            if(pair_content(static_cast<short>(stPairs),
                 &spEntry[0], &spEntry[1]) == ERR)
              spEntry[0] = spEntry[1] = -1;
            // Calculate foreground and background positions
            const size_t stIndexBG = stPairs / COLOUR_MAX,
                         stIndexFG = stPairs % COLOUR_MAX,
            // If the pairs are the same colour then we don't want to
            // initialise these pairs as whats the point in trying to
            // display the same colour on the same background?
                         stAdd = stIndexFG == stIndexBG ? 1 : 0;
            // Initialise the colour code Wrap the id's to the number of
            // palette entries the terminal let us initialise. Goto the
            // next pair if it succeded else fall through to finish.
            init_pair(static_cast<short>(stPairs),
              static_cast<short>((stIndexFG + stAdd) % stPalette),
              static_cast<short>(stIndexBG % stPalette));
          } // Log number of colours and pairs loaded
          cLog->LogDebugExSafe(
            "SysCon set $/$ palette entries and $/$($) pairs!",
            stPalette, COLOUR_MAX, stPairs, stPairsMax,
            stPairsMaxSupported );
        } // No
        else
        { // Clear the saved pairs table
          ptPairs.clear();
          // Log that we don't have any colour pairs
          cLog->LogDebugExSafe(
            "SysCon set no pairs from the $ palette entries!", stPalette);
        }
      } // No palette entries?
      else cLog->LogWarningExSafe("SysCon set no palette entries from $!",
        COLOUR_MAX);
    } // Install window update signal
    fpSignal = signal(SIGWINCH, OnTerminalResized);
    if(!fpSignal) XCL("Failed to install window update handler!");
    // Update size
    CheckAndUpdateSize();
    // System console is initialised
    cLog->LogDebugSafe("SysCon initialised.");
  }
  /* -- Constructor -------------------------------------------------------- */
  SysCon(SysModList &&svVersion, const size_t stI) : // No parameters
    /* -- Initialisers ----------------------------------------------------- */
    SysBase{ StdMove(svVersion), stI }, // Initialise base with module info
    IHelper{ __FUNCTION__ },           // Initialise init helper
    fpSignal(nullptr),                 // Signal handler on standby
    aColour(0),                        // Black colour
    aColourSaved(0),                   // Black saved colour
    stPalette(0),                      // No palette colours
    stPairs(0),                        // No colour pairs
    diSizeM1{ -1, -1 },                // Init screen dimensions minus 1
    diSizeM2{ -2, -2 },                // Init screen dimensions minus 2
    iCursor(-1)                        // Current cursor setting uninitialised
    /* -- No code ---------------------------------------------------------- */
    { }
  /* -- Destructor --------------------------------------------------------- */
  DTORHELPER(~SysCon, SysConDeInit())
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(SysCon)              // Do not need defaults
};/* ----------------------------------------------------------------------- */
#define MSENGINE_SYSCON_CALLBACKS()    // Not required
/* == EoF =========================================================== EoF == */

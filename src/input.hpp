/* == INPUT.HPP ============================================================ **
** ######################################################################### **
** ## Mhatxotic Engine          (c) Mhatxotic Design, All Rights Reserved ## **
** ######################################################################### **
** ## This module handles the keyboard and controller input.              ## **
** ######################################################################### **
** ========================================================================= */
#pragma once                           // Only one incursion allowed
/* ------------------------------------------------------------------------- */
namespace IInput {                     // Start of private module namespace
/* -- Dependencies --------------------------------------------------------- */
using namespace ICollector::P;         using namespace IConsole::P;
using namespace ICVar::P;              using namespace ICVarDef::P;
using namespace ICVarLib::P;           using namespace IEvtMain::P;
using namespace IEvtWin::P;            using namespace IFboCore::P;
using namespace IFlags;                using namespace IGlFW::P;
using namespace IGlFWUtil::P;          using namespace IIdent::P;
using namespace ILog::P;               using namespace ILuaFunc::P;
using namespace IStd::P;               using namespace IString::P;
using namespace ISysUtil::P;           using namespace IUtf;
using namespace IUtil::P;              using namespace Lib::OS::GlFW;
/* ------------------------------------------------------------------------- */
namespace P {                          // Start of public module namespace
/* == Input flags ========================================================== */
BUILD_FLAGS(Input,
  /* ----------------------------------------------------------------------- */
  // No flags                          Mouse cursor is enabled?
  IF_NONE                   {Flag[0]}, IF_CURSOR                 {Flag[1]},
  // Full-screen toggler enabled?      Mouse cursor has focus?
  IF_FSTOGGLER              {Flag[2]}, IF_MOUSEFOCUS             {Flag[3]}
);/* -- Axis class --------------------------------------------------------- */
class JoyAxisInfo
{ /* -------------------------------------------------------------- */ private:
  const int        iId;                // Axis unique identifier
  float            fDeadZoneR;         // Reverse deadzone threshold
  float            fDeadZoneF;         // Forward deadzone threshold
  float            fUnbuffered;        // Current unbuffered axis press state
  int              iBuffered;          // Current buffered axis press state
  /* -- Get axis identifier ---------------------------------------- */ public:
  int AxisGetId(void) const { return iId; }
  /* -- Get reverse deadzone value ----------------------------------------- */
  float AxisGetReverseDeadZone(void) const { return fDeadZoneR; }
  /* -- Get forward deadzone value ----------------------------------------- */
  float AxisGetForwardDeadZone(void) const { return fDeadZoneF; }
  /* -- Set reverse deadzone value ----------------------------------------- */
  void AxisSetReverseDeadZone(const float fDZ) { fDeadZoneR = -fDZ; }
  /* -- Set forward deadzone value ----------------------------------------- */
  void AxisSetForwardDeadZone(const float fDZ) { fDeadZoneF = fDZ; }
  /* -- Get unbuffered state ----------------------------------------------- */
  float AxisGetUnbufferedState(void) const { return fUnbuffered; }
  /* -- Get buffered state ------------------------------------------------- */
  int AxisGetBufferedState(void) const { return iBuffered; }
  /* -- Clear button state ------------------------------------------------- */
  void AxisClearState(void) { fUnbuffered = 0.0f; iBuffered = GLFW_RELEASE; }
  /* -- Set axis state ----------------------------------------------------- */
  void AxisSetState(const float*const fpData)
  { // Get the axis reading and if it's moving negatively?
    fUnbuffered = fpData[AxisGetId()];
    if(fUnbuffered < fDeadZoneR)
    { // Released or already in reverse position?
      if(iBuffered <= GLFW_RELEASE)
      { // Set to -GLFW_REPEAT if currently -GLFW_PRESSED or
        //        -GLFW_PRESSED if currently GLFW_RELEASE
        if(iBuffered > -GLFW_REPEAT) --iBuffered;
        // State changed
        return;
      }
    } // Moving positively?
    else if(fUnbuffered > fDeadZoneF)
    { // Released or already in forward position?
      if(iBuffered >= GLFW_RELEASE)
      { // Set to GLFW_REPEAT if currentl GLFW_PRESSED or
        //        GLFW_PRESSED if currently GLFW_RELEASE
        if(iBuffered < GLFW_REPEAT) ++iBuffered;
        // State changed
        return;
      }
    } // Nothing pressed so reset buffered counter
    iBuffered = GLFW_RELEASE;
  }
  /* -- Constructor with unique id ----------------------------------------- */
  explicit JoyAxisInfo(const int iNId) :
    /* -- Initialisers ----------------------------------------------------- */
    iId(iNId),                         // Set unique id
    fDeadZoneR(-0.25f),                // Set default reverse deadzone
    fDeadZoneF(0.25f),                 // Set default forward deadzone
    fUnbuffered(0.0f),                 // Set default unbuffered state
    iBuffered(GLFW_RELEASE)            // Set default state
    /* -- No code ---------------------------------------------------------- */
    { }
};/* -- Axis data list type ------------------------------------------------ */
typedef array<JoyAxisInfo, GLFW_GAMEPAD_AXIS_LAST+1> JoyAxisList;
/* -- Button class --------------------------------------------------------- */
class JoyButtonInfo
{ /* -- Private variables ----------------------------------------- */ private:
  const int        iId;                // Button unique identifier
  unsigned int     uiUnbuffered,       // Current unbuffered butn press state
                   uiBuffered;         // Current buffered butn press state
  /* -- Get button id ---------------------------------------------- */ public:
  int ButtonGetId(void) const { return iId; }
  /* -- Get unbuffered state (GLFW_RELEASE or GLFW_PRESS) ------------------ */
  unsigned int ButtonGetUnbufferedState(void) const { return uiUnbuffered; }
  /* -- Get buffered state (GLFW_RELEASE, GLFW_PRESS or GLFW_REPEAT) ------- */
  unsigned int ButtonGetBufferedState(void) const { return uiBuffered; }
  /* -- Clear button state ------------------------------------------------- */
  void ButtonClearState(void) { uiUnbuffered = uiBuffered = GLFW_RELEASE; }
  /* -- Set button state --------------------------------------------------- */
  void ButtonSetState(const unsigned char*const ucpState)
  { // Save unbuffered state and compare it
    uiUnbuffered = static_cast<unsigned int>(ucpState[ButtonGetId()]);
    switch(uiUnbuffered)
    { // Button is released?
      case GLFW_RELEASE:
        // Reset button state if not released (0 = released)
        if(uiBuffered > GLFW_RELEASE) uiBuffered = GLFW_RELEASE;
        // Done
        return;
      // Button is pressed? Increase button state (1=pressed and 2=held)
      case GLFW_PRESS:
        // Set GLFW_PRESSED if GLFW_RELEASED or
        //     GLFW_REPEAT if GLFW_PRESSED.
        if(uiBuffered < GLFW_REPEAT) ++uiBuffered;
        // Done
        return;
      // Shouldn't get here
      default: break;
    } // Reset to released
    uiBuffered = GLFW_RELEASE;
  }
  /* -- Constructor with unique id ----------------------------------------- */
  explicit JoyButtonInfo(const int iNId) :
    /* -- Initialisers ----------------------------------------------------- */
    iId(iNId),                         // Set unique id
    uiUnbuffered(GLFW_RELEASE),        // Set default unbuffered state
    uiBuffered(GLFW_RELEASE)           // Set default buffered state
    /* -- No code ---------------------------------------------------------- */
    { }
};/* -- Button data list --------------------------------------------------- */
typedef array<JoyButtonInfo, GLFW_GAMEPAD_BUTTON_LAST+1> JoyButtonList;
/* -- Joystick type typedef ------------------------------------------------ */
BUILD_FLAGS(Joy,
  /* ----------------------------------------------------------------------- */
  // No flags                          Joystick is connnected?
  JF_NONE                   {Flag[0]}, JF_CONNECTED              {Flag[1]},
  // Joystick is actually a gamepad
  JF_GAMEPAD                {Flag[2]}
);/* -- Joystick class ----------------------------------------------------- */
class JoyInfo :
  /* -- Derived classes ---------------------------------------------------- */
  public JoyFlags,                     // Joystick flags
  private JoyAxisList,                 // Joystick axises data
  private JoyButtonList,               // Joystick buttons data
  public Ident                         // Joystick identifier
{ /* -------------------------------------------------------------- */ private:
  const int      iId;                  // Unique identifier of this
  /* -- Unbuffered and buffered axis data struct --------------------------- */
  size_t         stAxises;             // Axis count
  size_t         stButtons;            // Button count
  /* -- Return joystick id ----------------------------------------- */ public:
  int GetId(void) const { return iId; }
  /* -- Get button list data ----------------------------------------------- */
  JoyButtonList &GetButtonList(void)
    { return static_cast<JoyButtonList&>(*this); }
  const JoyButtonList &GetConstButtonList(void) const
    { return static_cast<const JoyButtonList&>(*this); }
  /* -- Clear button state ------------------------------------------------- */
  void ClearButtonState(void)
    { StdForEach(par_unseq, GetButtonList().begin(), GetButtonList().end(),
        [](JoyButtonInfo& jbiItem) { jbiItem.ButtonClearState(); }); }
  /* -- Get button count ------------------------------------------------- */
  size_t GetButtonCount(void) const { return stButtons; }
  /* -- Refresh button data ---------------------------------------------- */
  void RefreshButtons(void)
  { // Get joystick buttons and if found?
    int iButtons;
    if(const unsigned char*const cpData =
      GlFWGetJoystickButtons(GetId(), iButtons))
    { // Clamp count to number we support on the stack
      stButtons = UtilMinimum(static_cast<size_t>(iButtons),
        GetConstButtonList().size());
      // Return if no buttons
      if(!stButtons) return;
      // Enumate state for each joy button
      for(size_t stBId = 0; stBId < stButtons; ++stBId)
        GetButtonList()[stBId].ButtonSetState(cpData);
    }
  }
  /* -- Get axis list data ------------------------------------------------- */
  JoyAxisList &GetAxisList(void)
    { return static_cast<JoyAxisList&>(*this); }
  const JoyAxisList &GetConstAxisList(void) const
    { return static_cast<const JoyAxisList&>(*this); }
  /* -- Clear axis state ------------------------------------------------- */
  void ClearAxisState(void)
    { StdForEach(par_unseq, GetAxisList().begin(), GetAxisList().end(),
        [](JoyAxisInfo &jaiItem) { jaiItem.AxisClearState(); }); }
  /* -- Get axis count --------------------------------------------------- */
  size_t GetAxisCount(void) const { return stAxises; }
  /* -- Refresh axis data for this --------------------------------------- */
  void RefreshAxes(void)
  { // Get axis data and if succeeded?
    int iAxises;
    if(const float*const fpData = GlFWGetJoystickAxes(GetId(), iAxises))
    { // Clamp count to number we support on the stack
      stAxises = UtilMinimum(static_cast<size_t>(iAxises),
        GetConstAxisList().size());
      // Return if no axis
      if(!stAxises) return;
      // Enumate state for each joystick axis
      for(size_t stAId = 0; stAId < stAxises; ++stAId)
        GetAxisList()[stAId].AxisSetState(fpData);
    }
  }
  /* -- Refresh data ----------------------------------------------------- */
  void RefreshData(void) { RefreshAxes(); RefreshButtons(); }
  /* -- Return type of joystick ------------------------------------------ */
  const char *GetGamepadOrJoystickString(void) const
    { return FlagIsSetTwo(JF_GAMEPAD, "gamepad", "joystick"); }
  /* -- Joystick is connected? ----------------------------------- */ public:
  bool IsConnected(void) const { return FlagIsSet(JF_CONNECTED); }
  /* -- Joystick is disconnected? ---------------------------------------- */
  bool IsDisconnected(void) const { return !IsConnected(); }
  /* -- Clear button state if connected ---------------------------------- */
  void ClearButtonStateIfConnected(void)
    { if(IsConnected()) ClearButtonState(); }
  /* -- Clear buttons and axis state ------------------------------------- */
  void ClearState(void) { ClearAxisState(); ClearButtonState(); }
  /* -- Refresh data if connected ---------------------------------------- */
  void RefreshDataIfConnected() { if(IsConnected()) RefreshData(); }
  /* -- Get button state ------------------------------------------------- */
  unsigned int GetButtonState(const size_t stButtonId) const
    { return GetConstButtonList()[stButtonId].ButtonGetBufferedState(); }
  /* -- Get axis state --------------------------------------------------- */
  int GetAxisState(const size_t stAxisId) const
    { return GetConstAxisList()[stAxisId].AxisGetBufferedState(); }
  /* -- Get unbuffered axis state ---------------------------------------- */
  float GetUnbufferedAxisState(const size_t stAxisId) const
    { return GetConstAxisList()[stAxisId].AxisGetUnbufferedState(); }
  /* -- Get axis state --------------------------------------------------- */
  void SetAxisForwardDeadZone(const size_t stAxisId, const float fDZ)
    { GetAxisList()[stAxisId].AxisSetForwardDeadZone(fDZ); }
  void SetAxisReverseDeadZone(const size_t stAxisId, const float fDZ)
    { GetAxisList()[stAxisId].AxisSetReverseDeadZone(fDZ); }
  void SetAxisDeadZones(const size_t stAxisId,
    const float fFDZ, const float fRDZ)
  { // Get axis data and set the new values
    JoyAxisInfo &jaiItem = GetAxisList()[stAxisId];
    jaiItem.AxisSetForwardDeadZone(fFDZ);
    jaiItem.AxisSetReverseDeadZone(fRDZ);
  }
  /* -- Set default positive deadzone -------------------------------------- */
  void SetReverseDeadZone(const float fDZ)
    { StdForEach(par_unseq, GetAxisList().begin(), GetAxisList().end(),
        [fDZ](JoyAxisInfo &jaiItem)
          { jaiItem.AxisSetReverseDeadZone(fDZ); }); }
  /* -- Set default positive deadzone -------------------------------------- */
  void SetForwardDeadZone(const float fDZ)
    { StdForEach(par_unseq, GetAxisList().begin(), GetAxisList().end(),
        [fDZ](JoyAxisInfo &jaiItem)
          { jaiItem.AxisSetForwardDeadZone(fDZ); }); }
  /* -- Get/Set gamepad status ------------------------------------------- */
  void Connect(void)
  { // Now connected
    FlagSet(JF_CONNECTED);
    // Set gamepad status
    FlagSetOrClear(JF_GAMEPAD, glfwJoystickIsGamepad(GetId()));
    // Get joystick name and if it's not null?
    if(const char*const cpName = GlFWGetJoystickName(GetId()))
    { // If monitor name is blank return blank name
      if(*cpName) IdentSet(cpName);
      // Return blank name
      else IdentSet(cCommon->Unspec());
    } // Return null name
    else IdentSet(cCommon->Null());
    // Refresh joystick data
    RefreshData();
    // We gained this joystick
    cLog->LogInfoExSafe("Input detected $ '$' (I:$;B:$;A:$).",
      GetGamepadOrJoystickString(), IdentGet(), GetId(), GetButtonCount(),
      GetAxisCount());
    // Return if it's not a gamepad
    if(FlagIsClear(JF_GAMEPAD)) return;
    // Report name and identifier
    if(const char*const cpN = glfwGetGamepadName(GetId()))
      cLog->LogDebugExSafe("- Gamepad Name: $.", cpN);
    if(const char*const cpG = glfwGetJoystickGUID(GetId()))
      cLog->LogDebugExSafe("- Gamepad Identifier: $.", cpG);
  }
  /* -- Reset data ------------------------------------------------------- */
  void Disconnect(void)
  { // Ignore if already disconnected
    if(IsDisconnected()) return;
    // No longer connected
    FlagClear(JF_CONNECTED);
    // We lost the specified joystick
    cLog->LogInfoExSafe("Input disconnected $ '$' (I:$).",
      GetGamepadOrJoystickString(), IdentGet(), GetId());
  }
  /* -- Detect joystick ---------------------------------------------------- */
  bool IsPresent(void) { return glfwJoystickPresent(GetId()); }
  /* -- Constructor -------------------------------------------------------- */
  explicit JoyInfo(const int iNId) :
    /* -- Initialisers ----------------------------------------------------- */
    JoyFlags(JF_NONE),                 // Set no flags
    /* -- Initialise joystick axises --------------------------------------- */
#define JAI(x) JoyAxisInfo{ GLFW_GAMEPAD_AXIS_ ## x }
    /* --------------------------------------------------------------------- */
    JoyAxisList{ {                     // Initialise joystick axises ids
      /* ------------------------------------------------------------------- */
      JAI(LEFT_X),  JAI(LEFT_Y),       JAI(RIGHT_X),
      JAI(RIGHT_Y), JAI(LEFT_TRIGGER), JAI(RIGHT_TRIGGER)
      /* ------------------------------------------------------------------- */
    } },                               // End of joystic axises ids init
    /* --------------------------------------------------------------------- */
#undef JAI                             // Done with this macro
    /* -- Initialise joystick buttons -------------------------------------- */
#define JBL(x) JoyButtonInfo{ GLFW_GAMEPAD_BUTTON_ ## x }
    /* --------------------------------------------------------------------- */
    JoyButtonList{ {                   // Initialise joystick buttons ids
      /* ------------------------------------------------------------------- */
      JBL(A),           JBL(B),            JBL(X),           JBL(Y),
      JBL(LEFT_BUMPER), JBL(RIGHT_BUMPER), JBL(BACK),        JBL(START),
      JBL(GUIDE),       JBL(LEFT_THUMB),   JBL(RIGHT_THUMB), JBL(DPAD_UP),
      JBL(DPAD_RIGHT),  JBL(DPAD_DOWN),    JBL(DPAD_LEFT)
      /* ------------------------------------------------------------------- */
    } },                               // End of joystick button ids init
    /* --------------------------------------------------------------------- */
#undef JBL                             // Done with this macro
    /* -- Other initialisers ----------------------------------------------- */
    iId(iNId),                         // Set unique joystick id
    stAxises(0),                       // Set no axies
    stButtons(0)                       // Set no buttons
    /* -- No code ---------------------------------------------------------- */
    { }
};/* -- Joystick state typedefs -------------------------------------------- */
typedef array<JoyInfo, GLFW_JOYSTICK_LAST+1> JoyList; // Actual joystick data
typedef JoyList::const_iterator JoyListIt; // Iterator for vector of joys
/* ========================================================================= */
enum JoyStatus : int                   // Joystick init status
{ /* ----------------------------------------------------------------------- */
  JOY_DETECT = -1,                     // Automatically detect at startup
  JOY_DISABLE,                         // Joystick polling is disabled
  JOY_ENABLE                           // Joystick polling is enabled
};/* ----------------------------------------------------------------------- */
/* == Input class ========================================================== */
static class Input final :             // Handles keyboard, mouse & controllers
  /* -- Base classes ------------------------------------------------------- */
  private IHelper,                     // Initialsation helper
  public InputFlags,                   // Input configuration settings
  private JoyList,                     // Joystick data
  private EvtMain::RegVec              // Events list to register
{ /* -- Console ------------------------------------------------------------ */
  int              iConsoleKey1,       // First console key
                   iConsoleKey2;       // Second console key
  /* -- Events ----------------------------------------------------- */ public:
  LuaFunc          lfOnMouseClick,     // Mouse button clicked
                   lfOnMouseMove,      // Mouse cursor moved
                   lfOnMouseScroll,    // Mouse scroll wheel moved
                   lfOnMouseFocus,     // Mouse focus changed from window
                   lfOnKey,            // Unfiltered key pressed
                   lfOnChar,           // Filtered key pressed
                   lfOnDragDrop,       // Drag and dropped files
                   lfOnJoyState;       // Joystick connection event
  /* -------------------------------------------------------------- */ private:
  JoyStatus        jsStatus;           // Joystick detection/polling state
  /* ----------------------------------------------------------------------- */
  int              iWinWidth,          // Actual window width
                   iWinHeight,         // Actual window height
                   iWinWidthD2,        // Actual half window width
                   iWinHeightD2;       // Actual half window height
  /* -- Set cursor position ------------------------------------------------ */
  void OnSetCurPos(const EvtMainEvent &emeEvent)
  { // Get reference to actual arguments vector
    const EvtMainArgs &emaArgs = emeEvent.aArgs;
    // This function is called on an event sent by cEvtMain->Add. It it assume
    // to send only two parameters which is the newly requested X and Y
    // position. Glfw says that SetCursorPos should only be used in the Window
    // thread, so this is why it can't be an on-demand call.
    // More information:- https://www.glfw.org/docs/3.1/group__input.html
    // Calculate new position based on main fbo matrix.
    const float
      fAdjX = (emaArgs[0].f - cFboCore->fboMain.ffcStage.GetCoLeft()) /
        cFboCore->fboMain.GetCoRight() * GetWindowWidth(),
      fAdjY = (emaArgs[1].f - cFboCore->fboMain.ffcStage.GetCoTop()) /
        cFboCore->fboMain.GetCoBottom() * GetWindowHeight(),
      // Clamp the new position to the window bounds.
      fNewX = UtilClamp(fAdjX, 0.0f, cFboCore->fboMain.GetCoRight() - 1.0f),
      fNewY = UtilClamp(fAdjY, 0.0f, cFboCore->fboMain.GetCoBottom() - 1.0f);
    // Now translate that position back into the actual window cursor pos.
    cGlFW->WinSetCursorPos(static_cast<double>(fNewX),
                           static_cast<double>(fNewY));
  }
  /* -- Filtered key pressed ----------------------------------------------- */
  void OnFilteredKey(const EvtMainEvent &emeEvent)
  { // Get key pressed
    const unsigned int uiKey = emeEvent.aArgs[1].ui;
    // If console is enabled, send it to console instead
    if(cConsole->IsVisible()) return cConsole->OnCharPress(uiKey);
    // Else send the key to lua callbacks
    lfOnChar.LuaFuncDispatch(uiKey);
  }
  /* -- Mouse went inside the window --------------------------------------- */
  void OnMouseFocus(const EvtMainEvent &emeEvent)
  { // Get and check state
    const int iState = emeEvent.aArgs[1].i;
    switch(iState)
    { // Mouse is in the window? Set mouse in window flag
      case GLFW_TRUE: FlagSet(IF_MOUSEFOCUS); break;
      // Mouse is not in the window? Clear mouse in window flag
      case GLFW_FALSE: FlagClear(IF_MOUSEFOCUS); break;
      // Unknown state?
      default:
        // Log the bad mouse focus state and return
        cLog->LogWarningExSafe(
          "Input ignored bad mouse focus state $<$$>!",
          iState, hex, iState);
        // Don't dispatch an event
        return;
    } // Dispatch event to lua scripts
    return lfOnMouseFocus.LuaFuncDispatch(iState);
  }
  /* -- Mouse wheel scroll ------------------------------------------------- */
  void OnMouseWheel(const EvtMainEvent &emeEvent)
  { // Get reference to actual arguments vector
    const EvtMainArgs &emaArgs = emeEvent.aArgs;
    // Get movements
    const double dX = emaArgs[1].d, dY = emaArgs[2].d;
    // If console is enabled and ctrl not pressed? Send it to console instead
    if(cConsole->IsVisible() &&
       cGlFW->WinGetKey(GLFW_KEY_LEFT_CONTROL) == GLFW_RELEASE &&
       cGlFW->WinGetKey(GLFW_KEY_RIGHT_CONTROL) == GLFW_RELEASE)
      return cConGraphics->OnMouseWheel(dX, dY);
    // Set event to lua callbacks
    lfOnMouseScroll.LuaFuncDispatch(dX, dY);
  }
  /* -- Mouse button clicked ----------------------------------------------- */
  void OnMouseClick(const EvtMainEvent &emeEvent)
  { // Get reference to actual arguments vector
    const EvtMainArgs &emaArgs = emeEvent.aArgs;
    // Set event to lua callbacks
    lfOnMouseClick.LuaFuncDispatch(emaArgs[1].i, emaArgs[2].i, emaArgs[3].i);
  }
  /* -- Mouse button clicked ----------------------------------------------- */
  void OnMouseMove(const EvtMainEvent &emeEvent)
  { // Get reference to actual arguments vector
    const EvtMainArgs &emaArgs = emeEvent.aArgs;
    // Recalculate cursor position based on framebuffer size and send the
    // new co-ordinates to the lua callback handler
    lfOnMouseMove.LuaFuncDispatch(
      static_cast<double>(cFboCore->fboMain.ffcStage.GetCoLeft()) +
        ((emaArgs[1].d / GetWindowWidth()) *
        static_cast<double>(cFboCore->fboMain.GetCoRight())),
      static_cast<double>(cFboCore->fboMain.ffcStage.GetCoTop()) +
        ((emaArgs[2].d / GetWindowHeight()) *
        static_cast<double>(cFboCore->fboMain.GetCoBottom())));
  }
  /* -- Unfiltered key pressed --------------------------------------------- */
  void OnKeyPress(const EvtMainEvent &emeEvent)
  { // Get reference to actual arguments vector
    const EvtMainArgs &emaArgs = emeEvent.aArgs;
    // Get key code and ignore if unknown key
    const int iKey = emaArgs[1].i;
    if(iKey == GLFW_KEY_UNKNOWN) return;
    // Get modifier and actions and if Alt+Enter was pressed or released and
    // full-screen toggler enabled?
    const int iState = emaArgs[3].i, iMod = emaArgs[4].i;
    // Check for full-screen/window toggle press
    if(iKey == GLFW_KEY_ENTER &&       // If the ENTER key was pressed? and
       iMod == GLFW_MOD_ALT &&         // ...ALT key is held? and
       FlagIsSet(IF_FSTOGGLER))        // ...FullScreen key enabled?
    { // Return if keys not released
      if(iState != GLFW_RELEASE) return;
      // Get inverted full-screen setting
      const bool bFullScreen = !cCVars->GetInternal<bool>(VID_FS);
      // Set full screen setting depending on current state
      cCVars->SetInternal<bool>(VID_FS, bFullScreen);
      // Send command to toggle full-screen
      cEvtWin->AddUnblock(EWC_WIN_TOGGLE_FS, bFullScreen);
      // We handled this key so do not dispatch it to scripts
      return;
    } // Console is enabled?
    if(cConsole->IsVisible())
    { // Add normal key pressed. Since GLFW inconveniently gives us 3 int
      // parameters, we need to pack 2 ints together. Luckily, GLFW_RELEASE etc
      // is only 8-bit, we'll pack the modifiers with this value.
      cConGraphics->OnKeyPress(iKey, iState, iMod);
      // We handled this key so do not dispatch it to scripts
      return;
    } // Ignore the ESCAPE generated from hiding the console
    if(cConsole->FlagIsSet(CF_IGNOREESC) &&
       iState == GLFW_RELEASE && !iMod && iKey == GLFW_KEY_ESCAPE)
    { // Remove flag
      cConsole->FlagClear(CF_IGNOREESC);
      // We handled this key so do not dispatch it to scripts
      return;
    } // If key was pressed and is console key and no modifiers are pressed?
    if(iState == GLFW_PRESS && !iMod &&
      (iKey == iConsoleKey1 || iKey == iConsoleKey2))
    { // Set console enabled and if enabled? Ignore first key as registering
      // OnCharPress will trigger this keystroke and print it out in the
      // console.
      if(cConGraphics->SetVisible(true)) cConsole->FlagSet(CF_IGNOREKEY);
      // We handled this key so do not dispatch it to scripts
      return;
    } // Send lua event for key
    lfOnKey.LuaFuncDispatch(iKey, iState, iMod, emaArgs[2].i);
  }
  /* -- Files dragged and dropped on window--------------------------------- */
  void OnDragDrop(const EvtMainEvent&)
  { // Get files and return if empty
    StrVector &vFiles = cGlFW->WinGetFiles();
    if(vFiles.empty()) return;
    // Send off the event to lua callbacks
    lfOnDragDrop.LuaFuncDispatch(vFiles);
    // Clear the list
    vFiles.clear();
    vFiles.shrink_to_fit();
  }
  /* -- Joystick state changed --------------------------------------------- */
  void OnJoyState(const EvtMainEvent &emeEvent)
  { // Get reference to actual arguments vector
    const EvtMainArgs &emaArgs = emeEvent.aArgs;
    // Get joystick id as int
    const int iId = emaArgs[0].i;
    // What happened to the joystick?
    switch(const int iState = emaArgs[1].i)
    { // Connected? Setup joystick and return
      case GLFW_CONNECTED:
        return SetupJoystickAndDispatch(static_cast<size_t>(iId));
      // Disconnected?
      case GLFW_DISCONNECTED:
        return ClearJoystickAndDispatch(static_cast<size_t>(iId));
      // Invalid code?
      default:
        // Log the bad joystick state and return
        cLog->LogWarningExSafe("Input ignored bad joystick state ($ = $$)!",
          iId, hex, iState);
        // No need to dispatch any events
        return;
    }
  }
  /* -- Window past event--------------------------------------------------- */
  void OnWindowPaste(const EvtMainEvent&)
  { // Get text in clipboard
    UtfDecoder utfString{ cGlFW->WinGetClipboard() };
    // For each character, ddd the character to queue if valid
    while(const unsigned int uiChar = utfString.Next())
      if(uiChar >= 32) cConsole->OnCharPress(uiChar);
  }
  /* -- Update half window ------------------------------------------------- */
  void UpdateWindowSizeD2(void) { iWinWidthD2 = GetWindowWidth()/2;
                                  iWinHeightD2 = GetWindowHeight()/2; }
  /* -- Event handler for 'glfwSetJoystickCallback' ------------------------ */
  static void OnGamePad(int iJId, int iEvent)
    { cEvtMain->Add(EMC_INP_JOY_STATE, iJId, iEvent); }
  /* -- Commit cursor visibility now ------------------------------- */ public:
  void CommitCursorNow(void) { cGlFW->WinSetCursor(FlagIsSet(IF_CURSOR)); }
  /* -- Commit cursor visibility ------------------------------------------- */
  void CommitCursor(void)
    { cEvtWin->AddUnblock(EWC_WIN_CURSETVIS, FlagIsSet(IF_CURSOR)); }
  /* -- Set visibility of mouse cursor ------------------------------------- */
  void SetCursor(const bool bState)
  { // Set member var incase window needs to re-init so we can restore the
    // cursor state
    FlagSetOrClear(IF_CURSOR, bState);
    // Request to set cursor visibility
    CommitCursor();
  }
  /* -- Get button list data ----------------------------------------------- */
  JoyList &GetJoyList(void)
    { return static_cast<JoyList&>(*this); }
  const JoyList &GetConstJoyList(void) const
    { return static_cast<const JoyList&>(*this); }
  /* -- Get window size ---------------------------------------------------- */
  int GetWindowWidth(void) const { return iWinWidth; }
  int GetWindowHeight(void) const { return iWinHeight; }
  /* -- Update window size from actual glfw window ------------------------- */
  void UpdateWindowSize(void)
  { // Get new window size
    cGlFW->WinGetSize(iWinWidth, iWinHeight);
    // Update half window size
    UpdateWindowSizeD2();
  }
  /* -- Update window size (from display) ---------------------------------- */
  void SetWindowSize(const int iX, const int iY)
  { // Update new size
    iWinWidth = iX;
    iWinHeight = iY;
    // Update half size
    UpdateWindowSizeD2();
  }
  /* -- Request input state ------------------------------------------------ */
  void RequestMousePosition(void) const
    { cEvtWin->AddUnblock(EWC_WIN_CURPOSGET); }
  /* -- Forcefully move the cursor ----------------------------------------- */
  void SetCursorPos(const double dX, const double dY)
    { cEvtMain->Add(EMC_INP_SET_CUR_POS, dX, dY); }
  void SetCursorCentre(void)
    { SetCursorPos(static_cast<double>(iWinWidthD2),
                   static_cast<double>(iWinHeightD2)); }
  /* -- Joystick main tick ------------------------------------------------- */
  void PollJoysticks(void)
  { // If joystick enabled? Enumerate joysticks and refresh data
    if(jsStatus != JOY_DISABLE)
      for(JoyInfo &jsData : GetJoyList())
        jsData.RefreshDataIfConnected();
  }
  bool JoystickExists(const size_t stId)
    { return GetJoyData(stId).IsConnected(); }
  /* -- Dispatch connected event to lua ------------------------------------ */
  void DispatchLuaEvent(const size_t stJoystickId, const bool bConnected)
    { lfOnJoyState.LuaFuncDispatch(static_cast<lua_Integer>(stJoystickId),
        bConnected); }
  /* -- DeInitialise a joystick -------------------------------------------- */
  void ClearJoystickAndDispatch(const size_t stJoystickId)
  { // Get joystick data and ign ore if joystick wasn't originally connected
    JoyInfo &jsData = GetJoyData(stJoystickId);
    if(jsData.IsDisconnected()) return;
    // Send lua event to let guest know joystick was disconnected
    DispatchLuaEvent(stJoystickId, false);
    // Clear joystick, axis and button data
    jsData.Disconnect();
  }
  /* -- Initialise a new joystick ------------------------------------------ */
  void SetupJoystickAndDispatch(const size_t stJoystickId)
  { // Detect if is gamepad?
    GetJoyData(stJoystickId).Connect();
    // Send lua event to let guest know joystick was connected and return
    DispatchLuaEvent(stJoystickId, true);
  }
  /* -- Return a joystick is present? -------------------------------------- */
  void AutoDetectJoystick(void)
  { // Joysticks detected count
    size_t stCount = 0;
    // Enumerate joysticks...
    for(JoyInfo &jsData : GetJoyList())
      // If joystick is present?
      if(jsData.IsPresent())
      { // Send event that the joystick was connected
        cEvtMain->Add(EMC_INP_JOY_STATE, jsData.GetId(), GLFW_CONNECTED);
        ++stCount;
      } // Send event that the joystick was disconnected
      else cEvtMain->Add(EMC_INP_JOY_STATE, jsData.GetId(), GLFW_DISCONNECTED);
    // If we did not find joysticks? Disable polling
    if(!stCount)
    { // If smart detection was enabled?
      if(jsStatus == JOY_DETECT)
      { // Display joystick polling to save on CPU resources
        jsStatus = JOY_DISABLE;
        // Log result
        cLog->LogInfoSafe(
          "Input disabling joystick polling as no devices are detected.");
      } // Done
      return;
    } // Poll joysticks
    PollJoysticks();
    // Done if smart detection was not enabled
    if(jsStatus != JOY_DETECT) return;
    // Joystick polling set to enabled
    jsStatus = JOY_ENABLE;
    // Log result
    cLog->LogInfoExSafe(
      "Input enabling joystick polling as $ devices are detected.", stCount);
  }
  // -- CVar callback to toggle raw mouse ---------------------------------- */
  CVarReturn SetRawMouseEnabled(const bool bState)
  { // Send request to set raw mouse motion state if enabled
    if(IHIsInitialised()) cEvtWin->AddUnblock(EWC_WIN_SETRAWMOUSE, bState);
    // CVar allowed to be set
    return ACCEPT;
  }
  // -- CVar callback to toggle sticky keys -------------------------------- */
  CVarReturn SetStickyKeyEnabled(const bool bState)
  { // Send request to set sticky keys state if enabled
    if(IHIsInitialised()) cEvtWin->AddUnblock(EWC_WIN_SETSTKKEYS, bState);
    // CVar allowed to be set
    return ACCEPT;
  }
  // -- CVar callback to toggle sticky mouse ------------------------------- */
  CVarReturn SetStickyMouseEnabled(const bool bState)
  { // Send request to set sticky mouse if enabled
    if(IHIsInitialised()) cEvtWin->AddUnblock(EWC_WIN_SETSTKMOUSE, bState);
    // CVar allowed to be set
    return ACCEPT;
  }
  // -- Initialise joysticks ----------------------------------------------- */
  void BeginDetection(void)
  { // Check current user setting
    switch(jsStatus)
    { // Set to detection mode or enable? Redetect joysticks
      case JOY_DETECT: case JOY_ENABLE: AutoDetectJoystick(); break;
      // Disable it? Set to disabled and clear joystick states
      case JOY_DISABLE: ClearJoystickButtons(); break;
      // Invalid value
      default: break;
    }
  }
  // -- CVar callback to toggling joystick polling ------------------------- */
  CVarReturn SetJoystickEnabled(const JoyStatus jsNewStatus)
    { return CVarSimpleSetIntNLGE(jsStatus, jsNewStatus,
        JOY_DETECT, JOY_ENABLE); }
  /* -- Clear joystick state ----------------------------------------------- */
  void ClearJoystickButtons(void)
    { StdForEach(par_unseq, GetJoyList().begin(), GetJoyList().end(),
        [](JoyInfo &jsData) { jsData.ClearButtonStateIfConnected(); }); }
  /* -- Clear keyboard, mouse and joystick states -------------------------- */
  void ClearJoyStates(void) { ClearJoystickButtons(); }
  /* -- Return joystick data ----------------------------------------------- */
  JoyInfo &GetJoyData(const size_t stId) { return GetJoyList()[stId]; }
  /* -- Return joysticks count --------------------------------------------- */
  size_t GetJoyCount(void) const { return GetConstJoyList().size(); }
  /* -- Disable input events ----------------------------------------------- */
  void DisableInputEvents(void) { cEvtMain->UnregisterEx(*this); }
  /* -- Enable input events ------------------------------------------------ */
  void EnableInputEvents(void) { cEvtMain->RegisterEx(*this); }
  /* -- Init --------------------------------------------------------------- */
  void Init(void)
  { // if window not available? This should never happen but we will put
    // this here just incase. The subsequent operations are pointless without
    // a valid GLFW window. Log that initialisation is being skipped and return
    // if window is not available.
    if(!cGlFW->WinIsAvailable())
      return cLog->LogWarningSafe(
       "Input initialisation skipped with no window available!");
    // Class initialised
    IHInitialise();
    // Log progress
    cLog->LogDebugSafe("Input interface is initialising...");
    // Init input engine events
    EnableInputEvents();
    // Init input settings
    SetRawMouseEnabled(cCVars->GetInternal<bool>(INP_RAWMOUSE));
    SetStickyKeyEnabled(cCVars->GetInternal<bool>(INP_STICKYKEY));
    SetStickyMouseEnabled(cCVars->GetInternal<bool>(INP_STICKYMOUSE));
    // Set/Restore cursor state
    SetCursor(FlagIsSet(IF_CURSOR));
    // Register joystick callback
    glfwSetJoystickCallback(OnGamePad);
    // Log progress
    cLog->LogDebugExSafe("Input interface initialised (R:$;J:$).",
      StrFromBoolTF(GlFWIsRawMouseMotionSupported()), GetJoyCount());
  }
  /* -- DeInit ------------------------------------------------------------- */
  void DeInit(void)
  { // Ignore if class not initialised
    if(IHNotDeInitialise()) return;
    // Log progress
    cLog->LogDebugSafe("Input interface deinitialising...");
    // Unregister joystick callback
    glfwSetJoystickCallback(nullptr);
    // Deinit engine events in the order they were registered
    DisableInputEvents();
    // Log progress
    cLog->LogDebugSafe("Input interface deinitialised.");
  }
  /* -- Constructor -------------------------------------------------------- */
  Input(void) :
    /* -- Initialisers ----------------------------------------------------- */
    IHelper(__FUNCTION__),             // Init initialisation helper class
    InputFlags(IF_NONE),               // No flags set initially
    /* -- Init joysticks --------------------------------------------------- */
    JoyList{ { JoyInfo(GLFW_JOYSTICK_1),  JoyInfo(GLFW_JOYSTICK_2),
               JoyInfo(GLFW_JOYSTICK_3),  JoyInfo(GLFW_JOYSTICK_4),
               JoyInfo(GLFW_JOYSTICK_5),  JoyInfo(GLFW_JOYSTICK_6),
               JoyInfo(GLFW_JOYSTICK_7),  JoyInfo(GLFW_JOYSTICK_8),
               JoyInfo(GLFW_JOYSTICK_9),  JoyInfo(GLFW_JOYSTICK_10),
               JoyInfo(GLFW_JOYSTICK_11), JoyInfo(GLFW_JOYSTICK_12),
               JoyInfo(GLFW_JOYSTICK_13), JoyInfo(GLFW_JOYSTICK_14),
               JoyInfo(GLFW_JOYSTICK_15), JoyInfo(GLFW_JOYSTICK_16) } },
    /* -- Init events for event manager ------------------------------------ */
    EvtMain::RegVec{                   // Events list to register
      { EMC_INP_SET_CUR_POS,  bind(&Input::OnSetCurPos,   this, _1) },
      { EMC_INP_CHAR,         bind(&Input::OnFilteredKey, this, _1) },
      { EMC_INP_PASTE,        bind(&Input::OnWindowPaste, this, _1) },
      { EMC_INP_MOUSE_MOVE,   bind(&Input::OnMouseMove,   this, _1) },
      { EMC_INP_MOUSE_CLICK,  bind(&Input::OnMouseClick,  this, _1) },
      { EMC_INP_MOUSE_FOCUS,  bind(&Input::OnMouseFocus,  this, _1) },
      { EMC_INP_MOUSE_SCROLL, bind(&Input::OnMouseWheel,  this, _1) },
      { EMC_INP_KEYPRESS,     bind(&Input::OnKeyPress,    this, _1) },
      { EMC_INP_DRAG_DROP,    bind(&Input::OnDragDrop,    this, _1) },
      { EMC_INP_JOY_STATE,    bind(&Input::OnJoyState,    this, _1) },
    },
    /* -- More initialisers ------------------------------------------------ */
    iConsoleKey1(GLFW_KEY_UNKNOWN),    // Init primary console key
    iConsoleKey2(GLFW_KEY_UNKNOWN),    // Init secondary console key
    lfOnMouseClick{ "OnMouseClick" },  // Init mouse click lua event
    lfOnMouseMove{ "OnMouseMove" },    // Init mouse movement lua event
    lfOnMouseScroll{ "OnMouseScroll" },// Init mouse wheel lua event
    lfOnMouseFocus{ "OnMouseFocus" },  // Init mouse focus lua event
    lfOnKey{ "OnUnfilteredKey" },      // Init unfiltered keypress lua event
    lfOnChar{ "OnFilteredKey" },       // Init filtered keypress lua event
    lfOnDragDrop{ "OnDragDrop" },      // Init drag & drop lua event
    lfOnJoyState{ "OnJoyState" },      // Init joy state lua event
    jsStatus(JOY_DISABLE),             // Initial joystick status is disabled
    iWinWidth(0),                      // Window width init by display
    iWinHeight(0),                     // Window height init by display
    iWinWidthD2(0),                    // Window width/2 init by display
    iWinHeightD2(0)                    // Window height/2 init by display
    /* -- No code ---------------------------------------------------------- */
    { }
  /* -- Destructor --------------------------------------------------------- */
  DTORHELPER(~Input, DeInit())
  /* ----------------------------------------------------------------------- */
  DELETECOPYCTORS(Input)               // Suppress default functions for safety
  /* -- Handle a deadzone change ------------------------------------------- */
  CVarReturn SetDefaultJoyDZ(const float fDZ,
    const function<void(JoyInfo&)> &fcbCallBack)
  { // Bail if invalid deadzone
    if(fDZ > 1) return DENY;
    // Set it
    StdForEach(par_unseq, GetJoyList().begin(),
      GetJoyList().end(), fcbCallBack);
    // Success
    return ACCEPT;
  }
  /* -- Set default negative deadzone -------------------------------------- */
  CVarReturn SetDefaultJoyRevDZ(const float fNewDeadZone)
    { return SetDefaultJoyDZ(fNewDeadZone, [fNewDeadZone](JoyInfo &jiItem)
        { jiItem.SetReverseDeadZone(fNewDeadZone); }); }
  /* -- Set default positive deadzone -------------------------------------- */
  CVarReturn SetDefaultJoyFwdDZ(const float fNewDeadZone)
    { return SetDefaultJoyDZ(fNewDeadZone, [fNewDeadZone](JoyInfo &jiItem)
        { jiItem.SetForwardDeadZone(fNewDeadZone); }); }
  /* -- Set first console key ---------------------------------------------- */
  CVarReturn SetConsoleKey1(const int iK)
    { return CVarSimpleSetIntNG(iConsoleKey1, iK, GLFW_KEY_LAST); }
  /* -- Set second console key --------------------------------------------- */
  CVarReturn SetConsoleKey2(const int iK)
    { return CVarSimpleSetIntNG(iConsoleKey2, iK, GLFW_KEY_LAST); }
  /* -- Set full screen toggler -------------------------------------------- */
  CVarReturn SetFSTogglerEnabled(const bool bState)
    { FlagSetOrClear(IF_FSTOGGLER, bState); return ACCEPT; }
  /* ----------------------------------------------------------------------- */
} *cInput = nullptr;                   // Global input class
/* ------------------------------------------------------------------------- */
}                                      // End of public module namespace
/* ------------------------------------------------------------------------- */
}                                      // End of private module namespace
/* == EoF =========================================================== EoF == */

-- INPUT.LUA =============================================================== --
-- ooooooo.--ooooooo--.ooooo.-----.ooooo.--oooooooooo-oooooooo.----.ooooo..o --
-- 888'-`Y8b--`888'--d8P'-`Y8b---d8P'-`Y8b-`888'---`8-`888--`Y88.-d8P'---`Y8 --
-- 888----888--888--888---------888---------888--------888--.d88'-Y88bo.---- --
-- 888----888--888--888---------888---------888oo8-----888oo88P'---`"Y888o.- --
-- 888----888--888--888----oOOo-888----oOOo-888--"-----888`8b.--------`"Y88b --
-- 888---d88'--888--`88.---.88'-`88.---.88'-888-----o--888-`88b.--oo----.d8P --
-- 888bd8P'--oo888oo-`Y8bod8P'---`Y8bod8P'-o888ooood8-o888o-o888o-8""8888P'- --
-- ========================================================================= --
-- (c) Mhatxotic Design, 2024          (c) Millennium Interactive Ltd., 1994 --
-- ========================================================================= --
-- Lua aliases (optimisation) ---------------------------------------------- --
local error<const>, floor<const>, pairs<const>, remove<const>,
  tostring<const>, xpcall<const> =
    error, math.floor, pairs, table.remove, tostring, xpcall;
-- M-Engine aliases (optimisation) ----------------------------------------- --
local CoreStack<const>, CoreTicks<const>, DisplayReset<const>,
  InputClearStates<const>, InputGetJoyAxis<const>, InputGetJoyButton<const>,
  InputGetNumJoyAxises<const>, InputOnJoyState<const>, InputOnKey<const>,
  InputOnMouseClick<const>, InputOnMouseMove<const>, InputOnMouseScroll<const>,
  InputSetCursor<const>, InputSetCursorCentre<const>, InputSetCursorPos<const>,
  SShotFbo<const>, UtilBlank<const>, UtilClamp<const>, UtilIsBoolean<const>,
  UtilIsFunction<const>, UtilIsInteger<const>, UtilIsString<const>,
  UtilIsTable<const>, fboMain<const> =
    Core.Stack, Core.Ticks, Display.Reset, Input.ClearStates, Input.GetJoyAxis,
    Input.GetJoyButton, Input.GetNumJoyAxises, Input.OnJoyState, Input.OnKey,
    Input.OnMouseClick, Input.OnMouseMove, Input.OnMouseScroll, Input.SetCursor,
    Input.SetCursorCentre, Input.SetCursorPos, SShot.Fbo, Util.Blank,
    Util.Clamp, Util.IsBoolean, Util.IsFunction, Util.IsInteger, Util.IsString,
    Util.IsTable, Fbo.Main();
-- Diggers function and data aliases --------------------------------------- --
local InitSetup, IsFading, SetErrorMessage, aCursorData, texSpr;
-- Globals ----------------------------------------------------------------- --
local aKeys<const> = Input.KeyCodes;   -- Keyboard scan codes
local iCursorMin, iCursorMax;          -- Cursor minimum and maximum
local iCursorAdjX, iCursorAdjY;        -- Cursor origin co-ordinates
local iCId;                            -- Current cursor id
local iStageLeft, iStageRight;         -- Stage left and top
local iStageTop, iStageBottom;         -- Stage right and bottom
-- Input handling variables ------------------------------------------------ --
local aMouseState<const>  = { };       -- Formatted mouse state
local iCursorX, iCursorY  = 160, 120;  -- Cursor position
local nWheelX, nWheelY    = 0, 0;      -- Mouse wheel state
local nJoyAX, nJoyAY      = 0, 0;      -- Joystick axis values
local aJoy<const>         = { };       -- Joysticks connected data
local iJoyActive;                      -- Currently active joystick
-- Current polled keybinds and all available key binds --------------------- --
local aGlobalKeyBinds;                 -- Global keybinds (defined later)
local aKeyBinds;                       -- Key/state/func translation lookup
local aKeyBank<const> = { };           -- All keys
local aKeyBankCats<const> = { };       -- All keys categorised
local iKeyBank = 0;                    -- Currently active keybank
-- Mouse is in specified bounds -------------------------------------------- --
local function IsMouseInBounds(iX1, iY1, iX2, iY2)
  return iCursorX >= iX1 and iCursorY >= iY1 and
         iCursorX < iX2 and iCursorY < iY2 end;
local function IsMouseNotInBounds(iX1, iY1, iX2, iY2)
  return iCursorX < iX1 or iCursorY < iY1 or
         iCursorX >= iX2 or iCursorY >= iY2 end;
local function IsMouseXLessThan(iX) return iCursorX < iX end;
local function IsMouseXGreaterEqualThan(iX) return iCursorX >= iX end;
local function IsMouseYLessThan(iY) return iCursorY < iY end;
local function IsMouseYGreaterEqualThan(iY) return iCursorY >= iY end;
local function GetMouseX() return iCursorX end;
local function GetMouseY() return iCursorY end;
-- Returns current mouse button state -------------------------------------- --
local function GetMouseState(iButton) return aMouseState[iButton] or 0 end;
-- Clears the specified mouse button state --------------------------------- --
local function ClearMouseState(iButton) aMouseState[iButton] = nil end;
-- Returns true if the specified mouse button is held down ----------------- --
local function IsMouseHeld(iButton) return GetMouseState(iButton) > 0 end
-- Returns true if the specified mouse button was pressed ------------------ --
local function IsMousePressed(iButton)
  if GetMouseState(iButton) == 0 then return false end;
  ClearMouseState(iButton);
  return true;
end
-- Returns true if the specified mouse button was pressed ------------------ --
local function IsMousePressedNoRelease(iButton)
  if GetMouseState(iButton) == 0 then return false end;
  return true;
end
-- Returns true if the specified mouse button was pressed ------------------ --
local function IsMouseReleased(iButton) return not IsMousePressed(iButton) end;
-- Returns current joystick state ------------------------------------------ --
local function GetJoyState(iButton)
  if not iJoyActive then return 0 end;
  return InputGetJoyButton(iJoyActive, iButton);
end
-- Returns true if specified joystick button was pressed ------------------- --
local function IsJoyPressed(iButton) return GetJoyState(iButton) == 1 end
-- Returns true if specified joystick button is held down ------------------ --
local function IsJoyHeld(iButton) return GetJoyState(iButton) >= 1 end
-- Returns true if specified joystick button is released ------------------- --
local function IsJoyReleased(iButton) return not IsJoyPressed(iButton) end
-- Returns true if specified mouse or joystick button is pressed ----------- --
local function IsButtonPressed(iButton)
  return IsMousePressed(iButton) or IsJoyPressed(iButton);
end
-- Returns true if specified mouse or joystick button is pressed ----------- --
local function IsButtonPressedNoRelease(iButton)
  return IsMousePressedNoRelease(iButton) or IsJoyPressed(iButton);
end
-- Returns true if specified mouse or joystick button is held -------------- --
local function IsButtonHeld(iButton)
  return IsMouseHeld(iButton) or IsJoyHeld(iButton);
end
-- Returns true if specified mouse or joystick button is released ---------- --
local function IsButtonReleased(iButton)
  return IsMouseReleased(iButton) and IsJoyReleased(iButton);
end
-- Get mouse scrolling state ----------------------------------------------- --
local function IsScrollingLeft()
  if not IsJoyPressed(6) and nWheelX <= 0 then return false end;
  nWheelX = 0;
  return true;
end
-- Get mouse scrolling state ----------------------------------------------- --
local function IsScrollingRight()
  if not IsJoyPressed(7) and nWheelX >= 0 then return false end;
  nWheelX = 0;
  return true;
end
-- Get mouse scrolling state ----------------------------------------------- --
local function IsScrollingUp()
  if not IsJoyPressed(4) and nWheelY <= 0 then return false end;
  nWheelY = 0;
  return true;
end
-- Get mouse scrolling state ----------------------------------------------- --
local function IsScrollingDown()
  if not IsJoyPressed(5) and nWheelY >= 0 then return false end;
  nWheelY = 0;
  return true;
end
-- When a key is pressed --------------------------------------------------- --
local function OnKey(iKey, iState)
  -- Get function for key and return if it is not assigned
  local fcbCb<const> = aKeyBinds[iState][iKey];
  if not fcbCb then return end;
  -- Protected call so we can handle errors
  local bResult<const>, sReason<const> = xpcall(fcbCb, CoreStack);
  if not bResult then SetErrorMessage(sReason) end;
end
-- When the mouse is clicked ----------------------------------------------- --
local function OnMouseClick(iButton, iState) aMouseState[iButton] = iState end
-- Joystick procedure ------------------------------------------------------ --
local function JoystickProc()
  -- If joystick is available
  if iJoyActive then
    -- Axis going left?
    local nAxisX<const> = InputGetJoyAxis(iJoyActive, 0);
    if nAxisX < 0 then
      -- Reset if positive
      if nJoyAX > 0 then nJoyAX = 0 end;
      -- Update X axis acceleration
      nJoyAX = UtilClamp(nJoyAX - 0.5, -5, 0);
    -- Axis going right?
    elseif nAxisX > 0 then
      -- Reset if negative
      if nJoyAX < 0 then nJoyAX = 0 end;
      -- Update X axis acceleration
      nJoyAX = UtilClamp(nJoyAX + 0.5, 0, 5);
    -- X Axis not going left or right? Reset X axis acceleration
    else nJoyAX = 0 end;
    -- Axis going up?
    local nAxisY<const> = InputGetJoyAxis(iJoyActive, 1);
    if nAxisY < 0 then
      -- Reset if positive
      if nJoyAY > 0 then nJoyAY = 0 end;
      -- Update Y axis acceleration
      nJoyAY = UtilClamp(nJoyAY - 0.5, -5, 0);
    -- Axis going down?
    elseif nAxisY > 0 then
      -- Reset if negative
      if nJoyAY < 0 then nJoyAY = 0 end;
      -- Update Y axis acceleration
      nJoyAY = UtilClamp(nJoyAY + 0.5, 0, 5);
    -- Y Axis not going up or down? Reset Y axis acceleration
    else nJoyAY = 0 end;
    -- Axis moving?
    if nJoyAX ~= 0 or nJoyAY ~= 0 then
      -- Adjust mouse position
      iCursorX, iCursorY =
        UtilClamp(iCursorX + nJoyAX, iStageLeft, iStageRight - 1),
        UtilClamp(iCursorY + nJoyAY, iStageTop, iStageBottom - 1);
      -- Update mouse position
      InputSetCursorPos(iCursorX, iCursorY);
    -- No axis pressed
    end
    -- Check for setup buttons
    if IsJoyPressed(8) and not IsFading() then return InitSetup(1) end;
  -- Joystick polling not enabled
  end
  -- Check for setup buttons
  if IsMousePressed(5) and not IsFading() then InitSetup(1) end;
end
-- Check joystick states --------------------------------------------------- --
local function OnJoyState(iJ, bState)
  -- Joystick is connected? Insert into joysticks list
  if bState then aJoy[1 + #aJoy] = iJ;
  -- Joystick was removed? Find joystick and remove it
  else for iI = 1, #aJoy do
    if aJoy[iI] == iJ then remove(aJoy, iI) break end;
  end end;
  -- If we have joysticks?
  if #aJoy > 0 then
    -- Joystick id
    for iJoy = 1, #aJoy do
      -- Get joystick
      local iJoyPending<const> = aJoy[iJoy];
      -- Get number of axises and return if not have two
      local iNumAxises<const> = InputGetNumJoyAxises(iJoyPending);
      if iNumAxises >= 2 then
        -- Set the first active joystick
        iJoyActive = iJoyPending;
        -- Success
        return;
      end
    end
  end
  -- Joystick no longer valid
  iJoyActive = nil;
end
-- When the mouse wheel is moved ------------------------------------------- --
local function OnMouseScroll(nX, nY) nWheelX, nWheelY = nX, nY end;
-- When the mouse is moved ------------------------------------------------- --
local function OnMouseMove(nX, nY)
  iCursorX, iCursorY = floor(nX), floor(nY);
end
-- Get cursor -------------------------------------------------------------- --
local function GetCursor() return iCId end;
-- Set cursor -------------------------------------------------------------- --
local function SetCursor(iId)
  -- Check parameter
  if not UtilIsInteger(iId) then
    error("Cursor id integer is invalid! "..tostring(iId)) end;
  -- Get cursor data for id and check it
  local aCursorItem<const> = aCursorData[iId];
  if not UtilIsTable(aCursorItem) then
    error("Cursor id not valid! "..tostring(aCursorItem)) end;
  -- Set new cursor dynamics
  iCursorMin, iCursorMax, iCursorAdjX, iCursorAdjY =
    aCursorItem[1], aCursorItem[2], aCursorItem[3], aCursorItem[4];
  -- Set cursor id
  iCId = iId;
end
-- Categorise the keys ----------------------------------------------------- --
local function RegisterCategorise(sName, aKeys)
  -- Check that given table is valid
  if not UtilIsTable(aKeys) then
    error("Key table is invalid! "..tostring(aKeys)) end;
  -- Check and add all keys to global bank in key bank
  for iCategory, aBinds in pairs(aKeys) do
    -- Check that given table is valid
    if not UtilIsTable(aBinds) then
      error("Invalid key binds table in category "..iCategory.."! "..
        tostring(aBinds)) end;
    -- Enumerate binds
    for iIndex = 1, #aBinds do
      -- Get bind details and check default key
      local aBind<const> = aBinds[iIndex];
      if not UtilIsTable(aBind) then
        error("Invalid key bind table in category "..iCategory..":"..iIndex..
          "! "..tostring(aBind)) end;
      -- Check key
      local iKey<const> = aBind[1];
      if not UtilIsInteger(iKey) then
        error("Invalid key "..tostring(iKey).." at index "..iIndex) end;
      -- Check callback when key pressed
      local fcbCb<const> = aBind[2];
      if not UtilIsFunction(fcbCb) then
        error("Invalid callback "..tostring(fcbCb).." at index "..iIndex) end;
      -- Check label
      local sId<const> = aBind[3];
      if not UtilIsString(sId) or #sId == 0 then
        error("Invalid id "..tostring(sId).." at index "..iIndex) end;
      -- Check description
      local sDesc<const> = aBind[4];
      if not UtilIsString(sDesc) or #sDesc == 0 then
        error("Invalid label "..tostring(sDesc).." at index "..iIndex) end;
      -- Check if we've registered this and if we haven't?
      local aExisting<const> = aKeyBankCats[sId];
      if not aExisting then
        -- Must be 4 variables ONLY
        if #aBind ~= 4 then
          error("Required 4 (not "..#aBind..") members at index "..iIndex) end;
        -- Backup key (used for default key)
        aBind[5] = aBind[1];
        -- Create full name of bind for setup screen
        aBind[6] = sName..": "..aBind[4];
        -- Set data with identifier. Duplicates will overwrite each other. This
        -- is the whole point since we may need to use the same bind but for
        -- different key states.
        aKeyBankCats[1 + #aKeyBankCats] = aBind;
        aKeyBankCats[sId] = aBind;
      -- We've registered it but show error if it's a different table
      elseif aExisting ~= aBind then
        error("Duplicate identifier '"..sId.."' between '"..sDesc..
              "' and '"..aExisting[4].."' at index "..iIndex.."!");
      end
    end
  end
end
-- Register keys from other module and return to them an identifier -------- --
local function RegisterKeys(sName, aKeys)
  -- Categories the keys
  RegisterCategorise(sName, aKeys);
  -- Add keybinds to key bank
  aKeyBank[1 + #aKeyBank] = { sName, aKeys };
  -- Return identifier
  return #aKeyBank;
end
-- Return current keybinds list -------------------------------------------- --
local function GetKeyBank() return iKeyBank end;
-- Set global keys table --------------------------------------------------- --
local function SetGlobalKeyBinds(aKeys) aGlobalKeyBinds = aKeys end;
-- Set active keybinds ----------------------------------------------------- --
local function SetKeys()
  -- Get statics
  local aStates<const> = Input.States;
  local iPress<const>, iRelease<const>, iRepeat<const> =
    aStates.PRESS, aStates.RELEASE, aStates.REPEAT;
  -- Real function
  local function DoSetKeys(bState, iIdentifier)
    -- Check parameters
    if not UtilIsBoolean(bState) then
      error("Bad global key state: "..tostring(bState)) end;
    -- Clear keybinds list
    aKeyBinds = {
      [iPress]   = { },                -- Pressed keys to functions
      [iRelease] = { },                -- Released keys to functions
      [iRepeat]  = { },                -- Repeated keys to functions
    };
    -- If we're to add the persistent keys?
    if bState then
      for iCategory, aBinds in pairs(aGlobalKeyBinds) do
        local aKeyBindsCat<const> = aKeyBinds[iCategory];
        for iIndex = 1, #aBinds do
          local aBind<const> = aBinds[iIndex];
          aKeyBindsCat[aBind[1]] = aBind[2];
        end
      end
    end
    -- Done if no keys are to be set?
    if not iIdentifier then iKeyBank = 0 return end;
    -- Make sure identifier is valid
    if not UtilIsInteger(iIdentifier) then
      error("Invalid table index type: "..tostring(iIdentifier)) end;
    if iIdentifier == 0 then iKeyBank = 0 return end;
    -- Get and check identifier in key bank
    local aKeys<const> = aKeyBank[iIdentifier];
    if not UtilIsTable(aKeys) then
      error("Invalid table index not registered: "..iIdentifier) end;
    -- Add binds from key bank to currently active keybinds
    for iCategory, aBinds in pairs(aKeys[2]) do
      local aKeyBindsCat<const> = aKeyBinds[iCategory];
      for iIndex = 1, #aBinds do
        local aBind<const> = aBinds[iIndex];
        aKeyBindsCat[aBind[1]] = aBind[2];
      end
    end
    -- Set keybank id so modules can restore a previous keybank
    iKeyBank = iIdentifier;
  end
  -- Set the real function
  SetKeys = DoSetKeys;
end
SetKeys();
-- Clear input states ------------------------------------------------------ --
local function ClearStates()
  -- Make sure user can't input anything
  InputClearStates();
  -- Clear keyboard and mouse
  for iButton in pairs(aMouseState) do aMouseState[iButton] = nil end
  nWheelX, nWheelY = 0, 0;
end
-- Renders the mouse cursor ------------------------------------------------ --
local function CursorRender()
  texSpr:BlitSLT(CoreTicks() // 4 % iCursorMax + iCursorMin,
    iCursorX + iCursorAdjX, iCursorY + iCursorAdjY);
end
-- When the fbo is resized ------------------------------------------------- --
local function OnFrameBufferUpdate(_, _, nLeft, nTop, nRight, nBottom)
  -- Record stage bounds
  iStageLeft, iStageTop, iStageRight, iStageBottom =
    floor(nLeft), floor(nTop), floor(nRight), floor(nBottom);
  -- If cursor is off the left of the screne? Clamp it to left
  if iCursorX < iStageLeft then iCursorX = iStageLeft;
  -- Cursor is off the right of the screen? Clamp it to right
  elseif iCursorX >= iStageRight then iCursorX = iStageRight-1 end;
  -- If cursor if off the top of the screen? Clamp it to top
  if iCursorY < iStageTop then iCursorY = iStageTop;
  -- Cursor is off the bottom of screen? Clamp it to bottom
  elseif iCursorY >= iStageBottom then iCursorY = iStageBottom-1 end;
end
-- Disable key handlers ---------------------------------------------------- --
local function DisableKeyHandlers()
  InputOnJoyState(nil);
  InputOnKey(nil);
end
-- Restore key handlers ---------------------------------------------------- --
local function RestoreKeyHandlers()
  InputOnJoyState(OnJoyState);
  InputOnKey(OnKey);
end
-- Script has been initialised --------------------------------------------- --
local function OnReady(GetAPI)
  -- Get imports
  InitSetup, IsFading, SetErrorMessage, aCursorData, texSpr =
    GetAPI("InitSetup", "IsFading", "SetErrorMessage", "aCursorData",
      "texSpr");
  -- Enable cursor clamper when fbo changes
  GetAPI("RegisterFBUCallback")("input", OnFrameBufferUpdate);
  -- Enable input capture events
  InputOnJoyState(OnJoyState);
  InputOnKey(OnKey);
  InputOnMouseClick(OnMouseClick);
  InputOnMouseMove(OnMouseMove);
  InputOnMouseScroll(OnMouseScroll);
  -- Global function key callbacks
  local function GkCbConfig() InitSetup(1) end;
  local function GkCbBinds() InitSetup(2) end;
  local function GkCbReadme() InitSetup(3) end;
  local function GkCbSShot() SShotFbo(fboMain) end;
  -- Set the global keybinds
  aGlobalKeyBinds = { [Input.States.PRESS] = {
    { aKeys.F1, GkCbConfig, "gksc", "SETUP SCREEN" };
    { aKeys.F2, GkCbBinds, "gksb", "SETUP KEYBINDS" },
    { aKeys.F3, GkCbReadme, "gksa", "SHOW ACKNOWLEDGEMENTS" },
    { aKeys.F10, InputSetCursorCentre, "gkcc", "SET CURSOR CENTRE" },
    { aKeys.F11, DisplayReset, "gkwr", "RESET WINDOW SIZE" },
    { aKeys.F12, GkCbSShot, "gkss", "TAKE SCREENSHOT" },
  }}
  -- Add keybinds to key bank categories for configuration
  RegisterCategorise("GLOBAL", aGlobalKeyBinds);
end
-- Exports and imports ----------------------------------------------------- --
return { F = OnReady, A = { ClearMouseState = ClearMouseState,
  ClearStates = ClearStates, CursorRender = CursorRender,
  DisableKeyHandlers = DisableKeyHandlers, GetCursor = GetCursor,
  GetJoyState = GetJoyState, GetKeys = GetKeys, GetKeyBank = GetKeyBank,
  GetMouseState = GetMouseState, GetMouseX = GetMouseX, GetMouseY = GetMouseY,
  IsButtonHeld = IsButtonHeld, IsButtonPressed = IsButtonPressed,
  IsButtonPressedNoRelease = IsButtonPressedNoRelease,
  IsButtonReleased = IsButtonReleased, IsJoyHeld = IsJoyHeld,
  IsJoyPressed = IsJoyPressed, IsJoyReleased = IsJoyReleased,
  IsMouseHeld = IsMouseHeld, IsMouseInBounds = IsMouseInBounds,
  IsMouseNotInBounds = IsMouseNotInBounds, IsMousePressed = IsMousePressed,
  IsMousePressedNoRelease = IsMousePressedNoRelease,
  IsMouseReleased = IsMouseReleased,
  IsMouseXGreaterEqualThan = IsMouseXGreaterEqualThan,
  IsMouseXLessThan = IsMouseXLessThan,
  IsMouseYGreaterEqualThan = IsMouseYGreaterEqualThan,
  IsMouseYLessThan = IsMouseYLessThan, IsScrollingDown = IsScrollingDown,
  IsScrollingLeft = IsScrollingLeft, IsScrollingRight = IsScrollingRight,
  IsScrollingUp = IsScrollingUp, JoystickProc = JoystickProc,
  RegisterKeys = RegisterKeys, RestoreKeyHandlers = RestoreKeyHandlers,
  SetCursor = SetCursor, SetKeys = SetKeys, aKeyBank = aKeyBank,
  aKeyBankCats = aKeyBankCats } };
-- End-of-File ============================================================= --

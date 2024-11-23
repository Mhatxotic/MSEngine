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
  tostring<const> =
    error, math.floor, pairs, table.remove, tostring;
-- M-Engine aliases (optimisation) ----------------------------------------- --
local CoreTicks<const>, InputClearStates<const>, InputGetJoyAxis<const>,
  InputGetJoyButton<const>, InputGetNumJoyAxises<const>, InputSetCursor<const>,
  InputSetCursorPos<const>, UtilBlank<const>, UtilClamp<const>,
  UtilIsInteger<const>, UtilIsTable<const>
  = ------------------------------------------------------------------------ --
  Core.Ticks, Input.ClearStates, Input.GetJoyAxis, Input.GetJoyButton,
  Input.GetNumJoyAxises, Input.SetCursor, Input.SetCursorPos, Util.Blank,
  Util.Clamp, Util.IsInteger, Util.IsTable;
-- Globals ----------------------------------------------------------------- --
local aStates<const> = Input.States;   -- Keyboard press states
local aKeys<const> = Input.KeyCodes;   -- Keyboard scan codes
local aCursorIdData, aCursorData;      -- Cursor data
local iCursorMin, iCursorMax;          -- Cursor minimum and maximum
local iCursorAdjX, iCursorAdjY;        -- Cursor origin co-ordinates
local texSpr;                          -- Texture where cursors are
local iCId;                            -- Current cursor id
local iStageLeft, iStageRight;         -- Stage left and top
local iStageTop, iStageBottom;         -- Stage right and bottom
-- Input handling variables ------------------------------------------------ --
local aKeyState<const>    = { };       -- Formatted keyboard state
local aMouseState<const>  = { };       -- Formatted mouse state
local iCursorX, iCursorY  = 160, 120;  -- Cursor position
local nWheelX, nWheelY    = 0, 0;      -- Mouse wheel state
local nJoyAX, nJoyAY      = 0, 0;      -- Joystick axis values
local fcbJoystick         = UtilBlank; -- Joystick to mouse conversion function
local aJoy<const>         = { };       -- Joysticks connected data
local iJoyActive;                      -- Currently active joystick
-- Current polled keybinds and all available key binds --------------------- --
local aGlobalKeyBinds;                 -- Global keybinds (defined later)
local aKeyBinds;                       -- Key/state/func translation lookup
local aKeyBank<const> = { { } };       -- All keys ([1] reserved for all)
local iKeyBank = 0;                    -- Currently active keybank
-- Get current key state for specified key --------------------------------- --
local function GetKeyState(iKey) return aKeyState[iKey] or 0 end;
-- Clear specified key state for specified key ----------------------------- --
local function ClearKeyState(iKey) aKeyState[iKey] = nil end;
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
-- Get mouse scrolling state ----------------------------------------------- --
local function IsScrollingLeft()
  if nWheelX <= 0 then return false else nWheelX = 0 return true end;
end
-- Get mouse scrolling state ----------------------------------------------- --
local function IsScrollingRight()
  if nWheelX >= 0 then return false else nWheelX = 0 return true end;
end
-- Get mouse scrolling state ----------------------------------------------- --
local function IsScrollingUp()
  if nWheelY <= 0 then return false else nWheelY = 0 return true end;
end
-- Get mouse scrolling state ----------------------------------------------- --
local function IsScrollingDown()
  if nWheelY >= 0 then return false else nWheelY = 0 return true end;
end
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
-- Is key being pressed? (Doesn't repeat) ---------------------------------- --
local function IsKeyPressed(iKey)
  if GetKeyState(iKey) == 1 then ClearKeyState(iKey) return true end;
  return false;
end
-- Is key not being pressed? ----------------------------------------------- --
local function IsKeyReleased(iKey) return not IsKeyPressed(iKey) end;
-- Is key being pressed (uses OS repeat speed) ----------------------------- --
local function IsKeyRepeating(iKey)
  if IsKeyPressed(iKey) then return true end;
  if GetKeyState(iKey) < 2 then return false end;
  ClearKeyState(iKey);
  return true;
end
-- Is key being held? (FPS dependent) -------------------------------------- --
local function IsKeyHeld(iKey) return GetKeyState(iKey) >= 1 end;
-- When a key is pressed --------------------------------------------------- --
local function OnKey(iKey, iState)
  -- Get function for key and call the function if set
  local aKey<const> = aKeyBinds[iState][iKey];
  if aKey then aKey() end;
  -- Else use our global key press table (DELETE ME WHEN KEYBINDS DONE)
  aKeyState[iKey] = iState;
end
-- When the mouse is clicked ----------------------------------------------- --
local function OnMouseClick(iButton, iState) aMouseState[iButton] = iState end
-- Check joystick states --------------------------------------------------- --
local function OnJoyState(iJ, bState)
  -- Joystick is connected? Insert into joysticks list
  if bState then aJoy[1 + #aJoy] = iJ;
  -- Joystick was removed? Find joystick and remove it
  else
    for iI = 1, #aJoy do if aJoy[iI] == iJ then remove(aJoy, iI) break end end;
  end
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
        -- Mouse callback
        local function JoystickMoveCallback()
          -- Ignore if no joystick is available
          if not iJoyActive then fcbJoystick = UtilBlank return end;
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
        end
        -- Real update mouse info
        fcbJoystick = JoystickMoveCallback;
        -- Success
        return;
      end
    end
  end
  -- Joystick no longer valid
  iJoyActive = nil;
  -- Clear joystick to mouse callback
  fcbJoystick = UtilBlank;
end
-- When the mouse wheel is moved ------------------------------------------- --
local function OnMouseScroll(nX, nY) nWheelX, nWheelY = nX, nY end;
-- When the mouse is moved ------------------------------------------------- --
local function OnMouseMove(nX, nY) iCursorX,iCursorY = floor(nX),floor(nY) end;
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
-- Register keys from other module and return to them an identifier
local function RegisterKeys(aKeys)
  -- Check that given table is valid
  if not UtilIsTable(aKeys) then
    error("Key table is invalid! "..tostring(aKeys)) end;
  -- Add keybinds to key bank
  aKeyBank[#aKeyBank + 1] = aKeys;
  -- Add all keys to global bank in key bank
  local aGlobalBank<const> = aKeyBank[1];
  for iCategory, aBinds in pairs(aKeys) do
    for iIndex = 1, #aBinds do aGlobalBank[#aGlobalBank] = aBinds[iIndex] end;
  end
  -- Return identifier
  return #aKeyBank;
end
-- Return current keybinds list
local function GetKeyBank() return iKeyBank end;
-- Set global keys table
local function SetGlobalKeyBinds(aKeys) aGlobalKeyBinds = aKeys end;
-- Set global keys availability status. The keys will initially not be
-- available until the intro movie begins.
local function SetKeys(bState, iIdentifier)
  -- Clear keybinds list
  aKeyBinds = {
    [aStates.PRESS] = { },               -- Pressed keys to functions
    [aStates.RELEASE] = { },             -- Released keys to functions
    [aStates.REPEAT] = { }               -- Repeated keys to functions
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
  for iCategory, aBinds in pairs(aKeys) do
    local aKeyBindsCat<const> = aKeyBinds[iCategory];
    for iIndex = 1, #aBinds do
      local aBind<const> = aBinds[iIndex];
      aKeyBindsCat[aBind[1]] = aBind[2];
    end
  end
  -- Set keybank id so modules can restore a previous keybank
  iKeyBank = iIdentifier;
end
-- Register global keys ---------------------------------------------------- --
local function RegisterGlobalKeys(aKeys)
  -- Check parameter
  if not UtilIsTable(aKeys) then error("Invalid keys: "..tostring(aKeys)) end;
  -- Set the keys
  aGlobalKeyBinds = aKeys;
end
-- Clear input states ------------------------------------------------------ --
local function ClearStates()
  -- Make sure user can't input anything
  InputClearStates();
  -- Clear keyboard and mouse
  for iKey in pairs(aKeyState) do ClearKeyState(iKey) end
  for iButton in pairs(aMouseState) do aMouseState[iButton] = nil end
  nWheelX, nWheelY = 0, 0;
end
-- Joystick procedure call ------------------------------------------------- --
local function JoystickProc() fcbJoystick() end;
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
-- Exports and imports ----------------------------------------------------- --
return { A = {
  -- Exports --------------------------------------------------------------- --
  ClearKeyState = ClearKeyState, ClearMouseState = ClearMouseState,
  ClearStates = ClearStates, CursorRender = CursorRender,
  GetCallbacks = GetCallbacks, GetCursor = GetCursor,
  GetJoyState = GetJoyState, GetKeyState = GetKeyState,
  GetMouseState = GetMouseState, GetMouseX = GetMouseX, GetMouseY = GetMouseY,
  IsButtonHeld = IsButtonHeld, IsButtonPressed = IsButtonPressed,
  IsButtonPressedNoRelease = IsButtonPressedNoRelease,
  IsButtonReleased = IsButtonReleased, IsJoyHeld = IsJoyHeld,
  IsJoyPressed = IsJoyPressed, IsJoyReleased = IsJoyReleased,
  IsKeyHeld = IsKeyHeld, IsKeyPressed = IsKeyPressed,
  IsKeyReleased = IsKeyReleased, IsKeyRepeating = IsKeyRepeating,
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
  RegisterGlobalKeys = RegisterGlobalKeys, SetCursor = SetCursor,
  SetKeys = SetKeys;
  -- ----------------------------------------------------------------------- --
  }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  texSpr, aCursorIdData, aCursorData =
    GetAPI("texSpr", "aCursorIdData", "aCursorData");
  -- Enable cursor fixer when fbo changes ---------------------------------- --
  GetAPI("RegisterFBUCallback")("input", OnFrameBufferUpdate);
  -- Pur cursor in centre -------------------------------------------------- --
  Input.SetCursorCentre();
  -- Enable input capture events ------------------------------------------- --
  Input.OnJoyState(OnJoyState);
  Input.OnKey(OnKey);
  Input.OnMouseClick(OnMouseClick);
  Input.OnMouseMove(OnMouseMove);
  Input.OnMouseScroll(OnMouseScroll);
  -- Request joystick events again (we didn't get them on the first frame) - --
  Input.RefreshJoysticks();
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

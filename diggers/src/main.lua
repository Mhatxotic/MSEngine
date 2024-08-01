-- MAIN.LUA ================================================================ --
-- ooooooo.--ooooooo--.ooooo.-----.ooooo.--oooooooooo-oooooooo.----.ooooo..o --
-- 888'-`Y8b--`888'--d8P'-`Y8b---d8P'-`Y8b-`888'---`8-`888--`Y88.-d8P'---`Y8 --
-- 888----888--888--888---------888---------888--------888--.d88'-Y88bo.---- --
-- 888----888--888--888---------888---------888oo8-----888oo88P'---`"Y888o.- --
-- 888----888--888--888----oOOo-888----oOOo-888--"-----888`8b.--------`"Y88b --
-- 888---d88'--888--`88.---.88'-`88.---.88'-888-----o--888-`88b.--oo----.d8P --
-- 888bd8P'--oo888oo-`Y8bod8P'---`Y8bod8P'-o888ooood8-o888o-o888o-8""8888P'- --
-- ========================================================================= --
-- Copyr. (c) MS-Design, 2024   Copyr. (c) Millennium Interactive Ltd., 1994 --
-- ========================================================================= --
-- Lua aliases (optimisation) ---------------------------------------------- --
local ceil<const>, collectgarbage<const>, error<const>, floor<const>,
  format<const>, max<const>, min<const>, pairs<const>, random<const>,
  remove<const>, sort<const>, tostring<const>, unpack<const> =
    math.ceil, collectgarbage, error, math.floor, string.format, math.max,
    math.min, pairs, math.random, table.remove, table.sort, tostring,
    table.unpack;
-- M-Engine aliases (optimisation) ----------------------------------------- --
local AssetParseBlock<const>, CoreLog<const>, CoreOnTick<const>,
  CoreStack<const>, CoreWrite<const>, DisplayReset<const>,
  FboConEnabled<const>, FboDraw<const>, CoreCatchup<const>, CoreTicks<const>,
  CoreTime<const>, InputClearStates<const>, InputGetJoyAxis<const>,
  InputGetJoyButton<const>, InputGetNumJoyAxises<const>, InputSetCursor<const>,
  InputSetCursorPos<const>, SShotFbo<const>, TextureCreate<const>,
  UtilBlank<const>, UtilClamp<const>, UtilClampInt<const>, UtilDuration<const>,
  UtilExplode<const>, UtilImplode<const>, UtilIsFunction<const>,
  UtilIsInteger<const>, UtilIsNumber<const>, UtilIsString<const>,
  UtilIsTable<const>, UtilRoundInt<const>, VariableRegister<const> =
    Asset.ParseBlock, Core.Log, Core.OnTick, Core.Stack,
    Core.Write, Display.Reset, Fbo.ConEnabled, Fbo.Draw, Core.Catchup,
    Core.Ticks, Core.Time, Input.ClearStates, Input.GetJoyAxis,
    Input.GetJoyButton, Input.GetNumJoyAxises, Input.SetCursor,
    Input.SetCursorPos, SShot.Fbo, Texture.Create, Util.Blank, Util.Clamp,
    Util.ClampInt, Util.Duration, Util.Explode, Util.Implode, Util.IsFunction,
    Util.IsInteger, Util.IsNumber, Util.IsString, Util.IsTable, Util.RoundInt,
    Variable.Register;
-- Globals ----------------------------------------------------------------- --
local fboMain<const> = Fbo.Main();     -- Main frame buffer object class
local fFont<const> = Font.Console();   -- Main console class
local aKeys<const> = Input.KeyCodes;   -- Keyboard codes
local CId, CBProc, CBRender, CBInput;  -- Generic tick callbacks
local aCursorIdData, aCursorData;      -- Cursor data
local CursorMin, CursorMax;            -- Cursor minimum and maximum
local CursorOX, CursorOY;              -- Cursor origin co-ordinates
local fcbFrameBufferCallbacks = { };   -- Frame buffer updated function
-- Input handling variables ------------------------------------------------ --
local aAPI;                            -- API to send to other functions
local aCache              = { };       -- File cache
local aModules            = { };       -- Modules data
local aKeyState           = { };       -- Formatted keyboard state
local aMouseState         = { };       -- Formatted mouse state
local aJoyState
local aSounds             = { };       -- Sound effects
local bTestMode           = false;     -- Test mode enabled
local fcbFading           = false;     -- Fading callback
local iCursorX, iCursorY  = 0, 0;      -- Cursor position
local nWheelX, nWheelY    = 0, 0;      -- Mouse wheel state
local nJoyAX, nJoyAY      = 0, 0;      -- Joystick axis values
local fcbMouse            = UtilBlank; -- Joystick to mouse conversion function
local aJoy                = { };       -- Joysticks connected data
local iJoyActive;                      -- Currently active joystick
local vidHandle;                       -- FMV playback handle
local nMusicPosition;                  -- Saved music position
local strmMusic;                       -- Currently playing music handle
local iMusicLoops;                     -- Saved music loops count
local texSpr;                          -- Sprites texture
local fontLarge;                       -- Large font (16px)
local fontLittle;                      -- Little font (8px)
local fontTiny;                        -- Tiny font (5px)
local fontSpeech;                      -- Speech font (10px)
-- Stage size -------------------------------------------------------------- --
local iStageWidth, iStageHeight;       -- Width and height
local iStageLeft, iStageTop;           -- Top left corner
local iStageRight, iStageBottom;       -- Bottom right corner
-- Library functions loaded later ------------------------------------------ --
local InitSetup, InitScene, InitCredits, InitEnding, LoadLevel,
  InitIntro, InitFail, InitScore, InitTitle, InitNewGame, aObjectTypes,
  aLevelsData, aRacesData, CheckGlobalKeys, InitDebugPlay;
-- Constants for loader ---------------------------------------------------- --
local aBFlags<const> = Image.Flags;    -- Get bitmap loading flags
local iPNG<const> = aBFlags.FCE_PNG;   -- Get forced PNG format flag
local aPFlags<const> = Pcm.Flags;      -- Get waveform loading flags
local iOGG<const> = aPFlags.FCE_OGG;   -- Get forced wave format
local aPrFlags<const> = Asset.Progress;-- Asset progress flags
local iFStart<const> = aPrFlags.FILESTART; -- File opened with information
-- Generic function to return a handle ------------------------------------ --
local function GenericReturnHandle(hH) return hH end;
-- Function to parse a script --------------------------------------------- --
local function ParseScript(aA)
  -- Get name of asset
  local sName<const> = aA:Name();
  -- Compile the script and get the return value
  local aModData<const> = AssetParseBlock(sName, 1, aA);
  if not UtilIsTable(aModData) then error(sName..": bad return!") end;
  local fcbModCb<const> = aModData.F;
  if not UtilIsFunction(fcbModCb) then error(sName..": bad callback!") end;
  local aModAPI<const> = aModData.A;
  if not UtilIsTable(aModAPI) then error(sName..": bad api!") end;
  -- Set name of module
  aModData.N = sName;
  -- Add functions to the api
  for sKey, vVar in pairs(aModAPI) do
    -- Check variable name
    if not UtilIsString(sKey) then
      error(sName.."["..tostring(sKey).."] bad key!") end;
    -- Check not already registered
    if aAPI[sKey] ~= nil then
      error(sName.."["..sKey.."] already registered!") end;
    -- Check that value is valid
    if nil == vVar then error(sName.."["..sKey.."] bad variable!") end;
    -- Assign variable in internal API
    aAPI[sKey] = vVar;
  end
  -- Put returned data in API for later when everything is loaded and we'll
  -- call the modules callback function with the fully loaded API.
  aModules[1 + #aModules] = aModData;
  -- Return success
  return true;
end
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
Input.OnKey(function(iKey, iState) aKeyState[iKey] = iState end);
-- When the mouse is clicked ----------------------------------------------- --
Input.OnMouseClick(function(iButton, iState) aMouseState[iButton] = iState end);
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
          if not iJoyActive then fcbMouse = UtilBlank return end;
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
              UtilClampInt(iCursorX + nJoyAX, iStageLeft, iStageRight - 1),
              UtilClampInt(iCursorY + nJoyAY, iStageTop, iStageBottom - 1);
            -- Update mouse position
            InputSetCursorPos(iCursorX, iCursorY);
          -- No axis pressed
          end
        end
        -- Real update mouse info
        fcbMouse = JoystickMoveCallback;
        -- Success
        return;
      end
    end
  end
  -- Joystick no longer valid
  iJoyActive = nil;
  -- Clear joystick to mouse callback
  fcbMouse = UtilBlank;
end
-- When a joystick device is changed --------------------------------------- --
Input.OnJoyState(OnJoyState);
-- When the mouse wheel is moved ------------------------------------------- --
local function OnMouseScroll(nX, nY) nWheelX, nWheelY = nX, nY end;
Input.OnMouseScroll(OnMouseScroll);
-- When the mouse is moved ------------------------------------------------- --
local function OnMouseMove(nX, nY) iCursorX,iCursorY = floor(nX),floor(nY) end;
Input.OnMouseMove(OnMouseMove);
-- Error handler ----------------------------------------------------------- --
local function SetErrorMessage(sReason)
  -- Activate main frame buffer object just incase it isn't
  fboMain:Activate();
  -- Show cursor
  InputSetCursor(true);
  -- Make sure text doesn't go off the screen
  local sFullReason<const> = sReason;
  local aLines<const> = UtilExplode(sReason, "\n");
  if #aLines > 15 then
    while #aLines > 15 do remove(aLines, #aLines) end;
    aLines[1 + #aLines] = "...more";
    sReason = UtilImplode(aLines, "\n");
  end
  -- Log the message
  Core.LogEx(sFullReason, 1);
  -- Add generic info to the message
  local sMessage<const> =
    "ERROR!\n\n\z
     \rcffffff00The program has halted and cannot continue.\rr\n\n\z
     Reason:-\n\n\z
     \rcffffff00"..tostring(sReason).."\rr\n\n\z
     Press C to copy to clipboard, R to retry or X to quit.";
  -- Keys used in tick function
  local iKeyC<const>, iKeyR<const>, iKeyX<const> = aKeys.C, aKeys.R, aKeys.X;
  -- Second change bool
  local nNext = 0;
  -- Callback function
  local function OnTick()
   -- Console disabled? Check for reset keys
    if not FboConEnabled() then
      if IsKeyPressed(iKeyC) then return Util.ClipSet(sFullReason) end;
      if IsKeyPressed(iKeyR) then return Core.Reset() end;
      if IsKeyPressed(iKeyX) then return Core.Quit() end;
    end
    -- Set clear colour depending on time
    local nTime<const>, nRed = CoreTime();
    if nTime % 1 < 0.5 then nRed = 0.5 else nRed = 1.0 end;
    -- Show error message
    fboMain:SetClearColour(nRed, 0, 0, 1);
    fFont:SetCRGBA(1, 1, 1, 1);
    fFont:SetSize(1);
    fFont:PrintW(iStageLeft + 8, iStageTop + 8, iStageWidth - 60, 0, sMessage);
    -- Draw frame if we changed the background colour
    if nTime >= nNext then FboDraw() nNext = nTime + 0.5 end;
  end
  -- Set loop function
  CoreOnTick(OnTick);
end
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
  CursorMin, CursorMax, CursorOX, CursorOY =
    aCursorItem[1], aCursorItem[2], aCursorItem[3], aCursorItem[4];
  -- Set cursor id
  CId = iId;
end
-- Set global keys availability status. The keys will initially not be
-- available until the intro movie begins.
local function SetGlobalKeys(bState)
  -- Keys used it global keys
  local iKeyF1<const>, iKeyF2<const>, iKeyF11<const>, iKeyF12<const> =
    aKeys.F1, aKeys.F2, aKeys.F11, aKeys.F12;
  -- Actual function
  local function Function(bState)
    -- Callback
    local function Callback()
      -- F1 key pressed?
      if IsKeyPressed(iKeyF1) then InitSetup(false);
      -- F2 key pressed?
      elseif IsKeyPressed(iKeyF2) or (IsJoyPressed(8) and IsJoyPressed(9))
        then InitSetup(true);
      -- F11 key pressed?
      elseif IsKeyPressed(iKeyF11) then DisplayReset();
      -- F12 key pressed?
      elseif IsKeyPressed(iKeyF12) then SShotFbo(fboMain) end;
    end
    -- Set global keys if enabled
    if bState then CheckGlobalKeys = Callback;
    -- Disabled
    else CheckGlobalKeys = UtilBlank end
  end
  -- Assign new function and call it
  SetGlobalKeys = Function;
  Function(bState);
end
SetGlobalKeys(false);
-- Get callbacks ----------------------------------------------------------- --
local function GetCallbacks() return CBProc, CBRender, CBInput end;
-- Set callbacks ----------------------------------------------------------- --
local function SetCallbacks(CBP, CBR, CBI)
  CBProc, CBRender, CBInput = CBP or UtilBlank,
                              CBR or UtilBlank,
                              CBI or UtilBlank end;
-- ------------------------------------------------------------------------- --
local function TimeIt(sName, fcbCallback, ...)
  -- Check parameters
  if not UtilIsString(sName) then
    error("Name string is invalid! "..tostring(sName)) end;
  if not UtilIsFunction(fcbCallback) then
    error("Function is invalid! "..tostring(fcbCallback)) end;
  -- Save time
  local nTime<const> = CoreTime();
  -- Execute function
  fcbCallback(...);
  -- Put result in console
  CoreLog("Procedure '"..sName.."' completed in "..
    UtilDuration(CoreTime()-nTime, 3).." sec!");
end
-- Asset types supported --------------------------------------------------- --
local aTypes<const> = {
  -- Async function   Params  Prefix  Suffix  Data loader function  Info?   Id
  { Image.FileAsync,  {iPNG}, "tex/", ".png", Texture.CreateTS,   false }, -- 1
  { Image.FileAsync,  {iPNG}, "tex/", ".png", TextureCreate,      false }, -- 2
  { Image.FileAsync,  {iPNG}, "tex/", ".png", Font.Image,         false }, -- 3
  { Pcm.FileAsync,    {iOGG}, "sfx/", ".ogg", Sample.Create,      false }, -- 4
  { Asset.FileAsync,  {0},    "",     "",     GenericReturnHandle,false }, -- 5
  { Image.FileAsync,  {0},    "tex/", ".png", Mask.Create,        false }, -- 6
  { Stream.FileAsync, {},     "mus/", ".ogg", GenericReturnHandle,false }, -- 7
  { Video.FileAsync,  {},     "fmv/", ".ogv", GenericReturnHandle,false }, -- 8
  { Asset.FileAsync,  {0},    "src/", ".lua", ParseScript,        true  }, -- 9
  -- Async function   Params  Prefix Suffix  Data loader function  Info?   Id
};
-- Loader ------------------------------------------------------------------ --
local function LoadResources(sProcedure, aResources, fComplete)
  -- Check parameters
  if not UtilIsString(sProcedure) then
    error("Procedure name string is invalid! "..tostring(sProcedure)) end;
  if not UtilIsTable(aResources) then
    error("Resources table is invalid! "..tostring(aResources)) end;
  if #aResources == 0 then error("No resources specified to load!") end;
  if not UtilIsFunction(fComplete) then
    error("Finished callback is invalid! "..tostring(fComplete)) end;
  -- Initialise queue
  local sDst, aInfo, aNCache, iTotal, iLoaded = "", { }, { }, nil, nil;
  -- Progress update on asynchronous loading
  local function ProgressUpdate(iCmd, ...)
    if iCmd == iFStart then aInfo = { ... } end;
  end
  -- Load item
  local function LoadItem(iI)
    -- Get resource data
    local aResource<const> = aResources[iI];
    if not UtilIsTable(aResource) then
      error("Supplied table at index "..iI.." is invalid!") end;
    -- Get type of resource and throw error if the type is invalid
    local aTypeData<const> = aTypes[aResource.T];
    if not UtilIsTable(aTypeData) then
      error("Supplied load type of '"..tostring(aResource.T)..
        "' is invalid at index "..iI.."!") end;
    -- Get destination file to load and check it
    sDst = aTypeData[3]..aResource.F..aTypeData[4];
    if #sDst == 0 then error("Filename at index "..iI.." is empty!") end;
    -- Handle to resource
    local hHandle;
    -- Build parameters table to send to function
    local aSrcParams<const> = aTypeData[2];
    local aDstParams<const> = { sDst,                 -- [1]
                                unpack(aSrcParams) }; -- [2]
    aDstParams[1 + #aDstParams] = SetErrorMessage;    -- [3]
    aDstParams[1 + #aDstParams] = ProgressUpdate;     -- [4]
    -- Get no-cache setting
    local bNoCache<const> = aResource.NC;
    -- When final handle has been acquired
    local function OnHandle(vHandle, bCached)
      -- Set handles
      hHandle, aResource.H = vHandle, vHandle;
      -- Cache the handle unless requested not to
      if not bNoCache then aNCache[sDst] = vHandle end;
      -- Set stage 2 duration and total duration
      aResource.ST2 = CoreTime() - aResource.ST2;
      aResource.ST3 = aResource.ST1 + aResource.ST2;
      -- Loaded counter increment
      iLoaded = iLoaded + 1;
      -- Execute the resource callback if available
      local fcbCallback<const> = aResource.A;
      if UtilIsFunction(fcbCallback) then fcbCallback() end;
      -- No need to show intermediate load times if cached
      if bCached then bCached = ".";
      -- Wasn't cached?
      else
        -- Calculate times for log
        bCached = " ("..UtilDuration(aResource.ST1, 3).."+"..
                        UtilDuration(aResource.ST2, 3);
        -- Add no cache flag and finish string
        if bNoCache then bCached = bCached.."/NC).";
                    else bCached = bCached..")." end;
      end
      -- Say in log that we loaded
      CoreLog("Loaded resource "..iLoaded.."/"..iTotal..": '"..
        sDst.."' in "..UtilDuration(aResource.ST3, 3).." sec"..bCached);
      -- Load the next item if not completed yet
      if iLoaded < iTotal then return LoadItem(iI + 1) end;
      -- Set new cache
      aCache = aNCache;
      -- Set arrow cursor
      SetCursor(aCursorIdData.ARROW);
      -- Enable global keys
      SetGlobalKeys(true);
      -- Garbage collect to remove unloaded assets
      collectgarbage();
      -- Execute finished handler function with our resource list
      TimeIt(sProcedure, fComplete, aResources);
    end
    -- Setup handle
    local function SetupSecondStage()
      -- Get current time
      local nTime<const> = CoreTime();
      -- Set stage 1 duration and stage 2 start time
      aResource.ST1 = nTime - aResource.ST1;
      aResource.ST2 = nTime;
      -- Function wants file info?
      local aParams<const> = aResource.P;
      if aTypeData[6] then
        for iI = 1, #aInfo do aParams[1 + #aParams] = aInfo[iI] end;
      end
    end
    -- When first handle has been loaded
    local function OnLoaded(vData)
      -- Setup second stage
      SetupSecondStage();
      -- Load the file and set the handle
      OnHandle(aTypeData[5](vData, unpack(aResource.P)));
    end
    aDstParams[1 + #aDstParams] = OnLoaded;
    -- Set stage 1 time
    aResource.ST1 = CoreTime();
    -- Reset info for progress update
    while #aInfo > 0 do remove(aInfo, #aInfo) end;
    -- Send cached handle if it exists
    local vCached<const> = aCache[sDst];
    if vCached then
      -- Setup second stage
      SetupSecondStage();
      -- Send straight to handle
      OnHandle(vCached, true);
    -- Dispatch the call
    else aTypeData[1](unpack(aDstParams)) end;
  end
  -- Disable global keys until everything has loaded
  SetGlobalKeys(false);
  -- Clear callbacks but keep the last render callback
  SetCallbacks(nil, CBRender, nil);
  -- Set loading cursor
  if aCursorIdData then SetCursor(aCursorIdData.WAIT) end;
  -- Initialise counters
  iTotal, iLoaded = #aResources, 0;
  -- Load first item
  LoadItem(1);
  -- Progress function
  local function GetProgress() return iLoaded/iTotal, sDst end
  -- Return progress function
  return GetProgress;
end
-- ------------------------------------------------------------------------- --
local function VideoStop()
  if vidHandle then vidHandle = vidHandle:Destroy() end;
end
-- ------------------------------------------------------------------------- --
local function VideoPlay(Handle)
  VideoStop();
  vidHandle = Handle;
  vidHandle:SetVLTRB(0, 0, 320, 240);
  vidHandle:SetTCLTRB(0, 0, 1, 1);
  vidHandle:SetFilter(true);
  vidHandle:Play();
  return vidHandle;
end
-- Return music handle ----------------------------------------------------- --
local function GetMusic() return strmMusic end;
-- Set music and video volume ---------------------------------------------- --
local function MusicVolume(Volume)
  if strmMusic then strmMusic:SetVolume(Volume) end;
  if vidHandle then vidHandle:SetVolume(Volume) end;
end
-- Pause if there is a music handle----------------------------------------- --
local function PauseMusic() if strmMusic then strmMusic:Stop() end end;
-- Resume music if there is a music handle---------------------------------- --
local function ResumeMusic() if strmMusic then strmMusic:Play(-1,1,0) end end
-- Stop music -------------------------------------------------------------- --
local function StopMusic(PosCmd)
  -- No current track? No problem
  if not strmMusic then return end;
  -- Save position?
  if 1 == PosCmd then
    -- Save position
    nMusicPosition = strmMusic:GetPosition();
    -- Save loop count
    iMusicLoops = strmMusic:GetLoop();
  end
  -- Resume video if there is one
  if vidHandle then vidHandle:Play() end;
  -- Stop music
  strmMusic = strmMusic:Stop();
end
-- ------------------------------------------------------------------------- --
local function PlayMusic(musicHandle, Volume, PosCmd, Loop, Start)
  -- Set default parameters that aren't specified
  if not UtilIsNumber(Volume) then Volume = 1 end;
  if not UtilIsInteger(PosCmd) then PosCmd = 0 end;
  if not UtilIsInteger(Loop) then Loop = -1 end;
  if not UtilIsInteger(Start) then Start = 0 end;
  -- Stop music
  StopMusic(PosCmd);
  -- Handle specified?
  if musicHandle then
    -- Set loop
    if Start then musicHandle:SetLoopBegin(Start) end;
    -- Pause video if there is one
    if vidHandle then vidHandle:Pause() end;
    -- Asked to restore position?
    if 2 == PosCmd and nMusicPosition and nMusicPosition > 0 then
      -- Restore position
      musicHandle:SetPosition(nMusicPosition);
      -- Play music
      musicHandle:SetLoop(iMusicLoops);
      -- Delete position and loop variable
      nMusicPosition, iMusicLoops = nil, nil;
    -- No restore position?
    else
      -- Play music from start
      musicHandle:SetPosition(0);
      -- Loop forever
      musicHandle:SetLoop(-1);
    end
    -- Set volume
    musicHandle:SetVolume(Volume);
    -- Play music
    musicHandle:Play();
    -- Set current track
    strmMusic = musicHandle;
  end
end
-- Render fade ------------------------------------------------------------- --
local function RenderFade(Amount, L, T, R, B, S)
  texSpr:SetCA(Amount);
  texSpr:BlitSLTRB(S or 1023, L or iStageLeft,  T or iStageTop,
                              R or iStageRight, B or iStageBottom);
  texSpr:SetCA(1);
end
-- Render shadow ----------------------------------------------------------- --
local function RenderShadow(iL, iT, iR, iB)
  -- Save colour
  texSpr:PushColour();
  -- Set shadow normal intensity
  texSpr:SetCRGBA(1, 1, 1, 0.5);
  -- Calculate starting position
  local iLM16<const>, iTM16<const> = iL-16, iT-16;
  -- Draw top part
  texSpr:BlitSLT(1016, iR, iT-12)
  -- Draw sides
  texSpr:BlitSLTRB(1018, iR, iT+4, iR+16, iB);
  -- Draw bottom part
  texSpr:BlitSLT(1019, iL-12, iB)
  texSpr:BlitSLTRB(1020, iL+4, iB, iR, iB+16);
  texSpr:BlitSLT(1021, iR, iB)
  -- Restore colour
  texSpr:PopColour();
end
-- Set bottom right tip ---------------------------------------------------- --
local function SetBottomRightTip(strTip)
  -- Draw the left side of the tip rect
  texSpr:BlitSLT(847, 232, 216);
  -- Draw the background of the tip rect
  for iColumn = 1, 3 do texSpr:BlitSLT(848, 232 + (iColumn * 16), 216) end;
  -- Draw the right of the tip rect
  texSpr:BlitSLT(849, 296, 216);
  -- Set tip colour
  fontLittle:SetCRGB(1, 1, 1);
  -- Print the tip
  fontLittle:PrintC(272, 220, strTip or "");
end
-- Set bottom right tip ---------------------------------------------------- --
local function SetBottomRightTipAndShadow(strTip)
  -- Draw the left side of the tip rect
  SetBottomRightTip(strTip);
   -- Render tip shadow
  RenderShadow(232, 216, 312, 232);
end
-- Bounds checking painter ------------------------------------------------- --
local function BCBlit(texHandle, iTexIndex, iLeft, iTop, iRight, iBottom)
  -- If not out of bounds draw the texture
  if min(iRight, iStageRight)   <= max(iLeft, iStageLeft) or
     min(iBottom, iStageBottom) <= max(iTop, iStageTop) then return end;
  texHandle:BlitSLTRB(iTexIndex, iLeft, iTop, iRight, iBottom);
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
-- Is fading --------------------------------------------------------------- --
local function IsFading() return not not fcbFading end;
-- Fade -------------------------------------------------------------------- --
local function Fade(S, E, C, D, A, M, L, T, R, B, Z)
  -- Check parameters
  if not UtilIsNumber(S) then
    error("Invalid starting value number! "..tostring(S)) end;
  if not UtilIsNumber(E) then
    error("Invalid ending value number! "..tostring(E)) end;
  if not UtilIsNumber(C) then
    error("Invalid fade inc/decremember value! "..tostring(C)) end
  if not UtilIsFunction(A) then
    error("Invalid after function! "..tostring(A)) end;
  -- If already fading, run the after function
  if UtilIsFunction(fcbFading) then fcbFading() end;
  -- Set loading cursor because player can't control anything
  SetCursor(aCursorIdData.WAIT);
  -- During function
  local function During(nVal)
    -- Clear states
    ClearStates();
    -- Call users during function
    D();
    -- Clamp new fade value
    S = UtilClamp(nVal, 0, 1);
    -- Render blackout
    RenderFade(S, L, T, R, B, Z);
    -- Fade music too
    if M then MusicVolume(1 - S) end;
  end
  -- Finished function
  local function Finish()
    -- Reset fade vars
    S, fcbFading = E, nil;
    -- No callbacks incase caller forgets to set anything
    SetCallbacks(nil, nil, nil);
    -- Set arrow incase caller forgets to set one
    SetCursor(aCursorIdData.ARROW);
    -- Call the after function
    A();
  end
  -- Cleanup function
  local function Clean()
    -- Garbage collect
    collectgarbage();
    -- Reset hi-res timer
    CoreCatchup();
  end
  -- Fade out?
  if S < E then
    -- Save old fade function
    fcbFading = A;
    -- Function during
    local function OnFadeOutFrame()
      -- Fade out
      During(S + C);
      -- Finished if we reached the ending point
      if S < E then return end;
      -- Cleanup
      Clean();
      -- Call finish function
      Finish()
    end
    -- Set fade out procedure
    SetCallbacks(nil, OnFadeOutFrame, nil);
  -- Fade in?
  elseif S > E then
    -- Cleanup
    Clean();
    -- Save old fade function
    fcbFading = A;
    -- Function during
    local function OnFadeInFrame()
      -- Fade in
      During(S - C);
      -- Finished if we reached the ending point
      if S <= E then Finish() end;
    end
    -- Set fade in procedure
    SetCallbacks(nil, OnFadeInFrame, nil);
  -- Ending already reached?
  else
    -- Cleanup
    Clean();
    -- Call finish function
    Finish();
  end
end
-- Get cursor -------------------------------------------------------------- --
local function GetCursor() return CId end;
-- Function to play sound at the specified pan ----------------------------- --
local function PlaySound(iSfxId, nPan, nPitch)
  aSounds[iSfxId]:Play(1, nPan, nPitch or 1, false);
end
-- Function to play sound with no panning ---------------------------------- --
local function PlayStaticSound(iSfxId, nGain, nPitch)
  aSounds[iSfxId]:Play(nGain or 1, 0, nPitch or 1, false);
end
-- Function to loop the specified sound at the specified pan --------------- --
local function LoopSound(iSfxId, nPan, nPitch)
  aSounds[iSfxId]:Play(1, nPan, nPitch or 1, true);
end
-- Function to loop the specified sound with no panning -------------------- --
local function LoopStaticSound(iSfxId, nGain, nPitch)
  aSounds[iSfxId]:Play(nGain or 1, 0, nPitch or 1, true);
end
-- Function to stop specified sound ---------------------------------------- --
local function StopSound(iSfxId) aSounds[iSfxId]:Stop() end;
-- Refresh viewport info --------------------------------------------------- --
local function RefreshViewportInfo()
  -- Refresh matrix parameters
  iStageWidth, iStageHeight,
    iStageLeft, iStageTop, iStageRight, iStageBottom = fboMain:GetMatrix();
  -- Floor all the values as the main frame buffer object is always on the
  -- pixel boundary
  iStageWidth, iStageHeight, iStageLeft, iStageTop, iStageRight, iStageBottom =
    floor(iStageWidth), floor(iStageHeight), floor(iStageLeft),
    floor(iStageTop), floor(iStageRight), floor(iStageBottom);
  -- Clamp mouse cursor into stage
  if     iCursorX  < iStageLeft   then iCursorX = iStageLeft;
  elseif iCursorY  < iStageTop    then iCursorY = iStageTop end;
  if     iCursorX >= iStageRight  then iCursorX = iStageRight-1;
  elseif iCursorY >= iStageBottom then iCursorY = iStageBottom-1 end;
  -- Call frame buffer callbacks
  for _, fcbC in pairs(fcbFrameBufferCallbacks) do
    fcbC(iStageWidth, iStageHeight,
      iStageLeft, iStageTop, iStageRight, iStageBottom) end;
end
-- Register a callback and automatically when window size changes ---------- --
local function RegisterFrameBufferUpdateCallback(sName, fCB)
  -- Check parameters
  if not UtilIsString(sName) then
    error("Invalid callback name string! "..tostring(sName)) end;
  if nil ~= fCB and not UtilIsFunction(fCB) then
    error("Invalid callback function! "..tostring(fCB)) end;
  -- Register callback when frame buffer is updated
  fcbFrameBufferCallbacks[sName] = fCB;
  -- If a callback was set then call it
  if nil ~= fCB then fCB(iStageWidth, iStageHeight,
    iStageLeft, iStageTop, iStageRight, iStageBottom) end;
end
-- Returns wether test mode is enabled ------------------------------------- --
local function GetTestMode() return bTestMode end;
-- Refresh viewport info and automatically when window size changes
RefreshViewportInfo();
Fbo.OnRedraw(RefreshViewportInfo);
-- Setup a default sprite set until the real sprite is loaded since we are
-- loading everything asynchronously.
texSpr = TextureCreate(Image.Blank("placeholder", 1, 1, false, true), 0);
texSpr:TileSTC(1024);
-- Initialise viewport and cursor
InputSetCursor(false);
-- Initialise function callbacks
SetCallbacks(nil, nil, nil);
-- The first tick function
local function fcbTick()
  -- Empty callback function for CVar events
  local function fcbEmpty() return true end;
  -- Register file data CVar
  local aCVF<const> = Variable.Flags;
  -- Default CVar flags for string storage
  local iCFR<const> = aCVF.STRINGSAVE|aCVF.TRIM|aCVF.PROTECTED|aCVF.DEFLATE;
  -- Default CVar flags for boolean storage
  local iCFB<const> = aCVF.BOOLEANSAVE;
  -- Initialise base API functions
  aAPI = {
    GetKeyState = GetKeyState, ClearKeyState = ClearKeyState,
    IsMouseInBounds = IsMouseInBounds, IsMouseNotInBounds = IsMouseNotInBounds,
    IsMouseXLessThan = IsMouseXLessThan,
    IsMouseXGreaterEqualThan = IsMouseXGreaterEqualThan,
    IsMouseYLessThan = IsMouseYLessThan,
    IsMouseYGreaterEqualThan = IsMouseYGreaterEqualThan,
    GetMouseX = GetMouseX, GetMouseY = GetMouseY,
    IsScrollingLeft = IsScrollingLeft, IsScrollingRight = IsScrollingRight,
    IsScrollingUp = IsScrollingUp, IsScrollingDown = IsScrollingDown,
    GetMouseState = GetMouseState, ClearMouseState = ClearMouseState,
    IsMouseHeld = IsMouseHeld, IsMousePressed = IsMousePressed,
    IsMousePressedNoRelease = IsMousePressedNoRelease,
    IsMouseReleased = IsMouseReleased, GetJoyState = GetJoyState,
    IsJoyPressed = IsJoyPressed, IsJoyHeld = IsJoyHeld,
    IsJoyReleased = IsJoyReleased, IsButtonPressed = IsButtonPressed,
    IsButtonPressedNoRelease = IsButtonPressedNoRelease,
    IsButtonHeld = IsButtonHeld, IsButtonReleased = IsButtonReleased,
    IsKeyReleased = IsKeyReleased, IsKeyPressed = IsKeyPressed,
    IsKeyRepeating = IsKeyRepeating, IsKeyHeld = IsKeyHeld,
    SetCursor = SetCursor, SetGlobalKeys = SetGlobalKeys,
    GetCallbacks = GetCallbacks, SetCallbacks = SetCallbacks,
    LoadResources = LoadResources, VideoStop = VideoStop,
    VideoPlay = VideoPlay, GetMusic = GetMusic,
    MusicVolume = MusicVolume, PauseMusic = PauseMusic,
    ResumeMusic = ResumeMusic, StopMusic = StopMusic, PlayMusic = PlayMusic,
    TimeIt = TimeIt, RenderFade = RenderFade, BCBlit = BCBlit,
    ClearStates = ClearStates, Fade = Fade, GetCursor = GetCursor,
    RefreshViewportInfo = RefreshViewportInfo, PlaySound = PlaySound,
    PlayStaticSound = PlayStaticSound, LoopSound = LoopSound,
    LoopStaticSound = LoopStaticSound, StopSound = StopSound,
    IsFading = IsFading, SetBottomRightTip = SetBottomRightTip,
    RegisterFBUCallback = RegisterFrameBufferUpdateCallback,
    GetTestMode = GetTestMode, RenderShadow = RenderShadow,
    SetBottomRightTipAndShadow = SetBottomRightTipAndShadow
  };
  -- 4 save slots so 4 save variables
  for iI = 1, 4 do
    aAPI["VarGameData"..iI] =
      VariableRegister("gam_data"..iI, "", iCFR, fcbEmpty);
  end
  -- ...and a CVar that lets us show setup for the first time
  aAPI.VarGameSetup = VariableRegister("gam_setup", 1, iCFB, fcbEmpty);
  -- ...and a CVar that lets us skip the intro
  aAPI.VarGameIntro = VariableRegister("gam_intro", 1, iCFB, fcbEmpty);
  -- ...and a CVar that lets us start straight into a level
  aAPI.VarGameTest = VariableRegister("gam_test", "", aCVF.STRING, fcbEmpty);
  -- Data script loaded event
  local function DataLoaded()
    aCursorIdData, aCursorData = aAPI.aCursorIdData, aAPI.aCursorData;
  end;
  -- Base code scripts that are to be loaded
  local aBaseScripts<const> = {
    {T=9,F="bank",   P={}}, {T=9,F="book",  P={}}, {T=9,F="cntrl", P={}},
    {T=9,F="credits",P={}}, {T=9,F="data",  P={},A=DataLoaded },
    {T=9,F="debug",  P={}}, {T=9,F="end",   P={}}, {T=9,F="ending",P={}},
    {T=9,F="fail",   P={}}, {T=9,F="file",  P={}}, {T=9,F="game",  P={}},
    {T=9,F="intro",  P={}}, {T=9,F="lobby", P={}}, {T=9,F="map",   P={}},
    {T=9,F="post",   P={}}, {T=9,F="race",  P={}}, {T=9,F="scene", P={}},
    {T=9,F="score",  P={}}, {T=9,F="setup", P={}}, {T=9,F="shop",  P={}},
    {T=9,F="title",  P={}}, {T=9,F="tntmap",P={}},
  };
  -- Base fonts that are to be loaded
  local aBaseFonts<const> = {
    {T=3,F="font16", P={}}, {T=3,F="font8",  P={}},
    {T=3,F="font5",  P={}}, {T=3,F="font10", P={}},
  };
  -- Base textures that are to be loaded
  local aBaseTextures<const> = {
    {T=1,F="sprites", P={16,16,0,0,0}},
  };
  -- Base masks that are to be loaded
  local aBaseMasks<const> = {
    {T=6,F="lmask", P={16,16}},
    {T=6,F="smask", P={16,16}}
  };
  -- Base sound effects that are to be loaded
  local aBaseSounds<const> = {
    {T=4,F="click",   P={}}, {T=4,F="dftarg",  P={}}, {T=4,F="dgrablin",P={}},
    {T=4,F="dhabbish",P={}}, {T=4,F="dquarior",P={}}, {T=4,F="dig",     P={}},
    {T=4,F="alert",   P={}}, {T=4,F="tnt",     P={}}, {T=4,F="gem",     P={}},
    {T=4,F="gclose",  P={}}, {T=4,F="gopen",   P={}}, {T=4,F="jump",    P={}},
    {T=4,F="punch",   P={}}, {T=4,F="teleport",P={}}, {T=4,F="kick",    P={}},
    {T=4,F="select",  P={}}, {T=4,F="sale",    P={}}, {T=4,F="switch",  P={}},
    {T=4,F="hololoop",P={}}, {T=4,F="holo",    P={}}
  }
  -- Add all these to all the base assets to load
  local aBaseAssetsCategories<const> =
    { aBaseScripts, aBaseFonts, aBaseTextures, aBaseMasks, aBaseSounds };
  -- Build base assets to load
  local aBaseAssets<const> = { };
  for iBaseIndex = 1, #aBaseAssetsCategories do
    local aAssets<const> = aBaseAssetsCategories[iBaseIndex];
    for iAssetIndex = 1, #aAssets do
      aBaseAssets[1 + #aBaseAssets] = aAssets[iAssetIndex];
    end
  end
  -- Calculate starting indexes of each base asset
  local iBaseScripts<const> = 1;
  local iBaseFonts<const> = iBaseScripts + #aBaseScripts;
  local iBaseTextures<const> = iBaseFonts + #aBaseFonts;
  local iBaseMasks<const> = iBaseTextures + #aBaseTextures;
  local iBaseSounds<const> = iBaseMasks + #aBaseMasks;
  -- When base assets have loaded
  local function OnLoaded(aData)
    -- Set font handles
    fontLarge, fontLittle, fontTiny, fontSpeech =
      aData[iBaseFonts].H, aData[iBaseFonts + 1].H,
      aData[iBaseFonts + 2].H, aData[iBaseFonts + 3].H;
    aAPI.fontLarge, aAPI.fontLittle, aAPI.fontTiny, aAPI.fontSpeech =
      fontLarge, fontLittle, fontTiny, fontSpeech;
    -- Set sprites texture
    texSpr = aData[iBaseTextures].H;
    aAPI.texSpr = texSpr;
    -- Set masks
    aAPI.maskLevel, aAPI.maskSprites = aData[iBaseMasks].H,
      aData[iBaseMasks + 1].H;
    -- Function to grab an API function. This function will be sent to all
    -- the above loaded modules.
    local function GetAPI(...)
      -- Get functions and if there is only one then return it
      local tFuncs<const> = { ... }
      if #tFuncs == 0 then error("No functions specified to check") end;
      -- Functions already added
      local aAdded<const> = { };
      -- Find each function specified and return all of them
      local tRets<const> = { };
      for iI = 1, #tFuncs do
        -- Check parameter
        local sMember<const> = tFuncs[iI];
        if not UtilIsString(sMember) then
          error("Function name at "..iI.." is invalid") end;
        -- Check if we already cached this member and if already have it?
        local iCached<const> = aAdded[sMember];
        if iCached ~= nil then
          -- Print an error so we can remove duplicates
          error("Member '"..sMember.."' at parameter "..iI..
            " already requested at parameter "..iCached.."!");
        end
        -- Get the function callback and if it's a function?
        local vMember<const> = aAPI[sMember];
        if vMember == nil then
          -- So instead of just throwing an error here, we will just silently
          -- accept the request, but the callback will be our own callback that
          -- will throw the error, this way, there is no error spam during
          -- initialisation.
          error("Invalid member '"..sMember.."'! "..tostring(vMember));
        end
        -- Cache function so we can track duplicated
        aAdded[sMember] = iI;
        -- Add it to returns
        tRets[1 + #tRets] = vMember;
      end
      -- Unpack returns table and return all the functions requested
      return unpack(tRets);
    end
    -- Ask modules to grab needed functions from the API
    for iI = 1, #aModules do
      local aModData<const> = aModules[iI];
      aModData.F(GetAPI, aModData);
    end
    -- Assign and check sound effects
    for iSHIndex = iBaseSounds, iBaseSounds + #aBaseSounds - 1 do
      aSounds[1 + #aSounds] = aData[iSHIndex].H end
    if #aBaseSounds ~= #aSounds then
      error("Only "..#aBaseSounds.." of "..aSounds.." sound effects!") end;
    -- Main procedure callback
    local function MainCallback()
      -- Update mouse position
      fcbMouse();
      -- Check global keys
      CheckGlobalKeys();
      -- Execute input, tick and render callbacks
      CBInput();
      CBProc();
      CBRender();
      -- Draw mouse cursor
      texSpr:BlitSLT(CoreTicks() // 4 % CursorMax + CursorMin,
        iCursorX + CursorOX, iCursorY + CursorOY);
      -- Draw screen at end of LUA tick
      FboDraw();
    end
    -- Set main callback
    fcbTick = MainCallback;
    -- Load functions
    InitSetup, InitScene, InitScore, InitCredits, InitEnding, LoadLevel,
      InitIntro, InitTitle, InitFail, aLevelsData, aRacesData, aObjectTypes,
      InitNewGame, InitDebugPlay =
        GetAPI("InitSetup", "InitScene", "InitScore", "InitCredits",
          "InitEnding", "LoadLevel", "InitIntro", "InitTitle", "InitFail",
          "aLevelsData", "aRacesData", "aObjectTypes", "InitNewGame",
          "InitDebugPlay");
    -- Init game counters so testing stuff quickly works properly
    InitNewGame();
    -- Tests
    local sTestValue<const> = aAPI.VarGameTest:Get();
    if #sTestValue > 0 then
      -- Test mode enabled
      bTestMode = true;
      -- Get start level
      local iStartLevel<const> = tonumber(sTestValue) or 0;
      -- Test random level?
      if iStartLevel == 0 then return LoadLevel(random(#aLevelsData), "game");
      -- Testing infinite play mode?
      elseif iStartLevel == -1 then return InitDebugPlay();
      -- Testing the fail screen
      elseif iStartLevel == -2 then return InitFail();
      -- Testing the game over
      elseif iStartLevel == -3 then return InitScore();
      -- Testing the credits
      elseif iStartLevel == -4 then return InitCredits(false);
      -- Testing the rolling credits
      elseif iStartLevel == -5 then return InitCredits(true);
      -- Testing a races ending
      elseif iStartLevel > -10 and iStartLevel <= -6 then
        return InitEnding(#aRacesData + (-10 - iStartLevel));
      elseif iStartLevel <= #aLevelsData then
        return LoadLevel(iStartLevel, "game");
      elseif iStartLevel > #aLevelsData and iStartLevel <= #aLevelsData*2 then
        return InitScene(iStartLevel-#aLevelsData, "game");
      end
    end
    -- If being run for first time
    if aAPI.VarGameSetup:Get() == "0" then
      -- Skip intro? Initialise title screen
      if aAPI.VarGameIntro:Get() == "0" then return InitTitle() end;
      -- Initialise intro with setup dialog
      return InitIntro(false);
    end
    -- Set initial cursor position
    iCursorX, iCursorY = 0, 0;
    InputSetCursorPos(0, 0);
    -- Initialise setup screen by default
    InitIntro(true);
    -- No longer show setup screen
    aAPI.VarGameSetup:Set(0);
  end
  -- Start loading assets
  local fcbProgress<const> = LoadResources("Core", aBaseAssets, OnLoaded);
  -- Get console font and do positional calculations
  local fSolid<const> = TextureCreate(Image.Colour(0xFFFFFFFF), 0);
  local iWidth<const>, iHeight<const>, iBorder<const> = 300, 2, 1;
  local iX<const> = 160-(iWidth/2)-iBorder;
  local iY<const> = 120-(iHeight/2)-iBorder;
  local iBorderX2<const> = iBorder*2;
  local iXPlus1<const>, iYPlus1<const> = iX+iBorder, iY+iBorder;
  local iXBack<const> = iX+iWidth+iBorderX2
  local iYBack<const> = iY+iHeight+iBorderX2;
  local iXBack2<const> = iX+iWidth+iBorder;
  local iYBack2<const> = iY+iHeight+(iBorderX2-iBorder);
  local iXText<const>, iYText<const> = iX+iWidth+iBorderX2, iY - 12;
  -- Last percentage
  local nLastPercentage = -1;
  -- Loader display function
  local function LoaderProc()
    -- Get current progress and return if progress hasn't changed
    local nPercent<const>, sFile<const> = fcbProgress();
    if nPercent == nLastPercentage then return end;
    nLastPercentage = nPercent;
    -- Draw progress bar
    fSolid:SetCRGBA(1, 0, 0, 1);        -- Border
    fSolid:BlitLTRB(iX, iY, iXBack, iYBack);
    fSolid:SetCRGBA(0.25, 0, 0, 1);     -- Backdrop
    fSolid:BlitLTRB(iXPlus1, iYPlus1, iXBack2, iYBack2);
    fSolid:SetCRGBA(1, 1, 1, 1);        -- Progress
    fSolid:BlitLTRB(iXPlus1, iYPlus1, iXPlus1+(nPercent*iWidth), iYBack2);
    fFont:SetCRGBA(1, 1, 1, 1);         -- Filename & percentage
    fFont:SetSize(1);
    fFont:Print(iX, iYText, sFile);
    fFont:PrintR(iXText, iYText, format("%.f%% Completed", nPercent*100));
    -- Catchup accumulator (we don't care about it);
    CoreCatchup();
    -- Draw screen at end of LUA tick
    FboDraw();
  end
  -- Set new tick function
  fcbTick = LoaderProc;
end;
-- Main callback with smart error handling --------------------------------- --
local function MainProc()
  -- Protected call so we can handle errors
  local bResult<const>, sReason<const> = xpcall(fcbTick, CoreStack);
  if not bResult then SetErrorMessage(sReason) end;
end
-- This will be the main entry procedure ----------------------------------- --
CoreOnTick(MainProc);
-- End-of-File ============================================================= --

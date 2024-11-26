-- MAIN.LUA ================================================================ --
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
local collectgarbage<const>, error<const>, floor<const>, format<const>,
  max<const>, min<const>, pairs<const>, random<const>, remove<const>,
  tonumber<const>, tostring<const>, unpack<const> =
    collectgarbage, error, math.floor, string.format, math.max, math.min,
    pairs, math.random, table.remove, tonumber, tostring, table.unpack;
-- M-Engine aliases (optimisation) ----------------------------------------- --
local AssetParseBlock<const>, CoreLog<const>, CoreOnTick<const>,
  CoreStack<const>, CoreWrite<const>, FboDraw<const>,
  CoreCatchup<const>, InputSetCursor<const>,
  CoreTime<const>, TextureCreate<const>, UtilBlank<const>,
  UtilClamp<const>, UtilDuration<const>, UtilExplode<const>,
  UtilImplode<const>, UtilIsFunction<const>, UtilIsInteger<const>,
  UtilIsNumber<const>, UtilIsString<const>, UtilIsTable<const>,
  VariableRegister<const> =
    Asset.ParseBlock, Core.Log, Core.OnTick, Core.Stack, Core.Write,
    Fbo.Draw, Core.Catchup, Input.SetCursor,
    Core.Time, Texture.Create, Util.Blank,
    Util.Clamp, Util.Duration, Util.Explode, Util.Implode, Util.IsFunction,
    Util.IsInteger, Util.IsNumber, Util.IsString, Util.IsTable,
    Variable.Register;
-- Locals ------------------------------------------------------------------ --
local fboMain<const> = Fbo.Main();     -- Main frame buffer object class
local fFont<const> = Font.Console();   -- Main console class
local aKeys<const> = Input.KeyCodes;   -- Keyboard codes
local CBProc, CBRender, CBInput;       -- Generic tick callbacks
local fcbFrameBufferCbs<const> = { };  -- Frame buffer updated function
local iCursorArrow, iCursorWait;       -- Cursor ids for arrow and wait
local aAPI<const>         = { };       -- API to send to other functions
local aCache              = { };       -- File cache
local aModules<const>     = { };       -- Modules data
local bTestMode           = false;     -- Test mode enabled
local fcbFading           = false;     -- Fading callback
local texSpr;                          -- Sprites texture
local fontLarge;                       -- Large font (16px)
local fontLittle;                      -- Little font (8px)
local fontTiny;                        -- Tiny font (5px)
local fontSpeech;                      -- Speech font (10px)
-- Stage dimensions -------------------------------------------------------- --
local iStageWidth  = 320;              -- Width of stage
local iStageHeight = 240;              -- Height of stage
local iStageLeft   = 0;                -- Left of stage
local iStageTop    = 0;                -- Top of stage
local iStageRight  = iStageWidth;      -- Right of stage
local iStageBottom = iStageHeight;     -- Bottom of stage
-- Library functions loaded later ------------------------------------------ --
local aLevelsData, aObjectTypes, aRacesData, ClearStates, InitCredits,
  InitTitleCredits, InitDebugPlay, InitEnding, InitFail, InitIntro,
  InitNewGame, InitScene, InitScore, InitTitle, JoystickProc, LoadLevel,
  MusicVolume;
-- These could be called even though they aren't initialised yet ----------- --
local SetKeys, SetCursor = UtilBlank, UtilBlank;
-- Constants for loader ---------------------------------------------------- --
local aBFlags<const> = Image.Flags;    -- Get bitmap loading flags
local iPNG<const> = aBFlags.FCE_PNG;   -- Get forced PNG format flag
local aPFlags<const> = Pcm.Flags;      -- Get waveform loading flags
local iOGG<const> = aPFlags.FCE_OGG;   -- Get forced wave format
local aPrFlags<const> = Asset.Progress;-- Asset progress flags
local iFStart<const> = aPrFlags.FILESTART; -- File opened with information
-- Generic function to return a handle ------------------------------------- --
local function GenericReturnHandle(hH) return hH end;
-- Parse the return value of a script -------------------------------------- --
local function ParseScriptResult(sName, aModData)
  -- Check parameters
  if not UtilIsString(sName) then error("Bad name: "..tostring(sName)) end;
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
end
-- Function to parse a script ---------------------------------------------- --
local function ParseScript(aScript)
  -- Get name of module
  local sName<const> = aScript:Name();
  -- Compile the script and parse the return value
  ParseScriptResult(sName, AssetParseBlock(sName, 1, aScript));
  -- Return success
  return true;
end
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
  -- Get key states
  local iRelease<const> = Input.States.RELEASE;
  -- Keys used in tick function
  local iKeyC<const>, iKeyR<const>, iKeyX<const> = aKeys.C, aKeys.R, aKeys.X;
  -- Input event callback
  local function OnKey(iKey, iState)
    -- Ignore if not releasing a key
    if iState ~= iRelease then return end;
    -- Check for pressed keys from instructions
    if     iKey == iKeyC then return Util.ClipSet(sFullReason);
    elseif iKey == iKeyR then return Core.Reset();
    elseif iKey == iKeyX then return Core.Quit() end;
  end
  -- Override current input funciton
  Input.OnKey(OnKey);
  -- Second change bool
  local nNext = 0;
  -- Callback function
  local function OnTick()
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
local function LoadResources(sProcedure, aResources, fComplete, ...)
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
  -- Grab extra parameters to send to callback
  local aParams<const> = { ... };
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
      SetCursor(iCursorArrow);
      -- Enable global keys
      SetKeys(true);
      -- Garbage collect to remove unloaded assets
      collectgarbage();
      -- Execute finished handler function with our resource list
      TimeIt(sProcedure, fComplete, aResources, unpack(aParams));
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
  SetKeys(false);
  -- Clear callbacks but keep the last render callback
  SetCallbacks(nil, CBRender, nil);
  -- Set loading cursor
  SetCursor(iCursorWait);
  -- Initialise counters
  iTotal, iLoaded = #aResources, 0;
  -- Load first item
  LoadItem(1);
  -- Progress function
  local function GetProgress() return iLoaded/iTotal, sDst end
  -- Return progress function
  return GetProgress;
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
  -- Return if draw is not in bounds (occlusion)
  if min(iRight, iStageRight)   <= max(iLeft, iStageLeft) or
     min(iBottom, iStageBottom) <= max(iTop, iStageTop) then return end;
  texHandle:BlitSLTRB(iTexIndex, iLeft, iTop, iRight, iBottom);
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
  SetCursor(iCursorWait);
  -- Disable all keybanks and globals
  SetKeys(false);
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
    -- Set arrow incase caller forgets to set one
    SetCursor(iCursorArrow);
    -- Enable global keys
    SetKeys(true);
    -- No callbacks incase caller forgets to set anything
    SetCallbacks(nil, nil, nil);
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
  -- Call frame buffer callbacks
  for _, fcbC in pairs(fcbFrameBufferCbs) do
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
  fcbFrameBufferCbs[sName] = fCB;
  -- If a callback was set then call it
  if nil ~= fCB then fCB(iStageWidth, iStageHeight,
    iStageLeft, iStageTop, iStageRight, iStageBottom) end;
end
-- Returns wether test mode is enabled ------------------------------------- --
local function GetTestMode() return bTestMode end;
-- The first tick function
local function fcbTick()
  -- Refresh viewport info and automatically when window size changes
  Fbo.OnRedraw(RefreshViewportInfo);
  RefreshViewportInfo();
  -- Initialise base API functions
  ParseScriptResult("main", { F=UtilBlank, A={ BCBlit = BCBlit, Fade = Fade,
    GetCallbacks = GetCallbacks, GetTestMode = GetTestMode,
    IsFading = IsFading, LoadResources = LoadResources,
    RefreshViewportInfo = RefreshViewportInfo,
    RegisterFBUCallback = RegisterFrameBufferUpdateCallback,
    RenderFade = RenderFade, RenderShadow = RenderShadow,
    SetBottomRightTip = SetBottomRightTip,
    SetBottomRightTipAndShadow = SetBottomRightTipAndShadow,
    SetErrorMessage = SetErrorMessage, SetCallbacks = SetCallbacks,
    TimeIt = TimeIt } });
  -- Empty callback function for CVar events
  local function fcbEmpty() return true end;
  -- Register file data CVar
  local aCVF<const> = Variable.Flags;
  -- Default CVar flags for string storage
  local iCFR<const> = aCVF.STRINGSAVE|aCVF.TRIM|aCVF.PROTECTED|aCVF.DEFLATE;
  -- Default CVar flags for boolean storage
  local iCFB<const> = aCVF.BOOLEANSAVE;
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
  -- Setup a default sprite set until the real sprite is loaded since we are
  -- loading everything asynchronously.
  texSpr = TextureCreate(Image.Blank("placeholder", 1, 1, false, true), 0);
  texSpr:TileSTC(1024);
  -- Initialise function callbacks
  SetCallbacks(nil, nil, nil);
  -- Base code scripts that are to be loaded (setup must be last)
  local aBaseScripts<const> = {
    {T=9,F="audio",  P={}}, {T=9,F="bank",    P={}}, {T=9,F="book",     P={}},
    {T=9,F="cntrl",  P={}}, {T=9,F="credits", P={}}, {T=9,F="data",     P={}},
    {T=9,F="debug",  P={}}, {T=9,F="end",     P={}}, {T=9,F="ending",   P={}},
    {T=9,F="fail",   P={}}, {T=9,F="file",    P={}}, {T=9,F="game",     P={}},
    {T=9,F="input",  P={}}, {T=9,F="intro",   P={}}, {T=9,F="lobby",    P={}},
    {T=9,F="map",    P={}}, {T=9,F="pause",   P={}}, {T=9,F="post",     P={}},
    {T=9,F="race",   P={}}, {T=9,F="scene",   P={}}, {T=9,F="score",    P={}},
    {T=9,F="shop",   P={}}, {T=9,F="title",   P={}}, {T=9,F="tcredits", P={}},
    {T=9,F="tntmap", P={}}, {T=9,F="setup",   P={}},
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
    -- Load dependecies we need on this module
    aLevelsData, aObjectTypes, aRacesData, ClearStates, InitCredits,
      InitDebugPlay, InitEnding, InitFail, InitIntro, InitNewGame, InitScene,
      InitScore, InitTitle, InitTitleCredits, JoystickProc, LoadLevel,
      MusicVolume, SetCursor, SetKeys =
        GetAPI("aLevelsData", "aObjectTypes", "aRacesData", "ClearStates",
          "InitCredits", "InitDebugPlay", "InitEnding", "InitFail",
          "InitIntro", "InitNewGame", "InitScene", "InitScore", "InitTitle",
          "InitTitleCredits", "JoystickProc", "LoadLevel", "MusicVolume",
          "SetCursor", "SetKeys");
    -- Assign loaded sound effects (audio.hpp)
    GetAPI("RegisterSounds")(aData, iBaseSounds, #aBaseSounds);
    -- We need the cursor ids for the arrow and waiting (input.hpp)
    local aCursorIdData<const> = GetAPI("aCursorIdData");
    iCursorArrow = aCursorIdData.ARROW;
    iCursorWait = aCursorIdData.WAIT;
    -- Get cursor render function (input.hpp)
    local CursorRender<const> = aAPI.CursorRender;
    -- Main procedure callback
    local function MainCallback()
      -- Poll joysticks (input.hpp)
      JoystickProc();
      -- Execute input, tick and render callbacks
      CBInput();
      CBProc();
      CBRender();
      -- Draw mouse cursor (input.hpp)
      CursorRender();
      -- Draw screen at end of LUA tick
      FboDraw();
    end
    -- Set main callback
    fcbTick = MainCallback;
    -- Init game counters so testing stuff quickly works properly
    InitNewGame();
    -- Hide the cursor
    InputSetCursor(false);
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
      -- Testing the final credits
      elseif iStartLevel == -4 then return InitCredits(false);
      -- Testing the final rolling credits
      elseif iStartLevel == -5 then return InitCredits(true);
      -- Testing the title screen rolling credits
      elseif iStartLevel == -6 then return InitTitleCredits();
      -- Testing a races ending
      elseif iStartLevel > -11 and iStartLevel <= -7 then
        return InitEnding(#aRacesData + (-11 - iStartLevel));
      -- Reserved for testing map post mortem maybe (todo)
      elseif iStartLevel <= -11 then
      -- Test a specific lvel
      elseif iStartLevel <= #aLevelsData then
        return LoadLevel(iStartLevel, "game");
      -- Test a specific level with starting scene
      elseif iStartLevel > #aLevelsData and iStartLevel <= #aLevelsData*2 then
        return InitScene(iStartLevel-#aLevelsData, "game");
      end
    end
    -- If being run for first time
    if 0 == tonumber(aAPI.VarGameSetup:Get()) then
      -- Skip intro? Initialise title screen
      if 0 == tonumber(aAPI.VarGameIntro:Get()) then return InitTitle() end;
      -- Initialise intro with setup dialog
      return InitIntro(false);
    end
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

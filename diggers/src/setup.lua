-- SETUP.LUA =============================================================== --
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
-- Core function aliases --------------------------------------------------- --
local cos<const>, floor<const>, format<const>, ipairs<const>, len<const>,
  maxinteger<const>, max<const>, min<const>, pairs<const>, remove<const>,
  rep<const>, sin<const>, sort<const>, tonumber<const>, tostring<const> =
    math.cos, math.floor, string.format, ipairs, utf8.len, math.maxinteger,
    math.max, math.min, pairs, table.remove, string.rep, math.sin, table.sort,
    tonumber, tostring;
-- M-Engine function and variable aliases ---------------------------------- --
local AudioGetNumPBDs<const>, AudioGetPBDName<const>, AudioReset<const>,
  CoreCPUUsage<const>, CoreEngine<const>, CoreLibrary<const>,
  CoreLicense<const>, CoreRAM<const>, CoreTime<const>, DisplayFSType<const>,
  DisplayGetSize<const>, DisplayGPUFPS<const>, DisplayMonitor<const>,
  DisplayMonitorData<const>, DisplayMonitors<const>, DisplayReset<const>,
  DisplayVidModeData<const>, DisplayVidModes<const>, DisplayVReset<const>,
  InputGetKeyName<const>, InputOnKey<const>, UtilClamp<const>,
  UtilClampInt<const>, UtilExplode<const>, UtilGetRatio<const>,
  UtilWordWrap<const>, VariableGetInt<const>, VariableRegister<const>,
  VariableResetInt<const>, VariableSetInt<const>, aCVars<const>, aKeys<const>,
  aMods<const>, aStates<const>, iCredits<const>, iNativeMode<const> =
    Audio.GetNumPBDevices, Audio.GetPBDeviceName, Audio.Reset, Core.CPUUsage,
    Core.Engine, Core.Library, Core.License, Core.RAM, Core.Time,
    Display.FSType, Display.GetSize, Display.GPUFPS, Display.Monitor,
    Display.MonitorData, Display.Monitors, Display.Reset, Display.VidModeData,
    Display.VidModes, Display.VReset, Input.GetKeyName, Input.OnKey,
    Util.Clamp, Util.ClampInt, Util.Explode, Util.GetRatio, Util.WordWrap,
    Variable.GetInt, Variable.Register, Variable.ResetInt, Variable.SetInt,
    Variable.Internal, Input.KeyCodes, Input.KeyMods, Input.States,
    Core.Libraries.MAX, Display.FSTypes.NATIVE;
-- Read and prepare engine version information ----------------------------- --
local sAppTitle, sAppVendor, iAppMajor<const>, iAppMinor<const>,
  iAppBuild<const>, iAppRevision<const>, _, _, sAppExeType = CoreEngine();
sAppTitle, sAppVendor, sAppExeType =
  sAppTitle:upper(), sAppVendor:upper(), sAppExeType:upper();
-- Read game version information ------------------------------------------- --
local sGameVersion<const>, sGameName<const>, sGameCopyr<const>,
      sGameDescription<const>, sGameWebsite<const>
      = -- ----------------------------------------------------------------- --
      VariableGetInt(aCVars.app_version):upper(),
      VariableGetInt(aCVars.app_longname):upper(),
      VariableGetInt(aCVars.app_copyright):upper(),
      VariableGetInt(aCVars.app_description):upper(),
      VariableGetInt(aCVars.app_website):upper();
-- Other CVars used -------------------------------------------------------- --
local iCVvidvsync<const>, iCVappdelay<const>, iCVtexfilter<const>,
      iCVaudvol<const>, iCVaudstrvol<const>, iCVaudsamvol<const>,
      iCVaudfmvvol<const>, iCVvidmonitor<const>, iCVwinwidth<const>,
      iCVwinheight<const>, iCVvidfs<const>, iCVvidfsmode<const>,
      iCVaudinterface
      = -- ----------------------------------------------------------------- --
      aCVars.vid_vsync, aCVars.app_delay, aCVars.vid_texfilter, aCVars.aud_vol,
      aCVars.aud_strvol, aCVars.aud_samvol, aCVars.aud_fmvvol,
      aCVars.vid_monitor, aCVars.win_width, aCVars.win_height, aCVars.vid_fs,
      aCVars.vid_fsmode, aCVars.aud_interface;
-- Diggers function and data aliases --------------------------------------- --
local DisableKeyHandlers, GetCallbacks, GetCursor, GetKeyBank, GetMouseY,
  GetMusic, InitSetup, IsButtonHeld, IsButtonPressed, IsMouseInBounds,
  IsMouseYGreaterEqualThan, IsMouseYLessThan, IsScrollingDown, IsScrollingLeft,
  IsScrollingRight, IsScrollingUp, LoadResources, PlayMusic, PlayStaticSound,
  RegisterFBUCallback, RegisterKeys, RenderFade, RenderShadow,
  RestoreKeyHandlers, SetCallbacks, SetCursor, SetKeys, StopMusic,
  aKeyBankCats, aKeyToLiteral, aSetupButtonData, aSetupOptionData, fontLarge,
  fontLittle, fontTiny, texSpr;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 7, F = "setup" } };
-- Frame-limiter types ----------------------------------------------------- --
local aFrameLimiterLabels<const> = {
  "Adaptive VSync",                    -- VSync = -1; Delay = 0
  "None",                              -- VSync =  0; Delay = 0
  "VSync Only",                        -- VSync =  1; Delay = 0
  "Double VSync",                      -- VSync =  2; Delay = 0
  "Adaptive VSync & Suspend",          -- VSync = -1; Delay = 1
  "Suspend Only",                      -- VSync =  0; Delay = 1
  "VSync & Suspend",                   -- VSync =  1; Delay = 1
  "Double VSync & Suspend",            -- VSync =  2; Delay = 1
};
-- Window types ------------------------------------------------------------ --
local aWindowLabels<const> = {
  "Windowed Mode", "Borderless Full-screen Mode", "Exclusive Full-screen Mode",
  "Native Full-screen Mode"
};
-- Custom window size labels ----------------------------------------------- --
local aCustomLabels<const> = { "<Custom>", "<Auto>" };
-- Window sizes ------------------------------------------------------------ --
local aWindowSizes<const> = {          -- Keep to arbitrary aspect ratios
  {   0,   0}, --[[ Default (auto)  --]] { 320, 240}, --[[ ( 4:3 ) QVGA    --]]
  { 480, 360}, --[[ ( 4:3 ) Trivial --]] { 512, 384}, --[[ ( 4:3 ) 0.20M3  --]]
  { 640, 360}, --[[ (16:9 ) 0.23M9  --]] { 640, 400}, --[[ (16:10) 0.26M3  --]]
  { 640, 480}, --[[ ( 4:3 ) 0.29M4  --]] { 720, 540}, --[[ ( 4:3 ) Trivial --]]
  { 768, 480}, --[[ (16:10) WVGA    --]] { 800, 600}, --[[ ( 4:3 ) SVGA    --]]
  { 960, 540}, --[[ (16:9 ) qHD     --]] { 960, 720}, --[[ ( 4:3 ) 0.69M3  --]]
  {1024, 576}, --[[ (16:9 ) 0.59M9  --]] {1280, 720}, --[[ (16:9 ) WXGA    --]]
  {1280, 800}, --[[ (16:10) WXGA    --]] {1280, 960}, --[[ ( 4:3 ) SXGA-   --]]
  {1400, 900}, --[[ (16:9 ) WSXGA   --]] {1600,1200}, --[[ (16:9 ) HD+     --]]
  {1680,1050}, --[[ (16:10) WSXGA+  --]] {1920,1080}, --[[ (16:9 ) FHD     --]]
  {1920,1200}, --[[ (16:10) WUXGA   --]] {2048,1280}, --[[ (16:10) 2.62MA  --]]
  {2304,1440}, --[[ (16:10) 3.32MA  --]] {2560,1440}, --[[ (16:9 ) WQHD    --]]
  {2560,1600}  --[[ (16:10) WQXGA   --]]
};
-- Other ----------------------------------------------------------------------
local iOColour, aColours<const> = 1, { -- Colour transition animations
  0xFFF0F0F0,0xFFE0E0E0,0xFFD0D0D0,0xFFC0C0C0,0xFFB0B0B0,0xFFA0A0A0,0xFF909090,
  0xFF808080,0xFF707070,0xFF606060,0xFF505050,0xFF404040,0xFF303030,0xFF202020,
  0xFF101010,0xFF202020,0xFF303030,0xFF404040,0xFF505050,0xFF606060,0xFF707070,
  0xFF808080,0xFF909090,0xFFA0A0A0,0xFFB0B0B0,0xFFC0C0C0,0xFFD0D0D0,0xFFE0E0E0
};
-- Main locals ------------------------------------------------------------- --
local fcbInput, fcbRender, fcbLogic,   -- Current input/render/logic funcs
      iCArrow, iCBottom, iCSelect,     -- Cursor ids
      iCTop, iCWait,                   -- More cursor ids
      iSClick, iSSelect,               -- Sound effect ids
      iLastCursorId,                   -- Cursor id before entering setup
      iLastKeyBank,                    -- Keybank before entering setup
      iStageB, iStageH, iStageL,       -- Bottom, height, left stage bounds
      iStageR, iStageT, iStageW,       -- Right, top and width stage bounds
      musLast,                         -- Music handle before entering setup
      nButtonIntensity,                -- Current button intensity
      nButtonIntensityIncrement,       -- Current button intensity increment
      nCPUUsageProcess,                -- Current process CPU usage
      nCPUUsageSystem,                 -- Current system CPU usage
      nGPUFramesPerSecond,             -- Current graphical frames per second
      nRAMUsePercentage,               -- Current ram usage percentage
      nStatusLinePos,                  -- Marquee text tip position
      nStatusLineSize,                 -- Marquee text tip width
      nTime,                           -- Current execution time
      nTipId,                          -- Current tip id
      sStatusLine1, sStatusLine2,      -- Current status title and subtitle
      sStatusLineSave,                 -- Saved status title
      sTitle;                          -- Current main title
-- Readme locals ----------------------------------------------------------- --
local aCreditLines<const> = { };       -- Actual readme data
local aReadmeColourData<const> = { };  -- Readme colourisation date
local iKeyBankReadme,                  -- Readme keybank id
      aReadmeData,                     -- Readme data
      aReadmeVisibleLines;             -- Readme/binds lines data
local iReadmeIndexBegin = 1;           -- Current start line
local iReadmeIndexEnd = 1;             -- Ending line
local iReadmeRows<const> = 28;         -- Maximum readme on-screen rows
local iReadmeCols<const> = 77;         -- Maximum readme on-screen columns
local iReadmeSpacing<const> = 6;       -- Spacing between each line
local iReadmePaddingX<const> = 8;      -- Starting X co-ordinate
local iReadmePaddingY<const> = 27;     -- Starting Y co-ordinate
local iReadmeColsM1<const> = iReadmeCols - 1; -- Readme columns minus one
-- Configuration locals ---------------------------------------------------- --
local iCatSize<const> = 15;            -- Category line height
local iAudioDeviceId,                  -- Current audio device id
      iAudioDeviceIdOriginal,          -- Original audio device id
      iCatBottom,                      -- Bottom of categories position
      iFullScreenMode,                 -- Current full-screen mode number
      iFullScreenModeOriginal,         -- Original full-screen mode number
      iFullScreenState,                -- Current full-screen state
      iFullScreenStateOriginal,        -- Original full-screen state
      iKeyBankSetup,                   -- Key bank id for configuration screen
      iMonitorId,                      -- Current monitor id
      iMonitorIdOriginal,              -- Original monitor id
      iSelectedButton,                 -- Currently selected button
      iSelectedOption,                 -- Currently selected option
      iWindowId,                       -- Current window size id
      iWindowIdOriginal;               -- Original window size id
-- Binding locals ---------------------------------------------------------- --
local aBindingsList<const> = { };      -- All of the formatted keybindings data
local iBindsIndexBegin = 1;            -- Current starting keybinds position
local iBindsIndexEnd = 1;              -- Current ending keybinds position
local iKeyBankBind;                    -- Key bank id for key binds screen
local iPress<const> = aStates.PRESS;   -- Pressed state id
local iRepeat<const> = aStates.REPEAT; -- Repeated state id
local iControl<const> = aMods.CONTROL; -- Control modifier pressed id
local iBackspace<const> = aKeys.BACKSPACE; -- Backspace key id
local iEscape<const> = aKeys.ESCAPE;   -- Escape key id
local iSpace<const> = aKeys.SPACE;     -- Spacebar key id
-- ------------------------------------------------------------------------- --
local function GetMonitorIdOrPrimary()
  -- If the monitor id is set to the primary monitor then we need to return
  -- the actual id of the primary monitor instead
  if iMonitorId == -1 then return DisplayMonitor() end;
  -- Return selected monitor id
  return iMonitorId;
end
-- ------------------------------------------------------------------------- --
local function UpdateLabels()
  -- This will update the text on all the labels based on updated values
  for iIndex = 1, #aSetupOptionData do
    local aData<const> = aSetupOptionData[iIndex];
    aData[2] = aData[3]();
  end
end
-- ------------------------------------------------------------------------- --
local function ColouriseText(sText)
  -- Set next colour to start on
  local iColour, sOutText = iOColour, "";
  -- For each letter in the title
  for iIndex = 1, #sText do
    -- Apply colour to the letter
    sOutText = sOutText..format("\rc%08x",
      aColours[1 + (iColour % #aColours)])..
      sText:sub(iIndex, iIndex);
    -- Next colour
    iColour = iColour - 1;
  end
  -- Set colour for next time
  iOColour = (iOColour + 1) % #aColours;
  -- Return result
  return sOutText;
end
-- ------------------------------------------------------------------------- --
local function FlickerColour1()
  fontLarge:SetCRGBA(1, 1, 1, 1);
  fontTiny:SetCRGBA(0.75, 0.75, 0.5, 1);
end
-- ------------------------------------------------------------------------- --
local function FlickerColour2()
  fontLarge:SetCRGBA(0.75, 0.75, 0.75, 1);
  fontTiny:SetCRGBA(1, 1, 0.75, 1);
end
-- ------------------------------------------------------------------------- --
local function FlickerColours(cbCol1, cbCol2)
  if nTime % 0.43 < 0.215 then cbCol1() else cbCol2() end;
end
-- ------------------------------------------------------------------------- --
local function RenderBackgroundStart(nId)
  -- Render game background
  fcbRender();
  -- Draw background animation
  local iStageLP6<const> = iStageL + 6;
  local nTimeM2<const> = nTime * 2;
  texSpr:SetCRGB(0, 0, 0);
  for iY = iStageT + 6, iStageB, 16 do
    local nTimeM2SX<const> = nTimeM2 - iY;
    for iX = iStageLP6, iStageR, 16 do
      local nAngle = nTimeM2SX - iX;
      nAngle = 0.5 + ((cos(nAngle) * sin(nAngle)));
      texSpr:SetCA(nAngle * 0.75);
      local nDim<const> = nAngle * 16;
      texSpr:BlitSLTWHA(444, iX, iY, nDim, nDim, nAngle);
    end
  end
  -- Draw background for text
  texSpr:SetCRGB(0.2, 0.1, 0.1);
  RenderFade(0.75, 4, 28, 316, 212, 1022);
  -- Draw title and status fades
  texSpr:SetCRGB(0.4, 0.2, 0.2);
  RenderFade(0.75, 4, 212, 316, 236, 1022);
  RenderFade(0.75, 4, 4, 316, 28, 1022);
  -- Draw shadow around window
  RenderShadow(4, 4, 316, 236);
  -- Print title
  texSpr:SetCRGBA(1, 1, 1, 1);
  -- Set alternating colour for title
  FlickerColours(FlickerColour1, FlickerColour2);
  fontLarge:PrintC(160, 8, ColouriseText(sTitle));
  -- Print tip
  if nStatusLineSize and nStatusLineSize > 0 then
    fontTiny:PrintM(8 - nStatusLinePos, 226,
      nStatusLinePos, 304 + nStatusLinePos, sStatusLine2);
    nStatusLinePos = nStatusLinePos + 1;
    if nStatusLinePos >= nStatusLineSize then nStatusLinePos = 0 end;
  else fontTiny:PrintC(160, 226, sStatusLine2) end;
  -- Print system information
  FlickerColours(FlickerColour2, FlickerColour1);
  fontTiny:PrintC(160, 217, sStatusLine1);
  fontTiny:Print (  8,  9, format("RAM %.1f%%", nRAMUsePercentage));
  fontTiny:PrintR(312, 18, format("%.1f%% ENG", nCPUUsageProcess));
  FlickerColours(FlickerColour1, FlickerColour2);
  fontTiny:PrintR(312,  9, format("%.1f%% SYS", nCPUUsageSystem));
  fontTiny:Print (  8, 18, format("%.1f FPS",   nGPUFramesPerSecond));
end
-- ------------------------------------------------------------------------- --
local function Finish()
  -- Unload data
  aReadmeData, aReadmeVisibleLines = { }, { };
  -- Return to sub-proc
  SetCallbacks(fcbLogic, fcbRender, fcbInput);
  -- Set original cursor
  SetCursor(iLastCursorId);
  -- Music to resume?
  if musLast then
    -- Play the music
    PlayMusic(musLast, nil, 2);
    -- Do not keep reference to handle
    musLast = nil;
  -- No music to set? Just stop the setup music
  else StopMusic() end;
  -- Restore redraw callback
  RegisterFBUCallback("setup");
  -- Restore original keybank
  SetKeys(true, iLastKeyBank);
  -- Done with saved keybank id
  iLastKeyBank = nil;
end
-- ------------------------------------------------------------------------- --
local function Refresh()
  -- Refresh monitor settings
  local function RefreshMonitorSettings()
    -- Initialise monitor video modes and use primary monitor if invalid
    iMonitorId = tonumber(VariableGetInt(iCVvidmonitor));
    if iMonitorId < -1 or iMonitorId >= DisplayMonitors() then
      iMonitorId = -1 end;
    iMonitorIdOriginal = iMonitorId;
    -- Initialise video resolution and use desktop resolution if invalid
    iFullScreenState = tonumber(VariableGetInt(iCVvidfs));
    if iFullScreenState < 0 or iFullScreenState > 1 then
      iFullScreenState = 0 end;
    iFullScreenMode = tonumber(VariableGetInt(iCVvidfsmode));
    -- If full-screen mode is enabled?
    if iFullScreenState == 1 then
      -- If full-screen mode is -1 (Exclusive full-screen)?
      if iFullScreenMode >= -1 then iFullScreenState = 2;
      -- If full-screen mode is -2 (Borderless window mode)?
      elseif iFullScreenMode == -2 then iFullScreenState = 1 end;
    -- Windowed mode
    else iFullScreenMode = -2 end;
    -- If the full-screen mode CVar is invalid then reset to 'automatic' mode
    -- where the engine will set the full-screen mode to the desktop mode.
    if iFullScreenMode < -2 or
      iFullScreenMode >= DisplayVidModes(GetMonitorIdOrPrimary()) then
        iFullScreenMode = -1 end;
    -- Record the the initialised variables so we can check if they were
    -- modified when the user clicks the apply button.
    iFullScreenModeOriginal = iFullScreenMode;
    iFullScreenStateOriginal = iFullScreenState;
  end;
  -- Refresh window settings
  local function RefreshWindowSettings()
    -- Get window size
    local iWindowWidth = tonumber(VariableGetInt(iCVwinwidth));
    local iWindowHeight = tonumber(VariableGetInt(iCVwinheight));
    -- Set to defaults if invalid
    if iWindowWidth < -1 then iWindowWidth = -1 end;
    if iWindowHeight < -1 then iWindowHeight = -1 end;
    -- Set 'automatic' window id
    iWindowId = 0;
    -- Find window size in list and override the above index if found
    for iIndex = 1, #aWindowSizes do
      local aData = aWindowSizes[iIndex];
      if aData[1] == iWindowWidth and aData[2] == iWindowHeight then
        iWindowId = iIndex;
      end
    end
    -- Record original id
    iWindowIdOriginal = iWindowId;
  end
  -- Refresh audio settings
  local function RefreshAudioSettings()
    iAudioDeviceId = tonumber(VariableGetInt(iCVaudinterface));
    iAudioDeviceIdOriginal = iAudioDeviceId;
  end
  -- Perform refreshes
  RefreshMonitorSettings();
  RefreshWindowSettings();
  RefreshAudioSettings();
  -- Update labels
  UpdateLabels();
end
-- On frame buffer refresh callback ---------------------------------------- --
local function OnFrameBufferUpdate(...)
  -- Update stage bounds
  iStageW, iStageH, iStageL, iStageT, iStageR, iStageB = ...;
  -- Refresh settings
  Refresh();
end
-- ------------------------------------------------------------------------- --
local function ApplySettings()
  -- Do window reset?
  local bWindowReset = false;
  -- Set window size
  if iWindowId >= 1 and iWindowId <= #aWindowSizes then
    local aData<const> = aWindowSizes[iWindowId];
    if aData[1] == 0 and aData[2] == 0 then bWindowReset = true end;
    VariableSetInt(iCVwinwidth, aData[1]);
    VariableSetInt(iCVwinheight, aData[2]);
  end
  -- Set window variables if needed
  if iFullScreenState == 2 then VariableSetInt(iCVvidfs, 1)
                           else VariableSetInt(iCVvidfs, iFullScreenState) end;
  -- If full-screen mode is resetting?
  if iFullScreenMode == -3 then
    -- Now set to default mode
    iFullScreenMode = -2;
    VariableResetInt(iCVvidfsmode);
  else VariableSetInt(iCVvidfsmode, iFullScreenMode) end;
  VariableSetInt(iCVvidmonitor, iMonitorId);
  VariableSetInt(iCVaudinterface, iAudioDeviceId);
  -- Reset audio subsystem if interface changed
  if iAudioDeviceIdOriginal ~= iAudioDeviceId then AudioReset() end;
  -- If GPU related parameters changed from original then reset video
  if iFullScreenMode ~= iFullScreenModeOriginal or
     iFullScreenStateOriginal ~= iFullScreenState or
     iMonitorIdOriginal ~= iMonitorId then DisplayVReset();
  -- If window parameters changed then just reset window
  elseif bWindowReset or iFullScreenState == 0 and
         iWindowId ~= iWindowIdOriginal then DisplayReset() end;
  -- Refresh/update settings
  Refresh();
end
-- ------------------------------------------------------------------------- --
local nAlpha<const> = 1/60;
local function ProcSysInfo()
  -- Get time
  nTime = CoreTime();
  -- Get cpu info, ram info and nGPUFramesPerSecond
  nCPUUsageProcess, nCPUUsageSystem = CoreCPUUsage();
  nRAMUsePercentage = CoreRAM();
  nGPUFramesPerSecond = (nAlpha * DisplayGPUFPS()) + (1.0 - nAlpha) *
    (nGPUFramesPerSecond or 60);
end
-- ------------------------------------------------------------------------- --
local function ProcReadme()
  -- Set system info
  ProcSysInfo();
  -- Show up mouse cursor if on top half of screen
  if IsMouseYGreaterEqualThan(206) then SetCursor(iCBottom);
  -- Show down mouse cursor if on bottom half of screen
  elseif IsMouseYLessThan(32) then SetCursor(iCTop);
  -- Show default cursor otherwise
  else SetCursor(iCArrow) end;
end
-- ------------------------------------------------------------------------- --
local function RenderReadme()
  -- Render default background
  RenderBackgroundStart(757);
  -- Draw readme
  for iIndex = 1, #aReadmeVisibleLines do
    -- Get data
    local aData<const> = aReadmeVisibleLines[iIndex];
    -- Calculate gradient colour
    local iCol<const> = aReadmeColourData[iIndex];
    -- Calculate intensity
    local nIntensity<const> =
      0.75 + (((iIndex / #aReadmeVisibleLines) + nTime) % 0.25);
    -- Set colour
    fontTiny:SetCRGB(nIntensity, nIntensity, nIntensity);
    -- Print line
    fontTiny:Print(aData[1], aData[2], aData[3]);
  end
  -- Set alternating title colour based on current time
  if nTime % 0.43 < 0.215 then fontTiny:SetCRGBA(0.5, 0.5, 0.5, 1);
                          else fontTiny:SetCRGBA(0.75, 0.75, 0.75, 1) end;
end
-- ------------------------------------------------------------------------- --
local function SetTip(nNewTipId, sTip)
  -- Ignore if tip set
  if nNewTipId == nTipId then return end;
  -- Set new tip
  nTipId = nNewTipId;
  -- No tip? Reset
  if not sTip then
    -- Save status line
    sStatusLine2 = sStatusLineSave;
    -- Re-calculate size and reset position
    nStatusLineSize, nStatusLinePos = -1, -1;
    -- Done
    return;
  end
  -- Get size of tip
  local sTipPlusSep = sTip.." -+- "
  local nTipSizePixels = fontTiny:PrintS(sTipPlusSep);
  local nMaxLine = 304+nTipSizePixels;
  -- Fill the line until it is big enough to scroll seamlessly
  sStatusLine2, nStatusLineSize = "", nTipSizePixels;
  while nStatusLineSize < nMaxLine do
    -- Set the tip and append a separator for seamless repeating
    sStatusLine2 = sStatusLine2..sTipPlusSep;
    -- Calculate size
    nStatusLineSize = fontTiny:PrintS(sStatusLine2);
  end
  -- Reset size to tip length
  nStatusLineSize = nTipSizePixels;
  -- Add more text so we can have a seamless repeating
  sStatusLine2 = sStatusLine2..sTip;
  -- Reset position
  nStatusLinePos = -304;
end
-- ------------------------------------------------------------------------- --
local function UpdateReadmeLines()
  -- Clear displayed lines
  aReadmeVisibleLines = { };
  -- For each line in readme file...
  for iIndex = iReadmeIndexBegin,
    min(iReadmeIndexBegin + iReadmeRows, #aReadmeData) do
    -- Get line and truncate it if it is too long
    local sLine = aReadmeData[iIndex];
    if #sLine > iReadmeColsM1 then sLine = sLine:sub(1, iReadmeColsM1) end;
    -- Insert visible line
    aReadmeVisibleLines[1 + #aReadmeVisibleLines] =
      { iReadmePaddingX, iReadmePaddingY + ((#aReadmeVisibleLines + 1) *
        iReadmeSpacing), sLine };
  end
  -- Update statuses
  sStatusLine1 = "DISPLAYING LINE "..iReadmeIndexBegin.." TO "..
    iReadmeIndexEnd.." OF "..#aReadmeData.." OF THESE ACKNOWLEDGEMENTS";
  -- Make sure marquee is showing
  SetTip(0, "MOVE THE CURSOR TO THE BOTTOM OR TOP OF THE SCREEN AND PRESS \z
    RMB, JB1 OR PRESS "..
    aKeyBankCats.srmpu[9]..", "..aKeyBankCats.srmpd[9]..", "..
    aKeyBankCats.srmh[9]..", "..aKeyBankCats.srme[9]..", "..
    aKeyBankCats.srmu[9].." OR "..aKeyBankCats.srmd[9].." TO SCROLL THE \z
    README. "..aKeyBankCats.gksc[9]..", RMB OR JB2 TO RETURN TO SETUP. "..
    aKeyBankCats.sf[9].." TO LEAVE SETUP.");
end
-- ------------------------------------------------------------------------- --
local function SetReadme(Line)
  -- Get maximum lines
  local iMax<const> =
    UtilClampInt(#aReadmeData - #aReadmeColourData, 1, maxinteger);
  -- Set to end line?
  if Line == maxinteger then iReadmeIndexBegin = iMax;
  -- Set line?
  else iReadmeIndexBegin = UtilClampInt(Line, 1, iMax) end;
  -- Set ending line
  iReadmeIndexEnd = UtilClampInt(iReadmeIndexBegin +
    #aReadmeColourData, 1, #aReadmeData);
  -- Update displayed readme lines
  UpdateReadmeLines();
end
-- ------------------------------------------------------------------------- --
local function ScrollReadme(iAdj) SetReadme(iReadmeIndexBegin + iAdj) end;
local function ScrollReadmePageUp() ScrollReadme(-29) end;
local function ScrollReadmePageDown() ScrollReadme(29) end;
local function ScrollReadmeUp() ScrollReadme(-1) end;
local function ScrollReadmeDown() ScrollReadme(1) end;
local function ScrollReadmeHome() SetReadme(1) end;
local function ScrollReadmeEnd() SetReadme(#aReadmeData) end;
-- ------------------------------------------------------------------------- --
local function ProcReadmeInput()
  -- Check for mouse scroll wheel moving
  if IsScrollingLeft() then ScrollReadmePageUp();
  elseif IsScrollingRight() then ScrollReadmePageDown();
  elseif IsScrollingUp() then ScrollReadmeUp();
  elseif IsScrollingDown() then ScrollReadmeDown();
  -- Cancel button pressed? Cancel readme
  elseif IsButtonPressed(1) then InitSetup(1);
  -- Select button pressed? Scroll!
  elseif IsButtonHeld(0) then
    -- On bottom section of screen? Scroll down
    if IsMouseYGreaterEqualThan(206) then ScrollReadmeDown();
    -- Else scroll up if on top section of screen
    elseif IsMouseYLessThan(32) then ScrollReadmeUp() end;
  end
end
-- ------------------------------------------------------------------------- --
local function InitReadme()
  -- Set title
  sTitle = "ABOUT";
  -- Set readme lines
  aReadmeData = aCreditLines;
  -- This make sure the status tip is updated
  nTipId = -1;
  -- Initialise readme lines
  UpdateReadmeLines();
  -- At least one tick
  ProcReadme();
  -- Arrow cursor
  SetCursor(iCArrow);
  -- Restore original keys
  SetKeys(true, iKeyBankReadme);
  -- Set readme procedures
  SetCallbacks(ProcReadme, RenderReadme, ProcReadmeInput);
end
-- ------------------------------------------------------------------------- --
local function RenderSetup()
  -- Render default background
  RenderBackgroundStart(771);
  -- Draw selected item
  if iSelectedOption > 0 then
    texSpr:SetCRGB(0, 0, 0);
    local iY<const> = 28 + (iSelectedOption - 1) * iCatSize;
    RenderFade(nButtonIntensity, 4, iY, 316, iY + iCatSize, 1022);
    texSpr:SetCRGB(1, 1, 1);
    -- Set tip
    SetTip(iSelectedOption, aSetupOptionData[iSelectedOption][6]);
  -- No selected option so remove tip if a button isn't selected
  end
  -- For each category
  for iIndex, aData in pairs(aSetupOptionData) do
    local nIntensity;
    if iSelectedOption == iIndex then fontLittle:SetCRGB(1, 1, 1);
    else
      nIntensity = 0.5 + (((iIndex/#aSetupOptionData) + nTime) % 0.5);
      fontLittle:SetCRGB(0, 0, nIntensity);
    end
    fontLittle:Print(8, 17+(iIndex*iCatSize), aData[1]);
    if iSelectedOption == iIndex then fontLittle:SetCRGB(1, 1, 1);
    else
      nIntensity = 0.5 + (((iIndex/#aSetupOptionData) + -nTime) % 0.5);
      fontLittle:SetCRGB(0, nIntensity, 0);
    end
    fontLittle:PrintR(312, 17+(iIndex*iCatSize), aData[2]);
  end
  -- No selected button
  iSelectedButton = 0;
  -- For each button
  texSpr:SetCRGB(0, 0, 0);
  for iIndex, aData in pairs(aSetupButtonData) do
    -- Mouse in bounds?
    if IsMouseInBounds(aData[1], aData[2], aData[3], aData[4]) then
      -- Set tip
      SetTip(aData[7], aData[10]);
      -- Set button
      iSelectedButton = aData[7];
      -- Set glowing colour
      texSpr:SetCRGB(nButtonIntensity, nButtonIntensity, nButtonIntensity);
      -- Draw background
      RenderFade(1-nButtonIntensity,
        aData[1], aData[2], aData[3], aData[4], 1022);
    -- Mouse not in bounds? Just draw black background
    else RenderFade(0.5, aData[1], aData[2], aData[3], aData[4], 1023) end;
    -- Set button text colour and print the text
    fontLittle:SetCRGB(1, 1, 1);
    fontLittle:PrintC(aData[8], aData[9], iIndex);
  end
  -- Remove tip if an option isn't selected
  if iSelectedButton == 0 and iSelectedOption == 0 then
    SetTip(0, sStatusLineSave) end;
  -- Print generic info
  if nTime % 0.43 < 0.215 then fontTiny:SetCRGBA(0.5, 0.5, 0.5, 1);
                          else fontTiny:SetCRGBA(0.75, 0.75, 0.75, 1) end;
  -- Reset sprites colour because we changed it
  texSpr:SetCRGBA(1, 1, 1, 1);
end
-- ------------------------------------------------------------------------- --
local function LastOne(iIndex)
  -- Play sound
  PlayStaticSound(iSClick);
  -- Get data
  local aData<const> = aSetupOptionData[iIndex];
  -- Call last function
  aData[4]();
  -- Refresh
  aData[2] = aData[3]();
end
-- ------------------------------------------------------------------------- --
local function NextOne(iIndex)
  -- Play sound
  PlayStaticSound(iSClick);
  -- Get data
  local aData<const> = aSetupOptionData[iIndex];
  -- Call next function
  aData[5]();
  -- Refresh
  aData[2] = aData[3]();
end
-- ------------------------------------------------------------------------- --
local function ProcSetupInput()
  -- For each button
  for _, aData in pairs(aSetupButtonData) do
    -- Mouse in bounds?
    if IsMouseInBounds(aData[1], aData[2], aData[3], aData[4]) then
      -- Nothing selected
      iSelectedOption = 0;
      -- Set specified cursor
      SetCursor(aData[5]);
      -- Left button clicked?
      if IsButtonPressed(0) then
        -- Play sound
        PlayStaticSound(iSClick);
        -- Execute command
        aData[6]();
      end
      -- Done
      return;
    end
  end
  -- Test if mouse is in the configuration options area
  if IsMouseInBounds(4, 28, 316, iCatBottom) then
    -- Set selected option
    iSelectedOption = (GetMouseY() - 28) // iCatSize + 1;
    -- Show select cursor
    SetCursor(iCSelect);
    -- Left clicked or mouse scrolled down?
    if IsButtonPressed(2) or IsButtonPressed(5) or IsButtonPressed(7) or
       IsScrollingUp() then NextOne(iSelectedOption);
    -- Right clicked or mouse scrolled up?
    elseif IsButtonPressed(0) or IsButtonPressed(4) or IsButtonPressed(6) or
           IsScrollingDown() then LastOne(iSelectedOption) end;
    -- Done
    return;
  end
  -- Nothing selected
  iSelectedOption = 0;
  -- Default cursor
  SetCursor(iCArrow);
end
-- ------------------------------------------------------------------------- --
local function ProcSetup()
  -- Set system info
  ProcSysInfo();
  -- Set button intensity
  nButtonIntensity =
    UtilClamp(nButtonIntensity + nButtonIntensityIncrement, 0.25, 0.75);
  if nButtonIntensity == 0.25 or nButtonIntensity == 0.75 then
    nButtonIntensityIncrement = -nButtonIntensityIncrement end;
end
-- ------------------------------------------------------------------------- --
local function InitConfig()
  -- No option selected
  iSelectedOption = 0;
  -- Set title
  sTitle = "SETUP";
  -- Initialise status bars
  sStatusLine1 = sGameName.." ("..sAppExeType..") "..sGameVersion.."."..
    iAppMajor.."."..iAppMinor.."."..iAppBuild.."."..iAppRevision.." - "..
    sGameWebsite;
  sStatusLine2 = sAppVendor.." PROUDLY PRESENTS "..sGameName.."! A REMAKE \z
    FOR MODERN OPERATING SYSTEMS AND HARDWARE FROM THE CLASSIC CD32 AND DOS \z
    DAYS. THIS IS THE CONFIGURATION SCREEN. PRESS "..aKeyBankCats.sf[9].." \z
    OR THE 'DONE' BUTTON TO RETURN TO THE GAME OR MOVE YOUR MOUSE OVER AN \z
    OPTION TO HAVE MORE EXPLAINED ABOUT IT HERE. USE YOUR MOUSE OR JOYSTICK \z
    TO MOVE THE CURSOR AND THE BUTTONS TO CHANGE OPTIONS. PRESS "..
    aKeyBankCats.gksc[9].." AT ANY TIME TO SEE THIS SCREEN, "..
    aKeyBankCats.gksb[9].." TO CHANGE KEYBINDINGS OR "..
    aKeyBankCats.gksa[9].." TO SEE THE ACKNOWLEDGEMENTS. \z
    PRESS ALT+ENTER AT ANY TIME TO TOGGLE FULL-SCREEN AND WINDOW. PRESS "..
    aKeyBankCats.gkcc[9].." TO FIX THE MOUSE CURSOR, PRESS "..
    aKeyBankCats.gkwr[9].." TO RESTORE THE WINDOW POSITION OR PRESS "..
    aKeyBankCats.gkss[9].." TO TAKE A SCREENSHOT.";
  sStatusLineSave = sStatusLine2;
  SetTip(0, sStatusLineSave);
  -- Refresh all settings
  Refresh();
  -- Restore original keys
  SetKeys(true, iKeyBankSetup);
  -- Set configuration procedures
  SetCallbacks(ProcSetup, RenderSetup, ProcSetupInput)
end
-- ------------------------------------------------------------------------- --
local function ProcSetupInput() end;
-- ------------------------------------------------------------------------- --
local function UpdateBindsLines()
  -- Clear displayed lines
  aReadmeVisibleLines = { };
  -- For each line in readme file...
  for iIndex = iBindsIndexBegin,
    min(iBindsIndexBegin + iReadmeRows, #aBindingsList) do
    -- Get line and truncate it if it is too long
    local aBind<const> = aBindingsList[iIndex];
    local sLine = aBind[6];
    local sBind<const> = aBind[8];
    sLine = sLine.." "..rep(".", 74 - #sLine - #sBind).." "..sBind;
    if #sLine > iReadmeColsM1 then sLine = sLine:sub(1, iReadmeColsM1) end;
    -- Insert visible line
    local iY<const> =
      iReadmePaddingY + ((#aReadmeVisibleLines + 1) * iReadmeSpacing)
    aReadmeVisibleLines[1 + #aReadmeVisibleLines] =
      { iReadmePaddingX, iY, sLine, iReadmePaddingX+304, iY+6, aBind };
  end
  -- Update statuses
  sStatusLine1 = "DISPLAYING INPUT BINDING "..iBindsIndexBegin.." TO "..
    iBindsIndexEnd.." OF "..#aBindingsList.." OF TOTAL INPUT BINDINGS";
  -- Make sure marquee is showing
  SetTip(0, "MOVE THE CURSOR TO A BIND YOU WANT TO CHANGE AND PRESS RMB OR \z
    JB1 ON IT TO CHANGE THE KEY BINDING FOR IT. PRESS "..
    aKeyBankCats.sbpu[9]..", "..aKeyBankCats.sbpd[9]..", "..
    aKeyBankCats.sbh[9]..", "..aKeyBankCats.sbe[9]..", "..
    aKeyBankCats.sbu[9].." OR "..aKeyBankCats.sbd[9].." TO SCROLL THE \z
    BINDS. "..aKeyBankCats.gksc[9]..", RMB OR JB2 TO RETURN TO SETUP. "..
    aKeyBankCats.sf[9].." TO LEAVE SETUP.");
end
-- ------------------------------------------------------------------------- --
local function SetBinds(iLine)
  -- Get maximum lines
  local iMax<const> =
    UtilClampInt(#aBindingsList - #aReadmeColourData, 1, maxinteger);
  -- Set to end line?
  if iLine == maxinteger then iBindsIndexBegin = iMax;
  -- Set line?
  else iBindsIndexBegin = UtilClampInt(iLine, 1, iMax) end;
  -- Set ending line
  iBindsIndexEnd = UtilClampInt(iBindsIndexBegin +
    #aReadmeColourData, 1, #aBindingsList);
  -- Update displayed readme lines
  UpdateBindsLines();
end
-- Bind scroll callbacks --------------------------------------------------- --
local function ScrollBinds(iAdj) SetBinds(iBindsIndexBegin + iAdj) end;
local function ScrollBindsPageUp() ScrollBinds(-29) end;
local function ScrollBindsPageDown() ScrollBinds(29) end;
local function ScrollBindsUp() ScrollBinds(-1) end;
local function ScrollBindsDown() ScrollBinds(1) end;
local function ScrollBindsHome() SetBinds(1) end;
local function ScrollBindsEnd() SetBinds(#aBindingsList) end;
-- ------------------------------------------------------------------------- --
local function RenderBinds()
  -- Render default background
  RenderBackgroundStart(757);
  -- Draw readme
  for iIndex = 1, #aReadmeVisibleLines do
    -- Get data
    local aData<const> = aReadmeVisibleLines[iIndex];
    -- Calculate gradient colour
    local iCol<const> = aReadmeColourData[iIndex];
    -- Return if no option is selected
    local nIntensity;
    if iSelectedOption == iIndex then
      -- Get currently selected line data and render a selection rectangle
      texSpr:SetCRGB(0, 1, 0);
      RenderFade(0.75, aData[1], aData[2], aData[4], aData[5], 1022);
      texSpr:SetCRGB(1, 1, 1);
      nIntensity = 1;
    else
      -- Calculate intensity
      nIntensity = 0.75 + (((iIndex / #aReadmeVisibleLines) + nTime) % 0.25);
    end
    -- Set text colour and print the bind line
    fontTiny:SetCRGB(nIntensity, nIntensity, nIntensity);
    fontTiny:Print(aData[1], aData[2], aData[3]);
  end
  -- Set alternating title colour based on current time
  if nTime % 0.43 < 0.215 then fontTiny:SetCRGBA(0.5, 0.5, 0.5, 1);
                          else fontTiny:SetCRGBA(0.75, 0.75, 0.75, 1) end;
end
-- ------------------------------------------------------------------------- --
local function ProcBindsInput()
  -- Check for mouse scroll wheel moving
  if IsScrollingLeft() then ScrollBindsPageUp();
  elseif IsScrollingRight() then ScrollBindsPageDown();
  elseif IsScrollingUp() then ScrollBindsUp();
  elseif IsScrollingDown() then ScrollBindsDown();
  -- Cancel button pressed? Cancel binds screen
  elseif IsButtonPressed(1) then InitSetup(1);
  -- Anything else?
  elseif iSelectedOption and IsButtonPressed(0) then
    -- Get key bind data
    local aBindData<const> = aReadmeVisibleLines[iSelectedOption][6];
    -- Set text to receive key
    local sTextSave<const> = aBindData[8];
    aBindData[8] = "???";
    -- Update readme lines
    UpdateBindsLines();
    -- Remove marquee settings
    sStatusLineSave, nStatusLineSize, nStatusLinePos, nTipId =
      nil, nil, nil, nil;
    -- Update tip at the bottom
    sStatusLine1 = "PRESS ANY KEY TO USE AS NEW KEY BINDING";
    sStatusLine2 = "CTRL+ESC:CANCEL  \z
                    CTRL+SPACE:DEFAULT  \z
                    CTRL+BACKSPACE:CLEAR";
    -- Get current callbacks
    local CBProc<const>, CBRender<const>, CBInput<const> = GetCallbacks();
    -- Disable everything but rendering and animations
    SetCallbacks(ProcSysInfo, RenderBinds, nil);
    -- Set cursor to busy
    SetCursor(iCWait);
    -- Disable all input events
    DisableKeyHandlers();
    -- On key scan functino
    local function OnScanKey(iKey, iState, iMods)
      -- Ignore if not pressed
      if iState ~= iPress then return end;
      -- Mods were pressed?
      if iMods > 0 then
        -- Control was pressed?
        if iMods & iControl == iMods then
          -- Backspace was pressed? Set unbound
          if iKey == iBackspace then iKey = 0;
          -- Escape was pressed? Keep existing key
          elseif iKey == iEscape then iKey = aBindData[1];
          -- Space key was pressed? Use default
          elseif iKey == iSpace then iKey = aBindData[5];
          -- Not recognised? Ignore press
          else return end;
        -- Do not process key with mods
        else return end;
      end
      -- Apply bind to cvar the cvar callback will change the text to the
      -- new value but won't if the value could not be changed in which we
      -- restore the original text value here.
      if aBindData[7]:Set(iKey) ~= 0 then aBindData[8] = sTextSave end;
      -- Restore input handlers
      RestoreKeyHandlers();
      -- Update readme lines
      UpdateBindsLines();
      -- Re-enable callbacks
      SetCallbacks(CBProc, CBRender, CBInput);
    end
    -- Set new callbacks
    InputOnKey(OnScanKey);
  -- Select button pressed? Scroll!
  elseif IsButtonHeld(0) then
    -- On bottom section of screen? Scroll down
    if IsMouseYGreaterEqualThan(206) then ScrollBindsDown();
    -- Else scroll up if on top section of screen
    elseif IsMouseYLessThan(32) then ScrollBindsUp() end;
  end
end
-- ------------------------------------------------------------------------- --
local function ProcBinds()
  -- Set system info
  ProcSysInfo();
  -- Draw readme
  for iIndex = 1, #aReadmeVisibleLines do
    -- Get data and if line is being selected?
    local aData<const> = aReadmeVisibleLines[iIndex];
    if IsMouseInBounds(aData[1], aData[2], aData[4], aData[5]) then
      -- Make option selected
      iSelectedOption = iIndex;
      -- Set selection cursor
      SetCursor(iCSelect);
      -- No need to process anything else
      return;
    end
  end
  -- Show up mouse cursor if on top half of screen
  if IsMouseYGreaterEqualThan(206) then SetCursor(iCBottom);
  -- Show down mouse cursor if on bottom half of screen
  elseif IsMouseYLessThan(32) then SetCursor(iCTop);
  -- Show default cursor otherwise
  else SetCursor(iCArrow) end;
  -- Clear if selected option
  if iSelectedOption then iSelectedOption = nil end;
end
-- ------------------------------------------------------------------------- --
local function InitBinds()
  -- No option selected
  iSelectedOption = 0;
  -- Set title
  sTitle = "BINDINGS";
  -- Clear status line
  sStatusLineSave = nil;
  -- Arrow cursor
  SetCursor(iCArrow);
  -- This make sure the status tip is updated
  nTipId = -1;
  -- Update binds lines
  UpdateBindsLines();
  -- Restore original keys
  SetKeys(true, iKeyBankBind);
  -- Set configuration procedures
  SetCallbacks(ProcBinds, RenderBinds, ProcBindsInput)
end
-- ------------------------------------------------------------------------- --
local function DoInitSetup(iMode)
  -- Get current callbacks
  local CBProc, CBRender, CBInput = GetCallbacks();
  -- Available modes
  local aModes<const> = {
    { InitConfig, RenderSetup  },
    { InitBinds,  RenderBinds },
    { InitReadme, RenderReadme },
  };
  -- Set and check requested mode/
  local aMode<const> = aModes[iMode];
  if not aMode then error("Invalid mode: "..iMode) end;
  -- Return if function already set
  if CBRender == aMode[2] then return end;
  -- Save current keybank so we can restore it on exit
  if not iLastKeyBank then iLastKeyBank = GetKeyBank() end;
  -- Remove the mode and go through available modes
  remove(aModes, iMode);
  for iIndex = 1, #aModes do
    -- Get mode data and just call init function if we're still in setup
    local aAltMode<const> = aModes[iIndex];
    if CBRender == aAltMode[2] then return aMode[1]() end;
  end
  -- Required setup assets finished loading
  local function OnLoaded(aResource)
    -- Save current music
    musLast = GetMusic();
    -- Play setup music
    PlayMusic(aResource[1], nil, 1);
    -- Initialise button intensity
    nButtonIntensity, nButtonIntensityIncrement = 1, 0.01;
    -- Backup old callbacks (Return to them later)
    fcbLogic, fcbRender, fcbInput = CBProc, CBRender, CBInput;
    -- Backup current cursor id
    iLastCursorId = GetCursor();
    -- Get time
    nTime = CoreTime();
    -- Calculate bottom of categories
    iCatBottom = 28 + (#aSetupOptionData * iCatSize);
    -- Call the mode init function
    aMode[1]();
  end
  -- Register frame buffer update
  RegisterFBUCallback("setup", OnFrameBufferUpdate);
  -- Load bank texture
  LoadResources("Setup", aAssets, OnLoaded);
end
InitSetup = DoInitSetup;
-- Script has been initialised --------------------------------------------- --
local function OnReady(GetAPI)
  -- Grab import functions and data
  DisableKeyHandlers, GetCallbacks, GetCursor, GetKeyBank, GetMouseY, GetMusic,
    IsButtonHeld, IsButtonPressed, IsMouseInBounds, IsMouseYGreaterEqualThan,
    IsMouseYLessThan, IsScrollingDown, IsScrollingLeft, IsScrollingRight,
    IsScrollingUp, LoadResources, PlayMusic, PlayStaticSound,
    RegisterFBUCallback, RegisterKeys, RenderFade, RenderShadow,
    RestoreKeyHandlers, SetCallbacks, SetCursor, SetKeys, StopMusic,
    aKeyBankCats, aKeyToLiteral, aSetupButtonData, aSetupOptionData, fontLarge,
    fontLittle, fontTiny, texSpr =
      GetAPI("DisableKeyHandlers", "GetCallbacks", "GetCursor", "GetKeyBank",
        "GetMouseY", "GetMusic", "IsButtonHeld", "IsButtonPressed",
        "IsMouseInBounds", "IsMouseYGreaterEqualThan", "IsMouseYLessThan",
        "IsScrollingDown", "IsScrollingLeft", "IsScrollingRight",
        "IsScrollingUp", "LoadResources", "PlayMusic", "PlayStaticSound",
        "RegisterFBUCallback", "RegisterKeys", "RenderFade", "RenderShadow",
        "RestoreKeyHandlers", "SetCallbacks", "SetCursor", "SetKeys",
        "StopMusic", "aKeyBankCats", "aKeyToLiteral", "aSetupButtonData",
        "aSetupOptionData", "fontLarge", "fontLittle", "fontTiny", "texSpr");
  -- Callback to set all settings to default
  local function SetDefaults()
    -- Push defaults
    iFullScreenState = 0;
    iFullScreenMode = -3;
    iMonitorId = -1;
    iAudioDeviceId = -1;
    iWindowId = 1;
    -- Other options
    VariableResetInt(iCVappdelay);
    VariableResetInt(iCVvidvsync);
    VariableResetInt(iCVtexfilter);
    -- Reset volumes
    VariableResetInt(iCVaudvol);
    VariableResetInt(iCVaudstrvol);
    VariableResetInt(iCVaudsamvol);
    VariableResetInt(iCVaudfmvvol);
    -- Set new settings
    ApplySettings();
  end
  -- Apply button data
  local aButtons<const> = { { "APPLY", ApplySettings },
                            { "DONE",  Finish },
                            { "RESET", SetDefaults },
                            { "BINDS", InitBinds },
                            { "ABOUT", InitReadme },
                          };
  -- Start and end vertical position
  local iY1<const>, iY2<const> = 193, 212;
  -- Start drawing buttons from the left and the size of each button. We set
  -- the shader to round off any sub-pixelling so fractions are handled safely.
  local nX, nSize<const> = 4, 312 / #aButtons;
  -- Text position
  local nSizeD2<const>, iYText<const> = nSize / 2, iY1 + 6;
  -- For each button
  for iIndex = 1, #aButtons do
    -- Get the button data
    local aCb<const> = aButtons[iIndex];
    local aButton<const> = aSetupButtonData[aCb[1]];
    -- Set button co-ordinates
    aButton[1], aButton[2], aButton[3], aButton[4] = nX, iY1, nX + nSize, iY2;
    -- Click function
    aButton[6] = aCb[2];
    -- Text position
    aButton[8], aButton[9] = nX + nSizeD2, iYText;
    -- Next button position
    nX = nX + nSize;
  end;
  -- Option picker callbacks : Monitor choice callbacks
  local function MonitorUpdate()
    if iMonitorId == -1 then return "Primary Monitor" end;
    local sMsg<const> = DisplayMonitorData(iMonitorId);
    if #sMsg > 34 then return sMsg:sub(0,30).."..." end;
    return sMsg;
  end
  local function MonitorDown()
    if iMonitorId == -1 then return end;
    iMonitorId = iMonitorId - 1;
    UpdateLabels()
  end
  local function MonitorUp()
    if iMonitorId == DisplayMonitors()-1 then return end;
    iMonitorId = iMonitorId + 1;
    UpdateLabels()
  end
  -- Full-screen state callbacks
  local function FSStateUpdate()
    if DisplayFSType() == iNativeMode then return aWindowLabels[4] end;
    return aWindowLabels[iFullScreenState + 1];
  end
  local function FSStateDown()
    if iFullScreenState <= 0 or
       DisplayFSType() == iNativeMode then return end;
    iFullScreenState = iFullScreenState - 1;
    if iFullScreenState < 2 then iFullScreenMode = -2 end;
    UpdateLabels()
  end
  local function FSStateUp()
    if iFullScreenState >= #aWindowLabels-2 or
       DisplayFSType() == iNativeMode then return end;
    iFullScreenState = iFullScreenState + 1;
    if iFullScreenState == 2 then iFullScreenMode = -1 end;
    UpdateLabels()
  end
  -- Resolution callbacks
  local function FSResUpdate()
    if iFullScreenMode == -2 or
       DisplayFSType() == iNativeMode then return "Disabled" end;
    if iFullScreenMode == -1 then return "Automatic" end;
    -- Which one
    local iWidth<const>, iHeight<const>, iBits<const>, nRefresh<const> =
      DisplayVidModeData(GetMonitorIdOrPrimary(), iFullScreenMode);
    -- Return data
    return iWidth.."x"..iHeight.."x"..iBits.." "..nRefresh.."hz ("..
      UtilGetRatio(iWidth, iHeight)..")";
  end
  local function FSResDown()
    if iFullScreenMode <= -1 or
       DisplayFSType() == iNativeMode then
      return end;
    iFullScreenMode = iFullScreenMode - 1;
  end
  local function FSResUp()
    if iFullScreenMode <= -2 or
       DisplayFSType() == iNativeMode or
       iFullScreenMode >= DisplayVidModes(GetMonitorIdOrPrimary())-1 then
      return end;
    iFullScreenMode = iFullScreenMode + 1;
  end
  -- Window size callbacks
  local function WSizeUpdate()
    -- Ignore if in full-screen
    if iFullScreenState ~= 0 or
       DisplayFSType() == iNativeMode then
      return "Disabled" end;
    -- Custom resolution? Return custom resolution label with size
    if iWindowId <= 1 then
      local iWinX<const>, iWinY<const> = DisplayGetSize();
      return aCustomLabels[iWindowId + 1].." "..
        iWinX.."x"..iWinY.." ("..UtilGetRatio(iWinX, iWinY)..")";
    end
    -- Which one
    local aData<const> = aWindowSizes[iWindowId];
    if not aData then return "Unknown ("..iWindowId..")" end;
    -- Return data
    return aData[1].."x"..aData[2]..
      " ("..UtilGetRatio(aData[1], aData[2])..")";
  end
  local function WSizeDown()
    if iFullScreenState ~= 0 or
       DisplayFSType() == iNativeMode then return end;
    iWindowId = iWindowId - 1;
    if iWindowId < 1 then iWindowId = 1 end;
  end
  local function WSizeUp()
    if iFullScreenState ~= 0 or
       DisplayFSType() == iNativeMode then return end;
    iWindowId = iWindowId + 1;
    if iWindowId > #aWindowSizes then iWindowId = #aWindowSizes end;
  end
  -- Frame limiter choice callbacks
  local function GetVarVidVsync()
    return tonumber(VariableGetInt(iCVvidvsync)) end;
  local function GetVarAppDelay()
    return tonumber(VariableGetInt(iCVappdelay)) end;
  local function LimiterGet()
    -- Get VSync value, thread delay and kernel tick rate
    local iFrameLimiter = 1 + GetVarVidVsync();
    -- Check for delay and if set? Set software category too
    if GetVarAppDelay() > 0 then iFrameLimiter = iFrameLimiter + 4 end;
    -- Return value
    return iFrameLimiter;
  end
  local function LimiterUpdate()
    -- Get VSync value, thread delay and kernel tick rate
    local iFrameLimiter = 1 + GetVarVidVsync();
    -- Check for delay and if set? Set software category too
    if GetVarAppDelay() > 0 then iFrameLimiter = iFrameLimiter + 4 end;
    -- Set original value
    return aFrameLimiterLabels[LimiterGet()+1];
  end
  local function LimiterSet(iFrameLimiter)
    -- Set frame limiter options
    local iVSync, iDelay;
    if iFrameLimiter >= 4 then iVSync, iDelay = -1 + (iFrameLimiter % 4), 1;
    else iVSync, iDelay = -1 + iFrameLimiter, 0 end;
    VariableSetInt(iCVvidvsync, iVSync);
    VariableSetInt(iCVappdelay, iDelay);
  end
  local function LimiterDown()
    LimiterSet(UtilClampInt(LimiterGet()-1, 0, #aFrameLimiterLabels-1));
  end
  local function LimiterUp()
    LimiterSet(UtilClampInt(LimiterGet()+1, 0, #aFrameLimiterLabels-1));
  end
  -- Filter choice callbacks
  local function GetVarTexFilter()
    return tonumber(VariableGetInt(iCVtexfilter)) end;
  local function SetVarTexFilter(iV)
    return VariableSetInt(iCVtexfilter, iV) end;
  local function FilterUpdate()
    -- Point filtering if disabled
    if GetVarTexFilter() == 0 then return "Point" end;
    -- Anything else is bilinear
    return "Bilinear";
  end
  local function FilterSwap()
    -- Set enabled (GL_LINEAR) if was disabled
    if GetVarTexFilter() == 0 then return SetVarTexFilter(3) end;
    -- Set disabled (GL_NEAREST) if was enabled
    SetVarTexFilter(0);
  end
  -- Audio device set callbacks
  local function AudioUpdate()
    if iAudioDeviceId == -1 then return "Default Playback Device";
    elseif iAudioDeviceId >= AudioGetNumPBDs() then
      return "Invalid Playback Device" end;
    local sName = AudioGetPBDName(iAudioDeviceId);
    local sPrefix<const> = "OpenAL Soft on ";
    if sName:sub(1, #sPrefix) == sPrefix then sName = sName:sub(#sPrefix) end;
    if #sName > 34 then return sName:sub(0,30).."..." end;
    return sName;
  end
  local function AudioDown()
    if iAudioDeviceId == -1 then return end;
    iAudioDeviceId = iAudioDeviceId - 1;
  end
  local function AudioUp()
    if iAudioDeviceId == AudioGetNumPBDs()-1 then return end;
    iAudioDeviceId = iAudioDeviceId + 1;
  end
  -- Volume set utilities
  local function VPrepare(sCV) return floor(VariableGetInt(sCV)*100).."%" end;
  local function VSet(sCV, iAdj)
    VariableSetInt(sCV,
      UtilClamp(tonumber(VariableGetInt(sCV)) + (iAdj*0.05), 0, 1));
  end
  -- Master volume callbacks
  local function VMasterUpdate() return VPrepare(iCVaudvol) end;
  local function VMasterSet(iAdj) VSet(iCVaudvol, iAdj) end;
  local function VMasterDown() VMasterSet(-1) end;
  local function VMasterUp() VMasterSet(1) end;
  -- Stream volume callbacks
  local function VStreamUpdate() return VPrepare(iCVaudstrvol) end;
  local function VStreamSet(iAdj) VSet(iCVaudstrvol, iAdj) end;
  local function VStreamDown() VStreamSet(-1) end;
  local function VStreamUp() VStreamSet(1) end;
  -- Sample volume callbacks
  local function VSampleSet(iAdj) VSet(iCVaudsamvol, iAdj) end;
  local function VSampleUpdate() return VPrepare(iCVaudsamvol) end;
  local function VSampleDown() VSampleSet(-1) end;
  local function VSampleUp() VSampleSet(1) end;
  -- FMV volume callbacks
  local function VFMVUpdate() return VPrepare(iCVaudfmvvol) end;
  local function VFMVSet(iAdj) VSet(iCVaudfmvvol, iAdj) end;
  local function VFMVDown() VFMVSet(-1) end;
  local function VFMVUp() VFMVSet(1) end;
  -- Apply functions to static option table
  for iIndex, aF in ipairs({
    { MonitorUpdate, MonitorDown, MonitorUp  }, -- [01]
    { FSStateUpdate, FSStateDown, FSStateUp  }, -- [02]
    { FSResUpdate,   FSResDown,   FSResUp    }, -- [03]
    { WSizeUpdate,   WSizeDown,   WSizeUp    }, -- [04]
    { LimiterUpdate, LimiterDown, LimiterUp  }, -- [05]
    { FilterUpdate,  FilterSwap,  FilterSwap }, -- [06]
    { AudioUpdate,   AudioDown,   AudioUp    }, -- [07]
    { VMasterUpdate, VMasterDown, VMasterUp  }, -- [08]
    { VStreamUpdate, VStreamDown, VStreamUp  }, -- [09]
    { VSampleUpdate, VSampleDown, VSampleUp  }, -- [10]
    { VFMVUpdate,    VFMVDown,    VFMVUp     }, -- [11]
  }) do
    local aOptionItem<const> = aSetupOptionData[iIndex];
    aOptionItem[3] = aF[1];
    aOptionItem[4] = aF[2];
    aOptionItem[5] = aF[3];
  end
  -- Setup key bank
  local aGenericEscape<const> = { iEscape, Finish, "sf", "CLOSE" };
  local aOnlyEscape<const> = { [iPress] = { aGenericEscape } };
  -- Setup configuration keys
  iKeyBankSetup = RegisterKeys("SETUP", aOnlyEscape);
  -- Frequently used key ids
  local iPageUp<const>, iPageDown<const>, iHome<const>, iEnd<const>,
    iUp<const>, iDown<const> =
      aKeys.PAGE_UP, aKeys.PAGE_DOWN, aKeys.HOME, aKeys.END, aKeys.UP,
        aKeys.DOWN;
  -- Setup readme keys
  local aReadmePageUp<const>, aReadmePageDown<const>,
        aReadmeHome<const>,   aReadmeEnd<const>,
        aReadmeUp<const>,     aReadmeDown<const> =
    { iPageUp, ScrollReadmePageUp, "srmpu", "SCROLL UP A PAGE" },
    { iPageDown, ScrollReadmePageDown, "srmpd", "SCROLL DOWN A PAGE" },
    { iHome, ScrollReadmeHome, "srmh", "SCROLL TO THE START" },
    { iEnd, ScrollReadmeEnd, "srme", "SCROLL TO THE END" },
    { iUp, ScrollReadmeUp, "srmu", "SCROLL UP A LINE" },
    { iDown, ScrollReadmeDown, "srmd", "SCROLL DOWN A LINE" };
  iKeyBankReadme = RegisterKeys("SETUP ACKNOWLEDGEMENTS", {
    [iPress] = { aGenericEscape, aReadmePageUp, aReadmePageDown,
      aReadmeHome, aReadmeEnd, aReadmeUp, aReadmeDown },
    [iRepeat] = { aReadmePageUp, aReadmePageDown, aReadmeHome,
      aReadmeEnd, aReadmeUp, aReadmeDown },
  });
  -- Setup bind keys
  local aBindsPageUp<const>, aBindsPageDown<const>,
        aBindsHome<const>,   aBindsEnd<const>,
        aBindsUp<const>,     aBindsDown<const> =
    { iPageUp, ScrollBindsPageUp, "sbpu", "SCROLL UP A PAGE"},
    { iPageDown, ScrollBindsPageDown, "sbpd", "SCROLL DOWN A PAGE" },
    { iHome, ScrollBindsHome, "sbh", "SCROLL TO THE START" },
    { iEnd, ScrollBindsEnd, "sbe", "SCROLL TO THE END"},
    { iUp, ScrollBindsUp, "sbu", "SCROLL UP A LINE" },
    { iDown, ScrollBindsDown, "sbd", "SCROLL DOWN A LINE" };
  iKeyBankBind = RegisterKeys("SETUP BINDINGS", {
    [iPress] = { aGenericEscape, aBindsPageUp, aBindsPageDown,
      aBindsHome, aBindsEnd, aBindsUp, aBindsDown },
    [iRepeat] = { aBindsPageUp, aBindsPageDown, aBindsHome,
      aBindsEnd, aBindsUp, aBindsDown },
  });
  -- Init third party credits
  local function Header(sString)
    -- Add ellipsis
    sString = sString.."...";
    -- Add titlebar for credit
    aCreditLines[1 + #aCreditLines] = sString;
    aCreditLines[1 + #aCreditLines] = rep('=', len(sString));
    aCreditLines[1 + #aCreditLines] = "";
  end
  -- Add game name header
  Header(sGameName.." "..sGameVersion);
  -- Write  game information
  aCreditLines[1 + #aCreditLines] = sGameDescription..".";
  aCreditLines[1 + #aCreditLines] =
    "COPYRIGHT (C) "..sGameCopyr:sub(14):upper()..".";
  aCreditLines[1 + #aCreditLines] = "RUNNING ON "..sAppTitle.." "..iAppMajor..
    "."..iAppMinor.."."..iAppBuild.."."..iAppRevision.." FOR "..sAppExeType..
    ".";
  aCreditLines[1 + #aCreditLines] = "SEE HTTPS://"..sGameWebsite..
    " FOR MORE INFORMATION AND UPDATES.";
  aCreditLines[1 + #aCreditLines] = "";
  -- Add third party credits header
  Header("ACKNOWLEDGEMENT OF "..iCredits.." THIRD-PARTY CREDITS");
  -- Enumerate credits so we can build a quick credits list
  local iCreditsM1<const> = iCredits - 1;
  for iIndex = 0, iCreditsM1, 2 do
    -- Get credit information
    local sName<const>, sVersion<const> = CoreLibrary(iIndex);
    -- If we can show another?
    iIndex = iIndex + 1;
    if iIndex <= iCreditsM1 then
      -- Get second credit information
      local sName2<const>, sVersion2<const> = CoreLibrary(iIndex);
      -- Insert both credits
      aCreditLines[1 + #aCreditLines] =
        format("%2d: %-16s %16s  %2d: %-16s %16s",
        iIndex, sName:upper(), "(v"..sVersion:upper()..")",
        iIndex+1, sName2:upper(), "(v"..sVersion2:upper()..")");
    -- Only one left so write last
    else aCreditLines[1 + #aCreditLines] = format("%2d: %-17s %15s", iIndex,
      sName:upper(), "(v"..sVersion:upper()..")") end;
  end
  -- Add space
  aCreditLines[1 + #aCreditLines] = "";
  -- Add licenses header
  Header("LICENSES");
  -- Now for all the other credits in detail
  for iIndex = 0, iCreditsM1 do
    -- Get credit information
    local sName<const>, sVersion<const>, bCopyright, sAuthor<const> =
      CoreLibrary(iIndex);
    -- Set copyright
    if bCopyright then bCopyright = "(C)";
                  else bCopyright = "BY" end;
    -- Line to write
    Header((iIndex+1)..". USES "..sName:upper().." "..bCopyright.." "..
      sAuthor:upper());
    -- Add credit license
    local aLines<const> = UtilExplode(CoreLicense(iIndex), "\n");
    for iIndex = 1, #aLines do
      local sLine<const> = aLines[iIndex];
      if #sLine > 78 then
        local aWrappedLines<const> = UtilWordWrap(sLine, iReadmeCols, 0);
        for iWI = 1, #aWrappedLines do
          aCreditLines[1 + #aCreditLines] = aWrappedLines[iWI]:upper();
        end
      else aCreditLines[1 + #aCreditLines] = sLine:upper() end;
    end
  end
  -- Add third party credits header
  aCreditLines[1 + #aCreditLines] = "*** END-OF-FILE ***";
  -- Init text colours
  for iIndex = 1, iReadmeRows do
    aReadmeColourData[1 + #aReadmeColourData] =
      (iIndex / iReadmeRows) * 0.25 end;
  -- Truncate bottom empty lines
  while #aCreditLines > 0 and #aCreditLines[#aCreditLines] == 0 do
    remove(aCreditLines, #aCreditLines) end;
  -- Get flag for a unsigned integer saveable cvar type
  local iSS<const> = Variable.Flags.UINTEGERSAVE;
  -- Build bindings list
  for iBind = 1, #aKeyBankCats do
    -- Get bind data
    local aBind<const> = aKeyBankCats[iBind];
    -- Create a cvar for key
    local function CVarModified(sV)
      -- Convert to number and check it
      sV = floor(tonumber(sV));
      if sV < 0 and sV >= 1000 then return false end;
      -- Update actual keybind and literal value
      aBind[1] = sV;
      local sValue<const> = aKeyToLiteral[sV] or aKeyToLiteral.UNKNOWN;
      aBind[8] = sValue.." ["..format("%03d", sV).."]";
      aBind[9] = sValue;
      -- Accepted
      return true;
    end
    -- Register a variable for it
    aBind[7] = VariableRegister("gam_key_"..aBind[3], aBind[1], iSS,
      CVarModified);
    -- Put in bindings list
    aBindingsList[1 + #aBindingsList] = aBind;
  end
  -- Sort the bindings list
  local function BindSortFunction(aA, aB) return aA[6] < aB[6] end;
  sort(aBindingsList, BindSortFunction);
  -- Set sound effect ids
  local aSfxData<const> = GetAPI("aSfxData");
  iSClick, iSSelect = aSfxData.CLICK, aSfxData.SELECT;
  -- Set cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCArrow, iCBottom, iCSelect, iCTop, iCWait =
    aCursorIdData.ARROW, aCursorIdData.BOTTOM, aCursorIdData.SELECT,
    aCursorIdData.TOP, aCursorIdData.WAIT;
end
-- Return imports and exports ---------------------------------------------- --
return { A = { InitSetup = InitSetup }, F = OnReady };
-- == End-of-File ========================================================== --

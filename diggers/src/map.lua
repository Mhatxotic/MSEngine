-- MAP.LUA ================================================================= --
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
local pairs<const> = pairs;
-- M-Engine function aliases ----------------------------------------------- --
local CoreTicks<const>, InputSetCursorPos<const>, UtilClampInt<const> =
  Core.Ticks, Input.SetCursorPos, Util.ClampInt;
-- Diggers function and data aliases --------------------------------------- --
local Fade, GetMouseX, GetMouseY, InitCon, InitLobby, IsButtonPressed,
  IsButtonReleased, IsMouseInBounds, IsMouseNotInBounds,
  IsMouseXGreaterEqualThan, IsMouseXLessThan,  IsMouseYGreaterEqualThan,
  IsMouseYLessThan, IsScrollingDown, IsScrollingUp, LoadResources,
  PlayStaticSound, RegisterFBUCallback, SetBottomRightTipAndShadow,
  SetCallbacks, SetCursor, SetKeys, aGlobalData, aLevelsData, aZoneData;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "map", P = { 0 } } };
-- Locals ------------------------------------------------------------------ --
local aZoneAvail,                      -- Zones available
      aZoneCache, aFlagCache,          -- Zone hot points and completion cache
      iCBottom, iCSelect, iCArrow,     -- More cursor ids
      iCLeft, iCRight, iCTop, iCExit,  -- Cursor ids
      iKeyBankId;                      -- Key bank id for keys
local iMapSizeX<const>,                -- Map size pixel width
      iMapSizeY<const> = 640, 350;     -- Map size pixel height
local iSClick, iSSelect,               -- Sound effect ids
      iStageL, iStageT,                -- Stage upper-left co-ordinates
      iStageLneg, iStageTneg,          -- Negatated upper-left stage co-ords
      iTileFlagTexId,                  -- Texture id for flag sprite
      iZone;                           -- Currently selected zone
local iZoneAvail = 0;                  -- Currently scrolled available zone
local iZoneMaxX, iZoneMaxY;            -- Maximum map bounds
local iZonePosX, iZonePosY = 0, 0;     -- Map scroll position
local sTip,                            -- Current tip string
      texZone;                         -- Zone map graphics texture
-- Set specific object ----------------------------------------------------- --
local function SetZone(iAdjust)
  -- Don't do anything if no objects
  if #aZoneAvail == 0 then return end;
  -- Play sound
  PlayStaticSound(iSClick);
  -- Set new zone
  iZoneAvail = iZoneAvail + iAdjust;
  -- Modulo it if it's out of range
  if iZoneAvail < 1 or iZoneAvail > #aZoneAvail then
    iZoneAvail = 1 + ((iZoneAvail - 1) % #aZoneAvail) end;
  -- Get zone data and move to an actual zone that isn't completed
  local aZone<const> = aZoneData[aZoneAvail[iZoneAvail]];
  -- Centre map on zone point
  iZonePosX = UtilClampInt(aZone[1] - 160, 0, iZoneMaxX);
  iZonePosY = UtilClampInt(aZone[2] - 120, 0, iZoneMaxY);
  -- Set the new cursor position
  InputSetCursorPos(aZone[6] - (iZonePosX - iStageL),
                    aZone[7] - (iZonePosY - iStageT));
end
-- Cycle between objects --------------------------------------------------- --
local function NextZone() SetZone(1) end;
local function PreviousZone() SetZone(-1) end;
-- On frame buffer updated ------------------------------------------------- --
local function OnFrameBufferUpdate(...)
  -- Update stage bounds
  local _ _, _, iStageL, iStageT, _, _ = ...;
  -- Get negated stage left co-ordinate
  iStageLneg = -iStageL;
  iStageTneg = -iStageT;
  -- Update maximums
  iZoneMaxX = 320 + (iStageL * 2);
  iZoneMaxY = 110 + (iStageT * 2);
end
-- Render the map ---------------------------------------------------------- --
local function RenderMap()
  -- Draw main chunk of map
  texZone:BlitLT(-iZonePosX + iStageL, -iZonePosY + iStageT);
  -- For each flag data in flag cache
  for iFlagId = 1, #aFlagCache do
    -- Get flag data
    local aFlagData<const> = aFlagCache[iFlagId];
    -- Draw the flag to say the level was completed
    texZone:BlitSLT(iTileFlagTexId, aFlagData[1] - (iZonePosX + iStageLneg),
                                    aFlagData[2] - (iZonePosY + iStageTneg));
  end
  -- Draw tip
  if sTip then SetBottomRightTipAndShadow(sTip) end;
end
-- Finish map screen function ---------------------------------------------- --
local function Finish()
  -- Play sound
  PlayStaticSound(iSSelect);
  -- When screen has faded out
  local function OnFadeOut()
    -- Remove FBO update callback
    RegisterFBUCallback("map");
    -- Dereference assets to garbage collector
    texZone = nil;
    -- Init controller screen
    InitCon();
  end
  -- Start fading out
  Fade(0, 1, 0.04, RenderMap, OnFadeOut);
end
-- Save and finish map screen function ------------------------------------- --
local function FinishAndAccept()
  -- Set new selected level
  aGlobalData.gSelectedLevel = iZone;
  -- Finished
  Finish();
end
-- Mouse over the exit ----------------------------------------------------- --
local function MouseOverExit()
  -- Set tip
  sTip = "CONTROLLER";
  -- Set select cursor
  SetCursor(iCExit);
  -- Button was pressed?
  if IsButtonPressed(0) then Finish() end;
end
-- Input procedure --------------------------------------------------------- --
local function InputMap()
  -- Scrolling up?
  if IsScrollingUp() then NextZone();
  elseif IsScrollingDown() then PreviousZone() end;
  -- Cursor at left edge of screen?
  if IsMouseXLessThan(16) then
    -- Map at left edge?
    if iZonePosX > 0 then
      -- Set left scroll cursor
      SetCursor(iCLeft);
      -- Update X position
      iZonePosX = UtilClampInt(iZonePosX - 8, 0, iZoneMaxX);
    -- Not at left edge so chance to exit without selecting
    else MouseOverExit() end;
    -- Done
    return;
  -- Cursor at right edge of screen?
  elseif IsMouseXGreaterEqualThan(304) then
    -- Map at right edge?
    if iZonePosX < iZoneMaxX then
      -- Set right scroll cursor
      SetCursor(iCRight);
      -- Update X position
      iZonePosX = UtilClampInt(iZonePosX + 8, 0, iZoneMaxX);
    -- Not at right edge so chance to exit without selecting
    else MouseOverExit() end;
    -- Done
    return;
  -- Cursor at top edge of screen?
  elseif IsMouseYLessThan(16) then
    -- Map at top edge?
    if iZonePosY > 0 then
      -- Set top scroll cursor
      SetCursor(iCTop);
      -- Update Y position
      iZonePosY = UtilClampInt(iZonePosY - 8, 0, iZoneMaxY);
    -- Not at top edge so chance to exit without selecting
    else MouseOverExit() end;
    -- Done
    return;
  -- Cursor at bottom edge of screen?
  elseif IsMouseYGreaterEqualThan(224) then
    -- Map at bottom edge?
    if iZonePosY < iZoneMaxY then
      -- Set bottom scroll cursor
      SetCursor(iCBottom);
      -- Update Y position
      iZonePosY = UtilClampInt(iZonePosY + 8, 0, iZoneMaxY);
    -- Not at bottom edge so chance to exit without selecting
    else MouseOverExit() end;
    -- Done
    return;
  -- Anything else?
  else
    -- Get mouse position on whole map adjusted by current map scroll
    local iX<const> = GetMouseX() + iZonePosX + iStageLneg;
    local iY<const> = GetMouseY() + iZonePosY;
    -- For each map data available
    for iZoneId = 1, #aZoneData do
      -- Get map data;
      local aZoneItem<const> = aZoneData[iZoneId];
      -- Mouse cursor inside zone boundary?
      if iX >= aZoneItem[1] and iY >= aZoneItem[2] and
         iX <  aZoneItem[3] and iY <  aZoneItem[4] then
        -- Return cache'd info of zone
        iZone = aZoneCache[iZoneId];
        if iZone then
          -- Set select cursor
          SetCursor(iCSelect);
          -- Get information about selected zone
          local aLevel<const> = aLevelsData[iZone];
          -- Get current time (rotated every 60 frames/1 second)
          local iTicks<const> = CoreTicks() % 180;
          -- Show name of zone at 0 to 1 seconds
          if iTicks < 60 then sTip = aLevel.n;
          -- Show terrain type at 1 to 2 seconds
          elseif iTicks < 120 then sTip = aLevel.t.n;
          -- Show Zogs needed to win at 2 to 3 seconds
          else sTip = aLevel.w.." TO WIN" end;
          -- Button was pressed?
          if IsButtonPressed(0) then FinishAndAccept() end
          -- Got a zone
          return;
        end
        -- Matched a hot zone
        break;
      end
    end
    -- No zone selected
    iZone = nil;
  end
  -- No valid zone selected so set arrow cursor
  SetCursor(iCArrow);
  -- Tell user to put mouse over a valid zone
  sTip = "SELECT ZONE";
end
-- On map faded in --------------------------------------------------------- --
local function OnFadeIn()
  -- Set key bank
  SetKeys(true, iKeyBankId);
  -- Set map callbacks
  SetCallbacks(nil, RenderMap, InputMap);
end
-- On loaded --------------------------------------------------------------- --
local function OnLoaded(aResources)
  -- Register frame buffer update
  RegisterFBUCallback("map", OnFrameBufferUpdate);
  -- Set texture handles
  texZone = aResources[1];
  texZone:TileSTC(1);
  texZone:TileS(0, 0, 0, 672, 350);
  iTileFlagTexId = texZone:TileA(640, 0, 672, 32);
  -- Clear zone and flag cache
  aZoneCache, aFlagCache, aZoneAvail = { }, { }, { };
  -- Rebuild flag data cache
  for iZoneId in pairs(aGlobalData.gLevelsCompleted) do
    aFlagCache[1 + #aFlagCache] = aZoneData[iZoneId][8];
  end
  -- Rebuild zone data cache
  for iZoneId = 1, #aZoneData do
    local aZoneItem<const> = aZoneData[iZoneId];
    local iZoneCompleted;
    if not aGlobalData.gLevelsCompleted[iZoneId] then
      local aDep<const> = aZoneItem[5];
      if #aDep ~= 0 then
        for iDepId = 1, #aDep do
          local iDepZone<const> = aDep[iDepId];
          if aGlobalData.gLevelsCompleted[iDepZone] then
            iZoneCompleted = iZoneId;
            break;
          end
        end
      else iZoneCompleted = iZoneId end;
    end
    -- Set completed or not
    if iZoneCompleted then
      aZoneCache[1 + #aZoneCache] = iZoneCompleted;
      aZoneAvail[1 + #aZoneAvail] = iZoneCompleted;
    else
      aZoneCache[1 + #aZoneCache] = false;
    end
  end
  -- Change render procedures
  Fade(1, 0, 0.04, RenderMap, OnFadeIn);
end
-- Init zone selection screen function ------------------------------------- --
local function InitMap()
  -- Load texture resource
  LoadResources("Map Select", aAssets, OnLoaded);
end
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  Fade, GetMouseX, GetMouseY, InitCon, InitLobby, IsButtonPressed,
    IsButtonReleased, IsMouseInBounds, IsMouseNotInBounds,
    IsMouseXGreaterEqualThan, IsMouseXLessThan, IsMouseYGreaterEqualThan,
    IsMouseYLessThan, IsScrollingDown, IsScrollingUp, LoadResources,
    PlayStaticSound, RegisterFBUCallback, SetBottomRightTipAndShadow,
    SetCallbacks, SetCursor, SetKeys, aGlobalData, aLevelsData, aZoneData =
      GetAPI("Fade", "GetMouseX", "GetMouseY", "InitCon", "InitLobby",
        "IsButtonPressed", "IsButtonReleased", "IsMouseInBounds",
        "IsMouseNotInBounds", "IsMouseXGreaterEqualThan", "IsMouseXLessThan",
        "IsMouseYGreaterEqualThan", "IsMouseYLessThan", "IsScrollingDown",
        "IsScrollingUp", "LoadResources", "PlayStaticSound",
        "RegisterFBUCallback", "SetBottomRightTipAndShadow", "SetCallbacks",
        "SetCursor", "SetKeys", "aGlobalData", "aLevelsData",
        "aZoneData");
  -- Key callbacks
  local function FinishAndAcceptCheck()
    if iZone then FinishAndAccept() end end
  -- Register keybinds
  local aKeys<const> = Input.KeyCodes;
  iKeyBankId = GetAPI("RegisterKeys")("ZMTC ZONE SELECT", {
    [Input.States.PRESS] = {
      { aKeys.ESCAPE, Finish, "zmtczsc", "CANCEL" },
      { aKeys.ENTER, FinishAndAcceptCheck, "zmtczsa", "ACCEPT" },
      { aKeys.LEFT, PreviousZone, "zmtczpz", "PREVIOUS" },
      { aKeys.RIGHT, NextZone, "zmtcznz", "NEXT" },
    }
  });
  -- Set cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCLeft, iCRight, iCTop, iCBottom, iCSelect, iCArrow, iCExit =
    aCursorIdData.LEFT, aCursorIdData.RIGHT, aCursorIdData.TOP,
      aCursorIdData.BOTTOM, aCursorIdData.SELECT, aCursorIdData.ARROW,
      aCursorIdData.EXIT;
  -- Set sound effect ids
  local aSfxData<const> = GetAPI("aSfxData");
  iSSelect, iSClick = aSfxData.SELECT, aSfxData.CLICK;
  -- Add centre positions for zone data
  for iIndex = 1, #aZoneData do
    -- Get zone data, calculate and set centre position
    local aZone<const> = aZoneData[iIndex];
    local iX<const>, iY<const> = aZone[1], aZone[2];
    local iCX<const>, iCY<const> =
      iX + ((aZone[3] - iX) // 2), iY + ((aZone[4] - iY) // 2);
    aZone[6], aZone[7] = iCX, iCY;
    -- Calculate flag position
    aZone[8] = { iCX - 16, iCY - 16, iCX + 16, iCY + 16 };
  end
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitMap = InitMap }, F = OnReady };
-- End-of-File ============================================================= --

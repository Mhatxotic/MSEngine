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
  SetCallbacks, SetCursor, SetKeys, aCursorIdData, aGlobalData, aLevelsData,
  aSfxData, aZoneData;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "map", P = { 0 } } };
-- Locals ------------------------------------------------------------------ --
local aZoneAvail;                      -- Zones available
local aZoneCache, aFlagCache;          -- Zone hot points and completion cache
local iKeyBankId;                      -- Key bank id for keys
local iMapSizeX<const>,                -- Map size pixel width
      iMapSizeY<const> = 640, 350;     -- Map size pixel height
local iStageL, iStageT;                -- Stage upper-left co-ordinates
local iStageLneg, iStageTneg;          -- Negatated upper-left stage co-ords
local iTileFlagTexId;                  -- Texture id for flag sprite
local iZone;                           -- Currently selected zone
local iZoneAvail = 0;                  -- Currently scrolled available zone
local iZoneMaxX, iZoneMaxY;            -- Maximum map bounds
local iZonePosX, iZonePosY = 0, 0;     -- Map scroll position
local sTip = "";                       -- Current tip string
local texZone;                         -- Zone map graphics texture
-- Cursor ids -------------------------------------------------------------- --
local iLeft, iRight, iTop, iBottom, iSelect, iArrow, iExit;
-- Set specific object ----------------------------------------------------- --
local function SetZone(iAdjust)
  -- Don't do anything if no objects
  if #aZoneAvail == 0 then return end;
  -- Set new zone
  iZoneAvail = iZoneAvail + iAdjust;
  -- Modulo it if it's out of range
  if iZoneAvail < 1 or iZoneAvail > #aZoneAvail then
    iZoneAvail = 1 + ((iZoneAvail - 1) % #aZoneAvail) end;
  -- Get zone data and move to an actual zone that isn't completed
  local aZone<const> = aZoneData[aZoneAvail[iZoneAvail]];
  -- Calculate centre position
  local iX<const> = aZone[1];
  local iCentreX<const> = iX + ((aZone[3] - iX) // 2);
  local iY<const> = aZone[2];
  local iCentreY<const> = iY + ((aZone[4] - iY) // 2);
  -- Clamp viewport on map
  iZonePosX = UtilClampInt(iX - 160, 0, iZoneMaxX);
  iZonePosY = UtilClampInt(iY - 120, 0, iZoneMaxY);
  -- Set the new cursor position
  InputSetCursorPos(iCentreX - (iZonePosX - iStageL),
                    iCentreY - (iZonePosY - iStageT));
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
-- Play click sound and finish map screen function ------------------------- --
local function ClickAndFinish()
  -- Play sound
  PlayStaticSound(aSfxData.SELECT);
  -- Fade out to controller screen
  Finish();
end
-- Mouse over the exit ----------------------------------------------------- --
local function MouseOverExit()
  -- Set tip
  sTip = "CONTROLLER";
  -- Set select cursor
  SetCursor(iExit);
  -- Button was pressed?
  if IsButtonPressed(0) then ClickAndFinish() end;
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
      SetCursor(iLeft);
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
      SetCursor(iRight);
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
      SetCursor(iTop);
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
      SetCursor(iBottom);
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
          SetCursor(iSelect);
          -- Button was pressed?
          if IsButtonPressed(0) then
            -- Set new selected level
            aGlobalData.gSelectedLevel = iZone;
            -- Finished
            ClickAndFinish();
          end
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
  SetCursor(iArrow);
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
  texZone = aResources[1].H;
  texZone:TileSTC(1);
  texZone:TileS(0, 0, 0, 672, 350);
  iTileFlagTexId = texZone:TileA(640, 0, 672, 32);
  -- Clear zone and flag cache
  aZoneCache, aFlagCache, aZoneAvail = { }, { }, { };
  -- Rebuild flag data cache
  for iZoneId in pairs(aGlobalData.gLevelsCompleted) do
    local aZoneItem<const> = aZoneData[iZoneId];
    local iFlagX<const>, iFlagY<const> = aZoneItem[5], aZoneItem[6];
    aFlagCache[1 + #aFlagCache] = { iFlagX, iFlagY, iFlagX+32, iFlagY+32 };
  end
  -- Rebuild zone data cache
  for iZoneId = 1, #aZoneData do
    local aZoneItem<const> = aZoneData[iZoneId];
    local iZoneCompleted;
    if not aGlobalData.gLevelsCompleted[iZoneId] then
      local aDep<const> = aZoneItem[7];
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
    SetCallbacks, SetCursor, SetKeys, aCursorIdData, aGlobalData, aLevelsData,
    aSfxData, aZoneData =
      GetAPI("Fade", "GetMouseX", "GetMouseY", "InitCon", "InitLobby",
        "IsButtonPressed", "IsButtonReleased", "IsMouseInBounds",
        "IsMouseNotInBounds", "IsMouseXGreaterEqualThan", "IsMouseXLessThan",
        "IsMouseYGreaterEqualThan", "IsMouseYLessThan", "IsScrollingDown",
        "IsScrollingUp", "LoadResources", "PlayStaticSound",
        "RegisterFBUCallback", "SetBottomRightTipAndShadow", "SetCallbacks",
        "SetCursor", "SetKeys", "aCursorIdData", "aGlobalData", "aLevelsData",
        "aSfxData", "aZoneData");
  -- Register keybinds
  local aKeys<const>, aStates<const> = Input.KeyCodes, Input.States;
  iKeyBankId = GetAPI("RegisterKeys")("ZONE SELECT", {
    [aStates.PRESS] = {
      { aKeys.ESCAPE, Finish, "zsc", "CANCEL" },
      { aKeys.MINUS, PreviousZone, "zpz", "PREVIOUS ZONE" },
      { aKeys.EQUAL, NextZone, "znz", "NEXT ZONE" },
    }
  });
  -- Set cursor ids
  iLeft, iRight, iTop, iBottom, iSelect, iArrow, iExit =
    aCursorIdData.LEFT, aCursorIdData.RIGHT, aCursorIdData.TOP,
      aCursorIdData.BOTTOM, aCursorIdData.SELECT, aCursorIdData.ARROW,
      aCursorIdData.EXIT;
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitMap = InitMap }, F = OnReady };
-- End-of-File ============================================================= --

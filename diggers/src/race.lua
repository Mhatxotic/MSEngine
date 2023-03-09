-- CNTRL.LUA =============================================================== --
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
-- Core function aliases --------------------------------------------------- --
-- M-Engine function aliases ----------------------------------------------- --
-- Diggers function and data aliases --------------------------------------- --
local Fade, InitCon, IsButtonPressed, IsMouseInBounds, IsMouseNotInBounds,
  IsScrollingDown, IsScrollingUp, LoadResources, PlayStaticSound, RenderShadow,
  SetBottomRightTipAndShadow, SetCallbacks, SetCursor, TypeIdToId,
  aCursorIdData, aGlobalData, aRaceStatData, aSfxData, texSpr;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "lobbyc", P = { 0 } },
                         { T = 1, F = "race",   P = { 64, 128, 1, 1, 0 } } };
-- Init race screen function ----------------------------------------------- --
local function InitRace()
  -- Data loaded function
  local function OnLoaded(aResources)
    -- Setup lobby texture
    local texLobby = aResources[1].H;
    texLobby:TileSTC(1);
    texLobby:TileS(0, 0, 272, 428, 512);
    -- Get texture resource and trim texture coordinates list to 5
    local texRace = aResources[2].H;
    texRace:TileSTC(5);
    -- Cache other tiles
    local iTileName<const> = texRace:TileA(0, 496, 160, 512);
                             texRace:TileA(0, 479, 160, 495);
                             texRace:TileA(0, 462, 160, 478);
                             texRace:TileA(0, 445, 160, 461);
    local iTileBG<const> = texRace:TileA(208, 312, 512, 512);
    local iTileSpecial<const> = texRace:TileA(190, 496, 206, 512);
                                texRace:TileA(171, 496, 187, 512);
    -- Currently visible race id and selected race data
    local iRaceId, aRaceDataSelected;
    -- Set clamped race id and race data
    local function SetRace(iId)
      iRaceId = iId % #aRaceStatData;
      aRaceDataSelected = aRaceStatData[iRaceId + 1];
    end
    -- Adjust race function
    local function AdjustRace(iAmount)
      PlayStaticSound(aSfxData.CLICK);
      SetRace(iRaceId + iAmount);
    end
    -- Set currently selected race
    local iRaceIdSelected = aGlobalData.gSelectedRace;
    -- Set race already selected
    SetRace(iRaceIdSelected or 0);
    -- Tip text
    local sTip;
    -- Render race
    local function RenderRace()
      -- Draw backdrop, race screen and it's shadow
      texLobby:BlitLT(-54, 0);
      texRace:BlitSLT(iTileBG, 8, 8);
      RenderShadow(8, 8, 312, 208);
      -- Draw race and title text
      texRace:BlitSLT(iRaceId, 172, 54);
      texRace:BlitSLT(iTileName+iRaceId, 80, 24);
      -- Draw stats
      texSpr:BlitSLTRB(801, 115,  62, 115+aRaceDataSelected[2],  65);
      texSpr:BlitSLTRB(801, 115,  82, 115+aRaceDataSelected[3],  85);
      texSpr:BlitSLTRB(801, 115, 102, 115+aRaceDataSelected[4], 105);
      texSpr:BlitSLTRB(801, 115, 122, 115+aRaceDataSelected[5], 125);
      texSpr:BlitSLTRB(801, 115, 142, 115+aRaceDataSelected[6], 145);
      texSpr:BlitSLTRB(801, 115, 162, 115+aRaceDataSelected[7], 165);
      -- Draw special
      if aRaceDataSelected[8] >= 0 then
        texRace:BlitSLT(iTileSpecial+aRaceDataSelected[8], 110, 175);
      end
      -- Draw selected symbol
      if iRaceId == iRaceIdSelected then
        texRace:BlitSLT(4, 132, 80, 192, 208);
      end
      -- Draw tip
      SetBottomRightTipAndShadow(sTip);
    end
    -- Finish so fade out
    local function Finished()
      -- Play select sound
      PlayStaticSound(aSfxData.SELECT);
      -- When faded out?
      local function OnFadeOut()
        -- Dereference assets for garbage collector
        texRace, texLobby = nil, nil;
        -- Load controller screen
        InitCon();
      end
      -- Fade out to controller screen
      Fade(0, 1, 0.04, RenderRace, OnFadeOut);
    end
    -- Proc race function
    local function InputRace()
      -- Mouse wheel scrolled down? Previous race
      if IsScrollingDown() then AdjustRace(-1);
      -- Mouse wheel scrolled up? Next race
      elseif IsScrollingUp() then AdjustRace(1);
      -- Mouse over race pic
      elseif IsMouseInBounds(172, 54, 236, 182) then
        -- Set accept tip
        sTip = "ACCEPT";
        SetCursor(aCursorIdData.OK);
        -- Mouse button clicked? Set race and fade out to controller
        if IsButtonPressed(0) then
          aGlobalData.gSelectedRace, iRaceIdSelected =
            aRaceDataSelected[1], iRaceId;
          Finished();
        end
      -- Mouse over next race arrow?
      elseif IsMouseInBounds(248, 192, 264, 208) then
        -- Set tip
        sTip = "NEXT";
        SetCursor(aCursorIdData.SELECT);
        -- Mouse button clicked? Next race
        if IsButtonPressed(0) then AdjustRace(1) end;
      -- Mouse over the exit area?
      elseif IsMouseNotInBounds(8, 8, 312, 208) then
        -- Set tip
        sTip = "CANCEL";
        SetCursor(aCursorIdData.EXIT);
        -- Mouse button clicked? Go back to controller screen
        if IsButtonPressed(0) then Finished() end;
      -- Nothing selected
      else
        sTip = "SELECT RACE";
        SetCursor(aCursorIdData.ARROW);
      end;
    end
    -- Proc race function while fading
    local function ProcRaceInitial()
      SetCallbacks(nil, RenderRace, InputRace);
    end
    -- Fade in
    Fade(1, 0, 0.04, RenderRace, ProcRaceInitial);
  end
  -- Load resources
  LoadResources("Race Select", aAssets, OnLoaded);
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitRace = InitRace }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  Fade, InitCon, IsButtonPressed, IsMouseInBounds, IsMouseNotInBounds,
  IsScrollingDown, IsScrollingUp, LoadResources, PlayStaticSound, RenderShadow,
  SetBottomRightTipAndShadow, SetCallbacks, SetCursor, aCursorIdData,
  aGlobalData, aRaceStatData, aSfxData, texSpr
  = -- --------------------------------------------------------------------- --
  GetAPI("Fade", "InitCon", "IsButtonPressed", "IsMouseInBounds",
    "IsMouseNotInBounds", "IsScrollingDown", "IsScrollingUp", "LoadResources",
    "PlayStaticSound", "RenderShadow", "SetBottomRightTipAndShadow",
    "SetCallbacks", "SetCursor", "aCursorIdData", "aGlobalData",
    "aRaceStatData", "aSfxData", "texSpr");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

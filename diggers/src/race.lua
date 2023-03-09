-- CNTRL.LUA =============================================================== --
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
-- M-Engine function aliases ----------------------------------------------- --
-- Diggers function and data aliases --------------------------------------- --
local Fade, InitCon, IsButtonPressed, IsMouseInBounds, IsMouseNotInBounds,
  IsScrollingDown, IsScrollingUp, LoadResources, PlayStaticSound, RenderShadow,
  SetBottomRightTipAndShadow, SetCallbacks, SetCursor, SetKeys, TypeIdToId,
   aGlobalData, aRaceStatData, texSpr;
-- Locals ------------------------------------------------------------------ --
local aRaceDataSelected;               -- Race id data
local iCArrow, iCExit, iCOK, iCSelect; -- Cursor ids
local iKeyBankId;                      -- Key bank id
local iRaceId;                         -- Chosen race id
local iRaceIdSelected;                 -- Currently displayed race id
local iSClick, iSSelect;               -- Sound effects used
local iTileBG;                         -- Race screen background
local iTileName;                       -- First race texture
local iTileSpecial;                    -- Special items tile
local sTip;                            -- Tip text
local texLobby;                        -- Lobby texture
local texRace;                         -- Race texture
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "lobbyc", P = { 0 } },
                         { T = 1, F = "race",   P = { 64, 128, 1, 1, 0 } } };
-- Set clamped race id and race data --------------------------------------- --
local function SetRace(iId)
  iRaceId = iId % #aRaceStatData;
  aRaceDataSelected = aRaceStatData[iRaceId + 1];
end
-- Adjust race function ---------------------------------------------------- --
local function AdjustRace(iAmount)
  PlayStaticSound(iSClick);
  SetRace(iRaceId + iAmount);
end
-- Cycle race function ----------------------------------------------------- --
local function RacePrevious() AdjustRace(-1) end;
local function RaceNext() AdjustRace(1) end;
-- Render race ------------------------------------------------------------- --
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
  if iRaceId == iRaceIdSelected then texRace:BlitSLT(4, 132, 80, 192, 208) end;
  -- Draw tip
  SetBottomRightTipAndShadow(sTip);
end
-- Finish so fade out ------------------------------------------------------ --
local function Finish()
  -- Play select soud
  PlayStaticSound(iSSelect)
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
-- Finish so fade out ------------------------------------------------------ --
local function FinishAccept()
  -- Apply new setting
  aGlobalData.gSelectedRace, iRaceIdSelected =
    aRaceDataSelected[1], iRaceId;
  -- Fade out to lobby
  Finish();
end
-- Set tip and cursor ------------------------------------------------------ --
local function SetTipAndCursor(sNTip, iCId) sTip = sNTip SetCursor(iCId) end;
-- Proc race function ------------------------------------------------------ --
local function InputRace()
  -- Mouse wheel scrolled down? Previous race
  if IsScrollingDown() then RacePrevious();
  -- Mouse wheel scrolled up? Next race
  elseif IsScrollingUp() then RaceNext();
  -- Mouse over race pic
  elseif IsMouseInBounds(172, 54, 236, 182) then
    -- Set accept tip
    SetTipAndCursor("ACCEPT", iCOK);
    -- Mouse button clicked? Set race and fade out to controller
    if IsButtonPressed(0) then FinishAccept() end;
  -- Mouse over next race arrow?
  elseif IsMouseInBounds(248, 192, 264, 208) then
    -- Set tip
    SetTipAndCursor("NEXT", iCSelect);
    -- Mouse button clicked? Next race
    if IsButtonPressed(0) then RaceNext() end;
  -- Mouse over the exit area?
  elseif IsMouseNotInBounds(8, 8, 312, 208) then
    -- Set tip
    SetTipAndCursor("CANCEL", iCExit);
    -- Mouse button clicked? Go back to controller screen
    if IsButtonPressed(0) then Finish() end;
  -- Nothing selected
  else SetTipAndCursor("SELECT RACE", iCArrow) end;
end
-- Proc race function while fading ----------------------------------------- --
local function ProcRaceInitial()
  -- Enable keybank
  SetKeys(true, iKeyBankId);
  -- Set callbacks
  SetCallbacks(nil, RenderRace, InputRace);
end
-- Data loaded function ---------------------------------------------------- --
local function OnLoaded(aResources)
  -- Setup lobby texture
  texLobby = aResources[1];
  texLobby:TileSTC(1);
  texLobby:TileS(0, 0, 272, 428, 512);
  -- Get texture resource and trim texture coordinates list to 5
  texRace = aResources[2];
  texRace:TileSTC(5);
  -- Cache other tiles
  iTileName = texRace:TileA(0, 496, 160, 512);
              texRace:TileA(0, 479, 160, 495);
              texRace:TileA(0, 462, 160, 478);
              texRace:TileA(0, 445, 160, 461);
  iTileBG = texRace:TileA(208, 312, 512, 512);
  iTileSpecial = texRace:TileA(190, 496, 206, 512);
                 texRace:TileA(171, 496, 187, 512);
  -- Set currently selected race
  iRaceIdSelected = aGlobalData.gSelectedRace;
  -- Set race already selected
  SetRace(iRaceIdSelected or 0);
  -- Fade in
  Fade(1, 0, 0.04, RenderRace, ProcRaceInitial);
end
-- Init race screen function ----------------------------------------------- --
local function InitRace() LoadResources("Race Select", aAssets, OnLoaded) end;
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  Fade, InitCon, IsButtonPressed, IsMouseInBounds, IsMouseNotInBounds,
    IsScrollingDown, IsScrollingUp, LoadResources, PlayStaticSound,
    RenderShadow, SetBottomRightTipAndShadow, SetCallbacks, SetCursor,
    SetKeys, aGlobalData, aRaceStatData, texSpr =
      GetAPI("Fade", "InitCon", "IsButtonPressed", "IsMouseInBounds",
        "IsMouseNotInBounds", "IsScrollingDown", "IsScrollingUp",
        "LoadResources", "PlayStaticSound", "RenderShadow",
        "SetBottomRightTipAndShadow", "SetCallbacks", "SetCursor", "SetKeys",
        "aGlobalData", "aRaceStatData", "texSpr");
  -- Register keybinds
  local aKeys<const> = Input.KeyCodes;
  iKeyBankId = GetAPI("RegisterKeys")("ZMTC RACE SELECT", {
    [Input.States.PRESS] = {
      { aKeys.ESCAPE, Finish, "zmtcrsc", "CANCEL" },
      { aKeys.ENTER, FinishAccept, "zmtcrsa", "ACCEPT" },
      { aKeys.LEFT, RacePrevious, "zmtcrsp", "PREVIOUS" },
      { aKeys.RIGHT, RaceNext, "zmtcrsn", "NEXT" },
    }
  });
  -- Set sound effect ids
  local aSfxData<const> = GetAPI("aSfxData");
    iSClick, iSSelect = aSfxData.CLICK, aSfxData.SELECT;
  -- Set cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCOK, iCSelect, iCExit, iCArrow = aCursorIdData.OK, aCursorIdData.SELECT,
    aCursorIdData.EXIT, aCursorIdData.ARROW;
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitRace = InitRace }, F = OnReady };
-- End-of-File ============================================================= --

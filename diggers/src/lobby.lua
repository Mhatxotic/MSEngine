-- LOBBY.LUA =============================================================== --
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
local error<const>, tostring<const>, unpack<const> =
  error, tostring, table.unpack;
-- M-Engine aliases (optimisation) ----------------------------------------- --
local CoreTicks<const>, UtilBlank<const>, UtilIsTable<const>,
  UtilIsBoolean<const>, UtilIsInteger<const> =
    Core.Ticks, Util.Blank, Util.IsTable, Util.IsBoolean, Util.IsInteger;
-- Diggers function and data aliases --------------------------------------- --
local Fade, GameProc, InitBank, InitCon, InitContinueGame,
  InitScene, InitShop, InitTitle, IsButtonReleased, IsMouseInBounds,
  IsMouseNotInBounds, LoadResources, PlayMusic, PlayStaticSound,
  RegisterFBUCallback, RenderInterface, RenderShadow, SetBottomRightTip,
  SetBottomRightTipAndShadow, SetCallbacks, SetCursor, SetKeys,
  aGlobalData, fontSpeech;
-- Locals ------------------------------------------------------------------ --
local aInputClickChecks,               -- Hotspot data for when mouse clicked
      aMouseOverChecks,                -- Hotspot data for when mouse over
      fcbRenderExtra,                  -- Any extra rendering to be done
      iCArrow, iCExit, iCOK, iCSelect, -- Cursor ids
      iKeyBankClosedExitId,            -- Closed key bank id (saved, can exit)
      iKeyBankClosedNoExitId,          -- Closed key bank id (no save, no exit)
      iKeyBankClosedReadyId,           -- Closed key bank id (can play zone)
      iKeyBankClosedSelectedId,        -- Closed key bank selected
      iKeyBankOpenedId,                -- Opened key bank id
      iSSelect,                        -- Sound effects used
      iStageL, iStageR,                -- Stage bounds
      sTip,                            -- Tip text
      texLobby;                        -- Lobby texture
-- Assets required --------------------------------------------------------- --
local aMusicAsset<const>          = { T = 7, F = "lobby",  P = { } };
local aClosedTexture<const>       = { T = 2, F = "lobbyc", P = { 0 } };
local aClosedAssetsNoMusic<const> = { aClosedTexture };
local aClosedAssetsMusic<const>   = { aClosedTexture, aMusicAsset };
local aOpenTexture<const>         = { T = 2, F = "lobbyo", P = { 0 } };
local aOpenAssetsNoMusic<const>   = { aOpenTexture };
local aOpenAssetsMusic<const>     = { aOpenTexture, aMusicAsset };
-- Register frame buffer update -------------------------------------------- --
local function OnFrameBufferUpdate(...)
  local _; _, _, iStageL, _, iStageR, _ = ...;
end
-- Set cursor and tip ------------------------------------------------------ --
local function SetTipAndCursor(sMsg, iCursor)
  -- Set new tip
  sTip = sMsg;
  -- Set new cursor
  SetCursor(iCursor);
end
-- Lobby open render proc -------------------------------------------------- --
local function RenderLobbyOpen()
  -- Render game interface, backdrop, shadow and tip
  RenderInterface();
  texLobby:BlitLT(8, 8);
  RenderShadow(8, 8, 312, 208);
  SetBottomRightTip(sTip);
  -- Render fire
  local iFrame<const> = CoreTicks() % 9;
  if iFrame >= 6 then texLobby:BlitSLT(1, 113, 74);
  elseif iFrame >= 3 then texLobby:BlitSLT(2, 113, 74);
  else fcbRenderExtra() end;
end
-- Lobby closed render proc ------------------------------------------------ --
local function RenderLobbyClosed()
  -- Draw backdrop
  texLobby:BlitLT(-54, 0);
  -- Render lobby
  texLobby:BlitSLT(1, 8, 8);
  -- Render lobby shadow
  RenderShadow(8, 8, 312, 208);
  -- Render fire
  local iFrame<const> = CoreTicks() % 9;
  if iFrame >= 6 then texLobby:BlitSLT(5, 113, 74);
  elseif iFrame >= 3 then texLobby:BlitSLT(4, 113, 74);
  -- Flash if not ready to play
  else fcbRenderExtra() end;
  -- Draw foliage
  texLobby:BlitSLT(2, iStageR-238, 183);
  texLobby:BlitSLT(3, iStageL,      56);
  -- Render tip
  SetBottomRightTipAndShadow(sTip);
end
-- Lobby main check hotspots tick ------------------------------------------ --
local function ProcLobbyClosed()
  -- Check for mouse over events
  for iI = 1, #aMouseOverChecks do
    -- Get item to check and if specified condition is met?
    local aMouseOverCheckItem<const> = aMouseOverChecks[iI];
    if aMouseOverCheckItem[1]() then
      -- Set the tip for that item
      SetTipAndCursor(aMouseOverCheckItem[2], aMouseOverCheckItem[3]);
      -- No need to check anymore
      break;
    end
  end
end

-- Lobby main open tick ---------------------------------------------------- --
local function ProcLobbyOpen()
  -- Continue game logic so the AI can still win if player wasting time
  GameProc();
  -- Check for mouse over events
  ProcLobbyClosed();
end
-- Lobby open click procedure activation ----------------------------------- --
local function LobbyOpenActivate(aInputClickCheckItem)
  -- Play sound and init the bank screen
  PlayStaticSound(iSSelect);
  -- Start the loading waiting procedure
  SetCallbacks(GameProc, RenderInterface, nil);
  -- Load requested screen
  aInputClickCheckItem[2](unpack(aInputClickCheckItem[3]));
  -- Dereference assets for the garbage collector
  texLobby, aInputClickChecks, aMouseOverChecks = nil, nil, nil;
end
-- Lobby open input tick --------------------------------------------------- --
local function InputLobbyOpen()
  -- Mouse button not clicked? Check what was clicked and proceed to
  -- respective procedure
  if IsButtonReleased(0) then return end;
  -- Check for clicks
  for iI = 1, #aInputClickChecks do
    -- Get item to check and if specified condition is met?
    local aInputClickCheckItem<const> = aInputClickChecks[iI];
    if aInputClickCheckItem[1]() then
      return LobbyOpenActivate(aInputClickCheckItem) end;
  end
end
-- Lobby closed click procedure activation --------------------------------- --
local function LobbyClosedActivate(aInputClickCheckItem)
  -- Play sound and init the bank screen
  PlayStaticSound(iSSelect);
  -- When faded out?
  local function OnFadeOutClosed()
    -- Call exit function with requested parameters
    aInputClickCheckItem[2](unpack(aInputClickCheckItem[3]));
    -- Dereference assets for the garbage collector
    texLobby, aInputClickChecks, aMouseOverChecks = nil, nil, nil;
  end
  -- Fade out to title screen
  return Fade(0, 1, 0.04,
    RenderLobbyClosed, OnFadeOutClosed, aInputClickCheckItem[4]);
end
-- Lobby closed input tick ------------------------------------------------- --
local function InputLobbyClosed()
  -- Mouse button not clicked? Check what was clicked and proceed to
  -- respective procedure
  if IsButtonReleased(0) then return end;
  -- Check for clicks
  for iI = 1, #aInputClickChecks do
    -- Get item to check and if specified condition is met?
    local aInputClickCheckItem<const> = aInputClickChecks[iI];
    if aInputClickCheckItem[1]() then
      return LobbyClosedActivate(aInputClickCheckItem) end;
  end
end
-- Always returns true ----------------------------------------------------- --
local function AlwaysTrue() return true end;
-- When closed lobby has faded in? Set lobby callbacks --------------------- --
local function OnLobbyFadedIn()
  -- Set requested closed key bank keys
  SetKeys(true, iKeyBankClosedSelectedId);
  -- Set callbacks
  SetCallbacks(ProcLobbyClosed, RenderLobbyClosed, InputLobbyClosed);
end
-- Lobby loaded in game ---------------------------------------------------- --
local function OnOpenedLobbyLoaded()
  -- Cache texture coordinates for background. We make sure we have one
  -- tile incase the texture was already cached and therefore the values
  -- will be overwritten
  texLobby:TileSTC(3);
  texLobby:TileS(0, 208, 312, 512, 512); -- Lobby open graphic
  texLobby:TileS(1, 305, 185, 398, 258); -- Fire animation graphic B
  texLobby:TileS(2, 400, 185, 493, 258); -- Fire animation graphic C
  -- Set opened key bank
  SetKeys(true, iKeyBankOpenedId);
  -- Change render procedures
  SetCallbacks(ProcLobbyOpen, RenderLobbyOpen, InputLobbyOpen);
end
-- Lobby loaded pre-game --------------------------------------------------- --
local function OnClosedLobbyLoaded()
  -- Set speech colour to white
  fontSpeech:SetCRGBAI(0xFFFFFFFF);
  -- Cache background (same rule as above)
  texLobby:TileSTC(6);
  texLobby:TileS(0,   0, 272, 512, 512); -- Background graphic
  texLobby:TileS(1,   0,   0, 304, 200); -- Lobby graphic
  texLobby:TileS(2,   0, 214, 238, 271); -- Foliage graphic left
  texLobby:TileS(3, 305,   0, 512, 184); -- Foliage graphic right
  texLobby:TileS(4, 305, 185, 398, 258); -- Fire animation graphic B
  texLobby:TileS(5, 400, 185, 493, 258); -- Fire animation graphic C
  -- Fade In a closed lobby
  Fade(1, 0, 0.04, RenderLobbyClosed, OnLobbyFadedIn);
end
-- When assets have loaded? ------------------------------------------------ --
local function OnLoaded(aResources, fcbOnLoaded, iSaveMusicPos)
  -- Register frame buffer update
  RegisterFBUCallback("lobby", OnFrameBufferUpdate);
  -- Play lobby music if requested
  if #aResources == 2 then PlayMusic(aResources[2], nil, iSaveMusicPos) end;
  -- sTip and lobby texture
  sTip, texLobby = "", aResources[1];
  -- From in game?
  fcbOnLoaded();
end
-- Not ready callback ------------------------------------------------------ --
local function NotReadyCallback() fontSpeech:Print(157, 115, "!") end;
-- Mouse is over the controller? ------------------------------------------- --
local function MouseOverController()
  return IsMouseInBounds(151, 124, 164, 137) end;
-- If mouse over the bank door? -------------------------------------------- --
local function MouseOverBank()
  return IsMouseInBounds(74, 87, 103, 104) end;
-- If mouse over the shop door --------------------------------------------- --
local function MouseOverShop()
  return IsMouseInBounds(217, 87, 245, 104) end;
-- Mouse is over the exit hotspot? ----------------------------------------- --
local function MouseOverExit() return IsMouseNotInBounds(8, 8, 312, 208) end;
-- Add an input click check ------------------------------------------------ --
local function AddInputClickCheck(aData)
  aInputClickChecks[1 + #aInputClickChecks] = aData end;
-- Add a hotpoint ---------------------------------------------------------- --
local function AddMouseOverCheck(aData)
  aMouseOverChecks[1 + #aMouseOverChecks] = aData end;
-- Init lobby function ----------------------------------------------------- --
local function InitLobby(aActiveObject, bNoSetMusic, iSaveMusicPos)
  -- Active object must be specified or omitted
  if aActiveObject ~= nil and not UtilIsTable(aActiveObject) then
    error("Invalid object owner table! "..tostring(aActiveObject)) end;
  -- No set music flag can be nil set to false as a result
  if bNoSetMusic == nil then bNoSetMusic = false;
  -- Else if it's specified and it's not a boolean then show error
  elseif not UtilIsBoolean(bNoSetMusic) then
    error("Invalid set music flag! "..tostring(bNoSetMusic));
  -- Must specify position if bNoSetMusic is false
  elseif aActiveObject and not bNoSetMusic and
    not UtilIsInteger(iSaveMusicPos) then
      error("Invalid save pos id! "..tostring(iSaveMusicPos)); end;
  -- Clear check tables
  aInputClickChecks, aMouseOverChecks = { }, { };
  -- Resources to load
  local aAssets, fcbOnLoaded;
  -- In a game?
  if aActiveObject then
    -- In-game onloaded event
    fcbOnLoaded = OnOpenedLobbyLoaded;
    -- Set resources depending on music requested
    if bNoSetMusic then aAssets = aOpenAssetsNoMusic;
                   else aAssets = aOpenAssetsMusic end;
    -- Input click checks lookup table
    AddInputClickCheck({ MouseOverBank, InitBank, { aActiveObject } });
    AddInputClickCheck({ MouseOverShop, InitShop, { aActiveObject } });
    AddInputClickCheck({ MouseOverExit, InitContinueGame,
      { true, aActiveObject } });
    -- Mouseover checks lookup table
    AddMouseOverCheck({ MouseOverBank, "BANK", iCSelect });
    AddMouseOverCheck({ MouseOverShop, "SHOP", iCSelect });
    AddMouseOverCheck({ MouseOverExit, "CONTINUE", iCExit });
    -- No extra rendering
    fcbRenderExtra = UtilBlank;
  -- Not in a game?
  else
    -- In-game onloaded event
    fcbOnLoaded = OnClosedLobbyLoaded;
    -- Set resources depending on music requested
    if bNoSetMusic then aAssets = aClosedAssetsNoMusic;
                   else aAssets = aClosedAssetsMusic end;
    -- Start configuring hotspots. Controller is available in all of them
    AddInputClickCheck({ MouseOverController, InitCon, { }, false });
    aMouseOverChecks =
      { { MouseOverController, "CONTROLLER", iCSelect } };
    -- If game is ready to play?
    if aGlobalData.gSelectedLevel ~= nil and
       aGlobalData.gSelectedRace ~= nil then
      -- Player is allowed to begin the zone
      AddInputClickCheck({ MouseOverExit, InitScene,
        { aGlobalData.gSelectedLevel }, true });
      AddMouseOverCheck({ MouseOverExit, "BEGIN ZONE", iCOK });
      iKeyBankClosedSelectedId = iKeyBankClosedReadyId;
      -- No extra rendering
      fcbRenderExtra = UtilBlank;
    -- If game has been saved?
    elseif aGlobalData.gGameSaved then
      -- Player is allowed to exit to the title screen
      AddInputClickCheck({ MouseOverExit, InitTitle, { }, true });
      AddMouseOverCheck({ MouseOverExit, "ABORT GAME", iCExit });
      iKeyBankClosedSelectedId = iKeyBankClosedExitId;
      -- Set exclamation mark callback
      fcbRenderExtra = NotReadyCallback;
    -- Player did not save the game?
    else
      -- Can't exit key binds
      iKeyBankClosedSelectedId = iKeyBankClosedNoExitId;
      -- Set exclamation mark callback
      fcbRenderExtra = NotReadyCallback;
    end
  end
  -- Always the last item to show where the player is and the arrow cursor
  AddMouseOverCheck({ AlwaysTrue, "LOBBY", iCArrow });
  -- Load closed lobby texture
  LoadResources("Lobby", aAssets, OnLoaded, fcbOnLoaded, iSaveMusicPos);
end
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  Fade, GameProc, InitBank, InitCon, InitContinueGame, InitScene, InitShop,
    InitTitle, IsButtonReleased, IsMouseInBounds, IsMouseNotInBounds,
    LoadResources, PlayMusic, PlayStaticSound, RegisterFBUCallback,
    RenderInterface, RenderShadow, SetBottomRightTip,
    SetBottomRightTipAndShadow, SetCallbacks, SetCursor, SetKeys, aGlobalData,
    fontSpeech =
      GetAPI("Fade", "GameProc", "InitBank", "InitCon", "InitContinueGame",
        "InitScene", "InitShop", "InitTitle", "IsButtonReleased",
        "IsMouseInBounds", "IsMouseNotInBounds", "LoadResources", "PlayMusic",
        "PlayStaticSound", "RegisterFBUCallback", "RenderInterface",
        "RenderShadow", "SetBottomRightTip", "SetBottomRightTipAndShadow",
        "SetCallbacks", "SetCursor", "SetKeys", "aGlobalData", "fontSpeech");
  -- Prepare key bind registration
  local aKeys<const>, aStates<const> = Input.KeyCodes, Input.States;
  local iPress<const> = aStates.PRESS;
  local RegisterKeys<const> = GetAPI("RegisterKeys");
  local sName<const> = "ZMTC LOBBY";
  -- Force an open lobby input click
  local function ForceOpenInputClick(iIndex)
    LobbyOpenActivate(aInputClickChecks[iIndex]) end
  -- Open lobby key events
  local function OnOpenBankPressed() ForceOpenInputClick(1) end;
  local function OnOpenShopPressed() ForceOpenInputClick(2) end;
  local function OnOpenExitPressed() ForceOpenInputClick(3) end;
  -- Register open lobby keybanks
  iKeyBankOpenedId = RegisterKeys(sName, {
    [iPress] = {
      { aKeys.B, OnOpenBankPressed, "zmtclb", "BANK" },
      { aKeys.S, OnOpenShopPressed, "zmtcls", "SHOP" },
      { aKeys.ESCAPE, OnOpenExitPressed, "zmtclbtg", "BACK TO GAME" };
    }
  });
  -- Force a closed lobby input click
  local function ForceClosedInputClick(iIndex)
    LobbyClosedActivate(aInputClickChecks[iIndex]) end;
  -- Closed lobby key events
  local function OnClosedControllerPressed() ForceClosedInputClick(1) end;
  local function OnClosedEscapePressed() ForceClosedInputClick(2) end;
  -- Controller bind
  local aController<const> =
    { aKeys.ENTER, OnClosedControllerPressed, "zmtclc", "CONTROLLER" };
  -- Controller and escape whole bind
  local aEscapeController<const> = {
    [iPress] = {
      aController,
      { aKeys.ESCAPE, OnClosedEscapePressed, "zmtclltc",
          "LEAVE TRADE CENTRE" };
    }
  };
  -- Register closed lobby keybanks
  iKeyBankClosedExitId = RegisterKeys(sName, aEscapeController);
  iKeyBankClosedNoExitId = RegisterKeys(sName, { [iPress] = { aController } });
  iKeyBankClosedReadyId = RegisterKeys(sName, aEscapeController);
  -- Set sound effect ids
  iSSelect = GetAPI("aSfxData").SELECT;
  -- Set cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCOK, iCSelect, iCExit, iCArrow = aCursorIdData.OK, aCursorIdData.SELECT,
    aCursorIdData.EXIT, aCursorIdData.ARROW;
end
-- Exports and imports------------------------------------------------------ --
return { A = { InitLobby = InitLobby }, F = OnReady };
-- End-of-File ============================================================= --

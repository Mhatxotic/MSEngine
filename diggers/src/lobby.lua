-- LOBBY.LUA =============================================================== --
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
local error<const>, tostring<const>, unpack<const> =
  error, tostring, table.unpack;
-- M-Engine aliases (optimisation) ----------------------------------------- --
local CoreTicks<const>, UtilIsTable<const>, UtilIsBoolean<const>,
  UtilIsInteger<const> =
    Core.Ticks, Util.IsTable, Util.IsBoolean, Util.IsInteger;
-- Diggers function and data aliases --------------------------------------- --
local EndConditionsCheck, Fade, GameProc, InitBank, InitCon, InitContinueGame,
  InitScene, InitShop, InitTitle, IsButtonReleased, IsMouseInBounds,
  IsMouseNotInBounds, LoadResources, PlayMusic, PlayStaticSound,
  RegisterFBUCallback, RenderInterface, RenderShadow, SetBottomRightTip,
  SetBottomRightTipAndShadow, SetCallbacks, SetCursor, aCursorIdData,
  aGlobalData, aSfxData, fontSpeech;
-- Assets required --------------------------------------------------------- --
local aMusicAsset<const>          = { T = 7, F = "lobby",  P = { } };
local aClosedTexture<const>       = { T = 2, F = "lobbyc", P = { 0 } };
local aClosedAssetsNoMusic<const> = { aClosedTexture };
local aClosedAssetsMusic<const>   = { aClosedTexture, aMusicAsset };
local aOpenTexture<const>         = { T = 2, F = "lobbyo", P = { 0 } };
local aOpenAssetsNoMusic<const>   = { aOpenTexture };
local aOpenAssetsMusic<const>     = { aOpenTexture, aMusicAsset };
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
  -- Resources to load
  local aAssets;
  -- In a game?
  if aActiveObject then
    -- Set resources depending on music requested
    if bNoSetMusic then aAssets = aOpenAssetsNoMusic;
                   else aAssets = aOpenAssetsMusic end;
  -- Not in a game? Set resources depending on music requested
  elseif bNoSetMusic then aAssets = aClosedAssetsNoMusic;
                     else aAssets = aClosedAssetsMusic end;
  -- When assets have loaded?
  local function OnLoaded(aResources)
    -- Register frame buffer update
    local iStageL, iStageR;
    local function OnFrameBufferUpdate(...)
      local _; _, _, iStageL, _, iStageR, _ = ...;
    end
    RegisterFBUCallback("lobby", OnFrameBufferUpdate);
    -- Play lobby music if requested
    if not bNoSetMusic then PlayMusic(aResources[2].H, nil, iSaveMusicPos) end;
    -- Tip and lobby texture
    local Tip, texLobby = "", aResources[1].H;
    -- Set cursor and tip
    local function SetTipAndCursor(sMsg, iCursor)
      -- Set new tip
      Tip = sMsg;
      -- Set new cursor
      SetCursor(iCursor);
    end
    -- Mouseover checks
    local function MouseOverExit()
      return IsMouseNotInBounds(8, 8, 312, 208) end;
    -- From in game?
    if aActiveObject then
      -- Lobby open render proc
      local function RenderLobbyOpen()
        -- Render game interface
        RenderInterface();
        -- Render backdrop
        texLobby:BlitLT(8, 8);
        -- Render backdrop shadow
        RenderShadow(8, 8, 312, 208);
        -- Render fire
        local iFrame<const> = CoreTicks() % 9;
        if iFrame >= 6 then texLobby:BlitSLT(1, 113, 74);
        elseif iFrame >= 3 then texLobby:BlitSLT(2, 113, 74) end;
        -- Render tip
        SetBottomRightTip(Tip);
      end
      -- Some mouse tests
      local function MouseOverBank()
        return IsMouseInBounds(74, 87, 103, 104) end;
      local function MouseOverShop()
        return IsMouseInBounds(217, 87, 245, 104) end;
      -- Input click checks lookup table
      local aInputClickChecks<const> = {
        { MouseOverBank, InitBank, { aActiveObject } },
        { MouseOverShop, InitShop, { aActiveObject } },
        { MouseOverExit, InitContinueGame, { true, aActiveObject } },
      };
      -- Lobby open input tick
      local function InputLobbyOpen()
        -- Mouse button not clicked? Check what was clicked and proceed to
        -- respective procedure
        if IsButtonReleased(0) then return end;
        -- Check for clicks
        for iI = 1, #aInputClickChecks do
          -- Get item to check and if specified condition is met?
          local aInputClickCheckItem<const> = aInputClickChecks[iI];
          if aInputClickCheckItem[1]() then
            -- Play sound and init the bank screen
            PlayStaticSound(aSfxData.SELECT);
            -- Dereference assets for the garbage collector
            texLobby = nil;
            -- Start the loading waiting procedure
            SetCallbacks(GameProc, RenderInterface, nil);
            -- Load requested screen
            aInputClickCheckItem[2](unpack(aInputClickCheckItem[3]));
            -- Done
            return;
          end
        end
      end
      -- Always returns true
      local function AlwaysTrue() return true end;
      -- Mouseover checks lookup table
      local aMouseOverChecks<const> = {
        { MouseOverBank, "BANK",     aCursorIdData.SELECT },
        { MouseOverShop, "SHOP",     aCursorIdData.SELECT },
        { MouseOverExit, "CONTINUE", aCursorIdData.EXIT   },
        { AlwaysTrue,    "LOBBY",    aCursorIdData.ARROW  },
      };
      -- Lobby main open tick
      local function ProcLobbyOpen()
        -- Continue game logic so the AI can still win if player wasting time
        GameProc();
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
      -- Cache texture coordinates for background. We make sure we have one
      -- tile incase the texture was already cached and therefore the values
      -- will be overwritten
      texLobby:TileSTC(3);
      texLobby:TileS(0, 208, 312, 512, 512); -- Lobby open graphic
      texLobby:TileS(1, 305, 185, 398, 258); -- Fire animation graphic B
      texLobby:TileS(2, 400, 185, 493, 258); -- Fire animation graphic C
      -- Change render procedures
      SetCallbacks(ProcLobbyOpen, RenderLobbyOpen, InputLobbyOpen);
    -- Lobby is closed?
    else
      -- Ready to play boolean
      local bReadyToPlay<const> = aGlobalData.gSelectedLevel ~= nil and
                                  aGlobalData.gSelectedRace ~= nil;
      local bGameSaved<const> = aGlobalData.gGameSaved;
      -- Set speech colour to white
      fontSpeech:SetCRGBAI(0xFFFFFFFF);
      -- Lobby closed render proc
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
        elseif not bReadyToPlay then fontSpeech:Print(157, 115, "!") end;
        -- Draw foliage
        texLobby:BlitSLT(2, iStageR-238, 183);
        texLobby:BlitSLT(3, iStageL,      56);
        -- Render tip
        SetBottomRightTipAndShadow(Tip);
      end
      -- Some mouse tests
      local function MouseOverController()
        return IsMouseInBounds(151, 124, 164, 137) end;
      -- Lobby closed input tick
      local function InputLobbyClosed()
        -- Mouse button not clicked? Return!
        if IsButtonReleased(0) then return end;
        -- Mouse is over controller?
        if MouseOverController() then
          -- Play select sound
          PlayStaticSound(aSfxData.SELECT);
          -- Fade out then init fat controller passing the lobby texture around
          -- so we can keep drawing the background without having to reload it
          Fade(0, 1, 0.04, RenderLobbyClosed, InitCon);
        -- Mouse is over exit?
        elseif MouseOverExit() then
          -- Level and race selected?
          if aGlobalData.gSelectedLevel and aGlobalData.gSelectedRace then
            -- Play sound
            PlayStaticSound(aSfxData.SELECT);
            -- Can no longer exit to title until saved again
            aGlobalData.gGameSaved = nil;
            -- When lobby has faded out to start a level?
            local function OnFadeOutEnterZone()
              -- Unregister callback
              RegisterFBUCallback("lobby");
              -- Dereference assets for garbage collector
              texLobby = nil;
              -- Begin game
              InitScene(aGlobalData.gSelectedLevel);
            end
            -- Fade out to enter a new zone
            Fade(0, 1, 0.04, RenderLobbyClosed, OnFadeOutEnterZone, true);
          -- No levels completed? We can return to title screen
          elseif aGlobalData.gGameSaved then
            -- Play sound
            PlayStaticSound(aSfxData.SELECT);
            -- When lobby has faded out to title screen?
            local function OnFadeOutTitle()
              -- Unregister callback
              RegisterFBUCallback("lobby");
              -- Dereference assets for garbage collector
              texLobby = nil;
              -- Load title screen
              InitTitle();
            end
            -- Fade out to title screen
            Fade(0, 1, 0.04, RenderLobbyClosed, OnFadeOutTitle, true);
          end
        end
      end
      -- Lobby main closed tick
      local function ProcLobbyClosed()
        -- Mouse is over exit?
        if MouseOverExit() then
          -- Level and race selected?
          if bReadyToPlay then
            SetTipAndCursor("BEGIN", aCursorIdData.OK);
          -- Game saved?
          elseif bGameSaved then
            SetTipAndCursor("CANCEL", aCursorIdData.EXIT);
          end
        -- Mouse over controller?
        elseif MouseOverController() and not aActiveObject then
          SetTipAndCursor("CONTROLLER", aCursorIdData.SELECT);
        -- Nothing selected?
        else SetTipAndCursor("LOBBY", aCursorIdData.ARROW) end;
      end
      -- Cache background (same rule as above)
      texLobby:TileSTC(6);
      texLobby:TileS(0,   0, 272, 512, 512); -- Background graphic
      texLobby:TileS(1,   0,   0, 304, 200); -- Lobby graphic
      texLobby:TileS(2,   0, 214, 238, 271); -- Foliage graphic left
      texLobby:TileS(3, 305,   0, 512, 184); -- Foliage graphic right
      texLobby:TileS(4, 305, 185, 398, 258); -- Fire animation graphic B
      texLobby:TileS(5, 400, 185, 493, 258); -- Fire animation graphic C
      -- When closed lobby has faded in? Set lobby callbacks
      local function OnFadeIn()
        SetCallbacks(ProcLobbyClosed, RenderLobbyClosed, InputLobbyClosed);
      end
      -- Fade In a closed lobby
      Fade(1, 0, 0.04, RenderLobbyClosed, OnFadeIn);
    end
  end
  -- Load closed lobby texture
  LoadResources("Lobby", aAssets, OnLoaded);
end
-- Exports and imports------------------------------------------------------ --
return { A = { InitLobby = InitLobby }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  EndConditionsCheck, Fade, GameProc, InitBank, InitCon, InitContinueGame,
  InitScene, InitShop, InitTitle, IsButtonReleased, IsMouseInBounds,
  IsMouseNotInBounds, LoadResources, PlayMusic, PlayStaticSound,
  RegisterFBUCallback, RenderInterface, RenderShadow, SetBottomRightTip,
  SetBottomRightTipAndShadow, SetCallbacks, SetCursor, aCursorIdData,
  aGlobalData, aSfxData, fontSpeech
  = -- --------------------------------------------------------------------- --
  GetAPI("EndConditionsCheck", "Fade", "GameProc", "InitBank", "InitCon",
    "InitContinueGame", "InitScene", "InitShop", "InitTitle",
    "IsButtonReleased", "IsMouseInBounds", "IsMouseNotInBounds",
    "LoadResources", "PlayMusic", "PlayStaticSound", "RegisterFBUCallback",
    "RenderInterface", "RenderShadow", "SetBottomRightTip",
    "SetBottomRightTipAndShadow", "SetCallbacks", "SetCursor", "aCursorIdData",
    "aGlobalData", "aSfxData", "fontSpeech");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

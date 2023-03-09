-- POST.LUA ================================================================ --
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
local error<const>, tostring<const> = error, tostring;
-- M-Engine function aliases ----------------------------------------------- --
local UtilTableSize<const>, UtilIsInteger<const> =
  Util.TableSize, Util.IsInteger;
-- Diggers function and data aliases --------------------------------------- --
local AdjustViewPortX, AdjustViewPortY, Fade, GetAbsMousePos, InitEnding,
  InitFail, InitLobby, IsButtonHeld, IsButtonPressed, IsButtonReleased,
  IsKeyHeld, IsMouseInBounds, IsMouseNotInBounds, IsMouseXGreaterEqualThan,
  IsMouseXLessThan, IsMouseYGreaterEqualThan, IsMouseYLessThan,
  IsScrollingDown, IsScrollingUp, IsSpriteCollide, LoadResources, PlayMusic,
  PlayStaticSound, RenderFade, RenderObjects, RenderTerrain, SetCallbacks,
  SetCursor, aCursorIdData, aGlobalData, aLevelsData, aObjectFlags, aObjects,
  aSfxData, fontSpeech;
-- Resources --------------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "end", P = { 0 } },
                         { T = 7, F = "win", P = { } } };
-- Need some key codes ----------------------------------------------------- --
local aKeys<const> = Input.KeyCodes;
local iKeyUp<const>, iKeyDown<const>, iKeyLeft<const>, iKeyRight<const> =
  aKeys.UP, aKeys.DOWN, aKeys.LEFT, aKeys.RIGHT;
-- Initialise the lose screen ---------------------------------------------- --
local function InitPost(iLId)
  -- Check parameters
  if not UtilIsInteger(iLId) then
    error("Invalid level id integer specified! "..tostring(iLId)) end;
  -- When post mortem assets are loaded?
  local function OnLoaded(aResources)
    -- Get post mortem texture
    local texEnd = aResources[1].H;
    texEnd:TileSTC(1);
    texEnd:TileSD(0, 208, 232, 304, 24);
    -- Loop End music
    PlayMusic(aResources[2].H, nil, nil, nil, 371767);
    -- Object hovered over by mouse
    local sObjectDefault<const> = "MAP POST MORTEM";
    local sObject = sObjectDefault
    -- Post mortem logic
    local function LogicPostMortem()
      -- Get absolute mouse position on level
      local AMX<const>, AMY<const> = GetAbsMousePos();
      -- Walk through objects
      for iIndex = 1, #aObjects do
        -- Get object data and if cursor overlapping it ?
        local aObject<const> = aObjects[iIndex];
        if IsSpriteCollide(479, AMX, AMY, aObject.S,
          aObject.X, aObject.Y) then
          -- Set tip with name and health of object
          sObject = (aObject.OD.LONGNAME or aObject.OD.NAME)..
            " ("..aObject.H.."%)";
          -- Done
          return;
        end
      end
      -- Set generic message
      sObject = sObjectDefault;
    end
    -- Post mortem render
    local function RenderPostMortem()
      -- Render terrain and objects
      RenderTerrain();
      RenderObjects();
      -- Render post mortem banner and text
      texEnd:BlitLT(8, 208);
      fontSpeech:SetCRGB(0, 0, 0.25);
      fontSpeech:PrintC(160, 215, sObject);
    end
    -- Process horizontal move?
    local function ProcHorizontalPress(iXA)
      -- Move view in specified direction
      AdjustViewPortX(iXA);
      -- Check for other keys too
      if IsKeyHeld(iKeyUp) then AdjustViewPortY(-16);
      elseif IsKeyHeld(iKeyDown) then AdjustViewPortY(16) end;
    end
    -- Process vertical move?
    local function ProcVerticalPress(iYA)
      -- Move view in specified direction
      AdjustViewPortY(iYA);
      -- Check for other keys too
      if IsKeyHeld(iKeyLeft)  then AdjustViewPortX(-16);
      elseif IsKeyHeld(iKeyRight) then AdjustViewPortX(16) end;
    end
    -- Post mortem input
    local function InputPostMortem()
      -- Is up key pressed?
      if IsKeyHeld(iKeyUp) then ProcVerticalPress(-16);
      -- Is down key pressed?
      elseif IsKeyHeld(iKeyDown) then ProcVerticalPress(16);
      -- Is left key pressed?
      elseif IsKeyHeld(iKeyLeft) then ProcHorizontalPress(-16);
      -- Is right key pressed?
      elseif IsKeyHeld(iKeyRight) then ProcHorizontalPress(16);
      -- Mouse at top edge of screen?
      elseif IsMouseXLessThan(16) then
        SetCursor(aCursorIdData.LEFT);
        if IsButtonHeld(0) then AdjustViewPortX(-16) end;
      -- Mouse at right edge of screen?
      elseif IsMouseXGreaterEqualThan(304) then
        SetCursor(aCursorIdData.RIGHT);
        if IsButtonHeld(0) then AdjustViewPortX(16) end;
      -- Mouse at left edge of screen?
      elseif IsMouseYLessThan(16) then
        SetCursor(aCursorIdData.TOP);
        if IsButtonHeld(0) then AdjustViewPortY(-16) end;
      -- Mouse over exit point?
      elseif IsMouseYGreaterEqualThan(224) then
        -- Set exit cursor
        SetCursor(aCursorIdData.EXIT);
        -- Left mouse button pressed?
        if IsButtonPressed(0) then
          -- Play button select sound
          PlayStaticSound(aSfxData.SELECT);
          -- When faded out?
          local function OnFadeOut()
            -- Dereference assets for garbage collection
            texEnd = nil;
            -- Select new level and no longer new game
            aGlobalData.gSelectedLevel, aGlobalData.gNewGame =
              nil, nil;
            -- Current level completed
            aGlobalData.gLevelsCompleted[iLId] = true;
            -- Bank balance reached? Show good ending if bank balance
            -- reached
            if aGlobalData.gBankBalance >=
               aGlobalData.gZogsToWinGame then
              return InitEnding(aGlobalData.gSelectedRace) end;
            -- Count number of levels completed and if all levels
            -- completed? Show bad ending :( else back to the lobby.
            local iNumCompleted<const> =
              UtilTableSize(aGlobalData.gLevelsCompleted);
            if iNumCompleted >= #aLevelsData then InitFail();
            else
              aGlobalData.gGameSaved = false;
              InitLobby();
            end
          end
          -- Fade out...
          Fade(0, 1, 0.04, RenderPostMortem, OnFadeOut, true);
        end
      -- Mouse over edge of bottom?
      elseif IsMouseYGreaterEqualThan(192) then
        SetCursor(aCursorIdData.BOTTOM);
        if IsButtonHeld(0) then AdjustViewPortY(16) end;
      -- Mouse not anywhere interesting?
      else SetCursor(aCursorIdData.ARROW) end;
    end
    -- Fade in counter
    nFade = 0.5;
    -- Proc fade in
    local function LogicAnimatedPostMortem()
      -- Fade in elements
      if nFade > 0 then nFade = nFade - 0.01;
      -- Fade complete?
      elseif nFade <= 0 then
        -- Clamp fade to fully transparent
        nFade = 0;
        -- Set OK (continue) cursor
        SetCursor(aCursorIdData.OK);
        -- Set post mortem procedure
        SetCallbacks(LogicPostMortem, RenderPostMortem, InputPostMortem);
      end
    end
    -- Render fade in
    local function RenderAnimatedPostMortem()
      -- Render terrain and objects
      RenderTerrain();
      RenderObjects();
      -- Render fade in
      RenderFade(nFade);
      -- Render post mortem banner and text
      local nAdj<const> = nFade * 128;
      texEnd:BlitLT(8, 208 + nAdj);
      fontSpeech:SetCRGB(0, 0, 0.25);
      fontSpeech:PrintC(160, 215 + nAdj, sObject);
    end
    -- Set WAIT cursor for animation
    SetCursor(aCursorIdData.WAIT);
    -- Set post mortem procedure
    SetCallbacks(LogicAnimatedPostMortem, RenderAnimatedPostMortem);
  end
  -- Load music and when finished execute the win assets handler
  LoadResources("Post Mortem", aAssets, OnLoaded);
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitPost = InitPost }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  AdjustViewPortX, AdjustViewPortY, Fade, GetAbsMousePos, InitEnding, InitFail,
  InitLobby, IsButtonHeld, IsButtonPressed, IsButtonReleased, IsKeyHeld,
  IsMouseInBounds, IsMouseNotInBounds, IsMouseXGreaterEqualThan,
  IsMouseXLessThan, IsMouseYGreaterEqualThan, IsMouseYLessThan,
  IsScrollingDown, IsScrollingUp, IsSpriteCollide, LoadResources, PlayMusic,
  PlayStaticSound, RenderFade, RenderObjects, RenderTerrain, SetCallbacks,
  SetCursor, aCursorIdData, aGlobalData, aLevelsData, aObjectFlags, aObjects,
  aSfxData, fontSpeech
  = -- --------------------------------------------------------------------- --
  GetAPI(
    "AdjustViewPortX", "AdjustViewPortY", "Fade",  "GetAbsMousePos",
    "InitEnding", "InitFail", "InitLobby", "IsButtonHeld", "IsButtonPressed",
    "IsButtonReleased", "IsKeyHeld", "IsMouseInBounds", "IsMouseNotInBounds",
    "IsMouseXGreaterEqualThan", "IsMouseXLessThan", "IsMouseYGreaterEqualThan",
    "IsMouseYLessThan", "IsScrollingDown", "IsScrollingUp", "IsSpriteCollide",
    "LoadResources", "PlayMusic", "PlayStaticSound", "RenderFade",
    "RenderObjects", "RenderTerrain", "SetCallbacks", "SetCursor",
    "aCursorIdData", "aGlobalData", "aLevelsData", "aObjectFlags", "aObjects",
    "aSfxData", "fontSpeech");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

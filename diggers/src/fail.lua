-- FAIL.LUA ================================================================ --
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
local Fade, InitScore, IsButtonReleased, IsButtonReleased, LoadResources,
  PlayMusic, PlayStaticSound, SetCallbacks, SetCursor, aCursorIdData, aSfxData,
  fontLarge;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 7, F = "lose", P = { } } };
-- Init ending screen functions -------------------------------------------- --
local function InitFail()
  -- When fail assets have loaded?
  local function OnLoaded(aResources)
    -- Stop music so we can break the good news
    PlayMusic(aResources[1].H);
    -- Game over render tick
    local function GameOverRenderProc()
      -- Show fail message
      fontLarge:SetCRGB(1, 0.25, 0.25);
      fontLarge:PrintC(160, 90, "NO ZONES LEFT TO MINE!");
      fontLarge:PrintC(160, 122, "Your mission has failed!");
    end
    -- When fail screen has faded in
    local function OnFadeIn()
      -- Set exit cursor
      SetCursor(aCursorIdData.EXIT);
      -- Input procedure
      local function FailInput()
        -- Mouse button not clicked? Return!
        if IsButtonReleased(0) then return end;
        -- Play sound
        PlayStaticSound(aSfxData.SELECT);
        -- Fade out and load title with fade
        Fade(0,1, 0.04, GameOverRenderProc, InitScore, true);
      end
      -- Change render procedures
      SetCallbacks(nil, GameOverRenderProc, FailInput);
    end
    -- Fade in
    Fade(1, 0, 0.04, GameOverRenderProc, OnFadeIn);
  end
  -- Load music and when finished
  LoadResources("No More Zones", aAssets, OnLoaded);
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitFail = InitFail }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  Fade, InitScore, IsButtonReleased, LoadResources, PlayMusic, PlayStaticSound,
  SetCallbacks, SetCursor, aCursorIdData, aSfxData, fontLarge
  = -- --------------------------------------------------------------------- --
  GetAPI("Fade", "InitScore", "IsButtonReleased",  "LoadResources",
    "PlayMusic", "PlayStaticSound", "SetCallbacks", "SetCursor",
    "aCursorIdData", "aSfxData", "fontLarge");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

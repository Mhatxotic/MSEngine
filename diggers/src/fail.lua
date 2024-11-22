-- FAIL.LUA ================================================================ --
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
local Fade, InitScore, IsButtonPressed, LoadResources, PlayMusic,
  PlayStaticSound, SetCallbacks, SetCursor, fontLarge;
-- Locals ------------------------------------------------------------------ --
local iCExit;                          -- Exit cursor id
local iKeyBankId;                      -- Key bank id
local iSSelect;                        -- Select sfx id
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 7, F = "lose" } };
-- Game over render tick --------------------------------------------------- --
local function RenderProc()
  -- Show fail message
  fontLarge:SetCRGB(1, 0.25, 0.25);
  fontLarge:PrintC(160, 90, "NO ZONES LEFT TO MINE!");
  fontLarge:PrintC(160, 122, "Your mission has failed!");
end
-- Finish procedure -------------------------------------------------------- --
local function Finish()
  -- Play sound
  PlayStaticSound(iSSelect);
  -- Fade out and load title with fade
  Fade(0,1, 0.04, RenderProc, InitScore, true);
end
-- Input procedure to fade out when mouse clicked -------------------------- --
local function InputProc() if IsButtonPressed(0) then Finish() end end;
-- When fail screen has faded in ------------------------------------------- --
local function OnFadeIn()
  -- Set exit cursor
  SetCursor(iCExit);
  -- Set fail keys
  SetKeys(true, iKeyBankId);
  -- Change render procedures
  SetCallbacks(nil, RenderProc, InputProc);
end
-- When fail assets have loaded? ------------------------------------------- --
local function OnLoaded(aResources)
  -- Stop music so we can break the good news
  PlayMusic(aResources[1]);
  -- Fade in
  Fade(1, 0, 0.04, RenderProc, OnFadeIn);
end
-- Init ending screen functions -------------------------------------------- --
local function InitFail() LoadResources("GAME OVER", aAssets, OnLoaded) end;
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  Fade, InitScore, IsButtonPressed, LoadResources, PlayMusic, PlayStaticSound,
    SetCallbacks, SetCursor, SetKeys, fontLarge =
      GetAPI("Fade", "InitScore", "IsButtonPressed",  "LoadResources",
        "PlayMusic", "PlayStaticSound", "SetCallbacks", "SetCursor", "SetKeys",
        "fontLarge");
  -- Register keybinds
  iKeyBankId = GetAPI("RegisterKeys")("IN-GAME NO MORE ZONES", {
    [Input.States.PRESS] =
      { { Input.KeyCodes.ESCAPE, Finish, "ignmzl", "LEAVE" } }
  });
  -- Get exit cursor id
  iCExit = GetAPI("aCursorIdData").EXIT;
  -- Get select sound effect id
  iSSelect = GetAPI("aSfxData").SELECT;
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitFail = InitFail }, F = OnReady };
-- End-of-File ============================================================= --

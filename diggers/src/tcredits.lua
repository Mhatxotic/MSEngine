-- TCREDITS.LUA ============================================================ --
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
local aCreditsData, Fade, fontLarge, fontLittle, InitTitle, InitTitle,
  IsButtonReleased, LoadResources, PlayMusic, SetCallbacks, SetKeys;
-- Assets required --------------------------------------------------------- --
local aTexture<const> = { T = 2, F = "title", P = { 0 } };
local aAssetsNoMusic<const> = { aTexture };
local aAssetsMusic<const> = { aTexture, { T = 7, F = "title" } };
-- Locals ------------------------------------------------------------------ --
local texTitle;                        -- Title screen texture
local iKeyBankId;                      -- Key bank for title credits keys
local iCreditsCounter, iCreditsNext;   -- Credits timer and next trigger
local strCredits1, iCredits1Y;         -- Large font title text and position
local strCredits2, iCredits2Y;         -- Small font subtitle text and position
local iCreditId;                       -- Current credit id (aCreditsData)
-- Set new credit ---------------------------------------------------------- --
local function SetCredit(iId)
  -- Set credit
  iCreditId = iId;
  -- Get credit data and return if failed
  local aData<const> = aCreditsData[iId];
  if not aData then return end;
  -- Set strings
  iCreditsNext = iCreditsNext + 120;
  strCredits1 = aData[1];
  strCredits2 = aData[2];
  -- Now we need to measure the height of all three strings so we
  -- can place the credits in the exact vertical centre of the screen
  local iCredits1H = fontLittle:PrintWS(320, 0, strCredits1);
  local iCredits2H = fontLarge:PrintWS(320, 0, strCredits2)/2;
  iCredits1Y = 120 - iCredits2H - 4 - iCredits1H;
  iCredits2Y = 120 - iCredits2H;
  -- Success
  return true;
end
-- Render credits proc ----------------------------------------------------- --
local function RenderCredits()
  -- Set text colour
  fontLittle:SetCRGB(1, 0.7, 1);
  fontLarge:SetCRGB(1, 1, 1);
  -- Draw background
  texTitle:BlitLT(-96, 0);
  -- Display text compared to amount of time passed
  fontLittle:PrintC(160, iCredits1Y, strCredits1);
  fontLarge:PrintC(160, iCredits2Y, strCredits2);
end
-- Fade out to title screen ------------------------------------------------ --
local function Finish()
  -- On fade out init title screen without setting music
  local function OnFadeOut()
    -- Initialise the title and give back the texture handle
    InitTitle(true);
    -- Done with the texture handle here
    texTitle = nil;
  end;
  -- Start fading out
  Fade(0, 1, 0.04, RenderCredits, OnFadeOut);
end
-- Credits main logic ------------------------------------------------------ --
local function CreditsLogic()
  -- Increment counter and if ignore if counter not exceeded
  iCreditsCounter = iCreditsCounter + 1;
  if iCreditsCounter < iCreditsNext then return end;
  -- Set next credit and return if succeeded
  if SetCredit(iCreditId + 1) then return end;
  -- Fade out to credits and load demo level
  Finish();
end
-- Credits input logic ----------------------------------------------------- --
local function CreditsInput()
  -- Ignore if no button or escape not pressed
  if IsButtonReleased(0) then return end;
  -- Fade out to credits and load demo level
  Finish();
end
-- When credits have faded in? --------------------------------------------- --
local function OnRenderCreditsFadeIn()
  -- Set keys for this screen
  SetKeys(true, iKeyBankId);
  -- Set credits callback
  SetCallbacks(CreditsLogic, RenderCredits, CreditsInput);
end
-- When we have the resources ---------------------------------------------- --
local function OnTitleCreditsReady()
  -- Initialise zarg texture and tile
  texTitle:SetCRGBA(1, 1, 1, 1);
  texTitle:TileSTC(1);
  texTitle:TileS(0, 0, 0, 512, 240);
  -- Credits counter and texts
  iCreditsCounter, iCreditsNext = 0, 0;
  -- Set new credit function
  SetCredit(1);
  -- Fade in
  Fade(1, 0, 0.04, RenderCredits, OnRenderCreditsFadeIn);
end
-- When title resources have loaded?
local function OnTitleCreditsLoaded(aResources, bNoMusic)
  -- Load texture and credit tiles
  texTitle = aResources[1];
  -- Play music
  if not bNoMusic then PlayMusic(aResources[2]) end;
  -- Resources are ready
  OnTitleCreditsReady();
end
-- Initialise the credits screen function ---------------------------------- --
local function InitTitleCredits(bNoMusic)
  -- Set assets to use based on music requested and load them
  local aAssets;
  if bNoMusic then aAssets = aAssetsNoMusic else aAssets = aAssetsMusic end;
  LoadResources("Title Credits", aAssets, OnTitleCreditsLoaded, bNoMusic);
end
-- Script ready function --------------------------------------------------- --
local function OnReady(GetAPI)
  -- Get imports
  aCreditsData, Fade, fontLarge, fontLittle, InitTitle, IsButtonReleased,
  LoadResources, PlayMusic, SetCallbacks, SetKeys =
    GetAPI("aCreditsData", "Fade", "fontLarge", "fontLittle", "InitTitle",
      "IsButtonReleased", "LoadResources", "PlayMusic", "SetCallbacks",
      "SetKeys");
  -- Register keybinds
  local aKeys<const>, aStates<const> = Input.KeyCodes, Input.States;
  iKeyBankId = GetAPI("RegisterKeys")("TITLE CREDITS", {
    [aStates.PRESS] = { { aKeys.ESCAPE, Finish, "tcc", "CANCEL" } }
  });
end
-- Return imports and exports ---------------------------------------------- --
return { A = { InitTitleCredits = InitTitleCredits }, F = OnReady };
-- End-of-File ============================================================= --

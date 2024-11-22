-- TNTMAP.LUA ============================================================== --
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
local TextureCreateTS<const>, ImageRaw<const>, AssetCreate<const>
      = -- ----------------------------------------------------------------- --
      Texture.CreateTS, Image.Raw, Asset.Create;
-- Diggers function and data aliases --------------------------------------- --
local Fade, GameProc, GetGameTicks, InitContinueGame, aLevelData, IsButtonHeld,
  IsButtonPressed, IsMouseInBounds, IsMouseNotInBounds, LoadResources,
  PlayStaticSound, RenderInterface, RenderShadow, SetBottomRightTip,
  SetCallbacks, SetCursor, SetKeys, aObjects, aTileData, aTileFlags, texSpr;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "tntmap", P = { 0 } } };
-- Locals ------------------------------------------------------------------ --
local iBSize<const> = 128 * 128 * 3;   -- Byte size of map
local iCExit, iCSelect, iCArrow,       -- Cursor ids
      iKeyBankId,                      -- Key bank id
      iSFlags, iWFlags,                -- Solid and water tile flags
      iSSelect,                        -- Select sound effect
      iTerrainPage,                    -- Default top page
      nNextUpdate,                     -- Next map update (updates on 1st tick)
      sTip,                            -- Current tip
      texTNTMap,                       -- TNT map texture
      texTerrain;                      -- Terrain texture (dynamic)
-- POI testing ------------------------------------------------------------- --
local function MouseOverExit()
  return IsMouseNotInBounds(8, 8, 312, 208) end;
local function MouseOverUpButton()
  return IsMouseInBounds(140, 179, 156, 195) end;
local function MouseOverDownButton()
  return IsMouseInBounds(162, 179, 178, 195) end;
local function MouseOverTerrain()
  return IsMouseInBounds(32, 44, 288, 172) end;
-- Set tip and cursor ------------------------------------------------------ --
local function SetTipAndCursor(sNewTip, iCursorId)
  sTip = sNewTip;
  SetCursor(iCursorId);
end
-- Set map page ------------------------------------------------------------ --
local function SetMapPage(iPage)
  -- Ignore if already on this p age
  if iTerrainPage == iPage then return end;
  -- Play sound
  PlayStaticSound(iSSelect);
  -- Set page
  iTerrainPage = iPage;
end
-- Leave the map ----------------------------------------------------------- --
local function Finish()
  -- Play sound
  PlayStaticSound(iSSelect);
  -- Dereference assets for garbage collector
  texTNTMap, texTerrain = nil, nil;
  -- Start the loading waiting procedure
  SetCallbacks(GameProc, RenderInterface, nil);
  -- Continue game
  InitContinueGame(false);
end
-- Scrolling --------------------------------------------------------------- --
local function GoScrollUp() SetMapPage(0) end;
local function GoScrollDown() SetMapPage(1) end;
-- Input callback ---------------------------------------------------------- --
local function InputProc()
  -- Check where mouse is and show appropriate tip
  if MouseOverExit() then
    -- Set tip and cursor to go exit
    SetTipAndCursor("CONTINUE", iCExit);
    -- Mouse button clicked? Return!
    if IsButtonHeld(0) then return Finish() end;
  -- Mouse over up button and on first page?
  elseif MouseOverUpButton() and iTerrainPage == 1 then
    -- Set tip and cursor to go up
    SetTipAndCursor("UP", iCSelect);
    -- Mouse button clicked? Set top half of map
    if IsButtonHeld(0) then GoScrollUp() end;
  -- Mouse over down button and on first page?
  elseif MouseOverDownButton() and iTerrainPage == 0 then
    -- Set tip and cursor to go down
    SetTipAndCursor("DOWN", iCSelect);
    -- Mouse button clicked? Set bottom half of map
    if IsButtonHeld(0) then GoScrollDown() end;
  -- Mouse over something else?
  else SetTipAndCursor("TNT MAP", iCArrow) end;
end
-- Render callback --------------------------------------------------------- --
local function RenderProc()
  -- Render everything
  RenderInterface();
  -- Draw appropriate background
  texTNTMap:BlitLT(8, 8);
  -- Render shadow
  RenderShadow(8, 8, 312, 208);
  -- Draw terrain
  texTerrain:BlitSLTRB(iTerrainPage, 32, 44, 288, 172);
  -- Dim appropriate button
  if iTerrainPage == 0 then texSpr:BlitSLTRB(801, 140, 179, 157, 196);
  elseif iTerrainPage == 1 then texSpr:BlitSLTRB(801, 162, 179, 179, 196) end;
  -- Draw tip
  SetBottomRightTip(sTip);
end
-- TNT map procedure ------------------------------------------------------- --
local function MapProc()
  -- Perform game actions
  GameProc();
  -- Done if map update interval not reached
  if GetGameTicks() < nNextUpdate then return end;
  -- Wait about another five seconds
  nNextUpdate = GetGameTicks() + 300;
  -- Create storage for bitmap data (128x128xRGB). The asset will be moved
  -- into the engine so we need to allocate it every time.
  local asBData<const> = AssetCreate("TNTMap", iBSize)
  -- For each pixel row
  for iY = 0, 127 do
    -- Calculate Y position in destination bitmap
    local iBYPos<const> = (iBSize - ((iY + 1) * 384)) + 3;
    -- Calculate Y position from level data
    local iLYPos<const> = iY * 128;
    -- For each pixel column
    for iX = 0, 127 do
      -- Get tile at level position
      local iTId<const> = aLevelData[1 + iLYPos + iX];
      -- Get tile flags
      local iTFlags<const> = aTileData[1 + iTId];
      -- Get bitmap position and then the locations of the components
      local iBPos<const> = iBYPos + (iX * 3);
      local iBPosGB<const> = iBPos - 2; -- Green/Blue (16-bit write)
      local iBPosR<const> = iBPos - 3; -- Red (8-bit write)
      -- Pixel values to write (Green/Blue + Red)
      local iIGB, iIR;
      -- Tile is clear?
      if iTId == 0 then iIGB, iIR = 0xFACE, 0x87;
      -- Tile is solid diggable block?
      elseif iTId == 3 then iIGB, iIR = 0x1A7F, 0x00;
      -- Tile is water?
      elseif iTFlags & iWFlags ~= 0 then iIGB, iIR = 0xFF00, 0x00;
      -- Tile is not destructible and not dug?
      elseif iTFlags & iSFlags == 0 then iIGB, iIR = 0x7F70, 0x7F;
      -- Other tiles
      else iIGB, iIR = 0x0000, 0x00 end;
      -- Apply pixel
      asBData:WU16LE(iBPosGB, iIGB);
      asBData:WU8(iBPosR, iIR);
    end
  end
  -- For each object, treat as POI
  for iObjectId = 1, #aObjects do
    -- Get object
    local aObj<const> = aObjects[iObjectId];
    -- Get position in pixel in bitmap for object
    local iPos<const> =
      (iBSize - ((aObj.AY + 1) * 384)) + (aObj.AX * 3) + 3;
    -- Make a white RGB dot
    asBData:WU16LE(iPos - 2, 0xFFFF);
    asBData:WU8(iPos - 3, 0xFF);
  end
  -- Push array as texture
  texTerrain = TextureCreateTS(ImageRaw("TNTMap", asBData,
    128, 128, 24, 0x1907), 128, 64, 0, 0, 0);
end
-- On assets loaded event -------------------------------------------------- --
local function OnLoaded(aResources)
  -- Initialise variables
  texTNTMap, sTip, iTerrainPage, nNextUpdate = aResources[1], nil, 0, 0;
  -- Set keybank keys
  SetKeys(true, iKeyBankId);
  -- Set callbacks
  SetCallbacks(MapProc, RenderProc, InputProc);
end
-- Init TNT map screen function -------------------------------------------- --
local function InitTNTMap() LoadResources("TNT Map", aAssets, OnLoaded) end;
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  Fade, GameProc, GetGameTicks, InitContinueGame, IsButtonHeld,
    IsMouseInBounds, IsMouseNotInBounds, LoadResources, PlayStaticSound,
    RenderInterface, RenderShadow, SetBottomRightTip, SetCallbacks, SetCursor,
    SetKeys, aLevelData, aObjects, aTileData, aTileFlags, texSpr =
      GetAPI("Fade", "GameProc", "GetGameTicks","InitContinueGame",
        "IsButtonHeld", "IsMouseInBounds", "IsMouseNotInBounds",
         "LoadResources", "PlayStaticSound", "RenderInterface", "RenderShadow",
        "SetBottomRightTip", "SetCallbacks", "SetCursor", "SetKeys",
        "aLevelData",  "aObjects", "aTileData", "aTileFlags", "texSpr");
  -- Register keybinds
  local aKeys<const> = Input.KeyCodes;
  iKeyBankId = GetAPI("RegisterKeys")("IN-GAME TNT MAP", {
    [Input.States.PRESS] = {
      { aKeys.ESCAPE, Finish, "igtnte", "LEAVE" },
      { aKeys.UP, GoScrollUp, "igtntsu", "SCROLL UP" },
      { aKeys.DOWN, GoScrollDown, "igtntsd", "SCROLL DOWN" },
    }
  });
  -- Store water tile flags
  iWFlags = aTileFlags.W;
  -- Get solid tile flags
  iSFlags = aTileFlags.D + aTileFlags.AD;
  -- Set sound effect ids
  iSSelect = GetAPI("aSfxData").SELECT;
  -- Set cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCExit, iCSelect, iCArrow =
    aCursorIdData.EXIT, aCursorIdData.SELECT, aCursorIdData.ARROW;
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitTNTMap = InitTNTMap }, F = OnReady };
-- End-of-File ============================================================= --

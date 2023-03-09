-- SHOP.LUA ================================================================ --
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
local random<const>, format<const>, error<const>, tostring<const> =
  math.random, string.format, error, tostring;
-- M-Engine function aliases ----------------------------------------------- --
local CoreTicks<const>, UtilIsInteger<const>, UtilIsTable<const> =
  Core.Ticks, Util.IsInteger, Util.IsTable;
-- Diggers function and data aliases --------------------------------------- --
local BuyItem, Fade, GameProc, InitCon, InitLobby, IsButtonPressed,
  IsButtonReleased, IsMouseInBounds, IsMouseNotInBounds, IsScrollingDown,
  IsScrollingUp, LoadResources, LoopStaticSound, PlayMusic, PlayStaticSound,
  RenderInterface, RenderShadow, SetBottomRightTip, SetCallbacks, SetCursor,
  SetKeys, StopSound, aObjectActions, aObjectData, aObjectDirections,
  aObjectJobs, aShopData, fontLittle, fontSpeech, fontTiny;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 1, F = "shop", P = { 65, 65, 1, 1, 0 } },
                         { T = 7, F = "shop" } };
-- Locals ------------------------------------------------------------------ --
local aBuyObject,                      -- Currently selected object data
      aDigger,                         -- Currently selected digger
      aDiggerInfo,                     -- Digger properties
      iAnimDoor,                       -- Current door animation id
      iAnimDoorMod, iAnimDoorMax,      -- Door visibility and maximum
      iBuyHoloId,                      -- Current holo emitter id
      iBuyId,                          -- Currently selected object id
      iBuyObjTypeId,                   -- Currently selected object type id
      iCArrow,                         -- Arrow cursor id
      iCWait, iCSelect, iCExit,        -- Cursor ids
      iForkAnim,                       -- Current forklift truck animation id
      iForkAnimMod, iForkAnimMax,      -- Forklift enabled id and maximum id
      iHoloAnimTileId,                 -- Current holo emitter animation id
      iHoloAnimTileIdMod,              -- Holo emitter is being shown
      iKeyBankClosedId,                -- Closed shop key bank id
      iKeyBankOpenId,                  -- Opened shop key bank id
      iSHolo,                          -- Switch product sound effect id
      iSError, iSFind, iSHoloHum,      -- Sound effect ids
      iSOpen, iSSelect, iSTrade,       -- More sound effect ids
      iSpeechTicks, bShopOpen,         -- Speech ticks left and shop open
      iTileBG,                         -- Background tile id
      iTileDoor,                       -- Door animation tile ids
      iTileEmitter,                    -- Holo emitter tile ids
      iTileFork,                       -- Forklift truck animation tile ids
      iTileKeeper,                     -- Shop keeper chatting tile ids
      iTileLights,                     -- Lights animation tile ids
      iTileSpeech,                     -- Speech tile id
      iTileStatus,                     -- Status tile id
      sMsg, sTip, iCarryable,          -- Speech text, tip and number carrayble
      texShop;                         -- shop texture
-- Test if current object can carry the specified object ------------------- --
local function UpdateCarryable()
  iCarryable = (aDiggerInfo.STRENGTH - aDigger.IW) // aBuyObject.WEIGHT;
end
-- Set actual new object --------------------------------------------------- --
local function SetObject(iId)
  -- Check id is valid
  if not UtilIsInteger(iId) then error("No id specified to set!") end;
  -- Get object type from shelf and make sure it's valid
  local iObjType<const> = aShopData[iId];
  if not UtilIsInteger(iObjType) then
    error("No shop data for item '"..iId.."'!") end;
  -- Set object information and make sure the object data is valid
  iBuyId, iBuyObjTypeId, aBuyObject, iBuyHoloId =
    iId, iObjType, aObjectData[iObjType], iId - 1;
  if not UtilIsTable(aBuyObject) then
    error("No object data for object type '"..iObjType.."'!") end;
  -- Animate the holographic emitter
  iHoloAnimTileId, iHoloAnimTileIdMod = 13, 1;
  -- Update Digger carrying weight
  UpdateCarryable();
end
-- Scroll through objects -------------------------------------------------- --
local function AdjustObject(Id)
  iBuyId = iBuyId + Id;
  if iBuyId < 1 then SetObject(#aShopData);
  elseif iBuyId > #aShopData then SetObject(1);
  else SetObject(iBuyId) end;
  PlayStaticSound(iSHolo);
end
-- Shop logic function ----------------------------------------------------- --
local function ShopLogic()
  -- Perform game functions in the background
  GameProc();
  -- Time elapsed to animate the holographic emitter?
  if CoreTicks() % 4 == 0 then
    -- Animate the holographic emitter
    iHoloAnimTileId = iHoloAnimTileId + iHoloAnimTileIdMod;
    if iHoloAnimTileId == 19 then iHoloAnimTileIdMod = -1;
    elseif iHoloAnimTileId == 15 then iHoloAnimTileIdMod = 1 end;
  end
  -- Time elapsed to animate the door and forklift?
  if CoreTicks() % 8 == 0 then
    -- Animate the door
    iAnimDoor = iAnimDoor + iAnimDoorMod;
    if iAnimDoor == iAnimDoorMax then iAnimDoorMod = -1;
    elseif iAnimDoor == iTileDoor then iAnimDoorMod = 0 end;
    -- Animate the forklift
    iForkAnim = iForkAnim + iForkAnimMod;
    if iForkAnim == iForkAnimMax then
      iForkAnim, iForkAnimMod = iTileFork, 0 end;
  end
end
-- Render function --------------------------------------------------------- --
local function ShopRender()
  -- Render original interface
  RenderInterface();
  -- Draw backdrop
  texShop:BlitSLT(iTileBG, 8, 8);
  -- Render shadow
  RenderShadow(8, 8, 312, 208);
  -- Draw animations
  if iAnimDoor ~= 0 then texShop:BlitSLT(iAnimDoor, 272, 79) end;
  if random() < 0.001 and iAnimDoorMod == 0 then iAnimDoorMod = 1 end;
  texShop:BlitSLT(CoreTicks() // 10 % 3 + iTileLights, 9, 174);
  if iForkAnim ~= 0 then texShop:BlitSLT(iForkAnim, 112, 95) end;
  if random() < 0.001 and iForkAnimMod == 0 then iForkAnimMod = 1 end;
  -- Shop is open
  if bShopOpen then
    texShop:BlitSLT(iTileStatus, 16, 16);
    texShop:BlitSLT(iBuyHoloId, 197, 88);
    texShop:BlitSLT(iHoloAnimTileId, 197, 88);
    texShop:BlitSLT(iTileEmitter, 200, 168);
    fontLittle:SetCRGB(0.5, 1, 0.5);
    fontLittle:PrintC(80, 31, aBuyObject.LONGNAME);
    fontTiny:SetCRGB(0.5, 0.75, 0);
    fontTiny:PrintC(80, 43, aBuyObject.DESC);
    fontLittle:SetCRGB(1, 1, 0);
    fontLittle:PrintC(80, 63,
      format("%03uz (%u)", aBuyObject.VALUE, iCarryable));
  end
  -- Speech ticks set
  if iSpeechTicks > 0 then
    texShop:BlitSLT(CoreTicks() // 10 % 4 + iTileKeeper, 112, 127);
    texShop:BlitSLT(iTileSpeech, 0, 160);
    fontSpeech:PrintC(57, 168, sMsg);
    iSpeechTicks = iSpeechTicks-1;
  end
  SetBottomRightTip(sTip);
end
-- Set tip and cursor ------------------------------------------------------ --
local function SetTipAndCursor(sText, iId)
  sTip = sText;
  SetCursor(iId);
end
-- Make the guy talk ------------------------------------------------------- --
local function SetSpeech(sM, iSfx)
  sMsg, iSpeechTicks = sM, 120;
  PlayStaticSound(iSfx);
end
-- Open up the shop -------------------------------------------------------- --
local function OpenShop()
  -- Play sound effects
  PlayStaticSound(iSSelect);
  PlayStaticSound(iSOpen);
  LoopStaticSound(iSHoloHum);
  -- Set open shop keys
  SetKeys(true, iKeyBankOpenId);
  bShopOpen = true;
end
-- Shop exit requested ----------------------------------------------------- --
local function ExitShop()
  -- Play sound
  PlayStaticSound(iSSelect);
  -- Stop humming sound
  StopSound(iSHoloHum);
  -- Shop no longer opened
  bShopOpen = false;
  -- Dereference assets for garbage collector
  texShop = false;
  -- Set no keys
  SetKeys(true);
  -- Start the loading waiting procedure
  SetCallbacks(GameProc, RenderInterface, nil);
  -- Return to lobby
  InitLobby(aDigger);
end
-- Adjust product ---------------------------------------------------------- --
local function PreviousProduct() AdjustObject(-1) end;
local function NextProduct() AdjustObject(1) end;
local function BuyProduct()
  -- Check weight and if can't carry this?
  if aDigger.IW + aBuyObject.WEIGHT > aDiggerInfo.STRENGTH then
    SetSpeech("TOO HEAVY FOR YOU", iSError);
  -- Try to buy it and if failed?
  elseif BuyItem(aDigger, iBuyObjTypeId) then
    SetSpeech("SOLD TO YOU NOW!", iSTrade);
    PlayStaticSound(iSTrade);
    UpdateCarryable();
  -- Can't afford it
  else SetSpeech("YOU CANNOT AFFORD IT", iSError) end;
end
-- Shop input callback ----------------------------------------------------- --
local function ShopInput()
  -- Deny any input if speech bubble open
  if iSpeechTicks > 0 then
    sTip = "WAIT";
    return SetCursor(iCWait);
  end
  -- Player clicked the F'Targ?
  if not bShopOpen and IsMouseInBounds(94, 130, 153, 206) then
    SetTipAndCursor("OPEN SHOP", iCSelect);
    -- Mouse button clicked?
    if IsButtonPressed(0) then OpenShop() end;
  -- Mouse over exit?
  elseif IsMouseNotInBounds(8, 8, 312, 208) then
    -- Set help for player
    SetTipAndCursor("GO TO LOBBY", iCExit);
    -- Mouse button clicked?
    if IsButtonPressed(0) then return ExitShop() end;
  -- Shop is open?
  elseif bShopOpen then
    -- Left scroll button (previous item)
    if IsMouseInBounds(31, 59, 47, 74) then
      SetTipAndCursor("LAST ITEM", iCSelect);
      -- Mouse button clicked?
      if IsButtonPressed(0) then PreviousProduct() end
    -- Right scroll button (next item)
    elseif IsMouseInBounds(110, 59, 126, 74) then
      SetTipAndCursor("NEXT ITEM", iCSelect);
      -- Mouse button clicked?
      if IsButtonPressed(0) then NextProduct() end
    -- Mouse over purchase (projector)
    elseif IsMouseInBounds(197, 88, 261, 152) then
      SetTipAndCursor("BUY ITEM", iCSelect);
      -- Mouse button clicked?
      if IsButtonPressed(0) then BuyProduct() end;
    else SetTipAndCursor("SHOP", iCArrow) end;
    -- Mouse wheel moved down?
    if IsScrollingDown() then AdjustObject(-1);
    -- Mouse wheel moved up?
    elseif IsScrollingUp() then AdjustObject(1) end;
  -- Shop closed
  else SetTipAndCursor("SHOP", iCArrow) end;
end
-- When shop assets have loaded? ------------------------------------------- --
local function OnLoaded(aResources)
  -- Play shop music
  PlayMusic(aResources[2]);
  -- Set texture. We only have 25 tiles sized 65x65, discard all the other
  -- tiles as we're using the same bitmap for other sized textures.
  texShop = aResources[1];
  texShop:TileSTC(25);
  -- Cache tile co-ordinates
  iTileBG = texShop:TileA(208, 312, 512, 512);
  iTileSpeech = texShop:TileA(  0, 417, 112, 441);
  iTileKeeper =
    texShop:TileA(  0, 264,  48, 312);
    texShop:TileA( 49, 264,  97, 312);
    texShop:TileA( 98, 264, 146, 312);
    texShop:TileA(147, 264, 195, 312);
  iTileStatus = texShop:TileA(  0, 442, 128, 512);
  iTileEmitter = texShop:TileA(196, 264, 250, 303);
  iTileLights =
    texShop:TileA(345, 282, 400, 310);
    texShop:TileA(401, 282, 456, 310);
    texShop:TileA(457, 282, 512, 310);
  iTileDoor =
    texShop:TileA(313, 220, 352, 240);
    texShop:TileA(353, 220, 392, 240);
    texShop:TileA(393, 220, 432, 240);
    texShop:TileA(433, 220, 472, 240);
    texShop:TileA(473, 220, 512, 240);
    texShop:TileA(313, 241, 352, 261);
    texShop:TileA(353, 241, 392, 261);
    texShop:TileA(393, 241, 432, 261);
    texShop:TileA(433, 241, 472, 261);
    texShop:TileA(473, 241, 512, 261);
    texShop:TileA(313, 262, 352, 282);
    texShop:TileA(353, 262, 392, 282);
    texShop:TileA(393, 262, 432, 282);
    texShop:TileA(433, 262, 472, 282);
    texShop:TileA(473, 262, 512, 282);
  iTileFork =
    texShop:TileA(  0, 313,  64, 345);
    texShop:TileA( 65, 313, 129, 345);
    texShop:TileA(130, 313, 194, 345);
    texShop:TileA(  0, 346,  64, 378);
    texShop:TileA( 65, 346, 129, 378);
    texShop:TileA(130, 346, 194, 378);
    texShop:TileA(  0, 379,  64, 411);
    texShop:TileA( 65, 379, 129, 411);
    texShop:TileA(130, 379, 194, 411);
    texShop:TileA(137, 412, 201, 444);
    texShop:TileA(137, 445, 201, 477);
  -- Reset variables we'll need
  iBuyId, aBuyObject, iBuyObjTypeId, iBuyHoloId, iHoloAnimTileId,
    iHoloAnimTileIdMod = nil, nil, nil, nil, nil, nil;
  iAnimDoor, iAnimDoorMod, iAnimDoorMax = iTileDoor, 0, iTileDoor+14;
  iForkAnim, iForkAnimMod, iForkAnimMax = iTileFork, 0, iTileFork+11;
  iSpeechTicks, bShopOpen = 120, false;
  sMsg, sTip, iCarryable = "SELECT ME TO OPEN SHOP", nil, nil;
  -- Set colour of speech text
  fontSpeech:SetCRGB(0, 0, 0.25);
  -- Select first object
  SetObject(1);
  -- Set closed shop keys
  SetKeys(true, iKeyBankClosedId);
  -- Set shop callbacks
  SetCallbacks(ShopLogic, ShopRender, ShopInput);
end
-- Initialise the shop screen ---------------------------------------------- --
local function InitShop(aActiveObject)
  -- Get selected digger
  aDigger = aActiveObject;
  if not UtilIsTable(aDigger) then
    error("Invalid customer object specified! "..tostring(aDigger)) end;
  -- Get object data
  aDiggerInfo = aDigger.OD;
  -- Load shop resources
  LoadResources("Shop", aAssets, OnLoaded);
end
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  BuyItem, Fade, GameProc, InitCon, InitLobby, IsButtonPressed,
    IsButtonReleased, IsMouseInBounds, IsMouseNotInBounds, IsScrollingDown,
    IsScrollingUp, LoadResources, LoopStaticSound, PlayMusic, PlayStaticSound,
    RenderInterface, RenderShadow, SetBottomRightTip, SetCallbacks, SetCursor,
    SetKeys,
    StopSound, aObjectActions, aObjectData, aObjectDirections,
    aObjectJobs, aShopData, fontLittle, fontSpeech, fontTiny =
      GetAPI("BuyItem", "Fade", "GameProc", "InitCon", "InitLobby",
        "IsButtonPressed", "IsButtonReleased", "IsMouseInBounds",
        "IsMouseNotInBounds", "IsScrollingDown", "IsScrollingUp",
        "LoadResources", "LoopStaticSound", "PlayMusic", "PlayStaticSound",
        "RenderInterface", "RenderShadow", "SetBottomRightTip", "SetCallbacks",
        "SetCursor", "SetKeys", "StopSound", "aObjectActions",
        "aObjectData", "aObjectDirections", "aObjectJobs",
        "aShopData", "fontLittle", "fontSpeech", "fontTiny");
  -- Shop key callbacks
  local function GoExitShop() if iSpeechTicks <= 0 then ExitShop() end end;
  local function GoOpenShop() if iSpeechTicks <= 0 then OpenShop() end end;
  local function GoPreviousProduct()
    if iSpeechTicks <= 0 then PreviousProduct() end end;
  local function GoNextProduct()
    if iSpeechTicks <= 0 then NextProduct() end end;
  local function GoBuyProduct() if iSpeechTicks <= 0 then BuyProduct() end end;
  -- Register keybinds
  local aKeys<const> = Input.KeyCodes;
  local iPress<const> = Input.States.PRESS;
  local RegisterKeys<const> = GetAPI("RegisterKeys");
  local aEscape<const> = { aKeys.ESCAPE, GoExitShop, "zmtcsl", "LEAVE" };
  local sName<const> = "ZMTC SHOP";
  iKeyBankClosedId = RegisterKeys(sName, {
    [iPress] = {
      aEscape,
      { aKeys.ENTER, GoOpenShop, "zmtcso", "OPEN" },
    }
  });
  iKeyBankOpenId = RegisterKeys(sName, {
    [iPress] = {
      aEscape,
      { aKeys.LEFT, GoPreviousProduct, "zmtcspp", "PREVIOUS PRODUCT" },
      { aKeys.RIGHT, GoNextProduct, "zmtcsnp", "NEXT PRODUCT" },
      { aKeys.SPACE, GoBuyProduct, "zmtcsbp", "PURCHASE PRODUCT" },
    }
  });
  -- Set sound effect ids
  local aSfxData<const> = GetAPI("aSfxData");
  iSError, iSFind, iSHolo, iSHoloHum, iSOpen, iSSelect, iSTrade =
    aSfxData.ERROR, aSfxData.FIND, aSfxData.SSELECT, aSfxData.HOLOHUM,
    aSfxData.SOPEN, aSfxData.SELECT, aSfxData.TRADE;
  -- Set cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCWait, iCSelect, iCExit, iCArrow = aCursorIdData.WAIT, aCursorIdData.SELECT,
    aCursorIdData.EXIT, aCursorIdData.ARROW;
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitShop = InitShop }, F = OnReady };
-- End-of-File ============================================================= --

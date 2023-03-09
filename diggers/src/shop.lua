-- SHOP.LUA ================================================================ --
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
  StopSound, aCursorIdData, aObjectActions, aObjectData, aObjectDirections,
  aObjectJobs, aSfxData, aShopData, fontLittle, fontSpeech, fontTiny;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 1, F = "shop", P = { 65, 65, 1, 1, 0 } },
                         { T = 7, F = "shop", P = { } } };
-- Initialise the shop screen ---------------------------------------------- --
local function InitShop(aActiveObject)
  -- Check parameter
  if not UtilIsTable(aActiveObject) then
    error("Invalid customer object specified! "..tostring(aActiveObject)) end;
  -- Get object data
  local aObjectInfo<const> = aActiveObject.OD;
  -- When shop assets have loaded?
  local function OnLoaded(aResources)
    -- Play shop music
    PlayMusic(aResources[2].H);
    -- Set texture. We only have 25 tiles sized 65x65, discard all the other
    -- tiles as we're using the same bitmap for other sized textures.
    local texShop = aResources[1].H;
    texShop:TileSTC(25);
    -- Cache tile co-ordinates
    local iTileBG<const> = texShop:TileA(208, 312, 512, 512);
    local iTileSpeech<const> = texShop:TileA(  0, 417, 112, 441);
    local iTileKeeper<const> =
      texShop:TileA(  0, 264,  48, 312);
      texShop:TileA( 49, 264,  97, 312);
      texShop:TileA( 98, 264, 146, 312);
      texShop:TileA(147, 264, 195, 312);
    local iTileStatus<const> = texShop:TileA(  0, 442, 128, 512);
    local iTileEmitter<const> = texShop:TileA(196, 264, 250, 303);
    local iTileLights<const> =
      texShop:TileA(345, 282, 400, 310);
      texShop:TileA(401, 282, 456, 310);
      texShop:TileA(457, 282, 512, 310);
    local iTileDoor<const> =
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
    local iTileFork<const> =
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
    -- Variables we'll need
    local iBuyId, aBuyObject, aBuyObjectId, iBuyHoloId, aBuyObjectName;
    local iHoloAnimTileId, iHoloAnimTileIdMod;
    local iAnimDoor, iAnimDoorMod, iAnimDoorMax = iTileDoor, 0, iTileDoor+14;
    local iForkAnim, iForkAnimMod, iForkAnimMax = iTileFork, 0, iTileFork+11;
    local iSpeechTicks, bShopOpen = 120, false;
    local sMsg, sTip, iCarryable = "SELECT ME TO OPEN SHOP", nil, nil;
    -- Test if current object can carry the specified object
    local function UpdateCarryable()
      iCarryable = (aObjectInfo.STRENGTH - aActiveObject.IW) //
        aBuyObject.WEIGHT;
    end
    -- Set actual new object
    local function SetObject(iId)
      -- Check id is valid
      if not UtilIsInteger(iId) then error("No id specified to set!") end;
      -- Get object type from shelf and make sure it's valid
      local iObjType<const> = aShopData[iId];
      if not UtilIsInteger(iObjType) then
        error("No shop data for item '"..iId.."'!") end;
      -- Set object information and make sure the object data is valid
      iBuyId, aBuyObjectId, aBuyObject, iBuyHoloId =
        iId, iObjType, aObjectData[iObjType], iId - 1;
      if not UtilIsTable(aBuyObject) then
        error("No object data for object type '"..iObjType.."'!") end;
      -- Animate the holographic emitter
      iHoloAnimTileId, iHoloAnimTileIdMod = 13, 1;
      -- Update Digger carrying weight
      UpdateCarryable();
    end
    -- Scroll through objects
    local function AdjustObject(Id)
      iBuyId = iBuyId + Id;
      if iBuyId < 1 then SetObject(#aShopData);
      elseif iBuyId > #aShopData then SetObject(1);
      else SetObject(iBuyId) end;
      PlayStaticSound(aSfxData.SSELECT);
    end
    -- Shop logic function
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
    -- Render function
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
    -- Set tip and cursor
    local function SetTipAndCursor(sText, iId)
      sTip = sText;
      SetCursor(iId);
    end
    -- Make the guy talk
    local function SetSpeech(sM, iSfx)
      sMsg, iSpeechTicks = sM, 120;
      PlayStaticSound(iSfx);
    end
    -- Shop input callback
    local function ShopInput()
      -- Deny any input if speech bubble open
      if iSpeechTicks > 0 then
        sTip = "WAIT";
        return SetCursor(aCursorIdData.WAIT);
      end
      -- Player clicked the F'Targ?
      if not bShopOpen and IsMouseInBounds(94, 130, 153, 206) then
        SetTipAndCursor("OPEN SHOP", aCursorIdData.SELECT);
        -- Mouse button clicked?
        if IsButtonPressed(0) then
          PlayStaticSound(aSfxData.SELECT);
          PlayStaticSound(aSfxData.SOPEN);
          LoopStaticSound(aSfxData.HOLOHUM);
          bShopOpen = true;
        end
      -- Mouse over exit?
      elseif IsMouseNotInBounds(8, 8, 312, 208) then
        -- Set help for player
        SetTipAndCursor("GO TO LOBBY", aCursorIdData.EXIT);
        -- Mouse button clicked?
        if IsButtonPressed(0) then
          -- Play sound
          PlayStaticSound(aSfxData.SELECT);
          -- Stop humming sound
          StopSound(aSfxData.HOLOHUM);
          -- Shop no longer opened
          bShopOpen = false;
          -- Dereference assets for garbage collector
          texShop = false;
          -- Start the loading waiting procedure
          SetCallbacks(GameProc, RenderInterface, nil);
          -- Return to lobby
          return InitLobby(aActiveObject);
        end
      -- Shop is open?
      elseif bShopOpen then
        -- Left scroll button (previous item)
        if IsMouseInBounds(31, 59, 47, 74) then
          SetTipAndCursor("LAST ITEM", aCursorIdData.SELECT);
          -- Mouse button clicked?
          if IsButtonPressed(0) then AdjustObject(-1) end
        -- Right scroll button (next item)
        elseif IsMouseInBounds(110, 59, 126, 74) then
          SetTipAndCursor("NEXT ITEM", aCursorIdData.SELECT);
          -- Mouse button clicked?
          if IsButtonPressed(0) then AdjustObject(1) end
        -- Mouse over purchase (projector)
        elseif IsMouseInBounds(197, 88, 261, 152) then
          SetTipAndCursor("BUY ITEM", aCursorIdData.SELECT);
          -- Mouse button clicked?
          if IsButtonPressed(0) then
            -- Check weight and if can't carry this?
            if aActiveObject.IW + aBuyObject.WEIGHT > aObjectInfo.STRENGTH then
              SetSpeech("TOO HEAVY FOR YOU", aSfxData.ERROR);
            -- Try to buy it and if failed?
            elseif BuyItem(aActiveObject, aBuyObjectId) then
              SetSpeech("SOLD TO YOU NOW!", aSfxData.TRADE);
              PlayStaticSound(aSfxData.SELECT);
              UpdateCarryable();
            -- Can't afford it
            else SetSpeech("YOU CANNOT AFFORD IT", aSfxData.ERROR) end;
          end
        else SetTipAndCursor("SHOP", aCursorIdData.ARROW) end;
        -- Mouse wheel moved down?
        if IsScrollingDown() then AdjustObject(-1);
        -- Mouse wheel moved up?
        elseif IsScrollingUp() then AdjustObject(1) end;
      -- Shop closed
      else SetTipAndCursor("SHOP", aCursorIdData.ARROW) end;
    end
    -- Set colour of speech text
    fontSpeech:SetCRGB(0, 0, 0.25);
    -- Select first object
    SetObject(1);
    -- Set shop callbacks
    SetCallbacks(ShopLogic, ShopRender, ShopInput);
  end
  -- Load shop resources
  LoadResources("Shop", aAssets, OnLoaded);
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitShop = InitShop }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  BuyItem, Fade, GameProc, InitCon, InitLobby, IsButtonPressed,
  IsButtonReleased, IsMouseInBounds, IsMouseNotInBounds, IsScrollingDown,
  IsScrollingUp, LoadResources, LoopStaticSound, PlayMusic, PlayStaticSound,
  RenderInterface, RenderShadow, SetBottomRightTip, SetCallbacks, SetCursor,
  StopSound, aCursorIdData, aObjectActions, aObjectData, aObjectDirections,
  aObjectJobs, aSfxData, aShopData, fontLittle, fontSpeech, fontTiny
  = -- --------------------------------------------------------------------- --
  GetAPI("BuyItem", "Fade", "GameProc","InitCon", "InitLobby",
    "IsButtonPressed", "IsButtonReleased", "IsMouseInBounds",
    "IsMouseNotInBounds", "IsScrollingDown", "IsScrollingUp", "LoadResources",
    "LoopStaticSound", "PlayMusic", "PlayStaticSound", "RenderInterface",
    "RenderShadow", "SetBottomRightTip", "SetCallbacks", "SetCursor",
    "StopSound", "aCursorIdData", "aObjectActions", "aObjectData",
    "aObjectDirections", "aObjectJobs", "aSfxData", "aShopData", "fontLittle",
    "fontSpeech", "fontTiny");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

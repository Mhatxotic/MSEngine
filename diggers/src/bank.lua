-- BANK.LUA ================================================================ --
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
local format<const>, unpack<const>, error<const> =
  string.format, table.unpack, error;
-- M-Engine function aliases ----------------------------------------------- --
local CoreTicks<const>, UtilBlank<const>, UtilIsTable<const> =
  Core.Ticks, Util.Blank, Util.IsTable;
-- Diggers function and data aliases --------------------------------------- --
local Fade, GameProc, GetGameTicks, HaveZogsToWin, InitLobby, IsButtonPressed,
  IsMouseInBounds, IsMouseNotInBounds, IsScrollingDown, IsScrollingUp,
  LoadResources, PlayMusic, PlayStaticSound, RenderInterface, RenderShadow,
  SellSpecifiedItems, SetBottomRightTip, SetCallbacks, SetCursor,
  aGemsAvailable, aObjectActions, aObjectData, aObjectDirections, aObjectJobs,
  aObjectTypes, fontSpeech, texSpr;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 1, F = "bank", P = { 80, 94, 0, 0, 0 } },
                         { T = 7, F = "bank" } };
-- Locals ------------------------------------------------------------------ --
local aBankerData,                     -- Banker data
      aDigger,                         -- Currently selected digger
      aPlayer,                         -- Owner of digger
      bGameWon,                        -- Game is won?
      fcbSpeechCallback,               -- Speech callback
      iBankerId,                       -- Banker id selected
      iBankerTexId,                    -- Banker texture id selected
      iBankerX, iBankerY,              -- Banker position
      iCArrow,                         -- Arrow cursor ids
      iCWait, iCSelect, iCExit,        -- Cursor ids
      iKeyBankId,                      -- Bank key bank id
      iSError, iSFind, iSSelect,       -- Sound effect ids
      iSTrade,                         -- Trade sound effect id
      iSpeechBubbleX, iSpeechBubbleY,  -- Speech bubble position
      iSpeechTextX, iSpeechTextY,      -- Speech text position
      iSpeechTimer, strTip,            -- Speech timer and trip
      iTreasureValueModifier,          -- Modified treasure value
      strBankerSpeech,                 -- Speech bubble text
      texBank,                         -- Bank texture
      tileBG,                          -- Background tile
      tileSpeech;                      -- Speech tile
-- Mouse over events ------------------------------------------------------- --
local function MsOvFTarg()   return IsMouseInBounds(25,113,87,183) end;
local function MsOvHabbish() return IsMouseInBounds(129,95,191,184) end;
local function MsOvGrablin() return IsMouseInBounds(234,97,295,184) end;
local function MsOvGem1()    return IsMouseInBounds(40,24,72,40) end;
local function MsOvGem2()    return IsMouseInBounds(144,24,176,40) end;
local function MsOvGem3()    return IsMouseInBounds(248,24,280,40) end;
local function MsOvExit()    return IsMouseNotInBounds(8,8,312,208) end;
-- Banker id to mouse function look up table ------------------------------- --
local aBankerStaticData<const> = {
  -- Sell func -- Chk func Gem XY  Tex<Bank>XY  Bub XY  Msg XY ----
  { MsOvFTarg,   MsOvGem1,  50,21, { 0,  16,96,   0,62,  56,70 } },
  { MsOvHabbish, MsOvGem2, 153,21, { 4, 112,96, 104,62, 160,70 } },
  { MsOvGrablin, MsOvGem3, 257,21, { 8, 224,96, 208,62, 264,70 } }
  -- Sell func -- Chk Func Gem XY  Tex<Bank>XY  Bub XY  Msg XY ----
};
-- Function to refresh banker data ----------------------------------------- --
local function RefreshBankerData()
  -- Return if not enough data or data the same
  if #aBankerData == #aBankerStaticData and
    aGemsAvailable[1] == aBankerData[1][1] then return end;
    -- For each gem available
  for iGemId = 1, #aBankerStaticData do
    -- Get gem type and function data
    local iGemTypeId<const> = aGemsAvailable[iGemId];
    local aFuncData<const> = aBankerStaticData[iGemId];
    local aGemObjData<const> = aObjectData[iGemTypeId];
    -- Insert data into lookup table
    aBankerData[iGemId] = {
      iGemId,                                 -- [01] Gem (banker) id
      iGemTypeId,                             -- [02] Gem type id
      aGemObjData.VALUE // 2 +                -- [03] Gem value
        iTreasureValueModifier,
      aGemObjData[aObjectActions.STOP]        -- [04] Gem sprite
                 [aObjectDirections.NONE][1],
      aGemObjData.LONGNAME,                   -- [05] Gem name
      aFuncData[1],                           -- [06] Mouse over sell func
      aFuncData[2],                           -- [07] Mouse over gem func
      aFuncData[3],                           -- [08] Gem position X
      aFuncData[4],                           -- [09] Gem position Y
      aFuncData[5]                            -- [10] Speech data for banker
    };
  end
end
-- Set speech -------------------------------------------------------------- --
local function SetSpeech(iId, iHoldTime, iSfxId, strMsg, fcbOnComplete)
  -- Set speech message and banker id
  strBankerSpeech = strMsg;
  iBankerId = iId;
  -- Set render details from lookup table
  iBankerTexId, iBankerX, iBankerY, iSpeechBubbleX, iSpeechBubbleY,
    iSpeechTextX, iSpeechTextY = unpack(aBankerData[iId][10]);
  -- Finish callback
  local function OnComplete()
    -- Call completion function
    if fcbOnComplete then fcbOnComplete() end;
    -- Enable keys again
    SetKeys(true, iKeyBankId);
  end
  -- Set event when speech completed
  fcbSpeechCallback = OnComplete;
  -- Play sound
  PlayStaticSound(iSfxId);
  -- Set speech timer
  iSpeechTimer = iHoldTime;
  -- Disable keys
  SetKeys(true);
end
-- Function to check if player has won game -------------------------------- --
local function HasBeatenGame()
  -- Ignore if win message already used or player hasn't beaten game
  if bGameWon or not HaveZogsToWin(aPlayer) then return end;
  -- Set speech bubble for win
  SetSpeech(iBankerId, 120, iSFind, "YOU'VE WON THIS ZONE!");
  -- Set that we've won the game so we don't have to say it again
  bGameWon = true;
end
-- Sets a speech bubble but checks if the player won too ------------------- --
local function SetSpeechSell(iBankerId, iGemId)
  -- Record money
  local iMoney<const>, strName = aPlayer.M, nil;
  -- Sell all Jennite first before trying to sell anything else
  if SellSpecifiedItems(aDigger, aObjectTypes.JENNITE) > 0 then
    strName = aObjectData[aObjectTypes.JENNITE].LONGNAME;
  -- No Jennite found so try what the banker is trading
  elseif SellSpecifiedItems(aDigger, iGemId) > 0 then
    strName = aObjectData[iGemId].LONGNAME end;
  -- Money changed hands? Set succeeded message and check for win
  if strName then
    SetSpeech(iBankerId, 60, iSTrade, strName.." SOLD FOR $"..
      format("%03u", aPlayer.M - iMoney), HasBeatenGame);
  -- Set failed speech bubble
  else SetSpeech(iBankerId, 60, iSError, "YOU HAVE NONE OF THESE!") end;
end
-- Speech render procedure ------------------------------------------------- --
local function BankRender()
  -- Render original interface
  RenderInterface();
  -- Draw backdrop with bankers and windows
  texBank:BlitSLT(tileBG, 8, 8);
  -- Render shadow
  RenderShadow(8, 8, 312, 208);
  -- For each banker
  for iI = 1, #aBankerData do
    -- Get banker data and draw it
    local aData<const> = aBankerData[iI];
    texSpr:BlitSLT(aData[4], aData[8], aData[9]);
  end
  -- Speech bubble should show?
  if iSpeechTimer > 0 then
    -- Show banker talking graphic, speech bubble and text
    texBank:BlitSLT(CoreTicks() // 10 % 4 + iBankerTexId,
      iBankerX, iBankerY);
    texBank:BlitSLT(tileSpeech, iSpeechBubbleX, iSpeechBubbleY);
    fontSpeech:PrintC(iSpeechTextX, iSpeechTextY, strBankerSpeech);
    -- Decrement speech bubble timer
    iSpeechTimer = iSpeechTimer - 1;
  -- Speech timer has ended so if there is a callback?
  elseif fcbSpeechCallback then
    -- Call it and clear
    fcbSpeechCallback = fcbSpeechCallback();
  end
  -- Draw tip
  SetBottomRightTip(strTip);
end
-- Exit bank to lobby ------------------------------------------------------ --
local function GoExitBank()
  -- Play sound and exit to game
  PlayStaticSound(iSSelect);
  -- Dereference assets to garbage collector
  texBank = nil;
  -- Disable keys
  SetKeys(true);
  -- Start the loading waiting procedure
  SetCallbacks(GameProc, RenderInterface, nil);
  -- Return to lobby
  return InitLobby(aDigger);
end
-- Check price of an item -------------------------------------------------- --
local function SetCheckSell(iIndex, aData)
  -- Disable keys
  SetKeys(true);
  -- Set the price
  SetSpeech(iIndex, 60, iSSelect,
    format("%s FETCHES $%03u", aData[5], aData[3]))
end
-- Bank input callback ----------------------------------------------------- --
local function BankInput()
  -- Speech text playing?
  if iSpeechTimer > 0 then
    -- Set tip and cursor to wait
    strTip = "WAIT";
    SetCursor(iCWait);
  -- Mouse over exit point?
  elseif MsOvExit() then
    -- Set tip and cursor to exit
    strTip = "GO TO LOBBY";
    SetCursor(iCExit);
    -- Mouse clicked?
    if IsButtonPressed(0) then GoExitBank() end;
  -- Anything else? For each item in sell data
  else for iIndex = 1, #aBankerData do
    -- Get sell data and if mouse is over the sell point?
    local aData<const> = aBankerData[iIndex];
    if aData[6]() then
      -- Set selling gem tip and cursor
      strTip = "SELL GEMS?";
      SetCursor(iCSelect);
      -- Mouse clicked? Sell gems of that type
      if IsButtonPressed(0) then SetSpeechSell(iIndex, aData[2]) end;
      -- Done
      return;
    -- Mouse over gem?
    elseif aData[7]() then
      -- Set checking gem tip and cursor
      strTip = "CHECK VALUE";
      SetCursor(iCSelect);
      -- Mouse clicked? Sell gems of that type
      if IsButtonPressed(0) then SetCheckSell(iIndex, aData) end;
      -- Done
      return;
    end
    -- Nothing happening set idle text and cursor
    strTip = "BANK";
    SetCursor(iCArrow);
  end end
end
-- Main bank procedure ----------------------------------------------------- --
local function BankProc()
  -- Process game procedures
  GameProc();
  -- Check for change
  RefreshBankerData();
end
-- Resources loaded event callback ----------------------------------------- --
local function OnLoaded(aResources)
  -- Play bank music
  PlayMusic(aResources[2]);
  -- Load texture. We only have 12 animations, discard all the other tiles
  -- as we're using the same bitmap for other sized textures.
  texBank = aResources[1];
  texBank:TileSTC(12);
  -- Cache background and speech bubble co-ordinates
  tileBG = texBank:TileA(208, 312, 512, 512);
  tileSpeech = texBank:TileA(0, 488, 112, 512);
  -- Get treasure value modifier
  iTreasureValueModifier = GetGameTicks() // 18000;
  -- Banker data
  aBankerData = { };
  -- Initialise banker data
  RefreshBankerData();
  -- No speech bubbles, reset win notification and set empty tip
  iSpeechTimer, strTip = 0, "";
  -- Set colour of speech text
  fontSpeech:SetCRGB(0, 0, 0.25);
  -- Speech render data and message
  strBankerSpeech, iBankerId, iBankerTexId, iBankerX, iBankerY,
    iSpeechBubbleX, iSpeechBubbleY, iSpeechTextX, iSpeechTextY =
      nil, nil, nil, nil, nil, nil, nil, nil, nil;
  -- Set a speech bubble above the specified characters head
  fcbSpeechCallback = nil;
  -- Get active object and objects owner
  aPlayer = aDigger.P;
  -- Prevents duplicate win messages
  bGameWon = false;
  -- Enable keys
  SetKeys(true, iKeyBankId);
  -- Set the callbacks
  SetCallbacks(BankProc, BankRender, BankInput);
end
-- Initialise the bank screen ---------------------------------------------- --
local function InitBank(aActiveObject)
  -- Set and check active object
  if not UtilIsTable(aActiveObject) then error("Object not selected!") end;
  aDigger = aActiveObject;
  -- Sanity check gems available count
  if #aGemsAvailable < #aBankerStaticData then
    error("Gems available mismatch ("..#aGemsAvailable.."<"..
      #aBankerStaticData..")!")
  end
  -- Load bank texture
  LoadResources("Bank", aAssets, OnLoaded);
end
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  Fade, GameProc, GetGameTicks, HaveZogsToWin, InitLobby, IsButtonPressed,
    IsMouseInBounds, IsMouseNotInBounds, IsScrollingDown, IsScrollingUp,
    LoadResources, PlayMusic, PlayStaticSound, RenderInterface, RenderShadow,
    SellSpecifiedItems, SetBottomRightTip, SetCallbacks, SetCursor, SetKeys,
    aGemsAvailable, aObjectActions, aObjectData, aObjectDirections,
    aObjectJobs, aObjectTypes, fontSpeech, texSpr =
      GetAPI("Fade", "GameProc", "GetGameTicks", "HaveZogsToWin", "InitLobby",
        "IsButtonPressed", "IsMouseInBounds", "IsMouseNotInBounds",
        "IsScrollingDown", "IsScrollingUp", "LoadResources", "PlayMusic",
        "PlayStaticSound", "RenderInterface", "RenderShadow",
        "SellSpecifiedItems", "SetBottomRightTip", "SetCallbacks", "SetCursor",
        "SetKeys", "aGemsAvailable", "aObjectActions", "aObjectData",
        "aObjectDirections", "aObjectJobs", "aObjectTypes", "fontSpeech",
        "texSpr");
  -- Check slot key event callbacks
  local function GoCheckSlot(iSlot)
    if iSpeechTimer <= 0 then SetCheckSell(iSlot, aBankerData[iSlot]) end;
  end
  local function GoCheckSlot1() GoCheckSlot(1) end;
  local function GoCheckSlot2() GoCheckSlot(2) end;
  local function GoCheckSlot3() GoCheckSlot(3) end;
  -- Sell key event callbacks
  local function GoSellSlot(iSlot)
    if iSpeechTimer <= 0 then SetSpeechSell(iSlot, aBankerData[iSlot][2]) end;
  end
  local function GoSellSlot1() GoSellSlot(1) end;
  local function GoSellSlot2() GoSellSlot(2) end;
  local function GoSellSlot3() GoSellSlot(3) end;
  -- Register keybinds
  local aKeys<const> = Input.KeyCodes;
  iKeyBankId = GetAPI("RegisterKeys")("ZMTC BANK", {
    [Input.States.PRESS] = {
      { aKeys.ESCAPE, GoExitBank, "zmtcbl", "LEAVE" },
      { aKeys.N1, GoCheckSlot1, "zmtcbcsa", "CHECK SLOT 1" },
      { aKeys.N2, GoCheckSlot2, "zmtcbcsb", "CHECK SLOT 2" },
      { aKeys.N3, GoCheckSlot3, "zmtcbcsc", "CHECK SLOT 3" },
      { aKeys.N8, GoSellSlot1, "zmtcbssa", "SELL SLOT 1" },
      { aKeys.N9, GoSellSlot2, "zmtcbssb", "SELL SLOT 2" },
      { aKeys.N0, GoSellSlot3, "zmtcbssc", "SELL SLOT 3" }
    }
  });
  -- Set sound effect ids
  local aSfxData<const> = GetAPI("aSfxData");
  iSError, iSFind, iSSelect, iSTrade =
    aSfxData.ERROR, aSfxData.FIND, aSfxData.SELECT, aSfxData.TRADE;
  -- Set cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCWait, iCSelect, iCExit, iCArrow = aCursorIdData.WAIT, aCursorIdData.SELECT,
    aCursorIdData.EXIT, aCursorIdData.ARROW;
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitBank = InitBank }, F = OnReady };
-- End-of-File ============================================================= --

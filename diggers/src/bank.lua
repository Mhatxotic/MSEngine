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
  aCursorIdData, aGemsAvailable, aObjectActions, aObjectData,
  aObjectDirections, aObjectJobs, aObjectTypes, aSfxData, fontSpeech, texSpr;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 1, F = "bank", P = { 80, 94, 0, 0, 0 } },
                         { T = 7, F = "bank", P = { } } };
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
-- Initialise the bank screen ---------------------------------------------- --
local function InitBank(aActiveObject)
  -- Check parameter
  if not UtilIsTable(aActiveObject) then
    error("Object owner not specified!") end;
  -- Sanity check gems available count
  if #aGemsAvailable < #aBankerStaticData then
    error("Gems available mismatch ("..#aGemsAvailable.."<"..
      #aBankerStaticData..")!")
  end
  -- Resources loaded event callback
  local function OnLoaded(aResources)
    -- Play bank music
    PlayMusic(aResources[2].H);
    -- Load texture. We only have 12 animations, discard all the other tiles
    -- as we're using the same bitmap for other sized textures.
    local texBank = aResources[1].H;
    texBank:TileSTC(12);
    -- Cache background and speech bubble co-ordinates
    local tileBG<const> = texBank:TileA(208, 312, 512, 512);
    local tileSpeech<const> = texBank:TileA(0, 488, 112, 512);
    -- Get treasure value modifier
    local iTreasureValueModifier<const> = GetGameTicks() // 18000;
    -- Banker data
    local aBankerData<const> = { };
    -- Function to refresh banker data
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
    -- Initialise banker data
    RefreshBankerData();
    -- No speech bubbles, reset win notification and set empty tip
    local iSpeechTimer, strTip = 0, "";
    -- Set colour of speech text
    fontSpeech:SetCRGB(0, 0, 0.25);
    -- Speech render data and message
    local strBankerSpeech, iBankerId, iBankerTexId, iBankerX, iBankerY,
      iSpeechBubbleX, iSpeechBubbleY, iSpeechTextX, iSpeechTextY;
    -- Set a speech bubble above the specified characters head
    local fcbSpeechCallback;
    local function SetSpeech(iId, iHoldTime, iSfxId, strMsg, fcbOnComplete)
      -- Set speech message and banker id
      strBankerSpeech = strMsg;
      iBankerId = iId;
      -- Set render details from lookup table
      iBankerTexId, iBankerX, iBankerY, iSpeechBubbleX, iSpeechBubbleY,
        iSpeechTextX, iSpeechTextY = unpack(aBankerData[iId][10]);
      -- Set event when speech completed
      fcbSpeechCallback = fcbOnComplete or UtilBlank;
      -- Play sound
      PlayStaticSound(iSfxId);
      -- Set speech timer
      iSpeechTimer = iHoldTime;
    end
    -- Get active object and objects owner
    local aPlayer<const> = aActiveObject.P;
    -- Prevents duplicate win messages
    local bGameWon = false;
    -- Function to check if player has won game
    local function HasBeatenGame()
      -- Ignore if win message already used or player hasn't beaten game
      if bGameWon or not HaveZogsToWin(aPlayer) then return end;
      -- Set speech bubble for win
      SetSpeech(iBankerId, 120, aSfxData.FIND, "YOU'VE WON THIS ZONE!");
      -- Set that we've won the game so we don't have to say it again
      bGameWon = true;
    end
    -- Sets a speech bubble but checks if the player won too
    local function SetSpeechSell(iBankerId, iGemId)
      -- Record money
      local iMoney<const>, strName = aPlayer.M, nil;
      -- Sell all Jennite first before trying to sell anything else
      if SellSpecifiedItems(aActiveObject, aObjectTypes.JENNITE) > 0 then
        strName = aObjectData[aObjectTypes.JENNITE].LONGNAME;
      -- No Jennite found so try what the banker is trading
      elseif SellSpecifiedItems(aActiveObject, iGemId) > 0 then
        strName = aObjectData[iGemId].LONGNAME end;
      -- Money changed hands? Set succeeded message and check for win
      if strName then
        SetSpeech(iBankerId, 60, aSfxData.TRADE, strName.." SOLD FOR $"..
          format("%03u", aPlayer.M - iMoney), HasBeatenGame);
      -- Set failed speech bubble
      else SetSpeech(iBankerId, 60, aSfxData.ERROR,
        "YOU HAVE NONE OF THESE!") end;
    end
    -- Speech render procedure
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
      -- Speech timer has ended so if there is a callback? Call and clear
      elseif fcbSpeechCallback then
        fcbSpeechCallback = fcbSpeechCallback() end;
      -- Draw tip
      SetBottomRightTip(strTip);
    end
    -- Bank input callback
    local function BankInput()
      -- Speech text playing?
      if iSpeechTimer > 0 then
        -- Set tip and cursor to wait
        strTip = "WAIT";
        SetCursor(aCursorIdData.WAIT);
      -- Mouse over exit point?
      elseif MsOvExit() then
        -- Set tip and cursor to exit
        strTip = "GO TO LOBBY";
        SetCursor(aCursorIdData.EXIT);
        -- Mouse clicked?
        if IsButtonPressed(0) then
          -- Play sound and exit to game
          PlayStaticSound(aSfxData.SELECT);
          -- Dereference assets to garbage collector
          texBank = nil;
          -- Start the loading waiting procedure
          SetCallbacks(GameProc, RenderInterface, nil);
          -- Return to lobby
          return InitLobby(aActiveObject);
        end
      -- Anything else? For each item in sell data
      else for iIndex = 1, #aBankerData do
        -- Get sell data and if mouse is over the sell point?
        local aData<const> = aBankerData[iIndex];
        if aData[6]() then
          -- Set selling gem tip and cursor
          strTip = "SELL GEMS?";
          SetCursor(aCursorIdData.SELECT);
          -- Mouse clicked? Sell gems of that type
          if IsButtonPressed(0) then SetSpeechSell(iIndex, aData[2]) end;
          -- Done
          return;
        -- Mouse over gem?
        elseif aData[7]() then
          -- Set checking gem tip and cursor
          strTip = "CHECK VALUE";
          SetCursor(aCursorIdData.SELECT);
          -- Mouse clicked? Sell gems of that type
          if IsButtonPressed(0) then SetSpeech(iIndex, 60, aSfxData.SELECT,
            format("%s FETCHES $%03u", aData[5], aData[3])) end;
          -- Done
          return;
        end
        -- Nothing happening set idle text and cursor
        strTip = "BANK";
        SetCursor(aCursorIdData.ARROW);
      end end
    end
    local function BankProc()
      -- Process game procedures
      GameProc();
      -- Check for change
      RefreshBankerData();
    end
    -- Set the callbacks
    SetCallbacks(BankProc, BankRender, BankInput);
  end
  -- Load bank texture
  LoadResources("Bank", aAssets, OnLoaded);
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitBank = InitBank }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  Fade, GameProc, GetGameTicks, HaveZogsToWin, InitLobby, IsButtonPressed,
  IsMouseInBounds, IsMouseNotInBounds, IsScrollingDown, IsScrollingUp,
  LoadResources, PlayMusic, PlayStaticSound, RenderInterface, RenderShadow,
  SellSpecifiedItems, SetBottomRightTip, SetCallbacks, SetCursor,
  aCursorIdData, aGemsAvailable, aObjectActions, aObjectData,
  aObjectDirections, aObjectJobs, aObjectTypes, aSfxData, fontSpeech, texSpr
  = -- --------------------------------------------------------------------- --
  GetAPI("Fade", "GameProc", "GetGameTicks", "HaveZogsToWin", "InitLobby",
    "IsButtonPressed", "IsMouseInBounds", "IsMouseNotInBounds",
    "IsScrollingDown", "IsScrollingUp", "LoadResources", "PlayMusic",
    "PlayStaticSound", "RenderInterface", "RenderShadow", "SellSpecifiedItems",
    "SetBottomRightTip", "SetCallbacks", "SetCursor", "aCursorIdData",
    "aGemsAvailable", "aObjectActions", "aObjectData", "aObjectDirections",
    "aObjectJobs", "aObjectTypes", "aSfxData", "fontSpeech", "texSpr");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

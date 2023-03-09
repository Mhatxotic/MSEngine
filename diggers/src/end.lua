-- END.LUA ================================================================= --
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
local abs<const>, error<const>, floor<const>, tostring<const> =
  math.abs, error, math.floor, tostring;
-- M-Engine function aliases ----------------------------------------------- --
local UtilIsBoolean<const>, UtilIsInteger<const>, UtilIsString<const>,
  UtilIsTable<const> = Util.IsBoolean, Util.IsInteger, Util.IsString,
  Util.IsTable;
-- Diggers function and data aliases --------------------------------------- --
local Fade, GetCapitalValue, GetGameTicks, InitPost, InitScore,
  IsButtonReleased, LoadResources, PlayMusic, PlayStaticSound, RenderFade,
  RenderObjects, RenderTerrain, SetCallbacks, SetCursor, SetKeys,
  aGemsAvailable, aGlobalData, fontLarge;
-- Locals ------------------------------------------------------------------ --
local aCollections,                    -- All texts
      aLinesBottom,                    -- Bottom lines of texts
      aLinesCentre,                    -- Centre lines of texts
      aLinesTop,                       -- Top lines of texts
      fcbOnFadeIn,                     -- Function to call when faded in
      iCOK, iCExit, iCWait,            -- Cursor ids
      iDeadCost,                       -- Death duties total
      iEndTexId,                       -- End tile id chosen from texture
      iGameTicks,                      -- Total game ticks
      iGameTime,                       -- Total game time
      iKeyBankLoseId,                  -- Lose screen key bank id
      iKeyBankWinResultId,             -- Win screen result key bank id
      iKeyBankWinStatusId,             -- Win screen game status bank id
      iLevelId,                        -- Level that was completed
      iSSelect,                        -- Select sound effect
      iSalary,                         -- Salary paid total
      nFade, nScale,                   -- Fade amounts
      texEnd;                          -- End texture
-- Resources --------------------------------------------------------------- --
local aEndAssets<const>  = { T = 2, F = "end", P = { 0 } };
local aWinAssets<const>  = { true,  -- Select win routines
             { aEndAssets, { T = 7, F = "select" } } };
local aLoseAssets<const> = { false, -- Select lose routines
             { aEndAssets, { T = 7, F = "lose",   P = { } } } };
-- Mark positive colour or negative ---------------------------------------- --
local function Green(sValue) return "\rcff7fff7f"..sValue.."\rr" end;
local function Red(sValue) return "\rcffff7f7f"..sValue.."\rr" end;
local function Colourise(iValue)
  if iValue >= 0 then return Green(iValue);
  else return Red(iValue) end;
end
-- Function to help make lines data ---------------------------------------- --
local function MakeLine(aDest, sMsg)
  -- Chosen X pixel and callback to scroll in
  local iX, fCb;
  -- Id would be even?
  if #aDest % 2 == 0 then
    -- Function to gradually scroll the message in from the left
    local function Increase(iX)
      -- Clamp (don't include 160 or we'll get a FP error)
      if iX >= 159 then return 160;
      -- Move the message right
      else return iX + abs(-160 + iX) * 0.1 end;
    end
    -- Set the X pixel and callback
    iX, fCb = -160, Increase;
  -- Id would be odd?
  else
    -- Function to gradually scroll the message in from the right
    local function Decrease(iX)
      -- Clamp (don't include 160 or we'll get a FP error)
      if iX < 161 then return 160;
      -- Move the message left
      else return iX - (iX - 160) * 0.1 end;
    end
    -- Set the X pixel and callback
    iX, fCb = 480, Decrease;
  end
  -- Insert into chosen lines
  aDest[1 + #aDest] = { iX, aDest.Y + (#aDest * 16), fCb, sMsg };
end
-- Proc a collection of lines ---------------------------------------------- --
local function ProcCollection(aCollection)
  for iLineId = 1, #aCollection do
    local aItem<const> = aCollection[iLineId];
    aItem[1] = aItem[3](aItem[1]);
  end
end
-- Draw a collection of lines ---------------------------------------------- --
local function DrawCollection(aCollection)
  fontLarge:SetCRGBA(1, 1, 1, 1);
  for iLineId = 1, #aCollection do
    local aItem<const> = aCollection[iLineId];
    fontLarge:PrintC(aItem[1], aItem[2], aItem[4]);
  end
end
-- Render end function ----------------------------------------------------- --
local function RenderEnd()
  -- Render terrain and objects
  RenderTerrain();
  RenderObjects();
  -- Render animated fade
  RenderFade(nFade);
  -- Draw ending graphic
  local nScale<const> = nFade * 2;
  texEnd:SetCA(nScale);
  texEnd:BlitSLTWHA(iEndTexId, 160, 120, 159 * nScale, 95 * nScale, nScale);
  -- Set font colour and draw lines
  for iCollectionId = 1, #aCollections do
    DrawCollection(aCollections[iCollectionId]);
  end
end
-- Goto map post mortem ---------------------------------------------------- --
local function GoPostMortem()
  -- Play sound
  PlayStaticSound(iSSelect);
  -- Load music and when finished execute the win assets handler
  InitPost(iLevelId);
end
-- Input win info screen --------------------------------------------------- --
local function InputWinInfo()
  -- Mouse button not clicked? Return!
  if IsButtonReleased(0) then return end;
  -- Goto post mortem
  GoPostMortem();
end
-- Render win information screen ------------------------------------------- --
local function RenderWinInfo()
  -- Render terrain and objects
  RenderTerrain();
  RenderObjects();
  -- Fade backdrop
  RenderFade(0.5);
  -- Draw centre lines
  DrawCollection(aLinesCentre);
end
-- Proc win information screen --------------------------------------------- --
local function ProcWinInfo()
  -- Fade in elements
  if nFade < 0.5 then nFade = nFade + 0.01;
  -- Fade complete?
  elseif nFade >= 0.5 then
    -- Set OK (continue) cursor
    SetCursor(iCOK);
    -- Set game status creen keybinds
    SetKeys(true, iKeyBankWinStatusId);
    -- Clear animation procedure and set wait to click
    SetCallbacks(nil, RenderWinInfo, InputWinInfo);
  end
  -- Draw centre lines
  ProcCollection(aLinesCentre);
end
-- Set game status page ---------------------------------------------------- --
local function GoWinGameStatus()
  -- Play sound
  PlayStaticSound(iSSelect);
  -- Wait cursor for bank text animation animation
  SetCursor(iCWait);
  -- Build data for centre lines
  MakeLine(aLinesCentre,
    Colourise(aGlobalData.gBankBalance).." IN BANK");
  MakeLine(aLinesCentre,
    Colourise(aGlobalData.gPercentCompleted).."% COMPLETED");
  MakeLine(aLinesCentre, "RAISE "..
    Colourise(aGlobalData.gZogsToWinGame - aGlobalData.gBankBalance)..
    " MORE");
  MakeLine(aLinesCentre, "ZOGS TO WIN THE GAME");
  MakeLine(aLinesCentre,
    "(REQUIRED: "..Colourise(aGlobalData.gZogsToWinGame)..")");
  -- We're going to reuse this value just as an input blocking timer
  nFade = 0;
  -- Dereference the ending texture
  texEnd = nil
  -- Set no keys until animation finished
  SetKeys(true);
  -- Show win information screen
  SetCallbacks(ProcWinInfo, RenderWinInfo, nil);
end
-- Render end win input function ------------------------------------------- --
local function InputEndWin()
  -- Mouse button not clicked? Return!
  if IsButtonReleased(0) then return end;
  -- Transition in the game status
  GoWinGameStatus();
end
-- Set game status page ---------------------------------------------------- --
local function GoLoseScore()
  -- Play sound
  PlayStaticSound(iSSelect);
  -- On fade out
  local function OnFadeOut()
    -- Dereference the ending texture
    texEnd = nil
    -- Init score screen
    InitScore();
  end
  -- Failed? Restart the level!
  Fade(0, 1, 0.04, RenderEnd, OnFadeOut, true);
end
-- Render end input function ----------------------------------------------- --
local function InputEndLose()
  -- Mouse button not clicked? Return!
  if IsButtonReleased(0) then return end;
  -- Goto score screen
  GoLoseScore();
end
-- Proc end function ------------------------------------------------------- --
local function ProcBankAnimateEnd()
  -- Animate centre lines
  ProcCollection(aLinesCentre);
end
-- Proc end function ------------------------------------------------------- --
local function ProcAnimateEnd()
  -- Fade in elements
  if nFade < 0.5 then nFade = nFade + 0.01;
  -- Fade complete?
  elseif nFade >= 0.5 then
    -- Clamp fade
    nFade = 0.5;
    -- The zone was won? Clear animation proc and set input win
    fcbOnFadeIn();
  end
  -- Alter animation
  for iCollectionId = 1, #aCollections do
    ProcCollection(aCollections[iCollectionId]);
  end
end
-- On loaded event function ------------------------------------------------ --
local function OnLoaded(aResources, aActivePlayer, aOpponentPlayer, sMsg)
  -- Keep waiting cursor for animation
  SetCursor(iCWait);
  -- Play End music
  PlayMusic(aResources[2]);
  -- Load texture
  texEnd = aResources[1];
  texEnd:TileSTC(4);
  texEnd:TileSD(0,   0,  0, 159, 95);
  texEnd:TileSD(1, 159,  0, 159, 95);
  texEnd:TileSD(2, 318,  0, 159, 95);
  texEnd:TileSD(3,   0, 95, 159, 95);
  -- Get cost of capital
  aGlobalData.gCapitalCarried = GetCapitalValue();
  -- Get cost of digger deaths
  iDeadCost, iSalary = 0, 0;
  local aActivePlayerDiggers<const> = aActivePlayer.D;
  for iI = 1, #aActivePlayerDiggers do
    local aDigger<const> = aActivePlayerDiggers[iI];
    if not aDigger then
      aGlobalData.gTotalDeaths = aGlobalData.gTotalDeaths + 1;
      iDeadCost = iDeadCost + 65;
    else
      iSalary = iSalary + 30;
    end
  end
  -- Get game ticks and time
  iGameTicks = GetGameTicks();
  iGameTime = iGameTicks // 3600;
  -- Add data
  aGlobalData.gTotalGemsFound =
    aGlobalData.gTotalGemsFound + aActivePlayer.GEM;
  aGlobalData.gTotalGemsSold =
    aGlobalData.gTotalGemsSold + aActivePlayer.GS;
  aGlobalData.gTotalCapital =
    aGlobalData.gTotalCapital + aGlobalData.gCapitalCarried;
  aGlobalData.gTotalDeathExp =
    aGlobalData.gTotalDeathExp + iDeadCost;
  aGlobalData.gTotalPurchExp =
    aGlobalData.gTotalPurchExp + aActivePlayer.BP;
  aGlobalData.gTotalTimeTaken =
    aGlobalData.gTotalTimeTaken + iGameTicks // 60;
  aGlobalData.gTotalIncome =
    aGlobalData.gTotalIncome + aActivePlayer.GI;
  aGlobalData.gTotalDug =
    aGlobalData.gTotalDug + aActivePlayer.DUG;
  aGlobalData.gTotalPurchases =
    aGlobalData.gTotalPurchases + aActivePlayer.PUR;
  aGlobalData.gTotalSalaryPaid =
    aGlobalData.gTotalSalaryPaid + iSalary;
  aGlobalData.gBankBalance =
    aGlobalData.gBankBalance + (aActivePlayer.M - iDeadCost - iSalary);
  aGlobalData.gPercentCompleted =
    floor(aGlobalData.gBankBalance / aGlobalData.gZogsToWinGame * 100);
  -- Make lines data with initial Y position
  aLinesTop, aLinesBottom, aLinesCentre = { Y=12 }, { Y=180 }, { Y=80 };
  -- Array holding top and bottom datas which are drawn together
  aCollections = { aLinesTop, aLinesBottom };
  -- Build data for top three lines
  MakeLine(aLinesTop, sMsg);
  MakeLine(aLinesTop, "OPPONENT HAD "..Green(aOpponentPlayer.M).." ZOGS");
  MakeLine(aLinesTop, "GAME TIME WAS "..Green(iGameTime).." MINS");
  -- Build data for bottom three lines
  MakeLine(aLinesBottom,
    Green(aGlobalData.gCapitalCarried).." CAPITAL CARRIED");
  MakeLine(aLinesBottom, Red(iSalary).." SALARY PAID");
  MakeLine(aLinesBottom, Red(iDeadCost).." DEATH DUTIES");
  -- Fade amount
  nFade, nScale = 0, 0;
  -- Change render procedures
  SetCallbacks(ProcAnimateEnd, RenderEnd, nil);
end
-- On faded in win --------------------------------------------------------- --
local function OnFadeInWin()
  -- Set OK (continue) cursor
  SetCursor(iCOK);
  -- Set game status creen keybinds
  SetKeys(true, iKeyBankWinResultId);
  -- Clear animation procedure and set wait to click
  SetCallbacks(nil, RenderEnd, InputEndWin);
end
-- On faded in lose ------------------------------------------------------- --
local function OnFadeInLose()
  -- Set EXIT cursor
  SetCursor(iCExit)
  -- Set game status creen keybinds
  SetKeys(true, iKeyBankLoseId);
  -- Clear animation procedure and set wait to click
  SetCallbacks(nil, RenderEnd, InputEndLose);
end
-- Initialise the lose screen ---------------------------------------------- --
local function InitEnd(iLId, aAP, aOP, aIR, iETId, sMsg)
  -- Check parameters
  if not UtilIsInteger(iLId) then
    error("Invalid level id specified! "..tostring(iLId)) end;
  if iLId <= 0 then error("Specify positive level id, not "..iLId.."!") end;
  if not UtilIsTable(aAP) then
    error("Invalid active player table! "..tostring(aAP)) end;
  if not UtilIsTable(aOP) then
    error("Invalid opponent player table! "..tostring(aOP)) end;
  if not UtilIsTable(aIR) then
    error("Invalid resources table! "..tostring(aIR)) end;
  if not UtilIsInteger(iETId) then
    error("Invalid texture id integer! "..tostring(iETId)) end;
  if not UtilIsString(sMsg) then
    error("Invalid message string! "..tostring(sMsg)) end;
  -- Set level id
  iLevelId = iLId;
  -- Set tile id to use
  iEndTexId = iETId;
  -- Set callback
  if aIR[1] then fcbOnFadeIn = OnFadeInWin else fcbOnFadeIn = OnFadeInLose end;
  -- Load level ending resources
  LoadResources("ZoneEnd", aIR[2], OnLoaded, aAP, aOP, sMsg);
end
-- ------------------------------------------------------------------------- --
local function InitLoseDead(iLId, aP, aOP)
  InitEnd(iLId, aP, aOP, aLoseAssets, 0, "ALL YOUR DIGGERS DIED") end;
local function InitWinDead(iLId, aP, aOP)
  InitEnd(iLId, aP, aOP, aWinAssets,  1, "YOUR OPPONENT IS DEAD") end;
local function InitWin(iLId, aP, aOP)
  InitEnd(iLId, aP, aOP, aWinAssets,  2, "YOU RAISED THE CASH") end;
local function InitLose(iLId, aP, aOP)
  InitEnd(iLId, aP, aOP, aLoseAssets, 3, "YOUR OPPONENT WON") end;
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  Fade, GetCapitalValue, GetGameTicks, InitPost, InitScore, IsButtonReleased,
    LoadResources, PlayMusic, PlayStaticSound, RenderFade, RenderObjects,
    RenderTerrain, SetCallbacks, SetCursor, SetKeys, aGemsAvailable,
    aGlobalData, fontLarge =
      GetAPI("Fade", "GetCapitalValue", "GetGameTicks", "InitPost",
        "InitScore", "IsButtonReleased", "LoadResources", "PlayMusic",
        "PlayStaticSound", "RenderFade", "RenderObjects", "RenderTerrain",
        "SetCallbacks", "SetCursor", "SetKeys", "aGemsAvailable",
        "aGlobalData", "fontLarge");
  -- Register keybinds
  local aKeys<const>, aStates<const> = Input.KeyCodes, Input.States;
  local iPress<const> = aStates.PRESS;
  iKeyBankLoseId = GetAPI("RegisterKeys")("IN-GAME LOSE", {
    [iPress] = { { aKeys.ESCAPE, GoLoseScore, "iglets", "EXIT TO SCORES" } }
  });
  local iEnter<const> = aKeys.ENTER;
  iKeyBankWinResultId = GetAPI("RegisterKeys")("IN-GAME WIN", {
    [iPress] = { { iEnter, GoWinGameStatus, "igwc", "CONTINUE" } }
  });
  iKeyBankWinStatusId = GetAPI("RegisterKeys")("IN-GAME WIN", {
    [iPress] = { { iEnter, GoPostMortem, "igwpm", "POST MORTEM" } }
  });
  -- Set sound effect ids
  iSSelect = GetAPI("aSfxData").SELECT;
  -- Set cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCOK, iCExit, iCWait =
    aCursorIdData.OK, aCursorIdData.EXIT, aCursorIdData.WAIT;
end
-- Exports and imports ----------------------------------------------------- --
return { F = OnReady, A = { InitWin = InitWin,
                            InitWinDead = InitWinDead,
                            InitLose = InitLose,
                            InitLoseDead = InitLoseDead } };
-- End-of-File ============================================================= --

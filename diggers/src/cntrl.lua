-- CNTRL.LUA =============================================================== --
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
local unpack<const> = table.unpack;
-- M-Engine function aliases ----------------------------------------------- --
local CoreTicks<const> = Core.Ticks;
-- Diggers function and data aliases --------------------------------------- --
local Fade, IsButtonReleased, IsMouseInBounds, IsMouseNotInBounds,
  IsMouseNotInBounds, LoadResources, PlayStaticSound, RenderShadow,
  SetBottomRightTipAndShadow, SetCallbacks, SetCursor, SetKeys,
  aGlobalData, fontSpeech;
-- Locals ------------------------------------------------------------------ --
local aFlashCache;                     -- Hot point flash data
local aFlashData;                      -- Active hot point
local aMouseOverEvents;                -- Hotpoint data
local aSpeechList;                     -- Controller speeches list
local iKeyBankId;                      -- Key bank id
local iLastHotpoint;                   -- Last hot point selected
local iSSelect;                        -- Sound effect select id for
local iSpeechIndex;                    -- Current speech index
local iSpeechListCount;                -- Controller speech chatter frame
local iSpeechListLoop;                 -- Controller speech chatter loop point
local iSpeechTimer;                    -- Time to show controller speech.
local sMsg;                            -- Controller speech message
local sTip;                            -- Current bottom right tip
local texCon;                          -- Controller texture
local texLobby;                        -- Lobby texture
local tileBook, tileCon, tileConAnim;  -- Book and controller character tiles
local tileFile, tileFish, tileMap;     -- File, fish and map tiles
local tileRace, tileSpeech;            -- Race select and speech tiles
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "lobbyc", P = { 0 } },
                         { T = 2, F = "cntrl",  P = { 0 } } };
-- Render callback --------------------------------------------------------- --
local function RenderCon()
  -- Frame timer slowed down
  local iAnimTime<const> = CoreTicks() // 10;
  -- Draw backdrop, controller screen and animated fish
  texLobby:BlitLT(-54, 0);
  texCon:BlitSLT(tileCon, 8, 8);
  texCon:BlitSLT(iAnimTime % 5 + tileFish, 9, 119);
  -- Render shadow
  RenderShadow(8, 8, 312, 208);
  -- Draw speech bubble
  if iSpeechTimer > 0 then
    -- Draw yap
    texCon:BlitSLT(iAnimTime % 4 + tileConAnim, 88, 36);
    -- Draw flash
    if aFlashData then texCon:BlitSLT(iAnimTime % 2 + aFlashData[1],
      aFlashData[2], aFlashData[3]) end;
    -- Draw speech bubble
    texCon:BlitSLT(tileSpeech, 0, 150);
    -- Draw text
    fontSpeech:PrintC(78, 157, sMsg);
    -- Decrement speech timer
    iSpeechTimer = iSpeechTimer - 1;
  end
  -- Draw tip
  SetBottomRightTipAndShadow(sTip);
end
-- Controller logic -------------------------------------------------------- --
local function ControllerLogic()
  -- Process mouse over items
  for iI = 1, #aMouseOverEvents do
    -- Get mouse over event item and if mouse over condition is true?
    local aMouseOverEvent<const> = aMouseOverEvents[iI];
    if aMouseOverEvent[1]() then
      -- Do not update text or cursor if we already set this hotpoint.
      -- This is to save a bit of cpu cycles with setting the same
      -- string and cursor over and over again.
      if iI == iLastHotpoint then break end;
      iLastHotpoint = iI;
      -- Modify the new tip and cursor
      sTip = aMouseOverEvent[2];
      SetCursor(aMouseOverEvent[3]);
      -- No need to check anything else
      break;
    end
  end
  -- Grab a speech item relating to the current index and if found?
  local aSpeechItem<const> = aSpeechList[iSpeechIndex];
  if aSpeechItem then
    -- Set new speech data
    iSpeechTimer, sMsg, aFlashData = 300, aSpeechItem[1], aSpeechItem[2];
  -- Else if we're at the end? Reset the index
  elseif iSpeechIndex == iSpeechListLoop then iSpeechIndex = 0 end;
  -- Increment index
  iSpeechIndex = iSpeechIndex + 1;
end
-- Finish and return to lobby ---------------------------------------------- --
local function FinishAndFade(fcbOnFadeOut, aCbParams);
  -- Play select sound
  PlayStaticSound(iSSelect);
  -- Transition helper
  local function OnFadeOut()
    -- Dereference assets for garbage collection
    texLobby, texCon = nil, nil;
    -- Do next procedure
    fcbOnFadeOut(unpack(aCbParams));
  end
  -- Fade out to requested loading procedure
  return Fade(0, 1, 0.04, RenderCon, OnFadeOut);
end
-- Controller screen input procedure --------------------------------------- --
local function ControllerInput()
  -- Mouse button not clicked? Return!
  if IsButtonReleased(0) then return end;
  -- Process mouse over items
  for iI = 1, #aMouseOverEvents do
    -- Get hotpoint and if mouse is over the hotpoint then call transition
    local aMouseOverEvent<const> = aMouseOverEvents[iI];
    if aMouseOverEvent[1]() then
      local fcbCb<const> = aMouseOverEvent[4];
      if fcbCb then FinishAndFade(fcbCb, aMouseOverEvent[5]) end;
      return;
    end
  end
end
-- When controller screen has faded in? ------------------------------------ --
local function OnFadeIn()
  -- Set keybank
  SetKeys(true, iKeyBankId);
  -- Set controller callbacks
  SetCallbacks(ControllerLogic, RenderCon, ControllerInput);
end
-- When controller resources have loaded? ---------------------------------- --
local function OnLoaded(aResources)
  -- Setup lobby texture
  texLobby = aResources[1];
  texLobby:TileSTC(1);
  texLobby:TileS(0, 0, 272, 428, 512);
  -- Setup controller texture
  texCon = aResources[2];
  tileConAnim = texCon:TileA(0,   0, 160,  84);
                texCon:TileA(0,  85, 160, 169);
                texCon:TileA(0, 170, 160, 254);
                texCon:TileA(0, 255, 160, 339);
  -- Cache other tiles
  tileCon    = texCon:TileA(208, 312, 512, 512); -- [0](1)
  tileSpeech = texCon:TileA(356, 250, 512, 274); -- [0](1)
  tileFish   = texCon:TileA(273, 275, 320, 311); -- [0](5)
               texCon:TileA(321, 275, 368, 311); -- [1]
               texCon:TileA(369, 275, 416, 311); -- [2]
               texCon:TileA(417, 275, 464, 311); -- [3]
               texCon:TileA(465, 275, 512, 311); -- [4]
  tileMap    = texCon:TileA(  0, 412,  63, 453); -- [0](2)
               texCon:TileA( 64, 412, 127, 453); -- [1]
  tileRace   = texCon:TileA(128, 409, 160, 453); -- [0](2)
               texCon:TileA(161, 409, 193, 453); -- [1]
  tileBook   = texCon:TileA(  0, 454,  79, 485); -- [0](2)
               texCon:TileA( 80, 454, 159, 485); -- [1]
  tileFile   = texCon:TileA(  0, 486,  95, 512); -- [0](2)
               texCon:TileA( 96, 486, 191, 512); -- [1]
  -- Data for flashing textures to help the player know what to do
  aFlashCache = {
    [tileMap]  = { tileMap,  9,   9 }, [tileRace] = { tileRace, 232, 160 },
    [tileBook] = { tileBook, 9, 176 }, [tileFile] = { tileFile,  73, 181 },
  };
  -- Set empty tip and speech timer
  sTip, iSpeechTimer, sMsg, aFlashData, aSpeechList, iSpeechListCount,
    iSpeechListLoop, iSpeechIndex, iLastHotpoint =
      nil, 0, nil, nil, { }, 60, 0, 0, 0;
  -- Add a speech item
  local function AddSpeechItem(sString, iId)
    aSpeechList[iSpeechListCount] = { sString, aFlashCache[iId] }
    iSpeechListCount = iSpeechListCount + 900;
    iSpeechListLoop = iSpeechListCount - 120;
  end
  -- If we're not in a new game?
  if not aGlobalData.gNewGame then
    -- If no zone is selected?
    if not aGlobalData.gSelectedLevel then
      -- Player returned from completing a zone
      AddSpeechItem("WELCOME BACK, MASTER MINER");
      AddSpeechItem("PLEASE PICK YOUR NEXT ZONE", tileMap);
    -- Zone already selected? Tell player to bugger off
    else AddSpeechItem("NOW YOU'RE DONE, BE GONE") end;
    -- Add some other things
    AddSpeechItem("RECORDED YOUR PROGRESS?", tileFile);
    AddSpeechItem("WHAT!? YOU'RE STILL HERE?");
  -- New game and race not selected?
  elseif not aGlobalData.gSelectedRace then
    -- Zone not selected?
    if not aGlobalData.gSelectedLevel then
      -- Tell player to pick diggers race and zone
      AddSpeechItem("WELCOME, MASTER MINER", tileFile);
      AddSpeechItem("YOU'LL NEED TO PICK DIGGERS", tileRace);
      AddSpeechItem("YOU'LL WANT TO PICK A ZONE", tileMap);
    -- Level selected? Tell player to pick diggers
    else AddSpeechItem("NOW YOU MUST PICK DIGGERS", tileRace) end;
    -- Player can also load previous progress
    AddSpeechItem("PAST RECORDS ARE HERE", tileFile);
  -- Race selected but zone not selected? Tell player to pick a zone
  elseif not aGlobalData.gSelectedLevel then
    AddSpeechItem("YOU MUST ALSO PICK A ZONE", tileMap);
  -- Player has picked zone and race?
  else
    -- Tell player to bugger off and play the game
    AddSpeechItem("NOW YOU'RE DONE, BE GONE");
    AddSpeechItem("WHAT!? YOU'RE STILL HERE?");
  end
  -- Add some generic chatter
  AddSpeechItem("THE BOOK MAY BE OF HELP", tileBook);
  AddSpeechItem("AND DON'T TAKE ALL DAY");
  -- Set colour of speech text
  fontSpeech:SetCRGB(0, 0, 0.25);
  -- Change render procedures
  Fade(1, 0, 0.04, RenderCon, OnFadeIn);
end
-- Init controller screen function ----------------------------------------- --
local function InitCon() LoadResources("Controller", aAssets, OnLoaded) end;
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  Fade, IsButtonReleased, IsMouseInBounds, IsMouseNotInBounds, LoadResources,
    PlayStaticSound, RenderShadow, SetBottomRightTipAndShadow, SetCallbacks,
    SetCursor, SetKeys, aGlobalData, fontSpeech =
      GetAPI("Fade", "IsButtonReleased", "IsMouseInBounds",
        "IsMouseNotInBounds", "LoadResources", "PlayStaticSound",
        "RenderShadow", "SetBottomRightTipAndShadow", "SetCallbacks",
        "SetCursor", "SetKeys", "aGlobalData", "fontSpeech");
  -- Mouse over events
  local function MouseOverMap() return IsMouseInBounds(9, 9, 57, 52) end;
  local function MouseOverBook() return IsMouseInBounds(9, 176, 76, 207) end;
  local function MouseOverFile() return IsMouseInBounds(76, 182, 163, 207) end;
  local function MouseOverRace()
    return aGlobalData.gNewGame and IsMouseInBounds(242, 160, 261, 283) end;
  local function MouseOverExit() return IsMouseNotInBounds(8, 8, 312, 208) end;
  local function AlwaysTrue() return true end;
  local InitBook<const>, InitFile<const>, InitLobby<const>, InitMap<const>,
    InitRace<const>, aCursorIdData<const> = GetAPI("InitBook", "InitFile",
       "InitLobby", "InitMap", "InitRace", "aCursorIdData");
  local iCSelect<const> = aCursorIdData.SELECT;
  local aMapHP<const> =
    { MouseOverMap,  "SELECT ZONE", iCSelect, InitMap, { } };
  local aRaceHP<const> =
    { MouseOverRace, "SELECT RACE", iCSelect, InitRace, { } };
  local aFileHP<const> =
    { MouseOverFile, "LOAD/SAVE", iCSelect, InitFile, { } };
  local aBookHP<const> =
    { MouseOverBook, "THE BOOK", iCSelect, InitBook, { false } };
  local aExitHP<const> =
    { MouseOverExit, "GO TO LOBBY", aCursorIdData.EXIT,
        InitLobby, { nil, true } };
  aMouseOverEvents = { aMapHP, aRaceHP, aFileHP, aBookHP, aExitHP,
    { AlwaysTrue, "CONTROLLER", aCursorIdData.ARROW, nil, { } } };
  -- Exit function
  local function Finish(aHotpoint)
    FinishAndFade(aHotpoint[4], aHotpoint[5]);
  end
  local function FinishMap() Finish(aMapHP) end;
  local function FinishRace()
    if aGlobalData.gNewGame then Finish(aRaceHP) end end;
  local function FinishFile() Finish(aFileHP) end;
  local function FinishBook() Finish(aBookHP) end;
  local function FinishLobby() Finish(aExitHP) end;
  -- Register keybinds
  local aKeys<const> = Input.KeyCodes;
  iKeyBankId = GetAPI("RegisterKeys")("ZMTC CONTROLLER", {
    [Input.States.PRESS] = {
      { aKeys.ESCAPE, FinishLobby, "zmtccgtl", "GO TO LOBBY" },
      { aKeys.B, FinishBook, "zmtcrtb", "READ THE BOOK" },
      { aKeys.F, FinishFile, "zmtcfs", "FILE STORAGE" },
      { aKeys.R, FinishRace, "zmtccsrc", "SELECT RACE" },
      { aKeys.Z, FinishMap, "zmtccsz", "SELECT ZONE" }
    }
  });
  -- Set sound effect ids
  iSSelect = GetAPI("aSfxData").SELECT;
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitCon = InitCon }, F = OnReady };
-- End-of-File ============================================================= --

-- FILE.LUA ================================================================ --
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
local tonumber<const>, format<const>, pairs<const>, floor<const> =
  tonumber, string.format, pairs, math.floor;
-- M-Engine function aliases ----------------------------------------------- --
local UtilFormatTime<const>, CoreOSTime<const>, VariableSave<const> =
  Util.FormatTime, Core.OSTime, Variable.Save;
-- Diggers function and data aliases --------------------------------------- --
local Fade, InitCon, IsButtonReleased, IsMouseInBounds, IsMouseNotInBounds,
  LoadResources, PlayStaticSound, RenderShadow, SetBottomRightTipAndShadow,
  SetCallbacks, SetCursor, SetKeys, aLevelsData, aObjectData, aObjectTypes,
  fontSpeech, texSpr;
-- Locals ------------------------------------------------------------------ --
local aFileData;                       -- File data
local aNameData;                       -- File names data
local aSaveSlot<const> = { };          -- Contains save cvars
local iCArrow, iCExit, iCOK, iCSelect; -- Cursor ids
local iKeyBankId;                      -- Key bank id
local iSClick, iSSelect;               -- Sound effects used
local iSelected;                       -- File selected
local sMsg;                            -- Title text
local sTip;                            -- Current tip
local texFile;                         -- File screen texture
local texLobby;                        -- Lobby texture
local tileFile;                        -- File texture tile
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "cntrl",  P = { 0 } },
                         { T = 2, F = "lobbyc", P = { 0 } } };
-- Match text -------------------------------------------------------------- --
local sFileMatchText<const> =
  "^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+),\z
    (%d+),(%d+),(%d+),(%d+),([%d%s]*)$"
-- Global data ------------------------------------------------------------- --
local aGlobalData<const> = { };
-- Initialise a new game --------------------------------------------------- --
local function InitNewGame()
  aGlobalData.gBankBalance,      aGlobalData.gCapitalCarried,
  aGlobalData.gGameSaved,        aGlobalData.gLevelsCompleted,
  aGlobalData.gNewGame,          aGlobalData.gPercentCompleted,
  aGlobalData.gSelectedLevel,    aGlobalData.gSelectedRace,
  aGlobalData.gTotalCapital,     aGlobalData.gTotalExploration,
  aGlobalData.gTotalDeaths,      aGlobalData.gTotalDug,
  aGlobalData.gTotalGemsFound,   aGlobalData.gTotalGemsSold,
  aGlobalData.gTotalIncome,      aGlobalData.gTotalEnemyKills,
  aGlobalData.gTotalPurchases,   aGlobalData.gTotalHomicides,
  aGlobalData.gTotalTimeTaken,   aGlobalData.gZogsToWinGame =
    0,                             0,
    true,                          { },
    true,                          0,
    nil,                           nil,
    0,                             0,
    0,                             0,
    0,                             0,
    0,                             0,
    0,                             0,
    0,                             17500;
end
-- Read, verify and return save data --------------------------------------- --
local function LoadSaveData()
  -- Data to return
  local aFileData<const>, aNameData<const> = { }, { };
  -- Get game data CVars
  for iIndex = 1, 4 do
    -- Get CVar and if not empty
    local sData<const> = aSaveSlot[iIndex]:Get();
    if #sData > 0 then
      -- Get data for num
      -- We need 5 comma separated values (Last value optional)
      local T, TTT, R, B, C, TSP, TC, TDE, TD, TGS, TGF, TI,
        TDG, TPE, TP, LC, L = sData:match(sFileMatchText);
      -- Convert everything to integers
      T, TTT, R, B, C, TSP, TC, TDE, TD, TGS, TGF, TI, TDG, TPE, TP, LC =
        tonumber(T), tonumber(TTT), tonumber(R), tonumber(B), tonumber(C),
        tonumber(TSP), tonumber(TC), tonumber(TDE), tonumber(TD),
        tonumber(TGS), tonumber(TGF), tonumber(TI), tonumber(TDG),
        tonumber(TPE), tonumber(TP), tonumber(LC);
      -- Check variables and if they are all good?
      if TTT and T and R and B and C and TSP and TC and TDE and TD and
         TGS and TGF and TI and TDG and TPE and TP and LC and L and
         T >= 1 and TTT >= 0 and R >= 0 and R <= 3 and
         B <= aGlobalData.gZogsToWinGame and C >= 0 and C <= 9999 and
         TSP >= 0 and TC >= 0 and TDE >= 0 and TD >= 0 and TGS >= 0 and
         TGF >= 0 and TI >= 0 and TDG >= 0 and TPE >= 0 and TP >= 0 and
         LC >= 0 and LC <= #aLevelsData then
        -- Parse levels completed
        local CL<const>, LA = { }, 0;
        for LI in L:gmatch("(%d+)") do
          -- Convert to number and if valid number?
          LI = tonumber(LI);
          if LI and LI >= 1 and LI <= #aLevelsData then
            -- Push valid level
            CL[LI], LA = true, LA + 1;
          end
        end
        -- Levels added and valid number of levels?
        if LA > 0 and LA <= #aLevelsData and LA == LC then
          -- Level data OK! file and name data
          aFileData[iIndex], aNameData[iIndex] =
            { T, TTT, R, B, C, TSP, TC, TDE, TD, TGS,
              TGF, TI, TDG, TPE, TP, CL },
            format("%s (%s) %u%% (%05u$)",
              UtilFormatTime(T, "%a %b %d %H:%M:%S %Y"):upper(),
              aObjectData[aObjectTypes.FTARG + R].NAME,
              floor(B / aGlobalData.gZogsToWinGame * 100), B);
        else aNameData[iIndex] = "CORRUPTED SLOT "..iIndex.." (E#2)" end;
      else aNameData[iIndex] = "CORRUPTED SLOT "..iIndex.." (E#1)" end;
    else aNameData[iIndex] = "EMPTY SLOT "..iIndex end;
  end
  -- Return data
  return aFileData, aNameData;
end
-- Set tip and cursor ------------------------------------------------------ --
local function SetCursorAndTip(iCId, sWhat) SetCursor(iCId) sTip = sWhat end;
-- Render callback --------------------------------------------------------- --
local function RenderFile()
  -- Draw backdrop
  texLobby:BlitLT(-54, 0);
  -- Draw controller screen
  texFile:BlitSLT(tileFile, 8, 8);
  -- Render shadow
  RenderShadow(8, 8, 312, 208);
  -- Draw message
  fontSpeech:SetCRGB(0, 0, 0.25);
  fontSpeech:PrintC(160, 31, sMsg);
  -- Render file names
  for I = 1, 4 do
    -- File selected? Draw selection box!
    if iSelected == I then
      texSpr:BlitSLTRB(801, 35, 47+(I*13), 285, 60+(I*13));
    end
    -- Print name of file
    fontSpeech:SetCRGB(1, 1, 1);
    fontSpeech:PrintC(160, 49+(I*13), aNameData[I]);
  end
  -- Draw tip
  SetBottomRightTipAndShadow(sTip);
end
-- Mouse over events ------------------------------------------------------- --
local function MouseOverExit()
  return IsMouseNotInBounds(8, 8, 312, 208) end;
local function MouseOverLoad()
  return IsMouseInBounds(57, 126, 115, 183) end;
local function MouseOverSave()
  return IsMouseInBounds(201, 126, 259, 183) end;
local function MouseOverFile1()
  return IsMouseInBounds(35, 60, 281, 73) end;
local function MouseOverFile2()
  return IsMouseInBounds(35, 71, 281, 88) end;
local function MouseOverFile3()
  return IsMouseInBounds(35, 84, 281, 101) end;
local function MouseOverFile4()
  return IsMouseInBounds(35, 97, 281, 114) end;
-- Item selected ----------------------------------------------------------- --
local function Select(Id)
  -- Play select sound
  PlayStaticSound(iSClick);
  -- Set selected file
  iSelected = Id;
  -- Set message to selected file
  sMsg = aNameData[iSelected];
end
-- File screen logic ------------------------------------------------------- --
local function FileLogic()
  -- Load icon?
  if MouseOverLoad() then
    -- If we can load?
    if iSelected and aFileData[iSelected] then
      return SetCursorAndTip(iCOK, "LOAD "..iSelected) end;
    -- Can't load
    return SetCursorAndTip(iCArrow, "CAN'T LOAD");
  end
  -- Save icon?
  if MouseOverSave() then
    -- Race selected, file selected and not a new game? Can save!
    if aGlobalData.gSelectedRace and
       iSelected and
       not aGlobalData.gNewGame then
      return SetCursorAndTip(iCOK, "SAVE "..iSelected) end;
    -- Can't save
    return SetCursorAndTip(iCArrow, "CAN'T SAVE");
  end
  -- File selection
  if MouseOverFile1() then return SetCursorAndTip(iCSelect, "SELECT 1") end;
  if MouseOverFile2() then return SetCursorAndTip(iCSelect, "SELECT 2") end;
  if MouseOverFile3() then return SetCursorAndTip(iCSelect, "SELECT 3") end;
  if MouseOverFile4() then return SetCursorAndTip(iCSelect, "SELECT 4") end;
  -- Mouse over exit area
  if MouseOverExit() then return SetCursorAndTip(iCExit, "CONTROLLER") end;
  -- Nothing selected, show subject
  SetCursorAndTip(iCArrow, "FILE");
end
-- Fade to lobby ----------------------------------------------------------- --
local function Finish()
  -- Play select sound
  PlayStaticSound(iSSelect);
  -- When faded out?
  local function OnFadeOut()
    -- Dereference assets for garbage collector
    texFile = nil;
    -- Load controller screen
    InitCon();
  end
  -- Fade out
  Fade(0, 1, 0.04, RenderFile, OnFadeOut);
end
-- Select files ------------------------------------------------------------ --
local function SelectFile1() Select(1) end;
local function SelectFile2() Select(2) end;
local function SelectFile3() Select(3) end;
local function SelectFile4() Select(4) end;
-- Delete file ------------------------------------------------------------- --
local function FileDelete()
  -- No id? Ignore
  if not iSelected or not aFileData[iSelected] then return end;
  -- Play sound
  PlayStaticSound(iSSelect);
  -- Write data
  aSaveSlot[iSelected]:Reset("");
  -- Set message
  sMsg = "FILE "..iSelected.." DELETED SUCCESSFULLY!";
  -- Commit CVars on the game engine to persistent storage
  VariableSave();
  -- Refresh data
  aFileData, aNameData = LoadSaveData();
end
-- Load file --------------------------------------------------------------- --
local function FileLoad()
  -- No id? Ignore
  if not iSelected or not aFileData[iSelected] then return end
  -- Play sound
  PlayStaticSound(iSSelect);
  -- Get data and if no data then ignore
  local Data<const> = aFileData[iSelected];
  -- Set variables
  aGlobalData.gTotalTimeTaken, aGlobalData.gSelectedRace,
  aGlobalData.gSelectedLevel,  aGlobalData.gZogsToWinGame,
  aGlobalData.gBankBalance,    aGlobalData.gPercentCompleted,
  aGlobalData.gCapitalCarried, aGlobalData.gNewGame,
  aGlobalData.gGameSaved,      aGlobalData.gTotalHomicides,
  aGlobalData.gTotalCapital,   aGlobalData.gTotalExploration,
  aGlobalData.gTotalDeaths,    aGlobalData.gTotalGemsSold,
  aGlobalData.gTotalGemsFound, aGlobalData.gTotalIncome,
  aGlobalData.gTotalDug,       aGlobalData.gTotalEnemyKills,
  aGlobalData.gTotalPurchases, aGlobalData.gLevelsCompleted =
    Data[2],                     Data[3],
    nil,                         17500,
    Data[4],                     floor(aGlobalData.gBankBalance/
                                       aGlobalData.gZogsToWinGame*100),
    Data[5],                     false,
    true,                        Data[6],
    Data[7],                     Data[8],
    Data[9],                     Data[10],
    Data[11],                    Data[12],
    Data[13],                    Data[14],
    Data[15],                    Data[16];
  -- Set success message
  sMsg = "FILE LOADED SUCCESSFULLY!";
end
-- Save file --------------------------------------------------------------- --
local function FileSave()
  -- No id or race? Ignore
  if not iSelected or
     not aGlobalData.gSelectedRace or
     aGlobalData.gNewGame then return end;
  -- Number of levels and levels completed
  local NL, LC = 0, "";
  -- For each level completed
  for I in pairs(aGlobalData.gLevelsCompleted) do
    if NL == 0 then LC = LC..I else LC = LC.." "..I end;
    NL = NL + 1;
  end
  -- Play sound
  PlayStaticSound(iSSelect);
  -- Write data
  aSaveSlot[iSelected]:Set(
    format("%u,%u,%u,%d,%d,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%s",
      CoreOSTime(), aGlobalData.gTotalTimeTaken,
      aGlobalData.gSelectedRace, aGlobalData.gBankBalance,
      aGlobalData.gCapitalCarried, aGlobalData.gTotalHomicides,
      aGlobalData.gTotalCapital, aGlobalData.gTotalExploration,
      aGlobalData.gTotalDeaths, aGlobalData.gTotalGemsSold,
      aGlobalData.gTotalGemsFound, aGlobalData.gTotalIncome,
      aGlobalData.gTotalDug, aGlobalData.gTotalEnemyKills,
      aGlobalData.gTotalPurchases, NL, LC));
  -- Set message
  sMsg = "FILE "..iSelected.." SAVED SUCCESSFULLY!";
  -- Can exit to title
  aGlobalData.gGameSaved = true;
  -- Commit CVars on the game engine to persistent storage
  VariableSave();
  -- Refresh data
  aFileData, aNameData = LoadSaveData();
end
-- File screen input logic ------------------------------------------------- --
local function FileInput()
  -- Mouse button not clicked? Return!
  if IsButtonReleased(0) then return;
  -- Load clicked and file selected?
  elseif MouseOverLoad() then FileLoad();
  -- Save clicked and file selected?
  elseif MouseOverSave() then FileSave();
  -- File 1 clicked?
  elseif MouseOverFile1() then SelectFile1();
  -- File 2 clicked?
  elseif MouseOverFile2() then SelectFile2();
  -- File 3 clicked?
  elseif MouseOverFile3() then SelectFile3();
  -- File 4 clicked?
  elseif MouseOverFile4() then SelectFile4();
  -- Exit clicked?
  elseif MouseOverExit() then Finish() end;
end
-- When file screen has faded in? ------------------------------------------ --
local function OnFadeIn()
  -- Set key bank
  SetKeys(true, iKeyBankId);
  -- Set controller callbacks
  SetCallbacks(FileLogic, RenderFile, FileInput);
end
-- When file assets have loaded? ------------------------------------------- --
local function OnLoaded(aResources)
  -- Set loaded texture resource and create tile for file screen
  texFile = aResources[1];
  tileFile = texFile:TileA(207, 0, 512, 200);
  -- Setup lobby texture
  texLobby = aResources[2];
  texLobby:TileSTC(1);
  texLobby:TileS(0, 0, 272, 428, 512);
  -- Display data
  aFileData, aNameData = LoadSaveData();
  -- Top message, selected file and bottom-right tip
  sMsg, iSelected, sTip = "SELECT FILE", nil, nil;
  -- Change render procedures
  Fade(1, 0, 0.04, RenderFile, OnFadeIn);
end
-- Init load/save screen function ------------------------------------------ --
local function InitFile() LoadResources("File", aAssets, OnLoaded) end;
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  Fade, InitCon, IsButtonReleased, IsMouseInBounds, IsMouseNotInBounds,
    LoadResources, PlayStaticSound, RenderShadow, SetBottomRightTipAndShadow,
    SetCallbacks, SetCursor, SetKeys, aLevelsData, aObjectData, aObjectTypes,
    aSaveSlot[1], aSaveSlot[2], aSaveSlot[3], aSaveSlot[4], fontSpeech,
    texSpr =
      GetAPI("Fade", "InitCon", "IsButtonReleased", "IsMouseInBounds",
        "IsMouseNotInBounds", "LoadResources", "PlayStaticSound",
        "RenderShadow", "SetBottomRightTipAndShadow", "SetCallbacks",
        "SetCursor", "SetKeys", "aLevelsData", "aObjectData", "aObjectTypes",
        "cvData1", "cvData2", "cvData3", "cvData4", "fontSpeech", "texSpr");
  -- Register keybinds
  local aKeys<const> = Input.KeyCodes;
  iKeyBankId = GetAPI("RegisterKeys")("ZMTC FILE", {
    [Input.States.PRESS] = {
      { aKeys.BACKSPACE, FileDelete, "zmtcfdsf", "DELETE SELECTED FILE" },
      { aKeys.L, FileLoad, "zmtcflsf", "LOAD SELECTED FILE" },
      { aKeys.S, FileSave, "zmtcfssf", "SAVE SELECTED FILE" },
      { aKeys.N1, SelectFile1, "zmtcfsfa", "SELECT 1ST FILE" },
      { aKeys.N2, SelectFile2, "zmtcfsfb", "SELECT 2ND FILE" },
      { aKeys.N3, SelectFile3, "zmtcfsfc", "SELECT 3RD FILE" },
      { aKeys.N4, SelectFile4, "zmtcfsfd", "SELECT 4TH FILE" },
      { aKeys.ESCAPE, Finish, "zmtcfc", "CANCEL" }
    }
  });
  -- Set sound effect ids
  local aSfxData<const> = GetAPI("aSfxData");
    iSClick, iSSelect = aSfxData.CLICK, aSfxData.SELECT;
  -- Set cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCOK, iCSelect, iCExit, iCArrow = aCursorIdData.OK, aCursorIdData.SELECT,
    aCursorIdData.EXIT, aCursorIdData.ARROW;
end
-- Exports and imports ----------------------------------------------------- --
return { F = OnReady, A = { InitFile = InitFile,
                            InitNewGame = InitNewGame,
                            LoadSaveData = LoadSaveData,
                            aGlobalData = aGlobalData } };
-- End-of-File ============================================================= --

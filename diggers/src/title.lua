-- TITLE.LUA =============================================================== --
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
local pairs<const>, random<const> = pairs, math.random;
-- M-Engine function aliases ----------------------------------------------- --
local CoreRAM<const>, DisplayVRAM<const>, UtilBytes<const>,
  VariableGetInt<const> = Core.RAM, Display.VRAM, Util.Bytes, Variable.GetInt;
-- Consts ------------------------------------------------------------------ --
local iCVAppTitle<const> = Variable.Internal.app_version;
local strVersion<const> = VariableGetInt(iCVAppTitle).." ";
-- Diggers function and data aliases --------------------------------------- --
local DeInitLevel, Fade, GameProc, GetActivePlayer, GetGameTicks,
  GetOpponentPlayer, InitLobby, InitNewGame, InitTitleCredits,
  IsButtonReleased, IsMouseInBounds, LoadLevel, LoadResources, LoadSaveData,
  PlayStaticSound, ProcessViewPort, RegisterFBUCallback, RenderObjects,
  RenderTerrain, SelectObject, SetCursor, aKeyBankCats, aLevelsData,
  aObjectTypes, aObjects, fontTiny;
-- Locals ------------------------------------------------------------------ --
local fcbEnterAnimProc,                -- Enter animation procedure
      fcbLeaveAnimProc,                -- Leave animation procedure
      fcbRC,                           -- System information update function
      iCArrow, iCExit, iCOK,           -- Cursor ids
      iKeyBankId,                      -- Title key bank id
      iNextUpdate,                     -- Next system information update
      iSSelect,                        -- Select sound id
      iStageL, iStageR,                -- Stage bounds
      texTitle,                        -- Texture tile
      strCredits,                      -- Credits
      strSubTitle;                     -- Version and system information text
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "title", P = { 0 } } };
-- Get engine information -------------------------------------------------- --
local sAppTitle, sAppVendor, iAppMajor<const>, iAppMinor<const>,
  iAppBuild<const>, iAppRevision<const>, _, _, sAppExeType = Core.Engine();
sAppTitle, sAppVendor, sAppExeType =
  sAppTitle:upper(), sAppVendor:upper(), sAppExeType:upper();
-- Render in procedure ----------------------------------------------------- --
local function RenderEnterAnimProc()
  -- Scroll in amount
  local n1, n2 = 160, 168;
  -- Initial animation procedure
  local function RenderAnimProcInitial()
    -- Render terrain and game objects
    RenderTerrain();
    RenderObjects();
    -- Render title objects
    texTitle:BlitLT(79, 12 - n1);
    texTitle:BlitSLT(1, iStageL - n1, 72);
    texTitle:BlitSLT(2, (iStageR - 168) + n2, 72);
    -- Render status text
    fontTiny:SetCRGB(1, 0.9, 0);
    fontTiny:PrintC(160, 58 - n1, strSubTitle);
    fontTiny:PrintC(160, 206 + n1, strCredits);
    -- Move components in
    n1 = n1 - (n1 * 0.1);
    n2 = n2 - (n2 * 0.1);
    if n1 >= 1 and n2 >= 1 then return end;
    -- Animation completed
    local function RenderAnimProcFinished()
      -- Render terrain and game objects
      RenderTerrain();
      RenderObjects();
      -- Render title objects
      texTitle:BlitLT(79, 12);
      texTitle:BlitSLT(1, iStageL, 72);
      texTitle:BlitSLT(2, iStageR - 168, 72);
      -- Render status text
      fontTiny:SetCRGB(1, 0.9, 0);
      fontTiny:PrintC(160, 58, strSubTitle);
      fontTiny:PrintC(160, 206, strCredits);
    end
    -- Set finished callback and execute it
    fcbEnterAnimProc = RenderAnimProcFinished;
    fcbEnterAnimProc();
  end
  -- Set initial animation procedure end execute it
  fcbEnterAnimProc = RenderAnimProcInitial;
  fcbEnterAnimProc();
end
-- Render fade out procedure ----------------------------------------------- --
local function RenderLeaveAnimProc()
  -- Scroll in amount
  local n1, n2 = 160, 168;
  -- Initial animation procedure
  local function RenderAnimProcInitial()
    -- Render terrain and game objects
    RenderTerrain();
    RenderObjects();
    -- Render title objects
    texTitle:BlitLT(79, -148 + n1);
    texTitle:BlitSLT(1, iStageL - 168 + n1, 72);
    texTitle:BlitSLT(2, iStageR - n2, 72);
    -- Render status text
    fontTiny:SetCRGB(1, 0.9, 0);
    fontTiny:PrintC(160, 58 - n1, strSubTitle);
    fontTiny:PrintC(160, 370 - n1, strCredits);
    -- Move components in
    n1 = n1 - (n1 * 0.05);
    n2 = n2 - (n2 * 0.05);
    if n1 >= 1 and n2 >= 1 then return end;
    -- Animation completed
    local function RenderAnimProcFinished()
      -- Render terrain and game objects
      RenderTerrain();
      RenderObjects();
    end
    -- Set finished callback and execute it
    fcbLeaveAnimProc = RenderAnimProcFinished;
    fcbLeaveAnimProc();
  end
  -- Set initial animation procedure end execute it
  fcbLeaveAnimProc = RenderAnimProcInitial;
  fcbLeaveAnimProc();
end
-- Render fade out procedure ----------------------------------------------- --
local function RenderLeaveProc() fcbLeaveAnimProc() end;
-- When faded out to start game -------------------------------------------- --
local function OnFadeToLobby()
  -- Remove frame buffer update callback
  RegisterFBUCallback("title");
  -- De-init level
  DeInitLevel();
  -- Dereference loaded assets for garbage collector
  texTitle = nil;
  -- Reset game parameters
  InitNewGame();
  -- Load closed lobby
  InitLobby();
end
-- Fade out to start game -------------------------------------------------- --
local function GoFadeToLobby()
  -- Play sound
  PlayStaticSound(iSSelect);
  -- Start fading out
  Fade(0, 1, 0.04, RenderLeaveProc, OnFadeToLobby, true);
end
-- Fade out to quit -------------------------------------------------------- --
local function FinishQuit()
  -- Play sound
  PlayStaticSound(iSSelect);
  -- When faded out to quit
  local function OnFadeOutQuit() Core.Quit(0) end;
  -- Fade to black then quit
  return Fade(0, 1, 0.04, RenderLeaveProc, OnFadeOutQuit, true);
end
-- When demo level faded out? ---------------------------------------------- --
local function OnFadeToCredits()
  -- Remove frame buffer update callback
  RegisterFBUCallback("title");
  -- De-init level
  DeInitLevel();
  -- Done with the texture here
  texTitle = nil;
  -- Init title screen credits without music
  InitTitleCredits(true);
end
-- When demo level as loaded? ---------------------------------------------- --
local function ProcLogic()
  -- Process game functions
  GameProc();
  -- Process viewport scrolling
  ProcessViewPort();
  -- Refresh system information every second
  if GetGameTicks() % 60 == 59 then fcbRC() end;
  -- Select a random digger on the first tick
  if GetGameTicks() % 600 == 599 then
    -- Set next RAM update time
    iNextUpdate = GetGameTicks() + 60;
    -- Find a digger from the opposing player
    local aPlayer;
    if random() >= 0.5 then aPlayer = GetOpponentPlayer();
                       else aPlayer = GetActivePlayer() end;
    local aObject = aPlayer.D[random(#aPlayer.D)];
    -- Still not found? Find a random object
    if not aObject then aObject = aObjects[random(#aObjects)] end;
    -- Select the object if we got something!
    if aObject then SelectObject(aObject) end;
  end
  -- Return if it is not time to show the credits
  if GetGameTicks() % 1500 < 1499 then return end;
  -- Fade out to credits
  Fade(0, 1, 0.04, RenderLeaveProc, OnFadeToCredits);
end
-- Render function --------------------------------------------------------- --
local function ProcRender() fcbEnterAnimProc() end;
-- Input function ---------------------------------------------------------- --
local function ProcInput()
  -- Mouse over quit button?
  if IsMouseInBounds(iStageL + 54, 152, iStageL + 122, 181) then
    -- Show exit button
    SetCursor(iCExit);
    -- Ignore if not clicked
    if IsButtonReleased(0) then return end;
    -- Do quit
    return FinishQuit();
  end
  -- Mouse over start button?
  if IsMouseInBounds(iStageR - 123, 137, iStageR - 37, 183) then
    -- Show ok button
    SetCursor(iCOK);
    -- Return if not clicked
    if IsButtonReleased(0) then return end;
    -- Start the game
    return GoFadeToLobby();
  end
  -- Show arrow
  SetCursor(iCArrow);
end
-- Detect VRAM and update subtitle ----------------------------------------- --
local function DetectVRAM()
  -- Setup VRAM update function and no VRAM available?
  local _, _, nVFree<const> = DisplayVRAM();
  if nVFree == -1 then
    -- No VRAM callback
    local function NoVRAM()
      -- Get and display only RAM
      local _, _, nFree<const> = CoreRAM();
      strSubTitle = strVersion..UtilBytes(nFree, 1).." RAM FREE";
    end
    -- Set NO VRAM available callback
    fcbRC = NoVRAM;
  -- VRAM is available?
  else
    -- VRAM available callback
    local function VRAM()
      -- Get VRAM available and if is shared memory?
      local _, _, nVFree<const>, _, bIsShared<const> = DisplayVRAM();
      if bIsShared then
        strSubTitle = strVersion..UtilBytes(nVFree, 1).. "(S+V) FREE";
      -- Is dedicated memory?
      else
        -- Get free main memory
        local _, _, nFree<const> = CoreRAM();
        -- If both the same the memory is shared
        strSubTitle = strVersion..UtilBytes(nFree, 1).."(S)/"..
                                  UtilBytes(nVFree, 1).. "(V) FREE";
      end
    end
    -- Set VRAM available callback
    fcbRC = VRAM;
  end
  -- Update subtitle
  fcbRC();
end
-- Framebuffer changed callback -------------------------------------------- --
local function OnFrameBufferUpdated(...)
  -- Update stage bounds
  local _ _, _, iStageL, _, iStageR, _ = ...;
  -- Re-detect video RAM
  DetectVRAM();
end
-- Main demo level loader -------------------------------------------------- --
local function LoadDemoLevel(strTitle)
  -- Setup frame buffer updated callback
  RegisterFBUCallback("title", OnFrameBufferUpdated);
  -- Set initial enter function
  fcbEnterAnimProc, fcbLeaveAnimProc =
    RenderEnterAnimProc, RenderLeaveAnimProc;
  -- Next update time
  iNextUpdate = GetGameTicks();
  -- Levels completed
  local aZones<const> = { };
  -- Build array of all the completed levels from every save slot
  for iSlotId, aSlotData in pairs(LoadSaveData()) do
    for iZoneId in pairs(aSlotData[16]) do
      aZones[1 + #aZones] = iZoneId end;
  end
  -- If zero or one zone completed then allow showing the first two zones
  if #aZones <= 1 then aZones[1], aZones[2] = 1, 2 end;
  -- Load AI vs AI and use random zone
  LoadLevel(aZones[random(#aZones)], strTitle, iKeyBankId,
    aObjectTypes.DIGRANDOM, true, aObjectTypes.DIGRANDOM, true,
    ProcLogic, ProcRender, ProcInput);
end
-- Resources are ready? ---------------------------------------------------- --
local function OnTitleLoaded(aResources, bNoMusic)
  -- Initialise title texture
  texTitle = aResources[1];
  texTitle:SetCRGBA(1, 1, 1, 1);
  texTitle:TileSTC(1);
  texTitle:TileS(0,   0, 240, 162, 281);
  texTitle:TileA(     0, 344, 150, 512);
  texTitle:TileA(   344, 344, 512, 512);
  -- Initialise credits
  strCredits = "ORIGINAL VERSIONS BY TOBY SIMPSON AND MIKE FROGGATT\n\z
   (C) 1994 MILLENNIUM INTERACTIVE LTD. ALL RIGHTS RESERVED\n\rcffffff4f\z
   POWERED BY "..sAppTitle.." (C) 2024 "..sAppVendor..". \z
     ALL RIGHTS RESERVED\n\z
   PRESS "..aKeyBankCats.gksc[9].." TO SETUP, "..
     aKeyBankCats.gksb[9].." TO SET KEYS OR "..
     aKeyBankCats.gksa[9].." TO SEE ACKNOWLEDGEMENTS AT ANY TIME";
  -- Load demonstration level without or with title music
  if bNoMusic then LoadDemoLevel() else LoadDemoLevel("title") end;
end
-- Initialise the title screen function ------------------------------------ --
local function InitTitle(bNoMusic)
  LoadResources("Title Screen", aAssets, OnTitleLoaded, bNoMusic);
end
-- Script ready function --------------------------------------------------- --
local function OnReady(GetAPI)
  -- Get imports
  DeInitLevel, Fade, GameProc, GetActivePlayer, GetGameTicks,
    GetOpponentPlayer, InitLobby, InitNewGame, InitTitleCredits,
    IsButtonReleased, IsMouseInBounds, LoadLevel, LoadResources, LoadSaveData,
    PlayStaticSound, ProcessViewPort, RegisterFBUCallback, RenderObjects,
    RenderTerrain, SelectObject, SetCursor, aKeyBankCats, aLevelsData,
    aObjectTypes, aObjects, fontTiny =
      GetAPI("DeInitLevel", "Fade", "GameProc", "GetActivePlayer",
        "GetGameTicks", "GetOpponentPlayer", "InitLobby", "InitNewGame",
        "InitTitleCredits", "IsButtonReleased", "IsMouseInBounds", "LoadLevel",
        "LoadResources", "LoadSaveData", "PlayStaticSound", "ProcessViewPort",
        "RegisterFBUCallback", "RenderObjects", "RenderTerrain",
        "SelectObject", "SetCursor", "aKeyBankCats", "aLevelsData",
        "aObjectTypes", "aObjects", "fontTiny");
  -- Register keybinds
  local aKeys<const> = Input.KeyCodes;
  iKeyBankId = GetAPI("RegisterKeys")("TITLE SCREEN", {
    [Input.States.PRESS] = {
      { aKeys.ENTER, GoFadeToLobby, "tsst", "START GAME" },
      { aKeys.ESCAPE, FinishQuit, "tsqg", "QUIT GAME" }
    }
  });
  -- Get sound effect ids
  iSSelect = GetAPI("aSfxData").SELECT;
  -- Get cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCArrow, iCExit, iCOK =
    aCursorIdData.ARROW, aCursorIdData.EXIT, aCursorIdData.OK;
end
-- Return imports and exports ---------------------------------------------- --
return { A = { InitTitle = InitTitle }, F = OnReady };
-- End-of-File ============================================================= --

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
  GetOpponentPlayer, InitLobby, InitNewGame, IsButtonReleased, IsKeyReleased,
  IsMouseInBounds, LoadLevel, LoadResources, LoadSaveData, PlayStaticSound,
  ProcessViewPort, RegisterFBUCallback, RenderObjects, RenderTerrain,
  SelectObject, SetCallbacks, SetCursor, aCreditsData, aCursorIdData,
  aLevelsData, aObjectTypes, aObjects, aSfxData, fontLarge, fontLittle,
  fontTiny;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "title", P = { 0 } } };
-- Initialise the title screen function ------------------------------------ --
local function InitTitle()
  -- When title resources have loaded?
  local function OnTitleLoaded(aResources)
    -- Stage bounds
    local iStageL, iStageR;
    -- Load texture and credit tiles
    local texTitle = aResources[1].H;
    texTitle:SetCRGBA(1, 1, 1, 1);
    texTitle:TileSTC(1);
    texTitle:TileA(  0, 240, 162, 281);
    texTitle:TileA(  0, 344, 150, 512);
    texTitle:TileA(344, 344, 512, 512);
    local tileCredits<const> = texTitle:TileA(0, 0, 512, 240);
    -- Set version
    local strSubTitle;
    -- Set credits
    local strCredits<const> =
      "ORIGINAL VERSIONS BY TOBY SIMPSON AND MIKE FROGGATT\n\z
       (C) 1994 MILLENNIUM INTERACTIVE LTD. ALL RIGHTS RESERVED\n\rcffffff4f\z
       POWERED BY MHATXOTIC ENGINE (C) 2024 MHATXOTIC DESIGN.\z
         ALL RIGHTS RESERVED\n\z
       PRESS F1 TO SETUP THE ENGINE OR F2 FOR ACKNOWLEDGEMENTS AT ANY TIME";
    -- Main demo level loader
    local function LoadDemoLevel(strMusic);
      -- Setup frame buffer updated callback
      local function OnFrameBufferUpdated(...)
        local _ _, _, iStageL, _, iStageR, _ = ...;
      end
      RegisterFBUCallback("title", OnFrameBufferUpdated);
      -- Render in procedure
      local function RenderEnterAnimProc()
        -- Scroll in amount
        local n1, n2 = 160, 168;
        -- Initial animation procedure
        local function RenderAnimProcInitial()
          -- Render terrain and game objects
          RenderTerrain();
          RenderObjects();
          -- Render title objects
          texTitle:BlitSLT(1, 79, 12 - n1);
          texTitle:BlitSLT(2, iStageL - n1, 72);
          texTitle:BlitSLT(3, (iStageR - 168) + n2, 72);
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
            texTitle:BlitSLT(1, 79, 12);
            texTitle:BlitSLT(2, iStageL, 72);
            texTitle:BlitSLT(3, iStageR - 168, 72);
            -- Render status text
            fontTiny:SetCRGB(1, 0.9, 0);
            fontTiny:PrintC(160, 58, strSubTitle);
            fontTiny:PrintC(160, 206, strCredits);
          end
          -- Set finished callback and execute it
          RenderEnterAnimProc = RenderAnimProcFinished;
          RenderEnterAnimProc();
        end
        -- Set initial animation procedure end execute it
        RenderEnterAnimProc = RenderAnimProcInitial;
        RenderEnterAnimProc();
      end
      -- Render fade out procedure
      local function RenderLeaveAnimProc()
        -- Scroll in amount
        local n1, n2 = 160, 168;
        -- Initial animation procedure
        local function RenderAnimProcInitial()
          -- Render terrain and game objects
          RenderTerrain();
          RenderObjects();
          -- Render title objects
          texTitle:BlitSLT(1, 79, -148 + n1);
          texTitle:BlitSLT(2, iStageL - 168 + n1, 72);
          texTitle:BlitSLT(3, iStageR - n2, 72);
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
          RenderLeaveAnimProc = RenderAnimProcFinished;
          RenderLeaveAnimProc();
        end
        -- Set initial animation procedure end execute it
        RenderLeaveAnimProc = RenderAnimProcInitial;
        RenderLeaveAnimProc();
      end
      -- Render fade out procedure
      local function RenderLeaveProc() RenderLeaveAnimProc() end;
      -- Next update time
      local iNextUpdate = GetGameTicks();
      -- Setup VRAM update function
      local fcbRC, _, nVFree<const> = DisplayVRAM();
      if nVFree == -1 then
        -- No VRAM callback
        local function NoVRAM()
          -- Get and display only RAM
          local _, _, nFree<const> = CoreRAM();
          strSubTitle = strVersion..UtilBytes(nFree, 1).." RAM FREE";
        end
        -- Set NO VRAM available callback
        fcbRC = NoVRAM;
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
      -- Set subtitle
      fcbRC();
      -- When demo level as loaded?
      local function DemoLevelProc()
        -- Process game functions
        GameProc();
        -- Process viewport scrolling
        ProcessViewPort();
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
        -- When demo level faded out?
        local function OnDemoLevelFadeOut()
          -- Remove frame buffer update callback
          RegisterFBUCallback("title");
          -- De-init level
          DeInitLevel();
          -- Credits counter and texts
          local iCreditsCounter, iCreditsNext = 0, 0;
          local strCredits1, iCredits1Y;
          local strCredits2, iCredits2Y;
          -- Set new credit function
          local iCreditId;
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
          SetCredit(1);
          -- Render credits proc
          local function RenderCredits()
            -- Set text colour
            fontLittle:SetCRGB(1, 0.7, 1);
            fontLarge:SetCRGB(1, 1, 1);
            -- Draw background
            texTitle:BlitSLT(tileCredits, -96, 0);
            -- Display text compared to amount of time passed
            fontLittle:PrintC(160, iCredits1Y, strCredits1);
            fontLarge:PrintC(160, iCredits2Y, strCredits2);
          end
          -- When credits have faded in?
          local function OnRenderCreditsFadeIn()
            -- Credits main logic
            local function CreditsLogic()
              -- Increment counter and if ignore if counter not exceeded
              iCreditsCounter = iCreditsCounter + 1;
              if iCreditsCounter < iCreditsNext then return end;
              -- Set next credit and return if succeeded
              if SetCredit(iCreditId + 1) then return end;
              -- Fade out to credits and load demo level
              Fade(0, 1, 0.04, RenderCredits, LoadDemoLevel);
            end
            -- Get code for ESCAPE so user can leave the screen
            local aKeys<const> = Input.KeyCodes;
            local iKeyEscape<const> = aKeys.ESCAPE
            -- Credits input logic
            local function CreditsInput()
              -- Ignore if no button or escape not pressed
              if IsButtonReleased(0) and
                 IsKeyReleased(iKeyEscape) then return end;
              -- Fade out to credits and load demo level
              Fade(0, 1, 0.04, RenderCredits, LoadDemoLevel);
            end
            -- Set credits callback
            SetCallbacks(CreditsLogic, RenderCredits, CreditsInput);
          end
          -- Fade in
          Fade(1, 0, 0.04, RenderCredits, OnRenderCreditsFadeIn);
        end
        -- Fade out to credits
        Fade(0, 1, 0.04, RenderLeaveProc, OnDemoLevelFadeOut);
      end
      -- Render function
      local function DemoLevelRender() RenderEnterAnimProc() end;
      -- Input function
      local function DemoLevelInput()
        -- Mouse over quit button?
        if IsMouseInBounds(iStageL + 54, 152, iStageL + 122, 181) then
          -- Show exit button
          SetCursor(aCursorIdData.EXIT);
          -- Ignore if not clicked
          if IsButtonReleased(0) then return end;
          -- Play sound
          PlayStaticSound(aSfxData.SELECT);
          -- When faded out to quit
          local function OnFadeOutQuit() Core.Quit(0) end;
          -- Fade to black then quit
          return Fade(0, 1, 0.04, RenderLeaveProc, OnFadeOutQuit, true);
        end
        -- Mouse over start button?
        if IsMouseInBounds(iStageR - 123, 137, iStageR - 37, 183) then
          -- Show ok button
          SetCursor(aCursorIdData.OK);
          -- Return if not clicked
          if IsButtonReleased(0) then return end;
          -- Play sound
          PlayStaticSound(aSfxData.SELECT);
          -- When faded out to start game
          local function OnFadeOutStart()
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
          -- Start fading out
          return Fade(0, 1, 0.04, RenderLeaveProc, OnFadeOutStart, true);
        end
        -- Show arrow
        SetCursor(aCursorIdData.ARROW);
      end
      -- Levels completed
      local aZones = { };
      -- Build array of all the completed levels from every save slot
      for iSlotId, aSlotData in pairs(LoadSaveData()) do
        for iZoneId in pairs(aSlotData[16]) do
          aZones[1 + #aZones] = iZoneId end;
      end
      -- If zero or one zone completed then allow showing the first two zones
      if #aZones <= 1 then aZones[1], aZones[2] = 1, 2 end;
      -- Load AI vs AI and use random zone
      LoadLevel(aZones[random(#aZones)], strMusic, aObjectTypes.DIGRANDOM,
        true, aObjectTypes.DIGRANDOM, true, DemoLevelProc, DemoLevelRender,
        DemoLevelInput);
    end
    -- Load demonstration level with title music
    LoadDemoLevel("title");
  end
  -- Load title screen resource
  LoadResources("Title Screen", aAssets, OnTitleLoaded);
end
-- Return imports and exports ---------------------------------------------- --
return { A = { InitTitle = InitTitle }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  LoadResources, SetCallbacks, SetCursor, aLevelsData, aObjectTypes, LoadLevel,
  IsMouseInBounds, aCursorIdData, aSfxData, IsButtonReleased, PlayStaticSound,
  Fade, aCreditsData, IsKeyReleased, InitLobby, DeInitLevel, InitNewGame,
  fontTiny, fontLittle, fontLarge, GetGameTicks, RenderTerrain, RenderObjects,
  SelectObject, GameProc, RegisterFBUCallback, aObjects, GetActivePlayer,
  GetOpponentPlayer, LoadSaveData, ProcessViewPort
  = -- --------------------------------------------------------------------- --
  GetAPI("LoadResources", "SetCallbacks", "SetCursor", "aLevelsData",
    "aObjectTypes", "LoadLevel", "IsMouseInBounds", "aCursorIdData", "aSfxData",
    "IsButtonReleased", "PlayStaticSound", "Fade", "aCreditsData",
    "IsKeyReleased", "InitLobby", "DeInitLevel", "InitNewGame", "fontTiny",
    "fontLittle", "fontLarge", "GetGameTicks", "RenderTerrain",
    "RenderObjects", "SelectObject", "GameProc", "RegisterFBUCallback",
    "aObjects", "GetActivePlayer", "GetOpponentPlayer", "LoadSaveData",
    "ProcessViewPort");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

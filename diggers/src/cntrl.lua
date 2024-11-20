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
local Fade, InitBook, InitFile, InitLobby, InitMap, InitRace, IsButtonReleased,
  IsMouseInBounds, IsMouseNotInBounds, IsMouseNotInBounds, LoadResources,
  PlayStaticSound, RenderShadow, SetBottomRightTipAndShadow, SetCallbacks,
  SetCursor, aCursorIdData, aGlobalData, aSfxData, fontSpeech;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "lobbyc", P = { 0 } },
                         { T = 2, F = "cntrl",  P = { 0 } } };
-- Init controller screen function ----------------------------------------- --
local function InitCon()
  -- When controller resources have loaded?
  local function OnLoaded(aResources)
    -- Setup lobby texture
    local texLobby = aResources[1].H;
    texLobby:TileSTC(1);
    texLobby:TileS(0, 0, 272, 428, 512);
    -- Setup controller texture
    local texCon = aResources[2].H;
    local tileConAnim<const> = texCon:TileA(0,   0, 160,  84);
                               texCon:TileA(0,  85, 160, 169);
                               texCon:TileA(0, 170, 160, 254);
                               texCon:TileA(0, 255, 160, 339);
    -- Cache other tiles
    local tileCon<const>    = texCon:TileA(208, 312, 512, 512); -- [0](1)
    local tileSpeech<const> = texCon:TileA(356, 250, 512, 274); -- [0](1)
    local tileFish<const>   = texCon:TileA(273, 275, 320, 311); -- [0](5)
                              texCon:TileA(321, 275, 368, 311); -- [1]
                              texCon:TileA(369, 275, 416, 311); -- [2]
                              texCon:TileA(417, 275, 464, 311); -- [3]
                              texCon:TileA(465, 275, 512, 311); -- [4]
    local tileMap<const>    = texCon:TileA(  0, 412,  63, 453); -- [0](2)
                              texCon:TileA( 64, 412, 127, 453); -- [1]
    local tileRace<const>   = texCon:TileA(128, 409, 160, 453); -- [0](2)
                              texCon:TileA(161, 409, 193, 453); -- [1]
    local tileBook<const>   = texCon:TileA(  0, 454,  79, 485); -- [0](2)
                              texCon:TileA( 80, 454, 159, 485); -- [1]
    local tileFile<const>   = texCon:TileA(  0, 486,  95, 512); -- [0](2)
                              texCon:TileA( 96, 486, 191, 512); -- [1]
    -- Data for flashing textures to help the player know what to do
    local aFlashCache<const> = {
      [tileMap]  = { tileMap,  9,   9 }, [tileRace] = { tileRace, 232, 160 },
      [tileBook] = { tileBook, 9, 176 }, [tileFile] = { tileFile,  73, 181 },
    };
    -- Set empty tip and speech timer
    local sTip, iSpeechTimer, sMsg, aFlashData, aSpeechList, iSpeechListCount,
      iSpeechListLoop, iSpeechIndex, iLastHotpoint =
        "", 0, nil, nil, { }, 60, 0, 0, 0;
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
    -- Render callback
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
    -- When controller screen has faded in?
    local function OnFadeIn()
      -- Mouse over events
      local function MouseOverMap()
        return IsMouseInBounds(9, 9, 57, 52) end;
      local function MouseOverBook()
        return IsMouseInBounds(9, 176, 76, 207) end;
      local function MouseOverFile()
        return IsMouseInBounds(76, 182, 163, 207) end;
      local function MouseOverRace()
        return aGlobalData.gNewGame and
          IsMouseInBounds(242, 160, 261, 283) end;
      local function MouseOverExit()
        return IsMouseNotInBounds(8, 8, 312, 208) end;
      -- Always return true function
      local function AlwaysTrue() return true end;
      -- Controller screen input lookup table
      local aMouseOverEvents<const> = {
        { MouseOverMap,  "SELECT ZONE", "SELECT", InitMap,   { }           },
        { MouseOverRace, "SELECT RACE", "SELECT", InitRace,  { }           },
        { MouseOverFile, "LOAD/SAVE",   "SELECT", InitFile,  { }           },
        { MouseOverBook, "THE BOOK",    "SELECT", InitBook,  { false }     },
        { MouseOverExit, "GO TO LOBBY", "EXIT",   InitLobby, { nil, true } },
        { AlwaysTrue,    "CONTROLLER",  "ARROW",  nil,       { }           },
      };
      -- Controller logic
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
            SetCursor(aCursorIdData[aMouseOverEvent[3]]);
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
      -- Controller screen input procedure
      local function ControllerInput()
        -- Mouse button not clicked? Return!
        if IsButtonReleased(0) then return end;
        -- Process mouse over items
        for iI = 1, #aMouseOverEvents do
          -- Get mouse over event item and if mouse over condition is true
          local aMouseOverEvent<const> = aMouseOverEvents[iI];
          if aMouseOverEvent[1]() then
            -- Get fade out function and if set?
            local fcbOnFadeOut<const> = aMouseOverEvent[4];
            if fcbOnFadeOut then
              -- Play select sound
              PlayStaticSound(aSfxData.SELECT);
              -- Transition helper
              local function OnFadeOut()
                -- Dereference assets for garbage collection
                texLobby, texCon = nil, nil;
                -- Do next procedure
                fcbOnFadeOut(unpack(aMouseOverEvent[5]));
              end
              -- Fade out to requested loading procedure
              return Fade(0, 1, 0.04, RenderCon, OnFadeOut);
            end
            -- No need to check anything else
            break;
          end
        end
      end
      -- Set controller callbacks
      SetCallbacks(ControllerLogic, RenderCon, ControllerInput);
    end
    -- Change render procedures
    Fade(1, 0, 0.04, RenderCon, OnFadeIn);
  end
  -- Load resources
  LoadResources("Controller", aAssets, OnLoaded);
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitCon = InitCon }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  Fade, InitBook, InitFile, InitLobby, InitMap, InitRace, IsButtonReleased,
  IsMouseInBounds, IsMouseNotInBounds, LoadResources, PlayStaticSound,
  RenderShadow, SetBottomRightTipAndShadow, SetCallbacks, SetCursor,
  aCursorIdData, aGlobalData, aSfxData, fontSpeech
  = -- --------------------------------------------------------------------- --
  GetAPI("Fade", "InitBook", "InitFile", "InitLobby", "InitMap", "InitRace",
    "IsButtonReleased", "IsMouseInBounds", "IsMouseNotInBounds",
    "LoadResources", "PlayStaticSound", "RenderShadow",
    "SetBottomRightTipAndShadow", "SetCallbacks", "SetCursor", "aCursorIdData",
    "aGlobalData", "aSfxData", "fontSpeech");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

-- CREDITS.LUA ============================================================= --
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
local random<const>, remove<const> = math.random, table.remove;
-- Diggers function and data aliases --------------------------------------- --
local DeInitLevel, Fade, GameProc, GetMusic, InitScore, LoadLevel,
  LoadResources, LockViewPort, PlayMusic, ProcessViewPort, RegisterFBUCallback,
  RenderObjects, RenderTerrain, SelectObject, SetCallbacks, SetCursor,
  aCreditsData, aCreditsXData, aCursorIdData, aEndLoadData, aLevelTypesData,
  aLevelsData, aObjectTypes, aObjects, aPlayers, fontLarge, fontLittle;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "vignette", P = { 0 } } };
local aEndLevelData<const> = { n = "END", f = "end", t = false };
-- Init ending screen functions -------------------------------------------- --
local function InitCredits(bRolling)
  -- When assets have loaded
  local function OnLoaded(aResources)
    -- Set vignette texture
    local texVig = aResources[1].H;
    -- Register frame buffer update
    local iStageW, iStageH, iStageL, iStageT, iStageR, iStageB, iStageM;
    local function OnFrameBufferUpdate(...)
      -- Get new stage values
      iStageW, iStageH, iStageL, iStageT, iStageR, iStageB = ...;
      -- Set middle of stage
      iStageM = iStageL + (iStageW / 2);
    end
    RegisterFBUCallback("credits", OnFrameBufferUpdate);
    -- Build levels to pick from
    local aLevels<const> = { };
    for iI = 1, #aLevelsData do aLevels[1 + #aLevels] = iI end;
    -- Init rolling credits
    local function InitRollingCredits(strMusic)
      -- Credit data and current absolute position on-screen
      local aXCredits<const>, iYEnd = { }, 0;
      -- Enumerate through all extra credits
      for iIndex = 1, #aCreditsXData do
        -- Get credit title and name
        local aCredit<const> = aCreditsXData[iIndex];
        -- Simulate print of title string and return height
        local nHeight1<const> = fontLittle:PrintWS(iStageW, 0, aCredit[1]);
        -- Calculate absolute bottom pixel of title text on screen
        local iYEndPnHeight1<const> = iYEnd + nHeight1;
        -- Simulate print of name string and return height
        local nHeight2<const> = fontLarge:PrintWS(iStageW, 0, aCredit[2]);
        -- calculate absolute bottom pixel of name text on screen
        local iYEndPnHeight1PnHeight2<const> = iYEndPnHeight1 + nHeight2;
        -- Build credit data
        aXCredits[1 + #aXCredits] = {
          iYEnd,                        -- [1] Top of title
          iYEndPnHeight1 + 4,           -- [2] Top of name
          iYEndPnHeight1PnHeight2 + 16, -- [3] Bottom of name
          aCredit[1],                   -- [4] Credit title
          aCredit[2]                    -- [5] Credit name
        };
        -- Move Y pointer down
        iYEnd = iYEndPnHeight1PnHeight2 + 20;
      end
      -- Current absolute Y position of all credits starting at the bottom
      local iY = iStageB;
      -- Render rolling credits function
      local function RenderExtra()
        -- Render terrain and objects
        RenderTerrain();
        RenderObjects();
        -- Render vignette
        texVig:BlitLTRB(iStageL, iStageT, iStageR, iStageB);
        -- Prepare font colours
        fontLarge:SetCRGBA(1, 1, 1, 1);
        fontLittle:SetCRGBA(0, 1, 0, 1);
        -- Enumerate remaining credits
        local iI = 1;
        while iI <= #aXCredits do
          -- Get credit data
          local aCredit<const> = aXCredits[iI];
          -- Get top of title credit
          local iTop<const> = iY + aCredit[1];
          -- Get bottom of name credit
          local iBottom<const> = iY + aCredit[3];
          -- If bottom of credit is off the top of the screen?
          if iBottom < iStageT then
            -- Remove the credit and if there are no more remaining?
            remove(aXCredits, iI);
            if #aXCredits == 0 then
              -- When faded out to title?
              local function OnFadeOutScore()
                -- De-init the level data
                DeInitLevel();
                -- Dereference assets to garbage collector
                texVig = nil;
                -- Remove frame buffer update
                RegisterFBUCallback("credits");
                -- Initialise score screen
                InitScore();
              end
              -- Fade to title
              return Fade(0, 1, 0.0025, RenderExtra, OnFadeOutScore, true);
            end
          -- Top of credit is showing from the bottom of the screen?
          elseif iTop < iStageB then
            -- Get top of name credit
            local iMiddle<const> = iY + aCredit[2];
            -- Draw credit title if below the top of the screen
            if iMiddle > iStageT then
              fontLittle:PrintC(iStageM, iTop, aCredit[4]);
            end
            -- Draw credit name if above the bottom of the screen
            if iMiddle < iStageB then
              fontLarge:PrintC(iStageM, iMiddle, aCredit[5]);
            end
            -- Process next credit
            iI = iI + 1;
          -- No need to process more if name credit is off the bottom
          elseif iBottom >= iStageB then break end;
        end
      end
      -- Credits procedure
      local function ExtraProc()
        -- Process game functions
        GameProc();
        -- Scroll up credits
        iY = iY - 0.25;
        -- Keep viewport in top left
        LockViewPort();
      end
      -- Credits input procedure
      local function ExtraInput() end
      -- When faded out to title? Load demo level
      LoadLevel(aEndLevelData, strMusic, nil,
        true, aObjectTypes.DIGRANDOM, true, ExtraProc, RenderExtra,
        ExtraInput);
    end
    -- Load demo levels
    local function LoadDemoLevel(iCreditId, strMusic)
      -- Action timer
      local iActionTimer = 0;
      -- Get a random level to load
      local iLevelIdPicked<const> = random(#aLevels);
      local iLevelId<const> = aLevels[iLevelIdPicked];
      remove(aLevels, iLevelIdPicked);
      -- Record if this is the last credit
      local bLast<const> = iCreditId >= #aCreditsData or #aLevels == 0;
      -- Get credit and try next credit if invalid
      local aCredit<const> = aCreditsData[iCreditId];
      if not aCredit then return LoadDemoLevel(iLevelId, iCreditId + 1) end;
      -- Get texts
      local strCredits1<const>, strCredits2<const> = aCredit[1], aCredit[2];
      -- Now we need to measure the height of all three strings so we
      -- can place the credits in the exact vertical centre of the screen
      local iCredits1H<const> = fontLittle:PrintWS(iStageW, 0, strCredits1);
      local iCredits2H<const> = fontLarge:PrintWS(iStageW, 0, strCredits2);
      local iCredits2Y<const> = 228 - iCredits2H;
      local iCredits1Y<const> = iCredits2Y - 4 - iCredits1H;
      -- Main render function
      local function RenderCredits()
        -- Render terrain and objects
        RenderTerrain();
        RenderObjects();
        -- Render vignette
        texVig:BlitLTRB(iStageL, iStageT, iStageR, iStageB);
        -- Prepare font colours
        fontLarge:SetCRGBA(1, 1, 1, 1);
        fontLittle:SetCRGBA(0, 1, 0, 1);
      end
      -- Render function
      local function RenderCreditsBottomLeft()
        -- Render terrain, objects and vignette
        RenderCredits();
        -- Render credits
        local iLeft<const> = iStageL + 16;
        fontLittle:Print(iLeft, iCredits1Y, strCredits1);
        fontLarge:Print(iLeft, iCredits2Y, strCredits2);
      end
      -- Render function
      local function RenderCreditsTopRight()
        -- Render terrain, objects and vignette
        RenderCredits();
        -- Render credits
        local iRight<const> = iStageR - 16;
        fontLittle:PrintR(iRight, 16, strCredits1);
        fontLarge:PrintR(iRight, 28, strCredits2);
      end
      -- Pick which way to render the credits
      local fcbCreditsRender;
      if #aLevels % 2 == 0 then fcbCreditsRender = RenderCreditsTopRight;
                           else fcbCreditsRender = RenderCreditsBottomLeft end;
      -- Credits procedure
      local function CreditsProc()
        -- Process game functions
        GameProc();
        -- Set a random object in the level
        if iActionTimer == 0 then
          -- Select a random object and not a digger! The last objects in
          -- the list are always the diggers so we can just crop them out.
          -- If we get an object then select and focus on the object!
          SelectObject(aObjects[random(#aObjects-(#aPlayers[1].D*2))], true);
        end
        -- Should we change level?
        iActionTimer = iActionTimer + 1;
        if iActionTimer < 600 then return end;
        -- Keep rendering text during blackout loading
        SetCallbacks(nil, nil, nil);
        -- If this is the last credit?
        if bLast then
          return Fade(0, 1, 0.04, fcbCreditsRender, InitRollingCredits);
        end
        -- When faded out to next level?
        local function OnFadeOut() LoadDemoLevel(iCreditId+1) end;
        -- Fade out to next level
        Fade(0, 1, 0.04, fcbCreditsRender, OnFadeOut);
      end
      -- Set input procedure
      local function CreditsInput() SetCursor(aCursorIdData.ARROW) end;
      -- Load demo level
      LoadLevel(iLevelId, strMusic, nil, true,
        aObjectTypes.DIGRANDOM, true, CreditsProc, fcbCreditsRender,
        CreditsInput);
    end
    -- Load first level or credits
    if bRolling then InitRollingCredits("credits");
                else LoadDemoLevel(1, "credits") end;
  end
  -- Load bank texture
  LoadResources("Credits", aAssets, OnLoaded);
end
-- Exports and imports ----------------------------------------------------- --
return { A={ InitCredits = InitCredits }, F=function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  DeInitLevel, Fade, GameProc, GetMusic, InitScore, LoadLevel, LoadResources,
  LockViewPort, PlayMusic, ProcessViewPort, RegisterFBUCallback, RenderObjects,
  RenderTerrain, SelectObject, SetCallbacks, SetCursor, aCreditsData,
  aCreditsXData, aCursorIdData, aLevelTypesData, aLevelsData, aObjectTypes,
  aObjects, aPlayers, fontLarge, fontLittle
  = -- --------------------------------------------------------------------- --
  GetAPI("DeInitLevel", "Fade", "GameProc", "GetMusic", "InitScore",
    "LoadLevel", "LoadResources", "LockViewPort", "PlayMusic",
    "ProcessViewPort", "RegisterFBUCallback", "RenderObjects", "RenderTerrain",
    "SelectObject", "SetCallbacks", "SetCursor", "aCreditsData",
    "aCreditsXData", "aCursorIdData", "aLevelTypesData", "aLevelsData",
    "aObjectTypes", "aObjects", "aPlayers", "fontLarge", "fontLittle");
  -- Set ending level load data -------------------------------------------- --
  aEndLevelData.t = aLevelTypesData[4];
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

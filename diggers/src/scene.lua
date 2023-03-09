-- SCENE.LUA =============================================================== --
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
-- M-Engine function aliases ----------------------------------------------- --
-- Diggers function and data aliases --------------------------------------- --
local Fade, LoadLevel, LoadResources, PlayMusic, SetCallbacks, aGlobalData,
  aLevelTypesData, aLevelsData, fontLarge;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 1, F = false,    P = { 320, 240, 0, 0, 0 } },
                         { T = 7, F = "select", P = { } } };
-- Init scene function ----------------------------------------------------- --
local function InitScene(iZoneId)
  -- Set level number and get data for it.
  local iLevelId<const> = 1 + ((iZoneId - 1) % #aLevelsData);
  local aLevelInfo<const> = aLevelsData[iLevelId];
   -- On loaded function
  local function OnLoaded(aResources)
    -- Play scene music
    PlayMusic(aResources[2].H);
    -- Set scene texture
    local texScene = aResources[1].H;
    texScene:TileSTC(1);
    texScene:TileA(192, 272, 512, 512);
    -- Set first tile number
    local iTileId = 0;
    -- Set text to win label
    local sTextToWin<const> =
      "RAISE "..(aLevelInfo.w + aGlobalData.gCapitalCarried).." ZOGS TO WIN";
    -- Render the scene callback since we're using it multiple times
    local function RenderScene()
      -- Draw appropriate background
      texScene:BlitSLT(iTileId, 0, 0);
      -- Draw text if ready
      if iTileId == 1 then
        fontLarge:SetCRGBA(1, 1, 1, 1);
        fontLarge:PrintC(160, 192, sTextToWin);
      end
    end
    -- Fade in proc
    local function OnSceneFadeIn()
      -- Init wait timer
      local iWaitCounter = 0;
      -- Waiting on scene graphic
      local function SceneWaitProc()
        -- Increment timer and don't do anything until 2 seconds
        iWaitCounter = iWaitCounter + 1;
        if iWaitCounter < 120 then return end;
        -- Scene fade out proc
        local function OnSceneFadeOut()
          -- Set next tile number
          iTileId = 1;
          -- Required Zogs fade in proc
          local function OnRequiredFadeIn()
            -- Required Zogs wait procedure
            local function RequiredWaitProc()
              -- Increment timer and don't do anything until 4 seconds
              iWaitCounter = iWaitCounter + 1;
              if iWaitCounter < 240 then return end;
              -- On required fade out?
              local function OnRequiredFadeOut()
                -- Release assets to garbage collector
                texScene = nil;
                -- Load the requested level
                LoadLevel(iLevelId, "game");
              end
              -- Fade out and then load the level
              Fade(0, 1, 0.04, RenderScene, OnRequiredFadeOut, true);
            end
            -- Set required wait callbacks
            SetCallbacks(RequiredWaitProc, RenderScene, nil);
          end
          -- Fade in required scene
          Fade(1, 0, 0.04, RenderScene, OnRequiredFadeIn);
        end
        -- Set the gold scene
        Fade(0, 1, 0.04, RenderScene, OnSceneFadeOut);
      end
      -- Set scene wait callbacks
      SetCallbacks(SceneWaitProc, RenderScene, nil);
    end
    -- Fade in
    Fade(1, 0, 0.04, RenderScene, OnSceneFadeIn);
  end
  -- Get level terrain information
  local aTerrain<const> = aLevelInfo.t;
  -- Set scene setter texture to load
  aAssets[1].F = aTerrain.f.."ss";
  -- Load resources
  LoadResources("Scene "..aLevelInfo.n.."/"..aTerrain.n, aAssets, OnLoaded);
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitScene = InitScene }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  Fade, LoadLevel, LoadResources, PlayMusic, SetCallbacks, aGlobalData,
  aLevelTypesData, aLevelsData, fontLarge
  = -- --------------------------------------------------------------------- --
  GetAPI("Fade", "LoadLevel", "LoadResources", "PlayMusic", "SetCallbacks",
    "aGlobalData", "aLevelTypesData", "aLevelsData", "fontLarge");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

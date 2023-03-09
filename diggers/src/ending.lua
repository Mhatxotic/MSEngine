-- ENDING.LUA ============================================================== --
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
local assert<const>, max<const> = assert, math.max;
-- M-Engine function aliases ----------------------------------------------- --
local UtilIsInteger<const>, UtilIsTable<const> = Util.IsInteger, Util.IsTable;
-- Diggers function and data aliases --------------------------------------- --
local Fade, InitCredits, LoadResources, PlayMusic,SetCallbacks, aEndingData,
  fontLittle;
-- Assets required --------------------------------------------------------- --
local aAssets1<const> = { { T = 2, F = "lobbyc", P = { 0 } },
                          { T = 7, F = "select", P = { 0 } } };
local aAssets2<const> = { { T = 1, F = false,    P = { 428, 240, 0, 0, 0 } } };
local aAssets3<const> = { { T = 2, F = "ending3",P = { 0 } } };
-- Init ending screen functions -------------------------------------------- --
local function InitEnding(iRaceId)
  -- Check race id and check ending data
  assert(UtilIsInteger(iRaceId), "No race id specified!");
  local aEndingItem<const> = aEndingData[iRaceId];
  assert(UtilIsTable(aEndingData), "Invalid race id!");
  -- When assets have loaded?
  local function OnEnding1Loaded(aResources)
    -- Play win music
    PlayMusic(aResources[2].H, nil, nil, nil, 371767);
    -- Load lobby texture
    local texLobby = aResources[1].H;
          texLobby:TileA(0, 272, 512, 512);
          texLobby:TileA(0, 214, 238, 271);
          texLobby:TileA(305,   0, 512, 184);
    -- Render callback
    local function Ending1Render()
      -- Draw background
      texLobby:BlitSLT(1, -54, 0);
      -- Draw text
      fontLittle:SetCRGBA(1,1,1,1);
      fontLittle:PrintC(160, 200, "MINING OPERATIONS COMPLETED!");
    end
    -- First ending screen procedure
    local function OnEnding1FadeIn()
      -- Reset action timer
      local iActionTimer = 0;
      -- First ending scene waiting
      local function Ending1Proc()
        -- Increment action timer and done if action timer not reached yet
        iActionTimer = iActionTimer + 1;
        if iActionTimer < 120 then return end;
        -- When ending 1 has faded out
        local function OnEnding1FadeOut()
          -- Dereference lobby asset to garbage collector
          texLobby = nil;
          -- Reset action timer
          iActionTimer = 0;
          -- Ending screen 2 resources loaded?
          local function OnEnding2Loaded(aResources)
            -- Load texture and tiles
            local texEnding = aResources[1].H;
            -- Set tile ending
            local iTileEnding<const> = aEndingItem[2];
            -- Set custom race specific texts
            local sText1, sText2 = aEndingItem[3], aEndingItem[4];
            -- Render ending part 2
            local function Ending2Render()
              -- Draw background
              texEnding:BlitSLT(iTileEnding, -54, 0);
              -- Draw text
              fontLittle:SetCRGBA(1, 1, 1, 1);
              fontLittle:PrintC(160, 200, sText1);
              fontLittle:PrintC(160, 220, sText2);
            end
            -- When render part 2 has faded in
            local function OnEnding2FadeIn()
              -- Ending two procedure
              local function Ending2Proc()
                -- Increment action timer and done if action timer not reached yet
                iActionTimer = iActionTimer + 1;
                if iActionTimer < 240 then return end
                -- When ending screen 2 has faded out
                local function OnEnding2FadeOut()
                  -- Dereference ending asset to garbage collector
                  texEnding = nil;
                  -- Reset action timer
                  iActionTimer = 0;
                  -- Reset alpha value
                  local iAlphaValue = 1;
                  -- When ending 3 resources have loaded
                  local function OnEnding3Loaded(aResources)
                    -- Load stranger texture and tiles
                    local texStr = aResources[1].H;
                    local iTileStrBg<const> = texStr:TileA(0, 0, 428, 240);
                    local iTileStr<const> = texStr:TileA(0, 330, 113, 512);
                    -- Credits render callback
                    local function Ending3Render()
                      -- Draw background
                      texStr:BlitSLT(iTileStrBg, -54, 0);
                      -- Draw stranger
                      texStr:SetCA(iAlphaValue);
                      texStr:BlitSLT(iTileStr, 0, 68);
                      texStr:SetCA(1);
                      -- Draw text
                      fontLittle:SetCRGBA(1,1,1,1);
                      fontLittle:PrintC(160, 200,
                        "...WHILST THE MYSTERIOUS FIGURE OF THE");
                      fontLittle:PrintC(160, 220,
                        "MASTER MINER RETURNS FROM WHENCE HE CAME");
                    end
                    -- When ending screen 3 has faded in
                    local function OnEnding3FadeIn()
                      -- Ending 3 procedure
                      local function Ending3Proc()
                        -- Ignore if stranger isn't fully gone
                        iAlphaValue = max(0, iAlphaValue - 0.002);
                        if iAlphaValue > 0 then return end;
                        -- When ending screen 3 has faded out
                        local function OnEnding3FadeOut()
                          -- Dereference stranger asset to garbage collector
                          texStr = nil;
                          -- Initialise final credits
                          InitCredits();
                        end
                        -- Fade out ending screen 3
                        Fade(0, 1, 0.01, Ending3Render, OnEnding3FadeOut,
                          true);
                      end
                      -- Wait on ending screen 3
                      SetCallbacks(Ending3Proc, Ending3Render, nil);
                    end
                    -- Fade in ending screen 3
                    Fade(1, 0, 0.025, Ending3Render, OnEnding3FadeIn);
                  end
                  -- Load ending 3 resources
                  LoadResources("Ending3", aAssets3, OnEnding3Loaded);
                end
                -- Fade out on ending screen 2
                Fade(0, 1, 0.025, Ending2Render, OnEnding2FadeOut);
              end
              -- Wait on ending screen 2
              SetCallbacks(Ending2Proc, Ending2Render, nil);
            end
            -- Fade in ending screen 2
            Fade(1, 0, 0.025, Ending2Render, OnEnding2FadeIn);
          end
          -- Set race scene filename
          aAssets2[1].F = "ending"..aEndingItem[1];
          -- Load ending screen 2 resource
          LoadResources("Ending2", aAssets2, OnEnding2Loaded);
        end
        -- Fade out ending screen 1
        Fade(0, 1, 0.025, Ending1Render, OnEnding1FadeOut);
      end
      -- Wait on ending screen 1
      SetCallbacks(Ending1Proc, Ending1Render, nil);
    end
    -- Fade in to ending screen 1 (Mining operations complete!)
    Fade(1, 0, 0.025, Ending1Render, OnEnding1FadeIn);
  end
  -- Load bank texture
  LoadResources("Ending1", aAssets1, OnEnding1Loaded);
end
-- Exports and imports ----------------------------------------------------- --
return { A={ InitEnding = InitEnding }, F=function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  Fade, InitCredits, LoadResources, PlayMusic, SetCallbacks, aEndingData,
  fontLittle
  = -- --------------------------------------------------------------------- --
  GetAPI("Fade", "InitCredits","LoadResources", "PlayMusic", "SetCallbacks",
    "aEndingData", "fontLittle");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

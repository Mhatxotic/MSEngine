-- SCORE.LUA =============================================================== --
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
local unpack<const>, error<const>, pairs<const>, ipairs<const>, max<const>,
  min<const>, floor<const>, sin<const>, cos<const>, tostring<const>,
  mininteger<const> =
    table.unpack, error, pairs, ipairs, math.max, math.min, math.floor,
    math.sin, math.cos, tostring, math.mininteger;
-- M-Engine function aliases ----------------------------------------------- --
local CoreTime<const>, UtilIsInteger<const>, UtilIsString<const> =
  Core.Time, Util.IsInteger, Util.IsString;
-- Diggers function and data aliases --------------------------------------- --
local Fade, InitTitle, IsButtonReleased, LoadResources, PlayMusic,
  PlayStaticSound, RegisterFBUCallback, aGlobalData, RenderFade, SetCallbacks,
  SetCursor, aCursorIdData, aSfxData, fontLittle, fontTiny, texSpr;
-- Assets required --------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "title", P = { 0 } },
                         { T = 7, F = "score", P = { } } };
-- Init score screen function ---------------------------------------------- --
local function InitScore()
  -- When score assets have loaded?
  local function OnLoaded(aResources)
    -- Register frame buffer update
    local iStageL;
    RegisterFBUCallback("score", function(...)
      local _ _, _, iStageL, _, _, _ = ...;
    end);
    -- Play score music
    PlayMusic(aResources[2].H);
    -- Setup lobby texture
    local texTitle = aResources[1].H;
    texTitle:TileSTC(1);
    texTitle:TileS(0, 0, 0, 512, 240);
    texTitle:TileA(227, 240, 285, 448);
    -- Calculate totals
    local iTotalId, iTotalScore, aTotals = 0, 0, { };
    local iScoreItem = 0;
    -- Function to add a new total
    local function AddTotal(sLabel, iValue, iScorePerTick)
      -- Check parameters
      if not UtilIsString(sLabel) then
        error("Label string is invalid! "..tostring(sLabel)) end;
      if #sLabel == 0 then error("Label is empty!") end;
      if not UtilIsInteger(iValue) then
        error("Value integer is invalid! "..tostring(iValue)) end;
      if not UtilIsInteger(iScorePerTick) then
        error("Score/tick integer is invalid! "..tostring(iScorePerTick)) end;
      -- Starting X and movement callback are conditional
      local nStartX, fcbMove;
      -- If next id is odd?
      if #aTotals % 2 == 0 then
        -- Start from left
        nStartX = -480 - (#aTotals * 16);
        -- Set call back to move in from left
        fcbMove = function(aData)
          -- Ignore if in centre of screen
          if aData[7] >= 0 then return end;
          aData[7] = min(0, aData[7] + 8);
        end
      -- If next id is even?
      else
        -- Start from right
        nStartX = 480+(#aTotals*16)
        -- Set call back to move in from right
        fcbMove = function(aData)
          -- Ignore if in centre of screen
          if aData[7] <= 0 then return end;
          aData[7] = max(0, aData[7] - 8);
        end
      end
      -- Prepare the category in the categories list
      aTotals[1 + #aTotals] = {
        1,                             -- [01] Operational function
        0,                             -- [02] Current 'value' animated tally
        iValue,                        -- [03] Total 'value' remaining to tally
        iValue / 60,                   -- [04] 'Value' to take off per tick
        iScorePerTick,                 -- [05] Score to add per tick 'value'.
        sLabel,                        -- [06] Item label
        nStartX,                       -- [07] Starting X position
        32 + (#aTotals * 14),          -- [08] Starting Y position
        0,                             -- [09] Actual final score for item
        fcbMove                        -- [10] Move animation callback
      };
    end
    -- Count levels completed
    local iZonesComplete = 0;
    for _ in pairs(aGlobalData.gLevelsCompleted) do
      iZonesComplete = iZonesComplete + 1 end;
    -- Add score categories
    for iI, aData in ipairs({
      { "Zones completed",   iZonesComplete,             10000 },
      { "Bank balance",      aGlobalData.gBankBalance,      10 },
      { "Capital carried",   aGlobalData.gTotalCapital,    100 },
      { "Items purchased",   aGlobalData.gTotalPurchases, 1000 },
      { "Items value",       aGlobalData.gTotalPurchExp,    10 },
      { "Terrain dug",       aGlobalData.gTotalDug,          1 },
      { "Gems found",        aGlobalData.gTotalGemsFound,  100 },
      { "Gems sold",         aGlobalData.gTotalGemsSold,   100 },
      { "Gems value",        aGlobalData.gTotalIncome,      10 },
      { "Salary paid",       aGlobalData.gTotalSalaryPaid,  10 },
      { "Death duties",      aGlobalData.gTotalDeaths,    1000 },
      { "Death duties paid", aGlobalData.gTotalDeathExp,    10 },
      { "Time taken",       -aGlobalData.gTotalTimeTaken,    1 }
    }) do AddTotal(unpack(aData)) end;
    -- Total score
    local iTotalScore = 0;
    -- Draw animated logos
    local function DrawLogos()
      -- Don't draw anything if in 4:3 mode
      if iStageL >= 0 then return end;
      -- Draw sidebar scrolling logo's
      local Width = -iStageL-4;
      local Aspect = 208/58;
      local Height = Width*Aspect;
      local LX = (CoreTime()*100)%240;
      local LY = -LX;
      local X = iStageL+4;
      texTitle:SetCA(0.25);
      texTitle:BlitSLTRB(1,         X, -240+LX,    X+Width,-240+Height+LX);
      texTitle:BlitSLTRB(1,         X,      LX,    X+Width,     Height+LX);
      texTitle:BlitSLTRB(1,         X,  240+LX,    X+Width, 240+Height+LX);
      texTitle:BlitSLTRB(1, 320+Width,      Height+LY, 320,     LY);
      texTitle:BlitSLTRB(1, 320+Width,  240+Height+LY, 320, 240+LY);
      texTitle:BlitSLTRB(1, 320+Width,  480+Height+LY, 320, 480+LY);
      LX = -LX;
      LY = -LY - 240;
      texTitle:BlitSLTRB(1,         X, -240+LX,    X+Width,-240+Height+LX);
      texTitle:BlitSLTRB(1,         X,      LX,    X+Width,     Height+LX);
      texTitle:BlitSLTRB(1,         X,  240+LX,    X+Width, 240+Height+LX);
      texTitle:BlitSLTRB(1, 320+Width,      Height+LY, 320,     LY);
      texTitle:BlitSLTRB(1, 320+Width,  240+Height+LY, 320, 240+LY);
      texTitle:BlitSLTRB(1, 320+Width,  480+Height+LY, 320, 480+LY);
      -- Reset lobby texture colour
      texTitle:SetCRGBA(1, 1, 1, 1);
    end
    -- Bars position
    local iBarY = 0;
    -- Render function
    local function RenderSimple()
      -- Draw backdrop
      texTitle:BlitLT(-96, 0);
      -- Draw logos
      DrawLogos();
    end
    -- Proc function
    local function OnFadeIn()
      -- Set loading cursor
      SetCursor(aCursorIdData.WAIT);
      -- Coloured score
      local strScoreC, strScore, iColourIndex = "", "0", 1;
      -- Rank data
      local aRanks<const> = {
        { 600000, "Grand Master" }, {     550000, "Master"       },
        { 500000, "Professional" }, {     450000, "Genius"       },
        { 400000, "Expert"       }, {     350000, "Advanced"     },
        { 300000, "Intermediate" }, {     250000, "Adept"        },
        { 200000, "Amateur"      }, {     150000, "Apprentice"   },
        { 100000, "Novice"       }, {      50000, "Beginner"     },
        {      0, "Newbie"       }, { mininteger, "Slug"         }
      };
      local function GetRank()
        for iI = 1, #aRanks do
          local aRank<const> = aRanks[iI];
          if iTotalScore >= aRank[1] then return aRank[2] end;
        end
      end
      -- Game over text
      local sTitleText<const> = "GAME OVER -- HOW WELL DID YOU DO?";
      -- Render score
      local function RenderScore()
        -- Draw background
        texTitle:SetCRGBA(1, 1, 1, 1);
        texTitle:BlitLT(-96, 0);
        -- Draw logos
        DrawLogos();
        -- Draw title
        for iI = 1, #aTotals do
          -- Get bar data
          local aData<const> = aTotals[iI];
          -- This is our bar id?
          if iTotalId == iI then
            texSpr:SetCRGB(0, 0.5, 0);
            RenderFade(1, 8, aData[8]-2, 312, aData[8]+10, 1022);
            fontLittle:SetCRGBA(1, 1, 1, 1);
            fontLittle:Print(aData[7]+16, aData[8], aData[6]);
            fontTiny:SetCRGBA(1, 1, 1, 1);
            fontTiny:PrintR(aData[7]+160, aData[8]+1, floor(aData[2]));
            fontTiny:SetCRGBA(1, 1, 1, 1);
            fontTiny:Print(aData[7]+160, aData[8]+1, "x"..aData[5]);
            fontLittle:SetCRGBA(1, 1, 1, 1);
            fontLittle:PrintR(aData[7]+304, aData[8], floor(aData[9]));
          else
            if iTotalId > iI then texSpr:SetCRGB(0, 0, 0.5);
                             else texSpr:SetCRGB(0.5, 0, 0) end;
            local nVal = CoreTime()+iI/4;
            RenderFade(sin(nVal)*cos(nVal)+0.75,
              aData[7]+8, aData[8]-2, aData[7]+312, aData[8]+10, 1022);
            fontLittle:SetCRGBA(0.75, 0.75, 0.75, 1);
            fontLittle:Print(aData[7]+16, aData[8], aData[6]);
            fontTiny:SetCRGBA(0, 1, 0, 1);
            fontTiny:PrintR(aData[7]+160, aData[8]+1, aData[2]);
            fontTiny:SetCRGBA(1, 0.5, 0, 1);
            fontTiny:Print(aData[7]+160, aData[8]+1, "x"..aData[5]);
            fontLittle:SetCRGBA(1, 0, 1, 1);
            fontLittle:PrintR(aData[7]+304, aData[8], aData[9]);
          end
        end
        -- Set text colour
        fontLittle:SetCRGBAI(0xFFFFFFFF);
        texSpr:SetCRGBAI(0x7F0000FF);
        -- Finished tallying?
        if iTotalId > #aTotals then
          -- Starting X position
          local iX = 8;
          -- Draw the left side of the title and status bar
          for iY = 8, 216, 208 do texSpr:BlitSLT(847, iX, iY) end;
          -- Move along X axis again by one tile
          iX = iX + 16;
          -- Calculate X position where we are ending drawing at
          local iXmax = iX + (16 * 16);
          -- Until we are at the maximum
          while iX <= iXmax do
            -- Draw top and bottom part
            for iY = 8, 216, 208 do texSpr:BlitSLT(848, iX, iY) end;
            -- Move X along
            iX = iX + 16;
          end
          -- Draw the right side of the title and status bar
          for iY = 8, 216, 208 do texSpr:BlitSLT(849, iX, iY) end;
          -- Draw title
          fontLittle:PrintC(160, 12, sTitleText);
          -- Draw pulsating score
          fontLittle:SetSize(3);
          local nVal = CoreTime();
          fontLittle:SetCA(sin(nVal) * cos(nVal) + 0.75);
          fontLittle:PrintR(304, 213, strScore);
          -- Draw rank
          fontLittle:SetSize(1);
          fontLittle:Print(16, 220, strScoreC);
        -- Still tallying?
        else
          -- Animate title and status bars
          if iBarY < 24 then iBarY = iBarY + 1 end;
          -- Starting X position
          local iX = 8;
          -- Draw left part of title and status bar including animation
          texSpr:BlitSLT(847, iX, -16+iBarY);
          texSpr:BlitSLT(847, iX, 216+(24-iBarY));
          -- Move X along one tile
          iX = iX + 16;
          -- Draw centre part of title and status bar
          local iXmax = iX + (16 * 16);
          while iX <= iXmax do
            -- Draw top and bottom part
            texSpr:BlitSLT(848, iX, -16+iBarY);
            texSpr:BlitSLT(848, iX, 216+(24-iBarY));
            -- Move X along one tile
            iX = iX + 16;
          end
          -- Draw right part of title and status bar
          texSpr:BlitSLT(849, iX, -16+iBarY);
          texSpr:BlitSLT(849, iX, 216+(24-iBarY));
          -- Draw title text
          fontLittle:PrintC(160, -12+iBarY, sTitleText);
          -- Draw score text
          fontLittle:SetSize(3);
          fontLittle:PrintR(304, 213+(24-iBarY), strScore);
          -- Draw rank
          fontLittle:SetSize(1);
          fontLittle:Print(16, 220+(24-iBarY), strScoreC);
        end
        -- Reset sprites and font colour this for mouse cursor
        texSpr:SetCRGBAI(0xFFFFFFFF);
        fontLittle:SetCRGBAI(0xFFFFFFFF);
        fontTiny:SetCRGBAI(0xFFFFFFFF);
      end
      -- Tick procedure
      local function ProcScore()
        -- If animating in?
        if iTotalId == 0 then
          -- Animate bars
          for iI = 1, #aTotals do
            -- Get bar data
            local aData = aTotals[iI];
            -- Call movement callback for bar
            aData[10](aData);
          end
          -- If all bars have been moved? Start counting
          if aTotals[#aTotals][7] == 0 then iTotalId = 1 end;
          -- Done for now
          return;
        end
        local aData<const> = aTotals[iTotalId];
        if aData[1] == 1 then
          if aData[4] == 0 then
            aData[1] = 2;
          elseif aData[3] >= 0 then
            if aData[2] < aData[3] then
              aData[2] = aData[2] + aData[4];
              if aData[2] >= aData[3] then
                aData[2] = aData[3];
                iScoreItem = aData[2] * aData[5]
                aData[9] = iScoreItem;
                aData[1] = 2;
                iTotalScore = iTotalScore + iScoreItem;
                strScore = tostring(iTotalScore);
                iScoreItem = 0;
              else
                iScoreItem = aData[2] * aData[5];
                aData[9] = iScoreItem;
                strScore = tostring(floor(iTotalScore + iScoreItem));
              end
            end
          elseif aData[2] > aData[3] then
            aData[2] = aData[2] + aData[4];
            iScoreItem = aData[2] * aData[5];
            aData[9] = iScoreItem;
            strScore = tostring(floor(iTotalScore + iScoreItem));
          elseif aData[2] <= aData[3] then
            aData[2] = aData[3];
            iScoreItem = aData[2] * aData[5]
            aData[9] = iScoreItem;
            aData[1] = 2;
            iTotalScore = iTotalScore + iScoreItem;
            strScore = tostring(iTotalScore);
            iScoreItem = 0;
          end
          -- Update rank
          strScoreC = GetRank();
        elseif aData[1] == 2 then
          -- Increment total categories proceeded and if we did all of them?
          iTotalId = iTotalId + 1;
          if iTotalId > #aTotals then
            -- Set exit cursor
            SetCursor(aCursorIdData.EXIT);
            -- When faded out?
            local function InputScore()
              -- Mouse button not clicked? Return!
              if IsButtonReleased(0) then return end;
              -- Play sound
              PlayStaticSound(aSfxData.SELECT);
              -- When faded out?
              local function OnFadeOut()
                -- Remove callback
                RegisterFBUCallback("score");
                -- Dereference assets for garbage collection
                texTitle = true;
                --- ...and return to title screen!
                InitTitle(true);
              end
              -- Fade out...
              Fade(0, 1, 0.01, RenderScore, OnFadeOut, true);
            end
            -- Wait for input
            SetCallbacks(nil, RenderScore, InputScore);
          end
        end
      end
      -- Set callbacks
      SetCallbacks(ProcScore, RenderScore, nil);
    end
    -- Fade in
    Fade(1, 0, 0.025, RenderSimple, OnFadeIn);
  end
  -- Load score assets
  LoadResources("Game Over", aAssets, OnLoaded);
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitScore = InitScore }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  LoadResources, SetCallbacks, SetCursor, aCursorIdData, aSfxData, PlayStaticSound,
  Fade, InitTitle, PlayMusic, IsButtonReleased, RenderFade, texSpr, fontLittle,
  fontTiny, RegisterFBUCallback, aGlobalData
  = -- --------------------------------------------------------------------- --
  GetAPI("LoadResources", "SetCallbacks", "SetCursor", "aCursorIdData",
    "aSfxData", "PlayStaticSound", "Fade", "InitTitle", "PlayMusic",
    "IsButtonReleased", "RenderFade", "texSpr", "fontLittle", "fontTiny",
    "RegisterFBUCallback", "aGlobalData");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

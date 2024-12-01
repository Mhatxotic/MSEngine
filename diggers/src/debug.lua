-- DEBUG.LUA =============================================================== --
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
local max<const>, min<const>, random<const>, format<const>, ceil<const>,
  sin<const>, cos<const> =
  math.max, math.min, math.random, string.format, math.ceil, math.sin, math.cos;
-- M-Engine function aliases ----------------------------------------------- --
local UtilHex<const>, CoreCPUUsage<const>, CoreRAM<const>,
  DisplayGPUFPS<const>, CoreUptime<const>, CoreLUATime<const>,
  CoreLUAUsage<const> =
    Util.Hex, Core.CPUUsage, Core.RAM, Display.GPUFPS, Core.Uptime,
    Core.LUATime, Core.LUAUsage;
-- Diggers function and data aliases --------------------------------------- --
local Fade, GetGameTicks, GetMouseX, GetMouseY, aPlayers, aObjects,
  RenderTerrain, RenderObjects, RenderShroud, BCBlit, texSpr, fontLarge,
  fontLittle, fontTiny, SelectObject, GameProc, GetActiveObject,
  GetActivePlayer, SetCallbacks, LoadLevel, UpdateShroud, SetPlaySounds,
  HaveZogsToWin, ProcInput, GetOpponentPlayer, RegisterFBUCallback,
  aLevelsData, GetViewportData, GetLevelInfo;
-- Load infinite play ------------------------------------------------------ --
local function InitDebugPlay(iId)
  -- Frame buffer updated function
  local iStageL, iStageT, iStageR, iStageB;;
  local function OnFrameBufferUpdated(...)
    local _ _, _, iStageL, iStageT, iStageR, iStageB = ...;
  end
  -- We want to know when the frame buffer is updated
  RegisterFBUCallback("debug", OnFrameBufferUpdated);
  -- Player and digger ids for selection
  local iSelectedPlayerId, iSelectedDiggerId = 1, 1;
  -- Infinite play tick callback
  local function OnTick()
    -- Switch object every 10 seconds
    if GetGameTicks() % 600 == 0 then
      -- Select a player
      local aPlayer<const> = aPlayers[iSelectedPlayerId];
      -- Find a digger from the specified player.
      local aObject = aPlayer.D[iSelectedDiggerId];
      -- Still not found? Find a random object
      if not aObject then aObject = aObjects[random(#aObjects)] end;
      -- Select the object if we got something!
      if aObject then SelectObject(aObject) aObjectAutoSelected = aObject end;
      -- Next object
      iSelectedDiggerId = iSelectedDiggerId + 1;
      if iSelectedDiggerId > 5 then
        iSelectedDiggerId = 1;
        iSelectedPlayerId = iSelectedPlayerId + 1;
        if iSelectedPlayerId > 2 then iSelectedPlayerId = 1 end;
      end
    end
    -- Init game proc
    GameProc();
  end
  -- Infinite play render callback
  local function OnRender()
    -- Render terrain
    RenderTerrain();
    -- Render game objects
    RenderObjects();
  end
  -- If level selected
  local nGPUFramesPerSecond = 60;
  local nAlpha<const> = 1 / nGPUFramesPerSecond
  local iOppAnimMoney, sOppMoney = 0, nil;
  local iAnimMoney, sMoney = 0, nil;
  local function OnRenderRandom()
    -- Render terrain
    RenderTerrain();
    -- Get active player object and opponent player
    local aActivePlayer<const> = GetActivePlayer();
    local aActiveObject<const> = GetActiveObject();
    local aOpponentPlayer<const> = GetOpponentPlayer();
    -- Get viewport information
    local iPixPosX<const>, iPixPosY<const>,
          iPixPosTargetX<const>, iPixPosTargetY<const>,
          iPixCenPosX<const>, iPixCenPosY<const>,
          iPosX<const>, iPosY<const>,
          iAbsCenPosX<const>, iAbsCenPosY<const>,
          iViewportW<const>, iViewportH<const> = GetViewportData();
    -- Get level information
    local iLevelId, sLevelName, sLevelType, iWinLimit = GetLevelInfo();
    -- Calculate viewpoint position
    local nVPX<const>, nVPY<const> = iPixPosX - iStageL, iPixPosY - iStageT;
    -- For each object
    for iObjId = 1, #aObjects do
      -- Get object data
      local aObject<const> = aObjects[iObjId];
      local iX<const>, iY<const> = aObject.X, aObject.Y;
      -- Holds objects render position on-screen
      local iXX, iYY = iX - nVPX + aObject.OFX,
                       iY - nVPY + aObject.OFY;
      -- If in bounds?
      if min(iXX + 16, iStageR) > max(iXX, iStageL) and
         min(iYY + 16, iStageB) > max(iYY, iStageT) then
        -- Draw the texture
        texSpr:BlitSLTRB(aObject.S, iXX, iYY, iXX + 16, iYY + 16);
        -- Get health
        local iHealth<const> = aObject.H;
        -- Centre location of digger information
        local iXXC<const> = iXX + 8;
        -- Active object is a digger?
        local iDiggerId = aObject.DI;
        if iDiggerId then
          -- Is player one?
          if aObject.P == aActivePlayer then
            -- Active object? Set brighter
            if aObject == aActiveObject then
              fontTiny:SetCRGBA(1, 0.7, 0.8, 1);
            -- Inactive object? Set dim
            else fontTiny:SetCRGBA(1, 0.6, 0.7, 0.75) end;
          -- Is player two?
          elseif aObject == aActiveObject then
            -- Active object? Set brighter
            fontTiny:SetCRGBA(0.34, 0.9, 0.5, 1);
          -- Inactive object? Set dim
          else fontTiny:SetCRGBA(0.24, 0.8, 0.4, 0.75) end;
          -- Draw name and id of digger
          fontTiny:PrintC(iXXC, iYY - 9, aObject.OD.NAME.." "..iDiggerId);
          -- Get object inventory and if have any
          local aObjInv<const> = aObject.I;
          if #aObjInv > 0 then
            -- Draw them above head
            local iX = iXX - ((#aObjInv - 1) * 8 / 2) + 4;
            local iY<const> = iYY - 18;
            local iY2<const> = iY + 8;
            for iIIndex = 1, #aObjInv do
              texSpr:BlitSLTRB(aObjInv[iIIndex].S, iX, iY, iX+8, iY2);
              iX = iX + 8;
            end
          end
        -- Not a digger?
        else
          -- Active object? Set brighter
          if aObject == aActiveObject then fontTiny:SetCRGBA(1, 1, 1, 1);
          -- Inactive object? Set dim
          else fontTiny:SetCRGBA(0.9, 0.9, 0.9, 0.75) end;
          -- Draw name of object
          fontTiny:PrintC(iXXC, iYY - 9, aObject.OD.NAME.." "..aObject.U);
        end
        -- Set string for object target
        local aTarget = aObject.T;
        if aTarget then aTarget = format("\rt%08x%u", aTarget.S, aTarget.DI)
        -- No target?
        else
          -- Start of pursuer list
          aTarget = "\n";
          -- Add pursuers
          for iUId, aPursuer in pairs(aObject.TL) do
            aTarget = aTarget..format("\rt%08x%u", aPursuer.S, aPursuer.U);
          end
          -- Remove text if no pursuers
          if #aTarget <= 1 then aTarget = "" end;
        end
        -- Draw object status under object
        fontTiny:PrintCT(iXXC, iYY + 17, iX.."x"..iY.."\n"..
          aObject.A..":"..aObject.J..":"..aObject.D.." "..aObject.AT.."\n"..
          UtilHex(aObject.F)..aTarget, texSpr);
        -- Draw health bar background
        local iYHealth<const> = iYY - 1;
        local iYHealth2<const> = iYHealth - 1;
        texSpr:SetCRGB(0, 0, 0)
        texSpr:BlitSLTRB(1022, iXX, iYHealth, iXX + 16, iYHealth2);
        -- White to orange
        if iHealth >= 50 then texSpr:SetCRGB(1, 1, (iHealth-50)/50)
        -- Orange to red
        elseif iHealth > 0 then texSpr:SetCRGB(1, iHealth/50, 0) end;
        -- Draw health bar
        texSpr:BlitSLTRB(1022,
          iXX, iYHealth, iXX + iHealth / 6.25, iYHealth2);
        texSpr:SetCRGB(1, 1 ,1);
        -- Got an attachment? Draw it too!
        if aObject.STA then
          iXX, iYY = iXX + aObject.OFXA, iYY + aObject.OFYA;
          BCBlit(texSpr, aObject.SA, iXX, iYY, iXX + 16, iYY + 16);
        end
      end
    end
    -- Render shroud
    texSpr:SetCA(0.9);
    RenderShroud();
    -- Get system information
    local nCpu<const>, nSys<const> = CoreCPUUsage();
    nGPUFramesPerSecond = (nAlpha * DisplayGPUFPS()) + (1.0 - nAlpha) *
        (nGPUFramesPerSecond or 60);
    local nPerc<const>, _, _, _, nProc<const>, nPeak<const> = CoreRAM();
    -- Get player one data
    local iMoney1<const> = aActivePlayer.M;
    local iDiggers1<const> = aActivePlayer.DC;
    local iGems1<const> = aActivePlayer.GEM;
    local iDug1<const> = aActivePlayer.DUG;
    -- Get player two data
    local iMoney2<const> = aOpponentPlayer.M;
    local iDiggers2<const> = aOpponentPlayer.DC;
    local iGems2<const> = aOpponentPlayer.GEM;
    local iDug2<const> = aOpponentPlayer.DUG;
    -- Draw HUD text
    local nFade1, nFade2, nR, nG, nB;
    if iMoney1 > iMoney2 then
      nFade1, nFade2, nR, nG, nB = 1, 0.75, 1, 0.6, 0.7;
    elseif iMoney2 > iMoney1 then
      nFade1, nFade2, nR, nG, nB = 0.75, 1, 0.24, 0.8, 0.4;
    elseif iDiggers1 > iDiggers2 then
      nFade1, nFade2, nR, nG, nB = 1, 0.75, 1, 0.6, 0.7;
    elseif iDiggers2 > iDiggers1 then
      nFade1, nFade2, nR, nG, nB = 0.75, 1, 0.24, 0.8, 0.4;
    elseif iGems1 > iGems2 then
      nFade1, nFade2, nR, nG, nB = 1, 0.75, 1, 0.6, 0.7;
    elseif iGems2 > iGems1 then
      nFade1, nFade2, nR, nG, nB = 0.75, 1, 0.24, 0.8, 0.4;
    elseif iDug1 > iDug2 then
      nFade1, nFade2, nR, nG, nB = 1, 0.75, 1, 0.6, 0.7;
    elseif iDug2 > iDug1 then
      nFade1, nFade2, nR, nG, nB = 0.75, 1, 0.24, 0.8, 0.4;
    else
      nFade1, nFade2, nR, nG, nB = 1, 1, 1, 1, 1;
    end
    texSpr:SetCRGBA(nR, nG, nB, 1);
    texSpr:BlitSLTRB(1022, 159, 198, 160, 234);
    texSpr:SetCRGB(0, 0, 0);
    texSpr:BlitSLTRB(1022, 160, 199, 161, 235);
    texSpr:SetCRGB(1, 1, 1);
    -- Draw engine info
    fontTiny:SetCRGBA(1, 0.6, 0.7, nFade1);
    fontTiny:PrintR(155, 210, aActivePlayer.RD.LONGNAME);
    fontTiny:SetCRGBA(0.24, 0.8, 0.4, nFade2);
    fontTiny:Print(165, 210, aOpponentPlayer.RD.LONGNAME);
    fontTiny:SetCRGBA(1, 1, 1, 1);
    fontTiny:Print(iStageL + 5, 193, format(
      "FPS  %7.3f\n\z
       CPUP %7.3f %%\n\z
       RAMP %7.3f M\n\z
       PEAK %7.3f M\n\z
       LUA  %7.3f M\n\z
       CPUS %7.3f %%\n\z
       RAMS %7.3f %%\n\z",
      nGPUFramesPerSecond, nCpu, nProc / 1048576, nPeak / 1048576,
      CoreLUAUsage() / 1048576, nSys, nPerc));
    -- Draw viewport info
    fontTiny:Print(iStageL + 5, 5,
      format("VPXC %4d/%4d\n\z
              VPXT %4d/%4d\n\z
              VCPX %4d/%4d\n\z
              APOS %4d/%4d\n\z
              ACPS %4d/%4d\n\z
              AMAX %4d/%4d",
        iPixPosX, iPixPosY,
        iPixPosTargetX, iPixPosTargetY,
        iPixCenPosX, iPixCenPosY,
        iPosX, iPosY,
        iAbsCenPosX, iAbsCenPosY,
        iViewportW, iViewportH));
    -- Draw level and duration info
    fontTiny:PrintR(iStageR - 5, 187,
      format(         "%s [%02u]\n\z
                         %s TYPE\n\z
                         %u TWIN\n\z
                         %u OBJT\n\z
                         %u FRAM\n\z
          %02u:%02u:%06.03f GAME\n\z
          %02u:%02u:%06.03f LUAT\n\z
          %02u:%02u:%06.03f ENGT",
        sLevelName, iLevelId,
        sLevelType,
        iWinLimit,
        #aObjects,
        GetGameTicks(),
        GetGameTicks() // 216000 % 1000,
        GetGameTicks() // 3600 % 60,
        GetGameTicks() / 60 % 60,
        CoreLUATime() // 3600 % 1000,
        CoreLUATime() // 60 % 60,
        CoreLUATime() % 60,
        CoreUptime() // 3600 % 1000,
        CoreUptime() // 60 % 60,
        CoreUptime() % 60));
    -- Flash debug mode
    fontTiny:PrintR(iStageR - 5, 5, "DEBUG MODE");
    -- Draw gems and dug count
    fontLittle:SetCRGBA(1, 1, 1, nFade1);
    fontLittle:PrintR(155, 198, "("..iGems1..") "..iDug1);
    fontLittle:SetCA(nFade2);
    fontLittle:Print(165, 198, iDug2.." ("..iGems2..")");
    -- Animate player one's money
    if iAnimMoney ~= iMoney1 then
      -- Animated money over actual money?
      if iAnimMoney > iMoney1 then
        -- Decrement it
        iAnimMoney = iAnimMoney - ceil((iAnimMoney - iMoney1) * 0.1);
        -- Update displayed money
        sMoney = min(9999, iAnimMoney);
        -- Red colour and draw money
        fontLarge:SetCRGBA(1, 0.75, 0.75, nFade1);
        fontLarge:Print(15, 220, sMoney);
      -- Animated money under actual money? Increment
      elseif iAnimMoney < iMoney1 then
        -- Increment it
        iAnimMoney = iAnimMoney + ceil((iMoney1 - iAnimMoney) * 0.1);
        -- Update displayed money
        sMoney = min(9999, iAnimMoney);
        -- Green colour and draw money
        fontLarge:SetCRGBA(0.75, 1, 0.75, nFade1);
        fontLarge:PrintR(155, 219, sMoney);
      -- No change so set white font
      else
        -- Set money
        iAnimMoney, sMoney = iMoney1, iMoney1;
        -- Reset colour and draw money
        fontLarge:SetCRGBA(1, 1, 1, nFade1);
        fontLarge:PrintR(155, 219, sMoney);
      end
    -- Normal display
    else
      -- Reset colour and draw money
      fontLarge:SetCRGBA(1, 1, 1, nFade1);
      fontLarge:PrintR(155, 219, sMoney);
    end
    -- Animate player one's money
    if iOppAnimMoney ~= iMoney2 then
      -- Animated money over actual money?
      if iOppAnimMoney > iMoney2 then
        -- Decrement it
        iOppAnimMoney = iOppAnimMoney - ceil((iOppAnimMoney - iMoney2) * 0.1);
        -- Update displayed money
        sOppMoney = min(9999, iOppAnimMoney);
        -- Red colour and draw money
        fontLarge:SetCRGBA(1, 0.75, 0.75, nFade2);
        fontLarge:Print(165, 219, sOppMoney);
      -- Animated money under actual money? Increment
      elseif iOppAnimMoney < iMoney2 then
        -- Increment it
        iOppAnimMoney = iOppAnimMoney + ceil((iMoney2 - iOppAnimMoney) * 0.1);
        -- Update displayed money
        sOppMoney = min(9999, iOppAnimMoney);
        -- Green colour and draw money
        fontLarge:SetCRGBA(0.75, 1, 0.75, nFade2);
        fontLarge:Print(165, 219, sOppMoney);
      -- No change so set white font
      else
        -- Set money
        iOppAnimMoney, sMoney = iMoney2, iMoney2;
        -- Reset colour and draw money
        fontLarge:SetCRGBA(1, 1, 1, nFade2);
        fontLarge:Print(165, 219, sOppMoney);
      end
    -- Normal display
    else
      -- Reset colour and draw money
      fontLarge:SetCRGBA(1, 1, 1, nFade2);
      fontLarge:Print(165, 219, sOppMoney);
    end
  end
  -- Finished playing this zone
  local function Finish()
    -- When level has faded out?
    local function OnFadeOut()
      -- Unregister frame buffer update event
      RegisterFBUCallback("debug");
      -- Load a new level
      InitDebugPlay();
    end
    -- Fade out to load a new level
    Fade(0, 1, 0.04, OnRenderRandom, OnFadeOut);
  end
  -- Callbacks to use
  local fcbTCallback, fcbRCallback, fcbICallback;
  -- Infinite play tick callback
  local function OnTickRandomInitialise()
    -- For each player...
    for iPlayerId = 1, #aPlayers do
      -- Get player
      local aPlayer<const> = aPlayers[iPlayerId];
      -- Set remove shroud mode
      aPlayer.US = true;
      -- Get and enumerate player diggers
      local aDiggers<const> = aPlayer.D;
      for iDiggerId = 1, #aDiggers do
        -- Get digger
        local aDigger<const> = aDiggers[iDiggerId];
        -- Set remove shroud mode
        aDigger.US = true;
        UpdateShroud(aDigger.AX, aDigger.AY);
      end
    end
    -- Store mouse position
    local iX, iY, iNextObjectPoll = GetMouseX(), GetMouseY(), 0;
    -- Set real function
    local function OnTickRandom()
      -- Switch level after an hour
      if GetGameTicks() >= 216000 then return Finish() end;
      -- Do these checks every second
      if GetGameTicks() % 60 == 0 then
        -- ...or someone wins? Check each player
        for iPlayerId = 1, #aPlayers do
          -- Get player data and load a new level if this player...
          local aPlayer<const> = aPlayers[iPlayerId];
          if (aPlayer.M <= 100 and        -- ...(Is stuck on 100 Zogs
              GetGameTicks() >= 36840) or -- ...*and* it's been 10 minutes?)
             HaveZogsToWin(aPlayer) then  -- ...*or* player has won?
            return Finish() end;
        end
      end
      -- If we're blocked from polling objects then don't
      if GetGameTicks() < iNextObjectPoll then GameProc();
      -- Not blocked from selecting new objects?
      else
        -- Mouse position changed?
        local iNewX<const>, iNewY<const> = GetMouseX(), GetMouseY();
        if iNewX ~= iX or iNewY ~= iY then
          -- Update new position and block time for 10 seconds
          iX, iY, iNextObjectPoll = iNewX, iNewY, GetGameTicks() + 600;
          -- Don't cycle objects
          GameProc();
        -- Mouse position still same so cycle objects
        else OnTick() end;
      end
    end
    -- Set real function
    SetCallbacks(OnTickRandom, fcbRCallback, fcbICallback);
  end
  if iId then
    fcbTCallback, fcbRCallback, fcbICallback = OnTick, OnRender, nil;
  else
    iId, fcbTCallback, fcbRCallback, fcbICallback =
      random(#aLevelsData), OnTickRandomInitialise, OnRenderRandom, ProcInput;
  end
  -- Load infinite play (AI vs AI)
  LoadLevel(iId, "game", -1, nil, true, nil, true, fcbTCallback, fcbRCallback,
    fcbICallback);
  -- Play sound effects
  SetPlaySounds(true);
end
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  BCBlit, Fade, GameProc, GetActiveObject, GetActivePlayer, GetGameTicks,
    GetLevelInfo, GetMouseX, GetMouseY, GetOpponentPlayer, GetViewportData,
    HaveZogsToWin, LoadLevel, ProcInput, RegisterFBUCallback, RenderObjects,
    RenderShroud, RenderTerrain, SelectObject, SetCallbacks, SetPlaySounds,
    UpdateShroud, aLevelsData, aObjects, aPlayers, fontLarge, fontLittle,
    fontTiny, texSpr =
      GetAPI("BCBlit", "Fade", "GameProc", "GetActiveObject",
        "GetActivePlayer", "GetGameTicks", "GetLevelInfo", "GetMouseX",
        "GetMouseY", "GetOpponentPlayer", "GetViewportData", "HaveZogsToWin",
        "LoadLevel", "ProcInput", "RegisterFBUCallback", "RenderObjects",
        "RenderShroud", "RenderTerrain", "SelectObject", "SetCallbacks",
        "SetPlaySounds", "UpdateShroud", "aLevelsData", "aObjects", "aPlayers",
        "fontLarge", "fontLittle", "fontTiny", "texSpr");
end
-- Exports and imports ----------------------------------------------------- --
return { F = OnReady, A = { InitDebugPlay = InitDebugPlay } };
-- End-of-File ============================================================= --

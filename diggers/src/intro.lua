-- INTRO.LUA =============================================================== --
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
local error<const> = error;
-- M-Engine function aliases ----------------------------------------------- --
local UtilBlank<const>, CoreTime<const>, UtilIsInteger<const> =
  Util.Blank, Core.Time, Util.IsInteger;
-- Diggers function and data aliases --------------------------------------- --
local Fade, GetCallbacks, InitSetup, InitTitle, IsButtonPressed, LoadResources,
  RegisterFBUCallback, RenderFade,  RenderShadow, SetCallbacks, VideoPlay,
  VideoStop, aIntroSubTitles, fontLittle, texSpr;
-- Resources --------------------------------------------------------------- --
local aAssets<const> = { { T = 1, F = "grass", P= { 16, 16, 0, 0, 0 } },
                         { T = 2, F = "title", P= { 0 } },
                         { T = 8, F = "intro", P= { } } };
-- Intro initialisation function ------------------------------------------- --
local function InitIntro(bAndSetup)
  -- When intro resources have loaded?
  local function OnLoaded(aResources)
    -- Subtitle position
    local iStageST = 0;
    -- Register frame buffer update
    local iStageW, iStageH, iStageL, iStageT, iStageR, iStageB;
    local function OnFrameBufferUpdate(...)
      iStageW, iStageH, iStageL, iStageT, iStageR, iStageB = ...;
      iStageST = iStageL + (iStageW / 2);
    end
    RegisterFBUCallback("intro", OnFrameBufferUpdate);
    -- Get the texture handle that was loaded
    local tTiles, tTitle = aResources[1].H, aResources[2].H;
    tTitle:TileS(0, 0, 0, 512, 240);
    tTitle:TileA(227, 240, 285, 448);
    -- Load and play intro video
    local vVideo = aResources[3].H;
    vVideo:SetFilter(false);
    -- Subtitles list
    local iSubTitle, iFrameEnd = 1, math.maxinteger;
    -- Get font size
    local iFWidth<const>, iFHeight<const>, iPadding<const> =
      fontLittle:GetWidth(), fontLittle:GetHeight(), 5;
    -- For each credit
    for iI = 1, #aIntroSubTitles do
      -- Get subtitle item and we must have at least 3 leans
      local aSubTitle<const> = aIntroSubTitles[iI];
      -- Check parameter count
      if #aSubTitle < 3 then error("Not enough items on "..iI.."!") end;
      if #aSubTitle > 4 then error("Too many items on "..iI.."!") end;
      -- Verify frame start
      local iFrStart<const> = aSubTitle[1];
      if not UtilIsInteger(iFrStart) or iFrStart < 0 then
        error("Invalid start '"..tostring(iFrStart).."' on "..iI.."!") end;
      -- Verify frame end
      local iFrEnd<const> = aSubTitle[1];
      if not UtilIsInteger(iFrEnd) or iFrEnd < 0 then
        error("Invalid end '"..tostring(iFrEnd).."' on "..iI.."!") end;
      -- Get subtitles
      local aSubTitleTexts<const> = aSubTitle[3];
      local sSubTitle1<const> = aSubTitleTexts[1];
      local sSubTitle2<const> = aSubTitleTexts[2];
      -- Calculate length of first subtitle and if we have 2nd subtitle?
      local iWidth = #sSubTitle1 * iFWidth;
      if sSubTitle2 then
        -- Which subtitle is longest?
        iWidth = math.max(iWidth, #sSubTitle2 * iFWidth);
        -- Insert first and second subtitle Y position
        aSubTitle[1 + #aSubTitle] = 200; -- [4]
        aSubTitle[1 + #aSubTitle] = 210; -- [5]
      else
        -- Insert first and second (n/a) subtitle Y position
        aSubTitle[1 + #aSubTitle] = 206; -- [4]
        aSubTitle[1 + #aSubTitle] = 206; -- [5]
      end
      -- Insert half width of subtitle box plus padding
      aSubTitle[1 + #aSubTitle] = (iWidth / 2) + iPadding; -- [6]
      -- Insert top position of subtitle box minus padding
      aSubTitle[1 + #aSubTitle] = aSubTitle[4] - iPadding; -- [7]
      -- Insert bottom position of subtitle box plus font height plus padding
      aSubTitle[1 + #aSubTitle] = aSubTitle[5] + iFHeight + iPadding; -- [8]
    end
    -- Set first active subtitle to wait for
    local aSubTitle = aIntroSubTitles[iSubTitle];
    -- Background fade bounds and current subtitles being displayed
    local iFadeX, iFadeY1, iFadeY2, sSubTitle1, sSubTitle2;;
    -- Sub-title Y positions
    local iSubTitle1, iSubTitle2;
    -- Playing procedure()
    local function PlayingProc()
      -- If we're not in widescreen?
      if iStageL == 0 then
        -- Draw video normally
        vVideo:SetTCLTRB(0, 0, 1, 1);
        vVideo:SetVLTRB(0, 0, 320, 240);
        vVideo:Blit();
      -- In widescreen?
      else
        -- Draw video effect for widescreen (left side)
        vVideo:SetTCLTRB(0, 0, 0, 1);
        vVideo:SetVLTRB(0, 0, iStageL, 240);
        vVideo:Blit();
        -- Draw video effect for widescreen (right side)
        vVideo:SetTCLTRB(1, 0, 1, 1);
        vVideo:SetVLTRB(iStageR, 0, 320, 240);
        vVideo:Blit();
        -- Draw the actual video in the centre (4:3)
        vVideo:SetTCLTRB(0, 0, 1, 1);
        vVideo:SetVLTRB(0, 0, 320, 240);
        vVideo:Blit();
        -- Draw transparent tiles over the top of the widescreen border
        tTiles:SetCRGBA(1, 1, 1, 0.5);
        for iY = 0, 240, 16 do
          for iX = -16, iStageL-16, -16 do tTiles:BlitSLT(3, iX, iY) end;
          for iX = 320, iStageR, 16 do tTiles:BlitSLT(3, iX, iY) end;
        end
        -- Draw shadow
        texSpr:BlitSLTRB(1017, -16, iStageT,   0, iStageB);
        texSpr:BlitSLTRB(1018, 320, iStageT, 336, iStageB);
      end
      -- Get frame number
      local iFrame<const> = vVideo:GetFrame();
      -- Have subtitle?
      if sSubTitle1 then
        -- Calculate iX position of rectangle
        local iFadeX1<const> = iStageST - iFadeX;
        local iFadeX2<const> = iStageST + iFadeX;
        -- Draw subtitle background and shadow
        RenderFade(0.75, iFadeX1, iFadeY1, iFadeX2, iFadeY2);
        RenderShadow(iFadeX1, iFadeY1, iFadeX2, iFadeY2);
        -- Draw subtitle
        fontLittle:PrintC(iStageST, iSubTitle1, sSubTitle1);
        -- If we have subtitle two
        if sSubTitle2 then
          fontLittle:PrintC(iStageST, iSubTitle2, sSubTitle2);
        end
        -- Hide subtitle if timed out
        if iFrame >= iFrameEnd then sSubTitle1, sSubTitle2 = nil, nil end;
      end
      -- Get next subtitle data (fontLittle:PrintC(iStageST, 170, iFrame);)
      if iFrame >= aSubTitle[1] then
        -- Grab new fade bounds
        iFadeX, iFadeY1, iFadeY2 = aSubTitle[6], aSubTitle[7], aSubTitle[8];
        -- Set subtitle position
        iSubTitle1, iSubTitle2 = aSubTitle[4], aSubTitle[5];
        -- Set new subtile, ending time and next id
        sSubTitle1, sSubTitle2, iFrameEnd =
          aSubTitle[3][1], aSubTitle[3][2], aSubTitle[2];
        -- Set next sub-title to monitor
        iSubTitle = iSubTitle + 1;
        aSubTitle = aIntroSubTitles[iSubTitle] or { math.maxinteger };
      end
    end
    -- Not playing procedure
    local function NotPlayingProc()
      -- Draw background
      tTitle:SetCRGBA(1, 1, 1, 1);
      tTitle:BlitLT(-96, 0);
      -- Don't draw anything if in 4:3 mode
      if iStageL >= 0 then return end;
      -- Draw sidebar scrolling logo's
      local iWidth<const> = -iStageL - 4;
      local nAspect<const> = 208 / 58;
      local nHeight<const> = iWidth * nAspect;
      local iLX = (CoreTime() * 100) % 240;
      local iLY = -iLX;
      local iX<const> = iStageL + 4;
      local iXpWidth<const> = iX + iWidth;
      local nHeightPiLX = nHeight + iLX;
      local nHeightPiLY = nHeight + iLY;
      local iXRight<const> = 320 + iWidth;
      tTitle:SetCA(0.25);
      tTitle:BlitSLTRB(1, iX, -240+iLX, iXpWidth, -240 + nHeightPiLX);
      tTitle:BlitSLTRB(1, iX,      iLX, iXpWidth,        nHeightPiLX);
      tTitle:BlitSLTRB(1, iX,  240+iLX, iXpWidth,  240 + nHeightPiLX);
      tTitle:BlitSLTRB(1, iXRight,       nHeightPiLY, 320,       iLY);
      tTitle:BlitSLTRB(1, iXRight, 240 + nHeightPiLY, 320, 240 + iLY);
      tTitle:BlitSLTRB(1, iXRight, 480 + nHeightPiLY, 320, 480 + iLY);
      iLX = -iLX;
      iLY = -iLY - 240;
      nHeightPiLX = nHeight + iLX;
      nHeightPiLY = nHeight + iLY;
      tTitle:BlitSLTRB(1, iX, -240 + iLX, iXpWidth, -240 + nHeightPiLX);
      tTitle:BlitSLTRB(1, iX,        iLX, iXpWidth,        nHeightPiLX);
      tTitle:BlitSLTRB(1, iX,  240 + iLX, iXpWidth,  240 + nHeightPiLX);
      tTitle:BlitSLTRB(1, iXRight,       nHeightPiLY, 320,       iLY);
      tTitle:BlitSLTRB(1, iXRight, 240 + nHeightPiLY, 320, 240 + iLY);
      tTitle:BlitSLTRB(1, iXRight, 480 + nHeightPiLY, 320, 480 + iLY);
    end
    -- Render proc
    local fcbRender = NotPlayingProc;
    local function Render() fcbRender() end;
    -- Finish function
    local function Finish()
      -- Remove event function
      vVideo:OnEvent(UtilBlank);
      -- When video has faded out?
      local function OnFadeOut()
        -- Destroy video and texture handles
        VideoStop();
        -- Remove frame buffer update callback
        RegisterFBUCallback("intro");
        -- Dereference loaded assets for garbage collector
        tTiles, tTitle, vVideo = nil, nil, nil;
        -- Load title screen
        InitTitle();
      end
      -- Start fading out
      Fade(0, 1, 0.032, Render, OnFadeOut, true);
    end
    -- Play video and setup event
    local function PlayVideo()
      -- Get video events list and id's
      local aEvents<const> = Video.Events;
      local iStop<const>, iPause<const>, iPlay<const>, iFinish<const> =
        aEvents.STOP, aEvents.PAUSE, aEvents.PLAY, aEvents.FINISH;
      -- A video event occurred?
      local function OnEvent(iEvent)
        -- Playing?
        if iEvent == iPlay then
          -- If we were in our render loop? Transition to title screen
          if fcbRender == NotPlayingProc then fcbRender = PlayingProc end;
        -- Paused, stopped or finished?
        elseif iEvent == iPause or iEvent == iStop or iEvent == iFinish then
          -- We someone took our render callback (i.e. setup) then we need to
          -- to switch render proc
          local _, CBRender = GetCallbacks();
          if CBRender == Render then return Finish() end;
          -- If we were not in our render loop (i.e. setup?)
          fcbRender = NotPlayingProc;
        end
      end
      -- Set video event callback
      vVideo:OnEvent(OnEvent);
      -- Play the video
      VideoPlay(vVideo);
    end
    -- If not setup requested, we're done
    if not bAndSetup then PlayVideo() end;
    -- When video has faded in?
    local function OnFadeIn()
      -- Intro input procedure to just check if a button is pressed
      local function InputProc()
        if IsButtonPressed(0) then Finish() end;
      end
      -- Set intro callbacks
      SetCallbacks(nil, Render, InputProc);
      -- Load setup now
      if bAndSetup then PlayVideo() InitSetup() end;
    end
    -- Fade in
    Fade(1, 0, 0.025, Render, OnFadeIn);
  end
  -- Load resources asynchronously
  LoadResources("Intro", aAssets, OnLoaded);
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitIntro = InitIntro }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  Fade, GetCallbacks, InitSetup, InitTitle, IsButtonPressed, LoadResources,
  RegisterFBUCallback, RenderFade, RenderShadow, SetCallbacks, VideoPlay,
  VideoStop, aIntroSubTitles, fontLittle, texSpr
  = -- --------------------------------------------------------------------- --
  GetAPI("Fade", "GetCallbacks", "InitSetup", "InitTitle",  "IsButtonPressed",
    "LoadResources", "RegisterFBUCallback", "RenderFade", "RenderShadow",
    "SetCallbacks", "VideoPlay", "VideoStop", "aIntroSubTitles", "fontLittle",
    "texSpr");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

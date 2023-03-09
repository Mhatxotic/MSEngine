-- BOOK.LUA ================================================================ --
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
local ClampInt<const> = Util.ClampInt;
-- Diggers function and data aliases --------------------------------------- --
local LoadResources, Fade, SetCallbacks, IsMouseInBounds, IsMouseNotInBounds,
  SetCursor, PlayStaticSound, aSfxData, InitCon, PlayMusic, IsButtonPressed,
  IsButtonReleased, IsScrollingDown, IsScrollingUp, SetBottomRightTip,
  SetBottomRightTipAndShadow, RenderInterface, InitContinueGame, RenderShadow,
  GameProc, aCursorIdData;
-- Locals ------------------------------------------------------------------ --
local iBookPage = 0;                   -- Book current page (persisted)
local bIntroPage = false;              -- Intro page was displayed?
-- Assets ------------------------------------------------------------------ --
local aBookTexture<const>        = { T = 2, F = "book",   P = { 0 } };
local aLobbyOpenTexture<const>   = { T = 7, F = "lobby",  P = { 0 } };
local aLobbyClosedTexture<const> = { T = 2, F = "lobbyc", P = { 0 } };
local aAssets<const>             = { aBookTexture, false };
local aPageAsset<const>  = { { T = 1, F = false, P = { 255, 200, 0, 0, 0 } } };
-- Init book screen function ----------------------------------------------- --
local function InitBook(bFromInGame)
  -- Pages each sized 510x200 stored inside texture sized 1024^2. OpenGL 3.2
  -- guarantees us that 1024^2 textures are supported by every renderer.
  local iPagesPerTexture<const> = 20;
  -- Exit tip
  local strExitTip, strTip;
  -- Loading from in game?
  if bFromInGame then
    -- Set text for exit tip
    strExitTip = "BACK TO GAME";
    -- Load just the book texture
    aAssets[2] = aLobbyOpenTexture;
  -- Loading from controller screen?
  else
    -- Set text for exit tip
    strExitTip = "CONTROLLER";
    -- Load backdrop from closed lobby
    aAssets[2] = aLobbyClosedTexture;
  end
  -- When the resources have loaded
  local function OnLoadResources(aResources)
    -- Set texture and setup tiles
    local texBook, BookInput = aResources[1].H, nil;
    texBook:TileSTC(0);
    texBook:TileA(  0, 0, 304, 200); -- Cover
    texBook:TileA(305, 0, 360, 200); -- Spine
    -- Get lobby texture and setup background tile. This will be nil if loading
    -- from in-game so it doesn't matter. Already handled.
    local texLobby;
    if not bFromInGame then
      texLobby = aResources[2].H;
      texLobby:TileSTC(1);
      texLobby:TileS(0, 0, 272, 428, 512);
    -- Play music as we're coming from in game and save position
    else PlayMusic(aResources[2].H, nil, 1) end;
    -- Some vars
    local iFilePage, texPage, iTilePage;
    -- Book render background
    local function RenderBookBackground()
      -- If from controller?
      if bFromInGame then
        -- Render game interface
        RenderInterface();
        -- Draw tip
        SetBottomRightTip(strTip);
      else
        -- Render static background
        texLobby:BlitLT(-54, 0);
        -- Draw tip and return
        SetBottomRightTipAndShadow(strTip);
      end
      -- Render shadow
      RenderShadow(8, 8, 312, 208);
    end
    -- Book render callback
    local function RenderBook()
      -- Render book background
      RenderBookBackground();
      -- Draw spine
      texBook:BlitSLT(1, 8, 8);
      -- Draw backdrop
      texPage:BlitSLT(iTilePage, 57, 8);
    end
    -- Points of interest data
    local POIData;
    -- Total pages
    local iTotalPages<const> = 88;
    local iTotalPagesM1<const> = iTotalPages - 1;
    -- Page loader function
    local function LoadPage(iPage, fOnComplete)
      -- Set and clamp requested page
      iBookPage = ClampInt(iPage, 0, iTotalPagesM1);
      local iBookPageP1<const> = iBookPage + 1;
      -- Set displayed page number in POIData
      local strPage<const> = "PAGE "..iBookPageP1.."/"..iTotalPages;
      POIData[4][7] = strPage;
      -- Which texture page do we need and if we need to load it?
      local iLoadPage<const> = iBookPage // iPagesPerTexture;
      if iLoadPage == iFilePage and not fOnComplete then
        -- Set new page and actual page on texture
        iFilePage, iTilePage = iLoadPage, iBookPage % iPagesPerTexture;
        -- Update tip
        strTip = strPage;
        -- No need to do anything else
        return;
      end
      -- Set that we're loading
      strTip = "LOADING "..iBookPageP1;
      -- On loaded book assets
      local function OnPageLoaded(aResource)
        -- Set new page
        iFilePage = iLoadPage;
        -- Reset normal cursor
        SetCursor(aCursorIdData.ARROW);
        -- Set new page texture
        texPage = aResource[1].H;
        -- Set actual page on texture
        iTilePage = iBookPage % iPagesPerTexture;
        -- Call callback function if set on load completion
        if fOnComplete then return fOnComplete() end;
        -- If from controller?
        if bFromInGame then SetCallbacks(GameProc, RenderBook, BookInput);
                       else SetCallbacks(nil, RenderBook, BookInput) end;
      end
      -- Load the specified texture with the page image
      aPageAsset[1].F = "e/"..iLoadPage;
      LoadResources("The Book "..iLoadPage, aPageAsset, OnPageLoaded);
    end
    -- The render and input callbacks we have set
    local fRender, fInput;
    -- Set points of interest data
    POIData = {                                   -- Index
      { 17, 37, 70, 92, aCursorIdData.SELECT, aSfxData.CLICK, "CONTENTS",
        function() LoadPage(1) end },             -- Last
      { 17, 37, 96,118, aCursorIdData.SELECT, aSfxData.CLICK, "NEXT PAGE",
        function() LoadPage(iBookPage + 1) end }, -- Next
      { 17, 37,122,144, aCursorIdData.SELECT, aSfxData.CLICK, "LAST PAGE",
        function() LoadPage(iBookPage - 1) end }, -- Nada
      {  8,312,  8,208, aCursorIdData.ARROW,  nil,           nil,
        function() end }
    };
    -- Check if mouse in a POI item
    local function CursorInPOI(aData)
      -- Return failure if not in the given area
      if IsMouseNotInBounds(aData[1], aData[3], aData[2], aData[4])
        then return false end;
      -- Set tip
      strTip = aData[7];
      -- Success
      return true;
    end
    -- Activate a POI item
    local function ActivatePOI(aData)
      -- Play appropriate sound
      local sSound<const> = aData[6];
      if sSound then PlayStaticSound(sSound) end;
      -- Perform the action
      local fFunc<const> = aData[8];
      if fFunc then fFunc() end;
    end
    -- Cursor in exit area
    local function BookInputExitProc()
      -- Set exit tip
      strTip = strExitTip;
      -- Mouse is over the exit
      SetCursor(aCursorIdData.EXIT);
      -- Done if mouse button not clicked
      if IsButtonReleased(0) then return end;
      -- Play sound
      PlayStaticSound(aSfxData.SELECT);
      -- If from in game then continue the game
      if bFromInGame then
        -- Dereference assets for garbage collector
        texPage, texBook = nil, nil;
        -- Start the loading waiting procedure
        SetCallbacks(GameProc, RenderInterface, nil);
        -- Continue game
        return InitContinueGame(true);
      end;
      -- On faded event
      local function OnFadeOut()
        -- Dereference assets for garbage collector
        texPage, texBook, texLobby = nil, nil, nil;
        -- Init controller screen
        InitCon();
      end
      -- Fade out to controller
      Fade(0, 1, 0.04, fRender, OnFadeOut);
    end
    -- Set book input procedure
    local function OnBookInput()
      -- Get scroll wheel status and if mouse wheel moved down?
      if IsScrollingDown() then return ActivatePOI(POIData[3]) end;
      -- Mouse wheel moved up?
      if IsScrollingUp() then return ActivatePOI(POIData[2]) end;
      -- Iterate through the points of interest
      for iI = 1, #POIData do
        -- Get point of interest data and return if mouse is in this POI
        local aData = POIData[iI];
        if CursorInPOI(aData) then
          -- Show appropriate cursor
          SetCursor(aData[5]);
          -- Button pressed and data available?
          if IsButtonPressed(0) then return ActivatePOI(aData) end;
          -- Done
          return;
        end
      end
      -- Cursor in exit area
      BookInputExitProc();
    end
    -- Input book proc
    BookInput = OnBookInput;
    -- When page has loaded
    local function OnPageLoaded()
      -- If we've shown the intro page?
      if bIntroPage then fRender, fInput = RenderBook, BookInput;
      -- Not shown the intro page yet?
      else
        -- On render callback
        local function OnIntroRender()
          -- Render background
          RenderBookBackground();
          -- Draw backdrop
          texBook:BlitLT(8, 8);
        end
        -- On input callback
        local function OnIntroInput()
          -- In POI zone
          if CursorInPOI(POIData[4]) then
            -- Draw tip
            strTip = "OPEN";
            -- Set select cursor
            SetCursor(aCursorIdData.SELECT);
            -- Button pressed and data available?
            if IsButtonPressed(0) then
              -- Intro page confirmed
              bIntroPage = true;
              -- Set renderer to book page
              fRender = RenderBook;
              -- Play click sound
              PlayStaticSound(aSfxData.SELECT);
              -- If from controller?
              local fcbGameProc;
              if bFromInGame then fcbGameProc = GameProc end;
              SetCallbacks(fcbGameProc, RenderBook, BookInput);
            end
            -- Done
            return;
          end
          -- Cursor in exit area
          BookInputExitProc();
        end
        -- Set render callback
        fRender, fInput = OnIntroRender, OnIntroInput;
      end;
      -- If we're loading from in-game? We don't need to fade
      if bFromInGame then return SetCallbacks(GameProc, fRender, fInput) end;
      -- Function to call when finished fading in
      local function OnFadeIn()
        -- Return control to main loop
        SetCallbacks(nil, fRender, fInput);
      end
      -- From controller screen? Fade in
      Fade(1, 0, 0.04, fRender, OnFadeIn);
    end
    -- Load current page
    LoadPage(iBookPage, OnPageLoaded);
  end
  -- Load the resources
  LoadResources("The Book", aAssets, OnLoadResources);
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitBook = InitBook }, F = function(GetAPI)
  -- Imports --------------------------------------------------------------- --
  LoadResources, SetCallbacks, SetCursor, IsMouseInBounds, PlayStaticSound,
  Fade, IsMouseNotInBounds, aCursorIdData, aSfxData, InitCon, PlayMusic,
  IsButtonPressed, IsButtonReleased, IsScrollingDown, IsScrollingUp,
  SetBottomRightTip, SetBottomRightTipAndShadow, RenderInterface,
  InitContinueGame, RenderShadow, GameProc
  = -- --------------------------------------------------------------------- --
  GetAPI("LoadResources", "SetCallbacks", "SetCursor", "IsMouseInBounds",
    "PlayStaticSound", "Fade", "IsMouseNotInBounds", "aCursorIdData",
    "aSfxData", "InitCon", "PlayMusic", "IsButtonPressed", "IsButtonReleased",
    "IsScrollingDown", "IsScrollingUp", "SetBottomRightTip",
    "SetBottomRightTipAndShadow", "RenderInterface", "InitContinueGame",
    "RenderShadow", "GameProc");
  -- ----------------------------------------------------------------------- --
end };
-- End-of-File ============================================================= --

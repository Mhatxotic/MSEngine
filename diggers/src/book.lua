-- BOOK.LUA ================================================================ --
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
-- M-Engine function aliases ----------------------------------------------- --
local UtilBlank<const>, UtilClampInt<const> = Util.Blank, Util.ClampInt;
-- Diggers function and data aliases --------------------------------------- --
local Fade, GameProc, InitCon, InitContinueGame, IsButtonPressed,
  IsButtonReleased, IsMouseInBounds, IsMouseNotInBounds, IsScrollingDown,
  IsScrollingUp, LoadResources, PlayMusic, PlayStaticSound, RenderInterface,
  RenderShadow, SetBottomRightTip, SetBottomRightTipAndShadow, SetCallbacks,
  SetCursor, SetKeys;
-- Consts ------------------------------------------------------------------ --
-- Pages each sized 510x200 stored inside texture sized 1024^2. OpenGL 3.2
-- guarantees us that 1024^2 textures are supported by every renderer.
local iPagesPerTexture<const> = 20;
local iTotalPages<const> = 88;                -- Maximum number of pages
local iTotalPagesM1<const> = iTotalPages - 1; -- Maximum " minus one
-- Locals ------------------------------------------------------------------ --
local aPOIData;                        -- Points of interest data
local bCoverPage = true;               -- Cover page was displayed?
local fcbFinish,                       -- Callback to call to exit
      fcbCoverInput,                   -- Input callback for cover page
      fcbCoverRender,                  -- Render callback for cover page
      fcbOnCoverLoadResources,         -- Callback when cover handles loaded
      fcbOnCoverPageLoaded,            -- Callback when cover page loaded
      fcbPageInput,                    -- Main page input callback
      fcbPageLogic,                    -- Main page logic callback
      fcbRenderBackground;             -- Rendering background callback
local iBookPage = 0;                   -- Book current page (persisted)
local iCArrow, iCExit, iCOK, iCSelect, -- Cursor ids
      iFilePage, iTilePage,            -- File id and tile id
      iKeyBankCoverId,                 -- Key bank id for cover part
      iKeyBankPageId,                  -- Key bank id for pages part
      iKeyBankStartId,                 -- Key bank to set when cover page load
      iLoadPage,                       -- Current physical page
      iSClick, iSSelect;               -- Sound effects used
local strExitTip, strTip,              -- Tip strings
      texBook, texLobby, texPage;      -- Book, lobby and page texture handles
-- Assets ------------------------------------------------------------------ --
local aBookTexture<const>        = { T = 2, F = "book",   P = { 0 } };
local aLobbyOpenTexture<const>   = { T = 7, F = "lobby",  P = { 0 } };
local aLobbyClosedTexture<const> = { T = 2, F = "lobbyc", P = { 0 } };
local aAssets<const>             = { aBookTexture, false };
local aPageAsset<const>  = { { T = 1, F = false, P = { 255, 200, 0, 0, 0 } } };
-- Book render callback ---------------------------------------------------- --
local function PageRender()
  -- Render book background, spine and backdrop
  fcbRenderBackground();
  texBook:BlitSLT(1, 8, 8);
  texPage:BlitSLT(iTilePage, 57, 8);
end
-- Page texture texture handles loaded -------------------------------------- --
local function OnPageLoaded(aResource, fcbOnComplete)
  -- Set new page
  iFilePage = iLoadPage;
  -- Reset normal cursor
  SetCursor(iCArrow);
  -- Set new page texture
  texPage = aResource[1];
  -- Set actual page on texture
  iTilePage = iBookPage % iPagesPerTexture;
  -- Call callback function if set on load completion
  if fcbOnComplete then return fcbOnComplete() end;
  -- Enable keybank
  SetKeys(true, iKeyBankPageId);
  -- Run page loaded function
  SetCallbacks(fcbPageLogic, PageRender, fcbPageInput);
end
-- Page loader function ---------------------------------------------------- --
local function LoadPage(iPage, fcbOnComplete)
  -- Set and clamp requested page
  iBookPage = UtilClampInt(iPage, 0, iTotalPagesM1);
  local iBookPageP1<const> = iBookPage + 1;
  -- Set displayed page number in aPOIData
  local strPage<const> = "PAGE "..iBookPageP1.."/"..iTotalPages;
  aPOIData[4][7] = strPage;
  -- Which texture page do we need and if we need to load it?
  iLoadPage = iBookPage // iPagesPerTexture;
  if iLoadPage == iFilePage and not fcbOnComplete then
    -- Set new page and actual page on texture
    iFilePage, iTilePage = iLoadPage, iBookPage % iPagesPerTexture;
    -- Update tip
    strTip = strPage;
    -- No need to do anything else
    return;
  end
  -- Set that we're loading
  strTip = "LOADING "..iBookPageP1;
  -- Load the specified texture with the page image
  aPageAsset[1].F = "e/"..iLoadPage;
  LoadResources("The Book "..iLoadPage,
    aPageAsset, OnPageLoaded, fcbOnComplete);
end
-- Check if mouse in a POI item -------------------------------------------- --
local function CursorInPOI(aData)
  -- Return failure if not in the given area
  if IsMouseNotInBounds(aData[1], aData[3], aData[2], aData[4])
    then return false end;
  -- Set tip
  strTip = aData[7];
  -- Success
  return true;
end
-- Activate a POI item ----------------------------------------------------- --
local function ActivatePOI(aData)
  -- Play appropriate sound
  local sSound<const> = aData[6];
  if sSound then PlayStaticSound(sSound) end;
  -- Perform the action
  local fcbFunc<const> = aData[8];
  if fcbFunc then fcbFunc() end;
end
-- Cursor in exit area ----------------------------------------------------- --
local function PageExitCheck()
  -- Set exit tip
  strTip = strExitTip;
  -- Mouse is over the exit
  SetCursor(iCExit);
  -- Done if mouse button not clicked
  if IsButtonReleased(0) then return end;
  -- Call ening callback
  fcbFinish();
end
-- Set book input procedure ------------------------------------------------ --
local function PageInput()
  -- Get scroll wheel status and if mouse wheel moved down?
  if IsScrollingDown() then return ActivatePOI(aPOIData[3]) end;
  -- Mouse wheel moved up?
  if IsScrollingUp() then return ActivatePOI(aPOIData[2]) end;
  -- Iterate through the points of interest
  for iI = 1, #aPOIData do
    -- Get point of interest data and return if mouse is in this POI
    local aData<const> = aPOIData[iI];
    if CursorInPOI(aData) then
      -- Show appropriate cursor
      SetCursor(aData[5]);
      -- Button pressed and data available?
      if IsButtonPressed(0) then ActivatePOI(aData) end;
      -- Done
      return;
    end
  end
  -- Check if cursor in exit area
  PageExitCheck();
end
-- On render callback ------------------------------------------------------ --
local function CoverPageRender()
  -- Render background
  fcbRenderBackground();
  -- Draw backdrop
  texBook:BlitLT(8, 8);
end
-- Change cover to inside the book ----------------------------------------- --
local function CoverToPage()
  -- Cover page confirmed
  bCoverPage = false;
  -- Set renderer to book page
  fcbCoverRender = PageRender;
  -- Play click sound
  PlayStaticSound(iSSelect);
  -- Set page keys
  SetKeys(true, iKeyBankPageId);
  -- Set main page game proc
  SetCallbacks(fcbPageLogic, PageRender, PageInput);
end
-- On input callback ------------------------------------------------------- --
local function CoverPageInput()
  -- In POI zone
  if CursorInPOI(aPOIData[4]) then
    -- Draw tip
    strTip = "OPEN";
    -- Set select cursor
    SetCursor(iCSelect);
    -- Button pressed and data available?
    if IsButtonPressed(0) then CoverToPage() end;
    -- Done
    return;
  end
  -- Check if cursor in exit area
  PageExitCheck();
end
-- When cover page has loaded ---------------------------------------------- --
local function OnCoverPageLoaded()
  -- If we've shown the cover page?
  if bCoverPage == false then
    -- Set page keybank and callbacks
    iKeyBankStartId = iKeyBankPageId;
    fcbCoverRender, fcbCoverInput = PageRender, fcbPageInput;
  -- Not shown the cover page yet? Set render callback
  else
    -- Set cover page keybank and callbanks
    iKeyBankStartId = iKeyBankCoverId;
    fcbCoverRender, fcbCoverInput = CoverPageRender, CoverPageInput;
  end
  -- Cover has loaded
  fcbOnCoverPageLoaded();
end
-- When the resources have loaded ------------------------------------------ --
local function OnCoverLoadResources(aResources)
  -- Set texture and setup tiles
  texBook = aResources[1];
  texBook:TileSTC(0);
  texBook:TileA(  0, 0, 304, 200); -- Cover
  texBook:TileA(305, 0, 360, 200); -- Spine
  -- Call supplimental load routine depending if we're in-game or not
  fcbOnCoverLoadResources(aResources[2]);
  -- Input book proc
  fcbPageInput = PageInput;
  -- Load current page
  LoadPage(iBookPage, OnCoverPageLoaded);
end
-- Set render background function ------------------------------------------ --
local function PageRenderBackgroundInGame()
  -- Render game interface
  RenderInterface();
  -- Draw tip
  SetBottomRightTip(strTip);
  -- Render shadow
  RenderShadow(8, 8, 312, 208);
end
-- Set render background function ------------------------------------------ --
local function PageRenderBackgroundLobby()
  -- Render static background
  texLobby:BlitLT(-54, 0);
  -- Draw tip and return
  SetBottomRightTipAndShadow(strTip);
end
-- Cover loaded in-game supplimental callback ------------------------------ --
local function OnCoverPageLoadedInGame()
  -- Set intro page keys
  SetKeys(true, iKeyBankStartId);
  -- No transition from in-game
  SetCallbacks(GameProc, fcbCoverRender, fcbCoverInput);
end
-- Cover loaded in-lobby supplimental callback ----------------------------- --
local function OnCoverPageLoadedLobby()
  -- Cover data loaded?
  local function OnCoverDataLoaded()
    -- Set intro page keys
    SetKeys(true, iKeyBankStartId);
    -- Return control to main loop
    SetCallbacks(nil, fcbCoverRender, fcbCoverInput);
  end
  -- From controller screen? Fade in
  Fade(1, 0, 0.04, fcbCoverRender, OnCoverDataLoaded);
end
-- Finish in-game supplimental callback ------------------------------------ --
local function FinishInGame()
  -- Play sound
  PlayStaticSound(iSSelect);
  -- Dereference assets for garbage collector
  texPage, texBook = nil, nil;
  -- Start the loading waiting procedure
  SetCallbacks(GameProc, RenderInterface, nil);
  -- Continue game
  InitContinueGame(true);
end
-- Finish in-lobby supplimental callback ----------------------------------- --
local function FinishLobby()
  -- Play sound
  PlayStaticSound(iSSelect);
  -- On faded event
  local function OnFadeOut()
    -- Dereference assets for garbage collector
    texPage, texBook, texLobby = nil, nil, nil;
    -- Init controller screen
    InitCon();
  end
  -- Fade out to controller
  Fade(0, 1, 0.04, fcbCoverRender, OnFadeOut);
end
-- Lobby cover resources laoded -------------------------------------------- --
local function OnCoverResoucesLoadedLobby(texHandle)
  -- Get lobby texture and setup background tile. This will be nil if loading
  -- from in-game so it doesn't matter. Already handled.
  texLobby = texHandle;
  texLobby:TileSTC(1);
  texLobby:TileS(0, 0, 272, 428, 512);
end
-- In-Game cover resources laoded ------------------------------------------ --
local function OnCoverResoucesLoadedInGame(musHandle)
  -- Play music as we're coming from in game and save position
  PlayMusic(musHandle, nil, 1);
end
-- Init from in-game ------------------------------------------------------- --
local function InitBookInGame()
  -- Set text for exit tip
  strExitTip = "BACK TO GAME";
  -- Load just the book texture
  aAssets[2] = aLobbyOpenTexture;
  -- Set specific behaviour from in-game
  fcbOnCoverLoadResources = OnCoverResoucesLoadedInGame;
  fcbOnCoverPageLoaded = OnCoverPageLoadedInGame;
  fcbRenderBackground = PageRenderBackgroundInGame;
  fcbPageLogic = GameProc;
  fcbFinish = FinishInGame;
end
-- Init from lobby --------------------------------------------------------- --
local function InitBookLobby()
  -- Set text for exit tip
  strExitTip = "CONTROLLER";
  -- Load backdrop from closed lobby
  aAssets[2] = aLobbyClosedTexture;
  -- Set specific behaviour from the lobby
  fcbOnCoverLoadResources = OnCoverResoucesLoadedLobby
  fcbOnCoverPageLoaded = OnCoverPageLoadedLobby;
  fcbRenderBackground = PageRenderBackgroundLobby;
  fcbPageLogic = UtilBlank;
  fcbFinish = FinishLobby;
end
-- Init book screen function ----------------------------------------------- --
local function InitBook(bFromInGame)
  -- Loading from in-game or from lobby?
  if bFromInGame then InitBookInGame() else InitBookLobby() end;
  -- Load the resources
  LoadResources("The Book", aAssets, OnCoverLoadResources);
end
-- Scripts have been loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Grab imports
  Fade, GameProc, InitCon, InitContinueGame, IsButtonPressed, IsButtonReleased,
    IsMouseInBounds, IsMouseNotInBounds, IsScrollingDown,IsScrollingUp,
    LoadResources, PlayMusic, PlayStaticSound, RenderInterface, RenderShadow,
    SetBottomRightTip, SetBottomRightTipAndShadow, SetCallbacks, SetCursor,
    SetKeys =
      GetAPI("Fade", "GameProc", "InitCon", "InitContinueGame",
        "IsButtonPressed", "IsButtonReleased", "IsMouseInBounds",
        "IsMouseNotInBounds", "IsScrollingDown", "IsScrollingUp",
        "LoadResources", "PlayMusic", "PlayStaticSound", "RenderInterface",
        "RenderShadow", "SetBottomRightTip", "SetBottomRightTipAndShadow",
        "SetCallbacks", "SetCursor", "SetKeys");
  -- POI Callbacks
  local function GoContents() LoadPage(1) end;
  local function GoLast() LoadPage(iBookPage - 1) end;
  local function GoNext() LoadPage(iBookPage + 1) end;
  -- Key Callbacks
  local function KeyContents() PlayStaticSound(iSClick) GoContents() end;
  local function KeyLast() PlayStaticSound(iSClick) GoLast() end;
  local function KeyNext() PlayStaticSound(iSClick) GoNext() end;
  -- Register keybinds
  local RegisterKeys<const> = GetAPI("RegisterKeys");
  local aKeys<const> = Input.KeyCodes;
  local iPress<const> = Input.States.PRESS;
  local function Finish() fcbFinish() end
  local aClose<const> = { aKeys.ESCAPE, Finish, "zmtctbcl", "CLOSE" };
  local sName<const> = "ZMTC BOOK";
  iKeyBankPageId = RegisterKeys(sName, {
    [iPress] = {
      aClose,
      { aKeys.LEFT, KeyLast, "zmtctbpp", "PREVIOUS PAGE" },
      { aKeys.RIGHT, KeyNext, "zmtctbnp", "NEXT PAGE" },
      { aKeys.BACKSPACE, KeyContents, "zmtctbc", "CONTENTS" },
    }
  });
  iKeyBankCoverId = RegisterKeys(sName, {
    [iPress] = { aClose, { aKeys.ENTER, CoverToPage, "zmtcbob", "OPEN BOOK" } }
  });
  -- Set sound effect ids
  local aSfxData<const> = GetAPI("aSfxData");
    iSClick, iSSelect = aSfxData.CLICK, aSfxData.SELECT;
  -- Set cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCOK, iCSelect, iCExit, iCArrow = aCursorIdData.OK, aCursorIdData.SELECT,
    aCursorIdData.EXIT, aCursorIdData.ARROW;
  -- Set points of interest data
  aPOIData = {
    { 17,  37,  70,  92, iCSelect, iSClick, "CONTENTS",  GoContents }, -- Index
    { 17,  37,  96, 118, iCSelect, iSClick, "NEXT PAGE", GoNext },     -- Next
    { 17,  37, 122, 144, iCSelect, iSClick, "LAST PAGE", GoLast },     -- Last
    {  8, 312,   8, 208, iCArrow,  nil,     nil,         UtilBlank }   -- Dummy
  };
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitBook = InitBook }, F = OnReady };
-- End-of-File ============================================================= --

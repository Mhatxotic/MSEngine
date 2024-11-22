-- POST.LUA ================================================================ --
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
local InputSetCursorPos<const>, UtilTableSize<const>, UtilIsInteger<const> =
  Input.SetCursorPos, Util.TableSize, Util.IsInteger;
-- Diggers function and data aliases --------------------------------------- --
local AdjustViewPortX, AdjustViewPortY, Fade, GetAbsMousePos, InitEnding,
  InitFail, InitLobby, IsButtonHeld, IsButtonPressed, IsButtonReleased,
  IsMouseInBounds, IsMouseNotInBounds, IsMouseXGreaterEqualThan,
  IsMouseXLessThan, IsMouseYGreaterEqualThan, IsMouseYLessThan, IsScrollingUp,
  IsScrollingDown, IsSpriteCollide, LoadResources, PlayMusic, PlayStaticSound,
  RenderFade, RenderObjects, RenderTerrain, SelectObject, SetCallbacks,
  SetCursor, aGlobalData, aLevelsData, aObjectFlags, aObjects, fontSpeech,
  SetKeys;
-- Resources --------------------------------------------------------------- --
local aAssets<const> = { { T = 2, F = "end", P = { 0 } },
                         { T = 7, F = "win" } };
-- Locals ------------------------------------------------------------------ --
local iCLeft, iCRight, iCTop, iCExit,  -- Cursor ids
      iCBottom, iCWait, iCArrow;       -- More cursor ids
local iKeyBankId;                      -- Key bank to monitor keypresses
local iObject;                         -- Current object
local iSSelect, iSClick;               -- Sound effect ids
local sObject;                         -- Object selected text
local sObjectDefault<const> = "MAP POST MORTEM";
local texEnd;                          -- Post mortem textures
-- Post mortem logic ------------------------------------------------------- --
local function LogicPostMortem()
  -- Get absolute mouse position on level
  local iAMX<const>, iAMY<const> = GetAbsMousePos();
  -- Walk through objects
  for iIndex = 1, #aObjects do
    -- Get object data and if cursor overlapping it ?
    local aObject<const> = aObjects[iIndex];
    if IsSpriteCollide(479, iAMX, iAMY, aObject.S,
      aObject.X, aObject.Y) then
      -- Set tip with name and health of object
      sObject = (aObject.OD.LONGNAME or aObject.OD.NAME)..
        " ("..aObject.H.."%)";
      -- Done
      return;
    end
  end
  -- Set generic message
  sObject = sObjectDefault;
end
-- Post mortem render ------------------------------------------------------ --
local function RenderPostMortem()
  -- Render terrain and objects
  RenderTerrain();
  RenderObjects();
  -- Render post mortem banner and text
  texEnd:BlitLT(8, 208);
  fontSpeech:SetCRGB(0, 0, 0.25);
  fontSpeech:PrintC(160, 215, sObject);
end
-- Fade out to lobby ------------------------------------------------------- --
local function Finish()
  -- Play button select sound
  PlayStaticSound(iSSelect);
  -- When fade has completed?
  local function OnFadeOut()
    -- Dereference assets for garbage collection
    texEnd = nil;
    -- Current level completed and clear new game and selected level status
    aGlobalData.gLevelsCompleted[aGlobalData.gSelectedLevel] = true;
    aGlobalData.gSelectedLevel, aGlobalData.gNewGame = nil, nil;
    -- Bank balance reached? Show good ending if bank balance reached
    if aGlobalData.gBankBalance >= aGlobalData.gZogsToWinGame then
      return InitEnding(aGlobalData.gSelectedRace) end;
    -- Count number of levels completed and if all levels
    -- completed? Show bad ending :( else back to the lobby.
    local iNumCompleted<const> = UtilTableSize(aGlobalData.gLevelsCompleted);
    if iNumCompleted >= #aLevelsData then InitFail();
    else
      aGlobalData.gGameSaved = false;
      InitLobby();
    end
  end
  -- Start fading out
  Fade(0, 1, 0.04, RenderPostMortem, OnFadeOut, true);
end
-- Set specific object ----------------------------------------------------- --
local function SetObject(iNewObj)
  -- Don't do anything if no objects
  if #aObjects == 0 then return end;
  -- Play click sound
  PlayStaticSound(iSClick);
  -- Set new object value
  iObject = iNewObj;
  -- Modulo it if it's out of range
  if iObject < 1 or iObject > #aObjects then
    iObject = 1 + ((iObject - 1) % #aObjects) end;
  -- Focus on the object even with the mouse cursor
  local aObject<const> = aObjects[iObject];
  SelectObject(aObject, true, true);
end
-- Cycle between objects --------------------------------------------------- --
local function NextObject() SetObject(iObject + 1) end;
local function PreviousObject() SetObject(iObject - 1) end;
-- Scroll the map ---------------------------------------------------------- --
local function ScrollUp() AdjustViewPortY(-16) end;
local function ScrollDown() AdjustViewPortY(16) end;
local function ScrollLeft() AdjustViewPortX(-16) end;
local function ScrollRight() AdjustViewPortX(16) end;
-- Post mortem input ------------------------------------------------------- --
local function InputPostMortem()
  -- Mouse wheel is scrolling up? Goto previous object
  if IsScrollingUp() then PreviousObject();
  -- Mouse wheel is scrolling down? Goto next object
  elseif IsScrollingDown() then NextObject();
  -- Mouse at top edge of screen?
  elseif IsMouseXLessThan(16) then
    SetCursor(iCLeft);
    if IsButtonHeld(0) then ScrollLeft() end;
  -- Mouse at right edge of screen?
  elseif IsMouseXGreaterEqualThan(304) then
    SetCursor(iCRight);
    if IsButtonHeld(0) then ScrollRight() end;
  -- Mouse at left edge of screen?
  elseif IsMouseYLessThan(16) then
    SetCursor(iCTop);
    if IsButtonHeld(0) then ScrollUp() end;
  -- Mouse over exit point?
  elseif IsMouseYGreaterEqualThan(224) then
    -- Set exit cursor
    SetCursor(iCExit);
    -- Left mouse button pressed?
    if IsButtonPressed(0) then Finish() end;
  -- Mouse over edge of bottom?
  elseif IsMouseYGreaterEqualThan(192) then
    SetCursor(iCBottom);
    if IsButtonHeld(0) then ScrollDown() end;
  -- Mouse not anywhere interesting?
  else SetCursor(iCArrow) end;
end
-- Proc fade in ------------------------------------------------------------ --
local function LogicAnimatedPostMortem()
  -- Fade in elements and return until zero
  if nFade > 0 then nFade = nFade - 0.01 return end;
  -- Clamp fade to fully transparent
  nFade = 0;
  -- Enable post mortem keys
  SetKeys(true, iKeyBankId);
  -- Set no object id
  iObject = 0;
  -- Set EXIT (continue) cursor
  SetCursor(iCExit);
  -- Set post mortem procedure
  SetCallbacks(LogicPostMortem, RenderPostMortem, InputPostMortem);
end
-- Render fade in ---------------------------------------------------------- --
local function RenderAnimatedPostMortem()
  -- Render terrain and objects
  RenderTerrain();
  RenderObjects();
  -- Render fade in
  RenderFade(nFade);
  -- Render post mortem banner and text
  local nAdj<const> = nFade * 128;
  texEnd:BlitLT(8, 208 + nAdj);
  fontSpeech:SetCRGB(0, 0, 0.25);
  fontSpeech:PrintC(160, 215 + nAdj, sObject);
end
-- When post mortem assets are loaded? ------------------------------------- --
local function OnLoaded(aResources)
  -- Get post mortem texture
  texEnd = aResources[1];
  texEnd:TileSTC(1);
  texEnd:TileSD(0, 208, 232, 304, 24);
  -- Loop End music
  PlayMusic(aResources[2], nil, nil, nil, 371767);
  -- Object hovered over by mouse
  sObject = sObjectDefault
  -- Fade in counter
  nFade = 0.5;
  -- Set WAIT cursor for animation
  SetCursor(iCWait);
  -- Set post mortem procedure
  SetCallbacks(LogicAnimatedPostMortem, RenderAnimatedPostMortem);
end
-- Initialise the lose screen ---------------------------------------------- --
local function InitPost(iLId)
  LoadResources("Post Mortem", aAssets, OnLoaded);
end
-- When the script has loaded ---------------------------------------------- --
local function OnReady(GetAPI)
  -- Imports
  AdjustViewPortX, AdjustViewPortY, aGlobalData, aLevelsData, aObjectFlags,
    aObjects, Fade, fontSpeech, GetAbsMousePos, InitEnding, InitFail,
    InitLobby, IsButtonHeld, IsButtonPressed, IsButtonReleased,
    IsMouseInBounds, IsMouseNotInBounds, IsMouseXGreaterEqualThan,
    IsMouseXLessThan, IsMouseYGreaterEqualThan, IsMouseYLessThan,
    IsScrollingUp, IsScrollingDown, IsSpriteCollide, LoadResources,
    PlayMusic, PlayStaticSound, RenderFade, RenderObjects, RenderTerrain,
    SelectObject, SetCallbacks, SetCursor, SetKeys =
      GetAPI("AdjustViewPortX", "AdjustViewPortY", "aGlobalData",
        "aLevelsData", "aObjectFlags", "aObjects", "Fade", "fontSpeech",
        "GetAbsMousePos", "InitEnding", "InitFail", "InitLobby",
        "IsButtonHeld", "IsButtonPressed", "IsButtonReleased",
        "IsMouseInBounds", "IsMouseNotInBounds", "IsMouseXGreaterEqualThan",
        "IsMouseXLessThan", "IsMouseYGreaterEqualThan", "IsMouseYLessThan",
        "IsScrollingUp", "IsScrollingDown", "IsSpriteCollide", "LoadResources",
        "PlayMusic", "PlayStaticSound", "RenderFade", "RenderObjects",
        "RenderTerrain", "SelectObject", "SetCallbacks", "SetCursor",
        "SetKeys");
  -- Register keybinds
  local aKeys<const>, aStates<const> = Input.KeyCodes, Input.States;
  local aScrUp<const>, aScrDown<const>, aScrLeft<const>, aScrRight<const> =
    { aKeys.UP, ScrollUp, "igpmsmu", "SCROLL MAP UP" },
    { aKeys.DOWN, ScrollDown, "igpmsmd", "SCROLL MAP DOWN" },
    { aKeys.LEFT, ScrollLeft, "igpmsml", "SCROLL MAP LEFT" },
    { aKeys.RIGHT, ScrollRight, "igpmsmr", "SCROLL MAP RIGHT" };
  iKeyBankId = GetAPI("RegisterKeys")("IN-GAME POST MORTEM", {
    [aStates.PRESS] = {
      { aKeys.ESCAPE, Finish, "igpmc", "CLOSE" },
      { aKeys.MINUS, PreviousObject, "igpmop", "PREVIOUS" },
      { aKeys.EQUAL, NextObject, "igpmon", "NEXT" },
      aScrUp, aScrDown, aScrLeft, aScrRight
    }, [aStates.REPEAT] = { aScrUp, aScrDown, aScrLeft, aScrRight },
  });
  -- Set cursor ids
  local aCursorIdData<const> = GetAPI("aCursorIdData");
  iCLeft, iCRight, iCTop, iCBottom, iCWait, iCArrow, iCExit =
    aCursorIdData.LEFT, aCursorIdData.RIGHT, aCursorIdData.TOP,
      aCursorIdData.BOTTOM, aCursorIdData.WAIT, aCursorIdData.ARROW,
      aCursorIdData.EXIT;
  -- Set sound effect ids
  local aSfxData<const> = GetAPI("aSfxData");
  iSSelect, iSClick = aSfxData.SELECT, aSfxData.CLICK;
end
-- Exports and imports ----------------------------------------------------- --
return { A = { InitPost = InitPost }, F = OnReady };
-- End-of-File ============================================================= --

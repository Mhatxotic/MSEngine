-- PAUSE.LUA =============================================================== --
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
local CoreTime<const>, UtilFormatNTime<const> = Core.Time, Util.FormatNTime;
-- Diggers function and data aliases --------------------------------------- --
local DrawInfoFrameAndTitle, GetCallbacks, GetKeyBank, GetMusic, InitLose,
  IsJoyPressed, PlayMusic, RenderInterface, RenderFade, SetBottomRightTip,
  SetCallbacks, SetKeys, StopMusic, TriggerEnd, fontLittle, fontTiny;
-- Statics ------------------------------------------------------------------ --
local iPauseX<const> = 160;            -- Pause text X position
local iPauseY<const> = 72;             -- Pause text Y position
local iInstructionY<const> = iPauseY + 24; -- Instruction text Y position
local iSmallTipsY<const> = iInstructionY + 32; -- Small tips Y position
-- Locals ------------------------------------------------------------------ --
local iKeyBankId;                      -- Pause screen key bank id
local iLastKeyBankId;                  -- Saved key bank id
local sInstruction;                    -- Instruction text
local sSmallTips;                      -- Small instructions text
local muMusic;                         -- Current music played
local fCBProc, fCBRender, fCBInput;    -- Last callbacks
local nTimeNext;                       -- Next clock update
local strPause;                        -- Pause text string
-- End game callback ------------------------------------------------------- --
local function EndGame() TriggerEnd(InitLose) end;
-- Continue game callback -------------------------------------------------- --
local function ContinueGame()
  -- Resume music if we have it
  if muMusic then PlayMusic(muMusic, nil, 2) end;
  -- Restore game keys
  SetKeys(true, iLastKeyBankId);
  -- Unpause
  SetCallbacks(fCBProc, fCBRender, fCBInput);
end
-- Pause logic callback ---------------------------------------------------- --
local function ProcPause()
  -- Ignore if next update not elapsed
  if CoreTime() < nTimeNext then return end;
  -- Set new pause string
  strPause = UtilFormatNTime("%a/%H:%M:%S");
  -- Set next update time
  nTimeNext = CoreTime() + 0.25;
end
-- Pause render callback --------------------------------------------------- --
local function RenderPause()
  -- Render terrain, game objects, and a subtle fade
  RenderInterface();
  RenderFade(0.5);
  -- Write text informations
  DrawInfoFrameAndTitle("GAME PAUSED");
  fontLittle:SetCRGBA(0, 1, 0, 1);
  fontLittle:PrintC(iPauseX, iInstructionY, sInstruction);
  fontTiny:SetCRGBA(0.5, 0.5, 0.5, 1);
  fontTiny:PrintC(iPauseX, iSmallTipsY, sSmallTips);
  fontLittle:SetCRGBA(1, 1, 1, 1);
  -- Get and print local time
  SetBottomRightTip(strPause);
end
-- Pause input callback ---------------------------------------------------- --
local function InputPause()
  -- Return if pause button not pressed
  if not IsJoyPressed(9) then return end;
  -- If thumb buttons pressed? Allow the quit
  if IsJoyPressed(4) and IsJoyPressed(5) then EndGame();
  -- Normal unpause
  else ContinueGame() end;
end
-- Init pause screen ------------------------------------------------------- --
local function InitPause()
  -- Consts
  sInstruction = "Press ESCAPE or START to unpause.\n\z
                  \n\z
                  Press Q or START+JB4+JB5 to give up.";
  sSmallTips = "F1 OR SELECT+START BUTTON FOR SETUP\n\z
                F2 FOR THE GAME AND ENGINE CREDITS\n\z
                F11 TO RESET WINDOW SIZE AND POSITION\n\z
                F12 TO TAKE A SCREENSHOT";
  -- Save current music
  muMusic = GetMusic();
  -- Save callbacks
  fCBProc, fCBRender, fCBInput = GetCallbacks();
  -- Stop music
  StopMusic(1);
  -- Pause string
  nTimeNext, strPause = 0, nil;
  -- Save game keybank id to restore it on exit
  iLastKeyBankId = GetKeyBank();
  -- Set pause screen keys
  SetKeys(true, iKeyBankId);
  -- Set pause procedure
  SetCallbacks(ProcPause, RenderPause, InputPause);
end
-- When scripts have loaded ------------------------------------------------ --
local function OnReady(GetAPI)
  -- Get imports
  DrawInfoFrameAndTitle, GetCallbacks, GetKeyBank, GetMusic, InitLose,
    IsJoyPressed, PlayMusic, RenderInterface, RenderFade, SetBottomRightTip,
    SetCallbacks, SetKeys, StopMusic, TriggerEnd, fontLittle, fontTiny =
      GetAPI("DrawInfoFrameAndTitle", "GetCallbacks", "GetKeyBank", "GetMusic",
        "InitLose", "IsJoyPressed", "PlayMusic", "RenderInterface",
        "RenderFade", "SetBottomRightTip", "SetCallbacks", "SetKeys",
        "StopMusic", "TriggerEnd", "fontLittle", "fontTiny");
  -- Setup keybank
  local aKeys<const>, aStates<const> = Input.KeyCodes, Input.States;
  iKeyBankId = GetAPI("RegisterKeys")("PAUSE SCREEN", {
    [aStates.PRESS] = { { aKeys.Q, EndGame }, { aKeys.ESCAPE, ContinueGame } }
  });
end
-- Exports and imports ----------------------------------------------------- --
return { F = OnReady, A = { InitPause = InitPause } };
-- End-of-File ============================================================= --

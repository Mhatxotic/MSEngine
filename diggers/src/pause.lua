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
  IsButtonPressed, PlayMusic, RenderInterface, RenderFade, SetBottomRightTip,
  SetCallbacks, SetKeys, StopMusic, TriggerEnd, aKeyBankCats, fontLittle,
  fontTiny;
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
  -- Return if right mouse button or joystick button 1 not pressed
  if IsButtonPressed(1) then return ContinueGame() end;
  -- If thumb buttons or joystick button 3 and 4 pressed? Allow the quit
  if IsButtonPressed(3) and IsButtonPressed(4) then EndGame() end;
end
-- Init pause screen ------------------------------------------------------- --
local function InitPause()
  -- Consts
  sInstruction =
    "Press "..aKeyBankCats.igpcg[9]..", RMB or JB1 to unpause.\n\z
    \n\z
    Press "..aKeyBankCats.igpatg[9].." or MB3/JB3+MB4/JB4 to give up.";
  sSmallTips =
    aKeyBankCats.gksc[9]..", SELECT OR MB6 BUTTON FOR SETUP\n"..
    aKeyBankCats.gksb[9].." TO CHANGE KEY BINDINGS\n"..
    aKeyBankCats.gksa[9].." FOR THE GAME AND ENGINE CREDITS\n"..
    aKeyBankCats.gkcc[9].." TO RESET CURSOR POSITION\n"..
    aKeyBankCats.gkwr[9].." TO RESET WINDOW SIZE AND POSITION\n"..
    aKeyBankCats.gkss[9].." TO TAKE A SCREENSHOT";
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
    IsButtonPressed, PlayMusic, RenderInterface, RenderFade, SetBottomRightTip,
    SetCallbacks, SetKeys, StopMusic, TriggerEnd, aKeyBankCats, fontLittle,
    fontTiny =
      GetAPI("DrawInfoFrameAndTitle", "GetCallbacks", "GetKeyBank", "GetMusic",
        "InitLose", "IsButtonPressed", "PlayMusic", "RenderInterface",
        "RenderFade", "SetBottomRightTip", "SetCallbacks", "SetKeys",
        "StopMusic", "TriggerEnd", "aKeyBankCats", "fontLittle", "fontTiny");
  -- Setup keybank
  local aKeys<const>, aStates<const> = Input.KeyCodes, Input.States;
  iKeyBankId = GetAPI("RegisterKeys")("IN-GAME PAUSE", {
    [aStates.PRESS] = {
      { aKeys.Q, EndGame, "igpatg", "ABORT THE GAME" },
      { aKeys.ESCAPE, ContinueGame, "igpcg", "CONTINUE GAME" }
    }
  });
end
-- Exports and imports ----------------------------------------------------- --
return { F = OnReady, A = { InitPause = InitPause } };
-- End-of-File ============================================================= --

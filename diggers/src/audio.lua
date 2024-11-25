-- AUDIO.LUA =============================================================== --
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
-- Lua aliases (optimisation) ---------------------------------------------- --
local error, tostring = error, tostring;
-- M-Engine aliases (optimisation) ----------------------------------------- --
local UtilBlank<const>, UtilIsInteger<const>, UtilIsNumber<const>,
  UtilIsTable<const> = Util.Blank, Util.IsInteger, Util.IsNumber, Util.IsTable;
-- Input handling variables ------------------------------------------------ --
local aSounds             = { };       -- Sound effects
local vVideo;                          -- FMV playback handle
local nPosition;                       -- Saved music position
local sMusic;                          -- Currently playing music handle
local iLoops;                          -- Saved music loops count
-- ------------------------------------------------------------------------- --
local function VideoStop() if vVideo then vVideo = vVideo:Destroy() end end;
-- ------------------------------------------------------------------------- --
local function VideoPlay(Handle)
  VideoStop();
  vVideo = Handle;
  vVideo:SetVLTRB(0, 0, 320, 240);
  vVideo:SetTCLTRB(0, 0, 1, 1);
  vVideo:SetFilter(true);
  vVideo:Play();
  return vVideo;
end
-- Return music handle ----------------------------------------------------- --
local function GetMusic() return sMusic end;
-- Set music and video volume ---------------------------------------------- --
local function MusicVolume(Volume)
  if sMusic then sMusic:SetVolume(Volume) end;
  if vVideo then vVideo:SetVolume(Volume) end;
end
-- Pause if there is a music handle----------------------------------------- --
local function PauseMusic() if sMusic then sMusic:Stop() end end;
-- Resume music if there is a music handle---------------------------------- --
local function ResumeMusic() if sMusic then sMusic:Play(-1,1,0) end end
-- Stop music -------------------------------------------------------------- --
local function StopMusic(PosCmd)
  -- No current track? No problem
  if not sMusic then return end;
  -- Save position?
  if 1 == PosCmd then
    -- Save position
    nPosition = sMusic:GetPosition();
    -- Save loop count
    iLoops = sMusic:GetLoop();
  end
  -- Resume video if there is one
  if vVideo then vVideo:Play() end;
  -- Stop music
  sMusic = sMusic:Stop();
end
-- ------------------------------------------------------------------------- --
local function PlayMusic(musicHandle, Volume, PosCmd, Loop, Start)
  -- Set default parameters that aren't specified
  if not UtilIsNumber(Volume) then Volume = 1 end;
  if not UtilIsInteger(PosCmd) then PosCmd = 0 end;
  if not UtilIsInteger(Loop) then Loop = -1 end;
  if not UtilIsInteger(Start) then Start = 0 end;
  -- Stop music
  StopMusic(PosCmd);
  -- Handle specified?
  if musicHandle then
    -- Set loop
    if Start then musicHandle:SetLoopBegin(Start) end;
    -- Pause video if there is one
    if vVideo then vVideo:Pause() end;
    -- Asked to restore position?
    if 2 == PosCmd and nPosition and nPosition > 0 then
      -- Restore position
      musicHandle:SetPosition(nPosition);
      -- Play music
      musicHandle:SetLoop(iLoops);
      -- Delete position and loop variable
      nPosition, iLoops = nil, nil;
    -- No restore position?
    else
      -- Play music from start
      musicHandle:SetPosition(0);
      -- Loop forever
      musicHandle:SetLoop(-1);
    end
    -- Set volume
    musicHandle:SetVolume(Volume);
    -- Play music
    musicHandle:Play();
    -- Set current track
    sMusic = musicHandle;
  end
end
-- Function to play sound at the specified pan ----------------------------- --
local function PlaySound(iSfxId, nPan, nPitch)
  aSounds[iSfxId]:Play(1, nPan, nPitch or 1, false);
end
-- Function to play sound with no panning ---------------------------------- --
local function PlayStaticSound(iSfxId, nGain, nPitch)
  aSounds[iSfxId]:Play(nGain or 1, 0, nPitch or 1, false);
end
-- Function to loop the specified sound at the specified pan --------------- --
local function LoopSound(iSfxId, nPan, nPitch)
  aSounds[iSfxId]:Play(1, nPan, nPitch or 1, true);
end
-- Function to loop the specified sound with no panning -------------------- --
local function LoopStaticSound(iSfxId, nGain, nPitch)
  aSounds[iSfxId]:Play(nGain or 1, 0, nPitch or 1, true);
end
-- Function to stop specified sound ---------------------------------------- --
local function StopSound(iSfxId) aSounds[iSfxId]:Stop() end;
-- Function to register loaded sounds list --------------------------------- --
local function RegisterSounds(aHandles, iStart, iExpect)
  -- Check parameters
  if not UtilIsTable(aHandles) then
    error("Invalid table specified: "..tostring(aHandles)) end;
  if not UtilIsInteger(iStart) then
    error("Invalid start specified: "..tostring(iStart)) end;
  if not UtilIsInteger(iExpect) then
    error("Invalid count specified: "..tostring(iExpect)) end;
  if iStart < 1 then
    error("Invalid start specified: "..iStart) end;
  if iExpect < 0 then
    error("Invalid expect specified: "..iExpect) end;
  local iEnd<const> = iStart + iExpect - 1;
  if iEnd > #aHandles then
    error("Invalid end specified: "..iStart..","..iExpect..","..iEnd) end;
  -- Set all the requested handles
  for iSHIndex = iStart, iEnd do
    aSounds[1 + #aSounds] = aHandles[iSHIndex].H end
  -- Check we got the correct amount
  if iExpect ~= #aSounds then
    error("Only "..#aSounds.." of "..iExpect.." sound effects!") end;
end
-- Return module information ----------------------------------------------- --
return { F = UtilBlank, A = { GetMusic = GetMusic, LoopSound = LoopSound,
  LoopStaticSound = LoopStaticSound, MusicVolume = MusicVolume,
  PauseMusic = PauseMusic, PlayMusic = PlayMusic, PlaySound = PlaySound,
  PlayStaticSound = PlayStaticSound, RegisterSounds = RegisterSounds,
  ResumeMusic = ResumeMusic, StopMusic = StopMusic, StopSound = StopSound,
  VideoPlay = VideoPlay, VideoStop = VideoStop, InitTNTMap = InitTNTMap } };
-- End-of-File ============================================================= --

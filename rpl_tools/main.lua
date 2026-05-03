-- /ls rpl_tools/rpl_tools/main.lua
require("toriui.uielement")

--variables

local replayBounds = {
    startFrame = 200,
    endFrame = 400
}

local tempReplayName = "replayfocus-tmp"
local ws = get_world_state()
local hookName = "rpl_tools_hook"
local modname = get_game_rules().mod

local edited = false
local waitingForModDownload = false

--functions

local function custom_echo(msg, color)
    if color < 10 then color = "0" .. color end
    echo("^" .. COLORS.BLOSSOM .. "[ReplayFocus] ^" .. color .. msg)
end

local function createTempReplay()
    runCmd("savereplay " .. tempReplayName)
end

local function openTempReplay()
    custom_echo("Opening temp replay: " .. tempReplayName, COLORS.ORANGE)
    open_replay(tempReplayName .. ".rpl", 2)
end

local function setDefaultTextures()
    custom_echo("Auto-setting default textures", COLORS.GREEN)
    local players = { "Tori", "Uke" }
    for i = 0, 1 do
        runCmd("lp " .. i .. " " .. players[i + 1])
    end
end

local function customFindMod()
    modname = get_game_rules().mod
    custom_echo("Current mod: " .. modname, COLORS.BLUE)
    return modname == "classic.tbm" or find_mod(modname)
end
local function customDownloadMod()
    local shortName = modname:match("([^/]+)$")
    custom_echo("Mod file not found, trying to load mod: " .. shortName, COLORS.RED)
    runCmd("dl " .. shortName)
    waitingForModDownload = true
end

local function rewindIfOutOfBounds()
    if (edited) then
        createTempReplay()
        openTempReplay()
        edited = false
        return
    end
    local currentFrame = ws.match_frame or 0
    if currentFrame < replayBounds.startFrame or currentFrame > replayBounds.endFrame then
        rewind_replay_to_frame(replayBounds.startFrame)
        custom_echo("Replay out of bounds at frame " .. currentFrame .. ", rewinding to " .. replayBounds.startFrame,
            COLORS.VIOLET)
    end
end

--These run on start
remove_hooks(hookName)

if get_option("replaycache") < 1 then set_option("replaycache", 2) end

custom_echo("Activating Replay monitoring", COLORS.GREEN)
add_hook("enter_frame", "hookName", function()
    ws = get_world_state()
    if ws.match_frame % 10 ~= 0 then return end --check every 10 frames to reduce overhead
    if not get_replay_cache() then return end   --if replay cache is not active, do nothing
    if ws.replay_mode > 0 then
        rewindIfOutOfBounds()
    end
end)

add_hook("exit_freeze", "hookName", function()
    ws = get_world_state()
    if (ws.replay_mode == 0) then edited = true end
end)

add_hook("match_begin", "hookName", function()
    if not customFindMod() then
        customDownloadMod()
        return
    end
    setDefaultTextures()
end)

add_hook("downloader_complete", "hookName", function()
    if (waitingForModDownload and customFindMod()) then
        custom_echo("Download complete for: " .. modname, COLORS.GREEN)
        waitingForModDownload = false
        play_next_replay()
        play_prev_replay()
    end
end)

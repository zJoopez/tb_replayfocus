-- /ls rpl_tools/rpl_tools/main.lua
require("toriui.uielement")

--variables

local replayBounds = {
    startFrame = 200,
    endFrame = 400
}

local tempReplayName = "replayfocus-tmp"
local ws = get_world_state()
local edited = false

--functions

local function custom_echo(msg, color)
    if color < 10 then color = "0" .. color end
    echo("^" .. COLORS.BLOSSOM .. "[ReplayFocus] ^" .. color .. msg)
end

local function tryTempReplay()
    runCmd("savereplay " .. tempReplayName)
    custom_echo("using temp replay to force cache: " .. tempReplayName, COLORS.ORANGE)
    open_replay(tempReplayName .. ".rpl", 2)
end

local function rewindIfOutOfBounds()
    if (edited) then
        tryTempReplay()
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
remove_hook("enter_frame", "keepReplayWithinBounds")
remove_hook("exit_freeze", "cleanupTempReplay")

if get_option("replaycache") < 1 then set_option("replaycache", 2) end

custom_echo("Activating Replay monitoring", COLORS.GREEN)
add_hook("enter_frame", "keepReplayWithinBounds", function()
    ws = get_world_state()
    if ws.match_frame % 10 ~= 0 then return end --check every 10 frames to reduce overhead
    if not get_replay_cache() then return end   --if replay cache is not active, do nothing
    if ws.replay_mode == 1 then
        rewindIfOutOfBounds()
    end
end)

add_hook("exit_freeze", "cleanupTempReplay", function()
    print("exit")
    ws = get_world_state()
    if (ws.replay_mode < 1) then edited = true end
end)

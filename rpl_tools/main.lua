-- /ls rpl_tools/rpl_tools/main.lua
require("system.replays_manager")
require("toriui.uielement")

--variables

local replayBounds = {
    startFrame = 200,
    endFrame = 400
}
local inReplayMode = false

--functions

local function custom_echo(msg)
    echo("^28[ReplayFocus] ^41" .. msg)
end

local function rewindIfOutOfBounds()
    local ws = get_world_state()
    if ws.replay_mode == 0 then
        return
    end

    local currentFrame = ws.match_frame or 0
    if currentFrame < replayBounds.startFrame or currentFrame > replayBounds.endFrame then
        rewind_replay_to_frame(replayBounds.startFrame)
        custom_echo("Replay out of bounds at frame " .. currentFrame .. ", rewinding to " .. replayBounds.startFrame)
    end
end

--These run on start
if get_option("replaycache") < 1 then set_option("replaycache", 2) end 

custom_echo("Activating Replay monitoring")
add_hook("enter_frame", "keepReplayWithinBounds", function()
    local ws = get_world_state()
    if ws.replay_mode ~= 0 then
        if not inReplayMode then
            inReplayMode = true
        end
        rewindIfOutOfBounds()
    else
        inReplayMode = false
    end
end)
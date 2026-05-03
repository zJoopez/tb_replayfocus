-- /ls rpl_tools/rpl_tools/main.lua
require("toriui.uielement")

--variables

local replayBounds = {
    startFrame = 200,
    endFrame = 400
}
local inReplayMode = false

--functions

local function custom_echo(msg, color)
    if color < 10 then color = "0"..color end
    echo("^".. COLORS.BLOSSOM .."[ReplayFocus] ^"..color .. msg)
end

local function rewindIfOutOfBounds(ws)
    local currentFrame = ws.match_frame or 0
    if currentFrame < replayBounds.startFrame or currentFrame > replayBounds.endFrame then
        rewind_replay_to_frame(replayBounds.startFrame)
        custom_echo("Replay out of bounds at frame " .. currentFrame .. ", rewinding to " .. replayBounds.startFrame, COLORS.VIOLET)
    end
end

--These run on start
if get_option("replaycache") < 1 then set_option("replaycache", 2) end 

custom_echo("Activating Replay monitoring", COLORS.GREEN)
add_hook("enter_frame", "keepReplayWithinBounds", function()
    local ws = get_world_state()
    if ws.match_frame% 20 > 0 then return --check every 20 frames to reduce overhead
    elseif ws.replay_mode ~= 0 then
        rewindIfOutOfBounds(ws)
    end
end)
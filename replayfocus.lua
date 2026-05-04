-- Created by joopez
-- Project: ReplayFocus v.0.9
-- Built for Toribash v.5.76
-- /ls replayfocus.lua

require("toriui.uielement")

-- Variables

local tempReplayName = "replayfocus-tmp"
local hookName = "rpl_tools_hook"
local minRange = 100

local ws = get_world_state()
local modname = get_game_rules().mod
local edited = false
local waitingForModDownload = false

local replayBounds = {
    startFrame = 0,
    endFrame = minRange
}

-- UI toggles
local autoModLoading = false
local autoDefaultTextures = false
local autoRewinding = true

-- Functions

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
    return modname == "classic.tbm" or find_mod(modname)
end
local function customDownloadMod()
    local shortName = modname:match("([^/]+)$")
    custom_echo("Mod file not found, trying to load mod: " .. shortName, COLORS.RED)
    waitingForModDownload = true
    runCmd("dl " .. shortName)
end

local function modCheck()
    if autoModLoading and not customFindMod() then
        customDownloadMod()
        return
    end
end

local function textureCheck()
    if autoDefaultTextures then
        setDefaultTextures()
    end
end

local function rewindIfOutOfBounds()
    if (edited) then
        createTempReplay()
        openTempReplay()
        edited = false
        return
    end
    local startFrame = math.min(replayBounds.startFrame, ws.game_frame - minRange) -- extra protection
    local currentFrame = ws.match_frame or 0
    if currentFrame < startFrame or currentFrame > replayBounds.endFrame then
        rewind_replay_to_frame(startFrame)
        -- custom_echo("Replay out of bounds at frame " .. currentFrame .. ", rewinding to " .. startFrame,
        --     COLORS.VIOLET)
    end
end

-- UI
local windowHolder, windowWorkArea, windowMover = TBMenu:spawnMoveableWindow({
    x = 10,
    y = 100,
    w = 320,
    h = 320,
})

local content = windowWorkArea:addChild({
    pos = { 10, 15 },
    size = { windowWorkArea.size.w - 20, windowWorkArea.size.h - 20 },
}, true)

-- Title
local titleView = content:addChild({
    size = { content.size.w, 30 },
    bgColor = { 0, 0, 0, 0 }
})
titleView:addAdaptedText(true, "ReplayFocus", nil, nil, FONTS.MEDIUM, CENTER, 0.9)

-- Mod Loading Toggle
local modLabelView = content:addChild({
    pos = { 0, 35 },
    size = { content.size.w - 55, 25 },
    bgColor = { 0, 0, 0, 0 }
})
modLabelView:addAdaptedText(true, "Mod Loading", nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)
local modToggleView = content:addChild({
    pos = { content.size.w - 30, 35 },
    size = { 30, 25 }
})
TBMenu:spawnToggle2(modToggleView, nil, autoModLoading and 1 or 0, function(value)
    autoModLoading = (value == 1 or value == true)
    modCheck()
end)

-- Default Textures Toggle
local textureLabelView = content:addChild({
    pos = { 0, 65 },
    size = { content.size.w - 55, 25 },
    bgColor = { 0, 0, 0, 0 }
})
textureLabelView:addAdaptedText(true, "Set Default Textures", nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)
local textureToggleView = content:addChild({
    pos = { content.size.w - 30, 65 },
    size = { 30, 25 }
})
TBMenu:spawnToggle2(textureToggleView, nil, autoDefaultTextures and 1 or 0, function(value)
    autoDefaultTextures = (value == 1 or value == true)
    textureCheck()
end)

-- Rewind Toggle
local rewindLabelView = content:addChild({
    pos = { 0, 95 },
    size = { content.size.w - 55, 25 },
    bgColor = { 0, 0, 0, 0 }
})
rewindLabelView:addAdaptedText(true, "Focus", nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)
local rewindToggleView = content:addChild({
    pos = { content.size.w - 30, 95 },
    size = { 30, 25 }
})
TBMenu:spawnToggle2(rewindToggleView, nil, autoRewinding and 1 or 0, function(value)
    autoRewinding = (value == 1 or value == true)
end)

-- Playback range heading
local rangeHeadingView = content:addChild({
    pos = { 0, 125 },
    size = { content.size.w, 25 },
    bgColor = { 0, 0, 0, 0 }
})
local function updateRangeHeading()
    rangeHeadingView:addAdaptedText(true, "Focus Frames: " .. replayBounds.startFrame .. " - " .. replayBounds.endFrame,
        nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)
end
updateRangeHeading()

-- Start Frame Slider
local sliderLabelView = content:addChild({
    pos = { 5, 150 },
    size = { content.size.w - 5, 35 },
    bgColor = { 0, 0, 0, 0 }
})
sliderLabelView:addAdaptedText(true, "Start", nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)

local sliderView = content:addChild({
    pos = { content.size.w / 4, 150 },
    size = { content.size.w * 0.75, 35 }
})

local function spawnStartSlider()
    sliderView:kill(true)
    local maxFrame = ws.game_frame - minRange
    replayBounds.startFrame = math.min(replayBounds.startFrame, maxFrame) -- ensure start frame is not out of bounds on spawn
    return TBMenu:spawnSlider2(sliderView, { x = 5, y = 5, w = sliderView.size.w - 10, h = 28 },
        replayBounds.startFrame, {
            minValue = 0,
            maxValue = maxFrame,
            maxValueDisp = maxFrame,
            decimal = 0,
            darkerMode = true
        }, function(value)
            local currentOffset = math.max(minRange, replayBounds.endFrame - replayBounds.startFrame) -- maintain offset if end is already ahead, otherwise start moving end with start
            replayBounds.startFrame = math.floor(value)
            replayBounds.endFrame = replayBounds.startFrame + currentOffset

            updateRangeHeading()
        end)
end
spawnStartSlider()

-- End Frame Offset Slider
local endFrameLabelView = content:addChild({
    pos = { 5, 185 },
    size = { content.size.w - 5, 35 },
    bgColor = { 0, 0, 0, 0 }
})
endFrameLabelView:addAdaptedText(true, "Frames", nil, nil,
    FONTS.LMEDIUM, LEFTMID, 0.7)

local endSliderView = content:addChild({
    pos = { content.size.w / 4, 185 },
    size = { content.size.w * 0.75, 35 }
})
local function spawnEndSlider()
    endSliderView:kill(true)
    replayBounds.endFrame = math.min(replayBounds.endFrame, ws.game_frame) -- ensure end frame is not out of bounds on spawn
    return TBMenu:spawnSlider2(endSliderView, { x = 5, y = 5, w = endSliderView.size.w - 10, h = 28 },
        replayBounds.endFrame - replayBounds.startFrame, {
            minValue = minRange,
            maxValue = ws.game_frame,
            maxValueDisp = ws.game_frame,
            darkerMode = true
        }, function(value)
            replayBounds.endFrame = replayBounds.startFrame + math.floor(value)
            updateRangeHeading()
        end)
end
spawnEndSlider()

-- info
local copyright = content:addChild({
    pos = { 0, content.size.h - 35 },
    size = { content.size.w, 15 },
    bgColor = { 0, 0, 0, 0 }
})
copyright:addAdaptedText(true, "F1 shows/hides window", nil, nil, FONTS.SMALL, CENTER, 0.6)

-- copyright
local copyright = content:addChild({
    pos = { 0, content.size.h - 20 },
    size = { content.size.w, 15 },
    bgColor = { 0, 0, 0, 0 }
})
copyright:addAdaptedText(true, "script by joopez", nil, nil, FONTS.SMALL, CENTER, 0.6)

-- General

if get_option("replaycache") < 1 then set_option("replaycache", 2) end

-- Hooks

add_hook("enter_frame", hookName, function()
    ws = get_world_state()
    if ws.match_frame % 10 ~= 0 then return end --check every 10 frames to reduce overhead
    if not get_replay_cache() then return end   --if replay cache is not active, do nothing
    if ws.replay_mode > 0 and autoRewinding then
        rewindIfOutOfBounds()
    end
end)

add_hook("exit_freeze", hookName, function()
    ws = get_world_state()
    if (ws.replay_mode == 0) then edited = true end
end)

add_hook("match_begin", hookName, function()
    ws = get_world_state()
    modCheck()
    textureCheck()
    spawnStartSlider()
    spawnEndSlider()
    updateRangeHeading()
end)

add_hook("downloader_complete", hookName, function()
    if (waitingForModDownload and customFindMod()) then
        custom_echo("Download complete for: " .. modname, COLORS.GREEN)
        waitingForModDownload = false
        play_next_replay()
        play_prev_replay()
    end
end)

add_hook("key_up", hookName, function(key)
    if key ~= 282 then return end --F1
    if content.displayed then
        windowHolder:hide(true)
    else
        windowHolder:show(true)
    end
end)

windowHolder.killAction = function()
    remove_hooks(hookName)
    custom_echo("Exit complete, matanee~~", COLORS.VIOLET)
end

custom_echo("Script active", COLORS.VIOLET)

-- /ls rpl_tools/rpl_tools/main.lua
require("toriui.uielement")

-- Variables

local replayBounds = {
    startFrame = 200,
    endFrame = 400
}

local tempReplayName = "replayfocus-tmp"
local hookName = "rpl_tools_hook"
local ws = get_world_state()
local modname = get_game_rules().mod

local edited = false
local waitingForModDownload = false

-- UI toggles
local autoModLoading = true
local autoDefaultTextures = true
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
    custom_echo("Current mod: " .. modname, COLORS.BLUE)
    return modname == "classic.tbm" or find_mod(modname)
end
local function customDownloadMod()
    local shortName = modname:match("([^/]+)$")
    custom_echo("Mod file not found, trying to load mod: " .. shortName, COLORS.RED)
    waitingForModDownload = true
    runCmd("dl " .. shortName)
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

-- UI Creation
local function createControlPanel()
    local windowHolder, windowWorkArea, windowMover = TBMenu:spawnMoveableWindow({
        x = 100,
        y = 100,
        w = 300,
        h = 350
    })

    local content = windowWorkArea:addChild({
        pos = { 10, 15 },
        size = { windowWorkArea.size.w - 20, windowWorkArea.size.h - 20 },
        bgColor = { 0, 0, 0, 0 }
    }, true)

    -- Title
    local titleView = content:addChild({
        size = { content.size.w, 30 },
        bgColor = { 0, 0, 0, 0 }
    })
    titleView:addAdaptedText(true, "ReplayFocus Controls", nil, nil, FONTS.MEDIUM, CENTER, 0.8)

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
    end)

    -- Default Textures Toggle
    local textureLabelView = content:addChild({
        pos = { 0, 65 },
        size = { content.size.w - 55, 25 },
        bgColor = { 0, 0, 0, 0 }
    })
    textureLabelView:addAdaptedText(true, "Default Textures", nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)
    local textureToggleView = content:addChild({
        pos = { content.size.w - 30, 65 },
        size = { 30, 25 }
    })
    TBMenu:spawnToggle2(textureToggleView, nil, autoDefaultTextures and 1 or 0, function(value)
        autoDefaultTextures = (value == 1 or value == true)
    end)

    -- Rewind Toggle
    local rewindLabelView = content:addChild({
        pos = { 0, 95 },
        size = { content.size.w - 55, 25 },
        bgColor = { 0, 0, 0, 0 }
    })
    rewindLabelView:addAdaptedText(true, "Rewind", nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)
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
        size = { content.size.w, 22 },
        bgColor = { 0, 0, 0, 0 }
    })
    rangeHeadingView:addAdaptedText(true, "Range: ".. replayBounds.startFrame .. " - " .. replayBounds.endFrame, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)

    -- Start Frame Slider
    local sliderLabelView = content:addChild({
        pos = { 0, 150 },
        size = { content.size.w, 25 },
        bgColor = { 0, 0, 0, 0 }
    })
    sliderLabelView:addAdaptedText(true, "Start Frame: " .. replayBounds.startFrame, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)

    local sliderView = content:addChild({
        pos = { 0, 175 },
        size = { content.size.w, 35 }
    })
    local startSlider = TBMenu:spawnSlider2(sliderView, { x = 5, y = 5, w = content.size.w - 10, h = 25 }, replayBounds.startFrame, {
        minValue = 0,
        maxValue = 1000,
        decimal = 0,
    }, function(value)
        local newStartFrame = math.floor(value)
        local currentOffset = math.max(100, replayBounds.endFrame - replayBounds.startFrame)
        replayBounds.startFrame = newStartFrame
        replayBounds.endFrame = replayBounds.startFrame + currentOffset

        sliderLabelView:addAdaptedText(true, "Start Frame: " .. replayBounds.startFrame, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)
        rangeHeadingView:addAdaptedText(true, "Range: ".. replayBounds.startFrame .. " - " .. replayBounds.endFrame, nil, nil, FONTS.LMEDIUM, LEFTMID, 0.7)
    end)

    -- End Frame Offset Slider
    local endFrameLabelView = content:addChild({
        pos = { 0, 210 },
        size = { content.size.w, 25 },
        bgColor = { 0, 0, 0, 0 }
    })
    endFrameLabelView:addAdaptedText(true, "Focus Frames: " .. (replayBounds.endFrame - replayBounds.startFrame), nil, nil,
        FONTS.LMEDIUM, LEFTMID, 0.7)

    local endSliderView = content:addChild({
        pos = { 0, 235 },
        size = { content.size.w, 35 }
    })
    local endslider = TBMenu:spawnSlider2(endSliderView, { x = 5, y = 5, w = content.size.w - 10, h = 25 },
        replayBounds.endFrame - replayBounds.startFrame, {
            minValue = 100,
            maxValue = 1000,
            decimal = 0,
        }, function(value)
            replayBounds.endFrame = replayBounds.startFrame + math.floor(value)
            endFrameLabelView:addAdaptedText(true, "Focus Frames: " .. (replayBounds.endFrame - replayBounds.startFrame), nil, nil,
                FONTS.LMEDIUM, LEFTMID, 0.7)
            rangeHeadingView:addAdaptedText(true, "Range: ".. replayBounds.startFrame .. " - " .. replayBounds.endFrame, nil, nil,
                FONTS.LMEDIUM, LEFTMID, 0.7)
    end)

    return windowHolder
end

--These run on start
remove_hooks(hookName)

if get_option("replaycache") < 1 then set_option("replaycache", 2) end

custom_echo("Activating Replay monitoring", COLORS.GREEN)
add_hook("enter_frame", "hookName", function()
    ws = get_world_state()
    if ws.match_frame % 10 ~= 0 then return end --check every 10 frames to reduce overhead
    if not get_replay_cache() then return end   --if replay cache is not active, do nothing
    if ws.replay_mode > 0 and autoRewinding then
        rewindIfOutOfBounds()
    end
end)

add_hook("exit_freeze", "hookName", function()
    ws = get_world_state()
    if (ws.replay_mode == 0) then edited = true end
end)

add_hook("match_begin", "hookName", function()
    if autoModLoading and not customFindMod() then
        customDownloadMod()
        return
    end
    if autoDefaultTextures then
        setDefaultTextures()
    end
end)

add_hook("downloader_complete", "hookName", function()
    if (waitingForModDownload and customFindMod()) then
        custom_echo("Download complete for: " .. modname, COLORS.GREEN)
        waitingForModDownload = false
        play_next_replay()
        play_prev_replay()
    end
end)

createControlPanel()

-- tests/test_gl_m4.lua
-- Comprehensive Unit & Integration Test Suite for GL-M4: Blizzard Action Bar Artwork Controller

local unpack = unpack or table.unpack

local passCount = 0
local failCount = 0

local function assert_eq(actual, expected, msg)
    if actual == expected then
        passCount = passCount + 1
    else
        failCount = failCount + 1
        print("FAIL: " .. tostring(msg))
        print("  Expected: " .. tostring(expected))
        print("  Actual:   " .. tostring(actual))
        error("Test failed: " .. tostring(msg))
    end
end

local function assert_true(cond, msg)
    assert_eq(not not cond, true, msg)
end

local function assert_false(cond, msg)
    assert_eq(not not cond, false, msg)
end

-- 1. Mock WoW 3.3.5a UI Frame & Texture Environment
local MockFrame = {}
MockFrame.__index = MockFrame

function MockFrame.new(name, isTexture)
    local self = setmetatable({}, MockFrame)
    self.name = name
    self.isTexture = isTexture or false
    self.visible = true
    self.alpha = 1.0
    self.mouseEnabled = not isTexture
    self.scripts = {}
    self.registeredEvents = {}
    self.eventsUnregistered = false

    if name then
        _G[name] = self
    end
    return self
end

function MockFrame:Show() self.visible = true end
function MockFrame:Hide() self.visible = false end
function MockFrame:IsShown() return self.visible end

function MockFrame:SetAlpha(a) self.alpha = a end
function MockFrame:GetAlpha() return self.alpha end

function MockFrame:EnableMouse(enabled)
    self.mouseEnabled = not not enabled
end
function MockFrame:IsMouseEnabled()
    return self.mouseEnabled
end

function MockFrame:SetScript(evt, fn)
    self.scripts[evt] = fn
end
function MockFrame:GetScript(evt)
    return self.scripts[evt]
end

function MockFrame:RegisterEvent(evt)
    self.registeredEvents[evt] = true
end
function MockFrame:UnregisterAllEvents()
    self.registeredEvents = {}
    self.eventsUnregistered = true
end

_G.CreateFrame = function(frameType, name, parent)
    local f = MockFrame.new(name, false)
    return f
end

-- Instantiate standard WoW 3.3.5a Blizzard action bar artwork elements
local leftEndCap = MockFrame.new("MainMenuBarLeftEndCap", false)
local rightEndCap = MockFrame.new("MainMenuBarRightEndCap", false)

local mainBarOverlay = MockFrame.new("MainMenuBarOverlayFrame", false)
local mainBarArt = MockFrame.new("MainMenuBarArtFrame", false)

local mainBarTex0 = MockFrame.new("MainMenuBarTexture0", true)
local mainBarTex1 = MockFrame.new("MainMenuBarTexture1", true)
local mainBarTex2 = MockFrame.new("MainMenuBarTexture2", true)
local mainBarTex3 = MockFrame.new("MainMenuBarTexture3", true)

local maxLevelTex0 = MockFrame.new("MainMenuMaxLevelBar0", true)
local maxLevelTex1 = MockFrame.new("MainMenuMaxLevelBar1", true)
local maxLevelTex2 = MockFrame.new("MainMenuMaxLevelBar2", true)
local maxLevelTex3 = MockFrame.new("MainMenuMaxLevelBar3", true)

local microArtFrame = MockFrame.new("MicroButtonAndBagsBar", false)

-- Attach sample OnEvent script to overlay frame to test event preservation
local sampleEventRun = false
mainBarOverlay:SetScript("OnEvent", function(self, event)
    sampleEventRun = true
end)

-- Load module
local BlizzardArt = dofile("GridLock/Modules/BlizzardArt.lua")
local GridLock = _G.GridLock

print("=========================================")
print("Running GL-M4 Blizzard Action Bar Artwork Controller Tests")
print("=========================================")

-- Test Group 1: Public API Exposure
print("[Test Group 1] Public API Exposure on GridLock")
assert_true(type(GridLock.SetGryphonsVisible) == "function", "SetGryphonsVisible is exposed")
assert_true(type(GridLock.SetMainBarArtVisible) == "function", "SetMainBarArtVisible is exposed")
assert_true(type(GridLock.SetMicroMenuArtVisible) == "function", "SetMicroMenuArtVisible is exposed")
assert_true(type(GridLock.GetBlizzardArtState) == "function", "GetBlizzardArtState is exposed")
assert_true(type(GridLock.ApplyBlizzardArtSettings) == "function", "ApplyBlizzardArtSettings is exposed")


-- Test Group 2: Gryphon EndCaps Toggling & Mouse Click-Through
print("[Test Group 2] Left & Right Gryphon EndCap Controls")

-- Hide both gryphons
GridLock:SetGryphonsVisible(false, false)
assert_false(leftEndCap:IsShown(), "Left gryphon hidden")
assert_false(rightEndCap:IsShown(), "Right gryphon hidden")
assert_false(leftEndCap:IsMouseEnabled(), "Left gryphon mouse disabled (click-through)")
assert_false(rightEndCap:IsMouseEnabled(), "Right gryphon mouse disabled (click-through)")

local state1 = GridLock:GetBlizzardArtState()
assert_false(state1.leftGryphon, "State leftGryphon false")
assert_false(state1.rightGryphon, "State rightGryphon false")

-- Show left, hide right
GridLock:SetGryphonsVisible(true, false)
assert_true(leftEndCap:IsShown(), "Left gryphon shown")
assert_false(rightEndCap:IsShown(), "Right gryphon hidden")
assert_true(leftEndCap:IsMouseEnabled(), "Left gryphon mouse enabled")
assert_false(rightEndCap:IsMouseEnabled(), "Right gryphon mouse disabled")

local state2 = GridLock:GetBlizzardArtState()
assert_true(state2.leftGryphon, "State leftGryphon true")
assert_false(state2.rightGryphon, "State rightGryphon false")

-- Single boolean argument hides/shows both
GridLock:SetGryphonsVisible(false)
assert_false(leftEndCap:IsShown(), "Left gryphon hidden with single false arg")
assert_false(rightEndCap:IsShown(), "Right gryphon hidden with single false arg")

-- Table argument syntax
GridLock:SetGryphonsVisible({ left = true, right = true })
assert_true(leftEndCap:IsShown(), "Left gryphon shown via table arg")
assert_true(rightEndCap:IsShown(), "Right gryphon shown via table arg")


-- Test Group 3: MainMenuBar Background Art & Event Interference Controls
print("[Test Group 3] MainMenuBar Background Art Controls")

-- Hide MainMenuBar Background Art
GridLock:SetMainBarArtVisible(false)
assert_false(mainBarTex0:IsShown(), "MainBarTexture0 hidden")
assert_false(mainBarTex1:IsShown(), "MainBarTexture1 hidden")
assert_false(mainBarTex2:IsShown(), "MainBarTexture2 hidden")
assert_false(mainBarTex3:IsShown(), "MainBarTexture3 hidden")

assert_false(maxLevelTex0:IsShown(), "MaxLevelBar0 hidden")
assert_false(maxLevelTex1:IsShown(), "MaxLevelBar1 hidden")
assert_false(maxLevelTex2:IsShown(), "MaxLevelBar2 hidden")
assert_false(maxLevelTex3:IsShown(), "MaxLevelBar3 hidden")

assert_false(mainBarOverlay:IsShown(), "MainMenuBarOverlayFrame hidden")
assert_false(mainBarOverlay:IsMouseEnabled(), "MainMenuBarOverlayFrame mouse disabled (click-through)")
assert_eq(mainBarOverlay:GetScript("OnEvent"), nil, "Overlay frame OnEvent script wiped to disable event interference")
assert_true(mainBarOverlay.eventsUnregistered, "Overlay frame UnregisterAllEvents called")

local state3 = GridLock:GetBlizzardArtState()
assert_false(state3.mainBarArt, "State mainBarArt false")

-- Show MainMenuBar Background Art
GridLock:SetMainBarArtVisible(true)
assert_true(mainBarTex0:IsShown(), "MainBarTexture0 shown")
assert_true(mainBarTex1:IsShown(), "MainBarTexture1 shown")
assert_true(mainBarTex2:IsShown(), "MainBarTexture2 shown")
assert_true(mainBarTex3:IsShown(), "MainBarTexture3 shown")

assert_true(maxLevelTex0:IsShown(), "MaxLevelBar0 shown")
assert_true(maxLevelTex1:IsShown(), "MaxLevelBar1 shown")
assert_true(maxLevelTex2:IsShown(), "MaxLevelBar2 shown")
assert_true(maxLevelTex3:IsShown(), "MaxLevelBar3 shown")

assert_true(mainBarOverlay:IsShown(), "MainMenuBarOverlayFrame shown")
assert_true(mainBarOverlay:IsMouseEnabled(), "MainMenuBarOverlayFrame mouse enabled")
assert_true(type(mainBarOverlay:GetScript("OnEvent")) == "function", "Overlay frame OnEvent script restored")

local state4 = GridLock:GetBlizzardArtState()
assert_true(state4.mainBarArt, "State mainBarArt true")


-- Test Group 4: Micro Menu Background Art Controls
print("[Test Group 4] Micro Menu Background Art Controls")

-- Hide Micro Menu Art
GridLock:SetMicroMenuArtVisible(false)
assert_false(microArtFrame:IsShown(), "MicroButtonAndBagsBar hidden")
assert_false(microArtFrame:IsMouseEnabled(), "MicroButtonAndBagsBar mouse disabled (click-through)")

local state5 = GridLock:GetBlizzardArtState()
assert_false(state5.microMenuArt, "State microMenuArt false")

-- Show Micro Menu Art
GridLock:SetMicroMenuArtVisible(true)
assert_true(microArtFrame:IsShown(), "MicroButtonAndBagsBar shown")
assert_true(microArtFrame:IsMouseEnabled(), "MicroButtonAndBagsBar mouse enabled")

local state6 = GridLock:GetBlizzardArtState()
assert_true(state6.microMenuArt, "State microMenuArt true")


-- Test Group 5: Bulk Settings Application via ApplyBlizzardArtSettings
print("[Test Group 5] ApplyBlizzardArtSettings Bulk Configuration")

local newState = GridLock:ApplyBlizzardArtSettings({
    leftGryphon = false,
    rightGryphon = false,
    mainBarArt = false,
    microMenuArt = false,
})

assert_false(newState.leftGryphon, "Bulk apply leftGryphon false")
assert_false(newState.rightGryphon, "Bulk apply rightGryphon false")
assert_false(newState.mainBarArt, "Bulk apply mainBarArt false")
assert_false(newState.microMenuArt, "Bulk apply microMenuArt false")

assert_false(leftEndCap:IsShown(), "Left gryphon hidden post bulk apply")
assert_false(rightEndCap:IsShown(), "Right gryphon hidden post bulk apply")
assert_false(mainBarOverlay:IsShown(), "Overlay frame hidden post bulk apply")
assert_false(microArtFrame:IsShown(), "Micro art hidden post bulk apply")

-- Bulk apply with 'gryphons' shortcut property
GridLock:ApplyBlizzardArtSettings({
    gryphons = true,
    mainBarArt = true,
    microMenuArt = true,
})

local state7 = GridLock:GetBlizzardArtState()
assert_true(state7.leftGryphon, "Shortcut gryphons true -> leftGryphon true")
assert_true(state7.rightGryphon, "Shortcut gryphons true -> rightGryphon true")
assert_true(state7.mainBarArt, "mainBarArt true")
assert_true(state7.microMenuArt, "microMenuArt true")


-- Test Group 6: Mouse Click-Through & Non-Blocking Interaction Simulation
print("[Test Group 6] Mouse Click-Through & Non-Blocking Action Button Interaction")

-- Create a mock action button located behind the MainMenuBarOverlayFrame
local buttonClicked = false
local actionButton = MockFrame.new("ActionButton1", false)
actionButton:SetScript("OnMouseDown", function(self)
    buttonClicked = true
end)

-- Simulated mouse click dispatcher
local function DispatchClickAtPoint(framesInLayerOrder)
    -- Highest z-order (overlay art) checked first. If shown and mouse enabled, it blocks the click.
    -- Otherwise, click passes through to the underlying action button.
    for _, f in ipairs(framesInLayerOrder) do
        if f:IsShown() and f:IsMouseEnabled() then
            local script = f:GetScript("OnMouseDown")
            if script then script(f) end
            return f -- Click intercepted by frame f
        end
    end
    return nil
end

local frameStack = { mainBarOverlay, actionButton }

-- Case 1: Artwork is VISIBLE and Mouse-ENABLED (Default Blizzard state)
GridLock:SetMainBarArtVisible(true)
buttonClicked = false
local hitFrame = DispatchClickAtPoint(frameStack)
assert_eq(hitFrame, mainBarOverlay, "Visible artwork overlay intercepts mouse click")
assert_false(buttonClicked, "Action button click blocked by visible artwork frame")

-- Case 2: Artwork is HIDDEN and Click-Through (EnableMouse = false)
GridLock:SetMainBarArtVisible(false)
buttonClicked = false
local hitFrame2 = DispatchClickAtPoint(frameStack)
assert_eq(hitFrame2, actionButton, "Click passes through hidden artwork to ActionButton1")
assert_true(buttonClicked, "Action button successfully receives mouse click when artwork is hidden")

print("=========================================")
print(string.format("All GL-M4 Tests PASSED! (Passed: %d, Failed: %d)", passCount, failCount))
print("=========================================")

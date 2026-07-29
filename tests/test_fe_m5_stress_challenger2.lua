-- tests/test_fe_m5_stress_challenger2.lua
-- Empirical Stress Test Harness for ZenAlign FE-M5 Challenger 2
-- Focus: Boundary Conditions, Scaling Math, Overlapping Coordinates, Negative Offsets, Rapid Keybinding Modifiers

local passedCount = 0
local failedCount = 0

local function assert_test(cond, msg)
    if cond then
        passedCount = passedCount + 1
        print("  [PASS] " .. msg)
    else
        failedCount = failedCount + 1
        print("  [FAIL] " .. msg)
    end
end

-- 1. Mock WoW 3.3.5a API Environment
local mockFrames = {}
local mockScreen = { width = 1920, height = 1080 }
local mouseFocus = nil

_G.GetScreenWidth = function() return mockScreen.width end
_G.GetScreenHeight = function() return mockScreen.height end
_G.GetMouseFocus = function() return mouseFocus end
_G.InCombatLockdown = function() return false end

local mockShiftKey = false
local mockCtrlKey = false
local mockAltKey = false

_G.IsShiftKeyDown = function() return mockShiftKey end
_G.IsControlKeyDown = function() return mockCtrlKey end
_G.IsAltKeyDown = function() return mockAltKey end

_G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg) end
}
_G.SlashCmdList = {}

_G.GameTooltip = {
    owner = nil,
    GetOwner = function(self) return self.owner end,
    SetOwner = function(self, owner, anchor) self.owner = owner end,
    ClearLines = function(self) end,
    AddLine = function(self, ...) end,
    Show = function(self) end,
    Hide = function(self) end,
}

local mockSavedBindings = {}
_G.SetBinding = function(key, command)
    if command == nil then
        mockSavedBindings[key] = nil
    else
        mockSavedBindings[key] = command
    end
end

_G.GetBindingKey = function(command)
    for k, v in pairs(mockSavedBindings) do
        if v == command then return k end
    end
    return nil
end

_G.SaveBindings = function(mode) end

local FrameMT = {}
FrameMT.__index = FrameMT

function FrameMT:SetSize(w, h) self.width = w; self.height = h end
function FrameMT:SetWidth(w) self.width = w end
function FrameMT:SetHeight(h) self.height = h end
function FrameMT:GetWidth() return self.width or 100 end
function FrameMT:GetHeight() return self.height or 50 end
function FrameMT:SetPoint(point, rel, relPoint, x, y)
    self.point = { point = point, rel = rel, relPoint = relPoint, x = x or 0, y = y or 0 }
end
function FrameMT:GetPoint(i)
    if self.point then
        return self.point.point, self.point.rel, self.point.relPoint, self.point.x, self.point.y
    end
    return "CENTER", _G.UIParent, "CENTER", 0, 0
end
function FrameMT:ClearAllPoints() self.point = nil end
function FrameMT:SetAllPoints(parent) self.allPoints = parent end
function FrameMT:SetFrameStrata(strata) self.strata = strata end
function FrameMT:GetFrameStrata() return self.strata end
function FrameMT:SetFrameLevel(level) self.level = level end
function FrameMT:GetFrameLevel() return self.level or 0 end
function FrameMT:EnableMouse(flag) self.mouseEnabled = flag end
function FrameMT:IsMouseEnabled() return self.mouseEnabled end
function FrameMT:SetMovable(flag) self.movable = flag end
function FrameMT:SetClampedToScreen(flag) self.clamped = flag end
function FrameMT:Show() self.shown = true end
function FrameMT:Hide() self.shown = false end
function FrameMT:IsShown() return self.shown ~= false end
function FrameMT:GetName() return self.name end
function FrameMT:GetObjectType() return self.objectType or "Frame" end
function FrameMT:GetEffectiveScale() return self.scale or 1.0 end
function FrameMT:GetScale() return self.scale or 1.0 end
function FrameMT:SetScale(s) self.scale = s end
function FrameMT:GetAlpha() return self.alpha or 1.0 end
function FrameMT:SetAlpha(a) self.alpha = a end
function FrameMT:GetCenter() return self.x or 500, self.y or 400 end
function FrameMT:GetLeft() return (self.x or 500) - (self:GetWidth()/2) end
function FrameMT:GetRight() return (self.x or 500) + (self:GetWidth()/2) end
function FrameMT:GetTop() return (self.y or 400) + (self:GetHeight()/2) end
function FrameMT:GetBottom() return (self.y or 400) - (self:GetHeight()/2) end
function FrameMT:GetNumPoints() return self.point and 1 or 0 end
function FrameMT:GetParent() return self.parent end
function FrameMT:SetParent(p) self.parent = p end
function FrameMT:RegisterForClicks(...) self.registeredClicks = {...} end
function FrameMT:RegisterForDrag(...) self.registeredDrag = {...} end
function FrameMT:SetScript(event, fn) self.scripts = self.scripts or {}; self.scripts[event] = fn end
function FrameMT:GetScript(event) return self.scripts and self.scripts[event] end
function FrameMT:StartMoving() end
function FrameMT:StopMovingOrSizing() end
function FrameMT:EnableKeyboard(flag) self.keyboardEnabled = flag end
function FrameMT:EnableMouseWheel(flag) self.wheelEnabled = flag end
function FrameMT:RegisterEvent(evt) self.events = self.events or {}; self.events[evt] = true end
function FrameMT:UnregisterEvent(evt) if self.events then self.events[evt] = nil end end
function FrameMT:SetText(txt) self.text = txt end
function FrameMT:GetText() return self.text end

function FrameMT:SetBackdrop(bd) self.backdrop = bd end
function FrameMT:SetBackdropColor(r, g, b, a) self.backdropColor = {r=r, g=g, b=b, a=a} end
function FrameMT:SetBackdropBorderColor(r, g, b, a) self.backdropBorderColor = {r=r, g=g, b=b, a=a} end

function FrameMT:CreateTexture(name, layer)
    local tex = {
        name = name,
        layer = layer,
        SetTexture = function(s, path) s.texturePath = path end,
        SetVertexColor = function(s, r, g, b, a) s.color = {r=r, g=g, b=b, a=a} end,
        SetWidth = function(s, w) s.width = w end,
        SetHeight = function(s, h) s.height = h end,
        SetSize = function(s, w, h) s.width = w; s.height = h end,
        SetPoint = function(s, ...) s.points = {...} end,
        ClearAllPoints = function(s) s.points = nil end,
        Show = function(s) s.shown = true end,
        Hide = function(s) s.shown = false end,
        IsShown = function(s) return s.shown ~= false end,
    }
    return tex
end

local function CreateMockFrame(type, name, parent)
    local f = setmetatable({
        objectType = type or "Frame",
        name = name,
        parent = parent,
        shown = true,
        scale = 1.0,
        x = 500,
        y = 400,
        width = 100,
        height = 50,
    }, FrameMT)
    if name then
        _G[name] = f
        mockFrames[name] = f
    end
    return f
end

_G.CreateFrame = CreateMockFrame
_G.UIParent = CreateMockFrame("Frame", "UIParent")
_G.UIParent:SetSize(1920, 1080)
_G.UIParent.x = 960
_G.UIParent.y = 540

_G.WorldFrame = CreateMockFrame("Frame", "WorldFrame")

_G.strsplit = function(delimiter, text)
    local list = {}
    for match in (text .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(list, match)
    end
    return table.unpack(list)
end

_G.wipe = function(t)
    for k in pairs(t) do t[k] = nil end
    return t
end

local ZenAlign = {}
_G.ZenAlign = ZenAlign

local function loadScript(file)
    local f, err = loadfile(file)
    if not f then error("Failed to load file " .. file .. ": " .. tostring(err)) end
    f("ZenAlign", ZenAlign)
end

loadScript("ZenAlign/Localization/enUS.lua")
loadScript("ZenAlign/Core/Utils.lua")
loadScript("ZenAlign/Core/Config.lua")
loadScript("ZenAlign/Data/Frames.lua")
loadScript("ZenAlign/Core/Core.lua")

loadScript("ZenAlign/Modules/Snap.lua")
loadScript("ZenAlign/Modules/Keybind.lua")
loadScript("ZenAlign/Modules/Mover.lua")

local ZenAlign = _G.ZenAlign
ZenAlign:Initialize()

local Snap = ZenAlign:GetModule("Snap")
local Keybind = ZenAlign:GetModule("Keybind")
local Mover = ZenAlign:GetModule("Mover")

print("=== Running ZenAlign FE-M5 Challenger 2 Stress Test Suite ===")

-- ----------------------------------------------------
-- TEST SUITE 1: Extreme Scale Factor Snapping (0.1x to 5.0x)
-- ----------------------------------------------------
print("\n--- Test Suite 1: Extreme Scale Factor Snapping ---")

-- Setup Target Frame (Candidate) at fixed center (400, 300), base size 100x100
local targetFrame = CreateMockFrame("Frame", "TargetFrame_ScaleTest")
targetFrame:SetSize(100, 100)
targetFrame.x = 400
targetFrame.y = 300
Mover.movers[targetFrame:GetName()] = { targetFrame = targetFrame }

-- Setup Dragged Frame, base size 100x100
local draggedFrame = CreateMockFrame("Frame", "DraggedFrame_ScaleTest")
draggedFrame:SetSize(100, 100)

local scalesToTest = { 0.1, 0.25, 0.5, 1.0, 2.0, 3.0, 5.0 }

for _, targetScale in ipairs(scalesToTest) do
    for _, dragScale in ipairs(scalesToTest) do
        targetFrame:SetScale(targetScale)
        draggedFrame:SetScale(dragScale)

        -- Calculate expected bounds
        -- targetFrame: GetLeft() returns 400 - 50 = 350.
        -- Snap.lua: candidate left = frame:GetLeft() * targetScale = 350 * targetScale
        -- candidate right = candidate left + 100 * targetScale = (350 + 100) * targetScale = 450 * targetScale
        -- candidate top = (300 + 50) * targetScale = 350 * targetScale
        -- candidate bottom = (300 - 50) * targetScale = 250 * targetScale

        local candLeft = (targetFrame.x - targetFrame.width / 2) * targetScale
        local candRight = (targetFrame.x + targetFrame.width / 2) * targetScale
        local candTop = (targetFrame.y + targetFrame.height / 2) * targetScale
        local candBottom = (targetFrame.y - targetFrame.height / 2) * targetScale

        local dragW = draggedFrame.width * dragScale
        local dragH = draggedFrame.height * dragScale

        -- Test 1.1: TOP-to-BOTTOM Docking (dragged bottom docks to candidate top)
        -- Raw position Y close to candidate top + dragH / 2
        local expectedSnapY = candTop + dragH / 2
        local rawX = (candLeft + candRight) / 2 -- center X
        local rawY = expectedSnapY + 3 -- within threshold of 10

        Snap:ResetStickyState()
        local finalX, finalY, didSnap, snaps = Snap:GetFrameToFrameSnap(draggedFrame, rawX, rawY)

        assert_test(math.abs(finalY - expectedSnapY) < 0.001,
            string.format("Top-to-Bottom Dock Y at targetScale=%.2f dragScale=%.2f (RawY=%.2f -> SnapY=%.2f, Actual=%.2f)",
                targetScale, dragScale, rawY, expectedSnapY, finalY))

        -- Test 1.2: LEFT-to-RIGHT Docking (dragged right docks to candidate left)
        -- Raw position X close to candidate left - dragW / 2
        local expectedSnapX = candLeft - dragW / 2
        rawX = expectedSnapX - 4
        rawY = (candBottom + candTop) / 2

        Snap:ResetStickyState()
        finalX, finalY, didSnap, snaps = Snap:GetFrameToFrameSnap(draggedFrame, rawX, rawY)

        assert_test(math.abs(finalX - expectedSnapX) < 0.001,
            string.format("Left-to-Right Dock X at targetScale=%.2f dragScale=%.2f (RawX=%.2f -> SnapX=%.2f, Actual=%.2f)",
                targetScale, dragScale, rawX, expectedSnapX, finalX))
    end
end

-- ----------------------------------------------------
-- TEST SUITE 2: Overlapping Frame Coordinates
-- ----------------------------------------------------
print("\n--- Test Suite 2: Overlapping Frame Coordinates ---")

targetFrame:SetScale(1.0)
draggedFrame:SetScale(1.0)

-- Scenario 2.1: Complete Overlap (Same center 400, 300)
-- Target: (350..450, 250..350), Dragged 100x100
Snap:ResetStickyState()
local rawX, rawY = 400, 300
local finalX, finalY, didSnap, snaps = Snap:GetFrameToFrameSnap(draggedFrame, rawX, rawY)
assert_test(finalX == 400 and finalY == 300, string.format("Coincident frame center overlap snaps to CX=400, CY=300 (Got X=%.1f, Y=%.1f)", finalX, finalY))

-- Scenario 2.2: Dragged frame inside large target frame
-- Target 400x400 at (400, 400) -> bounds (200..600, 200..600)
local largeTarget = CreateMockFrame("Frame", "LargeTarget")
largeTarget:SetSize(400, 400)
largeTarget.x = 400
largeTarget.y = 400
Mover.movers[largeTarget:GetName()] = { targetFrame = largeTarget }

-- Dragged 50x50 near inner left edge of target (cand.left = 200)
-- Flush LEFT-to-LEFT: dragLeft (rawX - 25) aligns with cand.left (200) -> rawX should snap to 200 + 25 = 225
draggedFrame:SetSize(50, 50)
Snap:ResetStickyState()
rawX, rawY = 227, 400 -- 2px off flush left alignment
finalX, finalY, didSnap, snaps = Snap:GetFrameToFrameSnap(draggedFrame, rawX, rawY)
assert_test(math.abs(finalX - 225) < 0.001, string.format("Inner Flush Left-to-Left alignment inside large frame (Expected 225, Got %.1f)", finalX))

-- Dragged 50x50 near inner top edge of target (cand.top = 600)
-- Flush TOP-to-TOP: dragTop (rawY + 25) aligns with cand.top (600) -> rawY should snap to 600 - 25 = 575
Snap:ResetStickyState()
rawX, rawY = 400, 572 -- 3px off flush top alignment
finalX, finalY, didSnap, snaps = Snap:GetFrameToFrameSnap(draggedFrame, rawX, rawY)
assert_test(math.abs(finalY - 575) < 0.001, string.format("Inner Flush Top-to-Top alignment inside large frame (Expected 575, Got %.1f)", finalY))

-- Scenario 2.3: Target frame inside large dragged frame
-- Target 50x50 at (400, 400) -> bounds (375..425, 375..425)
local smallTarget = CreateMockFrame("Frame", "SmallTarget")
smallTarget:SetSize(50, 50)
smallTarget.x = 400
smallTarget.y = 400
Mover.movers[smallTarget:GetName()] = { targetFrame = smallTarget }

draggedFrame:SetSize(300, 300)
-- Center alignment CX_d = CX_cand (400)
Snap:ResetStickyState()
rawX, rawY = 405, 400 -- 5px off center
finalX, finalY, didSnap, snaps = Snap:GetFrameToFrameSnap(draggedFrame, rawX, rawY)
assert_test(finalX == 400, string.format("Large dragged frame center snaps to small target CX=400 (Got %.1f)", finalX))


-- ----------------------------------------------------
-- TEST SUITE 3: Negative Offsets & Negative Coordinates
-- ----------------------------------------------------
print("\n--- Test Suite 3: Negative Offsets & Negative Coordinates ---")

-- Target Frame at negative coordinates (-300, -200), size 100x100
-- Bounds: Left = -350, Right = -250, Top = -150, Bottom = -250
local negTarget = CreateMockFrame("Frame", "NegTarget")
negTarget:SetSize(100, 100)
negTarget.x = -300
negTarget.y = -200
Mover.movers[negTarget:GetName()] = { targetFrame = negTarget }

draggedFrame:SetSize(100, 100)
draggedFrame:SetScale(1.0)

-- Test 3.1: TOP-to-BOTTOM Docking at negative coordinates
-- Dragged bottom (rawY - 50) docks to negTarget top (-150) -> rawY snaps to -150 + 50 = -100
Snap:ResetStickyState()
rawX, rawY = -300, -96 -- 4px off
finalX, finalY, didSnap, snaps = Snap:GetFrameToFrameSnap(draggedFrame, rawX, rawY)
assert_test(math.abs(finalY - (-100)) < 0.001, string.format("Negative coordinate Top-to-Bottom docking (Expected -100, Got %.1f)", finalY))

-- Test 3.2: LEFT-to-RIGHT Docking at negative coordinates
-- Dragged left (rawX - 50) docks to negTarget right (-250) -> rawX snaps to -250 + 50 = -200
Snap:ResetStickyState()
rawX, rawY = -195, -200 -- 5px off
finalX, finalY, didSnap, snaps = Snap:GetFrameToFrameSnap(draggedFrame, rawX, rawY)
assert_test(math.abs(finalX - (-200)) < 0.001, string.format("Negative coordinate Left-to-Right docking (Expected -200, Got %.1f)", finalX))

-- Test 3.3: Sticky Breakaway under negative coordinates
Snap:ResetStickyState()
rawX, rawY = -300, -96
finalX, finalY = Snap:GetFrameToFrameSnap(draggedFrame, rawX, rawY) -- Sticky lock active at Y = -100

-- Move rawY to -110 (delta = 10 < releaseThreshold 16) -> should hold at -100
finalX, finalY = Snap:GetFrameToFrameSnap(draggedFrame, -300, -110)
assert_test(finalY == -100, string.format("Sticky lock held at Y=-100 for rawY=-110 in negative space (Got %.1f)", finalY))

-- Move rawY to -120 (delta = 20 >= releaseThreshold 16) -> should break away to -120
finalX, finalY = Snap:GetFrameToFrameSnap(draggedFrame, -300, -120)
assert_test(finalY == -120, string.format("Sticky lock breakaway to Y=-120 in negative space (Got %.1f)", finalY))


-- ----------------------------------------------------
-- TEST SUITE 4: Keybinding Modifier Parsing & Combinations
-- ----------------------------------------------------
print("\n--- Test Suite 4: Keybinding Modifier Parsing & Combinations ---")

Keybind:Activate()
local catcher = Keybind.catcher
local targetButton = CreateMockFrame("Button", "ActionButton1")
targetButton.action = 1
mockFrames["ActionButton1"] = targetButton

-- Test 4.1: SHIFT-CTRL-ALT-NUMPAD5 Rapid Combination Parsing
mockShiftKey = true
mockCtrlKey = true
mockAltKey = true

local formattedKey = Keybind:FormatKey("numpad5")
assert_test(formattedKey == "SHIFT-CTRL-ALT-NUMPAD5", string.format("FormatKey('numpad5') with Shift+Ctrl+Alt -> '%s'", tostring(formattedKey)))

local shortKey = Keybind:ShortenKeyText(formattedKey)
assert_test(shortKey == "scaN5", string.format("ShortenKeyText('SHIFT-CTRL-ALT-NUMPAD5') -> '%s' (Expected 'scaN5')", tostring(shortKey)))

-- Test 4.2: All Permutations of Modifiers with Key & Short Text
local modifierPermutations = {
    { shift = true,  ctrl = false, alt = false, raw = "f",        expectedFormat = "SHIFT-F",                 expectedShort = "sF" },
    { shift = false, ctrl = true,  alt = false, raw = "f",        expectedFormat = "CTRL-F",                  expectedShort = "cF" },
    { shift = false, ctrl = false, alt = true,  raw = "f",        expectedFormat = "ALT-F",                   expectedShort = "aF" },
    { shift = true,  ctrl = true,  alt = false, raw = "f",        expectedFormat = "SHIFT-CTRL-F",            expectedShort = "scF" },
    { shift = true,  ctrl = false, alt = true,  raw = "f",        expectedFormat = "SHIFT-ALT-F",             expectedShort = "saF" },
    { shift = false, ctrl = true,  alt = true,  raw = "f",        expectedFormat = "CTRL-ALT-F",              expectedShort = "caF" },
    { shift = true,  ctrl = true,  alt = true,  raw = "f",        expectedFormat = "SHIFT-CTRL-ALT-F",        expectedShort = "scaF" },
    { shift = true,  ctrl = true,  alt = true,  raw = "BUTTON3",  expectedFormat = "SHIFT-CTRL-ALT-BUTTON3",  expectedShort = "scaM3" },
    { shift = true,  ctrl = true,  alt = true,  raw = "MOUSEWHEELUP", expectedFormat = "SHIFT-CTRL-ALT-MOUSEWHEELUP", expectedShort = "scaMwU" },
}

for _, perm in ipairs(modifierPermutations) do
    mockShiftKey = perm.shift
    mockCtrlKey = perm.ctrl
    mockAltKey = perm.alt

    local fmt = Keybind:FormatKey(perm.raw)
    local srt = Keybind:ShortenKeyText(fmt)

    assert_test(fmt == perm.expectedFormat, string.format("Permutation format '%s' == '%s'", fmt, perm.expectedFormat))
    assert_test(srt == perm.expectedShort, string.format("Permutation short '%s' == '%s'", srt, perm.expectedShort))
end

-- Test 4.3: Standalone Modifier Suppression under Rapid Sequence
local standaloneKeys = { "LSHIFT", "RSHIFT", "SHIFT", "LCTRL", "RCTRL", "CTRL", "LALT", "RALT", "ALT" }
for _, standalone in ipairs(standaloneKeys) do
    mockShiftKey = (standalone:find("SHIFT") ~= nil)
    mockCtrlKey = (standalone:find("CTRL") ~= nil)
    mockAltKey = (standalone:find("ALT") ~= nil)

    local fmt = Keybind:FormatKey(standalone)
    assert_test(fmt == nil, string.format("Standalone modifier '%s' ignored (FormatKey returned nil)", standalone))
end

-- Test 4.4: Rapid Sequential Keybinding Execution Benchmark (100 Key Events)
Keybind.hoveredButton = targetButton

mockShiftKey = true
mockCtrlKey = true
mockAltKey = true

local startTime = os.clock()
for i = 1, 100 do
    Keybind:OnKeyDown("NUMPAD" .. (i % 10))
end
local endTime = os.clock()
local elapsedMs = (endTime - startTime) * 1000

local lastBound = _G.GetBindingKey("ACTIONBUTTON1")
assert_test(lastBound ~= nil and lastBound:find("SHIFT-CTRL-ALT-NUMPAD", 1, true) ~= nil,
    string.format("100 rapid keybind events processed successfully in %.2f ms (Last binding: %s)", elapsedMs, tostring(lastBound)))

Keybind:Deactivate()

print("\n=== Final Test Results ===")
print(string.format("Total Passed: %d | Total Failed: %d", passedCount, failedCount))

if failedCount > 0 then
    os.exit(1)
end

-- test_fe_m3.lua
-- Unit & Integration Tests for ZenAlign FE-M3: Multi-State Alpha & Combat Fade Manager

-- 1. Mock WoW 3.3.5a API Environment
local mockFrames = {}
local mockScreen = { width = 1920, height = 1080 }
local mouseOverFrame = nil
local inCombatLockdownState = false

_G.GetScreenWidth = function() return mockScreen.width end
_G.GetScreenHeight = function() return mockScreen.height end
_G.InCombatLockdown = function() return inCombatLockdownState end
_G.MouseIsOver = function(frame) return frame ~= nil and frame == mouseOverFrame end

_G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg) end
}
_G.SlashCmdList = {}

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
function FrameMT:Show() self.shown = true end
function FrameMT:Hide() self.shown = false end
function FrameMT:IsShown() return self.shown ~= false end
function FrameMT:GetName() return self.name end
function FrameMT:GetObjectType() return self.objectType or "Frame" end
function FrameMT:GetAlpha() return self.alpha or 1.0 end
function FrameMT:SetAlpha(a) self.alpha = a end
function FrameMT:IsMouseOver() return self == mouseOverFrame end
function FrameMT:RegisterEvent(evt) self.events = self.events or {}; self.events[evt] = true end
function FrameMT:UnregisterEvent(evt) if self.events then self.events[evt] = nil end end
function FrameMT:SetScript(event, fn) self.scripts = self.scripts or {}; self.scripts[event] = fn end
function FrameMT:GetScript(event) return self.scripts and self.scripts[event] end

_G.CreateFrame = function(frameType, name, parent, template)
    local f = setmetatable({
        objectType = frameType,
        name = name,
        parent = parent or _G.UIParent,
        template = template,
        shown = true,
        level = 0,
        alpha = 1.0,
    }, FrameMT)
    if name then
        _G[name] = f
    end
    table.insert(mockFrames, f)
    return f
end

_G.UIParent = _G.CreateFrame("Frame", "UIParent", nil)
_G.WorldFrame = _G.CreateFrame("Frame", "WorldFrame", nil)

_G.strsplit = function(delimiter, text)
    local list = {}
    for match in (text .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(list, match)
    end
    return table.unpack(list)
end

-- Load ZenAlign core files & FadeManager module
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
loadScript("ZenAlign/Modules/FadeManager.lua")

ZenAlign:Initialize()

-- Test Harness
local passCount = 0
local failCount = 0

local function assert_eq(actual, expected, testName)
    if actual == expected then
        passCount = passCount + 1
        print("  [PASS] " .. testName)
    else
        failCount = failCount + 1
        print(string.format("  [FAIL] %s: Expected %s, got %s", testName, tostring(expected), tostring(actual)))
    end
end

local function assert_near(actual, expected, tol, testName)
    tol = tol or 0.001
    if math.abs(actual - expected) <= tol then
        passCount = passCount + 1
        print("  [PASS] " .. testName)
    else
        failCount = failCount + 1
        print(string.format("  [FAIL] %s: Expected %s (+/-%s), got %s", testName, tostring(expected), tostring(tol), tostring(actual)))
    end
end

local function assert_true(cond, testName)
    if cond then
        passCount = passCount + 1
        print("  [PASS] " .. testName)
    else
        failCount = failCount + 1
        print("  [FAIL] " .. testName .. ": Condition was false")
    end
end

print("=== Running ZenAlign FE-M3: Multi-State Alpha & Combat Fade Manager Tests ===")

local FadeManager = ZenAlign:GetModule("FadeManager")
assert_true(FadeManager ~= nil, "FadeManager module loaded")

-- 1. Test Suite 1: Frame Registration & Default Alpha Settings
print("\n--- Test Suite 1: Frame Registration & Default Settings ---")
local testFrame1 = _G.CreateFrame("Frame", "TestFrame1", UIParent)
testFrame1:SetAlpha(1.0)

local rec1 = FadeManager:RegisterFrame("TestFrame1", 1.0, 0.6, 0.9, 0.2)
assert_true(rec1 ~= nil, "RegisterFrame by string name returned record")
assert_eq(rec1.frameName, "TestFrame1", "Record frameName is TestFrame1")
assert_eq(rec1.alphaOOC, 1.0, "alphaOOC is 1.0")
assert_eq(rec1.alphaCombat, 0.6, "alphaCombat is 0.6")
assert_eq(rec1.alphaHover, 0.9, "alphaHover is 0.9")
assert_eq(rec1.fadeDuration, 0.2, "fadeDuration is 0.2")
assert_eq(FadeManager.numRegistered, 1, "numRegistered is 1")

-- Register by frame object table
local testFrame2 = _G.CreateFrame("Frame", "TestFrame2", UIParent)
local rec2 = FadeManager:RegisterFrame(testFrame2, 0.8, 0.4, 1.0, 0.3)
assert_true(rec2 ~= nil, "RegisterFrame by table object returned record")
assert_eq(rec2.frameName, "TestFrame2", "Record frameName resolved to TestFrame2")
assert_eq(FadeManager.numRegistered, 2, "numRegistered is 2")

-- Register with missing optional parameters (check defaults)
local testFrame3 = _G.CreateFrame("Frame", "TestFrame3", UIParent)
local rec3 = FadeManager:RegisterFrame(testFrame3)
assert_eq(rec3.alphaOOC, 1.0, "Default alphaOOC is 1.0")
assert_eq(rec3.alphaCombat, 1.0, "Default alphaCombat is 1.0")
assert_eq(rec3.alphaHover, 1.0, "Default alphaHover is 1.0")
assert_eq(rec3.fadeDuration, 0.2, "Default fadeDuration is 0.2")

-- Test SetFrameAlphas
FadeManager:SetFrameAlphas("TestFrame1", 0.95, 0.55, 0.85)
assert_eq(rec1.alphaOOC, 0.95, "SetFrameAlphas updated alphaOOC to 0.95")
assert_eq(rec1.alphaCombat, 0.55, "SetFrameAlphas updated alphaCombat to 0.55")
assert_eq(rec1.alphaHover, 0.85, "SetFrameAlphas updated alphaHover to 0.85")

-- Restore rec1 alphas & cleanup testFrame2 / testFrame3
FadeManager:SetFrameAlphas("TestFrame1", 1.0, 0.6, 0.9)
FadeManager:UnregisterFrame("TestFrame2")
FadeManager:UnregisterFrame("TestFrame3")
assert_eq(FadeManager.numRegistered, 1, "Cleaned up test frames; numRegistered is 1")
assert_eq(FadeManager:GetFrameRecord("TestFrame3"), nil, "TestFrame3 record is nil after unregister")

-- 2. Test Suite 2: State Priority Resolution (Hover > Combat > Out-of-Combat)
print("\n--- Test Suite 2: State Priority Resolution ---")
-- Alphas: alphaOOC = 1.0, alphaCombat = 0.6, alphaHover = 0.9
FadeManager.inCombat = false
mouseOverFrame = nil

-- Out-of-Combat, No Mouseover -> Target Alpha = 1.0 (alphaOOC)
FadeManager:UpdateFrameTargetState(rec1)
assert_eq(rec1.targetAlpha, 1.0, "State 1: Out-of-Combat & No Hover -> target = 1.0 (alphaOOC)")

-- In-Combat, No Mouseover -> Target Alpha = 0.6 (alphaCombat)
FadeManager.inCombat = true
FadeManager:UpdateFrameTargetState(rec1)
assert_eq(rec1.targetAlpha, 0.6, "State 2: In-Combat & No Hover -> target = 0.6 (alphaCombat)")

-- In-Combat, Mouseover Active -> Target Alpha = 0.9 (alphaHover)
mouseOverFrame = testFrame1
FadeManager:UpdateFrameTargetState(rec1)
assert_eq(rec1.targetAlpha, 0.9, "State 3: In-Combat & Hover -> target = 0.9 (alphaHover overrides combat)")

-- Out-of-Combat, Mouseover Active -> Target Alpha = 0.9 (alphaHover)
FadeManager.inCombat = false
FadeManager:UpdateFrameTargetState(rec1)
assert_eq(rec1.targetAlpha, 0.9, "State 4: Out-of-Combat & Hover -> target = 0.9 (alphaHover overrides OOC)")

mouseOverFrame = nil
FadeManager:UpdateFrameTargetState(rec1)

-- 3. Test Suite 3: Combat Event Transitions
print("\n--- Test Suite 3: Combat Event Transitions ---")
local eventFrame = _G.ZenAlignFadeManagerFrame
assert_true(eventFrame ~= nil, "ZenAlignFadeManagerFrame event frame exists")
local onEvent = eventFrame:GetScript("OnEvent")
assert_true(onEvent ~= nil, "OnEvent script handler registered on eventFrame")

-- Trigger PLAYER_REGEN_DISABLED (Enter combat)
FadeManager.inCombat = false
onEvent(eventFrame, "PLAYER_REGEN_DISABLED")
assert_true(FadeManager.inCombat, "PLAYER_REGEN_DISABLED set inCombat = true")
assert_eq(rec1.targetAlpha, 0.6, "PLAYER_REGEN_DISABLED updated rec1 targetAlpha to 0.6")

-- Trigger PLAYER_REGEN_ENABLED (Exit combat)
onEvent(eventFrame, "PLAYER_REGEN_ENABLED")
assert_true(not FadeManager.inCombat, "PLAYER_REGEN_ENABLED set inCombat = false")
assert_eq(rec1.targetAlpha, 1.0, "PLAYER_REGEN_ENABLED updated rec1 targetAlpha to 1.0")

-- 4. Test Suite 4: Smooth OnUpdate Interpolation & O(1) Active Array Cleanup
print("\n--- Test Suite 4: Smooth OnUpdate Interpolation & O(1) Cleanup ---")
-- Reset state
FadeManager.inCombat = false
mouseOverFrame = nil

-- Prepare rec1: duration = 0.2, currentAlpha = 1.0, transition to 0.6 (simulate entering combat)
testFrame1:SetAlpha(1.0)
rec1.currentAlpha = 1.0
rec1.startAlpha = 1.0
rec1.targetAlpha = 0.6
rec1.fadeDuration = 0.2
rec1.elapsedTime = 0.0
rec1.isFading = false

FadeManager.inCombat = true
FadeManager:UpdateFrameTargetState(rec1)

assert_true(rec1.isFading, "rec1 isFading is true after target alpha change")
assert_eq(FadeManager.numActive, 1, "numActive is 1")
assert_eq(FadeManager.activeAnimations[1], rec1, "activeAnimations[1] is rec1")

-- Tick 1: 0.1s (50% progress) -> expected alpha = 1.0 + (0.6 - 1.0)*0.5 = 0.8
FadeManager:OnUpdate(0.1)
assert_near(rec1.currentAlpha, 0.8, 0.001, "Tick 1 (0.1s/0.2s): interpolated alpha is 0.8")
assert_near(testFrame1:GetAlpha(), 0.8, 0.001, "Tick 1: frame SetAlpha called with 0.8")
assert_true(rec1.isFading, "rec1 still fading at 50% progress")
assert_eq(FadeManager.numActive, 1, "numActive remains 1")

-- Tick 2: 0.1s (total 0.2s, 100% progress) -> completed transition
FadeManager:OnUpdate(0.1)
assert_near(rec1.currentAlpha, 0.6, 0.001, "Tick 2 (0.2s/0.2s): completed transition to target alpha 0.6")
assert_near(testFrame1:GetAlpha(), 0.6, 0.001, "Tick 2: frame SetAlpha final value is 0.6")
assert_true(not rec1.isFading, "rec1 isFading set to false upon completion")
assert_eq(FadeManager.numActive, 0, "numActive reduced to 0 after completion")
assert_eq(FadeManager.activeAnimations[1], nil, "activeAnimations[1] cleared to nil")

-- Unregister rec1 before multi-frame subtest
FadeManager:UnregisterFrame("TestFrame1")

-- Concurrent Fading & O(1) Swap-Removal Test
print("  Subtest: Concurrent Fading & O(1) Swap-Removal")
local frameA = _G.CreateFrame("Frame", "FrameA", UIParent)
local frameB = _G.CreateFrame("Frame", "FrameB", UIParent)
local frameC = _G.CreateFrame("Frame", "FrameC", UIParent)

local recA = FadeManager:RegisterFrame(frameA, 1.0, 0.0, 1.0, 0.4)
local recB = FadeManager:RegisterFrame(frameB, 1.0, 0.0, 1.0, 0.2) -- Faster duration (completes first)
local recC = FadeManager:RegisterFrame(frameC, 1.0, 0.0, 1.0, 0.4)

FadeManager.inCombat = true
FadeManager:UpdateAllFrames()

assert_eq(FadeManager.numActive, 3, "3 records active in activeAnimations")
assert_eq(recA.activeIdx, 1, "recA activeIdx = 1")
assert_eq(recB.activeIdx, 2, "recB activeIdx = 2")
assert_eq(recC.activeIdx, 3, "recC activeIdx = 3")

-- Tick 0.25s: recB (duration 0.2s) completes, recA and recC (duration 0.4s) continue
FadeManager:OnUpdate(0.25)
assert_eq(FadeManager.numActive, 2, "numActive reduced to 2 after recB completed")
assert_true(not recB.isFading, "recB completed fading")
-- Verify recC was swapped into index 2 (replacing recB)
assert_eq(FadeManager.activeAnimations[2], recC, "O(1) Swap-Remove: recC moved into index 2")
assert_eq(recC.activeIdx, 2, "recC activeIdx updated to 2")

-- Tick 0.20s more (total 0.45s): recA and recC complete
FadeManager:OnUpdate(0.20)
assert_eq(FadeManager.numActive, 0, "numActive reduced to 0 after all animations completed")
assert_true(not recA.isFading, "recA completed fading")
assert_true(not recC.isFading, "recC completed fading")

-- Cleanup test frames
FadeManager:UnregisterFrame("FrameA")
FadeManager:UnregisterFrame("FrameB")
FadeManager:UnregisterFrame("FrameC")

-- 5. Test Suite 5: Memory Garbage Allocation Check (Zero GC Memory Delta)
print("\n--- Test Suite 5: Memory Garbage Allocation Check ---")
-- Register 10 test frames
local gcTestFrames = {}
for idx = 1, 10 do
    local f = _G.CreateFrame("Frame", "GCTestFrame" .. idx, UIParent)
    f:SetAlpha(1.0)
    local rec = FadeManager:RegisterFrame(f, 1.0, 0.2 * (idx % 4), 0.9, 0.1 * (idx % 3 + 1))
    table.insert(gcTestFrames, rec)
end

-- Force initial collection & record memory count
collectgarbage("collect")
local memBefore = collectgarbage("count")

-- Run 1000 OnUpdate ticks with state changes
for tick = 1, 1000 do
    if tick % 50 == 0 then
        FadeManager.inCombat = not FadeManager.inCombat
    end
    if tick % 30 == 0 then
        mouseOverFrame = (tick % 60 == 0) and gcTestFrames[1].frame or nil
    end
    FadeManager:OnUpdate(0.016)
end

local memAfter = collectgarbage("count")
local memDelta = math.max(0, memAfter - memBefore)

print(string.format("  Memory before 1000 ticks: %.3f KB", memBefore))
print(string.format("  Memory after 1000 ticks:  %.3f KB", memAfter))
print(string.format("  Garbage Delta:            %.3f KB", memDelta))

assert_true(memDelta <= 0.0001, "Zero GC memory allocated during 1000 OnUpdate ticks")

print("\n=== Test Results ===")
print(string.format("Passed: %d, Failed: %d", passCount, failCount))
if failCount > 0 then
    os.exit(1)
end

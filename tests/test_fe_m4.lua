-- test_fe_m4.lua
-- Unit & Integration Tests for ZenAlign FE-M4: Action Bar Grid & Row/Column Layout Engine

-- 1. Mock WoW 3.3.5a API Environment
local mockFrames = {}
local mockScreen = { width = 1920, height = 1080 }
local inCombatLockdownState = false

_G.GetScreenWidth = function() return mockScreen.width end
_G.GetScreenHeight = function() return mockScreen.height end
_G.InCombatLockdown = function() return inCombatLockdownState end

_G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg) end
}
_G.SlashCmdList = {}

local FrameMT = {}
FrameMT.__index = FrameMT

-- Note: SetSize does NOT exist in 3.3.5a frame API. FrameMT:SetSize is omitted to ensure 3.3.5a compliance.
function FrameMT:SetWidth(w) self.width = w end
function FrameMT:SetHeight(h) self.height = h end
function FrameMT:GetWidth() return self.width or 36 end
function FrameMT:GetHeight() return self.height or 36 end
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
        width = 36,
        height = 36,
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

-- Create mock standard Blizzard Action Bar buttons
local function createMockBarButtons(prefix, count, width, height)
    width = width or 36
    height = height or 36
    for i = 1, count do
        local btnName = prefix .. i
        local btn = _G.CreateFrame("CheckButton", btnName, UIParent, "ActionButtonTemplate")
        btn:SetWidth(width)
        btn:SetHeight(height)
    end
end

createMockBarButtons("ActionButton", 12, 36, 36)
createMockBarButtons("MultiBarBottomLeftButton", 12, 36, 36)
createMockBarButtons("MultiBarBottomRightButton", 12, 36, 36)
createMockBarButtons("MultiBarRightButton", 12, 36, 36)
createMockBarButtons("MultiBarLeftButton", 12, 36, 36)
createMockBarButtons("PetActionButton", 10, 30, 30)
createMockBarButtons("ShapeshiftButton", 10, 30, 30)

_G.MainMenuBar = _G.CreateFrame("Frame", "MainMenuBar", UIParent)
_G.MultiBarBottomLeft = _G.CreateFrame("Frame", "MultiBarBottomLeft", UIParent)
_G.MultiBarBottomRight = _G.CreateFrame("Frame", "MultiBarBottomRight", UIParent)
_G.MultiBarRight = _G.CreateFrame("Frame", "MultiBarRight", UIParent)
_G.MultiBarLeft = _G.CreateFrame("Frame", "MultiBarLeft", UIParent)
_G.PetActionBarFrame = _G.CreateFrame("Frame", "PetActionBarFrame", UIParent)
_G.ShapeshiftBarFrame = _G.CreateFrame("Frame", "ShapeshiftBarFrame", UIParent)

-- Load ZenAlign core files & BarLayout module
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
loadScript("ZenAlign/Modules/BarLayout.lua")

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

print("=== Running ZenAlign FE-M4: Action Bar Grid & Row/Column Layout Engine Tests ===")

local BarLayout = ZenAlign:GetModule("BarLayout")
assert_true(BarLayout ~= nil, "BarLayout module loaded")

-- 1. Test Suite 1: Module Registration & Setup
print("\n--- Test Suite 1: Module Registration & Initialization ---")
assert_true(BarLayout.pendingLayouts ~= nil, "pendingLayouts table initialized")
assert_true(BarLayout.containers ~= nil, "containers table initialized")
assert_true(BarLayout.configs ~= nil, "configs table initialized")

-- 2. Test Suite 2: GetBarButtons Mapping
print("\n--- Test Suite 2: GetBarButtons Mapping ---")
local mainButtons = BarLayout:GetBarButtons("MainMenuBar")
assert_eq(#mainButtons, 12, "MainMenuBar returned 12 buttons")
assert_eq(mainButtons[1]:GetName(), "ActionButton1", "First button is ActionButton1")
assert_eq(mainButtons[12]:GetName(), "ActionButton12", "Twelfth button is ActionButton12")

local mbblButtons = BarLayout:GetBarButtons("MultiBarBottomLeft")
assert_eq(#mbblButtons, 12, "MultiBarBottomLeft returned 12 buttons")
assert_eq(mbblButtons[1]:GetName(), "MultiBarBottomLeftButton1", "First button is MultiBarBottomLeftButton1")

local petButtons = BarLayout:GetBarButtons("PetActionBarFrame")
assert_eq(#petButtons, 10, "PetActionBarFrame returned 10 buttons")
assert_eq(petButtons[1]:GetName(), "PetActionButton1", "First button is PetActionButton1")

local stanceButtons = BarLayout:GetBarButtons("ShapeshiftBarFrame")
assert_eq(#stanceButtons, 10, "ShapeshiftBarFrame returned 10 buttons")
assert_eq(stanceButtons[1]:GetName(), "ShapeshiftButton1", "First button is ShapeshiftButton1")

-- 3. Test Suite 3: Container Creation & Sizing Formulas Across 6 Grid Configurations
print("\n--- Test Suite 3: Container Creation & Sizing (All 6 Grids) ---")
-- Default spacing Sx=4, Sy=4, padding P=6, button size 36x36
-- Grid 1: 1x12 (Horizontal bar) -> W = 12*36 + 11*4 + 12 = 488, H = 1*36 + 0*4 + 12 = 48
local container1, w1, h1 = BarLayout:ApplyLayout("MainMenuBar", { rows = 1, cols = 12, spacing = 4, padding = 6 })
assert_eq(w1, 488, "Grid 1x12 width formula: 488")
assert_eq(h1, 48, "Grid 1x12 height formula: 48")
assert_eq(container1:GetWidth(), 488, "Container 1x12 width set to 488")
assert_eq(container1:GetHeight(), 48, "Container 1x12 height set to 48")

-- Grid 2: 2x6 (2 Rows, 6 Columns) -> W = 6*36 + 5*4 + 12 = 248, H = 2*36 + 1*4 + 12 = 88
local container2, w2, h2 = BarLayout:ApplyLayout("MainMenuBar", { rows = 2, cols = 6, spacing = 4, padding = 6 })
assert_eq(w2, 248, "Grid 2x6 width formula: 248")
assert_eq(h2, 88, "Grid 2x6 height formula: 88")

-- Grid 3: 3x4 (Keypad grid) -> W = 4*36 + 3*4 + 12 = 168, H = 3*36 + 2*4 + 12 = 128
local container3, w3, h3 = BarLayout:ApplyLayout("MainMenuBar", { rows = 3, cols = 4, spacing = 4, padding = 6 })
assert_eq(w3, 168, "Grid 3x4 width formula: 168")
assert_eq(h3, 128, "Grid 3x4 height formula: 128")

-- Grid 4: 4x3 (Vertical block) -> W = 3*36 + 2*4 + 12 = 128, H = 4*36 + 3*4 + 12 = 168
local container4, w4, h4 = BarLayout:ApplyLayout("MainMenuBar", { rows = 4, cols = 3, spacing = 4, padding = 6 })
assert_eq(w4, 128, "Grid 4x3 width formula: 128")
assert_eq(h4, 168, "Grid 4x3 height formula: 168")

-- Grid 5: 6x2 (Tall 2-Column bar) -> W = 2*36 + 1*4 + 12 = 88, H = 6*36 + 5*4 + 12 = 248
local container5, w5, h5 = BarLayout:ApplyLayout("MainMenuBar", { rows = 6, cols = 2, spacing = 4, padding = 6 })
assert_eq(w5, 88, "Grid 6x2 width formula: 88")
assert_eq(h5, 248, "Grid 6x2 height formula: 248")

-- Grid 6: 12x1 (Vertical bar) -> W = 1*36 + 0*4 + 12 = 48, H = 12*36 + 11*4 + 12 = 488
local container6, w6, h6 = BarLayout:ApplyLayout("MainMenuBar", { rows = 12, cols = 1, spacing = 4, padding = 6 })
assert_eq(w6, 48, "Grid 12x1 width formula: 48")
assert_eq(h6, 488, "Grid 12x1 height formula: 488")

-- 4. Test Suite 4: Button Grid Coordinate Math & Anchoring Calculations
print("\n--- Test Suite 4: Button Coordinate Math & Anchoring ---")
-- Apply 3x4 (3 rows, 4 cols) to MainMenuBar
BarLayout:ApplyLayout("MainMenuBar", { rows = 3, cols = 4, spacing = 4, padding = 6 })

-- ActionButton1: i=1, idx=0 -> row=0, col=0 -> X = 6 + 0*(36+4) = 6, Y = -6 - 0*(36+4) = -6
local btn1 = _G["ActionButton1"]
local point1, rel1, relPoint1, x1, y1 = btn1:GetPoint()
assert_eq(point1, "TOPLEFT", "ActionButton1 anchored to TOPLEFT")
assert_eq(x1, 6, "ActionButton1 X coord is 6")
assert_eq(y1, -6, "ActionButton1 Y coord is -6")

-- ActionButton2: i=2, idx=1 -> row=0, col=1 -> X = 6 + 1*40 = 46, Y = -6
local btn2 = _G["ActionButton2"]
local point2, rel2, relPoint2, x2, y2 = btn2:GetPoint()
assert_eq(x2, 46, "ActionButton2 X coord is 46")
assert_eq(y2, -6, "ActionButton2 Y coord is -6")

-- ActionButton5: i=5, idx=4 -> row=1, col=0 -> X = 6, Y = -6 - 1*40 = -46
local btn5 = _G["ActionButton5"]
local point5, rel5, relPoint5, x5, y5 = btn5:GetPoint()
assert_eq(x5, 6, "ActionButton5 X coord is 6")
assert_eq(y5, -46, "ActionButton5 Y coord is -46")

-- ActionButton12: i=12, idx=11 -> row=2, col=3 -> X = 6 + 3*40 = 126, Y = -6 - 2*40 = -86
local btn12 = _G["ActionButton12"]
local point12, rel12, relPoint12, x12, y12 = btn12:GetPoint()
assert_eq(x12, 126, "ActionButton12 X coord is 126")
assert_eq(y12, -86, "ActionButton12 Y coord is -86")

-- 5. Test Suite 5: Custom Spacing & Padding Variations
print("\n--- Test Suite 5: Custom Spacing & Padding Variations ---")
-- MultiBarBottomLeft with 2x6 grid, custom spacing Sx=8, Sy=10, padding P=12, Wb=36, Hb=36
-- Container W = 6*36 + 5*8 + 2*12 = 216 + 40 + 24 = 280
-- Container H = 2*36 + 1*10 + 2*12 = 72 + 10 + 24 = 106
local cCustom, wCustom, hCustom = BarLayout:ApplyLayout("MultiBarBottomLeft", {
    rows = 2,
    cols = 6,
    spacing = { x = 8, y = 10 },
    padding = 12,
})

assert_eq(wCustom, 280, "Custom spacing/padding width formula: 280")
assert_eq(hCustom, 106, "Custom spacing/padding height formula: 106")

-- Check MultiBarBottomLeftButton2 (row 0, col 1): X = 12 + 1*(36+8) = 56, Y = -12
local customBtn2 = _G["MultiBarBottomLeftButton2"]
local _, _, _, cx2, cy2 = customBtn2:GetPoint()
assert_eq(cx2, 56, "MultiBarBottomLeftButton2 custom X is 56")
assert_eq(cy2, -12, "MultiBarBottomLeftButton2 custom Y is -12")

-- Check MultiBarBottomLeftButton7 (row 1, col 0): X = 12, Y = -12 - 1*(36+10) = -58
local customBtn7 = _G["MultiBarBottomLeftButton7"]
local _, _, _, cx7, cy7 = customBtn7:GetPoint()
assert_eq(cx7, 12, "MultiBarBottomLeftButton7 custom X is 12")
assert_eq(cy7, -58, "MultiBarBottomLeftButton7 custom Y is -58")

-- 6. Test Suite 6: Combat Lockdown Protection Queue & PLAYER_REGEN_ENABLED Execution
print("\n--- Test Suite 6: Combat Lockdown Queue & Event Deferred Execution ---")
inCombatLockdownState = true

-- Call SetBarLayout while in combat
local success, msg = BarLayout:SetBarLayout("MultiBarRight", 4, 3, 4, 6)
assert_true(not success, "SetBarLayout returned false while in combat")
assert_true(BarLayout.pendingLayouts["MultiBarRight"] ~= nil, "Layout request queued in pendingLayouts")
assert_eq(BarLayout.pendingLayouts["MultiBarRight"].rows, 4, "Queued config rows = 4")
assert_eq(BarLayout.pendingLayouts["MultiBarRight"].cols, 3, "Queued config cols = 3")

-- Event handler trigger while STILL in combat (should not execute)
local eventFrame = _G.ZenAlignBarLayoutFrame
assert_true(eventFrame ~= nil, "ZenAlignBarLayoutFrame event frame exists")
local onEvent = eventFrame:GetScript("OnEvent")
assert_true(onEvent ~= nil, "OnEvent handler attached to ZenAlignBarLayoutFrame")

onEvent(eventFrame, "PLAYER_REGEN_ENABLED")
assert_true(BarLayout.pendingLayouts["MultiBarRight"] ~= nil, "Pending layout still queued if combat hasn't ended")

-- Exit combat and trigger PLAYER_REGEN_ENABLED
inCombatLockdownState = false
onEvent(eventFrame, "PLAYER_REGEN_ENABLED")

assert_true(BarLayout.pendingLayouts["MultiBarRight"] == nil, "Pending layout cleared after PLAYER_REGEN_ENABLED")

local mbRightContainer = BarLayout.containers["MultiBarRight"]
assert_true(mbRightContainer ~= nil, "MultiBarRight container created after combat ended")
assert_eq(mbRightContainer:GetWidth(), 128, "MultiBarRight container width updated to 128 (4x3 grid)")
assert_eq(mbRightContainer:GetHeight(), 168, "MultiBarRight container height updated to 168 (4x3 grid)")

-- Verify MultiBarRightButton1 point after combat queue processing
local mbrBtn1 = _G["MultiBarRightButton1"]
local _, _, _, mbrX1, mbrY1 = mbrBtn1:GetPoint()
assert_eq(mbrX1, 6, "MultiBarRightButton1 X coord is 6 after regen")
assert_eq(mbrY1, -6, "MultiBarRightButton1 Y coord is -6 after regen")

-- 7. Test Suite 7: Slash Command Integration (/za bar)
print("\n--- Test Suite 7: Slash Command Integration (/za bar) ---")
ZenAlign:HandleSlashCommand("bar MultiBarLeft 6 2")

local mbLeftContainer = BarLayout.containers["MultiBarLeft"]
assert_true(mbLeftContainer ~= nil, "MultiBarLeft container created via slash command")
assert_eq(mbLeftContainer:GetWidth(), 88, "MultiBarLeft width is 88 (6x2 grid)")
assert_eq(mbLeftContainer:GetHeight(), 248, "MultiBarLeft height is 248 (6x2 grid)")

print("\n=== Test Results ===")
print(string.format("Passed: %d, Failed: %d", passCount, failCount))
if failCount > 0 then
    os.exit(1)
end

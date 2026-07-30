-- tests/test_gl_m3.lua
-- Comprehensive Unit & Integration Test Suite for GL-M3: Bar Layout, Styling & Combat Queue

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

-- 1. Mock WoW 3.3.5a API Environment
local inCombat = false
_G.InCombatLockdown = function()
    return inCombat
end

local mockFrames = {}
local registeredEvents = {}

local MockFontString = {}
MockFontString.__index = MockFontString

function MockFontString.new(name)
    local self = setmetatable({}, MockFontString)
    self.name = name
    self.text = ""
    self.visible = true
    if name then _G[name] = self end
    return self
end

function MockFontString:SetText(t) self.text = t end
function MockFontString:GetText() return self.text end
function MockFontString:Show() self.visible = true end
function MockFontString:Hide() self.visible = false end
function MockFontString:IsShown() return self.visible end

local MockFrame = {}
MockFrame.__index = MockFrame

function MockFrame.new(name)
    local self = setmetatable({}, MockFrame)
    self.name = name
    self.points = {}
    self.width = 36
    self.height = 36
    self.visible = true
    self.attributes = {}
    self.children = {}
    self.scripts = {}
    if name then _G[name] = self end
    return self
end

function MockFrame:SetName(name)
    self.name = name
    if name then _G[name] = self end
end

function MockFrame:GetName() return self.name end

function MockFrame:SetPoint(point, relativeTo, relativePoint, x, y)
    table.insert(self.points, {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        x = x or 0,
        y = y or 0,
    })
end

function MockFrame:ClearAllPoints()
    self.points = {}
end

function MockFrame:GetPoint(index)
    index = index or 1
    local p = self.points[index]
    if p then
        return p.point, p.relativeTo, p.relativePoint, p.x, p.y
    end
end

function MockFrame:SetWidth(w) self.width = w end
function MockFrame:GetWidth() return self.width end
function MockFrame:SetHeight(h) self.height = h end
function MockFrame:GetHeight() return self.height end
function MockFrame:Show() self.visible = true end
function MockFrame:Hide() self.visible = false end
function MockFrame:IsShown() return self.visible end

function MockFrame:SetAttribute(k, v) self.attributes[k] = v end
function MockFrame:GetAttribute(k) return self.attributes[k] end

function MockFrame:GetChildren() return unpack(self.children) end
function MockFrame:AddChild(c) table.insert(self.children, c) end

function MockFrame:SetScript(evt, fn) self.scripts[evt] = fn end
function MockFrame:GetScript(evt) return self.scripts[evt] end

function MockFrame:RegisterEvent(evt)
    registeredEvents[evt] = registeredEvents[evt] or {}
    table.insert(registeredEvents[evt], self)
end

_G.CreateFrame = function(frameType, name, parent)
    local f = MockFrame.new(name)
    if parent then f:SetParent(parent) end
    return f
end

local shownGridButtons = {}
local hiddenGridButtons = {}
_G.ActionButton_ShowGrid = function(btn)
    shownGridButtons[btn] = true
    hiddenGridButtons[btn] = nil
end

_G.ActionButton_HideGrid = function(btn)
    hiddenGridButtons[btn] = true
    shownGridButtons[btn] = nil
end

-- 2. Load BarLayout Module
local BarLayout = dofile("GridLock/Modules/BarLayout.lua")
local GridLock = _G.GridLock

print("=========================================")
print("Running GL-M3 Action Button Styling & Grid Customization Tests")
print("=========================================")

-- Test Group 1: Public API Exposure
print("[Test Group 1] Public API Exposure on GridLock")
assert_true(type(GridLock.SetBarLayout) == "function", "SetBarLayout is exposed")
assert_true(type(GridLock.SetBarGridVisibility) == "function", "SetBarGridVisibility is exposed")
assert_true(type(GridLock.ToggleBarHotkeys) == "function", "ToggleBarHotkeys is exposed")
assert_true(type(GridLock.ToggleBarMacroText) == "function", "ToggleBarMacroText is exposed")
assert_true(type(GridLock.QueueCombatAction) == "function", "QueueCombatAction is exposed")
assert_true(type(GridLock.FormatHotkeyText) == "function", "FormatHotkeyText is exposed")
assert_true(type(GridLock.FlushCombatQueue) == "function", "FlushCombatQueue is exposed")

-- Test Group 2: Hotkey Text Shortening Engine
print("[Test Group 2] Hotkey Text Shortening Engine")
assert_eq(GridLock:FormatHotkeyText("SHIFT-1"), "s1", "SHIFT-1 -> s1")
assert_eq(GridLock:FormatHotkeyText("CTRL-A"), "cA", "CTRL-A -> cA")
assert_eq(GridLock:FormatHotkeyText("ALT-B"), "aB", "ALT-B -> aB")
assert_eq(GridLock:FormatHotkeyText("CTRL-ALT-A"), "caA", "CTRL-ALT-A -> caA")
assert_eq(GridLock:FormatHotkeyText("ALT-SHIFT-BUTTON3"), "asM3", "ALT-SHIFT-BUTTON3 -> asM3")
assert_eq(GridLock:FormatHotkeyText("CTRL-NUMPAD5"), "cN5", "CTRL-NUMPAD5 -> cN5")
assert_eq(GridLock:FormatHotkeyText("NUMPAD1"), "N1", "NUMPAD1 -> N1")
assert_eq(GridLock:FormatHotkeyText("SHIFT-MOUSEWHEELUP"), "sWU", "SHIFT-MOUSEWHEELUP -> sWU")
assert_eq(GridLock:FormatHotkeyText("CTRL-PAGEDOWN"), "cPD", "CTRL-PAGEDOWN -> cPD")
assert_eq(GridLock:FormatHotkeyText("ALT-SPACE"), "aSpc", "ALT-SPACE -> aSpc")
assert_eq(GridLock:FormatHotkeyText("CTRL-DELETE"), "cDel", "CTRL-DELETE -> cDel")
assert_eq(GridLock:FormatHotkeyText("Shift-Ctrl-Alt-Insert"), "scaIns", "Shift-Ctrl-Alt-Insert -> scaIns")
assert_eq(GridLock:FormatHotkeyText(""), "", "Empty string -> empty string")
assert_eq(GridLock:FormatHotkeyText(nil), "", "nil -> empty string")

-- Helper to construct a mock bar with 12 buttons
local function createMockBar(barName)
    local bar = MockFrame.new(barName)
    bar.buttons = {}
    for i = 1, 12 do
        local btnName = barName .. "Button" .. i
        local btn = MockFrame.new(btnName)
        btn:SetWidth(36)
        btn:SetHeight(36)
        
        -- Create hotkey and macro fontstrings
        local hotkey = MockFontString.new(btnName .. "HotKey")
        hotkey:SetText("SHIFT-" .. i)
        btn.HotKey = hotkey
        
        local macro = MockFontString.new(btnName .. "Name")
        macro:SetText("Macro" .. i)
        btn.Name = macro
        
        table.insert(bar.buttons, btn)
    end
    return bar
end

-- Test Group 3: All 6 Grid Dimension Layout Calculations
print("[Test Group 3] Grid Layout Calculations Across All 6 Dimensions")

-- 3.1: 1x12 (1 row, 12 cols)
local bar1 = createMockBar("GridLockBar1")
GridLock:SetBarLayout(bar1, 1, 12, 4, 5) -- R=1, C=12, spacing=4, padding=5
-- Width: 12 * 36 + 11 * 4 + 2 * 5 = 432 + 44 + 10 = 486
-- Height: 1 * 36 + 0 * 4 + 2 * 5 = 36 + 10 = 46
assert_eq(bar1:GetWidth(), 486, "1x12 Bar width calculation (486)")
assert_eq(bar1:GetHeight(), 46, "1x12 Bar height calculation (46)")

local p1, _, _, x1, y1 = bar1.buttons[1]:GetPoint(1)
assert_eq(x1, 5, "1x12 Button 1 x offset (5)")
assert_eq(y1, -5, "1x12 Button 1 y offset (-5)")

local p12, _, _, x12, y12 = bar1.buttons[12]:GetPoint(1)
-- Button 12 (col 11, row 0): X = 5 + 11 * (36 + 4) = 5 + 440 = 445, Y = -5
assert_eq(x12, 445, "1x12 Button 12 x offset (445)")
assert_eq(y12, -5, "1x12 Button 12 y offset (-5)")

-- 3.2: 2x6 (2 rows, 6 cols)
local bar2 = createMockBar("GridLockBar2")
GridLock:SetBarLayout(bar2, 2, 6, 4, 5) -- R=2, C=6, spacing=4, padding=5
-- Width: 6 * 36 + 5 * 4 + 10 = 216 + 20 + 10 = 246
-- Height: 2 * 36 + 1 * 4 + 10 = 72 + 4 + 10 = 86
assert_eq(bar2:GetWidth(), 246, "2x6 Bar width calculation (246)")
assert_eq(bar2:GetHeight(), 86, "2x6 Bar height calculation (86)")

local _, _, _, x7_2, y7_2 = bar2.buttons[7]:GetPoint(1)
-- Button 7 (col 0, row 1): X = 5 + 0 = 5, Y = -5 - 1 * (36 + 4) = -45
assert_eq(x7_2, 5, "2x6 Button 7 x offset (5)")
assert_eq(y7_2, -45, "2x6 Button 7 y offset (-45)")

local _, _, _, x12_2, y12_2 = bar2.buttons[12]:GetPoint(1)
-- Button 12 (col 5, row 1): X = 5 + 5 * 40 = 205, Y = -45
assert_eq(x12_2, 205, "2x6 Button 12 x offset (205)")
assert_eq(y12_2, -45, "2x6 Button 12 y offset (-45)")

-- 3.3: 3x4 (3 rows, 4 cols)
local bar3 = createMockBar("GridLockBar3")
GridLock:SetBarLayout(bar3, 3, 4, 4, 5)
-- Width: 4 * 36 + 3 * 4 + 10 = 144 + 12 + 10 = 166
-- Height: 3 * 36 + 2 * 4 + 10 = 108 + 8 + 10 = 126
assert_eq(bar3:GetWidth(), 166, "3x4 Bar width calculation (166)")
assert_eq(bar3:GetHeight(), 126, "3x4 Bar height calculation (126)")

-- 3.4: 4x3 (4 rows, 3 cols)
local bar4 = createMockBar("GridLockBar4")
GridLock:SetBarLayout(bar4, 4, 3, 4, 5)
-- Width: 3 * 36 + 2 * 4 + 10 = 108 + 8 + 10 = 126
-- Height: 4 * 36 + 3 * 4 + 10 = 144 + 12 + 10 = 166
assert_eq(bar4:GetWidth(), 126, "4x3 Bar width calculation (126)")
assert_eq(bar4:GetHeight(), 166, "4x3 Bar height calculation (166)")

-- 3.5: 6x2 (6 rows, 2 cols)
local bar5 = createMockBar("GridLockBar5")
GridLock:SetBarLayout(bar5, 6, 2, 4, 5)
-- Width: 2 * 36 + 1 * 4 + 10 = 72 + 4 + 10 = 86
-- Height: 6 * 36 + 5 * 4 + 10 = 216 + 20 + 10 = 246
assert_eq(bar5:GetWidth(), 86, "6x2 Bar width calculation (86)")
assert_eq(bar5:GetHeight(), 246, "6x2 Bar height calculation (246)")

-- 3.6: 12x1 (12 rows, 1 col)
local bar6 = createMockBar("GridLockBar6")
GridLock:SetBarLayout(bar6, 12, 1, 4, 5)
-- Width: 1 * 36 + 0 * 4 + 10 = 46
-- Height: 12 * 36 + 11 * 4 + 10 = 432 + 44 + 10 = 486
assert_eq(bar6:GetWidth(), 46, "12x1 Bar width calculation (46)")
assert_eq(bar6:GetHeight(), 486, "12x1 Bar height calculation (486)")

-- 3.7: Asymmetric Spacing Table { x = 8, y = 6 }
local barAsym = createMockBar("GridLockBarAsym")
GridLock:SetBarLayout(barAsym, 2, 6, { x = 8, y = 6 }, 10)
-- Width: 6 * 36 + 5 * 8 + 2 * 10 = 216 + 40 + 20 = 276
-- Height: 2 * 36 + 1 * 6 + 2 * 10 = 72 + 6 + 20 = 98
assert_eq(barAsym:GetWidth(), 276, "Asymmetric Bar width (276)")
assert_eq(barAsym:GetHeight(), 98, "Asymmetric Bar height (98)")
local _, _, _, x7_asym, y7_asym = barAsym.buttons[7]:GetPoint(1)
-- Button 7 (col 0, row 1): X = 10, Y = -10 - 1 * (36 + 6) = -52
assert_eq(x7_asym, 10, "Asymmetric Button 7 X (10)")
assert_eq(y7_asym, -52, "Asymmetric Button 7 Y (-52)")


-- Test Group 4: Grid Visibility Controls
print("[Test Group 4] Grid Visibility Controls & Attribute Toggling")
local gridBar = createMockBar("GridLockGridBar")

-- Enable Grid Visibility (showGrid = true)
GridLock:SetBarGridVisibility(gridBar, true)
assert_eq(gridBar:GetAttribute("showgrid"), 1, "Bar showgrid attribute set to 1")
assert_true(gridBar.showGrid, "bar.showGrid flag is true")
for _, btn in ipairs(gridBar.buttons) do
    assert_eq(btn:GetAttribute("showgrid"), 1, "Button showgrid attribute set to 1")
    assert_true(shownGridButtons[btn], "ActionButton_ShowGrid called for button")
end

-- Enable Grid Visibility with numeric value 2
GridLock:SetBarGridVisibility(gridBar, 2)
assert_eq(gridBar:GetAttribute("showgrid"), 2, "Bar showgrid attribute set to 2")
for _, btn in ipairs(gridBar.buttons) do
    assert_eq(btn:GetAttribute("showgrid"), 2, "Button showgrid attribute set to 2")
end

-- Disable Grid Visibility (showGrid = false)
GridLock:SetBarGridVisibility(gridBar, false)
assert_eq(gridBar:GetAttribute("showgrid"), 0, "Bar showgrid attribute set to 0")
assert_false(gridBar.showGrid, "bar.showGrid flag is false")
for _, btn in ipairs(gridBar.buttons) do
    assert_eq(btn:GetAttribute("showgrid"), 0, "Button showgrid attribute set to 0")
    assert_true(hiddenGridButtons[btn], "ActionButton_HideGrid called for button")
end


-- Test Group 5: Hotkey & Macro Text Toggling
print("[Test Group 5] Hotkey & Macro Text FontString Toggling")
local textBar = createMockBar("GridLockTextBar")

-- Toggle Hotkeys Off
GridLock:ToggleBarHotkeys(textBar, false)
assert_false(textBar.showHotkeys, "showHotkeys stored as false")
for _, btn in ipairs(textBar.buttons) do
    local hotkey = _G[btn:GetName() .. "HotKey"]
    assert_false(hotkey:IsShown(), "Hotkey FontString hidden")
end

-- Toggle Hotkeys On
GridLock:ToggleBarHotkeys(textBar, true)
assert_true(textBar.showHotkeys, "showHotkeys stored as true")
for i, btn in ipairs(textBar.buttons) do
    local hotkey = _G[btn:GetName() .. "HotKey"]
    assert_true(hotkey:IsShown(), "Hotkey FontString shown")
    assert_eq(hotkey:GetText(), "s" .. i, "Hotkey text formatted with shortening (s1..s12)")
end

-- Toggle Macro Text Off
GridLock:ToggleBarMacroText(textBar, false)
assert_false(textBar.showMacroText, "showMacroText stored as false")
for _, btn in ipairs(textBar.buttons) do
    local macro = _G[btn:GetName() .. "Name"]
    assert_false(macro:IsShown(), "Macro FontString hidden")
end

-- Toggle Macro Text On
GridLock:ToggleBarMacroText(textBar, true)
assert_true(textBar.showMacroText, "showMacroText stored as true")
for _, btn in ipairs(textBar.buttons) do
    local macro = _G[btn:GetName() .. "Name"]
    assert_true(macro:IsShown(), "Macro FontString shown")
end


-- Test Group 6: Combat Lockdown Protection Queue
print("[Test Group 6] Combat Lockdown Protection Queue")

local combatBar = createMockBar("GridLockCombatBar")
GridLock:SetBarLayout(combatBar, 1, 12, 2, 2)
assert_eq(combatBar:GetWidth(), 458, "Pre-combat bar width 458")

-- Enter combat
inCombat = true

-- Attempt layout modification in combat
GridLock:SetBarLayout(combatBar, 2, 6, 10, 10)
-- Width should NOT change during combat lockdown
assert_eq(combatBar:GetWidth(), 458, "Bar layout change deferred during combat lockdown")
assert_eq(#GridLock.pendingQueue, 1, "1 action queued in pendingQueue")

-- Attempt grid visibility toggle in combat
GridLock:SetBarGridVisibility(combatBar, true)
assert_eq(#GridLock.pendingQueue, 2, "2 actions queued in pendingQueue")
assert_eq(combatBar:GetAttribute("showgrid"), nil, "Grid visibility attribute unchanged during combat")

-- Attempt hotkey toggle in combat
GridLock:ToggleBarHotkeys(combatBar, false)
assert_eq(#GridLock.pendingQueue, 3, "3 actions queued in pendingQueue")

-- Attempt custom queued action
local customActionRun = false
GridLock:QueueCombatAction(function()
    customActionRun = true
end)
assert_eq(#GridLock.pendingQueue, 4, "4 actions queued in pendingQueue")
assert_false(customActionRun, "Custom action deferred during combat lockdown")

-- Exit combat and trigger PLAYER_REGEN_ENABLED
inCombat = false
local eventListeners = registeredEvents["PLAYER_REGEN_ENABLED"] or {}
assert_true(#eventListeners > 0, "PLAYER_REGEN_ENABLED registered on event frame")

-- Simulate event firing / FlushCombatQueue
GridLock:FlushCombatQueue()

assert_eq(#GridLock.pendingQueue, 0, "pendingQueue is empty after flushing")
-- Check deferred modifications were executed
assert_eq(combatBar:GetWidth(), 286, "Deferred 2x6 bar layout applied post-combat (286)")
assert_eq(combatBar:GetAttribute("showgrid"), 1, "Deferred grid visibility attribute set post-combat")
assert_false(combatBar.showHotkeys, "Deferred hotkey toggle applied post-combat")
assert_true(customActionRun, "Deferred custom action executed post-combat")

print("=========================================")
print(string.format("All GL-M3 Tests PASSED! (Passed: %d, Failed: %d)", passCount, failCount))
print("=========================================")

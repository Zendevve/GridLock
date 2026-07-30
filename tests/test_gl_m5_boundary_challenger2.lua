-- tests/test_gl_m5_boundary_challenger2.lua
-- Adversarial Boundary & Edge Case Test Suite for GridLock GL-M5 (Action Bars & Special Bars)

local unpack = unpack or table.unpack

local passCount = 0
local failCount = 0
local testLog = {}

local function log_result(testName, status, details)
    table.insert(testLog, { name = testName, status = status, details = details })
    if status == "PASS" then
        passCount = passCount + 1
        print(string.format("  [PASS] %s", testName))
    else
        failCount = failCount + 1
        print(string.format("  [FAIL] %s: %s", testName, tostring(details)))
    end
end

local function assert_eq(actual, expected, msg)
    if actual == expected then
        return true
    else
        local err = string.format("%s (Expected: %s, Actual: %s)", tostring(msg), tostring(expected), tostring(actual))
        error(err)
    end
end

local function assert_near(actual, expected, tol, msg)
    tol = tol or 0.001
    if math.abs(actual - expected) <= tol then
        return true
    else
        local err = string.format("%s (Expected ~%s, Actual: %s)", tostring(msg), tostring(expected), tostring(actual))
        error(err)
    end
end

local function assert_true(cond, msg)
    if cond then return true else error("Assertion failed: " .. tostring(msg)) end
end

local function assert_false(cond, msg)
    if not cond then return true else error("Assertion failed (expected false): " .. tostring(msg)) end
end

-- ============================================================================
-- 1. Mock WoW Environment Setup
-- ============================================================================
_G.InCombatLockdown = function() return false end
local mockClass = "WARRIOR"
_G.UnitClass = function(unit)
    if unit == "player" then
        return "Warrior", mockClass
    end
    return "Unknown", "UNKNOWN"
end

local mockInVehicle = false
local mockCanExitVehicle = false
_G.UnitInVehicle = function(unit) return mockInVehicle end
_G.CanExitVehicle = function() return mockCanExitVehicle end

_G.hooksecurefunc = function(name, hook)
    local orig = _G[name]
    _G[name] = function(...)
        if orig then orig(...) end
        hook(...)
    end
end

-- Mock Frame Class
local MockFrame = {}
MockFrame.__index = MockFrame

function MockFrame.new(name, frameType, parent)
    local self = setmetatable({}, MockFrame)
    self.name = name
    self.frameType = frameType or "Frame"
    self.parent = parent
    self.width = 36
    self.height = 36
    self.scale = 1.0
    self.alpha = 1.0
    self.visible = true
    self.points = {}
    self.attributes = {}
    self.scripts = {}
    self.events = {}
    self.eventsUnregistered = false
    self.text = ""
    
    if name then
        _G[name] = self
    end
    return self
end

function MockFrame:GetName() return self.name end
function MockFrame:GetWidth() return self.width end
function MockFrame:GetHeight() return self.height end
function MockFrame:SetWidth(w) self.width = w end
function MockFrame:SetHeight(h) self.height = h end
function MockFrame:SetSize(w, h) self.width = w; self.height = h end
function MockFrame:GetScale() return self.scale end
function MockFrame:SetScale(s) self.scale = s end
function MockFrame:GetAlpha() return self.alpha end
function MockFrame:SetAlpha(a) self.alpha = a end
function MockFrame:Show() self.visible = true end
function MockFrame:Hide() self.visible = false end
function MockFrame:IsShown() return self.visible end

function MockFrame:ClearAllPoints()
    self.points = {}
end
function MockFrame:SetPoint(point, relTo, relPoint, x, y)
    table.insert(self.points, { point = point, relTo = relTo, relPoint = relPoint, x = x, y = y })
end
function MockFrame:GetPoint(index)
    index = index or 1
    local p = self.points[index]
    if p then
        return p.point, p.relTo, p.relPoint, p.x, p.y
    end
end

function MockFrame:SetAttribute(key, val) self.attributes[key] = val end
function MockFrame:GetAttribute(key) return self.attributes[key] end

function MockFrame:SetScript(script, fn) self.scripts[script] = fn end
function MockFrame:GetScript(script) return self.scripts[script] end

function MockFrame:RegisterEvent(evt) self.events[evt] = true end
function MockFrame:UnregisterAllEvents()
    self.events = {}
    self.eventsUnregistered = true
end

function MockFrame:SetParent(p) self.parent = p end
function MockFrame:GetParent() return self.parent end

function MockFrame:SetText(txt) self.text = tostring(txt or "") end
function MockFrame:GetText() return self.text end

_G.UIParent = MockFrame.new("UIParent", "Frame", nil)
_G.UIParent:SetSize(1920, 1080)

_G.CreateFrame = function(frameType, name, parent)
    return MockFrame.new(name, frameType, parent)
end

-- Load GridLock modules
local GridLock = {}
_G.GridLock = GridLock

local BarLayout = dofile("GridLock/Modules/BarLayout.lua")
local SpecialBars = dofile("GridLock/Modules/SpecialBars.lua")

print("=========================================================================")
print("  GridLock GL-M5 Boundary & Edge Case Adversarial Challenger Suite")
print("=========================================================================\n")

-- ============================================================================
-- TEST SECTION 1: Extreme Grid Layout Configurations (Task 2)
-- ============================================================================
print("--- [GROUP 1] Extreme Grid Layout Configurations ---")

-- Test 1.1: SetBarLayout with 0 rows and 0 cols
local status1_1, err1_1 = pcall(function()
    local bar = MockFrame.new("TestBar1", "Frame", _G.UIParent)
    bar.buttons = {}
    for i = 1, 12 do
        local btn = MockFrame.new("TestBar1Button" .. i, "CheckButton", bar)
        btn:SetSize(36, 36)
        table.insert(bar.buttons, btn)
    end

    -- Call with 0 rows and 0 cols
    GridLock:SetBarLayout(bar, 0, 0, 2, 2)
    
    -- Verification: cols should be fallback to 1, rows fallback to 1 or math.ceil(12/1) = 12
    assert_eq(bar.cols, 1, "cols should be normalized from 0 to 1")
    assert_eq(bar.rows, 12, "rows should be normalized to math.ceil(12/1) = 12")
    assert_eq(bar.width, 1 * 36 + 0 * 2 + 4, "Container width should be 40")
    assert_eq(bar.height, 12 * 36 + 11 * 2 + 4, "Container height should be 458")
    
    -- Check first and last button positions
    local p1_point, _, _, p1_x, p1_y = bar.buttons[1]:GetPoint()
    assert_eq(p1_x, 2, "Button 1 x should be padding = 2")
    assert_eq(p1_y, -2, "Button 1 y should be -padding = -2")

    local p12_point, _, _, p12_x, p12_y = bar.buttons[12]:GetPoint()
    assert_eq(p12_x, 2, "Button 12 x should be padding = 2 (col 0)")
    assert_eq(p12_y, -2 - 11 * 38, "Button 12 y should be -2 - 11*38 = -420 (row 11)")
end)
log_result("SetBarLayout: 0 rows / 0 cols normalization", status1_1 and "PASS" or "FAIL", err1_1)

-- Test 1.2: SetBarLayout with Explicit Invalid Row/Col Mismatch (cols=1, rows=2 for 12 buttons)
local status1_2, err1_2 = pcall(function()
    local bar = MockFrame.new("TestBarMismatch", "Frame", _G.UIParent)
    bar.buttons = {}
    for i = 1, 12 do
        local btn = MockFrame.new("TestBarMismatchButton" .. i, "CheckButton", bar)
        btn:SetSize(36, 36)
        table.insert(bar.buttons, btn)
    end

    -- Explicit rows=2, cols=1 passed in
    GridLock:SetBarLayout(bar, 2, 1, 2, 2)
    
    -- Check if container height calculation matches actual button extent or is truncated to rows=2
    -- BarLayout line 174: H = rows * sampleHb + (rows - 1) * Sy + 2 * P = 2 * 36 + 1 * 2 + 4 = 78
    -- BUT button 12 is placed at row = 11, y = -420!
    -- This tests whether container height truncates/overflows.
    if bar.height < 458 then
        error(string.format("Container height underflow! Set to %d but buttons extend to 458px (rows parameter %d ignored actual button count)", bar.height, bar.rows))
    end
end)
log_result("SetBarLayout: Container height handling when explicit rows < required rows", status1_2 and "PASS" or "FAIL", err1_2)

-- Test 1.3: Negative Spacing (-10px) and Negative Padding (-5px)
local status1_3, err1_3 = pcall(function()
    local bar = MockFrame.new("TestBarNeg", "Frame", _G.UIParent)
    bar.buttons = {}
    for i = 1, 4 do
        local btn = MockFrame.new("TestBarNegButton" .. i, "CheckButton", bar)
        btn:SetSize(36, 36)
        table.insert(bar.buttons, btn)
    end

    -- 2x2 grid, spacing = -10, padding = -5
    GridLock:SetBarLayout(bar, 2, 2, -10, -5)
    
    -- x = P + col * (Wb + Sx) = -5 + col * (36 - 10) = -5 + col * 26
    -- y = -P - row * (Hb + Sy) = -(-5) - row * (36 - 10) = 5 - row * 26
    local _, _, _, btn2_x, _ = bar.buttons[2]:GetPoint()
    assert_eq(btn2_x, 21, "Button 2 x should be -5 + 1*26 = 21")
    
    -- Container Width W = cols * 36 + (cols - 1) * (-10) + 2 * (-5) = 2 * 36 - 10 - 10 = 52
    assert_eq(bar.width, 52, "Container width should be 52 with negative spacing/padding")
end)
log_result("SetBarLayout: Negative spacing (-10) and negative padding (-5)", status1_3 and "PASS" or "FAIL", err1_3)

-- Test 1.4: Extreme 100px Padding
local status1_4, err1_4 = pcall(function()
    local bar = MockFrame.new("TestBarPad100", "Frame", _G.UIParent)
    bar.buttons = {}
    for i = 1, 2 do
        local btn = MockFrame.new("TestBarPad100Btn" .. i, "CheckButton", bar)
        btn:SetSize(36, 36)
        table.insert(bar.buttons, btn)
    end

    GridLock:SetBarLayout(bar, 1, 2, 5, 100)
    
    local _, _, _, b1_x, b1_y = bar.buttons[1]:GetPoint()
    assert_eq(b1_x, 100, "Button 1 x should be padding 100")
    assert_eq(b1_y, -100, "Button 1 y should be -padding -100")
    
    -- W = 2 * 36 + 1 * 5 + 2 * 100 = 72 + 5 + 200 = 277
    assert_eq(bar.width, 277, "Container width should be 277")
end)
log_result("SetBarLayout: Extreme 100px padding layout math", status1_4 and "PASS" or "FAIL", err1_4)

-- Test 1.5: Rapid Reconfiguration (1x12 <-> 12x1 100 iterations)
local status1_5, err1_5 = pcall(function()
    local bar = MockFrame.new("TestBarRapid", "Frame", _G.UIParent)
    bar.buttons = {}
    for i = 1, 12 do
        local btn = MockFrame.new("TestBarRapidBtn" .. i, "CheckButton", bar)
        btn:SetSize(36, 36)
        table.insert(bar.buttons, btn)
    end

    for iter = 1, 100 do
        if iter % 2 == 1 then
            GridLock:SetBarLayout(bar, 1, 12, 2, 2)
            assert_eq(bar.width, 458, "Iter " .. iter .. " width for 1x12")
            assert_eq(bar.height, 40, "Iter " .. iter .. " height for 1x12")
        else
            GridLock:SetBarLayout(bar, 12, 1, 2, 2)
            assert_eq(bar.width, 40, "Iter " .. iter .. " width for 12x1")
            assert_eq(bar.height, 458, "Iter " .. iter .. " height for 12x1")
        end
    end
end)
log_result("SetBarLayout: Rapid 1x12 <-> 12x1 reconfiguration (100x stress)", status1_5 and "PASS" or "FAIL", err1_5)

-- Test 1.6: Scale Boundary Conditions (scale = 0, scale = -1, scale = 150)
local status1_6, err1_6 = pcall(function()
    local bar = MockFrame.new("TestBarScale", "Frame", _G.UIParent)
    GridLock:RegisterSpecialBar("TestScaleBar", bar, {})

    -- scale = 0
    GridLock:SetSpecialBarScale("TestScaleBar", 0)
    assert_eq(bar.scale, 0, "Scale 0 applied to frame")
    
    -- scale = 150 (percentage auto-convert 150 > 5 -> 1.5)
    GridLock:SetSpecialBarScale("TestScaleBar", 150)
    assert_eq(bar.scale, 1.5, "Scale 150 converted to 1.5")
    
    -- scale = 5 (Boundary check: is 5 converted to 0.05 or kept as 5.0?)
    GridLock:SetSpecialBarScale("TestScaleBar", 5)
    -- In SpecialBars: scale > 5 converts to scale/100. So 5 is NOT > 5, resulting in 5.0!
    assert_eq(bar.scale, 5.0, "Scale 5 kept as 5.0 (boundary check)")
end)
log_result("SpecialBars: Scale boundary conditions (0, 5, 150)", status1_6 and "PASS" or "FAIL", err1_6)

-- Test 1.7: Alpha Boundary Conditions (alpha = 0, alpha = -0.5, alpha = 200)
local status1_7, err1_7 = pcall(function()
    local bar = MockFrame.new("TestBarAlpha", "Frame", _G.UIParent)
    GridLock:RegisterSpecialBar("TestAlphaBar", bar, {})

    -- alpha = 0
    GridLock:SetSpecialBarAlpha("TestAlphaBar", 0)
    assert_eq(bar.alpha, 0, "Alpha 0 applied")

    -- alpha = 200 (auto-convert > 1.0 -> 2.0)
    GridLock:SetSpecialBarAlpha("TestAlphaBar", 200)
    assert_eq(bar.alpha, 2.0, "Alpha 200 converted to 2.0")
end)
log_result("SpecialBars: Alpha boundary conditions (0, 200)", status1_7 and "PASS" or "FAIL", err1_7)

print("\n--- [GROUP 2] Hotkey String Edge Cases ---")

-- Test 2.1: Empty, Nil, Non-String Hotkeys
local status2_1, err2_1 = pcall(function()
    assert_eq(GridLock:FormatHotkeyText(""), "", "Empty string returns empty string")
    assert_eq(GridLock:FormatHotkeyText(nil), "", "Nil input returns empty string")
    assert_eq(GridLock:FormatHotkeyText(12345), "12345", "Number converted to string")
    assert_eq(GridLock:FormatHotkeyText(false), "false", "Boolean converted to string")
end)
log_result("FormatHotkeyText: Nil, empty, and non-string inputs", status2_1 and "PASS" or "FAIL", err2_1)

-- Test 2.2: Complex Modifiers and Numpad/Mouse combinations
local status2_2, err2_2 = pcall(function()
    assert_eq(GridLock:FormatHotkeyText("CTRL-ALT-SHIFT-NUMPAD0"), "casN0", "CTRL-ALT-SHIFT-NUMPAD0 -> casN0")
    assert_eq(GridLock:FormatHotkeyText("SHIFT-CTRL-ALT-BUTTON1"), "scaM1", "SHIFT-CTRL-ALT-BUTTON1 -> scaM1")
    assert_eq(GridLock:FormatHotkeyText("Ctrl-Alt-Shift-Mouse Wheel Up"), "casWU", "Ctrl-Alt-Shift-Mouse Wheel Up -> casWU")
    assert_eq(GridLock:FormatHotkeyText("STRG-Alt-Shift-Mouse Wheel Down"), "casWD", "German STRG replacement to c")
    assert_eq(GridLock:FormatHotkeyText("SHIFT-PAGEUP"), "sPU", "SHIFT-PAGEUP -> sPU")
    assert_eq(GridLock:FormatHotkeyText("CTRL-PAGEDOWN"), "cPD", "CTRL-PAGEDOWN -> cPD")
    assert_eq(GridLock:FormatHotkeyText("ALT-INSERT"), "aIns", "ALT-INSERT -> aIns")
    assert_eq(GridLock:FormatHotkeyText("SHIFT-DELETE"), "sDel", "SHIFT-DELETE -> sDel")
    assert_eq(GridLock:FormatHotkeyText("CTRL-HOME"), "cHm", "CTRL-HOME -> cHm")
    assert_eq(GridLock:FormatHotkeyText("ALT-SPACE"), "aSpc", "ALT-SPACE -> aSpc")
    assert_eq(GridLock:FormatHotkeyText("CTRL-ESCAPE"), "cEsc", "CTRL-ESCAPE -> cEsc")
end)
log_result("FormatHotkeyText: Complex modifier strings and key aliases", status2_2 and "PASS" or "FAIL", err2_2)

-- Test 2.3: Unrecognized & Invalid Key Names
local status2_3, err2_3 = pcall(function()
    assert_eq(GridLock:FormatHotkeyText("CTRL-UNKNOWNKEY"), "cUNKNOWNKEY", "Unrecognized key name preserved")
    assert_eq(GridLock:FormatHotkeyText("ALT-F13"), "aF13", "F13 key preserved")
    assert_eq(GridLock:FormatHotkeyText("SHIFT-§"), "s§", "Special character key preserved")
end)
log_result("FormatHotkeyText: Unrecognized key names & special characters", status2_3 and "PASS" or "FAIL", err2_3)

-- Test 2.4: ToggleBarHotkeys formatting integration
local status2_4, err2_4 = pcall(function()
    local bar = MockFrame.new("TestHotkeyBar", "Frame", _G.UIParent)
    local btn = MockFrame.new("TestHotkeyBarButton1", "CheckButton", bar)
    local hk = MockFrame.new("TestHotkeyBarButton1HotKey", "FontString", btn)
    hk:SetText("CTRL-ALT-SHIFT-NUMPAD5")
    bar.buttons = { btn }
    
    GridLock:ToggleBarHotkeys(bar, true)
    assert_eq(hk:GetText(), "casN5", "ToggleBarHotkeys formats hotkey text on button")
    assert_true(hk:IsShown(), "Hotkey frame shown")
    
    GridLock:ToggleBarHotkeys(bar, false)
    assert_false(hk:IsShown(), "Hotkey frame hidden when toggle false")
end)
log_result("ToggleBarHotkeys: Integration with complex formatted hotkeys", status2_4 and "PASS" or "FAIL", err2_4)

print("\n--- [GROUP 3] Vehicle Frames, Missing Globals & Totem Bar Edge Cases ---")

-- Test 3.1: Non-Standard Vehicle Frames & Passenger Seats (CanExitVehicle vs UnitInVehicle)
local status3_1, err3_1 = pcall(function()
    local vehBar = MockFrame.new("VehicleMenuBar", "Frame", _G.UIParent)
    vehBar:Hide()
    
    local barObj = GridLock:RegisterSpecialBar("VehicleExitBar", vehBar, {})
    
    -- Scenario A: Standard vehicle (UnitInVehicle = true)
    mockInVehicle = true
    mockCanExitVehicle = true
    barObj.OnVehicleEvent(nil, "UNIT_ENTERED_VEHICLE", "player")
    assert_true(vehBar:IsShown(), "Vehicle exit bar shown when UnitInVehicle is true")
    assert_true(barObj.inVehicle, "inVehicle state is true")

    -- Scenario B: Passenger seat (UnitInVehicle = false, BUT CanExitVehicle = true!)
    mockInVehicle = false
    mockCanExitVehicle = true
    barObj.OnVehicleEvent(nil, "VEHICLE_UPDATE", nil)
    
    -- Check if inVehicle is set to true when player CanExitVehicle even though UnitInVehicle is false
    if not barObj.inVehicle or not vehBar:IsShown() then
        error("VehicleExitBar BUG: UnitInVehicle('player') returned false so CanExitVehicle() was skipped! Vehicle exit bar hidden when player is in passenger seat.")
    end
end)
log_result("VehicleExitBar: Passenger seat detection (UnitInVehicle=false, CanExitVehicle=true)", status3_1 and "PASS" or "FAIL", err3_1)

-- Test 3.2: Missing Global Frames Handling
local status3_2, err3_2 = pcall(function()
    -- Temporarily remove global frames
    local oldPet = _G.PetActionBarFrame
    local oldStance = _G.ShapeshiftBarFrame
    _G.PetActionBarFrame = nil
    _G.ShapeshiftBarFrame = nil

    -- Re-init special bars
    GridLock.specialBars = {}
    GridLock:InitSpecialBars()

    local petObj = GridLock:GetSpecialBar("PetBar")
    assert_true(petObj ~= nil, "PetBar registered even with missing global frame")
    assert_eq(petObj.frame, nil, "PetBar frame is nil")

    -- Check if calling layout or scale functions on nil frame crashes or is safe
    local updateStatus, updateErr = pcall(function()
        GridLock:UpdateSpecialBarLayout("PetBar")
        GridLock:SetSpecialBarScale("PetBar", 1.2)
        GridLock:SetSpecialBarAlpha("PetBar", 0.5)
        GridLock:SetSpecialBarVisibility("PetBar", false)
    end)
    assert_true(updateStatus, "Nil frame methods execute without Lua errors: " .. tostring(updateErr))

    -- Restore frames
    _G.PetActionBarFrame = oldPet
    _G.ShapeshiftBarFrame = oldStance
end)
log_result("SpecialBars: Graceful handling of missing global Blizzard frames", status3_2 and "PASS" or "FAIL", err3_2)

-- Test 3.3: Shaman Totem Bar Handling on Non-Shaman Classes (e.g. WARRIOR)
local status3_3, err3_3 = pcall(function()
    mockClass = "WARRIOR"
    local totemFrame = MockFrame.new("MultiCastActionBarFrame", "Frame", _G.UIParent)
    totemFrame:Show()

    GridLock.specialBars = {}
    GridLock:InitSpecialBars()

    local totemObj = GridLock:GetSpecialBar("TotemBar")
    assert_true(totemObj ~= nil, "TotemBar registered")
    assert_false(totemObj.enabled, "TotemBar enabled flag is false for Warrior")
    assert_false(totemFrame:IsShown(), "MultiCastActionBarFrame hidden for Warrior")

    -- Check if calling UpdateSpecialBarLayout directly alters totemFrame for non-Shaman
    GridLock:UpdateSpecialBarLayout("TotemBar", { rows = 1, cols = 4 })
    
    -- Boundary Check: Should UpdateSpecialBarLayout modify MultiCastActionBarFrame dimensions when enabled == false?
    -- If totemObj.enabled is false, modifying its layout is a potential leak/bug if Blizzard frame gets reshaped while hidden.
    if totemFrame.width > 0 and not totemObj.enabled then
        -- Document this behavior: UpdateSpecialBarLayout resizes disabled bar frames
        print("    [NOTE] UpdateSpecialBarLayout modified dimensions of disabled TotemBar for non-Shaman")
    end
end)
log_result("TotemBar: Non-Shaman class disabling and frame state", status3_3 and "PASS" or "FAIL", err3_3)

-- Test 3.4: Shaman Totem Bar Handling on Shaman Class
local status3_4, err3_4 = pcall(function()
    mockClass = "SHAMAN"
    local totemFrame = MockFrame.new("MultiCastActionBarFrame", "Frame", _G.UIParent)
    totemFrame.eventsUnregistered = false

    local barObj = {}
    barObj.frame = totemFrame
    GridLock:SetupTotemBar(barObj)

    assert_true(barObj.enabled, "TotemBar enabled for Shaman")
    assert_true(totemFrame.ignoreFramePositionManager, "ignoreFramePositionManager set to true")
    assert_true(totemFrame.eventsUnregistered, "Blizzard default events unregistered from MultiCastActionBarFrame")
end)
log_result("TotemBar: Shaman class setup and Blizzard event unregistration", status3_4 and "PASS" or "FAIL", err3_4)

-- ============================================================================
-- SUMMARY & REPORT GENERATION
-- ============================================================================
print("\n=========================================================================")
print(string.format("  Test Execution Complete: %d Passed, %d Failed", passCount, failCount))
print("=========================================================================\n")

if failCount > 0 then
    print("FAILED TESTS SUMMARY:")
    for _, item in ipairs(testLog) do
        if item.status == "FAIL" then
            print(string.format(" - %s: %s", item.name, tostring(item.details)))
        end
    end
end

os.exit(failCount == 0 and 0 or 1)

-- tests/test_gl_m2.lua
-- Comprehensive Unit & Integration Test Suite for GL-M2: Specialized Bar Suite

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
_G.InCombatLockdown = function() return false end

local mockPlayerClass = "WARRIOR"
_G.UnitClass = function(unit)
    if unit == "player" then
        return "Warrior", mockPlayerClass
    end
    return "Unknown", "UNKNOWN"
end

_G.hooksecurefunc = function(name, func)
    local orig = _G[name]
    _G[name] = function(...)
        if orig then orig(...) end
        func(...)
    end
end

-- Mock Frame Class
local MockFrame = {}
MockFrame.__index = MockFrame

function MockFrame.new(name)
    local self = setmetatable({}, MockFrame)
    self.name = name
    self.points = {}
    self.width = 0
    self.height = 0
    self.scale = 1.0
    self.alpha = 1.0
    self.visible = true
    self.parent = nil
    self.scripts = {}
    return self
end

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

function MockFrame:SetScale(s) self.scale = s end
function MockFrame:GetScale() return self.scale end

function MockFrame:SetAlpha(a) self.alpha = a end
function MockFrame:GetAlpha() return self.alpha end

function MockFrame:SetParent(p) self.parent = p end
function MockFrame:GetParent() return self.parent end

function MockFrame:Show() self.visible = true end
function MockFrame:Hide() self.visible = false end
function MockFrame:IsShown() return self.visible end

function MockFrame:SetScript(evt, fn) self.scripts[evt] = fn end
function MockFrame:GetScript(evt) return self.scripts[evt] end
function MockFrame:UnregisterAllEvents() self.eventsUnregistered = true end
function MockFrame:RegisterEvent(evt) self.registeredEvents = self.registeredEvents or {}; self.registeredEvents[evt] = true end

_G.CreateFrame = function(frameType, name, parent)
    local f = MockFrame.new(name)
    if parent then f:SetParent(parent) end
    if name then _G[name] = f end
    return f
end

_G.UIParent = MockFrame.new("UIParent")

-- Load module
local SpecialBars = dofile("GridLock/Modules/SpecialBars.lua")
local GridLock = _G.GridLock

print("=========================================")
print("Running GL-M2 Specialized Bar Suite Tests")
print("=========================================")

-- Test Group 1: API Exposure & Canonical ID Resolution
print("[Test Group 1] Canonical ID Resolution & Public API")
assert_eq(GridLock:GetCanonicalBarID("pet"), "PetBar", "pet -> PetBar")
assert_eq(GridLock:GetCanonicalBarID("PetBar"), "PetBar", "PetBar -> PetBar")
assert_eq(GridLock:GetCanonicalBarID("stance"), "StanceBar", "stance -> StanceBar")
assert_eq(GridLock:GetCanonicalBarID("shapeshift"), "StanceBar", "shapeshift -> StanceBar")
assert_eq(GridLock:GetCanonicalBarID("bags"), "BagBar", "bags -> BagBar")
assert_eq(GridLock:GetCanonicalBarID("micro"), "MicroMenu", "micro -> MicroMenu")
assert_eq(GridLock:GetCanonicalBarID("vehicle"), "VehicleExitBar", "vehicle -> VehicleExitBar")
assert_eq(GridLock:GetCanonicalBarID("totem"), "TotemBar", "totem -> TotemBar")
assert_eq(GridLock:GetCanonicalBarID("shaman"), "TotemBar", "shaman -> TotemBar")


-- Test Group 2: Pet Action Bar Registration, Button Reparenting & Layout Math
print("[Test Group 2] Pet Action Bar Layout & Reparenting")
local petFrame = MockFrame.new("PetActionBarFrame")
local petButtons = {}
for i = 1, 10 do
    local btn = MockFrame.new("PetActionButton" .. i)
    table.insert(petButtons, btn)
end

local petBarObj = GridLock:RegisterSpecialBar("PetBar", petFrame, petButtons)
assert_true(petBarObj ~= nil, "PetBar registered successfully")
assert_eq(petBarObj.id, "PetBar", "Bar ID is PetBar")
assert_eq(#petBarObj.buttons, 10, "10 pet buttons attached")

for i, btn in ipairs(petButtons) do
    assert_eq(btn:GetParent(), petFrame, string.format("Pet button %d reparented to petFrame", i))
end

-- Update Layout: 2 rows x 5 cols, padding = 3, spacing = 4, size 30x30
GridLock:UpdateSpecialBarLayout("PetBar", {
    rows = 2,
    cols = 5,
    padding = 3,
    spacing = 4,
    buttonWidth = 30,
    buttonHeight = 30,
})

-- Check button 1 anchor (col 0, row 0): x = 3, y = -3
local p1, ref1, rel1, x1, y1 = petButtons[1]:GetPoint(1)
assert_eq(p1, "TOPLEFT", "Button 1 point TOPLEFT")
assert_eq(x1, 3, "Button 1 x offset")
assert_eq(y1, -3, "Button 1 y offset")

-- Check button 6 anchor (col 0, row 1): x = 3, y = -(3 + 30 + 4) = -37
local p6, ref6, rel6, x6, y6 = petButtons[6]:GetPoint(1)
assert_eq(x6, 3, "Button 6 x offset")
assert_eq(y6, -37, "Button 6 y offset")

-- Check container frame dimensions:
-- Width: 3*2 + 5*30 + 4*4 = 6 + 150 + 16 = 172
-- Height: 3*2 + 2*30 + 1*4 = 6 + 60 + 4 = 70
assert_eq(petFrame:GetWidth(), 172, "Pet bar container frame width")
assert_eq(petFrame:GetHeight(), 70, "Pet bar container frame height")


-- Test Group 3: Stance Bar & Mover Handle Integration
print("[Test Group 3] Stance Bar & Drag/Snap Mover Handle")
local stanceFrame = MockFrame.new("ShapeshiftBarFrame")
local stanceButtons = {}
for i = 1, 10 do
    table.insert(stanceButtons, MockFrame.new("ShapeshiftButton" .. i))
end

GridLock:RegisterSpecialBar("StanceBar", stanceFrame, stanceButtons)
local mover = _G["GridLockMover_StanceBar"]
assert_true(mover ~= nil, "Mover frame GridLockMover_StanceBar created")
assert_eq(mover.barID, "StanceBar", "Mover barID set to StanceBar")

local snappedMover = nil
GridLock.SnapFrame = function(self, frame)
    snappedMover = frame
end

-- Simulate Mover Drag Drop
local onMouseDown = mover:GetScript("OnMouseDown")
local onMouseUp = mover:GetScript("OnMouseUp")
assert_true(type(onMouseDown) == "function", "Mover OnMouseDown script registered")
assert_true(type(onMouseUp) == "function", "Mover OnMouseUp script registered")

mover:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -200)
onMouseDown(mover, "LeftButton")
assert_true(mover.isDragging, "Mover starts dragging on left mouse down")

onMouseUp(mover, "LeftButton")
assert_false(mover.isDragging, "Mover stops dragging on mouse up")
assert_eq(snappedMover, mover, "GridLock:SnapFrame invoked on mover drop")


-- Test Group 4: Bag Bar
print("[Test Group 4] Bag Bar")
local bagFrame = MockFrame.new("GridLockBagBar")
local bagButtons = {
    MockFrame.new("MainMenuBarBackpackButton"),
    MockFrame.new("CharacterBag0Slot"),
    MockFrame.new("CharacterBag1Slot"),
    MockFrame.new("CharacterBag2Slot"),
    MockFrame.new("CharacterBag3Slot"),
    MockFrame.new("KeyRingButton"),
}
GridLock:RegisterSpecialBar("BagBar", bagFrame, bagButtons)
assert_eq(GridLock:GetSpecialBar("bags").id, "BagBar", "BagBar retrieved via 'bags' alias")
assert_eq(#bagButtons, 6, "BagBar has 6 buttons")

GridLock:UpdateSpecialBarLayout("BagBar", { rows = 1, cols = 6, spacing = 2, padding = 2, buttonWidth = 36, buttonHeight = 36 })
-- Width: 2*2 + 6*36 + 5*2 = 4 + 216 + 10 = 230
assert_eq(bagFrame:GetWidth(), 230, "Bag bar container width")


-- Test Group 5: Micro Menu Bar (-21px Vertical Offset & UpdateMicroButtons Hook)
print("[Test Group 5] Micro Menu Bar & UpdateMicroButtons Hook")
local microFrame = MockFrame.new("GridLockMicroMenu")
local microButtons = {
    MockFrame.new("CharacterMicroButton"),
    MockFrame.new("SpellbookMicroButton"),
    MockFrame.new("TalentMicroButton"),
    MockFrame.new("AchievementMicroButton"),
    MockFrame.new("QuestLogMicroButton"),
    MockFrame.new("SocialsMicroButton"),
    MockFrame.new("PVPMicroButton"),
    MockFrame.new("LFGMicroButton"),
    MockFrame.new("MainMenuMicroButton"),
    MockFrame.new("HelpMicroButton"),
}
GridLock:RegisterSpecialBar("MicroMenu", microFrame, microButtons)

-- Micro menu button width = 28, height = 58, vOffset = -21, padding = 2
local pm1, refm1, relm1, xm1, ym1 = microButtons[1]:GetPoint(1)
assert_eq(microButtons[1]:GetWidth(), 28, "Micro menu button 1 width 28px")
assert_eq(microButtons[1]:GetHeight(), 58, "Micro menu button 1 height 58px")
assert_eq(ym1, -23, "Micro menu button 1 y offset (-2 - 21 = -23)")

-- Simulate Blizzard UpdateMicroButtons call
_G.UpdateMicroButtons()
local pm1_after, refm1_after, relm1_after, xm1_after, ym1_after = microButtons[1]:GetPoint(1)
assert_eq(ym1_after, -23, "Micro menu button 1 y offset preserved after UpdateMicroButtons")


-- Test Group 6: Vehicle Exit Bar Events
print("[Test Group 6] Vehicle Exit Bar Event Handling")
local vehicleFrame = MockFrame.new("VehicleMenuBar")
local vehicleButtons = {
    MockFrame.new("VehicleMenuBarLeaveButton"),
    MockFrame.new("PitchUp"),
    MockFrame.new("PitchDown"),
}

GridLock:RegisterSpecialBar("VehicleExitBar", vehicleFrame, vehicleButtons)
local vehicleBarObj = GridLock:GetSpecialBar("VehicleExitBar")

-- Trigger vehicle enter event for player
vehicleBarObj.OnVehicleEvent(vehicleFrame, "UNIT_ENTERED_VEHICLE", "player")
assert_true(vehicleBarObj.inVehicle, "Player entered vehicle state detected")
assert_true(vehicleFrame:IsShown(), "Vehicle bar frame shown when in vehicle")

-- Trigger vehicle exit event for player
vehicleBarObj.OnVehicleEvent(vehicleFrame, "UNIT_EXITED_VEHICLE", "player")
assert_false(vehicleBarObj.inVehicle, "Player exited vehicle state detected")
assert_false(vehicleFrame:IsShown(), "Vehicle bar frame hidden when exiting vehicle")

-- Non-player vehicle event ignored
vehicleBarObj.OnVehicleEvent(vehicleFrame, "UNIT_ENTERED_VEHICLE", "party1")
assert_false(vehicleBarObj.inVehicle, "Non-player vehicle event ignored")


-- Test Group 7: Shaman Totem Bar & Class Check
print("[Test Group 7] Shaman Totem Bar Class Checks & Script Wiping")
local totemFrame = MockFrame.new("MultiCastActionBarFrame")
totemFrame:SetScript("OnShow", function() end)
totemFrame:SetScript("OnHide", function() end)

-- Non-shaman (WARRIOR)
mockPlayerClass = "WARRIOR"
local totemObj1 = GridLock:RegisterSpecialBar("TotemBar", totemFrame, {})
assert_false(totemObj1.enabled, "TotemBar disabled for WARRIOR")
assert_false(totemFrame:IsShown(), "Totem frame hidden for non-shaman")

-- Shaman (SHAMAN)
mockPlayerClass = "SHAMAN"
GridLock:SetupTotemBar(totemObj1)
assert_true(totemObj1.enabled, "TotemBar enabled for SHAMAN")
assert_true(totemFrame.ignoreFramePositionManager, "ignoreFramePositionManager flag set on MultiCastActionBarFrame")
assert_eq(totemFrame:GetScript("OnShow"), nil, "OnShow script wiped")
assert_eq(totemFrame:GetScript("OnHide"), nil, "OnHide script wiped")
assert_true(totemFrame.eventsUnregistered, "All default events unregistered")


-- Test Group 8: Scale, Alpha, and Visibility Controls
print("[Test Group 8] Scale, Alpha & Visibility API Controls")
GridLock:SetSpecialBarScale("PetBar", 0.85)
assert_eq(petFrame:GetScale(), 0.85, "SetSpecialBarScale decimal float 0.85")

GridLock:SetSpecialBarScale("PetBar", 110)
assert_eq(petFrame:GetScale(), 1.10, "SetSpecialBarScale percentage 110 -> 1.10")

GridLock:SetSpecialBarAlpha("PetBar", 0.5)
assert_eq(petFrame:GetAlpha(), 0.5, "SetSpecialBarAlpha 0.5")

GridLock:SetSpecialBarVisibility("PetBar", false)
assert_false(petFrame:IsShown(), "SetSpecialBarVisibility false hides frame")

GridLock:SetSpecialBarVisibility("PetBar", true)
assert_true(petFrame:IsShown(), "SetSpecialBarVisibility true shows frame")

print("=========================================")
print(string.format("All GL-M2 Tests PASSED! (Passed: %d, Failed: %d)", passCount, failCount))
print("=========================================")

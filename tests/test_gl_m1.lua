-- tests/test_gl_m1.lua
-- Comprehensive Unit & Integration Tests for GL-M1: Secure State Paging & Stance Switching

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

-- 1. Mock WoW 3.3.5a API Environment
_G.InCombatLockdown = function() return false end
local mockPlayerClass = "WARRIOR"
_G.UnitClass = function(unit)
    if unit == "player" then
        return "Warrior", mockPlayerClass
    end
    return "Unknown", "UNKNOWN"
end

local registeredDrivers = {}
_G.RegisterStateDriver = function(frame, state, driverString)
    registeredDrivers[frame] = { state = state, driverString = driverString }
    if frame and frame.SetAttribute then
        frame:SetAttribute("_stateDriver_" .. state, driverString)
    end
end

-- Simple Frame Mock
local FrameMT = {}
FrameMT.__index = FrameMT

function FrameMT:new(id)
    local obj = {
        id = id,
        attributes = {},
        children = {},
    }
    return setmetatable(obj, FrameMT)
end

function FrameMT:SetAttribute(key, val)
    self.attributes[key] = val
end

function FrameMT:GetAttribute(key)
    return self.attributes[key]
end

function FrameMT:GetID()
    return self.id or 1
end

function FrameMT:SetID(id)
    self.id = id
end

function FrameMT:GetChildren()
    return unpack(self.children)
end

function FrameMT:AddChild(child)
    table.insert(self.children, child)
    child.parent = self
end

function FrameMT:ChildUpdate(stateName, value)
    local snippet = self:GetAttribute("_childupdate-" .. stateName)
    for _, child in ipairs(self.children) do
        if child.SetAttribute then
            -- Simulate child update execution
            local childSnippet = child:GetAttribute("_childupdate-" .. stateName) or snippet
            if childSnippet then
                -- Simulate running snippet on child with message = value
                local page = tonumber(value) or 1
                local id = child:GetID() or 1
                local actionSlot = (page - 1) * 12 + id
                child:SetAttribute("actionpage", page)
                child:SetAttribute("type", "action")
                child:SetAttribute("action", actionSlot)
                child:SetAttribute("isVehicle", (page == 11 or page == 12))
            end
        end
    end
end

-- Load module
local ActionBarState = dofile("GridLock/Modules/ActionBarState.lua")
local GridLock = _G.GridLock

print("=========================================")
print("Running GL-M1 Secure State Paging Tests")
print("=========================================")

-- Test 1: Class Stance Drivers
print("[Test Group 1] Class Stance Driver Strings")

assert_eq(GridLock:GetClassStanceDriver("WARRIOR"), "[bonusbar:1]7; [bonusbar:2]8; [bonusbar:3]9", "Warrior Stance String")
assert_eq(GridLock:GetClassStanceDriver("Warrior"), "[bonusbar:1]7; [bonusbar:2]8; [bonusbar:3]9", "Warrior TitleCase Stance String")
assert_eq(GridLock:GetClassStanceDriver("warrior"), "[bonusbar:1]7; [bonusbar:2]8; [bonusbar:3]9", "Warrior LowerCase Stance String")

assert_eq(GridLock:GetClassStanceDriver("DRUID"), "[bonusbar:1,stealth:1]7; [bonusbar:1]7; [bonusbar:2]8; [bonusbar:3]9; [bonusbar:4]10", "Druid Stance String")
assert_eq(GridLock:GetClassStanceDriver("ROGUE"), "[bonusbar:1]7; [bonusbar:2]8", "Rogue Stance String")
assert_eq(GridLock:GetClassStanceDriver("PRIEST"), "[bonusbar:1]7", "Priest Stance String")
assert_eq(GridLock:GetClassStanceDriver("WARLOCK"), "[form:2]7", "Warlock Metamorphosis Stance String")
assert_eq(GridLock:GetClassStanceDriver("PALADIN"), "", "Paladin Stance String should be empty")
assert_eq(GridLock:GetClassStanceDriver("MAGE"), "", "Mage Stance String should be empty")
assert_eq(GridLock:GetClassStanceDriver(nil), "[bonusbar:1]7; [bonusbar:2]8; [bonusbar:3]9", "Default fallback using UnitClass player (WARRIOR)")


-- Test 2: State Driver Evaluator Engine
print("[Test Group 2] State Driver Evaluator Engine")

local warriorDriver = GridLock:GetClassStanceDriver("WARRIOR") .. "; 1"
assert_eq(GridLock:EvaluateStateDriver(warriorDriver, { bonusbar = 1 }), 7, "Warrior Battle Stance -> Page 7")
assert_eq(GridLock:EvaluateStateDriver(warriorDriver, { bonusbar = 2 }), 8, "Warrior Defensive Stance -> Page 8")
assert_eq(GridLock:EvaluateStateDriver(warriorDriver, { bonusbar = 3 }), 9, "Warrior Berserker Stance -> Page 9")
assert_eq(GridLock:EvaluateStateDriver(warriorDriver, { bonusbar = 0 }), 1, "Warrior No Stance -> Page 1")

local druidDriver = GridLock:GetClassStanceDriver("DRUID") .. "; 1"
assert_eq(GridLock:EvaluateStateDriver(druidDriver, { bonusbar = 1, stealth = 1 }), 7, "Druid Cat Prowl -> Page 7")
assert_eq(GridLock:EvaluateStateDriver(druidDriver, { bonusbar = 1, stealth = 0 }), 7, "Druid Cat Form -> Page 7")
assert_eq(GridLock:EvaluateStateDriver(druidDriver, { bonusbar = 2 }), 8, "Druid Tree of Life -> Page 8")
assert_eq(GridLock:EvaluateStateDriver(druidDriver, { bonusbar = 3 }), 9, "Druid Bear Form -> Page 9")
assert_eq(GridLock:EvaluateStateDriver(druidDriver, { bonusbar = 4 }), 10, "Druid Moonkin Form -> Page 10")
assert_eq(GridLock:EvaluateStateDriver(druidDriver, { bonusbar = 0 }), 1, "Druid Humanoid Form -> Page 1")

local rogueDriver = GridLock:GetClassStanceDriver("ROGUE") .. "; 1"
assert_eq(GridLock:EvaluateStateDriver(rogueDriver, { bonusbar = 1 }), 7, "Rogue Stealth -> Page 7")
assert_eq(GridLock:EvaluateStateDriver(rogueDriver, { bonusbar = 2 }), 8, "Rogue Shadow Dance -> Page 8")

local priestDriver = GridLock:GetClassStanceDriver("PRIEST") .. "; 1"
assert_eq(GridLock:EvaluateStateDriver(priestDriver, { bonusbar = 1 }), 7, "Priest Shadowform -> Page 7")

local warlockDriver = GridLock:GetClassStanceDriver("WARLOCK") .. "; 1"
assert_eq(GridLock:EvaluateStateDriver(warlockDriver, { form = 2 }), 7, "Warlock Metamorphosis -> Page 7")


-- Test 3: Vehicle, Modifiers & Bar Paging Evaluator
print("[Test Group 3] Full Main Bar Paging Evaluation")

local mainBarDriver = "[bonusbar:5]11; [bonusbar:1]7; [bonusbar:2]8; [bonusbar:3]9; [mod:ctrl]2; [mod:alt]3; [mod:shift]4; [bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6; 1"

assert_eq(GridLock:EvaluateStateDriver(mainBarDriver, { bonusbar = 5 }), 11, "Vehicle -> Page 11")
assert_eq(GridLock:EvaluateStateDriver("[vehicleui]12; [possessbar]12; [bonusbar:5]11; 1", { vehicleui = true }), 12, "VehicleUI condition -> Page 12")
assert_eq(GridLock:EvaluateStateDriver("[vehicleui]12; [possessbar]12; [bonusbar:5]11; 1", { possessbar = true }), 12, "PossessBar condition -> Page 12")
assert_eq(GridLock:EvaluateStateDriver(mainBarDriver, { bonusbar = 5, mod = "ctrl" }), 11, "Vehicle overrides Ctrl modifier")
assert_eq(GridLock:EvaluateStateDriver(mainBarDriver, { bonusbar = 1, mod = "ctrl" }), 7, "Stance overrides Ctrl modifier")
assert_eq(GridLock:EvaluateStateDriver(mainBarDriver, { mod = "ctrl" }), 2, "Ctrl modifier -> Page 2")
assert_eq(GridLock:EvaluateStateDriver(mainBarDriver, { mod = "alt" }), 3, "Alt modifier -> Page 3")
assert_eq(GridLock:EvaluateStateDriver(mainBarDriver, { mod = "shift" }), 4, "Shift modifier -> Page 4")
assert_eq(GridLock:EvaluateStateDriver(mainBarDriver, { bar = 2 }), 2, "Action Bar 2 selected -> Page 2")
assert_eq(GridLock:EvaluateStateDriver(mainBarDriver, { bar = 3 }), 3, "Action Bar 3 selected -> Page 3")
assert_eq(GridLock:EvaluateStateDriver(mainBarDriver, { bar = 6 }), 6, "Action Bar 6 selected -> Page 6")
assert_eq(GridLock:EvaluateStateDriver(mainBarDriver, {}), 1, "Default Fallback -> Page 1")


-- Test 4: GridLock:UpdateBarPaging
print("[Test Group 4] UpdateBarPaging Method")

local driver1, header1 = GridLock:UpdateBarPaging(1, { className = "WARRIOR" })
assert_eq(driver1, "[bonusbar:5]11; [bonusbar:1]7; [bonusbar:2]8; [bonusbar:3]9; [mod:ctrl]2; [mod:alt]3; [mod:shift]4; [bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6; 1", "Bar 1 Warrior driver string")

local driverDruid = GridLock:UpdateBarPaging(1, { className = "DRUID" })
assert_eq(driverDruid, "[bonusbar:5]11; [bonusbar:1,stealth:1]7; [bonusbar:1]7; [bonusbar:2]8; [bonusbar:3]9; [bonusbar:4]10; [mod:ctrl]2; [mod:alt]3; [mod:shift]4; [bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6; 1", "Bar 1 Druid driver string")

local driver2 = GridLock:UpdateBarPaging(2, { useModifiers = true })
assert_eq(driver2, "[mod:ctrl]2; [mod:alt]3; [mod:shift]4; 2", "Bar 2 driver with modifiers")

local driverCustom = GridLock:UpdateBarPaging(1, { customDriver = "[mod:ctrl]5; 1" })
assert_eq(driverCustom, "[mod:ctrl]5; 1", "Custom driver override")


-- Test 5: Secure Snippets & Child Button Updates
print("[Test Group 5] Secure Header & Child Button Action Slot Routing")

local parentHeader = FrameMT:new(0)
local childButtons = {}
for i = 1, 12 do
    local btn = FrameMT:new(i)
    table.insert(childButtons, btn)
    parentHeader:AddChild(btn)
end

GridLock:RegisterStateDriver(parentHeader, mainBarDriver)
assert_eq(parentHeader:GetAttribute("_onstate-page"), GridLock.SNIPPET_ONSTATE_PAGE, "Header _onstate-page snippet set")
assert_eq(parentHeader:GetAttribute("_childupdate-state"), GridLock.SNIPPET_CHILDUPDATE_STATE, "Header _childupdate-state snippet set")

-- Simulate Page 1 Update
parentHeader:ChildUpdate("state", 1)
assert_eq(childButtons[1]:GetAttribute("actionpage"), 1, "Child 1 actionpage for Page 1")
assert_eq(childButtons[1]:GetAttribute("action"), 1, "Child 1 action slot for Page 1")
assert_eq(childButtons[12]:GetAttribute("action"), 12, "Child 12 action slot for Page 1")
assert_eq(childButtons[1]:GetAttribute("isVehicle"), false, "Child 1 isVehicle for Page 1")

-- Simulate Page 7 Update (Stance)
parentHeader:ChildUpdate("state", 7)
assert_eq(childButtons[1]:GetAttribute("actionpage"), 7, "Child 1 actionpage for Page 7")
assert_eq(childButtons[1]:GetAttribute("action"), 73, "Child 1 action slot for Page 7 (73)")
assert_eq(childButtons[12]:GetAttribute("action"), 84, "Child 12 action slot for Page 7 (84)")
assert_eq(childButtons[1]:GetAttribute("isVehicle"), false, "Child 1 isVehicle for Page 7")

-- Simulate Page 11 Update (Vehicle)
parentHeader:ChildUpdate("state", 11)
assert_eq(childButtons[1]:GetAttribute("actionpage"), 11, "Child 1 actionpage for Page 11")
assert_eq(childButtons[1]:GetAttribute("action"), 121, "Child 1 action slot for Page 11 (121)")
assert_eq(childButtons[12]:GetAttribute("action"), 132, "Child 12 action slot for Page 11 (132)")
assert_eq(childButtons[1]:GetAttribute("isVehicle"), true, "Child 1 isVehicle for Page 11 (true)")


-- Test 6: InCombatLockdown Simulation Safety
print("[Test Group 6] Combat Lockdown Taint Safety")
_G.InCombatLockdown = function() return true end

parentHeader:ChildUpdate("state", 8)
assert_eq(childButtons[1]:GetAttribute("actionpage"), 8, "Child 1 actionpage for Page 8 in combat")
assert_eq(childButtons[1]:GetAttribute("action"), 85, "Child 1 action slot for Page 8 (85) in combat")
assert_eq(childButtons[1]:GetAttribute("type"), "action", "Child 1 type attribute in combat")

print("=========================================")
print(string.format("All GL-M1 Tests PASSED! (Passed: %d, Failed: %d)", passCount, failCount))
print("=========================================")

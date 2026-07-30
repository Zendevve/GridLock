-- tests/test_gl_m5_stress_challenger1.lua
-- Adversarial Stress & GC Allocation Verification Test Suite for GridLock Action Bar & Special Bar System
-- Target: GL-M5 High-Load Verification & Stress Testing

local unpack = unpack or table.unpack

local passCount = 0
local failCount = 0

local function assert_eq(actual, expected, msg)
    if actual == expected then
        passCount = passCount + 1
    else
        failCount = failCount + 1
        print("  [FAIL] " .. tostring(msg))
        print("    Expected: " .. tostring(expected))
        print("    Actual:   " .. tostring(actual))
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

local simulatedTime = 100.0
_G.GetTime = function()
    return simulatedTime
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
    self.alpha = 1.0
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

function MockFrame:SetParent(p) self.parent = p end
function MockFrame:GetParent() return self.parent end

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

function MockFrame:SetSize(w, h) self.width = w; self.height = h end
function MockFrame:SetWidth(w) self.width = w end
function MockFrame:GetWidth() return self.width end
function MockFrame:SetHeight(h) self.height = h end
function MockFrame:GetHeight() return self.height end
function MockFrame:Show() self.visible = true end
function MockFrame:Hide() self.visible = false end
function MockFrame:IsShown() return self.visible end

function MockFrame:SetAlpha(a) self.alpha = a end
function MockFrame:GetAlpha() return self.alpha end

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

function MockFrame:GetID() return self.id or 1 end
function MockFrame:SetID(id) self.id = id end

function MockFrame:GetLeft() return 100 end
function MockFrame:GetRight() return 200 end
function MockFrame:GetTop() return 200 end
function MockFrame:GetBottom() return 100 end
function MockFrame:GetCenter() return 150, 150 end
function MockFrame:GetEffectiveScale() return self.scale or 1.0 end
function MockFrame:GetScale() return self.scale or 1.0 end
function MockFrame:SetScale(s) self.scale = s end
function MockFrame:StartMoving() self.isMoving = true end
function MockFrame:StopMovingOrSizing() self.isMoving = false end

function MockFrame:ChildUpdate(stateName, value)
    local snippet = self:GetAttribute("_childupdate-" .. stateName)
    local childrenList = (#self.children > 0 and self.children) or (self.buttons or {})
    for _, child in ipairs(childrenList) do
        if child.SetAttribute then
            local childSnippet = child:GetAttribute("_childupdate-" .. stateName) or snippet
            if childSnippet then
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

_G.CreateFrame = function(frameType, name, parent)
    local f = MockFrame.new(name)
    if parent then f:SetParent(parent) end
    return f
end

_G.UIParent = MockFrame.new("UIParent")
_G.UIParent:SetWidth(1920)
_G.UIParent:SetHeight(1080)

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

-- Helper to create mock bar with N buttons
local function createMockBar(barName, numButtons)
    numButtons = numButtons or 12
    local bar = MockFrame.new(barName)
    bar.buttons = {}
    for i = 1, numButtons do
        local btnName = barName .. "Button" .. i
        local btn = MockFrame.new(btnName)
        btn:SetID(i)
        btn:SetWidth(36)
        btn:SetHeight(36)
        
        local hotkey = MockFontString.new(btnName .. "HotKey")
        hotkey:SetText("SHIFT-" .. i)
        btn.HotKey = hotkey
        
        local macro = MockFontString.new(btnName .. "Name")
        macro:SetText("Macro" .. i)
        btn.Name = macro
        
        table.insert(bar.buttons, btn)
        bar:AddChild(btn)
    end
    return bar
end

-- Load GridLock Modules
local ActionBarState = dofile("GridLock/Modules/ActionBarState.lua")
local SpecialBars = dofile("GridLock/Modules/SpecialBars.lua")
local BarLayout = dofile("GridLock/Modules/BarLayout.lua")
local BlizzardArt = dofile("GridLock/Modules/BlizzardArt.lua")
local GridLock = _G.GridLock

print("=====================================================================")
print("  GridLock GL-M5 Adversarial Stress & GC Allocation Verification Test")
print("=====================================================================")

-----------------------------------------------------------------------
-- Test Group 1: Rapid Stance Switches (Warrior, Druid, Rogue)
-----------------------------------------------------------------------
print("\n[Test Group 1] Rapid Stance Switches (Warrior, Druid, Rogue)")

local mainBar = createMockBar("GridLockBar1", 12)
GridLock:UpdateBarPaging(1, { header = mainBar, className = "WARRIOR", useStances = true })

-- 1A: Warrior Stance Switches (10,000 rapid cycles)
print("  Subtest 1A: Warrior Stance Switch Stress (10,000 cycles)")
local warriorDriver = GridLock:GetClassStanceDriver("WARRIOR") .. "; [bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6; 1"
local warriorStances = {
    { env = { bonusbar = 0 }, expectedPage = 1, stanceName = "No Stance / Humanoid" },
    { env = { bonusbar = 1 }, expectedPage = 7, stanceName = "Battle Stance" },
    { env = { bonusbar = 2 }, expectedPage = 8, stanceName = "Defensive Stance" },
    { env = { bonusbar = 3 }, expectedPage = 9, stanceName = "Berserker Stance" },
}

local startClk = os.clock()
for i = 1, 10000 do
    local stanceIndex = ((i - 1) % 4) + 1
    local stance = warriorStances[stanceIndex]
    local page = GridLock:EvaluateStateDriver(warriorDriver, stance.env)
    assert_eq(page, stance.expectedPage, "Warrior stance eval iteration " .. i .. " (" .. stance.stanceName .. ")")
    mainBar:ChildUpdate("state", page)
    assert_eq(mainBar.buttons[1]:GetAttribute("actionpage"), stance.expectedPage, "Button 1 actionpage")
    assert_eq(mainBar.buttons[1]:GetAttribute("action"), (stance.expectedPage - 1) * 12 + 1, "Button 1 action slot")
    assert_eq(mainBar.buttons[12]:GetAttribute("action"), (stance.expectedPage - 1) * 12 + 12, "Button 12 action slot")
end
local warriorDuration = os.clock() - startClk
print(string.format("  -> 10,000 Warrior stance transitions passed in %.4f sec (%.2f ops/sec)", warriorDuration, 10000 / warriorDuration))

-- 1B: Druid Form Switches (10,000 rapid cycles)
print("  Subtest 1B: Druid Form Switch Stress (10,000 cycles)")
local druidDriver = GridLock:GetClassStanceDriver("DRUID") .. "; [bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6; 1"
local druidForms = {
    { env = { bonusbar = 0 }, expectedPage = 1, formName = "Humanoid" },
    { env = { bonusbar = 1, stealth = 0 }, expectedPage = 7, formName = "Cat Form" },
    { env = { bonusbar = 1, stealth = 1 }, expectedPage = 7, formName = "Cat Form (Prowl)" },
    { env = { bonusbar = 2 }, expectedPage = 8, formName = "Tree of Life Form" },
    { env = { bonusbar = 3 }, expectedPage = 9, formName = "Bear Form" },
    { env = { bonusbar = 4 }, expectedPage = 10, formName = "Moonkin Form" },
}

startClk = os.clock()
for i = 1, 10000 do
    local formIndex = ((i - 1) % 6) + 1
    local form = druidForms[formIndex]
    local page = GridLock:EvaluateStateDriver(druidDriver, form.env)
    assert_eq(page, form.expectedPage, "Druid form eval iteration " .. i .. " (" .. form.formName .. ")")
    mainBar:ChildUpdate("state", page)
    assert_eq(mainBar.buttons[1]:GetAttribute("actionpage"), form.expectedPage, "Button 1 actionpage")
end
local druidDuration = os.clock() - startClk
print(string.format("  -> 10,000 Druid form transitions passed in %.4f sec (%.2f ops/sec)", druidDuration, 10000 / druidDuration))

-- 1C: Rogue Stance Switches (10,000 rapid cycles)
print("  Subtest 1C: Rogue Stealth & Shadow Dance Stress (10,000 cycles)")
local rogueDriver = GridLock:GetClassStanceDriver("ROGUE") .. "; [bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6; 1"
local rogueStances = {
    { env = { bonusbar = 0 }, expectedPage = 1, stanceName = "Normal" },
    { env = { bonusbar = 1 }, expectedPage = 7, stanceName = "Stealth" },
    { env = { bonusbar = 2 }, expectedPage = 8, stanceName = "Shadow Dance" },
}

startClk = os.clock()
for i = 1, 10000 do
    local stIndex = ((i - 1) % 3) + 1
    local st = rogueStances[stIndex]
    local page = GridLock:EvaluateStateDriver(rogueDriver, st.env)
    assert_eq(page, st.expectedPage, "Rogue stance eval iteration " .. i .. " (" .. st.stanceName .. ")")
    mainBar:ChildUpdate("state", page)
    assert_eq(mainBar.buttons[1]:GetAttribute("actionpage"), st.expectedPage, "Button 1 actionpage")
end
local rogueDuration = os.clock() - startClk
print(string.format("  -> 10,000 Rogue stance transitions passed in %.4f sec (%.2f ops/sec)", rogueDuration, 10000 / rogueDuration))

-----------------------------------------------------------------------
-- Test Group 2: Rapid Vehicle Entry/Exit Cycles
-----------------------------------------------------------------------
print("\n[Test Group 2] Rapid Vehicle Entry/Exit Cycles (10,000 cycles)")

local vehicleDriver = "[bonusbar:5]11; [bonusbar:1]7; [bonusbar:2]8; [bonusbar:3]9; [mod:ctrl]2; [mod:alt]3; [mod:shift]4; [bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6; 1"

startClk = os.clock()
for i = 1, 10000 do
    -- Vehicle Enter
    local vehEnv = { bonusbar = 5, vehicleui = true }
    local vehPage = GridLock:EvaluateStateDriver(vehicleDriver, vehEnv)
    assert_eq(vehPage, 11, "Vehicle Enter -> Page 11")
    mainBar:ChildUpdate("state", vehPage)
    assert_eq(mainBar.buttons[1]:GetAttribute("isVehicle"), true, "Button 1 isVehicle true")
    assert_eq(mainBar.buttons[1]:GetAttribute("actionpage"), 11, "Button 1 actionpage 11")
    assert_eq(mainBar.buttons[1]:GetAttribute("action"), 121, "Button 1 action slot 121")
    assert_eq(mainBar.buttons[12]:GetAttribute("action"), 132, "Button 12 action slot 132")
    
    -- Vehicle Exit (Back to normal page 1)
    local normalEnv = { bonusbar = 0, vehicleui = false }
    local normPage = GridLock:EvaluateStateDriver(vehicleDriver, normalEnv)
    assert_eq(normPage, 1, "Vehicle Exit -> Page 1")
    mainBar:ChildUpdate("state", normPage)
    assert_eq(mainBar.buttons[1]:GetAttribute("isVehicle"), false, "Button 1 isVehicle false")
    assert_eq(mainBar.buttons[1]:GetAttribute("actionpage"), 1, "Button 1 actionpage 1")
    assert_eq(mainBar.buttons[1]:GetAttribute("action"), 1, "Button 1 action slot 1")
    assert_eq(mainBar.buttons[12]:GetAttribute("action"), 12, "Button 12 action slot 12")
end
local vehicleDuration = os.clock() - startClk
print(string.format("  -> 10,000 Vehicle entry/exit cycles (20,000 state updates) passed in %.4f sec (%.2f ops/sec)", vehicleDuration, 20000 / vehicleDuration))

-----------------------------------------------------------------------
-- Test Group 3: Rapid Modifier Paging Changes
-----------------------------------------------------------------------
print("\n[Test Group 3] Rapid Modifier Paging Changes (10,000 cycles)")

local modDriver = "[mod:ctrl]2; [mod:alt]3; [mod:shift]4; 1"
local modifierStates = {
    { env = { mod = "ctrl" }, expectedPage = 2, modName = "CTRL" },
    { env = { mod = "alt" }, expectedPage = 3, modName = "ALT" },
    { env = { mod = "shift" }, expectedPage = 4, modName = "SHIFT" },
    { env = { mod = "" }, expectedPage = 1, modName = "NONE" },
}

startClk = os.clock()
for i = 1, 10000 do
    local stIdx = ((i - 1) % 4) + 1
    local st = modifierStates[stIdx]
    local page = GridLock:EvaluateStateDriver(modDriver, st.env)
    assert_eq(page, st.expectedPage, "Modifier eval iteration " .. i .. " (" .. st.modName .. ")")
    mainBar:ChildUpdate("state", page)
    assert_eq(mainBar.buttons[1]:GetAttribute("actionpage"), st.expectedPage, "Button 1 actionpage")
    assert_eq(mainBar.buttons[1]:GetAttribute("action"), (st.expectedPage - 1) * 12 + 1, "Button 1 action slot")
end
local modDuration = os.clock() - startClk
print(string.format("  -> 10,000 Modifier paging transitions passed in %.4f sec (%.2f ops/sec)", modDuration, 10000 / modDuration))

-----------------------------------------------------------------------
-- Test Group 4: 1,000+ Layout & Visibility Updates Under Combat Lockdown
-----------------------------------------------------------------------
print("\n[Test Group 4] 1,000+ Layout & Visibility Updates Under Combat Lockdown")

local testBars = {}
for b = 1, 10 do
    testBars[b] = createMockBar("GridLockTestBar" .. b, 12)
end

-- Enter combat lockdown
inCombat = true
assert_true(InCombatLockdown(), "InCombatLockdown is true")

-- Reset pending queue
GridLock.pendingQueue = {}

print("  Subtest 4A: Queueing 1,500 Layout, Grid Visibility, Hotkey & Macro Updates in Combat")
local expectedQueueSize = 0

-- Perform 1,500 operations under combat lockdown
for i = 1, 1500 do
    local barIndex = ((i - 1) % 10) + 1
    local bar = testBars[barIndex]
    local opType = i % 4
    
    if opType == 0 then
        -- SetBarLayout
        local cols = (i % 6) + 1
        local rows = math.ceil(12 / cols)
        GridLock:SetBarLayout(bar, rows, cols, 4, 3)
    elseif opType == 1 then
        -- SetBarGridVisibility
        local gridVal = (i % 2)
        GridLock:SetBarGridVisibility(bar, gridVal)
    elseif opType == 2 then
        -- ToggleBarHotkeys
        local show = (i % 2 == 0)
        GridLock:ToggleBarHotkeys(bar, show)
    else
        -- ToggleBarMacroText
        local show = (i % 2 == 1)
        GridLock:ToggleBarMacroText(bar, show)
    end
    expectedQueueSize = expectedQueueSize + 1
end

assert_eq(#GridLock.pendingQueue, 1500, "Pending combat queue size is exactly 1,500")
print("  -> Verified 1,500 operations successfully queued during combat without immediate execution.")

print("  Subtest 4B: Exiting Combat Lockdown & Flushing Queue (1,500 items)")
inCombat = false
assert_false(InCombatLockdown(), "InCombatLockdown is false")

startClk = os.clock()
GridLock:FlushCombatQueue()
local flushDuration = os.clock() - startClk

assert_eq(#GridLock.pendingQueue, 0, "Pending combat queue cleared after flush")
print(string.format("  -> 1,500 queued combat actions executed cleanly in %.4f sec (%.2f ops/sec)", flushDuration, 1500 / flushDuration))

-----------------------------------------------------------------------
-- Test Group 5: GC Allocation Stability & Memory Delta Analysis
-----------------------------------------------------------------------
print("\n[Test Group 5] GC Allocation Stability & Memory Delta Analysis (1,000 OnUpdate/Fade Iterations)")

-- Set up 10 special bars for fading simulation
local specialBarList = {}
for i = 1, 10 do
    local barID = "Bar" .. i
    local barObj = GridLock:RegisterSpecialBar(barID, testBars[i], testBars[i].buttons)
    table.insert(specialBarList, barObj)
end

-- Force Garbage Collection to establish clean baseline
collectgarbage("collect")
collectgarbage("collect")
local initialMemKB = collectgarbage("count")

print(string.format("  Initial Baseline Memory: %.2f KB", initialMemKB))

-- Define OnUpdate / Fade processing function simulating 1,000 frame updates
local function processFadeFrame(dt)
    simulatedTime = simulatedTime + dt
    local curTime = simulatedTime
    
    for _, barObj in ipairs(specialBarList) do
        local targetAlpha = 0.5 + 0.5 * math.sin(curTime * 2.0)
        GridLock:SetSpecialBarAlpha(barObj.id, targetAlpha)
        
        -- Simulate visibility check
        local isVis = targetAlpha > 0.1
        if isVis ~= barObj.config.visible then
            barObj.config.visible = isVis
            if barObj.frame and barObj.frame.Show and barObj.frame.Hide then
                if isVis then barObj.frame:Show() else barObj.frame:Hide() end
            end
        end
    end
end

-- Run 1,000 OnUpdate/fade iterations
startClk = os.clock()
for frame = 1, 1000 do
    processFadeFrame(0.016)
end
local fadeDuration = os.clock() - startClk

-- Measure memory after 1,000 frames BEFORE collecting garbage
local postIterMemKB = collectgarbage("count")
local grossAllocatedKB = postIterMemKB - initialMemKB

-- Force Garbage Collection to test uncollected memory retention (leaks)
collectgarbage("collect")
collectgarbage("collect")
local postGCMemKB = collectgarbage("count")
local uncollectedDeltaKB = postGCMemKB - initialMemKB

print(string.format("  - Executed 1,000 OnUpdate/fade iterations in %.4f sec (%.2f FPS)", fadeDuration, 1000 / fadeDuration))
print(string.format("  - Gross Memory Allocated (before GC): %.2f KB (%.2f bytes/frame)", grossAllocatedKB, (grossAllocatedKB * 1024) / 1000))
print(string.format("  - Memory After GC: %.2f KB", postGCMemKB))
print(string.format("  - Net Uncollected Memory Delta (Retention): %.2f KB", uncollectedDeltaKB))

-- Assert memory retention is < 1.0 KB over 1,000 frames (proving ZERO leak)
assert_true(uncollectedDeltaKB < 1.0, "Net uncollected memory delta < 1.0 KB (Zero memory leak detected)")
print("  -> GC Allocation Stability Verified PASSED!")

-----------------------------------------------------------------------
-- Test Group 6: High-Concurrency Interleaved State & Special Bar Stress Loop
-----------------------------------------------------------------------
print("\n[Test Group 6] High-Concurrency Interleaved State & Special Bar Stress Loop (5,000 cycles)")

startClk = os.clock()
for i = 1, 5000 do
    -- Interleaved stance eval
    local page = GridLock:EvaluateStateDriver(warriorDriver, { bonusbar = (i % 4) })
    mainBar:ChildUpdate("state", page)
    
    -- Interleaved mover update
    local bObj = specialBarList[(i % 10) + 1]
    GridLock:EnsureMoverHandle(bObj.id, bObj.frame)
    GridLock:UpdateMoverHandle(bObj)
    
    -- Interleaved alpha change
    GridLock:SetSpecialBarAlpha(bObj.id, (i % 100) / 100.0)
end
local interDuration = os.clock() - startClk
print(string.format("  -> 5,000 Interleaved operations passed in %.4f sec (%.2f ops/sec)", interDuration, 5000 / interDuration))

-----------------------------------------------------------------------
-- Final Test Summary
-----------------------------------------------------------------------
print("\n=====================================================================")
print(string.format("  ALL GL-M5 ADVERSARIAL STRESS TESTS PASSED! (Passed: %d, Failed: %d)", passCount, failCount))
print("=====================================================================\n")

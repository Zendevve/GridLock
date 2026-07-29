-- test_fe_m1.lua
-- Unit & Integration Tests for ZenAlign FE-M1: Frame-to-Frame Magnetic Docking & Sticky Snapping

-- 1. Mock WoW 3.3.5a API Environment
local mockFrames = {}
local mockScreen = { width = 1920, height = 1080 }
local mouseFocus = nil

_G.GetScreenWidth = function() return mockScreen.width end
_G.GetScreenHeight = function() return mockScreen.height end
_G.GetMouseFocus = function() return mouseFocus end
_G.InCombatLockdown = function() return false end
_G.IsControlKeyDown = function() return false end
_G.IsShiftKeyDown = function() return false end
_G.IsAltKeyDown = function() return false end

_G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg)
        -- mock chat
    end
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
        ClearAllPoints = function(s) s.points = nil end,
        SetPoint = function(s, ...) s.points = {...} end,
        SetAllPoints = function(s, parent) s.allPoints = parent end,
        Show = function(s) s.shown = true end,
        Hide = function(s) s.shown = false end,
        IsShown = function(s) return s.shown end,
    }
    self.textures = self.textures or {}
    table.insert(self.textures, tex)
    return tex
end

function FrameMT:CreateFontString(name, layer, template)
    local fs = {
        name = name,
        layer = layer,
        template = template,
        SetPoint = function(s, ...) s.point = {...} end,
        SetText = function(s, txt) s.text = txt end,
        GetText = function(s) return s.text end,
        SetTextColor = function(s, r, g, b, a) s.color = {r=r, g=g, b=b, a=a} end,
    }
    return fs
end

_G.CreateFrame = function(frameType, name, parent, template)
    local f = setmetatable({
        objectType = frameType,
        name = name,
        parent = parent or _G.UIParent,
        template = template,
        shown = true,
        level = 0,
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

_G.wipe = function(t)
    for k in pairs(t) do t[k] = nil end
    return t
end

-- Load ZenAlign core files
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
loadScript("ZenAlign/Modules/Grid.lua")
loadScript("ZenAlign/Modules/Snap.lua")
loadScript("ZenAlign/Modules/Mover.lua")
loadScript("ZenAlign/Modules/Position.lua")

ZenAlign:Initialize()

-- Test Harness Functions
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

print("=== Running ZenAlign FE-M1: Frame Docking & Sticky Snapping Tests ===")

local Snap = ZenAlign:GetModule("Snap")
local Mover = ZenAlign:GetModule("Mover")

assert_true(Snap ~= nil, "Snap module loaded")
assert_true(Mover ~= nil, "Mover module loaded")

-- Setup Target Frames for Testing
-- TargetFrameA: Center (400, 300), Width 100, Height 50 -> Left=350, Right=450, Top=325, Bottom=275
local frameA = _G.CreateFrame("Frame", "TargetFrameA", UIParent)
frameA.x, frameA.y = 400, 300
frameA:SetSize(100, 50)
frameA:Show()
local moverA = Mover:AttachToFrame(frameA)

-- DraggedFrame: Width 100, Height 50
local draggedFrame = _G.CreateFrame("Frame", "DraggedFrame", UIParent)
draggedFrame:SetSize(100, 50)
draggedFrame:Show()
local moverD = Mover:AttachToFrame(draggedFrame)

-- 1. Test Suite 1: Candidate Target Frames Discovery
print("\n--- Test Suite 1: Target Candidate Discovery & Bounds Normalization ---")
local candidates = Snap:GetCandidateTargetFrames(draggedFrame)
assert_true(#candidates > 0, "Discovered target candidate frames")
local foundA = false
for _, c in ipairs(candidates) do
    if c.frame == frameA then
        foundA = true
        assert_eq(c.left, 350, "FrameA Left bound = 350")
        assert_eq(c.right, 450, "FrameA Right bound = 450")
        assert_eq(c.top, 325, "FrameA Top bound = 325")
        assert_eq(c.bottom, 275, "FrameA Bottom bound = 275")
    end
end
assert_true(foundA, "TargetFrameA present in candidate list")

-- 2. Test Suite 2: Edge-to-Edge Docking Calculations
print("\n--- Test Suite 2: Edge-to-Edge Docking Calculations ---")
Snap:ResetStickyState()
ZenAlign.db.snapEnabled = true
ZenAlign.db.snapToFrames = true
ZenAlign.db.snapThreshold = 10

-- A. TOP-to-BOTTOM: Bottom of dragged docks to Top of target (325).
-- Dragged height = 50 => Dragged raw Y = 347 (Bottom = 322, delta 3px <= 10px).
-- Expected snapped Y = 325 + 25 = 350.
local sx, sy, didSnap, activeSnaps = Snap:GetFrameToFrameSnap(draggedFrame, 400, 347)
assert_near(sy, 350, 0.001, "TOP-to-BOTTOM docking snapped Y to 350")
assert_true(didSnap, "TOP-to-BOTTOM docking didSnap is true")

-- B. BOTTOM-to-TOP: Top of dragged docks to Bottom of target (275).
-- Dragged raw Y = 253 (Top = 278, delta 3px <= 10px).
-- Expected snapped Y = 275 - 25 = 250.
Snap:ResetStickyState()
sx, sy, didSnap = Snap:GetFrameToFrameSnap(draggedFrame, 400, 253)
assert_near(sy, 250, 0.001, "BOTTOM-to-TOP docking snapped Y to 250")

-- C. LEFT-to-RIGHT: Right of dragged docks to Left of target (350).
-- Dragged width = 100 => Dragged raw X = 303 (Right = 353, delta 3px <= 10px).
-- Expected snapped X = 350 - 50 = 300.
Snap:ResetStickyState()
sx, sy, didSnap = Snap:GetFrameToFrameSnap(draggedFrame, 303, 100)
assert_near(sx, 300, 0.001, "LEFT-to-RIGHT docking snapped X to 300")

-- D. RIGHT-to-LEFT: Left of dragged docks to Right of target (450).
-- Dragged raw X = 497 (Left = 447, delta 3px <= 10px).
-- Expected snapped X = 450 + 50 = 500.
Snap:ResetStickyState()
sx, sy, didSnap = Snap:GetFrameToFrameSnap(draggedFrame, 497, 100)
assert_near(sx, 500, 0.001, "RIGHT-to-LEFT docking snapped X to 500")

-- E. Flush LEFT-to-LEFT: Left of dragged aligns with Left of target (350).
-- Dragged raw X = 398 (Left = 348, delta 2px <= 10px).
-- Expected snapped X = 350 + 50 = 400.
Snap:ResetStickyState()
sx, sy, didSnap = Snap:GetFrameToFrameSnap(draggedFrame, 398, 100)
assert_near(sx, 400, 0.001, "Flush LEFT-to-LEFT aligned X to 400")

-- F. Flush RIGHT-to-RIGHT: Right of dragged aligns with Right of target (450).
-- Dragged raw X = 402 (Right = 452, delta 2px <= 10px).
-- Expected snapped X = 450 - 50 = 400.
Snap:ResetStickyState()
sx, sy, didSnap = Snap:GetFrameToFrameSnap(draggedFrame, 402, 100)
assert_near(sx, 400, 0.001, "Flush RIGHT-to-RIGHT aligned X to 400")

-- 3. Test Suite 3: Center Alignments
print("\n--- Test Suite 3: Center Alignments ---")
-- Center Horizontal: Target center X = 400. Use narrow frame (width 80) at raw X = 403 (center delta 3px <= 10px).
local centerTestFrame = _G.CreateFrame("Frame", "CenterTestFrame", UIParent)
centerTestFrame:SetSize(80, 50)
centerTestFrame:Show()
Mover:AttachToFrame(centerTestFrame)

Snap:ResetStickyState()
sx, sy, didSnap, activeSnaps = Snap:GetFrameToFrameSnap(centerTestFrame, 403, 100)
assert_near(sx, 400, 0.001, "Center Horizontal matched X to 400")
local foundGold = false
for _, snap in ipairs(activeSnaps) do
    if snap.colorType == "center" then foundGold = true end
end
assert_true(foundGold, "Center alignment line tagged as 'center' (Gold)")

-- Center Vertical: Target center Y = 300. Dragged raw Y = 295 (delta 5px <= 10px).
Snap:ResetStickyState()
sx, sy, didSnap, activeSnaps = Snap:GetFrameToFrameSnap(draggedFrame, 100, 295)
assert_near(sy, 300, 0.001, "Center Vertical matched Y to 300")

-- 4. Test Suite 4: Sticky Snapping & Hysteresis State Machine
print("\n--- Test Suite 4: Sticky Snapping & Hysteresis State Machine ---")
Snap:ResetStickyState()
ZenAlign.db.snapReleaseThreshold = 16

-- Step 1: Drag to raw X = 303 (LEFT-to-RIGHT docking against Left=350, attraction threshold 10px)
sx, sy, didSnap = Snap:GetFrameToFrameSnap(draggedFrame, 303, 100)
assert_near(sx, 300, 0.001, "Step 1: Snapped raw 303 -> 300")
assert_true(Snap.stickyState.activeX, "Step 1: Sticky lock activeX is true")

-- Step 2: Drag away to raw X = 308 (delta 8px from snapX 300 < releaseThreshold 16px)
sx, sy, didSnap = Snap:GetFrameToFrameSnap(draggedFrame, 308, 100)
assert_near(sx, 300, 0.001, "Step 2: Sticky lock held X at 300 for raw 308")
assert_true(Snap.stickyState.activeX, "Step 2: Sticky lock activeX remains true")

-- Step 3: Drag away to raw X = 318 (delta 18px from snapX 300 >= releaseThreshold 16px)
sx, sy, didSnap = Snap:GetFrameToFrameSnap(draggedFrame, 318, 100)
assert_true(not Snap.stickyState.activeX, "Step 3: Sticky lock broken (activeX is false)")
assert_near(sx, 318, 0.001, "Step 3: Raw position 318 returned after breakaway")

-- 5. Test Suite 5: Guide Line Overlay Creation & Color Coding
print("\n--- Test Suite 5: Guide Line Overlay Creation & Color Coding ---")
Snap:ResetStickyState()

-- Render Cyan edge docking line
local testSnaps = {
    { lineType = "vertical", x = 350, yMin = 200, yMax = 400, colorType = "edge" },
    { lineType = "horizontal", y = 300, xMin = 100, xMax = 500, colorType = "center" },
    { lineType = "vertical", x = 960, yMin = 0, yMax = 1080, colorType = "grid" }
}

Snap:RenderFrameGuideLines(testSnaps)
assert_true(Snap.guideFrame:IsShown(), "Snap.guideFrame overlay is shown")
assert_true(#Snap.guidePool >= 3, "Guide line texture pool allocated 3 lines")

-- Check Cyan edge line
local tex1 = Snap.guidePool[1]
assert_true(tex1:IsShown(), "Line texture 1 shown")
assert_eq(tex1.color.r, 0.0, "Cyan line Red = 0.0")
assert_eq(tex1.color.g, 0.8, "Cyan line Green = 0.8")
assert_eq(tex1.color.b, 1.0, "Cyan line Blue = 1.0")

-- Check Gold center line
local tex2 = Snap.guidePool[2]
assert_true(tex2:IsShown(), "Line texture 2 shown")
assert_eq(tex2.color.r, 1.0, "Gold line Red = 1.0")
assert_eq(tex2.color.g, 0.82, "Gold line Green = 0.82")
assert_eq(tex2.color.b, 0.0, "Gold line Blue = 0.0")

-- Check Green grid line
local tex3 = Snap.guidePool[3]
assert_true(tex3:IsShown(), "Line texture 3 shown")
assert_eq(tex3.color.r, 0.0, "Green line Red = 0.0")
assert_eq(tex3.color.g, 1.0, "Green line Green = 1.0")
assert_eq(tex3.color.b, 0.4, "Green line Blue = 0.4")

-- Test ClearGuideLines
Snap:ClearGuideLines()
assert_true(not Snap.guideFrame:IsShown(), "Guide overlay hidden after ClearGuideLines")
for _, tex in ipairs(Snap.guidePool) do
    assert_true(not tex.inUse, "Guide texture inUse is false after clear")
end

-- 6. Test Suite 6: Mover Drag Integration
print("\n--- Test Suite 6: Mover Drag Integration ---")
assert_true(moverD ~= nil, "Mover attached to draggedFrame")

Mover:OnDragStart(moverD)
assert_true(moverD.isDragging, "Mover isDragging is true on drag start")

moverD.x, moverD.y = 303, 100
Mover:OnDragUpdate(moverD)
assert_true(Snap.guideFrame:IsShown(), "Guide lines rendered during mover drag update")

Mover:OnDragStop(moverD)
assert_true(not moverD.isDragging, "Mover isDragging is false on drag stop")
assert_true(not Snap.guideFrame:IsShown(), "Guide lines cleared on mover drag stop")

print("\n=== Test Results ===")
print(string.format("Passed: %d, Failed: %d", passCount, failCount))
if failCount > 0 then
    os.exit(1)
end

-- tests/test_gl_bar_excellence.lua
-- Unit & Integration Test Suite for Action Bar Customization & Superiority

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

-- Mock WoW API Environment
_G.UIParent = {
    GetEffectiveScale = function() return 1.0 end,
    GetWidth = function() return 1920 end,
    GetHeight = function() return 1080 end,
    GetLeft = function() return 0 end,
    GetBottom = function() return 0 end,
    GetRight = function() return 1920 end,
    GetTop = function() return 1080 end,
}
_G.WorldFrame = {}
_G.DEFAULT_CHAT_FRAME = { AddMessage = function(self, msg) end }

_G.GetTime = function() return 1000.0 end
_G.InCombatLockdown = function() return false end

local driversRegistered = {}
_G.RegisterStateDriver = function(frame, state, driverString)
    driversRegistered[frame] = driverString
end

local masqueButtons = {}
_G.LibStub = function(lib, silent)
    if lib == "Masque" or lib == "ButtonFacade" then
        return {
            Group = function(self, addon, groupName)
                return {
                    AddButton = function(selfGroup, btn)
                        table.insert(masqueButtons, btn)
                    end
                }
            end
        }
    end
    return nil
end

_G.CreateFrame = function(frameType, name, parent, template)
    local f = {
        name = name,
        parent = parent,
        shown = true,
        points = {},
        scale = 1.0,
        alpha = 1.0,
        scripts = {},
        attributes = {},
    }
    f.GetName = function(self) return self.name end
    f.GetParent = function(self) return self.parent end
    f.IsShown = function(self) return self.shown end
    f.Show = function(self) self.shown = true end
    f.Hide = function(self) self.shown = false end
    f.SetMovable = function(self, mov) end
    f.SetUserPlaced = function(self, up) end
    f.SetFrameStrata = function(self, strata) end
    f.SetFrameLevel = function(self, level) self.level = level end
    f.GetFrameLevel = function(self) return self.level or 1 end
    f.SetClampedToScreen = function(self, clamp) end
    f.SetAllPoints = function(self, rel) end
    f.EnableMouse = function(self, enable) self.mouseEnabled = enable end
    f.SetAutoFocus = function(self, auto) end
    f.ClearFocus = function(self) end
    f.SetScrollChild = function(self, child) end
    f.GetEffectiveScale = function(self) return self.scale end
    f.GetScale = function(self) return self.scale end
    f.SetScale = function(self, sc) self.scale = sc end
    f.GetAlpha = function(self) return self.alpha end
    f.SetAlpha = function(self, a) self.alpha = a end
    f.GetWidth = function(self) return 36 end
    f.GetHeight = function(self) return 36 end
    f.SetWidth = function(self, w) self.w = w end
    f.SetHeight = function(self, h) self.h = h end
    f.SetSize = function(self, w, h) self.w = w; self.h = h end
    f.SetChecked = function(self, chk) self.checked = chk end
    f.GetChecked = function(self) return self.checked end
    f.LockHighlight = function(self) end
    f.UnlockHighlight = function(self) end
    f.SetMinMaxValues = function(self, min, max) end
    f.SetValueStep = function(self, step) end
    f.SetValue = function(self, val) self.val = val end
    f.GetValue = function(self) return self.val or 0 end
    f.SetText = function(self, t) self.text = t end
    f.GetText = function(self) return self.text end
    f.GetCenter = function(self) return 500, 500 end
    f.GetLeft = function(self) return 482 end
    f.GetRight = function(self) return 518 end
    f.GetBottom = function(self) return 482 end
    f.GetTop = function(self) return 518 end
    f.GetNumPoints = function(self) return #self.points end
    f.GetPoint = function(self, idx) return "CENTER", _G.UIParent, "CENTER", 0, 0 end
    f.SetPoint = function(self, p, rel, rp, x, y) table.insert(self.points, { p, rel, rp, x, y }) end
    f.ClearAllPoints = function(self) self.points = {} end
    f.SetAllPoints = function(self, rel) end
    f.SetBackdrop = function(self, bd) end
    f.SetBackdropColor = function(self, r, g, b, a) end
    f.SetBackdropBorderColor = function(self, r, g, b, a) end
    f.CreateTexture = function(self)
        return {
            SetTexture = function() end,
            SetVertexColor = function(s, r, g, b, a) self.borderColor = { r, g, b, a } end,
            SetWidth = function() end,
            SetHeight = function() end,
            SetPoint = function() end,
            SetAllPoints = function() end,
            ClearAllPoints = function() end,
            Hide = function() end,
            Show = function() end,
            SetTexCoord = function() end,
        }
    end
    f.CreateFontString = function(self)
        return {
            SetPoint = function() end,
            SetWidth = function() end,
            SetHeight = function() end,
            SetTextColor = function() end,
            SetText = function(s, txt) self.text = txt end,
            GetText = function(s) return self.text end,
            Hide = function() end,
            Show = function() end,
        }
    end
    f.SetScript = function(self, script, fn) self.scripts[script] = fn end
    f.GetScript = function(self, script) return self.scripts[script] end
    f.SetAttribute = function(self, k, v) self.attributes[k] = v end

    if name then
        _G[name] = f
        _G[name .. "Low"] = f:CreateFontString()
        _G[name .. "High"] = f:CreateFontString()
        _G[name .. "Text"] = f:CreateFontString()
    end
    return f
end

-- Load Modules
dofile("GridLock/Localization/enUS.lua")
dofile("GridLock/Core/Init.lua")
dofile("GridLock/Core/Utils.lua")
dofile("GridLock/Core/Config.lua")
dofile("GridLock/Data/Frames.lua")
dofile("GridLock/Data/Position.lua")
dofile("GridLock/Modules/Position.lua")
dofile("GridLock/Modules/BarLayout.lua")
dofile("GridLock/Modules/ActionBarState.lua")
dofile("GridLock/UI/Dashboard.lua")

print("=========================================")
print("Running GridLock Action Bar Excellence Tests")
print("=========================================")

-- Test Group 1: Custom State Driver Registration
print("[Test Group 1] Custom State Driver Registration")
local barFrame = _G.CreateFrame("Frame", "MainMenuBar")
GridLock:SetCustomStateDriver(barFrame, "[mod:alt] 2; [bonusbar:1] 7")
assert_eq(barFrame.customStateDriver, "[mod:alt] 2; [bonusbar:1] 7", "Custom state driver stored on frame")
assert_eq(driversRegistered[barFrame], "[mod:alt] 2; [bonusbar:1] 7", "Registered driver string with WoW C-engine")

-- Test Group 2: Border Color & Masque Grouping
print("[Test Group 2] Custom Border Tinting & Masque Registration")
local btn1 = _G.CreateFrame("Button", "MainMenuBarButton1")
btn1.Border = btn1:CreateTexture()

GridLock:SetBarBorderColor(barFrame, 0.0, 0.8, 1.0, 1.0)
assert_true(barFrame.borderColor ~= nil, "Bar border color set")

GridLock:RegisterMasqueGroup(barFrame, "MainMenuBar")
assert_true(#masqueButtons >= 1, "Registered buttons with Masque group")

-- Test Group 3: Dashboard Action Bar Customizer Card
print("[Test Group 3] Dashboard Action Bar Inspector Card")
local Dashboard = GridLock:GetModule("Dashboard")
Dashboard:CreateFrame()
Dashboard:SelectFrame("MainMenuBar")
assert_true(Dashboard.currentFrameName == "MainMenuBar", "Selected MainMenuBar in Dashboard")

print("=========================================")
print(string.format("All Action Bar Excellence Tests PASSED! (Passed: %d, Failed: 0)", passCount))
print("=========================================")

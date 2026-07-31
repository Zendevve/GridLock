-- GridLock UI Theme Module
-- Modern Dark-Glass Border Engine for WoW 3.3.5a

local addonName, GridLock = ...
GridLock = GridLock or _G.GridLock or {}
_G.GridLock = GridLock

local Theme = {}
if type(GridLock.RegisterModule) == "function" then
    GridLock:RegisterModule("Theme", Theme)
else
    GridLock.modules = GridLock.modules or {}
    GridLock.modules["Theme"] = Theme
end
GridLock.Theme = Theme

-- Color Constants (3.3.5a RGBA floats 0.0 - 1.0)
Theme.DARK_GLASS_BG = { r = 0.03, g = 0.04, b = 0.06, a = 0.95 }
Theme.GLOWING_CYAN_BORDER = { r = 0.0, g = 0.8, b = 1.0, a = 0.8 }
Theme.CARD_BG = { r = 0.04, g = 0.05, b = 0.08, a = 0.9 }
Theme.CARD_BORDER = { r = 0.12, g = 0.16, b = 0.22, a = 0.8 }

-- Helper function to generate backdrop table
function Theme:GetBackdropTable(edgeSize)
    return {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = edgeSize or 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    }
end

-- Apply Modern Dark-Glass style to any WoW frame
function Theme:ApplyDarkGlass(frame, bgR, bgG, bgB, bgA, borderR, borderG, borderB, borderA)
    if not frame or type(frame) ~= "table" then return false end
    if not frame.SetBackdrop then return false end

    local bg = self.DARK_GLASS_BG
    local border = self.GLOWING_CYAN_BORDER

    bgR = bgR or bg.r
    bgG = bgG or bg.g
    bgB = bgB or bg.b
    bgA = bgA or bg.a

    borderR = borderR or border.r
    borderG = borderG or border.g
    borderB = borderB or border.b
    borderA = borderA or border.a

    frame:SetBackdrop(self:GetBackdropTable(1))
    if frame.SetBackdropColor then
        frame:SetBackdropColor(bgR, bgG, bgB, bgA)
    end
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
    end
    return true
end

-- Create a pre-styled dark glass panel frame
function Theme:CreateDarkGlassFrame(name, parent, width, height, bg, border)
    local f = CreateFrame("Frame", name, parent or UIParent)
    if width then f:SetWidth(width) end
    if height then f:SetHeight(height) end

    bg = bg or self.DARK_GLASS_BG
    border = border or self.GLOWING_CYAN_BORDER

    self:ApplyDarkGlass(f, bg.r, bg.g, bg.b, bg.a, border.r, border.g, border.b, border.a)
    return f
end

-- Public API helper on GridLock core object
function GridLock:ApplyDarkGlassStyle(frame, bgR, bgG, bgB, bgA, borderR, borderG, borderB, borderA)
    return Theme:ApplyDarkGlass(frame, bgR, bgG, bgB, bgA, borderR, borderG, borderB, borderA)
end

return Theme

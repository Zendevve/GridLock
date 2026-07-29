-- ZenAlign Visibility Module
-- Handles hiding and showing frames

local ZenAlign = select(2, ...)

local Visibility = {}
ZenAlign:RegisterModule("Visibility", Visibility)

-- Hidden frames storage
Visibility.hiddenFrames = {}

function Visibility:OnInitialize()
    if ZenAlign.db then
        if not ZenAlign.db.hiddenFrames then
            ZenAlign.db.hiddenFrames = {}
        end
        self.hiddenFrames = ZenAlign.db.hiddenFrames
    end

    self:ApplySavedHiddenStates()
end

-- Apply saved hidden states on login/initialize
function Visibility:ApplySavedHiddenStates()
    if not self.hiddenFrames then return end

    for frameName, data in pairs(self.hiddenFrames) do
        local frame = _G[frameName]
        if frame and not ZenAlign.Utils.IsProtectedInCombat(frame) then
            frame:SetAlpha(0)
            if frame.EnableMouse then
                frame:EnableMouse(false)
            end
        end
    end
end

-- Hide a frame
function Visibility:HideFrame(frameName)
    local frame = _G[frameName]
    if not frame then
        ZenAlign.Utils.Print(ZENALIGN.FRAME_NOT_FOUND, frameName)
        return false
    end

    -- Check combat lockdown
    if ZenAlign.Utils.IsProtectedInCombat(frame) then
        ZenAlign.Utils.Print(ZENALIGN.FRAME_PROTECTED)
        return false
    end

    -- Store original visibility state if not present
    if not self.hiddenFrames[frameName] then
        local origAlpha = frame:GetAlpha()
        if origAlpha == 0 then origAlpha = 1.0 end
        self.hiddenFrames[frameName] = {
            wasShown = frame:IsShown(),
            alpha = origAlpha,
        }
    end

    -- Hide via alpha and disable mouse (safer than Hide() for standard frames)
    frame:SetAlpha(0)
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end

    ZenAlign.Utils.Print(ZENALIGN.FRAME_HIDDEN, frameName)
    return true
end

-- Show a hidden frame
function Visibility:ShowFrame(frameName)
    local frame = _G[frameName]
    if not frame then
        ZenAlign.Utils.Print(ZENALIGN.FRAME_NOT_FOUND, frameName)
        return false
    end

    -- Check combat lockdown
    if ZenAlign.Utils.IsProtectedInCombat(frame) then
        ZenAlign.Utils.Print(ZENALIGN.FRAME_PROTECTED)
        return false
    end

    -- Restore original state
    local stored = self.hiddenFrames[frameName]
    local restoreAlpha = 1.0
    if type(stored) == "table" and stored.alpha then
        restoreAlpha = stored.alpha
    end

    frame:SetAlpha(restoreAlpha)
    if frame.EnableMouse then
        frame:EnableMouse(true)
    end

    self.hiddenFrames[frameName] = nil

    ZenAlign.Utils.Print(ZENALIGN.FRAME_SHOWN, frameName)
    return true
end

-- Toggle frame visibility
function Visibility:ToggleFrame(frameName)
    if self.hiddenFrames[frameName] then
        return self:ShowFrame(frameName)
    else
        return self:HideFrame(frameName)
    end
end

-- Check if frame is hidden by us
function Visibility:IsHidden(frameName)
    return self.hiddenFrames[frameName] ~= nil
end

-- Show all hidden frames
function Visibility:ShowAll()
    local keys = {}
    for frameName, _ in pairs(self.hiddenFrames) do
        table.insert(keys, frameName)
    end
    for _, frameName in ipairs(keys) do
        self:ShowFrame(frameName)
    end
    wipe(self.hiddenFrames)
end

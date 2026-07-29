-- ZenAlign Position Module
-- Handles saving, loading, and applying frame positions

local ZenAlign = select(2, ...)

local Position = {}
ZenAlign:RegisterModule("Position", Position)

-- Original positions storage (for reset)
Position.originalPositions = {}

-- Hooked frames to prevent Blizzard overriding our positions
Position.hookedFrames = {}

-- Original managed frame positions (for reset)
Position.managedFrameBackup = {}

function Position:OnInitialize()
    -- Apply saved positions after a short delay (some frames load late)
    if C_Timer and C_Timer.After then
        C_Timer.After(0.5, function()
            self:ApplyAllSavedPositions()
        end)
    else
        -- Fallback for 3.3.5a which may not have C_Timer
        local f = CreateFrame("Frame")
        f.elapsed = 0
        f:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed > 0.5 then
                Position:ApplyAllSavedPositions()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

-- Save frame position
function Position:SavePosition(frameName, frame)
    if not frame then
        frame = _G[frameName]
    end
    if not frame then return false end

    -- Store original position, scale, and alpha if not already stored
    if not self.originalPositions[frameName] then
        local origAlpha = frame:GetAlpha()
        if not origAlpha or origAlpha == 0 then origAlpha = 1.0 end
        self.originalPositions[frameName] = {
            points = self:SerializeAllPoints(frame),
            scale = frame:GetScale() or 1.0,
            alpha = origAlpha
        }
    end

    -- Get current position
    local posData = ZenAlign.Utils.SerializePoint(frame, 1)
    if not posData then return false end

    -- Retain existing scale and alpha if present in DB
    local existing = ZenAlign:GetFramePosition(frameName)
    if existing then
        posData.scale = existing.scale
        posData.alpha = existing.alpha
    end

    -- Save to database
    ZenAlign:SaveFramePosition(frameName, posData)

    -- Disable managed frame positioning for this frame
    self:DisableManagedPosition(frameName)

    -- Hook frame to prevent position changes
    self:HookFrame(frameName, frame)

    ZenAlign.Utils.Debug("Saved position for %s", frameName)
    return true
end

-- Serialize all points for a frame
function Position:SerializeAllPoints(frame)
    local points = {}
    for i = 1, frame:GetNumPoints() do
        local pointData = ZenAlign.Utils.SerializePoint(frame, i)
        if pointData then
            table.insert(points, pointData)
        end
    end
    return points
end

-- Disable Blizzard's managed frame positioning
function Position:DisableManagedPosition(frameName)
    -- Handle UIPARENT_MANAGED_FRAME_POSITIONS
    if UIPARENT_MANAGED_FRAME_POSITIONS and UIPARENT_MANAGED_FRAME_POSITIONS[frameName] then
        if not self.managedFrameBackup[frameName] then
            self.managedFrameBackup[frameName] = UIPARENT_MANAGED_FRAME_POSITIONS[frameName]
        end
        UIPARENT_MANAGED_FRAME_POSITIONS[frameName] = nil
        ZenAlign.Utils.Debug("Disabled managed position for %s", frameName)
    end

    -- Handle UIPanelWindows
    if UIPanelWindows and UIPanelWindows[frameName] then
        if not self.managedFrameBackup[frameName .. "_panel"] then
            self.managedFrameBackup[frameName .. "_panel"] = UIPanelWindows[frameName]
        end
        UIPanelWindows[frameName] = nil
    end
end

-- Re-enable Blizzard's managed frame positioning
function Position:EnableManagedPosition(frameName)
    if self.managedFrameBackup[frameName] then
        if UIPARENT_MANAGED_FRAME_POSITIONS then
            UIPARENT_MANAGED_FRAME_POSITIONS[frameName] = self.managedFrameBackup[frameName]
        end
        self.managedFrameBackup[frameName] = nil
    elseif UIPARENT_MANAGED_FRAME_POSITIONS and frameName == "MainMenuBar" then
        UIPARENT_MANAGED_FRAME_POSITIONS[frameName] = { baseY = 0 }
    end

    if self.managedFrameBackup[frameName .. "_panel"] then
        if UIPanelWindows then
            UIPanelWindows[frameName] = self.managedFrameBackup[frameName .. "_panel"]
        end
        self.managedFrameBackup[frameName .. "_panel"] = nil
    end
end

-- Apply saved position to frame
function Position:ApplyPosition(frameName, posData)
    local frame = _G[frameName]
    if not frame then return false end

    if not posData then
        posData = ZenAlign:GetFramePosition(frameName)
    end
    if not posData then return false end

    -- Check combat lockdown
    if ZenAlign.Utils.IsProtectedInCombat(frame) then
        ZenAlign.Utils.Debug("Cannot apply position to %s during combat", frameName)
        return false
    end

    -- Store original if not stored
    if not self.originalPositions[frameName] then
        local origAlpha = frame:GetAlpha()
        if not origAlpha or origAlpha == 0 then origAlpha = 1.0 end
        self.originalPositions[frameName] = {
            points = self:SerializeAllPoints(frame),
            scale = frame:GetScale() or 1.0,
            alpha = origAlpha
        }
    end

    -- Disable managed positioning BEFORE applying
    self:DisableManagedPosition(frameName)

    -- Apply scale if saved
    if posData.scale and frame.SetScale then
        frame:SetScale(posData.scale)
    end

    -- Apply alpha if saved (but NEVER restore alpha=0 unless Visibility has it hidden)
    if posData.alpha and frame.SetAlpha then
        local Visibility = ZenAlign:GetModule("Visibility")
        local isHiddenByUs = Visibility and Visibility:IsHidden(frameName)
        if posData.alpha > 0 or isHiddenByUs then
            frame:SetAlpha(posData.alpha)
        else
            -- Saved alpha was 0 but frame is not hidden — restore to 1.0
            frame:SetAlpha(1.0)
        end
    end

    -- Apply position using original SetPoint (bypass our hook)
    local applyPoint = frame.ZenAlignOriginalSetPoint or frame.SetPoint
    local clearPoints = frame.ZenAlignOriginalClearAllPoints or frame.ClearAllPoints

    clearPoints(frame)

    local relativeTo = _G[posData.relativeTo] or UIParent
    applyPoint(frame, posData.point, relativeTo, posData.relativePoint, posData.x, posData.y)

    -- Hook frame after applying
    self:HookFrame(frameName, frame)

    ZenAlign.Utils.Debug("Applied position to %s", frameName)
    return true
end

-- Apply all saved positions
function Position:ApplyAllSavedPositions()
    for frameName, posData in pairs(ZenAlign.db.frames) do
        self:ApplyPosition(frameName, posData)
    end
end

-- Save original position helper
function Position:SaveOriginalPosition(frameName, frame)
    if not frame then frame = _G[frameName] end
    if not frame then return end

    if not self.originalPositions[frameName] then
        local origAlpha = frame:GetAlpha()
        if not origAlpha or origAlpha == 0 then origAlpha = 1.0 end
        self.originalPositions[frameName] = {
            points = self:SerializeAllPoints(frame),
            scale = frame:GetScale() or 1.0,
            alpha = origAlpha
        }
    end
end

-- Reset frame to original position
function Position:ResetPosition(frameName)
    local frame = _G[frameName]
    if not frame then return false end

    -- Check combat lockdown
    if ZenAlign.Utils.IsProtectedInCombat(frame) then
        ZenAlign.Utils.Print(ZENALIGN.POSITION_LOCKED, frameName)
        return false
    end

    -- Unhook the frame first so SetPoint/ClearAllPoints calls bypass hooks
    self:UnhookFrame(frameName)

    -- Re-enable managed positioning
    self:EnableManagedPosition(frameName)

    -- Clear visibility hidden state (so frame becomes visible again)
    local Visibility = ZenAlign:GetModule("Visibility")
    if Visibility and Visibility:IsHidden(frameName) then
        Visibility:ShowFrame(frameName)
    end

    -- Always force alpha and scale back to sane defaults
    if frame.SetAlpha then
        frame:SetAlpha(1.0)
    end
    if frame.SetScale then
        frame:SetScale(1.0)
    end
    if frame.EnableMouse then
        frame:EnableMouse(true)
    end

    -- Clear points before restoring
    frame:ClearAllPoints()

    -- Restoring position order:
    -- 1. Stored session original points
    -- 2. Hardcoded default position catalog
    -- 3. Standard screen center fallback
    local origData = self.originalPositions[frameName]
    local defaultPos = ZenAlign.PositionData and ZenAlign.PositionData:GetDefaultPosition(frameName)

    if origData and origData.points and #origData.points > 0 then
        for _, pointData in ipairs(origData.points) do
            ZenAlign.Utils.ApplyPoint(frame, pointData)
        end
    elseif defaultPos then
        local relTo = _G[defaultPos.relativeTo] or UIParent
        frame:SetPoint(defaultPos.point, relTo, defaultPos.relativePoint, defaultPos.x, defaultPos.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- Clear original storage and saved position from DB
    self.originalPositions[frameName] = nil
    ZenAlign:ClearFramePosition(frameName)

    -- Force UIParent to update managed frames
    if UIParent_ManageFramePositions then
        UIParent_ManageFramePositions()
    end

    -- Update Mover overlay position if attached
    local Mover = ZenAlign:GetModule("Mover")
    if Mover then
        local mover = Mover:GetMoverForFrame(frameName)
        if mover then
            Mover:UpdateMoverPosition(mover)
            Mover:UpdateTooltip(mover)
        end
    end

    return true
end

-- Reset ALL frames to default positions, scales, alphas, and hidden states
function Position:ResetAll()
    -- Collect all frame names to reset
    local framesToReset = {}
    if ZenAlign.db and ZenAlign.db.frames then
        for frameName in pairs(ZenAlign.db.frames) do
            framesToReset[frameName] = true
        end
    end
    for frameName in pairs(self.originalPositions) do
        framesToReset[frameName] = true
    end

    -- Detach all movers first
    local Mover = ZenAlign:GetModule("Mover")
    if Mover then
        Mover:DetachAll()
    end

    -- Show all hidden frames
    local Visibility = ZenAlign:GetModule("Visibility")
    if Visibility then
        Visibility:ShowAll()
    end

    -- Reset each recorded frame
    for frameName in pairs(framesToReset) do
        self:ResetPosition(frameName)
    end

    -- Wipe saved databases
    if ZenAlign.db then
        if ZenAlign.db.frames then wipe(ZenAlign.db.frames) end
        if ZenAlign.db.hiddenFrames then wipe(ZenAlign.db.hiddenFrames) end
    end
    wipe(self.originalPositions)

    -- Update Blizzard layout engine
    if UIParent_ManageFramePositions then
        UIParent_ManageFramePositions()
    end

    ZenAlign.Utils.Print(ZENALIGN.POSITION_RESET_ALL or "All frame positions, scales, and visibilities have been reset.")
end

-- Hook frame to prevent external position changes
function Position:HookFrame(frameName, frame)
    if not frame then
        frame = _G[frameName]
    end
    if not frame then return end

    -- Mark as hooked
    self.hookedFrames[frameName] = true

    -- Already fully hooked
    if frame.ZenAlignHooked then return end

    -- Store originals
    local originalSetPoint = frame.SetPoint
    local originalClearAllPoints = frame.ClearAllPoints

    frame.ZenAlignOriginalSetPoint = originalSetPoint
    frame.ZenAlignOriginalClearAllPoints = originalClearAllPoints

    -- Hook SetPoint - block external calls, reapply our position
    frame.SetPoint = function(self, ...)
        local name = self:GetName()
        if name and Position.hookedFrames[name] then
            local posData = ZenAlign:GetFramePosition(name)
            if posData then
                -- Ignore external SetPoint, but reapply our position
                originalClearAllPoints(self)
                local relativeTo = _G[posData.relativeTo] or UIParent
                originalSetPoint(self, posData.point, relativeTo, posData.relativePoint, posData.x, posData.y)
                return
            end
        end
        return originalSetPoint(self, ...)
    end

    -- Hook ClearAllPoints - prevent it from clearing, then reapply
    frame.ClearAllPoints = function(self)
        local name = self:GetName()
        if name and Position.hookedFrames[name] then
            local posData = ZenAlign:GetFramePosition(name)
            if posData then
                -- Don't actually clear, we'll handle positioning
                return
            end
        end
        return originalClearAllPoints(self)
    end

    frame.ZenAlignHooked = true
    ZenAlign.Utils.Debug("Hooked frame: %s", frameName)
end

-- Remove hook from frame
function Position:UnhookFrame(frameName)
    local frame = _G[frameName]
    if not frame then return end

    self.hookedFrames[frameName] = nil

    -- Restore original methods
    if frame.ZenAlignHooked then
        if frame.ZenAlignOriginalSetPoint then
            frame.SetPoint = frame.ZenAlignOriginalSetPoint
            frame.ZenAlignOriginalSetPoint = nil
        end
        if frame.ZenAlignOriginalClearAllPoints then
            frame.ClearAllPoints = frame.ZenAlignOriginalClearAllPoints
            frame.ZenAlignOriginalClearAllPoints = nil
        end
        frame.ZenAlignHooked = nil
    end

    ZenAlign.Utils.Debug("Unhooked frame: %s", frameName)
end

-- Get original position for frame
function Position:GetOriginalPosition(frameName)
    return self.originalPositions[frameName]
end

-- Check if frame has been modified
function Position:IsModified(frameName)
    return ZenAlign:HasSavedPosition(frameName)
end


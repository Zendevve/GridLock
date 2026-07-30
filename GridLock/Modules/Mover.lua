-- GridLock Mover Module
-- Handles frame movers for drag-to-move, drag-to-scale, alpha adjustment, and quick controls

local GridLock = select(2, ...)

local Mover = {}
GridLock:RegisterModule("Mover", Mover)

-- Active movers
Mover.movers = {}
Mover.moverPool = {}
Mover.nextId = 1

function Mover:OnInitialize()
    -- Movers created on demand
end

-- Update dynamic real-time visual tooltip for mover
function Mover:UpdateTooltip(mover)
    if not mover or not mover.frameName or not mover.targetFrame then return end
    if not GridLock.db or not GridLock.db.showMoverTooltip then return end
    if GameTooltip:GetOwner() ~= mover then return end

    local frame = mover.targetFrame
    local frameName = mover.frameName
    local displayName = frameName
    local frameInfo = GridLock.FrameData and GridLock.FrameData:GetFrameInfo(frameName)
    if frameInfo then
        displayName = frameInfo.displayName
    end

    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    point = point or "CENTER"
    x = x and GridLock.Utils.Round(x, 1) or 0
    y = y and GridLock.Utils.Round(y, 1) or 0

    local scale = frame:GetScale() or 1.0
    local scalePercent = math.floor(scale * 100 + 0.5)

    local alpha = frame:GetAlpha() or 1.0
    local alphaPercent = math.floor(alpha * 100 + 0.5)

    GameTooltip:ClearLines()
    GameTooltip:AddLine(displayName, 1, 1, 1)
    if displayName ~= frameName then
        GameTooltip:AddLine("(" .. frameName .. ")", 0.6, 0.6, 0.6)
    end
    GameTooltip:AddLine(string.format("Position: %s (X: %.1f, Y: %.1f)", point, x, y), 0.8, 0.8, 0.8)
    GameTooltip:AddLine(string.format("Scale: %d%%  |  Alpha: %d%%", scalePercent, alphaPercent), 0, 0.9, 1)
    GameTooltip:AddLine("Drag: Move | Wheel: Scale | Shift+Wheel: Alpha | Arrows: Nudge", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

-- Create a new mover frame
function Mover:CreateMover(id)
    local mover = CreateFrame("Frame", "GridLockMover" .. id, UIParent)
    mover:SetFrameStrata("TOOLTIP")
    mover:SetFrameLevel(100)
    mover:EnableMouse(true)
    mover:SetMovable(true)
    mover:RegisterForDrag("LeftButton")
    mover:SetClampedToScreen(true)

    -- Sleek Dark-Glass Mover Overlay Backdrop
    mover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })

    -- Solid dark glass backdrop color (0.08, 0.08, 0.12, 0.75) with subtle accent border
    mover:SetBackdropColor(0.08, 0.08, 0.12, 0.75)
    mover:SetBackdropBorderColor(0.2, 0.6, 1.0, 0.8)

    -- Label
    local label = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", mover, "CENTER", 0, 0)
    label:SetTextColor(1, 1, 1, 1)
    mover.label = label

    -- Drag handlers
    mover:SetScript("OnDragStart", function(self)
        Mover:OnDragStart(self)
    end)

    mover:SetScript("OnDragStop", function(self)
        Mover:OnDragStop(self)
    end)

    -- Update position and tooltip during drag
    mover:SetScript("OnUpdate", function(self)
        if self.isDragging then
            Mover:OnDragUpdate(self)
        end
    end)

    -- Mouse wheel scaling & alpha adjustments
    mover:EnableMouseWheel(true)
    mover:SetScript("OnMouseWheel", function(self, delta)
        if not self.targetFrame or not self.frameName then return end

        local step = (delta > 0) and 0.05 or -0.05

        if IsShiftKeyDown() then
            -- Adjust Alpha (0.1 to 1.0, step 0.05) — min 0.1 to prevent invisible frames
            local currAlpha = self.targetFrame:GetAlpha() or 1.0
            if currAlpha == 0 then currAlpha = 1.0 end -- fix if frame was hidden
            local newAlpha = GridLock.Utils.Round(math.min(1.0, math.max(0.1, currAlpha + step)), 2)
            self.targetFrame:SetAlpha(newAlpha)
            GridLock:SaveFrameAlpha(self.frameName, newAlpha)
        else
            -- Adjust Scale (0.5 to 2.0, step 0.05)
            local currScale = self.targetFrame:GetScale() or 1.0
            local newScale = GridLock.Utils.Round(math.min(2.0, math.max(0.5, currScale + step)), 2)
            self.targetFrame:SetScale(newScale)
            GridLock:SaveFrameScale(self.frameName, newScale)
            Mover:UpdateMoverPosition(self)
        end

        Mover:UpdateTooltip(self)

        local Dashboard = GridLock:GetModule("Dashboard")
        if Dashboard and Dashboard.frame and Dashboard.frame:IsShown() and Dashboard.currentFrameName == self.frameName then
            Dashboard:UpdateInspector()
        end
    end)

    -- Keyboard arrow key nudging listener
    mover:EnableKeyboard(true)
    mover:SetScript("OnKeyDown", function(self, key)
        if not self.frameName then
            if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(true) end
            return
        end

        local step = IsShiftKeyDown() and 10 or 1
        if key == "UP" then
            Mover:NudgeFrame(self.frameName, 0, step)
            if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
        elseif key == "DOWN" then
            Mover:NudgeFrame(self.frameName, 0, -step)
            if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
        elseif key == "LEFT" then
            Mover:NudgeFrame(self.frameName, -step, 0)
            if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
        elseif key == "RIGHT" then
            Mover:NudgeFrame(self.frameName, step, 0)
            if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
        else
            if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(true) end
            return
        end

        Mover:UpdateTooltip(self)

        local Dashboard = GridLock:GetModule("Dashboard")
        if Dashboard and Dashboard.frame and Dashboard.frame:IsShown() and Dashboard.currentFrameName == self.frameName then
            Dashboard:UpdateInspector()
        end
    end)

    -- Top-Right 3-Button Quick Toolbar
    local bar = CreateFrame("Frame", nil, mover)
    bar:SetWidth(60)
    bar:SetHeight(18)
    bar:SetPoint("TOPRIGHT", mover, "TOPRIGHT", -2, -2)
    bar:SetFrameLevel(mover:GetFrameLevel() + 10)
    mover.toolbar = bar

    -- Inspect Button [E]
    local btnInspect = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    btnInspect:SetWidth(18)
    btnInspect:SetHeight(16)
    btnInspect:SetPoint("RIGHT", bar, "RIGHT", -36, 0)
    btnInspect:SetText("E")
    btnInspect:SetFrameLevel(bar:GetFrameLevel() + 1)
    btnInspect:SetScript("OnClick", function(self)
        if mover.frameName then
            local Dashboard = GridLock:GetModule("Dashboard")
            if Dashboard then
                Dashboard:Show()
                Dashboard:SelectFrame(mover.frameName)
            end
        end
    end)
    btnInspect:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Inspect Frame in Dashboard [E]", 1, 1, 1)
        GameTooltip:Show()
    end)
    btnInspect:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    -- Reset Button [R]
    local btnReset = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    btnReset:SetWidth(18)
    btnReset:SetHeight(16)
    btnReset:SetPoint("RIGHT", bar, "RIGHT", -18, 0)
    btnReset:SetText("R")
    btnReset:SetFrameLevel(bar:GetFrameLevel() + 1)
    btnReset:SetScript("OnClick", function(self)
        if mover.frameName then
            local Position = GridLock:GetModule("Position")
            if Position then
                Position:ResetPosition(mover.frameName)
            end
            Mover:UpdateMoverPosition(mover)
            Mover:UpdateTooltip(mover)
            local Dashboard = GridLock:GetModule("Dashboard")
            if Dashboard and Dashboard.frame and Dashboard.frame:IsShown() and Dashboard.currentFrameName == mover.frameName then
                Dashboard:UpdateInspector()
            end
        end
    end)
    btnReset:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Reset Frame Position, Scale & Alpha [R]", 1, 1, 1)
        GameTooltip:Show()
    end)
    btnReset:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    -- Visibility Toggle Button [X]
    local btnVisibility = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    btnVisibility:SetWidth(18)
    btnVisibility:SetHeight(16)
    btnVisibility:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    btnVisibility:SetText("X")
    btnVisibility:SetFrameLevel(bar:GetFrameLevel() + 1)
    btnVisibility:SetScript("OnClick", function(self)
        if mover.frameName then
            local frameName = mover.frameName
            local Visibility = GridLock:GetModule("Visibility")
            if Visibility then
                Visibility:ToggleFrame(frameName)
                if Visibility:IsHidden(frameName) then
                    Mover:DetachFromFrame(frameName)
                end
            end
        end
    end)
    btnVisibility:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Toggle Frame Visibility [X]", 1, 1, 1)
        GameTooltip:Show()
    end)
    btnVisibility:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

    -- Real-time Tooltip OnEnter / OnLeave
    mover:SetScript("OnEnter", function(self)
        if GridLock.db and GridLock.db.showMoverTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
            Mover:UpdateTooltip(self)
        end
    end)

    mover:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    mover:Hide()
    mover.id = id

    return mover
end

-- Get an available mover from pool or create new
function Mover:GetMover()
    for _, mover in ipairs(self.moverPool) do
        if not mover.inUse then
            mover.inUse = true
            return mover
        end
    end

    -- Create new mover
    local mover = self:CreateMover(self.nextId)
    self.nextId = self.nextId + 1
    mover.inUse = true
    table.insert(self.moverPool, mover)

    return mover
end

-- Release a mover back to pool
function Mover:ReleaseMover(mover)
    local frameName = mover.frameName

    mover:Hide()
    mover:ClearAllPoints()
    mover.targetFrame = nil
    mover.frameName = nil
    mover.isDragging = false
    mover.inUse = false
    mover.originalPoints = nil

    if frameName then
        self.movers[frameName] = nil
    end
end

-- Attach mover to a frame
function Mover:AttachToFrame(frame)
    if type(frame) == "string" then
        frame = _G[frame]
    end
    if not frame then return end

    local frameName = frame:GetName()
    if not frameName then
        GridLock.Utils.Debug("Cannot attach mover to unnamed frame")
        return
    end

    -- Enable frame mobility
    if frame.SetMovable then
        frame:SetMovable(true)
    end
    if frame.SetUserPlaced then
        frame:SetUserPlaced(true)
    end

    -- Check if already has a mover
    if self.movers[frameName] then
        return self.movers[frameName]
    end

    -- Check combat protection
    if GridLock.Utils.IsProtectedInCombat(frame) then
        GridLock.Utils.Print(GRIDLOCK.POSITION_LOCKED, frameName)
        return
    end

    -- Disable Blizzard managed positioning for this frame
    local Position = GridLock:GetModule("Position")
    if Position then
        Position:DisableManagedPosition(frameName)
        Position:SaveOriginalPosition(frameName, frame)
    end

    local mover = self:GetMover()
    mover.targetFrame = frame
    mover.frameName = frameName

    -- Position mover over target frame
    self:UpdateMoverPosition(mover)

    -- Update label
    local displayName = frameName
    local frameInfo = GridLock.FrameData and GridLock.FrameData:GetFrameInfo(frameName)
    if frameInfo then
        displayName = frameInfo.displayName
    end
    mover.label:SetText(displayName)

    mover:Show()
    self.movers[frameName] = mover

    GridLock.Utils.Print(GRIDLOCK.MOVER_ATTACHED, displayName)

    return mover
end

-- Update mover position to match target frame
function Mover:UpdateMoverPosition(mover)
    local frame = mover.targetFrame
    if not frame then return end

    local scale = (frame.GetEffectiveScale and frame:GetEffectiveScale()) or 1.0
    local moverScale = mover:GetEffectiveScale() or 1.0

    local rawW = frame.GetWidth and frame:GetWidth() or 0
    local rawH = frame.GetHeight and frame:GetHeight() or 0

    if rawW <= 0 then rawW = 120 end
    if rawH <= 0 then rawH = 30 end

    local width = math.max(rawW * scale, 40)
    local height = math.max(rawH * scale, 20)

    local x, y = GridLock.Utils.GetFrameCenter(frame)
    if not x or not y then return end

    mover:SetWidth(width / moverScale)
    mover:SetHeight(height / moverScale)
    mover:ClearAllPoints()
    mover:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / moverScale, y / moverScale)
    if mover.toolbar then
        mover.toolbar:SetFrameLevel(mover:GetFrameLevel() + 10)
    end
end

-- Detach mover from frame
function Mover:DetachFromFrame(frameName)
    local mover = self.movers[frameName]
    if not mover then return end

    local displayName = frameName
    local frameInfo = GridLock.FrameData and GridLock.FrameData:GetFrameInfo(frameName)
    if frameInfo then
        displayName = frameInfo.displayName
    end

    self:ReleaseMover(mover)
    self.movers[frameName] = nil

    GridLock.Utils.Print(GRIDLOCK.MOVER_DETACHED, displayName)
end

-- Detach all movers
function Mover:DetachAll()
    for frameName, _ in pairs(self.movers) do
        self:DetachFromFrame(frameName)
    end
end

-- Get mover for frame
function Mover:GetMoverForFrame(frameName)
    return self.movers[frameName]
end

-- Drag start handler
function Mover:OnDragStart(mover)
    mover.isDragging = true

    -- Store cursor start position and mover center offset
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    cursorX = cursorX / uiScale
    cursorY = cursorY / uiScale

    local moverX, moverY = mover:GetCenter()
    if moverX and moverY then
        local moverScale = mover:GetEffectiveScale()
        moverX = (moverX * moverScale) / uiScale
        moverY = (moverY * moverScale) / uiScale
        mover.dragOffsetX = moverX - cursorX
        mover.dragOffsetY = moverY - cursorY
    else
        mover.dragOffsetX = 0
        mover.dragOffsetY = 0
    end

    -- Reset sticky snap state
    local Snap = GridLock:GetModule("Snap")
    if Snap then
        Snap:ResetStickyState()
    end

    -- Set OnUpdate script to update position while dragging
    mover:SetScript("OnUpdate", function(self)
        if self.isDragging then
            Mover:OnDragUpdate(self)
        end
    end)
end

-- Drag update handler (called every frame during drag)
function Mover:OnDragUpdate(mover)
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    cursorX = cursorX / uiScale
    cursorY = cursorY / uiScale

    local rawX = cursorX + (mover.dragOffsetX or 0)
    local rawY = cursorY + (mover.dragOffsetY or 0)

    -- Multiply by uiScale to get absolute screen coordinates for Snap
    local screenX = rawX * uiScale
    local screenY = rawY * uiScale

    local moverScale = mover:GetEffectiveScale()
    local finalX, finalY = screenX, screenY

    local Snap = GridLock:GetModule("Snap")
    if Snap and GridLock.db and GridLock.db.snapEnabled and not IsControlKeyDown() then
        local target = mover.targetFrame or mover
        finalX, finalY = Snap:ApplySnapToFrame(target, screenX, screenY)
    else
        if Snap then
            Snap:ClearGuideLines()
        end
    end

    mover:ClearAllPoints()
    mover:SetPoint("CENTER", UIParent, "BOTTOMLEFT", finalX / moverScale, finalY / moverScale)

    Mover:UpdateTooltip(mover)

    -- Sync active Inspector if open
    local Dashboard = GridLock:GetModule("Dashboard")
    if Dashboard and Dashboard.frame and Dashboard.frame:IsShown() and Dashboard.currentFrameName == mover.frameName then
        Dashboard:UpdateInspector()
    end
end

-- Drag stop handler
function Mover:OnDragStop(mover)
    mover.isDragging = false
    mover:SetScript("OnUpdate", nil)

    local Snap = GridLock:GetModule("Snap")
    if Snap then
        Snap:ClearGuideLines()
        Snap:ResetStickyState()
    end

    local frame = mover.targetFrame
    if not frame then return end

    -- Get mover center position
    local x, y = mover:GetCenter()
    if not x or not y then return end

    local moverScale = mover:GetEffectiveScale()
    x = x * moverScale
    y = y * moverScale

    -- Apply snap if enabled (and Ctrl not held)
    local Snap = GridLock:GetModule("Snap")
    if Snap and GridLock.db and GridLock.db.snapEnabled and not IsControlKeyDown() then
        x, y = Snap:ApplySnapToFrame(frame, x, y)
        Snap:HideGuides()
    end

    -- Calculate frame position
    local frameScale = frame:GetEffectiveScale()
    local frameX = x / frameScale
    local frameY = y / frameScale

    -- Get Position module to save FIRST (this also sets up hooks)
    local Position = GridLock:GetModule("Position")

    -- Temporarily unhook to allow our SetPoint to work
    if Position then
        Position.hookedFrames[mover.frameName] = nil
    end

    -- Use ORIGINAL methods if available (bypass our hooks)
    local clearFunc = frame.GridLockOriginalClearAllPoints or frame.ClearAllPoints
    local setFunc = frame.GridLockOriginalSetPoint or frame.SetPoint

    -- Apply position to frame
    clearFunc(frame)
    setFunc(frame, "CENTER", UIParent, "BOTTOMLEFT", frameX, frameY)

    -- Update mover position & tooltip
    self:UpdateMoverPosition(mover)
    self:UpdateTooltip(mover)

    -- Now save position (this will re-enable hooks)
    if Position then
        Position:SavePosition(mover.frameName, frame)
    end
end

-- Toggle mover for frame
function Mover:Toggle(frameName)
    if self.movers[frameName] then
        self:DetachFromFrame(frameName)
    else
        local frame = _G[frameName]
        if frame then
            self:AttachToFrame(frame)
        end
    end
end

-- Nudge a frame by deltaX, deltaY pixels (unaffected by grid snapping)
function Mover:NudgeFrame(frameName, deltaX, deltaY)
    local frame = _G[frameName]
    if not frame then return end

    if GridLock.Utils.IsProtectedInCombat(frame) then
        GridLock.Utils.Print(GRIDLOCK.FRAME_PROTECTED)
        return
    end

    local x, y = GridLock.Utils.GetFrameCenter(frame)
    if not x or not y then return end

    local newX = x + (deltaX or 0)
    local newY = y + (deltaY or 0)

    local frameScale = frame:GetEffectiveScale()
    local targetX = newX / frameScale
    local targetY = newY / frameScale

    local Position = GridLock:GetModule("Position")
    if Position then
        Position.hookedFrames[frameName] = nil
    end

    local clearFunc = frame.GridLockOriginalClearAllPoints or frame.ClearAllPoints
    local setFunc = frame.GridLockOriginalSetPoint or frame.SetPoint

    clearFunc(frame)
    setFunc(frame, "CENTER", UIParent, "BOTTOMLEFT", targetX, targetY)

    local mover = self.movers[frameName]
    if mover then
        self:UpdateMoverPosition(mover)
        self:UpdateTooltip(mover)
    end

    if Position then
        Position:SavePosition(frameName, frame)
    end
end

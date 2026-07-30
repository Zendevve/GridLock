-- GridLock Snap Module
-- PRIMARY FEATURE: Intelligent snap-to-grid & frame-to-frame magnetic docking

local GridLock = select(2, ...)

local Snap = {}
GridLock:RegisterModule("Snap", Snap)

-- Dynamic line texture pool & guide overlay
Snap.guideFrame = nil
Snap.guidePool = {}
Snap.stickyState = {}

function Snap:OnInitialize()
    self:CreateGuides()
    self:CreateGuideOverlayFrame()
end

-- Create legacy visual snap guides frame (backward compatibility)
function Snap:CreateGuides()
    local guides = CreateFrame("Frame", "GridLockSnapGuides", UIParent)
    guides:SetAllPoints(UIParent)
    guides:SetFrameStrata("TOOLTIP")
    guides:Hide()

    -- Vertical guide line
    guides.vLine = guides:CreateTexture(nil, "OVERLAY")
    guides.vLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    guides.vLine:SetVertexColor(0, 1, 0, 0.8)
    guides.vLine:SetWidth(2)
    guides.vLine:Hide()

    -- Horizontal guide line
    guides.hLine = guides:CreateTexture(nil, "OVERLAY")
    guides.hLine:SetTexture("Interface\\Buttons\\WHITE8X8")
    guides.hLine:SetVertexColor(0, 1, 0, 0.8)
    guides.hLine:SetHeight(2)
    guides.hLine:Hide()

    -- Center crosshair indicator
    guides.centerV = guides:CreateTexture(nil, "OVERLAY")
    guides.centerV:SetTexture("Interface\\Buttons\\WHITE8X8")
    guides.centerV:SetVertexColor(1, 0.5, 0, 0.8)
    guides.centerV:SetWidth(2)
    guides.centerV:SetHeight(20)
    guides.centerV:Hide()

    guides.centerH = guides:CreateTexture(nil, "OVERLAY")
    guides.centerH:SetTexture("Interface\\Buttons\\WHITE8X8")
    guides.centerH:SetVertexColor(1, 0.5, 0, 0.8)
    guides.centerH:SetWidth(20)
    guides.centerH:SetHeight(2)
    guides.centerH:Hide()

    self.guides = guides
end

-- Create guide overlay frame for dynamic line pool (FULLSCREEN_DIALOG strata)
function Snap:CreateGuideOverlayFrame()
    if not self.guideFrame then
        local f = CreateFrame("Frame", "GridLockSnapGuideOverlay", UIParent)
        f:SetAllPoints(UIParent)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetFrameLevel(2000)
        f:Hide()
        self.guideFrame = f
    end
    return self.guideFrame
end

-- Get a line texture from pool or create new
function Snap:GetGuideLineTexture()
    local f = self:CreateGuideOverlayFrame()
    for _, tex in ipairs(self.guidePool) do
        if not tex.inUse then
            tex.inUse = true
            return tex
        end
    end
    local tex = f:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\Buttons\\WHITE8X8")
    tex.inUse = true
    table.insert(self.guidePool, tex)
    return tex
end

-- Clear all rendered guide lines
function Snap:ClearGuideLines()
    for _, tex in ipairs(self.guidePool or {}) do
        tex.inUse = false
        tex:Hide()
        tex:ClearAllPoints()
    end
    if self.guideFrame then
        self.guideFrame:Hide()
    end
end

-- Reset sticky snapping hysteresis state
function Snap:ResetStickyState()
    self.stickyState = {
        activeX = false,
        snapX = nil,
        lineXInfo = nil,

        activeY = false,
        snapY = nil,
        lineYInfo = nil,

        draggedFrame = nil,
    }
end

-- Calculate snapped grid position
function Snap:CalculateSnappedPosition(x, y, gridSize)
    gridSize = gridSize or (GridLock.db and GridLock.db.gridSize) or 32

    local snappedX = GridLock.Utils.SnapToGrid(x, gridSize)
    local snappedY = GridLock.Utils.SnapToGrid(y, gridSize)

    return snappedX, snappedY
end

-- Get nearest grid point with distance info
function Snap:GetNearestGridPoint(x, y, gridSize)
    gridSize = gridSize or (GridLock.db and GridLock.db.gridSize) or 32

    local snappedX, snappedY = self:CalculateSnappedPosition(x, y, gridSize)
    local distX = math.abs(x - snappedX)
    local distY = math.abs(y - snappedY)
    local dist = GridLock.Utils.GetDistance(x, y, snappedX, snappedY)

    return snappedX, snappedY, dist, distX, distY
end

-- Check if position should snap to screen center
function Snap:CheckCenterSnap(x, y, threshold)
    threshold = threshold or (GridLock.db and GridLock.db.snapThreshold) or 10

    local screenW, screenH = GridLock.Utils.GetScreenSize()
    local centerX, centerY = screenW / 2, screenH / 2

    local snapX, snapY = nil, nil

    if math.abs(x - centerX) <= threshold then
        snapX = centerX
    end

    if math.abs(y - centerY) <= threshold then
        snapY = centerY
    end

    return snapX, snapY
end

-- Check if position should snap to screen edges
function Snap:CheckEdgeSnap(x, y, width, height, threshold)
    threshold = threshold or (GridLock.db and GridLock.db.snapThreshold) or 10

    local screenW, screenH = GridLock.Utils.GetScreenSize()
    local halfW, halfH = (width or 0) / 2, (height or 0) / 2

    local snapX, snapY = nil, nil

    -- Left edge
    if math.abs(x - halfW) <= threshold then
        snapX = halfW
    end
    -- Right edge
    if math.abs(x - (screenW - halfW)) <= threshold then
        snapX = screenW - halfW
    end
    -- Top edge
    if math.abs(y - (screenH - halfH)) <= threshold then
        snapY = screenH - halfH
    end
    -- Bottom edge
    if math.abs(y - halfH) <= threshold then
        snapY = halfH
    end

    return snapX, snapY
end

-- Collect all candidate target frames for magnetic docking
function Snap:GetCandidateTargetFrames(draggedFrame)
    local candidates = {}
    local seenFrames = {}

    local function addCandidate(frame)
        if not frame or seenFrames[frame] then return end
        seenFrames[frame] = true

        -- Ignore self and direct relationships
        if frame == draggedFrame then return end
        if draggedFrame.targetFrame and frame == draggedFrame.targetFrame then return end
        if frame.targetFrame and frame.targetFrame == draggedFrame then return end
        if frame.targetFrame and draggedFrame.targetFrame and frame.targetFrame == draggedFrame.targetFrame then return end

        if not frame.IsShown or not frame:IsShown() then return end

        local scale = (frame.GetEffectiveScale and frame:GetEffectiveScale()) or 1.0
        local w = (frame.GetWidth and frame:GetWidth() or 0) * scale
        local h = (frame.GetHeight and frame:GetHeight() or 0) * scale
        if w <= 0 or h <= 0 then return end

        local left, bottom
        if frame.GetLeft and frame.GetBottom then
            left = frame:GetLeft()
            bottom = frame:GetBottom()
        end

        if left and bottom then
            left = left * scale
            bottom = bottom * scale
        else
            local cx, cy = GridLock.Utils.GetFrameCenter(frame)
            if not cx or not cy then return end
            left = cx - w / 2
            bottom = cy - h / 2
        end

        local right = left + w
        local top = bottom + h
        local cx = (left + right) / 2
        local cy = (bottom + top) / 2

        table.insert(candidates, {
            frame = frame,
            left = left,
            right = right,
            top = top,
            bottom = bottom,
            cx = cx,
            cy = cy,
            width = w,
            height = h,
        })
    end

    -- 1. Active movers
    local Mover = GridLock:GetModule("Mover")
    if Mover and Mover.movers then
        for _, mover in pairs(Mover.movers) do
            if mover.targetFrame then
                addCandidate(mover.targetFrame)
            else
                addCandidate(mover)
            end
        end
    end

    -- 2. Registered frames in FrameData
    if GridLock.FrameData and GridLock.FrameData.frames then
        for cat, frameList in pairs(GridLock.FrameData.frames) do
            for _, info in ipairs(frameList) do
                local gFrame = _G[info.name]
                if gFrame then
                    addCandidate(gFrame)
                end
            end
        end
    end

    return candidates
end

-- Calculate Frame-to-Frame Magnetic Docking & Alignment with Sticky Snapping (Hysteresis)
function Snap:GetFrameToFrameSnap(draggedFrame, rawX, rawY)
    if not draggedFrame then
        return rawX, rawY, false, {}
    end

    local snapThreshold = (GridLock.db and GridLock.db.snapThreshold) or 10
    local releaseThreshold = (GridLock.db and GridLock.db.snapReleaseThreshold) or 16

    local scale = (draggedFrame.GetEffectiveScale and draggedFrame:GetEffectiveScale()) or 1.0
    local dragW = (draggedFrame.GetWidth and draggedFrame:GetWidth() or 0) * scale
    local dragH = (draggedFrame.GetHeight and draggedFrame:GetHeight() or 0) * scale

    local dragLeft = rawX - dragW / 2
    local dragRight = rawX + dragW / 2
    local dragTop = rawY + dragH / 2
    local dragBottom = rawY - dragH / 2

    if not self.stickyState or self.stickyState.draggedFrame ~= draggedFrame then
        self:ResetStickyState()
        self.stickyState.draggedFrame = draggedFrame
    end
    local state = self.stickyState

    local candidates = self:GetCandidateTargetFrames(draggedFrame)

    local finalX, finalY = rawX, rawY
    local snappedX, snappedY = false, false
    local activeSnaps = {}

    -- --- X AXIS HYSTERESIS & CANDIDATES ---
    if state.activeX then
        local delta = math.abs(rawX - state.snapX)
        if delta < releaseThreshold then
            finalX = state.snapX
            snappedX = true
            if state.lineXInfo then
                table.insert(activeSnaps, state.lineXInfo)
            end
        else
            state.activeX = false
            state.snapX = nil
            state.lineXInfo = nil
        end
    end

    if not state.activeX then
        local bestDelta = snapThreshold + 1
        local bestSnapX = nil
        local bestLineInfo = nil

        for _, cand in ipairs(candidates) do
            -- 1. LEFT-to-RIGHT: Right of dragged docks to Left of target
            local d1 = math.abs(dragRight - cand.left)
            if d1 <= snapThreshold and d1 < bestDelta then
                bestDelta = d1
                bestSnapX = cand.left - dragW / 2
                local lineX = cand.left
                local yMin = math.min(dragBottom, cand.bottom) - 10
                local yMax = math.max(dragTop, cand.top) + 10
                bestLineInfo = { lineType = "vertical", x = lineX, yMin = yMin, yMax = yMax, colorType = "edge" }
            end

            -- 2. RIGHT-to-LEFT: Left of dragged docks to Right of target
            local d2 = math.abs(dragLeft - cand.right)
            if d2 <= snapThreshold and d2 < bestDelta then
                bestDelta = d2
                bestSnapX = cand.right + dragW / 2
                local lineX = cand.right
                local yMin = math.min(dragBottom, cand.bottom) - 10
                local yMax = math.max(dragTop, cand.top) + 10
                bestLineInfo = { lineType = "vertical", x = lineX, yMin = yMin, yMax = yMax, colorType = "edge" }
            end

            -- 3. Flush LEFT-to-LEFT: Left of dragged aligns with Left of target
            local d3 = math.abs(dragLeft - cand.left)
            if d3 <= snapThreshold and d3 < bestDelta then
                bestDelta = d3
                bestSnapX = cand.left + dragW / 2
                local lineX = cand.left
                local yMin = math.min(dragBottom, cand.bottom) - 10
                local yMax = math.max(dragTop, cand.top) + 10
                bestLineInfo = { lineType = "vertical", x = lineX, yMin = yMin, yMax = yMax, colorType = "edge" }
            end

            -- 4. Flush RIGHT-to-RIGHT: Right of dragged aligns with Right of target
            local d4 = math.abs(dragRight - cand.right)
            if d4 <= snapThreshold and d4 < bestDelta then
                bestDelta = d4
                bestSnapX = cand.right - dragW / 2
                local lineX = cand.right
                local yMin = math.min(dragBottom, cand.bottom) - 10
                local yMax = math.max(dragTop, cand.top) + 10
                bestLineInfo = { lineType = "vertical", x = lineX, yMin = yMin, yMax = yMax, colorType = "edge" }
            end

            -- 5. Center Horizontal Alignment: CX_d = CX_o
            local d5 = math.abs(rawX - cand.cx)
            if d5 <= snapThreshold and d5 < bestDelta then
                bestDelta = d5
                bestSnapX = cand.cx
                local lineX = cand.cx
                local yMin = math.min(dragBottom, cand.bottom) - 10
                local yMax = math.max(dragTop, cand.top) + 10
                bestLineInfo = { lineType = "vertical", x = lineX, yMin = yMin, yMax = yMax, colorType = "center" }
            end
        end

        if bestSnapX then
            finalX = bestSnapX
            snappedX = true
            state.activeX = true
            state.snapX = bestSnapX
            state.lineXInfo = bestLineInfo
            table.insert(activeSnaps, bestLineInfo)
        end
    end

    -- --- Y AXIS HYSTERESIS & CANDIDATES ---
    if state.activeY then
        local delta = math.abs(rawY - state.snapY)
        if delta < releaseThreshold then
            finalY = state.snapY
            snappedY = true
            if state.lineYInfo then
                table.insert(activeSnaps, state.lineYInfo)
            end
        else
            state.activeY = false
            state.snapY = nil
            state.lineYInfo = nil
        end
    end

    if not state.activeY then
        local bestDelta = snapThreshold + 1
        local bestSnapY = nil
        local bestLineInfo = nil

        for _, cand in ipairs(candidates) do
            -- 1. TOP-to-BOTTOM: Bottom of dragged docks to Top of target
            local d1 = math.abs(dragBottom - cand.top)
            if d1 <= snapThreshold and d1 < bestDelta then
                bestDelta = d1
                bestSnapY = cand.top + dragH / 2
                local lineY = cand.top
                local xMin = math.min(dragLeft, cand.left) - 10
                local xMax = math.max(dragRight, cand.right) + 10
                bestLineInfo = { lineType = "horizontal", y = lineY, xMin = xMin, xMax = xMax, colorType = "edge" }
            end

            -- 2. BOTTOM-to-TOP: Top of dragged docks to Bottom of target
            local d2 = math.abs(dragTop - cand.bottom)
            if d2 <= snapThreshold and d2 < bestDelta then
                bestDelta = d2
                bestSnapY = cand.bottom - dragH / 2
                local lineY = cand.bottom
                local xMin = math.min(dragLeft, cand.left) - 10
                local xMax = math.max(dragRight, cand.right) + 10
                bestLineInfo = { lineType = "horizontal", y = lineY, xMin = xMin, xMax = xMax, colorType = "edge" }
            end

            -- 3. Flush TOP-to-TOP: Top of dragged aligns with Top of target
            local d3 = math.abs(dragTop - cand.top)
            if d3 <= snapThreshold and d3 < bestDelta then
                bestDelta = d3
                bestSnapY = cand.top - dragH / 2
                local lineY = cand.top
                local xMin = math.min(dragLeft, cand.left) - 10
                local xMax = math.max(dragRight, cand.right) + 10
                bestLineInfo = { lineType = "horizontal", y = lineY, xMin = xMin, xMax = xMax, colorType = "edge" }
            end

            -- 4. Flush BOTTOM-to-BOTTOM: Bottom of dragged aligns with Bottom of target
            local d4 = math.abs(dragBottom - cand.bottom)
            if d4 <= snapThreshold and d4 < bestDelta then
                bestDelta = d4
                bestSnapY = cand.bottom + dragH / 2
                local lineY = cand.bottom
                local xMin = math.min(dragLeft, cand.left) - 10
                local xMax = math.max(dragRight, cand.right) + 10
                bestLineInfo = { lineType = "horizontal", y = lineY, xMin = xMin, xMax = xMax, colorType = "edge" }
            end

            -- 5. Center Vertical Alignment: CY_d = CY_o
            local d5 = math.abs(rawY - cand.cy)
            if d5 <= snapThreshold and d5 < bestDelta then
                bestDelta = d5
                bestSnapY = cand.cy
                local lineY = cand.cy
                local xMin = math.min(dragLeft, cand.left) - 10
                local xMax = math.max(dragRight, cand.right) + 10
                bestLineInfo = { lineType = "horizontal", y = lineY, xMin = xMin, xMax = xMax, colorType = "center" }
            end
        end

        if bestSnapY then
            finalY = bestSnapY
            snappedY = true
            state.activeY = true
            state.snapY = bestSnapY
            state.lineYInfo = bestLineInfo
            table.insert(activeSnaps, bestLineInfo)
        end
    end

    return finalX, finalY, (snappedX or snappedY), activeSnaps
end

-- Render active visual guide lines overlay
function Snap:RenderFrameGuideLines(activeSnaps)
    self:ClearGuideLines()
    if not activeSnaps or #activeSnaps == 0 then return end

    local guideFrame = self:CreateGuideOverlayFrame()
    guideFrame:Show()

    for _, snap in ipairs(activeSnaps) do
        local tex = self:GetGuideLineTexture()
        if snap.lineType == "vertical" then
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", snap.x - 1, snap.yMax)
            tex:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", snap.x - 1, snap.yMin)
            tex:SetWidth(2)
            if snap.colorType == "edge" then
                tex:SetVertexColor(0.0, 0.8, 1.0, 0.9) -- Cyan
            elseif snap.colorType == "center" then
                tex:SetVertexColor(1.0, 0.82, 0.0, 0.9) -- Gold
            else
                tex:SetVertexColor(0.0, 1.0, 0.4, 0.8) -- Green
            end
            tex:Show()
        elseif snap.lineType == "horizontal" then
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", snap.xMin, snap.y + 1)
            tex:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", snap.xMax, snap.y + 1)
            tex:SetHeight(2)
            if snap.colorType == "edge" then
                tex:SetVertexColor(0.0, 0.8, 1.0, 0.9) -- Cyan
            elseif snap.colorType == "center" then
                tex:SetVertexColor(1.0, 0.82, 0.0, 0.9) -- Gold
            else
                tex:SetVertexColor(0.0, 1.0, 0.4, 0.8) -- Green
            end
            tex:Show()
        end
    end
end

-- Main snap calculation - combines magnetic docking + center + edge + grid snapping
function Snap:GetSnappedPosition(x, y, frameWidth, frameHeight, frame)
    if not GridLock.db or not GridLock.db.snapEnabled then
        return x, y, false
    end

    local finalX, finalY = x, y
    local snappedX, snappedY = false, false
    local activeSnaps = {}

    -- 1. Magnetic Frame-to-Frame Snap (if frame provided and enabled)
    if frame and GridLock.db.snapToFrames ~= false then
        local ffX, ffY, ffSnapped, ffLines = self:GetFrameToFrameSnap(frame, x, y)
        if math.abs(ffX - x) > 0.001 then
            finalX = ffX
            snappedX = true
        end
        if math.abs(ffY - y) > 0.001 then
            finalY = ffY
            snappedY = true
        end
        for _, line in ipairs(ffLines or {}) do
            table.insert(activeSnaps, line)
        end
    end

    local threshold = (GridLock.db and GridLock.db.snapThreshold) or 10

    -- 2. Screen Center Snap
    if GridLock.db.snapToCenter then
        local centerX, centerY = self:CheckCenterSnap(x, y, threshold * 2)
        if centerX and not snappedX then
            finalX = centerX
            snappedX = true
            local screenW, screenH = GridLock.Utils.GetScreenSize()
            table.insert(activeSnaps, { lineType = "vertical", x = centerX, yMin = 0, yMax = screenH, colorType = "grid" })
        end
        if centerY and not snappedY then
            finalY = centerY
            snappedY = true
            local screenW, screenH = GridLock.Utils.GetScreenSize()
            table.insert(activeSnaps, { lineType = "horizontal", y = centerY, xMin = 0, xMax = screenW, colorType = "grid" })
        end
    end

    -- 3. Screen Edge Snap
    if GridLock.db.snapToEdges then
        local edgeX, edgeY = self:CheckEdgeSnap(x, y, frameWidth, frameHeight, threshold)
        if edgeX and not snappedX then
            finalX = edgeX
            snappedX = true
            local screenW, screenH = GridLock.Utils.GetScreenSize()
            table.insert(activeSnaps, { lineType = "vertical", x = edgeX, yMin = 0, yMax = screenH, colorType = "grid" })
        end
        if edgeY and not snappedY then
            finalY = edgeY
            snappedY = true
            local screenW, screenH = GridLock.Utils.GetScreenSize()
            table.insert(activeSnaps, { lineType = "horizontal", y = edgeY, xMin = 0, xMax = screenW, colorType = "grid" })
        end
    end

    -- 4. Grid Snap (Threshold-gated: only snap if within snapThreshold distance!)
    if not snappedX or not snappedY then
        local gridSize = GridLock.db.gridSize or 32
        local gridX, gridY = self:CalculateSnappedPosition(x, y, gridSize)
        if not snappedX and math.abs(x - gridX) <= threshold then
            finalX = gridX
            snappedX = true
        end
        if not snappedY and math.abs(y - gridY) <= threshold then
            finalY = gridY
            snappedY = true
        end
    end

    -- Render guide lines
    self:RenderFrameGuideLines(activeSnaps)

    return finalX, finalY, (snappedX or snappedY)
end

-- Apply snap to a frame
function Snap:ApplySnapToFrame(frame, x, y)
    if not frame then return x, y, false end

    local scale = (frame.GetEffectiveScale and frame:GetEffectiveScale()) or 1.0
    local width = (frame.GetWidth and frame:GetWidth() or 0) * scale
    local height = (frame.GetHeight and frame:GetHeight() or 0) * scale

    local snappedX, snappedY, didSnap = self:GetSnappedPosition(x, y, width, height, frame)

    return snappedX, snappedY, didSnap
end

-- Show snap guides at position (legacy method for compatibility)
function Snap:ShowGuides(x, y, showVertical, showHorizontal)
    if not self.guides then return end

    local screenW, screenH = GridLock.Utils.GetScreenSize()
    local centerX, centerY = screenW / 2, screenH / 2

    self.guides:Show()

    if showVertical then
        self.guides.vLine:ClearAllPoints()
        self.guides.vLine:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x - 1, screenH)
        self.guides.vLine:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x - 1, 0)
        self.guides.vLine:Show()
    else
        self.guides.vLine:Hide()
    end

    if showHorizontal then
        self.guides.hLine:ClearAllPoints()
        self.guides.hLine:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 0, y + 1)
        self.guides.hLine:SetPoint("TOPRIGHT", UIParent, "BOTTOMRIGHT", 0, y + 1)
        self.guides.hLine:Show()
    else
        self.guides.hLine:Hide()
    end

    local threshold = (GridLock.db and GridLock.db.snapThreshold or 10) * 2
    if math.abs(x - centerX) < threshold then
        self.guides.centerV:ClearAllPoints()
        self.guides.centerV:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, y)
        self.guides.centerV:Show()
    else
        self.guides.centerV:Hide()
    end

    if math.abs(y - centerY) < threshold then
        self.guides.centerH:ClearAllPoints()
        self.guides.centerH:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, centerY)
        self.guides.centerH:Show()
    else
        self.guides.centerH:Hide()
    end
end

-- Hide all guides (clears dynamic guide overlay and legacy guides)
function Snap:HideGuides()
    self:ClearGuideLines()
    if not self.guides then return end

    self.guides:Hide()
    self.guides.vLine:Hide()
    self.guides.hLine:Hide()
    self.guides.centerV:Hide()
    self.guides.centerH:Hide()
end

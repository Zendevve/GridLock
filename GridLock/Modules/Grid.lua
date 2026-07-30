-- GridLock Grid Module
-- Displays a configurable grid overlay for alignment

local GridLock = select(2, ...)

local Grid = {}
GridLock:RegisterModule("Grid", Grid)

-- Grid frame storage
Grid.frame = nil
Grid.shown = false

-- Initialize grid
function Grid:OnInitialize()
    -- Grid is created on demand
end

-- Create grid frame
function Grid:CreateGrid()
    if self.frame then return self.frame end

    local grid = CreateFrame("Frame", "GridLockGrid", UIParent)
    grid:SetAllPoints(UIParent)
    grid:SetFrameStrata("BACKGROUND")
    grid:SetFrameLevel(0)
    grid:Hide()

    -- Store textures for reuse
    grid.lines = {}

    self.frame = grid
    return grid
end

-- Draw grid lines
function Grid:DrawGrid()
    local grid = self.frame
    if not grid then return end

    -- Clear existing lines
    for _, line in ipairs(grid.lines) do
        line:Hide()
    end

    local db = GridLock.db
    local size = db.gridSize
    local color = db.gridColor
    local centerColor = db.gridCenterColor
    local lineWidth = db.gridLineWidth

    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local ratio = screenWidth / screenHeight

    local lineIndex = 0

    -- Calculate number of lines needed
    local numVertical = math.ceil(screenWidth / size) + 1
    local numHorizontal = math.ceil(screenHeight / size) + 1

    local centerX = math.floor(screenWidth / 2)
    local centerY = math.floor(screenHeight / 2)

    -- Draw vertical lines
    for i = 0, numVertical do
        local x = i * size
        lineIndex = lineIndex + 1
        local line = self:GetOrCreateLine(grid, lineIndex)

        local isCenter = math.abs(x - centerX) < size / 2
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        if isCenter then
            line:SetVertexColor(centerColor.r, centerColor.g, centerColor.b, centerColor.a)
        else
            line:SetVertexColor(color.r, color.g, color.b, color.a)
        end

        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", grid, "TOPLEFT", x - lineWidth / 2, 0)
        line:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", x - lineWidth / 2, 0)
        line:SetWidth(lineWidth)
        line:Show()
    end

    -- Draw horizontal lines
    for i = 0, numHorizontal do
        local y = i * size
        lineIndex = lineIndex + 1
        local line = self:GetOrCreateLine(grid, lineIndex)

        local isCenter = math.abs(y - centerY) < size / 2
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        if isCenter then
            line:SetVertexColor(centerColor.r, centerColor.g, centerColor.b, centerColor.a)
        else
            line:SetVertexColor(color.r, color.g, color.b, color.a)
        end

        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", grid, "BOTTOMLEFT", 0, y + lineWidth / 2)
        line:SetPoint("TOPRIGHT", grid, "BOTTOMRIGHT", 0, y + lineWidth / 2)
        line:SetHeight(lineWidth)
        line:Show()
    end

    -- Hide unused lines
    for i = lineIndex + 1, #grid.lines do
        grid.lines[i]:Hide()
    end
end

-- Get or create a line texture
function Grid:GetOrCreateLine(grid, index)
    if not grid.lines[index] then
        local line = grid:CreateTexture(nil, "BACKGROUND")
        grid.lines[index] = line
    end
    return grid.lines[index]
end

-- Show grid
function Grid:Show()
    if not self.frame then
        self:CreateGrid()
    end

    self:DrawGrid()
    self.frame:Show()
    self.shown = true
    GridLock.gridShown = true

    GridLock.Utils.Print(GRIDLOCK.GRID_SHOWN, GridLock.db.gridSize)
end

-- Hide grid
function Grid:Hide()
    if self.frame then
        self.frame:Hide()
    end
    self.shown = false
    GridLock.gridShown = false

    GridLock.Utils.Print(GRIDLOCK.GRID_HIDDEN)
end

-- Toggle grid
function Grid:Toggle()
    if self.shown then
        self:Hide()
    else
        self:Show()
    end
end

-- Update grid (when size changes)
function Grid:Update()
    if self.shown then
        self:DrawGrid()
    end
end

-- Set grid size
function Grid:SetSize(size)
    size = math.min(256, math.max(8, size))
    GridLock.db.gridSize = size
    self:Update()
end

-- Cycle grid size (8 -> 16 -> 32 -> 64 -> 8)
function Grid:CycleSize()
    local current = GridLock.db and GridLock.db.gridSize or 32
    local nextSize = 32
    if current == 8 then
        nextSize = 16
    elseif current == 16 then
        nextSize = 32
    elseif current == 32 then
        nextSize = 64
    else
        nextSize = 8
    end
    self:SetSize(nextSize)
    return nextSize
end


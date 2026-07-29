-- ZenAlign Configuration and SavedVariables

local ZenAlign = select(2, ...)

-- Default configuration
local defaults = {
    -- Grid settings
    gridSize = 32,
    gridColor = { r = 0.5, g = 0.5, b = 0.5, a = 0.5 },
    gridCenterColor = { r = 1, g = 0, b = 0, a = 0.5 },
    gridLineWidth = 2,

    -- Snap settings
    snapEnabled = true,
    snapThreshold = 10,  -- Pixels to trigger snap
    snapReleaseThreshold = 16, -- Pixels to break snap lock
    snapToEdges = true,
    snapToCenter = true,
    snapToFrames = true,

    -- Mover settings
    moverColor = { r = 0, g = 1, b = 0.6, a = 0.8 },
    showMoverTooltip = true,

    -- General
    showMinimapButton = true,
    closeOnEscape = true,
    debug = false,

    -- Frame positions and visibility (populated at runtime)
    frames = {},
    hiddenFrames = {},
}

local charDefaults = {
    -- Per-character overrides (if needed)
    profile = "default",
}

-- Initialize configuration
function ZenAlign:InitConfig()
    -- Global SavedVariables
    if not ZenAlignDB then
        ZenAlignDB = {}
    end

    -- Per-character SavedVariables
    if not ZenAlignCharDB then
        ZenAlignCharDB = {}
    end

    -- Apply defaults
    self:ApplyDefaults(ZenAlignDB, defaults)
    self:ApplyDefaults(ZenAlignCharDB, charDefaults)

    -- Store reference
    self.db = ZenAlignDB
    self.charDb = ZenAlignCharDB
end

-- Apply default values to saved variables
function ZenAlign:ApplyDefaults(sv, defs)
    for k, v in pairs(defs) do
        if sv[k] == nil then
            if type(v) == "table" then
                sv[k] = ZenAlign.Utils.DeepCopy(v)
            else
                sv[k] = v
            end
        elseif type(v) == "table" and type(sv[k]) == "table" then
            self:ApplyDefaults(sv[k], v)
        end
    end
end

-- Get frame position data
function ZenAlign:GetFramePosition(frameName)
    return self.db.frames[frameName]
end

-- Save frame position data
function ZenAlign:SaveFramePosition(frameName, posData)
    self.db.frames[frameName] = posData
end

-- Clear frame position data
function ZenAlign:ClearFramePosition(frameName)
    self.db.frames[frameName] = nil
end

-- Check if frame has saved position
function ZenAlign:HasSavedPosition(frameName)
    return self.db.frames[frameName] ~= nil
end

-- Get all saved frame names
function ZenAlign:GetSavedFrameNames()
    local names = {}
    for name in pairs(self.db.frames) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- Get frame scale
function ZenAlign:GetFrameScale(frameName)
    local pos = self.db.frames[frameName]
    return pos and pos.scale or nil
end

-- Save frame scale
function ZenAlign:SaveFrameScale(frameName, scale)
    if not self.db.frames[frameName] then
        local f = _G[frameName]
        if f then
            local posData = ZenAlign.Utils.SerializePoint(f, 1) or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
            self.db.frames[frameName] = posData
        else
            return
        end
    end
    self.db.frames[frameName].scale = scale
end

-- Get frame alpha
function ZenAlign:GetFrameAlpha(frameName)
    local pos = self.db.frames[frameName]
    return pos and pos.alpha or nil
end

-- Save frame alpha
function ZenAlign:SaveFrameAlpha(frameName, alpha)
    if not self.db.frames[frameName] then
        local f = _G[frameName]
        if f then
            local posData = ZenAlign.Utils.SerializePoint(f, 1) or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
            self.db.frames[frameName] = posData
        else
            return
        end
    end
    self.db.frames[frameName].alpha = alpha
end

-- Reset all positions
function ZenAlign:ResetAllPositions()
    wipe(self.db.frames)
end

-- Export configuration to string
function ZenAlign:ExportConfig()
    -- Simple serialization for now
    local data = {}
    for name, pos in pairs(self.db.frames) do
        table.insert(data, string.format("%s:%s:%s:%s:%.2f:%.2f:%.2f:%.2f",
            name,
            pos.point,
            pos.relativeTo,
            pos.relativePoint,
            pos.x,
            pos.y,
            pos.scale or 1.0,
            pos.alpha or 1.0
        ))
    end
    return table.concat(data, "|")
end

-- Import configuration from string
function ZenAlign:ImportConfig(str)
    local parts = { strsplit("|", str) }
    for _, part in ipairs(parts) do
        local name, point, relTo, relPoint, x, y, scale, alpha = strsplit(":", part)
        if name and point then
            self.db.frames[name] = {
                point = point,
                relativeTo = relTo,
                relativePoint = relPoint,
                x = tonumber(x) or 0,
                y = tonumber(y) or 0,
                scale = tonumber(scale),
                alpha = tonumber(alpha),
            }
        end
    end
end


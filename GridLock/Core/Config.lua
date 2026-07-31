-- GridLock Configuration and SavedVariables

local addonName, GridLock = ...
GridLock = GridLock or _G.GridLock or {}
_G.GridLock = GridLock

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
function GridLock:InitConfig()
    -- Global SavedVariables
    if not GridLockDB then
        GridLockDB = {}
    end

    -- Per-character SavedVariables
    if not GridLockCharDB then
        GridLockCharDB = {}
    end

    -- Apply defaults
    self:ApplyDefaults(GridLockDB, defaults)
    self:ApplyDefaults(GridLockCharDB, charDefaults)

    -- Store reference
    self.db = GridLockDB
    self.charDb = GridLockCharDB
end

-- Apply default values to saved variables
function GridLock:ApplyDefaults(sv, defs)
    for k, v in pairs(defs) do
        if sv[k] == nil then
            if type(v) == "table" then
                sv[k] = GridLock.Utils.DeepCopy(v)
            else
                sv[k] = v
            end
        elseif type(v) == "table" and type(sv[k]) == "table" then
            self:ApplyDefaults(sv[k], v)
        end
    end
end

-- Get frame position data
function GridLock:GetFramePosition(frameName)
    self.db = self.db or { frames = {}, hiddenFrames = {} }
    return self.db.frames and self.db.frames[frameName]
end

-- Save frame position data
function GridLock:SaveFramePosition(frameName, posData)
    self.db.frames[frameName] = posData
end

-- Clear frame position data
function GridLock:ClearFramePosition(frameName)
    self.db.frames[frameName] = nil
end

-- Check if frame has saved position
function GridLock:HasSavedPosition(frameName)
    return self.db.frames[frameName] ~= nil
end

-- Get all saved frame names
function GridLock:GetSavedFrameNames()
    local names = {}
    for name in pairs(self.db.frames) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- Get frame scale
function GridLock:GetFrameScale(frameName)
    local pos = self.db.frames[frameName]
    return pos and pos.scale or nil
end

-- Save frame scale
function GridLock:SaveFrameScale(frameName, scale)
    if not self.db.frames[frameName] then
        local f = _G[frameName]
        if f then
            local posData = GridLock.Utils.SerializePoint(f, 1) or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
            self.db.frames[frameName] = posData
        else
            return
        end
    end
    self.db.frames[frameName].scale = scale
end

-- Get frame alpha
function GridLock:GetFrameAlpha(frameName)
    local pos = self.db.frames[frameName]
    return pos and pos.alpha or nil
end

-- Save frame alpha
function GridLock:SaveFrameAlpha(frameName, alpha)
    if not self.db.frames[frameName] then
        local f = _G[frameName]
        if f then
            local posData = GridLock.Utils.SerializePoint(f, 1) or { point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", x = 0, y = 0 }
            self.db.frames[frameName] = posData
        else
            return
        end
    end
    self.db.frames[frameName].alpha = alpha
end

-- Reset all positions
function GridLock:ResetAllPositions()
    wipe(self.db.frames)
end

-- Export configuration to string (Base64 + Checksum Hash format)
function GridLock:ExportConfig(rawFormat)
    self.db = self.db or { frames = {} }
    local data = {}
    for name, pos in pairs(self.db.frames) do
        table.insert(data, string.format("%s:%s:%s:%s:%.2f:%.2f:%.2f:%.2f",
            name,
            pos.point,
            pos.relativeTo or "UIParent",
            pos.relativePoint,
            pos.x or 0,
            pos.y or 0,
            pos.scale or 1.0,
            pos.alpha or 1.0
        ))
    end
    local rawStr = table.concat(data, "|")
    if rawFormat then
        return rawStr
    end
    local b64 = GridLock.Utils and GridLock.Utils.Base64Encode(rawStr) or rawStr
    local hash = GridLock.Utils and GridLock.Utils.CalculateHash(rawStr) or "00000000"
    return "!GL1:" .. b64 .. ":#" .. hash
end

-- Validate and decode import string
function GridLock:ValidateImportString(str)
    if not str or type(str) ~= "string" or str == "" then
        return false, nil, "Empty import string"
    end
    str = str:gsub("^%s+", ""):gsub("%s+$", "")

    if str:find("^!GL1:") then
        local b64, hash = str:match("^!GL1:(.-):#(.-)$")
        if not b64 then
            return false, nil, "Malformed export string header"
        end
        local rawStr = GridLock.Utils and GridLock.Utils.Base64Decode(b64) or b64
        local calcHash = GridLock.Utils and GridLock.Utils.CalculateHash(rawStr) or "00000000"
        if hash and hash ~= "" and calcHash ~= hash then
            return false, nil, "Checksum validation failed"
        end
        return true, rawStr, nil
    end

    -- Legacy raw pipe format
    if str:find(":") or str:find("|") then
        return true, str, nil
    end

    return false, nil, "Invalid format"
end

-- Import configuration from string
function GridLock:ImportConfig(str)
    local ok, rawStr, err = self:ValidateImportString(str)
    if not ok or not rawStr then
        if GridLock.Utils then GridLock.Utils.Print("Import failed: %s", err or "Invalid format") end
        return false, err
    end

    self.db = self.db or { frames = {} }
    self.db.frames = self.db.frames or {}

    local parts = { strsplit("|", rawStr) }
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

    -- Apply imported frame positions
    local Position = GridLock:GetModule("Position")
    if Position and Position.ApplyAllSavedPositions then
        Position:ApplyAllSavedPositions()
    end
    return true
end



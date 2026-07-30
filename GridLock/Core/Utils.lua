-- GridLock Utility Functions

local addonName, GridLock = ...
GridLock = GridLock or _G.GridLock or {}
_G.GridLock = GridLock

GridLock.Utils = {}
local Utils = GridLock.Utils

-- Table deep copy
function Utils.DeepCopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in pairs(orig) do
            copy[Utils.DeepCopy(k)] = Utils.DeepCopy(v)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Table shallow copy
function Utils.ShallowCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = v
    end
    return copy
end

-- Check if table is empty
function Utils.IsEmpty(t)
    return next(t) == nil
end

-- Snap value to grid
function Utils.SnapToGrid(value, gridSize)
    return math.floor((value + gridSize / 2) / gridSize) * gridSize
end

-- Snap X,Y coordinates to grid
function Utils.SnapPositionToGrid(x, y, gridSize)
    return Utils.SnapToGrid(x, gridSize), Utils.SnapToGrid(y, gridSize)
end

-- Get distance between two points
function Utils.GetDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Get frame's absolute center position
function Utils.GetFrameCenter(frame)
    if not frame or not frame.GetCenter then return nil, nil end
    local x, y = frame:GetCenter()
    if not x or not y then return nil, nil end
    local scale = frame:GetEffectiveScale()
    return x * scale, y * scale
end

-- Get frame's absolute bounds
function Utils.GetFrameBounds(frame)
    if not frame then return nil end
    local left = frame:GetLeft()
    local right = frame:GetRight()
    local top = frame:GetTop()
    local bottom = frame:GetBottom()
    if not (left and right and top and bottom) then return nil end
    local scale = frame:GetEffectiveScale()
    return {
        left = left * scale,
        right = right * scale,
        top = top * scale,
        bottom = bottom * scale,
        width = (right - left) * scale,
        height = (top - bottom) * scale,
    }
end

-- Get screen dimensions
function Utils.GetScreenSize()
    return GetScreenWidth(), GetScreenHeight()
end

-- Clamp value between min and max
function Utils.Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- Round number to decimal places
function Utils.Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Convert anchor point to coordinates offset
function Utils.AnchorToOffset(anchor)
    local xMult, yMult = 0, 0
    if anchor:find("LEFT") then xMult = -0.5
    elseif anchor:find("RIGHT") then xMult = 0.5 end
    if anchor:find("TOP") then yMult = 0.5
    elseif anchor:find("BOTTOM") then yMult = -0.5 end
    return xMult, yMult
end

-- Serialize point data for storage
function Utils.SerializePoint(frame, pointIndex)
    pointIndex = pointIndex or 1
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(pointIndex)
    if not point then return nil end

    local relName = "UIParent"
    if relativeTo and relativeTo.GetName then
        relName = relativeTo:GetName() or "UIParent"
    end

    return {
        point = point,
        relativeTo = relName,
        relativePoint = relativePoint,
        x = Utils.Round(x, 2),
        y = Utils.Round(y, 2),
    }
end

-- Deserialize and apply point data
function Utils.ApplyPoint(frame, pointData)
    if not frame or not pointData then return false end

    local relativeTo = _G[pointData.relativeTo] or UIParent
    frame:ClearAllPoints()
    frame:SetPoint(
        pointData.point,
        relativeTo,
        pointData.relativePoint,
        pointData.x,
        pointData.y
    )
    return true
end

-- Check if frame is a valid movable object
function Utils.IsValidFrame(frame)
    if not frame then return false end
    if type(frame) ~= "table" then return false end
    if not frame.GetObjectType then return false end

    local objType = frame:GetObjectType()
    local validTypes = {
        Frame = true,
        Button = true,
        CheckButton = true,
        StatusBar = true,
        Slider = true,
        EditBox = true,
        ScrollFrame = true,
        MessageFrame = true,
        GameTooltip = true,
        Minimap = true,
        PlayerModel = true,
        ColorSelect = true,
    }

    return validTypes[objType] or false
end

-- Check if frame is protected during combat
function Utils.IsProtectedInCombat(frame)
    if not InCombatLockdown() then return false end
    if not frame or not frame.IsProtected then return false end
    return frame:IsProtected()
end

-- Print message with addon prefix
function Utils.Print(msg, ...)
    if select("#", ...) > 0 then
        msg = string.format(msg, ...)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF99GridLock:|r " .. msg)
end

-- Debug print (only when debug mode enabled)
function Utils.Debug(msg, ...)
    if not GridLock.db or not GridLock.db.debug then return end
    if select("#", ...) > 0 then
        msg = string.format(msg, ...)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900GridLock Debug:|r " .. msg)
end

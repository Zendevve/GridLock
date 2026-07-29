-- ZenAlign Position Data
-- Default positions and position presets for Blizzard UI elements

local ZenAlign = select(2, ...)

ZenAlign.PositionData = {}
local PD = ZenAlign.PositionData

-- Default frame positions for standard Blizzard UI frames
PD.defaultPositions = {
    PlayerFrame = { point = "TOPLEFT", relativeTo = "UIParent", relativePoint = "TOPLEFT", x = 10, y = -12, scale = 1.0, alpha = 1.0 },
    TargetFrame = { point = "TOPLEFT", relativeTo = "UIParent", relativePoint = "TOPLEFT", x = 250, y = -12, scale = 1.0, alpha = 1.0 },
    FocusFrame = { point = "TOPLEFT", relativeTo = "UIParent", relativePoint = "TOPLEFT", x = 250, y = -220, scale = 1.0, alpha = 1.0 },
    MinimapCluster = { point = "TOPRIGHT", relativeTo = "UIParent", relativePoint = "TOPRIGHT", x = 0, y = 0, scale = 1.0, alpha = 1.0 },
    MainMenuBar = { point = "BOTTOM", relativeTo = "UIParent", relativePoint = "BOTTOM", x = 0, y = 0, scale = 1.0, alpha = 1.0 },
    ChatFrame1 = { point = "BOTTOMLEFT", relativeTo = "UIParent", relativePoint = "BOTTOMLEFT", x = 30, y = 40, scale = 1.0, alpha = 1.0 },
    BuffFrame = { point = "TOPRIGHT", relativeTo = "UIParent", relativePoint = "TOPRIGHT", x = -205, y = -13, scale = 1.0, alpha = 1.0 },
    CastingBarFrame = { point = "BOTTOM", relativeTo = "UIParent", relativePoint = "BOTTOM", x = 0, y = 100, scale = 1.0, alpha = 1.0 },
    DurabilityFrame = { point = "TOPRIGHT", relativeTo = "MinimapCluster", relativePoint = "BOTTOMRIGHT", x = 0, y = 15, scale = 1.0, alpha = 1.0 },
}

-- Get default position for a frame
function PD:GetDefaultPosition(frameName)
    return self.defaultPositions[frameName]
end

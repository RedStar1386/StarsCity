HUD = HUD or {}

HUD.version = "1.0"

-- Default size/profile for a new player.
HUD.defaultLayout = "small"
HUD.currentLayout = HUD.defaultLayout

-- Icon/type metadata stays shared between all layouts.
HUD.positionMeta = {
    ping   = { width=200, height=50, icon="ping" },
    clock  = { width=200, height=50, icon="clock" },
    health = { width=200, height=50, icon="health" },
    armor  = { width=200, height=50, icon="armor" },
    money  = { width=200, height=50, icon="money" },
    player = { width=250, height=50 },
    date   = { width=250, height=50, icon="date" },
    wanted = { width=300, height=50 }
}

-- Default positions for each size.
-- SMALL below is copied from your current position.xml.
-- MEDIUM/LARGE are independent starting layouts; arrange them in Edit Position
-- and Save when you are happy with them.
HUD.defaultLayouts = {

    small = {
        ping   = { x=1150, y=5 },
        clock  = { x=1206, y=5 },
        date   = { x=1262, y=5 },
        player = { x=1149, y=31 },
        health = { x=1150, y=67 },
        armor  = { x=1206, y=67 },
        money  = { x=1262, y=67 },
        wanted = { x=1222, y=93 }
    },

    medium = {
        ping   = { x=1138, y=4 },
        clock  = { x=1197, y=4 },
        date   = { x=1258, y=4 },
        player = { x=1138, y=33 },
        health = { x=1138, y=72 },
        armor  = { x=1198, y=72 },
        money  = { x=1258, y=72 },
        wanted = { x=1211, y=101 }
    },

    large = {
        ping   = { x=1132, y=3 },
        clock  = { x=1194, y=3 },
        date   = { x=1257, y=3 },
        player = { x=1133, y=35 },
        health = { x=1132, y=77 },
        armor  = { x=1194, y=77 },
        money  = { x=1257, y=77 },
        wanted = { x=1173, y=109 }
    }
}

local function copyLayout(source)

    local result = {}

    for name,meta in pairs(HUD.positionMeta) do

        local saved = source and source[name] or nil

        result[name] = {
            x = saved and saved.x or 100,
            y = saved and saved.y or 100,
            width = meta.width,
            height = meta.height,
            icon = meta.icon
        }

    end

    return result

end

HUD.copyLayout = copyLayout

-- Runtime layouts. Each size is completely independent.
HUD.layouts = {
    small = copyLayout(HUD.defaultLayouts.small),
    medium = copyLayout(HUD.defaultLayouts.medium),
    large = copyLayout(HUD.defaultLayouts.large)
}

-- Renderer/position editor keep using HUD.positions as before.
HUD.positions = HUD.layouts[HUD.currentLayout]

-- Compatibility for old reset code.
HUD.defaultPositions = copyLayout(HUD.defaultLayouts[HUD.defaultLayout])

function HUD:setLayout(size)

    if size ~= "small" and size ~= "medium" and size ~= "large" then
        return false
    end

    HUD.currentLayout = size
    HUD.positions = HUD.layouts[size]

    return true

end

function HUD:resetLayout(size)

    size = size or HUD.defaultLayout or "small"

    if not HUD.defaultLayouts[size] then
        return false
    end

    HUD.layouts[size] = copyLayout(HUD.defaultLayouts[size])
    HUD.currentLayout = size
    HUD.positions = HUD.layouts[size]

    return true

end

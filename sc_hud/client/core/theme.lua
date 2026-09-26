-- sc_hud/client/core/theme.lua
-- HUD Theme System

HUD = HUD or {}

HUD.theme = {}

------------------------------------------------
-- Background Settings
------------------------------------------------

HUD.theme.background = {

    color = {
        r = 15,
        g = 18,
        b = 25
    },

    opacity = 100 -- Default Small profile opacity

}


------------------------------------------------
-- Rounded Corner Settings
------------------------------------------------

HUD.theme.borderRadius = 4
-- Change this value for softer/sharper corners


------------------------------------------------
-- Icon Color System
------------------------------------------------

HUD.theme.icon = {

    currentColor = "default",

    availableColors = {

        "default",
        "sky",
        "yallow",
        "green",
        "red",
        "pink",
        "purple"

    },

    -- Text colors linked to icon theme.
    -- You can edit these RGB values manually.
    textColors = {
        default = {255, 255, 255},
        sky     = {70, 180, 255},
        yallow  = {255, 220, 70},
        green   = {80, 220, 100},
        red     = {255, 70, 70},
        pink    = {255, 100, 190},
        purple  = {170, 100, 255}
    }

}


------------------------------------------------
-- Font System
------------------------------------------------

HUD.theme.fonts = {

    default = "default",

    font1 = "assets/fonts/font1.ttf",
    font2 = "assets/fonts/font2.ttf",
    font3 = "assets/fonts/font3.ttf",
    font4 = "assets/fonts/font4.ttf"

}

HUD.theme.fontElements = {}
HUD.theme.currentFont = "default"


function HUD.theme:getFont()

    if self.currentFont == "default" then
        return "default"
    end

    if self.fontElements[self.currentFont]
    and isElement(self.fontElements[self.currentFont]) then
        return self.fontElements[self.currentFont]
    end

    local path = self.fonts[self.currentFont]

    if not path then
        return "default"
    end

    local font = dxCreateFont(path, 12, false, "antialiased")

    if not font then
        return "default"
    end

    self.fontElements[self.currentFont] = font

    return font

end


------------------------------------------------
-- Text Size System
------------------------------------------------

HUD.theme.textSize = {

    default = {
        small = 0.80,
        medium = 1.00,
        large = 1.05
    },

    font1 = {
        small = 0.40,
        medium = 0.48,
        large = 0.55
    },

    font2 = {
        small = 0.50,
        medium = 0.60,
        large = 0.70
    },

    font3 = {
        small = 0.50,
        medium = 0.65,
        large = 0.75
    },

    font4 = {
        small = 0.70,
        medium = 0.80,
        large = 0.90
    }

}


HUD.theme.currentTextSize = "small"


------------------------------------------------
-- Icon Size System
-- Each icon can have its own Small / Medium / Large size
------------------------------------------------

HUD.theme.iconSize = {

    ping = {
        small = 15,
        medium = 20,
        large = 25
    },

    clock = {
        small = 15,
        medium = 20,
        large = 25
    },

    health = {
        small = 15,
        medium = 20,
        large = 25
    },

    armor = {
        small = 15,
        medium = 20,
        large = 25
    },

    money = {
        small = 15,
        medium = 23,
        large = 25
    },

    date = {
        small = 15,
        medium = 20,
        large = 25
    },

    wanted = {
        small = 15,
        medium = 20,
        large = 25
    }

}


------------------------------------------------
-- Player Display Settings
-- These values are independent and can be edited manually.
------------------------------------------------

HUD.theme.player = {

    -- Extra multiplier on top of the selected font Small/Medium/Large size.
    textScale = 1.00,

    -- Player box size only.
    width = 250,
    height = 50

}


------------------------------------------------
-- Component Custom Size
------------------------------------------------

HUD.theme.components = {

    -- Each HUD has its own box size for Small / Medium / Large.
    -- The selected Text Size from the panel controls which box size is used.
    --
    -- iconScale / textScale remain optional per-component multipliers.
    -- gap controls the distance between icon and text.

    ping = {
        sizes = {
            small  = { width = 55, height = 25 },
            medium = { width = 58, height = 28 },
            large  = { width = 61, height = 31 }
        },
        iconScale = 1.00,
        textScale = 1.00,
        gap = 2
    },

    clock = {
        sizes = {
            small  = { width = 55, height = 25 },
            medium = { width = 58, height = 28 },
            large  = { width = 61, height = 31 }
        },
        iconScale = 1.00,
        textScale = 1.00,
        gap = 2
    },

    health = {
        sizes = {
            small  = { width = 55, height = 25 },
            medium = { width = 58, height = 28 },
            large  = { width = 61, height = 31 }
        },
        iconScale = 1.00,
        textScale = 1.00,
        gap = 3
    },

    armor = {
        sizes = {
            small  = { width = 55, height = 25 },
            medium = { width = 58, height = 28 },
            large  = { width = 61, height = 31 }
        },
        iconScale = 1.00,
        textScale = 1.00,
        gap = 3
    },

    money = {
        sizes = {
            small  = { width = 100, height = 25 },
            medium = { width = 103, height = 28 },
            large  = { width = 106, height = 31 }
        },
        iconScale = 1.00,
        textScale = 1.00,
        gap = 1
    },

    player = {
        sizes = {
            small  = { width = 212, height = 35 },
            medium = { width = 223, height = 38 },
            large  = { width = 230, height = 41 }
        },
        textScale = 1.25
    },

    date = {
        sizes = {
            small  = { width = 100, height = 25 },
            medium = { width = 103, height = 28 },
            large  = { width = 106, height = 31 }
        },
        iconScale = 1.00,
        textScale = 1.00,
        gap = 1
    },

    wanted = {
        sizes = {
            small  = { width = 140, height = 25 },
            medium = { width = 150, height = 28 },
            large  = { width = 190, height = 31 }
        },
        iconScale = 1.00,
        gap = 5
    }

}


------------------------------------------------
-- Toggle Animation
------------------------------------------------

HUD.theme.animation = {

    enabled = true,

    speed = 0.15

}


------------------------------------------------
-- Helpers
------------------------------------------------

function HUD.theme:getIcon(name)

    if self.icon.currentColor == "default" then
        return "assets/icons/" .. name .. ".png"
    end

    return "assets/icons/" ..
    name ..
    "_" ..
    self.icon.currentColor ..
    ".png"

end


function HUD.theme:getTextScale()

    local fontName = self.currentFont or "default"
    local fontSizes = self.textSize[fontName] or self.textSize.default

    if not fontSizes then
        return 1
    end

    return fontSizes[self.currentTextSize] or fontSizes.medium or 1

end


function HUD.theme:getIconSize(name)

    local sizes = self.iconSize and self.iconSize[name]

    if not sizes then
        return 30
    end

    return sizes[self.currentTextSize] or sizes.medium or 30

end


function HUD.theme:getComponentSize(name, fallbackWidth, fallbackHeight)

    local component = self.components and self.components[name]
    local preset = self.currentTextSize or "medium"

    if not component or not component.sizes then
        return fallbackWidth, fallbackHeight
    end

    local size = component.sizes[preset] or component.sizes.medium

    if not size then
        return fallbackWidth, fallbackHeight
    end

    return size.width or fallbackWidth, size.height or fallbackHeight

end


function HUD.theme:getIconTextColor()

    local colorName = (self.icon and self.icon.currentColor) or "default"
    local colors = self.icon and self.icon.textColors
    local rgb = colors and colors[colorName]

    if not rgb then
        rgb = {255, 255, 255}
    end

    return rgb[1], rgb[2], rgb[3]

end


------------------------------------------------
-- Default Profile Reset
------------------------------------------------

HUD.theme.defaults = {
    textSize = "small",
    iconColor = "default",
    currentFont = "default",
    opacity = 100,
    radius = 4
}

function HUD.theme:resetToDefault()

    self.currentTextSize = self.defaults.textSize
    self.icon.currentColor = self.defaults.iconColor
    self.currentFont = self.defaults.currentFont
    self.background.opacity = self.defaults.opacity
    self.borderRadius = self.defaults.radius

    if HUD.assets then
        HUD.assets.currentColor = self.defaults.iconColor
    end

end


------------------------------------------------
-- Apply saved theme loaded before theme.lua
------------------------------------------------

if HUD.storage and HUD.storage.pendingTheme then

    local saved = HUD.storage.pendingTheme

    if saved.iconColor and saved.iconColor ~= "" then
        HUD.theme.icon.currentColor = saved.iconColor

        if HUD.assets then
            HUD.assets.currentColor = saved.iconColor
        end
    end

    if saved.textSize
    and (saved.textSize == "small"
    or saved.textSize == "medium"
    or saved.textSize == "large") then
        HUD.theme.currentTextSize = saved.textSize
    end

    if saved.currentFont and HUD.theme.fonts[saved.currentFont] then
        HUD.theme.currentFont = saved.currentFont
    end

    if saved.opacity then
        HUD.theme.background.opacity = saved.opacity
    end

    if saved.radius then
        HUD.theme.borderRadius = saved.radius
    end

end

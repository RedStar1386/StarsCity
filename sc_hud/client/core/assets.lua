HUD = HUD or {}


HUD.assets = {}


-- Wanted

HUD.assets.starOff = "assets/icons/star_off.png"
HUD.assets.starOn = "assets/icons/star_on.png"



-- HUD Icons
-- Default icons are kept unchanged

HUD.assets.icons = {

    health = {
        default = "assets/icons/health.png",
        sky = "assets/icons/health_sky.png",
        yallow = "assets/icons/health_yallow.png",
        green = "assets/icons/health_green.png",
        red = "assets/icons/health_red.png",
        pink = "assets/icons/health_pink.png",
        purple = "assets/icons/health_purple.png"
    },

    armor = {
        default = "assets/icons/armor.png",
        sky = "assets/icons/armor_sky.png",
        yallow = "assets/icons/armor_yallow.png",
        green = "assets/icons/armor_green.png",
        red = "assets/icons/armor_red.png",
        pink = "assets/icons/armor_pink.png",
        purple = "assets/icons/armor_purple.png"
    },

    clock = {
        default = "assets/icons/clock.png",
        sky = "assets/icons/clock_sky.png",
        yallow = "assets/icons/clock_yallow.png",
        green = "assets/icons/clock_green.png",
        red = "assets/icons/clock_red.png",
        pink = "assets/icons/clock_pink.png",
        purple = "assets/icons/clock_purple.png"
    },

    date = {
        default = "assets/icons/date.png",
        sky = "assets/icons/date_sky.png",
        yallow = "assets/icons/date_yallow.png",
        green = "assets/icons/date_green.png",
        red = "assets/icons/date_red.png",
        pink = "assets/icons/date_pink.png",
        purple = "assets/icons/date_purple.png"
    },

    ping = {
        default = "assets/icons/ping.png",
        sky = "assets/icons/ping_sky.png",
        yallow = "assets/icons/ping_yallow.png",
        green = "assets/icons/ping_green.png",
        red = "assets/icons/ping_red.png",
        pink = "assets/icons/ping_pink.png",
        purple = "assets/icons/ping_purple.png"
    },

    money = {
        default = "assets/icons/money.png",
        sky = "assets/icons/money_sky.png",
        yallow = "assets/icons/money_yallow.png",
        green = "assets/icons/money_green.png",
        red = "assets/icons/money_red.png",
        pink = "assets/icons/money_pink.png",
        purple = "assets/icons/money_purple.png"
    }

}



-- Compatibility with old renderer

HUD.assets.health = HUD.assets.icons.health.default
HUD.assets.armor = HUD.assets.icons.armor.default
HUD.assets.clock = HUD.assets.icons.clock.default
HUD.assets.date = HUD.assets.icons.date.default
HUD.assets.ping = HUD.assets.icons.ping.default
HUD.assets.money = HUD.assets.icons.money.default



HUD.assets.currentColor = "default"



function HUD.assets:getIcon(name)

    local color = self.currentColor


    if HUD.theme
    and HUD.theme.icon
    and HUD.theme.icon.currentColor then

        color = HUD.theme.icon.currentColor

    end


    if self.icons[name]
    and self.icons[name][color] then

        return self.icons[name][color]

    end


    return self.icons[name].default

end

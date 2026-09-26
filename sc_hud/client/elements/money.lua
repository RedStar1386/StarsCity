HUD = HUD or {}


HUD:registerElement(
    "money",
    {

        getValue = function()

            return getPlayerMoney(localPlayer)

        end

    }
)

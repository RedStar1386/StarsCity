HUD = HUD or {}


HUD:registerElement(
    "armor",
    {

        getValue = function()

            return math.floor(
                getPedArmor(localPlayer)
            )

        end

    }
)

HUD = HUD or {}


HUD:registerElement(
    "health",
    {

        getValue = function()

            return math.floor(
                getElementHealth(localPlayer)
            )

        end

    }
)

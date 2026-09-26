HUD = HUD or {}


HUD:registerElement(
    "wanted",
    {

        getValue = function()


            local wanted = getElementData(
                localPlayer,
                "wanted"
            ) or 0


            wanted = tonumber(wanted) or 0


            return wanted


        end

    }
)

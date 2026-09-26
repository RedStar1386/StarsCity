HUD = HUD or {}


HUD:registerElement(
    "player",
    {

        getValue = function()


            local username = getElementData(
                localPlayer,
                "account:username"
            )


            if not username then

                username = getPlayerName(localPlayer)

            end


            local id = getElementData(
                localPlayer,
                "account:id"
            ) or 0



            return username.." ["..id.."]"


        end

    }
)

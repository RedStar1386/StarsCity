local screenW, screenH = guiGetScreenSize()

local loadingVisible = true
local rainbowTick = 0


-------------------------------------------------
-- Rainbow Color
-------------------------------------------------

local function getRainbowColor()

    rainbowTick = rainbowTick + 1

    local r =
        math.sin(rainbowTick * 0.03) * 127 + 128

    local g =
        math.sin(rainbowTick * 0.03 + 2) * 127 + 128

    local b =
        math.sin(rainbowTick * 0.03 + 4) * 127 + 128

    return r,g,b

end



-------------------------------------------------
-- Loading Render
-------------------------------------------------

addEventHandler(
    "onClientRender",
    root,
    function()

        if not loadingVisible then
            return
        end


        -- Black Screen

        dxDrawRectangle(
            0,
            0,
            screenW,
            screenH,
            tocolor(
                0,
                0,
                0,
                255
            )
        )



        local r,g,b =
            getRainbowColor()



        dxDrawText(
            "Loading...",
            0,
            screenH / 2 - 50,
            screenW,
            screenH / 2 + 50,

            tocolor(
                r,
                g,
                b,
                255
            ),

            3,
            "default-bold",

            "center",
            "center"
        )


    end
)



-------------------------------------------------
-- Close Loading Event
-------------------------------------------------

addEvent(
    "finishLoading",
    true
)


addEventHandler(
    "finishLoading",
    localPlayer,
    function()

        loadingVisible = false

    end
)

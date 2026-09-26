-- =========================================
-- STARS CITY PROFILE
-- F1 PROFILE PANEL
-- =========================================

local screenW, screenH = guiGetScreenSize()

local profileVisible = false


-- =========================================
-- TOGGLE PROFILE
-- =========================================

bindKey("F1", "down", function()

    profileVisible = not profileVisible

    showCursor(profileVisible)

    showChat(not profileVisible)

end)


-- =========================================
-- DRAW PROFILE
-- =========================================

addEventHandler("onClientRender", root, function()

    if not profileVisible then
        return
    end


    -- =====================================
    -- BACKGROUND
    -- =====================================

    dxDrawRectangle(
        0,
        0,
        screenW,
        screenH,
        tocolor(0, 0, 0, 170)
    )


    -- =====================================
    -- MAIN PANEL
    -- =====================================

    local panelW = 650
    local panelH = 430

    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2


    -- Shadow

    dxDrawRectangle(
        panelX + 8,
        panelY + 8,
        panelW,
        panelH,
        tocolor(0, 0, 0, 130)
    )


    -- Main Glass Panel

    dxDrawRectangle(
        panelX,
        panelY,
        panelW,
        panelH,
        tocolor(20, 20, 25, 235)
    )


    -- =====================================
    -- HEADER
    -- =====================================

    dxDrawRectangle(
        panelX,
        panelY,
        panelW,
        75,
        tocolor(15, 15, 20, 245)
    )


    dxDrawText(
        "STARS CITY",
        panelX + 30,
        panelY + 14,
        panelX + panelW,
        panelY + 45,
        tocolor(255, 255, 255, 255),
        1.6,
        "default-bold",
        "left",
        "center"
    )


    dxDrawText(
        "PLAYER PROFILE",
        panelX + 31,
        panelY + 42,
        panelX + panelW,
        panelY + 65,
        tocolor(170, 170, 170, 255),
        1.0,
        "default",
        "left",
        "center"
    )


    -- Close text

    dxDrawText(
        "F1 / ESC",
        panelX + panelW - 100,
        panelY + 25,
        panelX + panelW - 25,
        panelY + 55,
        tocolor(150, 150, 150, 255),
        1.0,
        "default-bold",
        "right",
        "center"
    )


    -- =====================================
    -- PLAYER DATA
    -- =====================================

    local username =
        getElementData(
            localPlayer,
            "account:username"
        ) or "Unknown"


    local playerID =
        getElementData(
            localPlayer,
            "account:id"
        ) or 0


    local gender =
        getElementData(
            localPlayer,
            "account:gender"
        ) or "Unknown"


    local vehicleSlots =
        getElementData(
            localPlayer,
            "player:vehicleSlots"
        ) or 1


    local cash =
        getPlayerMoney(localPlayer)


    -- =====================================
    -- PLAYER INFORMATION
    -- =====================================

    local infoX = panelX + 280
    local infoY = panelY + 115


    dxDrawText(
        "Username",
        infoX,
        infoY,
        infoX + 300,
        infoY + 30,
        tocolor(150, 150, 150, 255),
        1.0,
        "default",
        "left",
        "center"
    )


    dxDrawText(
        username,
        infoX,
        infoY + 25,
        infoX + 300,
        infoY + 60,
        tocolor(255, 255, 255, 255),
        1.25,
        "default-bold",
        "left",
        "center"
    )


    -- ID

    dxDrawText(
        "Player ID",
        infoX,
        infoY + 75,
        infoX + 300,
        infoY + 105,
        tocolor(150, 150, 150, 255),
        1.0,
        "default",
        "left",
        "center"
    )


    dxDrawText(
        "#" .. playerID,
        infoX,
        infoY + 100,
        infoX + 300,
        infoY + 135,
        tocolor(255, 215, 0, 255),
        1.25,
        "default-bold",
        "left",
        "center"
    )


    -- Gender

    dxDrawText(
        "Gender",
        infoX,
        infoY + 150,
        infoX + 300,
        infoY + 180,
        tocolor(150, 150, 150, 255),
        1.0,
        "default",
        "left",
        "center"
    )


    dxDrawText(
        gender,
        infoX,
        infoY + 175,
        infoX + 300,
        infoY + 210,
        tocolor(255, 255, 255, 255),
        1.15,
        "default-bold",
        "left",
        "center"
    )


    -- =====================================
    -- CASH
    -- =====================================

    dxDrawText(
        "Cash",
        infoX,
        infoY + 225,
        infoX + 300,
        infoY + 255,
        tocolor(150, 150, 150, 255),
        1.0,
        "default",
        "left",
        "center"
    )


    dxDrawText(
        "$" .. cash,
        infoX,
        infoY + 250,
        infoX + 300,
        infoY + 290,
        tocolor(80, 220, 120, 255),
        1.35,
        "default-bold",
        "left",
        "center"
    )


    -- =====================================
    -- VEHICLE SLOTS
    -- =====================================

    dxDrawText(
        "Vehicle Slots",
        infoX,
        infoY + 305,
        infoX + 300,
        infoY + 335,
        tocolor(150, 150, 150, 255),
        1.0,
        "default",
        "left",
        "center"
    )


    dxDrawText(
        tostring(vehicleSlots),
        infoX,
        infoY + 330,
        infoX + 300,
        infoY + 365,
        tocolor(255, 255, 255, 255),
        1.2,
        "default-bold",
        "left",
        "center"
    )


    -- =====================================
    -- PLAYER SKIN
    -- =====================================

    local skinID =
        getElementModel(localPlayer)


    dxDrawText(
        "Skin ID",
        panelX + 45,
        panelY + 315,
        panelX + 220,
        panelY + 345,
        tocolor(150, 150, 150, 255),
        1.0,
        "default",
        "center",
        "center"
    )


    dxDrawText(
        tostring(skinID),
        panelX + 45,
        panelY + 345,
        panelX + 220,
        panelY + 380,
        tocolor(255, 255, 255, 255),
        1.2,
        "default-bold",
        "center",
        "center"
    )


    -- =====================================
    -- FOOTER
    -- =====================================

    dxDrawText(
        "Press F1 to close profile",
        panelX,
        panelY + panelH - 40,
        panelX + panelW,
        panelY + panelH - 15,
        tocolor(120, 120, 120, 255),
        0.9,
        "default",
        "center",
        "center"
    )

end)


-- =========================================
-- ESC CLOSE
-- =========================================

bindKey("escape", "down", function()

    if not profileVisible then
        return
    end

    profileVisible = false

    showCursor(false)

    showChat(true)

end)
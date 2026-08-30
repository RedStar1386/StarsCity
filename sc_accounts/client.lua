-- ========================================================= 
-- STARS CITY 
-- ACCOUNT SYSTEM 
-- client.lua 
-- ========================================================= 
-- 
-- F1 = Player Profile 
-- 
-- ========================================================= 
 
 
local screenW, screenH = 
    guiGetScreenSize() 
 
 
-- ========================================================= 
-- PROFILE 
-- ========================================================= 
 
local profileVisible = false 
 
 
-- ========================================================= 
-- F1 PROFILE 
-- ========================================================= 
 
bindKey( 
 
    "F1", 
 
    "down", 
 
    function() 
 
        profileVisible = 
            not profileVisible 
 
 
        showCursor( 
            profileVisible 
        ) 
 
 
        showChat( 
            not profileVisible 
        ) 
 
    end 
 
) 
 
 
-- ========================================================= 
-- DRAW PROFILE 
-- ========================================================= 
 
addEventHandler( 
 
    "onClientRender", 
 
    root, 
 
    function() 
 
        if not profileVisible then 
            return 
        end 
 
 
        -- ================================================= 
        -- BACKGROUND 
        -- ================================================= 
 
        dxDrawRectangle( 
 
            0, 
            0, 
            screenW, 
            screenH, 
 
            tocolor( 
                0, 
                0, 
                0, 
                170 
            ) 
 
        ) 
 
 
        -- ================================================= 
        -- PANEL SIZE 
        -- ================================================= 
 
        local profileW = 650 
        local profileH = 430 
 
 
        local profileX = 
 
            (screenW - profileW) 
            / 2 
 
 
        local profileY = 
 
            (screenH - profileH) 
            / 2 
 
 
        -- ================================================= 
        -- SHADOW 
        -- ================================================= 
 
        dxDrawRectangle( 
 
            profileX + 8, 
            profileY + 8, 
            profileW, 
            profileH, 
 
            tocolor( 
                0, 
                0, 
                0, 
                130 
            ) 
 
        ) 
 
 
        -- ================================================= 
        -- MAIN PANEL 
        -- ================================================= 
 
        dxDrawRectangle( 
 
            profileX, 
            profileY, 
            profileW, 
            profileH, 
 
            tocolor( 
                20, 
                20, 
                25, 
                235 
            ) 
 
        ) 
 
 
        -- ================================================= 
        -- HEADER 
        -- ================================================= 
 
        dxDrawRectangle( 
 
            profileX, 
            profileY, 
            profileW, 
            75, 
 
            tocolor( 
                15, 
                15, 
                20, 
                245 
            ) 
 
        ) 
 
 
        dxDrawText( 
 
            "STARS CITY", 
 
            profileX + 30, 
            profileY + 14, 
 
            profileX + profileW, 
            profileY + 45, 
 
            tocolor( 
                255, 
                255, 
                255, 
                255 
            ), 
 
            1.6, 
 
            "default-bold", 
 
            "left", 
            "center" 
 
        ) 
 
 
        dxDrawText( 
 
            "PLAYER PROFILE", 
 
            profileX + 31, 
            profileY + 42, 
 
            profileX + profileW, 
            profileY + 65, 
 
            tocolor( 
                170, 
                170, 
                170, 
                255 
            ), 
 
            1.0, 
 
            "default", 
 
            "left", 
            "center" 
 
        ) 
 
 
        dxDrawText( 
 
            "F1 / ESC", 
 
            profileX + profileW - 100, 
            profileY + 25, 
 
            profileX + profileW - 25, 
            profileY + 55, 
 
            tocolor( 
                150, 
                150, 
                150, 
                255 
            ), 
 
            1.0, 
 
            "default-bold", 
 
            "right", 
            "center" 
 
        ) 
 
 
        -- ================================================= 
        -- PLAYER DATA 
        -- ================================================= 
 
        local username = 
 
            getElementData( 
 
                localPlayer, 
 
                "account:username" 
 
            ) 
 
            or "Unknown" 
 
 
        local playerID = 
 
            getElementData( 
 
                localPlayer, 
 
                "account:id" 
 
            ) 
 
            or 0 
 
 
        local gender = 
 
            getElementData( 
 
                localPlayer, 
 
                "account:gender" 
 
            ) 
 
            or "Unknown" 
 
 
        local vehicleSlots = 
 
            getElementData( 
 
                localPlayer, 
 
                "player:vehicleSlots" 
 
            ) 
 
            or 1 
 
 
        local cash = 
 
            getPlayerMoney( 
                localPlayer 
            ) 
 
 
        -- ================================================= 
        -- INFO 
        -- ================================================= 
 
        local infoX = 
            profileX + 280 
 
        local infoY = 
            profileY + 115 
 
 
        -- ================================================= 
        -- USERNAME 
        -- ================================================= 
 
        dxDrawText( 
 
            "Username", 
 
            infoX, 
            infoY, 
            infoX + 300, 
            infoY + 30, 
 
            tocolor( 
                150, 
                150, 
                150, 
                255 
            ), 
 
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
 
            tocolor( 
                255, 
                255, 
                255, 
                255 
            ), 
 
            1.25, 
 
            "default-bold", 
 
            "left", 
            "center" 
 
        ) 
 
 
        -- ================================================= 
        -- PLAYER ID 
        -- ================================================= 
 
        dxDrawText( 
 
            "Player ID", 
 
            infoX, 
            infoY + 75, 
            infoX + 300, 
            infoY + 105, 
 
            tocolor( 
                150, 
                150, 
                150, 
                255 
            ), 
 
            1.0, 
 
            "default", 
 
            "left", 
            "center" 
 
        ) 
 
 
        dxDrawText( 
 
            "#" 
            .. tostring(playerID), 
 
            infoX, 
            infoY + 100, 
            infoX + 300, 
            infoY + 135, 
 
            tocolor( 
                255, 
                215, 
                0, 
                255 
            ), 
 
            1.25, 
 
            "default-bold", 
 
            "left", 
            "center" 
 
        ) 
 
 
        -- ================================================= 
        -- GENDER 
        -- ================================================= 
 
        dxDrawText( 
 
            "Gender", 
 
            infoX, 
            infoY + 150, 
            infoX + 300, 
            infoY + 180, 
 
            tocolor( 
                150, 
                150, 
                150, 
                255 
            ), 
 
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
 
            tocolor( 
                255, 
                255, 
                255, 
                255 
            ), 
 
            1.15, 
 
            "default-bold", 
 
            "left", 
            "center" 
 
        ) 
 
 
        -- ================================================= 
        -- CASH 
        -- ================================================= 
 
        dxDrawText( 
 
            "Cash", 
 
            infoX, 
            infoY + 225, 
            infoX + 300, 
            infoY + 255, 
 
            tocolor( 
                150, 
                150, 
                150, 
                255 
            ), 
 
            1.0, 
 
            "default", 
 
            "left", 
            "center" 
 
        ) 
 
 
        dxDrawText( 
 
            "$" 
            .. tostring(cash), 
 
            infoX, 
            infoY + 250, 
            infoX + 300, 
            infoY + 290, 
 
            tocolor( 
                80, 
                220, 
                120, 
                255 
            ), 
 
            1.35, 
 
            "default-bold", 
 
            "left", 
            "center" 
 
        ) 
 
 
        -- ================================================= 
        -- VEHICLE SLOTS 
        -- ================================================= 
 
        dxDrawText( 
 
            "Vehicle Slots", 
 
            infoX, 
            infoY + 305, 
            infoX + 300, 
            infoY + 335, 
 
            tocolor( 
                150, 
                150, 
                150, 
                255 
            ), 
 
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
 
            tocolor( 
                255, 
                255, 
                255, 
                255 
            ), 
 
            1.2, 
 
            "default-bold", 
 
            "left", 
            "center" 
 
        ) 
 
 
        -- ================================================= 
        -- SKIN 
        -- ================================================= 
 
        local skinID = 
 
            getElementModel( 
                localPlayer 
            ) 
 
 
        dxDrawText( 
 
            "Skin ID", 
 
            profileX + 45, 
            profileY + 315, 
            profileX + 220, 
            profileY + 345, 
 
            tocolor( 
                150, 
                150, 
                150, 
                255 
            ), 
 
            1.0, 
 
            "default", 
 
            "center", 
            "center" 
 
        ) 
 
 
        dxDrawText( 
 
            tostring(skinID), 
 
            profileX + 45, 
            profileY + 345, 
            profileX + 220, 
            profileY + 380, 
 
            tocolor( 
                255, 
                255, 
                255, 
                255 
            ), 
 
            1.2, 
 
            "default-bold", 
 
            "center", 
            "center" 
 
        ) 
 
 
        -- ================================================= 
        -- FOOTER 
        -- ================================================= 
 
        dxDrawText( 
 
            "Press F1 to close profile", 
 
            profileX, 
            profileY + profileH - 40, 
            profileX + profileW, 
            profileY + profileH - 15, 
 
            tocolor( 
                120, 
                120, 
                120, 
                255 
            ), 
 
            0.9, 
 
            "default", 
 
            "center", 
            "center" 
 
        ) 
 
    end 
 
) 
 
 
-- ========================================================= 
-- ESC CLOSE 
-- ========================================================= 
 
bindKey( 
 
    "escape", 
 
    "down", 
 
    function() 
 
        if profileVisible then 
 
            profileVisible = 
                false 
 
 
            showCursor(false) 
 
 
            showChat(true) 
 
 
            return 
 
        end 
 
    end 
 
) 

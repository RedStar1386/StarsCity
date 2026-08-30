-- =========================================================
-- STARS CITY - STAFF SYSTEM
-- sc_staff/client.lua
-- =========================================================
-- /setstaff = Open Staff Manager
--
-- Panel Layout:
-- Player ID
-- Online / Offline Status
-- Staff Rank
-- Cancel / Confirm
-- =========================================================


local screenW, screenH =
    guiGetScreenSize()


local staffPanelVisible = false


-- =========================================================
-- GUI ELEMENTS
-- =========================================================

local playerIDEdit = nil
local rankCombo = nil

local onlineStatusLabel = nil

local confirmButton = nil
local cancelButton = nil


-- =========================================================
-- BACKGROUND IMAGE
-- =========================================================
-- عکس را داخل پوشه sc_staff با نام:
--
-- background.png
--
-- قرار بده.
-- =========================================================

local panelBackground =
    nil


-- =========================================================
-- COLORS
-- =========================================================

local COLOR_TITLE =
    tocolor(
        255,
        99,
        71,
        255
    )
-- #FF6347


local COLOR_PLAYER_ID =
    tocolor(
        0,
        255,
        255,
        255
    )


local COLOR_GREEN =
    tocolor(
        0,
        255,
        0,
        255
    )


local COLOR_RED =
    tocolor(
        255,
        0,
        0,
        255
    )


local COLOR_TEXT =
    tocolor(
        255,
        255,
        255,
        255
    )


-- =========================================================
-- CREATE PANEL
-- =========================================================

local function createStaffPanel()

    -- =====================================================
    -- DESTROY OLD ELEMENTS
    -- =====================================================

    if isElement(playerIDEdit) then
        destroyElement(playerIDEdit)
    end


    if isElement(rankCombo) then
        destroyElement(rankCombo)
    end


    if isElement(onlineStatusLabel) then
        destroyElement(onlineStatusLabel)
    end


    if isElement(confirmButton) then
        destroyElement(confirmButton)
    end


    if isElement(cancelButton) then
        destroyElement(cancelButton)
    end


    -- =====================================================
    -- BACKGROUND IMAGE
    -- =====================================================

    if isElement(panelBackground) then

        destroyElement(
            panelBackground
        )

    end


    panelBackground =
        dxCreateTexture(
            "background.png"
        )


    -- =====================================================
    -- PLAYER ID EDIT
    -- =====================================================

    playerIDEdit =
        guiCreateEdit(
            0,
            0,
            1,
            1,
            "",
            false
        )


    guiSetVisible(
        playerIDEdit,
        false
    )


    guiEditSetMaxLength(
        playerIDEdit,
        10
    )


    -- =====================================================
    -- RANK COMBO
    -- =====================================================

    rankCombo =
        guiCreateComboBox(
            0,
            0,
            1,
            1,
            "Select Staff Rank",
            false
        )


    guiSetVisible(
        rankCombo,
        false
    )


    -- =====================================================
    -- RANKS
    -- =====================================================
    -- توجه:
    --
    -- Citizen در ظاهر پنل = [7]
    -- ولی هنگام ارسال به Server = 0
    --
    -- چون مقدار واقعی Citizen در Database صفر است.
    -- =====================================================

    guiComboBoxAddItem(
        rankCombo,
        "[2] Server Manager"
    )


    guiComboBoxAddItem(
        rankCombo,
        "[3] Administrator"
    )


    guiComboBoxAddItem(
        rankCombo,
        "[4] Moderator"
    )


    guiComboBoxAddItem(
        rankCombo,
        "[5] Support"
    )


    guiComboBoxAddItem(
        rankCombo,
        "[6] Helper"
    )


    guiComboBoxAddItem(
        rankCombo,
        "[7] Citizen"
    )


    -- =====================================================
    -- ONLINE STATUS LABEL
    -- =====================================================

    onlineStatusLabel =
        guiCreateLabel(
            0,
            0,
            1,
            1,
            "",
            false
        )


    guiLabelSetHorizontalAlign(
        onlineStatusLabel,
        "center"
    )


    guiLabelSetVerticalAlign(
        onlineStatusLabel,
        "center"
    )


    guiSetVisible(
        onlineStatusLabel,
        false
    )


    -- =====================================================
    -- CONFIRM BUTTON
    -- =====================================================

    confirmButton =
        guiCreateButton(
            0,
            0,
            1,
            1,
            "Confirm",
            false
        )


    guiSetVisible(
        confirmButton,
        false
    )


    -- =====================================================
    -- CANCEL BUTTON
    -- =====================================================

    cancelButton =
        guiCreateButton(
            0,
            0,
            1,
            1,
            "Cancel",
            false
        )


    guiSetVisible(
        cancelButton,
        false
    )

end


-- =========================================================
-- PANEL SIZE
-- =========================================================

local PANEL_W = 620
local PANEL_H = 430


-- =========================================================
-- UPDATE PANEL ELEMENTS
-- =========================================================

local function updatePanelElements()

    if not staffPanelVisible then
        return
    end


    local panelX =
        (screenW - PANEL_W) / 2


    local panelY =
        (screenH - PANEL_H) / 2


    -- =====================================================
    -- PLAYER ID EDIT
    -- =====================================================

    guiSetPosition(
        playerIDEdit,
        panelX + 70,
        panelY + 145,
        false
    )


    guiSetSize(
        playerIDEdit,
        PANEL_W - 140,
        40,
        false
    )


    -- =====================================================
    -- ONLINE STATUS
    -- =====================================================

    guiSetPosition(
        onlineStatusLabel,
        panelX + 70,
        panelY + 188,
        false
    )


    guiSetSize(
        onlineStatusLabel,
        PANEL_W - 140,
        30,
        false
    )


    -- =====================================================
    -- RANK COMBO
    -- =====================================================

    guiSetPosition(
        rankCombo,
        panelX + 250,
        panelY + 255,
        false
    )


    guiSetSize(
        rankCombo,
        PANEL_W - 320,
        100,
        false
    )


    -- =====================================================
    -- CANCEL
    -- =====================================================

    guiSetPosition(
        cancelButton,
        panelX + 70,
        panelY + 350,
        false
    )


    guiSetSize(
        cancelButton,
        220,
        42,
        false
    )


    -- =====================================================
    -- CONFIRM
    -- =====================================================

    guiSetPosition(
        confirmButton,
        panelX + PANEL_W - 290,
        panelY + 350,
        false
    )


    guiSetSize(
        confirmButton,
        220,
        42,
        false
    )

end


-- =========================================================
-- UPDATE ONLINE STATUS
-- =========================================================

local function updateOnlineStatus()

    if not staffPanelVisible then
        return
    end


    if not isElement(
        playerIDEdit
    ) then

        return

    end


    local text =
        guiGetText(
            playerIDEdit
        )


    local targetID =
        tonumber(text)


    if not targetID then

        guiSetText(
            onlineStatusLabel,
            ""
        )

        return

    end


    local targetPlayer =
        nil


    for _, player in ipairs(
        getElementsByType("player")
    ) do

        local accountID =
            tonumber(
                getElementData(
                    player,
                    "account:id"
                )
            )


        if accountID == targetID then

            targetPlayer =
                player

            break

        end

    end


    -- =====================================================
    -- ONLINE
    -- =====================================================

    if targetPlayer then

        guiSetText(
            onlineStatusLabel,
            "[ This Player is Online ]"
        )


        guiLabelSetColor(
            onlineStatusLabel,
            0,
            255,
            0
        )


    -- =====================================================
    -- OFFLINE
    -- =====================================================

    else

        guiSetText(
            onlineStatusLabel,
            "[ This Player is Offline ]"
        )


        guiLabelSetColor(
            onlineStatusLabel,
            255,
            0,
            0
        )

    end

end


-- =========================================================
-- OPEN PANEL
-- =========================================================

local function openStaffPanel()

    if staffPanelVisible then
        return
    end


    if not isElement(
        playerIDEdit
    ) then

        createStaffPanel()

    end


    staffPanelVisible =
        true


    guiSetVisible(
        playerIDEdit,
        true
    )


    guiSetVisible(
        onlineStatusLabel,
        true
    )


    guiSetVisible(
        rankCombo,
        true
    )


    guiSetVisible(
        confirmButton,
        true
    )


    guiSetVisible(
        cancelButton,
        true
    )


    guiSetText(
        playerIDEdit,
        ""
    )


    guiSetText(
        onlineStatusLabel,
        ""
    )


    guiComboBoxSetSelected(
        rankCombo,
        -1
    )


    updatePanelElements()


    guiBringToFront(
        playerIDEdit
    )


    showCursor(true)

end


-- =========================================================
-- CLOSE PANEL
-- =========================================================

local function closeStaffPanel()

    staffPanelVisible =
        false


    if isElement(
        playerIDEdit
    ) then

        guiSetVisible(
            playerIDEdit,
            false
        )

    end


    if isElement(
        rankCombo
    ) then

        guiSetVisible(
            rankCombo,
            false
        )

    end


    if isElement(
        onlineStatusLabel
    ) then

        guiSetVisible(
            onlineStatusLabel,
            false
        )

    end


    if isElement(
        confirmButton
    ) then

        guiSetVisible(
            confirmButton,
            false
        )

    end


    if isElement(
        cancelButton
    ) then

        guiSetVisible(
            cancelButton,
            false
        )

    end


    showCursor(false)

end


-- =========================================================
-- SERVER OPEN EVENT
-- =========================================================

addEvent(
    "scOpenStaffManager",
    true
)


addEventHandler(
    "scOpenStaffManager",
    root,

    function()

        openStaffPanel()

    end
)


-- =========================================================
-- /SETSTAFF
-- =========================================================
-- هیچ ID یا Rank از Command گرفته نمی‌شود.
-- فقط پنل را باز/بسته می‌کند.
-- =========================================================

addCommandHandler(
    "setstaff",

    function()

        if staffPanelVisible then

            closeStaffPanel()

        else

            triggerServerEvent(
                "scRequestOpenStaffManager",
                localPlayer
            )

        end

    end
)


-- =========================================================
-- DRAW PANEL
-- =========================================================

addEventHandler(
    "onClientRender",
    root,

    function()

        if not staffPanelVisible then
            return
        end


        local panelX =
            (screenW - PANEL_W) / 2


        local panelY =
            (screenH - PANEL_H) / 2


        -- =================================================
        -- DARK SCREEN OVERLAY
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
                150
            )
        )


        -- =================================================
        -- PANEL SHADOW
        -- =================================================

        dxDrawRectangle(
            panelX + 8,
            panelY + 8,
            PANEL_W,
            PANEL_H,

            tocolor(
                0,
                0,
                0,
                150
            )
        )


        -- =================================================
        -- PANEL BACKGROUND IMAGE
        -- =================================================

        if isElement(
            panelBackground
        ) then

            dxDrawImage(
                panelX,
                panelY,
                PANEL_W,
                PANEL_H,
                panelBackground,
                0,
                0,
                0,
                tocolor(
                    255,
                    255,
                    255,
                    255
                )
            )

        else

            -- اگر background.png وجود نداشت
            -- پنل ساده نمایش داده می‌شود.

            dxDrawRectangle(
                panelX,
                panelY,
                PANEL_W,
                PANEL_H,

                tocolor(
                    20,
                    20,
                    25,
                    245
                )
            )

        end


        -- =================================================
        -- DARK OVERLAY ON PANEL
        -- =================================================

        dxDrawRectangle(
            panelX,
            panelY,
            PANEL_W,
            PANEL_H,

            tocolor(
                0,
                0,
                0,
                85
            )
        )


        -- =================================================
        -- HEADER DARK BACKGROUND
        -- =================================================

        dxDrawRectangle(
            panelX,
            panelY,
            PANEL_W,
            75,

            tocolor(
                0,
                0,
                0,
                100
            )
        )


        -- =================================================
        -- TITLE
        -- =================================================
        -- CENTER
        -- #FF6347
        -- =================================================

        dxDrawText(
            "Staff Manager",

            panelX,
            panelY + 15,

            panelX + PANEL_W,
            panelY + 60,

            COLOR_TITLE,

            1.5,

            "default-bold",

            "center",
            "center"
        )


        -- =================================================
        -- PLAYER ID LABEL
        -- =================================================
        -- LEFT
        -- CYAN
        -- =================================================

        dxDrawText(
            "Player ID",

            panelX + 70,
            panelY + 108,

            panelX + PANEL_W - 70,
            panelY + 140,

            COLOR_PLAYER_ID,

            1.1,

            "default-bold",

            "left",
            "center"
        )


        -- =================================================
        -- STAFF RANK LABEL
        -- =================================================
        -- LEFT
        -- GREEN
        -- =================================================

        dxDrawText(
            "Staff Rank:",

            panelX + 70,
            panelY + 215,

            panelX + 230,
            panelY + 245,

            COLOR_GREEN,

            1.1,

            "default-bold",

            "left",
            "center"
        )

    end
)


-- =========================================================
-- PLAYER ID ONLY NUMBERS
-- =========================================================

addEventHandler(
    "onClientGUIChanged",
    root,

    function()

        if source ~= playerIDEdit then
            return
        end


        local text =
            guiGetText(
                playerIDEdit
            )


        -- =====================================================
        -- REMOVE EVERYTHING EXCEPT NUMBERS
        -- =====================================================

        local numbersOnly =
            text:gsub(
                "%D",
                ""
            )


        if text ~= numbersOnly then

            guiSetText(
                playerIDEdit,
                numbersOnly
            )

        end


        updateOnlineStatus()

    end
)


-- =========================================================
-- CANCEL BUTTON
-- =========================================================

addEventHandler(
    "onClientGUIClick",
    root,

    function()

        if source ~= cancelButton then
            return
        end


        closeStaffPanel()

    end
)


-- =========================================================
-- CONFIRM BUTTON
-- =========================================================

addEventHandler(
    "onClientGUIClick",
    root,

    function()

        if source ~= confirmButton then
            return
        end


        -- =================================================
        -- PLAYER ID
        -- =================================================

        local targetID =
            tonumber(
                guiGetText(
                    playerIDEdit
                )
            )


        if not targetID then

            outputChatBox(
                "[StarsCity] Player ID Eshtebah Ast.",
                255,
                70,
                70
            )

            return

        end


        -- =================================================
        -- RANK
        -- =================================================

        local selectedRank =
            guiComboBoxGetSelected(
                rankCombo
            )


        if selectedRank == -1 then

            outputChatBox(
                "[StarsCity] Lotfan Staff Rank Ra Entekhab Konid.",
                255,
                70,
                70
            )

            return

        end


        -- =================================================
        -- CONVERT DISPLAY INDEX TO REAL RANK
        -- =================================================
        --
        -- Combo:
        --
        -- 0 = [2] Server Manager
        -- 1 = [3] Administrator
        -- 2 = [4] Moderator
        -- 3 = [5] Support
        -- 4 = [6] Helper
        -- 5 = [7] Citizen
        --
        -- Real:
        --
        -- 2
        -- 3
        -- 4
        -- 5
        -- 6
        -- 0
        -- =================================================

        local rankMap = {

            [0] = 2,
            [1] = 3,
            [2] = 4,
            [3] = 5,
            [4] = 6,
            [5] = 7

        }


        local newRank =
            rankMap[
                selectedRank
            ]


        if not newRank then

            outputChatBox(
                "[StarsCity] Rank Eshtebah Ast.",
                255,
                70,
                70
            )

            return

        end


        -- =================================================
        -- SEND TO SERVER
        -- =================================================

        triggerServerEvent(
            "scRequestSetStaff",
            localPlayer,
            targetID,
            newRank
        )

    end
)


-- =========================================================
-- STAFF RESULT
-- =========================================================

addEvent(
    "scStaffResult",
    true
)


addEventHandler(
    "scStaffResult",
    root,

    function(
        success,
        message
    )

        if success then

            outputChatBox(
                "[StarsCity] "
                .. tostring(message),

                0,
                255,
                0
            )


            closeStaffPanel()

        else

            outputChatBox(
                "[StarsCity] Khata: "
                .. tostring(message),

                255,
                70,
                70
            )

        end

    end
)


-- =========================================================
-- RESOURCE START
-- =========================================================

addEventHandler(
    "onClientResourceStart",
    resourceRoot,

    function()

        createStaffPanel()

    end
)
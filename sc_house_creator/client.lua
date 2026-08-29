-- =========================================================
-- STARS CITY
-- HOUSE CREATOR
-- client.lua
-- =========================================================

local window = nil
local grid = nil
local selectButton = nil
local cancelButton = nil
local infoLabel = nil

local currentHouseID = nil


local INTERIORS = {
    {id = 0,  name = "Normal World"},
    {id = 1,  name = "Ammu-Nation 1"},
    {id = 2,  name = "Ryder's House"},
    {id = 3,  name = "Jizzy's Pleasure Domes"},
    {id = 4,  name = "24/7 Shop 1"},
    {id = 5,  name = "Madd Dogg's Mansion"},
    {id = 6,  name = "Ammu-Nation 3"},
    {id = 7,  name = "Ammu-Nation 5"},
    {id = 8,  name = "Safe House 2"},
    {id = 9,  name = "Unknown Safe House"},
    {id = 10, name = "Four Dragons Casino"},
    {id = 11, name = "Four Dragons Office"},
    {id = 12, name = "Budget Inn Motel Room"},
    {id = 13, name = "LS Atrium"},
    {id = 14, name = "Kickstart Stadium"},
    {id = 15, name = "Binco"},
    {id = 16, name = "24/7 Shop 4"},
    {id = 17, name = "24/7 Shop 5"},
    {id = 18, name = "Lil Probe Inn"}
}


local function closeWindow()

    if isElement(window) then
        destroyElement(window)
    end

    window = nil
    grid = nil
    selectButton = nil
    cancelButton = nil
    infoLabel = nil

    showCursor(false)

end


local function fillInteriorGrid()

    if not isElement(grid) then
        return
    end

    guiGridListClear(grid)

    for _, data in ipairs(INTERIORS) do

        local row =
            guiGridListAddRow(grid)

        guiGridListSetItemText(
            grid,
            row,
            1,
            tostring(data.id),
            false,
            false
        )

        guiGridListSetItemText(
            grid,
            row,
            2,
            data.name,
            false,
            false
        )

        guiGridListSetItemData(
            grid,
            row,
            1,
            data.id
        )

    end

end


local function getSelectedInterior()

    if not isElement(grid) then
        return nil
    end

    local row =
        guiGridListGetSelectedItem(grid)


    if not row
    or row == -1 then
        return nil
    end


    return tonumber(
        guiGridListGetItemData(
            grid,
            row,
            1
        )
    )

end


local function selectInterior()

    local interiorID =
        getSelectedInterior()


    if interiorID == nil then

        outputChatBox(
            "[StarsCity] Lotfan Yek Interior Entekhab Konid.",
            255,
            215,
            0
        )

        return

    end


    if not currentHouseID then
        return
    end


    triggerServerEvent(
        "scHouseCreatorSelectInterior",
        resourceRoot,
        currentHouseID,
        interiorID
    )

end


addEvent(
    "scHouseCreatorOpen",
    true
)


addEventHandler(
    "scHouseCreatorOpen",
    resourceRoot,

    function(houseID)

        closeWindow()

        currentHouseID =
            tonumber(houseID)


        local sx, sy =
            guiGetScreenSize()


        local width = 560
        local height = 520

        local x =
            (sx - width) / 2

        local y =
            (sy - height) / 2


        window =
            guiCreateWindow(
                x,
                y,
                width,
                height,
                "StarsCity - House Creator",
                false
            )


        guiWindowSetSizable(
            window,
            false
        )


        guiSetInputMode(
            "no_binds_when_editing"
        )


        infoLabel =
            guiCreateLabel(
                20,
                30,
                width - 40,
                55,
                "House ID: "
                .. tostring(currentHouseID)
                .. "\n\nInterior Ra Entekhab Konid.",
                false,
                window
            )


        guiLabelSetHorizontalAlign(
            infoLabel,
            "left"
        )

        guiLabelSetVerticalAlign(
            infoLabel,
            "center"
        )


        grid =
            guiCreateGridList(
                20,
                90,
                width - 40,
                330,
                false,
                window
            )


        guiGridListAddColumn(
            grid,
            "ID",
            0.18
        )

        guiGridListAddColumn(
            grid,
            "Interior / Location",
            0.70
        )


        fillInteriorGrid()


        selectButton =
            guiCreateButton(
                20,
                440,
                250,
                45,
                "Entekhab Va Enter",
                false,
                window
            )


        cancelButton =
            guiCreateButton(
                290,
                440,
                250,
                45,
                "Cancel Sakht",
                false,
                window
            )


        addEventHandler(
            "onClientGUIClick",
            selectButton,
            selectInterior,
            false
        )


        addEventHandler(
            "onClientGUIDoubleClick",
            grid,
            function()
                selectInterior()
            end,
            false
        )


        addEventHandler(
            "onClientGUIClick",
            cancelButton,
            function()

                triggerServerEvent(
                    "scHouseCreatorCancel",
                    resourceRoot,
                    currentHouseID
                )

            end,
            false
        )


        showCursor(true)

    end
)


addEvent(
    "scHouseCreatorClose",
    true
)


addEventHandler(
    "scHouseCreatorClose",
    resourceRoot,

    function()
        closeWindow()
        currentHouseID = nil
    end
)


addEvent(
    "scHouseCreatorSetInfo",
    true
)


addEventHandler(
    "scHouseCreatorSetInfo",
    resourceRoot,

    function(message)

        if isElement(infoLabel) then
            guiSetText(
                infoLabel,
                tostring(message)
            )
        end

    end
)

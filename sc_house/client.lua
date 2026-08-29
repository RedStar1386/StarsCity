-- ========================================================= 
-- STARS CITY 
-- HOUSE CLIENT 
-- client.lua 
-- ========================================================= 
 
 
local houseWindow = nil 
local myHouseWindow = nil 
 
local currentHouseID = nil 
local currentMyHouseID = nil 
 
local renterGrid = nil 
local selectedRenterID = nil 
 
 
-- ========================================================= 
-- COLORS 
-- ========================================================= 
 
local COLOR_YELLOW = {255, 255, 0} 
local COLOR_PINK = {255, 105, 180} 
local COLOR_ORANGE = {255, 165, 0} 
local COLOR_TURQUOISE = {64, 224, 208} 
local COLOR_GREEN = {0, 255, 0} 
local COLOR_RED = {255, 0, 0} 
 
 
-- ========================================================= 
-- FORMAT MONEY 
-- ========================================================= 
 
local function formatMoney(number) 
 
    number = tonumber(number) or 0 
 
    local formatted = 
        tostring( 
            math.floor(number) 
        ) 
 
    while true do 
 
        local result, count = 
            string.gsub( 
                formatted, 
                "^(-?%d+)(%d%d%d)", 
                "%1,%2" 
            ) 
 
        formatted = result 
 
        if count == 0 then 
            break 
        end 
 
    end 
 
    return "$" .. formatted 
 
end 
 
 
-- ========================================================= 
-- CLOSE HOUSE 
-- ========================================================= 
 
local function closeHousePanel() 
 
    if isElement(houseWindow) then 
        destroyElement(houseWindow) 
    end 
 
    houseWindow = nil 
    currentHouseID = nil 
 
    showCursor(false) 
 
end 
 
 
-- ========================================================= 
-- CLOSE MY HOUSE 
-- ========================================================= 
 
local function closeMyHousePanel() 
 
    if isElement(myHouseWindow) then 
        destroyElement(myHouseWindow) 
    end 
 
    myHouseWindow = nil 
    currentMyHouseID = nil 
    renterGrid = nil 
    selectedRenterID = nil 
 
    showCursor(false) 
 
end 
 
 
-- ========================================================= 
-- HOUSE PANEL 
-- ========================================================= 
 
addEvent( 
    "scOpenHousePanel", 
    true 
) 
 
addEventHandler( 
    "scOpenHousePanel", 
    root, 
 
    function( 
        houseID, 
        houseName, 
        owner, 
        ownerID, 
        price, 
        rentPrice, 
        locked, 
        isOwner 
    ) 
 
        closeHousePanel() 
 
        currentHouseID = 
            tonumber(houseID) 
 
        local sx, sy = 
            guiGetScreenSize() 
 
        houseWindow = 
            guiCreateWindow( 
 
                sx / 2 - 190, 
                sy / 2 - 210, 
 
                380, 
                420, 
 
                "HOUSE INFO", 
 
                false 
 
            ) 
 
        guiWindowSetSizable( 
            houseWindow, 
            false 
        ) 
 
 
        -- ================================================= 
        -- HOUSE ID 
        -- ================================================= 
 
        local idLabel = 
            guiCreateLabel( 
 
                20, 
                45, 
                340, 
                30, 
 
                "House ID: #" 
                .. tostring(houseID), 
 
                false, 
                houseWindow 
 
            ) 
 
        guiLabelSetHorizontalAlign( 
            idLabel, 
            "center" 
        ) 
 
        guiSetFont( 
            idLabel, 
            "default-bold" 
        ) 
 
        guiLabelSetColor( 
            idLabel, 
            COLOR_YELLOW[1], 
            COLOR_YELLOW[2], 
            COLOR_YELLOW[3] 
        ) 
 
 
        -- ================================================= 
        -- OWNER 
        -- ================================================= 
 
        local ownerText = 
            owner 
 
        if not owner 
        or owner == "" then 
 
            ownerText = 
                "---" 
 
        end 
 
        local ownerLabel = 
            guiCreateLabel( 
 
                20, 
                82, 
                340, 
                30, 
 
                "Owner: " 
                .. tostring(ownerText), 
 
                false, 
                houseWindow 
 
            ) 
 
        guiLabelSetHorizontalAlign( 
            ownerLabel, 
            "center" 
        ) 
 
        guiSetFont( 
            ownerLabel, 
            "default-bold" 
        ) 
 
        guiLabelSetColor( 
            ownerLabel, 
            COLOR_PINK[1], 
            COLOR_PINK[2], 
            COLOR_PINK[3] 
        ) 
 
 
        -- ================================================= 
        -- PRICE 
        -- ================================================= 
 
        local priceLabel = 
            guiCreateLabel( 
 
                20, 
                119, 
                340, 
                30, 
 
                "Price: " 
                .. formatMoney(price), 
 
                false, 
                houseWindow 
 
            ) 
 
        guiLabelSetHorizontalAlign( 
            priceLabel, 
            "center" 
        ) 
 
        guiSetFont( 
            priceLabel, 
            "default-bold" 
        ) 
 
        guiLabelSetColor( 
            priceLabel, 
            COLOR_ORANGE[1], 
            COLOR_ORANGE[2], 
            COLOR_ORANGE[3] 
        ) 
 
 
        -- ================================================= 
        -- RENT PRICE 
        -- ================================================= 
 
        local rentLabel = 
            guiCreateLabel( 
 
                20, 
                156, 
                340, 
                30, 
 
                "Rent Price: " 
                .. ( 
                    tonumber(rentPrice) > 0 
                    and formatMoney(rentPrice) 
                    or "---" 
                ), 
 
                false, 
                houseWindow 
 
            ) 
 
        guiLabelSetHorizontalAlign( 
            rentLabel, 
            "center" 
        ) 
 
        guiSetFont( 
            rentLabel, 
            "default-bold" 
        ) 
 
        guiLabelSetColor( 
            rentLabel, 
            COLOR_TURQUOISE[1], 
            COLOR_TURQUOISE[2], 
            COLOR_TURQUOISE[3] 
        ) 
 
 
        -- ================================================= 
        -- BUY 
        -- ================================================= 
 
        local buyButton = 
            guiCreateButton( 
 
                45, 
                205, 
 
                290, 
                42, 
 
                "Buy House", 
 
                false, 
                houseWindow 
 
            ) 
 
        guiSetProperty( 
            buyButton, 
            "NormalTextColour", 
            "FFFFFF00" 
        ) 
 
 
        -- ================================================= 
        -- RENT 
        -- ================================================= 
 
        local rentButton = 
            guiCreateButton( 
 
                45, 
                255, 
 
                290, 
                42, 
 
                "Rent", 
 
                false, 
                houseWindow 
 
            ) 
 
        guiSetProperty( 
            rentButton, 
            "NormalTextColour", 
            "FF40E0D0" 
        ) 
 
 
        -- ================================================= 
        -- ENTRY 
        -- ================================================= 
 
        local entryButton = 
            guiCreateButton( 
 
                45, 
                305, 
 
                140, 
                42, 
 
                "Entry", 
 
                false, 
                houseWindow 
 
            ) 
 
        guiSetProperty( 
            entryButton, 
            "NormalTextColour", 
            "FF00FF00" 
        ) 
 
 
        -- ================================================= 
        -- CANCEL 
        -- ================================================= 
 
        local cancelButton = 
            guiCreateButton( 
 
                195, 
                305, 
 
                140, 
                42, 
 
                "Cancel", 
 
                false, 
                houseWindow 
 
            ) 
 
        guiSetProperty( 
            cancelButton, 
            "NormalTextColour", 
            "FFFF0000" 
        ) 
 
 
        -- ================================================= 
        -- LOCK STATUS 
        -- ================================================= 
 
        local lockLabel = 
            guiCreateLabel( 
 
                20, 
                355, 
 
                340, 
                25, 
 
                locked 
                and "House Status: LOCKED" 
                or "House Status: UNLOCKED", 
 
                false, 
                houseWindow 
 
            ) 
 
        guiLabelSetHorizontalAlign( 
            lockLabel, 
            "center" 
        ) 
 
        guiSetFont( 
            lockLabel, 
            "default-bold" 
        ) 
 
        if locked then 
 
            guiLabelSetColor( 
                lockLabel, 
                COLOR_RED[1], 
                COLOR_RED[2], 
                COLOR_RED[3] 
            ) 
 
        else 
 
            guiLabelSetColor( 
                lockLabel, 
                COLOR_GREEN[1], 
                COLOR_GREEN[2], 
                COLOR_GREEN[3] 
            ) 
 
        end 
 
 
        -- ================================================= 
        -- BUY CLICK 
        -- ================================================= 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            buyButton, 
 
            function() 
 
                if not currentHouseID then 
                    return 
                end 
 
                triggerServerEvent( 
                    "scBuyHouse", 
                    localPlayer, 
                    currentHouseID 
                ) 
 
            end, 
 
            false 
 
        ) 
 
 
        -- ================================================= 
        -- RENT CLICK 
        -- ================================================= 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            rentButton, 
 
            function() 
 
                if locked then 
 
                    outputChatBox( 
 
                        "[StarsCity] In Khane Ghafel Ast.", 
 
                        255, 
                        70, 
                        70 
 
                    ) 
 
                    return 
 
                end 
 
                triggerServerEvent( 
                    "scRentHouse", 
                    localPlayer, 
                    currentHouseID 
                ) 
 
            end, 
 
            false 
 
        ) 
 
 
        -- ================================================= 
        -- ENTRY CLICK 
        -- ================================================= 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            entryButton, 
 
            function() 
 
                triggerServerEvent( 
                    "scHouseEntry", 
                    localPlayer, 
                    currentHouseID 
                ) 
 
            end, 
 
            false 
 
        ) 
 
 
        -- ================================================= 
        -- CANCEL CLICK 
        -- ================================================= 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            cancelButton, 
 
            function() 
 
                closeHousePanel() 
 
            end, 
 
            false 
 
        ) 
 
 
        showCursor(true) 
 
    end 
) 
 
 
-- ========================================================= 
-- MY HOUSE PANEL 
-- ========================================================= 
 
addEvent( 
    "scOpenMyHouse", 
    true 
) 
 
addEventHandler( 
    "scOpenMyHouse", 
    root, 
 
    function( 
        houseID, 
        houseName, 
        owner, 
        price, 
        rentPrice, 
        locked, 
        renters 
    ) 
 
        closeMyHousePanel() 
 
        currentMyHouseID = 
            tonumber(houseID) 
 
        local sx, sy = 
            guiGetScreenSize() 
 
        myHouseWindow = 
            guiCreateWindow( 
 
                sx / 2 - 250, 
                sy / 2 - 300, 
 
                500, 
                600, 
 
                "* My House *", 
 
                false 
 
            ) 
 
        guiWindowSetSizable( 
            myHouseWindow, 
            false 
        ) 
 
 
        -- ================================================= 
        -- HOUSE ID 
        -- ================================================= 
 
        local idLabel = 
            guiCreateLabel( 
 
                25, 
                45, 
                450, 
                30, 
 
                "🏠 House ID : #" 
                .. tostring(houseID), 
 
                false, 
                myHouseWindow 
 
            ) 
 
        guiLabelSetHorizontalAlign( 
            idLabel, 
            "center" 
        ) 
 
        guiSetFont( 
            idLabel, 
            "default-bold" 
        ) 
 
        guiLabelSetColor( 
            idLabel, 
            COLOR_YELLOW[1], 
            COLOR_YELLOW[2], 
            COLOR_YELLOW[3] 
        ) 
 
 
        -- ================================================= 
        -- RENTERS 
        -- ================================================= 
 
        local renterLabel = 
            guiCreateLabel( 
 
                25, 
                85, 
                450, 
                30, 
 
                "👥 Renters", 
 
                false, 
                myHouseWindow 
 
            ) 
 
        guiLabelSetHorizontalAlign( 
            renterLabel, 
            "center" 
        ) 
 
        guiSetFont( 
            renterLabel, 
            "default-bold" 
        ) 
 
        guiLabelSetColor( 
            renterLabel, 
            COLOR_YELLOW[1], 
            COLOR_YELLOW[2], 
            COLOR_YELLOW[3] 
        ) 
 
 
        renterGrid = 
            guiCreateGridList( 
 
                40, 
                120, 
 
                420, 
                140, 
 
                false, 
                myHouseWindow 
 
            ) 
 
        guiGridListAddColumn( 
            renterGrid, 
            "Renter", 
            0.65 
        ) 
 
        guiGridListAddColumn( 
            renterGrid, 
            "ID", 
            0.25 
        ) 
 
 
        -- ================================================= 
        -- POPULATE RENTERS 
        -- ================================================= 
 
        local function populateRenters(list) 
 
            guiGridListClear( 
                renterGrid 
            ) 
 
            selectedRenterID = nil 
 
            for _, renter in ipairs( 
                list or {} 
            ) do 
 
                local row = 
                    guiGridListAddRow( 
                        renterGrid 
                    ) 
 
                -- RENTER NAME 
                guiGridListSetItemText( 
 
                    renterGrid, 
                    row, 
                    1, 
 
                    tostring( 
                        renter.player_name 
                    ), 
 
                    false, 
                    false 
 
                ) 
 
                guiGridListSetItemColor( 
 
                    renterGrid, 
                    row, 
                    1, 
 
                    COLOR_TURQUOISE[1], 
                    COLOR_TURQUOISE[2], 
                    COLOR_TURQUOISE[3] 
 
                ) 
 
 
                -- RENTER ID 
                guiGridListSetItemText( 
 
                    renterGrid, 
                    row, 
                    2, 
 
                    tostring( 
                        renter.player_id 
                    ), 
 
                    false, 
                    false 
 
                ) 
 
                guiGridListSetItemColor( 
 
                    renterGrid, 
                    row, 
                    2, 
 
                    COLOR_PINK[1], 
                    COLOR_PINK[2], 
                    COLOR_PINK[3] 
 
                ) 
 
 
                guiGridListSetItemData( 
 
                    renterGrid, 
                    row, 
                    1, 
 
                    renter.player_id 
 
                ) 
 
            end 
 
        end 
 
 
        populateRenters( 
            renters 
        ) 
 
 
        -- ================================================= 
        -- KICK 
        -- ================================================= 
 
        local kickButton = 
            guiCreateButton( 
 
                40, 
                270, 
 
                420, 
                40, 
 
                "Kick Selected Renter", 
 
                false, 
                myHouseWindow 
 
            ) 
 
        guiSetProperty( 
            kickButton, 
            "NormalTextColour", 
            "FFFF0000" 
        ) 
 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            renterGrid, 
 
            function() 
 
                local row = 
                    guiGridListGetSelectedItem( 
                        renterGrid 
                    ) 
 
                if row == -1 then 
 
                    selectedRenterID = 
                        nil 
 
                    return 
 
                end 
 
                selectedRenterID = 
                    tonumber( 
 
                        guiGridListGetItemData( 
 
                            renterGrid, 
                            row, 
                            1 
 
                        ) 
 
                    ) 
 
            end, 
 
            false 
 
        ) 
 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            kickButton, 
 
            function() 
 
                if not selectedRenterID then 
 
                    outputChatBox( 
 
                        "[StarsCity] Yek Az Mostajerha Ra Entekhab Konid.", 
 
                        255, 
                        70, 
                        70 
 
                    ) 
 
                    return 
 
                end 
 
                triggerServerEvent( 
 
                    "scHouseKickRenter", 
 
                    localPlayer, 
 
                    currentMyHouseID, 
 
                    selectedRenterID 
 
                ) 
 
            end, 
 
            false 
 
        ) 
 
 
        -- ================================================= 
        -- HOUSE LOCK 
        -- ================================================= 
 
        local lockLabel = 
            guiCreateLabel( 
 
                25, 
                325, 
 
                450, 
                30, 
 
                "🔐 House Lock", 
 
                false, 
                myHouseWindow 
 
            ) 
 
        guiLabelSetHorizontalAlign( 
            lockLabel, 
            "center" 
        ) 
 
        guiSetFont( 
            lockLabel, 
            "default-bold" 
        ) 
 
        guiLabelSetColor( 
            lockLabel, 
            COLOR_YELLOW[1], 
            COLOR_YELLOW[2], 
            COLOR_YELLOW[3] 
        ) 
 
 
        local lockButton = 
            guiCreateButton( 
 
                55, 
                365, 
 
                180, 
                40, 
 
                "Lock", 
 
                false, 
                myHouseWindow 
 
            ) 
 
        local unlockButton = 
            guiCreateButton( 
 
                265, 
                365, 
 
                180, 
                40, 
 
                "Unlock", 
 
                false, 
                myHouseWindow 
 
            ) 
 
        guiSetProperty( 
            lockButton, 
            "NormalTextColour", 
            "FFFF0000" 
        ) 
 
        guiSetProperty( 
            unlockButton, 
            "NormalTextColour", 
            "FF00FF00" 
        ) 
 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            lockButton, 
 
            function() 
 
                triggerServerEvent( 
 
                    "scHouseSetLock", 
 
                    localPlayer, 
 
                    currentMyHouseID, 
 
                    true 
 
                ) 
 
            end, 
 
            false 
 
        ) 
 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            unlockButton, 
 
            function() 
 
                triggerServerEvent( 
 
                    "scHouseSetLock", 
 
                    localPlayer, 
 
                    currentMyHouseID, 
 
                    false 
 
                ) 
 
            end, 
 
            false 
 
        ) 
 
 
        -- ================================================= 
        -- RENT PRICE 
        -- ================================================= 
 
        local rentPriceLabel = 
            guiCreateLabel( 
 
                25, 
                420, 
 
                150, 
                30, 
 
                "💸 Rent Price :", 
 
                false, 
                myHouseWindow 
 
            ) 
 
        guiLabelSetColor( 
            rentPriceLabel, 
            COLOR_YELLOW[1], 
            COLOR_YELLOW[2], 
            COLOR_YELLOW[3] 
        ) 
 
 
        local rentEdit = 
            guiCreateEdit( 
 
                175, 
                415, 
 
                190, 
                40, 
 
                tostring( 
                    rentPrice or 0 
                ), 
 
                false, 
                myHouseWindow 
 
            ) 
 
        guiEditSetMaxLength( 
            rentEdit, 
            8 
        ) 
 
 
        local rentSave = 
            guiCreateButton( 
 
                375, 
                415, 
 
                70, 
                40, 
 
                "Set", 
 
                false, 
                myHouseWindow 
 
            ) 
 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            rentSave, 
 
            function() 
 
                local amount = 
                    tonumber( 
                        guiGetText( 
                            rentEdit 
                        ) 
                    ) 
 
                if not amount then 
 
                    outputChatBox( 
 
                        "[StarsCity] Meghdar Eshtebah Ast.", 
 
                        255, 
                        70, 
                        70 
 
                    ) 
 
                    return 
 
                end 
 
                if amount > 30000000 then 
 
                    outputChatBox( 
 
                        "[StarsCity] Rent Price Bishtar Az $30,000,000 Nemitavanad Bashad.", 
 
                        255, 
                        70, 
                        70 
 
                    ) 
 
                    return 
 
                end 
 
                triggerServerEvent( 
 
                    "scHouseSetRentPrice", 
 
                    localPlayer, 
 
                    currentMyHouseID, 
 
                    amount 
 
                ) 
 
            end, 
 
            false 
 
        ) 
 
 
        -- ================================================= 
        -- HOUSE PRICE 
        -- ================================================= 
 
        local housePriceLabel = 
            guiCreateLabel( 
 
                25, 
                470, 
 
                150, 
                30, 
 
                "💰 House Price :", 
 
                false, 
                myHouseWindow 
 
            ) 
 
        guiLabelSetColor( 
            housePriceLabel, 
            COLOR_YELLOW[1], 
            COLOR_YELLOW[2], 
            COLOR_YELLOW[3] 
        ) 
 
 
        local housePriceEdit = 
            guiCreateEdit( 
 
                175, 
                465, 
 
                190, 
                40, 
 
                tostring( 
                    price or 0 
                ), 
 
                false, 
                myHouseWindow 
 
            ) 
 
        guiEditSetMaxLength( 
            housePriceEdit, 
            10 
        ) 
 
 
        local priceSave = 
            guiCreateButton( 
 
                375, 
                465, 
 
                70, 
                40, 
 
                "Set", 
 
                false, 
                myHouseWindow 
 
            ) 
 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            priceSave, 
 
            function() 
 
                local amount = 
                    tonumber( 
                        guiGetText( 
                            housePriceEdit 
                        ) 
                    ) 
 
                if not amount then 
 
                    outputChatBox( 
 
                        "[StarsCity] Meghdar Eshtebah Ast.", 
 
                        255, 
                        70, 
                        70 
 
                    ) 
 
                    return 
 
                end 
 
                if amount > 500000000 then 
 
                    outputChatBox( 
 
                        "[StarsCity] House Price Bishtar Az $500,000,000 Nemitavanad Bashad.", 
 
                        255, 
                        70, 
                        70 
 
                    ) 
 
                    return 
 
                end 
 
                triggerServerEvent( 
 
                    "scHouseSetPrice", 
 
                    localPlayer, 
 
                    currentMyHouseID, 
 
                    amount 
 
                ) 
 
            end, 
 
            false 
 
        ) 
 
 
        -- ================================================= 
        -- CLOSE 
        -- ================================================= 
 
        local closeButton = 
            guiCreateButton( 
 
                100, 
                525, 
 
                300, 
                40, 
 
                "Close", 
 
                false, 
                myHouseWindow 
 
            ) 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            closeButton, 
 
            function() 
 
                closeMyHousePanel() 
 
            end, 
 
            false 
 
        ) 
 
 
        showCursor(true) 
 
    end 
) 
 
 
-- ========================================================= 
-- UPDATE RENTERS 
-- ========================================================= 
 
addEvent( 
    "scUpdateMyHouseRenters", 
    true 
) 
 
addEventHandler( 
    "scUpdateMyHouseRenters", 
    root, 
 
    function(renters) 
 
        if not isElement( 
            renterGrid 
        ) then 
            return 
        end 
 
        guiGridListClear( 
            renterGrid 
        ) 
 
        selectedRenterID = nil 
 
        for _, renter in ipairs( 
            renters or {} 
        ) do 
 
            local row = 
                guiGridListAddRow( 
                    renterGrid 
                ) 
 
            -- RENTER NAME 
            guiGridListSetItemText( 
 
                renterGrid, 
                row, 
                1, 
 
                tostring( 
                    renter.player_name 
                ), 
 
                false, 
                false 
 
            ) 
 
            guiGridListSetItemColor( 
 
                renterGrid, 
                row, 
                1, 
 
                COLOR_TURQUOISE[1], 
                COLOR_TURQUOISE[2], 
                COLOR_TURQUOISE[3] 
 
            ) 
 
 
            -- RENTER ID 
            guiGridListSetItemText( 
 
                renterGrid, 
                row, 
                2, 
 
                tostring( 
                    renter.player_id 
                ), 
 
                false, 
                false 
 
            ) 
 
            guiGridListSetItemColor( 
 
                renterGrid, 
                row, 
                2, 
 
                COLOR_PINK[1], 
                COLOR_PINK[2], 
                COLOR_PINK[3] 
 
            ) 
 
 
            guiGridListSetItemData( 
 
                renterGrid, 
                row, 
                1, 
 
                renter.player_id 
 
            ) 
 
        end 
 
    end 
) 
 
 
-- ========================================================= 
-- UPDATE HOUSE STATE 
-- ========================================================= 
 
addEvent( 
    "scUpdateMyHouseState", 
    true 
) 
 
addEventHandler( 
    "scUpdateMyHouseState", 
    root, 
 
    function( 
        locked, 
        rentPrice, 
        housePrice 
    ) 
 
        outputChatBox( 
 
            "[StarsCity] House Settings Updated.", 
 
            80, 
            220, 
            120 
 
        ) 
 
    end 
) 
 
 
-- ========================================================= 
-- CLOSE HOUSE PANEL 
-- ========================================================= 
 
addEvent( 
    "scCloseHousePanel", 
    true 
) 
 
addEventHandler( 
    "scCloseHousePanel", 
    root, 
 
    function() 
 
        closeHousePanel() 
 
    end 
) 
 
 
-- ========================================================= 
-- HOUSE MESSAGE 
-- ========================================================= 
 
addEvent( 
    "scHouseMessage", 
    true 
) 
 
addEventHandler( 
    "scHouseMessage", 
    root, 
 
    function( 
        success, 
        message 
    ) 
 
        outputChatBox( 
 
            "[StarsCity] " 
            .. tostring(message), 
 
            success and 80 or 255, 
            success and 220 or 70, 
            success and 120 or 70 
 
        ) 
 
    end 
) 
 
 
-- ========================================================= 
-- ESC 
-- ========================================================= 
 
bindKey( 
 
    "escape", 
    "down", 
 
    function() 
 
        if isElement(houseWindow) then 
 
            closeHousePanel() 
 
            return 
 
        end 
 
        if isElement(myHouseWindow) then 
 
            closeMyHousePanel() 
 
        end 
 
    end 
 
) 
 
-- ========================================================= 
-- HOUSE EXIT PANEL 
-- ========================================================= 
 
local houseExitWindow = nil 
local currentExitHouseID = nil 
 
 
-- ========================================================= 
-- CLOSE EXIT PANEL 
-- ========================================================= 
 
local function closeHouseExitPanel() 
 
    if isElement(houseExitWindow) then 
 
        destroyElement( 
            houseExitWindow 
        ) 
 
    end 
 
 
    houseExitWindow = nil 
    currentExitHouseID = nil 
 
    showCursor(false) 
 
end 
 
 
-- ========================================================= 
-- OPEN EXIT PANEL 
-- ========================================================= 
 
addEvent( 
    "scOpenHouseExitPanel", 
    true 
) 
 
 
addEventHandler( 
    "scOpenHouseExitPanel", 
    root, 
 
    function(houseID) 
 
        closeHouseExitPanel() 
 
 
        currentExitHouseID = 
            tonumber(houseID) 
 
 
        local sx, sy = 
            guiGetScreenSize() 
 
 
        -- ================================================= 
        -- WINDOW 
        -- ================================================= 
 
        houseExitWindow = 
            guiCreateWindow( 
 
                sx / 2 - 150, 
                sy / 2 - 100, 
 
                300, 
                200, 
 
                "HOUSE EXIT", 
 
                false 
 
            ) 
 
 
        guiWindowSetSizable( 
            houseExitWindow, 
            false 
        ) 
 
 
        -- ================================================= 
        -- EXIT BUTTON 
        -- ================================================= 
 
        local exitButton = 
            guiCreateButton( 
 
                35, 
                55, 
 
                230, 
                45, 
 
                "Exit", 
 
                false, 
 
                houseExitWindow 
 
            ) 
 
 
        guiSetProperty( 
            exitButton, 
            "NormalTextColour", 
            "FF00FF00" 
        ) 
 
 
        -- ================================================= 
        -- CANCEL BUTTON 
        -- ================================================= 
 
        local cancelButton = 
            guiCreateButton( 
 
                35, 
                115, 
 
                230, 
                45, 
 
                "Cancel", 
 
                false, 
 
                houseExitWindow 
 
            ) 
 
 
        guiSetProperty( 
            cancelButton, 
            "NormalTextColour", 
            "FFFF0000" 
        ) 
 
 
        -- ================================================= 
        -- EXIT CLICK 
        -- ================================================= 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            exitButton, 
 
            function() 
 
                if not currentExitHouseID then 
                    return 
                end 
 
 
                triggerServerEvent( 
 
                    "scHouseExit", 
 
                    localPlayer, 
 
                    currentExitHouseID 
 
                ) 
 
            end, 
 
            false 
 
        ) 
 
 
        -- ================================================= 
        -- CANCEL CLICK 
        -- ================================================= 
 
        addEventHandler( 
 
            "onClientGUIClick", 
 
            cancelButton, 
 
            function() 
 
                closeHouseExitPanel() 
 
            end, 
 
            false 
 
        ) 
 
 
        showCursor(true) 
 
    end 
) 
 
 
-- ========================================================= 
-- CLOSE EXIT PANEL EVENT 
-- ========================================================= 
 
addEvent( 
    "scCloseHouseExitPanel", 
    true 
) 
 
 
addEventHandler( 
    "scCloseHouseExitPanel", 
    root, 
 
    function() 
 
        closeHouseExitPanel() 
 
    end 
) 
 
 
-- ========================================================= 
-- ESC 
-- ========================================================= 
 
bindKey( 
 
    "escape", 
    "down", 
 
    function() 
 
        if isElement(houseExitWindow) then 
 
            closeHouseExitPanel() 
 
        end 
 
    end 
 
) 

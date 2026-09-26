HUD = HUD or {}


local function drawHUDRoundedRectangle(x, y, w, h, r, color)

    r = math.max(0, math.min(r or 0, math.floor(math.min(w, h) / 2)))

    if r <= 0 then
        dxDrawRectangle(x, y, w, h, color)
        return
    end

    -- Non-overlapping pieces.
    -- This prevents the center from becoming darker because of alpha stacking.
    dxDrawRectangle(x + r, y, w - (r * 2), h, color)

    if h - (r * 2) > 0 then
        dxDrawRectangle(x, y + r, r, h - (r * 2), color)
        dxDrawRectangle(x + w - r, y + r, r, h - (r * 2), color)
    end

    dxDrawCircle(x + r, y + r, r, 180, 270, color)
    dxDrawCircle(x + w - r, y + r, r, 270, 360, color)
    dxDrawCircle(x + r, y + h - r, r, 90, 180, color)
    dxDrawCircle(x + w - r, y + h - r, r, 0, 90, color)

end



function HUD:render()

    -- Hide HUD before player login
    if not getElementData(localPlayer, "account:loggedIn") then
        return
    end

    for name, pos in pairs(HUD.positions) do

        if self:isVisible(name) then

            local element = self:getElement(name)

            if element then

                local value = element.getValue()

                if name == "wanted" then

                    local wantedWidth = pos.width
                    local wantedHeight = pos.height

                    if HUD.theme and HUD.theme.getComponentSize then
                        wantedWidth, wantedHeight = HUD.theme:getComponentSize(
                            "wanted",
                            pos.width,
                            pos.height
                        )
                    end

                    local opacity = 180

                    if HUD.theme
                    and HUD.theme.background
                    and HUD.theme.background.opacity then
                        opacity = HUD.theme.background.opacity
                    end

                    local radius = 12

                    if HUD.theme and HUD.theme.borderRadius then
                        radius = HUD.theme.borderRadius
                    end

                    drawHUDRoundedRectangle(
                        pos.x,
                        pos.y,
                        wantedWidth,
                        wantedHeight,
                        radius,
                        tocolor(0,0,0,opacity)
                    )

                    self:drawWanted(
                        pos.x,
                        pos.y,
                        value,
                        wantedWidth,
                        wantedHeight
                    )

                else

                    local component = nil

                    if HUD.theme and HUD.theme.components then
                        component = HUD.theme.components[name]
                    end

                    local boxWidth = pos.width
                    local boxHeight = pos.height

                    if HUD.theme and HUD.theme.getComponentSize then
                        boxWidth, boxHeight = HUD.theme:getComponentSize(
                            name,
                            pos.width,
                            pos.height
                        )
                    elseif component and component.sizes then

                        local preset = (HUD.theme and HUD.theme.currentTextSize) or "medium"
                        local boxSize = component.sizes[preset] or component.sizes.medium

                        if boxSize then
                            boxWidth = boxSize.width or boxWidth
                            boxHeight = boxSize.height or boxHeight
                        end

                    end

                    local opacity = 180

                    if HUD.theme
                    and HUD.theme.background
                    and HUD.theme.background.opacity then
                        opacity = HUD.theme.background.opacity
                    end

                    local radius = 12

                    if HUD.theme and HUD.theme.borderRadius then
                        radius = HUD.theme.borderRadius
                    end

                    drawHUDRoundedRectangle(
                        pos.x,
                        pos.y,
                        boxWidth,
                        boxHeight,
                        radius,
                        tocolor(0,0,0,opacity)
                    )

                    local scale = 1

                    if HUD.theme
                    and HUD.theme.getTextScale then
                        scale = HUD.theme:getTextScale()
                    end

                    if component and component.textScale then
                        scale = scale * component.textScale
                    end

                    local font = "default"

                    if HUD.theme
                    and HUD.theme.getFont then
                        font = HUD.theme:getFont()
                    end

                    if name == "player" then

                        -- player.lua remains the only source of username + ID.
                        -- Expected example: RedStar [1]
                        local playerValue = tostring(value)
                        local playerName, idText = playerValue:match("^(.-)(%s+%[[^%]]+%])$")

                        if not playerName or not idText then

                            local totalWidth = dxGetTextWidth(playerValue, scale, font)
                            local startX = pos.x + ((boxWidth - totalWidth) / 2)

                            dxDrawText(
                                playerValue,
                                startX,
                                pos.y,
                                pos.x + boxWidth,
                                pos.y + boxHeight,
                                tocolor(255,255,255,255),
                                scale,
                                font,
                                "left",
                                "center"
                            )

                        else

                            local nameWidth = dxGetTextWidth(playerName, scale, font)
                            local idWidth = dxGetTextWidth(idText, scale, font)
                            local totalWidth = nameWidth + idWidth
                            local startX = pos.x + ((boxWidth - totalWidth) / 2)

                            dxDrawText(
                                playerName,
                                startX,
                                pos.y,
                                pos.x + boxWidth,
                                pos.y + boxHeight,
                                tocolor(255,255,255,255),
                                scale,
                                font,
                                "left",
                                "center"
                            )

                            local r, g, b = 255, 255, 255

                            if HUD.theme and HUD.theme.getIconTextColor then
                                r, g, b = HUD.theme:getIconTextColor()
                            end

                            dxDrawText(
                                idText,
                                startX + nameWidth,
                                pos.y,
                                pos.x + boxWidth,
                                pos.y + boxHeight,
                                tocolor(r,g,b,255),
                                scale,
                                font,
                                "left",
                                "center"
                            )

                        end

                    else

                        local text = tostring(value)
                        local textWidth = dxGetTextWidth(text, scale, font)

                        local iconPath = nil
                        local iconSize = 0
                        local gap = 0

                        if pos.icon and HUD.assets then

                            if HUD.assets.getIcon then
                                iconPath = HUD.assets:getIcon(pos.icon)
                            elseif HUD.assets[pos.icon] then
                                iconPath = HUD.assets[pos.icon]
                            end

                            if iconPath then

                                iconSize = 30

                                if HUD.theme and HUD.theme.getIconSize then
                                    iconSize = HUD.theme:getIconSize(pos.icon)
                                end

                                if component and component.iconScale then
                                    iconSize = iconSize * component.iconScale
                                end

                                gap = (component and component.gap) or 10

                            end

                        end

                        local groupWidth = textWidth

                        if iconPath then
                            groupWidth = iconSize + gap + textWidth
                        end

                        -- Center the whole "icon + text" group inside its box.
                        local startX = pos.x + ((boxWidth - groupWidth) / 2)
                        local textX = startX

                        if iconPath then

                            local iconY = pos.y + ((boxHeight - iconSize) / 2)

                            dxDrawImage(
                                startX,
                                iconY,
                                iconSize,
                                iconSize,
                                iconPath
                            )

                            textX = startX + iconSize + gap

                        end

                        dxDrawText(
                            text,
                            textX,
                            pos.y,
                            pos.x + boxWidth,
                            pos.y + boxHeight,
                            tocolor(255,255,255,255),
                            scale,
                            font,
                            "left",
                            "center"
                        )

                    end


                end

            end

        end

    end

end



function HUD:drawWanted(x,y,wanted,boxWidth,boxHeight)

    local size = 32

    if HUD.theme
    and HUD.theme.getIconSize then
        size = HUD.theme:getIconSize("wanted")
    end

    local gap = 5

    if HUD.theme and HUD.theme.components and HUD.theme.components.wanted then

        local wantedConfig = HUD.theme.components.wanted

        if wantedConfig.iconScale then
            size = size * wantedConfig.iconScale
        end

        if wantedConfig.gap then
            gap = wantedConfig.gap
        end

    end

    local totalWidth = (6 * size) + (5 * gap)

    local startX = x
    local startY = y

    if boxWidth then
        startX = x + ((boxWidth - totalWidth) / 2)
    end

    if boxHeight then
        startY = y + ((boxHeight - size) / 2)
    end


    for i = 1,6 do

        local image = HUD.assets.starOff


        if i <= wanted then

            image = HUD.assets.starOn

        end


        dxDrawImage(

            startX + ((i-1)*(size+gap)),
            startY,
            size,
            size,
            image

        )

    end

end
 
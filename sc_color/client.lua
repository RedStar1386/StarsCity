local open = false
local sx, sy = guiGetScreenSize()
local positionFile = "panel_position.xml"

local panel = {
    w = 470,
    h = 392,
}
local function clampPanelPosition(x, y)
    return math.max(0, math.min(x, sx - panel.w)), math.max(0, math.min(y, sy - panel.h))
end

local function loadPanelPosition()
    if fileExists(positionFile) then
        local xml = xmlLoadFile(positionFile)
        if xml then
            local x = tonumber(xmlNodeGetAttribute(xml, "x"))
            local y = tonumber(xmlNodeGetAttribute(xml, "y"))
            if x and y then
                panel.x, panel.y = clampPanelPosition(x, y)
                xmlUnloadFile(xml)
                return
            end
            xmlUnloadFile(xml)
        end
    end
    panel.x = sx - panel.w
    panel.y = (sy - panel.h) / 2
end

local function savePanelPosition()
    local xml = xmlCreateFile(positionFile, "panel")
    if xml then
        xmlNodeSetAttribute(xml, "x", tostring(math.floor(panel.x)))
        xmlNodeSetAttribute(xml, "y", tostring(math.floor(panel.y)))
        xmlSaveFile(xml)
        xmlUnloadFile(xml)
    end
end

loadPanelPosition()

local color = {
    h = 0,
    s = 1,
    v = 1,
    r = 255,
    g = 0,
    b = 0,
    a = 255,
}

local originalColor = { r = 255, g = 0, b = 0, a = 255 }
local dragMode = nil
local historyColors = {}
local pickerCallbackEvent = nil
local cursorWasShowing = false
local previousInputMode = nil
local controlStates = {}
local PICKER_CONTROLS = {
    "fire", "aim_weapon", "next_weapon", "previous_weapon",
    "forwards", "backwards", "left", "right", "jump", "sprint", "crouch",
    "enter_exit", "vehicle_fire", "vehicle_secondary_fire", "vehicle_left",
    "vehicle_right", "accelerate", "brake_reverse", "handbrake", "horn",
    "vehicle_look_left", "vehicle_look_right", "vehicle_look_behind",
    "vehicle_mouse_look", "special_control_left", "special_control_right",
    "special_control_up", "special_control_down"
}

local panelDragging = false
local panelDragOffsetX, panelDragOffsetY = 0, 0

local input = {
    active = nil,
    fields = {
        hex = "FF0000",
        r = "255",
        g = "0",
        b = "0",
    }
}

local presets = {
    {255, 0, 0},      -- red
    {255, 128, 0},    -- orange
    {255, 255, 0},    -- yellow
    {0, 255, 0},      -- green
    {0, 255, 255},    -- ice blue
    {0, 90, 255},     -- blue
    {128, 0, 255},    -- purple
    {255, 105, 180},  -- pink
    {139, 69, 19},    -- brown
    {0, 0, 0},        -- black
    {128, 128, 128},  -- gray
    {255, 255, 255},  -- white
}

local function clamp(v, minv, maxv)
    if v < minv then return minv end
    if v > maxv then return maxv end
    return v
end

local function hsvToRgb(h, s, v)
    h = h % 360
    s = clamp(s, 0, 1)
    v = clamp(v, 0, 1)

    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local rr, gg, bb = 0, 0, 0

    if h < 60 then
        rr, gg, bb = c, x, 0
    elseif h < 120 then
        rr, gg, bb = x, c, 0
    elseif h < 180 then
        rr, gg, bb = 0, c, x
    elseif h < 240 then
        rr, gg, bb = 0, x, c
    elseif h < 300 then
        rr, gg, bb = x, 0, c
    else
        rr, gg, bb = c, 0, x
    end

    return math.floor((rr + m) * 255 + 0.5), math.floor((gg + m) * 255 + 0.5), math.floor((bb + m) * 255 + 0.5)
end

local function rgbToHsv(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local maxv = math.max(r, g, b)
    local minv = math.min(r, g, b)
    local delta = maxv - minv

    local h = 0
    if delta == 0 then
        h = 0
    elseif maxv == r then
        h = 60 * (((g - b) / delta) % 6)
    elseif maxv == g then
        h = 60 * (((b - r) / delta) + 2)
    else
        h = 60 * (((r - g) / delta) + 4)
    end

    local s = maxv == 0 and 0 or (delta / maxv)
    local v = maxv
    return h, s, v
end

local function syncInputsFromColor()
    input.fields.hex = string.format("%02X%02X%02X", color.r, color.g, color.b)
    input.fields.r = tostring(color.r)
    input.fields.g = tostring(color.g)
    input.fields.b = tostring(color.b)
end

local function updateColorFromHSV()
    color.r, color.g, color.b = hsvToRgb(color.h, color.s, color.v)
    syncInputsFromColor()
end

local function updateColorFromRGB(r, g, b)
    color.r = clamp(math.floor(r + 0.5), 0, 255)
    color.g = clamp(math.floor(g + 0.5), 0, 255)
    color.b = clamp(math.floor(b + 0.5), 0, 255)
    color.h, color.s, color.v = rgbToHsv(color.r, color.g, color.b)
    syncInputsFromColor()
end

local function commitActiveField()
    if not input.active then return end

    if input.active == "hex" then
        local hex = (input.fields.hex or ""):gsub("#", ""):upper()
        if #hex == 6 and hex:match("^[0-9A-F]+$") then
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            updateColorFromRGB(r, g, b)
        else
            syncInputsFromColor()
        end
    else
        local r = tonumber(input.fields.r)
        local g = tonumber(input.fields.g)
        local b = tonumber(input.fields.b)
        if r and g and b then
            updateColorFromRGB(clamp(r, 0, 255), clamp(g, 0, 255), clamp(b, 0, 255))
        else
            syncInputsFromColor()
        end
    end
end

local function isMouseIn(x, y, w, h, mx, my)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local function drawRoundedRect(x, y, w, h, colorValue, radius)
    radius = math.floor(math.min(radius or 8, w / 2, h / 2))
    if radius < 1 then
        dxDrawRectangle(x, y, w, h, colorValue)
        return
    end

    dxDrawRectangle(x + radius, y, w - radius * 2, h, colorValue)
    dxDrawRectangle(x, y + radius, radius, h - radius * 2, colorValue)
    dxDrawRectangle(x + w - radius, y + radius, radius, h - radius * 2, colorValue)

    dxDrawCircle(x + radius, y + radius, radius, 180, 270, colorValue, colorValue, 12)
    dxDrawCircle(x + w - radius, y + radius, radius, 270, 360, colorValue, colorValue, 12)
    dxDrawCircle(x + radius, y + h - radius, radius, 90, 180, colorValue, colorValue, 12)
    dxDrawCircle(x + w - radius, y + h - radius, radius, 0, 90, colorValue, colorValue, 12)
end

local function drawRoundedBorderedRect(x, y, w, h, bgColor, borderColor, radius)
    drawRoundedRect(x, y, w, h, borderColor, radius)
    drawRoundedRect(x + 1, y + 1, w - 2, h - 2, bgColor, math.max(0, (radius or 8) - 1))
end

local function getLayout()
    local x, y = panel.x, panel.y
    return {
        sv = {x = x + 18, y = y + 56, w = 222, h = 180},
        hue = {x = x + 18, y = y + 248, w = 222, h = 14},
        history = {x = x + 18, y = y + 266, size = 16, gap = 4, max = 10},
        dividerY = y + 288,
        preset = {x = x + 18, y = y + 298, size = 16, gap = 4, cols = 6},

        rightX = x + 252,
        previewCurrent = {x = x + 252, y = y + 56, w = 200, h = 50},
        previewOld = {x = x + 252, y = y + 116, w = 200, h = 50},

        fields = {
            hex = {x = x + 252, y = y + 190, w = 94, h = 38, label = "HEX"},
            r   = {x = x + 350, y = y + 190, w = 30, h = 38, label = "R"},
            g   = {x = x + 384, y = y + 190, w = 30, h = 38, label = "G"},
            b   = {x = x + 418, y = y + 190, w = 30, h = 38, label = "B"},
            a   = {x = x + 252, y = y + 248, w = 200, h = 22, label = "Alpha / Opacity"},
        },

        copy = {x = x + 252, y = y + 292, w = 96, h = 30},
        paste = {x = x + 356, y = y + 292, w = 96, h = 30},
        apply = {x = x + 252, y = y + 334, w = 96, h = 30},
        cancel = {x = x + 356, y = y + 334, w = 96, h = 30},
    }
end

local function drawInputField(name, cfg)
    local active = input.active == name
    local borderColor = active and tocolor(86, 140, 220, 255) or tocolor(72, 72, 72, 255)
    drawRoundedBorderedRect(cfg.x, cfg.y, cfg.w, cfg.h, tocolor(34, 34, 34, 240), borderColor, 7)

    local value = input.fields[name] or ""
    local display = (name == "hex" and ("#" .. value) or value)
    local caret = active and (getTickCount() % 1000 < 500)
    if caret then
        display = display .. "|"
    end

    dxDrawText(display, cfg.x + 7, cfg.y + 4, cfg.x + cfg.w - 7, cfg.y + 20, tocolor(245, 245, 245, 255), 1.0, "default-bold", "left", "top", true, false, false)
    dxDrawText(cfg.label, cfg.x, cfg.y + 20, cfg.x + cfg.w, cfg.y + cfg.h - 2, tocolor(180, 180, 180, 255), 0.95, "default", "center", "center")
end

local function updateSVFromMouse(mx, my)
    local l = getLayout().sv
    color.s = clamp((mx - l.x) / l.w, 0, 1)
    color.v = clamp(1 - ((my - l.y) / l.h), 0, 1)
    updateColorFromHSV()
end

local function updateHueFromMouse(mx)
    local l = getLayout().hue
    color.h = clamp((mx - l.x) / l.w, 0, 1) * 360
    updateColorFromHSV()
end

local function updateAlphaFromMouse(mx)
    local a = getLayout().fields.a
    color.a = clamp(math.floor(((mx - a.x) / a.w) * 255 + 0.5), 0, 255)
end

local function pushHistory()
    local item = {color.r, color.g, color.b}
    for i, v in ipairs(historyColors) do
        if v[1] == item[1] and v[2] == item[2] and v[3] == item[3] then
            table.remove(historyColors, i)
            break
        end
    end
    table.insert(historyColors, 1, item)
    while #historyColors > 10 do
        table.remove(historyColors)
    end
end

local function setHistory(list)
    historyColors = list or {}
end

local function getReadableTextColor(r, g, b)
    local brightness = (r * 0.299) + (g * 0.587) + (b * 0.114)
    if brightness > 150 then
        return tocolor(20, 20, 20, 220)
    end
    return tocolor(255, 255, 255, 235)
end

local function renderColorPicker()
    if not open then return end

    local l = getLayout()
    drawRoundedBorderedRect(panel.x, panel.y, panel.w, panel.h, tocolor(27, 27, 27, 245), tocolor(62, 62, 62, 255), 12)
    dxDrawText("Color Picker", panel.x, panel.y + 12, panel.x + panel.w, panel.y + 36, tocolor(255, 255, 255, 255), 1.2, "default-bold", "center", "center")

    drawRoundedBorderedRect(l.sv.x, l.sv.y, l.sv.w, l.sv.h, tocolor(0, 0, 0, 255), tocolor(66, 66, 66, 255), 9)
    for xx = 0, l.sv.w - 1, 4 do
        for yy = 0, l.sv.h - 1, 4 do
            local s = xx / l.sv.w
            local v = 1 - (yy / l.sv.h)
            local rr, gg, bb = hsvToRgb(color.h, s, v)
            dxDrawRectangle(l.sv.x + xx, l.sv.y + yy, 4, 4, tocolor(rr, gg, bb, 255))
        end
    end

    local cx = l.sv.x + color.s * l.sv.w
    local cy = l.sv.y + (1 - color.v) * l.sv.h
    dxDrawRectangle(cx - 7, cy, 15, 1, tocolor(255, 255, 255, 230))
    dxDrawRectangle(cx, cy - 7, 1, 15, tocolor(255, 255, 255, 230))
    dxDrawRectangle(cx - 5, cy - 5, 11, 1, tocolor(0, 0, 0, 220))
    dxDrawRectangle(cx - 5, cy + 5, 11, 1, tocolor(0, 0, 0, 220))
    dxDrawRectangle(cx - 5, cy - 4, 1, 9, tocolor(0, 0, 0, 220))
    dxDrawRectangle(cx + 5, cy - 4, 1, 9, tocolor(0, 0, 0, 220))

    drawRoundedBorderedRect(l.hue.x, l.hue.y, l.hue.w, l.hue.h, tocolor(0, 0, 0, 255), tocolor(66, 66, 66, 255), 6)
    for xx = 0, l.hue.w - 1, 2 do
        local h = (xx / l.hue.w) * 360
        local rr, gg, bb = hsvToRgb(h, 1, 1)
        dxDrawRectangle(l.hue.x + xx, l.hue.y, 2, l.hue.h, tocolor(rr, gg, bb, 255))
    end
    local hx = l.hue.x + (color.h / 360) * l.hue.w
    dxDrawRectangle(hx - 2, l.hue.y - 3, 4, l.hue.h + 6, tocolor(255, 255, 255, 240))
    dxDrawRectangle(hx - 1, l.hue.y - 2, 2, l.hue.h + 4, tocolor(0, 0, 0, 220))

    dxDrawLine(panel.x + 18, l.dividerY, panel.x + 240, l.dividerY, tocolor(80, 80, 80, 220), 1)

    for i = 1, math.min(#historyColors, l.history.max) do
        local rgb = historyColors[i]
        local x = l.history.x + (i - 1) * (l.history.size + l.history.gap)
        drawRoundedBorderedRect(x, l.history.y, l.history.size, l.history.size, tocolor(rgb[1], rgb[2], rgb[3], 255), tocolor(82, 82, 82, 255), 4)
    end

    for i, rgb in ipairs(presets) do
        local col = (i - 1) % l.preset.cols
        local row = math.floor((i - 1) / l.preset.cols)
        local x = l.preset.x + col * (l.preset.size + l.preset.gap)
        local y = l.preset.y + row * (l.preset.size + l.preset.gap)
        local border = (color.r == rgb[1] and color.g == rgb[2] and color.b == rgb[3]) and tocolor(255, 255, 255, 230) or tocolor(82, 82, 82, 255)
        drawRoundedBorderedRect(x, y, l.preset.size, l.preset.size, tocolor(rgb[1], rgb[2], rgb[3], 255), border, 4)
    end

    drawRoundedBorderedRect(l.previewCurrent.x, l.previewCurrent.y, l.previewCurrent.w, l.previewCurrent.h, tocolor(color.r, color.g, color.b, color.a), tocolor(66, 66, 66, 255), 8)
    dxDrawText("#" .. string.format("%02X%02X%02X", color.r, color.g, color.b), l.previewCurrent.x, l.previewCurrent.y, l.previewCurrent.x + l.previewCurrent.w, l.previewCurrent.y + l.previewCurrent.h, getReadableTextColor(color.r, color.g, color.b), 1.0, "default-bold", "center", "center")

    drawRoundedBorderedRect(l.previewOld.x, l.previewOld.y, l.previewOld.w, l.previewOld.h, tocolor(originalColor.r, originalColor.g, originalColor.b, originalColor.a or 255), tocolor(66, 66, 66, 255), 8)
    dxDrawText("#" .. string.format("%02X%02X%02X", originalColor.r, originalColor.g, originalColor.b), l.previewOld.x, l.previewOld.y, l.previewOld.x + l.previewOld.w, l.previewOld.y + l.previewOld.h, getReadableTextColor(originalColor.r, originalColor.g, originalColor.b), 1.0, "default-bold", "center", "center")

    drawInputField("hex", l.fields.hex)
    drawInputField("r", l.fields.r)
    drawInputField("g", l.fields.g)
    drawInputField("b", l.fields.b)

    dxDrawText("Alpha / Opacity", l.fields.a.x, l.fields.a.y - 18, l.fields.a.x + 120, l.fields.a.y - 2, tocolor(184, 184, 184, 255), 0.98, "default-bold", "left", "center")
    drawRoundedBorderedRect(l.fields.a.x, l.fields.a.y, l.fields.a.w, l.fields.a.h, tocolor(42, 42, 42, 255), tocolor(66, 66, 66, 255), 7)
    drawRoundedRect(l.fields.a.x + 1, l.fields.a.y + 1, math.max(0, (l.fields.a.w - 2) * (color.a / 255)), l.fields.a.h - 2, tocolor(color.r, color.g, color.b, 190), 6)
    dxDrawText(string.format("%d%%", math.floor((color.a / 255) * 100 + 0.5)), l.fields.a.x, l.fields.a.y, l.fields.a.x + l.fields.a.w, l.fields.a.y + l.fields.a.h, tocolor(255, 255, 255, 255), 0.95, "default-bold", "center", "center")

    drawRoundedBorderedRect(l.copy.x, l.copy.y, l.copy.w, l.copy.h, tocolor(48, 48, 48, 255), tocolor(78, 78, 78, 255), 8)
    dxDrawText("Copy HEX", l.copy.x, l.copy.y, l.copy.x + l.copy.w, l.copy.y + l.copy.h, tocolor(255, 255, 255, 255), 1, "default-bold", "center", "center")
    drawRoundedBorderedRect(l.paste.x, l.paste.y, l.paste.w, l.paste.h, tocolor(48, 48, 48, 255), tocolor(78, 78, 78, 255), 8)
    dxDrawText("Paste HEX", l.paste.x, l.paste.y, l.paste.x + l.paste.w, l.paste.y + l.paste.h, tocolor(255, 255, 255, 255), 1, "default-bold", "center", "center")

    drawRoundedBorderedRect(l.apply.x, l.apply.y, l.apply.w, l.apply.h, tocolor(66, 120, 83, 255), tocolor(89, 140, 106, 255), 8)
    dxDrawText("Apply", l.apply.x, l.apply.y, l.apply.x + l.apply.w, l.apply.y + l.apply.h, tocolor(255, 255, 255, 255), 1, "default-bold", "center", "center")
    drawRoundedBorderedRect(l.cancel.x, l.cancel.y, l.cancel.w, l.cancel.h, tocolor(120, 65, 65, 255), tocolor(145, 88, 88, 255), 8)
    dxDrawText("Cancel", l.cancel.x, l.cancel.y, l.cancel.x + l.cancel.w, l.cancel.y + l.cancel.h, tocolor(255, 255, 255, 255), 1, "default-bold", "center", "center")
end


local function captureAndDisableControls()
    controlStates = {}
    for _, controlName in ipairs(PICKER_CONTROLS) do
        local enabled = true
        if type(isControlEnabled) == "function" then
            enabled = isControlEnabled(controlName) == true
        end
        controlStates[controlName] = enabled
        toggleControl(controlName, false)
    end
end

local function restoreCapturedControls()
    for controlName, wasEnabled in pairs(controlStates) do
        toggleControl(controlName, wasEnabled == true)
    end
    controlStates = {}
end

local function clearPickerSession()
    pickerCallbackEvent = nil
    input.active = nil
    dragMode = nil
    panelDragging = false
end


-- Public API for other resources.
-- callbackEvent: client event triggered on Apply with (r, g, b, a).
-- initialR/G/B/A: optional initial color shown as Previous/Current.
local openPanel
local closePanel

function openColorPicker(callbackEvent, initialR, initialG, initialB, initialA)
    -- Close any previous session first, then register the new callback. This prevents
    -- an old consumer callback from leaking into a later standalone /color session.
    if open and closePanel then
        closePanel(true)
    end

    if callbackEvent and type(callbackEvent) == "string" and callbackEvent ~= "" then
        pickerCallbackEvent = callbackEvent
    else
        pickerCallbackEvent = nil
    end

    local r = tonumber(initialR)
    local g = tonumber(initialG)
    local b = tonumber(initialB)
    local a = tonumber(initialA)
    if r and g and b then
        updateColorFromRGB(clamp(r, 0, 255), clamp(g, 0, 255), clamp(b, 0, 255))
        color.a = clamp(a or 255, 0, 255)
    end

    openPanel()
    return true
end

openPanel = function()
    if open then return true end
    open = true
    cursorWasShowing = isCursorShowing()
    previousInputMode = type(guiGetInputMode) == "function" and guiGetInputMode() or nil
    showCursor(true)
    captureAndDisableControls()
    guiSetInputMode("no_binds_when_editing")
    input.active = nil
    dragMode = nil
    originalColor = {r = color.r, g = color.g, b = color.b, a = color.a}
    triggerServerEvent("scColorPicker:requestHistory", resourceRoot)
    addEventHandler("onClientRender", root, renderColorPicker)
    return true
end

closePanel = function(clearCallback)
    if not open then
        if clearCallback then
            clearPickerSession()
        end
        return true
    end

    commitActiveField()
    open = false
    savePanelPosition()
    removeEventHandler("onClientRender", root, renderColorPicker)
    restoreCapturedControls()

    if not cursorWasShowing then
        showCursor(false)
    end

    if previousInputMode and previousInputMode ~= "" then
        guiSetInputMode(previousInputMode)
    else
        guiSetInputMode("allow_binds")
    end

    cursorWasShowing = false
    previousInputMode = nil
    input.active = nil
    dragMode = nil
    panelDragging = false

    if clearCallback then
        pickerCallbackEvent = nil
    end

    return true
end

addEvent("scColorPicker:open", true)
addEventHandler("scColorPicker:open", resourceRoot, function()
    if open then closePanel(true) else openPanel() end
end)

addEvent("scColorPicker:setHistory", true)
addEventHandler("scColorPicker:setHistory", resourceRoot, function(list)
    setHistory(list)
end)

addEventHandler("onClientClick", root, function(button, state, mx, my)
    if not open or button ~= "left" then return end
    local l = getLayout()

    if state == "down" then
        if isMouseIn(l.apply.x, l.apply.y, l.apply.w, l.apply.h, mx, my) then
            -- Apply is intentionally non-destructive to the picker UI: consumers receive
            -- the selected color immediately, while the picker remains open so the user
            -- can keep testing colors. Only Cancel closes the picker.
            commitActiveField()
            pushHistory()
            triggerServerEvent("scColorPicker:saveHistory", resourceRoot, historyColors)

            if pickerCallbackEvent then
                triggerEvent(pickerCallbackEvent, resourceRoot, color.r, color.g, color.b, color.a)
            end

            return
        end

        if isMouseIn(l.cancel.x, l.cancel.y, l.cancel.w, l.cancel.h, mx, my) then
            updateColorFromRGB(originalColor.r, originalColor.g, originalColor.b)
            color.a = originalColor.a
            closePanel(true)
            return
        end

        if isMouseIn(l.copy.x, l.copy.y, l.copy.w, l.copy.h, mx, my) then
            setClipboard("#" .. string.format("%02X%02X%02X", color.r, color.g, color.b))
            return
        end

        if isMouseIn(l.paste.x, l.paste.y, l.paste.w, l.paste.h, mx, my) then
            local clip = (getClipboard() or ""):gsub("#", ""):upper()
            if #clip == 6 and clip:match("^[0-9A-F]+$") then
                updateColorFromRGB(tonumber(clip:sub(1, 2), 16), tonumber(clip:sub(3, 4), 16), tonumber(clip:sub(5, 6), 16))
            end
            return
        end

        if isMouseIn(l.sv.x, l.sv.y, l.sv.w, l.sv.h, mx, my) then
            commitActiveField()
            input.active = nil
            dragMode = "sv"
            updateSVFromMouse(mx, my)
            return
        end

        if isMouseIn(l.hue.x, l.hue.y, l.hue.w, l.hue.h, mx, my) then
            commitActiveField()
            input.active = nil
            dragMode = "hue"
            updateHueFromMouse(mx)
            return
        end

        if isMouseIn(l.fields.a.x, l.fields.a.y, l.fields.a.w, l.fields.a.h, mx, my) then
            commitActiveField()
            input.active = nil
            dragMode = "alpha"
            updateAlphaFromMouse(mx)
            return
        end

        for i = 1, math.min(#historyColors, l.history.max) do
            local x = l.history.x + (i - 1) * (l.history.size + l.history.gap)
            if isMouseIn(x, l.history.y, l.history.size, l.history.size, mx, my) then
                local rgb = historyColors[i]
                updateColorFromRGB(rgb[1], rgb[2], rgb[3])
                return
            end
        end

        for i, rgb in ipairs(presets) do
            local col = (i - 1) % l.preset.cols
            local row = math.floor((i - 1) / l.preset.cols)
            local x = l.preset.x + col * (l.preset.size + l.preset.gap)
            local y = l.preset.y + row * (l.preset.size + l.preset.gap)
            if isMouseIn(x, y, l.preset.size, l.preset.size, mx, my) then
                updateColorFromRGB(rgb[1], rgb[2], rgb[3])
                return
            end
        end

        for _, key in ipairs({"hex", "r", "g", "b"}) do
            local cfg = l.fields[key]
            if isMouseIn(cfg.x, cfg.y, cfg.w, cfg.h, mx, my) then
                if input.active and input.active ~= key then
                    commitActiveField()
                end
                input.active = key
                return
            end
        end

        -- drag only empty areas of the panel
        if isMouseIn(panel.x, panel.y, panel.w, panel.h, mx, my) then
            panelDragging = true
            panelDragOffsetX = mx - panel.x
            panelDragOffsetY = my - panel.y
            return
        end

        commitActiveField()
        input.active = nil
    elseif state == "up" then
        if panelDragging then
            savePanelPosition()
        end
        panelDragging = false
        dragMode = nil
    end
end)

addEventHandler("onClientCursorMove", root, function(_, _, mx, my)
    if not open then return end

    if panelDragging then
        panel.x, panel.y = clampPanelPosition(mx - panelDragOffsetX, my - panelDragOffsetY)
        return
    end

    if not dragMode then return end
    if dragMode == "sv" then
        updateSVFromMouse(mx, my)
    elseif dragMode == "hue" then
        updateHueFromMouse(mx)
    elseif dragMode == "alpha" then
        updateAlphaFromMouse(mx)
    end
end)

addEventHandler("onClientCharacter", root, function(char)
    if not open or not input.active then return end

    if input.active == "hex" then
        char = char:upper()
        if char:match("[0-9A-F]") and #input.fields.hex < 6 then
            input.fields.hex = input.fields.hex .. char
        end
    else
        if char:match("%d") and #input.fields[input.active] < 3 then
            input.fields[input.active] = input.fields[input.active] .. char
        end
    end
end)

addEventHandler("onClientKey", root, function(button, press)
    if not press then return end

    if open and button == "escape" then
        cancelEvent()
        closePanel(true)
        return
    end

    if not open or not input.active then return end

    if button == "backspace" then
        local value = input.fields[input.active] or ""
        input.fields[input.active] = value:sub(1, #value - 1)
        cancelEvent()
    elseif button == "enter" or button == "num_enter" then
        commitActiveField()
        cancelEvent()
    elseif button == "tab" then
        commitActiveField()
        local order = {"hex", "r", "g", "b"}
        local currentIndex = 1
        for i, name in ipairs(order) do
            if name == input.active then
                currentIndex = i
                break
            end
        end
        input.active = order[(currentIndex % #order) + 1]
        cancelEvent()
    end
end)

bindKey("escape", "down", function()
    if open then
        closePanel(true)
    end
end)


addEventHandler("onClientResourceStop", resourceRoot, function()
    if open then
        -- Do not persist callback/session state across a resource restart.
        open = false
        removeEventHandler("onClientRender", root, renderColorPicker)
        restoreCapturedControls()
        if not cursorWasShowing then
            showCursor(false)
        end
        if previousInputMode and previousInputMode ~= "" then
            guiSetInputMode(previousInputMode)
        else
            guiSetInputMode("allow_binds")
        end
    end

    clearPickerSession()
    cursorWasShowing = false
    previousInputMode = nil
end)

syncInputsFromColor()

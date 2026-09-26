-- =========================================================
-- STARS CITY - GLOBAL GUI INPUT GUARD
-- Prevents MTA/game key binds (especially chat T/Y) from firing
-- while a GUI text input is focused. The typed key still reaches
-- the EditBox/Memo normally.
-- =========================================================

SC_STAFF_INPUT_GUARD = SC_STAFF_INPUT_GUARD or {}
local G = SC_STAFF_INPUT_GUARD

G.mode = "no_binds_when_editing"

function G.apply()
    if type(guiSetInputMode) == "function" then
        guiSetInputMode(G.mode)
        return true
    end
    return false
end

-- Apply once as soon as sc_staff starts. This MTA input mode is global on
-- the client and therefore also protects EditBoxes created by other panels.
addEventHandler("onClientResourceStart", resourceRoot, function()
    G.apply()
end)

-- Re-assert whenever any GUI element receives focus. This protects us if
-- another resource temporarily changes the GUI input mode later.
addEventHandler("onClientGUIFocus", root, function()
    G.apply()
end)

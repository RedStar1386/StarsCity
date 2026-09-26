HUD = HUD or {}


HUD.positionEditor = {}


HUD.positionEditor.active = false

HUD.positionEditor.dragging = false

HUD.positionEditor.selected = nil



function HUD.positionEditor:toggle()


    self.active = not self.active


    self.dragging = false


    self.selected = nil


    outputChatBox(

        "POSITION EDIT : "..tostring(self.active)

    )


end




function HUD.positionEditor:reset()

    -- RESET always returns the entire HUD to the server default profile:
    -- Small + Small default positions + default visual theme.

    if HUD.theme and HUD.theme.resetToDefault then
        HUD.theme:resetToDefault()
    elseif HUD.theme then
        HUD.theme.currentTextSize = "small"
    end

    if HUD.resetLayout then
        HUD:resetLayout("small")
    elseif HUD.setLayout then
        HUD:setLayout("small")
    end

    -- Current default visibility: every HUD element enabled.
    if HUD.settings and HUD.settings.visible then
        for name,_ in pairs(HUD.settings.visible) do
            HUD.settings.visible[name] = true
        end
    end

    outputChatBox("HUD Reset To Default (SMALL)")

end




function HUD.positionEditor:save()


    self.active = false

    self.dragging = false

    self.selected = nil


    outputChatBox(

        "POSITION SAVED"

    )

end






addEventHandler(

"onClientClick",

root,


function(button,state,cx,cy)


    if not HUD.positionEditor.active then

        return

    end



    if button=="left"
    and state=="down" then



        for name,pos in pairs(HUD.positions) do

            -- Use the same Small / Medium / Large box size
            -- that renderer.lua currently draws.
            local hitWidth = pos.width
            local hitHeight = pos.height

            if HUD.theme
            and HUD.theme.getComponentSize then

                hitWidth, hitHeight = HUD.theme:getComponentSize(
                    name,
                    pos.width,
                    pos.height
                )

            end


            if cx >= pos.x
            and cx <= pos.x + hitWidth
            and cy >= pos.y
            and cy <= pos.y + hitHeight then



                HUD.positionEditor.selected=name

                HUD.positionEditor.dragging=true


                break


            end


        end


    end



    if button=="left"
    and state=="up" then


        HUD.positionEditor.dragging=false


    end


end

)







addEventHandler(

"onClientCursorMove",

root,


function(_,_,cx,cy)



    if not HUD.positionEditor.active then

        return

    end



    if not HUD.positionEditor.dragging then

        return

    end



    local item = HUD.positionEditor.selected



    if item then


        HUD.positions[item].x = cx

        HUD.positions[item].y = cy


    end



end

)

HUD = HUD or {}


HUD.elements = {}



function HUD:registerElement(name, data)

    self.elements[name] = data

end





function HUD:getElement(name)

    return self.elements[name]

end





function HUD:isVisible(name)


    if not self.settings then

        return true

    end



    if not self.settings.visible then

        return true

    end



    if self.settings.visible[name] == false then

        return false

    end



    return true


end

require 'LeftClickRedux/LeftClickReduxOptions'

ISInventoryPage.onMouseDownOutside_pre_leftclickredux = ISInventoryPage.onMouseDownOutside

function ISInventoryPage.onMouseDownOutside(self, x, y)
    if(self.isVisible and not self.isCollapsed and (self:getMouseX() < 0 or self:getMouseY() < 0 or self:getMouseX() > self:getWidth() or self:getMouseY() > self:getHeight()) and not self.pin) then
        LeftClickRedux.inventoryClosedFlag = true;
    end
    return ISInventoryPage.onMouseDownOutside_pre_leftclickredux(self, x, y);
end
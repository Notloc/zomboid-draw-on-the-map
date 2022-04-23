require 'LeftClickRedux/LeftClickReduxOptions'

local walkToText = getText("ContextMenu_Walk_to");

ISContextMenu.addOption_pre_leftclickredux = ISContextMenu.addOption;
ISContextMenu.addOption = function(self, name, target, onSelect, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10)
	if LeftClickRedux.OPTIONS.removeDefaultWalkAction and name == walkToText then
		return;
	end
	return ISContextMenu.addOption_pre_leftclickredux(self, name, target, onSelect, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10);
end

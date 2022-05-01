require "LeftClickRedux/LeftClickRedux"

local LCR = LeftClickRedux.GLOBALS;

function runPatch()
	ISObjectClickHandler.doClickWindow_pre_lcr_patch =  ISObjectClickHandler.doClickWindow;

	ISObjectClickHandler.doClickWindow = function(object, playerNum, playerObj)
	    if LCR.preventShutWindow then
			LCR.preventShutWindow = false;
			return false;
		end
	    return ISObjectClickHandler.doClickWindow_pre_lcr_patch(object, playerNum, playerObj);
	end
end

Events.OnGameStart.Add(runPatch);
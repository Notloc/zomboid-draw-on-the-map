require "TimedActions/ISBaseTimedAction"

FaceThenExecuteTimedAction = ISBaseTimedAction:derive("FaceThenExecuteTimedAction")

function FaceThenExecuteTimedAction:isValid()
	return true;
end

function FaceThenExecuteTimedAction:waitToStart()
	if self.executeWhileTurning then
		if self.lambda then
			self.lambda();
		end
	end

	if self.isTargetWorldObject then
		self.character:faceLocationF(self.target:getWorldPosX(), self.target:getWorldPosY());
	else
		self.character:faceThisObject(self.target)
	end

	return self.character:shouldBeTurning()
end

function FaceThenExecuteTimedAction:update()
	self.character:faceThisObject(self.target)
end

function FaceThenExecuteTimedAction:start()
	if self.onStartFunc then
        local args = self.onStartArgs
        self.onStartFunc(args[1], args[2], args[3], args[4])
    end

    if self.lambda then
		self.lambda();
	end
	self:forceComplete();
end

function FaceThenExecuteTimedAction:stop()
	ISBaseTimedAction.stop(self);
	if self.onStopFunc then
        local args = self.onStopArgs
        self.onStopFunc(args[1], args[2], args[3], args[4])
    end
end

function FaceThenExecuteTimedAction:perform()
	ISBaseTimedAction.perform(self); -- needed to remove from queue / start next.
	if self.onStopFunc then
        local args = self.onStopArgs
        self.onStopFunc(args[1], args[2], args[3], args[4])
    end
end

function FaceThenExecuteTimedAction:setOnStart(func, arg1, arg2, arg3, arg4)
    self.onStartFunc = func
    self.onStartArgs = { arg1, arg2, arg3, arg4 }
end

function FaceThenExecuteTimedAction:setOnStop(func, arg1, arg2, arg3, arg4)
    self.onStopFunc = func
    self.onStopArgs = { arg1, arg2, arg3, arg4 }
end

function FaceThenExecuteTimedAction:new(character, target, lambda, executeWhileTurning)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.stopOnRun = false;
	o.character = character
	o.target = target
	o.lambda = lambda
	o.maxTime = -1
	o.executeWhileTurning = executeWhileTurning
	o.isTargetWorldObject = instanceof(target, "IsoWorldInventoryObject");
	return o
end    	

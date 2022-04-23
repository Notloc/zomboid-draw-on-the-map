require "TimedActions/ISBaseTimedAction"

DelayedCodeExecutionTimedAction = ISBaseTimedAction:derive("DelayedCodeExecutionTimedAction")

function DelayedCodeExecutionTimedAction:isValid()
	return true;
end

function DelayedCodeExecutionTimedAction:start()
    if self.lambda then
		self.lambda();
	end
	self:forceComplete();
end

function DelayedCodeExecutionTimedAction:new(character, lambda)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.stopOnRun = false;
	o.character = character
	o.lambda = lambda
	o.maxTime = -1
	return o
end

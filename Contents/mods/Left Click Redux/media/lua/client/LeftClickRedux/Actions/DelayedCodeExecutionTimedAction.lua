require "TimedActions/ISBaseTimedAction"

DelayedCodeExecutionTimedAction = ISBaseTimedAction:derive("DelayedCodeExecutionTimedAction")

function DelayedCodeExecutionTimedAction:isValid()
	return true;
end

function DelayedCodeExecutionTimedAction:start()
    if self.lambda then
		self.lambda();
	end
	if self.maxTime == -1 then
		self:forceComplete();
	end
end

function DelayedCodeExecutionTimedAction:new(character, lambda, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.stopOnRun = false;
	o.character = character
	o.lambda = lambda

	if not time then
		time = -1;
	end

	o.maxTime = time
	return o
end

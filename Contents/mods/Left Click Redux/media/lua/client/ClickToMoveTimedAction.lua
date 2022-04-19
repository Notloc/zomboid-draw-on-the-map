require "TimedActions/WalkToTimedAction"

ClickToMoveTimedAction = ISWalkToTimedAction:derive("ClickToMoveTimedAction");

function ClickToMoveTimedAction:start()
    ISWalkToTimedAction.start(self);

    if self.onStartFunc then
        local args = self.onStartArgs
        self.onStartFunc(args[1], args[2], args[3], args[4])
    end
end

function ClickToMoveTimedAction:stop()
    ISWalkToTimedAction.stop(self);

    if self.onStopFunc then
        local args = self.onStopArgs
        self.onStopFunc(args[1], args[2], args[3], args[4])
    end
end

function ClickToMoveTimedAction:perform()
    ISWalkToTimedAction.perform(self);

    if self.onStopFunc then
        local args = self.onStopArgs
        self.onStopFunc(args[1], args[2], args[3], args[4])
    end
end

function ClickToMoveTimedAction:setOnStart(func, arg1, arg2, arg3, arg4)
    self.onStartFunc = func
    self.onStartArgs = { arg1, arg2, arg3, arg4 }
end

function ClickToMoveTimedAction:setOnStop(func, arg1, arg2, arg3, arg4)
    self.onStopFunc = func
    self.onStopArgs = { arg1, arg2, arg3, arg4 }
end

function ClickToMoveTimedAction:new (character, location, additionalTest, additionalContext)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;

    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = -1;
    o.location = location;
    o.pathIndex = 0;
    o.additionalTest = additionalTest;
    o.additionalContext = additionalContext;
    return o
end

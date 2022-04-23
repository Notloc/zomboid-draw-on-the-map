require "TimedActions/WalkToTimedAction"

ClickToMoveTimedAction = ISWalkToTimedAction:derive("ClickToMoveTimedAction");

function ClickToMoveTimedAction:isValid()
    return not self.character:getVehicle()
end

function ClickToMoveTimedAction:start()
    self:updateTargetLocation(self.target)
    if self.onStartFunc then
        local args = self.onStartArgs
        self.onStartFunc(self)
    end
end

function ClickToMoveTimedAction:stop()
    ISWalkToTimedAction.stop(self);

    if self.onStopFunc then
        local args = self.onStopArgs
        self.onStopFunc(self)
    end
end

function ClickToMoveTimedAction:perform()
    ISWalkToTimedAction.perform(self);

    if self.onStopFunc then
        local args = self.onStopArgs
        self.onStopFunc(self)
    end
end

function ClickToMoveTimedAction:setOnStart(func)
    self.onStartFunc = func
end

function ClickToMoveTimedAction:setOnStop(func)
    self.onStopFunc = func
end

function ClickToMoveTimedAction:updateTargetLocation(target)
    self.target = target;
    if instanceof(target, "IsoGridSquare") or instanceof(target, "IsoObject") then
        self.character:getPathFindBehavior2():pathToLocation(target:getX(), target:getY(), target:getZ());
    else
        self.character:getPathFindBehavior2():pathToLocationF(target.x, target.y, target.z);
    end
end

function ClickToMoveTimedAction:new (character, target, additionalTest, additionalContext)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;

    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = -1;
    o.target = target;
    o.pathIndex = 0;
    o.additionalTest = additionalTest;
    o.additionalContext = additionalContext;
    return o
end

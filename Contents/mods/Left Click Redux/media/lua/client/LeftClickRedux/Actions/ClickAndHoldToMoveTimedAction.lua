require "TimedActions/ISBaseTimedAction"

ClickAndHoldToMoveTimedAction = ISBaseTimedAction:derive("ClickAndHoldToMoveTimedAction")

function ClickAndHoldToMoveTimedAction:isValid()
    return true;
end

function ClickAndHoldToMoveTimedAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function ClickAndHoldToMoveTimedAction:start()
    ISBaseTimedAction.start(self);
    self.character:getPathFindBehavior2():pathToLocationF(self.location.x, self.location.y, self.location.z);
end

function ClickAndHoldToMoveTimedAction:update()
    if instanceof(self.character, "IsoPlayer") and
        (self.character:pressedMovement(false) or self.character:pressedCancelAction()) then
            self:forceStop()
        return
    end

    self.result = self.character:getPathFindBehavior2():update();

    if self.additionalTest ~= nil then
       if self.additionalTest(self.additionalContext) then
            self:forceComplete();
            return
       end
    end
end

function ClickAndHoldToMoveTimedAction:setTargetLocation(location)
    self.character:getPathFindBehavior2():pathToLocationF(location.x, location.y, location.z);
end

function ClickAndHoldToMoveTimedAction:stop()
    ISBaseTimedAction.stop(self);
    self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil);
end

function ClickAndHoldToMoveTimedAction:perform()
    self.character:getPathFindBehavior2():cancel()
    self.character:setPath2(nil);

    ISBaseTimedAction.perform(self);
end

function ClickAndHoldToMoveTimedAction:new(character, location)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = -1;
    o.pathIndex = 0;
    o.location = location;
    return o
end

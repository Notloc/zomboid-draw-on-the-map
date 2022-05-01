require 'LeftClickRedux/LeftClickReduxOptions'
require 'LeftClickRedux/ItemUtil'
require 'LeftClickRedux/Util'

local LCR = LeftClickRedux;

LCR.clickData = {lastClickTime=0, prevX=0, prevY=0};
LCR.tickCounter = 0;
LCR.mouseDown = false;

local OPTIONS = LCR.OPTIONS;
local ENUMS = LCR.OPTIONS.ENUMS;

local HOLD_TO_MOVE_START_DELAY = 20;
local HOLD_TO_MOVE_UPDATE_DELAY = 4;

local CYAN = {r=0.1, g=0.9, b=0.6, a=1};
local YELLOW = {r=1, g=1, b=0, a=1};

function LCR.onTick()
	LCR.inventoryClosedFlag = false;

	-- OnObjectMouseUp Event was unreliable due to lack of calls when releasing over UI elements
	if not Mouse.isButtonDown(0) then
		LCR.mouseDown = false;
		LCR.tickCounter = 0;
		LCR.cancelHoldToMoveAction();
		return;
	end

	if OPTIONS.isHoldToMove and not LCR.holdToMoveAction and LCR.tickCounter >= HOLD_TO_MOVE_START_DELAY then
		local playerNumber = 0;
		local player = getSpecificPlayer(playerNumber);
		if not LCR.mouseDown or not Util.isPlayerReady(player) or Util.isPaused() then
			return;
		end

		LCR.clearActionQueue(player);
		local location = Util.findPathableLocationFromMouse(player);
		if location then
			LCR.holdToMoveAction = ClickAndHoldToMoveTimedAction:new(player, location);
			ISTimedActionQueue.add(LCR.holdToMoveAction);
			LCR.tickCounter = 0;
		end
		return;
	end

	if LCR.holdToMoveAction and LCR.tickCounter >= HOLD_TO_MOVE_UPDATE_DELAY then
		local playerNumber = 0;
		local player = getSpecificPlayer(playerNumber);
		if not LCR.mouseDown or not Util.isPlayerReady(player) or Util.isPaused() then
			return;
		end

		LCR.updateHoldToMoveAction(player);
	end

	LCR.tickCounter = LCR.tickCounter + 1;
end

function LCR.updateHoldToMoveAction(player)
	if OPTIONS.holdToMoveStyle == ENUMS.HOLD_PATHING then
		local location = Util.findPathableLocationFromMouse(player);
		if location then
			LCR.holdToMoveAction:setTargetLocation(location);
		else
			LCR.holdToMoveAction:forceComplete();
			LCR.holdToMoveAction = nil;
		end
	elseif OPTIONS.holdToMoveStyle == ENUMS.HOLD_SIMPLE then -- Its actually complicated
		local playerX = player:getX();
		local playerY = player:getY();

		local x, y = Util.findLocationFromMouse(player);
		x = x - playerX;
		y = y - playerY;

		local h = math.sqrt(x*x + y*y);
		if h < 1 * getCore():getZoom(0) then
			return
		end

		h = h * 1.75;

		local targetX = x/h + playerX;
		local targetY = y/h + playerY;
		local z = Util.roundZ(player:getZ());

		if z % 1 ~= 0 then -- Round input direction on stairs
			x, y = Util.roundInputDirectionAndNormalize(x,y);
			targetX = playerX + x;
			targetY = playerY + y;
		end

		local playerSqr = player:getSquare();
		local targetSqr = getCell():getGridSquare(targetX, targetY, z);
		local hopFlag = Util.checkHopFlagByDirection(playerSqr, x, y) or Util.checkHopFlagByDirection(targetSqr, -x, -y);

		if targetSqr and not targetSqr:isBlockedTo(playerSqr) or hopFlag then
			
			if z > 0 and targetSqr and not AdjacentFreeTileFinder.privCanStand(targetSqr) then -- Check if we're going down stairs
				z = z-1;
				targetSqr = getCell():getGridSquare(targetX, targetY, z); 
				if not targetSqr then
					return
				end
			end

			if targetSqr:getApparentZ(targetSqr:getX(), targetSqr:getY()) % 1 ~= 0 then
				targetSqr = Util.findEndOfStairs(targetSqr, x, y);
				if not targetSqr then
					return;
				end
				targetX = targetSqr:getX();
				targetY = targetSqr:getY();
				z = targetSqr:getZ();
			end
			LCR.holdToMoveAction:setTargetLocation({x=targetX, y=targetY, z=z});
		end
	end

	LCR.tickCounter = -1;
end

function LCR.onDown(object, rawX, rawY)
	LCR.mouseDown = true;
	local isDblClick = LCR.isDoubleClick(rawX, rawY);

	local playerNumber = 0;
	local player = getSpecificPlayer(playerNumber);
	if not Util.isPlayerReady(player) then
		return;
	end

	if OPTIONS.isClickOnLooseItems then
		local itemOut = {}	
		ItemUtil.findWorldObjectUnderMouse(playerNumber, object, rawX, rawY, itemOut)

		if itemOut.item then
			LCR.pickupItem(player, itemOut.item, isDblClick);
			return;
		end
	end

	if OPTIONS.isClickToInteract and object ~= nil then
		local isInteractable = Util.isInteractableObject(object);
		if isInteractable or object:getContainer() then
			LCR.moveToObject(player, object, rawX, rawY, isDblClick);
			return;
		end
	end

	if OPTIONS.isClickToMove then
		if OPTIONS.clickToMoveStyle == ENUMS.DOUBLE_CLICK and not isDblClick then
			return
		end

		local zoom = getCore():getZoom(playerNumber);
		local x = rawX * zoom;
		local y = rawY * zoom;
		local z = player:getZ();
		local gridX, gridY = ISCoordConversion.ToWorld(x, y, z);
		
		if OPTIONS.suppressActionsWhileInventoryIsOpen and LCR.inventoryClosedFlag then
			return;
		end

		local targetSquare = Util.findPathableSquare(gridX, gridY, z);
		LCR.moveToTarget(player, targetSquare);
	end
end

function LCR.isDoubleClick(x, y)
	local data = LCR.clickData;
	data.isDoubleClick = UIManager.isDoubleClick(data.prevX, data.prevY, x, y, data.lastClickTime);
   	data.lastClickTime = getTimestampMs();
    data.prevX = x;
    data.prevY = y;
    return data.isDoubleClick;
end

function LCR.pickupItem(player, wItem, isDoubleClick)
	if LCR.isSuppressActionsForInventory() then
		return;
	end

	if not Util.verifyPermission(player, wItem) then
		return;
	end

	local doPickup = function()
		local angle = Util.playerAngleTo(player, wItem);
		if math.abs(angle) > 25 then
			ISTimedActionQueue.add(
				LCR.createFaceThenExecuteAction(player, wItem)
			);
		end

		local time = ISWorldObjectContextMenu.grabItemTime(player, wItem); -- These defaults are hella slow
		ISTimedActionQueue.add(ISGrabItemAction:new(player, wItem, time/4)); -- Speed it up since we're not rummaging through containers

		local invItem = wItem:getItem();
		if isDoubleClick and instanceof(invItem, "HandWeapon") then
			local equipCallback = function()
				ItemUtil.equipWeapon(player, invItem, 20, true, invItem:isTwoHandWeapon())
			end
			LCR.queueCallback(equipCallback);
		end
	end

	LCR.clearActionQueue(player);
	if LCR.isNeedsToMove(player, wItem, 1.2) then
		local square = Util.getClosestSquareFromObject(player, wItem);
		if not square then
			return;
		end

		local stopCheck = function() 
			return not Util.isBlocked(player, wItem) and Util.distanceToSquared(player, wItem) <= 1.2 * 1.2;
		end;

		LCR.moveToTarget(player, square, wItem, stopCheck, YELLOW);
		LCR.queueCallback(player, doPickup);
	else
		doPickup();
	end
end

function LCR.moveToObject(player, object, rawX, rawY, isDblClick)
	if object == nil then
		return;
	end

	if not Util.verifyPermission(player, object) then
		return;
	end

	local targetSquare = Util.getClosestSquareFromObject(player, object);
	if not targetSquare then
		return;
	end

	local hasContainer = object:getContainer() ~= nil;
	if not hasContainer and LCR.isSuppressActionsForInventory() then
		return;
	end

	local stopCheck = nil;
	if instanceof(object, "IsoDoor") then
		stopCheck = function(data)
			local playerSqr = player:getSquare();
			return object:isAdjacentToSquare(playerSqr) and playerSqr:DistToProper(targetSquare) <= 1;
		end;
	elseif hasContainer then
		stopCheck = function(data)
			return player:getSquare():DistToProper(object:getSquare()) <= 1.2;
		end;
	end

	
	local isNeedsToMove = LCR.isNeedsToMove(player, object, 1.5);

	if isNeedsToMove then
		LCR.clearActionQueue(player);	
		LCR.moveToTarget(player, targetSquare, object, stopCheck);
	elseif not Util:isPaused() then 
		LCR.cancelActiveMovementAction(player); -- Cancel any active movements to prevent the player from walking away from a container they just clicked	
	end

	local clickedNearbyOpenWindow = instanceof(object, "IsoWindow") and object:canClimbThrough(player);
	if clickedNearbyOpenWindow then
		LCR.GLOBALS.preventShutWindow = true;
		if not isDblClick then
			local tickDelay = 10;
			LCR.queueCallback(player, nil, tickDelay); -- Give the player a chance to double click before closing the window
		else
			if not isNeedsToMove then
				LCR.clearActionQueue(player);
			end

			LCR.queueCallback(player, function()
				LCR.createClimbWindowAction(player, object);
			end);
			return;
		end
	end

	if isDblClick then
		local waterObj = Util.getCleanWaterObject(object:getSquare())
		if waterObj then
			LCR.createDrinkAction(player, waterObj);
			return;
		end

		if instanceof(object, "IsoTelevision") or instanceof(object, "IsoRadio") then
			LCR.queueCallback(player, function()
				object:getDeviceData():setIsTurnedOn(not object:getDeviceData():getIsTurnedOn());
			end);
			return;
		end

		if instanceof(object, "IsoStove") then
			LCR.queueCallback(player, function()
				object:Toggle();
			end);
			return;
		end
	end

	local callback;
	if hasContainer then
		callback = function()
			ISObjectClickHandler.doClick(object, rawX, rawY);
		end;
	elseif isNeedsToMove or clickedNearbyOpenWindow then
		if Util.isAltInteractableObject(object) then
			callback = function()
				ISObjectClickHandler.doClick(object, rawX, rawY);
			end;
		else
		 	callback = function() 
				ISObjectClickHandler.doClickSpecificObject(object, 0, player);
			end;
		end
	end
	ISTimedActionQueue.add(
		LCR.createFaceThenExecuteAction(player, object, callback, hasContainer)
	);
end

function LCR.isNeedsToMove(player, object, minDistance)
	if instanceof(object, "IsoDoor") then
		return not object:isAdjacentToSquare(player:getCurrentSquare());
	end

	if Util.isBlocked(player, object) then
		return true;
	end

	local otherSqr = nil;
	if instanceof(object, "IsoWindow") then
		minDistance = 0.2;
		otherSqr = object:getOppositeSquare();
	end 
	if instanceof(object, "IsoCurtain") then
		minDistance = 0.2;
	end

	local playerSqr = player:getSquare();	
	if otherSqr then
		local otherDist = playerSqr:DistToProper(otherSqr);
		if otherDist < minDistance then
			return false;
		end
	end

	local sqr = object:getSquare();
	local dist = playerSqr:DistToProper(sqr);
	return dist > minDistance;
end


function LCR.moveToTarget(player, target, objectTarget, stopCheck, color)
	if not target then 
		return;
	end

	if not Util.isPaused() then
		local action = LCR.getActiveMovementAction(player)
		if action then
			action:updateTargetLocation(target);
			LCR.highlightSquare(target, color);
			return;
		end
	end

	ISTimedActionQueue.add(
		LCR.createMovementAction(player, target, objectTarget, stopCheck, color)
	);
end

function LCR.queueCallback(player, callback, time)
	ISTimedActionQueue.add(
		DelayedCodeExecutionTimedAction:new(player, callback, time)
	);
end

function LCR.createMovementAction(player, target, targetObject, earlyStopCheck, color)
	if not target then
		return;
	end

	if Util.isPaused() then 
		LCR.highlightSquare(target, color); -- Highlight immediately if queuing while paused
	end

	local moveAction = ClickToMoveTimedAction:new(player, target, earlyStopCheck);
	local onStart = function() LCR.highlightSquare(target, color); LCR.highlightObject(targetObject); end;
	local onStop = function(context) LCR.clearSquareHighlight(context.target); LCR.clearObjectHighlight(); end;
	moveAction:setOnStart(onStart);
	moveAction:setOnStop(onStop);
	
	return moveAction;
end

function LCR.createFaceThenExecuteAction(player, object, func, executeWhileTurning)
	local action = FaceThenExecuteTimedAction:new(player, object, func, executeWhileTurning);
	local onStart = function() LCR.highlightObject(object); end;
	local onStop = function() LCR.clearObjectHighlight(); end;
	action:setOnStart(onStart);
	action:setOnStop(onStop);
	return action;
end

function LCR.createDrinkAction(player, waterObject)
	local waterAvailable = waterObject:getWaterAmount()
	local thirst = player:getStats():getThirst()
	local waterNeeded = math.floor((thirst + 0.005) / 0.1)
	local waterConsumed = math.min(waterNeeded, waterAvailable)
	ISTimedActionQueue.add(ISTakeWaterAction:new(player, nil, waterConsumed, waterObject, (waterConsumed * 10) + 15, nil));
end


function LCR.createClimbWindowAction(player, window)
	if ISWorldObjectContextMenu.isTrappedAdjacentToWindow(player, window) then
		ISTimedActionQueue.add(ISClimbThroughWindow:new(player, window, 0));
		return;
	end

	local square = window:getSquare();
	if luautils.walkAdjWindowOrDoor(player, square, window) then
		ISTimedActionQueue.add(ISClimbThroughWindow:new(player, window, 0));
	end
end

function LCR.clearActionQueue(player, force)
	if not force and Util.isPaused() then 
		return; -- Actions queue instead if the game is paused
	end

	LCR.cancelActiveAction(player);
	player:StopAllActionQueue();
	ISTimedActionQueue.clear(player);
end

function LCR.getActiveMovementAction(player)
	local action = ISTimedActionQueue.getTimedActionQueue(player).current;
	if action and (action.Type == "ClickToMoveTimedAction") then
		return action;
	end
end

function LCR.cancelActiveAction(player)
	local action = ISTimedActionQueue.getTimedActionQueue(player).current;
	if action then
		action:forceStop();
	end
end

function LCR.cancelActiveMovementAction(player)
	local action = LCR.getActiveMovementAction(player);
	if action then
		action:forceStop();
	end
end

function LCR.cancelHoldToMoveAction()
	if LCR.holdToMoveAction then
		LCR.holdToMoveAction:forceComplete();
		LCR.holdToMoveAction = nil;
	end
end






function LCR.highlightSquare(square, color)
	if not color then
		color = CYAN;
	end

	LCR.clearSquareHighlight();
	if OPTIONS.isHighlightGround and square then
		LCR.groundMarker = getWorldMarkers():addGridSquareMarker(square, color.r, color.g, color.b, true, 0.55)
		LCR.groundMarkerSquare = square;
	end
end

function LCR.clearSquareHighlight(square)
	if square and square ~= LCR.groundMarkerSquare then
		return -- If a square is passed to id the target marker, but its no longer valid, do nothing
	end

	if LCR.groundMarker then
		LCR.groundMarker:remove()
		LCR.groundMarker = nil;
		LCR.groundMarkerSquare = nil;
	end
end

function LCR.highlightObject(object, color, thickness)
	LCR.clearObjectHighlight();
	if OPTIONS.isHighlightObjects and object then
		object:setOutlineHighlight(true);
		if color then
			object:setOutlineHighlightCol(color.r, color.g, color.b, color.a);
		end
		if thickness then
			object:setOutlineThickness(thickness);
		end

		LCR.lastHighlighted = object;
	end
end

function LCR.clearObjectHighlight()
	if LCR.lastHighlighted then
		LCR.lastHighlighted:setOutlineHighlight(false);
		LCR.lastHighlighted = nil;
	end
end

function LCR.isSuppressActionsForInventory()
	return OPTIONS.suppressActionsWhileInventoryIsOpen and LCR.inventoryClosedFlag;
end

Events.OnTick.Add(LCR.onTick);
Events.OnObjectLeftMouseButtonDown.Add(LCR.onDown);

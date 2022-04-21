require 'ItemUtil'

-- MOD OPTIONS

local SINGLE_CLICK = 1
local DOUBLE_CLICK = 2

local HOLD_PATHING = 1
local HOLD_SIMPLE = 2

local OPTIONS = {
	isClickToMove = true,
	clickToMoveStyle = SINGLE_CLICK,

	isHoldToMove = true,
	holdToMoveStyle = HOLD_PATHING,

	isClickToInteract = true,
	isClickOnLooseItems = true,

	isHighlightGround = true,
	isHighlightObjects = true,

	removeDefaultWalkAction = false,
}

if ModOptions and ModOptions.getInstance then

	local function autoRegisterOnApplyEvents(settings)
		for key,_ in pairs(settings.names) do
			local option = settings:getData(key);
			function option:OnApplyInGame(val)
				OPTIONS[key] = val;
			end
		end
	end

	local settings = ModOptions:getInstance(OPTIONS, "CTM_OSRS", "Left Click Redux");
	settings.names = {
		isClickToMove = "Enable Click to Move",
		clickToMoveStyle = "Click to Move Style",

		isHoldToMove = "Enable Hold to Move",
		holdToMoveStyle = "Hold to Move Style",

		isClickToInteract = "Enable Click to Interact",
		isClickOnLooseItems = "Enable Loose Item Interactions",

		isHighlightGround = "Show Destination Marker",
		isHighlightObjects = "Highlight Objects for Interaction",

		removeDefaultWalkAction = "Remove Default 'Walk To' Action from Context Menu"
	};

	autoRegisterOnApplyEvents(settings);

	local clickStyleDrop = settings:getData("clickToMoveStyle");
	clickStyleDrop[SINGLE_CLICK] = "Single Click"
	clickStyleDrop[DOUBLE_CLICK] = "Double Click"

	local holdStyleDrop = settings:getData("holdToMoveStyle");
	holdStyleDrop[HOLD_PATHING] = "Normal"
	holdStyleDrop[HOLD_SIMPLE] = "Simple"
	holdStyleDrop.tooltip = "The movement style when using hold to move.\nNormal: Uses pathfinding to move towards the cursor.\nSimple: The player moves straight towards the cursor, regardless of walls and obstacles."
end



local walkToText = getText("ContextMenu_Walk_to");

function ISContextMenu:addOption(name, target, onSelect, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10)
	if getCore():getGameMode() == "Tutorial" then
		if self:getOptionFromName(name) then
			return;
		end
	end
	if OPTIONS.removeDefaultWalkAction and name == walkToText then
		return;
	end

	local option = self:allocOption(name, target, onSelect, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10);
	self.options[self.numOptions] = option;
	self.numOptions = self.numOptions + 1;
	self:calcHeight()
	self:setWidth(self:calcWidth())
	return option;
end




-- UTIL

local Util = {}

function Util.isPlayerReady(player)
	return not (player == nil or player:IsAiming() or getCell():getDrag(0));
end

function Util.findPathableSquare(x, y, z)
	local square, location = Util.findPathableOnGrid(x,y,z);
	return square;
end

function Util.findPathableLocation(x, y, z)
	local square, location = Util.findPathableOnGrid(x,y,z);
	return location;
end

function Util.findPathableOnGrid(x, y, z)
	z =  math.floor(z + 0.25); -- Round up if close, makes stairs work better

	local square = getCell():getGridSquare(x, y, z);
	while (square == nil or not square:TreatAsSolidFloor()) and z > 0 do
		z = z - 1;
		square = getCell():getGridSquare(x, y, z);
	end

	local location = {x=x, y=y, z=z};
	if not square or not square:TreatAsSolidFloor() then
		square = nil;
		location = nil;
	end

	return square, location;
end

function Util.findPathableLocationFromMouse(player)
	local x = Mouse.getX();
	local y = Mouse.getY();
	local z = player:getZ();
	local gridX, gridY = ISCoordConversion.ToWorld(x, y, z);

	if z % 1 ~= 0 then
		local xDiff = gridX - player:getX();
		local yDiff = gridY - player:getY();

		if math.abs(xDiff) >= math.abs(yDiff) then
			gridX = player:getX() + (0.7 * xDiff / math.abs(xDiff));
			gridY = player:getY();
		else
			gridX = player:getX();
			gridY = player:getY() + (0.7 * yDiff / math.abs(yDiff));
		end
	end

	return Util.findPathableLocation(gridX, gridY, z)
end

function Util.isInteractableObject(object)
	return  instanceof(object, "IsoCurtain") or 
			instanceof(object, "IsoDoor") or instanceof(object, "IsoLightSwitch") or 
			instanceof(object, "IsoThumpable") or instanceof(object, "IsoWindow");
end

-- Lots of heuristics since I couldn't get pathfinding to return a path immediately
function Util.getClosestSquareFromObject(object, player)
	if instanceof(object, "IsoDoor") or instanceof(object, "IsoWindow") then
		local playerSqr = player:getSquare();
		local square = object:getSquare();
		local oppositeSquare = object:getOppositeSquare();

		local isOutside = playerSqr:isOutside();
		local sqrOutside = square:isOutside();
		local oppositeOutside = oppositeSquare:isOutside();

		if not AdjacentFreeTileFinder.privCanStand(square) then
			return oppositeSquare;
		elseif not AdjacentFreeTileFinder.privCanStand(oppositeSquare) then
			return square;
		end

		if isOutside == sqrOutside and isOutside ~= oppositeOutside then
			return square;
		elseif isOutside == oppositeOutside and isOutside ~= sqrOutside then
			return oppositeSquare;
		end

		local normalDist = playerSqr:DistToProper(square);
		local oppositeDist = playerSqr:DistToProper(oppositeSquare);

		if normalDist <= oppositeDist then
			return square;
		end
		return oppositeSquare;
	end

	local square = object:getSquare();
	if not AdjacentFreeTileFinder.privCanStand(square) or object:getContainer() then
		local adjacent = AdjacentFreeTileFinder.Find(square, player, true);
		if adjacent then
			square = adjacent;
		else
			square = nil;
		end
	end

	return square;
end

function Util.isPaused()
	return UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0;
end

function Util.distanceToSquared(obj1, obj2)
	local x = obj1:getX() - obj2:getX();
	local y = obj1:getY() - obj2:getY();
	return (x*x) + (y*y);
end

function Util.vector2(x,y)
	return {x=x, y=y}
end

function Util.angleTo(dir, pos, to)
	to.x = to.x - pos.x;
	to.y = to.y - pos.y;

	local dot = Util.dotProduct(dir, to);
	local lengthSqr = Util.magnitudeSqr(dir) * Util.magnitudeSqr(to);

	return math.acos(dot / math.sqrt(lengthSqr)) * 180 / math.pi;
end

function Util.magnitudeSqr(v)
	return (v.x * v.x) + (v.y * v.y);
end

function Util.dotProduct(a, b)
	return (a.x * b.x) + (a.y * b.y);
end



local CYAN = {r=0.1, g=0.9, b=0.6, a=1};
local YELLOW = {r=1, g=1, b=0, a=1};

-- LEFT CLICK REDUX

LeftClickRedux = {}
LeftClickRedux.clickData = {prevX=0, prevY=0};
LeftClickRedux.mouseDown = false;
LeftClickRedux.tickCounter = 0;

function LeftClickRedux.onTick()
	local playerNumber = 0;
	local player = getSpecificPlayer(playerNumber);

	if not LeftClickRedux.mouseDown or not Util.isPlayerReady(player) or Util.isPaused() then
		return;
	end

	-- OnObjectMouseUp Event was unreliable due to lack of calls when releasing over UI elements
	if not Mouse.isButtonDown(0) then
		LeftClickRedux.cancelHoldToMoveAction();
		return;
	end

	if OPTIONS.isHoldToMove and not LeftClickRedux.holdToMoveAction and LeftClickRedux.tickCounter >= 20 then
		LeftClickRedux.clearActionQueue(player);
		local location = Util.findPathableLocationFromMouse(player);
		if location then
			LeftClickRedux.holdToMoveAction = ClickAndHoldToMoveTimedAction:new(player, location);
			ISTimedActionQueue.add(LeftClickRedux.holdToMoveAction);
			LeftClickRedux.tickCounter = 0;
		end
		return;
	end

	if LeftClickRedux.holdToMoveAction and LeftClickRedux.tickCounter >= 6 then
		local location = Util.findPathableLocationFromMouse(player);
		if location then
			LeftClickRedux.holdToMoveAction:setTargetLocation(location);
			LeftClickRedux.tickCounter = -1;
		else
			LeftClickRedux.holdToMoveAction:forceComplete();
			LeftClickRedux.holdToMoveAction = nil;
		end
	end

	LeftClickRedux.tickCounter = LeftClickRedux.tickCounter + 1;
end

function LeftClickRedux.cancelHoldToMoveAction()
	LeftClickRedux.mouseDown = false;
	LeftClickRedux.tickCounter = 0;

	if LeftClickRedux.holdToMoveAction then
		LeftClickRedux.holdToMoveAction:forceComplete();
		LeftClickRedux.holdToMoveAction = nil;
	end
end

function LeftClickRedux.isDoubleClick(x, y)
	local data = LeftClickRedux.clickData;
    if data.lastClickTime ~= nil and UIManager.isDoubleClick(data.prevX, data.prevY, x, y, data.lastClickTime) then
        data.isDoubleClick = true
    else
        data.isDoubleClick = false
    end
    data.lastClickTime = getTimestampMs()

    data.prevX = x;
    data.prevY = y;

    return data.isDoubleClick;
end

function LeftClickRedux.onDown(object, rawX, rawY)
	local playerNumber = 0;
	local player = getSpecificPlayer(playerNumber);

	if not Util.isPlayerReady(player) then
		return;
	end

	LeftClickRedux.mouseDown = true;
	local isDblClick = LeftClickRedux.isDoubleClick(rawX, rawY);


	if OPTIONS.isClickOnLooseItems then
		local itemOut = {}	
		ItemUtil.findWorldObjectUnderMouse(playerNumber, object, rawX, rawY, itemOut)

		if itemOut.item then
			LeftClickRedux.pickupItem(player, itemOut.item, isDblClick);
			return;
		end
	end

	if OPTIONS.isClickToInteract and object ~= nil then
		local isInteractable = Util.isInteractableObject(object);
		if isInteractable or object:getContainer() then
			LeftClickRedux.moveToObject(player, object, isInteractable, rawX, rawY);
			return;
		end
	end

	if OPTIONS.isClickToMove then
		if OPTIONS.clickToMoveStyle == DOUBLE_CLICK and not isDblClick then
			return
		end

		local zoom = getCore():getZoom(playerNumber);
		local x = rawX * zoom;
		local y = rawY * zoom;
		local z = player:getZ();
		local gridX, gridY = ISCoordConversion.ToWorld(x, y, z);
		
		local targetSquare = Util.findPathableSquare(gridX, gridY, z);
		LeftClickRedux.moveToSquare(player, targetSquare);
	end
end

function LeftClickRedux.pickupItem(player, wItem, isDoubleClick)
	local doPickup = function()
		local itemPos = Util.vector2(wItem:getWorldPosX(), wItem:getWorldPosY());
		local playerPos = Util.vector2(player:getX(), player:getY());

		local playerForwardInternal = player:getForwardDirection();
		local playerForward = Util.vector2(playerForwardInternal:getX(), playerForwardInternal:getY());

		local angle = Util.angleTo(playerForward, playerPos, itemPos);

		if math.abs(angle) > 0 then
			ISTimedActionQueue.add(
				LeftClickRedux.createFaceThenExecuteAction(player, wItem)
			);
		end

		local time = ISWorldObjectContextMenu.grabItemTime(player, wItem); -- These defaults are hella slow
		ISTimedActionQueue.add(ISGrabItemAction:new(player, wItem, time/4)); -- Speed it up since we're not rummaging through containers

		local invItem = wItem:getItem();
		if isDoubleClick and instanceof(invItem, "HandWeapon") then
			ISTimedActionQueue.add(
				DelayedCodeExecutionTimedAction:new(player, 
				function()
					if player:getInventory():contains(invItem) then
						ItemUtil.equipWeapon(player, invItem, 20, true, invItem:isTwoHandWeapon())
					end
				end)
			);
		end
	end

	LeftClickRedux.clearActionQueue(player);
	if LeftClickRedux.isNeedsToMove(player, wItem, 1.2) or wItem:getSquare():isBlockedTo(player:getSquare()) then
		local square = Util.getClosestSquareFromObject(wItem, player);
		ISTimedActionQueue.add(
			LeftClickRedux.createMovementAction(player, square, nil, 
				function() 
					return Util.distanceToSquared(player, wItem) <= 1.2 * 1.2 and not wItem:getSquare():isBlockedTo(player:getSquare());
				end, YELLOW
			)
		);

		ISTimedActionQueue.add(
			DelayedCodeExecutionTimedAction:new(player, doPickup)
		);
	else
		doPickup();
	end
end

function LeftClickRedux.moveToObject(player, object, isInteractable, rawX, rawY)
	if object == nil then
		return;
	end

	local targetSquare = Util.getClosestSquareFromObject(object, player);

	local container = object:getContainer();

	local adjacentCheck = nil; -- Check if we are close enough to use a door if needed
							   -- So we interact early if possible
	if instanceof(object, "IsoDoor") then
		adjacentCheck = function(data)
			local playerSqr = player:getSquare();
			return object:isAdjacentToSquare(playerSqr) and playerSqr:DistToProper(targetSquare) <= 1;
		end;
	elseif container then
		adjacentCheck = function(data)
			return player:getSquare():DistToProper(object:getSquare()) <= 1.2;
		end;
	end

	local followUpAction = nil; -- Do this action after pathing. However, if we don't need to move, we assume the regular interaction triggered and leave this blank.
	if LeftClickRedux.isNeedsToMove(player, object) then
		LeftClickRedux.clearActionQueue(player);
		ISTimedActionQueue.add(
			LeftClickRedux.createMovementAction(player, targetSquare, object, adjacentCheck)
		);
		if isInteractable then 
			followUpAction = function() 
				ISObjectClickHandler.doClickSpecificObject(object, 0, player);
			end;
		end	
	elseif not Util:isPaused() then -- Cancel any active movements to prevent the player from walking away from a container they just clicked
		LeftClickRedux.cancelActiveMovementAction(player);
	end

	if container then -- Always reclick a container after turning, the player turning sometimes changes what container is selected
		followUpAction = function()
			ISObjectClickHandler.doClick(object, rawX, rawY);
		end;
	end

	local executeWhileTurning = container ~= nil;
	ISTimedActionQueue.add(
		LeftClickRedux.createFaceThenExecuteAction(player, object, followUpAction, executeWhileTurning)
	);
end

function LeftClickRedux.isNeedsToMove(player, object, minDistance)
	if instanceof(object, "IsoDoor") then
		return not object:isAdjacentToSquare(player:getCurrentSquare());
	end

	if not minDistance then
		minDistance = 1.55;
	end

	if instanceof(object, "IsoWindow") or instanceof(object, "IsoCurtain") then
		minDistance = 0;
	end 
	
	local sqr = player:getSquare();
	local sqr2 = object:getSquare();

	local dist = sqr:DistToProper(sqr2);
	return dist > minDistance;
end

function LeftClickRedux.moveToSquare(player, targetSquare)
	if targetSquare == nil then
		return;
	end

	LeftClickRedux.clearActionQueue(player);
	ISTimedActionQueue.add(
		LeftClickRedux.createMovementAction(player, targetSquare)
	);
end

function LeftClickRedux.createMovementAction(player, targetSquare, targetObject, earlyStopCheck, color)
	if Util.isPaused() then 
		LeftClickRedux.highlightSquare(targetSquare, color); -- Highlight immediately if queuing while paused
	end

	local moveAction = ClickToMoveTimedAction:new(player, targetSquare, earlyStopCheck);
	local onStart = function() LeftClickRedux.highlightSquare(targetSquare, color); LeftClickRedux.highlightObject(targetObject); end;
	local onStop = function() LeftClickRedux.clearSquareHighlight(targetSquare); LeftClickRedux.clearObjectHighlight(); end;
	moveAction:setOnStart(onStart);
	moveAction:setOnStop(onStop);
	
	return moveAction;
end

function LeftClickRedux.createFaceThenExecuteAction(player, object, func, executeWhileTurning)
	local action = FaceThenExecuteTimedAction:new(player, object, func, executeWhileTurning);
	local onStart = function() LeftClickRedux.highlightObject(object); end;
	local onStop = function() LeftClickRedux.clearObjectHighlight(); end;
	action:setOnStart(onStart);
	action:setOnStop(onStop);
	return action;
end

function LeftClickRedux.clearActionQueue(player)
	if Util.isPaused() then 
		return; -- Actions queue instead if the game is paused
	end

	player:StopAllActionQueue();
	ISTimedActionQueue.clear(player);
end

function LeftClickRedux.cancelActiveMovementAction(player)
	local current = ISTimedActionQueue.getTimedActionQueue(player).current;
	if current and (current.Type == "ClickToMoveTimedAction") then
		current:forceStop();
	end
end

function LeftClickRedux.highlightSquare(square, color)
	if not color then
		color = CYAN;
	end

	LeftClickRedux.clearSquareHighlight();
	if OPTIONS.isHighlightGround and square then
		LeftClickRedux.groundMarker = getWorldMarkers():addGridSquareMarker(square, color.r, color.g, color.b, true, 0.55)
		LeftClickRedux.groundMarkerSquare = square;
	end
end

function LeftClickRedux.clearSquareHighlight(square)
	if square and square ~= LeftClickRedux.groundMarkerSquare then
		return -- If a square is passed to id the target marker, but its no longer valid, do nothing
	end

	if LeftClickRedux.groundMarker then
		LeftClickRedux.groundMarker:remove()
		LeftClickRedux.groundMarker = nil;
		LeftClickRedux.groundMarkerSquare = nil;
	end
end

function LeftClickRedux.highlightObject(object, color, thickness)
	LeftClickRedux.clearObjectHighlight();
	if OPTIONS.isHighlightObjects and object then
		object:setOutlineHighlight(true);
		if color then
			object:setOutlineHighlightCol(color.r, color.g, color.b, color.a);
		end
		if thickness then
			object:setOutlineThickness(thickness);
		end

		LeftClickRedux.lastHighlighted = object;
	end
end

function LeftClickRedux.clearObjectHighlight()
	if LeftClickRedux.lastHighlighted then
		LeftClickRedux.lastHighlighted:setOutlineHighlight(false);
		LeftClickRedux.lastHighlighted = nil;
	end
end

Events.OnTick.Add(LeftClickRedux.onTick);
Events.OnObjectLeftMouseButtonDown.Add(LeftClickRedux.onDown);

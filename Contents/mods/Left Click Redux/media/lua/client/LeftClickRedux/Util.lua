Util = {}

function Util.isPlayerReady(player)
	return not (player == nil or player:IsAiming() or getCell():getDrag(0));
end

function Util.findPathableSquare(x, y, z)
	local square, location = Util.findPathableOnIsoGrid(x,y,z);
	return square;
end

function Util.findPathableLocation(x, y, z)
	local square, location = Util.findPathableOnIsoGrid(x,y,z);
	return location;
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
			gridX = player:getX() + (0.65 * xDiff / math.abs(xDiff));
			gridY = player:getY();
		else
			gridX = player:getX();
			gridY = player:getY() + (0.65 * yDiff / math.abs(yDiff));
		end
	end

	return Util.findPathableLocation(gridX, gridY, z)
end

function Util.findPathableOnIsoGrid(x, y, z)
	z =  Util.roundZ(z);

	local square = getCell():getGridSquare(x, y, z);
	while (square == nil or not square:TreatAsSolidFloor()) and z > 0 do
		z = z - 1;
		square = getCell():getGridSquare(x, y, z);
	end

	local location = {x=x, y=y, z=z};
	if not AdjacentFreeTileFinder.privCanStand(square) then
		square = nil;
		location = nil;
	end

	return square, location;
end

function Util.roundZ(z)
	return math.floor(z + 0.345); -- Round up if close, makes stairs work
end

function Util.findLocationFromMouse(player)
	local x = Mouse.getX();
	local y = Mouse.getY();
	local z = Util.roundZ(player:getZ());
	return ISCoordConversion.ToWorld(x, y, z);
end

function Util.isInteractableObject(object)
	return  instanceof(object, "IsoCurtain") or 
			instanceof(object, "IsoDoor") or instanceof(object, "IsoLightSwitch") or 
			instanceof(object, "IsoThumpable") or instanceof(object, "IsoWindow") or
			Util.isAltInteractableObject(object);
end

function Util.isAltInteractableObject(object)
	return instanceof(object, "IsoRadio") or instanceof(object, "IsoTelevision");
end

-- Lots of heuristics since I couldn't get pathfinding to return a path immediately
function Util.getClosestSquareFromObject(player, object)
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

function Util.playerAngleTo(player, target)
	local targetPos;
	if instanceof(target, "IsoWorldInventoryObject") then
		targetPos = Util.vector2(target:getWorldPosX(), target:getWorldPosY());
	else
		targetPos = Util.vector2(target:getX(), target:getY());
	end

	local playerPos = Util.vector2(player:getX(), player:getY());
	local playerForwardInternal = player:getForwardDirection();
	local playerForward = Util.vector2(playerForwardInternal:getX(), playerForwardInternal:getY());

	return Util.angleTo(playerForward, playerPos, targetPos);
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

function Util.isBlocked(player, object)
	return object:getSquare():isBlockedTo(player:getSquare())
end

function Util.isInventoryOpenAndNotPinned(playerNumber)
	local invWindow = getPlayerInventory(playerNumber);
	local lootWindow = getPlayerLoot(playerNumber);
	return (invWindow.isVisible and not invWindow.isCollapsed and not invWindow.pin) or (lootWindow.isVisible and not lootWindow.isCollapsed and not lootWindow.pin);
end

function Util.checkHopFlagByDirection(sqr, x, y)
	if not sqr then
		return false;
	end

	sqr = sqr:getProperties();
	if math.abs(x) > math.abs(y) then
		if x > 0 then
			return sqr:Is(IsoFlagType.HoppableE);
		else
			return sqr:Is(IsoFlagType.HoppableW);
		end
	else
		if y < 0 then
			return sqr:Is(IsoFlagType.HoppableN);
		else
			return sqr:Is(IsoFlagType.HoppableS);
		end
	end
end

function Util.sign(val)
	return val / math.abs(val);
end

function Util.roundInputDirectionAndNormalize(x, y)
	if math.abs(x) > math.abs(y) then
		x = Util.sign(x);
		y = 0;
	else
		x = 0;
		y = Util.sign(y);
	end
	return x,y;
end

function Util.findEndOfStairs(sqr, x, y)
	x,y = Util.roundInputDirectionAndNormalize(x,y);
	local cell = getCell();
	local z = sqr:getApparentZ(sqr:getX(), sqr:getY());
	while sqr and sqr:HasStairs() do
		sqr = Util.findPathableOnIsoGrid(x + sqr:getX() + 0.5, y + sqr:getY() + 0.5, z);
		if sqr then
			z = sqr:getApparentZ(sqr:getX(), sqr:getY());
		end
	end
	return sqr;
end


function Util.getCleanWaterObject(sqr)
	local objects = sqr:getObjects();
	for i = 0, objects:size()-1 do
		local obj = objects:get(i);
		if obj:hasWater() and not obj:isTaintedWater() then
			return obj;
		end
	end
	return nil;
end
ItemUtil = {}

local tableContains = function( _table, _item )
    for _,v in ipairs(_table) do
        if v==_item then return true end
    end
    return false;
end

ItemUtil.collectAllIsoObjects = function (object, x, y)
    local sq = object:getSquare();
    if instanceof(object, "IsoMovingObject") then
        sq = object:getCurrentSquare();
    end

    local objects = {}
    if (sq and sq:isSeen(0)) or instanceof(object, "IsoWindow") or instanceof(object, "IsoDoor") or instanceof(object, "IsoThumpable") or instanceof(object, "IsoTree") then
        table.insert(objects, object);
    end
    local doorTrans = IsoObjectPicker.Instance:PickDoor(x, y, true)
    if doorTrans ~= nil and not tableContains(objects, doorTrans) then
        table.insert(objects, doorTrans)
    end
    local window = IsoObjectPicker.Instance:PickWindow(x, y)
    if window ~= nil then
        table.insert(objects, window)
    end
    local windowFrame = IsoObjectPicker.Instance:PickWindowFrame(x, y)
    if windowFrame ~= nil then
        table.insert(objects, windowFrame)
    end
    local thump = IsoObjectPicker.Instance:PickThumpable(x, y)
    if thump ~= nil then
        table.insert(objects, thump)
    end
    local tree = IsoObjectPicker.Instance:PickTree(x, y)
    if tree then
        table.insert(objects, tree)
    end
    
    return objects;
end

function ItemUtil.findWorldObjectUnderMouse(playerNum, object, x, y, itemOut)
	local worldobjects = ItemUtil.collectAllIsoObjects(object, x, y);

	local squares = {}
	local doneSquare = {}
	for i,v in ipairs(worldobjects) do
		if v:getSquare() and not doneSquare[v:getSquare()] then
			doneSquare[v:getSquare()] = true
			table.insert(squares, v:getSquare())
		end
	end

	if #squares == 0 then return {} end

	local worldObjects = {}
	local squares2 = {}
	for k,v in pairs(squares) do
		squares2[k] = v
	end

	ItemUtil.getWorldObjectUnderMouse(playerNum, x, y, squares, itemOut);
end

function ItemUtil.getWorldObjectUnderMouse(playerNum, screenX, screenY, squares, itemOut)
	local radius = 32 / getCore():getZoom(playerNum);

	local closestDist = 1000;
	local closest = nil;

	for _,square in ipairs(squares) do
		local squareObjects = square:getWorldObjects()
		for i=1,squareObjects:size() do
			local worldObject = squareObjects:get(i-1)
			local dist = IsoUtils.DistanceToSquared(screenX, screenY,
				worldObject:getScreenPosX(playerNum), worldObject:getScreenPosY(playerNum))

			if dist < closestDist and dist <= radius * radius then
				closestDist = dist;
				itemOut.item = worldObject;
			end
		end
	end
end


ItemUtil.equipWeapon = function(player, weapon, primary, twoHands)
	-- Drop corpse or generator
	if isForceDropHeavyItem(player:getPrimaryHandItem()) then
		ISTimedActionQueue.add(ISUnequipAction:new(player, player:getPrimaryHandItem(), 50));
	end
	-- if weapon isn't in main inventory, put it there first.
	ISInventoryPaneContextMenu.transferIfNeeded(player, weapon)
    -- Then equip it.
    ISTimedActionQueue.add(ISEquipWeaponAction:new(player, weapon, 50, primary, twoHands));
end



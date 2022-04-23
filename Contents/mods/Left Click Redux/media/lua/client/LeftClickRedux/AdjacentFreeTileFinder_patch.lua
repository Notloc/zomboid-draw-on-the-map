
-- Fix bracket balancing to fix bug with diagonal tile wall detection

AdjacentFreeTileFinder.privTrySquareForWalls = function(src, test)
    if src == nil or test == nil then return false; end

    if src:getX() < test:getX() and src:getY() == test:getY() then
        if test:Is("DoorWallW") and not test:isDoorBlockedTo(src) then return true; end
        if test:Is(IsoFlagType.cutW) or test:Is(IsoFlagType.collideW) then return false; end
    end
    if src:getX() > test:getX() and src:getY() == test:getY()  then
        if src:Is("DoorWallW") and not src:isDoorBlockedTo(test) then return true; end
        if src:Is(IsoFlagType.cutW)  or src:Is(IsoFlagType.collideW) then return false; end
    end

    if src:getY() < test:getY() and src:getX() == test:getX()  then
        if test:Is("DoorWallN") and not test:isDoorBlockedTo(src) then return true; end
        if test:Is(IsoFlagType.cutN)  or test:Is(IsoFlagType.collideN)  then return false; end
    end
    if src:getY() > test:getY() and src:getX() == test:getX()  then
        if src:Is("DoorWallN") and not src:isDoorBlockedTo(test) then return true; end
        if src:Is(IsoFlagType.cutN)  or src:Is(IsoFlagType.collideN) then return false; end
    end

    if src:getX() ~= test:getX() and src:getY() ~= test:getY() then
        if  not AdjacentFreeTileFinder.privTrySquareForWalls2(src, test:getX(), src:getY(), src:getZ()) or
            not AdjacentFreeTileFinder.privTrySquareForWalls2(src, src:getX(), test:getY(), src:getZ()) or
            not AdjacentFreeTileFinder.privTrySquareForWalls2(test, test:getX(), src:getY(), src:getZ()) or
            not AdjacentFreeTileFinder.privTrySquareForWalls2(test, src:getX(), test:getY(), src:getZ()) then
            return false
        end
    end

    return true;
end


-- Added a parameter to allow requesting diagonals to always be checked

AdjacentFreeTileFinder.Find = function(gridSquare, playerObj, doDiagonals)
    local choices = {}
    local choicescount = 1;
    -- first try straight lines (N/S/E/W)
    local a = gridSquare:getAdjacentSquare(IsoDirections.W)
    local b = gridSquare:getAdjacentSquare(IsoDirections.E)
    local c = gridSquare:getAdjacentSquare(IsoDirections.N)
    local d = gridSquare:getAdjacentSquare(IsoDirections.S)

    -- for each of them, test that square then if it's 'adjacent' then add it to the table for picking.
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) then table.insert(choices, a); choicescount = choicescount + 1; end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) then table.insert(choices,  b); choicescount = choicescount + 1;end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) then  table.insert(choices, c); choicescount = choicescount + 1;end
    if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) then table.insert(choices, d); choicescount = choicescount + 1; end

    -- only do diags if no other choices or requested
    if choicescount == 1 or doDiagonals then
        -- now do diags.
        a = gridSquare:getAdjacentSquare(IsoDirections.NW)
        b = gridSquare:getAdjacentSquare(IsoDirections.NE)
        c = gridSquare:getAdjacentSquare(IsoDirections.SW)
        d = gridSquare:getAdjacentSquare(IsoDirections.SE)

        if AdjacentFreeTileFinder.privTrySquare(gridSquare, a) then  table.insert(choices, a); choicescount = choicescount + 1; end
        if AdjacentFreeTileFinder.privTrySquare(gridSquare, b) then  table.insert(choices,  b); choicescount = choicescount + 1;end
        if AdjacentFreeTileFinder.privTrySquare(gridSquare, c) then  table.insert(choices, c); choicescount = choicescount + 1;end
        if AdjacentFreeTileFinder.privTrySquare(gridSquare, d) then  table.insert(choices, d); choicescount = choicescount + 1; end

    end

    -- if we have multiple choices, pick the one closest to the player
    if choicescount > 1 then
       local lowestdist = 100000;
       local distchoice = nil;

       for i, k in ipairs(choices) do
          local dist = k:DistToProper(playerObj);
          if dist < lowestdist then
              lowestdist = dist;
              distchoice = k;
          end
       end

        return distchoice;
    end
    return nil;
end

WorldMapSymbolTool_FreeHandEraser = ISWorldMapSymbolTool:derive("WorldMapSymbolTool_FreeHandEraser")

local soundCap = false;

function WorldMapSymbolTool_FreeHandEraser:activate()
end

function WorldMapSymbolTool_FreeHandEraser:deactivate()
end

function WorldMapSymbolTool_FreeHandEraser:onMouseDown(x, y)
	if self.rightDown then
		return false;
	end

	self.mouseHeld = true;
	self.doErase = true;

	self.prevX = nil
	self.prevY = nil

	return true;
end

function WorldMapSymbolTool_FreeHandEraser:onMouseUp(x, y)
	self.mouseHeld = false;
	self.doErase = false;
	return false
end

function WorldMapSymbolTool_FreeHandEraser:onMouseMove(dx, dy)
	return false
end

function WorldMapSymbolTool_FreeHandEraser:onRightMouseDown(x, y)
	self.rightDown = true;
	return true;
end

function WorldMapSymbolTool_FreeHandEraser:onRightMouseUp(x, y)
	self.rightDown = false;
	return true;
end

function WorldMapSymbolTool_FreeHandEraser:render()
	if self.doErase then
		local x = self.symbolsUI.mapUI:getMouseX()
		local y = self.symbolsUI.mapUI:getMouseY()
		soundCap = false;

		if not self.rotation then
			self.rotation = 0
		end

		self:eraseAnnotation(x, y)


		local positionSteps = 1
		local pX = 0
		local pY = 0

		-- Determine if and how many steps to take between the last and current mouse position
		if self.prevX then
			local dx = x - self.prevX
			local dy = y - self.prevY
			local distance = math.sqrt(dx*dx + dy*dy)
			if distance > 10 then
				positionSteps = math.ceil(math.sqrt(distance/3))
				if positionSteps > 5 then
					positionSteps = 5
				end
			end
			pX = math.abs(dx) / positionSteps
			pY = math.abs(dy) / positionSteps
		end


		local spread = 2
		local rotation = 0
		local turns = 2

		local startX = self.prevX or x
		local startY = self.prevY or y

		-- Lerp between the last and current mouse position, erasing symbols along the way
		for p=1,positionSteps do
			-- Whirl around the mouse for more coverage
			local x2 = startX + pX * p
			local y2 = startY + pY * p
			for i=1,turns do
				self:eraseAnnotation(x2+math.cos(rotation)*spread,              y2+math.sin(rotation)*spread)
				self:eraseAnnotation(x2+math.cos(rotation+math.pi/2)*spread,    y2+math.sin(rotation+math.pi/2)*spread)
				self:eraseAnnotation(x2+math.cos(rotation+math.pi)*spread,      y2+math.sin(rotation+math.pi)*spread)
				self:eraseAnnotation(x2+math.cos(rotation+math.pi*3/2)*spread,  y2+math.sin(rotation+math.pi*3/2)*spread)
				self:eraseAnnotation(x2+math.cos(rotation+math.pi/4)*spread,    y2+math.sin(rotation+math.pi/4)*spread)
				self:eraseAnnotation(x2+math.cos(rotation+math.pi*3/4)*spread,  y2+math.sin(rotation+math.pi*3/4)*spread)
				self:eraseAnnotation(x2+math.cos(rotation+math.pi*5/4)*spread,  y2+math.sin(rotation+math.pi*5/4)*spread)
				self:eraseAnnotation(x2+math.cos(rotation+math.pi*7/4)*spread,  y2+math.sin(rotation+math.pi*7/4)*spread)

				spread = spread + 4
				rotation = rotation + math.pi/turns
			end
		end

		self.prevX = x
		self.prevY = y
	end
end

function WorldMapSymbolTool_FreeHandEraser:onJoypadDownInMap(button, joypadData)
	if button == Joypad.AButton then
	end
end

function WorldMapSymbolTool_FreeHandEraser:getJoypadAButtonText()
	if self.symbolsUI.mouseOverNote or self.symbolsUI.mouseOverSymbol then
		return getText("IGUI_Map_RemoveElement")
	end
	return nil
end

function WorldMapSymbolTool_FreeHandEraser:eraseAnnotation(x, y)
	local index = self.symbolsAPI:hitTest(x, y)
	if index ~= -1 then
		self.symbolsAPI:removeSymbolByIndex(index)
		if self.symbolsUI.character and not soundCap then
			soundCap = true
			self.symbolsUI.character:playSoundLocal("MapRemoveMarking")
		end
	end
end

function WorldMapSymbolTool_FreeHandEraser:new(symbolsUI)
	local o = ISWorldMapSymbolTool.new(self, symbolsUI)
	return o
end
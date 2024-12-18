require "ISUI/Maps/ISWorldMapSymbols"

local DEFAULT_SCALE = 3

WorldMapSymbolTool_FreeHandTool = ISWorldMapSymbolTool:derive("WorldMapSymbolTool_FreeHandTool")

function WorldMapSymbolTool_FreeHandTool:activate()
	self.drawingActive = false;
	self.rightDown = false;
	self.symbolsUI:setVisible(true) -- this ensures the preview is visible
end

function WorldMapSymbolTool_FreeHandTool:deactivate()
	self.drawingActive = false;
end

function WorldMapSymbolTool_FreeHandTool:onMouseDown(x, y)
	if self.rightDown then
		return false;
	end

	self.dragging = false
	self.dragMoved = false
	self.drawingActive = true;
	self.lastWorldX = self.mapAPI:uiToWorldX(x, y);
	self.lastWorldY = self.mapAPI:uiToWorldY(x, y);

	self:addSymbol(self.lastWorldX, self.lastWorldY, true)
	return true
end

function WorldMapSymbolTool_FreeHandTool:onMouseUp(x, y)
	if self.drawingActive then
		self.drawingActive = false;
		self:drawLine(x, y);
		return true
	end
end

function WorldMapSymbolTool_FreeHandTool:onMouseMove(dx, dy)
	if self.drawingActive then
		local mouseX = self:getMouseX()
		local mouseY = self:getMouseY()
		self:drawLine(mouseX, mouseY);
	end
	return false
end

function WorldMapSymbolTool_FreeHandTool:onRightMouseDown(x, y)
	self.rightDown = true;
	return true;
end

function WorldMapSymbolTool_FreeHandTool:onRightMouseUp(x, y)
	self.rightDown = false;
	print(self.symbolsUI.symbolsAPI:getSymbolCount())
	return true;
end 

function WorldMapSymbolTool_FreeHandTool:render()
	local symbol = self:getSelectedSymbol()

	if (self.symbolsUI.playerNum ~= 0) or (JoypadState.players[self.symbolsUI.playerNum+1] and not wasMouseActiveMoreRecentlyThanJoypad()) then
		self:renderSymbol(symbol, self.mapUI.width / 2, self.mapUI.height / 2)
	else
		self:renderSymbol(symbol, self:getMouseX(), self:getMouseY())
	end
end

function WorldMapSymbolTool_FreeHandTool:renderSymbol(symbol, x, y)
	if not symbol then return end
	local scale = self.scale * ISMap.SCALE * 0.1 * self.symbolsUI.mapAPI:getWorldScale()
	local sym = symbol
	local symW = sym.image:getWidth() / 2 * scale
	local symH = sym.image:getHeight() / 2 * scale
	self.mapUI:drawTextureScaled(sym.image, x-symW, y-symH,
		sym.image:getWidth() * scale, sym.image:getHeight() * scale,
		1, sym.textureColor.r, sym.textureColor.g, sym.textureColor.b)
end

function WorldMapSymbolTool_FreeHandTool:drawLine(x,y)
	if self.symbolsAPI:getSymbolCount() > 250000 then -- I have altered the limit. Pray that I do not alter it further.
		return
	end

	local limit = ISMap.SCALE * (2.4 * self.scale / DEFAULT_SCALE / self.fill);

	local worldX = self.mapAPI:uiToWorldX(x, y)
	local worldY = self.mapAPI:uiToWorldY(x, y)

	local diff = math.abs(worldX - self.lastWorldX) + math.abs(worldY - self.lastWorldY);
	if diff > limit then
		local xDiff = worldX - self.lastWorldX;
		local yDiff = worldY - self.lastWorldY;

		local divisor = diff/limit;
		divisor = math.floor(divisor) + 1

		xDiff = xDiff/divisor;
		yDiff = yDiff/divisor;

		for i=1,divisor do
			self:addSymbol(self.lastWorldX + xDiff * i, self.lastWorldY + yDiff * i, false);
		end

		self.lastWorldX = worldX;
		self.lastWorldY = worldY;
	end
end

function WorldMapSymbolTool_FreeHandTool:addSymbol(worldX, worldY, sound)
	local tex = self.lineTex;
	if self.symbolsUI.selectedSymbol then
		tex = self.symbolsUI.selectedSymbol.tex;
	end

	local textureSymbol = self.symbolsAPI:addTexture(tex, worldX, worldY)
	local col = self.symbolsUI.currentColor;
	textureSymbol:setRGBA(col:getR(), col:getG(), col:getB(), 1.0)
	textureSymbol:setAnchor(0.5, 0.5)
	textureSymbol:setScale(ISMap.SCALE * self.scale / 10)
	if sound and self.symbolsUI.character then
		self.symbolsUI.character:playSoundLocal("MapAddSymbol")
	end
end

function WorldMapSymbolTool_FreeHandTool:getSelectedSymbol()
	if self.symbolsUI.selectedSymbol then
		return self.symbolsUI.selectedSymbol
	end

	if self.defaultSymbol then
		return self.defaultSymbol
	end

	for _, symbol in ipairs(self.symbolsUI.buttonList) do
		if symbol.tex == self.lineTex then
			self.defaultSymbol = symbol
			return symbol
		end
	end
end

function WorldMapSymbolTool_FreeHandTool:new(symbolsUI)
	local o = ISWorldMapSymbolTool.new(self, symbolsUI)
	o.lineTex = "c";
	o.scale = DEFAULT_SCALE;
	o.fill = 1
	return o
end

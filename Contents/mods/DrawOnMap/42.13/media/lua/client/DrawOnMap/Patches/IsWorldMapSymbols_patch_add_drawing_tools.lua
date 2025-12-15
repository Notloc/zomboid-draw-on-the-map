require "ISUI/Maps/ISWorldMapSymbols"
require "DrawOnMap/WorldMapSymbolTool_FreeHandTool"
require "DrawOnMap/WorldMapSymbolTool_FreeHandEraser"
require "DrawOnMap/WorldMapSymbolTool_LineTool"

ISWorldMapSymbols.initTools_prepatch_drawonmap = ISWorldMapSymbols.initTools;

ISWorldMapSymbols.initTools = function(self)
	self:initTools_prepatch_drawonmap();
	self.tools.FreeHandTool = WorldMapSymbolTool_FreeHandTool:new(self);
	self.tools.LineTool = WorldMapSymbolTool_LineTool:new(self);
	self.tools.FreeHandEraseTool = WorldMapSymbolTool_FreeHandEraser:new(self);
end


ISWorldMapSymbols.onButtonClick_prepatch_drawonmap = ISWorldMapSymbols.onButtonClick;

ISWorldMapSymbols.onButtonClick = function(self, button)
	local originalTool = self.currentTool;
	
	self:onButtonClick_prepatch_drawonmap(button)

	 -- Allow symbol selection with the free hand tool selected
	if button.symbol and originalTool == self.tools.FreeHandTool then
		local symbol = self.selectedSymbol;
		self:setCurrentTool(self.tools.FreeHandTool);
		self.selectedSymbol = symbol;
	end
end

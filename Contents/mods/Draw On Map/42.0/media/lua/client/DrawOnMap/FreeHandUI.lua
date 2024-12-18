FreeHandUI = ISPanelJoypad:derive("FreeHandUI")
require "ISUI/ISSliderPanel"

local MIN_FILL = 0.05
local MAX_FILL = 1.0
local DEFAULT_FILL = 1.0
local STEP_FILL = 0.05

local MIN_SIZE = 0.5
local MAX_SIZE = 25.0
local DEFAULT_SIZE = 2.5
local STEP_SIZE = 0.5

local FONT = UIFont.Small
local FONT_HEIGHT = getTextManager():getFontHeight(FONT)

function FreeHandUI:new(x, y, width, height, symbolsUI)
	local o = ISPanelJoypad:new(x, y, width, height);
    o.moveWithMouse = true;
    o.symbolsUI = symbolsUI;
    setmetatable(o, self)
    self.__index = self
    return o
end

function FreeHandUI:init()
	local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

	local btnWid = self.width - 40
	local btnHgt = FONT_HGT_SMALL + 2 * 2

	local sliderWidth = self.width - 40;

	local y = 14

	self.freeHandBtn = ISButton:new(20, y, btnWid, btnHgt, getText("UI_DrawOnMap_Draw"), self, FreeHandUI.onButtonClick)
	self.freeHandBtn.internal = "FREE_HAND"
	self.freeHandBtn:initialise()
	self.freeHandBtn:instantiate()
	self.freeHandBtn.borderColor.a = 0.0
	self:addChild(self.freeHandBtn)

	y = self.freeHandBtn:getBottom() + 10

	self.lineBtn = ISButton:new(20, y, btnWid, btnHgt, getText("UI_DrawOnMap_Line"), self, FreeHandUI.onButtonClick)
	self.lineBtn.internal = "LINE"
	self.lineBtn:initialise()
	self.lineBtn:instantiate()
	self.lineBtn.borderColor.a = 0.0
	self:addChild(self.lineBtn)

	y = self.lineBtn:getBottom() + 10

	self.freeHandEraseBtn = ISButton:new(20, y, btnWid, btnHgt, getText("UI_DrawOnMap_Erase"), self, FreeHandUI.onButtonClick)
	self.freeHandEraseBtn.internal = "FREE_HAND_ERASE"
	self.freeHandEraseBtn:initialise()
	self.freeHandEraseBtn:instantiate()
	self.freeHandEraseBtn.borderColor.a = 0.0
	self:addChild(self.freeHandEraseBtn)

	y = self.freeHandEraseBtn:getBottom() + 10

	self.sizeTextY = y
	y = y + FONT_HEIGHT * 1.25
	self.sizeSlider = FreeHandUI.createSlider(self, 20, y, sliderWidth, 15, MIN_SIZE, MAX_SIZE, STEP_SIZE, DEFAULT_SIZE, self.updateScaleValue)
	self:addChild(self.sizeSlider)

	y = self.sizeSlider:getBottom() + 7

	self.fillTextY = y;
	y = y + FONT_HEIGHT * 1.25
	self.fillSlider = FreeHandUI.createSlider(self.symbolsUI.tools.FreeHandTool, 20, y, sliderWidth, 15, MIN_FILL, MAX_FILL, STEP_FILL, DEFAULT_FILL, self.symbolsUI.tools.FreeHandTool.updateFillValue)
	self:addChild(self.fillSlider)

	self:insertNewLineOfButtons(self.freeHandBtn)
	self:insertNewLineOfButtons(self.freeHandEraseBtn)

	self:setHeight(self.fillSlider:getBottom() + 14)

	self.symbolsUI.tools.FreeHandTool.scale = DEFAULT_SIZE
	self.symbolsUI.tools.FreeHandTool.fill = DEFAULT_FILL

	self.symbolsUI.tools.LineTool.scale = DEFAULT_SIZE
	self.symbolsUI.tools.LineTool.fill = DEFAULT_FILL
end

function FreeHandUI.createSlider(target, xPos, yPos, width, height, min, max, step, defaultValue, onValueChanged)
	local slider = ISSliderPanel:new(xPos, yPos, width, height, target, onValueChanged)
	slider:setValues(min, max, step, 0)
	slider.currentValue = defaultValue;
	slider:initialise()
	slider:instantiate()
	slider.doToolTip = false

	return slider
end

function FreeHandUI:updateScaleValue(value)
	self.symbolsUI.tools.FreeHandTool.scale = value
	self.symbolsUI.tools.LineTool.scale = value
end

function FreeHandUI:updateFillValue(value)
	self.symbolsUI.tools.FreeHandTool.fill = value
	self.symbolsUI.tools.LineTool.fill = value
end

function FreeHandUI:drawTextCentered(text, y, font)
	local textWidth = getTextManager():MeasureStringX(font, text);
	self:drawText(text, (self.width / 2) - (textWidth / 2), y, 1, 1, 1, 1, font)
end

function FreeHandUI:prerender()
	ISPanelJoypad.prerender(self)
	
	self:checkInventory()
	self.freeHandBtn.borderColor.a = (self.symbolsUI.currentTool == self.symbolsUI.tools.FreeHandTool) and 1 or 0
	self.lineBtn.borderColor.a = (self.symbolsUI.currentTool == self.symbolsUI.tools.LineTool) and 1 or 0
	self.freeHandEraseBtn.borderColor.a = (self.symbolsUI.currentTool == self.symbolsUI.tools.FreeHandEraseTool) and 1 or 0

	self:drawTextCentered(getText("UI_DrawOnMap_Thickness"), self.sizeTextY, FONT)
	self:drawTextCentered(getText("UI_DrawOnMap_Fill"), self.fillTextY, FONT)
end

function FreeHandUI:checkInventory()
	self.freeHandBtn.enable = self.symbolsUI.addNoteBtn.enable;
	self.freeHandBtn.tooltip = self.symbolsUI.addNoteBtn.tooltip;

	self.freeHandEraseBtn.enable = self.symbolsUI.removeBtn.enable;
	self.freeHandEraseBtn.tooltip = self.symbolsUI.removeBtn.tooltip;

	if self.symbolsUI.currentTool == self.symbolsUI.tools.FreeHandTool and not self.freeHandBtn.enable then
		self.symbolsUI:setCurrentTool(nil)
	end
	if self.symbolsUI.currentTool == self.symbolsUI.tools.FreeHandEraseTool and not self.freeHandEraseBtn.enable then
		self.symbolsUI:setCurrentTool(nil)
	end
end

function FreeHandUI:onButtonClick(button)
	local symbolsUI = self.symbolsUI;

	if button.internal == "FREE_HAND" then
		symbolsUI.selectedSymbol = nil
		symbolsUI:toggleTool(symbolsUI.tools.FreeHandTool)
	end

	if button.internal == "FREE_HAND_ERASE" then
		symbolsUI.selectedSymbol = nil
		symbolsUI:toggleTool(symbolsUI.tools.FreeHandEraseTool)
	end

	if button.internal == "LINE" then
		symbolsUI.selectedSymbol = nil
		symbolsUI:toggleTool(symbolsUI.tools.LineTool)
	end
end

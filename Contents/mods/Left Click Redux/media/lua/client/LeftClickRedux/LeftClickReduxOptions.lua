LeftClickRedux = {
	GLOBALS = {}
}

local LCR = {
	SINGLE_CLICK = 1,
	DOUBLE_CLICK = 2,

	HOLD_PATHING = 1,
	HOLD_SIMPLE = 2,
}

LeftClickRedux.OPTIONS = {
	ENUMS = LCR,

	isClickToMove = true,
	clickToMoveStyle = LCR.SINGLE_CLICK,
	suppressActionsWhileInventoryIsOpen = true,

	isHoldToMove = true,
	holdToMoveStyle = LCR.HOLD_SIMPLE,

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
				LeftClickRedux.OPTIONS[key] = val;
			end
		end
	end

	local settings = ModOptions:getInstance(LeftClickRedux.OPTIONS, "CTM_OSRS", "Left Click Redux");
	settings.names = {
		isClickToMove = "Enable Click to Move",
		clickToMoveStyle = "Click to Move Style",
		suppressActionsWhileInventoryIsOpen = "Suppress Walking When Click Close Inventory",

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
	clickStyleDrop[LCR.SINGLE_CLICK] = "Single Click"
	clickStyleDrop[LCR.DOUBLE_CLICK] = "Double Click"

	local holdStyleDrop = settings:getData("holdToMoveStyle");
	holdStyleDrop[LCR.HOLD_PATHING] = "Normal"
	holdStyleDrop[LCR.HOLD_SIMPLE] = "Simple"
	holdStyleDrop.tooltip = "The movement style when using hold to move.\nNormal: Uses pathfinding to move towards the cursor.\nSimple: The player moves straight towards the cursor, regardless of walls and obstacles."
end
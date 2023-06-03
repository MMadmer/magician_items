_G = GLOBAL
local require = _G.require
local STRINGS = _G.STRINGS
local RECIPETABS = _G.RECIPETABS
local Recipe = _G.Recipe
local Ingredient = _G.Ingredient
local TECH = _G.TECH
local TUNING = _G.TUNING
local GetPlayer = _G.GetPlayer
local RECIPE_GAME_TYPE = _G.RECIPE_GAME_TYPE
local Vector3 = _G.Vector3
local Transform = _G.Transform
local SpawnPrefab = _G.SpawnPrefab
local TheSim = _G.TheSim
local Action = _G.Action
local ActionHandler = _G.ActionHandler

local seg_time = 30 --each segment of the clock is 30 seconds
local total_day_time = seg_time*16

TUNING.TOPHAT_MAGICIAN = total_day_time * 8
TUNING.DESTRUCTION = GetModConfigData('destruction') -- Add "if TUNING.DESTRUCTION" if u set block with "workable" component to ur item
TUNING.GLOBAL_UTILS = 
{
	-- Game/world container dimensions
	DIMENSIONS = 
	{
		-- Minimum dimensions for game working 1
		-- Check mod items to find out how to connect your container
		-- Danger with connected container destruction(can loose items under certain conditions)
		"shadow",
	}
}

PrefabFiles =
{
	"tophat_magician",
	"magician_chest",
}

Assets =
{
	Asset("ATLAS", "images/inventoryimages/tophat_magician.xml"),
	Asset("ATLAS", "images/inventoryimages/magician_chest.xml"),
	Asset("ATLAS", "minimap/magician_chest.xml"),
}

AddMinimapAtlas("minimap/magician_chest.xml")

-- Magician's recipes
-------------------------------------------------------
local mag_item_0 = Recipe("tophat_magician",
	{ 
		Ingredient("tophat", 1),
		Ingredient("nightmarefuel", 2)
	},
	RECIPETABS.MAGIC,
	{ SCIENCE = 1 }
)
mag_item_0.atlas = "images/inventoryimages/tophat_magician.xml"

-------------------------------------------------------
local mag_item_1 = Recipe("magician_chest",
	{ 
		Ingredient("silk", 1), 
		Ingredient("boards", 4), 
		Ingredient("nightmarefuel", 9) 
	}, 
	RECIPETABS.MAGIC, 
	{ SCIENCE = 1 }, 
	"magician_chest_placer"
)
mag_item_1.atlas = "images/inventoryimages/magician_chest.xml"
-------------------------------------------------------

-- Magician's chest
local function updatestoreroom(inst)
	inst.components.container.widgetpos = _G.Vector3(360 - (12 * 4.5), 170, 0)

	inst.components.container.widgetanimbank = "ui_chest_4x5"
	inst.components.container.widgetanimbuild = "ui_chest_4x5"
end
AddPrefabPostInit("magician_chest", updatestoreroom)
AddPrefabPostInit("tophat_magician", updatestoreroom)

modimport "world/general_world.lua"

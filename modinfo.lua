name = "Dimension mechanic items"
description = [[
This mode adds new dimension containers mechanic like in DST.
Place your items in a vault and retrieve from another anywhere 
on the map!
]]
author = "Madmer"
version = "1.01"
forumthread = ""
api_version = 6

dont_starve_compatible = true
reign_of_giants_compatible = true
shipwrecked_compatible = true
hamlet_compatible = true

icon_atlas = "preview.xml"
icon = "preview.tex"

local alpha = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}
local KEY_A = 97
local keyslist = {}
for i = 1,#alpha do keyslist[i] = {description = alpha[i],data = i + KEY_A - 1} end

configuration_options = 
{
	{
		name = "destruction", 
		label = "(danger)Magician's box destruction", 
        hover = "Enable/disable Magician's box destruction",
		options = 
		{
			{description = "Enable", data = true,},
			{description = "Disable (default)", data = false,},
		},
		default = false
	},
}

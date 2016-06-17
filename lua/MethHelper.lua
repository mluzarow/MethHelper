-- Batch complete (Rats)
local RatsFinishedID = "pln_rat_stage1_28"
local RatsAddedID = "pln_rat_stage1_12" -- ???
local CookoffFinishedID = "pln_rt1_28"
local CookoffAddedID = "pln_rt1_12"

-- Dictionary mapping dialogue codes to plain text ingredients
local ingredient_dialog = {}
ingredient_dialog["pln_rt1_20"] = "Muriatic Acid"
ingredient_dialog["pln_rt1_22"] = "Caustic Soda"
ingredient_dialog["pln_rt1_24"] = "Hydrogen Chloride"
ingredient_dialog["pln_rat_stage1_20"] = "Muriatic Acid"
ingredient_dialog["pln_rat_stage1_22"] = "Caustic Soda"
ingredient_dialog["pln_rat_stage1_24"] = "Hydrogen Chloride"
-- Round about hacky way to trigger by both ingredients and recipe state dialogue
ingredient_dialog [RatsFinishedID] = true
ingredient_dialog [RatsAddedID] = true
ingredient_dialog [CookoffFinishedID] = true
ingredient_dialog [CookoffAddedID] = true

-- Track number of ingredients in current meth recipe 
local currentRecipe = 1
-- Track total number of bags made
local totalBags = 0
-- Track current recipe state
local currentRecipeList = {}
currentRecipeList ["Muriatic Acid"] = false
currentRecipeList ["Caustic Soda"] = false
currentRecipeList ["Hydrogen Chloride"] = false

-- Math.Clamp
function clampCeiling (var, vMax)
	if val > vMax then
		val = vMax
	end
	
	return val
	
local _queue_dialog_orig = DialogManager.queue_dialog
function DialogManager:queue_dialog(id, ...)
	-- If dialogue code is found in dict
    if ingredient_dialog[id] then
		-- If "batch finished" dialogue is played
		if id == CookoffFinishedID or id == RatsFinishedID then
			currentRecipe = 1
			totalBags = totalBags + 1
			-- Reset recipe state
			currentRecipeList ["Muriatic Acid"] = false
			currentRecipeList ["Caustic Soda"] = false
			currentRecipeList ["Hydrogen Chloride"] = false
			
			managers.chat:_receive_message (1, "[MethMagic]", "Total bags: [" .. totalBags .. "]", Color.green)
		
		-- If "ingredient added" dialogue is played
		elseif (id == CookoffAddedID or id == RatsAddedID) and (currentRecipe ["Muriatic Acid"] == true and currentRecipeList ["Caustic Soda"] == true and currentRecipeList ["Hydrogen Chloride"] ==  true) then
			currentRecipe = clampCeiling (currentRecipe + 1, 3)
		
		-- Else ID is for ingredient
		else
			-- Check to make sure that the ingredient is not already being echoed
			if currentRecipeList [ingredient_dialog [id]] == false then
				-- Flip the flag
				currentRecipeList [ingredient_dialog [id]] = true
			
				-- Print text
				managers.chat:_receive_message (1, "[MethMagic]", "[" .. currentRecipe .. "/3] [" .. ingredient_dialog[id] .. "]", Color.green)
			end
		end
	end
	
    return _queue_dialog_orig(self, id, ...)
end
-- feed_system_message () shows it to you and nobody else
		-- send_message () shows it to everyone
		-- _receive_message () shows it to everyone

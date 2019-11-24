_G.MethHelper = _G.MethHelper or {}
MethHelper._path = ModPath
MethHelper._data_path = SavePath .. 'Meth_helper.txt'
MethHelper._data = {}

function MethHelper:Save()
    local file = io.open(self._data_path, 'w+')
    if file then
        file:write(json.encode(self._data))
        file:close()
    end
end

function MethHelper:Load()
    local file = io.open(self._data_path, 'r')
    if file then
        for k, v in pairs(json.decode(file:read('*all')) or {}) do
            self._data[k] = v
        end
        file:close()
    else
        MethHelper._data.silent_toggle = false
        MethHelper._data.active_toggle = true
    end
end

Hooks:Add(
    'LocalizationManagerPostInit',
    'LocalizationManagerPostInit_MethHelper',
    function(loc)
        loc:load_localization_file(MethHelper._path .. 'menu/' .. 'lang.json')
    end
)

Hooks:Add(
    'MenuManagerInitialize',
    'MenuManagerInitialize_MethHelper',
    function(menu_manager)
        --[[
		Setup our callbacks as defined in our item callback keys, and perform our logic on the data retrieved.
	]]
        MenuCallbackHandler.callback_meth_helper_active = function(self, item)
            MethHelper._data.meth_helper_active_value = (item:value() == 'on' and true or false)
            MethHelper._data.active_toggle = item:value()
            MethHelper:Save()
        end

        MenuCallbackHandler.callback_meth_helper_silent = function(self, item)
            MethHelper._data.meth_helper_silent_value = (item:value() == 'on' and true or false)
            MethHelper._data.silent_toggle = item:value()
            MethHelper:Save()
        end

        --[[
		Load our previously saved data from our save file.
	]]
        MethHelper:Load()

        --[[
		Load our menu json file and pass it to our MenuHelper so that it can build our in-game menu for us.
		We pass our parent mod table as the second argument so that any keybind functions can be found and called
			as necessary.
		We also pass our data table as the third argument so that our saved values can be loaded from it.
	]]
        MenuHelper:LoadFromJsonFile(MethHelper._path .. 'menu/menu.json', MethHelper, MethHelper._data)
    end
)

-- Dialogue event codes
local RatsFinishedID = 'pln_rat_stage1_28'
local RatsAddedID = 'pln_rat_stage1_12'
local CookoffFinishedID = 'pln_rt1_28'
local CookoffAddedID = 'pln_rt1_12'
local BorderCrystalFinsishedID = 'Play_loc_mex_cook_17'
local BorderCrystalFinsishedID2 = 'Play_loc_mex_cook_13'
local BorderCrystalAddedID = 'Play_loc_mex_cook_22'

-- Dictionary mapping dialogue codes to plain text ingredients
local ingredient_dialog = {}
ingredient_dialog['pln_rt1_20'] = 'Muriatic Acid'
ingredient_dialog['pln_rt1_22'] = 'Caustic Soda'
ingredient_dialog['pln_rt1_24'] = 'Hydrogen Chloride'
ingredient_dialog['pln_rat_stage1_20'] = 'Muriatic Acid'
ingredient_dialog['pln_rat_stage1_22'] = 'Caustic Soda'
ingredient_dialog['pln_rat_stage1_24'] = 'Hydrogen Chloride'
ingredient_dialog['Play_loc_mex_cook_03'] = 'Muriatic Acid'
ingredient_dialog['Play_loc_mex_cook_04'] = 'Caustic Soda'
ingredient_dialog['Play_loc_mex_cook_05'] = 'Hydrogen Chloride'
-- Round about hacky way to trigger by both ingredients and recipe state dialogue
ingredient_dialog[RatsFinishedID] = true
ingredient_dialog[RatsAddedID] = true
ingredient_dialog[CookoffFinishedID] = true
ingredient_dialog[CookoffAddedID] = true
ingredient_dialog[BorderCrystalFinsishedID] = true
ingredient_dialog[BorderCrystalFinsishedID2] = true
ingredient_dialog[BorderCrystalAddedID] = true

-- Track total number of bags made
local totalBags = 0
-- Track current recipe state
local currentRecipeList = {}
currentRecipeList['Muriatic Acid'] = false
currentRecipeList['Caustic Soda'] = false
currentRecipeList['Hydrogen Chloride'] = false

IngredientCount = 0
OldIngredientCount = 0

function countAddedIngredients(Table)
    local count = 0
    for i, v in pairs(Table) do
        if v == true then
            count = count + 1
        end
    end
    return count
end

-- Trigger this every time there is dialogue
local _queue_dialog_orig = DialogManager.queue_dialog
function DialogManager:queue_dialog(id, ...)

    -- If dialogue code is found in dict
    if ingredient_dialog[id] and MethHelper._data.active_toggle == true or MethHelper._data.active_toggle == 'on' then
        -- If "batch finished" dialogue is played
        if id == CookoffFinishedID or id == RatsFinishedID or id == BorderCrystalFinsishedID or id == BorderCrystalFinsishedID2 then
            -- If "ingredient added" dialogue is played
            OldIngredientCount = 0
            totalBags = totalBags + 1
            -- Reset recipe state
            currentRecipeList['Muriatic Acid'] = false
            currentRecipeList['Caustic Soda'] = false
            currentRecipeList['Hydrogen Chloride'] = false
            -- check menu options
            if MethHelper._data.silent_toggle == true or MethHelper._data.silent_toggle == 'on' then
                managers.chat:_receive_message(1, '[SilentMethMagic]', 'Total bags: [' .. totalBags .. ']', Color.green)
            else
                managers.chat:send_message(1, '[SilentMethMagic]', 'Total bags: [' .. totalBags .. ']', Color.green)
            end
        elseif
            (id == CookoffAddedID or id == RatsAddedID or id == BorderCrystalAddedID) and ((currentRecipeList['Muriatic Acid'] == true and currentRecipeList['Caustic Soda'] == true and currentRecipeList['Hydrogen Chloride'] == true) == false) and
                ((currentRecipeList['Muriatic Acid'] == false and currentRecipeList['Caustic Soda'] == false and currentRecipeList['Hydrogen Chloride'] == false) == false)
         then
            IngredientCount = countAddedIngredients(currentRecipeList)
            if IngredientCount > OldIngredientCount then
                OldIngredientCount = IngredientCount
                if MethHelper._data.silent_toggle == true or MethHelper._data.silent_toggle == 'on' then
                    managers.chat:_receive_message(1, '[SilentMethMagic]', 'Ingredient added!', Color.green)
                else
                    managers.chat:send_message(1, '[SilentMethMagic]', 'Ingredient added!', Color.green)
                end
            end
        elseif (id == CookoffAddedID or id == RatsAddedID or id == BorderCrystalAddedID) and countAddedIngredients(currentRecipeList) == 3 then
            -- Else ID is for ingredient
            IngredientCount = countAddedIngredients(currentRecipeList)
            if IngredientCount > OldIngredientCount then
                OldIngredientCount = IngredientCount
                if MethHelper._data.silent_toggle == true or MethHelper._data.silent_toggle == 'on' then
                    managers.chat:_receive_message(1, '[SilentMethMagic]', 'Ingredient added!', Color.green)
                else
                    managers.chat:send_message(1, '[SilentMethMagic]', 'Ingredient added!', Color.green)
                end
            end
        else
            -- Check to make sure that the ingredient is not already being echoed
            if currentRecipeList[ingredient_dialog[id]] == false then
                -- Flip the flag
                currentRecipeList[ingredient_dialog[id]] = true

                -- Print text
                if MethHelper._data.silent_toggle == true or MethHelper._data.silent_toggle == 'on' then
                    managers.chat:_receive_message(1, '[SilentMethMagic]', '[' .. countAddedIngredients(currentRecipeList) .. '/3] [' .. ingredient_dialog[id] .. ']', Color.green)
                else
                    managers.chat:send_message(1, '[SilentMethMagic]', '[' .. countAddedIngredients(currentRecipeList) .. '/3] [' .. ingredient_dialog[id] .. ']', Color.green)
                end
            end
        end
    end
    -- for event mapping
    -- log("DialogManager: said " .. tostring(id))
    -- managers.chat:send_message(ChatManager.GAME, managers.network.account:username() or "Offline", id)

    return _queue_dialog_orig(self, id, ...)
end
-- feed_system_message () shows it to you and nobody else
-- send_message () shows it to everyone
-- _receive_message () shows it to everyone

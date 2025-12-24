local cooking = require("cooking")

local assets =
{
	Asset("ANIM", "anim/atbook_chefwolf.zip"),
	Asset("ANIM", "anim/atbook_chefwolf_13x7.zip"),
	Asset("ATLAS", "images/inventoryimages/atbook_chefwolf.xml"),
	Asset("ATLAS", "images/ui/container/icon_gb.xml"),
	Asset("ATLAS", "images/ui/container/icon_gz_1.xml"),
	Asset("ATLAS", "images/ui/container/icon_gz_2.xml"),
	Asset("ATLAS", "images/ui/container/icon_gz_3.xml"),
	Asset("ATLAS", "images/ui/container/icon_k.xml"),
}

local function GetCook(prefab)
	for k, v in pairs(cooking.recipes.cookpot) do
		if v.name == prefab then
			return v
		end
	end
	for k, v in pairs(cooking.recipes.portablecookpot) do
		if v.name == prefab then
			return v
		end
	end
end

local function IsModCook(prefab)
	for cooker, recipes in pairs(cooking.recipes) do
		if IsModCookingProduct(cooker, prefab) then return true end
	end
	return false
end

local function ItemChange(inst, data)
	local container = inst.components.container
	if container then
		inst.AnimState:ClearAllOverrideSymbols()
		local item = container.slots[1]
		if item and item:IsValid() then
			local prefab = item.prefab
			prefab = string.gsub(prefab, "_spice_garlic", "")
			prefab = string.gsub(prefab, "_spice_sugar", "")
			prefab = string.gsub(prefab, "_spice_chili", "")
			prefab = string.gsub(prefab, "_spice_salt", "")
			local recipe = GetCook(prefab)
			if recipe then
				local overridebuild = IsModCook(item.prefab) and item.prefab or nil
				local build = recipe.overridebuild or overridebuild or "cook_pot_food"
				local overridesymbol = recipe.overridesymbolname or prefab
				inst.AnimState:OverrideSymbol("food", build, overridesymbol)
			end
		end
	end
end

local function InitFn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 0.4, 0.6)

	inst.AnimState:SetBank("atbook_chefwolf")
	inst.AnimState:SetBuild("atbook_chefwolf")
	inst.AnimState:PlayAnimation("idle_full", true)

	inst:AddTag("atbook_chefwolf")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst.OnEntityReplicated = function(inst)
			inst.replica.container:WidgetSetup("atbook_chefwolf")
		end
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("atbook_chefwolf")

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("atbook_chefwolf")

	inst:AddComponent("preserver")
	inst.components.preserver:SetPerishRateMultiplier(-1)

	inst:ListenForEvent("itemget", ItemChange)
	inst:ListenForEvent("itemlose", ItemChange)

	return inst
end

STRINGS.NAMES.ATBOOK_CHEFWOLF = "小狼大厨"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ATBOOK_CHEFWOLF = "要试一试族长大人的厨艺嘛？"
STRINGS.RECIPE_DESC.ATBOOK_CHEFWOLF = "要试一试族长大人的厨艺嘛？"

return Prefab("atbook_chefwolf", InitFn, assets),
	MakePlacer("atbook_chefwolf_placer", "atbook_chefwolf", "atbook_chefwolf", "idle_empty")

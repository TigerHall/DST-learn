local prefs = {}

local assets =
{
    Asset("ANIM", "anim/hmr_preparedfoods.zip"),
}

local prefabs =
{
    "spoiled_food",
}
local cacheAtlas={}--图片缓存，减少文件读取次数
--获取图片背景通道
local function getItemImageAtlas(name)
	if cacheAtlas[name] then
        return cacheAtlas[name]--优先读取缓存数据
    end
    local img=name..".tex"
	local trueatlas = softresolvefilepath("images/inventoryimages/"..name..".xml")
	if trueatlas and TheSim:AtlasContains(trueatlas, img) then
		cacheAtlas[name]="images/inventoryimages/"..name..".xml"
        return cacheAtlas[name]
	end
	trueatlas = softresolvefilepath("images/"..name..".xml")
	if trueatlas and TheSim:AtlasContains(trueatlas, img) then
		cacheAtlas[name]="images/"..name..".xml"
        return cacheAtlas[name]
	end
	trueatlas = softresolvefilepath("images/monkey_king_item.xml")
	if trueatlas and TheSim:AtlasContains(trueatlas, img) then
		cacheAtlas[name]="images/monkey_king_item.xml"
        return cacheAtlas[name]
	end
	return nil
end

local function IsNativeCookingProduct(name, ismaster)
	--普通料理
	if not ismaster then
		for k, v in pairs(require("preparedfoods")) do
			if name==v.name then
				return true
			end
		end
	end
	--大厨料理
	for k, v in pairs(require("preparedfoods_warly")) do
		if name==v.name then
			return true
		end
	end
    return false
end

local function MakePreparedFood(data)
    local foodassets = assets
    local spicename = data.spice ~= nil and string.lower(data.spice) or nil
    if spicename ~= nil then
		foodassets = shallowcopy(assets)
		table.insert(foodassets, Asset("ANIM", "anim/hmr_spices.zip"))
		table.insert(foodassets, Asset("ATLAS", "images/inventoryimages/"..spicename.."_over.xml"))
        table.insert(foodassets, Asset("IMAGE", "images/inventoryimages/"..spicename.."_over.tex"))
        table.insert(foodassets, Asset("ATLAS_BUILD", "images/inventoryimages/"..spicename.."_over.xml", 256))
    end

    local foodprefabs = prefabs
    if data.prefabs ~= nil then
        foodprefabs = shallowcopy(prefabs)
        for i, v in ipairs(data.prefabs) do
            if not table.contains(foodprefabs, v) then
                table.insert(foodprefabs, v)
            end
        end
    end

    --更换料理展示名字
	local function DisplayNameFn(inst)
        return subfmt(STRINGS.NAMES[data.spice.."_FOOD"], { food = STRINGS.NAMES[string.upper(data.basename)] })
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

		local food_symbol_build = nil
        if spicename ~= nil then
            inst.AnimState:SetBuild("plate_food")
            inst.AnimState:SetBank("plate_food")
            inst.AnimState:PlayAnimation("idle")
            --调料贴图展示
			inst.AnimState:OverrideSymbol("swap_garnish", "hmr_spices", spicename)

            inst:AddTag("spicedfood")

			--设置背景料理贴图
			inst.inv_image_bg = { image = (data.basename or data.name)..".tex" }
            inst.inv_image_bg.atlas = getItemImageAtlas(data.basename or data.name) or GetInventoryItemAtlas(inst.inv_image_bg.image)

			food_symbol_build = data.overridebuild or "cook_pot_food"
        else
			inst.AnimState:SetBuild(data.overridebuild or "cook_pot_food")
			inst.AnimState:SetBank(data.overridebank or "cook_pot_food")
            inst.AnimState:PlayAnimation(data.overrideanim or "idle")
        end

        inst.AnimState:OverrideSymbol("swap_food", data.overridebuild or (IsNativeCookingProduct(data.basename) and (food_symbol_build or "cook_pot_food")) or data.basename, data.basename or data.name)

        inst:AddTag("preparedfood")
        if data.tags ~= nil then
            for i,v in pairs(data.tags) do
                inst:AddTag(v)
            end
        end

        if data.basename ~= nil then
            inst:SetPrefabNameOverride(data.basename)
            if data.spice ~= nil then
                inst.displaynamefn = DisplayNameFn
            end
        end

        if data.floater ~= nil then
            MakeInventoryFloatable(inst, data.floater[1], data.floater[2], data.floater[3])
        else
            MakeInventoryFloatable(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

		inst.food_symbol_build = food_symbol_build or data.overridebuild

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = data.health or 0
        inst.components.edible.hungervalue = data.hunger or 0
        inst.components.edible.foodtype = data.foodtype or FOODTYPE.GENERIC
        inst.components.edible.sanityvalue = data.sanity or 0
        inst.components.edible.temperaturedelta = data.temperature or 0
        inst.components.edible.temperatureduration = data.temperatureduration or 0
        inst.components.edible.nochill = data.nochill or nil
        inst.components.edible.spice = data.spice
        inst.components.edible:SetOnEatenFn(data.oneatenfn)

        inst:AddComponent("inspectable")
        inst.wet_prefix = data.wet_prefix

        inst:AddComponent("inventoryitem")

        if spicename ~= nil then
            inst.components.inventoryitem.atlasname = "images/inventoryimages/"..spicename.."_over.xml"--修改物品栏贴图，前景为调料，背景为料理
			inst.components.inventoryitem:ChangeImageName(spicename.."_over")
        elseif data.basename ~= nil then
            inst.components.inventoryitem.atlasname = "images/inventoryimages/"..data.basename..".xml"
            inst.components.inventoryitem:ChangeImageName(data.basename)
		end
		--神话相关兼容，部分料理不可堆叠
        if not data.nostack then
			inst:AddComponent("stackable")
			inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
		end

        if data.perishtime ~= nil and data.perishtime > 0 then
            inst:AddComponent("perishable")
            inst.components.perishable:SetPerishTime(data.perishtime)
            inst.components.perishable:StartPerishing()
            inst.components.perishable.onperishreplacement = "spoiled_food"
        end

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableLaunchAndPerish(inst)

        inst:AddComponent("bait")

        inst:AddComponent("tradable")

        return inst
    end

    table.insert(prefs, Prefab(data.name, fn, foodassets, foodprefabs))
end

for k, v in pairs(require("hmrmain/hmr_spicedfoods").GetSpicedFoods()) do
    MakePreparedFood(v)
end
for k, v in pairs(require("hmrmain/hmr_preparedfoods")) do
    MakePreparedFood(v)
end


return unpack(prefs)

-- HMR_UTIL.PreRegisterPrefab(unpack(prefs))
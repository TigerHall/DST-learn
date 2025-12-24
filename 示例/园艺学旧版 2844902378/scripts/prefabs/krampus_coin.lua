local assets =
{
  Asset("ANIM", "anim/quagmire_coins.zip"),
  Asset("ATLAS", "images/inventoryimages/krampus_coin.xml"),
  Asset("IMAGE", "images/inventoryimages/krampus_coin.tex"),
}

local prefabs = 
{
}

local regenvolume = 600
local regenspeed = 2.5
local regenhealth = -5
local regensanity = -5
local regenhungry = -5 

local function onstartregen(inst, drinker)
	drinker.regenvalue = regenvolume
	if not drinker.written then
		drinker.written = true
		local OldOnSave = drinker.OnSave
		drinker.OnSave = function(inst,data)
			if OldOnSave then
				OldOnSave(inst,data)
			end
			data.regenvalue = inst.regenvalue or 0
		end
		local OldOnPreLoad = drinker.OnPreLoad
		drinker.OnLoad = function(inst,data)
			if OldOnLoad then
				OldOnLoad(inst,data)
			end
			inst.regenpotiontask = inst:DoPeriodicTask(regenspeed,function()
				if inst.regenvalue == 0 then 
					inst.regenpotiontask:Cancel()
					inst.regenpotiontask = nil
				else
					inst.components.health:DoDelta(regenhealth) 
					inst.components.sanity:DoDelta(regensanity) 
				end
			end)
		end
	end
	if drinker.regenpotiontask then
		drinker.regenpotiontask:Cancel()
		drinker.regenpotiontask = nil
	end
	if drinker:HasTag("player") and not drinker:HasTag("playerghost") then
		drinker.regenpotiontask = drinker:DoPeriodicTask(regenspeed,function()
			if drinker.regenvalue == 0 then 
				drinker.regenpotiontask:Cancel()
				drinker.regenpotiontask = nil
			else
				drinker.components.health:DoDelta(regenhealth) 
				drinker.components.sanity:DoDelta(regensanity) 
				drinker.regenvalue = drinker.regenvalue - 1
			end
		end)
		drinker:ListenForEvent("death", function()
			if drinker.regenpotiontask then
				drinker.regenpotiontask:Cancel()
				drinker.regenpotiontask = nil
			end
		end)
	end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
	
    inst.AnimState:SetBank("quagmire_coins")
    inst.AnimState:SetBuild("quagmire_coins")
    inst.AnimState:PlayAnimation("idle")
	inst.AnimState:OverrideSymbol("coin01", "quagmire_coins", "coin0"..tostring(2))
    inst.AnimState:OverrideSymbol("coin_shad1", "quagmire_coins", "coin_shad"..tostring(2))
	
	MakeInventoryFloatable(inst, "med", nil, 0.35)
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")
		
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "krampus_coin"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/krampus_coin.xml"
	
	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 6
	inst.components.tradable.tradefor = { "butter","butter","nightmarefuel","nightmarefuel","ice","ice","ice","ice","ice","ice"}
	
	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL
		
	inst:AddComponent("boatpatch")
	inst.components.boatpatch.patch_type = "treegrowth"
    inst:AddComponent("repairer")
	inst.components.repairer.repairmaterial = MATERIALS.WOOD
	inst.components.repairer.healthrepairvalue = (200)
	
	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(480)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "humanmeat"
    
    inst:AddComponent("edible")
    inst.components.edible.hungervalue = 200
	inst.components.edible.sanityvalue = 300
	inst.components.edible.healthvalue = 300
	inst.components.edible:SetOnEatenFn(onstartregen)
	inst.components.edible.foodtype = "MEAT"
	
    inst:AddComponent("bait")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("common/inventory/krampus_coin", fn, assets, prefabs)
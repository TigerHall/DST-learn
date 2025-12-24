local prefs = {}

local function MakePrime(name, data)
    local assets = {
        Asset("ANIM", "anim/hmr_primes.zip"),
    }

    local buff_name = data.buff or name.."_buff"

    local function OnEaten(inst, eater)
        if eater.components.hunger and eater.components.debuffable then
            eater.components.debuffable:AddDebuff(buff_name, buff_name)
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("hmr_primes")
        inst.AnimState:SetBuild("hmr_primes")
        inst.AnimState:PlayAnimation(name)

        inst:AddTag("hmr_prime")
        if data.tags ~= nil then
            for _, tag in ipairs(data.tags) do
                inst:AddTag(tag)
            end
        end

        MakeInventoryFloatable(inst, "small", .1)

        if data.common_postinit ~= nil then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..name..".xml"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

        inst:AddComponent("tradable")

        inst:AddComponent("edible")
        inst.components.edible.healthvalue = 0
        inst.components.edible.hungervalue = 0
        inst.components.edible.sanityvalue = 0
        inst.components.edible.foodtype = FOODTYPE.VEGGIE
        inst.components.edible:SetOnEatenFn(OnEaten)

        if data.master_postinit then
            data.master_postinit(inst)
        end

        MakeHauntableLaunch(inst)

        return inst
    end
    table.insert(prefs, Prefab(name, fn, assets))
end

local PRIMES = {
    honor_aloe_prime = {
        tags = {"honor_prime", "honor_aloe_prime"},
    },
    honor_hamimelon_prime = {
        tags = {"honor_prime", "honor_hamimelon_prime"},
    },
    honor_nut_prime = {
        tags = {"honor_prime", "honor_nut_prime"},
    },
    honor_goldenlanternfruit_prime = {
        tags = {"honor_prime", "honor_goldenlanternfruit_prime"},
    },
    honor_rice_prime = {
        tags = {"honor_prime", "honor_rice_prime"},
        master_postinit = function(inst)
            inst.components.edible.hungervalue = 60
        end
    },
    honor_wheat_prime = {
        tags = {"honor_prime", "honor_wheat_prime"},
        master_postinit = function(inst)
            inst.components.edible.hungervalue = 60
        end
    },
    honor_coconut_prime = {
        tags = {"honor_prime", "honor_coconut_prime"},
        master_postinit = function(inst)
            inst.components.edible.foodtype = FOODTYPE.MEAT
            inst.components.edible.secondaryfoodtype = FOODTYPE.VEGGIE
        end
    },
    honor_tea_prime = {
        tags = {"honor_prime", "honor_tea_prime"},
        master_postinit = function(inst)
            inst.components.edible.sanityvalue = 99999
        end
    },
    terror_blueberry_prime = {
        tags = {"terror_prime", "terror_blueberry_prime"},
    },
    terror_snakeskinfruit_prime = {
        tags = {"terror_prime", "terror_snakeskinfruit_prime"},
    },
    terror_ginger_prime = {
        tags = {"terror_prime", "terror_ginger_prime"},
    },
    terror_litchi_prime = {
        tags = {"terror_prime", "terror_litchi_prime"},
    },
    terror_coffee_prime = {
        tags = {"terror_prime", "terror_coffee_prime"},
    },
    terror_hawthorn_prime = {
        tags = {"terror_prime", "terror_hawthorn_prime"},
    },
    terror_bellpepper_prime = {
        tags = {"terror_prime", "terror_bellpepper_prime"},
    },
    terror_passionfruit_prime = {
        tags = {"terror_prime", "terror_passionfruit_prime"},
    },
}

for name, data in pairs(PRIMES) do
    MakePrime(name, data)
end

return unpack(prefs)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    梅影装饰花丛

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_plum_blossom_bush_rose_skin_fx"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_plum_blossom_bush_flower_thickets.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function client_side_fx(parent)
        for i = 0, 5, 1 do
            local inst = CreateEntity()
            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst:AddTag("FX")
            inst:AddTag("fx")
            inst:AddTag("NOBLOCK")
            inst.entity:SetParent(parent.entity)
            inst.AnimState:SetBank("tbat_plant_plum_blossom_bush_flower_thickets")
            inst.AnimState:SetBuild("tbat_plant_plum_blossom_bush_flower_thickets")
            inst.AnimState:PlayAnimation("fx"..i,true)
            inst.AnimState:SetTime(math.random()*2)
            -- inst.AnimState:SetSortOrder(1)
            inst.AnimState:SetFinalOffset(1)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst:AddTag("FX")
        inst:AddTag("fx")
        inst:AddTag("NOBLOCK")
        inst.entity:SetPristine()
        inst.persists = false   --- 是否留存到下次存档加载。
        if not TheNet:IsDedicated() then
            client_side_fx(inst)
        end
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)
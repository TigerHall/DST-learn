--击杀
local excluded_prefabs = {
    lureplant = true,
    elecarmet = true,
    klaus = true
}
-- 采集
local notpick = {
    statueglommer = 1,
    neverfadebush = 1,
    plant_certificate = 1,
    medal_wormwood_flower = 1,
    archive_switch = 1,
}
-- 双倍采集
local function onpick(inst, data)
    if data.object and data.object.components.pickable and
        not data.object.components.trader then
        if data.object.components.pickable.use_lootdropper_for_product and data.object.components.lootdropper then
            local loot = {}
            for _, prefab in ipairs(data.object.components.lootdropper:GenerateLoot()) do
                table.insert(loot, data.object.components.lootdropper:SpawnLootPrefab(prefab))
            end
            if not next(loot) and next(data.loot) then
                for k, v in pairs(data.loot) do
                    if v and v.prefab then
                        table.insert(loot, data.object.components.lootdropper:SpawnLootPrefab(v.prefab))
                    end
                end
            end
            for i, item in ipairs(loot) do
                if item.components.inventoryitem ~= nil then
                    inst.components.inventory:GiveItem(item, nil, inst:GetPosition())
                end
            end
        elseif data.object.components.pickable.product ~= nil and not notpick[data.object.prefab] then
            local item = SpawnPrefab(data.object.components.pickable.product)
            if item.components.stackable then
                item.components.stackable:SetStackSize(data.object.components.pickable.numtoharvest)
            end
            inst.components.inventory:GiveItem(item, nil, data.object:GetPosition())
            if (data.object.prefab == "cactus" or data.object.prefab == "oasis_cactus") and data.object.has_flower then
                local item2 = SpawnPrefab("cactus_flower")
                inst.components.inventory:GiveItem(item2, nil, data.object:GetPosition())
            end
        end
    end
end

local function onbuild(inst, data)
    if inst and data then
        if inst:HasDebuff("tbat_wishnote_buff", "tbat_wishnote_buff") then
            inst:RemoveDebuff("tbat_wishnote_buff")
        end
    end
end

local SHADOWCREATURE_MUST_TAGS = { "shadowcreature", "_combat", "locomotor" }
local SHADOWCREATURE_CANT_TAGS = { "INLIMBO", "notaunt" }
local function OnReadFn(inst, book)
    if inst.components.sanity:IsInsane() then
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 16, SHADOWCREATURE_MUST_TAGS, SHADOWCREATURE_CANT_TAGS)
        if #ents < TUNING.BOOK_MAX_SHADOWCREATURES then
            TheWorld.components.shadowcreaturespawner:SpawnShadowCreature(inst)
        end
    end
end

local function launchitem(item)
    local speed = math.random() * 5 + 2
    local angle = math.random(360) * DEGREES
    item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
end


local debuffs_def = {
    {
        prefab = "tbat_kill_get_drop",
        name = "击杀获取掉落物", --buff名称
        name_en = "击杀获取掉落物", --buff名称（英语）
        time = 999, --持续时间（s）
        tags = { "indefinite" }, --标签（indefinite：无限时间）
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                inst._fx.entity:SetParent(target.entity)
                if not inst.tbat_kill_get_drop then
                    inst.tbat_kill_get_drop = function (src, pushdata)
                        if src and src.components.inventory
                            and pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatdropget")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            local loots = pushdata.victim.components.lootdropper:GetAllPossibleLoot()
                            for k, v in pairs(loots) do
                                src.components.inventory:GiveItem(SpawnPrefab(k))
                            end
                            pushdata.victim:AddTag("tbatdropget")
                        end
                    end
                    inst:ListenForEvent("killed", inst.tbat_kill_get_drop, target)
                end
                
            end
        end,
        OnDetached = function(inst, target)
            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            if target then
                -- inst移除的时候监听其实就自己会消失，但是还是手动移除一下比较好
                if not inst.tbat_kill_get_drop then
                    inst.tbat_kill_get_drop = function(src, pushdata)
                        if src and src.components.inventory
                            and pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatdropget")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            local loots = pushdata.victim.components.lootdropper:GetAllPossibleLoot()
                            for k, v in pairs(loots) do
                                src.components.inventory:GiveItem(SpawnPrefab(k))
                            end
                            pushdata.victim:AddTag("tbatdropget")
                        end
                    end
                end
                inst:RemoveEventCallback("killed", inst.tbat_kill_get_drop, target)
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_kill_get_drop then
                    inst.tbat_kill_get_drop = function(src, pushdata)
                        if src and src.components.inventory
                            and pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatdropget")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            local loots = pushdata.victim.components.lootdropper:GetAllPossibleLoot()
                            for k, v in pairs(loots) do
                                src.components.inventory:GiveItem(SpawnPrefab(k))
                            end
                            pushdata.victim:AddTag("tbatdropget")
                        end
                    end
                end
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },
    {
        prefab = "tbat_kill_get_drop2",
        name = "击杀获取掉落物", --buff名称
        name_en = "击杀获取掉落物", --buff名称（英语）
        time = 480, --持续时间（s）
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                inst._fx.entity:SetParent(target.entity)
                if not inst.tbat_kill_get_drop then
                    inst.tbat_kill_get_drop = function(src, pushdata)
                        if src and src.components.inventory
                            and pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatdropget")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            local loots = pushdata.victim.components.lootdropper:GetAllPossibleLoot()
                            for k, v in pairs(loots) do
                                src.components.inventory:GiveItem(SpawnPrefab(k))
                            end
                            pushdata.victim:AddTag("tbatdropget")
                        end
                    end
                    inst:ListenForEvent("killed", inst.tbat_kill_get_drop, target)
                end
            end
        end,
        OnDetached = function(inst, target)
            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            if target then
                -- inst移除的时候监听其实就自己会消失，但是还是手动移除一下比较好
                if not inst.tbat_kill_get_drop then
                    inst.tbat_kill_get_drop = function(src, pushdata)
                        if src and src.components.inventory
                            and pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatdropget")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            local loots = pushdata.victim.components.lootdropper:GetAllPossibleLoot()
                            for k, v in pairs(loots) do
                                src.components.inventory:GiveItem(SpawnPrefab(k))
                            end
                            pushdata.victim:AddTag("tbatdropget")
                        end
                    end
                end
                inst:RemoveEventCallback("killed", inst.tbat_kill_get_drop, target)
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_kill_get_drop then
                    inst.tbat_kill_get_drop = function(src, pushdata)
                        if src and src.components.inventory
                            and pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatdropget")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            local loots = pushdata.victim.components.lootdropper:GetAllPossibleLoot()
                            for k, v in pairs(loots) do
                                src.components.inventory:GiveItem(SpawnPrefab(k))
                            end
                            pushdata.victim:AddTag("tbatdropget")
                        end
                    end
                end
            end
        end,
        OnTimerDone = function(inst, data)
            --计时结束时移除效果并告知效果结束
            if data.name == "buffover" then
                local target = inst.entity:GetParent()
                --特效
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                if target then
                    -- inst移除的时候监听其实就自己会消失，但是还是手动移除一下比较好
                    if not inst.tbat_kill_get_drop then
                        inst.tbat_kill_get_drop = function(src, pushdata)
                            if src and src.components.inventory
                                and pushdata.victim
                                and pushdata.victim.components.lootdropper
                                and not pushdata.victim:HasTag("tbatdropget")
                                and not excluded_prefabs[pushdata.victim.prefab]
                            then
                                local loots = pushdata.victim.components.lootdropper:GetAllPossibleLoot()
                                for k, v in pairs(loots) do
                                    src.components.inventory:GiveItem(SpawnPrefab(k))
                                end
                                pushdata.victim:AddTag("tbatdropget")
                            end
                        end
                    end
                    inst:RemoveEventCallback("killed", inst.tbat_kill_get_drop, target)
                end
                inst:Remove()
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },
    {
        prefab = "tbat_make_half",
        name = "制作减半", --buff名称
        name_en = "制作减半", --buff名称（英语）
        time = 999, --持续时间（s）
        tags = { "indefinite" },
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if target.components.builder then
                    local oldingredientmod = target.components.builder.ingredientmod
                    if oldingredientmod and oldingredientmod > 0.5 then
                        target.components.builder.ingredientmod = 0.5
                        inst.oldingredientmod = oldingredientmod
                    end
                end
                
            end
        end,
        OnDetached = function(inst, target)
            if target then
                if inst.oldingredientmod then
                    target.components.builder.ingredientmod = inst.oldingredientmod
                end
            end

            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if target.components.builder then
                    local oldingredientmod = target.components.builder.ingredientmod
                    if oldingredientmod and oldingredientmod > 0.5 then
                        target.components.builder.ingredientmod = 0.5
                        inst.oldingredientmod = oldingredientmod
                    end
                end
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_make_half2",
        name = "制作减半", --buff名称
        name_en = "制作减半", --buff名称（英语）
        time = 60, --持续时间（s）
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if target.components.builder then
                    local oldingredientmod = target.components.builder.ingredientmod
                    if oldingredientmod and oldingredientmod > 0.5 then
                        target.components.builder.ingredientmod = 0.5
                        inst.oldingredientmod = oldingredientmod
                    end
                end
            end
        end,
        OnDetached = function(inst, target)
            if target then
                if inst.oldingredientmod then
                    target.components.builder.ingredientmod = inst.oldingredientmod
                end
            end

            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if target.components.builder then
                    local oldingredientmod = target.components.builder.ingredientmod
                    if oldingredientmod and oldingredientmod > 0.5 then
                        target.components.builder.ingredientmod = 0.5
                        inst.oldingredientmod = oldingredientmod
                    end
                end
            end
        end,
        OnTimerDone = function(inst, data)
            --计时结束时移除效果并告知效果结束
            if data.name == "buffover" then
                local target = inst.entity:GetParent()
                --特效
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                if target then
                    if inst.oldingredientmod then
                        target.components.builder.ingredientmod = inst.oldingredientmod
                    end
                end
                inst:Remove()
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_double_drop",
        name = "双倍掉落", --buff名称
        name_en = "双倍掉落", --buff名称（英语）
        time = 999, --持续时间（s）
        tags = { "indefinite" },
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_double_drop then
                    inst.tbat_double_drop = function(src, pushdata)
                        if pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatkilled")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            pushdata.victim.components.lootdropper:DropLoot()
                            pushdata.victim:AddTag("tbatkilled")
                        end
                    end
                    inst:ListenForEvent("killed", inst.tbat_double_drop, target)
                end
                
            end
        end,
        OnDetached = function(inst, target)
            if target then
                if not inst.tbat_double_drop then
                    inst.tbat_double_drop = function(src, pushdata)
                        if pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatkilled")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            pushdata.victim.components.lootdropper:DropLoot()
                            pushdata.victim:AddTag("tbatkilled")
                        end
                    end
                end
                inst:RemoveEventCallback("killed", inst.tbat_double_drop, target)
            end

            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_double_drop then
                    inst.tbat_double_drop = function(src, pushdata)
                        if pushdata and pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatkilled")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            pushdata.victim.components.lootdropper:DropLoot()
                            pushdata.victim:AddTag("tbatkilled")
                        end
                    end
                end
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_double_drop2",
        name = "双倍掉落", --buff名称
        name_en = "双倍掉落", --buff名称（英语）
        time = 480, --持续时间（s）
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_double_drop then
                    inst.tbat_double_drop = function(src, pushdata)
                        if pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatkilled")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            pushdata.victim.components.lootdropper:DropLoot()
                            pushdata.victim:AddTag("tbatkilled")
                        end
                    end
                    inst:ListenForEvent("killed", inst.tbat_double_drop, target)
                end
            end
        end,
        OnDetached = function(inst, target)
            if target then
                if not inst.tbat_double_drop then
                    inst.tbat_double_drop = function(src, pushdata)
                        if pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatkilled")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            pushdata.victim.components.lootdropper:DropLoot()
                            pushdata.victim:AddTag("tbatkilled")
                        end
                    end
                end
                inst:RemoveEventCallback("killed", inst.tbat_double_drop, target)
            end

            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_double_drop then
                    inst.tbat_double_drop = function(src, pushdata)
                        if pushdata and pushdata.victim
                            and pushdata.victim.components.lootdropper
                            and not pushdata.victim:HasTag("tbatkilled")
                            and not excluded_prefabs[pushdata.victim.prefab]
                        then
                            pushdata.victim.components.lootdropper:DropLoot()
                            pushdata.victim:AddTag("tbatkilled")
                        end
                    end
                end
            end
        end,
        OnTimerDone = function(inst, data)
            --计时结束时移除效果并告知效果结束
            if data.name == "buffover" then
                local target = inst.entity:GetParent()
                --特效
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                if target then
                    if not inst.tbat_double_drop then
                        inst.tbat_double_drop = function(src, pushdata)
                            if pushdata.victim
                                and pushdata.victim.components.lootdropper
                                and not pushdata.victim:HasTag("tbatkilled")
                                and not excluded_prefabs[pushdata.victim.prefab]
                            then
                                pushdata.victim.components.lootdropper:DropLoot()
                                pushdata.victim:AddTag("tbatkilled")
                            end
                        end
                    end
                    inst:RemoveEventCallback("killed", inst.tbat_double_drop, target)
                end
                inst:Remove()
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_one_shot",
        name = "一击必杀(1%)", --buff名称
        name_en = "一击必杀(1%)", --buff名称（英语）
        time = 999, --持续时间（s）
        tags = { "indefinite" },
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_one_shot then
                    inst.tbat_one_shot = function(src, pushdata)
                        if pushdata and pushdata.target then
                            local target2 = pushdata.target
                            if math.random() < 0.01 and target2:IsValid() and target2.components.health and not target2.components.health:IsDead() and target2.components.combat then
                                target2.components.health._ignore_maxdamagetakenperhit = true
                                target2.components.health:DoDelta(-target2.components.health.currenthealth, nil, src.prefab, nil, src, true)
                                target2.components.health._ignore_maxdamagetakenperhit = nil
                                if target2.components.health:IsDead() and not target2.tbat_kill then
                                    src:PushEvent("killed", { victim = target2 })
                                    if target2.components.combat ~= nil and target2.components.combat.onkilledbyother ~= nil then
                                        target2.components.combat.onkilledbyother(target2, src)
                                    end
                                    target2.tbat_kill = true
                                end
                            end
                        end
                    end
                    inst:ListenForEvent("onhitother", inst.tbat_one_shot, target)
                end
                
            end
        end,
        OnDetached = function(inst, target)
            if target then
                if not inst.tbat_one_shot then
                    inst.tbat_one_shot = function(src, pushdata)
                        if pushdata and pushdata.target then
                            local target2 = pushdata.target
                            if math.random() < 0.01 and target2:IsValid() and target2.components.health and not target2.components.health:IsDead() and target2.components.combat then
                                target2.components.health._ignore_maxdamagetakenperhit = true
                                target2.components.health:DoDelta(-target2.components.health.currenthealth, nil,
                                src.prefab, nil, src, true)
                                target2.components.health._ignore_maxdamagetakenperhit = nil
                                if target2.components.health:IsDead() and not target2.tbat_kill then
                                    src:PushEvent("killed", { victim = target2 })
                                    if target2.components.combat ~= nil and target2.components.combat.onkilledbyother ~= nil then
                                        target2.components.combat.onkilledbyother(target2, src)
                                    end
                                    target2.tbat_kill = true
                                end
                            end
                        end
                    end
                end
                inst:RemoveEventCallback("onhitother", inst.tbat_one_shot, target)
            end

            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_one_shot then
                    inst.tbat_one_shot = function(src, pushdata)
                        if pushdata and pushdata.target then
                            local target2 = pushdata.target
                            if math.random() < 0.01 and target2:IsValid() and target2.components.health and not target2.components.health:IsDead() and target2.components.combat then
                                target2.components.health._ignore_maxdamagetakenperhit = true
                                target2.components.health:DoDelta(-target2.components.health.currenthealth, nil,
                                src.prefab, nil, src, true)
                                target2.components.health._ignore_maxdamagetakenperhit = nil
                                if target2.components.health:IsDead() and not target2.tbat_kill then
                                    src:PushEvent("killed", { victim = target2 })
                                    if target2.components.combat ~= nil and target2.components.combat.onkilledbyother ~= nil then
                                        target2.components.combat.onkilledbyother(target2, src)
                                    end
                                    target2.tbat_kill = true
                                end
                            end
                        end
                    end
                end
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_one_shot2",
        name = "一击必杀(1%)", --buff名称
        name_en = "一击必杀(1%)", --buff名称（英语）
        time = 480, --持续时间（s）
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_one_shot then
                    inst.tbat_one_shot = function(src, pushdata)
                        if pushdata and pushdata.target then
                            local target2 = pushdata.target
                            if math.random() < 0.01 and target2:IsValid() and target2.components.health and not target2.components.health:IsDead() and target2.components.combat then
                                target2.components.health._ignore_maxdamagetakenperhit = true
                                target2.components.health:DoDelta(-target2.components.health.currenthealth, nil,
                                    src.prefab, nil, src, true)
                                target2.components.health._ignore_maxdamagetakenperhit = nil
                                if target2.components.health:IsDead() and not target2.tbat_kill then
                                    src:PushEvent("killed", { victim = target2 })
                                    if target2.components.combat ~= nil and target2.components.combat.onkilledbyother ~= nil then
                                        target2.components.combat.onkilledbyother(target2, src)
                                    end
                                    target2.tbat_kill = true
                                end
                            end
                        end
                    end
                    inst:ListenForEvent("onhitother", inst.tbat_one_shot, target)
                end
            end
        end,
        OnDetached = function(inst, target)
            if target then
                if not inst.tbat_one_shot then
                    inst.tbat_one_shot = function(src, pushdata)
                        if pushdata and pushdata.target then
                            local target2 = pushdata.target
                            if math.random() < 0.01 and target2:IsValid() and target2.components.health and not target2.components.health:IsDead() and target2.components.combat then
                                target2.components.health._ignore_maxdamagetakenperhit = true
                                target2.components.health:DoDelta(-target2.components.health.currenthealth, nil,
                                    src.prefab, nil, src, true)
                                target2.components.health._ignore_maxdamagetakenperhit = nil
                                if target2.components.health:IsDead() and not target2.tbat_kill then
                                    src:PushEvent("killed", { victim = target2 })
                                    if target2.components.combat ~= nil and target2.components.combat.onkilledbyother ~= nil then
                                        target2.components.combat.onkilledbyother(target2, src)
                                    end
                                    target2.tbat_kill = true
                                end
                            end
                        end
                    end
                end
                inst:RemoveEventCallback("onhitother", inst.tbat_one_shot, target)
            end

            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_one_shot then
                    inst.tbat_one_shot = function(src, pushdata)
                        if pushdata and pushdata.target then
                            local target2 = pushdata.target
                            if math.random() < 0.01 and target2:IsValid() and target2.components.health and not target2.components.health:IsDead() and target2.components.combat then
                                target2.components.health._ignore_maxdamagetakenperhit = true
                                target2.components.health:DoDelta(-target2.components.health.currenthealth, nil,
                                    src.prefab, nil, src, true)
                                target2.components.health._ignore_maxdamagetakenperhit = nil
                                if target2.components.health:IsDead() and not target2.tbat_kill then
                                    src:PushEvent("killed", { victim = target2 })
                                    if target2.components.combat ~= nil and target2.components.combat.onkilledbyother ~= nil then
                                        target2.components.combat.onkilledbyother(target2, src)
                                    end
                                    target2.tbat_kill = true
                                end
                            end
                        end
                    end
                end
            end
        end,
        OnTimerDone = function(inst, data)
            --计时结束时移除效果并告知效果结束
            if data.name == "buffover" then
                local target = inst.entity:GetParent()
                --特效
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                if target then
                    if not inst.tbat_one_shot then
                        inst.tbat_one_shot = function(src, pushdata)
                            if pushdata and pushdata.target then
                                local target2 = pushdata.target
                                if math.random() < 0.01 and target2:IsValid() and target2.components.health and not target2.components.health:IsDead() and target2.components.combat then
                                    target2.components.health._ignore_maxdamagetakenperhit = true
                                    target2.components.health:DoDelta(-target2.components.health.currenthealth, nil,
                                        src.prefab, nil, src, true)
                                    target2.components.health._ignore_maxdamagetakenperhit = nil
                                    if target2.components.health:IsDead() and not target2.tbat_kill then
                                        src:PushEvent("killed", { victim = target2 })
                                        if target2.components.combat ~= nil and target2.components.combat.onkilledbyother ~= nil then
                                            target2.components.combat.onkilledbyother(target2, src)
                                        end
                                        target2.tbat_kill = true
                                    end
                                end
                            end
                        end
                    end
                    inst:RemoveEventCallback("onhitother", inst.tbat_one_shot, target)
                end
                inst:Remove()
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_double_collect",
        name = "双倍采集", --buff名称
        name_en = "双倍采集", --buff名称（英语）
        time = 999, --持续时间（s）
        tags = { "indefinite" },
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_double_collect then
                    inst.tbat_double_collect = onpick
                    inst:ListenForEvent("picksomething", inst.tbat_double_collect, target)
                end
                
            end
        end,
        OnDetached = function(inst, target)
            if target then
                if not inst.tbat_double_collect then
                    inst.tbat_double_collect = onpick
                end
                inst:RemoveEventCallback("picksomething", inst.tbat_double_collect, target)
            end
            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end

            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_double_collect then
                    inst.tbat_double_collect = onpick
                end
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_double_collect2",
        name = "双倍采集", --buff名称
        name_en = "双倍采集", --buff名称（英语）
        time = 480, --持续时间（s）
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_double_collect then
                    inst.tbat_double_collect = onpick
                    inst:ListenForEvent("picksomething", inst.tbat_double_collect, target)
                end
            end
        end,
        OnDetached = function(inst, target)
            if target then
                if not inst.tbat_double_collect then
                    inst.tbat_double_collect = onpick
                end
                inst:RemoveEventCallback("picksomething", inst.tbat_double_collect, target)
            end
            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end

            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.tbat_double_collect then
                    inst.tbat_double_collect = onpick
                end
            end
        end,
        OnTimerDone = function(inst, data)
            --计时结束时移除效果并告知效果结束
            if data.name == "buffover" then
                local target = inst.entity:GetParent()
                --特效
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                if target then
                    if not inst.tbat_double_collect then
                        inst.tbat_double_collect = onpick
                    end
                    inst:RemoveEventCallback("picksomething", inst.tbat_double_collect, target)
                end
                inst:Remove()
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_food_double_recover",
        name = "食物双倍恢复", --buff名称
        name_en = "食物双倍恢复", --buff名称（英语）
        time = 999, --持续时间（s）
        tags = { "indefinite" },
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
            end
        end,
        OnDetached = function(inst, target)
            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_food_double_recover2",
        name = "食物双倍恢复", --buff名称
        name_en = "食物双倍恢复", --buff名称（英语）
        time = 480, --持续时间（s）
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
            end
        end,
        OnDetached = function(inst, target)
            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_gflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
            end
        end,
        OnTimerDone = function(inst, data)
            --计时结束时移除效果并告知效果结束
            if data.name == "buffover" then
                local target = inst.entity:GetParent()
                --特效
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                inst:Remove()
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_wishnote_buff",
        name = "愿望之笺", --buff名称
        name_en = "愿望之笺", --buff名称（英语）
        time = 180, --持续时间（s）
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                inst._fx = SpawnPrefab("tbat_lizifx_star")
                inst._fx.entity:SetParent(target.entity)
                target:AddTag("tbat_wishnote_buff")
                if not inst.onbuild then
                    inst.onbuild = onbuild
                    inst:ListenForEvent('consumeingredients', inst.onbuild, target)
                end
                
            end
        end,
        OnDetached = function(inst, target)
            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            if target then
                if not inst.onbuild then
                    inst.onbuild = onbuild
                end
                target:RemoveTag("tbat_wishnote_buff")
                inst:RemoveEventCallback('consumeingredients', inst.onbuild, target)
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_star")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if not inst.onbuild then
                    inst.onbuild = onbuild
                end
                target:AddTag("tbat_wishnote_buff")
            end
            inst.components.timer:StopTimer("buffover")
            inst.components.timer:StartTimer("buffover", 180)
        end,
        OnTimerDone = function(inst, data)
            --计时结束时移除效果并告知效果结束
            if data.name == "buffover" then
                --特效
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                local target = inst.entity:GetParent()
                if target then
                    target:RemoveTag("tbat_wishnote_buff")
                    if not inst.onbuild then
                        inst.onbuild = onbuild
                    end
                    inst:RemoveEventCallback('consumeingredients', inst.onbuild, target)
                end
                inst:Remove()
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_knowledge_buff",
        name = "知识之纱", --buff名称
        name_en = "知识之纱", --buff名称（英语）
        time = 480, --持续时间（s）
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                inst._fx = SpawnPrefab("tbat_lizifx_bflower")
                inst._fx.entity:SetParent(target.entity)
                if not target.components.reader then
                    target:AddComponent("reader")
                    target.components.reader:SetOnReadFn(OnReadFn)
                    inst.targethasreadercomponent = false
                else
                    inst.targethasreadercomponent = true
                end
                if not target:HasTag("reader") then
                    target:AddTag("reader")
                    inst.targethasreadertag = false
                else
                    inst.targethasreadertag = true
                end
                if not target:HasTag("bookbuilder") then
                    target:AddTag("bookbuilder")
                    inst.targethasbookbuildertag = false
                else
                    inst.targethasbookbuildertag = true
                end
                if target:HasTag("aspiring_bookworm") then
                    target.components.reader:SetAspiringBookworm(false)
                    inst.targethasaspiringbookwormtag = true
                else
                    inst.targethasaspiringbookwormtag = false
                end
            end
        end,
        OnDetached = function(inst, target)
            if target then
                --特效
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                if not inst.targethasreadercomponent then
                    if target.components.reader then
                        target:RemoveComponent("reader")
                    end
                    
                end
                if not inst.targethasreadertag then
                    if target:HasTag("reader") then
                        target:RemoveTag("reader")
                    end
                    
                end
                if not inst.targethasbookbuildertag then
                    if target:HasTag("bookbuilder") then
                        target:RemoveTag("bookbuilder")
                    end
                end
                if inst.targethasaspiringbookwormtag then
                    target.components.reader:SetAspiringBookworm(true)
                    target:AddTag("aspiring_bookworm")
                end
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_bflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
            end
            inst.components.timer:StopTimer("buffover")
            inst.components.timer:StartTimer("buffover", 480)
        end,
        OnTimerDone = function(inst, data)
            --计时结束时移除效果并告知效果结束
            if data.name == "buffover" then
                local target = inst.entity:GetParent()
                --特效
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                if target then
                    if not inst.targethasreadercomponent then
                        if target.components.reader then
                            target:RemoveComponent("reader")
                        end
                    end
                    if not inst.targethasreadertag then
                        if target:HasTag("reader") then
                            target:RemoveTag("reader")
                        end
                    end
                    if not inst.targethasbookbuildertag then
                        if target:HasTag("bookbuilder") then
                            target:RemoveTag("bookbuilder")
                        end
                    end
                    if inst.targethasaspiringbookwormtag then
                        target.components.reader:SetAspiringBookworm(true)
                        target:AddTag("aspiring_bookworm")
                    end
                end
                inst:Remove()
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },

    {
        prefab = "tbat_courage_buff",
        name = "勇气之誓", --buff名称
        name_en = "勇气之誓", --buff名称（英语）
        time = 480, --持续时间（s）
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_rose")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if target then
                    if target.components.combat then -- 双倍攻
                        target.components.combat.externaldamagemultipliers:SetModifier("tbat_courage_buff", 2)
                    end
                    if not inst.tbat_courage_buff then
                        inst.tbat_courage_buff = function(src, pushdata)
                            if not pushdata then
                                return
                            end
                            local target2 = pushdata.target
                            if not (target2 and target2.brainfn) then
                                return
                            end
                            local dmg = pushdata.damage or 0
                            local spdmg = pushdata.spdamage or {}
                            for k, v in pairs(spdmg) do
                                dmg = dmg + v
                            end
                            if src.components.health then
                                src.components.health:DoDelta(dmg * 0.5 / 100)
                            end
                        end
                        inst:ListenForEvent("onhitother", inst.tbat_courage_buff, target)
                    end
                    
                end
            end
        end,
        OnDetached = function(inst, target)
            --特效
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            if target then
                if target.components.combat then
                    target.components.combat.externaldamagemultipliers:RemoveModifier("tbat_courage_buff")
                end
                if not inst.tbat_courage_buff then
                    inst.tbat_courage_buff = function(src, pushdata)
                        if not pushdata then
                            return
                        end
                        local target2 = pushdata.target
                        if not (target2 and target2.brainfn) then
                            return
                        end
                        local dmg = pushdata.damage or 0
                        local spdmg = pushdata.spdamage or {}
                        for k, v in pairs(spdmg) do
                            dmg = dmg + v
                        end
                        if src.components.health then
                            src.components.health:DoDelta(dmg * 0.5 / 100)
                        end
                    end
                end
                inst:RemoveEventCallback("onhitother", inst.tbat_courage_buff, target)
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_rose")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if target then
                    if target.components.combat then
                        target.components.combat.externaldamagemultipliers:SetModifier("tbat_courage_buff", 2)
                    end
                    if not inst.tbat_courage_buff then
                        inst.tbat_courage_buff = function(src, pushdata)
                            if not pushdata then
                                return
                            end
                            local target2 = pushdata.target
                            if not (target2 and target2.brainfn) then
                                return
                            end
                            local dmg = pushdata.damage or 0
                            local spdmg = pushdata.spdamage or {}
                            for k, v in pairs(spdmg) do
                                dmg = dmg + v
                            end
                            if src.components.health then
                                src.components.health:DoDelta(dmg * 0.5 / 100)
                            end
                        end
                    end
                end
            end
            inst.components.timer:StopTimer("buffover")
            inst.components.timer:StartTimer("buffover", 480)
        end,
        OnTimerDone = function(inst, data)
            --计时结束时移除效果并告知效果结束
            if data.name == "buffover" then
                local target = inst.entity:GetParent()
                --特效
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                if target then
                    if target.components.combat then
                        target.components.combat.externaldamagemultipliers:RemoveModifier("tbat_courage_buff")
                    end

                    if not inst.tbat_courage_buff then
                        inst.tbat_courage_buff = function(src, pushdata)
                            if not pushdata then
                                return
                            end
                            local target2 = pushdata.target
                            if not (target2 and target2.brainfn) then
                                return
                            end
                            local dmg = pushdata.damage or 0
                            local spdmg = pushdata.spdamage or {}
                            for k, v in pairs(spdmg) do
                                dmg = dmg + v
                            end
                            if src.components.health then
                                src.components.health:DoDelta(dmg * 0.5 / 100)
                            end
                        end
                    end
                    inst:RemoveEventCallback("onhitother", inst.tbat_courage_buff, target)
                end
                inst:Remove()
            end
        end,
        OnSave = function(inst, data)

        end,
        OnLoad = function(inst, data)

        end,
    },
    {
        prefab = "tbat_cure_buff",
        name = "桃花之约",
        name_en = "桃花之约",
        time = 60,
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                --特效
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_rflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                inst.tbat_heal_num = target:HasTag("player") and 1 or 2
                inst.entity:SetParent(target.entity)
                if inst.tbat_cure_task then
                    inst.tbat_cure_task:Cancel()
                end
                inst.tbat_cure_task = inst:DoPeriodicTask(1, function(self)
                    if target and target:IsValid() and target.components.health and not target.components.health:IsDead() then
                        target.components.health:DoDelta(self.tbat_heal_num)
                    end
                end)
            end
        end,
        OnDetached = function(inst, target)
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            if inst.tbat_cure_task then
                inst.tbat_cure_task:Cancel()
                inst.tbat_cure_task = nil
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_rflower")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                inst.tbat_heal_num = target:HasTag("player") and 1 or 2
                inst.entity:SetParent(target.entity)
                if inst.tbat_cure_task then
                    inst.tbat_cure_task:Cancel()
                end
                inst.tbat_cure_task = inst:DoPeriodicTask(1, function(self)
                    if target and target:IsValid() and target.components.health and not target.components.health:IsDead() then
                        target.components.health:DoDelta(self.tbat_heal_num)
                    end
                end)
            end
            inst.components.timer:StopTimer("buffover")
            inst.components.timer:StartTimer("buffover", 60)
        end,
        OnTimerDone = function(inst, data)
            if data.name == "buffover" then
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                if inst.tbat_cure_task then
                    inst.tbat_cure_task:Cancel()
                    inst.tbat_cure_task = nil
                end
                inst:Remove()
            end
        end,
        OnSave = function(inst, data)
        end,
        OnLoad = function(inst, data)
        end,
    },
    {
        prefab = "tbat_fail_buff",
        name = "失败药剂",
        name_en = "失败药剂",
        time = 60,
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                inst.entity:SetParent(target.entity)
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_ghost")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if inst.tbat_poop_task then
                    inst.tbat_poop_task:Cancel()
                end
                inst.tbat_poop_task = inst:DoPeriodicTask(3, function(self)
                    if target.components.health then
                        target.components.health:DoDelta(-1)
                    end
                    local x, y, z = target.Transform:GetWorldPosition()
                    local poop = SpawnPrefab("poop")
                    poop.Transform:SetPosition(x, 0.3, z)
                    launchitem(poop)
                end)
            end
        end,
        OnDetached = function(inst, target)
            if inst._fx then
                inst._fx:Remove()
                inst._fx = nil
            end
            if inst.tbat_poop_task then
                inst.tbat_poop_task:Cancel()
                inst.tbat_poop_task = nil
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_lizifx_ghost")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                inst.entity:SetParent(target.entity)
                if inst.tbat_poop_task then
                    inst.tbat_poop_task:Cancel()
                end
                inst.tbat_poop_task = inst:DoPeriodicTask(3, function(self)
                    if target.components.health then
                        target.components.health:DoDelta(-1)
                    end
                    local x, y, z = target.Transform:GetWorldPosition()
                    local poop = SpawnPrefab("poop")
                    poop.Transform:SetPosition(x, 0.3, z)
                    launchitem(poop)
                end)
            end
            inst.components.timer:StopTimer("buffover")
            inst.components.timer:StartTimer("buffover", 60)
        end,
        OnTimerDone = function(inst, data)
            if data.name == "buffover" then
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                if inst.tbat_poop_task then
                    inst.tbat_poop_task:Cancel()
                    inst.tbat_poop_task = nil
                end
                inst:Remove()
            end
        end,
        OnSave = function(inst, data)
        end,
        OnLoad = function(inst, data)
        end,
    },
    {
        prefab = "tbat_item_crystal_bubble_debuff",
        name = "水晶气泡",
        name_en = "水晶气泡",
        time = 240,
        OnAttached = function(inst, target, followsymbol, followoffset, data, buffer)
            if target and not target:HasTag("playerghost") then
                inst.entity:SetParent(target.entity) --将buff实体绑定到目标身上
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_crystal_bubble_fx")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                if target.components.moistureimmunity == nil then
                    target:AddComponent("moistureimmunity")
                end
                target.components.moistureimmunity:AddSource(inst)
                inst.delay_count = 0
                inst.tbat_blocksinkfx_task = inst:DoPeriodicTask(0.6, function() --设置定时任务
                    local is_moving = target.sg:HasStateTag("moving")           -- 在移动
                    local is_running = target.sg:HasStateTag("running")         -- 在跑步
                    -- 如果玩家在水上移动
                    if target.components.drownable ~= nil and
                        target.components.drownable:IsOverWater() then
                        if is_running or is_moving then
                            SpawnPrefab("weregoose_splash_less" ..
                                tostring(math.random(2))).entity:SetParent(target.entity)
                        end
                    end
                end)
                inst.tbat_blocksink_moving_task = inst:DoPeriodicTask(3.5, function()
                    RemovePhysicsColliders(target)
                    if target.components.drownable then
                        target.components.drownable.enabled = false
                    end
                end)
                --修改目标的碰撞属性
                RemovePhysicsColliders(target)
            end
        end,
        OnDetached = function(inst, target)  --buff解除
            if target then
                if inst._fx then
                    inst._fx:Remove()
                    inst._fx = nil
                end
                if target.components.moistureimmunity then
                    target:RemoveComponent("moistureimmunity")
                end
                
                if not (target:HasTag("playerghost") or (target.components.inventory and target.components.inventory:EquipHasTag("mcw_blockdrown"))) then
                    --恢复目标的碰撞属性
                    if target.components.drownable and
                        not (target.components.mk_flyer and target.components.mk_flyer._isflying and target.components.mk_flyer._isflying:value()) then -- 兼容神话云
                        target.components.drownable.enabled = true
                    end
                    ChangeToCharacterPhysics(target)
                end
                if inst.tbat_blocksinkfx_task then
                    inst.tbat_blocksinkfx_task:Cancel() --取消之前设置的定时任务
                    inst.tbat_blocksinkfx_task = nil
                end
                if inst.tbat_blocksink_moving_task then
                    inst.tbat_blocksink_moving_task:Cancel() --取消之前设置的定时任务
                    inst.tbat_blocksink_moving_task = nil
                end
            end
            inst:Remove()
        end,
        OnExtended = function(inst, target, followsymbol, followoffset, data, buffer)
            if target then
                if not inst._fx then
                    inst._fx = SpawnPrefab("tbat_crystal_bubble_fx")
                    inst._fx.entity:SetParent(target.entity)
                else
                    inst._fx.entity:SetParent(target.entity)
                end
                RemovePhysicsColliders(target)
                if target.components.drownable then
                    target.components.drownable.enabled = false
                end
                inst.components.timer:StopTimer("buffover")
                inst.components.timer:StartTimer("buffover", 240)
            end
        end,
        OnTimerDone = function(inst, data)
            if data.name == "buffover" then
                local target = inst.entity:GetParent()
                if target then
                    if inst._fx then
                        inst._fx:Remove()
                        inst._fx = nil
                    end
                    if target.components.moistureimmunity then
                        target:RemoveComponent("moistureimmunity")
                    end
                    if target.components.drownable and
                        not (target.components.mk_flyer and target.components.mk_flyer._isflying and target.components.mk_flyer._isflying:value()) then -- 兼容神话云
                        target.components.drownable.enabled = true
                    end
                    if not (target:HasTag("playerghost") or (target.components.inventory and target.components.inventory:EquipHasTag("mcw_blockdrown"))) then
                        ChangeToCharacterPhysics(target)
                    end
                    if inst.tbat_blocksinkfx_task then
                        inst.tbat_blocksinkfx_task:Cancel()
                        inst.tbat_blocksinkfx_task = nil
                    end
                    if inst.tbat_blocksink_moving_task then
                        inst.tbat_blocksink_moving_task:Cancel() --取消之前设置的定时任务
                        inst.tbat_blocksink_moving_task = nil
                    end
                end
                inst:Remove()
            end
        end
    },
}

local function MakeTbatBuffs(data)
    local function fn()
        local inst = CreateEntity()

        if data.tags then
            for _, v in ipairs(data.tags) do
                inst:AddTag(v)
            end
        end
        if not TheWorld.ismastersim then
            inst:DoTaskInTime(0, inst.Remove)
            return inst
        end
        -----------------------------------

        inst.entity:AddTransform()

        --[[Non-networked entity]]
        inst.entity:Hide()
        inst.persists = false

        inst:AddTag("CLASSIFIED")

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(data.OnAttached) --设置附加Buff时执行的函数
        inst.components.debuff:SetDetachedFn(data.OnDetached) --设置解除buff时执行的函数
        inst.components.debuff:SetExtendedFn(data.OnExtended) --设置延长buff时执行的函数
        inst.components.debuff.keepondespawn = true
        inst:AddComponent("timer")
        if inst:HasTag("indefinite") then
            --只有有时间组件才能显示，不用buffover这个名字就能显示无限时间（勋章）
            --不设立监听事件即时到时间也无事发生
            inst.components.timer:StartTimer("---", data.time)
        else
            inst.components.timer:StartTimer("buffover", data.time)
            inst:ListenForEvent("timerdone", data.OnTimerDone)
        end
        inst.OnSave = data.OnSave
        inst.OnPreLoad = data.OnLoad
        return inst
    end

    return Prefab(data.prefab, fn)
end


local tbat_debuffs = {}
for _, v in ipairs(debuffs_def) do
    if TBAT.LANGUAGE == "ch" then
        STRINGS.NAMES[string.upper(v.prefab)] = v.name
    else
        STRINGS.NAMES[string.upper(v.prefab)] = v.name_en
    end
    table.insert(tbat_debuffs, MakeTbatBuffs(v))
end

return unpack(tbat_debuffs)

--   温蒂技能树优化   --

-- 技能树文本改动
local SkillTreeDefs = require("prefabs/skilltree_defs")
if SkillTreeDefs.SKILLTREE_DEFS["wendy"] ~= nil then
    SkillTreeDefs.SKILLTREE_DEFS["wendy"].wendy_lunar_3.desc = 
        TUNING.isCh2hm and "温蒂可以在非新月时使用月晷，为阿比盖尔充满月能，变身为虚影。\n在非满月期间，月晷可以让阿比盖尔恢复虚影形态。\n" or
        "Wendy can use the Moondial during non-new moons to charge Abigail's lunar energy and transform her into a ghost. \nDuring non-full moons, the Moondial can restore Abigail to ghost form."
    SkillTreeDefs.SKILLTREE_DEFS["wendy"].wendy_sisturn_1.desc = 
        TUNING.isCh2hm and "寒冷的死亡气息能让花瓣在姐妹骨灰罐中永久保存。" or 
        "The chilling aura of death preserves the petals placed in the sisturn longer. \nThe petals becomes eternally fresh"
    SkillTreeDefs.SKILLTREE_DEFS["wendy"].wendy_sisturn_3.desc = STRINGS.SKILLTREE.WENDY.WENDY_GRAVESTONE_1_DESC .. 
        (TUNING.isCh2hm and "\n经月晷转化后，虚影形态的阿比盖尔在冲刺时获得高额减伤。" or
        "\nAfter transformed from the Moondial, Abigail gains high damage reduction when sprinting.")
    SkillTreeDefs.SKILLTREE_DEFS["wendy"].wendy_gravestone_1.desc = STRINGS.SKILLTREE.WENDY.WENDY_GRAVESTONE_1_DESC ..
        (TUNING.isCh2hm and "\n装饰完的坟墓会生成一个小惊吓。" or
        "\nAfter decorating, the grave will spawn a small ghost.")
    SkillTreeDefs.SKILLTREE_DEFS["wendy"].wendy_shadow_3.desc = STRINGS.SKILLTREE.WENDY.WENDY_SHADOW_3_DESC ..
        (TUNING.isCh2hm and "\n使阿比盖尔获得暗影分身。（虚影形态下无效）" or
        "\nAllows Abigail to gain a shadow clone. (Not effective in ghost form)")
end

-- 月晷无视月相变化转化阿比
local function domutate2hm(inst,doer)
    local ghostlybond = doer.components.ghostlybond
    if not ghostlybond or not ghostlybond.ghost or not ghostlybond.summoned then
        return false, "NOGHOST"
    elseif not TheWorld.state.isnight then
        return false, "NOTNIGHT"
    elseif ghostlybond.ghost:HasTag("gestalt") then
        if not TheWorld.state.isfullmoon then
            ghostlybond.ghost:ChangeToGestalt(false)
        else
            return false, "FULLMOON"
        end
    else
        if not TheWorld.state.isnewmoon then
            ghostlybond.ghost:ChangeToGestalt(true)
        else
            return false, "NEWMOON"
        end
    end
    return true
end

AddPrefabPostInit("moondial", function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.ghostgestalter.domutatefn = domutate2hm
end)      

-- 虚影形态阿比不受谋杀暗影魔法影响
AddPrefabPostInit("abigail", function(inst)
    if not TheWorld.ismastersim then return end
    old_DoShadowBurstBuff = inst.DoShadowBurstBuff 
    inst.DoShadowBurstBuff = function(inst, ...)
        if inst:HasTag("gestalt") then
            return
        end
        if old_DoShadowBurstBuff then 
            old_DoShadowBurstBuff(inst, ...) 
        end
    end
end) 

-- =======================================================================================================
-- 坟墓装饰完成后生成小惊吓，任务完成时在坟墓位置生成哀悼荣耀
AddPrefabPostInit("smallghost", function(inst)
    if not TheWorld.ismastersim then return end

    local old_pickup_toy = inst.PickupToy
    inst.PickupToy = function(inst, toy)

        if old_pickup_toy then old_pickup_toy(inst, toy) end
        
        -- 检查是否是装饰坟墓生成的小惊吓且任务已完成
        if inst._decorated_grave_ghost and (not inst._toys or not next(inst._toys)) then
            local leader = inst.components.follower and inst.components.follower:GetLeader()
            local leader_gets_extra_flowers = (leader and leader.isplayer and
                leader.components.skilltreeupdater and
                leader.components.skilltreeupdater:IsActivated("wendy_smallghost_3"))
            
            -- 坟墓位置生成3个哀悼荣耀
            local grave_pos = inst._grave_position
            if grave_pos then
                inst:DoTaskInTime(0.1, function()
                    for i = 1, 3 do
                        local angle = math.random() * PI2
                        local ghostflower = SpawnPrefab("ghostflower")
                        if ghostflower then
                            ghostflower.Transform:SetPosition(
                                grave_pos.x + math.cos(angle) * 1.5,
                                grave_pos.y,
                                grave_pos.z - math.sin(angle) * 1.5
                            )
                            ghostflower:DelayedGrow()
                        end
                    end
                    
                    -- 如果有三级小惊吓技能，额外生成3个
                    if leader_gets_extra_flowers then
                        for i = 1, 3 do
                            local angle = math.random() * PI2
                            local ghostflower = SpawnPrefab("ghostflower")
                            if ghostflower then
                                ghostflower.Transform:SetPosition(
                                    grave_pos.x + math.cos(angle) * 1.5,
                                    grave_pos.y,
                                    grave_pos.z - math.sin(angle) * 1.5
                                )
                                ghostflower:DelayedGrow()
                            end
                        end
                    end
                end)
            end
        end
    end
    
    -- 保存是否为装饰坟墓生成的小惊吓和需要生成荣耀的坟墓位置
    local old_OnSave = inst.OnSave
    local old_OnLoad = inst.OnLoad
    
    inst.OnSave = function(inst, data)
        if old_OnSave then
            old_OnSave(inst, data)
        end
        
        if inst._decorated_grave_ghost then
            data._decorated_grave_ghost = true
            if inst._grave_position then
                data._grave_position = {
                    x = inst._grave_position.x,
                    y = inst._grave_position.y,
                    z = inst._grave_position.z
                }
            end
        end
    end
    
    inst.OnLoad = function(inst, data, newents)
        if old_OnLoad then
            old_OnLoad(inst, data, newents)
        end
        
        if data and data._decorated_grave_ghost then
            inst._decorated_grave_ghost = true
            if data._grave_position then
                inst._grave_position = Vector3(
                    data._grave_position.x,
                    data._grave_position.y,
                    data._grave_position.z
                )
            end
        end
    end
end)

-- 修改坟墓，在装饰完成时生成特殊的小惊吓
AddPrefabPostInit("gravestone", function(inst)
    if not TheWorld.ismastersim then return end
    
    local old_OnDecorated = inst.components.upgradeable.onstageadvancefn
    inst.components.upgradeable.onstageadvancefn = function(grave)
        if old_OnDecorated then old_OnDecorated(grave) end
        
        -- 检查是否有玩家具有坟墓装饰技能
        local has_gravestone_skill = false
        for _, player in ipairs(AllPlayers) do
            if player:HasTag("ghostlyfriend") and 
                player.components.skilltreeupdater and
                player.components.skilltreeupdater:IsActivated("wendy_gravestone_1") then
                has_gravestone_skill = true
                break
            end
        end
        
        if has_gravestone_skill then
            -- 生成装饰坟墓的专属小惊吓
            local ix, iy, iz = grave.Transform:GetWorldPosition()
            local ghost = SpawnPrefab("smallghost")
            
            if ghost then
                ghost.Transform:SetPosition(ix + 0.3, iy, iz + 0.3)
                
                ghost:LinkToHome(grave)
                
                -- 标记这是装饰坟墓生成的小惊吓
                ghost._decorated_grave_ghost = true
                ghost._grave_position = Vector3(ix, iy, iz)
                
                -- 建立坟墓和小惊吓的双向关联
                grave._decorated_ghost = ghost
                
                -- 当坟墓被移除时，清理小惊吓
                grave:ListenForEvent("onremove", function()
                    if grave._decorated_ghost and grave._decorated_ghost:IsValid() then
                        grave._decorated_ghost:Remove()
                    end
                end)
            end
        end
    end
    
    -- 保存和加载坟墓的装饰小惊吓关联
    local old_OnSave = inst.OnSave
    local old_OnLoadPostPass = inst.OnLoadPostPass
    
    inst.OnSave = function(grave, data)
        if old_OnSave then
            old_OnSave(grave, data)
        end
        
        if grave._decorated_ghost and grave._decorated_ghost:IsValid() then
            data._decorated_ghost_guid = grave._decorated_ghost.GUID
        end
    end
    
    inst.OnLoadPostPass = function(grave, newents, savedata)
        if old_OnLoadPostPass then
            old_OnLoadPostPass(grave, newents, savedata)
        end
        
        if savedata and savedata._decorated_ghost_guid and newents and newents[savedata._decorated_ghost_guid] then
            grave._decorated_ghost = newents[savedata._decorated_ghost_guid].entity
            
            if grave._decorated_ghost and grave._decorated_ghost:IsValid() then
                -- 重新建立事件监听
                grave:ListenForEvent("onremove", function()
                    if grave._decorated_ghost and grave._decorated_ghost:IsValid() then
                        grave._decorated_ghost:Remove()
                    end
                end)
            end
        end
    end
end)

-- 阿比虚影形态攻击增强
TUNING.ABIGAIL_GESTALT_ATTACKAT_DAMAGE_MULT_RATE = 5/6
TUNING.WENDYSKILL_GESTALT_ATTACKAT_COMMAND_COOLDOWN = 6
-- 月阿比技能冲刺命中减冷却

-- 光之怒增强
-- 取消攻击后硬直
-- 概率释放三连击

-- 月树花庇护的阿比在虚影形态冲刺时获得减伤
local function ShouldApplyDamageReduction(inst)
    local blossoms = TheWorld.components.sisturnregistry and 
                    TheWorld.components.sisturnregistry:IsBlossom() or false                        
    local skilled = inst.components.follower and 
                    inst.components.follower.leader and 
                    inst.components.follower.leader.components.skilltreeupdater and 
                    inst.components.follower.leader.components.skilltreeupdater:IsActivated("wendy_sisturn_3") or false                       
    local inworld = not inst:HasTag("INLIMBO") and (inst.sg and not inst.sg:HasStateTag("dissipate")) or false   
    return blossoms and skilled and inworld
end            
local function PatchAbigailSG()
    local SG = require("stategraphs/SGabigail")
    local gestalt_loop_attack = SG.states.gestalt_loop_attack
    local old_loop_attack_onenter = gestalt_loop_attack.onenter
    local old_loop_attack_onexit = gestalt_loop_attack.onexit        
    gestalt_loop_attack.onenter = function(inst, ...)
        if old_loop_attack_onenter then 
            old_loop_attack_onenter(inst, ...)
        end
        if ShouldApplyDamageReduction(inst) then inst.components.health:SetAbsorptionAmount(0.9) end
    end
    gestalt_loop_attack.onexit = function(inst, ...)
        inst.components.health:SetAbsorptionAmount(0)
        if old_loop_attack_onexit then 
            old_loop_attack_onexit(inst, ...) 
        end
    end
    -- 应用给技能冲刺
    local gestalt_loop_homing_attack = SG.states.gestalt_loop_homing_attack
    local old_homing_onenter = gestalt_loop_homing_attack.onenter
    local old_homing_onexit = gestalt_loop_homing_attack.onexit
    gestalt_loop_homing_attack.onenter = function(inst, ...)
        if old_homing_onenter then
            old_homing_onenter(inst, ...)
        end
        if ShouldApplyDamageReduction(inst) then inst.components.health:SetAbsorptionAmount(0.9) end
    end
    gestalt_loop_homing_attack.onexit = function(inst, ...)
        inst.components.health:SetAbsorptionAmount(0)
        if old_homing_onexit then
            old_homing_onexit(inst, ...)
        end
    end
end
AddPrefabPostInit("abigail", function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, PatchAbigailSG)
end)

-- 骨灰罐永鲜
TUNING.WENDY_SISTURN_PETAL_PRESRVE = 0

-- 幽魂花冠取消新鲜度设置，哀悼荣耀补充耐久
AddPrefabPostInit("ghostflowerhat", function (inst)
    if not TheWorld.ismastersim then return end
    -- 移除幽影花冠的新鲜度
    if inst.components.perishable ~= nil then
        inst:RemoveComponent("perishable")
    end
    -- 添加20%防水
    if inst.components.waterproofer == nil then
        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
    end
    --添加新的耐久组件
    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(TUNING.PERISH_MED)
    inst.components.fueled:SetDepletedFn(inst.Remove)
    inst.components.fueled.no_sewing = true
    -- --添加新的可修补组件
    -- inst:AddComponent("repairable2hm")
    -- inst.repairmaterials2hm = {ghostflower = TUNING.PERISH_MED * 0.15}
end)

-- 幽魂花冠储存buff
local function UpdateGhostFlowerBuffTime(inst) -- 显示花冠剩余buff时间的函数
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner:HasTag("player") then
        if inst.components.equippable:IsEquipped() then
            -- 检查普通和超级药水buff
            local buff_types = {"elixir_buff", "super_elixir_buff"}
            for _, buff_type in ipairs(buff_types) do
                local debuff = owner:GetDebuff(buff_type)
                if debuff and debuff.components.timer then
                    local timeleft = debuff.components.timer:GetTimeLeft("decay")
                    if timeleft then
                        -- 格式化显示时间
                        inst.components.hoverer2hm.hoverStr = string.format(
                            TUNING.util2hm.GetLanguage("药水效果剩余: %s", "Elixir Time Left: %s"),
                            TUNING.util2hm.GetTime(math.floor(timeleft))
                        )
                        return
                    end
                end
            end
        
        -- 检查花冠存储的buff（当花冠被摘下时）
        elseif inst.stored_buff and inst.stored_buff_timeleft then
            inst.components.hoverer2hm.hoverStr = string.format(
                TUNING.util2hm.GetLanguage("储存效果剩余: %s", "Stored Time Left: %s"),
                TUNING.util2hm.GetTime(math.floor(inst.stored_buff_timeleft))
            )
            return
        end
    end
    
    -- 没有buff时清空显示
    inst.components.hoverer2hm.hoverStr = ""
end

-- 物品掉落时清空显示
local function GhostFlowerOnDropped(inst)
    inst.components.hoverer2hm.hoverStr = ""
    if inst.updateBuffTimeTask then
        inst.updateBuffTimeTask:Cancel()
        inst.updateBuffTimeTask = nil
    end
end

-- 物品放入背包时开始更新显示
local function GhostFlowerOnPutInInventory(inst)
    GhostFlowerOnDropped(inst)
    inst.updateBuffTimeTask = inst:DoPeriodicTask(1, UpdateGhostFlowerBuffTime)
    UpdateGhostFlowerBuffTime(inst)
end


AddPrefabPostInit("ghostflowerhat", function (inst)
    if not TheWorld.ismastersim then return end
    -- 初始化存储变量
    inst.stored_buff = nil
    inst.stored_buff_data = nil
    inst.stored_buff_timeleft = nil
    local ghostflower_onequip2hm = inst.components.equippable.onequipfn
    local ghostflower_onunequip2hm = inst.components.equippable.onunequipfn
    inst.is_in_cooldown = false  -- CD状态标记

    local function ghostflower_onequip(inst, owner)
        -- 先执行原有的装备逻辑
        ghostflower_onequip2hm(inst, owner)
        if not owner:HasTag("player") then return end
    
        -- 检查是否有存储的buff，并重新应用
        if inst.stored_buff and inst.stored_buff_data then
            -- 重新创建buff
            -- local buff_types = {"elixir_buff", "super_elixir_buff"}
            -- for _, buff_type in ipairs(buff_types) do
                local buff = owner:AddDebuff(inst.stored_buff, inst.stored_buff_data.prefab, nil, nil, function()
                    local cur_buff = owner:GetDebuff(inst.stored_buff)
                    if cur_buff ~= nil and cur_buff.prefab ~= inst.stored_buff_data.prefab then
                        owner:RemoveDebuff(inst.stored_buff)
                    end
                end)
                local buff = owner:GetDebuff(inst.stored_buff)
                if buff then
                    -- -- 恢复buff效果
                    -- buff:buff_skill_modifier_fn(inst.stored_buff_data.giver, owner)
                    
                    -- 如果有剩余时间，设置计时器
                    if inst.stored_buff_timeleft and buff.components.timer then
                        buff.components.timer:StopTimer("decay")
                        buff.components.timer:StartTimer("decay", inst.stored_buff_timeleft)
                    end
                    -- 重置充能
                    if owner.components.health and inst.components.rechargeable and inst.components.rechargeable:GetCharge() > 0 then 
                        inst.components.rechargeable:Discharge(3)
                        owner.components.health.externalreductionmodifiers:RemoveModifier(owner, "forcefield")            
                    end
                    
                end
            -- end

            -- 清空存储
            inst.stored_buff = nil
            inst.stored_buff_data = nil
            inst.stored_buff_timeleft = nil
        end
    end
    
    local function ghostflower_onunequip(inst, owner)
        -- 检查当前是否有buff
        local debuff = owner:GetDebuff("elixir_buff")
        if debuff then  
            -- 存储buff信息
            inst.stored_buff = "elixir_buff"
            inst.stored_buff_data = {
                prefab = debuff.prefab,
                giver = debuff.giver,
                potion_tunings = debuff.potion_tunings  -- 保存药水配置
            }
            
            -- 存储剩余时间
            if debuff.components.timer then
                inst.stored_buff_timeleft = debuff.components.timer:GetTimeLeft("decay")
            end  
            if owner:HasDebuff("ghostlyelixir_attack_buff") then 
                ghostflower_onunequip2hm(inst, owner)
                owner:AddDebuff("ghostvision_buff","ghostvision_buff")
                return
            end
        end
        
        -- 执行原有的卸下逻辑
        ghostflower_onunequip2hm(inst, owner)

    end
    inst.components.equippable:SetOnEquip(ghostflower_onequip)
    inst.components.equippable:SetOnUnequip(ghostflower_onunequip)
    -- 添加悬浮文本组件
    inst:AddComponent("hoverer2hm")
    
    -- 监听物品事件
    inst:ListenForEvent("onputininventory", GhostFlowerOnPutInInventory)
    inst:ListenForEvent("ondropped", GhostFlowerOnDropped)
    
    -- 监听buff变化事件
    inst:ListenForEvent("timerdone", function(owner, data)
        if data.name == "decay" then
            UpdateGhostFlowerBuffTime(inst)
        end
    end)
    
    -- 初始更新显示
    if inst.components.inventoryitem:IsHeld() then
        GhostFlowerOnPutInInventory(inst)
    end

    -- 暂时不进行数据保存，储存的buff在重新加载时会丢失

end)



---- 吴迪技能树优化 ----

----- 技能树文本改动
local SkillTreeDefs = require("prefabs/skilltree_defs")

if SkillTreeDefs.SKILLTREE_DEFS["woodie"] ~= nil then
    if GetModConfigData("Woodie Hunger Wereness") then 
        SkillTreeDefs.SKILLTREE_DEFS["woodie"].woodie_curse_weremeter_1.desc = 
            TUNING.isCh2hm and "动物形态的饥饿速率为2.25倍。" or
            "The starvation rate in animal form is 1.5 times faster."
        SkillTreeDefs.SKILLTREE_DEFS["woodie"].woodie_curse_weremeter_2.desc = 
            TUNING.isCh2hm and "动物形态的饥饿速率为1.75倍。" or
            "The starvation rate in animal form is 1.25 times faster."
        SkillTreeDefs.SKILLTREE_DEFS["woodie"].woodie_curse_weremeter_3.desc =
            TUNING.isCh2hm and "动物形态的饥饿速率为1.5倍。" or
            "The starvation rate in animal form is normal."
        SkillTreeDefs.SKILLTREE_DEFS["woodie"].woodie_curse_master.desc = STRINGS.SKILLTREE.WOODIE.WOODIE_CURSE_MASTER_DESC ..
            (TUNING.isCh2hm and "\n动物形态获得理智回复。" or
            "\nGain sanity while in animal form.")
    end
    SkillTreeDefs.SKILLTREE_DEFS["woodie"].woodie_human_treeguard_1.desc = STRINGS.SKILLTREE.WOODIE.WOODIE_HUMAN_TREEGUARD_1_DESC ..
        (TUNING.isCh2hm and "\n露西斧对树精守卫额外造成双倍伤害。" or
        "\n Lucy deals extra double damage to leifs.")
    if GetModConfigData("leif") then
        SkillTreeDefs.SKILLTREE_DEFS["woodie"].woodie_human_treeguard_2.desc = STRINGS.SKILLTREE.WOODIE.WOODIE_HUMAN_TREEGUARD_2_DESC ..
            (TUNING.isCh2hm and "\n露西斧无视桦树精抵抗。" or
            "\n Lucy ignores birchnutdrake cutdown resistence")
    end
    SkillTreeDefs.SKILLTREE_DEFS["woodie"].woodie_human_lucy_2.desc = STRINGS.SKILLTREE.WOODIE.WOODIE_HUMAN_LUCY_2_DESC ..
        (TUNING.isCh2hm and "\n露西雕刻的硬木帽可以抵御落石伤害。\n使用木头修复你的硬木帽子。" or
        "\nLucy carved Hardwood Hat can protect you from earthquake.\nUse logs to repair your hardwood hat.")
    SkillTreeDefs.SKILLTREE_DEFS["woodie"].woodie_human_lucy_3.desc = STRINGS.SKILLTREE.WOODIE.WOODIE_HUMAN_LUCY_3_DESC ..
        (TUNING.isCh2hm and "\n露西雕刻的木手杖拥有无限的基础耐久。\n使用活木升级你的木手杖。" or
        "\nLucy carved Wooden Walking Stick has infinite durability.\nUse livinglogs to upgrade your Wooden Stick.")
    SkillTreeDefs.SKILLTREE_DEFS["woodie"].woodie_allegiance_shadow.desc = STRINGS.SKILLTREE.WOODIE.WOODIE_ALLEGIANCE_SHADOW_DESC ..
        (TUNING.isCh2hm and "\n变回人形后维持一段时间。" or
        "\nMaintains a short time after transfroming back.")
    SkillTreeDefs.SKILLTREE_DEFS["woodie"].woodie_allegiance_lunar.desc = STRINGS.SKILLTREE.WOODIE.WOODIE_ALLEGIANCE_LUNAR_DESC ..
        (TUNING.isCh2hm and "\n在满月时获得随机俗气雕像。" or
        "\nReceive a random wereitem on fullmoon.")
end

-- “鹿人精通”：可以按住ctrl以在无目标时释放位面重击
 
-- “暗影牧人”：变身结束后的30秒内也对影怪保持中立
AddPrefabPostInit("woodie", function(inst)
    if inst.UpdateShadowDominanceState then     
        inst.UpdateShadowDominanceState = function(self)
            local wereform = inst:HasTag("wereplayer")

            if wereform and inst:HasTag("player_shadow_aligned") then
                inst:AddTag("inherentshadowdominance")
                inst:AddTag("shadowdominance")

            elseif inst:HasTag("inherentshadowdominance") then
                inst:RemoveTag("inherentshadowdominance")

                if inst.components.inventory ~= nil then
                    for k, v in pairs(inst.components.inventory.equipslots) do
                        if v.components.shadowdominance ~= nil then
                            --A item with shadowdominance is equipped, don't remove the shadowdominance tag.
                            return
                        end
                    end
                end
                -- 延迟仇恨
                self:DoTaskInTime(30, function()
                    self:RemoveTag("shadowdominance")
                end)
            end
        end  
    end
end)

-- “月亮叛徒”：伍迪满月获得随机俗气雕像
local function OnIsFullmoon(inst, isfullmoon)
    if inst.components.skilltreeupdater and inst.components.skilltreeupdater:IsActivated("woodie_allegiance_lunar") then 
        if isfullmoon and inst.components.inventory and not inst:HasTag("wereplayer") and not inst:HasTag("playerghost") then
            local wereitem = SpawnPrefab(({"wereitem_goose", "wereitem_beaver", "wereitem_moose"})[math.random(1, 3)])
            inst.components.inventory:GiveItem(wereitem)
            inst.SoundEmitter:PlaySound(({
                wereitem_goose = "dontstarve/characters/woodie/goose/death",
                wereitem_beaver = "dontstarve/characters/woodie/beaver_chop_tree",
                wereitem_moose = "dontstarve/characters/woodie/moose/death"
            })[wereitem.prefab])
        end
    end
end

AddPrefabPostInit("woodie", function(inst)
    if not TheWorld.ismastersim then return end
    inst:WatchWorldState("isfullmoon", OnIsFullmoon)
end)

-- 硬木帽防水（海棠遗留的设定）
AddPrefabPostInit("woodcarvedhat", function(inst)
    inst:AddTag("waterproofer")
    if not TheWorld.ismastersim then return end
    if not inst.components.waterproofer then
        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
    end
end)

-- “拐杖雕刻”：使用活木升级使其一段时间内获得额外20%/15%/10%加速效果
local function UpdateStatus(inst)
    if not inst:IsValid() then return end
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
    
    if inst.components.perishable then
        local percent = inst.components.perishable:GetPercent()
        
        -- 根据新鲜度设置不同的加速效果
        if percent > 0.5 then -- 新鲜 (>50%)
            inst.components.equippable.walkspeedmult = 1.35 -- 额外20%
        elseif percent > 0.2 then -- 不新鲜 (>20%)
            inst.components.equippable.walkspeedmult = 1.30 -- 额外15%
        else -- 变质
            inst.components.equippable.walkspeedmult = 1.25 -- 额外10%
        end
        
        
    else
        inst.components.equippable.walkspeedmult = TUNING.WALKING_STICK_SPEED_MULT -- 1.15
    end
end

local function resetperishableview(inst)
    inst.resetviewtask2hm = nil
    local grandowner = inst.components.inventoryitem:GetGrandOwner()
    if not (grandowner and grandowner.Transform) then return end
    local x, y, z = grandowner.Transform:GetWorldPosition()
    if not TheWorld.Map:IsPassableAtPoint(x, y, z, true) then return end
    local owner = inst.components.inventoryitem.owner
    if owner and owner.components.inventory then
        if inst.components.equippable:IsEquipped() then
            owner.components.inventory:Unequip(EQUIPSLOTS.HANDS)
            owner:AddChild(inst)
            inst:RemoveFromScene()
            inst:DoTaskInTime(0, function() owner.components.inventory:Equip(inst) end)
        else
            local prevslot = owner.components.inventory:GetItemSlot(inst)
            owner.components.inventory:RemoveItem(inst)
            owner:AddChild(inst)
            inst:RemoveFromScene()
            inst:DoTaskInTime(0, function() owner.components.inventory:GiveItem(inst, prevslot) end)
        end
    elseif owner and owner.components.container then
        local prevslot = owner.components.container:GetItemSlot(inst)
        owner.components.container:RemoveItem(inst)
        owner:AddChild(inst)
        inst:RemoveFromScene()
        inst:DoTaskInTime(0, function() owner.components.container:GiveItem(inst, prevslot) end)
    end
end

local function customrepair(inst, repairuse, doer, repair_item)
    if not (doer.components.skilltreeupdater 
            and doer.components.skilltreeupdater:IsActivated("woodie_human_lucy_3")) or 
            (inst.components.perishable and inst.components.perishable:GetPercent() >= 1) then
        return false
    end
    if repair_item and repair_item.prefab == "livinglog" then
        if not inst.components.perishable then
            inst:AddComponent("perishable")
            inst.components.perishable.perishtime = TUNING.TOTAL_DAY_TIME * 16
            inst.components.perishable.perishremainingtime = TUNING.TOTAL_DAY_TIME * 8 -- 初始50%
            inst.components.perishable:StartPerishing()
            inst:AddTag("show_spoilage")
            inst.level2hm:set(2)
            if doer then doer.components.talker:Say((TUNING.isCh2hm and "它似乎活过来了" or "It seems to be alive")) end
        else
            inst.components.perishable:AddTime(TUNING.TOTAL_DAY_TIME * 8) -- 每个活木增加50%新鲜度
        end
        if repair_item.components.stackable then
            repair_item.components.stackable:Get():Remove()
        else
            repair_item:Remove()
        end
        inst.SoundEmitter:PlaySound("dontstarve/creatures/leif/livinglog_burn")
        -- 更新拥有者的速度
        if doer and doer.components.locomotor then
            doer.components.locomotor:EnableGroundSpeedMultiplier(false)
            doer.components.locomotor:EnableGroundSpeedMultiplier(true)
        end
        if not inst.resetviewtask2hm then inst.resetviewtask2hm = inst:DoTaskInTime(0, resetperishableview) end
        UpdateStatus(inst)
        return true
    end
    return false
end

local function checkfreshness(inst)
    if inst.components.perishable and inst.components.perishable:GetPercent() <= 0 then
        inst:RemoveTag("show_spoilage")
        inst:RemoveComponent("perishable")
        if not inst.resetviewtask2hm then inst.resetviewtask2hm = inst:DoTaskInTime(0, resetperishableview) end
        UpdateStatus(inst)
    end
end

-- 显示名称函数
local function DisplayNameFn(inst)
    return inst:HasTag("show_spoilage") and ((TUNING.isCh2hm and "活化" or "Living ") .. STRINGS.NAMES.WALKING_STICK) or nil   
end

AddPrefabPostInit("walking_stick", function(inst)
    inst:AddTag("show_spoilage")

    inst.level2hm = net_smallbyte(inst.GUID, "walking_stick.level2hm", "level2hmdirty")

    inst.repairmaterials2hm = {livinglog = 1}
    inst.repairtext2hm = "UPGRADE"

    inst.displaynamefn = DisplayNameFn

    if not TheWorld.ismastersim then
        return
    end

    -- 吴迪木手杖无限耐久
    if inst.components.fueled ~= nil then
        inst:RemoveComponent("fueled")
    end
    -- 原始装备和卸下函数中没有对fueled的判空，覆盖函数避免报错
    inst.components.equippable:SetOnEquip(function(inst, owner)
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("equipskinneditem", inst:GetSkinName())
            owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "walking_stick", inst.GUID, "swap_walking_stick")
        else
            owner.AnimState:OverrideSymbol("swap_object", "walking_stick", "swap_walking_stick")
        end
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
        UpdateStatus(inst) -- 更新状态
    end)
    inst.components.equippable:SetOnUnequip(function(inst, owner)
        local skin_build = inst:GetSkinBuild()
        if skin_build ~= nil then
            owner:PushEvent("unequipskinneditem", inst:GetSkinName())
        end
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
    end)

    -- 海棠的注能玻璃刀代码中添加了初始新鲜度
    inst:AddComponent("perishable")
    inst.components.perishable.perishtime = TUNING.TOTAL_DAY_TIME * 16 -- 16天
    inst.components.perishable.perishremainingtime = 0
    inst.components.perishable:StartPerishing()

    inst.level2hm:set(1)
    -- 添加可修复组件
    inst:AddComponent("persistent2hm")

    inst:AddComponent("repairable2hm")
    inst.components.repairable2hm.ignoremax = true
    inst.components.repairable2hm.customrepair = customrepair
    
    inst:DoTaskInTime(0, checkfreshness)
    inst:ListenForEvent("perished", checkfreshness)

    
    -- 初始化状态
    UpdateStatus(inst)
    inst._updatestatus = function() UpdateStatus(inst) end
end)  

-- 点亮“树精守卫伐木者”技能后露西斧对树精造成双倍伤害并免疫桦树精的效率抵抗；
local function DamageCalculator(inst, attacker, target)
    -- 露西伤害和普通斧头相同
    local damage = TUNING.AXE_DAMAGE
    -- 树精守卫伐木者Ⅰ
    if target and target:HasTag("leif") then
        damage = damage * 2
    end
    return damage
end
AddPrefabPostInit("lucy", function(inst)
    if not TheWorld.ismastersim then return end
    if inst.components.weapon then inst.components.weapon:SetDamage(DamageCalculator) end
end)
-- 树精守卫伐木者Ⅱ，见树精增强模块

-- 吴迪变身不掉落
AddComponentPostInit("inventory", function(self)
    self.DropEquipped = function(keepBackpack)
        for k, v in pairs(self.equipslots) do
            if v ~= nil and not (keepBackpack and v:HasTag("backpack")) then
                local item = self:Unequip(k)
                if item ~= nil then
                    self:GiveItem(item)
                end
            end
        end
    end
end)
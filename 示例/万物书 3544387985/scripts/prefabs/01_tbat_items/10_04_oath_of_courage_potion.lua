--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的药水模板

    动画注意事项：
    【注意】药水瓶的png单独在一个文件夹图层里，方便调用套入锅里。（推荐 【 pot 】 ）


]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_item_oath_of_courage_potion"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_item_oath_of_courage_potion.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable 右键使用模块
    local function workable_on_work_fn(inst,doer)
        ------------------------------------------------------------------------------------------
        --- 物品消耗
            inst.components.stackable:Get():Remove()
        ------------------------------------------------------------------------------------------
        --- 内部执行
            local debuff_prefab = this_prefab.."_debuff"
            doer:AddDebuff(debuff_prefab,debuff_prefab)
        ------------------------------------------------------------------------------------------
        return true
    end
    local function workable_test_fn(inst,doer,right_click)        
        return inst.replica.inventoryitem:IsGrandOwner(doer)
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.HEAL.USE)
        replica_com:SetSGAction("dolongaction") --- 执行长动作动画
        -- replica_com:SetSGAction("doshortaction") --- 执行瞬间动画
    end
    local function workable_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_workable")
        inst.components.tbat_com_workable:SetOnWorkFn(workable_on_work_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 落水影子
    local function shadow_init(inst)
        if inst:IsOnOcean(false) then       --- 如果在海里（不包括船）
            inst.AnimState:Hide("SHADOW")
            inst.AnimState:HideSymbol("shadow")
        else                                
            inst.AnimState:Show("SHADOW")
            inst.AnimState:ShowSymbol("shadow")
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function item_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank("tbat_item_oath_of_courage_potion")
        inst.AnimState:SetBuild("tbat_item_oath_of_courage_potion")
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetScale(0.7,0.7,0.7)
        MakeInventoryFloatable(inst, "med", 0.05, {0.85, 0.45, 0.85})
        inst.entity:SetPristine()
        ------------------------------------------------------------------------------------------
        --- 客户端
            workable_install(inst)
        ------------------------------------------------------------------------------------------
        --- 服务器端
            if not TheWorld.ismastersim then
                return inst
            end
        ------------------------------------------------------------------------------------------
        --- 图标和检查
            inst:AddComponent("inspectable")
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem:TBATInit("tbat_item_oath_of_courage_potion","images/inventoryimages/tbat_item_oath_of_courage_potion.xml")
        ------------------------------------------------------------------------------------------
        --- 叠堆
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize =  TBAT.PARAM.STACK_40()
        ------------------------------------------------------------------------------------------
        --- 作祟
            MakeHauntableLaunch(inst)
        ------------------------------------------------------------------------------------------
        --- 落水影子
            inst:ListenForEvent("on_landed",shadow_init)
            shadow_init(inst)
        ------------------------------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- debuff
    local DEBUFF_REMAIN_TIME = 480
    local function OnAttached(inst,player) -- 玩家得到 debuff 的瞬间。 穿越洞穴、重新进存档 也会执行。【注意】有可能执行两次，和饥荒的初始化相关
        -----------------------------------------------------
        --- 绑定父物体
            inst.entity:SetParent(player.entity)
            inst.Transform:SetPosition(0,0,0)
        -----------------------------------------------------
        --- 伤害翻倍
            player.components.combat.externaldamagemultipliers:SetModifier(inst,2)
        -----------------------------------------------------
        --- 吸血：造成伤害的0.5%   带脑子的才算数，避免打木桩等其他吸血
            -- 			attacker:PushEvent("onhitother", { target = self.inst, damage = damage, damageresolved = damageresolved, stimuli = stimuli, spdamage = spdamage, weapon = weapon, redirected = damageredirecttarget })
            inst:ListenForEvent("onhitother",function(_,data)
                data = data or {}
                local target = data.target
                if not (target and target.brainfn) then
                    return
                end
                local damage = data.damage or 0
                local spdamage = data.spdamage or {}
                local all_dmg = damage
                for damage_type, value in pairs(spdamage) do
                    all_dmg = all_dmg + value
                end
                local heal_num = all_dmg * 0.5/100
                if player.components.health then
                    player.components.health:DoDelta(heal_num)
                end
            end,player)
        -----------------------------------------------------
        --- 计时器
            if inst.components.tbat_data:Get("time") == nil then
                inst.components.tbat_data:Set("time",DEBUFF_REMAIN_TIME)
            end
            inst:DoPeriodicTask(1,function()
                local time = inst.components.tbat_data:Add("time",-1)
                if time <= 0 then
                    inst:Remove()
                end
            end)
        -----------------------------------------------------
        --- 创建特效
            local fx = player:SpawnChild("tbat_sfx_rose")
            fx.Transform:SetPosition(-1,2,0)
        -----------------------------------------------------
        ---
            inst:ListenForEvent("onremove",function()
                fx:Remove()
            end)
        -----------------------------------------------------
    end
    local function ExtendDebuff(inst)  --- 添加同一索引的时候执行
        inst.components.tbat_data:Set("time",DEBUFF_REMAIN_TIME)
    end
    local function debuff_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst:AddTag("CLASSIFIED")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("tbat_data")
        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff.keepondespawn = true -- 是否保持debuff 到下次登陆
        inst.components.debuff:SetDetachedFn(inst.Remove)
        inst.components.debuff:SetExtendedFn(ExtendDebuff)

        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, item_fn, assets),
    Prefab(this_prefab.."_debuff", debuff_fn, assets)

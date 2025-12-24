--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_container_mushroom_snail_cauldron"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_container_mushroom_snail_cauldron.zip"),
        Asset("ANIM", "anim/tbat_container_mushroom_snail_cauldron_ui.zip"),    -- 原始界面
        Asset("ANIM", "anim/tbat_chat_icon_mushroom_snail_cauldron.zip"),       -- 聊天图标
        Asset("IMAGE", "images/widgets/tbat_container_mushroom_snail_cauldron_slot.tex"),   -- 容器格子图标
        Asset("ATLAS", "images/widgets/tbat_container_mushroom_snail_cauldron_slot.xml"),   -- 容器格子图标
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 密语图标
    TBAT.FNS:AddChatIconData(this_prefab,{
        atlas = "images/chat_icon/empty.xml",
        image = "empty.tex",                     --- 128x128 pix
        scale = nil,                            ---- 图标自定义缩放，避免一棍子打死。默认0.25
        fx = {
            bank = "tbat_chat_icon_mushroom_snail_cauldron",
            build = "tbat_chat_icon_mushroom_snail_cauldron",
            anim = "idle",
            time = 1,
        },  
    })
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 容器
    local container_install_fn = require("prefabs/06_tbat_containers/06_02_snail_container_install")
    local container_ui_install_fn = require("prefabs/06_tbat_containers/06_03_01_snail_ui_event")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- anim controller 动画控制
    local function cook_on_start(inst,doer)
        inst.AnimState:PlayAnimation("idle_2_working",true)
    end
    local function cook_on_finish(inst,data)
        inst.AnimState:PlayAnimation("idle_2_prefull",false)
        inst.AnimState:PushAnimation("idle_2_full",true)
        local build,layer = inst.components.tbat_com_mushroom_snail_cauldron:GetOverrideSymbol()
        if build and layer then
            inst.AnimState:OverrideSymbol("td",build,layer)
        end
    end
    local function on_harvest(inst,doer)
        inst.AnimState:PlayAnimation("idle_2",true)
    end
    local function on_container_open(inst,data)
        if inst:HasTag("working") then
            if not inst.AnimState:IsCurrentAnimation("idle_2_working") then
                inst.AnimState:PlayAnimation("idle_2_working",true)
            end
        elseif inst:HasTag("can_be_harvest") then
            if not inst.AnimState:IsCurrentAnimation("idle_2_full") then
                inst.AnimState:PlayAnimation("idle_2_full",true)
            end
        elseif inst.AnimState:IsCurrentAnimation("idle_1") or inst.AnimState:IsCurrentAnimation("idle_2_to_1") then
            inst.AnimState:PlayAnimation("idle_1_to_2",false)
            inst.AnimState:PushAnimation("idle_2",true)
        end
    end
    local function on_container_close(inst,data)
        if inst:HasTag("working") then
            if not inst.AnimState:IsCurrentAnimation("idle_2_working") then
                inst.AnimState:PlayAnimation("idle_2_working",true)
            end
        elseif inst:HasTag("can_be_harvest") then
            if not inst.AnimState:IsCurrentAnimation("idle_2_full") then
                inst.AnimState:PlayAnimation("idle_2_full",true)
            end
        elseif inst.AnimState:IsCurrentAnimation("idle_2") or inst.AnimState:IsCurrentAnimation("idle_1_to_2") then
            inst.AnimState:PlayAnimation("idle_2_to_1",false)
            inst.AnimState:PushAnimation("idle_1",true)
        end
    end
    local function hit_anim(inst)
        if inst:HasOneOfTags({"working","can_be_harvest"}) then
            
        elseif inst.AnimState:IsCurrentAnimation("idle_1") then
            inst.AnimState:PlayAnimation("hit",false)
            inst.AnimState:PushAnimation("idle_2_to_1",false)
            inst.AnimState:PushAnimation("idle_1",true)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 失败/成功通告
    local function cook_finished_event(inst,data)
        local userid = data.cooker_userid
        local product = data.product
        local cook_fail = data.cook_fail        
        if cook_fail then 
            local origin_product = data.origin_product
            local origin_product_name = STRINGS.NAMES[string.upper(origin_product)]
            local str = TBAT:GetString2(this_prefab,"cook_fail")
            str = TBAT.FNS:ReplaceString(str,"{xxxx}",origin_product_name)
            TBAT.MSC:WhisperTo(userid,str)
        else
            local product_name = STRINGS.NAMES[string.upper(product)]
            local str = TBAT:GetString2(this_prefab,"cook_succeed")
            str = TBAT.FNS:ReplaceString(str,"{xxxx}",product_name)
            TBAT.MSC:WhisperTo(userid,str)
        end
    end
    local function cook_annouce_event_install(inst)
        inst:ListenForEvent("OnFinished",cook_finished_event)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- official workable
    local function onfinished(inst,worker)
        if inst:HasTag("can_be_harvest") then
                local product,num = inst.components.tbat_com_mushroom_snail_cauldron:GetProduct()
                if product then
                        num = math.ceil(num/2)  -- 拆除返还一半
                        num = math.max(num,1)   -- 最少返还1
                        for i = 1, num, 1 do
                            inst.components.lootdropper:SpawnLootPrefab(product)                    
                        end
                end
        end
    end
    local workable_cmd = {
        onhit = hit_anim,
        onfinished = onfinished,
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 右键采收
    local function workable_test_fn(inst,doer,right_click)        
        return right_click and inst:HasTag("can_be_harvest")
    end
    local function workable_on_work_fn(inst,doer)
        inst.components.tbat_com_mushroom_snail_cauldron:OnHarvest(doer)
        on_container_close(inst,{doer = doer})
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.PICK.HARVEST)
        replica_com:SetSGAction("dolongaction")
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
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeObstaclePhysics(inst, 1)
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon("tbat_container_mushroom_snail_cauldron.tex")
        inst.AnimState:SetBank("tbat_container_mushroom_snail_cauldron")
        inst.AnimState:SetBuild("tbat_container_mushroom_snail_cauldron")
        inst.AnimState:PlayAnimation("idle_1",true)
        inst:AddTag("structure")
        inst:AddTag(this_prefab)
        ------------------------------------------------------------
        --- 预制优化
            inst.entity:SetPristine()
        ------------------------------------------------------------
        --- 容器
            container_install_fn(inst)
            container_ui_install_fn(inst)
            workable_install(inst)
        ------------------------------------------------------------
        --- ismastersim
            if not TheWorld.ismastersim then
                return inst
            end
        ------------------------------------------------------------
        --- 反鲜
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(-1)
        ------------------------------------------------------------
        ---
            cook_annouce_event_install(inst)
        ------------------------------------------------------------
        --- 掉落
            inst:AddComponent("lootdropper")
        ------------------------------------------------------------
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ------------------------------------------------------------
        ---
            inst:AddComponent("tbat_com_mushroom_snail_cauldron")
            inst.components.tbat_com_mushroom_snail_cauldron:SetOnStartFn(cook_on_start)
            inst.components.tbat_com_mushroom_snail_cauldron:SetOnFinishFn(cook_on_finish)
            inst.components.tbat_com_mushroom_snail_cauldron:SetOnHarvestFn(on_harvest)
        ------------------------------------------------------------
        ---
            inst:ListenForEvent("onopen",on_container_open)
            inst:ListenForEvent("onclose",on_container_close)
        ------------------------------------------------------------
        --- 拆除
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,9,workable_cmd)
        ------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle_1",true)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer", "tbat_container_mushroom_snail_cauldron", "tbat_container_mushroom_snail_cauldron", "idle_1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    向日葵仓鼠灯

    名字：（手持大葵花那个）：
    功能：晚上发光，照亮半径三格地皮
    制作：6葵瓜子+2萤火虫制作
    检索台词：吸收阳光为你照亮黑暗！
    给与一个松鼠牙可升级
    名字：（带上草帽贴图版）：
    功能：晚上发光范围增加至半径五格地皮
    无碰撞体积，灯类型建筑，发光方式为晚上会亮起荧光（动画师已做动画，需要调整成多个发光光点）

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_sunflower_hamster"
    local level_up_item_prefab = "tbat_material_squirrel_incisors"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_sunflower_hamster.zip"),
        Asset("ANIM", "anim/tbat_building_sunflower_hamster_light.zip"),

        Asset("ANIM", "anim/tbat_building_sunflower_hamster_gumball_machine.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 皮肤API套件
    local skins_data = {
        ["tbat_hamster_gumball_machine"] = {                    --- 
            bank = "tbat_building_sunflower_hamster_gumball_machine",
            build = "tbat_building_sunflower_hamster_gumball_machine",
            atlas = "images/map_icons/tbat_building_sunflower_hamster_gumball_machine.xml",
            image = "tbat_building_sunflower_hamster_gumball_machine",  -- 不需要 .tex
            name = TBAT:GetString2(this_prefab,"skin.gumball_machine"),        --- 切名字用的
            name_color = "pink",
            server_fn = function(inst) -- 切换到这个skin调用 。服务端
                inst.MiniMapEntity:SetIcon("tbat_building_sunflower_hamster_gumball_machine.tex")
            end,
            server_switch_out_fn = function(inst) -- 切换离开这个皮肤用
                inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            end,
            unlock_announce_data = { -- 解锁提示
                bank = "tbat_building_sunflower_hamster_gumball_machine",
                build = "tbat_building_sunflower_hamster_gumball_machine",
                anim = "idle_1",
                scale = 0.25,
                offset = Vector3(0, -50, 0),
            },
            placer_fn = function(inst)
                inst.AnimState:SetBank("tbat_building_sunflower_hamster_gumball_machine")
                inst.AnimState:SetBuild("tbat_building_sunflower_hamster_gumball_machine")
                inst.AnimState:PlayAnimation("idle_1",true)
            end
        },
    }
    TBAT.SKIN:DATA_INIT(skins_data,this_prefab)
    TBAT.SKIN.SKIN_PACK:Pack("pack_warm_and_cozy_home","tbat_hamster_gumball_machine")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- anim fx
    local function anim_fx_event(inst,flag)
        local flag = inst.net_anim_fx:value()
        -------------------------------------------------
        --- 检测皮肤
            local current_skin_data = inst.replica.tbat_com_skin_data and inst.replica.tbat_com_skin_data:GetCurrentData()
            if current_skin_data then
                flag = false
            end
        -------------------------------------------------
        if flag then
            for k, v in pairs(inst._anim_light_fx) do
                v:Show()
            end
        else
            for k, v in pairs(inst._anim_light_fx) do
                v:Hide()
            end
        end
    end
    local function create_anim_fx(parent)
        parent._anim_light_fx = parent._anim_light_fx or {}
        for k, v in pairs(parent._anim_light_fx) do
            v:Remove()
        end
        parent._anim_light_fx = {}
        for i = 1, 15, 1 do
            parent.AnimState:OverrideSymbol("light"..i,"tbat_building_sunflower_hamster","empty")        
            local inst = CreateEntity()
            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.AnimState:SetBuild("tbat_building_sunflower_hamster_light")
            inst.AnimState:SetBank("tbat_building_sunflower_hamster_light")
            inst.entity:SetParent(parent.entity)
            -- inst.entity:AddFollower()
            -- inst.Follower:FollowSymbol(parent.GUID, "light"..i,0,0,0,true)
            inst.Transform:SetPosition(math.random(-15,15)/10,math.random()*4.5,math.random(-15,15)/10)
            inst.AnimState:PlayAnimation("light_"..math.random(4),true)
            inst.AnimState:SetTime(1.5*math.random())
            table.insert(parent._anim_light_fx,inst)
            inst:Hide()
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 开关灯封装
    local function LightOn(inst)
        inst.Light:Enable(true)
        inst.net_anim_fx:set(true)
        inst.AnimState:Show("LIGHT")
        inst.AnimState:ShowSymbol("light")
    end
    local function LightOff(inst)
        inst.Light:Enable(false)
        inst.net_anim_fx:set(false)
        inst.AnimState:Hide("LIGHT")
        inst.AnimState:HideSymbol("light")
    end
    local function light_init(inst)
        if TheWorld:HasTag("cave") then
            LightOn(inst)
            return
        end
        if TheWorld.state.isday then
            LightOff(inst)
        else
            LightOn(inst)
        end
    end
    local function light_init_delay(inst)
        inst:DoTaskInTime(5,light_init)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 物品接受
    local function acceptable_test_fn(inst,item,doer,right_click)        
        if not inst:HasTag("lv2") and item.prefab == level_up_item_prefab then
            return true
        end
        return false
    end
    local function acceptable_on_accept_fn(inst,item,doer)
        --------------------------------------------------
        -- 
            if item.components.stackable then
                item.components.stackable:Get():Remove()
            else
                item:Remove()
            end
        --------------------------------------------------
        --- 
            inst:PushEvent("level_up")            
            inst.AnimState:PlayAnimation("grow")
            inst.AnimState:PushAnimation("idle_2", true)
        --------------------------------------------------
        return true
    end
    local function acceptable_replica_init(inst,replica_com)
        replica_com:SetText("tbat_building_piano_rabbit",STRINGS.ACTIONS.UPGRADE.GENERIC)
        replica_com:SetSGAction("dolongaction")
        replica_com:SetTestFn(acceptable_test_fn)
        replica_com:SetDistance(1.5)
    end
    local function acceptable_com_install(inst)
        inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_acceptable",acceptable_replica_init)
        if not TheWorld.ismastersim then
            return
        end
        inst:AddComponent("tbat_com_acceptable")
        inst.components.tbat_com_acceptable:SetOnAcceptFn(acceptable_on_accept_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---  level
    local function level_up_event(inst)
        inst:AddTag("lv2")
        inst.components.tbat_data:Set("lv2",true)
        inst.Light:SetRadius(15)
        inst.AnimState:PlayAnimation("idle_2",true)
    end
    local function level_onload(com)
        if com:Get("lv2") then
            level_up_event(com.inst)
        end
    end
    local function level_sys_install(inst)
        if not TheWorld.ismastersim then
            return
        end
        inst:ListenForEvent("level_up",level_up_event)
        inst.components.tbat_data:AddOnLoadFn(level_onload)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- offical workable
    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- onbuild_event
    local function onbuild_event(inst,_table)
        local builder = _table and _table.builder
        if builder and builder.components.talker then
            builder.components.talker:Say(TBAT:GetString2(this_prefab,"onbuild_talk"))
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建建筑
    local function building_fn()
        -------------------------------------------------
        ---
            local inst = CreateEntity()
            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddSoundEmitter()
            inst.entity:AddNetwork()
            inst.entity:AddMiniMapEntity()
            inst.MiniMapEntity:SetIcon(this_prefab..".tex")
            TBAT.SKIN:SetDefaultBankBuild(inst,"tbat_building_sunflower_hamster","tbat_building_sunflower_hamster")
            -- inst.AnimState:SetBank("tbat_building_sunflower_hamster")
            -- inst.AnimState:SetBuild("tbat_building_sunflower_hamster")
            inst.AnimState:PlayAnimation("idle_1",true)
            inst:AddTag("structure")
            inst:AddTag(this_prefab)
        -------------------------------------------------
        --- 灯光
            inst.entity:AddLight()
            inst.Light:SetFalloff(0.7)
            inst.Light:SetIntensity(.4)
            inst.Light:SetRadius(12)
            inst.Light:SetColour(180 / 255, 195 / 255, 150 / 255)
            inst.Light:Enable(false)
        -------------------------------------------------
        --- 动画特效
            if not TheNet:IsDedicated() then
                create_anim_fx(inst)
                inst:ListenForEvent("anim_fx_update",anim_fx_event)

            end
        -------------------------------------------------
        --- net
            inst.net_anim_fx = net_bool(inst.GUID, "net_anim_fx","anim_fx_update")
            inst.net_anim_fx:set(false)
        -------------------------------------------------
        ---
            inst.LightOn = LightOn
            inst.LightOff = LightOff
        -------------------------------------------------
            inst.entity:SetPristine()
        -------------------------------------------------
        ---
            if TheWorld.ismastersim then
                inst:AddComponent("tbat_data")
            end
            acceptable_com_install(inst)
            level_sys_install(inst)
            inst:LightOff()
        -------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        -------------------------------------------------
        ---
            inst:DoTaskInTime(0,light_init)
            inst:WatchWorldState("phase",light_init_delay)
        -------------------------------------------------
        ---
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        -------------------------------------------------
        ----
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,5)
        -------------------------------------------------
        ----
            inst:ListenForEvent("onbuilt",onbuild_event)            
        -------------------------------------------------
        --- 皮肤和名称
            inst:AddComponent("tbat_com_skin_data")
            inst:AddComponent("named")
            inst.components.named:TBATSetName(TBAT:GetString2(this_prefab,"name"))
        -------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
    local function placer_postinit_fn(inst)
        inst.AnimState:PlayAnimation("idle_1",true)
        create_anim_fx(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, building_fn, assets),
    MakePlacer(this_prefab.."_placer",this_prefab,this_prefab, "idle_1", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)


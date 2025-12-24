--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

     双   生   小   鹅   灯

     为了可以自由调节高度。把动画和 本体剥离。

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_twin_goslings"
    local ANIM_FX_HIGH_OFFSET = 3    --- 动画高度
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_twin_goslings.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 高亮child
    local function AddHighLightChild(inst,child)
        inst.highlightchildren = inst.highlightchildren or{}
        table.insert(inst.highlightchildren,child)
    end
    local function AddHighLightChild_Client(inst)
        local parent = inst.entity:GetParent()
        if parent then
            parent.highlightchildren = parent.highlightchildren or{}
            table.insert(parent.highlightchildren,inst)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- light controller
    local function light_swtich_fn(inst)
        if TheWorld:HasTag("cave") or not TheWorld.state.isday then
            inst.Light:Enable(true)
            inst.anim_fx.AnimState:ShowSymbol("light")
        else
            inst.Light:Enable(false)
            inst.anim_fx.AnimState:HideSymbol("light")
        end
    end
    local function light_update_fn(inst)
        inst:DoTaskInTime(5,light_swtich_fn)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 
    local function OnBuilt(inst,doer)
        inst.anim_fx.AnimState:PlayAnimation("place")
        inst.anim_fx.AnimState:PushAnimation("idle",true)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- workable_cmd
    local workable_cmd = {
        block_remove = true,
        onfinished = function(inst,worker)
            inst.Light:Enable(false)
            inst.anim_fx.AnimState:HideSymbol("light")
            inst.anim_fx.AnimState:PlayAnimation("remove")
            -- inst:ListenForEvent("animover",inst.Remove)
            inst:DoTaskInTime(0.5,inst.Remove)
        end,
        fx = false,
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.entity:AddMiniMapEntity()
        inst.MiniMapEntity:SetIcon(this_prefab..".tex")
        -- inst.AnimState:SetBank("tbat_building_twin_goslings")
        -- inst.AnimState:SetBuild("tbat_building_twin_goslings")
        -- inst.AnimState:PlayAnimation("idle",true)
        -- inst.AnimState:HideSymbol("light")
        inst:AddTag("structure")
        inst:AddTag(this_prefab)
        ------------------------------------------
        ---
            inst.entity:AddDynamicShadow()
            inst.DynamicShadow:SetSize(2, 0.3)
        ------------------------------------------
        ---
            inst.entity:AddLight()
            inst.Light:SetFalloff(0.85)
            inst.Light:SetIntensity(.75)
            inst.Light:SetRadius(1)
            inst.Light:SetColour(180 / 255, 195 / 255, 150 / 255)
            inst.Light:Enable(false)
        ------------------------------------------
        inst.entity:SetPristine()
        ------------------------------------------
        --- 动画件剥离
            if TheWorld.ismastersim then
                local fx = inst:SpawnChild(this_prefab.."_fx")
                AddHighLightChild(inst,fx)
                fx.Transform:SetPosition(0,ANIM_FX_HIGH_OFFSET,0)
                inst.anim_fx = fx
            end
            inst:AddComponent("highlight")   --- 高亮处理 -- parent.highlightchildren = {inst}
        ------------------------------------------

        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------
        ---
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,5,workable_cmd)
        ------------------------------------------
        ---
            light_update_fn(inst)
            inst:WatchWorldState("phase",light_update_fn)
            inst:WatchWorldState("cycles",light_update_fn)
        ------------------------------------------
        ---
            inst.OnBuilt = OnBuilt
        ------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---- 
    local function anim_fx()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst:AddTag("CLASSIFIED")
        inst:AddTag("NOCLICK")
        inst:AddTag("INLIMBO")
        inst:AddTag("FX")
        inst:AddTag("NOCLICK")
        inst.AnimState:SetBank("tbat_building_twin_goslings")
        inst.AnimState:SetBuild("tbat_building_twin_goslings")
        inst.AnimState:PlayAnimation("idle",true)
        inst.AnimState:HideSymbol("light")
        inst.entity:SetPristine()
        inst.persists = false   --- 是否留存到下次存档加载。
        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = AddHighLightChild_Client
            return inst
        end
        return inst

    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        inst.AnimState:HideSymbol("light")
        inst.AnimState:HideSymbol("idle")
        local fx = inst:SpawnChild(this_prefab.."_fx")
        fx.Transform:SetPosition(0,ANIM_FX_HIGH_OFFSET,0)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets),
        MakePlacer(this_prefab.."_placer",this_prefab,this_prefab,"idle",nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil),
        Prefab(this_prefab.."_fx", anim_fx)


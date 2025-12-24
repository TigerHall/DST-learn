--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    薰衣草花房

    转换概率  在 visual container  那边配置

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_building_lavender_flower_house"
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_building_lavender_flower_house.zip"),
        Asset("ANIM", "anim/tbat_chat_icon_building_lavender_flower_house.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 虚拟容器
    local function GetVisualContainer(inst)
        if inst.visual_container and inst.visual_container:IsValid() then
            return inst.visual_container
        end
        local visual_container = nil
        local record = inst.components.tbat_data:Get("container_record")
        if record then
            visual_container = SpawnSaveRecord(record)
        else
            visual_container = SpawnPrefab("tbat_building_lavender_flower_house_visual_container")
        end
        visual_container.Transform:SetPosition(0,0,0)
        -- visual_container.entity:SetParent(inst.entity)
        inst.visual_container = visual_container
        return visual_container
    end
    local function ContainerSave(com)
        local container_inst = GetVisualContainer(com.inst)
        local record = container_inst:GetSaveRecord()
        com:Set("container_record",record)
    end
    local function init(inst)
        local container_inst = GetVisualContainer(inst)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 摧毁
    local destroy_fn = function(inst,worker)
        local visual_container = GetVisualContainer(inst)
        visual_container.Transform:SetPosition(inst.Transform:GetWorldPosition())
        visual_container.components.container:Close()
        visual_container.components.container:DropEverything()
        visual_container:Remove()
    end
    local destroy_cmd = {
        onfinished = destroy_fn,
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- pet  pick event
    local function pet_pick_event(inst,data)
        local visual_container = GetVisualContainer(inst)
        visual_container:PushEvent("pet_pick",data)
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 修改COM
    local workable_replica_fn = function(inst,replica_com)
        inst:DoTaskInTime(1,function()
            replica_com:SetTestFn(function(inst,doer,right_click)
                if not right_click then
                    return false
                end
                if inst:HasTag(doer.userid) then
                    replica_com:SetSGAction("dolongaction")
                    replica_com:SetText(this_prefab,"\n"..TBAT:GetString2(this_prefab,"action_pet_back_str"))
                else                        
                    replica_com:SetSGAction("give")
                    replica_com:SetText(this_prefab,"\n"..TBAT:GetString2(this_prefab,"action_look_str"))
                end
                return true
            end)
            
        end)
    end
    local workable_active_fn_replace = function(inst)
        local old_active_fn = inst.components.tbat_com_workable.acive_fn
        inst.components.tbat_com_workable.acive_fn = function(inst,doer)
            ---------------------------------------------------------------------------------------
            local container_inst = inst:GetVisualContainer()
            ---------------------------------------------------------------------------------------
            --- 正在打开容器，则切换到归还宠物逻辑
                if container_inst.components.container:IsOpen() and container_inst.components.container:IsOpenedBy(doer) then
                    container_inst.components.container:Close(doer)
                    container_inst.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    return old_active_fn(inst,doer)                
                end
            ---------------------------------------------------------------------------------------
            --- 如果容器没打开，则打开。并上切换TAG
                if not container_inst.components.container:IsOpen() then
                    container_inst.Transform:SetPosition(doer.Transform:GetWorldPosition())
                    container_inst.components.container:Open(doer)
                    inst:AddTag(doer.userid)
                    local tempInst = CreateEntity()
                    tempInst:ListenForEvent("onclose",function(_,data)
                        if data and data.doer and data.doer.userid == doer.userid then
                            inst:RemoveTag(doer.userid)
                            tempInst:Remove()
                        end
                    end,container_inst)
                    return true
                end
            ---------------------------------------------------------------------------------------
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function house_fn()
        --------------------------------------------------------------------------------------------------------
            local inst = CreateEntity()
            inst.entity:AddTransform()
            inst.entity:AddAnimState()
            inst.entity:AddSoundEmitter()
            inst.entity:AddNetwork()
            inst.entity:AddMiniMapEntity()
            inst.MiniMapEntity:SetIcon("tbat_building_lavender_flower_house.tex")
            MakeObstaclePhysics(inst, 1.2)
            inst.AnimState:SetBank("tbat_building_lavender_flower_house")
            inst.AnimState:SetBuild("tbat_building_lavender_flower_house")
            inst.AnimState:PlayAnimation("idle")
            inst:AddTag("structure")
            inst:AddTag(this_prefab)
        --------------------------------------------------------------------------------------------------------
            inst.entity:SetPristine()
        --------------------------------------------------------------------------------------------------------
            inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_workable",workable_replica_fn)
            TBAT.PET_MODULES:PetHouseComInstall(inst,"tbat_pet_eyebone_lavender_kitty")
            if TheWorld.ismastersim then
                workable_active_fn_replace(inst)
            end
        --------------------------------------------------------------------------------------------------------
            if not TheWorld.ismastersim then
                return inst
            end
        --------------------------------------------------------------------------------------------------------
        ---
            inst.GetVisualContainer = GetVisualContainer
        --------------------------------------------------------------------------------------------------------
        --- 检查
            inst:AddComponent("inspectable")
        --------------------------------------------------------------------------------------------------------
        --- 数据
            if inst.components.tbat_data == nil then
                inst:AddComponent("tbat_data")
            end
            inst.components.tbat_data:AddOnSaveFn(ContainerSave)
        --------------------------------------------------------------------------------------------------------
        --- 作祟
            MakeHauntableLaunch(inst)
        --------------------------------------------------------------------------------------------------------
        --- 拆毁
            TBAT.MODULES:OFFICIAL_WORKABLE_DESTROY_INSTALL(inst,10,destroy_cmd)
        --------------------------------------------------------------------------------------------------------
        ---
            inst:ListenForEvent("pet_pick",pet_pick_event)
            inst:DoTaskInTime(0,init)
        --------------------------------------------------------------------------------------------------------
        --- 
            inst.components.tbat_com_action_fail_reason:Add_Reason("give_back_item_fail",TBAT:GetString2(this_prefab,"give_back_item_fail"))
        --------------------------------------------------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- placer
    local function placer_postinit_fn(inst)
        
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, house_fn, assets),
        MakePlacer(this_prefab.."_placer", "tbat_building_lavender_flower_house", "tbat_building_lavender_flower_house", "idle", nil, nil, nil, nil, nil, nil, placer_postinit_fn, nil, nil)
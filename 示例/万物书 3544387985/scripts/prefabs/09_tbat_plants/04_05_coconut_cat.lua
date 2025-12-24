--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    预制的prefab模板

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 前置准备
    local this_prefab = "tbat_plant_coconut_cat"
    local anim_scale = 2
    local TAKE_CARE_RADIUS = 12
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Assets素材资源
    local assets =
    {
        Asset("ANIM", "anim/tbat_plant_coconut_cat.zip"),
    }
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 右键使用
    local function create_indicator(inst)        
        if inst.indicator and inst.indicator:IsValid() then
            inst.indicator.time = 0
            return
        end
        local indicator = inst:SpawnChild("tbat_sfx_dotted_circle_client")
        indicator:PushEvent("Set",{ radius = TAKE_CARE_RADIUS })
        inst.indicator = indicator
        local update_time = 0.3
        indicator:DoPeriodicTask(update_time,function()
            indicator.time = (indicator.time or 0) + update_time
            if indicator.time > 1 then
                indicator:Remove()
            end
        end)
        indicator:ListenForEvent("onremove",function()
            indicator:Remove()
        end,inst)
    end
    local function workable_test_fn(inst,doer,right_click)
        create_indicator(inst)
        return right_click
    end
    local function workable_on_work_fn(inst,doer)
        inst:Remove()
        doer.components.inventory:GiveItem(SpawnPrefab("tbat_plant_coconut_cat_kit"))
        return true
    end
    local function workable_replica_init(inst,replica_com)
        replica_com:SetTestFn(workable_test_fn)
        replica_com:SetText(this_prefab,STRINGS.ACTIONS.DISMANTLE)
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
--- deploy
    local function deploy_event(inst,cmd)
        inst.Transform:SetPosition(cmd.pt.x,0,cmd.pt.z)
        inst.AnimState:PlayAnimation("stage_2_to_3")
        inst.AnimState:PushAnimation("stage_3",true)
        if TBAT.DEBUGGING then
            inst:DoTaskInTime(3,function()
                inst:PushEvent("start_work_origin")
            end)
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 浇水+唱歌
    local NOTAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "burnt", "player", "monster" }
    -- local ONEOFTAGS = {"plant"}
    -- local ONEOFTAGS = {"tendable_farmplant"}
    local ONEOFTAGS = {"tendable_farmplant","farm_plant"}

    local old_on_hit_fn = nil
    local new_Hit = function(self,target)
        local x,y,z = self.inst.Transform:GetWorldPosition()
        old_on_hit_fn(self,target)
        local ents = TheSim:FindEntities(x,0,z,1,nil,nil,ONEOFTAGS)
        for i,tempInst in ipairs(ents) do
            if tempInst.components.farmplanttendable then
                tempInst.components.farmplanttendable:TendTo(self.inst.owner)
            end
        end
    end
        

    local PUMP_WORK_RANGE = TAKE_CARE_RADIUS        
    local easing = require("easing")
    local function spawn_project_for_pos(start_pos,targetpos,attacker,owningweapon)
        local x,y,z = start_pos.x,start_pos.y,start_pos.z
        local projectile = SpawnPrefab("waterstreak_projectile")
        projectile.Transform:SetPosition(x, 5, z)
        local dx = targetpos.x - x
        local dz = targetpos.z - z
        local rangesq = dx * dx + dz * dz
        local maxrange = PUMP_WORK_RANGE
        local speed = easing.linear(rangesq, 15, 3, maxrange * maxrange)
        projectile.components.complexprojectile:SetHorizontalSpeed(speed)
        projectile.components.complexprojectile:SetGravity(-25)
        projectile.components.complexprojectile:Launch(targetpos, attacker, owningweapon)
        old_on_hit_fn = old_on_hit_fn or projectile.components.complexprojectile.Hit
        projectile.components.complexprojectile.Hit = new_Hit
        
        projectile.owner = attacker
    end
    local function LaunchProjectile(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        if true then
            local ents = TheSim:FindEntities(x, y, z, PUMP_WORK_RANGE, nil, NOTAGS, ONEOFTAGS)
            local targetpos
            -- print("fff +++ ents",#ents)
            if #ents == 0 then
                -- targetpos = ents[1]:GetPosition()
                targetpos = Vector3(x,y,z)
                spawn_project_for_pos(targetpos,targetpos,inst,inst)
            else
                local start_pos = Vector3(x,y,z)
                for i, tempInst in ipairs(ents) do
                    tempInst:DoTaskInTime(i*FRAMES*2,function()
                        spawn_project_for_pos(start_pos,tempInst:GetPosition(),inst,inst)
                    end)
                end
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- main logic
    local function init(inst)
        inst.ready = true
    end
    local function start_work(inst)
        if not inst.ready then
            -- print("not ready!!!")
            return
        end
        -- TheNet:Announce("椰子猫猫【"..inst.GUID.."】开始丢水球工作！")
        LaunchProjectile(inst)
    end
    local function main_logic_install(inst)
        inst:ListenForEvent("start_work_origin",LaunchProjectile)
        inst:ListenForEvent("start_work",start_work)
        inst:ListenForEvent("entitywake",start_work)
        -- TheWorld.components.tbat_com_special_timer_for_theworld:AddOneTimeTimer(init,inst)
        inst:DoTaskInTime(0,init)
        inst:DoPeriodicTask(TBAT.DEBUGGING and 5 or  60,start_work,math.random(TBAT.DEBUGGING and 2 or 30))
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 创建物品
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("tbat_plant_coconut_cat")
        inst.AnimState:SetBuild("tbat_plant_coconut_cat")
        inst.AnimState:PlayAnimation("stage_3",true)
        inst.AnimState:SetScale(anim_scale,anim_scale)
        inst:SetDeploySmartRadius(0.1)
        inst.entity:SetPristine()
        ------------------------------------------------------------
        ---
            workable_install(inst)
        ------------------------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
        ------------------------------------------------------------
        --- deploy
            inst:ListenForEvent("deploy",deploy_event)
        ------------------------------------------------------------
        ---
            inst:AddComponent("inspectable")
            MakeHauntableLaunch(inst)
        ------------------------------------------------------------
        ---
            main_logic_install(inst)
        ------------------------------------------------------------
        return inst
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
return Prefab(this_prefab, fn, assets)

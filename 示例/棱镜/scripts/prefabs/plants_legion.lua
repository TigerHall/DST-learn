local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
local easing = require("easing")
local TOOLS_L = require("tools_legion")
local TOOLS_P_L = require("tools_plant_legion")
local prefs = {}
local pas = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local paw = {} --专门装打蜡对象的数据

pas.SetAnim = function(inst, bank, build, anim, isloop)
    inst.AnimState:SetBank(bank)
	inst.AnimState:SetBuild(build or bank)
    inst.AnimState:PlayAnimation(anim or "idle", isloop)
end
pas.SetMiniMap = function(inst, img, priority)
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon(img..".tex")
    if priority ~= nil then
        inst.MiniMapEntity:SetPriority(priority)
    end
end
pas.SetWorkable = function(inst, onworked, onfinished, actname, workleft) --可破坏组件
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS[actname or "DIG"])
    inst.components.workable:SetWorkLeft(workleft or 1)
    if onworked then
        inst.components.workable:SetOnWorkCallback(onworked)
    end
    if onfinished then
        inst.components.workable:SetOnFinishCallback(onfinished)
    end
end
pas.SetWorkable2 = function(inst, onworked, onfinished, actname, workleft) --可破坏组件2
    inst.components.workable:SetWorkAction(ACTIONS[actname or "DIG"])
    inst.components.workable:SetWorkLeft(workleft or 1)
    inst.components.workable:SetOnWorkCallback(onworked)
    inst.components.workable:SetOnFinishCallback(onfinished)
end
pas.SetInventoryItem = function(inst, img) --物品栏组件
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = img
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..img..".xml"
end
pas.SetFuel = function(inst, value) --燃料组件
    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = value or TUNING.TINY_FUEL
end
pas.SetDeployable = function(inst, ondeploy, mode, spacing) --摆放组件
    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = ondeploy
    if mode ~= nil then --Tip: 默认就是 DEPLOYMODE.DEFAULT。代表可以摆放在地面、船上。排除水面和虚空
        inst.components.deployable:SetDeployMode(mode)
    end
    inst.components.deployable:SetDeploySpacing(spacing or DEPLOYSPACING.LESS)
end
pas.SetPlacerAnim = function(inst, skin)
    if skin == nil or skin == "" or ls_skineddata[skin] == nil then
        return true
    end
    local dd = ls_skineddata[skin]
    if dd.fn_placer ~= nil then
        dd.fn_placer(inst)
    elseif dd.anim ~= nil then
        if dd.anim.bank then
            inst.AnimState:SetBank(dd.anim.bank)
        end
        if dd.anim.build then
            inst.AnimState:SetBuild(dd.anim.build)
        end
    else
        return true
    end
    return false
end
pas.SetEquippable = function(inst, onequip, onunequip, slot) --可装备组件
    inst:AddComponent("equippable")
    if slot ~= nil then
        inst.components.equippable.equipslot = slot --默认就是手部
    end
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end
pas.SetDeploySmartRadius = function(inst, radkey)
    --反正就是种植半径的一半
    inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[radkey or DEPLOYSPACING.LESS] / 2)
end
pas.SetRotatable_com = function(inst)
    inst:AddTag("rotatableobject") --能让栅栏击剑起作用
    inst:AddTag("flatrotated_l") --棱镜标签：旋转时旋转180度
    inst.Transform:SetTwoFaced() --两个面，这样就可以左右不同（再多貌似有问题）
end
pas.SetStackable = function(inst, maxsize) --叠加组件
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = maxsize or TUNING.STACK_SIZE_SMALLITEM
end

pas.OnLandedClient_new = function(self, ...)
    if self.OnLandedClient_legion ~= nil then
        self.OnLandedClient_legion(self, ...)
    end
    if self.floatparam_l ~= nil then
        self.inst.AnimState:SetFloatParams(self.floatparam_l, 1, self.bob_percent)
    end
end
pas.SetFloatable = function(inst, float) --漂浮组件
    MakeInventoryFloatable(inst, float[2], float[3], float[4])
    if float[1] ~= nil then
        local floater = inst.components.floater
        if floater.OnLandedClient_legion == nil then
            floater.OnLandedClient_legion = floater.OnLandedClient
            floater.OnLandedClient = pas.OnLandedClient_new
        end
        floater.floatparam_l = float[1]
    end
end

--------------------------------------------------------------------------
--[[ 雨竹 ]]
--------------------------------------------------------------------------

pas.assets_monstrain = { Asset("ANIM", "anim/monstrain.zip") }

pas.SetFruitAnim_monstrain = function(inst, hasfruit) --设置果实的贴图
    if inst._setfruitonanimover then
        inst._setfruitonanimover = nil
        inst:RemoveEventCallback("animover", pas.SetFruitAnim_monstrain)
    end
    if hasfruit then
        inst.AnimState:Show("fruit") --这里参数为动画中贴图的设定名字，不是通道名
    else
        inst.AnimState:Hide("fruit")
    end
end
pas.SetOnAnimOver_monstrain = function(inst) --在一个动画播放结束才隐藏果实贴图
    if inst._setfruitonanimover then
        pas.SetFruitAnim_monstrain(inst, false)
    else
        inst._setfruitonanimover = true
        inst:ListenForEvent("animover", pas.SetFruitAnim_monstrain)
    end
end
pas.CancelSetOnAnimOver_monstrain = function(inst) --取消在一个动画播放结束才隐藏果实贴图的设定
    if inst._setfruitonanimover then
        pas.SetFruitAnim_monstrain(inst, false)
    end
end

pas.Shake_monstrain = function(inst)
    if not inst.components.pickable:IsBarren() then
        inst.AnimState:PlayAnimation("shake")
        inst.AnimState:PushAnimation("idle", true)
        pas.CancelSetOnAnimOver_monstrain(inst)
    end
end
pas.GetStatus_monstrain = function(inst)
    return (inst.AnimState:IsCurrentAnimation("idle_summer") and "SUMMER")
        or (inst.AnimState:IsCurrentAnimation("idle_winter") and "WINTER")
        or (not inst.components.pickable:CanBePicked() and "PICKED")
        or "GENERIC"
end
pas.OnFinished_monstrain = function(inst, worker)
    local pos = inst:GetPosition()
    TOOLS_L.SpawnStackDrop("dug_monstrain", 1, pos, nil, nil, { dropper = inst })
    if inst.components.pickable:CanBePicked() then --成熟了
        TOOLS_L.SpawnStackDrop("squamousfruit", 1, pos, nil, nil, { dropper = inst })
        TOOLS_L.SpawnStackDrop("monstrain_leaf", math.random() < 0.5 and 2 or 1, pos, nil, nil, { dropper = inst })
    end
    inst:Remove()
end
pas.CanBeFertilized_monstrain = function(self)
    return false
end
pas.OnHaunt_monstrain = function(inst) --被作祟时
    if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
        pas.Shake_monstrain(inst)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_COOLDOWN_TINY
        return true
    end
    return false
end

pas.OnRegen_monstrain = function(inst) --成熟时
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
    pas.SetFruitAnim_monstrain(inst, true)
    inst.legiontag_sivctl_timely = nil
end
pas.OnPicked_monstrain = function (inst, picker, lootbase) --被采集时
    inst.AnimState:PlayAnimation("shake")
    inst.AnimState:PushAnimation("idle", true)
    pas.SetOnAnimOver_monstrain(inst)

    local loot = {}
    local pos = inst:GetPosition()
    TOOLS_L.SpawnStackDrop("squamousfruit", 1, pos, nil, loot, { dropper = inst })
    TOOLS_L.SpawnStackDrop("monstrain_leaf", 1, pos, nil, loot, { dropper = inst })
    if picker ~= nil then
        picker:PushEvent("picksomething", { object = inst, loot = loot })
        if picker.components.inventory ~= nil then --给予采摘者
            for _, item in pairs(loot) do
                if item.components.inventoryitem ~= nil then
                    picker.components.inventory:GiveItem(item, nil, pos)
                end
            end
        end
    end
end
pas.OnEmpty_monstrain = function(inst) --重新开始生长时
    inst.Physics:SetActive(true) --开启体积
    if POPULATING then
        inst.AnimState:PlayAnimation("idle", true)
        TOOLS_L.RandomAnimFrame(inst)
    elseif inst.AnimState:IsCurrentAnimation("idle_winter") then
        inst.AnimState:PlayAnimation("winter_to_idle")
        inst.AnimState:PushAnimation("idle", true)
    elseif inst.AnimState:IsCurrentAnimation("idle_summer") then
        inst.AnimState:PlayAnimation("summer_to_idle")
        inst.AnimState:PushAnimation("idle", true)
    else
        inst.AnimState:PlayAnimation("idle", true)
        TOOLS_L.RandomAnimFrame(inst)
    end
    pas.SetFruitAnim_monstrain(inst, false)
    inst.legiontag_sivctl_timely = nil
    inst.components.pickable.cycles_left = nil --Pickable:MakeEmpty() 并不会修改这个数据，所以只能这里手动改一下
end
pas.OnBarren_monstrain = function(inst, wasempty) --枯萎时
    inst.Physics:SetActive(false) --取消体积
    local idlepst = TheWorld.state.iswinter and "idle_winter" or "idle_summer"
    if POPULATING then
        inst.AnimState:PlayAnimation(idlepst, true)
    else
        inst.AnimState:PlayAnimation("withering")
        inst.AnimState:PushAnimation(idlepst, true)
    end
    pas.CancelSetOnAnimOver_monstrain(inst)
    inst:RemoveTag("barren") --这个标签代表能被尝试施肥，但我不想它出现
    if idlepst == "idle_summer" then --冬天并不是缺水
        inst.legiontag_sivctl_timely = true
    else
        inst.legiontag_sivctl_timely = nil
    end
    inst.components.pickable.targettime = nil --Pickable:MakeBarren() 并不会修改这个数据，所以只能这里手动改一下
end

pas.OnIsNight_monstrain = function(inst)
    if inst:HasTag("lifeless_l") or TheWorld.state.isnight or inst.components.pickable:IsBarren() then
        inst.components.childspawner:StopSpawning()
        for _, child in pairs(inst.components.childspawner.childrenoutside) do
            if child.components.homeseeker ~= nil then
                child.components.homeseeker:GoHome()
            end
            child:PushEvent("gohome")
        end
    else
        inst.components.childspawner:StartSpawning()
    end
end
pas.CostNutrition_monstrain = function(inst, actlcpt, dosoil)
    if not TheWorld.state.issummer or not inst.components.pickable:IsBarren() then --夏天，枯萎了才需要汲水
        return
    end
    local mo = TOOLS_P_L.CostMoisture(inst, inst.sivctls, actlcpt, 10, false, nil)
    if mo ~= nil then --汲水成功，恢复生长状态
        inst.components.pickable:MakeEmpty()
        TOOLS_P_L.SpawnFxMoi(inst)
    end
end
pas.OnSeasonChange_monstrain = function(inst) --季节变化时
    if TheWorld.state.iswinter then
        inst.components.pickable:MakeBarren()
        return
    elseif TheWorld.state.issummer then
        local mo = TOOLS_P_L.CostMoisture(inst, inst.sivctls, nil, 10, false, nil)
        if mo == nil then --汲水失败，变成枯萎状态
            inst.components.pickable:MakeBarren()
            return
        else
            TOOLS_P_L.SpawnFxMoi(inst)
        end
    end
    -- inst.components.pickable:Resume() --兼容以前的数据，以后记得删了
    if inst.components.pickable:IsBarren() then --判定一下，防止重置了生长进度
        inst.components.pickable:MakeEmpty()
    end
end
pas.Wax_monstrain = function(inst, doer, waxitem, right)
    local dd = {}
    if inst.components.pickable:CanBePicked() then
        dd.state = 3
    elseif inst.components.pickable:IsBarren() then
        if TheWorld.state.iswinter then
            dd.state = 2
        else
            dd.state = 1
        end
    end
    if right then
        return TOOLS_L.WaxObject(inst, doer, waxitem, "monstrain_waxed", dd, true)
    else
        return TOOLS_L.WaxObject(inst, doer, waxitem, "monstrain_item_waxed", dd, nil)
    end
end

pas.Init_monstrain = function(inst)
    inst.task_init = nil
    inst:WatchWorldState("iswinter", pas.OnSeasonChange_monstrain)
    inst:WatchWorldState("issummer", pas.OnSeasonChange_monstrain)
    inst:WatchWorldState("isnight", pas.OnIsNight_monstrain)
    -- pas.OnSeasonChange_monstrain(inst) --pickable组件会维护状态的
    pas.OnIsNight_monstrain(inst)
end
pas.OnSave_monstrain = function(inst, data)
    if inst:HasTag("lifeless_l") then
        data.lifeless_l = true
    end
end
pas.OnLoad_monstrain = function(inst, data)
    if data ~= nil then
        if data.lifeless_l then
            inst:AddTag("lifeless_l")
        end
    end
end
pas.NameDetail_monstrain = function(inst)
    if inst:HasTag("lifeless_l") then
        return STRINGS.NAMEDETAIL_L.SMEARED.MONSTRAIN
    end
end
pas.Smear_monstrain = function(inst, doer, item)
    inst:AddTag("lifeless_l")
    inst.components.childspawner:StopSpawning()
end

table.insert(prefs, Prefab("monstrain", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    pas.SetMiniMap(inst, "monstrain", nil)

    pas.SetDeploySmartRadius(inst, nil)
    MakeSmallObstaclePhysics(inst, .1)

    pas.SetAnim(inst, "monstrain", nil, nil, true)
    inst.Transform:SetScale(1.4, 1.4, 1.4) --设置相对大小

    pas.SetFruitAnim_monstrain(inst, true)
    pas.SetRotatable_com(inst)

    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("birdblocker")
    inst:AddTag("plant")
    inst:AddTag("waxable_l")
    -- inst:AddTag("waxable_l2")

    inst.no_wet_prefix = true
    inst.legion_namedetail = pas.NameDetail_monstrain

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.legiontag_nopost_pickable = true --雨竹不要做对pickable组件的修改
    inst.CostNutrition = pas.CostNutrition_monstrain
    inst.legionfn_smear_siv = pas.Smear_monstrain

    TOOLS_L.RandomAnimFrame(inst)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = pas.GetStatus_monstrain

    inst:AddComponent("lootdropper")

    inst:AddComponent("savedrotation")

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "raindonate"
    inst.components.childspawner:SetSpawnPeriod(TUNING.MOSQUITO_POND_SPAWN_TIME)
    inst.components.childspawner:SetRegenPeriod(TUNING.MOSQUITO_POND_REGEN_TIME)
    inst.components.childspawner:SetMaxChildren(1)
    inst.components.childspawner:StartRegen()

    inst:AddComponent("pickable")
    inst.components.pickable.CanBeFertilized = pas.CanBeFertilized_monstrain --不能被施肥
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"
    inst.components.pickable:SetUp(nil, TUNING.TOTAL_DAY_TIME*6)
    inst.components.pickable.onregenfn = pas.OnRegen_monstrain
    inst.components.pickable.onpickedfn = pas.OnPicked_monstrain
    inst.components.pickable.makeemptyfn = pas.OnEmpty_monstrain
    inst.components.pickable.makebarrenfn = pas.OnBarren_monstrain
    --inst.components.pickable.ontransplantfn = OnTransPlant_monstrain

    pas.SetWorkable(inst, pas.Shake_monstrain, pas.OnFinished_monstrain, nil, 2)

    MakeHauntableIgnite(inst)
    AddHauntableCustomReaction(inst, pas.OnHaunt_monstrain, false, false, true)

    inst.OnSave = pas.OnSave_monstrain
    inst.OnLoad = pas.OnLoad_monstrain
    TOOLS_L.SetSprayWaxable(inst, nil, pas.Wax_monstrain)
    inst.task_init = inst:DoTaskInTime(0.3, pas.Init_monstrain)
    TOOLS_P_L.FindSivCtls(inst, inst, { true, nil, true }, nil, POPULATING)

    return inst
end, pas.assets_monstrain, {
    "raindonate",
    "squamousfruit",
    "monstrain_leaf",
    "dug_monstrain"
}))

--------------------------------------------------------------------------
--[[ 雨竹块茎 ]]
--------------------------------------------------------------------------

pas.OnMoistureDelta_tuber = function(inst, data)
    --小于1是为了忽略干燥导致的损失(不然水壶得浇水5次)
    if inst:IsValid() and inst.components.moisture:GetMoisturePercent() >= 0.95 then
        local tree = SpawnPrefab("monstrain")
        if tree ~= nil then
            tree.AnimState:PlayAnimation("idle_summer", true)
            tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
            if TheWorld.state.iswinter or TheWorld.state.issummer then
                tree.components.pickable:MakeBarren()
            else
                tree.components.pickable:MakeEmpty()
            end
            inst.SoundEmitter:PlaySound("farming/common/farm/rot")
            inst:Remove()
        end
    end
end
pas.OnFinished_tuber = function(inst, worker)
    inst.components.lootdropper:SpawnLootPrefab("dug_monstrain")
    inst:Remove()
end
pas.OnTimerDone_tuber = function(inst, data)
    if data.name == "dehydration" then
        inst.components.lootdropper:SpawnLootPrefab("spoiled_food")
        inst:Remove()
    end
end
pas.CostNutrition_tuber = function(inst, actlcpt, dosoil)
    local moicpt = inst.components.moisture
    local need = moicpt:GetMaxMoisture() - moicpt:GetMoisture()
    if need <= 0 then --按理来说这个情况不会出现的
        pas.OnMoistureDelta_tuber(inst, nil)
        return
    end
    local mo = TOOLS_P_L.CostMoisture(inst, inst.sivctls, actlcpt, need, false, nil)
    if mo ~= nil then
        TOOLS_P_L.SpawnFxMoi(inst, true)
        moicpt:DoDelta(mo, true)
    end
end
pas.Wax_tuber = function(inst, doer, waxitem, right)
    if right then
        return TOOLS_L.WaxObject(inst, doer, waxitem, "monstrain_waxed", { state = 1 }, true)
    else
        return TOOLS_L.WaxObject(inst, doer, waxitem, "monstrain_item_waxed", { state = 1 }, nil)
    end
end

table.insert(prefs, Prefab("monstrain_wizen", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    pas.SetMiniMap(inst, "monstrain", nil)
    pas.SetDeploySmartRadius(inst, nil)

    pas.SetAnim(inst, "monstrain", nil, "idle_summer", true)
    inst.Transform:SetScale(1.4, 1.4, 1.4)

    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("birdblocker")
    inst:AddTag("plant")
    inst:AddTag("ctlmoi_l") --使其可被浇水，不过是我自己加的，官方没有
    inst:AddTag("waxable_l")
    -- inst:AddTag("waxable_l2")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.CostNutrition = pas.CostNutrition_tuber

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    pas.SetWorkable(inst, nil, pas.OnFinished_tuber, nil, nil)

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("dehydration", 3*TUNING.TOTAL_DAY_TIME)
    inst:ListenForEvent("timerdone", pas.OnTimerDone_tuber)

    inst:AddComponent("moisture")
    inst:ListenForEvent("moisturedelta", pas.OnMoistureDelta_tuber)

    MakeHauntableIgnite(inst)
    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    TOOLS_L.SetSprayWaxable(inst, nil, pas.Wax_tuber)
    TOOLS_P_L.FindSivCtls(inst, inst, { true, nil, true }, true, POPULATING) --水分重要，需及时吸取来扎根

    return inst
end, pas.assets_monstrain, { "monstrain", "dug_monstrain" }))

--------------------------------------------------------------------------
--[[ 浆果丛类的植物，比如棱镜三花丛 ]]
--------------------------------------------------------------------------

pas.SetBerries_bush = function(inst, pct)
    if inst._setberriesonanimover then
        inst._setberriesonanimover = nil
        inst:RemoveEventCallback("animover", pas.SetBerries_bush)
    end
    if inst._fruitform then --花朵和叶子在同一张图的贴图形式
        if pct == nil then
            inst.AnimState:ClearOverrideSymbol("bush_berry_build")
        elseif pct >= 0.9 then
            inst.AnimState:OverrideSymbol("bush_berry_build", inst.AnimState:GetBuild(), "bush3")
        elseif pct >= 0.33 then
            inst.AnimState:OverrideSymbol("bush_berry_build", inst.AnimState:GetBuild(), "bush2")
        else
            inst.AnimState:OverrideSymbol("bush_berry_build", inst.AnimState:GetBuild(), "bush1")
        end
        return
    end
    if pct == nil then
        inst.AnimState:Hide("berries")
        inst.AnimState:Hide("berriesmore")
        inst.AnimState:Hide("berriesmost")
    elseif pct >= 0.9 then
        inst.AnimState:Hide("berries")
        inst.AnimState:Hide("berriesmore")
        inst.AnimState:Show("berriesmost")
    elseif pct >= 0.33 then
        inst.AnimState:Hide("berries")
        inst.AnimState:Show("berriesmore")
        inst.AnimState:Hide("berriesmost")
    else
        inst.AnimState:Show("berries")
        inst.AnimState:Hide("berriesmore")
        inst.AnimState:Hide("berriesmost")
    end
end
pas.SetOnAnimOver_bush = function(inst)
    if inst._setberriesonanimover then
        pas.SetBerries_bush(inst, nil)
    else
        inst._setberriesonanimover = true
        inst:ListenForEvent("animover", pas.SetBerries_bush)
    end
end
pas.CancelSetOnAnimOver_bush = function(inst)
    if inst._setberriesonanimover then
        pas.SetBerries_bush(inst, nil)
    end
end

pas.TriggerFlowerTag = function(inst, isadd)
    if inst:HasTag("bush_l_f") then --只有花丛才需要，普通丛不需要
        if isadd then
            inst:AddTag("flower")
        else
            inst:RemoveTag("flower")
        end
    end
end
pas.MakeEmpty_bush = function(inst) --变为正常生长的样子，没有果实贴图
    if POPULATING then
        inst.AnimState:PlayAnimation("idle", true)
        TOOLS_L.RandomAnimFrame(inst)
    elseif inst:HasTag("withered") or inst.AnimState:IsCurrentAnimation("dead") then
        inst.AnimState:PlayAnimation("dead_to_idle")
        inst.AnimState:PushAnimation("idle", true)
    else
        inst.AnimState:PlayAnimation("idle", true)
    end
    pas.TriggerFlowerTag(inst, true)
    pas.SetBerries_bush(inst, nil)
end
pas.MakeBarren_bush = function(inst) --缺肥缺水导致的枯萎时
    if not POPULATING and (inst:HasTag("withered") or inst.AnimState:IsCurrentAnimation("idle")) then
        inst.AnimState:PlayAnimation("idle_to_dead")
        inst.AnimState:PushAnimation("dead", false)
    else
        inst.AnimState:PlayAnimation("dead")
    end
    pas.CancelSetOnAnimOver_bush(inst)
    pas.TriggerFlowerTag(inst, false)
end
pas.GetBerriesPercent = function(pickable)
    return pickable.cycles_left and pickable.cycles_left / pickable.max_cycles or 1
end
pas.MakeFull_bush = function(inst) --成熟时
    local anim = "idle"
    local berries = nil
    if inst.components.pickable ~= nil then
        if inst.components.pickable:CanBePicked() then
            berries = pas.GetBerriesPercent(inst.components.pickable)
        elseif inst.components.pickable:IsBarren() then
            anim = "dead"
        end
    end
    if anim ~= "idle" then
        inst.AnimState:PlayAnimation(anim)
    elseif POPULATING then
        inst.AnimState:PlayAnimation("idle", true)
        TOOLS_L.RandomAnimFrame(inst)
    else
        inst.AnimState:PlayAnimation("grow")
        inst.AnimState:PushAnimation("idle", true)
    end
    pas.SetBerries_bush(inst, berries)
end
pas.OnTransplant_bush = function(inst) --被移植种下时，一般只在植物种在地上时触发
    inst.AnimState:PlayAnimation("dead")
    pas.SetBerries_bush(inst, nil)
    inst.components.pickable:MakeBarren() --置为枯萎状态
end
pas.Shake_bush = function(inst)
    if
        inst.components.pickable ~= nil and
        not inst.components.pickable:CanBePicked() and
        inst.components.pickable:IsBarren()
    then
        inst.AnimState:PlayAnimation("shake_dead")
        inst.AnimState:PushAnimation("dead", false)
    else
        inst.AnimState:PlayAnimation("shake")
        inst.AnimState:PushAnimation("idle", true)
    end
    pas.CancelSetOnAnimOver_bush(inst)
end
pas.OnHaunt_bush = function(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
        pas.Shake_bush(inst)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_COOLDOWN_TINY
        return true
    end
    return false
end

pas.GetRegenTime = function(inst, time)
    if inst.components.pickable == nil then
        return time
    end
    --V2C: nil cycles_left means unlimited picks, so use max value for math
    local max_cycles = inst.components.pickable.max_cycles
    local cycles_left = inst.components.pickable.cycles_left or max_cycles
    local num_cycles_passed = math.max(0, max_cycles - cycles_left)
    return time
        + TUNING.BERRY_REGROW_INCREASE * num_cycles_passed
        + TUNING.TOTAL_DAY_TIME * math.random()
end
pas.GetRegenTime_bush = function(inst)
    return pas.GetRegenTime(inst, TUNING.TOTAL_DAY_TIME*6)
end
pas.OnPicked_bush = function(inst, picker)
    if inst.components.pickable:IsBarren() then
        inst.AnimState:PlayAnimation("idle_to_dead")
        inst.AnimState:PushAnimation("dead", false)
        pas.SetBerries_bush(inst, nil)
        pas.TriggerFlowerTag(inst, false)
    else
        inst.AnimState:PlayAnimation("picked")
        inst.AnimState:PushAnimation("idle", true)
        pas.SetOnAnimOver_bush(inst)
    end
end
pas.Wax_bush = function(inst, doer, waxitem, right)
    local dd = { form = inst._fruitform }
    if inst.components.pickable ~= nil then
        if inst.components.pickable:CanBePicked() then
            local pct = pas.GetBerriesPercent(inst.components.pickable)
            if pct >= 0.9 then
                dd.state = 1
            elseif pct >= 0.33 then
                dd.state = 2
            else
                dd.state = 3
            end
        elseif inst.components.pickable:IsBarren() then
            dd.state = 4
        end
    end
    if right then
        return TOOLS_L.WaxObject(inst, doer, waxitem, inst.legion_waxprefab.."_waxed", dd, true)
    else
        return TOOLS_L.WaxObject(inst, doer, waxitem, inst.legion_waxprefab.."_item_waxed", dd, nil)
    end
end

pas.MakeBush = function(dd)
    table.insert(prefs, Prefab(dd.name, function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        pas.SetMiniMap(inst, dd.name, nil)
        pas.SetAnim(inst, "berrybush2", dd.name, nil, true)
        pas.SetRotatable_com(inst)

        inst:AddTag("bush")
        inst:AddTag("plant")
        inst:AddTag("bush_l") --棱镜标签：棱镜花丛专属标签。暂无作用

        -- MakeSnowCoveredPristine(inst) --由于某些花丛因体型原因，积雪效果有破绽，就不用了

        if dd.fn_common ~= nil then
            dd.fn_common(inst)
        end
        pas.SetBerries_bush(inst, 1)

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        TOOLS_L.RandomAnimFrame(inst)

        inst:AddComponent("inspectable")

        inst:AddComponent("savedrotation")

        inst:AddComponent("lootdropper")

        inst:AddComponent("pickable")
        inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
        inst.components.pickable.ontransplantfn = pas.OnTransplant_bush
        inst.components.pickable.makeemptyfn = pas.MakeEmpty_bush
        inst.components.pickable.makebarrenfn = pas.MakeBarren_bush
        inst.components.pickable.makefullfn = pas.MakeFull_bush
        -- inst.components.pickable.onpickedfn = pas.OnPicked_bush

        inst:ListenForEvent("onwenthome", pas.Shake_bush) --监听生物回家事件，目前只有火鸡会触发吧

        MakeHauntableIgnite(inst)
        AddHauntableCustomReaction(inst, pas.OnHaunt_bush, false, false, true)

        if dd.fn_server ~= nil then
            dd.fn_server(inst)
        end

        return inst
    end, dd.assets, dd.prefabs))
end

----------------
--[[ 蔷薇花丛 ]]
----------------

pas.SpawnFlowerWeapon = function(bush, pos, doer, swordname, nodrop, breakit)
    local items = {}
    if nodrop then
        TOOLS_L.SpawnStackDrop(swordname, 1, pos, doer, items, nil)
    else
        TOOLS_L.SpawnStackDrop(swordname, 1, pos, nil, items, { dropper = bush })
    end
    for _, item in ipairs(items) do
        bush.components.skinedlegion:SetLinkedSkin(item, "sword", doer)
        if breakit and item.components.finiteuses ~= nil then
            item.components.finiteuses:SetUses(1)
        end
    end
end
pas.SpawnLoot_rose = function(inst, picker, mustdrop)
    local sets
    local pos = inst:GetPosition()
    local rand = math.random()
    if math.random() < CONFIGS_LEGION.FLOWERWEAPONSCHANCE then --3%几率掉落剑
        pas.SpawnFlowerWeapon(inst, pos, picker, "rosorns")
    end
    if mustdrop then
        sets = { dropper = inst }
        picker = nil
    end
    if rand < 0.3 then --30%几率掉落花瓣，65%几率掉落树枝，5%几率掉落蔷薇折枝
        TOOLS_L.SpawnStackDrop("petals", 1, pos, picker, nil, sets)
    elseif rand < 0.95 then
        TOOLS_L.SpawnStackDrop("twigs", 1, pos, picker, nil, sets)
    else
        TOOLS_L.SpawnStackDrop("cutted_rosebush", 1, pos, nil, nil, { dropper = inst })
    end
    TOOLS_L.PushLuckyEvent(inst)
end
pas.OnPicked_rose = function(inst, picker)
    pas.OnPicked_bush(inst, picker)
    pas.SpawnLoot_rose(inst, picker, false)

    --采集时被刺伤
    --暗影仆从、盖娅、穿了荆棘甲的玩家 不会被刺伤
    if  picker and picker.components.combat ~= nil and
        not picker:HasAnyTag("shadowminion", "genesis_gaia") and
        not (
            picker.components.inventory ~= nil and
            (   picker.components.inventory:EquipHasTag("bramble_resistant") or
                (CONFIGS_LEGION.ENABLEDMODS.MythWords and picker.components.inventory:Has("thorns_pill", 1))
            )
        )
    then
        picker.components.combat:GetAttacked(inst, 3)
        if picker.task_l_pickrose == nil and picker.components.talker ~= nil and math.random() < 0.01 then
            picker.task_l_pickrose = picker:DoTaskInTime(0, function()
                if picker.components.talker ~= nil then
                    picker.components.talker:Say(GetString(picker, "ANNOUNCE_PICK_ROSEBUSH"))
                end
                picker.task_l_pickrose = nil
            end)
        else
            picker:PushEvent("thorns")
        end
    end
end
pas.OnFinished_rose = function(inst, worker)
    if inst.components.pickable ~= nil then
        local pos = inst:GetPosition()
        local sets = { dropper = inst }
        local withered = inst.components.witherable ~= nil and inst.components.witherable:IsWithered()
        if withered or inst.components.pickable:IsBarren() then --枯萎时被挖起
            TOOLS_L.SpawnStackDrop("twigs", 2, pos, nil, nil, sets)
        else
            if inst.components.pickable:CanBePicked() then --有果实时被挖起
                TOOLS_L.SpawnStackDrop(inst.components.pickable.product, 1, pos, nil, nil, sets)
                pas.SpawnLoot_rose(inst, worker, true)
            end
            TOOLS_L.SpawnStackDrop("dug_rosebush", 1, pos, nil, nil, sets)
        end
    end
    inst:Remove()
end
pas.Common_flowerbush = function(inst)
    -- MakeSmallObstaclePhysics(inst, .1)
    inst:SetPhysicsRadiusOverride(.5)
    inst:AddTag("flower") --花的标签
    inst:AddTag("witherable") --可枯萎标签
    inst:AddTag("renewable")
    inst:AddTag("bush_l_f") --棱镜标签：表示能被暗影仆从采摘(默认是带 flwoer 标签的东西无法被采摘)、能被沃比识别
    inst:AddTag("waxable_l")
end

pas.MakeBush({
    name = "rosebush",
    assets = {
        Asset("ANIM", "anim/berrybush2.zip"), --官方猪村浆果丛动画
        Asset("ANIM", "anim/rosebush.zip")
    },
    prefabs = { "petals_rose", "dug_rosebush", "rosorns", "twigs", "petals", "cutted_rosebush" },
    fn_common = function(inst)
        pas.SetDeploySmartRadius(inst, CONFIGS_LEGION.ROSEBUSHSPACING or DEPLOYSPACING.MEDIUM)
        pas.Common_flowerbush(inst)
        inst:AddTag("thorny") --多刺标签
        LS_C_Init(inst, "rosebush", false)
    end,
    fn_server = function(inst)
        inst:AddComponent("witherable")

        inst.components.pickable:SetUp("petals_rose", TUNING.TOTAL_DAY_TIME*6)
        inst.components.pickable.getregentimefn = pas.GetRegenTime_bush
        inst.components.pickable.max_cycles = TUNING.BERRYBUSH_CYCLES + math.random(2)
        inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
        inst.components.pickable.onpickedfn = pas.OnPicked_rose

        pas.SetWorkable(inst, nil, pas.OnFinished_rose, nil, 1)

        MakeNoGrowInWinter(inst) --冬季停止生长
        MakeLargeBurnable(inst)
        MakeMediumPropagator(inst)

        inst.legion_waxprefab = "rosebush"
        TOOLS_L.SetSprayWaxable(inst, nil, pas.Wax_bush)
    end
})

----------------
--[[ 蹄莲花丛 ]]
----------------

pas.SpawnLoot_lily = function(inst, picker, mustdrop)
    local sets
    local pos = inst:GetPosition()
    local rand = math.random()
    if math.random() < CONFIGS_LEGION.FLOWERWEAPONSCHANCE then --3%几率掉落剑
        pas.SpawnFlowerWeapon(inst, pos, picker, "lileaves")
    end
    if mustdrop then
        sets = { dropper = inst }
        picker = nil
    end
    if rand < 0.3 then --30%几率掉落1花瓣，60%几率掉落2花瓣，10%几率掉落蹄莲芽束
        TOOLS_L.SpawnStackDrop("petals", 1, pos, picker, nil, sets)
    elseif rand < 0.9 then
        TOOLS_L.SpawnStackDrop("petals", 2, pos, picker, nil, sets)
    else
        TOOLS_L.SpawnStackDrop("cutted_lilybush", 1, pos, nil, nil, { dropper = inst })
    end
    TOOLS_L.PushLuckyEvent(inst)
end
pas.OnPicked_lily = function(inst, picker)
    pas.OnPicked_bush(inst, picker)
    pas.SpawnLoot_lily(inst, picker, false)
end
pas.OnFinished_lily = function(inst, worker)
    if inst.components.pickable ~= nil then
        local pos = inst:GetPosition()
        local sets = { dropper = inst }
        local withered = inst.components.witherable ~= nil and inst.components.witherable:IsWithered()
        if withered or inst.components.pickable:IsBarren() then --枯萎时被挖起
            TOOLS_L.SpawnStackDrop("twigs", 2, pos, nil, nil, sets)
        else
            if inst.components.pickable:CanBePicked() then --有果实时被挖起
                TOOLS_L.SpawnStackDrop(inst.components.pickable.product, 1, pos, nil, nil, sets)
                pas.SpawnLoot_lily(inst, worker, true)
            end
            TOOLS_L.SpawnStackDrop("dug_lilybush", 1, pos, nil, nil, sets)
        end
    end
    inst:Remove()
end

pas.MakeBush({
    name = "lilybush",
    assets = {
        Asset("ANIM", "anim/berrybush2.zip"), --官方猪村浆果丛动画
        Asset("ANIM", "anim/lilybush.zip")
    },
    prefabs = { "petals_lily", "dug_lilybush", "lileaves", "twigs", "petals", "cutted_lilybush" },
    fn_common = function(inst)
        pas.SetDeploySmartRadius(inst, CONFIGS_LEGION.LILYBUSHSPACING or DEPLOYSPACING.MEDIUM)
        pas.Common_flowerbush(inst)
        LS_C_Init(inst, "lilybush", false)
    end,
    fn_server = function(inst)
        inst:AddComponent("witherable")

        inst.components.pickable:SetUp("petals_lily", TUNING.TOTAL_DAY_TIME*6)
        inst.components.pickable.getregentimefn = pas.GetRegenTime_bush
        inst.components.pickable.max_cycles = TUNING.BERRYBUSH_CYCLES + math.random(2)
        inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
        inst.components.pickable.onpickedfn = pas.OnPicked_lily

        pas.SetWorkable(inst, nil, pas.OnFinished_lily, nil, 1)

        MakeNoGrowInWinter(inst) --冬季停止生长
        MakeLargeBurnable(inst)
        MakeMediumPropagator(inst)

        inst.legion_waxprefab = "lilybush"
        TOOLS_L.SetSprayWaxable(inst, nil, pas.Wax_bush)
    end
})

----------------
--[[ 兰草花丛 ]]
----------------

pas.SpawnLoot_orchid = function(inst, picker, mustdrop)
    local sets
    local pos = inst:GetPosition()
    local rand = math.random()
    if math.random() < CONFIGS_LEGION.FLOWERWEAPONSCHANCE then --3%几率掉落剑
        pas.SpawnFlowerWeapon(inst, pos, picker, "orchitwigs")
    end
    if mustdrop then
        sets = { dropper = inst }
        picker = nil
    end
    if rand < 0.3 then --30%几率掉落花瓣，60%几率掉落干草，10%几率掉落兰草种籽
        TOOLS_L.SpawnStackDrop("petals", 1, pos, picker, nil, sets)
    elseif rand < 0.9 then
        TOOLS_L.SpawnStackDrop("cutgrass", 1, pos, picker, nil, sets)
    else
        TOOLS_L.SpawnStackDrop("cutted_orchidbush", 1, pos, nil, nil, { dropper = inst })
    end
    TOOLS_L.PushLuckyEvent(inst)
end
pas.OnPicked_orchid = function(inst, picker)
    pas.OnPicked_bush(inst, picker)
    pas.SpawnLoot_orchid(inst, picker, false)
end
pas.OnFinished_orchid = function(inst, worker)
    if inst.components.pickable ~= nil then
        local pos = inst:GetPosition()
        local sets = { dropper = inst }
        local withered = inst.components.witherable ~= nil and inst.components.witherable:IsWithered()
        if withered or inst.components.pickable:IsBarren() then --枯萎时被挖起
            TOOLS_L.SpawnStackDrop("cutgrass", 2, pos, nil, nil, sets)
        else
            if inst.components.pickable:CanBePicked() then --有果实时被挖起
                TOOLS_L.SpawnStackDrop(inst.components.pickable.product, 1, pos, nil, nil, sets)
                pas.SpawnLoot_orchid(inst, worker, true)
            end
            TOOLS_L.SpawnStackDrop("dug_orchidbush", 1, pos, nil, nil, sets)
        end
    end
    inst:Remove()
end

pas.MakeBush({
    name = "orchidbush",
    assets = {
        Asset("ANIM", "anim/berrybush2.zip"), --官方猪村浆果丛动画
        Asset("ANIM", "anim/orchidbush.zip")
    },
    prefabs = { "petals_orchid", "dug_orchidbush", "orchitwigs", "cutgrass", "petals", "cutted_orchidbush" },
    fn_common = function(inst)
        pas.SetDeploySmartRadius(inst, CONFIGS_LEGION.ORCHIDBUSHSPACING)
        pas.Common_flowerbush(inst)
        LS_C_Init(inst, "orchidbush", false)
    end,
    fn_server = function(inst)
        inst:AddComponent("witherable")

        inst.components.pickable:SetUp("petals_orchid", TUNING.TOTAL_DAY_TIME*6)
        inst.components.pickable.getregentimefn = pas.GetRegenTime_bush
        inst.components.pickable.max_cycles = TUNING.BERRYBUSH_CYCLES + math.random(2)
        inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
        inst.components.pickable.onpickedfn = pas.OnPicked_orchid

        pas.SetWorkable(inst, nil, pas.OnFinished_orchid, nil, 1)

        MakeNoGrowInWinter(inst) --冬季停止生长
        MakeMediumBurnable(inst)
        MakeSmallPropagator(inst)

        inst.legion_waxprefab = "orchidbush"
        TOOLS_L.SetSprayWaxable(inst, nil, pas.Wax_bush)
    end
})

----------------
--[[ 永不凋零花丛 ]]
----------------

pas.OnTransplant_never = function(inst)
    inst.components.pickable:MakeEmpty() --直接进入生长状态
end
pas.OnPicked_never = function(inst, picker)
    if picker and picker.prefab == "hermitcrab" then --螃蟹奶奶采集的，必需掉落，不然就被吃了
        pas.SpawnFlowerWeapon(inst, inst:GetPosition(), picker, "neverfade", nil)
    else
        pas.SpawnFlowerWeapon(inst, inst:GetPosition(), picker, "neverfade", true)
    end
    inst.AnimState:PlayAnimation("picked")
    pas.SetBerries_bush(inst, nil)
    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
end
pas.WaxRemove_never = function(inst, doer)
    pas.SpawnFlowerWeapon(inst, inst:GetPosition(), doer, "neverfade", nil, true) --得给把坏的剑
    inst:Remove()
end

pas.MakeBush({
    name = "neverfadebush",
    assets = {
        Asset("ANIM", "anim/berrybush2.zip"), --官方猪村浆果丛动画
        Asset("ANIM", "anim/neverfadebush.zip")
    },
    prefabs = { "neverfade", "petals" },
    fn_common = function(inst)
        -- MakeSmallObstaclePhysics(inst, .1)
        pas.SetDeploySmartRadius(inst, DEPLOYSPACING.MEDIUM)
        inst:SetPhysicsRadiusOverride(.5)
        inst:AddTag("flower")
        inst:AddTag("waxable_l")
        LS_C_Init(inst, "neverfadebush", false)
        inst.legiontag_nopost_pickable = true --永不凋零花丛不要做对pickable组件的修改
    end,
    fn_server = function(inst)
        inst.components.pickable:SetUp("petals", TUNING.TOTAL_DAY_TIME*3)
        inst.components.pickable.ontransplantfn = pas.OnTransplant_never
        inst.components.pickable.makebarrenfn = nil --它不能枯萎
        -- inst.components.pickable.max_cycles = TUNING.BERRYBUSH_CYCLES + math.random(2)
        -- inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
        inst.components.pickable.onpickedfn = pas.OnPicked_never

        inst.legion_waxprefab = "neverfadebush"
        inst.legionfn_waxremove = pas.WaxRemove_never
        TOOLS_L.SetSprayWaxable(inst, nil, pas.Wax_bush)
    end
})

----------------
--[[ 夜玫瑰花丛 ]]
----------------

pas.SpawnLoot_nightrose = function(inst, picker, mustdrop)
    local sets
    local pos = inst:GetPosition()
    local rand = math.random()
    if math.random() < CONFIGS_LEGION.FLOWERWEAPONSCHANCE then --3%几率掉落剑
        TOOLS_L.SpawnStackDrop("hat_whisperose", 1, pos, nil, nil, { dropper = inst })
    end
    if mustdrop then
        sets = { dropper = inst }
        picker = nil
    end
    if rand < 0.3 then --30%几率掉落树枝，65%几率掉落噩梦燃料，5%几率掉落夜玫瑰棘果
        TOOLS_L.SpawnStackDrop("twigs", 1, pos, picker, nil, sets)
    elseif rand < 0.95 then
        TOOLS_L.SpawnStackDrop("nightmarefuel", 1, pos, picker, nil, sets)
    else
        TOOLS_L.SpawnStackDrop("cutted_nightrosebush", 1, pos, nil, nil, { dropper = inst })
    end
    TOOLS_L.PushLuckyEvent(inst)
end
pas.OnPicked_nightrose = function(inst, picker)
    pas.OnPicked_bush(inst, picker)
    pas.SpawnLoot_nightrose(inst, picker, false)

    --采集时被刺伤
    --暗影仆从、倪克斯、盖娅、当前不会被影怪主动攻击的玩家、穿了荆棘甲的玩家 不会被刺伤
    if  picker and picker.components.combat ~= nil and
        not picker:HasAnyTag("shadowminion", "genesis_nyx", "genesis_gaia", "shadowdominance") and
        not (
            picker.components.inventory ~= nil and
            (   picker.components.inventory:EquipHasTag("bramble_resistant") or
                (CONFIGS_LEGION.ENABLEDMODS.MythWords and picker.components.inventory:Has("thorns_pill", 1))
            )
        )
    then
        picker.components.combat:GetAttacked(inst, 6)
        picker:PushEvent("thorns")
    end
end
pas.OnFinished_nightrose = function(inst, worker)
    if inst.components.pickable ~= nil then
        local pos = inst:GetPosition()
        local sets = { dropper = inst }
        local withered = inst.components.witherable ~= nil and inst.components.witherable:IsWithered()
        if withered or inst.components.pickable:IsBarren() then --枯萎时被挖起
            TOOLS_L.SpawnStackDrop("twigs", 2, pos, nil, nil, sets)
        else
            if inst.components.pickable:CanBePicked() then --有果实时被挖起
                TOOLS_L.SpawnStackDrop(inst.components.pickable.product, 1, pos, nil, nil, sets)
                pas.SpawnLoot_nightrose(inst, worker, true)
            end
            TOOLS_L.SpawnStackDrop("dug_nightrosebush", 1, pos, nil, nil, sets)
        end
    end
    inst:Remove()
end

pas.MakeBush({
    name = "nightrosebush",
    assets = {
        Asset("ANIM", "anim/berrybush2.zip"), --官方猪村浆果丛动画
        Asset("ANIM", "anim/nightrosebush.zip")
    },
    prefabs = { "petals_nightrose", "dug_nightrosebush", "hat_whisperose", "twigs", "nightmarefuel", "cutted_nightrosebush" },
    fn_common = function(inst)
        pas.SetDeploySmartRadius(inst, CONFIGS_LEGION.ROSEBUSHSPACING or DEPLOYSPACING.MEDIUM)
        pas.Common_flowerbush(inst)
        inst.AnimState:SetLightOverride(0.1)
        inst:AddTag("thorny") --多刺标签
        inst._fruitform = true
    end,
    fn_server = function(inst)
        inst:AddComponent("witherable")

        inst.components.pickable:SetUp("petals_nightrose", TUNING.TOTAL_DAY_TIME*6)
        inst.components.pickable.getregentimefn = pas.GetRegenTime_bush
        inst.components.pickable.max_cycles = TUNING.BERRYBUSH_CYCLES + math.random(2)
        inst.components.pickable.cycles_left = inst.components.pickable.max_cycles
        inst.components.pickable.onpickedfn = pas.OnPicked_nightrose

        pas.SetWorkable(inst, nil, pas.OnFinished_nightrose, nil, 1)

        -- MakeNoGrowInWinter(inst) --冬季停止生长
        MakeLargeBurnable(inst)
        MakeMediumPropagator(inst)

        inst.legion_waxprefab = "nightrosebush"
        TOOLS_L.SetSprayWaxable(inst, nil, pas.Wax_bush)
    end
})

--------------------------------------------------------------------------
--[[ 颤栗树相关 ]]
--------------------------------------------------------------------------

pas.prefabs_shyerry = { "shyerry", "shyerrytree1", "shyerrytree2", "shyerrytree3", "shyerrytree4" }
pas.notags_shyerryflower = TOOLS_L.TagsCombat1({
    "plantkin", "self_fertilizable", "buzzard", "shadow", "ghost", "abigail", "shadowminion", "structure", "genesis_gaia"
})
pas.fruitpoint_shy = 16
pas.scale_shy = 1.3

SetSharedLootTable("shyerrytree_large", {
    {"shyerrylog", 0.5}, {"log", 1}
})
SetSharedLootTable("shyerrytree_medium", {
    {"shyerrylog", 0.1}, {"log", 0.5}
})

pas.GetStatus_shyerry = function(inst)
    return (inst.components.burnable ~= nil and inst.components.burnable:IsBurning() and "BURNING") or nil
end
pas.Disappear_shyerry = function(inst, push)
    if inst:IsAsleep() then
        inst:Remove()
        return
    end
    if inst.isdead then
        return
    else
        inst.isdead = true
        inst.persists = false
    end
    RemovePhysicsColliders(inst)
    if push then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("wither", false)
    else
        inst.AnimState:PlayAnimation("wither", false)
    end
    inst:ListenForEvent("animover", function(inst)
        if inst.AnimState:AnimDone() then
            if inst.shytarget_l ~= nil then --颤栗花被角色吓跑后，角色就会说特殊台词
                local scare = inst.shytarget_l
                if
                    scare:IsValid() and scare.components.talker ~= nil and not scare:HasTag("playerghost") and
                    (scare.components.health == nil or not scare.components.health:IsDead())
                then
                    scare.components.talker:Say(GetString(scare, "DESCRIBE", { "SHYERRYFLOWER", "SHY" }))
                end
                inst.shytarget_l = nil
            end
            inst:Remove()
        end
    end)
end
pas.OnBurnt_shyerry = function(inst)
    inst.components.lootdropper:SpawnLootPrefab("charcoal")
    pas.Disappear_shyerry(inst)
end
pas.OnWorked_shyerry = function(inst, worker, workleft, numworks)
    if inst.isdead then return end
	TOOLS_L.PlayChopSound(inst, worker)
	inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)
end
pas.OnFinished_shyerry = function(inst, worker)
	if inst.isdead then return end
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
    -- TOOLS_L.PlayChopSound(inst, worker)
    inst.components.lootdropper:DropLoot()
    pas.Disappear_shyerry(inst)
end
pas.Wax_shyerry = function(inst, doer, waxitem, right)
    local dd = {}
    local prefab = inst.prefab
    if prefab == "shyerrytree4_s" or prefab == "shyerrytree3_s" or
        prefab == "shyerrytree2_s" or prefab == "shyerrytree1_s"
    then
        dd.small = true
    end
    dd.form = string.sub(inst.AnimState:GetBuild(), -1, -1)
    return TOOLS_L.WaxObject(inst, doer, waxitem, "shyerrytree_item_waxed", dd, nil)
end
pas.MakeShyerryTree = function(dd)
    table.insert(prefs, Prefab(dd.name, function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        pas.SetMiniMap(inst, "shyerrytree", -1)
        pas.SetDeploySmartRadius(inst, nil)
        MakeObstaclePhysics(inst, dd.physicrad)
        pas.SetAnim(inst, "bramble_core", dd.anim or dd.name, nil, true)
        pas.SetRotatable_com(inst)

        if dd.scale ~= nil then
            inst.Transform:SetScale(dd.scale, dd.scale, dd.scale)
        end

        inst:AddTag("shyerry")
        inst:AddTag("plant")
        -- inst:AddTag("tree") --不能有这个标签，会让农场书报错
        inst:AddTag("boulder") --使巨鹿、熊獾的移动能撞烂自己
        inst:AddTag("waxable_l")

        inst:SetPrefabNameOverride("shyerrytree")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.legionfn_wax = pas.Wax_shyerry

        local color = 0.5 + math.random()*0.5
        inst.AnimState:SetMultColour(color, color, color, 1)
        TOOLS_L.RandomAnimFrame(inst)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = pas.GetStatus_shyerry

        inst:AddComponent("savedrotation")

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable(dd.loot or "shyerrytree_medium")

        pas.SetWorkable(inst, pas.OnWorked_shyerry, pas.OnFinished_shyerry, "CHOP", dd.workleft)

        MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
        inst.components.burnable:SetFXLevel(5)
        inst.components.burnable:SetOnBurntFn(pas.OnBurnt_shyerry)
        MakeMediumPropagator(inst)

        MakeHauntableIgnite(inst)

        return inst
    end, {
        Asset("ANIM", "anim/"..(dd.anim or dd.name)..".zip"),
        Asset("ANIM", "anim/shyerrybush.zip")
    }, { "shyerrylog" }))
end

pas.MakeShyerryTree({ ------颤栗树
    name = "shyerrytree1", physicrad = 1, scale = nil, loot = "shyerrytree_large", workleft = 10
})
pas.MakeShyerryTree({
    name = "shyerrytree2", physicrad = 1, scale = nil, loot = "shyerrytree_large", workleft = 10
})
pas.MakeShyerryTree({
    name = "shyerrytree3", physicrad = 0.85, scale = nil, loot = "shyerrytree_large", workleft = 10
})
pas.MakeShyerryTree({
    name = "shyerrytree4", physicrad = 0.52, scale = nil, loot = "shyerrytree_large", workleft = 10
})
pas.MakeShyerryTree({
    name = "shyerrytree1_s", anim = "shyerrytree1", physicrad = 0.8, scale = 0.8, loot = nil, workleft = 6
})
pas.MakeShyerryTree({
    name = "shyerrytree2_s", anim = "shyerrytree2", physicrad = 0.8, scale = 0.8, loot = nil, workleft = 6
})
pas.MakeShyerryTree({
    name = "shyerrytree3_s", anim = "shyerrytree3", physicrad = 0.65, scale = 0.8, loot = nil, workleft = 6
})
pas.MakeShyerryTree({
    name = "shyerrytree4_s", anim = "shyerrytree4", physicrad = 0.4, scale = 0.8, loot = nil, workleft = 6
})

table.insert(prefs, Prefab("shyerrycore_treetop", function() ------颤栗树之心的顶部树梢动画
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddFollower()
    pas.SetAnim(inst, "bramble_core", "shyerrycore_treetop", nil, true)
    inst.Transform:SetTwoFaced()
    inst.AnimState:SetFinalOffset(-1)

    inst:AddComponent("highlightchild")

    inst:AddTag("FX")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    return inst
end, { Asset("ANIM", "anim/shyerrycore_treetop.zip"), Asset("ANIM", "anim/shyerrybush.zip") }, nil))

pas.GetStatus_shyerrycore = function(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        return "BURNING"
    end
    local cpt = inst.components.shyerrygrow
    if cpt.stage == 1 then
        return "WEAK"
    elseif cpt.stage >= cpt.stage_max then
        return "STRONG"
    else
        return "GROWING"
    end
end
pas.OnWorked_shyerrycore = function(inst, worker, workleft, numworks)
	inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle", true)
end
pas.OnFinished_shyerrycore = function(inst, worker)
    local pos = inst:GetPosition()
    local sets = { dropper = inst }
    TOOLS_L.SpawnStackDrop("shyerrycore_item", 1, pos, nil, nil, sets)
    local numwood = inst.components.shyerrygrow.stage
    if numwood > 1 then --1阶段太小了，不应该有特效和声音
        TOOLS_L.SpawnStackDrop("shyerrylog", numwood, pos, nil, nil, sets)
        inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
        local fx = SpawnPrefab(numwood >= 3 and "collapse_big" or "collapse_small")
        fx.Transform:SetPosition(pos:Get())
        fx:SetMaterial("wood")
    end
    inst:Remove()
end
pas.OnWorked_shyerrycore_f = function(inst, worker, workleft, numworks)
    pas.OnWorked_shyerrycore(inst, worker, workleft, numworks)
    if workleft > 0 then
        return
    end
    if inst._numfruit == nil or inst._numfruit <= 0 then --数据出错了才会运行这里
        pas.SetWorkable2(inst, pas.OnWorked_shyerrycore, pas.OnFinished_shyerrycore, nil, 6)
        return
    end
    local num = math.random(inst._numfruit)
    inst._numfruit = inst._numfruit - num
    TOOLS_L.SpawnStackDrop("shyerry", num, inst:GetPosition(), nil, nil, { dropper = inst, pos_y = 2 })
    local cpt = inst.components.shyerrygrow
    cpt:SetFruit(cpt.fruit - num*pas.fruitpoint_shy) --因为每16点为一个果实。而SetFruit()会触发workable组件的重置
end
pas.shyerrycoredata = {
    {   numline = 1, numlinetree = 2, fruitchance = 0.02,
        fn_stage = function(inst, cpt)
            inst.AnimState:ClearOverrideSymbol("stalk01")
            if inst.components.burnable ~= nil then
                inst.components.burnable:SetFXLevel(2) --火势大小，范围是1-6
            end
            inst.Physics:SetCapsule(0.4*pas.scale_shy, 2)
            pas.SetWorkable2(inst, pas.OnWorked_shyerrycore, pas.OnFinished_shyerrycore, nil, 2)
        end
    },
    {   numline = 2, numlinetree = 4, fruitchance = 0.03,
        fn_stage = function(inst, cpt)
            inst.AnimState:OverrideSymbol("stalk01", inst.AnimState:GetBuild(), "stalklvl2")
            if inst.components.burnable ~= nil then
                inst.components.burnable:SetFXLevel(3)
            end
            inst.Physics:SetCapsule(0.9*pas.scale_shy, 2)
            pas.SetWorkable2(inst, pas.OnWorked_shyerrycore, pas.OnFinished_shyerrycore, nil, 4)
        end
    },
    {   numline = 3, numlinetree = 6, fruitchance = 0.04, fruitmax = 3,
        fn_stage = function(inst, cpt)
            inst.AnimState:OverrideSymbol("stalk01", inst.AnimState:GetBuild(), "stalklvl30")
            if inst.components.burnable ~= nil then
                inst.components.burnable:SetFXLevel(4)
            end
            inst.Physics:SetCapsule(1.2*pas.scale_shy, 2)
            pas.SetWorkable2(inst, pas.OnWorked_shyerrycore, pas.OnFinished_shyerrycore, nil, 6)
        end,
        fn_fruit = function(inst, cpt, newnum)
            inst._numfruit = newnum
            inst.AnimState:OverrideSymbol("stalk01", inst.AnimState:GetBuild(), "stalklvl3"..tostring(newnum))
            if newnum <= 0 then
                pas.SetWorkable2(inst, pas.OnWorked_shyerrycore, pas.OnFinished_shyerrycore, nil, 6)
            else
                pas.SetWorkable2(inst, pas.OnWorked_shyerrycore_f, nil, "HAMMER", 2)
            end
        end
    }
}
pas.OnBurnt_shyerrycore = function(inst)
    local pos = inst:GetPosition()
    local sets = { dropper = inst }
    TOOLS_L.SpawnStackDrop("shyerrycore_item", 1, pos, nil, nil, sets)
    local numwood = inst.components.shyerrygrow.stage
    if numwood > 1 then
        TOOLS_L.SpawnStackDrop("charcoal", numwood, pos, nil, nil, sets)
        if inst._numfruit ~= nil and inst._numfruit > 0 then
            TOOLS_L.SpawnStackDrop("shyerry_cooked", inst._numfruit, pos, nil, nil, sets)
        end
    end
    inst:Remove()
end
pas.DealData_shyerrycore = function(inst, data)
    local dd = {
        gr = tostring(data.gr), grmax = tostring(data.grmax or 48),
        ft = tostring(data.ft), st = tostring(data.st or 3),
        n1 = tostring(data.n1 or 0), nmax = tostring(data.nmax or 500),
		n2 = tostring(data.n2 or 0),
		n3 = tostring(data.n3 or 0),
        mo = tostring(data.mo or 0), momax = tostring(data.momax or 500)
    }
    if data.con ~= nil then
        dd.con = tostring(data.con)
        return subfmt(STRINGS.NAMEDETAIL_L.SHYERRYCORE, dd)
    else
        return subfmt(STRINGS.NAMEDETAIL_L.SHYERRYCORE_PLANTED, dd)
    end
end
pas.GetData_shyerrycore = function(inst)
    local cpt = inst.components.shyerrygrow
    local data = { gr = cpt.growth, ft = cpt.fruit }
    if cpt.stage ~= 3 then
        data.st = cpt.stage
    end
    if cpt.growth_max ~= 48 then
        data.grmax = cpt.growth_max
    end
    if cpt.nutrient_max ~= 500 then
        data.nmax = cpt.nutrient_max
    end
    if cpt.nutrient1 ~= 0 then
		data.n1 = TOOLS_L.ODPoint(cpt.nutrient1, 10)
	end
	if cpt.nutrient2 ~= 0 then
		data.n2 = TOOLS_L.ODPoint(cpt.nutrient2, 10)
	end
	if cpt.nutrient3 ~= 0 then
		data.n3 = TOOLS_L.ODPoint(cpt.nutrient3, 10)
	end
    if cpt.moisture_max ~= 500 then
        data.momax = cpt.moisture_max
    end
    if cpt.moisture ~= 0 then
		data.mo = TOOLS_L.ODPoint(cpt.moisture, 10)
	end
    if inst.num_conquest_l ~= nil then
        data.con = inst.num_conquest_l
    end
    return data
end
pas.Wax_shyerrycore = function(inst, doer, waxitem, right)
    local dd = { isboss = inst.num_conquest_l ~= nil, stage = tostring(inst.components.shyerrygrow.stage) }
    if dd.stage == "3" and inst._numfruit ~= nil and inst._numfruit > 0 then
        dd.fruit = tostring(inst._numfruit)
    end
    return TOOLS_L.WaxObject(inst, doer, waxitem, "shyerrycore_item_waxed", dd, nil)
end
table.insert(prefs, Prefab("shyerrycore_planted", function() ------不正常的颤栗树之心
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    pas.SetMiniMap(inst, "shyerrycore_planted", 5)
    pas.SetDeploySmartRadius(inst, DEPLOYSPACING.PLACER_DEFAULT)
    MakeObstaclePhysics(inst, 2)
    pas.SetAnim(inst, "bramble_core", "shyerrycore_planted", nil, true)
    pas.SetRotatable_com(inst)
    inst.Transform:SetScale(pas.scale_shy, pas.scale_shy, pas.scale_shy)

    inst:AddTag("shyerry")
    inst:AddTag("plant")
    inst:AddTag("waxable_l")

    TOOLS_L.InitMouseInfo(inst, pas.DealData_shyerrycore, pas.GetData_shyerrycore, 3)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    -- inst._numfruit = 0
    inst.legionfn_wax = pas.Wax_shyerrycore

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = pas.GetStatus_shyerrycore

    inst:AddComponent("lootdropper")

    inst:AddComponent("savedrotation")

    inst:AddComponent("workable")

    MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
    inst.components.burnable:SetOnBurntFn(pas.OnBurnt_shyerrycore)
    MakeMediumPropagator(inst)

    MakeHauntableIgnite(inst)

    inst:AddComponent("shyerrygrow")
    inst.components.shyerrygrow:SetUp(pas.shyerrycoredata)

    TOOLS_L.RandomAnimFrame(inst)

    return inst
end, { Asset("ANIM", "anim/shyerrycore_planted.zip"), Asset("ANIM", "anim/shyerrybush.zip") }, pas.prefabs_shyerry))

pas.CheckTreeTop = function(inst)
    if inst._treetop == nil or not inst._treetop:IsValid() then
        local fx = SpawnPrefab("shyerrycore_treetop")
        -- fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx.entity:SetParent(inst.entity)
        -- fx.Follower:FollowSymbol(
        --     inst.GUID, fxdata.symbol, --TIP: 跟随通道时，默认跟随通道文件夹里ID=0的
        --     0, 0, 0
        -- )
        fx.components.highlightchild:SetOwner(inst)
        inst._treetop = fx
    end
end
pas.SameAnimTreeTop = function(inst)
    inst.AnimState:PlayAnimation("idle", true)
    inst._treetop.AnimState:PlayAnimation("idle", true)

    local fm = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
    inst.AnimState:SetFrame(fm)
    inst._treetop.AnimState:SetFrame(fm)
end
pas.OnWorked_shyerrycore2_f = function(inst, worker, workleft, numworks)
    pas.OnWorked_shyerrycore(inst, worker, workleft, numworks)
    if inst._treetop ~= nil then
        inst._treetop.AnimState:PlayAnimation("hit")
        inst._treetop.AnimState:PushAnimation("idle", true)
    end
    if workleft > 0 then
        return
    end
    inst.components.workable.workleft = 3
    if inst._numfruit == nil or inst._numfruit <= 0 then --数据出错了才会运行这里
        inst.components.workable:SetWorkable(false)
        return
    end
    local num = math.random(inst._numfruit)
    inst._numfruit = inst._numfruit - num
    TOOLS_L.SpawnStackDrop("shyerry", num, inst:GetPosition(), nil, nil, { dropper = inst, pos_y = 2 })
    local cpt = inst.components.shyerrygrow
    cpt:SetFruit(cpt.fruit - num*pas.fruitpoint_shy) --因为每16点为一个果实。而SetFruit()会触发workable组件的重置
end
pas.shyerrycoredata2 = {
    {   numline = 3, numlinetree = 5, fruitchance = 0.02,
        fn_stage = function(inst, cpt)
            inst.AnimState:ClearOverrideSymbol("stalk01")
            if inst._treetop ~= nil then
                inst._treetop:Remove()
                inst._treetop = nil
            end
            TOOLS_L.RandomAnimFrame(inst)
            if inst.components.burnable ~= nil then
                inst.components.burnable:SetFXLevel(2) --火势大小，范围是1-6
            end
            inst.Physics:SetCapsule(0.6*pas.scale_shy, 2)
            inst.components.workable:SetWorkable(false)
        end
    },
    {   numline = 4, numlinetree = 10, fruitchance = 0.03,
        fn_stage = function(inst, cpt)
            inst.AnimState:OverrideSymbol("stalk01", inst.AnimState:GetBuild(), "stalklvl2")
            pas.CheckTreeTop(inst)
            inst._treetop.AnimState:ClearOverrideSymbol("bulb01")
            pas.SameAnimTreeTop(inst)
            if inst.components.burnable ~= nil then
                inst.components.burnable:SetFXLevel(4)
            end
            inst.Physics:SetCapsule(1.4*pas.scale_shy, 2)
            inst.components.workable:SetWorkable(false)
        end
    },
    {   numline = 6, numlinetree = 15, fruitchance = 0.04, fruitmax = 6,
        fn_stage = function(inst, cpt)
            inst.AnimState:OverrideSymbol("stalk01", inst.AnimState:GetBuild(), "stalklvl3")
            pas.CheckTreeTop(inst)
            inst._treetop.AnimState:OverrideSymbol("bulb01", inst._treetop.AnimState:GetBuild(), "treetop30")
            pas.SameAnimTreeTop(inst)
            if inst.components.burnable ~= nil then
                inst.components.burnable:SetFXLevel(5)
            end
            inst.Physics:SetCapsule(1.8*pas.scale_shy, 2)
            inst.components.workable:SetWorkable(false)
        end,
        fn_fruit = function(inst, cpt, newnum)
            inst._numfruit = newnum
            if inst._treetop ~= nil then
                inst._treetop.AnimState:OverrideSymbol("bulb01",
                    inst._treetop.AnimState:GetBuild(), "treetop3"..tostring(newnum))
            end
            if newnum <= 0 then
                inst.components.workable:SetWorkable(false)
            else
                pas.SetWorkable2(inst, pas.OnWorked_shyerrycore2_f, nil, "HAMMER", 3)
            end
        end
    }
}
pas.OnBurnt_shyerrycore2 = function(inst)
    local cpt = inst.components.shyerrygrow
    if inst._numfruit ~= nil and inst._numfruit > 0 then --优先烧掉果实
        local lost
        if inst._numfruit >= 3 then
            lost = 3
            inst._numfruit = inst._numfruit - 3
        else
            lost = inst._numfruit
            inst._numfruit = nil
        end
        TOOLS_L.SpawnStackDrop("shyerry_cooked", lost, inst:GetPosition(), nil, nil, { dropper = inst, pos_y = 2 })
        cpt:SetFruit(cpt.fruit - lost*pas.fruitpoint_shy)
    elseif cpt.growth > 0 then --其次是烧掉生长进度
        if cpt.growth >= 8 then
            cpt.growth = cpt.growth - 8
            TOOLS_L.SpawnStackDrop("charcoal", 2, inst:GetPosition(), nil, nil, { dropper = inst, pos_y = 2 })
        else
            cpt.growth = 0
            TOOLS_L.SpawnStackDrop("ash", 1, inst:GetPosition(), nil, nil, { dropper = inst, pos_y = 2 })
        end
    end
end
pas.OnSave_shyerrycore2 = function(inst, data)
    if inst.num_conquest_l > 0 then
        data.num_conquest_l = inst.num_conquest_l
    end
end
pas.OnLoad_shyerrycore2 = function(inst, data, newents)
    if data ~= nil then
        if data.num_conquest_l ~= nil then
            inst.num_conquest_l = data.num_conquest_l
        end
    end
end
table.insert(prefs, Prefab("shyerrycore", function() ------颤栗树之心
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    pas.SetMiniMap(inst, "shyerrycore", 5)
    pas.SetDeploySmartRadius(inst, DEPLOYSPACING.PLACER_DEFAULT)
    MakeObstaclePhysics(inst, 2)
    pas.SetAnim(inst, "bramble_core", "shyerrycore", nil, true)
    pas.SetRotatable_com(inst)
    inst.Transform:SetScale(pas.scale_shy, pas.scale_shy, pas.scale_shy)

    inst:AddTag("shyerry")
    inst:AddTag("plant")
    inst:AddTag("waxable_l")
    inst:AddTag("irreplaceable") --该标签能使其不会被新地形(比如洞穴中庭触手)给强制删除

    TOOLS_L.InitMouseInfo(inst, pas.DealData_shyerrycore, pas.GetData_shyerrycore, 3)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    -- inst._numfruit = 0
    -- inst._treetop = nil
    inst.num_conquest_l = 0 --征服次数
    inst.legionfn_wax = pas.Wax_shyerrycore

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = pas.GetStatus_shyerrycore

    inst:AddComponent("lootdropper")

    inst:AddComponent("savedrotation")

    inst:AddComponent("workable")

    MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
    inst.components.burnable:SetOnBurntFn(pas.OnBurnt_shyerrycore2)
    MakeLargePropagator(inst)

    MakeHauntableIgnite(inst)

    inst:AddComponent("shyerrygrow")
    inst.components.shyerrygrow.growth_max = 80
    inst.components.shyerrygrow.moisture_max = 1000
    inst.components.shyerrygrow.nutrient_max = 1000
    inst.components.shyerrygrow:SetUp(pas.shyerrycoredata2)

    inst.OnSave = pas.OnSave_shyerrycore2
    inst.OnLoad = pas.OnLoad_shyerrycore2

    return inst
end, { Asset("ANIM", "anim/shyerrycore.zip"), Asset("ANIM", "anim/shyerrybush.zip") }, pas.prefabs_shyerry))

pas.NoShy_shyerryflower = function(inst)
    if inst.task_shy ~= nil then
        inst.task_shy:Cancel()
        inst.task_shy = nil
    end
end
pas.TryShy_shyerryflower = function(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 10, { "scarytoprey" }, pas.notags_shyerryflower)
    for _, v in ipairs(ents) do
        if v ~= inst and v.entity:IsVisible() and v.legiontag_fragrantbody == nil then
            if inst.components.pickable ~= nil then
                inst.components.pickable.caninteractwith = false
            end
            if v:HasTag("player") then
                inst.shytarget_l = v
            end
            pas.NoShy_shyerryflower(inst)
            pas.Disappear_shyerry(inst)
            return
        end
    end
end
pas.BeShy_shyerryflower = function(inst)
    if inst.task_shy == nil then
        inst.task_shy = inst:DoPeriodicTask(1.5, pas.TryShy_shyerryflower, 0.5+5*math.random())
    end
end
pas.OnPicked_shyerryflower = function(inst, picker, lootbase)
    pas.NoShy_shyerryflower(inst)
    pas.Disappear_shyerry(inst, true)
end
pas.OnHaunt_shyerryflower = function(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
        if math.random() <= 0.33 then
            if inst.components.pickable ~= nil then
                inst.components.pickable.caninteractwith = false --已经要掉落果实了，不再能采集
                if inst.components.pickable.product ~= nil then
                    inst.components.lootdropper:SpawnLootPrefab(inst.components.pickable.product)
                end
            end
            pas.Disappear_shyerry(inst, true)
        else
            inst.AnimState:PlayAnimation("hit")
            inst.AnimState:PushAnimation("idle", true)
        end
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_COOLDOWN_TINY
        return true
    end
    return false
end
pas.OnBurnt_shyerryflower = function(inst)
    if inst.components.pickable ~= nil then
        inst.components.pickable.caninteractwith = false
    end
    inst.components.lootdropper:SpawnLootPrefab("shyerry_cooked")
    pas.NoShy_shyerryflower(inst)
    pas.Disappear_shyerry(inst)
end
pas.Wax_shyerryflower = function(inst, doer, waxitem, right)
    return TOOLS_L.WaxObject(inst, doer, waxitem, "shyerryflower_item_waxed", {}, nil)
end
table.insert(prefs, Prefab("shyerryflower", function() ------颤栗花
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    pas.SetDeploySmartRadius(inst, nil)
    MakeSmallObstaclePhysics(inst, .1)

    pas.SetAnim(inst, "bramble_core", "shyerrybush", nil, true)
    pas.SetRotatable_com(inst)
    inst.Transform:SetScale(0.6, 0.6, 0.6)

    inst:AddTag("shyerry")
    inst:AddTag("plant")
    inst:AddTag("waxable_l")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.legiontag_nopost_pickable = true --颤栗花不要做对pickable组件的修改
    inst.legionfn_wax = pas.Wax_shyerryflower

    TOOLS_L.RandomAnimFrame(inst)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = pas.GetStatus_shyerry

    inst:AddComponent("lootdropper")

    inst:AddComponent("savedrotation")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/harvest_berries"
    inst.components.pickable:SetUp("shyerry", 10)
    inst.components.pickable.onpickedfn = pas.OnPicked_shyerryflower

    MakeHauntableIgnite(inst)
    AddHauntableCustomReaction(inst, pas.OnHaunt_shyerryflower, false, false, true)

    MakeMediumBurnable(inst)
    inst.components.burnable:SetFXLevel(5)
    inst.components.burnable:SetOnBurntFn(pas.OnBurnt_shyerryflower)
    MakeLargePropagator(inst)

    inst.OnEntitySleep = pas.NoShy_shyerryflower
    inst.OnEntityWake = pas.BeShy_shyerryflower

    return inst
end, {
    Asset("ANIM", "anim/shyerrybush.zip")
    -- Asset("ANIM", "anim/bramble_core.zip") --荆棘花的动画模板
}, { "shyerry", "shyerry_cooked" }))

----兼容以前的代码

pas.MakeOldPrefab = function(name, newprefab)
    table.insert(prefs, Prefab(name, function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst:DoTaskInTime(1+math.random(), function(inst)
            local tree = SpawnPrefab(newprefab)
            if tree ~= nil then
                tree.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            inst:Remove()
        end)

        return inst
    end, nil, nil))
end
pas.MakeOldPrefab("shyerrymanager", "shyerrycore")
pas.MakeOldPrefab("shyerrytree1_planted", "shyerrycore_planted")
pas.MakeOldPrefab("shyerrytree3_planted", "shyerrycore_planted")

--------------------------------------------------------------------------
--[[ 耐酸蕨类 ]]
--------------------------------------------------------------------------

pas.Wax_randomanim = function(inst, doer, waxitem, right)
    return TOOLS_L.WaxObject(inst, doer, waxitem, inst.prefab.."_item_waxed",
            { form = tostring(inst.components.randomanimlegion.type2 or 1) }, nil)
end

pas.Redetailed_fern = function(inst, brush, mode, doer)
    local cpt = inst.components.randomanimlegion
    if mode == 1 then --完全随机
        cpt.type2 = TOOLS_L.GetExceptRandomNumber(1, 5, cpt.type2)
    else --顺序
        cpt.type2 = TOOLS_L.GetNextCycleNumber(1, 5, cpt.type2)
    end
    cpt:SetAnim(nil, nil)
    return false, { scale = 0.7 }
end
table.insert(prefs, Prefab("fern_l", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.AnimState:SetBank("fern_l")
    inst.AnimState:SetBuild("fern_l")
    pas.SetRotatable_com(inst)
    inst:AddTag("NOBLOCK")
    inst:AddTag("waxable_l")
    -- inst:AddTag("plant") --按官方设定来看，蕨类不算是植物

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.legiontag_nopost_pickable = true --不要做对pickable组件的修改
    inst.legionfn_wax = pas.Wax_randomanim
    inst.legionfn_redetailed = pas.Redetailed_fern

    inst:AddComponent("inspectable")
    inst:AddComponent("savedrotation")

    inst:AddComponent("randomanimlegion")
    inst.components.randomanimlegion:SetAnim(nil, 5)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("foliage", 10)
	inst.components.pickable.remove_when_picked = true
    inst.components.pickable.quickpick = true

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)

    return inst
end, { Asset("ANIM", "anim/fern_l.zip") }, nil))

--------------------------------------------------------------------------
--[[ 冰皂草 ]]
--------------------------------------------------------------------------

pas.Redetailed_icelegume = function(inst, brush, mode, doer)
    local cpt = inst.components.randomanimlegion
    if mode == 1 then --完全随机
        cpt.type2 = TOOLS_L.GetExceptRandomNumber(1, 9, cpt.type2)
    else --顺序
        cpt.type2 = TOOLS_L.GetNextCycleNumber(1, 9, cpt.type2)
    end
    cpt:SetAnim(nil, nil)
    return false, { scale = 0.7 }
end
table.insert(prefs, Prefab("icelegume_l", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.AnimState:SetBank("icelegume_l")
    inst.AnimState:SetBuild("pot_whitewood2")
    pas.SetRotatable_com(inst)
    inst:AddTag("NOBLOCK")
    inst:AddTag("waxable_l")
    -- inst:AddTag("plant") --不加这个，官方这种采集消失的果实植物貌似都没加

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.legiontag_nopost_pickable = true --不要做对pickable组件的修改
    inst.legionfn_wax = pas.Wax_randomanim
    inst.legionfn_redetailed = pas.Redetailed_icelegume

    inst:AddComponent("inspectable")
    inst:AddComponent("savedrotation")

    inst:AddComponent("randomanimlegion")
    inst.components.randomanimlegion:SetAnim(nil, 9)

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("bean_l_ice", 10)
	inst.components.pickable.remove_when_picked = true
    inst.components.pickable.quickpick = true

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableIgnite(inst)

    return inst
end, { Asset("ANIM", "anim/icelegume_l.zip"), Asset("ANIM", "anim/pot_whitewood2.zip") }, nil))

--------------------------------------------------------------------------
--[[ 打蜡后的植物 ]]
--------------------------------------------------------------------------

paw.DISAPPEAR_TIME = 2
paw.DISAPPEAR_COLOR_MULT = 1.2
paw.waxstrkeys = {
    pot_ww = { "fruitname", "stage", "animkey", "barren", "skin" },
    xeed = { "stage", "lvl", "state", "form", "skin" },
    shyerrytree = { "form", "small" },
    shyerrycore = { "isboss", "stage", "fruit" },
    worldsword = { "state" }, --因为客户端不需要皮肤信息，所以皮肤数据不需要传输过去
    monstrain = { "state", "skin" },
    flowerbush = { "state", "form", "skin" },
    sivthetree = { "state" },
    sivderivant = { "stage", "form", "skin" },
    icire_rock = { "state" }, --客户端不需要皮肤数据
    form = { "form" }
    -- xx = { "", "", "", "" },
}

paw.Disappear_wax = function(inst, worker) --直接用的官方的逻辑。详见 prefabs\waxed_plant_common.lua 的 Disappear()
    local ticktime = TheSim:GetTickTime()

    inst.persists = false
    -- RemovePhysicsColliders(inst)
    if inst.DynamicShadow ~= nil then
        inst.DynamicShadow:Enable(false)
    end
    inst.SoundEmitter:PlaySound("qol1/wax_spray/fade")

    if inst.components.workable:GetWorkAction() == ACTIONS.CHOP then
        TOOLS_L.PlayChopSound(inst, worker)
    end

    local multcolor = inst.AnimState:GetMultColour()
    inst:StartThread(function()
        local ticks = 0
        while ticks * ticktime < paw.DISAPPEAR_TIME do
            local n = ticks * ticktime / paw.DISAPPEAR_TIME

            local alpha = easing.inQuad(1 - n, 0, 1, 1)
            local color = 1 - (n * paw.DISAPPEAR_COLOR_MULT)

            local color = math.min(multcolor, color)

            inst.AnimState:SetErosionParams(0.2, 0.2, n)
            inst.AnimState:SetMultColour(color, color, color, alpha)

            if inst.children ~= nil then
                for child, _ in pairs(inst.children) do
                    if child.AnimState ~= nil then
                        child.AnimState:SetErosionParams(0.2, 0.2, n)
                        child.AnimState:SetMultColour(color, color, color, alpha)
                    end
                end
            end

            ticks = ticks + 1
            Yield()
        end

        inst:Remove()
    end)
end
paw.OnFinished_wax = function(inst, worker)
    if inst.dug_prefab ~= nil then
        local item = inst.components.lootdropper:SpawnLootPrefab(FunctionOrValue(inst.dug_prefab, inst))
        if item then
            TOOLS_L.InheritWaxed(inst, item)
        end
        inst:Remove()
    else
        paw.Disappear_wax(inst, worker)
    end
end
paw.OnWaxClient = function(inst)
    local str = inst._waxstr_l:value() or ""
    local dd = {}
    local newdd = {}
    if #str > 0 then
        local splits = string.split(str, "&")
        for i, v in ipairs(inst._waxstrkey) do
            if splits[i] ~= nil and splits[i] ~= "?" then --?代表是空值、空字符串、false
                if splits[i] == "!" then --!代表true
                    dd[v] = true
                else
                    dd[v] = splits[i]
                end
            end
        end
    end
    if dd.skin ~= nil and dd.skin ~= "" then
        newdd.skin = dd.skin
    end
    if TheNet:GetIsClient() then inst._dd_wax_c = newdd end --只有单纯的客户端才需要这个数据
    return dd, newdd
end
paw.InitNet_wax = function(inst, strkey, strfn) --基础
    inst._waxstr_l = net_string(inst.GUID, "obj_waxstr_l._waxstr_l", "str_wl_dirty")
    inst._waxstr_l:set_local("")
    inst._waxstrkey = paw.waxstrkeys[strkey]
    if strfn ~= nil and not TheNet:IsDedicated() then
        inst:ListenForEvent("str_wl_dirty", strfn)
    end
end
paw.OnSave_wax = function(inst, data)
    if inst._dd_wax ~= nil then
        local dd_wax = {}
        for k, v in pairs(inst._dd_wax) do
            dd_wax[k] = v
        end
        if inst.components.skinedlegion ~= nil then --自动保存当前皮肤数据
            dd_wax.skin = inst.components.skinedlegion.skin
            dd_wax.userid = inst.components.skinedlegion.userid
        end
        data.dd_wax = dd_wax
    end
end
paw.OnLoad_wax = function(inst, data)
    if data ~= nil and data.dd_wax ~= nil then
        if inst.fn_dowax ~= nil then
            inst.fn_dowax(inst, data.dd_wax)
        else
            inst._dd_wax = data.dd_wax
        end
    end
end
paw.DoWax = function(inst, dd)
    inst._dd_wax = dd
    if inst._waxstr_l ~= nil and inst._waxstrkey ~= nil then
        local netstr = {}
        for i, v in ipairs(inst._waxstrkey) do
            if dd[v] == nil or dd[v] == false or dd[v] == "" then
                netstr[i] = "?"
            elseif dd[v] == true then
                netstr[i] = "!"
            else
                netstr[i] = dd[v]
            end
        end
        inst._waxstr_l:set(table.concat(netstr, "&"))
    end
end
paw.OnDeploy_wax = function(inst, pt, deployer, rot, dd)
    local plant = SpawnPrefab(dd.prefab)
    if plant == nil then
        return
    end
    TOOLS_L.InheritWaxed(inst, plant)
    plant.Transform:SetPosition(pt:Get())

    if inst.components.stackable ~= nil then
        inst.components.stackable:Get():Remove()
    else
        inst:Remove()
    end
    if deployer ~= nil and deployer.SoundEmitter ~= nil then
        deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
    end
end

paw.Decor_owner = function(inst, furniture) --官方的代码很有兼容性，不用担心特效位置不对
    if inst._onownerchange ~= nil then
        inst._onownerchange(inst)
    end
end
paw.SetFurnitureDecor_comm = function(inst) --装饰组件前置
    inst.entity:AddFollower() --能当装饰品需要这个
    inst:AddTag("furnituredecor") --能当装饰品
end
paw.SetFurnitureDecor_serv = function(inst, ondecor) --装饰组件
    inst:AddComponent("furnituredecor")
    if ondecor ~= nil then
        inst.components.furnituredecor.onputonfurniture = ondecor
    end
end

paw.MakeWaxedPlant = function(dd)
    table.insert(prefs, Prefab(dd.name.."_waxed", function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        inst:SetDeploySmartRadius(0.25)
        if dd.dug_prefab ~= nil then
            inst:AddTag("waxable_l")
        end
        if dd.fn_redetailed ~= nil then
            inst.legiontag_redetailable = true
        end
        if dd.twoface then
            pas.SetRotatable_com(inst)
        end
        if dd.fn_common ~= nil then
            dd.fn_common(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst._dd_wax = {}

        inst:AddComponent("inspectable")
        inst.components.inspectable:SetNameOverride("waxed_plant")

        pas.SetWorkable(inst, nil, paw.OnFinished_wax, dd.action, 1)

        if dd.twoface then
            inst:AddComponent("savedrotation")
        end

        if dd.dug_prefab ~= nil then
            inst.dug_prefab = dd.dug_prefab
            inst:AddComponent("lootdropper")
        end

        MakeHauntable(inst)

        inst.OnSave = paw.OnSave_wax
        inst.OnLoad = paw.OnLoad_wax

        if dd.snow then
            TOOLS_L.MakeSnowCovered_serv(inst)
        end
        if dd.fn_dowax ~= nil then
            inst.fn_dowax = dd.fn_dowax
        end
        if dd.fn_redetailed ~= nil then
            inst.legionfn_redetailed = dd.fn_redetailed
        end
        if dd.fn_server ~= nil then
            dd.fn_server(inst)
        end

        return inst
    end, nil, nil))
end
paw.MakeWaxedItem = function(dd)
    table.insert(prefs, Prefab(dd.name.."_item_waxed", function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        if dd.float ~= nil then
            pas.SetFloatable(inst, dd.float)
        end
        inst.pickupsound = "vegetation_firm"

        if dd.fn_deploy ~= nil then
            inst.overridedeployplacername = "waxedobject_l_placer"
        end
        inst:AddTag("waxable_l")
        inst:AddTag("NORATCHECK") --mod兼容：永不妥协。该道具不算鼠潮分

        if dd.fn_dowax_placer ~= nil then
            inst.fn_dowax_placer = dd.fn_dowax_placer
        end
        if dd.fn_common ~= nil then
            dd.fn_common(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst._dd_wax = {}
        inst.fn_dowax = paw.DoWax

        inst:AddComponent("inspectable")
        inst.components.inspectable:SetNameOverride("waxed_plant")

        if dd.fn_deploy ~= nil then
            pas.SetDeployable(inst, dd.fn_deploy, nil, DEPLOYSPACING.NONE) --DEPLOYSPACING.NONE。无距离限制
        end

        pas.SetFuel(inst, nil)
        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)
        MakeHauntableLaunch(inst)

        inst.OnSave = paw.OnSave_wax
        inst.OnLoad = paw.OnLoad_wax

        if dd.fn_server ~= nil then
            dd.fn_server(inst)
        end

        return inst
    end, nil, nil))
end

----------

paw.OnWaxClient_form = function(inst)
    local dd, newdd = paw.OnWaxClient(inst)
    newdd.form = dd.form or "1"
    inst.legion_namedetail = STRINGS.NAMEDETAIL_L.FORM..newdd.form
end
paw.DoWax_form = function(inst, dd)
    paw.DoWax(inst, dd)
    if dd.form ~= nil then
        inst.AnimState:PlayAnimation("idle"..dd.form)
    end
    dd.frame = nil
    dd.multcolor = nil
end

paw.MakeWaxedPlant({ ------冰皂草
    name = "icelegume_l", dug_prefab = "icelegume_l_item_waxed", twoface = true,
    fn_common = function(inst)
        paw.InitNet_wax(inst, "form", paw.OnWaxClient_form)
        pas.SetAnim(inst, "icelegume_l", "pot_whitewood2", "idle1", nil)
    end,
    fn_dowax = paw.DoWax_form,
    fn_redetailed = function(inst, brush, mode, doer)
        local form = tonumber(inst._dd_wax.form or 1)
        if type(form) ~= "number" then form = 1 end
        if mode == 1 then --完全随机
            form = TOOLS_L.GetExceptRandomNumber(1, 9, form)
        else --顺序
            form = TOOLS_L.GetNextCycleNumber(1, 9, form)
        end
        inst._dd_wax.form = tostring(form)
        paw.DoWax_form(inst, inst._dd_wax)
        return false, { scale = 0.7 }
    end
})
paw.MakeWaxedItem({ ------冰皂草(物品)
    name = "icelegume_l", float = { nil, "small", 0.15, 1.1 },
    fn_common = function(inst)
        paw.InitNet_wax(inst, "form", paw.OnWaxClient_form)
        pas.SetAnim(inst, "bean_l_ice", nil, nil, nil)
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "bean_l_ice")
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "icelegume_l_waxed" })
    end,
    fn_dowax_placer = function(item, builder, recipe, placer)
        local dd = item._dd_wax_c or item._dd_wax or {} --只在无洞穴本地档时才有 _dd_wax 数据
        placer.AnimState:SetBank("icelegume_l")
        placer.AnimState:SetBuild("pot_whitewood2")
        placer.AnimState:SetPercent("idle"..(dd.form or "1"), 0)
        placer.Transform:SetTwoFaced() --为了让种植预览和种植后的动画旋转角度保持一致
    end
})

paw.MakeWaxedPlant({ ------耐酸蕨类
    name = "fern_l", dug_prefab = "fern_l_item_waxed", twoface = true,
    fn_common = function(inst)
        paw.InitNet_wax(inst, "form", paw.OnWaxClient_form)
        pas.SetAnim(inst, "fern_l", nil, "idle1", nil)
    end,
    fn_dowax = paw.DoWax_form,
    fn_redetailed = function(inst, brush, mode, doer)
        local form = tonumber(inst._dd_wax.form or 1)
        if type(form) ~= "number" then form = 1 end
        if mode == 1 then --完全随机
            form = TOOLS_L.GetExceptRandomNumber(1, 5, form)
        else --顺序
            form = TOOLS_L.GetNextCycleNumber(1, 5, form)
        end
        inst._dd_wax.form = tostring(form)
        paw.DoWax_form(inst, inst._dd_wax)
        return false, { scale = 0.7 }
    end
})
paw.MakeWaxedItem({ ------耐酸蕨类(物品)
    name = "fern_l", float = { nil, "med", 0.2, 0.8 },
    fn_common = function(inst)
        paw.InitNet_wax(inst, "form", paw.OnWaxClient_form)
        pas.SetAnim(inst, "foliage", nil, "cooked", nil)
    end,
    fn_server = function(inst)
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = "quagmire_foliage_cooked" --用官方贴图的话，写法稍有不同
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "fern_l_waxed" })
    end,
    fn_dowax_placer = function(item, builder, recipe, placer)
        local dd = item._dd_wax_c or item._dd_wax or {} --只在无洞穴本地档时才有 _dd_wax 数据
        placer.AnimState:SetBank("fern_l")
        placer.AnimState:SetBuild("fern_l")
        placer.AnimState:SetPercent("idle"..(dd.form or "1"), 0)
        placer.Transform:SetTwoFaced() --为了让种植预览和种植后的动画旋转角度保持一致
    end
})

paw.potanimbuilds = {
    wormlight_lesser = "pot_whitewood2", wormlight = "pot_whitewood2", cutlichen = "pot_whitewood2",
    bean_l_ice = "pot_whitewood2"
}
paw.OnWaxClient_pot_ww = function(inst)
    local dd, newdd = paw.OnWaxClient(inst)
    local spa = STRINGS.NAMEDETAIL_L.SPACE
    local str
    newdd.barren = dd.barren
    if dd.fruitname == nil then --未种植
        str = STRINGS.NAMEDETAIL_L.UNPLANTED
    else
        newdd.fruitname = dd.fruitname
        newdd.stage = dd.stage or "0"
        newdd.animkey = dd.animkey or "1"
        str = (STRINGS.NAMES[string.upper(dd.fruitname)] or STRINGS.NAMES.UNKNOWN)..spa..STRINGS.NAMEDETAIL_L.STAGE
            ..tostring(tonumber(newdd.stage)+1).."/5"..spa..STRINGS.NAMEDETAIL_L.FORM..newdd.animkey
    end
    if newdd.barren then --贫瘠
        inst.legion_namedetail = str..spa..STRINGS.NAMEDETAIL_L.BARREN
    else
        inst.legion_namedetail = str
    end
end
paw.Init_pot_whitewood_wax = function(inst)
    local dd = inst._dd_wax
    local _dd = inst._dd
    if dd.fruitname ~= nil then
        local fx = inst._plant
        if fx == nil then
            fx = SpawnPrefab("potplant_l_fx")
            fx.entity:SetParent(inst.entity)
            fx.components.highlightchild:SetOwner(inst)
            inst._plant = fx
        end
        local overridebuild = paw.potanimbuilds[dd.fruitname] or "pot_whitewood" --贴图太多，另外做了动画包，所以需要专门设置
        if overridebuild ~= fx.AnimState:GetBuild() then
            fx.AnimState:SetBank(overridebuild)
            fx.AnimState:SetBuild(overridebuild)
        end
        if _dd ~= nil then
            if _dd.fixmap ~= nil and _dd.fixmap[dd.fruitname] ~= nil then
                local fdd = _dd.fixmap[dd.fruitname]
                if fdd[dd.animkey] ~= nil then
                    fdd = fdd[dd.animkey]
                end
                local bb = fdd.bank or _dd.bank
                if bb ~= nil then
                    fx.AnimState:SetBank(bb)
                end
                bb = fdd.build or _dd.build
                if bb ~= nil then
                    fx.AnimState:SetBuild(bb)
                end
                fx.Follower:FollowSymbol(inst.GUID, "afollowed",
                    fdd.x or _dd.x or 0, fdd.y or _dd.y or 0, fdd.z or _dd.z or 0)
                fx.loopanim = fdd.loopanim
            else
                if _dd.bank ~= nil then
                    fx.AnimState:SetBank(_dd.bank)
                end
                if _dd.build ~= nil then
                    fx.AnimState:SetBuild(_dd.build)
                end
                fx.Follower:FollowSymbol(inst.GUID, "afollowed", _dd.x or 0, _dd.y or 0, _dd.z or 0)
            end
            if _dd.plantfn ~= nil then
                _dd.plantfn(inst, fx)
            end
        else
            fx.Follower:FollowSymbol(inst.GUID, "afollowed", 0, 0, 0)
        end
        fx.AnimState:PlayAnimation(dd.fruitname..dd.stage.."_"..dd.animkey, fx.loopanim)
        if fx.loopanim then
            TOOLS_L.RandomAnimFrame(fx)
        end
    end
    -- if _dd ~= nil and _dd.soilchangefn ~= nil then
    --     _dd.soilchangefn(inst)
    -- end
    if _dd ~= nil and _dd.soilfn ~= nil then
        _dd.soilfn(inst, dd.barren)
    else
        if dd.barren then
            inst.AnimState:OverrideSymbol("asoil", inst.AnimState:GetBuild() or "pot_whitewood", "asoilout")
            if inst._plant ~= nil then
                inst._plant.AnimState:OverrideSymbol("asoil", inst.AnimState:GetBuild() or "pot_whitewood", "asoilout")
            end
        else
            inst.AnimState:ClearOverrideSymbol("asoil")
            if inst._plant ~= nil then
                -- inst._plant.AnimState:ClearOverrideSymbol("asoil") --不能直接clear，需要兼容皮肤
                inst._plant.AnimState:OverrideSymbol("asoil", inst.AnimState:GetBuild() or "pot_whitewood", "asoil")
            end
        end
    end
end
paw.MakeWaxedPlant({ ------稀有基质培植盆
    name = "pot_whitewood", dug_prefab = "pot_whitewood_item_waxed", action = "HAMMER", twoface = true,
    fn_common = function(inst)
        pas.SetMiniMap(inst, "pot_whitewood", nil)
        paw.InitNet_wax(inst, "pot_ww", paw.OnWaxClient_pot_ww)
        pas.SetAnim(inst, "pot_whitewood", nil, nil, nil)
        LS_C_Init(inst, "pot_whitewood", false, "data_wax", "pot_whitewood_waxed")
    end,
    fn_server = function(inst)
        inst.fn_init = paw.Init_pot_whitewood_wax
    end,
    fn_dowax = function(inst, dd)
        paw.DoWax(inst, dd)
        inst.legiontag_dowax = true
        if dd.skin ~= nil then
            inst.components.skinedlegion:SetSkin(dd.skin, dd.userid)
        end
        paw.Init_pot_whitewood_wax(inst)
        dd.frame = nil
        dd.multcolor = nil
        inst.legiontag_dowax = nil
    end
})
paw.MakeWaxedItem({ ------稀有基质培植盆(物品)
    name = "pot_whitewood", float = { 0.05, "med", 0.2, 0.8 },
    fn_common = function(inst)
        paw.InitNet_wax(inst, "pot_ww", paw.OnWaxClient_pot_ww)
        pas.SetAnim(inst, "pot_whitewood", nil, "placer", nil)
        inst.AnimState:SetScale(0.7, 0.7) --稍微小一点，以此做区分
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "pot_whitewood")
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "pot_whitewood_waxed" })
    end,
    fn_dowax_placer = function(item, builder, recipe, placer)
        local dd = item._dd_wax_c or item._dd_wax or {} --只在无洞穴本地档时才有 _dd_wax 数据
        if pas.SetPlacerAnim(placer, dd.skin) then
            placer.AnimState:SetBank("pot_whitewood")
            placer.AnimState:SetBuild("pot_whitewood")
            if dd.barren then
                placer.AnimState:OverrideSymbol("asoil", "pot_whitewood", "asoilout")
            -- else
            --     placer.AnimState:ClearOverrideSymbol("asoil")
            end
            --新增一个植株体的动画实体太麻烦了，不搞了
        end
        placer.Transform:SetTwoFaced() --为了让种植预览和种植后的动画旋转角度保持一致
        placer.AnimState:SetPercent("placer", 0)
    end
})

paw.OnWaxClient_sivderivant = function(inst)
    local dd, newdd = paw.OnWaxClient(inst)
    if dd.stage == nil then
        dd.stage = 1
    else
        newdd.stage = dd.stage
        dd.stage = tonumber(dd.stage) + 1
    end
    if dd.form then
        newdd.form = true
        inst.legion_namedetail = STRINGS.NAMEDETAIL_L.SIVING_THETREE_WAXED
            ..STRINGS.NAMEDETAIL_L.SPACE..STRINGS.NAMEDETAIL_L.SIVING_DERIVANT_WAXED[dd.stage]
    else
        inst.legion_namedetail = STRINGS.NAMEDETAIL_L.SIVING_DERIVANT_WAXED[dd.stage]
    end
end
paw.MakeWaxedPlant({ ------子圭奇型岩
    name = "siving_derivant", dug_prefab = "siving_derivant_item_waxed", twoface = true, snow = true,
    fn_common = function(inst)
        pas.SetMiniMap(inst, "siving_derivant", nil)
        paw.InitNet_wax(inst, "sivderivant", paw.OnWaxClient_sivderivant)
        pas.SetAnim(inst, "siving_derivant", nil, "lvl0", nil)
        inst.AnimState:SetScale(1.3, 1.3)
        LS_C_Init(inst, "siving_derivant", false, "data_wax", "siving_derivant_waxed")
    end,
    fn_dowax = function(inst, dd)
        paw.DoWax(inst, dd)
        inst.legiontag_dowax = true
        if dd.skin ~= nil then
            inst.components.skinedlegion:SetSkin(dd.skin, dd.userid)
        end
        inst.AnimState:PlayAnimation("lvl"..(dd.stage or "0")..(dd.form and "_live" or ""))
        dd.frame = nil
        dd.multcolor = nil
        inst.legiontag_dowax = nil
    end
})
paw.MakeWaxedItem({ ------子圭奇型岩(物品)
    name = "siving_derivant",
    fn_common = function(inst)
        paw.InitNet_wax(inst, "sivderivant", paw.OnWaxClient_sivderivant)
        pas.SetAnim(inst, "siving_derivant", nil, "item", nil)
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "siving_derivant_item")
        inst.components.inventoryitem:SetSinks(true)
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "siving_derivant_waxed" })
    end,
    fn_dowax_placer = function(item, builder, recipe, placer)
        local dd = item._dd_wax_c or item._dd_wax or {}
        if pas.SetPlacerAnim(placer, dd.skin) then
            placer.AnimState:SetBank("siving_derivant")
            placer.AnimState:SetBuild("siving_derivant")
            placer.AnimState:SetScale(1.3, 1.3)
        end
        placer.Transform:SetTwoFaced() --为了让种植预览和种植后的动画旋转角度保持一致
        placer.AnimState:SetPercent("lvl"..(dd.stage or "0")..(dd.form and "_live" or ""), 0)
    end
})

paw.OnWaxClient_sivthetree = function(inst)
    local dd, newdd = paw.OnWaxClient(inst)
    if dd.state then
        newdd.state = true
        inst.legion_namedetail = STRINGS.NAMEDETAIL_L.SIVING_THETREE_WAXED
    end
end
paw.MakeWaxedPlant({ ------子圭神木岩
    name = "siving_thetree", dug_prefab = "siving_thetree_item_waxed", twoface = true,
    fn_common = function(inst)
        pas.SetMiniMap(inst, "siving_thetree", 1)
        paw.InitNet_wax(inst, "sivthetree", paw.OnWaxClient_sivthetree)
        pas.SetAnim(inst, "siving_thetree", nil, nil, nil)
        inst.AnimState:SetScale(1.3, 1.3)
    end,
    fn_dowax = function(inst, dd)
        paw.DoWax(inst, dd)
        if dd.state then
            inst.AnimState:SetBuild("siving_thetree_live")
        -- else
        --     inst.AnimState:SetBuild("siving_thetree")
        end
        dd.frame = nil
        dd.multcolor = nil
    end
})
paw.MakeWaxedItem({ ------子圭神木岩(物品)
    name = "siving_thetree",
    fn_common = function(inst)
        paw.InitNet_wax(inst, "sivthetree", paw.OnWaxClient_sivthetree)
        pas.SetAnim(inst, "siving_derivant", nil, "item_live", nil)
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "siving_derivant_item")
        inst.components.inventoryitem:SetSinks(true)
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "siving_thetree_waxed" })
    end,
    fn_dowax_placer = function(item, builder, recipe, placer)
        local dd = item._dd_wax_c or item._dd_wax or {} --只在无洞穴本地档时才有 _dd_wax 数据
        placer.AnimState:SetBank("siving_thetree")
        placer.AnimState:SetBuild(dd.state and "siving_thetree_live" or "siving_thetree")
        placer.AnimState:SetPercent("idle", 0)
        placer.AnimState:SetScale(1.3, 1.3)
        placer.Transform:SetTwoFaced() --为了让种植预览和种植后的动画旋转角度保持一致
    end
})

paw.OnWaxClient_flowerbush = function(inst)
    local dd, newdd = paw.OnWaxClient(inst)
    if dd.form then
        newdd.form = true
    end
    if dd.state ~= nil then
        newdd.state = tonumber(dd.state)
        if newdd.state == 4 then
            inst.legion_namedetail = STRINGS.NAMEDETAIL_L.WITHERED
        else
            inst.legion_namedetail = STRINGS.NAMEDETAIL_L.FRUITS[newdd.state]
        end
    end
end
paw.DoWax_flowerbush = function(inst, dd)
    paw.DoWax(inst, dd)
    inst.legiontag_dowax = true
    if dd.form then
        inst._fruitform = true
    end
    if dd.skin ~= nil and inst.components.skinedlegion ~= nil then
        inst.components.skinedlegion:SetSkin(dd.skin, dd.userid)
    end
    if dd.state == 4 then
        inst.AnimState:PlayAnimation("dead", false)
        pas.SetBerries_bush(inst, nil)
    else
        inst.AnimState:PlayAnimation("idle", true)
        if dd.state == nil then
            pas.SetBerries_bush(inst, nil)
        elseif dd.state == 1 then
            pas.SetBerries_bush(inst, 1)
        elseif dd.state == 2 then
            pas.SetBerries_bush(inst, 0.5)
        else
            pas.SetBerries_bush(inst, 0.1)
        end
        if dd.frame then
            inst.AnimState:SetFrame(dd.frame)
        else
            TOOLS_L.RandomAnimFrame(inst)
        end
    end
    dd.frame = nil
    dd.multcolor = nil
    inst.legiontag_dowax = nil
end
paw.DoWaxPlacer_flowerbush = function(item, builder, recipe, placer)
    local dd = item._dd_wax_c or item._dd_wax or {} --只在无洞穴本地档时才有 _dd_wax 数据
    if dd.form then
        placer._fruitform = true
    end
    if pas.SetPlacerAnim(placer, dd.skin) then
        local build = item.AnimState:GetBuild()
        if build == "neverfade" then
            build = "neverfadebush"
        end
        placer.AnimState:SetBank("berrybush2")
        placer.AnimState:SetBuild(build)
    end
    placer.Transform:SetTwoFaced() --为了让种植预览和种植后的动画旋转角度保持一致
    if dd.state == 4 then
        placer.AnimState:SetPercent("dead", 0)
        pas.SetBerries_bush(placer, nil)
    else
        placer.AnimState:SetPercent("idle", 0)
        if dd.state == nil then
            pas.SetBerries_bush(placer, nil)
        elseif dd.state == 1 then
            pas.SetBerries_bush(placer, 1)
        elseif dd.state == 2 then
            pas.SetBerries_bush(placer, 0.5)
        else
            pas.SetBerries_bush(placer, 0.1)
        end
    end
end

paw.MakeWaxedPlant({ ------蔷薇花丛
    name = "rosebush", dug_prefab = "rosebush_item_waxed", twoface = true,
    fn_common = function(inst)
        pas.SetMiniMap(inst, "rosebush", nil)
        paw.InitNet_wax(inst, "flowerbush", paw.OnWaxClient_flowerbush)
        pas.SetAnim(inst, "berrybush2", "rosebush", nil, true)
        pas.SetBerries_bush(inst, nil)
        LS_C_Init(inst, "rosebush", false, "data_wax", "rosebush_waxed")
    end,
    fn_dowax = paw.DoWax_flowerbush
})
paw.MakeWaxedItem({ ------蔷薇花丛(物品)
    name = "rosebush", float = { 0.03, "large", 0.2, {0.65, 0.5, 0.65} },
    fn_common = function(inst)
        paw.InitNet_wax(inst, "flowerbush", paw.OnWaxClient_flowerbush)
        pas.SetAnim(inst, "berrybush2", "rosebush", "dropped", nil)
        inst.fn_dowax_placer = paw.DoWaxPlacer_flowerbush
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "dug_rosebush")
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "rosebush_waxed" })
    end
})
paw.MakeWaxedPlant({ ------蹄莲花丛
    name = "lilybush", dug_prefab = "lilybush_item_waxed", twoface = true,
    fn_common = function(inst)
        pas.SetMiniMap(inst, "lilybush", nil)
        paw.InitNet_wax(inst, "flowerbush", paw.OnWaxClient_flowerbush)
        pas.SetAnim(inst, "berrybush2", "lilybush", nil, true)
        pas.SetBerries_bush(inst, nil)
        LS_C_Init(inst, "lilybush", false, "data_wax", "lilybush_waxed")
    end,
    fn_dowax = paw.DoWax_flowerbush
})
paw.MakeWaxedItem({ ------蹄莲花丛(物品)
    name = "lilybush", float = { 0.03, "large", 0.2, {0.65, 0.5, 0.65} },
    fn_common = function(inst)
        paw.InitNet_wax(inst, "flowerbush", paw.OnWaxClient_flowerbush)
        pas.SetAnim(inst, "berrybush2", "lilybush", "dropped", nil)
        inst.fn_dowax_placer = paw.DoWaxPlacer_flowerbush
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "dug_lilybush")
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "lilybush_waxed" })
    end
})
paw.MakeWaxedPlant({ ------兰草花丛
    name = "orchidbush", dug_prefab = "orchidbush_item_waxed", twoface = true,
    fn_common = function(inst)
        pas.SetMiniMap(inst, "orchidbush", nil)
        paw.InitNet_wax(inst, "flowerbush", paw.OnWaxClient_flowerbush)
        pas.SetAnim(inst, "berrybush2", "orchidbush", nil, true)
        pas.SetBerries_bush(inst, nil)
        LS_C_Init(inst, "orchidbush", false, "data_wax", "orchidbush_waxed")
    end,
    fn_dowax = paw.DoWax_flowerbush
})
paw.MakeWaxedItem({ ------兰草花丛(物品)
    name = "orchidbush", float = { nil, "large", 0.1, {0.65, 0.5, 0.65} },
    fn_common = function(inst)
        paw.InitNet_wax(inst, "flowerbush", paw.OnWaxClient_flowerbush)
        pas.SetAnim(inst, "berrybush2", "orchidbush", "dropped", nil)
        inst.fn_dowax_placer = paw.DoWaxPlacer_flowerbush
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "dug_orchidbush")
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "orchidbush_waxed" })
    end
})
paw.MakeWaxedPlant({ ------永不凋零花丛
    name = "neverfadebush", dug_prefab = "neverfadebush_item_waxed", twoface = true,
    fn_common = function(inst)
        pas.SetMiniMap(inst, "neverfadebush", nil)
        paw.InitNet_wax(inst, "flowerbush", paw.OnWaxClient_flowerbush)
        pas.SetAnim(inst, "berrybush2", "neverfadebush", nil, true)
        pas.SetBerries_bush(inst, nil)
        LS_C_Init(inst, "neverfadebush", false, "data_wax", "neverfadebush_waxed")
    end,
    fn_dowax = paw.DoWax_flowerbush
})
paw.MakeWaxedItem({ ------永不凋零花丛(物品)
    name = "neverfadebush", float = { 0.12, "med", 0.4, 0.5 },
    fn_common = function(inst)
        paw.InitNet_wax(inst, "flowerbush", paw.OnWaxClient_flowerbush)
        pas.SetAnim(inst, "neverfade", nil, nil, nil)
        inst.fn_dowax_placer = paw.DoWaxPlacer_flowerbush
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "neverfade")
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "neverfadebush_waxed" })
    end
})
paw.MakeWaxedPlant({ ------夜玫瑰花丛
    name = "nightrosebush", dug_prefab = "nightrosebush_item_waxed", twoface = true,
    fn_common = function(inst)
        pas.SetMiniMap(inst, "nightrosebush", nil)
        paw.InitNet_wax(inst, "flowerbush", paw.OnWaxClient_flowerbush)
        pas.SetAnim(inst, "berrybush2", "nightrosebush", nil, true)
        inst.AnimState:SetLightOverride(0.1)
        inst._fruitform = true
        pas.SetBerries_bush(inst, nil)
    end,
    fn_dowax = paw.DoWax_flowerbush
})
paw.MakeWaxedItem({ ------夜玫瑰花丛(物品)
    name = "nightrosebush", float = { 0.03, "large", 0.2, 0.65 },
    fn_common = function(inst)
        paw.InitNet_wax(inst, "flowerbush", paw.OnWaxClient_flowerbush)
        pas.SetAnim(inst, "nightrosebush", nil, "dropped", nil)
        inst.AnimState:SetLightOverride(0.1)
        inst._fruitform = true
        inst.fn_dowax_placer = paw.DoWaxPlacer_flowerbush
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "dug_nightrosebush")
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "nightrosebush_waxed" })
    end
})

paw.OnWaxClient_monstrain = function(inst)
    local dd, newdd = paw.OnWaxClient(inst)
    if dd.state ~= nil then
        newdd.state = tonumber(dd.state)
        inst.legion_namedetail = STRINGS.NAMEDETAIL_L.MONSTRAIN_WAXED[newdd.state]
    end
end
paw.MakeWaxedPlant({ ------雨竹
    name = "monstrain", dug_prefab = "monstrain_item_waxed", twoface = true,
    fn_common = function(inst)
        pas.SetMiniMap(inst, "monstrain", nil)
        paw.InitNet_wax(inst, "monstrain", paw.OnWaxClient_monstrain)
        pas.SetAnim(inst, "monstrain", nil, nil, true)
        inst.AnimState:Hide("fruit")
        inst.Transform:SetScale(1.4, 1.4, 1.4)
    end,
    fn_dowax = function(inst, dd)
        paw.DoWax(inst, dd)
        inst.legiontag_dowax = true
        if dd.skin ~= nil then
            inst.components.skinedlegion:SetSkin(dd.skin, dd.userid)
        end
        if dd.state == nil then
            inst.AnimState:PlayAnimation("idle", true)
            inst.AnimState:Hide("fruit")
        elseif dd.state == 1 then
            inst.AnimState:PlayAnimation("idle_summer", true)
        elseif dd.state == 2 then
            inst.AnimState:PlayAnimation("idle_winter", true)
        else
            inst.AnimState:PlayAnimation("idle", true)
            inst.AnimState:Show("fruit")
        end
        if dd.frame then
            inst.AnimState:SetFrame(dd.frame)
            dd.frame = nil
        else
            TOOLS_L.RandomAnimFrame(inst)
        end
        dd.multcolor = nil
        inst.legiontag_dowax = nil
    end
})
paw.MakeWaxedItem({ ------雨竹(物品)
    name = "monstrain", float = { nil, "small", 0.2, 1.2 },
    fn_common = function(inst)
        paw.InitNet_wax(inst, "monstrain", paw.OnWaxClient_monstrain)
        pas.SetAnim(inst, "monstrain", nil, "dropped", nil)
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "dug_monstrain")
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "monstrain_waxed" })
    end,
    fn_dowax_placer = function(item, builder, recipe, placer)
        local dd = item._dd_wax_c or item._dd_wax or {} --只在无洞穴本地档时才有 _dd_wax 数据
        if pas.SetPlacerAnim(placer, dd.skin) then
            placer.AnimState:SetBank("monstrain")
            placer.AnimState:SetBuild("monstrain")
            placer.Transform:SetScale(1.4, 1.4, 1.4)
        end
        if dd.state == nil then
            placer.AnimState:SetPercent("idle", 0)
            placer.AnimState:Hide("fruit")
        elseif dd.state == 1 then
            placer.AnimState:SetPercent("idle_summer", 0)
        elseif dd.state == 2 then
            placer.AnimState:SetPercent("idle_winter", 0)
        else
            placer.AnimState:SetPercent("idle", 0)
            placer.AnimState:Show("fruit")
        end
        placer.Transform:SetTwoFaced() --为了让种植预览和种植后的动画旋转角度保持一致
    end
})

paw.dd_agronssword = {
    img_tex = "agronssword", img_atlas = "images/inventoryimages/agronssword.xml",
    img_tex2 = "agronssword2", img_atlas2 = "images/inventoryimages/agronssword2.xml",
    build = "agronssword", fx = "agronssword_fx"
}
paw.OnWaxClient_worldsword = function(inst)
    local dd, newdd = paw.OnWaxClient(inst)
    if dd.state ~= nil then
        newdd.state = tonumber(dd.state)
        inst.legion_namedetail = STRINGS.NAMEDETAIL_L.WORLDSWORD_WAXED[newdd.state]
    end
end
paw.DoWax_worldsword = function(inst, dd)
    paw.DoWax(inst, dd)
    inst.legiontag_dowax = true
    if dd.state ~= nil then
        inst._revolt_l = true
    end
    if dd.skin ~= nil then
        inst.components.skinedlegion:SetSkin(dd.skin, dd.userid)
    end
    inst.fn_init(inst, inst._revolt_l)
    dd.frame = nil
    dd.multcolor = nil
    inst.legiontag_dowax = nil
end
paw.OnEquip_agronssword_wax = function(inst, owner)
    TOOLS_L.hand_on_shield(owner, inst._dd.build, inst._revolt_l and "swap2" or "swap1")
end
paw.Init_agronssword_wax = function(inst, revolt)
    if revolt then
        inst.components.inventoryitem.atlasname = inst._dd.img_atlas2
        inst.components.inventoryitem:ChangeImageName(inst._dd.img_tex2)
        inst.AnimState:PlayAnimation("idle2")
    else
        inst.components.inventoryitem.atlasname = inst._dd.img_atlas
        inst.components.inventoryitem:ChangeImageName(inst._dd.img_tex)
        inst.AnimState:PlayAnimation("idle")
    end
end
paw.MakeWaxedItem({ ------艾力冈的剑(物品)
    name = "agronssword",
    fn_common = function(inst)
        -- pas.SetMiniMap(inst, "agronssword", 1)
        paw.InitNet_wax(inst, "worldsword", paw.OnWaxClient_worldsword)
        pas.SetAnim(inst, "agronssword", nil, nil, nil)
        LS_C_Init(inst, "agronssword", true, "data_wax", "agronssword_item_waxed")
        inst:AddTag("nopunch")
        inst:AddTag("nomimic_l") --棱镜标签。不让拟态蠕虫进行复制
    end,
    fn_server = function(inst)
        inst._dd = paw.dd_agronssword
        inst.components.inspectable:SetNameOverride("waxed_item_l")
        pas.SetInventoryItem(inst, "agronssword")
        -- inst.components.inventoryitem:SetSinks(true)
        pas.SetEquippable(inst, paw.OnEquip_agronssword_wax, TOOLS_L.hand_off_shield, nil)

        inst.fn_init = paw.Init_agronssword_wax
        inst.fn_dowax = paw.DoWax_worldsword
    end
})

paw.dd_refractedmoonlight = {
    img_tex = "refractedmoonlight", img_atlas = "images/inventoryimages/refractedmoonlight.xml",
    img_tex2 = "refractedmoonlight2", img_atlas2 = "images/inventoryimages/refractedmoonlight2.xml",
    build = "refractedmoonlight", fx = "refracted_l_spark_fx"
}
paw.OnEquip_refracted_wax = function(inst, owner)
    TOOLS_L.hand_on(owner, inst._dd.build, inst._revolt_l and "swap2" or "swap1")
end
paw.Init_refracted_wax = function(inst, revolt)
    if revolt then
        inst.components.inventoryitem.atlasname = inst._dd.img_atlas2
        inst.components.inventoryitem:ChangeImageName(inst._dd.img_tex2)
        inst.AnimState:PlayAnimation("idle2", true)
        if inst._dd.fxfn ~= nil then
            inst._dd.fxfn(inst)
        end
    else
        inst.components.inventoryitem.atlasname = inst._dd.img_atlas
        inst.components.inventoryitem:ChangeImageName(inst._dd.img_tex)
        inst.AnimState:PlayAnimation("idle", true)
        if inst._dd.fxendfn ~= nil then
            inst._dd.fxendfn(inst)
        end
    end
    TOOLS_L.RandomAnimFrame(inst)
end
paw.MakeWaxedItem({ ------月折宝剑(物品)
    name = "refractedmoonlight",
    fn_common = function(inst)
        -- pas.SetMiniMap(inst, "refractedmoonlight", 1)
        paw.InitNet_wax(inst, "worldsword", paw.OnWaxClient_worldsword)
        pas.SetAnim(inst, "refractedmoonlight", nil, nil, true)
        LS_C_Init(inst, "refractedmoonlight", false, "data_wax", "refractedmoonlight_item_waxed")
        inst:AddTag("nopunch")
        inst:AddTag("nomimic_l") --棱镜标签。不让拟态蠕虫进行复制
    end,
    fn_server = function(inst)
        inst._dd = paw.dd_refractedmoonlight
        inst.components.inspectable:SetNameOverride("waxed_item_l")
        pas.SetInventoryItem(inst, "refractedmoonlight")
        -- inst.components.inventoryitem:SetSinks(true)
        pas.SetEquippable(inst, paw.OnEquip_refracted_wax, TOOLS_L.hand_off, nil)

        inst.fn_init = paw.Init_refracted_wax
        inst.fn_dowax = paw.DoWax_worldsword
    end
})

paw.OnWaxClient_shyerrycore = function(inst)
    local dd, newdd = paw.OnWaxClient(inst)
    local spa = STRINGS.NAMEDETAIL_L.SPACE
    newdd.isboss = dd.isboss
    newdd.stage = dd.stage or "1"
    local str = (dd.isboss and "" or STRINGS.NAMEDETAIL_L.ABNORMAL)..spa..STRINGS.NAMEDETAIL_L.STAGE..newdd.stage.."/3"
    if dd.fruit ~= nil then --有果子
        newdd.fruit = dd.fruit
        inst.legion_namedetail = str..spa..STRINGS.NAMEDETAIL_L.FRUIT..dd.fruit
    else
        inst.legion_namedetail = str
    end
end
paw.MakeWaxedPlant({ ------颤栗树之心、不正常的颤栗树之心
    name = "shyerrycore", dug_prefab = "shyerrycore_item_waxed", twoface = true,
    fn_common = function(inst)
        pas.SetMiniMap(inst, "shyerrycore_planted", nil)
        paw.InitNet_wax(inst, "shyerrycore", paw.OnWaxClient_shyerrycore)
        pas.SetAnim(inst, "bramble_core", "shyerrycore", nil, true)
        inst.Transform:SetScale(pas.scale_shy, pas.scale_shy, pas.scale_shy)
    end,
    fn_dowax = function(inst, dd)
        paw.DoWax(inst, dd)
        if dd.isboss then
            if dd.stage == "2" then
                inst.AnimState:OverrideSymbol("stalk01", inst.AnimState:GetBuild(), "stalklvl2")
                pas.CheckTreeTop(inst)
            elseif dd.stage == "3" then
                inst.AnimState:OverrideSymbol("stalk01", inst.AnimState:GetBuild(), "stalklvl3")
                pas.CheckTreeTop(inst)
                inst._treetop.AnimState:OverrideSymbol("bulb01",
                    inst._treetop.AnimState:GetBuild(), "treetop3"..(dd.fruit or "0"))
            end
        else
            inst.AnimState:SetBuild("shyerrycore_planted")
            if dd.stage == "2" then
                inst.AnimState:OverrideSymbol("stalk01", inst.AnimState:GetBuild(), "stalklvl2")
            elseif dd.stage == "3" then
                inst.AnimState:OverrideSymbol("stalk01",
                    inst.AnimState:GetBuild(), "stalklvl3"..(dd.fruit or "0"))
            end
        end
        local fm = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
        inst.AnimState:SetFrame(fm)
        if inst._treetop ~= nil then
            inst._treetop.AnimState:SetFrame(fm)
        end
        dd.frame = nil
        dd.multcolor = nil
    end
})
paw.MakeWaxedItem({ ------颤栗树之心、不正常的颤栗树之心(物品)
    name = "shyerrycore", float = { 0.02, "med", 0.2, 0.7 },
    fn_common = function(inst)
        paw.InitNet_wax(inst, "shyerrycore", paw.OnWaxClient_shyerrycore)
        pas.SetAnim(inst, "shyerrycore_planted", nil, "item", nil)
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "shyerrycore_item")
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "shyerrycore_waxed" })
    end,
    fn_dowax_placer = function(item, builder, recipe, placer)
        local dd = item._dd_wax_c or item._dd_wax or {} --只在无洞穴本地档时才有 _dd_wax 数据
        placer.AnimState:SetBank("bramble_core")
        if dd.isboss then
            placer.AnimState:SetBuild("shyerrycore")
            if dd.stage == "2" then
                placer.AnimState:OverrideSymbol("stalk01", placer.AnimState:GetBuild(), "stalklvl2")
            elseif dd.stage == "3" then
                placer.AnimState:OverrideSymbol("stalk01", placer.AnimState:GetBuild(), "stalklvl3")
                --新增一个树梢动画实体太麻烦了，不搞了
            end
        else
            placer.AnimState:SetBuild("shyerrycore_planted")
            if dd.stage == "2" then
                placer.AnimState:OverrideSymbol("stalk01", placer.AnimState:GetBuild(), "stalklvl2")
            elseif dd.stage == "3" then
                placer.AnimState:OverrideSymbol("stalk01", placer.AnimState:GetBuild(), "stalklvl3"..(dd.fruit or "0"))
            end
        end
        placer.AnimState:SetPercent("idle", 0)
        placer.Transform:SetScale(pas.scale_shy, pas.scale_shy, pas.scale_shy)
        placer.Transform:SetTwoFaced() --为了让种植预览和种植后的动画旋转角度保持一致
    end
})

paw.OnWaxClient_shyerrytree = function(inst)
    local dd, newdd = paw.OnWaxClient(inst)
    newdd.form = dd.form or "1"
    if dd.small then
        newdd.small = true
        inst.legion_namedetail = STRINGS.NAMEDETAIL_L.SMALLER..STRINGS.NAMEDETAIL_L.SPACE
            ..STRINGS.NAMEDETAIL_L.FORM..newdd.form
    else
        inst.legion_namedetail = STRINGS.NAMEDETAIL_L.FORM..newdd.form
    end
end
paw.MakeWaxedPlant({ ------颤栗树
    name = "shyerrytree", dug_prefab = "shyerrytree_item_waxed", twoface = true,
    fn_common = function(inst)
        pas.SetMiniMap(inst, "shyerrytree", -1)
        paw.InitNet_wax(inst, "shyerrytree", paw.OnWaxClient_shyerrytree)
        pas.SetAnim(inst, "bramble_core", "shyerrytree1", nil, true)
    end,
    fn_dowax = function(inst, dd)
        paw.DoWax(inst, dd)
        if dd.form ~= nil then
            inst.AnimState:SetBuild("shyerrytree"..dd.form)
        end
        if dd.small then
            inst.Transform:SetScale(0.8, 0.8, 0.8)
        end
        TOOLS_L.RandomAnimFrame(inst)
        dd.frame = nil
        if dd.multcolor then
            inst.AnimState:SetMultColour(unpack(dd.multcolor))
        end
    end
})
paw.MakeWaxedItem({ ------颤栗树(物品)
    name = "shyerrytree", float = { nil, "med", 0.2, 0.8 },
    fn_common = function(inst)
        paw.InitNet_wax(inst, "shyerrytree", paw.OnWaxClient_shyerrytree)
        pas.SetAnim(inst, "shyerrylog", nil, nil, nil)
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "shyerrylog")
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "shyerrytree_waxed" })
    end,
    fn_dowax_placer = function(item, builder, recipe, placer)
        local dd = item._dd_wax_c or item._dd_wax or {} --只在无洞穴本地档时才有 _dd_wax 数据
        placer.AnimState:SetBank("bramble_core")
        placer.AnimState:SetBuild("shyerrytree"..(dd.form or "1"))
        placer.AnimState:SetPercent("idle", 0)
        if dd.small then
            placer.Transform:SetScale(0.8, 0.8, 0.8)
        end
        placer.Transform:SetTwoFaced() --为了让种植预览和种植后的动画旋转角度保持一致
    end
})

paw.MakeWaxedPlant({ ------颤栗花
    name = "shyerryflower", dug_prefab = "shyerryflower_item_waxed", twoface = true,
    fn_common = function(inst)
        pas.SetAnim(inst, "bramble_core", "shyerrybush", nil, true)
        inst.Transform:SetScale(0.6, 0.6, 0.6)
    end,
    fn_dowax = function(inst, dd)
        inst._dd_wax = dd
        TOOLS_L.RandomAnimFrame(inst)
        dd.frame = nil
        dd.multcolor = nil
    end
})
paw.MakeWaxedItem({ ------颤栗花(物品)
    name = "shyerryflower", float = { 0.04, "small", 0.25, 0.9 },
    fn_common = function(inst)
        pas.SetAnim(inst, "shyerry", nil, nil, nil)
    end,
    fn_server = function(inst)
        pas.SetInventoryItem(inst, "shyerry")
        pas.SetStackable(inst)
    end,
    fn_deploy = function(inst, pt, deployer, rot)
        paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = "shyerryflower_waxed" })
    end,
    fn_dowax_placer = function(item, builder, recipe, placer)
        placer.AnimState:SetBank("bramble_core")
        placer.AnimState:SetBuild("shyerrybush")
        placer.AnimState:SetPercent("idle", 0)
        placer.Transform:SetScale(0.6, 0.6, 0.6)
        placer.Transform:SetTwoFaced() --为了让种植预览和种植后的动画旋转角度保持一致
    end
})

paw.OnWaxClient_icire = function(inst)
    local dd, newdd = paw.OnWaxClient(inst)
    if dd.state ~= nil then
        newdd.state = tonumber(dd.state)
        inst.legion_namedetail = STRINGS.NAMEDETAIL_L.ICIRE_ROCK_WAXED[newdd.state]
    end
end
paw.DoWax_icire = function(inst, dd)
    paw.DoWax(inst, dd)
    inst.legiontag_dowax = true
    if dd.skin ~= nil then
        inst.components.skinedlegion:SetSkin(dd.skin, dd.userid)
    end
    inst.fn_temp(inst)
    dd.frame = nil
    dd.multcolor = nil
    inst.legiontag_dowax = nil
end
paw.TempFn_icire_wax = function(inst)
    local range = inst._dd_wax and inst._dd_wax.state or 3
    local canbloom = true
    local newname = "icire_rock"..tostring(range)
    if inst._dd ~= nil then
        newname = newname..inst._dd.img_pst
        inst.components.inventoryitem.atlasname = "images/inventoryimages_skin/"..newname..".xml"
        inst.components.inventoryitem:ChangeImageName(newname)
        canbloom = inst._dd.canbloom
        if inst._dd.tempfn ~= nil then
            inst._dd.tempfn(inst, range)
        end
    else
        inst.components.inventoryitem.atlasname = "images/inventoryimages/"..newname..".xml"
        inst.components.inventoryitem:ChangeImageName(newname)
    end
    inst.AnimState:PlayAnimation(tostring(range), true)

    if range == 1 or range == 5 then --最冷与最热都会发光
        local lig = inst._light
        if lig == nil or not lig:IsValid() then
            lig = SpawnPrefab("heatrocklight")
            if range == 1 then
                lig.Light:SetColour(64/255, 64/255, 208/255)
            else
                lig.Light:SetColour(235/255, 165/255, 12/255)
            end
            lig.Light:SetIntensity(0.5)
            lig.entity:SetParent(inst.entity)
            inst._light = lig
        end
        lig.Light:Enable(true)
    else
        canbloom = false
        if inst._light ~= nil then
            inst._light:Remove()
            inst._light = nil
        end
    end
    if canbloom then
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    else
        inst.AnimState:ClearBloomEffectHandle()
    end
end
paw.OnEntityWake_icire_wax = function(inst)
    if inst._dd ~= nil and inst._dd.entwakefn ~= nil then
        inst._dd.entwakefn(inst)
    end
end
paw.OnEntitySleep_icire_wax = function(inst)
    if inst._dd ~= nil and inst._dd.entsleepfn ~= nil then
        inst._dd.entsleepfn(inst)
    end
end
paw.OnOwnerChange_icire_wax = function(inst, owner, newowners)
    local lig = inst._light
    if owner:HasTag("pocketdimension_container") or owner:HasTag("buried") then --在世界容器里
        if lig ~= nil then
            lig.entity:SetParent(inst.entity)
        end
        inst.inworldbox_l = true
        if inst._dd ~= nil and inst._dd.entsleepfn ~= nil then
            inst._dd.entsleepfn(inst)
        end
    else
        if lig ~= nil then
            lig.entity:SetParent(owner.entity)
        end
        inst.inworldbox_l = nil
        if not inst:IsAsleep() then
            if inst._dd ~= nil and inst._dd.entwakefn ~= nil then
                inst._dd.entwakefn(inst)
            end
        end
    end
    if lig == nil then
        return
    end
    if inst.inworldbox_l or owner:HasTag("player") then --在世界容器、玩家身上不发光
        if not lig:IsInLimbo() then
			lig:RemoveFromScene() --直接隐藏，就算因为温度变化导致亮起来了也没事
		end
    else
        if lig:IsInLimbo() then
			lig:ReturnToScene()
		end
    end
end
paw.OnRemove_icire_wax = function(inst)
    if inst._light ~= nil then
        inst._light:Remove()
    end
end
paw.MakeWaxedItem({ ------鸳鸯石(物品)
    name = "icire_rock",
    fn_common = function(inst)
        paw.SetFurnitureDecor_comm(inst)
        paw.InitNet_wax(inst, "icire_rock", paw.OnWaxClient_icire)
        pas.SetAnim(inst, "heat_rock", nil, "3", true)
        inst.AnimState:OverrideSymbol("rock", "icire_rock", "rock")
        inst.AnimState:OverrideSymbol("shadow", "icire_rock", "shadow")
        inst:AddTag("icebox_valid")
        LS_C_Init(inst, "icire_rock", false, "data_wax", "icire_rock_item_waxed")
    end,
    fn_server = function(inst)
        inst.components.inspectable:SetNameOverride("waxed_item_l")
        pas.SetInventoryItem(inst, "icire_rock")
        inst.components.inventoryitem:SetSinks(true)
        paw.SetFurnitureDecor_serv(inst, paw.Decor_owner)
        TOOLS_L.ListenOwnerChange(inst, paw.OnOwnerChange_icire_wax)
        inst.fn_temp = paw.TempFn_icire_wax
        inst.fn_dowax = paw.DoWax_icire
        inst.OnEntitySleep = paw.OnEntitySleep_icire_wax
        inst.OnEntityWake = paw.OnEntityWake_icire_wax
        inst.OnRemoveEntity = paw.OnRemove_icire_wax
    end
})

----------------
--[[ 异种植物 ]]
----------------

local skinedplant = {
	cactus_meat = true, carrot = true, lightbulb = true, berries = true
}

paw.OnWaxClient_xeed = function(inst)
    local dd, newdd = paw.OnWaxClient(inst)
    local spa = STRINGS.NAMEDETAIL_L.SPACE
    local str = STRINGS.NAMEDETAIL_L.CLUSTERLVL..(dd.lvl or "0")..spa..STRINGS.NAMEDETAIL_L.STAGE..(dd.stage or "1")
    newdd.stage = dd.stage and tonumber(dd.stage) or 1
    newdd.lvl = dd.lvl and tonumber(dd.lvl) or 0
    newdd.state = dd.state
    local cropdd = CROPS_DATA_LEGION[inst.xeedkey]
    if cropdd ~= nil then --显示最大阶段
        str = str.."/"..#cropdd.leveldata
    end
    if dd.state == "1" then --枯萎了
        inst.legion_namedetail = str..spa..STRINGS.NAMEDETAIL_L.WITHERED
    else
        if dd.form ~= nil then --形态
            newdd.form = tonumber(dd.form)
            str = str..spa..STRINGS.NAMEDETAIL_L.FORM..dd.form
        end
        if dd.state == "2" then --盛开
            inst.legion_namedetail = str..spa..STRINGS.NAMEDETAIL_L.FULLBLOOM
        else
            inst.legion_namedetail = str
        end
    end
end
paw.DisplayName_xeed_wax = function(inst)
    if inst._displayname == nil then
        inst._displayname = STRINGS.NAMEDETAIL_L.WAXED.." "..STRINGS.NAMES[string.upper("plant_"..inst.xeedkey.."_l")]
    end
    return inst._displayname
end
paw.SetSize_xeed_wax = function(inst, dd, lv) --设置簇栽大小
    local sizedd = dd.cluster_size or { 1, 1.8 }
    if lv == nil or lv < 0 then
        lv = 0
    elseif lv > 99 then
        lv = 99
    end
    lv = Remap(lv, 0, 99, sizedd[1], sizedd[2])
	inst.AnimState:SetScale(lv, lv, lv)
end
paw.SetAnim_xeed_wax = function(inst, dd, stage, form, state, skin, pause)
    local lvl = dd.leveldata[stage or 1] or dd.leveldata[1]
    if state == "1" and lvl.deadanim ~= nil then --枯萎了
        if pause then
            inst.AnimState:SetPercent(lvl.deadanim, 0)
        else
            inst.AnimState:PlayAnimation(lvl.deadanim, false)
        end
    else
        local anim
        if type(lvl.anim) == 'table' then
            anim = lvl.anim[form or 1] or lvl.anim[1]
		else
			anim = lvl.anim
		end
        if pause then
            inst.AnimState:SetPercent(anim, 0)
        else
            inst.AnimState:PlayAnimation(anim, true)
        end
    end
    if dd.fnwax_animfix ~= nil then
        dd.fnwax_animfix(inst, dd, stage, form, state, skin, pause)
    end
end
paw.DoWax_xeed = function(inst, dd)
    paw.DoWax(inst, dd)
    inst.legiontag_dowax = true
    if dd.skin ~= nil and inst.components.skinedlegion ~= nil then
        inst.components.skinedlegion:SetSkin(dd.skin, dd.userid)
    end
    local cropdd = CROPS_DATA_LEGION[inst.xeedkey]
    if cropdd ~= nil then
        paw.SetAnim_xeed_wax(inst, cropdd, dd.stage, dd.form, dd.state, dd.skin, false)
        paw.SetSize_xeed_wax(inst, cropdd, dd.lvl)
    end
    if dd.state ~= "1" then --没有枯萎
        if dd.frame then
            inst.AnimState:SetFrame(dd.frame)
        else
            TOOLS_L.RandomAnimFrame(inst)
        end
    end
    dd.frame = nil
    dd.multcolor = nil
    inst.legiontag_dowax = nil
end
paw.DoWaxPlacer_xeed = function(item, builder, recipe, placer)
    local cropdd = CROPS_DATA_LEGION[item.xeedkey]
    if cropdd == nil then
        return
    end
    local dd = item._dd_wax_c or item._dd_wax or {} --只在无洞穴本地档时才有 _dd_wax 数据
    if pas.SetPlacerAnim(placer, dd.skin) then
        placer.AnimState:SetBank(cropdd.bank)
        placer.AnimState:SetBuild(cropdd.build)
        if cropdd.bank == "plant_normal_legion" then
            -- placer.AnimState:OverrideSymbol("dirt", "crop_soil_legion", "dirt")
        else
            placer.AnimState:OverrideSymbol("soil", "crop_soil_legion", "soil")
        end
    end
    placer.Transform:SetTwoFaced() --为了让种植预览和种植后的动画旋转角度保持一致
    paw.SetAnim_xeed_wax(placer, cropdd, dd.stage, dd.form, dd.state, dd.skin, true)
    paw.SetSize_xeed_wax(placer, cropdd, dd.lvl)
end
paw.WaxCluster_xeed = function(inst, newc)
    local cropdd = CROPS_DATA_LEGION[inst.xeedkey]
    if cropdd ~= nil then
        paw.SetSize_xeed_wax(inst, cropdd, newc)
    end
end

for k, v in pairs(CROPS_DATA_LEGION) do
    local name_plant = "plant_"..k.."_l"
    paw.MakeWaxedPlant({ ------异种植株
        name = name_plant, dug_prefab = name_plant.."_item_waxed", twoface = true,
        fn_common = function(inst)
            pas.SetMiniMap(inst, "plant_crop_l", nil)
            paw.InitNet_wax(inst, "xeed", paw.OnWaxClient_xeed)

            inst.AnimState:SetBank(v.bank)
            inst.AnimState:SetBuild(v.build)
            if v.bank == "plant_normal_legion" then
                -- inst.AnimState:OverrideSymbol("dirt", "crop_soil_legion", "dirt")
            else
                inst.AnimState:OverrideSymbol("soil", "crop_soil_legion", "soil")
            end
            paw.SetAnim_xeed_wax(inst, v, 1, 1, nil, nil, false)
            paw.SetSize_xeed_wax(inst, v, 0)

            inst:AddTag("waxclusterable_l")

            inst.xeedkey = k
            inst.displaynamefn = paw.DisplayName_xeed_wax
            if skinedplant[k] then
                LS_C_Init(inst, name_plant, false, "data_wax", name_plant.."_waxed")
            end
        end,
        fn_server = function(inst)
            inst.fn_dowax = paw.DoWax_xeed
            inst.fn_waxcluster = paw.WaxCluster_xeed
        end
    })
    paw.MakeWaxedItem({ ------异种(物品)
        name = name_plant, float = { nil, "small", 0.2, 1.2 },
        fn_common = function(inst)
            paw.InitNet_wax(inst, "xeed", paw.OnWaxClient_xeed)
            pas.SetAnim(inst, "seeds_crop_l", nil, nil, nil)
            inst.xeedkey = k
            inst.fn_dowax_placer = paw.DoWaxPlacer_xeed
            inst.displaynamefn = paw.DisplayName_xeed_wax

            inst:AddTag("waxclusterable_l")

            local imgbg
            if v.image ~= nil then
                imgbg = { image = v.image.name, atlas = v.image.atlas }
            else
                imgbg = {}
            end
            if imgbg.image == nil then
                imgbg.image = k..".tex"
            end
            if imgbg.atlas == nil then
                imgbg.atlas = GetInventoryItemAtlas(imgbg.image)
            end
            inst.inv_image_bg = imgbg
        end,
        fn_server = function(inst)
            pas.SetInventoryItem(inst, "seeds_crop_l2")
            inst:AddComponent("waxclusterlegion")
        end,
        fn_deploy = function(inst, pt, deployer, rot)
            paw.OnDeploy_wax(inst, pt, deployer, rot, { prefab = name_plant.."_waxed" })
        end
    })
end

--------------------
--------------------

return unpack(prefs)

require("componentactions")
-- 动作组件检测防止崩溃
if EntityScript then
    local UnregisterComponentActions = EntityScript.UnregisterComponentActions
    local HasActionComponent = EntityScript.HasActionComponent
    local MOD_ACTION_COMPONENT_IDS = getupvalue2hm(EntityScript.RegisterComponentActions, "MOD_ACTION_COMPONENT_IDS")
    if MOD_ACTION_COMPONENT_IDS == nil then
        local CheckModComponentIds = getupvalue2hm(UnregisterComponentActions, "CheckModComponentIds") or
                                         getupvalue2hm(HasActionComponent, "CheckModComponentIds")
        MOD_ACTION_COMPONENT_IDS = CheckModComponentIds and getupvalue2hm(CheckModComponentIds, "MOD_ACTION_COMPONENT_IDS")
    end
    if MOD_ACTION_COMPONENT_IDS then
        EntityScript.UnregisterComponentActions = function(self, name, ...)
            local modactioncomponents = self.modactioncomponents
            self.modactioncomponents = nil
            UnregisterComponentActions(self, name, ...)
            self.modactioncomponents = modactioncomponents
            if self.modactioncomponents ~= nil then
                for modname, cmplist in pairs(self.modactioncomponents) do
                    local id = MOD_ACTION_COMPONENT_IDS[modname] and MOD_ACTION_COMPONENT_IDS[modname][name]
                    if id ~= nil then
                        for i, v in ipairs(cmplist) do
                            if v == id then
                                table.remove(cmplist, i)
                                if self.actionreplica ~= nil then self.actionreplica.modactioncomponents[modname]:set(cmplist) end
                                break
                            end
                        end
                    end
                end
            end
        end
        EntityScript.HasActionComponent = function(self, name, ...)
            local modactioncomponents = self.modactioncomponents
            self.modactioncomponents = nil
            local result = HasActionComponent(self, name, ...)
            self.modactioncomponents = modactioncomponents
            if result then return true end
            if self.modactioncomponents ~= nil then
                for modname, cmplist in pairs(self.modactioncomponents) do
                    local id = MOD_ACTION_COMPONENT_IDS[modname] and MOD_ACTION_COMPONENT_IDS[modname][name]
                    if id ~= nil then for i, v in ipairs(cmplist) do if v == id then return true end end end
                end
            end
            return false
        end
    end
end
-- 终极修复 replica 补丁
AddPrefabPostInit("world", function(inst)
    local ValidateReplicaComponent = EntityScript.ValidateReplicaComponent
    if inst.ismastersim or TheNet:IsDedicated() then
        function EntityScript:ValidateReplicaComponent(name, cmp) return cmp or nil end
    else
        -- 有些时候，actioncomponents有组件，但却没有该组件的replica
        function EntityScript:ValidateReplicaComponent(name, cmp)
            return ValidateReplicaComponent(self, name, cmp) or
                       ((self.components and self.components[name] ~= nil or self.userid ~= nil or self:HasActionComponent(name)) and cmp or nil)
        end
    end
end)
-- 给inventoryitem组件函数打补丁
local classifiedreplicafns = {
    inventoryitem_replica = {
        "SetPickupPos",
        "SerializeUsage",
        "SetChargeTime",
        "SetDeployMode",
        "SetDeploySpacing",
        "SetDeployRestrictedTag",
        "SetUseGridPlacer",
        "SetAttackRange",
        "SetWalkSpeedMult",
        "SetEquipRestrictedTag"
    },
    constructionsite_replica = {"SetBuilder", "SetSlotCount"}
}
for replica, replicafns in pairs(classifiedreplicafns) do
    AddClassPostConstruct("components/" .. replica, function(self)
        for _, fnname in ipairs(replicafns) do
            local fn = self[fnname]
            self[fnname] = function(self, ...) if self.classified ~= nil then return fn(self, ...) end end
        end
    end)
end
AddClassPostConstruct("components/equippable_replica", function(self)
    local IsEquipped = self.IsEquipped
    self.IsEquipped = function(self, ...)
        if self.inst.components.equippable == nil and (ThePlayer == nil or ThePlayer.replica.inventory == nil) then return false end
        return IsEquipped(self, ...)
    end
end)

-- 农场BUG修复
AddComponentPostInit("growable", function(self)
    local DoGrowth = self.DoGrowth
    self.DoGrowth = function(self, ...) if self.inst and self.inst:IsValid() then return DoGrowth(self, ...) end end
    local SetStage = self.SetStage
    self.SetStage = function(self, stage, ...)
        if self.inst and self.inst.prefab == "weed_ivy" and stage == 4 then stage = 3 end
        if SetStage then SetStage(self, stage, ...) end
    end
end)
AddComponentPostInit("farming_manager", function(self)
    local CycleNutrientsAtPoint = self.CycleNutrientsAtPoint
    self.CycleNutrientsAtPoint = function(self, x, y, z, ...)
        if not x or not z then return end
        return CycleNutrientsAtPoint(self, x, y, z, ...)
    end
end)

-- 每日时长防止崩溃
local function GetModifiedSegs(retsegs)
    local importance = {"night", "dusk", "day"}
    local total = retsegs.day + retsegs.dusk + retsegs.night
    while total ~= 16 do
        for _, k in ipairs(importance) do
            if total >= 16 and retsegs[k] > 1 then
                retsegs[k] = retsegs[k] - 1
            elseif total < 16 and retsegs[k] > 0 then
                retsegs[k] = retsegs[k] + 1
            end
            total = retsegs.day + retsegs.dusk + retsegs.night
            if total == 16 then break end
        end
    end
    return retsegs
end
AddClassPostConstruct("widgets/uiclock", function(self)
    local OnClockSegsChanged = self.OnClockSegsChanged
    function self:OnClockSegsChanged(data, ...)
        data.day = data.day or 0
        data.dusk = data.dusk or 0
        data.night = data.night or 0
        if (data.day + data.dusk + data.night) ~= 16 then data = GetModifiedSegs(data) end
        return OnClockSegsChanged(self, data, ...)
    end
end)

-- 现在单位被删除之后：无法创建新的计时器，所有计时器API置空，所有组件无法调用更新函数，从而防止无效单位崩溃
if EntityScript then
    local CancelAllPendingTasks = EntityScript.CancelAllPendingTasks
    EntityScript.CancelAllPendingTasks = function(self, ...)
        self.DoTaskInTime = nilfn
        self.DoPeriodicTask = nilfn
        self.ListenForEvent = nilfn
        self.WatchWorldState = nilfn
        -- self.AddComponent
        -- if self.pendingtasks then
        --     for k, v in pairs(self.pendingtasks) do if k and k.fn then k.fn = nilfn end end
        --     self.pendingtasks = nil
        -- end
        for k, v in pairs(self.components) do if v and type(v) == "table" and v.OnUpdate then v.OnUpdate = nilfn end end
        CancelAllPendingTasks(self, ...)
    end
end
AddPrefabPostInit("world", function(inst)
    local Map = getmetatable(inst.Map).__index
    local GetTileCenterPoint = Map.GetTileCenterPoint
    if GetTileCenterPoint ~= nil then
        Map.GetTileCenterPoint = function(self, tx, ty, ...)
            local x, y, z, t = GetTileCenterPoint(self, tx, ty, ...)
            return x or 0, y or 0, z or 0, t
        end
    end
end)

-- 滑倒组件防止崩溃
AddComponentPostInit("slipperyfeet", function(self)
    if self.OnInit then
        local OnInit = self.OnInit
        self.OnInit = function(inst) if inst.components.slipperyfeet then OnInit(inst) end end
        if self.inittask then self.inittask.fn = self.OnInit end
    end
end)

-- 死亡后禁止前往hit状态
local deathstates = {"death", "seamlessplayerswap_death"}
AddStategraphPostInit("wilson", function(sg)
    for index, state in ipairs(deathstates) do
        if sg.states[state] and sg.states[state].onenter then
            local onenter = sg.states[state].onenter
            sg.states[state].onenter = function(inst, ...)
                onenter(inst, ...)
                if inst.sg and inst.sg.GoToState then
                    local old = inst.sg.GoToState
                    inst.sg.GoToState = function(self, statename, params, ...)
                        if statename == "hit" and self.currentstate and self.currentstate.name == state then return end
                        inst.sg.GoToState = old
                        return old(self, statename, params, ...)
                    end
                end
            end
        end
    end
end)

-- 客户端游戏自动更新时防止崩溃
if GetModConfigData("ignore client error") and not TheNet:IsDedicated() then
    require("update")
    if GLOBAL.Update then
        local lastreason
        local old = GLOBAL.Update
        GLOBAL.Update = function(dt)
            if TheWorld and not TheWorld.ismastersim then
                local result, reason = pcall(function() old(dt) end)
                if not result and (TheWorld and TheWorld.errortask2hm == nil or lastreason ~= reason) then
                    if TheWorld and TheWorld.errortask2hm == nil then
                        TheWorld.errortask2hm = TheWorld:DoTaskInTime(60, function(inst) inst.errortask2hm = nil end)
                    end
                    lastreason = reason
                    if reason and type and type(reason) == "string" and print then
                        print("intercept update error:" .. reason)
                        pcall(function() if ThePlayer and ThePlayer.components.talker then ThePlayer.components.talker:Say(reason) end end)
                    end
                end
            else
                old(dt)
            end
        end
    end
end

-- 玩家标签数目扩展
local PlayerTagEntitiesNumber = GetModConfigData("player tags limit")
if TUNING.PlayerTagEntitiesNumber == nil and PlayerTagEntitiesNumber and PlayerTagEntitiesNumber > 0 then
    TUNING.PlayerTagEntitiesNumber = PlayerTagEntitiesNumber
    local ignoretags = {"DECOR", "NOCLICK"}
    local function onplayerremove(inst)
        for _, entity in ipairs(inst.tagsentities) do
            if entity:value() and entity:value():IsValid() and entity:value().realRemove then entity:value().Remove = entity:value().realRemove end
        end
    end
    local function processplayertags(inst)
        if inst.tagsentities then return end
        inst.tagsentities = {}
        for i = 1, PlayerTagEntitiesNumber, 1 do
            table.insert(inst.tagsentities, net_entity(inst.GUID, "tagsentities" .. tostring(i)))
            if TheWorld.ismastersim then
                local proxyentity = SpawnPrefab("playertagentity2hm")
                inst:AddChild(proxyentity)
                proxyentity.entity:Hide()
                proxyentity.Transform:SetPosition(0, 0, 0)
                proxyentity.infinitetags = 0
                proxyentity.realRemove = proxyentity.Remove
                proxyentity.Remove = nilfn
                inst.tagsentities[i]:set(proxyentity)
            end
        end
        -- 客户端和服务器查询标签时,先从副实体上检测标签
        local HasTag = inst.HasTag
        inst.HasTag = function(self, tag, ...)
            if not table.contains(ignoretags, tag) then
                for _, entity in ipairs(self.tagsentities) do if entity:value() and entity:value().entity:HasTag(tag) then return true end end
            end
            return HasTag(self, tag, ...)
        end
        inst.HasTags = function(self, tag, ...)
            local tags = type(tag) == "table" and tag or {tag, ...}
            for _, tag in ipairs(tags) do if not self:HasTag(tag) then return false end end
            return true
        end
        local HasOneOfTags = inst.HasOneOfTags
        inst.HasOneOfTags = function(self, tag, ...)
            local tags = type(tag) == "table" and tag or {tag, ...}
            for _, tag in ipairs(tags) do
                if not table.contains(ignoretags, tag) then
                    for _, entity in ipairs(self.tagsentities) do
                        if entity:value() and entity:value().entity:HasTag(tag) then return true end
                    end
                end
            end
            return HasOneOfTags(self, tags, ...)
        end
        inst.HasAllTags = inst.HasTags
        inst.HasAnyTag = inst.HasOneOfTags
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("onremove", onplayerremove)
        -- 客户端和服务器添加标签时,下划线开头的标签必定存放在角色本体来便于角色客户端检测replica ValidateReplicaComponent
        local AddTag = inst.AddTag
        inst.AddTag = function(self, tag, ...)
            if tag == nil or self:HasTag(tag) then return end
            if string.byte(tag, 1, 1) ~= 95 and not table.contains(ignoretags, tag) then -- 95代表字符"_"
                for _, entity in ipairs(self.tagsentities) do
                    if entity:value() and entity:value().infinitetags < 50 then
                        entity:value().infinitetags = entity:value().infinitetags + 1
                        entity:value().entity:AddTag(tag)
                        return
                    end
                end
            end
            return AddTag(self, tag, ...)
        end
        -- 客户端和服务器移除标签时
        local RemoveTag = inst.RemoveTag
        inst.RemoveTag = function(self, tag, ...)
            if tag == nil then return end
            if not table.contains(ignoretags, tag) then
                for _, entity in ipairs(self.tagsentities) do
                    if entity:value() and entity:value().entity:HasTag(tag) then
                        entity:value().infinitetags = entity:value().infinitetags - 1
                        entity:value().entity:RemoveTag(tag)
                    end
                end
            end
            return RemoveTag(self, tag, ...)
        end
        inst.AddOrRemoveTag = function(self, tag, condition, ...)
            if condition then
                self:AddTag(tag)
            else
                self:RemoveTag(tag)
            end
        end
    end
    local function processplayer(world, inst) if inst and inst:HasTag("player") then processplayertags(inst) end end
    AddPrefabPostInit("world", function(inst) inst:ListenForEvent("entity_spawned", processplayer) end)
end

-- 修复亮茄崩溃
AddStategraphPostInit("lunarthrall_plant_vine", function(sg)
    local attacked = sg.events and sg.events.attacked and sg.events.attacked.fn
    if attacked then
        sg.events.attacked.fn = function(inst)
            -- 增加判断是否有health组件
            if inst.components.health and not inst.components.health:IsDead() then
                if inst.sg:HasStateTag("caninterrupt") or not inst.sg:HasStateTag("busy") then
                    inst.sg:GoToState("hit")
                end
            end
        end
    end
end)


-- ====================================================================
-- 修复拟态蠕虫尝试复制的实体无预制体名称，SpawnPrefab传入nil或空字符串会导致崩溃
AddComponentPostInit("shadowthrall_mimics", function(self)
    if self.SpawnMimicFor then
        local old_SpawnMimicFor = self.SpawnMimicFor
        self.SpawnMimicFor = function(item)
            -- 增加nil检查，防止崩溃
            if item == nil or not item:IsValid() then
                return false
            end
            if item.prefab == nil or type(item.prefab) ~= "string" or item.prefab == "" then
                return false
            end
            return old_SpawnMimicFor(item)
        end
    end
end)

-- ====================================================================
-- 修复沃特投掷月亮投泥带时owner为nil导致崩溃
AddPrefabPostInit("wurt_terraform_projectile", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0, function(inst)
        if inst.components.complexprojectile then
            local old_Launch = inst.components.complexprojectile.Launch
            inst.components.complexprojectile.Launch = function(self, targetPos, attacker, ...)
                -- 如果attacker有inventoryitem，尝试获取其owner以确保attacker是玩家而不是投掷物本身
                if attacker and attacker.components and attacker.components.inventoryitem then
                    local owner = attacker.components.inventoryitem:GetGrandOwner()
                    if owner and owner:IsValid() then
                        attacker = owner
                    end
                end
                return old_Launch(self, targetPos, attacker, ...)
            end
        end
    end)
end)

-- ====================================================================
-- 修复影怪嘲讽丢仇恨和不可选中问题
AddStategraphPostInit("shadowcreature", function(sg)
    if not sg.states.attack then return end

    if sg.states.attack.events and sg.states.attack.events.animqueueover then
        sg.states.attack.events.animqueueover.fn = function(inst)
            inst.sg:GoToState("idle")
        end
    end
end)

-- ====================================================================
-- 修复健身房异常退出导致碰撞体积丢失（还需要进一步修改）
local GymStates = require("stategraphs/SGwilson_gymstates")
if GymStates and GymStates.AddGymStates then
    local original_AddGymStates = GymStates.AddGymStates
    GymStates.AddGymStates = function(states, actionhandlers, events)
        original_AddGymStates(states, actionhandlers, events)
        
        -- 健身状态添加busy标签
        for _, state in ipairs(states) do
            if state.name == "mighty_gym_workout_loop" or 
               state.name == "mighty_gym_active_pre" or
               state.name == "mighty_gym_success" or
               state.name == "mighty_gym_success_perfect" then
                if state.tags then
                    if not table.contains(state.tags, "busy") then
                        table.insert(state.tags, "busy")
                    end
                else
                    state.tags = {"busy"}
                end
            end
        end
    end
end

-- ====================================================================
-- 修复出生保护消失时跳船导致永久碰撞体积丢失
AddPrefabPostInit("spawnprotectionbuff", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0, function()
        if inst.OnEnableProtectionFn then
            local original_OnEnableProtectionFn = inst.OnEnableProtectionFn
            inst.OnEnableProtectionFn = function(inst, target, enable)
                if enable then
                    target:AddTag("notarget")
                    target:AddTag("spawnprotection")
                    
                    -- 保存完整的碰撞掩码供后续恢复
                    if not target._spawnprotection_saved_collision then
                        target._spawnprotection_saved_collision = bit.bor(
                            COLLISION.WORLD,
                            COLLISION.OBSTACLES,
                            COLLISION.SMALLOBSTACLES,
                            COLLISION.CHARACTERS,
                            COLLISION.GIANTS
                        )
                    end
                    
                    -- 使用ClearCollidesWith而不是SetCollisionMask，保持当前其他碰撞层
                    target.Physics:ClearCollidesWith(bit.bor(
                        COLLISION.OBSTACLES,
                        COLLISION.SMALLOBSTACLES,
                        COLLISION.CHARACTERS,
                        COLLISION.FLYERS
                    ))
                    target.AnimState:SetHaunted(true)
                else
                    target:RemoveTag("notarget")
                    target:RemoveTag("spawnprotection")
                    
                    -- 使用SetCollisionMask完全恢复碰撞，而不是CollidesWith累加
                    if target._spawnprotection_saved_collision then
                        target.Physics:SetCollisionMask(target._spawnprotection_saved_collision)
                        target._spawnprotection_saved_collision = nil
                    else
                        target.Physics:SetCollisionMask(
                            COLLISION.WORLD,
                            COLLISION.OBSTACLES,
                            COLLISION.SMALLOBSTACLES,
                            COLLISION.CHARACTERS,
                            COLLISION.GIANTS
                        )
                    end
                    target.AnimState:SetHaunted(false)
                    
                    if inst.AnimState then
                        inst.AnimState:PushAnimation("buff_pst", false)
                    end
                end
            end
        end
    end)
end)

-- 在跳船状态中，如果有出生保护，保存完整碰撞状态
AddStategraphPostInit("wilson", function(sg)
    for _, state in ipairs(sg.states) do
        if state.name == "hop_loop" and state.onenter then
            local original_onenter = state.onenter
            state.onenter = function(inst, data)
                if inst:HasTag("spawnprotection") then
                    inst.sg.statemem.collisionmask = bit.bor(
                        COLLISION.WORLD,
                        COLLISION.OBSTACLES,
                        COLLISION.SMALLOBSTACLES,
                        COLLISION.CHARACTERS,
                        COLLISION.GIANTS
                    )
                    if data ~= nil then
                        data.collisionmask = inst.sg.statemem.collisionmask
                    end
                end
                return original_onenter(inst, data)
            end
        end
    end
end)

-- ====================================================================

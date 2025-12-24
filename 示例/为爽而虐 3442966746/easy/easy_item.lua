local hardmode = TUNING.hardmode2hm


-- 哀悼之穴
if GetModConfigData("player_tomb") then
    local function SpawnGhost(x, y, z, data)
        if data then
            local ghost = SpawnPrefab("player_soul2hm")
            ghost.Transform:SetPosition(x, y, z)
            ghost.components.named:SetName(data.username)
            ghost.username = data.username
            ghost.cause = data.cause
            ghost.userid = data.userid
            ghost.afflicter = data.afflicter
            ghost.prefabName = data.prefabName
        end
    end

    local function AfterDeath(x, y, z, data)
        local ents = TheSim:FindEntities(x, y, z, 2, {"skeleton_player"}, {"skeleton_player_ghost"})
        local target, dis
        if ents then
            for _, ent in pairs(ents) do
                if ent.userid == data.userid then
                    local len = ent:GetDistanceSqToPoint(x, y, z)
                    if not target or len < dis then
                        target = ent
                        dis = len
                    end
                end
            end
        end
        if target then
            target:AddTag("skeleton_player_ghost")
            target:ListenForEvent("onremove", function()
                local x, y, z = target.Transform:GetWorldPosition()
                SpawnGhost(x, y, z, data)
            end)
            target.deadMsg = data
        else
            SpawnGhost(x, y, z, data)
        end
    end
    AddPlayerPostInit(function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("death", function(inst, data)
            data = data or {}
            local deadMsg = {
                userid = inst.userid,
                username = inst:GetDisplayName(),
                prefabName = inst.prefab,
            }
            if data.cause and type(data.cause) == "table" and data.cause.GetDisplayName then
                deadMsg.cause = data.cause:GetDisplayName()
            elseif data.cause and type(data.cause) == "string" then
                deadMsg.cause = data.cause
            else
                deadMsg.cause = "unknown"
            end
            if data.afflicter and type(data.afflicter) == "table" and data.afflicter.GetDisplayName then
                deadMsg.afflicter = data.afflicter:GetDisplayName()
            elseif data.afflicter and type(data.afflicter) == "string" then
                deadMsg.afflicter = data.afflicter
            end
            if deadMsg.userid and deadMsg.username then
                local x, y, z = inst.Transform:GetWorldPosition()
                TheWorld:DoTaskInTime(2, function()
                    AfterDeath(x, y, z, deadMsg)
                end)
            end
        end)
    end)
    local OnSave = function(inst, data)
        data.deadMsg = inst.deadMsg
    end
    local OnLoad = function(inst, data)
        inst.deadMsg = data.deadMsg
        if inst.deadMsg then
            inst:AddTag("skeleton_player_ghost")
            inst:ListenForEvent("onremove", function()
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnGhost(x, y, z, inst.deadMsg)
            end)
        end
    end
    AddPrefabPostInit("skeleton_player", function(inst)
        if not TheWorld.ismastersim then return end
        inst:AddTag("skeleton_player")
        SetOnSave(inst, OnSave)
        SetOnLoad(inst, OnLoad)
    end)
end

-- 钓具箱/超级钓具箱存放角色专属道具
if GetModConfigData("Tackle Box Can Hold Role's Item") then
    local function disabledroponopen(inst, self) if self.droponopen then self.droponopen = nil end end
    AddComponentPostInit("container", function(self)
        if self.inst:HasTag("portablestorage") then self.inst:RemoveTag("portablestorage") end
        self.inst:DoTaskInTime(0, disabledroponopen, self)
    end)
    
    -- 保护移动中打开容器内食物不受孢子云/孢子背包影响
    local spore_immune_containers = {
        ["spicepack"] = true, ["rabbitkinghorn_container"] = true,
        ["tacklestation2hm"] = true, ["shadow_container"] = true, ["alterguardianhat"] = true,
        ["mushroom_light"] = true, ["mushroom_light2"] = true, ["tacklecontainer"] = true,
        ["alterguardianhatshard"] = true, ["supertacklecontainer"] = true,
        ["skullchest_child"] = true, ["skullchest"] = true, ["beargerfur_sack"] = true,
    }
    
    local function IsItemInImmuneContainer(item)
        if item:IsInLimbo() and item.components.inventoryitem ~= nil then
            local owner = item.components.inventoryitem.owner
            if owner ~= nil and spore_immune_containers[owner.prefab] then
                return true
            end
        end
        return false
    end
    
    local function TryPerishProtected(item)
        -- 如果在免疫容器中，直接返回不腐烂
        if IsItemInImmuneContainer(item) then
            return
        end
        
        -- 否则执行原版逻辑
        if item:IsInLimbo() then
            local owner = item.components.inventoryitem ~= nil and item.components.inventoryitem.owner or nil
            if owner == nil or 
                (owner.components.container ~= nil and
                 not owner.components.container:IsOpen() and
                 owner:HasOneOfTags({"structure", "portablestorage"}))
            then
                return
            end
        end
        item.components.perishable:ReducePercent(TUNING.TOADSTOOL_SPORECLOUD_ROT)
    end
    
    local SPOIL_CANT_TAGS = {"small_livestock"}
    local SPOIL_ONEOF_TAGS = {"fresh", "stale", "spoiled"}
    local function DoAreaSpoilProtected(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, inst.components.aura.radius, nil, SPOIL_CANT_TAGS, SPOIL_ONEOF_TAGS)
        for i, v in ipairs(ents) do
            TryPerishProtected(v)
        end
    end
    
    AddPrefabPostInit("sporecloud", function(inst)
        if not TheWorld.ismastersim then return end
        if inst._spoiltask then
            inst._spoiltask:Cancel()
            inst._spoiltask = inst:DoPeriodicTask(inst.components.aura.tickperiod, DoAreaSpoilProtected, inst.components.aura.tickperiod * .5)
        end
    end)
    
    -- 兼容妥协孢子背包 
    if TUNING.DSTU then 
        local function TryPerishSporepack(item)
            -- 优先检查免疫容器
            if IsItemInImmuneContainer(item) then
                return
            end
            
            -- 执行原版逻辑
            if item:IsInLimbo() then
                local item_owner = item.components.inventoryitem ~= nil and item.components.inventoryitem.owner or nil
                if item_owner == nil or
                    (item_owner.components.container ~= nil and
                        (item_owner:HasTag("chest") or item_owner:HasTag("structure"))) then
                    return
                end
            end
            item.components.perishable:ReducePercent(0.005)
        end
        
        local function TryRefreshSporepack(item)
            -- 孢子类物品的刷新逻辑保持不变
            if item:IsInLimbo() then
                local item_owner = item.components.inventoryitem ~= nil and item.components.inventoryitem.owner or nil
                if item_owner == nil or
                    (item_owner.components.container ~= nil and
                        (item_owner:HasTag("chest") or item_owner:HasTag("structure"))) then
                    return
                end
            end
            item.components.perishable:ReducePercent(-0.005)
        end
        
        local function DoAreaSpoilProtectedSporepack(owner)
            local x, y, z = owner.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 3, nil, {"small_livestock"}, {"fresh", "stale", "spoiled", "spore", "spore_special"})
            for i, v in ipairs(ents) do
                if v:HasTag("spore") or v:HasTag("spore_special") then
                    TryRefreshSporepack(v)
                else
                    TryPerishSporepack(v)
                end
            end
        end
        
        -- 装备孢子背包时替换任务
        AddPlayerPostInit(function(inst)
            if not TheWorld.ismastersim then return end
            
            inst:ListenForEvent("equip", function(inst, data)
                if data and data.item and data.item.prefab == "sporepack" then
                    inst:DoTaskInTime(0, function()
                        if inst.sporespoil_task then
                            inst.sporespoil_task:Cancel()
                            inst.sporespoil_task = inst:DoPeriodicTask(3, DoAreaSpoilProtectedSporepack)
                        end
                    end)
                end
            end)
        end)
    end

    -- TUNING.SEEDPOUCH_PRESERVER_RATE = 0
    local function perish_rate_multiplier(inst, item) return item and (item:HasTag("spider") or item:HasTag("spore")) and 0 or 1 end
    local function TackleBoxCanHoldRolesItem(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.preserver == nil then
            inst:AddComponent("preserver")
            inst.components.preserver:SetPerishRateMultiplier(perish_rate_multiplier)
        end
    end
    AddPrefabPostInit("tacklecontainer", TackleBoxCanHoldRolesItem)
    AddPrefabPostInit("supertacklecontainer", TackleBoxCanHoldRolesItem)
    local containers = require("containers")
    local specialitems = {"lucy", "ghostflower", "scandata", "spear_wathgrithr_lightning_charged"}
    if containers and containers.params and containers.params.tacklecontainer and containers.params.supertacklecontainer then
        local olditemtestfn = containers.params.tacklecontainer.itemtestfn
        local newitemtestfn = function(container, item, slot)
            return item.prefab ~= nil and
                       ((AllRecipes[item.prefab] ~= nil and AllRecipes[item.prefab].builder_tag ~= nil) or
                           table.contains(CRAFTING_FILTERS.CHARACTER.recipes, item.prefab) or item:HasTag("spider") or item:HasTag("spore") or
                           table.contains(specialitems, item.prefab)) and (container.containeritem2hm or not (item.replica and item.replica.container))
        end
        containers.params.tacklecontainer.itemtestfn = function(container, item, slot)
            return olditemtestfn == nil or olditemtestfn(container, item, slot) or newitemtestfn(container, item, slot)
        end
        containers.params.supertacklecontainer.itemtestfn = containers.params.tacklecontainer.itemtestfn
    end
    AddComponentPostInit("pocketwatch_dismantler", function(self)
        local oldDismantle = self.Dismantle
        self.Dismantle = function(self, target, doer, ...)
            local owner = target.components.inventoryitem:GetGrandOwner()
            if owner == nil then return end
            return oldDismantle(self, target, doer, ...)
        end
    end)
end

-- 作祟救赎的心复活
if GetModConfigData("Haunt Telltale Heart To Revive") then
    local function OnHauntFn(inst, haunter)
        if haunter.components.health then haunter.components.health:DeltaPenalty(TUNING.REVIVE_HEALTH_PENALTY) end
        inst:Hide()
        inst.persists = false
        inst:DoTaskInTime(5, inst.Remove)
        return true
    end
    AddPrefabPostInit("reviver", function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.hauntable then inst:AddComponent("hauntable") end
        inst.components.hauntable:SetOnHauntFn(OnHauntFn)
        inst.components.hauntable:SetOnUnHauntFn(inst.Remove)
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)
    end)
    AddComponentPostInit("hauntable", function(self)
        local DoHaunt = self.DoHaunt
        self.DoHaunt = function(self, doer, ...)
            if self.inst:IsValid() and self.inst.components.container then
                local item = self.inst.components.container:FindItem(function(item)
                    return item and item:IsValid() and item.components.hauntable and item.components.hauntable.hauntvalue == TUNING.HAUNT_INSTANT_REZ
                end)
                if item then
                    self.inst.components.container:DropItem(item)
                    return DoHaunt(self, doer, ...)
                end
            end
            DoHaunt(self, doer, ...)
        end
    end)
    local ex_fns = require "prefabs/player_common_extensions"
    local OnRespawnFromGhost = ex_fns.OnRespawnFromGhost
    ex_fns.OnRespawnFromGhost = function(inst, data, ...)
        OnRespawnFromGhost(inst, data, ...)
        if data then inst.rezsource2hm = (data.user and data.user:GetDisplayName()) or (data.source and data.source:GetBasicDisplayName()) end
    end
    require "widgets/eventannouncer"
    local GetNewRezAnnouncementString = GLOBAL.GetNewRezAnnouncementString
    GLOBAL.GetNewRezAnnouncementString = function(theRezzed, source, ...)
        if theRezzed and (source == STRINGS.NAMES.SHENANIGANS or source == nil) and theRezzed.rezsource2hm then source = theRezzed.rezsource2hm end
        theRezzed.rezsource2hm = nil
        return GetNewRezAnnouncementString(theRezzed, source, ...)
    end
    local function processskeleton(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.lootdropper then
            inst.components.lootdropper.min_speed = 2.5
            inst.components.lootdropper.max_speed = 4
        end
    end
    AddPrefabPostInit("skeleton", processskeleton)
    AddPrefabPostInit("skeleton_player", processskeleton)
end

-- 自动航行的暗影船
if GetModConfigData("boat use shadowheart upgrade") then
    -- 客户端暗影船血量显示
    AddClassPostConstruct("widgets/boatmeter", function(self)
        local RefreshHealth = self.RefreshHealth
        self.RefreshHealth = function(self, ...)
            if self.boat and self.boat:IsValid() and self.boat:HasTag("shadowboathealth2hm") and self.boat.components.healthsyncer and
                not self.boat.components.healthsyncer.processd2hm then
                self.boat.components.healthsyncer.processd2hm = true
                self.boat.components.healthsyncer.max_health = self.boat.components.healthsyncer.max_health * 4
            end
            RefreshHealth(self, ...)
        end
    end)
    -- 暗影船自动修漏洞
    local function delayrepairleak(leak)
        if leak and leak:IsValid() and leak:HasTag("boat_leak") and leak.components.boatleak then
            if leak.components.boatleak.current_state == "med_leak" then
                leak.components.boatleak:SetState("small_leak")
                leak:DoTaskInTime(10, delayrepairleak)
            else
                leak.AnimState:SetMultColour(0.75, 0.75, 0.75, 0.75)
                leak.components.boatleak:SetState("repaired_treegrowth")
            end
        end
    end
    local function tryinstrepairleak(inst)
        if inst.components.boatleak and inst.components.boatleak.boat and inst.components.boatleak.boat:IsValid() and
            inst.components.boatleak.boat:HasTag("shadowboat2hm") and not inst.repair2hm then
            inst.repair2hm = true
            inst:DoTaskInTime(10, delayrepairleak)
        end
    end
    AddPrefabPostInit("boat_leak", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.boatleak then inst:DoTaskInTime(0, tryinstrepairleak) end
    end)
    local function onspawnnewboatleak(inst, data)
        if inst.prefab == "boat_grass" and data and data.leak_size then
            local damage = TUNING.BOAT.GRASSBOAT_LEAK_DAMAGE[data.leak_size]
            if damage ~= nil then inst.components.health:DoDelta(damage / 2) end
        elseif inst.components.hullhealth then
            for index, leak in pairs(inst.components.hullhealth.leak_indicators) do
                if leak and leak:IsValid() and not leak.repair2hm then
                    leak.repair2hm = true
                    leak:DoTaskInTime(10, delayrepairleak)
                end
            end
            for index, leak in pairs(inst.components.hullhealth.leak_indicators_dynamic) do
                if leak and leak:IsValid() and not leak.repair2hm then
                    leak.repair2hm = true
                    leak:DoTaskInTime(10, delayrepairleak)
                end
            end
        end
    end
    local function delayonspawnnewboatleak(inst, data) inst:DoTaskInTime(0, onspawnnewboatleak, data) end
    -- 升级后自动修甲板和漏洞,并定位暗影舵
    local function repairandfindsteeringwheel(inst)
        if inst.components.hullhealth then
            for index, leak in pairs(inst.components.hullhealth.leak_indicators) do
                if leak and leak:IsValid() and not leak.repair2hm then
                    leak.repair2hm = true
                    leak:DoTaskInTime(10, delayrepairleak)
                end
            end
            for index, leak in pairs(inst.components.hullhealth.leak_indicators_dynamic) do
                if leak and leak:IsValid() and not leak.repair2hm then
                    leak.repair2hm = true
                    leak:DoTaskInTime(10, delayrepairleak)
                end
            end
        end
        -- 暗影舵
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 4, {"steeringwheel"})
        if ents and #ents > 0 then
            for i, ent in ipairs(ents) do
                if ent and ent:IsValid() and ent.components.steeringwheel and ent:GetCurrentPlatform() == inst and not ent.isshadowsail2hm then
                    ent.isshadowsail2hm = true
                    ent.AnimState:SetMultColour(0.75, 0.75, 0.75, 1)
                end
            end
        end
        -- 暗影船甲板保护自动修理
        if inst.components.boatring then
            for index, boatbumper in ipairs(inst.components.boatring.boatbumpers) do
                if boatbumper and boatbumper:IsValid() and boatbumper.components.health and not boatbumper.components.health:IsDead() then
                    boatbumper.components.health:StartRegen(1, 20)
                end
            end
        end
    end
    -- 把船变成暗影船,血量提高,开始自愈
    local function makeboatshadowsail(inst)
        inst.AnimState:SetMultColour(0.75, 0.75, 0.75, 0.75)
        inst:AddTag("shadowboat2hm")
        if inst.components.health then
            local max = inst.components.health.maxhealth
            if max == TUNING.BOAT.HEALTH or (TUNING.BOAT.ANCIENT_BOAT and max == TUNING.BOAT.ANCIENT_BOAT.HEALTH) then
                inst:AddTag("shadowboathealth2hm")
                inst.components.health.maxhealth = max * 4
                if inst.components.healthsyncer then inst.components.healthsyncer.max_health = inst.components.health.maxhealth end
                inst.components.health:DoDelta(max * 3)
            end
            inst.components.health:StartRegen(1, 10)
        end
        -- 草船不再持续损坏
        if inst.components.hullhealth then inst.components.hullhealth:SetSelfDegrading(0) end
        -- 甲板添加时自动自愈
        if inst.components.boatring then
            local AddBumper = inst.components.boatring.AddBumper
            inst.components.boatring.AddBumper = function(self, bumper, ...)
                AddBumper(self, bumper, ...)
                if bumper and bumper:IsValid() and bumper.components.health and not bumper.components.health:IsDead() then
                    bumper.components.health:StartRegen(1, 20)
                end
            end
        end
        -- 漏洞出现时自动修复
        inst:ListenForEvent("spawnnewboatleak", delayonspawnnewboatleak)
        if inst.sinkloot then
            local oldsinkloot = inst.sinkloot
            inst.sinkloot = function(...)
                oldsinkloot(...)
                local x, y, z = inst.Transform:GetWorldPosition()
                local heart = SpawnPrefab("shadowheart")
                heart.Transform:SetPosition(x, y, z)
                heart.disableupgrade2hm = true
                heart:DoTaskInTime(240, function() if heart.disableupgrade2hm then heart.disableupgrade2hm = nil end end)
            end
        end
        inst:DoTaskInTime(0, repairandfindsteeringwheel)
    end
    -- 加载暗影船
    local function processpersistent(inst, data) if data and data.shadowsail then makeboatshadowsail(inst) end end
    local boats = {"boat", "boat_grass", "boat_pirate", "dragonboat_body", "boat_ancient", "boat_otterden"}
    for _, boat in ipairs(boats) do
        AddPrefabPostInit(boat, function(inst)
            if not TheWorld.ismastersim then return end
            if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
            inst.onload2hm = processpersistent
        end)
    end
    -- 黑心落到船上后,会升级船为暗影船,并产生升级特效
    local function processplatform(inst)
        if inst and inst:IsValid() and not inst.disableupgrade2hm then
            local platform = inst:GetCurrentPlatform()
            if platform and platform:IsValid() and platform.components.health and not platform.components.health:IsDead() and
                table.contains(boats, platform.prefab) and not platform:HasTag("shadowboat2hm") and not platform.components.vanish_on_sleep then
                platform.components.persistent2hm.data.shadowsail = true
                makeboatshadowsail(platform)
                inst:Remove()
                TUNING.disablepillarreticuleonce2hm = true
                local spell = SpawnPrefab("mod_hardmode_shadow_pillar_spell")
                TUNING.disablepillarreticuleonce2hm = nil
                spell.caster = platform
                spell.disablepillar = true
                local x, y, z = platform.Transform:GetWorldPosition()
                spell.entity:SetParent(platform.entity)
                spell.Transform:SetPosition(platform.entity:WorldToLocalSpace(x, y, z))
            end
        end
    end
    local function ondropped(inst) inst:DoTaskInTime(0, processplatform) end
    AddPrefabPostInit("shadowheart", function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("ondropped", ondropped)
    end)
    -- 暗影船自动航行,玩家下船后解除自动航行
    local function autoshadowsail(inst)
        if not (inst.components.boatphysics and inst.shadowsailor2hm and not inst.shadowsailor2hm:HasTag("playerghost") and
            inst.shadowsailor2hm:GetCurrentPlatform() == inst) then
            if inst.shadowsailor2hm and inst.shadowsailor2hm:IsValid() and inst.shadowsailor2hm.components.talker and
                not inst.shadowsailor2hm:HasTag("playerghost") then
                inst.shadowsailor2hm.components.talker:Say((TUNING.isCh2hm and "我似乎失去了什么" or "I seem to have lost something"))
            end
            inst.shadowsailor2hm = nil
            if inst.shadowwalktask2hm then
                inst.shadowwalktask2hm:Cancel()
                inst.shadowwalktask2hm = nil
            end
            return
        end
        if inst.components.boatphysics.steering_rotate then return end
        local pos = Vector3(inst.Transform:GetWorldPosition())
        local doer_x, doer_y, doer_z = inst.shadowsailor2hm.Transform:GetWorldPosition()
        local row_dir_x, row_dir_z = doer_x - pos.x, doer_z - pos.z
        if math.abs(row_dir_x) < 0.8 and math.abs(row_dir_z) < 0.8 then return end
        local character_force_mult = inst.shadowsailor2hm.components.expertsailor ~= nil and
                                         inst.shadowsailor2hm.components.expertsailor:GetRowForceMultiplier() or 1
        local character_extra_max_velocity = inst.shadowsailor2hm.components.expertsailor ~= nil and
                                                 inst.shadowsailor2hm.components.expertsailor:GetRowExtraMaxVelocity() or 0
        inst.components.boatphysics:ApplyRowForce(row_dir_x, row_dir_z, 0.3 * character_force_mult, 2 + character_extra_max_velocity)
        inst.components.boatphysics:SetTargetRudderDirection(row_dir_x, row_dir_z)
    end
    -- 首次操作船舵时会获得船只权限,拥有权限的人在船上走动会操控舵的坐标,再次操作则会失去权限
    local function resetboatsailor(inst, platform, sailor)
        if inst.components.steeringwheel.sailor ~= sailor then return end
        platform.shadowsailor2hm = sailor
        inst.components.steeringwheel:StopSteering()
        sailor.components.steeringwheeluser:SetSteeringWheel(nil)
        sailor:PushEvent("stop_steering_boat")
        if sailor.sg then sailor.sg:GoToState("changeoutsidewardrobe") end
        if not platform.shadowwalktask2hm then platform.shadowwalktask2hm = platform:DoPeriodicTask(0.25, autoshadowsail) end
    end
    -- 暗影船上的船舵有特殊特效,可以通过船舵激活自动航行或关闭自动航行
    local function checksteeringwheel(inst, self)
        if not inst:IsValid() then return end
        if not inst.isshadowsail2hm then
            local platform = inst:GetCurrentPlatform()
            if platform and platform:HasTag("shadowboat2hm") then
                inst.isshadowsail2hm = true
                inst.AnimState:SetMultColour(0.75, 0.75, 0.75, 1)
            end
        end
        local oldonstartfn = self.onstartfn
        self.onstartfn = function(inst, sailor, ...)
            oldonstartfn(inst, sailor, ...)
            local platform = inst:GetCurrentPlatform()
            if inst.isshadowsail2hm and platform and platform:HasTag("shadowboat2hm") and sailor and sailor:HasTag("player") then
                if platform.shadowsailor2hm ~= sailor then
                    inst:DoTaskInTime(0, resetboatsailor, platform, sailor)
                elseif platform.shadowsailor2hm == sailor then
                    platform.shadowsailor2hm = nil
                    if sailor and sailor.components.talker then
                        sailor.components.talker:Say((TUNING.isCh2hm and "我似乎失去了什么" or "I seem to have lost something"))
                    end
                end
            end
        end
    end
    AddComponentPostInit("steeringwheel", function(self) self.inst:DoTaskInTime(0, checksteeringwheel, self) end)
    -- -- 隐藏船只,船只上的单位一并隐藏
    -- local function hideboat(inst)
    --     if inst.components.persistent2hm.data.platformfollowers then return end
    --     inst.components.persistent2hm.data.platformfollowers = {}
    --     if inst.components.walkableplatform then inst.components.walkableplatform:SetEntitiesOnPlatform() end
    --     if inst.platformfollowers then
    --         local shore_pt
    --         for k, v in pairs(inst.platformfollowers) do
    --             if k and k:IsValid() and k.GUID and k ~= inst then
    --                 if k:HasTag("ignorewalkableplatformdrowning") or k:HasTag("player") then
    --                     if k.components.drownable ~= nil then
    --                         if shore_pt == nil then
    --                             shore_pt = Vector3(FindRandomPointOnShoreFromOcean(inst.Transform:GetWorldPosition()))
    --                         end
    --                         k:PushEvent("onsink", {boat = inst, shore_pt = shore_pt})
    --                     else
    --                         k:PushEvent("onsink", {boat = inst})
    --                     end
    --                     inst:RemovePlatformFollower(k)
    --                 else
    --                     k:RemoveFromScene()
    --                     inst:RemovePlatformFollower(k)
    --                     table.insert(inst.components.persistent2hm.data.platformfollowers, k.GUID)
    --                 end
    --             end
    --         end
    --     end
    --     if inst.components.walkableplatform then inst.components.walkableplatform:StopUpdating() end
    --     if inst.components.boatphysics then inst.components.boatphysics:StopUpdating() end
    --     if inst.OnPhysicsSleep then inst:OnPhysicsSleep() end
    --     if inst.stopupdatingtask then
    --         inst.stopupdatingtask:Cancel()
    --         inst.stopupdatingtask = nil
    --     end
    --     inst:RemoveFromScene()
    -- end
end

-- 橙宝石升级牛铃铛收和放, 牛死后救赎之心复活，阴郁铃铛复活成本减少
if GetModConfigData("beef_bell use orangegem upgrade") then
    local easing = require("easing")

    TUNING.BELL_COOLDOWN_TIME_2HM = 15                  -- 收和放冷却15秒
    TUNING.REVIVE_HEALTH_PERCENT_2HM = 0.1              -- 复活血量10%
    TUNING.SHADOW_BEEF_BELL_CURSE_HEALTH_PENALTY = 0.2  -- 扣血上限50%→20%
    TUNING.SHADOW_BEEF_BELL_CURSE_SANITY_DELTA = 0      -- 扣理智100→0
    TUNING.SHADOW_BEEF_BELL_REVIVE_COOLDOWN = 0         -- 移除复活冷却
    
    -- 升级牛铃绑定的牛禁用掉落物
    local function beefalo_nodrop(beefalo)
        if beefalo.components.lootdropper then
            beefalo.components.lootdropper:SetLoot()
            beefalo.components.lootdropper:SetChanceLootTable()
            beefalo.components.lootdropper.SpawnLootPrefab = nillootdropperSpawnLootPrefab
            beefalo.components.lootdropper.GenerateLoot = emptytablefn
            beefalo.components.lootdropper.DropLoot = emptytablefn
        end
        if beefalo.components.writeable then 
            beefalo.components.writeable:SetOnWritingEndedFn() 
        end
    end

    -- 升级后牛铃的绑定动作
    local function upgraded_bell_use_handler(inst, target, user)
        if inst.components.useabletargeteditem then 
            inst.components.useabletargeteditem.inuse_targeted = true 
        end
        
        if inst:GetBeefalo() then
            return false, "BEEF_BELL_HAS_BEEF_ALREADY"
        end
        
        if inst.original_use_handler then
            return inst.original_use_handler(inst, target, user)
        end
        return false
    end

    -- 升级后牛铃的右键动作
    local function upgraded_bell_stop_handler(inst)

        if inst.components.rechargeable ~= nil and not inst.components.rechargeable:IsCharged() then
            return false
        end
        
        local beefalo = inst:GetBeefalo()
        -- 有牛时收回牛
        if beefalo then 
            if beefalo.components.rideable.rider then 
                beefalo.components.rideable.rider.components.rider:ActualDismount() 
            end

            if beefalo.components.health:IsDead() then
                local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
                if owner and owner.components.talker then
                    owner.components.talker:Say(TUNING.isCh2hm and "牛牛还躺着呢" or "it is waiting god's help")
                end
                return false
            end

            -- 添加保护标签防止牛鞍操作
            beefalo:AddTag("being_recalled_by_bell")
            
            local data = {}
            if beefalo.components.skinner_beefalo then
                data.clothing = beefalo.components.skinner_beefalo:GetClothing()
            end

            data.beef_record = beefalo:GetSaveRecord()
            inst.components.persistent2hm.data.beefalo = data
            
            beefalo._marked_for_despawn = true
            beefalo:PushEvent("despawn")
            
            if inst:HasTag("hasbeefalo2hm") then inst:RemoveTag("hasbeefalo2hm") end
            
            inst.components.rechargeable:Discharge(TUNING.BELL_COOLDOWN_TIME_2HM)
            if inst.components.useabletargeteditem then 
                inst.components.useabletargeteditem.inuse_targeted = true 
            end
            return 
        end
        
        -- 无牛有存档则召唤已保存的牛
        if inst.components.persistent2hm.data.beefalo then
            local beef_data = inst.components.persistent2hm.data.beefalo
            if beef_data.beef_record then
                local beef = SpawnSaveRecord(beef_data.beef_record)
                if beef then
                    inst.components.useabletargeteditem:StartUsingItem(beef)
                    inst:AddTag("hasbeefalo2hm")
                    
                    beefalo_nodrop(beef)

                    beef.Transform:SetPosition(inst.Transform:GetWorldPosition())

                    beef:DoTaskInTime(0, function(beef)
                        if beef_data.clothing and beef.components.skinner_beefalo then 
                            beef.components.skinner_beefalo:SetClothing(beef_data.clothing)
                        end
                    end)

                    inst.components.persistent2hm.data.beefalo = nil
                    inst.components.rechargeable:Discharge(TUNING.BELL_COOLDOWN_TIME_2HM)
                    if inst.components.useabletargeteditem then 
                        inst.components.useabletargeteditem.inuse_targeted = true 
                    end
                    return
                end
            end
        end
        -- 无牛也无数据
        local owner = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner()
        if owner and owner.components.talker then
            owner.components.talker:Say(TUNING.isCh2hm and "没有绑定的牛牛" or "No beefalo bound")
        end

        inst:CleanUpBell()
        inst:RemoveTag("hasbeefalo2hm")
        inst.components.persistent2hm.data.beefalo = nil
    end

    -- 普通牛铃绑定的牛尸体清理
    local function cleanup_dead_beefalo(beefalo)
        if not beefalo or not beefalo:IsValid() then return end
        
        beefalo.persists = false
        
        if beefalo:HasTag("NOCLICK") then
            return
        end

        beefalo:AddTag("NOCLICK")
        RemovePhysicsColliders(beefalo)

        if beefalo.DynamicShadow ~= nil then
            beefalo.DynamicShadow:Enable(false)
        end

        local multcolor = beefalo.AnimState:GetMultColour()
        local ticktime = TheSim:GetTickTime()
        local erodetime = 5

        beefalo:StartThread(function()
            local ticks = 0
            while beefalo:IsValid() and (ticks * ticktime < erodetime) do
                local n = ticks * ticktime / erodetime
                local alpha = easing.inQuad(1 - n, 0, 1, 1)
                local color = 1 - (n * 5)
                local color = math.min(multcolor, color)

                beefalo.AnimState:SetErosionParams(n, .05, 1.0)
                beefalo.AnimState:SetMultColour(color, color, color, math.max(.3, alpha))
                ticks = ticks + 1
                Yield()
            end
            beefalo:Remove()
        end)
    end
    
    -- 应用升级给牛铃
    local function apply_bell_upgrade(bell)
        local beefalo = bell:GetBeefalo()
        if beefalo then 
            beefalo_nodrop(beefalo)
            bell:AddTag("hasbeefalo2hm")
        end

        if bell.components.useabletargeteditem then
            if not bell.original_use_handler then
                bell.original_use_handler = bell.components.useabletargeteditem.onusefn
            end
            -- 替换右键动作
            bell.components.useabletargeteditem:SetOnUseFn(upgraded_bell_use_handler)
            bell.components.useabletargeteditem:SetOnStopUseFn(upgraded_bell_stop_handler)
        end
        
        bell.components.persistent2hm.data.upgraded = true
        bell:AddTag("upgraded_bell")
        
        if bell.components.useabletargeteditem then 
            bell.components.useabletargeteditem.inuse_targeted = true 
        end

        if bell.clientupgrade2hm then
            bell.clientupgrade2hm:set(true)
        end
    end

    STRINGS.ACTIONS.STOPUSINGITEM.SHOWBEEF2HM = TUNING.isCh2hm and "召唤" or "Out"
    STRINGS.ACTIONS.STOPUSINGITEM.HIDEBEEF2HM = TUNING.isCh2hm and "收回" or "In"
    local oldSTOPUSINGITEMstrfn = ACTIONS.STOPUSINGITEM.strfn

    ACTIONS.STOPUSINGITEM.strfn = function(act)
        local res = oldSTOPUSINGITEMstrfn(act)
        if res == "BEEF_BELL" and act.invobject and act.invobject.prefab == "beef_bell" and act.invobject:HasTag("upgraded_bell") then
            return act.invobject:HasTag("hasbeefalo2hm") and "HIDEBEEF2HM" or "SHOWBEEF2HM"
        elseif res == "SHADOW_BEEF_BELL" and act.invobject and act.invobject.prefab == "shadow_beef_bell" and act.invobject:HasTag("upgraded_bell") then
            return act.invobject:HasTag("hasbeefalo2hm") and "HIDEBEEF2HM" or "SHOWBEEF2HM"
        end
        return res
    end

    local function itemtilefn(inst, self)
        if inst:HasTag("upgraded_bell") then
            if not inst.bgimage2hm then
                inst.bgimage2hm = "orangegem.tex"
                inst.bgaltas2hm = GetInventoryItemAtlas(inst.bgimage2hm)
            end
        end
        return "upgrade2hmdirty", nil, inst.bgaltas2hm, inst.bgimage2hm
    end
    
    -- 初始化牛铃
    local function process_bell(bell, is_shadow_bell)

        bell.itemtilefn2hm = itemtilefn
        bell.clientupgrade2hm = net_bool(bell.GUID, "bell.upgrade2hm", "upgrade2hmdirty")
        bell.clientupgrade2hm:set(false)

        if not TheWorld.ismastersim then return end
        
        if not bell.components.rechargeable then bell:AddComponent("rechargeable") end

        bell.components.rechargeable:SetOnDischargedFn(function(inst) 
            inst:AddTag("oncooldown") 
            if inst.components.useabletargeteditem then 
                inst.components.useabletargeteditem.inuse_targeted = false 
            end
        end)

        bell.components.rechargeable:SetOnChargedFn(function(inst) 
            inst:RemoveTag("oncooldown") 
            if inst.components.useabletargeteditem then 
                inst.components.useabletargeteditem.inuse_targeted = true 
            end
        end)
        
        -- 橙宝石升级
        if not bell.components.trader then bell:AddComponent("trader")  end
        bell.components.trader.acceptnontradable = true

        bell.components.trader:SetAbleToAcceptTest(function(inst, item)
            return item.prefab == "orangegem" and not inst:HasTag("upgraded_bell")
        end)

        bell.components.trader.onaccept = function(inst, giver, item)
            if item.prefab == "orangegem" then
                giver.SoundEmitter:PlaySound("aqol/new_test/gem")
                apply_bell_upgrade(inst)
                return true
            end
            return false
        end
        
        if not bell.components.persistent2hm then bell:AddComponent("persistent2hm") end
        
        bell:DoTaskInTime(0, function()
            if bell.components.persistent2hm.data.upgraded then
                apply_bell_upgrade(bell)
                local basename = bell:GetSkinName() or bell.prefab
                bell.components.inventoryitem:ChangeImageName(basename.."_linked")
                bell.AnimState:PlayAnimation("idle2", true)
                bell:AddTag("nobundling")
            end
        end)
        
        local original_handler = bell.components.useabletargeteditem.onusefn
        bell.components.useabletargeteditem:SetOnUseFn(function(inst, target, user)
            local successful, failreason = original_handler(inst, target, user)
            
            -- 如果牛铃已升级，自动应用升级功能
            if successful and inst:HasTag("upgraded_bell") then
                local beefalo = inst:GetBeefalo()
                if beefalo then 
                    beefalo_nodrop(beefalo)
                    inst:AddTag("hasbeefalo2hm")
                    
                    if not inst.original_use_handler then
                        inst.original_use_handler = original_handler
                        inst.components.useabletargeteditem:SetOnUseFn(upgraded_bell_use_handler)
                        inst.components.useabletargeteditem:SetOnStopUseFn(upgraded_bell_stop_handler)
                    end
                end
                
                if inst.components.useabletargeteditem then 
                    inst.components.useabletargeteditem.inuse_targeted = true 
                end
            end
            return successful, failreason
        end)
        
        -- 减少阴郁牛铃复活惩罚
        if is_shadow_bell then
            if bell.ReviveTarget then
                bell.ReviveTarget = function(inst, target, doer)
                    target:OnRevived(inst)
                    if target.components.health then
                        target.components.health:SetPercent(TUNING.REVIVE_HEALTH_PERCENT_2HM)
                    end
                    doer:AddDebuff("shadow_beef_bell_curse", "shadow_beef_bell_curse")
                end
            end
            
            if bell.DoCurseEffects then
                bell.DoCurseEffects = function(inst, target)
                    target.components.health:DeltaPenalty(TUNING.SHADOW_BEEF_BELL_CURSE_HEALTH_PENALTY)
                    
                    if not target.components.health:IsDead() and not inst.loading then
                        target:PushEvent("consumehealthcost")
                        target:ShakeCamera(CAMERASHAKE.VERTICAL, .5, .025, .15, target, 16)
                    end
                end
            end
        end

        bell:ListenForEvent("onremove", function(inst)
            local beefalo = inst:GetBeefalo()
            if beefalo and beefalo:IsValid() and beefalo.components.health:IsDead() then
                cleanup_dead_beefalo(beefalo)
            end
        end)
    end
    
    AddPrefabPostInit("beef_bell", function(inst)
        process_bell(inst, false)
    end)
    
    AddPrefabPostInit("shadow_beef_bell", function(inst)
        process_bell(inst, true)
    end)

    -- 绑定了牛铃的牛死亡后保留尸体
    AddPrefabPostInit("beefalo", function(inst)
        if not TheWorld.ismastersim then return end
        
        local original_SetBeefBellOwner = inst.SetBeefBellOwner
        inst.SetBeefBellOwner = function(inst, bell, bell_user)
            local success, reason = original_SetBeefBellOwner(inst, bell, bell_user)
            if success and bell then
                -- 升级铃铛：移除死亡监听、保留尸体、禁止燃烧
                if not bell:HasTag("shadowbell") then
                    bell:RemoveEventCallback("death", bell.components.leader._onfollowerdied, inst)
                    if inst.components.burnable ~= nil then
                        inst.components.burnable.nocharring = true
                    end
                end
            end
            return success, reason
        end

        inst.ShouldKeepCorpse = function(inst)
            local leader = inst.components.follower:GetLeader()
            return leader ~= nil and leader:HasTag("bell")
        end
        
        local old_OnSave = inst.OnSave
        inst.OnSave = function(inst, data)
            if old_OnSave then
                old_OnSave(inst, data)
            end
            if inst:ShouldKeepCorpse() and inst.components.health:IsDead() then
                data.beef_bell_dead = true
            end
        end
        
        local old_OnLoad = inst.OnLoad  
        inst.OnLoad = function(inst, data)

            local is_dead_beef = data and data.beef_bell_deads
            
            if old_OnLoad then old_OnLoad(inst, data) end
            
            -- 死牛加载完成后，确保保持死亡状态
            if is_dead_beef and inst:IsValid() then
                inst:DoTaskInTime(0, function()
                    if inst:IsValid() and inst.sg then
                        if inst.sg.GoToState then
                            inst.sg:GoToState("death")
                        end
                    end
                end)
            end
        end
        
        -- 拦截牛鞍操作，防止收回时刷物资
        if inst.components.rideable then
            local original_SetSaddle = inst.components.rideable.SetSaddle
            inst.components.rideable.SetSaddle = function(self, doer, newsaddle)
                if inst:HasTag("being_recalled_by_bell") then
                    return 
                end
                return original_SetSaddle(self, doer, newsaddle)
            end
        end
    end)

    -- 救赎之心可以复活牛
    AddPrefabPostInit("reviver", function(inst)
        if not TheWorld.ismastersim then return end
        
        local function CanReviveTarget(inst, target, doer)
            return target.GetBeefBellOwner ~= nil and target:GetBeefBellOwner() == doer
        end
        
        local function Reviver_ReviveTarget(inst, target, doer)
            target:OnRevived(inst)

            if target.components.health then
                target.components.health:SetPercent(TUNING.REVIVE_HEALTH_PERCENT_2HM)
            end

            target.SoundEmitter:PlaySound("dontstarve/ghost/player_revive")
            
            inst:DoTaskInTime(0, inst.Remove)
            if doer then 
                doer:ShakeCamera(CAMERASHAKE.VERTICAL, .5, .025, .15, doer, 16) 
            end
        end
        
        inst.CanReviveTarget = CanReviveTarget
        inst.ReviveTarget = Reviver_ReviveTarget
    end)
end

-- 视界拓展套件
if GetModConfigData("Horizon Expandinator") then
    TUNING.SCRAP_MONOCLE_EXTRA_VIEW_DIST = 50 -- 原版为20


    local function process_upgrade(inst)
        inst:AddTag("horizon2hm")

        local _OnEquip = inst.components.equippable.onequipfn
        local _OnUnequip = inst.components.equippable.onunequipfn

        inst.components.equippable.onequipfn = function(inst, owner)
            if owner.isplayer then
                owner:AddCameraExtraDistance(inst, TUNING.SCRAP_MONOCLE_EXTRA_VIEW_DIST)
            end
            if _OnEquip then _OnEquip(inst, owner) end
        end

        inst.components.equippable.onunequipfn = function(inst, owner)
            if owner.isplayer then
                owner:RemoveCameraExtraDistance(inst)
            end
            if _OnUnequip then _OnUnequip(inst, owner) end
        end
        -- 拆解时返还
        inst:ListenForEvent("ondeconstructstructure", function(inst, caster)
            local item = SpawnPrefab("scrap_monoclehat")
            if caster and caster.components.inventory then
                if item then
                    caster.components.inventory:GiveItem(item, nil, caster:GetPosition())
                end
            else
                item.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
        end)
    end

    local function upgrade_scrap2hm(inst, doer, target, pos, act)
        if target.components.equippable and target.components.equippable:IsEquipped() then
            if doer and doer.components.talker then
                doer:DoTaskInTime(.01, function()
                    doer.components.talker:Say(TUNING.isCh2hm and "先把它摘下来吧" or "I need to unequip it first.")
                end)
            end
            return 
        end
        target.components.persistent2hm.data.horizon2hm = true
        process_upgrade(target)
        doer.SoundEmitter:PlaySound("dontstarve/HUD/repair_clothing")
        inst:Remove()
        return true
	end

    -- 预处理
    local function processpersistent(inst, data)
        if data and data.horizon2hm then
            process_upgrade(inst)
        end
    end
    
    -- 名字前缀
    local function displaynamefn2hm(inst)
        return inst:HasTag("horizon2hm") and ((TUNING.isCh2hm and "超视距 " or "Expanded ") .. inst.name) or nil   
    end

    STRINGS.ACTIONS.ACTION2HM.SCRAP_MONOCLEHAT = TUNING.isCh2hm and "升级" or "UPGRADE"

    AddPrefabPostInit("scrap_monoclehat", function(inst)
        inst.displaynamefn = function(inst)
            return TUNING.isCh2hm and "视界拓展套件" or "Horizon Expandinator Kit"
        end
        inst.actionothercondition2hm = function(inst, doer, actions, right, target)
            return target:HasTag("goggles") and not target:HasTag("horizon2hm")
        end

        if not TheWorld.ismastersim then return end
        if inst.components.equippable then inst:RemoveComponent("equippable") end
        if inst.components.fueled then inst:RemoveComponent("fueled") end
        inst:AddComponent("action2hm")
		inst.components.action2hm.actionfn = upgrade_scrap2hm
    end)

    AddPrefabPostInitAny(function(inst)
        if inst:HasTag("goggles") then
            inst.displaynamefn = displaynamefn2hm
            if not TheWorld.ismastersim then return end
            if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
            -- 3.1.1.72使用SetOnLoad2hm来避免覆盖其他地方设置的onload2hm函数
            SetOnLoad2hm(inst, function(inst, data)
                processpersistent(inst, data)
            end)
        end
    end)

    -----------------------------
    -- 当前视距不变
    AddClassPostConstruct("cameras/followcamera", function(self)
        self.MaximizeDistance2hm = self.MaximizeDistance
        self.MaximizeDistance = function(self, ...)
            self.zoomstep = 10 -- 增加灵敏度
            self.distance = TheWorld:HasTag("cave") and 25 or 30
            self.distancetarget = TheWorld:HasTag("cave") and 25 or 30
        end
    end)
end

-- 信号弹召唤流浪商人，敌对信号弹召唤熊獾
if GetModConfigData("Flare Spawn") then
    TUNING.WANDERINGTRADER_VIRTUALWALKING_SPEEDMULT = 1.5 -- 流浪商人脱加载别跑那么快

    local function OnMegaflareSpawnBearger(data)
        if not data or not data.pt then return end
        
        local fx, fy, fz = data.pt.x, data.pt.y, data.pt.z
        
        if not TheWorld.Map:IsVisualGroundAtPoint(fx, fy, fz) then return end
        
        local season = TheWorld.state.season
        if season ~= "summer" and season ~= "autumn" then return end
        
        -- 延迟5-25秒后执行召唤逻辑
        TheWorld:DoTaskInTime(5 + math.random() * 20, function()
            local players = FindPlayersInRange(fx, fy, fz, 35)
            if #players == 0 then return end
            
            if math.random() > 0.5 then return end
            
            TheWorld:PushEvent("megaflare_summon_bearger", {
                pt = Vector3(fx, fy, fz),
                players = players
            })
        end)
    end
    
    -- 给熊大添加事件监听
    AddPrefabPostInit("bearger", function(inst)
        if not TheWorld.ismastersim then return end
        
        local function OnSummonedByFlare(world, data)
            if not data or not data.pt or not inst:IsValid() then return end
            
            local fx, fy, fz = data.pt.x, data.pt.y, data.pt.z
            
            -- 检查距离，只传送远处的熊大
            if inst:GetDistanceSqToPoint(fx, fy, fz) > 100*100 then

                local spawn_pt = FindWalkableOffset(Vector3(fx, fy, fz), math.random() * 2 * PI, 40, 12, true)
                if spawn_pt then
                    spawn_pt = Vector3(fx + spawn_pt.x, fy, fz + spawn_pt.z)
                    inst.Transform:SetPosition(spawn_pt.x, spawn_pt.y, spawn_pt.z)
                    
                    if data.players then
                        for _, player in ipairs(data.players) do
                            if player.components.talker then
                                player.components.talker:Say(TUNING.isCh2hm and "熊獾被信号弹吸引过来了！" or "A bearger has been attracted by the flare!")
                            end
                        end
                    end
                end
            end
        end
        
        inst:ListenForEvent("megaflare_summon_bearger", OnSummonedByFlare, TheWorld)
    end)
    
    
    AddComponentPostInit("worldsettingstimer", function(self)
        if TheWorld and TheWorld.ismastersim then
            TheWorld:ListenForEvent("megaflare_detonated", function(world, data)
                OnMegaflareSpawnBearger(data)
            end)
        end
    end)
end

-- 四本后可以升级你的扫把,这个扫把可以每个世界各绑定一个科技...
if GetModConfigData("Reskin Tool Upgrade") then
    local function unlinkprototyper(inst)
        inst:RemoveTag("linkprototyper2hm")
        inst.linkprototyper2hm:set("")
        local worldid = TheWorld.components.persistent2hm.data.id
        local data = inst.components.persistent2hm and inst.components.persistent2hm.data
        if worldid and data and data[worldid] ~= nil and data[worldid].linkprototyperid ~= nil then data[worldid].linkprototyperid = nil end
        inst.bindprototyper2hm = nil
    end
    local function linkprototyper(inst, prototyper)
        inst:ListenForEvent("onremove", function() unlinkprototyper(inst) end, prototyper)
        inst.bindprototyper2hm = prototyper
        inst:AddTag("linkprototyper2hm")
        inst.linkprototyper2hm:set(prototyper.prefab)
        if inst.components.spellcaster then inst.components.spellcaster.canusefrominventory = false end
    end
    -- 加载时寻找之前绑定的科技建筑
    local function onload(inst)
        if inst:HasTag("linkprototyper2hm") then return end
        local worldid = TheWorld.components.persistent2hm.data.id
        local data = inst.components.persistent2hm and inst.components.persistent2hm.data
        if worldid and data and data[worldid] ~= nil and data[worldid].linkprototyperid ~= nil and TUNING.linkids2hm then
            local prototyper = TUNING.linkids2hm[data[worldid].linkprototyperid]
            if prototyper and prototyper:IsValid() then linkprototyper(inst, prototyper) end
        end
    end
    -- 绑定一个科技建筑，该建筑可能不在TUNING.linkids2hm记录列表里，需要添加该建筑到记录列表里
    local function ongive(inst, prototyper, doer)
        if inst:HasTag("linkprototyper2hm") then return end
        -- 修复：检查新的暗影魔法系统
        if hardmode and not (doer and doer:HasTag("shadowmagic")) then return end
        local worldid = TheWorld.components.persistent2hm.data.id
        if prototyper and prototyper:IsValid() and inst.components.persistent2hm and prototyper.components.persistent2hm and worldid then
            local id = prototyper.components.persistent2hm.data.id
            if id then
                if TUNING.linkids2hm and not TUNING.linkids2hm[id] then TUNING.linkids2hm[id] = prototyper end
                local data = inst.components.persistent2hm.data
                data[worldid] = data[worldid] or {}
                data[worldid].linkprototyperid = id
                linkprototyper(inst, prototyper)
                local fx_prefab = "explode_reskin"
                local skin_fx = SKIN_FX_PREFAB[inst:GetSkinName()]
                if skin_fx ~= nil and skin_fx[1] ~= nil then fx_prefab = skin_fx[1] end
                SpawnPrefab(fx_prefab).Transform:SetPosition(doer.Transform:GetWorldPosition())
                return true
            end
        end
    end
    local function DisplayNameFn(inst)
        local v = inst.linkprototyper2hm:value()
        if v and v ~= "" then
            local vname = STRINGS.NAMES[string.upper(v)]
            return STRINGS.NAMES.RESKIN_TOOL .. (vname and (" " .. vname) or "")
        end
    end
    local function itemtilefn(inst, self)
        if inst.disablebgimage2hm then return end
        local v = inst.linkprototyper2hm:value()
        if v and v ~= "" then
            if not inst.bgimage2hm and not inst.disablebgimage2hm then
                local recipe = AllRecipes[v]
                if recipe then
                    inst.bgimage2hm = recipe.imagefn ~= nil and recipe.imagefn() or recipe.image
                    inst.bgaltas2hm = GetInventoryItemAtlas(inst.bgimage2hm, true) or recipe:GetAtlas()
                else
                    inst.disablebgimage2hm = true
                    return
                end
            end
            -- if self.image and not self.image.revert2hm then
            --     self.image.revert2hm = true
            --     self.image:SetScale(1, -1, 1)
            -- end
        elseif inst.bgimage2hm then
            inst.bgimage2hm = nil
            inst.bgaltas2hm = nil
        end
        return "upgrade2hmdirty", nil, inst.bgaltas2hm, inst.bgimage2hm
    end
    AddPrefabPostInit("reskin_tool", function(inst)
        inst.linkprototyper2hm = net_string(inst.GUID, "reskin_tool.linkprototyper2hm", "upgrade2hmdirty")
        inst.displaynamefn = DisplayNameFn
        inst.itemtilefn2hm = itemtilefn
        if not TheWorld.ismastersim then return end
        inst.prototyperfn2hm = ongive
        inst:AddComponent("persistent2hm")
        inst:DoTaskInTime(0, onload)
    end)
    -- 打扫动作
    local sweepact = Action({mount_valid = true, encumbered_valid = true, priority = 1})
    sweepact.id = "SWEEP2HM"
    sweepact.strfn = function(act)
        local doer = act.doer
        if doer and doer.replica.inventory and doer.replica.inventory then
            local weapon = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if weapon and weapon.prefab == "reskin_tool" and weapon:HasTag("linkprototyper2hm") and weapon.linkprototyper2hm and
                weapon.linkprototyper2hm:value() ~= "" then return string.upper(weapon.linkprototyper2hm:value()) end
        end
    end
    sweepact.fn = function(act)
        if act.invobject and act.doer and act.doer.components.inventory then
            local weapon = act.doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if weapon and weapon.prefab == "reskin_tool" and weapon.bindprototyper2hm and weapon.bindprototyper2hm:IsValid() and
                weapon.bindprototyper2hm.components.trader then
                local count
                if weapon.bindprototyper2hm.components.trader:IsAcceptingStacks() then
                    count = (weapon.bindprototyper2hm.components.inventory ~= nil and
                                weapon.bindprototyper2hm.components.inventory:CanAcceptCount(act.invobject)) or
                                (act.invobject.components.stackable ~= nil and act.invobject.components.stackable.stacksize) or 1
                    if count <= 0 then return false end
                end
                local able, reason = weapon.bindprototyper2hm.components.trader:AbleToAccept(act.invobject, act.doer, count)
                if not able then return false, reason end
                weapon.bindprototyper2hm.notactive2hm = true
                weapon.bindprototyper2hm.components.trader:AcceptGift(act.doer, act.invobject, count)
                weapon.bindprototyper2hm.notactive2hm = nil
                local fx_prefab = "explode_reskin"
                local skin_fx = SKIN_FX_PREFAB[weapon:GetSkinName()]
                if skin_fx ~= nil and skin_fx[1] ~= nil then fx_prefab = skin_fx[1] end
                SpawnPrefab(fx_prefab).Transform:SetPosition(act.doer.Transform:GetWorldPosition())
                return true
            end
        end
    end
    AddAction(sweepact)
    local function sweepactfn(inst, doer, actions)
        if not (inst.replica.equippable and inst.replica.equippable:IsEquipped()) and not inst.replica.container and doer and doer.replica.inventory and
            doer.replica.inventory then
            local weapon = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if weapon and weapon.prefab == "reskin_tool" and weapon:HasTag("linkprototyper2hm") then table.insert(actions, ACTIONS.SWEEP2HM) end
        end
    end
    table.insert(TUNING.INVENTORYFNS2HM, sweepactfn)
    STRINGS.ACTIONS.SWEEP2HM = {}
    STRINGS.ACTIONS.SWEEP2HM.GENERIC = STRINGS.UI.BUGREPORTSCREEN.SUBMIT_FAILURE_TITLE
    STRINGS.ACTIONS.SWEEP2HM.RESEARCHLAB = STRINGS.ACTIONS.GIVE.GENERIC .. " " .. STRINGS.NAMES.RESEARCHLAB
    STRINGS.ACTIONS.SWEEP2HM.RESEARCHLAB2 = STRINGS.ACTIONS.GIVE.GENERIC .. " " .. STRINGS.NAMES.RESEARCHLAB2
    STRINGS.ACTIONS.SWEEP2HM.RESEARCHLAB4 = STRINGS.ACTIONS.GIVE.GENERIC .. " " .. STRINGS.NAMES.RESEARCHLAB4
    STRINGS.ACTIONS.SWEEP2HM.TURFCRAFTINGSTATION = STRINGS.ACTIONS.GIVE.GENERIC .. " " .. STRINGS.NAMES.TURFCRAFTINGSTATION
    AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SWEEP2HM, "veryquickcastspell"))
    AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SWEEP2HM, "veryquickcastspell"))
end

-- 陷阱耐久提升，制作时需要多一颗狗牙
if GetModConfigData("trap_teeth") then
    TUNING.TRAP_TEETH_USES = 40
    TUNING.TRAP_BRAMBLE_USES = 20
    AddRecipePostInit("trap_teeth", function(recipe) 
        for _, ingredient in pairs(recipe.ingredients) do
            if ingredient and ingredient.type == "houndstooth" and ingredient.amount then
                ingredient.amount = ingredient.amount + 1
            end
        end
    end)
end

-- 眼睛炮塔增强
if GetModConfigData("Enhanced_Eyeturret") then
    -- 攻速、血量、回血速度翻倍
    TUNING.EYETURRET_HEALTH = TUNING.EYETURRET_HEALTH * 2                   -- 2000
    TUNING.EYETURRET_ATTACK_PERIOD = TUNING.EYETURRET_ATTACK_PERIOD * 0.5   -- 1.5s/次
    TUNING.EYETURRET_REGEN = TUNING.EYETURRET_REGEN * 2                     -- 24/s

    -- 收回后冷却时间
    TUNING.EYETURRET_COOLDOWN_RECALL = 60   -- 主动
    TUNING.EYETURRET_COOLDOWN_DEATH = 12000 -- 死亡收回

    -- 原版 burnable.lua:360 直接访问skilltreeupdater，需要空函数以防止报错
    local eyeturret_skilltreeupdater = {IsActivated = falsefn}
    
    local GEM_TYPES = {"redgem", "orangegem", "yellowgem", "greengem", "bluegem", "purplegem"}
    
    local GEM_COLORS = {
        redgem = {227/255, 23/255, 13/255},     
        orangegem = {255/255, 97/255, 0/255},   
        yellowgem = {255/255, 255/255, 0/255},  
        greengem = {0/255, 201/255, 87/255},    
        bluegem = {30/255, 144/255, 255/255},   
        purplegem = {153/255, 51/255, 250/255}, 
    }
    
    local GEM_SHOCKWAVE_COLORS = {
        redgem = {0.6, 0.1, 0.1}, 
        orangegem = {0.6, 0.3, 0}, 
        yellowgem = {0.7, 0.7, 0}, 
        greengem = {0.1, 0.6, 0.1}, 
        bluegem = {0.1, 0.1, 0.6}, 
        purplegem = {0.3, 0.1, 0.5}, 
    }
    
    local GEM_NAMES = {
        redgem = STRINGS.NAMES.REDGEM,
        orangegem = STRINGS.NAMES.ORANGEGEM,
        yellowgem = STRINGS.NAMES.YELLOWGEM,
        greengem = STRINGS.NAMES.GREENGEM,
        bluegem = STRINGS.NAMES.BLUEGEM,
        purplegem = STRINGS.NAMES.PURPLEGEM,
    }
    
    local containers = require("containers")
    local params = containers.params
    
    params.eyeturret = {
        widget = {
            slotpos = {
                Vector3(0, 0, 0),
            },
            slotbg = {
                { image = "nightmarefuel.tex", atlas = "images/inventoryimages.xml" },
            },
            animbank = "ui_antlionhat_1x1",
            animbuild = "ui_antlionhat_1x1",
            pos = Vector3(0, 200, 0),
            side_align_tip = 100,
        },
        type = "chest",
        acceptsstacks = true,
    }
    
    function params.eyeturret.itemtestfn(container, item, slot)
        return item and item.prefab == "nightmarefuel"
    end
    
    -- ================================================================
    -- 眼球炮塔物品eyeturret_item增强

    -- 应用宝石增强
    local function ApplyGemUpgrade_Item(inst, gem_type)
        if not table.contains(GEM_TYPES, gem_type) then return end
        
        inst:AddTag("upgraded_" .. gem_type)
        inst.upgrade_type2hm = gem_type

        if inst.components.persistent2hm then
            inst.components.persistent2hm.data.upgraded = true
            inst.components.persistent2hm.data.upgrade_type = gem_type
        end

        if inst.clientupgrade2hm then
            inst.clientupgrade2hm:set(true)
        end
    end
    
    -- 名称
    local function DisplayNameFn_Item(inst)
        for _, gem_type in ipairs(GEM_TYPES) do
            if inst:HasTag("upgraded_" .. gem_type) then
                return GEM_NAMES[gem_type] .. (TUNING.isCh2hm and "" or " ") .. STRINGS.NAMES.EYETURRET_ITEM
            end
        end
        return nil
    end
    
    -- 角标
    local function ItemTileFn_Item(inst)
        if not inst.bgimage2hm then
            for _, gem_type in ipairs(GEM_TYPES) do
                if inst:HasTag("upgraded_" .. gem_type) then
                    inst.bgimage2hm = gem_type .. ".tex"
                    break
                end
            end
            if inst.bgimage2hm then 
                inst.bgaltas2hm = GetInventoryItemAtlas(inst.bgimage2hm) 
            end
        end
        return "upgrade2hmdirty", nil, inst.bgaltas2hm, inst.bgimage2hm
    end
    
    local function OnSave_Item(inst, data)
        if inst.upgrade_type2hm then
            data.upgrade_type2hm = inst.upgrade_type2hm
        end
    end
    
    local function OnLoad_Item(inst, data)
        if data and data.upgrade_type2hm then
            ApplyGemUpgrade_Item(inst, data.upgrade_type2hm)
        end
    end
    
    local function ondeploy_eyeturret(inst, pt, deployer)
        local turret = SpawnPrefab("eyeturret", inst.linked_skinname, inst.skin_id)
        if turret ~= nil then
            turret.Physics:SetCollides(false)
            turret.Physics:Teleport(pt.x, 0, pt.z)
            turret.Physics:SetCollides(true)
            turret:syncanim("place")
            turret:syncanimpush("idle_loop", true)
            turret.SoundEmitter:PlaySound("dontstarve/common/place_structure_stone")

            if inst.components.finiteuses and turret.components.health then
                turret.components.health:SetPercent(inst.components.finiteuses:GetPercent())
            end

            turret.linked_skinname = inst.linked_skinname
            turret.skin_id = inst.skin_id

            -- 传递宝石增强
            if inst.upgrade_type2hm then
                turret._deployed_gem_type = inst.upgrade_type2hm
                turret:AddTag("upgraded_" .. inst.upgrade_type2hm)
                
                -- 应用宝石颜色给眼球
                turret:DoTaskInTime(0.1, function()
                    if turret and turret:IsValid() and turret._deployed_gem_type and GEM_COLORS[turret._deployed_gem_type] then
                        local color = GEM_COLORS[turret._deployed_gem_type]
                        turret.AnimState:SetMultColour(color[1], color[2], color[3], 1)
                        -- 基座颜色不用改
                    end
                end)
            end
            
            inst:Remove()
        end
    end

    AddPrefabPostInit("eyeturret_item", function(inst)
        inst.displaynamefn = DisplayNameFn_Item
        inst.itemtilefn2hm = ItemTileFn_Item
        inst.clientupgrade2hm = net_bool(inst.GUID, "eyeturret_item.upgrade2hm", "upgrade2hmdirty")
        inst.clientupgrade2hm:set(false)
        
        if not TheWorld.ismastersim then return end

        if not inst.components.finiteuses then 
            inst:AddComponent("finiteuses")
            inst.components.finiteuses:SetMaxUses(TUNING.EYETURRET_HEALTH)
            inst.components.finiteuses:SetUses(TUNING.EYETURRET_HEALTH)
        end

        if not inst.components.rechargeable then 
            inst:AddComponent("rechargeable") 
        end

        inst.components.rechargeable:SetOnDischargedFn(function(inst)
            inst:AddTag("oncooldown")
            if inst.components.deployable then
                inst.components.deployable.restrictedtag = "oncooldown"
            end
        end)
        
        inst.components.rechargeable:SetOnChargedFn(function(inst)
            inst:RemoveTag("oncooldown")
            if inst.components.deployable then
                inst.components.deployable.restrictedtag = nil
            end
        end)

        if inst.components.deployable then
            inst.components.deployable.ondeploy = ondeploy_eyeturret
        end

        if not inst.components.persistent2hm then
            inst:AddComponent("persistent2hm")
        end

        if not inst.components.trader then
            inst:AddComponent("trader")
        end

        inst.components.trader.acceptnontradable = true
        
        inst.components.trader:SetAbleToAcceptTest(function(inst, item, giver)    
            return table.contains(GEM_TYPES, item.prefab) and not inst.upgrade_type2hm
        end)
        
        inst.components.trader.onaccept = function(inst, giver, item)
            if table.contains(GEM_TYPES, item.prefab) then
                if giver.SoundEmitter then
                    giver.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
                end
                ApplyGemUpgrade_Item(inst, item.prefab)
                return true
            end
            return false
        end
        
        SetOnSave(inst, OnSave_Item)
        SetOnLoad(inst, OnLoad_Item)
        
        inst.upgrade_type2hm = nil
    end)
    
    -- =============================================================
    -- 部署后的炮塔eyeturret部分
    
    local function OnContainerOpen(inst)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
    end

    local function OnContainerClose(inst)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
    end
    
    local function OnDismantle_eyeturret(inst)
        if inst.components.container then
            inst.components.container:DropEverything()
        end
        
        local skin_build = inst:GetSkinBuild()
        if skin_build and skin_build ~= "eyeturret" then
            skin_build = skin_build .. "item"                   -- 皮肤build需要加item后缀
        else
            skin_build = nil 
        end
        local item = SpawnPrefab("eyeturret_item", skin_build, inst.skin_id)
        if item then
            item.Transform:SetPosition(inst.Transform:GetWorldPosition())
            
            if item.components.finiteuses and inst.components.health then
                item.components.finiteuses:SetPercent(inst.components.health:GetPercent())
            end

            -- 传递宝石增强
            if inst._deployed_gem_type then
                ApplyGemUpgrade_Item(item, inst._deployed_gem_type)
            end

            if item.components.rechargeable then
                item.components.rechargeable:Discharge(TUNING.EYETURRET_COOLDOWN_RECALL)
            end
        end
        
        local fx = SpawnPrefab("collapse_small")
        if fx then
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
        
        inst.SoundEmitter:PlaySound("dontstarve/common/together/catapult/destroy")
        inst:Remove()
    end

    local function OnEyeturretDeath(inst)
        if inst.components.container then
            inst.components.container:DropEverything()
        end
        
        local skin_build = inst:GetSkinBuild()
        if skin_build and skin_build ~= "eyeturret" then
            skin_build = skin_build .. "item"  
        else
            skin_build = nil 
        end
        local item = SpawnPrefab("eyeturret_item", skin_build, inst.skin_id)
        if item then
            item.Transform:SetPosition(inst.Transform:GetWorldPosition())
            
            if item.components.finiteuses then
                -- 重新部署时满血
                item.components.finiteuses:SetPercent(1)
            end

            if inst._deployed_gem_type then
                ApplyGemUpgrade_Item(item, inst._deployed_gem_type)
            end
            
            if item.components.rechargeable then
                item.components.rechargeable:Discharge(TUNING.EYETURRET_COOLDOWN_DEATH)
            end
            
            local fx = SpawnPrefab("collapse_small")
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
        
        inst:Remove()
    end

    -- 冲击波
    local function CreateShockwave(tx, ty, tz, color)
        local fx = SpawnPrefab("eyeturret_shockwave_fx")
        if fx then
            fx.Transform:SetPosition(tx, ty, tz)
            if color and fx.color_r then
                fx.color_r:set(color[1])
                fx.color_g:set(color[2])
                fx.color_b:set(color[3])
            end
            return fx
        end
    end
    
    -- 减速
    local function ApplyShadowDebuff(target, apply_slow)
        if not target:IsValid() or not target.components.locomotor then
            return
        end
        
        if target._purplegem_eyeturret_task then
            return
        end
        
        if apply_slow then
            local shadow_fx = SpawnPrefab("shadow_trap_debuff_fx")
            if shadow_fx then
                shadow_fx.entity:SetParent(target.entity)
                if shadow_fx.OnSetTarget then
                    shadow_fx:OnSetTarget(target)
                end
                target._purplegem_eyeturret_fx = shadow_fx
            end
            
            target.components.locomotor:SetExternalSpeedMultiplier(target, "purplegem_eyeturret", 0.7)
            target._purplegem_eyeturret_task = target:DoTaskInTime(4, function()
                if target and target:IsValid() then
                    if target.components.locomotor then
                        target.components.locomotor:RemoveExternalSpeedMultiplier(target, "purplegem_eyeturret")
                    end
                    if target._purplegem_eyeturret_fx and target._purplegem_eyeturret_fx:IsValid() then
                        if target._purplegem_eyeturret_fx.KillFX then
                            target._purplegem_eyeturret_fx:KillFX()
                        else
                            target._purplegem_eyeturret_fx:Remove()
                        end
                    end
                    target._purplegem_eyeturret_fx = nil
                    target._purplegem_eyeturret_task = nil
                end
            end)
        end
    end
    
    -- 中毒
    local function _Green_Tick_Eyeturret(inst, src)
        if inst.components.health and not inst.components.health:IsDead() then
            local delta = -math.clamp(inst.components.health.maxhealth / 20, 1, 40)
            inst.components.health:DoDelta(delta, nil, src)
            local fx = SpawnPrefab("ghostlyelixir_speed_dripfx")
            if fx ~= nil then
                fx.Transform:SetScale(.5, .5, .5)
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
        end
        inst._attrgreen_idx_eyeturret = (inst._attrgreen_idx_eyeturret or 0) + 1
        if inst._attrgreen_idx_eyeturret >= 10 and inst._attrgreen_task_eyeturret then
            inst._attrgreen_task_eyeturret:Cancel()
            inst._attrgreen_task_eyeturret = nil
            inst._attrgreen_idx_eyeturret = nil
        end
    end
    
    -- 根据宝石类型对单体目标添加特殊效果
    local function ApplyBasicAttackEffect(inst, target)
        if not (inst._deployed_gem_type and target and target:IsValid()) then
            return
        end
        
        if target:HasTag("player") then return end
        
        local gemtype = inst._deployed_gem_type
        
        if gemtype == "bluegem" then
            -- 蓝：冰冻
            if target.components.freezable then
                target.components.freezable:AddColdness(1)
                target.components.freezable:SpawnShatterFX()
            end
            
        elseif gemtype == "redgem" then
            -- 红：点燃
            if target.components.burnable then
                target.components.burnable:Ignite(true, nil, inst)
            end
            
        elseif gemtype == "purplegem" then
            -- 紫：减速
            if target.components.locomotor then
                ApplyShadowDebuff(target, true)
            end
            
        elseif gemtype == "yellowgem" then
            -- 黄：电击
            if not target:HasTag("electricstunimmune") then
                SpawnPrefab("electrichitsparks"):AlignToTarget(target, inst, true)
                
                -- 眩晕
                if target.sg and target.sg:HasState("electrocute") and 
                   not (target:HasTag("electricdamageimmune") or 
                       (target.components.inventory ~= nil and target.components.inventory:IsInsulated())) then
                    target:PushEvent("electrocute", { attacker = inst, stimuli = "electric" })
                end
                
                -- 眩晕冷却
                target:AddTag("electricstunimmune")
                target:DoTaskInTime(math.random(8, 10), function()
                    if target and target:IsValid() then
                        target:RemoveTag("electricstunimmune")
                    end
                end)
            else
                SpawnPrefab("electrichitsparks"):AlignToTarget(target, inst, true)
            end
        elseif gemtype == "greengem" then
            -- 绿：中毒
            if target.components.health then
                target._attrgreen_idx_eyeturret = 0
                if target._attrgreen_task_eyeturret == nil then
                    target._attrgreen_task_eyeturret = target:DoPeriodicTask(1, _Green_Tick_Eyeturret, 0.25, inst)
                end
            end
            
        elseif gemtype == "orangegem" then
            -- 橙：传送
            if target.Physics then
                local ix, iy, iz = inst.Transform:GetWorldPosition()
                local tx, ty, tz = target.Transform:GetWorldPosition()
                local angle = math.atan2(tz - iz, tx - ix)
                local radius = 6
                local offset = Vector3(radius * math.cos(angle), 0, radius * math.sin(angle))
                local dest = Vector3(tx, ty, tz) + offset
                
                if TheWorld.Map:IsAboveGroundAtPoint(dest.x, dest.y, dest.z) and 
                   not TheWorld.Map:IsPointNearHole(dest) then
                    target.Physics:Teleport(dest.x, dest.y, dest.z)
                    SpawnPrefab("sand_puff_large_front").Transform:SetPosition(dest.x, dest.y, dest.z)
                    SpawnPrefab("sand_puff_large_back").Transform:SetPosition(tx, ty, tz)
                end
            end
        end
    end

    -- 装填燃料概率触发aoe冲击波
    local function TrySpecialAttack(inst, target)
        if not (inst.components.container and target and target:IsValid()) then
            return false
        end

        if not inst._deployed_gem_type then
            return false
        end

        local fuel = inst.components.container:FindItem(function(item)
            return item.prefab == "nightmarefuel"
        end)
        
        if not fuel then return false end
        
        if math.random() > 0.33 then return false end

        if fuel.components.stackable and fuel.components.stackable:StackSize() > 1 then
            fuel.components.stackable:Get():Remove()
        else
            inst.components.container:RemoveItem(fuel, true):Remove()
        end

        if inst.UpdateShadowFX then
            inst:UpdateShadowFX()
        end
        
        if inst._deployed_gem_type then
            local gemtype = inst._deployed_gem_type
            local tx, ty, tz = target.Transform:GetWorldPosition()
            local ATTACK_RANGE = 4.5
            local NOTAGS = {"playerghost", "INLIMBO", "eyeturret", "flight", "invisible", "player"}
            local TARGET_ONEOF_TAGS = {"_combat"}
            
            -- 预警圈
            local ping = SpawnPrefab("deerclops_icelance_ping_fx")
            if ping then
                ping.Transform:SetScale(0.8, 0.8, 0.8)
                ping.Transform:SetPosition(tx, ty, tz)
                if gemtype ~= "bluegem" and GEM_COLORS[gemtype] then
                    local color = GEM_COLORS[gemtype]
                    ping.AnimState:SetMultColour(color[1], color[2], color[3], 1)
                    if ping.disc and ping.disc.AnimState then
                        ping.disc.AnimState:SetMultColour(color[1], color[2], color[3], 1)
                    end
                end

                ping:DoTaskInTime(.8, function()
                    if ping and ping:IsValid() then
                        ping:KillFX()
                    end
                    
                    local ents = TheSim:FindEntities(tx, ty, tz, ATTACK_RANGE, nil, NOTAGS, TARGET_ONEOF_TAGS)
                    
                    if gemtype == "bluegem" then
                        -- 蓝：冰冻
                        -- local fx = SpawnPrefab("deer_ice_flakes")
                        -- if fx then
                        --     fx.Transform:SetPosition(tx, ty, tz)
                        --     fx.Transform:SetScale(1.6, 1.6, 1.6)
                        --     fx:DoTaskInTime(0.5, fx.KillFX or fx.Remove)
                        -- end
                        inst.SoundEmitter:PlaySound("dontstarve/common/break_iceblock")
                        CreateShockwave(tx, ty, tz, GEM_SHOCKWAVE_COLORS["bluegem"])
                        for i, v in ipairs(ents) do
                            if v:IsValid() and v.components.health and not v.components.health:IsDead() then
                                if v.components.combat and not v:HasTag("player") then
                                    v.components.combat:GetAttacked(inst, 50, nil)
                                end
                                if v.components.freezable and not v:HasTag("player") then
                                    v.components.freezable:AddColdness(6)
                                    v.components.freezable:SpawnShatterFX()
                                end
                            end
                        end
                    elseif gemtype == "redgem" then
                        -- 红：点燃
                        inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/dragonfly/buttstomp")
                        CreateShockwave(tx, ty, tz, GEM_SHOCKWAVE_COLORS["redgem"])
                        for i, v in ipairs(ents) do
                            if v:IsValid() and v.components.health and not v.components.health:IsDead() then
                                if v.components.combat and not v:HasTag("player") then
                                    v.components.combat:GetAttacked(inst, 80, nil)
                                end
                                if v.components.burnable and not v:HasTag("player") then
                                    v.components.burnable:Ignite(true, nil, inst)
                                end
                            end
                        end
                        
                    elseif gemtype == "purplegem" then
                        -- 紫宝石：三段冲击 50->40->20
                        CreateShockwave(tx, ty, tz, GEM_SHOCKWAVE_COLORS["purplegem"])
                        
                        for i, v in ipairs(ents) do
                            if v:IsValid() and v.components.health and not v.components.health:IsDead() then
                                if v.components.combat and not v:HasTag("player") then
                                    v.components.combat:GetAttacked(inst, 50, nil)
                                    ApplyShadowDebuff(v, true)
                                end
                            end
                        end
                        
                        -- 第二段冲击
                        TheWorld:DoTaskInTime(.4, function()
                            CreateShockwave(tx, ty, tz, GEM_SHOCKWAVE_COLORS["purplegem"])
                            
                            local ents2 = TheSim:FindEntities(tx, ty, tz, ATTACK_RANGE, nil, NOTAGS, TARGET_ONEOF_TAGS)
                            for i, v in ipairs(ents2) do
                                if v:IsValid() and v.components.health and not v.components.health:IsDead() then
                                    if v.components.combat and not v:HasTag("player") then
                                        v.components.combat:GetAttacked(inst, 40, nil)
                                        ApplyShadowDebuff(v, true)
                                    end
                                end
                            end
                            
                            -- 第三段冲击
                            TheWorld:DoTaskInTime(.3, function()
                                CreateShockwave(tx, ty, tz, GEM_SHOCKWAVE_COLORS["purplegem"])
                                
                                local ents3 = TheSim:FindEntities(tx, ty, tz, ATTACK_RANGE, nil, NOTAGS, TARGET_ONEOF_TAGS)
                                for i, v in ipairs(ents3) do
                                    if v:IsValid() and v.components.health and not v.components.health:IsDead() then
                                        if v.components.combat and not v:HasTag("player") then
                                            v.components.combat:GetAttacked(inst, 20, nil)
                                            ApplyShadowDebuff(v, true)
                                        end
                                    end
                                end
                            end)
                        end)
                        
                    elseif gemtype == "yellowgem" then
                        -- 黄：电击附加眩晕
                        CreateShockwave(tx, ty, tz, GEM_SHOCKWAVE_COLORS["yellowgem"])
                        for i, v in ipairs(ents) do
                            if v:IsValid() and v.components.health and not v.components.health:IsDead() and 
                               v.components.combat and not v:HasTag("player") then
                            
                                local lightning = SpawnPrefab("lightning")
                                if lightning then
                                    lightning.Transform:SetPosition(v.Transform:GetWorldPosition())
                                end
                                
                                -- 电击效果
                                if not v:HasTag("electricstunimmune") then
                                    SpawnPrefab("electrichitsparks"):AlignToTarget(v, inst, true)
                                    local damage_mult = 1
                                    if not (v:HasTag("electricdamageimmune") or 
                                           (v.components.inventory ~= nil and v.components.inventory:IsInsulated())) then
                                        damage_mult = TUNING.ELECTRIC_DAMAGE_MULT or 1
                                        local wetness_mult = (v.components.moisture ~= nil and v.components.moisture:GetMoisturePercent()) or 
                                                            (v:GetIsWet() and 1) or 0
                                        damage_mult = damage_mult + TUNING.ELECTRIC_WET_DAMAGE_MULT * wetness_mult
                                    end

                                    -- 眩晕
                                    if v.sg and v.sg:HasState("electrocute") and 
                                       not (v:HasTag("electricdamageimmune") or 
                                           (v.components.inventory ~= nil and v.components.inventory:IsInsulated())) then
                                        v:PushEvent("electrocute", { attacker = inst, stimuli = "electric" })
                                    end
                                    
                                    -- 原50伤害变为电击伤害
                                    v.components.combat:GetAttacked(inst, 50, nil, "electric")
                                    
                                    -- 冷却
                                    v:AddTag("electricstunimmune")
                                    v:DoTaskInTime(math.random(10, 12), function()
                                        if v and v:IsValid() then
                                            v:RemoveTag("electricstunimmune")
                                        end
                                    end)
                                else
                                    SpawnPrefab("electrichitsparks"):AlignToTarget(v, inst, true)
                                    v.components.combat:GetAttacked(inst, 50, nil, "electric")
                                end
                            end
                        end
                        
                    elseif gemtype == "orangegem" then
                        -- 橙：传送
                        CreateShockwave(tx, ty, tz, GEM_SHOCKWAVE_COLORS["orangegem"])
                        local ix, iy, iz = inst.Transform:GetWorldPosition()
                        for i, v in ipairs(ents) do
                            if v:IsValid() and v.components.health and not v.components.health:IsDead() and 
                               v.components.combat and not v:HasTag("player") then
                                v.components.combat:GetAttacked(inst, 50, nil)
                                
                                if v.Physics then
                                    local vx, vy, vz = v.Transform:GetWorldPosition()
                                    local angle = math.atan2(vz - iz, vx - ix)
                                    local radius = 6
                                    local offset = Vector3(radius * math.cos(angle), 0, radius * math.sin(angle))
                                    local dest = Vector3(vx, vy, vz) + offset
                                    
                                    if TheWorld.Map:IsAboveGroundAtPoint(dest.x, dest.y, dest.z) and 
                                       not TheWorld.Map:IsPointNearHole(dest) then
                                        v.Physics:Teleport(dest.x, dest.y, dest.z)
                                        SpawnPrefab("sand_puff_large_front").Transform:SetPosition(dest.x, dest.y, dest.z)
                                        SpawnPrefab("sand_puff_large_back").Transform:SetPosition(vx, vy, vz)
                                    end
                                end
                            end
                        end                     
                    elseif gemtype == "greengem" then
                        -- 绿：中毒
                        CreateShockwave(tx, ty, tz, GEM_SHOCKWAVE_COLORS["greengem"])
                        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/spore_shoot")
                        for i, v in ipairs(ents) do
                            if v:IsValid() and v.components.health and not v.components.health:IsDead() and 
                               v.components.combat and not v:HasTag("player") then
                                v.components.combat:GetAttacked(inst, 50, nil)

                                if v.components.health then
                                    v._attrgreen_idx_eyeturret = 0
                                    if v._attrgreen_task_eyeturret == nil then
                                        v._attrgreen_task_eyeturret = v:DoPeriodicTask(1, _Green_Tick_Eyeturret, 0.25, inst)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
        
        return true
    end

    local function OnSave_Eyeturret(inst, data)
        if inst._deployed_gem_type then
            data.deployed_gem_type = inst._deployed_gem_type
        end
    end
    
    local function OnLoad_Eyeturret(inst, data)
        if data and data.deployed_gem_type then
            inst._deployed_gem_type = data.deployed_gem_type
            inst:AddTag("upgraded_" .. data.deployed_gem_type)

            inst:DoTaskInTime(0, function()
                if inst and inst:IsValid() and inst._deployed_gem_type and GEM_COLORS[inst._deployed_gem_type] then
                    local color = GEM_COLORS[inst._deployed_gem_type]
                    inst.AnimState:SetMultColour(color[1], color[2], color[3], 1)
                end
            end)
        end
    end

    local function UpdateShadowFX(inst)
        if TheWorld.ismastersim then
            local has_fuel = inst.components.container and 
                            inst.components.container:FindItem(function(item)
                                return item.prefab == "nightmarefuel"
                            end) ~= nil
            if inst._has_fuel_net then
                inst._has_fuel_net:set(has_fuel)
            end
        end
        
        local has_fuel = inst._has_fuel_net and inst._has_fuel_net:value() or false
        
        if has_fuel and not inst._shadow_fx then
            inst._shadow_fx = SpawnPrefab("shadow_trap_debuff_fx")
            if inst._shadow_fx then
                inst._shadow_fx.entity:SetParent(inst.entity)
            end
        elseif not has_fuel and inst._shadow_fx then
            if inst._shadow_fx.KillFX then
                inst._shadow_fx:KillFX()
            else
                inst._shadow_fx:Remove()
            end
            inst._shadow_fx = nil
        end
    end
    
    AddPrefabPostInit("eyeturret", function(inst)

        inst._has_fuel_net = net_bool(inst.GUID, "eyeturret._has_fuel_net", "fuel_dirty")
        
        if not TheWorld.ismastersim then 
            inst:ListenForEvent("fuel_dirty", UpdateShadowFX)
            return 
        end

        if not inst.components.container then
            inst:AddComponent("container")
            inst.components.container:WidgetSetup("eyeturret")
            inst.components.container.onopenfn = OnContainerOpen
            inst.components.container.onclosefn = OnContainerClose
        end
        
        inst.UpdateShadowFX = UpdateShadowFX

        if not inst.components.portablestructure then 
            inst:AddComponent("portablestructure") 
        end
        inst.components.portablestructure:SetOnDismantleFn(OnDismantle_eyeturret)

        inst:ListenForEvent("death", OnEyeturretDeath)

        if inst.components.lootdropper then
            inst:RemoveComponent("lootdropper")
        end
        
        inst:ListenForEvent("onattackother", function(inst, data)
            if data and data.target then
                TrySpecialAttack(inst, data.target)
            end
        end)
        
        SetOnSave(inst, OnSave_Eyeturret)
        SetOnLoad(inst, OnLoad_Eyeturret)
        

        inst:ListenForEvent("itemget", function(inst, data)
            if data and data.item and data.item.prefab == "nightmarefuel" then
                inst:UpdateShadowFX()
            end
        end)
        
        inst:ListenForEvent("itemlose", function(inst, data)
            inst:UpdateShadowFX()
        end)
        

        inst:DoTaskInTime(0.1, function()
            inst:UpdateShadowFX()
        end)
        
        inst.components.skilltreeupdater = eyeturret_skilltreeupdater

        -- 电击特殊攻击，原版weapon(1秒)设置后再设置
        inst:DoTaskInTime(1.1, function()
            if inst._deployed_gem_type == "yellowgem" and inst.components.inventory then
                local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if weapon and weapon.components.weapon then
                    weapon.components.weapon.stimuli = "electric"
                end
            end
        end)
        
        -- 属性增强的不同标签和能力
        inst:DoTaskInTime(0, function()
            if inst._deployed_gem_type then
                if inst._deployed_gem_type == "redgem" then
                    inst:AddTag("controlled_burner")
                elseif inst._deployed_gem_type == "bluegem" then
                    inst:AddTag("freezeimmune")
                    if inst.components.freezable then
                        inst:RemoveComponent("freezable")
                    end
                elseif inst._deployed_gem_type == "orange" then
                    if inst.components.combat then 
                        inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.33, "orange2hm") 
                    end
                elseif inst._deployed_gem_type == "yellowgem" then
                    inst:AddTag("electricdamageimmune")
                elseif inst._deployed_gem_type == "greengem" then
                    inst:AddTag("sporeresistant")
                    inst:AddTag("miasmaimmune")
                end
            end
        end)
     
        inst:ListenForEvent("onremove", function(inst)
            if inst._shadow_fx then
                if inst._shadow_fx.KillFX then
                    inst._shadow_fx:KillFX()
                else
                    inst._shadow_fx:Remove()
                end
                inst._shadow_fx = nil
            end
        end)
    end)
    
    -- 命中时应用基础攻击的特殊效果
    AddPrefabPostInit("eye_charge", function(inst)
        if not TheWorld.ismastersim then return end

        local old_onhit = inst.components.projectile.onhit
        inst.components.projectile:SetOnHitFn(function(inst, owner, target)
            if old_onhit then
                old_onhit(inst, owner, target)
            end

            if owner and owner:IsValid() and target and target:IsValid() then
                ApplyBasicAttackEffect(owner, target)
            end
        end)
    end)
    
end

-- 睡袋升级帐篷
if GetModConfigData("Tent_Upgrade") then
    local function cyclesrepair(inst)
        if inst.components.finiteuses and inst.components.finiteuses:GetPercent() < 1 then inst.components.finiteuses:Repair(1) end
    end
    local function worldphase() return TheWorld.state.phase end
    local function upgradesleep(inst)
        inst.components.finiteuses:SetMaxUses(inst.components.finiteuses.total * 2)
        inst.components.finiteuses:SetUses(inst.components.finiteuses.total)
        inst:WatchWorldState("cycles", cyclesrepair)
        if inst.components.sleepingbag then inst.components.sleepingbag.GetSleepPhase = worldphase end
        inst.level2hm:set(2)
    end

    local function customrepair(inst, repairuse, doer, repair_item)
        if not inst.components.persistent2hm.data.upgrade then
            inst.components.persistent2hm.data.upgrade = true
            upgradesleep(inst)
        elseif inst.components.finiteuses:GetPercent() >= 1 then
            return false
        end
        local shinefx = SpawnPrefab("pocketwatch_warpback_fx")
        shinefx.AnimState:SetTime(10 * FRAMES)
        local parent = inst.components.inventoryitem and inst.components.inventoryitem:GetGrandOwner() or inst
        parent:AddChild(shinefx)
        inst.components.finiteuses:SetUses(inst.components.finiteuses.total)
        if repair_item.components.stackable then
            repair_item.components.stackable:Get():Remove()
        else
            repair_item:Remove()
        end
        return true
    end
    local function onpreload(inst, data) if data and data.persistent2hm and data.persistent2hm.upgrade then upgradesleep(inst) end end
    local function DisplayNameFn(inst)
        if inst.level2hm:value() > 1 then
            if inst.repairtext2hm then inst.repairtext2hm = nil end
            return (TUNING.isCh2hm and "高级" or "Upgraded ") .. inst.name
        else
            return inst.name
        end
    end
    local function sleepbombcanrepair(inst)
        inst.repairmaterials2hm = {sleepbomb = 1}
        inst.repairtext2hm = "UPGRADE"
        if not inst.displaynamefn then inst.displaynamefn = DisplayNameFn end
        inst.level2hm = net_byte(inst.GUID, "tent.level2hm")
        if not TheWorld.ismastersim then return end
        inst.level2hm:set(1)
        if inst.components.finiteuses then
            inst:AddComponent("repairable2hm")
            inst.components.repairable2hm.customrepair = customrepair
            inst:AddComponent("persistent2hm")
            SetOnPreLoad(inst, onpreload)
        end
        -- -- 超绝回复速度
        -- inst.components.sleepingbag.health_tick = TUNING.SLEEP_HEALTH_PER_TICK * 4
    end
    AddPrefabPostInit("bedroll_furry", sleepbombcanrepair)
    AddPrefabPostInit("tent", sleepbombcanrepair)
    AddPrefabPostInit("siestahut", sleepbombcanrepair)
    
    -- 升级后无条件回复血量san值上限（需要启用帐篷恢复理智上限选项）
    if GetModConfigData("Tent restores sanity penalty") then
        AddComponentPostInit("sleepingbaguser", function(SleepingBagUser)
            local _DoSleep = SleepingBagUser.DoSleep
            local _DoWakeUp = SleepingBagUser.DoWakeUp
            SleepingBagUser.DoSleep = function(self, bed)
                _DoSleep(self, bed)
                if self.bed.level2hm and self.bed.level2hm:value() > 1 then
                    self.healthtask2hm = self.inst:DoPeriodicTask(self.bed.components.sleepingbag.tick_period, function()
                        local health_tick = self.bed.components.sleepingbag.health_tick * self.health_bonus_mult
                        if self.inst.components.health ~= nil then
                            self.inst.components.health:DeltaPenalty(-health_tick / 200)
                        end
                    end)
                    -- 注意：理智恢复功能已经在 easy_structures.lua 中的 "Tent restores sanity penalty" 选项里统一处理
                    -- 升级后的帐篷享受2倍的理智恢复速度
                end
            end
            SleepingBagUser.DoWakeUp = function(self, nostatechange)
                if self.healthtask2hm ~= nil then
                    self.healthtask2hm:Cancel()
                    self.healthtask2hm = nil
                end
                _DoWakeUp(self, nostatechange)
            end
        end)
    end
end

-- 指南针显示流浪商人位置
if GetModConfigData("compass_show_trader") then
    AddMinimapAtlas("images/map_icons/wanderingtrader.xml")
    
    AddPrefabPostInit("wanderingtrader", function(inst)
        if not TheWorld.ismastersim then return end
        
        if not inst.components.maprevealable then
            inst:AddComponent("maprevealable")
        end
        
        inst.components.maprevealable:SetIconPrefab("globalmapicon")
        inst.components.maprevealable:SetIcon("wanderingtrader.tex")
        inst.components.maprevealable:SetIconPriority(10)
        
        inst.components.maprevealable:AddRevealSource(inst, "compassbearer")
        
    end)
end








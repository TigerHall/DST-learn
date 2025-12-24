local HMR_LISTS = require("hmrmain/hmr_lists")

----------------------------------------------------------------------------
---[[加载界面小提示]]
----------------------------------------------------------------------------
for i, description in ipairs(STRINGS.HMR.SURVIVAL_TIPS) do
    local currenttime = os.time()
    local year = os.date("%Y", currenttime)
    local month = os.date("%m", currenttime)
    local day = os.date("%d", currenttime)
    local date = string.format("%s年%s月%s日", year, month, day)
    local name = "不愿透露姓名的旦某"

    local has_name = false
    description = description:gsub("%{(.-)%}", function(key)
        has_name = true
        return "\n--"..STRINGS.HMR.SURVIVAL_TIPS_AUTHOR[key] or key
    end)
    if not has_name then
        description = string.format("%s\n--%s", description, name)
    end

    local str = string.format("【丰耘日记】%s  %s", description, date)
    AddLoadingTip(STRINGS.UI.LOADING_SCREEN_OTHER_TIPS, "TIP_L"..tostring(i), str)
end
-- 设置mod提示的权重
SetLoadingTipCategoryWeights(LOADING_SCREEN_TIP_CATEGORY_WEIGHTS_START, { CONTROLS = 1, SURVIVAL = 1, LORE = 1, LOADING_SCREEN = 1, OTHER = 5 })
SetLoadingTipCategoryWeights(LOADING_SCREEN_TIP_CATEGORY_WEIGHTS_END, { CONTROLS = 1, SURVIVAL = 1, LORE = 1, LOADING_SCREEN = 1, OTHER = 5 })

----------------------------------------------------------------------------
---[[添加组件]]
----------------------------------------------------------------------------
local PERMANENT_PREFAB_TAGS = {"FX", "CLASSIFIED"}
AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim or inst:HasOneOfTags(PERMANENT_PREFAB_TAGS) then
        return
    end
    inst:AddComponent("hmrstatusmodifier")
end)

----------------------------------------------------------------------------
---[[农作物植株初始化]]
----------------------------------------------------------------------------
local FARM_PLANT_LIST = HMR_LISTS.FARM_PLANTS_LIST
for name, data in pairs(FARM_PLANT_LIST) do
    if data.farm_plant_master_postinit ~= nil then
        AddPrefabPostInit("farm_plant_"..name, function(inst)
            if not TheWorld.ismastersim then
                return
            end
            data.farm_plant_master_postinit(inst)
        end)
    end
end

----------------------------------------------------------------------------
---[[辉煌修补套件]]
----------------------------------------------------------------------------
AddReplicableComponent("hmrrepairable")

-- 万物皆可修
local REPAIR_BLACK_LIST = HMR_LISTS.REPAIR_BLACK_LIST
AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if REPAIR_BLACK_LIST[inst.prefab] then
        return
    end

    if inst.components.armor ~= nil or
        inst.components.finiteuses ~= nil or
        inst.components.fueled ~= nil or
        inst.components.perishable ~= nil
    then
        inst:AddComponent("hmrrepairable")
    end
end)

----------------------------------------------------------------------------
---[[辉煌护甲]]
----------------------------------------------------------------------------
-- 辉煌套装不受亮茄攻击
AddPrefabPostInit("lunarthrall_plant", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local function CanNotAttack(target)
        return target and target.components.inventory and target.components.inventory:EquipHasTag("lunarthrall_plant_friendly")
    end

    local oldCanTarget = inst.components.combat.CanTarget
    inst.components.combat.CanTarget = function(self, target)
        if CanNotAttack(target) then
            return false
        end
        return oldCanTarget(self, target)
    end

    local oldkeeptargetfn = inst.components.combat.keeptargetfn
    inst.components.combat.keeptargetfn = function(inst, target)
        if CanNotAttack(target) then
            return false
        end
        return oldkeeptargetfn(inst, target)
    end
end)

-- 辉煌护甲霸体
local function DoHurtSound(inst)
    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride, nil, inst.hurtsoundvolume)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/hurt", nil, inst.hurtsoundvolume)
    end
end

AddStategraphPostInit("wilson", function(sg)
    -- 受击无硬直
    local eve1 = sg.events["attacked"]
    local event_fn_attacked = eve1.fn
    eve1.fn = function(inst, data, ...)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("drowning") then
            if not inst.sg:HasStateTag("sleeping") then -- 睡袋貌似有自己的特殊机制
                if inst.replica.inventory and inst.replica.inventory:EquipHasTag("honor_armor") then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                    DoHurtSound(inst)
                    return
                end
            end
        end
        return event_fn_attacked(inst, data, ...)
    end

    -- 防击退
    local eve2 = sg.events["knockback"]
    local event_fn_knockback = eve2.fn
    eve2.fn = function(inst, data, ...)
        if inst.replica.inventory and inst.replica.inventory:EquipHasTag("honor_armor") and
            not (data and data.knocker and data.knocker.prefab and data.knocker.prefab == "gelblob")
        then
            return
        end
        return event_fn_knockback(inst, data, ...)
    end

    -- 防恶液
    local suspended_event = sg.events["suspended"]
    local event_fn_suspended = suspended_event.fn
    suspended_event.fn = function(inst, data, ...)
        if inst.replica.inventory and inst.replica.inventory:EquipHasTag("honor_armor") then
            return
        end
        return event_fn_suspended(inst, data, ...)
    end
end)

HMR_UTIL.AddKeyboardControl("honor_armor_skill_enabled", {
    {name = "honor_armor_skill_enable", down = true, key = "HONOR_ARMOR_SKILL", params = true},
    {name = "honor_armor_skill_disable", down = false, key = "HONOR_ARMOR_SKILL", params = false}
}, function(player, enabled)
    local function FindEquippedHonorArmor()
        if player and player.components.inventory then
            for k, v in pairs(player.components.inventory.equipslots) do
                if v and v.prefab == "honor_armor" then
                    return v
                end
            end
        end
    end
    local armor = FindEquippedHonorArmor()
    if armor ~= nil then
        if enabled then
            armor:EnableSkill(player)
        else
            armor:DisableSkill(player)
        end
    end
end)

----------------------------------------------------------------------------
---[[辉煌工具]]
---------------------------s-------------------------------------------------
-- 辉煌工具添加掉落
AddComponentPostInit("finiteuses", function(FiniteUses)
    function FiniteUses:SetOnUsedAsItem(fn)
        self.onusedasitem = fn
    end

    local oldOnUsedAsItem = FiniteUses.OnUsedAsItem
    function FiniteUses:OnUsedAsItem(action, doer, target)
        if self.onusedasitem then
            self.onusedasitem(self.inst, action, doer, target)
        end
        return oldOnUsedAsItem(self, action, doer, target)
    end
end)

-- 辉煌工具切换耕地状态
HMR_UTIL.AddKeyboardControl("honor_multitool_change_mode", {
    {name = "honor_multitool_change_mode", down = true, key = "HONOR_MULTITOOL_MODE"},
}, function(player)
    local tool = player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if tool ~= nil and tool.prefab == "honor_multitool" then
        tool:OnModeChanged(player)
    end
end)

-- 兼容《Snapping tills(一田十格）》显示圆圈
AddPlayerPostInit(function(player)
    player.net_honormultitoolmode = net_tinybyte(player.GUID, "net_honormultitoolmode", "net_honormultitoolmode_dirty")
    player.net_honormultitoolmode:set(0)
    if not TheNet:IsDedicated() then
        player:DoTaskInTime(3, function()   -- 一田十格的加载优先级有点低，我们延迟一会
            if not player.components.snaptiller then return end
            player:ListenForEvent("net_honormultitoolmode_dirty", function(inst)
                player.components.snaptiller.snapmode = player.net_honormultitoolmode:value()
            end)
        end)
    end
end)

AddComponentPostInit("snaptillplacer", function(SnapTillPlacer)
    local function MakeSnapTillPlacer(self, x, z, index)
        if self.linked == nil then
            self.linked = {}
        end

        local inst = SpawnPrefab("snaptillplacer")
        if inst then
            inst.Transform:SetPosition(x, 0, z)
            --inst:SetDebugNumber(index)
            table.insert(self.linked, inst)
        end
    end

    local function ApplayVisible(self)
        if self.linked ~= nil then
            for _, v in ipairs(self.linked) do
                if self.visible then
                    v:Show()
                else
                    v:Hide()
                end
            end
        end
    end

    local oldOnUpdate = SnapTillPlacer.OnUpdate
    function SnapTillPlacer:OnUpdate(dt)
        local item = self.inst and self.inst.replica.inventory and self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if not item then return end
        if not item:HasTag("honor_hoe") then
            return oldOnUpdate(self, dt)
        end

        -- 辉煌工具(有“honor_hoe”标签即可兼容)
        if self.inst == nil then
            self:ClearLinked()
            return
        end

        if self.inst.components.snaptiller.snapmode == 0 then
            self:ClearLinked()
            return
        end

        if self.inst.components.snaptiller == nil or self.inst.replica.inventory == nil or
           (self.inst.replica.rider and self.inst.replica.rider:IsRiding()) then
            self:ClearLinked()
            return
        end

        local activeitem = self.inst.replica.inventory:GetActiveItem()
        local deployedfarmplant = false

        --is wormwood?
        if self.inst:HasTag("plantkin") and activeitem and activeitem:HasTag("deployedfarmplant") then
            deployedfarmplant = true
        end

        if not deployedfarmplant then
            local equippeditem = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if not equippeditem or (equippeditem and not equippeditem:HasTag("honor_hoe")) then --其实之前已经判断过了
                self:ClearLinked()
                return
            end
        end

        local pos = nil

        if TheInput:ControllerAttached() then
            pos = Point(self.inst.entity:LocalToWorldSpace(0, 0, 0))
        else
            if not deployedfarmplant and activeitem ~= nil then
                self:ClearLinked()
                return
            end

            pos = TheInput:GetWorldPosition()
        end

        if not pos then
            self:ClearLinked()
            return
        end

        local tilex, tiley = TheWorld.Map:GetTileCoordsAtPoint(pos.x, pos.y, pos.z)
        local tile = TheWorld.Map:GetTile(tilex, tiley)

        if self.cachetilepos == nil then
            self.cachetilepos = {tilex, tiley}
        end

        if self.cachesnapmode == nil then
            self.cachesnapmode = self.inst.components.snaptiller.snapmode
        end

        if self.cachesnapmode == 1 then
            local res = self.inst.components.snaptiller:HasAdjacentSoilTile(Point(TheWorld.Map:GetTileCenterPoint(tilex, tiley)))
            if self.cacheadjacentsoil ~= res then
                self.cacheadjacentsoil = res
                self:ClearLinked()
            end
        end

        if (tile == WORLD_TILES.FARMING_SOIL or tile == WORLD_TILES.QUAGMIRE_SOIL) or deployedfarmplant then
            if self.cachetilepos[1] ~= tilex or self.cachetilepos[2] ~= tiley or
               self.cachesnapmode ~= self.inst.components.snaptiller.snapmode or self.linked == nil then
                self:ClearLinked()
                local snaplist = self.inst.components.snaptiller:GetSnapListOnTile(tilex, tiley)
                for i, v in ipairs(snaplist) do
                    MakeSnapTillPlacer(self, v[1], v[2], i)
                end
                self.cachetilepos = {tilex, tiley}
                self.cachesnapmode = self.inst.components.snaptiller.snapmode
                ApplayVisible(self)
            end
        else
            self:ClearLinked()
        end

        if self.linked ~= nil then
            local can = true
            for _, v in ipairs(self.linked) do
                if deployedfarmplant then
                    local x, y, z = v.Transform:GetWorldPosition()
                    can = TheWorld.Map:CanTillSoilAtPoint(x, y, z, true)
                else
                    if self.inst.components.snaptiller.isquagmire then
                        can = TheWorld.Map:CanTillSoilAtPoint(Point(v.Transform:GetWorldPosition()))
                    else
                        can = TheWorld.Map:CanTillSoilAtPoint(v.Transform:GetWorldPosition())
                    end
                end

                if can then
                    v.AnimState:PlayAnimation("on", false)
                else
                    v.AnimState:PlayAnimation("off", false)
                end
            end
        end
    end
end)

----------------------------------------------------------------------------
---[[辉煌法杖]]
----------------------------------------------------------------------------
-- 辉煌法杖可移除池塘
AddComponentPostInit("spellcaster", function(SpellCaster)
    local oldCanCast = SpellCaster.CanCast
    function SpellCaster:CanCast(doer, target, pos)
        if self.inst.prefab == "honor_weapon" and target ~= nil and (target.prefab == "honor_pond" or target.prefab == "marsh_plant") then
            return true
        else
            return oldCanCast(self, doer, target, pos)
        end
    end
end)

----------------------------------------------------------------------------
---[[辉煌背包]]
----------------------------------------------------------------------------
AddComponentPostInit("inventoryitem", function(InventoryItem)
    function InventoryItem:FindOwner(param)
        if self.owner then
            if type(param) == "string" then
                if self.owner:HasTag(param) then
                    return self.owner
                end
            elseif type(param) == "function" then
                if param(self.owner) then
                    return self.owner
                end
            else
                return
            end

            if self.owner.components.inventoryitem then
                return self.owner.components.inventoryitem:FindOwner(param)
            end
        end
    end
end)

-- 升温/降温
AddComponentPostInit("temperature", function(Temperature)
    local oldOnUpdate = Temperature.OnUpdate
    function Temperature:OnUpdate(dt, applyhealthdelta)
        local function GetContainer(container)
            return container.components.hmrcontainermanager ~= nil and container.components.hmrcontainermanager.slot_temperature ~= nil
        end
        local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:FindOwner(GetContainer)
        if owner ~= nil then
            local slot = owner.components.container:GetItemSlot(self.inst)
            if slot ~= nil then
                local temp, rate = owner.components.hmrcontainermanager:GetSlotTemperature(slot)
                if temp ~= nil and rate ~= nil then
                    if self.current > temp then
                        self:SetTemperature(math.max(self.current - dt * rate, temp))
                    elseif self.current < temp then
                        self:SetTemperature(math.min(self.current + dt * rate, temp))
                    end
                    return
                end
            end
        end

        return oldOnUpdate(self, dt, applyhealthdelta)
    end
end)

----------------------------------------------------------------------------
---[[传送宝箱与背包关联]]
----------------------------------------------------------------------------
-- 背包搜索框
local HonorBackpack = require "widgets/honor_backpack"
AddClassPostConstruct("widgets/containerwidget", function(self)
    self.honor_backpack = self:AddChild(HonorBackpack(self.owner))
    -- self.honor_backpack:SetPosition(0, 0, 0)
    self.honor_backpack:Hide()

    local oldOpen = self.Open
    function self:Open(container, doer)
        oldOpen(self, container, doer)
        if container.prefab == "honor_backpack" then
            self.honor_backpack:Show()
        end
    end

    local oldClose = self.Close
    function self:Close()
        oldClose(self)
        self.honor_backpack:Hide()
    end
end)

-- 向箱子发送任务事件
AddModRPCHandler("HMR", "HONOR_BACKPACK_TRANSMIT", function(player, prefab)
    local chests, chests_has_target = {}, {}

    for _, ent in pairs(Ents) do
        if ent:HasTag("hmr_chest_transmit") and ent.components.container then
            for _, slot in pairs(ent.components.container.slots) do
                if slot ~= nil and (prefab == slot.prefab or prefab == slot.name) then
                    table.insert(chests_has_target, ent)
                    break
                end
            end
            table.insert(chests, ent)
        end
    end

    local function SortByDist(a, b)
        return player:GetDistanceSqToInst(a) < player:GetDistanceSqToInst(b)
    end
    table.sort(chests, SortByDist)
    table.sort(chests_has_target, SortByDist)

    local success = false
    if #chests_has_target >= 0 then
        for _, chest in ipairs(chests_has_target) do
            if chest.TransmitItem ~= nil and chest:TransmitItem(prefab, player) then
                success = true
                break
            end
        end
    end

    if not success and #chests >= 0 then
        for _, chest in ipairs(chests) do
            if chest.TransmitItem ~= nil and chest:TransmitItem(prefab, player) then
                success = true
                break
            end
        end
    end

    if not success then
        if player.components.talker ~= nil then
            player.components.talker:Say(STRINGS.HMR.TRANSMIT_CHEST.TRANSMIT_SEARCHFAILED_ANNOUNCE)
        end
        if player.components.sanity ~= nil then
            player.components.sanity:DoDelta(-5)
        end
    end
end)

----------------------------------------------------------------------------
---[[辉煌炼化容器]]
----------------------------------------------------------------------------
-- 界面
local HonorCookpot = require "widgets/honor_cookpot"
AddClassPostConstruct("widgets/containerwidget", function(self)
    self.honor_cookpot = self:AddChild(HonorCookpot(self.owner))
    self.honor_cookpot:SetPosition(0, 0, 0)
    self.honor_cookpot:Hide()

    local oldOpen = self.Open
    function self:Open(container, doer)
        oldOpen(self, container, doer)
        if container.prefab == "honor_cookpot" then
            self.honor_cookpot:Show()
            self.honor_cookpot:SetCookpot(container)
        end
    end

    local oldClose = self.Close
    function self:Close()
        oldClose(self)
        self.honor_cookpot:Hide()
        self.honor_cookpot:SetCookpot(nil)
    end
end)

-- RPC
-- 烹饪
AddModRPCHandler("HMR","honor_cookpot_cook", function(player, cookpot, status)
    if cookpot ~= nil then
        if status then
            cookpot._cookbtn:set(true)
        else
            cookpot._cookbtn:set(false)
        end
    end
end)

-- 研磨
AddModRPCHandler("HMR","honor_cookpot_grind", function(player, cookpot)
    if cookpot ~= nil then
        cookpot:OnGrind(player)
    end
end)

-- 调味
AddModRPCHandler("HMR","honor_cookpot_season", function(player, cookpot)
    if cookpot ~= nil then
        cookpot:OnSeason(player)
    end
end)

----------------------------------------------------------------------------
---[[处理调味料理]]
----------------------------------------------------------------------------
-- Mod加载完后给所有食谱添加一遍新调料的料理，以下代码源自【小穹】，由【能力勋章】修改
local oldRegisterPrefabs = GLOBAL.ModManager.RegisterPrefabs
GLOBAL.ModManager.RegisterPrefabs = function(self,...)
    HMR_UTIL.PreRegisterPrefab(require("prefabs/hmr_preparedfoods"))
    --这个时候 PrefabFiles文件还没有被加载
	--所有的菜谱都过一遍，把需要添加新料理的食谱都记下来
    local cooking = require("cooking")
    local SPICED_FOODS_DEF = require("hmrmain/hmr_spicedfoods")
    for potname, data in pairs(cooking.recipes) do
        if potname and data and potname ~= "portablespicer" then
			SPICED_FOODS_DEF.GenerateSpicedFoods(data)
        end
    end
	-- 添加新的调味料理食谱
    for k, v in pairs(SPICED_FOODS_DEF.GetSpicedFoods()) do
        AddCookerRecipe("portablespicer", v)
    end
    oldRegisterPrefabs(self,...)
end

----------------------------------------------------------------------------
---[[巨型杂交水稻屏幕叶子]]
----------------------------------------------------------------------------
AddPlayerPostInit(function(inst)
    inst.net_under_hybridrice = net_bool(inst.GUID, "honor_under_hybirdrice", "under_hybirdrice_dirty")
    inst.net_under_hybridrice:set(false)

    if not TheWorld.ismastersim then
        return
    end
    inst:ListenForEvent("onchangehybridricezone", function(player, under)
        inst.net_under_hybridrice:set(under)
    end)
end)

local HybridRiceLeaves = require "widgets/honor_hybridrice_leaves"
AddClassPostConstruct("screens/playerhud", function(self)
    local oldCreateOverlays = self.CreateOverlays
    function self:CreateOverlays(owner)
        oldCreateOverlays(self, owner)
        self.hybridrice_leaves = self.overlayroot:AddChild(HybridRiceLeaves(owner))
    end

    local oldOnUpdate = self.OnUpdate
    function self:OnUpdate(dt)
        oldOnUpdate(self, dt)
        if self.hybridrice_leaves then
            self.hybridrice_leaves:OnUpdate(dt)
        end
    end
end)

---------------------------------------------------------------------------
---[[青衢纳宝箱阵列箱子]]
---------------------------------------------------------------------------
AddReplicableComponent("hmrcontainermanager")
AddClassPostConstruct("widgets/containerwidget", function(ContainerWidget)
    local function UpdateSlots(container)
        if container.replica.hmrcontainermanager and
            container.replica.hmrcontainermanager:GetSlotDisplay() ~= nil and
            ContainerWidget.inv
        then
            for i, slot in pairs(ContainerWidget.inv) do
                if container.replica.hmrcontainermanager:ShouldShowSlot(i) then
                    slot:Show()
                else
                    slot:Hide()
                end
            end
        end
    end

    local function OnSlotDirty(container)
        UpdateSlots(container)
    end

    local oldOpen = ContainerWidget.Open
    function ContainerWidget:Open(container, ...)
        oldOpen(self, container, ...)
        UpdateSlots(container)

        container:ListenForEvent("slot_display_dirty", OnSlotDirty)
        self.container = container
    end

    local oldClose = ContainerWidget.Close
    function ContainerWidget:Close(...)
        if self.container ~= nil then
            self.container:RemoveEventCallback("slot_display_dirty", OnSlotDirty)
            oldClose(self, ...)
        end
    end
end)

---------------------------------------------------------------------------
---[[灵枢织造箱判断容器是否真的满了（可堆叠未到达最大值的不算满]]
---------------------------------------------------------------------------
AddComponentPostInit("container", function(Container)
    function Container:IsRealFull()
        if not self:IsFull() then
            return false
        end

        local isrealfull = true
        for _, slot in pairs(self.slots) do
            if self:CanAcceptCount(slot) >= 1 then
                isrealfull = false
            end
        end
        return isrealfull
    end
end)

---------------------------------------------------------------------------
---[[灵枢织造箱_洞穴香蕉树可移植]]
---------------------------------------------------------------------------
AddPrefabPostInit("cave_banana_tree", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    local function OnDigup(inst)
        inst.components.lootdropper:SpawnLootPrefab("hmr_dug_cavebananatree")

        if inst.components.pickable:CanBePicked() then
            if math.random() < 0.5 then
                inst.components.lootdropper:SpawnLootPrefab("cave_banana")
            end
        end

        inst:Remove()
    end
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnDigup)
end)

---------------------------------------------------------------------------
---[[工厂]]
---------------------------------------------------------------------------
AddReplicableComponent("hmrfactory")

---------------------------------------------------------------------------
---[[龙龛探秘箱垃圾箱子]]
---------------------------------------------------------------------------
-- 处理阵列箱子的打开与关闭
AddComponentPostInit("container", function(Container)
    -- 处理构成阵列的箱子的打开与关闭
    local oldOpen = Container.Open
    function Container:Open(doer)
        oldOpen(self, doer)
        if self.inst:HasTag("hmr_chest_recycle") then
            local slot = self.inst.components.entitytracker:GetEntity("slot")
            if slot ~= nil and slot.components.container ~= nil then
                slot.components.container:Open(doer)
            end
        end
    end

    local oldClose = Container.Close
    function Container:Close(doer)
        oldClose(self, doer)
        if self.inst:HasTag("hmr_chest_recycle") then
            local slot = self.inst.components.entitytracker:GetEntity("slot")
            if slot ~= nil and slot.components.container ~= nil then
                slot.components.container:Close(doer)
            end
        end
    end
end)

AddClassPostConstruct("widgets/containerwidget", function(self)
    local oldOpen = self.Open
    function self:Open(container, doer)
        oldOpen(self, container, doer)
        if container.prefab == "hmr_chest_recycle" then
            self:MoveToBack()
        end
        if container.prefab == "hmr_chest_recycle_virtual" then
            self:MoveToFront()
        end
    end
end)

---------------------------------------------------------------------------
---[[辉煌治愈吹箭可治疗玩家]]
---------------------------------------------------------------------------
AddPlayerPostInit(function(player)
    if not TheWorld.ismastersim then
        return
    end
    player:AddComponent("hcurable")
end)

-- 区分治愈子弹和攻击子弹
AddComponentPostInit("weapon", function(Weapon)
    local oldLaunchProjectile = Weapon.LaunchProjectile
    function Weapon:LaunchProjectile(attacker, target, type)
        if type ~= nil and type == "cure" then
            if self.projectile ~= nil then
                if self.onprojectilelaunch ~= nil then
                    self.onprojectilelaunch(self.inst, attacker, target)
                end

                local proj = SpawnPrefab(self.projectile)
                if proj ~= nil then
                    proj.components.weapon:SetDamage(0)
                    if proj.components.projectile ~= nil then
                        if self.projectile_offset ~= nil then
                            local x, y, z = attacker.Transform:GetWorldPosition()

                            local dir = (target:GetPosition() - Vector3(x, y, z)):Normalize()
                            dir = dir * self.projectile_offset

                            proj.Transform:SetPosition(x + dir.x, y, z + dir.z)
                        else
                            proj.Transform:SetPosition(attacker.Transform:GetWorldPosition())
                        end
                        proj.components.projectile:Throw(self.inst, target, attacker)
                        if self.inst.projectiledelay ~= nil then
                            proj.components.projectile:DelayVisibility(self.inst.projectiledelay)
                        end
                    elseif proj.components.complexprojectile ~= nil then
                        proj.Transform:SetPosition(attacker.Transform:GetWorldPosition())
                        proj.components.complexprojectile:Launch(target:GetPosition(), attacker, self.inst)
                    end
                end

                if self.onprojectilelaunched ~= nil then
                    self.onprojectilelaunched(self.inst, attacker, target, proj)
                end
            end
        else
            oldLaunchProjectile(self, attacker, target, type)
        end
    end
end)

----------------------------------------------------------------------------
---[[丰耘科技面板]]
----------------------------------------------------------------------------
local HMR_PANEL_BUTTON = require "widgets/hmr_panel_button"
AddClassPostConstruct("widgets/inventorybar", function(self)
    self.hmr_tech = self:AddChild(HMR_PANEL_BUTTON(self.owner))
    self.hmr_tech:SetHAnchor(0) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
    self.hmr_tech:SetVAnchor(2) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
    self.hmr_tech:SetPosition(-200, 200, 0)

    -- 鼠标跟随
    HMR_UTIL.AddDraggableUI(self.hmr_tech, self.hmr_tech.openbutton.image, "hmr_tech_button", {drag_offset = 1})
end)

AddPrefabPostInit("world", function(inst)
    inst:AddComponent("hmrtechtree")
end)

-- 通知服务器学习科技
AddModRPCHandler("HMR", "HMRTECHTREE_LEARN", function(player, tech)
    TheWorld.components.hmrtechtree:LearnTech(tech, player)
end)

-- 通知客户端更新科技状态
AddClientModRPCHandler("HMR", "UPDATE_CILENT_TECHTREE", function(str)
    local success, decoded_techstatus = pcall(json.decode, str)
    if success then
        local new_techs = {}
        for tech_name, status in pairs(decoded_techstatus) do
            if not  TheWorld.components.hmrtechtree:GetTechStatus(tech_name) then
                new_techs[tech_name] = status
                TheWorld.components.hmrtechtree.techstatus[tech_name] = status
            end
        end

        if ThePlayer and ThePlayer.HMRTech ~= nil and next(decoded_techstatus) ~= nil then
            ThePlayer.HMRTech:LearnSkill(decoded_techstatus)
        end
    end
end)

----------------------------------------------------------------------------
---[[模组集成面板]]
----------------------------------------------------------------------------
local HMRPopupScreen = require "screens/hmrpopupscreen"
AddClassPostConstruct("screens/playerhud",function(self, anim, owner)
	self.ShowHMRScreen = function()
		self.hmrpopupscreen = HMRPopupScreen(self.owner)
        self:OpenScreenUnderPause(self.hmrpopupscreen)
        return self.hmrpopupscreen
	end

	self.CloseHMRScreen = function()
		if self.hmrpopupscreen ~= nil then
            if self.hmrpopupscreen.inst:IsValid() then
                TheFrontEnd:PopScreen(self.hmrpopupscreen)
            end
            self.hmrpopupscreen = nil
        end
	end
end)

AddPopup("HMR")
POPUPS.HMR.fn = function(inst, show)
    if inst.HUD then
        if not show then
            inst.HUD:CloseHMRScreen()
        elseif not inst.HUD:ShowHMRScreen() then
            POPUPS.HMR:Close(inst)
        end
    end
end

----------------------------------------------------------------------------
---[[解决辉煌多用工具锄地动作动画丢失]]
----------------------------------------------------------------------------
AddStategraphPostInit("wilson", function(sg)
    local till_start = sg.states["till_start"]
    if till_start ~= nil then
        local oldonenter = till_start.onenter
        till_start.onenter = function(inst)
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool ~= nil and equippedTool.prefab == "honor_multitool" then
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("till_pre")
            else
                oldonenter(inst)
            end
        end
    end

    local till = sg.states["till"]
    if till ~= nil then
        local oldonenter = till.onenter
        till.onenter = function(inst)
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool ~= nil and equippedTool.prefab == "honor_multitool" then
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("till_loop")
            else
                oldonenter(inst)
            end
        end
    end
end)

local TIMEOUT = 2
AddStategraphPostInit("wilson_client", function(sg)
    local till_start = sg.states["till_start"]
    if till_start ~= nil then
        local oldonenter = till_start.onenter
        till_start.onenter = function(inst)
            local equippedTool = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool ~= nil and equippedTool.prefab == "honor_multitool" then
                inst.AnimState:PlayAnimation("till_pre")
                inst.AnimState:PushAnimation("till_lag", false)

                inst:PerformPreviewBufferedAction()
                inst.sg:SetTimeout(TIMEOUT)
            else
                oldonenter(inst)
            end
        end
    end
end)

----------------------------------------------------------------------------
---[[为生物添加可定身组件]]
----------------------------------------------------------------------------
AddPrefabPostInitAny(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.health ~= nil or inst.components.combat ~= nil then
        inst:AddComponent("hstunnable")
        local health_mult = math.clamp((inst.components.health and inst.components.health.maxhealth or 100) * 0.1, 1, 8)
        local damage_mult = math.clamp((inst.components.combat and inst.components.combat.defaultdamage or 50) * 0.1, 0.5, 2)
        inst.components.hstunnable:SetBearableStunDegree(health_mult * damage_mult)
    end
end)

---------------------------------------------------------------------------
---[[装饰栅栏刷新]]
---------------------------------------------------------------------------
AddModRPCHandler("HMR", "hdecoratable_refresh", function(player, inst)
    inst.components.hdecoratable:Refresh()
end)

---------------------------------------------------------------------------
---[[设置地毯可被叉子叉起]]
---------------------------------------------------------------------------
AddComponentPostInit("terraformer", function(Terraformer)
    local oldTerraform = Terraformer.Terraform
    function Terraformer:Terraform(pt, doer)
        local carpets = TheSim:FindEntities(pt.x, pt.y, pt.z, 6, {"hmr_carpet"})
        local min_dist = 6
        local target_carpet = nil
        for _, carpet in pairs(carpets) do
            print(pt.x, pt.y, pt.z, carpet.Transform:GetWorldPosition())
            local dist = carpet:GetDistanceSqToPoint(pt.x, pt.y, pt.z)
            if dist < min_dist and dist < carpet.radius * carpet.radius then
                min_dist = dist
                target_carpet = carpet
            end
        end
        if target_carpet ~= nil then
            target_carpet.components.workable:WorkedBy(doer, 1)
            return true
        else
            return oldTerraform(self, pt, doer)
        end
    end
end)

---------------------------------------------------------------------------
---[[引燃者组件]]
---------------------------------------------------------------------------
AddPlayerPostInit(function(player)
    if not TheWorld.ismastersim then
        return
    end
    player:AddComponent("higniter")
end)

local SpDamageUtil = require("components/spdamageutil")
AddComponentPostInit("explosive", function(Explosive)
    local oldOnBurnt = Explosive.OnBurnt
    function Explosive:OnBurnt()
        if self.inst:HasTag("donot_remove") then
            local CANT_TAGS = { "INLIMBO" }
            if not self.skip_camera_flash then
                for i, v in ipairs(AllPlayers) do
                    local distSq = v:GetDistanceSqToInst(self.inst)
                    local k = math.max(0, math.min(1, distSq / 400))
                    local intensity = k * 0.75 * (k - 2) + 0.75 --easing.outQuad(k, 1, -1, 1)
                    if intensity > 0 then
                        v:ScreenFlash(intensity)
                        v:ShakeCamera(CAMERASHAKE.FULL, .7, .02, intensity / 2)
                    end
                end
            end

            if self.onexplodefn ~= nil then
                self.onexplodefn(self.inst)
            end

            local stacksize = self.inst.components.stackable ~= nil and self.inst.components.stackable:StackSize() or 1
            local totaldamage = self.explosivedamage * stacksize

            local x, y, z = self.inst.Transform:GetWorldPosition()

            local world = TheWorld
            if world.components.dockmanager ~= nil then
                world.components.dockmanager:DamageDockAtPoint(x, y, z, totaldamage)
            end

            local attacker = self.attacker or self.pvpattacker

            local workablecount = TUNING.EXPLOSIVE_MAX_WORKABLE_INVENTORYITEMS
            local ents = TheSim:FindEntities(x, y, z, self.explosiverange, nil, CANT_TAGS)
            for i, v in ipairs(ents) do
                if v ~= self.inst and not v:IsInLimbo() and v:IsValid() and
                    (self.pvpattacker == nil or v == self.pvpattacker or not v:HasTag("player"))
                    then
                    local damagetypemult = self.inst.components.damagetypebonus ~= nil and self.inst.components.damagetypebonus:GetBonus(v) or 1

                    if v.components.workable ~= nil and v.components.workable:CanBeWorked() then
                        -- NOTES(JBK): Stackable inventory items can be placed down 1 by 1 making this a convenience to players to not have to drop them down 1 by 1 first for maximum potential output.
                        local workdamage = self.buildingdamage * stacksize * damagetypemult
                        local dowork = true
                        if v.components.inventoryitem ~= nil then
                            if workablecount > 0 then
                                workablecount = workablecount - 1
                                workdamage = workdamage * (v.components.stackable ~= nil and v.components.stackable:StackSize() or 1)
                            else
                                dowork = false
                            end
                        end
                        if dowork then
                            v.components.workable:WorkedBy(self.inst, workdamage)
                        end
                    end

                    --Recheck valid after work
                    if not v:IsInLimbo() and v:IsValid() then
                        if self.lightonexplode and
                            v.components.fueled == nil and
                            v.components.burnable ~= nil and
                            not v.components.burnable:IsBurning() and
                            not v:HasTag("burnt") then
                            v.components.burnable:Ignite()
                        end

                        if v.components.combat ~= nil and not (v.components.health ~= nil and v.components.health:IsDead()) then
                            local dmg = totaldamage * damagetypemult
                            if v.components.explosiveresist ~= nil then
                                dmg = dmg * (1 - v.components.explosiveresist:GetResistance())
                                v.components.explosiveresist:OnExplosiveDamage(dmg, self.inst)
                            end

                            local spdmg = SpDamageUtil.CollectSpDamage(self.inst)
                            if spdmg ~= nil and damagetypemult ~= 1 then
                                spdmg = SpDamageUtil.ApplyMult(spdmg, damagetypemult)
                            end

                            --V2C: still passing self.inst instead of attacker here, so we don't
                            --     use attacker for calculating damage mods.
                            v.components.combat:GetAttacked(self.inst, dmg, nil, nil, spdmg) -- NOTES(JBK): The component combat might remove itself in the GetAttacked callback!

                            if attacker ~= nil and v.components.combat ~= nil and not (v.components.health ~= nil and v.components.health:IsDead()) and v:IsValid() then
                                if attacker:IsValid() then
                                    v.components.combat:SuggestTarget(attacker)
                                else
                                    attacker = nil
                                end
                            end
                        end

                        v:PushEvent("explosion", { explosive = self.inst })
                    end
                end
            end

            for i = 1, stacksize do
                world:PushEvent("explosion", { damage = self.explosivedamage })
            end

            if self.inst.components.health ~= nil then
                -- NOTES(JBK): Make sure to keep the events fired up to date with the health component.
                world:PushEvent("entity_death", { inst = self.inst, explosive = true, })
                self.inst:PushEvent("death")
            end
        else
            oldOnBurnt(self)
        end
    end
end)

---------------------------------------------------------------------------
---[[水稻精华buff禁止修改移速倍率]]
---------------------------------------------------------------------------
AddComponentPostInit("inventoryitem", function(InventoryItem)
    local InventoryItem_Replica = InventoryItem.inst.replica.inventoryitem

    local oldSetWalkSpeedMult = InventoryItem_Replica.SetWalkSpeedMult
    function InventoryItem_Replica:SetWalkSpeedMult(mult)
        local owner = InventoryItem_Replica.inst.components.inventoryitem ~= nil and InventoryItem_Replica.inst.components.inventoryitem:GetGrandOwner() or ThePlayer
        if owner ~= nil and owner:HasTag("hmr_ignore_speed_mult") then
            mult = 1
        end
        oldSetWalkSpeedMult(self, mult)
    end
end)

---------------------------------------------------------------------------
---[[贪婪甲虫吃农作物动作]]
---------------------------------------------------------------------------
local HEATPLANT = Action()
HEATPLANT.id = "HEATPLANT"
HEATPLANT.str = "吃掉"
HEATPLANT.fn = function(act)
    if act.target ~= nil and act.doer ~= nil then
        if act.doer.eaten_list == nil then
            act.doer.eaten_list = {}
        end
        local name = string.gsub(act.target.prefab, "farm_plant_", "")
        name = string.gsub(name, "_oversized", "")
        name = string.gsub(name, "_waxed", "")
        name = string.gsub(name, "_rotten", "")
        table.insert(act.doer.eaten_list, name)

        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(act.target.Transform:GetWorldPosition())
        fx:SetMaterial("wood")
        act.target:Remove()
    end
end
AddAction(HEATPLANT)

---------------------------------------------------------------------------
---[[控制潮湿度]]
---------------------------------------------------------------------------
-- 按键控制潮湿度
--[[
    RPC_name
    keys_data = {{name = "", down = true, continuous = true, key = KEY, params = {}}, ... }
    handlerfn = function(player, data)
    key_from_config_override = config_name
]]
HMR_UTIL.AddKeyboardControl("moisture_control", {
    {name = "moisture_control_up", down = true, continuous = true, key = "MOISTURE_CONTROL_UP", params = 1},
    {name = "moisture_control_down", down = true, continuous = true, key = "MOISTURE_CONTROL_DOWN", params = -1},
}, function(player, data)
    if player.components.moisture ~= nil and
        (player.components.debuffable ~= nil and
        player.components.debuffable:HasDebuff("terror_blueberry_prime_buff")) or
        player:HasTag("terror_tower_moisture_buff")
    then
        player.components.moisture:DoDelta(data)
    end
end)

---------------------------------------------------------------------------
---[[添加坐下与离开椅子的回调]]
---------------------------------------------------------------------------
AddComponentPostInit("sittable", function(Sittable)
    function Sittable:SetOnSit(fn)
        self.onsit = fn
    end

    function Sittable:SetOnLeave(fn)
        self.onleave = fn
    end

    local oldSetOccupier = Sittable.SetOccupier
    function Sittable:SetOccupier(occupier)
        if occupier == nil and self.occupier ~= nil then
            if self.onleave ~= nil then
                self.onleave(self.occupier)
            end
        end
        oldSetOccupier(self, occupier)
        if self.occupier ~= nil and self.onsit ~= nil then
            self.onsit(self.occupier)
        end
    end
end)

---------------------------------------------------------------------------
---[[地皮物品栏图片]]
---------------------------------------------------------------------------
local TURF_LIST = HMR_LISTS.TURF_LIST
local function GetWaveBearing(map, ex, ey, ez)
	local radius = 3.5
	local tx, tz = ex % TILE_SCALE, ez % TILE_SCALE
	local left = tx - radius < 0
	local right = tx + radius > TILE_SCALE
	local up = tz - radius < 0
	local down = tz + radius > TILE_SCALE


	local offs_1 =
	{
		{-1,-1, left and up},   {0,-1, up},   {1,-1, right and up},
		{-1, 0, left},		    			  {1, 0, right},
		{-1, 1, left and down}, {0, 1, down}, {1, 1, right and down},
	}

	local width, height = map:GetSize()
	local halfw, halfh = 0.5 * width, 0.5 * height
	local x, y = map:GetTileXYAtPoint(ex, ey, ez)
	local xtotal, ztotal, n = 0, 0, 0

	local is_nearby_land_tile = false

	for i = 1, #offs_1, 1 do
		local curoff = offs_1[i]
		local offx, offy = curoff[1], curoff[2]

		local ground = map:GetTile(x + offx, y + offy)
		if IsLandTile(ground) then
			if curoff[3] then
				return false
			else
				is_nearby_land_tile = true
			end
			xtotal = xtotal + ((x + offx - halfw) * TILE_SCALE)
			ztotal = ztotal + ((y + offy - halfh) * TILE_SCALE)
			n = n + 1
		end
	end

	radius = 4.5
	local minoffx, maxoffx, minoffy, maxoffy
	if not is_nearby_land_tile then
		minoffx = math.floor((tx - radius) / TILE_SCALE)
		maxoffx = math.floor((tx + radius) / TILE_SCALE)
		minoffy = math.floor((tz - radius) / TILE_SCALE)
		maxoffy = math.floor((tz + radius) / TILE_SCALE)
	end

	local offs_2 =
	{
		{-2,-2}, {-1,-2}, {0,-2}, {1,-2}, {2,-2},
		{-2,-1}, 						  {2,-1},
		{-2, 0}, 						  {2, 0},
		{-2, 1}, 						  {2, 1},
		{-2, 2}, {-1, 2}, {0, 2}, {1, 2}, {2, 2}
	}
	for i = 1, #offs_2, 1 do
		local curoff = offs_2[i]
		local offx, offy = curoff[1], curoff[2]

		local ground = map:GetTile(x + offx, y + offy)
		if IsLandTile(ground) then
			if not is_nearby_land_tile then
				is_nearby_land_tile = offx >= minoffx and offx <= maxoffx and offy >= minoffy and offy <= maxoffy
			end
			xtotal = xtotal + ((x + offx - halfw) * TILE_SCALE)
			ztotal = ztotal + ((y + offy - halfh) * TILE_SCALE)
			n = n + 1
		end
	end

	if n == 0 then return true end
	if not is_nearby_land_tile then return false end
	return -math.atan2(ztotal/n - ez, xtotal/n - ex)/DEGREES - 90
end

local function TrySpawnWavesOrShore(self, map, x, y, z)
	local bearing = GetWaveBearing(map, x, y, z)
	if bearing == false then return end

	if bearing == true then
		SpawnPrefab("wave_shimmer").Transform:SetPosition(x, y, z)
	else
		local wave = SpawnPrefab("wave_shore")
		wave.Transform:SetPosition( x, y, z )
		wave.Transform:SetRotation(bearing)
		wave:SetAnim()
	end
end
for _, data in pairs(TURF_LIST) do
    if data.item_prefab ~= nil then
        table.insert(Assets, Asset("ATLAS", "images/inventoryimages/"..data.item_prefab.."_turf.xml"))
        table.insert(Assets, Asset("IMAGE", "images/inventoryimages/"..data.item_prefab.."_turf.tex"))
        table.insert(Assets, Asset("ATLAS_BUILD", "images/inventoryimages/"..data.item_prefab.."_turf.xml", 256))
        AddPrefabPostInit("turf_"..data.item_prefab, function(inst)
            if not TheWorld.ismastersim then return end
            if inst.components.inventoryitem then
                inst.components.inventoryitem.atlasname = "images/inventoryimages/"..data.item_prefab.."_turf.xml"
                inst.components.inventoryitem.imagename = data.item_prefab.."_turf"
            end
        end)
    end
    if data.edge ~= nil then
        table.insert(Assets, Asset("ATLAS", "levels/tiles/"..data.edge..".xml"))
        table.insert(Assets, Asset("IMAGE", "levels/tiles/"..data.edge..".tex"))
    end
    if data.ocean_depth ~= nil then
        AddComponentPostInit("wavemanager", function(self)
            self.shimmer[WORLD_TILES[string.upper(data.id)]] = {per_sec = 80, spawn_rate = 0, tryspawn = TrySpawnWavesOrShore}
        end)
    end
end

---------------------------------------------------------------------------
---[[樱花岛管理组件]]
---------------------------------------------------------------------------
AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent("hmrcherryislandmanager")
end)

----------------------------------------------------------------------------
---[[花盆移栽]]
----------------------------------------------------------------------------
AddReplicableComponent("hmrtransplanter")

----------------------------------------------------------------------------
---[[人物添加跃迁组件]]
----------------------------------------------------------------------------
AddPlayerPostInit(function(player)
    player:AddComponent("hmrblinker")
	player.components.hmrblinker:SetBlinkFX()
end)

----------------------------------------------------------------------------
---[[添加buff通知]]
----------------------------------------------------------------------------
AddComponentPostInit("debuffable", function(Debuffable)
    local oldAddDebuff = Debuffable.AddDebuff
    function Debuffable:AddDebuff(name, ...)
        local debuff = oldAddDebuff(self, name, ...)
        if debuff ~= nil then
            self.inst:PushEvent("add_debuff", { debuff = debuff, name = name })
        end
        return debuff
    end

    local oldRemoveDebuff = Debuffable.RemoveDebuff
    function Debuffable:RemoveDebuff(name)
        local debuff = self.debuffs[name]
        if debuff ~= nil then
            self.inst:PushEvent("remove_debuff", { debuff = debuff, name = name })
        end
        oldRemoveDebuff(self, name)
    end
end)

AddReplicableComponent("hmrbuffviewer")

AddPlayerPostInit(function(player)
    if not TheWorld.ismastersim then
        return
    end
    player:AddComponent("hmrbuffviewer")
end)

local BuffPanel = require("widgets/hmr_buff_panel")
AddClassPostConstruct("widgets/statusdisplays", function(self, inst)
    self.hmr_buff_panel = self:AddChild(BuffPanel(self.owner))
    self.hmr_buff_panel:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
    self.hmr_buff_panel:SetVAnchor(1) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
    self.hmr_buff_panel:SetPosition(200, -200, 0)
end)

----------------------------------------------------------------------------
---[[修改便携香料站显示调味料理的OverrideSymbol]]
----------------------------------------------------------------------------
if TheNet:GetIsServer() or TheNet:IsDedicated() then
    local ALL_SPICES_DATA = HMR_LISTS.SPICE_DATA_LIST
    local HMR_SPICES = {}
    for name, data in pairs(ALL_SPICES_DATA) do
        if data.source ~= nil and data.source == "hmr" then
            HMR_SPICES[data.product] = true
        end
    end

    local OverrideSymbolHook = UserDataHook.MakeHook("AnimState", "OverrideSymbol", function(inst, symbol, build, file)
        if build == "spices" then
            if HMR_SPICES[string.lower(file)] then
                inst.userdatas.AnimState:OverrideSymbol(symbol, "hmr_spices", file)
                return true
            end
        end
        return false
    end)

    AddPrefabPostInit("portablespicer", function(inst)
        UserDataHook.Hook(inst, OverrideSymbolHook)
    end)
end

----------------------------------------------------------------------------
---[[建筑可摧毁修改，配合hmrworkblocker组件]]
----------------------------------------------------------------------------
AddComponentPostInit("workable", function(Workable)
    local function CanBeWorked(inst, worker)
        local x, y, z = inst.Transform:GetWorldPosition()
        local max_range = 100
        local blockers = TheSim:FindEntities(x, y, z, max_range, {"workblocker"})
        for _, blocker in pairs(blockers) do
            if blocker.components.hmrworkblocker and blocker.components.hmrworkblocker:CanBlock(inst, worker) then
                return false
            end
        end
        return true
    end

    local oldShouldRecoil = Workable.ShouldRecoil
    function Workable:ShouldRecoil(worker, ...)
        if not CanBeWorked(self.inst, worker) then
            return true, 0
        else
            return oldShouldRecoil(self, worker, ...)
        end
    end

    local oldWorkedBy_Internal = Workable.WorkedBy_Internal
    function Workable:WorkedBy_Internal(worker, ...)
        if not CanBeWorked(self.inst, worker) then
            return false
        else
            return oldWorkedBy_Internal(self, worker, ...)
        end
    end

    local oldWorkedBy = Workable.WorkedBy
    function Workable:WorkedBy(worker, ...)
        if not CanBeWorked(self.inst, worker) then
            return false
        else
            return oldWorkedBy(self, worker, ...)
        end
    end
end)

----------------------------------------------------------------------------
---[[嘲讽]]
----------------------------------------------------------------------------
AddComponentPostInit("combat", function(Combat)
    local oldTryRetarget = Combat.TryRetarget
    function Combat:TryRetarget()
        local taunted = false
        if not (self.inst.components.health ~= nil and self.inst.components.health:IsDead())
            and not (self.inst.components.sleeper ~= nil and self.inst.components.sleeper:IsInDeepSleep())
        then
            local leader = self.inst.components.follower and self.inst.components.follower:GetLeader() or self.inst
            if leader and leader:IsValid() then
                local is_companion = leader:HasOneOfTags({"player", "companion", "pet"})
                if not is_companion then
                    local x, y, z = leader.Transform:GetWorldPosition()
                    if x and y and z then
                        local mockers = TheSim:FindEntities(x, y, z, 20, {"mocker"})
                        if #mockers > 0 then
                            local dist, target = 1000000, nil
                            for _, mocker in pairs(mockers) do
                                local current_dist = leader:GetDistanceSqToInst(mocker)
                                if current_dist < dist then
                                    dist = current_dist
                                    target = mocker
                                end
                            end

                            if target ~= nil then
                                self:SetTarget(target)
                                self.lastwasattackedbytargettime = GetTime()
                                taunted = true

                                return
                            end
                        end
                    end
                end
            end
        end

        if not taunted then
            return oldTryRetarget(self)
        end
    end
end)

----------------------------------------------------------------------------
---[[皮肤更换容器背景]]
----------------------------------------------------------------------------
AddComponentPostInit("container", function(Container)
    function Container:SetUISkin(skin_name)
        if self.inst.replica.container ~= nil then
            self.inst.replica.container:SetUISkin(skin_name)
        end
    end
end)

AddClassPostConstruct("components/container_replica", function(Container)
    local containers = require "containers"
    local params = containers.params

    Container._skin_name = net_string(Container.inst.GUID, "hmr_container.skin_name", "skin_name_dirty")
    Container._skin_name:set("")

    Container.inst:ListenForEvent("skin_name_dirty", function()
        for player, opener in pairs(Container.openers) do
            if player.HUD then
                player:PushEvent("refreshcrafting")
                if player.HUD.controls then
                    local widget = player.HUD.controls.containers[Container.inst]
                    if widget then
                        widget:Refresh()
                    end
                end
            end
        end
    end)

    function Container:SetUISkin(skin_name)
        if skin_name == nil then
            skin_name = ""
        end
        self._skin_name:set(skin_name)
    end

    local oldGetWidget = Container.GetWidget
    function Container:GetWidget()
        local widget = deepcopy(oldGetWidget(self))
        local skin_name = self._skin_name:value()
        local widget_override = skin_name ~= "" and params[skin_name] and params[skin_name].widget
        if widget_override then
            for k, v in pairs(widget_override) do
                widget[k] = v
            end
        end
        return widget
    end
end)

----------------------------------------------------------------------------
---[[添加人物]]
----------------------------------------------------------------------------
-- [[人物性别：FEMALE,MALE,ROBOT,NEUTRAL,PLURAL]]

-- local skin_modes = {
--     {
--         type = "ghost_skin",
--         anim_bank = "ghost",
--         idle_anim = "idle",
--         scale = 0.75,
--         offset = { 0, -25 }
--     },
-- }
-- AddModCharacter("hmr_lingna", "FEMALE", skin_modes)
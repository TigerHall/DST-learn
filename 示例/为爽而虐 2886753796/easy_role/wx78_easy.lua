local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")

-- WX-78拆电路板不消耗耐久不掉电力
if GetModConfigData("WX-78 Safe Remove Module") then
    local module_definitions = require("wx78_moduledefs").module_definitions
    for _, def in ipairs(module_definitions) do
        AddPrefabPostInit("wx78module_" .. def.name, function(inst)
            if not TheWorld.ismastersim then return end
            if inst.components.upgrademodule and inst.components.upgrademodule.onremovedfromownerfn then
                local oldfn = inst.components.upgrademodule.onremovedfromownerfn
                inst.components.upgrademodule.onremovedfromownerfn = function(inst, ...)
                    if TUNING.saferemoveupgrademodule2hm and inst.components.finiteuses then return end
                    oldfn(inst, ...)
                end
            end
            -- 2025.10.13 melon:电路死亡不掉落
            if inst.components.inventoryitem then
                inst.components.inventoryitem.keepondeath = true -- 死亡不掉落
                inst.components.inventoryitem.keepondrown = true -- 溺水不掉落
            end
        end)
    end
    ACTIONS.REMOVEMODULES.fn = function(act)
        if (act.invobject ~= nil and act.invobject.components.upgrademoduleremover ~= nil) and
            (act.doer ~= nil and act.doer.components.upgrademoduleowner ~= nil) then
            if act.doer.components.upgrademoduleowner:NumModules() > 0 then
                TUNING.saferemoveupgrademodule2hm = true
                act.doer.components.upgrademoduleowner:PopOneModule()
                TUNING.saferemoveupgrademodule2hm = nil
                return true
            else
                return false, "NO_MODULES"
            end
        end
        return false
    end
    -- 2025.10.13 melon:电路提取器死亡不掉落
    AddPrefabPostInit("wx78_moduleremover", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.inventoryitem then
            inst.components.inventoryitem.keepondeath = true -- 死亡不掉落
            inst.components.inventoryitem.keepondrown = true -- 溺水不掉落
        end
    end)
    -- 2025.10.13 melon:无电路、电不满时右键扣5血回1格电 
    local _REMOVEMODULES_FAIL_fn = ACTIONS.REMOVEMODULES_FAIL.fn
    ACTIONS.REMOVEMODULES_FAIL.fn = function(act)
        if not act.doer.components.upgrademoduleowner:ChargeIsMaxed() then
            act.doer.components.upgrademoduleowner:AddCharge(1)
            if act.doer.components.health then act.doer.components.health:DoDelta(-5) end
        end
        return _REMOVEMODULES_FAIL_fn(act)
    end
    -- 2025.10.13 melon:生物扫描分析仪wx78_scanner跟随下地
    AddPrefabPostInit("wx78", function(inst)
        if not TheWorld.ismastersim then return end
        local _OnDespawn = inst.OnDespawn
		inst.wx78_scanner_save2hm = nil
		inst.OnDespawn = function(inst, migrationdata, ...) -- 随从下洞以及带下线代码
			for k, v in pairs(inst.components.leader.followers) do
				if k.prefab == "wx78_scanner" then 
					inst.wx78_scanner_save2hm = k:GetSaveRecord()
					-- remove followers
					k:AddTag("notarget")
					k:AddTag("NOCLICK")
					k.persists = false
					k:DoTaskInTime(0.1, function(k)
						local fx = SpawnPrefab("spawn_fx_small")
						fx.Transform:SetPosition(k.Transform:GetWorldPosition())
						if not k.components.colourtweener then
							k:AddComponent("colourtweener")
						end
						k.components.colourtweener:StartTween({ 0, 0, 0, 1 }, 13 * FRAMES, k.Remove)
					end)
                    -- break -- 只1个
				end
			end
			return _OnDespawn(inst, migrationdata, ...)
		end
		local _OnSave = inst.OnSave
		inst.OnSave = function(inst, data, ...)
			data.wx78_scanner_save2hm = inst.wx78_scanner_save2hm
			if _OnSave ~= nil then return _OnSave(inst, data, ...) end
		end
		local _OnLoad = inst.OnLoad
		inst.OnLoad = function(inst, data, ...)
			if data and data.wx78_scanner_save2hm then
                inst:DoTaskInTime(0.1, function(inst)
                    local follower = SpawnSaveRecord(data.wx78_scanner_save2hm)
                    inst.components.leader:AddFollower(follower)
                    follower:DoTaskInTime(0, function(follower)
                        if inst:IsValid() and not follower:IsNear(inst, 8) then
                            follower.Transform:SetPosition(inst.Transform:GetWorldPosition())
                            follower.sg:GoToState("idle")
                        end
                    end)
                    local fx = SpawnPrefab("spawn_fx_small")
                    fx.Transform:SetPosition(follower.Transform:GetWorldPosition())
                end)
			end
			if _OnLoad ~= nil then return _OnLoad(inst, data, ...) end
		end
    end)
end

-- WX-78同种电路板融合升级
if GetModConfigData("WX-78 Integrated Upgrade Module Level") then
    -- 移速数值扩展
    local index = #TUNING.WX78_MOVESPEED_CHIPBOOSTS
    local diff = TUNING.WX78_MOVESPEED_CHIPBOOSTS[index] - TUNING.WX78_MOVESPEED_CHIPBOOSTS[index - 1]
    for i = index + 1, TUNING.WX78_MAXELECTRICCHARGE, 1 do
        TUNING.WX78_MOVESPEED_CHIPBOOSTS[i] = math.clamp(TUNING.WX78_MOVESPEED_CHIPBOOSTS[i - 1] + diff, 0, 10)
    end
    local function DisplayNameFn(inst)
        if inst.level2hm:value() ~= 1 then
            return inst.name .. " Lv" .. inst.level2hm:value()
        else
            return inst.name
        end
    end
    local function OnSave(inst, data)
        if inst.level2hm ~= nil then
            data.level = inst.level2hm:value()
        else
            data.level = 1
        end
    end
    local function OnLoad(inst, data) if data ~= nil then if data.level ~= nil then inst.level2hm:set(data.level) end end end
    local module_definitions = require("wx78_moduledefs").module_definitions
    local function itemtilefn(inst)
        local leveltext
        if inst.level2hm and inst.level2hm:value() >= 2 then leveltext = "Lv" .. inst.level2hm:value() end
        return "level2hmdirty", leveltext
    end
    for _, def in ipairs(module_definitions) do
        AddPrefabPostInit("wx78module_" .. def.name, function(inst)
            inst.repairmaterials2hm = {scandata = 1}
            inst.level2hm = net_smallbyte(inst.GUID, "module.level2hm", "level2hmdirty")
            inst.itemtilefn2hm = itemtilefn
            inst.displaynamefn = DisplayNameFn
            if not TheWorld.ismastersim then return end
            inst:DoTaskInTime(0.1, function(inst)
                if TUNING.DSTU and not inst.components.finiteuses and inst.components.fueled then
                    inst.repairmaterials2hm.scandata = 480 * 5
                end
            end)
            inst.level2hm:set(1)
            inst.OnSave = OnSave
            inst.OnLoad = OnLoad
            -- if not TUNING.DSTU then 
            inst:AddComponent("repairable2hm")
            -- end
            -- inst.components.repairable2hm.customrepair = onrepair
        end)
    end
    -- if TUNING.DSTU and FUELTYPE.CIRCUITBITS then
    --     AddPrefabPostInit("scandata", function(inst)
    --         if not TheWorld.ismastersim then return end
    --         inst:AddComponent("fuel")
    --         inst.components.fuel.fueltype = FUELTYPE.CIRCUITBITS
    --         inst.components.fuel.fuelvalue = 480 * 5
    --     end)
    -- end
    AddComponentPostInit("upgrademodule", function(self)
        local TryActivate = self.TryActivate
        self.TryActivate = function(self, isloading, ...)
            if not self.activated and self.inst.level2hm then
                self.activated = true
                local level = self.inst.level2hm:value()
                if self.onactivatedfn ~= nil then
                    for index = 1, level or 1 do
                        if index == 1 then
                            self.onactivatedfn(self.inst, self.target, isloading)
                        else
                            self.tmp2hm = self.tmp2hm or {}
                            local tmpinst = self.tmp2hm[index - 1] or SpawnPrefab(self.inst.prefab)
                            if tmpinst and tmpinst:IsValid() then
                                tmpinst.components.upgrademodule:SetTarget(self.target)
                                self.tmp2hm[index - 1] = tmpinst
                                self.onactivatedfn(tmpinst, self.target, isloading)
                                tmpinst.persists = false
                                self.inst:AddChild(tmpinst)
                                tmpinst:RemoveFromScene()
                                tmpinst.Transform:SetPosition(0, 0, 0)
                            end
                        end
                    end
                end
            else
                TryActivate(self, isloading, ...)
            end
        end
        local TryDeactivate = self.TryDeactivate
        self.TryDeactivate = function(self, ...)
            if self.activated and self.inst.level2hm then
                self.activated = false
                local level = self.inst.level2hm:value()
                if self.ondeactivatedfn ~= nil then
                    for index = level or 1, 1, -1 do
                        if index == 1 then
                            self.ondeactivatedfn(self.inst, self.target)
                        else
                            self.tmp2hm = self.tmp2hm or {}
                            local tmpinst = self.tmp2hm[index - 1]
                            if tmpinst and tmpinst:IsValid() then
                                self.ondeactivatedfn(tmpinst, self.target)
                                self.tmp2hm[index - 1] = nil
                                tmpinst:Remove()
                            end
                        end
                    end
                end
            else
                TryDeactivate(self, ...)
            end
        end
    end)
    AddComponentPostInit("upgrademoduleowner", function(self)
        self.CanUpgrade = function(self, module_instance)
            if self._last_upgrade_time ~= nil then if (self._last_upgrade_time + self.upgrade_cooldown) > GetTime() then return false, "COOLDOWN" end end
            local slots = module_instance.components.upgrademodule.slots
            if module_instance.level2hm then
                local count = 0
                count = count + module_instance.level2hm:value()
                for _, module in ipairs(self.modules) do
                    if module.prefab == module_instance.prefab and module.level2hm then count = count + module.level2hm:value() end
                end
                if TUNING.WX78_MAXELECTRICCHARGE / slots < count then return false, "NOTENOUGHSLOTS" end
            end
            if self.canupgradefn ~= nil then
                return self.canupgradefn(self.inst, module_instance)
            else
                return true
            end
        end
    end)
    AddComponentAction("USEITEM", "upgrademodule", function(inst, doer, target, actions)
        if inst.prefab == target.prefab and doer:HasTag("upgrademoduleowner") then table.insert(actions, ACTIONS.UPGRADE) end
    end)
    local oldUPGRADEfn = ACTIONS.UPGRADE.fn
    ACTIONS.UPGRADE.fn = function(act)
        if oldUPGRADEfn(act) then return true end
        if act.invobject and act.target and act.invobject.prefab == act.target.prefab and act.invobject.components.upgrademodule and
            act.target.components.upgrademodule and act.invobject.level2hm and act.target.level2hm and
            (act.invobject.level2hm:value() + act.target.level2hm:value()) <= (TUNING.WX78_MAXELECTRICCHARGE / act.invobject.components.upgrademodule.slots) then
            act.target.level2hm:set(act.invobject.level2hm:value() + act.target.level2hm:value())
            if act.doer then
                local shinefx = SpawnPrefab("pocketwatch_warpback_fx")
                shinefx.AnimState:SetTime(10 * FRAMES)
                shinefx.entity:SetParent(act.doer.entity)
            end
            if act.target.components.finiteuses then act.target.components.finiteuses:SetUses(TUNING.WX78_MODULE_USES) end
            act.invobject:Remove()
            return true
        end
    end
end

-- WX-78吃齿轮升级
if GetModConfigData("WX-78 Eat Gears InCrease Data") then
    local function OnLoad(inst, data)
        if data ~= nil then
            inst.gearslevel2hm = math.min(inst._gears_eaten or 0, 15)
            inst.components.health.maxhealth = inst.components.health.maxhealth + inst.gearslevel2hm * 5
            inst.components.sanity.max = inst.components.sanity.max + inst.gearslevel2hm * 5
            inst.components.hunger.max = inst.components.hunger.max + inst.gearslevel2hm * 5
            if data._wx78_health then inst.components.health:SetCurrentHealth(data._wx78_health) end
            if data._wx78_sanity then inst.components.sanity.current = data._wx78_sanity end
            if data._wx78_hunger then inst.components.hunger.current = data._wx78_hunger end
        end
    end
    local function OnEat(inst, data)
        if data.food ~= nil and data.food.components.edible ~= nil and data.food.components.edible.foodtype == FOODTYPE.GEARS and inst.gearslevel2hm < 15 then
            inst.gearslevel2hm = (inst.gearslevel2hm or 0) + 1
            inst.components.health.maxhealth = inst.components.health.maxhealth + 5
            inst.components.sanity.max = inst.components.sanity.max + 5
            inst.components.hunger.max = inst.components.hunger.max + 5
            inst.components.health:DoDelta(5)
            inst.components.sanity:DoDelta(5)
            inst.components.hunger:DoDelta(5)
        end
    end
    local function OnDeath(inst)
        inst.components.health.maxhealth = inst.components.health.maxhealth - inst.gearslevel2hm * 5
        inst.components.sanity.max = inst.components.sanity.max - inst.gearslevel2hm * 5
        inst.components.hunger.max = inst.components.hunger.max - inst.gearslevel2hm * 5
        inst.gearslevel2hm = 0
    end
    AddPrefabPostInit("wx78", function(inst)
        if not TheWorld.ismastersim then return end
        inst.gearslevel2hm = 0
        SetOnLoad(inst, OnLoad)
        inst:ListenForEvent("oneat", OnEat)
        inst:ListenForEvent("death", OnDeath)
    end)
end

--2025.11.2夜风wx-78芯片容器
-- WX-78右键自身打开芯片容器(只能储存芯片/电路板/生物数据/钳子)
if GetModConfigData("wx78_module_pack") then
    -- 给 WX-78 相关物品添加标签（用于容器过滤）
    local function AddToolboxItemTag(prefab)
        AddPrefabPostInit(prefab, function(inst)
            inst:AddTag("wx78_toolbox_item")
        end)
    end
    
    -- 添加标签到所有模块
    local module_definitions = require("wx78_moduledefs").module_definitions
    for _, def in ipairs(module_definitions) do
        AddToolboxItemTag("wx78module_" .. def.name)
    end
    
    -- 添加标签到其他物品
    local wx78_items = {"wx78_scanner", "scandata", "wx78_moduleremover"}
    for _, prefab in ipairs(wx78_items) do
        AddToolboxItemTag(prefab)
    end
    
    -- 定义虚拟芯片容器参数（使用标签过滤）
    local containers = require("containers")
    containers.params.wx78_toolbox = {
        widget = {
            slotpos = {},
            animbank = "ui_tacklecontainer_3x2",
            animbuild = "ui_tacklecontainer_3x2",
            pos = Vector3(0, 200, 0),
            side_align_tip = 160,
        },
        type = "chest",
        itemtestfn = function(container, item, slot)
            return item ~= nil and item:HasTag("wx78_toolbox_item")
        end,
    }
    
    -- 设置 6 格槽位位置
    for y = 0, 1 do
        for x = 0, 2 do
            table.insert(containers.params.wx78_toolbox.widget.slotpos, Vector3(80 * x - 80, 80 * y - 40, 0))
        end
    end
    
    -- 初始化虚拟芯片容器
    local function inittoolbox(inst)
        if inst.toolbox2hm and inst.toolbox2hm:IsValid() then return end
        
        local toolbox = SpawnPrefab("wx78_toolbox")
        if not (toolbox and toolbox:IsValid() and toolbox.components.container) then return end
        
        -- 恢复保存的容器数据
        if inst.components.persistent2hm and inst.components.persistent2hm.data.wx78_toolbox then
            toolbox.components.container.init2hm = true
            toolbox:SetPersistData(inst.components.persistent2hm.data.wx78_toolbox)
            toolbox.components.container.init2hm = nil
            inst.components.persistent2hm.data.wx78_toolbox = nil
        end
        
        -- 设置容器属性和关联关系
        toolbox:AddTag("dcs2hm")
        toolbox:AddTag("NOBLOCK")
        inst.toolbox2hm = toolbox
        toolbox.master2hm = inst
        toolbox.components.container.skipautoclose = true
        toolbox.components.container.usespecificslotsforitems = false
        toolbox.components.container.acceptsstacks = true
        toolbox.persists = false
        toolbox:Hide()
        inst:AddChild(toolbox)
    end
    
    -- OnSave 时序列化容器数据
    local function OnSave(inst, data)
        if inst.toolbox2hm and inst.toolbox2hm:IsValid() then
            local persistdata = inst.toolbox2hm:GetPersistData()
            if persistdata then
                data.wx78_toolbox = persistdata
            end
        end
    end
    
    AddPrefabPostInit("wx78", function(inst)
        if not TheWorld.ismastersim then return end
        
        -- 添加 persistent2hm 组件
        if not inst.components.persistent2hm then 
            inst:AddComponent("persistent2hm")
        end
        
        -- 注册 OnSave
        SetOnSave2hm(inst, OnSave)
        
        -- 延迟初始化容器
        inst:DoTaskInTime(0, inittoolbox)
    end)
    -- 添加右键自身打开/关闭芯片容器功能
    AddRightSelfAction("wx78", 0, "dolongaction", nil, function(act)
        if act.doer and act.doer.prefab == "wx78" then
            local toolbox = act.doer.toolbox2hm
            if toolbox and toolbox:IsValid() and toolbox.components.container and act.doer == toolbox.master2hm then
                if toolbox.components.container.openlist[act.doer] then
                    toolbox.components.container:Close(act.doer)
                else
                    toolbox.components.container:Open(act.doer)
                end
                return true
            else
                -- 容器不存在或无效，重新初始化
                act.doer:DoTaskInTime(0, inittoolbox)
                return false
            end
        end
    end, TUNING.isCh2hm and "芯片容器" or "Circuit Container", nil, nil)
end  

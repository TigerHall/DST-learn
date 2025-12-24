local MOD_NAME = "HMR"

local UTIL = {}
GLOBAL[MOD_NAME.."_UTIL"] = UTIL

-- ----------------------------------------------------------------------------
-- ---[[判断网络]]
-- ----------------------------------------------------------------------------
UTIL.GetIsServer = function()
    return TheNet and(TheNet:GetIsServer() or TheNet:IsDedicated()) or
        TheWorld and TheWorld.ismastersim
end

UTIL.GetIsClient = function()
    return TheNet and TheNet:GetIsClient() or
        not UTIL.GetIsServer()
end

----------------------------------------------------------------------------
---[[模组名字]]
----------------------------------------------------------------------------
UTIL.GetModName = function()
    return env.modname
end

----------------------------------------------------------------------------
---[[提前注册prefab]]
----------------------------------------------------------------------------
local PRE_REGISTER_ID = 0
UTIL.PreRegisterPrefab = function(...)
    local allprefab = {}
    local function RegModPrefab(data)
        data.search_asset_first_path = MODS_ROOT .. UTIL.GetModName() .. "/" -- 资源优先搜索路径
        RegisterSinglePrefab(data)
        PREFABDEFINITIONS[data.name] = data
        env.Prefabs[data.name] = data
        table.insert(allprefab, data.name) -- 注册到mod环境里 
        Prefabs[data.name] = data -- 注册到全局环境
    end

    for i, v in ipairs({...}) do
        RegModPrefab(v)
    end

    local all_foods_prefab = Prefab(UTIL.GetModName().."_pre_reg_"..PRE_REGISTER_ID, nil, Assets, allprefab, true)
    all_foods_prefab.search_asset_first_path = MODS_ROOT .. HMR_UTIL.GetModName() .. "/"
    RegisterSinglePrefab(all_foods_prefab)
    TheSim:LoadPrefabs({all_foods_prefab.name})
    table.insert(ModManager.loadedprefabs, all_foods_prefab.name)
end

----------------------------------------------------------------------------
---[[初始化]]
----------------------------------------------------------------------------
AddPrefabPostInitAny(function(inst)
    if inst[MOD_NAME] == nil then
        inst[MOD_NAME] = {}
    end

    inst[MOD_NAME].tasks = {} -- 任务
end)

AddPlayerPostInit(function(inst)
    if inst[MOD_NAME] == nil then
        inst[MOD_NAME] = {}
    end

    inst[MOD_NAME].tags = {}            -- 标签
    inst[MOD_NAME].statuseffects = {}   -- 状态效果
end)

----------------------------------------------------------------------------
---[[常用图标]]
----------------------------------------------------------------------------
-- TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_PRIMARY)
-- TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_SECONDARY)

----------------------------------------------------------------------------
---[[数据编码]]
----------------------------------------------------------------------------
UTIL.EncodeData = function(data)
    local success, str = pcall(json.encode, data)
    if success then
        return str
    else
        -- UTIL.PrintLog("数据编码失败："..tostring(data))
        return nil
    end
end

UTIL.DecodeData = function(str)
    local success, data = pcall(json.decode, str)
    if success then
        return data
    else
        -- UTIL.PrintLog("数据解码失败："..tostring(str))
        return nil
    end
end

----------------------------------------------------------------------------
---[[数字处理]]
----------------------------------------------------------------------------
UTIL.FormatNumber = function(number, decimal_places)
    decimal_places = decimal_places or 2
    return tonumber(string.format("%." .. decimal_places .. "f", number))
end

UTIL.Round = function(number, decimal_places)
    decimal_places = decimal_places or 0
    local factor = 10^decimal_places
    return math.floor(number * factor + 0.5) / factor
end

----------------------------------------------------------------------------
---[[数据存储]]
----------------------------------------------------------------------------
UTIL.GetPersistentString = function(key)
    local result, success = nil, false
    TheSim:GetPersistentString(key, function(load_success, str)
        if load_success then
            local decode_success, value = pcall(json.decode, str)
            if decode_success then
                result = value
                success = true
            end
        end
    end, false)

    if success then
        print("【"..MOD_NAME.."】成功读取本地数据"..key)
        return result
    else
        print("【"..MOD_NAME.."】读取本地数据"..key.."失败")
        return nil
    end
end

UTIL.SetPersistentString = function(key, value)
    local encode_success, str = pcall(json.encode, value)
    if encode_success then
        TheSim:SetPersistentString(key, str, false)
        print("【"..MOD_NAME.."】成功保存本地数据"..key)
        return true
    else
        print("【"..MOD_NAME.."】保存本地数据"..key.."失败")
        return false
    end
end

----------------------------------------------------------------------------
---[[模组配置]]
----------------------------------------------------------------------------
UTIL.CollectDefaultConfigs = function(group, test)
    local configs = {}
    for k, v in pairs(group) do
        if type(v) == "table" and (test == nil or test(v)) then
            configs[v.name] = v.default
        end
    end
    return configs
end

UTIL.GetDefaultConfig = function(key, group)
    for k, v in pairs(group) do
        if type(v) == "table" and v.name == key then
            return v.default
        end
    end
end

local function IsControlConfig(config)
    return config.options ~= nil and
        type(config.options[1]) == "string" and
        config.options[1] == "binding_common"
end

local function IsClientConfig(config)
    return config.options ~= nil and
        type(config.options[1]) == "table"
end

local function ApplySavedConfig(config, saved_config)
    if saved_config ~= nil then
        for k, v in pairs(saved_config) do
            config[k] = v
        end
    end
end

local CONFIG_DATA = require("hmrmain/hmr_config_data")

GLOBAL.HMR_CONTROLS = UTIL.CollectDefaultConfigs(CONFIG_DATA.client, IsControlConfig)
GLOBAL.HMR_CLIENT_CONFIGS = UTIL.CollectDefaultConfigs(CONFIG_DATA.client, IsClientConfig)
GLOBAL.HMR_SERVER_CONFIGS = UTIL.CollectDefaultConfigs(CONFIG_DATA.server)

ApplySavedConfig(HMR_CONTROLS, UTIL.GetPersistentString("HMR_CONTROLS"))
ApplySavedConfig(HMR_CLIENT_CONFIGS, UTIL.GetPersistentString("HMR_CLIENT_CONFIGS"))
ApplySavedConfig(HMR_SERVER_CONFIGS, UTIL.GetPersistentString("HMR_SERVER_CONFIGS"))

UTIL.GetConfig = function(key, group) -- TODO:根据group检索设置
    if HMR_CONTROLS[key] ~= nil then
        return HMR_CONTROLS[key]
    elseif HMR_CLIENT_CONFIGS[key] ~= nil then
        return HMR_CLIENT_CONFIGS[key]
    elseif HMR_SERVER_CONFIGS[key] ~= nil then
        return HMR_SERVER_CONFIGS[key]
    end
end

----------------------------------------------------------------------------
---[[UI缩放]]
----------------------------------------------------------------------------
local ZOOM_SIZE_CACHE = {} -- 临时存储缩放大小
local ORIGINAL_SIZE = {} -- 所有UI的原大小

local function LoadZoomSize()
    local data = UTIL.GetPersistentString(MOD_NAME.."_ZOOM_SIZE")
    if data ~= nil and type(data) == "table" then
        for widget_type, size in pairs(data) do
            ZOOM_SIZE_CACHE[widget_type] = size
        end
    end
end
local function SaveZoomSize()
	if next(ZOOM_SIZE_CACHE) then
		UTIL.SetPersistentString(MOD_NAME.."_ZOOM_SIZE", ZOOM_SIZE_CACHE)
	end
end

-- 获取缩放大小
UTIL.GetUISize = function(widget_type)
    if ZOOM_SIZE_CACHE[widget_type] == nil then
        LoadZoomSize()
    end
    return ZOOM_SIZE_CACHE[widget_type]
end

--重置缩放大小
UTIL.ResetUISize = function()
	ZOOM_SIZE_CACHE = {}
	UTIL.SetPersistentString(MOD_NAME.."_ZOOM_SIZE", ZOOM_SIZE_CACHE)
	for k, v in pairs(ORIGINAL_SIZE) do
		if k.inst and k.inst:IsValid() and v ~= nil then
			k:SetScale(v.x, v.y, v.z) -- 重置
		else
			ORIGINAL_SIZE[k] = nil
		end
	end
end

-- 添加可拖拽UI
--[[
params:
	self: 缩放父亲UI
	target_ui: 拖拽目标UI，一般为动画或贴图背景
	widget_type: UI类型
	data: 拖拽数据
		owner: 拖拽所属对象（需要具有DoTaskInTime方法）
		drag_offset: 拖拽速度比（有时鼠标与UI的移动速度不统一，需要用这个调整）
			数字越大，鼠标的相对速度越快（UI的相对速度越小）
			常用值：容器--0.6，按钮（丰耘科技）--0.925
]]
UTIL.AddZoomableUI = function(self, target_ui, widget_type, data)
    if self == nil or self.zoomable then
        return
    end
    self.zoomable = true
	ORIGINAL_SIZE[self] = self:GetScale() -- 存储UI原缩放

    data = data or {}

	-- 恢复保存的位置
	local owner = data.owner or self.owner or self.inst or self.container
	local saved_size = UTIL.GetUISize(widget_type)
	if owner ~= nil and saved_size ~= nil then
		owner:DoTaskInTime(0, function()
			self:SetScale(saved_size, saved_size, saved_size)
		end)
	end

	-- 拖拽提示
    local function AddToolTip(target)
        if target ~= nil then
            local old_tooltip = target.tooltip
            local tooltip_icon = TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_ZOOM_OUT)..TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_ZOOM_IN)
            if old_tooltip ~= nil then
                target:SetTooltip(old_tooltip.."\n"..tooltip_icon.."缩放")
            else
                target:SetTooltip(tooltip_icon.."缩放")
            end
        end
	end
    AddToolTip(self.bgimage)
    AddToolTip(self.bganim)
    AddToolTip(target_ui)

	--设置拖拽坐标
	function self:SetZoomSize(zoom_in)
		local sx, sy, sz = self.inst.UITransform:GetScale()
		local speed = data and data.zoom_speed or 1
        local zoom_scale = (zoom_in and 0.01 or -0.01) * speed + 1

        local newscale_x = zoom_scale * sx
        local newscale_y = zoom_scale * sy
        local newscale_z = zoom_scale * sz
        if 0.1 <= newscale_x and newscale_x <= 10 and
            0.1 <= newscale_y and newscale_y <= 10 and
            0.1 <= newscale_z and newscale_z <= 10
        then
		    self:SetScale(newscale_x, newscale_y, newscale_z)

            ZOOM_SIZE_CACHE[widget_type] = Vector3(newscale_x, newscale_y, newscale_z)
            SaveZoomSize()
        end
	end

	local oldOnControl = self.OnControl
	function self:OnControl(control, down)
		if control == CONTROL_ZOOM_IN then
            self:SetZoomSize(true)
		end
        if control == CONTROL_ZOOM_OUT then
            self:SetZoomSize(false)
		end

		if oldOnControl then
			return oldOnControl(self, control, down)
		end
	end
end

----------------------------------------------------------------------------
---[[UI拖拽]]
----------------------------------------------------------------------------
local DRAG_POS_CACHE = {} -- 临时存储拖拽坐标
local ORIGINAL_POS = {} -- 所有UI的原坐标

local function LoadDragPos()
    local data = UTIL.GetPersistentString(MOD_NAME.."_DRAG_POS")
    if data ~= nil and type(data) == "table" then
        for widget_type, pos in pairs(data) do
            DRAG_POS_CACHE[widget_type] = Vector3(pos.x, pos.y, pos.z)
        end
    end
end

local function SaveDragPos()
	if next(DRAG_POS_CACHE) then
		UTIL.SetPersistentString(MOD_NAME.."_DRAG_POS", DRAG_POS_CACHE)
	end
end

-- 获取拖拽坐标
UTIL.GetUIPos = function(widget_type)
    if DRAG_POS_CACHE[widget_type] == nil then
        LoadDragPos()
    end
    return DRAG_POS_CACHE[widget_type]
end

--重置拖拽坐标
UTIL.ResetUIPos = function()
	DRAG_POS_CACHE = {}
	UTIL.SetPersistentString(MOD_NAME.."_DRAG_POS", DRAG_POS_CACHE)
	for k, v in pairs(ORIGINAL_POS) do
		if k.inst and k.inst:IsValid() and v ~= nil then
			k:SetPosition(v) -- 重置坐标
		else
			ORIGINAL_POS[k] = nil
		end
	end
end

AddPlayerPostInit(function(player)
    if not TheWorld.ismastersim then
        -- 如果有一个父体是可缩放的，那他就是可缩放的
        local function IsZoomableWidget(widget)
            if widget ~= nil and widget.zoomable then
                return true
            end
            local parent = widget:GetParent()
            if parent == nil then
                return false
            else
                return IsZoomableWidget(parent)
            end
        end
        -- 是否正在进行缩放
        local function IsZoomingUI()
            local entity = TheInput:GetHUDEntityUnderMouse()
            if entity ~= nil and IsZoomableWidget(entity.widget) and
                (TheInput:IsControlPressed(CONTROL_ZOOM_IN) or TheInput:IsControlPressed(CONTROL_ZOOM_OUT))
            then
                return true
            end
            return false
        end

        local oldZoomIn = TheCamera.ZoomIn
        TheCamera.ZoomIn = function(self, ...)
            if IsZoomingUI() then
                return
            end
            oldZoomIn(self, ...)
        end
        local oldZoomOut = TheCamera.ZoomOut
        TheCamera.ZoomOut = function(self, ...)
            if IsZoomingUI() then
                return
            end
            oldZoomOut(self, ...)
        end
    end
end)

-- 添加可拖拽UI
--[[
params:
	self: 拖拽父亲UI
	target_ui: 拖拽目标UI，一般为动画或贴图背景
	widget_type: UI类型
	data: 拖拽数据
		owner: 拖拽所属对象（需要具有DoTaskInTime方法）
		drag_offset: 拖拽速度比（有时鼠标与UI的移动速度不统一，需要用这个调整）
			数字越大，鼠标的相对速度越快（UI的相对速度越小）
			常用值：容器--0.6，按钮（丰耘科技）--0.925
]]
UTIL.AddDraggableUI = function(self, target_ui, widget_type, data)
    if self == nil or self.dragable then
        return
    end
    self.dragable = true
	ORIGINAL_POS[self] = self:GetPosition() -- 存储UI原坐标

    data = data or {}

	-- 恢复保存的位置
	local owner = data.owner or self.owner or self.inst or self.container
	local saved_pos = UTIL.GetUIPos(widget_type)
	if owner ~= nil and saved_pos ~= nil then
		owner:DoTaskInTime(0, function()
			self:SetPosition(saved_pos)
		end)
	end

	-- 拖拽提示
    local function AddToolTip(target)
        if target ~= nil and target.SetTooltip ~= nil then
            local old_tooltip = target.tooltip
            if old_tooltip ~= nil then
                target:SetTooltip(old_tooltip.."\n"..TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_SECONDARY).."拖拽")
            else
                target:SetTooltip(TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_SECONDARY).."拖拽")
            end
        end
	end
    AddToolTip(self.bgimage)
    AddToolTip(self.bganim)
    AddToolTip(target_ui)

	--设置拖拽坐标
	function self:SetDragPosition(x, y, z)
		local pos
		if type(x) == "number" then
			pos = Vector3(x, y, z)
		else
			pos = x
		end

		local self_scale = Vector3(self.inst.UITransform:GetScale()) -- 自身的缩放
        local final_scale = self:GetScale()                          -- 自身与父体共同的缩放

        local newpos = self.p_startpos + (pos-self.m_startpos)/(data.drag_offset or final_scale.x/self_scale.x)
		self:SetPosition(newpos)
	end

	--开始拖动
	function self:StartDrag()
		if not self.followhandler then
			local mousepos = TheInput:GetScreenPosition()
			self.m_startpos = mousepos--鼠标初始坐标
			self.p_startpos = self:GetPosition()--面板初始坐标
			self.followhandler = TheInput:AddMoveHandler(function(x, y)
				self:SetDragPosition(x, y, 0)
				if not Input:IsMouseDown(MOUSEBUTTON_RIGHT) then
					self:EndDrag()
				end
			end)
			self:SetDragPosition(mousepos)
		end
	end

	--停止拖动
	function self:EndDrag()
		if self.followhandler then
			self.followhandler:Remove()
		end
		self.followhandler = nil
		self.m_startpos = nil
		self.p_startpos = nil
		local newpos = self:GetPosition()
		if widget_type ~= nil then
			DRAG_POS_CACHE[widget_type] = newpos
		end
		SaveDragPos()
	end

	local oldOnControl = self.OnControl
	function self:OnControl(control, down)
		if control == CONTROL_SECONDARY then
			if down then
				self:StartDrag()
			else
				self:EndDrag()
			end
		end
		if oldOnControl then
			return oldOnControl(self, control, down)
		end
	end
end

-- 拥有标签的容器即可拖拽或缩放，标签如下：
-- dragablecontainerui
-- zoomablecontainerui
AddClassPostConstruct("widgets/containerwidget", function(ContainerWidget)
    local oldOpen = ContainerWidget.Open
    function ContainerWidget:Open(container, ...)
        oldOpen(self, container, ...)
        if container ~= nil and (container:HasTag("dragablecontainerui") or container:HasTag("zoomablecontainerui")) then
            local widget = self.container.replica.container:GetWidget()
			if widget then
				local drag_type = widget.dragtype or container.prefab
				if drag_type and container:HasTag("dragablecontainerui") then
                    UTIL.AddDraggableUI(self, self.bgimage, drag_type--[[, {drag_offset = 0.6}]])
                    UTIL.AddDraggableUI(self, self.bganim, drag_type--[[, {drag_offset = 0.6}]])
					--设置容器坐标(可装备的容器第一次打开做个延迟，不然加载游戏进来位置读不到)
					local newpos = UTIL.GetUIPos(drag_type)
					if newpos then
						if self.container:HasTag("_equippable") and not self.container.isopended then
							self.container:DoTaskInTime(0, function()
								self:SetPosition(newpos)
							end)
							self.container.isopended = true
						else
							self:SetPosition(newpos)
						end
					end
				end

                local zoom_type = widget.zoomtype or container.prefab
                if zoom_type and container:HasTag("zoomablecontainerui") then
                    UTIL.AddZoomableUI(self, self.bgimage, drag_type, {speed = 1})
                    UTIL.AddZoomableUI(self, self.bganim, drag_type, {speed = 1})
                    local newsize = UTIL.GetUISize(drag_type)
                    if newsize then
                        if self.container:HasTag("_equippable") and not self.container.isopended then
							self.container:DoTaskInTime(0, function()
								self:SetScale(newsize.x, newsize.y, newsize.z)
							end)
							self.container.isopended = true
						else
							self:SetScale(newsize.x, newsize.y, newsize.z)
						end
                    end
                end
			end
        end
    end
end)

AddPlayerPostInit(function(player)
    if not TheWorld.ismastersim then
        local function ResetUIPos(_, data)
            if data.value then
                UTIL.ResetUIPos()
            end
        end
        player:ListenForEvent("RESET_UI_POS_dirty", ResetUIPos)
    end
end)

----------------------------------------------------------------------------
---[[添加键盘控制]]
----------------------------------------------------------------------------
--[[
    RPC_name
    keys_data = {{down = true, continuous = true, key = KEY, params = {}}, ... }
    handlerfn = function(player, data)
    key_from_config_override = config_name
]]
UTIL.AddKeyboardControl = function(RPC_name, keys_data, handlerfn, key_from_config_override, key_from)
    AddClassPostConstruct("screens/playerhud", function(self)
        local modname = KnownModIndex:GetModActualName("[DST]丰耘秘境 Harvest Mysterious Realm")
        local isdown = {}
        local oldOnRawKey = self.OnRawKey
        function self:OnRawKey(key, down, ...)
            if oldOnRawKey(self, key, down) then
                return true
            end
            for _, key_data in pairs(keys_data) do
                local real_key = key_from_config_override and GetModConfigData(key_from_config_override, modname) or key_data.key
                if UTIL.GetConfig(key_data.key) ~= nil then
                    real_key = UTIL.GetConfig(key_data.key)
                elseif key_from_config_override and GetModConfigData(key_from_config_override, modname) ~= nil then
                    real_key = GetModConfigData(key_from_config_override, modname)
                elseif key_data.key ~= nil then
                    real_key = key_data.key
                end

                local name = key_data.name or real_key

                if key == real_key then
                    local param
                    if key_data.params ~= nil then
                        if type(key_data.params) == "function" then
                            param = key_data.params(self, key, down)
                        else
                            param = key_data.params
                        end
                    end
                    if key_data.continuous then
                        if down == key_data.down then
                            SendModRPCToServer(MOD_RPC[MOD_NAME][RPC_name], param)
                        end
                    else
                        if isdown[name] == nil then
                            isdown[name] = false
                        end

                        if isdown[name] ~= down then
                            isdown[name] = down
                            if down == key_data.down then
                                SendModRPCToServer(MOD_RPC[MOD_NAME][RPC_name], param)
                            end
                        end
                    end
                end
            end
        end
    end)
    AddModRPCHandler(MOD_NAME, RPC_name, function(player, data)
        if handlerfn ~= nil then
            handlerfn(player, data)
        end
    end)
end

----------------------------------------------------------------------------
---[[攻击]]
----------------------------------------------------------------------------
local function CanAttack(attacker, target)
    return attacker and
        attacker.components.combat ~= nil and
        attacker.components.combat:CanTarget(target) and
        not attacker.components.combat:IsAlly(target)
end

UTIL.Attack = function(attacker, target, damage, special_damage, data)
    data = data or {}
    if target and target:IsValid() and target.components.health then
        if data.attacktest ~= nil and data.attacktest(attacker, target) or CanAttack(attacker, target) then
            if target.components.combat ~= nil and target.components.combat:CanBeAttacked() then
                return target.components.combat:GetAttacked(attacker, damage, data.weapon, data.stimuli, special_damage)
            else
                target.components.health:DoDelta(- damage)
                return true
            end
        end
    else
        -- UTIL.PrintLog("UTIL.Attack: target is nil or has no health component")
    end
    return false
end

----------------------------------------------------------------------------
---[[容器背景]]
----------------------------------------------------------------------------
-- 更复杂的背景动画
AddClassPostConstruct("widgets/containerwidget", function(ContainerWidget)
    local oldOpen = ContainerWidget.Open
    function ContainerWidget:Open(container, doer)
        oldOpen(self, container, doer)
        local widget = container.replica.container:GetWidget()

        -- loop动画改为函数，可实现更复杂的播放效果
        if widget.animloopfn ~= nil then
            widget.animloopfn(self, container, doer)
        end
    end
end)

-- 更换容器背景
AddClassPostConstruct("components/container_replica", function(Container)
    Container[MOD_NAME.."__widget_override"] = net_string(Container.inst.GUID, "container."..MOD_NAME.."_widget_override", "widget_dirty")
    local function OnWidgetDirty(inst)
        for player, opener in pairs(Container.openers) do
            if player.HUD then
                -- player:PushEvent("refreshcrafting")
                if player.HUD.controls then
                    local widget = player.HUD.controls.containers[Container.inst]
                    if widget then
                        widget:Refresh()
                    end
                end
            end
        end
    end
    Container.inst:ListenForEvent("widget_dirty", OnWidgetDirty)

    local containers = require "containers"
    local params = containers.params

    function Container:OverrideWidget(prefab)
        self[MOD_NAME.."__widget_override"]:set(prefab or "default")
    end

    local oldGetWidget = Container.GetWidget
    function Container:GetWidget()
        local widget = oldGetWidget(self)
        local widget_override = self[MOD_NAME.."__widget_override"]:value()
        if widget_override ~= nil and widget_override ~= "default" then
            local data = params[widget_override]
            if data ~= nil and next(data) ~= nil then
                local _widget = deepcopy(widget)
                for k, v in pairs(data) do
                    _widget[k] = v
                end
                return _widget
            end
        end
        return widget
    end
end)

----------------------------------------------------------------------------
---[[增添官方人物技能]]
----------------------------------------------------------------------------
local SKILL_TAGS = {
	"plantkin", 			-- 沃姆伍德，随意种植
	"self_fertilizable", 	-- 沃姆伍德，自我施肥

    "expertchef", 			-- 沃利，可以让烤东西的时间更短/可以抵消自身笨拙厨子的标签
    "professionalchef", 	-- 沃利，可以使用专用厨具科技
    "masterchef", 			-- 沃利，可以放置专用厨具
}
local SKILL_TAGS_HASH = {} -- deployrestrictedtag被设置成了hash传递的网络变量，需要知道标签对应的hash值

AddPlayerPostInit(function(player)
	-- 注册标签网络变量
	for _, tag in ipairs(SKILL_TAGS) do
		player[MOD_NAME].tags[tag] = net_bool(player.GUID, MOD_NAME.."_tag."..tag)
		if TheWorld.ismastersim then
			player[MOD_NAME].tags[tag]:set(false)
		end
		SKILL_TAGS_HASH[hash(tag)] = tag
	end

	-- 判断是否有标签
	local oldHasTag = player.HasTag
	player.HasTag = function(self, tag)
		local _tag = type(tag) == "number" and SKILL_TAGS_HASH[tag] or string.lower(tag)
		if table.contains(SKILL_TAGS, _tag) and player[MOD_NAME].tags[_tag]:value() then
			return true
		else
			return oldHasTag(self, tag)
		end
	end

	local oldHasTags = player.HasTags
	function player:HasTags(...)
        local tags = select(1, ...)
        if type(tags) == "string" then
            tags = {tags}
        end
		for i, tag in ipairs(tags) do
			local _tag = type(tag)=="number" and SKILL_TAGS_HASH[tag] or string.lower(tag)
			if table.contains(SKILL_TAGS, _tag) and player[MOD_NAME].tags[_tag]:value() then
				table.remove(tags, i)
			end
		end
        if #tags == 0 then
            return true
        end
		return oldHasTags(self, unpack(tags))
	end

	local oldHasOneOfTags = player.HasOneOfTags
	function player:HasOneOfTags(...)
        local tags = select(1, ...)
        if type(tags) == "string" then
            tags = {tags}
        end
		for i, tag in ipairs(tags) do
			local _tag = type(tag)=="number" and SKILL_TAGS_HASH[tag] or string.lower(tag)
			if table.contains(SKILL_TAGS, _tag) and player[MOD_NAME].tags[_tag]:value() then
				return true
			end
		end
		return oldHasOneOfTags(self, ...)
	end

    if not TheWorld.ismastersim then
        return
    end

    player[MOD_NAME].skills = {}
end)

--[[
params:
	player: 玩家实体
	skill_name: 技能名称
]]
local function TendPlant(player)
    local x, y, z = player.Transform:GetWorldPosition()

    local TEND_PLANT_CANT_TAGS = {"INLIMBO", "FX"}
    local TEND_PLANT_ONEOF_TAGS = {"tendable_farmplant"}
    local ents = TheSim:FindEntities(x, y, z, 10, nil, TEND_PLANT_CANT_TAGS, TEND_PLANT_ONEOF_TAGS)
    for _, ent in ipairs(ents) do
        if ent.components.farmplanttendable then
            ent.components.farmplanttendable:TendTo(player)
        end
    end
end

UTIL.AddCharacterSkill = function(player, skill_name, source)
    if source == nil then
        source = "default"
    end

    -- 记录玩家技能
    if player[MOD_NAME].skills[skill_name] == nil then
        player[MOD_NAME].skills[skill_name] = {}
    end
    player[MOD_NAME].skills[skill_name][source] = true

	-- 标签型技能
	if table.contains(SKILL_TAGS, skill_name) then
		player[MOD_NAME].tags[skill_name]:set_local(false)
		player[MOD_NAME].tags[skill_name]:set(true)
	end

    -- 照料植物
	if skill_name == "tendplant" then
        if player[MOD_NAME.."_tendplanttask"] ~= nil then
            player[MOD_NAME.."_tendplanttask"]:Cancel()
        end
        player[MOD_NAME.."_tendplanttask"] = player:DoPeriodicTask(0.5, TendPlant)
    end
end

UTIL.RemoveCharacterSkill = function(player, skill_name, source)
    if source == nil then
        source = "default"
    end

    -- 记录玩家技能
    if player[MOD_NAME].skills[skill_name] ~= nil then
        player[MOD_NAME].skills[skill_name][source] = nil
    end

    if player[MOD_NAME].skills[skill_name] == nil or next(player[MOD_NAME].skills[skill_name]) == nil then
        -- 标签型技能
        if table.contains(SKILL_TAGS, skill_name) then
            player[MOD_NAME].tags[skill_name]:set_local(true)
            player[MOD_NAME].tags[skill_name]:set(false)
        end

        -- 照料植物
        if skill_name == "tendplant" then
            if player[MOD_NAME.."_tendplanttask"] ~= nil then
                player[MOD_NAME.."_tendplanttask"]:Cancel()
                player[MOD_NAME.."_tendplanttask"] = nil
            end
        end
    end
end

----------------------------------------------------------------------------
---[[寻找大脑结点]]
----------------------------------------------------------------------------
--[[
    每一个node的值域都是{name = "", parent = "", children = {}}
]]
UTIL.GetBrainNodeByName = function(name, node)
    if node == nil or name == nil then
        return
    end

    if node.name == name then
        return node
    end

    if node.children ~= nil then
        for _, child in ipairs(node.children) do
            local result = UTIL.GetBrainNodeByName(name, child)
            if result ~= nil then
                return result
            end
        end
    end
end



----------------------------------------------------------------------------
---[[同时移除]]
----------------------------------------------------------------------------
UTIL.BindRemovalToInst = function(inst, target)
    if not inst or not target or not target:IsValid() or not inst:IsValid() then
        return
    end

    local function OnTargetRemoved()
        if inst then
            inst:Remove()
        end
    end
    target[MOD_NAME.."_OnTargetRemoved"] = OnTargetRemoved
    target:ListenForEvent("onremove", target[MOD_NAME.."_OnTargetRemoved"])
end

UTIL.UnbindRemovalFromInst = function(inst, target)
    if not inst or not target or not target:IsValid() or not inst:IsValid() then
        return
    end

    if target[MOD_NAME.."_OnTargetRemoved"] and type(target[MOD_NAME.."_OnTargetRemoved"]) == "function" then
        target:RemoveEventCallback("onremove", target[MOD_NAME.."_OnTargetRemoved"])
        target[MOD_NAME.."_OnTargetRemoved"] = nil
    end
end

----------------------------------------------------------------------------
---[[掉落战利品]]
----------------------------------------------------------------------------
--[[
params:
    guy,    -- 没给pt则扔到guy物品栏
    loot,   -- 给loot则生成loot，否则掉落dropper的lootdropper
    dropper,
    pt,     -- 给pt则优先扔到指定位置
    data = {
        min_speed = 0,
        max_speed = 2,
        y_speed = 8,
        flingtargetpos = pt or x, y, z,
        flingtargetvariance = 0,
    }
]]
UTIL.DropLoot = function(guy, loot, dropper, pt, data)
    if data == nil then
        data = {}
    end

    if loot == nil and dropper ~= nil and dropper.components.lootdropper ~= nil then
        local prefabs = dropper.components.lootdropper:GenerateLoot()
        if dropper:HasTag("burnt")
            or (dropper.components.burnable ~= nil and
                dropper.components.burnable:IsBurning() and
                (dropper.components.fueled == nil or dropper.components.burnable.ignorefuel))
        then
            local isstructure = dropper:HasTag("structure")
            for k, v in pairs(prefabs) do
                if TUNING.BURNED_LOOT_OVERRIDES[v] ~= nil then
                    prefabs[k] = TUNING.BURNED_LOOT_OVERRIDES[v]
                elseif PrefabExists(v.."_cooked") then
                    prefabs[k] = v.."_cooked"
                elseif PrefabExists("cooked"..v) then
                    prefabs[k] = "cooked"..v
                elseif dropper.components.burnable and dropper.components.burnable:GetControlledBurn() then
                    -- Leave it be, but we will drop it smouldering.
                elseif (not isstructure and not dropper:HasTag("tree")) or dropper:HasTag("hive") then -- because trees have specific burnt loot and "hive"s are structures...
                    prefabs[k] = "ash"
                end
            end
        end

        if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
            local prefabname = string.upper(dropper.prefab)
            local num_decor_loot = dropper.components.lootdropper.GetWintersFeastOrnaments ~= nil and dropper.components.lootdropper.GetWintersFeastOrnaments(dropper) or TUNING.WINTERS_FEAST_TREE_DECOR_LOOT[prefabname] or nil
            if num_decor_loot ~= nil then
                for i = 1, num_decor_loot.basic do
                    table.insert(prefabs, GetRandomBasicWinterOrnament())
                end
                if num_decor_loot.special ~= nil then
                    table.insert(prefabs, num_decor_loot.special)
                end
            elseif not TUNING.WINTERS_FEAST_LOOT_EXCLUSION[prefabname] and (dropper:HasTag("monster") or dropper:HasTag("animal")) then
                local rand = math.random()
                if rand < 0.005 then
                    table.insert(prefabs, GetRandomBasicWinterOrnament())
                elseif rand < 0.20 then
                    table.insert(prefabs, "winter_food"..math.random(NUM_WINTERFOOD))
                end
            end
        end

        TheWorld:PushEvent("entity_droploot", { inst = dropper })

        loot = prefabs
    end
    loot = (type(loot) == "table" and loot.GUID == nil) and loot or {loot}

    for _, item in pairs(loot) do
        if type(item) == "string" then
            item = SpawnPrefab(item)
        end
        if item then
            if pt == nil and guy ~= nil and guy.components.inventory == nil then
                pt = guy:GetPosition()
            end

            if pt ~= nil then
                -- 扔地上
                item.Transform:SetPosition(pt:Get())

                local min_speed = data.min_speed or 0
                local max_speed = data.max_speed or 2
                local y_speed = data.y_speed or 8
                local y_speed_variance = data.y_speed_variance or 4

                if item.Physics ~= nil then
                    local angle = (data.flingtargetpos ~= nil and GetRandomWithVariance(item:GetAngleToPoint(data.flingtargetpos), data.flingtargetvariance or 0) * DEGREES)
                        or math.random() * TWOPI
                    local speed = min_speed + math.random() * (max_speed - min_speed)
                    if item:IsAsleep() then
                        local radius = .5 * speed + (dropper ~= nil and dropper.Physics ~= nil and dropper:GetPhysicsRadius(1) + item:GetPhysicsRadius(1) or 0)
                        item.Transform:SetPosition(
                            pt.x + math.cos(angle) * radius,
                            0,
                            pt.z - math.sin(angle) * radius
                        )
                    else
                        local sinangle = math.sin(angle)
                        local cosangle = math.cos(angle)
                        item.Physics:SetVel(speed * cosangle, GetRandomWithVariance(y_speed, y_speed_variance), speed * -sinangle)

                        if dropper ~= nil and dropper.Physics ~= nil then
                            local radius = item:GetPhysicsRadius(1) + dropper:GetPhysicsRadius(1)
                            if not data.spawn_loot_inside_prefab then
                                item.Transform:SetPosition(
                                    pt.x + cosangle * radius,
                                    pt.y,
                                    pt.z - sinangle * radius
                                )
                            else
                                radius = radius * math.random()
                                item.Transform:SetPosition(
                                    pt.x + cosangle * radius,
                                    pt.y + 0.5,
                                    pt.z - sinangle * radius
                                )
                            end
                        end

                    end
                end
            else
                -- 扔在玩家身上
                local give_pt = pt or dropper ~= nil and dropper:GetPosition() or guy:GetPosition()
                guy.components.inventory:GiveItem(item, nil, give_pt)
            end
        end
    end
end

----------------------------------------------------------------------------
---[[踏水]]
----------------------------------------------------------------------------
local lower_modname = string.lower(MOD_NAME)

local function ShouldWalkOnWater(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return TheWorld.Map:IsOceanAtPoint(x, y, z, false) and inst[lower_modname.."_waterwalking_enabled"]
end
AddStategraphState("wilson", State{
    name = lower_modname.."_surf_pre",
    tags = {"moving", "running", "canrotate", "surfing"},

    onenter = function(inst)
        inst.components.locomotor:RunForward()
        inst.AnimState:PlayAnimation("surf_pre")

        if inst[lower_modname.."_wave_fx"] ~= nil and inst[lower_modname.."_wave_fx"]:IsValid() and inst[lower_modname.."_wave_fx"].disappear_task == nil then
            inst[lower_modname.."_wave_fx"]:Disappear()
        end
        local wave_fx = SpawnPrefab(lower_modname.."_wave_ripple")
        if wave_fx then
            wave_fx.entity:SetParent(inst.entity)
            wave_fx.Transform:SetPosition(0, -0.7, 0)
            inst[lower_modname.."_wave_fx"] = wave_fx
        end
    end,

    onupdate = function(inst)
        inst.components.locomotor:RunForward()

        if not ShouldWalkOnWater(inst) then
            inst.sg:GoToState(lower_modname.."_surf_pst")
        end
    end,

    onexit = function(inst)
        inst:DoTaskInTime(0.1, function()
            if not inst.sg:HasStateTag("surfing") and inst[lower_modname.."_wave_fx"] ~= nil then
                inst[lower_modname.."_wave_fx"]:Disappear()
            end
        end)
    end,

    events =
    {
        EventHandler("animover", function(inst) inst.sg:GoToState(lower_modname.."_surf") end),
    },
})

AddStategraphState("wilson", State{
    name = lower_modname.."_surf",
    tags = {"canrotate", "moving", "running", "surfing"},
    onenter = function(inst)
        inst.components.locomotor:RunForward()
        if not inst.SoundEmitter:PlayingSound("surf_loop") then
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/sail_LP_leaf", "surf_loop")
        end

        inst.AnimState:PlayAnimation("surf_loop", false)
    end,

    onupdate = function(inst)
        inst.components.locomotor:RunForward()
        if not ShouldWalkOnWater(inst) then
            inst.sg:GoToState(lower_modname.."_surf_pst")
        end
    end,

    onexit = function(inst)
        inst:DoTaskInTime(0.1, function()
            if not inst.sg:HasStateTag("surfing") and inst[lower_modname.."_wave_fx"] ~= nil then
                inst[lower_modname.."_wave_fx"]:Disappear()
            end
        end)
    end,

    events =
    {
        EventHandler("animover", function(inst) inst.sg:GoToState(lower_modname.."_surf") end ),
    },
})

AddStategraphState("wilson", State{
    name = lower_modname.."_surf_pst",
    tags = {"canrotate", "idle"},

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("surf_pst")
        local wave_fx = inst[lower_modname.."_wave_fx"]
        if wave_fx then
            local x, y, z = inst.Transform:GetWorldPosition()
            wave_fx.entity:SetParent(nil)
            wave_fx.Transform:SetPosition(x, -0.7, z)
            wave_fx.Transform:SetRotation(inst.Transform:GetRotation())
            wave_fx:Disappear()
            inst[lower_modname.."_wave_fx"] = nil
        end
    end,

    onexit = function(inst)
        inst:DoTaskInTime(0.1, function()
            if not inst.sg:HasStateTag("surfing") and inst[lower_modname.."_wave_fx"] ~= nil then
                inst[lower_modname.."_wave_fx"]:Disappear()
            end
        end)
    end,

    events =
    {
        EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
    },
})

AddStategraphPostInit("wilson", function(sg)
    local locomote_event = sg.events["locomote"]
    if locomote_event then
        local oldfn = locomote_event.fn
        locomote_event.fn = function(inst, data)
            local is_moving = inst.sg:HasStateTag("moving")
            local should_move = inst.components.locomotor:WantsToMoveForward()
            if ShouldWalkOnWater(inst) then
                if data and data.dir then
                    inst.components.locomotor:SetMoveDir(data.dir)
                end
                if not is_moving and should_move then
                    inst.sg:GoToState(lower_modname.."_surf_pre")
                elseif is_moving and not should_move then
                    inst.sg:GoToState(lower_modname.."_surf_pst")
                end
            else
                oldfn(inst, data)
            end
        end
    end
end)

AddStategraphState("wilson_client", State{
    name = lower_modname.."_surf_pre",
    tags = {"moving", "running", "canrotate", "surfing"},

    onenter = function(inst)
        inst.components.locomotor:RunForward()
        inst.AnimState:PlayAnimation("surf_pre")
    end,

    onupdate = function(inst)
        inst.components.locomotor:RunForward()

        if not ShouldWalkOnWater(inst) then
            inst.sg:GoToState(lower_modname.."_surf_pst")
        end
    end,

    events =
    {
        EventHandler("animover", function(inst) inst.sg:GoToState(lower_modname.."_surf") end),
    },
})

AddStategraphState("wilson_client", State{
    name = lower_modname.."_surf",
    tags = {"canrotate", "moving", "running", "surfing"},
    onenter = function(inst)
        inst.components.locomotor:RunForward()
        if not inst.SoundEmitter:PlayingSound("surf_loop") then
            inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/sail_LP_leaf", "surf_loop")
        end

        inst.AnimState:PlayAnimation("surf_loop", false)
    end,

    onupdate = function(inst)
        inst.components.locomotor:RunForward()
        if not ShouldWalkOnWater(inst) then
            inst.sg:GoToState(lower_modname.."_surf_pst")
        end
    end,

    events =
    {
        EventHandler("animover", function(inst) inst.sg:GoToState(lower_modname.."_surf") end ),
    },
})

AddStategraphState("wilson_client", State{
    name = lower_modname.."_surf_pst",
    tags = {"canrotate", "idle"},

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("surf_pst")
    end,

    events =
    {
        EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
    },
})

AddStategraphPostInit("wilson_client", function(sg)
    local locomote_event = sg.events["locomote"]
    if locomote_event then
        local oldfn = locomote_event.fn
        locomote_event.fn = function(inst, data)
            local is_moving = inst.sg:HasStateTag("moving")
            local should_move = inst.components.locomotor:WantsToMoveForward()
            if ShouldWalkOnWater(inst) then
                if data and data.dir then
                    inst.components.locomotor:SetMoveDir(data.dir)
                end
                if not is_moving and should_move then
                    inst.sg:GoToState(lower_modname.."_surf_pre")
                elseif is_moving and not should_move then
                    inst.sg:GoToState(lower_modname.."_surf_pst")
                end
            else
                oldfn(inst, data)
            end
        end
    end
end)

UTIL.SetWaterSplashFollow = function(inst, follow, frequency)
    if inst._water_splash_follow_task ~= nil then
        inst._water_splash_follow_task:Cancel()
    end

    if not follow then
        if inst._water_splash_follow_task ~= nil then
            inst._water_splash_follow_task:Cancel()
            inst._water_splash_follow_task = nil
        end
        return
    end

    frequency = frequency or 1 -- 单位：墙

    inst._last_pt_for_water_splash = inst:GetPosition()
    inst._water_splash_follow_task = inst:DoPeriodicTask(0.1, function()
        local pt = inst:GetPosition()
        local last_x, last_y, last_z = inst._last_pt_for_water_splash:Get()
        local current_x, current_y, current_z = pt:Get()
        local dist = math.sqrt((current_x - last_x)^2 + (current_y - last_y)^2 + (current_z - last_z)^2)
        if inst.components.drownable ~= nil and inst.components.drownable:IsOverWater() and dist >= frequency then
            SpawnPrefab("weregoose_splash_less" .. tostring(math.random(2))).Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst._last_pt_for_water_splash = pt
        end
    end)
end

UTIL.EnableWaterWalking = function(player, enable)
    if enable == nil then
        enable = true
    end

    player[lower_modname.."_waterwalking_enabled"] = enable

    local function OnChangeArea(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        if ShouldWalkOnWater(inst) and not inst.sg:HasStateTag("surfing") then
            inst.sg:GoToState(lower_modname.."_surf_pre")
        end
    end

    local function SetWaterWalkingCollision(inst, enable)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.OBSTACLES)
        inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)
        inst.Physics:CollidesWith(COLLISION.GIANTS)

        if enable then
            player.Physics:CollidesWith(COLLISION.GROUND)
        else
            player.Physics:CollidesWith(COLLISION.WORLD)
        end
    end

    local function OnRespawn()
        SetWaterWalkingCollision(player, true)
    end

    if enable then
        if player.components.drownable ~= nil and player.components.drownable.enabled ~= false then
            player.components.drownable.enabled = false

            SetWaterWalkingCollision(player, true)

            -- UTIL.SetWaterSplashFollow(player, true, 1)

            player:ListenForEvent("changearea", OnChangeArea)
            player:ListenForEvent("ms_respawnedfromghost", OnRespawn)
        end
    else
        if player.components.drownable ~= nil and player.components.drownable.enabled == false then
            player.components.drownable.enabled = true

            SetWaterWalkingCollision(player, false)

            -- UTIL.SetWaterSplashFollow(player, false)

            player:RemoveEventCallback("changearea", OnChangeArea)
            player:RemoveEventCallback("ms_respawnedfromghost", OnRespawn)
        end
    end
end

----------------------------------------------------------------------------
---[[将物品转变为无功能的装饰]]
----------------------------------------------------------------------------
-- 该方法有风险
-- UTIL.MakeItemDecor = function(inst, data)
--     if not inst:IsValid() then
--         print("[ERROR] 无法对无效实体执行 RemoveAllComponents")
--         return
--     end

--     inst.entity:AddFollower()

--     -- 移除组件
--     local component_names = {}
--     for name in pairs(inst.components) do
--         table.insert(component_names, name)
--     end
--     for _, name in ipairs(component_names) do
--         inst:RemoveComponent(name)
--     end
--     if next(inst.components) ~= nil then
--         print("[WARNING] 部分组件未成功移除：")
--     end

--     if data == nil then
--         data = {}
--     end

--     if data.persists ~= true then
--         inst.persists = false
--     end

--     inst:AddTag("decor")
--     inst:AddTag("NOCLICK")
--     inst:AddTag("NOBLOCK")
--     inst:AddTag("FX")
-- end

----------------------------------------------------------------------------
---[[恒温]]
----------------------------------------------------------------------------
AddComponentPostInit("temperature", function(Temperature)
    local oldOnUpdate = Temperature.OnUpdate
    function Temperature:OnUpdate(dt, ...)
        if self.inst[MOD_NAME].ct_sources ~= nil and next(self.inst[MOD_NAME].ct_sources) ~= nil then
            local delta = 25 - self.current
            self:DoDelta(delta * dt)
        else
            return oldOnUpdate(self, dt, ...)
        end
    end
end)

UTIL.AddConstantTemperatureSource = function(inst, source)
    if inst.components.temperature == nil or source == nil then
        return false
    end

    inst[MOD_NAME].ct_sources = inst[MOD_NAME].ct_sources or {}
    inst[MOD_NAME].ct_sources[source] = true
end

UTIL.RemoveConstantTemperatureSource = function(inst, source)
    if inst.components.temperature == nil or source == nil then
        return false
    end

    inst[MOD_NAME].ct_sources = inst[MOD_NAME].ct_sources or {}
    inst[MOD_NAME].ct_sources[source] = nil
end

----------------------------------------------------------------------------
---[[获取动画信息]]
----------------------------------------------------------------------------
--[[
params: 
    inst,  -- 实体
    skin_build,  -- 是否获取皮肤动画信息
]]
UTIL.GetAnimData = function(inst, skin_build)
    if inst == nil then
        return
    end

    local str, new_inst
    if skin_build then
        str = inst.entity:GetDebugString()
    else
        new_inst = SpawnPrefab(inst.prefab)
        if new_inst ~= nil then
            str = new_inst.entity:GetDebugString()
        end
    end

	if str == nil then
		return
	end

	local bank, build, anim = str:match("bank: (.+) build: (.+) anim: .+:(.+) Frame")
    if bank == nil or bank == "FROMNUM" then
        if skin_build then
            bank = inst.AnimState:GetBankHash()
        elseif new_inst ~= nil then
            bank = new_inst.AnimState:GetBankHash()
        end
    end
    if build == nil or build == "FROMNUM" then
        if skin_build then
            build = inst.AnimState:GetBuild()
        elseif new_inst ~= nil then
            build = new_inst.AnimState:GetBuild()
        end
    end
    if new_inst ~= nil and new_inst:IsValid() then
        new_inst:Remove()
    end

    return bank, build, anim
end

-- ----------------------------------------------------------------------------
-- ---[[修改信息]]
-- ----------------------------------------------------------------------------
-- -- 用于修改如生命值上限之类的信息
-- AddPrefabPostInitAny(function(inst)
--     if not TheWorld.ismastersim then
--         return
--     end

--     inst:AddComponent("hmrmodifier")
-- end)

-- local oldAddComponent = GLOBAL.EntityScript.AddComponent
-- GLOBAL.EntityScript.AddComponent = function(self, name, ...)
--     local component = oldAddComponent(self, name, ...)
--     self:PushEvent("componentadded", {component = component, name = name})
--     return component
-- end

-- UTIL.AddModify = function(inst, component, key, value)
--     if inst == nil or component == nil or key == nil or value == nil then
--         return
--     end

--     if inst.components[component] == nil then
--         return
--     end

--     if inst.components.hmrmodifier == nil then
--         inst:AddComponent("hmrmodifier")
--     end

--     inst.components.hmrmodifier:AddModify(component, key, value)
-- end

-- UTIL.RemoveModify = function(inst, component, key)
--     if inst == nil or component == nil or key == nil then
--         return
--     end

--     if inst.components[component] == nil then
--         return
--     end

--     if inst.components.hmrmodifier == nil then
--         return
--     end

--     inst.components.hmrmodifier:RemoveModify(component, key)
-- end

-- UTIL.HasOriginalValue = function(inst, component, key)
--     if inst == nil or component == nil or key == nil then
--         return false
--     end

--     if inst.components[component] == nil then
--         return false
--     end

--     if inst.components.hmrmodifier == nil then
--         return false
--     end

--     return inst.components.hmrmodifier:HasOriginalValue(component, key)
-- end

-- UTIL.SetOriginalValue = function(inst, component, key, value)
--     if inst == nil or component == nil or key == nil or value == nil then
--         return
--     end

--     if inst.components[component] == nil then
--         return
--     end

--     if inst.components.hmrmodifier == nil then
--         inst:AddComponent("hmrmodifier")
--     end

--     inst.components.hmrmodifier:SetOriginalValue(component, key, value)
-- end

-- UTIL.GetOriginalValue = function(inst, component, key)
--     if inst == nil or component == nil or key == nil then
--         return
--     end

--     if inst.components[component] == nil then
--         return
--     end

--     if inst.components.hmrmodifier == nil then
--         return
--     end

--     return inst.components.hmrmodifier:GetOriginalValue(component, key)
-- end

----------------------------------------------------------------------------
---[[长时间血量（或其他）恢复]]
----------------------------------------------------------------------------
UTIL.STANDARD_STATUS = {
    HEALTH = "HEALTH",
    HUNGER = "HUNGER",
    SANITY = "SANITY",
    MOISTURE = "MOISTURE",
}

UTIL.AddStatusEffect = function(inst, status, key, amount, period, duratioin, callback)
    local component = string.lower(status)
    if inst.components[component] == nil then
        UTIL.PrintLog("实体"..(inst.name or inst.prefab).."没有 "..component.." 组件")
        return
    end

    amount = amount or 1
    period = period or 1

    local tasks = inst[MOD_NAME].tasks
    if tasks[component] == nil then
        tasks[component] = {}
    end
    if tasks[component][key] ~= nil then
        UTIL.PrintLog("任务 "..key.." 已存在，已取消原有任务")
        if tasks[component][key].task ~= nil then
            tasks[component][key].task:Cancel()
        end
        tasks[component][key] = nil
    end

    -- 开始任务
    tasks[component][key] = {
        task = component == "health" and inst:DoPeriodicTask(period, function() inst.components.health:DoDelta(amount) end) or
               component == "sanity" and inst:DoPeriodicTask(period, function() inst.components.sanity:DoDelta(amount) end) or
               component == "hunger" and inst:DoPeriodicTask(period, function() inst.components.hunger:DoDelta(amount) end) or
               component == "temperature" and inst:DoPeriodicTask(period, function() inst.components.temperature:DoDelta(amount) end) or
               nil,
        data = {
            amount = amount,
            period = period,
            duration = duratioin,
            -- callback = callback,
        }
    }
    if component == "moisture" then
        inst.components.moisture:AddRateBonus(inst, amount / period, key)
    end

    if duratioin ~= nil then
        inst:DoTaskInTime(duratioin, function()
            UTIL.RemoveStatusEffect(inst, status, key)
            if callback ~= nil then
                callback(inst, component, key)
            end
        end)
    end

    -- 同步客户端数据
    local effects_data = {}
    for k, v in pairs(tasks[component]) do
        effects_data[k] = {
            amount = v.data.amount,
            period = v.data.period,
        }
    end
    local encoded_effects_data = UTIL.EncodeData(effects_data)
    if encoded_effects_data ~= nil and inst[MOD_NAME] ~= nil and inst[MOD_NAME].statuseffects ~= nil and inst[MOD_NAME].statuseffects[component] ~= nil then
        inst[MOD_NAME].statuseffects[component]:set(encoded_effects_data)
    else
        UTIL.PrintLog("effects_data同步客户端数据失败")
    end
end

UTIL.RemoveStatusEffect = function(inst, status, key)
    local component = string.lower(status)

    local tasks = inst[MOD_NAME].tasks
    if tasks[component] == nil or tasks[component][key] == nil then
        UTIL.PrintLog("任务 "..key.." 不存在")
        return
    end

    if inst.components[component] == nil then
        UTIL.PrintLog("实体"..(inst.name or inst.prefab).."没有 "..component.." 组件")
        return
    end

    if tasks[component][key].task ~= nil then
        tasks[component][key].task:Cancel()
    end
    tasks[component][key] = nil
    if component == "moisture" then
        inst.components.moisture:RemoveRateBonus(inst, key)
    end

    -- 同步客户端数据
    local effects_data = {}
    for k, v in pairs(tasks[component]) do
        effects_data[k] = v.data
    end
    local encoded_effects_data = UTIL.EncodeData(effects_data)
    if encoded_effects_data ~= nil then
        inst[MOD_NAME].statuseffects[component]:set(encoded_effects_data)
    else
        UTIL.PrintLog("effects_data同步客户端数据失败")
    end
end

AddPlayerPostInit(function(inst)
    inst[MOD_NAME].statuseffects.health = net_string(inst.GUID, MOD_NAME.."_tasks.health", MOD_NAME.."_tasks_dirty")
    inst[MOD_NAME].statuseffects.hunger = net_string(inst.GUID, MOD_NAME.."_tasks.hunger", MOD_NAME.."_tasks_dirty")
    inst[MOD_NAME].statuseffects.sanity = net_string(inst.GUID, MOD_NAME.."_tasks.sanity", MOD_NAME.."_tasks_dirty")
    inst[MOD_NAME].statuseffects.moisture = net_string(inst.GUID, MOD_NAME.."_tasks.moisture", MOD_NAME.."_tasks_dirty")
    inst[MOD_NAME].statuseffects.temperature = net_string(inst.GUID, MOD_NAME.."_tasks.temperature", MOD_NAME.."_tasks_dirty")
end)

local function GetArrowAnim(speed)
    local anim = "neutral"
    if speed <= -5 then
        anim = "arrow_loop_decrease_most"
    elseif speed <= -2 then
        anim = "arrow_loop_decrease_more"
    elseif speed < 0 then
        anim = "arrow_loop_decrease"
    elseif speed == 0 then
        anim = "arrow_loop_neutral"
    elseif speed <= 2 then
        anim = "arrow_loop_increase"
    elseif speed <= 5 then
        anim = "arrow_loop_increase_more"
    elseif speed > 5 then
        anim = "arrow_loop_increase_most"
    end
    return anim
end

local function GetArrowSpeed(self, status)
    local player = self.owner or ThePlayer
    local tasks = player and player[MOD_NAME].statuseffects[status] and player[MOD_NAME].statuseffects[status]:value()
    if player ~= nil and tasks ~= nil then
        local decoded_tasks = UTIL.DecodeData(tasks)
        if decoded_tasks ~= nil then
            local speed = 0
            for key, task in pairs(decoded_tasks) do
                speed = speed + task.amount / task.period
            end
            return speed
        end
    end
    return 0
end

local function SetArrowAnim(self, status, arrow)
    local speed = GetArrowSpeed(self, status)
    if speed ~= 0 then
        local anim = GetArrowAnim(speed)
        if self.arrowdir ~= anim then
            self.arrowdir = anim
            arrow:GetAnimState():PlayAnimation(anim, true)
        end
        return true
    end
    return false
end

-- 健康值箭头
AddClassPostConstruct("widgets/healthbadge", function(self)
    local oldOnUpdate = self.OnUpdate
    function self:OnUpdate(dt)
        if TheNet:IsServerPaused() then return end

        local changed = SetArrowAnim(self, "health", self.sanityarrow)

        if not changed and oldOnUpdate then
            oldOnUpdate(self, dt)
        end
    end
end)

-- 饱食度箭头
AddClassPostConstruct("widgets/hungerbadge", function(self)
    local oldOnUpdate = self.OnUpdate
    function self:OnUpdate(dt)
        if TheNet:IsServerPaused() then return end

        local changed = SetArrowAnim(self, "hunger", self.hungerarrow)

        if not changed and oldOnUpdate then
            oldOnUpdate(self, dt)
        end
    end
end)

-- 精神值箭头
AddClassPostConstruct("widgets/sanitybadge", function(self)
    local oldOnUpdate = self.OnUpdate
    function self:OnUpdate(dt)
        if TheNet:IsServerPaused() then return end

        local changed = SetArrowAnim(self, "sanity", self.sanityarrow)

        if not changed and oldOnUpdate then
            oldOnUpdate(self, dt)
        else
            -- sanity在update时除了更新箭头，还要更新鬼魂状态
            local sanity = self.owner.replica.sanity
            local ghost = sanity ~= nil and sanity:IsGhostDrain()
            if self.ghost ~= ghost then
                self.ghost = ghost
                if ghost then
                    self.ghostanim:GetAnimState():PlayAnimation("ghost_activate")
                    self.ghostanim:GetAnimState():PushAnimation("ghost_idle", true)
                    self.ghostanim:Show()
                else
                    self.ghostanim:GetAnimState():PlayAnimation("ghost_deactivate")
                end
            end
        end
    end
end)

-- 潮湿度箭头(自动)

----------------------------------------------------------------------------
---[[添加放置器范围圆圈]]
----------------------------------------------------------------------------
UTIL.CIRCLE_RADIUS_SCALE = 1888 / 150 / 2 -- 源艺术尺寸 / 动画缩放比例 / 2（除以2得到半径）

UTIL.AddDeployHelper = function(inst, radius, color, type)
    if not TheNet:IsDedicated() then
        local function OnEnableHelper(inst, enabled)
            if enabled then
                if inst.helper == nil then
                    inst.helper = CreateEntity()

                    --[[Non-networked entity]]
                    inst.helper.entity:SetCanSleep(false)
                    inst.helper.persists = false

                    inst.helper.entity:AddTransform()
                    inst.helper.entity:AddAnimState()

                    inst.helper:AddTag("CLASSIFIED")
                    inst.helper:AddTag("NOCLICK")
                    inst.helper:AddTag("placer")

                    local PLACER_SCALE = radius / UTIL.CIRCLE_RADIUS_SCALE
                    local COLOR = color or {1, 1, 1, 1}
                    if COLOR[4] == nil then
                        COLOR[4] = 1
                    end
                    local circle_anim = (type or "hollow").."_circle"
                    inst.helper.AnimState:SetBank("hmr_placement")
                    inst.helper.AnimState:SetBuild("hmr_placement")
                    inst.helper.AnimState:PlayAnimation(circle_anim)
                    inst.helper.AnimState:SetLightOverride(1)
                    inst.helper.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
                    inst.helper.AnimState:SetLayer(LAYER_BACKGROUND)
                    inst.helper.AnimState:SetSortOrder(1)
                    inst.helper.AnimState:SetAddColour(unpack(COLOR))
                    inst.helper.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)

                    inst.helper.entity:SetParent(inst.entity)
                end
            elseif inst.helper ~= nil then
                inst.helper:Remove()
                inst.helper = nil
            end
        end
        inst:AddComponent("deployhelper")
        inst.components.deployhelper.onenablehelper = OnEnableHelper
    end
end

UTIL.MakePlacerWithRange = function(name, bank, build, anim, range, data)
    data = data or {}
    local function placer_postinit_fn(inst)
        local placer = CreateEntity()

        --[[Non-networked entity]]
        placer.entity:SetCanSleep(false)
        placer.persists = false

        placer.entity:AddTransform()
        placer.entity:AddAnimState()

        placer:AddTag("CLASSIFIED")
        placer:AddTag("NOCLICK")
        placer:AddTag("placer")

        local circle_anim = (data.type or "hollow").."_circle"
        placer.AnimState:SetBank("hmr_placement")
        placer.AnimState:SetBuild("hmr_placement")
        placer.AnimState:PlayAnimation(circle_anim)
        placer.AnimState:SetLightOverride(1)
        placer.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        local PLACER_SCALE = range / UTIL.CIRCLE_RADIUS_SCALE
        placer.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)
        placer.AnimState:SetLayer(LAYER_BACKGROUND)

        placer.entity:SetParent(inst.entity)

        inst.components.placer:LinkEntity(placer)

        if data.placer_postinit_fn then
            data.placer_postinit_fn(inst, placer)
        end
    end

    return MakePlacer(
        name, bank, build, anim,
        data.onground,
        data.snap,
        data.metersnap,
        data.scale,
        data.fixedcameraoffset,
        data.facing,
        placer_postinit_fn,
        data.offset,
        data.onfailedplacement)
end

----------------------------------------------------------------------------
---[[渐隐、渐显]]
----------------------------------------------------------------------------
UTIL.AppearGradually = function(inst, appear_time, cb)
    local time_to_appear = appear_time or 1  -- 总渐显时间，默认1秒
    local tick_time = TheSim:GetTickTime()   -- 引擎每帧时间间隔

    -- 隐藏动态阴影（如果有）
    if inst.DynamicShadow ~= nil then
        inst.DynamicShadow:Enable(false)
    end

    -- 启动线程控制渐显过程
    inst:StartThread(function()
        local ticks = 0
        local total_ticks = math.ceil(time_to_appear / tick_time)  -- 计算总帧数，避免循环误差

        while ticks < total_ticks do
            -- 计算当前显现进度（0到1之间）
            local appear_amount = ticks / total_ticks
            -- 设置侵蚀参数：第一个值越小，实体越显（0为完全显示，1为完全隐藏）
            inst.AnimState:SetErosionParams(1 - appear_amount, 0.1, 1.0)
            ticks = ticks + 1
            Yield()  -- 等待下一帧
        end

        -- 关键修复：强制设置为完全显示状态，清除所有隐藏残留
        inst.AnimState:SetErosionParams(0, 0.1, 1.0)  -- 0表示完全显示
        -- 重新启用动态阴影
        if inst.DynamicShadow ~= nil then
            inst.DynamicShadow:Enable(true)
        end
        if cb ~= nil then
            cb(inst)
        end
    end)
end

UTIL.DisappearGradually = function(inst, disappear_time, cb, remove)
    local time_to_erode = disappear_time or 1
    local tick_time = TheSim:GetTickTime()

    if inst.DynamicShadow ~= nil then
        inst.DynamicShadow:Enable(false)
    end
    if inst.components.floater ~= nil then
        inst.components.floater:Erode(time_to_erode)
    end

    inst:StartThread(function()
        local ticks = 0
        while ticks * tick_time < time_to_erode do
            local erode_amount = ticks * tick_time / time_to_erode
            inst.AnimState:SetErosionParams(erode_amount, 0.1, 1.0)
            ticks = ticks + 1
            Yield()
        end
        if cb ~= nil then
            cb(inst)
        elseif remove ~= false then
            inst:Remove()
        end
    end)
end

----------------------------------------------------------------------------
---[[DeBug]]
----------------------------------------------------------------------------
-- UTIL.PrintTable = function(table)
--     if table == nil then
--         print("【"..MOD_NAME.."】需要打印的表不存在")
--         return
--     end

--     if type(table) ~= "table" then
--         print("【"..MOD_NAME.."】需要打印的数据不是表类型")
--     end

--     local function GenerateTab(count)
--         local str = ""
--         for i = 1, count do
--             str = str .. "\t"
--         end
--         return str
--     end

--     print("【"..MOD_NAME.."】测试表:", table)
--     local count = 1
--     local function Print(t)
--         if type(t) == "table" then
--             for k, v in pairs(t) do
--                 print(GenerateTab(count).."k =", k, "类型："..type(k), "\tv =", v, "类型："..type(v))
--                 if type(v) == "table" then
--                     count = count + 1
--                     Print(v)
--                 end
--             end
--         end
--     end

--     print("【"..MOD_NAME.."】测试表内容开始：===========================")
--     Print(table)
--     print("【"..MOD_NAME.."】测试表内容结束：===========================")
-- end

UTIL.PrintTable = function(rootTable, tableName)
    if rootTable == nil then
        print("【"..MOD_NAME.."】需要打印的表不存在")
        return
    end

    if type(rootTable) ~= "table" then
        print("【"..MOD_NAME.."】需要打印的数据不是表类型")
        return
    end

    print("【"..MOD_NAME.."】测试表内容开始：===========================")

    -- 默认表名
    tableName = tableName or "table"

    -- 缓存已处理过的表地址，用于检测循环引用
    local cacheMap = {}

    -- 缩进字符串生成函数
    local function makeIndent(level)
        return string.rep("    ", level) -- 使用4空格缩进
    end

    -- 键的格式化函数
    local function formatKey(key)
        local keyType = type(key)
        if keyType == "string" and string.match(key, "^[%a_][%w_]*$") then
            return key -- 合法标识符直接返回
        elseif keyType == "string" then
            return "[" .. string.format("%q", key) .. "]" -- 非标识符字符串加引号
        elseif keyType == "number" then
            return "[" .. tostring(key) .. "]" -- 数字键加方括号
        else
            return "[" .. tostring(key) .. "]" -- 其他类型
        end
    end

    -- 递归打印函数 (先定义)
    local function printTableRec(tableToPrint, currentIndent, currentLevel, localCache)
        local result = {"{\n"}
        local nextIndent = currentIndent .. makeIndent(currentLevel)

        -- 分类收集键
        local numberKeys = {}
        local otherKeys = {}
        for key in pairs(tableToPrint) do
            if type(key) == "number" then
                table.insert(numberKeys, key)
            else
                table.insert(otherKeys, key)
            end
        end

        -- 排序：数字键按值排序，其他键按类型和字符串排序
        table.sort(numberKeys)
        table.sort(otherKeys, function(a, b)
            local typeA, typeB = type(a), type(b)
            if typeA ~= typeB then
                return typeA < typeB
            end
            return tostring(a) < tostring(b)
        end)

        -- 合并键列表（先数字后其他）
        local allKeys = {}
        for _, key in ipairs(numberKeys) do table.insert(allKeys, key) end
        for _, key in ipairs(otherKeys) do table.insert(allKeys, key) end

        -- 处理所有键值对
        for i, key in ipairs(allKeys) do
            local value = tableToPrint[key]
            local formattedKey = formatKey(key)

            -- 值的格式化处理
            local valueType = type(value)
            local formattedValue
            if valueType == "table" then
                if localCache[value] then
                    formattedValue = "<循环引用>"
                else
                    localCache[value] = true
                    formattedValue = printTableRec(value, nextIndent, currentLevel + 1, localCache)
                end
            elseif valueType == "string" then
                formattedValue = string.format("%q", value) -- 字符串加引号
            elseif valueType == "boolean" or valueType == "number" then
                formattedValue = tostring(value) -- 布尔值和数字直接输出
            else
                formattedValue = "<" .. tostring(value) .. ">" -- 其他类型
            end

            table.insert(result, nextIndent)
            table.insert(result, formattedKey)
            table.insert(result, " = ")
            table.insert(result, formattedValue)

            if i < #allKeys then
                table.insert(result, ",\n")
            else
                table.insert(result, "\n")
            end
        end

        table.insert(result, currentIndent)
        table.insert(result, "}")
        return table.concat(result)
    end

    -- 执行打印
    local ok, result = pcall(printTableRec, rootTable, makeIndent(1), 1, {})
    if ok then
        -- 添加表名输出
        print(tableName .. " = " .. result)
    else
        print("【"..MOD_NAME.."】打印失败: " .. result)
    end

    print("【"..MOD_NAME.."】测试表内容结束：===========================")
end

UTIL.PrintLog = function(...)
    if next({...}) == nil then
        print("【"..MOD_NAME.."】需要打印的日志不存在")
        return
    end

    print("【"..MOD_NAME.."】", ...)
end


----------------------------------------------------------------------------
---[[DeBug]]
----------------------------------------------------------------------------
UTIL.GetLocalVar = function(filename, varname)
    local target_value = nil  -- 存储捕获到的变量值
    local modname = filename:gsub("%.lua$", "")  -- 提取模块名（去掉.lua后缀，适配require）
    
    -- 1. 清除模块缓存（确保require重新加载文件，触发钩子捕获变量）
    package.loaded[modname] = nil

    -- 2. 设置行钩子：仅监控目标文件，找到变量后立即停止
    debug.sethook(function()
        -- 遍历栈帧层级（2~10，覆盖require嵌套调用场景）
        for level = 2, 10 do
            local frame_info = debug.getinfo(level, "S")  -- 获取栈帧的源码信息
            if not frame_info then break end  -- 无更多栈帧则退出
            
            -- 过滤：仅处理目标文件（source格式为"@文件名"）
            if frame_info.source == "@" .. filename then
                -- 遍历当前栈帧的所有局部变量
                local var_idx = 1
                while true do
                    local name, value = debug.getlocal(level, var_idx)
                    if not name then break end  -- 无更多变量则退出
                    
                    -- 找到目标变量，记录值并立即移除钩子（提升性能）
                    if name == varname then
                        target_value = value
                        debug.sethook(nil)  -- 停止监控，避免冗余执行
                        return  -- 直接退出钩子，无需继续
                    end
                    var_idx = var_idx + 1
                end
            end
        end
    end, "l")  -- "l"=行钩子（监控每一行执行，确保捕获变量生命周期）

    -- 3. 用require加载目标文件（触发钩子捕获变量）
    require(modname)

    -- 4. 兜底移除钩子（防止极端情况未触发移除）
    debug.sethook(nil)

    return target_value  -- 返回捕获到的值（未找到返回nil）
end

----------------------------------------------------------------------------
---[[MOD是否开启]]
----------------------------------------------------------------------------
UTIL.IsModEnabled = function(name)
    local moddir = KnownModIndex:GetModsToLoad(true)
    local enablemods = {}
    for k, dir in pairs(moddir) do
        local info = KnownModIndex:GetModInfo(dir)
        local name = info and info.name or "unknow"
        enablemods[dir] = name
    end

    for k, v in pairs(enablemods) do
        if v and (k:match(name) or v:match(name)) then return true end
    end
    return false
end

----------------------------------------------------------------------------
---[[丰耘专属部分]]
----------------------------------------------------------------------------
UTIL.IsTerrorPlant = function(inst)
    if inst == nil or inst.prefab == nil then
        return false
    end

    local PLANT_DEFS = require("prefabs/farm_plant_defs").PLANT_DEFS
    local plant_name = inst.prefab:gsub("^farm_plant_", "")
    if PLANT_DEFS[plant_name] and PLANT_DEFS[plant_name].terror_plant then
        return true
    end
end


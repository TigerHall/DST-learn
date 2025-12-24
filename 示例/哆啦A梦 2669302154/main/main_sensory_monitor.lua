--------------------------------
--[[ 感觉监视器全局处理]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-06]]
--[[ @updateTime: 2022-01-06]]
--[[ @email: x7430657@163.com]]
--------------------------------
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local SensoryMonitorPanel = require "widgets/sensory_monitor_widget"
local SensoryMonitorFn = require "function/sensory_monitor_fn"
local Table = require "util/table"
local Upvalue = require "util/upvalue"
-- 去除脚步声
do
    local oldPlayFootstep = GLOBAL.PlayFootstep
    GLOBAL.PlayFootstep = function(inst, ...) --去除脚步声
        if inst and  inst:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG) then -- 正在监视
            return
        end
        return oldPlayFootstep(inst, ...)
    end
end


-- 同步移动速度,至少不能小于目标速度,不然追不上
do
    AddComponentPostInit("locomotor",function(self)
        local oldGetWalkSpeed = self.GetWalkSpeed
        function self:GetWalkSpeed(...)
            if self.inst:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG) then
                local targetWalkSpeed
                -- 监视目标不为nil 且拥有locomotor组件
                if TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[self.inst] ~= nil
                        -- 保险起见 增加判断监视目标不能是自己的判断，不然出现无线递归
                        and TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[self.inst] ~= self.inst
                        and TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[self.inst].components.locomotor
                then
                    targetWalkSpeed = TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[self.inst].components.locomotor:GetWalkSpeed()
                end
                if targetWalkSpeed  then
                    --local walkSpeed = oldGetWalkSpeed(self,...)
                    --if targetWalkSpeed > walkSpeed then
                    return targetWalkSpeed
                    --end
                end
                return oldGetWalkSpeed(self,...)
            end
            return oldGetWalkSpeed(self,...)--旧逻辑
        end


        local oldGetRunSpeed = self.GetRunSpeed
        function self:GetRunSpeed(...)
            if self.inst:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG) then
                local targetRunSpeed
                -- 监视目标不为nil 且拥有locomotor组件
                if TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[self.inst] ~= nil
                        -- 保险起见 增加判断监视目标不能是自己的判断，不然出现无线递归
                        and TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[self.inst] ~= self.inst
                        and TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[self.inst].components.locomotor
                then
                    targetRunSpeed = TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[self.inst].components.locomotor:GetRunSpeed()
                end
                if targetRunSpeed  then
                    --local runSpeed = oldGetRunSpeed(self,...)
                    --if targetRunSpeed > runSpeed then
                    return targetRunSpeed
                    --end
                end
                return oldGetRunSpeed(self,...)
            end
            return oldGetRunSpeed(self,...)--旧逻辑
        end
    end)
end



-- RPC
do
    --用来处理客户端退出监控时,发送至服务端
    AddModRPCHandler(modname,"senory_monitor.exit", function(player, status)
        -- TODO 这里status没传过来 不知道为什么
        Logger:Debug({"ModRPC["..modname.."][senory_monitor.exit]",player._senory_monitor_status,status})
        SensoryMonitorFn:Exit(player)
    end)
    AddModRPCHandler(modname,"senory_monitor.change", function(player, type,userid,guid)
        Logger:Debug({"ModRPC["..modname.."][senory_monitor.change]",player._senory_monitor_status, type,userid,guid})
        SensoryMonitorFn:Change(player,type,userid,guid)
    end)
end

-- 在network上增加组件以实现获取玩家等数据并传输给客户端
-- 当前有forest_network,cave_network,即两个世界,该network生成后会设置到TheWorld.net上
-- 同时设置TheWorld监听玩家加入和离开
-- 需要说明的是:
-- 如果后续饥荒还有其他network则需要增加以兼容,不挂在TheWorld上是因为world没有AddNetwork,无法传递数据
-- 所以如果有更好的全局对象且存在AddNetwork,也可以将doraemon_sensory_monitor添加在它身上,以替代network

do
    local netWorks = {"forest_network","cave_network"} -- 森林和洞穴世界
    for _,network in pairs(netWorks) do
        AddPrefabPostInit(network, function(inst)
            if TheWorld.ismastersim then -- 服务器
                Logger:Debug("TheWorld.net添加组件")
                TheWorld.net:AddComponent("doraemon_sensory_monitor") -- 增加组件
                -- 先更新一次
                TheWorld.net.components.doraemon_sensory_monitor:UpdatePlayers()
                TheWorld.net.components.doraemon_sensory_monitor:UpdateCameras()

                TheWorld:ListenForEvent("ms_playerjoined", function(_, player)
                    --ms_playerjoined 玩家加入
                    --ms_playerspawn 玩家生成
                    --dprint("Player Left:", player, player.userid)
                    -- 可以成功监听 prefab: 玩家人物prefab name:玩家名称
                    Logger:Debug({"加入游戏",player.prefab,player.name,player.GUID})
                    TheWorld.net.components.doraemon_sensory_monitor:UpdatePlayers()
                end)

                TheWorld:ListenForEvent("ms_playerleft", function(_, player)
                    --dprint("Player Left:", player, player.userid)
                    -- 可以成功监听 prefab: 玩家人物prefab name:玩家名称
                    Logger:Debug({"离开游戏",player.prefab,player.name,player.GUID})
                    TheWorld.net.components.doraemon_sensory_monitor:UpdatePlayers()
                    -- 有人监视他,需要将该用户返回
                    if TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[player] then
                        for _,cameraFollower in pairs(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[player]) do
                            if player == TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER[cameraFollower] and cameraFollower:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG)
                            then
                                SensoryMonitorFn:BackToSelf(cameraFollower) -- 返回监视自己的body
                            end
                        end
                    end
                    -- 如果他正在监视,则先退出
                    if player:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG) then
                        SensoryMonitorFn:Exit(player)
                    end
                    -- 删除有关资源
                    Table:RemoveKey(TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS,player)
                    Table:RemoveKey(TUNING.DORAEMON_TECH.SENSORY_MONITOR_LEADER,player)
                    Table:RemoveKey(TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY,player)
                end)
            end
        end)

    end


end

-- 屏幕
do
    AddClassPostConstruct("screens/playerhud", function(self)
        -- 设置面板 每次popscreen会自动销毁 所以不需要提前保存
        --self.sensoryMonitorPanel =  SensoryMonitorPanel(self.owner)
        --self.sensoryMonitorPanel:Hide()
        local switchBtn = TEMPLATES.StandardButton(nil ,
                STRINGS.DORAEMON_TECH.DORAEMON_SENSORY_MONITOR_PANEL_SWITCH,
                {100, 50}
        )
        switchBtn:SetOnClick(function ()
            --if self.sensoryMonitorPanel ~= nil then
                self.sensoryMonitorPanel =  SensoryMonitorPanel(self.owner)
                self:OpenScreenUnderPause(self.sensoryMonitorPanel)
                return self.sensoryMonitorPanel
            --end
        end)
        switchBtn:SetVAnchor(ANCHOR_TOP)
        switchBtn:SetHAnchor(ANCHOR_MIDDLE)
        switchBtn:SetScaleMode(SCALEMODE_PROPORTIONAL)
        switchBtn:SetMaxPropUpscale(MAX_HUD_SCALE)
        --设置widget的位置，上面通过 SetHAnchor，SetVAnchor两个函数设置了大致位置，这里的坐标原点就是以这两个函数设置的方向为基础计算的，左减右加，上加下减
        switchBtn:SetPosition(-100, -50)
        switchBtn:Hide()
        self:AddChild(switchBtn)

        -- 退出监控按钮
        local closeBtn = TEMPLATES.StandardButton(nil ,
                STRINGS.DORAEMON_TECH.DORAEMON_SENSORY_MONITOR_PANEL_EXIT,
                {100, 50}
        )
        closeBtn:SetOnClick(function ()
            -- 退出监视
            if closeBtn.parent ~= nil then
                self:HideSensoryMonitor()
                SendModRPCToServer(MOD_RPC[modname]["senory_monitor.exit"], false)
            end
        end)
        closeBtn:SetVAnchor(ANCHOR_TOP)
        closeBtn:SetHAnchor(ANCHOR_MIDDLE)
        closeBtn:SetScaleMode(SCALEMODE_PROPORTIONAL)
        closeBtn:SetMaxPropUpscale(MAX_HUD_SCALE)
        closeBtn:SetPosition(100, -50)
        closeBtn:Hide()
        self:AddChild(closeBtn)
        -- 进入监控,显示方法
        function self:ShowSensoryMonitor()
            switchBtn:Show()
            closeBtn:Show()
        end
        -- 关闭监控(仅UI)
        function self:HideSensoryMonitor()
            -- 存在监控面板
            if self.sensoryMonitorPanel ~= nil
                and self.sensoryMonitorPanel.inst:IsValid() -- 没有被关闭
            then
                TheFrontEnd:PopScreen(self.sensoryMonitorPanel)
                --self.sensoryMonitorPanel:Hide()
            end
            if switchBtn.shown then
                switchBtn:Hide()
                closeBtn:Hide()
            end
        end
        -- 更新玩家
        function self:UpdateSensoryPlayerMonitor()
            if self.sensoryMonitorPanel then
                self.sensoryMonitorPanel:UpdatePlayerScrollPanel()
            end
        end
        -- 更新摄像头
        function self:UpdateSensoryCameraMonitor()
            if self.sensoryMonitorPanel then
                self.sensoryMonitorPanel:UpdateCameraScrollPanel()
            end
        end
    end)
end

-- 玩家相关
do
    AddPlayerPostInit(function(inst)
        -- 初始化相关对象
        inst._senory_monitor_status = net_bool(inst.GUID, "senory_monitor._status", "senory_monitor._statusdirty")
        inst._senory_monitor_status:set(false)
        if not TheWorld.ismastersim then
            inst:ListenForEvent("senory_monitor._statusdirty", function()
                local status = inst._senory_monitor_status:value()
                Logger:Debug({"修改_senory_monitor_status",status,inst.HUD,TheWorld.ismastersim},1)
                if inst.HUD then -- 存在hud , 说明是客户端
                    if status then
                        inst.HUD:ShowSensoryMonitor()
                    else
                        inst.HUD:HideSensoryMonitor()
                    end
                end
            end)
        else
            local oldGetSaveRecord = inst.GetSaveRecord -- 保存数据
            function inst:GetSaveRecord(...)
                -- 保存时需要退出监视，暂时这么处理吧，
                -- 否则正在监视时，手动退出游戏，需要保存用户监视前的位置和物品信息
                -- 并且进入游戏时还原
                if inst:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG) then
                    SensoryMonitorFn:Exit(inst)
                end
                return oldGetSaveRecord(inst,...)
            end


            -- 该table中inst对应的是数组对象,所以这里提前初始化下
            TUNING.DORAEMON_TECH.SENSORY_MONITOR_FOLLOWERS[inst] = {}

            -- 以下代码废弃,只保存了地址且加载那块未实现成功
            -- 保存和加载,支持监控,以免监控中退出游戏
--[[            local oldOnSave = inst.OnSave
            inst.OnSave = function(inst,data)
                -- 如果正在监视,则保存body的位置
                if inst:HasTag(TUNING.DORAEMON_TECH.SENSORY_MONITOR_TAG)
                        and  TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY[inst] ~= nil
                then
                    local x,y,z = TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY[inst].Transform:GetWorldPosition()
                    data.sensory_monitor_status = true
                    data.sensory_monitor_body_posx = x
                    data.sensory_monitor_body_posy = y
                    data.sensory_monitor_body_posz = z
                else
                    data.senory_monitor_status = false
                end
                -- 调用旧逻辑
                return oldOnSave(inst,data)
            end
            local _OldOnLoad = inst._OnLoad
            inst._OnLoad = function(inst,data,newents,...)
                -- 需要先调用旧逻辑
                if _OldOnLoad ~= nil then
                    _OldOnLoad(inst,data)
                end
                -- 将玩家改到当时body的位置
                Logger:Debug({"自定义OnLoad",data.sensory_monitor_status,data.sensory_monitor_body_posx,data.sensory_monitor_body_posy,data.sensory_monitor_body_posz})
                if data.sensory_monitor_status then
                    -- 临时记录position ,然后再玩家加入的时候更改位置，暂时如此处理
                    -- 最好能直接改变用户保存的位置，就不需要这么麻烦了
                    inst._load_sensory_monitor_status = data.sensory_monitor_status
                    inst._load_sensory_monitor_body_posx = data.sensory_monitor_body_posx
                    inst._load_sensory_monitor_body_posy = data.sensory_monitor_body_posy
                    inst._load_sensory_monitor_body_posz = data.sensory_monitor_body_posz
                    -- 这里设置没用
                    --inst.Physics:Teleport
                    inst.Transform:SetPosition(data.sensory_monitor_body_posx,data.sensory_monitor_body_posy,data.sensory_monitor_body_posz)
                end
            end]]
        end
    end)
end


-- inventory 重写dropitem方法,以阻止物品捡起限定
-- (神话物品捡起限定是捡起后调用了DropItem方法)
do
    AddComponentPostInit("inventory",function(self)
        local oldDropItem = self.DropItem
        function self:DropItem(...)
            -- 如果实体是监视器的body 则不能丢弃物品(什么都不做)
            if self.inst.prefab ~= TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY_PREFAB then
                return oldDropItem(self,...)
            end
            return
        end
    end)
end

-- health组件，防止监控的body被秒
do
    AddComponentPostInit("health",function(self)
        local oldDoDelta = self.DoDelta
        function self:DoDelta(...)
            -- 如果实体是监视器的body 则不能丢弃物品(什么都不做)
            if self.inst.prefab ~= TUNING.DORAEMON_TECH.SENSORY_MONITOR_BODY_PREFAB then
                return oldDoDelta(self,...)
            end
            return 0
        end
    end)
end

-- 摄像头 writable增加摄像头布局,同木牌
do
    -- 增加布局
    local writeables = require("writeables")
    writeables.AddLayout(TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERA_PREFAB,writeables.GetLayout("homesign"))
end
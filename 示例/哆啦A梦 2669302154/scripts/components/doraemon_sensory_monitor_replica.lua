--------------------------------
--[[ 监控组件]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-02-11]]
--[[ @updateTime: 2022-02-11]]
--[[ @email: x7430657@163.com]]
--------------------------------
local Table = require("util/table")

local function OnPlayersDirty(self, inst)
    self.players = Table:ToTable(inst.replica.doraemon_sensory_monitor._players:value())
    if ThePlayer and ThePlayer.HUD then -- 存在hud , 说明是客户端
        ThePlayer.HUD:UpdateSensoryPlayerMonitor()
    end
end

local function OnCamerasDirty(self, inst)
    -- 客机同步camera,注意只能同步id为nil或者用户id相等的
    local items = Table:ToTable(inst.replica.doraemon_sensory_monitor._cameras:value())
    self.cameras = {}
    for _,item in pairs(items) do
        if item.userid == nil or item.userid == ThePlayer.userid then
            table.insert(self.cameras,item)
        end
    end
    if ThePlayer and ThePlayer.HUD then -- 存在hud , 说明是客户端
        ThePlayer.HUD:UpdateSensoryCameraMonitor()
    end
end

local SensoryMonitor = Class(function(self, inst)
    --self._status = net_bool(inst.GUID, "doraemon_evil_passport._status", "doraemon_evil_passport._statusdirty")
    --self._status:set(false)
    self.inst = inst
    self.players = {}
    self.cameras = {}
    self._players = net_string(inst.GUID, "doraemon_sensory_monitor._players", "doraemon_sensory_monitor._playersdirty")
    self._cameras = net_string(inst.GUID, "doraemon_sensory_monitor._cameras", "doraemon_sensory_monitor._camerasdirty")

    if not TheWorld.ismastersim then
        -- 这里做个判断，只在客机里监听这个 destdirty 事件，destdirty事件就是上面定义的字符串通信变量的事件名
        inst:ListenForEvent("doraemon_sensory_monitor._playersdirty", function(inst) OnPlayersDirty(self, inst) end)
        inst:ListenForEvent("doraemon_sensory_monitor._camerasdirty", function(inst) OnCamerasDirty(self, inst) end)
    end
end)

function SensoryMonitor:UpdatePlayers(players_str)
    if TheWorld.ismastersim then
        -- 在这调用复制组件里的方法，将 数据给传过去
        self._players:set(players_str)
    end
end

function SensoryMonitor:UpdateCameras(cameras_str)
    if TheWorld.ismastersim then
        -- 在这调用复制组件里的方法，将 数据给传过去
        self._cameras:set(cameras_str)
    end
end


function SensoryMonitor:GetPlayers()
    return self.players
end
function SensoryMonitor:GetCameras()
    return self.cameras
end
return SensoryMonitor
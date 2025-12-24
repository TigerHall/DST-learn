--------------------------------
--[[ 监控组件]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-02-11]]
--[[ @updateTime: 2022-02-11]]
--[[ @email: x7430657@163.com]]
--------------------------------
local Table = require("util/table")
local PlayerUtil = require("util/player_util")
require "modindex"

local SensoryMonitor = Class(function(self, inst)
    self.inst = inst
    self.players = {}
    self.cameras = {}
end)

function SensoryMonitor:UpdatePlayers()
    local items = {}
    local allPlayers = PlayerUtil:GetAllPlayers(true)
    for k, player in ipairs(allPlayers) do
        table.insert(items,{index = k, name = self:GetPlayerName(player), type = TUNING.DORAEMON_TECH.SENSORY_MONITOR_TYPE_PLAYER , userid = player.userid , guid = player.GUID})
    end
    self.players = items
    -- 同步数据到复制组件里
    if self.inst.replica.doraemon_sensory_monitor then
        -- 在这调用复制组件里的方法，将 self.dest 数据给传过去
        self.inst.replica.doraemon_sensory_monitor:UpdatePlayers(Table:ToString(self.players))
    end
end

function SensoryMonitor:UpdateCameras()
    local items = {}
    local allCameras = TUNING.DORAEMON_TECH.SENSORY_MONITOR_CAMERAS
    print(TUNING.DORAEMON_TECH.MODNAME)
    --local isShare =  GetModConfigData("camera_share",KnownModIndex:GetModActualName(TUNING.DORAEMON_TECH.MODNAME))
    local isShare = TUNING.DORAEMON_TECH.CONFIG.CAMERA_SHARE
    for k, camera in ipairs(allCameras) do
        if isShare or camera._owner == nil then -- 如果是分享的,则不传id
            table.insert(items,{index = k, name = self:GetCameraName(camera), type = TUNING.DORAEMON_TECH.SENSORY_MONITOR_TYPE_CAMERA ,userid = nil , guid = camera.GUID})
        else
            if camera._owner and camera._owner.userid ~= nil and camera._owner.userid:len() > 0 then -- 存在owner
                table.insert(items,{index = k, name = self:GetCameraName(camera), type = TUNING.DORAEMON_TECH.SENSORY_MONITOR_TYPE_CAMERA ,userid = camera._owner.userid , guid = camera.GUID})
            end
        end
    end
    self.cameras = items
    -- 同步数据到复制组件里
    if self.inst.replica.doraemon_sensory_monitor then
        -- 在这调用复制组件里的方法，将 self.dest 数据给传过去
        self.inst.replica.doraemon_sensory_monitor:UpdateCameras(Table:ToString(self.cameras))
    end
end

function SensoryMonitor:GetPlayers()
    return self.players
end
function SensoryMonitor:GetCameras()
    return self.cameras
end

function SensoryMonitor:GetPlayerName(player)
    return player.name or ""
end

function SensoryMonitor:GetCameraName(inst)
    if inst and inst.components
            and inst.components.writeable and inst.components.writeable:GetText()
    then
        return inst.components.writeable:GetText()
    end
    return "未命名"
end
return SensoryMonitor
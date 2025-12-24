--------------------------------
--[[ PlayerUtil: 玩家工具方法]]
--[[ @author: 谅直]]
--[[ @createTime: 2022-01-06]]
--[[ @updateTime: 2022-01-06]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("util/logger")
local Table = require("util/table")
local StringUtil = require("util/string_util")
local PlayerUtil = {}

--[[获取所有玩家,该方法还需要优化]]
--[[如果获取同一个世界玩家，返回的是玩家对象，拥有GUID]]
--[[否则，返回的是clientObj,没有GUID]]
--[[@param sameWorld: 是否同一个世界]]
--[[@param exceptUserIds: table类型,不包含这些用户id的玩家.可为空]]
--[[@return availablePlayers: table类型,key为整数索引,value为玩家]]
--[[
clientObj属性如下：
table: 0000000032407550 len:16 {
           [1:base_skin] => "warly_none"
           [2:eventlevel] => 0
           [3:muted] => false
           [4:admin] => true
           [5:playerage] => 3
           [6:userid] => "KU_paOb59Um"
           [7:friend] => false
           [8:performance] => 0
           [9:vanity] => table: 0000000032407640 len:2 {
                    [1:1] => "playerportrait_bg_rabbithouseyule"
                    [2:2] => "profileflair_yule_puppington"
           }
           [10:userflags] => 0
           [11:name] => "谅直"
           [12:colour] => table: 00000000324076E0 len:4 {
                     [1:1] => 0.80392158031464
                     [2:2] => 0.3098039329052
                     [3:3] => 0.22352941334248
                     [4:4] => 1
           }
           [13:netid] => "76561198100954009"
           [14:equip] => table: 00000000324075A0 len:5 {
                     [1:1] => ""
                     [2:2] => ""
                     [3:3] => ""
                     [4:4] => ""
                     [5:5] => "pickaxe_victorian"
           }
           [15:prefab] => "warly"
           [16:lobbycharacter] => ""
  }
}
]]
function PlayerUtil:GetAllPlayers(sameWorld,exceptUserIds)
    local availablePlayers = {}
    Logger:Debug({"是否开启PVP",TheNet:GetPVPEnabled()})
    if not TheNet:GetPVPEnabled() then -- 没有开启PVP
        -- AllPlayers 对应同一个世界上的玩家 , 但未亲自实测
        -- TheNet:GetClientTable(): 抄自饥荒tab界面
        local allPlayers = sameWorld and AllPlayers or TheNet:GetClientTable()
        allPlayers = allPlayers or {} -- 以防万一,避免nil
        Logger:Debug({"玩家总数",Table:Size(allPlayers)})
        for _, v in ipairs(allPlayers) do
            Logger:Debug({"获取到的玩家",v.name,v.userid})
            if StringUtil:IsNotBlank(v.userid) then
                if exceptUserIds == nil or not Table:HasValue(exceptUserIds,v.userid) then
                    table.insert(availablePlayers,v)
                end
            end
        end
    else
        -- 开启PVP只返回用户自己
        if exceptUserIds == nil or not Table:HasValue(exceptUserIds,ThePlayer.userid) then
            table.insert(availablePlayers,ThePlayer)
        end
    end
    return availablePlayers
end





return PlayerUtil

--------------------------------
--[[ 状态扩展类,已废弃]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-10]]
--[[ @updateTime: 2021-12-10]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("class")
Doraemon_State = Class(function (self,args)
    self.type = args.type--类型: all,client,server
    self.args = args
end)

function Doraemon_State:ClientState()
    --返回客户端client
    self.args.timeline = self.args.client_timeline
    self.args.events = self.args.client_events
    return State(self.args)
end

function Doraemon_State:ServerState()
    --返回服务器client
    self.args.timeline = self.args.server_timeline
    self.args.events = self.args.server_events
    return State(self.args)
end



function Doraemon_State:IsClient()
    return self.type == 'all' or self.type == 'client'
end
function Doraemon_State:IsServer()
    return self.type == 'all' or self.type == 'server'
end


return Doraemon_State
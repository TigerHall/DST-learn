local TravelScreen = require "widgets/travelscreen"
local Travelable = Class(function(self, inst)
    self.inst = inst
    self.name = "木牌:" .. tostring(#Pigpet.homesigns + 1)
    --插入到homesigns表中
    table.insert(Pigpet.homesigns, self.inst)
end)


function Travelable:CollectSceneActions(doer, actions, right)
    if right then
		table.insert(actions, ACTIONS.TRAVEL)
	end
end

function Travelable:OnSave()
    local data = {}
    data.name = self.name
    return data
end   

function Travelable:OnLoad(data)
    if data then
        self.name = data.name
    end
end


function Travelable:OnSelect(traveller)
	if not traveller then
		return
	end
    if traveller.components.health and traveller.components.health:IsDead() then
        return
    end
    --打开选择地点页面
    TheFrontEnd:PushScreen(TravelScreen(self.inst, traveller))
end


function Travelable:OnRemoveEntity()
    --从 homesigns 表中移除
    for k, v in pairs(Pigpet.homesigns) do
        if v == self.inst then
            table.remove(Pigpet.homesigns, k)
            break
        end
    end
end

function Travelable:DoTravel(traveller)
    if not traveller then
        return
    end
    if traveller.components.health and traveller.components.health:IsDead() then
        return
    end
    --传送
    local x, y, z = self.inst.Transform:GetWorldPosition()
    traveller.Transform:SetPosition(x-1, y, z)

    --把宠物猪传送到主角身边
    if traveller.components.leader and traveller.components.leader.followers then
        for kf, _ in pairs(traveller.components.leader.followers) do
             kf.Transform:SetPosition(x-1, y, z)
        end
    end
end

return Travelable









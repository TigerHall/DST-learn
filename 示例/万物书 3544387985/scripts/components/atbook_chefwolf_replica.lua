local ChefWolf = Class(function (self, inst)
    self.inst = inst

    self.orderlistencode = net_string(inst.GUID, "atbook_chefwolf_replica.orderlistencode")
    self.cooktime = net_int(inst.GUID, "atbook_chefwolf_replica.cooktime")
end)

function ChefWolf:GetCookTime()
    return self.cooktime:value() or 0
end

function ChefWolf:GetOrderList()

    local orderlist = DecodeAndUnzipString(self.orderlistencode:value())
    local info = ""
    if orderlist then
        for index, value in ipairs(orderlist) do
            local str = "\n"
            if index == 1 then
                str = str .. string.format("正在制作：%s %d 份，剩余 %d 秒。", STRINGS.NAMES[string.upper(value.prefab)], value.numcook, self:GetCookTime())
            else
                str = str .. string.format("排队中：%s %d 份，预计 %d 秒。", STRINGS.NAMES[string.upper(value.prefab)], value.numcook, value.cooktime)
            end
            info = info .. str
        end

    end
    return info
end

return ChefWolf
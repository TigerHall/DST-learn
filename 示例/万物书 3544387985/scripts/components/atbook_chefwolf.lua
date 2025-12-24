local function oncooktime(self, cooktime)
    if self.inst.replica.atbook_chefwolf then
        self.inst.replica.atbook_chefwolf.cooktime:set(cooktime)
    end
end

local function onorderlistencode(self, orderlistencode)
    if self.inst.replica.atbook_chefwolf then
        self.inst.replica.atbook_chefwolf.orderlistencode:set(orderlistencode)
    end
end

local ChefWolf = Class(function(self, inst)
        self.inst = inst

        self.orderlist = {}
        self.orderlistencode = ""
        self.cooktime = 0

        self.inst:DoPeriodicTask(1, function()
            if self.cooktime == 1 and self.orderlist[1] then
                local product = SpawnPrefab(self.orderlist[1].prefab)
                if product then
                    if product.components.stackable then
                        product.components.stackable:SetStackSize(self.orderlist[1].numcook)
                    end
                    if self.inst.components.container.slots[1] then
                        local item = self.inst.components.container:RemoveItem(self.inst.components.container.slots[1],
                            true)
                        self.inst.components.container:GiveItem(product, 1)
                        self.inst.components.container:GiveItem(item)
                    else
                        self.inst.components.container:GiveItem(product, 1)
                    end
                end
                table.remove(self.orderlist, 1)
                if self.orderlist[1] then
                    self.cooktime = math.ceil(self.orderlist[1].cooktime)
                end
            end
            self.cooktime = math.max(0, math.ceil(self.cooktime - 1))
            self.orderlistencode = ZipAndEncodeString(self.orderlist)

            if self.cooktime == 0 and self.inst.AnimState:IsCurrentAnimation("cook_loop") then
                self.inst.AnimState:PlayAnimation("cook_pst")
                self.inst.AnimState:PushAnimation("idle_full", true)
            end
        end)
    end, nil,
    {
        cooktime = oncooktime,
        orderlistencode = onorderlistencode,
    })

function ChefWolf:Order(order)
    if order then
        -- prefab numcook cooktime
        if #self.orderlist == 0 then
            self.inst.AnimState:PlayAnimation("cook_pre")
            self.inst.AnimState:PushAnimation("cook_loop", true)
        end
        table.insert(self.orderlist, order)
        self.orderlistencode = ZipAndEncodeString(self.orderlist)
        if self.cooktime == 0 then
            self.cooktime = math.ceil(order.cooktime)
        end
    end
end

function ChefWolf:OnSave()
    local data = {}
    data.cooktime = self.cooktime
    data.orderlist = self.orderlist
    return data
end

function ChefWolf:OnLoad(data)
    if data then
        self.cooktime = data.cooktime or 0
        self.orderlist = data.orderlist or {}
        self.orderlistencode = ZipAndEncodeString(self.orderlist)
    end
    if #self.orderlist > 0 then
        self.inst.AnimState:PlayAnimation("cook_loop", true)
    end
end

return ChefWolf

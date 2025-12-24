local SourceModifierList = require("util/sourcemodifierlist")

-- 产物计算：生产时间*（基础效率+加成效率）
local Factory = Class(function(self, inst)
	self.inst = inst

    self.product = nil
    self.produce_rate = 0.05
    self.efficiency = 1
    self.start_produce_time = nil
    self.onproduce = nil

    self.temp_storage = {}
    self.temp_storage_size = 100
    self.storage = nil

    self.produce_task = nil

    self.externalefficiencymultiplier = SourceModifierList(inst, 1, SourceModifierList.additive)
end)

function Factory:SetProduct(product)
    self.product = product
end

function Factory:SetEfficiency(efficiency)
    self.efficiency = efficiency
end

function Factory:SetStorage(storage)
    self.storage = storage
end

function Factory:SetTempStorageSize(size)
    self.temp_storage_size = size
end

function Factory:SetOnProduce(fn)
    self.onproduce = fn
end

function Factory:SetOnCollectTempStorage(fn)
    self.oncollecttempstorage = fn
end

function Factory:GetEfficiency()
    return self.produce_rate * (self.efficiency + self.externalefficiencymultiplier:Get())
end

function Factory:GetProduceDuration()
    return GetTime() - self.start_produce_time
end

function Factory:GetProductNum()
    return self:GetEfficiency() * self:GetProduceDuration()
end

function Factory:SetTempStorage(storage)
    storage = storage or {}

    for k, v in pairs(storage) do
        if v == 0 then
            storage[k] = nil
        end
    end

    self.temp_storage = storage
    if self.inst.replica.hmrfactory then
        self.inst.replica.hmrfactory:SetTempStorage(storage)
    end
end

local function ChooseProduct(product_list)
    local total_weight = 0
    for product, weight in pairs(product_list) do
        total_weight = total_weight + weight
    end

    local rand = math.random() * total_weight
    for product, weight in pairs(product_list) do
        rand = rand - weight
        if rand <= 0 then
            return product
        end
    end
end

function Factory:GenerateProductList()
    local product_list = {}
    if type(self.product) == "string" then
        product_list = {[self.product] = 1}
    else
        product_list = self.product
    end

    local products = {}
    for i = 1, self:GetProductNum() do
        local product = ChooseProduct(product_list)
        if product then
            products[product] = (products[product] or 0) + 1
        end
    end

    if self.temp_storage ~= nil and next(self.temp_storage) ~= nil then
        for product, num in pairs(self.temp_storage) do
            products[product] = (products[product] or 0) + num
        end
        self:SetTempStorage()
    end

    return products
end

function Factory:GetTempStorageNum(temp_products)
    local num = 0
    temp_products = temp_products or self.temp_storage
    for product, n in pairs(self.temp_storage) do
        num = num + n
    end
    return num
end

function Factory:AddToTempStorage(products)
    local temp_products = {}
    for product, num in pairs(products) do
        temp_products[product] = (temp_products[product] or 0) + math.min(num, self.temp_storage_size - self:GetTempStorageNum(temp_products))
        if self.temp_storage_size <= self:GetTempStorageNum(temp_products) then
            break
        end
    end
    self:SetTempStorage(temp_products)
end

function Factory:CollectAllTempStorage(gay)
    for product, num in pairs(self.temp_storage) do
        for i = 1, num do
            local item = SpawnPrefab(product)
            if item ~= nil then
                HMR_UTIL.DropLoot(gay, item, nil, gay == nil and self.inst:GetPosition() or nil)
            end
        end
    end
    self:SetTempStorage()
    if self.oncollecttempstorage then
        self.oncollecttempstorage(self.inst)
    end

    return true
end

function Factory:IsProducing()
    return self.stop_produce ~= true
end

function Factory:Produce()
    local products = {}
    if not self.stop_produce then
        products = self:GenerateProductList()
    else
        products = self.temp_storage
    end

    if self.onproduce then
        self.onproduce(self.inst, products)
    end

    if self.storage ~= nil then
        local container = self.storage.components.container or self.storage.components.inventory
        if container then
            for product, num in pairs(products) do
                for i = 1, num do
                    local item = SpawnPrefab(product)
                    if item ~= nil then
                        local success = container:GiveItem(item, nil, nil, false)
                        if not success then
                            item:Remove()
                        else
                            products[product] = products[product] - 1
                        end
                    else
                        print("产物", product, "无法生成")
                        products[product] = products[product] - 1 -- 避免无法生成的产物堆积
                    end
                end
            end
        end
    end

    if next(products) ~= nil then
        self:AddToTempStorage(products)
    elseif self.stop_produce and self.produce_task ~= nil then
        self.produce_task:Cancel()
        self.produce_task = nil
    end

    self.start_produce_time = GetTime()
end

function Factory:StartProduce()
    if self.produce_task ~= nil then
        self.produce_task:Cancel()
        self.produce_task = nil
    end
    self.stop_produce = false
    self.start_produce_time = GetTime()
    self.produce_task = self.inst:DoPeriodicTask(10, function() self:Produce() end, math.random())
end

function Factory:StopProduce()
    self.stop_produce = true
end

function Factory:OnSave()
    local data =
    {
        temp_storage = self.temp_storage,

    }
    return next(data) ~= nil and data or nil
end

function Factory:OnLoad(data)
    if data then
        self:SetTempStorage(data.temp_storage or {})
    end
end

return Factory

local params = require("containers").params
local Utils = require("aab_utils/utils")

-- 不要一次全销毁，按堆叠销毁
local function DestroyContents(self, onpredestroyitemcallbackfn)
    for k = 1, self.numslots do
        local item = k and self.slots[k] or nil
        item = item and self:RemoveItem_Internal(item, k) --取一个就行了
        -- local item = self:RemoveItemBySlot(k)
        if item ~= nil then
            if onpredestroyitemcallbackfn ~= nil then
                onpredestroyitemcallbackfn(self.inst, item)
            end
            if item:IsValid() then
                item:Remove()
            end
        end
    end
end

local function StartCookingBefore(self, doer)
    self._aab_doer = doer --连续做饭需要一个厨师
end

local function TryContinueCook(inst)
    local self = inst.components.stewer
    local container = inst.components.container
    if self._aab_doer and self._aab_doer:IsValid()
        and not self:IsCooking()
        and container and not container:IsOpenedByOthers(self._aab_doer)
        and self:CanCook()
    then
        self:Harvest()                    --先把食物扔出来
        self:StartCooking(self._aab_doer) --继续
    else
        self._aab_doer = nil
    end
end

local function ondonecookingAfter(retTab, inst)
    inst:DoTaskInTime(0, TryContinueCook)
end

for _, v in ipairs({
    "cookpot",
    "archive_cookpot",
    "portablecookpot",
    "portablespicer"
}) do
    if params[v] then
        params[v].acceptsstacks = nil
    end

    AddPrefabPostInit(v, function(inst)
        if not TheWorld.ismastersim then return end

        inst.components.container.DestroyContents = DestroyContents
        Utils.FnDecorator(inst.components.stewer, "StartCooking", StartCookingBefore)
        Utils.FnDecorator(inst.components.stewer, "ondonecooking", nil, ondonecookingAfter)
    end)
end

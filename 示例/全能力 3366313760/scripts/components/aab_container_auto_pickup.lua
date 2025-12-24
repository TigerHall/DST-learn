local AutoPickup = Class(function(self, inst)
    self.inst = inst

    self.target = nil --需要收集的

    self.bird = nil   --鸟
    self._onchildkilled = function(bird) self:OnChildKilled(bird) end
end)

function AutoPickup:OnChildKilled(bird)
    if self.bird == bird then
        self.bird = nil
        self:FindNearItem() --再生成一个
    end
end

function AutoPickup:SpawnBird(bird)
    if self.bird and self.bird:IsValid() then
        return
    end

    self.bird = bird or SpawnAt("aab_polly_rogers", self.inst)
    self.inst:ListenForEvent("onremove", self._onchildkilled, self.bird)
    self.bird:Setup(self.inst) --绑定
end

local function CheckTarget(inst, self)
    local item = self.target
    if not (item
            and item:IsValid()
            and not item:HasTag("INLIMBO")
            and item.components.inventoryitem
            and item.components.inventoryitem.is_landed
            and item.components.inventoryitem.canbepickedup
            and not item.components.inventoryitem.owner
            and self.inst.components.container:CanTakeItemInSlot(item)
            and inst.components.container:CanAcceptCount(item) > 0
            and inst:IsNear(item, TUNING.AAB_CONTAINER_AUTO_PICKUP)) then
        self:FindNearItem() --再生成一个
    end
end

function AutoPickup:GetTarget()
    CheckTarget(self.inst, self)
    return self.target
end

local PICKUP_MUST_TAGS = { "_inventoryitem" }
local PICKUP_CANT_TAGS = { "INLIMBO" }
function AutoPickup:FindNearItem()
    if not self.inst.components.container
        or (self.inst.components.equippable and self.inst.components.equippable:IsEquipped()) --不是我不想，是ACTIONS.STORE好像不支持背包，不过像熊桶可以
    then
        return
    end

    local items = {}
    self.inst.components.container:ForEachItem(function(ent) items[ent.prefab] = true end)

    local x, y, z = self.inst.Transform:GetWorldPosition()
    for _, v in ipairs(TheSim:FindEntities(x, y, z, TUNING.AAB_CONTAINER_AUTO_PICKUP, PICKUP_MUST_TAGS, PICKUP_CANT_TAGS)) do
        if items[v.prefab]
            and v.components.inventoryitem.is_landed
            and not v.components.inventoryitem.owner
            and v.components.inventoryitem.canbepickedup
            and self.inst.components.container:CanTakeItemInSlot(v)
            and self.inst.components.container:CanAcceptCount(v) > 0
        then
            self.target = v
            self:SpawnBird()
            self.checktask = self.inst:DoPeriodicTask(2, CheckTarget, 2, self)
            return
        end
    end

    self.target = nil
end

local function OnItemGet(inst, data)
    CheckTarget(inst, inst.components.aab_container_auto_pickup)
end

function AutoPickup:SetEnable(enable)
    local inst = self.inst
    if enable then
        inst:AddTag("aab_container_auto_pickup")

        inst:ListenForEvent("itemget", OnItemGet)

        self:FindNearItem()
    else
        inst:RemoveTag("aab_container_auto_pickup")

        inst:RemoveEventCallback("itemget", OnItemGet)

        if self.bird then
            self.bird.components.inventory:DropEverything()
            ReplacePrefab(self.bird, "small_puff")
        end
        if self.checktask then
            self.checktask:Cancel()
            self.checktask = nil
        end
        self.target = nil
    end
end

----------------------------------------------------------------------------------------------------

function AutoPickup:OnEntityWake()
    if self.inst:HasTag("aab_container_auto_pickup") then
        self.checktask = self.inst:DoPeriodicTask(2, CheckTarget, 0, self)
    end
end

function AutoPickup:OnEntitySleep()
    if self.checktask then
        self.checktask:Cancel()
        self.checktask = nil
    end
end

----------------------------------------------------------------------------------------------------
function AutoPickup:LoadPostPass(newents, savedata)
    if savedata.bird ~= nil then
        local bird = newents[savedata.bird]
        if bird ~= nil then
            bird = bird.entity
            self:SpawnBird(bird)
        end
    end
end

function AutoPickup:OnSave()
    local data = {}
    local refs = {}
    data.enable = self.inst:HasTag("aab_container_auto_pickup")

    if self.bird and self.bird:IsValid() then
        data.bird = self.bird.GUID
        refs = { data.bird }
    end

    return data, refs
end

function AutoPickup:OnLoad(data)
    if not data then return end

    if data.enable then
        self:SetEnable(true)
    end
end

return AutoPickup

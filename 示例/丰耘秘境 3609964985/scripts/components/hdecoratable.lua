local function GetBuild(inst)   -- 来自花花
    local str = inst.entity:GetDebugString()
	if not str then
		return nil
	end
	local bank, build, anim = str:match("bank: (.+) build: (.+) anim: .+:(.+) Frame")

    return bank, build, anim
end

local function EncodeData(slot, bank, build, anim, stacksize)
    if bank == nil or build == nil or anim == nil or stacksize == nil then
        return string.format("slot:%d", slot)
    else
        return string.format("slot:%d,bank:%s,build:%s,anim:%s,stacksize:%d", slot, bank, build, anim, stacksize)
    end
end

local function DecodeData(data)
    local slot = data:match("slot:(%d+)")
    local bank, build, anim, stacksize = data:match("bank:(.+),build:(.+),anim:(.+),stacksize:(%d+)")
    return tonumber(slot), bank, build, anim, stacksize and tonumber(stacksize) or 0
end

local HDecoratable = Class(function(self, inst)
    self.inst = inst

    self.decors = {}

    -- 刚取走再拿出时，两次slot相同，导致不更新
    self._update = net_event(inst.GUID, "net_update")
    self._itemdata = net_string(inst.GUID, "net_itemdata")

    self.inst:ListenForEvent("itemget", function(inst, data)
        if data and data.slot then
            self.inst:DoTaskInTime(0, function()
                local bank, build, anim = GetBuild(data.item)
                local stasksize = data.item.replica.stackable ~= nil and data.item.replica.stackable:StackSize() or 1
                self._itemdata:set(EncodeData(data.slot, bank, build, anim, stasksize))
                self._update:push()
            end)
        end
    end)
    self.inst:ListenForEvent("itemlose", function(inst, data)
        if data and data.slot then
            self._itemdata:set(EncodeData(data.slot))
            self._update:push()
        end
    end)


    if not TheWorld.ismastersim then
        self.inst:ListenForEvent("net_update", function()
            self:Decorate(self._itemdata:value())
        end)

        return
    end

    local function OnStackSizeChanged(item, data)
        local slot = inst.components.container:GetItemSlot(item)
        local bank, build, anim = GetBuild(item)
        local stasksize = item.replica.stackable:StackSize()
        self._itemdata:set(EncodeData(slot, bank, build, anim, stasksize))
        self._update:push()
    end

    self.inst:ListenForEvent("onopen", function()
        for _, item in pairs(self.inst.components.container.slots) do
            if item ~= nil and item.components.stackable ~= nil then
                inst:ListenForEvent("stacksizechange", OnStackSizeChanged, item)
            end
        end
    end)
    self.inst:ListenForEvent("onclose", function()
        inst:RemoveEventCallback("stacksizechange", OnStackSizeChanged)
    end)
end)

local function Decor_OnRemoveEntity(inst)
	local parent = inst.entity:GetParent()
	if parent and parent.highlightchildren then
		table.removearrayvalue(parent.highlightchildren, inst)
	end
end

local function CreateDecorByEntity(bank, build, anim, stacksize)
	local inst = CreateEntity()

	inst:AddTag("FX")
    inst:AddTag("hmr_decor")
	inst.entity:SetCanSleep(TheWorld.ismastersim)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst.AnimState:SetBank(bank)
	inst.AnimState:SetBuild(build)
	inst.AnimState:PlayAnimation(anim, true)
    local scale = stacksize * 0.1
    inst.AnimState:SetScale(scale, scale)

	inst.OnRemoveEntity = Decor_OnRemoveEntity

	return inst
end

function HDecoratable:SetSwapSymbolData(swapsymbol, offset_x, offset_y)
    self.swapsymbol = swapsymbol
    self.offset_x = offset_x
    self.offset_y = offset_y
end

local function GetSlotPos(inst, slot)
    local widget = inst.replica.container:GetWidget()
    if widget ~= nil and widget.slotpos ~= nil then
        return widget.slotpos[slot]
    end
end

function HDecoratable:Decorate(itemdata)
    local inst = self.inst
    local slot, bank, build, anim, stacksize = DecodeData(itemdata)

    if self.decors[slot] ~= nil then
        self.decors[slot]:Remove()
        self.decors[slot] = nil
    end

    if bank ~= nil and build ~= nil and anim ~= nil then
        local decor = CreateDecorByEntity(bank, build, anim, stacksize)
        if decor ~= nil then
            decor.entity:SetParent(inst.entity)
            local pos = GetSlotPos(inst, slot)
            local x, y = pos.x + self.offset_x, - pos.y + self.offset_y
            -- 参数6：为true时不改变scale(不知道具体什么作用)
            decor.Follower:FollowSymbol(inst.GUID, self.swapsymbol, x, y, 0, false)
            self.decors[slot] = decor
        end
    end
end

function HDecoratable:Refresh()
    if TheWorld.ismastersim then
        local num = 0
        for _, item in pairs(self.inst.components.container.slots) do
            if item ~= nil then
                self.inst:DoTaskInTime(num * FRAMES, function()
                    local bank, build, anim = GetBuild(item)
                    local stasksize = item.replica.stackable ~= nil and item.replica.stackable:StackSize() or 1
                    self._itemdata:set(EncodeData(self.inst.components.container:GetItemSlot(item), bank, build, anim, stasksize))
                    self._update:push()
                end)
                num = num + 1
            end
        end
    else
        SendModRPCToServer(GetModRPC("HMR", "hdecoratable_refresh"), self.inst)
    end
end

function HDecoratable:OnRemoveEntity()
    for k, decor in pairs(self.decors) do
        decor:Remove()
    end
end
HDecoratable.OnRemoveFromEntity = HDecoratable.OnRemoveEntity

return HDecoratable


--[[
local HDecoratable = Class(function(self, inst)
    self.inst = inst

    self.decors = {}

    self.inst:ListenForEvent("itemget", function(inst, data)
        if data and data.slot then
            self:DecorateBySlot(data.slot)
        end
    end)
    self.inst:ListenForEvent("itemlose", function(inst, data)
        if data and data.slot then
            self:DecorateBySlot(data.slot)
        end
    end)

    local function OnStackSizeChanged(item, data)
        print("OnStackSizeChanged", item, data)
        local slot = inst.components.container:GetItemSlot(item)
        print("slot", slot)
        if slot ~= nil then
            self:DecorateBySlot(slot)
        end
    end
    self.inst:ListenForEvent("onopen", function()
        print("onopen")
        for _, item in pairs(self.inst.components.container.slots) do
            print("onopen item", item)
            if item ~= nil and item.components.stackable ~= nil then
                print("onopen item listen", item)
                inst:ListenForEvent("stacksizechange", OnStackSizeChanged, item)
            end
        end
    end)
    self.inst:ListenForEvent("onclose", function()
        inst:RemoveEventCallback("stacksizechange", OnStackSizeChanged)
    end)
end)

local function Decor_OnRemoveEntity(inst)
	local parent = inst.entity:GetParent()
	if parent and parent.highlightchildren then
		table.removearrayvalue(parent.highlightchildren, inst)
	end
end

local function Decor_OnLoad(inst, data)
    if data.slot then
        inst.slot = data.slot
    end
end

local function Decor_OnSave(inst, data)
    if inst.slot then
        data.slot = inst.slot
    end
end

local function GetBuild(inst)
    local str = inst.entity:GetDebugString()
	if not str then
		return nil
	end
	local bank, build, anim = str:match("bank: (.+) build: (.+) anim: .+:(.+) Frame")

    return bank, build, anim
end

local function CreateDecorByEntity(item)
	local inst = CreateEntity()

	inst:AddTag("FX")
    inst:AddTag("hmr_decor")
	inst.entity:SetCanSleep(TheWorld.ismastersim)
	inst.persists = false

    local bank, build, anim = GetBuild(item)

    if bank == nil or build == nil or anim == nil then
        return nil
    end

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst.AnimState:SetBank(bank)
	inst.AnimState:SetBuild(build)
	inst.AnimState:PlayAnimation(anim)
    local stacksize = item.replica.stackable ~= nil and item.replica.stackable:StackSize() or 1
    local scale = stacksize * 0.1
    inst.AnimState:SetScale(scale, scale)

	inst.OnRemoveEntity = Decor_OnRemoveEntity
    inst.OnLoad = Decor_OnLoad
    inst.OnSave = Decor_OnSave

	return inst
end

function HDecoratable:SetSwapSymbolData(swapsymbol, offset_x, offset_y)
    self.swapsymbol = swapsymbol
    self.offset_x = offset_x
    self.offset_y = offset_y
end

local function GetSlotPos(inst, slot)
    local widget = inst.replica.container:GetWidget()
    if widget ~= nil and widget.slotpos ~= nil then
        return widget.slotpos[slot]
    end
end

function HDecoratable:DecorateBySlot(slot)
    local inst = self.inst
    local item = inst.components.container:GetItemInSlot(slot)

    if item ~= nil then
        if self.decors[slot] ~= nil then
            self.decors[slot]:Remove()
            self.decors[slot] = nil
        end

        local decor = CreateDecorByEntity(item)
        if decor ~= nil then
            decor.entity:SetParent(inst.entity)
            local pos = GetSlotPos(inst, slot)
            local x, y = pos.x + self.offset_x, - pos.y + self.offset_y
            -- 参数6：为true时不改变scale(不知道具体什么作用)
            decor.Follower:FollowSymbol(inst.GUID, self.swapsymbol, x, y, 0, false)
            self.decors[slot] = decor
        end
    else
        if self.decors[slot] ~= nil then
            self.decors[slot]:Remove()
            self.decors[slot] = nil
        end
    end
end

function HDecoratable:OnRemoveEntity()
    for k, decor in pairs(self.decors) do
        decor:Remove()
    end
end
HDecoratable.OnRemoveFromEntity = HDecoratable.OnRemoveEntity

function HDecoratable:OnLoad(data)
    self.inst:DoTaskInTime(2, function()
        for _, item in pairs(self.inst.components.container.slots) do
            print("OnLoad item", item)
            if item ~= nil then
                self:DecorateBySlot(self.inst.components.container:GetItemSlot(item))
            end
        end
    end)
end

return HDecoratable
]]
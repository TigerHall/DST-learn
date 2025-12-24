local function GetPriority(list)
    local length = 0
    for k,v in pairs(list) do
        length = length + 1
    end
    return length
end
local function UnequipItem(player, slot)
    if slot ~= nil then
        local tool = player.components.inventory:GetEquippedItem(slot)
        if tool ~= nil then
            --inventory.GiveItem自带能否放进物品栏的控制
            player.components.inventory:GiveItem(player.components.inventory:Unequip(slot))
        end
    end
end
local function CreateItem(self, itemdata, setpos)
    local item = SpawnPrefab(itemdata.prefab, itemdata.skinname, itemdata.skin_id)
    if item ~= nil and item:IsValid() then
        if setpos then
            item.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        end
        item:SetPersistData(itemdata.data)
        return item
    end
end

local function OnReroll(inst)
    local self = inst.components.dressup
    self.swaplist = {}
    for _,v in pairs(self.itemlist) do
        if v ~= nil and v.item ~= nil then
            local item = CreateItem(self, v.item, true)
            if item ~= nil then
                if item.components.inventoryitem ~= nil then
                    item.components.inventoryitem:OnDropped(true)
                end
            end
        end
    end
    self.itemlist = {}
end
local function EquipSet_dress(inst, item)
    if DRESSUP_DATA_LEGION[item.prefab] then
        local dd = DRESSUP_DATA_LEGION[item.prefab]
        if dd.onequipfn ~= nil then
            local slot = inst.components.dressup:GetDressSlot(item, dd)
            if slot and inst.components.dressup.itemlist[slot] ~= nil then
                dd.onequipfn(inst, item)
            end
        end
	end
end
local function OnEquip_dress(inst, data)
    if data == nil or data.item == nil then
        return
    end
	EquipSet_dress(inst, data.item)
    if data.eslot == EQUIPSLOTS.HANDS then --装备手部装备时显示提灯图层，恢复盾牌贴图
        inst.AnimState:Show("lantern_overlay") --这里用的小写，和 LANTERN_OVERLAY 不同，就可以不被幻化逻辑覆盖
    end
end
local function OnFix_dress(inst, data)
    if inst.components.inventory == nil then
        return
    end
    for k, v in pairs(inst.components.inventory.equipslots) do
        if v ~= nil then
            EquipSet_dress(inst, v)
        end
    end
end
local function OnUnequip_dress(inst, data)
    if data == nil then
        return
    end
    if data.eslot == EQUIPSLOTS.HANDS then --卸下手部装备时隐藏提灯图层，防止悬空盾牌出现
        inst.AnimState:Hide("lantern_overlay") --这里用的小写，和 LANTERN_OVERLAY 不同，就可以不被幻化逻辑覆盖
    end
end

local BODYTALL = "body_t"

local DressUp = Class(function(self, inst)
    self.inst = inst
    self.itemlist = {
        -- body = { item = nil, swaps = {结构与self.swaplist相同}, priority = 0 },
    }
    self.swaplist = {
        -- swap_object = {
        --     buildskin = nil,
        --     buildfile = nil,
        --     buildsymbol = nil,
        --     guid = nil,
        --     type = nil, --clear、swap、show、hide
        --     priority = 0
        -- }
    }
    self.itemdd = {} --用来保存每个装备的特殊数据

    inst:ListenForEvent("ms_playerreroll", OnReroll) --重选人物时
    inst:ListenForEvent("equip", OnEquip_dress)
    inst:ListenForEvent("dressup_l", OnFix_dress)
	inst:ListenForEvent("unequip", OnUnequip_dress)
end)

function DressUp:GetDressData(buildskin, buildfile, buildsymbol, guid, type)
    return {
        buildskin = buildskin,
        buildfile = buildfile,
        buildsymbol = buildsymbol,
        guid = guid,
        type = type,
        priority = 0 --默认最高优先度，后面才更新
    }
end

function DressUp:SetDressTop(itemswap)
    itemswap["headbase_hat"] = self:GetDressData(nil, nil, nil, nil, "clear")

    itemswap["HAT"] = self:GetDressData(nil, nil, nil, nil, "show")
    itemswap["HAIR_HAT"] = self:GetDressData(nil, nil, nil, nil, "show")
    itemswap["HAIR_NOHAT"] = self:GetDressData(nil, nil, nil, nil, "hide")
    itemswap["HAIR"] = self:GetDressData(nil, nil, nil, nil, "hide")

    itemswap["HEAD"] = self:GetDressData(nil, nil, nil, nil, "hide")
    itemswap["HEAD_HAT"] = self:GetDressData(nil, nil, nil, nil, "show")
    itemswap["HEAD_HAT_NOHELM"] = self:GetDressData(nil, nil, nil, nil, "show")
    itemswap["HEAD_HAT_HELM"] = self:GetDressData(nil, nil, nil, nil, "hide")

    itemswap["face"] = self:GetDressData(nil, nil, nil, nil, "showsym")
    itemswap["swap_face"] = self:GetDressData(nil, nil, nil, nil, "showsym")
    itemswap["beard"] = self:GetDressData(nil, nil, nil, nil, "showsym")
    itemswap["cheeks"] = self:GetDressData(nil, nil, nil, nil, "showsym")

    itemswap["helmex"] = self:GetDressData(nil, nil, nil, nil, "no")
end
function DressUp:SetDressOpenTop(itemswap)
    itemswap["headbase_hat"] = self:GetDressData(nil, nil, nil, nil, "clear")

    itemswap["HAT"] = self:GetDressData(nil, nil, nil, nil, "show")
    itemswap["HAIR_HAT"] = self:GetDressData(nil, nil, nil, nil, "hide")
    itemswap["HAIR_NOHAT"] = self:GetDressData(nil, nil, nil, nil, "show")
    itemswap["HAIR"] = self:GetDressData(nil, nil, nil, nil, "show")

    itemswap["HEAD"] = self:GetDressData(nil, nil, nil, nil, "show")
    itemswap["HEAD_HAT"] = self:GetDressData(nil, nil, nil, nil, "hide")
    itemswap["HEAD_HAT_NOHELM"] = self:GetDressData(nil, nil, nil, nil, "hide")
    itemswap["HEAD_HAT_HELM"] = self:GetDressData(nil, nil, nil, nil, "hide")

    itemswap["face"] = self:GetDressData(nil, nil, nil, nil, "showsym")
    itemswap["swap_face"] = self:GetDressData(nil, nil, nil, nil, "showsym")
    itemswap["beard"] = self:GetDressData(nil, nil, nil, nil, "showsym")
    itemswap["cheeks"] = self:GetDressData(nil, nil, nil, nil, "showsym")

    itemswap["helmex"] = self:GetDressData(nil, nil, nil, nil, "no")
end
function DressUp:SetDressFullHead(itemswap) --头部完全不显示
    itemswap["swap_hat"] = self:GetDressData(nil, nil, nil, nil, "clear")

    itemswap["HAT"] = self:GetDressData(nil, nil, nil, nil, "hide")
    itemswap["HAIR_HAT"] = self:GetDressData(nil, nil, nil, nil, "hide")
    itemswap["HAIR_NOHAT"] = self:GetDressData(nil, nil, nil, nil, "hide")
    itemswap["HAIR"] = self:GetDressData(nil, nil, nil, nil, "hide")

    itemswap["HEAD"] = self:GetDressData(nil, nil, nil, nil, "hide")
    itemswap["HEAD_HAT"] = self:GetDressData(nil, nil, nil, nil, "show")
    itemswap["HEAD_HAT_NOHELM"] = self:GetDressData(nil, nil, nil, nil, "hide")
    itemswap["HEAD_HAT_HELM"] = self:GetDressData(nil, nil, nil, nil, "show")

    itemswap["face"] = self:GetDressData(nil, nil, nil, nil, "hidesym")
    itemswap["swap_face"] = self:GetDressData(nil, nil, nil, nil, "hidesym")
    itemswap["beard"] = self:GetDressData(nil, nil, nil, nil, "hidesym")
    itemswap["cheeks"] = self:GetDressData(nil, nil, nil, nil, "hidesym")

    itemswap["helmex"] = self:GetDressData(nil, nil, nil, nil, "yes")
end
function DressUp:SetDressHand(itemswap)
    itemswap["whipline"] = self:GetDressData(nil, nil, nil, nil, "clear")
    itemswap["lantern_overlay"] = self:GetDressData(nil, nil, nil, nil, "clear")
end
function DressUp:SetDressShield(itemswap)
    itemswap["LANTERN_OVERLAY"] = self:GetDressData(nil, nil, nil, nil, "show")
    itemswap["swap_object"] = self:GetDressData(nil, nil, nil, nil, "clear")
    itemswap["whipline"] = self:GetDressData(nil, nil, nil, nil, "clear")
end

function DressUp:GetDressSlot(item, data)
    if data.dressslot ~= nil then
        return data.dressslot
    elseif data.istallbody then
        return BODYTALL
    elseif item.components.equippable ~= nil then
        return item.components.equippable.equipslot
    else
        return nil
    end
end

-----

function DressUp:InitClear(symbol) --恢复实际展示的默认效果（清除）
    if self.swaplist[symbol] ~= nil then --该通道有幻化数据的话，就不恢复
        return
    end
    self.inst.AnimState:ClearOverrideSymbol(symbol)
end
function DressUp:InitHideSym(symbol) --恢复实际展示的默认效果（隐藏通道）
    if self.swaplist[symbol] ~= nil then
        return
    end
    self.inst.AnimState:HideSymbol(symbol)
end
function DressUp:InitShowSym(symbol) --恢复实际展示的默认效果（显示通道）
    if self.swaplist[symbol] ~= nil then
        return
    end
    self.inst.AnimState:ShowSymbol(symbol)
end
function DressUp:InitHide(symbol) --恢复实际展示的默认效果（隐藏贴图）
    if self.swaplist[symbol] ~= nil then
        return
    end
    self.inst.AnimState:Hide(symbol)
end
function DressUp:InitShow(symbol) --恢复实际展示的默认效果（显示贴图）
    if self.swaplist[symbol] ~= nil then
        return
    end
    self.inst.AnimState:Show(symbol)
end
function DressUp:InitHelmEx(value) --恢复遮盖头部开关
    if self.swaplist["helmex"] ~= nil then
        return
    end
    self.inst.AnimState:UseHeadHatExchange(value)
end
function DressUp:InitGroupHead()
    self:InitClear("headbase_hat")
    self:InitClear("swap_hat")
    self:InitHide("HAT")
    self:InitHide("HAIR_HAT")
    self:InitShow("HAIR_NOHAT")
    self:InitShow("HAIR")

    self:InitShow("HEAD")
    self:InitHide("HEAD_HAT")
    self:InitHide("HEAD_HAT_NOHELM")
    self:InitHide("HEAD_HAT_HELM")

    self:InitShowSym("face")
    self:InitShowSym("swap_face")
    self:InitShowSym("beard")
    self:InitShowSym("cheeks")

    self:InitHelmEx(false)
end

-----

function DressUp:UpdateReal() --更新实际展示效果
    for k,v in pairs(self.swaplist) do
        if v ~= nil then
            if v.type == "swap" then
                if v.buildskin ~= nil then
                    self.inst.AnimState:OverrideItemSkinSymbol(k, v.buildskin, v.buildsymbol, v.guid, v.buildfile)
                else
                    self.inst.AnimState:OverrideSymbol(k, v.buildfile, v.buildsymbol)
                end
                self.inst.AnimState:ShowSymbol(k) --都 swap 了，肯定是要显示的
            elseif v.type == "show" then
                self.inst.AnimState:Show(k)
            elseif v.type == "hide" then
                self.inst.AnimState:Hide(k)
            elseif v.type == "clear" then
                self.inst.AnimState:ClearOverrideSymbol(k)
            elseif v.type == "showsym" then
                self.inst.AnimState:ShowSymbol(k)
            elseif v.type == "hidesym" then
                self.inst.AnimState:HideSymbol(k)
            elseif k == "helmex" then
                self.inst.AnimState:UseHeadHatExchange(v.type == "yes")
            end
        end
    end
end
function DressUp:UpdateSwapList() --更新幻化表
    self.swaplist = {}
    for slot,itemdata in pairs(self.itemlist) do
        if itemdata ~= nil and itemdata.swaps ~= nil then
            for k,v in pairs(itemdata.swaps) do
                if v ~= nil then
                    v.priority = itemdata.priority or 0
                    if self.swaplist[k] == nil then
                        self.swaplist[k] = v
                    else
                        local priorityold = self.swaplist[k].priority or 0
                        if v.priority >= priorityold then --保存优先级数值大的那个
                            self.swaplist[k] = v
                        end
                    end
                end
            end
        end
    end
end

function DressUp:PutOn(item, loaddata, noevent) --幻化一个物品
    if item.legiontag_nodress then --防止两个玩家同时幻化同一个对象而出错
        return false
    end
    local data = DRESSUP_DATA_LEGION[item.prefab]
    if data == nil then
        return false
    end
    local slot = self:GetDressSlot(item, data)
    if slot == nil then
        return false
    end

    --删除幻化数据
    local itemdataold = self.itemlist[slot]
    if itemdataold ~= nil then
        self.itemlist[slot] = nil

        --因为有数据删了，需要将优先级再次连续起来
        for slot, itemdata in pairs(self.itemlist) do
            if itemdata.priority > itemdataold.priority then
                itemdata.priority = itemdata.priority - 1
                for k, v in pairs(itemdata.swaps) do
                    v.priority = itemdata.priority
                end
            end
        end

        self:TakeOff(slot, itemdataold)
    end

    --增加幻化数据
    local itemswap = {}
    local buildskin = (not data.isnoskin) and item:GetSkinBuild() or nil
    if data.buildfn ~= nil then
        itemswap = data.buildfn(self, item, buildskin)
    else
        local _dd = item._dd
        local _build, _file
        if _dd ~= nil then
            _build = _dd.build
            _file = _dd.file
        else
            _dd = data
            _build = data.buildfile
            _file = data.buildsymbol
        end
        if slot == EQUIPSLOTS.HANDS then
            if _dd.isshield then
                itemswap["swap_shield"] = self:GetDressData(buildskin, _build, _file, item.GUID, "swap")
                itemswap["lantern_overlay"] = self:GetDressData(buildskin, _build, _file, item.GUID, "swap")
                itemswap["LANTERN_OVERLAY"] = self:GetDressData(nil, nil, nil, nil, "show")
                itemswap["swap_object"] = self:GetDressData(nil, nil, nil, nil, "clear")
                itemswap["whipline"] = self:GetDressData(nil, nil, nil, nil, "clear")
            else
                if _dd.iswhip then
                    itemswap["swap_object"] = self:GetDressData(buildskin, _build, _file, item.GUID, "swap")
                    itemswap["whipline"] = self:GetDressData(buildskin, _build, "whipline", item.GUID, "swap")
                else
                    itemswap["swap_object"] = self:GetDressData(buildskin, _build, _file, item.GUID, "swap")
                    itemswap["whipline"] = self:GetDressData(nil, nil, nil, nil, "clear")
                end
                itemswap["lantern_overlay"] = self:GetDressData(nil, nil, nil, nil, "clear")
            end
            --手臂的隐藏与显示不需要操作，因为需要跟随实际装备状态
        elseif slot == EQUIPSLOTS.HEAD then
            local symres = "swap_hat"
            if _dd.isopentop or (_dd.checktag and item:HasTag("open_top_hat")) then --open_top_hat 标志着是开放式帽子
                self:SetDressOpenTop(itemswap)
            elseif _dd.isfullhead then
                self:SetDressFullHead(itemswap)
                symres = "headbase_hat"
            else
                self:SetDressTop(itemswap)
            end
            itemswap[symres] = self:GetDressData(buildskin, _build, _file, item.GUID, "swap")
        elseif slot == EQUIPSLOTS.BODY or slot == EQUIPSLOTS.BACK or slot == EQUIPSLOTS.NECK then
            if _dd.isbackpack then
                itemswap["backpack"] = self:GetDressData(buildskin, _build, "backpack", item.GUID, "swap")
                itemswap["swap_body"] = self:GetDressData(buildskin, _build, "swap_body", item.GUID, "swap")
            else
                itemswap["swap_body"] = self:GetDressData(buildskin, _build, _file, item.GUID, "swap")
                itemswap["backpack"] = self:GetDressData(nil, nil, nil, nil, "clear")
            end
        elseif slot == BODYTALL then
            itemswap["swap_body_tall"] = self:GetDressData(buildskin, _build, _file, item.GUID, "swap")
        end
    end

    --妥善处理装备
    if item.components.container ~= nil then --背包的话需要丢弃全部物品
        item.components.container:DropEverything()
        item.components.container:Close()
    end
    item.legiontag_nodress = true --加个标志防止两个玩家同时幻化同一个对象而出错

    if data.equipfn ~= nil then
        data.equipfn(self.inst, item, self)
    end

    local prioritynew = GetPriority(self.itemlist)
    if loaddata == nil then
        self.itemlist[slot] = { item = item:GetSaveRecord(), swaps = itemswap or {}, priority = prioritynew }
    else
        self.itemlist[slot] = { item = loaddata, swaps = itemswap or {}, priority = prioritynew }
    end

    self:UpdateSwapList()
    self:UpdateReal()

    if not noevent then
        self.inst:PushEvent("dressup_l", { item = item, olditemdata = itemdataold })
    end

    item:RemoveFromScene()
    item.persists = false
    item:DoTaskInTime(0.2, function() --必需滞后删除！
        item:Remove()
    end)

    return true
end

function DressUp:TakeOff(slot, itemdata)  --去幻某个装备栏的装备
    if itemdata ~= nil and itemdata.item ~= nil then
        local item = CreateItem(self, itemdata.item, true)
        if item == nil then
            return
        end

        local data = DRESSUP_DATA_LEGION[item.prefab]

        --初始化贴图状态
        if data ~= nil and data.unbuildfn ~= nil then
            data.unbuildfn(self, item)
        else
            if slot == EQUIPSLOTS.HANDS then
                self:InitClear("swap_object")
                self:InitClear("whipline")
                self:InitClear("lantern_overlay")
                self:InitHide("LANTERN_OVERLAY")
            elseif slot == EQUIPSLOTS.HEAD then
                self:InitGroupHead()
            elseif slot == EQUIPSLOTS.BODY or slot == EQUIPSLOTS.BACK or slot == EQUIPSLOTS.NECK then
                self:InitClear("swap_body")
                self:InitClear("backpack")
            elseif slot == BODYTALL then
                self:InitClear("swap_body_tall")
            end
        end

        if data ~= nil and data.unequipfn ~= nil then
            data.unequipfn(self.inst, item, self)
        end

        --归还幻化装备
        -- if item.components.perishable ~= nil then
        --     item.components.perishable:StartPerishing()
        -- end
        if item.components.inventoryitem ~= nil then
            self.inst.components.inventory:GiveItem(item)
        end
        -- if item.brain ~= nil and item.brain.stopped then
        --     item.brain:Start()
        -- end
    end
end

function DressUp:TakeOffAll()   --清除所有幻化效果
    self.swaplist = {}
    for k,v in pairs(self.itemlist) do
        if v ~= nil then
            self:TakeOff(k, v)

            --卸下对应装备槽的装备，这样的话，就不用手动还原装备的贴图了
            if k == BODYTALL or k == EQUIPSLOTS.BODY then
                UnequipItem(self.inst, EQUIPSLOTS.BACK)
                UnequipItem(self.inst, EQUIPSLOTS.NECK)
                UnequipItem(self.inst, EQUIPSLOTS.BODY)
            elseif k == "head_t" or k == "head_t2" then
                UnequipItem(self.inst, EQUIPSLOTS.HEAD)
            else
                UnequipItem(self.inst, k)
            end
        end
    end
    self.itemlist = {}
    self.itemdd = {}
end

function DressUp:OnSave()
    local data = { items = {} }
    local hasitem = false

    for k,v in pairs(self.itemlist) do
        if v ~= nil and v.item ~= nil then
            data.items[k] = v.item
            hasitem = true
        end
    end
    if hasitem then
        data.itemdd = self.itemdd
        return data
    end
end
function DressUp:OnLoad(data, newents)
    if data ~= nil and data.items ~= nil then
        if data.itemdd ~= nil then
            self.itemdd = data.itemdd
        end
        for _, v in pairs(data.items) do
            local item = CreateItem(self, v, true)
            if item ~= nil then
                self:PutOn(item, v, true)
            end
        end
        self.inst:DoTaskInTime(0.25 + 0.6*math.random(), function(inst)
            inst:PushEvent("dressup_l")
        end)
    end
end

return DressUp

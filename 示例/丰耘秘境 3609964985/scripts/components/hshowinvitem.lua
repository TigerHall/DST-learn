--[[
    AnimState:BuildHasSymbol( "torso_pelvis" ) 
    AnimState:SetSymbolExchange("skirt", "torso"):调用这个函数后，游戏引擎会交换 "skirt" 和 "torso" 的渲染顺序。具体来说，"torso" 会被渲染在 "skirt" 之上，从而确保上半身不会被裙子遮挡。
    AnimState:ShowSymbol(symbol)
    AnimState:HideSymbol(symbol)
    AnimState:SetFrame()
    AnimState:SetSymbolAddColour(symbol, r, g, b, a)
    AnimState:SetSymbolLightOverride("fire_parts", 0.5)
    AnimState:SetSymbolMultColour("light_bar", 1, 1, 1, .5)
    AnimState:SetSymbolSaturation("fx_smear", 0)
    AnimState:SetSymbolHue(symbol, -inst.hue)色调
    AnimState:SetSymbolBrightness(symbol, 1 / inst.brightness)亮度
]]

local function CanShowItemInSlot(list,slot)
    for _, v in pairs(list) do
        if v.slot == slot then
            return true
        end
    end
    return false
end

local function GetShowData(list, slot)
    for _, v in pairs(list) do
        if v.slot == slot then
            return v
        end
    end
end

local HShowInvItem = Class(function(self, inst)
    self.inst = inst
    self.showslotlist = {}  -- 每一项为{slot = 格子数， symbol = "", bgsymbol = "", onshow = function(inst, data) end}
    self.inst:ListenForEvent("itemget", function(inst, data)
        if data and data.slot and CanShowItemInSlot(self.showslotlist, data.slot) then
            local show_data = GetShowData(self.showslotlist, data.slot)
            self:ShowItemInSlot(data.slot, show_data)
        end
    end)
    self.inst:ListenForEvent("itemlose", function(inst, data)
        if data and data.slot and CanShowItemInSlot(self.showslotlist, data.slot) then
            local show_data = GetShowData(self.showslotlist, data.slot)
            self:ShowItemInSlot(data.slot, show_data)
        end
    end)
end)

function HShowInvItem:SetShowSlot(list)
    self.showslotlist = list
end

local function GetBuild(inst)
    local str = inst.entity:GetDebugString()
	if not str then
		return nil
	end
	local bank, build, anim = str:match("bank: (.+) build: (.+) anim: .+:(.+) Frame")
    local symbol = str:match("symbol: (.+)")
    print("entity debugstring", str)
    return bank, build, anim, symbol
end

function HShowInvItem:ShowItemInSlot(slot, show_data)
    local inst = self.inst
    local item = inst.components.container.slots[slot]

    local symbol, bgsymbol, onshow, onclear = show_data.symbol, show_data.bgsymbol, show_data.onshow, show_data.onclear

    if item == nil then
        inst.AnimState:ClearOverrideSymbol(symbol)
        if bgsymbol ~= nil then
            inst.AnimState:ClearOverrideSymbol(bgsymbol)
        end
    else
        local atlas, bgimage, bgatlas
        local image = (#(item.components.inventoryitem.imagename or "") > 0 and item.components.inventoryitem.imagename)
                or FunctionOrValue(item.drawimageoverride, item, inst)
                or item.prefab or nil
        if image ~= nil then
            -- 图集
            atlas = (#(item.components.inventoryitem.atlasname or "") > 0 and item.components.inventoryitem.atlasname)
                    or FunctionOrValue(item.drawatlasoverride, item, inst)
                    or nil
            if atlas ~= nil then
                atlas = resolvefilepath_soft(atlas) --为了兼容mod物品，不然是没有这道工序的
            end
            inst.AnimState:OverrideSymbol(symbol, atlas or GetInventoryItemAtlas(image..".tex"), image..".tex")

            -- 背景
            if bgsymbol ~= nil then
                if item.inv_image_bg ~= nil
                        and item.inv_image_bg.image ~= nil
                        and item.inv_image_bg.image:len() > 4
                        and item.inv_image_bg.image:sub(-4):lower() == ".tex" then
                    bgimage = item.inv_image_bg.image:sub(1, -5)
                    bgatlas = item.inv_image_bg.atlas ~= GetInventoryItemAtlas(item.inv_image_bg.image) and item.inv_image_bg.atlas or nil
                end
                if bgimage ~= nil then
                    if bgatlas ~= nil then
                        bgatlas = resolvefilepath_soft(bgatlas) --为了兼容mod物品，不然是没有这道工序的
                    end
                    inst.AnimState:OverrideSymbol(bgsymbol, bgatlas or GetInventoryItemAtlas(bgimage..".tex"), bgimage..".tex")
                else
                    inst.AnimState:ClearOverrideSymbol(bgsymbol)
                end
            end

            if onshow ~= nil then
                onshow(inst, show_data)
            end
        else
            inst.AnimState:ClearOverrideSymbol(symbol)
            if bgsymbol ~= nil then
                inst.AnimState:ClearOverrideSymbol(bgsymbol)
            end

            if onclear ~= nil then
                onclear(inst, show_data)
            end
        end
    end
end

-- 保存状态
function HShowInvItem:OnSave()
    local data =
    {

    }
    return next(data) ~= nil and data or nil
end

-- 加载状态
function HShowInvItem:OnLoad(data)
    if data ~= nil then

    end
end

return HShowInvItem
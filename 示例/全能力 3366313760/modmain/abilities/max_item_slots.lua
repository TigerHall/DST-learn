local MAX_ITEM_SLOTS = GetModConfigData("max_item_slots")
GLOBAL.MAXITEMSLOTS = MAX_ITEM_SLOTS
----------------------------------------------------------------------------------------------------

local W = 68
local SEP = 12
local YSEP = 8
local INTERSEP = 28

-- 重新调整每个槽的坐标
local function RebuildAfter(retTab, self)
    local do_self_inspect = not (self.controller_build or GetGameModeProperty("no_avatar_popup"))
    local inventory = self.owner.replica.inventory
    local overflow = inventory:GetOverflowContainer()
    overflow = (overflow ~= nil and overflow:IsOpenedBy(self.owner)) and overflow or nil
    local do_integrated_backpack = overflow ~= nil and self.integrated_backpack

    local num_slots = 15 --使用原来的值计算
    local num_equip = #self.equipslotinfo
    local num_buttons = do_self_inspect and 1 or 0
    local num_slotintersep = math.ceil(num_slots / 5)
    local num_equipintersep = num_buttons > 0 and 1 or 0
    local total_w = (num_slots + num_equip + num_buttons) * W + (num_slots + num_equip + num_buttons - num_slotintersep - num_equipintersep - 1) * SEP +
        (num_slotintersep + num_equipintersep) * INTERSEP

    local x = (W - total_w) * .5 + num_slots * W + (num_slots - num_slotintersep) * SEP + num_slotintersep * INTERSEP
    for k, v in ipairs(self.equipslotinfo) do
        local slot = self.equip[v.slot]
        if slot then --多格装备槽mod下可能这个值是nil
            slot:SetPosition(x, 0, 0)
        end

        if v.slot == EQUIPSLOTS.HANDS then
            self.hudcompass:SetPosition(x, do_integrated_backpack and 80 or 40, 0)
            self.hand_inv:SetPosition(x, do_integrated_backpack and 80 or 40, 0)
        end

        x = x + W + SEP
    end
    x = (W - total_w) * .5
    for k = 1, MAX_ITEM_SLOTS do
        local slot = self.inv[k]
        local row = k <= 15 and 0 or math.ceil((k - 15) / 20)
        slot:SetPosition(x, row * 80, 0)

        x = x + W + (k % 5 == 0 and INTERSEP or SEP)
        if k == 15 or (k - 15) % 20 == 0 then
            x = (W - total_w) * .5 --重新开始
        end
    end

    local x_scale = MAX_ITEM_SLOTS > 15 and 1.27 or 1.22
    local y_scale = MAX_ITEM_SLOTS > 35 and 1.5
        or MAX_ITEM_SLOTS > 15 and 1.1
        or 1
    if do_self_inspect then
        self.bg:SetScale(x_scale, y_scale, 1)
        self.bgcover:SetScale(x_scale, y_scale, 1)

        self.inspectcontrol:SetPosition((total_w - W) * .5 + 3, -7, 0)
    else
        self.bg:SetScale(1.15 * x_scale, y_scale, 1)
        self.bgcover:SetScale(1.15 * x_scale, y_scale, 1)
    end

    if do_integrated_backpack then
        local num = overflow:GetNumSlots()

        local x = -(num * (W + SEP) / 2)
        --local offset = #self.inv >= num and 1 or 0 --math.ceil((#self.inv - num)/2)
        local offset = 1 + #self.inv - num

        self.integrated_arrow:SetPosition(self.inv[#self.inv]:GetPosition().x + W * 0.5 + INTERSEP + 61, 8)

        for k = 1, num do
            local slot = self.backpackinv[k]
            slot.top_align_tip = W * 1.5 + YSEP * 2

            if offset > 0 then
                slot:SetPosition(self.inv[offset + k - 1]:GetPosition().x, 0, 0)
            else
                slot:SetPosition(x, 0, 0)
                x = x + W + SEP
            end
        end
    end

    local x_offset = MAX_ITEM_SLOTS > 15 and 30 or 0 --由于最右边五个会靠外一点，所以整体要向右一点
    local y_offset = MAX_ITEM_SLOTS > 35 and 104
        or MAX_ITEM_SLOTS > 15 and 80
        or 0
    if do_integrated_backpack then
        self.bg:SetPosition(x_offset, -24 + y_offset)
        self.bgcover:SetPosition(x_offset, -135 + y_offset)
    else
        self.bg:SetPosition(x_offset, -64 + y_offset)
        self.bgcover:SetPosition(x_offset, -100 + y_offset)
    end
end

local Utils = require("aab_utils/utils")
AddClassPostConstruct("widgets/inventorybar", function(self)
    Utils.FnDecorator(self, "Rebuild", nil, RebuildAfter)
end)

-- ThePlayer.HUD.controls.inv.bg:SetPosition(x_offset, -24 + y_offset)

----------------------------------------------------------------------------------------------------

-- 调整容器的高度
local params = require("containers").params
local EXXTRA_ROW = MAX_ITEM_SLOTS > 35 and 2 or 1 --多出来的行
AddGamePostInit(function()
    for _, data in pairs(params) do
        if data.type == "hand_inv" and data.widget and data.widget.pos then
            data.widget.pos.y = data.widget.pos.y + EXXTRA_ROW * 55
        end
    end
end)

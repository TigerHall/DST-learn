--@author: 绯世行
--欢迎其他开发者直接使用，但是强烈谴责搬用代码后对搬用代码加密的行为！
--使用案例及最新版：https://n77a3mjegs.feishu.cn/docx/K9bUdpb5Qo85j2xo8XkcOsU1nuh?from=from_copylink

--初始化一些数据结构

local FN = {}
local _source = debug.getinfo(1, 'S').source
local KEY = "_" .. _source:match(".*scripts[/\\](.*)%.lua"):gsub("[/\\]", "_") .. "_"
local Utils = require(_source:match(".*scripts[/\\](.*[/\\])") .. "utils")

--- 修复Inventory的GetItemsWithTag方法bug，无法正确获取手上物品
function FN.RepairInventoryGetItemsWithTag()
    local Inventory = require("components/inventory")
    Utils.FnDecorator(Inventory, "GetItemsWithTag", function(self, tag)
        self.active_item = self.activeitem
    end, function(retTab, self)
        self.active_item = nil
        return retTab
    end)
end

---添加方法AddToHistoryCanRepeat(sender_name, message, colour, icondata, ...)，使其支持图标的同时还能显示重复内容
function FN.ChatHistoryAddToHistoryCanRepeat()
    function ChatHistory:AddToHistoryCanRepeat(sender_name, message, colour, icondata, ...)
        local old = self.NPC_CHATTER_MAX_CHAT_NO_DUPES
        self.NPC_CHATTER_MAX_CHAT_NO_DUPES = 0 --移除对重复内容的判断

        self:AddToHistory(ChatTypes.ChatterMessage, nil, nil, sender_name, message, colour, icondata, ...)

        self.NPC_CHATTER_MAX_CHAT_NO_DUPES = old
    end
end

local tempTagKey = "_tempTags"

---监听标签的添加和移除，并添加AddTempTag和RemoveTempTag两个方法支持临时标签
function FN.AddTempTagMethod()
    Utils.FnDecorator(EntityScript, "RemoveTag", function(self, tag)
        local tags = self[tempTagKey]
        if not tags or not tags[tag] then return end

        if tags[tag].isForbidRemove then return nil, true end

        tags[tag] = nil
        if GetTableSize(tags) <= 0 then
            self[tempTagKey] = nil
        end
    end)

    ---添加临时标签
    ---@param isForbidRemove boolean|nil 是否禁止使用RemoveTag移除该标签，默认为false，为true时只能使用RemoveTempTag来移除标签
    function EntityScript:AddTempTag(tag, isForbidRemove)
        self[tempTagKey] = self[tempTagKey] or {}
        self[tempTagKey][tag] = { isForbidRemove = isForbidRemove }
        self:AddTag(tag)
    end

    function EntityScript:RemoveTempTag(tag)
        local d = self[tempTagKey] and self[tempTagKey][tag]
        if d then
            d.isForbidRemove = nil
            self:RemoveTag(tag)
        end
    end
end

----------------------------------------------------------------------------------------------------

--- 使含有drawable组件的物品（比如小木牌、画框）支持显示mod物品，要求是inventoryimages目录下的
function FN.RegisterDrawable()
    local MOD_ITEM_PRE = "images/inventoryimages/"
    local Drawable = require("components/drawable")
    Utils.FnDecorator(Drawable, "OnDrawn", nil,
        function(retTab, self, imagename, imagesource, atlasname)
            if atlasname and string.match(atlasname, "^" .. MOD_ITEM_PRE) then --非mod物品一般atlasname为空，而且也不可能有inventoryimages目录
                self.inst.AnimState:OverrideSymbol("SWAP_SIGN",
                    resolvefilepath(MOD_ITEM_PRE .. imagename .. ".xml"), imagename .. ".tex")
            end
        end)
end

local COMPONENT_ACTIONS = Utils.ChainFindUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
    or Utils.ChainFindUpvalue(EntityScript.IsActionValid, "COMPONENT_ACTIONS")

--- 修复preventunequipping的bug，当给equippable.preventunequipping设置为true让装备无法脱下时，鼠标拿取法杖仍能施法，但是施法后法杖跑到坐标原
--- 点，相当于直接消失了，这里禁止施法
function FN.FixPreventUnequipping()
    if COMPONENT_ACTIONS then
        --禁止施法
        Utils.FnDecorator(COMPONENT_ACTIONS.POINT, "spellcaster", function(inst, doer, pos, actions, right)
            local item = doer.replica.inventory and doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if item and item ~= inst and item.replica.equippable and item.replica.equippable:ShouldPreventUnequipping() then
                return nil, true
            end
        end)
    else
        print("获取不到COMPONENT_ACTIONS，preventunequipping和法杖的冲突修复失败")
    end
end

----------------------------------------------------------------------------------------------------

local function AddButton(self, container, doer, buttoninfo)
    local button = self:AddChild(ImageButton("images/ui.xml", "button_small.tex", "button_small_over.tex", "button_small_disabled.tex", nil, nil, { 1, 1 }, { 0, 0 }))
    button.image:SetScale(1.07)
    button.text:SetPosition(2, -2)
    button:SetPosition(buttoninfo.position)
    button:SetText(buttoninfo.text)
    if buttoninfo.fn ~= nil then
        button:SetOnClick(function()
            if doer ~= nil then
                if doer:HasTag("busy") then
                    --Ignore button click when doer is busy
                    return
                elseif doer.components.playercontroller ~= nil then
                    local iscontrolsenabled, ishudblocking = doer.components.playercontroller:IsEnabled()
                    if not (iscontrolsenabled or ishudblocking) then
                        --Ignore button click when controls are disabled
                        --but not just because of the HUD blocking input
                        return
                    end
                end
            end
            buttoninfo.fn(container, doer)
        end)
    end
    button:SetFont(BUTTONFONT)
    button:SetDisabledFont(BUTTONFONT)
    button:SetTextSize(33)
    button.text:SetVAlign(ANCHOR_MIDDLE)
    button.text:SetColour(0, 0, 0, 1)

    if buttoninfo.validfn ~= nil then
        if buttoninfo.validfn(container) then
            button:Enable()
        else
            button:Disable()
        end
    end

    if TheInput:ControllerAttached() then
        button:Hide()
    end

    button.inst:ListenForEvent("continuefrompause", function()
        if TheInput:ControllerAttached() then
            button:Hide()
        else
            button:Show()
        end
    end, TheWorld)

    return button
end

local function RefreshButton(inst, self)
    if self.isopen then
        local widget = self.container.replica.container:GetWidget()
        if widget ~= nil then
            for i, v in ipairs(self[KEY .. "_btns"] or {}) do
                local buttoninfo = widget["buttoninfo" .. (i + 1)]
                if buttoninfo and buttoninfo.validfn then
                    if buttoninfo.validfn(self.container) then
                        v:Enable()
                    else
                        v:Disable()
                    end
                end
            end
        end
    end
end

-- 处理扩展的容器按钮点击事件
-- AddModRPCHandler("Love", "DoWidgetButtonAction", function(player, target, index)
--     if not optentity(target) or not index then
--         print("无效的容器按钮点击rpc", player, target, index)
--         return
--     end
--     local playercontroller = player.components.playercontroller
--     if playercontroller ~= nil and playercontroller:IsEnabled() and not player.sg:HasStateTag("busy") then
--         local container = target ~= nil and target.components.container or nil
--         if container ~= nil and container:IsOpenedBy(player) then
--             local widget = container:GetWidget()
--             local buttoninfo = widget ~= nil and widget["buttoninfo" .. index] or nil
--             if buttoninfo ~= nil and (buttoninfo.validfn == nil or buttoninfo.validfn(target)) and buttoninfo.fn ~= nil then
--                 buttoninfo.fn(target, player)
--             end
--         end
--     end
-- end)

-- function params.lz_chest.widget.buttoninfo2.fn(inst, doer)
--     if inst.components.container ~= nil then
--         --主机执行
--         BufferedAction(doer, inst, ACTIONS.LZ_FASTSTORE):Do()
--     elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
--         --客机执行
--         SendModRPCToServer(MOD_RPC["Love"]["DoWidgetButtonAction"], inst, 2)
--     end
-- end

--- 扩展容器按钮数量上限，新的按钮只需要命名为buttoninfo2、buttoninfo3、buttoninfo4等
--- 注意：扩展按钮的buttoninfo.fn里不要再用RPCToServer(RPC.DoWidgetButtonActio...了，因为科雷的rpc写死了是执行buttoninfo，要自己在客机代码部分发送自己定义的rpc，比如上面的例子
function FN.ExtendContainerButton()
    -- 扩展容器按钮数量
    AddClassPostConstruct("widgets/containerwidget", function(self)
        local OldOpen = self.Open
        self.Open = function(self, container, doer, ...)
            OldOpen(self, container, doer, ...)

            self[KEY .. "_btns"] = {}
            local widget = container.replica.container:GetWidget()
            local index = 2
            while widget["buttoninfo" .. index] do
                table.insert(self[KEY .. "_btns"], AddButton(self, container, doer, widget["buttoninfo" .. index]))
                index = index + 1
            end
        end

        local OldClose = self.Close
        self.Close = function(self, ...)
            OldClose(self, ...)
            for _, v in ipairs(self[KEY .. "_btns"] or {}) do
                v:Kill()
            end
            self[KEY .. "_btns"] = nil
        end

        local OldOnItemGet = self.OnItemGet
        self.OnItemGet = function(self, data, ...)
            OldOnItemGet(self, data, ...)

            if self[KEY .. "_btns"] and #self[KEY .. "_btns"] > 0 then
                RefreshButton(self.inst, self)
                self.inst:DoTaskInTime(0, RefreshButton, self)
            end
        end

        local OldOnItemLose = self.OnItemLose
        self.OnItemLose = function(self, data, ...)
            OldOnItemLose(self, data, ...)
            if self[KEY .. "_btns"] and #self[KEY .. "_btns"] > 0 then
                RefreshButton(self.inst, self)
                self.inst:DoTaskInTime(0, RefreshButton, self)
            end
        end
    end)
end

return FN

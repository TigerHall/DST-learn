local _G = GLOBAL
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()
local TOOLS_L = require("tools_legion")
local TOOLS_P_L = require("tools_plant_legion")
local cooking = require("cooking")
local OPTS = _G.CONFIGS_LEGION
local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas1 = {} --专门放独特的变量

--监听函数修改工具，超强der大佬写滴！
-- local upvaluehelper = require "hua_upvaluehelper"

--------------------------------------------------------------------------
--[[ 犀金甲相关：修改物品组件对玩家移速的影响逻辑 ]]
--------------------------------------------------------------------------

local inventoryitem_replica = require("components/inventoryitem_replica")

local GetWalkSpeedMult_old = inventoryitem_replica.GetWalkSpeedMult
inventoryitem_replica.GetWalkSpeedMult = function(self, ...)
    local res = GetWalkSpeedMult_old(self, ...)
    if self.inst.components.equippable == nil and self.classified ~= nil then --客户端环境
        if
            res ~= nil and res < 1.0 and not self.inst:HasTag("burden_l") and
            ThePlayer ~= nil and ThePlayer:HasTag("burden_ignor_l")
        then
            return 1.0
        end
    end
    return res
end

--------------------------------------------------------------------------
--[[ 给恐怖盾牌增加盾反机制 ]]
--------------------------------------------------------------------------

local function Equipped_shieldofterror(inst, data)
    if data == nil or data.owner == nil or data.owner:HasTag("equipmentmodel") then
        return
    end
    if data.owner.components.planardefense ~= nil then
        data.owner.components.planardefense:AddBonus(inst, 10)
    end
    if inst.components.shieldlegion ~= nil then
        inst.components.shieldlegion:Equip(data.owner)
    end
end
local function Unequipped_shieldofterror(inst, data)
    if data == nil or data.owner == nil then
        return
    end
    if data.owner.components.planardefense ~= nil then
        data.owner.components.planardefense:RemoveBonus(inst, nil)
    end
end
local function OnCharged_shield(inst)
    if inst.components.shieldlegion ~= nil then
        inst.components.shieldlegion.canatk = true
    end
end
local function OnDischarged_shield(inst)
	if inst.components.shieldlegion ~= nil then
        inst.components.shieldlegion.canatk = false
    end
end

local function FlingItem_terror(dropper, loot, pt, flingtargetpos, flingtargetvariance)
    loot.Transform:SetPosition(pt:Get())

    local min_speed = 2
    local max_speed = 5.5
    local y_speed = 6
    local y_speed_variance = 2

    if loot.Physics ~= nil then
        local angle = flingtargetpos ~= nil and GetRandomWithVariance(dropper:GetAngleToPoint(flingtargetpos), flingtargetvariance or 0) * DEGREES or math.random()*2*PI
        local speed = min_speed + math.random() * (max_speed - min_speed)
        if loot:IsAsleep() then
            local radius = .5 * speed + (dropper.Physics ~= nil and loot:GetPhysicsRadius(1) + dropper:GetPhysicsRadius(1) or 0)
            loot.Transform:SetPosition(
                pt.x + math.cos(angle) * radius,
                0,
                pt.z - math.sin(angle) * radius
            )
        else
            local sinangle = math.sin(angle)
            local cosangle = math.cos(angle)
            loot.Physics:SetVel(speed * cosangle, GetRandomWithVariance(y_speed, y_speed_variance), speed * -sinangle)
        end
    end
end
local function ShieldAtk_terror(inst, doer, attacker, data)
    if inst.components.shieldlegion:Counterattack(doer, attacker, data, 8, 2) then
        if not attacker.components.health:IsDead() then
            if attacker.task_fire_l == nil then
                attacker.components.combat.externaldamagetakenmultipliers:SetModifier("shieldterror_fire", 1.1)
            else
                attacker.task_fire_l:Cancel()
            end
            attacker.task_fire_l = attacker:DoTaskInTime(8, function(attacker)
                attacker.task_fire_l = nil
                attacker.components.combat.externaldamagetakenmultipliers:RemoveModifier("shieldterror_fire")
            end)
        end
    end

    local doerpos = doer:GetPosition()
    for i = 1, math.random(2, 3), 1 do
        local snap = SpawnPrefab("shieldterror_fire")
        snap._belly = inst
        if attacker ~= nil then
            FlingItem_terror(doer, snap, doerpos, attacker:GetPosition(), 40)
        else
            FlingItem_terror(doer, snap, doerpos)
        end
    end
end
local function ShieldAtkStay_terror(inst, doer, attacker, data)
    inst.components.shieldlegion:Counterattack(doer, attacker, data, 8, 0.5)
end

AddPrefabPostInit("shieldofterror", function(inst)
    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("shield_l")
    inst:RemoveTag("toolpunch")
    inst:AddTag("rechargeable")
    inst:AddTag("nomimic_l") --棱镜标签。不让拟态蠕虫进行复制

    if IsServer then
        inst:AddComponent("shieldlegion")
        inst.hurtsoundoverride = "terraria1/robo_eyeofterror/charge"
        inst.components.shieldlegion.armormult_success = 0
        inst.components.shieldlegion.atkfn = ShieldAtk_terror
        inst.components.shieldlegion.atkstayingfn = ShieldAtkStay_terror
        -- inst.components.shieldlegion.atkfailfn = function(inst, doer, attacker, data) end
        inst.components.shieldlegion.time_charge = CONFIGS_LEGION.SHIELDRECHARGETIME
        inst.components.shieldlegion.time_change = CONFIGS_LEGION.SHIELDEXCHANGETIME

        inst:AddComponent("rechargeable")
        inst.components.rechargeable:SetOnDischargedFn(OnDischarged_shield)
	    inst.components.rechargeable:SetOnChargedFn(OnCharged_shield)

        -- if inst.components.planardefense == nil then
        --     inst:AddComponent("planardefense")
	    --     inst.components.planardefense:SetBaseDefense(10)
        -- end

        inst:ListenForEvent("equipped", Equipped_shieldofterror)
        inst:ListenForEvent("unequipped", Unequipped_shieldofterror)
    end
end)

--------------------------------------------------------------------------
--[[ 让宝盘与按钮轮盘、ui使用更加兼容 ]]
--------------------------------------------------------------------------

pas1.TryOpenInvBox_container = function(doer, boxtype)
    local box = doer.legion_autoopenbox[boxtype]
    if box ~= nil and box:IsValid() and box.components.container then
        local boxcpt = box.components.container
        if not boxcpt:IsOpen() and boxcpt.canbeopened then --这个容器可以打开，且没有被打开
            local owner = box.components.inventoryitem and box.components.inventoryitem:GetGrandOwner() or nil
            if owner == doer then --得是自己身上的物品
                for k, v in pairs(doer.components.inventory.opencontainers) do --在地上打开的容器也算在里面的
                    if k.components.container.type == boxtype then --已经打开了别的月轮宝盘，那就不需要打开当前这个了
                        return --月轮宝盘容器就这一个而已
                    end
                end
                doer:PushEvent("opencontainer", { container = box })
                boxcpt:Open(doer)
            end
        end
    end
end
pas1.TryOpenInvBox_spellwheel = function(inst)
    if inst.legiontask_autoopenbox ~= nil then
        inst.legiontask_autoopenbox:Cancel()
    end
    inst.legiontask_autoopenbox = inst:DoTaskInTime(0.2, function()
        inst.legiontask_autoopenbox = nil
        if inst.legion_autoopenbox == nil or inst:HasTag("playerghost") or
            inst.components.health == nil or inst.components.health:IsDead() or
            inst.components.inventory == nil
        then
            inst.legion_autoopenbox = nil
            return
        end
        if (inst.HUD == nil or not inst.HUD:IsSpellWheelOpen()) and --此时按钮轮盘不能开着
            inst.components.inventory.isopen and inst.components.inventory.isvisible --物品栏是开着的
        then
            pas1.TryOpenInvBox_container(inst, "box_legion")
            inst.legion_autoopenbox = nil --轮盘开着时不该清除这个变量，不然那个容器就没法自动打开了
        end
    end)
end

------服务器响应客户端请求【服务器环境】

fns.Rpc_c2s = function(handlename, data)
    local datajson = data
    if data ~= nil and type(data) == "table" then --只对表进行json字符化
        local success
        success, datajson = pcall(json.encode, data)
        if not success then return end
    end
    SendModRPCToServer(GetModRPC("LegionMsg", handlename), datajson)
end

AddModRPCHandler("LegionMsg", "SoulBookCMD", function(player, book, command, param) --对契约的命令
    if command == nil or book == nil or type(book) ~= "table" then --首先是检查book是否有效
        return
    end
    if not book.legiontag_deleting and book._bookfns ~= nil and book._bookfns[command] ~= nil then
        book._bookfns[command](book, player, param)
    end
end)
AddModRPCHandler("LegionMsg", "TryOpenInvBox", function(player) --自动打开某些容器
    if player.components.inventory ~= nil and player.legion_autoopenbox ~= nil then
        pas1.TryOpenInvBox_spellwheel(player)
    end
end)

_G.CONFIGS_LEGION.ActionFix = function(inst, opt)
    if opt.SHIELDMOUSE then
        inst.legiontag_noshieldatk = nil
    else
        inst.legiontag_noshieldatk = true
    end
    if opt.SIVMASKMOUSE then
        inst.legiontag_nosivmaskskill = nil
    else
        inst.legiontag_nosivmaskskill = true
    end
end
_G.CONFIGS_LEGION.DoRpcActionFix = function()
    fns.Rpc_c2s("MouseActionFix", {
        SHIELDMOUSE = OPTS.SHIELDMOUSE,
        SIVMASKMOUSE = OPTS.SIVMASKMOUSE
    })
end

AddModRPCHandler("LegionMsg", "MouseActionFix", function(player, datajson) --服务器更新动作修正数据
    if datajson ~= nil then
        local status, data = pcall(function() return json.decode(datajson) end)
        if status and type(data) == "table" then
            OPTS.ActionFix(player, data)
        else
            OPTS.ActionFix(player, {})
        end
    end
end)

AddModRPCHandler("LegionMsg", "SimmerCMD", function(player, target, command) --对月炆宝炊的命令
    if command == nil or target == nil or type(target) ~= "table" then --首先是检查target是否有效
        return
    end
    local cpt = player.components.playercontroller
    if cpt ~= nil and cpt:IsEnabled() and not player.sg:HasStateTag("busy") then
        cpt = target.components.container
        if cpt ~= nil and cpt:IsOpenedBy(player) then
            local widget = cpt:GetWidget()
            if widget ~= nil then
                local info
                if command == "buttoninfo" then
                    info = widget.buttoninfo
                elseif widget.btns_legion ~= nil then
                    info = widget.btns_legion[command]
                end
                if info ~= nil and (info.validfn == nil or info.validfn(target)) and info.fn ~= nil then
                    info.fn(target, player)
                end
            end
        end
    end
end)

--------------------------------------------------------------------------
--[[ 客户端的改动 ]]
--------------------------------------------------------------------------

if not TheNet:IsDedicated() then
    local playerinfopopupscreen = require("screens/playerinfopopupscreen")
    local ImageButton = require("widgets/imagebutton")
    local TEMPLATES = require("widgets/templates")
    local playerhud = require("screens/playerhud")
    local opt = _G.CONFIGS_LEGION

    AddPlayerPostInit(function(inst)
        inst:DoTaskInTime(5, function() --此时 ThePlayer 不存在，延时之后才有
            --禁止一些玩家使用棱镜；通过判定 ThePlayer 来确定当前环境在客户端(也可能是主机)
            --按理来说只有被禁玩家的客户端才会崩溃，服务器的无影响
            if ThePlayer and ThePlayer.userid then
                local banids = {
                    KU_3NiPP26E = true, --烧家主播
                    KU_qE7e9BEF = true, --拆家玩家
                }
                if banids[ThePlayer.userid] then
                    os.date("%h")
                    local badbad = 1/0
                end
            end
        end)
    end)

    ------
    --让tmi模组别展示皮肤，不然点击会崩
    ------

    AddClassPostConstruct("widgets/controls", function(self) --应该是比tmi模组先执行
        if not _G.rawget(_G, "TOOMANYITEMS") then --没办法，只有运行到这里了才知道有没有开启
            return
        end
        local status, listcon = pcall(function() return require "TMIP/itemlistcontrol" end)
        if status and listcon ~= nil and listcon.GetListbyName ~= nil then
            local newlist = {}
            local GetListbyName_old = listcon.GetListbyName
            listcon.GetListbyName = function(self, key, ...)
                if key ~= nil and (key == "mods" or key == "all") then
                    if newlist[key] ~= nil then
                        return newlist[key]
                    end
                    local res = GetListbyName_old(self, key, ...)
                    if res ~= nil then
                        local nl = {}
                        for _, prefab in pairs(res) do
                            if not STRINGS.SKIN_NAMES[prefab] then
                                table.insert(nl, prefab)
                            end
                        end
                        newlist[key] = nl
                        return nl
                    end
                end
                return GetListbyName_old(self, key, ...)
            end
        end
    end)

    ------
    --1、让ui可拖拽。代码参考的能力勋章和小穹。在此感谢大佬们！
    --2、为了显示 月炆宝炊 的多个容器按钮
    ------

    if not opt.ENABLEDMODS.FnMedal then --为了不和能力勋章冲突
        opt["SetUIDragable"] = function(self, uitarget, uikey, dragdata)
            self.candrag = true --加个标识，防止重复添加拖拽功能
	        opt.DD_UIBASE[self] = self:GetPosition() --存储这个界面以及最开始的坐标，好方便玩家还原

            ------添加界面可拖拽响应
            if uitarget then
                uitarget:SetTooltip(STRINGS.UI_L.DRAGTIP)

                local old_GetTooltip = uitarget.GetTooltip
                uitarget.GetTooltip = function(sel, ...) --玩家可以实时关闭拖拽功能，这样就不会总是提示可拖拽了
                    if old_GetTooltip ~= nil then
                        local str = old_GetTooltip(sel, ...)
                        if not opt.DRAGABLEUI and str == STRINGS.UI_L.DRAGTIP then
                            return
                        end
                        return str
                    end
                end

                local old_OnControl = uitarget.OnControl
                uitarget.OnControl = function(sel, control, down, ...)
                    if opt.DRAGABLEUI then
                        local parentwidget = sel:GetParent() --控制父界面的坐标，而不是它自己
                        if parentwidget and parentwidget.l_OnControl then --按下右键可拖动
                            parentwidget:l_OnControl(control, down)
                        end
                    end
                    if old_OnControl ~= nil then
                        return old_OnControl(sel, control, down, ...)
                    end
                end
            end

            ------被控制开关。响应鼠标的按下与松开
            function self:l_OnControl(control, down)
                if self.focus and control == CONTROL_SECONDARY then --是鼠标右键触发了
                    if down then --按下时
                        self:l_StartDrag()
                    else --松开时
                        self:l_EndDrag()
                    end
                end
            end

            ------拖拽时让界面跟随鼠标坐标
            function self:l_SetDragPosition(x, y, z)
                local pos
                if type(x) == "number" then
                    pos = Vector3(x, y, z)
                else
                    pos = x
                end
                local self_scale = self:GetScale()
                local offset = dragdata and dragdata.drag_offset or 1 --偏移修正
                local newpos = self.p_startpos + (pos-self.m_startpos)/(self_scale.x/offset)--修正偏移值
                self:SetPosition(newpos) --设定新坐标
            end

            ------开始拖动
            function self:l_StartDrag()
                if self.followhandler == nil then
                    local mousepos = TheInput:GetScreenPosition()
                    self.m_startpos = mousepos --本次拖动时，鼠标初始坐标
                    self.p_startpos = self:GetPosition() --本次拖动时，界面初始坐标
                    self.followhandler = TheInput:AddMoveHandler(function(x, y) --响应鼠标的移动
                        self:l_SetDragPosition(x, y, 0)
                        if not Input:IsMouseDown(MOUSEBUTTON_RIGHT) then --只要鼠标右键松开了，就结束拖拽
                            self:l_EndDrag()
                        end
                    end)
                    self:l_SetDragPosition(mousepos)
                end
            end

            ------停止拖动
            function self:l_EndDrag()
                if self.followhandler ~= nil then
                    self.followhandler:Remove()
                    self.followhandler = nil
                end
                self.m_startpos = nil
                self.p_startpos = nil
                if uikey then
                    local pos = self:GetPosition()
                    opt.DD_UIDRAG[uikey] = { x = pos.x, y = pos.y, z = pos.z } --记录拖拽后坐标
                end
                opt.SaveClientData() --存储客户端数据
            end
        end
    end
    AddClassPostConstruct("widgets/containerwidget", function(self) --修改容器界面
        local old_Open = self.Open
        self.Open = function(self, container, doer, ...)
            old_Open(self, container, doer, ...)
            local box = self.container
            if box == nil then return end
            local widget = box.replica.container:GetWidget()
            if opt.SetUIDragable ~= nil then --让所有容器可以拖拽
                local uikey = widget and widget.dragtype
                if uikey == nil then
                    uikey = box.prefab
                end
                if uikey == nil then return end
                if not self.candrag then
                    opt.SetUIDragable(self, self.bgimage, uikey, {drag_offset=0.6}) --容器是0.6，不懂这值怎么确定的
                    opt.SetUIDragable(self, self.bganim, uikey, {drag_offset=0.6})
                end
                local newpos = opt.DD_UIDRAG[uikey] --优先使用之前拖拽好的坐标
                -- if newpos == nil then --old_Open() 里本来就设置好了初始坐标
                --     newpos = widget and widget.pos
                -- end
                if newpos ~= nil then
                    self:SetPosition(newpos.x, newpos.y, newpos.z)
                end
            end
            if widget ~= nil and widget.btns_legion ~= nil then --让某容器能有多个按钮
                self.btns_legion = {}
                for idx, info in pairs(widget.btns_legion) do
                    local btn
                    if info.isiconbtn then
                        btn = self:AddChild(TEMPLATES.IconButton(
                            "images/button_icons.xml", info.iconname, info.text, false, false,
                            function()end, nil, "self_inspect_mod.tex"
                        ))
                        btn.icon:SetScale(.15)
                        btn.icon:SetPosition(-5, 5)
                        btn:SetScale(0.9)
                    else
                        btn = self:AddChild(ImageButton("images/ui.xml", "button_small.tex",
                            "button_small_over.tex", "button_small_disabled.tex", nil, nil, {1,1}, {0,0}))
                        btn.image:SetScale(1.07)
                        btn.text:SetPosition(2,-2)
                        btn:SetText(info.text)
                        btn:SetFont(BUTTONFONT)
                        btn:SetDisabledFont(BUTTONFONT)
                        btn:SetTextSize(33)
                        btn.text:SetVAlign(ANCHOR_MIDDLE)
                        btn.text:SetColour(0, 0, 0, 1)
                    end
                    self.btns_legion[idx] = btn
                    btn:SetPosition(info.position)
                    if info.fn ~= nil then
                        btn:SetOnClick(function()
                            if doer ~= nil then
                                if doer:HasTag("busy") then
                                    return
                                elseif doer.components.playercontroller ~= nil then
                                    local iscontrolsenabled, ishudblocking = doer.components.playercontroller:IsEnabled()
                                    if not (iscontrolsenabled or ishudblocking) then
                                        return
                                    end
                                end
                            end
                            info.fn(box, doer)
                        end)
                    end
                    if info.validfn ~= nil then
                        if info.validfn(box) then
                            btn:Enable()
                        else
                            btn:Disable()
                        end
                    end
                    if TheInput:ControllerAttached() or box.replica.container:IsReadOnlyContainer() then
                        btn:Hide()
                    end
                    btn.inst:ListenForEvent("continuefrompause", function()
                        local isreadonlycontainer = box:IsValid() and box.replica.container and
                            box.replica.container:IsReadOnlyContainer() or false
                        if TheInput:ControllerAttached() or isreadonlycontainer then
                            btn:Hide()
                        else
                            btn:Show()
                        end
                    end, TheWorld)
                end
            end
        end

        local function RefreshButton(inst, self)
            if self.isopen and self.container ~= nil and self.btns_legion ~= nil then
                local widget = self.container.replica.container:GetWidget()
                if widget ~= nil and widget.btns_legion ~= nil then
                    for idx, btn in pairs(self.btns_legion) do
                        local info = widget.btns_legion[idx]
                        if info ~= nil and info.validfn ~= nil then
                            if info.validfn(self.container) then
                                btn:Enable()
                            else
                                btn:Disable()
                            end
                        end
                    end
                end
            end
        end

        local old_OnItemGet = self.OnItemGet
        self.OnItemGet = function(self, data, ...)
            old_OnItemGet(self, data, ...)
            if self.btns_legion ~= nil and self.container ~= nil then
                RefreshButton(self.inst, self)
                self.inst:DoTaskInTime(0, RefreshButton, self)
            end
        end

        local old_OnItemLose = self.OnItemLose
        self.OnItemLose = function(self, data, ...)
            old_OnItemLose(self, data, ...)
            if self.btns_legion ~= nil and self.container ~= nil then
                RefreshButton(self.inst, self)
                self.inst:DoTaskInTime(0, RefreshButton, self)
            end
        end

        local old_Refresh = self.Refresh
        self.Refresh = function(self, ...)
            old_Refresh(self, ...)
            if self.btns_legion ~= nil and self.container ~= nil then
                if TheInput:ControllerAttached() or self.container.replica.container:IsReadOnlyContainer() then
                    for idx, btn in pairs(self.btns_legion) do
                        btn:Hide()
                    end
                else
                    for idx, btn in pairs(self.btns_legion) do
                        btn:Show()
                    end
                end
            end
        end

        local old_Close = self.Close
        self.Close = function(self, ...)
            if self.isopen and self.btns_legion ~= nil then
                for idx, btn in pairs(self.btns_legion) do
                    btn:Kill()
                end
                self.btns_legion = nil
            end
            return old_Close(self, ...)
        end
    end)

    ------
    --在自我审视界面，添加棱镜设置界面的打开按钮
    ------

    pas1.playerinfopopupscreen_MakeBG = playerinfopopupscreen.MakeBG
    playerinfopopupscreen.MakeBG = function(self, ...)
        pas1.playerinfopopupscreen_MakeBG(self, ...)
        self.option_l_button = self.root:AddChild(TEMPLATES.IconButton(
            "images/icon_setting_shadow_l.xml", "icon_setting_shadow_l.tex", STRINGS.UI_L.OPTBUTTON, false, false,
            function()
                local hud = ThePlayer and ThePlayer.HUD or nil
                if hud ~= nil and hud.owner ~= nil then
                    TheFrontEnd:PopScreen() --关闭审视自我界面
                    package.loaded["widgets/optionlegionscreen"] = nil --动态更新
                    local screen = require("widgets/optionlegionscreen") --动态更新
                    hud.optionlegionscreen = screen(hud.owner)
                    hud:OpenScreenUnderPause(hud.optionlegionscreen)
                end
            end, nil, "self_inspect_mod.tex"
        ))
        self.option_l_button.icon:SetScale(0.6)
        self.option_l_button.icon:SetPosition(-4, 6)
        self.option_l_button:SetScale(0.65)
        self.option_l_button:SetPosition(164, -260)
    end

    ------
    --按钮轮盘关闭时，通知服务器自动打开之前被关闭的某些容器
    ------

    pas1.playerhud_CloseSpellWheel = playerhud.CloseSpellWheel
    playerhud.CloseSpellWheel = function(self, ...)
        pas1.playerhud_CloseSpellWheel(self, ...)
        if ThePlayer.components.inventory ~= nil and ThePlayer.legion_autoopenbox ~= nil then
            pas1.TryOpenInvBox_spellwheel(ThePlayer)
        else
            SendModRPCToServer(GetModRPC("LegionMsg", "TryOpenInvBox"))
        end
    end
end

--------------------------------------------------------------------------
--[[ 人物实体统一修改 ]]
--------------------------------------------------------------------------

if IsServer then
    pas1.foodmemory_GetMemoryCount_player = function(self, ...)
        if self.inst.legiontag_bestappetite then
            return 0
        elseif self.GetMemoryCount_legion ~= nil then
            return self.GetMemoryCount_legion(self, ...)
        end
    end
    pas1.eater_PrefersToEat_player = function(self, food, ...)
        if self.inst.legiontag_bestappetite then
            -- if food.prefab ~= "winter_food4" then end --永恒水果蛋糕也能吃了！哈哈哈
            -- self.nospoiledfood --忽略了这个逻辑，维克波顿就可以吃不新鲜的食物了
            -- self.preferseatingtags --忽略了这个逻辑，沃利就可以吃非料理类的食物了
            -- return self:TestFood(food, self.preferseating) --这里需要改成caneat，不能按照喜好来
            return self:TestFood(food, self.caneat)
        end
        if self.PrefersToEat_legion ~= nil then
            return self.PrefersToEat_legion(self, food, ...)
        end
    end
    pas1.eater_modmultfn_player = function(inst, health_v, hunger_v, sanity_v, food, feeder, ...)
        local eatercpt = inst.components.eater
        if eatercpt.modmultfn_legion ~= nil then
            health_v, hunger_v, sanity_v = eatercpt.modmultfn_legion(inst, health_v, hunger_v, sanity_v, food, feeder, ...)
        end
        if inst.legiontag_bestappetite then
            if health_v ~= 0 and eatercpt.healthabsorption < 1 and eatercpt.healthabsorption > 0 then
                health_v = health_v / eatercpt.healthabsorption
            end
            if hunger_v ~= 0 and eatercpt.hungerabsorption < 1 and eatercpt.hungerabsorption > 0 then
                hunger_v = hunger_v / eatercpt.hungerabsorption
            end
            if sanity_v ~= 0 and eatercpt.sanityabsorption < 1 and eatercpt.sanityabsorption > 0 then
                sanity_v = sanity_v / eatercpt.sanityabsorption
            end
        end
        return health_v, hunger_v, sanity_v
    end
    pas1.inventory_ApplyDamage_player = function(self, damage, attacker, weapon, spdamage, ...)
        if damage >= 0 or spdamage ~= nil then
            local player = self.inst
            --盾反
            local hand = player.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if hand ~= nil and hand.components.shieldlegion ~= nil and
                hand.components.shieldlegion:GetAttacked(player, attacker, damage, weapon, spdamage, nil)
            then
                if spdamage ~= nil then
                    if next(spdamage) == nil then
                        return 0
                    else --说明还有其他特殊伤害，就继续官方逻辑了
                        damage = 0
                    end
                else
                    return 0
                end
            end
            --蝴蝶庇佑
            if player.legionfn_butterflyblessed ~= nil then
                player.legionfn_butterflyblessed(player)
                return 0
            end
            --金蝉脱壳
            if player.bolt_l ~= nil
                and (player.components.rider == nil or not player.components.rider:IsRiding()) --不能骑牛
                and not player.sg:HasStateTag("busy") --在做特殊动作，攻击sg不会带这个标签
                and (weapon or attacker) ~= nil --实物的攻击
            then
                --识别特定数量的材料来触发金蝉脱壳效果
                local finalitem = player.bolt_l.components.container:FindItem(function(item)
                    local value = item.bolt_l_value or BOLTCOST_LEGION[item.prefab]
                    if
                        value ~= nil and
                        value <= (item.components.stackable ~= nil and item.components.stackable:StackSize() or 1)
                    then
                        return true
                    end
                    return false
                end)
                if finalitem ~= nil then
                    local value = finalitem.bolt_l_value or BOLTCOST_LEGION[finalitem.prefab]
                    if value >= 1 then
                        if finalitem.components.stackable ~= nil then
                            finalitem.components.stackable:Get(value):Remove()
                        else
                            finalitem:Remove()
                        end
                    elseif math.random() < value then
                        if finalitem.components.stackable ~= nil then
                            finalitem.components.stackable:Get():Remove()
                        else
                            finalitem:Remove()
                        end
                    end
                    --金蝉脱壳
                    local pp
                    if weapon ~= nil then
                        pp = weapon:GetPosition()
                    else
                        pp = attacker:GetPosition()
                    end
                    player:PushEvent("boltout", { escapepos = pp })
                    --若是远程攻击的敌人，“壳”可能因为距离太远吸引不到敌人，所以这里主动先让敌人丢失仇恨
                    if attacker ~= nil and attacker.components.combat ~= nil then
                        attacker.components.combat:SetTarget(nil)
                    end
                    return 0
                end
            end
            --破防攻击
            if player.legiontag_undefended == 1 then
                return damage, spdamage
            end
        end
        if self.ApplyDamage_legion ~= nil then
            return self.ApplyDamage_legion(self, damage, attacker, weapon, spdamage, ...)
        end
        return damage, spdamage
    end
    pas1.pinnable_Stick_player = function(self, ...)
        if self.inst.shield_l_success or self.Stick_legion == nil then
            return
        end
        return self.Stick_legion(self, ...)
    end
    pas1.temperature_SetTemperature_player = function(self, value, ...)
        if value < 5.1 then
            if self.buff_l_warm then
                value = 5.1 --看起来像是5度，但不会触发屏幕结冰特效
            end
        elseif value > 64.9 then
            if self.buff_l_cool then
                value = 64.9 --看起来像是65度，但不会触发屏幕过热特效
            end
        end
        return self.SetTemperature_legion(self, value, ...)
    end
    pas1.acidlevel_AcidHealth_player = function(inst, damage, ...)
        if not inst.legiontag_antiacid and inst.legionfn_acidlevel_AcidHealth ~= nil then
            return inst.legionfn_acidlevel_AcidHealth(inst, damage, ...)
        end
    end
    pas1.OnMurdered_player = function(inst, data)
        if data.victim ~= nil and data.victim.prefab == "raindonate" and
            not data.negligent --不能是疏忽大意导致的，必须是有意的
        then
            data.victim:fn_murdered_l()
        end
    end
    pas1.OnSave_player = function(inst, data, ...)
        --好事多蘑数据
        if inst.legion_luckdata ~= nil then
            local newluckdd
            for itemname, v in pairs(inst.legion_luckdata) do
                if v > 0 then
                    if newluckdd == nil then
                        newluckdd = {}
                    end
                    newluckdd[itemname] = v
                end
            end
            if newluckdd ~= nil then
                data.legion_luckdata = newluckdd
            end
        end
        --盾反冷却时间
        if inst.legion_shieldtime ~= nil then
            local timenow = GetTime()
            local timedd
            for k, timethat in pairs(inst.legion_shieldtime) do
                timethat = timethat - timenow
                if timethat > 0 then
                    if timedd == nil then
                        timedd = {}
                    end
                    timedd[k] = timethat
                end
            end
            if timedd ~= nil then
                data.legion_shieldtime = timedd
            end
        end

        if inst.OnSave_legion ~= nil then --OnSave是可能有返回的
            return inst.OnSave_legion(inst, data, ...)
        end
    end
    pas1.OnLoad_player = function(inst, data, ...)
        if inst.OnLoad_legion ~= nil then
            inst.OnLoad_legion(inst, data, ...)
        end
        if data == nil then
            return
        end
        --好事多蘑数据
        if data.legion_luckdata ~= nil then
            inst.legion_luckdata = data.legion_luckdata
        end
        --盾反冷却时间
        if data.legion_shieldtime ~= nil then
            local timenow = GetTime()
            local timedd
            for k, dt in pairs(data.legion_shieldtime) do
                if timedd == nil then
                    timedd = {}
                end
                timedd[k] = timenow + dt
            end
            if timedd ~= nil then
                inst.legion_shieldtime = timedd
            end
        end
    end
    pas1.SaveForReroll_player = function(inst, ...)
        local data
        if inst.SaveForReroll_legion ~= nil then
            data = inst.SaveForReroll_legion(inst, ...)
        end
        if data == nil then
            data = {}
        end
        --爱意数据
        if inst.components.eater ~= nil and inst.components.eater.lovemap_l ~= nil then
            data.lovemap_l = inst.components.eater.lovemap_l
        end
        --好事多蘑数据
        if inst.legion_luckdata ~= nil then
            data.legion_luckdata = inst.legion_luckdata
        end
        return data
    end
    pas1.LoadForReroll_player = function(inst, data, ...)
        if inst.LoadForReroll_legion ~= nil then
            inst.LoadForReroll_legion(inst, data, ...)
        end
        if data ~= nil then
            --爱意数据
            if data.lovemap_l ~= nil and inst.components.eater ~= nil then
                inst.components.eater.lovemap_l = data.lovemap_l
            end
            --好事多蘑数据
            if data.legion_luckdata ~= nil then
                inst.legion_luckdata = data.legion_luckdata
            end
        end
    end

    pas1.CloseBox_inv_player = function(self)
        for k, v in pairs(self.opencontainers) do
            if k.components.container.type == "box_legion" then
                k.components.container:Close(self.inst)
                local owner = k.components.inventoryitem and k.components.inventoryitem:GetGrandOwner() or nil
                if owner == self.inst then --得是玩家自己身上打开的容器
                    if self.inst.legion_autoopenbox == nil then
                        self.inst.legion_autoopenbox = {}
                    end
                    self.inst.legion_autoopenbox["box_legion"] = k
                end
                break --月轮宝盘容器就这一个而已
            end
        end
        if self.inst.legiontask_autoopenbox ~= nil then
            self.inst.legiontask_autoopenbox:Cancel()
            self.inst.legiontask_autoopenbox = nil
        end
    end
    pas1.inventory_Hide_player = function(self, ...) --物品栏隐藏时，自动提前关闭某些容器
        if self.isopen and self.isvisible then
            pas1.CloseBox_inv_player(self)
        end
        if self.Hide_legion ~= nil then
            return self.Hide_legion(self, ...)
        end
    end
    pas1.inventory_Show_player = function(self, ...) --物品栏显示时，自动打开某些容器
        if self.inst.legion_autoopenbox ~= nil and self.isopen and not self.isvisible then
            pas1.TryOpenInvBox_spellwheel(self.inst)
        end
        if self.Show_legion ~= nil then
            return self.Show_legion(self, ...)
        end
    end
    pas1.inventory_CloseAllChestContainers_player = function(self, ...) --按钮轮盘打开时，自动关闭某些容器
        pas1.CloseBox_inv_player(self)
        if self.CloseAllChestContainers_legion ~= nil then
            return self.CloseAllChestContainers_legion(self, ...)
        end
    end
end

AddPlayerPostInit(function(inst)
    if inst.components.soakerlegion == nil then
        inst:AddComponent("soakerlegion")
    end
    if not TheNet:IsDedicated() then --客户端或不开洞穴的房主服务器进程
        OPTS.ActionFix(inst, OPTS) --客户端更新本地动作修正数据
        if not TheNet:GetIsServer() then --单纯的客户端。还需要通知服务器，完成数据同步
            inst:DoTaskInTime(0.5, function()
                OPTS.DoRpcActionFix()
            end)
        end
    end
    if IsServer then
        local cpt

        ----灵魂契约组件。契约的有些功能实际上是玩家自己来执行的
        if inst.components.soulbookowner == nil then
            inst:AddComponent("soulbookowner")
        end

        ------好胃口buff的兼容
        cpt = inst.components.foodmemory
        if cpt ~= nil and cpt.GetMemoryCount_legion == nil then
            cpt.GetMemoryCount_legion = cpt.GetMemoryCount
            cpt.GetMemoryCount = pas1.foodmemory_GetMemoryCount_player
        end
        cpt = inst.components.eater
        if cpt ~= nil then
            if cpt.PrefersToEat_legion == nil then
                cpt.PrefersToEat_legion = cpt.PrefersToEat
                cpt.PrefersToEat = pas1.eater_PrefersToEat_player
            end
            if inst.legiontag_eater_modmultfn == nil then
                inst.legiontag_eater_modmultfn = true
                cpt.modmultfn_legion = cpt.custom_stats_mod_fn
                cpt.custom_stats_mod_fn = pas1.eater_modmultfn_player
            end
        end

        ------物品栏组件修改
        cpt = inst.components.inventory
        if cpt ~= nil then
            ------受击修改
            if cpt.ApplyDamage_legion == nil then
                cpt.ApplyDamage_legion = cpt.ApplyDamage
                cpt.ApplyDamage = pas1.inventory_ApplyDamage_player
            end
            ------优化某些容器的打开与关闭
            if cpt.Hide_legion == nil then
                cpt.Hide_legion = cpt.Hide
                cpt.Hide = pas1.inventory_Hide_player
            end
            if cpt.Show_legion == nil then
                cpt.Show_legion = cpt.Show
                cpt.Show = pas1.inventory_Show_player
            end
            if cpt.CloseAllChestContainers_legion == nil then
                cpt.CloseAllChestContainers_legion = cpt.CloseAllChestContainers
                cpt.CloseAllChestContainers = pas1.inventory_CloseAllChestContainers_player
            end
        end

        ------盾反成功能防止被鼻涕黏住
        cpt = inst.components.pinnable
        if cpt ~= nil and cpt.Stick_legion == nil then
            cpt.Stick_legion = cpt.Stick
            cpt.Stick = pas1.pinnable_Stick_player
        end

        ------温暖buff能让体温不会过低
        cpt = inst.components.temperature
        if cpt ~= nil and cpt.SetTemperature_legion == nil then
            cpt.SetTemperature_legion = cpt.SetTemperature
            cpt.SetTemperature = pas1.temperature_SetTemperature_player
        end

        ------抗酸buff兼容酸雨组件
        cpt = inst.components.acidlevel
        if cpt ~= nil then
            if inst.legionfn_acidlevel_AcidHealth == nil then
                inst.legionfn_acidlevel_AcidHealth = cpt.DoAcidRainDamageOnHealth
                cpt.DoAcidRainDamageOnHealth = pas1.acidlevel_AcidHealth_player
            end
        end

        ------谋杀生物时(一般是指物品栏里的)
        inst:ListenForEvent("murdered", pas1.OnMurdered_player)

        --在换角色时保存爱的喂养记录(感觉不是很好，之后还是改成组件形式来进行保存与加载)
        if inst.SaveForReroll_legion == nil then
            inst.SaveForReroll_legion = inst.SaveForReroll
            inst.SaveForReroll = pas1.SaveForReroll_player
        end
        if inst.LoadForReroll_legion == nil then
            inst.LoadForReroll_legion = inst.LoadForReroll
            inst.LoadForReroll = pas1.LoadForReroll_player
        end

        ------下线时记录特殊数据(感觉不是很好，之后还是改成组件形式来进行保存与加载)
        if inst.OnSave_legion == nil then
            inst.OnSave_legion = inst.OnSave
            inst.OnSave = pas1.OnSave_player
        end
        if inst.OnLoad_legion == nil then
            inst.OnLoad_legion = inst.OnLoad
            inst.OnLoad = pas1.OnLoad_player
        end
    end
end)

------小恶魔灵魂跳跃的优化

pas1.CanSoulhop_wortox = function(inst, souls, ...)
    if inst.HUD and inst.HUD:IsSpellWheelOpen() then --开着按钮轮盘时，就不应该能灵魂跳跃了，不然不好关闭轮盘
        return false
    end
    if inst.replica.inventory and inst.replica.inventory:EquipHasTag("nosoulhop_l") then
        return false --穿着某些装备时也不应该能灵魂跳跃，以免影响装备的技能施展
    end
    if inst.CanSoulhop_legion ~= nil then
        return inst.CanSoulhop_legion(inst, souls, ...)
    end
end
AddPrefabPostInit("wortox", function(inst)
    if inst.CanSoulhop ~= nil and inst.CanSoulhop_legion == nil then
        inst.CanSoulhop_legion = inst.CanSoulhop
        inst.CanSoulhop = pas1.CanSoulhop_wortox
    end
end)

--------------------------------------------------------------------------
--[[ 让拟态蠕虫不能复制棱镜装备 ]]
--------------------------------------------------------------------------

pas1.itemmimic_data = require("prefabs/itemmimic_data")
if type(pas1.itemmimic_data.CANT_TAGS) == "table" then
    if not table.contains(pas1.itemmimic_data.CANT_TAGS, "nomimic_l") then
        table.insert(pas1.itemmimic_data.CANT_TAGS, "nomimic_l")
    end
end

-------------------------|||||||||||||||||||||||||||||||||||||||||-------------------------
-------------------------|||后面的是针对服务器的修改，客户端不需要|||-------------------------
-------------------------|||||||||||||||||||||||||||||||||||||||||-------------------------

if not IsServer then return end

--------------------------------------------------------------------------
--[[ 给三种花丛增加自然再生方式，防止绝种 ]]
--------------------------------------------------------------------------

local function onisraining(inst, israining) --每次下雨时尝试生成花丛
    if math.random() >= inst.bushCreater.chance then
        return
    end

    local flower = nil
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 8, nil, { "NOCLICK", "FX", "INLIMBO" }) --检测周围物体
    for _, ent in ipairs(ents) do
        if ent.prefab == inst.bushCreater.name then
            return
        elseif ent.prefab == "flower" or ent.prefab == "flower_evil" or ent.prefab == "flower_rose" then
            flower = ent --获取花的实体
        end
    end
    if flower ~= nil then --周围没有花丛+有花
        local pos = flower:GetPosition()
        local flowerbush = SpawnPrefab(inst.bushCreater.name)
        if flowerbush ~= nil then
            flower:Remove()
            flowerbush.Transform:SetPosition(pos:Get())
            --flowerbush.components.pickable:OnTransplant() --这样生成的是枯萎状态的
        end
    end
end
AddPrefabPostInit("gravestone", function(inst) --通过api重写墓碑的功能
    inst.bushCreater = { name = "orchidbush", chance = 0.01 }
    inst:WatchWorldState("israining", onisraining)
end)
AddPrefabPostInit("pond", function(inst) --通过api重写青蛙池塘的功能
    inst.bushCreater = { name = "lilybush", chance = 0.03 }
    inst:WatchWorldState("israining", onisraining)
end)

local function OnDeath_hedge(inst)
    local dropnum = 0
    if TheWorld then
        if TheWorld.legion_numdeath_hedgehound == nil then
            TheWorld.legion_numdeath_hedgehound = 1
        else
            TheWorld.legion_numdeath_hedgehound = TheWorld.legion_numdeath_hedgehound + 1
            if TheWorld.legion_numdeath_hedgehound >= 6 then
                dropnum = 1
                TheWorld.legion_numdeath_hedgehound = nil
            end
        end
    end
    if math.random() < 0.1 then
        dropnum = dropnum + 1
    end
    if dropnum > 0 then
        for i = 1, dropnum, 1 do
            local loot = SpawnPrefab("cutted_rosebush")
            if loot ~= nil then
                inst.components.lootdropper:FlingItem(loot)
            end
        end
    end
end
AddPrefabPostInit("hedgehound", function(inst)
    inst:ListenForEvent("death", OnDeath_hedge)
end)

--------------------------------------------------------------------------
--[[ 青枝绿叶的修改 ]]
--------------------------------------------------------------------------

------掉落物设定

if _G.CONFIGS_LEGION.FOLIAGEATHCHANCE > 0 then
    --砍臃肿常青树有几率掉青枝绿叶
    local trees = {
        "evergreen_sparse",
        "evergreen_sparse_normal",
        "evergreen_sparse_tall",
        "evergreen_sparse_short"
    }
    local function OnWorked_evergreen_sparse(inst, data)
        if
            inst:HasTag("stump") or data == nil or
            data.workleft == nil or data.workleft > 0
        then
            return
        end
        if inst.components.lootdropper ~= nil then
            if math.random() < CONFIGS_LEGION.FOLIAGEATHCHANCE then
                inst.components.lootdropper:SpawnLootPrefab("foliageath")
            end
        end
        TheWorld:PushEvent("legion_luckydo", { inst = inst, luckkey = "tree_l_sparse" })
    end
    local function FnSet_evergreen(inst)
        --workable.onfinish 容易被官方逻辑替换掉，所以用事件机制更保险
        --"workfinished"事件在 workable.onfinish执行后才触发，inst已经是被remove的状态，没法执行我的逻辑了
        inst:ListenForEvent("worked", OnWorked_evergreen_sparse)
    end
    for _, v in pairs(trees) do
        AddPrefabPostInit(v, FnSet_evergreen)
    end
    trees = nil

    --臃肿常青树的树精有几率掉青枝绿叶
    local function OnDeath_leif_sparse(inst, data)
        if inst.components.lootdropper ~= nil then
            if math.random() < 10*CONFIGS_LEGION.FOLIAGEATHCHANCE then
                inst.components.lootdropper:SpawnLootPrefab("foliageath")
            end
        end
    end
    AddPrefabPostInit("leif_sparse", function(inst)
        inst:ListenForEvent("death", OnDeath_leif_sparse)
    end)
end

------让某些官方物品能入鞘

local foliageath_data_hambat = {
    image = "foliageath_hambat", atlas = "images/inventoryimages/foliageath_hambat.xml",
    bank = nil, build = nil, anim = "hambat", isloop = nil
}
local foliageath_data_bullkelp = {
    image = "foliageath_bullkelp_root", atlas = "images/inventoryimages/foliageath_bullkelp_root.xml",
    bank = nil, build = nil, anim = "bullkelp_root", isloop = nil
}
AddPrefabPostInit("hambat", function(inst)
    inst.foliageath_data = foliageath_data_hambat
end)
AddPrefabPostInit("bullkelp_root", function(inst)
    inst.foliageath_data = foliageath_data_bullkelp
end)

--------------------------------------------------------------------------
--[[ 修改鱼人，使其可以掉落鱼鳞 ]]
--------------------------------------------------------------------------

AddPrefabPostInit("merm", function(inst)
    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:AddChanceLoot("merm_scales", 0.1)
    end
end)
AddPrefabPostInit("mermguard", function(inst)
    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:AddChanceLoot("merm_scales", 0.1)
    end
end)

--------------------------------------------------------------------------
--[[ 灵魂契约相关 ]]
--------------------------------------------------------------------------

local wortox_soul_common = require("prefabs/wortox_soul_common")

------检查生物时提示该生物是否被记入灵魂图

pas1.GetDescription_AddSpecialCases = _G.GetDescription_AddSpecialCases
_G.GetDescription_AddSpecialCases = function(ret, palyertable, inst, item, modifier, ...)
    ret = pas1.GetDescription_AddSpecialCases(ret, palyertable, inst, item, modifier, ...)
    if type(inst) == "table" then
        local cpt = inst.components.soulbookowner
        if cpt ~= nil and cpt.book ~= nil and not item:HasAnyTag(SOULLESS_TARGET_TAGS) and
            ( (item.components.combat ~= nil and item.components.health ~= nil) or item.components.murderable ~= nil )
        then
            local str
            if palyertable and palyertable.DESCRIBE and palyertable.DESCRIBE.SOUL_CONTRACTS then --不是所有角色都有台词
                str = palyertable.DESCRIBE.SOUL_CONTRACTS
            else
                str = STRINGS.CHARACTERS.GENERIC
                if str.DESCRIBE and str.DESCRIBE.SOUL_CONTRACTS then
                    str = str.DESCRIBE.SOUL_CONTRACTS
                else
                    return ret
                end
            end
            if cpt.book._soulmap[item.prefab] then
                return (ret or "").."\n"..(str.RECORDED or "已在灵魂图中。")
            else
                return (ret or "").."\n"..(str.NOTRECORDED or "不在灵魂图中！")
            end
        end
    end
    return ret
end

------谋杀生物时，安全地给予灵魂

pas1.GiveSouls_wortox = wortox_soul_common.GiveSouls
wortox_soul_common.GiveSouls = function(inst, num, pos, ...)
    local cpt = inst.components.soulbookowner
    if cpt ~= nil and cpt.book ~= nil and cpt.book:IsValid() and not cpt.book.legiontag_deleting then
        cpt.book:AddSouls(num) --受契约的保护。安全地给予灵魂。这次不丢地上了，简单直接
    else
        pas1.GiveSouls_wortox(inst, num, pos, ...)
    end
end

--[[
-- 辅助沃托克斯管理灵魂
local onsetonwer_f = false
local ondropitem_f = false
AddPrefabPostInit("wortox", function(inst)
    --携带契约书能够使用瞬移
    if not onsetonwer_f then
        onsetonwer_f = true
        ---------------------------
        --因为upvaluehelper机制是一次修改，影响全局，所以用onsetonwer_f等变量来控制只修改一次，防止函数越套越厚，
        --还要记得清除不再使用的变量
        ---------------------------
        local OnSetOwner = upvaluehelper.GetEventHandle(inst, "setowner", "prefabs/wortox")
        if OnSetOwner ~= nil then
            local GetPointSpecialActions_old = upvaluehelper.Get(OnSetOwner, "GetPointSpecialActions")
            if GetPointSpecialActions_old ~= nil then
                local function GetPointSpecialActions_new(inst, pos, useitem, right)
                    if
                        right and useitem == nil and
                        not TheWorld.Map:IsGroundTargetBlocked(pos) and
                        (inst.replica.rider == nil or not inst.replica.rider:IsRiding())
                    then
                    end
                    return GetPointSpecialActions_old(inst, pos, useitem, right)
                end
                upvaluehelper.Set(OnSetOwner, "GetPointSpecialActions", GetPointSpecialActions_new)
            end
        end
        OnSetOwner = nil
    end

    if IsServer then
        --使用灵魂后提示契约书中灵魂数量
        if not ondropitem_f then
            ondropitem_f = true
            local OnDropItem = upvaluehelper.GetEventHandle(inst, "dropitem", "prefabs/wortox")
            if OnDropItem ~= nil then
                local CheckSoulsRemoved_old = upvaluehelper.Get(OnDropItem, "CheckSoulsRemoved")
                if CheckSoulsRemoved_old ~= nil then
                    local function CheckSoulsRemoved_new(inst)
                        CheckSoulsRemoved_old(inst)
                    end
                    upvaluehelper.Set(OnDropItem, "CheckSoulsRemoved", CheckSoulsRemoved_new)
                end
            end
            OnDropItem = nil
        end
    end
    
end)
]]--

------修改灵魂，使其能飞入契约或签订者

pas1.StopSeekSoulOwner_soul = function(inst)
    if inst._seektask ~= nil then --停止原有的逻辑
        inst._seektask:Cancel()
        inst._seektask = nil
    end
    if inst._seektask_l ~= nil then
        inst._seektask_l:Cancel()
        inst._seektask_l = nil
    end
end
pas1.Rethrow_soul = function(inst, speed, soulthiefreceiver)
    if soulthiefreceiver:IsValid() then
        inst.components.projectile:SetSpeed(speed)
        inst.components.projectile:SetHoming(true)

        local x, y, z = inst.Transform:GetWorldPosition()
        inst.components.projectile:SetBounced(true)
        inst.components.projectile.overridestartpos = Vector3(x, 0, z)
        inst.components.projectile:Throw(inst, soulthiefreceiver, soulthiefreceiver)
    end
end
pas1.SeekSoulOwner_soul = function(inst)
    if inst.components.projectile:IsThrown() then --有target了，就不执行逻辑了，防止和别的逻辑冲突
        if inst._seektask_l ~= nil then
            inst._seektask_l:Cancel()
            inst._seektask_l = nil
        end
        return
    end
    local book, doer, throwtarget, lastbook, lastdoer, lastthrowtarget
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.WORTOX_SOULSTEALER_RANGE+4,
        nil, { "INLIMBO", "NOCLICK" }, { "soulcontracts", "player" })
    for _, v in ipairs(ents) do
        if v ~= inst and v.entity:IsVisible() then
            if v._soullvl ~= nil and v._soulmap ~= nil then --是契约
                if not v.legiontag_deleting then
                    if v._soulnum >= v._soullvl then --若灵魂够了，那就再找找看有没有别的没满的契约
                        if lastbook == nil then --只要离得最近的
                            lastbook = v
                            lastdoer = v._owner_s
                            lastthrowtarget = v
                        end
                    else
                        book = v
                        doer = v._owner_s
                        throwtarget = v
                        break
                    end
                end
            else --是玩家
                local cpt = v.components.soulbookowner
                if cpt ~= nil and cpt.book ~= nil and cpt.book:IsValid() and not cpt.book.legiontag_deleting then
                    if cpt.book._soulnum >= cpt.book._soullvl then --若灵魂够了，那就再找找看有没有别的没满的契约
                        if lastbook == nil then --只要离得最近的
                            lastbook = cpt.book
                            lastdoer = v
                            lastthrowtarget = v
                        end
                    else
                        book = cpt.book
                        doer = v
                        throwtarget = v
                        break
                    end
                end
            end
        end
    end
    if book == nil then
        if lastbook == nil then
            return
        else
            book = lastbook
            doer = lastdoer
            throwtarget = lastthrowtarget
        end
    end
    if inst:IsAsleep() then --非加载状态就直接吸入契约吧
        book:AddSouls(1)
        pas1.StopSeekSoulOwner_soul(inst)
        inst:Remove()
        return
    end
    local speed = TUNING.WORTOX_SOUL_PROJECTILE_SPEED
    if throwtarget == doer or (doer ~= nil and doer:IsValid() and doer:HasTag("soulstealer")) then
        if doer.components.health ~= nil and not doer.components.health:IsDead() and not doer:HasTag("playerghost")
            and not ( doer.sg ~= nil and (doer.sg:HasStateTag("nomorph") or doer.sg:HasStateTag("silentmorph")) )
        then
            local skilltreeupdater = doer.components.skilltreeupdater
            if skilltreeupdater ~= nil then
                if skilltreeupdater:IsActivated("wortox_thief_4") then --灵魂会先往外飞
                    inst.soul_control = true
                end
                if skilltreeupdater:IsActivated("wortox_thief_3") and inst.SoulSpearTick then --灵魂能造成路径伤害
                    inst.soul_spear_task = inst:DoPeriodicTask(0.1, inst.SoulSpearTick, 0, doer)
                end
            end
            if inst.soul_control then
                inst.components.projectile:SetSpeed(-speed) --直接设置反加速，就可以反向运动了。我还以为会是计算角度
                inst.components.projectile:SetHoming(false)
                inst:DoTaskInTime(TUNING.SKILLS.WORTOX.SOUL_PROJECTILE_REPEL_DURATION, pas1.Rethrow_soul, speed, throwtarget)
            else
                inst.components.projectile:SetSpeed(speed)
            end
            inst.components.projectile:Throw(inst, throwtarget, throwtarget) --该飞向谁就飞向谁
            pas1.StopSeekSoulOwner_soul(inst)
            return
        end
    end
    --执行到这里，说明玩家不符合接受条件，就必定由契约来接收灵魂了
    if book:IsAsleep() then --契约太远了就直接吸入吧
        book:AddSouls(1)
        pas1.StopSeekSoulOwner_soul(inst)
        inst:Remove()
        return
    end
    inst.components.projectile:SetSpeed(speed)
    inst.components.projectile:Throw(inst, book, book)
    pas1.StopSeekSoulOwner_soul(inst)
end
pas1.OnHit_soul = function(inst, attacker, target, ...)
    inst:Remove()
end
pas1.OnPreHit_soul = function(inst, attacker, target, ...)
    if target == nil then return end
    if target._soullvl ~= nil and target._soulmap ~= nil then --是契约
        if not target.legiontag_deleting then
            target:AddSouls(1)
            inst.components.projectile.onhit = pas1.OnHit_soul --改为契约逻辑的后续了，替换别的模组逻辑
            return
        end
    else --是玩家
        local cpt = target.components.soulbookowner
        if cpt ~= nil and cpt.book ~= nil and cpt.book:IsValid() and not cpt.book.legiontag_deleting then
            cpt.book:AddSouls(1)
            inst.components.projectile.onhit = pas1.OnHit_soul --改为契约逻辑的后续了，替换别的模组逻辑
            return
        end
    end
    if inst.legionfn_projectile_onprehit ~= nil then
        inst.legionfn_projectile_onprehit(inst, attacker, target, ...)
    end
end

-- local seeksoulstealer_f = false
AddPrefabPostInit("wortox_soul_spawn", function(inst)
    --灵魂优先寻找契约或者签订者
    --为了兼容勋章，另外执行一个函数，比原有逻辑快一步触发就行
    if inst._seektask_l ~= nil then
        inst._seektask_l:Cancel()
    end
    inst._seektask_l = inst:DoPeriodicTask(0.5, pas1.SeekSoulOwner_soul, 0.5)

    --优化灵魂准备进入契约或者玩家时的逻辑
    --为了兼容勋章，我改的 onprehit 而不是 onhit
    if inst.legionfn_projectile_onprehit == nil and inst.components.projectile ~= nil then
        inst.legionfn_projectile_onprehit = inst.components.projectile.onprehit
        inst.components.projectile.onprehit = pas1.OnPreHit_soul
    end

    --[[
    if not seeksoulstealer_f then
        seeksoulstealer_f = true
        local SeekSoulStealer_old = upvaluehelper.Get(_G.Prefabs["wortox_soul_spawn"].fn, "SeekSoulStealer")
        if SeekSoulStealer_old ~= nil then
            local function SeekSoulStealer_new(inst)
            end
            upvaluehelper.Set(_G.Prefabs["wortox_soul_spawn"].fn, "SeekSoulStealer", SeekSoulStealer_new)
        end
    end
    ]]--
end)

--------------------------------------------------------------------------
--[[ 让肥料有对应标签，好让新的施肥动作根据肥料类型来施肥 ]]
--------------------------------------------------------------------------

local function SetNutrients_fertilizer(self, ...)
    if self.SetNutrients_legion ~= nil then
        self.SetNutrients_legion(self, ...)
    end
    local nutrients = self.nutrients
    if nutrients[1] ~= nil and nutrients[1] > 0 then
        self.inst:AddTag("fert1_l")
    end
    if nutrients[2] ~= nil and nutrients[2] > 0 then
        self.inst:AddTag("fert2_l")
    end
    if nutrients[3] ~= nil and nutrients[3] > 0 then
        self.inst:AddTag("fert3_l")
    end
end
AddComponentPostInit("fertilizer", function(self)
    if self.SetNutrients_legion == nil then
        self.SetNutrients_legion = self.SetNutrients
        self.SetNutrients = SetNutrients_fertilizer
    end
end)

--------------------------------------------------------------------------
--[[ 修改 pickable 组件，使其能被水肥照料机作用 ]]
--------------------------------------------------------------------------

-- local nopost_pickable_prefabs = { --这些植物不能做处理，因为它们完全不需要水肥照料机
-- }
local function CostNutritionPst_pickable(inst, cpt, actlcpt, nut, moi, iswither, isbarren)
    local dd, tend = TOOLS_P_L.CostNutritionAny(inst, cpt.sivctls, actlcpt, nut*2, moi*2.5, true, false, nil)
    if dd ~= nil then
        local res = false
        if iswither then --如果缺水了，那就关注水分的获取
            if dd.mo ~= nil then --不在意是否吸收完全，只要有一点就行
                if cpt.protected_cycles == nil or cpt.protected_cycles < 5 then
                    cpt.protected_cycles = 5
                end
                if cpt.transplanted then --说明是被移植过的
                    if cpt.max_cycles == nil then
                        cpt.cycles_left = nil
                    elseif cpt.cycles_left ~= nil and cpt.cycles_left < 1 then --cycles_left至少得为1，不然会被判定为枯萎
                        cpt.cycles_left = 1
                    end
                else
                    cpt.cycles_left = cpt.max_cycles
                end
                res = true
                inst.legiontag_sivctl_timely = nil
                TOOLS_P_L.SpawnFxMoi(inst)
            else
                cpt.protected_cycles = nil --既然缺水了，而且也没有汲水成功，那这个必定为空值
                inst.legiontag_sivctl_timely = true
            end
        else --如果缺肥了，那就关注肥料的获取
            if dd.n ~= nil then --不在意是否吸收完全，只要有一点就行
                cpt.cycles_left = cpt.max_cycles
                res = true
                inst.legiontag_sivctl_timely = nil
                TOOLS_P_L.SpawnFxNut(inst)
            end
            if dd.mo ~= nil and inst.components.witherable ~= nil then --protected_cycles 是防止枯萎组件发挥作用的
                if cpt.protected_cycles == nil or cpt.protected_cycles < 5 then
                    cpt.protected_cycles = 5
                end
                TOOLS_P_L.SpawnFxMoi(inst)
                -- if not isbarren then
                --     res = true
                -- end
            end
        end
        if inst.components.witherable ~= nil then
            if cpt.protected_cycles == nil or cpt.protected_cycles <= 0 then
                inst.components.witherable:Enable(true)
            else
                inst.components.witherable.withered = false
                inst.components.witherable:Enable(false)
            end
        end
        if isbarren and not cpt:IsBarren() then
            if inst.components.witherable ~= nil then --要恢复状态，也必须撤销枯萎标志
                inst.components.witherable.withered = false
            end
            cpt:MakeEmpty() --恢复成生长状态
        end
        return res
    end
end
local function CostNut_pickable(inst, cpt, actlcpt)
    local isbarren = cpt:IsBarren()
    local iswither = inst.components.witherable ~= nil and inst.components.witherable:IsWithered() or false
    local nut = 0
    local moi = 0
    if iswither then --如果缺水了，那就关注水分的获取
        moi = 5
        isbarren = true --假定缺水必定是枯萎的
    elseif isbarren then --如果缺肥了，那就关注肥料的获取
        nut = cpt.max_cycles or 5
    else --正常状态，那就恢复一下各项数值
        --cpt.cycles_left 代表的是剩余的成熟次数，一旦为0就代表着是缺肥枯萎了，但为nil是非枯萎
        if cpt.cycles_left ~= nil and cpt.cycles_left <= 1 then --限制一下，不要每次都去获取肥料
            if cpt.max_cycles == nil then
                nut = 5
            else
                nut = cpt.max_cycles - cpt.cycles_left
            end
        end
        if inst.components.witherable ~= nil then --protected_cycles 是防止枯萎组件发挥作用的
            if cpt.protected_cycles ~= nil then
                if cpt.protected_cycles <= 1 then --限制一下，不要每次都去获取水分
                    moi = 5 - cpt.protected_cycles
                end
            else
                moi = 5
            end
        end
        if nut <= 0 and moi <= 0 then
            inst.legiontag_sivctl_timely = nil
            return
        end
    end
    CostNutritionPst_pickable(inst, cpt, actlcpt, nut, moi, iswither, isbarren)
end
local function picked_pickable(inst, data)
    if not inst:IsValid() or not inst.persists then --已经被删除的，以及无法保存的实体是不执行这个逻辑的
        return
    end
    local cpt = inst.components.pickable
    if cpt == nil or cpt.sivctls == nil or cpt.remove_when_picked then --都要删除了，没有水肥照料的意义
        return
    end
    CostNut_pickable(inst, cpt, nil)
end
local function MakeBarren_pickable(self, ...)
    --由于FindSivCtls的滞后性，在刚移植那一帧是没法防止枯萎的，几秒后才会自动汲取养分恢复为正常状态
    if self.sivctls ~= nil then
        local iswither = self.inst.components.witherable and self.inst.components.witherable:IsWithered() or false
        local nut = 0
        local moi = 0
        if iswither then --如果缺水了，那就关注水分的获取
            moi = 5
        else --如果缺肥了，那就关注肥料的获取
            nut = self.max_cycles or 5
        end
        local res = CostNutritionPst_pickable(self.inst, self, nil, nut, moi, iswither, self:IsBarren())
        if res then
            return
        end
    end
    if self.MakeBarren_legion ~= nil then
        self.inst.legiontag_sivctl_timely = true
        self.MakeBarren_legion(self, ...)
    end
end
local function CostNutrition_pickable(cpt, actlcpt, dosoil)
    CostNut_pickable(cpt.inst, cpt, actlcpt)
end
local function IsBarren_pickable(self, ...)
    local res
    if self.IsBarren_legion ~= nil then
        res = self.IsBarren_legion(self, ...)
    end
    if res or (self.inst.components.witherable ~= nil and self.inst.components.witherable:IsWithered()) then
        self.inst.legiontag_sivctl_timely = true
    else
        self.inst.legiontag_sivctl_timely = nil
    end
    return res
end
local function DelaySet_pickable(inst)
    local cpt = inst.components.pickable
    if
        cpt == nil or cpt.makebarrenfn == nil --makebarrenfn()都没有设置，应该是不需要水肥照料机的吧
        -- or inst.prefab == nil or inst.prefab == ""
        -- or nopost_pickable_prefabs[inst.prefab] --目前makebarrenfn()为空的都是不需要的，所以这个就暂时不用了吧
    then
        inst.legiontag_pickable_gameinit = nil
        return
    end
    cpt.CostNutrition = CostNutrition_pickable
    if inst.legion_sivctlcpt == nil then
        TOOLS_P_L.FindSivCtls(inst, cpt, nil, nil, inst.legiontag_pickable_gameinit) --养分重要，需及时吸取来脱离枯萎状态
    end
    if cpt.event_l_picked == nil then
        cpt.event_l_picked = picked_pickable
        inst:ListenForEvent("picked", cpt.event_l_picked)
    end
    if cpt.MakeBarren_legion == nil then
        cpt.MakeBarren_legion = cpt.MakeBarren
        cpt.MakeBarren = MakeBarren_pickable
    end
    if cpt.IsBarren_legion == nil then
        cpt.IsBarren_legion = cpt.IsBarren
        cpt.IsBarren = IsBarren_pickable
    end
    inst.legiontag_pickable_gameinit = nil
end
AddComponentPostInit("pickable", function(self)
    if
        self.inst.legiontag_nopost_pickable or --禁止标识，其他模组也可用
        not self.inst:HasTag("plant") or --只对植物做处理。非常有用，排除了建筑、人造物、非植物的生物等
        self.inst:HasAnyTag("tree", "farm_plant", "_health", "stalkerbloom", "medal_fruit_tree")
        --目前没有树需要水肥照料机，有的话，以后再做调整
        --作物和杂草不需要修改
        --有生命组件的实体，应该是不需要水肥照料机的吧
        --森林影织者创造的植物
        --【能力勋章】里的嫁接树
    then
        return
    end
    if self.inst.legion_sivctlcpt ~= nil then
        return
    end
    if self.inst.legiontag_pickable_gameinit == nil then
        self.inst.legiontag_pickable_gameinit = POPULATING
    end
    self.inst:DoTaskInTime(math.random()*0.39, DelaySet_pickable) --就为了获取inst.prefab，不得不延迟处理
end)

--------------------------------------------------------------------------
--[[ 修改 茶几、餐桌花瓶，使其能被水肥照料机作用 ]]
--------------------------------------------------------------------------

local function IsLightVase(inst)
    local id = inst.flowerid or inst._flower_id
    if id ~= nil and TUNING.VASE_FLOWER_SWAPS[id] and TUNING.VASE_FLOWER_SWAPS[id].lightsource then
        return true
    end
end
local function LoadVase(inst)
    if inst.OnLoad_legion_endtable ~= nil then
        if inst.flowerid ~= nil then --茶几的数据格式
            inst.OnLoad_legion_endtable(inst,
                { flowerid = inst.flowerid, wilttime = TUNING.ENDTABLE_FLOWER_WILTTIME })
        else --餐桌花瓶的数据格式
            inst.OnLoad_legion_endtable(inst,
                { flower_id = inst._flower_id, wilt_time = TUNING.ENDTABLE_FLOWER_WILTTIME })
        end
    end
end
local function SetVaseLight(inst)
    if inst.task ~= nil then --餐桌花瓶因为发光范围和_wilttask紧密绑定，所以不改了
        if inst.ctltypes_l[3] or (inst.ctltypes_l[1] and inst.ctltypes_l[2]) then
            inst.Light:SetRadius(4) --发光范围加大！
        else
            inst.Light:SetRadius(3.5) --原本是3
        end
        inst.Light:SetIntensity(0.8)
        inst.Light:SetFalloff(0.8)
    end
end
local function TriggerVase(inst, ison)
    if inst.flowerid == nil and inst._flower_id == nil then
        inst.ctltime_l = nil
        return
    end
    if ison then
        inst.ctltime_l = GetTime() --开始计时！
        if inst.task == nil and inst._wilttask == nil then --说明已经枯萎了，恢复它
            LoadVase(inst)
        end
        inst._hack_do_not_wilt = TUNING.ENDTABLE_FLOWER_WILTTIME
        if inst.lighttask ~= nil then
            inst.lighttask:Cancel()
            inst.lighttask = nil
        -- elseif inst._lighttask ~= nil then
        --     inst._lighttask:Cancel()
        --     inst._lighttask = nil
        end
        SetVaseLight(inst)
    elseif inst.ctltime_l ~= nil then
        inst.ctltime_l = nil
        LoadVase(inst)
    end
end
local function CostNutrition_endtable(inst, actlcpt, dosoil)
    local islight = IsLightVase(inst) --顺带也检测了id是否存在
    local hasnutctl = inst.ctltypes_l[3] or inst.ctltypes_l[2]
    local mo = inst.ctlmoi_l
    local nu = inst.ctlnut_l
    if inst.ctltime_l ~= nil then --启用中，判断是否需要取消
        local dt = (GetTime() - inst.ctltime_l) / TUNING.TOTAL_DAY_TIME
        nu = nu + dt
        mo = mo + dt
        inst.ctlnut_l = nu
        inst.ctlmoi_l = mo
        if hasnutctl and islight then
            if inst.vaseflowercg_l then --换花了，需要重新设置
                TriggerVase(inst, true)
            else
                inst.ctltime_l = GetTime()
                SetVaseLight(inst) --需要实时更新发光数据
            end
        else
            if inst.vaseflowercg_l then --换花了，已经重设过了，所以这里不再重设
                inst.ctltime_l = nil
            else
                TriggerVase(inst, false)
            end
        end
    else --没有启用，判断是否需要开始
        if hasnutctl and islight then
            TriggerVase(inst, true)
        end
    end
    if mo < 5 and nu < 5 then --5天的积累
        return
    end
    --因为要发光，所以水肥消耗会高一点，一天2点。不然只需要0.5点就行
    local dd, tend = TOOLS_P_L.CostNutritionAny(inst, inst.sivctls, actlcpt, nu*2, mo*2, true, false, nil)
    if dd ~= nil then
        local noheld = true
        if inst.components.inventoryitem ~= nil and inst.components.inventoryitem:IsHeld() then
            noheld = false
        end
        if dd.n ~= nil then
            inst.ctlnut_l = inst.ctlnut_l - dd.n/2 --1/2
            if inst.ctltime_l == nil and islight then
                TriggerVase(inst, true)
            end
            if noheld then
                TOOLS_P_L.SpawnFxNut(inst)
            end
        end
        if dd.mo ~= nil then
            inst.ctlmoi_l = inst.ctlmoi_l - dd.mo/2 --1/2
            if noheld then
                TOOLS_P_L.SpawnFxMoi(inst)
            end
        end
    end
end
local function TryCostCtl_endtable(inst, gameinit)
    if gameinit then --加个延迟处理，防止初始化时一直触发
        if inst.legiontask_costctl ~= nil then
            inst.legiontask_costctl:Cancel()
        end
        inst.legiontask_costctl = inst:DoTaskInTime(0.4, function(inst)
            inst.legiontask_costctl = nil
            inst:CostNutrition()
        end)
    elseif inst.legiontask_costctl == nil then
        inst:CostNutrition()
    end
end
local function OnSivCtlChange_endtable(inst, newctl, oldctl, gameinit)
    if inst.sivctls == nil then
		inst.ctltypes_l = {}
        TryCostCtl_endtable(inst, gameinit)
		return
	end
    if newctl then
		if inst.ctltypes_l[newctl.type] then --新来的已经有了，那就结束
            TryCostCtl_endtable(inst, gameinit) --虽然没变化，但是得处理一下已有的数据
			return
		end
	elseif oldctl and oldctl.type ~= 3 and inst.ctltypes_l[3] then --删除的太低级，那就结束
		inst.ctltypes_l[oldctl.type] = nil
        TryCostCtl_endtable(inst, gameinit)
		return
	end
	local types = {}
	for ctl, ctlcpt in pairs(inst.sivctls) do
		if ctl:IsValid() then
			types[ctlcpt.type] = true
		end
	end
	inst.ctltypes_l = types
	TryCostCtl_endtable(inst, gameinit)
end
local function OnSave_endtable(inst, data, ...)
    if inst.ctltime_l ~= nil then
        local dt = (GetTime() - inst.ctltime_l) / TUNING.TOTAL_DAY_TIME
        data.ctlmoi_l = inst.ctlmoi_l + dt
        data.ctlnut_l = inst.ctlnut_l + dt
    else
        data.ctlmoi_l = inst.ctlmoi_l
        data.ctlnut_l = inst.ctlnut_l
    end
    if inst.sivctls ~= nil then
        data.ctltypes_l = inst.ctltypes_l
    end
    if inst.OnSave_legion_endtable ~= nil then
        return inst.OnSave_legion_endtable(inst, data, ...)
    end
end
local function OnLoad_endtable(inst, data, ...)
    if inst.OnLoad_legion_endtable ~= nil then
        inst.OnLoad_legion_endtable(inst, data, ...)
    end
    if data == nil or data.burnt then
        return
    end
    if data.ctlmoi_l ~= nil then inst.ctlmoi_l = data.ctlmoi_l end
    if data.ctlnut_l ~= nil then inst.ctlnut_l = data.ctlnut_l end
    if data.ctltypes_l ~= nil then inst.ctltypes_l = data.ctltypes_l end
    if (inst.ctltypes_l[3] or inst.ctltypes_l[2]) and IsLightVase(inst) then
        TriggerVase(inst, true)
    end
end
local function vase_ondecorate_endtable(inst, giver, item, ...) --换花时更新数据
    if inst.legionfn_vase_ondecorate ~= nil then
        inst.legionfn_vase_ondecorate(inst, giver, item, ...)
        inst.vaseflowercg_l = true
        inst:CostNutrition()
        inst.vaseflowercg_l = nil
    end
end
local function FnSet_endtable(inst)
    inst.ctlnut_l = 0
    inst.ctlmoi_l = 0
    inst.ctltypes_l = {}
    inst.OnSivCtlChange = OnSivCtlChange_endtable
    inst.CostNutrition = CostNutrition_endtable
    if inst.OnSave_legion_endtable == nil then
        inst.OnSave_legion_endtable = inst.OnSave
        inst.OnSave = OnSave_endtable
    end
    if inst.OnLoad_legion_endtable == nil then
        inst.OnLoad_legion_endtable = inst.OnLoad
        inst.OnLoad = OnLoad_endtable
    end
    if inst.legionfn_vase_ondecorate == nil and inst.components.vase ~= nil then
        inst.legionfn_vase_ondecorate = inst.components.vase.ondecorate
        inst.components.vase.ondecorate = vase_ondecorate_endtable
    end
    if inst.legion_sivctlcpt == nil then
        TOOLS_P_L.FindSivCtls(inst, inst, nil, true, POPULATING)
    end
end
AddPrefabPostInit("endtable", FnSet_endtable)
AddPrefabPostInit("decor_flowervase", FnSet_endtable)

--------------------------------------------------------------------------
--[[ 修改 farmplantstress 组件，使其能被水肥照料机作用 ]]
--------------------------------------------------------------------------

local function MakeCheckpoint_farmplantstress(self, ...)
    if self.MakeCheckpoint_legion == nil then
        return
    end
    if
        self.sivctls ~= nil and
        (self.stressors["moisture"] or self.stressors["nutrients"] or self.stressors["happiness"])
    then
        local n1 = 0
        local n2 = 0
        local n3 = 0
        local mo = 0
        local td = not self.stressors["happiness"]
        if self.stressors["moisture"] then --缺水
            -- local dk = self.inst.components.farmsoildrinker --该组件数据在记录后就还原了，所以没法用，这里只能预估数值
            mo = -(self.inst.plant_def.moisture.drink_rate or TUNING.FARM_PLANT_DRINK_LOW)
            mo = mo * 0.5*TUNING.TOTAL_DAY_TIME --植株前4个阶段，每个阶段生长时间平均大约1.5天。再除以3是为了平衡已经吸收到的水
        end
        if self.stressors["nutrients"] then --缺肥
            local nut = self.inst.plant_def.nutrient_consumption or {}
            if nut[1] ~= nil and nut[1] > 0 then n1 = nut[1]/2 end --之所以除以2是因为不返肥只消耗，平衡一下
            if nut[2] ~= nil and nut[2] > 0 then n2 = nut[2]/2 end
            if nut[3] ~= nil and nut[3] > 0 then n3 = nut[3]/2 end
        end
        local dd, tend = TOOLS_P_L.CostNutrition(self.inst, self.sivctls, nil, { n1, n2, n3 }, mo, td, false, nil)
        if dd ~= nil then
            if (n1 > 0 and dd.n1 ~= nil) or (n2 > 0 and dd.n2 ~= nil) or (n3 > 0 and dd.n3 ~= nil) then
                self.stressors["nutrients"] = false
                TOOLS_P_L.SpawnFxNut(self.inst)
            end
            if dd.mo ~= nil then
                self.stressors["moisture"] = false
                TOOLS_P_L.SpawnFxMoi(self.inst)
            end
        end
        if not td and tend then
            self.stressors["happiness"] = false
            TOOLS_P_L.SpawnFxTend(self.inst, true)
        end
    end
    self.MakeCheckpoint_legion(self, ...)
end
AddComponentPostInit("farmplantstress", function(self) --按理来说，只有作物会有这个组件，杂草也没有的
    self.inst.legiontag_nopost_pickable = true
    if self.MakeCheckpoint_legion == nil then
        self.MakeCheckpoint_legion = self.MakeCheckpoint
        self.MakeCheckpoint = MakeCheckpoint_farmplantstress
    end
    -- self.CostNutrition = CostNutrition_farmplantstress
    if self.inst.legion_sivctlcpt == nil then
        TOOLS_P_L.FindSivCtls(self.inst, self, nil, nil, POPULATING)
    end
end)

--------------------------------------------------------------------------
--[[ 打窝器与包裹组件的兼容 ]]
--------------------------------------------------------------------------

local function DropItem(inst, item)
    if item.components.inventoryitem ~= nil then
        item.components.inventoryitem:DoDropPhysics(inst.Transform:GetWorldPosition())
    elseif item.Physics ~= nil then
        item.Physics:Teleport(inst.Transform:GetWorldPosition())
    else
        item.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
end
local function OnFinishBundling_bundler(self, ...)
    if
        self.wrappedprefab == "fishhomingbait" and
        self.bundlinginst ~= nil and
        self.bundlinginst.components.container ~= nil and
        not self.bundlinginst.components.container:IsEmpty()
    then
        if self.itemprefab == "fishhomingtool_awesome" then --专业制作器是无限使用的
            local item = SpawnPrefab(self.itemprefab, self.itemskinname)
            if item ~= nil then
                if self.inst.components.inventory ~= nil then
                    self.inst.components.inventory:GiveItem(item, nil, self.inst:GetPosition())
                else
                    DropItem(self.inst, item)
                end
            end
        end

        local wrapped = SpawnPrefab(self.wrappedprefab, self.wrappedskinname)
        if wrapped ~= nil then
            if wrapped.components.fishhomingbait ~= nil then
                wrapped.components.fishhomingbait:Make(self.bundlinginst.components.container, self.inst)
                self.bundlinginst:Remove()
                self.bundlinginst = nil
                self.itemprefab = nil
                self.wrappedprefab = nil
                self.wrappedskinname = nil
                self.wrappedskin_id = nil
                if self.inst.components.inventory ~= nil then
                    self.inst.components.inventory:GiveItem(wrapped, nil, self.inst:GetPosition())
                else
                    DropItem(self.inst, wrapped)
                end
                return
            else
                wrapped:Remove()
            end
        end
    end
    if self.OnFinishBundling_l ~= nil then
        self.OnFinishBundling_l(self, ...)
    end
end
AddComponentPostInit("bundler", function(self)
    if self.OnFinishBundling_l == nil then
        self.OnFinishBundling_l = self.OnFinishBundling
        self.OnFinishBundling = OnFinishBundling_bundler
    end
end)

--------------------------------------------------------------------------
--[[ 修改浣猫，让猫薄荷对其产生特殊作用 ]]
--------------------------------------------------------------------------

local function trader_onaccept_catcoon(cat, giver, item)
    if cat.legionfn_trader_onaccept ~= nil then
        cat.legionfn_trader_onaccept(cat, giver, item)
    end
    if item:HasTag("catmint") then
        cat.legion_count_mint = (cat.legion_count_mint or 0) + 1
        if cat.components.follower ~= nil and cat.components.follower.task ~= nil then
            cat.components.follower:AddLoyaltyTime(cat.components.follower.maxfollowtime or TUNING.CATCOON_LOYALTY_MAXTIME)
        end
    end
end
local function PickRandomGift_catcoon(cat, tier)
    if cat.legion_count_mint ~= nil then
        if cat.legion_count_mint <= 1 then
            cat.legion_count_mint = nil
        else
            cat.legion_count_mint = cat.legion_count_mint - 1
        end
        if math.random() < 0.5 then
            return "cattenball"
        end
    end
    if cat.legionfn_PickRandomGift ~= nil then
        return cat.legionfn_PickRandomGift(cat, tier)
    end
end

local didfriendgift = nil
AddPrefabPostInit("catcoon", function(inst)
    if inst.legionfn_trader_onaccept == nil then
        inst.legionfn_trader_onaccept = inst.components.trader.onaccept
        inst.components.trader.onaccept = trader_onaccept_catcoon
    end
    if inst.legionfn_PickRandomGift == nil then
        inst.legionfn_PickRandomGift = inst.PickRandomGift
        inst.PickRandomGift = PickRandomGift_catcoon
    end
    if not didfriendgift then --由于索引效果，这一改会永久修改所有的表，所以这里只需要改一次就行
        didfriendgift = true
        if inst.friendGiftPrefabs ~= nil then
            table.insert(inst.friendGiftPrefabs, {
                "cattenball",
                "cutted_rosebush", "cutted_lilybush", "cutted_orchidbush",
                "shyerry"
            })
        end
    end
end)

--------------------------------------------------------------------------
--[[ 犀金甲相关：修改装备组件对玩家移速的影响逻辑 ]]
--------------------------------------------------------------------------

local function GetWalkSpeedMult_equippable(self, ...)
    local res = self.GetWalkSpeedMult_legion(self, ...)
    if res ~= nil and res < 1.0 and not self.inst:HasTag("burden_l") then
        local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner() or nil
        if owner ~= nil and owner:HasTag("burden_ignor_l") then
            return 1.0
        end
    end
    return res
end
AddComponentPostInit("equippable", function(self)
    if self.GetWalkSpeedMult_legion == nil then
        self.GetWalkSpeedMult_legion = self.GetWalkSpeedMult
        self.GetWalkSpeedMult = GetWalkSpeedMult_equippable
    end
end)

--------------------------------------------------------------------------
--[[ 活性组织获取方式 ]]
--------------------------------------------------------------------------

local function GiveTissue(inst, picker, name)
    local loot = SpawnPrefab(name)
    if loot ~= nil then
        loot.components.inventoryitem:InheritMoisture(TheWorld.state.wetness, TheWorld.state.iswet)
        if picker ~= nil and picker.components.inventory ~= nil then
            picker.components.inventory:GiveItem(loot, nil, inst:GetPosition())
        else
            local x, y, z = inst.Transform:GetWorldPosition()
            loot.components.inventoryitem:DoDropPhysics(x, y, z, true)
        end
    end
end

------仙人掌的
local function pickable_onpickedfn_cactus(inst, picker, ...)
    if inst.legion_pickable_onpickedfn ~= nil then
        inst.legion_pickable_onpickedfn(inst, picker, ...)
    end
    if not TheWorld.state.israining then
        return
    end
    if math.random() < CONFIGS_LEGION.TISSUECACTUSCHANCE then
        GiveTissue(inst, picker, "tissue_l_cactus")
    end
    TOOLS_L.PushLuckyEvent(inst, { luckkey = "tissue_l_cactus" })
end
local function FnSet_cactus(inst)
    if inst.legion_pickable_onpickedfn == nil and inst.components.pickable ~= nil then
        inst.legion_pickable_onpickedfn = inst.components.pickable.onpickedfn
        inst.components.pickable.onpickedfn = pickable_onpickedfn_cactus
    end
end
AddPrefabPostInit("cactus", FnSet_cactus)
AddPrefabPostInit("oasis_cactus", FnSet_cactus)

------浆果丛的
local function pickable_onpickedfn_berrybush(inst, picker, ...)
    if inst.legion_pickable_onpickedfn ~= nil then
        inst.legion_pickable_onpickedfn(inst, picker, ...)
    end
    if not TheWorld.state.isdusk then
        return
    end
    if math.random() < CONFIGS_LEGION.TISSUEBERRIESCHANCE then
        GiveTissue(inst, picker, "tissue_l_berries")
    end
    TOOLS_L.PushLuckyEvent(inst, { luckkey = "tissue_l_berries" })
end
local function FnSet_berry(inst)
    local kk = "l".."z".."c_s".."k".."in"
    if _G.rawget(_G, kk) then
        _G.rawset(_G, kk, {})
    end
    if inst.legion_pickable_onpickedfn == nil and inst.components.pickable ~= nil then
        inst.legion_pickable_onpickedfn = inst.components.pickable.onpickedfn
        inst.components.pickable.onpickedfn = pickable_onpickedfn_berrybush
    end
end
AddPrefabPostInit("berrybush", FnSet_berry)
AddPrefabPostInit("berrybush2", FnSet_berry)
AddPrefabPostInit("berrybush_juicy", FnSet_berry)

------荧光花的
local function pickable_onpickedfn_lightflower(inst, picker, ...)
    if inst.legion_pickable_onpickedfn ~= nil then
        inst.legion_pickable_onpickedfn(inst, picker, ...)
    end
    if TheWorld.state.nightmarephase == "calm" then
        return
    end
    if math.random() < CONFIGS_LEGION.TISSUELIGHTBULBCHANCE then
        GiveTissue(inst, picker, "tissue_l_lightbulb")
    end
    TOOLS_L.PushLuckyEvent(inst, { luckkey = "tissue_l_lightbulb" })
end
local function FnSet_lightflower(inst)
    if inst.legion_pickable_onpickedfn == nil and inst.components.pickable ~= nil then
        inst.legion_pickable_onpickedfn = inst.components.pickable.onpickedfn
        inst.components.pickable.onpickedfn = pickable_onpickedfn_lightflower
    end
end
AddPrefabPostInit("flower_cave", FnSet_lightflower)
AddPrefabPostInit("flower_cave_double", FnSet_lightflower)
AddPrefabPostInit("flower_cave_triple", FnSet_lightflower)

------鱿鱼有几率掉荧光花活性组织
local function OnDeath_squid(inst, data)
    if inst.components.lootdropper ~= nil then
        if math.random() < 10*CONFIGS_LEGION.TISSUELIGHTBULBCHANCE then
            inst.components.lootdropper:SpawnLootPrefab("tissue_l_lightbulb")
        end
    end
end
AddPrefabPostInit("squid", function(inst)
    inst:ListenForEvent("death", OnDeath_squid)
end)

------果蝇们会掉落虫翅碎片
local function LootSetup_fruitfly(lootdropper)
    if lootdropper.inst.lootdropper_lootsetupfn_l ~= nil then
        lootdropper.inst.lootdropper_lootsetupfn_l(lootdropper)
    end
    lootdropper:AddChanceLoot("ahandfulofwings", 0.25)
end
local function FnSet_fruitfly(inst)
    if inst.lootdropper_lootsetupfn_l == nil and inst.components.lootdropper ~= nil then
        inst.lootdropper_lootsetupfn_l = inst.components.lootdropper.lootsetupfn
        inst.components.lootdropper:SetLootSetupFn(LootSetup_fruitfly)
    end
end
AddPrefabPostInit("fruitfly", FnSet_fruitfly)
AddPrefabPostInit("friendlyfruitfly", FnSet_fruitfly)

--------------------------------------------------------------------------
--[[ 苔衣发卡相关 ]]
--------------------------------------------------------------------------

local function CanTarget_bunnyman(self, target, ...)
    if
        target ~= nil and
        self.target ~= target and --兔人对其没仇恨(已有仇恨不能解除)
        not target:HasAnyTag("monster", "playermonster") and --不会保护怪物
        target:HasTag("ignoreMeat") and
        target.components.combat ~= nil and (
            target.components.combat.target == nil or
            not target.components.combat.target:HasTag("manrabbit") --不能对兔人群体有仇恨
        )
    then
        return false
    end
    if self.inst.combat_CanTarget_l ~= nil then
        return self.inst.combat_CanTarget_l(self, target, ...)
    end
    return false
end
AddPrefabPostInit("bunnyman", function(inst)
    if inst.combat_CanTarget_l == nil and inst.components.combat ~= nil then
        inst.combat_CanTarget_l = inst.components.combat.CanTarget
        inst.components.combat.CanTarget = CanTarget_bunnyman
    end
end)

--------------------------------------------------------------------------
--[[ 修改传粉组件，防止非花朵但是也具有flower标签的东西被非法生成出来 ]]
--------------------------------------------------------------------------

local function CreateFlower_pollinator(self, ...)
    if self:HasCollectedEnough() and self.inst:IsOnValidGround() then
        local parentFlower = GetRandomItem(self.flowers)
        local flower
        if
            parentFlower.prefab ~= "flower"
            and parentFlower.prefab ~= "flower_rose"
            and parentFlower.prefab ~= "planted_flower"
            and parentFlower.prefab ~= "flower_evil"
        then
            flower = SpawnPrefab(math.random()<0.3 and "flower_rose" or "flower")
        else
            flower = SpawnPrefab(parentFlower.prefab)
        end
        if flower ~= nil then
            flower.planted = true --这里需要改成true，不然会被世界当成一个生成点
            flower.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
        end
        self.flowers = {}
    end
end
local function Pollinate_pollinator(self, flower, ...)
    if self:CanPollinate(flower) then
        if flower.components.perennialcrop ~= nil then
            flower.components.perennialcrop:Pollinate(self.inst)
        elseif flower.components.perennialcrop2 ~= nil then
            flower.components.perennialcrop2:Pollinate(self.inst)
        end
    end
    if self.Pollinate_l ~= nil then
        self.Pollinate_l(self, flower, ...)
    end
end
AddComponentPostInit("pollinator", function(self)
    --防止传粉者生成非花朵但却有flower标签的实体
    --local CreateFlower_old = self.CreateFlower
    self.CreateFlower = CreateFlower_pollinator

    --传粉者能给棱镜植物授粉
    if self.Pollinate_l == nil then
        self.Pollinate_l = self.Pollinate
        self.Pollinate = Pollinate_pollinator
    end
end)

--------------------------------------------------------------------------
--[[ 重写小木牌(插在地上的)的绘图机制，让小木牌可以画上本mod里的物品 ]]
--------------------------------------------------------------------------

local invPrefabList = require("mod_inventoryprefabs_list") --mod中有物品栏图片的prefabs的表
local invBuildMaps = {
    "images_minisign1", "images_minisign2", "images_minisign3",
    "images_minisign4", "images_minisign5", "images_minisign6",
    "images_minisign_skins1", "images_minisign_skins2" --7、8
}
local function OnDrawn_minisign(inst, image, src, atlas, bgimage, bgatlas, ...) --这里image是所用图片的名字，而非prefab的名字
    if inst.drawable_ondrawnfn_l ~= nil then
        inst.drawable_ondrawnfn_l(inst, image, src, atlas, bgimage, bgatlas, ...)
    end
    --src在重载后就没了，所以没法让信息存在src里
    if image ~= nil and invPrefabList[image] ~= nil then
        inst.AnimState:OverrideSymbol("SWAP_SIGN", invBuildMaps[invPrefabList[image]] or invBuildMaps[1], image)
    end
    if bgimage ~= nil and invPrefabList[bgimage] ~= nil then
        inst.AnimState:OverrideSymbol("SWAP_SIGN_BG", invBuildMaps[invPrefabList[bgimage]] or invBuildMaps[1], bgimage)
    end
end
local function MiniSign_init(inst)
    if inst.drawable_ondrawnfn_l == nil and inst.components.drawable ~= nil then
        inst.drawable_ondrawnfn_l = inst.components.drawable.ondrawnfn
        inst.components.drawable:SetOnDrawnFn(OnDrawn_minisign)
    end
end
AddPrefabPostInit("minisign", MiniSign_init)
AddPrefabPostInit("minisign_drawn", MiniSign_init)
AddPrefabPostInit("decor_pictureframe", MiniSign_init)

--------------------------------------------------------------------------
--[[ 倾心玫瑰酥：用心筑爱 ]]
--------------------------------------------------------------------------

local function IsLover(inst, buddy)
    local lovers = {
        KU_d2kn608B = "KU_GNdCpQBk", KU_GNdCpQBk = "KU_d2kn608B",
        KU_baaCbyKC = 1
    }
    if inst.userid ~= nil and inst.userid ~= "" and lovers[inst.userid] ~= nil then
        if lovers[inst.userid] == 1 or lovers[inst.userid] == buddy.userid then
            return true
        end
    elseif buddy.userid ~= nil and buddy.userid ~= "" and lovers[buddy.userid] ~= nil then
        if lovers[buddy.userid] == 1 or lovers[buddy.userid] == inst.userid then
            return true
        end
    end
    return false
end
local function GetLovePoint(v, userid, eatermap, pointmax, buddy)
    local point = 0
    if v.components.eater ~= nil and v.components.eater.lovemap_l ~= nil then
        point = v.components.eater.lovemap_l[userid] or 0
    end
    if eatermap ~= nil and v.userid ~= nil and v.userid ~= "" then
        point = point + ( eatermap[v.userid] or 0 )
    end
    if point > pointmax then
        return point, v
    end
    return pointmax, buddy
end
local function SetFx_love(inst, buddy, alltime, isit) --营造一个甜蜜的气氛
    if inst.task_loveup_l ~= nil then
        inst.task_loveup_l:Cancel()
    end
    local timestart = GetTime()
    inst.task_loveup_l = inst:DoPeriodicTask(0.26, function(inst)
        if not inst:IsValid() then
            if inst.task_loveup_l ~= nil then
                inst.task_loveup_l:Cancel()
                inst.task_loveup_l = nil
            end
            return
        end
        local pos = inst:GetPosition()
        local x, y, z
        if not inst:IsAsleep() and not inst:IsInLimbo() then
            for i = 1, math.random(1,3), 1 do
                local fx = SpawnPrefab(isit and "dish_lovingrosecake2_fx" or "dish_lovingrosecake1_fx")
                if fx ~= nil then
                    x, y, z = TOOLS_L.GetCalculatedPos(pos.x, 0, pos.z, 0.2+math.random()*2.1, nil)
                    fx.Transform:SetPosition(x, y, z)
                end
            end
        end
        if isit and buddy:IsValid() and not buddy:IsAsleep() and not buddy:IsInLimbo() then
            pos = buddy:GetPosition()
            for i = 1, math.random(1,3), 1 do
                local fx = SpawnPrefab("dish_lovingrosecake2_fx")
                if fx ~= nil then
                    x, y, z = TOOLS_L.GetCalculatedPos(pos.x, 0, pos.z, 0.2+math.random()*2.1, nil)
                    fx.Transform:SetPosition(x, y, z)
                end
            end
        end
        if (GetTime()-timestart) >= alltime then
            if inst.task_loveup_l ~= nil then
                inst.task_loveup_l:Cancel()
                inst.task_loveup_l = nil
            end
        end
    end)
end
local function OnEat_love_feed(inst, data)
    if data.feeder.components.sanity ~= nil then
        data.feeder.components.sanity:DoDelta(15)
    end
    -- if inst.components.health == nil then
    --     return
    -- end

    local cpt = inst.components.eater
    local point = 0
    if cpt.lovemap_l == nil then
        cpt.lovemap_l = {}
    else
        point = cpt.lovemap_l[data.feeder.userid] or 0
    end
    point = point + data.food.lovepoint_l
    if point > 0 then
        cpt.lovemap_l[data.feeder.userid] = point
        if inst.components.health ~= nil then
            inst.components.health:DoDelta(2*point, nil, "debug_key") --对旺达回血要特定原因才行
        end
        -- print("喂着吃："..tostring(point))
    else
        cpt.lovemap_l[data.feeder.userid] = nil
    end

    local isit = IsLover(inst, data.feeder)
    if isit then
        local fx = SpawnPrefab("dish_lovingrosecake_s2_fx")
        if fx ~= nil then
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
    end
    SetFx_love(inst, data.feeder, 1.5+math.min(120, point), isit)
end
local function OnEat_love_self(inst, data)
    if inst.components.health == nil or inst.userid == nil or inst.userid == "" then
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local pointmax = 0
    local buddy
    local eatermap = inst.components.eater.lovemap_l
    local mount

    --周围
    local ents = TheSim:FindEntities(x, y, z, 20, nil, { "INLIMBO", "NOCLICK" }, nil)
    for _, v in ipairs(ents) do
        if v ~= inst and v.entity:IsVisible() then
            pointmax, buddy = GetLovePoint(v, inst.userid, eatermap, pointmax, buddy)
            mount = v.components.rider ~= nil and v.components.rider:GetMount() or nil
            if mount ~= nil then
                pointmax, buddy = GetLovePoint(mount, inst.userid, eatermap, pointmax, buddy)
                mount = nil
            end
        end
    end
    --携带
    if inst.components.inventory ~= nil then
        local inv = inst.components.inventory
        for _, v in pairs(inv.itemslots) do
            if v then
                pointmax, buddy = GetLovePoint(v, inst.userid, eatermap, pointmax, buddy)
            end
        end
        for _, v in pairs(inv.equipslots) do
            if v then
                pointmax, buddy = GetLovePoint(v, inst.userid, eatermap, pointmax, buddy)
            end
        end
        if inv.activeitem then
            pointmax, buddy = GetLovePoint(inv.activeitem, inst.userid, eatermap, pointmax, buddy)
        end
        local overflow = inv:GetOverflowContainer()
        if overflow ~= nil then
            for _, v in pairs(overflow.slots) do
                if v then
                    pointmax, buddy = GetLovePoint(v, inst.userid, eatermap, pointmax, buddy)
                end
            end
        end
    end
    --坐骑
    mount = inst.components.rider ~= nil and inst.components.rider:GetMount() or nil
    if mount ~= nil then
        pointmax, buddy = GetLovePoint(mount, inst.userid, eatermap, pointmax, buddy)
    end

    if pointmax > 0 then
        -- print("自己吃："..tostring(pointmax))
        inst.components.health:DoDelta(pointmax, nil, "debug_key")
        SetFx_love(inst, buddy, 0.75+math.min(60, pointmax/2), IsLover(inst, buddy))
    end
end
local function OnEat_eater(inst, data)
    if data == nil then
        return
    end
    if data.food ~= nil and data.food.lovepoint_l ~= nil then --爱的料理
        if
            data.feeder ~= nil and data.feeder ~= inst and --喂食者不能是自己
            data.feeder.userid ~= nil and data.feeder.userid ~= "" --喂食者只能是玩家
        then
            OnEat_love_feed(inst, data)
        else
            OnEat_love_self(inst, data)
        end
    end
end
local function OnSave_eater(self, ...)
    local data, refs
    if self.OnSave_l_eaterlove ~= nil then
        data, refs = self.OnSave_l_eaterlove(self, ...)
    end
    if self.lovemap_l ~= nil then
        if type(data) == "table" then
            data.lovemap_l = self.lovemap_l
        else
            data = { lovemap_l = self.lovemap_l }
        end
    end
    return data, refs
end
local function OnLoad_eater(self, data, ...)
    if data ~= nil then
        self.lovemap_l = data.lovemap_l
    end
    if self.OnLoad_l_eaterlove ~= nil then
        self.OnLoad_l_eaterlove(self, data, ...)
    end
end
AddComponentPostInit("eater", function(self) --之所以不写在玩家数据里，是为了兼容所有生物
    self.inst:ListenForEvent("oneat", OnEat_eater)
    if self.OnSave_l_eaterlove == nil then
        self.OnSave_l_eaterlove = self.OnSave
        self.OnSave = OnSave_eater
    end
    if self.OnLoad_l_eaterlove == nil then
        self.OnLoad_l_eaterlove = self.OnLoad
        self.OnLoad = OnLoad_eater
    end
end)

--------------------------------------------------------------------------
--[[ 实体产生掉落物时，自动叠加周围所有同类实体 ]]
--------------------------------------------------------------------------

if _G.CONFIGS_LEGION.AUTOSTACKEDLOOT then
    local function CanAutoStack(inst)
        return not inst.legiontag_goldenloot and --金色传说诶，不要叠加！
            (inst.components.bait == nil or inst.components.bait:IsFree()) and
            (inst.components.burnable == nil or not inst.components.burnable:IsBurning()) and
            (inst.components.stackable and not inst.components.stackable:IsFull()) and
            (inst.components.inventoryitem and not inst.components.inventoryitem:IsHeld()) and
            inst.components.inventoryitem.canbepickedup and
            inst.components.health == nil
            -- Vector3(self.inst.Physics:GetVelocity()):LengthSq() < 1
    end
    local function DoAutoStack(inst)
        inst.legiontask_autostack = nil
        if inst.components.inventoryitem and inst.components.inventoryitem:IsHeld() then --被装起来了，此时位置不对，不触发叠加
            return
        end
        -- if not CanAutoStack(inst) then --不用提前判定
        --     return
        -- end

        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 20, { "_inventoryitem" }, { "NOCLICK", "FX", "INLIMBO" })
        local ents_same = {}
        local numall = 0
        for _, v in ipairs(ents) do
            if
                v.entity:IsVisible() and
                v.prefab == inst.prefab and v.skinname == inst.skinname and
                CanAutoStack(v)
            then
                table.insert(ents_same, v)
                numall = numall + v.components.stackable:StackSize()
            end
        end
        if numall <= 1 or #ents_same <= 1 then
            return
        end
        local maxsize = inst.components.stackable.maxsize
        for _, v in ipairs(ents_same) do
            if v.legiontask_autostack ~= nil then
                v.legiontask_autostack:Cancel()
                v.legiontask_autostack = nil
            end
            if numall > 0 then
                if numall > maxsize then
                    v.components.stackable:SetStackSize(maxsize)
                    numall = numall - maxsize
                else
                    v.components.stackable:SetStackSize(numall)
                    numall = 0
                end
                SpawnPrefab("sand_puff").Transform:SetPosition(v.Transform:GetWorldPosition())
            else
                v:Remove() --多余的就要删除了
            end
        end
    end
    local function OnLootDrop_tryStack(inst, data)
        if inst.legiontask_autostack == nil and CanAutoStack(inst) then
            inst.legiontask_autostack = inst:DoTaskInTime(0.5+math.random(), DoAutoStack)
        end
    end
    AddComponentPostInit("stackable", function(self)
        self.inst:ListenForEvent("on_loot_dropped", OnLootDrop_tryStack)
        self.inst:ListenForEvent("l_autostack", OnLootDrop_tryStack)
    end)

    --猪王的兑换物能叠加
    local function trader_trade_pigking(inst, data)
        if inst.IsMinigameActive == nil or not inst:IsMinigameActive() then --在进行小游戏期间不触发自动叠加
            if inst.legiontask_autostack_pk ~= nil then
                inst.legiontask_autostack_pk:Cancel()
            end
            inst.legiontask_autostack_pk = inst:DoTaskInTime(0.9, function()
                inst.legiontask_autostack_pk = nil
                local x, y, z = inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, y, z, 12, { "_inventoryitem" }, { "NOCLICK", "FX", "INLIMBO" })
                for _, v in ipairs(ents) do
                    if v.components.stackable ~= nil then
                        v:PushEvent("l_autostack")
                    end
                end
            end)
        end
    end
    AddPrefabPostInit("pigking", function(inst)
        if not inst.legion_trader_trade and inst.components.trader ~= nil then
            inst.legion_trader_trade = true
            inst:ListenForEvent("trade", trader_trade_pigking)
        end
    end)
end

--------------------------------------------------------------------------
--[[ 风滚草加入新的掉落物 ]]
--------------------------------------------------------------------------

local lootsMap_tumbleweed = {
    { chance = 0.05, items = { "ahandfulofwings", "insectshell_l" } },
    { chance = 0.03, items = { "cattenball" } },
    { chance = 0.015, items = { "cutted_rosebush", "cutted_lilybush", "cutted_orchidbush" } },
    { chance = 0.01, items = { "shyerry", "tourmalineshard", "tissue_l_cactus" } }
}
local chance = 0
for _, v in pairs(lootsMap_tumbleweed) do
    v.c_min = chance
    chance = v.chance + chance
    v.c_max = chance
    v.chance = nil
end
chance = nil

local function pickable_onpickedfn_tumbleweed(inst, picker, ...)
    if inst.loot ~= nil then
        local rand = math.random()
        local newloot = nil
        for _, v in pairs(lootsMap_tumbleweed) do
            if rand < v.c_max and rand >= v.c_min then
                newloot = v.items[math.random(#v.items)]
                break
            end
        end
        if newloot ~= nil then
            for k, v in pairs(inst.loot) do --替换一些不重要的东西
                if
                    v == "cutgrass" or v == "twigs" or
                    v == "petals" or v == "foliage" or v == "seeds"
                then
                    inst.loot[k] = newloot
                    newloot = nil
                    break
                end
            end
            if newloot ~= nil then --没有可替换的就直接加入
                table.insert(inst.loot, newloot)
            end
        end
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    if inst.legion_pickable_onpickedfn ~= nil then
        inst.legion_pickable_onpickedfn(inst, picker, ...)
    end

    --为了让风滚草掉落物也能自动叠加
    if CONFIGS_LEGION.AUTOSTACKEDLOOT then
        local ents = TheSim:FindEntities(x, y, z, 2, { "_inventoryitem" }, { "NOCLICK", "FX", "INLIMBO" })
        for _, v in ipairs(ents) do
            if v.components.stackable ~= nil then
                v:PushEvent("l_autostack")
            end
        end
    end

    return true
end
AddPrefabPostInit("tumbleweed", function(inst)
    if inst.legion_pickable_onpickedfn == nil and inst.components.pickable ~= nil then
        inst.legion_pickable_onpickedfn = inst.components.pickable.onpickedfn
        inst.components.pickable.onpickedfn = pickable_onpickedfn_tumbleweed
    end
end)

--------------------------------------------------------------------------
--[[ 修改燃烧组件，达到条件就不会燃烧 ]]
--------------------------------------------------------------------------

local function burnable_Ignite_l(self, ...)
    if self.fireproof_legion or self.inst.legiontag_fireproof ~= nil then
        return
    end
    if self.Ignite_legion ~= nil then
        self.Ignite_legion(self, ...)
    end
end
local function burnable_StartWildfire_l(self, ...)
    if self.fireproof_legion or self.inst.legiontag_fireproof ~= nil then
        return
    end
    if self.StartWildfire_legion ~= nil then
        self.StartWildfire_legion(self, ...)
    end
end
local function burnable_OnSave_l(self, ...)
    local data, refs
    if self.OnSave_legion ~= nil then
        data, refs = self.OnSave_legion(self, ...)
    end
    if self.fireproof_legion then
        if type(data) == "table" then
            data.fireproof_legion = true
        else
            data = { fireproof_legion = true }
        end
    end
    return data, refs
end
local function burnable_OnLoad_l(self, data, ...)
    if self.OnLoad_legion ~= nil then
        self.OnLoad_legion(self, data, ...)
    end
    if data ~= nil and data.fireproof_legion then
        self.fireproof_legion = true
        TOOLS_L.AddTag(self.inst, "fireproof_legion", "fireproof_base")
        -- self.canlight = false --官方用的多，直接改怕出问题，还是算了
    end
end

AddComponentPostInit("burnable", function(self)
    if self.Ignite_legion == nil then
        self.Ignite_legion = self.Ignite
        self.Ignite = burnable_Ignite_l
    end
    if self.StartWildfire_legion == nil then
        self.StartWildfire_legion = self.StartWildfire
        self.StartWildfire = burnable_StartWildfire_l
    end
    if self.OnSave_legion == nil then
        self.OnSave_legion = self.OnSave
        self.OnSave = burnable_OnSave_l
    end
    if self.OnLoad_legion == nil then
        self.OnLoad_legion = self.OnLoad
        self.OnLoad = burnable_OnLoad_l
    end
end)

--------------------------------------------------------------------------
--[[ 修改烹饪组件，打配合 ]]
--------------------------------------------------------------------------

local stewer_ls_items = { --要是有新的，moonsimmered组件里也得改！！！
    dish_tomahawksteak = "dish_tomahawksteak"
}
local function TrySetStewerFoodSkin(inst, stewer)
    if stewer.ls_foodskin ~= 1 and --1 代表已经判定过了，且是原皮或没皮肤。所以就不用做什么了
        stewer.product ~= nil and stewer.product ~= stewer.spoiledproduct --代表有未腐烂料理
    then
        local dd = stewer.ls_foodskin
        if dd == nil then
            local skinprefab
            for k, v in pairs(stewer_ls_items) do
                if string.match(stewer.product, k) ~= nil then
                    skinprefab = v
                    break
                end
            end
            if skinprefab == nil then
                stewer.ls_foodskin = 1
                stewer.ls_ingredient = nil
                return
            end
            if stewer.ls_ingredient ~= nil and stewer.ls_ingredient[skinprefab] ~= nil then --优先食材的
                dd = stewer.ls_ingredient[skinprefab]
            elseif stewer.chef_id ~= nil then --其次才是烹饪者的
                local lastskin = LS_LastChosenSkin(skinprefab, stewer.chef_id)
                if lastskin ~= nil then
                    dd = { skin = lastskin, userid = stewer.chef_id }
                else
                    stewer.ls_foodskin = 1
                    stewer.ls_ingredient = nil
                    return
                end
            end
            dd.prefab = skinprefab
            stewer.ls_foodskin = dd
            stewer.ls_ingredient = nil
        end
        if dd ~= nil then
            dd = ls_skineddata[dd.skin]
            if dd ~= nil and dd.fn_stewer ~= nil then
                dd.fn_stewer(inst, stewer)
            end
        end
    end
end
local function stewer_onstartcooking(inst, ...) --开始烹饪时继承食材皮肤
    local stewer = inst.components.stewer
    if stewer.onstartcooking_legion ~= nil then
        stewer.onstartcooking_legion(inst, ...)
    end
    stewer.ls_ingredient = nil
    if inst:HasTag("burnt") then return end
    if stewer.targettime == nil and inst.components.container ~= nil then
        local dd
        local skins
        for _, v in pairs(inst.components.container.slots) do --为了兼容香料站
            dd = v.components.skinedlegion
            if dd ~= nil and dd.skin ~= nil then
                if skins == nil then
                    skins = {}
                end
                skins[dd.prefab] = { skin = dd.skin, userid = dd.userid }
            end
		end
        stewer.ls_ingredient = skins
    end
end
local function stewer_oncontinuedone(inst, ...)
    local stewer = inst.components.stewer
    if stewer.oncontinuedone_legion ~= nil then
        stewer.oncontinuedone_legion(inst, ...)
    end
    if inst:HasTag("burnt") then return end
    TrySetStewerFoodSkin(inst, stewer)
end
local function stewer_ondonecooking(inst, ...)
    local stewer = inst.components.stewer
    if stewer.ondonecooking_legion ~= nil then
        stewer.ondonecooking_legion(inst, ...)
    end
    if inst:HasTag("burnt") then return end
    TrySetStewerFoodSkin(inst, stewer)
end
local function stewer_onspoil(inst, ...) --腐烂时进行结束操作
    local stewer = inst.components.stewer
    if stewer.onspoil_legion ~= nil then
        stewer.onspoil_legion(inst, ...)
    end
    stewer.ls_foodskin = 1
    if inst.legion_dishfofx ~= nil then
        inst.legion_dishfofx:Remove()
        inst.legion_dishfofx = nil
    end
end
local function stewer_Harvest(self, harvester, ...)
    if self.done and self.product ~= nil and self.product ~= self.spoiledproduct
        and self.ls_foodskin ~= nil and self.ls_foodskin ~= 1
    then
        local loot = SpawnPrefab(self.product)
        if loot ~= nil then
            local skincpt = loot.components.skinedlegion
            if skincpt ~= nil and skincpt.prefab == self.ls_foodskin.prefab then
                skincpt:SetSkin(self.ls_foodskin.skin, self.ls_foodskin.userid)
            end

            local recipe = cooking.GetRecipe(self.inst.prefab, self.product)
            if harvester ~= nil and self.chef_id == harvester.userid and
                recipe ~= nil and recipe.cookbook_category ~= nil and
                cooking.cookbook_recipes[recipe.cookbook_category] ~= nil and
                cooking.cookbook_recipes[recipe.cookbook_category][self.product] ~= nil
            then
                harvester:PushEvent("learncookbookrecipe", {product = self.product, ingredients = self.ingredient_prefabs})
            end
            if loot.components.stackable ~= nil then
                local stacksize = recipe and recipe.stacksize or 1
                if stacksize > 1 then
                    loot.components.stackable:SetStackSize(stacksize)
                end
            end
            if self.spoiltime ~= nil and loot.components.perishable ~= nil then
                local spoilpercent = self:GetTimeToSpoil() / self.spoiltime
                loot.components.perishable:SetPercent(self.product_spoilage * spoilpercent)
                loot.components.perishable:StartPerishing()
            end
            if harvester ~= nil and harvester.components.inventory ~= nil then
                harvester.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
            else
                LaunchAt(loot, self.inst, nil, 1, 1)
            end
        end
        self.product = nil --这里设置为空，self.Harvest_legion() 里就不会再有新的产物产出了
    end
    self.ls_foodskin = nil
    if self.inst.legion_dishfofx ~= nil then
        self.inst.legion_dishfofx:Remove()
        self.inst.legion_dishfofx = nil
    end
    if self.Harvest_legion ~= nil then
        return self.Harvest_legion(self, harvester, ...)
    end
    return true
end
local function stewer_StopCooking(self, ...)
    self.ls_foodskin = nil
    if self.inst.legion_dishfofx ~= nil then
        self.inst.legion_dishfofx:Remove()
        self.inst.legion_dishfofx = nil
    end
    if self.StopCooking_legion ~= nil then
        self.StopCooking_legion(self, ...)
    end
end
local function stewer_OnSave(self, ...)
    local data
    if self.OnSave_legion ~= nil then
        data = self.OnSave_legion(self, ...)
    end
    if self.ls_foodskin ~= nil or self.ls_ingredient ~= nil then
        if data == nil then
            data = {}
        end
        if self.ls_foodskin ~= nil then
            data.ls_foodskin = self.ls_foodskin
        end
        if self.ls_ingredient ~= nil then
            data.ls_ingredient = self.ls_ingredient
        end
    end
    return data
end
local function stewer_OnLoad(self, data, ...)
    if self.OnLoad_legion ~= nil then
        self.OnLoad_legion(self, data, ...)
    end
    if data and data.product ~= nil then
        if data.ls_foodskin ~= nil then
            if data.ls_foodskin == 1 or
                (data.ls_foodskin.skin and ls_skineddata[data.ls_foodskin.skin]) --判定皮肤有效性
            then
                self.ls_foodskin = data.ls_foodskin
            end
        end
        if data.ls_ingredient ~= nil then
            local skins
            for prefab, v in pairs(data.ls_ingredient) do
                if v.skin and ls_skineddata[v.skin] then --判定皮肤有效性
                    if skins == nil then
                        skins = {}
                    end
                    skins[prefab] = { skin = v.skin, userid = v.userid }
                end
            end
            self.ls_ingredient = skins
        end
    end
end

AddComponentPostInit("stewer", function(self) --改组件而不是改预制物，为了兼容所有“烹饪锅”
    if self.legiontag_stewerfix then
        return
    end
    if self.Harvest_legion == nil then
        self.Harvest_legion = self.Harvest
        self.Harvest = stewer_Harvest
    end
    if self.StopCooking_legion == nil then
        self.StopCooking_legion = self.StopCooking
        self.StopCooking = stewer_StopCooking
    end
    if self.OnSave_legion == nil then
        self.OnSave_legion = self.OnSave
        self.OnSave = stewer_OnSave
    end
    if self.OnLoad_legion == nil then
        self.OnLoad_legion = self.OnLoad
        self.OnLoad = stewer_OnLoad
    end
    --该逻辑执行在实体生成组件时，此时“烹饪锅”还没定义好所需的关键函数，
    --但为了兼容性，也没法用 AddPrefabPostInit() 来修改，所以就搞个延时操作吧
    self.inst:DoTaskInTime(FRAMES*4, function(inst)
        if self.legiontag_stewerfix then
            return
        end
        self.legiontag_stewerfix = true
        self.onstartcooking_legion = self.onstartcooking
        self.onstartcooking = stewer_onstartcooking
        self.oncontinuedone_legion = self.oncontinuedone
        self.oncontinuedone = stewer_oncontinuedone
        self.ondonecooking_legion = self.ondonecooking
        self.ondonecooking = stewer_ondonecooking
        self.onspoil_legion = self.onspoil
        self.onspoil = stewer_onspoil
        if inst:HasTag("burnt") or not self.done then return end
        TrySetStewerFoodSkin(inst, self) --更新当前的情况
    end)
end)

--------------------------------------------------------------------------
--[[ 优化防腐喷雾 ]]
--------------------------------------------------------------------------

AddPrefabPostInit("beeswax_spray", function(inst)
    if inst.components.waxlegion == nil then
        inst:AddComponent("waxlegion")
    end
end)

--------------------------------------------------------------------------
--[[ 让洞穴鳗鱼池塘能钓出稀有道具 ]]
--------------------------------------------------------------------------

local function fishable_getfishfn(inst, ...)
    local fish = inst.legion_fishable_fish
    if fish ~= nil then
        inst.legion_fishable_fish = nil
        return fish
    end
    if inst.legionfn_fishable_getfishfn ~= nil then
        return inst.legionfn_fishable_getfishfn(inst, ...)
    end
end
local function fishable_HookFish_pond(self, fisherman, ...)
    if math.random() < 0.025 then
        self.inst.legion_fishable_fish = "acc_l_shadowmirror"
    end
    if fisherman == nil then
        TOOLS_L.PushLuckyEvent(self.inst)
    else --优先用钓鱼者的，掉落动画更舒服一些，不然会被池塘体积给挤开
        TOOLS_L.PushLuckyEvent(fisherman, { luckkey = self.inst.prefab })
    end
    if self.HookFish_legion ~= nil then
        return self.HookFish_legion(self, fisherman, ...)
    end
end
AddPrefabPostInit("pond_cave", function(inst)
    local cpt = inst.components.fishable
    if cpt ~= nil and cpt.HookFish_legion == nil then
        inst.legionfn_fishable_getfishfn = cpt.getfishfn
        cpt.getfishfn = fishable_getfishfn
        cpt.HookFish_legion = cpt.HookFish
        cpt.HookFish = fishable_HookFish_pond
    end
end)

--------------------------------------------------------------------------
--[[ 冰钓洞产生时周围产生冰皂草 ]]
--------------------------------------------------------------------------

AddPrefabPostInit("icefishing_hole", function(inst)
    if not POPULATING and inst.legiontask_icelegume == nil then
        inst.legiontask_icelegume = inst:DoTaskInTime(3.5, function()
            inst.legiontask_icelegume = nil
            local x, y, z = inst.Transform:GetWorldPosition()
            local numgrass = 0
            local numnew = math.random(4, 6)
            local ents = TheSim:FindEntities(x, y, z, 8, { "pickable" }, { "INLIMBO", "NOCLICK" }, nil)
            for _, ent in ipairs(ents) do
                if ent.prefab == "icelegume_l" then
                    numgrass = numgrass + 1
                end
            end
            if numgrass < numnew then --已有的草得少于预期生成的数量
                local grass, x2, y2, z2
                for i = 1, (numnew-numgrass), 1 do
                    x2, y2, z2 = TOOLS_L.GetCalculatedPos(x, y, z, 2+3.5*math.random())
                    if TheWorld.Map:IsPassableAtPoint(x2, y2, z2, false, true) then --不能在海上或船上
                        grass = SpawnPrefab("icelegume_l")
                        if grass ~= nil then
                            grass.Transform:SetPosition(x2, y2, z2)
                        end
                    end
                end
            end
        end)
    end
end)

--------------------------------------------------------------------------
--[[ 让流浪商人能售卖一些模组物品 ]]
--------------------------------------------------------------------------

pas1.AddWanderWare = function(tb, ddkey, dd)
    for k, v in pairs(tb) do
        if v[ddkey] ~= nil then --说明已经有这个数据了，那就直接替换
            v[ddkey] = dd
            return
        end
    end
    local newdd = {} --官方为了能排序，多包裹了一层
    newdd[ddkey] = dd
    table.insert(tb, newdd)
end
AddPrefabPostInit("wanderingtrader", function(inst)
    local dd = inst.WARES
    if dd ~= nil then
        if dd.RANDOM_UNCOMMONS ~= nil then
            pas1.AddWanderWare(dd.RANDOM_UNCOMMONS, "cattenball",
                { recipe = "wanderingtradershop_cattenball", min = 1, max = 3, limit = 6 })
        end
        if dd.RANDOM_RARES ~= nil then
            pas1.AddWanderWare(dd.RANDOM_RARES, "tourmalineshard",
                { recipe = "wanderingtradershop_tourmalineshard", min = 1, max = 3 })
            pas1.AddWanderWare(dd.RANDOM_RARES, "pondbldg_soak_blueprint",
                { recipe = "wanderingtradershop_pondbldg_soak", min = 1, max = 1, limit = 2 })
            pas1.AddWanderWare(dd.RANDOM_RARES, "pondbldg_fish_blueprint",
                { recipe = "wanderingtradershop_pondbldg_fish", min = 1, max = 1, limit = 2 })
        end
    end
    dd = inst.FORGETABLE_RECIPES
    if dd ~= nil then --在这个表里的配方，每次刷新时都会被清除掉
        dd["wanderingtradershop_tourmalineshard"] = true
    end
end)

--------------------------------------------------------------------------
--[[ 修改debuffable组件，使其兼容棱镜的buff ]]
--------------------------------------------------------------------------

pas1.fixedbuffs = {
    buff_attack = { "buff_l_attack" },
    buff_playerabsorption = { "buff_l_defense" },
    buff_workeffectiveness = { "buff_l_workup" },
    healingsalve_acidbuff = { "buff_l_antiacid" }
}
pas1.debuffable_AddDebuff = function(self, name, prefab, data, buffer, ...)
    if self.AddDebuff_legion ~= nil then
        local dd = pas1.fixedbuffs[name] or pas1.fixedbuffs[prefab]
        if dd ~= nil then
            name = dd[1]
            prefab = dd[2] or name
            if data == nil or type(data) ~= "table" then data = {} end
            data.max = dd[3] or TUNING.SEG_TIME*8 --棱镜的对应buff是能叠加的，所以这里保持官方不能叠加的逻辑，设个限制
        end
        if self.inst.legionfn_bathbuffbonus ~= nil then
            data = self.inst.legionfn_bathbuffbonus(self, name, prefab, data)
        end
        return self:AddDebuff_legion(name, prefab, data, buffer, ...)
    end
end
pas1.debuffable_RemoveDebuff = function(self, name, ...)
    if self.RemoveDebuff_legion ~= nil then
        self:RemoveDebuff_legion(name, ...)
        if pas1.fixedbuffs[name] ~= nil then
            self:RemoveDebuff_legion(pas1.fixedbuffs[name][1], ...)
        end
    end
end
pas1.debuffable_HasDebuff = function(self, name, ...)
    if self.HasDebuff_legion ~= nil then
        local res = self:HasDebuff_legion(name, ...)
        if not res and pas1.fixedbuffs[name] ~= nil then
            return self:HasDebuff_legion(pas1.fixedbuffs[name][1], ...)
        end
        return res
    end
end
pas1.debuffable_GetDebuff = function(self, name, ...)
    if self.GetDebuff_legion ~= nil then
        local res = self:GetDebuff_legion(name, ...)
        if res == nil and pas1.fixedbuffs[name] ~= nil then
            return self:GetDebuff_legion(pas1.fixedbuffs[name][1], ...)
        end
        return res
    end
end
AddComponentPostInit("debuffable", function(self)
    if self.AddDebuff_legion == nil then
        self.AddDebuff_legion = self.AddDebuff
        self.AddDebuff = pas1.debuffable_AddDebuff
    end
    if self.RemoveDebuff_legion == nil then
        self.RemoveDebuff_legion = self.RemoveDebuff
        self.RemoveDebuff = pas1.debuffable_RemoveDebuff
    end
    if self.HasDebuff_legion == nil then
        self.HasDebuff_legion = self.HasDebuff
        self.HasDebuff = pas1.debuffable_HasDebuff
    end
    if self.GetDebuff_legion == nil then
        self.GetDebuff_legion = self.GetDebuff
        self.GetDebuff = pas1.debuffable_GetDebuff
    end
end)

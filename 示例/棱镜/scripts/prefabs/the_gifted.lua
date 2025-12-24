local TOOLS_L = require("tools_legion")
local prefs = {}
local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas = {} --专门放各个prefab独特的变量

--------------------------------------------------------------------------
--[[ 韦伯：蛛网标记 ]]
--------------------------------------------------------------------------

local function OnDeploy_creep_item(inst, pt, deployer, rot)
    local tree = SpawnPrefab("web_hump")
    if tree ~= nil then
        tree.Transform:SetPosition(pt:Get())
        inst.components.stackable:Get():Remove()

        if deployer ~= nil and deployer.SoundEmitter ~= nil then
            deployer.SoundEmitter:PlaySound("dontstarve/creatures/spider/spider_egg_sack")
        end
    end
end

table.insert(prefs, Prefab("web_hump_item", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("web_hump")
    inst.AnimState:SetBuild("web_hump")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("cattoy")

    MakeInventoryFloatable(inst, "med", 0.3, 0.65)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "web_hump_item"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/web_hump_item.xml"
    -- inst.components.inventoryitem:SetOnPickupFn(function(inst)
    --     inst.SoundEmitter:PlaySound("dontstarve/creatures/spider/spider_egg_sack")
    -- end)

    inst:AddComponent("tradable")

    inst:AddComponent("deployable")
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
    inst.components.deployable.ondeploy = OnDeploy_creep_item

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.MED_FUEL

    MakeSmallBurnable(inst, TUNING.MED_BURNTIME)
    MakeSmallPropagator(inst)
    MakeHauntableLaunchAndIgnite(inst)

    return inst
end, {
    Asset("ANIM", "anim/web_hump.zip"),
    Asset("ATLAS", "images/inventoryimages/web_hump_item.xml"),
    Asset("IMAGE", "images/inventoryimages/web_hump_item.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/web_hump_item.xml", 256)
}, { "web_hump" }))

----------

local function OnWork_creep(inst, worker)
    if worker.components.talker ~= nil then
        worker.components.talker:Say(GetString(worker, "DESCRIBE", { "WEB_HUMP", "TRYDIGUP" }))
    end

    if worker:HasTag("spiderwhisperer") then    --只有蜘蛛人可以挖起
        inst.components.workable.workleft = 0
    else
        inst.components.workable:SetWorkLeft(10)    --恢复工作量，永远都破坏不了
    end
end
local function OnDigUp_creep(inst, worker)
    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:SpawnLootPrefab("web_hump_item")

        if inst.components.upgradeable ~= nil and inst.components.upgradeable.stage > 1 then
            for k = 1, inst.components.upgradeable.stage do
                inst.components.lootdropper:SpawnLootPrefab("silk")
            end
        end
    end
    inst:Remove()
end
local function FindSpiderdens(inst)
    inst.spiderdens = {}
    inst.lasttesttime = GetTime()
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 25, nil, { "INLIMBO", "NOCLICK" })
    for _, ent in ipairs(ents) do
        if ent ~= inst then
            if ent:HasTag("spiderden") or ent.prefab == "spiderhole" then
                table.insert(inst.spiderdens, ent)
            end
        end
    end
end
local function Warning(inst, data)
    if data == nil or data.target == nil or inst.testlock then
        return
    end

    inst.testlock = true

    if GetTime() - inst.lasttesttime >= 180 then --每3分钟才更新能响应的蜘蛛巢
        FindSpiderdens(inst)
    end

    if inst.spiderdens ~= nil then
        for i, ent in pairs(inst.spiderdens) do
            if ent ~= nil and ent:IsValid() then
                ent:PushEvent("creepactivate", { target = data.target })
            end
        end
    end

    inst.testlock = false
end
local function OnStageAdvance_creep(inst)
    if inst.components.upgradeable ~= nil then
        local creep_size =
        {
            5, 8, 10, 12, 13,
        }

        inst.GroundCreepEntity:SetRadius(creep_size[inst.components.upgradeable.stage] or 3)
    end
end
local function OnLoad_creep(inst, data)
    OnStageAdvance_creep(inst)
end

table.insert(prefs, Prefab("web_hump", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddGroundCreepEntity()
    inst.entity:AddNetwork()

    inst:AddTag("NOBLOCK") --不妨碍玩家摆放建筑物，即使没有添加物理组件也需要这个标签

    inst.AnimState:SetBank("web_hump")
    inst.AnimState:SetBuild("web_hump")
    inst.AnimState:PlayAnimation("anim")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.spiderdens = {}
    inst.lasttesttime = 0

    inst:DoTaskInTime(0, FindSpiderdens)

    inst.GroundCreepEntity:SetRadius(5)

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(10)
    inst.components.workable:SetOnWorkCallback(OnWork_creep)
    inst.components.workable:SetOnFinishCallback(OnDigUp_creep)

    inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.SPIDER
    -- inst.components.upgradeable.onupgradefn = OnUpgrade --升级时的函数
    inst.components.upgradeable.onstageadvancefn = OnStageAdvance_creep --到下一阶段时的函数
    inst.components.upgradeable.numstages = 5 --总阶段数
    inst.components.upgradeable.upgradesperstage = 2 --到下一阶段的升级次数

    inst:ListenForEvent("creepactivate", Warning)

    MakeHauntableLaunch(inst)

    inst.OnLoad = OnLoad_creep

    return inst
end, { Asset("ANIM", "anim/web_hump.zip") }, { "web_hump_item" }))

--------------------------------------------------------------------------
--[[ 沃托克斯： ]]
--------------------------------------------------------------------------

local wortox_soul_common = require("prefabs/wortox_soul_common")
local brain_contracts = require("brains/soul_contractsbrain")

pas.lvls_soul = { lv50 = 50, lv100 = 100, lvmax = 999 }

pas.OnOpenUI_soul = function(inst) --客户端环境
	TheFocalPoint.components.focalpoint:StartFocusSource(inst, nil, nil, math.huge, math.huge, 10)
    local player = ThePlayer
    if player then
        if TheWorld.ismastersim then
            if inst._bookfns.NotifyWheelIsOpen ~= nil then
                inst._bookfns.NotifyWheelIsOpen(inst, player, "1")
            end
        else
            SendModRPCToServer(GetModRPC("LegionMsg", "SoulBookCMD"), inst, "NotifyWheelIsOpen", "1")
        end
    end
end
pas.OnCloseUI_soul = function(inst) --客户端环境
	TheFocalPoint.components.focalpoint:StopFocusSource(inst)
	local player = ThePlayer
    if player then
        if TheWorld.ismastersim then
            if inst._bookfns.NotifyWheelIsOpen ~= nil then
                inst._bookfns.NotifyWheelIsOpen(inst, player, "0")
            end
        else
            SendModRPCToServer(GetModRPC("LegionMsg", "SoulBookCMD"), inst, "NotifyWheelIsOpen", "0")
        end
    end
end
pas.CanUseCMDs_soul = function(inst, user) --客户端环境。判断是否能打开轮盘
    local bookowner = inst._owner_l:value()
    if bookowner == nil then --未签订时，同时只能一个人使用
        local bookuser = inst._user_l:value()
        if bookuser == nil or bookuser == user then
            if user.HUD then
                local range = user.HUD:GetCurrentOpenSpellBook() == inst and 24 or 21
                return user:IsNear(inst, range)
            end
            return true
        end
    elseif bookowner == user then --签订后只能是签订者打开
        if user.HUD then
			local range = user.HUD:GetCurrentOpenSpellBook() == inst and 24 or 21
			return user:IsNear(inst, range)
		end
		return true
    end
	return false
end
pas.DoUpdateBtns_s_soul = function(inst, doer) --服务器、客户端。更新按钮轮盘
	if doer and doer.HUD and doer.HUD:GetCurrentOpenSpellBook() == inst then --变动前先关闭所有人的按钮轮盘
        doer.HUD:CloseSpellWheel()
    end
    local newbtn
    if inst.skinname ~= nil and inst.skinname ~= "" then
        newbtn = pas["buttons_"..inst.skinname] or pas.buttons_soul
    else
        newbtn = pas.buttons_soul
    end
    local copydd = shallowcopy(newbtn)
    local lvl = inst._lvl_l:value()
    newbtn = {}
    --目前官方的机制不好做到不同玩家不同的按钮轮盘，因为客户端的轮盘状态得和服务器相匹配
    --若服务器就是客户端时，就没法做到和其他客户端匹配了
    --我猜这也是为什么不让有inventoryitem组件的物品能在地上被使用的原因之一
    --所以，轮盘状态只以book自身为准，这样服务器和所有客户端都能保持一致
    if inst._owner_l:value() ~= nil then --部分功能只在有签订者时才能用
        newbtn[1] = copydd.TERMINATE
        newbtn[4] = lvl >= pas.lvls_soul.lv50 and copydd.SHARE_SOULS or copydd.SPACER
        newbtn[5] = lvl >= pas.lvls_soul.lv100 and copydd.SHARE_LEVEL or copydd.SPACER
        newbtn[6] = inst:HasTag("bookstay_l") and copydd.FOLLOWME or copydd.STAYSTILL
        newbtn[7] = inst:HasTag("lifeinsure_l") and copydd.LIFE_IGNORE or copydd.LIFE_INSURANCE
    else
        newbtn[1] = copydd.SIGN
        newbtn[4] = copydd.SPACER
        newbtn[5] = copydd.SPACER
        newbtn[6] = copydd.SPACER
        newbtn[7] = copydd.SPACER
    end
    newbtn[2] = copydd.EXTRACT_SOULS
    newbtn[3] = copydd.STORE_SOULS
    inst._spells = newbtn
    inst.components.spellbook:SetItems(newbtn)
end
pas.DoUpdateBtns_c_soul = function(inst, force) --客户端环境。更新按钮轮盘
    pas.DoUpdateBtns_s_soul(inst, ThePlayer)
end
pas.OnUpdateBtnsDirty_soul = function(inst)
	inst:DoTaskInTime(0, pas.DoUpdateBtns_c_soul, true)
end
pas.GetMyData_soul = function(inst)
    local dd = { lvl = inst._soullvl, num = inst._soulnum, map = inst._soulmap }
    if inst:HasTag("bookstay_l") then
        dd.stay = true
    end
    if inst:HasTag("lifeinsure_l") then
        dd.life = true
    end
    if inst.skinname ~= nil and inst.skinname ~= "" then
        dd.skin = inst.skinname
    end
    return dd
end
pas.SetMyData_soul = function(inst, data)
    if data == nil then return end
    if data.stay then
        inst:AddTag("bookstay_l")
    end
    if data.life then
        inst:AddTag("lifeinsure_l")
    end
    if data.skin ~= nil and inst.components.skinedlegion ~= nil then
        inst.components.skinedlegion:SetSkin(data.skin)
    end
    local newlvl = data.lvl or 0
    if data.map ~= nil then
        local newmap = {}
        local maplvl = 0
        for prefabname, v in pairs(data.map) do
            if v == true then
                newmap[prefabname] = true
                maplvl = maplvl + 1
            else --目前就这两个选项
                newmap[prefabname] = 5
                maplvl = maplvl + 5
            end
        end
        inst._soulmap = newmap
        if maplvl ~= newlvl then
            newlvl = maplvl
        end
    end
    pas.TriggerLevel_soul(inst, newlvl)
    if data.num ~= nil and data.num > 0 then
        if data.num >= inst._soullvl then
            inst._soulnum = inst._soullvl
        else
            inst._soulnum = data.num
        end
    end
end
pas.OnSave_soul = function(inst, data)
	data.soulbookdata = inst:GetMyData()
end
pas.OnLoad_soul = function(inst, data)
    if data ~= nil and data.soulbookdata ~= nil then
        inst:SetMyData(data.soulbookdata)
    end
end
pas.TriggerLevel_base_soul = function(book, num, showfx)
    if book._soullvl >= pas.lvls_soul.lvmax then
        return
    end
    num = num + book._soullvl
    if num > pas.lvls_soul.lvmax then
        num = pas.lvls_soul.lvmax
    end
    book._soullvl = num
    book._lvl_l:set(num)
    if showfx then
        book:PushEvent("trytoshowlvlup")
    end
end
pas.TriggerLevel_soul = function(book, num, showfx)
    local oldnum = book._soullvl
    num = num + oldnum
    if num > pas.lvls_soul.lvmax then
        num = pas.lvls_soul.lvmax
    end
    book._soullvl = num
    book._lvl_l:set(num)
    if showfx then
        book:PushEvent("trytoshowlvlup")
    end
    if num >= pas.lvls_soul.lv100 then --100级有新按钮可以用
        book.TriggerLevel = pas.TriggerLevel_base_soul
        book.AddSouls = pas.AddSouls_soul
        if book.task_init == nil then --加载时不需要更新，会延迟更新的
            book._updatespells:push()
            book.UpdateBtns(book, book._user_l:value())
        end
    elseif num >= pas.lvls_soul.lv50 and oldnum < pas.lvls_soul.lv50 then --50级有新按钮可以用
        book.AddSouls = pas.AddSouls_soul
        if book.task_init == nil then
            book._updatespells:push()
            book.UpdateBtns(book, book._user_l:value())
        end
    end
end
pas.Init_soul = function(book, owner)
    if owner ~= nil or not book:IsAsleep() then
        pas.AddEntsListen_soul(book)
    else
        pas.RemoveEntsListen_soul(book)
    end
    if owner ~= nil then
        book:RestartBrain()
    else
        book:StopBrain()
    end
    book.SetLifeInsure(book, book:HasTag("lifeinsure_l"))
    pas.SetRangeCheck_soul(book)
    book._updatespells:push() --更新所有客户端的按钮轮盘
    book.UpdateBtns(book, book._user_l:value())
end
pas.SetOwner_soul = function(book, owner) --签订者的签订与解除
    book._owner_s = owner
    book._owner_l:set(owner)
    book._soulrange = TUNING.WORTOX_SOULEXTRACT_RANGE --20
    book._healrange = TUNING.WORTOX_SOULHEAL_RANGE + 3 --8+3
    book._healmult = 1
    book._heallost = TUNING.WORTOX_SOULHEAL_LOSS_PER_PLAYER --每多一个恢复对象则少回复2点
    if owner == nil then
        book.persists = true --从现在开始自己保存
    else
        book.persists = false --不再自主保存
        if owner.components.skilltreeupdater ~= nil then
            if owner.components.skilltreeupdater:IsActivated("wortox_thief_1") then
                book._soulrange = book._soulrange + TUNING.SKILLS.WORTOX.SOULEXTRACT_RANGE_BONUS --+10，挺广的
            end
            if owner.components.skilltreeupdater:IsActivated("wortox_soulprotector_1") then
                book._healrange = book._healrange + TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_1_RANGE --+3
            end
            if owner.components.skilltreeupdater:IsActivated("wortox_soulprotector_2") then
                book._healrange = book._healrange + TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_2_RANGE --+3
            end
            if owner.components.skilltreeupdater:IsActivated("wortox_soulprotector_3") then
                book._healmult = book._healmult + TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_3_MULT --增加50%治疗量
            end
            if owner.components.skilltreeupdater:IsActivated("wortox_soulprotector_4") then
                book._heallost = book._heallost * TUNING.SKILLS.WORTOX.WORTOX_SOULPROTECTOR_4_LOSS_PER_PLAYER_MULT --2x0.5
            end
        end
    end
    if book._soullvl >= pas.lvls_soul.lv50 or (owner ~= nil and owner:HasTag("soulstealer")) then --50级前会损失灵魂
        book.AddSouls = pas.AddSouls_soul
    else
        book.AddSouls = pas.AddSouls_half_soul
    end
    if book.task_init == nil then --加载时不需要更新，会延迟更新的
        pas.Init_soul(book, owner)
        book:PushEvent("ownerchange")
    end
end
pas.OnEntityWake_soul = function(inst)
    pas.AddEntsListen_soul(inst)
end
pas.OnEntitySleep_soul = function(inst)
    if inst._owner_s ~= nil then --有签订者时保持监听
        pas.AddEntsListen_soul(inst)
    else
        pas.RemoveEntsListen_soul(inst)
    end
end

fns.GetOwnerSoulInfo = function(inst)
    local cpt = inst.components.inventory
    local item, hasemptyslot
    local souls = {}
    local count = 0
    for i = 1, cpt.maxslots, 1 do --先检查物品栏
        item = cpt.itemslots[i]
        if item ~= nil then
            if item.prefab == "wortox_soul" then
                count = count + (item.components.stackable ~= nil and item.components.stackable:StackSize() or 1)
                table.insert(souls, item)
            end
        else
            hasemptyslot = true
        end
    end
    if cpt.activeitem ~= nil then --再检查鼠标栏
        item = cpt.activeitem
        if item.prefab == "wortox_soul" then
            count = count + (item.components.stackable ~= nil and item.components.stackable:StackSize() or 1)
            table.insert(souls, item)
        end
    -- else --看来灵魂并不会直接给予到鼠标栏
    --     hasemptyslot = true
    end
    return count, hasemptyslot, souls
end
fns.GiveSoulsToOwnerSafety = function(owner, num)
    local soulnum, hasemptyslot = fns.GetOwnerSoulInfo(owner)
    if (soulnum > 0 or hasemptyslot) and --既没有灵魂，也没有空格子了，说明没法再放入灵魂了
        soulnum < 20 --懒得判断灵魂罐提高上限什么的了，最安全的限定就是20个
    then
        soulnum = 20 - soulnum
        if num > soulnum then
            num = num - soulnum
        else
            soulnum = num
            num = 0
        end
        local soul = SpawnPrefab("wortox_soul")
        if soulnum > 1 and soul.components.stackable ~= nil then
            soul.components.stackable:SetStackSize(soulnum)
        end
        owner.components.inventory:GiveItem(soul, nil, owner:GetPosition())
        return num, true
    else
        return num, false
    end
end
pas.SetFx_soul = function(book, target) --会改变target滤色的特效
    local x, y, z = target.Transform:GetWorldPosition()
    local fx = SpawnPrefab(book._dd and book._dd.fx or "soul_l_fx")
    fx.Transform:SetPosition(x, y, z)
    fx:Setup(target)
end
pas.AddSouls_soul = function(inst, num, nofx) --添加灵魂
    local hasfx
    local owner = inst._owner_s
    if owner ~= nil and owner:IsValid() then
        if owner:HasTag("soulstealer") then --小恶魔的话，优先给它灵魂，而不是存进契约
            if owner.components.health and not owner.components.health:IsDead() and not owner:HasTag("playerghost") and
                owner.components.inventory and owner.components.inventory.isopen
            then
                local res
                num, res = fns.GiveSoulsToOwnerSafety(owner, num)
                if res and not nofx then
                    pas.SetFx_soul(inst, owner)
                    hasfx = true
                end
                if num < 1 then return end
            end
            owner = nil
        end
    else
        owner = nil
    end
    if inst._soulnum < inst._soullvl then
        local need = inst._soullvl - inst._soulnum
        if num > need then
            inst._soulnum = inst._soullvl
            num = num - need
        else
            inst._soulnum = inst._soulnum + num
            num = 0
        end
        if not nofx then
            if not inst:IsAsleep() then --非加载时，不需要特效
                pas.SetFx_soul(inst, inst)
            end
            hasfx = true
        end
        if num < 1 then return end
    end
    if owner ~= nil and not owner:HasTag("playerghost") and
        owner.components.health and not owner.components.health:IsDead() and
        owner.components.inventory and owner.components.inventory.isopen
    then --其他角色的话，优先给契约灵魂，而不是存到物品栏
        local res
        num, res = fns.GiveSoulsToOwnerSafety(owner, num)
        if res and not nofx then
            pas.SetFx_soul(inst, owner)
            hasfx = true
        end
        if num < 1 then return end
    end
    --多余的灵魂就释放掉。优先以签订者为中心
    local pos
    owner = inst._owner_s
    if owner ~= nil and owner:IsValid() then
        pos = owner:GetPosition()
        if not hasfx and not nofx then
            local fx = SpawnPrefab(inst._dd and inst._dd.bookhealfx or "soulbook_l_fx")
            fx.Transform:SetPosition(pos:Get())
        end
    else
        pos = inst:GetPosition()
        if not hasfx and not nofx and not inst:IsAsleep() then --非加载时，不需要特效
            local fx = SpawnPrefab(inst._dd and inst._dd.bookhealfx or "soulbook_l_fx")
            fx.Transform:SetPosition(pos:Get())
        end
    end
    inst:DoHeal(num, pos)
end
pas.AddSouls_half_soul = function(inst, num, nofx) --添加灵魂，损失50%
    num = num/2
    local soulchance = num - math.floor(num)
    num = math.floor(num)
    if soulchance > 0 and math.random() < soulchance then
        num = num + 1
    end
    if num < 1 then
        return
    end
    pas.AddSouls_soul(inst, num, nofx)
end
pas.TrySpawnSouls_soul = function(book, target, num)
    local range = book._soulrange or TUNING.WORTOX_SOULEXTRACT_RANGE
    local owner = book._owner_s
    if owner ~= nil and owner:IsValid() and (target == owner or owner:IsNear(target, range)) then --靠近签订者
        pas.AddSoulMap_soul(book, target, nil, nil)
        target.nosoultask = target:DoTaskInTime(5, pas.OnRestoreSoul)
        if num == nil then
            num = wortox_soul_common.GetNumSouls(target)
        end
        wortox_soul_common.SpawnSoulsAt(target, num) --在玩家附近肯定是在加载范围内的
    elseif book:IsNear(target, range) then --靠近契约
        pas.AddSoulMap_soul(book, target, nil, nil)
        target.nosoultask = target:DoTaskInTime(5, pas.OnRestoreSoul)
        if num == nil then
            num = wortox_soul_common.GetNumSouls(target)
        end
        if target:IsAsleep() or book:IsAsleep() then --不在加载范围那就直接进契约逻辑
            book:AddSouls(num)
        else
            wortox_soul_common.SpawnSoulsAt(target, num)
        end
    end
end
pas.OnRestoreSoul = function(target)
    target.nosoultask = nil
end
pas.AddSoulMap_soul = function(book, target, dorangetest, dovalidtest) --尝试记入灵魂图
    if book._soulmap[target.prefab] == nil and book._soullvl < pas.lvls_soul.lvmax then
        if dovalidtest ~= nil then
            if not pas.IsValidVictim_soul(target, dovalidtest.explosive) then
                return --不能掉落灵魂的生物，就不记入灵魂图
            end
        end
        if dorangetest then
            local owner = book._owner_s
            if owner ~= nil and owner:IsValid() and (target == owner or owner:IsNear(target, 30)) then --靠近签订者
            elseif book:IsNear(target, 30) then --靠近契约
            else
                return --如果离契约和签订者都挺远的话，那就不能记入灵魂图
            end
        end
        if target:HasTag("epic") then
            book._soulmap[target.prefab] = 5
            book:TriggerLevel(5, true)
        else
            book._soulmap[target.prefab] = true
            book:TriggerLevel(1, true)
        end
    end
end
pas.IsValidVictim_soul = function(victim, explosive)
    return ( (victim.components.combat ~= nil and victim.components.health ~= nil) or victim.components.murderable ~= nil )
        and not victim:HasAnyTag(SOULLESS_TARGET_TAGS)
        and ( (victim.components.health == nil or victim.components.health:IsDead()) or explosive )
end
pas.OnEntDropLoot_soul = function(inst, data) --生物掉落战利品时。记录，生成灵魂
    local victim = data.inst
    if victim == nil or inst.legiontag_deleting or not victim:IsValid() then return end
    if victim.nosoultask == nil then
        if pas.IsValidVictim_soul(victim, data.explosive) then
            pas.TrySpawnSouls_soul(inst, victim, nil)
        end
    else
        pas.AddSoulMap_soul(inst, victim, true, data)
    end
end
pas.OnEntDeath_soul = function(inst, data) --生物死亡时。记录，生成灵魂
    if data.inst ~= nil and not inst.legiontag_deleting then
        data.inst._soulsource = data.afflicter --标记击杀者
        if data.inst.components.lootdropper == nil or data.inst.components.lootdropper.forcewortoxsouls or data.explosive then
            pas.OnEntDropLoot_soul(inst, data)
        else
            if data.inst:IsValid() then
                pas.AddSoulMap_soul(inst, data.inst, true, data)
            end
        end
    end
end
pas.OnStarvedTrapSouls_soul = function(inst, data) --陷阱里的生物饿死时。只生成灵魂
    if data == nil or data.trap == nil or data.trap.nosoultask or not data.trap:IsValid() or
        data.numsouls == nil or data.numsouls < 1 or inst.legiontag_deleting
    then
        return
    end
    pas.TrySpawnSouls_soul(inst, data.trap, data.numsouls)
end
pas.OnMurdered_soul = function(book, inst, data) --物品栏生物被谋杀时。记录，生成灵魂
    local victim = data.victim
    if victim == nil or not victim:IsValid() then return end
    if wortox_soul_common.HasSoul(victim) then
        pas.AddSoulMap_soul(book, victim, nil, nil)
    else
        return
    end
    if data.incinerated then
        return -- NOTES(JBK): Do not give souls for this.
    end
    if victim.nosoultask == nil then
        victim.nosoultask = victim:DoTaskInTime(5, pas.OnRestoreSoul)
        book:AddSouls(wortox_soul_common.GetNumSouls(victim) * (data.stackmult or 1))
    end
end
pas.AddEntsListen_soul = function(inst)
    if inst._onentitydroplootfn == nil then
        inst._onentitydroplootfn = function(src, data) pas.OnEntDropLoot_soul(inst, data) end
        inst:ListenForEvent("entity_droploot", inst._onentitydroplootfn, TheWorld)
    end
    if inst._onentitydeathfn == nil then
        inst._onentitydeathfn = function(src, data) pas.OnEntDeath_soul(inst, data) end
        inst:ListenForEvent("entity_death", inst._onentitydeathfn, TheWorld)
    end
    if inst._onstarvedtrapsoulsfn == nil then
        inst._onstarvedtrapsoulsfn = function(src, data) pas.OnStarvedTrapSouls_soul(inst, data) end
        inst:ListenForEvent("starvedtrapsouls", inst._onstarvedtrapsoulsfn, TheWorld)
    end
end
pas.RemoveEntsListen_soul = function(inst)
    if inst._onentitydroplootfn ~= nil then
        inst:RemoveEventCallback("entity_droploot", inst._onentitydroplootfn, TheWorld)
        inst._onentitydroplootfn = nil
    end
    if inst._onentitydeathfn ~= nil then
        inst:RemoveEventCallback("entity_death", inst._onentitydeathfn, TheWorld)
        inst._onentitydeathfn = nil
    end
    if inst._onstarvedtrapsoulsfn ~= nil then
        inst:RemoveEventCallback("starvedtrapsouls", inst._onstarvedtrapsoulsfn, TheWorld)
        inst._onstarvedtrapsoulsfn = nil
    end
end

pas.btn_scale_soul = 0.6
pas.soulbookhealmult = CONFIGS_LEGION.SOULBOOKHEALMULT or 1.0

pas.DoAction_s_soul = function(doer, book, action) --服务器。执行一个动作
    if doer and doer.components.playercontroller then
        local buffaction = BufferedAction(doer, book, action)
        doer.components.playercontroller:DoAction(buffaction)
    end
end
pas.DoAction_c_soul = function(doer, book, action, cmd, param) --客户端。执行一个动作
    if doer and doer.components.playercontroller then
        local buffaction = BufferedAction(doer, book, action)
        if doer.components.locomotor == nil then
            -- NOTES(JBK): Does not call locomotor component functions needed for pre_action_cb, manual call here.
            if buffaction.action.pre_action_cb then
                buffaction.action.pre_action_cb(buffaction)
            end
            SendModRPCToServer(GetModRPC("LegionMsg", "SoulBookCMD"), book, cmd, param)
        elseif doer.components.playercontroller:CanLocomote() then
            buffaction.preview_cb = function()
                SendModRPCToServer(GetModRPC("LegionMsg", "SoulBookCMD"), book, cmd, param)
            end
            doer.components.playercontroller:DoAction(buffaction)
        end
    end
end
pas.fns_s_soul = { --服务器的操作集合。无洞穴存档的服主会触发
    SIGN = function(book, doer, param)
        pas.DoAction_s_soul(doer or ThePlayer, book, ACTIONS.SOULBOOK_SIGN)
    end,
    EXTRACT_SOULS = function(book, doer, param)
        local player = doer or ThePlayer
        if player then
            if book._owner_s == player then --签订者可以隔空操作
                player.legion_soul_actdist = 1000
            else
                player.legion_soul_actdist = nil
            end
        end
        pas.DoAction_s_soul(player, book, ACTIONS.SOULBOOK_EXTRACT_SOULS)
    end,
    STORE_SOULS = function(book, doer, param)
        local player = doer or ThePlayer
        if player then
            if book._owner_s == player then --签订者可以隔空操作
                player.legion_soul_actdist = 1000
            else
                player.legion_soul_actdist = nil
            end
        end
        pas.DoAction_s_soul(player, book, ACTIONS.SOULBOOK_STORE_SOULS)
    end,
    SHARE_SOULS = function(book, doer, param)
        pas.DoAction_s_soul(doer or ThePlayer, book, ACTIONS.SOULBOOK_SHARE_SOULS)
    end,
    SHARE_LEVEL = function(book, doer, param)
        pas.DoAction_s_soul(doer or ThePlayer, book, ACTIONS.SOULBOOK_SHARE_LEVEL)
    end,
    FOLLOWME = function(book, doer, param)
        local player = doer or ThePlayer
        if player and player.components.soulbookowner ~= nil then
            player.components.soulbookowner:FollowMe(book)
        end
    end,
    LIFE_IGNORE = function(book, doer, param)
        local player = doer or ThePlayer
        if player and player.components.soulbookowner ~= nil then
            player.components.soulbookowner:LifeInsure(book)
        end
    end,
    NotifyWheelIsOpen = function(book, doer, param)
        if param == "1" then --使用者不影响签订者的判定，所以不用判断签订者
            book._user_l:set(doer)
        else
            book._user_l:set(nil)
        end
    end
}
pas.fns_c_soul = { --客户端的操作集合。所有单纯的客户端会触发这里
    SIGN = function(book)
        pas.DoAction_c_soul(ThePlayer, book, ACTIONS.SOULBOOK_SIGN, "SIGN")
    end,
    EXTRACT_SOULS = function(book)
        if book._owner_l:value() == ThePlayer then --签订者可以隔空操作
            ThePlayer.legion_soul_actdist = 1000
        else
            ThePlayer.legion_soul_actdist = nil
        end
        pas.DoAction_c_soul(ThePlayer, book, ACTIONS.SOULBOOK_EXTRACT_SOULS, "EXTRACT_SOULS")
    end,
    STORE_SOULS = function(book)
        if book._owner_l:value() == ThePlayer then --签订者可以隔空操作
            ThePlayer.legion_soul_actdist = 1000
        else
            ThePlayer.legion_soul_actdist = nil
        end
        pas.DoAction_c_soul(ThePlayer, book, ACTIONS.SOULBOOK_STORE_SOULS, "STORE_SOULS")
    end,
    SHARE_SOULS = function(book)
        pas.DoAction_c_soul(ThePlayer, book, ACTIONS.SOULBOOK_SHARE_SOULS, "SHARE_SOULS")
    end,
    SHARE_LEVEL = function(book)
        pas.DoAction_c_soul(ThePlayer, book, ACTIONS.SOULBOOK_SHARE_LEVEL, "SHARE_LEVEL")
    end,
    FOLLOWME = function(book)
        if book._owner_l:value() == ThePlayer then
            SendModRPCToServer(GetModRPC("LegionMsg", "SoulBookCMD"), book, "FOLLOWME")
        end
    end,
    LIFE_IGNORE = function(book)
        if book._owner_l:value() == ThePlayer then
            SendModRPCToServer(GetModRPC("LegionMsg", "SoulBookCMD"), book, "LIFE_IGNORE")
        end
    end
}
pas.buttons_soul = { --按钮数据
    SPACER = { --占位用的
        label = "",
        bank = "ui_l_soulbook", build = "ui_l_soulbook",
        anims = { disabled = { anim = "empty" } },
        widget_scale = pas.btn_scale_soul,
        checkenabled = function() return false end,
        noselect = true, spacer = true
    },
    SIGN = {
		label = STRINGS.COMMANDS_SOUL_CONTRACTS.SIGN,
		onselect = function(inst) --服务器、客户端通用。按钮触发时，操作执行前
			inst.components.spellbook:SetSpellName(STRINGS.COMMANDS_SOUL_CONTRACTS.SIGN)
            inst.components.spellbook.closeonexecute = true --false时，保持轮盘界面不关闭
		end,
		execute = function(bk) --服务器、客户端通用。按钮触发后，开始执行操作
            --能触发这里的，只有不开洞穴档的服主、单纯的客户端玩家，所以用 ThePlayer 来获取操作者
            if bk._bookfns and bk._bookfns["SIGN"] then bk._bookfns["SIGN"](bk) end
        end,
		bank = "ui_l_soulbook", build = "ui_l_soulbook",
		anims = {
			idle = { anim = "sign" },
			focus = { anim = "sign_focus" },
			down = { anim = "sign_pressed" }
		},
		widget_scale = pas.btn_scale_soul, default_focus = nil
	},
    TERMINATE = {
		label = STRINGS.COMMANDS_SOUL_CONTRACTS.TERMINATE,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.COMMANDS_SOUL_CONTRACTS.TERMINATE)
            inst.components.spellbook.closeonexecute = true
		end,
		execute = function(bk) if bk._bookfns and bk._bookfns["SIGN"] then bk._bookfns["SIGN"](bk) end end,
		bank = "ui_l_soulbook", build = "ui_l_soulbook",
		anims = {
			idle = { anim = "terminate" },
			focus = { anim = "terminate_focus" },
			down = { anim = "terminate_pressed" }
		},
		widget_scale = pas.btn_scale_soul
	},
    EXTRACT_SOULS = {
		label = STRINGS.COMMANDS_SOUL_CONTRACTS.EXTRACT_SOULS,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.COMMANDS_SOUL_CONTRACTS.EXTRACT_SOULS)
            inst.components.spellbook.closeonexecute = false
		end,
		execute = function(bk) if bk._bookfns and bk._bookfns["EXTRACT_SOULS"] then bk._bookfns["EXTRACT_SOULS"](bk) end end,
		bank = "ui_l_soulbook", build = "ui_l_soulbook",
		anims = {
			idle = { anim = "soulout" },
			focus = { anim = "soulout_focus" },
			down = { anim = "soulout_pressed" }
		},
		widget_scale = pas.btn_scale_soul
	},
    STORE_SOULS = {
		label = STRINGS.COMMANDS_SOUL_CONTRACTS.STORE_SOULS,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.COMMANDS_SOUL_CONTRACTS.STORE_SOULS)
            inst.components.spellbook.closeonexecute = false
		end,
		execute = function(bk) if bk._bookfns and bk._bookfns["STORE_SOULS"] then bk._bookfns["STORE_SOULS"](bk) end end,
		bank = "ui_l_soulbook", build = "ui_l_soulbook",
		anims = {
			idle = { anim = "soulin" },
			focus = { anim = "soulin_focus" },
			down = { anim = "soulin_pressed" }
		},
		widget_scale = pas.btn_scale_soul
	},
    SHARE_SOULS = {
		label = STRINGS.COMMANDS_SOUL_CONTRACTS.SHARE_SOULS,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.COMMANDS_SOUL_CONTRACTS.SHARE_SOULS)
            inst.components.spellbook.closeonexecute = true
		end,
		execute = function(bk) if bk._bookfns and bk._bookfns["SHARE_SOULS"] then bk._bookfns["SHARE_SOULS"](bk) end end,
		bank = "ui_l_soulbook", build = "ui_l_soulbook",
		anims = {
			idle = { anim = "soulshare" },
			focus = { anim = "soulshare_focus" },
			down = { anim = "soulshare_pressed" }
		},
		widget_scale = pas.btn_scale_soul
	},
    SHARE_LEVEL = {
		label = STRINGS.COMMANDS_SOUL_CONTRACTS.SHARE_LEVEL,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.COMMANDS_SOUL_CONTRACTS.SHARE_LEVEL)
            inst.components.spellbook.closeonexecute = true
		end,
		execute = function(bk) if bk._bookfns and bk._bookfns["SHARE_LEVEL"] then bk._bookfns["SHARE_LEVEL"](bk) end end,
		bank = "ui_l_soulbook", build = "ui_l_soulbook",
		anims = {
			idle = { anim = "lvlshare" },
			focus = { anim = "lvlshare_focus" },
			down = { anim = "lvlshare_pressed" }
		},
		widget_scale = pas.btn_scale_soul
	},
    STAYSTILL = {
		label = STRINGS.COMMANDS_SOUL_CONTRACTS.STAYSTILL,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.COMMANDS_SOUL_CONTRACTS.STAYSTILL)
            inst.components.spellbook.closeonexecute = true
		end,
		execute = function(bk) if bk._bookfns and bk._bookfns["FOLLOWME"] then bk._bookfns["FOLLOWME"](bk) end end,
		bank = "ui_l_soulbook", build = "ui_l_soulbook",
		anims = {
			idle = { anim = "stay" },
			focus = { anim = "stay_focus" },
			down = { anim = "stay_pressed" }
		},
		widget_scale = pas.btn_scale_soul
	},
    FOLLOWME = {
		label = STRINGS.COMMANDS_SOUL_CONTRACTS.FOLLOWME,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.COMMANDS_SOUL_CONTRACTS.FOLLOWME)
            inst.components.spellbook.closeonexecute = true
		end,
		execute = function(bk) if bk._bookfns and bk._bookfns["FOLLOWME"] then bk._bookfns["FOLLOWME"](bk) end end,
		bank = "ui_l_soulbook", build = "ui_l_soulbook",
		anims = {
			idle = { anim = "follow" },
			focus = { anim = "follow_focus" },
			down = { anim = "follow_pressed" }
		},
		widget_scale = pas.btn_scale_soul
	},
    LIFE_INSURANCE = {
		label = pas.soulbookhealmult > 0 and STRINGS.COMMANDS_SOUL_CONTRACTS.LIFE_INSURANCE or
                STRINGS.COMMANDS_SOUL_CONTRACTS.LIFE_INSURANCE_BAN,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(pas.soulbookhealmult > 0 and
                STRINGS.COMMANDS_SOUL_CONTRACTS.LIFE_INSURANCE or STRINGS.COMMANDS_SOUL_CONTRACTS.LIFE_INSURANCE_BAN)
            inst.components.spellbook.closeonexecute = true
		end,
		execute = function(bk) if bk._bookfns and bk._bookfns["LIFE_IGNORE"] then bk._bookfns["LIFE_IGNORE"](bk) end end,
		bank = "ui_l_soulbook", build = "ui_l_soulbook",
		anims = {
			idle = { anim = "heal" },
			focus = { anim = "heal_focus" },
			down = { anim = "heal_pressed" }
		},
		widget_scale = pas.btn_scale_soul
	},
    LIFE_IGNORE = {
		label = STRINGS.COMMANDS_SOUL_CONTRACTS.LIFE_IGNORE,
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(STRINGS.COMMANDS_SOUL_CONTRACTS.LIFE_IGNORE)
            inst.components.spellbook.closeonexecute = true
		end,
		execute = function(bk) if bk._bookfns and bk._bookfns["LIFE_IGNORE"] then bk._bookfns["LIFE_IGNORE"](bk) end end,
		bank = "ui_l_soulbook", build = "ui_l_soulbook",
		anims = {
			idle = { anim = "noheal" },
			focus = { anim = "noheal_focus" },
			down = { anim = "noheal_pressed" }
		},
		widget_scale = pas.btn_scale_soul
	}
}
pas.GetSkinedBtns = function(btns, bank, build)
    local res = {}
    for k, v in pairs(btns) do
        local newv = {}
        for kk, vv in pairs(v) do
            newv[kk] = vv
        end
        newv.bank = bank
        newv.build = build
        res[k] = newv
    end
    return res
end
-- pas.buttons_soul_contracts_taste = pas.GetSkinedBtns(pas.buttons_soul, "ui_l_soulbook_taste", "ui_l_soulbook_taste")
pas.GetSkinedBtns = nil

pas.DealData_soul = function(inst, data)
    local dd = { us = tostring(data.us or 0), usmax = tostring(inst._lvl_l:value()) }
    if data.ow == nil then
        return subfmt(STRINGS.NAMEDETAIL_L.SOULBOOK1, dd)
    else
        dd.ow = data.ow
        return subfmt(STRINGS.NAMEDETAIL_L.SOULBOOK2, dd)
    end
end
pas.GetData_soul = function(inst)
    local data = {}
    if inst._soulnum > 0 then
        data.us = inst._soulnum
    end
    if inst._owner_s ~= nil and inst._owner_s:IsValid() then
        data.ow = inst._owner_s.name or inst._owner_s.userid
    end
    return data
end
fns.IsPlayerFriend = function(v)
    local v_target = v.components.combat.target
    if v_target == nil then
        if TOOLS_L.IsPlayerFollower(v) or
            (v.components.domesticatable ~= nil and v.components.domesticatable:IsDomesticated())
        then
            return true
        end
    elseif not v_target:HasTag("player") then
        if TOOLS_L.IsPlayerFollower(v) or
            (v.components.domesticatable ~= nil and v.components.domesticatable:IsDomesticated() and
                not TOOLS_L.IsPlayerFollower(v_target) --v的仇恨对象不能是玩家的跟随者
            )
        then
            return true
        end
    end
end
pas.DoHeal_soul = function(book, soulnum, pos) --治疗周围的玩家和跟随者
    if pas.soulbookhealmult <= 0 then
        return
    end
    if book._soulnum < 1 and soulnum == nil then
        return
    end
    local healents = {}
    local fxer = {}
    local healplayers = {}
    local count_ents = 0
    local sanityents = {}
    local count_sanitys = 0
    local range = book._healrange or TUNING.WORTOX_SOULHEAL_RANGE
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, range, { "_combat", "_health" }, { "NOCLICK", "INLIMBO" }, nil)
    for _, v in ipairs(ents) do
        if v.entity:IsVisible() then
            local health = v.components.health
            if v:HasTag("player") then
                if not v:HasTag("playerghost") and --Tip: 什么鬼，鬼魂状态的玩家居然不是 health:IsDead()
                    health ~= nil and not health:IsDead()
                then
                    if health:IsHurt() and not v:HasTag("health_as_oldage") and not health:IsInvincible() then
                        table.insert(healplayers, v)
                        count_ents = count_ents + 1
                        health = nil
                    end
                    local mount = v.components.rider ~= nil and v.components.rider:GetMount() or nil --骑着的动物
                    if mount and mount.components.health ~= nil and mount.components.health:IsHurt() then
                        table.insert(healents, mount)
                        if health ~= nil then --说明骑乘者不需要加血
                            table.insert(fxer, v) --用以补充特效
                        end
                        count_ents = count_ents + 1
                    end
                    if v._souloverloadtask == nil and v.components.sanity and v:HasTag("soulstealer") then
                        table.insert(sanityents, v)
                        count_sanitys = count_sanitys + 1
                    end
                end
            elseif v.components.combat ~= nil and --判定周围玩家的跟随者和部分友好生物
                health ~= nil and not health:IsDead() and not health:IsInvincible() and health:IsHurt() and
                fns.IsPlayerFriend(v)
            then
                table.insert(healents, v)
                count_ents = count_ents + 1
            end
        end
    end
    if count_ents > 0 then
        local healfx = book._dd and book._dd.healfx or "soulheal_l_fx"
        local heallost = book._heallost or TUNING.WORTOX_SOULHEAL_LOSS_PER_PLAYER
        local amt = math.max(TUNING.WORTOX_SOULHEAL_MINIMUM_HEAL, TUNING.HEALING_MED - heallost*(count_ents-1))
        if soulnum ~= nil then
            if soulnum > 1 then --先整数运算
                amt = amt * soulnum
            end
        else --消耗契约的灵魂
            book._soulnum = book._soulnum - 1
        end
        if book._healmult ~= nil then --再小数运算
            amt = amt * book._healmult
        end
        if pas.soulbookhealmult ~= 1 then
            amt = amt * pas.soulbookhealmult
        end
        for _, v in ipairs(healplayers) do --玩家加血
            if v.wortox_inclination == "naughty" then --是淘气包的小恶魔回复量降低25%
                v.components.health:DoDelta(amt*TUNING.SKILLS.WORTOX.NAUGHTY_SOULHEAL_RECEIVED_MULT, nil, book.prefab)
            else
                v.components.health:DoDelta(amt, nil, book.prefab)
            end
            if v.components.combat and v.components.combat.hiteffectsymbol then
                local fx = SpawnPrefab(healfx)
                fx.Follower:FollowSymbol(v.GUID, v.components.combat.hiteffectsymbol, 0, -50, 0)
                fx:Setup(v)
            end
        end
        -- amt = amt * 2 --对非玩家的生物回复量加倍。还是算了，契约本身已经很超模了
        for _, v in ipairs(healents) do --非玩家的加血
            v.components.health:DoDelta(amt, nil, book.prefab)
            if not (v:IsAsleep() or v:IsInLimbo()) and v.components.combat and v.components.combat.hiteffectsymbol then
                local fx = SpawnPrefab(healfx)
                fx.Follower:FollowSymbol(v.GUID, v.components.combat.hiteffectsymbol, 0, -50, 0)
                fx:Setup(v)
            end
        end
        for _, v in ipairs(fxer) do --特效补充
            if v.components.combat and v.components.combat.hiteffectsymbol then
                local fx = SpawnPrefab(healfx)
                fx.Follower:FollowSymbol(v.GUID, v.components.combat.hiteffectsymbol, 0, -50, 0)
                fx:Setup(v)
            end
        end
        if book.task_life ~= nil and book._soulnum >= 1 then --既然开启了生命保险，那就直接判断是否还需要继续回血
            local needheal
            for _, v in ipairs(healplayers) do
                if v.components.health:GetPercentWithPenalty() <= 0.9 then
                    needheal = true
                    break
                end
            end
            if not needheal then
                for _, v in ipairs(healents) do
                    if v.components.health:GetPercent() <= 0.8 then
                        needheal = true
                        break
                    end
                end
            end
            if needheal then
                book._needheal = true
            end
        end
    end
    if count_sanitys > 0 then
        local amt = TUNING.SANITY_TINY * 0.5 --5x0.5
        if soulnum ~= nil and soulnum > 1 then
            amt = amt * soulnum
        end
        for _, v in ipairs(sanityents) do
            if v.wortox_inclination == "nice" then
                v.components.sanity:DoDelta(amt * TUNING.SKILLS.WORTOX.NICE_SANITY_MULT) --x2
            elseif v.wortox_inclination == "naughty" then
                v.components.sanity:DoDelta(amt * TUNING.SKILLS.WORTOX.NAUGHTY_SANITY_MULT) --x0
            else
                v.components.sanity:DoDelta(amt)
            end
        end
    end
end
pas.CheckHeal_soul = function(book)
    if book:IsAsleep() or book._soulnum < 1 or book._owner_s == nil or not book._owner_s:IsValid() then
        return
    end
    if book._needheal then
        book:PushEvent("trytoheal")
        return
    end
    local x, y, z = book._owner_s.Transform:GetWorldPosition()
    local range = book._healrange or TUNING.WORTOX_SOULHEAL_RANGE
    local ents = TheSim:FindEntities(x, y, z, range, { "_combat", "_health" }, { "NOCLICK", "INLIMBO" }, nil)
    range = false
    for _, v in ipairs(ents) do
        if v.entity:IsVisible() then
            local health = v.components.health
            if v:HasTag("player") then
                if not v:HasTag("playerghost") and health ~= nil and not health:IsDead() then
                    if not v:HasTag("health_as_oldage") and not health:IsInvincible() and
                        health:GetPercentWithPenalty() <= 0.9 --损失了10%血量
                    then
                        range = true
                        break
                    end
                    local mount = v.components.rider ~= nil and v.components.rider:GetMount() or nil --骑着的动物
                    if mount and mount.components.health ~= nil and mount.components.health:GetPercent() <= 0.8 then
                        range = true
                        break
                    end
                end
            elseif v.components.combat ~= nil and --判定周围玩家的跟随者和部分友好生物
                health ~= nil and not health:IsDead() and not health:IsInvincible() and
                health:GetPercent() <= 0.8 and --损失了20%血量
                fns.IsPlayerFriend(v)
            then
                range = true
                break
            end
        end
    end
    if range then
        book._needheal = true
        book:PushEvent("trytoheal")
    end
end
pas.SetLifeInsure_soul = function(inst, ison)
    if ison and pas.soulbookhealmult > 0 and inst._owner_s ~= nil then
        if inst.task_life == nil then
            inst.task_life = inst:DoPeriodicTask(2, pas.CheckHeal_soul, 1+3*math.random())
        end
    else
        if inst.task_life ~= nil then
            inst.task_life:Cancel()
            inst.task_life = nil
        end
        inst._needheal = nil
    end
end
pas.CheckRange_soul = function(book)
    if book._owner_s == nil or not book._owner_s:IsValid() then
        book._needteleport = nil
        return
    end
    if book._needteleport then
        book:PushEvent("trytoteleport")
        return
    end
    local p1x, p1y, p1z = book.Transform:GetWorldPosition()
    local p2x, p2y, p2z = book._owner_s.Transform:GetWorldPosition()
    p1y = distsq(p1x, p1z, p2x, p2z)
    if book:HasTag("bookstay_l") then --禁足了，那就可以再远很多
        book._needteleport = p1y >= 10000
    else
        book._needteleport = p1y >= 625
    end
    if book._needteleport then
        book:PushEvent("trytoteleport")
    end
end
pas.SetRangeCheck_soul = function(inst)
    if inst._owner_s ~= nil then
        if inst.task_range == nil then
            inst.task_range = inst:DoPeriodicTask(6, pas.CheckRange_soul, 3+3*math.random())
        end
    else
        if inst.task_range ~= nil then
            inst.task_range:Cancel()
            inst.task_range = nil
        end
        inst._needteleport = nil
    end
end
pas.ShareSouls_soul = function(book)
    local owner = book._owner_s
    if book._soulnum < 1 then
        if owner ~= nil and owner.components.talker ~= nil then
            owner.components.talker:Say(GetString(owner, "DESCRIBE", { "SOUL_CONTRACTS", "SOULLESS" }))
        end
        return
    end
    local num = book._soulnum
    local x, y, z = book.Transform:GetWorldPosition()
    local range = book._healrange or TUNING.WORTOX_SOULHEAL_RANGE
    local ents = TheSim:FindEntities(x, y, z, range, { "soulcontracts" }, { "NOCLICK", "INLIMBO" }, nil)
    range = true
    for _, v in ipairs(ents) do
        if v ~= book and v.entity:IsVisible() and not v.legiontag_deleting and v._soulnum ~= nil then
            range = false
            if v._soulnum < v._soullvl then
                local need = v._soullvl - v._soulnum
                if need >= num then
                    v._soulnum = v._soulnum + num
                    num = 0
                else
                    v._soulnum = v._soullvl
                    num = num - need
                end
                book.SetSoulFx(book, v)
                if num < 1 then
                    break
                end
            end
        end
    end
    if range then
        if owner ~= nil and owner.components.talker ~= nil then
            owner.components.talker:Say(GetString(owner, "DESCRIBE", { "SOUL_CONTRACTS", "NOBOOK" }))
        end
    elseif num >= book._soulnum then
        if owner ~= nil and owner.components.talker ~= nil then
            owner.components.talker:Say(GetString(owner, "DESCRIBE", { "SOUL_CONTRACTS", "BOOKISFULL" }))
        end
    else
        book._soulnum = num
        local fx = SpawnPrefab(book._dd and book._dd.booksharesoulfx or "soulbook_share2_l_fx")
        fx.Transform:SetPosition(x, y+2, z)
        book.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/hop_out")
    end
end
pas.ShareLevel_soul = function(book)
    local owner = book._owner_s
    local needsoul, lvlup
    local num = book._soulnum
    local cost = 10
    local x, y, z = book.Transform:GetWorldPosition()
    local range = book._healrange or TUNING.WORTOX_SOULHEAL_RANGE
    local ents = TheSim:FindEntities(x, y, z, range, { "soulcontracts" }, { "NOCLICK", "INLIMBO" }, nil)
    range = true
    for _, v in ipairs(ents) do
        if v ~= book and v.entity:IsVisible() and not v.legiontag_deleting and v._soulmap ~= nil then
            range = false --代表周围有契约
            local vm = v._soulmap
            local vnum = v._soulnum
            local lvls = 0
            for prefabname, vv in pairs(book._soulmap) do
                if vm[prefabname] == nil then
                    if (num + vnum) >= cost then
                        if vnum >= cost then --优先消耗其他契约的灵魂
                            vnum = vnum - cost
                        else
                            local left = cost
                            if vnum > 0 then
                                left = left - vnum
                                vnum = 0
                            end
                            if num > 0 then
                                if left >= num then
                                    num = 0
                                else
                                    num = num - left
                                end
                            end
                        end
                        vm[prefabname] = vv
                        lvls = lvls + (vv == true and 1 or 5)
                    else
                        needsoul = true --代表仍有灵魂图没有传授完成
                        break
                    end
                end
            end
            if lvls > 0 then
                lvlup = true --代表有契约升级了
                v._soulnum = vnum
                v:TriggerLevel(lvls, true)
            end
        end
    end
    if range then
        if owner ~= nil and owner.components.talker ~= nil then
            owner.components.talker:Say(GetString(owner, "DESCRIBE", { "SOUL_CONTRACTS", "NOBOOK" }))
        end
        return
    end
    if lvlup then
        book._soulnum = num
        local fx = SpawnPrefab(book._dd and book._dd.booksharelvlfx or "soulbook_share1_l_fx")
        fx.Transform:SetPosition(x, y, z)
        book.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/hop_out")
    end
    if needsoul then --还未完成，说明仍需要灵魂
        if owner ~= nil and owner.components.talker ~= nil then
            owner.components.talker:Say(GetString(owner, "DESCRIBE", { "SOUL_CONTRACTS", "SOULLESS" }))
        end
    elseif not lvlup then --已完成，并且本次没有升级过，说明等级都够了
        if owner ~= nil and owner.components.talker ~= nil then
            owner.components.talker:Say(GetString(owner, "DESCRIBE", { "SOUL_CONTRACTS", "BOOKISHIGH" }))
        end
    end
end

table.insert(prefs, Prefab("soul_contracts", function() --物品栏的灵魂契约
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    -- inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    -- inst.MiniMapEntity:SetIcon("soul_contracts.tex") --不要地图图标了，不然会让地图上到处都是契约图标

    MakeFlyingCharacterPhysics(inst, 1, .5)
    inst.DynamicShadow:SetSize(1.3, .6)

    inst.AnimState:SetBank("book_maxwell")
    inst.AnimState:SetBuild("soul_contracts")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetScale(0.9, 0.9, 0.9)
    inst.AnimState:HideSymbol("shadow")
    inst.Transform:SetTwoFaced()

    inst:AddTag("soulcontracts")
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("NOBLOCK")
    inst:AddTag("flying")
    inst:AddTag("meteor_protection") --防止被流星破坏
    inst:AddTag("noattack") --防止被巨型蠕虫吃掉

    inst._updatespells = net_event(inst.GUID, "soul_contracts._updatespells")
    inst._lvl_l = net_ushortint(inst.GUID, "soul_contracts._lvl_l", "lvl_l_dirty")
    inst._lvl_l:set_local(0)
    inst._owner_l = net_entity(inst.GUID, "soul_contracts._owner_l", "owner_l_dirty") --签订者
    inst._owner_l:set_local(nil)
    inst._user_l = net_entity(inst.GUID, "soul_contracts._user_l", "user_l_dirty") --使用者
    inst._user_l:set_local(nil)
    inst._spells = {}
    local spellbook = inst:AddComponent("spellbook")
    -- spellbook:SetRequiredTag("ghostlyfriend")
	spellbook:SetRadius(125) --轮盘半径
	spellbook:SetFocusRadius(128) --获取到焦点时的半径
	spellbook:SetCanUseFn(pas.CanUseCMDs_soul)
	-- spellbook:SetShouldOpenFn(ShouldOpenWobyCommands)
	spellbook:SetOnOpenFn(pas.OnOpenUI_soul)
	spellbook:SetOnCloseFn(pas.OnCloseUI_soul)
	-- spellbook:SetItems(inst._spells)
	-- spellbook:SetBgData(SPELLBOOK_BG) --按钮轮盘界面背景，不搞这个，不然还得手动设置各个按钮位置
    spellbook.opensound = "dontstarve/common/together/book_maxwell/use"
	spellbook.closesound = "dontstarve/common/together/book_maxwell/close"

    TOOLS_L.InitMouseInfo(inst, pas.DealData_soul, pas.GetData_soul)
    LS_C_Init(inst, "soul_contracts", false)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then --单纯的客户端
        inst._bookfns = pas.fns_c_soul
        inst:ListenForEvent("soul_contracts._updatespells", pas.OnUpdateBtnsDirty_soul)
		-- pas.OnUpdateBtnsDirty_soul(inst)
        return inst
    end

    -- inst._dd = {}
    inst._bookfns = pas.fns_s_soul
    inst.UpdateBtns = pas.DoUpdateBtns_s_soul
    inst.GetMyData = pas.GetMyData_soul
    inst.SetMyData = pas.SetMyData_soul
    inst.AddSouls = pas.AddSouls_half_soul
    inst.TriggerLevel = pas.TriggerLevel_soul
    inst.SetBookOwner = pas.SetOwner_soul
    inst.SetLifeInsure = pas.SetLifeInsure_soul
    inst.OnMurdered = pas.OnMurdered_soul
    inst.SetSoulFx = pas.SetFx_soul
    inst.DoHeal = pas.DoHeal_soul
    inst.ShareSouls = pas.ShareSouls_soul
    inst.ShareLevel = pas.ShareLevel_soul
    inst.GetOwnerSoulInfo = fns.GetOwnerSoulInfo
    -- inst._owner_s = nil
    inst._soulnum = 0 --灵魂数量
    inst._soullvl = 0 --契约等级
    inst._soulmap = {} --灵魂图
    inst._tag_moving3 = 0
    inst._soulrange = TUNING.WORTOX_SOULEXTRACT_RANGE --20
    inst._healrange = TUNING.WORTOX_SOULHEAL_RANGE + 3 --8+3
    inst._healmult = 1
    inst._heallost = TUNING.WORTOX_SOULHEAL_LOSS_PER_PLAYER --2

    inst:AddComponent("inspectable")

    inst:AddComponent("colourtweener")

    -- inst:AddComponent("inventoryitem")
    -- inst.components.inventoryitem.canonlygoinpocket = true --只能放进物品栏中，不能放进箱子、背包等容器内
    -- inst.components.inventoryitem.imagename = "soul_contracts"
    -- inst.components.inventoryitem.atlasname = "images/inventoryimages/soul_contracts.xml"
    -- inst.components.inventoryitem.pushlandedevents = false
    -- inst.components.inventoryitem.nobounce = true
    -- inst.components.inventoryitem.canbepickedup = false --无法被直接捡起来

    -- inst:AddComponent("follower") --这个组件只是说会在静止状态时自动瞬移到主人附近，但我有自己的跟随机制，不需要官方的逻辑
    -- inst.components.follower.CachePlayerLeader = EmptyCptFn --不想它在重进世界时出错了还跟着玩家
    -- inst.components.follower.keepdeadleader = true
    -- inst.components.follower.keepleaderduringminigame = true

    local locomotor = inst:AddComponent("locomotor") --移动组件必须比状态机 SetStateGraph 先执行！
    locomotor.walkspeed = 7
    locomotor.runspeed = 7
    locomotor:EnableGroundSpeedMultiplier(false)
    locomotor.pathcaps = { ignorewalls = true, allowocean = true } --能直接穿墙移动、海上飞行
    locomotor:SetTriggersCreep(false) --不会触发蜘蛛网警告

    inst:SetBrain(brain_contracts)
    inst:SetStateGraph("SGsoul_contracts")

    inst.OnSave = pas.OnSave_soul
	inst.OnLoad = pas.OnLoad_soul
    inst.OnEntityWake = pas.OnEntityWake_soul
    inst.OnEntitySleep = pas.OnEntitySleep_soul

    inst.task_init = inst:DoTaskInTime(0.1+math.random()*0.4, function()
        inst.task_init = nil
        pas.Init_soul(inst, inst._owner_s)
    end)

    return inst
end, {
    Asset("ANIM", "anim/book_maxwell.zip"), --官方暗影秘典动画模板
    Asset("ANIM", "anim/soul_contracts.zip"),
    -- Asset("ATLAS", "images/inventoryimages/soul_contracts.xml"),
    -- Asset("IMAGE", "images/inventoryimages/soul_contracts.tex"),
    -- Asset("ATLAS_BUILD", "images/inventoryimages/soul_contracts.xml", 256),
    Asset("SCRIPT", "scripts/prefabs/wortox_soul_common.lua") --官方灵魂通用功能函数文件
}, {
    "soul_l_fx", --灵魂被吸收时的特效
    "soulheal_l_fx" --灵魂治愈目标时的特效
}))

--------------------------------------------------------------------------
--[[ 威尔逊 ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ 薇诺娜 ]]
--------------------------------------------------------------------------

--全息组件

--------------------------------------------------------------------------
--[[ 沃姆伍德 ]]
--------------------------------------------------------------------------

--花园铲

--------------------------------------------------------------------------
--[[ 沃利 ]]
--------------------------------------------------------------------------

--便携式烧烤架

--------------------
--------------------

return unpack(prefs)

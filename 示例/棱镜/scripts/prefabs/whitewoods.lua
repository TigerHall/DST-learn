local prefs = {}
local pas = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local TOOLS_L = require("tools_legion")

local function SetWorkable2(inst, onworked, onfinished, actname, workleft) --可破坏组件2
    inst.components.workable:SetWorkAction(ACTIONS[actname or "DIG"])
    inst.components.workable:SetWorkLeft(workleft or 1)
    inst.components.workable:SetOnWorkCallback(onworked)
    inst.components.workable:SetOnFinishCallback(onfinished)
end

--------------------------------------------------------------------------
--[[ 白木吉他 ]]
--------------------------------------------------------------------------

local TIME_FOURHANDSPLAY = 1.5
local RANGE_FOURHANDSPLAY = 10
local RANGE_PLAY = 20
local COST_HUNGER = -0.5
local TYPE_PLAY = "normal"

local function SpawnFx(fx, target, scale, xOffset, yOffset, zOffset)
    local fx = SpawnPrefab(fx)

    if fx then
        fx.Transform:SetNoFaced()
        xOffset = xOffset or 0 --控制前后
        yOffset = yOffset or 0 --控制高度
        zOffset = zOffset or 0 --控制左右

        -- if target.components.rider ~= nil and target.components.rider:IsRiding() then
        --     yOffset = yOffset + 2.3
        --     xOffset = xOffset + 0.5
        --     zOffset = zOffset + 0.5
        -- end

        target:AddChild(fx)
        fx.Transform:SetPosition(xOffset, yOffset, zOffset)

        scale = scale or 1
        fx.Transform:SetScale(scale, scale, scale)
    end

    return fx
end

local function PlayFail(inst, owner, talktype)
    if talktype ~= nil and owner.components.talker ~= nil then
        owner.components.talker:Say(GetString(owner, "DESCRIBE", { "GUITAR_WHITEWOOD", talktype }))
    end
    owner:PushEvent("playenough")
    if inst.playtask ~= nil then
        inst.playtask:Cancel()
        inst.playtask = nil
    end
end
local function PlayStart(inst, owner)
    owner.AnimState:OverrideSymbol("swap_guitar", "swap_guitar_whitewood", "swap_guitar_whitewood")

    --开始联弹等待阶段
    if owner.fourhands_task ~= nil then
        owner.fourhands_task:Cancel()
    end
    owner.fourhands_playtype = TYPE_PLAY
    owner.fourhands_valid = nil
    owner.fourhands_myleader = nil
    owner.fourhands_status = 1
    owner.fourhands_task = inst:DoTaskInTime(TIME_FOURHANDSPLAY, function()
        owner.fourhands_task = nil
        --主弹才播放音乐
        if owner.fourhands_status == 1 then
            local songs = owner.fourhands_valid and {
                "legion/guitar_songs/never_end_love",
                "legion/guitar_songs/let_her_go"
            } or {
                "legion/guitar_songs/town",
                "legion/guitar_songs/viva_la_vida"
            }

            for _, fn in pairs(GUITARSONGSPOOL_LEGION) do
                if fn then
                    local res = fn(inst, owner, owner.fourhands_valid, songs, TYPE_PLAY)
                    if res and res == "override" then
                        return
                    end
                end
            end
            owner.SoundEmitter:PlaySound(songs[math.random(#songs)], "guitarsong_l")
            owner.SoundEmitter:SetVolume("guitarsong_l", 0.5)
        end
    end)

    --判断周围是否有在弹琴的玩家，如果有，自己就是副弹，没有自己就是主弹
    local x, y, z = owner.Transform:GetWorldPosition()
    for i, v in ipairs(AllPlayers) do
        if
            v ~= owner and
            v.entity:IsVisible() and
            not (v.components.health:IsDead() or v:HasTag("playerghost")) and
            v.fourhands_playtype == TYPE_PLAY and --只判断同类型的吉他
            v:GetDistanceSqToPoint(x, y, z) < RANGE_PLAY * RANGE_PLAY and --距离要够
            v.sg ~= nil and v.sg:HasStateTag("playguitar") and v.fourhands_status == 1 --只判断正在弹的主弹
        then
            --主弹不在联弹等待阶段，或者范围不在联弹有效范围，则自己弹奏失败
            if v.fourhands_task == nil or v:GetDistanceSqToPoint(x, y, z) > RANGE_FOURHANDSPLAY * RANGE_FOURHANDSPLAY then
                owner.fourhands_status = -1 --弹奏失败
            else
                if v.fourhands_valid == nil then --告知主弹这次是联弹
                    v.fourhands_valid = {}
                end
                table.insert(v.fourhands_valid, owner)

                owner.fourhands_myleader = v --记下本次联弹的主弹对象
                owner.fourhands_status = 0  --确定自己副弹的位置

                --产生联弹成功的特效
                inst:DoTaskInTime(math.random(), function()
                    if v:IsValid() and v.entity:IsVisible() then
                        SpawnFx("battlesong_attach", v, 0.6)
                    end
                    if owner:IsValid() and owner.entity:IsVisible() then
                        SpawnFx("battlesong_attach", owner, 0.6)
                    end
                end)
            end
            break
        end
    end
end
local function PlayDoing(inst, owner)
    owner.AnimState:PlayAnimation("soothingplay_loop", true) --之所以把动画改到这里而不是写进sg中，是为了兼容多种弹奏动画。建议写进PlayStart，并改造一下sg

    --尝试联弹失败，弹奏也失败
    if owner.fourhands_status == -1 then
        PlayFail(inst, owner, 'FAILED')
        SpawnFx("battlesong_detach", owner, 0.6)
        return
    end

    --饥饿值没了也无法弹奏
    if owner.components.hunger ~= nil and owner.components.hunger:IsStarving() then
        PlayFail(inst, owner, 'HUNGRY')
        return
    end

    inst.components.fueled:StartConsuming() --开始损坏

    if inst.playtask ~= nil then
        inst.playtask:Cancel()
    end
    inst.playcount = -1 --从-1开始，为了第一次就生效
    inst.playtask = inst:DoPeriodicTask(1,
        owner.fourhands_status == 1 and
        function() --主弹逻辑：效果实施
            if not owner:IsValid() then
                return
            end

            local x, y, z = owner.Transform:GetWorldPosition()
            for i, v in ipairs(AllPlayers) do
                if
                    v.entity:IsVisible() and
                    not (v.components.health:IsDead() or v:HasTag("playerghost")) and
                    v:GetDistanceSqToPoint(x, y, z) < RANGE_PLAY * RANGE_PLAY
                then
                    if v.components.sanity ~= nil then
                        --第二个参数能使数值变化时不播放音效
                        v.components.sanity:DoDelta(owner.fourhands_valid and 1 or 0.5, true)
                    end
                end
            end

            if owner.components.hunger ~= nil then
                --第二个参数能使数值变化时不播放音效
                owner.components.hunger:DoDelta(COST_HUNGER, true)
                if owner.components.hunger:IsStarving() then
                    PlayFail(inst, owner, 'HUNGRY')
                    return
                end
            end

            inst.playcount = inst.playcount + 1
            if inst.playcount % 5 == 0 then --每五秒照料一次作物
                local ents = TheSim:FindEntities(x, y, z, RANGE_PLAY, { "tendable_farmplant" }, { "INLIMBO" })
                for _,v in ipairs(ents) do
                    if v.components.farmplanttendable ~= nil then
                        v.components.farmplanttendable:TendTo(owner)
                    end
                end
                inst.playcount = 0
            end
        end or
        function() --副弹逻辑：监听主弹弹奏状态
            if
                owner.fourhands_myleader == nil or
                not owner.fourhands_myleader:IsValid() or
                not owner.fourhands_myleader.entity:IsVisible() or
                owner.fourhands_myleader.sg == nil or not owner.fourhands_myleader.sg:HasStateTag("playguitar")
            then
                PlayFail(inst, owner, nil)
            else
                if owner.components.hunger ~= nil then
                    owner.components.hunger:DoDelta(COST_HUNGER, true)
                    if owner.components.hunger:IsStarving() then
                        PlayFail(inst, owner, 'HUNGRY')
                        return
                    end
                end
            end
        end,
    1)

    --弹奏时的特效
    if inst.fxtask ~= nil then
        inst.fxtask:Cancel()
    end
    inst.fxtask = inst:DoPeriodicTask(0.5, function()
        if not owner:IsValid() then
            return
        end
        local x, y, z = owner.Transform:GetWorldPosition()
        local rad = math.random(0.5, 1.5)
        local angle = math.random() * 2 * PI
        local fx = SpawnPrefab("guitar_whitewood_doing_fx")
        if fx then
            fx.Transform:SetNoFaced()
            fx.Transform:SetScale(0.4, 0.4, 0.4)
            fx.Transform:SetPosition(x + rad * math.cos(angle), y, z - rad * math.sin(angle))
        end
    end, 0.5)
end
local function PlayEnd(inst, owner)
    if owner.fourhands_status == 1 then
        owner.SoundEmitter:KillSound("guitarsong_l")
    end

    if inst.playtask ~= nil then
        inst.playtask:Cancel()
        inst.playtask = nil
    end
    if inst.fxtask ~= nil then
        inst.fxtask:Cancel()
        inst.fxtask = nil
    end
    inst.playcount = nil
    if owner.fourhands_task ~= nil then
        owner.fourhands_task:Cancel()
        owner.fourhands_task = nil
    end
    owner.fourhands_valid = nil
    owner.fourhands_myleader = nil
    owner.fourhands_status = nil

    if inst.broken then --损坏了，消失
        inst:Remove()
    else                --还没坏，停止损坏
        inst.components.fueled:StopConsuming()
    end
end

local function OnFinished(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner ~= nil then
        owner:PushEvent("playenough")
    end
    inst.broken = true
end

table.insert(prefs, Prefab("guitar_whitewood", function()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("guitar")

    inst.AnimState:SetBank("guitar_whitewood")
    inst.AnimState:SetBuild("guitar_whitewood")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryFloatable(inst, "med", 0.3, 0.6)
    local OnLandedClient_old = inst.components.floater.OnLandedClient
    inst.components.floater.OnLandedClient = function(self)
        OnLandedClient_old(self)
        self.inst.AnimState:SetFloatParams(0.1, 1, self.bob_percent)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")

    inst:AddComponent("instrument")

    inst.PlayStart = PlayStart
    inst.PlayDoing = PlayDoing
    inst.PlayEnd = PlayEnd

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.GUITAR
    inst.components.fueled:InitializeFuelLevel(TUNING.TOTAL_DAY_TIME) --1天
    inst.components.fueled:SetDepletedFn(OnFinished)
    inst.components.fueled.accepting = true

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "guitar_whitewood"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/guitar_whitewood.xml"

    MakeHauntableLaunch(inst)

    return inst
end, {
    Asset("ANIM", "anim/guitar_whitewood.zip"),
    Asset("ANIM", "anim/swap_guitar_whitewood.zip"),
    Asset("ATLAS", "images/inventoryimages/guitar_whitewood.xml"),
    Asset("IMAGE", "images/inventoryimages/guitar_whitewood.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/guitar_whitewood.xml", 256)
}, {
    "battlesong_attach",
    "battlesong_detach",
    "guitar_whitewood_doing_fx",
}))

--------------------------------------------------------------------------
--[[ 白木地片 ]]
--------------------------------------------------------------------------

table.insert(prefs, Prefab("mat_whitewood_item", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("deploykititem") --为了让deployable组件的摆放动作显示为“放置”

    inst.AnimState:SetBank("mat_whitewood")
    inst.AnimState:SetBuild("mat_whitewood")
    inst.AnimState:PlayAnimation("item")

    MakeInventoryFloatable(inst, "med", 0.3, 0.8)
    local OnLandedClient_old = inst.components.floater.OnLandedClient
    inst.components.floater.OnLandedClient = function(self)
        OnLandedClient_old(self)
        self.inst.AnimState:SetFloatParams(0.1, 1, self.bob_percent)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "mat_whitewood_item"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/mat_whitewood_item.xml"

    inst:AddComponent("z_repairerlegion")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.WOOD
    inst.components.edible.healthvalue = 0
    inst.components.edible.hungervalue = 0

    inst:AddComponent("deployable")
    inst.components.deployable.ondeploy = function(inst, pt, deployer, rot)
        local tree = SpawnPrefab("mat_whitewood")
        if tree ~= nil then
            tree.Transform:SetPosition(pt:Get())
            inst.components.stackable:Get():Remove()
            tree.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
        end
    end
    -- inst.components.deployable:SetDeployMode(DEPLOYMODE.WALL)
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    MakeHauntableLaunch(inst)

    return inst
end, {
    Asset("ANIM", "anim/mat_whitewood.zip"),
    Asset("ATLAS", "images/inventoryimages/mat_whitewood_item.xml"),
    Asset("IMAGE", "images/inventoryimages/mat_whitewood_item.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/mat_whitewood_item.xml", 256)
}, { "mat_whitewood" }))

table.insert(prefs, Prefab("mat_whitewood", function()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    -- MakeObstaclePhysics(inst, .5)

    inst:AddTag("playerowned") --不会被投石机破坏
    inst:AddTag("NOBLOCK")

    inst.AnimState:SetBank("mat_whitewood")
    inst.AnimState:SetBuild("mat_whitewood")
    inst.AnimState:PlayAnimation("idle1")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    -- inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(function(inst)
        inst.components.lootdropper:DropLoot()

        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("wood")

        inst:Remove()
    end)

    inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.MAT_L
    inst.components.upgradeable.onupgradefn = function(inst, doer, item)
        inst.SoundEmitter:PlaySound("dontstarve/common/place_structure_wood")
    end
    inst.components.upgradeable.onstageadvancefn = function(inst)
        local stagenow = inst.components.upgradeable:GetStage()
        inst.AnimState:PlayAnimation("idle"..tostring(stagenow))

        stagenow = math.floor(stagenow/2)
        if stagenow > 0 then
            local loots = {}
            for i = 1, stagenow, 1 do
                table.insert(loots, "mat_whitewood_item")
            end
            inst.components.lootdropper:SetLoot(loots)
        else
            inst.components.lootdropper:SetLoot(nil)
        end
    end
    inst.components.upgradeable.numstages = 5
    inst.components.upgradeable.upgradesperstage = 1

    inst.OnLoad = function(inst, data) --由于 upgradeable 组件不会自己重新初始化，只能这里再初始化
        inst.components.upgradeable.onstageadvancefn(inst)
    end

    return inst
end, { Asset("ANIM", "anim/mat_whitewood.zip") }, { "mat_whitewood_item" }))

--------------------------------------------------------------------------
--[[ 白木展示台、白木展示柜 ]]
--------------------------------------------------------------------------

local invPrefabList = require("mod_inventoryprefabs_list")  --mod中有物品栏图片的prefabs的表
local invBuildMaps = {
    "images_minisign1", "images_minisign2", "images_minisign3",
    "images_minisign4", "images_minisign5", "images_minisign6",
    "images_minisign_skins1", "images_minisign_skins2" --7、8
}

local function SetShowSlot(inst, slot)
    local item = inst.components.container.slots[slot]
    if item == nil then
        inst.AnimState:ClearOverrideSymbol("slot"..tostring(slot))
        inst.AnimState:ClearOverrideSymbol("slotbg"..tostring(slot))
    else
        local atlas, bgimage, bgatlas
        local image = FunctionOrValue(item.drawimageoverride, item, inst) or (#(item.components.inventoryitem.imagename or "") > 0 and item.components.inventoryitem.imagename) or item.prefab or nil
        if image ~= nil then
            atlas = FunctionOrValue(item.drawatlasoverride, item, inst) or (#(item.components.inventoryitem.atlasname or "") > 0 and item.components.inventoryitem.atlasname) or nil
            if item.inv_image_bg ~= nil and item.inv_image_bg.image ~= nil and item.inv_image_bg.image:len() > 4 and item.inv_image_bg.image:sub(-4):lower() == ".tex" then
                bgimage = item.inv_image_bg.image:sub(1, -5)
                bgatlas = item.inv_image_bg.atlas ~= GetInventoryItemAtlas(item.inv_image_bg.image) and item.inv_image_bg.atlas or nil
            end

            if invPrefabList[image] ~= nil then
                inst.AnimState:OverrideSymbol("slot"..tostring(slot), invBuildMaps[invPrefabList[image]] or invBuildMaps[1], image)
            else
                if atlas ~= nil then
                    atlas = resolvefilepath_soft(atlas) --为了兼容mod物品，不然是没有这道工序的
                end
                inst.AnimState:OverrideSymbol("slot"..tostring(slot), atlas or GetInventoryItemAtlas(image..".tex"), image..".tex")
            end
            if bgimage ~= nil then
                if invPrefabList[bgimage] ~= nil then
                    inst.AnimState:OverrideSymbol("slotbg"..tostring(slot), invBuildMaps[invPrefabList[bgimage]] or invBuildMaps[1], bgimage)
                else
                    if bgatlas ~= nil then
                        bgatlas = resolvefilepath_soft(bgatlas) --为了兼容mod物品，不然是没有这道工序的
                    end
                    inst.AnimState:OverrideSymbol("slotbg"..tostring(slot), bgatlas or GetInventoryItemAtlas(bgimage..".tex"), bgimage..".tex")
                end
            else
                inst.AnimState:ClearOverrideSymbol("slotbg"..tostring(slot))
            end
        else
            inst.AnimState:ClearOverrideSymbol("slot"..tostring(slot))
            inst.AnimState:ClearOverrideSymbol("slotbg"..tostring(slot))
        end
    end
end
local function ItemGet_chest(inst, data)
    if data and data.slot and data.slot <= inst.shownum_l then
        SetShowSlot(inst, data.slot)
    end
end
local function ItemLose_chest(inst, data)
    if data and data.slot and data.slot <= inst.shownum_l then
        SetShowSlot(inst, data.slot)
    end
end

local function OnOpen_chest(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("open")
        if inst.skin_open_sound then
            inst.SoundEmitter:PlaySound(inst.skin_open_sound)
        else
            inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
        end
    end
end
local function OnClose_chest(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("close")
        inst.AnimState:PushAnimation("closed", false)
        if inst.skin_close_sound then
            inst.SoundEmitter:PlaySound(inst.skin_close_sound)
        else
            inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
        end
        for i = 1, inst.shownum_l, 1 do
            SetShowSlot(inst, i)
        end
    end
end
local function OnHit_chest(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.container ~= nil then
            inst.components.container:DropEverything()
            inst.components.container:Close()
        end
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
    end
end
local function OnHammered_chest(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function OnSave_chest(inst, data)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() or inst:HasTag("burnt") then
        data.burnt = true
    end
end
local function OnLoad_chest(inst, data)
    if data ~= nil then
        if data.burnt and inst.components.burnable ~= nil then
            inst.components.burnable.onburnt(inst)
        end
    end
end
local function OnSave_chest_inf(inst, data)
    if inst.legiontag_chestupgraded then
        data.legiontag_chestupgraded = true
    end
end
local function OnLoad_chest_inf(inst, data)
    if data ~= nil then
        if data.legiontag_chestupgraded then
            inst.legiontag_chestupgraded = true
        end
    end
end

local function OnEntityReplicated_chest(inst)
    if inst.replica.container ~= nil then --烧毁后 container 组件会被移除
        inst.replica.container:WidgetSetup("chest_whitewood")
    end
end
local function OnEntityReplicated_chest2(inst)
    if inst.replica.container ~= nil then --烧毁后 container 组件会被移除
        inst.replica.container:WidgetSetup("chest_whitewood_big")
    end
end

local function OnHit_chest_inf(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("closed", false)
    inst.components.container:Close()
    if worker == nil or not worker:HasTag("player") then --只能被玩家破坏。没必要弄烂箱子设定
        inst.components.workable:SetWorkLeft(inst.shownum_l == 3 and 2 or 4)
        return
    end
    inst.components.container:DropEverything(nil, true)
    if not inst.components.container:IsEmpty() then --如果箱子里还有物品，那就不能被破坏
        inst.components.workable:SetWorkLeft(inst.shownum_l == 3 and 2 or 4)
    end
end
local function OnHammered_chest_inf(inst, worker)
    local box = SpawnPrefab(inst.shownum_l == 3 and "chest_whitewood" or "chest_whitewood_big")
    if box ~= nil then
        local skin = inst.components.skinedlegion:GetSkin()
        if skin ~= nil then
            box.components.skinedlegion:SetSkin(skin, LS_C_UserID(inst, worker))
        end
        box.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
    if inst.legiontag_chestupgraded then
        inst.components.lootdropper:SpawnLootPrefab("chestupgrader_l")
    else
        inst.components.lootdropper:SpawnLootPrefab("chestupgrade_stacksize")
    end
    OnHammered_chest(inst, worker)
end
local function OnUpgrade_chest_inf(inst, item, doer)
    local is_chestupgrader_l = item:HasTag("chestupgrader_l")
    if item.components.stackable ~= nil then
		item.components.stackable:Get(1):Remove()
	else
		item:Remove()
	end
    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("chestupgrade_stacksize_fx")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
    end
    local newbox = SpawnPrefab(inst.prefab.."_inf")
    if newbox ~= nil then
        local skin = inst.components.skinedlegion:GetSkin()
        if skin ~= nil then
            newbox.components.skinedlegion:SetSkin(skin, LS_C_UserID(inst, doer))
        end
        newbox.legiontag_chestupgraded = is_chestupgrader_l --表明这是用月石角撑升级的

        --继承能力勋章的不朽等级
        local cpt = inst.components.medal_immortal
        if cpt ~= nil and newbox.components.medal_immortal ~= nil then
            local ilvl = cpt.GetLevel ~= nil and cpt:GetLevel() or 0
            if ilvl > 0 and cpt.SetImmortal ~= nil then
                newbox.components.medal_immortal:SetImmortal(ilvl)
            end
        end

        newbox.Transform:SetPosition(x, y, z)

        --将原箱子中的物品转移到新箱子中
        cpt = inst.components.container
        if cpt ~= nil then
            cpt:Close() --强制关闭使用中的箱子
            cpt.canbeopened = false
            if not cpt:IsEmpty() then
                if newbox.components.container ~= nil then
                    local allitems = cpt:RemoveAllItems()
                    for _, v in ipairs(allitems) do
                        v.Transform:SetPosition(x, y, z) --防止放不进容器时，掉在世界原点
                        newbox.components.container:GiveItem(v)
                    end
                else
                    cpt:DropEverything()
                end
            end
        end
    end
    inst:Remove()
end

local function MakeChest(data)
    table.insert(prefs, Prefab(data.name, function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon("chest_whitewood.tex")
        inst:SetDeploySmartRadius(0.5) --建造半径的一半

        inst:AddTag("structure")
        inst:AddTag("chest")
        inst:AddTag("playerowned") --不会被投石机破坏

        if data.fn_common ~= nil then
            data.fn_common(inst)
        end
        inst.AnimState:PlayAnimation("closed")

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.shownum_l = 3

        inst:AddComponent("inspectable")

        inst:AddComponent("container")
        inst.components.container.onopenfn = OnOpen_chest
        inst.components.container.onclosefn = OnClose_chest
        inst.components.container.skipclosesnd = true
        inst.components.container.skipopensnd = true

        inst:AddComponent("lootdropper")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

        TOOLS_L.MakeSnowCovered_serv(inst)

        -- inst:ListenForEvent("onbuilt", onbuilt)
        inst:ListenForEvent("itemget", ItemGet_chest)
        inst:ListenForEvent("itemlose", ItemLose_chest)

        if data.fn_server ~= nil then
            data.fn_server(inst)
        end

        if TUNING.FUNCTIONAL_MEDAL_IS_OPEN then
            SetImmortalable(inst, 2, nil)
        end

        return inst
    end, data.assets, data.prefabs))
end

MakeChest({
    name = "chest_whitewood",
    assets = {
        Asset("ANIM", "anim/chest_whitewood.zip"),
        Asset("ANIM", "anim/ui_chester_shadow_3x4.zip"),
        Asset("ANIM", "anim/ui_chest_whitewood_3x4.zip")
    },
    prefabs = { "chest_whitewood_inf", "chestupgrade_stacksize_fx" },
    fn_common = function(inst)
        inst:AddTag("chest_upgradeable") --能被 弹性空间制造器 升级
        -- inst:AddTag("chestupgradeable_l") --能被 月石角撑 升级
        inst.AnimState:SetBank("chest_whitewood")
        inst.AnimState:SetBuild("chest_whitewood")
        LS_C_Init(inst, "chest_whitewood", false)
        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = OnEntityReplicated_chest
        end
    end,
    fn_server = function(inst)
        inst.shownum_l = 3
        inst.legionfn_chestupgrade = OnUpgrade_chest_inf
        inst.OnSave = OnSave_chest
        inst.OnLoad = OnLoad_chest

        inst.components.container:WidgetSetup("chest_whitewood")

        inst.components.workable:SetWorkLeft(2)
        inst.components.workable:SetOnWorkCallback(OnHit_chest)
        inst.components.workable:SetOnFinishCallback(OnHammered_chest)

        MakeMediumBurnable(inst, nil, nil, true)
        MakeMediumPropagator(inst)
    end
})
MakeChest({
    name = "chest_whitewood_inf",
    assets = {
        Asset("ANIM", "anim/chest_whitewood_inf.zip"),
        Asset("ANIM", "anim/ui_chester_shadow_3x4.zip"),
        Asset("ANIM", "anim/ui_chest_whitewood_inf_3x4.zip")
    },
    prefabs = { "chestupgrade_stacksize" },
    fn_common = function(inst)
        inst.AnimState:SetBank("chest_whitewood")
        inst.AnimState:SetBuild("chest_whitewood_inf")
        LS_C_Init(inst, "chest_whitewood", false, "data_inf", "chest_whitewood_inf")
        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = OnEntityReplicated_chest
        end
    end,
    fn_server = function(inst)
        inst.shownum_l = 3
        inst.OnSave = OnSave_chest_inf
        inst.OnLoad = OnLoad_chest_inf

        inst.components.container:WidgetSetup("chest_whitewood")
        inst.components.container:EnableInfiniteStackSize(true)

        inst.components.workable:SetWorkLeft(2)
        inst.components.workable:SetOnWorkCallback(OnHit_chest_inf)
        inst.components.workable:SetOnFinishCallback(OnHammered_chest_inf)
    end
})

MakeChest({
    name = "chest_whitewood_big",
    assets = {
        Asset("ANIM", "anim/chest_whitewood_big.zip"),
        Asset("ANIM", "anim/ui_bookstation_4x5.zip"),
        Asset("ANIM", "anim/ui_chest_whitewood_4x6.zip")
    },
    prefabs = { "chest_whitewood_big_inf", "chestupgrade_stacksize_fx" },
    fn_common = function(inst)
        inst:AddTag("chest_upgradeable") --能被 弹性空间制造器 升级
        -- inst:AddTag("chestupgradeable_l") --能被 月石角撑 升级
        inst.AnimState:SetBank("chest_whitewood_big")
        inst.AnimState:SetBuild("chest_whitewood_big")
        LS_C_Init(inst, "chest_whitewood_big", false)
        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = OnEntityReplicated_chest2
        end
    end,
    fn_server = function(inst)
        inst.shownum_l = 8
        inst.legionfn_chestupgrade = OnUpgrade_chest_inf
        inst.OnSave = OnSave_chest
        inst.OnLoad = OnLoad_chest

        inst.components.container:WidgetSetup("chest_whitewood_big")

        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnWorkCallback(OnHit_chest)
        inst.components.workable:SetOnFinishCallback(OnHammered_chest)

        MakeLargeBurnable(inst, nil, nil, true)
        MakeLargePropagator(inst)
    end
})
MakeChest({
    name = "chest_whitewood_big_inf",
    assets = {
        Asset("ANIM", "anim/chest_whitewood_big_inf.zip"),
        Asset("ANIM", "anim/ui_bookstation_4x5.zip"),
        Asset("ANIM", "anim/ui_chest_whitewood_inf_4x6.zip")
    },
    prefabs = { "chestupgrade_stacksize" },
    fn_common = function(inst)
        inst.AnimState:SetBank("chest_whitewood_big")
        inst.AnimState:SetBuild("chest_whitewood_big_inf")
        LS_C_Init(inst, "chest_whitewood_big", false, "data_inf", "chest_whitewood_big_inf")
        if not TheWorld.ismastersim then
            inst.OnEntityReplicated = OnEntityReplicated_chest2
        end
    end,
    fn_server = function(inst)
        inst.shownum_l = 8
        inst.OnSave = OnSave_chest_inf
        inst.OnLoad = OnLoad_chest_inf

        inst.components.container:WidgetSetup("chest_whitewood_big")
        inst.components.container:EnableInfiniteStackSize(true)

        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnWorkCallback(OnHit_chest_inf)
        inst.components.workable:SetOnFinishCallback(OnHammered_chest_inf)
    end
})

--------------------------------------------------------------------------
--[[ 稀有基质培植盆 ]]
--------------------------------------------------------------------------

pas.SporeSleep_pot = function(inst)
    if inst.components.periodicspawner ~= nil then
        inst.components.periodicspawner:Stop()
    end
end
pas.SporeWake_pot = function(inst)
    if inst.components.periodicspawner ~= nil and inst.components.periodicspawner.target_time == nil then
        inst.components.periodicspawner:Start()
    end
end
pas.Stage_pot_spore = function(inst, fruitnum, time, spore)
    if fruitnum >= 4 and not inst:HasTag("lifeless_l") then
        if inst.components.periodicspawner == nil then
            inst:AddComponent("periodicspawner")
        end
        local cpt = inst.components.periodicspawner
        cpt:SetPrefab(spore)
        cpt:SetIgnoreFlotsamGenerator(true)
        cpt:SetRandomTimes(time, 5, true)
        cpt.OnSave = nil --附加组件，不需要保存啥的
        cpt.OnLoad = nil
        if inst:IsAsleep() then
            cpt:Stop()
        elseif cpt.target_time == nil then
            cpt:Start()
        end
        inst.OnEntitySleep = pas.SporeSleep_pot
        inst.OnEntityWake = pas.SporeWake_pot
    else
        if inst.components.periodicspawner ~= nil then inst:RemoveComponent("periodicspawner") end
        inst.OnEntitySleep = nil
        inst.OnEntityWake = nil
    end
end
pas.OnSpawn_pot_moonspore = function(inst, spore) --官方逻辑
    spore._alwaysinstantpops = true
end
pas.GetSpawnPoint_pot_moonspore = function(inst) --官方逻辑
    local pos = inst:GetPosition()
    local offset = FindWalkableOffset(pos, math.random() * TWOPI, GetRandomMinMax(0.5, 3.5), 4)
    if offset ~= nil then
        return pos + offset
    end
    return pos
end
pas.Stage_pot_moonspore = function(inst, fruitnum, time)
    if fruitnum >= 4 and not inst:HasTag("lifeless_l") then
        if inst.components.periodicspawner == nil then
            inst:AddComponent("periodicspawner")
        end
        local cpt = inst.components.periodicspawner
        cpt:SetPrefab("spore_moon")
        cpt:SetIgnoreFlotsamGenerator(true)
        cpt:SetRandomTimes(time, 0.25, true)
        cpt:SetOnSpawnFn(pas.OnSpawn_pot_moonspore)
        cpt:SetGetSpawnPointFn(pas.GetSpawnPoint_pot_moonspore)
        cpt.OnSave = nil
        cpt.OnLoad = nil
        if inst:IsAsleep() then
            cpt:Stop()
        elseif cpt.target_time == nil then
            cpt:Start()
        end
        inst.OnEntitySleep = pas.SporeSleep_pot
        inst.OnEntityWake = pas.SporeWake_pot
    else
        if inst.components.periodicspawner ~= nil then inst:RemoveComponent("periodicspawner") end
        inst.OnEntitySleep = nil
        inst.OnEntityWake = nil
    end
end
pas.RandomSpore_pot = function(inst)
    local spores = { "spore_tall", "spore_medium", "spore_small" }
    return spores[math.random(1, 3)]
end

pas.Stage_pot_wormlight = function(inst, fruitnum, radmult)
    local fx = inst._potlight
    if fruitnum >= 1 and not inst:HasTag("lifeless_l") then
        if fx == nil or not fx:IsValid() then
            fx = SpawnPrefab("heatrocklight")
            fx.Light:SetIntensity(0.8)
            fx.Light:SetFalloff(0.5)
            fx.Light:SetColour(1, 1, 1)
            fx.entity:SetParent(inst.entity)
            inst._potlight = fx
            fx = inst._plant
            if fx ~= nil and fx:IsValid() then
                fx.AnimState:SetSymbolLightOverride("wormlight", 0.4)
                fx.AnimState:SetSymbolLightOverride("wormlight2", 0.4)
            end
            fx = inst._potlight
        end
        local rad = 0.7 --2.8/4
        if radmult ~= nil then
            rad = rad * radmult
        end
        fx.Light:SetRadius(rad*fruitnum)
        fx.Light:Enable(true)
    else
        if fx ~= nil then
            if fx:IsValid() then
                fx:Remove()
            end
            inst._potlight = nil
            fx = inst._plant
            if fx ~= nil and fx:IsValid() then
                fx.AnimState:SetSymbolLightOverride("wormlight", 0)
                fx.AnimState:SetSymbolLightOverride("wormlight2", 0)
            end
        end
    end
end
pas.Stage_pot_wormlight_s = function(inst, fruitnum)
    pas.Stage_pot_wormlight(inst, fruitnum, 0.7)
end

local potFertilityMax = 160
local potLvlUpMap = {
    red_cap = { shroom_skin="red_fungus" }, --用 蘑菇皮 升级
    green_cap = { shroom_skin="green_fungus" },
    blue_cap = { shroom_skin="blue_fungus" },
    moon_cap = { shroom_skin="moon_fungus" },
    albicans_cap = { shroom_skin="albicans_fungus" },
    wormlight_s = { yots_redlantern="worm_lantern_s" }, --用 蠕虫年红灯笼 升级
    wormlight = { yots_redlantern="worm_lantern" }
}
local potPlants = { --培植盆植物表
    -- lightbulb = { --荧光果
    --     pri=1, --优先级
    --     fruitname="lightbulb", --果实代码名
    --     fruitnum=4, --每个阶段会增加的果实数量
    --     growtime=2.5, --每个阶段的时间
    --     nomaxlvl=true, --是否不能达到4阶段。空值代表能达到，也代表着采摘后可以继续生长
    --     lvlup={ key="value" }, --key:升级物prefab名，value:升级后培植盆植物表的key。只有某物品能给多种植物升级时才设置该参数
    --     sourceloot="loot" --种植来源物prefab
    -- },
    -- tissue_l_lightbulb = { pri=3, fruitname="lightbulb", fruitnum=5, growtime=2 }, --荧光花活性组织
    succulent_picked = { pri=1, fruitname="succulent_picked", fruitnum=3, growtime=6, nomaxlvl=true }, --多肉植物
    foliage = { pri=1, fruitname="foliage", fruitnum=3, growtime=4.5, nomaxlvl=true }, --蕨叶
    cutlichen = { pri=1, fruitname="cutlichen", fruitnum=3, growtime=9, nomaxlvl=true }, --苔藓

    bean_l_ice = { pri=1, fruitname="bean_l_ice", fruitnum=3, growtime=9, nomaxlvl=true }, --冰皂豆

    red_cap = { --红蘑菇
        pri=1, fruitname="red_cap", fruitnum=3, growtime=6, nomaxlvl=true, lvlup=potLvlUpMap.red_cap,
        smearkey="POT_FUNGUS"
    },
    spore_medium = { --红色孢子
        pri=2, fruitname="red_cap", fruitnum=3, growtime=5.5, nomaxlvl=true, lvlup=potLvlUpMap.red_cap,
        smearkey="POT_FUNGUS"
    },
    red_mushroomhat = { --红蘑菇帽
        pri=3, fruitname="red_cap", fruitnum=3, growtime=4.5, lvlup=potLvlUpMap.red_cap, smearkey="POT_FUNGUS",
        stagefn = function(inst, fruitnum)
            pas.Stage_pot_spore(inst, fruitnum, 60, "spore_medium")
        end
    },
    red_fungus = { --蘑菇皮
        pri=4, fruitname="red_cap", fruitnum=4, growtime=3.5, sourceloot="shroom_skin", smearkey="POT_FUNGUS",
        stagefn = function(inst, fruitnum)
            pas.Stage_pot_spore(inst, fruitnum, 25, "spore_medium")
        end
    },

    green_cap = { --绿蘑菇
        pri=1, fruitname="green_cap", fruitnum=3, growtime=6, nomaxlvl=true, lvlup=potLvlUpMap.green_cap,
        smearkey="POT_FUNGUS"
    },
    spore_small = { --绿色孢子
        pri=2, fruitname="green_cap", fruitnum=3, growtime=5.5, nomaxlvl=true, lvlup=potLvlUpMap.green_cap,
        smearkey="POT_FUNGUS"
    },
    green_mushroomhat = { --绿蘑菇帽
        pri=3, fruitname="green_cap", fruitnum=3, growtime=4.5, lvlup=potLvlUpMap.green_cap, smearkey="POT_FUNGUS",
        stagefn = function(inst, fruitnum)
            pas.Stage_pot_spore(inst, fruitnum, 60, "spore_small")
        end
    },
    green_fungus = { --蘑菇皮
        pri=4, fruitname="green_cap", fruitnum=4, growtime=3.5, sourceloot="shroom_skin", smearkey="POT_FUNGUS",
        stagefn = function(inst, fruitnum)
            pas.Stage_pot_spore(inst, fruitnum, 25, "spore_small")
        end
    },

    blue_cap = { --蓝蘑菇
        pri=1, fruitname="blue_cap", fruitnum=3, growtime=6, nomaxlvl=true, lvlup=potLvlUpMap.blue_cap,
        smearkey="POT_FUNGUS"
    },
    spore_tall = { --蓝色孢子
        pri=2, fruitname="blue_cap", fruitnum=3, growtime=5.5, nomaxlvl=true, lvlup=potLvlUpMap.blue_cap,
        smearkey="POT_FUNGUS"
    },
    blue_mushroomhat = { --蓝蘑菇帽
        pri=3, fruitname="blue_cap", fruitnum=3, growtime=4.5, lvlup=potLvlUpMap.blue_cap, smearkey="POT_FUNGUS",
        stagefn = function(inst, fruitnum)
            pas.Stage_pot_spore(inst, fruitnum, 60, "spore_tall")
        end
    },
    blue_fungus = { --蘑菇皮
        pri=4, fruitname="blue_cap", fruitnum=4, growtime=3.5, sourceloot="shroom_skin", smearkey="POT_FUNGUS",
        stagefn = function(inst, fruitnum)
            pas.Stage_pot_spore(inst, fruitnum, 25, "spore_tall")
        end
    },

    moon_cap = { --月亮蘑菇
        pri=1, fruitname="moon_cap", fruitnum=3, growtime=8, nomaxlvl=true, lvlup=potLvlUpMap.moon_cap,
        smearkey="POT_FUNGUS"
    },
    moon_mushroomhat = { --月亮蘑菇帽
        pri=3, fruitname="moon_cap", fruitnum=3, growtime=6.5, lvlup=potLvlUpMap.moon_cap, smearkey="POT_FUNGUS",
        stagefn = function(inst, fruitnum)
            pas.Stage_pot_moonspore(inst, fruitnum, 8)
        end
    },
    moon_fungus = { --蘑菇皮
        pri=4, fruitname="moon_cap", fruitnum=4, growtime=5.5, sourceloot="shroom_skin", smearkey="POT_FUNGUS",
        stagefn = function(inst, fruitnum)
            pas.Stage_pot_moonspore(inst, fruitnum, 2)
        end
    },

    albicans_cap = { --素白菇
        pri=1, fruitname="albicans_cap", fruitnum=3, growtime=8, nomaxlvl=true, lvlup=potLvlUpMap.albicans_cap,
        smearkey="POT_FUNGUS"
    },
    hat_albicans_mushroom = { --素白蘑菇帽
        pri=3, fruitname="albicans_cap", fruitnum=3, growtime=6, lvlup=potLvlUpMap.albicans_cap, smearkey="POT_FUNGUS",
        stagefn = function(inst, fruitnum)
            pas.Stage_pot_spore(inst, fruitnum, 50, pas.RandomSpore_pot)
        end
    },
    albicans_fungus = { --蘑菇皮
        pri=4, fruitname="albicans_cap", fruitnum=4, growtime=5.5, sourceloot="shroom_skin", smearkey="POT_FUNGUS",
        stagefn = function(inst, fruitnum)
            pas.Stage_pot_spore(inst, fruitnum, 20, pas.RandomSpore_pot)
        end
    },

    wormlight_lesser = { --小发光浆果
        pri=1, fruitname="wormlight_lesser", fruitnum=3, growtime=8, nomaxlvl=true, lvlup=potLvlUpMap.wormlight_s,
        stagefn = pas.Stage_pot_wormlight_s, smearkey="POT_WORMLIGHT"
    },
    worm_lantern_s = { --小发光浆果
        pri=2, fruitname="wormlight_lesser", fruitnum=3, growtime=6, sourceloot="yots_redlantern", smearkey="POT_WORMLIGHT",
        stagefn = pas.Stage_pot_wormlight_s, sourcename = STRINGS.NAMES.REDLANTERN --蠕虫年红灯笼 的名字比较特殊
    },

    wormlight = { --发光浆果
        pri=1, fruitname="wormlight", fruitnum=3, growtime=9, nomaxlvl=true, lvlup=potLvlUpMap.wormlight,
        stagefn = pas.Stage_pot_wormlight, smearkey="POT_WORMLIGHT"
    },
    worm_lantern = { --发光浆果
        pri=2, fruitname="wormlight", fruitnum=3, growtime=7, sourceloot="yots_redlantern", smearkey="POT_WORMLIGHT",
        stagefn = pas.Stage_pot_wormlight, sourcename = STRINGS.NAMES.REDLANTERN
    },
    --要是以后有巨型蠕虫的掉落物就可以继续升级了
}
local potAnims = {
    succulent_picked = 5, foliage = 5, red_cap = 2, green_cap = 2, blue_cap = 2, moon_cap = 2, albicans_cap = 2,
    wormlight_lesser = 3, wormlight = 3, cutlichen = 3, bean_l_ice = 3
}
local potAnimBuilds = { --【【【【【记得同步设置打蜡那边的数据！！！！！】】】】】
    wormlight_lesser = "pot_whitewood2", wormlight = "pot_whitewood2", cutlichen = "pot_whitewood2",
    bean_l_ice = "pot_whitewood2"
}
local potFerts = {
    slurtleslime = 1, --蛞蝓龟黏液
    jammypreserves = 2, --果酱
    phlegm = 2, --脓鼻涕
    glommerfuel = 3, --格罗姆的黏液
    berrysauce = 3, --快乐浆果酱
    shroomcake = 3, --蘑菇蛋糕
    livinglog = 3, --活木
    livingtree_root = 8, --完全正常的树根
    treegrowthsolution = 10, --树果酱
    compostwrap = 20, --肥料包
    dish_shyerryjam = 40, --颤栗果酱
    weisuo_silvery_kela = 10, --【猥琐联盟】银坷垃
    weisuo_golden_kela = 30, --【猥琐联盟】金坷垃
    spice_poop = 10, --【能力勋章】秘制酱料
}
local potUpdater = {
    oceanfish_small_6_inv = true, --落叶比目鱼
    oceanfish_medium_8_inv = true, --冰鲷鱼
    oceanfish_small_7_inv = true, --花朵金枪鱼
    oceanfish_small_8_inv = true, --炽热太阳鱼
    book_gardening = true, --应用园艺学
    book_horticulture = true, --园艺学简编版
    book_horticulture_upgraded = true, --园艺学扩展版
}

local function SetSoilSymbol_pot(inst, isout) --肥料没了时切换土壤贴图
    if inst._dd ~= nil and inst._dd.soilfn ~= nil then
        inst._dd.soilfn(inst, isout)
    else
        if isout then
            inst.AnimState:OverrideSymbol("asoil", inst.AnimState:GetBuild() or "pot_whitewood", "asoilout")
            if inst._plant ~= nil then
                inst._plant.AnimState:OverrideSymbol("asoil", inst.AnimState:GetBuild() or "pot_whitewood", "asoilout")
            end
        else
            inst.AnimState:ClearOverrideSymbol("asoil")
            if inst._plant ~= nil then
                -- inst._plant.AnimState:ClearOverrideSymbol("asoil") --不能直接clear，需要兼容皮肤
                inst._plant.AnimState:OverrideSymbol("asoil", inst.AnimState:GetBuild() or "pot_whitewood", "asoil")
            end
        end
    end
end
local function OnWorked_pot(inst, worker, workleft, numworks)
    if inst._dd ~= nil and inst._dd.workedfn ~= nil then
        inst._dd.workedfn(inst, worker, workleft)
    else
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle", false)
    end
end
local function OnFinished_pot(inst, worker) --被破坏掉
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()

    local pos = inst:GetPosition()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(pos:Get())
    fx:SetMaterial("wood")

    local num = inst._fertility - potFerts.dish_shyerryjam --因为本身要返还一个颤栗果酱，所以这里得扣除一个果酱的数值
    if num >= potFerts.treegrowthsolution then --返还肥料，不需要考虑果实
        num = math.floor(num / potFerts.treegrowthsolution)
        TOOLS_L.SpawnStackDrop("treegrowthsolution", num, pos, nil, nil, { dropper = inst })
    end
    inst:Remove()
end
local function OnWorked_pot_f(inst, worker) --单纯的被挖掉植株而已
    if inst._growdd ~= nil then
        if inst._fruitnum > 0 then --返还果实
            local dd = inst._growdd
            local loots = {}
            local sets = { dropper = inst }
            local pos = inst:GetPosition()
            if inst._fruitnum >= 4 then --满级时会返还来源物
                loots[dd.sourceloot or dd.source] = 1
            end
            loots[dd.fruitname] = inst._fruitnum*dd.fruitnum + (loots[dd.fruitname] or 0)
            for item, num in pairs(loots) do
                TOOLS_L.SpawnStackDrop(item, num, pos, nil, nil, sets)
            end
        end
    end
    inst.components.growable:SetStage(1) --停止生长
    inst.components.growable:StopGrowing()
end

local function GetMaxStage_pot(inst)
    return inst._growdd.nomaxlvl and 3 or 4
end
local function GetStatus_pot(inst)
    if inst._growdd == nil then
        return inst._fertility <= 0 and "BARREN" or "GENERIC"
    end
    if inst._fruitnum <= 1 then
        return inst._fertility <= 0 and "BARREN" or "ALITTLE"
    elseif inst._fruitnum >= GetMaxStage_pot(inst) then
        return "LOTS"
    else
        return inst._fertility <= 0 and "BARREN" or "SOME"
    end
end
local function GetFruits_pot(inst, doer)
    if inst._fruitnum > 0 and inst._growdd ~= nil then
        TOOLS_L.SpawnStackDrop(inst._growdd.fruitname, inst._fruitnum*inst._growdd.fruitnum,
            inst:GetPosition(), doer, nil, { dropper = inst })
    end
end

local function SetGrowDD_pot(inst, source, growmult, maxlvl, animkey)
    local model = potPlants[source]
    local newdd = {
        pri = model.pri, fruitname = model.fruitname, fruitnum = model.fruitnum,
        growtime = model.growtime, source = source, stagefn = model.stagefn,
        lvlup = model.lvlup, sourceloot = model.sourceloot
    }
    if growmult ~= nil and growmult ~= 1 and growmult > 0 then
        newdd.growmult = growmult
    end
    if not maxlvl then
        newdd.nomaxlvl = model.nomaxlvl
    end
    if animkey ~= nil and potAnims[model.fruitname] >= animkey then
        newdd.animkey = animkey
    else
        newdd.animkey = math.random(potAnims[model.fruitname])
    end
    inst._growdd = newdd
end
local function OnGetItem_pot(inst, giver, source, growmult, maxlvl, animkey)
    if giver ~= nil then
        local skill = giver.components.skilltreeupdater
        if giver:HasTag("genesis_gaia") then --大地之力
            maxlvl = true
            if growmult > 0.9 then
                growmult = 0.9
            end
        end
        if skill ~= nil then
            local gmult
            if skill:IsActivated("wormwood_mushroomplanter_ratebonus2") then
                gmult = TUNING.WORMWOOD_MUSHROOMPLANTER_RATEBONUS_2 --0.8，加速20%
            elseif skill:IsActivated("wormwood_mushroomplanter_ratebonus1") then
                gmult = TUNING.WORMWOOD_MUSHROOMPLANTER_RATEBONUS_1 --0.9，加速10%
            end
            if gmult ~= nil and gmult < growmult then --加速越快就越小，找出最小值
                growmult = gmult
            end
            if not maxlvl then
                maxlvl = skill:IsActivated("wormwood_mushroomplanter_upgrade")
            end
        end
    end
    SetGrowDD_pot(inst, source, growmult, maxlvl, animkey) --更新数据
    inst.components.growable:SetStage(2) --重新开始生长
    inst.components.growable:StartGrowing()
end
local function AcceptTest_pot(inst, item, giver, count)
    if item.legion_potww_fueled ~= nil or potFerts[item.prefab] ~= nil then
        if inst._fertility >= potFertilityMax then
            if giver ~= nil then giver.legion_potww_traderes = "NONEED" end
            return false
        end
    elseif inst._growdd == nil then --还没有开始种植，所以就判断能否种植
        if potPlants[item.prefab] == nil then
            if giver ~= nil then giver.legion_potww_traderes = "WRONGITEM" end
            return false
        end
    else
        local dd = inst._growdd
        if dd.lvlup ~= nil and dd.lvlup[item.prefab] ~= nil then --是可升级的物品
            return true
        elseif item.legiontag_potww_up ~= nil or potUpdater[item.prefab] then --升级为无限生长的
            if not dd.nomaxlvl then
                if giver ~= nil then giver.legion_potww_traderes = "NONEED" end
                return false
            end
        elseif potPlants[item.prefab] ~= nil then
            local newdd = potPlants[item.prefab]
            if dd.fruitname ~= newdd.fruitname or newdd.pri <= dd.pri then --同类之间可以进行升级
                if giver ~= nil then giver.legion_potww_traderes = "NONEED" end
                return false
            end
        else
            if giver ~= nil then giver.legion_potww_traderes = "WRONGITEM" end
            return false
        end
    end
    return true
end
local function OnAccept_pot(inst, giver, item, count)
    local used
    local dd = item.legion_potww_fueled or potFerts[item.prefab]
    if dd then --施肥
        local need = TOOLS_L.ComputCost(inst._fertility, potFertilityMax, dd, item)
        if need > 0 then
            local oldf = inst._fertility
            inst._fertility = oldf + dd*need
            if inst._dd ~= nil and inst._dd.soilchangefn ~= nil then
                inst._dd.soilchangefn(inst)
            end
            if oldf <= 0 and inst._fertility > 0 then --有肥料了
                SetSoilSymbol_pot(inst, false)
                if inst._growdd ~= nil and inst._fruitnum < GetMaxStage_pot(inst) then
                    inst:AddTag("plant") --能继续生长时才需要这个标签
                    inst.components.growable:StartGrowing() --开始生长
                end
            end
        end
    elseif inst._growdd == nil then --种植新的
        if potPlants[item.prefab] ~= nil then
            OnGetItem_pot(inst, giver, item.prefab, 1, false, nil)
            used = true
        end
    else --进行升级
        dd = inst._growdd
        local source = item.prefab
        if dd.lvlup ~= nil and dd.lvlup[source] ~= nil then --是可升级的物品
            source = dd.lvlup[source]
        elseif item.legiontag_potww_up ~= nil or potUpdater[source] then --升级为无限生长的
            if dd.nomaxlvl then
                source = dd.source
                dd.nomaxlvl = nil
            else
                source = nil
            end
        else --同类升级
            local newdd = potPlants[source]
            if newdd == nil or dd.fruitname ~= newdd.fruitname or newdd.pri <= dd.pri then
                source = nil
            end
        end
        if source ~= nil then
            local growable = inst.components.growable
            local time = growable.pausedremaining
            if time == nil and growable.targettime ~= nil then --已生长的时间不想浪费掉
                time = growable.targettime - GetTime()
            end
            if time ~= nil and time > 0 then
                inst._growdt = time
            end
            GetFruits_pot(inst, giver) --操作前先把已有的果实收获了
            OnGetItem_pot(inst, giver, source, dd.growmult or 1, not dd.nomaxlvl, dd.animkey) --继承数据
            used = true
        end
    end
    if used then
        if item.components.stackable ~= nil then
            item.components.stackable:Get(1):Remove()
        else
            item:Remove()
        end
    end
    if item:IsValid() then --得把剩下的东西还给玩家
        item.Transform:SetPosition(inst.Transform:GetWorldPosition()) --提前设置好位置，放入玩家物品栏失败时也不怕消失了
        local inv = giver and giver.components.inventory or nil
        if inv ~= nil then
            if inv.activeitem ~= nil then --鼠标上已有物品，就只能放物品栏了
                inv:GiveItem(item, nil, inst:GetPosition())
            else
                inv:GiveActiveItem(item)
            end
        end
    end
end
local function OnRefuse_pot(inst, giver, item)
    if giver ~= nil and giver.legion_potww_traderes ~= nil then
        if not inst.legiontag_nocallback and giver.components.talker ~= nil then
            giver.components.talker:Say(GetString(giver, "DESCRIBE", { "POT_WHITEWOOD", giver.legion_potww_traderes }))
        end
        giver.legion_potww_traderes = nil
    end
end

local function GetGrowTime_pot(inst, stage, stagedata)
    if inst._growdd == nil or inst._fertility <= 0 then --缺肥或者未种植是不能生长的
        return
    end
    local basetime = inst._growdd.growtime
    if inst._growdd.growmult ~= nil then
        basetime = basetime * inst._growdd.growmult
    end
    basetime = GetRandomWithVariance(TUNING.TOTAL_DAY_TIME*basetime, 60)
    if inst._growdt ~= nil then --已生长的时间不想浪费掉
        if inst._growdt < basetime then
            basetime = inst._growdt
        end
        inst._growdt = nil
    end
    return basetime
end
local function SetPlantAnim_pot(inst, hasplant)
    if hasplant and inst._growdd ~= nil then
        inst.legionfn_smear_siv = pas.Smear_pot_whitewood --种植后就可以涂抹了
        if inst._plant == nil then
            pas.Init_pot_whitewood(inst) --统一化管理
            return
        end
        local fx = inst._plant
        local dd = inst._growdd
        fx.AnimState:PlayAnimation(dd.fruitname..tostring(inst._fruitnum).."_"..tostring(dd.animkey), fx.loopanim)
        if fx.loopanim then
            TOOLS_L.RandomAnimFrame(fx)
        end
    else
        inst.legionfn_smear_siv = nil --没种植时就不能涂抹了
        inst:RemoveTag("lifeless_l") --失去植物后就得清理涂抹标记，以便下一个种植物执行正常逻辑
        if inst._plant ~= nil then
            inst._plant:Remove()
            inst._plant = nil
        end
    end
end
local function PreGrow_pot(inst, stage, stagedata) --生长时消耗肥料
    local oldf = inst._fertility
    inst._fertility = oldf - (inst._magicgrow and 2 or 1) --魔法催熟会多消耗肥料
    if inst._dd ~= nil and inst._dd.soilchangefn ~= nil then
        inst._dd.soilchangefn(inst)
    end
    if oldf > 0 and inst._fertility <= 0 then
        inst:RemoveTag("plant") --不能催熟了，不然会浪费催熟次数
        SetSoilSymbol_pot(inst, true)
        inst.components.growable:StopGrowing() --没肥料了，得停止生长
    end
end
local function Grow_pot(inst, stage, stagedata)
    if inst._growdd ~= nil and inst._fruitnum >= GetMaxStage_pot(inst) then
        inst.SoundEmitter:PlaySound("dontstarve/common/together/mushroomfarm/spore_grow")
    else
        inst.SoundEmitter:PlaySound("dontstarve/common/together/mushroomfarm/grow")
    end
end
local function MagicGrow_pot(inst, doer) --催熟效果为20天
    inst.magic_growth_delay = nil --官方加的，这里用不到这个数据，清理一下
    if inst._fertility > 0 then
        inst._magicgrow = true
        inst.components.growable:LongUpdate(TUNING.TOTAL_DAY_TIME * 20)
        inst._magicgrow = nil
    end
end
local function GrowBase_pot(inst, fruitnum, nomagic)
    if inst._growdd == nil then --正常来说不会运行这里，要是出错了，就恢复到最初阶段
        inst:DoTaskInTime(0.5, function()
            inst.components.growable:SetStage(1)
            inst.components.growable:StopGrowing()
        end)
        return
    end
    inst._fruitnum = fruitnum
    if not nomagic then
        if inst._fertility > 0 then
            inst:AddTag("plant") --这个标签才能使得园艺学能起作用
        end
        inst.components.growable.magicgrowable = true
        inst.components.growable.domagicgrowthfn = MagicGrow_pot
    else
        inst:RemoveTag("plant")
        inst.components.growable.magicgrowable = nil
        inst.components.growable.domagicgrowthfn = nil
    end
    SetWorkable2(inst, OnWorked_pot_f, nil, nil, 1)
    SetPlantAnim_pot(inst, true)
    if inst._growdd.stagefn ~= nil then
        inst._growdd.stagefn(inst, fruitnum)
    end
end
local function OnBurnt_pot(inst)
    inst.components.lootdropper:DropLoot()
    if inst._fertility >= potFerts.treegrowthsolution then --返还肥料
        local num = math.floor(inst._fertility / potFerts.treegrowthsolution)
        TOOLS_L.SpawnStackDrop("treegrowthsolution", num, inst:GetPosition(), nil, nil, { dropper = inst })
    end
    OnWorked_pot_f(inst, nil) --返还果实
    inst:Remove()
end
local function OnPicked_pot(inst, doer, loot)
    GetFruits_pot(inst, doer)
    if inst._growdd == nil or inst._growdd.nomaxlvl then --一次性的采摘
        inst.components.growable:SetStage(1)
        inst.components.growable:StopGrowing()
    else --无限生长的采摘
        inst.components.growable:SetStage(2)
        if inst._fertility <= 0 then
            inst.components.growable:StopGrowing()
        else
            inst.components.growable:StartGrowing()
        end
    end
end
local function SetPickable_pot(inst)
    if inst.components.pickable == nil then
        inst:AddComponent("pickable")
    end
    inst.components.pickable.onpickedfn = OnPicked_pot
    inst.components.pickable:SetUp(nil)
    -- inst.components.pickable.use_lootdropper_for_product = true --有自己的独特收获物机制，不需要沿用官方的逻辑
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
end

local function OnSave_pot(inst, data)
    local dd = inst._growdd
    if dd ~= nil then
        data.source = dd.source
        data.animkey = dd.animkey
        if dd.growmult ~= nil then
            data.growmult = dd.growmult
        end
        if dd.nomaxlvl then
            data.nomaxlvl = true
        end
    end
    data.fertility = inst._fertility
    if inst:HasTag("lifeless_l") then
        data.lifeless_l = true
    end
end
local function OnPreLoad_pot(inst, data, newents)
    if data == nil then return end
    if data.lifeless_l then
        inst:AddTag("lifeless_l")
    end
    if data.fertility ~= nil then
        inst._fertility = data.fertility
    end
    if data.source ~= nil and potPlants[data.source] ~= nil then --检查合理性
        SetGrowDD_pot(inst, data.source, data.growmult or 1, not data.nomaxlvl, data.animkey)
    end
end
local function DealData_pot(inst, data)
    local dd = { ft = tostring(data.ft), ftmax = tostring(potFertilityMax) }
    if data.sc ~= nil and potPlants[data.sc] ~= nil then
        local plantdd = potPlants[data.sc]
        local respst
        dd.stmax = data.no and 3 or 4
        dd.st = data.fn or 0
        if inst:HasTag("lifeless_l") then
            respst = STRINGS.NAMEDETAIL_L.SMEARED[plantdd.smearkey or "POT"]
        end
        if dd.st >= dd.stmax then --已长满，必定成熟了
            dd.gt = "0"
        else
            dd.gt = tostring(data.gt or 0)
            if data.ft <= 0 then --生长时才需要提示缺肥
                if respst == nil then
                    respst = STRINGS.NAMEDETAIL_L.POT_WHITEWOOD[3]
                else --两个提示需要只占一行，不然总行数可能会超过4行
                    respst = respst..STRINGS.NAMEDETAIL_L.PERIOD..STRINGS.NAMEDETAIL_L.POT_WHITEWOOD[3]
                end
            end
        end
        if dd.st > 0 then
            dd.fn = tostring(dd.st * plantdd.fruitnum)
        else
            dd.fn = "0"
        end
        if plantdd.sourcename ~= nil then
            dd.sc = plantdd.sourcename
        else
            dd.sc = STRINGS.NAMES[string.upper(plantdd.sourceloot or data.sc)] or STRINGS.NAMES.UNKNOWN
        end
        dd.stmax = tostring(dd.stmax + 1)
        dd.st = tostring(dd.st + 1)
        if respst == nil then
            return subfmt(STRINGS.NAMEDETAIL_L.POT_WHITEWOOD[1], dd)
        else
            return subfmt(STRINGS.NAMEDETAIL_L.POT_WHITEWOOD[1], dd).."\n"..respst
        end
    else
        return subfmt(STRINGS.NAMEDETAIL_L.POT_WHITEWOOD[2], dd)
    end
end
local function GetData_pot(inst)
    local data = { ft = inst._fertility } --剩余肥料
    if inst._growdd ~= nil then
        local dd = inst._growdd
        local cpt = inst.components.growable
        if cpt.targettime ~= nil then --剩余生长时间
            local gt = cpt.targettime - GetTime()
            if gt > 0 then
                data.gt = TOOLS_L.ODPoint(gt/TUNING.TOTAL_DAY_TIME, 100)
            end
        end
        if inst._fruitnum > 0 then --果实量，也能间接表达阶段
            data.fn = inst._fruitnum
        end
        data.sc = dd.source --种植物
        if dd.nomaxlvl then --是否循环生长
            data.no = true
        end
    end
    return data
end
pas.Init_pot_whitewood = function(inst)
    local dd = inst._growdd
    local _dd = inst._dd
    if dd ~= nil and dd.fruitname ~= nil then
        local fx = inst._plant
        if fx == nil then
            fx = SpawnPrefab("potplant_l_fx")
            fx.entity:SetParent(inst.entity)
            fx.components.highlightchild:SetOwner(inst)
            inst._plant = fx
        end
        local overridebuild = potAnimBuilds[dd.fruitname] or "pot_whitewood" --贴图太多，另外做了动画包，所以需要专门设置
        if overridebuild ~= fx.AnimState:GetBuild() then
            fx.AnimState:SetBank(overridebuild)
            fx.AnimState:SetBuild(overridebuild)
        end
        fx.loopanim = nil
        if _dd ~= nil then
            if _dd.fixmap ~= nil and _dd.fixmap[dd.fruitname] ~= nil then
                local fdd = _dd.fixmap[dd.fruitname]
                if fdd[dd.animkey] ~= nil then
                    fdd = fdd[dd.animkey]
                end
                local bb = fdd.bank or _dd.bank
                if bb ~= nil then
                    fx.AnimState:SetBank(bb)
                end
                bb = fdd.build or _dd.build
                if bb ~= nil then
                    fx.AnimState:SetBuild(bb)
                end
                fx.Follower:FollowSymbol(inst.GUID, "afollowed",
                    fdd.x or _dd.x or 0, fdd.y or _dd.y or 0, fdd.z or _dd.z or 0)
                fx.loopanim = fdd.loopanim
            else
                if _dd.bank ~= nil then
                    fx.AnimState:SetBank(_dd.bank)
                end
                if _dd.build ~= nil then
                    fx.AnimState:SetBuild(_dd.build)
                end
                fx.Follower:FollowSymbol(inst.GUID, "afollowed", _dd.x or 0, _dd.y or 0, _dd.z or 0)
            end
            if _dd.plantfn ~= nil then
                _dd.plantfn(inst, fx)
            end
        else
            fx.Follower:FollowSymbol(inst.GUID, "afollowed", 0, 0, 0)
        end
        fx.AnimState:PlayAnimation(dd.fruitname..tostring(inst._fruitnum).."_"..tostring(dd.animkey), fx.loopanim)
        if fx.loopanim then
            TOOLS_L.RandomAnimFrame(fx)
        end
    end
    if _dd ~= nil and _dd.soilchangefn ~= nil then
        _dd.soilchangefn(inst)
    end
    SetSoilSymbol_pot(inst, inst._fertility <= 0)
end
pas.Wax_pot = function(inst, doer, waxitem, right)
    local dd = {}
    if inst._growdd ~= nil then
        dd.fruitname = inst._growdd.fruitname --动画名称前缀
        dd.stage = tostring(inst._fruitnum) --生长阶段
        dd.animkey = tostring(inst._growdd.animkey) --动画样式
    end
    if inst._fertility <= 0 then --是否缺肥
        dd.barren = true
    end
    return TOOLS_L.WaxObject(inst, doer, waxitem, "pot_whitewood_item_waxed", dd, nil)
end
pas.Smear_pot_whitewood = function(inst, doer, item)
    inst:AddTag("lifeless_l")
    if inst._growdd ~= nil and inst._growdd.stagefn ~= nil then --重新执行阶段函数，就可以去除特殊逻辑效果了
        inst._growdd.stagefn(inst, inst._fruitnum)
    end
end

local growth_stages_pot = {
    {   name = "lvl0", time = function(inst, stage, stagedata)end,
        fn = function(inst, stage, stagedata)
            if inst._growdd ~= nil then
                if inst._growdd.stagefn ~= nil then --需要把一些特殊机制给删除并还原了
                    inst._growdd.stagefn(inst, -1)
                end
                inst._growdd = nil
            end
            inst._fruitnum = 0
            inst.components.growable.magicgrowable = nil --这个阶段不能被催熟，因为还没种什么
            inst.components.growable.domagicgrowthfn = nil
            SetWorkable2(inst, OnWorked_pot, OnFinished_pot, "HAMMER", 2)
            SetPlantAnim_pot(inst, false)
            inst:RemoveTag("plant")
            if inst.components.pickable ~= nil then inst:RemoveComponent("pickable") end
        end
    },
    {   name = "lvl1", time = GetGrowTime_pot,
        fn = function(inst, stage, stagedata)
            GrowBase_pot(inst, 0)
            if inst.components.pickable ~= nil then inst:RemoveComponent("pickable") end
        end
    },
    {   name = "lvl2", time = GetGrowTime_pot, pregrowfn = PreGrow_pot, --pregrowfn则没有这个机制
        growfn = Grow_pot, --在Growable:LongUpdate()时中间阶段不会连续触发growfn，可能会漏掉逻辑，所以关键逻辑不能写这里面
        fn = function(inst, stage, stagedata)
            GrowBase_pot(inst, 1)
            SetPickable_pot(inst)
        end
    },
    {   name = "lvl3", time = GetGrowTime_pot, pregrowfn = PreGrow_pot, growfn = Grow_pot,
        fn = function(inst, stage, stagedata)
            GrowBase_pot(inst, 2)
            SetPickable_pot(inst)
        end
    },
    {   name = "lvl4", pregrowfn = PreGrow_pot, growfn = Grow_pot,
        time = function(inst, stage, stagedata)
            if inst._growdd == nil or inst._growdd.nomaxlvl then return end --看条件，不是都能长到最大阶段
            return GetGrowTime_pot(inst, stage, stagedata)
        end,
        fn = function(inst, stage, stagedata)
            if inst._growdd ~= nil and not inst._growdd.nomaxlvl then --说明还能继续长
                GrowBase_pot(inst, 3)
            else
                GrowBase_pot(inst, 3, true)
            end
            SetPickable_pot(inst)
        end
    },
    {   name = "lvl5", time = function(inst, stage, stagedata)end, pregrowfn = PreGrow_pot, growfn = Grow_pot,
        fn = function(inst, stage, stagedata)
            GrowBase_pot(inst, 4, true) --已经完全成熟了，不需要催熟了
            SetPickable_pot(inst)
        end
    }
}

table.insert(prefs, Prefab("pot_whitewood", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst:SetDeploySmartRadius(0.5) --建造半径的一半
    MakeObstaclePhysics(inst, .15)

    inst.MiniMapEntity:SetIcon("pot_whitewood.tex")

    inst:AddTag("structure")
    inst:AddTag("playerowned") --不会被投石机破坏
    inst:AddTag("trader")
    inst:AddTag("alltrader")
    inst:AddTag("waxable_l")
    inst:AddTag("rotatableobject") --能让栅栏击剑起作用
    inst:AddTag("flatrotated_l") --棱镜标签：旋转时旋转180度
    inst.Transform:SetTwoFaced() --两个面，这样就可以左右不同（再多貌似有问题）

    inst.AnimState:SetBank("pot_whitewood")
    inst.AnimState:SetBuild("pot_whitewood")
    inst.AnimState:PlayAnimation("idle")

    TOOLS_L.InitMouseInfo(inst, DealData_pot, GetData_pot, 2)
    LS_C_Init(inst, "pot_whitewood", false)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.fn_init = pas.Init_pot_whitewood
    inst.legionfn_wax = pas.Wax_pot
    inst.legiontag_nopost_pickable = true --培植盆不要做对pickable组件的修改
    inst._fertility = 80
    inst._fruitnum = 0
    -- inst._plant = nil
    -- inst._growdd = nil

    inst:AddComponent("savedrotation")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus_pot

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")

    inst:AddComponent("growable")
    inst.components.growable.stages = growth_stages_pot
    inst.components.growable.springgrowth = true --春季时生长能加速
    inst.components.growable:SetStage(1)

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptStacks() --现在交易组件能设置为一次性全部给予了
    inst.components.trader:SetAcceptTest(AcceptTest_pot)
    inst.components.trader.onaccept = OnAccept_pot
    inst.components.trader.onrefuse = OnRefuse_pot
    inst.components.trader.deleteitemonaccept = false --收到物品不马上移除，根据具体物品决定
    inst.components.trader.acceptnontradable = true

    MakeMediumBurnable(inst)
    MakeLargePropagator(inst)
    inst.components.burnable:SetOnBurntFn(OnBurnt_pot)

    inst.OnSave = OnSave_pot
    inst.OnPreLoad = OnPreLoad_pot --在所有组件 Onload() 前执行，能提前设置好数据
    -- inst.OnLoad = OnLoad_pot

    MakeHauntableLaunch(inst)

    return inst
end, {
    Asset("ANIM", "anim/pot_whitewood.zip"),
    Asset("ANIM", "anim/pot_whitewood2.zip"),
    Asset("ATLAS", "images/inventoryimages/pot_whitewood.xml"),
    Asset("IMAGE", "images/inventoryimages/pot_whitewood.tex"),
    Asset("ATLAS_BUILD", "images/inventoryimages/pot_whitewood.xml", 256)
}, { "potplant_l_fx" }))

-----
-----

return unpack(prefs)

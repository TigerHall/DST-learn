------！！！其他模组的装备要兼容幻化逻辑，具体说明请查看 "棱镜文件夹\readme\tip_dressup.lua"

local _G = GLOBAL
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

--------------------------------------------------------------------------
--[[ 全局幻化数据 ]]
--------------------------------------------------------------------------

local function Fn_symbolSwap(dressup, item, buildskin)
    local itemswap = {}
    if item.components.symbolswapdata ~= nil then
        local swap = item.components.symbolswapdata
        itemswap["swap_body_tall"] = dressup:GetDressData(
            buildskin, swap.build, swap.symbol, item.GUID, "swap"
        )
    end
    return itemswap
end

local function Fn_removeFollowSymbolFx(inst, fxkey)
    if inst[fxkey] ~= nil then
        for i, v in ipairs(inst[fxkey]) do
            v:Remove()
        end
        inst[fxkey] = nil
    end
end
local function Fn_setFollowSymbolFx(owner, fxkey, fxdata, randomanim)
    if owner[fxkey] == nil then
        owner[fxkey] = {}
        for i, v in ipairs(fxdata) do
            local fx = SpawnPrefab(v.name)
            if v.anim ~= nil then
                if v.noloop then
                    fx.AnimState:PlayAnimation(v.anim, false)
                else
                    fx.AnimState:PlayAnimation(v.anim, true)
                end
            end
            table.insert(owner[fxkey], fx)
        end
    end
    local frame = nil
    if randomanim then
        frame = math.random(owner[fxkey][1].AnimState:GetCurrentAnimationNumFrames()) - 1
    end
    for i, v in ipairs(owner[fxkey]) do
        local fxdd = fxdata[i]
        v.entity:SetParent(owner.entity)
        v.Follower:FollowSymbol(owner.GUID, fxdd.symbol, fxdd.x, fxdd.y, fxdd.z, true, nil, fxdd.idx, fxdd.idx2)
        if frame ~= nil then
            v.AnimState:SetFrame(frame)
        end
        if v.components.highlightchild ~= nil then
            v.components.highlightchild:SetOwner(owner)
        end
    end
end

local function Fn_setFollowFx(owner, fxkey, fxname)
    --不能把数据存在item上，因为幻化后item会被删除
    if owner[fxkey] ~= nil then
        owner[fxkey]:Remove()
    end
    owner[fxkey] = SpawnPrefab(fxname)
    if owner[fxkey] then
        owner[fxkey]:AttachToOwner(owner)
    end
end
local function Fn_removeFollowFx(owner, fxkey)
    if owner[fxkey] ~= nil then
        if owner[fxkey].Remove ~= nil then
            owner[fxkey]:Remove()
        else --兼容测试版和正式版
            Fn_removeFollowSymbolFx(owner, fxkey)
        end
        owner[fxkey] = nil
    end
end

local function GetSymbol_sivmask(dressup)
    local maps = {
        wolfgang = true,
        waxwell = true,
        wathgrithr = true,
        winona = true,
        wortox = true,
        wormwood = true,
        wurt = true,
        pigman = true,
        pigguard = true,
        moonpig = true,
        bunnyman = true
    }
    if dressup.inst.sivmask_swapsymbol or maps[dressup.inst.prefab] then
        return "swap_other"
    else
        return "swap_hat"
    end
end

local dressup_data = {
    -------------------------------
    --手部-------------------------
    -------------------------------

    spear = { buildfile = "swap_spear", buildsymbol = "swap_spear" },
    hambat = { buildfile = "swap_ham_bat", buildsymbol = "swap_ham_bat" },
    spear_wathgrithr = { buildfile = "swap_spear_wathgrithr", buildsymbol = "swap_spear_wathgrithr" },
    spear_wathgrithr_lightning = { --奔雷矛
        buildfile = "spear_wathgrithr_lightning", buildsymbol = "swap_spear_wathgrithr_lightning"
    },
    spear_wathgrithr_lightning_charged = { --充能奔雷矛
        buildfile = "spear_wathgrithr_lightning", buildsymbol = "swap_spear_wathgrithr_lightning",
        equipfn = function(owner, item)
            local fx = SpawnPrefab("spear_wathgrithr_lightning_fx")
            if fx == nil then
                return
            end
            owner.fx_d_spear_wathgrithr_l_c = fx
            local skin_build = item:GetSkinBuild()
            if skin_build ~= nil then
                fx.AnimState:OverrideItemSkinSymbol("swap_spear_wathgrithr_lightning", skin_build, "swap_spear_wathgrithr_lightning", item.GUID, "swap_spear_wathgrithr_lightning")
                fx.AnimState:PlayAnimation("swap_straight_loop", true)
            else
                fx.AnimState:ClearOverrideSymbol("swap_spear_wathgrithr_lightning")
                fx.AnimState:PlayAnimation("swap_loop", true)
            end

            local FX_OFFSETS = { --每出一个新皮肤，多半得更新这里
                DEFAULT = {0, 0, 0},
                ["spear_wathgrithr_lightning_lunar"]    = {0,  20, 0},
                ["spear_wathgrithr_lightning_valkyrie"] = {0,   0, 0},
                ["spear_wathgrithr_lightning_wrestle"]  = {0, -20, 0},
                ["spear_wathgrithr_lightning_northern"] = {0, -10, 0},
            }
            local offset = FX_OFFSETS[skin_build] or FX_OFFSETS.DEFAULT
            fx.entity:SetParent(owner.entity)
            fx.Follower:FollowSymbol(owner.GUID, "swap_object", offset[1], offset[2], offset[3], true)
            fx.components.highlightchild:SetOwner(owner)
            if owner.components.colouradder ~= nil then
                owner.components.colouradder:AttachChild(fx)
            end
        end,
        unequipfn = function(owner, item)
            if owner.fx_d_spear_wathgrithr_l_c == nil then
                return
            end
            if owner.components.colouradder ~= nil then
                owner.components.colouradder:DetachChild(owner.fx_d_spear_wathgrithr_l_c)
            end
            owner.fx_d_spear_wathgrithr_l_c:Remove()
        end,
        onequipfn = function(owner, item)
            if item.SetFxOwner ~= nil then
                item:SetFxOwner(nil)
            end
        end
    },
    nightsword = { buildfile = "swap_nightmaresword", buildsymbol = "swap_nightmaresword" },
    lantern = {
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_object"] = dressup:GetDressData(
                buildskin, "swap_lantern", "swap_lantern", item.GUID, "swap"
            )

            --提灯光效贴图没法控制了，就像鞭子类武器的鞭子击打动画一样没法强制改，只能跟随目前的装备类型才行。
            --比如，幻化鞭子后，装备海带鞭才会看见鞭子的击打动画；幻化提灯后，装备提灯时才会看见提灯光效
            if item.components.fueled:IsEmpty() then
                itemswap["lantern_overlay"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            else
                itemswap["lantern_overlay"] = dressup:GetDressData(
                    buildskin, "swap_lantern", "lantern_overlay", item.GUID, "swap"
                )
            end
            itemswap["whipline"] = dressup:GetDressData(nil, nil, nil, nil, "clear")

            return itemswap
        end,
        equipfn = function(player, item)
            --幻化前需要关闭它，防止玩家发光
            if item.components.machine ~= nil and item.components.machine:IsOn() then
                item.components.machine:TurnOff()
            end
        end
    },
    bugnet = { buildfile = "swap_bugnet", buildsymbol = "swap_bugnet" },
    thulecitebugnet = { buildfile = "thulecitebugnet", buildsymbol = "swap_object" }, --铥矿捕虫网
    fishingrod = { buildfile = "swap_fishingrod", buildsymbol = "swap_fishingrod" },
    grass_umbrella = { buildfile = "swap_parasol", buildsymbol = "swap_parasol" },
    umbrella = { buildfile = "swap_umbrella", buildsymbol = "swap_umbrella" },
    waterballoon = { buildfile = "swap_waterballoon", buildsymbol = "swap_waterballoon" },
    compass = { buildfile = "swap_compass", buildsymbol = "swap_compass" },
    axe = { buildfile = "swap_axe", buildsymbol = "swap_axe" },
    goldenaxe = { buildfile = "swap_goldenaxe", buildsymbol = "swap_goldenaxe" },
    pickaxe = { buildfile = "swap_pickaxe", buildsymbol = "swap_pickaxe" },
    goldenpickaxe = { buildfile = "swap_goldenpickaxe", buildsymbol = "swap_goldenpickaxe" },
    shovel = { buildfile = "swap_shovel", buildsymbol = "swap_shovel" },
    goldenshovel = { buildfile = "swap_goldenshovel", buildsymbol = "swap_goldenshovel" },
    multitool_axe_pickaxe = {
        buildfile = "swap_multitool_axe_pickaxe",
        buildsymbol = "swap_multitool_axe_pickaxe"
    },
    hammer = { buildfile = "swap_hammer", buildsymbol = "swap_hammer" },
    pitchfork = { buildfile = "swap_pitchfork", buildsymbol = "swap_pitchfork" },
    saddlehorn = { buildfile = "swap_saddlehorn", buildsymbol = "swap_saddlehorn" },
    brush = { buildfile = "swap_beefalobrush", buildsymbol = "swap_beefalobrush" },
    batbat = { buildfile = "swap_batbat", buildsymbol = "swap_batbat" },
    firestaff = { buildfile = "swap_staffs", buildsymbol = "swap_redstaff" },
    icestaff = { buildfile = "swap_staffs", buildsymbol = "swap_bluestaff" },
    telestaff = { buildfile = "swap_staffs", buildsymbol = "swap_purplestaff" },
    yellowstaff = { buildfile = "swap_staffs", buildsymbol = "swap_yellowstaff" },
    greenstaff = { buildfile = "swap_staffs", buildsymbol = "swap_greenstaff" },
    orangestaff = { buildfile = "swap_staffs", buildsymbol = "swap_orangestaff" },
    opalstaff = { buildfile = "swap_staffs", buildsymbol = "swap_opalstaff" },
    nightstick = { buildfile = "swap_nightstick", buildsymbol = "swap_nightstick" },
    whip = { iswhip = true, buildfile = "swap_whip", buildsymbol = "swap_whip" },
    sleepbomb = { buildfile = "swap_sleepbomb", buildsymbol = "swap_sleepbomb" },
    blowdart_sleep = { buildfile = "swap_blowdart", buildsymbol = "swap_blowdart" },
    blowdart_fire = { buildfile = "swap_blowdart", buildsymbol = "swap_blowdart" },
    blowdart_yellow = { buildfile = "swap_blowdart", buildsymbol = "swap_blowdart" },
    blowdart_pipe = { buildfile = "swap_blowdart_pipe", buildsymbol = "swap_blowdart_pipe" },
    boomerang = { buildfile = "swap_boomerang", buildsymbol = "swap_boomerang" },
    staff_tornado = { buildfile = "swap_tornado_stick", buildsymbol = "swap_tornado_stick" },
    cane = { buildfile = "swap_cane", buildsymbol = "swap_cane" },
    ruins_bat = { buildfile = "swap_ruins_bat", buildsymbol = "swap_ruins_bat" },
    tentaclespike = { isnoskin = true, buildfile = "swap_spike", buildsymbol = "swap_spike" },
    bullkelp_root = { isnoskin = true, iswhip = true, buildfile = "swap_bullkelproot", buildsymbol = "swap_whip" },
    chum = { buildfile = "swap_chum_pouch", buildsymbol = "swap_chum_pouch" }, --鱼食
    diviningrod = { isnoskin = true, buildfile = "swap_diviningrod", buildsymbol = "swap_diviningrod" }, --零件探测器
    fishingnet = { buildfile = "swap_boat_net", buildsymbol = "swap_boat_net" }, --渔网
    glasscutter = { buildfile = "swap_glasscutter", buildsymbol = "swap_glasscutter" }, --月玻璃刀
    gnarwail_horn = { isnoskin = true, buildfile = "gnarwail_horn", buildsymbol = "swap_gnarwailhorn" }, --一角鲸的角
    messagebottle = { --瓶中信
        isnoskin = true, dressslot = EQUIPSLOTS.HANDS, buildfile = "swap_bottle", buildsymbol = "swap_bottle"
    },
    gelblob_bottle = { isnoskin = true, buildfile = "swap_gelblobbottle", buildsymbol = "swap_bottle" }, --黏汁罐
    oar = { buildfile = "swap_oar", buildsymbol = "swap_oar" }, --木桨
    oar_driftwood = { buildfile = "swap_oar_driftwood", buildsymbol = "swap_oar_driftwood" }, --浮木桨
    oar_monkey = { buildfile = "swap_oar_monkey", buildsymbol = "swap_oar_monkey" }, --战桨
    malbatross_beak = { buildfile = "swap_malbatross_beak", buildsymbol = "swap_malbatross_beak" }, --邪天翁喙
    yotd_oar = { buildfile = "yotd_oar", buildsymbol = "swap_oar" }, --利爪船桨
    oceanfishingrod = { --海钓竿
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_object"] = dressup:GetDressData(
                buildskin, "swap_fishingrod_ocean", "swap_fishingrod_ocean", item.GUID, "swap"
            )
            itemswap["fishingline"] = dressup:GetDressData(
                buildskin, "swap_fishingrod_ocean", "fishingline", item.GUID, "swap"
            )
            itemswap["FX_fishing"] = dressup:GetDressData(
                buildskin, "swap_fishingrod_ocean", "FX_fishing", item.GUID, "swap"
            )
            dressup:SetDressHand(itemswap)

            return itemswap
        end,
        unbuildfn = function(dressup, item)
            dressup:InitClear("swap_object")
            dressup:InitClear("whipline")
            dressup:InitClear("lantern_overlay")
            dressup:InitHide("LANTERN_OVERLAY")

            dressup:InitClear("fishingline")
            dressup:InitClear("FX_fishing")
        end
    },
    reskin_tool = { buildfile = "swap_reskin_tool", buildsymbol = "swap_reskin_tool" }, --扫把
    slingshot = { buildfile = "swap_slingshot", buildsymbol = "swap_slingshot" }, --弹弓
    trident = { buildfile = "swap_trident", buildsymbol = "swap_trident" }, --刺耳三叉戟
    waterplant_bomb = { isnoskin = true, buildfile = "swap_barnacle_burr", buildsymbol = "swap_barnacle_burr" }, --种壳
    moonglassaxe = { buildfile = "swap_glassaxe", buildsymbol = "swap_glassaxe" },
    lighter = { buildfile = "swap_lighter", buildsymbol = "swap_lighter" },
    torch = { buildfile = "swap_torch", buildsymbol = "swap_torch" },
    farm_hoe = { buildfile = "quagmire_hoe", buildsymbol = "swap_quagmire_hoe" },
    golden_farm_hoe = { buildfile = "swap_goldenhoe", buildsymbol = "swap_goldenhoe" },
    wateringcan = { buildfile = "swap_wateringcan", buildsymbol = "swap_wateringcan" },
    premiumwateringcan = { buildfile = "swap_premiumwateringcan", buildsymbol = "swap_premiumwateringcan" },
    pocketwatch_weapon = { buildfile = "pocketwatch_weapon", buildsymbol = "swap_object" },
    shieldofterror = { isshield = true, buildfile = "swap_eye_shield", buildsymbol = "swap_shield" }, --恐怖盾牌
    dumbbell = { buildfile = "swap_dumbbell", buildsymbol = "swap_dumbbell" }, --哑铃
    dumbbell_golden = { buildfile = "swap_dumbbell_golden", buildsymbol = "swap_dumbbell_golden" }, --黄金哑铃
    dumbbell_gem = { buildfile = "swap_dumbbell_gem", buildsymbol = "swap_dumbbell_gem" }, --宝石哑铃
    dumbbell_marble = { buildfile = "swap_dumbbell_marble", buildsymbol = "swap_dumbbell_marble" }, --大理石哑铃
    dumbbell_heat = { --热铃
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_object"] = dressup:GetDressData(
                buildskin, item.swap_dumbbell, item.swap_dumbbell_symbol, item.GUID, "swap"
            )
            dressup:SetDressHand(itemswap)
            return itemswap
        end
    },
    dumbbell_redgem = { buildfile = "swap_dumbbell_redgem", buildsymbol = "swap_dumbbell_redgem" }, --火铃
    dumbbell_bluegem = { buildfile = "swap_dumbbell_bluegem", buildsymbol = "swap_dumbbell_bluegem" }, --冰铃
    cutless = { buildfile = "cutless", buildsymbol = "swap_cutless" }, --木头短剑
    firepen = { buildfile = "firepen", buildsymbol = "swap_firepen" }, --抒焰笔
    fence_rotator = { buildfile = "fence_rotator", buildsymbol = "swap_fence_rotator" }, --栅栏刺钉
    bernie_inactive = {
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            if item.components.fueled:IsEmpty() then
                itemswap["swap_object"] = dressup:GetDressData(
                    buildskin, "bernie_build", "swap_bernie_dead", item.GUID, "swap"
                )
                itemswap["swap_object_bernie"] = dressup:GetDressData(
                    buildskin, "bernie_build", "swap_bernie_dead_idle_willow", item.GUID, "swap"
                )
            else
                itemswap["swap_object"] = dressup:GetDressData(
                    buildskin, "bernie_build", "swap_bernie", item.GUID, "swap"
                )
                itemswap["swap_object_bernie"] = dressup:GetDressData(
                    buildskin, "bernie_build", "swap_bernie_idle_willow", item.GUID, "swap"
                )
            end
            dressup:SetDressHand(itemswap)

            return itemswap
        end
    },
    goldenpitchfork = { buildfile = "swap_goldenpitchfork", buildsymbol = "swap_goldenpitchfork" },
    featherfan = { dressslot = EQUIPSLOTS.HANDS, buildfile = "fan", buildsymbol = "swap_fan" },
    perdfan = { dressslot = EQUIPSLOTS.HANDS, buildfile = "fan", buildsymbol = "swap_fan_perd" },
    sword_lunarplant = {
        buildfile = "sword_lunarplant", buildsymbol = "swap_sword_lunarplant",
        equipfn = function(owner, item)
            Fn_setFollowSymbolFx(owner, "fx_d_sword_lunarplant", {
                { name = "sword_lunarplant_blade_fx", anim = nil, symbol = "swap_object", idx = 0, idx2 = 3 },
                { name = "sword_lunarplant_blade_fx", anim = "swap_loop2", symbol = "swap_object", idx = 5, idx2 = 8 }
            }, true)
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowSymbolFx(owner, "fx_d_sword_lunarplant")
        end,
        onequipfn = function(owner, item)
            item.blade1.entity:SetParent(item.entity)
            item.blade2.entity:SetParent(item.entity)
            item.blade1.Follower:FollowSymbol(item.GUID, "swap_spear", nil, nil, nil, true, nil, 0, 3)
            item.blade2.Follower:FollowSymbol(item.GUID, "swap_spear", nil, nil, nil, true, nil, 5, 8)
            item.blade1.components.highlightchild:SetOwner(item)
            item.blade2.components.highlightchild:SetOwner(item)
        end
    },
    staff_lunarplant = {
        buildfile = "staff_lunarplant", buildsymbol = "swap_staff_lunarplant",
        equipfn = function(owner, item)
            Fn_setFollowSymbolFx(owner, "fx_d_staff_lunarplant", {
                { name = "staff_lunarplant_fx", anim = nil, symbol = "swap_object" }
            }, true)
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowSymbolFx(owner, "fx_d_staff_lunarplant")
        end,
        onequipfn = function(owner, item)
            item.fx.entity:SetParent(item.entity)
            item.fx.Follower:FollowSymbol(item.GUID, "swap_spear", nil, nil, nil, true)
            item.fx.components.highlightchild:SetOwner(item)
        end
    },
    bomb_lunarplant = { buildfile = "bomb_lunarplant", buildsymbol = "swap_bomb_lunarplant" },
    pickaxe_lunarplant = { buildfile = "pickaxe_lunarplant", buildsymbol = "swap_pickaxe_lunarplant" },
    shovel_lunarplant = { buildfile = "shovel_lunarplant", buildsymbol = "swap_shovel_lunarplant" },
    voidcloth_umbrella = {
        buildfile = "umbrella_voidcloth", buildsymbol = "swap_umbrella",
        equipfn = function(owner, item)
            Fn_setFollowFx(owner, "fx_d_voidcloth_umbrella", "voidcloth_umbrella_fx")
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_voidcloth_umbrella")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(item, "_fx")
        end
    },
    voidcloth_scythe = {
        buildfile = "scythe_voidcloth", buildsymbol = "swap_scythe",
        equipfn = function(owner, item)
            Fn_setFollowSymbolFx(owner, "fx_d_voidcloth_scythe", {
                { name = "voidcloth_scythe_fx", anim = nil, symbol = "swap_object", idx = 2 }
            }, false)
            if owner.fx_d_voidcloth_scythe[1] ~= nil then
                owner.fx_d_voidcloth_scythe[1]:ToggleEquipped(true)
            end
        end,
        unequipfn = function(owner, item)
            -- if owner.fx_d_voidcloth_scythe[1] ~= nil then
            --     owner.fx_d_voidcloth_scythe[1]:ToggleEquipped(false)
            -- end
            Fn_removeFollowSymbolFx(owner, "fx_d_voidcloth_scythe")
        end,
        onequipfn = function(owner, item)
            item.fx.entity:SetParent(item.entity)
            item.fx.Follower:FollowSymbol(item.GUID, "swap_spear", nil, nil, nil, true, nil, 2)
            item.fx.components.highlightchild:SetOwner(item)
            item.fx:ToggleEquipped(false)
        end
    },
    walking_stick = { buildfile = "walking_stick", buildsymbol = "swap_walking_stick" },
    houndstooth_blowpipe = { buildfile = "swap_houndstooth_blowpipe", buildsymbol = "swap_blowdart_pipe" }, --嚎弹炮
    wathgrithr_shield = { isshield = true, buildfile = "swap_wathgrithr_shield", buildsymbol = "swap_shield" }, --战斗圆盾
    beeswax_spray = { buildfile = "plant_spray", buildsymbol = "swap_plant_spray" }, --防腐喷雾
    mosquitobomb = { isnoskin = true, buildfile = "swap_mosquitobomb", buildsymbol = "swap_mosquitobomb" }, --蚊子炸弹。看来这东西不会有皮肤了
    wurt_swampitem_lunar = { isnoskin = true, buildfile = "swap_wurt_swampbomb", buildsymbol = "swap_lunar" }, --光芒投泥带。看来这东西不会有皮肤了
    wurt_swampitem_shadow = { isnoskin = true, buildfile = "swap_wurt_swampbomb", buildsymbol = "swap_shadow" }, --绝望投泥带。看来这东西不会有皮肤了
    winona_telebrella = { --传送伞
        buildfile = "winona_telebrella", buildsymbol = "swap_winona_telebrella",
        equipfn = function(owner, item)
            Fn_setFollowSymbolFx(owner, "fx_d_winona_telebrella", {
                { name = "winona_telebrella_swap_fx", anim = nil, symbol = "swap_object", idx = 0, idx2 = 19 },
                { name = "winona_telebrella_swap_fx", anim = "swap20", noloop = true, symbol = "swap_object", idx = 19 }
            }, false)
            owner.fx_d_winona_telebrella[1]:SetLedEnabled(true)
            owner.fx_d_winona_telebrella[2]:SetLedEnabled(true)
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowSymbolFx(owner, "fx_d_winona_telebrella")
        end,
        onequipfn = function(owner, item)
            if item.swapfx ~= nil then
                item.swapfx.AnimState:PlayAnimation("noanim") --虽然无法直接删除，但是可以播放不存在的动画来实现隐藏效果
            end
            if item.swapfx2 ~= nil then
                item.swapfx2.AnimState:PlayAnimation("noanim")
            end
        end
    },
    shadow_battleaxe = { --暗影槌
        buildfile = "shadow_battleaxe", buildsymbol = "xxx",
        equipfn = function(owner, item)
            Fn_setFollowFx(owner, "fx_d_shadow_battleaxe", "shadow_battleaxe_l_fofx"..tostring(item.level or 4))
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_shadow_battleaxe")
        end,
        onequipfn = function(owner, item)
            if item.SetFxOwner ~= nil then
                item:SetFxOwner()
            end
        end
    },
    voidcloth_boomerang = { --阴郁回旋镖
        buildfile = "boomerang_voidcloth", buildsymbol = "xxx",
        equipfn = function(owner, item)
            Fn_setFollowFx(owner, "fx_d_voidcloth_boomerang", "voidcloth_boomerang_l_fofx")
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_voidcloth_boomerang")
        end,
        onequipfn = function(owner, item)
            if item.SetFxOwner ~= nil then
                item:SetFxOwner()
            end
        end
    },
    rabbitkingspear = { buildfile = "swap_rabbitkingspear", buildsymbol = "swap_rabbitkingspear" }, --兔王棍
    snowball_item = { isnoskin = true, buildfile = "snowball", buildsymbol = "swap_object" }, --雪球
    gestalt_cage = { --幻灵捕获机
        buildfile = "gestalt_cage", buildsymbol = "swap_object",
        equipfn = function(owner, item)
            Fn_setFollowFx(owner, "fx_d_gestalt_cage", "gestalt_cage_swap_fx")
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_gestalt_cage")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(item, "fx")
        end
    },
    -- minifan = { buildfile = "swap_minifan", buildsymbol = "swap_minifan" }, --有贴图之外的实体，不做幻化
    -- redlantern = { buildfile = "swap_redlantern", buildsymbol = "swap_redlantern" }, --有贴图之外的实体，不做幻化
    -- thurible = { buildfile = "swap_thurible", buildsymbol = "swap_thurible" }, --暗影香炉。有贴图之外的实体，不做幻化
    -- lucy = { buildfile = "swap_lucy_axe", buildsymbol = "swap_lucy_axe" }, --露西斧，伍迪只有一把，不做幻化
    -- propsign = { isnoskin = true, buildfile = "swap_sign_elite", buildsymbol = "swap_sign_elite" }, --猪王比赛的木牌：会在重启后自动消失，不能做幻化

    -------------------------------
    --头部-------------------------
    -------------------------------

    strawhat = { buildfile = "hat_straw", buildsymbol = "swap_hat" },
    tophat = { buildfile = "hat_top", buildsymbol = "swap_hat" },
    beefalohat = { buildfile = "hat_beefalo", buildsymbol = "swap_hat" },
    featherhat = { buildfile = "hat_feather", buildsymbol = "swap_hat" },
    beehat = { buildfile = "hat_bee", buildsymbol = "swap_hat" },
    minerhat = {
        buildfile = "hat_miner", buildsymbol = "swap_hat_off",
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            if item.components.fueled:IsEmpty() then
                itemswap["swap_hat"] = dressup:GetDressData(
                    buildskin, "hat_miner", "swap_hat_off", item.GUID, "swap"
                )
            else
                itemswap["swap_hat"] = dressup:GetDressData(
                    buildskin, "hat_miner", "swap_hat", item.GUID, "swap"
                )
            end
            dressup:SetDressTop(itemswap)
            return itemswap
        end
    },
    spiderhat = { buildfile = "hat_spider", buildsymbol = "swap_hat" },
    earmuffshat = { isopentop = true, buildfile = "hat_earmuffs", buildsymbol = "swap_hat" },
    footballhat = { checktag = true, buildfile = "hat_football", buildsymbol = "swap_hat" },
    winterhat = { buildfile = "hat_winter", buildsymbol = "swap_hat" },
    bushhat = { buildfile = "hat_bush", buildsymbol = "swap_hat" },
    flowerhat = { isopentop = true, buildfile = "hat_flower", buildsymbol = "swap_hat" },
    walrushat = { buildfile = "hat_walrus", buildsymbol = "swap_hat" },
    slurtlehat = { buildfile = "hat_slurtle", buildsymbol = "swap_hat" },
    ruinshat = { isopentop = true, buildfile = "hat_ruins", buildsymbol = "swap_hat" },
    molehat = { checktag = true, buildfile = "hat_mole", buildsymbol = "swap_hat" },
    wathgrithrhat = { checktag = true, buildfile = "hat_wathgrithr", buildsymbol = "swap_hat" },
    wathgrithr_improvedhat = { checktag = true, buildfile = "hat_wathgrithr_improved", buildsymbol = "swap_hat" },
    icehat = { buildfile = "hat_ice", buildsymbol = "swap_hat" },
    rainhat = { buildfile = "hat_rain", buildsymbol = "swap_hat" },
    catcoonhat = { buildfile = "hat_catcoon", buildsymbol = "swap_hat" },
    watermelonhat = { buildfile = "hat_watermelon", buildsymbol = "swap_hat" },
    eyebrellahat = { isopentop = true, buildfile = "hat_eyebrella", buildsymbol = "swap_hat" },
    red_mushroomhat = { buildfile = "hat_red_mushroom", buildsymbol = "swap_hat" },
    green_mushroomhat = { buildfile = "hat_green_mushroom", buildsymbol = "swap_hat" },
    blue_mushroomhat = { buildfile = "hat_blue_mushroom", buildsymbol = "swap_hat" },
    hivehat = { buildfile = "hat_hive", buildsymbol = "swap_hat" },
    dragonheadhat = { buildfile = "hat_dragonhead", buildsymbol = "swap_hat" },
    dragonbodyhat = { buildfile = "hat_dragonbody", buildsymbol = "swap_hat" },
    dragontailhat = { buildfile = "hat_dragontail", buildsymbol = "swap_hat" },
    goggleshat = { isopentop = true, buildfile = "hat_goggles", buildsymbol = "swap_hat" },
    deserthat = { buildfile = "hat_desert", buildsymbol = "swap_hat" },
    skeletonhat = { buildfile = "hat_skeleton", buildsymbol = "swap_hat" },
    walterhat = {
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}

            if dressup.inst.prefab == "walter" then
                itemswap["swap_hat"] = dressup:GetDressData(
                    buildskin, "hat_walter", "swap_hat", item.GUID, "swap"
                )
            else
                itemswap["swap_hat"] = dressup:GetDressData(
                    buildskin, "hat_walter", "swap_hat_large", item.GUID, "swap"
                )
            end
            dressup:SetDressTop(itemswap)

            return itemswap
        end,
    },
    kelphat = { isopentop = true, buildfile = "hat_kelp", buildsymbol = "swap_hat" },
    mermhat = { isopentop = true, buildfile = "hat_merm", buildsymbol = "swap_hat" },
    cookiecutterhat = { buildfile = "hat_cookiecutter", buildsymbol = "swap_hat" },
    batnosehat = { isnoskin = true, buildfile = "hat_batnose", buildsymbol = "swap_hat" },
    slurper = { --啜食者
        isnoskin = true,
        buildfile = "hat_slurper",
        buildsymbol = "swap_hat",
        equipfn = function(player, item)
            --幻化前需要关闭发光，防止玩家发光
            if item._light ~= nil and item._light.Light ~= nil then
                item._light.Light:Enable(false)
            end
        end,
        unequipfn = function(player, item)
            --取消幻化后需要恢复发光
            if item._light ~= nil and item._light.Light ~= nil then
                item._light.Light:Enable(true)
            end
        end
    },
    perd = { --火鸡
        isnoskin = true,
        dressslot = EQUIPSLOTS.HEAD,
        buildfile = "hat_straw_perd", buildsymbol = "swap_hat"
    },
    plantregistryhat = { buildfile = "hat_plantregistry", buildsymbol = "swap_hat" }, --耕作先驱帽
    nutrientsgoggleshat = { buildfile = "hat_nutrientsgoggles", buildsymbol = "swap_hat" }, --高级耕作先驱帽
    moonstorm_goggleshat = { buildfile = "hat_moonstorm_goggles", buildsymbol = "swap_hat" }, --天文护目镜
    eyemaskhat = { buildfile = "hat_eyemask", buildsymbol = "swap_hat" }, --眼面具
    balloonhat = { buildfile = "hat_balloon", buildsymbol = "swap_hat" },
    monkey_mediumhat = { buildfile = "hat_monkey_medium", buildsymbol = "swap_hat" }, --船长的三角帽
    monkey_smallhat = { buildfile = "hat_monkey_small", buildsymbol = "swap_hat" }, --海盗头巾
    polly_rogershat = { --波莉·罗杰的帽子
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            local symbol = "swap_hat"
            if not item.components.spawner.child or item.components.spawner.child.components.health:IsDead() then
                symbol = "swap_hat2"
            end

            itemswap["swap_hat"] = dressup:GetDressData(
                buildskin, "hat_polly_rogers", symbol, item.GUID, "swap"
            )
            dressup:SetDressTop(itemswap)

            return itemswap
        end
    },
    antlionhat = { buildfile = "hat_antlion", buildsymbol = "swap_hat" },
    mask_dollhat = { buildfile = "hat_mask_doll", buildsymbol = "swap_hat" },
    mask_dollbrokenhat = { buildfile = "hat_mask_dollbroken", buildsymbol = "swap_hat" },
    mask_dollrepairedhat = { buildfile = "hat_mask_dollrepaired", buildsymbol = "swap_hat" },
    mask_blacksmithhat = { buildfile = "hat_mask_blacksmith", buildsymbol = "swap_hat" },
    mask_mirrorhat = { buildfile = "hat_mask_mirror", buildsymbol = "swap_hat" },
    mask_queenhat = { buildfile = "hat_mask_queen", buildsymbol = "swap_hat" },
    mask_kinghat = { buildfile = "hat_mask_king", buildsymbol = "swap_hat" },
    mask_treehat = { buildfile = "hat_mask_tree", buildsymbol = "swap_hat" },
    mask_foolhat = { buildfile = "hat_mask_fool", buildsymbol = "swap_hat" },
    mask_sagehat = { buildfile = "hat_mask_sage", buildsymbol = "swap_hat" },
    mask_halfwithat = { buildfile = "hat_mask_halfwit", buildsymbol = "swap_hat" },
    mask_toadyhat = { buildfile = "hat_mask_toady", buildsymbol = "swap_hat" },
    nightcaphat = { buildfile = "hat_nightcap", buildsymbol = "swap_hat" }, --睡帽
    dreadstonehat = { buildfile = "hat_dreadstone", buildsymbol = "swap_hat" }, --绝望石头盔
    lunarplanthat = {
        isfullhead = true, buildfile = "hat_lunarplant", buildsymbol = "swap_hat",
        equipfn = function(owner, item)
            Fn_setFollowFx(owner, "fx_d_lunarplanthat", "lunarplanthat_fx")
            if owner.fx_d_lunarplanthat.skinbuildhash then
                local skinbuild = item.AnimState:GetSkinBuild()
                if skinbuild then
                    owner.fx_d_lunarplanthat.skinbuildhash:set(skinbuild)
                end
            end
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_lunarplanthat")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(item, "fx")
        end
    },
    alterguardianhat = {
        dressslot = "head_t",
        buildfn = function(dressup, item, buildskin)
            local dd = dressup.itemdd.alterguardianhat_lvl
            if dd == nil then --从源头获取数据，但源数据只有装备时才有，所以这里只能自己判定出来
                local lunarseedscount = 0
                local lunarseedsmaxed
                if item.components.container ~= nil then
                    lunarseedscount = #item.components.container:FindItems(function(it) return it:HasTag("lunarseed") end)
                    lunarseedsmaxed = lunarseedscount == item.components.container:GetNumSlots()
                end
                dd = (lunarseedsmaxed and 2) or
                    (lunarseedscount > TUNING.ALTERGUARDIANHAT_SEEDCOUNT_FOR_FULL_PLANAR_CONVERSION and 1) or 0
                dressup.itemdd.alterguardianhat_lvl = dd
            end
            local itemswap = {}
            local owner = dressup.inst
            if owner.fx_l_alterfront == nil then
                owner.fx_l_alterfront = SpawnPrefab("alterguardian_hat_equipped")
                owner.fx_l_alterfront:OnActivated(owner, true)
                if buildskin then
                    owner.fx_l_alterfront:SetSkin(buildskin, item.GUID)
                end
                owner.fx_l_alterfront:SetFlameLevel(dd, buildskin, item.GUID)
            end
            if owner.fx_l_alterback == nil then
                owner.fx_l_alterback = SpawnPrefab("alterguardian_hat_equipped")
                owner.fx_l_alterback:OnActivated(owner, false)
                if buildskin then
                    owner.fx_l_alterback:SetSkin(buildskin, item.GUID)
                end
                owner.fx_l_alterback:SetFlameLevel(dd, buildskin, item.GUID)
            end
            return itemswap
        end,
        unbuildfn = function(dressup, item)
            local owner = dressup.inst
            if owner.fx_l_alterfront ~= nil then
                owner.fx_l_alterfront:OnDeactivated()
                owner.fx_l_alterfront = nil
            end
            if owner.fx_l_alterback ~= nil then
                owner.fx_l_alterback:OnDeactivated()
                owner.fx_l_alterback = nil
            end
            dressup:InitGroupHead()
            dressup.itemdd.alterguardianhat_lvl = nil
        end
    },
    voidclothhat = {
        isfullhead = true, buildfile = "hat_voidcloth", buildsymbol = "swap_hat",
        equipfn = function(owner, item)
            Fn_setFollowFx(owner, "fx_d_voidclothhat", "voidclothhat_fx")
            -- owner.AnimState:SetSymbolBrightness("headbase_hat", 0)
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_voidclothhat")
            -- owner.AnimState:SetSymbolBrightness("headbase_hat", 1)
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(item, "fx")
            -- owner.AnimState:SetSymbolBrightness("headbase_hat", 1)
        end
    },
    tallbirdegg = {
        isnoskin = true,
        dressslot = "head_t2",
        buildfn = function(cpt, item, buildskin)
            local state = cpt.itemdd.tallbirdegg_state
            local itemswap = {}
            itemswap["HAT"] = cpt:GetDressData(nil, nil, nil, nil, "show")
            if state == nil then
                state = tostring(math.random(3))
                cpt.itemdd.tallbirdegg_state = state
            end
            Fn_setFollowFx(cpt.inst, "fx_d_tallbirdegg", "tallbirdegg_l_fofx"..state)
            return itemswap
        end,
        unbuildfn = function(cpt, item)
            Fn_removeFollowFx(cpt.inst, "fx_d_tallbirdegg")
            cpt:InitHide("HAT")
            cpt.itemdd.tallbirdegg_state = nil
        end
    },
    tallbirdegg_cracked = {
        isnoskin = true,
        dressslot = "head_t2",
        buildfn = function(cpt, item, buildskin)
            local state = cpt.itemdd.tallbirdegg_state
            local itemswap = {}
            itemswap["HAT"] = cpt:GetDressData(nil, nil, nil, nil, "show")
            if state == nil then
                if item.AnimState:IsCurrentAnimation("idle_hot") then
                    state = "2"
                elseif item.AnimState:IsCurrentAnimation("idle_cold") then
                    state = "3"
                else
                    state = "1"
                end
                cpt.itemdd.tallbirdegg_state = state
            end
            Fn_setFollowFx(cpt.inst, "fx_d_tallbirdegg2", "tallbirdegg_l_fofx"..state)
            return itemswap
        end,
        unbuildfn = function(cpt, item)
            Fn_removeFollowFx(cpt.inst, "fx_d_tallbirdegg2")
            cpt:InitHide("HAT")
            cpt.itemdd.tallbirdegg_state = nil
        end
    },
    woodcarvedhat = { buildfile = "hat_woodcarved", buildsymbol = "swap_hat" },
    wagpunkhat = {
        buildfile = "hat_wagpunk", buildsymbol = "swap_hat",
        equipfn = function(owner, item)
            Fn_setFollowFx(owner, "fx_d_wagpunkhat", "wagpunkhat_fx")
            if owner.fx_d_wagpunkhat ~= nil then
                owner.fx_d_wagpunkhat.level:set(5)
            end
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_wagpunkhat")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(item, "fx")
        end
    },
    moon_mushroomhat = { buildfile = "hat_moon_mushroom", buildsymbol = "swap_hat" },
    scrap_monoclehat = { isopentop = true, buildfile = "hat_scrap_monocle", buildsymbol = "swap_hat" }, --视界扩展器
    scraphat = { buildfile = "hat_scrap", buildsymbol = "swap_hat" }, --拾荒尖帽
    -- inspectacleshat = { buildfile = "hat_inspectacles", buildsymbol = "swap_hat" }, --检查专用镜。因为特效和逻辑嵌在一起，不能做幻化
    roseglasseshat = { isopentop = true, buildfile = "hat_roseglasses", buildsymbol = "swap_hat" }, --玫瑰色眼镜
    rabbithat = { --洞穴花环
        buildfile = "hat_rabbit", buildsymbol = "swap_hat",
        equipfn = function(owner, item, cpt)
            local state = cpt.itemdd.rabbithat_state
            if state == nil then
                if owner.components.sanity ~= nil and owner.components.sanity:IsInsane() then
                    state = "3"
                elseif TheWorld.state.iswinter then
                    state = "2"
                else
                    state = "1"
                end
                cpt.itemdd.rabbithat_state = state
            end
            Fn_setFollowFx(owner, "fx_d_rabbithat", "rabbithat_l_fofx"..state)
        end,
        unequipfn = function(owner, item, cpt)
            Fn_removeFollowFx(owner, "fx_d_rabbithat")
            cpt.itemdd.rabbithat_state = nil
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(item, "fx")
        end
    },
    ghostflowerhat = { isopentop = true, buildfile = "hat_ghostflower", buildsymbol = "swap_hat" }, --幽魂花冠

    -------------------------------
    --身体-------------------------
    -------------------------------

    armorwood = { buildfile = "armor_wood", buildsymbol = "swap_body" },
    armorgrass = { buildfile = "armor_grass", buildsymbol = "swap_body" },
    armordragonfly = { buildfile = "torso_dragonfly", buildsymbol = "swap_body" },
    armorslurper = { buildfile = "armor_slurper", buildsymbol = "swap_body" },
    armorskeleton = { buildfile = "armor_skeleton", buildsymbol = "swap_body" },
    armor_sanity = { buildfile = "armor_sanity", buildsymbol = "swap_body" },
    armorruins = { buildfile = "armor_ruins", buildsymbol = "swap_body" },
    armormarble = { buildfile = "armor_marble", buildsymbol = "swap_body" },
    armorsnurtleshell = { istallbody = true, buildfile = "armor_slurtleshell", buildsymbol = "swap_body_tall" },
    backpack = { isbackpack = true, buildfile = "swap_backpack" },
    krampus_sack = { isbackpack = true, buildfile = "swap_krampus_sack" },
    candybag = { isbackpack = true, buildfile = "candybag" },
    piggyback = { isbackpack = true, buildfile = "swap_piggyback" },
    icepack = { isbackpack = true, buildfile = "swap_icepack" },
    onemanband = { istallbody = true, buildfile = "swap_one_man_band", buildsymbol = "swap_body_tall" },
    amulet = {
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_body"] = dressup:GetDressData(
                buildskin, "torso_amulets", buildskin ~= nil and "swap_body" or "redamulet", item.GUID, "swap"
            )
            itemswap["backpack"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            return itemswap
        end
    },
    blueamulet = {
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_body"] = dressup:GetDressData(
                buildskin, "torso_amulets", buildskin ~= nil and "swap_body" or "blueamulet", item.GUID, "swap"
            )
            itemswap["backpack"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            return itemswap
        end
    },
    purpleamulet = {
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_body"] = dressup:GetDressData(
                buildskin, "torso_amulets", buildskin ~= nil and "swap_body" or "purpleamulet", item.GUID, "swap"
            )
            itemswap["backpack"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            return itemswap
        end
    },
    greenamulet = {
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_body"] = dressup:GetDressData(
                buildskin, "torso_amulets", buildskin ~= nil and "swap_body" or "greenamulet", item.GUID, "swap"
            )
            itemswap["backpack"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            return itemswap
        end
    },
    orangeamulet = {
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_body"] = dressup:GetDressData(
                buildskin, "torso_amulets", buildskin ~= nil and "swap_body" or "orangeamulet", item.GUID, "swap"
            )
            itemswap["backpack"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            return itemswap
        end
    },
    yellowamulet = {
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_body"] = dressup:GetDressData(
                buildskin, "torso_amulets", buildskin ~= nil and "swap_body" or "yellowamulet", item.GUID, "swap"
            )
            itemswap["backpack"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            return itemswap
        end
    },
    raincoat = { buildfile = "torso_rain", buildsymbol = "swap_body" },
    sweatervest = { buildfile = "armor_sweatervest", buildsymbol = "swap_body" },
    trunkvest_summer = { buildfile = "armor_trunkvest_summer", buildsymbol = "swap_body" },
    trunkvest_winter = { buildfile = "armor_trunkvest_winter", buildsymbol = "swap_body" },
    reflectivevest = { buildfile = "torso_reflective", buildsymbol = "swap_body" },
    hawaiianshirt = { buildfile = "torso_hawaiian", buildsymbol = "swap_body" },
    beargervest = { buildfile = "torso_bearger", buildsymbol = "swap_body" },
    cavein_boulder = { --洞穴落石
        istallbody = true,
        -- buildfn = Fn_symbolSwap
        buildfn = function(dressup, item, buildskin) --找不到原因，这个没法使用 Fn_symbolSwap
            local itemswap = {}

            if buildskin == nil then
                itemswap["swap_body_tall"] = dressup:GetDressData(
                    nil, "swap_cavein_boulder", "swap_body"..tostring(item.variation or ""), item.GUID, "swap"
                )
            else --Tip: 我怀疑官方贴图切换底层逻辑会强制一个皮肤贴图回归它的通道
                itemswap["swap_body_tall"] = dressup:GetDressData(
                    buildskin, "swap_cavein_boulder", "swap_boulder", item.GUID, "swap"
                )
            end

            return itemswap
        end
    },
    sunkenchest = { isnoskin = true, istallbody = true, buildfile = "swap_sunken_treasurechest", buildsymbol = "swap_body" }, --沉底宝箱
    shell_cluster = { isnoskin = true, istallbody = true, buildfile = "singingshell_cluster", buildsymbol = "swap_body" }, --贝壳堆
    glassspike_short = { isnoskin = true, istallbody = true, buildfile = "swap_glass_spike", buildsymbol = "swap_body_short" }, --小玻璃尖刺
    glassspike_med = { isnoskin = true, istallbody = true, buildfile = "swap_glass_spike", buildsymbol = "swap_body_med" }, --中玻璃尖刺
    glassspike_tall = { isnoskin = true, istallbody = true, buildfile = "swap_glass_spike", buildsymbol = "swap_body_tall" }, --大玻璃尖刺
    glassblock = { isnoskin = true, istallbody = true, buildfile = "swap_glass_block", buildsymbol = "swap_body" }, --玻璃城堡
    potatosack = { isnoskin = true, istallbody = true, buildfile = "potato_sack", buildsymbol = "swap_body" }, --土豆袋
    armor_bramble = { buildfile = "armor_bramble", buildsymbol = "swap_body" }, --荆棘甲
    spicepack = { isbackpack = true, buildfile = "swap_chefpack" },
    seedpouch = { isbackpack = true, buildfile = "seedpouch" },
    oceantreenut = { isnoskin = true, istallbody = true, buildfile = "oceantreenut", buildsymbol = "swap_body" }, --疙瘩树果
    carnival_vest_a = { isbackpack = true, buildfile = "carnival_vest_a" }, --叽叽喳喳围巾
    carnival_vest_b = { isbackpack = true, buildfile = "carnival_vest_b" }, --叽叽喳喳斗篷
    carnival_vest_c = { isbackpack = true, buildfile = "carnival_vest_c" }, --叽叽喳喳小披肩
    balloonvest = { buildfile = "balloonvest", buildsymbol = "swap_body" },
    costume_doll_body = { buildfile = "costume_doll_body", buildsymbol = "swap_body" },
    costume_queen_body = { buildfile = "costume_queen_body", buildsymbol = "swap_body" },
    costume_king_body = { buildfile = "costume_king_body", buildsymbol = "swap_body" },
    costume_blacksmith_body = { buildfile = "costume_blacksmith_body", buildsymbol = "swap_body" },
    costume_mirror_body = { buildfile = "costume_mirror_body", buildsymbol = "swap_body" },
    costume_tree_body = { buildfile = "costume_tree_body", buildsymbol = "swap_body" },
    costume_fool_body = { buildfile = "costume_fool_body", buildsymbol = "swap_body" },
    armordreadstone = { buildfile = "armor_dreadstone", buildsymbol = "swap_body" },
    armor_lunarplant = { --亮茄盔甲
        buildfile = "armor_lunarplant", buildsymbol = "swap_body",
        equipfn = function(owner, item)
            Fn_setFollowFx(owner, "fx_d_armor_lunarplant", "armor_lunarplant_glow_fx")
            if owner.fx_d_armor_lunarplant.skinbuildhash then
                local skinbuild = item.AnimState:GetSkinBuild()
                if skinbuild then
                    owner.fx_d_armor_lunarplant.skinbuildhash:set(skinbuild)
                end
            end
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_armor_lunarplant")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(item, "fx")
        end
    },
    armor_lunarplant_husk = { --荆棘茄甲
        buildfile = "armor_lunarplant_husk", buildsymbol = "swap_body",
        equipfn = function(owner, item)
            Fn_setFollowFx(owner, "fx_d_armor_lunarplant_husk", "armor_lunarplant_husk_glow_fx")
            if owner.fx_d_armor_lunarplant_husk.skinbuildhash then
                local skinbuild = item.AnimState:GetSkinBuild()
                if skinbuild then
                    owner.fx_d_armor_lunarplant_husk.skinbuildhash:set(skinbuild)
                end
            end
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_armor_lunarplant_husk")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(item, "fx")
        end
    },
    armor_voidcloth = {
        buildfile = "armor_voidcloth", buildsymbol = "swap_body",
        equipfn = function(owner, item)
            Fn_setFollowFx(owner, "fx_d_armor_voidcloth", "armor_voidcloth_fx")
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_armor_voidcloth")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(item, "fx")
        end
    },
    armorwagpunk = {
        buildfile = "armor_wagpunk_01", buildsymbol = "swap_body",
        equipfn = function(owner, item)
            Fn_setFollowFx(owner, "fx_d_armorwagpunk", "armorwagpunk_fx")
            if owner.fx_d_armorwagpunk ~= nil then
                owner.fx_d_armorwagpunk.level:set(5)
            end
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_armorwagpunk")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(item, "fx")
        end
    },
    armor_carrotlure = { buildfile = "armor_carrotlure", buildsymbol = "swap_body" }, --胡萝卜外套
    -- moon_altar --月科技系列的可搬动建筑，独一无二的，不能幻化
    -- sculpture_knighthead = { --骑士的大理石碎片。全图唯一性，不做幻化
    --     isnoskin = true,
    --     istallbody = true,
    --     buildfile = "swap_sculpture_knighthead",
    --     buildsymbol = "swap_body"
    -- },
    -- sculpture_bishophead = { --主教的大理石碎片。全图唯一性，不做幻化
    --     isnoskin = true,
    --     istallbody = true,
    --     buildfile = "swap_sculpture_bishophead",
    --     buildsymbol = "swap_body"
    -- },
    -- sculpture_rooknose = { --战车的大理石碎片。全图唯一性，不做幻化
    --     isnoskin = true,
    --     istallbody = true,
    --     buildfile = "swap_sculpture_rooknose",
    --     buildsymbol = "swap_body"
    -- },

    -------------------------------
    --棱镜-------------------------
    -------------------------------

    agronssword = { --tip：通过幻化就可以把这把剑带到其他世界啦！
        isnoskin = true, -- isshield = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            local symbol = item._revolt_l and "swap2" or "swap1"
            itemswap["lantern_overlay"] = dressup:GetDressData(nil, item._dd.build, symbol, item.GUID, "swap")
            itemswap["swap_shield"] = dressup:GetDressData(nil, item._dd.build, symbol, item.GUID, "swap")
            dressup:SetDressShield(itemswap)
            return itemswap
        end
    },
    backcub = {
        isnoskin = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            local swapdd
            if item._dd ~= nil then
                swapdd = dressup:GetDressData(nil, item._dd.build, item._dd.file, item.GUID, "swap")
            else
                swapdd = dressup:GetDressData(nil, "swap_backcub", "swap_body", item.GUID, "swap")
            end
            if dressup.inst.prefab == "webber" then
                itemswap["swap_body_tall"] = swapdd
                itemswap["swap_body"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            else
                itemswap["swap_body"] = swapdd
            end
            itemswap["backpack"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            return itemswap
        end,
        unbuildfn = function(dressup, item)
            if dressup.inst.prefab == "webber" then
                dressup:InitClear("swap_body_tall")
            end
            dressup:InitClear("swap_body")
            dressup:InitClear("backpack")
        end
    },
    boltwingout = { isnoskin = true, buildfile = "swap_boltwingout", buildsymbol = "swap_body" },
    -- book_weather --该道具贴图切换比较特殊，不做幻化
    shield_l_sand = { isnoskin = true, isshield = true, buildfile = "shield_l_sand", buildsymbol = "swap_shield" },
    shield_l_log = { isnoskin = true, isshield = true, buildfile = "shield_l_log", buildsymbol = "swap_shield" },
    dualwrench = { isnoskin = true, buildfile = "swap_dualwrench", buildsymbol = "swap_dualwrench" },
    fimbul_axe = { isnoskin = true, buildfile = "fimbul_axe", buildsymbol = "swap_base" },
    giantsfoot = { isnoskin = true, isbackpack = true, buildfile = "giantsfoot", buildsymbol = "swap_body" },
    hat_albicans_mushroom = { isnoskin = true, buildfile = "hat_albicans_mushroom", buildsymbol = "swap_hat" },
    hat_cowboy = {
        isnoskin = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            if item._dd ~= nil then
                itemswap["swap_hat"] = dressup:GetDressData(
                    nil, item._dd.build, item._dd.file, item.GUID, "swap"
                )
                itemswap["swap_body"] = dressup:GetDressData(
                    nil, item._dd.build, "swap_body", item.GUID, "swap"
                )
            else
                itemswap["swap_hat"] = dressup:GetDressData(
                    nil, "hat_cowboy", "swap_hat", item.GUID, "swap"
                )
                itemswap["swap_body"] = dressup:GetDressData(
                    nil, "hat_cowboy", "swap_body", item.GUID, "swap"
                )
            end
            dressup:SetDressTop(itemswap)
            return itemswap
        end,
        unbuildfn = function(dressup, item)
            dressup:InitGroupHead()
            dressup:InitClear("swap_body") --还原牛仔围巾的效果
        end
    },
    hat_lichen = { isnoskin = true, isopentop = true, buildfile = "hat_lichen", buildsymbol = "swap_hat" },
    hat_mermbreathing = {
        isnoskin = true, isopentop = true,
        buildfile = "hat_mermbreathing", buildsymbol = "swap_hat"
    },
    lileaves = { isnoskin = true, buildfile = "swap_lileaves", buildsymbol = "swap_lileaves" },
    neverfade = {
        isnoskin = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}

            if item._dd ~= nil then
                if item.isbroken_l then
                    itemswap["swap_object"] = dressup:GetDressData(
                        nil, item._dd.build2, item._dd.file2, item.GUID, "swap"
                    )
                else
                    itemswap["swap_object"] = dressup:GetDressData(
                        nil, item._dd.build, item._dd.file, item.GUID, "swap"
                    )
                end
            else
                if item.isbroken_l then
                    itemswap["swap_object"] = dressup:GetDressData(
                        nil, "swap_neverfade_broken", "swap_neverfade_broken", item.GUID, "swap"
                    )
                else
                    itemswap["swap_object"] = dressup:GetDressData(
                        nil, "swap_neverfade", "swap_neverfade", item.GUID, "swap"
                    )
                end
            end
            dressup:SetDressHand(itemswap)

            return itemswap
        end
    },
    orchitwigs = { isnoskin = true, buildfile = "swap_orchitwigs", buildsymbol = "swap_orchitwigs" },
    pinkstaff = { isnoskin = true, buildfile = "swap_pinkstaff", buildsymbol = "swap_pinkstaff" },
    refractedmoonlight = { --tip：通过幻化就可以把这把剑带到其他世界啦！
        isnoskin = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_object"] = dressup:GetDressData(
                nil, item._dd.build, item._revolt_l and "swap2" or "swap1", item.GUID, "swap"
            )
            dressup:SetDressHand(itemswap)
            return itemswap
        end
    },
    rosorns = { isnoskin = true, buildfile = "swap_rosorns", buildsymbol = "swap_rosorns" },
    sachet = { isnoskin = true, buildfile = "sachet", buildsymbol = "swap_body" },
    tripleshovelaxe = { isnoskin = true, buildfile = "tripleshovelaxe", buildsymbol = "swap" },
    triplegoldenshovelaxe = { isnoskin = true, buildfile = "triplegoldenshovelaxe", buildsymbol = "swap" },
    theemperorscrown = {
        isnoskin = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_hat"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            dressup:SetDressOpenTop(itemswap)
            return itemswap
        end,
        unbuildfn = function(dressup, item) end --没啥好恢复的
    },
    theemperorsmantle = {
        isnoskin = true,
        istallbody = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_body_tall"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            return itemswap
        end,
        unbuildfn = function(dressup, item) end --没啥好恢复的
    },
    theemperorspendant = {
        isnoskin = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["backpack"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            itemswap["swap_body"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            return itemswap
        end,
        unbuildfn = function(dressup, item) end --没啥好恢复的
    },
    theemperorsscepter = {
        isnoskin = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            itemswap["swap_object"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
            dressup:SetDressHand(itemswap)
            return itemswap
        end,
        unbuildfn = function(dressup, item) end --没啥好恢复的
    },
    fishhomingtool_awesome = {
        isnoskin = true, dressslot = EQUIPSLOTS.HANDS,
        buildfile = "fishhomingtool_awesome", buildsymbol = "swap"
    },
    fishhomingbait = {
        isnoskin = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            local dd = item._dd[item.components.fishhomingbait.type_shape]
            if dd.isshield then
                itemswap["swap_shield"] = dressup:GetDressData(nil, dd.build, dd.swap, item.GUID, "swap")
                itemswap["lantern_overlay"] = dressup:GetDressData(nil, dd.build, dd.swap, item.GUID, "swap")
                dressup:SetDressShield(itemswap)
            else
                itemswap["swap_object"] = dressup:GetDressData(nil, dd.build, dd.swap, item.GUID, "swap")
                dressup:SetDressHand(itemswap)
            end
            return itemswap
        end
    },
    dish_tomahawksteak = {
        isnoskin = true, buildfile = "dish_tomahawksteak", buildsymbol = "swap",
        equipfn = function(owner, item)
            if item._dd ~= nil and item._dd.build == "dish_tomahawksteak_twist" then
                Fn_setFollowFx(owner, "fx_d_steak_twist", "dish_tomahawksteak_twist_fofx")
            end
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_steak_twist")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "legion_steak_twist_fofx")
        end
    },
    siving_feather_fake = {
        isnoskin = true, buildfile = "siving_feather_fake", buildsymbol = "swap",
        equipfn = function(owner, item)
            if item._dd ~= nil and item._dd.build == "siving_feather_fake_collector" then
                Fn_setFollowFx(owner, "fx_d_sivfea_fake", "sivfea_fake_collector_fofx")
            end
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_sivfea_fake")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_l_sivfea_fake")
        end
    },
    siving_feather_real = {
        isnoskin = true, buildfile = "siving_feather_real", buildsymbol = "swap",
        equipfn = function(owner, item)
            if item._dd ~= nil and item._dd.build == "siving_feather_real_collector" then
                Fn_setFollowFx(owner, "fx_d_sivfea_real", "sivfea_real_collector_fofx")
            end
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_sivfea_real")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_l_sivfea_real")
        end
    },
    siving_mask = {
        isnoskin = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            if item._dd ~= nil then
                itemswap["swap_hat"] = dressup:GetDressData(
                    nil, item._dd.build, item._dd.file or GetSymbol_sivmask(dressup), item.GUID, "swap"
                )
                if item._dd.isopentop then
                    dressup:SetDressOpenTop(itemswap)
                else
                    dressup:SetDressTop(itemswap)
                end
            else
                itemswap["swap_hat"] = dressup:GetDressData(
                    nil, "siving_mask", GetSymbol_sivmask(dressup), item.GUID, "swap"
                )
                dressup:SetDressOpenTop(itemswap)
            end
            return itemswap
        end
    },
    siving_mask_gold = {
        isnoskin = true,
        buildfn = function(dressup, item, buildskin)
            local itemswap = {}
            if item._dd ~= nil then
                if item._dd.build == "siving_mask_gold_era" then
                    Fn_setFollowFx(dressup.inst, "fx_d_sivmask", "sivmask_era_fofx")
                    itemswap["swap_hat"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
                    dressup:SetDressOpenTop(itemswap)
                elseif item._dd.build == "siving_mask_gold_era2" then
                    Fn_setFollowFx(dressup.inst, "fx_d_sivmask", "sivmask_era2_fofx")
                    itemswap["swap_hat"] = dressup:GetDressData(nil, nil, nil, nil, "clear")
                    dressup:SetDressOpenTop(itemswap)
                else
                    itemswap["swap_hat"] = dressup:GetDressData(
                        nil, item._dd.build, item._dd.file or GetSymbol_sivmask(dressup), item.GUID, "swap"
                    )
                    if item._dd.isopentop then
                        dressup:SetDressOpenTop(itemswap)
                    else
                        dressup:SetDressTop(itemswap)
                    end
                end
            else
                itemswap["swap_hat"] = dressup:GetDressData(
                    nil, "siving_mask_gold", GetSymbol_sivmask(dressup), item.GUID, "swap"
                )
                dressup:SetDressOpenTop(itemswap)
            end
            return itemswap
        end,
        unequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_d_sivmask")
        end,
        onequipfn = function(owner, item)
            Fn_removeFollowFx(owner, "fx_l_sivmask")
        end
    },
    siving_suit = { isnoskin = true, buildfile = "siving_suit", buildsymbol = "swap_body" },
    siving_suit_gold = { isnoskin = true, buildfile = "siving_suit_gold", buildsymbol = "swap_body" },
    hat_elepheetle = { isnoskin = true, buildfile = "hat_elepheetle", buildsymbol = "swap_hat" },
    armor_elepheetle = { isnoskin = true, buildfile = "armor_elepheetle", buildsymbol = "swap_body" },
    lance_carrot_l = { isnoskin = true, buildfile = "lance_carrot_l", buildsymbol = "swap_object" },
    acc_l_shadowmirror = { isnoskin = true, isshield = true, buildfile = "acc_l_shadowmirror", buildsymbol = "swap_shield" },
    hat_whisperose = { isnoskin = true, isopentop = true, buildfile = "hat_whisperose", buildsymbol = "swap_hat" },
    shadowbrush_l = { isnoskin = true, buildfile = "shadowbrush_l", buildsymbol = "swap_object" },
}
dressup_data.agronssword_item_waxed = dressup_data.agronssword
dressup_data.refractedmoonlight_item_waxed = dressup_data.refractedmoonlight

if _G.rawget(_G, "DRESSUP_DATA_LEGION") then --已有变量了(多半是别的模组加的)，那就逐一添加数据
    for k, v in pairs(dressup_data) do
        _G.DRESSUP_DATA_LEGION[k] = v
    end
else --没有变量，那就直接赋值即可
    _G.DRESSUP_DATA_LEGION = dressup_data
end

--统一添加各种雕像的幻化数据
local pieces = {
    "pawn", "rook", "knight", "bishop", "muse", "formal", "hornucopia", "pipe",
    "deerclops", "bearger", "moosegoose", "dragonfly", "minotaur", "guardianphase3",
    "clayhound", "claywarg", "butterfly", "anchor", "moon", "carrat", "beefalo",
    "crabking", "malbatross", "toadstool", "stalker", "klaus", "beequeen", "antlion",
    "eyeofterror", "twinsofterror", "kitcoon", "catcoon", "manrabbit", "daywalker",
    "deerclops_mutated", "warg_mutated", "bearger_mutated", "yotd", "sharkboi",
    "wormboss", "daywalker2", "yots",
    "lggoldgod", "lgfiregod"  --【海洋传说】
}
-- local materials = {
--     "marble", "stone", "moonglass",
-- }
for _,v in pairs(pieces) do
    _G.DRESSUP_DATA_LEGION["chesspiece_"..v] = {
        isnoskin = true,
        istallbody = true,
        buildfn = Fn_symbolSwap
    }
end
pieces = nil

--统一添加各种巨型作物的幻化数据
local oversizecrops = {
    asparagus = "farm_plant_asparagus",
    garlic = "farm_plant_garlic",
    pumpkin = "farm_plant_pumpkin",
    corn = "farm_plant_corn_build",
    onion = "farm_plant_onion_build",
    potato = "farm_plant_potato",
    dragonfruit = "farm_plant_dragonfruit_build",
    pomegranate = "farm_plant_pomegranate_build",
    eggplant = "farm_plant_eggplant_build",
    tomato = "farm_plant_tomato",
    watermelon = "farm_plant_watermelon_build",
    pepper = "farm_plant_pepper",
    durian = "farm_plant_durian_build",
    carrot = "farm_plant_carrot",
    pineananas = "farm_plant_pineananas",
    gourd = "farm_plant_gourd", --【神话书说】巨型葫芦(没有做腐烂状态的)
    lg_putao = "farm_plant_lg_putao", --【海洋传说】巨型葡萄
    lg_mangguo = "farm_plant_lg_mangguo", --【海洋传说】巨型芒果
    lz_lizhi = "farm_plant_lz_lizhi", --【荔枝枝】巨型荔枝
}
local cropdressdata = {
    isnoskin = true,
    istallbody = true,
    buildfn = Fn_symbolSwap
}
for k,v in pairs(oversizecrops) do
    _G.DRESSUP_DATA_LEGION[k.."_oversized"] = cropdressdata
    _G.DRESSUP_DATA_LEGION[k.."_oversized_waxed"] = cropdressdata
    _G.DRESSUP_DATA_LEGION[k.."_oversized_rotten"] = cropdressdata
end
oversizecrops = nil
_G.DRESSUP_DATA_LEGION["immortal_fruit_oversized"] = cropdressdata --【能力勋章】巨型不朽果实(没有其他状态的)
_G.DRESSUP_DATA_LEGION["medal_gift_fruit_oversized"] = cropdressdata --【能力勋章】巨型包果(没有其他状态的)
_G.DRESSUP_DATA_LEGION["snowman"] = cropdressdata

--统一添加枕头幻化数据
for material, _ in pairs(require("prefabs/pillow_defs")) do
    _G.DRESSUP_DATA_LEGION["handpillow_"..material] = {
        buildfile = "swap_pillows_"..material,
        buildsymbol = "swap_object"
    }
    _G.DRESSUP_DATA_LEGION["bodypillow_"..material] = {
        buildfile = "swap_pillows_"..material,
        buildsymbol = "swap_body"
    }
end

--统一添加猫咪、鸟类、物品幻化数据
local animaldd = {
    kitcoon_forest = 2, kitcoon_savanna = 2, kitcoon_deciduous = 2,
    kitcoon_marsh = 2, kitcoon_grass = 2, kitcoon_rocky = 2,
    kitcoon_desert = 2, kitcoon_moon = 2, kitcoon_yot = 2,
    crow = 2, robin = 2, robin_winter = 2, canary = 2, puffin = 2, quagmire_pigeon = 2,
    bird_mutant = 2, bird_mutant_spitter = 2,
    buzzard = 2, smallbird = 2,
    poop = 1, guano = 1, spoiled_food = 1
}
local function buildfn_animal(dressup, item, buildskin)
    local itemswap = {}
    itemswap["HAT"] = dressup:GetDressData(nil, nil, nil, nil, "show")
    Fn_setFollowFx(dressup.inst, "fx_d_"..item.prefab, item.prefab.."_l_fofx")
    return itemswap
end
local function unbuildfn_animal(dressup, item)
    Fn_removeFollowFx(dressup.inst, "fx_d_"..item.prefab)
    dressup:InitHide("HAT")
end
for k,v in pairs(animaldd) do
    _G.DRESSUP_DATA_LEGION[k] = {
        isnoskin = true, dressslot = "head_t2",
        -- lvl = v > 1 and v or nil,
        buildfn = buildfn_animal, unbuildfn = unbuildfn_animal
    }
end
animaldd = nil

-------------------
-------------------

if not IsServer then return end

--------------------------------------------------------------------------
--[[ 切换symbol时固定为幻化的装饰 ]]
--------------------------------------------------------------------------

local function FileDeal_swap(inst, animstate, symbol)
    if inst.components.dressup and inst.components.dressup.swaplist[symbol] ~= nil then
        local swapdata = inst.components.dressup.swaplist[symbol]
        if swapdata.type == "swap" then
            if swapdata.buildskin ~= nil then
                --Tip：一个皮肤物品第一次使用这个函数时，在那一帧内必须没被删除，否则该函数会引起崩溃
                animstate:OverrideItemSkinSymbol(
                    symbol,
                    swapdata.buildskin,
                    swapdata.buildsymbol,
                    swapdata.guid,
                    swapdata.buildfile
                )
            else
                animstate:OverrideSymbol(symbol, swapdata.buildfile, swapdata.buildsymbol)
            end
            -- print("----"..symbol.."-"..swapdata.buildfile.."-"..swapdata.buildsymbol.."-"..tostring(swapdata.buildskin))
        elseif swapdata.type == "clear" then
            animstate:ClearOverrideSymbol(symbol)
        else --还剩 showsym hidesym 在这个情况下不处理
            return false
        end
        return true
    else
        return false
    end
end
local function FileDeal_show(inst, animstate, symbol)
    if inst.components.dressup and inst.components.dressup.swaplist[symbol] ~= nil then
        local swapdata = inst.components.dressup.swaplist[symbol]
        if swapdata.type == "swap" or swapdata.type == "showsym" then --都 swap 了，肯定是要显示的
            animstate:ShowSymbol(symbol)
        elseif swapdata.type == "hidesym" then
            animstate:HideSymbol(symbol)
        else --还剩 clear
            return false
        end
        return true
    else
        return false
    end
end
local function SymbolDeal_show(inst, animstate, symbol)
    if inst.components.dressup and inst.components.dressup.swaplist[symbol] ~= nil then
        local swapdata = inst.components.dressup.swaplist[symbol]
        if swapdata.type == "show" then
            animstate:Show(symbol)
        elseif swapdata.type == "hide" then
            animstate:Hide(symbol)
        else
            return false
        end
        return true
    else
        return false
    end
end
local function HelmDeal_show(inst, animstate, value)
    if inst.components.dressup and inst.components.dressup.swaplist["helmex"] ~= nil then
        local swapdata = inst.components.dressup.swaplist["helmex"]
        if swapdata.type == "yes" then
            animstate:UseHeadHatExchange(true)
        elseif swapdata.type == "no" then
            animstate:UseHeadHatExchange(false)
        else
            return false
        end
        return true
    else
        return false
    end
end

--显示、隐藏、修改动画文件的"动画通道"
local hook_OverrideSymbol = UserDataHook.MakeHook("AnimState","OverrideSymbol",
    function(inst, symbol, build, file)
        -- print("1----"..symbol.."-"..build.."-"..file)
        return FileDeal_swap(inst, inst.userdatas.AnimState, symbol)
    end
)
local hook_OverrideItemSkinSymbol = UserDataHook.MakeHook("AnimState","OverrideItemSkinSymbol",
    function(inst, symbol, ...)
        -- print("2----"..symbol)
        return FileDeal_swap(inst, inst.userdatas.AnimState, symbol)
    end
)
local hook_ClearOverrideSymbol = UserDataHook.MakeHook("AnimState","ClearOverrideSymbol",
    function(inst, symbol, ...)
        return FileDeal_swap(inst, inst.userdatas.AnimState, symbol)
    end
)
local hook_ShowSymbol = UserDataHook.MakeHook("AnimState","ShowSymbol",
    function(inst, symbol, ...)
        return FileDeal_show(inst, inst.userdatas.AnimState, symbol)
    end
)
local hook_HideSymbol = UserDataHook.MakeHook("AnimState","HideSymbol",
    function(inst, symbol, ...)
        return FileDeal_show(inst, inst.userdatas.AnimState, symbol)
    end
)

--显示或隐藏动画中的"图片名"
local hook_Show = UserDataHook.MakeHook("AnimState","Show",
    function(inst, symbol, ...)
        return SymbolDeal_show(inst, inst.userdatas.AnimState, symbol)
    end
)
local hook_Hide = UserDataHook.MakeHook("AnimState","Hide",
    function(inst, symbol, ...)
        return SymbolDeal_show(inst, inst.userdatas.AnimState, symbol)
    end
)

--完全遮盖头部
local hook_UseHeadHatExchange = UserDataHook.MakeHook("AnimState","UseHeadHatExchange",
    function(inst, enable, ...)
        return HelmDeal_show(inst, inst.userdatas.AnimState, enable)
    end
)

AddPlayerPostInit(function(inst)
    UserDataHook.Hook(inst, hook_OverrideSymbol)
    UserDataHook.Hook(inst, hook_OverrideItemSkinSymbol)
    UserDataHook.Hook(inst, hook_ClearOverrideSymbol)
    UserDataHook.Hook(inst, hook_Show)
    UserDataHook.Hook(inst, hook_Hide)
    UserDataHook.Hook(inst, hook_ShowSymbol)
    UserDataHook.Hook(inst, hook_HideSymbol)
    UserDataHook.Hook(inst, hook_UseHeadHatExchange)

    inst.AnimState:Hide("LANTERN_OVERLAY") --人物默认清除提灯光效贴图，防止幻化的提灯显示出问题
    inst:AddComponent("dressup")
end)

--知识点，就不删除了
-- AddPlayerPostInit(function(inst)
--     local AnimState = getmetatable(inst.AnimState).__index
--     local OverrideSymbol_old = AnimState.OverrideSymbol
-- end)

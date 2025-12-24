local TOOLS_L = require("tools_legion")
local ZIP_SOAK_L = require("zip_soak_legion")
local TOOLS_F = require("tools_fx_legion")
local prefs = {}
local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas = {} --专门放各个prefab独特的变量

fns.dd_float = {
    fish = { nil, "small", 0.03, {0.7, 0.55, 0.7} }
}
fns.SetFloatFx = function(inst, float)
    if float[1] ~= nil then
        inst.AnimState:SetFloatParams(float[1], 1.0, 1) --第三个参数可以让动画像在水里漂浮一样，上下浮动
    end
    if float[2] ~= nil then
        local fx = SpawnPrefab("float_front_l_fx")
        fx.entity:SetParent(inst.entity)
        fx.Transform:SetPosition(0, float[3] or 0, 0)
        fx.AnimState:PlayAnimation("idle_front_"..float[2], true)
        inst.fx_front = fx
        fx = SpawnPrefab("float_back_l_fx")
        fx.entity:SetParent(inst.entity)
        fx.Transform:SetPosition(0, float[3] or 0, 0)
        fx.AnimState:PlayAnimation("idle_back_"..float[2], true)
        inst.fx_back = fx
        if float[4] ~= nil then
            if type(float[4]) == "table" then
                inst.fx_front.Transform:SetScale(float[4][1], float[4][2], float[4][3])
                inst.fx_back.Transform:SetScale(float[4][1], float[4][2], float[4][3])
            else
                inst.fx_front.Transform:SetScale(float[4], float[4], float[4])
                inst.fx_back.Transform:SetScale(float[4], float[4], float[4])
            end
        end
    end
end
fns.Dirty_float = function(inst)
    local key = inst._floatfx_l:value()
    if key == nil or key == "" or fns.dd_float[key] == nil then
        return
    end
    fns.SetFloatFx(inst, fns.dd_float[key])
end
fns.InitSimpleFloat = function(inst, name, dirtyfn, value)
    inst._floatfx_l = net_string(inst.GUID, name.."._floatfx_l", "floatfx_l_dirty")
    inst._floatfx_l:set_local(value or "")
    if not TheNet:IsDedicated() then --客户端或不开洞穴的房主服务器进程
        if dirtyfn == nil then
            dirtyfn = fns.Dirty_float
        end
        inst:ListenForEvent("floatfx_l_dirty", dirtyfn)
        if value ~= nil then --说明需要初始化
            dirtyfn(inst)
        end
    end
end

fns.GetAssets = function(name, other)
    local sets = {
        Asset("ANIM", "anim/"..name..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/"..name..".xml", 256)
    }
    if other ~= nil then
        for _, v in pairs(other) do
            table.insert(sets, v)
        end
    end
    return sets
end
fns.GetAssets2 = function(name, build, other)
    local sets = {
        Asset("ANIM", "anim/"..build..".zip"),
        Asset("ATLAS", "images/inventoryimages/"..name..".xml"),
        Asset("IMAGE", "images/inventoryimages/"..name..".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/"..name..".xml", 256)
    }
    if other ~= nil then
        for _, v in pairs(other) do
            table.insert(sets, v)
        end
    end
    return sets
end
fns.CommonFn = function(inst, bank, build, anim, isloop)
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build or bank)
    inst.AnimState:PlayAnimation(anim or "idle", isloop)
end
fns.SetRotatable_com = function(inst)
    inst:AddTag("rotatableobject") --能让栅栏击剑起作用
    inst:AddTag("flatrotated_l") --棱镜标签：旋转时旋转180度
    inst.Transform:SetTwoFaced() --两个面，这样就可以左右不同（再多貌似有问题）
end
fns.SetWorkable = function(inst, onworked, onfinished, actname, workleft) --可破坏组件
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS[actname or "DIG"])
    inst.components.workable:SetWorkLeft(workleft or 1)
    if onworked then
        inst.components.workable:SetOnWorkCallback(onworked)
    end
    if onfinished then
        inst.components.workable:SetOnFinishCallback(onfinished)
    end
end
fns.SetContainer = function(inst, name, onopen, onclose, isinf) --容器组件
    inst:AddComponent("container")
    inst.components.container:WidgetSetup(name)
    if isinf then
        inst.components.container:EnableInfiniteStackSize(true)
    end
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
end

--------------------------------------------------------------------------
--[[ 各种地垫、地毯 ]]
--------------------------------------------------------------------------

pas.MakeCarpet = function(data)
    table.insert(prefs, Prefab(data.name, function()
        local inst = CreateEntity()
        if data.fn_common ~= nil then
            data.fn_common(inst)
        end
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetFinalOffset(1)

        inst:AddTag("DECOR")
        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")
        inst:AddTag("carpet_l") --棱镜标签：地毯识别

        LS_C_Init(inst, data.name, false)

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst:AddComponent("lootdropper")
        inst:AddComponent("savedrotation")

        if data.fn_server ~= nil then
            data.fn_server(inst)
        end

        return inst
    end, data.assets, nil))
end
pas.OnRemove_carpet = function(inst, doer)
    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
end
pas.ServerFn_carpet = function(inst)
    inst.legionfn_onremove = pas.OnRemove_carpet
end

pas.MakeCarpet({ ------白木地垫
    assets = { Asset("ANIM", "anim/carpet_whitewood.zip") },
    name = "carpet_whitewood", fn_server = pas.ServerFn_carpet,
    fn_common = function(inst)
        fns.CommonFn(inst, "carpet_whitewood", nil, nil, nil)
    end
})
pas.MakeCarpet({ ------白木地毯
    assets = { Asset("ANIM", "anim/carpet_whitewood.zip") },
    name = "carpet_whitewood_big", fn_server = pas.ServerFn_carpet,
    fn_common = function(inst)
        fns.CommonFn(inst, "carpet_whitewood", nil, "idle_big", nil)
        inst:AddTag("carpet_big")
    end
})
pas.MakeCarpet({ ------线绒地垫
    assets = { Asset("ANIM", "anim/carpet_plush.zip") },
    name = "carpet_plush", fn_server = pas.ServerFn_carpet,
    fn_common = function(inst)
        fns.CommonFn(inst, "carpet_plush", nil, nil, nil)
    end
})
pas.MakeCarpet({ ------线绒地毯
    assets = { Asset("ANIM", "anim/carpet_plush.zip") },
    name = "carpet_plush_big", fn_server = pas.ServerFn_carpet,
    fn_common = function(inst)
        fns.CommonFn(inst, "carpet_plush", nil, "idle_big", nil)
        inst:AddTag("carpet_big")
    end
})

--------------------------------------------------------------------------
--[[ 各种泉池 ]]
--------------------------------------------------------------------------

--Tip：一个对象体积设置为5.5时，玩家居然可以走到距离这个对象4.5左右的位置，
--      但对象体积为2.5时，玩家却只能走到距离这个对象2.8左右的位置。这就挺奇葩的了，暂时不理解原因！
--      不过，若是站在4.5位置时丢弃物品，物品会被挤出4.5的范围
pas.rad_pond = {
    base = 5.5, --基础体积
    clear = 4.4, --池塘清理半径。由于玩家能走到距离池塘中心4.5左右的位置，所以这个值得小于4.5才行
    fx = 3.5, --各种特效和装饰的最大半径
    steam = 2.8, --自制蒸汽特效最大半径
    deploy = 2.5, --周围可摆放对象的限制半径
    pondbldg_fish = { 2.0, 3.5, 0, 0 },
    pondbldg_soak = { 4.7, 5.7, 0, 0 }
}
pas.rad_pond_s = {
    base = 2.5, clear = 2.5, fx = 1.8, steam = 1.2, deploy = 1.2,
    pondbldg_fish = { 1.2, 2.2, 0, 0 },
    pondbldg_soak = { 3.0, 3.8, 0, 0 }
}
pas.fxdd_pondsteam = {
    { bank = "crater_steam", build = "crater_steam", anims = { "steam1", "steam2", "steam3", "steam4" } },
    { bank = "slow_steam", build = "slow_steam", anims = { "steam1", "steam2", "steam3", "steam4", "steam5" } }
}
pas.fxdd_pondbubble = { { anims = { "bubbles_1", "bubbles_2", "bubbles_3" } } }
pas.fxdd_pondsteam_cold = {
    { anims = { "idle" } }
}
pas.fxdd_pondsteam2_cold = {
    { "pre", "loop", "loop", "loop", "pst" },
    { "pre", "loop", "loop", "loop", "loop", "loop", "loop", "pst" },
    { "pre", "loop", "loop", "pst" },
    { "pre", "loop", "loop", "loop", "loop", "loop", "pst" },
    { "pre", "loop", "loop", "loop", "loop", "loop", "loop", "loop", "loop", "loop", "loop", "pst" },
    { "pre", "loop", "loop", "loop", "loop", "loop", "loop", "loop", "loop", "pst" },
    { "pre", "loop", "loop", "loop", "loop", "pst" }
}

pas.decodata_pond = {
    {
        { prefab = "rock_l_nitre", x = -2.926147, z = 2.930603 },
        { prefab = "fern_l", x = -3.444702, z = 2.31723 },
        { prefab = "pebble_l_nitre", x = -3.981567, z = -1.974334, animtype = 2 },
        { prefab = "fern_l", x = -2.87207, z = -3.407104 },	
        { prefab = "rock_l_nitre", x = -0.113464, z = 4.516235 },
        { prefab = "rock_l_nitre", x = -2.225036, z = -4.044219 },
        { prefab = "pebble_l_nitre", x = 4.631713, z = -0.296203, animtype = 2 },
        { prefab = "fern_l", x = 2.786743, z = 3.728637 },

        { prefab = "pebble_l_nitre", x = 3.267028, z = 3.36975, animtype = 1 },
        { prefab = "pebble_l_nitre", x = -2.803649, z = 3.788421, animtype = 2 },
        { prefab = "pebble_l_nitre", x = 3.040039, z = -3.625701, animtype = 1 },
        { prefab = "rock_l_nitre", x = 4.726257, z = 0.950408 },
        { prefab = "fern_l", x = 2.723632, z = -4.092956 },
        { prefab = "pebble_l_nitre", x = -5.023559, z = -1.269348, animtype = 1 },
        { prefab = "rock_l_nitre", x = -4.024719, z = -3.288208 },
        { prefab = "pebble_l_nitre", x = 2.490173, z = -4.575714, animtype = 3 },

        { prefab = "pebble_l_nitre", x = 0.452209, z = 5.225494, animtype = 3 },
        { prefab = "pebble_l_nitre", x = 1.238403, z = -5.534027, animtype = 1 }
    },
    {
        { prefab = "pebble_l_nitre", x = -0.590698, z = -4.376647, animtype = 3 },
        { prefab = "fern_l", x = -0.430969, z = 4.445861 },
        { prefab = "fern_l", x = 3.392944, z = -3.017303 },
        { prefab = "rock_l_nitre", x = -3.888916, z = -2.344146 },
        { prefab = "rock_l_nitre", x = -2.889526, z = 3.566925 },
        { prefab = "pebble_l_nitre", x = -4.32788, z = -1.574584, animtype = 1 },
        { prefab = "rock_l_nitre", x = -1.549194, z = -4.36203 },
        { prefab = "pebble_l_nitre", x = 3.488952, z = 3.165496, animtype = 2 },

        { prefab = "pebble_l_nitre", x = -4.591918, z = 1.10025, animtype = 3 },
        { prefab = "rock_l_nitre", x = 2.900207, z = -3.85794 },
        { prefab = "pebble_l_nitre", x = 4.032165, z = 2.689849, animtype = 1 },
        { prefab = "fern_l", x = 0.763244, z = 4.845703 },
        { prefab = "rock_l_nitre", x = -4.589965, z = 2.35086 },
        { prefab = "pebble_l_nitre", x = 5.192504, z = 0.125091, animtype = 1 },
        { prefab = "rock_l_nitre", x = -0.403015, z = -5.44992 },
        { prefab = "pebble_l_nitre", x = -2.41748, z = -5.023773, animtype = 2 },

        { prefab = "pebble_l_nitre", x = -4.384277, z = 3.743133, animtype = 1 }
    },
    {
        { prefab = "fern_l", x = -4.072082, z = 1.652435 },
        { prefab = "pebble_l_nitre", x = 1.727783, z = 4.102783, animtype = 3 },
        { prefab = "rock_l_nitre", x = -3.010986, z = 3.578948 },
        { prefab = "rock_l_nitre", x = -4.619323, z = -1.216461 },
        { prefab = "rock_l_nitre", x = 4.691406, z = 0.973541 },
        { prefab = "pebble_l_nitre", x = -1.624328, z = 4.589874, animtype = 3 },
        { prefab = "rock_l_nitre", x = 2.121093, z = -4.400665 },
        { prefab = "rock_l_nitre", x = 4.887939, z = -1.255676 },

        { prefab = "pebble_l_nitre", x = 2.093811, z = 4.671173, animtype = 2 },
        { prefab = "pebble_l_nitre", x = -0.14801, z = -5.250427, animtype = 3 },
        { prefab = "pebble_l_nitre", x = -4.187194, z = -3.17633, animtype = 3 },
        { prefab = "pebble_l_nitre", x = -2.322204, z = 4.945373, animtype = 3 },
        { prefab = "fern_l", x = 1.786499, z = -5.175354 },
        { prefab = "pebble_l_nitre", x = -5.46228, z = -0.603912, animtype = 2 },
        { prefab = "rock_l_nitre", x = 5.01654, z = 2.484161 },
        { prefab = "pebble_l_nitre", x = 5.594177, z = -0.57843, animtype = 3 },

        { prefab = "pebble_l_nitre", x = 5.122253, z = -2.688385, animtype = 1 },
        { prefab = "pebble_l_nitre", x = 0.717956, z = 5.910064, animtype = 1 }
    }
}
pas.idx_ponddeco = math.random(#pas.decodata_pond)

pas.decodata_pond_s = {
    {
        { prefab = "pebble_l_nitre", x = 1.624816, z = 2.394012, animtype = 2 },
        { prefab = "pebble_l_nitre", x = -1.832946, z = 2.275939, animtype = 3 },
        { prefab = "pebble_l_nitre", x = -3.010986, z = 0.293579, animtype = 2 },
        { prefab = "fern_l", x = 2.261169, z = 2.112823 },
        { prefab = "pebble_l_nitre", x = -0.504882, z = -3.069061, animtype = 3 },
        { prefab = "rock_l_nitre", x = 1.197692, z = -2.881774 },
        { prefab = "rock_l_nitre", x = -0.98822, z = 3.218231 },
        { prefab = "pebble_l_nitre", x = 2.391235, z = -2.801788, animtype = 2 },

        { prefab = "fern_l", x = -0.52185, z = 3.865509 },
        { prefab = "pebble_l_nitre", x = -0.51715, z = -3.978485, animtype = 1 }
    },
    {
        { prefab = "pebble_l_nitre", x = 2.215209, z = -1.618316, animtype = 1 },
        { prefab = "pebble_l_nitre", x = -1.001159, z = -2.558593, animtype = 2 },
        { prefab = "fern_l", x = -2.814025, z = 0.222229 },
        { prefab = "rock_l_nitre", x = 2.874145, z = 0.037322 },
        { prefab = "rock_l_nitre", x = 1.011474, z = 2.864685 },
        { prefab = "pebble_l_nitre", x = 2.598449, z = 1.980133, animtype = 3 },
        { prefab = "pebble_l_nitre", x = 2.118713, z = -2.573852, animtype = 3 },
        { prefab = "pebble_l_nitre", x = 3.296936, z = -0.879669, animtype = 2 },

        { prefab = "fern_l", x = -2.758972, z = 2.300598 },
        { prefab = "rock_l_nitre", x = 3.433532, z = 1.282104 },
        { prefab = "pebble_l_nitre", x = -3.53186, z = -0.98883, animtype = 1 },
        { prefab = "pebble_l_nitre", x = 2.032836, z = 3.497894, animtype = 2 }
    },
    {
        { prefab = "pebble_l_nitre", x = -1.712219, z = -2.247619, animtype = 3 },
        { prefab = "pebble_l_nitre", x = 2.810424, z = -0.461181, animtype = 1 },
        { prefab = "fern_l", x = -0.014892, z = 2.848968 },
        { prefab = "rock_l_nitre", x = -2.360839, z = 1.627685 },
        { prefab = "fern_l", x = 1.25177, z = -2.587738 },
        { prefab = "pebble_l_nitre", x = -2.057128, z = 2.540588, animtype = 2 },
        { prefab = "fern_l", x = 1.405212, z = 3.025848 },
        { prefab = "pebble_l_nitre", x = 3.329101, z = 0.706085, animtype = 2 },

        { prefab = "fern_l", x = -2.657653, z = -1.8638 },
        { prefab = "pebble_l_nitre", x = -1.1427, z = -3.36798, animtype = 2 },
        { prefab = "rock_l_nitre", x = -1.040283, z = 3.961486 }
    },
    {
        { prefab = "pebble_l_nitre", x = 1.365295, z = 2.428161, animtype = 1 },
        { prefab = "fern_l", x = -0.422363, z = 2.758331 },
        { prefab = "rock_l_nitre", x = -2.812133, z = -0.123474 },
        { prefab = "pebble_l_nitre", x = 0.612487, z = -2.91809, animtype = 2 },
        { prefab = "pebble_l_nitre", x = 0.90863, z = 2.911895, animtype = 2 },
        { prefab = "pebble_l_nitre", x = -2.640014, z = 1.69284, animtype = 2 },
        { prefab = "pebble_l_nitre", x = 0.044921, z = -3.341369, animtype = 3 },
        { prefab = "fern_l", x = -2.51593, z = -2.250396 },

        { prefab = "pebble_l_nitre", x = -3.327758, z = -1.045196, animtype = 3 },
        { prefab = "rock_l_nitre", x = -2.164611, z = -2.857818 },
        { prefab = "pebble_l_nitre", x = 2.702819, z = -2.431152, animtype = 1 },
        { prefab = "pebble_l_nitre", x = -0.063354, z = 3.645568, animtype = 1 },
        { prefab = "fern_l", x = 3.482666, z = 1.263122 }
    }
}
pas.idx_ponddeco_s = math.random(#pas.decodata_pond_s)

pas._PondRadComput = function(tb)
    local tbb = tb.pondbldg_soak
    tbb[3] = tbb[1] * tbb[1]
    tbb[4] = tbb[2] * tbb[2]
    tbb = tb.pondbldg_fish
    tbb[3] = tbb[1] * tbb[1]
    tbb[4] = tbb[2] * tbb[2]
end
pas._PondRadComput(pas.rad_pond)
pas._PondRadComput(pas.rad_pond_s)
pas._PondRadComput = nil

pas.Auto_pondfx = function(fx)
    local countdd = fx._fxddnum
    local animtype
    if fx.animtype > countdd then --说明上一次是隐藏，这一次必须展示出来
        animtype = math.random(countdd)
    elseif math.random() < 0.4 then --有几率发生变化
        animtype = math.random(1 + countdd)
    else
        animtype = fx.animtype
    end
    if animtype ~= fx.animtype then
        fx.animtype = animtype
        if animtype > countdd then --是隐藏
            fx:Hide()
            fx.task_hide = fx:DoTaskInTime(1.5+math.random()*2, function()
                fx.task_hide = nil
                pas.Auto_pondfx(fx)
            end)
            return
        else
            local dd = fx._fxdd[animtype]
            local newanim = dd.anims[math.random(#dd.anims)]
            if dd.bank ~= nil then
                --Tip：SetBank()时，如果当前播放动画名，在新的bank里不存在，日志会警告 Could not find anim [] in bank []
                --所以官方又加了 SetBankAndPlayAnimation 来同时修改bank和anim，就不会再出警告了
                if dd.bank ~= fx.bank_l then
                    fx.bank_l = dd.bank
                    fx.AnimState:SetBankAndPlayAnimation(dd.bank, newanim)
                    fx.AnimState:SetBuild(dd.build)
                else
                    fx.AnimState:PlayAnimation(newanim, false)
                end
            else
                fx.AnimState:PlayAnimation(newanim, false)
            end
            fx:Show()
            if fx.task_hide ~= nil then
                fx.task_hide:Cancel()
                fx.task_hide = nil
            end
        end
    else
        local dd = fx._fxdd[animtype]
        fx.AnimState:PlayAnimation(dd.anims[math.random(#dd.anims)], false)
    end
    if fx._creator == nil or not fx._creator:IsValid() then
        fx:Remove()
        return
    end
    local x, y, z = fx._creator.Transform:GetWorldPosition()
    x, y, z = TOOLS_L.GetCalculatedPos(x, y, z, fx._creator._dd_rad.fx*math.random(), nil)
    fx.Transform:SetPosition(x, y, z)
end
pas.Init_pondfx = function(inst, numsteam, numbubble, numsteam2)
    local fx
    if numsteam ~= nil then --官方蒸汽，很小，没有氛围感。但也需要，用来表现较浓厚的蒸汽
        for i = 1, numsteam, 1 do
            fx = SpawnPrefab("pond_steam_l_fx")
            inst.fx_steam[i] = fx
            fx._creator = inst
            fx._fxdd = pas.fxdd_pondsteam
            fx._fxddnum = #(pas.fxdd_pondsteam)
            fx.animtype = fx._fxddnum + 1
            fx:ListenForEvent("animover", pas.Auto_pondfx)
            pas.Auto_pondfx(fx)
        end
    end
    if numbubble ~= nil then --水面气泡
        for i = 1, numbubble, 1 do
            fx = SpawnPrefab("pond_bubble_l_fx")
            inst.fx_bubble[i] = fx
            fx._creator = inst
            fx._fxdd = pas.fxdd_pondbubble
            fx._fxddnum = #(pas.fxdd_pondbubble)
            fx.animtype = fx._fxddnum + 1
            fx:ListenForEvent("animover", pas.Auto_pondfx)
            pas.Auto_pondfx(fx)
        end
    end
    if numsteam2 ~= nil then --自己做的有氛围感的蒸汽。用来表现淡淡的蒸汽
        local function onanimoversteam(fxx)
            if fxx._creator == nil then
                fxx:Remove()
            else
                fxx.AnimState:PlayAnimation("steam"..tostring(math.random(6)), false)
            end
        end
        local x, y, z = inst.Transform:GetWorldPosition()
        local pos = {}
        pos[numsteam2] = { x, z }
        if numsteam2 >= 2 then
            numsteam2 = numsteam2 - 1
            local rad = inst._dd_rad.steam
            local thebase = 2*PI*math.random()
            local the = 2*PI / numsteam2
            local x1, z1
            for i = 1, numsteam2, 1 do
                x1, y, z1 = TOOLS_L.GetCalculatedPos(x, y, z, rad, thebase + the*i)
                pos[i] = { x1, z1 }
            end
            numsteam2 = numsteam2 + 1
        end
        local rand1, rand2, vv
        for i, v in ipairs(pos) do
            fx = SpawnPrefab("pond_steam2_l_fx")
            inst.fx_steam2[i] = fx
            fx._creator = inst
            fx:ListenForEvent("animover", onanimoversteam)
            onanimoversteam(fx)
            rand1 = fx.AnimState:GetCurrentAnimationNumFrames()
            rand2 = math.random(rand1) --1-n
            fx.AnimState:SetFrame(rand2 - 1)
            fx.Transform:SetPosition(v[1], y, v[2])

            fx = SpawnPrefab("pond_steam2_l_fx")
            inst.fx_steam2[i+numsteam2] = fx
            fx._creator = inst
            fx:ListenForEvent("animover", onanimoversteam)
            onanimoversteam(fx)
            vv = math.floor(rand1/3)
            rand2 = rand2 + vv
            if rand2 > rand1 then
                rand2 = rand2 - rand1
            end
            fx.AnimState:SetFrame(rand2 - 1)
            fx.Transform:SetPosition(v[1], y, v[2])

            fx = SpawnPrefab("pond_steam2_l_fx")
            inst.fx_steam2[i+numsteam2+numsteam2] = fx
            fx._creator = inst
            fx:ListenForEvent("animover", onanimoversteam)
            onanimoversteam(fx)
            rand2 = rand2 + vv
            if rand2 > rand1 then
                rand2 = rand2 - rand1
            end
            fx.AnimState:SetFrame(rand2 - 1)
            fx.Transform:SetPosition(v[1], y, v[2])
        end
    end
end
pas.Init_pondfx_cold = function(inst, numsteam, numbubble, numsteam2)
    local fx
    if numsteam ~= nil then --用来表现较浓厚的冷气
        for i = 1, numsteam, 1 do
            fx = SpawnPrefab("pond_coldsteam_l_fx")
            inst.fx_steam[i] = fx
            fx._creator = inst
            fx._fxdd = pas.fxdd_pondsteam_cold
            fx._fxddnum = #(pas.fxdd_pondsteam_cold)
            fx.animtype = fx._fxddnum + 1
            fx:ListenForEvent("animover", pas.Auto_pondfx)
            pas.Auto_pondfx(fx)
        end
    end
    if numbubble ~= nil then --水面气泡
        for i = 1, numbubble, 1 do
            fx = SpawnPrefab("pond_bubble_l_fx")
            inst.fx_bubble[i] = fx
            fx._creator = inst
            fx._fxdd = pas.fxdd_pondbubble
            fx._fxddnum = #(pas.fxdd_pondbubble)
            fx.animtype = fx._fxddnum + 1
            fx:ListenForEvent("animover", pas.Auto_pondfx)
            pas.Auto_pondfx(fx)
        end
    end
    if numsteam2 ~= nil then --用来表现淡淡的冷气
        local x, y, z = inst.Transform:GetWorldPosition()
        local pos = {}
        pos[numsteam2] = { x, z }
        if numsteam2 >= 2 then
            numsteam2 = numsteam2 - 1
            local rad = inst._dd_rad.steam
            local thebase = 2*PI*math.random()
            local the = 2*PI / numsteam2
            local x1, z1
            for i = 1, numsteam2, 1 do
                x1, y, z1 = TOOLS_L.GetCalculatedPos(x, y, z, rad, thebase + the*i)
                pos[i] = { x1, z1 }
            end
            numsteam2 = numsteam2 + 1
        end
        for i, v in ipairs(pos) do
            fx = SpawnPrefab("pond_coldsteam2_l_fx")
            inst.fx_steam2[i] = fx
            fx._creator = inst
            TOOLS_F.StartRandomAnims(fx, true, pas.fxdd_pondsteam2_cold)
            TOOLS_L.RandomAnimFrame(fx)
            fx.Transform:SetPosition(v[1], y, v[2])

            fx = SpawnPrefab("pond_coldsteam2_l_fx")
            inst.fx_steam2[i+numsteam2] = fx
            fx._creator = inst
            TOOLS_F.StartRandomAnims(fx, true, pas.fxdd_pondsteam2_cold)
            TOOLS_L.RandomAnimFrame(fx)
            fx.Transform:SetPosition(v[1], y, v[2])

            fx = SpawnPrefab("pond_coldsteam2_l_fx")
            inst.fx_steam2[i+numsteam2+numsteam2] = fx
            fx._creator = inst
            TOOLS_F.StartRandomAnims(fx, true, pas.fxdd_pondsteam2_cold)
            TOOLS_L.RandomAnimFrame(fx)
            fx.Transform:SetPosition(v[1], y, v[2])
        end
    end
end
pas.Remove_pondfx = function(inst)
    for _, v in pairs(inst.fx_steam) do
        if v:IsValid() then
            v._creator = nil --只需要移除这个就好，然后特效会自己到时间删除的
        end
    end
    inst.fx_steam = {}
    for _, v in pairs(inst.fx_bubble) do
        if v:IsValid() then
            v._creator = nil --只需要移除这个就好，然后特效会自己到时间删除的
        end
    end
    inst.fx_bubble = {}
    if inst.legiontag_pondtemp == 1 then
        for _, v in pairs(inst.fx_steam2) do
            if v:IsValid() then
                v._creator = nil --只需要移除这个就好，然后特效会自己到时间删除的
            end
        end
    else
        local function fxoff(fx)
            if fx.AnimState:AnimDone() then
                fx:Remove()
            end
        end
        for _, v in pairs(inst.fx_steam2) do
            if v:IsValid() then
                v._creator = nil
                if v._ls_randanims == nil then
                    v:Remove()
                else
                    TOOLS_F.StopRandomAnims(v)
                    v.AnimState:PushAnimation("pst", false)
                    v:ListenForEvent("animover", fxoff)
                end
            end
        end
    end
    inst.fx_steam2 = {}
end
pas.OnRemove_pond = function(inst)
    for _, v in pairs(inst.fx_steam) do
        if v:IsValid() then
            v:Remove()
        end
    end
    inst.fx_steam = {}
    for _, v in pairs(inst.fx_bubble) do
        if v:IsValid() then
            v:Remove()
        end
    end
    inst.fx_bubble = {}
    for _, v in pairs(inst.fx_steam2) do
        if v:IsValid() then
            v:Remove()
        end
    end
    inst.fx_steam2 = {}
    for _, v in pairs(inst._mydecos) do
        if v.ent ~= nil and v.ent:IsValid() then
            v.ent:Remove()
        end
    end
    inst._mydecos = {}
    inst.components.soakablelegion:BeRemoved()
end

fns.MakePond = function(sets)
    table.insert(prefs, Prefab(sets.name, function()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        sets.fn_common(inst)

        inst.MiniMapEntity:SetIcon(sets.name..".tex")
        inst.MiniMapEntity:SetPriority(3)
        MakePondPhysics(inst, sets.radius.base)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetLayer(LAYER_BACKGROUND)
        inst.AnimState:SetSortOrder(1) --鱼2、水面特效3、人物和物品波纹特效4
        -- inst.AnimState:SetScale(1.3, 1.3)

        inst:AddTag("watersource")
        -- inst:AddTag("pond") -- 官方标签，暂时还没发现有什么用处
        inst:AddTag("antlion_sinkhole_blocker")
        inst:AddTag("birdblocker")
        inst:AddTag("nosoak_l") --暂时不能浸泡，等初始化完成才行
        inst.no_wet_prefix = true
        inst._dd_rad = sets.radius
        inst:SetDeploySmartRadius(sets.radius.deploy)

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        inst.fx_steam = {}
        inst.fx_bubble = {}
        inst.fx_steam2 = {}

        inst:AddComponent("inspectable")

        inst:AddComponent("savedrotation")

        inst:AddComponent("watersource")

        inst:ListenForEvent("onremove", pas.OnRemove_pond)

        sets.fn_server(inst)

        return inst
    end, sets.assets, sets.prefabs))
end

pas.OnSave_pond = function(inst, data)
    local mydecos = {}
    for k, v in pairs(inst._mydecos) do
        local dd = { x = v.x, z = v.z, cycle = v.cycle, prefab = v.prefab }
        if v.ent ~= nil and v.ent:IsValid() then
            dd.saved = v.ent:GetSaveRecord()
            dd.cycle = 0
        end
        mydecos[k] = dd
    end
    data.mydecos = mydecos
    if not inst._needinitself then
        data.inited_l = true
    end
end
pas.OnLoad_pond = function(inst, data)
    if data ~= nil then
        if data.mydecos ~= nil then
            local ent
            local x, y, z = inst.Transform:GetWorldPosition()
            for k, v in pairs(data.mydecos) do
                if v.saved ~= nil then
                    ent = SpawnPrefab(v.saved.prefab, v.saved.skinname, v.saved.skin_id)
                    if ent ~= nil then
                        ent.Transform:SetPosition(x + v.x, y, z + v.z) --应用位置偏移量
                        ent:SetPersistData(v.saved.data)
                        ent.persists = false --现在保存与加载由泉池接管
                        ent.pondowner_l = inst
                    end
                end
                inst._mydecos[k] = { x = v.x, z = v.z, prefab = v.prefab, cycle = v.cycle, ent = ent }
            end
        end
        if data.inited_l then --Tip：新世界刚产生时也会对已有实体执行onload操作！
            inst._needinitself = nil
        end
    end
end
pas.SetTempFx_pond = function(pondcpt)
    local inst = pondcpt.inst
    if pondcpt.tick_temperature[1] > 0 then
        if inst.legiontag_pondtemp ~= 1 then
            pas.Remove_pondfx(inst)
            inst.legiontag_pondtemp = 1
            pas.Init_pondfx(inst, 3, 2, 7)
        end
    elseif pondcpt.tick_temperature[1] < 0 then
        if inst.legiontag_pondtemp ~= 2 then
            pas.Remove_pondfx(inst)
            inst.legiontag_pondtemp = 2
            pas.Init_pondfx_cold(inst, 4, 2, 7)
        end
    elseif inst.legiontag_pondtemp ~= nil then
        pas.Remove_pondfx(inst)
        inst.legiontag_pondtemp = nil
    end
end
pas.SetTempFx_pond_s = function(pondcpt)
    local inst = pondcpt.inst
    if pondcpt.tick_temperature[1] > 0 then
        if inst.legiontag_pondtemp ~= 1 then
            pas.Remove_pondfx(inst)
            inst.legiontag_pondtemp = 1
            pas.Init_pondfx(inst, 1, 1, 4)
        end
    elseif pondcpt.tick_temperature[1] < 0 then
        if inst.legiontag_pondtemp ~= 2 then
            pas.Remove_pondfx(inst)
            inst.legiontag_pondtemp = 2
            pas.Init_pondfx_cold(inst, 2, 1, 4)
        end
    elseif inst.legiontag_pondtemp ~= nil then
        pas.Remove_pondfx(inst)
        inst.legiontag_pondtemp = nil
    end
end
pas.InitDecos_pond = function(inst, data)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ent
    inst._mydecos = {}
    for _, dd in pairs(data) do
        ent = SpawnPrefab(dd.prefab)
        if ent ~= nil then
            if dd.prefab == "pebble_l_nitre" then
                if dd.animtype ~= nil and dd.animtype > 1 and ent.components.randomanimlegion ~= nil then
                    ent.components.randomanimlegion.type1 = dd.animtype
                    ent.components.randomanimlegion:SetAnim(nil, pas.anims_pebble_nitre[dd.animtype])
                end
            else
                ent.persists = false --现在保存与加载由泉池接管
                ent.pondowner_l = inst
                table.insert(inst._mydecos, { x = dd.x, z = dd.z, prefab = dd.prefab, cycle = 0, ent = ent })
            end
            ent.Transform:SetPosition(x + dd.x, y, z + dd.z)
        end
    end
end
pas.TryRespawnDecos_pond = function(inst)
    local x, y, z
    for _, v in pairs(inst._mydecos) do
        if v.ent == nil or not v.ent:IsValid() then
            v.ent = nil
            if v.cycle >= 2 then
                v.cycle = v.cycle - 1
            elseif v.cycle <= 0 then
                v.cycle = 5
            elseif v.cycle <= 1 then
                v.cycle = 0
                local newent = SpawnPrefab(v.prefab)
                if newent ~= nil then
                    newent.persists = false --现在保存与加载由泉池接管
                    newent.pondowner_l = inst
                    if x == nil then
                        x, y, z = inst.Transform:GetWorldPosition()
                    end
                    newent.Transform:SetPosition(x + v.x, y, z + v.z)
                    v.ent = newent
                end
            end
        end
    end
end
pas.IsDusk_pond = function(inst)
    if TheWorld.state.isdusk then
        pas.TryRespawnDecos_pond(inst)
    end
end
pas.IsCaveDusk_pond = function(inst)
    if TheWorld.state.iscavedusk then
        pas.TryRespawnDecos_pond(inst)
    end
end

--anim/crater_pool 温泉动画有特效可以弄
fns.MakePond({ name = "pond_l_smoke", --气熏温泉(大)
    assets = { Asset("ANIM", "anim/pond_l_smoke.zip") },
    prefabs = { "pond_steam_l_fx", "pond_bubble_l_fx", "pond_steam2_l_fx", "pond_coldsteam_l_fx", "pond_coldsteam2_l_fx",
        "rock_l_nitre", "fern_l"
    },
    radius = pas.rad_pond,
    fn_common = function(inst)
        inst.AnimState:SetBank("moonglasspool_tile")
        inst.AnimState:SetBuild("moonglasspool_tile")
        inst.AnimState:PlayAnimation("idle", true)
        inst.AnimState:OverrideSymbol("innerblob", "pond_l_smoke", "innerblob")
        inst.AnimState:OverrideSymbol("rocklines", "pond_l_smoke", "rocklines")
        inst.legiontag_bigpond = true
        -- LS_C_Init(inst, "pond_l_smoke", false)
    end,
    fn_server = function(inst)
        local soakablelegion = inst:AddComponent("soakablelegion")
        soakablelegion.points = 8
        soakablelegion.radius = { 0.8, 1.6 }
        soakablelegion.radiuscenter = 0.5
        soakablelegion.fn_value = ZIP_SOAK_L.fn_value_hot
        soakablelegion.fn_mixtickspst = pas.SetTempFx_pond

        inst._mydecos = {}
        inst._needinitself = true
        inst.OnSave = pas.OnSave_pond
        inst.OnLoad = pas.OnLoad_pond
        inst.task_init = inst:DoTaskInTime(5.5+math.random()*1.5, function()
            inst.task_init = nil
            inst.components.soakablelegion:UpdateTick(true)
            inst.components.soakablelegion:UpdateFishTick(true)
            inst.components.soakablelegion:MixAllTicks()
            inst.components.soakablelegion:UpdateBldgTags()
            inst:RemoveTag("nosoak_l")
            if inst._needinitself then
                inst._needinitself = nil
                inst.Transform:SetRotation(math.random(-180, 180))
                pas.InitDecos_pond(inst, pas.decodata_pond[pas.idx_ponddeco] or pas.decodata_pond[1])
                if pas.idx_ponddeco >= #pas.decodata_pond then
                    pas.idx_ponddeco = 1
                else
                    pas.idx_ponddeco = pas.idx_ponddeco + 1
                end
            end
            if TheWorld:HasTag("cave") then --Tip：在地面世界，黄昏时 iscavedusk 也会触发
                inst:WatchWorldState("iscavedusk", pas.IsCaveDusk_pond)
            else
                inst:WatchWorldState("isdusk", pas.IsDusk_pond)
            end
        end)
    end
})
fns.MakePond({ name = "pond_l_smoke_s", --气熏温泉(小)
    assets = { Asset("ANIM", "anim/pond_l_smoke.zip") },
    prefabs = { "pond_steam_l_fx", "pond_bubble_l_fx", "pond_steam2_l_fx", "pond_coldsteam_l_fx", "pond_coldsteam2_l_fx",
        "rock_l_nitre", "fern_l"
    },
    radius = pas.rad_pond_s,
    fn_common = function(inst)
        inst.AnimState:SetBank("moonglasspool_tile")
        inst.AnimState:SetBuild("moonglasspool_tile")
        inst.AnimState:PlayAnimation("smallpool_idle", true)
        inst.AnimState:OverrideSymbol("innerblob", "pond_l_smoke", "innerblob")
        inst.AnimState:OverrideSymbol("rockline_small", "pond_l_smoke", "rockline_small")
        inst.AnimState:SetScale(1.3, 1.3, 1.3)
        inst:SetPrefabNameOverride("pond_l_smoke")
        -- LS_C_Init(inst, "pond_l_smoke_s", false)
    end,
    fn_server = function(inst)
        local soakablelegion = inst:AddComponent("soakablelegion")
        soakablelegion.points = 2
        soakablelegion.radius = { 0.3, 1.2 }
        soakablelegion.fn_value = ZIP_SOAK_L.fn_value_hot
        soakablelegion.fn_mixtickspst = pas.SetTempFx_pond_s

        inst._mydecos = {}
        inst._needinitself = true
        inst.OnSave = pas.OnSave_pond
        inst.OnLoad = pas.OnLoad_pond
        inst.task_init = inst:DoTaskInTime(0.5+math.random()*1.5, function()
            inst.task_init = nil
            inst.components.soakablelegion:UpdateTick(true)
            inst.components.soakablelegion:UpdateFishTick(true)
            inst.components.soakablelegion:MixAllTicks()
            inst.components.soakablelegion:UpdateBldgTags()
            inst:RemoveTag("nosoak_l")
            if inst._needinitself then
                inst._needinitself = nil
                inst.Transform:SetRotation(math.random(-180, 180))
                pas.InitDecos_pond(inst, pas.decodata_pond_s[pas.idx_ponddeco_s] or pas.decodata_pond_s[1])
                if pas.idx_ponddeco_s >= #pas.decodata_pond_s then
                    pas.idx_ponddeco_s = 1
                else
                    pas.idx_ponddeco_s = pas.idx_ponddeco_s + 1
                end
            end
            if TheWorld:HasTag("cave") then
                inst:WatchWorldState("iscavedusk", pas.IsCaveDusk_pond)
            else
                inst:WatchWorldState("isdusk", pas.IsDusk_pond)
            end
        end)
    end
})

pas.OnSave_pond_made = function(inst, data)
    data.holder = true --只有存在data数据时，才能使得加载时 OnLoad() 能被执行
end
pas.OnLoad_pond_made = function(inst, data)
    -- if data ~= nil then
    -- end
    inst._needinitself = nil
end

--------------------------------------------------------------------------
--[[ 泉池的特效 ]]
--------------------------------------------------------------------------

table.insert(prefs, Prefab("pond_steam_l_fx", function() --蒸汽特效
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetFinalOffset(3)
    inst.AnimState:SetLightOverride(0.05)
    inst.AnimState:SetScale(1.3, 1.3)
    inst.AnimState:SetDeltaTimeMultiplier(0.8)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    return inst
end, {
    Asset("ANIM", "anim/crater_steam.zip"), --官方蒸汽特效1
    Asset("ANIM", "anim/slow_steam.zip") --官方蒸汽特效2
}, nil))

table.insert(prefs, Prefab("pond_coldsteam_l_fx", function() --冷气特效
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("deer_ice_flakes")
    inst.AnimState:SetBuild("pond_coldsteam2_l_fx")
    inst.AnimState:SetFinalOffset(3)
    inst.AnimState:SetLightOverride(0.05)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetScale(0.5, 0.5)
    inst.AnimState:SetMultColour(1, 1, 1, 0.7)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    return inst
end, {
    Asset("ANIM", "anim/deer_ice_flakes.zip"), --官方旧版本帝王蟹的冷气特效
    Asset("ANIM", "anim/pond_coldsteam2_l_fx.zip")
}, nil))

table.insert(prefs, Prefab("pond_bubble_l_fx", function() --气泡特效
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("bubble_fx")
    inst.AnimState:SetBuild("crab_king_bubble_fx")
    inst.AnimState:SetFinalOffset(2)
    inst.AnimState:SetScale(0.6, 0.6)
    inst.AnimState:SetDeltaTimeMultiplier(0.8)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    return inst
end, { Asset("ANIM", "anim/crab_king_bubble_fx.zip") }, nil))

table.insert(prefs, Prefab("pond_steam2_l_fx", function() --蒸汽特效2
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("pond_steam2_l_fx")
    inst.AnimState:SetBuild("pond_steam2_l_fx")
    inst.AnimState:SetFinalOffset(3)
    inst.AnimState:SetLightOverride(0.1)
    inst.AnimState:SetMultColour(1, 1, 1, 0.6)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    return inst
end, { Asset("ANIM", "anim/pond_steam2_l_fx.zip") }, nil))

table.insert(prefs, Prefab("pond_coldsteam2_l_fx", function() --冷气特效2
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("deer_ice_flakes")
    inst.AnimState:SetBuild("pond_coldsteam2_l_fx")
    inst.AnimState:OverrideSymbol("inlight", "pond_coldsteam2_l_fx", "noflake")
    inst.AnimState:SetFinalOffset(3)
    inst.AnimState:SetLightOverride(0.1)
    inst.AnimState:SetMultColour(1, 1, 1, 0.1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetScale(1.0, 0.8)
    -- inst.AnimState:SetDeltaTimeMultiplier(0.8) --动画帧数不够，会显得有些卡顿，不加了

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    return inst
end, {
    Asset("ANIM", "anim/deer_ice_flakes.zip"), --官方旧版本帝王蟹的冷气特效
    Asset("ANIM", "anim/pond_coldsteam2_l_fx.zip")
}, nil))

pas.Dirty_ponddeco = function(inst)
    local key = inst._floatfx_l:value()
    if key == nil or key == "" or ZIP_SOAK_L.decos[key] == nil then
        return
    end
    local data = ZIP_SOAK_L.decos[key]
    if data.float ~= nil then
        fns.SetFloatFx(inst, data.float)
    end
end
table.insert(prefs, Prefab("pond_deco_l_fx", function() --装饰物动画实体
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    -- inst.AnimState:SetFinalOffset(2) --不能设置这个，会导致漂浮特效都被自身动画挡住了
    inst.Transform:SetTwoFaced() --两个面，这样就可以左右不同

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    fns.InitSimpleFloat(inst, "pond_deco_l_fx", pas.Dirty_ponddeco, nil)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    return inst
end, nil, nil))

--------------------------------------------------------------------------
--[[ 碎石块 ]]
--------------------------------------------------------------------------

pas.anims_pebble_nitre = { 5, 5, 3, 3 }
pas.OnFinished_pebble_nitre = function(inst, worker)
    TOOLS_L.SpawnStackDrop("pebbleitem_l_nitre", 1, inst:GetPosition(), nil, nil, { noevent = true, stackevent = true })
    inst:Remove()
end
pas.Redetailed_pebble_nitre = function(inst, brush, mode, doer)
    local cpt = inst.components.randomanimlegion
    if mode == 1 then --完全随机
        cpt.type1 = TOOLS_L.GetExceptRandomNumber(1, #pas.anims_pebble_nitre, cpt.type1)
        cpt:SetAnim(nil, pas.anims_pebble_nitre[cpt.type1])
    elseif mode == 2 then --阶段顺序
        cpt.type1 = TOOLS_L.GetNextCycleNumber(1, #pas.anims_pebble_nitre, cpt.type1)
        cpt:SetAnim(nil, pas.anims_pebble_nitre[cpt.type1])
    else --当前顺序
        cpt.type2 = TOOLS_L.GetNextCycleNumber(1, pas.anims_pebble_nitre[cpt.type1], cpt.type2)
        cpt:SetAnim(nil, nil)
    end
    return false, { scale = 0.9 }
end
table.insert(prefs, Prefab("pebble_l_nitre", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.AnimState:SetBank("pebble_l_nitre")
    inst.AnimState:SetBuild("pebble_l_nitre")
    fns.SetRotatable_com(inst)
    inst:AddTag("NOBLOCK")
    inst:SetPrefabNameOverride("pebbleitem_l_nitre")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")
    inst:AddComponent("savedrotation")

    local randomanimlegion = inst:AddComponent("randomanimlegion")
    randomanimlegion.type1 = 1
    randomanimlegion:SetAnim(nil, pas.anims_pebble_nitre[1])
    randomanimlegion:SetMultColour(0.8)

    fns.SetWorkable(inst, nil, pas.OnFinished_pebble_nitre, nil, 1)
    TOOLS_L.MakeSnowCovered_serv(inst)
    inst.legionfn_redetailed = pas.Redetailed_pebble_nitre

    return inst
end, { Asset("ANIM", "anim/pebble_l_nitre.zip") }, nil))

--------------------------------------------------------------------------
--[[ 硝石堆 ]]
--------------------------------------------------------------------------

SetSharedLootTable('rock_l_nitre', { --4~5个硝石
    {'nitre', 1.00}, {'nitre', 1.00}, {'nitre', 1.00}, {'nitre', 1.00}, {'nitre', 0.5}
})

pas.OnWorked_rock_nitre = function(inst, worker, workleft, numworks)
    if workleft <= 0 then
        local pt = inst:GetPosition()
        SpawnPrefab("rock_break_fx").Transform:SetPosition(pt.x, pt.y, pt.z)
        inst.components.lootdropper:DropLoot(pt)
        inst:Remove()
    else
        if workleft <= 2 then
            --由于workable组件不会保存数据，所以会出现没开凿完的，游戏重载后动画不在第四阶段，但依然能开凿6次的小问题
            local randomanimlegion = inst.components.randomanimlegion
            if randomanimlegion.type1 > 3 then
                randomanimlegion.type1 = 3
                randomanimlegion:SetAnim(nil, pas.anims_pebble_nitre[3])
            end
        end
    end
end
table.insert(prefs, Prefab("rock_l_nitre", function()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
    MakeObstaclePhysics(inst, 0.3)
    inst.MiniMapEntity:SetIcon("rock_l_nitre.tex")
    inst.AnimState:SetBank("pebble_l_nitre")
    inst.AnimState:SetBuild("pebble_l_nitre")
    fns.SetRotatable_com(inst)
    inst:AddTag("boulder")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then return inst end

    inst:AddComponent("inspectable")
    inst:AddComponent("savedrotation")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('rock_l_nitre')

    local randomanimlegion = inst:AddComponent("randomanimlegion")
    randomanimlegion.type1 = 4
    randomanimlegion:SetAnim(nil, pas.anims_pebble_nitre[4])
    randomanimlegion:SetMultColour(0.8)

    fns.SetWorkable(inst, pas.OnWorked_rock_nitre, nil, "MINE", 4)
    TOOLS_L.MakeSnowCovered_serv(inst)
    MakeHauntableWork(inst)

    return inst
end, { Asset("ANIM", "anim/pebble_l_nitre.zip") }, nil))

--------------------------------------------------------------------------
--[[ 澡花壳 ]]
--------------------------------------------------------------------------

pas.OnClose_bldg = function(inst)
    inst.AnimState:PlayAnimation("close")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound("hookline_2/characters/hermit/tacklebox/small_close")
    if inst.pondcpt_l ~= nil and inst.pondcpt_l.inst:IsValid() then
        inst.pondcpt_l:OnCloseBldg(inst)
    end
end
pas.OnBuilt_bldg = function(inst, data) --建造出来时，寻找泉池并绑定
    pas.OnClose_bldg(inst)
    local key = inst.prefab
    local pt = data and data.pos or inst:GetPosition()
    local x2, y2, z2, rad, dist
    local ents = TheSim:FindEntities(pt.x, 0, pt.z, 7.5, { key }, { "INLIMBO", "NOCLICK" })
    for _, ent in ipairs(ents) do
        if ent.entity:IsVisible() and ent._dd_rad ~= nil and ent.components.soakablelegion ~= nil then
            rad = ent._dd_rad[key]
            if rad ~= nil then
                x2, y2, z2 = ent.Transform:GetWorldPosition()
                dist = distsq(pt.x, pt.z, x2, z2)
                if dist >= rad[3] and dist <= rad[4] then --最终位置得在池塘周围
                    dist = ent.components.soakablelegion:BindBldg(inst, pt.x, pt.z)
                    ent.components.soakablelegion:UpdateBldgTags()
                    if dist then
                        return
                    end
                end
            end
        end
    end
end
pas.OnDeconstruct_bldg = function(inst, doer) --被分解时
    if inst.pondcpt_l ~= nil and inst.pondcpt_l.inst:IsValid() then
        inst.pondcpt_l:UnboundBldg(inst)
    end
end
pas.OnWorked_bldg = function(inst, worker, workleft, numworks) --敲击时
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
    inst.components.container:Close()
    if inst.pondcpt_l ~= nil and inst.pondcpt_l.inst:IsValid() and inst.pondcpt_l.task_soak ~= nil then
        inst.components.workable:SetWorkLeft(3) --泉池有人在浸泡时，是不可破坏的
    end
end
pas.OnFinished_bldg = function(inst, worker) --破坏时
    inst.components.lootdropper:DropLoot()
    inst.components.container:DropEverything()
    if inst.pondcpt_l ~= nil and inst.pondcpt_l.inst:IsValid() then
        inst.pondcpt_l:UnboundBldg(inst)
    end
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end
pas.OnOpen_bldg = function(inst, data)
    inst.AnimState:PlayAnimation("open")
    inst.AnimState:PushAnimation("opened", false)
    inst.SoundEmitter:PlaySound("hookline_2/characters/hermit/tacklebox/small_open")
end

pas.OnReplicated_bldg_soak = function(inst)
    if inst.replica.container ~= nil then
        inst.replica.container:WidgetSetup("pondbldg_soak")
    end
end
pas.DealData_bldg_soak = function(inst, data)
    local dd = {}
    local res
    local v = data.tk
    if v ~= nil then
        dd.hea = tostring(v.hea or 0)
        dd.san = tostring(v.san or 0)
        dd.moi = tostring(v.moi or 0)
        dd.mul = tostring(v.mul or 0)
        dd.tp1 = tostring(v.tp1 or 0)
        dd.tp2 = v.tp2 and tostring(v.tp2) or "-"
        dd.tp3 = v.tp3 and tostring(v.tp3) or "-"
        res = subfmt(STRINGS.NAMEDETAIL_L.BLDG_SOAK, dd)
    end
    if data.bf ~= nil then
        local re
        local num = 0
        local newbuffs = {}
        for _, buffdd in pairs(data.bf) do
            v = buffdd.id ~= nil and tonumber(buffdd.id) or nil
            if v ~= nil then
                dd = ZIP_SOAK_L.buffinfos[v]
                if dd ~= nil then
                    re = string.upper(dd.name)
                    re = "["..(buffdd.ca and "★" or "")..(STRINGS.NAMES[re] or re)..": "
                        ..tostring(buffdd.ti or dd.time)..STRINGS.NAMEDETAIL_L.SECOND
                    if dd.showcycle then
                        re = re..", "..tostring(buffdd.cy or dd.cycle)..STRINGS.NAMEDETAIL_L.BUFFCYCLE.."]"
                    else
                        re = re.."]"
                    end
                    newbuffs[v] = re
                end
            end
        end
        for idx, info in ipairs(ZIP_SOAK_L.buffinfos) do --这个表代表着顺序
            if newbuffs[idx] ~= nil then
                num = num + 1
                if res == nil then
                    res = newbuffs[idx]
                elseif num <= 3 then --第一行摆三个
                    res = res..(num%3 == 1 and "\n" or "  ")..newbuffs[idx]
                else --后续都是摆四个
                    res = res..((num-3)%4 == 1 and "\n" or "  ")..newbuffs[idx]
                end
            end
        end
    end
    return res
end
pas.GetData_bldg_soak = function(inst)
    local cpt = inst.pondcpt_l
    if cpt == nil or not cpt.inst:IsValid() then
        return
    end
    local data = { tk = {} } --Tip：要序列化的数据不能是{ [1]=xx, [3]=2 }这种形式的，只能是{ jj=1 }这种
    local dd, val
    ----buffs
    for buffkey, buffdd in pairs(cpt.tick_buffs) do
        if buffdd.idx ~= nil then
            dd = ZIP_SOAK_L.buffinfos[buffdd.idx]
            val = { id = buffdd.idx } --只传下标，不传buffkey，因为buffkey太长了
            ----每秒可加时间
            if buffdd.time ~= dd.time then
                if buffdd.time == nil then --被抑制了
                    val.ti = 0
                else
                    val.ti = TOOLS_L.ODPoint(buffdd.time, 100)
                end
            end
            ----能否主动提供buff
            if buffdd.can then
                val.ca = true
            end
            ----循环时间
            if dd.showcycle and buffdd.cycle ~= dd.cycle then
                val.cy = math.floor(buffdd.cycle)
            end
            if data.bf == nil then
                data.bf = {}
            end
            data.bf["a"..tostring(buffdd.idx)] = val --Tip：就算下标是排序的，等反序列化后还是会乱掉
        end
    end
    dd = data.tk
    val = cpt.datainfos
    ----生命
    if val.tick_health ~= nil then
        dd.hea = TOOLS_L.ODPoint(val.tick_health, 100)
    end
    ----精神
    if val.tick_sanity ~= nil then
        dd.san = TOOLS_L.ODPoint(val.tick_sanity, 100)
    end
    ----潮湿度
    if val.tick_moisture ~= nil then
        dd.moi = TOOLS_L.ODPoint(val.tick_moisture, 100)
    end
    ----催长剂
    if val.tick_formula ~= nil then
        dd.mul = TOOLS_L.ODPoint(val.tick_formula, 100)
    end
    ----温度
    if val.tick_temperature ~= nil then
        dd.tp1 = TOOLS_L.ODPoint(val.tick_temperature[1] or 0, 100)
        dd.tp2 = TOOLS_L.ODPoint(val.tick_temperature[2] or 0, 100)
        dd.tp3 = TOOLS_L.ODPoint(val.tick_temperature[3] or 0, 100)
    end
    return data
end

table.insert(prefs, Prefab("pondbldg_soak", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "pondbldg_soak", nil, "closed", nil)
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("pondbldg_soak.tex")
    inst.MiniMapEntity:SetPriority(4) --优先级得在泉池之上
    inst:SetDeploySmartRadius(0.1)
    fns.SetRotatable_com(inst)
    inst:AddTag("structure")
    TOOLS_L.InitMouseInfo(inst, pas.DealData_bldg_soak, pas.GetData_bldg_soak, 3)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = pas.OnReplicated_bldg_soak
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst:AddComponent("savedrotation")
    fns.SetContainer(inst, "pondbldg_soak", pas.OnOpen_bldg, pas.OnClose_bldg)

    inst:AddComponent("preserver")
	inst.components.preserver:SetPerishRateMultiplier(0.0) --永久保鲜！但这并不是一个储物类容器

    fns.SetWorkable(inst, pas.OnWorked_bldg, pas.OnFinished_bldg, "HAMMER", 3)
    TOOLS_L.MakeSnowCovered_serv(inst)
    MakeHauntable(inst)

    inst:ListenForEvent("onbuilt", pas.OnBuilt_bldg)
    inst:ListenForEvent("ondeconstructstructure", pas.OnDeconstruct_bldg)

    return inst
end, {
    Asset("ANIM", "anim/ui_chest_3x3.zip"), --官方的容器栏背景动画模板
    Asset("ANIM", "anim/ui_l_pond_3x2.zip"),
    Asset("ANIM", "anim/pondbldg_soak.zip")
}, nil))

--------------------------------------------------------------------------
--[[ 鱼栖壳 ]]
--------------------------------------------------------------------------

pas.OnReplicated_bldg_fish = function(inst)
    if inst.replica.container ~= nil then
        inst.replica.container:WidgetSetup("pondbldg_fish")
    end
end
pas.SetPerishRate_bldg_fish = function(inst, item)
    if item == nil then
        return 1.0
    end
    if item:HasAnyTag("pondfish", "smalloceancreature") then --水生生物可以返鲜
        return -0.333
    end
    return 0 --以后能放别的物品，还是保鲜好了
end
pas.OnItemGet_bldg_fish = function(inst, data)
    if inst.pondcpt_l ~= nil and not inst.pondcpt_l.checkfishtick then
        if data ~= nil and data.item ~= nil and ZIP_SOAK_L.fish[data.item.prefab] ~= nil then
            inst.pondcpt_l.checkfishtick = true
        end
    end
end
pas.OnItemLose_bldg_fish = function(inst, data)
    if inst.pondcpt_l ~= nil and not inst.pondcpt_l.checkfishtick then
        if data ~= nil and data.prev_item ~= nil and ZIP_SOAK_L.fish[data.prev_item.prefab] ~= nil then
            inst.pondcpt_l.checkfishtick = true
        end
    end
end

table.insert(prefs, Prefab("pondbldg_fish", function()
    local inst = CreateEntity()
    fns.CommonFn(inst, "pondbldg_fish", nil, "closed", nil)
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("pondbldg_fish.tex")
    inst.MiniMapEntity:SetPriority(4) --优先级得在泉池之上
    inst:SetDeploySmartRadius(0.1)
    inst:SetPhysicsRadiusOverride(1.5) --增加可触发半径，因为要放进泉池里面，无法走过去打开容器
    fns.SetRotatable_com(inst)
    fns.InitSimpleFloat(inst, "pondbldg_fish", nil, "fish")
    inst:AddTag("structure")
    inst:AddTag("meteor_protection") --防止被流星破坏
    inst.legiontag_notfoodbox = true --代表这不是食物存储类容器

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = pas.OnReplicated_bldg_fish
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")
    inst:AddComponent("savedrotation")
    fns.SetContainer(inst, "pondbldg_fish", pas.OnOpen_bldg, pas.OnClose_bldg)

    inst:AddComponent("preserver")
	inst.components.preserver:SetPerishRateMultiplier(pas.SetPerishRate_bldg_fish)

    fns.SetWorkable(inst, pas.OnWorked_bldg, pas.OnFinished_bldg, "HAMMER", 3)
    TOOLS_L.MakeSnowCovered_serv(inst)
    MakeHauntable(inst)

    inst:ListenForEvent("onbuilt", pas.OnBuilt_bldg)
    inst:ListenForEvent("ondeconstructstructure", pas.OnDeconstruct_bldg)
    inst:ListenForEvent("itemget", pas.OnItemGet_bldg_fish) --只有空格子放上物品时才触发，已有物品叠加数变化时不会触发的
	inst:ListenForEvent("itemlose", pas.OnItemLose_bldg_fish) --只有格子失去整个物品时才触发，已有物品叠加数变化时不会触发的

    return inst
end, {
    Asset("ANIM", "anim/ui_bookstation_4x5.zip"), --官方的容器栏背景动画模板
    Asset("ANIM", "anim/ui_l_pond_6x6.zip"),
    Asset("ANIM", "anim/pondbldg_fish.zip")
}, nil))

--------------------
--------------------

return unpack(prefs)

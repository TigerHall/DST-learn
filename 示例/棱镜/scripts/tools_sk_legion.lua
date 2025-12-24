local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas = {} --为了不暴露局部变量，单独装一起

pas.CopyValue = function(data, nokeys)
    if data == nil or type(data) ~= "table" then
        return data
    end
    local dd = {}
    for k, v in pairs(data) do
        if nokeys == nil or not nokeys[k] then --部分数据不需要复制
            dd[k] = pas.CopyValue(v)
        end
    end
    return dd
end
pas.CopySkinedData = function(basedata, copyeddata, nokeys)
    for name, data in pairs(copyeddata) do
        local dd = pas.CopyValue(data, nokeys)
        basedata[name] = dd
    end
end

fns.dd_agronssword = {
    img_tex = "agronssword", img_atlas = "images/inventoryimages/agronssword.xml",
    img_tex2 = "agronssword2", img_atlas2 = "images/inventoryimages/agronssword2.xml",
    build = "agronssword", fx = "agronssword_fx"
}
fns.dd_agronssword_taste = {
    img_tex = "agronssword_taste", img_atlas = "images/inventoryimages_skin/agronssword_taste.xml",
    img_tex2 = "agronssword_taste2", img_atlas2 = "images/inventoryimages_skin/agronssword_taste2.xml",
    build = "agronssword_taste", fx = "agronssword_taste_fx"
}
fns.dd_float_agronssword = { cut = -0.01, size = "small", offset_y = 0.2, scale = 1.1, nofx = nil }
fns.dd_float_agronssword_taste = { cut = 0.02, size = "small", offset_y = 0.25, scale = 1.2, nofx = nil }
fns.dd_float_agronssword_sun = { cut = -0.01, size = "small", offset_y = 0.3, scale = nil, nofx = nil }

fns.dd_fishhomingbait = {
    dusty = {
        img = "fishhomingbait1", atlas = "images/inventoryimages/fishhomingbait1.xml",
        anim = "idle1", swap = "swap1", symbol = "base1", build = "fishhomingbait"
    },
    pasty = {
        img = "fishhomingbait2", atlas = "images/inventoryimages/fishhomingbait2.xml",
        anim = "idle2", swap = "swap2", symbol = "base2", build = "fishhomingbait"
    },
    hardy = {
        img = "fishhomingbait3", atlas = "images/inventoryimages/fishhomingbait3.xml",
        anim = "idle3", swap = "swap3", symbol = "base3", build = "fishhomingbait"
    }
}
fns.dd_siving_ctlwater = {
    siv_bar = {
        x = 0, y = -180, z = 0, scale = nil,
        bank = "siving_ctlwater", build = "siving_ctlwater", anim = "bar"
    }
}
fns.dd_siving_ctldirt = {
    siv_bar1 = {
        x = -48, y = -140, z = 0, scale = nil,
        bank = "siving_ctldirt", build = "siving_ctldirt", anim = "bar1"
    },
    siv_bar2 = {
        x = -5, y = -140, z = 0, scale = nil,
        bank = "siving_ctldirt", build = "siving_ctldirt", anim = "bar2"
    },
    siv_bar3 = {
        x = 39, y = -140, z = 0, scale = nil,
        bank = "siving_ctldirt", build = "siving_ctldirt", anim = "bar3"
    }
}
fns.dd_siving_ctlall = {
    siv_bar1 = {
        x = -53, y = -335, z = 0, scale = nil,
        bank = "siving_ctldirt", build = "siving_ctldirt", anim = "bar1"
    },
    siv_bar2 = {
        x = -10, y = -360, z = 0, scale = nil,
        bank = "siving_ctldirt", build = "siving_ctldirt", anim = "bar2"
    },
    siv_bar3 = {
        x = 34, y = -335, z = 0, scale = nil,
        bank = "siving_ctldirt", build = "siving_ctldirt", anim = "bar3"
    },
    siv_bar4 = {
        x = -10, y = -297, z = 0, scale = nil,
        bank = "siving_ctlwater", build = "siving_ctlwater", anim = "bar"
    }
}
fns.dd_refractedmoonlight = {
    img_tex = "refractedmoonlight", img_atlas = "images/inventoryimages/refractedmoonlight.xml",
    img_tex2 = "refractedmoonlight2", img_atlas2 = "images/inventoryimages/refractedmoonlight2.xml",
    build = "refractedmoonlight", fx = "refracted_l_spark_fx"
}
fns.dd_refractedmoonlight_taste = {
    img_tex = "refractedmoonlight_taste", img_atlas = "images/inventoryimages_skin/refractedmoonlight_taste.xml",
    img_tex2 = "refractedmoonlight_taste2", img_atlas2 = "images/inventoryimages_skin/refractedmoonlight_taste2.xml",
    build = "refractedmoonlight_taste", fx = "refracted_l_spark_taste_fx"
}
fns.img_tomahawksteak = { atlas = "images/inventoryimages/dish_tomahawksteak.xml", image = "dish_tomahawksteak.tex" }
fns.swap_tomahawksteak = { build = "dish_tomahawksteak", file = "base" }
fns.img_tomahawksteak_twist = {
    atlas = "images/inventoryimages_skin/dish_tomahawksteak_twist.xml", image = "dish_tomahawksteak_twist.tex"
}
fns.swap_tomahawksteak_twist = { build = "dish_tomahawksteak_twist", file = "xx" }

fns.overkeys_simmer = { "data_up", "data_uppro", "data_up_inf", "data_uppro_inf", "data_uppro_item", "data_uppro_inf_item" }
fns.anim_simmer = { bank = "simmeredmoonlight", build = "simmeredmoonlight", anim = 0 }
fns.float_simmer_item = { cut = nil, size = "small", offset_y = 0.15, scale = 1.3 }
fns.float_simmer_pro_item = { cut = nil, size = "small", offset_y = 0.15, scale = 1.3 }
fns.img_simmer_pro_item = {
    name = "simmeredmoonlight_pro_item", atlas = "images/inventoryimages/simmeredmoonlight_pro_item.xml",
    setable = true
}
fns.img_simmer_pro_inf_item = {
    name = "simmeredmoonlight_pro_inf_item", atlas = "images/inventoryimages/simmeredmoonlight_pro_inf_item.xml",
    setable = true
}
fns.On_simmer_pro = function(inst, skined, skinname, userid)
    inst.AnimState:OverrideSymbol("potbase", inst.AnimState:GetBuild(), "potbase_pro")
end
fns.On_simmer_inf = function(inst, skined, skinname, userid)
    inst.AnimState:OverrideSymbol("pot", inst.AnimState:GetBuild(), "pot_inf")
end
fns.On_simmer_pro_inf = function(inst, skined, skinname, userid)
    inst.AnimState:OverrideSymbol("potbase", inst.AnimState:GetBuild(), "potbase_pro")
    inst.AnimState:OverrideSymbol("pot", inst.AnimState:GetBuild(), "pot_inf")
end

----------

fns.GetImg_base = function()
    return { setable = true }
end
fns.GetImg_base2 = function()
    return { setable = false }
end

----------

pas.GetBerriesPercent = function(pickable)
    return pickable.cycles_left and pickable.cycles_left / pickable.max_cycles or 1
end
fns.On_fruitformbush = function(inst, skined, skinname, userid)
    inst._fruitform = true
    local pct
    if inst._dd_wax ~= nil then --打过蜡的
        if inst.legiontag_dowax or POPULATING then return end --POPULATING=true时，运行到这里，inst._dd_wax 还没有准备好
        if inst._dd_wax.state == nil then
            --nothing
        elseif inst._dd_wax.state == 1 then
            pct = 1
        elseif inst._dd_wax.state == 2 then
            pct = 0.5
        else
            pct = 0.1
        end
    elseif inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then --正常植物
        pct = pas.GetBerriesPercent(inst.components.pickable)
    end
    if pct == nil then
        inst.AnimState:ClearOverrideSymbol("bush_berry_build")
    elseif pct >= 0.9 then
        inst.AnimState:OverrideSymbol("bush_berry_build", inst.AnimState:GetBuild(), "bush3")
    elseif pct >= 0.33 then
        inst.AnimState:OverrideSymbol("bush_berry_build", inst.AnimState:GetBuild(), "bush2")
    else
        inst.AnimState:OverrideSymbol("bush_berry_build", inst.AnimState:GetBuild(), "bush1")
    end
end
fns.Off_fruitformbush = function(inst, skined, skinname, userid)
    inst._fruitform = nil
    local pct
    if inst._dd_wax ~= nil then --打蜡植物
        if inst._dd_wax.state == nil then
            --nothing
        elseif inst._dd_wax.state == 1 then
            pct = 1
        elseif inst._dd_wax.state == 2 then
            pct = 0.5
        else
            pct = 0.1
        end
        inst._dd_wax.form = nil --打蜡数据也得还原呀！
    elseif inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then --正常植物
        pct = pas.GetBerriesPercent(inst.components.pickable)
    end
    inst.AnimState:ClearOverrideSymbol("bush_berry_build")
    if pct == nil then
        inst.AnimState:Hide("berries")
        inst.AnimState:Hide("berriesmore")
        inst.AnimState:Hide("berriesmost")
    elseif pct >= 0.9 then
        inst.AnimState:Hide("berries")
        inst.AnimState:Hide("berriesmore")
        inst.AnimState:Show("berriesmost")
    elseif pct >= 0.33 then
        inst.AnimState:Hide("berries")
        inst.AnimState:Show("berriesmore")
        inst.AnimState:Hide("berriesmost")
    else
        inst.AnimState:Show("berries")
        inst.AnimState:Hide("berriesmore")
        inst.AnimState:Hide("berriesmost")
    end
end

----------

pas.On_dd = function(inst, skined)
    if skined ~= nil then
        inst._dd = skined.dd
    else
        inst._dd = nil
    end
end
fns.On_pot_ww = function(inst, skined, skinname, userid)
    pas.On_dd(inst, skined)
    if inst._dd_wax ~= nil then --打过蜡的
        if inst.legiontag_dowax or POPULATING then return end
    end
    if inst.fn_init ~= nil then
        inst.fn_init(inst)
    end
end

fns.dd_pot_ww_future = {
    y = -35,
    fixmap = {
        succulent_picked = { y = -70, [2] = { y=-25 }, [3] = { y=-25 } },
        foliage = { y = -70, [3] = { y=-60 } }
    },
    plantfn = function(inst, fx)
        fx.AnimState:ClearOverrideSymbol("asoil") --土壤贴图丢不得
        fx.AnimState:SetAddColour(22/255, 179/255, 163/255, 0)
        fx.AnimState:SetLightOverride(0.1)
    end,
    workedfn = function(inst, worker, workleft)
        if inst._fx_ls1 ~= nil then
            inst._fx_ls1.AnimState:SetFrame(0)
        end
        if inst._fx_ls2 ~= nil then
            inst._fx_ls2.AnimState:SetFrame(0)
        end
    end,
    soilfn = function(inst, isout)end, --用来防止多做操作的
    soilchangefn = function(inst)
        if inst.task_soilfx ~= nil then
            return
        end
        inst.task_soilfx = inst:DoTaskInTime(0.6, function()
            inst.task_soilfx = nil
            local fx = inst._soilfx_ls
            if fx == nil or not fx:IsValid() then
                fx = SpawnPrefab("pot_ww_future_fx")
                fx.AnimState:SetFinalOffset(4)
                fx.entity:SetParent(inst.entity)
                fx.components.highlightchild:SetOwner(inst)
                inst._soilfx_ls = fx
            end
            local ft = inst._fertility or 80
            if ft <= 0 then
                ft = 0
            else
                ft = math.min(8, math.ceil(ft/20))
            end
            fx.AnimState:PlayAnimation("ft"..tostring(ft), false)
        end)
    end
}
fns.dd_pot_ww_future_wax = {
    y = fns.dd_pot_ww_future.y, plantfn = fns.dd_pot_ww_future.plantfn, fixmap = fns.dd_pot_ww_future.fixmap,
    soilfn = function(inst, isout)
        local fx = inst._soilfx_ls
        if fx == nil or not fx:IsValid() then
            fx = SpawnPrefab("pot_ww_future_fx")
            fx.AnimState:SetFinalOffset(4)
            fx.entity:SetParent(inst.entity)
            fx.components.highlightchild:SetOwner(inst)
            inst._soilfx_ls = fx
        end
        local ft = isout and 0 or math.random(8)
        fx.AnimState:PlayAnimation("ft"..tostring(ft), false)
        if inst._plant ~= nil then --土壤贴图丢不得
            inst._plant.AnimState:ClearOverrideSymbol("asoil")
        end
    end
}
pas.OnRemoved_pot_ww_future = function(inst)
    if inst.task_bgfx ~= nil then
        inst.task_bgfx:Cancel()
        inst.task_bgfx = nil
    end
    if inst._fx_ls1 ~= nil then
        inst._fx_ls1:Remove()
        inst._fx_ls1 = nil
    end
    if inst._fx_ls2 ~= nil then
        inst._fx_ls2:Remove()
        inst._fx_ls2 = nil
    end
    if inst.task_soilfx ~= nil then
        inst.task_soilfx:Cancel()
        inst.task_soilfx = nil
    end
    if inst._soilfx_ls ~= nil then
        inst._soilfx_ls:Remove()
        inst._soilfx_ls = nil
    end
end
fns.On_pot_ww_future = function(inst, skined, skinname, userid)
    pas.On_dd(inst, skined)
    inst.AnimState:SetSymbolLightOverride("aphoton", 0.1)
    inst:ListenForEvent("onremove", pas.OnRemoved_pot_ww_future)

    if inst.task_bgfx == nil then --加载时和刚制作出来时无法获取正确坐标位置，所以延时获取才行
        inst.task_bgfx = inst:DoTaskInTime(POPULATING and 0.7+math.random() or 0.3, function()
            inst.task_bgfx = nil
            local fx = inst._fx_ls1 --背景
            if fx == nil or not fx:IsValid() then
                fx = SpawnPrefab("pot_ww_future_fx")
                fx.AnimState:SetFinalOffset(1)
                fx.AnimState:PlayAnimation("bgfx", false)
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                -- fx.entity:SetParent(inst.entity) --如果这样，鼠标很容易误触，所以还是不要融为一体更好
                -- fx.components.highlightchild:SetOwner(inst)
                inst._fx_ls1 = fx
            end
            local fx2 = inst._fx_ls2 --前景
            if fx2 == nil or not fx2:IsValid() then
                fx2 = SpawnPrefab("pot_ww_future_fx")
                fx2.AnimState:SetFinalOffset(3)
                fx2.AnimState:PlayAnimation("ftfx", false)
                fx2.Transform:SetPosition(inst.Transform:GetWorldPosition())
                -- fx2.entity:SetParent(inst.entity) --如果这样，鼠标很容易误触，所以还是不要融为一体更好
                -- fx2.components.highlightchild:SetOwner(inst)
                inst._fx_ls2 = fx2
            end
            inst.AnimState:PlayAnimation("idle2", true)
            inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames())-1)
        end)
    end

    if inst._dd_wax ~= nil then --打过蜡的
        if inst.legiontag_dowax or POPULATING then return end
    end
    if inst.fn_init ~= nil then
        inst.fn_init(inst)
    end
end
fns.Off_pot_ww_future = function(inst, skined, skinname, userid)
    inst.AnimState:PlayAnimation("idle", false)
    inst.AnimState:SetSymbolLightOverride("aphoton", 0)
    inst:RemoveEventCallback("onremove", pas.OnRemoved_pot_ww_future)
    pas.OnRemoved_pot_ww_future(inst)
    if inst._plant ~= nil then
        inst._plant.AnimState:SetAddColour(0, 0, 0, 0)
        inst._plant.AnimState:SetLightOverride(0)
    end
end

fns.dd_pot_ww_world = { y = 10, fixmap = { cutlichen = { y = 17 }, bean_l_ice = { y = 17 } } }

fns.On_plant_berries = function(inst, skined, skinname, userid)
    local cpt = inst.components.perennialcrop2
    if cpt ~= nil and cpt.stage >= cpt.stage_max then
        inst.AnimState:OverrideSymbol("fruit1", inst.AnimState:GetBuild() or "crop_legion_berries", "fruit2")
    else
        inst.AnimState:ClearOverrideSymbol("fruit1")
    end
end

----------

fns.dd_soulbook = {
    fx = "soul_l_fx", healfx = "soulheal_l_fx", bookhealfx = "soulbook_l_fx",
    booksharelvlfx = "soulbook_share1_l_fx", booksharesoulfx = "soulbook_share2_l_fx",
    jumpinfx = "soulbook_jumpin_l_fx", jumpoutfx = "soulbook_jumpout_l_fx",
    lvlfx = "soulbook_lvlup_l_fx"
}
fns.dd_soulbook_taste = {
    fx = "soul_l_fx_taste", healfx = "soulheal_l_fx_taste", bookhealfx = "soulbook_l_fx_taste",
    booksharelvlfx = "soulbook_share1_l_fx_taste", booksharesoulfx = "soulbook_share2_l_fx_taste",
    jumpinfx = "soulbook_jumpin_l_fx_taste", jumpoutfx = "soulbook_jumpout_l_fx_taste",
    lvlfx = "soulbook_lvlup_l_fx_taste"
}

fns.On_soulbook = function(inst, skined, skinname, userid)
    if skined ~= nil then
        inst._dd = skined.dd
    else
        inst._dd = {}
        pas.CopySkinedData(inst._dd, fns.dd_soulbook)
    end
    if inst.task_init == nil then --加载时不需要更新，会延迟初始化的
        if inst.task_skininit ~= nil then
            inst.task_skininit:Cancel()
        end
        inst.task_skininit = inst:DoTaskInTime(0.2, function() --延迟操作，因为此时服务器和客户端的inst.skinname参数还未设置好
            inst.task_skininit = nil
            inst._updatespells:push() --更新所有客户端的按钮轮盘
            inst.UpdateBtns(inst, inst._user_l:value())
        end)
    end
end

--TOOLS_S.
-- local TOOLS_S = require("tools_sk_legion")
return fns

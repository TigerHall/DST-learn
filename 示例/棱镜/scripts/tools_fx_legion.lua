local fns = {} --lua的限制，一个域里只能有最多200个局部变量，否则会报错。通过把所有变量都存进一个主变量，来预防这个问题
local pas = {} --为了不暴露局部变量，单独装一起

--[ 设置掉落散开型特效。借鉴于提灯的皮肤特效代码。但是因为提灯皮肤的特效动画没法做修改，所以整个逻辑都没用了，先留着吧 ]--

local function Fx1_remove(fx)
    fx._lantern._lit_fx_inst = nil
end
local function Fx1_enterlimbo(inst)
    --V2C: wow! superhacks!
    --     we want to drop the FX behind when the item is picked up, but the transform
    --     is cleared before lantern_off is reached, so we need to figure out where we
    --     were just before.
    if inst._lit_fx_inst ~= nil then
        inst._lit_fx_inst._lastpos = inst._lit_fx_inst:GetPosition()
        local parent = inst.entity:GetParent()
        if parent ~= nil then
            local x, y, z = parent.Transform:GetWorldPosition()
            local angle = (360 - parent.Transform:GetRotation()) * DEGREES
            local dx = inst._lit_fx_inst._lastpos.x - x
            local dz = inst._lit_fx_inst._lastpos.z - z
            local sinangle, cosangle = math.sin(angle), math.cos(angle)
            inst._lit_fx_inst._lastpos.x = dx * cosangle + dz * sinangle
            inst._lit_fx_inst._lastpos.y = inst._lit_fx_inst._lastpos.y - y
            inst._lit_fx_inst._lastpos.z = dz * cosangle - dx * sinangle
        end
    end
end
local function Fx1_off(inst)
    local fx = inst._lit_fx_inst
    if fx ~= nil then
        if fx.KillFX ~= nil then
            inst._lit_fx_inst = nil
            inst:RemoveEventCallback("onremove", Fx1_remove, fx)
            fx:RemoveEventCallback("enterlimbo", Fx1_enterlimbo, inst)
            fx._lastpos = fx._lastpos or fx:GetPosition()
            fx.entity:SetParent(nil)
            if fx.Follower ~= nil then
                fx.Follower:StopFollowing()
            end
            fx.Transform:SetPosition(fx._lastpos:Get())
            fx:KillFX()
        else
            fx:Remove()
        end
    end
end
local function Fx1_on(inst)
    local owner = inst.components.inventoryitem.owner
    if owner ~= nil then
        if inst._lit_fx_inst ~= nil and inst._lit_fx_inst.prefab ~= inst._heldfx then
            Fx1_off(inst)
        end
        if inst._heldfx ~= nil then
            if inst._lit_fx_inst == nil then
                inst._lit_fx_inst = SpawnPrefab(inst._heldfx)
                inst._lit_fx_inst._lantern = inst
                inst._lit_fx_inst.entity:AddFollower()
                inst:ListenForEvent("onremove", Fx1_remove, inst._lit_fx_inst)
            end
            inst._lit_fx_inst.entity:SetParent(owner.entity)

            local follow_dd = inst._sets_l.follow_dd
            if follow_dd ~= nil then
                inst._lit_fx_inst.Follower:FollowSymbol(owner.GUID, follow_dd.symbol or "swap_object",
                    follow_dd.x or 0, follow_dd.y or 0, follow_dd.z or 0)
            else
                inst._lit_fx_inst.Follower:FollowSymbol(owner.GUID, "swap_object", 0, 0, 0)
            end
        end
    else
        if inst._lit_fx_inst ~= nil and inst._lit_fx_inst.prefab ~= inst._groundfx then
            Fx1_off(inst)
        end
        if inst._groundfx ~= nil then
            if inst._lit_fx_inst == nil then
                inst._lit_fx_inst = SpawnPrefab(inst._groundfx)
                inst._lit_fx_inst._lantern = inst
                inst:ListenForEvent("onremove", Fx1_remove, inst._lit_fx_inst)
                if inst._lit_fx_inst.KillFX ~= nil then
                    inst._lit_fx_inst:ListenForEvent("enterlimbo", Fx1_enterlimbo, inst)
                end
            end
            inst._lit_fx_inst.entity:SetParent(inst.entity)
        end
    end
end
local function Fx1_init(inst, sets, nostart)
    if not TheWorld.ismastersim then
        return
    end
    inst._heldfx = sets.fx_held
    inst._groundfx = sets.fx_ground
    inst._sets_l = sets
    if sets.events ~= nil then
        for eventname, kind in pairs(sets.events) do
            if kind == 1 then
                inst:ListenForEvent(eventname, Fx1_on)
            else
                inst:ListenForEvent(eventname, Fx1_off)
            end
        end
    else
        inst:ListenForEvent("equipped", Fx1_on)
        inst:ListenForEvent("unequipped", Fx1_off)
        inst:ListenForEvent("onremove", Fx1_off)
    end
    if not nostart then
        Fx1_on(inst)
    end
end
local function Fx1_clear(inst)
    Fx1_off(inst)

    inst._heldfx = nil
    inst._groundfx = nil
    if inst._sets_l ~= nil then
        if inst._sets_l.events ~= nil then
            for eventname, kind in pairs(inst._sets_l.events) do
                if kind == 1 then
                    inst:RemoveEventCallback(eventname, Fx1_on)
                else
                    inst:RemoveEventCallback(eventname, Fx1_off)
                end
            end
        else
            inst:RemoveEventCallback("equipped", Fx1_on)
            inst:RemoveEventCallback("unequipped", Fx1_off)
            inst:RemoveEventCallback("onremove", Fx1_off)
        end
        inst._sets_l = nil
    end
end

--[ 官方手杖皮肤特效式的特效 ]--

pas.cane_do_trail = function(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner() or inst
    if not owner.entity:IsVisible() then
        return
    end
    local fxdd = inst._ls_fxdd
    local x, y, z = owner.Transform:GetWorldPosition()
    if owner.sg ~= nil and owner.sg:HasStateTag("moving") then
        local theta = -owner.Transform:GetRotation() * DEGREES
        local speed = owner.components.locomotor:GetRunSpeed() * .1
        x = x + speed * math.cos(theta)
        z = z + speed * math.sin(theta)
    end
    local mounted = owner.components.rider ~= nil and owner.components.rider:IsRiding()
    local map = TheWorld.Map
    local offset = FindValidPositionByFan(
        math.random() * TWOPI,
        (mounted and 1 or .5) + math.random() * .5,
        4,
        function(offset)
            local pt = Vector3(x + offset.x, 0, z + offset.z)
            return map:IsPassableAtPoint(pt:Get())
                and not map:IsPointNearHole(pt)
                and #TheSim:FindEntities(pt.x, 0, pt.z, .7, fxdd.trailfx_tags or { "shadowtrail" }) <= 0
        end
    )
    if offset ~= nil then
        SpawnPrefab(fxdd.trailfx).Transform:SetPosition(x + offset.x, 0, z + offset.z)
    end
end
pas.cane_equipped = function(inst, data)
    local fxdd = inst._ls_fxdd
    if fxdd.handfx ~= nil then
        if fxdd.handfx_inst == nil then
            fxdd.handfx_inst = SpawnPrefab(fxdd.handfx)
            fxdd.handfx_inst.entity:AddFollower()
        end
        fxdd.handfx_inst.entity:SetParent(data.owner.entity)
        fxdd.handfx_inst.Follower:FollowSymbol(data.owner.GUID, "swap_object", 0, fxdd.handfx_offset_y or 0, 0)
    end
    if fxdd.trailfx ~= nil and fxdd.trailfx_task == nil then
        fxdd.trailfx_task = inst:DoPeriodicTask(6 * FRAMES, pas.cane_do_trail, 2 * FRAMES)
    end
end
pas.cane_unequipped = function(inst, owner)
    local fxdd = inst._ls_fxdd
    if fxdd == nil then
        return
    end
    if fxdd.handfx_inst ~= nil then
        fxdd.handfx_inst:Remove()
        fxdd.handfx_inst = nil
    end
    if fxdd.trailfx_task ~= nil then
        fxdd.trailfx_task:Cancel()
        fxdd.trailfx_task = nil
    end
end
fns.FxCane_on = function(inst, sets)
    local fxdd = sets
    inst._ls_fxdd = sets
    if fxdd.handfx ~= nil or fxdd.trailfx ~= nil then
        inst:ListenForEvent("equipped", pas.cane_equipped)
        inst:ListenForEvent("unequipped", pas.cane_unequipped)
        if fxdd.handfx ~= nil then
            if fxdd.handfx_offset_y == nil then
                fxdd.handfx_offset_y = -105
            end
            inst:ListenForEvent("onremove", pas.cane_unequipped)
        end
    end
end
fns.FxCane_off = function(inst)
    inst:RemoveEventCallback("equipped", pas.cane_equipped)
    inst:RemoveEventCallback("unequipped", pas.cane_unequipped)
    inst:RemoveEventCallback("onremove", pas.cane_unequipped)
    pas.cane_unequipped(inst)
    inst._ls_fxdd = nil
end

--[ 随机播放动画 ]--

pas.DoRandomAnim = function(inst)
    local dd = inst._ls_randanims
    if dd == nil then
        return
    end
    local anim = nil
    if dd.x == nil then
        dd.x = math.random(#dd.anims)
    end
    anim = dd.anims[dd.x] or dd.anims[1]
    if type(anim) == "table" then
        if dd.y == nil then
            dd.y = 1
        else
            dd.y = dd.y + 1
        end
        anim = anim[dd.y]
        if anim == nil then
            dd.x = nil
            dd.y = nil
            pas.DoRandomAnim(inst)
            return
        end
    else
        dd.x = nil
        dd.y = nil
    end
    inst.AnimState:PlayAnimation(anim, false)
end
fns.StartRandomAnims = function(inst, doit, anims)
    if inst._ls_randanims == nil then
        inst:ListenForEvent("animover", pas.DoRandomAnim) --看起来被装备后，动画会自动暂停。所以我也不用主动关闭监听了
    end
    inst._ls_randanims = { anims = anims }
    if doit then
        pas.DoRandomAnim(inst)
    end
end
fns.StopRandomAnims = function(inst)
    inst._ls_randanims = nil
    inst:RemoveEventCallback("animover", pas.DoRandomAnim)
end

--[ 动画部件跟随型特效 ]--

fns.FxFollow_on = function(inst, owner, fxname, sym, x, y, fxkey)
    local fx = SpawnPrefab(fxname)
    if fx ~= nil then
        fx.entity:SetParent(owner.entity)
        if fx.Follower == nil then
            fx.entity:AddFollower()
        end
        fx.Follower:FollowSymbol(owner.GUID, sym or "swap_object", x or 0, y or 0, 0)
        if fx.components.highlightchild ~= nil then
            fx.components.highlightchild:SetOwner(owner)
        end
        inst[fxkey] = fx
    end
end
fns.FxFollow_off = function(inst, fxkey)
    if inst[fxkey] ~= nil then
        inst[fxkey]:Remove()
        inst[fxkey] = nil
    end
end

-- local TOOLS_F = require("tools_fx_legion")
return fns

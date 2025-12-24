local function MakeSoulFx(name, TINT, data)
    local SCALE = .8
    local function PushColour(inst, addval, multval)
        if inst.components.highlight == nil then
            inst.AnimState:SetHighlightColour(TINT.r * addval, TINT.g * addval, TINT.b * addval, 0)
            inst.AnimState:OverrideMultColour(multval, multval, multval, 1)
        else
            inst.AnimState:OverrideMultColour()
        end
    end
    local function PopColour(inst)
        if inst.components.highlight == nil then
            inst.AnimState:SetHighlightColour()
        end
        inst.AnimState:OverrideMultColour()
    end
    local function OnUpdateTargetTint(inst)--, dt)
        if inst._tinttarget:IsValid() then
            local curframe = inst.AnimState:GetCurrentAnimationFrame()
            if curframe < 10 then
                local k = curframe / 10
                k = k * k
                PushColour(inst._tinttarget, (1 - k) * .7, k * .7 + .3)
            else
                inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateTargetTint)
                inst.OnRemoveEntity = nil
                PopColour(inst._tinttarget)
            end
        else
            inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateTargetTint)
            inst.OnRemoveEntity = nil
        end
    end
    local function OnRemoveEntity(inst)
        if inst._tinttarget:IsValid() then
            PopColour(inst._tinttarget)
        end
    end
    local function OnTargetDirty(inst)
        if inst._target:value() ~= nil and inst._tinttarget == nil then
            if inst.components.updatelooper == nil then
                inst:AddComponent("updatelooper")
            end
            inst.components.updatelooper:AddOnUpdateFn(OnUpdateTargetTint)
            inst._tinttarget = inst._target:value()
            inst.OnRemoveEntity = OnRemoveEntity
        end
    end
    local function Setup(inst, target)
        inst._target:set(target)
        if not TheNet:IsDedicated() then
            OnTargetDirty(inst)
        end
        if target.SoundEmitter ~= nil then
            target.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)
        end
    end

    local function Fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("wortox_soul_ball")
        inst.AnimState:SetBuild("wortox_soul_ball")
        inst.AnimState:PlayAnimation("idle_pst")
        inst.AnimState:SetFrame(6)
        inst.AnimState:SetScale(SCALE, SCALE)
        inst.AnimState:SetFinalOffset(3)

        inst:AddTag("FX")

        inst._target = net_entity(inst.GUID, name.."._target", "targetdirty")

        if data.fn_common ~= nil then
            data.fn_common(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            inst:ListenForEvent("targetdirty", OnTargetDirty)
            return inst
        end

        inst:ListenForEvent("animover", inst.Remove)
        inst.persists = false
        inst.Setup = Setup

        return inst
    end

    return Prefab(name, Fn, data.assets)
end

local function MakeSoulHealFx(name, TINT, data)
    local function OnUpdateTargetTint(inst)--, dt)
        if inst._tinttarget:IsValid() then
            local curframe = inst.AnimState:GetCurrentAnimationFrame()
            if curframe < 10 then
                local k = curframe / 10 * .5
                if inst._tinttarget.components.colouradder ~= nil then
                    inst._tinttarget.components.colouradder:PushColour(inst, TINT.r * k, TINT.g * k, TINT.b * k, 0)
                end
            elseif curframe < 40 then
                local k = (curframe - 10) / 30
                k = (1 - k * k) * .5
                if inst._tinttarget.components.colouradder ~= nil then
                    inst._tinttarget.components.colouradder:PushColour(inst, TINT.r * k, TINT.g * k, TINT.b * k, 0)
                end
            else
                inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateTargetTint)
                if inst._tinttarget.components.colouradder ~= nil then
                    inst._tinttarget.components.colouradder:PopColour(inst)
                end
            end
        else
            inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateTargetTint)
        end
    end
    local function Setup(inst, target)
        if inst.components.updatelooper == nil then
            inst:AddComponent("updatelooper")
            inst.components.updatelooper:AddOnUpdateFn(OnUpdateTargetTint)
            inst._tinttarget = target
        end
        if target.SoundEmitter ~= nil then
            target.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/heal")
        end
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddFollower() --直接就加了
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("wortox_soul_heal_fx")
        inst.AnimState:SetBuild("wortox_soul_heal_fx")
        inst.AnimState:PlayAnimation("heal")
        inst.AnimState:SetFinalOffset(3)
        inst.AnimState:SetScale(1.5, 1.5)
        inst.AnimState:SetDeltaTimeMultiplier(2) --播放加速？

        inst:AddTag("FX")

        if data.fn_common ~= nil then
            data.fn_common(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end

        if math.random() < .5 then
            inst.AnimState:SetScale(-1.5, 1.5)
        end

        inst:ListenForEvent("animover", inst.Remove)
        inst.persists = false
        inst.Setup = Setup

        return inst
    end
    return Prefab(name, fn, data.assets)
end

------
------

local assets = { Asset("ANIM", "anim/wortox_soul_ball.zip") }
local co = { r = 154/255, g = 23/255, b = 19/255 } --暗红色(官方)
local co_taste = { r = 246/255, g = 207/255, b = 75/255 } --金黄色
local fx_base = { assets = assets }
local fx_taste = {
    assets = assets,
    fn_common = function(inst)
        inst.AnimState:SetAddColour(co_taste.r, co_taste.g, co_taste.b, 0) --Tip: 该函数没法帧同步
    end
}

local assets_heal = { Asset("ANIM", "anim/wortox_soul_heal_fx.zip") }
local healfx_base = { assets = assets_heal }
local healfx_taste = { assets = assets_heal, fn_common = fx_taste.fn_common }

------

return MakeSoulFx("soul_l_fx", co, fx_base),
    MakeSoulFx("soul_l_fx_taste", co_taste, fx_taste),
    MakeSoulHealFx("soulheal_l_fx", co, healfx_base),
    MakeSoulHealFx("soulheal_l_fx_taste", co_taste, healfx_taste)

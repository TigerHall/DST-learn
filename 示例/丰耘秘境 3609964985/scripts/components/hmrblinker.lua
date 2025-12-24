-- 该组件加在通用端

local function DefaultCanBlinkTo(inst, pt)
    -- NOTES(JBK): Keep in sync with blinkstaff. [BATELE]
    return TheWorld.Map:IsPassableAtPoint(pt:Get()) and not TheWorld.Map:IsGroundTargetBlocked(pt)
end

local function DefaultCanBlinkFromWithMap(inst, pt)
    -- NOTES(JBK): Change this if there is a reason to anchor Wortox when trying to use the map to teleport.
    return true
end

local function GetPointSpecialActions(inst, pos, useitem, right)
    local self = inst.components.hmrblinker
    if self:IsEnabled() then
        if right and useitem == nil and self ~= nil then
            if self.other_special_actions_fn ~= nil then
                local actions = self.other_special_actions_fn(self.inst, pos, useitem, right)
                if actions ~= nil then
                    return actions
                end
            end

            local canblink
            if inst.checkingmapactions then
                canblink = self.canblinkfromwithmap(inst, inst:GetPosition())
            else
                canblink = self.canblinkto(inst, pos)
            end
            if canblink then
                return { ACTIONS.HMR_BLINK }
            end
        end
    end
    return {}
end

local function OnSetOwner(inst)
    if inst.components.playeractionpicker ~= nil then
        local oldpointspecialactionsfn = inst.components.playeractionpicker.pointspecialactionsfn
        inst.components.playeractionpicker.pointspecialactionsfn = function(...)
            local actions = nil
            if oldpointspecialactionsfn ~= nil then
                actions = oldpointspecialactionsfn(...)
            end
            if actions == nil or #actions == 0 then
                actions = GetPointSpecialActions(...)
            end
            return actions
        end
    end
end

local Blinker = Class(function(self, inst)
    self.inst = inst

    self.canblinkto = DefaultCanBlinkTo
    self.canblinkfromwithmap = DefaultCanBlinkFromWithMap

    self.tintcolor = {154 / 255, 23 / 255, 19 / 255}
    self.blink_sources = {}

    self.enabled = net_bool(inst.GUID, "hmr_blink_enabled")
    if TheWorld.ismastersim then
        self.enabled:set_local(true)
        self.enabled:set(false)
    end

    inst:ListenForEvent("setowner", OnSetOwner)
end)

function Blinker:BlinkTo(pos)
    print("传送", pos, self.inst:GetPosition())
    if self.inst.sg ~= nil then
        self.inst.sg:GoToState("hmr_blinkin_pre")
    end
    BufferedAction(self.inst, nil, ACTIONS.HMR_BLINK, nil, pos):Do()
end

function Blinker:IsEnabled()
    return self.enabled:value()
end

function Blinker:Enable(enable)
    if TheWorld.ismastersim then
        self.enabled:set(enable)
    end
end

function Blinker:SetSource(source)
    self.current_source = source
    local data = self.blink_sources[source]
    if data ~= nil then
        if data.tintcolor ~= nil then
            self.tintcolor = data.tintcolor
        end
        if data.blinkfx ~= nil then
            self.fx_in = data.blinkfx[1]
            self.fx_out = data.blinkfx[2]
        end
        if data.onblinkin ~= nil then
            self.onblinkin = data.onblinkin
        end
        if data.onblinkout ~= nil then
            self.onblinkout = data.onblinkout
        end
    end
    if data == nil or source == nil then
        self.fx_in = "wortox_portal_jumpin_fx"
        self.fx_out = "wortox_portal_jumpout_fx"
        self.onblinkin = nil
        self.onblinkout = nil
        self.tintcolor = {154 / 255, 23 / 255, 19 / 255}
    end
end

-- source：实体，key：字符串
-- 由于用了实体记录源头，所以不进行保存，重新进入游戏时靠重新添加源头来恢复
function Blinker:AddSource(source, data)
    self.blink_sources[source] = data
    self:SetSource(source)
    if not self:IsEnabled() then
        self:Enable(true)
    end
end

function Blinker:RemoveSource(source)
    self.blink_sources[source] = nil
    if self.current_source == source then
        local next_source = next(self.blink_sources)
        if next_source == nil then
            self:Enable(false)
        else
            self.current_source = next_source
            self:SetSource(next_source)
        end
    end
end

function Blinker:IsSource(source)
    return self.blink_sources[source] ~= nil
end

function Blinker:SetOtherSpecialActionsFn(fn)
    self.other_special_actions_fn = fn
end

-- 可以进行普通跳跃
function Blinker:SetCanBlinkTo(fn)
    if fn ~= nil and type(fn) == "function" then
        self.canblinkto = fn
    else
        self.canblinkto = function()
            return true
        end
    end
end

-- 可以进行地图跳跃
function Blinker:SetCanBlinkFromWithMap(fn)
    if fn ~= nil and type(fn) == "function" then
        self.canblinkfromwithmap = fn
    else
        self.canblinkfromwithmap = function()
            return true
        end
    end
end

function Blinker:SetBlinkFX(fx_in, fx_out)
    self.fx_in = fx_in or "wortox_portal_jumpin_fx"
    self.fx_out = fx_out or "wortox_portal_jumpout_fx"
end

function Blinker:SetTintColor(color)
    self.tintcolor = color
end

function Blinker:GetTintColor()
    return self.tintcolor
end

function Blinker:IsTintEnabled()
    return self.tint_enable ~= false
end

function Blinker:SetTintEnable(enable)
    self.tint_enable = enable
end

function Blinker:SetOnBlinkIn(fn)
    self.onblinkin = fn
end

function Blinker:SetOnBlinkOut(fn)
    self.onblinkout = fn
end

function Blinker:BlinkIn()
    if self.fx_in ~= nil then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local fx = SpawnPrefab(self.fx_in)
        if fx ~= nil then
            fx.Transform:SetPosition(x, y, z)
        end
    end

    if self.onblinkin ~= nil then
        self.onblinkin(self.inst)
    end
end

function Blinker:BlinkOut()
    if self.fx_out ~= nil then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local fx = SpawnPrefab(self.fx_out)
        if fx ~= nil then
            fx.Transform:SetPosition(x, y, z)
        end
    end

    if self.onblinkout ~= nil then
        self.onblinkout(self.inst)
    end
end

function Blinker:OnSave()
    return {
        enabled = self.enabled:value(),
        tint_enable = self.tint_enable,
    }
end

function Blinker:OnLoad(data)
    if data.enabled == nil then
        data.enabled = false
    end
    self.enabled:set(data.enabled)
    self.tint_enable = data.tint_enable
end

return Blinker
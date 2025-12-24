local SoakerLegion = Class(function(self, inst)
    self.inst = inst
    -- self.target = nil --当前浸泡着的池子
    -- self.targetpos = {} --浸泡对象的世界坐标
    -- self.targetrad = 5.5 --浸泡对象的体积半径
    -- self.pos = {} --当前浸泡的世界坐标
    -- self.posidx = idx
    -- self.startpos = {} --当前浸泡前起跳位置的世界坐标
    self.times = {}
    self.talks = {}
    self.animtype = 0 --动画形式。4：漂浮装置的动画、3：坐下表情的动画、0：没有浸泡、1：浸泡跳入、2：浸泡跳出
    -- self.toy = nil --泡澡载具。玩家泡澡时携带，能提供一些特殊效果
    -- self.istoysoaking = true --标志目前泡澡流程是否是泡澡载具的影响
    self.cg_buffs = {}

    self._animtype = net_tinybyte(inst.GUID, "soakerlegion._animtype", "animtype_l_dirty")
    self._animtype:set_local(0)
    if not TheNet:IsDedicated() then --客户端或不开洞穴的房主服务器进程
        inst:ListenForEvent("animtype_l_dirty", function()
            self:AnimTypeDirty(self._animtype:value())
        end)
    end
end)

function SoakerLegion:SayIt(key)
    if self.inst.components.talker == nil then
        return
    end
    if self.inst:HasTag("mime") then --哑巴
        self.inst.components.talker:Say("") --虽然说不出话，但也得做动作
        return
    end
    local str = STRINGS.CHARACTERS[string.upper(self.inst.prefab)]
    if str == nil or str.SOAK_L == nil or str.SOAK_L[key] == nil then
        str = STRINGS.CHARACTERS.GENERIC.SOAK_L[key]
    else
        str = str.SOAK_L[key]
    end
    if str ~= nil then
        if type(str) == "table" then
            str = str[math.random(#str)]
        end
        self.inst.components.talker:Say(str)
    end
end

local function IsToy(item)
    if item.components.playerfloater ~= nil and item.components.equippable == nil then --官方的“个人漂浮装置”
        return true
    end
end
function SoakerLegion:FindAToy()
    if self.inst.components.inventory.isopen then
        local toy = self.inst.components.inventory:FindItem(IsToy)
        if toy == nil then
            return
        end
        -- self.mult_health = 1.1
        self.mult_sanity = 1.1
        self.mult_moisture = 0.75
        self.cg_buffs = { buff_l_softskin = 2, buff_l_dizzy = 1 } --数值代表延后的时间周期，不是直接的时间
        self.istoysoaking = true
        self.toy = toy
    end
end
function SoakerLegion:TriggerToy(ison)
    if self.toy == nil then
        return
    end
    local inst = self.inst
    if ison then
        -- inst.Transform:SetSixFaced()
        inst.AnimState:PlayAnimation("float_pre")
        inst.AnimState:PushAnimation("float_loop", true)
        inst.AnimState:OverrideSymbol("splash_wave", "player_float", "splash_wave")
        inst.AnimState:Show("float_front") --水面特效居然和人物动画一体的，而且贴图也不清晰
        inst.AnimState:Show("float_back")
        if self.toy:IsValid() then
            local cpt = self.toy.components.playerfloater
            if cpt ~= nil and cpt.onequipfn ~= nil then
                cpt.onequipfn(self.toy, inst)
            end
        end
    else
        -- inst.Transform:SetFourFaced()
        inst.AnimState:ClearOverrideSymbol("splash_wave")
        if self.toy:IsValid() then
            local cpt = self.toy.components.playerfloater
            if cpt ~= nil and cpt.onunequipfn ~= nil then
                cpt.onunequipfn(self.toy, inst)
            end
        end
    end
end

function SoakerLegion:SetSplash(nohide)
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("soak_waterspout_l_fx")
    if fx ~= nil then
        if self.istoysoaking then
            if not nohide then
                fx.AnimState:HideSymbol("fx_ripple_part") --有载具时，不显示水面条纹，不然平面高度对不上有点奇怪
            end
        else
            y = y + 0.3
        end
        fx.Transform:SetPosition(x, y, z)
    end
    self.inst.SoundEmitter:PlaySound("dontstarve/creatures/pengull/splash")
    self.inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small")
end
function SoakerLegion:JumpIn(target) --【服务器】试着浸泡，准备跳入
    local cpt = target.components.soakablelegion
    if cpt == nil then
        return
    end
    local inst = self.inst
    if inst:HasTag("upgrademoduleowner") then --机器人不防水，会拒绝泡澡。除非以后官方或者模组给机器人做防水的道具或插件
        if not inst:HasTag("moistureimmunity") then --不防水时
            if inst.sg ~= nil then inst.sg:GoToState("idle") end
            self:SayIt("REFUSE")
            return
        end
    end
    if not inst:HasTag("playermerm") and inst.components.moisture ~= nil and --沃特不受潮湿度限制
        inst.components.moisture:GetMoisturePercent() >= 0.8 --80%潮湿后就不进去了
    then
        if inst.sg ~= nil then inst.sg:GoToState("idle") end
        self:SayIt("REFUSE_WATER")
        return
    end
    local idx = {}
    for i = 1, cpt.points, 1 do
        if cpt.soakers[i] == nil or not cpt.soakers[i]:IsValid() then
            table.insert(idx, i)
        end
    end
    if idx[1] == nil then --没位置可以泡了
        if inst.sg ~= nil then
            inst.sg:GoToState("idle")
        end
        self:SayIt("NOSPACE")
        return
    else
        idx = idx[math.random(#idx)]
    end
    self.startpos = inst:GetPosition()
    self.targetpos = target:GetPosition()
    self.targetrad = target._dd_rad.base or target:GetPhysicsRadius(0)
    self.pos = cpt:OccupySpace(inst, idx)
    self.posidx = idx
    self.target = target
    if inst.sg ~= nil then
        --检查浸泡点是否是正常位置，在海上和船上是不行的
        if inst.sg.currentstate.name == "soak_l_pre" and
            TheWorld.Map:IsPassableAtPoint(self.pos.x, self.pos.y, self.pos.z, false, true)
        then
            self.animtype = 1
            self._animtype:set(1)
            self:FindAToy()
            inst.sg:GoToState("soak_l_jumpin")
            return
        else
            inst.sg:GoToState("idle")
        end
    end
    self:ResetSoaking()
    self:SayIt("REFUSE")
end
function SoakerLegion:StartSoaking() --【服务器】开始浸泡
    if self.animtype >= 3 then
        return
    end
    local inst = self.inst
    inst:ForceFacePoint(self.targetpos:Get()) --面朝中心
    self.pos = inst:GetPosition() --以实际落点为准
    if self.toy ~= nil then
        self.animtype = 4
        self:TriggerToy(true)
        self.istoysoaking = true
    else
        self.animtype = 3
        if math.random() < 0.65 then
            inst.AnimState:PlayAnimation("emote_loop_sit2", true) --这个动画最像在泡澡的样子
        else
            local anims = { "emote_loop_sit1", "emote_loop_sit3", "emote_loop_sit4" }
            inst.AnimState:PlayAnimation(anims[math.random(#anims)], true)
        end
    end
    self._animtype:set(self.animtype)
    if self.target ~= nil and self.target:IsValid() then --浸泡效果开始！
        self.target.components.soakablelegion:StartSoak(inst)
    end
end
function SoakerLegion:StopSoaking() --【服务器】停止浸泡
    if self.target ~= nil then
        if self.target:IsValid() then
            self.target.components.soakablelegion:LeaveSpace(self.posidx, self.inst) --得让池子让出位置
        end
        self.target = nil
    end
    self:TriggerToy(false)
    self.toy = nil
    self.animtype = 2
    self._animtype:set(2)
end
function SoakerLegion:ResetSoaking() --【服务器】中断、停止时，清理浸泡状态的数据
    if self.target ~= nil then
        if self.target:IsValid() then
            self.target.components.soakablelegion:LeaveSpace(self.posidx, self.inst) --得让池子让出位置
        end
        self.target = nil
    end
    self:TriggerToy(false)
    self.toy = nil
    self.istoysoaking = nil
    self.mult_health = nil
    self.mult_sanity = nil
    self.mult_moisture = nil
    self.cg_buffs = {}

    self.pos = nil
    self.posidx = nil
    self.startpos = nil
    self.targetpos = nil
    self.targetrad = nil
    self.animtype = 0
    self._animtype:set(0)
    self.times = {}
    self.talks = {}
end

function SoakerLegion:AnimTypeDirty(newv) --【客户端】浸泡动画设置
    local inst = self.inst
    if newv <= 2 then --说明是结束浸泡
        if newv ~= 1 then
            inst.AnimState:SetFloatParams(0.0, 0.0, 0.0)
            if self.fx_front ~= nil and self.fx_front:IsValid() then
                self.fx_front:Remove()
                self.fx_front = nil
            end
            if self.fx_back ~= nil and self.fx_back:IsValid() then
                self.fx_back:Remove()
                self.fx_back = nil
            end
        end
        return
    end
    if newv == 3 then
        --Tip: 第一个参数是动画切割比例。最好小于0，如果大于0，在视角放大后，动画切割比例会往上偏移，可能会露馅，虽然影响也不大
        --第三个参数可以让动画像在水里漂浮一样，上下浮动
        inst.AnimState:SetFloatParams(0.18, 1.0, 1)

        local fx = SpawnPrefab("float_front_l_fx")
        fx.entity:SetParent(inst.entity)
        fx.Transform:SetScale(0.65, 0.65, 0.65)
        fx.Transform:SetPosition(0, 0.5, 0)
        self.fx_front = fx
        fx = SpawnPrefab("float_back_l_fx")
        fx.entity:SetParent(inst.entity)
        fx.Transform:SetScale(0.65, 0.65, 0.65)
        fx.Transform:SetPosition(0, 0.5, 0)
        self.fx_back = fx
    end

    --可能是服务器的 soak_l_jumpin 有 nopredict 标签，所以会导致很快离开 soak_l。因此这里再次触发一次！
    if TheNet:GetIsClient() and inst.sg ~= nil and inst.sg.currentstate.name ~= "soak_l" and
        not inst:HasTag("playerghost")
    then
        inst.sg:GoToState("soak_l")
    end
end

return SoakerLegion

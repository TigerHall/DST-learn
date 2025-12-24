local function OnReroll(inst) --重选人物时，解除契约
    local cpt = inst.components.soulbookowner
    if cpt ~= nil and cpt.book ~= nil and cpt.book:IsValid() then
        cpt:DoTerminate(cpt.book)
    end
end
local function OnRemove(inst) --玩家实体消失时，删除契约
    local cpt = inst.components.soulbookowner
    if cpt ~= nil and cpt.book ~= nil and cpt.book:IsValid() and not cpt.book.legiontag_deleting then
        if cpt._book_listen ~= nil then
            inst:RemoveEventCallback("onremove", cpt._onbookremove, cpt._book_listen)
            cpt._book_listen = nil
        end
        cpt.book:Remove()
    end
end
local function OnDespawn(inst) --玩家上下线时，契约跟着消失
    local cpt = inst.components.soulbookowner
    if cpt ~= nil then
        if cpt.task_spawnbook ~= nil then --也就预防一下，真不至于这么巧合
            cpt.task_spawnbook:Cancel()
            cpt.task_spawnbook = nil
        end
        if cpt.book ~= nil and cpt.book:IsValid() then
            if cpt._book_listen ~= nil then
                inst:RemoveEventCallback("onremove", cpt._onbookremove, cpt._book_listen)
                cpt._book_listen = nil
            end
            local fx = SpawnPrefab("spawn_fx_small")
            fx.entity:SetParent(cpt.book.entity)
            cpt.book.legiontag_deleting = true
            cpt.book.components.colourtweener:StartTween({ 0, 0, 0, 1 }, 13*FRAMES, cpt.book.Remove)
        end
    end
end
local function OnBookRemove(self, book)
    if self.book == nil or book == self.book then --如果自己没有签订，却触发了这里。说明哪里不正常，不过也无所谓，继续运行
        if self.task_spawnbook == nil then
            self.bookcache = book:GetMyData() --不知道契约在被移除时，还能不能得到正确的数据
            self.task_spawnbook = self.inst:DoTaskInTime(1, function()
                self.task_spawnbook = nil
                self:SpawnBook()
            end)
        end
    end
end
local function OnMurdered(inst, data)
    local cpt = inst.components.soulbookowner
    if cpt ~= nil and cpt.book ~= nil and cpt.book:IsValid() and not cpt.book.legiontag_deleting then
        cpt.book:OnMurdered(inst, data)
    end
end
local function OnHarvestTrapSouls(inst, data) --可能会和勋章重复刷出魂，因为没有限制只触发一次的机制。不管了，问题不大
    if (data.numsouls or 0) > 0 then
        local cpt = inst.components.soulbookowner
        if cpt ~= nil and cpt.book ~= nil and cpt.book:IsValid() and not cpt.book.legiontag_deleting then
            cpt.book:AddSouls(data.numsouls)
            data.numsouls = 0 --设置为0，这样别的地方就不会触发了吧
        end
    end
end

local SoulBookOwner = Class(function(self, inst)
    self.inst = inst
    -- self.book = nil
    -- self.bookcache = nil
    -- self.task_spawnbook = nil
    -- self._self_listen = nil
    -- self._book_listen = nil
    self._onbookremove = function(bk)
        OnBookRemove(self, bk)
    end
end, nil, {
    -- staying = onstaying
})

local function SayIt(inst, key)
    if inst.components.talker ~= nil then
        inst.components.talker:Say(GetString(inst, "DESCRIBE", { "SOUL_CONTRACTS", key }))
    end
end

function SoulBookOwner:DoSign(book) --签订
    self.book = book
    book:SetBookOwner(self.inst)
    if self._book_listen == nil then
        self._book_listen = book
        self.inst:ListenForEvent("onremove", self._onbookremove, book)
    elseif self._book_listen ~= book then
        self.inst:RemoveEventCallback("onremove", self._onbookremove, self._book_listen)
        self._book_listen = book
        self.inst:ListenForEvent("onremove", self._onbookremove, book)
    end
    if not self._self_listen then --没有契约时就不监听，不做无用功，这也算是一种优化吧
        self._self_listen = true
        self.inst:ListenForEvent("ms_playerreroll", OnReroll) --玩家重选人物时。比"player_despawn"事件先触发
        self.inst:ListenForEvent("player_despawn", OnDespawn) --玩家上下线、上下洞穴时。比"onremove"事件先触发
        self.inst:ListenForEvent("onremove", OnRemove) --玩家实体消失时
        self.inst:ListenForEvent("murdered", OnMurdered) --玩家杀死物品栏的生物时
        if not self.inst:HasTag("soulstealer") then --小恶魔不需要这个监听
            self.inst:ListenForEvent("harvesttrapsouls", OnHarvestTrapSouls) --玩家从陷阱里取出会死亡的猎物时
        end
    end
end
function SoulBookOwner:DoTerminate(book) --解除
    self.book = nil
    self.bookcache = nil
    book:SetBookOwner(nil)
    if self._book_listen ~= nil then
        self.inst:RemoveEventCallback("onremove", self._onbookremove, self._book_listen)
        self._book_listen = nil
    end
    if self._self_listen then
        self._self_listen = nil
        self.inst:RemoveEventCallback("ms_playerreroll", OnReroll)
        self.inst:RemoveEventCallback("player_despawn", OnDespawn)
        self.inst:RemoveEventCallback("onremove", OnRemove)
        self.inst:RemoveEventCallback("murdered", OnMurdered)
        self.inst:RemoveEventCallback("harvesttrapsouls", OnHarvestTrapSouls)
    end
end
function SoulBookOwner:TrySign(book) --签订/解除契约
    if self.task_spawnbook ~= nil then --有契约正在重生
        SayIt(self.inst, "WRONG")
        return
    end
    local oldowner = book._owner_s
    if oldowner == nil then --可以签订
        if self.book ~= nil and self.book:IsValid() then --先把旧的契约解除了
            self:DoTerminate(self.book)
        end
        self:DoSign(book)
        -- self.bookcache = book:GetMyData() --记录数据
        SayIt(self.inst, "SIGN")
    elseif oldowner == self.inst or self.book == book then --可以解除
        --要是两个契约的签订者是同一个玩家，那就得两本契约都去除。不过按理来说这个情况不会有的
        if self.book ~= nil and self.book ~= book and self.book:IsValid() then
            self:DoTerminate(self.book)
        end
        self:DoTerminate(book)
        SayIt(oldowner, "TERMINATE")
    else --按理来说这里不会触发。一个契约只能同时一个人使用，签订后的契约只会是签订者才能用
        SayIt(self.inst, "WRONG")
        book._updatespells:push() --肯定是哪里出问题了，关闭界面再刷新按钮，来冷静一下
        book.UpdateBtns(book, self.inst)
        return
    end
    local fx = SpawnPrefab(book._dd and book._dd.healfx or "soulheal_l_fx")
    fx.Transform:SetPosition(book.Transform:GetWorldPosition())
    book.SoundEmitter:PlaySound("meta5/abigail/gestalt_abigail_dashattack_hit")
    book.SoundEmitter:PlaySound("meta5/abigail/gestalt_abigail_dashattack_pst")

    local cpt = self.inst.components.sanity
    if cpt ~= nil then
        local need
        if cpt.current < 100 then
            need = 100 - cpt.current
        end
        cpt:DoDelta(-100)
        if need ~= nil and not self.inst:HasTag("playerghost") then --精神值不足会扣血
            cpt = self.inst.components.health
            if cpt ~= nil and not cpt:IsDead() then
                cpt:DoDelta(-need, nil, book.prefab)
            end
        end
    end
end

local function GetCalculatedPos(x, y, z, radius, theta)
    local rad = radius or math.random() * 3
    local the = theta or math.random() * 2 * PI
    return x + rad * math.cos(the), y, z - rad * math.sin(the)
end
function SoulBookOwner:SpawnBook() --生成契约
    local data = self.bookcache
    local book = SpawnPrefab("soul_contracts", data and data.skin or nil)
    if book ~= nil then
        local xx, yy, zz = self.inst.Transform:GetWorldPosition()
        local x, y, z = GetCalculatedPos(xx, yy, zz, 2+math.random()*6, nil)
        book:SetMyData(data)
        book.Transform:SetPosition(x, y, z)
        self:DoSign(book)
        -- book.AnimState:SetMultColour(0,0,0,1)
        book.components.colourtweener:StartTween({1,1,1,1}, 19*FRAMES)
        local fx = SpawnPrefab("spawn_fx_small")
        fx.entity:SetParent(book.entity)
    end
end

local function IsValidOwner(inst)
    return not inst:HasTag("playerghost") and inst.components.inventory and
        inst.components.health and not inst.components.health:IsDead()
end
function SoulBookOwner:Souls2Player(book) --提取灵魂
    if (book._owner_s ~= nil and book._owner_s ~= self.inst) or not IsValidOwner(self.inst) then
        SayIt(self.inst, "NOTMINE")
        return
    end
    local num = book._soulnum
    if num < 1 then
        SayIt(self.inst, "SOULLESS")
        return
    end
    local soulnum, hasemptyslot, souls = book.GetOwnerSoulInfo(self.inst)
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
        book._soulnum = num
        local soul = SpawnPrefab("wortox_soul")
        if soulnum > 1 and soul.components.stackable ~= nil then
            soul.components.stackable:SetStackSize(soulnum)
        end
        self.inst.components.inventory:GiveItem(soul, nil, self.inst:GetPosition())
        book.SetSoulFx(book, self.inst)
    else
        book._soulnum = num - 1
        local pos = self.inst:GetPosition()
        local fx = SpawnPrefab(book._dd and book._dd.bookhealfx or "soulbook_l_fx")
        fx.Transform:SetPosition(pos:Get())
        book:DoHeal(1, pos) --以玩家为中心释放灵魂
    end
end
function SoulBookOwner:Souls2Book(book) --存储灵魂
    if not IsValidOwner(self.inst) then
        SayIt(self.inst, "NOTMINE")
        return
    end
    local num = book._soulnum
    local soulnum, hasemptyslot, souls = book.GetOwnerSoulInfo(self.inst)
    if soulnum < 1 then
        SayIt(self.inst, "OWNERSOULLESS")
        return
    end
    if num < book._soullvl then
        local need = book._soullvl - num
        if need >= soulnum then
            book._soulnum = num + soulnum
            for _, v in ipairs(souls) do --移除全部灵魂
                v:Remove()
            end
        else
            book._soulnum = book._soullvl
            for _, v in ipairs(souls) do --移除 need 数量的灵魂
                if v.components.stackable ~= nil then
                    local stack = v.components.stackable:StackSize()
                    if stack <= need then
                        v:Remove()
                        need = need - stack
                    else
                        v.components.stackable:Get(need):Remove()
                        need = 0
                    end
                else
                    v:Remove()
                    need = need - 1
                end
                if need < 1 then
                    break
                end
            end
        end
        if not book:IsAsleep() then
            book.SetSoulFx(book, book)
        end
    else
        for _, v in ipairs(souls) do --移除玩家手里的一个灵魂
            if v.components.stackable ~= nil then
                v.components.stackable:Get(1):Remove()
            else
                v:Remove()
            end
            break
        end
        local pos = self.inst:GetPosition()
        local fx = SpawnPrefab(book._dd and book._dd.bookhealfx or "soulbook_l_fx")
        fx.Transform:SetPosition(pos:Get())
        book:DoHeal(1, pos) --以玩家为中心释放灵魂
    end
end

function SoulBookOwner:ShareSouls(book) --分享灵魂
    if self.book == nil or self.book ~= book then
        SayIt(self.inst, "NOTMINE")
        return
    end
    if book._soulnum < 1 then
        SayIt(self.inst, "SOULLESS")
        return
    end
    book._needsharesoul = true
    book:PushEvent("trytosharesouls")
end
function SoulBookOwner:ShareLevel(book) --分享等级
    if self.book == nil or self.book ~= book then
        SayIt(self.inst, "NOTMINE")
        return
    end
    book._needsharelvl = true
    book:PushEvent("trytosharelvls")
end

function SoulBookOwner:FollowMe(book) --原地停留/跟随
    if self.book == nil or self.book ~= book then
        SayIt(self.inst, "NOTMINE")
        return
    end
    if book:HasTag("bookstay_l") then
        book:RemoveTag("bookstay_l")
    else
        book:AddTag("bookstay_l")
        book:PushEvent("trytostay")
    end
    book._updatespells:push()
    book.UpdateBtns(book, book._user_l:value())
end

function SoulBookOwner:LifeInsure(book) --生命保险的开启与关闭
    if book._owner_s == nil or book._owner_s ~= self.inst then
        SayIt(self.inst, "NOTMINE")
        return
    end
    if book:HasTag("lifeinsure_l") then
        book:RemoveTag("lifeinsure_l")
        book.SetLifeInsure(book, false)
    else
        book:AddTag("lifeinsure_l")
        book.SetLifeInsure(book, true)
    end
    book._updatespells:push()
    book.UpdateBtns(book, book._user_l:value())
end

function SoulBookOwner:OnSave()
    local data = {}
    if self.book ~= nil and self.book:IsValid() then
        data.book = self.book:GetMyData()
    elseif self.bookcache ~= nil then
        data.book = self.bookcache
    end
    return data
end
function SoulBookOwner:OnLoad(data, newents)
    if data == nil or data.book == nil then
        return
    end
    self.bookcache = data.book
    if self.task_spawnbook == nil then
        self.task_spawnbook = self.inst:DoTaskInTime(0.5+math.random(), function()
            self.task_spawnbook = nil
            self:SpawnBook()
        end)
    end
end

return SoulBookOwner

--[[
标签扩展：
    集五年一班多位大佬讨论总结得出，通过额外的实体对象来存储额外的标签

标签扩展尝试记录：
1. 使用net_bool记录标签，但是需要提前写好需要扩展的标签名
2. 使用net_string通信，向客机传递标签更改信息，并且每次标签改动延迟一两帧再发送，标签数量无上限，但是刚加载游戏时可能会漏掉几个标签，概率发生
3. 使用rpc通信替代net_string，比net_string更快一点，但是前者的问题还是没有解决
4. 使用额外的对象记录标签，需要提前指定需要的标签数量上限


1. net_entity变量在标签对象身上，也就像标签对象来完成客机的初始化，就不用考虑玩家身上限制几个net_entity变量了
2. 主机的标签对象自动扩容，不过不会自动简缩，标签对象只会多不会少，不过重上游戏会重新生成的

使用方法：
1. 修改xx_extend_tags.lua和xx_tagent.lua文件前缀，为自己mod前缀
2. modmain中引入xx_extend_tags.lua文件

]]

--key值，如果ONLY_MOD_TAGS为true则这个应该是拦截标签的前缀
local pre = debug.getinfo(1, 'S').source:match("([^/]+)extend_tags%.lua$") --当前文件前缀

--是否只拦截自己mod的标签，如果为false则拦截玩家绝大部分标签
local ONLY_MOD_TAGS = false

----------------------------------------------------------------------------------------------------
local MAX_COUNT = 63
local TAG_ENTS = pre .. "tagents"
-- tt_tagent对象的固有标签，排除掉
local EXCLUDE_TAGS = {
    DECOR = true,
    NOCLICK = true,
    [pre .. "tagent"] = true,

    --state会添加的标签，这些标签留不留都可以，从EXCLUDE_TAGS中去掉也行
    attack = true,
    autopredict = true,
    busy = true,
    dirt = true,
    doing = true,
    fishing = true,
    flight = true,
    hiding = true,
    idle = true,
    invisible = true,
    lure = true,
    moving = true,
    nibble = true,
    noattack = true,
    nopredict = true,
    pausepredict = true,
    sleeping = true,
    working = true,
    boathopping = true,
}

table.insert(PrefabFiles, pre .. "extend_tags")

local function processplayertags(inst)
    if inst[TAG_ENTS] then return end
    inst[TAG_ENTS] = {}

    if TheWorld.ismastersim then
        -- 先加一个实体，不够了再创建
        local ent = SpawnPrefab(pre .. "extend_tags")
        ent:Setup(inst)
        table.insert(inst[TAG_ENTS], ent)
    end

    local OldAddTag = inst.AddTag
    inst.AddTag = function(inst, tag, ...)
        tag = tag and string.lower(tag)
        if tag
            and not EXCLUDE_TAGS[tag]
            and string.byte(tag, 1, 1) ~= 95                      --不处理组件副件，即下划线开头的标签
            and (not ONLY_MOD_TAGS or string.find(tag, pre) == 1) --只处理mod标签
            and not inst:HasTag(tag)                              --已经有了
        then
            -- print("添加标签", inst, tag)
            local newents = {}

            local has = false
            for _, ent in ipairs(inst[TAG_ENTS]) do
                if ent:IsValid() then
                    if ent.tag_count < MAX_COUNT then
                        has = true
                        ent.tag_count = ent.tag_count + 1
                        ent:AddTag(tag, ...)
                    end
                    table.insert(newents, ent)
                end
            end
            if not has then
                -- print("标签扩容")
                -- 扩容
                local ent = SpawnPrefab(pre .. "extend_tags")
                ent:Setup(inst)
                ent:AddTag(tag, ...)
                table.insert(newents, ent)
            end
            inst[TAG_ENTS] = newents
            return
        end

        return OldAddTag(inst, tag, ...)
    end

    local OldRemoveTag = inst.RemoveTag
    inst.RemoveTag = function(inst, tag, ...)
        if tag and not EXCLUDE_TAGS[tag] then
            for _, ent in ipairs(inst[TAG_ENTS]) do
                if ent:IsValid() then
                    if ent:HasTag(tag, ...) then
                        ent.tag_count = ent.tag_count - 1
                    end
                    ent:RemoveTag(tag, ...)
                end
            end
        end
        return OldRemoveTag(inst, tag, ...)
    end

    inst.AddOrRemoveTag = function(inst, tag, condition)
        if condition then
            inst:AddTag(tag)
        else
            inst:RemoveTag(tag)
        end
    end

    local OldHasTag = inst.HasTag
    inst.HasTag = function(inst, tag, ...)
        if tag and not EXCLUDE_TAGS[tag] then
            for _, ent in ipairs(inst[TAG_ENTS]) do
                if ent:IsValid() then
                    if ent:HasTag(tag, ...) then
                        return true
                    end
                end
            end
        end

        return OldHasTag(inst, tag, ...)
    end

    inst.HasTags = function(inst, ...)
        local tags = select(1, ...)
        for _, v in ipairs(type(tags) == "table" and tags or { ... }) do
            if not inst:HasTag(v) then return false end
        end
        return true
    end

    inst.HasAllTags = inst.HasTags

    inst.HasOneOfTags = function(inst, ...)
        local tags = select(1, ...)
        for _, v in ipairs(type(tags) == "table" and tags or { ... }) do
            if inst:HasTag(v) then --如果是表里套表，保持崩溃，因为原版也会崩溃
                return true
            end
        end
        return false
    end

    inst.HasAnyTag = inst.HasOneOfTags
end

-- local function processplayer(world, inst) if inst and inst:HasTag("player") then processplayertags(inst) end end
-- AddPrefabPostInit("world", function(inst) inst:ListenForEvent("entity_spawned", processplayer) end)

AddPlayerPostInit(processplayertags)

----------------------------------------------------------------------------------------------------

-- 标签对象不能被AddPrefabPostInitAny初始化

local OldAddPrefabPostInitAny = env.AddPrefabPostInitAny
env.AddPrefabPostInitAny = function(fn)
    local newfn = function(inst)
        if not inst:HasTag(pre .. "tagent") then return fn(inst) end
    end
    return OldAddPrefabPostInitAny(newfn)
end

local PrefabPostInitAny = {}
for _, fn in ipairs(env.postinitfns.PrefabPostInitAny or {}) do
    local newfn = function(inst)
        if not inst:HasTag(pre .. "tagent") then return fn(inst) end
    end
    table.insert(PrefabPostInitAny, newfn)
end
env.postinitfns.PrefabPostInitAny = PrefabPostInitAny

----------------------------------------------------------------------------------------------------
-- 检查一下参数，有些mod不规范，比如永不妥协，表里套表或者单纯一个字符串什么的
local function CheckTagTable(tags)
    if not tags then return end

    local res = {}
    if type(tags) == "table" then
        for _, v in ipairs(tags) do
            if type(v) == "string" then
                table.insert(res, v)
            end
        end
        return res
    elseif type(tags) == "string" then
        table.insert(res, tags)
        return res
    end
end

--全部查找并且自己标签判断，可能有点儿效率问题，感觉加了游戏会变卡，但又不得不覆盖
local OldFindEntities = getmetatable(TheSim).__index["FindEntities"]
getmetatable(TheSim).__index["FindEntities"] = function(self, x, y, z, radius, mustTags, cantTags, oneOfTags)
    mustTags = CheckTagTable(mustTags)
    cantTags = CheckTagTable(cantTags)
    oneOfTags = CheckTagTable(oneOfTags)

    local newCantTags = cantTags and shallowcopy(cantTags) or {}
    local cant_player = table.contains(newCantTags, "player")
    if not cant_player then
        table.insert(newCantTags, "player")
    end
    if not table.contains(newCantTags, pre .. "tagent") then
        table.insert(newCantTags, pre .. "tagent")
    end
    local ents = OldFindEntities(self, x, y, z, radius, mustTags, newCantTags, oneOfTags) --如果有mod少参数导致这里报错了，不处理

    if not cant_player then               --把玩家加上
        local dissq = radius * radius
        for _, v in ipairs(AllPlayers) do --严格来说AllPlayers和player标签不能画等号，不兼容生成玩家对象但是从AllPlayers中移除的mod
            if v:GetDistanceSqToPoint(x, y, z) <= dissq
                and (not mustTags or v:HasTags(mustTags))
                and (not cantTags or not v:HasOneOfTags(cantTags))
                and (not oneOfTags or v:HasOneOfTags(oneOfTags))
            then
                table.insert(ents, v)
            end
        end
    end

    return ents
end


----------------------------------------------------------------------------------------------------

AddPrefabPostInit("inventoryitem_classified", function(inst)
    --新增一个网络变量来记录标签的字符串值
    inst[pre .. "equiprestrictedtag"] = net_string(inst.GUID, "equippable. " .. pre .. "restrictedtag")
    inst[pre .. "deployrestrictedtag"] = net_string(inst.GUID, "deployable." .. pre .. "restrictedtag")
end)

AddClassPostConstruct("components/inventoryitem_replica", function(self)
    local OldSetEquipRestrictedTag = self.SetEquipRestrictedTag
    self.SetEquipRestrictedTag = function(self, restrictedtag, ...)
        self.classified[pre .. "equiprestrictedtag"]:set_local(restrictedtag or "")
        self.classified[pre .. "equiprestrictedtag"]:set(restrictedtag or "")
        return OldSetEquipRestrictedTag(self, restrictedtag, ...)
    end

    --- 把原来的散列值替换成字符串，不知道有没有什么问题
    function self:GetEquipRestrictedTag()
        if self.inst.components.equippable ~= nil then
            return self.inst.components.equippable.restrictedtag
        end
        -- ###
        return self.classified ~= nil
            and self.classified[pre .. "equiprestrictedtag"]:value() ~= ""
            and self.classified[pre .. "equiprestrictedtag"]:value()
            or nil
    end

    local OldSetDeployRestrictedTag = self.SetDeployRestrictedTag
    self.SetDeployRestrictedTag = function(self, restrictedtag, ...)
        self.classified[pre .. "deployrestrictedtag"]:set_local(restrictedtag or "")
        self.classified[pre .. "deployrestrictedtag"]:set(restrictedtag or "")
        return OldSetDeployRestrictedTag(self, restrictedtag, ...)
    end

    function self:IsDeployable(deployer)
        if self.inst.components.deployable ~= nil then
            return self.inst.components.deployable:IsDeployable(deployer)
        elseif self.classified == nil or self.classified.deploymode:value() == DEPLOYMODE.NONE then
            return false
        end
        -- ###
        -- local restrictedtag = self.classified.deployrestrictedtag:value()
        -- if restrictedtag and restrictedtag ~= 0 and not (deployer and deployer:HasTag(restrictedtag)) then
        --     return false
        -- end
        local restrictedtag = self.classified[pre .. "deployrestrictedtag"]:value()
        if restrictedtag and restrictedtag ~= "" and not (deployer and deployer:HasTag(restrictedtag)) then
            return false
        end
        local rider = deployer and deployer.replica.rider or nil
        if rider and rider:IsRiding() then
            --can only deploy tossables while mounted
            return self.inst:HasTag("projectile")
        end
        return true
    end
end)

local pre = debug.getinfo(1, 'S').source:match("([^/]+)extend_tags%.lua$") --当前文件前缀
local TAG_ENTS = pre .. "tagents"

local function OnSetPlayer(inst)
    local player = inst.player:value()
    if player then
        if not table.contains(player[TAG_ENTS], inst) then
            -- print("客机绑定")
            table.insert(player[TAG_ENTS], inst)
        end
    end
end

-- 主客机都可能调用
local function Setup(inst, player)
    -- print("初始化", TheWorld.ismastersim, player)
    player:AddChild(inst)
    inst.Transform:SetPosition(0, 0, 0)
    inst:ListenForEvent("onremove", function() inst:Remove() end, player)

    inst:DoTaskInTime(0, function() --需要延迟一下再绑定，尤其是在游戏刚加载的时候
        inst.player:set_local(player)
        inst.player:set(player)
    end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    inst.entity:Hide()

    inst:AddTag("DECOR")
    inst:AddTag("NOCLICK")
    inst:AddTag(pre .. "tagent")

    inst.player = net_entity(inst.GUID, pre .. "extend_tags.player", "playertagdirty") --让对象反过来记录玩家，就不需要提前写标签数量上限了
    inst.tag_count = 63 - 50                                                           --以防万一，按照初始13个标签计算，这个值只对主机生效
    inst.Setup = Setup

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("playertagdirty", OnSetPlayer)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then return inst end

    inst.persists = false

    return inst
end

--[[
该预制件要求：
1. 不能被FindEntities搜索到
2. 不能被AddPrefabPostInitAny初始化
]]
return Prefab(pre .. "extend_tags", fn)

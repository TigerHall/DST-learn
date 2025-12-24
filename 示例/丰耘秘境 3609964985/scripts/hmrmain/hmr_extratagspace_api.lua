---------------------------------------------------------------------------------------------------------------------
------------------这个文件出自风铃草大佬之手,感谢风铃草大佬~--------------------------------
---------------------------------------------------------------------------------------------------------------------
-- 这种方式对FindEntity等地方的调用无效,仅适用于解锁配方、标签判断等比较常规的场景
local Tags = {}--强制覆盖原标签及对应方法
local Hash_To_Tags = {}
local key = "CN"

if TUNING.MoreTagsReg == nil then
    TUNING.MoreTagsReg = {}
end
function RegTag(tag)
    tag = string.lower(tag)
    if not TUNING.MoreTagsReg[tag] then
        TUNING.MoreTagsReg[tag] = key
        Tags[tag] = true
        Hash_To_Tags[hash(tag)] = tag
    end
end

--------------------原版标签--------------------
local dst_tags = {
    --威屌技能树
    -- "alchemist",
    -- "gem_alchemistI",
    -- "gem_alchemistII",
    -- "gem_alchemistIII",
    -- "ore_alchemistI",
    -- "ore_alchemistII",
    -- "ore_alchemistIII",
    -- "ick_alchemistI",
    -- "ick_alchemistII",
    -- "ick_alchemistIII",
    -- "skill_wilson_allegiance_shadow",
    -- "skill_wilson_allegiance_lunar",
    --火女技能树
    "controlled_burner",
    "ember_master",
    --植物人技能树
    "farmplantidentifier",
    -- "saplingcrafter",
    -- "berrybushcrafter",
    -- "juicyberrybushcrafter",
    -- "reedscrafter",
    -- "lureplantcrafter",
    -- "syrupcrafter",
    -- "lunarplant_husk_crafter",
    "farmplantfastpicker",
    -- "carratcrafter",
    -- "lightfliercrafter",
    -- "fruitdragoncrafter",
    --大力士技能树
    "wolfgang_coach",
    -- "wolfgang_dumbbell_crafting",
    "wolfgang_overbuff_1",
    "wolfgang_overbuff_2",
    "wolfgang_overbuff_3",
    "wolfgang_overbuff_4",
    "wolfgang_overbuff_5",
    --伍迪技能树
    "toughworker",
    "weremoosecombo",
    --女工技能树
    "portableengineer",
    -- "charliet1maker",
    -- "wagstafft1maker",
    -- "wagstafft2maker",
    --女武神技能树
    -- "battlesongshadowalignedmaker",
    -- "battlesonglunaralignedmaker",
    --小鱼妹技能树
    -- "mosquitocraft_1",
    -- "mosquitocraft_2",
    -- "merm_swampmaster_fertilizer",--根本没用到
    -- "merm_swampmaster_offeringpot",
    -- "merm_swampmaster_offeringpot_upgraded",
    -- "merm_swampmaster_mermtoolshed",
    -- "merm_swampmaster_mermtoolshed_upgraded",
    -- "merm_swampmaster_mermarmory",
    -- "merm_swampmaster_mermarmory_upgraded",
    -- "wurt_shadow_spelluser",
    -- "wurt_lunar_spelluser",
    -- "shadow_swamp_bomb_spelluser",
    -- "lunar_swamp_bomb_spelluser",
    --公共
    "player_shadow_aligned",--暗影阵营玩家
    "player_lunar_aligned",--月亮阵营玩家

    "masterchef",
    "professionalchef",
    "expertchef",
    "handyperson",
    "basicengineer",
    "portableengineer",
    "remotecontrol",
    "engineering",
    "engineeringbatterypowered",
    "fastbuilder",
    "bookbuilder",
    "valkyrie",
    "battlesinger",
    "plantkin",
    "scientist",
    "spiderwhisperer",
    UPGRADETYPES.SPIDER.."_upgradeuser",
}
for _,v in ipairs(dst_tags) do
    RegTag(v)
end

-------------------------------------------------------相关方法-------------------------------------------------------
local function AddTag(inst, stag, ...)
    if not inst or not stag then return end
    local tag = type(stag)=="number" and Hash_To_Tags[stag] or string.lower(stag)--如果是哈希值则从哈希值转回字母tag
    if Tags[tag] then
        if inst[key].Tags and inst[key].Tags[tag] then
            inst[key].Tags[tag]:set_local(false)
            inst[key].Tags[tag]:set(true)
        end
    else
        return inst[key].AddTag(inst, stag, ...)
    end
end

local function RemoveTag(inst, stag, ...)
    if not inst or not stag then return end
    local tag = type(stag)=="number" and Hash_To_Tags[stag] or string.lower(stag)--如果是哈希值则从哈希值转回字母tag
    if Tags[tag] then
        if inst[key].Tags and inst[key].Tags[tag] then
            inst[key].Tags[tag]:set_local(true)
            inst[key].Tags[tag]:set(false)
        end
    else
        return inst[key].RemoveTag(inst, stag, ...)
    end
end

local function HasTag(inst, stag, ...)
    if not inst or not stag then return end
    local tag = type(stag)=="number" and Hash_To_Tags[stag] or string.lower(stag)--如果是哈希值则从哈希值转回字母tag
    if Tags[tag] and inst[key].Tags and inst[key].Tags[tag] then
        return inst[key].Tags[tag]:value()
    else
        return inst[key].HasTag(inst, stag, ...)
    end
end

local function HasTags(inst,...)
    local tags = select(1, ...)
    if type(tags) ~= "table" then
        tags = {...}
    end
    for _,v in ipairs(tags) do
        if not HasTag(inst, v) then return false end
    end
    return true
end

local function HasOneOfTags(inst,...)
    local tags = select(1, ...)
    if type(tags) ~= "table" then
        tags = {...}
    end
    for _,v in ipairs(tags) do
        if HasTag(inst, v) then return true end
    end
    return false
end

local function AddOrRemoveTag(inst,stag,condition,...)
    if not inst or not stag then return end
    local ltag = type(stag)=="number" and Hash_To_Tags[stag] or string.lower(stag)--如果是哈希值则从哈希值转回字母tag
    if Tags[ltag] then 
        if condition then 
            AddTag(inst,ltag,...)
        else
            RemoveTag(inst,ltag,...)
        end
    else
        return inst[key].AddOrRemoveTag(inst,stag,condition,...)
    end
end

function FixTag(inst) -- 传入实体 主客机一起调用
    inst[key] = {
        AddTag = inst.AddTag,
        HasTag = inst.HasTag,
        RemoveTag = inst.RemoveTag,
        HasTags = inst.HasTags,
        HasOneOfTags = inst.HasOneOfTags,
        AddOrRemoveTag = inst.AddOrRemoveTag,
        Tags = {}
    }
    inst.AddTag = AddTag
    inst.HasTag = HasTag
    inst.RemoveTag = RemoveTag
    inst.HasTags = HasTags
    inst.HasOneOfTags = HasOneOfTags
    inst.HasAllTags = HasTags
    inst.HasAnyTag = HasOneOfTags
    inst.AddOrRemoveTag = AddOrRemoveTag

    for k, _ in pairs(Tags) do
        inst[key].Tags[k] = net_bool(inst.GUID, key .. "." .. k, GUID, key .. "." .. k .. "dirty")
        if inst[key].HasTag(inst, k) then
            inst[key].RemoveTag(inst, k)
            inst[key].Tags[k]:set_local(false)
            inst[key].Tags[k]:set(true)
        else
            inst[key].Tags[k]:set(false)
        end
    end

end

AddPlayerPostInit(function(inst) -- 默认只扩展人物的
    FixTag(inst)
end)
local function item_use_to_test_fn(inst, target, doer, right_click)
    if (target.replica.health or target.replica._.health) and not target:HasTag("player") then
        return true
    end
end
local function item_use_to_active_fn(inst, target, doer)
    -----------------------------------------------------------------------------------------------------
    --- 物品消耗
    inst.components.stackable:Get():Remove()
    -----------------------------------------------------------------------------------------------------
    ---
    if target.components.health then
        local debuff_prefab = "tbat_cure_buff"
        target:AddDebuff(debuff_prefab, debuff_prefab)
        target.components.health:DoDelta(100)
    end
    -----------------------------------------------------------------------------------------------------
    return true
end
local function item_use_to_com_replica_init(inst, replica_com)
    replica_com:SetTestFn(item_use_to_test_fn)
    replica_com:SetText("tbat_item_peach_blossom_pact_potion", STRINGS.ACTIONS.HEAL.GENERIC)
    replica_com:SetDistance(1)
    replica_com:SetSGAction("give")
end

local wlist = require "util/weighted_list"
local bufflist = {
    tbat_kill_get_drop = 3,
    tbat_make_half = 3,
    tbat_double_drop = 3,
    tbat_one_shot = 3,
    tbat_double_collect = 43,
    tbat_food_double_recover = 43,
}
local bufflist2 = {
    tbat_kill_get_drop2 = 3,
    tbat_make_half2 = 3,
    tbat_double_drop2 = 3,
    tbat_one_shot2 = 3,
    tbat_double_collect2 = 43,
    tbat_food_double_recover2 = 43,
}
local luckybufflist = wlist(bufflist2)
local potions = {
    {
        name = "tbat_item_failed_potion",
        build = "tbat_item_failed_potion",
        bank = "tbat_item_failed_potion",
        atlasName = "tbat_item_failed_potion",
        imageName = "tbat_item_failed_potion",
        stackableSize = TUNING.STACK_SIZE_SMALLITEM,
        oneatenfn = function(inst, eater)
            if eater:HasTag("player") and eater.components.playercontroller then
                eater:AddDebuff("tbat_fail_buff", "tbat_fail_buff")
            end
        end,
    },
    {
        name = "tbat_item_wish_note_potion",
        build = "tbat_item_wish_note_potion",
        bank = "tbat_item_wish_note_potion",
        atlasName = "tbat_item_wish_note_potion",
        imageName = "tbat_item_wish_note_potion",
        stackableSize = TUNING.STACK_SIZE_SMALLITEM,
        oneatenfn = function(inst, eater)
            if eater:HasTag("player") and eater.components.playercontroller then
                eater:AddDebuff("tbat_wishnote_buff", "tbat_wishnote_buff")
            end
        end,
    },
    {
        name = "tbat_item_veil_of_knowledge_potion",
        build = "tbat_item_veil_of_knowledge_potion",
        bank = "tbat_item_veil_of_knowledge_potion",
        atlasName = "tbat_item_veil_of_knowledge_potion",
        imageName = "tbat_item_veil_of_knowledge_potion",
        stackableSize = TUNING.STACK_SIZE_SMALLITEM,
        oneatenfn = function(inst, eater)
            if eater:HasTag("player") and eater.components.playercontroller then
                eater:AddDebuff("tbat_knowledge_buff", "tbat_knowledge_buff")
            end
        end,
    },
    {
        name = "tbat_item_oath_of_courage_potion",
        build = "tbat_item_oath_of_courage_potion",
        bank = "tbat_item_oath_of_courage_potion",
        atlasName = "tbat_item_oath_of_courage_potion",
        imageName = "tbat_item_oath_of_courage_potion",
        stackableSize = TUNING.STACK_SIZE_SMALLITEM,
        oneatenfn = function(inst, eater)
            if eater:HasTag("player") and eater.components.playercontroller then
                eater:AddDebuff("tbat_courage_buff", "tbat_courage_buff")
            end
        end,
    },
    {
        name = "tbat_item_lucky_words_potion",
        build = "tbat_item_lucky_words_potion",
        bank = "tbat_item_lucky_words_potion",
        atlasName = "tbat_item_lucky_words_potion",
        imageName = "tbat_item_lucky_words_potion",
        stackableSize = TUNING.STACK_SIZE_SMALLITEM,
        oneatenfn = function(inst, eater)
            if eater:HasTag("player") and eater.components.playercontroller then
                -- 这六个buff不能叠加，先清buff
                for k, v in pairs(bufflist) do
                    if eater:HasDebuff(k) then
                        eater:RemoveDebuff(k)
                    end
                end
                for k, v in pairs(bufflist2) do
                    if eater:HasDebuff(k) then
                        eater:RemoveDebuff(k)
                    end
                end
                -- 六个buff按权重抽取
                local buffname = luckybufflist:getChoice(math.random() * luckybufflist:getTotalWeight())
                eater:AddDebuff(buffname, buffname)
            end
        end,
    },
    {
        name = "tbat_item_peach_blossom_pact_potion",
        build = "tbat_item_peach_blossom_pact_potion",
        bank = "tbat_item_peach_blossom_pact_potion",
        atlasName = "tbat_item_peach_blossom_pact_potion",
        imageName = "tbat_item_peach_blossom_pact_potion",
        stackableSize = TUNING.STACK_SIZE_SMALLITEM,
        oneatenfn = function(inst, eater)
            eater:AddDebuff("tbat_cure_buff", "tbat_cure_buff")
        end,
        commonfn = function (inst)
            inst:ListenForEvent("TBAT_OnEntityReplicated.tbat_com_item_use_to", item_use_to_com_replica_init)
        end,
        masterfn = function (inst)
            inst:AddComponent("tbat_com_item_use_to")
            inst.components.tbat_com_item_use_to:SetActiveFn(item_use_to_active_fn)
        end
    },
}


local function shadow_init(inst)
    if inst:IsOnOcean(false) then     --- 如果在海里（不包括船）
        inst.AnimState:Hide("SHADOW")
        inst.AnimState:HideSymbol("shadow")
    else
        inst.AnimState:Show("SHADOW")
        inst.AnimState:ShowSymbol("shadow")
    end
end
local function make_potion(config)

    local ass = {
        Asset("ANIM", "anim/" .. config.build .. ".zip"),
        Asset("ATLAS", "images/inventoryimages/" .. config.atlasName .. ".xml"),
        Asset("IMAGE", "images/inventoryimages/" .. config.imageName .. ".tex"),
        Asset("ATLAS_BUILD", "images/inventoryimages/" .. config.atlasName .. ".xml", 256),
    }

    local function item_fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        inst.AnimState:SetBank(config.build)
        inst.AnimState:SetBuild(config.bank)
        inst.AnimState:PlayAnimation("idle")
        inst.AnimState:SetScale(0.7, 0.7, 0.7)
        MakeInventoryFloatable(inst, "med", 0.05, { 0.85, 0.45, 0.85 })
        inst.entity:SetPristine()

        if config.commonfn then
            config.commonfn(inst)
        end

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. config.atlasName .. ".xml"
        inst.components.inventoryitem.imagename = config.imageName

        -- 可食用
        if config.oneatenfn then
            inst:AddComponent("edible")
            inst.components.edible.foodtype = FOODTYPE.GOODIES
            inst.components.edible.hungervalue = 0
            inst.components.edible.healthvalue = 0
            inst.components.edible.sanityvalue = 0
            inst.components.edible:SetOnEatenFn(config.oneatenfn)
        end

        -- 可堆叠
        if config.stackableSize then
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = config.stackableSize
        end

        -- 交易
        if config.tradableGoldValue then
            inst:AddComponent("tradable")
            inst.components.tradable.goldvalue = config.tradableGoldValue
        end

        if config.masterfn then
            config.masterfn(inst)
        end

        MakeHauntableLaunch(inst)

        -- 落水影子
        inst:ListenForEvent("on_landed", shadow_init)
        shadow_init(inst)

        return inst
    end

    return Prefab(config.name, item_fn, ass)

end
local prefs = {}
for k, v in pairs(potions) do
    table.insert(prefs, make_potion(v))
end
return unpack(prefs)

--------------------------------
--[[ 还原光线]]
--[[ @author: 谅直]]
--[[ @createTime: 2021-12-02]]
--[[ @updateTime: 2021-12-06]]
--[[ @email: x7430657@163.com]]
--------------------------------
require("util/logger")
local assets =
{
    Asset("ANIM", "anim/"..TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB..".zip"),--动画
    Asset("ATLAS", "images/inventoryimages/"..TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB..".xml"),--物品栏贴图
    Asset("IMAGE", "images/inventoryimages/"..TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB..".tex"),
    Asset("SOUND", "sound/common.fsb"),--旋风扇声音
}
--[[影响某个实体]]
--[[@param inst: 还原光线entity]]
--[[@param target: 目标entity]]
local function effectEntity(inst,target)
    local valid = false
    if target.components.fueled and target.components.fueled:GetPercent() < 1 then -- 燃料
        target.components.fueled:SetPercent(1)
        if not valid then
            valid = true
        end
    end
    if target.components.finiteuses and target.prefab ~= TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB
            and target.components.finiteuses:GetPercent() < 1
    then
        -- 有限使用 但不能是还原光线
        target.components.finiteuses:SetPercent(1)
        if not valid then
            valid = true
        end
    end
    if target.components.armor and target.components.armor.maxcondition > 0
            and target.components.armor:GetPercent() < 1
    then
        -- 盔甲
        target.components.armor:SetPercent(1)
        if not valid then
            valid = true
        end
    end
    if target.components.perishable and target.components.perishable:GetPercent() < 1 then
        -- 食物
        target.components.perishable:SetPercent(1)
        if not valid then
            valid = true
        end
    end
    if valid then
        local caster = inst.components.inventoryitem.owner -- 必须先获取,防止inst因为无耐久被删除后拿不到
        inst.components.finiteuses:Use(1)
        if caster.components.staffsanity then -- 同饥荒法杖
            caster.components.staffsanity:DoCastingDelta(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_SANITY)
        elseif caster.components.sanity ~= nil then
            caster.components.sanity:DoDelta(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_SANITY)
        end
    end
    return valid
end
--[[是否可以施法]]
local function canSpell(inst,caster)
    local sanityValid = true -- 是否可以施法
    if caster.components.sanity ~= nil then -- 存在san值
        if caster.components.staffsanity then -- 同饥荒法杖,staffsanity似乎是增强或减少san值消耗的
            sanityValid = caster.components.sanity.current >= math.abs(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_SANITY * ( caster.components.staffsanity.multiplier or 1))
        else
            sanityValid = caster.components.sanity.current >= math.abs(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_SANITY)
        end
    end
    Logger:Debug({"施法可以施法",sanityValid,caster.components.sanity.current,TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_SANITY,caster.components.staffsanity })
    -- 法杖本身有效 且san值可以施法
    return (inst.components.finiteuses == nil or inst.components.finiteuses.current > 0 )
            and sanityValid
end
-- 抄自懒人法杖
local ORANGE_PICKUP_MUST_TAGS = { "_inventoryitem" }
local ORANGE_PICKUP_CANT_TAGS = { "INLIMBO", "NOCLICK", "knockbackdelayinteraction", "catchable", "fire", "minesprung", "mineactive", "spider" }

--[[施法]]
local function spellFn(staff, target, pos)
    local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_RANGE, ORANGE_PICKUP_MUST_TAGS, ORANGE_PICKUP_CANT_TAGS)
    local caster = staff.components.inventoryitem.owner
    local validCount = 0 -- 生效数量
    local currentValid -- 当前是否生效
    for _,v in pairs(ents) do
        if v.components.inventoryitem ~= nil and
                v.components.inventoryitem.canbepickedup and
                v.components.inventoryitem.cangoincontainer and
                not v.components.inventoryitem:IsHeld()
        then
            if canSpell(staff,caster) then
                currentValid = effectEntity(staff,v)
                if currentValid then
                    validCount = validCount +1
                    v:DoTaskInTime(0.5 + math.random() * 0.5, function()
                        local fx = SpawnPrefab("farm_plant_happy")
                        fx.Transform:SetPosition(v.Transform:GetWorldPosition())
                    end)
                end
            else
                break
            end
        end

    end
    if caster ~= nil and validCount > 0 then
        caster.components.talker:Say(STRINGS.DORAEMON_TECH.MAGIC_FLASHLIGHT_SPELL_SAY)
    end
end


--[[是否可以在物品栏中使用]]
local function canuse(inst, doer, target, actions, right)
    -- 存在该标签 则可以使用 , 之所以通过标签是因为很多组件客户端拿不到,只能通过标签来判断
    if target and target:HasTag(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USE_TAG) then
        return true
    end
    return false
end
--[[物品栏右键还原]]
local function onuse(act)
    local valid = false
    if canSpell(act.invobject,act.invobject.components.inventoryitem.owner)then
        valid = effectEntity(act.invobject,act.target)
    end
    return valid
end


local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    --inst.AnimState:SetBank(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB)
    --    --inst.AnimState:SetBuild(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB)
    inst.AnimState:SetBank(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB)
    inst.AnimState:SetBuild(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB)
    inst.AnimState:PlayAnimation("idle")
    inst:AddTag("nopunch")

    inst:AddComponent("doraemon_click_useitem")
    inst.components.doraemon_click_useitem.canuse = canuse
    inst.components.doraemon_click_useitem.onuse = onuse
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -------
    inst:AddComponent("finiteuses")--耐久
    inst.components.finiteuses:SetOnFinished(function (inst)
        inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
        inst:Remove()
    end )
    inst.components.finiteuses:SetMaxUses(35)
    inst.components.finiteuses:SetUses(35)


    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/"..TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB..".xml"
    inst:AddComponent("tradable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
    inst.components.equippable:SetOnEquip(function(inst, owner)
        owner.AnimState:OverrideSymbol("swap_object", TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB, "swap_magicflashlight")
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
    end)
    inst.components.equippable:SetOnUnequip(function(inst, owner)
        owner.AnimState:Hide("ARM_carry")
        owner.AnimState:Show("ARM_normal")
    end)

    inst.fxcolour = {223/255, 208/255, 69/255} -- 同黄色法杖
    --inst.castsound = "dontstarve/common/staffteleport"
    inst.components.finiteuses:SetMaxUses(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USES) -- 5次
    inst.components.finiteuses:SetUses(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_USES)
    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(spellFn)
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true

    MakeHauntableLaunchAndPerish(inst) --作祟相关

    return inst
end



return  Prefab(TUNING.DORAEMON_TECH.MAGIC_FLASHLIGHT_PREFAB, fn, assets)
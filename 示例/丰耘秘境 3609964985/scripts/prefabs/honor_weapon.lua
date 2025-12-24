require("components/deployhelper") -- TriggerDeployHelpers lives here
local cd = {
    rice = 20,
    wheat = 50,
    avocado = 100,
    tea = 1,
    coconut = 10,
}
local maxcharge = {
    rice = 20,
    wheat = 10,
    avocado = 0,
    tea = 50,
    coconut = 20,
}

local assets =
{
    Asset("ANIM", "anim/spear.zip"),
    Asset("ANIM", "anim/swap_spear.zip"),
}

local prefabs =
{
	"bomb_lunarplant_explode_fx",
	"reticule",
	"reticuleaoe",
	"reticuleaoeping",
}

-- 强制卸下装备
local function Unequip(inst)
    -- 如果实例是可装备的并且当前已装备
    if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
        -- 获取装备实例的所有者
        local owner = inst.components.inventoryitem.owner
        -- 如果所有者存在并且有物品栏组件
        if owner ~= nil and owner.components.inventory ~= nil then
            -- 卸下装备
            local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
            -- 如果卸下的物品存在，将其放回物品栏
            if item ~= nil then
                owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
            end
        end
    end
end

-- 装备耐久消失回调函数
local function OnFinished(inst)
    inst.AnimState:PlayAnimation("broken")
    if not inst:HasTag("broken") then
        inst:AddTag("broken")
    end
    Unequip(inst)
end

local function OnBlink(staff, pos, caster)
    staff.components.finiteuses:Use(3)
    staff.components.rechargeable:Discharge(5)
end

local function dofx(inst, owner)
    if inst.fx then
        inst.fx:Remove()
    end
    inst.fx = SpawnPrefab("honor_weapon_fx_"..inst.mode)
    inst.fx.Transform:SetPosition(owner.Transform:GetWorldPosition())
    inst.fx.entity:SetParent(owner.entity)
    inst.fx.entity:AddFollower()
    inst.fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -180, 0)
end

local function dofx_common(inst, owner)
    if inst.fx_common then
        inst.fx_common:Remove()
    end
    inst.fx_common = SpawnPrefab("honor_weapon_fx_common")
    inst.fx_common.Transform:SetPosition(owner.Transform:GetWorldPosition())
    inst.fx_common.entity:SetParent(owner.entity)
    inst.fx_common.entity:AddFollower()
    inst.fx_common.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -180, 0)
end

local function killfx(inst)
    if inst.fx then
        inst.fx:Remove()
        inst.fx = nil
    end
    if inst.fx_common then
        inst.fx_common:Remove()
    end
    if inst.fx_coconut then
        inst.fx_coconut:Remove()
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_spear", "swap_spear")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    inst.owner = owner
    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end

    -- 特效
    --dofx(inst, owner)
    --dofx_common(inst, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    inst.owner = nil
    if inst.components.container ~= nil then
        inst.components.container:Close()
    end

    killfx(inst)
end

local function honor_enabled(inst)
    inst.honor_enabled = true
    inst.components.weapon.damage = inst.components.weapon.damage + 20
end

local function honor_disabled(inst)
    inst.honor_enabled = false
    inst.components.weapon.damage = inst.components.weapon.damage - 20
end

----------------------------------------------------------------------------
--- 大米精华
----------------------------------------------------------------------------

-- 大米施法函数
local function riceattack(inst, target, pos, player)
    local cd = cd.rice

    -- 生成或移除池塘和植物
    local pond = SpawnPrefab("honor_pond")
    -- 移除的目标限制在组件修改中
    if target ~= nil then
        target:Remove()
    end
    if pos ~= nil then
        pond.Transform:SetPosition(pos.x, pos.y, pos.z)
    end

    -- 施法后处理，cd/法杖特效
    inst.components.rechargeable:SetCharge(inst.components.rechargeable:GetCharge() - cd,true)
    inst.replica.inventoryitem:SetChargeTime(inst.components.rechargeable:GetRechargeTime())  -- 更新本地显示充电时间（蓝色进度饼）
    if inst.components.rechargeable.current < cd then
        inst:RemoveComponent("spellcaster")
    end
    if inst.components.rechargeable:GetCharge() < cd then
        killfx(inst)
    end
end

-- 大米精华
local function ricefn(inst, slot)
    if slot ~= nil then
        inst.maxcharge.rice = maxcharge.rice
        if slot == 1 then
            inst.mode = "rice"
            inst.cd = cd.rice
            if inst.components.rechargeable.current >= cd.rice then
                inst.fxcolour = {255/255, 215/255, 0/255}  -- 金黄色
                inst:AddComponent("spellcaster")
                inst.components.spellcaster:SetSpellFn(riceattack)
                inst.components.spellcaster.canuseonpoint = true
                inst.components.spellcaster.canuseonpoint_water = false
                inst.components.spellcaster.canuseontargets = true
                --inst.components.spellcaster.canonlyuseonrecipes = false
                --inst.components.spellcaster.quickcast = true
                --inst:PushEvent("show")
            end
        end

        -- 普攻
        local oldonattack = inst.components.weapon.onattack or nil
            inst.components.weapon.onattack = function(inst, attacker, target)
                if attacker.components.moisture then
                    attacker.components.moisture:DoDelta(-5)
                end
                -- 烘干3个装备栏物品/将诅咒饰品换为猴尾草
                local num = 0
                if attacker.components.inventory and attacker.components.inventory.itemslots then
                    for i, item in pairs(attacker.components.inventory.itemslots) do
                        if item.components.inventoryitemmoisture and item.components.inventoryitemmoisture.iswet then
                            item.components.inventoryitemmoisture:SetMoisture(0)-- 湿度设为0
                            num = num + 1
                        end
                        if item.prefab == "cursed_monkey_token" then
                            local gift = SpawnPrefab("monkeytail")
                            if item.components.stackable and item.components.stackable.stacksize > 1 then
                                item.components.stackable:Get()
                                item.components.inventoryitem.owner.components.inventory:GiveItem(gift)
                            else
                                item:Remove()
                                item.components.inventoryitem.owner.components.inventory:GiveItem(gift)
                            end
                            num = num + 1
                        end
                        if num >= 3 then
                            break
                        end
                    end
                end

                if oldonattack then
                    oldonattack(inst, attacker, target)
                end
            end
    else
        inst.maxcharge.rice = 0
    end
end

----------------------------------------------------------------------------
--- 麦粒精华
----------------------------------------------------------------------------

-- 麦粒施法函数
local function wheatattack(inst, target, pos, player)
    local cd = cd.wheat

    -- 特效
    local round_fx = SpawnPrefab("deerclops_icelance_ping_fx")
    round_fx.Transform:SetPosition(pos.x, pos.y, pos.z)
    round_fx:DoTaskInTime(10, function()
        round_fx:Remove()
    end)
    local ice_fx = SpawnPrefab("deerclops_impact_circle_fx")
    ice_fx.Transform:SetPosition(pos.x, pos.y, pos.z)

    -- 施法区域内实体增加5点冰冻值
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, 5, nil, "player")
    for k,v in pairs(ents) do
        local item = v.components.freezable
        if item ~= nil and not v:HasTag("player") then
            item:AddColdness(4)
            item:SpawnShatterFX()
        end
    end
    -- 施法后8秒内每2秒区域内增加1点冰冻值
    for i = 1,4 do
        inst:DoTaskInTime(i * 2, function()
            local ents = TheSim:FindEntities(pos.x, 0, pos.z, 5, nil, "player")
            for k,v in pairs(ents) do
                local item = v.components.freezable
                if item ~= nil and not v:HasTag("player") then
                    item:AddColdness(1)
                    item:SpawnShatterFX()
                    local icespike_fx = SpawnPrefab("icespike_fx"..tostring(math.random(1, 4)))
                    local ix, iy, iz = v.Transform:GetWorldPosition()
                    icespike_fx.Transform:SetPosition(ix, iy, iz)
                end
            end
        end)
    end

    -- 施法后处理，cd/法杖特效
    inst.components.rechargeable:SetCharge(inst.components.rechargeable:GetCharge() - cd,true)
    inst.replica.inventoryitem:SetChargeTime(inst.components.rechargeable:GetRechargeTime())  -- 更新本地显示充电时间（蓝色进度饼）
    if inst.components.rechargeable.current < cd then
        inst:RemoveComponent("spellcaster")
    end
    if inst.components.rechargeable:GetCharge() < cd then
        killfx(inst)
    end
end

-- 麦粒精华
local function wheatfn(inst, slot)
    if slot ~= nil then
        inst.maxcharge.wheat = maxcharge.wheat
        if slot == 1 then
            inst.mode = "wheat"
            inst.cd = cd.wheat
            if inst.components.rechargeable.current >= cd.wheat then
                inst.fxcolour = {16/255,96/255,176/255}  -- 蓝色
                inst:AddComponent("spellcaster")
                inst.components.spellcaster:SetSpellFn(wheatattack)
                inst.components.spellcaster.canuseonpoint = true
                inst.components.spellcaster.canuseonpoint_water = true
            end
        end

        -- 普攻概率冰冻
        local oldonattack = inst.components.weapon.onattack or nil
        inst.components.weapon.onattack = function(inst, attacker, target)
            if target.components.freezable then
                if math.random() <= 0.1 then
                    target.components.freezable:AddColdness(4)
                    target.components.freezable:SpawnShatterFX()
                end
            end

            if oldonattack then
                oldonattack(inst, attacker, target)
            end
        end
    else
        inst.maxcharge.wheat = 0
    end
end

----------------------------------------------------------------------------
--- 茶丛精华
----------------------------------------------------------------------------

local function countitem(owner, item)
    local count = 0
    for i, v in pairs(owner.components.inventory.itemslots) do
        if v.prefab == item then
            if v.components.stackable then
                count = count + item.components.stackable:StackSize()
            else
                count = count + 1
            end
        end
    end
    return count
end

local function teaspell(inst, target, pos, player)
    local cd = cd.tea

    local light = nil
    if inst.teamode == "greentea" then
        light = SpawnPrefab("honor_greentea_light")
    elseif inst.teamode == "dhp" then
        light = SpawnPrefab("honor_dhp_light")
    elseif inst.teamode == "jasmine" then
        light = SpawnPrefab("honor_jasmine_light")
    end
    light.Transform:SetPosition(pos.x, pos.y, pos.z)

    -- 施法后处理，cd/法杖特效
    inst.components.rechargeable:SetCharge(inst.components.rechargeable:GetCharge() - cd,true)
    inst.replica.inventoryitem:SetChargeTime(inst.components.rechargeable:GetRechargeTime())  -- 更新本地显示充电时间（蓝色进度饼）
    if inst.components.rechargeable.current < cd then
        inst:RemoveComponent("spellcaster")
    end
    if inst.components.rechargeable:GetCharge() < cd then
        killfx(inst)
    end
end

local function teafn(inst, slot)
    if slot ~= nil then
        inst.maxcharge.tea = maxcharge.tea
        if slot == 1 then
            -- inst.mode = "tea"  茶叶的施法模式改为三种
            inst.cd = cd.tea
            if inst.components.rechargeable.current >= cd.tea then

                -- 根据装备栏三种茶叶果实数量选择施法模式
                if inst.components.inventoryitem.owner then
                    local owner = inst.components.inventoryitem.owner
                    -- local greenteanum = countitem(owner, "honor_greentea")
                    -- local dhpnum = countitem(owner, "honor_dhp")
                    -- local jasminenum = countitem(owner, "honor_jasmine")
                    local greenteanum = 1
                    local dhpnum = 1
                    local jasminenum = 1
                    local totalnum = greenteanum + dhpnum + jasminenum
                    if totalnum > 0 then
                        local light = math.random()
                        if light <= greenteanum / totalnum then
                            inst.fxcolour = { 144 / 255, 238 / 255, 144 / 255 }
                            inst.teamode = "greentea"
                            --owner.components.inventory:RemoveItem("honor_greentea", false)
                            inst.mode = "greentea"
                        elseif light <= (greenteanum + dhpnum) / totalnum then
                            inst.fxcolour = { 255 / 255, 128 / 255, 0 / 255 }
                            inst.teamode = "dhp"
                            --owner.components.inventory:RemoveItem("honor_dhp", false)
                            inst.mode = "dhp"
                        else
                            inst.fxcolour = { 255 / 255, 182 / 255, 193 / 255 }
                            inst.teamode = "jasmine"
                            --owner.components.inventory:RemoveItem("honor_jasmine", false)
                            inst.mode = "jasmine"
                        end

                        inst:AddComponent("spellcaster")
                        inst.components.spellcaster:SetSpellFn(teaspell)
                        inst.components.spellcaster.canuseonpoint = true
                        inst.components.spellcaster.canuseonpoint_water = true
                    end
                end
            end
        end

        -- 普攻概率冰冻
        -- local oldonattack = inst.components.weapon.onattack or nil
        -- inst.components.weapon.onattack = function(inst, attacker, target)
        --     if target.components.freezable then
        --         if math.random() <= 0.1 then
        --             target.components.freezable:AddColdness(4)
        --             target.components.freezable:SpawnShatterFX()
        --         end
        --     end

        --     if oldonattack then
        --         oldonattack(inst, attacker, target)
        --     end
        -- end
    else
        inst.maxcharge.tea = 0
    end
end

----------------------------------------------------------------------------
--- 椰子精华
----------------------------------------------------------------------------

-- 椰子施法函数
local function coconutspell(inst, target, pos, player)
    local cd = cd.coconut
    local range = 3

    -- 特效
    local coconut_cloud_fx = SpawnPrefab("ghostlyelixir_slowregen_fx")
    --coconut_cloud_fx:DoTaskInTime(0.2, function() coconut_cloud_fx.AnimState:SetMultColour(0.545, 0.271, 0.075, 0.5) end)
    coconut_cloud_fx.Transform:SetPosition(pos.x, 20, pos.z)

    local fall_fx = SpawnPrefab("cavein_debris")
    fall_fx.Transform:SetPosition(pos.x, 0 , pos.z)

    local ground_fx = SpawnPrefab("shadow_teleport_in")
    ground_fx.Transform:SetPosition(pos.x, 0, pos.z)

    -- 施法区域内生成椰子
    for i = 1 , math.random(8, 12) do
        local coconut = SpawnPrefab("honor_coconut")
        local angle = math.random(0, 360)
        local r = math.random(0, range)
        local x = r * math.cos(angle)
        local z = r * math.sin(angle)
        local high = math.random(18,22)
        coconut:DoTaskInTime(math.random() / 3, function()
            coconut.Transform:SetPosition(pos.x + x, high, pos.z + z)
            coconut:DoTaskInTime(math.sqrt(2 * high / 9.8), function()
                local bomb_rand = math.random()
                local ents = TheSim:FindEntities(pos.x + x, 0, pos.z + z, range / 5, nil, "player")
                for k,v in pairs(ents) do
                    if v.components.health ~= nil and not v.components.health:IsDead() then
                        -- function Health:DoDelta(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
                        if bomb_rand <= 0.6 then
                            v.components.health:DoDelta(- 20 , 0.2)
                        else
                            v.components.health:DoDelta(- 40 , 0.2)
                        end
                    end
                end

                if bomb_rand <= 0.6 then
                    local bomb_fx = SpawnPrefab("bundle_unwrap")
                    bomb_fx.Transform:SetPosition(pos.x + x, 0, pos.z + z)
                end
                coconut:Remove()
            end)
        end)
    end

    -- 生成椰树精
    if inst.coconut_attacknum >= 52 or math.random() <= 0.1 then
        local coconuttree = SpawnPrefab("honor_coconuttree")
        coconuttree.components.follower.leader = player
        coconuttree.Transform:SetPosition(pos.x, pos.y, pos.z)

        -- 特效
        local ct_fx = SpawnPrefab("groundpound_fx")  -- 泥土
        ct_fx.Transform:SetPosition(pos.x, pos.y, pos.z)
        local ct_fx2 = SpawnPrefab("die_fx")  -- 烟雾
        ct_fx2.Transform:SetPosition(pos.x, pos.y, pos.z)

        coconuttree:DoTaskInTime(150, function()
            coconuttree:Remove()
        end)

        inst.coconut_attacknum = 0
    end

    -- 施法后处理，cd/法杖特效
    inst.components.rechargeable:SetCharge(inst.components.rechargeable:GetCharge() - cd,true)
    inst.replica.inventoryitem:SetChargeTime(inst.components.rechargeable:GetRechargeTime())  -- 更新本地显示充电时间（蓝色进度饼）
    if inst.components.rechargeable.current < cd then
        inst:RemoveComponent("spellcaster")
    end
    if inst.components.rechargeable:GetCharge() < cd then
        killfx(inst)
    end
end

local function coconutfn(inst, slot)
    if slot ~= nil then
        inst.maxcharge.coconut = maxcharge.coconut
        if slot == 1 then
            inst.mode = "coconut"
            inst.cd = cd.coconut
            if inst.components.rechargeable.current >= cd.coconut then
                if inst.components.inventoryitem.owner then
                    inst.fxcolour = { 139 / 255, 69 / 255, 19 / 255 }  -- 椰子棕色
                    inst:AddComponent("spellcaster")
                    inst.components.spellcaster:SetSpellFn(coconutspell)
                    inst.components.spellcaster.canuseonpoint = true
                    inst.components.spellcaster.canuseonpoint_water = true
                end

                local owner = inst.owner
                if owner then
                    inst.fx_coconut = SpawnPrefab("honor_fruit_coconut_fx")
                    inst.fx_coconut.Transform:SetPosition(owner.Transform:GetWorldPosition())
                    inst.fx_coconut.entity:SetParent(owner.entity)
                    inst.fx_coconut.entity:AddFollower()
                    inst.fx_coconut.Follower:FollowSymbol(owner.GUID, "swap_object", 0, -180, 0)
            
                end
            end
        end

        -- 普攻积攒次数，满52次施法必召唤椰子树精
        local oldonattack = inst.components.weapon.onattack or nil
        inst.components.weapon.onattack = function(inst, attacker, target)
            if inst.coconut_attacknum <= 52 then
                inst.coconut_attacknum = inst.coconut_attacknum + 1
            end
            if oldonattack then
                oldonattack(inst, attacker, target)
            end
        end
    else
        inst.maxcharge.coconut = 0
    end
end

----------------------------------------------------------------------------
--- 更新武器技能
----------------------------------------------------------------------------

local function getitemslot(inst, item)
    local slot = inst.components.container.slots
    for i, v in pairs(slot) do
        if v.prefab == item then
            return i
        end
    end
    return nil
end

local function update_weapon(inst)
    if inst.components.spellcaster then
        inst:RemoveComponent("spellcaster")
    end
    inst.components.weapon.onattack = nil
    inst.mode = "empty"
    inst.cd = 0
    if inst.components.container ~= nil then
        ricefn(inst, getitemslot(inst, "honor_rice_prime"))
        wheatfn(inst, getitemslot(inst, "honor_wheat_prime"))
        teafn(inst, getitemslot(inst, "honor_tea_prime"))
        coconutfn(inst, getitemslot(inst, "honor_coconut_prime"))
        -- avocadofn(inst, inst.components.container:GetItemSlot("honor_avocado_prime"))

        -- 更新最大能量
        inst.MaxCharge = 100
        for k, v in pairs(inst.maxcharge) do
            inst.MaxCharge = inst.MaxCharge + v
        end
        inst.components.rechargeable:SetMaxCharge(inst.MaxCharge)
        inst.components.rechargeable:SetChargeTime(inst.MaxCharge)
        -- 有技能且冷却好则显示粒子特效
        if inst.mode ~= "empty" and inst.components.rechargeable:GetCharge() >= inst.cd then
            if inst.owner ~= nil then
                dofx(inst, inst.owner)
                dofx_common(inst, inst.owner)
            end
        else
            killfx(inst)
        end
    end
end

local function OnChargedFn(inst)

end

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    for r = 5, 0, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        --if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
        if  not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function ShouldRepeatCast(inst, target)
    return true
end

local function OnSave(inst, data)
    data.coconut_attacknum = inst.coconut_attacknum or 0
end

local function OnLoad(inst, data)
    inst.coconut_attacknum = data.coconut_attacknum or 0
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("spear")
    inst.AnimState:SetBuild("swap_spear")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("weapon")
    inst:AddTag("sharp")
    inst:AddTag("honor_weapon")
    inst:AddTag("honor_repairable")
    inst:AddTag("HMR_repairable")

    inst.MaxCharge = 0
    inst.maxcharge =
    {
        rice = 0,
        wheat = 0,
        avocado = 0
    }
    inst.mode = "empty"
    inst.coconut_attacknum = 0

    inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetAllowWater(true)
	inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
	inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
	inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true
	inst.components.aoetargeting.reticule.twinstickmode = 1
	inst.components.aoetargeting.reticule.twinstickrange = 16
	inst.components.aoetargeting:SetDeployRadius(0)
	inst.components.aoetargeting:SetShouldRepeatCastFn(nil)
	inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe_1d2_12"
	inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping_1d2_12"
	inst.components.aoetargeting:SetRange(15)
	inst.components.aoetargeting.alwaysvalid = true

    inst.components.aoetargeting:SetDeployRadius(0)
    inst.components.aoetargeting:SetShouldRepeatCastFn(ShouldRepeatCast)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoecatapultelementalvolley"
    inst.components.aoetargeting.reticule.pingprefab = "reticuleaoecatapultvolleyping"
    --inst.components.aoetargeting.reticule.updatepositionfn = ElementalVolleyUpdatePositionFn

    MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, -9)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(45)
    inst.components.weapon:SetRange(1.2, 5)

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(15)

    -------

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(400)
    inst.components.finiteuses:SetUses(400)
    inst.components.finiteuses:SetOnFinished(OnFinished)

    inst:AddComponent("rechargeable") -- 添加冷却组件
    inst.components.rechargeable:SetMaxCharge(100)  -- 总能量为100， 每秒恢复1能量
    inst.components.rechargeable:SetChargeTime(100)  -- 冷却时间为100秒
    inst.components.rechargeable.current = 0
    inst.components.rechargeable:SetOnDischargedFn(OnChargedFn)

    -- inst.update_weapon_task = inst:DoPeriodicTask(1, function()
    --     update_weapon(inst)
    -- end)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("honor_weapon")
    inst:ListenForEvent("itemget", update_weapon, inst)
    inst:ListenForEvent("itemlose", update_weapon, inst)
    update_weapon(inst)

    inst:ListenForEvent("skill_changed", function (inst, data)
        data.owner.components.talker:Say("你的神器技能已更新！")
        local prime = {}
        for i = 1, 3 do
            if inst.components.container.slots[i] ~= nil then
                prime[i] = inst.components.container.slots[i]
                inst.components.container.slots[i]:Remove()
            end
        end
        for i = 1, 3 do
            if prime[i] ~= nil then
                inst.components.container:GiveItem(SpawnPrefab(prime[i].prefab), (i+1) % 3 + 1)
            end
        end
        update_weapon(inst)
    end)

    local update = false
    local flag = false      -- 防止重复更新
    inst:DoPeriodicTask(1, function()
        if inst.components.rechargeable then
            local charge = inst.components.rechargeable:GetCharge()
            if charge >= inst.cd then
                update = true
            else
                update = false
            end
            if flag ~= update then
                flag = update
                if flag then
                    update_weapon(inst)
                end
            end
        end
    end)

    -- inst:AddComponent("blinkstaff")
    -- inst.components.blinkstaff:SetFX("sand_puff_large_front", "sand_puff_large_back")
    -- inst.components.blinkstaff.onblinkfn = OnBlink

    -- 套装组件
    inst:AddComponent("setbonus")
    inst.components.setbonus:SetSetName("HONOR")
    inst.components.setbonus:SetOnEnabledFn(honor_enabled)
    inst.components.setbonus:SetOnDisabledFn(honor_disabled)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("honor_weapon", fn, assets,prefabs)
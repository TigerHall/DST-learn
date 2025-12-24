


local assets = {
    Asset("ANIM", "anim/tbat_sensangu.zip"),
    -- Asset("IMAGE", "images/inventoryimages/tbat_sensangu.tex"), --物品栏贴图
    -- Asset("ATLAS", "images/inventoryimages/tbat_sensangu.xml"),
    -- Asset("ATLAS_BUILD", "images/inventoryimages/tbat_sensangu.xml", 256),
}
local function dig_up1(inst, worker)
    if inst.components.lootdropper ~= nil then
        inst.components.lootdropper:SpawnLootPrefab("tbat_sensangu_item")
    end
    inst:Remove()
end
local function dig_up2(inst, worker)
    if inst.components.lootdropper ~= nil then
        if math.random() < 0.05 then
            inst.components.lootdropper:SpawnLootPrefab("tbat_sensangu_item")
            inst.components.lootdropper:SpawnLootPrefab("tbat_sensangu_item")
        else
            inst.components.lootdropper:SpawnLootPrefab("tbat_sensangu_item")
        end
    end
    inst:Remove()
end
local function SetStage1(inst)

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(2)
        inst.components.workable:SetOnFinishCallback(dig_up1)
    end
    inst.AnimState:PlayAnimation("stage1", true)
end

local function Grow1(inst)
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrowFromWilt")
    inst.AnimState:PlayAnimation("stage1", true)
    inst.cangrow = false
    inst.components.growable:StopGrowing()
end

local function SetStage2(inst)

    inst:AddTag('lightningrod') --避雷针功能
    if inst.components.workable then
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(dig_up1)
    end
    

    inst.AnimState:PlayAnimation("stage2", true)
end

local function Grow2(inst)
    inst.AnimState:PlayAnimation("grow1")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrowFromWilt")
    inst.AnimState:PushAnimation("stage2", true)
    inst.cangrow = false
    inst.components.growable:StopGrowing()
end

local MIN = TUNING.SHADE_CANOPY_RANGE_SMALL
local MAX = MIN + TUNING.WATERTREE_PILLAR_CANOPY_BUFFER
local function OnFar(inst, player)
    if player.tbatsensangucanopy then
        player.tbatsensangucanopy = player.tbatsensangucanopy - 1
        player:PushEvent("onchangetbatsensangucanopyzone", player.tbatsensangucanopy > 0)
    end
    inst.players[player] = nil
end

local function OnNear(inst, player)
    inst.players[player] = true

    player.tbatsensangucanopy = (player.tbatsensangucanopy or 0) + 1

    player:PushEvent("onchangetbatsensangucanopyzone", player.tbatsensangucanopy > 0)
end

local function OnRemoveEntity(inst)
    for player in pairs(inst.players) do
        if player:IsValid() then
            if player.tbatsensangucanopy then
                OnFar(inst, player)
            end
        end
    end
end
local function SetStage3(inst)

    inst:AddTag('lightningrod') --避雷针功能

    if inst.components.workable then
        inst.components.workable:SetWorkLeft(6)
        inst.components.workable:SetOnFinishCallback(dig_up2)
    end

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
    inst.components.playerprox:SetDist(MIN, MAX)
    inst.components.playerprox:SetOnPlayerFar(OnFar)
    inst.components.playerprox:SetOnPlayerNear(OnNear)

    inst.components.raindome:Enable()

    inst.AnimState:PlayAnimation("stage3", true)

    inst.OnRemoveEntity = OnRemoveEntity
end

local function Grow3(inst)
    inst.AnimState:PlayAnimation("grow2")
    inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrowFromWilt")
    inst.AnimState:PushAnimation("stage3", true)
    inst.cangrow = false
    inst.components.growable:StopGrowing()
end

local growth_stages = {
    {
        name = "small",
        time = function()
            return TUNING.TOTAL_DAY_TIME * 3
        end,
        fn = SetStage1,
        growfn = Grow1,
    },
    {
        name = "medium",
        time = function()
            return TUNING.TOTAL_DAY_TIME * 3
        end,
        fn = SetStage2,
        growfn = Grow2,
    },
    {
        name = "big",
        time = function()
            return TUNING.TOTAL_DAY_TIME * 3
        end,
        fn = SetStage3,
        growfn = Grow3,
    },
}
local function ShouldAcceptItem(inst, item, giver)
    if item.prefab == 'tbat_item_crystal_bubble' and (inst.components.growable and inst.components.growable.stage < 3) and not inst.cangrow then
        return true
    end
    return false
end

local function OnGetItemFromPlayer(inst, giver, item)
    if item.prefab == 'tbat_item_crystal_bubble' then
        if inst.components.growable.stage < 3 then
            -- inst.components.growable:LongUpdate(TUNING.TOTAL_DAY_TIME * 3)
            inst.cangrow = true
            inst.components.growable:StartGrowing()
        end
    end
end

local function onsave(inst, data)
    data.cangrow = inst.cangrow or false
end

local function onload(inst, data)
    if data ~= nil then
        inst.cangrow = data.cangrow or false
        if inst.cangrow then
            inst.components.growable:StartGrowing()
        end
    end
end
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Light:SetIntensity(0.5)
    inst.Light:SetRadius(2)
    inst.Light:Enable(true)
    inst.Light:SetFalloff(1)
    inst.Light:SetColour(200 / 255, 200 / 255, 200 / 255)

    MakeObstaclePhysics(inst, .25)

    inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.DEFAULT] / 2) --seed/planted_tree deployspacing/2

    inst:AddTag("petrifiable")
    inst:AddTag('daylight') --自然光
    inst.AnimState:SetBuild("tbat_sensangu")
    inst.AnimState:SetBank("tbat_sensangu")

    inst:AddComponent("raindome")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.raindome:Disable()
    inst.components.raindome:SetRadius(20)

    inst.players = {}

    inst.cangrow = false

    -------------------
    inst:AddComponent("inspectable")

    -------------------
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(2)
    inst.components.workable:SetOnFinishCallback(dig_up1)

    -------------------
    inst:AddComponent("lootdropper")

    ---------------------
    inst:AddComponent("growable")
    inst.components.growable.stages = growth_stages
    inst.components.growable:SetStage(1)
    inst.components.growable.loopstages = false
    inst.components.growable.magicgrowable = false

    inst:AddComponent("simplemagicgrower")
    inst.components.simplemagicgrower:SetLastStage(#inst.components.growable.stages)

    inst:AddComponent('trader')
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)

    inst.OnSave = onsave
    inst.OnLoad = onload

    return inst
end


local function ondeploy(inst, pt, deployer)
    local tree = SpawnPrefab("tbat_sensangu")
    if tree ~= nil then
        tree.Transform:SetPosition(pt:Get())
        inst:Remove()
        if deployer ~= nil and deployer.SoundEmitter ~= nil then
            deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
        end
    end
end
local function dug_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", nil, 0.75) --漂浮

    inst.AnimState:SetBank("tbat_sensangu")        --地上动画
    inst.AnimState:SetBuild("tbat_sensangu")
    inst.AnimState:PlayAnimation("item")


    inst.entity:SetPristine()

    inst:AddTag("meteor_protection") --防止被流星破坏
    inst:AddTag("nosteal")           --防止被火药猴偷走
    inst:AddTag("NORATCHECK")        --mod兼容：永不妥协。该道具不算鼠潮分

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")                                                    --可检查组件

    inst:AddComponent("inventoryitem")                                                  --物品组件
    inst.components.inventoryitem.atlasname = "images/inventoryimages/tbat_sensangu_item.xml" --物品贴图
    inst.components.inventoryitem.imagename = "tbat_sensangu_item"

    -- 堆叠组件
    inst:AddComponent("stackable")


    inst:AddComponent("deployable")
    --inst.components.deployable:SetDeployMode(DEPLOYMODE.ANYWHERE)
    inst.components.deployable.ondeploy = ondeploy
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)

    return inst
end

return Prefab("tbat_sensangu", fn, assets), Prefab("tbat_sensangu_item", dug_fn, assets),
    MakePlacer("tbat_sensangu_item_placer", "tbat_sensangu", "tbat_sensangu", "stage1")

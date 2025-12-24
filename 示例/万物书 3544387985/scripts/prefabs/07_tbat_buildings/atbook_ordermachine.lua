local assets =
{
    Asset("ANIM", "anim/atbook_ordermachine.zip"),
    Asset("ATLAS", "images/inventoryimages/atbook_ordermachine.xml"),
}

local IMAGES = {
    BG = { "images/ui/atbook_chefwolf/icon_k.xml", "icon_k.tex" },
    BG_SMALL = { "images/ui/atbook_chefwolf/icon_shiwusx.xml", "icon_shiwusx.tex" },
    BG_RIGHT = { "images/ui/atbook_chefwolf/icon_di_r.xml", "icon_di_r.tex" },
    BG_LEFT = { "images/ui/atbook_chefwolf/icon_di_l.xml", "icon_di_l.tex" },
    BG_NUM = { "images/ui/atbook_chefwolf/di_sl.xml", "di_sl.tex" },
    TITLE = { "images/ui/atbook_chefwolf/icon_mc.xml", "icon_mc.tex" },
    SLOT = { "images/ui/atbook_chefwolf/icon_gz_kz.xml", "icon_gz_kz.tex" },
    SLOT_DARK = { "images/ui/atbook_chefwolf/icon_gz_jz.xml", "icon_gz_jz.tex" },
    ARROW = { "images/ui/atbook_chefwolf/icon_fy_u.xml", "icon_fy_u.tex" },
    ARROW2 = { "images/ui/atbook_chefwolf/icon_sl_l.xml", "icon_sl_l.tex" },
    SCROLL_BAR = { "images/ui/atbook_chefwolf/icon_hd.xml", "icon_hd.tex" },
    POSITION_MARKER = { "images/ui/atbook_chefwolf/icon_hl.xml", "icon_hl.tex" },
    CLOSE = { "images/ui/atbook_chefwolf/icon_gb.xml", "icon_gb.tex" },
    BTN_BLUE = { "images/ui/atbook_chefwolf/icon_dc_1.xml", "icon_dc_1.tex" },
    BTN_PINK = { "images/ui/atbook_chefwolf/icon_dc_2.xml", "icon_dc_2.tex" },
    BTN_GREEN = { "images/ui/atbook_chefwolf/icon_pd.xml", "icon_pd.tex" },
}

for _, value in pairs(IMAGES) do
    table.insert(assets, Asset("ATLAS", value[1]))
end

local function OnFar(inst, player)
    inst.players[player] = nil

    local flag = false
    for v in pairs(inst.players) do
        if v:IsValid() then
            flag = true
        end
    end
    if not flag then
        inst.AnimState:PlayAnimation("idle_empty")
    end

    SendModRPCToClient(CLIENT_MOD_RPC["ATBOOK"]["chefwolfwidget"], player.userid, inst, false)
end

local function OnNear(inst, player)
    inst.players[player] = true

    inst.AnimState:PlayAnimation("idle")
end

local function InitFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.4, 0.6)

    inst.AnimState:SetBank("atbook_ordermachine")
    inst.AnimState:SetBuild("atbook_ordermachine")
    inst.AnimState:PlayAnimation("idle_empty")

    inst:AddTag("atbook_ordermachine")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("atbook_ordermachine")

    inst.players = {}

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
    inst.components.playerprox:SetDist(3, 4)
    inst.components.playerprox:SetOnPlayerFar(OnFar)
    inst.components.playerprox:SetOnPlayerNear(OnNear)

    return inst
end

STRINGS.NAMES.ATBOOK_ORDERMACHINE = "自助点菜机"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ATBOOK_ORDERMACHINE = "要试一试族长大人的厨艺嘛？"
STRINGS.RECIPE_DESC.ATBOOK_ORDERMACHINE = "要试一试族长大人的厨艺嘛？"

return Prefab("atbook_ordermachine", InitFn, assets),
    MakePlacer("atbook_ordermachine_placer", "atbook_ordermachine", "atbook_ordermachine", "idle_empty")

local containers = require("containers")

containers.params.atbook_chefwolf = {
    widget =
    {
        slotpos = {},
        slotbg = {},
        animbank = "ui_chest_3x3",
        animbuild = "atbook_chefwolf_13x7",
        pos = Vector3(0, 50, 0),
        side_align_tip = 160,
        buttoninfo = {
            position = Vector3(350, 325, 0),
            fn = function(inst)
                SendModRPCToServer(MOD_RPC["ATBOOK"]["closecontainer"], inst)
            end
        }
    },
    type = "chest",
    itemtestfn = function(container, item, slot)
        if slot == 45 then
            if item.prefab ~= "wetgoop" and item:HasTag("preparedfood") and not item:HasTag("spicedfood") then
                return true
            end
            return false
        elseif slot == 46 then
            if item:HasTag("spice") then
                return true
            end
            return false
        else
            if item:HasTag("spice") then
                return true
            end
            if item:HasTag("preparedfood") then
                return true
            end
            if item:HasTag("icebox_valid") then
                return true
            end
            for k, v in pairs(FOODTYPE) do
                if item:HasTag("edible_" .. v) then
                    return true
                end
            end
            if not (item:HasTag("fresh") or item:HasTag("stale") or item:HasTag("spoiled")) then
                return false
            end
            if item:HasTag("smallcreature") then
                return false
            end

            return false
        end
    end
}

for y = 0, 6 do
    for x = 0, 4 do
        table.insert(containers.params.atbook_chefwolf.widget.slotpos, Vector3(-460 + 72 * x, 175 - 72 * y, 0))
        table.insert(containers.params.atbook_chefwolf.widget.slotbg,
            { image = "icon_gz_3.tex", atlas = "images/ui/container/icon_gz_3.xml" })
    end
end

for y = 0, 6 do
    for x = -1, 1 do
        if y ~= 3 then
            table.insert(containers.params.atbook_chefwolf.widget.slotpos, Vector3(72 * x, 175 - 72 * y, 0))
            table.insert(containers.params.atbook_chefwolf.widget.slotbg,
                { image = "icon_gz_3.tex", atlas = "images/ui/container/icon_gz_3.xml" })
        elseif x == 1 or x == -1 then
            table.insert(containers.params.atbook_chefwolf.widget.slotpos, Vector3(72 * x, 175 - 72 * y, 0))
            table.insert(containers.params.atbook_chefwolf.widget.slotbg,
                { image = "icon_gz_1.tex", atlas = "images/ui/container/icon_gz_1.xml" })
        end
    end
end

for y = 0, 6 do
    for x = 0, 4 do
        table.insert(containers.params.atbook_chefwolf.widget.slotpos, Vector3(170 + 72 * x, 175 - 72 * y, 0))
        table.insert(containers.params.atbook_chefwolf.widget.slotbg,
            { image = "icon_gz_3.tex", atlas = "images/ui/container/icon_gz_3.xml" })
    end
end

for k, v in pairs(containers.params) do
    containers.params[k] = v
    --更新容器格子数量的最大值
    containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, v.widget.slotpos ~= nil and #v.widget.slotpos or 0)
end

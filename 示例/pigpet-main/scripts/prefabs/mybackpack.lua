local assets=
{
    Asset("ATLAS", "images/inventoryimages/mybackpack.xml")
}

local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_body", "swap_backpack", "backpack")
    owner.AnimState:OverrideSymbol("swap_body", "swap_backpack", "swap_body")
    owner.components.inventory:SetOverflow(inst)
    inst.components.container:Open(owner)
    
end

local function onunequip(inst, owner) 
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.AnimState:ClearOverrideSymbol("backpack")
    owner.components.inventory:SetOverflow(nil)
    inst.components.container:Close(owner)
end


local function onopen(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/backpack_open", "open")
end

local function onclose(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/backpack_close", "open")
end


local function fn(Sim)
	local inst = CreateEntity()
    
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("backpack1")
    inst.AnimState:SetBuild("backpack")
    inst.AnimState:PlayAnimation("anim")
    inst:AddTag("fridge")
    inst:AddTag("backpack")
	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetIcon("backpack.png")
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.foleysound = "dontstarve/movement/foley/backpack"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/mybackpack.xml" -- 设置物品栏图片文档。官方内置的物体有默认的图片文档，所以不需要设置这一项，但自己额外添加的物体使用自己的图片文档，就应该设置这一项

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BACK
    
    inst.components.equippable:SetOnEquip( onequip )
    inst.components.equippable:SetOnUnequip( onunequip )
    
    
    --添加一个容器，可以用房物品     
    inst:AddComponent("container")
    local slotpos = {}
    local x_offset = (-72-72-40-2)*2

    --3行15列
    for x = 1, 3 do
       for y=1, 25 do
        table.insert(slotpos, Vector3(72*y +x_offset, 72*x -2-40-72-36, 0))
       end
    end

    inst.components.container:SetNumSlots(#slotpos)      
    inst.components.container.widgetslotpos = slotpos
    inst.components.container.widgetanimbank = "ui_chest_3x3"
    -- inst.components.container.widgetanimbuild = "ui_portablecellar"
    inst.components.container.widgetpos = Vector3(-340, -395, 0)
    inst.components.container.side_align_tip = 0
    inst.components.container.type = "pack"
   
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose

    
    return inst
end

return Prefab( "common/mybackpack", fn, assets) 

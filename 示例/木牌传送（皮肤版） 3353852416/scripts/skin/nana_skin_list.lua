GLOBAL.setmetatable(env,{__index = function(t, k)return GLOBAL.rawget(GLOBAL,k)end,})

modimport("scripts/skin/skinsapi.lua")--调用皮肤api  来自穹

local item_list =            --有皮肤的物品代码
{
"teleportation",
}

local pifu_list =            --对应的皮肤
{   
	
	{"teleportation","t2",STRINGS.NANA_TELEPORT_TYGGJ},
	{"teleportation","t3",STRINGS.NANA_TELEPORT_MSNLB},
	{"teleportation","t4",STRINGS.NANA_TELEPORT_HDT},
	{"teleportation","t5",STRINGS.NANA_TELEPORT_NWSFS},
	{"teleportation","t6",STRINGS.NANA_TELEPORT_KGLXZ},
	{"teleportation","t7",STRINGS.NANA_TELEPORT_T7},
	{"teleportation","t8",STRINGS.NANA_TELEPORT_T8},
	{"teleportation","t9",STRINGS.NANA_TELEPORT_T9},
	{"teleportation","t10",STRINGS.NANA_TELEPORT_T10},


	
}



--开始注册:
for k,v in pairs (item_list) do  --注册默认皮肤
	MakeItemSkinDefaultImage( v,"images/inventoryimages/"..v..".xml", v)
	RegisterInventoryItemAtlas("images/inventoryimages/"..v..".xml", v..".tex")
end

for k,v in pairs (pifu_list) do
	RegisterInventoryItemAtlas("images/inventoryimages/"..v[2]..".xml", v[2]..".tex")  --注册皮肤
	MakeItemSkin( v[1], v[2],--原名和皮肤名
    {
	   basebuild = v[1],    --原物品scml文件名字
	   rarity = "NANA", --珍惜度:没有什么意义,是啥都行,可以随便编一个
	   type = "item",       --类别
	   name = v[3],         --填皮肤的名称:经典,小熊,小猫,小狗什么的
	  -- atlas = "images/inventoryimages/"..v[2]..".xml",  --制作栏的图片
       image = v[2],
    })
end

	MakeItemSkin("teleportation","t1",{
        name = STRINGS.NANA_TELEPORT_MFM,
        atlas = "images/inventoryimages/t1.xml",
        image = "t1",
        build = "t1",
        bank = "t1",
        basebuild = "teleportation",--基础build就是原皮的
        basebank = "teleportation",--同上
    })
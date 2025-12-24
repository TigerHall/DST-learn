GLOBAL.Pigpet = {}

Assets = 
{
    Asset("IMAGE", "images/recipe_hud.tex"),
	Asset("ATLAS", "images/recipe_hud.xml"),
    Asset( "IMAGE", "images/beefalo.tex" ),
    Asset( "ATLAS", "images/beefalo.xml" ),
    Asset("IMAGE", "images/slots5.tex"),
	Asset("ATLAS", "images/slots5.xml"),
    Asset("IMAGE", "images/status_bgs.tex"),
	Asset("ATLAS", "images/status_bgs.xml"),
    Asset("ATLAS", "images/inventoryimages/pigpetfood.xml"),
    Asset( "IMAGE", "images/carrot_planted.tex" ),
    Asset( "ATLAS", "images/carrot_planted.xml" ),
    Asset( "IMAGE", "images/flint.tex" ),
    Asset( "ATLAS", "images/flint.xml" ),
    Asset( "IMAGE", "images/rabbithole.tex" ),
    Asset( "ATLAS", "images/rabbithole.xml" ),
    
    Asset( "ATLAS", "images/iai_ing_plus.xml" ),
    Asset( "IMAGE", "images/iai_ing_plus.tex" ),
    
}

GLOBAL.Pigpet.pickPrefeb = {
    sapling = "twigs",
    flower = "petals",
    grass = "cutgrass",
    carrot_planted = "carrot",
    berrybush = "berries",
    asparagus_planted = "asparagus",
    radish_planted = "radish",
    flower_rainforest = "petals",
    rock_flippable = "rocks",
    dungpile = "poop",
    aloe_planted = "aloe",
}

GLOBAL.Pigpet.growth = {}

GLOBAL.Pigpet.notPickPrefeb = {
    "heatrock",
    "spoiled_food",
    "wetgoop"
}

GLOBAL.Pigpet.notPickTag = {
    "trap",
    "backpack"
}

GLOBAL.Pigpet.homesigns = {}

--声明预制物
PrefabFiles = {
    "pigpet",
    "mybackpack",
    "pigpetfood"
}

local pigpetfood
if GLOBAL.IsDLCEnabled(GLOBAL.CAPY_DLC) or GLOBAL.IsDLCEnabled(GLOBAL.PORKLAND_DLC) then
    pigpetfood = GLOBAL.Recipe("pigpetfood",  {GLOBAL.Ingredient("cutgrass", 10), GLOBAL.Ingredient("twigs", 10)}, GLOBAL.RECIPETABS.SURVIVAL, GLOBAL.TECH.NONE, nil, nil, nil, nil, 10)
else
    pigpetfood = GLOBAL.Recipe("pigpetfood",   {GLOBAL.Ingredient("cutgrass", 10), GLOBAL.Ingredient("twigs", 10)}, GLOBAL.RECIPETABS.SURVIVAL, GLOBAL.TECH.NONE, nil, 10) 
end

pigpetfood.atlas = "images/inventoryimages/pigpetfood.xml"

--0 正常 1 禁用 2 隐藏
GLOBAL.Pigpet.Status = 0
GLOBAL.STRINGS.NAMES.PIGPET = "皮皮熊"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.PIGPET = "我是一只宠物" -- 物体的检查描述


GLOBAL.STRINGS.NAMES.MYBACKPACK = "超级大背包"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.MYBACKPACK = "超级大，永久保鲜" 


GLOBAL.STRINGS.NAMES.PIGPETFOOD = "宠物饲料"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.PIGPETFOOD = "这是给宠物吃的，可以恢复生命值"
GLOBAL.STRINGS.RECIPE_DESC.PIGPETFOOD = "可以恢复宠物生命值20点"


modimport("scripts/show_info.lua")
modimport("scripts/extra_equipment.lua")
modimport("scripts/travel.lua")




local function AttachAttackRangeIndicator(inst)
   local attackrange = inst.components.combat:GetAttackRange()
   
   if attackrange > 0 then  -- 仅处理有攻击范围的实体
        local indicator = GLOBAL.CreateEntity()
        indicator:AddTag("NOCLICK")  -- 不可点击
        indicator:AddTag("FX")       -- 标记为特效
        indicator.entity:AddTransform()
        indicator.entity:AddAnimState()
        
        -- 设置纹理（复用firefighter_placement资源）
        local animstate = indicator.entity:AddAnimState()
        animstate:SetBank("firefighter_placement")
        animstate:SetBuild("firefighter_placement")
        animstate:PlayAnimation("idle")
        animstate:SetOrientation(GLOBAL.ANIM_ORIENTATION.OnGround)  -- 平面显示（贴地）
        animstate:SetLayer(GLOBAL.LAYER_BACKGROUND)       -- 显示在地面层（不遮挡实体）
        animstate:SetSortOrder(3)                         -- 排序层级（确保可见）
        animstate:SetMultColour(1, 0, 0, 1)             -- 绿色半透明（R:0, G:1, B:0, 透明度1）

        indicator.persists = false
        indicator.entity:SetParent(inst.entity)

         -- 核心：计算缩放比例，使圆圈半径匹配攻击范围
        local scale = attackrange / GLOBAL.TUNING.FIRE_DETECTOR_RANGE * 3  -- 计算所需缩放比例
        indicator.Transform:SetScale(scale, scale, scale) 
    end
end

--监听所有预制物的构造
AddPrefabPostInitAny(function(inst)
    --如果可以堆叠
    if not inst.components then
        return
    end

    if inst.components.stackable then
        --设置最大堆叠999
        inst.components.stackable.maxsize = 999
    end
    --如果是装备，则增加 tradable 组件
    if inst.components.equippable then
        inst:AddComponent("tradable") 
    end

    if inst.components.combat then
        AttachAttackRangeIndicator(inst)
    end
end)

--冰箱不会腐烂
TUNING.PERISH_FRIDGE_MULT = 0
--
--监听是否已经有背包了
AddPrefabPostInit("mybackpack", function(inst)
    GLOBAL.Pigpet.mybackpack = inst
end)

--监听pigpet构造    
AddPrefabPostInit("pigpet", function(inst)
    GLOBAL.Pigpet.pet = inst
end)

local function CreatePigpetIfnot()
    if not GLOBAL.Pigpet.pet then
        GLOBAL.SpawnPrefab("pigpet")
    end

    local player = GLOBAL.GetPlayer()
    GLOBAL.Pigpet.pet.Transform:SetPosition(player.Transform:GetWorldPosition())
    GLOBAL.Pigpet.pet.components.follower:SetLeader(player)

    GLOBAL.Pigpet.Status = 0
     --监听pigpet 死亡事件
    GLOBAL.Pigpet.pet:ListenForEvent("death", function(inst)
        --player 说一句话
        player.components.talker:Say("皮皮熊死了，1分钟后自动复活")
       --启动一个5秒钟的一次性定时器
        player:DoTaskInTime(60, function() 
            CreatePigpetIfnot()
        end)
    end)
end

local function CreateMyBackpack()
    local player = GLOBAL.GetPlayer()
    if not GLOBAL.Pigpet.mybackpack then
        GLOBAL.SpawnPrefab("mybackpack")
    end
    player.components.inventory:Equip(GLOBAL.Pigpet.mybackpack)
end

local function ShowFullMap(inst)
    --读取 show_global_map 配置，判断是否开启地图
    local show_global_map = GetModConfigData("show_global_map")
    if not show_global_map then
        return
    end
    inst:DoTaskInTime( 0.001, function() 
        minimap = TheSim:FindFirstEntityWithTag("minimap")
        minimap.MiniMap:ShowArea(0,0,0,40000)
    end)
end

--监听世界的构造
AddSimPostInit(function(inst)
   --CreatePigpetIfnot()
   ShowFullMap(inst)
   CreateMyBackpack()
end)

local cookbook_screen = GLOBAL.require("cookbook_screen")
local arrange = GLOBAL.require("arrange")

GLOBAL.TheInput:AddKeyHandler(function(key, down)
   if key == GLOBAL.KEY_F1 and not down then       
        local screen = TheFrontEnd:GetActiveScreen()
        -- End if we can't find the screen name (e.g. asleep)
        if not screen or not screen.name then return true end
        -- If the hud exists, open the UI
        if screen.name:find("HUD") then
            -- We want to pass in the (clientside) player entity         
            TheFrontEnd:PushScreen(cookbook_screen())
            return true
        else
            -- If the screen is already open, close it
            if screen.name == "CookbookScreen" then
                screen:OnClose()
            end
        end
    elseif key == GLOBAL.KEY_F2 and not down then   
        GLOBAL.Pigpet.Status = GLOBAL.Pigpet.Status + 1
        if GLOBAL.Pigpet.Status > 2 then
            GLOBAL.Pigpet.Status = 0
            GLOBAL.Pigpet.pet:Show()
        end  
        if GLOBAL.Pigpet.Status == 2 then
            --隐藏宠物
            GLOBAL.Pigpet.pet:Hide()
        end
    elseif key == GLOBAL.KEY_F3 and not down then
        arrange()
    elseif key == GLOBAL.KEY_F5 and not down then
        GLOBAL.GetPlayer().components.autosaver:DoSave()
    elseif key == GLOBAL.KEY_F6 and not down then
        GLOBAL.Settings.save_slot = GLOBAL.SaveGameIndex.saveslot
		GLOBAL.SetPause(true)
		GLOBAL.StartNextInstance({reset_action=GLOBAL.RESET_ACTION.LOAD_SLOT, save_slot = GLOBAL.SaveGameIndex:GetCurrentSaveSlot()}, true)
		GLOBAL.SetPause(false)
    end
end)    

AddPlayerPostInit(function(inst)
    inst:AddTag("fridge")
end)

--获取关闭自动保存配置，如果关闭了，将 AUTOSAVE_INTERVAL 设置无限大
local disableautosave = GetModConfigData("disableautosave")
if disableautosave then
    GLOBAL.TUNING.AUTOSAVE_INTERVAL = 99999999999
end

--读取配置，如果死亡不删除档案，将删除档案的方法替换为一个空方法
local disabledeleteondeath = GetModConfigData("disabledeleteondeath")
if disabledeleteondeath then
    function GLOBAL.SaveIndex:EraseCurrent(cb)
        GLOBAL.GetPlayer():DoTaskInTime(2, function()
            GLOBAL.TheFrontEnd:Fade(false,1)
        end )
        GLOBAL.GetPlayer():DoTaskInTime(5, function()
            GLOBAL.StartNextInstance({reset_action=GLOBAL.RESET_ACTION.LOAD_SLOT, save_slot = GLOBAL.SaveGameIndex:GetCurrentSaveSlot()}, true)
        end )
    end
end


--一键制作
local ImageButton = GLOBAL.require "widgets/imagebutton"
AddClassPostConstruct("widgets/ingredientui", function(self, ...)
     local args = {...}
        if #args > 0 then
            --v:GetAtlas(imageName), imageName, v.amount, num_found, has, STRINGS.NAMES[string.upper(v.type)], owner
            -- 先获取名字， 公国imageName 分割出.tex 前面的部分
            local prefab = args[2]
            local owner = args[7]
            local dot_index = string.find(prefab, "%.tex")
            if dot_index then
                prefab = string.sub(prefab, 1, dot_index - 1)
            end
            -- 获取配方
            local all_receipes = AllRecipes or GLOBAL.GetAllRecipes()
            local receipe = all_receipes[prefab]
            if receipe == nil then
            return
        end
            -- 如果需要多个材料的才需要添加按钮
            local need_add = true
            local show_ingredients = true
            if #receipe.ingredients == 1 and receipe.ingredients[1].amount ==1 then
                need_add = false
                show_ingredients = false
            end
            if need_add then
                for _, ingredient in ipairs(receipe.ingredients) do
                    -- 判断材料是否足够
                    if not owner.components.inventory:Has(ingredient.type, GLOBAL.RoundUp(ingredient.amount * owner.components.builder.ingredientmod), true) then
                        need_add = false
                        break
                    end
                end
            end

            if need_add then
                self.doAction = self:AddChild(ImageButton("images/iai_ing_plus.xml", "iai_ing_plus.tex", "iai_ing_plus.tex", "iai_ing_plus.tex"))
                self.doAction:SetPosition(-20, 20)
                    self.doAction:MoveToFront()
                    self.doAction:SetOnClick(function()
                    GLOBAL.DoRecipeClick(owner, GLOBAL.Recipes[prefab])
                    end)
                end
            if show_ingredients then
                --显示所有材料
                local ingredient_str = ""
                for _, ingredient in ipairs(receipe.ingredients) do
                    if ingredient.type ~= nil then             
                        ingredient_str = ingredient_str .. tostring(ingredient.amount) .. "x" .. GLOBAL.STRINGS.NAMES[string.upper(ingredient.type)] .. " "
                end
                end
                self:SetTooltip(ingredient_str)
            end
        end
end)




local TopBanner = GLOBAL.require "widgets/top_banner"
local Image = GLOBAL.require "widgets/image"

AddClassPostConstruct("widgets/controls", function(self)
    -- 如果已存在则移除旧的
    if self.top_banner and self.top_banner.Kill then
        self.top_banner:Kill()
        self.top_banner = nil
    end

    -- 创建并添加 banner（初始文本）
    self.top_banner = self.sidepanel:AddChild(TopBanner(""))
    self.top_banner:SetPosition(-300,0,0)
    -- 暴露到 self 以便其它代码更新文本： self.top_banner:SetString("新的文本")


    --self.easy_build_panel = self.bottom_root:AddChild(ImageButton(GLOBAL.resolvefilepath(GLOBAL.GetInventoryItemAtlas("axe.xml")), "axe.tex", "axe.tex", "axe.tex"))
    --self.easy_build:SetPosition(200, -50)
    --[[self.right_root = self:AddChild(Image("images/hud.xml", "craft_bg.tex"))
    self.right_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.right_root:SetHAnchor(ANCHOR_RIGHT)
    self.right_root:SetVAnchor(ANCHOR_MIDDLE)
    self.right_root:SetMaxPropUpscale(MAX_HUD_SCALE)  --]]   
end)
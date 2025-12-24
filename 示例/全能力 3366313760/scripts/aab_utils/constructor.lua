--@author: 绯世行
--使用案例及最新版：https://n77a3mjegs.feishu.cn/docx/K9bUdpb5Qo85j2xo8XkcOsU1nuh?from=from_copylink

--初始化时调用

local FN = {}
local _source = debug.getinfo(1, 'S').source
local KEY = "_" .. _source:match(".*scripts[/\\](.*)%.lua"):gsub("[/\\]", "_") .. "_"

local Utils = require(_source:match(".*scripts[/\\](.*[/\\])") .. "utils")

local env --环境变量，需要手动赋值

function FN.SetEnv(newEnv)
    env = newEnv
end

---按照一定的格式创建一个基础的预制体，适用于那些功能简单的预制体
---@param name string 预制体名
---@param data table|nil
function FN.MakePrefab(name, data)
    data = data or {}
    local basename = Utils.GetVal(data, "basename", name)
    local assets = Utils.GetVal(data, "assets")         --默认name名字的动画资产、如果是物品的话还有物品栏贴图
    local prefabs = Utils.GetVal(data, "prefabs")
    local bank = Utils.GetVal(data, "bank", basename)   --默认name
    local build = Utils.GetVal(data, "build", basename) --默认name
    local common_init = Utils.GetVal(data, "common_init")
    local master_init = Utils.GetVal(data, "master_init")
    local ishat = Utils.GetVal(data, "ishat", false)
    local isitem = Utils.GetVal(data, "isitem", ishat)                  --是否是一个物品，如果为true会默认图片路径为images/inventoryimages/，图片名为name
    local anim = Utils.GetVal(data, "anim", ishat and "anim" or "idle") --默认播放动画，默认idle
    local minimap = Utils.GetVal(data, "minimap", false)

    if not assets then
        assets = { Asset("ANIM", "anim/" .. build .. ".zip") }
    end

    if isitem then
        table.insert(assets, Asset("ATLAS", "images/inventoryimages/" .. basename .. ".xml"))
        table.insert(assets, Asset("ATLAS_BUILD", "images/inventoryimages/" .. basename .. ".xml", 256)) --小木牌和展柜使用
        RegisterInventoryItemAtlas("images/inventoryimages/" .. basename .. ".xml", basename .. ".tex")
    end
    if minimap then
        -- table.insert(assets, Asset("MINIMAP_IMAGE", name))
        table.insert(assets, Asset("ATLAS", "images/map_icons/" .. basename .. ".xml"))
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        if minimap then
            inst.entity:AddMiniMapEntity()
            inst.MiniMapEntity:SetIcon(basename .. ".tex")
        end
        inst.entity:AddNetwork()

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)

        if ishat then
            inst:AddTag("hat")

            MakeInventoryFloatable(inst)
            inst.components.floater:SetBankSwapOnFloat(false, nil, { bank = bank, anim = anim }) --Hats default animation is not "idle", so even though we don't swap banks, we need to specify the swap_data for re-skinning to reset properly when floating
            inst.components.floater:SetSize("med")
            inst.components.floater:SetVerticalOffset(0.1)
        end


        if isitem then
            MakeInventoryPhysics(inst)
        end

        if common_init ~= nil then
            common_init(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        if isitem then
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.atlasname = "images/inventoryimages/" .. basename .. ".xml"

            inst:AddComponent("inspectable")
        end

        if ishat then
            inst:AddComponent("tradable")

            inst:AddComponent("equippable")
            inst.components.equippable.equipslot = EQUIPSLOTS.HEAD

            MakeHauntableLaunch(inst)
        end

        if master_init ~= nil then
            master_init(inst)
        end

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

----------------------------------------------------------------------------------------------------

---拷贝原版brain对象，不会受到AddBrainPostInit的影响。
---在增强游戏已有brain时使用，防止使用的brain被其他mod不小心初始化了
---@param requirePath string 调用require的参数
---@param initFn function|nil 如果原brain在构造器里初始化了一些属性，可以在该函数里初始化
---@return Brain brain
function FN.CopyBrainFn(requirePath, initFn)
    local NewBrain = Class(Brain, function(self, inst)
        Brain._ctor(self, inst)
        if initFn then
            initFn(self)
        end
    end)

    local brain = require(requirePath)
    for k, v in pairs(brain) do
        if type(v) == "function" then
            NewBrain[k] = v
        end
    end

    return NewBrain
end

----------------------------------------------------------------------------------------------------

function FN.OnHatEquip(inst, owner, fname, symbol_override)
    owner.AnimState:OverrideSymbol("swap_hat", fname, symbol_override or "swap_hat")

    if inst.components.fueled ~= nil then
        inst.components.fueled:StartConsuming()
    end

    owner.AnimState:ClearOverrideSymbol("headbase_hat") --clear out previous overrides

    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
        owner.AnimState:Show("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end
end

function FN.OnHatUnequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    owner.AnimState:ClearOverrideSymbol("headbase_hat") --it might have been overriden by _onequip
    if owner.components.skinner ~= nil then
        owner.components.skinner.base_change_cb = owner.old_base_change_cb
    end

    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
end

function FN.OpenTopOnEquip(owner)
    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    owner.AnimState:Show("HEAD")
    owner.AnimState:Hide("HEAD_HAT")
    owner.AnimState:Hide("HEAD_HAT_NOHELM")
    owner.AnimState:Hide("HEAD_HAT_HELM")
end

function FN.FullHelmOnEquip(owner)
    if owner:HasTag("player") then
        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")

        owner.AnimState:Hide("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Show("HEAD_HAT_HELM")

        owner.AnimState:HideSymbol("face")
        owner.AnimState:HideSymbol("swap_face")
        owner.AnimState:HideSymbol("beard")
        owner.AnimState:HideSymbol("cheeks")

        -- owner.AnimState:UseHeadHatExchange(true)
    else
        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")
    end
end

function FN.FullHelmOnUnEquip(inst, owner)
    FN.OnHatUnequip(inst, owner)

    if owner:HasTag("player") then
        owner.AnimState:ShowSymbol("face")
        owner.AnimState:ShowSymbol("swap_face")
        owner.AnimState:ShowSymbol("beard")
        owner.AnimState:ShowSymbol("cheeks")

        owner.AnimState:UseHeadHatExchange(false)
    end
end

---添加Actions，写个方法省事点，需要env
---@param data table|nil
---@param id string
---@param str string|function
---@param fn function
---@param wilsonAction string|nil
---@param wilsonClientAction string|nil
function FN.AddAction(data, id, str, fn, wilsonAction, wilsonClientAction)
    local action = Action(data)
    action.id = id
    local oldActionStr
    if type(str) == "function" then
        -- action.stroverridefn = str --不用这个，这个需要直接返回文本
        action.strfn = str
        oldActionStr = STRINGS.ACTIONS[string.upper(id)]
    else
        action.str = str
    end

    action.fn = fn
    env.AddAction(action)
    --AddAction里面会直接覆盖STRINGS.ACTIONS，真麻烦
    STRINGS.ACTIONS[string.upper(id)] = oldActionStr or STRINGS.ACTIONS[string.upper(id)]

    if wilsonAction then
        env.AddStategraphActionHandler("wilson", ActionHandler(action, wilsonAction))
    end
    if wilsonClientAction then
        env.AddStategraphActionHandler("wilson_client", ActionHandler(action, wilsonClientAction))
    end
    return action
end

----------------------------------------------------------------------------------------------------
-- 图鉴形式展示wiki

local addScrapbookWikiDirty = true
---用图鉴的形式展示wiki，一般来说只在最开始的时候调用一次，调用该方法需要设置env
---实现该功能不得不覆盖了ScrapbookScreen的MakeSideBar方法，追加图鉴分类，这导致以后可能需要维护
---@param type string 新增的图鉴分类，建议与mod名保持一致，需要初始化STRINGS.SCRAPBOOK.CATS.XXX变量，XXX是这里的key大写形式
---@param data table 配置
function FN.AddScrapbookWiki(type, data)
    if addScrapbookWikiDirty then
        env.RegisterScrapbookIconAtlas("images/inventoryimages3.xml", "unknown_hand.tex")
        addScrapbookWikiDirty = nil
    end

    -- 添加分类
    table.insert(SCRAPBOOK_CATS, type)

    -- 设置数据
    local dataset = require("screens/redux/scrapbookdata")
    for key, d in pairs(data) do
        dataset[key] = d

        -- 偷个懒，设置默认值
        d.type = type
        d.name = d.name or key
        d.specialinfo = d.specialinfo or string.upper(key)
        d.prefab = d.prefab or key
        d.build = d.build or ""
        d.bank = d.bank or ""
        d.anim = d.anim or ""
        d.tex = d.tex or "unknown_hand.tex"

        -- 图鉴图标
        if d.atlas then
            env.RegisterScrapbookIconAtlas(d.atlas, d.tex)
        end
    end

    -- 追加图鉴分类
    local ScrapbookScreen = require("screens/redux/scrapbookscreen")
    local ImageButton = require "widgets/imagebutton"
    local Text = require "widgets/text"
    local Image = require "widgets/image"
    local Widget = require "widgets/widget"
    local UIAnim = require "widgets/uianim"
    local PANEL_HEIGHT = 530
    Utils.FnDecorator(ScrapbookScreen, "MakeSideBar", nil, function(retTab, self)
        local colors = {
            { 114 / 255, 56 / 255, 56 / 255 },
            { 111 / 255, 85 / 255, 47 / 255 },
            { 137 / 255, 126 / 255, 89 / 255 },
            { 95 / 255, 123 / 255, 87 / 255 },
            { 113 / 255, 127 / 255, 126 / 255 },
            { 74 / 255, 84 / 255, 99 / 255 },
            { 79 / 255, 73 / 255, 107 / 255 },
        }

        local button = { name = type, filter = type }
        local index = #self.menubuttons + 1 --索引

        local idx = index % #colors
        if idx == 0 then idx = #colors end
        button.color = colors[idx]


        local buttonwidth = 252 / 2.2  --75
        local buttonheight = 112 / 2.2 --30
        local totalheight = PANEL_HEIGHT - 100

        local MakeButton = function(idx, data)
            local y = totalheight / 2 - ((totalheight / 7) * idx - 1) + 50

            local buttonwidget = self.root:AddChild(Widget())

            local button = buttonwidget:AddChild(ImageButton("images/scrapbook.xml", "tab.tex"))
            button:ForceImageSize(buttonwidth, buttonheight)
            button.scale_on_focus = false
            button.basecolor = { data.color[1], data.color[2], data.color[3] }
            button:SetImageFocusColour(math.min(1, data.color[1] * 1.2), math.min(1, data.color[2] * 1.2),
                math.min(1, data.color[3] * 1.2), 1)
            button:SetImageNormalColour(data.color[1], data.color[2], data.color[3], 1)
            button:SetImageSelectedColour(data.color[1], data.color[2], data.color[3], 1)
            button:SetImageDisabledColour(data.color[1], data.color[2], data.color[3], 1)
            button:SetOnClick(function()
                self:SelectSideButton(data.filter)
                self.current_dataset = self:CollectType(dataset, data.filter)
                self.current_view_data = self:CollectType(dataset, data.filter)
                self:SetGrid()
            end)

            buttonwidget.focusimg = button:AddChild(Image("images/scrapbook.xml", "tab_over.tex"))
            buttonwidget.focusimg:ScaleToSize(buttonwidth, buttonheight)
            buttonwidget.focusimg:SetClickable(false)
            buttonwidget.focusimg:Hide()

            buttonwidget.selectimg = button:AddChild(Image("images/scrapbook.xml", "tab_selected.tex"))
            buttonwidget.selectimg:ScaleToSize(buttonwidth, buttonheight)
            buttonwidget.selectimg:SetClickable(false)
            buttonwidget.selectimg:Hide()

            buttonwidget:SetOnGainFocus(function()
                buttonwidget.focusimg:Show()
            end)
            buttonwidget:SetOnLoseFocus(function()
                buttonwidget.focusimg:Hide()
            end)

            local text = button:AddChild(Text(HEADERFONT, 12, STRINGS.SCRAPBOOK.CATS[string.upper(data.name)],
                UICOLOURS.WHITE))
            text:SetPosition(10, -8)
            buttonwidget:SetPosition(522 + buttonwidth / 2, y)

            local total = 0
            local count = 0
            for i, set in pairs(dataset) do
                if set.type == data.filter then
                    total = total + 1
                    if set.knownlevel > 0 then
                        count = count + 1
                    end
                end
            end
            if total > 0 then
                local percent = (count / total) * 100
                if percent < 1 then
                    percent = math.floor(percent * 100) / 100
                else
                    percent = math.floor(percent)
                end

                local progress = buttonwidget:AddChild(Text(HEADERFONT, 18, percent .. "%", UICOLOURS.GOLD))
                progress:SetPosition(15, 17)
            end

            buttonwidget.newcreatures = {}

            buttonwidget.flash = buttonwidget:AddChild(UIAnim())
            buttonwidget.flash:GetAnimState():SetBank("cookbook_newrecipe")
            buttonwidget.flash:GetAnimState():SetBuild("cookbook_newrecipe")
            buttonwidget.flash:GetAnimState():PlayAnimation("anim", true)
            buttonwidget.flash:GetAnimState():SetScale(0.15, 0.15, 0.15)
            buttonwidget.flash:SetPosition(40, 0, 0)
            buttonwidget.flash:Hide()
            buttonwidget.flash:SetClickable(false)

            buttonwidget.filter = data.filter
            buttonwidget.focus_forward = button

            table.insert(self.menubuttons, buttonwidget)
        end

        MakeButton(index, button)
    end)

    Utils.FnDecorator(ScrapbookScreen, "SetPlayerKnowledge", nil, function()
        for _, d in pairs(data) do
            d.knownlevel = 2 --默认解锁
        end
    end)
end

-- 给出AddScrapbookWiki方法的使用示例
-- local Constructor = require("ptribe_utils/constructor")
-- Constructor.SetEnv(env) --工具文件拿不到mod函数，需要把env传给它
-- Constructor.AddScrapbookWiki("ptribeTribe", {
--     name = "猪人部落", --图鉴分类名
--     items = {
--         -- 所有值都可省，只需要确保STRINGS.NAMES.XXX1和STRINGS.SCRAPBOOK.SPECIALINFO.XXX2有值就行，XXX1和XXX2分别是name和specialinfo的值，不填都默认为键值
--         deed = {
--             name = "deed",                                              --用于查找预制体名，默认与键值保持一致
--             atlas = "images/inventoryimages/hamletinventoryimages.xml", --图片的atlas，方法自动调用RegisterScrapbookIconAtlas
--             tex = "deed.tex",                                           --右侧选项图标，需要使用RegisterScrapbookIconAtlas注册物品图标
--             prefab = "deed",                                            --用于游戏监听玩家解锁用，这里填空也没事，wiki的图鉴不需要解锁，如果是存在的预制体下面还会显示是否可制作、每个人对该物品的描述，默认key一致（预制体不存在也不会报错）
--             -- 动画展示
--             build = "deed",
--             bank = "deed",
--             anim = "idle",
--             animoffsetbgx = 60, --修改动画偏移，如果动画不在正中心，可用这个变量进行偏移
--             animoffsetbgy = 20, --修改动画偏移，如果动画不在正中心，可用这个变量进行偏移
--             scale = 1,
--             deps = { "oinc" }, --相关物品，点击物品图标就可以导航到对应图鉴，对方也可以导航到自己页面
--             specialinfo = "DEED", --补充说明，对应STRINGS.SCRAPBOOK.SPECIALINFO.XXX变量的XXX，这应该作为mod wiki的重点
--             subcat = "trinket", --名称分类，就是在名称的前面加一级分类
--             -- 词条，词条种类可在scrapbookscreen.lua查找，词条使用可在scrapbookdata.lua查找
--             health = 150, --生命
--             damage = "15-40", --攻击力
--             sanityaura = 1.6666666666667, --理智光环
--             -- type = "", --这个是图鉴所属分类，不需要填写，方法会自动分类到mod的wiki类别里
--             stacksize = 40, --最大堆叠数
--             hungervalue = 20, --食物回饥饿数值
--             healthvalue = 20, --食物回血数值
--             sanityvalue = 0, --食物回理智数值
--             foodtype = "VEGGIE", --食物类型
--             weapondamage = 27.2, --武器伤害
--             planardamage = 200, --位面伤害
--             areadamage = 120, --范围伤害
--             weaponrange = 10, --武器攻击范围
--             finiteuses = 10, --耐久
--             toolactions = { "CHOP" }, --可进行的操作：砍、挖、凿、锤
--             armor = 945, --护甲值
--             absorb_percent = 0.8, --护甲防御/减伤
--             armor_planardefense = 10, --位面防御
--             forgerepairable = { "lunarplant_kit" }, --修理方式，可用什么修理
--             repairitems = { "cutgrass" }, --可用什么修复
--             waterproofer = 0.2, --防水百分比
--             insulator = 60, --隔热或防寒值
--             insulator_type = "summer", --隔热或防寒类型
--             dapperness = 0.033333333333333, --理智恢复速度
--             fueledrate = 1, --耐久度消耗倍率
--             fueledmax = 3840, --耐久度最大值
--             fueledtype1 = "USAGE", --耐久度类型
--             fueleduses = true, --是否可填充耐久
--             fueledtype2 = "CHEMICAL", --耐久度类型
--             fueltype = "BURNABLE", --燃料类型
--             fuelvalue=180, --燃料值
--             sewable = true, --是否可用缝纫包修复
--             perishable = 960, --新鲜值，会转换为腐烂天数
--             notes = { shadow_aligned = true }, --月亮或暗影阵营
--             lightbattery = true, --发光
--             float_range = 9, --施法范围
--             float_accuracy = 0.1, --鱼饵准确性
--             lure_charm = 0.1, --鱼饵诱饵吸引力
--             lure_dist = 1, --额外范围
--             lure_radius = 5, --诱饵半径
--             oar_force = 0.8, --划船力量
--             oar_velocity = 5, --划船最大速度
--             workable = "CHOP", --可以被执行的操作
--             fishable = true, --可以被钓鱼，例如湖泊
--             picakble = true, --可以采摘
--             harvestable = true, --可以收获
--             stewer = true, -- 可以烹饪
--             activatable = "CALM", --激活类型，对于可交互的物品的交互操作，例如伯尼可以安抚，胡萝卜可以右键旋转，空芯树桩可以洗劫
--             burnable = true, --是否可燃
--             pickable=true, --是否可采集
--         },
--     }
-- })

----------------------------------------------------------------------------------------------------
---拷贝一个已有prefab，并创建新的prefab
---@param newPrefab string 新的预制体名
---@param oldprefab string 已有的预制体名
---@param data table|nil
function FN.CopyPrefab(newPrefab, oldprefab, data)
    local assets = Utils.GetVal(data, "assets", {})   --资产
    local prefabs = Utils.GetVal(data, "prefabs", {}) --预制体
    local init = Utils.GetVal(data, "init")           --初始化，不用返回inst

    local oldPrefab = Prefabs[oldprefab]

    table.insert(prefabs, oldprefab)
    ConcatArrays(assets, oldPrefab.assets)

    local function newFn(...)
        local inst = oldPrefab.fn(...)
        if init then
            init(inst, ...)
        end
        return inst
    end

    return Prefab(newPrefab, newFn, assets, prefabs)
end

return FN

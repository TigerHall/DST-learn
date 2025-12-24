local hardmode = TUNING.hardmode2hm and GetModConfigData("role_nerf")
-- 薇克巴顿不失眠
if GetModConfigData("Wickerbottom Is Not Insomniac") then 
    AddPrefabPostInit("wickerbottom", function(inst) inst:RemoveTag("insomniac") end) 
end

-- 薇克巴顿免疫装备/怪物/黑夜三种掉理智
if GetModConfigData("Wickerbottom No Sanity Dapperness") then
    local function GetEquippableDapperness(owner, equippable)
        local dapperness = equippable:GetDapperness(owner, owner.components.sanity.no_moisture_penalty)
        return dapperness < 0 and 0 or dapperness
    end
    AddPrefabPostInit("wickerbottom", function(inst)
        if not TheWorld.ismastersim then return end
        inst.components.sanity:SetNegativeAuraImmunity(true)
        inst.components.sanity:SetPlayerGhostImmunity(true)
        inst.components.sanity:SetLightDrainImmune(true)
        inst.components.sanity.get_equippable_dappernessfn = GetEquippableDapperness
    end)
end

-- 薇克巴顿读书消耗更少耐久
if GetModConfigData("Wickerbottom Read Book Less Use") then
    AddComponentPostInit("book", function(self)
        local oldInteract = self.Interact
        self.Interact = function(self, fn, reader, ...)
            if reader.prefab == "wickerbottom" and reader.components.sanity and not self.inst:HasTag("shadowmagic") and self.inst.components.finiteuses then
                local success = true
                local reason
                if fn then
                    success, reason = fn(self.inst, reader)
                    if success then self.inst.components.finiteuses:Use(math.max(0.35, 1 - reader.components.sanity:GetPercent())) end
                end
                return success, reason
            else
                return oldInteract(self, fn, reader, ...)
            end
        end
    end)
end

-- 薇克巴顿冰火魔杖
if GetModConfigData("Wickerbottom Use Staff") then
    local function createlight(staff, target, pos)
        local spike = SpawnPrefab(staff.prefab == "icestaff" and "sharkboi_icespike" or "emberlight")
        spike.Transform:SetPosition(pos:Get())
        staff.components.finiteuses:Use(staff.prefab == "icestaff" and 1 or 4)
        local caster = staff.components.inventoryitem.owner
        if staff.prefab == "icestaff" then
            if caster ~= nil then spike.Transform:SetRotation(caster.Transform:GetRotation()) end
            if spike.SetVariation then spike:SetVariation(math.random(4)) end
        end
        if caster ~= nil then
            if caster.components.staffsanity then
                caster.components.staffsanity:DoCastingDelta(staff.prefab == "icestaff" and -TUNING.SANITY_TINY or -TUNING.SANITY_MEDLARGE)
            elseif caster.components.sanity ~= nil then
                caster.components.sanity:DoDelta(staff.prefab == "icestaff" and -TUNING.SANITY_TINY or -TUNING.SANITY_MEDLARGE)
            end
        end
    end
    local specialitems = {icestaff = true, firestaff = true, firepen = true}
    local function onunequip(inst, data)
        if data and data.item and data.item:IsValid() and specialitems[data.item.prefab] and data.item.wickerbottom2hm and data.item.components.spellcaster then
            data.item.wickerbottom2hm = nil
            data.item:RemoveComponent("spellcaster")
        end
    end
    local function onequip(inst, data)
        if not inst.wickerbottomrefresh2hm and data and data.item and data.item:IsValid() and specialitems[data.item.prefab] and
            not data.item.components.spellcaster then
            data.item.wickerbottom2hm = true
            data.item:AddComponent("spellcaster")
            data.item.components.spellcaster:SetSpellFn(createlight)
            data.item.components.spellcaster.canuseonpoint = true
            if data.item.prefab == "icestaff" then data.item.components.spellcaster.quickcast = true end
        end
    end
    AddPrefabPostInit("wickerbottom", function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("equip", onequip)
        inst:ListenForEvent("unequip", onunequip)
    end)
end

-- 薇克巴顿每日一书,且可以作为免费的制作材料
if GetModConfigData("Wickerbottom Daily Book") then
    local TechTree = require("techtree")
    -- 书柜存放更多道具
    if not TUNING.erasablepapertag2hm then
        TUNING.erasablepapertag2hm = true
        AddComponentPostInit("erasablepaper", function(self) self.inst:AddTag("erasablepaper") end)
    end
    local containers = require("containers")
    local olditemtestfn = containers.params.bookstation.itemtestfn
    containers.params.bookstation.itemtestfn = function(container, item, slot, ...)
        return (olditemtestfn and olditemtestfn(container, item, slot, ...)) or item:HasTag("erasablepaper") or 
            item:HasTag("scrapbook_page") or item.prefab == "stash_map" or item.prefab == "mapscroll"
    end
    -- 专属书柜存放有限制
    local books = {
        "book_birds",
        "book_gardening",
        "book_horticulture",
        "book_horticulture_upgraded",
        "book_silviculture",
        "book_sleep",
        "book_brimstone",
        "book_tentacles",
        "book_fish",
        "book_web",
        "book_temperature",
        "book_light",
        "book_light_upgraded",
        "book_fire",
        "book_moon",
        "book_rain",
        "book_bees",
        "book_research_station"
    }
    -- bookstation2hm兼容
    containers.params.bookstation2hm = {}
    containers.params.bookstation2hm.widget = containers.params.bookstation.widget
    containers.params.bookstation2hm.type = containers.params.bookstation.type
    containers.params.bookstation2hm.itemtestfn = function(container, item, slot)
        return container.init2hm or (slot and slot <= 16 and item:HasTag("dailybook2hm")) or 
        ((slot == nil or slot > 16) and table.contains(books, item.prefab))
    end
    containers.params.bookstation2hm.usespecificslotsforitems = true
    containers.params.bookstation2hm.acceptsstacks = false
    AddClassPostConstruct("widgets/containerwidget", function(self)
        local oldOpen = self.Open
        self.Open = function(self, container, doer, ...)
            local result = oldOpen(self, container, doer, ...)
            if container and container.prefab == "bookstation2hm" then
                local atlas = resolvefilepath(CRAFTING_ATLAS)
                for k, v in pairs(self.inv) do
                    if k <= 16 then
                        v:SetBGImage2(atlas, "favorite_checked.tex", {1, 1, 1, 0.1})
                        local w, h = v.bgimage:GetSize()
                        v.bgimage2:SetSize(w, h)
                    end
                end
                if self.bgimage.SetTint then self.bgimage:SetTint(1, 1, 1, 0.25) end
                if self.bganim.inst and self.bganim.inst.AnimState then self.bganim.inst.AnimState:SetMultColour(1, 1, 1, 0.25) end
            end
            return result
        end
    end)
    local lockbooks = {"book_birds", "book_horticulture", "book_research_station", "book_light", "book_rain", "book_fish"}
    local function delayremove(inst) inst:DoTaskInTime(0, inst.Remove) end
    local function processbook(inst, book)
        book.master2hm = inst
        book:AddTag("dailybook2hm")
        book:AddTag("hide_percentage")
        if book.components.inventoryitem then
            book.components.inventoryitem:SetOnDroppedFn(delayremove)
            book:ListenForEvent("onputininventory", delayremove)
            book:ListenForEvent("ondropped", delayremove)
            book.components.inventoryitem.onactiveitemfn = delayremove
        end
        if book.components.finiteuses then
            book.components.finiteuses:SetMaxUses(1)
            book.components.finiteuses:SetUses(1)
            book.components.finiteuses:SetPercent(0.01)--防止通过拆解扫把白嫖
            book:ListenForEvent("percentusedchange", delayremove)
        end
    end
    local function dailybook(inst)
        if not inst:HasTag("playerghost") and inst.components.persistent2hm and (inst.components.persistent2hm.data.dailybook or -1) < TheWorld.state.cycles and
            inst.bookstation2hm and inst.bookstation2hm:IsValid() and inst.bookstation2hm.components.container and
            #(inst.bookstation2hm.components.container:FindItems(function(item) return item and item:HasTag("dailybook2hm") end)) < 16 then
            inst.components.persistent2hm.data.dailybook = TheWorld.state.cycles
            local self = inst.bookstation2hm.components.container
            local slot
            for i = 1, math.min(self.numslots, 16) do
                if not self.slots[i] then
                    slot = i
                    break
                end
            end
            if not slot then return end
            local bookname = "book_research_station"
            if TheWorld.state.cycles > 0 then
                if inst.components.builder and inst.components.builder.recipes then
                    local recipes = inst.components.builder.recipes
                    local books2 = deepcopy(books)
                    for index, name in ipairs(books) do
                        if table.contains(recipes, name) or table.contains(lockbooks, name) then
                            table.insert(books2, name)
                            table.insert(books2, name)
                        end
                    end
                    bookname = books2[math.random(#books2)]
                else
                    bookname = books[math.random(#books)]
                end
            end
            local book = SpawnPrefab(bookname)
            if book and book:IsValid() then
                if book.components.inventoryitem then
                    book:AddTag("dailybook2hm")
                    self:GiveItem(book, slot)
                    processbook(inst, book)
                else
                    book:Remove()
                end
            end
        end
    end
    local function initbookstation(inst)
        if not (inst.bookstation2hm and inst.bookstation2hm:IsValid()) then
            local bookstation = SpawnPrefab("bookstation2hm")
            if bookstation and bookstation:IsValid() and bookstation.components.container then
                if inst.components.persistent2hm.data.bookstation then
                    bookstation.components.container.init2hm = true
                    bookstation:SetPersistData(inst.components.persistent2hm.data.bookstation)
                    bookstation.components.container.init2hm = nil
                    inst.components.persistent2hm.data.bookstation = nil
                end
                for i = 1, 16 do
                    local item = bookstation.components.container.slots[i]
                    if item and item:IsValid() then processbook(inst, item) end
                end
                bookstation:AddTag("dcs2hm")
                inst.bookstation2hm = bookstation
                bookstation.master2hm = inst
                bookstation.components.container.skipautoclose = true
                bookstation:Hide()
                inst:AddChild(bookstation)
                -- bookstation:RemoveFromScene()
                bookstation:AddTag("NOBLOCK")
                bookstation:RemoveTag("chest")
                if inst.components.builder and not inst.components.builder.DoBuild2hm then
                    inst.components.builder.DoBuild2hm = true
                    local DoBuild = inst.components.builder.DoBuild
                    inst.components.builder.DoBuild = function(self, ...)
                        local inst = self.inst
                        if inst.bookstation2hm and inst.bookstation2hm:IsValid() and inst.bookstation2hm.components.container and
                            inst.bookstation2hm.components.container.openlist and inst.bookstation2hm.components.container.openlist[inst] ~= nil then
                            inst.bookstation2hm.components.container:Close(inst)
                        end
                        return DoBuild(self, ...)
                    end
                end
                bookstation.persists = false
                dailybook(inst)
            end
        end
    end
    local function OnSave(inst, data)
        data.bookstation = InGamePlay() and (inst.bookstation2hm and inst.bookstation2hm:IsValid() and inst.bookstation2hm:GetPersistData() or nil) or
                               data.bookstation
    end
    local function rightselfstrfn2hm(act)
        if act.doer and act.doer.bookstationlevel2hm then return "BOOKSTATION" .. tostring(act.doer.bookstationlevel2hm:value()) end
    end
    STRINGS.ACTIONS.RIGHTSELFACTION2HM.BOOKSTATION = STRINGS.NAMES.BOOKSTATION
    STRINGS.ACTIONS.RIGHTSELFACTION2HM.BOOKSTATION0 = STRINGS.NAMES.BOOKSTATION .. " Lv0"
    STRINGS.ACTIONS.RIGHTSELFACTION2HM.BOOKSTATION1 = STRINGS.NAMES.BOOKSTATION .. " Lv1"
    STRINGS.ACTIONS.RIGHTSELFACTION2HM.BOOKSTATION2 = STRINGS.NAMES.BOOKSTATION .. " Lv2"
    STRINGS.ACTIONS.RIGHTSELFACTION2HM.BOOKSTATION3 = STRINGS.NAMES.BOOKSTATION .. " Lv3"
    STRINGS.ACTIONS.RIGHTSELFACTION2HM.BOOKSTATION4 = STRINGS.NAMES.BOOKSTATION .. " Lv4 Max"
    -- 奶奶自带科技
    if not PROTOTYPER_DEFS.wickerbottom then
        PROTOTYPER_DEFS.wickerbottom = {
            icon_atlas = "images/crafting_menu_avatars.xml",
            icon_image = "avatar_wickerbottom.tex",
            action_str = "WICKERBOTTOM",
            is_crafting_station = false
        }
    end
    if not STRINGS.ACTIONS.OPEN_CRAFTING.WICKERBOTTOM then STRINGS.ACTIONS.OPEN_CRAFTING.WICKERBOTTOM = TUNING.isCh2hm and "Learn with" or "请教" end
    AddPrefabPostInit("wickerbottom", function(inst)
        inst:AddTag("prototyper")
        inst.rightselfstrfn2hm = rightselfstrfn2hm
        inst.bookstationlevel2hm = net_byte(inst.GUID, "wickerbottomstation.level2hm")
        if not TheWorld.ismastersim then return end
        inst.bookstationlevel2hm:set(0)
        if not inst.components.persistent2hm then inst:AddComponent("persistent2hm") end
        
        -- 确保有prototyper组件，作为隐藏书架的代理，使EvaluateTechTrees能够找到它
        if not inst.components.prototyper then
            inst:AddComponent("prototyper")
            inst.components.prototyper.trees = {BOOKCRAFT = 0, SCIENCE = 0, MAGIC = 0}
        else
            -- 如果已经有prototyper（被其他模组添加），重置其科技树为书架初始值
            inst.components.prototyper.trees = {BOOKCRAFT = 0, SCIENCE = 0, MAGIC = 0}
        end
        
        -- 书架科技对所有人可用
        if inst.components.prototyper then
            inst.components.prototyper.restrictedtag = nil
            
            -- 兼容妥协，自己使用时不触发鼓励语句
            if TUNING.DSTU and inst.components.prototyper.onactivate then
                local old_onactivate = inst.components.prototyper.onactivate
                inst.components.prototyper.onactivate = function(prototyper_inst, doer)
                    if doer and doer.prefab ~= "wickerbottom" then
                        old_onactivate(prototyper_inst, doer)
                    end
                end
            end
        end
        
        inst:WatchWorldState("cycles", dailybook)
        SetOnSave2hm(inst, OnSave)
        inst:DoTaskInTime(0, initbookstation)
    end)
    AddRightSelfAction("wickerbottom", 1, "dolongaction", nil, function(act)
        if act.doer and act.doer.prefab == "wickerbottom" and act.doer.bookstation2hm then
            local bookstation = act.doer.bookstation2hm
            if bookstation and bookstation:IsValid() and bookstation.components.container and act.doer == bookstation.master2hm then
                if bookstation.components.container.openlist[act.doer] then
                    bookstation.components.container:Close(act.doer)
                    -- if act.doer.components.builder ~= nil and act.doer.components.prototyper ~= nil then
                    --     return act.doer.components.builder:UsePrototyper(act.doer)
                    -- end
                else
                    bookstation.components.container:Open(act.doer)
                end
                return true
            else
                act.doer:DoTaskInTime(0, initbookstation)
            end
        end
    end, STRINGS.NAMES.BOOKSTATION)
    AddPrefabPostInit("bookstation2hm", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.container ~= nil then
            local GetSpecificSlotForItem = inst.components.container.GetSpecificSlotForItem
            inst.components.container.GetSpecificSlotForItem = function(self, item, ...)
                local result = GetSpecificSlotForItem(self, item, ...)
                if result >= 17 then
                    for i = self.numslots, 17, -1 do
                        local item = self.slots[i]
                        if not item then return i end
                    end
                elseif result == 1 then
                    for i = 1, math.min(self.numslots, 16) do
                        local item = self.slots[i]
                        if not item then return i end
                    end
                end
                return result
            end
        end
    end)
    -- 书柜动态等级
    local function NewRestoreBooks(inst)
        local wicker_bonus = 1
        local x, y, z = inst.Transform:GetWorldPosition()
        local players = FindPlayersInRange(x, y, z, TUNING.BOOKSTATION_BONUS_RANGE, true)
        for _, player in ipairs(players) do
            if player:HasTag("bookbuilder") then
                wicker_bonus = TUNING.BOOKSTATION_WICKER_BONUS
                break
            end
        end
        for k, v in pairs(inst.components.container.slots) do
            if v and v:HasTag("book") and not v:HasTag("dailybook2hm") and v.components.finiteuses then
                local percent = v.components.finiteuses:GetPercent()
                if percent < 1 then v.components.finiteuses:SetPercent(math.min(1, percent + (TUNING.BOOKSTATION_RESTORE_AMOUNT * wicker_bonus))) end
            end
        end
    end
    local updatemode = hardmode and GetModConfigData("role_nerf") and GetModConfigData("wickerbottom")
    local function resetbookstationlevel(inst)
        if not inst.init2hm then
            inst.init2hm = true
            inst:ListenForEvent("itemget", resetbookstationlevel)
            inst:ListenForEvent("itemlose", resetbookstationlevel)
            if inst.RestoreTask ~= nil and updatemode then
                inst.RestoreTask:Cancel()
                inst.RestoreTask = nil
            end
        end
        if not inst.components.container then return end
        local items = {}
        for k, v in pairs(inst.components.container.slots) do
            if v and v:IsValid() and v.prefab and table.contains(books, v.prefab) and not table.contains(items, v.prefab) then
                table.insert(items, v.prefab)
            end
        end
        local oldbookslevel2hm = inst.bookslevel2hm or 0
        inst.bookslevel2hm = math.min(math.floor(#items / 4), 4)
        if inst.bookslevel2hm == oldbookslevel2hm then
            if inst.master2hm and inst.master2hm:IsValid() and inst.master2hm.components.builder then
                inst.master2hm.components.builder:EvaluateTechTrees()
            end
            return
        elseif inst.bookslevel2hm > oldbookslevel2hm then
            local shinefx = SpawnPrefab("pocketwatch_warpback_fx")
            shinefx.AnimState:SetTime(10 * FRAMES)
            local parent = inst.master2hm and inst.master2hm:IsValid() and inst.master2hm or inst
            parent:AddChild(shinefx)
            inst:PushEvent("ms_giftopened")
        elseif inst.bookslevel2hm < oldbookslevel2hm and inst.components.workable then
            inst.components.workable.onwork(inst)
        end
        inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl2_ding")
        if inst.level2hm then inst.level2hm:set(inst.bookslevel2hm) end
        if inst.master2hm and inst.master2hm:IsValid() and inst.master2hm.bookstationlevel2hm then
            inst.master2hm.bookstationlevel2hm:set(inst.bookslevel2hm)
        end
        if updatemode then
            if inst.RestoreTask ~= nil then
                inst.RestoreTask:Cancel()
                inst.RestoreTask = nil
            end
            if inst.bookslevel2hm > 0 then
                inst.RestoreTask = inst:DoPeriodicTask(TUNING.BOOKSTATION_RESTORE_TIME * (8 - inst.bookslevel2hm * 1.5) / 8, NewRestoreBooks)
            end
        end

        local tech_trees = TechTree.Create({
            SCIENCE = math.clamp(inst.bookslevel2hm, not hardmode and inst.prefab == "bookstation" and 2 or 0, 3),
            BOOKCRAFT = math.clamp(inst.bookslevel2hm, not hardmode and inst.prefab == "bookstation" and 1 or 0, 1),
            CARPENTRY = math.clamp(inst.bookslevel2hm, 0, 2),
            SEAFARING = math.clamp(inst.bookslevel2hm, 0, 2),
            CARTOGRAPHY = math.clamp(inst.bookslevel2hm - 1, 0, 2),
            MAGIC = math.clamp(inst.bookslevel2hm - 2, not hardmode and inst.prefab == "bookstation" and 1 or 0, 2),
            TURFCRAFTING = math.clamp(inst.bookslevel2hm - 2, 0, 2),
            MASHTURFCRAFTING = math.clamp(inst.bookslevel2hm - 2, 0, 2),
            FISHING = math.clamp(inst.bookslevel2hm - 3, 0, 1)
        })
        
        -- 更新书架自身的prototyper
        if inst.components.prototyper then
            inst.components.prototyper.trees = tech_trees
        end
        
        -- 更新角色prototyper，使角色作为隐藏书架的代理
        if inst.master2hm and inst.master2hm:IsValid() and inst.master2hm.components.prototyper then
            inst.master2hm.components.prototyper.trees = tech_trees
            inst.master2hm.components.prototyper.restrictedtag = nil    -- 确保所有角色可用
        end
        
        -- 通知所有正在使用这个prototyper的玩家更新科技树
        local prototyper = inst.components.prototyper or (inst.master2hm and inst.master2hm:IsValid() and inst.master2hm.components.prototyper) or nil
        if prototyper and prototyper.doers then
            for doer, v in pairs(prototyper.doers) do
                if v and doer and doer.components.builder then 
                    doer.components.builder:EvaluateTechTrees()
                end
            end
        end

        -- 特别通知薇克巴顿自己更新科技树
        if inst.master2hm and inst.master2hm:IsValid() and inst.master2hm.components.builder then
            inst.master2hm.components.builder:EvaluateTechTrees()
        end
    end
    local function DisplayNameFn(inst) return inst.name .. " Lv" .. inst.level2hm:value() .. (inst.level2hm:value() >= 4 and " Max" or "") end
    local function processbookstation(inst)
        if not inst.displaynamefn then inst.displaynamefn = DisplayNameFn end
        inst.level2hm = net_byte(inst.GUID, "bookstation.level2hm")
        if not TheWorld.ismastersim then return end
        inst.level2hm:set(0)
        if inst.components.prototyper and hardmode then inst.components.prototyper.trees = {BOOKCRAFT = 0, SCIENCE = 0, MAGIC = 0} end
        inst:DoTaskInTime(0, resetbookstationlevel)
    end
    AddPrefabPostInit("bookstation", processbookstation)
    AddPrefabPostInit("bookstation2hm", processbookstation)
end

-- 薇克巴顿书籍增强
if GetModConfigData("Wickerbottom Book Buff") then
    -- 养蜂笔记召唤的嗡嗡蜜蜂不会攻击玩家（除非玩家主动攻击它们或攻击蜂王）
    AddPrefabPostInit("beeguard", function(inst)
        if not TheWorld.ismastersim then return end
        
        inst:DoTaskInTime(0, function()
            if inst.components.combat then
                local oldRetargetFn = inst.components.combat.targetfn
                inst.components.combat:SetRetargetFunction(2, function(inst)
                    -- 若为玩家召唤的
                    if inst:IsFriendly() then
                        local commander = inst:GetQueen()
                        if commander == nil then
                            return nil
                        end
                        
                        -- 不要主动攻击任何玩家
                        if commander:HasTag("player") then
                            local pvpon = TheNet:GetPVPEnabled()
                            local FRIENDLYBEES_MUST = { "_combat", "_health" }
                            local FRIENDLYBEES_CANT = { "INLIMBO", "noauradamage", "bee", "companion", "player" }  -- 添加player到黑名单
                            local FRIENDLYBEES_MUST_ONE = { "monster", "prey" }
                            
                            local ix, iy, iz = inst.Transform:GetWorldPosition()
                            local ents = TheSim:FindEntities(
                                ix, iy, iz, TUNING.BOOK_BEES_MAX_ATTACK_RANGE,
                                FRIENDLYBEES_MUST, FRIENDLYBEES_CANT, FRIENDLYBEES_MUST_ONE
                            )

                            for _, v in ipairs(ents) do
                                if v ~= commander then
                                    return v
                                end
                            end
                            return nil
                        end
                    end
                    
                    if oldRetargetFn then
                        return oldRetargetFn(inst)
                    end
                    return nil
                end)
                
            end
        end)
    end)
    
    -- 控温学使玩家获得的35度体温和潮湿度清零的buff能够维持4分钟
    AddPrefabPostInit("book_temperature", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.book and inst.components.book.onread then
            local old_onread = inst.components.book.onread
            
            inst.components.book.onread = function(inst, reader)
                local success, reason = old_onread(inst, reader)
                
                if success then
                    local x, y, z = reader.Transform:GetWorldPosition()
                    local players = FindPlayersInRange(x, y, z, 16, true)
                    for _, player in pairs(players) do
                        if player.components.temperature and player.components.moisture then
                            player:AddDebuff("book_temperature_buff2hm", "book_temperature_buff2hm")
                        end
                    end
                end
                
                return success, reason
            end
        end
    end)
    
    -- 意念控火术妥协开启时消除范围内夏季燃烧产生的浓烟
    AddPrefabPostInit("book_fire", function(inst)
        if not TheWorld.ismastersim then return end
        if inst.components.book and inst.components.book.onread then
            local old_onread = inst.components.book.onread
            
            inst.components.book.onread = function(inst, reader)
                local success, reason = old_onread(inst, reader)
                
                if success and TUNING.DSTU then
                    local x, y, z = reader.Transform:GetWorldPosition()
                    local radius = TUNING.BOOK_FIRE_RADIUS or 16
                    
                    local smogs = TheSim:FindEntities(x, y, z, radius, {"smog"}, {"INLIMBO"})
                    
                    for k, v in pairs(smogs) do
                        v:Remove()
                    end
                end
                
                return success, reason
            end
        end
    end)

    -- 月之魔典可以召唤极光，妥协开启时耐久回调为1，随时可读但仅满月时进行额外的月光转化
    AddPrefabPostInit("book_moon", function(inst)
        if not TheWorld.ismastersim then return end
        
        if TUNING.DSTU and TUNING.DSTU.WICKERNERF_MOONBOOK then
            if inst.components.finiteuses then
                inst.components.finiteuses:SetMaxUses(1)
                inst.components.finiteuses:SetUses(1)
            end
        end
        
        if inst.components.book and inst.components.book.onread then
            local old_onread = inst.components.book.onread
             
            inst.components.book.onread = function(inst, reader)
                local success, reason
                
                if TUNING.DSTU and TUNING.DSTU.WICKERNERF_MOONBOOK then
                    success = true  -- 随时可以读书
                    
                    -- 仅在满月时执行月光转化
                    if TheWorld.state.isfullmoon then
                        local x, y, z = reader.Transform:GetWorldPosition()
                        local ents = TheSim:FindEntities(x, y, z, 8, nil, {"player", "playerghost", "INLIMBO", "dead"}, {"halloweenmoonmutable", "werebeast"})
                        local woodies = TheSim:FindEntities(x, y, z, 8, {"wereness"}, {"playerghost", "INLIMBO", "dead"})
                        
                        for k, v in ipairs(ents) do
                            local ex, ey, ez = v.Transform:GetWorldPosition()
                            
                            if v.components.halloweenmoonmutable ~= nil then
                                v.components.halloweenmoonmutable:Mutate()
                                local fx = SpawnPrefab("halloween_moonpuff")
                                fx.Transform:SetPosition(ex, ey, ez)
                            end
                            
                            if v.components.werebeast ~= nil and not v.components.werebeast:IsInWereState() then
                                v.components.werebeast:SetWere(1)
                                local fx = SpawnPrefab("halloween_moonpuff")
                                fx.Transform:SetPosition(ex, ey, ez)
                            end
                        end
                        
                        for k, v in ipairs(woodies) do
                            local ex, ey, ez = v.Transform:GetWorldPosition()
                            
                            local pct = v.components.wereness:GetPercent()
                            if pct > 0 then
                                v.components.wereness:SetPercent(1)
                                local fx = SpawnPrefab("halloween_moonpuff")
                                fx.Transform:SetPosition(ex, ey, ez)
                            else
                                v.components.wereness:SetPercent(1, true)
                                v.components.wereeater:ForceTransformToWere()
                                local fx = SpawnPrefab("halloween_moonpuff")
                                fx.Transform:SetPosition(ex, ey, ez)
                            end
                        end
                    end
                else
                    -- 妥协未开启时，执行原版逻辑
                    success, reason = old_onread(inst, reader)
                end
                
                -- 召唤极光
                if success and reader then
                    local x, y, z = reader.Transform:GetWorldPosition()
                    local aurora = SpawnPrefab("staffcoldlight")
                    if aurora then
                        aurora.Transform:SetPosition(x, y, z)
                    end
                end
                
                return success, reason
            end
        end
    end)
    
    
    -- 困难模式下月之魔典制作需要消耗1彩虹宝石
    if hardmode then
        AddRecipePostInit("book_moon", function(recipe)
            local has_opalgem = false
            for _, ingredient in pairs(recipe.ingredients) do
                if ingredient.type == "opalpreciousgem" then
                    has_opalgem = true
                    break
                end
            end
            if not has_opalgem then
                table.insert(recipe.ingredients, Ingredient("opalpreciousgem", 1))
            end
        end)
    end
end
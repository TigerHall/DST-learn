----------------------------------------------------------------------------------------------------------------------------------
--[[


]]--
----------------------------------------------------------------------------------------------------------------------------------
--- replica 同步
    ------------------------------------------------------------
        local function GetReplica(self)
            return self.inst.replica.tbat_com_mushroom_snail_cauldron or self.inst.replica._.tbat_com_mushroom_snail_cauldron
        end
        local function SetReplica(self,fn_name,value)
            local replica = GetReplica(self)
            if replica and replica[fn_name] then
                replica[fn_name](replica,value)
            end
        end
    ------------------------------------------------------------
    --- 
        local function set_product(self,product)
            SetReplica(self,"SetProduct",product)
        end
        local function set_origin_product(self,product)
            SetReplica(self,"SetOriginProduct",product)
        end
        local function set_stacksize(self,num)
            SetReplica(self,"SetStackSize",num)
        end
        local function set_cooker_userid(self,userid)
            SetReplica(self,"SetCookerUserid",userid)
        end
        local function set_cooker_name(self,name)
            SetReplica(self,"SetCookerName",name)
        end
        local function set_remaining_time(self,num)
            SetReplica(self,"SetRemainingTime",num)
        end
        local function set_cook_fail(self,bool)
            SetReplica(self,"SetCookFail",bool)
        end
    ------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
local tbat_com_mushroom_snail_cauldron = Class(function(self, inst)
    self.inst = inst
    inst:AddTag("tbat_com_mushroom_snail_cauldron")
    ------------------------------------------------------------
    --- 基础数据
        self.DataTable = {}
        self.TempTable = {}
        self._onload_fns = {}
        self._onsave_fns = {}
        self._on_post_init_fns = {}
    ------------------------------------------------------------
    ---
        self.cook_start_slot_index = 30
        self.remaining_time = 0
    ------------------------------------------------------------
    ---
        self.product = ""
        self.origin_product = ""
        self.stacksize = 0
        self.overridebuild = ""
        self.overridesymbolname = ""
        self.cooker_userid = ""
        self.cooker_name = ""
        self.cook_fail = false
    ------------------------------------------------------------
    --- 激活操作
        inst:ListenForEvent("start_clicked",function(inst,data)
            local userid = data.userid
            local doer = LookupPlayerInstByUserID(userid)
            if doer and doer:HasTag("player") then
                self:OnStart(doer)
            end
        end)
        inst:ListenForEvent("harvest_clicked",function(inst,data)
            local userid = data.userid
            local doer = LookupPlayerInstByUserID(userid)
            if doer and doer:HasTag("player") then
                self:OnHarvest(doer)
            end
        end)
    ------------------------------------------------------------
    --- 同步配方数据
        inst:ListenForEvent("onopen",function(_,data)
            local doer = data.doer
            if doer and doer.components.tbat_com_mushroom_snail_cauldron__for_player then
                doer.components.tbat_com_mushroom_snail_cauldron__for_player:SyncData()
            end
        end)
    ------------------------------------------------------------
end,
nil,
{
    product = set_product,
    origin_product = set_origin_product,
    stacksize = set_stacksize,
    cooker_userid = set_cooker_userid,
    cooker_name = set_cooker_name,
    remaining_time = set_remaining_time,
    cook_fail = set_cook_fail,
})
------------------------------------------------------------------------------------------------------------------------------
--- 烹饪 update fn
    local function cooking_timer_update_fn(inst,self)
        self.remaining_time = self.remaining_time - 1
        if TBAT.DEBUGGING then
            print(" tbat_com_mushroom_snail_cauldron 剩余时间:",self.remaining_time,inst)
        end
        if self.remaining_time <= 0 then
            self.remaining_time = 0            
            self:OnFinish(true)
            TheWorld.components.tbat_com_special_timer_for_theworld:RemoveTimer(inst)
        end
        
    end
------------------------------------------------------------------------------------------------------------------------------
--- 消耗物品
    local function RemoveItem(item,num)
        if item.components.stackable then
            item.components.stackable:Get(num):Remove()
        else
            item:Remove()
        end
    end
------------------------------------------------------------------------------------------------------------------------------
--- 开始烹饪
    function tbat_com_mushroom_snail_cauldron:SetOnStartFn(fn)
        self.on_start_fn = fn
    end
    function tbat_com_mushroom_snail_cauldron:OnStart(doer)
        if self.remaining_time > 0 then
            print("[MSC]正在制作中")
            return
        end

        local item_1 = self.inst.components.container:GetItemInSlot(self.cook_start_slot_index + 1)
        local item_2 = self.inst.components.container:GetItemInSlot(self.cook_start_slot_index + 2)
        local item_3 = self.inst.components.container:GetItemInSlot(self.cook_start_slot_index + 3)
        local item_4 = self.inst.components.container:GetItemInSlot(self.cook_start_slot_index + 4)
        local product,product_data = TBAT.MSC:TestByItems(item_1, item_2, item_3, item_4)
        if product == nil then
            return
        end
        --------------------------------------------------------------------------
        --- 烹饪时间
            local cook_time = product_data.time or 30
            if self.cook_time_remake_fn then
                cook_time = self.cook_time_remake_fn(self.inst,doer) or cook_time
            end
            if TBAT.DEBUGGING then
                cook_time = math.floor(cook_time/10)
                cook_time = math.max(cook_time,5)
            end
        --------------------------------------------------------------------------
        --- 记忆数据
            self.remaining_time = cook_time                 -- 剩余时间
            self.product = product                          -- 产品
            self.origin_product = product                   -- 原产品
            self.stacksize = product_data.stacksize or 1    -- 叠堆
        --------------------------------------------------------------------------
        ---
            self.inst:AddTag("working")
        --------------------------------------------------------------------------
        --- 玩家记忆
            self.cooker_userid = doer.userid
            self.cooker_name = doer:GetDisplayName()
        --------------------------------------------------------------------------
        --- 动画包
            self.overridebuild = product_data.overridebuild  -- 动画包
            self.overridesymbolname = product_data.overridesymbolname -- 动画包里的图层
        --------------------------------------------------------------------------
        --- 【关键】失败控制
            if product_data.fail_product_prefab ~= nil and PrefabExists(product_data.fail_product_prefab) then
                if not doer.components.tbat_com_mushroom_snail_cauldron__for_player:HasRecipe(product) then
                    self.product = product_data.fail_product_prefab
                    self.stacksize = product_data.fail_stacksize or self.stacksize
                    self.overridebuild = product_data.fail_overridebuild or self.overridebuild
                    self.overridesymbolname = product_data.fail_overridesymbolname or self.overridesymbolname
                    self.cook_fail = true
                    -- print("fake error : 这是个失败的配方",self.product)
                end
            end
        --------------------------------------------------------------------------
        ---
            
        --------------------------------------------------------------------------
        --- 消耗物品(先合并同类物)
            local items_data_in_slot = {}
            items_data_in_slot[item_1.prefab] = (items_data_in_slot[item_1.prefab] or 0) + TBAT.MSC:GetItemStack(item_1)
            items_data_in_slot[item_2.prefab] = (items_data_in_slot[item_2.prefab] or 0) + TBAT.MSC:GetItemStack(item_2)
            items_data_in_slot[item_3.prefab] = (items_data_in_slot[item_3.prefab] or 0) + TBAT.MSC:GetItemStack(item_3)
            items_data_in_slot[item_4.prefab] = (items_data_in_slot[item_4.prefab] or 0) + TBAT.MSC:GetItemStack(item_4)

            local cost_cmd = {}
            for k, single_prefab_cmd in pairs(product_data.recipe) do
                local prefab = single_prefab_cmd[1]
                local num = single_prefab_cmd[2]
                cost_cmd[prefab] = (cost_cmd[prefab] or 0) + num
            end

            for prefab,num_in_slot in pairs(items_data_in_slot) do 
                items_data_in_slot[prefab] = num_in_slot - (cost_cmd[prefab] or 0)
            end
            ---- 返还多余物品
            local function has_same_item(prefab)
                for i = 1, self.cook_start_slot_index, 1 do
                    local item = self.inst.components.container:GetItemInSlot(i)
                    if item and item.prefab == prefab then
                        return true
                    end
                end
                return false
            end
            local function get_empty_slot()
                for i = 1, self.cook_start_slot_index, 1 do
                    local item = self.inst.components.container:GetItemInSlot(i)
                    if not item then
                        return i
                    end
                end
                return nil
            end
            for prefab,need_2_return_num in pairs(items_data_in_slot) do
                -- print("[MSC] 剩余:",prefab,need_2_return_num)
                if need_2_return_num > 0 then
                    for i = 1, need_2_return_num, 1 do
                            if has_same_item(prefab) then
                                    self.inst.components.container:GiveItem(SpawnPrefab(prefab))
                            else
                                    local empty_slot = get_empty_slot()
                                    if empty_slot then
                                        self.inst.components.container:GiveItem(SpawnPrefab(prefab),empty_slot)
                                    else
                                        doer.components.inventory:GiveItem(SpawnPrefab(prefab))
                                    end
                            end
                    end
                end
            end
            item_1:Remove()
            item_2:Remove()
            item_3:Remove()
            item_4:Remove()
        --------------------------------------------------------------------------
        --- 定时器
            TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(self.inst,1,cooking_timer_update_fn,self)
        --------------------------------------------------------------------------
        --- 触发事件
            if self.on_start_fn then
                self.on_start_fn(self.inst,doer)
            end
        --------------------------------------------------------------------------
        --- 推送event
            local event_cmd = {
                doer = doer,
                product = self.product,
                origin_product = self.origin_product,
                stacksize = self.stacksize,
                time = self.remaining_time,
                pot = self.inst,
            }
            self.inst:PushEvent("OnStarted",event_cmd)
            doer:PushEvent("tbat_com_mushroom_snail_cauldron.Started",event_cmd)
        --------------------------------------------------------------------------
        --- 回调覆盖
            self.remaining_time = event_cmd.time            -- 剩余时间
            self.product = event_cmd.product                -- 产品
            self.stacksize = event_cmd.stacksize or 1       -- 叠堆
        --------------------------------------------------------------------------
            -- print("[MSC] 开始烹饪")
            -- print("[MSC] 剩余时间:",self.remaining_time)
            -- print("[MSC] 产品:",self.product)
            -- print("[MSC] 叠堆:",self.stacksize)
        --------------------------------------------------------------------------
    end
------------------------------------------------------------------------------------------------------------------------------
--- 停止烹饪
    function tbat_com_mushroom_snail_cauldron:SetOnFinishFn(fn)
        self.on_finish_fn = fn
    end
    function tbat_com_mushroom_snail_cauldron:OnFinish(event_flag)
        local cmd_table = {
                overridebuild = self.overridebuild,
                overridesymbolname = self.overridesymbolname,
                cooker_userid = self.cooker_userid,
                cooker_name = self.cooker_name,
                cook_fail = self.cook_fail,
                product = self.product,
                stacksize = self.stacksize,
                cook_time = self.cook_time,
                origin_product = self.origin_product,
            }
        if self.on_finish_fn then
            self.on_finish_fn(self.inst,cmd_table)
        end
        self.inst:RemoveTag("working")
        self.inst:AddTag("can_be_harvest")
        if event_flag then
            self.inst:PushEvent("OnFinished",cmd_table)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
--- harvest
    function tbat_com_mushroom_snail_cauldron:SetOnHarvestFn(fn)
        self.on_harvest_fn = fn
    end
    function tbat_com_mushroom_snail_cauldron:OnHarvest(doer)
        --------------------------------------------------------------------------
        --- 
            if not self.inst:HasTag("can_be_harvest") then
                return
            end
        --------------------------------------------------------------------------
        --- 
            if self.on_harvest_fn then
                self.on_harvest_fn(self.inst,doer)
            end
        --------------------------------------------------------------------------
        --- 生成物品
            for i = 1, self.stacksize, 1 do
                doer.components.inventory:GiveItem(SpawnPrefab(self.product))
            end
            self.product = ""
            self.origin_product = ""
            self.stacksize = 0
            self.overridebuild = ""
            self.overridesymbolname = ""
            self.cooker_userid = ""
            self.cooker_name = ""
            self.cook_fail = false
        --------------------------------------------------------------------------
        --- tag + event
            self.inst:RemoveTag("can_be_harvest")
            self.inst:PushEvent("OnHarvested")
        --------------------------------------------------------------------------
    end
------------------------------------------------------------------------------------------------------------------------------
--- get product / symble
    function tbat_com_mushroom_snail_cauldron:GetProduct()
        local product = self.product
        local stacksize = self.stacksize
        if PrefabExists(product) and stacksize > 0 then
            return product,stacksize
        end
        return nil,0
    end
    function tbat_com_mushroom_snail_cauldron:GetOverrideSymbol()
            -- self.overridebuild = product_data.overridebuild  -- 动画包
            -- self.overridesymbolname = product_data.overridesymbolname -- 动画包里的图层
        local overridebuild = nil
        local overridesymbolname = nil
        if self.overridebuild and self.overridebuild ~= "" then
            overridebuild = self.overridebuild
        end
        if self.overridesymbolname and self.overridesymbolname ~= "" then
            overridesymbolname = self.overridesymbolname
        end
        if overridebuild and overridesymbolname then
            return overridebuild,overridesymbolname
        end
        return nil,nil
    end
------------------------------------------------------------------------------------------------------------------------------
--- on save / load
    function tbat_com_mushroom_snail_cauldron:Cook_OnSave()
        --------------------------------------------------------------------------
        --- working
            if self.inst:HasTag("working") then
                self:Set("working",true)
                self:Set("remaining_time",self.remaining_time)
            else
                self:Set("working",false)
                self:Set("remaining_time",0)
            end
        --------------------------------------------------------------------------
        --- harvest
            if self.inst:HasTag("can_be_harvest") then
                self:Set("can_be_harvest",true)
            else
                self:Set("can_be_harvest",false)
            end
        --------------------------------------------------------------------------
        --- product
            self:Set("product",self.product)
            self:Set("origin_product",self.origin_product)
            self:Set("stacksize",self.stacksize)
            self:Set("overridebuild",self.overridebuild)
            self:Set("overridesymbolname",self.overridesymbolname)
            self:Set("cooker_userid",self.cooker_userid)
            self:Set("cooker_name",self.cooker_name)
        --------------------------------------------------------------------------
        --- cook_fail
            self:Set("cook_fail",self.cook_fail)
        --------------------------------------------------------------------------
    end
    function tbat_com_mushroom_snail_cauldron:Cook_OnLoad()
        --------------------------------------------------------------------------
        --- working
            if self:Get("working") then
                self.inst:AddTag("working")
                self.remaining_time = self:Get("remaining_time",0)
                --------------------------------------------------------------------------
                --- 重启定时器
                    TheWorld.components.tbat_com_special_timer_for_theworld:AddTimer(self.inst,1,cooking_timer_update_fn,self)
                --------------------------------------------------------------------------
                --- 触发事件
                    if self.on_start_fn then
                        self.on_start_fn(self.inst)
                    end
                --------------------------------------------------------------------------
            else
                self.inst:RemoveTag("working")
            end
        --------------------------------------------------------------------------
        --- harvest
            if self:Get("can_be_harvest") then
                self.inst:AddTag("can_be_harvest")
                self.inst:DoTaskInTime(0,function()
                    self:OnFinish()                    
                end)
            else
                self.inst:RemoveTag("can_be_harvest")
            end
        --------------------------------------------------------------------------
        --- product
            self.product = self:Get("product") or ""
            self.origin_product = self:Get("origin_product") or ""
            self.stacksize = self:Get("stacksize",1)
            self.overridebuild = self:Get("overridebuild") or ""
            self.overridesymbolname = self:Get("overridesymbolname") or ""
            self.cooker_userid = self:Get("cooker_userid") or ""
            self.cooker_name = self:Get("cooker_name") or ""
            self.cook_fail = self:Get("cook_fail",false)
        --------------------------------------------------------------------------
    end
------------------------------------------------------------------------------------------------------------------------------











------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
----- onload/onsave 函数
    function tbat_com_mushroom_snail_cauldron:AddOnLoadFn(fn)
        if type(fn) == "function" then
            table.insert(self._onload_fns, fn)
        end
    end
    function tbat_com_mushroom_snail_cauldron:ActiveOnLoadFns()
        for k, temp_fn in pairs(self._onload_fns) do
            temp_fn(self)
        end
    end
    function tbat_com_mushroom_snail_cauldron:AddOnSaveFn(fn)
        if type(fn) == "function" then
            table.insert(self._onsave_fns, fn)
        end
    end
    function tbat_com_mushroom_snail_cauldron:ActiveOnSaveFns()
        for k, temp_fn in pairs(self._onsave_fns) do
            temp_fn(self)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
----- 数据读取/储存
    function tbat_com_mushroom_snail_cauldron:Get(index,default)
        if index then
            return self.DataTable[index] or default
        end
        return nil or default
    end
    function tbat_com_mushroom_snail_cauldron:Set(index,theData)
        if index then
            self.DataTable[index] = theData
        end
    end

    function tbat_com_mushroom_snail_cauldron:Add(index,num,min,max)
        if index then
            if min and max then
                local ret = (self.DataTable[index] or 0) + ( num or 0 )
                ret = math.clamp(ret,min,max)
                self.DataTable[index] = ret
                return ret
            else
                self.DataTable[index] = (self.DataTable[index] or 0) + ( num or 0 )
                return self.DataTable[index]
            end
        end
        return 0
    end
------------------------------------------------------------------------------------------------------------------------------
--- 在 DoTaskInTime 0 之前，world 创建完成之后。只有玩家自身、TheWorld起作用
    function tbat_com_mushroom_snail_cauldron:OnPostInit()
        for k, v in pairs(self._on_post_init_fns) do
            v(self.inst)
        end
    end
    function tbat_com_mushroom_snail_cauldron:AddOnPostInitFn(fn)
        if type(fn) == "function" then
            table.insert(self._on_post_init_fns, fn)
        end
    end
------------------------------------------------------------------------------------------------------------------------------
    function tbat_com_mushroom_snail_cauldron:OnSave()
        self:ActiveOnSaveFns()
        self:Cook_OnSave()
        local data =
        {
            -- DataTable = self.DataTable
        }
        -------------------------------------
        --
            for k, v in pairs(self.DataTable) do
                data[k] = v
            end
        -------------------------------------
        return next(data) ~= nil and data or nil
    end

    function tbat_com_mushroom_snail_cauldron:OnLoad(data)
        -- if data.DataTable then
        --     self.DataTable = data.DataTable
        -- end
        -------------------------------------
        ---
            data = data or {}
            for k, v in pairs(data) do
                self.DataTable[k] = v
            end
        -------------------------------------
        self:ActiveOnLoadFns()
        self:Cook_OnLoad()
    end
------------------------------------------------------------------------------------------------------------------------------
return tbat_com_mushroom_snail_cauldron








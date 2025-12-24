-- ===========================================================================
-- 重构了技能树系统，使用本模组独立的技能树经验和状态管理
local skilltreedefs = require "prefabs/skilltree_defs"

-- ============================================================================
-- 必要的工具函数
local EXP_PER_POINT = 5     
local DEFAULT_MAX_POINTS = 30   
local maxpoints = {         
    wilson = 26, willow = 24, wolfgang = 25, woodie = 27, wathgrithr = 23,
    wormwood = 26, wurt = 27, winona = 26, wortox = 28, walter = 26, wendy = 25
}

-- 最大经验
local function GetMaxExperience(characterprefab)
    return (maxpoints[characterprefab] or DEFAULT_MAX_POINTS) * EXP_PER_POINT
end
-- 可用洞察点数
local function CalculateAvailablePoints(experience)
    return math.floor(experience / EXP_PER_POINT)
end

-- 按依赖关系排序技能，确保母技能先被激活，遗忘时不能直接遗忘母技能
local function SortSkillsByDependency(skills_list, characterprefab)
    local skilldefs = skilltreedefs.SKILLTREE_DEFS[characterprefab]
    if not skilldefs then return skills_list end
    
    local sorted_skills = {}
    local remaining_skills = {}
    for _, skill in ipairs(skills_list) do
        remaining_skills[skill] = true
    end
    
    -- 多轮处理，每轮添加所有前置技能都已满足的技能
    local max_iterations = #skills_list + 10 -- 防止无限循环
    local iteration = 0
    
    while next(remaining_skills) and iteration < max_iterations do
        iteration = iteration + 1
        local added_in_this_round = false
        
        for skill_name, _ in pairs(remaining_skills) do
            local skilldef = skilldefs[skill_name]
            local can_add = true
            
            if skilldef then
                -- 检查 must_have_one_of 依赖
                if skilldef.must_have_one_of and can_add then
                    local has_one_of = false
                    for required_skill, _ in pairs(skilldef.must_have_one_of) do
                        -- 检查是否已经在排序列表中，或者是lock_open类型的技能
                        local required_skilldef = skilldefs[required_skill]
                        if table.contains(sorted_skills, required_skill) or 
                           (required_skilldef and required_skilldef.lock_open) then
                            has_one_of = true
                            break
                        end
                    end
                    can_add = has_one_of
                end
                
                -- 检查 must_have_all_of 依赖
                if skilldef.must_have_all_of and can_add then
                    for required_skill, _ in pairs(skilldef.must_have_all_of) do
                        local required_skilldef = skilldefs[required_skill]
                        if not table.contains(sorted_skills, required_skill) and 
                           not (required_skilldef and required_skilldef.lock_open) then
                            can_add = false
                            break
                        end
                    end
                end
                
                -- 如果是根技能，可以直接添加
                if skilldef.root then can_add = true end
            end
            
            if can_add then
                table.insert(sorted_skills, skill_name)
                remaining_skills[skill_name] = nil
                added_in_this_round = true
            end
        end
        
        -- 如果这轮没有添加任何技能，但还有剩余技能，说明可能有循环依赖
        -- 直接添加剩余技能，避免死锁
        if not added_in_this_round and next(remaining_skills) then
            for skill_name, _ in pairs(remaining_skills) do
                table.insert(sorted_skills, skill_name)
                remaining_skills[skill_name] = nil
                -- 一次只添加一个，下轮继续
                break 
            end
        end
    end
    
    return sorted_skills
end

-- 检查技能是否可以安全遗忘（没有其他技能依赖它）
local function CanSafelyForgetSkill(skill_name, characterprefab, current_activated_skills)
    local skilldefs = skilltreedefs.SKILLTREE_DEFS[characterprefab]
    if not skilldefs then return false end
    
    -- 检查是否有其他已激活的技能依赖这个技能
    for activated_skill, _ in pairs(current_activated_skills) do
        if activated_skill ~= skill_name then
            local activated_skilldef = skilldefs[activated_skill]
            if activated_skilldef then
                -- 检查 must_have_one_of 依赖
                if activated_skilldef.must_have_one_of and activated_skilldef.must_have_one_of[skill_name] then
                    -- 检查是否还有其他满足条件的技能
                    local has_alternative = false
                    for required_skill, _ in pairs(activated_skilldef.must_have_one_of) do
                        if required_skill ~= skill_name and current_activated_skills[required_skill] then
                            has_alternative = true
                            break
                        end
                        -- 检查 lock_open 类型的依赖
                        local required_skilldef = skilldefs[required_skill]
                        if required_skilldef and required_skilldef.lock_open and 
                           required_skilldef.lock_open(characterprefab, current_activated_skills, true) then
                            has_alternative = true
                            break
                        end
                    end

                    if not has_alternative then
                        -- 返回依赖它的技能名
                        return false, activated_skill 
                    end
                end
                
                -- 检查 must_have_all_of 依赖
                if activated_skilldef.must_have_all_of and activated_skilldef.must_have_all_of[skill_name] then
                    return false, activated_skill -- 直接阻止遗忘
                end
            end
        end
    end
    
    return true
end

-- ============================================================================
-- RPC通信工具
-- 客户端接收经验数据同步
if TheNet and not TheWorld then
    local client_data = {}
    
    -- 获取同步数据
    function GetClientCustomData(characterprefab)
        return client_data[characterprefab] or {days_played = 0, custom_experience = 0 }
    end
    
    -- 存储读取数据
    function UpdateClientData(characterprefab, days, exp)
        client_data[characterprefab] = {days_played = days, custom_experience = exp }
    end
end

-- 同步经验数据到客户端
AddClientModRPCHandler("happypatchmod", "SyncCustomXP", function(days_played, custom_xp)
    if ThePlayer and ThePlayer.prefab then
        UpdateClientData(ThePlayer.prefab, days_played, custom_xp)

        if ThePlayer.components.skilltreeupdater and ThePlayer.components.skilltreeupdater.skilltree then
            ThePlayer.components.skilltreeupdater.skilltree:SetSkillXP2hm(ThePlayer.prefab, custom_xp)
            ThePlayer.components.skilltreeupdater.skilltree.dirty = true
        end
        

        ThePlayer:DoTaskInTime(0.1, function()

            if ThePlayer.HUD and ThePlayer.HUD.controls and ThePlayer.HUD.controls.skilltreetoast then
                ThePlayer.HUD.controls.skilltreetoast:RefreshTree()
            end

            ThePlayer:PushEvent("onupdateskillxp_client", {
                characterprefab = ThePlayer.prefab,
                experience = custom_xp,
                days_played = days_played
            })
        end)
    end
end)

-- 同步技能状态到客户端
AddClientModRPCHandler("happypatchmod", "SyncSkillStates", function(activated_skills_data, custom_xp)

    local function apply_skill_states(attempt)
        attempt = attempt or 1
        local max_attempts = 3
        if attempt > max_attempts then return end
        
        if not (ThePlayer and ThePlayer.prefab and ThePlayer.components.skilltreeupdater) then

            local task_time = attempt * 0.5
            
            if ThePlayer then ThePlayer:DoTaskInTime(task_time, function() apply_skill_states(attempt + 1) end) end
            return
        end
        
        local skilltree = ThePlayer.components.skilltreeupdater.skilltree
        if not skilltree then
            ThePlayer:DoTaskInTime(0.5, function() apply_skill_states(attempt + 1) end)
            return
        end

        local activated_skills = {}
        if activated_skills_data and activated_skills_data ~= "" then
            local skills_list = string.split(activated_skills_data, ",")
            for _, skill in ipairs(skills_list) do
                if skill and skill ~= "" then
                    activated_skills[skill] = true
                end
            end
        end
        

        if not skilltree.activatedskills[ThePlayer.prefab] then skilltree.activatedskills[ThePlayer.prefab] = {} end

        for skill, _ in pairs(skilltree.activatedskills[ThePlayer.prefab]) do
            skilltree.activatedskills[ThePlayer.prefab][skill] = nil
        end

        for skill, _ in pairs(activated_skills) do skilltree.activatedskills[ThePlayer.prefab][skill] = true end       
        skilltree:SetSkillXP2hm(ThePlayer.prefab, custom_xp)
        skilltree.dirty = true 
        
        ThePlayer:DoTaskInTime(0.1, function()
            ThePlayer:PushEvent("onupdateskillxp_client", {
                characterprefab = ThePlayer.prefab,
                exp = custom_xp,
                skills = activated_skills
            })
            
            for skill_name, _ in pairs(activated_skills) do
                ThePlayer:PushEvent("onactivateskill_client", {skill = skill_name, restored = true})
            end
        end)

    
    end

    apply_skill_states(1)
end)

-- 同步数据和技能状态到客户端
local function SyncDataToClient(player, days_played, custom_experience)
    if player and player.userid then

        SendModRPCToClient(GetClientModRPC("happypatchmod", "SyncCustomXP"), player.userid, days_played, custom_experience)
        

        if player.components.skilltreeupdater and player.components.skilltreeupdater.skilltree then
            local activated_skills = player.components.skilltreeupdater.skilltree:GetActivatedSkills(player.prefab)
            if activated_skills then
                local skills_list = {}
                for skill, _ in pairs(activated_skills) do
                    table.insert(skills_list, skill)
                end
                local skills_data = table.concat(skills_list, ",")

                player:DoTaskInTime(0.3, function()
                    SendModRPCToClient(GetClientModRPC("happypatchmod", "SyncSkillStates"), player.userid, 
                                       skills_data, custom_experience)
                end)
            end
        end
    end
end

-- 服务器端处理技能遗忘的RPC，networkrpc种被klei注释掉的部分
AddModRPCHandler("EasyMode2hm", "DeactivateSkill", function(player, skill_id)
    if not player or not skill_id or not player.components.skilltreeupdater then return end
    local skilltreeupdater = player.components.skilltreeupdater
    if not skilltreeupdater:IsActivated(skill_id, player.prefab) then
        return
    end
    skilltreeupdater:DeactivateSkill(skill_id, player.prefab)
end)

-- ============================================================================
-- 世界数据交换 

-- 技能数据同步到其他世界
local function SyncSkillDataToOtherWorld(userid, character_name, data)
    if not data then return end 
    -- 添加时间戳用于验证
    data.sync_time = os.time()
    
    -- 发送到所有其他世界
    local rpc = GetShardModRPC("happypatchmod", "ReceiveSkillData")
    if rpc then SendModRPCToShard(rpc, nil, userid, character_name, DataDumper(data, nil, true)) end
end

-- 同步其他世界的技能数据
AddShardModRPCHandler("happypatchmod", "ReceiveSkillData", function(shard_id, userid, character_name, data_string)
    if not data_string then return end

    local success, data = RunInSandboxSafe(data_string)
    if not success or not data then return end
    
    -- 验证数据时效性（5分钟内）
    if not data.sync_time or os.time() - data.sync_time > 300 then return end
    
    -- 更新本世界的数据
    if TheWorld and TheWorld.components.persistent2hm then
        if not TheWorld.components.persistent2hm.data.player_character_data then
            TheWorld.components.persistent2hm.data.player_character_data = {}
        end
        if not TheWorld.components.persistent2hm.data.player_character_data[userid] then
            TheWorld.components.persistent2hm.data.player_character_data[userid] = {}
        end
        
        local current_data = TheWorld.components.persistent2hm.data.player_character_data[userid][character_name]
        if current_data and current_data.sync_time and current_data.sync_time >= data.sync_time then
            return
        end
        
        -- 替换数据
        TheWorld.components.persistent2hm.data.player_character_data[userid][character_name] = data
        
        -- 如果玩家在当前世界，立即更新其技能状态
        for _, player in ipairs(AllPlayers) do
            if player.userid == userid and player.prefab == character_name then
                if player.components.skilltreeupdater and player.components.skilltreeupdater.skilltree then

                    player.components.skilltreeupdater.skilltree:SetSkillXP2hm(character_name, data.custom_experience or 0)

                    if data.activated_skills then
                        local activated_skills = {}
                        for skill_name, is_active in pairs(data.activated_skills) do
                            if is_active then
                                activated_skills[skill_name] = true
                            end
                        end
                        player.components.skilltreeupdater.skilltree.activatedskills[character_name] = activated_skills
                    end
                    player.components.skilltreeupdater.skilltree.dirty = true
                end

                SyncDataToClient(player, data.days_played or 0, data.custom_experience or 0)
                break
            end
        end
    end
end)

-- 服务器端执行数据保存和玩家角色数据获取
AddComponentPostInit("persistent2hm", function(self)

    -- 存档时保存技能树数据到世界组件
    local oldOnSave = self.OnSave
    self.OnSave = function(self)
        local data = oldOnSave and oldOnSave(self) or {}
        if self.data.player_character_data then data.player_character_data = self.data.player_character_data end 
        return data
    end

    -- 技能树数据从世界存档恢复
    local oldOnLoad = self.OnLoad
    self.OnLoad = function(self, data)
        if oldOnLoad then oldOnLoad(self, data) end
        if data and data.player_character_data then self.data.player_character_data = data.player_character_data end
    end
    
    -- 获取玩家角色数据
    self.GetPlayerCharacterData = function(self, userid, character_name)
        if not self.data.player_character_data then self.data.player_character_data = {} end
        if not self.data.player_character_data[userid] then self.data.player_character_data[userid] = {} end
        if not self.data.player_character_data[userid][character_name] then
            self.data.player_character_data[userid][character_name] = {
                days_played = 0,
                custom_experience = 0,
                activated_skills = {},
                initialized_2hm = false
            }
        end
        
        local data = self.data.player_character_data[userid][character_name]
        if not data.activated_skills then data.activated_skills = {} end
        
        return data
    end
    
    -- 设置玩家角色数据并同步
    self.SetPlayerCharacterData = function(self, userid, character_name, data)
        if not self.data.player_character_data then self.data.player_character_data = {} end   
        if not self.data.player_character_data[userid] then self.data.player_character_data[userid] = {} end

        self.data.player_character_data[userid][character_name] = data

        SyncSkillDataToOtherWorld(userid, character_name, data)
    end
end)

-- ============================================================================
-- 核心技能系统
local skillpointsopt = GetModConfigData("Skilltree Points")


TUNING.SKILL_THRESHOLDS = {}
for i = 1, 30 do TUNING.SKILL_THRESHOLDS[i] = EXP_PER_POINT end

local startskills = math.clamp(-skillpointsopt - 1, 0, 15)
local start_experience = startskills * EXP_PER_POINT

AddPlayerPostInit(function(inst)

    if not TheWorld.ismastersim then return end

    if not TheWorld.components.persistent2hm then TheWorld:AddComponent("persistent2hm") end

    inst:DoTaskInTime(0, function()

        local function wait_for_userid()
            if inst.components.skilltreeupdater and inst.userid and inst.userid ~= "" then
                local data = TheWorld.components.persistent2hm:GetPlayerCharacterData(inst.userid, inst.prefab)

                initialize_player_skills(inst, data)
            else
                inst:DoTaskInTime(0.5, wait_for_userid)
            end
        end
        
        wait_for_userid()
    end)        
end)


function initialize_player_skills(inst, data)
    local max_xp = GetMaxExperience(inst.prefab)
    
    if not data.initialized_2hm then   
        data.custom_experience = math.min(start_experience, max_xp)
        data.days_played = 0
        data.initialized_2hm = true
        
        -- 同步初始数据到所有世界
        if TheShard:IsMaster() then TheWorld.components.persistent2hm:SetPlayerCharacterData(inst.userid, inst.prefab, data) end

    else
        if TheShard:IsMaster() and data.activated_skills then
            local skill_count = 0
            for _, _ in pairs(data.activated_skills) do skill_count = skill_count + 1 end
            if skill_count > 0 then
                TheWorld.components.persistent2hm:SetPlayerCharacterData(inst.userid, inst.prefab, data)
            end
        end
    end

    -- 初始化激活技能
    if data.activated_skills then

        local skills_to_restore = {}
        local skill_count = 0
        for skill_name, is_activated in pairs(data.activated_skills) do
            if is_activated then
                table.insert(skills_to_restore, skill_name)
                skill_count = skill_count + 1
            end
        end
        
        if skill_count > 0 then
            inst._restoring_skills = true
            inst._skill_restore_protection = true  
            
            -- 临时给予足够的经验用于激活流程
            local original_experience = data.custom_experience
            data.custom_experience = skill_count * EXP_PER_POINT
            inst.components.skilltreeupdater.skilltree:SetSkillXP2hm(inst.prefab, data.custom_experience)
            inst.components.skilltreeupdater.skilltree.activatedskills[inst.prefab] = {}

            local sorted_skills = SortSkillsByDependency(skills_to_restore, inst.prefab)
            
            -- 临时禁用验证以确保恢复成功
            local old_skip_validation = inst.components.skilltreeupdater.skilltree.skip_validation
            inst.components.skilltreeupdater.skilltree.skip_validation = true
            
            -- 批量激活技能 
            local restored_count = 0
            for i, skill_name in ipairs(sorted_skills) do
                if inst.components.skilltreeupdater.skilltree:IsActivated(skill_name, inst.prefab) then
                    restored_count = restored_count + 1
                    inst:PushEvent("onactivateskill_server", {skill = skill_name, restored = true})
                end
                
                -- 调用原版 ActivateSkill
                local success = false
                pcall(function()
                    success = inst.components.skilltreeupdater:ActivateSkill(skill_name, inst.prefab, true)
                end)
                
                if not success then
                    -- 直接设置激活状态 + 手动触发回调
                    if not inst.components.skilltreeupdater.skilltree.activatedskills[inst.prefab] then
                        inst.components.skilltreeupdater.skilltree.activatedskills[inst.prefab] = {}
                    end
                    inst.components.skilltreeupdater.skilltree.activatedskills[inst.prefab][skill_name] = true                    
                    -- 触发技能激活回调
                    pcall(function() inst.components.skilltreeupdater:ActivateSkill_Server(skill_name) end)
                    success = true
                end
                
                if success then  
                    restored_count = restored_count + 1  
                    -- 为每个激活的技能触发服务器端事件，确保监听器生效
                    inst:PushEvent("onactivateskill_server", {skill = skill_name, restored = true})
                end
            end
            
            -- 验证恢复设置
            inst.components.skilltreeupdater.skilltree.skip_validation = old_skip_validation
            
            -- 验证恢复结果
            local actual_restored = inst.components.skilltreeupdater.skilltree:GetActivatedSkills(inst.prefab) or {}
            local actual_count = 0
            for _ in pairs(actual_restored) do actual_count = actual_count + 1 end
            
            -- 更新存储状态以匹配实际状态
            data.activated_skills = {}
            for skill_name, _ in pairs(actual_restored) do
                data.activated_skills[skill_name] = true
            end
            
            -- 立即保存状态到持久化存储
            if TheWorld.components.persistent2hm.data then
                TheWorld.components.persistent2hm.data.player_character_data = 
                    TheWorld.components.persistent2hm.data.player_character_data or {}
                TheWorld.components.persistent2hm.data.player_character_data[inst.userid] = 
                    TheWorld.components.persistent2hm.data.player_character_data[inst.userid] or {}
                TheWorld.components.persistent2hm.data.player_character_data[inst.userid][inst.prefab] = data
            end
            
            inst._restoring_skills = false
            inst._skill_restore_protection = false  -- 移除保护标志
            
            -- 技能恢复完成后，手动触发同步到其他世界 
            if restored_count > 0 then
                data.custom_experience = original_experience
                TheWorld.components.persistent2hm:SetPlayerCharacterData(inst.userid, inst.prefab, data)
            end
            
            -- 恢复正确的经验值
            data.custom_experience = original_experience
            inst.components.skilltreeupdater.skilltree:SetSkillXP2hm(inst.prefab, data.custom_experience)
            
        end
    end

    -- 延迟再次同步，确保数据一致性
    inst:DoTaskInTime(0.5, function()
        if inst.components.skilltreeupdater and inst.components.skilltreeupdater.skilltree then
            inst.components.skilltreeupdater.skilltree:SetSkillXP2hm(inst.prefab, data.custom_experience)
            inst.components.skilltreeupdater.skilltree.dirty = true
            
            local final_activated = inst.components.skilltreeupdater.skilltree:GetActivatedSkills(inst.prefab) or {}
            local final_count = 0
            for skill_name, _ in pairs(final_activated) do 
                final_count = final_count + 1
            end
            
            local stored_count = 0
            for skill_name, is_active in pairs(data.activated_skills) do
                if is_active then 
                    stored_count = stored_count + 1
                end
            end
            
            if final_count ~= stored_count then
                data.activated_skills = {}
                for skill_name, _ in pairs(final_activated) do
                    data.activated_skills[skill_name] = true
                end
            end
            
            -- 延迟同步，采用重试机制确保客户端准备就绪 
            local function delayed_sync_with_retry(attempt)
                attempt = attempt or 1
                local max_attempts = 5
                local delays = {1, 2, 3, 5, 8} 
                
                if attempt > max_attempts then
                    return
                end
                
                inst:DoTaskInTime(delays[attempt], function()
                    if inst and inst:IsValid() and inst.components.skilltreeupdater and inst.components.skilltreeupdater.skilltree then
                        SyncDataToClient(inst, data.days_played, data.custom_experience)
                        
                        -- 第一次尝试后，继续尝试几次确保同步成功
                        if attempt < 3 then
                            delayed_sync_with_retry(attempt + 1)
                        end
                    else
                        delayed_sync_with_retry(attempt + 1)
                    end
                end)
            end

            delayed_sync_with_retry(1)

            SyncDataToClient(inst, data.days_played, data.custom_experience)
        end
    end)
        
    
    -- 监听天数变化，增加经验
    inst:WatchWorldState("cycles", function()
        
        if inst.components.skilltreeupdater and inst.userid and inst.prefab then
            local data = TheWorld.components.persistent2hm:GetPlayerCharacterData(inst.userid, inst.prefab)
            
            if not data then return end
            
            if data.custom_experience == nil then data.custom_experience = 0 end
            if data.days_played == nil then data.days_played = 0 end
            
            local max_xp = GetMaxExperience(inst.prefab)
            if not max_xp then max_xp = DEFAULT_MAX_POINTS * EXP_PER_POINT end
            
            data.days_played = data.days_played + 1
            
            local total = 0
            if inst.components.skilltreeupdater.skilltree then
                local skills = inst.components.skilltreeupdater.skilltree:GetActivatedSkills(inst.prefab)
                if skills then
                    for k, v in pairs(skills) do
                        total = total + 1
                    end
                end
            end
            local available_points = CalculateAvailablePoints(data.custom_experience)

            if max_xp > (total + available_points) * EXP_PER_POINT then
                data.custom_experience = math.min(data.custom_experience + 1, max_xp)
                      
                -- 数据同步
                TheWorld.components.persistent2hm:SetPlayerCharacterData(inst.userid, inst.prefab, data)                    
                inst.components.skilltreeupdater.skilltree:SetSkillXP2hm(inst.prefab, data.custom_experience)                   
                inst.components.skilltreeupdater.skilltree.dirty = true                    
                SyncDataToClient(inst, data.days_played, data.custom_experience)
            end
        end
    end)
end

-- 技能树激活系统重构
AddComponentPostInit("skilltreeupdater", function(self)
    
    -- 禁用原版经验获取
    local oldAddSkillXP = self.AddSkillXP
    self.AddSkillXP = function(self, amount, characterprefab, fromrpc)
        local inst = self.inst

        if inst and inst.userid and TheWorld.ismastersim and TheWorld.components.persistent2hm then
            local data = TheWorld.components.persistent2hm:GetPlayerCharacterData(inst.userid, inst.prefab)
            if data and data.custom_experience ~= nil then
                return false -- 直接返回false，阻止原版经验增加
            end
        end

        return oldAddSkillXP(self, amount, characterprefab, fromrpc)
    end
    
    -- 添加自定义经验获取用于测试
    -- ThePlayer.components.skilltreeupdater:AddSkillXP2hm(100)
    self.AddSkillXP2hm = function(self, amount, characterprefab)
        local inst = self.inst
        if not inst or not inst.userid or not TheWorld.ismastersim then return false end
        
        local target_prefab = characterprefab or inst.prefab
        if not target_prefab then return false end
        
        local data = TheWorld.components.persistent2hm:GetPlayerCharacterData(inst.userid, target_prefab)
        if not data then return false end

        local max_xp = GetMaxExperience(target_prefab)

        local old_exp = data.custom_experience or 0
        data.custom_experience = math.min(old_exp + amount, max_xp)
        
        TheWorld.components.persistent2hm:SetPlayerCharacterData(inst.userid, target_prefab, data)
        
        self.skilltree:SetSkillXP2hm(target_prefab, data.custom_experience)
        self.skilltree.dirty = true
        
        SyncDataToClient(inst, data.days_played or 0, data.custom_experience)

        return data.custom_experience - old_exp
    end
    
    -- 初始化时禁用原版的技能树激活状态
    local oldSetPlayerSkillSelection = self.SetPlayerSkillSelection
    self.SetPlayerSkillSelection = function(self, skillselection)
        local inst = self.inst       

        if inst._skill_restore_protection then return end

        if inst and inst.userid and TheWorld and TheWorld.ismastersim and TheWorld.components.persistent2hm then
            local data = TheWorld.components.persistent2hm:GetPlayerCharacterData(inst.userid, inst.prefab)
            if data and data.custom_experience ~= nil then
                return
            end
        end
        
        return oldSetPlayerSkillSelection(self, skillselection)
    end
    
    local oldSendFromSkillTreeBlob = self.SendFromSkillTreeBlob
    self.SendFromSkillTreeBlob = function(self, inst, activatedskills, ...)
        
        if inst._skill_restore_protection then return end

        if inst and inst.userid and TheWorld and TheWorld.ismastersim and TheWorld.components.persistent2hm then
            local data = TheWorld.components.persistent2hm:GetPlayerCharacterData(inst.userid, inst.prefab)
            if data and data.custom_experience ~= nil then
                return
            end
        end         
        return oldSendFromSkillTreeBlob(self, inst, activatedskills, ...)
    end
    
    local oldActivateSkill = self.ActivateSkill
    self.ActivateSkill = function(self, skill, prefab, fromrpc)
        local inst = self.inst
        local characterprefab = inst.prefab

        if TheWorld.ismastersim then
            if inst.userid and TheWorld.components.persistent2hm then    
                local data = TheWorld.components.persistent2hm:GetPlayerCharacterData(inst.userid, characterprefab)
                if (not data or data.custom_experience < EXP_PER_POINT) or 
                   self.skilltree:IsActivated(skill, characterprefab) or 
                   (not self.skilltree:IsValidSkill(skill, characterprefab)) then return false end

                local old_skip_validation = self.skilltree.skip_validation

                self.skilltree.skip_validation = true
                
                local was_activated_before = self.skilltree:IsActivated(skill, characterprefab)
                
                local return_value = oldActivateSkill(self, skill, prefab, fromrpc)

                self.skilltree.skip_validation = old_skip_validation
                
                local is_activated_after = self.skilltree:IsActivated(skill, characterprefab)
                
                local activation_success = is_activated_after and not was_activated_before
                
                if activation_success then

                    if not inst._restoring_skills then

                        data.custom_experience = data.custom_experience - EXP_PER_POINT
                        
                        if not data.activated_skills then data.activated_skills = {} end
                        data.activated_skills[skill] = true

                        local current_activated = self.skilltree:GetActivatedSkills(characterprefab) or {}
                        local stored_skills = {}
                        for stored_skill, is_active in pairs(data.activated_skills) do
                            if is_active then stored_skills[stored_skill] = true end
                        end

                        local inconsistent = false
                        for active_skill, _ in pairs(current_activated) do
                            if not stored_skills[active_skill] then
                                data.activated_skills[active_skill] = true
                                inconsistent = true
                            end
                        end
                        for stored_skill, _ in pairs(stored_skills) do
                            if not current_activated[stored_skill] then
                                data.activated_skills[stored_skill] = nil
                                inconsistent = true
                            end
                        end

                        TheWorld.components.persistent2hm:SetPlayerCharacterData(inst.userid, characterprefab, data)
                    end
                    
                    self.skilltree:SetSkillXP2hm(characterprefab, data.custom_experience)
                    
                    if not inst._restoring_skills then 
                        SyncDataToClient(inst, data.days_played or 0, data.custom_experience)
                    end 

                    return true

                else
                    return false
                end
            else
                return oldActivateSkill(self, skill, prefab, fromrpc)
            end
        else
            return oldActivateSkill(self, skill, prefab, fromrpc)
        end
    end
    
    local oldDeactivateSkill = self.DeactivateSkill

    self.DeactivateSkill = function(self, skill, prefab, fromrpc)
        local inst = self.inst
        local characterprefab = inst.prefab

        if TheWorld.ismastersim then
            
            if not inst.userid then return 
                oldDeactivateSkill(self, skill, prefab, fromrpc) 
            end

            if not self.skilltree:IsActivated(skill, characterprefab) then return false end                
            
            local current_activated_skills = self.skilltree:GetActivatedSkills(characterprefab) or {}
            
            
            local can_forget, dependent_skill = CanSafelyForgetSkill(skill, characterprefab, current_activated_skills)

            if not can_forget then
                return false
            end
            
            local data = TheWorld.components.persistent2hm:GetPlayerCharacterData(inst.userid, characterprefab)
            if not data then
                return oldDeactivateSkill(self, skill, prefab, fromrpc)
            end
            
            local original_xp = data.custom_experience or 0
            
            local was_activated_before = self.skilltree:IsActivated(skill, characterprefab)

            local return_value = oldDeactivateSkill(self, skill, prefab, fromrpc)                

            local is_activated_after = self.skilltree:IsActivated(skill, characterprefab)                

            local deactivation_success = was_activated_before and not is_activated_after

            if deactivation_success then
                local max_xp = GetMaxExperience(characterprefab)

                data.custom_experience = math.min(original_xp + 3, max_xp) 
                
                
                if not data.activated_skills then
                    data.activated_skills = {}
                end

                data.activated_skills[skill] = nil 
                
            
                TheWorld.components.persistent2hm:SetPlayerCharacterData(inst.userid, characterprefab, data)

                self.skilltree:SetSkillXP2hm(characterprefab, data.custom_experience)

                SyncDataToClient(inst, data.days_played or 0, data.custom_experience)
                
                return true
            else
                return false
            end
        else
            return oldDeactivateSkill(self, skill, prefab, fromrpc)
        end
    end
end)

-- 数据保存系统
AddClassPostConstruct("skilltreedata", function(self)

    if not self.skillxp2hm then self.skillxp2hm = {} end
    
    -- 重写经验获取，使用独立的skillxp2hm系统
    local oldGetSkillXP = self.GetSkillXP
    self.GetSkillXP = function(self, characterprefab)
        local inst = self.owner

        if inst and inst.userid and TheWorld and TheWorld.components.persistent2hm then
            local data = TheWorld.components.persistent2hm:GetPlayerCharacterData(inst.userid, characterprefab)
            if data and data.custom_experience ~= nil then
                local max_xp = (maxpoints[characterprefab] or 30) * 5 -- EXP_PER_POINT = 5
                data.custom_experience = math.min(data.custom_experience, max_xp)
                self.skillxp2hm[characterprefab] = data.custom_experience
                return data.custom_experience
            end
        end
        
        if self.skillxp2hm[characterprefab] then
            return self.skillxp2hm[characterprefab]
        end
        
        local current_xp = oldGetSkillXP(self, characterprefab) or 0
        if not inst or not inst.userid then
            local max_xp = GetMaxExperience(characterprefab)
            current_xp = math.min(current_xp, max_xp)
        end
        return current_xp
    end

    local oldGetAvailableSkillPoints = self.GetAvailableSkillPoints
    self.GetAvailableSkillPoints = function(self, characterprefab)
        local inst = self.owner
        if inst and inst.userid and TheWorld and TheWorld.components.persistent2hm then
            local data = TheWorld.components.persistent2hm:GetPlayerCharacterData(inst.userid, characterprefab)
            if data and data.custom_experience ~= nil then
                -- 使用独立的经验系统计算可用点数
                return CalculateAvailablePoints(data.custom_experience)
            end
        end

        if self.skillxp2hm and self.skillxp2hm[characterprefab] then
            return CalculateAvailablePoints(self.skillxp2hm[characterprefab])
        end
        
        local current_xp = self:GetSkillXP(characterprefab) or 0
        if not inst or not inst.userid then
            local max_xp = GetMaxExperience(characterprefab)
            current_xp = math.min(current_xp, max_xp)
        end
        return CalculateAvailablePoints(current_xp)
    end
    
    local oldGetPointsForSkillXP = self.GetPointsForSkillXP
    self.GetPointsForSkillXP = function(self, skillxp)
        local inst = self.owner
        if inst and inst.userid and TheWorld and TheWorld.components.persistent2hm then
            -- 5点经验=1个技能点
            return CalculateAvailablePoints(skillxp)
        end
        return oldGetPointsForSkillXP(self, skillxp)
    end

    local oldValidateCharacterData = self.ValidateCharacterData
    self.ValidateCharacterData = function(self, characterprefab, activatedskills, skillxp_input)
        local inst = self.owner
        
        -- 跳过经验数量验证
        if inst and inst.userid and TheWorld and TheWorld.ismastersim and TheWorld.components.persistent2hm then
            local data = TheWorld.components.persistent2hm:GetPlayerCharacterData(inst.userid, characterprefab)
            if data and data.custom_experience ~= nil then

                local allocatedskills = 0
                if activatedskills then
                    for _ in pairs(activatedskills) do
                        allocatedskills = allocatedskills + 1
                    end
                end

                return true
            end
        end
        
        -- 客户端没有persistent2hm数据
        if inst and inst.userid and not (TheWorld and TheWorld.ismastersim) then
            return true
        end
        
        if not inst or not inst.userid then
            return true
        end
        
        return oldValidateCharacterData(self, characterprefab, activatedskills, skillxp_input)
    end
    
    self.GetSkillXP2hm = function(self, characterprefab)
        return self.skillxp2hm and self.skillxp2hm[characterprefab] or 0
    end
    
    self.SetSkillXP2hm = function(self, characterprefab, experience)
        if not self.skillxp2hm then
            self.skillxp2hm = {}
        end
        self.skillxp2hm[characterprefab] = experience
    end
    
end)

-- ui界面系统
AddClassPostConstruct("widgets/redux/skilltreebuilder", function(self)
    local Text = require "widgets/text"
    local COLOR = self.fromfrontend and UICOLOURS.GOLD or UICOLOURS.BLACK

    if self.root and self.root.xp then 
        if not self.root.xp_days_played then
            self.root.xp_days_played = self.root.xp:AddChild(Text(HEADERFONT, 25, 0, COLOR))
            self.root.xp_days_played:SetHAlign(ANCHOR_LEFT)
        end            
        if not self.root.xp_experience then
            self.root.xp_experience = self.root.xp:AddChild(Text(HEADERFONT, 25, 0, COLOR))
            self.root.xp_experience:SetHAlign(ANCHOR_LEFT)
        end
    end

    local oldRefreshTree = self.RefreshTree
    self.RefreshTree = function(self, skillschanged)

        if not (self and self.inst and self.inst:IsValid()) then return end
        
        oldRefreshTree(self, skillschanged)
        
        -- 快速加点需保持边框的隐藏状态
        if self.selectedskill and self.skillgraphics and self.skillgraphics[self.selectedskill] then
            if not TheInput:ControllerAttached() then
                self.skillgraphics[self.selectedskill].frame:Hide()
            end
        end
        
        local characterprefab = self.target
        local readonly = self.readonly
        local skilltreeupdater = self.fromfrontend and TheSkillTree or 
                                (ThePlayer and ThePlayer.components.skilltreeupdater)
        
        local days_played, experience, max_exp = 0, 0, 0
        
        -- 在客户端，优先使用同步的数据
        if not TheWorld.ismastersim and GetClientCustomData then
            local client_data = GetClientCustomData(characterprefab)
            experience = client_data.custom_experience or 0
            days_played = client_data.days_played or 0
            max_exp = GetMaxExperience(characterprefab)
        elseif self.fromfrontend then
            -- 前端状态：使用技能树更新器获取经验，并应用我们的经验上限
            experience = skilltreeupdater:GetSkillXP(characterprefab) or 0
            max_exp = GetMaxExperience(characterprefab)
            -- 确保经验不超过我们的上限
            experience = math.min(experience, max_exp)
            days_played = math.floor(experience / 1) -- 估算天数
        elseif skilltreeupdater then
            -- 服务器端或游戏中，使用技能树更新器获取当前经验
            experience = skilltreeupdater:GetSkillXP(characterprefab) or 0
            max_exp = GetMaxExperience(characterprefab)
            days_played = math.floor(experience / 1) -- 估算天数
        end

        -- 更新游玩天数，游玩经验
        if self.root and self.root.xp_days_played and self.root.xp_days_played.inst and self.root.xp_days_played.inst:IsValid() then
            local prefix = TUNING.isCh2hm and "游玩天数: " or "has played: "
            local suffix = TUNING.isCh2hm and "天" or " days"
            self.root.xp_days_played:SetString(prefix .. tostring(days_played) .. suffix)
            local w2, h2 = self.root.xp_days_played:GetRegionSize()
            self.root.xp_days_played:SetPosition(-100-(w2/2), 12)
            self.root.xp_days_played:Show()
        end
        if self.root and self.root.xp_experience and self.root.xp_experience.inst and self.root.xp_experience.inst:IsValid() then
            local prefix = TUNING.isCh2hm and "游玩经验: " or "exp: "
            self.root.xp_experience:SetString(prefix .. tostring(experience) .. "/" .. tostring(max_exp))
            local w3, h3 = self.root.xp_experience:GetRegionSize()
            self.root.xp_experience:SetPosition(100+(w3/2), 12)
            self.root.xp_experience:Show()
        end
        
        -- 更新剩余洞察点显示
        if self.root and self.root.xptotal and self.root.xptotal.inst and self.root.xptotal.inst:IsValid() then
            local available_points = 0
            if not TheWorld.ismastersim and GetClientCustomData then
                -- 客户端使用同步的数据
                local client_data = GetClientCustomData(characterprefab)
                available_points = CalculateAvailablePoints(client_data.custom_experience or 0)
            elseif self.fromfrontend then
                -- 前端状态：使用我们的计算方式
                available_points = CalculateAvailablePoints(experience)
            else
                -- 服务器端或游戏中
                available_points = CalculateAvailablePoints(experience)
            end
            self.root.xptotal:SetString(tostring(available_points))
        end

        
        if self.fromfrontend then
            -- 选人界面只显示状态，禁用所有交互
            if self.infopanel then
                if self.infopanel.activatebutton then self.infopanel.activatebutton:Hide() end
                if self.infopanel.respec_button then self.infopanel.respec_button:Hide() end
                
                if self.selectedskill and skilltreeupdater then
                    local skill_activated = skilltreeupdater:IsActivated(self.selectedskill, characterprefab)
                    if skill_activated and not self.skilltreedef[self.selectedskill].infographic then
                        if self.infopanel.activatedbg then self.infopanel.activatedbg:Show() end
                        if self.infopanel.activatedtext then self.infopanel.activatedtext:Show() end
                    end
                end
            end
        else
            if self.selectedskill and self.infopanel and not readonly and skilltreeupdater then
                local skill_activated = skilltreeupdater:IsActivated(self.selectedskill, characterprefab)
                
                if skill_activated then
                    local skill_data = self.skilltreedef[self.selectedskill]
                    local can_forget = skill_data and not skill_data.infographic and not skill_data.lock_open

                    -- 替换"已掌握技能"为"遗忘"按钮
                    if can_forget then
                        if self.infopanel.activatedbg then self.infopanel.activatedbg:Hide() end
                        if self.infopanel.activatedtext then self.infopanel.activatedtext:Hide() end
                        
                        if self.infopanel.activatebutton then
                            self.infopanel.activatebutton:Show()
                            self.infopanel.activatebutton:SetText(TUNING.isCh2hm and "遗忘(+3经验)" or "Forget(+3 exp)")
                            self.infopanel.activatebutton:SetOnClick(function()
                                self:ForgetSkill(skilltreeupdater, characterprefab)
                            end)
                        end
                    end
                else
                    -- 未激活时保持学习按钮
                    if self.infopanel.activatebutton then
                        self.infopanel.activatebutton:SetText(TUNING.isCh2hm and "学习(-5经验)" or "Learn(-5 exp)")
                    end
                end
            end
        end
    end
    
    -- 添加客户端事件监听
    if not self.fromfrontend and ThePlayer then
        ThePlayer:ListenForEvent("onupdateskillxp_client", function(player, data)
            if data and data.characterprefab == self.target and self.inst and self.inst:IsValid() then
                self:RefreshTree(true)
            end
        end)
    end

    -- 遗忘技能方法
    self.ForgetSkill = function(self, skilltreeupdater, characterprefab)
        if not self.selectedskill then return end
        
        local skill_data = self.skilltreedef[self.selectedskill]
        local is_activated = skilltreeupdater:IsActivated(self.selectedskill, characterprefab)
        local can_forget = skill_data and not skill_data.infographic and not skill_data.lock_open and is_activated
        
        if not can_forget then return end

        -- 检查依赖关系
        if TheWorld.ismastersim then
            local current_activated_skills = skilltreeupdater:GetActivatedSkills() or {}
            local safe_to_forget, dependent_skill = CanSafelyForgetSkill(self.selectedskill, characterprefab, current_activated_skills)
            
            if not safe_to_forget then return end
        end

        -- 执行遗忘功能
        if TheWorld.ismastersim then
            -- 直接调用服务器端的DeactivateSkill方法
            skilltreeupdater:DeactivateSkill(self.selectedskill, characterprefab)
        else
            -- 发送自定义RPC到服务器
            SendModRPCToServer(MOD_RPC["EasyMode2hm"]["DeactivateSkill"], self.selectedskill)
        end

        -- 播放遗忘效果
        if self.skillgraphics[self.selectedskill] and self.skillgraphics[self.selectedskill].button then
            local pos = self.skillgraphics[self.selectedskill].button:GetPosition()
            local UIAnim = require "widgets/uianim"
            local clickfx = self:AddChild(UIAnim())
            clickfx:GetAnimState():SetBuild("skills_activate")
            clickfx:GetAnimState():SetBank("skills_activate")
            clickfx:GetAnimState():PushAnimation("idle")
            clickfx:GetAnimState():SetMultColour(1, 0.5, 0.5, 1)
            clickfx.inst:ListenForEvent("animover", function() clickfx:Kill() end)
            clickfx:SetPosition(pos.x, pos.y + 15)
            TheFrontEnd:GetSound():PlaySound("wilson_rework/ui/shadow_skill")
        end      

        self.inst:DoTaskInTime(0.1, function() self:RefreshTree(true) end)
    end
end)


-- ============================================================================
-- 技能树快速加点,冲突技能解禁
local function LearnParentSkill(self, current_skill, skilltreeupdater)
    for skill, skilldata in pairs(self.skilltreedef) do
        if skilldata and not skilldata.lock_open and skilldata.connects then
            for _, connected_skill in ipairs(skilldata.connects) do
                if connected_skill == current_skill and self.skillgraphics[skill] then
                    if self.skillgraphics[skill].status and self.skillgraphics[skill].status.activatable then
                        skilltreeupdater:ActivateSkill(skill, self.target)
                        local pos = self.skillgraphics[skill].button:GetPosition()
                        local UIAnim = require "widgets/uianim"
                        local clickfx = self:AddChild(UIAnim())
                        clickfx:GetAnimState():SetBuild("skills_activate")
                        clickfx:GetAnimState():SetBank("skills_activate")
                        clickfx:GetAnimState():PushAnimation("idle")
                        clickfx.inst:ListenForEvent("animover", function() clickfx:Kill() end)
                        clickfx:SetPosition(pos.x,pos.y + 15)
                        TheFrontEnd:GetSound():PlaySound("wilson_rework/ui/skill_mastered")
                        return true
                    else
                        return LearnParentSkill(self, skill, skilltreeupdater)
                    end
                end
            end
        end
    end
    return false
end

AddClassPostConstruct("widgets/redux/skilltreebuilder", function(self)
    local old_buildbuttons = self.buildbuttons
    self.buildbuttons = function(self, ...)
        old_buildbuttons(self, ...)
        
        -- 前端模式下禁用快速加点功能
        if self.fromfrontend then return end
        
        if not self.buttongrid then return end
        
        for _, data in ipairs(self.buttongrid) do
            if data and data.button then
                local old_onclick = data.button.onclick
                data.button:SetOnClick(function(...)
                    if not TheInput:ControllerAttached() and self.skillgraphics then
                        for skill, graphics in pairs(self.skillgraphics) do
                            if graphics and graphics.button == data.button and self.selectedskill == skill then
                                -- 直接学习可激活技能
                                if graphics.status and graphics.status.activatable and self.infopanel.activatebutton:IsVisible() then
                                    self:LearnSkill(ThePlayer and ThePlayer.components.skilltreeupdater, self.target)
                                    break
                                else
                                    -- 快速加点：先学习前置技能
                                    local skilltreeupdater = ThePlayer and ThePlayer.components.skilltreeupdater
                                    if skilltreeupdater then
                                        local available_points = skilltreeupdater:GetAvailableSkillPoints(self.target) or 0
                                        if available_points > 0 and self.skilltreedef and self.skilltreedef[skill] and not self.skilltreedef[skill].root then
                                            LearnParentSkill(self, skill, skilltreeupdater)
                                        end
                                    end
                                end
                            end
                        end
                    end
                    old_onclick(...)
                    
                    -- 确保UI状态正确更新，保持选中状态
                    if not TheInput:ControllerAttached() then
                        self.inst:DoTaskInTime(0.05, function()
                            self:RefreshTree(false)
                        end)
                    end
                end)
            end
        end
    end
end)

-- 优化技能树提示显示
AddClassPostConstruct("widgets/skilltreetoast", function(self)
    self.tab_gift:Hide()
    self.shownotification = Profile:GetScrapbookHudDisplay()
    
    local UpdateElements = self.UpdateElements
    self.UpdateElements = function(self, ...)
        local craft_hide = self.craft_hide
        self.craft_hide = craft_hide or not self.shownotification
        if self.shownotification then
            self.tab_gift:Show()
        else
            self.tab_gift:Hide()
        end
        UpdateElements(self, ...)
        self.craft_hide = craft_hide
    end
    
    local Onupdate = self.Onupdate
    self.Onupdate = function(self, ...)
        if self.shownotification ~= Profile:GetScrapbookHudDisplay() then
            self.shownotification = Profile:GetScrapbookHudDisplay()
            self:UpdateElements()
        end
        if self.opened then Onupdate(self, ...) end
    end
    
    local UpdateControllerHelp = self.UpdateControllerHelp
    self.UpdateControllerHelp = function(self, ...)
        if self.opened then UpdateControllerHelp(self, ...) end
    end
end)

-- 技能组解禁
local finalTags = {"lunar_favor", "shadow_favor"}
local woodieTags = {"beaver", "moose", "goose"}
local woodieEpicTags = {"beaver_epic", "moose_epic", "goose_epic"}

-- 角色可以同时点出暗影与位面的终极技能
for prefab, skills in pairs(skilltreedefs.SKILLTREE_DEFS) do
    if skills and type(skills) == "table" then
        for skill_name, skill in pairs(skills) do
            if skill and skill.tags then
                for i = #skill.tags, 1, -1 do if table.contains(finalTags, skill.tags[i]) then table.remove(skill.tags, i) end end
            end
        end
    end
end

-- 威尔逊可以拆解宝石
AddRecipe2("transmute_orangegem2hm", {Ingredient("orangegem", 1)}, TECH.NONE,
            {product = "purplegem", numtogive = 2, image = "purplegem.tex", builder_tag = "gem_alchemistII", description = "transmute_orangegem"},
            {"CHARACTER"})
AddRecipe2("transmute_yellowgem2hm", {Ingredient("yellowgem", 1)}, TECH.NONE,
            {product = "orangegem", numtogive = 2, image = "orangegem.tex", builder_tag = "gem_alchemistII", description = "transmute_yellowgem"},
            {"CHARACTER"})
AddRecipe2("transmute_greengem2hm", {Ingredient("greengem", 1)}, TECH.NONE,
            {product = "yellowgem", numtogive = 2, image = "yellowgem.tex", builder_tag = "gem_alchemistIII", description = "transmute_greengem"},
            {"CHARACTER"})

-- 薇诺娜可以点出双终极技能
if skilltreedefs.SKILLTREE_DEFS and skilltreedefs.SKILLTREE_DEFS.winona then
    local skills = skilltreedefs.SKILLTREE_DEFS.winona
    if skills and type(skills) == "table" and skills.winona_wagstaff_2_lock and skills.winona_charlie_2_lock then
        skills.winona_wagstaff_2_lock.lock_open = function(prefabname, activatedskills, readonly)
            return activatedskills and activatedskills["winona_wagstaff_1"]
        end
        skills.winona_charlie_2_lock.lock_open = function(prefabname, activatedskills, readonly)
            return activatedskills and activatedskills["winona_charlie_1"]
        end
    end
end

-- 伍迪可以点出三个形态的最后技能
local FN = skilltreedefs.FN
if skilltreedefs.FN and skilltreedefs.FN.CountTags then
    local old = skilltreedefs.FN.CountTags
    skilltreedefs.FN.CountTags = function(prefab, targettag, ...)
        if targettag then
            if table.contains(woodieTags, targettag) then
                TUNING.woodieEpicTags2hm = 2
            elseif TUNING.woodieEpicTags2hm and TUNING.woodieEpicTags2hm > 0 and table.contains(woodieEpicTags, targettag) then
                TUNING.woodieEpicTags2hm = TUNING.woodieEpicTags2hm - 1
                return 0
            elseif TUNING.woodieEpicTags2hm then
                TUNING.woodieEpicTags2hm = nil
            end
        end
        return old(prefab, targettag, ...)
    end
end

-- 薇格弗德妥协重做部分回调,且依旧可以做曲子
if TUNING.DSTU and TUNING.DSTU.WATHGRITHR_REWORK then

    local skills = skilltreedefs.SKILLTREE_DEFS and skilltreedefs.SKILLTREE_DEFS.wathgrithr
    if skills and skills.wathgrithr_allegiance_lock_1 and skills.wathgrithr_allegiance_lock_1.lock_open then
        skills.wathgrithr_allegiance_lock_1.lock_open = function(prefabname, activatedskills, readonly)
            -- return skilltreedefs.FN.CountSkills(prefabname, activatedskills) = 1
            return true
        end
    end
    if skills and skills.wathgrithr_allegiance_shadow and skills.wathgrithr_allegiance_shadow then
        local onactivate = skills.wathgrithr_allegiance_shadow.onactivate
        skills.wathgrithr_allegiance_shadow.onactivate = function(inst, ...)
            if onactivate then onactivate(inst, ...) end
            inst:AddTag("battlesongshadowalignedmaker")
        end
        local onactivate = skills.wathgrithr_allegiance_lunar.onactivate
        skills.wathgrithr_allegiance_lunar.onactivate = function(inst, ...)
            if onactivate then onactivate(inst, ...) end
            inst:AddTag("battlesonglunaralignedmaker")
        end
        local ondeactivate = skills.wathgrithr_allegiance_shadow.ondeactivate
        skills.wathgrithr_allegiance_shadow.ondeactivate = function(inst, ...)
            if ondeactivate then ondeactivate(inst, ...) end
            inst:RemoveTag("battlesongshadowalignedmaker")
        end
        local ondeactivate = skills.wathgrithr_allegiance_lunar.ondeactivate
        skills.wathgrithr_allegiance_lunar.ondeactivate = function(inst, ...)
            if ondeactivate then ondeactivate(inst, ...) end
            inst:RemoveTag("battlesonglunaralignedmaker")
        end
    end
end

-- ============================================================================
-- 当薇洛同时点出暗影和月亮阵营技能时，伯尼变大后会随机选择一种形态

-- 常量定义
BERNIEALLEGIANCE = {NONE = 0, SHADOW = 1, LUNAR = 2}

AddPrefabPostInit("bernie_big", function(inst)
    if not TheWorld.ismastersim then return end
    
    local old_CheckForAllegiances = inst.CheckForAllegiances
    
    inst.CheckForAllegiances = function(inst, leader)
        if not leader or not leader.components.skilltreeupdater then 
            if old_CheckForAllegiances then
                old_CheckForAllegiances(inst, leader)
            end
            return 
        end
        
        local allegiance = inst.current_allegiance:value()
        local has_shadow = leader.components.skilltreeupdater:IsActivated("willow_allegiance_shadow_bernie")
        local has_lunar = leader.components.skilltreeupdater:IsActivated("willow_allegiance_lunar_bernie")
        
        -- 如果两个阵营都没有，调用原始函数处理清除逻辑
        if not has_shadow and not has_lunar then
            if old_CheckForAllegiances then
                old_CheckForAllegiances(inst, leader)
            end
            return
        end
        
        -- 如果两个阵营都激活了，随机选择一个
        local chosen_shadow = false
        local chosen_lunar = false
        
        if has_shadow and has_lunar then
            if math.random() < 0.5 then
                chosen_shadow = true
            else
                chosen_lunar = true
            end
        elseif has_shadow then
            chosen_shadow = true
        elseif has_lunar then
            chosen_lunar = true
        end
        
        -- 如果当前没有阵营状态，需要初始化阵营形态
        if allegiance == 0 and (chosen_shadow or chosen_lunar) then
            -- 不设置 should_shrink，因为伯尼刚生成时正在执行activate动画
            
            local base_build = chosen_shadow and "bernie_shadow_build" or "bernie_lunar_build"
            inst.AnimState:SetBuild(base_build)
            
            -- 处理皮肤
            local skin_build = inst:GetSkinBuild()
            if skin_build ~= nil then
                local BERNIE_SKIN_SYMBOLS = {
                    "blob_body", "big_tail", "big_strand", "big_leg_upper", "big_leg_lower",
                    "big_head", "big_hand", "big_fluff", "big_ear", "big_body",
                    "big_arm_upper", "big_arm_lower",
                }
                local BERNIE_SMALL_SKIN_SYMBOLS = {
                    "bernie_torso", "bernie_tail", "bernie_legupper", "bernie_leglower",
                    "bernie_inactive", "bernie_headbase", "bernie_head", "bernie_hand",
                    "bernie_face", "bernie_ear", "bernie_armupper", "bernie_armlower",
                }
                
                local modified_skin_build = skin_build .. (chosen_shadow and "_shadow_build" or "_lunar_build")
                for _, symbol in ipairs(BERNIE_SKIN_SYMBOLS) do
                    inst.AnimState:OverrideItemSkinSymbol(symbol, modified_skin_build, symbol, inst.GUID, base_build)
                end
                for _, symbol in ipairs(BERNIE_SMALL_SKIN_SYMBOLS) do
                    inst.AnimState:OverrideItemSkinSymbol(symbol, skin_build, symbol, inst.GUID, skin_build)
                end
            else
                local BERNIE_SKIN_SYMBOLS = {
                    "blob_body", "big_tail", "big_strand", "big_leg_upper", "big_leg_lower",
                    "big_head", "big_hand", "big_fluff", "big_ear", "big_body",
                    "big_arm_upper", "big_arm_lower",
                }
                local BERNIE_SMALL_SKIN_SYMBOLS = {
                    "bernie_torso", "bernie_tail", "bernie_legupper", "bernie_leglower",
                    "bernie_inactive", "bernie_headbase", "bernie_head", "bernie_hand",
                    "bernie_face", "bernie_ear", "bernie_armupper", "bernie_armlower",
                }
                for _, symbol in ipairs(BERNIE_SKIN_SYMBOLS) do
                    inst.AnimState:ClearOverrideSymbol(symbol)
                end
                for _, symbol in ipairs(BERNIE_SMALL_SKIN_SYMBOLS) do
                    inst.AnimState:ClearOverrideSymbol(symbol)
                end
            end
            
            inst.AnimState:SetSymbolBloom("blob_body")           
            inst:AddTag(chosen_shadow and "shadow_aligned" or "lunar_aligned")         
            inst.current_allegiance:set(chosen_shadow and BERNIEALLEGIANCE.SHADOW or BERNIEALLEGIANCE.LUNAR)
            
            if inst.components.planarentity == nil then
                inst:AddComponent("planarentity")
            end
            if inst.components.planardamage == nil then
                inst:AddComponent("planardamage")
            end
            if inst.components.planardefense == nil then
                inst:AddComponent("planardefense")
            end
            
            inst.components.planardamage:SetBaseDamage(TUNING.BERNIE_PLANAR_DAMAGE)
            inst.components.planardefense:SetBaseDefense(TUNING.BERNIE_PLANAR_DEFENCE)
        end
    end
end)
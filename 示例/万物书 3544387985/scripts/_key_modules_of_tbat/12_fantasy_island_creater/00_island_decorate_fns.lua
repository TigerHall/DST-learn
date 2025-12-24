--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    装修岛屿用的 扫描代码。

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


        local this_anchor = TheSim:FindEntities(x, 0, z, 10, {"tbat_room_anchor_fantasy_island"})[1]
        
        if this_anchor._test_fx then
            this_anchor._test_fx:Remove()
        end

        local RADIUS = 20

        local fx = this_anchor:SpawnChild("tbat_sfx_dotted_circle_client")
        fx:PushEvent("Set",{
            radius = RADIUS,
        })
        local r,g,b = 0/255,255/255,0/255
        local Temp_COLOR_1 = {r,g,b,0}
        local Temp_COLOR_2 = {r,g,b,1}
        fx.AnimState:SetAddColour(unpack(Temp_COLOR_1))
        fx.AnimState:SetMultColour(unpack(Temp_COLOR_2))
        fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        this_anchor._test_fx = fx


        local black_list_prefab = {
            ["tbat_sfx_ground_fireflies"] = true ,
        }
        local black_tags = {"fx","FX","tbat_room_anchor_fantasy_island","player"}
        
        local test_fn = function(inst)
            if inst.prefab == nil or black_list_prefab[inst.prefab] then
                return false
            end
            if inst.entity:GetParent() then
                return false
            end
            if inst:HasOneOfTags(black_tags) then
                return false
            end
            if inst.sg then
                return false
            end
            if inst.brainfn then
                return false
            end
            if inst.components.inventoryitem then
                return false
            end
            return true
        end

        local x,y,z = this_anchor.Transform:GetWorldPosition()
        local anchor_pos = Vector3(x,y,z)
        local ents = TheSim:FindEntities(x,y,z, RADIUS)
        local prefab_list = {}
        for i,v in ipairs(ents) do
            if test_fn(v) then
                prefab_list[v.prefab] = v:GetDisplayName()
            end
        end
        for prefab, name in pairs(prefab_list) do
            print('["'..prefab..'"]=true,#'..name..'@')
        end

        local save_data = false

        local white_list = {
            
        }

            -- data = {
            --     [prefab_or_skin ] = {
            --         prefab = "driftwood_tall" ,
            --         points = { Vector3(0,0,0),Vector3(1,0,1) },  --- 根据点个数生成对应数量的目标
            --         points_str = "",                             --- 【可选】坐标的 json 格式。
            --         pt = Vector3(0,0,0),                         --- 【可选】单个的时候可选这个。
            --         rotation = 0,                                --- 【可选】旋转角度
            --         fn = function(inst) end,                     --- 【可选】执行特殊函数
            --         tbat_skin = nil,                             --- 【可选】本MOD的物品皮肤皮肤
            --         has_tbat_skin = true,                         --- 【可选】以index 为皮肤名字。
            --         mirror = nil,                                --- 【可选】镜像
            --         scale = {1,1,1},                             --- 【可选】缩放
            --         health_percent = nil,                        --- 【可选】生命百分比
            --     },
            -- }

        -- local data = {}
        -- for k,target in pairs(ents) do
        --     if white_list[target.prefab] then
        --         local target_pos = Vector3(target.Transform:GetWorldPosition())
        --         local vect = target_pos - anchor_pos
        --         vect.x = math.floor(vect.x*10)/10
        --         vect.y = 0
        --         vect.z = math.floor(vect.z*10)/10

        --         local index = target.prefab
        --         local has_skin = false
        --         if target.components.tbat_com_skin_data then
        --             local current_skin = target.components.tbat_com_skin_data:GetCurrent()
        --             if current_skin ~= nil then
        --                 index = current_skin
        --                 has_skin = true
        --             end
        --         end

        --         local single_data = data[index] or {}
        --         data[index] = single_data
        --         single_data.points = single_data.points or {}

        --         single_data.prefab = target.prefab
        --         table.insert(single_data.points, {x=vect.x,z=vect.z})

        --         if has_skin then
        --             single_data.has_tbat_skin = true
        --         end

        --         local scale_x,scale_y,scale_z = target.AnimState:GetScale()
        --         if scale_x ~= 1 or scale_y ~= 1 or scale_z ~= 1 then
        --             single_data.scale = {scale_x,scale_y,scale_z}
        --         end

        --         if target.components.health then
        --             single_data.health_percent = math.ceil(target.components.health:GetPercent())
        --         end
        --          
        --         save_data = true
        --     end
        -- end

        -- if save_data then
        --     local str = json.encode(data)
        --     -- print(str)
        --     TheSim:SetPersistentString("tbat_fantasy_island_test_data", str, false, function()
        --         print("info tbat_fantasy_island_test_data SAVED!")
        --     end)
        -- end
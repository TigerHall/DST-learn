--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    本文件和 modmain.lua 平级。
    本文件集中注册  components 及其 replica 组件

    特别说明: components 组件不必注册，放到  /script/components 文件夹里就行了。但是这个组件只能 服务器调用（包括带洞穴的存档）
    组件对应的客户端组件 为 replica ，命名方式为：组件原名后面加上“_replica”
    replica 组件必须用 函数 AddReplicableComponent 注册，参数为 组件原名（不带“_replica")
    示例：  inst.components.abcd  组件， 放置  abcd.lua 文件在   components 文件夹里，使用 inst:AddComponent("abcd") 添加。
            对应的replica 文件为   abcd_replica.lua，同样放在   components 文件夹里，必须使用 AddReplicableComponent("abcd") 在 modmain 注册
            客户端使用  inst.replica.abcd 调用 ，相关参数匹配同步 参照官方 已有组件。
        注意： replica 参数传送有一定的延迟，即便是在本机洞穴存档（开启延迟补偿），低延迟方案则必须走 RPC通道

    AddReplicableComponent("npc_base_lib")  --- 示例

    inst:ListenForEvent("TBAT_OnEntityReplicated.XXXX",fn)

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 带 classified 的注册函数，tbat 专属便利API
    --[[
    
        XXX_replica.lua  那边，做一条API ，返回 给 tbat_classified 调用的初始化 api

        local classified_init_fn = function(inst)

        end
        com:GetClassifiedInitFn()
            return classified_init_fn
        end

    ]]--
    TBAT.CLASSIFIED_DATA = {}
    TBAT.CLASSIFIED_INSTALL_FNS = TBAT.CLASSIFIED_INSTALL_FNS or {}
    local function TBAT_AddReplicableComponentWithClassified(com_name)
        AddReplicableComponent(com_name)
        local replica_com = require("components/"..com_name.."_replica")
        if replica_com and replica_com.GetClassifiedInitFn then
            TBAT.CLASSIFIED_DATA[com_name] = replica_com:GetClassifiedInitFn()
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- 添加组件
    TBAT_AddReplicableComponentWithClassified("tbat_com_excample_classified")
    TBAT_AddReplicableComponentWithClassified("tbat_com_custom_tags") -- 客制化 tag 系统

    AddReplicableComponent("tbat_com_rpc_event")  --- RPC通道
    AddReplicableComponent("tbat_com_workable")  --- 通用物品交互
    AddReplicableComponent("tbat_com_acceptable")  --- 通用物品接受
    AddReplicableComponent("tbat_com_item_use_to")  --- 通用物品给予
    AddReplicableComponent("tbat_com_point_and_target_spell_caster")  --- 通用目标、点施法器

    AddReplicableComponent("tbat_com_client_side_data")  --- 客户端数据获取

    AddReplicableComponent("tbat_com_map_jumper")  --- 地图跳跃用

    AddReplicableComponent("tbat_com_mushroom_snail_cauldron")  --- 蘑菇小蜗埚(炼丹炉)
    AddReplicableComponent("tbat_com_mushroom_snail_cauldron__for_player")  --- 蘑菇小蜗埚(炼丹炉) 配方控制器


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---

    if EntityScript.ReplicateComponent_tbat_old_fn == nil then

        -- EntityScript.ReplicateComponent
        EntityScript.ReplicateComponent_tbat_old_fn = EntityScript.ReplicateComponent
        EntityScript.ReplicateComponent = function(self,name)
            self.ReplicateComponent_tbat_old_fn(self,name)
            local replica_com = self.replica[name] or self.replica._[name]
            if replica_com then
                self:PushEvent("TBAT_OnEntityReplicated."..tostring(name),replica_com)
                -- self.replica[name] = replica_com
            end
        end
    end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
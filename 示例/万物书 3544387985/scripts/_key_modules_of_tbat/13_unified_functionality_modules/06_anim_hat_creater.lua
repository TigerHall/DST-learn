--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[

    复制齿轮帽子的相关特效机制

    让帽子可以是个动画

    wagpunkhat

    onequip 里 ：

            inst.hat_fx = SpawnPrefab(hat_fx_prefab)
            if inst.hat_fx ~= nil then 
                inst.hat_fx:AttachToOwner(owner)
            end

]]--
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
    function TBAT.MODULES:CreateAnimHat(prefab,cmd_data,assets)
        -- cmd_data = cmd_data or {
        --     --------------------------------------------------------------------------
        --     --- 特效件本体
        --         common_postinit = function(inst)
                
        --         end,
        --         master_postinit = function(inst)
                
        --         end,
        --     --------------------------------------------------------------------------
        --     --- 子特效件 可能的联动函数 ，只在 客户端运行。
        --         child_fn = function(inst,parent,index)

        --         end,
        --     --------------------------------------------------------------------------
        --     --- 动画  --- i 为  framebegin -> frameend ，其中正面是 1 ，侧面是2，背面是3
        --         bank = "",
        --         build = "",
        --         anim_down = "idle1",
        --         anim_side = "idle2",
        --         anim_up = "idle3",
        --         loop = true,            --- 循环播放
        --         -- isfullhelm = true,   --- 暂时不知道是做什么的
        --         override_follow_symbol = "", -- 覆盖 follow_symbol
        --         override_framebegin = 0,
        --         override_frameend = 0,
        --     --------------------------------------------------------------------------
        -- }

        --------------------------------------------------------------------------------------------------
        --- 参数解析
            local bank = cmd_data.bank
            local build = cmd_data.build
            local anims = {
                [1] = cmd_data.anim_down,
                [2] = cmd_data.anim_side,
                [3] = cmd_data.anim_up,
            }
            local loop = cmd_data.loop
            local isfullhelm = cmd_data.isfullhelm
            local override_follow_symbol = cmd_data.override_follow_symbol
            local override_framebegin = cmd_data.override_framebegin
            local override_frameend = cmd_data.override_frameend
        --------------------------------------------------------------------------------------------------
        --- create_fn
            local create_fn = function(i)
                local inst = CreateEntity()
                --[[Non-networked entity]]
                inst.entity:AddTransform()
                inst.entity:AddAnimState()
                inst.entity:AddFollower()

                inst:AddTag("FX")
                inst:AddTag("fx")
                inst:AddTag("NOBLOCK")
                -- inst.AnimState:SetBank("tbat_eq_ray_fish_hat")
                -- inst.AnimState:SetBuild("tbat_eq_ray_fish_hat")
                -- --- i 为  framebegin -> frameend ，其中正面是 1 ，侧面是2，背面是3
                -- inst.AnimState:PlayAnimation("hat"..i, true)

                inst.AnimState:SetBank(bank)
                inst.AnimState:SetBuild(build)
                local anim = anims[i]
                if anim then
                    inst.AnimState:PlayAnimation(anim,loop)
                end
                inst:AddComponent("highlightchild")

                inst.persists = false
                return inst
            end
        --------------------------------------------------------------------------------------------------
        ---
            local function FollowFx_OnRemoveEntity(inst)
                for i, v in ipairs(inst.fx) do
                    v:Remove()
                end
            end

            local function FollowFx_ColourChanged(inst, r, g, b, a)
                for i, v in ipairs(inst.fx) do
                    v.AnimState:SetAddColour(r, g, b, a)
                end
            end

            local function SpawnFollowFxForOwner(inst, owner)
                local follow_symbol = override_follow_symbol or isfullhelm and owner.isplayer and owner.AnimState:BuildHasSymbol("headbase_hat") and "headbase_hat" or "swap_hat"
                inst.fx = {}
                local frame
                local framebegin = override_framebegin or 1
                local frameend = override_frameend or 3
                for i = framebegin, frameend do
                    local fx = create_fn(i)
                    ------------------------------------------------------------------------------
                    --- 随机某一帧进行动画播放
                        local total_anim_frames = fx.AnimState:GetCurrentAnimationNumFrames()
                        if type(total_anim_frames) == "number" and total_anim_frames > 0 then
                            frame = frame or math.random(total_anim_frames) - 1
                            fx.AnimState:SetFrame(frame)
                        end
                    ------------------------------------------------------------------------------
                    fx.entity:SetParent(owner.entity)
                    fx.Follower:FollowSymbol(owner.GUID, follow_symbol, nil, nil, nil, true, nil, i - 1) 
                            --- 往指定png序号套inst实体
                            --- 动画拆包后， XX-0.png 为序号 1，这里由于引擎是C语言的关系，是从0开始的，所以需要偏移 -1
                    fx.components.highlightchild:SetOwner(owner)
                    ------------------------------------------------------------------------------
                    --- 子特效件 可能的联动函数
                        if cmd_data.child_fn then
                            cmd_data.child_fn(fx,inst,i)
                        end
                    ------------------------------------------------------------------------------
                    table.insert(inst.fx, fx)
                end
                inst.components.colouraddersync:SetColourChangedFn(FollowFx_ColourChanged)
                inst.OnRemoveEntity = FollowFx_OnRemoveEntity
            end
        --------------------------------------------------------------------------------------------------
        ---
            local function OnEntityReplicated(inst)
                local owner = inst.entity:GetParent()
                if owner ~= nil then
                    SpawnFollowFxForOwner(inst, owner)
                end
            end
        --------------------------------------------------------------------------------------------------
        --- 绑定给玩家使用
            local function AttachToOwner(inst, owner)
                inst.entity:SetParent(owner.entity)
                if owner.components.colouradder ~= nil then
                    owner.components.colouradder:AttachChild(inst)
                end
                if inst.owningitem and inst.skinbuildhash then
                    local skinbuild = inst.owningitem.AnimState:GetSkinBuild()
                    if skinbuild then
                        inst.skinbuildhash:set(skinbuild)
                    end
                end
                --Dedicated server does not need to spawn the local fx
                if not TheNet:IsDedicated() then            
                    SpawnFollowFxForOwner(inst, owner)
                end
            end
        --------------------------------------------------------------------------------------------------
        --- main fx fn
            local function fn()
                local inst = CreateEntity()
                inst.entity:AddTransform()
                inst.entity:AddNetwork()
                inst:AddTag("FX")
                inst:AddTag("fx")
                inst:AddTag("NOBLOCK")
                inst:AddComponent("colouraddersync")
                if cmd_data.common_postinit ~= nil then
                    cmd_data.common_postinit(inst)
                end
                inst.entity:SetPristine()
                if not TheWorld.ismastersim then
                    inst.OnEntityReplicated = OnEntityReplicated
                    return inst
                end
                inst.AttachToOwner = AttachToOwner
                inst.persists = false
                if cmd_data.master_postinit ~= nil then
                    cmd_data.master_postinit(inst)
                end
                return inst
            end
        --------------------------------------------------------------------------------------------------
        --- 返回
            return Prefab(prefab, fn, assets)
        --------------------------------------------------------------------------------------------------
    end
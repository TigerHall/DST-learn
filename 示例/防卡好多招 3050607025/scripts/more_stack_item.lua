local TheNet = GLOBAL.TheNet
local TheSim = GLOBAL.TheSim
local ThePlayer = GLOBAL.ThePlayer
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

local function newStackable(self)
    local _Put = self.Put
    self.Put = function(self, item, source_pos)
        if item.prefab == self.inst.prefab then
            local newtotal = item.components.stackable:StackSize() + self.inst.components.stackable:StackSize()
        end
        return _Put(self, item, source_pos)
    end
end

--遍历需要叠加的动物
local function AddAnimalStackables(value)
	if IsServer == false then
		return
	end
	for k,v in ipairs(value) do
		AddPrefabPostInit(v,function(inst)
			if(inst.components.stackable == nil) then
				inst:AddComponent("stackable")
			end
			if inst.components.follower then
				local old_stack_get = inst.components.stackable.Get
				function inst.components.stackable:Get(num)
					local stack_get = old_stack_get(self, num)
					if inst.components.follower then
						stack_get.components.follower:SetLeader(inst.components.follower.leader)
					end
					return stack_get
				end
			end
			if inst.components.inventoryitem then
				inst.components.inventoryitem:SetOnDroppedFn(function(inst)
					-- if(inst.components.perishable ~= nil) then
						-- inst.components.perishable:StopPerishing()
					-- end
					if(inst.sg ~= nil) then
						inst.sg:GoToState("stunned")
					end
					local leader = nil
					if inst.components.follower then
						leader = inst.components.follower.leader
					end
					if inst.components.stackable then
						while inst.components.stackable:StackSize() > 1 do
							local item = inst.components.stackable:Get()
							if item then
								if item.components.inventoryitem then
									if item.components.follower and leader then
										item.components.follower:SetLeader(leader)
									end
									item.components.inventoryitem:OnDropped()
								end
								item.Physics:Teleport(inst.Transform:GetWorldPosition())
							end
						end
					 end
				end)
			end
		end)
	end
end

--遍历需要叠加的物品
local function AddItemStackables(value)
	if IsServer == false then
		return
	end
	for k,v in ipairs(value) do
		AddPrefabPostInit(v,function(inst)
			if  inst.components.sanity ~= nil  then
				return
			end
			if  inst.components.inventoryitem == nil  then
				return
			end
			if(inst.components.stackable == nil) then
				inst:AddComponent("stackable")
			end
		end)
	end
end

	--AddComponentPostInit("stackable", newStackable)
	
	--小兔子
	AddAnimalStackables({"rabbit",})
	--鼹鼠
	AddAnimalStackables({"mole","carrat"})
	--鸟类
	AddAnimalStackables({"robin","robin_winter","crow","puffin","canary","canary_poisoned","bird_mutant","bird_mutant_spitter",})
	--鱼类
	local STACKABLE_OBJECTS_BASE = {"pondfish","pondeel","oceanfish_medium_1_inv","oceanfish_medium_2_inv","oceanfish_medium_3_inv","oceanfish_medium_4_inv","oceanfish_medium_5_inv","oceanfish_medium_6_inv","oceanfish_medium_7_inv","oceanfish_medium_8_inv","oceanfish_small_1_inv","oceanfish_small_2_inv","oceanfish_small_3_inv","oceanfish_small_4_inv","oceanfish_small_5_inv","oceanfish_small_6_inv","oceanfish_small_7_inv","oceanfish_small_8_inv","oceanfish_small_9_inv","wobster_sheller_land","wobster_moonglass_land","oceanfish_medium_9_inv"}
	AddAnimalStackables(STACKABLE_OBJECTS_BASE)

	--眼球炮塔
	AddItemStackables({"eyeturret_item"})
	
	if GetModConfigData("STACK_OTHER_OBJECTS") == "A" then
		--高脚鸟蛋相关
		AddAnimalStackables({"tallbirdegg_cracked","tallbirdegg"})
		--岩浆虫卵相关
		AddAnimalStackables({"lavae_egg","lavae_egg_cracked","lavae_tooth","lavae_cocoon"})
	end
	
	--暗影心房
	AddItemStackables({"shadowheart","shadowheart_infused"})
	--犀牛角
	AddItemStackables({"minotaurhorn"})
	--格罗姆翅膀
	AddItemStackables({"glommerwings"})
	--月岩雕像
	AddItemStackables({"moonrockidol"})
	--蜘蛛类
	AddAnimalStackables({"spider","spider_healer","spider_hider","spider_moon","spider_spitter","spider_warrior","spider_dropper","spider_water",})
	--超级打包盒
	AddItemStackables({"miao_packbox"})
	--荷叶（神话）
	AddItemStackables({"myth_lotusleaf","myth_mooncake_ice","myth_mooncake_lotus","myth_mooncake_nuts",})

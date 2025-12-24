-- 不留树根的树集合
local NO_STUMP_TREES = 
{
	-- 常青树
	"evergreen",
	"evergreen_normal",
	"evergreen_tall",
	"evergreen_short",
	
	-- 无果常青树
	"evergreen_sparse",
	"evergreen_sparse_normal",
	"evergreen_sparse_tall",
	"evergreen_short",
	
	-- 多枝树
	"twiggytree",
	"twiggy_normal",
	"twiggy_tall",
	"twiggy_short",
	"twiggy_old",
	
	-- 桦树
	"deciduoustree",
	"deciduoustree_normal",
	"deciduoustree_tall",
	"deciduoustree_short",
	
	-- 月数
	"moon_tree",
	"moon_tree_short",
	"moon_tree_normal",
	"moon_tree_tall",
	
	-- 尖刺灌木
	"marsh_tree",
	
	-- 磨菇树
	"mushtree_tall",
	"mushtree_medium",
	"mushtree_small",
	
	-- 月亮磨菇树
	"mushtree_moon",
	
	-- 棕榈树
	"palmconetree",
}

for i,v in ipairs(NO_STUMP_TREES) do
	AddPrefabPostInit(v, function(inst)
		if inst.components.workable then
			-- 重写树木chop_down_tree方法
			local old_chop_down_tree = inst.components.workable.onfinish
			local function chop_down_tree(inst, chopper) 
				old_chop_down_tree(inst,chopper)
				-- 掉落一个木头
				if inst.components.lootdropper then
					inst.components.lootdropper:SpawnLootPrefab("log")
				end
				-- -- ①树根1-2秒内自动消失
				-- if inst.components.timer ~= nil and inst.components.timer:TimerExists("decay") then
					-- inst.components.timer:SetTimeLeft("decay", GetRandomWithVariance(2, 1))
					-- inst.components.timer:ResumeTimer("decay")
				-- end
				-- ②砍到后立即移除
				inst:AddTag("NOCLICK")
				inst:DoTaskInTime(4, inst.Remove)
				--inst:ListenForEvent("animover", inst.Remove)
			end
			inst.components.workable:SetOnFinishCallback(chop_down_tree)
		end
	end)
end
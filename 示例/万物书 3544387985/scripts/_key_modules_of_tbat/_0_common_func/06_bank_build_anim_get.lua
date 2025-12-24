



local function get(target)
        -----------------------------------------------------------------------------------------------------
        --- debug 文本
            local debugstring = target.entity:GetDebugString()
        -----------------------------------------------------------------------------------------------------
        --- 这段逻辑大部分来自【小穹MOD】，自己修改了一部分
            local bank,build,anim = nil,nil,nil
            if target.AnimState then

                bank, build, anim = debugstring:match("bank: (.+) build: (.+) anim: .+:(.+) Frame")
                if (not bank) or (bank:find("FROMNUM")) and target.AnimState.GetBank then
                    -- bank = target.prefab -- 抢救一下吧
                    bank = target.AnimState:GetBank()
                end
                if (not build) or (build:find("FROMNUM")) then
                    -- build = target.prefab -- 抢救一下吧
                    build = target.AnimState:GetBuild()
                end

                if target.skinname and not Prefabs[target.prefab .. "_placer"] then
                    local temp_inst = SpawnPrefab(target.prefab)
                    debugstring = temp_inst.entity:GetDebugString()
                    bank, build, anim = debugstring:match("bank: (.+) build: (.+) anim: .+:(.+) Frame")
                    temp_inst:Remove()
                end
            end
        -------------------------------------------------------------------------------------
            -- print(bank,build,anim)
            return bank,build,anim
        -----------------------------------------------------------------------------------------------------
end

function TBAT.FNS:GetBankBuildAnim(target)
    return get(target)
end
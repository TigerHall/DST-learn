local Jx_Bath = Class(function(self, inst) 
    self.inst = inst
    self.current_player = nil
end)

function Jx_Bath:StartBath(player)
    if player == nil or not player:IsValid() then 
      return
    end
    
    self.inst:AddTag("hasplayer")
    self.current_player = player
    player.bath_task = player:DoPeriodicTask(1,function()
      if player.components.health then
        player.components.health:DoDelta(5, true)
      end
      if player.components.sanity then
        player.components.sanity:DoDelta(5, true)
      end
      if player.components.temperature then
        local tem = player.components.temperature:GetCurrent()
        if tem < 54 then
          player.components.temperature:SetTemperature(tem + 1)
        elseif tem > 56 then
          player.components.temperature:SetTemperature(tem - 1)
        end
      end
    end)
end

function Jx_Bath:StopBath(player)
    if player == nil or not player:IsValid() then 
      return
    end
    self.inst:RemoveTag("hasplayer")
    self.current_player = nil
    if player.bath_task then
      player.bath_task:Cancel()
      player.bath_task = nil
    end
end

function Jx_Bath:OnPlayerDespawn()
    self.inst:RemoveTag("hasplayer")
    self.current_player = nil
    self.inst:PushEvent("onstopbath")
end

return Jx_Bath
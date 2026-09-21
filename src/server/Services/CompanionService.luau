local Shared=game:GetService("ReplicatedStorage").Shared
local Characters=require(Shared.CharacterDatabase)
local Rarities=require(Shared.RarityConfig)
local Rules=require(Shared.Rules)
local Config=require(Shared.GameConfig)
local Factory=require(script.Parent.ModelFactory)
local Service={Entries={}}
function Service:Remove(player)
    local e=self.Entries[player]
    if e then e.Model:Destroy(); self.Entries[player]=nil end
end
function Service:Spawn(player,id)
    local cfg=Characters[id]
    if not cfg then return end
    local previous=self.Entries[player]
    local nextAttack=previous and previous.NextAttack or os.clock()+1
    local hits=previous and previous.Hits or 0
    self:Remove(player)
    local rarity=Rarities[cfg.Rarity]
    local model=Factory.Humanoid(cfg.Name,Factory.Color(cfg.Color),Factory.Color(cfg.Hair),cfg.Weapon,rarity.Rank,0.9)
    model.Name=player.Name.."_Companion"; model:SetAttribute("OwnerUserId",player.UserId)
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    model:PivotTo(root and root.CFrame*CFrame.new(4,0,3) or CFrame.new(0,4,85))
    model.Parent=workspace.AnimeRNGWorld
    self.Entries[player]={Model=model,Id=id,NextAttack=nextAttack,Hits=hits,HitUntil=0}
end
function Service:Tick(player,data,monsters,effects)
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then self:Remove(player); return end
    local e=self.Entries[player]
    if not e or e.Id~=data.Equipped then self:Spawn(player,data.Equipped); e=self.Entries[player] end
    if not e then return end
    local target=player:GetAttribute("AutoCombat")~=false and monsters:Nearest(player,Config.CombatRange) or nil
    local goal=root.CFrame*CFrame.new(4,0,4)
    if target then
        local targetPos=target.Model.PrimaryPart.Position
        local away=Vector3.new(root.Position.X-targetPos.X,0,root.Position.Z-targetPos.Z)
        if away.Magnitude<0.1 then away=Vector3.new(1,0,0) end
        local position=Vector3.new(targetPos.X,root.Position.Y-0.3,targetPos.Z)+away.Unit*(4+target.Config.Scale)
        goal=CFrame.lookAt(position,Vector3.new(targetPos.X,position.Y,targetPos.Z))
    end
    local current=e.Model:GetPivot()
    local distance=(current.Position-goal.Position).Magnitude
    e.Model:PivotTo(distance>65 and goal or current:Lerp(goal,0.36))
    local now=os.clock()
    if target and now>=e.NextAttack and (e.Model.PrimaryPart.Position-target.Model.PrimaryPart.Position).Magnitude<11+target.Config.Scale then
        e.NextAttack=now+Config.AttackInterval; e.Hits=e.Hits+1; e.HitUntil=now+0.45
        local cfg=Characters[e.Id]
        local amount=Rules.damage(cfg,Rarities[cfg.Rarity],data.UnitXP[e.Id])
        local skill=e.Hits%5==0
        if skill then amount=math.floor(amount*1.75) end
        effects:FireAllClients({Kind=skill and "Skill" or "Hit",From=e.Model.PrimaryPart.Position,Position=target.Model.PrimaryPart.Position,Amount=amount,Color=Rarities[cfg.Rarity].Color})
        monsters:Hit(target,amount,player)
    end
    local label=e.Model.PrimaryPart:FindFirstChild("Nameplate")
    if label then label.Text.Text=Characters[e.Id].Name.." ["..Characters[e.Id].Rarity.."]\nLevel "..Rules.level(data.UnitXP[e.Id]) end
    Factory.Animate(e.Model,now,distance>0.4,now<e.HitUntil)
end
return Service

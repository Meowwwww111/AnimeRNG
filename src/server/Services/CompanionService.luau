local Shared=game:GetService("ReplicatedStorage").Shared
local Characters=require(Shared.CharacterDatabase)
local Rarities=require(Shared.RarityConfig)
local Rules=require(Shared.Rules)
local Config=require(Shared.GameConfig)
local Math=require(Shared.PresentationMath)
local Factory=require(script.Parent.ModelFactory)
local Service={Entries={}}
function Service:Remove(player)
    local e=self.Entries[player]
    if e then e.Model:Destroy(); self.Entries[player]=nil end
end
function Service:Spawn(player,id)
    local cfg=Characters[id]; if not cfg then return end
    local old=self.Entries[player]
    local nextAttack=old and old.NextAttack or os.clock()+1
    local hits=old and old.Hits or 0
    self:Remove(player)
    local model=Factory.Actor("Unit",id,cfg,player:GetAttribute("World") or 1)
    model.Name=player.Name.."_Companion"; model:SetAttribute("OwnerUserId",player.UserId)
    model:SetAttribute("DisplayName",cfg.Name); model:SetAttribute("Rarity",cfg.Rarity)
    model:SetAttribute("Follow",true)
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local cf=root and root.CFrame*CFrame.new(3.4,0,3.6) or CFrame.new(0,4,85)
    Factory.Publish(model,cf,false,0)
    model.Parent=workspace.AnimeRNGWorld; Factory.Register(model)
    self.Entries[player]={Model=model,Id=id,NextAttack=nextAttack,Hits=hits,HitUntil=0,LastTick=os.clock()}
end
function Service:Tick(player,data,monsters,effects)
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then self:Remove(player); return end
    local e=self.Entries[player]
    if not e or e.Id~=data.Equipped then self:Spawn(player,data.Equipped); e=self.Entries[player] end
    if not e then return end
    local now=os.clock(); local dt=math.min(0.5,math.max(0,now-e.LastTick)); e.LastTick=now
    local target=player:GetAttribute("AutoCombat")~=false and monsters:Nearest(player,Config.CombatRange) or nil
    local desired=root.CFrame*CFrame.new(3.4,0,3.6)
    local floor=0.3
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances={workspace.AnimeRNGWorld}
    local hit=workspace:Raycast(desired.Position+Vector3.new(0,5,0),Vector3.new(0,-35,0),params)
    if hit then floor=hit.Position.Y end
    local pos=Vector3.new(desired.Position.X,floor+e.Model:GetAttribute("Height"),desired.Position.Z)
    local goal=CFrame.new(pos)*desired.Rotation
    if target then
        local tp=target.Model.PrimaryPart.Position
        local away=Vector3.new(root.Position.X-tp.X,0,root.Position.Z-tp.Z)
        if away.Magnitude<0.1 then away=Vector3.new(1,0,0) end
        pos=Vector3.new(tp.X,0.4+e.Model:GetAttribute("Height"),tp.Z)+away.Unit*(4+target.Config.Scale)
        goal=CFrame.lookAt(pos,Vector3.new(tp.X,pos.Y,tp.Z))
    end
    e.Model:SetAttribute("World",player:GetAttribute("World") or 1)
    e.Model:SetAttribute("Follow",target==nil)
    local current=e.Model:GetPivot(); local distance=(current.Position-goal.Position).Magnitude
    local cf=distance>70 and goal or current:Lerp(goal,Math.alpha(6.5,dt))
    -- Pose is cosmetic on clients; attack timing, damage and range remain server-owned.
    if target and now>=e.NextAttack and (cf.Position-target.Model.PrimaryPart.Position).Magnitude<12+target.Config.Scale*2 then
        e.NextAttack=now+Config.AttackInterval; e.Hits=e.Hits+1
        e.HitUntil=workspace:GetServerTimeNow()+0.42
        local cfg=Characters[e.Id]
        local amount=Rules.damage(cfg,Rarities[cfg.Rarity],data.UnitXP[e.Id])
        local skill=e.Hits%5==0
        if skill then amount=math.floor(amount*1.75) end
        effects:FireAllClients({Kind=skill and "Skill" or "Hit",From=cf.Position,
            Position=target.Model.PrimaryPart.Position,Amount=amount,Color=Rarities[cfg.Rarity].Color})
        monsters:Hit(target,amount,player)
    end
    e.Model:SetAttribute("Level",Rules.level(data.UnitXP[e.Id]))
    Factory.Publish(e.Model,cf,distance>0.35,e.HitUntil)
end
return Service

local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").Shared
local Monsters=require(Shared.MonsterDatabase)
local Factory=require(script.Parent.ModelFactory)
local Service={Live={}}
local function living(player)
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if root and hum and hum.Health>0 then return root,hum end
    return nil,nil
end
function Service:Init(world,onKill,effects)
    self.World=world; self.OnKill=onKill; self.Effects=effects; self.Live={}
    for _,marker in ipairs(world.Markers) do self:Spawn(marker) end
end
function Service:Spawn(marker)
    if not self.World.Root.Parent then return end
    local cfg=Monsters[marker.Id]
    local model=Factory.Monster(marker.Key,cfg,marker.World)
    local hp=cfg.HP*(marker.World==2 and 5 or 1)
    model:SetAttribute("MonsterId",marker.Id); model:SetAttribute("World",marker.World)
    model:SetAttribute("HP",hp); model:SetAttribute("MaxHP",hp)
    local home=marker.Position+Vector3.new(0,model:GetAttribute("Height"),0)
    model:PivotTo(CFrame.new(home)); model.Parent=self.World.Root
    local s={Model=model,Marker=marker,Config=cfg,HP=hp,MaxHP=hp,Home=home,Alive=true,Contributors={},NextHit=0,NextSlam=os.clock()+8,HitUntil=0}
    self.Live[marker.Key]=s
    self:UpdateLabel(s)
end
function Service:UpdateLabel(s)
    local gui=s.Model.PrimaryPart:FindFirstChild("Nameplate")
    if gui then gui.Text.Text=string.format("%s  [World %d]\n%d / %d HP",s.Config.Name,s.Marker.World,math.ceil(s.HP),s.MaxHP) end
end
function Service:Nearest(player,range)
    local root=living(player)
    if not root then return nil end
    local best,distance=nil,range
    for _,s in pairs(self.Live) do
        if s.Alive and s.Marker.World==(player:GetAttribute("World") or 1) then
            local delta=(s.Model.PrimaryPart.Position-root.Position).Magnitude
            if delta<distance then best=s; distance=delta end
        end
    end
    return best
end
function Service:Hit(s,amount,player)
    if not s or not s.Alive or not s.Model.Parent then return false end
    local applied=math.min(s.HP,amount)
    if applied<=0 then return false end
    s.HP=s.HP-applied
    local contribution=s.Contributors[player] or {Amount=0,Time=0}
    contribution.Amount=contribution.Amount+applied; contribution.Time=os.clock()
    s.Contributors[player]=contribution
    s.Model:SetAttribute("HP",s.HP); self:UpdateLabel(s)
    if s.HP>0 then return false end
    -- Mark dead BEFORE events/rewards/respawn. Repeated calls cannot pay twice.
    s.Alive=false
    self.Effects:FireAllClients({Kind="Death",Position=s.Model.PrimaryPart.Position,Color=s.Config.Color})
    self.OnKill(s,player)
    s.Model:Destroy()
    task.delay(s.Marker.Id=="WorldBoss" and 25 or 7,function()
        if self.Live[s.Marker.Key]==s then self:Spawn(s.Marker) end
    end)
    return true
end
function Service:Tick(dt)
    local now=os.clock()
    for _,s in pairs(self.Live) do
        if s.Alive and s.Model.Parent then
            local pos=s.Model.PrimaryPart.Position
            local target,hum,closest=nil,nil,32
            for _,player in ipairs(Players:GetPlayers()) do
                local hrp,h=living(player)
                if hrp and player:GetAttribute("World")==s.Marker.World and (hrp.Position-s.Home).Magnitude<55 then
                    local distance=(hrp.Position-pos).Magnitude
                    if distance<closest then closest=distance; target=hrp; hum=h end
                end
            end
            local goal=target and Vector3.new(target.Position.X,s.Home.Y,target.Position.Z) or s.Home
            if (pos-s.Home).Magnitude>35 then goal=s.Home; target=nil end
            local delta=goal-pos
            local moving=delta.Magnitude>(target and 5+s.Config.Scale or 0.5)
            if moving then
                local step=delta.Unit*math.min(delta.Magnitude,s.Config.Speed*dt)
                local dest=pos+step
                s.Model:PivotTo(CFrame.lookAt(dest,dest+delta.Unit))
            end
            if target and closest<6+s.Config.Scale and now>=s.NextHit then
                s.NextHit=now+1.8; s.HitUntil=now+0.4
                local damage=s.Config.Damage*(s.Marker.World==2 and 1.6 or 1)
                hum:TakeDamage(damage)
                self.Effects:FireAllClients({Kind="Hit",Position=target.Position,From=pos,Amount=damage,Color={255,110,110}})
            end
            if target and s.Marker.Id=="WorldBoss" and now>s.NextSlam then
                s.NextSlam=now+9
                local center=Vector3.new(pos.X,0.8,pos.Z)
                self.Effects:FireAllClients({Kind="Slam",Position=center,Radius=17,Duration=1.4,Color={231,86,127}})
                task.delay(1.4,function()
                    if not s.Alive then return end
                    for _,player in ipairs(Players:GetPlayers()) do
                        local hrp,h=living(player)
                        if hrp and player:GetAttribute("World")==s.Marker.World then
                            local flat=Vector3.new(hrp.Position.X,center.Y,hrp.Position.Z)
                            if (flat-center).Magnitude<17 then h:TakeDamage(s.Config.Damage*1.5*(s.Marker.World==2 and 1.6 or 1)) end
                        end
                    end
                end)
            end
            Factory.Animate(s.Model,now,moving,now<s.HitUntil)
        end
    end
end
return Service

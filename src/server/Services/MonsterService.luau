local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").Shared
local Monsters=require(Shared.MonsterDatabase)
local Worlds=require(Shared.WorldConfig)
local Math=require(Shared.PresentationMath)
local Factory=require(script.Parent.ModelFactory)
local Service={Live={}}
local function living(player)
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if root and hum and hum.Health>0 then return root,hum end
    return nil,nil
end
local function flat(a,b) return Vector3.new(a.X-b.X,0,a.Z-b.Z).Magnitude end
function Service:Init(world,onKill,effects)
    self.World=world; self.OnKill=onKill; self.Effects=effects; self.Live={}
    for _,marker in ipairs(world.Markers) do self:Spawn(marker) end
end
function Service:Spawn(marker)
    if not self.World.Root.Parent then return end
    local original=Monsters[marker.Id]; local cfg={}
    for k,v in pairs(original) do cfg[k]=v end
    cfg.Name=Worlds[marker.World].EnemyNames[marker.Id]
    local model=Factory.Actor("Monster",marker.Id,cfg,marker.World); model.Name=marker.Key
    local hp=cfg.HP*(marker.World==2 and 5 or 1)
    model:SetAttribute("MonsterId",marker.Id); model:SetAttribute("HP",hp); model:SetAttribute("MaxHP",hp)
    model:SetAttribute("DisplayName",cfg.Name)
    local home=marker.Position+Vector3.new(0,model:GetAttribute("Height"),0)
    Factory.Publish(model,CFrame.new(home),false,0)
    model.Parent=self.World.Root; Factory.Register(model)
    self.Live[marker.Key]={Model=model,Marker=marker,Config=cfg,HP=hp,MaxHP=hp,Home=home,Alive=true,
        Contributors={},NextHit=0,NextSlam=os.clock()+8,HitUntil=0,Returning=false}
end
function Service:Nearest(player,range)
    local root=living(player)
    if not root or not self.World:Enforce(player) then return nil end
    local best,distance=nil,range
    for _,s in pairs(self.Live) do
        if s.Alive and s.Marker.World==self.World:WorldFor(player) and math.abs(root.Position.Y-s.Marker.Position.Y)<14 then
            local delta=flat(s.Model.PrimaryPart.Position,root.Position)
            if delta<distance then best=s; distance=delta end
        end
    end
    return best
end
function Service:Hit(s,amount,player)
    if not s or not s.Alive or not s.Model.Parent or not Math.finite(amount) or amount<=0 then return false end
    local root=living(player)
    if not root or self.World:WorldFor(player)~=s.Marker.World or not self.World:Enforce(player)
        or flat(root.Position,s.Model.PrimaryPart.Position)>34 then return false end
    local applied=math.min(s.HP,amount); s.HP=s.HP-applied
    local c=s.Contributors[player] or {Amount=0,Time=0}
    c.Amount=c.Amount+applied; c.Time=os.clock(); s.Contributors[player]=c
    s.Model:SetAttribute("HP",s.HP)
    if s.HP>0 then return false end
    s.Alive=false
    self.Effects:FireAllClients({Kind="Death",Position=s.Model.PrimaryPart.Position,Color=s.Config.Color})
    self.OnKill(s,player); s.Model:Destroy()
    task.delay(s.Marker.Id=="WorldBoss" and 25 or 7,function()
        if self.Live[s.Marker.Key]==s then self:Spawn(s.Marker) end
    end)
    return true
end
function Service:Tick(dt)
    local now=os.clock(); local players=Players:GetPlayers()
    for _,p in ipairs(players) do self.World:Enforce(p) end
    for _,s in pairs(self.Live) do
        if s.Alive and s.Model.Parent then
            local cf=s.Model:GetPivot(); local pos=cf.Position
            if flat(pos,s.Home)>35 then s.Returning=true end
            if s.Returning and flat(pos,s.Home)<1 then s.Returning=false end
            local target,hum,closest=nil,nil,32
            if not s.Returning then
                for _,player in ipairs(players) do
                    local hrp,h=living(player)
                    if hrp and self.World:WorldFor(player)==s.Marker.World and flat(hrp.Position,s.Home)<53
                        and math.abs(hrp.Position.Y-s.Marker.Position.Y)<14 then
                        local d=flat(hrp.Position,pos)
                        if d<closest then closest=d; target=hrp; hum=h end
                    end
                end
            end
            local goal=target and Vector3.new(target.Position.X,s.Home.Y,target.Position.Z) or s.Home
            local delta=goal-pos
            local moving=delta.Magnitude>(target and 4+s.Config.Scale or 0.35)
            if moving then
                local dest=pos+delta.Unit*math.min(delta.Magnitude,s.Config.Speed*dt)
                cf=CFrame.lookAt(dest,dest+delta.Unit)
            elseif target and delta.Magnitude>0.01 then cf=CFrame.lookAt(pos,goal) end
            if target and closest<6+s.Config.Scale and now>=s.NextHit then
                s.NextHit=now+1.8; s.HitUntil=workspace:GetServerTimeNow()+0.4
                local damage=s.Config.Damage*(s.Marker.World==2 and 1.6 or 1)
                hum:TakeDamage(damage)
                self.Effects:FireAllClients({Kind="Hit",Position=target.Position,From=pos,Amount=damage,Color={255,110,110}})
            end
            if target and s.Marker.Id=="WorldBoss" and now>s.NextSlam then
                s.NextSlam=now+9
                local center=Vector3.new(pos.X,s.Marker.Position.Y+0.8,pos.Z)
                self.Effects:FireAllClients({Kind="Slam",Position=center,Radius=17,Duration=1.4,Color={231,86,127}})
                task.delay(1.4,function()
                    if not s.Alive then return end
                    for _,p in ipairs(Players:GetPlayers()) do
                        local hrp,h=living(p)
                        if hrp and self.World:WorldFor(p)==s.Marker.World and self.World:Enforce(p)
                            and flat(hrp.Position,center)<17 and math.abs(hrp.Position.Y-center.Y)<12 then
                            h:TakeDamage(s.Config.Damage*1.5*(s.Marker.World==2 and 1.6 or 1))
                        end
                    end
                end)
            end
            Factory.Publish(s.Model,cf,moving,s.HitUntil)
        end
    end
end
return Service

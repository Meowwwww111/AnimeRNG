local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Factory=require(script.Parent.ModelFactory)
local Data=require(script.Parent.DataService)
local Zones=require(RS.Shared.WorldConfig)
local Math=require(RS.Shared.PresentationMath)
local World={Stations={},Spawns={},Markers={},Assigned={}}
local function part(parent,name,size,pos,tint,material,solid)
    local p=Factory.Part(parent,name,size,CFrame.new(pos),tint,material)
    p.CanCollide=solid~=false; p.CanQuery=solid~=false
    return p
end
function World:Allowed(player,zone)
    local d=Data:Get(player)
    return Math.canEnter(d and d.UnlockedWorld or 1,zone,Zones)
end
function World:WorldFor(player) return self.Assigned[player] or 1 end
function World:Near(player,root,range)
    local char=player.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local zone=self:WorldFor(player)
    return hrp and hum and hum.Health>0 and root and root:GetAttribute("World")==zone
        and self:Allowed(player,zone) and Math.inside(Zones[zone],hrp.Position)
        and (hrp.Position-root.Position).Magnitude<=(range or 15)
end
local function prompt(root,label,callback)
    local p=Instance.new("ProximityPrompt")
    p.ActionText=label; p.ObjectText=root.Name; p.MaxActivationDistance=12
    p.HoldDuration=0.2; p.RequiresLineOfSight=false; p.KeyboardKeyCode=Enum.KeyCode.E
    p.Parent=root; p.Triggered:Connect(callback)
end
function World:Build(interact)
    local old=workspace:FindFirstChild("AnimeRNGWorld")
    if old then old:Destroy() end
    self.Stations={}; self.Spawns={}; self.Markers={}; self.Assigned={}
    local root=Instance.new("Folder"); root.Name="AnimeRNGWorld"; root.Parent=workspace; self.Root=root
    for zone=1,2 do
        local cfg=Zones[zone]; local o=Vector3.new(cfg.Origin.X,cfg.Origin.Y,cfg.Origin.Z)
        local folder=Instance.new("Folder"); folder.Name="World"..zone; folder.Parent=root
        folder:SetAttribute("World",zone)
        local village=zone==1
        local stone=village and Color3.fromRGB(161,153,139) or Color3.fromRGB(43,42,60)
        local accent=village and Color3.fromRGB(255,189,118) or Color3.fromRGB(150,108,255)
        local wood=Color3.fromRGB(104,62,46)
        part(folder,"Island",Vector3.new(300,8,360),o+Vector3.new(0,-4,-35),village and Color3.fromRGB(87,140,106) or stone,village and Enum.Material.Grass or Enum.Material.Basalt)
        part(folder,"ArrivalPlaza",Vector3.new(146,0.5,87),o+Vector3.new(0,0.2,67),stone,village and Enum.Material.Cobblestone or Enum.Material.Slate)
        part(folder,"CombatCauseway",Vector3.new(village and 12 or 22,0.35,193),o+Vector3.new(0,0.15,-68),stone,village and Enum.Material.Cobblestone or Enum.Material.Marble)
        local spawn=Instance.new("SpawnLocation")
        spawn.Name="World"..zone.."Spawn"; spawn.Size=Vector3.new(8,0.6,8)
        spawn.CFrame=CFrame.new(o+Vector3.new(0,0.8,85)); spawn.Anchored=true
        spawn.Neutral=true; spawn.Enabled=zone==1; spawn.Transparency=1; spawn.Duration=0; spawn.Parent=folder
        self.Spawns[zone]=spawn
        local sign=part(folder,"WorldName",Vector3.new(1,1,1),o+Vector3.new(0,6,100),accent,nil,false)
        sign.Transparency=1; Factory.Label(sign,cfg.Name..(village and "\nShrines, bamboo and woodland monsters" or "\nRuined fortress, rifts and shadow enemies"),0)
        self.Stations[zone]={}
        local specs={{"Summon",-37,69,"Summon / 10 coins"},{"Craft",37,69,"Craft luck upgrades"},
            {"Trade",-62,42,"Open trading"},{"Shop",62,42,"Luck shop"},{"Portal",0,115,village and "World 2 / Boss clear required" or "Return to Starfall Village"}}
        for _,spec in ipairs(specs) do
            local key,x,z,text=spec[1],spec[2],spec[3],spec[4]
            local base=part(folder,key,Vector3.new(13,1.2,13),o+Vector3.new(x,0.7,z),stone,Enum.Material.Slate)
            base:SetAttribute("World",zone)
            local rune=part(folder,key.."Rune",Vector3.new(11,0.1,11),o+Vector3.new(x,1.35,z),accent,Enum.Material.Neon,false); rune.Transparency=0.6
            if key=="Craft" then
                part(folder,"Workbench",Vector3.new(7,1,4),o+Vector3.new(x,3,z),wood,Enum.Material.Wood)
                part(folder,"Anvil",Vector3.new(3,1.5,2),o+Vector3.new(x,4,z),Color3.fromRGB(104,120,144),Enum.Material.Metal)
            else
                for _,side in ipairs({-1,1}) do
                    part(folder,key.."Pillar",Vector3.new(1.2,8,1.2),o+Vector3.new(x+side*5,4.5,z+3),village and wood or stone,village and Enum.Material.Wood or Enum.Material.Basalt)
                end
                part(folder,key.."Lintel",Vector3.new(13,1,1.5),o+Vector3.new(x,8.8,z+3),village and Color3.fromRGB(146,60,49) or accent,village and Enum.Material.Wood or Enum.Material.Neon)
                if village then part(folder,key.."Roof",Vector3.new(15,0.4,2.4),o+Vector3.new(x,9.55,z+3),Color3.fromRGB(56,62,75),Enum.Material.Slate) end
                if key=="Portal" then
                    local field=part(folder,"PortalVeil",Vector3.new(8,6,0.2),o+Vector3.new(x,4.5,z+3),accent,Enum.Material.Neon,false); field.Transparency=0.68
                else
                    local gem=part(folder,key.."Focus",Vector3.new(1.2,2,1.2),o+Vector3.new(x,3.5,z),accent,Enum.Material.Neon,false)
                    gem.CFrame=gem.CFrame*CFrame.Angles(0,math.rad(45),math.rad(25))
                end
            end
            Factory.Label(base,text,6); self.Stations[zone][key]=base
            prompt(base,text,function(p) if World:Near(p,base,15) then interact(p,key,zone) end end)
        end
        local arena=part(folder,village and "ShrineCourtyard" or "ThroneDais",Vector3.new(78,0.65,62),o+Vector3.new(0,0.3,-161),stone,Enum.Material.Slate)
        arena:SetAttribute("World",zone)
        if village then
            -- Japanese-inspired village: tiled houses, torii, bamboo and flowering trees.
            for _,s in ipairs({-1,1}) do
                local x=s*107
                part(folder,"PlasterHouse",Vector3.new(28,13,22),o+Vector3.new(x,6.5,58),Color3.fromRGB(227,217,191),Enum.Material.SmoothPlastic)
                part(folder,"DarkTileEaves",Vector3.new(34,2,27),o+Vector3.new(x,14,58),Color3.fromRGB(49,60,78),Enum.Material.Slate)
                part(folder,"UpperTileRoof",Vector3.new(26,3,21),o+Vector3.new(x,16,58),Color3.fromRGB(60,73,92),Enum.Material.Slate)
                for _,dx in ipairs({-9,0,9}) do
                    part(folder,"TimberBeam",Vector3.new(0.6,13,0.7),o+Vector3.new(x+dx,6.5,46.8),wood,Enum.Material.Wood)
                    part(folder,"PaperWindow",Vector3.new(5,5,0.2),o+Vector3.new(x+dx,8,46.6),Color3.fromRGB(252,215,149),Enum.Material.Glass,false)
                end
                for i=1,14 do
                    local z=-195+i*17
                    part(folder,"Bamboo",Vector3.new(0.85,10+i%3*2,0.85),o+Vector3.new(s*(124+i%3*5),5,z),Color3.fromRGB(56,113,64),Enum.Material.Grass)
                    if i%3==0 then
                        local crown=part(folder,"BlossomCrown",Vector3.new(13,8,12),o+Vector3.new(s*121,12,z),Color3.fromRGB(238,166,183),Enum.Material.Grass,false); crown.Shape=Enum.PartType.Ball
                        part(folder,"BlossomTrunk",Vector3.new(2,10,2),o+Vector3.new(s*121,5,z),wood,Enum.Material.Wood)
                    end
                end
                part(folder,"ShrinePillar",Vector3.new(2,13,2),o+Vector3.new(s*29,6.5,-191),Color3.fromRGB(162,53,45),Enum.Material.Wood)
            end
            part(folder,"ToriiCrossbeam",Vector3.new(65,1.8,3),o+Vector3.new(0,13,-191),Color3.fromRGB(163,61,49),Enum.Material.Wood)
            part(folder,"ToriiCap",Vector3.new(71,1,4),o+Vector3.new(0,14.5,-191),Color3.fromRGB(39,44,59),Enum.Material.Slate)
        else
            -- A different silhouette and layout: ruined towers, broken walls and rifts.
            for _,s in ipairs({-1,1}) do
                for i=1,4 do
                    local z=68-i*62
                    part(folder,"Bastion",Vector3.new(21,28+i*3,21),o+Vector3.new(s*128,14+i*1.5,z),stone,Enum.Material.Basalt)
                    for _,dx in ipairs({-7,0,7}) do
                        part(folder,"Battlement",Vector3.new(4,5,21),o+Vector3.new(s*128+dx,30+i*3,z),stone,Enum.Material.Basalt)
                    end
                    part(folder,"RiftPool",Vector3.new(22,0.08,24),o+Vector3.new(s*91,0.18,z+8),Color3.fromRGB(115,52,172),Enum.Material.Neon,false)
                    local crystal=part(folder,"ObsidianCrystal",Vector3.new(4,12+i,4),o+Vector3.new(s*99,6+i*0.5,z+8),accent,Enum.Material.Neon)
                    crystal.CFrame=crystal.CFrame*CFrame.Angles(0,math.rad(22),math.rad(s*18))
                end
                part(folder,"CitadelBackWall",Vector3.new(28,33,9),o+Vector3.new(s*29,16.5,-195),stone,Enum.Material.Basalt)
                part(folder,"ThroneSpire",Vector3.new(4,47,6),o+Vector3.new(s*40,23.5,-191),accent,Enum.Material.Slate)
            end
            part(folder,"ThroneBack",Vector3.new(15,19,4),o+Vector3.new(0,9.5,-193),Color3.fromRGB(62,44,86),Enum.Material.Marble)
            part(folder,"EclipseSeal",Vector3.new(9,9,0.2),o+Vector3.new(0,23,-194),accent,Enum.Material.Neon,false)
        end
        local spots={{"Slime",-35,5},{"Slime",0,-5},{"Slime",35,5},{"Bandit",-65,-35},{"Bandit",65,-35},
            {"Ogre",-38,-67},{"Ogre",38,-67},{"Demon",-63,-102},{"Titan",43,-105},{"WorldBoss",0,-160}}
        for i,spot in ipairs(spots) do
            local x,z=spot[2],spot[3]
            if not village and i<10 then x=x*0.9; z=z-8 end
            table.insert(self.Markers,{Key="W"..zone.."_"..i,Id=spot[1],World=zone,Position=o+Vector3.new(x,0,z)})
        end
        -- Physics barrier + server bounds. The underlying Baseplate cannot connect worlds.
        for _,spec in ipairs({{Vector3.new(3,140,360),Vector3.new(-150,60,-35)},
            {Vector3.new(3,140,360),Vector3.new(150,60,-35)},
            {Vector3.new(300,140,3),Vector3.new(0,60,-215)},
            {Vector3.new(300,140,3),Vector3.new(0,60,145)}}) do
            local wall=part(folder,"WorldBoundary",spec[1],o+spec[2],stone,nil,true)
            wall.Transparency=1; wall.CanQuery=false
        end
    end
    return root
end
function World:Teleport(player,zone)
    if not self:Allowed(player,zone) then return false end
    local spawn=self.Spawns[zone]; if not spawn then return false end
    self.Assigned[player]=zone; player:SetAttribute("World",zone)
    local char=player.Character
    if char then
        char:PivotTo(spawn.CFrame*CFrame.new(0,4,0))
        local hrp=char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero end
    end
    return true
end
function World:Enforce(player)
    local zone=self:WorldFor(player)
    if not self:Allowed(player,zone) then self:Teleport(player,1); return false end
    local char=player.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if not Math.inside(Zones[zone],hrp.Position) then self:Teleport(player,zone); return false end
    if player:GetAttribute("World")~=zone then player:SetAttribute("World",zone) end
    return true
end
Players.PlayerRemoving:Connect(function(p) World.Assigned[p]=nil end)
return World

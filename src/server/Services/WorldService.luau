local Factory=require(script.Parent.ModelFactory)
local World={Stations={},Spawns={},Markers={}}
local function part(parent,name,size,pos,tint,material,solid)
    local p=Factory.Part(parent,name,size,CFrame.new(pos),tint,material)
    p.CanCollide=solid~=false; p.CanQuery=solid~=false
    return p
end
local function prompt(root,label,callback)
    local p=Instance.new("ProximityPrompt")
    p.ActionText=label; p.ObjectText=root.Name; p.MaxActivationDistance=12
    p.HoldDuration=0.2; p.RequiresLineOfSight=false
    p.KeyboardKeyCode=Enum.KeyCode.E; p.Parent=root
    p.Triggered:Connect(callback)
    return p
end
function World:Near(player,root,range)
    local char=player.Character
    local hrp=char and char:FindFirstChild("HumanoidRootPart")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    return hrp and hum and hum.Health>0 and root and (hrp.Position-root.Position).Magnitude<=(range or 15)
end
function World:Build(interact)
    local old=workspace:FindFirstChild("AnimeRNGWorld")
    if old then old:Destroy() end
    self.Stations={}; self.Spawns={}; self.Markers={}
    local root=Instance.new("Folder"); root.Name="AnimeRNGWorld"; root.Parent=workspace
    self.Root=root
    local moss=Color3.fromRGB(75,123,96)
    local stone=Color3.fromRGB(47,55,73)
    for zone=1,2 do
        local origin=Vector3.new((zone-1)*500,0,0)
        local folder=Instance.new("Folder"); folder.Name="World"..zone; folder.Parent=root
        local accent=zone==1 and Color3.fromRGB(114,155,245) or Color3.fromRGB(188,101,236)
        part(folder,"Island",Vector3.new(300,5,360),origin+Vector3.new(0,-2.5,-35),zone==1 and moss or Color3.fromRGB(83,65,110),Enum.Material.Grass)
        part(folder,"Plaza",Vector3.new(148,0.4,86),origin+Vector3.new(0,0.15,64),stone,Enum.Material.Slate)
        part(folder,"MainPath",Vector3.new(12,0.3,195),origin+Vector3.new(0,0.2,-68),Color3.fromRGB(128,128,138),Enum.Material.Cobblestone)
        local spawn=Instance.new("SpawnLocation")
        spawn.Name="World"..zone.."Spawn"; spawn.Size=Vector3.new(8,0.6,8)
        spawn.CFrame=CFrame.new(origin+Vector3.new(0,0.8,85))
        spawn.Anchored=true; spawn.Neutral=true; spawn.Enabled=zone==1
        spawn.Transparency=0.8; spawn.Duration=0; spawn.Parent=folder
        self.Spawns[zone]=spawn
        local sign=part(folder,"Welcome",Vector3.new(1,1,1),origin+Vector3.new(0,8,102),accent,nil,false)
        sign.Transparency=1
        Factory.Label(sign,zone==1 and "STARFALL VILLAGE\nSummon • Explore • Defeat the Void" or "ECLIPSE WASTES\nWorld 2 • Stronger monsters",0)
        self.Stations[zone]={}
        local stationSpecs={{"Summon",-37,69,"Summon / 10 coins"},{"Craft",37,69,"Craft luck upgrades"},{"Trade",-62,42,"Open trading"},{"Shop",62,42,"Luck shop"},{"Portal",0,110,zone==1 and "Travel to World 2" or "Return to Village"}}
        for _,spec in ipairs(stationSpecs) do
            local key,x,z,text=spec[1],spec[2],spec[3],spec[4]
            local base=part(folder,key,Vector3.new(13,1.4,13),origin+Vector3.new(x,0.8,z),stone,Enum.Material.Marble)
            local ring=part(folder,key.."Rune",Vector3.new(11,0.15,11),origin+Vector3.new(x,1.6,z),accent,Enum.Material.Neon,false)
            ring.Transparency=0.45
            if key=="Craft" then
                part(folder,"Workbench",Vector3.new(7,1,4),origin+Vector3.new(x,3,z),Color3.fromRGB(122,89,64),Enum.Material.Wood)
                part(folder,"Anvil",Vector3.new(3,1.5,2),origin+Vector3.new(x,4,z),Color3.fromRGB(104,120,144),Enum.Material.Metal)
            else
                for _,side in ipairs({-1,1}) do
                    part(folder,key.."Pillar",Vector3.new(1.3,9,1.3),origin+Vector3.new(x+side*5,5,z+3),stone,Enum.Material.Marble)
                end
                part(folder,key.."Arch",Vector3.new(12,1.3,1.3),origin+Vector3.new(x,9.5,z+3),accent,Enum.Material.Neon,false)
                local crystal=part(folder,key.."Crystal",Vector3.new(2,3,2),origin+Vector3.new(x,4,z),accent,Enum.Material.Neon,false)
                crystal.CFrame=crystal.CFrame*CFrame.Angles(0,math.rad(45),math.rad(18))
            end
            Factory.Label(base,text,6)
            self.Stations[zone][key]=base
            prompt(base,text,function(player)
                if World:Near(player,base,15) then interact(player,key,zone) end
            end)
        end
        part(folder,"BossArena",Vector3.new(74,0.8,58),origin+Vector3.new(0,0.4,-160),stone,Enum.Material.Slate)
        for _,x in ipairs({-36,36}) do
            for _,z in ipairs({-135,-185}) do
                part(folder,"ArenaPillar",Vector3.new(3,13,3),origin+Vector3.new(x,6.5,z),stone,Enum.Material.Basalt)
                part(folder,"ArenaBeacon",Vector3.new(3.4,1,3.4),origin+Vector3.new(x,13.5,z),accent,Enum.Material.Neon,false)
            end
        end
        local spots={{"Slime",-35,5},{"Slime",0,-5},{"Slime",35,5},{"Bandit",-65,-35},{"Bandit",65,-35},{"Ogre",-38,-67},{"Ogre",38,-67},{"Demon",-63,-102},{"Titan",43,-105},{"WorldBoss",0,-160}}
        for index,spot in ipairs(spots) do
            table.insert(self.Markers,{Key="W"..zone.."_"..index,Id=spot[1],World=zone,Position=origin+Vector3.new(spot[2],0,spot[3])})
        end
        -- Boundary scenery, kept outside the flat navigation corridors.
        local random=Random.new(zone*197)
        for i=1,26 do
            local x=(i%2==0 and 1 or -1)*random:NextNumber(108,140)
            local z=random:NextNumber(-200,125)
            local pos=origin+Vector3.new(x,0,z)
            part(folder,"TreeTrunk",Vector3.new(2,9,2),pos+Vector3.new(0,4.5,0),Color3.fromRGB(85,68,56),Enum.Material.Wood)
            local canopy=part(folder,"TreeCanopy",Vector3.new(12,10,12),pos+Vector3.new(0,11,0),zone==1 and Color3.fromRGB(70,148,116) or Color3.fromRGB(143,91,164),Enum.Material.Grass,false)
            canopy.Shape=Enum.PartType.Ball
        end
    end
    return root
end
function World:Teleport(player,zone)
    local spawn=self.Spawns[zone]
    if not spawn then return end
    player:SetAttribute("World",zone)
    if player.Character then player.Character:PivotTo(spawn.CFrame*CFrame.new(0,4,0)) end
end
return World

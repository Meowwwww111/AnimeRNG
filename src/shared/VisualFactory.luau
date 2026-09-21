-- Cosmetic factory. Never used to calculate damage, rolls, access, inventory or rewards.
local RS=game:GetService("ReplicatedStorage")
local Characters=require(script.Parent.CharacterDatabase)
local Monsters=require(script.Parent.MonsterDatabase)
local Art=require(script.Parent.ArtDirection)
local Worlds=require(script.Parent.WorldConfig)
local V={}
local function rgb(t) return Color3.fromRGB(t[1],t[2],t[3]) end
local ink=rgb({24,26,39})
local function part(model,name,size,cf,tint,shape,class)
    local p=Instance.new(class or "Part")
    p.Name=name; p.Size=size; p.CFrame=cf; p.Color=tint
    p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
    p.CastShadow=true; p.Material=Enum.Material.SmoothPlastic
    if shape then p.Shape=shape end
    p.Parent=model; return p
end
local function detail(model,base,name,size,offset,tint,shape,class)
    local p=part(model,name,size,base.CFrame*offset,tint,shape,class)
    p.Anchored=false; p.Massless=true
    local w=Instance.new("WeldConstraint"); w.Part0=base; w.Part1=p; w.Parent=p
    return p
end
local function bone(model,name,parent,size,tint,c0,c1)
    c1=c1 or CFrame.new()
    local p=part(model,name,size,parent.CFrame*c0*c1:Inverse(),tint)
    p.Anchored=false; p.Massless=true
    local j=Instance.new("Motor6D"); j.Name=name.."Joint"; j.Part0=parent; j.Part1=p
    j.C0=c0; j.C1=c1; j.Parent=parent
    return p
end
local function glow(p) p.Material=Enum.Material.Neon; p.CastShadow=false; return p end
local function wedge(model,base,name,size,offset,tint)
    return detail(model,base,name,size,offset,tint,nil,"WedgePart")
end
local function nameplate(root)
    local g=Instance.new("BillboardGui"); g.Name="Nameplate"; g.Size=UDim2.fromOffset(235,55)
    g.MaxDistance=80; g.StudsOffset=Vector3.new(0,3.7,0); g.Adornee=root; g.Parent=root
    local t=Instance.new("TextLabel"); t.Name="Text"; t.BackgroundTransparency=1; t.Size=UDim2.fromScale(1,1)
    t.Font=Enum.Font.GothamMedium; t.TextSize=13; t.TextColor3=Color3.new(1,1,1); t.TextStrokeTransparency=0.2
    t.TextWrapped=true; t.Parent=g
end
local function hair(model,head,tint,style)
    -- Flattened cap plus tapered locks: no upright rectangular 'hair sticks'.
    detail(model,head,"HairCrown",Vector3.new(1.29,0.67,1.17),CFrame.new(0,0.48,0.04),tint,Enum.PartType.Ball)
    for i=-2,2 do
        local sweep=style=="Sweep" and 0.23 or 0
        local length=style=="Crop" and 0.5 or 0.72+math.abs(i)*0.045
        local lock=wedge(model,head,"TaperedFringe",Vector3.new(0.31,length,0.2),
            CFrame.new(i*0.225+sweep,0.32,-0.54)*CFrame.Angles(math.rad(170),0,math.rad(i*9-18*sweep)),tint)
        if style=="Flame" then lock.Color=tint:Lerp(Color3.fromRGB(242,175,64),math.abs(i)*0.08) end
    end
    for _,s in ipairs({-1,1}) do
        wedge(model,head,"SideLock",Vector3.new(0.22,style=="Long" and 1.35 or 0.78,0.58),
            CFrame.new(s*0.58,0.12,0.05)*CFrame.Angles(0,0,math.rad(s*8)),tint)
    end
    if style=="Flame" then
        for i=-2,2 do
            wedge(model,head,"SweptCrownLock",Vector3.new(0.31,0.8,0.65),
                CFrame.new(i*0.22,0.79,0.14)*CFrame.Angles(math.rad(35),0,math.rad(-i*18)),tint)
        end
    elseif style=="Long" then
        detail(model,head,"BackHair",Vector3.new(1.13,1.5,0.32),CFrame.new(0,-0.02,0.58),tint)
    end
end
local function face(model,head,accent,mask,evil)
    for _,s in ipairs({-1,1}) do
        detail(model,head,"Ear",Vector3.new(0.14,0.25,0.17),CFrame.new(s*0.6,-0.06,0),head.Color,Enum.PartType.Ball)
        -- Whites, colored iris, pupil and upper lash give a readable focused expression.
        detail(model,head,"EyeWhite",Vector3.new(0.34,0.16,0.03),CFrame.new(s*0.27,0.05,-0.543),Color3.fromRGB(246,241,233))
        local iris=detail(model,head,"Iris",Vector3.new(0.12,0.155,0.035),CFrame.new(s*0.255,0.045,-0.565),accent)
        if evil then glow(iris) end
        detail(model,head,"Pupil",Vector3.new(0.045,0.12,0.022),CFrame.new(s*0.255,0.043,-0.59),ink)
        detail(model,head,"EyeGlint",Vector3.new(0.035,0.045,0.024),CFrame.new(s*0.255-0.025,0.083,-0.606),Color3.new(1,1,1))
        detail(model,head,"UpperLash",Vector3.new(0.37,0.045,0.035),CFrame.new(s*0.27,0.14,-0.572)*CFrame.Angles(0,0,math.rad(s*9)),ink)
        detail(model,head,"Brow",Vector3.new(0.32,0.055,0.04),CFrame.new(s*0.27,0.26,-0.54)*CFrame.Angles(0,0,math.rad(s*10)),ink)
    end
    if mask then
        detail(model,head,"HalfMask",Vector3.new(1.08,0.42,0.19),CFrame.new(0,-0.3,-0.5),ink)
    else
        wedge(model,head,"Nose",Vector3.new(0.075,0.16,0.11),CFrame.new(0,-0.115,-0.575)*CFrame.Angles(0,math.pi,0),head.Color:Lerp(ink,0.08))
        detail(model,head,"Mouth",Vector3.new(0.19,0.022,0.024),CFrame.new(0,-0.35,-0.538),head.Color:Lerp(ink,0.6))
    end
end
local function humanoid(name,tint,hairColor,accent,look,weapon,scale,kind)
    local model=Instance.new("Model"); model.Name=name
    local skin=kind and tint:Lerp(rgb({159,145,125}),0.3) or rgb({229,183,149})
    local root=part(model,"Root",Vector3.new(1,1,1),CFrame.new(),ink); root.Transparency=1; model.PrimaryPart=root
    local torso=bone(model,"Torso",root,Vector3.new(1.62,1.75,0.85),tint,CFrame.new(0,0.25,0))
    local pelvis=bone(model,"Pelvis",torso,Vector3.new(1.35,0.65,0.78),ink,CFrame.new(0,-1.15,0))
    local neck=detail(model,torso,"Neck",Vector3.new(0.4,0.27,0.4),CFrame.new(0,1.03,0),skin)
    neck.Shape=Enum.PartType.Ball
    local head=bone(model,"Head",torso,Vector3.new(1.13,1.25,1.04),skin,CFrame.new(0,1.68,0))
    -- Built-in head mesh has a softer jaw/crown than the earlier large box.
    local hm=Instance.new("SpecialMesh"); hm.MeshType=Enum.MeshType.Head; hm.Scale=Vector3.new(1,1,1); hm.Parent=head
    face(model,head,accent,look.Mask,kind~=nil)
    for _,s in ipairs({-1,1}) do
        local suffix=s==1 and "R" or "L"
        local upper=bone(model,"UpperArm"..suffix,torso,Vector3.new(0.57,1.3,0.62),tint,CFrame.new(s*1.08,0.65,0),CFrame.new(0,0.65,0))
        local lower=bone(model,"Forearm"..suffix,upper,Vector3.new(0.51,1.1,0.55),tint:Lerp(ink,0.18),CFrame.new(0,-0.65,0),CFrame.new(0,0.55,0))
        detail(model,lower,"Hand"..suffix,Vector3.new(0.5,0.38,0.52),CFrame.new(0,-0.63,0),skin)
        local thigh=bone(model,"Thigh"..suffix,pelvis,Vector3.new(0.59,1.25,0.65),ink,CFrame.new(s*0.37,-0.28,0),CFrame.new(0,0.625,0))
        local shin=bone(model,"Shin"..suffix,thigh,Vector3.new(0.52,1.1,0.58),ink,CFrame.new(0,-0.625,0),CFrame.new(0,0.55,0))
        detail(model,shin,"Boot"..suffix,Vector3.new(0.61,0.45,0.85),CFrame.new(0,-0.48,-0.12),tint:Lerp(ink,0.62))
        detail(model,lower,"Cuff",Vector3.new(0.57,0.19,0.6),CFrame.new(0,-0.34,0),accent)
        if look.Outfit=="Armor" then
            wedge(model,upper,"ShoulderPlate",Vector3.new(0.85,0.45,1),CFrame.new(s*0.12,0.58,0)*CFrame.Angles(0,0,math.rad(-s*12)),accent)
            detail(model,shin,"Greave",Vector3.new(0.57,0.75,0.16),CFrame.new(0,-0.03,-0.34),tint:Lerp(accent,0.45))
        end
    end
    detail(model,torso,"WaistSash",Vector3.new(1.73,0.25,0.94),CFrame.new(0,-0.62,0),accent)
    detail(model,torso,"Collar",Vector3.new(1.13,0.32,0.96),CFrame.new(0,0.76,0),tint:Lerp(ink,0.42))
    for _,s in ipairs({-1,1}) do
        detail(model,torso,"Lapel",Vector3.new(0.14,1.12,0.055),CFrame.new(s*0.34,0.12,-0.46)*CFrame.Angles(0,0,math.rad(s*18)),accent)
    end
    if look.Outfit=="Longcoat" or look.Outfit=="Haori" or look.Outfit=="Robe" then
        for _,s in ipairs({-1,1}) do
            local coat=bone(model,"Coat"..(s==1 and "R" or "L"),pelvis,Vector3.new(0.7,1.6,0.18),tint,
                CFrame.new(s*0.45,-0.15,0.48),CFrame.new(0,0.65,0))
            detail(model,coat,"HemTrim",Vector3.new(0.71,0.15,0.2),CFrame.new(0,-0.7,0),accent)
        end
        if look.Outfit=="Haori" then
            detail(model,torso,"HaoriBack",Vector3.new(1.83,1.6,0.12),CFrame.new(0,0.12,0.49),tint:Lerp(accent,0.3))
        end
    elseif look.Outfit=="Armor" then
        wedge(model,torso,"ChestArmor",Vector3.new(1.42,1.1,0.2),CFrame.new(0,0.17,-0.52)*CFrame.Angles(math.pi,0,0),tint:Lerp(accent,0.35))
    end
    if look.Scarf then
        detail(model,torso,"Scarf",Vector3.new(1.17,0.3,1.02),CFrame.new(0,0.89,0),accent)
        bone(model,"ScarfTail",torso,Vector3.new(0.43,1.48,0.1),accent,CFrame.new(-0.39,0.7,0.63),CFrame.new(0,0.63,0))
    end
    if kind~="Sentinel" and kind~="Regent" and kind~="StoneGuardian" and kind~="Crystal" and kind~="Obsidian" then hair(model,head,hairColor,look.Hair or "Sweep") end
    if look.Crown or kind=="Regent" then
        for i=-2,2 do
            glow(wedge(model,head,"CrownPoint",Vector3.new(0.17,0.45+math.abs(i)*0.08,0.19),CFrame.new(i*0.24,0.8,-0.14)*CFrame.Angles(0,0,math.rad(-i*10)),accent))
        end
    end
    local hand=model:FindFirstChild("ForearmR")
    if weapon=="Sword" or weapon=="Scythe" then
        detail(model,hand,"WrappedGrip",Vector3.new(0.17,0.8,0.19),CFrame.new(0,-0.67,-0.42),ink)
        detail(model,hand,"SwordGuard",Vector3.new(0.8,0.12,0.37),CFrame.new(0,-0.16,-0.42),accent)
        local blade=detail(model,hand,"SteelBlade",Vector3.new(0.16,2.5,0.08),CFrame.new(0,1.15,-0.42),rgb({213,229,238}))
        blade.Material=Enum.Material.Metal
        wedge(model,hand,"BladeTip",Vector3.new(0.16,0.45,0.08),CFrame.new(0,2.6,-0.42),blade.Color)
        detail(model,pelvis,"Scabbard",Vector3.new(0.22,2.75,0.23),CFrame.new(-0.92,-0.25,0.44)*CFrame.Angles(math.rad(-12),0,math.rad(-18)),ink)
        if weapon=="Scythe" then
            wedge(model,hand,"ScytheHook",Vector3.new(2.3,0.65,0.13),CFrame.new(-0.95,2.35,-0.42)*CFrame.Angles(0,0,math.rad(-12)),accent)
        end
    elseif weapon=="Staff" then
        detail(model,hand,"StaffShaft",Vector3.new(0.17,4.8,0.17),CFrame.new(0,-0.4,-0.48),hairColor)
        glow(detail(model,hand,"FocusCrystal",Vector3.new(0.44,0.75,0.44),CFrame.new(0,2.1,-0.48)*CFrame.Angles(0,0,math.rad(35)),accent))
    else
        for _,s in ipairs({"L","R"}) do
            detail(model,model["Forearm"..s],"Bracer",Vector3.new(0.67,0.68,0.73),CFrame.new(0,-0.28,0),tint:Lerp(accent,0.35))
        end
    end
    if kind=="Oni" or kind=="Fiend" or kind=="Devourer" then
        for _,s in ipairs({-1,1}) do
            wedge(model,head,"CurvedHorn",Vector3.new(0.22,0.95,0.32),CFrame.new(s*0.51,0.86,0.13)*CFrame.Angles(math.rad(-20),0,math.rad(s*30)),rgb({227,211,165}))
            if kind=="Fiend" or kind=="Devourer" then
                wedge(model,torso,"Wing",Vector3.new(1.8,2.7,0.22),CFrame.new(s*1.6,0.4,0.65)*CFrame.Angles(0,0,math.rad(-s*23)),tint:Lerp(ink,0.4))
            end
        end
    elseif kind=="Sentinel" or kind=="Regent" then
        detail(model,head,"ClosedHelm",Vector3.new(1.27,1.3,1.31),CFrame.new(0,0.09,-0.02),ink)
        glow(detail(model,head,"HelmVisor",Vector3.new(0.81,0.1,0.04),CFrame.new(0,0.14,-0.69),accent))
    elseif kind=="StoneGuardian" or kind=="Obsidian" or kind=="Crystal" then
        for _,s in ipairs({-1,1}) do
            local plate=wedge(model,torso,"StoneShard",Vector3.new(1.1,1.6,1.1),CFrame.new(s*0.97,0.53,0)*CFrame.Angles(0,0,math.rad(-s*20)),tint)
            if kind=="Crystal" then glow(plate) end
        end
        glow(detail(model,torso,"HeartCore",Vector3.new(0.34,0.8,0.09),CFrame.new(0,0.18,-0.63)*CFrame.Angles(0,0,math.rad(32)),accent))
    end
    model:ScaleTo(scale)
    nameplate(root)
    root.Nameplate.StudsOffset=Vector3.new(0,3.25*scale,0)
    return model
end
local allowed={Model=true,Folder=true,Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true,
    SpecialMesh=true,BlockMesh=true,CylinderMesh=true,Decal=true,Texture=true,SurfaceAppearance=true,
    Motor6D=true,Weld=true,WeldConstraint=true,Attachment=true,Bone=true,AnimationController=true,Animator=true}
local function imported(kind,id)
    -- Optional artist-approved LOCAL template. No HTTP, InsertService or require(assetId).
    local bank=RS:FindFirstChild("ArtAssets")
    local group=bank and bank:FindFirstChild(kind=="Unit" and "Units" or "Enemies")
    local template=group and group:FindFirstChild(id)
    if not template or not template:IsA("Model") or template:GetAttribute("ArtReviewed")~=true then return nil end
    local copy=template:Clone()
    if not copy then return nil end
    -- Strip code, packages, remotes, audio, physics helpers and effects before parenting.
    for _,item in ipairs(copy:GetDescendants()) do if not allowed[item.ClassName] then item:Destroy() end end
    local root=copy:FindFirstChild("HumanoidRootPart",true) or copy:FindFirstChild("Root",true) or copy.PrimaryPart
    if not root or not root:IsA("BasePart") then copy:Destroy(); return nil end
    copy.PrimaryPart=root
    local parts={}; local edges={}; local count=0
    for _,p in ipairs(copy:GetDescendants()) do
        if p:IsA("BasePart") then
            count=count+1; parts[p]=true; edges[p]={}
            p.Anchored=p==root; p.Massless=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false
        end
    end
    if count>180 then copy:Destroy(); return nil end
    for _,j in ipairs(copy:GetDescendants()) do
        if j:IsA("Motor6D") or j:IsA("Weld") or j:IsA("WeldConstraint") then
            if parts[j.Part0] and parts[j.Part1] then
                table.insert(edges[j.Part0],j.Part1); table.insert(edges[j.Part1],j.Part0)
            else j:Destroy() end
        end
    end
    -- Unconnected static accessories are welded once; no cosmetic part falls under physics.
    local reached={}
    local function visit(p)
        if reached[p] then return end
        reached[p]=true
        for _,other in ipairs(edges[p]) do visit(other) end
    end
    visit(root)
    for p in pairs(parts) do
        if not reached[p] then
            local weld=Instance.new("WeldConstraint"); weld.Part0=root; weld.Part1=p; weld.Parent=p
            visit(p)
        end
    end
    root.Transparency=1; nameplate(root)
    copy:SetAttribute("ImportedArt",true)
    return copy
end
function V.Build(kind,id,world)
    local external=imported(kind,kind=="Unit" and id or ("W"..world.."_"..id))
    if external then return external end
    if kind=="Unit" then
        local c=Characters[id]; if not c then return nil end
        local a=Art.Units[id]
        return humanoid(c.Name,rgb(c.Color),rgb(c.Hair),rgb(a.Accent),a,c.Weapon,0.86)
    end
    local cfg=Monsters[id]; if not cfg then return nil end
    local style=Art.Enemies[world][id]
    local accent=world==1 and rgb({167,218,138}) or rgb({148,134,255})
    if style=="Slime" or style=="Wisp" then
        local model=Instance.new("Model"); model.Name=style
        local root=part(model,"Root",Vector3.new(1,1,1),CFrame.new(),ink); root.Transparency=1; model.PrimaryPart=root
        if style=="Slime" then
            local body=detail(model,root,"Jelly",Vector3.new(3.65,2.7,3.5),CFrame.new(0,-0.25,0),rgb(cfg.Color),Enum.PartType.Ball)
            body.Transparency=0.12
            for _,s in ipairs({-1,1}) do
                detail(model,root,"Eye",Vector3.new(0.28,0.44,0.08),CFrame.new(s*0.51,0.08,-1.56),ink,Enum.PartType.Ball)
                detail(model,root,"Shine",Vector3.new(0.07,0.1,0.03),CFrame.new(s*0.51-0.055,0.19,-1.605),Color3.new(1,1,1))
            end
            detail(model,root,"Mouth",Vector3.new(0.32,0.04,0.035),CFrame.new(0,-0.31,-1.62),ink)
        else
            glow(detail(model,root,"FloatingCore",Vector3.new(1.1,1.9,1.1),CFrame.new(0,0.5,0)*CFrame.Angles(0,0,math.rad(35)),accent))
            for i=1,4 do
                glow(wedge(model,root,"OrbitShard",Vector3.new(0.42,1.65,0.5),CFrame.Angles(0,i*math.pi/2,0)*CFrame.new(1.1,-0.2,0),accent:Lerp(ink,0.25)))
            end
        end
        nameplate(root); return model
    end
    local a={Outfit="Armor",Hair="Crop",Mask=false,Crown=style=="Regent"}
    if style=="Shinobi" then a={Outfit="Uniform",Hair="Sweep",Mask=true,Scarf=true} end
    if style=="Reaper" or style=="Devourer" then a.Outfit="Longcoat" end
    local tint=world==1 and rgb(cfg.Color) or rgb({49,48,74})
    return humanoid(Worlds[world].EnemyNames[id],tint,rgb({40,35,47}),accent,a,
        style=="Reaper" and "Scythe" or ((style=="Sentinel" or style=="Regent") and "Sword" or "Fists"),cfg.Scale,style)
end
function V.Joints(model)
    local out={}
    for _,j in ipairs(model:GetDescendants()) do if j:IsA("Motor6D") then out[j.Name]=j end end
    return out
end
function V.Animate(joints,time,speed,attack)
    local gait=math.sin(time*9)*0.43*speed
    local breath=math.sin(time*2.1)*0.014
    local function pose(name,x,y,z)
        local j=joints[name.."Joint"]
        if j then j.Transform=CFrame.Angles(x or 0,y or 0,z or 0) end
    end
    pose("Torso",breath,attack*0.17,0)
    pose("UpperArmR",gait-attack*1.4,0,0.06+attack*0.18)
    pose("UpperArmL",-gait-attack*0.25,0,-0.06)
    pose("ForearmR",-0.1-attack*0.55); pose("ForearmL",-0.12)
    pose("ThighL",gait); pose("ThighR",-gait)
    pose("ShinL",math.max(0,-gait)*0.85); pose("ShinR",math.max(0,gait)*0.85)
    pose("CoatL",0.06+gait*0.12); pose("CoatR",0.06-gait*0.12)
    pose("ScarfTail",0.1+speed*0.25+math.sin(time*4)*0.03)
end
return V

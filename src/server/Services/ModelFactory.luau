-- Original low-poly geometry only. No remote asset execution, catalog models or meshes.
local Factory={}
local function color(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
Factory.Color=color
function Factory.Part(parent,name,size,cf,tint,material,shape)
    local p=Instance.new("Part")
    p.Name=name; p.Size=size; p.CFrame=cf; p.Color=tint
    p.Material=material or Enum.Material.SmoothPlastic
    p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
    if shape then p.Shape=shape end
    p.Parent=parent
    return p
end
local function detail(parent,base,name,size,offset,tint,material,shape)
    local p=Factory.Part(parent,name,size,base.CFrame*offset,tint,material,shape)
    p.Anchored=false; p.Massless=true
    local weld=Instance.new("WeldConstraint"); weld.Part0=base; weld.Part1=p; weld.Parent=p
    return p
end
function Factory.Label(root,text,offset)
    local gui=Instance.new("BillboardGui")
    gui.Name="Nameplate"; gui.Size=UDim2.fromOffset(230,55)
    gui.StudsOffset=Vector3.new(0,offset or 4,0); gui.MaxDistance=95
    gui.Adornee=root; gui.AlwaysOnTop=false; gui.Parent=root
    local label=Instance.new("TextLabel")
    label.Name="Text"; label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1
    label.TextColor3=Color3.new(1,1,1); label.TextStrokeTransparency=0.3
    label.Font=Enum.Font.GothamBold; label.TextSize=14; label.TextWrapped=true
    label.Text=text; label.Parent=gui
    return label
end
local function joint(parent,name,a,b,c0,c1)
    b.Anchored=false; b.Massless=true
    local m=Instance.new("Motor6D"); m.Name=name; m.Part0=a; m.Part1=b
    m.C0=c0; m.C1=c1 or CFrame.new(); m.Parent=parent
    m:SetAttribute("Rest",c0)
    return m
end
function Factory.Humanoid(name,tint,hair,weapon,rank,scale,kind)
    local model=Instance.new("Model"); model.Name=name
    local dark=Color3.fromRGB(31,34,49)
    local skin=kind and tint:Lerp(Color3.fromRGB(130,115,100),0.25) or Color3.fromRGB(231,185,146)
    local root=Factory.Part(model,"Root",Vector3.new(1,1,1),CFrame.new(),dark)
    root.Transparency=1; model.PrimaryPart=root
    local torso=Factory.Part(model,"Torso",Vector3.new(2,2,1),CFrame.new(),tint)
    joint(root,"RootJoint",root,torso,CFrame.new())
    local head=Factory.Part(model,"Head",Vector3.new(1.65,1.55,1.45),CFrame.new(0,1.8,0),skin)
    joint(torso,"Neck",torso,head,CFrame.new(0,1.8,0))
    for _,side in ipairs({-1,1}) do
        local suffix=side==1 and "R" or "L"
        local arm=Factory.Part(model,"Arm"..suffix,Vector3.new(0.8,2,0.85),CFrame.new(side*1.45,0,0),tint)
        joint(torso,"Shoulder"..suffix,torso,arm,CFrame.new(side*1.45,0.8,0),CFrame.new(0,0.8,0))
        local leg=Factory.Part(model,"Leg"..suffix,Vector3.new(0.85,2,0.9),CFrame.new(side*0.52,-2,0),dark)
        joint(torso,"Hip"..suffix,torso,leg,CFrame.new(side*0.52,-1,0),CFrame.new(0,1,0))
        detail(model,arm,"Hand",Vector3.new(0.83,0.5,0.88),CFrame.new(0,-0.95,0),skin)
        detail(model,leg,"Boot",Vector3.new(0.95,0.5,1.2),CFrame.new(0,-0.8,-0.1),tint:Lerp(dark,0.5))
        detail(model,head,"Eye",Vector3.new(0.3,0.13,0.1),CFrame.new(side*0.38,0.05,-0.74),kind and Color3.fromRGB(255,95,90) or dark,kind and Enum.Material.Neon or nil)
    end
    detail(model,torso,"Belt",Vector3.new(2.12,0.25,1.1),CFrame.new(0,-0.65,0),dark)
    detail(model,head,"HairCap",Vector3.new(1.8,0.6,1.6),CFrame.new(0,0.7,0.08),hair)
    for i=-2,2 do
        detail(model,head,"HairSpike",Vector3.new(0.35,1+math.abs(i)*0.13,0.55),CFrame.new(i*0.32,1.05,0.05)*CFrame.Angles(0,0,math.rad(-i*16)),hair)
    end
    if rank>=4 or kind then
        detail(model,torso,"Mantle",Vector3.new(2.3,2.7,0.2),CFrame.new(0,-0.25,0.8)*CFrame.Angles(math.rad(-9),0,0),tint:Lerp(dark,0.35))
        for _,x in ipairs({-1.3,1.3}) do detail(model,torso,"Pauldron",Vector3.new(1.1,0.65,1.3),CFrame.new(x,0.8,0),hair) end
    end
    local arm=model:FindFirstChild("ArmR")
    if weapon=="Sword" then
        detail(model,arm,"Hilt",Vector3.new(0.28,1,0.28),CFrame.new(0,-1.1,-0.55),dark)
        detail(model,arm,"Guard",Vector3.new(1.4,0.2,0.4),CFrame.new(0,-0.6,-0.55),hair)
        detail(model,arm,"Blade",Vector3.new(0.38,3.4,0.15),CFrame.new(0,1.2,-0.55),rank>=5 and hair or Color3.fromRGB(205,221,235),rank>=5 and Enum.Material.Neon or Enum.Material.Metal)
    elseif weapon=="Staff" then
        detail(model,arm,"Staff",Vector3.new(0.25,5.5,0.25),CFrame.new(0,-0.6,-0.6),dark)
        detail(model,arm,"StaffGem",Vector3.new(0.8,0.8,0.8),CFrame.new(0,2.1,-0.6),tint,Enum.Material.Neon,Enum.PartType.Ball)
    else
        for _,suffix in ipairs({"L","R"}) do
            detail(model,model["Arm"..suffix],"Gauntlet",Vector3.new(1,0.8,1),CFrame.new(0,-0.8,0),hair,Enum.Material.Metal)
        end
    end
    if kind=="Demon" or kind=="Boss" then
        for _,side in ipairs({-1,1}) do
            detail(model,head,"Horn",Vector3.new(0.35,1.8,0.35),CFrame.new(side*0.8,1.1,0)*CFrame.Angles(0,0,math.rad(side*28)),Color3.fromRGB(222,186,143))
        end
    end
    if rank>=5 then
        local light=Instance.new("PointLight"); light.Color=hair; light.Brightness=0.65; light.Range=10; light.Parent=torso
        detail(model,torso,"Core",Vector3.new(0.45,0.65,0.12),CFrame.new(0,0.25,-0.57),hair,Enum.Material.Neon)
    end
    local controller=Instance.new("AnimationController"); controller.Parent=model
    local animator=Instance.new("Animator"); animator.Parent=controller
    model:ScaleTo(scale or 1)
    for _,m in ipairs(model:GetDescendants()) do
        if m:IsA("Motor6D") then m:SetAttribute("Rest",m.C0) end
    end
    model:SetAttribute("Height",3*(scale or 1))
    Factory.Label(root,name,3.8*(scale or 1))
    return model
end
function Factory.Monster(id,cfg,world)
    local tint=color(cfg.Color)
    if world==2 then tint=tint:Lerp(Color3.fromRGB(153,93,220),0.35) end
    if cfg.Kind~="Slime" then
        local model=Factory.Humanoid(id,tint,Color3.fromRGB(62,52,76),"Fists",cfg.Kind=="Boss" and 6 or 2,cfg.Scale,cfg.Kind)
        for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") and p.Name~="Root" then p.CanQuery=true end end
        return model
    end
    local model=Instance.new("Model"); model.Name=id
    local root=Factory.Part(model,"Root",Vector3.new(4.2,3.2,4.2),CFrame.new(),tint,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
    root.CanQuery=true; model.PrimaryPart=root; model:SetAttribute("Height",1.6)
    for _,x in ipairs({-0.7,0.7}) do
        detail(model,root,"Eye",Vector3.new(0.55,0.7,0.2),CFrame.new(x,0.4,-1.8),Color3.fromRGB(25,37,38))
        detail(model,root,"Sparkle",Vector3.new(0.17,0.17,0.1),CFrame.new(x-0.1,0.6,-1.94),Color3.new(1,1,1))
    end
    Factory.Label(root,id,3)
    return model
end
function Factory.Animate(model,time,moving,attacking)
    local torso=model:FindFirstChild("Torso")
    if not torso then return end
    for _,jointName in ipairs({"ShoulderR","ShoulderL","HipR","HipL"}) do
        local m=torso:FindFirstChild(jointName)
        if m then
            local sign=(jointName=="ShoulderR" or jointName=="HipL") and 1 or -1
            local angle=moving and math.sin(time*9)*0.45*sign or math.sin(time*2)*0.04
            if attacking and jointName=="ShoulderR" then angle=-1.8 end
            m.C0=m:GetAttribute("Rest")*CFrame.Angles(angle,0,0)
        end
    end
end
return Factory

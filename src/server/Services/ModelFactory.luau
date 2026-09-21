-- Server owns ONE invisible root per actor. Clients render cosmetic rigs locally.
local CollectionService=game:GetService("CollectionService")
local Factory={}
function Factory.Color(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
function Factory.Part(parent,name,size,cf,tint,material,shape)
    local p=Instance.new("Part")
    p.Name=name; p.Size=size; p.CFrame=cf; p.Color=tint
    p.Material=material or Enum.Material.SmoothPlastic
    p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
    if shape then p.Shape=shape end
    p.Parent=parent
    return p
end
function Factory.Label(root,text,offset)
    local gui=Instance.new("BillboardGui")
    gui.Name="Nameplate"; gui.Size=UDim2.fromOffset(245,60); gui.MaxDistance=90
    gui.StudsOffset=Vector3.new(0,offset or 4,0); gui.Adornee=root; gui.Parent=root
    local label=Instance.new("TextLabel")
    label.Name="Text"; label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1
    label.TextColor3=Color3.new(1,1,1); label.TextStrokeTransparency=0.25
    label.Font=Enum.Font.GothamBold; label.TextSize=14; label.TextWrapped=true
    label.Text=text; label.Parent=gui
    return label
end
function Factory.Height(kind,cfg)
    if kind=="Unit" then return 3.7*0.86 end
    if cfg.Kind=="Slime" then return 1.65 end
    return 3.7*cfg.Scale
end
function Factory.Actor(kind,id,cfg,world)
    local model=Instance.new("Model"); model.Name=id
    local root=Factory.Part(model,"Root",Vector3.new(1,1,1),CFrame.new(),Color3.new())
    root.Transparency=1; model.PrimaryPart=root
    model:SetAttribute("VisualType",kind); model:SetAttribute("VisualId",id)
    model:SetAttribute("World",world); model:SetAttribute("Height",Factory.Height(kind,cfg))
    model:SetAttribute("Moving",false); model:SetAttribute("AttackUntil",0)
    return model
end
function Factory.Publish(model,cf,moving,attackUntil)
    model:PivotTo(cf)
    model:SetAttribute("Moving",moving==true)
    model:SetAttribute("AttackUntil",attackUntil or 0)
    model:SetAttribute("Pose",cf)
end
function Factory.Register(model)
    CollectionService:AddTag(model,"AnimeRNGActor")
end
return Factory

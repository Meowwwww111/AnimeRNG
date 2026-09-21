-- Client-only presentation. Server proxies remain the sole source of combat/access state.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
local Shared=RS:WaitForChild("Shared")
local V=require(Shared:WaitForChild("VisualFactory"))
local Math=require(Shared:WaitForChild("PresentationMath"))
local Worlds=require(Shared:WaitForChild("WorldConfig"))
local player=Players.LocalPlayer
local entries,pending={},{}
local folder=Instance.new("Folder"); folder.Name="AnimeRNG_LocalVisuals"; folder.Parent=workspace
local DELAY=0.15
local function remove(proxy)
    pending[proxy]=nil
    local e=entries[proxy]; if not e then return end
    entries[proxy]=nil
    for _,c in ipairs(e.Connections) do c:Disconnect() end
    if e.View then e.View:Destroy() end
end
local function label(e)
    if not e.View then return end
    local gui=e.View.PrimaryPart:FindFirstChild("Nameplate")
    if not gui then return end
    local p=e.Proxy; local name=p:GetAttribute("DisplayName") or p:GetAttribute("VisualId") or ""
    if p:GetAttribute("VisualType")=="Unit" then
        gui.Text.Text=name.." ["..(p:GetAttribute("Rarity") or "").."]\nLevel "..(p:GetAttribute("Level") or 1)
    else
        gui.Text.Text=name.."\n"..math.ceil(p:GetAttribute("HP") or 0).." / "..(p:GetAttribute("MaxHP") or 0).." HP"
    end
end
local function sample(e)
    local cf=e.Proxy:GetAttribute("Pose")
    if typeof(cf)~="CFrame" then return end
    local last=e.Samples[#e.Samples]
    if last and (last.CF.Position-cf.Position).Magnitude>80 then e.Samples={}; e.Current=cf end
    table.insert(e.Samples,{Time=os.clock(),CF=cf})
    while #e.Samples>6 do table.remove(e.Samples,1) end
end
local function add(proxy)
    if entries[proxy] or pending[proxy] or not proxy:IsA("Model") then return end
    pending[proxy]=true
    task.spawn(function()
        local deadline=os.clock()+5
        while proxy.Parent and (not proxy:GetAttribute("VisualType") or typeof(proxy:GetAttribute("Pose"))~="CFrame") and os.clock()<deadline do task.wait(0.05) end
        if not proxy.Parent or not pending[proxy] or not proxy:GetAttribute("VisualType") then pending[proxy]=nil; return end
        local e={Proxy=proxy,Samples={},Connections={},Speed=0,Attack=0,Active=false}
        entries[proxy]=e; pending[proxy]=nil
        table.insert(e.Connections,proxy:GetAttributeChangedSignal("Pose"):Connect(function() sample(e) end))
        for _,attr in ipairs({"HP","MaxHP","Level","DisplayName","Rarity"}) do
            table.insert(e.Connections,proxy:GetAttributeChangedSignal(attr):Connect(function() label(e) end))
        end
        table.insert(e.Connections,proxy.AncestryChanged:Connect(function(_,parent) if not parent then remove(proxy) end end))
        sample(e)
    end)
end
CollectionService:GetInstanceAddedSignal("AnimeRNGActor"):Connect(add)
CollectionService:GetInstanceRemovedSignal("AnimeRNGActor"):Connect(remove)
for _,proxy in ipairs(CollectionService:GetTagged("AnimeRNGActor")) do add(proxy) end
local lightTween
local function theme()
    local z=Worlds[player:GetAttribute("World") or 1]; if not z then return end
    local function c(t) return Color3.fromRGB(t[1],t[2],t[3]) end
    if lightTween then lightTween:Cancel() end
    lightTween=TweenService:Create(Lighting,TweenInfo.new(0.45),{
        ClockTime=z.ClockTime,Ambient=c(z.Ambient),OutdoorAmbient=c(z.OutdoorAmbient),
        FogColor=c(z.FogColor),FogStart=z.FogEnd*0.38,FogEnd=z.FogEnd})
    lightTween:Play()
end
player:GetAttributeChangedSignal("World"):Connect(theme); theme()
RunService.PreRender:Connect(function(dt)
    local now=os.clock(); local zone=player:GetAttribute("World") or 1
    local camera=workspace.CurrentCamera; local builds=0
    for proxy,e in pairs(entries) do
        local latest=e.Samples[#e.Samples]
        local active=latest~=nil and proxy:GetAttribute("World")==zone
            and (not camera or (latest.CF.Position-camera.CFrame.Position).Magnitude<380)
        e.Active=active
        if active and not e.View and builds<2 and not e.Failed then
            builds=builds+1
            local ok,view=pcall(V.Build,proxy:GetAttribute("VisualType"),proxy:GetAttribute("VisualId"),zone)
            if ok and view then
                e.View=view; e.Joints=V.Joints(view); e.Current=latest.CF
                view:PivotTo(e.Current); label(e)
            else
                e.Failed=true; warn("[AnimeRNG visual] "..proxy.Name..": "..tostring(view))
            end
        end
        if e.View then
            if active then
                if e.View.Parent~=folder then e.View.Parent=folder; e.Current=latest.CF end
                local a,b,t=Math.segment(e.Samples,now-DELAY)
                local target=e.Samples[a].CF:Lerp(e.Samples[b].CF,t)
                local following=proxy:GetAttribute("VisualType")=="Unit" and proxy:GetAttribute("Follow")==true
                if following then
                    local owner=Players:GetPlayerByUserId(proxy:GetAttribute("OwnerUserId") or 0)
                    local root=owner and owner.Character and owner.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local desired=root.CFrame*CFrame.new(3.4,0,3.6)
                        local pos=Vector3.new(desired.Position.X,latest.CF.Position.Y,desired.Position.Z)
                        target=CFrame.new(pos)*desired.Rotation
                        e.Current=(e.Current.Position-target.Position).Magnitude>70 and target or e.Current:Lerp(target,Math.alpha(16,dt))
                    else e.Current=target end
                else e.Current=target end
                local speed=proxy:GetAttribute("Moving") and 1 or 0
                if following and e.LastPosition and dt>0 then speed=math.min(1,(e.Current.Position-e.LastPosition).Magnitude/dt/8) end
                e.Speed=e.Speed+(speed-e.Speed)*Math.alpha(12,dt)
                e.LastPosition=e.Current.Position
                e.View:PivotTo(e.Current)
            elseif e.View.Parent then e.View.Parent=nil end
        end
    end
end)
RunService.PreSimulation:Connect(function(dt)
    local now=workspace:GetServerTimeNow()
    for proxy,e in pairs(entries) do
        if e.Active and e.View and not e.View:GetAttribute("ImportedArt") then
            local remaining=math.max(0,(proxy:GetAttribute("AttackUntil") or 0)-now)
            local attack=remaining>0 and math.sin(math.pi*math.min(1,remaining/0.42)) or 0
            e.Attack=e.Attack+(attack-e.Attack)*Math.alpha(22,dt)
            V.Animate(e.Joints,now,e.Speed,e.Attack)
        end
    end
end)
script.Destroying:Connect(function()
    for proxy in pairs(entries) do remove(proxy) end
    folder:Destroy()
end)

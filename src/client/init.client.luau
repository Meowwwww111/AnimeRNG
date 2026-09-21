local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Input=game:GetService("UserInputService")
local player=Players.LocalPlayer
local Shared=RS:WaitForChild("Shared")
local Characters=require(Shared.CharacterDatabase)
local Rarities=require(Shared.RarityConfig)
local Recipes=require(Shared.RecipeDatabase)
local Config=require(Shared.GameConfig)
local Rules=require(Shared.Rules)
local remotes=RS:WaitForChild("AnimeRNGRemotes",30)
if not remotes then warn("[AnimeRNG] Server failed to start. Check server Output."); return end
local request=remotes:WaitForChild("Request",30)
if not request then warn("[AnimeRNG] Pull the entire update and restart Play."); return end
local gui=Instance.new("ScreenGui"); gui.Name="AnimeRNG"; gui.ResetOnSpawn=false
local playerGui=player:WaitForChild("PlayerGui")
local old=playerGui:FindFirstChild(gui.Name); if old then old:Destroy() end
 gui.Parent=playerGui
local background=Color3.fromRGB(20,25,40)
local accent=Color3.fromRGB(113,160,248)
local textColor=Color3.fromRGB(233,239,252)
local state,tradeState,panelKind=nil,nil,nil
local render,perform
local function decorate(frame)
    frame.BackgroundColor3=background; frame.BorderSizePixel=0
    local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,9); corner.Parent=frame
end
local function label(parent,text,height)
    local t=Instance.new("TextLabel"); t.Size=UDim2.new(1,-16,0,height or 34)
    t.BackgroundTransparency=1; t.Font=Enum.Font.GothamMedium; t.TextSize=15
    t.TextWrapped=true; t.TextColor3=textColor; t.TextXAlignment=Enum.TextXAlignment.Left
    t.Text=text; t.Parent=parent
    return t
end
local function button(parent,text,callback,tint)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-16,0,40)
    b.Font=Enum.Font.GothamBold; b.TextSize=14; b.TextWrapped=true
    b.TextColor3=textColor; b.Text=text; decorate(b)
    b.BackgroundColor3=tint or Color3.fromRGB(44,63,92)
    b.Parent=parent; b.Activated:Connect(callback)
    return b
end
local hud=Instance.new("Frame"); hud.Size=UDim2.fromOffset(365,104); hud.Position=UDim2.fromOffset(14,12); decorate(hud); hud.BackgroundTransparency=0.18; hud.Parent=gui
local hudText=label(hud,"STARFALL RNG\nLoading player data...",94); hudText.Position=UDim2.fromOffset(10,5)
local notice=label(gui,"Walk towards the slimes: your starter companion fights automatically.",62)
notice.Size=UDim2.new(0.85,0,0,62); notice.AnchorPoint=Vector2.new(0.5,1)
notice.Position=UDim2.new(0.5,0,1,-79); notice.TextXAlignment=Enum.TextXAlignment.Center
notice.TextStrokeTransparency=0.25
local function notify(message)
    if not message or message=="" then return end
    notice.Text=message
end
local panel=Instance.new("Frame"); panel.Size=UDim2.fromOffset(660,470)
panel.AnchorPoint=Vector2.new(0.5,0.5); panel.Position=UDim2.fromScale(0.5,0.5)
decorate(panel); panel.Visible=false; panel.Parent=gui
local header=label(panel,"",40); header.Position=UDim2.fromOffset(18,8)
local close=button(panel,"X",function() panel.Visible=false; panelKind=nil end)
close.Size=UDim2.fromOffset(35,34); close.Position=UDim2.new(1,-47,0,9)
local scroll=Instance.new("ScrollingFrame"); scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
scroll.Position=UDim2.fromOffset(14,56); scroll.Size=UDim2.new(1,-24,1,-66)
scroll.ScrollBarThickness=6; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.CanvasSize=UDim2.new(); scroll.Parent=panel
local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,8); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=scroll
local function clear()
    for _,child in ipairs(scroll:GetChildren()) do if child~=layout then child:Destroy() end end
    scroll.CanvasPosition=Vector2.zero
end
local function updateHUD()
    if not state then return end
    local unit=Characters[state.Equipped]
    hudText.Text=string.format("STARFALL RNG  |  World %d\nCoins %d  •  Summons %d  •  Kills %d\nLuck weight +%.0f%%  |  Auto-combat %s\n%s  •  %s",state.World,state.Coins,state.Rolls,state.Kills,state.LuckBonus*100,state.AutoCombat and "ON" or "OFF",unit and unit.Name or "No companion",state.DataMode or "Loading")
end
perform=function(action,payload)
    local ok,response=pcall(function() return request:InvokeServer(action,payload) end)
    if not ok or not response then notify("Request failed. Check your connection or Studio Output."); return end
    if response.data then state=response.data; updateHUD() end
    notify(response.message)
    if panelKind and panelKind~="Trade" then render(panelKind) end
    return response
end
local function materialText(materials)
    local parts={}
    for _,id in ipairs(Config.TradeItems) do
        if materials[id] and materials[id]>0 then table.insert(parts,id.." x"..materials[id]) end
    end
    return #parts>0 and table.concat(parts,"  |  ") or "Nothing"
end
local function oddsRows(rows,prefix)
    for _,row in ipairs(rows or {}) do
        label(scroll,string.format("%s%s [%s]  %.9f%%",prefix or "",Characters[row.Id].Name,row.Rarity,row.Probability*100),32)
    end
end
local function tradeAction(action,items,userId)
    return perform("Trade",{Action=action,Items=items,UserId=userId,Id=tradeState and tradeState.Id,Version=tradeState and tradeState.Version})
end
render=function(kind)
    panelKind=kind; panel.Visible=true; header.Text=string.upper(kind); clear()
    if not state then label(scroll,"Player data is loading."); return end
    if kind=="Inventory" then
        label(scroll,"Owned characters are stacked. Equip one companion; duplicates add summon XP.",42)
        local ids={}
        for id in pairs(state.Inventory) do table.insert(ids,id) end
        table.sort(ids,function(a,b)
            local da=Rules.damage(Characters[a],Rarities[Characters[a].Rarity],state.UnitXP[a])
            local db=Rules.damage(Characters[b],Rarities[Characters[b].Rarity],state.UnitXP[b])
            if da==db then return a<b end
            return da>db
        end)
        for _,id in ipairs(ids) do
            local c=Characters[id]; local r=Rarities[c.Rarity]
            button(scroll,string.format("%s%s • %s • Lv %d • %d damage • x%d",id==state.Equipped and "EQUIPPED / " or "",c.Name,c.Rarity,Rules.level(state.UnitXP[id]),Rules.damage(c,r,state.UnitXP[id]),state.Inventory[id]),function() perform("Equip",id) end,Color3.fromRGB(r.Color[1],r.Color[2],r.Color[3]):Lerp(background,0.67))
        end
    elseif kind=="Craft" then
        label(scroll,"Materials: "..materialText(state.Materials),60)
        label(scroll,"Craft at the physical workbench. Charm tiers are permanent and can be crafted once each.",46)
        for _,id in ipairs({"LuckyCharm1","LuckyCharm2","LuckyCharm3","LuckPotion","CharmToken"}) do
            local recipe=Recipes[id]
            local desc=recipe.Name.."  /  "..materialText(recipe.Materials)
            if recipe.Tier then desc=desc..string.format("  /  +%.0f%% weight",recipe.LuckBonus*100) end
            button(scroll,desc,function() perform("Craft",id) end)
        end
        button(scroll,"Use earned luck potion (owned "..state.Materials.LuckPotion..") / remaining "..state.PotionRemaining.."s",function() perform("Use","LuckPotion") end)
        button(scroll,"Bind an unbound sigil permanently (owned "..state.Materials.CharmToken..")",function() perform("Use","CharmToken") end)
    elseif kind=="Odds" then
        label(scroll,"Actual current odds per character. Independent rolls, NO pity. Luck boosts Rare+ weights; probabilities are normalized.",62)
        oddsRows(state.Odds)
        label(scroll,"Percentages are rounded; displayed totals may not equal exactly 100%. No purchase guarantees a rare character.",50)
    elseif kind=="Quests" then
        label(scroll,"Earn free rewards through play. Defeat the World 1 boss to unlock the portal.",42)
        for _,q in ipairs(state.Quests) do
            button(scroll,string.format("%s / %d of %d / +%d coins / %s",q.Name,math.min(q.Progress,q.Goal),q.Goal,q.Coins,q.Claimed and "CLAIMED" or "Claim"),function() perform("Claim",q.Id) end)
        end
    elseif kind=="Shop" then
        label(scroll,not state.Shop.Enabled and "Robux purchases are OFF. Product IDs and launch checks must be configured first." or (state.Shop.Allowed and "Optional paid luck. Roblox shows the final price before confirming." or "Paid luck is unavailable for this account. Earned rolls and crafting remain available."),60)
        label(scroll,"Permanent pass: +50% Rare+ weight. Potion: +100% Rare+ weight for 10 minutes; duration stacks, strength does not. No guaranteed rarity.",65)
        label(scroll,"Odds details / current -> with pass -> with potion",34)
        for i,row in ipairs(state.Odds) do
            label(scroll,string.format("%s: %.9f%% -> %.9f%% -> %.9f%%",Characters[row.Id].Name,row.Probability*100,state.PassOdds[i].Probability*100,state.PotionOdds[i].Probability*100),38)
        end
        label(scroll,"Percentages rounded; displayed totals may not equal exactly 100%.",34)
        if state.Shop.Allowed and state.Shop.PassAvailable and not state.Shop.OwnsPass then button(scroll,"Review permanent-luck purchase",function() perform("Purchase","Pass") end) end
        if state.Shop.Allowed and state.Shop.PotionAvailable then button(scroll,"Review luck-potion purchase",function() perform("Purchase","Potion") end) end
        button(scroll,"Use purchased potion (owned "..state.PaidPotions..")",function() perform("Use","PaidPotion") end)
    elseif kind=="Trade" then
        if not state.TradingAllowed then label(scroll,"Live trading is disabled. This build supports session-only two-player Studio trades, not durable cash-item transfers.",90); return end
        label(scroll,"STUDIO TEST / both players must stand at the same trading arch. No paid items, characters, Robux or activated upgrades.",60)
        if not tradeState or tradeState.Stage=="Closed" then
            label(scroll,"Invite another player from this server:",35)
            for _,other in ipairs(Players:GetPlayers()) do
                if other~=player then button(scroll,other.Name,function() tradeAction("Invite",nil,other.UserId) end) end
            end
            label(scroll,"Use Studio's two-player server test to test trading.",36)
            return
        end
        label(scroll,tradeState.Partner.." / "..tradeState.Stage.." / "..tradeState.Message,60)
        label(scroll,"THEIR OFFER: "..materialText(tradeState.TheirOffer or {}),60)
        label(scroll,"YOUR OFFER: "..materialText(tradeState.Offer or {}),60)
        if tradeState.Stage=="Invited" then
            button(scroll,"Accept invitation",function() tradeAction("Join") end)
        else
            local fields={}
            for _,id in ipairs(Config.TradeItems) do
                local row=Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,-16,0,34); row.Parent=scroll
                local t=label(row,id.." (owned "..(state.Materials[id] or 0)..")",34); t.Size=UDim2.new(0.7,0,1,0)
                local box=Instance.new("TextBox"); box.Size=UDim2.new(0.25,0,1,0); box.Position=UDim2.fromScale(0.73,0)
                box.Text=tostring((tradeState.Offer or {})[id] or 0); box.TextSize=16; box.TextColor3=textColor
                box.ClearTextOnFocus=false; decorate(box); box.BackgroundColor3=Color3.fromRGB(54,69,92); box.Parent=row
                fields[id]=box
            end
            button(scroll,"Update my offer (resets BOTH approvals)",function()
                local items={}
                for id,box in pairs(fields) do items[id]=tonumber(box.Text) or -1 end
                tradeAction("Offer",items)
            end)
            button(scroll,tradeState.Ready and "Ready / waiting for partner" or "Ready: review my offer",function() tradeAction("Ready") end)
            if tradeState.Stage=="Confirm" then button(scroll,"FINAL CONFIRM / review offers, then wait 3 seconds",function() tradeAction("Confirm") end) end
        end
        button(scroll,"Cancel trade",function() tradeAction("Cancel") end)
    end
end
local bar=Instance.new("Frame"); bar.Size=UDim2.fromOffset(650,44); bar.AnchorPoint=Vector2.new(0.5,1)
bar.Position=UDim2.new(0.5,0,1,-20); bar.BackgroundTransparency=1; bar.Parent=gui
for i,item in ipairs({"Inventory","Odds","Quests","Craft","Trade","Auto"}) do
    local b=button(bar,item,function()
        if item=="Auto" then if state then perform("Auto",not state.AutoCombat) end
        elseif panelKind==item then panel.Visible=false; panelKind=nil
        else render(item) end
    end)
    b.Size=UDim2.fromOffset(101,42); b.Position=UDim2.fromOffset((i-1)*109,0)
end
local scales={}
for _,frame in ipairs({hud,panel,bar}) do local scale=Instance.new("UIScale"); scale.Parent=frame; scales[#scales+1]=scale end
local function resize()
    local camera=workspace.CurrentCamera
    if not camera then return end
    local size=camera.ViewportSize
    local factor=math.min(1,(size.X-20)/680,(size.Y-65)/490)
    for _,scale in ipairs(scales) do scale.Scale=math.max(0.35,factor) end
end
resize()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
Input.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.B then render("Inventory") end
end)
remotes.State.OnClientEvent:Connect(function(data,message)
    if data then
        state=data; updateHUD()
        -- Keep open odds/purchase previews fresh when boosts expire; preserve scroll.
        if panelKind=="Odds" or panelKind=="Shop" then
            local position=scroll.CanvasPosition
            render(panelKind)
            scroll.CanvasPosition=position
        end
    end
    notify(message)
end)
remotes.OpenPanel.OnClientEvent:Connect(function(kind) render(kind) end)
remotes.Trade.OnClientEvent:Connect(function(data)
    tradeState=data; notify(data.Message); render("Trade")
end)
local fxFolder=Instance.new("Folder"); fxFolder.Name="AnimeRNGLocalEffects"; fxFolder.Parent=workspace
local function fxPart(size,cf,tint)
    local p=Instance.new("Part"); p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
    p.Size=size; p.CFrame=cf; p.Color=tint; p.Material=Enum.Material.Neon; p.Parent=fxFolder
    return p
end
remotes.Effects.OnClientEvent:Connect(function(info)
    local camera=workspace.CurrentCamera
    if not camera or (camera.CFrame.Position-info.Position).Magnitude>220 then return end
    local rgb=info.Color or {140,190,255}; local tint=Color3.fromRGB(rgb[1],rgb[2],rgb[3])
    if info.Kind=="Slam" then
        local p=fxPart(Vector3.new(0.2,info.Radius*2,info.Radius*2),CFrame.new(info.Position)*CFrame.Angles(0,0,math.pi/2),tint)
        p.Shape=Enum.PartType.Cylinder; p.Transparency=0.65
        Tween:Create(p,TweenInfo.new(info.Duration),{Transparency=0.2}):Play()
        Debris:AddItem(p,info.Duration+0.1)
        return
    end
    if info.From then
        local length=(info.Position-info.From).Magnitude
        if length>0.1 then
            local p=fxPart(Vector3.new(0.15,0.15,length),CFrame.lookAt((info.From+info.Position)/2,info.Position),tint)
            Tween:Create(p,TweenInfo.new(0.25),{Transparency=1}):Play(); Debris:AddItem(p,0.3)
        end
    end
    local p=fxPart(Vector3.new(0.6,0.6,0.6),CFrame.new(info.Position),tint); p.Shape=Enum.PartType.Ball
    local big=info.Kind=="Summon" and 8 or (info.Kind=="Skill" and 5 or 2.5)
    Tween:Create(p,TweenInfo.new(0.45),{Size=Vector3.new(big,big,big),Transparency=1}):Play(); Debris:AddItem(p,0.5)
    if info.Amount then
        local anchor=fxPart(Vector3.new(0.1,0.1,0.1),CFrame.new(info.Position+Vector3.new(0,2,0)),tint); anchor.Transparency=1
        local billboard=Instance.new("BillboardGui"); billboard.Size=UDim2.fromOffset(140,40); billboard.Adornee=anchor; billboard.AlwaysOnTop=true; billboard.Parent=anchor
        local text=label(billboard,tostring(info.Amount),40); text.TextColor3=tint; text.TextSize=22; text.TextStrokeTransparency=0.2; text.TextXAlignment=Enum.TextXAlignment.Center
        Tween:Create(anchor,TweenInfo.new(0.7),{CFrame=anchor.CFrame*CFrame.new(0,3,0)}):Play()
        Tween:Create(text,TweenInfo.new(0.7),{TextTransparency=1,TextStrokeTransparency=1}):Play(); Debris:AddItem(anchor,0.8)
    end
end)
task.spawn(function()
    for _=1,20 do
        local response=perform("Get")
        if response and response.data then return end
        task.wait(1)
    end
    notify("Player data is still loading. Check server Output for errors.")
end)

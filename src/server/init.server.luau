local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Shared=RS:WaitForChild("Shared")
local Config=require(Shared.GameConfig)
local Rules=require(Shared.Rules)
local Characters=require(Shared.CharacterDatabase)
local Rarities=require(Shared.RarityConfig)
local Data=require(script.Services.DataService)
local RNG=require(script.Services.RNGService)
local Craft=require(script.Services.CraftingService)
local World=require(script.Services.WorldService)
local Monsters=require(script.Services.MonsterService)
local Companions=require(script.Services.CompanionService)
local Purchase=require(script.Services.PurchaseService)
local Trade=require(script.Services.TradingService)

local old=RS:FindFirstChild("AnimeRNGRemotes")
if old then old:Destroy() end
local remotes=Instance.new("Folder"); remotes.Name="AnimeRNGRemotes"; remotes.Parent=RS
local function remote(class,name)
    local r=Instance.new(class); r.Name=name; r.Parent=remotes; return r
end
local request=remote("RemoteFunction","Request")
local stateEvent=remote("RemoteEvent","State")
local effects=remote("RemoteEvent","Effects")
local openPanel=remote("RemoteEvent","OpenPanel")
local tradeEvent=remote("RemoteEvent","Trade")
local clocks,buckets,joining={},{},{}
local function snapshot(p)
    local d=Data:Get(p)
    if not d then return nil end
    local bonus=Purchase:Bonus(p,d)
    local shop=Purchase:Status(p)
    local activePotion=d.PotionUntil>os.time() or (shop.Allowed and d.PaidPotionUntil>os.time())
    local quests={}
    for _,q in ipairs(Config.Quests) do
        table.insert(quests,{Id=q.Id,Name=q.Name,Progress=d[q.Stat] or 0,Goal=q.Goal,Claimed=d.Claimed[q.Id]==true,Coins=q.Coins})
    end
    return {Coins=d.Coins,Rolls=d.Rolls,Kills=d.Kills,Inventory=Rules.copy(d.Inventory),Equipped=d.Equipped,
        Materials=Rules.copy(d.Materials),UnitXP=Rules.copy(d.UnitXP),LuckBonus=bonus,CharmTier=d.CharmTier,
        PermanentLuck=d.PermanentLuck,UnlockedWorld=d.UnlockedWorld,World=p:GetAttribute("World") or 1,
        AutoCombat=p:GetAttribute("AutoCombat")~=false,Odds=RNG:Odds(bonus),Quests=quests,
        DataMode=p:GetAttribute("DataMode"),PotionRemaining=math.max(0,d.PotionUntil-os.time()),
        PaidPotions=d.PaidPotions,PaidPotionRemaining=math.max(0,d.PaidPotionUntil-os.time()),Shop=shop,
        PassOdds=RNG:Odds(bonus+(shop.OwnsPass and 0 or Config.PaidPassBonus)),
        PotionOdds=RNG:Odds(bonus+(activePotion and 0 or Config.PotionBonus)),TradingAllowed=Trade:Allowed()}
end
local function push(p,message)
    if p.Parent then stateEvent:FireClient(p,snapshot(p),message) end
end
local function cooldown(p,key,seconds)
    clocks[p]=clocks[p] or {}
    local now=os.clock()
    if now<(clocks[p][key] or 0) then return false end
    clocks[p][key]=now+seconds
    return true
end
local function station(p,name)
    local zone=p:GetAttribute("World") or 1
    local stations=World.Stations[zone]
    return stations and World:Near(p,stations[name],15)
end
local function act(p,action,payload)
    if action=="Get" then return true,"" end
    if not Data:Writable(p) then return false,"Player data is loading or saving. Try again shortly." end
    local d=Data:Get(p)
    if action=="Roll" then
        if not station(p,"Summon") then return false,"Walk to the summon altar and press E." end
        if not cooldown(p,"Roll",Config.RollCooldown) then return false,"Summon is cooling down." end
        if d.Coins<Config.RollCost then return false,"Earn coins by fighting monsters or claiming quests." end
        local id,rarity=RNG:Roll(Purchase:Bonus(p,d))
        d.Coins=d.Coins-Config.RollCost; d.Rolls=d.Rolls+1
        d.Inventory[id]=(d.Inventory[id] or 0)+1
        d.UnitXP[id]=(d.UnitXP[id] or 0)+5
        local current=Characters[d.Equipped]
        if not current or Rules.damage(Characters[id],Rarities[rarity],d.UnitXP[id])>Rules.damage(current,Rarities[current.Rarity],d.UnitXP[d.Equipped]) then d.Equipped=id end
        local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if root then effects:FireAllClients({Kind="Summon",Position=root.Position,Color=Rarities[rarity].Color}) end
        return true,"Summoned "..Characters[id].Name.." ["..rarity.."]. Your strongest unit stays equipped."
    elseif action=="Equip" then
        if type(payload)~="string" or not Characters[payload] or not d.Inventory[payload] then return false,"You do not own that character." end
        d.Equipped=payload; return true,"Equipped "..Characters[payload].Name
    elseif action=="Craft" then
        if not station(p,"Craft") then return false,"Stand beside the crafting workbench." end
        if not cooldown(p,"Craft",0.5) then return false,"Crafting is cooling down." end
        return Craft:Craft(d,payload)
    elseif action=="Use" then
        if payload=="PaidPotion" then return Purchase:UsePotion(p,d) end
        return Craft:Use(d,payload)
    elseif action=="Auto" then
        if type(payload)~="boolean" then return false,"Invalid setting" end
        p:SetAttribute("AutoCombat",payload); return true,payload and "Companion auto-combat ON" or "Companion auto-combat OFF"
    elseif action=="Claim" then
        for _,q in ipairs(Config.Quests) do
            if q.Id==payload then
                if d.Claimed[q.Id] or (d[q.Stat] or 0)<q.Goal then return false,"Quest is not ready or was already claimed." end
                d.Claimed[q.Id]=true; d.Coins=d.Coins+q.Coins
                for _,mat in ipairs({"Essence","Crystal","BossCore"}) do d.Materials[mat]=d.Materials[mat]+(q[mat] or 0) end
                return true,"Quest rewards claimed."
            end
        end
        return false,"Unknown quest"
    elseif action=="Trade" then
        return Trade:Request(p,payload)
    elseif action=="Purchase" then
        if not station(p,"Shop") or not cooldown(p,"Purchase",3) then return false,"Stand at the shop and wait before trying again." end
        return Purchase:Prompt(p,payload)
    elseif action=="Travel" then
        if not station(p,"Portal") then return false,"Stand beside the portal." end
        local zone=(p:GetAttribute("World") or 1)==1 and 2 or 1
        if zone>d.UnlockedWorld then return false,"Defeat the Void Devourer in World 1 to unlock World 2." end
        Trade:Cancel(p,"Travel cancelled the trade.")
        World:Teleport(p,zone); return true,"Entered World "..zone
    end
    return false,"Unknown action"
end
local function execute(p,action,payload)
    if type(action)~="string" or #action>24 then return {ok=false,message="Invalid action"} end
    local b=buckets[p] or {Tokens=12,Time=os.clock()}; buckets[p]=b
    local now=os.clock(); b.Tokens=math.min(12,b.Tokens+(now-b.Time)*6); b.Time=now
    if b.Tokens<1 then return {ok=false,message="Too many requests. Please wait."} end
    b.Tokens=b.Tokens-1
    local success,ok,message=pcall(act,p,action,payload)
    if not success then warn("[AnimeRNG] "..action..": "..tostring(ok)); return {ok=false,message="Action failed; see server Output."} end
    return {ok=ok,message=message,data=snapshot(p)}
end
request.OnServerInvoke=execute
World:Build(function(p,kind)
    if kind=="Summon" or kind=="Portal" then
        local response=execute(p,kind=="Summon" and "Roll" or "Travel")
        push(p,response.message)
    else
        if cooldown(p,"Panel",0.5) then openPanel:FireClient(p,kind); push(p) end
    end
end)
Trade:Init(Data,World,tradeEvent,push)
Purchase:Init(Data,push)
Monsters:Init(World,function(s,killer)
    local total=0
    for _,c in pairs(s.Contributors) do total=total+c.Amount end
    for player,c in pairs(s.Contributors) do
        local hrp=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if player.Parent and hrp and os.clock()-c.Time<45 and (hrp.Position-s.Home).Magnitude<90 and (c.Amount/total>=0.05 or player==killer) then
            local share=c.Amount/total
            task.spawn(function()
                local deadline=os.clock()+5
                while player.Parent and not Data:Writable(player) and os.clock()<deadline do task.wait(0.1) end
                if not Data:Writable(player) then return end
                local d=Data:Get(player)
                local multiplier=s.Marker.World==2 and 3 or 1
                local coins=math.max(1,math.floor(s.Config.RewardCoins*multiplier*share))
                d.Coins=d.Coins+coins; d.Kills=d.Kills+1
                for mat,n in pairs(s.Config.Drops) do d.Materials[mat]=(d.Materials[mat] or 0)+math.max(1,math.floor(n*multiplier*share)) end
                d.UnitXP[d.Equipped]=(d.UnitXP[d.Equipped] or 0)+math.max(1,math.floor(s.Config.XP*share))
                if s.Marker.Id=="WorldBoss" then d.BossKills=d.BossKills+1; d.UnlockedWorld=2 end
                push(player,s.Config.Name.." defeated: +"..coins.." coins + materials"..(s.Marker.Id=="WorldBoss" and " / World 2 unlocked!" or ""))
            end)
        end
    end
end,effects)
local function joined(p)
    if joining[p] then return end
    joining[p]=true
    p:SetAttribute("World",1); p:SetAttribute("AutoCombat",true)
    p.RespawnLocation=World.Spawns[1]
    local function spawned(char)
        local hrp=char:WaitForChild("HumanoidRootPart",10)
        if not hrp or p.Character~=char then return end
        World:Teleport(p,1)
        local d=Data:Get(p)
        if d then Companions:Spawn(p,d.Equipped) end
    end
    p.CharacterAdded:Connect(spawned)
    if p.Character then task.spawn(spawned,p.Character) end
    local d=Data:Load(p)
    if not d then return end
    if p.Character then Companions:Spawn(p,d.Equipped) end
    task.spawn(function() Purchase:Load(p); push(p) end)
    push(p,"Welcome! Your starter companion follows you. Walk toward the slimes to fight.")
end
Players.PlayerAdded:Connect(joined)
Players.PlayerRemoving:Connect(function(p)
    Trade:Cancel(p,"Player disconnected."); Companions:Remove(p); Purchase.Cache[p]=nil
    clocks[p]=nil; buckets[p]=nil; joining[p]=nil
    Data:Remove(p)
end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(joined,p) end
local closing=false
local lastState,lastSave,lastTrade=0,0,0
local lastTick=os.clock()
task.spawn(function()
    while not closing do
        task.wait(0.12)
        local now=os.clock(); local dt=math.min(0.3,now-lastTick); lastTick=now
        Monsters:Tick(dt)
        for _,p in ipairs(Players:GetPlayers()) do
            if Data:Writable(p) then Companions:Tick(p,Data:Get(p),Monsters,effects) end
        end
        if now-lastTrade>=1 then Trade:Tick(); lastTrade=now end
        if now-lastState>=2 then for _,p in ipairs(Players:GetPlayers()) do push(p) end; lastState=now end
        if now-lastSave>=Config.AutoSaveSeconds then
            for _,p in ipairs(Players:GetPlayers()) do task.spawn(function() Data:Save(p) end) end
            lastSave=now
        end
    end
end)
game:BindToClose(function()
    closing=true
    local remaining=0
    for _,p in ipairs(Players:GetPlayers()) do
        remaining=remaining+1
        task.spawn(function() Data:Remove(p); remaining=remaining-1 end)
    end
    local deadline=os.clock()+25
    while (remaining>0 or Data:HasSessions()) and os.clock()<deadline do task.wait(0.1) end
end)
print("[AnimeRNG] "..Config.Version.." world ready. Purchases enabled: "..tostring(Config.PurchasesEnabled))

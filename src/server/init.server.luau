local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(script.Services.DataService)
local RNG = require(script.Services.RNGService)
local Craft = require(script.Services.CraftingService)
local World = require(script.Services.WorldService)
local MonsterService = require(script.Services.MonsterService)
local CompanionService = require(script.Services.CompanionService)
local Characters = require(ReplicatedStorage.Shared.CharacterDatabase)
local Monsters = require(ReplicatedStorage.Shared.MonsterDatabase)

World:Build()
MonsterService:SpawnAll()

local old = ReplicatedStorage:FindFirstChild("AnimeRNGRemotes")
if old then old:Destroy() end
local remotes = Instance.new("Folder")
remotes.Name = "AnimeRNGRemotes"
remotes.Parent = ReplicatedStorage
local function remote(name)
    local r = Instance.new("RemoteFunction")
    r.Name = name
    r.Parent = remotes
    return r
end
local Roll = remote("Roll")
local GetData = remote("GetData")
local Attack = remote("Attack")
local CraftLuck = remote("CraftLuck")

Players.PlayerAdded:Connect(function(p)
    local d = Data:Load(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if d.Equipped then CompanionService:Spawn(p,d.Equipped) end
    end)
end)
Players.PlayerRemoving:Connect(function(p)
    CompanionService:Remove(p)
    Data:Remove(p)
end)
game:BindToClose(function()
    for _,p in Players:GetPlayers() do Data:Save(p) end
end)

GetData.OnServerInvoke = function(p) return Data:Get(p) end

Roll.OnServerInvoke = function(p)
    local d = Data:Get(p)
    if not d then return nil end
    local cost = 10
    if d.Coins < cost then return {ok=false,error="Not enough coins"} end
    d.Coins -= cost
    d.Rolls += 1
    local id,rarity = RNG:Roll(d.PermanentLuck)
    table.insert(d.Inventory,id)
    d.Equipped = id
    CompanionService:Spawn(p,id)
    return {ok=true,id=id,rarity=rarity,data=d}
end

CraftLuck.OnServerInvoke = function(p,id)
    local d = Data:Get(p)
    if not d then return {ok=false} end
    local ok,result = Craft:Craft(d,id)
    return {ok=ok,result=result,data=d}
end

Attack.OnServerInvoke = function(p,monsterId)
    local d = Data:Get(p)
    local cfg = Monsters[monsterId]
    if not d or not cfg or not d.Equipped then return {ok=false,error="Invalid attack"} end
    local c = Characters[d.Equipped]
    if not c then return {ok=false} end
    local dead,hp = MonsterService:Damage(monsterId,c.BaseDamage)
    local reward = 0
    if dead then
        reward = cfg.RewardCoins
        d.Coins += reward
        for mat,n in pairs(cfg.Drops) do
            d.Materials[mat] = (d.Materials[mat] or 0) + n
        end
        MonsterService:Respawn(monsterId)
    end
    return {ok=true,dead=dead,hp=hp,damage=c.BaseDamage,reward=reward,data=d}
end

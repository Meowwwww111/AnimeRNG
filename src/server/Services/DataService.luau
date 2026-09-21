local DataStoreService=game:GetService("DataStoreService")
local store=DataStoreService:GetDataStore("AnimeRNG_PlayerData_v1")
local DataService={}
local sessions={}
local function fresh()
 return {Coins=100,Inventory={},Equipped=nil,Materials={Essence=0,Crystal=0,BossCore=0},PermanentLuck=0,Rolls=0}
end
function DataService:Get(player) return sessions[player] end
function DataService:Load(player)
 local ok,data=pcall(function() return store:GetAsync("u_"..player.UserId) end)
 sessions[player]=(ok and data) or fresh()
 return sessions[player]
end
function DataService:Save(player)
 local data=sessions[player]; if not data then return end
 pcall(function() store:UpdateAsync("u_"..player.UserId,function() return data end) end)
end
function DataService:Remove(player) self:Save(player); sessions[player]=nil end
return DataService
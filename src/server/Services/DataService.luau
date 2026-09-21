local DataStoreService = game:GetService("DataStoreService")

local DataService = {}
local sessions = {}
local store = nil

-- DataStoreService:GetDataStore can error in an unpublished Studio place.
-- Keep local development playable and enable persistence automatically once
-- the experience is published/API access is available.
pcall(function()
    store = DataStoreService:GetDataStore("AnimeRNG_PlayerData_v1")
end)

local function fresh()
    return {
        Coins = 100,
        Inventory = {},
        Equipped = nil,
        Materials = {Essence = 0, Crystal = 0, BossCore = 0},
        PermanentLuck = 0,
        Rolls = 0,
    }
end

function DataService:Get(player)
    return sessions[player]
end

function DataService:Load(player)
    local data = nil
    if store then
        local ok, loaded = pcall(function()
            return store:GetAsync("u_" .. player.UserId)
        end)
        if ok then
            data = loaded
        end
    end
    sessions[player] = data or fresh()
    return sessions[player]
end

function DataService:Save(player)
    local data = sessions[player]
    if not data or not store then
        return
    end
    pcall(function()
        store:UpdateAsync("u_" .. player.UserId, function()
            return data
        end)
    end)
end

function DataService:Remove(player)
    self:Save(player)
    sessions[player] = nil
end

return DataService

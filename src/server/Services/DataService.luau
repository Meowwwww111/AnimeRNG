local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.GameConfig)
local Rules=require(Shared.Rules)
local Characters=require(Shared.CharacterDatabase)
local Data={}
local sessions={}
local ephemeral=Run:IsStudio() and not Config.StudioPersistence
local store
if not ephemeral then
    local ok,value=pcall(function()
        return DSS:GetDataStore(Run:IsStudio() and Config.StudioDataStoreName or Config.DataStoreName)
    end)
    if ok then store=value else warn("[AnimeRNG] DataStore unavailable: "..tostring(value)) end
end
local function fence(player,s,message)
    s.Uncertain=true
    warn("[AnimeRNG] "..message)
    if player.Parent then player:Kick("Your save is unavailable. Please rejoin in a few minutes; we have not reset your data.") end
end
function Data:IsEphemeral() return ephemeral end
function Data:Get(player)
    local s=sessions[player]
    return s and not s.Uncertain and s.Data or nil
end
function Data:Writable(player)
    local s=sessions[player]
    if not s or s.Busy or s.Closing or s.Uncertain then return false end
    if not ephemeral and os.time()-s.LastSave>Config.SessionLease-45 then
        fence(player,s,"Save lease safety timeout for "..player.UserId)
        return false
    end
    return true
end
function Data:Load(player)
    if sessions[player] then return self:Get(player) end
    local token=Http:GenerateGUID(false)
    local loaded
    if ephemeral then
        loaded=Rules.migrate(nil,Characters)
    elseif store then
        local success,result=false,nil
        for attempt=1,3 do
            success,result=pcall(function()
                return store:UpdateAsync("u_"..player.UserId,function(old)
                    local lease=type(old)=="table" and old.Session
                    if lease and lease.Token~=token and lease.Expires>os.time() then return nil end
                    local raw=type(old)=="table" and (old.Data or old) or nil
                    return {Data=Rules.migrate(raw,Characters),Session={Token=token,Expires=os.time()+Config.SessionLease}}
                end)
            end)
            if success then break end
            task.wait(attempt)
        end
        if success and result and result.Session.Token==token then loaded=result.Data end
    end
    if not loaded then
        if player.Parent then player:Kick("Could not safely load your save. Please rejoin in a few minutes.") end
        return nil
    end
    sessions[player]={Data=loaded,Token=token,LastSave=os.time(),Busy=false,Closing=false}
    player:SetAttribute("DataMode",ephemeral and "Session only / Studio" or "Persistent")
    if not player.Parent then self:Remove(player); return nil end
    return loaded
end
function Data:Save(player,release)
    local s=sessions[player]
    if not s or s.Uncertain then return false end
    if s.Busy then return false end
    if ephemeral then s.LastSave=os.time(); return true end
    if not store then return false end
    s.Busy=true
    local snapshot=Rules.copy(s.Data)
    local writeId=Http:GenerateGUID(false)
    local ok,result=pcall(function()
        return store:UpdateAsync("u_"..player.UserId,function(old)
            if not old or not old.Session or old.Session.Token~=s.Token then return nil end
            local lease=not release and {Token=s.Token,Expires=os.time()+Config.SessionLease} or nil
            return {Data=snapshot,Session=lease,WriteId=writeId}
        end)
    end)
    s.Busy=false
    if ok and result and result.WriteId==writeId then s.LastSave=os.time(); return true end
    if ok then fence(player,s,"Session ownership lost for "..player.UserId)
    else warn("[AnimeRNG] Save failed; keeping memory, not writing defaults: "..tostring(result)) end
    return false
end
function Data:GrantReceipt(player,purchaseId)
    local s=sessions[player]
    if not s or ephemeral or not store or s.Uncertain then return false end
    if s.Data.Receipts[purchaseId] then return true end
    if not self:Writable(player) then return false end
    s.Busy=true
    local snapshot=Rules.copy(s.Data)
    snapshot.Receipts[purchaseId]=true
    snapshot.PaidPotions=snapshot.PaidPotions+1
    local ok,result=pcall(function()
        return store:UpdateAsync("u_"..player.UserId,function(old)
            if not old or not old.Session or old.Session.Token~=s.Token then return nil end
            if old.Data.Receipts[purchaseId] then return old end
            return {Data=snapshot,Session={Token=s.Token,Expires=os.time()+Config.SessionLease}}
        end)
    end)
    s.Busy=false
    if ok and result and result.Session and result.Session.Token==s.Token and result.Data.Receipts[purchaseId] then
        s.Data=result.Data; s.LastSave=os.time(); return true
    end
    -- An ambiguous network response must never be followed by a stale autosave.
    fence(player,s,"Receipt commit unconfirmed for "..player.UserId)
    return false
end
function Data:Remove(player)
    local s=sessions[player]
    if not s or s.Closing then return end
    s.Closing=true
    local deadline=os.clock()+18
    while s.Busy and os.clock()<deadline do task.wait(0.1) end
    if not s.Busy then
        for attempt=1,3 do
            if self:Save(player,true) then break end
            if s.Uncertain then break end
            task.wait(0.5)
        end
    end
    sessions[player]=nil
end
function Data:HasSessions() return next(sessions)~=nil end
return Data

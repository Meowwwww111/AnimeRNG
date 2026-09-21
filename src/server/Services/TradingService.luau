-- Session-only Studio prototype. Deliberately rejects live trades until durable
-- multi-profile escrow/recovery is implemented and fault-injection tested.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Http=game:GetService("HttpService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Rules=require(Shared.Rules)
local Config=require(Shared.GameConfig)
local Trade={Active={}}
function Trade:Init(data,world,event,push)
    self.Data=data; self.World=world; self.Event=event; self.Push=push
end
function Trade:Allowed()
    return Run:IsStudio() and self.Data:IsEphemeral()
end
function Trade:AtBooth(player)
    local zone=player:GetAttribute("World") or 1
    return self.World:Near(player,self.World.Stations[zone].Trade,18)
end
function Trade:Publish(t,message)
    for _,p in ipairs(t.Players) do
        if p.Parent then
            local other=t.Players[1]==p and t.Players[2] or t.Players[1]
            self.Event:FireClient(p,{Id=t.Id,Version=t.Version,Stage=t.Stage,Partner=other.Name,
                PartnerId=other.UserId,Offer=t.Offers[p],TheirOffer=t.Offers[other],Ready=t.Ready[p] or false,
                TheirReady=t.Ready[other] or false,Confirmed=t.Confirmed[p] or false,Message=message or "",
                Wait=math.max(0,(t.ConfirmAt or 0)-os.clock())})
        end
    end
end
function Trade:Cancel(player,message)
    local t=self.Active[player]
    if not t then return end
    t.Stage="Closed"
    for _,p in ipairs(t.Players) do self.Active[p]=nil end
    self:Publish(t,message or "Trade cancelled.")
end
function Trade:Request(player,payload)
    if not self:Allowed() then return false,"Trading is a Studio session-only test. Live trading is disabled to protect saved items." end
    if not self:AtBooth(player) then return false,"Stand beside the trading arch." end
    if type(payload)~="table" then return false,"Invalid trade request" end
    if payload.Action=="Invite" then
        if not Rules.integer(payload.UserId,-1000000000,100000000000) or payload.UserId==player.UserId then return false,"Choose another player." end
        local other=Players:GetPlayerByUserId(payload.UserId)
        if not other or not self:AtBooth(other) or other:GetAttribute("World")~=player:GetAttribute("World") then return false,"Both players must be at the same trading arch." end
        if self.Active[player] or self.Active[other] then return false,"A player already has a trade open." end
        if not self.Data:Writable(player) or not self.Data:Writable(other) then return false,"Player data is not ready." end
        local t={Id=Http:GenerateGUID(false),Players={player,other},Offers={[player]={},[other]={}},Ready={},Confirmed={},Version=1,Stage="Invited",Inviter=player,Expires=os.clock()+120}
        self.Active[player]=t; self.Active[other]=t; self:Publish(t,player.Name.." invited you to trade.")
        return true,"Trade invitation sent."
    end
    local t=self.Active[player]
    if not t or payload.Id~=t.Id then return false,"Trade no longer exists." end
    if payload.Action=="Cancel" then self:Cancel(player); return true,"Cancelled" end
    if payload.Action=="Join" and t.Stage=="Invited" and player~=t.Inviter then
        t.Stage="Editing"; t.Expires=os.clock()+180; self:Publish(t); return true,"Edit your offer."
    end
    if t.Stage=="Invited" then return false,"Waiting for your partner to join." end
    if payload.Version~=t.Version then return false,"Offer changed; review it again." end
    if payload.Action=="Offer" then
        local data=self.Data:Get(player)
        if not data or not Rules.offer(payload.Items,data.Materials,Config.TradeItems) then return false,"Invalid quantities or insufficient materials." end
        t.Offers[player]=Rules.copy(payload.Items); t.Ready={}; t.Confirmed={}; t.Stage="Editing"
        t.Version=t.Version+1; t.ConfirmAt=nil; self:Publish(t,"Offer changed; both approvals reset.")
        return true,"Offer updated."
    elseif payload.Action=="Ready" then
        t.Ready[player]=true
        if t.Ready[t.Players[1]] and t.Ready[t.Players[2]] then t.Stage="Confirm"; t.ConfirmAt=os.clock()+3 end
        self:Publish(t,"Review both offers before final confirmation.")
        return true,"Ready."
    elseif payload.Action=="Confirm" then
        if t.Stage~="Confirm" or os.clock()<t.ConfirmAt then return false,"Wait at least 3 seconds and review both offers." end
        t.Confirmed[player]=true
        local a,b=t.Players[1],t.Players[2]
        if t.Confirmed[a] and t.Confirmed[b] then
            if not self:AtBooth(a) or not self:AtBooth(b) or not self.Data:Writable(a) or not self.Data:Writable(b) then self:Cancel(player,"Trade conditions changed."); return false,"Trade cancelled." end
            local da,db=self.Data:Get(a),self.Data:Get(b)
            if not Rules.exchange(da.Materials,db.Materials,t.Offers[a],t.Offers[b],Config.TradeItems) then self:Cancel(player,"Items changed or offers were empty."); return false,"Trade cancelled." end
            print("[AnimeRNG trade / Studio] "..t.Id.." "..a.UserId.." <-> "..b.UserId)
            self:Cancel(player,"Trade completed. Session-only Studio items exchanged.")
            self.Push(a); self.Push(b)
            return true,"Trade complete."
        end
        self:Publish(t,"Waiting for the other final confirmation.")
        return true,"Confirmed."
    end
    return false,"Invalid trade action."
end
function Trade:Tick()
    local seen={}
    for player,t in pairs(self.Active) do
        if not seen[t] then
            seen[t]=true
            if os.clock()>t.Expires or not t.Players[1].Parent or not t.Players[2].Parent or not self:AtBooth(t.Players[1]) or not self:AtBooth(t.Players[2]) then self:Cancel(player,"Trade expired or a player left the booth.") end
        end
    end
end
return Trade

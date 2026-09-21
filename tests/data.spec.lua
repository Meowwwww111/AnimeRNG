-- Mocked service tests under Lua 5.4; these are NOT Roblox integration tests.
local Rules=require("Rules")
local count=0
local function check(v,msg) count=count+1; assert(v,msg) end
local backing,failWrite,foreign={},false,false
local fakeStore={}
function fakeStore:UpdateAsync(key,fn)
    if failWrite then error("simulated network outage") end
    local new=fn(Rules.copy(backing[key]))
    if new~=nil then backing[key]=Rules.copy(new) end
    return Rules.copy(new)
end
local serial=0
local services={
    ReplicatedStorage={Shared={GameConfig="GameConfig",Rules="Rules",CharacterDatabase="CharacterDatabase"}},
    RunService={IsStudio=function() return false end},
    HttpService={GenerateGUID=function() serial=serial+1; return "test-token-"..serial end},
    DataStoreService={GetDataStore=function() return fakeStore end},
}
game={GetService=function(_,name) return services[name] end}
task={wait=function() end}
warn=function() end
local function player(id)
    return {UserId=id,Parent=true,SetAttribute=function() end,Kick=function(p,msg) p.Kicked=msg end}
end
local Data=dofile("src/server/Services/DataService.luau")
local p=player(1)
local d=Data:Load(p)
check(d~=nil and d.Coins==100,"Fresh persistent profile")
d.Coins=350
check(Data:Save(p),"Save")
check(backing.u_1.Data.Coins==350,"Saved correct snapshot")
check(Data:GrantReceipt(p,"purchase-1"),"Receipt granted")
check(Data:Get(p).PaidPotions==1,"Receipt grants exactly one potion")
check(Data:GrantReceipt(p,"purchase-1"),"Duplicate receipt acknowledged")
check(Data:Get(p).PaidPotions==1,"Duplicate receipt does not grant twice")
Data:Remove(p)
check(backing.u_1.Session==nil,"Release clears lease")
local p2=player(1)
check(Data:Load(p2).Coins==350,"Rejoin keeps progress")
check(Data:Get(p2).PaidPotions==1,"Rejoin keeps purchase")
local q=player(2)
backing.u_2={Data={Coins=9000},Session={Token="another-server",Expires=os.time()+999}}
check(Data:Load(q)==nil and q.Kicked~=nil,"Foreign active lease blocks load")
check(backing.u_2.Data.Coins==9000,"Locked profile untouched")
failWrite=true
local r=player(3)
backing.u_3={Coins=700,Inventory={"StreetFighter"}}
check(Data:Load(r)==nil,"Read failure never creates a fallback persistent session")
check(backing.u_3.Coins==700,"Read failure never resets saved currency")
check(not Data:Save(p2),"Transient autosave fails cleanly")
check(Data:Get(p2).Coins==350,"Transient autosave preserves memory")
check(not Data:GrantReceipt(p2,"purchase-2"),"Uncertain receipt not acknowledged")
check(p2.Kicked~=nil and not Data:Writable(p2),"Uncertain receipt fences session")
check(not Data:Save(p2),"No stale overwrite after uncertain receipt")
failWrite=false
local legacyPlayer=player(4)
backing.u_4={Coins=500,Inventory={"StormNinja","StormNinja"},Equipped="StormNinja",PermanentLuck=0.5}
local migrated=Data:Load(legacyPlayer)
check(migrated.Inventory.StormNinja==2 and migrated.Coins==500,"Legacy persistent migration")
check(migrated.PermanentLuck==0.5,"Legacy luck preserved")
print("PASS: "..count.." mocked persistence checks")

local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rarity=require(ReplicatedStorage.Shared.RarityConfig)
local Characters=require(ReplicatedStorage.Shared.CharacterDatabase)
local RNG={}
local random=Random.new()
local function rarityRoll(luck)
 local total=0; local weights={}
 for name,cfg in pairs(Rarity) do
  local tierBoost=(name=="Common" or name=="Uncommon") and 1 or math.max(1,1+luck)
  local w=cfg.Weight*tierBoost; weights[name]=w; total+=w
 end
 local x=random:NextNumber(0,total); local n=0
 for name,w in pairs(weights) do n+=w; if x<=n then return name end end
 return "Common"
end
function RNG:Roll(luck)
 local rarity=rarityRoll(luck or 0)
 local pool={}
 for id,c in pairs(Characters) do if c.Rarity==rarity then table.insert(pool,id) end end
 if #pool==0 then return self:Roll(luck) end
 return pool[random:NextInteger(1,#pool)],rarity
end
return RNG
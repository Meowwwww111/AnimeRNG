local Shared=game:GetService("ReplicatedStorage").Shared
local Rules=require(Shared.Rules)
local Rarities=require(Shared.RarityConfig)
local Characters=require(Shared.CharacterDatabase)
local RNG={}
local random=Random.new()
function RNG:Odds(bonus) return Rules.odds(Rarities,Characters,bonus) end
function RNG:Roll(bonus)
    -- Independent rolls, never a pity counter or manipulated near-miss.
    return Rules.pick(self:Odds(bonus),math.min(random:NextNumber(),1-1e-15))
end
return RNG

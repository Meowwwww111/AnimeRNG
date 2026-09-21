-- Pure deterministic domain rules, shared with the test runner. No client decides rewards.
local Rules = {}
function Rules.integer(n, low, high)
    return type(n)=="number" and n==n and n>=low and n<=high and n%1==0
end
function Rules.copy(value)
    if type(value)~="table" then return value end
    local result={}
    for key, item in pairs(value) do result[key]=Rules.copy(item) end
    return result
end
function Rules.level(xp)
    return math.min(50,1+math.floor(math.sqrt(math.max(0,xp or 0)/50)))
end
function Rules.damage(character, rarity, xp)
    return math.max(1,math.floor(character.BaseDamage*rarity.DamageMultiplier*(1+0.06*(Rules.level(xp)-1))))
end
function Rules.odds(rarities, characters, bonus)
    bonus=math.max(0,math.min(100,tonumber(bonus) or 0))
    local counts, total, rows = {},0,{}
    for _, c in pairs(characters) do counts[c.Rarity]=(counts[c.Rarity] or 0)+1 end
    for name, r in pairs(rarities) do
        if counts[name] then total=total+r.Weight*(r.Rank>=3 and (1+bonus) or 1) end
    end
    assert(total>0,"No obtainable characters")
    for id,c in pairs(characters) do
        local r=rarities[c.Rarity]
        local chance=r.Weight*(r.Rank>=3 and (1+bonus) or 1)/total/counts[c.Rarity]
        table.insert(rows,{Id=id,Rarity=c.Rarity,Rank=r.Rank,Probability=chance})
    end
    table.sort(rows,function(a,b)
        if a.Rank==b.Rank then return a.Id<b.Id end
        return a.Rank<b.Rank
    end)
    return rows
end
function Rules.pick(rows, sample)
    assert(type(sample)=="number" and sample>=0 and sample<1,"Invalid RNG sample")
    local sum=0
    for _,r in ipairs(rows) do
        sum=sum+r.Probability
        if sample<sum then return r.Id,r.Rarity end
    end
    return rows[#rows].Id, rows[#rows].Rarity
end
function Rules.craft(data, recipe)
    if not recipe then return false,"Unknown recipe" end
    if recipe.Tier and recipe.Tier~=(data.CharmTier or 0)+1 then
        return false,"Craft each charm tier once, in order."
    end
    for id,n in pairs(recipe.Materials) do
        if (data.Materials[id] or 0)<n then return false,"Missing "..id end
    end
    for id,n in pairs(recipe.Materials) do data.Materials[id]=data.Materials[id]-n end
    if recipe.Tier then
        data.CharmTier=recipe.Tier
        data.PermanentLuck=data.PermanentLuck+recipe.LuckBonus
    else
        data.Materials[recipe.Item]=(data.Materials[recipe.Item] or 0)+1
    end
    return true,recipe.Name.." crafted"
end
function Rules.offer(offer, balances, allowlist)
    if type(offer)~="table" then return false end
    local allowed={}
    for _,key in ipairs(allowlist) do allowed[key]=true end
    local any=false
    for key,n in pairs(offer) do
        if not allowed[key] or not Rules.integer(n,0,1000000) or n>(balances[key] or 0) then return false end
        if n>0 then any=true end
    end
    return true,any
end
function Rules.exchange(a,b,offerA,offerB,allowlist)
    local okA,anyA=Rules.offer(offerA,a,allowlist)
    local okB,anyB=Rules.offer(offerB,b,allowlist)
    if not okA or not okB or not (anyA or anyB) then return false end
    -- No yield between validation and both in-memory changes.
    for _,id in ipairs(allowlist) do
        local x,y=offerA[id] or 0,offerB[id] or 0
        a[id]=(a[id] or 0)-x+y
        b[id]=(b[id] or 0)-y+x
    end
    return true
end
function Rules.migrate(raw, characters)
    local d=Rules.copy(type(raw)=="table" and raw or {})
    if d.Version~=3 then
        local owned={}
        for _,id in ipairs(d.Inventory or {}) do
            if characters[id] then owned[id]=(owned[id] or 0)+1 end
        end
        d.Inventory=owned
    end
    d.Inventory=d.Inventory or {}
    if next(d.Inventory)==nil then d.Inventory.StreetFighter=1 end
    if not characters[d.Equipped] or not d.Inventory[d.Equipped] then
        d.Equipped=next(d.Inventory)
    end
    d.Version=3
    d.Coins=d.Coins or 100
    d.Rolls=d.Rolls or 0
    d.Kills=d.Kills or 0
    d.BossKills=d.BossKills or 0
    d.PermanentLuck=d.PermanentLuck or 0
    d.CharmTier=d.CharmTier or 0
    d.SigilsUsed=d.SigilsUsed or 0
    d.Materials=d.Materials or {}
    for _,id in ipairs({"Essence","Crystal","BossCore","LuckPotion","CharmToken"}) do d.Materials[id]=d.Materials[id] or 0 end
    d.UnitXP=d.UnitXP or {}
    d.Claimed=d.Claimed or {}
    d.UnlockedWorld=d.UnlockedWorld or 1
    d.PotionUntil=d.PotionUntil or 0
    d.Receipts=d.Receipts or {}
    d.PaidPotions=d.PaidPotions or 0
    d.PaidPotionUntil=d.PaidPotionUntil or 0
    return d
end
return Rules

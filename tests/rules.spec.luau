local Rules=require("../src/shared/Rules")
local Rarities=require("../src/shared/RarityConfig")
local Characters=require("../src/shared/CharacterDatabase")
local Recipes=require("../src/shared/RecipeDatabase")
local Config=require("../src/shared/GameConfig")
local count=0
local function check(value,message)
    count=count+1
    assert(value,message)
end
local rows=Rules.odds(Rarities,Characters,0)
local sum=0
for _,r in ipairs(rows) do
    sum=sum+r.Probability
    check(r.Probability>0,"All characters obtainable")
    if r.Id=="StarbornHero" then check(math.abs(r.Probability-1/200000)<1e-12,"Base Celestial is 1/200000") end
end
check(math.abs(sum-1)<1e-12,"Probabilities sum to one")
check(#rows==10,"Ten original characters")
local high=Rules.odds(Rarities,Characters,5)
local highSum=0
for i,r in ipairs(high) do
    highSum=highSum+r.Probability
    check(r.Rank>=3 and r.Probability>rows[i].Probability or r.Rank<3 and r.Probability<rows[i].Probability,"Luck must favor Rare+")
end
check(math.abs(highSum-1)<1e-12,"Boosted odds normalized")
check(Rules.pick(rows,0)==rows[1].Id,"Lower boundary")
check(Rules.pick(rows,1-1e-12)==rows[#rows].Id,"Upper boundary")
check(not pcall(Rules.pick,rows,1),"Out-of-range sample rejected")
check(not Rules.integer(0/0,0,100),"NaN rejected")
check(not Rules.integer(math.huge,0,100),"Infinity rejected")
check(not Rules.integer(-1,0,100),"Negative rejected")
check(not Rules.integer(0.5,0,100),"Fraction rejected")
local d=Rules.migrate(nil,Characters)
check(d.Inventory.StreetFighter==1 and d.Equipped=="StreetFighter","Free starter prevents coin deadlock")
local legacy=Rules.migrate({Coins=125,Inventory={"StormNinja","StormNinja","StreetFighter"},Equipped="StormNinja",PermanentLuck=0.75},Characters)
check(legacy.Inventory.StormNinja==2,"Legacy duplicate migration")
check(legacy.Equipped=="StormNinja" and legacy.PermanentLuck==0.75 and legacy.Coins==125,"Preserve legacy progression")
check(Rules.migrate(legacy,Characters).Inventory.StormNinja==2,"Migration idempotent")
check(not Rules.craft(d,Recipes.LuckyCharm2),"Cannot skip charm tiers")
check(not Rules.craft(d,Recipes.LuckyCharm1),"Insufficient crafting resources")
check(d.Materials.Essence==0,"Failed craft does not debit")
d.Materials.Essence=10000; d.Materials.Crystal=1000; d.Materials.BossCore=100
check(Rules.craft(d,Recipes.LuckyCharm1),"Craft tier 1")
check(d.Materials.Essence==9900 and d.PermanentLuck==0.25,"Exact crafting debit and bonus")
check(not Rules.craft(d,Recipes.LuckyCharm1),"No unlimited tier-1 stacking")
check(Rules.craft(d,Recipes.LuckyCharm2),"Craft tier 2")
check(Rules.craft(d,Recipes.LuckyCharm3),"Craft tier 3")
check(d.PermanentLuck==1.75,"Three bounded permanent upgrades")
check(Rules.craft(d,Recipes.LuckPotion) and d.Materials.LuckPotion==1,"Crafted potion")
check(Rules.craft(d,Recipes.CharmToken) and d.Materials.CharmToken==1,"Unbound sigil")
local a,b={Essence=50,Crystal=2},{Essence=4,Crystal=20}
check(not Rules.offer({Essence=-1},a,Config.TradeItems),"Negative trade rejected")
check(not Rules.offer({Essence=0/0},a,Config.TradeItems),"NaN trade rejected")
check(not Rules.offer({Essence=51},a,Config.TradeItems),"Overdraw rejected")
check(not Rules.offer({PaidPotion=1},a,Config.TradeItems),"Paid item excluded")
check(not Rules.exchange(a,b,{},{},Config.TradeItems),"Empty trade rejected")
check(not Rules.exchange(a,b,{Essence=100},{Crystal=3},Config.TradeItems),"Invalid trade cannot transfer")
check(a.Essence==50 and b.Crystal==20,"Rejected trade preserves both balances")
check(Rules.exchange(a,b,{Essence=10},{Crystal=3},Config.TradeItems),"Valid exchange")
check(a.Essence==40 and b.Essence==14 and a.Crystal==5 and b.Crystal==17,"Both sides updated correctly")
check(a.Essence+b.Essence==54 and a.Crystal+b.Crystal==22,"Conservation of traded items")
check(Rules.level(0)==1 and Rules.level(50)==2 and Rules.level(1000000000)==50,"Level progression capped")
check(Rules.damage(Characters.StarbornHero,Rarities.Celestial,0)>Rules.damage(Characters.StreetFighter,Rarities.Common,0),"Rarity affects damage")
check(not Config.PurchasesEnabled and Config.LuckPassId==0 and Config.LuckPotionProductId==0,"Paid shop disabled by default")
print("PASS: "..count.." rules checks")

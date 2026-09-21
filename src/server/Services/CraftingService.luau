local Shared=game:GetService("ReplicatedStorage").Shared
local Rules=require(Shared.Rules)
local Recipes=require(Shared.RecipeDatabase)
local Config=require(Shared.GameConfig)
local Craft={}
function Craft:Craft(data,id)
    if type(id)~="string" then return false,"Invalid recipe" end
    return Rules.craft(data,Recipes[id])
end
function Craft:Use(data,id)
    if id=="LuckPotion" then
        if data.Materials.LuckPotion<1 then return false,"Craft a potion first." end
        if data.PotionUntil>os.time()+Config.MaxPotionSeconds-Config.PotionSeconds then return false,"One-hour duration cap reached." end
        data.Materials.LuckPotion=data.Materials.LuckPotion-1
        data.PotionUntil=math.max(os.time(),data.PotionUntil)+Config.PotionSeconds
        return true,"Earned luck potion active for 10 more minutes."
    elseif id=="CharmToken" then
        if data.SigilsUsed>=10 then return false,"Maximum 10 sigils already bound." end
        if data.Materials.CharmToken<1 then return false,"No unbound luck sigil." end
        data.Materials.CharmToken=data.Materials.CharmToken-1
        data.SigilsUsed=data.SigilsUsed+1
        data.PermanentLuck=data.PermanentLuck+0.1
        return true,"Sigil bound: permanent +10% rare-tier weight."
    end
    return false,"Unknown item"
end
return Craft

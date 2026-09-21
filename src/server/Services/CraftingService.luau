local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Recipes=require(ReplicatedStorage.Shared.RecipeDatabase)
local Crafting={}
function Crafting:Craft(data,recipeId)
 local r=Recipes[recipeId]; if not r then return false,"Unknown recipe" end
 for mat,n in pairs(r.Materials) do if (data.Materials[mat] or 0)<n then return false,"Missing "..mat end end
 for mat,n in pairs(r.Materials) do data.Materials[mat]-=n end
 data.PermanentLuck=(data.PermanentLuck or 0)+r.LuckBonus
 return true,data.PermanentLuck
end
return Crafting
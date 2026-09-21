local Players=game:GetService("Players")
local Marketplace=game:GetService("MarketplaceService")
local Policy=game:GetService("PolicyService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.GameConfig)
local Purchase={Cache={}}
function Purchase:Load(player)
    local item={Allowed=false,OwnsPass=false}
    self.Cache[player]=item
    if not Config.PurchasesEnabled then return end
    local ok,info=pcall(function() return Policy:GetPolicyInfoForPlayerAsync(player) end)
    item.Allowed=ok and info.ArePaidRandomItemsRestricted==false
    if item.Allowed and Config.LuckPassId>0 then
        local success,owns=pcall(function() return Marketplace:UserOwnsGamePassAsync(player.UserId,Config.LuckPassId) end)
        item.OwnsPass=success and owns==true
    end
end
function Purchase:Bonus(player,data)
    local unique=0
    for _,n in pairs(data.Inventory) do if n>0 then unique=unique+1 end end
    local bonus=data.PermanentLuck+math.max(0,unique-1)*0.02
    local cached=self.Cache[player]
    if cached and cached.Allowed and cached.OwnsPass then bonus=bonus+Config.PaidPassBonus end
    if data.PotionUntil>os.time() or (cached and cached.Allowed and data.PaidPotionUntil>os.time()) then
        bonus=bonus+Config.PotionBonus
    end
    return math.min(100,math.max(0,bonus))
end
function Purchase:Status(player)
    local c=self.Cache[player]
    return {Enabled=Config.PurchasesEnabled,Allowed=c and c.Allowed==true or false,OwnsPass=c and c.OwnsPass==true or false,
        PassAvailable=Config.PurchasesEnabled and Config.LuckPassId>0,PotionAvailable=Config.PurchasesEnabled and Config.LuckPotionProductId>0}
end
function Purchase:Prompt(player,kind)
    local c=self.Cache[player]
    if not Config.PurchasesEnabled then return false,"Robux shop is disabled until product IDs and release checks are configured." end
    if not c or not c.Allowed then return false,"Paid luck is unavailable for this account." end
    if kind=="Pass" and Config.LuckPassId>0 and not c.OwnsPass then
        Marketplace:PromptGamePassPurchase(player,Config.LuckPassId)
        return true,"Review the Roblox purchase confirmation."
    elseif kind=="Potion" and Config.LuckPotionProductId>0 then
        Marketplace:PromptProductPurchase(player,Config.LuckPotionProductId)
        return true,"Review the Roblox purchase confirmation."
    end
    return false,"Product unavailable or already owned."
end
function Purchase:UsePotion(player,data)
    local c=self.Cache[player]
    if not c or not c.Allowed then return false,"Paid luck is unavailable for this account." end
    if data.PaidPotions<1 then return false,"No purchased potion." end
    if data.PaidPotionUntil>os.time()+Config.MaxPotionSeconds-Config.PotionSeconds then return false,"One-hour duration cap reached." end
    data.PaidPotions=data.PaidPotions-1
    data.PaidPotionUntil=math.max(os.time(),data.PaidPotionUntil)+Config.PotionSeconds
    return true,"Purchased potion activated."
end
function Purchase:Init(data,push)
    Marketplace.ProcessReceipt=function(receipt)
        if Config.LuckPotionProductId<=0 or receipt.ProductId~=Config.LuckPotionProductId then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end
        local player=Players:GetPlayerByUserId(receipt.PlayerId)
        if player and data:GrantReceipt(player,tostring(receipt.PurchaseId)) then
            push(player,"Purchased luck potion delivered to your bag.")
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
    Marketplace.PromptGamePassPurchaseFinished:Connect(function(player,id,purchased)
        if id==Config.LuckPassId and purchased then
            self:Load(player) -- Verify ownership; never trust client completion messages.
            push(player,"Luck-pass ownership refreshed.")
        end
    end)
end
return Purchase

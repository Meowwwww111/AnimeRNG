local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local remotes=ReplicatedStorage:WaitForChild("AnimeRNGRemotes")
local player=Players.LocalPlayer

local gui=Instance.new("ScreenGui"); gui.Name="AnimeRNG"; gui.ResetOnSpawn=false; gui.Parent=player.PlayerGui
local frame=Instance.new("Frame"); frame.Size=UDim2.fromOffset(420,260); frame.Position=UDim2.new(.5,-210,.5,-130); frame.Parent=gui
local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,0,0,45); title.Text="ANIME RNG — MVP"; title.TextScaled=true; title.Parent=frame
local status=Instance.new("TextLabel"); status.Position=UDim2.fromOffset(10,50); status.Size=UDim2.new(1,-20,0,70); status.TextWrapped=true; status.Text="Loading..."; status.Parent=frame
local roll=Instance.new("TextButton"); roll.Position=UDim2.fromOffset(10,130); roll.Size=UDim2.fromOffset(190,50); roll.Text="ROLL (10 coins)"; roll.Parent=frame
local fight=Instance.new("TextButton"); fight.Position=UDim2.fromOffset(220,130); fight.Size=UDim2.fromOffset(190,50); fight.Text="FIGHT SLIME"; fight.Parent=frame
local craft=Instance.new("TextButton"); craft.Position=UDim2.fromOffset(10,195); craft.Size=UDim2.fromOffset(400,45); craft.Text="CRAFT LUCKY CHARM I"; craft.Parent=frame
local function show(d,msg)
 if not d then status.Text=msg or "No data"; return end
 status.Text=string.format("%s\nCoins: %d | Rolls: %d | Permanent Luck: +%.0f%% | Units: %d",msg or "",d.Coins,d.Rolls,(d.PermanentLuck or 0)*100,#d.Inventory)
end
task.spawn(function() show(remotes.GetData:InvokeServer(),"Ready") end)
roll.MouseButton1Click:Connect(function()
 local r=remotes.Roll:InvokeServer()
 if r and r.ok then show(r.data,"Rolled: "..r.id.." ["..r.rarity.."]") else status.Text=(r and r.error) or "Roll failed" end
end)
fight.MouseButton1Click:Connect(function()
 local r=remotes.Attack:InvokeServer("Slime")
 if r and r.ok then show(r.data,string.format("Defeated Slime in %d hits! +%d coins",r.hits,r.reward)) else status.Text=(r and r.error) or "Fight failed" end
end)
craft.MouseButton1Click:Connect(function()
 local r=remotes.CraftLuck:InvokeServer("LuckyCharm1")
 if r and r.ok then show(r.data,"Permanent luck upgraded!") else show(r and r.data,(r and r.result) or "Craft failed") end
end)
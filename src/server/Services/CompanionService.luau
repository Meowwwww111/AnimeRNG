local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Characters = require(ReplicatedStorage.Shared.CharacterDatabase)
local CompanionService = {}
local companions = {}

function CompanionService:Remove(player)
    local c = companions[player]
    if c then c:Destroy(); companions[player] = nil end
end

function CompanionService:Spawn(player, characterId)
    self:Remove(player)
    local cfg = Characters[characterId]
    if not cfg then return end
    local model = Instance.new("Model")
    model.Name = player.Name.."_Companion"
    local root = Instance.new("Part")
    root.Name = "Root"
    root.Size = Vector3.new(3,5,2)
    root.Anchored = true
    root.CanCollide = false
    root.Material = Enum.Material.SmoothPlastic
    root.Parent = model
    model.PrimaryPart = root
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(2.5,2.5,2.5)
    head.Anchored = true
    head.CanCollide = false
    head.Parent = model
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(180,45)
    gui.StudsOffset = Vector3.new(0,4,0)
    gui.AlwaysOnTop = true
    gui.Parent = head
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Text = cfg.Name.." ["..cfg.Rarity.."]"
    label.Parent = gui
    model.Parent = workspace
    companions[player] = model
    task.spawn(function()
        while model.Parent and player.Parent do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local target = hrp.CFrame * CFrame.new(4,1,3)
                root.CFrame = root.CFrame:Lerp(target,0.18)
                head.CFrame = root.CFrame * CFrame.new(0,3.2,0)
            end
            task.wait(0.05)
        end
    end)
end

return CompanionService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Monsters = require(ReplicatedStorage.Shared.MonsterDatabase)
local MonsterService = {}
local live = {}

local function healthGui(root, name, hp)
    local gui = Instance.new("BillboardGui")
    gui.Name = "HealthGui"
    gui.Size = UDim2.fromOffset(180, 55)
    gui.StudsOffset = Vector3.new(0, 5, 0)
    gui.AlwaysOnTop = true
    gui.Parent = root
    local text = Instance.new("TextLabel")
    text.Name = "Text"
    text.Size = UDim2.fromScale(1,1)
    text.BackgroundTransparency = 0.25
    text.TextScaled = true
    text.Text = name.."  "..hp.."/"..hp
    text.Parent = gui
end

local function makeMonster(id, position)
    local cfg = Monsters[id]
    local model = Instance.new("Model")
    model.Name = id
    model:SetAttribute("MonsterId", id)
    model:SetAttribute("MaxHP", cfg.HP)
    model:SetAttribute("HP", cfg.HP)

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = id == "WorldBoss" and Vector3.new(12,12,12) or Vector3.new(5,5,5)
    root.Shape = Enum.PartType.Ball
    root.Position = position + Vector3.new(0, root.Size.Y/2, 0)
    root.Anchored = true
    root.Material = Enum.Material.SmoothPlastic
    root.Color = id == "WorldBoss" and Color3.fromRGB(80,20,110) or Color3.fromRGB(110,70,55)
    root.Parent = model
    model.PrimaryPart = root
    healthGui(root, cfg.Name, cfg.HP)
    model.Parent = workspace.AnimeRNGWorld
    return model
end

function MonsterService:SpawnAll()
    local markers = workspace.AnimeRNGWorld.MonsterSpawns
    for _,marker in ipairs(markers:GetChildren()) do
        live[marker.Name] = makeMonster(marker.Name, marker.Position)
    end
    live.WorldBoss = makeMonster("WorldBoss", Vector3.new(0,1,-90))
end

function MonsterService:Get(id) return live[id] end

function MonsterService:Damage(id, amount)
    local model = live[id]
    if not model or not model.Parent then return false,0 end
    local hp = math.max(0, (model:GetAttribute("HP") or 0) - amount)
    model:SetAttribute("HP", hp)
    local root = model.PrimaryPart
    local gui = root and root:FindFirstChild("HealthGui")
    local cfg = Monsters[id]
    if gui and gui:FindFirstChild("Text") then
        gui.Text.Text = cfg.Name.."  "..math.floor(hp).."/"..cfg.HP
    end
    return hp <= 0, hp
end

function MonsterService:Respawn(id)
    local old = live[id]
    local pos = old and old.PrimaryPart and old.PrimaryPart.Position or Vector3.zero
    if old then old:Destroy() end
    task.delay(5, function()
        if id == "WorldBoss" then
            live[id] = makeMonster(id, Vector3.new(0,1,-90))
        else
            local marker = workspace.AnimeRNGWorld.MonsterSpawns:FindFirstChild(id)
            if marker then live[id] = makeMonster(id, marker.Position) end
        end
    end)
end

return MonsterService
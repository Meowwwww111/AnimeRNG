local WorldService = {}

local function part(parent, name, size, position, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.Material = material or Enum.Material.SmoothPlastic
    p.Parent = parent
    return p
end

local function label(adornee, text)
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(220, 50)
    gui.StudsOffset = Vector3.new(0, 4, 0)
    gui.AlwaysOnTop = true
    gui.Adornee = adornee
    gui.Parent = adornee
    local t = Instance.new("TextLabel")
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundTransparency = 1
    t.Text = text
    t.TextScaled = true
    t.TextStrokeTransparency = 0.3
    t.Parent = gui
end

function WorldService:Build()
    local old = workspace:FindFirstChild("AnimeRNGWorld")
    if old then old:Destroy() end
    local world = Instance.new("Folder")
    world.Name = "AnimeRNGWorld"
    world.Parent = workspace

    local ground = part(world, "World1Ground", Vector3.new(300, 2, 300), Vector3.new(0, -1, 0), Enum.Material.Grass)
    ground.Color = Color3.fromRGB(65, 120, 70)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "World1Spawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Vector3.new(0, 1, 55)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Parent = world

    local summon = part(world, "SummonAltar", Vector3.new(18, 2, 18), Vector3.new(-38, 1, 40), Enum.Material.Neon)
    summon.Color = Color3.fromRGB(120, 70, 200)
    label(summon, "SUMMON ALTAR")

    local craft = part(world, "CraftingStation", Vector3.new(18, 2, 18), Vector3.new(38, 1, 40), Enum.Material.Metal)
    craft.Color = Color3.fromRGB(210, 145, 45)
    label(craft, "LUCK CRAFTING")

    local boss = part(world, "BossArena", Vector3.new(70, 1, 70), Vector3.new(0, 0.5, -90), Enum.Material.Slate)
    boss.Color = Color3.fromRGB(60, 45, 65)
    label(boss, "VOID DEVOURER")

    local monsterFolder = Instance.new("Folder")
    monsterFolder.Name = "MonsterSpawns"
    monsterFolder.Parent = world
    local positions = {
        Vector3.new(-45,1,-5), Vector3.new(-20,1,-25), Vector3.new(15,1,-20),
        Vector3.new(45,1,-5), Vector3.new(0,1,-48),
    }
    local ids = {"Slime","Bandit","Ogre","Demon","Titan"}
    for i,pos in ipairs(positions) do
        local marker = part(monsterFolder, ids[i], Vector3.new(6,0.5,6), pos, Enum.Material.Neon)
        marker.Transparency = 0.35
    end
    return world
end

return WorldService
-- BlizzardSystem: Combines BlizzardSpawner logic and BlizzardUIConfig into one module
-- Now supports named directions ("North", "South", "East", "West", etc.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local BlizzardLocationEvent = ReplicatedStorage:FindFirstChild("BlizzardLocationEvent")

local BlizzardSystem = {}

-- Direction mapping table
BlizzardSystem.DirectionVectors = {
    ["North"] = Vector3.new(0, 0, -1),
    ["South"] = Vector3.new(0, 0, 1),
    ["East"]  = Vector3.new(1, 0, 0),
    ["West"]  = Vector3.new(-1, 0, 0),
    ["Up"]    = Vector3.new(0, 1, 0),
    ["Down"]  = Vector3.new(0, -1, 0),
    ["Northeast"] = Vector3.new(1, 0, -1).Unit,
    ["Northwest"] = Vector3.new(-1, 0, -1).Unit,
    ["Southeast"] = Vector3.new(1, 0, 1).Unit,
    ["Southwest"] = Vector3.new(-1, 0, 1).Unit,
}

function BlizzardSystem:GetDirectionVector(direction)
    if typeof(direction) == "string" then
        local dir = BlizzardSystem.DirectionVectors[direction]
        if dir then
            return dir
        else
            -- Default to East if unknown string
            return Vector3.new(1, 0, 0)
        end
    elseif typeof(direction) == "Vector3" then
        if direction.Magnitude > 0 then
            return direction.Unit
        else
            return Vector3.new(1, 0, 0)
        end
    else
        return Vector3.new(1, 0, 0)
    end
end

-- UI Config Section
BlizzardSystem.MarkerText = "Blizzard Here!"
BlizzardSystem.MarkerColor = Color3.fromRGB(0, 170, 255)
BlizzardSystem.MarkerBackgroundTransparency = 0.3
BlizzardSystem.MarkerSize = UDim2.new(0, 200, 0, 50)
BlizzardSystem.MarkerPosition = UDim2.new(0.5, -100, 0, 40)

function BlizzardSystem:SetMarkerText(text)
    self.MarkerText = text
end

function BlizzardSystem:SetMarkerColor(color)
    self.MarkerColor = color
end

function BlizzardSystem:SetMarkerBackgroundTransparency(trans)
    self.MarkerBackgroundTransparency = trans
end

function BlizzardSystem:SetMarkerSize(size)
    self.MarkerSize = size
end

function BlizzardSystem:SetMarkerPosition(pos)
    self.MarkerPosition = pos
end

function BlizzardSystem:GetMarkerText()
    return self.MarkerText
end

function BlizzardSystem:GetMarkerColor()
    return self.MarkerColor
end

function BlizzardSystem:GetMarkerBackgroundTransparency()
    return self.MarkerBackgroundTransparency
end

function BlizzardSystem:GetMarkerSize()
    return self.MarkerSize
end

function BlizzardSystem:GetMarkerPosition()
    return self.MarkerPosition
end

function BlizzardSystem.CustomizeUI(params)
    params = params or {}
    if params.markerText then BlizzardSystem.MarkerText = params.markerText end
    if params.markerColor then BlizzardSystem.MarkerColor = params.markerColor end
    if params.markerTransparency then BlizzardSystem.MarkerBackgroundTransparency = params.markerTransparency end
    if params.markerSize then BlizzardSystem.MarkerSize = params.markerSize end
    if params.markerPosition then BlizzardSystem.MarkerPosition = params.markerPosition end
end

-- Blizzard Spawner Section
local function createBlizzardSource(position, markerText, markerColor, markerTransparency, markerSize, markerPosition)
    local blizzardPart = Instance.new("Part")
    blizzardPart.Name = "BlizzardSource"
    blizzardPart.Size = Vector3.new(4, 4, 4)
    blizzardPart.Position = position
    blizzardPart.Anchored = true
    blizzardPart.CanCollide = false
    blizzardPart.Transparency = 0.7
    blizzardPart.Color = Color3.fromRGB(200, 200, 255)
    blizzardPart.Parent = Workspace

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "BlizzardBillboardMarker"
    billboardGui.Adornee = blizzardPart
    billboardGui.Size = markerSize
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = blizzardPart

    local markerLabel = Instance.new("TextLabel")
    markerLabel.Name = "BlizzardMarkerLabel"
    markerLabel.Text = markerText
    markerLabel.BackgroundColor3 = markerColor
    markerLabel.BackgroundTransparency = markerTransparency
    markerLabel.Size = UDim2.new(1, 0, 1, 0)
    markerLabel.Position = UDim2.new(0, 0, 0, 0)
    markerLabel.TextColor3 = Color3.new(1, 1, 1)
    markerLabel.TextScaled = true
    markerLabel.Parent = billboardGui

    return blizzardPart
end

local function createProps(numProps, propHealth, propHealthMin, propHealthMax)
    local propParts = {}
    for i = 1, numProps do
        local prop = Instance.new("Part")
        prop.Name = "BlizzardProp"
        prop.Size = Vector3.new(6, 6, 1)
        prop.Position = Vector3.new(math.random(-50, 50), 3, math.random(-50, 50))
        prop.Anchored = true
        prop.Color = Color3.fromRGB(100, 100, 100)
        prop.Parent = Workspace
        local health = propHealth
        if propHealthMin and propHealthMax then
            health = math.random(propHealthMin, propHealthMax)
        end
        prop:SetAttribute("Health", health)
        table.insert(propParts, prop)

    end
    return propParts
end

local function runBlizzardLoop(blizzardPart, propParts, damage, direction)
    task.spawn(function()
        while blizzardPart.Parent == Workspace do
            for _, player in Players:GetPlayers() do
                local character = player.Character
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if humanoid and rootPart then
                        local dir = (rootPart.Position - blizzardPart.Position)
                        if dir.Magnitude > 0 then
                            dir = dir.Unit
                        else
                            dir = direction
                        end
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {character}
                        rayParams.FilterType = Enum.RaycastFilterType.Blacklist

                        local rayResult = Workspace:Raycast(blizzardPart.Position, dir * 100, rayParams)
                        local exposed = true
                        if rayResult and rayResult.Instance.Name == "BlizzardProp" then
                            exposed = false
                        end

                        if exposed then
                            humanoid.Health = humanoid.Health - damage
                        end
                    end
                end
            end

            for i = 1, #propParts do
                local prop = propParts[i]
                if prop and prop.Parent == Workspace then
                    local health = prop:GetAttribute("Health")
                    if health then
                        health = health - 1
                        prop:SetAttribute("Health", health)
                        if health <= 0 then
                            prop:Destroy()
                            propParts[i] = nil
                        end
                    end
                end
            end

            if BlizzardLocationEvent then
                BlizzardLocationEvent:FireAllClients(blizzardPart.Position)
            end
            task.wait(1)
        end
    end)
end

function BlizzardSystem.SpawnBlizzard(params)
    params = params or {}
    local position = params.position or Vector3.new(0, 10, 0)
    local numProps = params.numProps or 10
    local damage = params.damage or 5
    local direction = BlizzardSystem:GetDirectionVector(params.direction or Vector3.new(1, 0, 0))
    local propHealth = params.propHealth or 20
    local markerText = params.markerText or BlizzardSystem.MarkerText
    local markerColor = params.markerColor or BlizzardSystem.MarkerColor
    local markerTransparency = params.markerTransparency or BlizzardSystem.MarkerBackgroundTransparency
    local markerSize = params.markerSize or BlizzardSystem.MarkerSize
    local markerPosition = params.markerPosition or BlizzardSystem.MarkerPosition

    local blizzardPart = createBlizzardSource(position, markerText, markerColor, markerTransparency, markerSize, markerPosition)
    local propParts = createProps(numProps, propHealth)
    runBlizzardLoop(blizzardPart, propParts, damage, direction)
    if BlizzardLocationEvent then
        BlizzardLocationEvent:FireAllClients(blizzardPart.Position)
    end
    return blizzardPart, propParts
end

function BlizzardSystem.SpawnBlizzardWithRandomPropHealth(params)
    params = params or {}
    local position = params.position or Vector3.new(0, 10, 0)
    local numProps = params.numProps or 10
    local damage = params.damage or 5
    local direction = BlizzardSystem:GetDirectionVector(params.direction or Vector3.new(1, 0, 0))
    local propHealthMin = params.propHealthMin or 10
    local propHealthMax = params.propHealthMax or 50
    local markerText = params.markerText or BlizzardSystem.MarkerText
    local markerColor = params.markerColor or BlizzardSystem.MarkerColor
    local markerTransparency = params.markerTransparency or BlizzardSystem.MarkerBackgroundTransparency
    local markerSize = params.markerSize or BlizzardSystem.MarkerSize
    local markerPosition = params.markerPosition or BlizzardSystem.MarkerPosition

    local blizzardPart = createBlizzardSource(position, markerText, markerColor, markerTransparency, markerSize, markerPosition)
    local propParts = createProps(numProps, nil, propHealthMin, propHealthMax)
    runBlizzardLoop(blizzardPart, propParts, damage, direction)
    if BlizzardLocationEvent then
        BlizzardLocationEvent:FireAllClients(blizzardPart.Position)
    end
    return blizzardPart, propParts
end

return BlizzardSystem


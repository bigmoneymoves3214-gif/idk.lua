local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- Destroy old UI if exists
local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("OGBrainrot")
if oldGui then oldGui:Destroy() end

local enabled = false
local running = false

-- Always queue script for next teleport (so it persists across multiple hops)
pcall(function()
    local queueFunc = queueonteleport or queue_on_teleport
    if queueFunc then
        queueFunc([[
            repeat task.wait() until game:IsLoaded()
            task.wait(2)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/bigmoneymoves3214-gif/idk.lua/refs/heads/main/lua"))()
        ]])
    end
end)

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OGBrainrot"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 60)
frame.Position = UDim2.new(1, -190, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -16, 0, 26)
btn.Position = UDim2.new(0, 8, 0, 5)
btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.Text = "OG Farm: OFF"
btn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = btn

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 20)
statusLabel.Position = UDim2.new(0, 8, 0, 34)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Text = "Idle"
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local function setStatus(text)
    statusLabel.Text = text
end

local function holdE(duration)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(duration)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function parseTimer(text)
    -- "OG Brainrot in 1:46" -> returns seconds
    local min, sec = text:match("(%d+):(%d+)")
    if min and sec then
        return tonumber(min) * 60 + tonumber(sec)
    end
    return 9999
end

local function serverHop()
    setStatus("Server hopping...")
    
    -- Queue script for next server
    pcall(function()
        local queueFunc = queueonteleport or queue_on_teleport
        if queueFunc then
            queueFunc([[
                repeat task.wait() until game:IsLoaded()
                task.wait(2)
                loadstring(game:HttpGet("https://raw.githubusercontent.com/bigmoneymoves3214-gif/idk.lua/refs/heads/main/lua"))()
            ]])
        end
    end)
    
    local placeId = game.PlaceId
    local servers = {}
    
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = game:HttpGet(url)
        local data = HttpService:JSONDecode(response)
        
        for _, server in ipairs(data.data or {}) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end)
    
    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(placeId, randomServer, player)
    else
        TeleportService:Teleport(placeId, player)
    end
end

local function log(msg)
    print("[OG Farm] " .. msg)
end

local function findCharRarity(instance)
    -- Recursively search for CharRarity TextLabel
    for _, child in pairs(instance:GetDescendants()) do
        if child.Name == "CharRarity" and (child:IsA("TextLabel") or child:IsA("TextBox")) then
            return child
        end
    end
    return nil
end

local function findPickupPrompt(instance)
    -- Search for ProximityPrompt
    for _, child in pairs(instance:GetDescendants()) do
        if child:IsA("ProximityPrompt") then
            return child
        end
    end
    return nil
end

local function mainLoop()
    log("Main loop started")
    while enabled and screenGui.Parent do
        running = true
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if not hrp then
            log("No HRP, waiting...")
            task.wait(0.5)
            continue
        end
        
        local brainrots = workspace:FindFirstChild("Brainrots")
        if not brainrots then
            setStatus("No Brainrots model")
            log("No Brainrots model found in workspace")
            task.wait(1)
            continue
        end
        
        log("Brainrots found: " .. brainrots.ClassName)

        local children = brainrots:GetChildren()
        log("Found " .. #children .. " brainrots")
        setStatus("Scanning " .. #children .. " brainrots")
        
        local foundOG = false
        
        for _, model in pairs(children) do
            if not enabled then break end
            
            log("Checking: " .. model.Name .. " (" .. model.ClassName .. ")")
            
            -- Find CharRarity anywhere in the model
            local charRarity = findCharRarity(model)
            if charRarity then
                local rarityText = charRarity.Text or ""
                log("  -> CharRarity found: '" .. rarityText .. "'")
                
                if rarityText:lower() == "og" then
                    foundOG = true
                    log("  -> OG FOUND!")
                    setStatus("Found OG: " .. model.Name)
                    
                    -- Find and modify pickup prompt
                    local pickupPrompt = findPickupPrompt(model)
                    if pickupPrompt then
                        log("  -> PickupPrompt found, setting HoldDuration to 0")
                        pickupPrompt.HoldDuration = 0
                    else
                        log("  -> No PickupPrompt found")
                    end
                    
                    -- Teleport to brainrot (find any part to teleport to)
                    local targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        log("  -> Teleporting to " .. targetPart.Name)
                        hrp.CFrame = targetPart.CFrame
                    else
                        log("  -> No part to teleport to")
                    end
                    task.wait(0.3)
                    
                    -- Hold E for 2 seconds
                    setStatus("Picking up...")
                    log("  -> Holding E...")
                    holdE(2)
                    task.wait(0.5)
                    
                    -- Teleport to upgrades shop
                    local shops = workspace:FindFirstChild("Shops")
                    if shops then
                        local upgrades = shops:FindFirstChild("Upgrades")
                        if upgrades then
                            local shopPart = upgrades.PrimaryPart or upgrades:FindFirstChildWhichIsA("BasePart")
                            if shopPart then
                                hrp.CFrame = shopPart.CFrame
                                log("  -> Teleported to Upgrades shop")
                            end
                            setStatus("At Upgrades shop")
                        else
                            log("  -> No Upgrades in Shops")
                        end
                    else
                        log("  -> No Shops folder")
                    end
                    
                    task.wait(1)
                    break
                end
            else
                log("  -> No CharRarity found")
            end
        end
        
        if not foundOG and enabled then
            -- Check countdown timer
            local countdownSign = workspace:FindFirstChild("CountdownSign")
            if countdownSign then
                local signPart = countdownSign:FindFirstChild("SignPart")
                if signPart then
                    local surfaceGui = signPart:FindFirstChild("SurfaceGui")
                    if surfaceGui then
                        local signFrame = surfaceGui:FindFirstChild("Frame")
                        if signFrame then
                            local ogLabel = signFrame:FindFirstChild("OG")
                            if ogLabel then
                                local timerText = ogLabel.Text or ""
                                local seconds = parseTimer(timerText)
                                
                                if seconds <= 30 then
                                    setStatus("Waiting... " .. seconds .. "s")
                                    task.wait(1)
                                else
                                    setStatus("Timer > 30s, hopping...")
                                    task.wait(1)
                                    serverHop()
                                    return
                                end
                            end
                        end
                    end
                end
            else
                setStatus("No countdown sign")
                task.wait(1)
            end
        end
        
        task.wait(0.5)
    end
    running = false
end

btn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        btn.Text = "OG Farm: ON"
        btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        if not running then
            task.spawn(mainLoop)
        end
    else
        btn.Text = "OG Farm: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        setStatus("Idle")
    end
end)

-- Auto-start
enabled = true
btn.Text = "OG Farm: ON"
btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
task.spawn(mainLoop)

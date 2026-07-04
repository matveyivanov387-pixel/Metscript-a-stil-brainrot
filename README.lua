-- mat hub (Chiraq Hub Anti-Ragdoll + ESP, CS-style GUI)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

pcall(function()
    if CoreGui:FindFirstChild("mat_hub_gui") then CoreGui.mat_hub_gui:Destroy() end
    if CoreGui:FindFirstChild("mat_hud") then CoreGui.mat_hud:Destroy() end
end)

local C = {
    BG = Color3.fromRGB(10, 10, 15),
    BGDeep = Color3.fromRGB(6, 6, 10),
    BGSurface = Color3.fromRGB(20, 20, 30),
    Accent = Color3.fromRGB(255, 45, 149),
    AccentGlow = Color3.fromRGB(255, 80, 200),
    TextPrimary = Color3.fromRGB(245, 245, 245),
    TextSub = Color3.fromRGB(160, 160, 180),
    StateOn = Color3.fromRGB(100, 255, 180),
    StateOff = Color3.fromRGB(60, 60, 80),
    ESPPink = Color3.fromRGB(255, 100, 200),
}

local State = {
    speedEnabled = false,
    walkSpeed = 30,
    stealingSpeed = 28.6,
    giantSpeed = 34,
    carpetSpeed = 130,
    infJumpEnabled = false,
    antiRagdollEnabled = false,
    aimbotEnabled = false,
    espEnabled = false,
    hudEnabled = false,
    optimizeEnabled = false,
    flyEnabled = false,
    fullbrightEnabled = false,
}

local CONFIG_FILE = "mat_hub_v3_config.json"
local function saveConfig()
    local cfg = {}
    for k, v in pairs(State) do cfg[k] = v end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(cfg)) end)
end

local function loadConfig()
    if not isfile or not isfile(CONFIG_FILE) then return end
    local ok, raw = pcall(function() return readfile(CONFIG_FILE) end)
    if not ok or not raw then return end
    local ok2, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or not cfg then return end
    for k, v in pairs(cfg) do
        if State[k] ~= nil then State[k] = v end
    end
end

local function getCharacter() return LocalPlayer.Character end
local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChild("Humanoid")
end

-- ========== SPEED (Chiraq) ==========
local function getWalkSpeed()
    local char = getCharacter()
    local isStealing = LocalPlayer:GetAttribute("Stealing") ~= nil
    local isGiantPotion = LocalPlayer:GetAttribute("GiantPotion") ~= nil
    local isHoldingCarpet = char and char:FindFirstChild("Flying Carpet") ~= nil
    if isHoldingCarpet then return State.carpetSpeed end
    if isGiantPotion then return State.giantSpeed end
    if isStealing then return State.stealingSpeed end
    return State.walkSpeed
end

local walkConn = nil
local function stopAutoWalk()
    if walkConn then walkConn:Disconnect(); walkConn = nil end
end

local function startAutoWalk(dir)
    stopAutoWalk()
    if not dir then return end
    local d = Vector3.new(dir.X, 0, dir.Z).Unit
    walkConn = RunService.Heartbeat:Connect(function()
        if not State.speedEnabled then return end
        local char = getCharacter()
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local spd = getWalkSpeed()
        root.Velocity = Vector3.new(d.X * spd, root.Velocity.Y, d.Z * spd)
    end)
end

local function toggleSpeed()
    State.speedEnabled = not State.speedEnabled
    saveConfig()
    if State.speedEnabled then
        local char = getCharacter()
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then startAutoWalk(root.CFrame.LookVector) end
    else
        stopAutoWalk()
    end
end

local function setSpeed(value)
    State.walkSpeed = value
    saveConfig()
end

-- ========== INF JUMP ==========
local function toggleInfJump()
    State.infJumpEnabled = not State.infJumpEnabled
    saveConfig()
end

UserInputService.JumpRequest:Connect(function()
    if State.infJumpEnabled then
        local h = getHumanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ========== ANTI-RAGDOLL (Chiraq) ==========
local function toggleAntiRagdoll()
    State.antiRagdollEnabled = not State.antiRagdollEnabled
    saveConfig()
end

RunService.Heartbeat:Connect(function()
    if not State.antiRagdollEnabled then return end
    local char = getCharacter()
    if char then
        local h = char:FindFirstChild("Humanoid")
        if h then
            h.AutoRotate = true
            h.PlatformStand = false
            if h:GetState() == Enum.HumanoidStateType.Physics then
                h:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end)

-- ========== FLY ==========
local flyBV, flyConn
local function toggleFly()
    State.flyEnabled = not State.flyEnabled
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if State.flyEnabled then
        local char = getCharacter()
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                flyBV = Instance.new("BodyVelocity")
                flyBV.MaxForce = Vector3.new(4000, 4000, 4000)
                flyBV.Parent = root
                flyConn = RunService.RenderStepped:Connect(function()
                    if not State.flyEnabled then return end
                    local c = getCharacter()
                    if not c then return end
                    local r = c:FindFirstChild("HumanoidRootPart")
                    if not r then return end
                    local move = Vector3.new()
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + r.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - r.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - r.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + r.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
                    if move.Magnitude > 0 then flyBV.Velocity = move.Unit * 60 else flyBV.Velocity = Vector3.new(0,0,0) end
                end)
            end
        end
    end
    saveConfig()
end

-- ========== BATLOCK ==========
local function getClosestPlayer()
    local hrp = getHRP()
    if not hrp then return nil end
    local closest, dist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local d = (targetHRP.Position - hrp.Position).Magnitude
                if d < dist then closest, dist = plr, d end
            end
        end
    end
    return closest
end

local function toggleAimbot()
    State.aimbotEnabled = not State.aimbotEnabled
    saveConfig()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and State.aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character then
            local char = getCharacter()
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end
        end
    end
end)

-- ========== ESP (Chiraq, с DepthMode AlwaysOnTop) ==========
local espHighlights, espConnections = {}, {}

local function clearESP()
    for _, h in ipairs(espHighlights) do if h and h.Parent then h:Destroy() end end
    espHighlights = {}
    for _, c in ipairs(espConnections) do if c then c:Disconnect() end end
    espConnections = {}
end

local function updateESP()
    if not State.espEnabled then return end
    clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = char
                highlight.FillColor = C.ESPPink
                highlight.FillTransparency = 0.3
                highlight.OutlineColor = Color3.new(255,255,255)
                highlight.OutlineTransparency = 0.2
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = char
                table.insert(espHighlights, highlight)
            end
            local conn = plr.CharacterAdded:Connect(function(newChar)
                task.wait(0.5)
                if not State.espEnabled then return end
                local h = Instance.new("Highlight")
                h.Adornee = newChar
                h.FillColor = C.ESPPink
                h.FillTransparency = 0.3
                h.OutlineColor = Color3.new(255,255,255)
                h.OutlineTransparency = 0.2
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = newChar
                table.insert(espHighlights, h)
            end)
            table.insert(espConnections, conn)
        end
    end
end

local function toggleESP()
    State.espEnabled = not State.espEnabled
    if State.espEnabled then
        updateESP()
        local conn = Players.PlayerAdded:Connect(function() updateESP() end)
        table.insert(espConnections, conn)
    else
        clearESP()
    end
    saveConfig()
end

RunService.Heartbeat:Connect(function()
    if State.espEnabled then updateESP() end
end)

-- ========== HUD ==========
local hudGui, hudConn
local function createHUD()
    if hudGui then hudGui:Destroy() end
    hudGui = Instance.new("ScreenGui")
    hudGui.Name = "mat_hud"
    hudGui.Parent = CoreGui

    local frame = Instance.new("Frame", hudGui)
    frame.Size = UDim2.new(0,160,0,44)
    frame.Position = UDim2.new(0.5,-80,0,10)
    frame.BackgroundColor3 = C.BGDeep
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,14)
    title.Position = UDim2.new(0,0,0,2)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 10
    title.TextColor3 = C.AccentGlow
    title.Text = "mat hub"
    title.TextXAlignment = Enum.TextXAlignment.Center

    local fpsLabel = Instance.new("TextLabel", frame)
    fpsLabel.Size = UDim2.new(0.5,0,0,14)
    fpsLabel.Position = UDim2.new(0,0,0,18)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Font = Enum.Font.Gotham
    fpsLabel.TextSize = 12
    fpsLabel.TextColor3 = C.TextPrimary
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Center

    local pingLabel = Instance.new("TextLabel", frame)
    pingLabel.Size = UDim2.new(0.5,0,0,14)
    pingLabel.Position = UDim2.new(0.5,0,0,18)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Font = Enum.Font.Gotham
    pingLabel.TextSize = 12
    pingLabel.TextColor3 = C.TextSub
    pingLabel.Text = "Ping: 0"
    pingLabel.TextXAlignment = Enum.TextXAlignment.Center

    local frameCount = 0
    local timeAcc = 0
    local conn = RunService.RenderStepped:Connect(function(dt)
        timeAcc = timeAcc + dt
        frameCount = frameCount + 1
        if timeAcc >= 0.5 then
            fpsLabel.Text = "FPS: " .. math.floor(frameCount / timeAcc)
            frameCount = 0
            timeAcc = 0
        end
        local ping = Stats.Network:GetServerStats()
        if ping then pingLabel.Text = "Ping: " .. math.floor(ping.Ping) end
    end)

    return hudGui, conn
end

local function toggleHUD()
    State.hudEnabled = not State.hudEnabled
    if State.hudEnabled then
        local gui, conn = createHUD()
        hudConn = conn
    else
        if hudGui then hudGui:Destroy(); hudGui = nil end
        if hudConn then hudConn:Disconnect(); hudConn = nil end
    end
    saveConfig()
end

-- ========== OPTIMIZE ==========
local function toggleOptimize()
    State.optimizeEnabled = not State.optimizeEnabled
    if State.optimizeEnabled then
        Lighting.GlobalShadows = false
        settings().Rendering.QualityLevel = 1
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") then v.Enabled = false end
            if v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled = false end
        end
    else
        Lighting.GlobalShadows = true
        settings().Rendering.QualityLevel = 10
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") then v.Enabled = true end
            if v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled = true end
        end
    end
    saveConfig()
end

-- ========== FULLBRIGHT ==========
local function toggleFullbright()
    State.fullbrightEnabled = not State.fullbrightEnabled
    if State.fullbrightEnabled then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1,1,1)
    else
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.new(0.3,0.3,0.3)
    end
    saveConfig()
end

-- ========== CS-STYLE GUI ==========
local function getGuiParent()
    if gethui then return gethui() end
    return CoreGui
end

local screenGui, mainFrame
local isOpen = true

local function createMainGUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "mat_hub_gui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = getGuiParent()

    local openBtn = Instance.new("TextButton", screenGui)
    openBtn.Name = "OpenBtn"
    openBtn.Text = "M"
    openBtn.TextColor3 = C.AccentGlow
    openBtn.Font = Enum.Font.GothamBlack
    openBtn.TextSize = 24
    openBtn.BackgroundColor3 = C.BGDeep
    openBtn.BackgroundTransparency = 0.2
    openBtn.Position = UDim2.new(0.01,0,0.2,0)
    openBtn.Size = UDim2.new(0,50,0,50)
    openBtn.Visible = false
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1,0)
    local stroke = Instance.new("UIStroke", openBtn)
    stroke.Color = C.Accent
    stroke.Thickness = 2

    openBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        openBtn.Visible = false
        isOpen = true
    end)

    mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0,340,0,440)
    mainFrame.Position = UDim2.new(0.5,-170,0.5,-220)
    mainFrame.BackgroundColor3 = C.BGDeep
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,16)
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = C.Accent
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.3

    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1,0,0,40)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextColor3 = C.AccentGlow
    title.Text = "mat hub"
    title.TextXAlignment = Enum.TextXAlignment.Center

    local closeBtn = Instance.new("TextButton", mainFrame)
    closeBtn.Size = UDim2.new(0,30,0,30)
    closeBtn.Position = UDim2.new(1,-35,0,5)
    closeBtn.BackgroundColor3 = C.StateOff
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)
    closeBtn.Text = "✕"
    closeBtn.TextSize = 16
    closeBtn.TextColor3 = C.TextPrimary
    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        openBtn.Visible = true
        isOpen = false
    end)

    local tabBar = Instance.new("Frame", mainFrame)
    tabBar.Size = UDim2.new(1,-20,0,30)
    tabBar.Position = UDim2.new(0,10,0,45)
    tabBar.BackgroundColor3 = C.BGSurface
    tabBar.BackgroundTransparency = 0.5
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0,6)

    local tabs = {"Кража", "Мувмент", "Визуал", "Прочее"}
    local tabButtons, tabContents = {}, {}

    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton", tabBar)
        btn.Size = UDim2.new(0.25,0,1,0)
        btn.Position = UDim2.new((i-1)*0.25,0,0,0)
        btn.BackgroundTransparency = 1
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = C.TextSub
        btn.Text = name
        btn.Name = name .. "_tab"
        table.insert(tabButtons, btn)

        local content = Instance.new("ScrollingFrame", mainFrame)
        content.Size = UDim2.new(1,-20,1,-100)
        content.Position = UDim2.new(0,10,0,80)
        content.BackgroundTransparency = 1
        content.ScrollBarThickness = 3
        content.ScrollBarImageColor3 = C.Accent
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        content.Visible = (i == 1)
        table.insert(tabContents, content)

        btn.MouseButton1Click:Connect(function()
            for _, b in ipairs(tabButtons) do b.TextColor3 = C.TextSub; b.BackgroundTransparency = 1 end
            for _, c in ipairs(tabContents) do c.Visible = false end
            btn.TextColor3 = C.AccentGlow
            btn.BackgroundTransparency = 0.8
            content.Visible = true
        end)
    end

    local function createToggle(parent, label, defaultValue, callback)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1,0,0,40)
        frame.BackgroundColor3 = C.BGSurface
        frame.BackgroundTransparency = 0.3
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(0.55,0,1,0)
        lbl.Position = UDim2.new(0.04,0,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextColor3 = C.TextPrimary
        lbl.Text = label
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0,65,0,28)
        btn.Position = UDim2.new(1,-75,0.5,-14)
        btn.BackgroundColor3 = defaultValue and C.StateOn or C.StateOff
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
        btn.Text = defaultValue and "ON" or "OFF"
        btn.TextSize = 11
        btn.TextColor3 = C.TextPrimary
        btn.Font = Enum.Font.GothamBold

        local state = defaultValue
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and C.StateOn or C.StateOff
            btn.Text = state and "ON" or "OFF"
            callback(state)
        end)
    end

    local function createSlider(parent, label, min, max, defaultValue, callback)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1,0,0,55)
        frame.BackgroundColor3 = C.BGSurface
        frame.BackgroundTransparency = 0.3
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(1,0,0,18)
        lbl.Position = UDim2.new(0.04,0,0.05,0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextColor3 = C.TextPrimary
        lbl.Text = label .. " (" .. defaultValue .. ")"
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local valueLbl = Instance.new("TextLabel", frame)
        valueLbl.Size = UDim2.new(0,50,0,18)
        

-- mat hub (базовая версия, исправлены только критические ошибки)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")

pcall(function()
    if CoreGui:FindFirstChild("mat_hub_gui") then CoreGui.mat_hub_gui:Destroy() end
    if CoreGui:FindFirstChild("mat_hud") then CoreGui.mat_hud:Destroy() end
end)

local State = {
    speedEnabled = false,
    walkSpeed = 16,
    infJumpEnabled = false,
    aimbotEnabled = false,
    espEnabled = false,
    hudEnabled = false,
    antiRagdollEnabled = false,
    optimizeEnabled = false,
}

local CONFIG_FILE = "mat_config.json"

local function saveConfig()
    local cfg = {}
    for k, v in pairs(State) do cfg[k] = v end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(cfg)) end)
end

local function loadConfig()
    if not isfile or not isfile(CONFIG_FILE) then return end
    local ok, raw = pcall(function() return readfile(CONFIG_FILE) end)
    if ok and raw then
        local ok2, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok2 and cfg then
            for k, v in pairs(cfg) do
                if State[k] ~= nil then State[k] = v end
            end
        end
    end
end

local function getCharacter() return LocalPlayer.Character end
local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChild("Humanoid")
end

-- ========== SPEED ==========
local function applySpeed()
    local h = getHumanoid()
    if h then
        h.WalkSpeed = State.speedEnabled and State.walkSpeed or 16
    end
end

local function toggleSpeed()
    State.speedEnabled = not State.speedEnabled
    applySpeed()
    saveConfig()
end

local function setSpeed(v)
    State.walkSpeed = v
    applySpeed()
    saveConfig()
end

-- ========== INF JUMP ==========
local infJumpConn = nil
local function toggleInfJump()
    State.infJumpEnabled = not State.infJumpEnabled
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    if State.infJumpEnabled then
        infJumpConn = RunService.Heartbeat:Connect(function()
            local h = getHumanoid()
            if h and (h:GetState() == Enum.HumanoidStateType.Jumping or h:GetState() == Enum.HumanoidStateType.Freefall) then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
    saveConfig()
end

-- ========== ANTI-RAGDOLL ==========
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

-- ========== BATLOCK ==========
local function getClosestPlayer()
    local hrp = getCharacter() and getCharacter():FindFirstChild("HumanoidRootPart")
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

-- ========== ESP ==========
local espHighlights = {}
local function clearESP()
    for _, h in ipairs(espHighlights) do
        if h and h.Parent then h:Destroy() end
    end
    espHighlights = {}
end

local function updateESP()
    if not State.espEnabled then return end
    clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                local h = Instance.new("Highlight")
                h.Adornee = char
                h.FillColor = Color3.fromRGB(255, 100, 175)
                h.FillTransparency = 0.3
                h.OutlineColor = Color3.fromRGB(255, 80, 200)
                h.OutlineTransparency = 0.2
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = char
                table.insert(espHighlights, h)
            end
        end
    end
end

local function toggleESP()
    State.espEnabled = not State.espEnabled
    if State.espEnabled then
        updateESP()
        Players.PlayerAdded:Connect(function() updateESP() end)
        Players.PlayerRemoving:Connect(function() updateESP() end)
    else
        clearESP()
    end
    saveConfig()
end

RunService.Heartbeat:Connect(function()
    if State.espEnabled then updateESP() end
end)

-- ========== HUD ==========
local hudGui = nil
local function createHUD()
    if hudGui then hudGui:Destroy() end
    hudGui = Instance.new("ScreenGui")
    hudGui.Name = "mat_hud"
    hudGui.Parent = CoreGui

    local frame = Instance.new("Frame", hudGui)
    frame.Size = UDim2.new(0, 160, 0, 44)
    frame.Position = UDim2.new(0.5, -80, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(12, 4, 10)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 14)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 10
    title.TextColor3 = Color3.fromRGB(255, 80, 200)
    title.Text = "mat hub"
    title.TextXAlignment = Enum.TextXAlignment.Center

    local fps = Instance.new("TextLabel", frame)
    fps.Size = UDim2.new(0.5, 0, 0, 14)
    fps.Position = UDim2.new(0, 0, 0, 18)
    fps.BackgroundTransparency = 1
    fps.Font = Enum.Font.Gotham
    fps.TextSize = 12
    fps.TextColor3 = Color3.fromRGB(245, 235, 242)
    fps.Text = "FPS: 0"
    fps.TextXAlignment = Enum.TextXAlignment.Center

    local ping = Instance.new("TextLabel", frame)
    ping.Size = UDim2.new(0.5, 0, 0, 14)
    ping.Position = UDim2.new(0.5, 0, 0, 18)
    ping.BackgroundTransparency = 1
    ping.Font = Enum.Font.Gotham
    ping.TextSize = 12
    ping.TextColor3 = Color3.fromRGB(160, 120, 145)
    ping.Text = "Ping: 0"
    ping.TextXAlignment = Enum.TextXAlignment.Center

    local cnt, acc = 0, 0
    local conn = RunService.RenderStepped:Connect(function(dt)
        acc = acc + dt
        cnt = cnt + 1
        if acc >= 0.5 then
            fps.Text = "FPS: " .. math.floor(cnt / acc)
            cnt, acc = 0, 0
        end
        local s = Stats.Network:GetServerStats()
        if s then ping.Text = "Ping: " .. math.floor(s.Ping) end
    end)

    return hudGui, conn
end

local hudConn = nil
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

-- ========== GUI ==========
local function getGuiParent()
    if gethui then return gethui() end
    return CoreGui
end

local screenGui
local mainFrame
local isOpen = true

local function createMainGUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "mat_hub_gui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = getGuiParent()

    local openBtn = Instance.new("TextButton", screenGui)
    openBtn.Name = "OpenBtn"
    openBtn.Text = "M"
    openBtn.TextColor3 = Color3.fromRGB(255, 80, 200)
    openBtn.Font = Enum.Font.GothamBlack
    openBtn.TextSize = 24
    openBtn.BackgroundColor3 = Color3.fromRGB(12, 4, 10)
    openBtn.BackgroundTransparency = 0.2
    openBtn.Position = UDim2.new(0.01, 0, 0.2, 0)
    openBtn.Size = UDim2.new(0, 50, 0, 50)
    openBtn.Visible = false
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", openBtn)
    stroke.Color = Color3.fromRGB(220, 40, 160)
    stroke.Thickness = 2

    openBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        openBtn.Visible = false
        isOpen = true
    end)

    mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0, 340, 0, 440)
    mainFrame.Position = UDim2.new(0.5, -170, 0.5, -220)
    mainFrame.BackgroundColor3 = Color3.fromRGB(12, 4, 10)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Color3.fromRGB(220, 40, 160)
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.3

    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 80, 200)
    title.Text = "mat hub"
    title.TextXAlignment = Enum.TextXAlignment.Center

    local closeBtn = Instance.new("TextButton", mainFrame)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(160, 120, 145)
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.Text = "✕"
    closeBtn.TextSize = 16
    closeBtn.TextColor3 = Color3.fromRGB(245, 235, 242)
    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        openBtn.Visible = true
        isOpen = false
    end)

    local content = Instance.new("ScrollingFrame", mainFrame)
    content.Size = UDim2.new(1, -20, 1, -50)
    content.Position = UDim2.new(0, 10, 0, 45)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Color3.fromRGB(220, 40, 160)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout", content)
    layout.Padding = UDim.new(0, 8)

    local function createToggle(label, defaultValue, callback)
        local frame = Instance.new("Frame", content)
        frame.Size = UDim2.new(1, 0, 0, 45)
        frame.BackgroundColor3 = Color3.fromRGB(34, 14, 27)
        frame.BackgroundTransparency = 0.3
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(0.55, 0, 1, 0)
        lbl.Position = UDim2.new(0.04, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.fromRGB(245, 235, 242)
        lbl.Text = label
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 70, 0, 30)
        btn.Position = UDim2.new(1, -78, 0.5, -15)
        btn.BackgroundColor3 = defaultValue and Color3.fromRGB(100, 255, 180) or Color3.fromRGB(160, 120, 145)
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.Text = defaultValue and "ON" or "OFF"
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(245, 235, 242)
        btn.Font = Enum.Font.GothamBold

        local state = defaultValue
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(100, 255, 180) or Color3.fromRGB(160, 120, 145)
            btn.Text = state and "ON" or "OFF"
            callback(state)
        end)
    end

    local function createSlider(label, min, max, defaultValue, callback)
        local frame = Instance.new("Frame", content)
        frame.Size = UDim2.new(1, 0, 0, 60)
        frame.BackgroundColor3 = Color3.fromRGB(34, 14, 27)
        frame.BackgroundTransparency = 0.3
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.Position = UDim2.new(0.04, 0, 0.05, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.fromRGB(245, 235, 242)
        lbl.Text = label .. " (" .. defaultValue .. ")"
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local valueLbl = Instance.new("TextLabel", frame)
        valueLbl.Size = UDim2.new(0, 50, 0, 18)
        valueLbl.Position = UDim2.new(1, -55, 0.05, 0)
        valueLbl.BackgroundTransparency = 1
        valueLbl.Font = Enum.Font.GothamBold
        valueLbl.TextSize = 14
        valueLbl.TextColor3 = Color3.fromRGB(220, 40, 160)
        valueLbl.Text = tostring(defaultValue)
        valueLbl.TextXAlignment = Enum.TextXAlignment.Right

        local sliderBtn = Instance.new("TextButton", frame)
        sliderBtn.Size = UDim2.new(0.92, 0, 0, 8)
        sliderBtn.Position = UDim2.new(0.04, 0, 0.6, 0)
        sliderBtn.BackgroundColor3 = Color3.fromRGB(12, 4, 10)
        sliderBtn.BorderSizePixel = 0
        Instance.new("UICorner", sliderBtn).CornerRadius = UDim.new(0, 4)

        local fill = Instance.new("Frame", sliderBtn)
        fill.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(220, 40, 160)
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

        local dragging = false
        local currentValue = defaultValue

        sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
        sliderBtn.MouseButton1Up:Connect(function() dragging = false end)

        UserInputService.InputChanged:Connect(function(input)
            if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            local pos = input.Position.X
            local absX = sliderBtn.AbsolutePosition.X
            local sizeX = sliderBtn.AbsoluteSize.X
            local pct = math.clamp((pos - absX) / sizeX, 0, 1)
            local val = math.floor(min + (max - min) * pct)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            lbl.Text = label .. " (" .. val .. ")"
            valueLbl.Text = tostring(val)
            currentValue = val
            callback(val)
        end)
    end

    createToggle("Скорость", State.speedEnabled, function(v)
        State.speedEnabled = v
        toggleSpeed()
    end)

    createSlider("Скорость", 16, 120, State.walkSpeed, function(v)
        setSpeed(v)
    end)

    createToggle("Inf Jump", State.infJumpEnabled, function(v)
        State.infJumpEnabled = v
        toggleInfJump()
    end)

    createToggle("Anti-Ragdoll", State.antiRagdollEnabled, function(v)
        State.antiRagdollEnabled = v
        toggleAntiRagdoll()
    end)

    createToggle("BatLock (аимбот)", State.aimbotEnabled, function(v)
        State.aimbotEnabled = v
        toggleAimbot()
    end)

    createToggle("Player ESP", State.espEnabled, function(v)
        State.espEnabled = v
        toggleESP()
    end)

    createToggle("HUD (FPS/Ping)", State.hudEnabled, function(v)
        State.hudEnabled = v
        toggleHUD()
    end)

    createToggle("Оптимизация FPS", State.optimizeEnabled, function(v)
        State.optimizeEnabled = v
        toggleOptimize()
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightBracket then
            if isOpen then
                mainFrame.Visible = false
                openBtn.Visible = true
                isOpen = false
            else
                mainFrame.Visible = true
                openBtn.Visible = false
                isOpen = true
            end
        end
    end)
end

loadConfig()
createMainGUI()

if State.speedEnabled then toggleSpeed() end
if State.infJumpEnabled then toggleInfJump() end
if State.antiRagdollEnabled then toggleAntiRagdoll() end
if State.aimbotEnabled then toggleAimbot() end
if State.espEnabled then toggleESP() end
if State.hudEnabled then toggleHUD() end
if State.optimizeEnabled then toggleOptimize() end

local splash = Instance.new("ScreenGui")
splash.Name = "mat_splash"
splash.Parent = CoreGui
local frame = Instance.new("Frame", splash)
frame.Size = UDim2.new(0, 280, 0, 60)
frame.Position = UDim2.new(0.5, -140, 0.85, 0)
frame.BackgroundColor3 = Color3.fromRGB(12, 4, 10)
frame.BackgroundTransparency = 0.15
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.TextColor3 = Color3.fromRGB(255, 80, 200)
label.Text = "mat hub loaded!"
task.wait(2)
splash:Destroy()

-- mat hub (чистая версия) — только нужные функции

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

-- Цветовая схема (оставляем как было)
local C = {
    BG = Color3.fromRGB(18, 8, 15),
    BGDeep = Color3.fromRGB(12, 4, 10),
    BGSurface = Color3.fromRGB(34, 14, 27),
    Accent = Color3.fromRGB(220, 40, 160),
    AccentGlow = Color3.fromRGB(255, 80, 200),
    TextPrimary = Color3.fromRGB(245, 235, 242),
    TextSub = Color3.fromRGB(160, 120, 145),
    StateOn = Color3.fromRGB(100, 255, 180),
    StateOff = Color3.fromRGB(160, 120, 145),
    ESPPink = Color3.fromRGB(255, 100, 175),
}

-- Состояние
local State = {
    speedEnabled = false,
    walkSpeed = 16,
    infJumpEnabled = false,
    aimbotEnabled = false,
    espEnabled = false,
    hudEnabled = false,
    antiRagdollEnabled = false,
}

-- Сохранение конфига
local CONFIG_FILE = "mat_hub_config.json"
local function saveConfig()
    local cfg = {
        speedEnabled = State.speedEnabled,
        walkSpeed = State.walkSpeed,
        infJumpEnabled = State.infJumpEnabled,
        aimbotEnabled = State.aimbotEnabled,
        espEnabled = State.espEnabled,
        hudEnabled = State.hudEnabled,
        antiRagdollEnabled = State.antiRagdollEnabled,
    }
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(cfg)) end)
end

local function loadConfig()
    if not isfile or not isfile(CONFIG_FILE) then return end
    local ok, raw = pcall(function() return readfile(CONFIG_FILE) end)
    if not ok or not raw then return end
    local ok2, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or not cfg then return end
    if cfg.speedEnabled ~= nil then State.speedEnabled = cfg.speedEnabled end
    if cfg.walkSpeed then State.walkSpeed = cfg.walkSpeed end
    if cfg.infJumpEnabled ~= nil then State.infJumpEnabled = cfg.infJumpEnabled end
    if cfg.aimbotEnabled ~= nil then State.aimbotEnabled = cfg.aimbotEnabled end
    if cfg.espEnabled ~= nil then State.espEnabled = cfg.espEnabled end
    if cfg.hudEnabled ~= nil then State.hudEnabled = cfg.hudEnabled end
    if cfg.antiRagdollEnabled ~= nil then State.antiRagdollEnabled = cfg.antiRagdollEnabled end
end

-- Хелперы
local function getCharacter() return LocalPlayer.Character end
local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChild("Humanoid")
end

-- ========== SPEED CUSTOM ==========
local function setSpeed(value)
    State.walkSpeed = value
    local h = getHumanoid()
    if h and State.speedEnabled then
        h.WalkSpeed = value
    end
end

local function toggleSpeed()
    State.speedEnabled = not State.speedEnabled
    local h = getHumanoid()
    if h then
        h.WalkSpeed = State.speedEnabled and State.walkSpeed or 16
    end
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
local antiRagdollConn = nil
local function toggleAntiRagdoll()
    State.antiRagdollEnabled = not State.antiRagdollEnabled
    if antiRagdollConn then antiRagdollConn:Disconnect(); antiRagdollConn = nil end
    if State.antiRagdollEnabled then
        antiRagdollConn = RunService.Heartbeat:Connect(function()
            local char = getCharacter()
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:FindFirstChild("RagdollCheck") then
                    hrp.RagdollCheck:Destroy()
                end
            end
        end)
    end
    saveConfig()
end

-- ========== BATLOCK (AIMBOT) ==========
local aimbotTarget = nil
local function getClosestPlayer()
    local hrp = getHRP()
    if not hrp then return nil end
    local closest, dist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local d = (targetHRP.Position - hrp.Position).Magnitude
                if d < dist then
                    closest, dist = plr, d
                end
            end
        end
    end
    return closest
end

local function toggleAimbot()
    State.aimbotEnabled = not State.aimbotEnabled
    saveConfig()
end

-- Обработка аимбота (авто-удар + наведение)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and State.aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character then
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local char = getCharacter()
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.CFrame = CFrame.new(root.Position, hrp.Position)
                    end
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    end
                end
            end
        end
    end
end)

-- ========== PLAYER ESP ==========
local espHighlights = {}
local espConnections = {}
local function clearESP()
    for _, h in ipairs(espHighlights) do
        if h and h.Parent then h:Destroy() end
    end
    espHighlights = {}
    for _, c in pairs(espConnections) do
        if c then c:Disconnect() end
    end
    espConnections = {}
end

local function updateESP()
    clearESP()
    if not State.espEnabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = char
                highlight.FillColor = C.ESPPink
                highlight.FillTransparency = 0.4
                highlight.Parent = char
                table.insert(espHighlights, highlight)
            end
            -- Подписываемся на появление персонажа
            local conn = plr.CharacterAdded:Connect(function(newChar)
                task.wait(0.5)
                local h = Instance.new("Highlight")
                h.Adornee = newChar
                h.FillColor = C.ESPPink
                h.FillTransparency = 0.4
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
    else
        clearESP()
    end
    saveConfig()
end

-- ========== HUD (FPS + PING) ==========
local hudGui = nil
local function createHUD()
    if hudGui then hudGui:Destroy() end
    hudGui = Instance.new("ScreenGui")
    hudGui.Name = "mat_hud"
    hudGui.Parent = getGuiParent()

    local frame = Instance.new("Frame", hudGui)
    frame.Size = UDim2.new(0, 150, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = C.BGDeep
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local fpsLabel = Instance.new("TextLabel", frame)
    fpsLabel.Size = UDim2.new(1, 0, 0.5, 0)
    fpsLabel.Position = UDim2.new(0, 0, 0, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextSize = 14
    fpsLabel.TextColor3 = C.TextPrimary
    fpsLabel.Text = "FPS: 0"

    local pingLabel = Instance.new("TextLabel", frame)
    pingLabel.Size = UDim2.new(1, 0, 0.5, 0)
    pingLabel.Position = UDim2.new(0, 0, 0.5, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.TextSize = 14
    pingLabel.TextColor3 = C.TextSub
    pingLabel.Text = "Ping: 0"

    local frameCount = 0
    local timeAcc = 0
    local pingConn = nil
    local hudConn = RunService.RenderStepped:Connect(function(dt)
        timeAcc = timeAcc + dt
        frameCount = frameCount + 1
        if timeAcc >= 0.5 then
            fpsLabel.Text = "FPS: " .. math.floor(frameCount / timeAcc)
            frameCount = 0
            timeAcc = 0
        end
        local stat = game:GetService("Stats")
        local ping = stat and stat.Network and stat.Network:GetServerStats()
        if ping then
            pingLabel.Text = "Ping: " .. math.floor(ping.Ping)
        end
    end)

    return hudGui, hudConn
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

-- ========== GUI (МЕНЮ) ==========
local function getGuiParent()
    if gethui then return gethui() end
    if game.CoreGui then return game.CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Снежинки
local function createSnowParticles(parent)
    local particles = {}
    for i = 1, 30 do
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(0, math.random(2, 5), 0, math.random(2, 5))
        frame.Position = UDim2.new(math.random() * 0.9, 0, math.random() * 0.8, 0)
        frame.BackgroundColor3 = Color3.new(1, 1, 1)
        frame.BackgroundTransparency = 0.5
        frame.BorderSizePixel = 0
        frame.Rotation = math.random(-30, 30)
        frame.ZIndex = 0
        local info = {
            speed = math.random(2, 5) / 10,
            fall = math.random(2, 5) / 10,
            startX = frame.Position.X.Scale,
            startY = frame.Position.Y.Scale,
            particle = frame,
            rotSpeed = math.random(-2, 2) / 5,
        }
        table.insert(particles, info)
    end
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        for _, p in ipairs(particles) do
            p.particle.Position = UDim2.new(
                p.startX + math.sin(tick() * p.speed + p.particle.Rotation) * 0.1,
                0,
                p.startY + (tick() * p.fall % 0.8) - 0.2,
                0
            )
            p.particle.Rotation = p.particle.Rotation + p.rotSpeed
        end
    end)
    return conn
end

local screenGui
local mainFrame
local function createMainGUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "mat_hub_gui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = getGuiParent()

    mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0, 320, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -175)
    mainFrame.BackgroundColor3 = C.BGDeep
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

    -- Снежинки
    local snowContainer = Instance.new("Frame", mainFrame)
    snowContainer.Size = UDim2.new(1, 0, 1, 0)
    snowContainer.BackgroundTransparency = 1
    snowContainer.ZIndex = 0
    createSnowParticles(snowContainer)

    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = C.AccentGlow
    title.Text = "mat hub"
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.ZIndex = 2

    local closeBtn = Instance.new("TextButton", mainFrame)
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0, 4)
    closeBtn.BackgroundColor3 = C.StateOff
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.Text = "✕"
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = C.TextPrimary
    closeBtn.ZIndex = 2
    closeBtn.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
    end)

    local content = Instance.new("Frame", mainFrame)
    content.Size = UDim2.new(1, -20, 1, -45)
    content.Position = UDim2.new(0, 10, 0, 40)
    content.BackgroundTransparency = 1
    content.ZIndex = 2

    -- Функции для создания элементов
    local function createToggle(label, value, callback)
        local frame = Instance.new("Frame", content)
        frame.Size = UDim2.new(1, 0, 0, 30)
        frame.Position = UDim2.new(0, 0, 0, #content:GetChildren() * 35)
        frame.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextColor3 = C.TextPrimary
        lbl.Text = label
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 65, 0, 26)
        btn.Position = UDim2.new(1, -70, 0, 2)
        btn.BackgroundColor3 = value and C.StateOn or C.BGSurface
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.Text = value and "ON" or "OFF"
        btn.TextSize = 11
        btn.TextColor3 = C.TextPrimary
        btn.Font = Enum.Font.GothamBold

        btn.MouseButton1Click:Connect(function()
            local newVal = not value
            value = newVal
            btn.BackgroundColor3 = value and C.StateOn or C.BGSurface
            btn.Text = value and "ON" or "OFF"
            callback(value)
        end)
    end

    local function createSlider(label, min, max, default, callback)
        local frame = Instance.new("Frame", content)
        frame.Size = UDim2.new(1, 0, 0, 40)
        frame.Position = UDim2.new(0, 0, 0, #content:GetChildren() * 35 + 10)
        frame.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(0.7, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextColor3 = C.TextPrimary
        lbl.Text = label .. " (" .. default .. ")"
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local valueLabel = Instance.new("TextLabel", frame)
        valueLabel.Size = UDim2.new(0, 50, 0, 18)
        valueLabel.Position = UDim2.new(1, -55, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 14
        valueLabel.TextColor3 = C.Accent
        valueLabel.Text = tostring(default)
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right

        local slider = Instance.new("TextButton", frame)
        slider.Size = UDim2.new(1, 0, 0, 8)
        slider.Position = UDim2.new(0, 0, 0, 28)
        slider.BackgroundColor3 = C.BGSurface
        slider.BorderSizePixel = 0
        Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 4)

        local fill = Instance.new("Frame", slider)
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = C.Accent
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

        local dragging = false
        slider.MouseButton1Down:Connect(function() dragging = true end)
        slider.MouseButton1Up:Connect(function() dragging = false end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            local pos = input.Position.X
            local absX = slider.AbsolutePosition.X
            local sizeX = slider.AbsoluteSize.X
            local pct = math.clamp((pos - absX) / sizeX, 0, 1)
            local val = min + (max - min) * pct
            val = math.floor(val)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            lbl.Text = label .. " (" .. val .. ")"
            valueLabel.Text = tostring(val)
            callback(val)
        end)
    end

    -- Добавляем элементы меню
    createToggle("Скорость", State.speedEnabled, function(v)
        State.speedEnabled = v
        toggleSpeed()
    end)

    createSlider("Скорость", 16, 120, State.walkSpeed, function(v)
        setSpeed(v)
        saveConfig()
    end)

    createToggle("Inf Jump", State.infJumpEnabled, function(v)
        toggleInfJump()
    end)

    createToggle("Anti-Ragdoll", State.antiRagdollEnabled, function(v)
        toggleAntiRagdoll()
    end)

    createToggle("BatLock (аимбот)", State.aimbotEnabled, function(v)
        toggleAimbot()
    end)

    createToggle("Player ESP", State.espEnabled, function(v)
        toggleESP()
    end)

    createToggle("HUD (FPS/Ping)", State.hudEnabled, function(v)
        toggleHUD()
    end)

    -- Закрытие по клавише ]
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightBracket then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)
end

-- Загрузка конфига и запуск
loadConfig()
createMainGUI()

-- Применяем сохранённые состояния
if State.speedEnabled then toggleSpeed() end
if State.infJumpEnabled then toggleInfJump() end
if State.antiRagdollEnabled then toggleAntiRagdoll() end
if State.aimbotEnabled then toggleAimbot() end
if State.espEnabled then toggleESP() end
if State.hudEnabled then toggleHUD() end

-- Splash
local splash = Instance.new("ScreenGui")
splash.Name = "mat_splash"
splash.Parent = getGuiParent()
local frame = Instance.new("Frame", splash)
frame.Size = UDim2.new(0, 280, 0, 60)
frame.Position = UDim2.new(0.5, -140, 0.85, 0)
frame.BackgroundColor3 = C.BGDeep
frame.BackgroundTransparency = 0.15
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.TextColor3 = C.AccentGlow
label.Text = "mat hub loaded!"
task.wait(2)
splash:Destroy()

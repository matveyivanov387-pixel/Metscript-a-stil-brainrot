-- met hub для Steal a Brainrot (Speed + Aimbot + Inf Jump + ESP Brainrot)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

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

local State = {
    walkSpeed = 16,
    speedEnabled = false,
    aimbotEnabled = false,
    infJumpEnabled = false,
    espEnabled = false,
}

local espHighlights = {}
local connections = {
    infJump = nil,
    esp = nil,
}

-- ФУНКЦИИ

local function getCharacter()
    return LocalPlayer.Character
end

local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChild("Humanoid")
end

-- Скорость
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
end

-- Бесконечный прыжок
local function toggleInfJump()
    State.infJumpEnabled = not State.infJumpEnabled
    if connections.infJump then
        connections.infJump:Disconnect()
        connections.infJump = nil
    end
    if State.infJumpEnabled then
        connections.infJump = RunService.Heartbeat:Connect(function()
            local h = getHumanoid()
            if h and (h:GetState() == Enum.HumanoidStateType.Jumping or h:GetState() == Enum.HumanoidStateType.Freefall) then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

-- Aimbot (наведение на игроков + авто-удар)
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
end

-- ESP самого дорогого брейнрота
local function getMostExpensiveBrainrot()
    local mostExpensive = nil
    local maxPrice = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("PriceTag") then
            local price = tonumber(v.PriceTag.Text:gsub("[^0-9]", "")) or 0
            if price > maxPrice then
                maxPrice = price
                mostExpensive = v
            end
        end
    end
    return mostExpensive
end

local function clearESP()
    for _, highlight in ipairs(espHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    espHighlights = {}
end

local function updateESP()
    clearESP()
    local target = getMostExpensiveBrainrot()
    if target and State.espEnabled then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = target
        highlight.FillColor = C.ESPPink
        highlight.FillTransparency = 0.4
        highlight.Parent = target
        table.insert(espHighlights, highlight)
    end
end

local function toggleESP()
    State.espEnabled = not State.espEnabled
    if not State.espEnabled then
        clearESP()
    else
        updateESP()
    end
end

-- GUI (меню)

local function getGuiParent()
    if gethui then return gethui() end
    if game.CoreGui then return game.CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function createMainGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "met_hub_gui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = getGuiParent()

    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0, 300, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
    mainFrame.BackgroundColor3 = C.BGDeep
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = C.AccentGlow
    title.Text = "met hub"
    title.TextXAlignment = Enum.TextXAlignment.Center

    local closeBtn = Instance.new("TextButton", mainFrame)
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 3)
    closeBtn.BackgroundColor3 = C.StateOff
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.Text = "✕"
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = C.TextPrimary
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    local content = Instance.new("Frame", mainFrame)
    content.Size = UDim2.new(1, -20, 1, -40)
    content.Position = UDim2.new(0, 10, 0, 35)
    content.BackgroundTransparency = 1

    local function createToggle(label, key, value, callback)
        local frame = Instance.new("Frame", content)
        frame.Size = UDim2.new(1, 0, 0, 30)
        frame.Position = UDim2.new(0, 0, 0, #content:GetChildren() * 32)
        frame.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextColor3 = C.TextPrimary
        lbl.Text = label
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 60, 0, 26)
        btn.Position = UDim2.new(1, -65, 0, 2)
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
            if callback then callback(value) end
        end)
    end

    local function createSlider(label, min, max, default, callback)
        local frame = Instance.new("Frame", content)
        frame.Size = UDim2.new(1, 0, 0, 40)
        frame.Position = UDim2.new(0, 0, 0, #content:GetChildren() * 42)
        frame.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextColor3 = C.TextPrimary
        lbl.Text = label .. " (" .. default .. ")"
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local valueLabel = Instance.new("TextLabel", frame)
        valueLabel.Size = UDim2.new(0, 40, 0, 18)
        valueLabel.Position = UDim2.new(1, -45, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 12
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
        slider.MouseButton1Down:Connect(function()
            dragging = true
        end)
        slider.MouseButton1Up:Connect(function()
            dragging = false
        end)
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
            if callback then callback(val) end
        end)
    end

    createToggle("Скорость", "speed", State.speedEnabled, function(v)
        State.speedEnabled = v
        toggleSpeed()
    end)

    createSlider("Скорость", 16, 120, State.walkSpeed, function(v)
        setSpeed(v)
    end)

    createToggle("Бесконечный прыжок", "infJump", State.infJumpEnabled, function(v)
        toggleInfJump()
    end)

    createToggle("Aimbot (бита)", "aimbot", State.aimbotEnabled, function(v)
        toggleAimbot()
    end)

    createToggle("ESP (дорогой брейнрот)", "esp", State.espEnabled, function(v)
        toggleESP()
    end)
end

-- Aimbot логика (авто-удар при зажатой левой кнопке мыши)
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

-- Обновление ESP при изменении объектов
if connections.esp then
    connections.esp:Disconnect()
    connections.esp = nil
end
connections.esp = RunService.Heartbeat:Connect(function()
    if State.espEnabled then
        updateESP()
    end
end)

-- Запуск GUI
createMainGUI()

-- Splash-сообщение
local splash = Instance.new("ScreenGui")
splash.Name = "met_splash"
splash.Parent = getGuiParent()
local frame = Instance.new("Frame", splash)
frame.Size = UDim2.new(0, 250, 0, 60)
frame.Position = UDim2.new(0.5, -125, 0.85, 0)
frame.BackgroundColor3 = C.BGDeep
frame.BackgroundTransparency = 0.15
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.TextColor3 = C.AccentGlow
label.Text = "met hub loaded!"
task.wait(2)
splash:Destroy()

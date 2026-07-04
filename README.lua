-- mat hub (Rayfield GUI + все функции)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Http = game:GetService("HttpService")
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

local function save()
    local cfg = {}
    for k, v in pairs(State) do cfg[k] = v end
    pcall(function() writefile(CONFIG_FILE, Http:JSONEncode(cfg)) end)
end

local function load()
    if not isfile or not isfile(CONFIG_FILE) then return end
    local ok, raw = pcall(function() return readfile(CONFIG_FILE) end)
    if ok and raw then
        local ok2, cfg = pcall(Http.JSONDecode, Http, raw)
        if ok2 and cfg then
            for k, v in pairs(cfg) do
                if State[k] ~= nil then State[k] = v end
            end
        end
    end
end

local function getChar() return LP.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChild("Humanoid")
end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ========== SPEED ==========
local function applySpeed()
    local h = getHum()
    if h then h.WalkSpeed = State.speedEnabled and State.walkSpeed or 16 end
end

local function toggleSpeed()
    State.speedEnabled = not State.speedEnabled
    applySpeed()
    save()
end

local function setSpeed(v)
    State.walkSpeed = v
    applySpeed()
    save()
end

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    applySpeed()
end)

-- ========== INF JUMP ==========
local infConn = nil
local function toggleInfJump()
    State.infJumpEnabled = not State.infJumpEnabled
    if infConn then infConn:Disconnect(); infConn = nil end
    if State.infJumpEnabled then
        infConn = RunService.Heartbeat:Connect(function()
            local h = getHum()
            if h and (h:GetState() == Enum.HumanoidStateType.Jumping or h:GetState() == Enum.HumanoidStateType.Freefall) then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
    save()
end

-- ========== ANTI-RAGDOLL ==========
local function toggleAntiRagdoll()
    State.antiRagdollEnabled = not State.antiRagdollEnabled
    save()
end

RunService.Heartbeat:Connect(function()
    if not State.antiRagdollEnabled then return end
    local c = getChar()
    if c then
        local h = c:FindFirstChild("Humanoid")
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
    save()
end

-- ========== BATLOCK ==========
local function getClosestPlayer()
    local hrp = getHRP()
    if not hrp then return nil end
    local closest, dist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local t = plr.Character:FindFirstChild("HumanoidRootPart")
            if t then
                local d = (t.Position - hrp.Position).Magnitude
                if d < dist then closest, dist = plr, d end
            end
        end
    end
    return closest
end

local function toggleAimbot()
    State.aimbotEnabled = not State.aimbotEnabled
    save()
end

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and State.aimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character then
            local c = getChar()
            if c then
                local tool = c:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end
        end
    end
end)

-- ========== ESP ==========
local espList = {}
local function clearESP()
    for _, h in ipairs(espList) do if h and h.Parent then h:Destroy() end end
    espList = {}
end

local function updateESP()
    if not State.espEnabled then return end
    clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local c = plr.Character
            if c then
                local h = Instance.new("Highlight")
                h.Adornee = c
                h.FillColor = Color3.fromRGB(255, 100, 175)
                h.FillTransparency = 0.3
                h.OutlineColor = Color3.fromRGB(255, 80, 200)
                h.OutlineTransparency = 0.2
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = c
                table.insert(espList, h)
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
    save()
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

    local f = Instance.new("Frame", hudGui)
    f.Size = UDim2.new(0, 160, 0, 44)
    f.Position = UDim2.new(0.5, -80, 0, 10)
    f.BackgroundColor3 = Color3.fromRGB(12, 4, 10)
    f.BackgroundTransparency = 0.2
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", f)
    title.Size = UDim2.new(1, 0, 0, 14)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 10
    title.TextColor3 = Color3.fromRGB(255, 80, 200)
    title.Text = "mat hub"
    title.TextXAlignment = Enum.TextXAlignment.Center

    local fps = Instance.new("TextLabel", f)
    fps.Size = UDim2.new(0.5, 0, 0, 14)
    fps.Position = UDim2.new(0, 0, 0, 18)
    fps.BackgroundTransparency = 1
    fps.Font = Enum.Font.Gotham
    fps.TextSize = 12
    fps.TextColor3 = Color3.fromRGB(245, 235, 242)
    fps.Text = "FPS: 0"
    fps.TextXAlignment = Enum.TextXAlignment.Center

    local ping = Instance.new("TextLabel", f)
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
        local g, c = createHUD()
        hudConn = c
    else
        if hudGui then hudGui:Destroy(); hudGui = nil end
        if hudConn then hudConn:Disconnect(); hudConn = nil end
    end
    save()
end

-- ========== GUI (Rayfield) ==========
local function getGuiParent()
    if gethui then return gethui() end
    return CoreGui
end

local function createMainGUI()
    if not Rayfield then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()
    end

    local Win = Rayfield:CreateWindow({
        Name = "mat hub",
        LoadingTitle = "Загрузка...",
        LoadingSubtitle = "by matspeqa",
        ConfigurationSaving = { Enabled = true, FolderName = "mat_hub", FileName = "Config" },
        KeySystem = false
    })

    local Main = Win:CreateTab("Основные", nil)
    Main:CreateSection("Движение")

    Main:CreateToggle({
        Name = "Скорость",
        CurrentValue = State.speedEnabled,
        Callback = function(v)
            State.speedEnabled = v
            toggleSpeed()
        end
    })

    Main:CreateSlider({
        Name = "Скорость",
        Range = { 16, 120 },
        Increment = 1,
        Suffix = "Speed",
        CurrentValue = State.walkSpeed,
        Callback = function(v)
            setSpeed(v)
        end
    })

    Main:CreateToggle({
        Name = "Inf Jump",
        CurrentValue = State.infJumpEnabled,
        Callback = function(v)
            State.infJumpEnabled = v
            toggleInfJump()
        end
    })

    Main:CreateToggle({
        Name = "Anti-Ragdoll",
        CurrentValue = State.antiRagdollEnabled,
        Callback = function(v)
            State.antiRagdollEnabled = v
            toggleAntiRagdoll()
        end
    })

    Main:CreateToggle({
        Name = "Aimbot (BatLock)",
        CurrentValue = State.aimbotEnabled,
        Callback = function(v)
            State.aimbotEnabled = v
            toggleAimbot()
        end
    })

    Main:CreateToggle({
        Name = "Player ESP",
        CurrentValue = State.espEnabled,
        Callback = function(v)
            State.espEnabled = v
            toggleESP()
        end
    })

    Main:CreateToggle({
        Name = "HUD (FPS/Ping)",
        CurrentValue = State.hudEnabled,
        Callback = function(v)
            State.hudEnabled = v
            toggleHUD()
        end
    })

    Main:CreateToggle({
        Name = "Оптимизация FPS",
        CurrentValue = State.optimizeEnabled,
        Callback = function(v)
            State.optimizeEnabled = v
            toggleOptimize()
        end
    })
end

load()
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
local f = Instance.new("Frame", splash)
f.Size = UDim2.new(0, 280, 0, 60)
f.Position = UDim2.new(0.5, -140, 0.85, 0)
f.BackgroundColor3 = Color3.fromRGB(12, 4, 10)
f.BackgroundTransparency = 0.15
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
local l = Instance.new("TextLabel", f)
l.Size = UDim2.new(1, 0, 1, 0)
l.BackgroundTransparency = 1
l.Font = Enum.Font.GothamBold
l.TextSize = 18
l.TextColor3 = Color3.fromRGB(255, 80, 200)
l.Text = "mat hub loaded!"
task.wait(2)
splash:Destroy()

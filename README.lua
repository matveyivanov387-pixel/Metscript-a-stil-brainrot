task.defer(function()
    repeat task.wait() until game:IsLoaded()
    task.wait(1)
    local Players = game:GetService('Players')
    local CoreGui = game:GetService('CoreGui')
    local TweenService = game:GetService('TweenService')
    local ui = Instance.new('ScreenGui')
    ui.ResetOnSpawn = false
    ui.Name = tostring(math.random(1000000, 9999999)) .. tostring(math.random(1000000, 9999999))
    ui.DisplayOrder = 100
    local image = Instance.new('ImageLabel')
    image.BackgroundTransparency = 1
    image.AnchorPoint = Vector2.new(0, 1)
    image.Position = UDim2.new(0, -200, 0.9, 0)
    image.Size = UDim2.fromOffset(200, 150)
    image.BorderSizePixel = 0
    if getcustomasset and writefile then
        writefile('kurtisimg.png', game:HttpGet('https://github.com/anowerrrr333-star/imgforscript/blob/main/Frame%201.png?raw=true'))
        image.Image = getcustomasset('kurtisimg.png')
    end
    image.Parent = ui
    ui.Parent = gethui and gethui() or CoreGui or Players.LocalPlayer:WaitForChild('PlayerGui')
    local initialPosition = image.Position
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(image, tweenInfo, {Position = UDim2.new(0.05, 0, 0.9, 0)}):Play()
    task.wait(0.5 + 7)
    TweenService:Create(image, tweenInfo, {Position = initialPosition}):Play()
    task.wait(0.5)
    ui:Destroy()
end)

task.defer(function()
    repeat task.wait() until game:IsLoaded()
    task.wait(1)
    local Players = game:GetService('Players')
    local CoreGui = game:GetService('CoreGui')
    local TweenService = game:GetService('TweenService')
    local ui = Instance.new('ScreenGui')
    ui.ResetOnSpawn = false
    ui.Name = tostring(math.random(1000000, 9999999)) .. tostring(math.random(1000000, 9999999))
    ui.DisplayOrder = 100
    local image = Instance.new('ImageLabel')
    image.BackgroundTransparency = 1
    image.AnchorPoint = Vector2.new(0, 1)
    image.Position = UDim2.new(0, -200, 0.9, 0)
    image.Size = UDim2.fromOffset(200, 150)
    image.BorderSizePixel = 0
    if getcustomasset and writefile then
        writefile('kurtisimg.png', game:HttpGet('https://github.com/anowerrrr333-star/imgforscript/blob/main/Frame%201.png?raw=true'))
        image.Image = getcustomasset('kurtisimg.png')
    end
    image.Parent = ui
    ui.Parent = gethui and gethui() or CoreGui or Players.LocalPlayer:WaitForChild('PlayerGui')
    local initialPosition = image.Position
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(image, tweenInfo, {Position = UDim2.new(0.05, 0, 0.9, 0)}):Play()
    task.wait(0.5 + 7)
    TweenService:Create(image, tweenInfo, {Position = initialPosition}):Play()
    task.wait(0.5)
    ui:Destroy()
end)

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ContextActionService = game:GetService("ContextActionService")
local PathfindingService = game:GetService("PathfindingService")
local Stats = game:GetService("Stats")
local lp = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "mat_hub_v1"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local COLORS = {
    MainBG = Color3.fromRGB(11, 14, 20),
    TabBG = Color3.fromRGB(15, 20, 28),
    Border = Color3.fromRGB(0, 170, 0),
    TextActive = Color3.fromRGB(0, 170, 0),
    TextInactive = Color3.fromRGB(140, 140, 140),
    RowBG = Color3.fromRGB(18, 24, 35)
}

local function create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            obj[k] = v
        end
    end
    obj.Parent = props.Parent
    return obj
end

local configFile = "mat_hub_v1_config.json"
local Config = {}
local ToggleStates = {}
local LockUIMove = false
local Keybinds = {}

local ToggleIcon, MainFrame, AntiRagdoll, XrayBase, NoAnim, PlayerESP, InfiniteJump, AutoSteal, WalkFling, NoPlayerCollision, AutoBat, AutoMedusa, Drop, ManualTp, Float, Taunt, SpeedVisual, Fov, TpDown

local PLOT3_POS = Vector3.new(-476.7524719238281, 10.464664459228516, 7.107429504394531)
local PLOT7_POS = Vector3.new(-476.7524719238281, 10.464664459228516, 114.10742950439453)
local FINAL_POS1 = Vector3.new(-483.59, -5.04, 104.24)
local FINAL_POS2 = Vector3.new(-483.51, -5.10, 18.89)
local CHECKPOINT_A = Vector3.new(-472.60, -7.00, 57.52)
local CHECKPOINT_B1 = Vector3.new(-472.65, -7.00, 95.69)
local CHECKPOINT_B2 = Vector3.new(-471.76, -7.00, 26.22)

Float = {
    Enabled = false,
    platform = nil,
    lockedHeight = nil,
    heartbeatConn = nil,
    characterConn = nil,
    gui = nil,
    btn = nil
}
Taunt = {Enabled = false, gui = nil, btn = nil}
SpeedVisual = {Enabled = false, speedBB = nil, heartbeatConn = nil}
Fov = {Enabled = false, loopConn = nil}
TpDown = {Enabled = false, btn = nil, gui = nil}
AutoMedusa = {Enabled = false, medusaPart = nil, lastUse = 0, initialized = false}
InfiniteJump = {Enabled = true, jumpForce = 54, clampFallSpeed = 130}

local function savePositionOnDrag(uiElement, configKey)
    if not uiElement then return end
    uiElement:GetPropertyChangedSignal("Position"):Connect(function()
        if Config.Positions then
            Config.Positions[configKey] = {
                uiElement.Position.X.Scale,
                uiElement.Position.X.Offset,
                uiElement.Position.Y.Scale,
                uiElement.Position.Y.Offset
            }
            saveConfig()
        end
    end)
end

local function createSpeedVisual()
    local char = lp.Character or lp.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    if SpeedVisual.speedBB then
        SpeedVisual.speedBB:Destroy()
    end
    SpeedVisual.speedBB = Instance.new("BillboardGui")
    SpeedVisual.speedBB.Adornee = hrp
    SpeedVisual.speedBB.Size = UDim2.new(0, 120, 0, 36)
    SpeedVisual.speedBB.StudsOffset = Vector3.new(0, 4.5, 0)
    SpeedVisual.speedBB.AlwaysOnTop = true
    SpeedVisual.speedBB.Parent = hrp
    local lbl = Instance.new("TextLabel", SpeedVisual.speedBB)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0
    lbl.TextScaled = true
    lbl.Text = "Speed: 0"
end

local function toggleSpeedVisual()
    SpeedVisual.Enabled = not SpeedVisual.Enabled
    if SpeedVisual.Enabled then
        createSpeedVisual()
        lp.CharacterAdded:Connect(function()
            task.wait(0.5)
            if SpeedVisual.Enabled then
                createSpeedVisual()
            end
        end)
        if not SpeedVisual.heartbeatConn then
            SpeedVisual.heartbeatConn = RunService.Heartbeat:Connect(function()
                if not SpeedVisual.Enabled then return end
                local char = lp.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                if not SpeedVisual.speedBB or not SpeedVisual.speedBB.Parent then
                    createSpeedVisual()
                end
                local lbl = SpeedVisual.speedBB and SpeedVisual.speedBB:FindFirstChildOfClass("TextLabel")
                if not lbl then return end
                local v = hrp.AssemblyLinearVelocity
                lbl.Text = "Speed: " .. math.floor(Vector3.new(v.X, 0, v.Z).Magnitude)
            end)
        end
    else
        if SpeedVisual.heartbeatConn then
            SpeedVisual.heartbeatConn:Disconnect()
            SpeedVisual.heartbeatConn = nil
        end
        if SpeedVisual.speedBB then
            SpeedVisual.speedBB:Destroy()
            SpeedVisual.speedBB = nil
        end
    end
end

local function toggleFov()
    Fov.Enabled = not Fov.Enabled
    if Fov.Enabled then
        if not Fov.loopConn then
            Fov.loopConn = RunService.Heartbeat:Connect(function()
                if not Fov.Enabled then return end
                local cam = workspace.CurrentCamera
                if cam then
                    cam.FieldOfView = 120
                end
            end)
        end
    else
        if Fov.loopConn then
            Fov.loopConn:Disconnect()
            Fov.loopConn = nil
        end
        local cam = workspace.CurrentCamera
        if cam then
            cam.FieldOfView = 70
        end
    end
end

local function updateEsp()
    if not PlayerESP.Enabled then
        for _, h in ipairs(PlayerESP.highlights or {}) do
            if h and h.Parent then
                h:Destroy()
            end
        end
        PlayerESP.highlights = {}
        return
    end
    if not PlayerESP.highlights then
        PlayerESP.highlights = {}
    end
    for _, h in ipairs(PlayerESP.highlights) do
        if h and h.Parent then
            h:Destroy()
        end
    end
    PlayerESP.highlights = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local char = plr.Character
            if char then
                local h = Instance.new("Highlight")
                h.Adornee = char
                h.FillColor = Color3.fromRGB(0, 170, 0)
                h.FillTransparency = 0.4
                h.OutlineColor = Color3.fromRGB(0, 255, 0)
                h.OutlineTransparency = 0.2
                h.Parent = char
                table.insert(PlayerESP.highlights, h)
            end
        end
    end
end

local function togglePlayerEsp()
    PlayerESP.Enabled = not PlayerESP.Enabled
    updateEsp()
    if PlayerESP.Enabled then
        Players.PlayerAdded:Connect(function()
            updateEsp()
        end)
        Players.PlayerRemoving:Connect(function()
            updateEsp()
        end)
    end
end

local function toggleAntiRagdoll()
    AntiRagdoll.Enabled = not AntiRagdoll.Enabled
end

local function toggleXrayBase()
    XrayBase.Enabled = not XrayBase.Enabled
end

local function toggleNoAnim()
    NoAnim.Enabled = not NoAnim.Enabled
end

local function toggleInfiniteJump()
    InfiniteJump.Enabled = not InfiniteJump.Enabled
end

local function toggleAutoSteal()
    AutoSteal.Enabled = not AutoSteal.Enabled
end

local function toggleWalkFling()
    WalkFling.Enabled = not WalkFling.Enabled
end

local function toggleNoPlayerCollision()
    NoPlayerCollision.Enabled = not NoPlayerCollision.Enabled
end

local function toggleAutoBat()
    AutoBat.Enabled = not AutoBat.Enabled
end

local function toggleAutoMedusa()
    AutoMedusa.Enabled = not AutoMedusa.Enabled
end

local function toggleDrop()
    Drop.Enabled = not Drop.Enabled
end

local function toggleManualTp()
    ManualTp.Enabled = not ManualTp.Enabled
end

local function toggleFloat()
    Float.Enabled = not Float.Enabled
    if Float.Enabled then
        if not Float.heartbeatConn then
            Float.heartbeatConn = RunService.Heartbeat:Connect(function()
                if not Float.Enabled then return end
                local char = lp.Character
                if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                if not Float.platform or not Float.platform.Parent then
                    Float.platform = Instance.new("Part")
                    Float.platform.Anchored = true
                    Float.platform.CanCollide = false
                    Float.platform.Transparency = 1
                    Float.platform.Size = Vector3.new(1, 0.5, 1)
                    Float.platform.Parent = workspace
                end
                Float.platform.CFrame = CFrame.new(root.Position + Vector3.new(0, -1.5, 0))
            end)
        end
    else
        if Float.heartbeatConn then
            Float.heartbeatConn:Disconnect()
            Float.heartbeatConn = nil
        end
        if Float.platform then
            Float.platform:Destroy()
            Float.platform = nil
        end
    end
end

local function toggleTaunt()
    Taunt.Enabled = not Taunt.Enabled
end

local function toggleTpDown()
    TpDown.Enabled = not TpDown.Enabled
end

local function saveConfig()
    if not writefile then return end
    local data = {
        ToggleStates = ToggleStates,
        Keybinds = Keybinds,
        Config = Config
    }
    pcall(function()
        writefile(configFile, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    if not isfile or not isfile(configFile) then return end
    local ok, raw = pcall(function()
        return readfile(configFile)
    end)
    if not ok or not raw then return end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not ok2 or not data then return end
    if data.ToggleStates then
        for k, v in pairs(data.ToggleStates) do
            ToggleStates[k] = v
        end
    end
    if data.Keybinds then
        for k, v in pairs(data.Keybinds) do
            Keybinds[k] = v
        end
    end
    if data.Config then
        Config = data.Config
    end
end

local function createToggle(parent, label, configKey, defaultState)
    local row = create("Frame", {
        Parent = parent,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = COLORS.RowBG,
        BackgroundTransparency = 0.3
    })
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = create("TextLabel", {
        Parent = row,
        Size = UDim2.new(0.65, 0, 1, 0),
        Position = UDim2.new(0.04, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = label,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local btn = create("TextButton", {
        Parent = row,
        Size = UDim2.new(0, 65, 0, 28),
        Position = UDim2.new(1, -72, 0.5, -14),
        BackgroundColor3 = ToggleStates[configKey] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0,
        Text = ToggleStates[configKey] and "ON" or "OFF",
        TextSize = 11,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold
    })
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        ToggleStates[configKey] = not ToggleStates[configKey]
        btn.BackgroundColor3 = ToggleStates[configKey] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        btn.Text = ToggleStates[configKey] and "ON" or "OFF"

        if configKey == "AntiRagdoll" then
            toggleAntiRagdoll()
        elseif configKey == "XrayBase" then
            toggleXrayBase()
        elseif configKey == "NoAnim" then
            toggleNoAnim()
        elseif configKey == "PlayerESP" then
            togglePlayerEsp()
        elseif configKey == "InfiniteJump" then
            toggleInfiniteJump()
        elseif configKey == "AutoSteal" then
            toggleAutoSteal()
        elseif configKey == "WalkFling" then
            toggleWalkFling()
        elseif configKey == "NoPlayerCollision" then
            toggleNoPlayerCollision()
        elseif configKey == "AutoBat" then
            toggleAutoBat()
        elseif configKey == "AutoMedusa" then
            toggleAutoMedusa()
        elseif configKey == "Drop" then
            toggleDrop()
        elseif configKey == "ManualTp" then
            toggleManualTp()
        elseif configKey == "Float" then
            toggleFloat()
        elseif configKey == "Taunt" then
            toggleTaunt()
        elseif configKey == "SpeedVisual" then
            toggleSpeedVisual()
        elseif configKey == "Fov" then
            toggleFov()
        elseif configKey == "TpDown" then
            toggleTpDown()
        end
        saveConfig()
    end)

    if defaultState then
        ToggleStates[configKey] = defaultState
        btn.BackgroundColor3 = defaultState and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        btn.Text = defaultState and "ON" or "OFF"
    end
end

local MainFrame = create("Frame", {
    Parent = ScreenGui,
    Size = UDim2.new(0, 280, 0, 420),
    Position = UDim2.new(0.5, -140, 0.5, -210),
    BackgroundColor3 = COLORS.MainBG,
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0
})
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local TitleBar = create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundTransparency = 1
})

local Title = create("TextLabel", {
    Parent = TitleBar,
    Size = UDim2.new(0.8, 0, 1, 0),
    Position = UDim2.new(0.05, 0, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = COLORS.Border,
    Text = "mat hub v 1",
    TextXAlignment = Enum.TextXAlignment.Left
})

local CloseBtn = create("TextButton", {
    Parent = TitleBar,
    Size = UDim2.new(0, 25, 0, 25),
    Position = UDim2.new(1, -30, 0, 3),
    BackgroundColor3 = Color3.fromRGB(60, 60, 60),
    BorderSizePixel = 0,
    Text = "✕",
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
end)

local TabBar = create("Frame", {
    Parent = MainFrame,
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 30),
    BackgroundColor3 = COLORS.TabBG
})

local Tabs = {"Main", "Visual", "Combat", "Other"}
local TabButtons = {}
local TabContents = {}

for i, name in ipairs(Tabs) do
    local btn = create("TextButton", {
        Parent = TabBar,
        Size = UDim2.new(0.25, 0, 1, 0),
        Position = UDim2.new((i - 1) * 0.25, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = COLORS.TextInactive,
        Text = name
    })
    btn.MouseButton1Click:Connect(function()
        for _, b in ipairs(TabButtons) do
            b.TextColor3 = COLORS.TextInactive
        end
        btn.TextColor3 = COLORS.TextActive
        for _, c in ipairs(TabContents) do
            c.Visible = false
        end
        TabContents[i].Visible = true
    end)
    table.insert(TabButtons, btn)

    local content = create("ScrollingFrame", {
        Parent = MainFrame,
        Size = UDim2.new(1, -20, 1, -90),
        Position = UDim2.new(0, 10, 0, 65),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = (i == 1)
    })
    Instance.new("UIListLayout", content).Padding = UDim.new(0, 6)
    table.insert(TabContents, content)
end

createToggle(TabContents[1], "Infinite Jump", "InfiniteJump", true)
createToggle(TabContents[1], "Anti-Ragdoll", "AntiRagdoll", false)
createToggle(TabContents[1], "No Anim", "NoAnim", false)
createToggle(TabContents[1], "Walk Fling", "WalkFling", false)

createToggle(TabContents[2], "Player ESP", "PlayerESP", false)
createToggle(TabContents[2], "Speed Visual", "SpeedVisual", false)
createToggle(TabContents[2], "FOV (120)", "Fov", false)

createToggle(TabContents[3], "Auto Steal", "AutoSteal", false)
createToggle(TabContents[3], "Auto Bat", "AutoBat", false)
createToggle(TabContents[3], "Auto Medusa", "AutoMedusa", false)
createToggle(TabContents[3], "Drop", "Drop", false)

createToggle(TabContents[4], "No Player Collision", "NoPlayerCollision", false)
createToggle(TabContents[4], "Manual TP", "ManualTp", false)
createToggle(TabContents[4], "Float", "Float", false)
createTogg

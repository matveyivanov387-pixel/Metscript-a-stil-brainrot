-- mat hub (Rayfield, все функции из Chiraq)
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local LP=Players.LocalPlayer
local Http=game:GetService("HttpService")
local CoreGui=game:GetService("CoreGui")
local Stats=game:GetService("Stats")

pcall(function()
    if CoreGui:FindFirstChild("mat_hub_gui") then CoreGui.mat_hub_gui:Destroy() end
    if CoreGui:FindFirstChild("mat_hud") then CoreGui.mat_hud:Destroy() end
end)

local State={speedEnabled=false,walkSpeed=30,infJumpEnabled=false,antiRagdollEnabled=false,aimbotEnabled=false,espEnabled=false,hudEnabled=false,flyEnabled=false}
local CONFIG_FILE="mat_config.json"

local function save()
    local cfg={}
    for k,v in pairs(State) do cfg[k]=v end
    pcall(function() writefile(CONFIG_FILE, Http:JSONEncode(cfg)) end)
end

local function load()
    if not isfile or not isfile(CONFIG_FILE) then return end
    local ok, raw=pcall(readfile, CONFIG_FILE)
    if ok and raw then
        local ok2, cfg=pcall(Http.JSONDecode, Http, raw)
        if ok2 and cfg then
            for k,v in pairs(cfg) do if State[k]~=nil then State[k]=v end end
        end
    end
end

local function getChar() return LP.Character end
local function getHRP() local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=getChar() return c and c:FindFirstChild("Humanoid") end

local function applySpeed()
    local h=getHum()
    if h then h.WalkSpeed = State.speedEnabled and State.walkSpeed or 16 end
end

local function toggleSpeed()
    State.speedEnabled=not State.speedEnabled
    applySpeed()
    save()
end

local function setSpeed(v)
    State.walkSpeed=v
    applySpeed()
    save()
end

local function toggleInfJump()
    State.infJumpEnabled=not State.infJumpEnabled
    save()
end

UIS.JumpRequest:Connect(function()
    if State.infJumpEnabled then
        local h=getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local function toggleAntiRagdoll()
    State.antiRagdollEnabled=not State.antiRagdollEnabled
    save()
end

RunService.Heartbeat:Connect(function()
    if not State.antiRagdollEnabled then return end
    local char=getChar()
    if char then
        local h=char:FindFirstChild("Humanoid")
        if h then
            h.AutoRotate=true
            h.PlatformStand=false
            if h:GetState()==Enum.HumanoidStateType.Physics then
                h:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end)

local flyBV, flyConn
local function toggleFly()
    State.flyEnabled=not State.flyEnabled
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if State.flyEnabled then
        local char=getChar()
        if char then
            local root=char:FindFirstChild("HumanoidRootPart")
            if root then
                flyBV=Instance.new("BodyVelocity")
                flyBV.MaxForce=Vector3.new(4000,4000,4000)
                flyBV.Parent=root
                flyConn=RunService.RenderStepped:Connect(function()
                    if not State.flyEnabled then return end
                    local c=getChar()
                    if not c then return end
                    local r=c:FindFirstChild("HumanoidRootPart")
                    if not r then return end
                    local move=Vector3.new()
                    if UIS:IsKeyDown(Enum.KeyCode.W) then move=move+r.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.S) then move=move-r.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then move=move-r.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.D) then move=move+r.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.Space) then move=move+Vector3.new(0,1,0) end
                    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move=move-Vector3.new(0,1,0) end
                    if move.Magnitude>0 then flyBV.Velocity=move.Unit*60 else flyBV.Velocity=Vector3.new(0,0,0) end
                end)
            end
        end
    end
    save()
end

local function getClosestPlayer()
    local hrp=getHRP()
    if not hrp then return nil end
    local closest, dist=nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr~=LP and plr.Character then
            local targetHRP=plr.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local d=(targetHRP.Position-hrp.Position).Magnitude
                if d<dist then closest, dist=plr, d end
            end
        end
    end
    return closest
end

local function toggleAimbot()
    State.aimbotEnabled=not State.aimbotEnabled
    save()
end

UIS.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 and State.aimbotEnabled then
        local target=getClosestPlayer()
        if target and target.Character then
            local char=getChar()
            if char then
                local tool=char:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end
        end
    end
end)

local espHighlights={}
local espConns={}

local function clearESP()
    for _,h in ipairs(espHighlights) do if h and h.Parent then h:Destroy() end end
    espHighlights={}
    for _,c in ipairs(espConns) do if c then c:Disconnect() end end
    espConns={}
end

local function updateESP()
    if not State.espEnabled then return end
    clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr~=LP then
            local char=plr.Character
            if char then
                local h=Instance.new("Highlight")
                h.Adornee=char
                h.FillColor=Color3.fromRGB(255,100,200)
                h.FillTransparency=0.3
                h.OutlineColor=Color3.new(1,1,1)
                h.OutlineTransparency=0.2
                h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent=char
                table.insert(espHighlights,h)
            end
            local conn=plr.CharacterAdded:Connect(function(newChar)
                task.wait(0.5)
                if not State.espEnabled then return end
                local h=Instance.new("Highlight")
                h.Adornee=newChar
                h.FillColor=Color3.fromRGB(255,100,200)
                h.FillTransparency=0.3
                h.OutlineColor=Color3.new(1,1,1)
                h.OutlineTransparency=0.2
                h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent=newChar
                table.insert(espHighlights,h)
            end)
            table.insert(espConns,conn)
        end
    end
end

local function toggleESP()
    State.espEnabled=not State.espEnabled
    if State.espEnabled then
        updateESP()
        table.insert(espConns, Players.PlayerAdded:Connect(function() updateESP() end))
    else
        clearESP()
    end
    save()
end

RunService.Heartbeat:Connect(function()
    if State.espEnabled then updateESP() end
end)

local hudGui, hudConn
local function createHUD()
    if hudGui then hudGui:Destroy() end
    hudGui=Instance.new("ScreenGui")
    hudGui.Name="mat_hud"
    hudGui.Parent=CoreGui
    local frame=Instance.new("Frame",hudGui)
    frame.Size=UDim2.new(0,160,0,44)
    frame.Position=UDim2.new(0.5,-80,0,10)
    frame.BackgroundColor3=Color3.fromRGB(6,6,10)
    frame.BackgroundTransparency=0.2
    frame.BorderSizePixel=0
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,8)
    local title=Instance.new("TextLabel",frame)
    title.Size=UDim2.new(1,0,0,14)
    title.Position=UDim2.new(0,0,0,2)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.GothamBlack
    title.TextSize=10
    title.TextColor3=Color3.fromRGB(255,80,200)
    title.Text="mat hub"
    title.TextXAlignment=Enum.TextXAlignment.Center
    local fps=Instance.new("TextLabel",frame)
    fps.Size=UDim2.new(0.5,0,0,14)
    fps.Position=UDim2.new(0,0,0,18)
    fps.BackgroundTransparency=1
    fps.Font=Enum.Font.Gotham
    fps.TextSize=12
    fps.TextColor3=Color3.fromRGB(245,245,245)
    fps.Text="FPS: 0"
    fps.TextXAlignment=Enum.TextXAlignment.Center
    local ping=Instance.new("TextLabel",frame)
    ping.Size=UDim2.new(0.5,0,0,14)
    ping.Position=UDim2.new(0.5,0,0,18)
    ping.BackgroundTransparency=1
    ping.Font=Enum.Font.Gotham
    ping.TextSize=12
    ping.TextColor3=Color3.fromRGB(160,160,180)
    ping.Text="Ping: 0"
    ping.TextXAlignment=Enum.TextXAlignment.Center
    local cnt=0; local acc=0
    local conn=RunService.RenderStepped:Connect(function(dt)
        acc=acc+dt; cnt=cnt+1
        if acc>=0.5 then
            fps.Text="FPS: "..math.floor(cnt/acc)
            cnt=0; acc=0
        end
        local s=Stats.Network:GetServerStats()
        if s then ping.Text="Ping: "..math.floor(s.Ping) end
    end)
    return hudGui, conn
end

local function toggleHUD()
    State.hudEnabled=not State.hudEnabled
    if State.hudEnabled then
        local gui, conn=createHUD()
        hudConn=conn
    else
        if hudGui then hudGui:Destroy(); hudGui=nil end
        if hudConn then hudConn:Disconnect(); hudConn=nil end
    end
    save()
end

-- GUI
local function getGuiParent()
    if gethui then return gethui() end
    return CoreGui
end

local function createMainGUI()
    if not Rayfield then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()
    end
    local Window=Rayfield:CreateWindow({
        Name="mat hub",
        LoadingTitle="Загрузка...",
        LoadingSubtitle="by matspeqa",
        ConfigurationSaving={Enabled=true,FolderName="mat_hub",FileName="Config"},
        KeySystem=false
    })
    local MainTab=Window:CreateTab("Основные", nil)
    MainTab:CreateSection("Движение")
    MainTab:CreateToggle({Name="Скорость", CurrentValue=State.speedEnabled, Callback=function(v)
        State.speedEnabled=v
        toggleSpeed()
    end})
    MainTab:CreateSlider({Name="Скорость", Range={16,120}, Increment=1, Suffix="Speed", CurrentValue=State.walkSpeed, Callback=function(v)
        setSpeed(v)
    end})
    MainTab:CreateToggle({Name="Inf Jump", CurrentValue=State.infJumpEnabled, Callback=function(v)
        State.infJumpEnabled=v
        toggleInfJump()
    end})
    MainTab:CreateToggle({Name="Fly", CurrentValue=State.flyEnabled, Callback=function(v)
        State.flyEnabled=v
        toggleFly()
    end})
    MainTab:CreateToggle({Name="Anti-Ragdoll", CurrentValue=State.antiRagdollEnabled, Callback=function(v)
        State.antiRagdollEnabled=v
        toggleAntiRagdoll()
    end})
    MainTab:CreateToggle({Name="Aimbot (BatLock)", CurrentValue=State.aimbotEnabled, Callback=function(v)
        State.aimbotEnabled=v
        toggleAimbot()
    end})
    MainTab:CreateToggle({Name="Player ESP", CurrentValue=State.espEnabled, Callback=function(v)
        State.espEnabled=v
        toggleESP()
    end})
    MainTab:CreateToggle({Name="HUD (FPS/Ping)", CurrentValue=State.hudEnabled, Callback=function(v)
        State.hudEnabled=v
        toggleHUD()
    end})
end

load()
createMainGUI()
if State.speedEnabled then toggleSpeed() end
if State.infJumpEnabled then toggleInfJump() end
if State.antiRagdollEnabled then toggleAntiRagdoll() end
if State.aimbotEnabled then toggleAimbot() end
if State.espEnabled then toggleESP() end
if State.hudEnabled then toggleHUD() end
if State.flyEnabled then toggleFly() end

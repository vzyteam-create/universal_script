--[[
    VANEZY HUB v2 - Auto Chest Farm
    ПОЛНЫЙ СКРИПТ С НАСТРОЙКАМИ, АНТИ-АФК, СОХРАНЕНИЕМ, СВОРАЧИВАНИЕМ РАЗДЕЛОВ
    Координаты сундука: (-55.20, -360.41, 9488.14)
--]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

-- Константы
local chestPosition = Vector3.new(-55.20, -360.41, 9488.14)
local flyHeight = 500
local maxFlySpeed = 1000

-- Переменные состояния
getgenv().AutoChest = false
getgenv().FlyingActive = false
getgenv().FlySpeedPercent = 52 -- По умолчанию 80%
getgenv().AntiAFK = false
getgenv().AntiAFKTime = 0 -- 0 = навсегда
getgenv().SaveSettings = false
getgenv().AntiAFKCoroutine = nil
getgenv().AntiAFKEndTime = 0

-- Функция расчёта скорости
local function getFlySpeed()
    return math.floor(maxFlySpeed * getgenv().FlySpeedPercent / 100)
end

-- Очистка старого GUI
if CoreGui:FindFirstChild("VanezyHub") then CoreGui:FindFirstChild("VanezyHub"):Destroy() end
if CoreGui:FindFirstChild("VanezyNotif") then CoreGui:FindFirstChild("VanezyNotif"):Destroy() end
if CoreGui:FindFirstChild("VanezyToggle") then CoreGui:FindFirstChild("VanezyToggle"):Destroy() end

-- =============================================
-- СОХРАНЕНИЕ НАСТРОЕК
-- =============================================
local function saveSettings()
    if not getgenv().SaveSettings then return end
    local settings = {
        flySpeedPercent = getgenv().FlySpeedPercent,
        antiAFK = getgenv().AntiAFK,
        antiAFKTime = getgenv().AntiAFKTime,
        saveSettings = getgenv().SaveSettings,
    }
    pcall(function()
        writefile("VanezyHub_Settings.json", game:GetService("HttpService"):JSONEncode(settings))
    end)
end

local function loadSettings()
    if not getgenv().SaveSettings then return end
    local success, data = pcall(function()
        return readfile("VanezyHub_Settings.json")
    end)
    if success and data then
        local settings = game:GetService("HttpService"):JSONDecode(data)
        if settings.flySpeedPercent then getgenv().FlySpeedPercent = settings.flySpeedPercent end
        if settings.antiAFK ~= nil then getgenv().AntiAFK = settings.antiAFK end
        if settings.antiAFKTime then getgenv().AntiAFKTime = settings.antiAFKTime end
        if settings.saveSettings ~= nil then getgenv().SaveSettings = settings.saveSettings end
    end
end

-- Загружаем настройки при старте
loadSettings()

-- =============================================
-- АНТИ-АФК
-- =============================================
local function startAntiAFK(duration)
    stopAntiAFK()
    getgenv().AntiAFKEndTime = duration > 0 and (os.time() + duration * 60) or 0
    getgenv().AntiAFKCoroutine = task.spawn(function()
        while getgenv().AntiAFK do
            -- Проверка времени
            if getgenv().AntiAFKEndTime > 0 and os.time() >= getgenv().AntiAFKEndTime then
                getgenv().AntiAFK = false
                getgenv().AntiAFKCoroutine = nil
                createNotification("Anti AFK", "Anti afk is turned <font color='rgb(255,80,80)' size='14'>off</font> after the time has expired", 5)
                updateAllToggles()
                break
            end
            -- Действие анти-АФК
            pcall(function() VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame) task.wait(0.1) VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame) end)
            task.wait(10)
        end
    end)
end

local function stopAntiAFK()
    if getgenv().AntiAFKCoroutine then
        task.cancel(getgenv().AntiAFKCoroutine)
        getgenv().AntiAFKCoroutine = nil
    end
end

-- =============================================
-- УВЕДОМЛЕНИЯ
-- =============================================
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "VanezyNotif"
NotifGui.ResetOnSpawn = false
NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotifGui.DisplayOrder = 999
NotifGui.Parent = CoreGui

local activeNotifications = {}

function createNotification(title, message, duration, customButtons)
    duration = duration or 5
    if #activeNotifications >= 5 then
        local oldest = table.remove(activeNotifications, 1)
        if oldest and oldest.Parent then
            oldest:TweenPosition(UDim2.new(0.5, -135, 0, -80), "In", "Quad", 0.2, true)
            task.delay(0.2, function() if oldest.Parent then oldest:Destroy() end end)
        end
    end
    local nf = Instance.new("Frame")
    nf.Size = UDim2.new(0, 270, 0, customButtons and 90 or 62)
    nf.Position = UDim2.new(0.5, -135, 0, -80)
    nf.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    nf.BorderSizePixel = 0
    nf.ClipsDescendants = true
    nf.Parent = NotifGui
    Instance.new("UICorner", nf).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", nf).Color = Color3.fromRGB(40, 40, 40)
    Instance.new("UIStroke", nf).Thickness = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, customButtons and -12 or -35, 0, 20)
    titleLabel.Position = UDim2.new(0, 12, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = nf
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -35, 0, customButtons and 20 or 18)
    msgLabel.Position = UDim2.new(0, 12, 0, 28)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 9
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.RichText = true
    msgLabel.Parent = nf
    
    if not customButtons then
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 18, 0, 18)
        closeBtn.Position = UDim2.new(1, -24, 0, 7)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 13
        closeBtn.Parent = nf
        closeBtn.MouseButton1Click:Connect(closeNotification)
    end
    
    local timeLine = Instance.new("Frame")
    timeLine.Size = UDim2.new(1, 0, 0, 2)
    timeLine.Position = UDim2.new(0, 0, 1, -2)
    timeLine.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
    timeLine.BorderSizePixel = 0
    timeLine.Parent = nf
    
    local yPos = 5 + (#activeNotifications * (customButtons and 100 or 72))
    TweenService:Create(nf, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -135, 0, yPos)
    }):Play()
    
    local lineTween = TweenService:Create(timeLine, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    })
    lineTween:Play()
    
    function closeNotification()
        local ht = TweenService:Create(nf, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -135, 0, -80)
        })
        ht:Play()
        ht.Completed:Connect(function()
            nf:Destroy()
            local idx = table.find(activeNotifications, nf)
            if idx then table.remove(activeNotifications, idx) end
            for i, n in ipairs(activeNotifications) do
                TweenService:Create(n, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0.5, -135, 0, 5 + ((i-1) * (customButtons and 100 or 72)))
                }):Play()
            end
        end)
    end
    
    if customButtons then
        local btnFrame = Instance.new("Frame")
        btnFrame.Size = UDim2.new(1, 0, 0, 30)
        btnFrame.Position = UDim2.new(0, 0, 0, 52)
        btnFrame.BackgroundTransparency = 1
        btnFrame.Parent = nf
        
        local yesBtn = Instance.new("TextButton")
        yesBtn.Size = UDim2.new(0, 80, 0, 26)
        yesBtn.Position = UDim2.new(0.5, -90, 0.5, -13)
        yesBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
        yesBtn.BorderSizePixel = 0
        yesBtn.Text = "✅"
        yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        yesBtn.Font = Enum.Font.GothamBold
        yesBtn.TextSize = 18
        yesBtn.Parent = btnFrame
        Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 8)
        
        local noFrame = Instance.new("Frame")
        noFrame.Size = UDim2.new(0, 80, 0, 26)
        noFrame.Position = UDim2.new(0.5, 10, 0.5, -13)
        noFrame.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        noFrame.BorderSizePixel = 0
        noFrame.Parent = btnFrame
        Instance.new("UICorner", noFrame).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", noFrame).Color = Color3.fromRGB(255, 0, 0)
        Instance.new("UIStroke", noFrame).Thickness = 2
        
        local noBtn = Instance.new("TextButton")
        noBtn.Size = UDim2.new(1, 0, 1, 0)
        noBtn.BackgroundTransparency = 1
        noBtn.Text = "❌"
        noBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        noBtn.Font = Enum.Font.GothamBold
        noBtn.TextSize = 20
        noBtn.Parent = noFrame
        
        return nf, yesBtn, noBtn, closeNotification
    end
    
    task.delay(duration, function()
        if nf and nf.Parent then closeNotification() end
    end)
    
    table.insert(activeNotifications, nf)
    return nf
end

function copyToClipboard(text, label)
    if pcall(function() setclipboard(text) end) then
        createNotification("Notification", "✅ Copied: " .. (label or text), 5)
    end
end

-- =============================================
-- КРУГЛАЯ КНОПКА
-- =============================================
local ToggleBtnGui = Instance.new("ScreenGui")
ToggleBtnGui.Name = "VanezyToggle"
ToggleBtnGui.ResetOnSpawn = false
ToggleBtnGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleBtnGui.Parent = CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 40, 0, 40)
ToggleBtn.Position = UDim2.new(0, 12, 0.5, -20)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "V"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBlack
ToggleBtn.TextSize = 17
ToggleBtn.Parent = ToggleBtnGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

local btnDragging = false
local btnDragStart, btnStartPos = nil, nil
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true
        btnDragStart = input.Position
        btnStartPos = ToggleBtn.Position
    end
end)
UIS.InputEnded:Connect(function() btnDragging = false end)
UIS.InputChanged:Connect(function(input)
    if btnDragging then
        local delta = input.Position - btnDragStart
        ToggleBtn.Position = UDim2.new(btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y)
    end
end)

-- =============================================
-- ГЛАВНЫЙ GUI (420×300)
-- =============================================
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "VanezyHub"
MainGui.ResetOnSpawn = false
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.Parent = CoreGui

local GUI_WIDTH = 420
local GUI_HEIGHT = 300

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, GUI_WIDTH, 0, GUI_HEIGHT)
MainFrame.Position = UDim2.new(0, 40, 0.5, -GUI_HEIGHT/2)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.BackgroundTransparency = 1
MainFrame.Parent = MainGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

MainFrame.BackgroundTransparency = 1
MainFrame.Size = UDim2.new(0, GUI_WIDTH, 0, 0)
MainFrame.Position = UDim2.new(0, 40, 0.5, 0)
TweenService:Create(MainFrame, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0,
    Size = UDim2.new(0, GUI_WIDTH, 0, GUI_HEIGHT),
    Position = UDim2.new(0, 40, 0.5, -GUI_HEIGHT/2)
}):Play()

-- =============================================
-- ЗАГОЛОВОК
-- =============================================
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Header.BorderSizePixel = 0
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local HubTitle = Instance.new("TextLabel")
HubTitle.Size = UDim2.new(1, -55, 0, 22)
HubTitle.Position = UDim2.new(0, 14, 0, 5)
HubTitle.BackgroundTransparency = 1
HubTitle.Text = "Vanezy Hub v1"
HubTitle.TextColor3 = Color3.fromRGB(255, 80, 80)
HubTitle.Font = Enum.Font.GothamBlack
HubTitle.TextSize = 17
HubTitle.TextXAlignment = Enum.TextXAlignment.Left
HubTitle.Parent = Header

local HubSub = Instance.new("TextLabel")
HubSub.Size = UDim2.new(1, -55, 0, 14)
HubSub.Position = UDim2.new(0, 14, 0, 27)
HubSub.BackgroundTransparency = 1
HubSub.Text = "by vanezy scripts"
HubSub.TextColor3 = Color3.fromRGB(100, 100, 100)
HubSub.Font = Enum.Font.Gotham
HubSub.TextSize = 9
HubSub.TextXAlignment = Enum.TextXAlignment.Left
HubSub.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -30, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(230, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "x"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextSize = 15
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -60, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 30)
MinBtn.BorderSizePixel = 0
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.TextSize = 16
MinBtn.Parent = Header
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

-- Статус-бар
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(0, 0, 0, 26)
StatusBar.Position = UDim2.new(1, -95, 0, 4)
StatusBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
StatusBar.BorderSizePixel = 0
StatusBar.ClipsDescendants = true
StatusBar.BackgroundTransparency = 1
StatusBar.Parent = Header
Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 8)

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(0, 120, 1, 0)
StatusText.Position = UDim2.new(0, 8, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = ""
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 9
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = StatusBar

local StatusToggleBg = Instance.new("Frame")
StatusToggleBg.Size = UDim2.new(0, 34, 0, 18)
StatusToggleBg.Position = UDim2.new(0, 135, 0.5, -9)
StatusToggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
StatusToggleBg.BorderSizePixel = 0
StatusToggleBg.Visible = false
StatusToggleBg.Parent = StatusBar
Instance.new("UICorner", StatusToggleBg).CornerRadius = UDim.new(1, 0)

local StatusToggleDot = Instance.new("Frame")
StatusToggleDot.Size = UDim2.new(0, 14, 0, 14)
StatusToggleDot.Position = UDim2.new(0, 2, 0.5, -7)
StatusToggleDot.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
StatusToggleDot.Parent = StatusToggleBg
Instance.new("UICorner", StatusToggleDot).CornerRadius = UDim.new(1, 0)

-- Перетаскивание
local winDragging = false
local winDragStart, winStartPos = nil, nil
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        winDragging = true
        winDragStart = input.Position
        winStartPos = MainFrame.Position
    end
end)
UIS.InputEnded:Connect(function() winDragging = false end)
UIS.InputChanged:Connect(function(input)
    if winDragging then
        local delta = input.Position - winDragStart
        MainFrame.Position = UDim2.new(winStartPos.X.Scale, winStartPos.X.Offset + delta.X, winStartPos.Y.Scale, winStartPos.Y.Offset + delta.Y)
    end
end)

-- =============================================
-- БОКОВАЯ ПАНЕЛЬ
-- =============================================
local SIDEBAR_WIDTH = 140
local SIDEBAR_COLLAPSED_WIDTH = 45

local SidePanel = Instance.new("Frame")
SidePanel.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -48)
SidePanel.Position = UDim2.new(0, 0, 0, 48)
SidePanel.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
SidePanel.BorderSizePixel = 0
SidePanel.ClipsDescendants = true
SidePanel.Parent = MainFrame

local ContentPanel = Instance.new("Frame")
ContentPanel.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -48)
ContentPanel.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, 48)
ContentPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
ContentPanel.BorderSizePixel = 0
ContentPanel.ClipsDescendants = true
ContentPanel.Parent = MainFrame

-- Кнопка сворачивания разделов
local CollapseBtn = Instance.new("TextButton")
CollapseBtn.Size = UDim2.new(0, 20, 0, 20)
CollapseBtn.Position = UDim2.new(0, SIDEBAR_WIDTH - 22, 1, -48)
CollapseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CollapseBtn.BorderSizePixel = 0
CollapseBtn.Text = "◀"
CollapseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CollapseBtn.Font = Enum.Font.GothamBold
CollapseBtn.TextSize = 10
CollapseBtn.ZIndex = 10
CollapseBtn.Parent = MainFrame
Instance.new("UICorner", CollapseBtn).CornerRadius = UDim.new(0, 4)

local sidebarCollapsed = false

-- =============================================
-- ВКЛАДКИ
-- =============================================
local Tabs = {
    {Name = "Home", Icon = "🏠"},
    {Name = "Main", Icon = "⚙️"},
}

local TabButtons = {}
local TabContents = {}
local TabIconsOnly = {}
local currentTab = nil

-- Создание вкладок
for i, tab in ipairs(Tabs) do
    -- Полная кнопка
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, -14, 0, 34)
    tabBtn.Position = UDim2.new(0, 7, 0, 7 + (i-1) * 40)
    tabBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    tabBtn.BorderSizePixel = 0
    tabBtn.Text = "  " .. tab.Icon .. "  " .. tab.Name
    tabBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 12
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    tabBtn.Parent = SidePanel
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

    -- Кнопка только с иконкой
    local iconBtn = Instance.new("TextButton")
    iconBtn.Size = UDim2.new(0, 32, 0, 32)
    iconBtn.Position = UDim2.new(0.5, -16, 0, 7 + (i-1) * 40)
    iconBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    iconBtn.BorderSizePixel = 0
    iconBtn.Text = tab.Icon
    iconBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    iconBtn.Font = Enum.Font.GothamBold
    iconBtn.TextSize = 16
    iconBtn.Visible = false
    iconBtn.Parent = SidePanel
    Instance.new("UICorner", iconBtn).CornerRadius = UDim.new(0, 6)

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Visible = false
    content.Parent = ContentPanel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    content.ChildAdded:Connect(function()
        local totalH = 0
        for _, child in pairs(content:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
                totalH = totalH + child.AbsoluteSize.Y + 5
            end
        end
        content.CanvasSize = UDim2.new(0, 0, 0, totalH + 10)
    end)

    TabButtons[tab.Name] = tabBtn
    TabContents[tab.Name] = content
    TabIconsOnly[tab.Name] = iconBtn

    local function switchToTab()
        if currentTab == tab.Name then return end
        currentTab = tab.Name
        for _, cnt in pairs(TabContents) do cnt.Visible = false end
        for _, btn in pairs(TabButtons) do btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22) btn.TextColor3 = Color3.fromRGB(180, 180, 180) end
        for _, btn in pairs(TabIconsOnly) do btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22) btn.TextColor3 = Color3.fromRGB(180, 180, 180) end
        task.delay(0.05, function()
            content.Visible = true
            tabBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            iconBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            iconBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
    end

    tabBtn.MouseButton1Click:Connect(switchToTab)
    iconBtn.MouseButton1Click:Connect(switchToTab)
end

-- =============================================
-- КНОПКА НАСТРОЕК СНИЗУ СЛЕВА
-- =============================================
local SettingsBtn = Instance.new("TextButton")
SettingsBtn.Size = UDim2.new(0, 32, 0, 32)
SettingsBtn.Position = UDim2.new(0, 6, 1, -38)
SettingsBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SettingsBtn.BorderSizePixel = 0
SettingsBtn.Text = "⚙️"
SettingsBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
SettingsBtn.Font = Enum.Font.GothamBold
SettingsBtn.TextSize = 16
SettingsBtn.ZIndex = 5
SettingsBtn.Parent = SidePanel
Instance.new("UICorner", SettingsBtn).CornerRadius = UDim.new(0, 6)

-- Разворачивающаяся кнопка Settings
local SettingsExpanded = Instance.new("Frame")
SettingsExpanded.Size = UDim2.new(0, 0, 0, 32)
SettingsExpanded.Position = UDim2.new(0, 40, 1, -38)
SettingsExpanded.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SettingsExpanded.BorderSizePixel = 0
SettingsExpanded.ClipsDescendants = true
SettingsExpanded.Parent = SidePanel
Instance.new("UICorner", SettingsExpanded).CornerRadius = UDim.new(0, 6)

local SettingsExpandedBtn = Instance.new("TextButton")
SettingsExpandedBtn.Size = UDim2.new(0, 80, 1, 0)
SettingsExpandedBtn.Position = UDim2.new(0, 0, 0, 0)
SettingsExpandedBtn.BackgroundTransparency = 1
SettingsExpandedBtn.Text = "Settings"
SettingsExpandedBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
SettingsExpandedBtn.Font = Enum.Font.GothamBold
SettingsExpandedBtn.TextSize = 12
SettingsExpandedBtn.Parent = SettingsExpanded

local settingsOpen = false

SettingsBtn.MouseButton1Click:Connect(function()
    settingsOpen = not settingsOpen
    if settingsOpen then
        SettingsExpanded:TweenSize(UDim2.new(0, 85, 0, 32), "Out", "Quad", 0.25, true)
    else
        SettingsExpanded:TweenSize(UDim2.new(0, 0, 0, 32), "Out", "Quad", 0.25, true)
    end
end)

-- Контент настроек
local SettingsContent = Instance.new("ScrollingFrame")
SettingsContent.Size = UDim2.new(1, 0, 1, 0)
SettingsContent.BackgroundTransparency = 1
SettingsContent.ScrollBarThickness = 3
SettingsContent.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
SettingsContent.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsContent.Visible = false
SettingsContent.Parent = ContentPanel

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 5)
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Parent = SettingsContent

SettingsContent.ChildAdded:Connect(function()
    local totalH = 0
    for _, child in pairs(SettingsContent:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
            totalH = totalH + child.AbsoluteSize.Y + 5
        end
    end
    SettingsContent.CanvasSize = UDim2.new(0, 0, 0, totalH + 10)
end)

SettingsExpandedBtn.MouseButton1Click:Connect(function()
    for _, cnt in pairs(TabContents) do cnt.Visible = false end
    for _, btn in pairs(TabButtons) do btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22) btn.TextColor3 = Color3.fromRGB(180, 180, 180) end
    for _, btn in pairs(TabIconsOnly) do btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22) btn.TextColor3 = Color3.fromRGB(180, 180, 180) end
    SettingsContent.Visible = true
    currentTab = "Settings"
end)

-- =============================================
-- ЗАГОЛОВКИ РАЗДЕЛОВ
-- =============================================
local function createSectionHeader(parent, text)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, -16, 0, 22)
    header.BackgroundTransparency = 1
    header.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 80, 80)
    label.Font = Enum.Font.GothamBlack
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = header
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, 0)
    line.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    line.BorderSizePixel = 0
    line.Parent = header
end

-- =============================================
-- HOME
-- =============================================
createSectionHeader(TabContents["Home"], "Home")

local homeContent = TabContents["Home"]

local function createLink(parent, text, url)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -16, 0, 36)
    f.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    f.BorderSizePixel = 0
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 1, 0)
    btn.Position = UDim2.new(0, 10, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(130, 190, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = f
    btn.MouseButton1Click:Connect(function() copyToClipboard(url, url) end)
end

local function createDivider(parent)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -16, 0, 1)
    d.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    d.BorderSizePixel = 0
    d.Parent = parent
    local g = Instance.new("UIGradient", d)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 180, 180)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 80)),
    })
end

createLink(homeContent, "Channel: https://t.me/VanezyScripts", "https://t.me/VanezyScripts")
createDivider(homeContent)
createLink(homeContent, "Creator: @vanezy", "https://t.me/vanezy")
createDivider(homeContent)
createLink(homeContent, "Friends: https://t.me/ScriptRobox", "https://t.me/ScriptRobox")
createDivider(homeContent)

local bugLabel = Instance.new("TextLabel")
bugLabel.Size = UDim2.new(1, -16, 0, 38)
bugLabel.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
bugLabel.BorderSizePixel = 0
bugLabel.Text = "⚠️ This script has just started\nand there may be bugs, sorry."
bugLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
bugLabel.Font = Enum.Font.Gotham
bugLabel.TextSize = 10
bugLabel.TextWrapped = true
bugLabel.Parent = homeContent
Instance.new("UICorner", bugLabel).CornerRadius = UDim.new(0, 6)

-- =============================================
-- MAIN
-- =============================================
createSectionHeader(TabContents["Main"], "Main")

local mainContent = TabContents["Main"]

-- Статус
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, -16, 0, 30)
statusFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
statusFrame.BorderSizePixel = 0
statusFrame.Parent = mainContent
Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 6)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⏸ Ожидание"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 11
statusLabel.Parent = statusFrame

-- Тоггл авто-сундука
local toggleFrame = Instance.new("Frame")
toggleFrame.Size = UDim2.new(1, -16, 0, 42)
toggleFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
toggleFrame.BorderSizePixel = 0
toggleFrame.Parent = mainContent
Instance.new("UICorner", toggleFrame).CornerRadius = UDim.new(0, 6)

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(0.6, 0, 1, 0)
toggleLabel.Position = UDim2.new(0, 10, 0, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "Avto chest"
toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleLabel.Font = Enum.Font.GothamBold
toggleLabel.TextSize = 13
toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
toggleLabel.Parent = toggleFrame

local toggleBg = Instance.new("Frame")
toggleBg.Size = UDim2.new(0, 44, 0, 24)
toggleBg.Position = UDim2.new(1, -54, 0.5, -12)
toggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBg.BorderSizePixel = 0
toggleBg.Parent = toggleFrame
Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)

local toggleDot = Instance.new("Frame")
toggleDot.Size = UDim2.new(0, 20, 0, 20)
toggleDot.Position = UDim2.new(0, 2, 0.5, -10)
toggleDot.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
toggleDot.BorderSizePixel = 0
toggleDot.Parent = toggleBg
Instance.new("UICorner", toggleDot).CornerRadius = UDim.new(1, 0)

-- Слайдер скорости (проценты)
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1, -16, 0, 46)
speedFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
speedFrame.BorderSizePixel = 0
speedFrame.Parent = mainContent
Instance.new("UICorner", speedFrame).CornerRadius = UDim.new(0, 6)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -12, 0, 18)
speedLabel.Position = UDim2.new(0, 10, 0, 4)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: " .. getgenv().FlySpeedPercent .. "% (" .. getFlySpeed() .. ")"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 10
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedFrame

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, -24, 0, 6)
sliderBg.Position = UDim2.new(0, 12, 0, 26)
sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = speedFrame
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(getgenv().FlySpeedPercent / 100, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local sliderDot = Instance.new("TextButton")
sliderDot.Size = UDim2.new(0, 14, 0, 14)
sliderDot.Position = UDim2.new(getgenv().FlySpeedPercent / 100, -7, 0, -4)
sliderDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderDot.BorderSizePixel = 0
sliderDot.Text = ""
sliderDot.Parent = sliderBg
Instance.new("UICorner", sliderDot).CornerRadius = UDim.new(1, 0)

local sliderDragging = false
sliderDot.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliderDragging = true end
end)
sliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        local p = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        getgenv().FlySpeedPercent = math.floor(p * 100)
        sliderFill.Size = UDim2.new(p, 0, 1, 0)
        sliderDot.Position = UDim2.new(p, -7, 0, -4)
        speedLabel.Text = "Speed: " .. getgenv().FlySpeedPercent .. "% (" .. getFlySpeed() .. ")"
        saveSettings()
    end
end)
UIS.InputEnded:Connect(function() sliderDragging = false end)
UIS.InputChanged:Connect(function(input)
    if sliderDragging then
        local p = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        getgenv().FlySpeedPercent = math.floor(p * 100)
        sliderFill.Size = UDim2.new(p, 0, 1, 0)
        sliderDot.Position = UDim2.new(p, -7, 0, -4)
        speedLabel.Text = "Speed: " .. getgenv().FlySpeedPercent .. "% (" .. getFlySpeed() .. ")"
        saveSettings()
    end
end)

-- =============================================
-- SETTINGS
-- =============================================
createSectionHeader(SettingsContent, "Settings")

-- Anti AFK
local antiAFKFrame = Instance.new("Frame")
antiAFKFrame.Size = UDim2.new(1, -16, 0, 42)
antiAFKFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
antiAFKFrame.BorderSizePixel = 0
antiAFKFrame.Parent = SettingsContent
Instance.new("UICorner", antiAFKFrame).CornerRadius = UDim.new(0, 6)

local antiAFKLabel = Instance.new("TextLabel")
antiAFKLabel.Size = UDim2.new(0.5, 0, 1, 0)
antiAFKLabel.Position = UDim2.new(0, 10, 0, 0)
antiAFKLabel.BackgroundTransparency = 1
antiAFKLabel.Text = "Anti AFK"
antiAFKLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
antiAFKLabel.Font = Enum.Font.GothamBold
antiAFKLabel.TextSize = 13
antiAFKLabel.TextXAlignment = Enum.TextXAlignment.Left
antiAFKLabel.Parent = antiAFKFrame

local antiAFKToggleBg = Instance.new("Frame")
antiAFKToggleBg.Size = UDim2.new(0, 44, 0, 24)
antiAFKToggleBg.Position = UDim2.new(1, -90, 0.5, -12)
antiAFKToggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
antiAFKToggleBg.BorderSizePixel = 0
antiAFKToggleBg.Parent = antiAFKFrame
Instance.new("UICorner", antiAFKToggleBg).CornerRadius = UDim.new(1, 0)

local antiAFKToggleDot = Instance.new("Frame")
antiAFKToggleDot.Size = UDim2.new(0, 20, 0, 20)
antiAFKToggleDot.Position = UDim2.new(0, 2, 0.5, -10)
antiAFKToggleDot.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
antiAFKToggleDot.Parent = antiAFKToggleBg
Instance.new("UICorner", antiAFKToggleDot).CornerRadius = UDim.new(1, 0)

-- Стрелочка для доп настроек
local antiAFKArrow = Instance.new("TextButton")
antiAFKArrow.Size = UDim2.new(0, 20, 0, 20)
antiAFKArrow.Position = UDim2.new(1, -35, 0.5, -10)
antiAFKArrow.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
antiAFKArrow.BorderSizePixel = 0
antiAFKArrow.Text = "▼"
antiAFKArrow.TextColor3 = Color3.fromRGB(200, 200, 200)
antiAFKArrow.Font = Enum.Font.GothamBold
antiAFKArrow.TextSize = 10
antiAFKArrow.Parent = antiAFKFrame
Instance.new("UICorner", antiAFKArrow).CornerRadius = UDim.new(0, 4)

-- Выпадающий список времени
local antiAFKDropdown = Instance.new("Frame")
antiAFKDropdown.Size = UDim2.new(1, -16, 0, 0)
antiAFKDropdown.Position = UDim2.new(0, 8, 1, 0)
antiAFKDropdown.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
antiAFKDropdown.BorderSizePixel = 0
antiAFKDropdown.ClipsDescendants = true
antiAFKDropdown.Visible = false
antiAFKDropdown.ZIndex = 10
antiAFKDropdown.Parent = SettingsContent
Instance.new("UICorner", antiAFKDropdown).CornerRadius = UDim.new(0, 6)

local dropdownList = Instance.new("UIListLayout")
dropdownList.Parent = antiAFKDropdown

local antiAFKOpen = false
local antiAFKSelectedTime = getgenv().AntiAFKTime
local confirmButtons = nil

-- Функция создания опций времени
local function createTimeOptions()
    for _, child in pairs(antiAFKDropdown:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") and child ~= antiAFKDropdown:FindFirstChild("UIListLayout") then
            child:Destroy()
        end
    end
    confirmButtons = nil
    
    local times = {0, 40, 60, 80, 100, 120, 140, 160, 180, 200}
    local timeNames = {"Forever", "40 minutes", "60 minutes", "80 minutes", "100 minutes", "120 minutes", "140 minutes", "160 minutes", "180 minutes", "200 minutes"}
    
    for i, t in ipairs(times) do
        local optFrame = Instance.new("Frame")
        optFrame.Size = UDim2.new(1, 0, 0, 30)
        optFrame.BackgroundColor3 = t == antiAFKSelectedTime and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(25, 25, 25)
        optFrame.BorderSizePixel = 0
        optFrame.Parent = antiAFKDropdown
        
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, -50, 1, 0)
        optBtn.Position = UDim2.new(0, 5, 0, 0)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = timeNames[i]
        optBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 11
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.Parent = optFrame
        optBtn.MouseButton1Click:Connect(function()
            antiAFKSelectedTime = t
            createTimeOptions()
            -- Показываем кнопки подтверждения
            if not confirmButtons then
                confirmButtons = Instance.new("Frame")
                confirmButtons.Size = UDim2.new(1, 0, 0, 30)
                confirmButtons.BackgroundTransparency = 1
                confirmButtons.Parent = antiAFKDropdown
                
                local confirmYes = Instance.new("TextButton")
                confirmYes.Size = UDim2.new(0, 60, 0, 24)
                confirmYes.Position = UDim2.new(0.5, -70, 0.5, -12)
                confirmYes.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
                confirmYes.BorderSizePixel = 0
                confirmYes.Text = "✅"
                confirmYes.TextColor3 = Color3.fromRGB(255, 255, 255)
                confirmYes.Font = Enum.Font.GothamBold
                confirmYes.TextSize = 14
                confirmYes.Parent = confirmButtons
                Instance.new("UICorner", confirmYes).CornerRadius = UDim.new(0, 6)
                confirmYes.MouseButton1Click:Connect(function()
                    getgenv().AntiAFKTime = antiAFKSelectedTime
                    if getgenv().AntiAFK then
                        stopAntiAFK()
                        startAntiAFK(getgenv().AntiAFKTime)
                    end
                    createNotification("Anti AFK", "✅ Activated", 3)
                    antiAFKDropdown.Visible = false
                    antiAFKOpen = false
                    antiAFKArrow.Text = "▼"
                    saveSettings()
                end)
                
                local confirmNo = Instance.new("TextButton")
                confirmNo.Size = UDim2.new(0, 60, 0, 24)
                confirmNo.Position = UDim2.new(0.5, 10, 0.5, -12)
                confirmNo.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
                confirmNo.BorderSizePixel = 0
                confirmNo.Text = "x"
                confirmNo.TextColor3 = Color3.fromRGB(255, 255, 255)
                confirmNo.Font = Enum.Font.GothamBold
                confirmNo.TextSize = 14
                confirmNo.Parent = confirmButtons
                Instance.new("UICorner", confirmNo).CornerRadius = UDim.new(0, 6)
                Instance.new("UIStroke", confirmNo).Color = Color3.fromRGB(255, 0, 0)
                Instance.new("UIStroke", confirmNo).Thickness = 2
                confirmNo.MouseButton1Click:Connect(function()
                    antiAFKSelectedTime = getgenv().AntiAFKTime
                    createTimeOptions()
                    confirmButtons:Destroy()
                    confirmButtons = nil
                end)
            end
        end)
    end
end

createTimeOptions()

antiAFKArrow.MouseButton1Click:Connect(function()
    antiAFKOpen = not antiAFKOpen
    if antiAFKOpen then
        antiAFKDropdown.Visible = true
        antiAFKDropdown:TweenSize(UDim2.new(1, -16, 0, 30 * 10 + 40), "Out", "Quad", 0.2, true)
        antiAFKArrow.Text = "▲"
    else
        antiAFKDropdown:TweenSize(UDim2.new(1, -16, 0, 0), "Out", "Quad", 0.2, true)
        task.delay(0.2, function() antiAFKDropdown.Visible = false end)
        antiAFKArrow.Text = "▼"
    end
end)

-- Save Settings
local saveFrame = Instance.new("Frame")
saveFrame.Size = UDim2.new(1, -16, 0, 42)
saveFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
saveFrame.BorderSizePixel = 0
saveFrame.Parent = SettingsContent
Instance.new("UICorner", saveFrame).CornerRadius = UDim.new(0, 6)

local saveLabel = Instance.new("TextLabel")
saveLabel.Size = UDim2.new(0.5, 0, 1, 0)
saveLabel.Position = UDim2.new(0, 10, 0, 0)
saveLabel.BackgroundTransparency = 1
saveLabel.Text = "Save Settings"
saveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
saveLabel.Font = Enum.Font.GothamBold
saveLabel.TextSize = 13
saveLabel.TextXAlignment = Enum.TextXAlignment.Left
saveLabel.Parent = saveFrame

local saveToggleBg = Instance.new("Frame")
saveToggleBg.Size = UDim2.new(0, 44, 0, 24)
saveToggleBg.Position = UDim2.new(1, -54, 0.5, -12)
saveToggleBg.BackgroundColor3 = getgenv().SaveSettings and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(50, 50, 50)
saveToggleBg.BorderSizePixel = 0
saveToggleBg.Parent = saveFrame
Instance.new("UICorner", saveToggleBg).CornerRadius = UDim.new(1, 0)

local saveToggleDot = Instance.new("Frame")
saveToggleDot.Size = UDim2.new(0, 20, 0, 20)
saveToggleDot.Position = getgenv().SaveSettings and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
saveToggleDot.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
saveToggleDot.Parent = saveToggleBg
Instance.new("UICorner", saveToggleDot).CornerRadius = UDim.new(1, 0)

-- Reset All Settings
local resetFrame = Instance.new("Frame")
resetFrame.Size = UDim2.new(1, -16, 0, 36)
resetFrame.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
resetFrame.BorderSizePixel = 0
resetFrame.Parent = SettingsContent
Instance.new("UICorner", resetFrame).CornerRadius = UDim.new(0, 6)

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(1, 0, 1, 0)
resetBtn.BackgroundTransparency = 1
resetBtn.Text = "Reset all settings"
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 12
resetBtn.Parent = resetFrame

-- =============================================
-- ФУНКЦИЯ ОБНОВЛЕНИЯ ВСЕХ ТОГГЛОВ
-- =============================================
local function updateAllToggles()
    -- Main toggle
    if getgenv().AutoChest then
        toggleBg.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        toggleDot.Position = UDim2.new(1, -22, 0.5, -10)
        StatusToggleBg.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        StatusToggleDot.Position = UDim2.new(1, -16, 0.5, -7)
    else
        toggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        toggleDot.Position = UDim2.new(0, 2, 0.5, -10)
        StatusToggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        StatusToggleDot.Position = UDim2.new(0, 2, 0.5, -7)
    end
    
    -- Anti AFK toggle
    if getgenv().AntiAFK then
        antiAFKToggleBg.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        antiAFKToggleDot.Position = UDim2.new(1, -22, 0.5, -10)
    else
        antiAFKToggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        antiAFKToggleDot.Position = UDim2.new(0, 2, 0.5, -10)
    end
    
    -- Save toggle
    if getgenv().SaveSettings then
        saveToggleBg.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        saveToggleDot.Position = UDim2.new(1, -22, 0.5, -10)
    else
        saveToggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        saveToggleDot.Position = UDim2.new(0, 2, 0.5, -10)
    end
end

-- Применяем начальное состояние
updateAllToggles()

-- =============================================
-- ОБРАБОТЧИКИ ТОГГЛОВ
-- =============================================

-- Основной тоггл авто-сундука
toggleBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        getgenv().AutoChest = not getgenv().AutoChest
        updateAllToggles()
        updateStatusBar()
        if getgenv().AutoChest then
            statusLabel.Text = "🚀 Запуск..."
            StatusText.Text = "🚀 Запуск..."
            if not getgenv().FlyingActive and isAwayFromChest() then
                flyToChest()
            end
        else
            stopFlying()
            statusLabel.Text = "⏸ Остановлен"
            StatusText.Text = "⏸ Остановлен"
        end
        saveSettings()
    end
end)

-- Мини-тоггл в статус-баре
StatusToggleBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        getgenv().AutoChest = not getgenv().AutoChest
        updateAllToggles()
        updateStatusBar()
        if getgenv().AutoChest then
            if not getgenv().FlyingActive and isAwayFromChest() then
                flyToChest()
            end
        else
            stopFlying()
        end
        saveSettings()
    end
end)

-- Anti AFK toggle
antiAFKToggleBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        getgenv().AntiAFK = not getgenv().AntiAFK
        updateAllToggles()
        if getgenv().AntiAFK then
            startAntiAFK(getgenv().AntiAFKTime)
        else
            stopAntiAFK()
        end
        saveSettings()
    end
end)

-- Save Settings toggle
saveToggleBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        getgenv().SaveSettings = not getgenv().SaveSettings
        updateAllToggles()
        if getgenv().SaveSettings then
            saveSettings()
        end
    end
end)

-- Reset All Settings
resetBtn.MouseButton1Click:Connect(function()
    local nf, yesBtn, noBtn, closeNotif = createNotification("Reset Settings", "Are you sure you want to reset all settings?", 10, true)
    yesBtn.MouseButton1Click:Connect(function()
        closeNotif()
        getgenv().FlySpeedPercent = 80
        getgenv().AntiAFK = false
        getgenv().AntiAFKTime = 0
        getgenv().SaveSettings = false
        stopAntiAFK()
        updateAllToggles()
        speedLabel.Text = "Скорость: " .. getgenv().FlySpeedPercent .. "% (" .. getFlySpeed() .. ")"
        sliderFill.Size = UDim2.new(getgenv().FlySpeedPercent / 100, 0, 1, 0)
        sliderDot.Position = UDim2.new(getgenv().FlySpeedPercent / 100, -7, 0, -4)
        antiAFKSelectedTime = 0
        createTimeOptions()
        pcall(function() delfile("VanezyHub_Settings.json") end)
        createNotification("Settings", "✅ All settings have been reset", 3)
    end)
    noBtn.MouseButton1Click:Connect(function() closeNotif() end)
end)

-- =============================================
-- ПОЛЁТ
-- =============================================
local flyCoroutine = nil

local function stopFlying()
    getgenv().FlyingActive = false
    if flyCoroutine then task.cancel(flyCoroutine) flyCoroutine = nil end
    local char = Player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if hrp:FindFirstChild("FlyVelocity") then hrp.FlyVelocity:Destroy() end
            if hrp:FindFirstChild("FlyGyro") then hrp.FlyGyro:Destroy() end
        end
        if char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.LocalTransparencyModifier = 0 part.CanCollide = true end
        end
    end
    statusLabel.Text = "⏸ Остановлен"
    StatusText.Text = "⏸ Остановлен"
end

function isAwayFromChest()
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return true end
    return (char.HumanoidRootPart.Position - chestPosition).Magnitude > 10
end

local function flyToChest()
    stopFlying()
    getgenv().FlyingActive = true
    flyCoroutine = task.spawn(function()
        local char = Player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
            statusLabel.Text = "❌ Нет персонажа"
            StatusText.Text = "❌ Нет персонажа"
            getgenv().FlyingActive = false
            return
        end
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.LocalTransparencyModifier = 0.5 part.CanCollide = false end
        end
        statusLabel.Text = "👻 Невидим + Ноклип"
        StatusText.Text = "👻 Невидим + Ноклип"
        local bv = Instance.new("BodyVelocity")
        bv.Name = "FlyVelocity"
        bv.MaxForce = Vector3.new(400000, 400000, 400000)
        bv.P = 10000
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
        local bg = Instance.new("BodyGyro")
        bg.Name = "FlyGyro"
        bg.MaxTorque = Vector3.new(400000, 400000, 400000)
        bg.P = 10000
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
        hum.PlatformStand = true
        local targetAbove = chestPosition + Vector3.new(0, flyHeight, 0)
        statusLabel.Text = "🔼 Летим к сундуку..."
        StatusText.Text = "🔼 Летим к сундуку..."
        local currentSpeed = getFlySpeed()
        local phase1Done = false
        while getgenv().FlyingActive and not phase1Done do
            if not hrp or not hrp.Parent or not hum or hum.Health <= 0 then break end
            local currentPos = hrp.Position
            local direction = targetAbove - currentPos
            local distance = direction.Magnitude
            if distance < 3 then
                bv.Velocity = Vector3.zero
                hrp.CFrame = CFrame.new(targetAbove)
                phase1Done = true
                break
            end
            bv.Velocity = direction.Unit * math.min(currentSpeed, distance * 2)
            bg.CFrame = CFrame.lookAt(currentPos, targetAbove)
            task.wait()
        end
        if not getgenv().FlyingActive then return end
        -- Проверка смерти
        if hum and hum.Health <= 0 then
            getgenv().FlyingActive = false
            StatusText.Text = "💀 Умер, жду респавн..."
            return
        end
        statusLabel.Text = "🔽 Снижаюсь к сундуку..."
        StatusText.Text = "🔽 Снижаюсь к сундуку..."
        task.wait(0.2)
        local phase2Done = false
        while getgenv().FlyingActive and not phase2Done do
            if not hrp or not hrp.Parent or not hum or hum.Health <= 0 then break end
            local currentPos = hrp.Position
            local direction = chestPosition - currentPos
            local distance = direction.Magnitude
            if distance < 2 then
                bv.Velocity = Vector3.zero
                hrp.CFrame = CFrame.new(chestPosition)
                phase2Done = true
                break
            end
            local vel = direction.Unit * math.min(currentSpeed * 0.8, distance * 2)
            if vel.Y > 0 then vel = Vector3.new(vel.X, -math.abs(vel.Y), vel.Z) end
            bv.Velocity = vel
            bg.CFrame = CFrame.lookAt(currentPos, chestPosition)
            task.wait()
        end
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        if hum and hum.PlatformStand then hum.PlatformStand = false end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.LocalTransparencyModifier = 0 part.CanCollide = true end
        end
        getgenv().FlyingActive = false
        -- Проверка смерти
        if hum and hum.Health <= 0 then
            StatusText.Text = "💀 Умер, жду респавн..."
            return
        end
        statusLabel.Text = "🎯 У сундука! Жду..."
        StatusText.Text = "🎯 У сундука! Жду..."
        while getgenv().AutoChest and not isAwayFromChest() do
            local c = Player.Character
            if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then
                local dist = (c.HumanoidRootPart.Position - chestPosition).Magnitude
                if dist > 3 and dist < 10 then
                    c.HumanoidRootPart.CFrame = CFrame.new(chestPosition)
                end
                if c.Humanoid.Health <= 0 then break end
            end
            task.wait(0.5)
        end
        if getgenv().AutoChest and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0 then
            statusLabel.Text = "🔄 Отдалился >10, цикл заново..."
            StatusText.Text = "🔄 Новый цикл..."
        end
    end)
end

-- =============================================
-- СТАТУС-БАР
-- =============================================
local isMinimized = false

function updateStatusBar()
    if isMinimized then
        StatusToggleBg.Visible = true
        StatusBar:TweenSize(UDim2.new(0, 175, 0, 26), "Out", "Quad", 0.25, true)
        StatusBar.Position = UDim2.new(1, -240, 0, 4)
        StatusBar.BackgroundTransparency = 0
        if getgenv().AutoChest then
            if not getgenv().FlyingActive and not isAwayFromChest() then
                StatusText.Text = "🎯 У сундука"
            elseif not getgenv().FlyingActive then
                StatusText.Text = "🔄 Готов к полёту"
            end
            StatusToggleBg.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            StatusToggleDot.Position = UDim2.new(1, -16, 0.5, -7)
        else
            StatusText.Text = "⏸ Остановлен"
            StatusToggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            StatusToggleDot.Position = UDim2.new(0, 2, 0.5, -7)
        end
    else
        StatusBar:TweenSize(UDim2.new(0, 0, 0, 26), "Out", "Quad", 0.2, true)
        StatusBar.BackgroundTransparency = 1
        StatusToggleBg.Visible = false
    end
end

-- =============================================
-- СВОРАЧИВАНИЕ РАЗДЕЛОВ
-- =============================================
CollapseBtn.MouseButton1Click:Connect(function()
    sidebarCollapsed = not sidebarCollapsed
    if sidebarCollapsed then
        -- Сворачиваем
        SidePanel:TweenSize(UDim2.new(0, SIDEBAR_COLLAPSED_WIDTH, 1, -48), "Out", "Quad", 0.25, true)
        ContentPanel:TweenSize(UDim2.new(1, -SIDEBAR_COLLAPSED_WIDTH, 1, -48), "Out", "Quad", 0.25, true)
        ContentPanel:TweenPosition(UDim2.new(0, SIDEBAR_COLLAPSED_WIDTH, 0, 48), "Out", "Quad", 0.25, true)
        CollapseBtn:TweenPosition(UDim2.new(0, SIDEBAR_COLLAPSED_WIDTH - 10, 1, -48), "Out", "Quad", 0.25, true)
        CollapseBtn.Text = "▶"
        -- Показываем только иконки
        for name, btn in pairs(TabButtons) do btn.Visible = false end
        for name, btn in pairs(TabIconsOnly) do btn.Visible = true end
        SettingsBtn.Visible = false
        SettingsExpanded.Visible = false
        -- Компактная кнопка настроек
        local compactSettings = SidePanel:FindFirstChild("CompactSettings")
        if not compactSettings then
            compactSettings = Instance.new("TextButton")
            compactSettings.Name = "CompactSettings"
            compactSettings.Size = UDim2.new(0, 32, 0, 32)
            compactSettings.Position = UDim2.new(0.5, -16, 1, -38)
            compactSettings.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            compactSettings.BorderSizePixel = 0
            compactSettings.Text = "⚙️"
            compactSettings.TextColor3 = Color3.fromRGB(180, 180, 180)
            compactSettings.Font = Enum.Font.GothamBold
            compactSettings.TextSize = 16
            compactSettings.Parent = SidePanel
            Instance.new("UICorner", compactSettings).CornerRadius = UDim.new(0, 6)
            compactSettings.MouseButton1Click:Connect(function()
                sidebarCollapsed = false
                SidePanel:TweenSize(UDim2.new(0, SIDEBAR_WIDTH, 1, -48), "Out", "Quad", 0.25, true)
                ContentPanel:TweenSize(UDim2.new(1, -SIDEBAR_WIDTH, 1, -48), "Out", "Quad", 0.25, true)
                ContentPanel:TweenPosition(UDim2.new(0, SIDEBAR_WIDTH, 0, 48), "Out", "Quad", 0.25, true)
                CollapseBtn:TweenPosition(UDim2.new(0, SIDEBAR_WIDTH - 22, 1, -48), "Out", "Quad", 0.25, true)
                CollapseBtn.Text = "◀"
                for name, btn in pairs(TabButtons) do btn.Visible = true end
                for name, btn in pairs(TabIconsOnly) do btn.Visible = false end
                SettingsBtn.Visible = true
                SettingsExpanded.Visible = true
                compactSettings:Destroy()
            end)
        end
    else
        SidePanel:TweenSize(UDim2.new(0, SIDEBAR_WIDTH, 1, -48), "Out", "Quad", 0.25, true)
        ContentPanel:TweenSize(UDim2.new(1, -SIDEBAR_WIDTH, 1, -48), "Out", "Quad", 0.25, true)
        ContentPanel:TweenPosition(UDim2.new(0, SIDEBAR_WIDTH, 0, 48), "Out", "Quad", 0.25, true)
        CollapseBtn:TweenPosition(UDim2.new(0, SIDEBAR_WIDTH - 22, 1, -48), "Out", "Quad", 0.25, true)
        CollapseBtn.Text = "◀"
        for name, btn in pairs(TabButtons) do btn.Visible = true end
        for name, btn in pairs(TabIconsOnly) do btn.Visible = false end
        SettingsBtn.Visible = true
        SettingsExpanded.Visible = true
        local compactSettings = SidePanel:FindFirstChild("CompactSettings")
        if compactSettings then compactSettings:Destroy() end
    end
end)

-- =============================================
-- СВОРАЧИВАНИЕ ОКНА
-- =============================================
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame:TweenSize(UDim2.new(0, GUI_WIDTH, 0, 48), "Out", "Quad", 0.25, true)
        SidePanel.Visible = false
        ContentPanel.Visible = false
        CollapseBtn.Visible = false
    else
        MainFrame:TweenSize(UDim2.new(0, GUI_WIDTH, 0, GUI_HEIGHT), "Out", "Quad", 0.25, true)
        SidePanel.Visible = true
        ContentPanel.Visible = true
        CollapseBtn.Visible = true
    end
    updateStatusBar()
end)

-- =============================================
-- КРУГЛАЯ КНОПКА
-- =============================================
local guiVisible = true
ToggleBtn.MouseButton1Click:Connect(function()
    if guiVisible then
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, GUI_WIDTH, 0, 0),
            Position = UDim2.new(0, 40, 0.5, 0)
        }):Play()
        task.delay(0.4, function() MainGui.Enabled = false end)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        }):Play()
        guiVisible = false
    else
        MainGui.Enabled = true
        MainFrame.BackgroundTransparency = 1
        MainFrame.Size = UDim2.new(0, GUI_WIDTH, 0, 0)
        MainFrame.Position = UDim2.new(0, 40, 0.5, 0)
        TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            Size = UDim2.new(0, GUI_WIDTH, 0, GUI_HEIGHT),
            Position = UDim2.new(0, 40, 0.5, -GUI_HEIGHT/2)
        }):Play()
        TweenService:Create(ToggleBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        }):Play()
        guiVisible = true
    end
end)

-- =============================================
-- ЗАКРЫТИЕ
-- =============================================
local function showGoodbyeAndClose()
    local sureNotif, yesBtn, noBtn, closeNotif = createNotification("Are you sure?", "", 10, true)
    yesBtn.MouseButton1Click:Connect(function()
        closeNotif()
        SidePanel.Visible = false
        ContentPanel.Visible = false
        Header.Visible = false
        CollapseBtn.Visible = false
        
        local goodbyeText = Instance.new("TextLabel")
        goodbyeText.Size = UDim2.new(1, 0, 0, 50)
        goodbyeText.Position = UDim2.new(0, 0, 0.5, -25)
        goodbyeText.BackgroundTransparency = 1
        goodbyeText.Text = "See you soon..."
        goodbyeText.TextColor3 = Color3.fromRGB(255, 255, 255)
        goodbyeText.Font = Enum.Font.GothamBlack
        goodbyeText.TextSize = 24
        goodbyeText.TextTransparency = 1
        goodbyeText.Parent = MainFrame
        
        TweenService:Create(goodbyeText, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0
        }):Play()
        
        task.delay(4, function()
            TweenService:Create(goodbyeText, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                TextTransparency = 1
            }):Play()
            TweenService:Create(MainFrame, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(ToggleBtn, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1
            }):Play()
        end)
        
        task.delay(7, function()
            MainGui:Destroy()
            NotifGui:Destroy()
            ToggleBtnGui:Destroy()
        end)
    end)
    noBtn.MouseButton1Click:Connect(function() closeNotif() end)
end

CloseBtn.MouseButton1Click:Connect(showGoodbyeAndClose)

-- =============================================
-- АКТИВАЦИЯ
-- =============================================
currentTab = "Home"
if TabContents["Home"] then
    TabContents["Home"].Visible = true
    if TabButtons["Home"] then
        TabButtons["Home"].BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        TabButtons["Home"].TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    if TabIconsOnly["Home"] then
        TabIconsOnly["Home"].BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    end
end

-- Респавн — перезапуск цикла
Player.CharacterAdded:Connect(function(char)
    if getgenv().AutoChest then
        task.wait(0.5)
        if not getgenv().FlyingActive and isAwayFromChest() then
            flyToChest()
        end
    end
end)

-- Отслеживание смерти
Player.CharacterRemoving:Connect(function(char)
    if getgenv().FlyingActive then
        getgenv().FlyingActive = false
        if flyCoroutine then task.cancel(flyCoroutine) flyCoroutine = nil end
        StatusText.Text = "💀 Умер, жду респавн..."
        statusLabel.Text = "💀 Умер, жду респавн..."
    end
end)

-- Основной цикл
task.spawn(function()
    while true do
        if getgenv().AutoChest and not getgenv().FlyingActive and isAwayFromChest() then
            local char = Player.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                flyToChest()
                while getgenv().FlyingActive do task.wait(0.1) end
                task.wait(0.5)
            end
        end
        task.wait(0.5)
    end
end)

RunService.Stepped:Connect(function()
    if getgenv().FlyingActive and Player.Character then
        for _, part in pairs(Player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- Обновление статус-бара
task.spawn(function()
    while true do
        if isMinimized and getgenv().AutoChest and not getgenv().FlyingActive then
            if not isAwayFromChest() then
                StatusText.Text = "🎯 У сундука"
            else
                StatusText.Text = "🔄 Готов к полёту"
            end
        end
        task.wait(1)
    end
end)

task.wait(0.5)
createNotification("Notification", "The script was created by the Vanezy Scripts team", 5)

print("Vanezy Hub v2 загружен!")
print("Скорость по умолчанию: 52% (" .. getFlySpeed() .. ")")

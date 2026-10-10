local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

for _, root in ipairs({CoreGui, playerGui}) do
    pcall(function()
        local old = root:FindFirstChild("WatermelonHub")
        if old then old:Destroy() end
    end)
end

local C = {
    pink = Color3.fromRGB(255, 55, 160),
    light = Color3.fromRGB(255, 120, 200),
    dark = Color3.fromRGB(18, 13, 23),
    darker = Color3.fromRGB(11, 9, 15),
    side = Color3.fromRGB(15, 11, 20),
    white = Color3.fromRGB(255, 240, 250),
    muted = Color3.fromRGB(165, 150, 175),
    green = Color3.fromRGB(70, 235, 145),
    red = Color3.fromRGB(255, 75, 105)
}

local function new(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function corner(obj, radius)
    new("UICorner", {
        CornerRadius = UDim.new(0, radius)
    }, obj)
end

local function stroke(obj, color, thickness, transparency)
    return new("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0
    }, obj)
end

local function tween(obj, duration, props)
    local t = TweenService:Create(
        obj,
        TweenInfo.new(duration, Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out),
        props
    )
    t:Play()
    return t
end

local GUI = new("ScreenGui", {
    Name = "WatermelonHub",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999
})

local ok = pcall(function()
    GUI.Parent = CoreGui
end)

if not ok or not GUI.Parent then
    GUI.Parent = playerGui
end

local loading = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.darker,
    BorderSizePixel = 0,
    ZIndex = 50
}, GUI)

new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 45),
    Position = UDim2.new(0, 0, 0.5, -60),
    BackgroundTransparency = 1,
    Text = "WATERMELON HUB",
    TextColor3 = C.white,
    TextSize = 25,
    Font = Enum.Font.GothamBlack,
    ZIndex = 51
}, loading)

local status = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 25),
    Position = UDim2.new(0, 0, 0.5, -5),
    BackgroundTransparency = 1,
    Text = "Initializing...",
    TextColor3 = C.light,
    TextSize = 12,
    Font = Enum.Font.Gotham,
    ZIndex = 51
}, loading)

local track = new("Frame", {
    Size = UDim2.fromOffset(190, 5),
    Position = UDim2.new(0.5, -95, 0.5, 30),
    BackgroundColor3 = Color3.fromRGB(45, 30, 48),
    BorderSizePixel = 0,
    ZIndex = 51
}, loading)
corner(track, 5)

local bar = new("Frame", {
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = C.pink,
    BorderSizePixel = 0,
    ZIndex = 52
}, track)
corner(bar, 5)

local percent = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 0.5, 43),
    BackgroundTransparency = 1,
    Text = "0%",
    TextColor3 = C.muted,
    TextSize = 11,
    ZIndex = 51
}, loading)

local main = new("Frame", {
    Name = "MainWindow",
    Size = UDim2.fromOffset(390, 270),
    Position = UDim2.new(0.5, -195, 0.5, -135),
    BackgroundColor3 = C.dark,
    BorderSizePixel = 0,
    Visible = false
}, GUI)
corner(main, 12)
stroke(main, C.pink, 1.5, 0.15)

local titlebar = new("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = C.darker,
    BorderSizePixel = 0
}, main)
corner(titlebar, 12)

new("TextLabel", {
    Size = UDim2.new(1, -100, 1, 0),
    Position = UDim2.fromOffset(13, 0),
    BackgroundTransparency = 1,
    Text = "Watermelon Hub",
    TextColor3 = C.white,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, titlebar)

local minimize = new("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -70, 0, 6),
    BackgroundColor3 = Color3.fromRGB(45, 30, 47),
    Text = "−",
    TextColor3 = C.white,
    TextSize = 22
}, titlebar)
corner(minimize, 7)

local close = new("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -36, 0, 6),
    BackgroundColor3 = Color3.fromRGB(100, 25, 60),
    Text = "×",
    TextColor3 = C.white,
    TextSize = 21
}, titlebar)
corner(close, 7)

local sidebar = new("Frame", {
    Position = UDim2.fromOffset(0, 42),
    Size = UDim2.new(0, 105, 1, -42),
    BackgroundColor3 = C.side,
    BorderSizePixel = 0
}, main)

local content = new("Frame", {
    Position = UDim2.fromOffset(105, 42),
    Size = UDim2.new(1, -105, 1, -42),
    BackgroundTransparency = 1,
    ClipsDescendants = true
}, main)

local function label(parent, text, pos, size, textSize, color)
    return new("TextLabel", {
        Position = pos,
        Size = size,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or C.white,
        TextSize = textSize or 12,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left
    }, parent)
end

label(sidebar, "MENU", UDim2.fromOffset(10, 12),
    UDim2.new(1, -15, 0, 25), 10, C.muted)

local function button(parent, text, pos, size)
    local b = new("TextButton", {
        Position = pos,
        Size = size,
        BackgroundColor3 = C.dark,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = C.muted,
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        AutoButtonColor = false
    }, parent)
    corner(b, 7)
    return b
end

local infoBtn = button(sidebar, "●  Info",
    UDim2.fromOffset(6, 45), UDim2.new(1, -12, 0, 38))

local cardsBtn = button(sidebar, "◆  Cards",
    UDim2.fromOffset(6, 90), UDim2.new(1, -12, 0, 38))

local infoPage = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1
}, content)

local cardsPage = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = false
}, content)

label(infoPage, "Welcome!", UDim2.fromOffset(12, 13),
    UDim2.new(1, -24, 0, 32), 19)

local infoCard = new("Frame", {
    Position = UDim2.fromOffset(12, 58),
    Size = UDim2.new(1, -24, 0, 112),
    BackgroundColor3 = C.darker,
    BorderSizePixel = 0
}, infoPage)
corner(infoCard, 9)
stroke(infoCard, C.pink, 1, 0.78)

label(infoCard, "WATERMELON HUB",
    UDim2.fromOffset(9, 9), UDim2.new(1, -18, 0, 25),
    13, C.light)

label(infoCard, "Your card automation hub.\nOpen Cards to manage Auto Roll.",
    UDim2.fromOffset(9, 35), UDim2.new(1, -18, 0, 62),
    11, C.muted)

label(cardsPage, "Cards", UDim2.fromOffset(12, 13),
    UDim2.new(1, -24, 0, 32), 19)

local card = new("Frame", {
    Position = UDim2.fromOffset(12, 59),
    Size = UDim2.new(1, -24, 0, 92),
    BackgroundColor3 = C.darker,
    BorderSizePixel = 0
}, cardsPage)
corner(card, 9)
stroke(card, C.pink, 1, 0.7)

label(card, "Auto Roll", UDim2.fromOffset(10, 10),
    UDim2.new(1, -90, 0, 26), 14)

local description = label(card, "Automatically request card rolls.",
    UDim2.fromOffset(10, 37), UDim2.new(1, -90, 0, 35),
    10, C.muted)

local toggle = button(card, "",
    UDim2.new(1, -72, 0, 30), UDim2.fromOffset(62, 30))
toggle.BackgroundColor3 = Color3.fromRGB(65, 45, 65)
toggle.BackgroundTransparency = 0
corner(toggle, 15)

local knob = new("Frame", {
    Position = UDim2.fromOffset(4, 4),
    Size = UDim2.fromOffset(22, 22),
    BackgroundColor3 = C.white,
    BorderSizePixel = 0
}, toggle)
corner(knob, 12)

local autoStatus = label(cardsPage, "STATUS: OFF",
    UDim2.fromOffset(12, 165), UDim2.new(1, -24, 0, 24),
    11, C.muted)
autoStatus.Font = Enum.Font.GothamBold

local hint = label(cardsPage, "Tap the toggle to start or stop.",
    UDim2.fromOffset(12, 188), UDim2.new(1, -24, 0, 32),
    10, C.muted)

local function selectPage(isInfo)
    infoPage.Visible = isInfo
    cardsPage.Visible = not isInfo
    infoBtn.BackgroundTransparency = isInfo and 0 or 1
    cardsBtn.BackgroundTransparency = isInfo and 1 or 0
    infoBtn.TextColor3 = isInfo and C.white or C.muted
    cardsBtn.TextColor3 = isInfo and C.muted or C.white
end

infoBtn.Activated:Connect(function()
    selectPage(true)
end)

cardsBtn.Activated:Connect(function()
    selectPage(false)
end)

selectPage(true)

local logo = new("TextButton", {
    Name = "WatermelonLogo",
    Size = UDim2.fromOffset(54, 54),
    Position = UDim2.fromOffset(15, 100),
    BackgroundColor3 = C.darker,
    Text = "W",
    TextColor3 = C.light,
    TextSize = 34,
    Font = Enum.Font.GothamBlack,
    Visible = false,
    AutoButtonColor = false
}, GUI)
corner(logo, 27)

local glow = stroke(logo, C.pink, 3, 0.3)

local minimized = false

minimize.Activated:Connect(function()
    minimized = true
    main.Visible = false
    logo.Visible = true
end)

logo.Activated:Connect(function()
    if minimized then
        minimized = false
        main.Visible = true
        logo.Visible = false
    end
end)

close.Activated:Connect(function()
    GUI:Destroy()
end)

local function makeDraggable(obj, target)
    local moving, start, origin = false, nil, nil

    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            moving = true
            start = input.Position
            origin = target.Position
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if moving and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = input.Position - start
            target.Position = UDim2.new(
                origin.X.Scale, origin.X.Offset + d.X,
                origin.Y.Scale, origin.Y.Offset + d.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            moving = false
        end
    end)
end

makeDraggable(titlebar, main)
makeDraggable(logo, logo)

local resize = new("TextButton", {
    Size = UDim2.fromOffset(25, 25),
    Position = UDim2.new(1, -25, 1, -25),
    BackgroundColor3 = C.pink,
    Text = "◢",
    TextColor3 = C.white,
    TextSize = 15,
    ZIndex = 5
}, main)
corner(resize, 6)

local resizing, resizeStart, originalSize = false, nil, nil

resize.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
        resizeStart = input.Position
        originalSize = main.AbsoluteSize
    end
end)

UIS.InputChanged:Connect(function(input)
    if resizing and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local d = input.Position - resizeStart
        main.Size = UDim2.fromOffset(
            math.clamp(originalSize.X + d.X, 320, 600),
            math.clamp(originalSize.Y + d.Y, 230, 600)
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

task.spawn(function()
    local messages = {
        "Initializing...",
        "Loading interface...",
        "Preparing cards...",
        "Almost ready..."
    }

    for i, message in ipairs(messages) do
        if not GUI.Parent then return end

        status.Text = message
        percent.Text = (i * 25) .. "%"

        tween(bar, 0.35, {
            Size = UDim2.new(i / 4, 0, 1, 0)
        })

        task.wait(0.35)
    end

    if not GUI.Parent then return end

    main.Visible = true
    main.BackgroundTransparency = 1

    tween(main, 0.4, {
        BackgroundTransparency = 0
    })

    tween(loading, 0.3, {
        BackgroundTransparency = 1
    })

    task.wait(0.35)

    if loading.Parent then
        loading:Destroy()
    end
end)

task.spawn(function()
    while GUI.Parent do
        tween(glow, 0.9, {
            Transparency = 0.85
        }).Completed:Wait()

        if not GUI.Parent then break end

        tween(glow, 0.9, {
            Transparency = 0.3
        }).Completed:Wait()
    end
end)

return {
    GUI = GUI,
    Toggle = toggle,
    Knob = knob,
    Status = autoStatus,
    Hint = hint,
    Description = description,
    Colors = C
}

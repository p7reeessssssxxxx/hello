--[[
    NexLib - Roblox Luau UI Library
    GitHub: github.com/yourname/NexLib
    Load: loadstring(game:HttpGet("https://raw.githubusercontent.com/yourname/NexLib/main/src/NexLib.lua"))()

    Usage:
        local NexLib = loadstring(game:HttpGet("RAW_URL"))()
        local Window = NexLib:CreateWindow({ Title = "MyHub", Subtitle = "v1.0" })
        local Tab = Window:AddTab("Combat", "rbxassetid://...")
        Tab:AddButton({ Text = "Hello", Callback = function() print("clicked") end })
]]

local NexLib = {}
NexLib.__index = NexLib

-- ─────────────────────────────────────────
--  Services
-- ─────────────────────────────────────────
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local CoreGui        = game:GetService("CoreGui")
local LocalPlayer    = Players.LocalPlayer

-- ─────────────────────────────────────────
--  Theme
-- ─────────────────────────────────────────
NexLib.Theme = {
    -- Backgrounds
    BG          = Color3.fromRGB(10,  12,  20),
    Panel       = Color3.fromRGB(14,  17,  28),
    Surface     = Color3.fromRGB(18,  22,  36),
    SurfaceHover= Color3.fromRGB(24,  29,  46),

    -- Accent gradient endpoints
    Accent1     = Color3.fromRGB(0,   229, 255),   -- cyan
    Accent2     = Color3.fromRGB(124, 77,  255),   -- purple

    -- Text
    TextPrimary   = Color3.fromRGB(220, 230, 255),
    TextSecondary = Color3.fromRGB(140, 155, 195),
    TextMuted     = Color3.fromRGB(80,  95,  135),

    -- Status
    Success = Color3.fromRGB(0,   230, 118),
    Warning = Color3.fromRGB(255, 193, 7),
    Danger  = Color3.fromRGB(255, 82,  82),

    -- Borders
    Border      = Color3.fromRGB(30,  40,  65),
    BorderGlow  = Color3.fromRGB(0,   229, 255),

    -- Misc
    ToggleOn    = Color3.fromRGB(0,   229, 255),
    ToggleOff   = Color3.fromRGB(40,  50,  75),
    SliderFill  = Color3.fromRGB(0,   200, 230),

    -- Font
    Font        = Enum.Font.GothamBold,
    FontMono    = Enum.Font.Code,
    FontLight   = Enum.Font.Gotham,
}

-- ─────────────────────────────────────────
--  Utility helpers
-- ─────────────────────────────────────────
local function Tween(obj, props, dur, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    return TweenService:Create(obj, TweenInfo.new(dur or 0.25, style, dir), props):Play()
end

local function MakeInstance(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function GradientFrame(parent, colors, rotation)
    local g = MakeInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colors[1]),
            ColorSequenceKeypoint.new(1, colors[2]),
        }),
        Rotation = rotation or 90,
    }, parent)
    return g
end

local function MakeCorner(radius, parent)
    return MakeInstance("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function MakeStroke(color, thickness, parent)
    return MakeInstance("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = 0.6,
    }, parent)
end

local function MakePadding(t, b, l, r, parent)
    return MakeInstance("UIPadding", {
        PaddingTop    = UDim.new(0, t),
        PaddingBottom = UDim.new(0, b),
        PaddingLeft   = UDim.new(0, l),
        PaddingRight  = UDim.new(0, r),
    }, parent)
end

-- Animated shine overlay (loops across a frame)
local function AddShine(frame)
    local shine = MakeInstance("Frame", {
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 0.85,
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(-0.3, 0, 0, 0),
        ZIndex = frame.ZIndex + 2,
        ClipsDescendants = false,
    }, frame)
    MakeInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1,   Color3.new(1,1,1)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   1),
            NumberSequenceKeypoint.new(0.5, 0.75),
            NumberSequenceKeypoint.new(1,   1),
        }),
        Rotation = 15,
    }, shine)

    local function loopShine()
        shine.Position = UDim2.new(-0.3, 0, 0, 0)
        local t = TweenService:Create(shine, TweenInfo.new(1.8, Enum.EasingStyle.Linear), {
            Position = UDim2.new(1.3, 0, 0, 0),
        })
        t:Play()
        t.Completed:Connect(function()
            task.wait(2.5)
            loopShine()
        end)
    end
    task.delay(math.random(0, 30) / 10, loopShine)
    return shine
end

-- ─────────────────────────────────────────
--  Loading Screen
-- ─────────────────────────────────────────
function NexLib:ShowLoadingScreen(config)
    config = config or {}
    local title    = config.Title    or "NexLib"
    local subtitle = config.Subtitle or "Loading..."
    local duration = config.Duration or 3
    local statuses = config.Statuses or {
        "Initializing...", "Loading modules...", "Connecting...", "Ready."
    }

    local T = self.Theme
    local screenGui = MakeInstance("ScreenGui", {
        Name = "NexLib_Loader",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, CoreGui)

    -- Dark overlay
    local overlay = MakeInstance("Frame", {
        Size = UDim2.new(1,0,1,0),
        BackgroundColor3 = T.BG,
        ZIndex = 1,
    }, screenGui)

    -- Background grid lines
    for i = 0, 20 do
        local line = MakeInstance("Frame", {
            Size = UDim2.new(1,0,0,1),
            Position = UDim2.new(0,0, i/20, 0),
            BackgroundColor3 = T.Accent1,
            BackgroundTransparency = 0.93,
            ZIndex = 2,
        }, overlay)
    end
    for i = 0, 30 do
        local line = MakeInstance("Frame", {
            Size = UDim2.new(0,1,1,0),
            Position = UDim2.new(i/30, 0, 0, 0),
            BackgroundColor3 = T.Accent1,
            BackgroundTransparency = 0.93,
            ZIndex = 2,
        }, overlay)
    end

    -- Center container
    local center = MakeInstance("Frame", {
        Size = UDim2.new(0, 340, 0, 180),
        Position = UDim2.new(0.5, -170, 0.5, -90),
        BackgroundTransparency = 1,
        ZIndex = 5,
    }, overlay)

    -- Title
    local titleLabel = MakeInstance("TextLabel", {
        Size = UDim2.new(1,0,0,50),
        BackgroundTransparency = 1,
        Text = title:upper(),
        Font = T.Font,
        TextSize = 36,
        TextColor3 = T.Accent1,
        ZIndex = 6,
    }, center)
    -- Gradient on title via UIGradient on a frame trick
    local titleGrad = MakeInstance("UIGradient", {
        Color = ColorSequence.new(T.Accent1, T.Accent2),
        Rotation = 45,
    }, titleLabel)

    -- Subtitle / status
    local statusLabel = MakeInstance("TextLabel", {
        Size = UDim2.new(1,0,0,24),
        Position = UDim2.new(0,0,0,56),
        BackgroundTransparency = 1,
        Text = statuses[1],
        Font = T.FontMono,
        TextSize = 12,
        TextColor3 = T.TextSecondary,
        ZIndex = 6,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, center)

    -- Progress bar background
    local barBg = MakeInstance("Frame", {
        Size = UDim2.new(1,0,0,3),
        Position = UDim2.new(0,0,0,100),
        BackgroundColor3 = T.Surface,
        ZIndex = 6,
    }, center)
    MakeCorner(2, barBg)

    -- Progress bar fill
    local barFill = MakeInstance("Frame", {
        Size = UDim2.new(0,0,1,0),
        BackgroundColor3 = T.Accent1,
        ZIndex = 7,
    }, barBg)
    MakeCorner(2, barFill)
    GradientFrame(barFill, {T.Accent1, T.Accent2}, 90)

    -- Dots
    local dotsFrame = MakeInstance("Frame", {
        Size = UDim2.new(0, 60, 0, 12),
        Position = UDim2.new(0.5, -30, 0, 128),
        BackgroundTransparency = 1,
        ZIndex = 6,
    }, center)
    local dotColors = {}
    for i = 1, 3 do
        local dot = MakeInstance("Frame", {
            Size = UDim2.new(0,8,0,8),
            Position = UDim2.new(0, (i-1)*22, 0, 2),
            BackgroundColor3 = T.Accent1,
            ZIndex = 7,
        }, dotsFrame)
        MakeCorner(4, dot)
        dotColors[i] = dot
    end

    -- Animate dots
    local function bounceDots()
        for i, dot in ipairs(dotColors) do
            task.delay((i-1)*0.15, function()
                while dot and dot.Parent do
                    Tween(dot, {Position = UDim2.new(0, (i-1)*22, 0, -4)}, 0.3, Enum.EasingStyle.Sine)
                    task.wait(0.35)
                    if dot and dot.Parent then
                        Tween(dot, {Position = UDim2.new(0, (i-1)*22, 0, 2)}, 0.3, Enum.EasingStyle.Sine)
                        task.wait(0.35)
                    end
                end
            end)
        end
    end
    bounceDots()

    -- Animate progress bar and cycle statuses
    local steps = #statuses
    local stepTime = duration / steps
    for i, status in ipairs(statuses) do
        task.delay((i-1)*stepTime, function()
            if statusLabel and statusLabel.Parent then
                statusLabel.Text = status
            end
            local targetWidth = i / steps
            if barFill and barFill.Parent then
                Tween(barFill, {Size = UDim2.new(targetWidth,0,1,0)}, stepTime * 0.9, Enum.EasingStyle.Quart)
            end
        end)
    end

    -- Fade out and destroy
    task.delay(duration, function()
        Tween(overlay, {BackgroundTransparency = 1}, 0.6)
        Tween(titleLabel, {TextTransparency = 1}, 0.6)
        Tween(statusLabel, {TextTransparency = 1}, 0.6)
        task.wait(0.7)
        screenGui:Destroy()
    end)

    return screenGui
end

-- ─────────────────────────────────────────
--  Window
-- ─────────────────────────────────────────
function NexLib:CreateWindow(config)
    config = config or {}
    local title    = config.Title    or "NexLib"
    local subtitle = config.Subtitle or "v1.0"
    local size     = config.Size     or Vector2.new(560, 400)
    local position = config.Position or UDim2.new(0.5, -size.X/2, 0.5, -size.Y/2)

    local T = self.Theme

    -- Root ScreenGui
    local screenGui = MakeInstance("ScreenGui", {
        Name            = "NexLib_" .. title,
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    }, CoreGui)

    -- ── Main Window Frame ──
    local window = MakeInstance("Frame", {
        Size              = UDim2.new(0, size.X, 0, size.Y),
        Position          = position,
        BackgroundColor3  = T.BG,
        BackgroundTransparency = 0.08,
        ZIndex            = 10,
        ClipsDescendants  = true,
    }, screenGui)
    MakeCorner(14, window)
    MakeStroke(T.Border, 1, window)

    -- Subtle inner glow border using gradient
    local glowBorder = MakeInstance("Frame", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        ZIndex = 9,
    }, window)
    MakeInstance("UIStroke", {
        Color = T.Accent1,
        Thickness = 1,
        Transparency = 0.75,
    }, glowBorder)
    MakeCorner(14, glowBorder)

    -- ── Title Bar ──
    local titleBar = MakeInstance("Frame", {
        Size             = UDim2.new(1,0,0,44),
        BackgroundColor3 = T.Panel,
        ZIndex           = 11,
    }, window)
    MakeInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, T.Panel),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 25, 40)),
        }),
        Rotation = 90,
    }, titleBar)

    -- Accent line at bottom of titlebar
    local accentLine = MakeInstance("Frame", {
        Size = UDim2.new(1,0,0,2),
        Position = UDim2.new(0,0,1,-2),
        BackgroundColor3 = T.Accent1,
        ZIndex = 12,
    }, titleBar)
    GradientFrame(accentLine, {T.Accent1, T.Accent2}, 90)

    -- Title dot
    local titleDot = MakeInstance("Frame", {
        Size = UDim2.new(0,8,0,8),
        Position = UDim2.new(0,14,0.5,-4),
        BackgroundColor3 = T.Accent1,
        ZIndex = 12,
    }, titleBar)
    MakeCorner(4, titleDot)

    -- Pulse dot animation
    task.spawn(function()
        while titleDot and titleDot.Parent do
            Tween(titleDot, {BackgroundColor3 = T.Accent2}, 1.2, Enum.EasingStyle.Sine)
            task.wait(1.2)
            Tween(titleDot, {BackgroundColor3 = T.Accent1}, 1.2, Enum.EasingStyle.Sine)
            task.wait(1.2)
        end
    end)

    -- Title text
    local titleLabel = MakeInstance("TextLabel", {
        Size = UDim2.new(1,-80,1,0),
        Position = UDim2.new(0,30,0,0),
        BackgroundTransparency = 1,
        Text = title,
        Font = T.Font,
        TextSize = 16,
        TextColor3 = T.TextPrimary,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
    }, titleBar)

    -- Subtitle
    local subtitleLabel = MakeInstance("TextLabel", {
        Size = UDim2.new(0,120,1,0),
        Position = UDim2.new(1,-130,0,0),
        BackgroundTransparency = 1,
        Text = subtitle,
        Font = T.FontMono,
        TextSize = 10,
        TextColor3 = T.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 12,
    }, titleBar)
    MakePadding(0,0,0,14,subtitleLabel)

    -- Close button
    local closeBtn = MakeInstance("TextButton", {
        Size = UDim2.new(0,28,0,28),
        Position = UDim2.new(1,-38,0.5,-14),
        BackgroundColor3 = Color3.fromRGB(255,60,60),
        BackgroundTransparency = 0.5,
        Text = "✕",
        Font = T.Font,
        TextSize = 12,
        TextColor3 = Color3.new(1,1,1),
        ZIndex = 13,
    }, titleBar)
    MakeCorner(8, closeBtn)
    closeBtn.MouseButton1Click:Connect(function()
        Tween(window, {BackgroundTransparency=1}, 0.2)
        task.wait(0.2)
        screenGui:Destroy()
    end)
    closeBtn.MouseEnter:Connect(function() Tween(closeBtn, {BackgroundTransparency=0.1}, 0.15) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeBtn, {BackgroundTransparency=0.5}, 0.15) end)

    -- Minimize button
    local minBtn = MakeInstance("TextButton", {
        Size = UDim2.new(0,28,0,28),
        Position = UDim2.new(1,-72,0.5,-14),
        BackgroundColor3 = T.Accent2,
        BackgroundTransparency = 0.6,
        Text = "—",
        Font = T.Font,
        TextSize = 12,
        TextColor3 = Color3.new(1,1,1),
        ZIndex = 13,
    }, titleBar)
    MakeCorner(8, minBtn)
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(window, {Size = UDim2.new(0, size.X, 0, 44)}, 0.3, Enum.EasingStyle.Back)
        else
            Tween(window, {Size = UDim2.new(0, size.X, 0, size.Y)}, 0.3, Enum.EasingStyle.Back)
        end
    end)
    minBtn.MouseEnter:Connect(function() Tween(minBtn, {BackgroundTransparency=0.2}, 0.15) end)
    minBtn.MouseLeave:Connect(function() Tween(minBtn, {BackgroundTransparency=0.6}, 0.15) end)

    -- ── Dragging ──
    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- ── Tab Bar ──
    local tabBar = MakeInstance("Frame", {
        Size = UDim2.new(0, 130, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = T.Panel,
        ZIndex = 11,
    }, window)
    MakeInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, T.Panel),
            ColorSequenceKeypoint.new(1, T.BG),
        }),
        Rotation = 0,
    }, tabBar)

    -- Right border on tabBar
    local tabBarBorder = MakeInstance("Frame", {
        Size = UDim2.new(0,1,1,0),
        Position = UDim2.new(1,-1,0,0),
        BackgroundColor3 = T.Border,
        ZIndex = 12,
    }, tabBar)

    local tabList = MakeInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,4),
    }, tabBar)
    MakePadding(10,10,8,8,tabBar)

    -- ── Content Area ──
    local contentArea = MakeInstance("Frame", {
        Size = UDim2.new(1,-130,1,-44),
        Position = UDim2.new(0,130,0,44),
        BackgroundTransparency = 1,
        ZIndex = 11,
        ClipsDescendants = true,
    }, window)

    -- Entrance animation
    window.Size = UDim2.new(0, size.X, 0, 0)
    window.BackgroundTransparency = 1
    Tween(window, {
        Size = UDim2.new(0, size.X, 0, size.Y),
        BackgroundTransparency = 0.08,
    }, 0.45, Enum.EasingStyle.Back)

    -- ── Window Object ──
    local windowObj = { _tabs = {}, _activeTab = nil, _T = T, _window = window }

    function windowObj:AddTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or ("Tab " .. (#self._tabs + 1))
        local icon    = tabConfig.Icon or "☰"

        local T = self._T

        -- Tab button
        local tabBtn = MakeInstance("TextButton", {
            Size = UDim2.new(1,0,0,36),
            BackgroundColor3 = T.Surface,
            BackgroundTransparency = 0.6,
            Text = "",
            ZIndex = 12,
            LayoutOrder = #self._tabs + 1,
        }, tabBar)
        MakeCorner(8, tabBtn)

        local tabIcon = MakeInstance("TextLabel", {
            Size = UDim2.new(0,22,1,0),
            Position = UDim2.new(0,8,0,0),
            BackgroundTransparency = 1,
            Text = icon,
            Font = T.Font,
            TextSize = 14,
            TextColor3 = T.TextMuted,
            ZIndex = 13,
        }, tabBtn)
        local tabLabel = MakeInstance("TextLabel", {
            Size = UDim2.new(1,-34,1,0),
            Position = UDim2.new(0,32,0,0),
            BackgroundTransparency = 1,
            Text = tabName,
            Font = T.Font,
            TextSize = 13,
            TextColor3 = T.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 13,
        }, tabBtn)

        -- Active indicator bar
        local activeBar = MakeInstance("Frame", {
            Size = UDim2.new(0,3,0,20),
            Position = UDim2.new(0,0,0.5,-10),
            BackgroundColor3 = T.Accent1,
            BackgroundTransparency = 1,
            ZIndex = 14,
        }, tabBtn)
        MakeCorner(2, activeBar)

        -- Tab content frame
        local tabFrame = MakeInstance("ScrollingFrame", {
            Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.Accent1,
            ZIndex = 12,
            Visible = false,
            CanvasSize = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, contentArea)

        local contentList = MakeInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0,6),
        }, tabFrame)
        MakePadding(12,12,12,12,tabFrame)

        local tabData = {
            _frame = tabFrame,
            _btn   = tabBtn,
            _bar   = activeBar,
            _T     = T,
            _items = {},
        }

        -- Hover effects
        tabBtn.MouseEnter:Connect(function()
            if self._activeTab ~= tabData then
                Tween(tabBtn, {BackgroundTransparency=0.3}, 0.15)
                Tween(tabLabel, {TextColor3=T.TextSecondary}, 0.15)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if self._activeTab ~= tabData then
                Tween(tabBtn, {BackgroundTransparency=0.6}, 0.15)
                Tween(tabLabel, {TextColor3=T.TextMuted}, 0.15)
            end
        end)

        local function activateTab(td)
            -- Deactivate old
            if self._activeTab and self._activeTab ~= td then
                local old = self._activeTab
                old._frame.Visible = false
                Tween(old._btn, {BackgroundTransparency=0.6}, 0.2)
                Tween(old._btn:FindFirstChild("TextLabel") or old._btn, {}, 0.2)
                Tween(old._bar, {BackgroundTransparency=1, Size=UDim2.new(0,3,0,14)}, 0.2)
                -- find labels
                for _, ch in ipairs(old._btn:GetChildren()) do
                    if ch:IsA("TextLabel") then
                        Tween(ch, {TextColor3=T.TextMuted}, 0.2)
                    end
                end
            end
            self._activeTab = td
            td._frame.Visible = true
            Tween(td._btn, {BackgroundTransparency=0.1}, 0.2)
            Tween(td._bar, {BackgroundTransparency=0, Size=UDim2.new(0,3,0,22)}, 0.25, Enum.EasingStyle.Back)
            for _, ch in ipairs(td._btn:GetChildren()) do
                if ch:IsA("TextLabel") then
                    Tween(ch, {TextColor3=T.Accent1}, 0.2)
                end
            end
        end

        tabBtn.MouseButton1Click:Connect(function()
            activateTab(tabData)
        end)

        table.insert(self._tabs, tabData)

        if #self._tabs == 1 then
            activateTab(tabData)
        end

        -- ────────────────────────────────
        --  Element builders on tabData
        -- ────────────────────────────────

        -- Section label
        function tabData:AddSection(text)
            local sectionFrame = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,30),
                BackgroundTransparency = 1,
                ZIndex = 13,
                LayoutOrder = #self._items + 1,
            }, tabFrame)
            local line1 = MakeInstance("Frame", {
                Size = UDim2.new(0.35,0,0,1),
                Position = UDim2.new(0,0,0.5,0),
                BackgroundColor3 = T.Border,
                ZIndex = 14,
            }, sectionFrame)
            local sLabel = MakeInstance("TextLabel", {
                Size = UDim2.new(0,0,1,0),
                Position = UDim2.new(0.5,0,0,0),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Text = text:upper(),
                Font = T.FontMono,
                TextSize = 10,
                TextColor3 = T.TextMuted,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex = 14,
            }, sectionFrame)
            MakeInstance("UIAnchorPoint", {}, sLabel)
            sLabel.AnchorPoint = Vector2.new(0.5, 0)
            local line2 = MakeInstance("Frame", {
                Size = UDim2.new(0.35,0,0,1),
                Position = UDim2.new(0.65,0,0.5,0),
                BackgroundColor3 = T.Border,
                ZIndex = 14,
            }, sectionFrame)
            table.insert(self._items, sectionFrame)
            return sectionFrame
        end

        -- Button
        function tabData:AddButton(cfg)
            cfg = cfg or {}
            local text     = cfg.Text     or "Button"
            local callback = cfg.Callback or function() end
            local desc     = cfg.Description

            local btnFrame = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,38),
                BackgroundColor3 = T.Surface,
                BackgroundTransparency = 0.3,
                ZIndex = 13,
                LayoutOrder = #self._items + 1,
            }, tabFrame)
            MakeCorner(10, btnFrame)
            MakeStroke(T.Border, 1, btnFrame)

            local btn = MakeInstance("TextButton", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 14,
            }, btnFrame)

            local lbl = MakeInstance("TextLabel", {
                Size = UDim2.new(1,-16,1,0),
                Position = UDim2.new(0,14,0,0),
                BackgroundTransparency = 1,
                Text = text,
                Font = T.Font,
                TextSize = 14,
                TextColor3 = T.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 14,
            }, btn)

            -- Arrow indicator
            local arrow = MakeInstance("TextLabel", {
                Size = UDim2.new(0,20,1,0),
                Position = UDim2.new(1,-28,0,0),
                BackgroundTransparency = 1,
                Text = "›",
                Font = T.Font,
                TextSize = 18,
                TextColor3 = T.TextMuted,
                ZIndex = 14,
            }, btn)

            AddShine(btnFrame)

            btn.MouseEnter:Connect(function()
                Tween(btnFrame, {BackgroundTransparency=0.05}, 0.15)
                Tween(lbl, {TextColor3=T.Accent1}, 0.15)
                Tween(arrow, {TextColor3=T.Accent1}, 0.15)
            end)
            btn.MouseLeave:Connect(function()
                Tween(btnFrame, {BackgroundTransparency=0.3}, 0.15)
                Tween(lbl, {TextColor3=T.TextPrimary}, 0.15)
                Tween(arrow, {TextColor3=T.TextMuted}, 0.15)
            end)
            btn.MouseButton1Down:Connect(function()
                Tween(btnFrame, {BackgroundTransparency=0.55, Size=UDim2.new(1,0,0,36)}, 0.08)
            end)
            btn.MouseButton1Up:Connect(function()
                Tween(btnFrame, {BackgroundTransparency=0.05, Size=UDim2.new(1,0,0,38)}, 0.15, Enum.EasingStyle.Back)
                task.spawn(callback)
            end)
            btn.MouseButton1Click:Connect(function()
                -- ripple effect
                local ripple = MakeInstance("Frame", {
                    Size = UDim2.new(0,0,0,0),
                    Position = UDim2.new(0.5,0,0.5,0),
                    AnchorPoint = Vector2.new(0.5,0.5),
                    BackgroundColor3 = T.Accent1,
                    BackgroundTransparency = 0.7,
                    ZIndex = 15,
                }, btnFrame)
                MakeCorner(100, ripple)
                Tween(ripple, {Size=UDim2.new(2,0,2,0), BackgroundTransparency=1}, 0.4)
                task.delay(0.4, function() if ripple then ripple:Destroy() end end)
            end)

            table.insert(self._items, btnFrame)
            return btnFrame
        end

        -- Toggle
        function tabData:AddToggle(cfg)
            cfg = cfg or {}
            local text     = cfg.Text    or "Toggle"
            local default  = cfg.Default or false
            local callback = cfg.Callback or function(_) end

            local state = default

            local rowFrame = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,44),
                BackgroundColor3 = T.Surface,
                BackgroundTransparency = 0.3,
                ZIndex = 13,
                LayoutOrder = #self._items + 1,
            }, tabFrame)
            MakeCorner(10, rowFrame)
            MakeStroke(T.Border, 1, rowFrame)

            local lbl = MakeInstance("TextLabel", {
                Size = UDim2.new(1,-60,1,0),
                Position = UDim2.new(0,14,0,0),
                BackgroundTransparency = 1,
                Text = text,
                Font = T.Font,
                TextSize = 14,
                TextColor3 = T.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 14,
            }, rowFrame)

            -- Toggle track
            local track = MakeInstance("Frame", {
                Size = UDim2.new(0,44,0,24),
                Position = UDim2.new(1,-56,0.5,-12),
                BackgroundColor3 = state and T.ToggleOn or T.ToggleOff,
                ZIndex = 14,
            }, rowFrame)
            MakeCorner(12, track)

            -- Knob
            local knob = MakeInstance("Frame", {
                Size = UDim2.new(0,18,0,18),
                Position = state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
                BackgroundColor3 = Color3.new(1,1,1),
                ZIndex = 15,
            }, track)
            MakeCorner(9, knob)

            if state then
                GradientFrame(track, {T.Accent1, T.Accent2}, 90)
            end

            local function setToggle(val)
                state = val
                if state then
                    Tween(track, {BackgroundColor3 = T.ToggleOn}, 0.25)
                    Tween(knob, {Position = UDim2.new(1,-21,0.5,-9)}, 0.25, Enum.EasingStyle.Back)
                    -- add glow
                    local stroke = track:FindFirstChildOfClass("UIStroke")
                    if not stroke then
                        MakeInstance("UIStroke", {Color=T.Accent1, Thickness=1.5, Transparency=0.3}, track)
                    end
                else
                    Tween(track, {BackgroundColor3 = T.ToggleOff}, 0.25)
                    Tween(knob, {Position = UDim2.new(0,3,0.5,-9)}, 0.25, Enum.EasingStyle.Back)
                    local stroke = track:FindFirstChildOfClass("UIStroke")
                    if stroke then stroke:Destroy() end
                end
                task.spawn(callback, state)
            end

            local clickBtn = MakeInstance("TextButton", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 16,
            }, rowFrame)
            clickBtn.MouseButton1Click:Connect(function()
                setToggle(not state)
            end)
            clickBtn.MouseEnter:Connect(function()
                Tween(rowFrame, {BackgroundTransparency=0.1}, 0.15)
            end)
            clickBtn.MouseLeave:Connect(function()
                Tween(rowFrame, {BackgroundTransparency=0.3}, 0.15)
            end)

            table.insert(self._items, rowFrame)
            local toggleObj = { _state = state }
            function toggleObj:Set(val) setToggle(val) end
            function toggleObj:Get() return state end
            return toggleObj
        end

        -- Slider
        function tabData:AddSlider(cfg)
            cfg = cfg or {}
            local text     = cfg.Text    or "Slider"
            local min      = cfg.Min     or 0
            local max      = cfg.Max     or 100
            local default  = cfg.Default or 50
            local suffix   = cfg.Suffix  or ""
            local callback = cfg.Callback or function(_) end

            local value = math.clamp(default, min, max)

            local sliderFrame = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,54),
                BackgroundColor3 = T.Surface,
                BackgroundTransparency = 0.3,
                ZIndex = 13,
                LayoutOrder = #self._items + 1,
            }, tabFrame)
            MakeCorner(10, sliderFrame)
            MakeStroke(T.Border, 1, sliderFrame)
            MakePadding(8,8,14,14,sliderFrame)

            local topRow = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,20),
                BackgroundTransparency = 1,
                ZIndex = 14,
            }, sliderFrame)
            local sliderLabel = MakeInstance("TextLabel", {
                Size = UDim2.new(1,-60,1,0),
                BackgroundTransparency = 1,
                Text = text,
                Font = T.Font,
                TextSize = 13,
                TextColor3 = T.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 14,
            }, topRow)
            local valLabel = MakeInstance("TextLabel", {
                Size = UDim2.new(0,60,1,0),
                Position = UDim2.new(1,-60,0,0),
                BackgroundTransparency = 1,
                Text = tostring(value) .. suffix,
                Font = T.FontMono,
                TextSize = 12,
                TextColor3 = T.Accent1,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 14,
            }, topRow)

            -- Track
            local trackBg = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,4),
                Position = UDim2.new(0,0,1,-4),
                BackgroundColor3 = T.Border,
                ZIndex = 14,
            }, sliderFrame)
            MakeCorner(2, trackBg)

            local pct = (value - min) / (max - min)
            local trackFill = MakeInstance("Frame", {
                Size = UDim2.new(pct,0,1,0),
                BackgroundColor3 = T.Accent1,
                ZIndex = 15,
            }, trackBg)
            MakeCorner(2, trackFill)
            GradientFrame(trackFill, {T.Accent1, T.Accent2}, 90)

            -- Thumb
            local thumb = MakeInstance("Frame", {
                Size = UDim2.new(0,16,0,16),
                Position = UDim2.new(pct,0,0.5,-8),
                AnchorPoint = Vector2.new(0.5,0.5),
                BackgroundColor3 = Color3.new(1,1,1),
                ZIndex = 16,
            }, trackBg)
            MakeCorner(8, thumb)
            MakeInstance("UIGradient", {
                Color = ColorSequence.new(T.Accent1, T.Accent2),
                Rotation = 45,
            }, thumb)

            -- Drag logic
            local draggingSlider = false
            local function updateFromX(absX)
                local trackAbsPos = trackBg.AbsolutePosition.X
                local trackAbsSize = trackBg.AbsoluteSize.X
                local rel = math.clamp((absX - trackAbsPos) / trackAbsSize, 0, 1)
                value = math.floor(min + (max - min) * rel)
                valLabel.Text = tostring(value) .. suffix
                Tween(trackFill, {Size = UDim2.new(rel,0,1,0)}, 0.05)
                Tween(thumb, {Position = UDim2.new(rel,0,0.5,-8)}, 0.05)
                task.spawn(callback, value)
            end

            trackBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = true
                    updateFromX(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateFromX(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = false
                end
            end)

            thumb.MouseEnter:Connect(function()
                Tween(thumb, {Size=UDim2.new(0,20,0,20)}, 0.15, Enum.EasingStyle.Back)
            end)
            thumb.MouseLeave:Connect(function()
                if not draggingSlider then
                    Tween(thumb, {Size=UDim2.new(0,16,0,16)}, 0.15)
                end
            end)

            table.insert(self._items, sliderFrame)
            local sliderObj = {}
            function sliderObj:Set(v)
                value = math.clamp(v, min, max)
                local r = (value-min)/(max-min)
                valLabel.Text = tostring(value)..suffix
                Tween(trackFill, {Size=UDim2.new(r,0,1,0)}, 0.2)
                Tween(thumb, {Position=UDim2.new(r,0,0.5,-8)}, 0.2)
            end
            function sliderObj:Get() return value end
            return sliderObj
        end

        -- Dropdown
        function tabData:AddDropdown(cfg)
            cfg = cfg or {}
            local text     = cfg.Text    or "Dropdown"
            local options  = cfg.Options or {"Option 1","Option 2","Option 3"}
            local default  = cfg.Default or options[1]
            local callback = cfg.Callback or function(_) end

            local selected = default
            local open = false

            local ddContainer = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,42),
                BackgroundTransparency = 1,
                ZIndex = 13,
                LayoutOrder = #self._items + 1,
                ClipsDescendants = false,
            }, tabFrame)

            local ddBtn = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,42),
                BackgroundColor3 = T.Surface,
                BackgroundTransparency = 0.3,
                ZIndex = 13,
            }, ddContainer)
            MakeCorner(10, ddBtn)
            MakeStroke(T.Border, 1, ddBtn)

            local ddLabel = MakeInstance("TextLabel", {
                Size = UDim2.new(1,0,0,20),
                Position = UDim2.new(0,14,0,4),
                BackgroundTransparency = 1,
                Text = text,
                Font = T.FontLight,
                TextSize = 11,
                TextColor3 = T.TextMuted,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 14,
            }, ddBtn)
            local ddVal = MakeInstance("TextLabel", {
                Size = UDim2.new(1,-40,0,18),
                Position = UDim2.new(0,14,0,22),
                BackgroundTransparency = 1,
                Text = selected,
                Font = T.Font,
                TextSize = 13,
                TextColor3 = T.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 14,
            }, ddBtn)
            local ddArrow = MakeInstance("TextLabel", {
                Size = UDim2.new(0,24,1,0),
                Position = UDim2.new(1,-34,0,0),
                BackgroundTransparency = 1,
                Text = "▾",
                Font = T.Font,
                TextSize = 14,
                TextColor3 = T.TextMuted,
                ZIndex = 14,
            }, ddBtn)

            -- Dropdown menu
            local menuFrame = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,0),
                Position = UDim2.new(0,0,1,4),
                BackgroundColor3 = T.Panel,
                ZIndex = 20,
                ClipsDescendants = true,
            }, ddContainer)
            MakeCorner(10, menuFrame)
            MakeStroke(T.Border, 1, menuFrame)

            local menuList = MakeInstance("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, menuFrame)
            MakePadding(4,4,0,0,menuFrame)

            local menuHeight = #options * 32 + 8

            for i, opt in ipairs(options) do
                local optBtn = MakeInstance("TextButton", {
                    Size = UDim2.new(1,0,0,32),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 21,
                    LayoutOrder = i,
                }, menuFrame)
                local optDot = MakeInstance("Frame", {
                    Size = UDim2.new(0,5,0,5),
                    Position = UDim2.new(0,12,0.5,-2.5),
                    BackgroundColor3 = T.Accent1,
                    BackgroundTransparency = 0.5,
                    ZIndex = 22,
                }, optBtn)
                MakeCorner(3, optDot)
                local optLabel = MakeInstance("TextLabel", {
                    Size = UDim2.new(1,-30,1,0),
                    Position = UDim2.new(0,24,0,0),
                    BackgroundTransparency = 1,
                    Text = opt,
                    Font = T.Font,
                    TextSize = 13,
                    TextColor3 = T.TextSecondary,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 22,
                }, optBtn)
                optBtn.MouseEnter:Connect(function()
                    Tween(optBtn, {BackgroundTransparency=0}, 0.1)
                    optBtn.BackgroundColor3 = T.SurfaceHover
                    Tween(optLabel, {TextColor3=T.Accent1}, 0.1)
                end)
                optBtn.MouseLeave:Connect(function()
                    Tween(optBtn, {BackgroundTransparency=1}, 0.1)
                    Tween(optLabel, {TextColor3=T.TextSecondary}, 0.1)
                end)
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    ddVal.Text = opt
                    -- close
                    open = false
                    Tween(menuFrame, {Size=UDim2.new(1,0,0,0)}, 0.25, Enum.EasingStyle.Quart)
                    Tween(ddArrow, {Rotation=0}, 0.25)
                    task.spawn(callback, opt)
                end)
            end

            local clickBtn = MakeInstance("TextButton", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 15,
            }, ddBtn)
            clickBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    Tween(menuFrame, {Size=UDim2.new(1,0,0,menuHeight)}, 0.3, Enum.EasingStyle.Back)
                    Tween(ddArrow, {Rotation=180}, 0.3)
                    Tween(ddBtn, {BackgroundTransparency=0.1}, 0.15)
                else
                    Tween(menuFrame, {Size=UDim2.new(1,0,0,0)}, 0.25)
                    Tween(ddArrow, {Rotation=0}, 0.25)
                    Tween(ddBtn, {BackgroundTransparency=0.3}, 0.15)
                end
            end)
            clickBtn.MouseEnter:Connect(function()
                Tween(ddBtn, {BackgroundTransparency=0.1}, 0.15)
            end)
            clickBtn.MouseLeave:Connect(function()
                if not open then Tween(ddBtn, {BackgroundTransparency=0.3}, 0.15) end
            end)

            table.insert(self._items, ddContainer)
            local ddObj = {}
            function ddObj:Set(val)
                selected = val
                ddVal.Text = val
            end
            function ddObj:Get() return selected end
            return ddObj
        end

        -- TextInput
        function tabData:AddTextInput(cfg)
            cfg = cfg or {}
            local text       = cfg.Text        or "Input"
            local placeholder= cfg.Placeholder or "Type here..."
            local callback   = cfg.Callback    or function(_) end

            local inputFrame = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,54),
                BackgroundColor3 = T.Surface,
                BackgroundTransparency = 0.3,
                ZIndex = 13,
                LayoutOrder = #self._items + 1,
            }, tabFrame)
            MakeCorner(10, inputFrame)
            MakeStroke(T.Border, 1, inputFrame)
            MakePadding(6,6,14,14,inputFrame)

            local inputLabel = MakeInstance("TextLabel", {
                Size = UDim2.new(1,0,0,18),
                BackgroundTransparency = 1,
                Text = text,
                Font = T.FontLight,
                TextSize = 11,
                TextColor3 = T.TextMuted,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 14,
            }, inputFrame)
            local textBox = MakeInstance("TextBox", {
                Size = UDim2.new(1,0,0,24),
                Position = UDim2.new(0,0,0,22),
                BackgroundTransparency = 1,
                Text = "",
                PlaceholderText = placeholder,
                PlaceholderColor3 = T.TextMuted,
                Font = T.FontMono,
                TextSize = 13,
                TextColor3 = T.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                ZIndex = 14,
            }, inputFrame)

            local underline = MakeInstance("Frame", {
                Size = UDim2.new(0,0,0,1),
                Position = UDim2.new(0,0,1,-1),
                BackgroundColor3 = T.Accent1,
                ZIndex = 14,
            }, inputFrame)

            textBox.Focused:Connect(function()
                Tween(underline, {Size=UDim2.new(1,0,0,1)}, 0.3, Enum.EasingStyle.Quart)
                Tween(inputFrame, {BackgroundTransparency=0.1}, 0.2)
            end)
            textBox.FocusLost:Connect(function(enter)
                Tween(underline, {Size=UDim2.new(0,0,0,1)}, 0.3)
                Tween(inputFrame, {BackgroundTransparency=0.3}, 0.2)
                if enter then task.spawn(callback, textBox.Text) end
            end)

            table.insert(self._items, inputFrame)
            local inputObj = {}
            function inputObj:Get() return textBox.Text end
            function inputObj:Set(v) textBox.Text = v end
            return inputObj
        end

        -- Key System prompt
        function tabData:AddKeySystem(cfg)
            cfg = cfg or {}
            local validKey  = cfg.Key      or "NEXLIB-DEMO-2024"
            local callback  = cfg.Callback or function() end
            local title     = cfg.Title    or "Key Required"

            local keyFrame = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,80),
                BackgroundColor3 = T.Surface,
                BackgroundTransparency = 0.1,
                ZIndex = 13,
                LayoutOrder = #self._items + 1,
            }, tabFrame)
            MakeCorner(12, keyFrame)
            MakeInstance("UIStroke", {
                Color = T.Accent2,
                Thickness = 1,
                Transparency = 0.5,
            }, keyFrame)
            MakePadding(10,10,14,14,keyFrame)

            -- gradient top bar
            local keyBar = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,2),
                BackgroundColor3 = T.Accent1,
                ZIndex = 14,
            }, keyFrame)
            GradientFrame(keyBar, {T.Accent2, T.Accent1}, 90)

            local keyTitle = MakeInstance("TextLabel", {
                Size = UDim2.new(1,0,0,20),
                Position = UDim2.new(0,0,0,8),
                BackgroundTransparency = 1,
                Text = "🔐  " .. title,
                Font = T.Font,
                TextSize = 13,
                TextColor3 = T.TextSecondary,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 14,
            }, keyFrame)

            local keyRow = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,32),
                Position = UDim2.new(0,0,0,34),
                BackgroundTransparency = 1,
                ZIndex = 14,
            }, keyFrame)

            local keyInput = MakeInstance("TextBox", {
                Size = UDim2.new(1,-90,1,0),
                BackgroundColor3 = T.BG,
                BackgroundTransparency = 0.2,
                Text = "",
                PlaceholderText = "XXXX-XXXX-XXXX",
                PlaceholderColor3 = T.TextMuted,
                Font = T.FontMono,
                TextSize = 13,
                TextColor3 = T.Accent1,
                ClearTextOnFocus = false,
                ZIndex = 15,
            }, keyRow)
            MakeCorner(8, keyInput)
            MakeStroke(T.Border, 1, keyInput)
            MakePadding(0,0,10,8,keyInput)

            local verifyBtn = MakeInstance("TextButton", {
                Size = UDim2.new(0,80,1,0),
                Position = UDim2.new(1,-80,0,0),
                BackgroundColor3 = T.Accent2,
                BackgroundTransparency = 0.3,
                Text = "VERIFY",
                Font = T.Font,
                TextSize = 12,
                TextColor3 = Color3.new(1,1,1),
                ZIndex = 15,
            }, keyRow)
            MakeCorner(8, verifyBtn)
            AddShine(verifyBtn)

            verifyBtn.MouseButton1Click:Connect(function()
                local entered = keyInput.Text:upper():gsub("%s","")
                if entered == validKey:upper() then
                    Tween(keyFrame, {BackgroundColor3=Color3.fromRGB(0,40,20)}, 0.3)
                    keyTitle.Text = "✔  Access Granted"
                    Tween(keyTitle, {TextColor3=T.Success}, 0.3)
                    task.spawn(callback)
                else
                    Tween(keyFrame, {BackgroundColor3=Color3.fromRGB(50,10,10)}, 0.15)
                    keyTitle.Text = "✕  Invalid Key"
                    Tween(keyTitle, {TextColor3=T.Danger}, 0.15)
                    task.wait(0.3)
                    Tween(keyFrame, {BackgroundColor3=T.Surface}, 0.3)
                    task.wait(1)
                    keyTitle.Text = "🔐  " .. title
                    Tween(keyTitle, {TextColor3=T.TextSecondary}, 0.3)
                end
            end)
            verifyBtn.MouseEnter:Connect(function() Tween(verifyBtn,{BackgroundTransparency=0.05},0.15) end)
            verifyBtn.MouseLeave:Connect(function() Tween(verifyBtn,{BackgroundTransparency=0.3},0.15) end)

            table.insert(self._items, keyFrame)
        end

        -- Label / Notification
        function tabData:AddLabel(cfg)
            cfg = cfg or {}
            local text  = cfg.Text  or "Label"
            local color = cfg.Color or T.TextSecondary

            local lbl = MakeInstance("TextLabel", {
                Size = UDim2.new(1,0,0,28),
                BackgroundTransparency = 1,
                Text = text,
                Font = T.FontLight,
                TextSize = 13,
                TextColor3 = color,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 13,
                LayoutOrder = #self._items + 1,
                TextWrapped = true,
            }, tabFrame)
            MakePadding(0,0,14,0,lbl)
            table.insert(self._items, lbl)
            local labelObj = {}
            function labelObj:Set(t) lbl.Text = t end
            function labelObj:SetColor(c) Tween(lbl, {TextColor3=c}, 0.2) end
            return labelObj
        end

        -- Separator
        function tabData:AddSeparator()
            local sep = MakeInstance("Frame", {
                Size = UDim2.new(1,0,0,1),
                BackgroundColor3 = T.Border,
                ZIndex = 13,
                LayoutOrder = #self._items + 1,
            }, tabFrame)
            table.insert(self._items, sep)
        end

        -- Notification (toast)
        function tabData:Notify(cfg)
            cfg = cfg or {}
            local msg      = cfg.Message  or "Notification"
            local duration = cfg.Duration or 3
            local ntype    = cfg.Type     or "info" -- info, success, warning, danger

            local colorMap = {
                info    = T.Accent1,
                success = T.Success,
                warning = T.Warning,
                danger  = T.Danger,
            }
            local col = colorMap[ntype] or T.Accent1

            local notifGui = MakeInstance("ScreenGui", {
                Name = "NexLib_Notif",
                ResetOnSpawn = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            }, CoreGui)
            local notifFrame = MakeInstance("Frame", {
                Size = UDim2.new(0, 260, 0, 52),
                Position = UDim2.new(1,-280, 1,-80),
                BackgroundColor3 = T.Panel,
                ZIndex = 100,
            }, notifGui)
            MakeCorner(12, notifFrame)
            MakeInstance("UIStroke", {Color=col, Thickness=1, Transparency=0.4}, notifFrame)

            local accentBar = MakeInstance("Frame", {
                Size = UDim2.new(0,3,1,0),
                BackgroundColor3 = col,
                ZIndex = 101,
            }, notifFrame)
            MakeCorner(2, accentBar)

            MakeInstance("TextLabel", {
                Size = UDim2.new(1,-18,1,0),
                Position = UDim2.new(0,14,0,0),
                BackgroundTransparency = 1,
                Text = msg,
                Font = T.Font,
                TextSize = 13,
                TextColor3 = T.TextPrimary,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                ZIndex = 101,
            }, notifFrame)

            -- Slide in
            notifFrame.Position = UDim2.new(1,20,1,-80)
            Tween(notifFrame, {Position=UDim2.new(1,-280,1,-80)}, 0.4, Enum.EasingStyle.Back)

            task.delay(duration, function()
                Tween(notifFrame, {Position=UDim2.new(1,20,1,-80), BackgroundTransparency=1}, 0.35)
                task.wait(0.4)
                notifGui:Destroy()
            end)
        end

        return tabData
    end

    return windowObj
end

return NexLib

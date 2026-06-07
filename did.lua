--[[
	╔══════════════════════════════════════════════════╗
	║           S K E E T  I S L A N D               ║
	║        Glassy Dynamic Island UI Library         ║
	║             for Roblox — Luau                   ║
	╚══════════════════════════════════════════════════╝

	GitHub: loadstring(game:HttpGet("https://raw.githubusercontent.com/yourname/SkeetIsland/main/SkeetIsland.lua"))()

	Features:
	  • Dynamic Island — expands/collapses with animation
	  • Key System with welcome screen
	  • Main UI panel (glassy, iOS-style)
	  • Settings UI
	  • Notification system
	  • Optional gradient glow
	  • Time & Date on island
	  • Glowing line shine effect
--]]

local SkeetIsland = {}
SkeetIsland.__index = SkeetIsland

-- ══════════════════════════════════════════
-- 	SERVICES
-- ══════════════════════════════════════════
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local HttpService     = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════
-- 	CONSTANTS & THEME
-- ══════════════════════════════════════════
local THEME = {
	-- Glass base
	IslandBG       = Color3.fromRGB(10, 10, 12),
	GlassBase      = Color3.fromRGB(18, 18, 22),
	GlassBorder    = Color3.fromRGB(255, 255, 255),
	GlassShine     = Color3.fromRGB(255, 255, 255),

	-- Accent / Glow
	AccentPrimary  = Color3.fromRGB(120, 80, 255),
	AccentSecond   = Color3.fromRGB(60, 180, 255),
	GlowColor      = Color3.fromRGB(130, 90, 255),

	-- Text
	TextPrimary    = Color3.fromRGB(240, 240, 255),
	TextSecondary  = Color3.fromRGB(160, 160, 185),
	TextMuted      = Color3.fromRGB(90, 90, 110),

	-- Status
	Success        = Color3.fromRGB(80, 220, 140),
	Warning        = Color3.fromRGB(255, 190, 60),
	Error          = Color3.fromRGB(255, 80, 80),
	Info           = Color3.fromRGB(80, 160, 255),

	-- Island sizes (collapsed → expanded)
	IslandCollapsedW  = 200,
	IslandCollapsedH  = 34,
	IslandExpandedW   = 340,
	IslandExpandedH   = 54,
	IslandOpenW       = 360,
	IslandOpenH       = 420,

	TweenSpeed     = 0.35,
	TweenStyle     = Enum.EasingStyle.Quart,
	TweenDir       = Enum.EasingDirection.Out,
}

-- ══════════════════════════════════════════
-- 	UTILITY
-- ══════════════════════════════════════════
local function Tween(obj, props, speed, style, dir)
	local info = TweenInfo.new(
		speed  or THEME.TweenSpeed,
		style  or THEME.TweenStyle,
		dir    or THEME.TweenDir
	)
	return TweenService:Create(obj, info, props)
end

local function MakeInstance(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	if parent then inst.Parent = parent end
	return inst
end

local function GlassFrame(name, size, pos, parent, cornerRadius)
	local frame = MakeInstance("Frame", {
		Name            = name,
		Size            = size,
		Position        = pos,
		BackgroundColor3 = THEME.GlassBase,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, parent)

	MakeInstance("UICorner", {
		CornerRadius = cornerRadius or UDim.new(0, 22),
	}, frame)

	-- Glass border stroke
	MakeInstance("UIStroke", {
		Color       = THEME.GlassBorder,
		Transparency = 0.72,
		Thickness   = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, frame)

	return frame
end

local function ShineEffect(parent, width, height)
	-- Top shine line that sweeps across
	local shine = MakeInstance("Frame", {
		Name = "Shine",
		Size = UDim2.new(0, width or 60, 0, 1),
		Position = UDim2.new(0, -80, 0, 0),
		BackgroundColor3 = THEME.GlassShine,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, parent)

	MakeInstance("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, shine)

	return shine
end

local function AnimateShine(shine, containerWidth)
	local function loop()
		shine.Position = UDim2.new(0, -80, 0, 0)
		Tween(shine, {Position = UDim2.new(0, (containerWidth or 300) + 80, 0, 0)}, 2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
		task.delay(4, loop)
	end
	task.delay(math.random(1, 3), loop)
end

local function GlowFrame(parent, color, spread)
	-- Outer glow via ImageLabel (UIStroke glow trick)
	local glow = MakeInstance("ImageLabel", {
		Name              = "Glow",
		Size              = UDim2.new(1, spread or 30, 1, spread or 30),
		Position          = UDim2.new(0, -(spread or 15), 0, -(spread or 15)),
		BackgroundTransparency = 1,
		Image             = "rbxassetid://5028857084", -- radial glow asset
		ImageColor3       = color or THEME.GlowColor,
		ImageTransparency = 0.55,
		ZIndex            = 0,
		ScaleType         = Enum.ScaleType.Slice,
		SliceCenter       = Rect.new(24, 24, 276, 276),
	}, parent)
	return glow
end

-- ══════════════════════════════════════════
-- 	ISLAND CORE
-- ══════════════════════════════════════════
function SkeetIsland.new(config)
	local self = setmetatable({}, SkeetIsland)

	config = config or {}
	self.Title          = config.Title or "SkeetIsland"
	self.SubTitle       = config.SubTitle or "v1.0"
	self.AccentColor    = config.AccentColor or THEME.AccentPrimary
	self.GradientGlow   = config.GradientGlow ~= false  -- default true
	self.KeyRequired    = config.Key ~= nil
	self.ValidKey       = config.Key
	self.KeyVerified    = false
	self.IsExpanded     = false
	self.IsOpen         = false
	self.Tabs           = {}
	self.Notifications  = {}
	self._notifQueue    = {}
	self._connections   = {}

	self:_BuildScreenGui()
	self:_BuildIsland()
	self:_BuildMainPanel()
	self:_BuildSettingsPanel()
	self:_StartClock()

	if self.KeyRequired then
		self:_ShowKeySystem()
	else
		self.KeyVerified = true
		self:_ShowWelcome()
	end

	return self
end

-- ══════════════════════════════════════════
-- 	GUI ROOT
-- ══════════════════════════════════════════
function SkeetIsland:_BuildScreenGui()
	-- Remove old instance if exists
	if PlayerGui:FindFirstChild("SkeetIslandUI") then
		PlayerGui:FindFirstChild("SkeetIslandUI"):Destroy()
	end

	self.ScreenGui = MakeInstance("ScreenGui", {
		Name              = "SkeetIslandUI",
		ResetOnSpawn      = false,
		ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset    = true,
	}, PlayerGui)

	-- Notification container (top-right)
	self.NotifContainer = MakeInstance("Frame", {
		Name              = "NotifContainer",
		Size              = UDim2.new(0, 320, 1, 0),
		Position          = UDim2.new(1, -330, 0, 10),
		BackgroundTransparency = 1,
		BorderSizePixel   = 0,
		ZIndex            = 100,
	}, self.ScreenGui)

	MakeInstance("UIListLayout", {
		SortOrder        = Enum.SortOrder.LayoutOrder,
		Padding          = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}, self.NotifContainer)
end

-- ══════════════════════════════════════════
-- 	DYNAMIC ISLAND
-- ══════════════════════════════════════════
function SkeetIsland:_BuildIsland()
	-- Container centered at top
	self.IslandContainer = MakeInstance("Frame", {
		Name              = "IslandContainer",
		Size              = UDim2.new(0, THEME.IslandCollapsedW, 0, THEME.IslandCollapsedH),
		Position          = UDim2.new(0.5, -THEME.IslandCollapsedW/2, 0, 12),
		BackgroundTransparency = 1,
		ZIndex            = 50,
	}, self.ScreenGui)

	-- The actual island pill
	self.Island = MakeInstance("Frame", {
		Name              = "Island",
		Size              = UDim2.new(1, 0, 1, 0),
		BackgroundColor3  = THEME.IslandBG,
		BackgroundTransparency = 0,
		BorderSizePixel   = 0,
		ClipsDescendants  = true,
		ZIndex            = 51,
	}, self.IslandContainer)

	MakeInstance("UICorner", {
		CornerRadius = UDim.new(0, 20),
	}, self.Island)

	-- Glow underneath island
	if self.GradientGlow then
		self._islandGlow = GlowFrame(self.Island, self.AccentColor, 28)
	end

	-- Glass border stroke on island
	self._islandStroke = MakeInstance("UIStroke", {
		Color        = THEME.GlassBorder,
		Transparency = 0.78,
		Thickness    = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, self.Island)

	-- Gradient fill (subtle)
	MakeInstance("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 26, 38)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 14)),
		}),
	}, self.Island)

	-- Shine sweep line
	self._islandShine = ShineEffect(self.Island, 70, 1)
	AnimateShine(self._islandShine, THEME.IslandCollapsedW)

	-- Glowing bottom line (the signature effect)
	self._islandLine = MakeInstance("Frame", {
		Name              = "GlowLine",
		Size              = UDim2.new(0.6, 0, 0, 1),
		Position          = UDim2.new(0.2, 0, 1, -1),
		BackgroundColor3  = self.AccentColor,
		BackgroundTransparency = 0,
		BorderSizePixel   = 0,
		ZIndex            = 55,
	}, self.Island)

	MakeInstance("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new(Color3.fromRGB(255,255,255)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0),
			NumberSequenceKeypoint.new(0.7, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, self._islandLine)

	-- Island content (collapsed state)
	self._islandContent = MakeInstance("Frame", {
		Name              = "Content",
		Size              = UDim2.new(1, -16, 1, 0),
		Position          = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		ZIndex            = 52,
	}, self.Island)

	-- Status dot
	self._statusDot = MakeInstance("Frame", {
		Name              = "StatusDot",
		Size              = UDim2.new(0, 7, 0, 7),
		Position          = UDim2.new(0, 4, 0.5, -3),
		BackgroundColor3  = THEME.Success,
		BorderSizePixel   = 0,
		ZIndex            = 53,
	}, self._islandContent)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, self._statusDot)

	-- Time label
	self._timeLabel = MakeInstance("TextLabel", {
		Name              = "Time",
		Size              = UDim2.new(0, 50, 1, 0),
		Position          = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text              = "00:00",
		TextColor3        = THEME.TextPrimary,
		TextSize          = 13,
		Font              = Enum.Font.GothamBold,
		TextXAlignment    = Enum.TextXAlignment.Left,
		ZIndex            = 53,
	}, self._islandContent)

	-- Title label (center)
	self._islandTitle = MakeInstance("TextLabel", {
		Name              = "Title",
		Size              = UDim2.new(1, -120, 1, 0),
		Position          = UDim2.new(0, 70, 0, 0),
		BackgroundTransparency = 1,
		Text              = self.Title,
		TextColor3        = THEME.TextPrimary,
		TextSize          = 13,
		Font              = Enum.Font.GothamBold,
		TextXAlignment    = Enum.TextXAlignment.Center,
		ZIndex            = 53,
	}, self._islandContent)

	-- FPS label (right)
	self._fpsLabel = MakeInstance("TextLabel", {
		Name              = "FPS",
		Size              = UDim2.new(0, 60, 1, 0),
		Position          = UDim2.new(1, -64, 0, 0),
		BackgroundTransparency = 1,
		Text              = "-- fps",
		TextColor3        = THEME.TextSecondary,
		TextSize          = 12,
		Font              = Enum.Font.Gotham,
		TextXAlignment    = Enum.TextXAlignment.Right,
		ZIndex            = 53,
	}, self._islandContent)

	-- FPS counter
	local frames, lastTime = 0, os.clock()
	self._connections[#self._connections+1] = RunService.RenderStepped:Connect(function()
		frames = frames + 1
		local now = os.clock()
		if now - lastTime >= 1 then
			self._fpsLabel.Text = math.floor(frames / (now - lastTime)) .. " fps"
			frames, lastTime = 0, now
		end
	end)

	-- Click handler
	local btn = MakeInstance("TextButton", {
		Size              = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text              = "",
		ZIndex            = 60,
	}, self.Island)

	btn.MouseButton1Click:Connect(function()
		if self.KeyVerified then
			if self.IsOpen then
				self:ClosePanel()
			else
				self:OpenPanel()
			end
		end
	end)

	btn.MouseEnter:Connect(function()
		if not self.IsOpen then
			self:_ExpandIsland()
		end
	end)

	btn.MouseLeave:Connect(function()
		if not self.IsOpen and self.IsExpanded then
			self:_CollapseIsland()
		end
	end)
end

function SkeetIsland:_ExpandIsland()
	if self.IsExpanded or self.IsOpen then return end
	self.IsExpanded = true
	local w, h = THEME.IslandExpandedW, THEME.IslandExpandedH
	Tween(self.IslandContainer, {
		Size     = UDim2.new(0, w, 0, h),
		Position = UDim2.new(0.5, -w/2, 0, 10),
	}):Play()
	Tween(self._islandLine, {
		Size = UDim2.new(0.8, 0, 0, 1),
		Position = UDim2.new(0.1, 0, 1, -1),
	}):Play()
	if self._islandGlow then
		Tween(self._islandGlow, {ImageTransparency = 0.3}):Play()
	end
end

function SkeetIsland:_CollapseIsland()
	if not self.IsExpanded or self.IsOpen then return end
	self.IsExpanded = false
	local w, h = THEME.IslandCollapsedW, THEME.IslandCollapsedH
	Tween(self.IslandContainer, {
		Size     = UDim2.new(0, w, 0, h),
		Position = UDim2.new(0.5, -w/2, 0, 12),
	}):Play()
	Tween(self._islandLine, {
		Size = UDim2.new(0.6, 0, 0, 1),
		Position = UDim2.new(0.2, 0, 1, -1),
	}):Play()
	if self._islandGlow then
		Tween(self._islandGlow, {ImageTransparency = 0.55}):Play()
	end
end

-- ══════════════════════════════════════════
-- 	MAIN PANEL
-- ══════════════════════════════════════════
function SkeetIsland:_BuildMainPanel()
	self.MainPanel = GlassFrame(
		"MainPanel",
		UDim2.new(0, 360, 0, 420),
		UDim2.new(0.5, -180, 0, 70),
		self.ScreenGui,
		UDim.new(0, 18)
	)
	self.MainPanel.BackgroundTransparency = 0.08
	self.MainPanel.ZIndex = 40
	self.MainPanel.Visible = false

	-- Gradient glow behind panel
	if self.GradientGlow then
		GlowFrame(self.MainPanel, self.AccentColor, 40)
	end

	-- Header
	local header = MakeInstance("Frame", {
		Name              = "Header",
		Size              = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		ZIndex            = 41,
	}, self.MainPanel)

	-- Title gradient text (via UIGradient on TextLabel — faked with two labels)
	local titleLabel = MakeInstance("TextLabel", {
		Name              = "Title",
		Size              = UDim2.new(1, -100, 1, 0),
		Position          = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
		Text              = self.Title,
		TextColor3        = THEME.TextPrimary,
		TextSize          = 20,
		Font              = Enum.Font.GothamBlack,
		TextXAlignment    = Enum.TextXAlignment.Left,
		ZIndex            = 42,
	}, header)

	MakeInstance("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 180, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 220, 255)),
		}),
	}, titleLabel)

	-- Subtitle
	MakeInstance("TextLabel", {
		Name              = "SubTitle",
		Size              = UDim2.new(0, 100, 0, 14),
		Position          = UDim2.new(0, 16, 0, 28),
		BackgroundTransparency = 1,
		Text              = self.SubTitle,
		TextColor3        = THEME.TextSecondary,
		TextSize          = 11,
		Font              = Enum.Font.Gotham,
		TextXAlignment    = Enum.TextXAlignment.Left,
		ZIndex            = 42,
	}, header)

	-- Close button
	local closeBtn = MakeInstance("TextButton", {
		Name              = "Close",
		Size              = UDim2.new(0, 28, 0, 28),
		Position          = UDim2.new(1, -40, 0.5, -14),
		BackgroundColor3  = Color3.fromRGB(255, 80, 80),
		BackgroundTransparency = 0.5,
		Text              = "✕",
		TextColor3        = Color3.fromRGB(255, 255, 255),
		TextSize          = 13,
		Font              = Enum.Font.GothamBold,
		BorderSizePixel   = 0,
		ZIndex            = 45,
	}, header)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, closeBtn)

	closeBtn.MouseButton1Click:Connect(function()
		self:ClosePanel()
	end)

	-- Settings button
	local settingsBtn = MakeInstance("TextButton", {
		Name              = "Settings",
		Size              = UDim2.new(0, 28, 0, 28),
		Position          = UDim2.new(1, -76, 0.5, -14),
		BackgroundColor3  = THEME.GlassBase,
		BackgroundTransparency = 0.4,
		Text              = "⚙",
		TextColor3        = THEME.TextSecondary,
		TextSize          = 14,
		Font              = Enum.Font.GothamBold,
		BorderSizePixel   = 0,
		ZIndex            = 45,
	}, header)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, settingsBtn)
	settingsBtn.MouseButton1Click:Connect(function()
		self:OpenSettings()
	end)

	-- Divider line
	local divider = MakeInstance("Frame", {
		Name              = "Divider",
		Size              = UDim2.new(1, -32, 0, 1),
		Position          = UDim2.new(0, 16, 0, 50),
		BackgroundColor3  = THEME.GlassBorder,
		BackgroundTransparency = 0.7,
		BorderSizePixel   = 0,
		ZIndex            = 42,
	}, self.MainPanel)

	MakeInstance("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0),
			NumberSequenceKeypoint.new(0.7, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, divider)

	-- Tab bar
	self._tabBar = MakeInstance("Frame", {
		Name              = "TabBar",
		Size              = UDim2.new(1, -32, 0, 32),
		Position          = UDim2.new(0, 16, 0, 58),
		BackgroundTransparency = 1,
		ZIndex            = 42,
	}, self.MainPanel)

	MakeInstance("UIListLayout", {
		FillDirection     = Enum.FillDirection.Horizontal,
		SortOrder         = Enum.SortOrder.LayoutOrder,
		Padding           = UDim.new(0, 6),
	}, self._tabBar)

	-- Content area
	self._contentArea = MakeInstance("Frame", {
		Name              = "ContentArea",
		Size              = UDim2.new(1, -32, 1, -106),
		Position          = UDim2.new(0, 16, 0, 98),
		BackgroundTransparency = 1,
		ClipsDescendants  = true,
		ZIndex            = 42,
	}, self.MainPanel)

	-- Shine on main panel
	local shine = ShineEffect(self.MainPanel, 120, 1)
	shine.ZIndex = 43
	AnimateShine(shine, 360)

	self._mainShine = shine
end

-- ══════════════════════════════════════════
-- 	SETTINGS PANEL
-- ══════════════════════════════════════════
function SkeetIsland:_BuildSettingsPanel()
	self.SettingsPanel = GlassFrame(
		"SettingsPanel",
		UDim2.new(0, 300, 0, 340),
		UDim2.new(0.5, -150, 0, 130),
		self.ScreenGui,
		UDim.new(0, 18)
	)
	self.SettingsPanel.BackgroundTransparency = 0.08
	self.SettingsPanel.ZIndex = 60
	self.SettingsPanel.Visible = false

	local titleL = MakeInstance("TextLabel", {
		Size              = UDim2.new(1, -50, 0, 44),
		Position          = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
		Text              = "Settings",
		TextColor3        = THEME.TextPrimary,
		TextSize          = 17,
		Font              = Enum.Font.GothamBlack,
		TextXAlignment    = Enum.TextXAlignment.Left,
		ZIndex            = 61,
	}, self.SettingsPanel)

	MakeInstance("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 180, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 220, 255)),
		}),
	}, titleL)

	local backBtn = MakeInstance("TextButton", {
		Size              = UDim2.new(0, 28, 0, 28),
		Position          = UDim2.new(1, -40, 0, 8),
		BackgroundColor3  = THEME.GlassBase,
		BackgroundTransparency = 0.4,
		Text              = "←",
		TextColor3        = THEME.TextSecondary,
		TextSize          = 16,
		Font              = Enum.Font.GothamBold,
		BorderSizePixel   = 0,
		ZIndex            = 65,
	}, self.SettingsPanel)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, backBtn)

	backBtn.MouseButton1Click:Connect(function()
		self.SettingsPanel.Visible = false
		self.SettingsPanel.BackgroundTransparency = 1
		Tween(self.SettingsPanel, {BackgroundTransparency = 0.08}):Play()
	end)

	-- Settings scroll
	self._settingsScroll = MakeInstance("ScrollingFrame", {
		Size              = UDim2.new(1, -16, 1, -52),
		Position          = UDim2.new(0, 8, 0, 50),
		BackgroundTransparency = 1,
		BorderSizePixel   = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = self.AccentColor,
		ZIndex            = 62,
	}, self.SettingsPanel)

	MakeInstance("UIListLayout", {
		SortOrder  = Enum.SortOrder.LayoutOrder,
		Padding    = UDim.new(0, 6),
	}, self._settingsScroll)

	MakeInstance("UIPadding", {
		PaddingLeft   = UDim.new(0, 4),
		PaddingRight  = UDim.new(0, 4),
	}, self._settingsScroll)

	-- Default settings items
	self:AddSetting("Gradient Glow",  "toggle",  self.GradientGlow, function(val)
		self.GradientGlow = val
		if self._islandGlow then
			self._islandGlow.Visible = val
		end
	end)

	self:AddSetting("Accent Color", "label", "Purple/Blue")
	self:AddSetting("Notifications", "toggle", true, function(val)
		self._notifsEnabled = val
	end)
	self:AddSetting("UI Scale", "label", "100%")
end

-- ══════════════════════════════════════════
-- 	KEY SYSTEM
-- ══════════════════════════════════════════
function SkeetIsland:_ShowKeySystem()
	self.KeyPanel = GlassFrame(
		"KeyPanel",
		UDim2.new(0, 340, 0, 280),
		UDim2.new(0.5, -170, 0.5, -140),
		self.ScreenGui,
		UDim.new(0, 20)
	)
	self.KeyPanel.BackgroundTransparency = 0.05
	self.KeyPanel.ZIndex = 80

	if self.GradientGlow then
		GlowFrame(self.KeyPanel, self.AccentColor, 50)
	end

	local shine = ShineEffect(self.KeyPanel, 140, 1)
	AnimateShine(shine, 340)

	-- Logo / title
	local logo = MakeInstance("TextLabel", {
		Size              = UDim2.new(1, 0, 0, 60),
		Position          = UDim2.new(0, 0, 0, 20),
		BackgroundTransparency = 1,
		Text              = self.Title,
		TextColor3        = Color3.fromRGB(255, 255, 255),
		TextSize          = 28,
		Font              = Enum.Font.GothamBlack,
		TextXAlignment    = Enum.TextXAlignment.Center,
		ZIndex            = 81,
	}, self.KeyPanel)

	MakeInstance("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 150, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 210, 255)),
		}),
	}, logo)

	MakeInstance("TextLabel", {
		Size              = UDim2.new(1, 0, 0, 20),
		Position          = UDim2.new(0, 0, 0, 82),
		BackgroundTransparency = 1,
		Text              = "Enter your key to continue",
		TextColor3        = THEME.TextSecondary,
		TextSize          = 12,
		Font              = Enum.Font.Gotham,
		TextXAlignment    = Enum.TextXAlignment.Center,
		ZIndex            = 81,
	}, self.KeyPanel)

	-- Key input box
	local inputFrame = MakeInstance("Frame", {
		Size              = UDim2.new(1, -40, 0, 38),
		Position          = UDim2.new(0, 20, 0, 118),
		BackgroundColor3  = Color3.fromRGB(8, 8, 12),
		BackgroundTransparency = 0.2,
		BorderSizePixel   = 0,
		ZIndex            = 82,
	}, self.KeyPanel)
	MakeInstance("UICorner", {CornerRadius = UDim.new(0, 12)}, inputFrame)
	MakeInstance("UIStroke", {
		Color        = THEME.AccentPrimary,
		Transparency = 0.6,
		Thickness    = 1,
	}, inputFrame)

	local input = MakeInstance("TextBox", {
		Size              = UDim2.new(1, -20, 1, 0),
		Position          = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text              = "",
		PlaceholderText   = "sk-XXXX-XXXX-XXXX",
		PlaceholderColor3 = THEME.TextMuted,
		TextColor3        = THEME.TextPrimary,
		TextSize          = 13,
		Font              = Enum.Font.Code,
		ClearTextOnFocus  = false,
		ZIndex            = 83,
	}, inputFrame)

	-- Status label
	local statusL = MakeInstance("TextLabel", {
		Size              = UDim2.new(1, 0, 0, 18),
		Position          = UDim2.new(0, 0, 0, 164),
		BackgroundTransparency = 1,
		Text              = "",
		TextColor3        = THEME.Error,
		TextSize          = 11,
		Font              = Enum.Font.Gotham,
		TextXAlignment    = Enum.TextXAlignment.Center,
		ZIndex            = 82,
	}, self.KeyPanel)

	-- Submit button
	local submitBtn = MakeInstance("TextButton", {
		Size              = UDim2.new(1, -40, 0, 40),
		Position          = UDim2.new(0, 20, 0, 190),
		BackgroundColor3  = self.AccentColor,
		BackgroundTransparency = 0.1,
		Text              = "UNLOCK",
		TextColor3        = Color3.fromRGB(255, 255, 255),
		TextSize          = 13,
		Font              = Enum.Font.GothamBlack,
		BorderSizePixel   = 0,
		ZIndex            = 83,
	}, self.KeyPanel)
	MakeInstance("UICorner", {CornerRadius = UDim.new(0, 12)}, submitBtn)

	MakeInstance("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 160, 255)),
		}),
	}, submitBtn)

	submitBtn.MouseButton1Click:Connect(function()
		local entered = input.Text
		if entered == self.ValidKey then
			self.KeyVerified = true
			statusL.Text = "✓ Key accepted!"
			statusL.TextColor3 = THEME.Success
			Tween(self.KeyPanel, {
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, -170, 0.5, -200),
			}, 0.5):Play()
			task.delay(0.5, function()
				self.KeyPanel:Destroy()
				self:_ShowWelcome()
			end)
		else
			statusL.Text = "✗ Invalid key. Try again."
			statusL.TextColor3 = THEME.Error
			Tween(inputFrame, {BackgroundColor3 = Color3.fromRGB(60, 10, 10)}, 0.1):Play()
			task.delay(0.3, function()
				Tween(inputFrame, {BackgroundColor3 = Color3.fromRGB(8, 8, 12)}, 0.3):Play()
			end)
		end
	end)
end

-- ══════════════════════════════════════════
-- 	WELCOME SCREEN
-- ══════════════════════════════════════════
function SkeetIsland:_ShowWelcome()
	local welcome = GlassFrame(
		"WelcomeScreen",
		UDim2.new(0, 360, 0, 200),
		UDim2.new(0.5, -180, 0.5, -100),
		self.ScreenGui,
		UDim.new(0, 20)
	)
	welcome.BackgroundTransparency = 1
	welcome.ZIndex = 75

	if self.GradientGlow then
		GlowFrame(welcome, self.AccentColor, 60)
	end

	Tween(welcome, {BackgroundTransparency = 0.05}, 0.6):Play()

	local greet = MakeInstance("TextLabel", {
		Size              = UDim2.new(1, 0, 0, 50),
		Position          = UDim2.new(0, 0, 0, 30),
		BackgroundTransparency = 1,
		Text              = "Welcome back,",
		TextColor3        = THEME.TextSecondary,
		TextSize          = 14,
		Font              = Enum.Font.Gotham,
		TextXAlignment    = Enum.TextXAlignment.Center,
		ZIndex            = 76,
	}, welcome)

	local nameL = MakeInstance("TextLabel", {
		Size              = UDim2.new(1, 0, 0, 50),
		Position          = UDim2.new(0, 0, 0, 68),
		BackgroundTransparency = 1,
		Text              = LocalPlayer.DisplayName,
		TextColor3        = Color3.fromRGB(255,255,255),
		TextSize          = 30,
		Font              = Enum.Font.GothamBlack,
		TextXAlignment    = Enum.TextXAlignment.Center,
		ZIndex            = 76,
	}, welcome)

	MakeInstance("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 150, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 210, 255)),
		}),
	}, nameL)

	local shine = ShineEffect(welcome, 160, 1)
	AnimateShine(shine, 360)

	-- Auto dismiss
	task.delay(2.5, function()
		Tween(welcome, {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, -180, 0.5, -160),
		}, 0.6):Play()
		task.delay(0.6, function()
			welcome:Destroy()
		end)
	end)
end

-- ══════════════════════════════════════════
-- 	OPEN / CLOSE PANEL
-- ══════════════════════════════════════════
function SkeetIsland:OpenPanel()
	if self.IsOpen or not self.KeyVerified then return end
	self.IsOpen = true
	self.IsExpanded = false

	local w, h = THEME.IslandOpenW, THEME.IslandOpenH
	-- Expand island to full panel size
	Tween(self.IslandContainer, {
		Size     = UDim2.new(0, w, 0, 34),
		Position = UDim2.new(0.5, -w/2, 0, 10),
	}, 0.2):Play()

	task.delay(0.15, function()
		self.MainPanel.Visible = true
		self.MainPanel.BackgroundTransparency = 1
		self.MainPanel.Position = UDim2.new(0.5, -180, 0, 56)
		Tween(self.MainPanel, {
			BackgroundTransparency = 0.08,
			Position = UDim2.new(0.5, -180, 0, 60),
		}, 0.35):Play()
	end)

	-- Update island title
	self._islandTitle.Text = "Menu Opened"
	self._statusDot.BackgroundColor3 = THEME.Success

	if self._islandGlow then
		Tween(self._islandGlow, {ImageTransparency = 0.2}):Play()
	end
end

function SkeetIsland:ClosePanel()
	if not self.IsOpen then return end
	self.IsOpen = false

	Tween(self.MainPanel, {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, -180, 0, 40),
	}, 0.25):Play()

	task.delay(0.25, function()
		self.MainPanel.Visible = false
		self:_CollapseIsland()
	end)

	self._islandTitle.Text = self.Title
	self._statusDot.BackgroundColor3 = THEME.Error

	if self._islandGlow then
		Tween(self._islandGlow, {ImageTransparency = 0.55}):Play()
	end
end

function SkeetIsland:OpenSettings()
	self.SettingsPanel.Visible = true
	self.SettingsPanel.BackgroundTransparency = 1
	self.SettingsPanel.Position = UDim2.new(0.5, -150, 0, 80)
	Tween(self.SettingsPanel, {
		BackgroundTransparency = 0.08,
		Position = UDim2.new(0.5, -150, 0, 100),
	}, 0.3):Play()
end

-- ══════════════════════════════════════════
-- 	TABS
-- ══════════════════════════════════════════
function SkeetIsland:AddTab(name, icon)
	local tabFrame = MakeInstance("TextButton", {
		Name              = name .. "Tab",
		Size              = UDim2.new(0, 0, 1, 0),
		AutomaticSize     = Enum.AutomaticSize.X,
		BackgroundColor3  = THEME.GlassBase,
		BackgroundTransparency = 0.5,
		Text              = (icon and icon .. "  " or "") .. name,
		TextColor3        = THEME.TextSecondary,
		TextSize          = 12,
		Font              = Enum.Font.GothamBold,
		BorderSizePixel   = 0,
		ZIndex            = 43,
	}, self._tabBar)

	MakeInstance("UICorner", {CornerRadius = UDim.new(0, 8)}, tabFrame)
	MakeInstance("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, tabFrame)

	-- Content frame for this tab
	local content = MakeInstance("Frame", {
		Name              = name .. "Content",
		Size              = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible           = false,
		ZIndex            = 43,
	}, self._contentArea)

	MakeInstance("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding   = UDim.new(0, 6),
	}, content)

	MakeInstance("UIPadding", {
		PaddingBottom = UDim.new(0, 8),
	}, content)

	local tab = {
		Name    = name,
		Button  = tabFrame,
		Content = content,
	}
	table.insert(self.Tabs, tab)

	tabFrame.MouseButton1Click:Connect(function()
		self:_SelectTab(tab)
	end)

	-- Select first tab automatically
	if #self.Tabs == 1 then
		self:_SelectTab(tab)
	end

	return tab
end

function SkeetIsland:_SelectTab(selected)
	for _, tab in ipairs(self.Tabs) do
		tab.Content.Visible = false
		Tween(tab.Button, {
			BackgroundTransparency = 0.5,
		}, 0.15):Play()
		tab.Button.TextColor3 = THEME.TextSecondary
	end

	selected.Content.Visible = true
	Tween(selected.Button, {
		BackgroundTransparency = 0.15,
	}, 0.15):Play()
	selected.Button.TextColor3 = THEME.TextPrimary

	-- Active indicator gradient
	if selected.Button:FindFirstChild("ActiveLine") then
		selected.Button.ActiveLine:Destroy()
	end
	local line = MakeInstance("Frame", {
		Name              = "ActiveLine",
		Size              = UDim2.new(0.8, 0, 0, 2),
		Position          = UDim2.new(0.1, 0, 1, -2),
		BackgroundColor3  = self.AccentColor,
		BorderSizePixel   = 0,
		ZIndex            = 44,
	}, selected.Button)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, line)
end

-- ══════════════════════════════════════════
-- 	ELEMENTS
-- ══════════════════════════════════════════
function SkeetIsland:AddToggle(tab, text, default, callback)
	local row = MakeInstance("Frame", {
		Name              = text .. "Toggle",
		Size              = UDim2.new(1, 0, 0, 38),
		BackgroundColor3  = THEME.GlassBase,
		BackgroundTransparency = 0.5,
		BorderSizePixel   = 0,
		ZIndex            = 44,
	}, tab.Content)
	MakeInstance("UICorner", {CornerRadius = UDim.new(0, 10)}, row)

	MakeInstance("TextLabel", {
		Size              = UDim2.new(1, -60, 1, 0),
		Position          = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text              = text,
		TextColor3        = THEME.TextPrimary,
		TextSize          = 13,
		Font              = Enum.Font.Gotham,
		TextXAlignment    = Enum.TextXAlignment.Left,
		ZIndex            = 45,
	}, row)

	local enabled = default or false

	local pill = MakeInstance("Frame", {
		Size              = UDim2.new(0, 40, 0, 22),
		Position          = UDim2.new(1, -52, 0.5, -11),
		BackgroundColor3  = enabled and self.AccentColor or Color3.fromRGB(50, 50, 60),
		BorderSizePixel   = 0,
		ZIndex            = 46,
	}, row)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, pill)

	local knob = MakeInstance("Frame", {
		Size              = UDim2.new(0, 16, 0, 16),
		Position          = enabled and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
		BackgroundColor3  = Color3.fromRGB(255, 255, 255),
		BorderSizePixel   = 0,
		ZIndex            = 47,
	}, pill)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

	local btn = MakeInstance("TextButton", {
		Size              = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text              = "",
		ZIndex            = 48,
	}, row)

	btn.MouseButton1Click:Connect(function()
		enabled = not enabled
		Tween(pill, {BackgroundColor3 = enabled and self.AccentColor or Color3.fromRGB(50,50,60)}, 0.18):Play()
		Tween(knob, {Position = enabled and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}, 0.18):Play()
		if callback then callback(enabled) end
	end)

	return row
end

function SkeetIsland:AddButton(tab, text, callback)
	local btn = MakeInstance("TextButton", {
		Name              = text .. "Btn",
		Size              = UDim2.new(1, 0, 0, 38),
		BackgroundColor3  = self.AccentColor,
		BackgroundTransparency = 0.2,
		Text              = text,
		TextColor3        = Color3.fromRGB(255, 255, 255),
		TextSize          = 13,
		Font              = Enum.Font.GothamBold,
		BorderSizePixel   = 0,
		ZIndex            = 44,
	}, tab.Content)
	MakeInstance("UICorner", {CornerRadius = UDim.new(0, 10)}, btn)

	MakeInstance("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 160, 255)),
		}),
	}, btn)

	btn.MouseButton1Click:Connect(function()
		Tween(btn, {BackgroundTransparency = 0.5}, 0.08):Play()
		task.delay(0.1, function()
			Tween(btn, {BackgroundTransparency = 0.2}, 0.15):Play()
		end)
		if callback then callback() end
	end)

	return btn
end

function SkeetIsland:AddSlider(tab, text, min, max, default, callback)
	local container = MakeInstance("Frame", {
		Name              = text .. "Slider",
		Size              = UDim2.new(1, 0, 0, 52),
		BackgroundColor3  = THEME.GlassBase,
		BackgroundTransparency = 0.5,
		BorderSizePixel   = 0,
		ZIndex            = 44,
	}, tab.Content)
	MakeInstance("UICorner", {CornerRadius = UDim.new(0, 10)}, container)

	local label = MakeInstance("TextLabel", {
		Size              = UDim2.new(1, -16, 0, 22),
		Position          = UDim2.new(0, 12, 0, 4),
		BackgroundTransparency = 1,
		Text              = text .. ":  " .. tostring(default or min),
		TextColor3        = THEME.TextPrimary,
		TextSize          = 12,
		Font              = Enum.Font.Gotham,
		TextXAlignment    = Enum.TextXAlignment.Left,
		ZIndex            = 45,
	}, container)

	local track = MakeInstance("Frame", {
		Size              = UDim2.new(1, -24, 0, 4),
		Position          = UDim2.new(0, 12, 0, 32),
		BackgroundColor3  = Color3.fromRGB(40, 40, 55),
		BorderSizePixel   = 0,
		ZIndex            = 45,
	}, container)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, track)

	local val = default or min
	local pct = (val - min) / (max - min)

	local fill = MakeInstance("Frame", {
		Size              = UDim2.new(pct, 0, 1, 0),
		BackgroundColor3  = self.AccentColor,
		BorderSizePixel   = 0,
		ZIndex            = 46,
	}, track)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, fill)

	MakeInstance("UIGradient", {
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 160, 255)),
		}),
	}, fill)

	local handle = MakeInstance("Frame", {
		Size              = UDim2.new(0, 14, 0, 14),
		Position          = UDim2.new(pct, -7, 0.5, -7),
		BackgroundColor3  = Color3.fromRGB(255, 255, 255),
		BorderSizePixel   = 0,
		ZIndex            = 47,
	}, track)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, handle)

	local dragging = false
	local btn = MakeInstance("TextButton", {
		Size              = UDim2.new(1, 0, 4, 0),
		Position          = UDim2.new(0, 0, -1.5, 0),
		BackgroundTransparency = 1,
		Text              = "",
		ZIndex            = 48,
	}, track)

	local function updateSlider(inputPos)
		local trackPos = track.AbsolutePosition.X
		local trackW   = track.AbsoluteSize.X
		local rel      = math.clamp((inputPos - trackPos) / trackW, 0, 1)
		local newVal   = math.floor(min + rel * (max - min))
		label.Text = text .. ":  " .. newVal
		Tween(fill, {Size = UDim2.new(rel, 0, 1, 0)}, 0.05):Play()
		Tween(handle, {Position = UDim2.new(rel, -7, 0.5, -7)}, 0.05):Play()
		if callback then callback(newVal) end
	end

	btn.MouseButton1Down:Connect(function()
		dragging = true
	end)

	self._connections[#self._connections+1] = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input.Position.X)
		end
	end)

	self._connections[#self._connections+1] = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	btn.MouseButton1Click:Connect(function()
		updateSlider(UserInputService:GetMouseLocation().X)
	end)

	return container
end

function SkeetIsland:AddLabel(tab, text)
	local l = MakeInstance("TextLabel", {
		Size              = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Text              = text,
		TextColor3        = THEME.TextMuted,
		TextSize          = 11,
		Font              = Enum.Font.Gotham,
		TextXAlignment    = Enum.TextXAlignment.Left,
		ZIndex            = 44,
	}, tab.Content)

	MakeInstance("UIPadding", {PaddingLeft = UDim.new(0, 4)}, l)
	return l
end

-- ══════════════════════════════════════════
-- 	SETTINGS ITEMS
-- ══════════════════════════════════════════
function SkeetIsland:AddSetting(name, settingType, default, callback)
	local row = MakeInstance("Frame", {
		Size              = UDim2.new(1, 0, 0, 38),
		BackgroundColor3  = THEME.GlassBase,
		BackgroundTransparency = 0.5,
		BorderSizePixel   = 0,
		ZIndex            = 63,
	}, self._settingsScroll)
	MakeInstance("UICorner", {CornerRadius = UDim.new(0, 10)}, row)

	MakeInstance("TextLabel", {
		Size              = UDim2.new(1, -80, 1, 0),
		Position          = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text              = name,
		TextColor3        = THEME.TextPrimary,
		TextSize          = 12,
		Font              = Enum.Font.Gotham,
		TextXAlignment    = Enum.TextXAlignment.Left,
		ZIndex            = 64,
	}, row)

	if settingType == "toggle" then
		local enabled = default or false
		local pill = MakeInstance("Frame", {
			Size              = UDim2.new(0, 36, 0, 20),
			Position          = UDim2.new(1, -46, 0.5, -10),
			BackgroundColor3  = enabled and self.AccentColor or Color3.fromRGB(50, 50, 60),
			BorderSizePixel   = 0,
			ZIndex            = 65,
		}, row)
		MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, pill)

		local knob = MakeInstance("Frame", {
			Size              = UDim2.new(0, 14, 0, 14),
			Position          = enabled and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
			BackgroundColor3  = Color3.fromRGB(255,255,255),
			BorderSizePixel   = 0,
			ZIndex            = 66,
		}, pill)
		MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, knob)

		local btn = MakeInstance("TextButton", {
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 67,
		}, row)

		btn.MouseButton1Click:Connect(function()
			enabled = not enabled
			Tween(pill, {BackgroundColor3 = enabled and self.AccentColor or Color3.fromRGB(50,50,60)}, 0.18):Play()
			Tween(knob, {Position = enabled and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}, 0.18):Play()
			if callback then callback(enabled) end
		end)

	elseif settingType == "label" then
		MakeInstance("TextLabel", {
			Size              = UDim2.new(0, 70, 1, 0),
			Position          = UDim2.new(1, -76, 0, 0),
			BackgroundTransparency = 1,
			Text              = tostring(default),
			TextColor3        = THEME.TextSecondary,
			TextSize          = 11,
			Font              = Enum.Font.Gotham,
			TextXAlignment    = Enum.TextXAlignment.Right,
			ZIndex            = 64,
		}, row)
	end

	-- Update canvas size
	local layout = self._settingsScroll:FindFirstChildOfClass("UIListLayout")
	if layout then
		self._settingsScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end

	return row
end

-- ══════════════════════════════════════════
-- 	NOTIFICATION SYSTEM
-- ══════════════════════════════════════════
--[[
	Crazy unique idea: Notifications drift up from the island itself,
	like "bubbles" detaching from the island and floating to the corner.
	Each has its own glass card with type-specific glowing border,
	an icon that pulses, and a progress bar that burns down.
	They stack beautifully with stagger animations.
]]
function SkeetIsland:Notify(config)
	if self._notifsEnabled == false then return end

	config = config or {}
	local title    = config.Title or "Notification"
	local message  = config.Message or ""
	local duration = config.Duration or 4
	local notifType = config.Type or "info" -- info, success, warning, error

	local typeColors = {
		info    = THEME.Info,
		success = THEME.Success,
		warning = THEME.Warning,
		error   = THEME.Error,
	}
	local typeIcons = {
		info    = "ℹ",
		success = "✓",
		warning = "⚠",
		error   = "✕",
	}

	local accentColor = typeColors[notifType] or THEME.Info

	-- Card
	local card = MakeInstance("Frame", {
		Name              = "Notif_" .. title,
		Size              = UDim2.new(1, 0, 0, 72),
		BackgroundColor3  = Color3.fromRGB(12, 12, 18),
		BackgroundTransparency = 0.1,
		BorderSizePixel   = 0,
		LayoutOrder       = #self.Notifications,
		ClipsDescendants  = true,
		ZIndex            = 101,
	}, self.NotifContainer)
	MakeInstance("UICorner", {CornerRadius = UDim.new(0, 16)}, card)

	-- Glass border
	local stroke = MakeInstance("UIStroke", {
		Color        = accentColor,
		Transparency = 0.4,
		Thickness    = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, card)

	-- Side accent bar
	MakeInstance("Frame", {
		Size              = UDim2.new(0, 3, 0.7, 0),
		Position          = UDim2.new(0, 0, 0.15, 0),
		BackgroundColor3  = accentColor,
		BorderSizePixel   = 0,
		ZIndex            = 102,
	}, card)

	-- Glow
	GlowFrame(card, accentColor, 20)

	-- Icon circle
	local iconCircle = MakeInstance("Frame", {
		Size              = UDim2.new(0, 32, 0, 32),
		Position          = UDim2.new(0, 14, 0.5, -16),
		BackgroundColor3  = accentColor,
		BackgroundTransparency = 0.6,
		BorderSizePixel   = 0,
		ZIndex            = 102,
	}, card)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, iconCircle)

	MakeInstance("TextLabel", {
		Size              = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text              = typeIcons[notifType] or "•",
		TextColor3        = accentColor,
		TextSize          = 14,
		Font              = Enum.Font.GothamBold,
		TextXAlignment    = Enum.TextXAlignment.Center,
		ZIndex            = 103,
	}, iconCircle)

	-- Title
	MakeInstance("TextLabel", {
		Size              = UDim2.new(1, -68, 0, 22),
		Position          = UDim2.new(0, 56, 0, 10),
		BackgroundTransparency = 1,
		Text              = title,
		TextColor3        = Color3.fromRGB(240, 240, 255),
		TextSize          = 13,
		Font              = Enum.Font.GothamBold,
		TextXAlignment    = Enum.TextXAlignment.Left,
		ZIndex            = 102,
	}, card)

	-- Message
	MakeInstance("TextLabel", {
		Size              = UDim2.new(1, -68, 0, 20),
		Position          = UDim2.new(0, 56, 0, 30),
		BackgroundTransparency = 1,
		Text              = message,
		TextColor3        = THEME.TextSecondary,
		TextSize          = 11,
		Font              = Enum.Font.Gotham,
		TextXAlignment    = Enum.TextXAlignment.Left,
		TextTruncate      = Enum.TextTruncate.AtEnd,
		ZIndex            = 102,
	}, card)

	-- Progress bar track
	local progTrack = MakeInstance("Frame", {
		Size              = UDim2.new(1, -16, 0, 2),
		Position          = UDim2.new(0, 8, 1, -4),
		BackgroundColor3  = Color3.fromRGB(30, 30, 40),
		BorderSizePixel   = 0,
		ZIndex            = 103,
	}, card)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, progTrack)

	local progFill = MakeInstance("Frame", {
		Size              = UDim2.new(1, 0, 1, 0),
		BackgroundColor3  = accentColor,
		BorderSizePixel   = 0,
		ZIndex            = 104,
	}, progTrack)
	MakeInstance("UICorner", {CornerRadius = UDim.new(1,0)}, progFill)

	-- Shine on notif
	local shine = ShineEffect(card, 80, 1)
	shine.ZIndex = 105
	AnimateShine(shine, 320)

	-- Slide in from right
	card.Position = UDim2.new(1, 20, 0, 0)
	Tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()

	-- Pulse icon
	local function pulseIcon()
		Tween(iconCircle, {BackgroundTransparency = 0.2}, 0.4):Play()
		task.delay(0.4, function()
			Tween(iconCircle, {BackgroundTransparency = 0.6}, 0.4):Play()
		end)
	end
	pulseIcon()

	-- Progress bar countdown
	Tween(progFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear):Play()

	-- Dismiss
	local function dismiss()
		Tween(card, {
			BackgroundTransparency = 1,
			Position = UDim2.new(1, 20, 0, 0),
		}, 0.3):Play()
		task.delay(0.3, function()
			card:Destroy()
		end)
	end

	-- Click to dismiss
	local dismissBtn = MakeInstance("TextButton", {
		Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 110,
	}, card)
	dismissBtn.MouseButton1Click:Connect(dismiss)

	task.delay(duration, dismiss)

	table.insert(self.Notifications, card)

	-- Update canvas
	self.NotifContainer.CanvasSize = UDim2.new(0, 0, 0, #self.Notifications * 80)
end

-- ══════════════════════════════════════════
-- 	CLOCK
-- ══════════════════════════════════════════
function SkeetIsland:_StartClock()
	self._connections[#self._connections+1] = RunService.Heartbeat:Connect(function()
		local t = os.time()
		local h = math.floor(t / 3600) % 24
		local m = math.floor(t / 60) % 60
		self._timeLabel.Text = string.format("%02d:%02d", h, m)
	end)
end

-- ══════════════════════════════════════════
-- 	DESTROY
-- ══════════════════════════════════════════
function SkeetIsland:Destroy()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end

-- ══════════════════════════════════════════
-- 	THEME CUSTOMIZER
-- ══════════════════════════════════════════
function SkeetIsland:SetAccent(color)
	self.AccentColor = color
	if self._islandLine then
		self._islandLine.BackgroundColor3 = color
	end
	if self._islandGlow then
		self._islandGlow.ImageColor3 = color
	end
end

return SkeetIsland

-- StarterPlayerScripts/AutoTrain.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local TrainRemote = Remotes:WaitForChild("RemoteEvent")

-- ===== SETTINGS =====
local TRAIN_DELAY = 0.25
local Y_OFFSET = 6

-- Big numbers
local K  = 1_000
local M  = 1_000_000
local B  = 1_000_000_000
local T  = 1_000_000_000_000
local QD = 1_000_000_000_000_000 -- quadrillion (10^15)

-- ===== Stat IDs (also Train IDs) =====
local STAT_ID = {
	Strength   = 1,
	Durability = 2,
	Chakra     = 3,
	Sword      = 4,
	Agility    = 5,
	Speed      = 6,
}

-- ===== Spots (merged + corrected) =====
-- Best spot = highest req <= current stat value
local SPOTS = {
	Strength = {
		{ req = 100,    path = "Workspace.Map.TrainingAreas.Training Dummy", label = "Dummy (100 Strength)" },
		{ req = 100*K,  path = "Workspace.Map.TrainingAreas.Fridge.Part", label = "Fridge (100K Strength)" },
		{ req = 1*M,    path = "Workspace.Map.TrainingAreas.Meteor", label = "Meteor (1M Strength)" },
		{ req = 100*M,  path = "Workspace.Map.TrainingAreas.Arena.Part", label = "Arena (100M Strength)" },
		{ req = 1*B,    path = "Workspace.Map.TrainingAreas.ExcaliburRocks.Model", label = "Excalibur (1B Strength)" },
		{ req = 50*T,   path = "Workspace.Map.TrainingAreas.FloatingIsland", label = "Floating Island (50T Strength)" },
	},

	Durability = {
		{ req = 100,    path = "Workspace.Map.TrainingAreas.Pirate ship.Model", label = "Ship (100 Durability)" },
		{ req = 1*M,    path = "Workspace.Map.TrainingAreas.Paw", label = "Paw (1M Durability)" },
		{ req = 100*M,  path = "Workspace.Map.TrainingAreas.BlackFire.Fire", label = "Black Flames (100M Durability)" },
	},

	Chakra = {
		-- CHANGED: Chakra Tree target
		{ req = 100,    path = "Workspace.Map.TrainingAreas.Tree1.ObjectRoot", label = "Chakra Tree (100 Chakra)" },
		{ req = 100*K,  path = "Workspace.Map.TrainingAreas.Waterfall.Pillar", label = "Waterfall (100K Chakra)" },
		{ req = 10*M,   path = "Workspace.Map.TrainingAreas.Fox.Fox", label = "Fox Statue (10M Chakra)" },
		{ req = 100*M,  path = "Workspace.Map.TrainingAreas.PinkSwords.Handle", label = "Sakura Tree (100M Chakra)" },
		{ req = 50*T,   path = "Workspace.Map.TrainingAreas.RamenShop.polySurface481", label = "Ramen Shop (50T Chakra)" },
		{ req = 25*QD,  path = "Workspace.Map.TrainingAreas.Ultimate Dragon.Meshes/shenron4", label = "Dragon (25QD Chakra)" },
	},

	Agility = {
		{ req = 100,    path = "Workspace.Map.TrainingAreas.Trampoline.Bouncy", label = "Trampoline (100 Agility)" },
		{ req = 10*K,   path = "Workspace.Map.TrainingAreas.Gravity.Part", label = "Gravity Chamber (10K Agility)" },
	},

	Speed = {
		{ req = 100,    path = "Workspace.Map.TrainingAreas.Treadmills", label = "Treadmills (100 Speed)" },
		{ req = 10*K,   path = "Workspace.Map.TrainingAreas.Gravity.Part", label = "Gravity Chamber (10K Speed)" },
	},

	Sword = {
		-- Add sword locations later when you find them
	},
}

-- ===== HELPERS =====
local function readNumberValue(inst: Instance): number?
	if inst and (inst:IsA("IntValue") or inst:IsA("NumberValue")) then
		return inst.Value
	end
	return nil
end

-- Reads from Players.LocalPlayer.Stats["1".."7"]
local function getStatValue(statName: string): number
	local id = STAT_ID[statName]
	if not id then return 0 end

	local statsFolder = player:FindFirstChild("Stats")
	if not statsFolder then return 0 end

	local valObj = statsFolder:FindFirstChild(tostring(id))
	local v = readNumberValue(valObj)
	return v or 0
end

local function getHRP()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function findAnyBasePart(root: Instance): BasePart?
	if not root then return nil end
	if root:IsA("BasePart") then return root end
	if root:IsA("Model") and root.PrimaryPart then return root.PrimaryPart end

	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("MeshPart") then return d end
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then return d end
	end
	return nil
end

local function resolveFromWorkspace(path: string): Instance?
	path = path:gsub("^Ugc%.", "")
	path = path:gsub("^Workspace%.", "")

	local cur: Instance = workspace
	for token in path:gmatch("[^%.]+") do
		local nxt = cur:FindFirstChild(token)
		if not nxt then return nil end
		cur = nxt
	end
	return cur
end

local function teleportToPath(path: string): boolean
	local hrp = getHRP()
	if not hrp then return false end

	local inst = resolveFromWorkspace(path)
	if not inst then return false end

	local part = findAnyBasePart(inst)
	if not part then return false end

	hrp.CFrame = part.CFrame + Vector3.new(0, Y_OFFSET, 0)
	return true
end

local function getBestSpot(statName: string)
	local list = SPOTS[statName]
	if not list or #list == 0 then return nil end

	local value = getStatValue(statName)
	local best = nil
	for _, s in ipairs(list) do
		if value >= s.req then
			if (not best) or (s.req > best.req) then
				best = s
			end
		end
	end
	return best
end

-- ===== Main loop =====
local enabled = {}
local teleportedOnce = {}
local lastChosenText = "None"

local function teleportOnceIfNeeded(statName: string)
	if teleportedOnce[statName] then return end

	local best = getBestSpot(statName)
	if not best then
		lastChosenText = statName .. ": No eligible spot"
		teleportedOnce[statName] = true
		return
	end

	local ok = teleportToPath(best.path)
	lastChosenText = statName .. ": " .. best.label .. (ok and "" or " (PATH NOT FOUND)")
	teleportedOnce[statName] = true
end

task.spawn(function()
	while true do
		for statName, on in pairs(enabled) do
			if on then
				-- Teleport only once per toggle ON
				teleportOnceIfNeeded(statName)

				-- Train continuously
				local id = STAT_ID[statName]
				if id then
					TrainRemote:FireServer("Train", id)
				end
			end
		end
		task.wait(TRAIN_DELAY)
	end
end)

-- ===== UI =====
local gui = Instance.new("ScreenGui")
gui.Name = "AutoTrainGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(360, 540)
frame.Position = UDim2.fromOffset(20, 120)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = gui

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 34)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BorderSizePixel = 0
topBar.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "ANIMEGPT"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 16
title.Parent = topBar

-- Dragging
do
	local dragging = false
	local dragStart, startPos
	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
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
end

local container = Instance.new("Frame")
container.Position = UDim2.fromOffset(10, 44)
container.Size = UDim2.new(1, -20, 1, -54)
container.BackgroundTransparency = 1
container.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = container

local function makeButton(text, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(340, 34)
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BorderSizePixel = 0
	btn.Parent = container
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.fromOffset(340, 150)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = Color3.new(1, 1, 1)
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.TextSize = 13
statsLabel.Text = "Loading stats..."
statsLabel.Parent = container

local chosenLabel = Instance.new("TextLabel")
chosenLabel.Size = UDim2.fromOffset(340, 42)
chosenLabel.BackgroundTransparency = 1
chosenLabel.TextColor3 = Color3.new(1, 1, 1)
chosenLabel.TextXAlignment = Enum.TextXAlignment.Left
chosenLabel.TextYAlignment = Enum.TextYAlignment.Top
chosenLabel.TextSize = 13
chosenLabel.Text = "Chosen: None"
chosenLabel.Parent = container

-- Credits bottom-right
local credits = Instance.new("TextLabel")
credits.AnchorPoint = Vector2.new(1, 1)
credits.Position = UDim2.new(1, -8, 1, -6)
credits.Size = UDim2.fromOffset(140, 18)
credits.BackgroundTransparency = 1
credits.Text = "@fent"
credits.TextColor3 = Color3.fromRGB(200, 200, 200)
credits.TextSize = 12
credits.TextXAlignment = Enum.TextXAlignment.Right
credits.TextYAlignment = Enum.TextYAlignment.Bottom
credits.Parent = frame

task.spawn(function()
	while statsLabel.Parent do
		statsLabel.Text =
			("Stats folder values:\nStrength(1): %d\nDurability(2): %d\nChakra(3): %d\nSword(4): %d\nAgility(5): %d\nSpeed(6): %d"):format(
				getStatValue("Strength"),
				getStatValue("Durability"),
				getStatValue("Chakra"),
				getStatValue("Sword"),
				getStatValue("Agility"),
				getStatValue("Speed")
			)
		chosenLabel.Text = "Chosen: " .. lastChosenText
		task.wait(0.4)
	end
end)

local function makeToggle(statName: string)
	enabled[statName] = false
	local btn
	btn = makeButton(statName .. ": OFF", function()
		enabled[statName] = not enabled[statName]
		btn.Text = statName .. ": " .. (enabled[statName] and "ON" or "OFF")

		if enabled[statName] then
			teleportedOnce[statName] = false
			teleportOnceIfNeeded(statName)
		else
			teleportedOnce[statName] = false
		end
	end)
end

makeToggle("Chakra")
makeToggle("Strength")
makeToggle("Durability")
makeToggle("Agility")
makeToggle("Speed")
makeToggle("Sword")

makeButton("STOP ALL", function()
	for k in pairs(enabled) do
		enabled[k] = false
		teleportedOnce[k] = false
	end
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextButton") and child.Text:find(":") then
			local name = child.Text:match("(.+):")
			if name then child.Text = name .. ": OFF" end
		end
	end
	lastChosenText = "None"
end)

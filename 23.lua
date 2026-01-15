-- Main Script
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local petStats = require(game:GetService("ReplicatedStorage").Game.PetStats)
local replication = require(game:GetService("ReplicatedStorage").Game.Replication)
local network = require(game:GetService("ReplicatedStorage").Modules.Network)

-- Create the GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetDeleterGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Create main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 200)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Create title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(1, 0, 1, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Pet Auto-Deleter v1.0"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.Parent = titleBar

-- Create close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Parent = titleBar

-- Create content frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -20, 1, -50)
contentFrame.Position = UDim2.new(0, 10, 0, 40)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- Create status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Stopped"
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = contentFrame

-- Create toggle button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, 0, 0, 40)
toggleButton.Position = UDim2.new(0, 0, 0, 40)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
toggleButton.Text = "START AUTO-DELETE"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 16
toggleButton.Parent = contentFrame

-- Create settings frame
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "Settings"
settingsFrame.Size = UDim2.new(1, 0, 0, 60)
settingsFrame.Position = UDim2.new(0, 0, 0, 90)
settingsFrame.BackgroundTransparency = 1
settingsFrame.Parent = contentFrame

-- Create percentage threshold setting
local percentageLabel = Instance.new("TextLabel")
percentageLabel.Name = "PercentageLabel"
percentageLabel.Size = UDim2.new(0.6, 0, 0, 20)
percentageLabel.BackgroundTransparency = 1
percentageLabel.Text = "Percentage Threshold:"
percentageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
percentageLabel.Font = Enum.Font.Gotham
percentageLabel.TextSize = 12
percentageLabel.TextXAlignment = Enum.TextXAlignment.Left
percentageLabel.Parent = settingsFrame

local percentageBox = Instance.new("TextBox")
percentageBox.Name = "PercentageBox"
percentageBox.Size = UDim2.new(0.4, 0, 0, 20)
percentageBox.Position = UDim2.new(0.6, 0, 0, 0)
percentageBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
percentageBox.Text = "50"
percentageBox.TextColor3 = Color3.fromRGB(255, 255, 255)
percentageBox.Font = Enum.Font.Gotham
percentageBox.TextSize = 12
percentageBox.Parent = settingsFrame

-- Create multiplier threshold setting
local multiplierLabel = Instance.new("TextLabel")
multiplierLabel.Name = "MultiplierLabel"
multiplierLabel.Size = UDim2.new(0.6, 0, 0, 20)
multiplierLabel.Position = UDim2.new(0, 0, 0, 25)
multiplierLabel.BackgroundTransparency = 1
multiplierLabel.Text = "Multiplier Threshold:"
multiplierLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
multiplierLabel.Font = Enum.Font.Gotham
multiplierLabel.TextSize = 12
multiplierLabel.TextXAlignment = Enum.TextXAlignment.Left
multiplierLabel.Parent = settingsFrame

local multiplierBox = Instance.new("TextBox")
multiplierBox.Name = "MultiplierBox"
multiplierBox.Size = UDim2.new(0.4, 0, 0, 20)
multiplierBox.Position = UDim2.new(0.6, 0, 0, 25)
multiplierBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
multiplierBox.Text = "100"
multiplierBox.TextColor3 = Color3.fromRGB(255, 255, 255)
multiplierBox.Font = Enum.Font.Gotham
multiplierBox.TextSize = 12
multiplierBox.Parent = settingsFrame

-- Create info label
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, 0, 0, 20)
infoLabel.Position = UDim2.new(0, 0, 0, 155)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Deletes low-value pets automatically"
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 11
infoLabel.Parent = contentFrame

-- Variables
local isDeleting = false
local deleteCoroutine = nil

-- Function to delete low-value pets
local function deleteLowValuePets()
	local threshold = tonumber(percentageBox.Text) or 50
	local multiplierThreshold = tonumber(multiplierBox.Text) or 100
	
	local petsToDelete = {}
	
	-- Identify low-value pets
	for petId, petData in pairs(replication.Data.Pets) do
		-- Skip equipped pets
		if not petData.Equipped then
			-- Get pet rarity percentage
			local success, percentage = pcall(function()
				return petStats:GetPercentage(petData.Name)
			end)
			
			-- Delete pets with low percentage or low multipliers
			if (success and percentage and percentage < threshold) or 
			   (petData.Multiplier1 and petData.Multiplier1 < multiplierThreshold) then
				table.insert(petsToDelete, petId)
			end
		end
		
		-- Check if we should stop
		if not isDeleting then
			break
		end
	end
	
	-- Delete identified pets
	for _, petId in ipairs(petsToDelete) do
		if not isDeleting then
			break
		end
		
		local success = pcall(function()
			network:InvokeServer("DeletePet", petId)
		end)
		
		if success then
			statusLabel.Text = string.format("Status: Deleting... (%d left)", #petsToDelete - _)
		else
			statusLabel.Text = "Status: Error occurred"
		end
		
		task.wait(0.1)  -- Small delay
	end
	
	if isDeleting then
		statusLabel.Text = "Status: Completed one cycle"
	end
end

-- Toggle function
local function toggleDeletion()
	if isDeleting then
		-- Stop deletion
		isDeleting = false
		if deleteCoroutine then
			coroutine.close(deleteCoroutine)
			deleteCoroutine = nil
		end
		toggleButton.Text = "START AUTO-DELETE"
		toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		statusLabel.Text = "Status: Stopped"
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	else
		-- Start deletion
		isDeleting = true
		toggleButton.Text = "STOP AUTO-DELETE"
		toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		statusLabel.Text = "Status: Running..."
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		
		-- Start deletion in a coroutine
		deleteCoroutine = coroutine.create(function()
			while isDeleting do
				deleteLowValuePets()
				task.wait(5)  -- Wait 5 seconds between cycles
			end
		end)
		coroutine.resume(deleteCoroutine)
	end
end

-- Connect button events
toggleButton.MouseButton1Click:Connect(toggleDeletion)
closeButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
	if deleteCoroutine and isDeleting then
		isDeleting = false
		coroutine.close(deleteCoroutine)
	end
end)

-- Round corners function
local function roundCorners(object)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = object
end

-- Apply rounded corners
roundCorners(mainFrame)
roundCorners(toggleButton)
roundCorners(percentageBox)
roundCorners(multiplierBox)
roundCorners(closeButton)

-- Add some padding
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 5)
padding.PaddingBottom = UDim.new(0, 5)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = contentFrame

-- Make percentage and multiplier boxes only accept numbers
percentageBox.FocusLost:Connect(function()
	local num = tonumber(percentageBox.Text)
	if not num or num < 0 or num > 100 then
		percentageBox.Text = "50"
	end
end)

multiplierBox.FocusLost:Connect(function()
	local num = tonumber(multiplierBox.Text)
	if not num or num < 0 then
		multiplierBox.Text = "100"
	end
end)

-- Make the GUI visible
screenGui.Enabled = true

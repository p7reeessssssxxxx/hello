--// ============================================================
--// NO.FEAR LOADER v2.1 (SIMPLIFIED - SINGLE KEY VERSION)
--// ============================================================
--// Discord:    https://discord.gg/G9QSXsB9wY
--// ============================================================

--// ============================================================
--// CONFIG — Overrideable by calling script via getfenv()
--// ============================================================
local _env = (getfenv and getfenv(0)) or {}
local ScriptURL  = _env.ScriptURL  or ""
local ScriptName = _env.ScriptName or "NoFear"

--// ============================================================
--// SIMPLE KEY SYSTEM - CHANGE THIS TO YOUR KEY
--// ============================================================
local CORRECT_KEY = "nofear2024"  -- <<< CHANGE THIS TO YOUR DESIRED KEY
local KEY_SAVE_FILE = "nofear_key.txt"

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local LP          = Players.LocalPlayer

-- Multi-executor request support
local request = syn and syn.request or http_request or request or (http and http.request)

-- Simple file operations
local function readSavedKey()
    local ok, data = pcall(readfile, KEY_SAVE_FILE)
    if ok and data and #data > 0 then
        return data:match("^%s*(.-)%s*$")
    end
    return nil
end

local function saveKey(key)
    pcall(writefile, KEY_SAVE_FILE, key)
end

local function clearSavedKey()
    pcall(writefile, KEY_SAVE_FILE, "")
end

-- Simple key validation - just checks if it matches our single key
local function validateKey(key)
    if not key or #key < 1 then 
        return false, "Please enter a key" 
    end
    
    -- Simple comparison (case insensitive)
    if string.lower(key) == string.lower(CORRECT_KEY) then
        return true, "Key accepted!"
    else
        return false, "Invalid key"
    end
end

local function destroyExisting()
    local cg = game:GetService("CoreGui")
    pcall(function() local e = cg:FindFirstChild("NoFearKeySystem"); if e then e:Destroy() end end)
    pcall(function() local h = gethui():FindFirstChild("NoFearKeySystem"); if h then h:Destroy() end end)
end

local function createKeyUI(onSuccess)
    destroyExisting()

    local CoreGui = game:GetService("CoreGui")
    local UIS = game:GetService("UserInputService")

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NoFearKeySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    pcall(function() ScreenGui.Parent = gethui() end)
    if not ScreenGui.Parent then ScreenGui.Parent = CoreGui end

    -- MAIN WINDOW 640x340
    local W = Instance.new("Frame", ScreenGui)
    W.Size = UDim2.new(0,640,0,340)
    W.Position = UDim2.new(0.5,-320,0.5,-170)
    W.BackgroundColor3 = Color3.fromRGB(30,30,30)
    W.BorderSizePixel = 1
    W.BorderColor3 = Color3.fromRGB(50,50,50)
    W.ZIndex = 11
    W.Active = true
    W.Draggable = true

    -- ── TOP BAR ──────────────────────────────────────────────────
    local TopBar = Instance.new("Frame", W)
    TopBar.Size = UDim2.new(1,0,0,32)
    TopBar.BackgroundColor3 = Color3.fromRGB(26,26,26)
    TopBar.BorderSizePixel = 0
    TopBar.ZIndex = 12

    local LogoCircle = Instance.new("Frame", TopBar)
    LogoCircle.Size = UDim2.new(0,20,0,20)
    LogoCircle.Position = UDim2.new(0,10,0.5,-10)
    LogoCircle.BackgroundColor3 = Color3.fromRGB(130,0,220)
    LogoCircle.BorderSizePixel = 0
    LogoCircle.ZIndex = 13
    Instance.new("UICorner", LogoCircle).CornerRadius = UDim.new(1,0)

    local LogoN = Instance.new("TextLabel", LogoCircle)
    LogoN.Size = UDim2.new(1,0,1,0)
    LogoN.BackgroundTransparency = 1
    LogoN.Text = "N"
    LogoN.TextColor3 = Color3.fromRGB(255,255,255)
    LogoN.TextSize = 12
    LogoN.Font = Enum.Font.GothamBlack
    LogoN.ZIndex = 14

    local TitleTxt = Instance.new("TextLabel", TopBar)
    TitleTxt.Size = UDim2.new(0,200,1,0)
    TitleTxt.Position = UDim2.new(0,36,0,0)
    TitleTxt.BackgroundTransparency = 1
    TitleTxt.Text = "NoFear"
    TitleTxt.TextColor3 = Color3.fromRGB(215,215,215)
    TitleTxt.TextSize = 14
    TitleTxt.Font = Enum.Font.GothamBold
    TitleTxt.TextXAlignment = Enum.TextXAlignment.Left
    TitleTxt.ZIndex = 13

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.Size = UDim2.new(0,32,1,0)
    CloseBtn.Position = UDim2.new(1,-32,0,0)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(110,110,110)
    CloseBtn.TextSize = 16
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.ZIndex = 13
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    -- ── CENTER PANEL (SIMPLIFIED) ────────────────────────────────
    local Center = Instance.new("Frame", W)
    Center.Size = UDim2.new(1,0,0,284)
    Center.Position = UDim2.new(0,0,0,32)
    Center.BackgroundColor3 = Color3.fromRGB(34,34,34)
    Center.BorderSizePixel = 0
    Center.ZIndex = 12

    local KeyTitle = Instance.new("TextLabel", Center)
    KeyTitle.Size = UDim2.new(1,-40,0,28)
    KeyTitle.Position = UDim2.new(0,20,0,30)
    KeyTitle.BackgroundTransparency = 1
    KeyTitle.Text = "Enter Access Key"
    KeyTitle.TextColor3 = Color3.fromRGB(210,210,210)
    KeyTitle.TextSize = 18
    KeyTitle.Font = Enum.Font.GothamBold
    KeyTitle.TextXAlignment = Enum.TextXAlignment.Center
    KeyTitle.ZIndex = 13

    local InputBox = Instance.new("TextBox", Center)
    InputBox.Size = UDim2.new(0,400,0,40)
    InputBox.Position = UDim2.new(0.5,-200,0,80)
    InputBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
    InputBox.BorderSizePixel = 1
    InputBox.BorderColor3 = Color3.fromRGB(55,55,55)
    InputBox.Text = ""
    InputBox.PlaceholderText = "Enter key here..."
    InputBox.TextColor3 = Color3.fromRGB(205,205,205)
    InputBox.PlaceholderColor3 = Color3.fromRGB(85,85,85)
    InputBox.TextSize = 14
    InputBox.Font = Enum.Font.Code
    InputBox.ClearTextOnFocus = false
    InputBox.TextXAlignment = Enum.TextXAlignment.Center
    InputBox.ZIndex = 13
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0,4)

    local StatusLabel = Instance.new("TextLabel", Center)
    StatusLabel.Size = UDim2.new(1,-40,0,20)
    StatusLabel.Position = UDim2.new(0,20,0,130)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(220,70,70)
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.Code
    StatusLabel.ZIndex = 13

    local EnterBtn = Instance.new("TextButton", Center)
    EnterBtn.Size = UDim2.new(0,200,0,40)
    EnterBtn.Position = UDim2.new(0.5,-100,0,160)
    EnterBtn.BackgroundColor3 = Color3.fromRGB(130,0,220)
    EnterBtn.BorderSizePixel = 0
    EnterBtn.Text = "Submit Key"
    EnterBtn.TextColor3 = Color3.fromRGB(255,255,255)
    EnterBtn.TextSize = 16
    EnterBtn.Font = Enum.Font.GothamBold
    EnterBtn.ZIndex = 13
    Instance.new("UICorner", EnterBtn).CornerRadius = UDim.new(0,4)

    -- Information text
    local InfoText = Instance.new("TextLabel", Center)
    InfoText.Size = UDim2.new(1,-40,0,40)
    InfoText.Position = UDim2.new(0,20,0,220)
    InfoText.BackgroundTransparency = 1
    InfoText.Text = "Default key: nofear2024\nDiscord: discord.gg/G9QSXsB9wY"
    InfoText.TextColor3 = Color3.fromRGB(155,155,155)
    InfoText.TextSize = 11
    InfoText.Font = Enum.Font.Code
    InfoText.ZIndex = 13

    -- ── BUTTON LOGIC ──────────────────────────────────────────────
    local busy = false

    EnterBtn.MouseButton1Click:Connect(function()
        if busy then return end
        busy = true
        
        local key = InputBox.Text:match("^%s*(.-)%s*$")
        if #key < 1 then
            StatusLabel.TextColor3 = Color3.fromRGB(220,70,70)
            StatusLabel.Text = "Please enter a key"
            busy = false
            return
        end
        
        EnterBtn.Text = "Checking..."
        StatusLabel.Text = ""

        local valid, msg = validateKey(key)

        if valid then
            saveKey(key)
            StatusLabel.TextColor3 = Color3.fromRGB(80,200,120)
            StatusLabel.Text = "Key accepted! Loading..."
            EnterBtn.Text = "Loading..."
            task.wait(1)
            ScreenGui:Destroy()
            onSuccess()
        else
            StatusLabel.TextColor3 = Color3.fromRGB(220,70,70)
            StatusLabel.Text = msg or "Invalid key"
            EnterBtn.Text = "Submit Key"
            busy = false
        end
    end)

    -- Allow Enter key to submit
    InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            EnterBtn.MouseButton1Click:Fire()
        end
    end)
end

local function runWithKeyCheck(callback)
    -- Try cached key first
    local cached = readSavedKey()
    if cached and #cached > 0 then
        local valid, msg = validateKey(cached)
        if valid then
            print("[NoFear] Key valid from cache")
            callback()
            return
        else
            print("[NoFear] Cached key invalid")
            clearSavedKey()
        end
    end

    -- Show key UI
    print("[NoFear] Key required - showing key UI")
    createKeyUI(function()
        print("[NoFear] Key accepted - loading " .. ScriptName)
        callback()
    end)
end

-- Final execution
if ScriptURL and #ScriptURL > 10 then
    -- Run with key check then load the script
    runWithKeyCheck(function()
        local ok, src = pcall(game.HttpGet, game, ScriptURL)
        if ok and src then
            loadstring(src)()
        else
            warn("[NoFear] Failed to load script from GitHub. Check ScriptURL.")
        end
    end)
else
    -- Module mode
    return runWithKeyCheck
end

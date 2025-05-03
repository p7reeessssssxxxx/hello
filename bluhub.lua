local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "BluHub",
    Icon = 0, 
    LoadingTitle = "bluhub loader",
    LoadingSubtitle = "by @n.exc",
    Theme = "Default", 
 
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface
 
    ConfigurationSaving = {
       Enabled = true,
       FolderName = BluHub, -- Create a custom folder for your hub/game
       FileName = "BluHub"
    },
 
    Discord = {
       Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
       Invite = "https://discord.gg/pcabxYSBSJ", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
       RememberJoins = true -- Set this to false to make them join the discord every time they load it up
    },
 
    KeySystem = true,
    KeySettings = {
       Title = "Bluhub key",
       Subtitle = "Key System",
       Note = "Join the discord for the key https://discord.gg/pcabxYSBSJ", -- Use this to tell the user how to get a key
       FileName = "BluHub", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
       SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
       GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
       Key = {"bluhubbest!"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
    }
 })

 local Tab = Window:CreateTab("BluHud loader", 4483362458) -- Title, Image

 local Section = Tab:CreateSection("tap to load script")
 Section:Set("Section Example")
 
 local Button = Tab:CreateButton({
    Name = "Tap to load script",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/p7reeessssssxxxx/hello/refs/heads/main/12.lua"))() 
    end,
 })
 
 Rayfield:Notify({
    Title = "Join the discord for the key",
    Content = "https://discord.gg/pcabxYSBSJ",
    Duration = 10.5,
    Image = 4483362458,
 })

 Rayfield:LoadConfiguration()

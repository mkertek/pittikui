local PittikUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/mkertek/pittikui/refs/heads/main/source.lua"))()

local Window = PittikUI:CreateWindow({
    Title = "My Script Hub",
    Size = UDim2.new(0, 600, 0, 440),
    MinSize = { X = 420, Y = 300 },
    MaxSize = { X = 900, Y = 700 },
    ConfigFolder = "MyHubConfigs",
})

local MainTab = Window:AddTab({ Name = "Main" })

local CombatSection = MainTab:AddSection({ Name = "Combat" })

CombatSection:AddToggle({
    Name = "Kill Aura",
    Default = false,
    Flag = "KillAura",
    Callback = function(state)
        print("Kill Aura:", state)
    end,
})

CombatSection:AddSlider({
    Name = "Attack Range",
    Min = 5,
    Max = 50,
    Default = 15,
    Increment = 1,
    Suffix = " studs",
    Flag = "AttackRange",
    Callback = function(value)
        print("Attack Range:", value)
    end,
})

CombatSection:AddButton({
    Name = "Kill All Nearby",
    Callback = function()
        PittikUI:Notify({
            Title = "Combat",
            Content = "Kill All executed!",
            Duration = 3,
        })
    end,
})

local MovementSection = MainTab:AddSection({ Name = "Movement" })

MovementSection:AddToggle({
    Name = "Speed Hack",
    Default = false,
    Flag = "SpeedHack",
    Callback = function(state)
        local player = game.Players.LocalPlayer
        if player and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = state and 100 or 16
            end
        end
    end,
})

MovementSection:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 500,
    Default = 16,
    Increment = 5,
    Flag = "WalkSpeed",
    Callback = function(value)
        local player = game.Players.LocalPlayer
        if player and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = value end
        end
    end,
})

MovementSection:AddToggle({
    Name = "Infinite Jump",
    Default = false,
    Flag = "InfJump",
    Callback = function(state)
        print("Infinite Jump:", state)
    end,
})

local VisualsTab = Window:AddTab({ Name = "Visuals" })

local ESPSection = VisualsTab:AddSection({ Name = "ESP" })

ESPSection:AddToggle({
    Name = "Player ESP",
    Default = false,
    Flag = "PlayerESP",
    Callback = function(state) print("Player ESP:", state) end,
}):AddColorPicker({
    Default = Color3.fromRGB(0, 255, 128),
    Flag = "PlayerESPColor",
    Callback = function(color) print("Player ESP Color:", color) end,
})

ESPSection:AddToggle({
    Name = "Box ESP",
    Default = false,
    Flag = "BoxESP",
    Callback = function(state) print("Box ESP:", state) end,
}):AddColorPicker({
    Default = Color3.fromRGB(0, 200, 255),
    Flag = "BoxESPColor",
    Callback = function(color) print("Box ESP Color:", color) end,
})

ESPSection:AddDropdown({
    Name = "ESP Mode",
    Items = {"2D Box", "Corner Box", "3D Box"},
    Default = "2D Box",
    Flag = "ESPMode",
    Callback = function(selected) print("ESP Mode:", selected) end,
})

local WorldSection = VisualsTab:AddSection({ Name = "World" })

WorldSection:AddToggle({
    Name = "Fullbright",
    Default = false,
    Flag = "Fullbright",
    Callback = function(state)
        local lighting = game:GetService("Lighting")
        if state then
            lighting.Brightness = 3
            lighting.GlobalShadows = false
        else
            lighting.Brightness = 1
            lighting.GlobalShadows = true
        end
    end,
})

WorldSection:AddSlider({
    Name = "FOV",
    Min = 30,
    Max = 120,
    Default = 70,
    Increment = 5,
    Suffix = "°",
    Flag = "FOV",
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = value
    end,
})

PittikUI:Notify({
    Title = "My Script Hub",
    Content = "Loaded! Press RightCtrl to toggle.",
    Duration = 5,
})

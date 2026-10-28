local PittikUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/mkertek/pittikui/main/source.lua"))()

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
})

ESPSection:AddToggle({
    Name = "Box ESP",
    Default = false,
    Flag = "BoxESP",
    Callback = function(state) print("Box ESP:", state) end,
})

ESPSection:AddDropdown({
    Name = "ESP Color",
    Items = {"Neon Green", "Cyan", "Red", "White", "Team Color"},
    Default = "Neon Green",
    Flag = "ESPColor",
    Callback = function(selected) print("ESP Color:", selected) end,
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

local SettingsTab = Window:AddTab({ Name = "Settings" })

local ConfigSection = SettingsTab:AddSection({ Name = "Configuration" })

local configNameBox = ConfigSection:AddTextBox({
    Name = "Config Name",
    Placeholder = "Enter config name...",
})

ConfigSection:AddButton({
    Name = "Save Config",
    Callback = function()
        local name = configNameBox:GetText()
        if name == "" then
            PittikUI:Notify({ Title = "Config", Content = "Please enter a config name!", Duration = 3 })
            return
        end
        local ok = Window:SaveConfig(name)
        PittikUI:Notify({
            Title = "Config",
            Content = ok and ('"' .. name .. '" saved!') or "Save failed!",
            Duration = 3,
        })
        if cfgDropdown and cfgDropdown.Refresh then
            local list = Window.Config:List()
            cfgDropdown:Refresh(#list > 0 and list or {"(empty)"})
        end
    end,
})

local savedList = Window.Config:List()
cfgDropdown = ConfigSection:AddDropdown({
    Name = "Saved Configs",
    Items = #savedList > 0 and savedList or {"(empty)"},
    Default = savedList[1] or "(empty)",
})

ConfigSection:AddButton({
    Name = "Load Selected Config",
    Callback = function()
        local sel = cfgDropdown.Value
        if sel == "(empty)" or sel == "" then
            PittikUI:Notify({ Title = "Config", Content = "No config selected!", Duration = 3 })
            return
        end
        Window:LoadConfig(sel)
        PittikUI:Notify({ Title = "Config", Content = '"' .. sel .. '" loaded!', Duration = 3 })
    end,
})

ConfigSection:AddButton({
    Name = "Delete Selected Config",
    Callback = function()
        local sel = cfgDropdown.Value
        if sel == "(empty)" or sel == "" then
            PittikUI:Notify({ Title = "Config", Content = "No config selected!", Duration = 3 })
            return
        end
        Window.Config:Delete(sel)
        PittikUI:Notify({ Title = "Config", Content = '"' .. sel .. '" deleted!', Duration = 3 })
        local list = Window.Config:List()
        cfgDropdown:Refresh(#list > 0 and list or {"(empty)"})
    end,
})

local UISection = SettingsTab:AddSection({ Name = "UI Customization" })

UISection:AddColorPicker({
    Name = "Accent Color",
    Default = Color3.fromRGB(0, 255, 128),
    Callback = function(color, hex)
        PittikUI:SetAccentColor(color)
        PittikUI:Notify({ Title = "Theme", Content = "Accent → " .. hex, Duration = 2 })
    end,
})

local KeybindSection = SettingsTab:AddSection({ Name = "Keybinds" })

KeybindSection:AddKeybind({
    Name = "Toggle GUI Key",
    Default = Enum.KeyCode.RightControl,
    Callback = function(key)
        PittikUI.ToggleKey = key
        PittikUI:Notify({ Title = "Keybind", Content = "Toggle key → " .. key.Name, Duration = 3 })
    end,
})

local InfoSection = SettingsTab:AddSection({ Name = "Info" })
InfoSection:AddLabel({ Name = "Drag bottom-right corner to resize." })
InfoSection:AddLabel({ Name = "Press toggle key to show/hide." })
InfoSection:AddButton({ Name = "Destroy GUI", Callback = function() Window:Close() end })

PittikUI:Notify({
    Title = "My Script Hub",
    Content = "Loaded! Press RightCtrl to toggle.",
    Duration = 5,
})

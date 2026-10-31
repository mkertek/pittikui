
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local PittikUI = {
    Version = "1.0",
    Windows = {},
    Theme = {
        Background       = Color3.fromRGB(12, 16, 22),
        Surface          = Color3.fromRGB(18, 22, 30),
        SurfaceAlt       = Color3.fromRGB(24, 28, 38),
        Card             = Color3.fromRGB(16, 20, 28),
        CardHover        = Color3.fromRGB(22, 28, 38),
        Border           = Color3.fromRGB(30, 36, 48),
        Accent           = Color3.fromRGB(0, 255, 128),
        AccentDim        = Color3.fromRGB(0, 180, 90),
        AccentGlow       = Color3.fromRGB(0, 255, 128),
        Text             = Color3.fromRGB(220, 225, 230),
        TextDim          = Color3.fromRGB(140, 150, 165),
        TextAccent       = Color3.fromRGB(0, 255, 128),
        Danger           = Color3.fromRGB(255, 60, 60),
        ToggleOn         = Color3.fromRGB(0, 255, 128),
        ToggleOff        = Color3.fromRGB(50, 55, 65),
        SliderFill       = Color3.fromRGB(0, 255, 128),
        SliderTrack      = Color3.fromRGB(35, 40, 50),
        DropdownBg       = Color3.fromRGB(14, 18, 26),
    },
    Flags = {},
    ConfigFolder = "PittikUIConfigs",
    ToggleKey = Enum.KeyCode.RightControl,
    _accentTexts = {},
    _accentDimTexts = {},
    _accentBgs = {},
    _accentStrokes = {},
    _accentScrollBars = {},
    _toggles = {},
    _accentImages = {},
    _listeningForKeybind = false,
    Transparency = 0,
}

local T = PittikUI.Theme
local FONT_MAIN = Enum.Font.GothamBold
local FONT_BODY = Enum.Font.GothamMedium
local FONT_SMALL = Enum.Font.Gotham
local CORNER_RADIUS = UDim.new(0, 0)

function PittikUI:_TrackText(label)
    table.insert(self._accentTexts, label)
end

function PittikUI:_TrackAccentDimText(label)
    table.insert(self._accentDimTexts, label)
end

function PittikUI:_TrackBg(frame)
    table.insert(self._accentBgs, frame)
end

function PittikUI:_TrackStroke(stroke)
    table.insert(self._accentStrokes, stroke)
end

function PittikUI:_TrackScrollBar(scrollFrame)
    table.insert(self._accentScrollBars, scrollFrame)
end

function PittikUI:_TrackImage(img)
    table.insert(self._accentImages, img)
end

function PittikUI:SetTransparency(val)
    if typeof(val) ~= "number" then return end
    if val > 1 then val = val / 100 end
    val = math.clamp(val, 0, 0.95)
    self.Transparency = val

    for _, win in ipairs(self.Windows) do
        win:SetTransparency(val)
    end
end

function PittikUI:SetAccentColor(color)
    T.Accent = color
    T.AccentDim = Color3.new(color.R * 0.7, color.G * 0.7, color.B * 0.7)
    T.AccentGlow = color
    T.TextAccent = color
    T.ToggleOn = color
    T.SliderFill = color

    for i = #self._accentTexts, 1, -1 do
        local lbl = self._accentTexts[i]
        if lbl and lbl.Parent then
            pcall(function() lbl.TextColor3 = color end)
        else
            table.remove(self._accentTexts, i)
        end
    end
    for i = #self._accentDimTexts, 1, -1 do
        local lbl = self._accentDimTexts[i]
        if lbl and lbl.Parent then
            pcall(function() lbl.TextColor3 = T.AccentDim end)
        else
            table.remove(self._accentDimTexts, i)
        end
    end
    for i = #self._accentBgs, 1, -1 do
        local bg = self._accentBgs[i]
        if bg and bg.Parent then
            pcall(function() bg.BackgroundColor3 = color end)
        else
            table.remove(self._accentBgs, i)
        end
    end
    for i = #self._accentStrokes, 1, -1 do
        local s = self._accentStrokes[i]
        if s and s.Parent then
            pcall(function() s.Color = color end)
        else
            table.remove(self._accentStrokes, i)
        end
    end
    for i = #self._accentScrollBars, 1, -1 do
        local sf = self._accentScrollBars[i]
        if sf and sf.Parent then
            pcall(function() sf.ScrollBarImageColor3 = color end)
        else
            table.remove(self._accentScrollBars, i)
        end
    end
    for i = #self._accentImages, 1, -1 do
        local img = self._accentImages[i]
        if img and img.Parent then
            pcall(function() img.ImageColor3 = color end)
        else
            table.remove(self._accentImages, i)
        end
    end
    for i = #self._toggles, 1, -1 do
        local item = self._toggles[i]
        if item and item.Bg and item.Bg.Parent then
            if item.GetState() then
                pcall(function() item.Bg.BackgroundColor3 = color end)
            end
        else
            table.remove(self._toggles, i)
        end
    end

    for _, win in ipairs(self.Windows) do
        if win.ActiveTab then
            pcall(function()
                win.ActiveTab.Label.TextColor3 = color
                win.ActiveTab.Indicator.BackgroundColor3 = color
            end)
        end
    end
end

local Util = {}

function Util.Create(className, props, children)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

function Util.Corner(parent, radius)
    return Util.Create("UICorner", { CornerRadius = radius or CORNER_RADIUS, Parent = parent })
end

function Util.Stroke(parent, color, thickness, transparency)
    local s = Util.Create("UIStroke", {
        Color = color or T.Accent,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
    if color == T.Accent or color == T.AccentGlow then
        PittikUI:_TrackStroke(s)
    end
    return s
end

function Util.Padding(parent, top, right, bottom, left)
    return Util.Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 8),
        PaddingRight = UDim.new(0, right or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft = UDim.new(0, left or 8),
        Parent = parent,
    })
end

function Util.ListLayout(parent, padding, direction, hAlign, vAlign, sortOrder)
    return Util.Create("UIListLayout", {
        Padding = UDim.new(0, padding or 6),
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

function Util.Tween(inst, duration, props, style, direction)
    local tween = TweenService:Create(inst, TweenInfo.new(
        duration or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out
    ), props)
    tween:Play()
    return tween
end

function Util.Ripple(button, color)
    local glow = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = color or T.AccentGlow,
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Parent = button,
    })
    Util.Corner(glow)
    Util.Tween(glow, 0.3, { BackgroundTransparency = 1 })
    task.delay(0.35, function() glow:Destroy() end)
end

function Util.MakeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Util.AutoResize(scrollFrame, listLayout)
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 16)
    end)
end

local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new(folder)
    local self = setmetatable({}, ConfigManager)
    self.Folder = folder or PittikUI.ConfigFolder
    self:_EnsureFolder()
    return self
end

function ConfigManager:_EnsureFolder()
    pcall(function()
        if isfolder and not isfolder(self.Folder) then
            if makefolder then makefolder(self.Folder) end
        end
    end)
end

function ConfigManager:Save(name, data)
    local path = self.Folder .. "/" .. name .. ".json"
    local success, err = pcall(function()
        if writefile then writefile(path, HttpService:JSONEncode(data)) end
    end)
    if not success then warn("[PittikUI] Save failed: " .. tostring(err)) end
    return success
end

function ConfigManager:Load(name)
    local path = self.Folder .. "/" .. name .. ".json"
    local success, result = pcall(function()
        if isfile and isfile(path) then
            return HttpService:JSONDecode(readfile(path))
        end
        return nil
    end)
    return success and result or nil
end

function ConfigManager:Delete(name)
    pcall(function()
        local path = self.Folder .. "/" .. name .. ".json"
        if isfile and isfile(path) and delfile then delfile(path) end
    end)
end

function ConfigManager:List()
    local files = {}
    pcall(function()
        if listfiles then
            for _, file in ipairs(listfiles(self.Folder)) do
                if string.sub(file, -5) == ".json" then
                    local n = string.match(file, "([^/\\]+)%.json$")
                    if n then table.insert(files, n) end
                end
            end
        end
    end)
    return files
end

function ConfigManager:SaveFlags(name, flags)
    local data = {}
    for flag, info in pairs(flags) do
        if info.Value ~= nil then data[flag] = info.Value end
    end
    return self:Save(name, data)
end

function ConfigManager:LoadFlags(name, flags)
    local data = self:Load(name)
    if data then
        for flag, value in pairs(data) do
            if flags[flag] and flags[flag].Set then flags[flag]:Set(value) end
        end
        return true
    end
    return false
end

local NotifContainer, NotifGui

local function EnsureNotifContainer()
    if NotifContainer then return end

    NotifGui = Util.Create("ScreenGui", {
        Name = "PittikUINotifs",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(NotifGui)
            NotifGui.Parent = CoreGui
        elseif gethui then
            NotifGui.Parent = gethui()
        else
            NotifGui.Parent = CoreGui
        end
    end)
    if not NotifGui.Parent then
        NotifGui.Parent = Player:WaitForChild("PlayerGui")
    end

    NotifContainer = Util.Create("Frame", {
        Name = "NotifContainer",
        Size = UDim2.new(0, 280, 1, 0),
        Position = UDim2.new(1, -290, 0, 10),
        BackgroundTransparency = 1,
        Parent = NotifGui,
    })
    Util.ListLayout(NotifContainer, 6, Enum.FillDirection.Vertical,
        Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
end

function PittikUI:Notify(options)
    EnsureNotifContainer()
    if not NotifContainer then return end
    local title = options.Title or "PittikUI"
    local content = options.Content or ""
    local duration = options.Duration or 4

    local notif = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = T.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = NotifContainer,
    })
    Util.Corner(notif)
    Util.Stroke(notif, T.Accent, 1, 0.3)

    local bar = Util.Create("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Parent = notif,
    })
    PittikUI:_TrackBg(bar)

    Util.Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 14, 0, 10),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = T.TextAccent,
        TextSize = 13,
        Font = FONT_MAIN,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    Util.Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 14, 0, 32),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = T.TextDim,
        TextSize = 12,
        Font = FONT_BODY,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = notif,
    })

    local pBg = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = T.Border,
        BorderSizePixel = 0,
        Parent = notif,
    })
    local pFill = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Parent = pBg,
    })
    PittikUI:_TrackBg(pFill)

    notif.Position = UDim2.new(1, 0, 0, 0)
    Util.Tween(notif, 0.3, { Position = UDim2.new(0, 0, 0, 0) })
    Util.Tween(pFill, duration, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)
    task.delay(duration, function()
        Util.Tween(notif, 0.3, { Position = UDim2.new(1, 0, 0, 0) })
        task.wait(0.35)
        notif:Destroy()
    end)
end

local Window = {}
Window.__index = Window

local DEFAULT_LOGO_B64 = "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"

local function Base64Decode(data)
    if typeof(crypt) == "table" and crypt.base64decode then
        local ok, res = pcall(crypt.base64decode, data)
        if ok and res then return res end
    end
    if typeof(syn) == "table" and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode then
        local ok, res = pcall(syn.crypt.base64.decode, data)
        if ok and res then return res end
    end
    if typeof(base64_decode) == "function" then
        local ok, res = pcall(base64_decode, data)
        if ok and res then return res end
    end

    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local t = {}
    for i = 1, 64 do t[b:sub(i, i)] = i - 1 end
    t['='] = 0

    local buffer = {}
    local len = #data
    local padding = 0
    if data:sub(-1) == '=' then padding = padding + 1 end
    if data:sub(-2, -2) == '=' then padding = padding + 1 end

    for i = 1, len, 4 do
        local c1 = t[data:sub(i, i)] or 0
        local c2 = t[data:sub(i+1, i+1)] or 0
        local c3 = t[data:sub(i+2, i+2)] or 0
        local c4 = t[data:sub(i+3, i+3)] or 0

        local n = bit32.bor(bit32.lshift(c1, 18), bit32.lshift(c2, 12), bit32.lshift(c3, 6), c4)

        table.insert(buffer, string.char(bit32.band(bit32.rshift(n, 16), 255)))
        if i + 2 <= len - padding then
            table.insert(buffer, string.char(bit32.band(bit32.rshift(n, 8), 255)))
        end
        if i + 3 <= len - padding then
            table.insert(buffer, string.char(bit32.band(n, 255)))
        end
    end
    return table.concat(buffer)
end

function PittikUI:ResolveAsset(icon)
    if icon == false then return nil end
    local getAsset = getcustomasset or getsynasset

    if not icon or icon == "" or icon == "default" then
        if getAsset and writefile then
            local filename = "pittik_logo_v1.png"
            local hasFile = false
            if isfile then
                local s, r = pcall(isfile, filename)
                hasFile = s and r
            end
            if not hasFile then
                local raw = Base64Decode(DEFAULT_LOGO_B64)
                if raw and #raw > 0 then
                    pcall(writefile, filename, raw)
                end
            end
            local ok, asset = pcall(getAsset, filename)
            if ok and asset then return asset end

            local gOk, body = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/mkertek/pittikui/refs/heads/main/logo_white_transparent.png")
            if gOk and body and #body > 0 then
                pcall(writefile, filename, body)
                local aOk, asset2 = pcall(getAsset, filename)
                if aOk and asset2 then return asset2 end
            end
        end
        return nil
    end

    if typeof(icon) == "number" or (typeof(icon) == "string" and tonumber(icon)) then
        return "rbxassetid://" .. tostring(icon)
    end
    local s = tostring(icon)
    if string.find(s, "^rbxassetid://") or string.find(s, "^roblox://") or string.find(s, "^http://www.roblox.com/") then
        return s
    end
    if string.find(s, "^http://") or string.find(s, "^https://") then
        if getAsset and writefile and isfile then
            local hash = "pittik_custom_asset.png"
            if not isfile(hash) then
                local ok, body = pcall(game.HttpGet, game, s)
                if ok and body and #body > 0 then
                    pcall(writefile, hash, body)
                end
            end
            if isfile(hash) then
                local ok, asset = pcall(getAsset, hash)
                if ok and asset then return asset end
            end
        end
    end
    if getAsset and isfile and isfile(s) then
        local ok, asset = pcall(getAsset, s)
        if ok and asset then return asset end
    end
    return s
end

function PittikUI:CreateWindow(options)
    options = options or {}
    local title = options.Title or ""
    local size = options.Size or UDim2.new(0, 600, 0, 440)
    local minSize = options.MinSize or { X = 420, Y = 300 }
    local maxSize = options.MaxSize or { X = 900, Y = 700 }

    if options.ConfigFolder then
        self.ConfigFolder = options.ConfigFolder
    end

    local existing = CoreGui:FindFirstChild("PittikUIMain")
    if existing then existing:Destroy() end

    local screenGui = Util.Create("ScreenGui", {
        Name = "PittikUIMain",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(screenGui)
            screenGui.Parent = CoreGui
        elseif gethui then
            screenGui.Parent = gethui()
        else
            screenGui.Parent = CoreGui
        end
    end)
    if not screenGui.Parent then
        screenGui.Parent = Player:WaitForChild("PlayerGui")
    end

    EnsureNotifContainer()

    local isCanvasGroupSupported = pcall(function()
        local test = Instance.new("CanvasGroup")
        test:Destroy()
    end)
    local frameClass = isCanvasGroupSupported and "CanvasGroup" or "Frame"

    local mainFrameProps = {
        Name = "MainFrame",
        Size = size,
        Position = UDim2.new(0.5, -(size.X.Offset / 2), 0.5, -(size.Y.Offset / 2)),
        BackgroundColor3 = T.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screenGui,
    }
    if isCanvasGroupSupported then
        mainFrameProps.GroupTransparency = self.Transparency
    end

    local mainFrame = Util.Create(frameClass, mainFrameProps)
    Util.Corner(mainFrame)
    Util.Stroke(mainFrame, T.Accent, 1.5, 0.2)

    local titleBar = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = T.Surface,
        BackgroundTransparency = self.Transparency,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    Util.Corner(titleBar)
    local titleBarFill = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, -6),
        BackgroundColor3 = T.Surface,
        BackgroundTransparency = self.Transparency,
        BorderSizePixel = 0,
        Parent = titleBar,
    })
    local titleLine = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = titleBar,
    })
    PittikUI:_TrackBg(titleLine)

    local logoContainer = Util.Create("Frame", {
        Name = "TitleLogoContainer",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 12, 0.5, -12),
        BackgroundTransparency = 1,
        Parent = titleBar,
    })

    local logoImage = Util.Create("ImageLabel", {
        Name = "TitleLogo",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ImageColor3 = T.Accent,
        ScaleType = Enum.ScaleType.Fit,
        Parent = logoContainer,
    })
    PittikUI:_TrackImage(logoImage)

    local pFallback = Util.Create("Frame", {
        Name = "FallbackLogo",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = T.SurfaceAlt,
        BorderSizePixel = 0,
        Parent = logoContainer,
    })
    Util.Corner(pFallback, UDim.new(0, 6))
    local pStroke = Util.Stroke(pFallback, T.Accent, 1.2, 0.2)
    PittikUI:_TrackStroke(pStroke)
    local pText = Util.Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "P",
        TextColor3 = T.Accent,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        Parent = pFallback,
    })
    PittikUI:_TrackText(pText)

    local function updateLogoVisual(asset)
        if asset and asset ~= "" then
            logoImage.Image = asset
            logoImage.Visible = true
            pFallback.Visible = false
        else
            logoImage.Visible = false
            pFallback.Visible = true
        end
    end

    local iconAsset = PittikUI:ResolveAsset(options.Icon or options.Logo)
    updateLogoVisual(iconAsset)

    if options.Icon == false or options.Logo == false then
        logoContainer.Visible = false
    end

    local titleLabel = Util.Create("TextLabel", {
        Size = UDim2.new(0.7, -80, 1, 0),
        Position = (options.Icon ~= false and options.Logo ~= false) and UDim2.new(0, 42, 0, 0) or UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        RichText = true,
        Text = title,
        TextColor3 = T.TextAccent,
        TextSize = 16,
        Font = FONT_MAIN,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = (title ~= nil and title ~= ""),
        Parent = titleBar,
    })
    PittikUI:_TrackText(titleLabel)

    if options.ShowBrand then
        Util.Create("TextLabel", {
            Size = UDim2.new(0, 50, 1, 0),
            Position = UDim2.new(1, -118, 0, 0),
            BackgroundTransparency = 1,
            Text = "PittikUI",
            TextColor3 = T.TextDim,
            TextTransparency = 0.5,
            TextSize = 9,
            Font = FONT_SMALL,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = titleBar,
        })
    end

    local controlsFrame = Util.Create("Frame", {
        Size = UDim2.new(0, 60, 0, 38),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundTransparency = 1,
        Parent = titleBar,
    })

    local minimizeBtn = Util.Create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(0, 0, 0.5, -14),
        BackgroundColor3 = T.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "—",
        TextColor3 = T.TextDim,
        TextSize = 14,
        Font = FONT_MAIN,
        AutoButtonColor = false,
        Parent = controlsFrame,
    })
    Util.Corner(minimizeBtn)
    Util.Stroke(minimizeBtn, T.Border, 1, 0.6)

    local closeBtn = Util.Create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(0, 30, 0.5, -14),
        BackgroundColor3 = T.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "✕",
        TextColor3 = T.Danger,
        TextSize = 12,
        Font = FONT_MAIN,
        AutoButtonColor = false,
        Parent = controlsFrame,
    })
    Util.Corner(closeBtn)
    Util.Stroke(closeBtn, T.Danger, 1, 0.7)

    local tabBarContainer = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        Position = UDim2.new(0, 0, 0, 38),
        BackgroundColor3 = T.Surface,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Border,
        BorderSizePixel = 0,
        Parent = tabBarContainer,
    })

    local tabBar = Util.Create("ScrollingFrame", {
        Name = "TabBar",
        Size = UDim2.new(1, -16, 1, -4),
        Position = UDim2.new(0, 8, 0, 2),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        Parent = tabBarContainer,
    })
    local tabLayout = Util.ListLayout(tabBar, 4, Enum.FillDirection.Horizontal,
        Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabBar.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + 8, 0, 0)
    end)

    local contentArea = Util.Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -16, 1, -82),
        Position = UDim2.new(0, 8, 0, 74),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = mainFrame,
    })

    local resizeHandle = Util.Create("TextButton", {
        Name = "ResizeHandle",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -18, 1, -18),
        BackgroundColor3 = T.SurfaceAlt,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 50,
        Parent = mainFrame,
    })
    Util.Corner(resizeHandle)
    for i = 0, 2 do
        local grip = Util.Create("Frame", {
            Size = UDim2.new(0, 10 - i * 3, 0, 1),
            Position = UDim2.new(1, -12 + i * 3, 0, 5 + i * 4),
            BackgroundColor3 = T.Accent,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            Rotation = -45,
            ZIndex = 51,
            Parent = resizeHandle,
        })
        PittikUI:_TrackBg(grip)
    end

    do
        local resizing = false
        local resizeStart, sizeStart
        resizeHandle.MouseEnter:Connect(function() Util.Tween(resizeHandle, 0.15, { BackgroundColor3 = T.CardHover }) end)
        resizeHandle.MouseLeave:Connect(function() Util.Tween(resizeHandle, 0.15, { BackgroundColor3 = T.SurfaceAlt }) end)
        resizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = true
                resizeStart = input.Position
                sizeStart = mainFrame.AbsoluteSize
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then resizing = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - resizeStart
                local newW = math.clamp(sizeStart.X + delta.X, minSize.X, maxSize.X)
                local newH = math.clamp(sizeStart.Y + delta.Y, minSize.Y, maxSize.Y)
                mainFrame.Size = UDim2.new(0, newW, 0, newH)
            end
        end)
    end

    if options.ShowVersion then
        Util.Create("TextLabel", {
            Size = UDim2.new(0, 60, 0, 14),
            Position = UDim2.new(0, 6, 1, -16),
            BackgroundTransparency = 1,
            Text = "PittikUI v" .. PittikUI.Version,
            TextColor3 = T.TextDim,
            TextTransparency = 0.6,
            TextSize = 8,
            Font = FONT_SMALL,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 2,
            Parent = mainFrame,
        })
    end

    Util.MakeDraggable(mainFrame, titleBar)

    local windowObj = setmetatable({
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        TitleBar = titleBar,
        TitleBarFill = titleBarFill,
        TitleLabel = titleLabel,
        LogoContainer = logoContainer,
        LogoImage = logoImage,
        _updateLogoVisual = updateLogoVisual,
        TabBarContainer = tabBarContainer,
        TabBar = tabBar,
        ContentArea = contentArea,
        Tabs = {},
        Sections = {},
        ActiveTab = nil,
        Minimized = false,
        Visible = true,
        Config = ConfigManager.new(PittikUI.ConfigFolder),
        Flags = PittikUI.Flags,
        _originalSize = size,
    }, Window)

    for _, btn in pairs({minimizeBtn, closeBtn}) do
        btn.MouseEnter:Connect(function() Util.Tween(btn, 0.15, { BackgroundColor3 = T.CardHover }) end)
        btn.MouseLeave:Connect(function() Util.Tween(btn, 0.15, { BackgroundColor3 = T.SurfaceAlt }) end)
    end
    minimizeBtn.MouseButton1Click:Connect(function() windowObj:Minimize() end)
    closeBtn.MouseButton1Click:Connect(function() windowObj:Close() end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if PittikUI._listeningForKeybind then return end
        if input.KeyCode == PittikUI.ToggleKey then windowObj:Toggle() end
    end)

    table.insert(PittikUI.Windows, windowObj)
    task.defer(function()
        pcall(function() windowObj:_CreateDefaultSettings() end)
    end)
    return windowObj
end

function Window:SetTransparency(val)
    if typeof(val) ~= "number" then return end
    if val > 1 then val = val / 100 end
    val = math.clamp(val, 0, 0.95)

    if self.MainFrame and self.MainFrame:IsA("CanvasGroup") then
        self.MainFrame.GroupTransparency = val
    else
        if self.MainFrame then
            self.MainFrame.BackgroundTransparency = val
        end
        if self.TitleBar then
            self.TitleBar.BackgroundTransparency = val
        end
        if self.TitleBarFill then
            self.TitleBarFill.BackgroundTransparency = val
        end
        if self.TabBarContainer then
            self.TabBarContainer.BackgroundTransparency = math.clamp(0.3 + val * 0.7, 0, 1)
        end
        for _, sec in ipairs(self.Sections or {}) do
            if sec.Frame then
                sec.Frame.BackgroundTransparency = math.clamp(val * 0.85, 0, 0.95)
            end
            if sec.Header then
                sec.Header.BackgroundTransparency = math.clamp(0.3 + val * 0.7, 0, 1)
            end
            if sec.HeaderFill then
                sec.HeaderFill.BackgroundTransparency = math.clamp(0.3 + val * 0.7, 0, 1)
            end
        end
    end
end

function Window:_CreateDefaultSettings()
    if self._hasSettingsTab then return end
    for _, tab in ipairs(self.Tabs) do
        if tab.Name == "Settings" then
            self._hasSettingsTab = true
            return
        end
    end
    self._hasSettingsTab = true

    local SettingsTab = self:AddTab({ Name = "Settings" })
    SettingsTab.Button.LayoutOrder = 9999

    if #self.Tabs > 1 and self.Tabs[1] ~= SettingsTab then
        self:_SelectTab(self.Tabs[1])
    end

    local ConfigSection = SettingsTab:AddSection({ Name = "Configuration" })
    local configNameBox = ConfigSection:AddTextBox({
        Name = "Config Name",
        Placeholder = "Enter config name...",
    })

    local cfgDropdown

    ConfigSection:AddButton({
        Name = "Save Config",
        Callback = function()
            local name = configNameBox:GetText()
            if name == "" then
                PittikUI:Notify({ Title = "Config", Content = "Please enter a config name!", Duration = 3 })
                return
            end
            local ok = self:SaveConfig(name)
            PittikUI:Notify({
                Title = "Config",
                Content = ok and ('"' .. name .. '" saved!') or "Save failed!",
                Duration = 3,
            })
            if cfgDropdown and cfgDropdown.Refresh then
                local list = self.Config:List()
                cfgDropdown:Refresh(#list > 0 and list or {"(empty)"})
            end
        end,
    })

    local savedList = self.Config:List()
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
            self:LoadConfig(sel)
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
            self.Config:Delete(sel)
            PittikUI:Notify({ Title = "Config", Content = '"' .. sel .. '" deleted!', Duration = 3 })
            local list = self.Config:List()
            cfgDropdown:Refresh(#list > 0 and list or {"(empty)"})
        end,
    })

    local ThemeSec = SettingsTab:AddSection({ Name = "UI Customization" })

    ThemeSec:AddColorPicker({
        Name = "Accent Color",
        Default = T.Accent,
        Callback = function(color)
            PittikUI:SetAccentColor(color)
        end,
    })

    ThemeSec:AddSlider({
        Name = "Menu Transparency",
        Min = 0,
        Max = 90,
        Default = math.floor(PittikUI.Transparency * 100),
        Increment = 5,
        Suffix = "%",
        Flag = "MenuTransparency",
        Callback = function(val)
            PittikUI:SetTransparency(val / 100)
        end,
    })

    ThemeSec:AddKeybind({
        Name = "Toggle GUI Key",
        Default = PittikUI.ToggleKey,
        Callback = function(key)
            PittikUI.ToggleKey = key
        end,
    })

    ThemeSec:AddButton({
        Name = "Destroy GUI",
        Callback = function()
            self:Close()
        end,
    })
end

function Window:SetTitle(newTitle)
    self.TitleLabel.Text = newTitle
end

function Window:SetIcon(icon)
    if icon == false then
        if self.LogoContainer then self.LogoContainer.Visible = false end
        self.TitleLabel.Position = UDim2.new(0, 14, 0, 0)
        return
    end
    local asset = PittikUI:ResolveAsset(icon)
    if self._updateLogoVisual then
        self._updateLogoVisual(asset)
    end
    if self.LogoContainer then self.LogoContainer.Visible = true end
    self.TitleLabel.Position = UDim2.new(0, 42, 0, 0)
end
Window.SetLogo = Window.SetIcon

function Window:AddTab(options)
    options = options or {}
    local name = options.Name or "Tab"

    for _, existingTab in ipairs(self.Tabs) do
        if existingTab.Name == name then
            return existingTab
        end
    end

    if name == "Settings" then
        self._hasSettingsTab = true
    end

    local tabIndex = #self.Tabs + 1

    local tabBtn = Util.Create("TextButton", {
        Name = "Tab_" .. name,
        Size = UDim2.new(0, 0, 0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = T.SurfaceAlt,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = tabIndex,
        Parent = self.TabBar,
    })
    Util.Corner(tabBtn)
    Util.Padding(tabBtn, 0, 12, 0, 12)

    local tabLabel = Util.Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = T.TextDim,
        TextSize = 12,
        Font = FONT_BODY,
        Parent = tabBtn,
    })

    local tabIndicator = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = tabBtn,
    })

    local tabPage = Util.Create("ScrollingFrame", {
        Name = "Page_" .. name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        Visible = false,
        Parent = self.ContentArea,
    })
    PittikUI:_TrackScrollBar(tabPage)
    Util.Padding(tabPage, 4, 0, 4, 0)
    local pageLayout = Util.ListLayout(tabPage, 8)
    Util.AutoResize(tabPage, pageLayout)

    local tabObj = {
        Name = name,
        Button = tabBtn,
        Label = tabLabel,
        Indicator = tabIndicator,
        Page = tabPage,
        Sections = {},
        Window = self,
    }

    tabBtn.MouseButton1Click:Connect(function() self:_SelectTab(tabObj) end)
    tabBtn.MouseEnter:Connect(function()
        if self.ActiveTab ~= tabObj then
            Util.Tween(tabBtn, 0.15, { BackgroundTransparency = 0.2 })
            Util.Tween(tabLabel, 0.15, { TextColor3 = T.Text })
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if self.ActiveTab ~= tabObj then
            Util.Tween(tabBtn, 0.15, { BackgroundTransparency = 0.5 })
            Util.Tween(tabLabel, 0.15, { TextColor3 = T.TextDim })
        end
    end)

    table.insert(self.Tabs, tabObj)
    if name ~= "Settings" and (not self.ActiveTab or self.ActiveTab.Name == "Settings") then
        self:_SelectTab(tabObj)
    elseif #self.Tabs == 1 then
        self:_SelectTab(tabObj)
    end

    setmetatable(tabObj, { __index = {
        AddSection = function(_, sOpts) return self:_AddSection(tabObj, sOpts) end
    }})
    return tabObj
end

function Window:_SelectTab(tabObj)
    if self.ActiveTab then
        local p = self.ActiveTab
        p.Page.Visible = false
        Util.Tween(p.Button, 0.2, { BackgroundTransparency = 0.5 })
        Util.Tween(p.Label, 0.2, { TextColor3 = T.TextDim })
        Util.Tween(p.Indicator, 0.2, { BackgroundTransparency = 1 })
    end
    self.ActiveTab = tabObj
    tabObj.Page.Visible = true
    Util.Tween(tabObj.Button, 0.2, { BackgroundTransparency = 0 })
    tabObj.Label.TextColor3 = T.TextAccent
    tabObj.Indicator.BackgroundColor3 = T.Accent
    Util.Tween(tabObj.Indicator, 0.2, { BackgroundTransparency = 0 })
end

function Window:Minimize()
    self.Minimized = not self.Minimized
    if self.Minimized then
        Util.Tween(self.MainFrame, 0.3, { Size = UDim2.new(0, self.MainFrame.AbsoluteSize.X, 0, 38) })
    else
        Util.Tween(self.MainFrame, 0.3, { Size = self._originalSize })
    end
end

function Window:Toggle()
    self.Visible = not self.Visible
    self.ScreenGui.Enabled = self.Visible
end

function Window:Close()
    if self.OnClose then
        pcall(self.OnClose)
    end
    Util.Tween(self.MainFrame, 0.3, {
        Size = UDim2.new(0, self.MainFrame.AbsoluteSize.X, 0, 0),
        Position = UDim2.new(
            self.MainFrame.Position.X.Scale, self.MainFrame.Position.X.Offset,
            self.MainFrame.Position.Y.Scale, self.MainFrame.Position.Y.Offset + self.MainFrame.AbsoluteSize.Y / 2
        )
    })
    task.delay(0.35, function() self.ScreenGui:Destroy() end)
end

function Window:SaveConfig(name) return self.Config:SaveFlags(name, PittikUI.Flags) end
function Window:LoadConfig(name) return self.Config:LoadFlags(name, PittikUI.Flags) end

function Window:_AddSection(tabObj, options)
    options = options or {}
    local name = options.Name or "Section"

    local sectionFrame = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.Card,
        BackgroundTransparency = math.clamp(PittikUI.Transparency * 0.85, 0, 0.95),
        BorderSizePixel = 0,
        LayoutOrder = #tabObj.Sections + 1,
        Parent = tabObj.Page,
    })
    Util.Corner(sectionFrame)
    Util.Stroke(sectionFrame, T.Accent, 1, 0.65)

    local headerFrame = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = T.SurfaceAlt,
        BackgroundTransparency = math.clamp(0.3 + PittikUI.Transparency * 0.7, 0, 1),
        BorderSizePixel = 0,
        Parent = sectionFrame,
    })
    Util.Corner(headerFrame)
    local headerFill = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, -6),
        BackgroundColor3 = T.SurfaceAlt,
        BackgroundTransparency = math.clamp(0.3 + PittikUI.Transparency * 0.7, 0, 1),
        BorderSizePixel = 0,
        Parent = headerFrame,
    })

    table.insert(self.Sections, {
        Frame = sectionFrame,
        Header = headerFrame,
        HeaderFill = headerFill,
    })

    local hAccent = Util.Create("Frame", {
        Size = UDim2.new(0, 3, 0.6, 0),
        Position = UDim2.new(0, 8, 0.2, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        Parent = headerFrame,
    })
    PittikUI:_TrackBg(hAccent)

    local hLabel = Util.Create("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(name),
        TextColor3 = T.TextAccent,
        TextSize = 11,
        Font = FONT_MAIN,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = headerFrame,
    })
    PittikUI:_TrackText(hLabel)

    local contentContainer = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = sectionFrame,
    })
    Util.Padding(contentContainer, 6, 10, 10, 10)
    Util.ListLayout(contentContainer, 5)

    local S = {
        Name = name,
        Frame = sectionFrame,
        Content = contentContainer,
        Window = self,
        Elements = {},
    }

    function S:AddLabel(opts)
        opts = opts or {}
        local label = Util.Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = opts.Name or opts.Text or "Label",
            TextColor3 = T.TextDim,
            TextSize = 12,
            Font = FONT_BODY,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = #self.Elements + 1,
            Parent = self.Content,
        })
        local el = { Instance = label, Type = "Label" }
        function el:Set(t) label.Text = t end
        table.insert(self.Elements, el)
        return el
    end

    function S:AddButton(opts)
        opts = opts or {}
        local bName = opts.Name or "Button"
        local callback = opts.Callback or function() end

        local btnFrame = Util.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            LayoutOrder = #self.Elements + 1,
            Parent = self.Content,
        })
        local btn = Util.Create("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = T.SurfaceAlt,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = btnFrame,
        })
        Util.Corner(btn)
        Util.Stroke(btn, T.Accent, 1, 0.7)

        Util.Create("TextLabel", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = bName,
            TextColor3 = T.Text,
            TextSize = 12,
            Font = FONT_BODY,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = btn,
        })
        local arrow = Util.Create("TextLabel", {
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(1, -24, 0, 0),
            BackgroundTransparency = 1,
            Text = "▶",
            TextColor3 = T.AccentDim,
            TextSize = 10,
            Font = FONT_MAIN,
            Parent = btn,
        })
        PittikUI:_TrackAccentDimText(arrow)
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        btn.MouseEnter:Connect(function()
            Util.Tween(btn, 0.15, { BackgroundColor3 = T.CardHover })
            if stroke then Util.Tween(stroke, 0.15, { Transparency = 0.3 }) end
            Util.Tween(arrow, 0.15, { TextColor3 = T.Accent })
        end)
        btn.MouseLeave:Connect(function()
            Util.Tween(btn, 0.15, { BackgroundColor3 = T.SurfaceAlt })
            if stroke then Util.Tween(stroke, 0.15, { Transparency = 0.7 }) end
            Util.Tween(arrow, 0.15, { TextColor3 = T.AccentDim })
        end)
        btn.MouseButton1Click:Connect(function()
            Util.Ripple(btn, T.AccentGlow)
            callback()
        end)
        table.insert(self.Elements, { Instance = btnFrame, Type = "Button" })
    end

    local function CreateColorPickerWidget(parentFrame, colorBtn, opts)
        opts = opts or {}
        local callback = opts.Callback or function() end
        local hue, sat, val = 0.33, 1, 1
        if opts.Default then hue, sat, val = Color3.toHSV(opts.Default) end

        local isOpen = false

        local pickerContainer = Util.Create("Frame", {
            Size = UDim2.new(1, -16, 0, 102),
            Position = UDim2.new(0, 8, 0, 34),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Visible = false,
            Parent = parentFrame,
        })

        local svField = Util.Create("Frame", {
            Size = UDim2.new(1, -55, 0, 76),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = pickerContainer,
        })
        Util.Corner(svField)

        local whiteOv = Util.Create("Frame", { Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = svField })
        Util.Create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) }), Parent = whiteOv })
        local blackOv = Util.Create("Frame", { Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(0,0,0), BorderSizePixel = 0, Parent = svField })
        Util.Create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }), Rotation = 90, Parent = blackOv })

        local svCursor = Util.Create("Frame", { Size = UDim2.new(0,10,0,10), Position = UDim2.new(sat,-5,1-val,-5), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Parent = svField })
        Util.Stroke(svCursor, Color3.new(1,1,1), 2, 0)

        local svBtn = Util.Create("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 6, Parent = svField })

        local hueBar = Util.Create("Frame", { Size = UDim2.new(1,-55,0,14), Position = UDim2.new(0,0,0,84), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ClipsDescendants = true, Parent = pickerContainer })
        Util.Corner(hueBar)
        Util.Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
                ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255,255,0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,0,255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
            }),
            Parent = hueBar,
        })

        local hueCursor = Util.Create("Frame", { Size = UDim2.new(0,4,1,4), Position = UDim2.new(hue,-2,0,-2), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 5, Parent = hueBar })
        Util.Corner(hueCursor)
        local hueBtn = Util.Create("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 6, Parent = hueBar })

        local preview = Util.Create("Frame", { Size = UDim2.new(0,42,0,42), Position = UDim2.new(1,-44,0,0), BackgroundColor3 = Color3.fromHSV(hue,sat,val), BorderSizePixel = 0, Parent = pickerContainer })
        Util.Corner(preview)
        Util.Stroke(preview, Color3.new(1,1,1), 1, 0.5)

        local function toHex(c) return string.format("#%02X%02X%02X", math.floor(c.R*255+.5), math.floor(c.G*255+.5), math.floor(c.B*255+.5)) end

        local hexLbl = Util.Create("TextLabel", { Size = UDim2.new(0,44,0,18), Position = UDim2.new(1,-45,0,48), BackgroundTransparency = 1, Text = toHex(Color3.fromHSV(hue,sat,val)), TextColor3 = T.TextDim, TextSize = 9, Font = FONT_SMALL, Parent = pickerContainer })

        local element

        local function updateColor(notify)
            local c = Color3.fromHSV(hue, sat, val)
            svField.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
            svCursor.Position = UDim2.new(sat, -5, 1-val, -5)
            hueCursor.Position = UDim2.new(hue, -2, 0, -2)
            preview.BackgroundColor3 = c
            colorBtn.BackgroundColor3 = c
            hexLbl.Text = toHex(c)
            if element then element.Value = c end
            if notify ~= false then
                callback(c, toHex(c))
            end
        end

        local svDrag, hueDrag = false, false
        svBtn.MouseButton1Down:Connect(function()
            svDrag = true
            local p, s = svField.AbsolutePosition, svField.AbsoluteSize
            sat = math.clamp((Mouse.X-p.X)/s.X, 0, 1)
            val = math.clamp(1-(Mouse.Y-p.Y)/s.Y, 0, 1)
            updateColor(true)
        end)
        hueBtn.MouseButton1Down:Connect(function()
            hueDrag = true
            hue = math.clamp((Mouse.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X, 0, 0.999)
            updateColor(true)
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if svDrag then
                    local p, s = svField.AbsolutePosition, svField.AbsoluteSize
                    sat = math.clamp((input.Position.X-p.X)/s.X, 0, 1)
                    val = math.clamp(1-(input.Position.Y-p.Y)/s.Y, 0, 1)
                    updateColor(true)
                elseif hueDrag then
                    hue = math.clamp((input.Position.X-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X, 0, 0.999)
                    updateColor(true)
                end
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false; hueDrag = false end
        end)

        colorBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                pickerContainer.Visible = true
                Util.Tween(parentFrame, 0.2, { Size = UDim2.new(1, 0, 0, 142) })
            else
                Util.Tween(parentFrame, 0.2, { Size = UDim2.new(1, 0, 0, 32) })
                task.delay(0.2, function()
                    if not isOpen then pickerContainer.Visible = false end
                end)
            end
        end)

        element = {
            Instance = parentFrame,
            Type = "ColorPicker",
            Value = Color3.fromHSV(hue, sat, val),
        }
        function element:Set(newColor)
            hue, sat, val = Color3.toHSV(newColor)
            updateColor(true)
        end

        if opts.Flag then
            element.Flag = opts.Flag
            PittikUI.Flags[opts.Flag] = element
        end

        return element
    end

    function S:AddToggle(opts)
        opts = opts or {}
        local tName = opts.Name or "Toggle"
        local default = opts.Default or false
        local flag = opts.Flag or nil
        local callback = opts.Callback or function() end
        local state = default

        local frame = Util.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = T.SurfaceAlt,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            LayoutOrder = #self.Elements + 1,
            Parent = self.Content,
        })
        Util.Corner(frame)
        Util.Stroke(frame, T.Border, 1, 0.7)

        local titleLbl = Util.Create("TextLabel", {
            Size = UDim2.new(1, -85, 0, 32),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = tName,
            TextColor3 = T.Text,
            TextSize = 12,
            Font = FONT_BODY,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame,
        })

        local swBg = Util.Create("Frame", {
            Size = UDim2.new(0, 36, 0, 18),
            Position = UDim2.new(1, -46, 0, 7),
            BackgroundColor3 = state and T.ToggleOn or T.ToggleOff,
            BorderSizePixel = 0,
            Parent = frame,
        })
        Util.Corner(swBg)

        local knob = Util.Create("Frame", {
            Size = UDim2.new(0, 14, 0, 14),
            Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = swBg,
        })
        Util.Corner(knob)

        local element

        local function updateVisual()
            if state then
                Util.Tween(swBg, 0.2, { BackgroundColor3 = T.ToggleOn })
                Util.Tween(knob, 0.2, { Position = UDim2.new(1, -16, 0.5, -7) })
            else
                Util.Tween(swBg, 0.2, { BackgroundColor3 = T.ToggleOff })
                Util.Tween(knob, 0.2, { Position = UDim2.new(0, 2, 0.5, -7) })
            end
        end

        local function toggleState()
            state = not state
            element.Value = state
            updateVisual()
            callback(state)
        end

        local clickBtn = Util.Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 2,
            Parent = frame,
        })
        clickBtn.MouseEnter:Connect(function() Util.Tween(frame, 0.15, { BackgroundColor3 = T.CardHover }) end)
        clickBtn.MouseLeave:Connect(function() Util.Tween(frame, 0.15, { BackgroundColor3 = T.SurfaceAlt }) end)
        clickBtn.MouseButton1Click:Connect(toggleState)

        table.insert(PittikUI._toggles, {
            Bg = swBg,
            GetState = function() return state end
        })

        element = { Instance = frame, Type = "Toggle", Value = state }
        function element:Set(val)
            state = val
            element.Value = val
            updateVisual()
            callback(state)
        end
        if flag then element.Flag = flag; PittikUI.Flags[flag] = element end

        function element:AddColorPicker(cOpts)
            cOpts = cOpts or {}
            local initColor = cOpts.Default or Color3.fromRGB(0, 255, 128)
            local colorBtn = Util.Create("TextButton", {
                Size = UDim2.new(0, 24, 0, 18),
                Position = UDim2.new(1, -76, 0, 7),
                BackgroundColor3 = initColor,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Active = true,
                ZIndex = 10,
                Parent = frame,
            })
            Util.Corner(colorBtn, UDim.new(0, 4))
            Util.Stroke(colorBtn, T.Border, 1, 0.6)

            titleLbl.Size = UDim2.new(1, -115, 0, 32)

            local picker = CreateColorPickerWidget(frame, colorBtn, cOpts)
            table.insert(S.Elements, picker)
            element.ColorPicker = picker
            return picker
        end

        if opts.Color or opts.ColorCallback or opts.ColorFlag then
            element:AddColorPicker({
                Default = opts.Color,
                Flag = opts.ColorFlag,
                Callback = opts.ColorCallback,
            })
        end

        table.insert(self.Elements, element)
        return element
    end

    function S:AddSlider(opts)
        opts = opts or {}
        local sName = opts.Name or "Slider"
        local min = opts.Min or 0
        local max = opts.Max or 100
        local default = opts.Default or min
        local increment = opts.Increment or 1
        local suffix = opts.Suffix or ""
        local flag = opts.Flag or nil
        local callback = opts.Callback or function() end
        local value = math.clamp(default, min, max)

        local frame = Util.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 48),
            BackgroundColor3 = T.SurfaceAlt,
            BorderSizePixel = 0,
            LayoutOrder = #self.Elements + 1,
            Parent = self.Content,
        })
        Util.Corner(frame)
        Util.Stroke(frame, T.Border, 1, 0.7)

        Util.Create("TextLabel", {
            Size = UDim2.new(0.6, 0, 0, 20),
            Position = UDim2.new(0, 10, 0, 4),
            BackgroundTransparency = 1,
            Text = sName,
            TextColor3 = T.Text,
            TextSize = 12,
            Font = FONT_BODY,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = frame,
        })
        local valLabel = Util.Create("TextLabel", {
            Size = UDim2.new(0.4, -10, 0, 20),
            Position = UDim2.new(0.6, 0, 0, 4),
            BackgroundTransparency = 1,
            Text = tostring(value) .. suffix,
            TextColor3 = T.TextAccent,
            TextSize = 12,
            Font = FONT_MAIN,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = frame,
        })
        PittikUI:_TrackText(valLabel)

        local track = Util.Create("Frame", {
            Size = UDim2.new(1, -20, 0, 6),
            Position = UDim2.new(0, 10, 0, 32),
            BackgroundColor3 = T.SliderTrack,
            BorderSizePixel = 0,
            Parent = frame,
        })
        Util.Corner(track)

        local pct = (value - min) / (max - min)
        local fill = Util.Create("Frame", {
            Size = UDim2.new(pct, 0, 1, 0),
            BackgroundColor3 = T.SliderFill,
            BorderSizePixel = 0,
            Parent = track,
        })
        Util.Corner(fill)
        PittikUI:_TrackBg(fill)

        local sknob = Util.Create("Frame", {
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(pct, -6, 0.5, -6),
            BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = track,
        })
        Util.Corner(sknob)
        Util.Stroke(sknob, T.Accent, 1, 0.5)
        PittikUI:_TrackBg(sknob)

        local element
        local dragging = false

        local function updateSlider(posX)
            local tStart = track.AbsolutePosition.X
            local tWidth = track.AbsoluteSize.X
            local rel = math.clamp((posX - tStart) / tWidth, 0, 1)
            local raw = min + (max - min) * rel
            value = math.floor(raw / increment + 0.5) * increment
            value = math.clamp(value, min, max)
            element.Value = value
            local p = (value - min) / (max - min)
            fill.Size = UDim2.new(p, 0, 1, 0)
            sknob.Position = UDim2.new(p, -6, 0.5, -6)
            valLabel.Text = tostring(value) .. suffix
            callback(value)
        end

        local inputBtn = Util.Create("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 3,
            Parent = track,
        })
        inputBtn.MouseButton1Down:Connect(function() dragging = true; updateSlider(Mouse.X) end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input.Position.X) end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        frame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then Util.Tween(frame, 0.15, { BackgroundColor3 = T.CardHover }) end end)
        frame.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then Util.Tween(frame, 0.15, { BackgroundColor3 = T.SurfaceAlt }) end end)

        element = { Instance = frame, Type = "Slider", Value = value }
        function element:Set(val)
            value = math.clamp(val, min, max); element.Value = value
            local p = (value - min) / (max - min)
            fill.Size = UDim2.new(p, 0, 1, 0)
            sknob.Position = UDim2.new(p, -6, 0.5, -6)
            valLabel.Text = tostring(value) .. suffix
            callback(value)
        end
        if flag then element.Flag = flag; PittikUI.Flags[flag] = element end
        table.insert(self.Elements, element)
        return element
    end

    function S:AddDropdown(opts)
        opts = opts or {}
        local dName = opts.Name or "Dropdown"
        local items = opts.Items or {}
        local default = opts.Default or (items[1] or "")
        local flag = opts.Flag or nil
        local callback = opts.Callback or function() end
        local selected = default
        local isOpen = false

        local dFrame = Util.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            ClipsDescendants = false,
            LayoutOrder = #self.Elements + 1,
            Parent = self.Content,
        })
        local mainBar = Util.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = T.SurfaceAlt,
            BorderSizePixel = 0,
            Parent = dFrame,
        })
        Util.Corner(mainBar)
        Util.Stroke(mainBar, T.Border, 1, 0.7)

        Util.Create("TextLabel", {
            Size = UDim2.new(0.5, -10, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = dName,
            TextColor3 = T.Text,
            TextSize = 12,
            Font = FONT_BODY,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = mainBar,
        })
        local selLabel = Util.Create("TextLabel", {
            Size = UDim2.new(0.5, -30, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(selected),
            TextColor3 = T.TextAccent,
            TextSize = 12,
            Font = FONT_MAIN,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = mainBar,
        })
        PittikUI:_TrackText(selLabel)

        local arrowLbl = Util.Create("TextLabel", {
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(1, -22, 0, 0),
            BackgroundTransparency = 1,
            Text = "▼",
            TextColor3 = T.AccentDim,
            TextSize = 10,
            Font = FONT_MAIN,
            Parent = mainBar,
        })
        PittikUI:_TrackAccentDimText(arrowLbl)

        local optContainer = Util.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 34),
            BackgroundColor3 = T.DropdownBg,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 10,
            Visible = false,
            Parent = dFrame,
        })
        Util.Corner(optContainer)
        Util.Stroke(optContainer, T.Accent, 1, 0.5)
        Util.Padding(optContainer, 3, 3, 3, 3)
        Util.ListLayout(optContainer, 2)
        local optBtns = {}
        local element

        local function buildOptions()
            for _, b in ipairs(optBtns) do b:Destroy() end
            optBtns = {}
            for i, item in ipairs(items) do
                local ob = Util.Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = T.SurfaceAlt,
                    BackgroundTransparency = (tostring(item) == tostring(selected)) and 0 or 0.5,
                    BorderSizePixel = 0,
                    Text = tostring(item),
                    TextColor3 = (tostring(item) == tostring(selected)) and T.TextAccent or T.Text,
                    TextSize = 11,
                    Font = FONT_BODY,
                    AutoButtonColor = false,
                    ZIndex = 11,
                    LayoutOrder = i,
                    Parent = optContainer,
                })
                Util.Corner(ob)
                ob.MouseEnter:Connect(function() Util.Tween(ob, 0.1, { BackgroundTransparency = 0, BackgroundColor3 = T.CardHover }) end)
                ob.MouseLeave:Connect(function()
                    local isSel = tostring(item) == tostring(selected)
                    Util.Tween(ob, 0.1, { BackgroundTransparency = isSel and 0 or 0.5, BackgroundColor3 = T.SurfaceAlt })
                end)
                ob.MouseButton1Click:Connect(function()
                    selected = item; element.Value = selected
                    selLabel.Text = tostring(item)
                    callback(item)
                    isOpen = false; arrowLbl.Text = "▼"
                    Util.Tween(optContainer, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
                    Util.Tween(dFrame, 0.2, { Size = UDim2.new(1, 0, 0, 32) })
                    task.delay(0.2, function() optContainer.Visible = false end)
                    task.defer(buildOptions)
                end)
                table.insert(optBtns, ob)
            end
        end
        buildOptions()

        local togBtn = Util.Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 5,
            Parent = mainBar,
        })
        togBtn.MouseEnter:Connect(function() Util.Tween(mainBar, 0.15, { BackgroundColor3 = T.CardHover }) end)
        togBtn.MouseLeave:Connect(function() Util.Tween(mainBar, 0.15, { BackgroundColor3 = T.SurfaceAlt }) end)
        togBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                arrowLbl.Text = "▲"; optContainer.Visible = true
                local th = #items * 28 + 6
                Util.Tween(optContainer, 0.2, { Size = UDim2.new(1, 0, 0, th) })
                Util.Tween(dFrame, 0.2, { Size = UDim2.new(1, 0, 0, 32 + th + 4) })
            else
                arrowLbl.Text = "▼"
                Util.Tween(optContainer, 0.2, { Size = UDim2.new(1, 0, 0, 0) })
                Util.Tween(dFrame, 0.2, { Size = UDim2.new(1, 0, 0, 32) })
                task.delay(0.2, function() optContainer.Visible = false end)
            end
        end)

        element = { Instance = dFrame, Type = "Dropdown", Value = selected }
        function element:Set(val)
            selected = val; element.Value = val
            selLabel.Text = tostring(val); callback(val)
            task.defer(buildOptions)
        end
        function element:Refresh(newItems, keep)
            items = newItems
            if not keep then selected = items[1] or ""; selLabel.Text = tostring(selected); element.Value = selected end
            buildOptions()
        end
        if flag then element.Flag = flag; PittikUI.Flags[flag] = element end
        table.insert(self.Elements, element)
        return element
    end

    function S:AddTextBox(opts)
        opts = opts or {}
        local tbFrame = Util.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = T.SurfaceAlt,
            BorderSizePixel = 0,
            LayoutOrder = #self.Elements + 1,
            Parent = self.Content,
        })
        Util.Corner(tbFrame)
        Util.Stroke(tbFrame, T.Border, 1, 0.7)

        Util.Create("TextLabel", {
            Size = UDim2.new(0.4, -5, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = opts.Name or "TextBox",
            TextColor3 = T.Text,
            TextSize = 12,
            Font = FONT_BODY,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tbFrame,
        })
        local tb = Util.Create("TextBox", {
            Size = UDim2.new(0.6, -10, 0, 24),
            Position = UDim2.new(0.4, 0, 0.5, -12),
            BackgroundColor3 = T.Background,
            BorderSizePixel = 0,
            Text = opts.Default or "",
            PlaceholderText = opts.Placeholder or "Type here...",
            PlaceholderColor3 = T.TextDim,
            TextColor3 = T.Text,
            TextSize = 12,
            Font = FONT_BODY,
            ClearTextOnFocus = false,
            Parent = tbFrame,
        })
        Util.Corner(tb)
        Util.Stroke(tb, T.Border, 1, 0.7)

        local cb = opts.Callback or function() end
        tb.FocusLost:Connect(function(enter) cb(tb.Text, enter) end)

        tbFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then Util.Tween(tbFrame, 0.15, { BackgroundColor3 = T.CardHover }) end end)
        tbFrame.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then Util.Tween(tbFrame, 0.15, { BackgroundColor3 = T.SurfaceAlt }) end end)

        local el = { Instance = tbFrame, Type = "TextBox", TextBox = tb }
        function el:GetText() return tb.Text end
        function el:SetText(t) tb.Text = t end
        table.insert(self.Elements, el)
        return el
    end

    function S:AddKeybind(opts)
        opts = opts or {}
        local kName = opts.Name or "Keybind"
        local currentKey = opts.Default or Enum.KeyCode.RightControl
        local callback = opts.Callback or function() end
        local listening = false

        local kf = Util.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = T.SurfaceAlt,
            BorderSizePixel = 0,
            LayoutOrder = #self.Elements + 1,
            Parent = self.Content,
        })
        Util.Corner(kf)
        Util.Stroke(kf, T.Border, 1, 0.7)

        Util.Create("TextLabel", {
            Size = UDim2.new(0.6, -5, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = kName,
            TextColor3 = T.Text,
            TextSize = 12,
            Font = FONT_BODY,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = kf,
        })
        local keyBtn = Util.Create("TextButton", {
            Size = UDim2.new(0.4, -10, 0, 24),
            Position = UDim2.new(0.6, 0, 0.5, -12),
            BackgroundColor3 = T.Background,
            BorderSizePixel = 0,
            Text = currentKey.Name,
            TextColor3 = T.TextAccent,
            TextSize = 11,
            Font = FONT_MAIN,
            AutoButtonColor = false,
            Parent = kf,
        })
        Util.Corner(keyBtn)
        Util.Stroke(keyBtn, T.Accent, 1, 0.6)
        PittikUI:_TrackText(keyBtn)

        keyBtn.MouseEnter:Connect(function() Util.Tween(keyBtn, 0.15, { BackgroundColor3 = T.CardHover }) end)
        keyBtn.MouseLeave:Connect(function() Util.Tween(keyBtn, 0.15, { BackgroundColor3 = T.Background }) end)

        keyBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            PittikUI._listeningForKeybind = true
            keyBtn.Text = "..."
            keyBtn.TextColor3 = Color3.fromRGB(255, 255, 100)
            local conn
            conn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    currentKey = input.KeyCode
                    keyBtn.Text = currentKey.Name
                    keyBtn.TextColor3 = T.TextAccent
                    listening = false
                    callback(currentKey)
                    conn:Disconnect()
                    task.defer(function()
                        PittikUI._listeningForKeybind = false
                    end)
                end
            end)
        end)

        kf.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then Util.Tween(kf, 0.15, { BackgroundColor3 = T.CardHover }) end end)
        kf.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then Util.Tween(kf, 0.15, { BackgroundColor3 = T.SurfaceAlt }) end end)

        local el = { Instance = kf, Type = "Keybind", Value = currentKey }
        function el:GetKey() return currentKey end
        table.insert(self.Elements, el)
        return el
    end

    function S:AddColorPicker(opts)
        opts = opts or {}
        local cpName = opts.Name or "Color"
        local initColor = opts.Default or Color3.fromRGB(0, 255, 128)

        local cpFrame = Util.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = T.SurfaceAlt,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            LayoutOrder = #self.Elements + 1,
            Parent = self.Content,
        })
        Util.Corner(cpFrame)
        Util.Stroke(cpFrame, T.Border, 1, 0.7)

        Util.Create("TextLabel", {
            Size = UDim2.new(1, -50, 0, 32),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = cpName,
            TextColor3 = T.Text,
            TextSize = 12,
            Font = FONT_BODY,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = cpFrame,
        })

        local colorBtn = Util.Create("TextButton", {
            Size = UDim2.new(0, 26, 0, 18),
            Position = UDim2.new(1, -36, 0, 7),
            BackgroundColor3 = initColor,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 8,
            Parent = cpFrame,
        })
        Util.Corner(colorBtn, UDim.new(0, 4))
        Util.Stroke(colorBtn, T.Border, 1, 0.6)

        cpFrame.MouseEnter:Connect(function() Util.Tween(cpFrame, 0.15, { BackgroundColor3 = T.CardHover }) end)
        cpFrame.MouseLeave:Connect(function() Util.Tween(cpFrame, 0.15, { BackgroundColor3 = T.SurfaceAlt }) end)

        local picker = CreateColorPickerWidget(cpFrame, colorBtn, opts)
        table.insert(self.Elements, picker)
        return picker
    end

    table.insert(tabObj.Sections, S)
    return S
end

return PittikUI

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
    _listeningForKeybind = false,
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

-- ============================================================
-- Color3 <-> kaydedilebilir tablo dönüşümü (config için)
-- ============================================================
local function Color3ToSave(c)
    return { c.R, c.G, c.B }
end

local function Color3FromSave(v)
    if typeof(v) == "Color3" then return v end
    if type(v) == "table" and type(v[1]) == "number" then
        return Color3.new(v[1], v[2] or v[1], v[3] or v[1])
    end
    if type(v) == "string" then
        local r, g, b = v:match("#?(%x%x)(%x%x)(%x%x)")
        if r and g and b then
            return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
        end
    end
    return nil
end

-- ============================================================
-- Açılır (popup) renk paleti — Apply yok, renk anında uygulanır
-- ============================================================
local function CloseActiveColorPopup()
    if PittikUI._activeColorPopup then
        local p = PittikUI._activeColorPopup
        PittikUI._activeColorPopup = nil
        p.Close()
    end
end

function PittikUI:OpenColorPopup(anchor, startColor, onChange)
    onChange = onChange or function() end

    CloseActiveColorPopup()

    local screenGui = anchor:FindFirstAncestorOfClass("ScreenGui")
    if not screenGui then return nil end

    local hue, sat, val = Color3.toHSV(startColor or Color3.new(1, 1, 1))
    local POP_W, POP_H = 190, 150

    -- Palet açıkken dışına tıklayınca kapanması için görünmez ekran
    local catcher = Util.Create("TextButton", {
        Name = "ColorPopupCatcher",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 90,
        Parent = screenGui,
    })

    local popup = Util.Create("Frame", {
        Name = "ColorPopup",
        Size = UDim2.new(0, POP_W, 0, POP_H),
        BackgroundColor3 = T.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 100,
        Visible = false,
        AnchorPoint = Vector2.new(0.5, 0),
        Parent = screenGui,
    })
    Util.Corner(popup, UDim.new(0, 4))
    Util.Stroke(popup, T.Accent, 1, 0.45)

    -- Üst satır: hex kodu + canlı önizleme
    local hexLbl = Util.Create("TextLabel", {
        Size = UDim2.new(1, -48, 0, 16),
        Position = UDim2.new(0, 12, 0, 7),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = T.TextDim,
        TextSize = 10,
        Font = FONT_SMALL,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 101,
        Parent = popup,
    })
    local preview = Util.Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(1, -24, 0, 7),
        BackgroundColor3 = Color3.fromHSV(hue, sat, val),
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = popup,
    })
    Util.Corner(preview, UDim.new(0, 4)) -- kare
    Util.Stroke(preview, Color3.new(1, 1, 1), 1, 0.4)

    -- Doymuşluk / Parlaklık alanı
    local svField = Util.Create("Frame", {
        Size = UDim2.new(1, -16, 0, 92),
        Position = UDim2.new(0, 8, 0, 28),
        BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 101,
        Parent = popup,
    })
    Util.Corner(svField, UDim.new(0, 4))

    local whiteOv = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = svField,
    })
    Util.Corner(whiteOv, UDim.new(0, 4))
    Util.Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = whiteOv,
    })

    local blackOv = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 101,
        Parent = svField,
    })
    Util.Corner(blackOv, UDim.new(0, 4))
    Util.Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90,
        Parent = blackOv,
    })

    local svCursor = Util.Create("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(sat, -5, 1 - val, -5),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 103,
        Parent = svField,
    })
    Util.Corner(svCursor, UDim.new(0, 2)) -- kare imleç
    Util.Stroke(svCursor, Color3.new(1, 1, 1), 2, 0)

    local svBtn = Util.Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 104,
        Parent = svField,
    })

    -- Ton (hue) çubuğu
    local hueBar = Util.Create("Frame", {
        Size = UDim2.new(1, -16, 0, 14),
        Position = UDim2.new(0, 8, 0, 126),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 101,
        Parent = popup,
    })
    Util.Corner(hueBar, UDim.new(0, 4))
    Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
        Parent = hueBar,
    })

    local hueCursor = Util.Create("Frame", {
        Size = UDim2.new(0, 4, 1, 4),
        Position = UDim2.new(hue, -2, 0, -2),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 103,
        Parent = hueBar,
    })
    Util.Corner(hueCursor, UDim.new(0, 2)) -- kare imleç

    local hueBtn = Util.Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 104,
        Parent = hueBar,
    })

    local function toHex(c)
        return string.format("#%02X%02X%02X",
            math.floor(c.R * 255 + 0.5),
            math.floor(c.G * 255 + 0.5),
            math.floor(c.B * 255 + 0.5))
    end

    local function refresh()
        local c = Color3.fromHSV(hue, sat, val)
        svField.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        svCursor.Position = UDim2.new(sat, -5, 1 - val, -5)
        hueCursor.Position = UDim2.new(hue, -2, 0, -2)
        preview.BackgroundColor3 = c
        hexLbl.Text = toHex(c)
    end
    refresh()

    local svDrag, hueDrag = false, false
    local conns = {}

    local function applySV(pos)
        local p, s = svField.AbsolutePosition, svField.AbsoluteSize
        sat = math.clamp((pos.X - p.X) / s.X, 0, 1)
        val = math.clamp(1 - (pos.Y - p.Y) / s.Y, 0, 1)
        refresh()
        onChange(Color3.fromHSV(hue, sat, val)) -- ANINDA uygula
    end

    local function applyHue(pos)
        hue = math.clamp((pos.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 0.999)
        refresh()
        onChange(Color3.fromHSV(hue, sat, val)) -- ANINDA uygula
    end

    svBtn.MouseButton1Down:Connect(function()
        svDrag = true
        applySV(Vector2.new(Mouse.X, Mouse.Y))
    end)
    hueBtn.MouseButton1Down:Connect(function()
        hueDrag = true
        applyHue(Vector2.new(Mouse.X, Mouse.Y))
    end)

    table.insert(conns, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if svDrag then
                applySV(Vector2.new(input.Position.X, input.Position.Y))
            elseif hueDrag then
                applyHue(Vector2.new(input.Position.X, input.Position.Y))
            end
        end
    end))
    table.insert(conns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag, hueDrag = false, false
        end
    end))

    local closed = false
    local function close()
        if closed then return end
        closed = true
        for _, c in ipairs(conns) do c:Disconnect() end
        catcher:Destroy()
        popup:Destroy()
        if PittikUI._activeColorPopup and PittikUI._activeColorPopup.Popup == popup then
            PittikUI._activeColorPopup = nil
        end
    end

    catcher.MouseButton1Click:Connect(close)

    -- Karenin hemen altına (yer yoksa üstüne) konumlandır ve aç
    do
        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        local aPos, aSize = anchor.AbsolutePosition, anchor.AbsoluteSize

        local x = aPos.X + aSize.X - POP_W
        x = math.clamp(x, 8, math.max(8, vp.X - POP_W - 8))
        local y = aPos.Y + aSize.Y + 6
        if y + POP_H > vp.Y - 8 then
            y = aPos.Y - POP_H - 6
        end
        y = math.clamp(y, 8, math.max(8, vp.Y - POP_H - 8))

        popup.Position = UDim2.new(0, x + POP_W / 2, 0, y)
        popup.Size = UDim2.new(0, POP_W, 0, 0)
        popup.Visible = true
        Util.Tween(popup, 0.15, { Size = UDim2.new(0, POP_W, 0, POP_H) })
    end

    PittikUI._activeColorPopup = { Popup = popup, Close = close }

    return { Close = close, Popup = popup }
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

function PittikUI:CreateWindow(options)
    options = options or {}
    local title = options.Title or "PittikUI"
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

    local mainFrame = Util.Create("Frame", {
        Name = "MainFrame",
        Size = size,
        Position = UDim2.new(0.5, -(size.X.Offset / 2), 0.5, -(size.Y.Offset / 2)),
        BackgroundColor3 = T.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screenGui,
    })
    Util.Corner(mainFrame)
    Util.Stroke(mainFrame, T.Accent, 1.5, 0.2)

    -- ============================================================
    -- BAŞLIK ÇUBUĞU: Başlık + Sekmeler + Pencere butonları TEK SATIRDA
    -- (eski ayrı sekme satırı kaldırıldı -> içerik alanı büyüdü)
    -- ============================================================
    local titleBar = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = T.Surface,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    Util.Corner(titleBar)
    Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, -6),
        BackgroundColor3 = T.Surface,
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

    local titleLabel = Util.Create("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        RichText = true,
        Text = title,
        TextColor3 = T.TextAccent,
        TextSize = 16,
        Font = FONT_MAIN,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })
    PittikUI:_TrackText(titleLabel)

    -- Sekmeler: başlığın sağına dinamik olarak yerleşir
    local tabBar = Util.Create("ScrollingFrame", {
        Name = "TabBar",
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Parent = titleBar,
    })
    local tabLayout = Util.ListLayout(tabBar, 4, Enum.FillDirection.Horizontal,
        Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabBar.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + 8, 0, 0)
    end)

    local CONTROLS_RESERVE = 78 -- sağdaki pencere butonları için ayrılan alan
    local function layoutTabs()
        local tw = math.clamp(titleLabel.TextBounds.X, 24, 280)
        local startX = 14 + tw + 18
        tabBar.Position = UDim2.new(0, startX, 0, 5)
        tabBar.Size = UDim2.new(1, -(startX + CONTROLS_RESERVE), 1, -10)
    end
    titleLabel:GetPropertyChangedSignal("TextBounds"):Connect(layoutTabs)
    task.defer(layoutTabs)
    task.delay(0.1, layoutTabs)

    -- Pencere butonları (en sağda)
    local controlsFrame = Util.Create("Frame", {
        Size = UDim2.new(0, 60, 0, 38),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -6, 0, 0),
        BackgroundTransparency = 1,
        Parent = titleBar,
    })

    local minimizeBtn = Util.Create("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(0, 0, 0.5, -13),
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
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(0, 32, 0.5, -13),
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

    -- İçerik alanı: artık başlık çubuğunun hemen altında (ekstra alan kazanıldı)
    local contentArea = Util.Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -16, 1, -54),
        Position = UDim2.new(0, 8, 0, 46),
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

    Util.MakeDraggable(mainFrame, titleBar)

    local windowObj = setmetatable({
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        TitleBar = titleBar,
        TitleLabel = titleLabel,
        TabBar = tabBar,
        ContentArea = contentArea,
        Tabs = {},
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
    return windowObj
end

function Window:SetTitle(newTitle)
    self.TitleLabel.Text = newTitle
    -- TextBounds değişince sekmeler otomatik yeniden konumlanır
end

function Window:AddTab(options)
    options = options or {}
    local name = options.Name or "Tab"
    local tabIndex = #self.Tabs + 1

    local tabBtn = Util.Create("TextButton", {
        Name = "Tab_" .. name,
        Size = UDim2.new(0, 0, 0, 24),
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
        TextSize = 11,
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
    if #self.Tabs == 1 then self:_SelectTab(tabObj) end

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
    CloseActiveColorPopup()
    if self.Minimized then
        Util.Tween(self.MainFrame, 0.3, { Size = UDim2.new(0, self.MainFrame.AbsoluteSize.X, 0, 38) })
    else
        Util.Tween(self.MainFrame, 0.3, { Size = self._originalSize })
    end
end

function Window:Toggle()
    self.Visible = not self.Visible
    self.ScreenGui.Enabled = self.Visible
    if not self.Visible then CloseActiveColorPopup() end
end

function Window:Close()
    CloseActiveColorPopup()
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
        BorderSizePixel = 0,
        LayoutOrder = #tabObj.Sections + 1,
        Parent = tabObj.Page,
    })
    Util.Corner(sectionFrame)
    Util.Stroke(sectionFrame, T.Accent, 1, 0.65)

    local headerFrame = Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = T.SurfaceAlt,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = sectionFrame,
    })
    Util.Corner(headerFrame)
    Util.Create("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 1, -6),
        BackgroundColor3 = T.SurfaceAlt,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = headerFrame,
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

    -- ============================================================
    -- TOGGLE: [İsim] [kare renk kutusu] .......... [küçük aç/kapa]
    -- Renk kutusu ismin hemen sağında, aç/kapa en sağda.
    -- Satırın herhangi bir boş yerine tıklamak da toggle'lar.
    -- ============================================================
    function S:AddToggle(opts)
        opts = opts or {}
        local tName = opts.Name or "Toggle"
        local default = opts.Default or false
        local flag = opts.Flag or nil
        local callback = opts.Callback or function() end
        local state = default

        -- Renk seçici entegrasyonu: ColorPicker = true
        local hasColor = opts.ColorPicker == true or opts.ColorDefault ~= nil or opts.ColorFlag ~= nil
        local currentColor = opts.ColorDefault or Color3.fromRGB(0, 255, 128)
        local colorCallback = opts.ColorCallback or function() end
        local colorFlag = opts.ColorFlag

        local frame = Util.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = T.SurfaceAlt,
            BorderSizePixel = 0,
            LayoutOrder = #self.Elements + 1,
            Parent = self.Content,
        })
        Util.Corner(frame)
        Util.Stroke(frame, T.Border, 1, 0.7)

        local element
        local colorFlagEntry

        -- Sol taraf: isim + renk kutusu (tüm satır tıklanabilir)
        local clickBtn = Util.Create("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = frame,
        })
        Util.Padding(clickBtn, 0, 0, 0, 10)
        Util.ListLayout(clickBtn, 8, Enum.FillDirection.Horizontal,
            Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

        local nameLabel = Util.Create("TextLabel", {
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = tName,
            TextColor3 = T.Text,
            TextSize = 12,
            Font = FONT_BODY,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            Parent = clickBtn,
        })

        -- Kare renk paleti butonu (ismin hemen sağında)
        local swatch
        if hasColor then
            swatch = Util.Create("TextButton", {
                Size = UDim2.new(0, 18, 0, 18),
                BackgroundColor3 = currentColor,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = 2,
                Parent = clickBtn,
            })
            Util.Corner(swatch, UDim.new(0, 4)) -- kare
            local swStroke = Util.Stroke(swatch, Color3.new(1, 1, 1), 1, 0.55)

            swatch.MouseEnter:Connect(function()
                Util.Tween(frame, 0.15, { BackgroundColor3 = T.CardHover })
                Util.Tween(swStroke, 0.15, { Transparency = 0 })
            end)
            swatch.MouseLeave:Connect(function()
                Util.Tween(frame, 0.15, { BackgroundColor3 = T.SurfaceAlt })
                Util.Tween(swStroke, 0.15, { Transparency = 0.55 })
            end)
            swatch.MouseButton1Click:Connect(function()
                PittikUI:OpenColorPopup(swatch, currentColor, function(c)
                    currentColor = c
                    swatch.BackgroundColor3 = c
                    element.ColorValue = c
                    if colorFlagEntry then colorFlagEntry.Value = Color3ToSave(c) end
                    colorCallback(c)
                end)
            end)
        end

        -- Küçültülmüş aç/kapa düğmesi (en sağda)
        local swBg = Util.Create("TextButton", {
            Size = UDim2.new(0, 32, 0, 16),
            Position = UDim2.new(1, -40, 0.5, -8),
            BackgroundColor3 = state and T.ToggleOn or T.ToggleOff,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = frame,
        })
        Util.Corner(swBg)

        local knob = Util.Create("Frame", {
            Size = UDim2.new(0, 12, 0, 12),
            Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = swBg,
        })
        Util.Corner(knob)

        local function updateVisual()
            if state then
                Util.Tween(swBg, 0.2, { BackgroundColor3 = T.ToggleOn })
                Util.Tween(knob, 0.2, { Position = UDim2.new(1, -14, 0.5, -6) })
            else
                Util.Tween(swBg, 0.2, { BackgroundColor3 = T.ToggleOff })
                Util.Tween(knob, 0.2, { Position = UDim2.new(0, 2, 0.5, -6) })
            end
        end

        local function doToggle()
            state = not state
            element.Value = state
            updateVisual()
            callback(state)
        end

        clickBtn.MouseEnter:Connect(function() Util.Tween(frame, 0.15, { BackgroundColor3 = T.CardHover }) end)
        clickBtn.MouseLeave:Connect(function() Util.Tween(frame, 0.15, { BackgroundColor3 = T.SurfaceAlt }) end)
        clickBtn.MouseButton1Click:Connect(doToggle)

        swBg.MouseEnter:Connect(function() Util.Tween(frame, 0.15, { BackgroundColor3 = T.CardHover }) end)
        swBg.MouseLeave:Connect(function() Util.Tween(frame, 0.15, { BackgroundColor3 = T.SurfaceAlt }) end)
        swBg.MouseButton1Click:Connect(doToggle)

        table.insert(PittikUI._toggles, {
            Bg = swBg,
            GetState = function() return state end
        })

        element = { Instance = frame, Type = "Toggle", Value = state, ColorValue = hasColor and currentColor or nil }
        function element:Set(val)
            state = val
            element.Value = val
            updateVisual()
            callback(state)
        end
        function element:SetColor(c)
            if not hasColor then return end
            local nc = Color3FromSave(c)
            if not nc then return end
            currentColor = nc
            element.ColorValue = nc
            swatch.BackgroundColor3 = nc
            if colorFlagEntry then colorFlagEntry.Value = Color3ToSave(nc) end
            colorCallback(nc)
        end
        function element:GetColor() return currentColor end
        if flag then element.Flag = flag; PittikUI.Flags[flag] = element end
        if hasColor and colorFlag then
            colorFlagEntry = { Value = Color3ToSave(currentColor), Set = function(v) element:SetColor(v) end }
            PittikUI.Flags[colorFlag] = colorFlagEntry
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
        local callback = opts.Callback or function() end
        local flag = opts.Flag
        local currentColor = opts.Default or Color3.fromRGB(0, 255, 128)

        local cpFrame = Util.Create("Frame", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = T.SurfaceAlt,
            BorderSizePixel = 0,
            LayoutOrder = #self.Elements + 1,
            Parent = self.Content,
        })
        Util.Corner(cpFrame)
        Util.Stroke(cpFrame, T.Border, 1, 0.7)

        Util.Create("TextLabel", {
            Size = UDim2.new(1, -52, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = cpName,
            TextColor3 = T.Text,
            TextSize = 12,
            Font = FONT_BODY,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = cpFrame,
        })

        local element
        local flagEntry

        local swatch = Util.Create("TextButton", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -30, 0.5, -10),
            BackgroundColor3 = currentColor,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = cpFrame,
        })
        Util.Corner(swatch, UDim.new(0, 4)) -- kare
        local swStroke = Util.Stroke(swatch, Color3.new(1, 1, 1), 1, 0.6)

        swatch.MouseEnter:Connect(function()
            Util.Tween(cpFrame, 0.15, { BackgroundColor3 = T.CardHover })
            Util.Tween(swStroke, 0.15, { Transparency = 0.15 })
        end)
        swatch.MouseLeave:Connect(function()
            Util.Tween(cpFrame, 0.15, { BackgroundColor3 = T.SurfaceAlt })
            Util.Tween(swStroke, 0.15, { Transparency = 0.6 })
        end)

        local function toHex(c)
            return string.format("#%02X%02X%02X",
                math.floor(c.R * 255 + 0.5),
                math.floor(c.G * 255 + 0.5),
                math.floor(c.B * 255 + 0.5))
        end

        swatch.MouseButton1Click:Connect(function()
            PittikUI:OpenColorPopup(swatch, currentColor, function(c)
                currentColor = c
                swatch.BackgroundColor3 = c
                if element then element.Value = c end
                if flagEntry then flagEntry.Value = Color3ToSave(c) end
                callback(c, toHex(c))
            end)
        end)

        element = { Instance = cpFrame, Type = "ColorPicker", Value = currentColor }
        function element:Set(c)
            local nc = Color3FromSave(c)
            if not nc then return end
            currentColor = nc
            element.Value = nc
            swatch.BackgroundColor3 = nc
            if flagEntry then flagEntry.Value = Color3ToSave(nc) end
            callback(nc, toHex(nc))
        end
        element.SetColor = element.Set
        function element:GetColor() return currentColor end
        if flag then
            flagEntry = { Value = Color3ToSave(currentColor), Set = function(v) element:Set(v) end }
            PittikUI.Flags[flag] = flagEntry
        end
        table.insert(self.Elements, element)
        return element
    end

    table.insert(tabObj.Sections, S)
    return S
end

return PittikUI

--[[
    ============================================================
    NEER FLOW â€” UI SHELL (DESIGN ONLY)
    ============================================================
    Script ini HANYA berisi kerangka tampilan (GUI shell).
    Tidak ada logic fitur/game yang dihubungkan â€” semua tombol,
    dropdown, dan section di sini murni visual/placeholder.

    Fitur yang sudah tersedia:
      - Desain modern, dark theme, neon accent, rounded + smooth
      - Draggable (mouse & touch)
      - Resizable (drag dari pojok kanan-bawah)
      - Responsive terhadap ukuran layar (mobile & PC)
      - Minimize -> jadi small floating icon ("Diamond Core")
      - Close -> munculkan popup konfirmasi "Yakin ingin keluar?"
      - Sidebar navigasi + collapsible section + search dropdown

    Cara pakai: jalankan sebagai LocalScript (StarterPlayerScripts)
    atau lewat executor. Untuk menambah fitur asli, cari komentar
    "-- [HOOK]" di bagian bawah tiap tombol.
    ============================================================
]]

-- ================= SERVICES =================
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local Camera              = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- Bersihkan instance lama kalau script di-run ulang
local old = PlayerGui:FindFirstChild("NeerFlow_UI")
if old then old:Destroy() end

-- ================= THEME =================
local Theme = {
    Background      = Color3.fromRGB(13, 15, 20),
    Panel           = Color3.fromRGB(19, 21, 28),
    PanelLight      = Color3.fromRGB(27, 30, 39),
    Accent          = Color3.fromRGB(130, 97, 255),
    AccentSoft      = Color3.fromRGB(96, 200, 255),
    Text            = Color3.fromRGB(236, 236, 242),
    SubText         = Color3.fromRGB(146, 150, 163),
    Stroke          = Color3.fromRGB(48, 51, 63),
    Danger          = Color3.fromRGB(235, 84, 84),
    Success         = Color3.fromRGB(83, 214, 148),
}

-- ================= UTILITIES =================
local function Tween(obj, duration, props, style, dir)
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function Round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0, 10)
    c.Parent = obj
    return c
end

local function Stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function Pad(obj, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = obj
    return p
end

local function Gradient(obj, seq, rotation)
    local g = Instance.new("UIGradient")
    g.Color = seq
    g.Rotation = rotation or 0
    g.Parent = obj
    return g
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Drag support (mouse & touch)
local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos, dragInput

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Resize support (drag pojok kanan-bawah)
local function MakeResizable(handle, target, minSize, maxSize)
    local resizing, startPos, startSize

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            startPos = input.Position
            startSize = target.Size
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startPos
            local w = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxSize.X)
            local h = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
            target.Size = UDim2.new(0, w, 0, h)
        end
    end)
end

-- ================= ROOT GUI =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NeerFlow_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.Parent = PlayerGui

-- ================= MAIN WINDOW =================
local function GetIdealSize()
    local vp = Camera.ViewportSize
    local w = math.clamp(vp.X * 0.86, 340, 820)
    local h = math.clamp(vp.Y * 0.82, 380, 580)
    return UDim2.new(0, w, 0, h)
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = GetIdealSize()
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BackgroundTransparency = 0.03
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui
Round(MainFrame, UDim.new(0, 16))
Stroke(MainFrame, Theme.Stroke, 1, 0.25)

local MainScale = Instance.new("UIScale")
MainScale.Scale = IsMobile() and 0.9 or 1
MainScale.Parent = MainFrame

-- Body (semua konten yang perlu di-clip)
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.BackgroundTransparency = 1
Body.Size = UDim2.new(1, 0, 1, 0)
Body.ClipsDescendants = true
Body.Parent = MainFrame
Round(Body, UDim.new(0, 16))

-- ===== Title Bar =====
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.BackgroundColor3 = Theme.Panel
TitleBar.BackgroundTransparency = 0.1
TitleBar.Size = UDim2.new(1, 0, 0, 52)
TitleBar.Parent = Body

local TitleAccent = Instance.new("Frame")
TitleAccent.BackgroundColor3 = Theme.Accent
TitleAccent.BorderSizePixel = 0
TitleAccent.Size = UDim2.new(1, 0, 0, 2)
TitleAccent.AnchorPoint = Vector2.new(0, 1)
TitleAccent.Position = UDim2.new(0, 0, 1, 0)
TitleAccent.Parent = TitleBar
Gradient(TitleAccent, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(0.5, Theme.AccentSoft),
    ColorSequenceKeypoint.new(1, Theme.Accent),
}))

local DragZone = Instance.new("Frame")
DragZone.Name = "DragZone"
DragZone.BackgroundTransparency = 1
DragZone.Size = UDim2.new(1, -84, 1, 0)
DragZone.Parent = TitleBar

local IconHolder = Instance.new("Frame")
IconHolder.BackgroundColor3 = Theme.Accent
IconHolder.Size = UDim2.new(0, 30, 0, 30)
IconHolder.Position = UDim2.new(0, 14, 0.5, 0)
IconHolder.AnchorPoint = Vector2.new(0, 0.5)
IconHolder.Parent = DragZone
Round(IconHolder, UDim.new(0, 9))
Gradient(IconHolder, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(1, Theme.AccentSoft),
}), 90)

local IconGlyph = Instance.new("TextLabel")
IconGlyph.BackgroundTransparency = 1
IconGlyph.Text = "N"
IconGlyph.Font = Enum.Font.GothamBlack
IconGlyph.TextSize = 16
IconGlyph.TextColor3 = Color3.new(1, 1, 1)
IconGlyph.Size = UDim2.new(1, 0, 1, 0)
IconGlyph.Parent = IconHolder

local TitleLabel = Instance.new("TextLabel")
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "NEER FLOW"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextColor3 = Theme.Text
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Position = UDim2.new(0, 56, 0, 8)
TitleLabel.Size = UDim2.new(0, 220, 0, 18)
TitleLabel.Parent = DragZone

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text = "UI Shell  |  v1.0.0"
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.TextSize = 11
SubtitleLabel.TextColor3 = Theme.SubText
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.Position = UDim2.new(0, 56, 0, 26)
SubtitleLabel.Size = UDim2.new(0, 220, 0, 14)
SubtitleLabel.Parent = DragZone

-- Tombol Minimize & Close
local function CreateWindowBtn(icon, hoverColor)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 30, 0, 30)
    Btn.BackgroundColor3 = Theme.PanelLight
    Btn.AutoButtonColor = false
    Btn.Text = icon
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14
    Btn.TextColor3 = Theme.SubText
    Btn.Parent = TitleBar
    Round(Btn, UDim.new(0, 8))
    Btn.MouseEnter:Connect(function()
        Tween(Btn, 0.15, {BackgroundColor3 = hoverColor, TextColor3 = Color3.new(1, 1, 1)})
    end)
    Btn.MouseLeave:Connect(function()
        Tween(Btn, 0.15, {BackgroundColor3 = Theme.PanelLight, TextColor3 = Theme.SubText})
    end)
    return Btn
end

local CloseBtn = CreateWindowBtn("Ã—", Theme.Danger)
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.Position = UDim2.new(1, -12, 0.5, 0)

local MinimizeBtn = CreateWindowBtn("â€“", Theme.Accent)
MinimizeBtn.AnchorPoint = Vector2.new(1, 0.5)
MinimizeBtn.Position = UDim2.new(1, -50, 0.5, 0)

-- ===== Sidebar =====
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.BackgroundColor3 = Theme.Panel
Sidebar.BackgroundTransparency = 0.2
Sidebar.Position = UDim2.new(0, 0, 0, 52)
Sidebar.Size = UDim2.new(0.3, 0, 1, -52)
Sidebar.Parent = Body

Pad(Sidebar, 12, 12, 16, 12)

local NavHeader = Instance.new("TextLabel")
NavHeader.BackgroundTransparency = 1
NavHeader.Text = "NAVIGATION"
NavHeader.Font = Enum.Font.GothamBold
NavHeader.TextSize = 11
NavHeader.TextColor3 = Theme.SubText
NavHeader.TextXAlignment = Enum.TextXAlignment.Left
NavHeader.Size = UDim2.new(1, 0, 0, 16)
NavHeader.Parent = Sidebar

local NavList = Instance.new("Frame")
NavList.BackgroundTransparency = 1
NavList.Position = UDim2.new(0, 0, 0, 26)
NavList.Size = UDim2.new(1, 0, 1, -70)
NavList.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 6)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavList

local NavItems = {
    {Name = "Automatic", Icon = "âŸ³"},
    {Name = "Shop", Icon = "$"},
    {Name = "Teleport", Icon = "â—Ž"},
    {Name = "Fishing Spot", Icon = "âš“"},
    {Name = "Events", Icon = "âš¡"},
    {Name = "Misc", Icon = "âš™"},
}

local navButtons = {}

local function SelectNav(name)
    for _, data in pairs(navButtons) do
        local active = data.Name == name
        Tween(data.Btn, 0.15, {
            BackgroundColor3 = active and Theme.Accent or Theme.PanelLight,
            BackgroundTransparency = active and 0 or 1,
        })
        Tween(data.Label, 0.15, {TextColor3 = active and Color3.new(1, 1, 1) or Theme.SubText})
    end
end

for i, item in ipairs(NavItems) do
    local Btn = Instance.new("TextButton")
    Btn.Name = item.Name
    Btn.LayoutOrder = i
    Btn.Size = UDim2.new(1, 0, 0, 38)
    Btn.BackgroundColor3 = Theme.PanelLight
    Btn.BackgroundTransparency = 1
    Btn.AutoButtonColor = false
    Btn.Text = ""
    Btn.Parent = NavList
    Round(Btn, UDim.new(0, 9))
    Pad(Btn, 12, 8, 0, 0)

    local IconLbl = Instance.new("TextLabel")
    IconLbl.BackgroundTransparency = 1
    IconLbl.Text = item.Icon
    IconLbl.Font = Enum.Font.GothamBold
    IconLbl.TextSize = 14
    IconLbl.TextColor3 = Theme.SubText
    IconLbl.Size = UDim2.new(0, 20, 1, 0)
    IconLbl.Parent = Btn

    local Lbl = Instance.new("TextLabel")
    Lbl.BackgroundTransparency = 1
    Lbl.Text = item.Name
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextSize = 13
    Lbl.TextColor3 = Theme.SubText
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Position = UDim2.new(0, 26, 0, 0)
    Lbl.Size = UDim2.new(1, -26, 1, 0)
    Lbl.Parent = Btn

    navButtons[item.Name] = {Btn = Btn, Label = Lbl}

    Btn.MouseButton1Click:Connect(function()
        SelectNav(item.Name)
        -- [HOOK] tampilkan Content tab sesuai item.Name di sini
    end)
end

-- Baris "NeeR" bawah sidebar (mirip screenshot)
local NeeRRow = Instance.new("Frame")
NeeRRow.BackgroundColor3 = Theme.PanelLight
NeeRRow.Position = UDim2.new(0, 0, 1, -46)
NeeRRow.Size = UDim2.new(1, 0, 0, 46)
NeeRRow.Parent = Sidebar
Round(NeeRRow, UDim.new(0, 9))
Pad(NeeRRow, 10, 10, 0, 0)

local NeeRAvatar = Instance.new("Frame")
NeeRAvatar.BackgroundColor3 = Theme.Accent
NeeRAvatar.Size = UDim2.new(0, 26, 0, 26)
NeeRAvatar.AnchorPoint = Vector2.new(0, 0.5)
NeeRAvatar.Position = UDim2.new(0, 0, 0.5, 0)
NeeRAvatar.Parent = NeeRRow
Round(NeeRAvatar, UDim.new(1, 0))

local NeeRLabel = Instance.new("TextLabel")
NeeRLabel.BackgroundTransparency = 1
NeeRLabel.Text = "NeeR"
NeeRLabel.Font = Enum.Font.GothamMedium
NeeRLabel.TextSize = 13
NeeRLabel.TextColor3 = Theme.Text
NeeRLabel.TextXAlignment = Enum.TextXAlignment.Left
NeeRLabel.Position = UDim2.new(0, 36, 0, 0)
NeeRLabel.Size = UDim2.new(1, -70, 1, 0)
NeeRLabel.Parent = NeeRRow

local NeeRGear = Instance.new("TextButton")
NeeRGear.BackgroundTransparency = 1
NeeRGear.Text = "âš™"
NeeRGear.Font = Enum.Font.GothamBold
NeeRGear.TextSize = 15
NeeRGear.TextColor3 = Theme.SubText
NeeRGear.AnchorPoint = Vector2.new(1, 0.5)
NeeRGear.Position = UDim2.new(1, 0, 0.5, 0)
NeeRGear.Size = UDim2.new(0, 24, 0, 24)
NeeRGear.Parent = NeeRRow

-- ===== Content Area =====
local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0.3, 12, 0, 52)
Content.Size = UDim2.new(0.7, -24, 1, -64)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = Theme.Accent
Content.BorderSizePixel = 0
Content.Parent = Body

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 12)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

-- Section builder (collapsible card, mirip di screenshot)
local function CreateSection(order, title, expanded)
    local Section = Instance.new("Frame")
    Section.LayoutOrder = order
    Section.BackgroundColor3 = Theme.Panel
    Section.BackgroundTransparency = 0.15
    Section.Size = UDim2.new(1, 0, 0, 46)
    Section.AutomaticSize = Enum.AutomaticSize.Y
    Section.ClipsDescendants = true
    Section.Parent = Content
    Round(Section, UDim.new(0, 12))
    Stroke(Section, Theme.Stroke, 1, 0.4)

    local Header = Instance.new("TextButton")
    Header.BackgroundTransparency = 1
    Header.Size = UDim2.new(1, 0, 0, 46)
    Header.Text = ""
    Header.AutoButtonColor = false
    Header.Parent = Section
    Pad(Header, 16, 16, 0, 0)

    local Dot = Instance.new("Frame")
    Dot.BackgroundColor3 = Theme.Accent
    Dot.Size = UDim2.new(0, 6, 0, 6)
    Dot.AnchorPoint = Vector2.new(0, 0.5)
    Dot.Position = UDim2.new(0, 0, 0.5, 0)
    Dot.Parent = Header
    Round(Dot, UDim.new(1, 0))

    local HeaderText = Instance.new("TextLabel")
    HeaderText.BackgroundTransparency = 1
    HeaderText.Text = title
    HeaderText.Font = Enum.Font.GothamBold
    HeaderText.TextSize = 12
    HeaderText.TextColor3 = Theme.SubText
    HeaderText.TextXAlignment = Enum.TextXAlignment.Left
    HeaderText.Position = UDim2.new(0, 16, 0, 0)
    HeaderText.Size = UDim2.new(1, -40, 1, 0)
    HeaderText.Parent = Header

    local Chevron = Instance.new("TextLabel")
    Chevron.BackgroundTransparency = 1
    Chevron.Text = "â–¾"
    Chevron.Font = Enum.Font.GothamBold
    Chevron.TextSize = 13
    Chevron.TextColor3 = Theme.SubText
    Chevron.AnchorPoint = Vector2.new(1, 0.5)
    Chevron.Position = UDim2.new(1, 0, 0.5, 0)
    Chevron.Size = UDim2.new(0, 18, 1, 0)
    Chevron.Rotation = expanded and 0 or -90
    Chevron.Parent = Header

    local Inner = Instance.new("Frame")
    Inner.BackgroundTransparency = 1
    Inner.Position = UDim2.new(0, 16, 0, 46)
    Inner.Size = UDim2.new(1, -32, 0, 0)
    Inner.AutomaticSize = Enum.AutomaticSize.Y
    Inner.Visible = expanded
    Inner.Parent = Section

    local InnerLayout = Instance.new("UIListLayout")
    InnerLayout.Padding = UDim.new(0, 12)
    InnerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    InnerLayout.Parent = Inner
    Pad(Inner, 0, 0, 2, 16)

    local isOpen = expanded
    Header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        Inner.Visible = isOpen
        Tween(Chevron, 0.2, {Rotation = isOpen and 0 or -90})
    end)

    return Inner
end

-- Row helper (label kiri + control kanan)
local function CreateRow(parent, order, label)
    local Row = Instance.new("Frame")
    Row.LayoutOrder = order
    Row.BackgroundTransparency = 1
    Row.Size = UDim2.new(1, 0, 0, 32)
    Row.Parent = parent

    local Lbl = Instance.new("TextLabel")
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextSize = 13
    Lbl.TextColor3 = Theme.Text
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Size = UDim2.new(0.45, 0, 1, 0)
    Lbl.Parent = Row

    local Control = Instance.new("Frame")
    Control.BackgroundTransparency = 1
    Control.AnchorPoint = Vector2.new(1, 0.5)
    Control.Position = UDim2.new(1, 0, 0.5, 0)
    Control.Size = UDim2.new(0.55, 0, 0, 30)
    Control.Parent = Row

    return Control
end

-- Tombol neon (Execute, dsb)
local function CreateNeonBtn(parent, text, primary)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 100, 0, 30)
    Btn.AnchorPoint = Vector2.new(1, 0.5)
    Btn.Position = UDim2.new(1, 0, 0.5, 0)
    Btn.BackgroundColor3 = primary and Theme.Accent or Theme.PanelLight
    Btn.AutoButtonColor = false
    Btn.Text = text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 12
    Btn.TextColor3 = primary and Color3.new(1, 1, 1) or Theme.Text
    Btn.Parent = parent
    Round(Btn, UDim.new(0, 8))
    Stroke(Btn, primary and Theme.AccentSoft or Theme.Stroke, 1, primary and 0.3 or 0.5)

    Btn.MouseEnter:Connect(function()
        Tween(Btn, 0.15, {BackgroundColor3 = primary and Theme.AccentSoft or Theme.Stroke})
    end)
    Btn.MouseLeave:Connect(function()
        Tween(Btn, 0.15, {BackgroundColor3 = primary and Theme.Accent or Theme.PanelLight})
    end)
    return Btn
end

-- Tombol select/dropdown (mis. "Fishing Village â–¾")
local function CreateSelectBtn(parent, defaultText, arrowIcon)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundColor3 = Theme.PanelLight
    Btn.AutoButtonColor = false
    Btn.Text = ""
    Btn.Parent = parent
    Round(Btn, UDim.new(0, 8))
    Stroke(Btn, Theme.Stroke, 1, 0.4)
    Pad(Btn, 12, 10, 0, 0)

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Text = defaultText
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -20, 1, 0)
    Label.Parent = Btn

    local Chevron = Instance.new("TextLabel")
    Chevron.BackgroundTransparency = 1
    Chevron.Text = arrowIcon or "â–¾"
    Chevron.Font = Enum.Font.GothamBold
    Chevron.TextSize = 12
    Chevron.TextColor3 = Theme.SubText
    Chevron.AnchorPoint = Vector2.new(1, 0.5)
    Chevron.Position = UDim2.new(1, 0, 0.5, 0)
    Chevron.Size = UDim2.new(0, 16, 1, 0)
    Chevron.Parent = Btn

    return Btn, Label
end

-- ===== Isi Section (placeholder visual, sesuai screenshot) =====
local IslandsInner = CreateSection(1, "ISLANDS TELEPORT", true)
local selectIslandControl = CreateRow(IslandsInner, 1, "Select Island")
local IslandSelectBtn, IslandSelectLabel = CreateSelectBtn(selectIslandControl, "Fishing Village")

local teleportControl = CreateRow(IslandsInner, 2, "Teleport to Island")
local ExecuteBtn = CreateNeonBtn(teleportControl, "EXECUTE", true)
-- [HOOK] ExecuteBtn.MouseButton1Click:Connect(function() end)

CreateSection(2, "NPCS & MERCHANT TELEPORT", false)

local PlayerInner = CreateSection(3, "PLAYER TELEPORT", true)
local selectPlayerControl = CreateRow(PlayerInner, 1, "Select Player")
local PlayerSelectBtn, PlayerSelectLabel = CreateSelectBtn(selectPlayerControl, "Select Player...", "â–¸")

-- ===== Footer =====
local Footer = Instance.new("Frame")
Footer.BackgroundColor3 = Theme.Panel
Footer.BackgroundTransparency = 0.1
Footer.Position = UDim2.new(0, 0, 1, -12)
Footer.AnchorPoint = Vector2.new(0, 1)
Footer.Size = UDim2.new(1, 0, 0, 26)
Footer.Parent = Body

local FooterStatus = Instance.new("TextLabel")
FooterStatus.BackgroundTransparency = 1
FooterStatus.Text = "â—  NEER FLOW UI"
FooterStatus.Font = Enum.Font.Gotham
FooterStatus.TextSize = 11
FooterStatus.TextColor3 = Theme.Success
FooterStatus.TextXAlignment = Enum.TextXAlignment.Left
FooterStatus.Position = UDim2.new(0, 14, 0, 0)
FooterStatus.Size = UDim2.new(0, 200, 1, 0)
FooterStatus.Parent = Footer

local FooterVersion = Instance.new("TextLabel")
FooterVersion.BackgroundTransparency = 1
FooterVersion.Text = "NeeR Flow UI Â© 2026"
FooterVersion.Font = Enum.Font.Gotham
FooterVersion.TextSize = 11
FooterVersion.TextColor3 = Theme.SubText
FooterVersion.TextXAlignment = Enum.TextXAlignment.Right
FooterVersion.AnchorPoint = Vector2.new(1, 0)
FooterVersion.Position = UDim2.new(1, -14, 0, 0)
FooterVersion.Size = UDim2.new(0, 200, 1, 0)
FooterVersion.Parent = Footer

-- ===== Resize Handle =====
local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Text = "â‹°"
ResizeHandle.Font = Enum.Font.GothamBold
ResizeHandle.TextSize = 14
ResizeHandle.Rotation = 45
ResizeHandle.TextColor3 = Theme.SubText
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.AutoButtonColor = false
ResizeHandle.AnchorPoint = Vector2.new(1, 1)
ResizeHandle.Position = UDim2.new(1, -4, 1, -4)
ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
ResizeHandle.ZIndex = 5
ResizeHandle.Parent = MainFrame

-- ===== Search Dropdown Panel (mengikuti MainFrame, muncul di sisi kanan) =====
local SearchPanel = Instance.new("Frame")
SearchPanel.Name = "SearchPanel"
SearchPanel.BackgroundColor3 = Theme.Background
SearchPanel.BackgroundTransparency = 0.03
SearchPanel.Position = UDim2.new(1, 16, 0, 52)
SearchPanel.Size = UDim2.new(0, 220, 0, 340)
SearchPanel.Visible = false
SearchPanel.ZIndex = 10
SearchPanel.Parent = MainFrame
Round(SearchPanel, UDim.new(0, 14))
Stroke(SearchPanel, Theme.Stroke, 1, 0.25)
Pad(SearchPanel, 10, 10, 10, 10)

local SearchBox = Instance.new("TextBox")
SearchBox.BackgroundColor3 = Theme.PanelLight
SearchBox.PlaceholderText = "Search..."
SearchBox.Text = ""
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.TextColor3 = Theme.Text
SearchBox.PlaceholderColor3 = Theme.SubText
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Size = UDim2.new(1, 0, 0, 32)
SearchBox.ZIndex = 11
SearchBox.Parent = SearchPanel
Round(SearchBox, UDim.new(0, 8))
Pad(SearchBox, 10, 10, 0, 0)

local SearchList = Instance.new("ScrollingFrame")
SearchList.BackgroundTransparency = 1
SearchList.Position = UDim2.new(0, 0, 0, 40)
SearchList.Size = UDim2.new(1, 0, 1, -40)
SearchList.CanvasSize = UDim2.new(0, 0, 0, 0)
SearchList.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
SearchList.ScrollBarThickness = 3
SearchList.ScrollBarImageColor3 = Theme.Accent
SearchList.BorderSizePixel = 0
SearchList.ZIndex = 11
SearchList.Parent = SearchPanel

local SearchListLayout = Instance.new("UIListLayout")
SearchListLayout.Padding = UDim.new(0, 4)
SearchListLayout.SortOrder = Enum.SortOrder.LayoutOrder
SearchListLayout.Parent = SearchList

local IslandOptions = {
    "Fishing Village", "Bamboo Island", "Bora Reef", "Mystic Mangrove",
    "Lost Whale Island", "Iceberg", "Seabreeze Island", "Volcano",
    "Crimson Lava", "Dragon Island", "Emerald Island", "Ancient Abyss",
}

local function CreateListItem(order, text, selected)
    local Item = Instance.new("TextButton")
    Item.LayoutOrder = order
    Item.BackgroundColor3 = Theme.PanelLight
    Item.BackgroundTransparency = selected and 0 or 1
    Item.AutoButtonColor = false
    Item.Text = ""
    Item.Size = UDim2.new(1, 0, 0, 32)
    Item.ZIndex = 11
    Item.Parent = SearchList
    Round(Item, UDim.new(0, 7))
    Pad(Item, 10, 10, 0, 0)

    local Lbl = Instance.new("TextLabel")
    Lbl.BackgroundTransparency = 1
    Lbl.Text = text
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 13
    Lbl.TextColor3 = selected and Theme.AccentSoft or Theme.Text
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Size = UDim2.new(1, -20, 1, 0)
    Lbl.ZIndex = 11
    Lbl.Parent = Item

    local Check = Instance.new("TextLabel")
    Check.BackgroundTransparency = 1
    Check.Text = selected and "âœ“" or ""
    Check.Font = Enum.Font.GothamBold
    Check.TextSize = 13
    Check.TextColor3 = Theme.AccentSoft
    Check.AnchorPoint = Vector2.new(1, 0.5)
    Check.Position = UDim2.new(1, 0, 0.5, 0)
    Check.Size = UDim2.new(0, 16, 1, 0)
    Check.ZIndex = 11
    Check.Parent = Item

    Item.MouseEnter:Connect(function()
        if not selected then Tween(Item, 0.12, {BackgroundTransparency = 0.5}) end
    end)
    Item.MouseLeave:Connect(function()
        if not selected then Tween(Item, 0.12, {BackgroundTransparency = 1}) end
    end)

    Item.MouseButton1Click:Connect(function()
        IslandSelectLabel.Text = text
        SearchPanel.Visible = false
        -- [HOOK] simpan pilihan island di sini
    end)

    return Item
end

for i, name in ipairs(IslandOptions) do
    CreateListItem(i, name, name == "Fishing Village")
end

-- Click-outside untuk menutup SearchPanel
local ClickCatcher = Instance.new("TextButton")
ClickCatcher.BackgroundTransparency = 1
ClickCatcher.Text = ""
ClickCatcher.AutoButtonColor = false
ClickCatcher.Size = UDim2.new(1, 0, 1, 0)
ClickCatcher.Visible = false
ClickCatcher.ZIndex = 9
ClickCatcher.Parent = ScreenGui

ClickCatcher.MouseButton1Click:Connect(function()
    SearchPanel.Visible = false
    ClickCatcher.Visible = false
end)

IslandSelectBtn.MouseButton1Click:Connect(function()
    SearchPanel.Visible = not SearchPanel.Visible
    ClickCatcher.Visible = SearchPanel.Visible
end)

-- ================= MINIMIZED ICON (Diamond Core) =================
local MinIcon = Instance.new("TextButton")
MinIcon.Name = "DiamondCore"
MinIcon.AnchorPoint = Vector2.new(0.5, 0.5)
MinIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
MinIcon.Size = UDim2.new(0, 52, 0, 52)
MinIcon.BackgroundColor3 = Theme.Accent
MinIcon.AutoButtonColor = false
MinIcon.Text = ""
MinIcon.Visible = false
MinIcon.Parent = ScreenGui
Round(MinIcon, UDim.new(1, 0))
Stroke(MinIcon, Theme.AccentSoft, 1.5, 0.2)
Gradient(MinIcon, ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Accent),
    ColorSequenceKeypoint.new(1, Theme.AccentSoft),
}), 90)

local MinGlyph = Instance.new("TextLabel")
MinGlyph.BackgroundTransparency = 1
MinGlyph.Text = "N"
MinGlyph.Font = Enum.Font.GothamBlack
MinGlyph.TextSize = 20
MinGlyph.TextColor3 = Color3.new(1, 1, 1)
MinGlyph.Size = UDim2.new(1, 0, 1, 0)
MinGlyph.Parent = MinIcon

MakeDraggable(MinIcon, MinIcon)

-- Pulsing glow loop
task.spawn(function()
    while MinIcon.Parent do
        if MinIcon.Visible then
            Tween(MinIcon, 1, {Size = UDim2.new(0, 56, 0, 56)}, Enum.EasingStyle.Sine)
            task.wait(1)
            Tween(MinIcon, 1, {Size = UDim2.new(0, 52, 0, 52)}, Enum.EasingStyle.Sine)
            task.wait(1)
        else
            task.wait(0.3)
        end
    end
end)

-- ================= CLOSE CONFIRMATION MODAL =================
local Overlay = Instance.new("Frame")
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 1
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.Visible = false
Overlay.ZIndex = 20
Overlay.Parent = ScreenGui

local ConfirmCard = Instance.new("Frame")
ConfirmCard.AnchorPoint = Vector2.new(0.5, 0.5)
ConfirmCard.Position = UDim2.new(0.5, 0, 0.5, 0)
ConfirmCard.Size = UDim2.new(0, 300, 0, 160)
ConfirmCard.BackgroundColor3 = Theme.Background
ConfirmCard.ZIndex = 21
ConfirmCard.Parent = Overlay
Round(ConfirmCard, UDim.new(0, 14))
Stroke(ConfirmCard, Theme.Stroke, 1, 0.2)
Pad(ConfirmCard, 20, 20, 18, 16)

local ConfirmScale = Instance.new("UIScale")
ConfirmScale.Scale = 0.85
ConfirmScale.Parent = ConfirmCard

local ConfirmTitle = Instance.new("TextLabel")
ConfirmTitle.BackgroundTransparency = 1
ConfirmTitle.Text = "Konfirmasi Keluar"
ConfirmTitle.Font = Enum.Font.GothamBold
ConfirmTitle.TextSize = 16
ConfirmTitle.TextColor3 = Theme.Text
ConfirmTitle.TextXAlignment = Enum.TextXAlignment.Left
ConfirmTitle.Size = UDim2.new(1, 0, 0, 22)
ConfirmTitle.ZIndex = 21
ConfirmTitle.Parent = ConfirmCard

local ConfirmDesc = Instance.new("TextLabel")
ConfirmDesc.BackgroundTransparency = 1
ConfirmDesc.Text = "Yakin ingin keluar dari NeeR Flow?"
ConfirmDesc.Font = Enum.Font.Gotham
ConfirmDesc.TextSize = 13
ConfirmDesc.TextColor3 = Theme.SubText
ConfirmDesc.TextWrapped = true
ConfirmDesc.TextXAlignment = Enum.TextXAlignment.Left
ConfirmDesc.Position = UDim2.new(0, 0, 0, 28)
ConfirmDesc.Size = UDim2.new(1, 0, 0, 40)
ConfirmDesc.ZIndex = 21
ConfirmDesc.Parent = ConfirmCard

local CancelBtn = Instance.new("TextButton")
CancelBtn.Text = "Batal"
CancelBtn.Font = Enum.Font.GothamBold
CancelBtn.TextSize = 13
CancelBtn.TextColor3 = Theme.Text
CancelBtn.BackgroundColor3 = Theme.PanelLight
CancelBtn.AutoButtonColor = false
CancelBtn.AnchorPoint = Vector2.new(0, 1)
CancelBtn.Position = UDim2.new(0, 0, 1, 0)
CancelBtn.Size = UDim2.new(0.47, 0, 0, 36)
CancelBtn.ZIndex = 21
CancelBtn.Parent = ConfirmCard
Round(CancelBtn, UDim.new(0, 9))

local ConfirmBtn = Instance.new("TextButton")
ConfirmBtn.Text = "Ya, Keluar"
ConfirmBtn.Font = Enum.Font.GothamBold
ConfirmBtn.TextSize = 13
ConfirmBtn.TextColor3 = Color3.new(1, 1, 1)
ConfirmBtn.BackgroundColor3 = Theme.Danger
ConfirmBtn.AutoButtonColor = false
ConfirmBtn.AnchorPoint = Vector2.new(1, 1)
ConfirmBtn.Position = UDim2.new(1, 0, 1, 0)
ConfirmBtn.Size = UDim2.new(0.47, 0, 0, 36)
ConfirmBtn.ZIndex = 21
ConfirmBtn.Parent = ConfirmCard
Round(ConfirmBtn, UDim.new(0, 9))

-- ================= STATE / ANIMASI =================
local isMinimized = false

local function OpenModal()
    Overlay.Visible = true
    Tween(Overlay, 0.2, {BackgroundTransparency = 0.45})
    Tween(ConfirmScale, 0.22, {Scale = 1}, Enum.EasingStyle.Back)
end

local function CloseModal()
    Tween(Overlay, 0.18, {BackgroundTransparency = 1})
    Tween(ConfirmScale, 0.18, {Scale = 0.85})
    task.delay(0.18, function()
        Overlay.Visible = false
    end)
end

CloseBtn.MouseButton1Click:Connect(OpenModal)
CancelBtn.MouseButton1Click:Connect(CloseModal)

ConfirmBtn.MouseButton1Click:Connect(function()
    Tween(MainScale, 0.2, {Scale = 0.85})
    Tween(MainFrame, 0.2, {BackgroundTransparency = 1})
    Tween(Overlay, 0.2, {BackgroundTransparency = 1})
    MinIcon.Visible = false
    task.delay(0.22, function()
        ScreenGui:Destroy()
    end)
end)

local function Minimize()
    isMinimized = true
    Tween(MainScale, 0.22, {Scale = 0.4}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    Tween(MainFrame, 0.22, {BackgroundTransparency = 1})
    task.delay(0.2, function()
        MainFrame.Visible = false
        MinIcon.Visible = true
        MinIcon.Size = UDim2.new(0, 10, 0, 10)
        Tween(MinIcon, 0.25, {Size = UDim2.new(0, 52, 0, 52)}, Enum.EasingStyle.Back)
    end)
end

local function Restore()
    isMinimized = false
    MinIcon.Visible = false
    MainFrame.Visible = true
    MainScale.Scale = 0.4
    MainFrame.BackgroundTransparency = 1
    Tween(MainScale, 0.25, {Scale = IsMobile() and 0.9 or 1}, Enum.EasingStyle.Back)
    Tween(MainFrame, 0.22, {BackgroundTransparency = 0.03})
end

MinimizeBtn.MouseButton1Click:Connect(Minimize)

local minDragged = false
MinIcon.MouseButton1Click:Connect(function()
    if not minDragged then
        Restore()
    end
end)

-- ================= DRAG & RESIZE WIRING =================
MakeDraggable(DragZone, MainFrame)
MakeResizable(ResizeHandle, MainFrame, Vector2.new(340, 380), Vector2.new(900, 640))

-- ================= RESPONSIVE HANDLING =================
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    Tween(MainFrame, 0.25, {Size = GetIdealSize()})
    MainScale.Scale = IsMobile() and 0.9 or 1
end)

-- ================= ENTRANCE ANIMATION =================
MainScale.Scale = 0.85
MainFrame.BackgroundTransparency = 1
Tween(MainScale, 0.3, {Scale = IsMobile() and 0.9 or 1}, Enum.EasingStyle.Back)
Tween(MainFrame, 0.3, {BackgroundTransparency = 0.03})

--[[
    TokaiHub x BRM5 - Fixed
    Hỗ trợ: Synapse Z, Synapse X, KRNL, Fluxus, Delta, Codex, Solara, Wave, Xeno, Script-Ware
]]

-- ═══ SERVICES ═══
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

-- ═══ EXECUTOR COMPAT ═══
local function GetGuiParent()
    -- Thử gethui (Synapse Z, Wave, Xeno)
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    -- Thử syn.get_hidden_gui (Synapse X cũ)
    if syn and syn.get_hidden_gui then
        local ok, h = pcall(syn.get_hidden_gui)
        if ok and h then return h end
    end
    -- Thử CoreGui
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local ok2 = pcall(function()
            local t = Instance.new("Frame"); t.Parent = cg; t:Destroy()
        end)
        if ok2 then return cg end
    end
    -- Fallback PlayerGui
    return LocalPlayer:WaitForChild("PlayerGui", 10) or LocalPlayer.PlayerGui
end

local function SafeGetModules()
    -- Hỗ trợ nhiều tên API khác nhau
    local result = {}
    local sources = {}
    if getmodules then
        local ok, m = pcall(getmodules)
        if ok and m then for _, v in pairs(m) do table.insert(sources, v) end end
    end
    if getloadedmodules then
        local ok, m = pcall(getloadedmodules)
        if ok and m then for _, v in pairs(m) do table.insert(sources, v) end end
    end
    -- Deduplicate
    local seen = {}
    for _, v in ipairs(sources) do
        if not seen[v] then seen[v] = true; table.insert(result, v) end
    end
    return result
end

local function SafeClipboard(text)
    if setclipboard then pcall(setclipboard, text); return end
    if toclipboard then pcall(toclipboard, text); return end
    if syn and syn.write_clipboard then pcall(syn.write_clipboard, text); return end
    if Clipboard and Clipboard.set then pcall(function() Clipboard.set(text) end) end
end

local function SafePlaySound(id)
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = id; s.Volume = 0.5
        s.Parent = SoundService; s:Play()
        game:GetService("Debris"):AddItem(s, 3)
    end)
end

-- ═══ SAVE SYSTEM ═══
local SAVE_FILE = "TokaiHub_BRM5.json"
local function SafeWrite(name, content)
    pcall(function() if writefile then writefile(name, content) end end)
end
local function SafeRead(name)
    local ok, data = pcall(function()
        if not isfile or not readfile then return nil end
        if not isfile(name) then return nil end
        return readfile(name)
    end)
    return (ok and type(data) == "string") and data or nil
end
local function Serialize(t)
    local parts = {}
    for k, v in pairs(t) do
        local vs = type(v) == "boolean" and (v and "true" or "false") or tostring(v)
        table.insert(parts, tostring(k) .. "=" .. vs)
    end
    return table.concat(parts, ";")
end
local function Deserialize(s, default)
    local t = {}; for k, v in pairs(default) do t[k] = v end
    if not s or s == "" then return t end
    for pair in s:gmatch("([^;]+)") do
        local k, v = pair:match("^(.-)=(.+)$")
        if k and v then
            if v == "true" then t[k] = true
            elseif v == "false" then t[k] = false
            else local n = tonumber(v); if n then t[k] = n end end
        end
    end
    return t
end
local S_DEFAULT = {}
local S = Deserialize(SafeRead(SAVE_FILE), S_DEFAULT)
local function Save() SafeWrite(SAVE_FILE, Serialize(S)) end

-- ═══ CLEANUP OLD UI ═══
local function CleanupOld()
    local gui = GetGuiParent()
    for _, name in ipairs({"TOKAIHUB_BRM5", "TOKAIHUB_BRM5_OVERLAY", "TokaiToast_BRM5"}) do
        local old = gui:FindFirstChild(name)
        if old then old:Destroy() end
    end
    -- Cleanup PlayerGui juga
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, name in ipairs({"TOKAIHUB_BRM5", "TOKAIHUB_BRM5_OVERLAY"}) do
            local old = pg:FindFirstChild(name)
            if old then old:Destroy() end
        end
    end
end
CleanupOld()

-- ═══ TOAST SYSTEM ═══
local toastQueue, toastRunning = {}, false
local function ShowToast(msg, icon)
    icon = icon or "✨"
    table.insert(toastQueue, {msg = msg, icon = icon})
    if toastRunning then return end
    toastRunning = true
    task.spawn(function()
        while #toastQueue > 0 do
            local item = table.remove(toastQueue, 1)
            local ok, sg = pcall(function()
                local s = Instance.new("ScreenGui")
                s.Name = "TokaiToast_BRM5"
                s.IgnoreGuiInset = true
                s.ResetOnSpawn = false
                s.DisplayOrder = 999
                s.Parent = GetGuiParent()
                return s
            end)
            if not ok then task.wait(0.1); continue end
            local W = 230
            local toast = Instance.new("Frame", sg)
            toast.Size = UDim2.new(0, W, 0, 40)
            toast.Position = UDim2.new(0.5, -W/2, 0, -50)
            toast.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
            toast.BackgroundTransparency = 0.05
            Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 12)
            local stroke = Instance.new("UIStroke", toast)
            stroke.Color = Color3.fromRGB(235, 110, 140); stroke.Thickness = 1.5
            local iconF = Instance.new("Frame", toast)
            iconF.Size = UDim2.new(0, 34, 1, 0)
            iconF.BackgroundColor3 = Color3.fromRGB(235, 110, 140)
            iconF.BackgroundTransparency = 0.2
            Instance.new("UICorner", iconF).CornerRadius = UDim.new(0, 12)
            local iconL = Instance.new("TextLabel", iconF)
            iconL.Size = UDim2.new(1, 0, 1, 0); iconL.Text = item.icon
            iconL.Font = Enum.Font.GothamBold; iconL.TextSize = 16
            iconL.BackgroundTransparency = 1; iconL.TextColor3 = Color3.new(1, 1, 1)
            local msgL = Instance.new("TextLabel", toast)
            msgL.Size = UDim2.new(1, -42, 1, 0); msgL.Position = UDim2.new(0, 38, 0, 0)
            msgL.Text = item.msg; msgL.Font = Enum.Font.GothamBold; msgL.TextSize = 10
            msgL.TextColor3 = Color3.fromRGB(90, 45, 55); msgL.BackgroundTransparency = 1
            msgL.TextXAlignment = Enum.TextXAlignment.Left; msgL.TextWrapped = true
            TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.5, -W/2, 0, 14)}):Play()
            task.wait(2.5)
            TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(0.5, -W/2, 0, -55), BackgroundTransparency = 1}):Play()
            task.wait(0.35); sg:Destroy(); task.wait(0.1)
        end
        toastRunning = false
    end)
end

-- ═══ COLORS ═══
local MC  = Color3.fromRGB(255, 182, 193)  -- main pink
local TC  = Color3.fromRGB(90,  45,  55)   -- text dark
local DP  = Color3.fromRGB(235, 110, 140)  -- dark pink accent
local GRN = Color3.fromRGB(34,  197, 94)   -- green ON
local GRY = Color3.fromRGB(160, 160, 160)  -- gray OFF
local BG  = Color3.fromRGB(255, 248, 250)  -- dropdown bg

-- ═══ SCREEN GUI ═══
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TOKAIHUB_BRM5"
screenGui.DisplayOrder = 10
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = GetGuiParent()

SafePlaySound("rbxassetid://90621979353525")

-- Camera
local Camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

local screenW = Camera.ViewportSize.X
local FW = math.clamp(math.floor(screenW * 0.88), 300, 390)
local FH = 240
local isLocked = false
local dragLocked = false
local _G_ToggleKey = Enum.KeyCode.RightControl

-- ═══ OVERLAY ═══
local overlayGui = Instance.new("ScreenGui")
overlayGui.Name = "TOKAIHUB_BRM5_OVERLAY"
overlayGui.ResetOnSpawn = false
overlayGui.IgnoreGuiInset = true
overlayGui.DisplayOrder = 9
overlayGui.Parent = GetGuiParent()
local overlay = Instance.new("Frame", overlayGui)
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(10, 5, 10)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.Active = false

-- ═══ OPEN BUTTON ═══
local openBtn = Instance.new("ImageButton", screenGui)
openBtn.Name = "OpenButton"
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 10, 0.5, -25)
openBtn.BackgroundColor3 = MC
openBtn.Image = "rbxassetid://6031075938"  -- generic icon, aman untuk semua executor
openBtn.Visible = false
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)
local openStroke = Instance.new("UIStroke", openBtn); openStroke.Thickness = 3

-- ═══ MAIN FRAME ═══
local main = Instance.new("Frame", screenGui)
main.Name = "MainFrame"
main.Size = UDim2.new(0, FW, 0, FH)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = MC
main.BackgroundTransparency = 0.3
main.ClipsDescendants = false
main.Visible = false
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 15)
local mainStroke = Instance.new("UIStroke", main); mainStroke.Thickness = 2

-- Rainbow stroke
task.spawn(function()
    local cols = {
        Color3.fromRGB(255,255,255),
        Color3.fromRGB(255,192,203),
        Color3.fromRGB(230,190,255)
    }
    while true do
        task.wait()
        local t = (math.sin(tick()*2)+1)/2
        local c = cols[1]:Lerp(cols[2],t):Lerp(cols[3],(math.cos(tick()*1.5)+1)/2)
        mainStroke.Color = c; openStroke.Color = c
    end
end)

-- Glow border
task.defer(function()
    task.wait(0.1)
    for _, name in ipairs({0, 180}) do
        local border = Instance.new("Frame", screenGui)
        border.Name = "__GlowBorder"
        border.Size = UDim2.new(0, FW, 0, FH)
        border.Position = main.Position
        border.AnchorPoint = Vector2.new(0.5, 0.5)
        border.BackgroundTransparency = 1
        border.ZIndex = 2; border.Active = false
        Instance.new("UICorner", border).CornerRadius = UDim.new(0, 15)
        local bStroke = Instance.new("UIStroke", border)
        bStroke.Thickness = 2; bStroke.Color = Color3.new(1,1,1)
        bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        local grad = Instance.new("UIGradient", bStroke)
        grad.Color = ColorSequence.new(Color3.new(1,1,1))
        grad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.18, 0),
            NumberSequenceKeypoint.new(0.32, 0.95),
            NumberSequenceKeypoint.new(0.5, 1),
            NumberSequenceKeypoint.new(0.68, 0.95),
            NumberSequenceKeypoint.new(0.82, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        local phase = name
        task.spawn(function()
            local rot = phase; local spd = 18; local last = tick()
            while true do
                RunService.Heartbeat:Wait()
                local now = tick(); local dt = now - last; last = now
                rot = (rot + spd * dt) % 360; grad.Rotation = rot
            end
        end)
        task.spawn(function()
            while true do
                RunService.Heartbeat:Wait()
                border.Position = main.Position
                border.Visible = main.Visible
            end
        end)
    end
end)

-- ═══ TOOLBAR ═══
local toolbar = Instance.new("Frame", main)
toolbar.Size = UDim2.new(0, 30, 0, 100)
toolbar.Position = UDim2.new(1, 5, 0, 10)
toolbar.BackgroundColor3 = Color3.new(1,1,1)
toolbar.BackgroundTransparency = 0.5
Instance.new("UICorner", toolbar).CornerRadius = UDim.new(0, 8)
local tbl = Instance.new("UIListLayout", toolbar)
tbl.Padding = UDim.new(0, 5)
tbl.HorizontalAlignment = Enum.HorizontalAlignment.Center
tbl.VerticalAlignment = Enum.VerticalAlignment.Center

local function MakeToolBtn(txt, col)
    local b = Instance.new("TextButton", toolbar)
    b.Size = UDim2.new(0,22,0,22); b.BackgroundColor3 = col
    b.Text = txt; b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold; b.TextSize = 13
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
    b.MouseEnter:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{Size=UDim2.new(0,25,0,25)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.15),{Size=UDim2.new(0,22,0,22)}):Play()
    end)
    return b
end
local closeBtn = MakeToolBtn("−", Color3.fromRGB(235,80,80))
local lockBtn  = MakeToolBtn("🔓", Color3.fromRGB(80,200,80))
local keyBtn   = MakeToolBtn("⌨", DP)

-- ═══ SIDEBAR ═══
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0,35,0,200)
sidebar.Position = UDim2.new(1,-40,0.5,-100)
sidebar.BackgroundColor3 = Color3.new(1,1,1)
sidebar.BackgroundTransparency = 0.65
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(1,0)
local sbl = Instance.new("UIListLayout", sidebar)
sbl.Padding = UDim.new(0,7)
sbl.HorizontalAlignment = Enum.HorizontalAlignment.Center
sbl.VerticalAlignment = Enum.VerticalAlignment.Center

-- ═══ TAB CONTAINER ═══
local tabContainer = Instance.new("Frame", main)
tabContainer.Size = UDim2.new(0,335,0,215)
tabContainer.Position = UDim2.new(0,8,0,10)
tabContainer.BackgroundTransparency = 1
tabContainer.ClipsDescendants = true
local pages = Instance.new("Frame", tabContainer)
pages.Size = UDim2.new(1,0,1,0)
pages.BackgroundTransparency = 1

-- ═══ TOGGLE UI ═══
local isTweening = false
local activeDropdown = nil

local function ToggleUI()
    if isTweening then return end; isTweening = true
    if main.Visible then
        if activeDropdown then pcall(activeDropdown, true) end
        TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
        TweenService:Create(main, TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),
            {Size=UDim2.new(0,FW*0.05,0,FH*0.05), BackgroundTransparency=1}):Play()
        task.delay(0.32, function()
            main.Visible = false; main.BackgroundTransparency = 0.3
            overlay.Visible = false
            openBtn.Visible = true; openBtn.Size = UDim2.new(0,0,0,0)
            TweenService:Create(openBtn,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
                {Size=UDim2.new(0,50,0,50)}):Play()
            isTweening = false
        end)
    else
        openBtn.Visible = false
        overlay.Visible = true; overlay.BackgroundTransparency = 1
        TweenService:Create(overlay, TweenInfo.new(0.35), {BackgroundTransparency=0.5}):Play()
        main.Position = UDim2.new(0.5,0,0.5,0)
        main.Visible = true
        main.Size = UDim2.new(0,FW*0.05,0,FH*0.05)
        main.BackgroundTransparency = 1
        TweenService:Create(main, TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
            {Size=UDim2.new(0,FW,0,FH), BackgroundTransparency=0.3}):Play()
        task.delay(0.46, function() isTweening = false end)
    end
end

closeBtn.MouseButton1Click:Connect(function() SafePlaySound("rbxassetid://126347354635406"); ToggleUI() end)
lockBtn.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    lockBtn.Text = isLocked and "🔒" or "🔓"
    lockBtn.BackgroundColor3 = isLocked and Color3.fromRGB(200,80,80) or Color3.fromRGB(80,200,80)
end)
local isBinding = false
keyBtn.MouseButton1Click:Connect(function()
    if isBinding then return end
    isBinding = true; keyBtn.Text = "..."
    local c; c = UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            _G_ToggleKey = inp.KeyCode; keyBtn.Text = "⌨"; isBinding = false; c:Disconnect()
        end
    end)
end)
openBtn.MouseButton1Click:Connect(function() SafePlaySound("rbxassetid://126347354635406"); ToggleUI() end)
UserInputService.InputBegan:Connect(function(inp, gpe)
    if not gpe and inp.KeyCode == _G_ToggleKey then ToggleUI() end
end)

-- ═══ DRAG ═══
local function EnableDrag(obj)
    local dragging, dragStart, startPos
    obj.InputBegan:Connect(function(inp)
        if isLocked or dragLocked then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = inp.Position; startPos = obj.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and not isLocked and not dragLocked and
        (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false; dragLocked = false
        end
    end)
end
EnableDrag(main); EnableDrag(openBtn)

-- ═══ ELEMENT BUILDERS ═══
local function MakeBtn(parent, text, yPos, callback, toastMsg, toastIcon)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1,-4,0,28); btn.Position = UDim2.new(0,2,0,yPos)
    btn.BackgroundColor3 = Color3.fromRGB(255,255,255); btn.BackgroundTransparency = 0.45
    btn.Text = text; btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = TC; btn.TextSize = 10; btn.ClipsDescendants = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    local stroke = Instance.new("UIStroke", btn); stroke.Color = DP; stroke.Thickness = 1.2
    btn.MouseButton1Click:Connect(function()
        SafePlaySound("rbxassetid://126347354635406")
        TweenService:Create(btn,TweenInfo.new(0.07),{Size=UDim2.new(1,-8,0,25),Position=UDim2.new(0,4,0,yPos+1.5)}):Play()
        task.delay(0.07,function()
            TweenService:Create(btn,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
                {Size=UDim2.new(1,-4,0,28),Position=UDim2.new(0,2,0,yPos)}):Play()
        end)
        if toastMsg then ShowToast(toastMsg, toastIcon) end
        if callback then callback() end
    end)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(255,225,232),Position=UDim2.new(0,2,0,yPos-1)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(255,255,255),Position=UDim2.new(0,2,0,yPos)}):Play()
    end)
    return btn
end

local function MakeToggle(parent, labelText, yPos, savedKey, onCallback)
    local state = S[savedKey] or false
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-4,0,26); row.Position = UDim2.new(0,2,0,yPos)
    row.BackgroundColor3 = Color3.fromRGB(255,255,255); row.BackgroundTransparency = 0.45
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)
    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Color = state and GRN or Color3.fromRGB(200,200,200); rowStroke.Thickness = 1; rowStroke.Transparency = 0.5
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.72,0,1,0); lbl.Position = UDim2.new(0,8,0,0)
    lbl.Text = labelText; lbl.Font = Enum.Font.GothamBold; lbl.TextColor3 = TC; lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.BackgroundTransparency = 1
    local pill = Instance.new("Frame", row)
    pill.Size = UDim2.new(0,36,0,16); pill.Position = UDim2.new(1,-42,0.5,-8)
    pill.BackgroundColor3 = state and GRN or GRY
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)
    local pillGlow = Instance.new("UIStroke", pill); pillGlow.Color = GRN; pillGlow.Thickness = 2; pillGlow.Transparency = state and 0.3 or 1
    local knob = Instance.new("Frame", pill)
    knob.Size = UDim2.new(0,12,0,12)
    knob.Position = state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local setter
    setter = function(newState)
        state = newState; S[savedKey] = state; Save()
        TweenService:Create(pill,TweenInfo.new(0.2),{BackgroundColor3=state and GRN or GRY}):Play()
        TweenService:Create(pillGlow,TweenInfo.new(0.2),{Transparency=state and 0.3 or 1}):Play()
        TweenService:Create(rowStroke,TweenInfo.new(0.2),{Color=state and GRN or Color3.fromRGB(200,200,200)}):Play()
        local tp = state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
        TweenService:Create(knob,TweenInfo.new(0.08),{Size=UDim2.new(0,10,0,14)}):Play()
        task.delay(0.08,function()
            TweenService:Create(knob,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=tp,Size=UDim2.new(0,12,0,12)}):Play()
        end)
        if onCallback then onCallback(state) end
    end
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.MouseButton1Click:Connect(function() SafePlaySound("rbxassetid://126347354635406"); setter(not state) end)
    btn.MouseEnter:Connect(function() TweenService:Create(row,TweenInfo.new(0.15),{BackgroundTransparency=0.3}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(row,TweenInfo.new(0.15),{BackgroundTransparency=0.45}):Play() end)
    if state and onCallback then task.spawn(function() task.wait(1.5); onCallback(true) end) end
    return setter
end

local function MakeSlider(parent, labelText, yPos, min, max, savedKey, suffix, onCallback)
    local value = S[savedKey] or min
    local KW = 13
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-4,0,40); row.Position = UDim2.new(0,2,0,yPos)
    row.BackgroundColor3 = Color3.fromRGB(255,255,255); row.BackgroundTransparency = 0.45; row.ClipsDescendants = false
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6,0,0,18); lbl.Position = UDim2.new(0,8,0,2)
    lbl.Text = labelText; lbl.Font = Enum.Font.GothamBold; lbl.TextColor3 = TC; lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.BackgroundTransparency = 1
    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size = UDim2.new(0.35,0,0,18); valLbl.Position = UDim2.new(0.62,0,0,2)
    valLbl.Text = tostring(value)..suffix; valLbl.Font = Enum.Font.GothamBold
    valLbl.TextColor3 = DP; valLbl.TextSize = 9
    valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.BackgroundTransparency = 1
    local TP = 8 + math.ceil(KW/2)
    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1,-(TP*2),0,6); track.Position = UDim2.new(0,TP,0,27)
    track.BackgroundColor3 = Color3.fromRGB(220,190,200); track.ClipsDescendants = false
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((value-min)/(max-min),0,1,0); fill.BackgroundColor3 = DP
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local ip = (value-min)/(max-min)
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0,KW,0,KW)
    knob.Position = UDim2.new(ip,-math.floor(KW*ip),0.5,-math.ceil(KW/2))
    knob.BackgroundColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    local ks = Instance.new("UIStroke", knob); ks.Color = DP; ks.Thickness = 1.5
    local dragging = false
    local function upd(ax)
        local pct = math.clamp((ax - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + pct*(max-min))
        S[savedKey] = value; Save()
        valLbl.Text = tostring(value)..suffix
        fill.Size = UDim2.new(pct,0,1,0)
        knob.Position = UDim2.new(pct,-math.floor(KW*pct),0.5,-math.ceil(KW/2))
        if onCallback then onCallback(value) end
    end
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragLocked=true
        end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragLocked=true; upd(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            upd(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=false; dragLocked=false
        end
    end)
    return row
end

local function MakeDropdown(parent, labelText, yPos, options, savedKey, onCallback)
    local selected = S[savedKey] or options[1]
    local isOpen = false; local IH = 22; local HH = 26
    local head = Instance.new("Frame", parent)
    head.Size = UDim2.new(1,-4,0,HH); head.Position = UDim2.new(0,2,0,yPos)
    head.BackgroundColor3 = Color3.fromRGB(255,255,255); head.BackgroundTransparency = 0.4; head.ClipsDescendants = false
    Instance.new("UICorner", head).CornerRadius = UDim.new(0,7)
    local hStroke = Instance.new("UIStroke", head); hStroke.Color = DP; hStroke.Thickness = 1.2
    local lbl = Instance.new("TextLabel", head)
    lbl.Size = UDim2.new(0.55,0,1,0); lbl.Position = UDim2.new(0,8,0,0)
    lbl.Text = labelText; lbl.Font = Enum.Font.GothamBold; lbl.TextColor3 = TC; lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.BackgroundTransparency = 1
    local valLbl = Instance.new("TextLabel", head)
    valLbl.Size = UDim2.new(0.35,0,1,0); valLbl.Position = UDim2.new(0.55,0,0,0)
    valLbl.Text = selected; valLbl.Font = Enum.Font.GothamBold; valLbl.TextColor3 = DP; valLbl.TextSize = 8
    valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.BackgroundTransparency = 1
    local arrow = Instance.new("TextLabel", head)
    arrow.Size = UDim2.new(0,16,1,0); arrow.Position = UDim2.new(1,-18,0,0)
    arrow.Text = "▼"; arrow.Font = Enum.Font.GothamBold; arrow.TextColor3 = DP; arrow.TextSize = 8
    arrow.BackgroundTransparency = 1
    local listFrame = Instance.new("Frame", screenGui)
    listFrame.BackgroundColor3 = BG; listFrame.BackgroundTransparency = 0
    listFrame.Visible = false; listFrame.ZIndex = 20; listFrame.ClipsDescendants = true
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0,8)
    local lStroke = Instance.new("UIStroke", listFrame); lStroke.Color = DP; lStroke.Thickness = 1; lStroke.Transparency = 0.4
    local function CloseList(instant)
        if not isOpen then return end; isOpen = false; activeDropdown = nil
        TweenService:Create(arrow,TweenInfo.new(0.2),{Rotation=0}):Play()
        if instant then listFrame.Visible = false
        else
            local w = listFrame.AbsoluteSize.X
            TweenService:Create(listFrame,TweenInfo.new(0.18),{Size=UDim2.new(0,w,0,0)}):Play()
            task.delay(0.2, function() listFrame.Visible = false end)
        end
    end
    local function OpenList()
        if activeDropdown and activeDropdown ~= CloseList then pcall(activeDropdown, true) end
        activeDropdown = CloseList; isOpen = true
        local ap = head.AbsolutePosition; local as = head.AbsoluteSize
        local totalH = #options * IH + 6; local lw = as.X
        for _, c in pairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for i, opt in ipairs(options) do
            local item = Instance.new("TextButton", listFrame)
            item.Size = UDim2.new(1,0,0,IH); item.Position = UDim2.new(0,0,0,(i-1)*IH+3)
            item.BackgroundColor3 = opt==selected and Color3.fromRGB(255,215,228) or Color3.fromRGB(255,248,251)
            item.BackgroundTransparency = opt==selected and 0 or 1
            item.Font = Enum.Font.GothamBold; item.TextColor3 = opt==selected and DP or TC
            item.TextSize = 9; item.TextXAlignment = Enum.TextXAlignment.Left; item.ZIndex = 21; item.Text = ""
            local pad = Instance.new("UIPadding", item); pad.PaddingLeft = UDim.new(0,10)
            local chk = Instance.new("TextLabel", item)
            chk.Size=UDim2.new(0,12,1,0); chk.Text=opt==selected and "✓" or ""
            chk.Font=Enum.Font.GothamBold; chk.TextSize=8; chk.TextColor3=DP; chk.BackgroundTransparency=1; chk.ZIndex=22
            local txt = Instance.new("TextLabel", item)
            txt.Size=UDim2.new(1,-14,1,0); txt.Position=UDim2.new(0,14,0,0)
            txt.Text=opt; txt.Font=Enum.Font.GothamBold; txt.TextSize=9
            txt.TextColor3=opt==selected and DP or TC; txt.TextXAlignment=Enum.TextXAlignment.Left
            txt.BackgroundTransparency=1; txt.ZIndex=22
            item.MouseButton1Click:Connect(function()
                SafePlaySound("rbxassetid://126347354635406")
                selected=opt; S[savedKey]=selected; Save(); valLbl.Text=selected
                task.delay(0.07, function() CloseList(false) end)
                if onCallback then onCallback(selected) end
                ShowToast("Selected: "..selected, "✅")
            end)
        end
        listFrame.Size = UDim2.new(0,lw,0,0)
        listFrame.Position = UDim2.new(0,ap.X,0,ap.Y+as.Y+4)
        listFrame.Visible = true
        TweenService:Create(arrow,TweenInfo.new(0.2),{Rotation=180}):Play()
        TweenService:Create(listFrame,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,lw,0,totalH)}):Play()
    end
    local hBtn = Instance.new("TextButton", head)
    hBtn.Size=UDim2.new(1,0,1,0); hBtn.BackgroundTransparency=1; hBtn.Text=""; hBtn.ZIndex=10
    hBtn.MouseButton1Click:Connect(function()
        SafePlaySound("rbxassetid://126347354635406")
        if isOpen then CloseList(false) else OpenList() end
    end)
    return head
end

-- ═══ CREATE TAB ═══
local firstTab = true
local function CreateTab(name, iconText)
    local page = Instance.new("ScrollingFrame", pages)
    page.Name = name.."Page"
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = DP
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.ElasticBehavior = Enum.ElasticBehavior.Never
    page.ClipsDescendants = true

    -- Touch scroll lock
    local touchStart = nil
    page.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then touchStart = inp.Position end
    end)
    page.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch and touchStart then
            local dy = math.abs(inp.Position.Y - touchStart.Y)
            local dx = math.abs(inp.Position.X - touchStart.X)
            if dy > dx and dy > 6 then dragLocked = true end
        end
    end)
    page.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then touchStart = nil; dragLocked = false end
    end)

    local tabBtn = Instance.new("TextButton", sidebar)
    tabBtn.Size = UDim2.new(0,27,0,27)
    tabBtn.BackgroundColor3 = DP; tabBtn.BackgroundTransparency = 0.2
    tabBtn.Text = iconText or name:sub(1,1)
    tabBtn.TextScaled = true; tabBtn.Font = Enum.Font.GothamBold; tabBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(1,0)
    local tStroke = Instance.new("UIStroke", tabBtn)
    tStroke.Color = Color3.new(1,1,1); tStroke.Thickness = 2; tStroke.Transparency = 1
    tStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    tabBtn.MouseButton1Click:Connect(function()
        if page.Visible then return end
        SafePlaySound("rbxassetid://126347354635406")
        if activeDropdown then pcall(activeDropdown, true) end
        for _, v in pairs(pages:GetChildren()) do
            if v:IsA("ScrollingFrame") and v.Visible then
                TweenService:Create(v,TweenInfo.new(0.18),{Position=UDim2.new(-0.15,0,0,0)}):Play()
                task.delay(0.18, function() v.Visible=false; v.Position=UDim2.new(0,0,0,0) end)
            end
        end
        for _, b in pairs(sidebar:GetChildren()) do
            if b:IsA("TextButton") then
                TweenService:Create(b,TweenInfo.new(0.15),{BackgroundTransparency=0.2}):Play()
                local s = b:FindFirstChildOfClass("UIStroke")
                if s then TweenService:Create(s,TweenInfo.new(0.15),{Transparency=1}):Play() end
            end
        end
        task.delay(0.12, function()
            page.Position = UDim2.new(0.15,0,0,0); page.Visible = true
            TweenService:Create(page,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0,0)}):Play()
        end)
        TweenService:Create(tabBtn,TweenInfo.new(0.15),{BackgroundTransparency=0}):Play()
        TweenService:Create(tStroke,TweenInfo.new(0.2),{Transparency=0}):Play()
    end)

    local yOffset = 4
    local tab = {}

    function tab:Section(text)
        local lbl = Instance.new("TextLabel", page)
        lbl.Size=UDim2.new(1,-4,0,18); lbl.Position=UDim2.new(0,2,0,yOffset)
        lbl.Text="── "..text.." ──"; lbl.Font=Enum.Font.GothamBold
        lbl.TextColor3=DP; lbl.TextSize=9; lbl.BackgroundTransparency=1
        yOffset = yOffset + 22
    end
    function tab:Button(text, callback, toastMsg, toastIcon)
        MakeBtn(page, text, yOffset, callback, toastMsg, toastIcon)
        yOffset = yOffset + 32
    end
    function tab:Toggle(text, savedKey, callback)
        local setter = MakeToggle(page, text, yOffset, savedKey, callback)
        yOffset = yOffset + 30
        return setter
    end
    function tab:Slider(text, min, max, savedKey, suffix, callback)
        MakeSlider(page, text, yOffset, min, max, savedKey, suffix or "", callback)
        yOffset = yOffset + 44
    end
    function tab:Dropdown(text, options, savedKey, callback)
        MakeDropdown(page, text, yOffset, options, savedKey, callback)
        yOffset = yOffset + 32
    end
    function tab:Label(text)
        local lbl = Instance.new("TextLabel", page)
        lbl.Size=UDim2.new(1,-4,0,20); lbl.Position=UDim2.new(0,2,0,yOffset)
        lbl.Text=text; lbl.Font=Enum.Font.Gotham; lbl.TextSize=9
        lbl.TextColor3=TC; lbl.BackgroundTransparency=1
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextWrapped=true
        yOffset = yOffset + 24
    end

    if firstTab then
        firstTab = false
        page.Visible = true
        TweenService:Create(tabBtn,TweenInfo.new(0.1),{BackgroundTransparency=0}):Play()
        TweenService:Create(tStroke,TweenInfo.new(0.2),{Transparency=0}):Play()
    end

    return tab
end

-- ═══════════════════════════════════════════════════════════
--  BRM5 LOGIC
-- ═══════════════════════════════════════════════════════════

local Packages     = ReplicatedStorage:WaitForChild("Packages", 10)
local Events       = ReplicatedStorage:WaitForChild("Events", 10)
local RemoteEvent  = Events and Events:WaitForChild("RemoteEvent", 10)
local ServerSettings = {}

pcall(function()
    if Packages then
        local Server = require(Packages:WaitForChild("server"))
        ServerSettings = Server._cache
    end
end)

local SilentAim, Aimbot, Trigger = nil, false, false
local Actors, RoundInterface, Network = nil, nil, nil
local NPCFolder     = workspace:FindFirstChild("Bots") or workspace:WaitForChild("Bots", 10)
local RaycastFolder = workspace:FindFirstChild("Raycast") or workspace:WaitForChild("Raycast", 10)
local ProjectileSpeed   = 1000
local ProjectileGravity = Vector3.new(0, workspace.Gravity, 0)
local GravityCorrection = 2
local GroundTip, AircraftTip = nil, nil
local NoClipObjects = {}
local WhiteColor = Color3.new(1,1,1)

local Teleports = {
    {"FOB",                    Vector3.new(-3993,64,757)   },
    {"Communications Tower",   Vector3.new(-1800,785,-4140)},
    {"Dept. of Utilities",     Vector3.new(-54,63,-3645)   },
    {"Vietnama Village",       Vector3.new(739,118,-92)    },
    {"Fort Ronograd",          Vector3.new(6359,190,-1468) },
    {"Ronograd City",          Vector3.new(3478,176,1073)  },
    {"Sochraina City",         Vector3.new(93,26,3630)     },
    {"El Chara",               Vector3.new(-4768,108,5218) },
    {"Naval Docks",            Vector3.new(6174,130,2099)  },
    {"Quarry",                 Vector3.new(331,86,2598)    },
    {"Nuclear Silo",           Vector3.new(1024,44,-5148)  },
}

local KnownBodyParts = {
    "Head","HumanoidRootPart","UpperTorso","LowerTorso",
    "RightUpperArm","RightLowerArm","RightHand",
    "LeftUpperArm","LeftLowerArm","LeftHand",
    "RightUpperLeg","RightLowerLeg","RightFoot",
    "LeftUpperLeg","LeftLowerLeg","LeftFoot",
}

-- Flags
local F = {
    SA_Enabled=false, SA_Pred=false, SA_Wall=false, SA_Dist=false,
    SA_FOV=100, SA_DistLimit=250, SA_HitChance=100, SA_Part="Head",
    AB_Enabled=false, AB_Always=false, AB_Pred=false, AB_Wall=false,
    AB_Dist=false, AB_FOV=100, AB_DistLimit=250, AB_Sens=20, AB_Part="Head",
    NPCMode=true,
    Recoil=false, RecoilVal=0, BulletDrop=false, Firemodes=false,
    RapidFire=false, RPM=1000,
    NoClip=false, NoBob=false, NoStamina=false, NoNVG=false, NoNVGShape=false,
    SpeedHack=false, SpeedVal=120,
    ThirdPerson=false,
    VehEnabled=false, VehSpeed=100, VehAcc=1,
    HeliEnabled=false, HeliSpeed=200,
    AirEnabled=false, AirSpeed=130, AirFly=false, AirCam=false, AirFlySpeed=200,
    LightEnabled=false, LightBright=false, LightTime=12, LightFog=25,
}

local XZ=Vector3.new(1,0,1)
local function FixUnit(v) if v.Magnitude==0 then return Vector3.zero end return v.Unit end
local function InputToVelocity()
    local cf=Camera.CFrame
    local lv=(cf.LookVector*XZ);local rv=(cf.RightVector*XZ)
    return FixUnit(
        (UserInputService:IsKeyDown(Enum.KeyCode.W) and lv or Vector3.zero)+
        (UserInputService:IsKeyDown(Enum.KeyCode.S) and -lv or Vector3.zero)+
        (UserInputService:IsKeyDown(Enum.KeyCode.A) and -rv or Vector3.zero)+
        (UserInputService:IsKeyDown(Enum.KeyCode.D) and rv or Vector3.zero)+
        (UserInputService:IsKeyDown(Enum.KeyCode.Space) and Vector3.new(0,1,0) or Vector3.zero)+
        (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and Vector3.new(0,-1,0) or Vector3.zero)
    )
end

local WCP=RaycastParams.new(); WCP.FilterType=Enum.RaycastFilterType.Blacklist; WCP.IgnoreWater=true
local function Raycast(O,D,Filter) WCP.FilterDescendantsInstances=Filter; return workspace:Raycast(O,D,WCP) end
local function IsVisible(En,O,P,Char)
    if not En then return true end
    local rf = RaycastFolder or workspace
    return not Raycast(O,P-O,{Char,rf,LocalPlayer.Character})
end
local function IsDistLimited(En,D,Lim) if not En then return false end; return D>=Lim end
local function SolveTraj(O,V,T,G) return O+V*T+G*T*T/GravityCorrection end

local function GetClosest(Enabled,Wall,Dist,DistLim,FOV,Part,Pred,NPCMode)
    if not Enabled or not Actors then return end
    local camPos=Camera.CFrame.Position; local closest=nil
    for _,Actor in pairs(Actors) do
        local Player=Actor.Player
        if Player==LocalPlayer then continue end
        local Char=Actor.Character; local Hum=Actor.Humanoid; local Root=Actor.RootPart
        if not Hum or Hum.Health<=0 then continue end
        if NPCMode then
            if Actor._isPlayer then continue end
            local rra=Root:FindFirstChild("RootRigAttachment")
            if not rra then continue end
            if not Root:FindFirstChild("AlignOrientation") then continue end
            if rra:FindFirstChildOfClass("ProximityPrompt") then continue end
        else
            if not Actor._isPlayer then continue end
        end
        local bp = Char:FindFirstChild(Part)
        if not bp then bp=Char:FindFirstChild("Head") end
        if not bp then continue end
        local bpp=bp.Position
        local distance=(bpp-camPos).Magnitude
        if IsDistLimited(Dist,distance,DistLim) then continue end
        if not IsVisible(Wall,camPos,bpp,Char) then continue end
        if Pred then bpp=SolveTraj(bpp,bp.AssemblyLinearVelocity,distance/ProjectileSpeed,ProjectileGravity) end
        local sp,onScreen=Camera:WorldToViewportPoint(bpp)
        if not onScreen then continue end
        local mag=(Vector2.new(sp.X,sp.Y)-UserInputService:GetMouseLocation()).Magnitude
        if mag>=FOV then continue end
        if not closest or mag<closest[5] then closest={Player,Char,bp,sp,mag} end
    end
    return closest
end
local function AimAt(h,sens)
    if not h then return end
    local ml=UserInputService:GetMouseLocation()
    pcall(function() mousemoverel((h[4].X-ml.X)*sens,(h[4].Y-ml.Y)*sens) end)
end

function RequireModule(Name)
    for _,inst in ipairs(SafeGetModules()) do
        if inst.Name==Name then
            local ok,res=pcall(require,inst); if ok and res then return res end
        end
    end
end
local function HookFunction(ModuleName,FuncName,Hook)
    task.spawn(function()
        local mod,old
        while task.wait(0.5) do
            mod=RequireModule(ModuleName)
            if mod and mod[FuncName] then old=mod[FuncName]; break end
        end
        mod[FuncName]=function(...) return Hook(old,...) end
    end)
end
local function HookSignal(Signal,Index,Hook)
    local conn=nil
    pcall(function() conn=getconnections(Signal)[Index] end)
    if not conn then return end
    local oldFn=conn.Function; if not oldFn then return end
    conn:Disable()
    Signal:Connect(function(...) return Hook(oldFn,...) end)
end

local function AircraftFly(Self,Enabled,Speed,CamCtrl)
    if not Enabled then return end
    Self._force.MaxForce=Vector3.new(1,1,1)*40000000
    Self._force.Velocity=InputToVelocity()*Speed
    if CamCtrl then
        Self._gyro.MaxTorque=Vector3.new(1,1,1)*4000
        Self._gyro.CFrame=Camera.CFrame*CFrame.Angles(0,math.pi,0)
    end
end
local function TeleportModule(Position,Velocity)
    local PP=LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
    if not PP then return end
    local TPM={}
    local AP=Instance.new("AlignPosition"); AP.Mode=Enum.PositionAlignmentMode.OneAttachment; AP.Attachment0=PP.RootRigAttachment
    local AO=Instance.new("AlignOrientation"); AO.Mode=Enum.OrientationAlignmentMode.OneAttachment; AO.Attachment0=PP.RootRigAttachment
    AP.MaxVelocity=Velocity; AP.Position=Position; AP.Parent=PP; AO.Parent=PP
    function TPM:Update(p,v) AP.MaxVelocity=v; AP.Position=p end
    function TPM:Wait() while task.wait() do if (PP.Position-AP.Position).Magnitude<5 then break end end end
    function TPM:Destroy() TPM:Wait(); AP:Destroy(); AO:Destroy() end
    return TPM
end
function TeleportCharacter(Position)
    local PP=LocalPlayer.Character and LocalPlayer.Character.PrimaryPart; if not PP then return end
    local oldNC=F.NoClip; F.NoClip=true
    LocalPlayer.Character.Humanoid.Sit=true
    PP.CFrame=CFrame.new(PP.Position+Vector3.new(0,500,0))
    local TP=TeleportModule(Position+Vector3.new(0,500,0),500)
    if TP then TP:Destroy(); PP.CFrame=CFrame.new(Position) end
    LocalPlayer.Character.Humanoid.Sit=false; F.NoClip=oldNC
end
function EnableSwitch(Switch)
    local CamMod=RequireModule("CameraService"); if not CamMod or not CamMod._handler or not CamMod._handler._buttons then return end
    for _,Sw in pairs(CamMod._handler._buttons) do
        if Sw._id==Switch then Sw:Update(); Sw:Select(); CamMod._switch=Sw; CamMod._switch:Activate(); CamMod._switch:Unselect() end
    end
end

-- Hooks
HookFunction("ControllerClass","LateUpdate",function(Old,Self,...)
    if F.SpeedHack then Self.Speed=F.SpeedVal end; return Old(Self,...)
end)
HookFunction("ViewmodelClass","Update",function(Old,Self,...)
    local A={...}; if F.SpeedHack and A[2] then A[2]=CFrame.new(A[2].Position) end
    return Old(Self,table.unpack(A))
end)
HookFunction("CharacterCamera","Update",function(Old,Self,...)
    if F.NoBob then Self._bob=0 end
    if F.Recoil then Self._recoil.Velocity=Self._recoil.Velocity*(F.RecoilVal/100) end
    return Old(Self,...)
end)
HookFunction("FirearmInventory","_firemode",function(Old,Self,...)
    if F.Firemodes then
        local c=Self._config
        for _,n in ipairs({1,2,3}) do if not table.find(c.Tune.Firemodes,n) then table.insert(c.Tune.Firemodes,n) end end
    end; return Old(Self,...)
end)
HookFunction("FirearmInventory","_discharge",function(Old,Self,...)
    if F.RapidFire then Self._config.Tune.RPM=F.RPM end
    if F.BulletDrop then Self._velocity=1e6; Self._range=1e6 end
    ProjectileSpeed=Self._velocity; return Old(Self,...)
end)
HookFunction("CharacterMovement","Update",function(Old,Self,...)
    if F.NoStamina then Self._exhausted=0 end; return Old(Self,...)
end)
HookFunction("TurretMovement","_discharge",function(Old,Self,...)
    if F.BulletDrop then Self._tune.Velocity=1e6; Self._tune.Range=1e6 end
    ProjectileSpeed=Self._tune.Velocity; GroundTip=Self._tip; return Old(Self,...)
end)
HookFunction("AircraftMovement","_discharge",function(Old,Self,...)
    if F.BulletDrop then Self._tune.Velocity=1e6; Self._tune.Range=1e6 end
    ProjectileSpeed=Self._tune.Velocity; AircraftTip=Self._tip; return Old(Self,...)
end)
HookFunction("GroundMovement","Update",function(Old,Self,...)
    if F.VehEnabled then
        local A={...}; local R={Old(Self,...)}
        for _,M in pairs(Self._motors.f) do M.MotorMaxTorque=200000*F.VehSpeed; M.AngularVelocity=(-A[2].Y*F.VehSpeed) end
        for _,M in pairs(Self._motors.b) do M.MotorMaxTorque=200000*F.VehSpeed; M.AngularVelocity=-(-A[2].Y*F.VehSpeed) end
        return table.unpack(R)
    end; return Old(Self,...)
end)
HookFunction("HelicopterMovement","Update",function(Old,Self,...)
    if F.HeliEnabled then Self._tune.Speed=F.HeliSpeed end; return Old(Self,...)
end)
HookFunction("AircraftMovement","Update",function(Old,Self,...)
    if F.AirEnabled then Self._model.RPM.Value=F.AirSpeed end
    AircraftFly(Self,F.AirFly,F.AirFlySpeed,F.AirCam); return Old(Self,...)
end)
HookFunction("EnvironmentService","Update",function(Old,Self,...)
    if F.LightEnabled then
        local fog=F.LightFog/100
        Self._atmospheres.Default.Density=fog
        if Self._atmospheres.Desert then Self._atmospheres.Desert.Density=fog end
        if Self._atmospheres.Snow   then Self._atmospheres.Snow.Density=fog   end
    end; return Old(Self,...)
end)

if RemoteEvent then
    HookSignal(RemoteEvent.OnClientEvent,1,function(Old,...)
        local A={...}
        if A[1]=="ReplicateNVG" then
            if F.NoNVG then A[2]=false end
            if F.NoNVGShape then A[3]="" end
        end; return Old(table.unpack(A))
    end)
end

-- NoClip
RunService.Stepped:Connect(function()
    if not F.NoClip or not LocalPlayer.Character then return end
    for _,O in pairs(LocalPlayer.Character:GetDescendants()) do
        if O:IsA("BasePart") then
            if NoClipObjects[O]==nil then NoClipObjects[O]=O.CanCollide end
            O.CanCollide=false
        end
    end
end)

-- 3rd Person
RunService.Heartbeat:Connect(function()
    if F.ThirdPerson and ServerSettings["FIRSTPERSON_LOCKED"]==true then
        ServerSettings["FIRSTPERSON_LOCKED"]=false
    end
    if F.LightBright then Lighting.OutdoorAmbient=WhiteColor end
    if F.LightEnabled then Lighting.ClockTime=F.LightTime end
end)

-- Network
task.spawn(function()
    for _,T in pairs(getgc(true)) do
        if typeof(T)=="table" and rawget(T,"FireServer") and rawget(T,"InvokeServer") then
            Network=T; break
        end
    end
end)

-- Silent Aim namecall
local OldNamecall
OldNamecall=hookmetamethod(game,"__namecall",function(Self,...)
    if SilentAim and getnamecallmethod()=="Raycast" then
        if math.random(100)<=F.SA_HitChance then
            local A={...}
            local camP=Camera.CFrame.Position
            if A[1]==camP then
                A[2]=SilentAim[3].Position-camP
            elseif AircraftTip and A[1]==AircraftTip.WorldCFrame.Position then
                A[2]=SilentAim[3].Position-AircraftTip.WorldCFrame.Position
            elseif GroundTip and A[1]==GroundTip.WorldCFrame.Position then
                A[2]=SilentAim[3].Position-GroundTip.WorldCFrame.Position
            end
            return OldNamecall(Self,table.unpack(A))
        end
    end
    return OldNamecall(Self,...)
end)

-- Game loops
task.spawn(function()
    repeat task.wait() until RequireModule("RoundInterface")
    RoundInterface=RequireModule("RoundInterface")
    repeat task.wait() until RequireModule("ActorService")
    Actors=RequireModule("ActorService")._actors
    ShowToast("BRM5 Ready!", "✅")
end)
task.spawn(function()
    while task.wait() do
        SilentAim=GetClosest(F.SA_Enabled,F.SA_Wall,F.SA_Dist,F.SA_DistLimit,F.SA_FOV,F.SA_Part,F.SA_Pred,F.NPCMode)
    end
end)
task.spawn(function()
    while task.wait() do
        if not (Aimbot or F.AB_Always) then continue end
        AimAt(GetClosest(F.AB_Enabled,F.AB_Wall,F.AB_Dist,F.AB_DistLimit,F.AB_FOV,F.AB_Part,F.AB_Pred,F.NPCMode),F.AB_Sens/100)
    end
end)

-- ═══ BUILD UI TABS ═══

-- HOME
local home = CreateTab("Home", "🏠")
home:Label("TokaiHub x BRM5 | "..LocalPlayer.DisplayName)
home:Label("Bấm RightControl để ẩn/hiện | Kéo để di chuyển")
home:Section("Thông tin")
home:Label("Silent Aim · Aimbot · Weapon · Character · Vehicle · Teleport")
home:Label("Hỗ trợ: Synapse Z/X · KRNL · Fluxus · Delta · Wave · Xeno · Solara")

-- COMBAT
local combat = CreateTab("Combat", "⚔")
combat:Section("Silent Aim")
combat:Toggle("Silent Aim",      "sa_en",   function(v) F.SA_Enabled=v end)
combat:Toggle("Prediction",      "sa_pred", function(v) F.SA_Pred=v end)
combat:Toggle("Visibility Check","sa_wall", function(v) F.SA_Wall=v end)
combat:Toggle("Distance Check",  "sa_dist", function(v) F.SA_Dist=v end)
combat:Slider("FOV",    0,500,"sa_fov",  "r", function(v) F.SA_FOV=v end)
combat:Slider("Distance",25,1000,"sa_dlim","s",function(v) F.SA_DistLimit=v end)
combat:Slider("Hit Chance",0,100,"sa_hc","%",  function(v) F.SA_HitChance=v end)
combat:Dropdown("Aim Part",{"Head","HumanoidRootPart","UpperTorso","LowerTorso"},"sa_part",function(v) F.SA_Part=v end)

combat:Section("Aimbot")
combat:Toggle("Aimbot",          "ab_en",    function(v) F.AB_Enabled=v; Aimbot=v end)
combat:Toggle("Always On",       "ab_always",function(v) F.AB_Always=v end)
combat:Toggle("Prediction",      "ab_pred",  function(v) F.AB_Pred=v end)
combat:Toggle("Visibility Check","ab_wall",  function(v) F.AB_Wall=v end)
combat:Slider("Sensitivity",0,100,"ab_sens","%",function(v) F.AB_Sens=v end)
combat:Slider("FOV",0,500,"ab_fov","r",         function(v) F.AB_FOV=v end)
combat:Dropdown("Aim Part",{"Head","HumanoidRootPart","UpperTorso"},"ab_part",function(v) F.AB_Part=v end)

combat:Section("Mode")
combat:Toggle("NPC Mode","npc_mode",function(v) F.NPCMode=v end)

-- WEAPON
local weapon = CreateTab("Weapon", "🔫")
weapon:Section("Weapon")
weapon:Toggle("No Recoil",   "recoil_en",  function(v) F.Recoil=v end)
weapon:Slider("Recoil %",0,100,"recoil_val","%",function(v) F.RecoilVal=v end)
weapon:Toggle("Instant Hit", "bulletdrop", function(v) F.BulletDrop=v end)
weapon:Toggle("Unlock Modes","firemodes",  function(v) F.Firemodes=v end)
weapon:Toggle("Rapid Fire",  "rapid_en",   function(v) F.RapidFire=v end)
weapon:Slider("RPM",45,1000,"rpm_val","",  function(v) F.RPM=v end)

-- CHARACTER
local char = CreateTab("Char", "🏃")
char:Section("Character")
char:Toggle("NoClip",        "noclip",    function(v)
    F.NoClip=v
    if not v then
        for O,C in pairs(NoClipObjects) do pcall(function() O.CanCollide=C end) end
        table.clear(NoClipObjects)
    end
end)
char:Toggle("No Camera Bob", "nobob",     function(v) F.NoBob=v end)
char:Toggle("No Stamina",    "nostam",    function(v) F.NoStamina=v end)
char:Toggle("No NVG Effect", "nonvg",     function(v) F.NoNVG=v end)
char:Toggle("No NVG Shape",  "nonvgs",    function(v) F.NoNVGShape=v end)
char:Toggle("Speed Hack",    "ws_en",     function(v) F.SpeedHack=v end)
char:Slider("Speed",16,1000,"ws_val","",  function(v) F.SpeedVal=v end)
char:Toggle("Unlock 3rd Person","thirdp", function(v)
    F.ThirdPerson=v
    if ServerSettings then ServerSettings["FIRSTPERSON_LOCKED"]=not v end
    ShowToast(v and "3rd Person Unlocked!" or "3rd Person Locked", "👁")
end)

char:Section("Environment")
char:Toggle("Custom Lighting","light_en",  function(v) F.LightEnabled=v end)
char:Toggle("Full Brightness","light_br",  function(v) F.LightBright=v; Lighting.GlobalShadows=not v end)
char:Slider("Clock Time",0,24,"light_t","h",function(v) F.LightTime=v end)
char:Slider("Fog %",0,100,"light_fog","%",  function(v) F.LightFog=v end)

-- VEHICLE
local veh = CreateTab("Veh", "🚗")
veh:Section("Ground")
veh:Toggle("Enabled","veh_en",   function(v) F.VehEnabled=v end)
veh:Slider("Speed",0,1000,"veh_spd","",function(v) F.VehSpeed=v end)
veh:Slider("Accel",1,50,"veh_acc","", function(v) F.VehAcc=v end)
veh:Section("Helicopter")
veh:Toggle("Enabled","heli_en",  function(v) F.HeliEnabled=v end)
veh:Slider("Speed",0,500,"heli_spd","",function(v) F.HeliSpeed=v end)
veh:Section("Aircraft")
veh:Toggle("Speed Mod","air_en", function(v) F.AirEnabled=v end)
veh:Slider("Speed",130,950,"air_spd","",function(v) F.AirSpeed=v end)
veh:Toggle("Fly Mode","air_fly", function(v) F.AirFly=v end)
veh:Toggle("Camera Ctrl","air_cam",function(v) F.AirCam=v end)
veh:Slider("Fly Speed",145,500,"air_fspd","",function(v) F.AirFlySpeed=v end)
veh:Button("⚙ Setup Engines",function()
    local Air=RequireModule("MovementService")
    if not Air or not Air._handler or not Air._handler._main then ShowToast("Not in Aircraft!","❌"); return end
    if Network then Network:FireServer("CallInteraction","Fire","Canopy") end
    for _,sw in ipairs({"cicu","oxygen","battery","ac_r","ac_l","inverter","take_apu","apu","engine_r","engine_l","fuel_r_l","fuel_l_l","fuel_r_r","fuel_l_r"}) do
        EnableSwitch(sw)
    end
    ShowToast("Starting engines...","⚙")
    task.spawn(function()
        repeat task.wait() until Air._handler._main.APU.engine.PlaybackSpeed==1
        if Network then Network:FireServer("CallInteraction","Fire","LeftEngine"); Network:FireServer("CallInteraction","Fire","RightEngine") end
        ShowToast("Engines ready!","✅")
    end)
end,"Setting up...","⚙")
veh:Button("🔓 Unlock Camera",function()
    local Air=RequireModule("MovementService"); local CamMod=RequireModule("CameraService")
    if Air and Air._handler and Air._handler._controller then
        CamMod:Mount(Air._handler._controller,"Character"); CamMod._handler._zoom=128
        ShowToast("Camera unlocked!","🔓")
    end
end)

-- TELEPORT
local tp = CreateTab("TP", "📍")
tp:Section("Teleport")
for _,t in ipairs(Teleports) do
    tp:Button("📍 "..t[1],function() TeleportCharacter(t[2]) end,"Teleporting: "..t[1],"📍")
end

-- MISC
local misc = CreateTab("Misc", "⚙")
misc:Section("Server")
misc:Button("✨ Fake RGE",function()
    if ServerSettings and not ServerSettings.CHEATS_ENABLED then
        ServerSettings.CHEATS_ENABLED=true
        if RemoteEvent then
            for _,C in pairs(getconnections(RemoteEvent.OnClientEvent)) do C.Function("InitRGE") end
        end
        ShowToast("Fake RGE enabled!","✨")
    end
end)
misc:Button("🔄 Reset Character",function()
    if Network then Network:FireServer("ResetCharacter") end
    ShowToast("Character reset!","🔄")
end)
misc:Button("🔒 Toggle FP Lock",function()
    if ServerSettings then
        local cur=ServerSettings["FIRSTPERSON_LOCKED"]
        ServerSettings["FIRSTPERSON_LOCKED"]=not cur
        ShowToast("FP Lock: "..(not cur and "ON" or "OFF"),"🔒")
    end
end)

-- ═══ OPEN UI ═══
task.defer(function()
    task.wait(0.3)  -- Tunggu semua tab selesai dibuat
    openBtn.Visible=false
    overlay.Visible=true; overlay.BackgroundTransparency=1
    TweenService:Create(overlay,TweenInfo.new(0.4),{BackgroundTransparency=0.5}):Play()
    main.Visible=true
    main.Size=UDim2.new(0,FW*0.05,0,FH*0.05)
    main.BackgroundTransparency=1
    TweenService:Create(main,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Size=UDim2.new(0,FW,0,FH),BackgroundTransparency=0.3}):Play()
end)

ShowToast("TokaiHub x BRM5 Loaded!", "🌸")
print("[TokaiHub x BRM5] Loaded! Key: RightControl")

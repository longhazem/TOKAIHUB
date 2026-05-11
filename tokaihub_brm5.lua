--[[
    TokaiHub x BRM5
    UI: TokaiHub Library
    Logic: Parvus BRM5 (Silent Aim, Aimbot, Weapon, Character, Vehicle, Teleport...)
]]

-- ═══════════════════════════════════════════════════════════
--  TOKAIHUB UI LIBRARY (giữ nguyên hoàn toàn)
-- ═══════════════════════════════════════════════════════════

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Camera           = workspace.CurrentCamera

local startTime = os.time()
_G.ToggleKey   = Enum.KeyCode.RightControl
local isLocked = false
local DISCORD  = "https://discord.gg/nn783R2fK2"

local function GetGuiParent()
    if gethui then local ok,h=pcall(gethui) if ok and h then return h end end
    local ok,cg=pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return Players.LocalPlayer:WaitForChild("PlayerGui",5) or Players.LocalPlayer.PlayerGui
end
local function SafeCopy(text)
    if setclipboard then pcall(setclipboard,text);return end
    if toclipboard then pcall(toclipboard,text);return end
    if Clipboard and Clipboard.set then pcall(function() Clipboard.set(text) end);return end
    if syn and syn.write_clipboard then pcall(syn.write_clipboard,text) end
end
local SAVE_FILE="TokaiHubSave.json"
local function SafeWrite(name,content) pcall(function() if writefile then writefile(name,content) end end) end
local function SafeRead(name)
    local ok,data=pcall(function()
        if not isfile or not readfile then return nil end
        if not isfile(name) then return nil end
        return readfile(name)
    end)
    return (ok and type(data)=="string") and data or nil
end
local function Serialize(t)
    local parts={}
    for k,v in pairs(t) do
        local vs=type(v)=="boolean" and (v and "true" or "false") or tostring(v)
        table.insert(parts,k.."="..vs)
    end
    return table.concat(parts,";")
end
local function Deserialize(s,default)
    local t={}
    for k,v in pairs(default) do t[k]=v end
    if not s or s=="" then return t end
    for pair in s:gmatch("([^;]+)") do
        local k,v=pair:match("^(.-)=(.+)$")
        if k and v then
            if v=="true" then t[k]=true
            elseif v=="false" then t[k]=false
            else local n=tonumber(v); if n then t[k]=n end end
        end
    end
    return t
end

local DEFAULT={}
local function LoadSettings() return Deserialize(SafeRead(SAVE_FILE),DEFAULT) end
local S=LoadSettings()
local function Save() SafeWrite(SAVE_FILE,Serialize(S)) end

local function CleanupOldUI()
    local gui=GetGuiParent()
    local old=gui:FindFirstChild("TOKAIHUB"); if old then old:Destroy() end
    local oldO=gui:FindFirstChild("TOKAIHUB_OVERLAY"); if oldO then oldO:Destroy() end
end
CleanupOldUI()

local function PlayClickSound()
    local s=Instance.new("Sound"); s.SoundId="rbxassetid://126347354635406"; s.Volume=0.6
    s.Parent=SoundService; s:Play(); game:GetService("Debris"):AddItem(s,2)
end

local toastQueue,toastRunning={},false
local function ShowToast(msg,icon)
    icon=icon or "✨"
    table.insert(toastQueue,{msg=msg,icon=icon})
    if toastRunning then return end
    toastRunning=true
    coroutine.wrap(function()
        while #toastQueue>0 do
            local item=table.remove(toastQueue,1)
            local sg=Instance.new("ScreenGui",GetGuiParent())
            sg.Name="TokaiToast";sg.IgnoreGuiInset=true;sg.ResetOnSpawn=false
            local toastW=220
            local toast=Instance.new("Frame",sg)
            toast.Size=UDim2.new(0,toastW,0,38)
            toast.Position=UDim2.new(0.5,-toastW/2,0,-44)
            toast.BackgroundColor3=Color3.fromRGB(255,182,193)
            toast.BackgroundTransparency=0.08
            Instance.new("UICorner",toast).CornerRadius=UDim.new(0,12)
            local stroke=Instance.new("UIStroke",toast);stroke.Color=Color3.fromRGB(235,110,140);stroke.Thickness=1.5
            local iconBg=Instance.new("Frame",toast)
            iconBg.Size=UDim2.new(0,32,1,0);iconBg.BackgroundColor3=Color3.fromRGB(235,110,140);iconBg.BackgroundTransparency=0.2
            Instance.new("UICorner",iconBg).CornerRadius=UDim.new(0,12)
            local iconLbl=Instance.new("TextLabel",iconBg)
            iconLbl.Size=UDim2.new(1,0,1,0);iconLbl.Text=item.icon
            iconLbl.Font=Enum.Font.GothamBold;iconLbl.TextSize=16;iconLbl.BackgroundTransparency=1
            iconLbl.TextColor3=Color3.new(1,1,1)
            local msgLbl=Instance.new("TextLabel",toast)
            msgLbl.Size=UDim2.new(1,-40,1,0);msgLbl.Position=UDim2.new(0,36,0,0)
            msgLbl.Text=item.msg;msgLbl.Font=Enum.Font.GothamBold;msgLbl.TextSize=10
            msgLbl.TextColor3=Color3.fromRGB(90,45,55);msgLbl.BackgroundTransparency=1
            msgLbl.TextXAlignment=Enum.TextXAlignment.Left;msgLbl.TextWrapped=true
            TweenService:Create(toast,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
                {Position=UDim2.new(0.5,-toastW/2,0,18)}):Play()
            task.wait(2.2)
            TweenService:Create(toast,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
                {Position=UDim2.new(0.5,-toastW/2,0,-50),BackgroundTransparency=1}):Play()
            task.wait(0.35); sg:Destroy(); task.wait(0.1)
        end
        toastRunning=false
    end)()
end

local Library={}
function Library:CreateWindow()
    local screenGui=Instance.new("ScreenGui")
    screenGui.Name="TOKAIHUB"; screenGui.DisplayOrder=10
    screenGui.Parent=GetGuiParent(); screenGui.ResetOnSpawn=false; screenGui.IgnoreGuiInset=true
    do local os2=Instance.new("Sound");os2.SoundId="rbxassetid://90621979353525";os2.Volume=1
        os2.Parent=SoundService;os2:Play();game:GetService("Debris"):AddItem(os2,5) end

    local MainColor=Color3.fromRGB(255,182,193)
    local TextColor=Color3.fromRGB(90,45,55)
    local DarkPink=Color3.fromRGB(235,110,140)
    local Green=Color3.fromRGB(34,197,94)
    local Gray=Color3.fromRGB(160,160,160)

    local openBtn=Instance.new("ImageButton",screenGui)
    openBtn.Name="OpenButton";openBtn.Size=UDim2.new(0,50,0,50)
    openBtn.Position=UDim2.new(0,10,0.5,-25);openBtn.BackgroundColor3=MainColor
    openBtn.Image="rbxthumb://type=Asset&id=99217897221957&w=420&h=420";openBtn.Visible=false
    Instance.new("UICorner",openBtn).CornerRadius=UDim.new(1,0)
    local openStroke=Instance.new("UIStroke",openBtn);openStroke.Thickness=3

    local screenW=Camera.ViewportSize.X
    local FRAME_W=math.clamp(math.floor(screenW*0.88),300,390)
    local FRAME_H=240

    local main=Instance.new("Frame")
    main.Name="MainFrame";main.Size=UDim2.new(0,FRAME_W,0,FRAME_H)
    main.Position=UDim2.new(0.5,0,0.5,0);main.AnchorPoint=Vector2.new(0.5,0.5)
    main.BackgroundColor3=MainColor;main.BackgroundTransparency=0.3
    main.Parent=screenGui;main.ClipsDescendants=false;main.Visible=false
    Instance.new("UICorner",main).CornerRadius=UDim.new(0,15)
    local mainStroke=Instance.new("UIStroke",main);mainStroke.Thickness=2

    local toolbar=Instance.new("Frame",main)
    toolbar.Size=UDim2.new(0,30,0,95);toolbar.Position=UDim2.new(1,5,0,10)
    toolbar.BackgroundColor3=Color3.new(1,1,1);toolbar.BackgroundTransparency=0.5
    Instance.new("UICorner",toolbar).CornerRadius=UDim.new(0,8)
    local tbl=Instance.new("UIListLayout",toolbar)
    tbl.Padding=UDim.new(0,5);tbl.HorizontalAlignment=Enum.HorizontalAlignment.Center
    tbl.VerticalAlignment=Enum.VerticalAlignment.Center

    local function MakeToolBtn(txt,col)
        local b=Instance.new("TextButton",toolbar)
        b.Size=UDim2.new(0,22,0,22);b.BackgroundColor3=col
        b.Text=txt;b.TextColor3=Color3.new(1,1,1)
        b.Font=Enum.Font.GothamBold;b.TextSize=13
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
        local bs=Instance.new("UIStroke",b);bs.Color=Color3.new(1,1,1);bs.Thickness=1.5;bs.Transparency=0.8
        b.MouseEnter:Connect(function()
            TweenService:Create(b,TweenInfo.new(0.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,25,0,25)}):Play()
            TweenService:Create(bs,TweenInfo.new(0.15),{Transparency=0.2}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b,TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,22,0,22)}):Play()
            TweenService:Create(bs,TweenInfo.new(0.15),{Transparency=0.8}):Play()
        end)
        return b
    end
    local closeBtn=MakeToolBtn("-",Color3.fromRGB(235,80,80))
    local lockBtn=MakeToolBtn("🔓",Color3.fromRGB(80,200,80))
    local keyBtn=MakeToolBtn("⌨",DarkPink)

    local overlayGui=Instance.new("ScreenGui",GetGuiParent())
    overlayGui.Name="TOKAIHUB_OVERLAY";overlayGui.ResetOnSpawn=false
    overlayGui.IgnoreGuiInset=true;overlayGui.DisplayOrder=-1
    local overlay=Instance.new("Frame",overlayGui)
    overlay.Size=UDim2.new(1,0,1,0);overlay.BackgroundColor3=Color3.fromRGB(10,5,10)
    overlay.BackgroundTransparency=1;overlay.Visible=false;overlay.Active=false

    local activeDropdown=nil
    local isTweening=false
    local function ToggleUI()
        if isTweening then return end; isTweening=true
        if main.Visible then
            if activeDropdown then activeDropdown(true) end
            TweenService:Create(overlay,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
            TweenService:Create(main,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.In),
                {Size=UDim2.new(0,FRAME_W*0.05,0,FRAME_H*0.05),BackgroundTransparency=1}):Play()
            task.delay(0.35,function()
                main.Visible=false;main.BackgroundTransparency=0.3;overlay.Visible=false
                openBtn.Visible=true;openBtn.Size=UDim2.new(0,0,0,0)
                TweenService:Create(openBtn,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,50,0,50)}):Play()
                isTweening=false
            end)
        else
            openBtn.Visible=false;overlay.Visible=true;overlay.BackgroundTransparency=1
            TweenService:Create(overlay,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=0.5}):Play()
            main.Position=UDim2.new(0.5,0,0.5,0);main.Visible=true
            main.Size=UDim2.new(0,FRAME_W*0.05,0,FRAME_H*0.05);main.BackgroundTransparency=1
            TweenService:Create(main,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
                {Size=UDim2.new(0,FRAME_W,0,FRAME_H),BackgroundTransparency=0.3}):Play()
            task.delay(0.45,function() isTweening=false end)
        end
    end

    closeBtn.MouseButton1Click:Connect(function() PlayClickSound();ToggleUI() end)
    lockBtn.MouseButton1Click:Connect(function()
        PlayClickSound();isLocked=not isLocked
        lockBtn.Text=isLocked and "🔒" or "🔓"
        lockBtn.BackgroundColor3=isLocked and Color3.fromRGB(200,80,80) or Color3.fromRGB(80,200,80)
    end)
    local isBinding=false
    keyBtn.MouseButton1Click:Connect(function()
        if isBinding then return end
        PlayClickSound();isBinding=true;keyBtn.Text="..."
        local c;c=UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.Keyboard then
                _G.ToggleKey=inp.KeyCode;keyBtn.Text="⌨";isBinding=false;c:Disconnect()
            end
        end)
    end)

    coroutine.wrap(function()
        local cols={Color3.fromRGB(255,255,255),Color3.fromRGB(255,192,203),Color3.fromRGB(230,190,255)}
        while task.wait() do
            local t=(math.sin(tick()*2)+1)/2
            local c=cols[1]:Lerp(cols[2],t):Lerp(cols[3],(math.cos(tick()*1.5)+1)/2)
            mainStroke.Color=c;openStroke.Color=c
        end
    end)()

    local function CreateGlowBorder(phaseOffset)
        phaseOffset=phaseOffset or 0
        local border=Instance.new("Frame",screenGui)
        border.Name="__GlowBorder";border.Size=UDim2.new(0,FRAME_W,0,FRAME_H)
        border.Position=main.Position;border.AnchorPoint=Vector2.new(0.5,0.5)
        border.BackgroundTransparency=1;border.ZIndex=2;border.Active=false
        Instance.new("UICorner",border).CornerRadius=UDim.new(0,15)
        local stroke=Instance.new("UIStroke",border)
        stroke.Thickness=2;stroke.Color=Color3.new(1,1,1)
        stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
        local grad=Instance.new("UIGradient",stroke)
        grad.Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(0.5,Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1,Color3.new(1,1,1)),
        })
        grad.Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.08,0.95),
            NumberSequenceKeypoint.new(0.18,0),NumberSequenceKeypoint.new(0.32,0.95),
            NumberSequenceKeypoint.new(0.5,1),NumberSequenceKeypoint.new(0.68,0.95),
            NumberSequenceKeypoint.new(0.82,0),NumberSequenceKeypoint.new(0.92,0.95),
            NumberSequenceKeypoint.new(1,1),
        })
        coroutine.wrap(function()
            while true do
                RunService.Heartbeat:Wait()
                border.Position=main.Position;border.Visible=main.Visible
            end
        end)()
        coroutine.wrap(function()
            local rot=phaseOffset;local spd=18;local last=tick()
            while true do
                RunService.Heartbeat:Wait()
                local now=tick();local dt=now-last;last=now
                rot=(rot+spd*dt)%360;grad.Rotation=rot
            end
        end)()
    end
    task.defer(function()
        task.wait(0.1)
        for _,v in ipairs(screenGui:GetChildren()) do
            if v.Name=="__GlowBorder" then v:Destroy() end
        end
        CreateGlowBorder(0);CreateGlowBorder(180)
    end)

    openBtn.MouseButton1Click:Connect(function() PlayClickSound();ToggleUI() end)
    UserInputService.InputBegan:Connect(function(inp,gpe)
        if not gpe and inp.KeyCode==_G.ToggleKey then PlayClickSound();ToggleUI() end
    end)

    local dragLocked=false
    local function EnableDrag(obj)
        local dragging,dragInput,dragStart,startPos
        obj.InputBegan:Connect(function(inp)
            if isLocked or dragLocked then return end
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                dragging=true;dragStart=inp.Position;startPos=obj.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState==Enum.UserInputState.End then dragging=false end
                end)
            end
        end)
        obj.InputChanged:Connect(function(inp)
            if not isLocked and not dragLocked and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
                dragInput=inp
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if inp==dragInput and dragging and not isLocked and not dragLocked then
                local d=inp.Position-dragStart
                obj.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                dragging=false;dragLocked=false
            end
        end)
    end
    local function AttachScrollLock(sf)
        local touchStart=nil
        sf.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch then touchStart=inp.Position end end)
        sf.InputChanged:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.Touch and touchStart then
                local dy=math.abs(inp.Position.Y-touchStart.Y);local dx=math.abs(inp.Position.X-touchStart.X)
                if dy>dx and dy>6 then dragLocked=true end
            end
        end)
        sf.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.Touch then touchStart=nil;dragLocked=false end
        end)
    end
    EnableDrag(main);EnableDrag(openBtn)

    local sidebar=Instance.new("Frame",main)
    sidebar.Size=UDim2.new(0,35,0,200);sidebar.Position=UDim2.new(1,-40,0.5,-100)
    sidebar.BackgroundColor3=Color3.new(1,1,1);sidebar.BackgroundTransparency=0.65
    Instance.new("UICorner",sidebar).CornerRadius=UDim.new(1,0)
    local sbl=Instance.new("UIListLayout",sidebar)
    sbl.Padding=UDim.new(0,7);sbl.HorizontalAlignment=Enum.HorizontalAlignment.Center
    sbl.VerticalAlignment=Enum.VerticalAlignment.Center

    local tabContainer=Instance.new("Frame",main)
    tabContainer.Size=UDim2.new(0,335,0,215);tabContainer.Position=UDim2.new(0,8,0,10)
    tabContainer.BackgroundTransparency=1;tabContainer.ClipsDescendants=true
    local pages=Instance.new("Frame",tabContainer)
    pages.Size=UDim2.new(1,0,1,0);pages.BackgroundTransparency=1;pages.Active=false

    -- Element helpers (MakeAnimButton, MakeToggle, MakeSlider, MakeDropdown — giữ nguyên từ TokaiHub)
    local function MakeAnimButton(parent,text,yPos,callback,toastMsg,toastIcon)
        local btn=Instance.new("TextButton",parent)
        btn.Size=UDim2.new(1,-4,0,28);btn.Position=UDim2.new(0,2,0,yPos)
        btn.BackgroundColor3=Color3.fromRGB(255,255,255);btn.BackgroundTransparency=0.45
        btn.Text=text;btn.Font=Enum.Font.GothamBold;btn.TextColor3=TextColor;btn.TextSize=10
        btn.ClipsDescendants=true
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
        local stroke=Instance.new("UIStroke",btn);stroke.Color=DarkPink;stroke.Thickness=1.2
        local function SpawnRipple(ix,iy)
            local ripple=Instance.new("Frame",btn)
            local rx=ix-btn.AbsolutePosition.X;local ry=iy-btn.AbsolutePosition.Y
            local maxR=math.sqrt(btn.AbsoluteSize.X^2+btn.AbsoluteSize.Y^2)*1.5
            ripple.Size=UDim2.new(0,0,0,0);ripple.Position=UDim2.new(0,rx,0,ry)
            ripple.AnchorPoint=Vector2.new(0.5,0.5);ripple.BackgroundColor3=DarkPink
            ripple.BackgroundTransparency=0.55;ripple.ZIndex=5
            Instance.new("UICorner",ripple).CornerRadius=UDim.new(1,0)
            TweenService:Create(ripple,TweenInfo.new(0.85,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,maxR,0,maxR)}):Play()
            TweenService:Create(ripple,TweenInfo.new(0.85,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()
            game:GetService("Debris"):AddItem(ripple,0.9)
        end
        btn.MouseButton1Click:Connect(function()
            PlayClickSound();local mp=UserInputService:GetMouseLocation();SpawnRipple(mp.X,mp.Y)
            TweenService:Create(btn,TweenInfo.new(0.07,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                {Size=UDim2.new(1,-8,0,25),Position=UDim2.new(0,4,0,yPos+1.5)}):Play()
            task.delay(0.07,function()
                TweenService:Create(btn,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
                    {Size=UDim2.new(1,-4,0,28),Position=UDim2.new(0,2,0,yPos)}):Play()
            end)
            if toastMsg then ShowToast(toastMsg,toastIcon) end
            if callback then callback() end
        end)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                {BackgroundColor3=Color3.fromRGB(255,225,232),Position=UDim2.new(0,2,0,yPos-1)}):Play()
            TweenService:Create(stroke,TweenInfo.new(0.18),{Thickness=2}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                {BackgroundColor3=Color3.fromRGB(255,255,255),Position=UDim2.new(0,2,0,yPos)}):Play()
            TweenService:Create(stroke,TweenInfo.new(0.18),{Thickness=1.2}):Play()
        end)
        return btn
    end
    local function MakeToggle(parent,labelText,yPos,savedKey,onCallback)
        local state=S[savedKey] or false
        local row=Instance.new("Frame",parent)
        row.Size=UDim2.new(1,-4,0,26);row.Position=UDim2.new(0,2,0,yPos)
        row.BackgroundColor3=Color3.fromRGB(255,255,255);row.BackgroundTransparency=0.45
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)
        local rowStroke=Instance.new("UIStroke",row)
        rowStroke.Color=state and Green or Color3.fromRGB(200,200,200)
        rowStroke.Thickness=1;rowStroke.Transparency=0.5
        local lbl=Instance.new("TextLabel",row)
        lbl.Size=UDim2.new(0.7,0,1,0);lbl.Position=UDim2.new(0,8,0,0)
        lbl.Text=labelText;lbl.Font=Enum.Font.GothamBold;lbl.TextColor3=TextColor;lbl.TextSize=9
        lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.BackgroundTransparency=1
        local pill=Instance.new("Frame",row)
        pill.Size=UDim2.new(0,36,0,16);pill.Position=UDim2.new(1,-42,0.5,-8)
        pill.BackgroundColor3=state and Green or Gray
        Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
        local pillGlow=Instance.new("UIStroke",pill)
        pillGlow.Color=Green;pillGlow.Thickness=2;pillGlow.Transparency=state and 0.3 or 1
        local knob=Instance.new("Frame",pill)
        knob.Size=UDim2.new(0,12,0,12)
        knob.Position=state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
        knob.BackgroundColor3=Color3.new(1,1,1)
        Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
        local function SetState(newState)
            state=newState;S[savedKey]=state;Save()
            TweenService:Create(pill,TweenInfo.new(0.22,Enum.EasingStyle.Quad),{BackgroundColor3=state and Green or Gray}):Play()
            TweenService:Create(pillGlow,TweenInfo.new(0.25),{Transparency=state and 0.3 or 1}):Play()
            TweenService:Create(rowStroke,TweenInfo.new(0.25),{Color=state and Green or Color3.fromRGB(200,200,200)}):Play()
            local targetPos=state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
            TweenService:Create(knob,TweenInfo.new(0.08,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,10,0,14)}):Play()
            task.delay(0.08,function()
                TweenService:Create(knob,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=targetPos,Size=UDim2.new(0,12,0,12)}):Play()
            end)
            if onCallback then onCallback(state) end
        end
        local btn=Instance.new("TextButton",row)
        btn.Size=UDim2.new(1,0,1,0);btn.BackgroundTransparency=1;btn.Text=""
        btn.MouseButton1Click:Connect(function() PlayClickSound();SetState(not state) end)
        btn.MouseEnter:Connect(function() TweenService:Create(row,TweenInfo.new(0.15),{BackgroundTransparency=0.3}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(row,TweenInfo.new(0.15),{BackgroundTransparency=0.45}):Play() end)
        if state and onCallback then task.spawn(function() task.wait(1.2);onCallback(true) end) end
        return row,SetState
    end
    local function MakeSlider(parent,labelText,yPos,min,max,savedKey,suffix,onCallback)
        local value=S[savedKey] or min
        local KNOB_W=13
        local row=Instance.new("Frame",parent)
        row.Size=UDim2.new(1,-4,0,40);row.Position=UDim2.new(0,2,0,yPos)
        row.BackgroundColor3=Color3.fromRGB(255,255,255);row.BackgroundTransparency=0.45;row.ClipsDescendants=false
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)
        local lbl=Instance.new("TextLabel",row)
        lbl.Size=UDim2.new(0.6,0,0,18);lbl.Position=UDim2.new(0,8,0,2)
        lbl.Text=labelText;lbl.Font=Enum.Font.GothamBold;lbl.TextColor3=TextColor;lbl.TextSize=9
        lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.BackgroundTransparency=1
        local valLbl=Instance.new("TextLabel",row)
        valLbl.Size=UDim2.new(0.35,0,0,18);valLbl.Position=UDim2.new(0.62,0,0,2)
        valLbl.Text=tostring(value)..suffix;valLbl.Font=Enum.Font.GothamBold
        valLbl.TextColor3=DarkPink;valLbl.TextSize=9
        valLbl.TextXAlignment=Enum.TextXAlignment.Right;valLbl.BackgroundTransparency=1
        local TRACK_PAD=8+math.ceil(KNOB_W/2)
        local track=Instance.new("Frame",row)
        track.Size=UDim2.new(1,-(TRACK_PAD*2),0,6);track.Position=UDim2.new(0,TRACK_PAD,0,27)
        track.BackgroundColor3=Color3.fromRGB(220,190,200);track.ClipsDescendants=false
        Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
        local fill=Instance.new("Frame",track)
        fill.Size=UDim2.new((value-min)/(max-min),0,1,0);fill.BackgroundColor3=DarkPink
        Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
        local initPct=(value-min)/(max-min)
        local knob=Instance.new("Frame",track)
        knob.Size=UDim2.new(0,KNOB_W,0,KNOB_W)
        knob.Position=UDim2.new(initPct,-math.floor(KNOB_W*initPct),0.5,-math.ceil(KNOB_W/2))
        knob.BackgroundColor3=Color3.new(1,1,1)
        Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
        local ks=Instance.new("UIStroke",knob);ks.Color=DarkPink;ks.Thickness=1.5
        local dragging=false
        local function UpdateFromX(absX)
            local trackAbs=track.AbsolutePosition.X;local trackW=track.AbsoluteSize.X
            local pct=math.clamp((absX-trackAbs)/trackW,0,1)
            value=math.floor(min+pct*(max-min));S[savedKey]=value;Save()
            valLbl.Text=tostring(value)..suffix
            fill.Size=UDim2.new(pct,0,1,0)
            knob.Position=UDim2.new(pct,-math.floor(KNOB_W*pct),0.5,-math.ceil(KNOB_W/2))
            if onCallback then onCallback(value) end
        end
        knob.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                dragging=true;dragLocked=true
                TweenService:Create(knob,TweenInfo.new(0.1,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,KNOB_W+4,0,KNOB_W-3)}):Play()
            end
        end)
        track.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                dragging=true;dragLocked=true;UpdateFromX(inp.Position.X)
                TweenService:Create(knob,TweenInfo.new(0.1,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,KNOB_W+4,0,KNOB_W-3)}):Play()
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
                UpdateFromX(inp.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
                if dragging then TweenService:Create(knob,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,KNOB_W,0,KNOB_W)}):Play() end
                dragging=false;dragLocked=false
            end
        end)
        return row
    end
    local function MakeDropdown(parent,labelText,yPos,options,savedKey,onCallback)
        local selected=S[savedKey] or options[1]
        local isOpen=false;local ITEM_H=22;local HEAD_H=26
        local head=Instance.new("Frame",parent)
        head.Size=UDim2.new(1,-4,0,HEAD_H);head.Position=UDim2.new(0,2,0,yPos)
        head.BackgroundColor3=Color3.fromRGB(255,255,255);head.BackgroundTransparency=0.4;head.ClipsDescendants=false
        Instance.new("UICorner",head).CornerRadius=UDim.new(0,7)
        local headStroke=Instance.new("UIStroke",head);headStroke.Color=DarkPink;headStroke.Thickness=1.2
        local lbl=Instance.new("TextLabel",head)
        lbl.Size=UDim2.new(0,0,1,0);lbl.AutomaticSize=Enum.AutomaticSize.X;lbl.Position=UDim2.new(0,8,0,0)
        lbl.Text=labelText;lbl.Font=Enum.Font.GothamBold;lbl.TextColor3=TextColor;lbl.TextSize=9
        lbl.TextXAlignment=Enum.TextXAlignment.Left;lbl.BackgroundTransparency=1
        local pillBg=Instance.new("Frame",head)
        pillBg.Size=UDim2.new(0,0,0,18);pillBg.AutomaticSize=Enum.AutomaticSize.X
        pillBg.Position=UDim2.new(1,-24,0.5,-9);pillBg.BackgroundColor3=Color3.fromRGB(255,210,225)
        pillBg.BackgroundTransparency=0.2;Instance.new("UICorner",pillBg).CornerRadius=UDim.new(1,0)
        local pillPad=Instance.new("UIPadding",pillBg);pillPad.PaddingLeft=UDim.new(0,6);pillPad.PaddingRight=UDim.new(0,6)
        local valLbl=Instance.new("TextLabel",pillBg)
        valLbl.Size=UDim2.new(0,0,1,0);valLbl.AutomaticSize=Enum.AutomaticSize.X
        valLbl.Text=selected;valLbl.Font=Enum.Font.GothamBold;valLbl.TextColor3=DarkPink;valLbl.TextSize=8;valLbl.BackgroundTransparency=1
        task.defer(function() local pw=pillBg.AbsoluteSize.X;pillBg.Position=UDim2.new(1,-(pw+22),0.5,-9) end)
        local arrow=Instance.new("TextLabel",head)
        arrow.Size=UDim2.new(0,16,1,0);arrow.Position=UDim2.new(1,-18,0,0)
        arrow.Text="V";arrow.Font=Enum.Font.GothamBold;arrow.TextColor3=DarkPink;arrow.TextSize=9;arrow.BackgroundTransparency=1
        local listFrame=Instance.new("Frame",screenGui)
        listFrame.BackgroundColor3=Color3.fromRGB(255,243,247);listFrame.BackgroundTransparency=0.0
        listFrame.Visible=false;listFrame.ZIndex=20;listFrame.ClipsDescendants=true
        Instance.new("UICorner",listFrame).CornerRadius=UDim.new(0,8)
        local listStroke=Instance.new("UIStroke",listFrame);listStroke.Color=DarkPink;listStroke.Thickness=1.0;listStroke.Transparency=0.4
        local function CloseList(instant)
            if not isOpen then return end;isOpen=false;activeDropdown=nil
            TweenService:Create(arrow,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Rotation=0}):Play()
            TweenService:Create(headStroke,TweenInfo.new(0.15),{Transparency=0}):Play()
            if instant then listFrame.Visible=false
            else
                local w=listFrame.AbsoluteSize.X
                TweenService:Create(listFrame,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,w,0,0)}):Play()
                task.delay(0.2,function() listFrame.Visible=false end)
            end
        end
        local function OpenList()
            if activeDropdown and activeDropdown~=CloseList then activeDropdown(true) end
            activeDropdown=CloseList;isOpen=true
            local absPos=head.AbsolutePosition;local absSize=head.AbsoluteSize
            local totalH=#options*ITEM_H+6;local listW=absSize.X
            for _,c in pairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for i,opt in ipairs(options) do
                local item=Instance.new("TextButton",listFrame)
                item.Size=UDim2.new(1,0,0,ITEM_H);item.Position=UDim2.new(0,0,0,(i-1)*ITEM_H+3)
                item.BackgroundColor3=opt==selected and Color3.fromRGB(255,215,228) or Color3.fromRGB(255,248,251)
                item.BackgroundTransparency=opt==selected and 0.0 or 1
                item.Font=Enum.Font.GothamBold;item.TextColor3=opt==selected and DarkPink or TextColor
                item.TextSize=9;item.TextXAlignment=Enum.TextXAlignment.Left;item.ZIndex=21;item.Text=""
                local pad=Instance.new("UIPadding",item);pad.PaddingLeft=UDim.new(0,10)
                if i==1 or i==#options then Instance.new("UICorner",item).CornerRadius=UDim.new(0,8) end
                local chk=Instance.new("TextLabel",item);chk.Size=UDim2.new(0,12,1,0);chk.Text=opt==selected and "✓" or ""
                chk.Font=Enum.Font.GothamBold;chk.TextSize=8;chk.TextColor3=DarkPink;chk.BackgroundTransparency=1;chk.ZIndex=22
                local txt=Instance.new("TextLabel",item);txt.Size=UDim2.new(1,-14,1,0);txt.Position=UDim2.new(0,14,0,0)
                txt.Text=opt;txt.Font=Enum.Font.GothamBold;txt.TextSize=9
                txt.TextColor3=opt==selected and DarkPink or TextColor
                txt.TextXAlignment=Enum.TextXAlignment.Left;txt.BackgroundTransparency=1;txt.ZIndex=22
                item.MouseEnter:Connect(function()
                    if opt~=selected then TweenService:Create(item,TweenInfo.new(0.1),{BackgroundTransparency=0.5,BackgroundColor3=Color3.fromRGB(255,228,238)}):Play();txt.TextColor3=DarkPink end
                end)
                item.MouseLeave:Connect(function()
                    if opt~=selected then TweenService:Create(item,TweenInfo.new(0.1),{BackgroundTransparency=1,BackgroundColor3=Color3.fromRGB(255,248,251)}):Play();txt.TextColor3=TextColor end
                end)
                item.MouseButton1Click:Connect(function()
                    PlayClickSound();selected=opt;S[savedKey]=selected;Save();valLbl.Text=selected
                    task.defer(function() local pw=pillBg.AbsoluteSize.X;pillBg.Position=UDim2.new(1,-(pw+22),0.5,-9) end)
                    TweenService:Create(item,TweenInfo.new(0.07),{BackgroundColor3=Color3.fromRGB(200,255,215)}):Play()
                    task.delay(0.07,function() CloseList(false) end)
                    if onCallback then onCallback(selected) end
                    ShowToast("Đã chọn: "..selected,"✅")
                end)
            end
            listFrame.Size=UDim2.new(0,listW,0,0);listFrame.Position=UDim2.new(0,absPos.X,0,absPos.Y+absSize.Y+4);listFrame.Visible=true
            TweenService:Create(arrow,TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Rotation=180}):Play()
            TweenService:Create(headStroke,TweenInfo.new(0.15),{Transparency=0.3}):Play()
            TweenService:Create(listFrame,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,listW,0,totalH)}):Play()
        end
        local headBtn=Instance.new("TextButton",head);headBtn.Size=UDim2.new(1,0,1,0);headBtn.BackgroundTransparency=1;headBtn.Text="";headBtn.ZIndex=10
        headBtn.MouseButton1Click:Connect(function() PlayClickSound();if isOpen then CloseList(false) else OpenList() end end)
        headBtn.MouseEnter:Connect(function() TweenService:Create(head,TweenInfo.new(0.15),{BackgroundTransparency=0.25}):Play() end)
        headBtn.MouseLeave:Connect(function() TweenService:Create(head,TweenInfo.new(0.15),{BackgroundTransparency=0.4}):Play() end)
        return head
    end

    function Library:CreateTab(name,iconText)
        local page=Instance.new("ScrollingFrame",pages)
        page.Name=name.."Page";page.Size=UDim2.new(1,0,1,0);page.BackgroundTransparency=1;page.Visible=false
        page.ScrollBarThickness=0;page.CanvasSize=UDim2.new(0,0,0,0);page.AutomaticCanvasSize=Enum.AutomaticSize.Y
        page.ScrollingDirection=Enum.ScrollingDirection.Y;page.ElasticBehavior=Enum.ElasticBehavior.Never
        page.ScrollingEnabled=true;page.ClipsDescendants=true;AttachScrollLock(page)

        local tabBtn=Instance.new("TextButton",sidebar)
        tabBtn.Size=UDim2.new(0,27,0,27);tabBtn.BackgroundColor3=DarkPink
        tabBtn.BackgroundTransparency=0.2;tabBtn.Text=iconText or name:sub(1,1)
        tabBtn.TextScaled=true;tabBtn.Font=Enum.Font.GothamBold;tabBtn.TextColor3=Color3.new(1,1,1)
        Instance.new("UICorner",tabBtn).CornerRadius=UDim.new(1,0)
        local tabStroke=Instance.new("UIStroke",tabBtn);tabStroke.Color=Color3.new(1,1,1);tabStroke.Thickness=2;tabStroke.Transparency=1;tabStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

        tabBtn.MouseButton1Click:Connect(function()
            if page.Visible then return end;PlayClickSound()
            if activeDropdown then activeDropdown(true) end
            for _,v in pairs(pages:GetChildren()) do
                if v:IsA("ScrollingFrame") and v.Visible then
                    local tw=TweenService:Create(v,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.new(-0.15,0,0,0)})
                    tw:Play();task.delay(0.18,function() v.Visible=false;v.Position=UDim2.new(0,0,0,0) end)
                end
            end
            for _,b in pairs(sidebar:GetChildren()) do
                if b:IsA("TextButton") then
                    TweenService:Create(b,TweenInfo.new(0.15),{BackgroundTransparency=0.2}):Play()
                    local s=b:FindFirstChildOfClass("UIStroke");if s then TweenService:Create(s,TweenInfo.new(0.15),{Transparency=1}):Play() end
                end
            end
            task.delay(0.12,function()
                page.Position=UDim2.new(0.15,0,0,0);page.Visible=true
                TweenService:Create(page,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0,0)}):Play()
            end)
            TweenService:Create(tabBtn,TweenInfo.new(0.15),{BackgroundTransparency=0}):Play()
            TweenService:Create(tabStroke,TweenInfo.new(0.2),{Transparency=0}):Play()
            TweenService:Create(tabBtn,TweenInfo.new(0.08,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,23,0,23)}):Play()
            task.delay(0.08,function() TweenService:Create(tabBtn,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,27,0,27)}):Play() end)
        end)

        local yOffset=4
        local elements={}

        function elements:AddSection(text)
            local lbl=Instance.new("TextLabel",page)
            lbl.Size=UDim2.new(1,-4,0,18);lbl.Position=UDim2.new(0,2,0,yOffset)
            lbl.Text="── "..text.." ──";lbl.Font=Enum.Font.GothamBold
            lbl.TextColor3=DarkPink;lbl.TextSize=9;lbl.BackgroundTransparency=1
            yOffset=yOffset+22
        end
        function elements:AddButton(text,callback,toastMsg,toastIcon)
            MakeAnimButton(page,text,yOffset,callback,toastMsg,toastIcon);yOffset=yOffset+32
        end
        function elements:AddToggle(text,savedKey,callback)
            local _,setter=MakeToggle(page,text,yOffset,savedKey,callback);yOffset=yOffset+30
            return setter
        end
        function elements:AddSlider(text,min,max,savedKey,suffix,callback)
            MakeSlider(page,text,yOffset,min,max,savedKey,suffix or "",callback);yOffset=yOffset+44
        end
        function elements:AddDropdown(text,options,savedKey,callback)
            MakeDropdown(page,text,yOffset,options,savedKey,callback);yOffset=yOffset+32
        end
        function elements:AddCreation()
            local card=Instance.new("Frame",page)
            card.Size=UDim2.new(1,0,0,52);card.Position=UDim2.new(0,0,0,yOffset)
            card.BackgroundColor3=Color3.fromRGB(255,255,255);card.BackgroundTransparency=0.42
            Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
            local cstroke=Instance.new("UIStroke",card);cstroke.Color=DarkPink;cstroke.Thickness=1.2
            local bar=Instance.new("Frame",card);bar.Size=UDim2.new(0,5,1,0);bar.BackgroundColor3=DarkPink;bar.BackgroundTransparency=0.15
            Instance.new("UICorner",bar).CornerRadius=UDim.new(0,10)
            local title=Instance.new("TextLabel",card);title.Size=UDim2.new(1,-14,0,18);title.Position=UDim2.new(0,10,0,5)
            title.Text="✦ TokaiHub x BRM5";title.Font=Enum.Font.GothamBold;title.TextColor3=DarkPink;title.TextSize=11
            title.TextXAlignment=Enum.TextXAlignment.Left;title.BackgroundTransparency=1
            local names=Instance.new("TextLabel",card);names.Size=UDim2.new(1,-14,0,14);names.Position=UDim2.new(0,10,0,23)
            names.Text="longtokai  ·  zentakt";names.Font=Enum.Font.GothamBold;names.TextColor3=TextColor;names.TextSize=10
            names.TextXAlignment=Enum.TextXAlignment.Left;names.BackgroundTransparency=1
            local sub=Instance.new("TextLabel",card);sub.Size=UDim2.new(1,-14,0,12);sub.Position=UDim2.new(0,10,0,37)
            sub.Text="UI Library + BRM5 Logic";sub.Font=Enum.Font.Gotham;sub.TextColor3=Color3.fromRGB(160,100,120);sub.TextSize=7
            sub.TextXAlignment=Enum.TextXAlignment.Left;sub.BackgroundTransparency=1
            yOffset=yOffset+56
        end
        function elements:AddDashboard()
            local ROW_H=108;local GAP=6
            local function CreateBox(size,pos)
                local box=Instance.new("Frame",page);box.Size=size;box.Position=pos
                box.BackgroundColor3=Color3.fromRGB(255,255,255);box.BackgroundTransparency=0.55
                Instance.new("UICorner",box).CornerRadius=UDim.new(0,10);return box
            end
            local userBox=CreateBox(UDim2.new(0.605,-3,0,ROW_H),UDim2.new(0,0,0,yOffset))
            local pfp=Instance.new("ImageLabel",userBox);pfp.Size=UDim2.new(0,52,0,52);pfp.Position=UDim2.new(0,8,0.5,-26)
            pfp.Image=Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
            pfp.BackgroundTransparency=1;Instance.new("UICorner",pfp).CornerRadius=UDim.new(1,0)
            local g2=Instance.new("TextLabel",userBox);g2.Size=UDim2.new(0.52,0,0.35,0);g2.Position=UDim2.new(0,68,0.3,0)
            g2.Text=Players.LocalPlayer.DisplayName;g2.Font=Enum.Font.GothamBold;g2.TextColor3=DarkPink;g2.TextSize=13
            g2.TextXAlignment=Enum.TextXAlignment.Left;g2.BackgroundTransparency=1
            local g3=Instance.new("TextLabel",userBox);g3.Size=UDim2.new(0.52,0,0.22,0);g3.Position=UDim2.new(0,68,0.66,0)
            g3.Text="TokaiHub x BRM5";g3.Font=Enum.Font.Gotham;g3.TextColor3=Color3.fromRGB(160,100,120);g3.TextSize=7
            g3.TextXAlignment=Enum.TextXAlignment.Left;g3.BackgroundTransparency=1
            local aboutBox=CreateBox(UDim2.new(0.385,-3,0,ROW_H),UDim2.new(0.615,0,0,yOffset))
            local ad=Instance.new("TextLabel",aboutBox);ad.Size=UDim2.new(0.9,0,0.6,0);ad.Position=UDim2.new(0.05,0,0.1,0)
            ad.Text="BRM5 Hub\nSilent Aim · Aimbot · Weapon\nCharacter · Vehicle · Teleport"
            ad.Font=Enum.Font.Gotham;ad.TextColor3=TextColor;ad.TextSize=7;ad.TextWrapped=true
            ad.TextXAlignment=Enum.TextXAlignment.Left;ad.BackgroundTransparency=1
            local clockBox=CreateBox(UDim2.new(1,0,0,ROW_H),UDim2.new(0,0,0,yOffset+ROW_H+GAP))
            local timeLabel=Instance.new("TextLabel",clockBox);timeLabel.Size=UDim2.new(0.5,0,0,28);timeLabel.Position=UDim2.new(0,8,0,4)
            timeLabel.Font=Enum.Font.GothamBold;timeLabel.TextSize=22;timeLabel.TextColor3=TextColor;timeLabel.BackgroundTransparency=1
            timeLabel.TextXAlignment=Enum.TextXAlignment.Left
            local dateLabel=Instance.new("TextLabel",clockBox);dateLabel.Size=UDim2.new(0.9,0,0,13);dateLabel.Position=UDim2.new(0,8,0,34)
            dateLabel.Font=Enum.Font.GothamBold;dateLabel.TextSize=7;dateLabel.TextColor3=DarkPink;dateLabel.BackgroundTransparency=1
            dateLabel.TextXAlignment=Enum.TextXAlignment.Left
            task.spawn(function()
                while task.wait(1) do
                    timeLabel.Text=os.date("%I:%M:%S");dateLabel.Text=os.date("%A, %B %d — via TokaiHub x BRM5")
                end
            end)
            yOffset=yOffset+ROW_H*2+GAP+8
        end

        if name=="Home" then
            page.Visible=true
            TweenService:Create(tabBtn,TweenInfo.new(0.1),{BackgroundTransparency=0}):Play()
            TweenService:Create(tabStroke,TweenInfo.new(0.2),{Transparency=0}):Play()
        end
        return elements
    end

    task.defer(function()
        task.wait(0.05)
        openBtn.Visible=false;overlay.Visible=true;overlay.BackgroundTransparency=1
        TweenService:Create(overlay,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=0.5}):Play()
        main.Visible=true;main.Size=UDim2.new(0,FRAME_W*0.05,0,FRAME_H*0.05);main.BackgroundTransparency=1
        TweenService:Create(main,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,FRAME_W,0,FRAME_H),BackgroundTransparency=0.3}):Play()
    end)
    return Library
end

-- ═══════════════════════════════════════════════════════════
--  BRM5 LOGIC (từ Parvus, thay Window.Flags bằng biến local)
-- ═══════════════════════════════════════════════════════════

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")

local Packages     = ReplicatedStorage:WaitForChild("Packages")
local Events       = ReplicatedStorage:WaitForChild("Events")
local RemoteEvent  = Events:WaitForChild("RemoteEvent")
local Server       = require(Packages:WaitForChild("server"))
local ServerSettings = Server._cache

local LocalPlayer  = Players.LocalPlayer
local SilentAim, Aimbot, Trigger = nil, false, false
local Actors, RoundInterface, Network = nil, nil, nil
local NPCFolder    = workspace:WaitForChild("Bots")
local RaycastFolder = workspace:WaitForChild("Raycast")
local ProjectileSpeed   = 1000
local ProjectileGravity = Vector3.new(0, workspace.Gravity, 0)
local GravityCorrection = 2
local GroundTip, AircraftTip = nil, nil
local NoClipEvent, NoClipObjects = nil, {}
local WhiteColor = Color3.new(1,1,1)

local Teleports = {
    {"Forward Operating Base", Vector3.new(-3993,64,757)},
    {"Communications Tower",   Vector3.new(-1800,785,-4140)},
    {"Department Of Utilities",Vector3.new(-54,63,-3645)},
    {"Vietnama Village",       Vector3.new(739,118,-92)},
    {"Fort Ronograd",          Vector3.new(6359,190,-1468)},
    {"Ronograd City",          Vector3.new(3478,176,1073)},
    {"Sochraina City",         Vector3.new(93,26,3630)},
    {"El Chara",               Vector3.new(-4768,108,5218)},
    {"Naval Docks",            Vector3.new(6174,130,2099)},
    {"Quarry",                 Vector3.new(331,86,2598)},
    {"Nuclear Silo",           Vector3.new(1024,44,-5148)},
}

local KnownBodyParts = {
    {"Head",true},{"HumanoidRootPart",true},
    {"UpperTorso",false},{"LowerTorso",false},
    {"RightUpperArm",false},{"RightLowerArm",false},{"RightHand",false},
    {"LeftUpperArm",false},{"LeftLowerArm",false},{"LeftHand",false},
    {"RightUpperLeg",false},{"RightLowerLeg",false},{"RightFoot",false},
    {"LeftUpperLeg",false},{"LeftLowerLeg",false},{"LeftFoot",false},
}

-- Flags (thay thế Window.Flags)
local F = {
    -- Silent Aim
    ["SilentAim/Enabled"]        = false,
    ["SilentAim/TeamCheck"]      = false,
    ["SilentAim/VisibilityCheck"]= false,
    ["SilentAim/DistanceCheck"]  = false,
    ["SilentAim/DistanceLimit"]  = 250,
    ["SilentAim/FOV/Radius"]     = 100,
    ["SilentAim/Priority"]       = {"Closest"},
    ["SilentAim/BodyParts"]      = {"Head","HumanoidRootPart"},
    ["SilentAim/HitChance"]      = 100,
    ["SilentAim/Prediction"]     = false,
    -- Aimbot
    ["Aimbot/Enabled"]           = false,
    ["Aimbot/AlwaysEnabled"]     = false,
    ["Aimbot/TeamCheck"]         = false,
    ["Aimbot/VisibilityCheck"]   = false,
    ["Aimbot/DistanceCheck"]     = false,
    ["Aimbot/DistanceLimit"]     = 250,
    ["Aimbot/FOV/Radius"]        = 100,
    ["Aimbot/Priority"]          = {"Closest"},
    ["Aimbot/BodyParts"]         = {"Head","HumanoidRootPart"},
    ["Aimbot/Sensitivity"]       = 20,
    ["Aimbot/Prediction"]        = false,
    -- Weapon
    ["BRM5/Recoil/Enabled"]      = false,
    ["BRM5/Recoil/Value"]        = 0,
    ["BRM5/BulletDrop"]          = false,
    ["BRM5/Firemodes"]           = false,
    ["BRM5/RapidFire/Enabled"]   = false,
    ["BRM5/RapidFire/Value"]     = 1000,
    -- Character
    ["BRM5/NoClip"]              = false,
    ["BRM5/NoBob"]               = false,
    ["BRM5/NoStamina"]           = false,
    ["BRM5/DisableNVG"]          = false,
    ["BRM5/NVGShape"]            = false,
    ["BRM5/WalkSpeed/Enabled"]   = false,
    ["BRM5/WalkSpeed/Value"]     = 120,
    -- 3rd Person
    ["BRM5/ThirdPerson"]         = false,
    -- Vehicle
    ["BRM5/Vehicle/Enabled"]     = false,
    ["BRM5/Vehicle/Speed"]       = 100,
    ["BRM5/Vehicle/Acceleration"]= 1,
    ["BRM5/Helicopter/Enabled"]  = false,
    ["BRM5/Helicopter/Speed"]    = 200,
    ["BRM5/Aircraft/Enabled"]    = false,
    ["BRM5/Aircraft/Speed"]      = 130,
    ["BRM5/Aircraft/FlyEnabled"] = false,
    ["BRM5/Aircraft/Camera"]     = false,
    ["BRM5/Aircraft/FlySpeed"]   = 200,
    -- NPC
    ["BRM5/NPCMode"]             = true,
    -- Lighting
    ["BRM5/Lighting/Enabled"]    = false,
    ["BRM5/Lighting/Brightness"] = false,
    ["BRM5/Lighting/Time"]       = 12,
    ["BRM5/Lighting/Fog"]        = 0.255,
}

local XZ=Vector3.new(1,0,1);local YP=Vector3.new(0,1,0);local YM=Vector3.new(0,-1,0)
local function FixUnit(v) if v.Magnitude==0 then return Vector3.zero end return v.Unit end
local function FlatCameraVector(cf) return cf.LookVector*XZ,cf.RightVector*XZ end
local function InputToVelocity()
    local lv,rv=FlatCameraVector(Camera.CFrame)
    return FixUnit(
        (UserInputService:IsKeyDown(Enum.KeyCode.W) and lv or Vector3.zero)+
        (UserInputService:IsKeyDown(Enum.KeyCode.S) and -lv or Vector3.zero)+
        (UserInputService:IsKeyDown(Enum.KeyCode.A) and -rv or Vector3.zero)+
        (UserInputService:IsKeyDown(Enum.KeyCode.D) and rv or Vector3.zero)+
        (UserInputService:IsKeyDown(Enum.KeyCode.Space) and YP or Vector3.zero)+
        (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and YM or Vector3.zero)
    )
end

local WallCheckParams=RaycastParams.new()
WallCheckParams.FilterType=Enum.RaycastFilterType.Blacklist
WallCheckParams.IgnoreWater=true
local function Raycast(Origin,Direction,Filter)
    WallCheckParams.FilterDescendantsInstances=Filter
    return workspace:Raycast(Origin,Direction,WallCheckParams)
end
local function GetTeam(Player)
    if not RoundInterface then return nil end
    for TeamName,TeamData in pairs(RoundInterface.Teams) do
        for UserId,_ in pairs(TeamData.Players) do
            if tonumber(UserId)==Player.UserId then return TeamName end
        end
    end
end
local function InEnemyTeam(Enabled,Player)
    if not Enabled then return true end
    return not Player.Neutral and LocalPlayer.Team~=Player.Team
        or GetTeam(LocalPlayer)~=GetTeam(Player)
end
local function IsDistanceLimited(Enabled,Distance,Limit)
    if not Enabled then return end
    return Distance>=Limit
end
local function IsVisible(Enabled,Origin,Position,Character)
    if not Enabled then return true end
    return not Raycast(Origin,Position-Origin,{Character,RaycastFolder,LocalPlayer.Character})
end
local function SolveTrajectory(Origin,Velocity,Time,Gravity)
    return Origin+Velocity*Time+Gravity*Time*Time/GravityCorrection
end

local function GetClosest(Enabled,TeamCheck,VisibilityCheck,DistanceCheck,DistanceLimit,FieldOfView,Priority,BodyParts,PredictionEnabled,NPCMode)
    if not Enabled then return end
    if not Actors then return end
    local CameraPosition,Closest=Camera.CFrame.Position,nil
    for _,Actor in pairs(Actors) do
        local Player=Actor.Player
        if Player==LocalPlayer then continue end
        local Character=Actor.Character;local Humanoid=Actor.Humanoid;local RootPart=Actor.RootPart
        if Humanoid.Health<=0 then continue end
        if NPCMode then
            if Actor._isPlayer then continue end
            local rra=RootPart:FindFirstChild("RootRigAttachment")
            if not rra then continue end
            if not RootPart:FindFirstChild("AlignOrientation") then continue end
            if rra:FindFirstChildOfClass("ProximityPrompt") then continue end
        else
            if not Actor._isPlayer then continue end
            if not InEnemyTeam(TeamCheck,Player) then continue end
        end
        for _,BodyPart in ipairs(BodyParts) do
            local bp=Character:FindFirstChild(BodyPart);if not bp then continue end
            local bpp=bp.Position
            local Distance=(bpp-CameraPosition).Magnitude
            if IsDistanceLimited(DistanceCheck,Distance,DistanceLimit) then continue end
            if not IsVisible(VisibilityCheck,CameraPosition,bpp,Character) then continue end
            bpp=PredictionEnabled and SolveTrajectory(bpp,bp.AssemblyLinearVelocity,Distance/ProjectileSpeed,ProjectileGravity) or bpp
            local sp,onScreen=Camera:WorldToViewportPoint(bpp);if not onScreen then continue end
            local mag=(Vector2.new(sp.X,sp.Y)-UserInputService:GetMouseLocation()).Magnitude
            if mag>=FieldOfView then continue end
            if Priority=="Random" then
                Priority=KnownBodyParts[math.random(#KnownBodyParts)][1]
                bp=Character:FindFirstChild(Priority);if not bp then continue end
                bpp=PredictionEnabled and SolveTrajectory(bp.Position,bp.AssemblyLinearVelocity,Distance/ProjectileSpeed,ProjectileGravity) or bp.Position
                sp,onScreen=Camera:WorldToViewportPoint(bpp)
            elseif Priority~="Closest" then
                bp=Character:FindFirstChild(Priority);if not bp then continue end
                bpp=PredictionEnabled and SolveTrajectory(bp.Position,bp.AssemblyLinearVelocity,Distance/ProjectileSpeed,ProjectileGravity) or bp.Position
                sp,onScreen=Camera:WorldToViewportPoint(bpp)
            end
            FieldOfView,Closest=mag,{Player,Character,bp,sp}
        end
    end
    return Closest
end
local function AimAt(Hitbox,Sensitivity)
    if not Hitbox then return end
    local ml=UserInputService:GetMouseLocation()
    mousemoverel((Hitbox[4].X-ml.X)*Sensitivity,(Hitbox[4].Y-ml.Y)*Sensitivity)
end

function RequireModule(Name)
    local sources={}
    if getmodules then for _,m in pairs(getmodules()) do table.insert(sources,m) end end
    if getloadedmodules then for _,m in pairs(getloadedmodules()) do table.insert(sources,m) end end
    for _,inst in ipairs(sources) do
        if inst.Name==Name then local ok,res=pcall(require,inst);if ok and res then return res end end
    end
end
local function HookFunction(ModuleName,Function,Hook)
    task.spawn(function()
        local Module,Old=nil,nil
        while task.wait() do
            Module=RequireModule(ModuleName)
            if Module and Module[Function] then Old=Module[Function];break end
        end
        Module[Function]=function(...) return Hook(Old,...) end
    end)
end
local function HookSignal(Signal,Index,Hook)
    local Connection=getconnections(Signal)[Index];if not Connection then return end
    local OldConnection=Connection.Function;if not OldConnection then return end
    Connection:Disable()
    Signal:Connect(function(...) return Hook(OldConnection,...) end)
end

local function AircraftFly(Self,Enabled,Speed,CameraControl)
    if not Enabled then return end
    Self._force.MaxForce=Vector3.new(1,1,1)*40000000
    Self._force.Velocity=InputToVelocity()*Speed
    if CameraControl then
        Self._gyro.MaxTorque=Vector3.new(1,1,1)*4000
        Self._gyro.CFrame=Camera.CFrame*CFrame.Angles(0,math.pi,0)
    end
end

local function TeleportModule(Position,Velocity)
    local PrimaryPart=LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
    if not PrimaryPart then return end
    local TPModule={}
    local AlignPosition=Instance.new("AlignPosition")
    AlignPosition.Mode=Enum.PositionAlignmentMode.OneAttachment
    AlignPosition.Attachment0=PrimaryPart.RootRigAttachment
    local AlignOrientation=Instance.new("AlignOrientation")
    AlignOrientation.Mode=Enum.OrientationAlignmentMode.OneAttachment
    AlignOrientation.Attachment0=PrimaryPart.RootRigAttachment
    AlignPosition.MaxVelocity=Velocity;AlignPosition.Position=Position
    AlignPosition.Parent=PrimaryPart;AlignOrientation.Parent=PrimaryPart
    function TPModule:Update(p,v) AlignPosition.MaxVelocity=v;AlignPosition.Position=p end
    function TPModule:Wait()
        while task.wait() do if (PrimaryPart.Position-AlignPosition.Position).Magnitude<5 then break end end
    end
    function TPModule:Destroy() TPModule:Wait();AlignPosition:Destroy();AlignOrientation:Destroy() end
    return TPModule
end
function TeleportCharacter(Position)
    local PrimaryPart=LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
    if not PrimaryPart then return end
    local OldNC=F["BRM5/NoClip"];F["BRM5/NoClip"]=true
    LocalPlayer.Character.Humanoid.Sit=true
    PrimaryPart.CFrame=CFrame.new(PrimaryPart.Position+Vector3.new(0,500,0))
    local TP=TeleportModule(Position+Vector3.new(0,500,0),500)
    TP:Destroy();PrimaryPart.CFrame=CFrame.new(Position)
    LocalPlayer.Character.Humanoid.Sit=false;F["BRM5/NoClip"]=OldNC
end
function EnableSwitch(Switch)
    local CameraMod=RequireModule("CameraService");if not CameraMod or not CameraMod._handler._buttons then return end
    for _,Switches in pairs(CameraMod._handler._buttons) do
        if Switches._id==Switch then
            Switches:Update();Switches:Select()
            CameraMod._switch=Switches;CameraMod._switch:Activate();CameraMod._switch:Unselect()
        end
    end
end

-- Hooks
HookFunction("ControllerClass","LateUpdate",function(Old,Self,...)
    if F["BRM5/WalkSpeed/Enabled"] then Self.Speed=F["BRM5/WalkSpeed/Value"] end
    return Old(Self,...)
end)
HookFunction("ViewmodelClass","Update",function(Old,Self,...)
    local Args={...}
    if F["BRM5/WalkSpeed/Enabled"] and Args[2] then Args[2]=CFrame.new(Args[2].Position) end
    return Old(Self,table.unpack(Args))
end)
HookFunction("CharacterCamera","Update",function(Old,Self,...)
    if F["BRM5/NoBob"] then Self._bob=0 end
    if F["BRM5/Recoil/Enabled"] then Self._recoil.Velocity=Self._recoil.Velocity*(F["BRM5/Recoil/Value"]/100) end
    return Old(Self,...)
end)
HookFunction("FirearmInventory","_firemode",function(Old,Self,...)
    if F["BRM5/Firemodes"] then
        local c=Self._config
        if not table.find(c.Tune.Firemodes,1) then table.insert(c.Tune.Firemodes,1) end
        if not table.find(c.Tune.Firemodes,2) then table.insert(c.Tune.Firemodes,2) end
        if not table.find(c.Tune.Firemodes,3) then table.insert(c.Tune.Firemodes,3) end
    end
    return Old(Self,...)
end)
HookFunction("FirearmInventory","_discharge",function(Old,Self,...)
    if F["BRM5/RapidFire/Enabled"] then Self._config.Tune.RPM=F["BRM5/RapidFire/Value"] end
    if F["BRM5/BulletDrop"] then Self._velocity=1e6;Self._range=1e6 end
    ProjectileSpeed=Self._velocity;return Old(Self,...)
end)
HookFunction("CharacterMovement","Update",function(Old,Self,...)
    if F["BRM5/NoStamina"] then Self._exhausted=0 end
    return Old(Self,...)
end)
HookFunction("TurretMovement","_discharge",function(Old,Self,...)
    if F["BRM5/BulletDrop"] then Self._tune.Velocity=1e6;Self._tune.Range=1e6 end
    ProjectileSpeed=Self._tune.Velocity;GroundTip=Self._tip;return Old(Self,...)
end)
HookFunction("AircraftMovement","_discharge",function(Old,Self,...)
    if F["BRM5/BulletDrop"] then Self._tune.Velocity=1e6;Self._tune.Range=1e6 end
    ProjectileSpeed=Self._tune.Velocity;AircraftTip=Self._tip;return Old(Self,...)
end)
HookFunction("GroundMovement","Update",function(Old,Self,...)
    if F["BRM5/Vehicle/Enabled"] then
        local Args={...};local ReturnArgs={Old(Self,...)}
        for _,Motor in pairs(Self._motors.f) do
            Motor.MotorMaxTorque=200000*F["BRM5/Vehicle/Speed"]
            Motor.AngularVelocity=(-Args[2].Y*F["BRM5/Vehicle/Speed"])
        end
        for _,Motor in pairs(Self._motors.b) do
            Motor.MotorMaxTorque=200000*F["BRM5/Vehicle/Speed"]
            Motor.AngularVelocity=-(-Args[2].Y*F["BRM5/Vehicle/Speed"])
        end
        return table.unpack(ReturnArgs)
    end
    return Old(Self,...)
end)
HookFunction("HelicopterMovement","Update",function(Old,Self,...)
    if F["BRM5/Helicopter/Enabled"] then Self._tune.Speed=F["BRM5/Helicopter/Speed"] end
    return Old(Self,...)
end)
HookFunction("AircraftMovement","Update",function(Old,Self,...)
    if F["BRM5/Aircraft/Enabled"] then Self._model.RPM.Value=F["BRM5/Aircraft/Speed"] end
    AircraftFly(Self,F["BRM5/Aircraft/FlyEnabled"],F["BRM5/Aircraft/FlySpeed"],F["BRM5/Aircraft/Camera"])
    return Old(Self,...)
end)
HookFunction("EnvironmentService","Update",function(Old,Self,...)
    if F["BRM5/Lighting/Enabled"] then
        Self._atmospheres.Default.Density=F["BRM5/Lighting/Fog"]
        if Self._atmospheres.Desert then Self._atmospheres.Desert.Density=F["BRM5/Lighting/Fog"] end
        if Self._atmospheres.Snow   then Self._atmospheres.Snow.Density=F["BRM5/Lighting/Fog"]   end
    end
    return Old(Self,...)
end)

HookSignal(RemoteEvent.OnClientEvent,1,function(Old,...)
    local Args={...}
    if Args[1]=="ReplicateNVG" then
        if F["BRM5/DisableNVG"] then Args[2]=false end
        if F["BRM5/NVGShape"]   then Args[3]="" end
    end
    return Old(table.unpack(Args))
end)

-- NoClip heartbeat
RunService.Stepped:Connect(function()
    if not F["BRM5/NoClip"] then return end
    if not LocalPlayer.Character then return end
    for _,Object in pairs(LocalPlayer.Character:GetDescendants()) do
        if Object:IsA("BasePart") then
            if NoClipObjects[Object]==nil then NoClipObjects[Object]=Object.CanCollide end
            Object.CanCollide=false
        end
    end
end)

-- 3rd person heartbeat
RunService.Heartbeat:Connect(function()
    if F["BRM5/ThirdPerson"] then
        if ServerSettings["FIRSTPERSON_LOCKED"]==true then ServerSettings["FIRSTPERSON_LOCKED"]=false end
    end
end)

-- Network
task.spawn(function()
    for _,Table in pairs(getgc(true)) do
        if typeof(Table)=="table" and rawget(Table,"FireServer") and rawget(Table,"InvokeServer") then
            Network=Table;break
        end
    end
end)

-- Silent Aim namecall
local OldNamecall=nil
OldNamecall=hookmetamethod(game,"__namecall",function(Self,...)
    if SilentAim and getnamecallmethod()=="Raycast" then
        if math.random(100)<=F["SilentAim/HitChance"] then
            local Args={...}
            if Args[1]==Camera.CFrame.Position then
                Args[2]=SilentAim[3].Position-Camera.CFrame.Position
            elseif AircraftTip and Args[1]==AircraftTip.WorldCFrame.Position then
                Args[2]=SilentAim[3].Position-AircraftTip.WorldCFrame.Position
            elseif GroundTip and Args[1]==GroundTip.WorldCFrame.Position then
                Args[2]=SilentAim[3].Position-GroundTip.WorldCFrame.Position
            end
            return OldNamecall(Self,table.unpack(Args))
        end
    end
    return OldNamecall(Self,...)
end)

-- Thread loops
task.spawn(function()
    while task.wait() do
        SilentAim=GetClosest(F["SilentAim/Enabled"],F["SilentAim/TeamCheck"],F["SilentAim/VisibilityCheck"],
            F["SilentAim/DistanceCheck"],F["SilentAim/DistanceLimit"],F["SilentAim/FOV/Radius"],
            F["SilentAim/Priority"][1],F["SilentAim/BodyParts"],F["SilentAim/Prediction"],F["BRM5/NPCMode"])
    end
end)
task.spawn(function()
    while task.wait() do
        if not (Aimbot or F["Aimbot/AlwaysEnabled"]) then continue end
        AimAt(GetClosest(F["Aimbot/Enabled"],F["Aimbot/TeamCheck"],F["Aimbot/VisibilityCheck"],
            F["Aimbot/DistanceCheck"],F["Aimbot/DistanceLimit"],F["Aimbot/FOV/Radius"],
            F["Aimbot/Priority"][1],F["Aimbot/BodyParts"],F["Aimbot/Prediction"],F["BRM5/NPCMode"]),
            F["Aimbot/Sensitivity"]/100)
    end
end)

-- Wait for modules
task.spawn(function()
    repeat task.wait() until RequireModule("RoundInterface")
    RoundInterface=RequireModule("RoundInterface")
    repeat task.wait() until RequireModule("ActorService")
    Actors=RequireModule("ActorService")._actors
end)

Lighting.Changed:Connect(function(Property)
    if Property=="OutdoorAmbient" and F["BRM5/Lighting/Brightness"] and Lighting.OutdoorAmbient~=WhiteColor then
        Lighting.OutdoorAmbient=WhiteColor
    end
    if Property=="ClockTime" and F["BRM5/Lighting/Enabled"] and Lighting.ClockTime~=F["BRM5/Lighting/Time"] then
        Lighting.ClockTime=F["BRM5/Lighting/Time"]
    end
end)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() Camera=workspace.CurrentCamera end)

-- ═══════════════════════════════════════════════════════════
--  BUILD TABS
-- ═══════════════════════════════════════════════════════════
local win=Library:CreateWindow()

-- HOME
local homeTab=win:CreateTab("Home","H")
homeTab:AddDashboard()
homeTab:AddCreation()

-- COMBAT
local combatTab=win:CreateTab("Combat","⚔")

combatTab:AddSection("Silent Aim")
combatTab:AddToggle("Silent Aim",      "sa_enabled",   function(v) F["SilentAim/Enabled"]=v end)
combatTab:AddToggle("Prediction",      "sa_pred",      function(v) F["SilentAim/Prediction"]=v end)
combatTab:AddToggle("Visibility Check","sa_wall",      function(v) F["SilentAim/VisibilityCheck"]=v end)
combatTab:AddToggle("Distance Check",  "sa_dist",      function(v) F["SilentAim/DistanceCheck"]=v end)
combatTab:AddSlider("FOV Radius",  0,500,"sa_fov", "r",   function(v) F["SilentAim/FOV/Radius"]=v end)
combatTab:AddSlider("Distance",   25,1000,"sa_dlimit","s", function(v) F["SilentAim/DistanceLimit"]=v end)
combatTab:AddSlider("Hit Chance", 0,100,"sa_hc",  "%",    function(v) F["SilentAim/HitChance"]=v end)
combatTab:AddDropdown("Aim Part",{"Head","HumanoidRootPart","UpperTorso"},"sa_part",function(v)
    F["SilentAim/BodyParts"]={v}
end)

combatTab:AddSection("Aimbot")
combatTab:AddToggle("Aimbot",          "ab_enabled",   function(v) F["Aimbot/Enabled"]=v end)
combatTab:AddToggle("Always On",       "ab_always",    function(v) F["Aimbot/AlwaysEnabled"]=v end)
combatTab:AddToggle("Prediction",      "ab_pred",      function(v) F["Aimbot/Prediction"]=v end)
combatTab:AddToggle("Visibility Check","ab_wall",      function(v) F["Aimbot/VisibilityCheck"]=v end)
combatTab:AddSlider("Sensitivity", 0,100,"ab_sens","%",  function(v) F["Aimbot/Sensitivity"]=v end)
combatTab:AddSlider("FOV Radius",  0,500,"ab_fov", "r",  function(v) F["Aimbot/FOV/Radius"]=v end)

combatTab:AddSection("Mode")
combatTab:AddToggle("NPC Mode","npc_mode",function(v) F["BRM5/NPCMode"]=v end)

-- WEAPON
local weaponTab=win:CreateTab("Weapon","🔫")

weaponTab:AddSection("Weapon")
weaponTab:AddToggle("No Recoil",    "recoil_en",  function(v) F["BRM5/Recoil/Enabled"]=v end)
weaponTab:AddSlider("Recoil %",0,100,"recoil_val","%",function(v) F["BRM5/Recoil/Value"]=v end)
weaponTab:AddToggle("Instant Hit",  "bulletdrop", function(v) F["BRM5/BulletDrop"]=v end)
weaponTab:AddToggle("Unlock Modes", "firemodes",  function(v) F["BRM5/Firemodes"]=v end)
weaponTab:AddToggle("Rapid Fire",   "rapid_en",   function(v) F["BRM5/RapidFire/Enabled"]=v end)
weaponTab:AddSlider("RPM",45,1000,"rapid_val","",function(v) F["BRM5/RapidFire/Value"]=v end)

-- CHARACTER
local charTab=win:CreateTab("Char","🏃")

charTab:AddSection("Character")
charTab:AddToggle("NoClip",        "noclip",    function(v)
    F["BRM5/NoClip"]=v
    if not v then
        for Object,CanCollide in pairs(NoClipObjects) do Object.CanCollide=CanCollide end
        table.clear(NoClipObjects)
    end
end)
charTab:AddToggle("No Camera Bob", "nobob",     function(v) F["BRM5/NoBob"]=v end)
charTab:AddToggle("No Stamina",    "nostamina", function(v) F["BRM5/NoStamina"]=v end)
charTab:AddToggle("No NVG Effect", "nonvg",     function(v) F["BRM5/DisableNVG"]=v end)
charTab:AddToggle("No NVG Shape",  "nonvgs",    function(v) F["BRM5/NVGShape"]=v end)
charTab:AddToggle("Speed Hack",    "ws_en",     function(v) F["BRM5/WalkSpeed/Enabled"]=v end)
charTab:AddSlider("Speed",16,1000,"ws_val","",  function(v) F["BRM5/WalkSpeed/Value"]=v end)
charTab:AddToggle("Unlock 3rd Person","thirdperson",function(v)
    F["BRM5/ThirdPerson"]=v
    if v then ServerSettings["FIRSTPERSON_LOCKED"]=false
    else ServerSettings["FIRSTPERSON_LOCKED"]=true end
    ShowToast(v and "3rd Person: Mở khóa!" or "3rd Person: Khóa lại","👁")
end)

charTab:AddSection("Environment")
charTab:AddToggle("Custom Lighting","light_en",  function(v) F["BRM5/Lighting/Enabled"]=v end)
charTab:AddToggle("Full Brightness","light_br",  function(v) F["BRM5/Lighting/Brightness"]=v;Lighting.GlobalShadows=not v end)
charTab:AddSlider("Clock Time",0,24,"light_time","h",function(v) F["BRM5/Lighting/Time"]=v end)
charTab:AddSlider("Fog Density",0,100,"light_fog","%",function(v) F["BRM5/Lighting/Fog"]=v/100 end)

-- VEHICLE
local vehTab=win:CreateTab("Veh","🚗")

vehTab:AddSection("Ground Vehicle")
vehTab:AddToggle("Enabled",  "veh_en",  function(v) F["BRM5/Vehicle/Enabled"]=v end)
vehTab:AddSlider("Speed",0,1000,"veh_spd","",function(v) F["BRM5/Vehicle/Speed"]=v end)
vehTab:AddSlider("Acceleration",1,50,"veh_acc","",function(v) F["BRM5/Vehicle/Acceleration"]=v end)

vehTab:AddSection("Helicopter")
vehTab:AddToggle("Enabled",  "heli_en", function(v) F["BRM5/Helicopter/Enabled"]=v end)
vehTab:AddSlider("Speed",0,500,"heli_spd","",function(v) F["BRM5/Helicopter/Speed"]=v end)

vehTab:AddSection("Aircraft")
vehTab:AddToggle("Speed Mod",     "air_en",    function(v) F["BRM5/Aircraft/Enabled"]=v end)
vehTab:AddSlider("Speed",130,950,"air_spd","", function(v) F["BRM5/Aircraft/Speed"]=v end)
vehTab:AddToggle("Fly Mode",      "air_fly",   function(v) F["BRM5/Aircraft/FlyEnabled"]=v end)
vehTab:AddToggle("Camera Control","air_cam",   function(v) F["BRM5/Aircraft/Camera"]=v end)
vehTab:AddSlider("Fly Speed",145,500,"air_fspd","",function(v) F["BRM5/Aircraft/FlySpeed"]=v end)
vehTab:AddButton("⚙ Setup Engines",function()
    local Aircraft=RequireModule("MovementService")
    if not Aircraft or not Aircraft._handler or not Aircraft._handler._main then
        ShowToast("Không ở trong Aircraft!","❌");return
    end
    if Network then Network:FireServer("CallInteraction","Fire","Canopy") end
    for _,sw in ipairs({"cicu","oxygen","battery","ac_r","ac_l","inverter","take_apu","apu","engine_r","engine_l","fuel_r_l","fuel_l_l","fuel_r_r","fuel_l_r"}) do
        EnableSwitch(sw)
    end
    ShowToast("Đang khởi động engines...","⚙")
    task.spawn(function()
        repeat task.wait() until Aircraft._handler._main.APU.engine.PlaybackSpeed==1
        if Network then
            Network:FireServer("CallInteraction","Fire","LeftEngine")
            Network:FireServer("CallInteraction","Fire","RightEngine")
        end
        ShowToast("Engines sẵn sàng!","✅")
    end)
end,"Đang thiết lập...","⚙")
vehTab:AddButton("🔓 Unlock Camera",function()
    local Aircraft=RequireModule("MovementService")
    local CameraMod=RequireModule("CameraService")
    if Aircraft and Aircraft._handler and Aircraft._handler._controller then
        CameraMod:Mount(Aircraft._handler._controller,"Character")
        CameraMod._handler._zoom=128
        ShowToast("Camera đã mở khóa!","🔓")
    end
end)

-- TELEPORT
local tpTab=win:CreateTab("TP","📍")
tpTab:AddSection("Teleport")
for _,tp in ipairs(Teleports) do
    tpTab:AddButton("📍 "..tp[1],function()
        TeleportCharacter(tp[2])
    end,"Đang teleport: "..tp[1],"📍")
end

-- MISC
local miscTab=win:CreateTab("Misc","⚙")
miscTab:AddSection("Server")
miscTab:AddButton("✨ Enable Fake RGE",function()
    if not ServerSettings.CHEATS_ENABLED then
        ServerSettings.CHEATS_ENABLED=true
        for _,Connection in pairs(getconnections(RemoteEvent.OnClientEvent)) do
            Connection.Function("InitRGE")
        end
        ShowToast("Fake RGE enabled!","✨")
    end
end)
miscTab:AddButton("🔄 Reset Character",function()
    if Network then Network:FireServer("ResetCharacter") end
    ShowToast("Đã reset character!","🔄")
end)
miscTab:AddButton("🔒 Toggle FP Lock",function()
    local cur=ServerSettings["FIRSTPERSON_LOCKED"]
    ServerSettings["FIRSTPERSON_LOCKED"]=not cur
    ShowToast("FP Lock: "..(not cur and "ON" or "OFF"),"🔒")
end)

print("[TokaiHub x BRM5] Loaded! RightControl = toggle menu")

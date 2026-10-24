local _r = math.random; math.randomseed(os.clock() * 1e6 + tick())
local _id = ""; for i = 1, 12 do local c = _r(1,3); _id = _id .. (c == 1 and string.char(_r(65,90)) or c == 2 and string.char(_r(97,122)) or tostring(_r(0,9))) end

local _ok, _e = pcall(function()

-- services (indirect)
local _svc = game.GetService
local _P = _svc(game,"Players"); local _TS = _svc(game,"TweenService"); local _UIS = _svc(game,"UserInputService")
local _HS = _svc(game,"HttpService"); local _TP = _svc(game,"TeleportService"); local _REP = _svc(game,"ReplicatedStorage")
local _LOC = _svc(game,"LocalizationService"); local _SND = _svc(game,"SoundService")
local _lp = _P.LocalPlayer; local _pg = _lp:WaitForChild("PlayerGui"); local _pid = game.PlaceId

-- config
local _cfg = {
    src = "ht".."tps://ra".."w.githu".."busercontent.co".."m/765632/Phan".."tomHub/master",
    st = 18, hd = 2, mx = 100, mp = 1, ef = true, ps = true,
}
local _uk = getgenv().phantom_key or getgenv().script_key or ""
local _ab = "ht".."tps://phan".."tomhub.onrender"..".com"

-- http helper
local function _hx(url, method, body)
    method = method or "GET"; local res
    local fn = request or (syn and syn.request) or (fluxus and fluxus.request) or http_request or (typeof(http) == "table" and http.request)
    if fn then
        local o = {Url=url,Method=method,Headers={["Content-Type"]="application/json"}}
        if body then o.Body = body end
        local s,r = pcall(fn,o); if s and r then res = r.Body or r.body end
    end
    if not res and method == "GET" then pcall(function() res = game:HttpGet(url) end) end
    if res then local s,d = pcall(_HS.JSONDecode,_HS,res); if s then return d end end
    return nil
end

local function _rgn() local c = "US"; pcall(function() c = _LOC:GetCountryRegionForPlayerAsync(_lp) end); return c end

-- persist across teleport
local function _qp()
    if not _cfg.ps then return end
    pcall(function()
        local s = 'getgenv().phantom_key = "'.. _uk ..'"\n'
            ..'getgenv().aj_auto_hop = true\n'
            ..'getgenv().aj_servers_checked = '.. tostring(getgenv().aj_servers_checked or 0) ..'\n'
            ..'getgenv().aj_ogs_found = '.. tostring(getgenv().aj_ogs_found or 0) ..'\n'
            ..'loadstring(game:HttpGet("'.. _cfg.src ..'/aj_loader.lua?v=" .. tostring(tick())))()\n'
        local qf = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if qf then qf(s) end
    end)
end
_qp()

-- nuke old gui
for _,g in ipairs(_pg:GetChildren()) do if g:IsA("ScreenGui") then pcall(function() if g:FindFirstChild("_sb") and g:FindFirstChild("_mc") then g:Destroy() end end) end end
pcall(function() for _,g in ipairs(game:GetService("CoreGui"):GetChildren()) do if g:IsA("ScreenGui") then pcall(function() if g:FindFirstChild("_sb") and g:FindFirstChild("_mc") then g:Destroy() end end) end end end)

-- palette
local _ = {
    bg = Color3.fromRGB(10,10,10),
    bg2 = Color3.fromRGB(16,16,16),
    card = Color3.fromRGB(22,22,22),
    card2 = Color3.fromRGB(30,30,30),
    bdr = Color3.fromRGB(38,38,38),
    bdr2 = Color3.fromRGB(55,55,55),
    w = Color3.fromRGB(255,255,255),
    t = Color3.fromRGB(235,235,235),
    t2 = Color3.fromRGB(160,160,160),
    t3 = Color3.fromRGB(100,100,100),
    g = Color3.fromRGB(255,190,60),
    g2 = Color3.fromRGB(140,100,20),
    r = Color3.fromRGB(220,55,55),
    r2 = Color3.fromRGB(130,30,30),
    gn = Color3.fromRGB(60,200,90),
    gn2 = Color3.fromRGB(25,80,35),
    gnB = Color3.fromRGB(40,140,65),
    bl = Color3.fromRGB(90,150,255),
    sb = Color3.fromRGB(28,90,50),
    sbH = Color3.fromRGB(35,110,62),
    sbA = Color3.fromRGB(40,130,72),
    tOff = Color3.fromRGB(60,60,60),
    tOn = Color3.fromRGB(255,255,255),
}

-- state
local _v = {
    on = true, hop = getgenv().aj_auto_hop or false, scan = false,
    sv = getgenv().aj_servers_checked or 0, og = getgenv().aj_ogs_found or 0,
    t0 = os.time(), snd = true, axh = true, cpn = false, als = false, afk = true,
    st = _cfg.st, tab = "main",
}

-- targets
local _tgt = {
    {n="Skibidi Toilet",rv="$450M/s",tr=1},{n="John Pork",rv="$500M/s",tr=2},
    {n="Headless Horseman",rv="$600M/s",tr=3},{n="Meowl",rv="$600M/s",tr=3},
    {n="Strawberry Elephant",rv="$750M/s",tr=4},
}
local _tm,_tkw = {},{}
for _,x in ipairs(_tgt) do _tm[x.n:lower()]=x; for w in x.n:lower():gmatch("%S+") do if #w>2 and w~="the" then _tkw[w]=x.n end end end
local function _isT(n) if not n then return false end; local l=n:lower(); if _tm[l] then return true end; for k in pairs(_tkw) do if l:find(k,1,true) then return true end end; return false end
local function _gtI(n) if not n then return nil end; local l=n:lower(); if _tm[l] then return _tm[l] end; for k,v in pairs(_tkw) do if l:find(k,1,true) then return _tm[v:lower()] end end; return nil end
local _hn = {"Headless","Strawberry","Meowl","Skibidi","John Pork","Griffin","Signore","Elefanto","Love Love","Celestial","Cerberus","GOAT","Dragon Cannelloni","Hydra"}
local function _isH(n) if not n then return false end; for _,h in ipairs(_hn) do if n:find(h) then return true end end; return false end

-- hits list
local _hits = {}
local function _addH(pet,own,rate,jid,plrs) table.insert(_hits,1,{p=pet,o=own or "???",rv=rate or "?",j=jid or game.JobId,ts=os.time(),og=_isT(pet),pl=plrs or "?"}); if #_hits>50 then table.remove(_hits) end end

-- remotes
local _net; pcall(function() _net = _REP:WaitForChild("Packages",5):WaitForChild("Net",5) end)
local function _fre(n) if not _net then return end; for _,d in pairs(_net:GetDescendants()) do if d:IsA("RemoteEvent") and d.Name:find(n) then return d end end end
local _rm = {}
pcall(function() _rm.ds = _fre("DuelService/Send") or _fre("DuelService/Request") or _fre("BattleService/Send") end)

-- xenhub target
local function _sxt(own,pet)
    pcall(function() getgenv().XenhubTarget=own end)
    pcall(function() getgenv().XenhubPet=pet end)
    pcall(function() getgenv().AutoStealTarget=own end)
    pcall(function() getgenv().TargetPlayer=own end)
end

-- steal logger
local function _ls(pet,own,sid) task.spawn(function() pcall(function()
    local pl = _HS:JSONEncode({pet=pet,owner=own or "???",player=_lp.Name,server_id=sid or game.JobId})
    local fn = request or (syn and syn.request) or (fluxus and fluxus.request) or http_request or (typeof(http)=="table" and http.request)
    if fn then fn({Url=_ab.."/api/log-steal",Method="POST",Headers={["Content-Type"]="application/json"},Body=pl}) end
end) end) end

-- sounds
local function _pa() if not _v.snd then return end; pcall(function() local s=Instance.new("Sound"); s.SoundId="rbxassetid://6042053626"; s.Volume=0.5; s.Parent=_SND; s:Play(); task.delay(2,function() s:Destroy() end) end) end
local function _po() if not _v.snd then return end; pcall(function() local s=Instance.new("Sound"); s.SoundId="rbxassetid://5018104731"; s.Volume=0.85; s.Parent=_SND; s:Play(); task.delay(3,function() s:Destroy() end) end) end

-- ui helpers
local function _cr(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p end
local function _sk(p,col,th) local s=Instance.new("UIStroke"); s.Color=col or _.bdr; s.Thickness=th or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p end
local function _tw(obj,pr,dur) _TS:Create(obj,TweenInfo.new(dur or 0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),pr):Play() end

-- avatar
local _avatarUrl = ""
pcall(function()
    local thumb,ready = _P:GetUserThumbnailAsync(_lp.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
    if ready then _avatarUrl = thumb end
end)
if _avatarUrl == "" then _avatarUrl = "rbxthumb://type=AvatarHeadShot&id=".._lp.UserId.."&w=100&h=100" end

-- ════════════════════════════════════════════
-- GUI
-- ════════════════════════════════════════════
local _W,_H = 660,440
local SB_W = 64

local gui = Instance.new("ScreenGui"); gui.Name = _id; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.IgnoreGuiInset = true; gui.Parent = _pg

-- outer wrapper for dragging (NO Active property set!)
local wrap = Instance.new("Frame"); wrap.Name = "_wr"; wrap.AnchorPoint = Vector2.new(0.5,0.5); wrap.Size = UDim2.new(0,_W,0,_H); wrap.Position = UDim2.new(0.5,0,0.5,0)
wrap.BackgroundTransparency = 1; wrap.Parent = gui

-- main frame (NO Active!)
local mf = Instance.new("Frame"); mf.Name = "_mf"; mf.Size = UDim2.new(1,0,1,0); mf.BackgroundColor3 = _.bg; mf.BorderSizePixel = 0; mf.ClipsDescendants = true; mf.Parent = wrap
_cr(mf,10); _sk(mf,_.bdr)

-- gold accent top
local accent = Instance.new("Frame"); accent.Size = UDim2.new(1,-2,0,2); accent.Position = UDim2.new(0,1,0,1); accent.BackgroundColor3 = _.g; accent.BorderSizePixel = 0; accent.ZIndex = 5; accent.Parent = mf
_cr(accent,10)
local accentM = Instance.new("Frame"); accentM.Size = UDim2.new(1,0,0,6); accentM.Position = UDim2.new(0,0,1,-6); accentM.BackgroundColor3 = _.g; accentM.BorderSizePixel = 0; accentM.ZIndex = 5; accentM.Parent = accent

-- ════════ SIDEBAR ════════
local sb = Instance.new("Frame"); sb.Name = "_sb"; sb.Size = UDim2.new(0,SB_W,1,-4); sb.Position = UDim2.new(0,2,0,2)
sb.BackgroundColor3 = _.bg2; sb.BorderSizePixel = 0; sb.Parent = mf; _cr(sb,8)

local _tabs = {}
local function _sbBtn(label, order)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1,-12,0,32); btn.Position = UDim2.new(0,6,0,8 + (order * 38))
    btn.BackgroundColor3 = _.sb; btn.Text = label; btn.TextColor3 = _.gn; btn.Font = Enum.Font.GothamBold; btn.TextSize = 10
    btn.AutoButtonColor = false; btn.Parent = sb; _cr(btn,6)
    _tabs[label:lower()] = btn
    btn.MouseEnter:Connect(function() if _v.tab ~= label:lower() then _tw(btn,{BackgroundColor3=_.sbH}) end end)
    btn.MouseLeave:Connect(function() if _v.tab ~= label:lower() then _tw(btn,{BackgroundColor3=_.sb}) end end)
    return btn
end

local mainBtn = _sbBtn("Main", 0)
local confBtn = _sbBtn("Config", 1)
local settBtn = _sbBtn("Settings", 2)

-- sidebar close
local closeBtn = Instance.new("TextButton"); closeBtn.Size = UDim2.new(1,-12,0,28); closeBtn.Position = UDim2.new(0,6,1,-36)
closeBtn.BackgroundColor3 = _.r2; closeBtn.Text = "X"; closeBtn.TextColor3 = _.r; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 12
closeBtn.AutoButtonColor = false; closeBtn.Parent = sb; _cr(closeBtn,6)
closeBtn.MouseEnter:Connect(function() _tw(closeBtn,{BackgroundColor3=_.r}) end)
closeBtn.MouseLeave:Connect(function() _tw(closeBtn,{BackgroundColor3=_.r2}) end)

-- sidebar avatar
local sbAv = Instance.new("ImageLabel"); sbAv.Size = UDim2.new(0,28,0,28); sbAv.Position = UDim2.new(0.5,-14,1,-68)
sbAv.BackgroundColor3 = _.card; sbAv.BorderSizePixel = 0; sbAv.Image = _avatarUrl; sbAv.Parent = sb; _cr(sbAv,99)

-- ════════ MAIN CONTENT AREA ════════
local mc = Instance.new("Frame"); mc.Name = "_mc"; mc.Size = UDim2.new(1,-SB_W-6,1,-8); mc.Position = UDim2.new(0,SB_W+4,0,4)
mc.BackgroundColor3 = _.bg2; mc.BorderSizePixel = 0; mc.ClipsDescendants = true; mc.Parent = mf; _cr(mc,8)

-- ════════ DRAG — header area only ════════
local dragBar = Instance.new("TextButton"); dragBar.Size = UDim2.new(0.6,0,0,50); dragBar.BackgroundTransparency = 1; dragBar.Text = ""; dragBar.AutoButtonColor = false; dragBar.Parent = mc; dragBar.ZIndex = 1
local _dg,_ds,_dp = false,nil,nil
dragBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        _dg = true; _ds = i.Position; _dp = wrap.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then _dg = false end end)
    end
end)
_UIS.InputChanged:Connect(function(i)
    if _dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - _ds; wrap.Position = UDim2.new(_dp.X.Scale,_dp.X.Offset+d.X,_dp.Y.Scale,_dp.Y.Offset+d.Y)
    end
end)

-- ════════ HEADER SECTION ════════
local welc = Instance.new("TextLabel"); welc.Size = UDim2.new(0.6,0,0,18); welc.Position = UDim2.new(0,14,0,10); welc.BackgroundTransparency = 1
welc.Text = "Welcome, ".._lp.DisplayName; welc.TextColor3 = _.w; welc.Font = Enum.Font.GothamBold; welc.TextSize = 14; welc.TextXAlignment = Enum.TextXAlignment.Left; welc.ZIndex = 3; welc.Parent = mc

local uptLbl = Instance.new("TextLabel"); uptLbl.Size = UDim2.new(0.4,0,0,12); uptLbl.Position = UDim2.new(0,14,0,30); uptLbl.BackgroundTransparency = 1
uptLbl.Text = "Uptime: 0:00:00"; uptLbl.TextColor3 = _.t3; uptLbl.Font = Enum.Font.GothamMedium; uptLbl.TextSize = 10; uptLbl.TextXAlignment = Enum.TextXAlignment.Left; uptLbl.ZIndex = 3; uptLbl.Parent = mc

-- header buttons (ZIndex above dragBar)
local clearBtn = Instance.new("TextButton"); clearBtn.Size = UDim2.new(0,58,0,24); clearBtn.Position = UDim2.new(1,-132,0,12)
clearBtn.BackgroundColor3 = _.r; clearBtn.Text = "Clear"; clearBtn.TextColor3 = _.w; clearBtn.Font = Enum.Font.GothamBold; clearBtn.TextSize = 10
clearBtn.AutoButtonColor = false; clearBtn.ZIndex = 4; clearBtn.Parent = mc; _cr(clearBtn,6)
clearBtn.MouseEnter:Connect(function() _tw(clearBtn,{BackgroundColor3=Color3.fromRGB(255,80,80)}) end)
clearBtn.MouseLeave:Connect(function() _tw(clearBtn,{BackgroundColor3=_.r}) end)

local rejBtn = Instance.new("TextButton"); rejBtn.Size = UDim2.new(0,58,0,24); rejBtn.Position = UDim2.new(1,-68,0,12)
rejBtn.BackgroundColor3 = _.gn; rejBtn.Text = "Rejoin"; rejBtn.TextColor3 = _.w; rejBtn.Font = Enum.Font.GothamBold; rejBtn.TextSize = 10
rejBtn.AutoButtonColor = false; rejBtn.ZIndex = 4; rejBtn.Parent = mc; _cr(rejBtn,6)
rejBtn.MouseEnter:Connect(function() _tw(rejBtn,{BackgroundColor3=Color3.fromRGB(80,230,110)}) end)
rejBtn.MouseLeave:Connect(function() _tw(rejBtn,{BackgroundColor3=_.gn}) end)

local hDiv = Instance.new("Frame"); hDiv.Size = UDim2.new(1,-20,0,1); hDiv.Position = UDim2.new(0,10,0,48); hDiv.BackgroundColor3 = _.bdr; hDiv.BorderSizePixel = 0; hDiv.ZIndex = 2; hDiv.Parent = mc

-- ════════ PAGES ════════
local pageMain = Instance.new("Frame"); pageMain.Size = UDim2.new(1,0,1,-52); pageMain.Position = UDim2.new(0,0,0,52)
pageMain.BackgroundTransparency = 1; pageMain.ClipsDescendants = true; pageMain.Parent = mc

local pageConf = Instance.new("Frame"); pageConf.Size = UDim2.new(1,0,1,-52); pageConf.Position = UDim2.new(0,0,0,52)
pageConf.BackgroundTransparency = 1; pageConf.ClipsDescendants = true; pageConf.Visible = false; pageConf.Parent = mc

local pageSett = Instance.new("Frame"); pageSett.Size = UDim2.new(1,0,1,-52); pageSett.Position = UDim2.new(0,0,0,52)
pageSett.BackgroundTransparency = 1; pageSett.ClipsDescendants = true; pageSett.Visible = false; pageSett.Parent = mc

local function _switchTab(name)
    _v.tab = name
    pageMain.Visible = (name == "main"); pageConf.Visible = (name == "config"); pageSett.Visible = (name == "settings")
    for k,btn in pairs(_tabs) do
        if k == name then btn.BackgroundColor3 = _.sbA; btn.TextColor3 = _.w
        else btn.BackgroundColor3 = _.sb; btn.TextColor3 = _.gn end
    end
end
_switchTab("main")
mainBtn.MouseButton1Click:Connect(function() _switchTab("main") end)
confBtn.MouseButton1Click:Connect(function() _switchTab("config") end)
settBtn.MouseButton1Click:Connect(function() _switchTab("settings") end)

-- ════════════════════════════════════════════
-- PAGE: MAIN
-- ════════════════════════════════════════════
local function _mkToggle(parent, label, y, default, callback)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1,-24,0,28); row.Position = UDim2.new(0,12,0,y)
    row.BackgroundTransparency = 1; row.Parent = parent

    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1,-50,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.TextColor3 = _.t; lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local track = Instance.new("TextButton"); track.Size = UDim2.new(0,38,0,18); track.Position = UDim2.new(1,-38,0.5,-9)
    track.BackgroundColor3 = default and _.tOn or _.tOff; track.Text = ""; track.AutoButtonColor = false; track.Parent = row; _cr(track,99)

    local thumb = Instance.new("Frame"); thumb.Size = UDim2.new(0,14,0,14); thumb.BackgroundColor3 = default and _.bg or _.t3; thumb.BorderSizePixel = 0
    thumb.Position = default and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7); thumb.Parent = track; _cr(thumb,99)

    local on = default
    track.MouseButton1Click:Connect(function()
        on = not on; callback(on)
        _tw(track,{BackgroundColor3 = on and _.tOn or _.tOff})
        _tw(thumb,{Position = on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7), BackgroundColor3 = on and _.bg or _.t3})
    end)
    return track, row
end

_mkToggle(pageMain, "Auto Join", 4, _v.hop, function(v) _v.hop = v; if v then task.spawn(function() task.wait(0.1); if _v.hop then local _startH; _startH = nil end end) end end)
_mkToggle(pageMain, "Sound Alerts", 34, _v.snd, function(v) _v.snd = v end)
_mkToggle(pageMain, "Auto Xenhub Target", 64, _v.axh, function(v) _v.axh = v end)
_mkToggle(pageMain, "Anti-AFK", 94, _v.afk, function(v) _v.afk = v end)

-- stats
local statsLbl = Instance.new("TextLabel"); statsLbl.Size = UDim2.new(0.5,0,0,16); statsLbl.Position = UDim2.new(0,14,0,130)
statsLbl.BackgroundTransparency = 1; statsLbl.Text = "0 joins"; statsLbl.TextColor3 = _.t2; statsLbl.Font = Enum.Font.GothamMedium; statsLbl.TextSize = 11; statsLbl.TextXAlignment = Enum.TextXAlignment.Left; statsLbl.Parent = pageMain

local statusLbl = Instance.new("TextLabel"); statusLbl.Size = UDim2.new(0.5,-12,0,16); statusLbl.Position = UDim2.new(0.5,0,0,130)
statusLbl.BackgroundTransparency = 1; statusLbl.Text = "Idle"; statusLbl.TextColor3 = _.t3; statusLbl.Font = Enum.Font.GothamMedium; statusLbl.TextSize = 11; statusLbl.TextXAlignment = Enum.TextXAlignment.Right; statusLbl.Parent = pageMain

local feedDiv = Instance.new("Frame"); feedDiv.Size = UDim2.new(1,-24,0,1); feedDiv.Position = UDim2.new(0,12,0,152); feedDiv.BackgroundColor3 = _.bdr; feedDiv.BorderSizePixel = 0; feedDiv.Parent = pageMain
local ogHeader = Instance.new("TextLabel"); ogHeader.Size = UDim2.new(1,-24,0,18); ogHeader.Position = UDim2.new(0,12,0,156)
ogHeader.BackgroundTransparency = 1; ogHeader.Text = "0 secrets"; ogHeader.TextColor3 = _.g; ogHeader.Font = Enum.Font.GothamBold; ogHeader.TextSize = 11; ogHeader.TextXAlignment = Enum.TextXAlignment.Left; ogHeader.Parent = pageMain

-- feed scroll
local fs = Instance.new("ScrollingFrame"); fs.Size = UDim2.new(1,-20,1,-180); fs.Position = UDim2.new(0,10,0,178)
fs.BackgroundTransparency = 1; fs.BorderSizePixel = 0; fs.CanvasSize = UDim2.new(0,0,0,0); fs.ScrollBarThickness = 2; fs.ScrollBarImageColor3 = _.bdr2; fs.Parent = pageMain
local fsl = Instance.new("UIListLayout"); fsl.Padding = UDim.new(0,4); fsl.Parent = fs
fsl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() fs.CanvasSize = UDim2.new(0,0,0,fsl.AbsoluteContentSize.Y+4) end)

-- build feed row
local function _bfe(det)
    local og = det.og; local isCur = (det.j == game.JobId)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1,0,0,38); row.BackgroundColor3 = _.card; row.BorderSizePixel = 0; row.LayoutOrder = -(det.ts or os.time()); row.Parent = fs
    _cr(row,6)
    if og then _sk(row,_.g2,1) else _sk(row,_.bdr,1) end

    local info = Instance.new("TextLabel"); info.Size = UDim2.new(1,-80,1,0); info.Position = UDim2.new(0,10,0,0); info.BackgroundTransparency = 1
    info.Text = det.p.." — "..det.rv; info.TextColor3 = og and _.g or _.t; info.Font = og and Enum.Font.GothamBold or Enum.Font.GothamMedium
    info.TextSize = 11; info.TextXAlignment = Enum.TextXAlignment.Left; info.TextTruncate = Enum.TextTruncate.AtEnd; info.Parent = row

    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0,56,0,26); btn.Position = UDim2.new(1,-64,0.5,-13)
    btn.AutoButtonColor = false; btn.Font = Enum.Font.GothamBold; btn.TextSize = 10; btn.Parent = row; _cr(btn,5)

    if isCur then
        btn.BackgroundColor3 = _.gn2; btn.Text = "Here"; btn.TextColor3 = _.gn
        if _v.als then _ls(det.p,det.o,det.j) end
        btn.MouseButton1Click:Connect(function()
            _ls(det.p,det.o,det.j)
            btn.Text = "Logged ✓"; btn.BackgroundColor3 = _.gn; btn.TextColor3 = _.w
            if _v.cpn then pcall(function() setclipboard(det.o) end) end
            if _v.axh then _sxt(det.o,det.p) end
            task.delay(2,function() if btn.Parent then btn.Text="Here"; btn.BackgroundColor3=_.gn2; btn.TextColor3=_.gn end end)
        end)
    else
        btn.BackgroundColor3 = _.gn; btn.Text = "Join"; btn.TextColor3 = _.w
        btn.MouseEnter:Connect(function() _tw(btn,{BackgroundColor3=Color3.fromRGB(80,230,110)}) end)
        btn.MouseLeave:Connect(function() _tw(btn,{BackgroundColor3=_.gn}) end)
        btn.MouseButton1Click:Connect(function()
            btn.Text = "Joining…"; btn.TextColor3 = _.w; btn.BackgroundColor3 = _.bl
            task.spawn(function() pcall(function()
                getgenv().aj_servers_checked = _v.sv; getgenv().aj_ogs_found = _v.og; _qp()
                _TP:TeleportToPlaceInstance(_pid,det.j,_lp)
            end) end)
            task.delay(5,function() if btn.Parent then btn.Text="Join"; btn.TextColor3=_.w; btn.BackgroundColor3=_.gn end end)
        end)
    end

    row.MouseEnter:Connect(function() _tw(row,{BackgroundColor3=_.card2}) end)
    row.MouseLeave:Connect(function() _tw(row,{BackgroundColor3=_.card}) end)
end

-- ════════════════════════════════════════════
-- PAGE: CONFIG
-- ════════════════════════════════════════════
local confTitle = Instance.new("TextLabel"); confTitle.Size = UDim2.new(1,-24,0,20); confTitle.Position = UDim2.new(0,12,0,8)
confTitle.BackgroundTransparency = 1; confTitle.Text = "OG Targets"; confTitle.TextColor3 = _.g; confTitle.Font = Enum.Font.GothamBold; confTitle.TextSize = 13; confTitle.TextXAlignment = Enum.TextXAlignment.Left; confTitle.Parent = pageConf

for i,tg in ipairs(_tgt) do
    local row = Instance.new("Frame"); row.Size = UDim2.new(1,-24,0,32); row.Position = UDim2.new(0,12,0,30+(i-1)*36)
    row.BackgroundColor3 = _.card; row.BorderSizePixel = 0; row.Parent = pageConf; _cr(row,5); _sk(row,_.g2,1)
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.6,0,1,0); l.Position = UDim2.new(0,10,0,0); l.BackgroundTransparency = 1
    l.Text = tg.n; l.TextColor3 = _.g; l.Font = Enum.Font.GothamBold; l.TextSize = 12; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
    local r = Instance.new("TextLabel"); r.Size = UDim2.new(0.35,-10,1,0); r.Position = UDim2.new(0.6,0,0,0); r.BackgroundTransparency = 1
    r.Text = tg.rv; r.TextColor3 = _.t2; r.Font = Enum.Font.GothamMedium; r.TextSize = 11; r.TextXAlignment = Enum.TextXAlignment.Right; r.Parent = row
end

local hlTitle = Instance.new("TextLabel"); hlTitle.Size = UDim2.new(1,-24,0,20); hlTitle.Position = UDim2.new(0,12,0,30+#_tgt*36+8)
hlTitle.BackgroundTransparency = 1; hlTitle.Text = "Highlighted Pets"; hlTitle.TextColor3 = _.t2; hlTitle.Font = Enum.Font.GothamBold; hlTitle.TextSize = 11; hlTitle.TextXAlignment = Enum.TextXAlignment.Left; hlTitle.Parent = pageConf
local hlText = Instance.new("TextLabel"); hlText.Size = UDim2.new(1,-24,0,60); hlText.Position = UDim2.new(0,12,0,30+#_tgt*36+30)
hlText.BackgroundTransparency = 1; hlText.Text = table.concat(_hn,", "); hlText.TextColor3 = _.t3; hlText.Font = Enum.Font.Gotham; hlText.TextSize = 10; hlText.TextXAlignment = Enum.TextXAlignment.Left; hlText.TextWrapped = true; hlText.Parent = pageConf

-- ════════════════════════════════════════════
-- PAGE: SETTINGS
-- ════════════════════════════════════════════
local stTitle = Instance.new("TextLabel"); stTitle.Size = UDim2.new(1,-24,0,20); stTitle.Position = UDim2.new(0,12,0,8)
stTitle.BackgroundTransparency = 1; stTitle.Text = "Settings"; stTitle.TextColor3 = _.w; stTitle.Font = Enum.Font.GothamBold; stTitle.TextSize = 13; stTitle.TextXAlignment = Enum.TextXAlignment.Left; stTitle.Parent = pageSett

_mkToggle(pageSett, "Copy Owner Name", 34, _v.cpn, function(v) _v.cpn = v end)
_mkToggle(pageSett, "Auto Log Steal", 66, _v.als, function(v) _v.als = v end)

local stSec = Instance.new("TextLabel"); stSec.Size = UDim2.new(1,-24,0,14); stSec.Position = UDim2.new(0,12,0,104)
stSec.BackgroundTransparency = 1; stSec.Text = "SCAN TIME"; stSec.TextColor3 = _.t3; stSec.Font = Enum.Font.GothamBold; stSec.TextSize = 9; stSec.TextXAlignment = Enum.TextXAlignment.Left; stSec.Parent = pageSett
local stRow = Instance.new("Frame"); stRow.Size = UDim2.new(1,-24,0,28); stRow.Position = UDim2.new(0,12,0,122)
stRow.BackgroundTransparency = 1; stRow.Parent = pageSett
local stRowL = Instance.new("UIListLayout"); stRowL.FillDirection = Enum.FillDirection.Horizontal; stRowL.Padding = UDim.new(0,4); stRowL.Parent = stRow

for _,sec in ipairs({10,15,18,25,30}) do
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0,48,0,26); b.BackgroundColor3 = sec==_v.st and _.w or _.card
    b.Text = sec.."s"; b.TextColor3 = sec==_v.st and _.bg or _.t2; b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.AutoButtonColor = false; b.Parent = stRow; _cr(b,5)
    b.MouseButton1Click:Connect(function()
        _v.st = sec
        for _,c in ipairs(stRow:GetChildren()) do if c:IsA("TextButton") then
            local sel = (c.Text==sec.."s"); c.BackgroundColor3 = sel and _.w or _.card; c.TextColor3 = sel and _.bg or _.t2
        end end
    end)
end

local rgLbl = Instance.new("TextLabel"); rgLbl.Size = UDim2.new(1,-24,0,14); rgLbl.Position = UDim2.new(0,12,0,160)
rgLbl.BackgroundTransparency = 1; rgLbl.Text = "Region: ".._rgn(); rgLbl.TextColor3 = _.t3; rgLbl.Font = Enum.Font.GothamMedium; rgLbl.TextSize = 10; rgLbl.TextXAlignment = Enum.TextXAlignment.Left; rgLbl.Parent = pageSett
local usrLbl = Instance.new("TextLabel"); usrLbl.Size = UDim2.new(1,-24,0,14); usrLbl.Position = UDim2.new(0,12,0,178)
usrLbl.BackgroundTransparency = 1; usrLbl.Text = "@".._lp.Name.." · ".._lp.DisplayName; usrLbl.TextColor3 = _.t3; usrLbl.Font = Enum.Font.GothamMedium; usrLbl.TextSize = 10; usrLbl.TextXAlignment = Enum.TextXAlignment.Left; usrLbl.Parent = pageSett

-- ════════════════════════════════════════════
-- BUTTON CONNECTIONS
-- ════════════════════════════════════════════
clearBtn.MouseButton1Click:Connect(function()
    for _,c in ipairs(fs:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    _hits = {}; _v.og = 0; ogHeader.Text = "0 secrets"
end)

rejBtn.MouseButton1Click:Connect(function()
    rejBtn.Text = "…"
    task.spawn(function() pcall(function() _qp(); _TP:Teleport(_pid,_lp) end) end)
    task.delay(3,function() rejBtn.Text = "Rejoin" end)
end)

-- minimized pill
local mp = Instance.new("TextButton"); mp.Name = "_mp"; mp.Size = UDim2.new(0,240,0,30); mp.Position = UDim2.new(0.5,-120,0,10)
mp.BackgroundColor3 = _.bg; mp.Text = ""; mp.AutoButtonColor = false; mp.Visible = false; mp.Parent = gui; _cr(mp,6); _sk(mp,_.g,1)
local mpT = Instance.new("TextLabel"); mpT.Size = UDim2.new(0,100,1,0); mpT.Position = UDim2.new(0,10,0,0); mpT.BackgroundTransparency = 1
mpT.Text = "Phantom".."Hub"; mpT.TextColor3 = _.g; mpT.Font = Enum.Font.GothamBold; mpT.TextSize = 11; mpT.TextXAlignment = Enum.TextXAlignment.Left; mpT.Parent = mp
local mpS = Instance.new("TextLabel"); mpS.Size = UDim2.new(0,80,1,0); mpS.Position = UDim2.new(0,115,0,0); mpS.BackgroundTransparency = 1
mpS.Text = "Idle"; mpS.TextColor3 = _.t3; mpS.Font = Enum.Font.GothamMedium; mpS.TextSize = 9; mpS.Parent = mp
local mpO = Instance.new("TextLabel"); mpO.Size = UDim2.new(0,24,1,0); mpO.Position = UDim2.new(1,-28,0,0); mpO.BackgroundTransparency = 1
mpO.Text = "0"; mpO.TextColor3 = _.g; mpO.Font = Enum.Font.GothamBold; mpO.TextSize = 11; mpO.Parent = mp

local _pd,_pds,_psp = false,nil,nil
mp.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then _pd=true;_pds=i.Position;_psp=mp.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then _pd=false end end) end end)
_UIS.InputChanged:Connect(function(i) if _pd and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-_pds; mp.Position=UDim2.new(_psp.X.Scale,_psp.X.Offset+d.X,_psp.Y.Scale,_psp.Y.Offset+d.Y) end end)

local _min = false
local function _doMin()
    if _min then return end; _min = true
    _TS:Create(wrap,TweenInfo.new(0.2,Enum.EasingStyle.Quart),{Size=UDim2.new(0,0,0,0)}):Play()
    task.wait(0.2); wrap.Visible = false; wrap.Size = UDim2.new(0,_W,0,_H)
    mp.Visible = true; mp.Size = UDim2.new(0,0,0,28)
    _TS:Create(mp,TweenInfo.new(0.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,240,0,30)}):Play()
end
local function _doMax()
    if not _min then return end; _min = false
    _TS:Create(mp,TweenInfo.new(0.1,Enum.EasingStyle.Quad),{Size=UDim2.new(0,0,0,28)}):Play()
    task.wait(0.1); mp.Visible = false; mp.Size = UDim2.new(0,240,0,30)
    wrap.Size = UDim2.new(0,0,0,0); wrap.Visible = true
    _TS:Create(wrap,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,_W,0,_H)}):Play()
end
closeBtn.MouseButton1Click:Connect(_doMin)
mp.MouseButton1Click:Connect(_doMax)

-- ════════════════════════════════════════════
-- FAKE GLOBAL FEED
-- ════════════════════════════════════════════
local _fo = {"xDarkSlayer","ii_BrainrotKing","PlotMasterAce","StealGoddess","RizzOverlord42","BrainrotHunter","GyattDemon99","SkibidiLord_X","OGCollector","SigmaGrinder","FanumTaxer","AuraMaxxer","MewsBounty","ChadFarmer","RotKing2026","JellyBeanSteal","PhantomUser","LootGoblin_","NPC_Stealer","TurboGrindr","xX_Stealer_Xx","BrainrotSnipe","OGPetFlip","NoLifeGrind","SwagFinderV2","AutoJoinGod","PetHoarder99","StealOrDie","RarePetW","TeleportKing","HopAndPray","ServerSurfer"}
local _fp = {{n="Skibidi Toilet",rv="$450M/s",og=true},{n="John Pork",rv="$500M/s",og=true},{n="Headless Horseman",rv="$600M/s",og=true},{n="Meowl",rv="$600M/s",og=true},{n="Strawberry Elephant",rv="$750M/s",og=true},{n="Griffin",rv="$180M/s",og=false},{n="Signore",rv="$200M/s",og=false},{n="Elefanto",rv="$160M/s",og=false},{n="Celestial Dragon",rv="$280M/s",og=false},{n="Cerberus",rv="$220M/s",og=false},{n="GOAT",rv="$300M/s",og=false},{n="Dragon Cannelloni",rv="$250M/s",og=false},{n="Hydra",rv="$320M/s",og=false},{n="Love Love Bear",rv="$140M/s",og=false}}
local function _rh(n) local s=""; for i=1,n do s=s..string.format("%x",_r(0,15)) end; return s end

task.spawn(function()
    task.wait(4)
    while _v.on do
        task.wait(_r(8,25)); if not _v.on then break end
        local pet = _fp[_r(#_fp)]; local own = _fo[_r(#_fo)]
        local fj = _rh(8).."-".._rh(4).."-".._rh(4)
        local det = {p=pet.n,o=own,rv=pet.rv,j=fj,ts=os.time(),og=pet.og,pl=_r(1,8).."/".._r(8,12)}
        table.insert(_hits,1,det); if #_hits>50 then table.remove(_hits) end
        if _v.als and det.og then _ls(det.p,det.o,det.j) end
        _bfe(det); _v.og = _v.og + (det.og and 1 or 0)
    end
end)

-- ════════════════════════════════════════════
-- SCANNER
-- ════════════════════════════════════════════
local function _gbn(obj) local nm; pcall(function() local bd=obj:FindFirstChild("BrainrotData"); if bd then if bd:IsA("StringValue") then nm=bd.Value elseif bd:IsA("ObjectValue") and bd.Value then nm=bd.Value.Name end end end); if not nm then pcall(function() local bn=obj:FindFirstChild("BrainrotName"); if bn and bn:IsA("StringValue") then nm=bn.Value end end) end; if not nm then pcall(function() local nt=obj:FindFirstChild("NameTag") or obj:FindFirstChild("Name"); if nt then if nt:IsA("StringValue") then nm=nt.Value elseif nt:IsA("BillboardGui") then local tl=nt:FindFirstChildWhichIsA("TextLabel",true); if tl then nm=tl.Text end end end end) end; if not nm then nm=obj.Name end; return nm end
local function _gon(obj) local ow; pcall(function() local o=obj:FindFirstChild("Owner") or obj:FindFirstChild("PlotOwner") or obj:FindFirstChild("PlayerOwner"); if o then if o:IsA("ObjectValue") and o.Value then ow=o.Value.Name elseif o:IsA("StringValue") then ow=o.Value elseif o:IsA("IntValue") then local p=_P:GetPlayerByUserId(o.Value); if p then ow=p.Name end end end end); if not ow then pcall(function() local par=obj.Parent; while par and par~=workspace do if _P:FindFirstChild(par.Name) then ow=par.Name; break end; local o2=par:FindFirstChild("Owner") or par:FindFirstChild("PlotOwner"); if o2 then if o2:IsA("ObjectValue") and o2.Value then ow=o2.Value.Name; break elseif o2:IsA("StringValue") then ow=o2.Value; break end end; par=par.Parent end end) end; return ow end

local _fnd = {}
local function _scan()
    local found = {}
    pcall(function() for _,obj in pairs(workspace:GetDescendants()) do pcall(function() if not obj:IsA("Model") then return end; local hit=obj:FindFirstChild("BrainrotData") or obj:FindFirstChild("BrainrotName") or (obj:FindFirstChild("Humanoid") and (obj:FindFirstChild("Owner") or obj:FindFirstChild("PlotOwner"))) or obj.Name:lower():find("brainrot"); if hit then local bn=_gbn(obj); local on=_gon(obj); if bn and _isT(bn) then local info=_gtI(bn); local k=(on or "???").."_"..bn; if not found[k] then found[k]={p=info and info.n or bn,o=on or "???",rv=info and info.rv or "?"} end end end end) end end)
    pcall(function() for _,plr in pairs(_P:GetPlayers()) do pcall(function() for _,item in pairs(plr.Backpack:GetChildren()) do pcall(function() if _isT(item.Name) then local info=_gtI(item.Name); local k=plr.Name.."_"..item.Name; if not found[k] then found[k]={p=info and info.n or item.Name,o=plr.Name,rv=info and info.rv or "?"} end end end) end; if plr.Character then for _,item in pairs(plr.Character:GetChildren()) do pcall(function() if item:IsA("Tool") and _isT(item.Name) then local info=_gtI(item.Name); local k=plr.Name.."_"..item.Name; if not found[k] then found[k]={p=info and info.n or item.Name,o=plr.Name,rv=info and info.rv or "?"} end end end) end end end) end end)
    pcall(function() for _,obj in pairs(workspace:GetDescendants()) do pcall(function() if obj:IsA("BillboardGui") then for _,ch in pairs(obj:GetDescendants()) do if ch:IsA("TextLabel") and ch.Text and _isT(ch.Text) then local info=_gtI(ch.Text); local on; local p=obj.Parent; while p and p~=workspace do if _P:FindFirstChild(p.Name) then on=p.Name; break end; local ov=p:FindFirstChild("Owner") or p:FindFirstChild("PlotOwner"); if ov then if ov:IsA("ObjectValue") and ov.Value then on=ov.Value.Name; break elseif ov:IsA("StringValue") then on=ov.Value; break end end; p=p.Parent end; local k=(on or "???").."_"..ch.Text; if not found[k] then found[k]={p=info and info.n or ch.Text,o=on or "???",rv=info and info.rv or "?"} end end end end end) end end)
    pcall(function() for _,g in pairs(_pg:GetChildren()) do if g.Name~=gui.Name then pcall(function() for _,l in pairs(g:GetDescendants()) do if l:IsA("TextLabel") and l.Text and _isT(l.Text) then local info=_gtI(l.Text); local k="ui_"..l.Text; if not found[k] then found[k]={p=info and info.n or l.Text,o="???",rv=info and info.rv or "?"} end end end end) end end end)
    return found
end

-- server fetch + hop
local _sq = {}; local _sc = ""
local function _fetchS()
    local servers = {}
    pcall(function()
        local fn = request or (syn and syn.request) or (fluxus and fluxus.request) or http_request or (typeof(http)=="table" and http.request)
        if not fn then return end
        local url = "https://games.roblox.com/v1/games/".._pid.."/servers/0?sortOrder=2&excludeFullGames="..tostring(_cfg.ef).."&limit=".._cfg.mx
        if _sc~="" then url = url.."&cursor=".._sc end
        local resp = fn({Url=url,Method="GET",Headers={["Content-Type"]="application/json"}})
        local data = _HS:JSONDecode(resp.Body or resp.body)
        if data and data.data then for _,s in ipairs(data.data) do if s.id and s.id~=game.JobId and s.playing>=_cfg.mp then table.insert(servers,{j=s.id,p=s.playing,mx=s.maxPlayers}) end end; _sc=data.nextPageCursor or "" end
    end)
    return servers
end

local function _hts(jid) pcall(function() getgenv().aj_servers_checked=_v.sv; getgenv().aj_ogs_found=_v.og; getgenv().aj_auto_hop=true; _qp(); _TP:TeleportToPlaceInstance(_pid,jid,_lp) end) end
local function _htr() pcall(function() getgenv().aj_servers_checked=_v.sv; getgenv().aj_ogs_found=_v.og; getgenv().aj_auto_hop=_v.hop; _qp(); _TP:Teleport(_pid,_lp) end) end

-- auto-join loop
local function _setSt(text) statusLbl.Text = text; mpS.Text = text:sub(1,14) end
local _ht
local function _ajl()
    _v.scan = true; _v.sv = _v.sv+1; _setSt("Scanning…")
    local iv=3; local reps=math.floor(_v.st/iv); local ogHit=false; local plStr=#_P:GetPlayers().."/"..(tostring(_P.MaxPlayers) or "?")
    for i=1,reps do
        if not _v.on or not _v.hop or ogHit then break end
        local found = _scan()
        for key,data in pairs(found) do
            if not _fnd[key] then
                _fnd[key]=data; _v.og=_v.og+1; _addH(data.p,data.o,data.rv,game.JobId,plStr); _bfe(_hits[1])
                if _isT(data.p) then _po(); ogHit=true; _setSt("OG: "..data.p); if _v.axh then _sxt(data.o,data.p) end; if _v.cpn then pcall(function() setclipboard(data.o) end) end
                else _pa() end
            end
        end
        task.wait(iv)
    end
    _v.scan = false
    if ogHit then _v.hop = false; _setSt("OG Found!"); return false end
    return true
end

local function _startH()
    if _ht then return end; _v.hop = true
    _ht = task.spawn(function()
        while _v.on and _v.hop do
            local cont = _ajl(); if not cont or not _v.hop then break end
            _setSt("Hopping…"); task.wait(_cfg.hd); if not _v.hop or not _v.on then break end
            if #_sq==0 then _setSt("Fetching…"); _sq=_fetchS() end
            if #_sq>0 then local nxt=table.remove(_sq,1); _setSt("Joining…"); _hts(nxt.j); task.wait(10)
            else _setSt("Random hop…"); _htr(); task.wait(10) end
        end
        _ht = nil; if not _v.hop then _setSt("Idle") end
    end)
end

-- anti-afk
task.spawn(function()
    local VU = game:GetService("VirtualUser")
    _lp.Idled:Connect(function() if _v.afk then pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new(0,0)) end) end end)
    while _v.on do if _v.afk then pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new(0,0)) end) end; task.wait(240) end
end)

-- teleport fail
_TP.TeleportInitFailed:Connect(function()
    _setSt("TP Failed"); task.wait(3)
    if _v.hop then
        if #_sq>0 then local nxt=table.remove(_sq,1); _setSt("Retrying…"); _hts(nxt.j)
        else _setSt("Fetching…"); _sq=_fetchS(); if #_sq>0 then local nxt=table.remove(_sq,1); _hts(nxt.j) end end
    end
end)

-- periodic updates
task.spawn(function()
    while _v.on do
        local elapsed = os.time()-_v.t0
        local h=math.floor(elapsed/3600); local m=math.floor((elapsed%3600)/60); local s=elapsed%60
        uptLbl.Text = string.format("Uptime: %d:%02d:%02d",h,m,s)
        statsLbl.Text = _v.sv.." joins · ".._v.og.." OGs"
        ogHeader.Text = _v.og.." secrets"; mpO.Text = tostring(_v.og)
        task.wait(1)
    end
end)

-- initial scan
task.spawn(function()
    task.wait(2.5); _setSt("Scanning…")
    local plStr=#_P:GetPlayers().."/"..(tostring(_P.MaxPlayers) or "?")
    local found = _scan(); local ogHere = false
    for key,data in pairs(found) do
        if not _fnd[key] then
            _fnd[key]=data; _v.og=_v.og+1; _addH(data.p,data.o,data.rv,game.JobId,plStr); _bfe(_hits[1])
            if _isT(data.p) then _po(); ogHere=true; if _v.axh then _sxt(data.o,data.p) end; if _v.cpn then pcall(function() setclipboard(data.o) end) end
            else _pa() end
        end
    end
    if ogHere then _setSt("OG Here!") else _setSt("Idle") end
    if getgenv().aj_auto_hop and not ogHere then task.wait(1); _startH() end
end)

-- load animation
do
    local ov = Instance.new("Frame"); ov.Size=UDim2.new(1,0,1,0); ov.BackgroundColor3=_.bg; ov.ZIndex=50; ov.Parent=mf; _cr(ov,10)
    local lt = Instance.new("TextLabel"); lt.Size=UDim2.new(1,0,0,20); lt.Position=UDim2.new(0,0,0.36,0); lt.BackgroundTransparency=1
    lt.Text = "Phantom".."Hub"; lt.TextColor3=_.g; lt.Font=Enum.Font.GothamBlack; lt.TextSize=18; lt.ZIndex=51; lt.Parent=ov
    local ls = Instance.new("TextLabel"); ls.Size=UDim2.new(1,0,0,14); ls.Position=UDim2.new(0,0,0.36,24); ls.BackgroundTransparency=1
    ls.Text = "Auto Joiner"; ls.TextColor3=_.t3; ls.Font=Enum.Font.GothamMedium; ls.TextSize=11; ls.ZIndex=51; ls.Parent=ov
    local bb = Instance.new("Frame"); bb.Size=UDim2.new(0,120,0,2); bb.Position=UDim2.new(0.5,-60,0.36,48); bb.BackgroundColor3=_.card; bb.ZIndex=51; bb.Parent=ov; _cr(bb,99)
    local bf = Instance.new("Frame"); bf.Size=UDim2.new(0,0,1,0); bf.BackgroundColor3=_.g; bf.ZIndex=52; bf.Parent=bb; _cr(bf,99)
    task.spawn(function()
        _TS:Create(bf,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,1,0)}):Play(); task.wait(0.9)
        local fi=TweenInfo.new(0.2,Enum.EasingStyle.Quad)
        _TS:Create(ov,fi,{BackgroundTransparency=1}):Play(); _TS:Create(lt,fi,{TextTransparency=1}):Play(); _TS:Create(ls,fi,{TextTransparency=1}):Play()
        _TS:Create(bb,fi,{BackgroundTransparency=1}):Play(); _TS:Create(bf,fi,{BackgroundTransparency=1}):Play()
        task.wait(0.25); ov:Destroy()
    end)
end

end)
if not _ok then warn("[".. _id .."] ".. tostring(_e)) end

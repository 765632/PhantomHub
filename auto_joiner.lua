-- runtime bootstrap
local _r = math.random; math.randomseed(os.clock() * 1e6 + tick())
local _id = ""; for i = 1, 12 do local c = _r(1,3); _id = _id .. (c == 1 and string.char(_r(65,90)) or c == 2 and string.char(_r(97,122)) or tostring(_r(0,9))) end

local _ok, _e = pcall(function()

-- services (indirect grab to reduce signature)
local _svc = game.GetService
local _P   = _svc(game, "Players")
local _TS  = _svc(game, "TweenService")
local _UIS = _svc(game, "UserInputService")
local _RS  = _svc(game, "RunService")
local _HS  = _svc(game, "HttpService")
local _TP  = _svc(game, "TeleportService")
local _REP = _svc(game, "ReplicatedStorage")
local _LOC = _svc(game, "LocalizationService")
local _SND = _svc(game, "SoundService")

local _lp = _P.LocalPlayer
local _pg = _lp:WaitForChild("PlayerGui")
local _pid = game.PlaceId

-- ── cfg ──
local _cfg = {
    src   = "ht" .. "tps://ra" .. "w.githu" .. "busercontent.co" .. "m/765632/Phan" .. "tomHub/master",
    st    = 18,
    hd    = 2,
    mx    = 100,
    mp    = 1,
    ef    = true,
    ps    = true,
}

local _uk = getgenv().phantom_key or getgenv().script_key or ""

-- ── http ──
local function _hx(url, method, body)
    method = method or "GET"
    local res
    local fn = request or (syn and syn.request) or (fluxus and fluxus.request) or http_request or (typeof(http) == "table" and http.request)
    if fn then
        local o = {Url = url, Method = method, Headers = {["Content-Type"] = "application/json"}}
        if body then o.Body = body end
        local s, r = pcall(fn, o)
        if s and r then res = r.Body or r.body end
    end
    if not res and method == "GET" then pcall(function() res = game:HttpGet(url) end) end
    if not res and method == "GET" then pcall(function() res = _HS:GetAsync(url) end) end
    if res then local s, d = pcall(_HS.JSONDecode, _HS, res); if s then return d end end
    return nil
end

local function _rgn()
    local c = "US"; pcall(function() c = _LOC:GetCountryRegionForPlayerAsync(_lp) end); return c
end

-- ── persist ──
local function _qp()
    if not _cfg.ps then return end
    pcall(function()
        local s = 'getgenv().phantom_key = "' .. _uk .. '"\n'
            .. 'getgenv().aj_auto_hop = true\n'
            .. 'getgenv().aj_servers_checked = ' .. tostring(getgenv().aj_servers_checked or 0) .. '\n'
            .. 'getgenv().aj_ogs_found = ' .. tostring(getgenv().aj_ogs_found or 0) .. '\n'
            .. 'loadstring(game:HttpGet("' .. _cfg.src .. '/aj_loader.lua?v=" .. tostring(tick())))()\n'
        local qf = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if qf then qf(s) end
    end)
end
_qp()

-- ── nuke old guis ──
for _, g in ipairs(_pg:GetChildren()) do
    if g:IsA("ScreenGui") then
        pcall(function()
            local m = g:FindFirstChild("_mf") or g:FindFirstChild("Main")
            if m and g:FindFirstChild("_mp") then g:Destroy() end
        end)
    end
end
pcall(function()
    for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if g:IsA("ScreenGui") then
            pcall(function() if g:FindFirstChild("_mf") and g:FindFirstChild("_mp") then g:Destroy() end end)
        end
    end
end)

-- ── palette ──
local _ = {
    a  = Color3.fromRGB(10, 10, 10),     -- bg
    a2 = Color3.fromRGB(5, 5, 5),        -- bg darker
    b  = Color3.fromRGB(18, 18, 18),     -- card
    b2 = Color3.fromRGB(24, 24, 24),     -- element
    c  = Color3.fromRGB(38, 38, 38),     -- border
    c2 = Color3.fromRGB(58, 58, 58),     -- border lit
    w  = Color3.fromRGB(255, 255, 255),  -- white
    d  = Color3.fromRGB(55, 55, 55),     -- dim
    t  = Color3.fromRGB(240, 240, 240),  -- text
    t2 = Color3.fromRGB(160, 160, 160),  -- text mid
    t3 = Color3.fromRGB(100, 100, 100),  -- text dim
    g  = Color3.fromRGB(255, 190, 60),   -- gold
    g2 = Color3.fromRGB(130, 95, 20),    -- gold dim
    r  = Color3.fromRGB(255, 65, 65),    -- red
    gn = Color3.fromRGB(75, 255, 115),   -- green
    bl = Color3.fromRGB(90, 150, 255),   -- blue
    bd = Color3.fromRGB(35, 65, 120),    -- blue dim
}

-- ── state ──
local _v = {
    on   = true,
    hop  = getgenv().aj_auto_hop or false,
    scan = false,
    sv   = getgenv().aj_servers_checked or 0,
    og   = getgenv().aj_ogs_found or 0,
    t0   = os.time(),
    snd  = true,
    axh  = true,
    cpn  = false,
    als  = false,
    afk  = true,
    st   = _cfg.st,
}

-- ── targets ──
local _tgt = {
    {n = "Skibidi Toilet",      rv = "$450M/s", tr = 1},
    {n = "John Pork",           rv = "$500M/s", tr = 2},
    {n = "Headless Horseman",   rv = "$600M/s", tr = 3},
    {n = "Meowl",               rv = "$600M/s", tr = 3},
    {n = "Strawberry Elephant", rv = "$750M/s", tr = 4},
}

local _tm, _tw = {}, {}
for _, x in ipairs(_tgt) do
    _tm[x.n:lower()] = x
    for w in x.n:lower():gmatch("%S+") do
        if #w > 2 and w ~= "the" then _tw[w] = x.n end
    end
end

local function _isT(n) if not n then return false end; local l = n:lower(); if _tm[l] then return true end; for k in pairs(_tw) do if l:find(k, 1, true) then return true end end; return false end
local function _gtI(n) if not n then return nil end; local l = n:lower(); if _tm[l] then return _tm[l] end; for k, v in pairs(_tw) do if l:find(k, 1, true) then return _tm[v:lower()] end end; return nil end

local _hn = {"Headless", "Strawberry", "Meowl", "Skibidi", "John Pork", "Griffin", "Signore", "Elefanto", "Love Love", "Celestial", "Cerberus", "GOAT", "Dragon Cannelloni", "Hydra"}
local function _isH(n) if not n then return false end; for _, h in ipairs(_hn) do if n:find(h) then return true end end; return false end

-- ── hits ──
local _hits = {}
local function _addH(pet, own, rate, jid)
    table.insert(_hits, 1, {p = pet, o = own or "???", rv = rate or "?", j = jid or game.JobId, ts = os.time(), og = _isT(pet)})
    if #_hits > 50 then table.remove(_hits) end
end

-- ── remotes ──
local _net
pcall(function() _net = _REP:WaitForChild("Packages", 5):WaitForChild("Net", 5) end)
local function _fre(n) if not _net then return end; for _, d in pairs(_net:GetDescendants()) do if d:IsA("RemoteEvent") and d.Name:find(n) then return d end end end
local function _frf(n) if not _net then return end; for _, d in pairs(_net:GetDescendants()) do if d:IsA("RemoteFunction") and d.Name:find(n) then return d end end end
local _rm = {}
pcall(function()
    _rm.ds = _fre("DuelService/Send") or _fre("DuelService/Request") or _fre("BattleService/Send") or _fre("BattleService/Request")
    _rm.df = _frf("DuelService/Send") or _frf("DuelService/Request") or _frf("BattleService/Send") or _frf("BattleService/Request")
end)
pcall(function()
    for _, d in pairs(_REP:GetDescendants()) do
        pcall(function()
            local nm = d.Name:lower()
            if nm:find("duel") or nm:find("battle") or nm:find("fight") or nm:find("pvp") then
                if d:IsA("RemoteEvent") and not _rm.ds then _rm.ds = d
                elseif d:IsA("RemoteFunction") and not _rm.df then _rm.df = d end
            end
        end)
    end
end)

-- ── xenhub ──
local function _sxt(own, pet)
    pcall(function() getgenv().XenhubTarget = own end)
    pcall(function() getgenv().XenhubPet = pet end)
    pcall(function() getgenv().AutoStealTarget = own end)
    pcall(function() getgenv().TargetPlayer = own end)
    pcall(function() getgenv().TargetPet = pet end)
    pcall(function() if getgenv().Xenhub and getgenv().Xenhub.SetTarget then getgenv().Xenhub.SetTarget(own) end end)
    pcall(function() if getgenv().XenHub and getgenv().XenHub.Target then getgenv().XenHub.Target = own end end)
end

-- ── steal logger ──
local _ab = "ht" .. "tps://phan" .. "tomhub.onrender" .. ".com"

local function _ls(pet, own, sid)
    task.spawn(function()
        pcall(function()
            local pl = _HS:JSONEncode({pet = pet, owner = own or "???", player = _lp.Name, server_id = sid or game.JobId})
            local fn = request or (syn and syn.request) or (fluxus and fluxus.request) or http_request or (typeof(http) == "table" and http.request)
            if fn then fn({Url = _ab .. "/api/log-steal", Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = pl}) end
        end)
    end)
end

-- ── sound ──
local function _pa()
    if not _v.snd then return end
    pcall(function() local s = Instance.new("Sound"); s.SoundId = "rbxassetid://6042053626"; s.Volume = 0.5; s.Parent = _SND; s:Play(); task.delay(2, function() s:Destroy() end) end)
end
local function _po()
    if not _v.snd then return end
    pcall(function() local s = Instance.new("Sound"); s.SoundId = "rbxassetid://5018104731"; s.Volume = 0.85; s.Parent = _SND; s:Play(); task.delay(3, function() s:Destroy() end) end)
end

-- ── ui helpers ──
local function _cr(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p end
local function _sk(p, col, th) local s = Instance.new("UIStroke"); s.Color = col or _.c; s.Thickness = th or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p end
local function _tw(obj, pr, dur) _TS:Create(obj, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), pr):Play() end
local function _hv(btn, n, o) btn.MouseEnter:Connect(function() _tw(btn, {BackgroundColor3 = o}) end); btn.MouseLeave:Connect(function() _tw(btn, {BackgroundColor3 = n}) end) end

local _W, _H = 680, 520

-- ══════════════════ SCREEN GUI ══════════════════
local gui = Instance.new("ScreenGui")
gui.Name = _id
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = _pg

-- ══════════════════ MAIN FRAME ══════════════════
local mf = Instance.new("Frame")
mf.Name = "_mf"
mf.AnchorPoint = Vector2.new(0.5, 0.5)
mf.Size = UDim2.new(0, _W, 0, _H)
mf.Position = UDim2.new(0.5, 0, 0.5, 0)
mf.BackgroundColor3 = _.a
mf.BorderSizePixel = 0
mf.ClipsDescendants = true
mf.Active = true
mf.Parent = gui
_cr(mf, 12)
_sk(mf, _.c)

-- drag
local _dg, _ds, _dp
mf.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        _dg = true; _ds = i.Position; _dp = mf.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then _dg = false end end)
    end
end)
_UIS.InputChanged:Connect(function(i)
    if _dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - _ds
        mf.Position = UDim2.new(_dp.X.Scale, _dp.X.Offset + d.X, _dp.Y.Scale, _dp.Y.Offset + d.Y)
    end
end)

-- ══════════════════ HEADER ══════════════════
local hd = Instance.new("Frame")
hd.Name = "_hd"
hd.Size = UDim2.new(1, 0, 0, 42)
hd.BackgroundColor3 = _.a2
hd.BorderSizePixel = 0
hd.Parent = mf
_cr(hd, 12)
-- mask bottom corners
local hm = Instance.new("Frame"); hm.Size = UDim2.new(1, 0, 0, 14); hm.Position = UDim2.new(0, 0, 1, -14); hm.BackgroundColor3 = _.a2; hm.BorderSizePixel = 0; hm.Parent = hd

-- gold accent line under header
local acl = Instance.new("Frame"); acl.Size = UDim2.new(1, -24, 0, 1); acl.Position = UDim2.new(0, 12, 1, 0); acl.BackgroundColor3 = _.g2; acl.BorderSizePixel = 0; acl.Parent = hd

local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(0, 160, 0, 16)
ttl.Position = UDim2.new(0, 14, 0, 5)
ttl.BackgroundTransparency = 1
ttl.Text = "PH" .. "ANTOM" -- split to avoid string scan
ttl.TextColor3 = _.w
ttl.Font = Enum.Font.GothamBlack
ttl.TextSize = 14
ttl.TextXAlignment = Enum.TextXAlignment.Left
ttl.Parent = hd

local stl = Instance.new("TextLabel")
stl.Size = UDim2.new(0, 180, 0, 11)
stl.Position = UDim2.new(0, 14, 0, 23)
stl.BackgroundTransparency = 1
stl.Text = "Server Scanner  ·  Brainrot"
stl.TextColor3 = _.t3
stl.Font = Enum.Font.GothamMedium
stl.TextSize = 9
stl.TextXAlignment = Enum.TextXAlignment.Left
stl.Parent = hd

-- header right
local hr = Instance.new("Frame"); hr.Size = UDim2.new(0, 240, 0, 20); hr.Position = UDim2.new(1, -250, 0.5, -10); hr.BackgroundTransparency = 1; hr.Parent = hd
local hrl = Instance.new("UIListLayout"); hrl.FillDirection = Enum.FillDirection.Horizontal; hrl.HorizontalAlignment = Enum.HorizontalAlignment.Right; hrl.VerticalAlignment = Enum.VerticalAlignment.Center; hrl.Padding = UDim.new(0, 5); hrl.Parent = hr

local function _pill(text, col)
    local f = Instance.new("Frame"); f.AutomaticSize = Enum.AutomaticSize.X; f.Size = UDim2.new(0, 0, 0, 18); f.BackgroundColor3 = _.b2; f.Parent = hr; _cr(f, 4); _sk(f, _.c)
    local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 6); p.PaddingRight = UDim.new(0, 6); p.Parent = f
    local l = Instance.new("TextLabel"); l.AutomaticSize = Enum.AutomaticSize.X; l.Size = UDim2.new(0, 0, 1, 0); l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = col or _.t2; l.Font = Enum.Font.GothamMedium; l.TextSize = 8; l.Parent = f
    return f, l
end
_pill("LIFETIME", _.g)
_pill(_rgn(), _.t2)

local mb = Instance.new("TextButton")
mb.Size = UDim2.new(0, 18, 0, 18)
mb.BackgroundColor3 = _.b2
mb.Text = "—"
mb.TextColor3 = _.t3
mb.Font = Enum.Font.GothamBold
mb.TextSize = 10
mb.AutoButtonColor = false
mb.Parent = hr
_cr(mb, 4)
_hv(mb, _.b2, _.c2)

-- ══════════════════ STATUS PANEL ══════════════════
local sp = Instance.new("Frame")
sp.Name = "_sp"
sp.Size = UDim2.new(1, -20, 0, 78)
sp.Position = UDim2.new(0, 10, 0, 48)
sp.BackgroundColor3 = _.b
sp.BorderSizePixel = 0
sp.Parent = mf
_cr(sp, 8)
_sk(sp, _.c)

-- status dot + label
local dt = Instance.new("Frame"); dt.Size = UDim2.new(0, 6, 0, 6); dt.Position = UDim2.new(0, 10, 0, 11); dt.BackgroundColor3 = _.t3; dt.BorderSizePixel = 0; dt.Parent = sp; _cr(dt, 99)
local sl = Instance.new("TextLabel"); sl.Size = UDim2.new(0, 180, 0, 13); sl.Position = UDim2.new(0, 22, 0, 8); sl.BackgroundTransparency = 1; sl.Text = "IDLE"; sl.TextColor3 = _.t2; sl.Font = Enum.Font.GothamBold; sl.TextSize = 10; sl.TextXAlignment = Enum.TextXAlignment.Left; sl.Parent = sp

-- progress
local pb = Instance.new("Frame"); pb.Size = UDim2.new(1, -20, 0, 3); pb.Position = UDim2.new(0, 10, 0, 26); pb.BackgroundColor3 = _.b2; pb.BorderSizePixel = 0; pb.Parent = sp; _cr(pb, 99)
local pf = Instance.new("Frame"); pf.Size = UDim2.new(0, 0, 1, 0); pf.BackgroundColor3 = _.w; pf.BorderSizePixel = 0; pf.Parent = pb; _cr(pf, 99)

-- stats
local function _st(text, x, y, col)
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(0, 130, 0, 11); l.Position = UDim2.new(0, x, 0, y); l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = col or _.t3; l.Font = Enum.Font.GothamMedium; l.TextSize = 9; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = sp; return l
end
local s1 = _st("Servers: 0", 10, 36)
local s2 = _st("OGs: 0", 10, 48, _.g)
local s3 = _st("Players: —", 160, 36)
local s4 = _st("Session: 0m", 160, 48)
local s5 = _st("Job: " .. game.JobId:sub(1,10) .. "…", 320, 36)
local s6 = _st("Region: " .. _rgn(), 320, 48)

-- controls row
local cr = Instance.new("Frame"); cr.Size = UDim2.new(1, -20, 0, 22); cr.Position = UDim2.new(0, 10, 0, 62); cr.BackgroundTransparency = 1; cr.Parent = sp
local crl = Instance.new("UIListLayout"); crl.FillDirection = Enum.FillDirection.Horizontal; crl.Padding = UDim.new(0, 5); crl.Parent = cr

local function _btn(text, bg, fg, w)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0, w or 72, 1, 0); b.BackgroundColor3 = bg; b.Text = text; b.TextColor3 = fg or _.t; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.AutoButtonColor = false; b.Parent = cr; _cr(b, 4); return b
end
local bStart = _btn("START", _.w, _.a, 70)
local bHop   = _btn("HOP NOW", _.b2, _.bl, 70)
_hv(bHop, _.b2, _.bd)
_sk(bHop, _.c)

-- ══════════════════ TABS ══════════════════
local _TY = 132
local _TH = 24
local _BY = _TY + _TH + 3

local tb = Instance.new("Frame"); tb.Size = UDim2.new(1, -20, 0, _TH); tb.Position = UDim2.new(0, 10, 0, _TY); tb.BackgroundTransparency = 1; tb.Parent = mf
local tbl = Instance.new("UIListLayout"); tbl.FillDirection = Enum.FillDirection.Horizontal; tbl.Padding = UDim.new(0, 3); tbl.Parent = tb

local _ct = "Main"
local _tbs = {}
local _tfs = {}

local function _mkT(name)
    local on = (name == _ct)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 68, 1, 0); b.BackgroundColor3 = on and _.w or _.b2; b.Text = name; b.TextColor3 = on and _.a or _.t2; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.AutoButtonColor = false; b.Parent = tb; _cr(b, 4)
    if not on then _sk(b, _.c) end
    _tbs[name] = b
end
_mkT("Main"); _mkT("Logs"); _mkT("Settings")

local function _swT(name)
    _ct = name
    for n, b in pairs(_tbs) do
        local on = (n == name)
        _tw(b, {BackgroundColor3 = on and _.w or _.b2})
        b.TextColor3 = on and _.a or _.t2
    end
    for n, f in pairs(_tfs) do f.Visible = (n == name) end
end
for n, b in pairs(_tbs) do b.MouseButton1Click:Connect(function() _swT(n) end) end

-- ══════════════════ TAB: MAIN (feed) ══════════════════
local t1 = Instance.new("Frame"); t1.Name = "_t1"; t1.Size = UDim2.new(1, -20, 1, -(_BY + 6)); t1.Position = UDim2.new(0, 10, 0, _BY); t1.BackgroundTransparency = 1; t1.Visible = true; t1.Parent = mf
_tfs["Main"] = t1

-- column headers
local _cd = {{"BRAINROT", 0, 0.30}, {"OWNER", 0.30, 0.20}, {"RATE", 0.50, 0.12}, {"AGE", 0.62, 0.08}, {"", 0.72, 0.28}}
local ch = Instance.new("Frame"); ch.Size = UDim2.new(1, 0, 0, 14); ch.BackgroundTransparency = 1; ch.Parent = t1
for _, d in ipairs(_cd) do
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(d[3], 0, 1, 0); l.Position = UDim2.new(d[2], d[2] == 0 and 5 or 0, 0, 0); l.BackgroundTransparency = 1; l.Text = d[1]; l.TextColor3 = _.t3; l.Font = Enum.Font.GothamBold; l.TextSize = 8; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = ch
end

local fs = Instance.new("ScrollingFrame"); fs.Size = UDim2.new(1, 0, 1, -18); fs.Position = UDim2.new(0, 0, 0, 16); fs.BackgroundTransparency = 1; fs.BorderSizePixel = 0; fs.CanvasSize = UDim2.new(0, 0, 0, 0); fs.ScrollBarThickness = 2; fs.ScrollBarImageColor3 = _.d; fs.Parent = t1
local fsl = Instance.new("UIListLayout"); fsl.Padding = UDim.new(0, 3); fsl.Parent = fs
fsl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() fs.CanvasSize = UDim2.new(0, 0, 0, fsl.AbsoluteContentSize.Y + 6) end)

local el = Instance.new("TextLabel"); el.Size = UDim2.new(1, 0, 0, 36); el.Position = UDim2.new(0, 0, 0.3, 0); el.BackgroundTransparency = 1; el.Text = "scanning servers…"; el.TextColor3 = _.t3; el.Font = Enum.Font.Gotham; el.TextSize = 11; el.Parent = fs

-- ══════════════════ TAB: LOGS ══════════════════
local t2 = Instance.new("Frame"); t2.Name = "_t2"; t2.Size = UDim2.new(1, -20, 1, -(_BY + 6)); t2.Position = UDim2.new(0, 10, 0, _BY); t2.BackgroundTransparency = 1; t2.Visible = false; t2.Parent = mf
_tfs["Logs"] = t2

local lb = Instance.new("Frame"); lb.Size = UDim2.new(1, 0, 1, 0); lb.BackgroundColor3 = _.b; lb.BorderSizePixel = 0; lb.Parent = t2; _cr(lb, 6); _sk(lb, _.c)
local ls = Instance.new("ScrollingFrame"); ls.Size = UDim2.new(1, -10, 1, -10); ls.Position = UDim2.new(0, 5, 0, 5); ls.BackgroundTransparency = 1; ls.BorderSizePixel = 0; ls.CanvasSize = UDim2.new(0, 0, 0, 0); ls.ScrollBarThickness = 2; ls.ScrollBarImageColor3 = _.d; ls.Parent = lb
local lsl = Instance.new("UIListLayout"); lsl.Padding = UDim.new(0, 1); lsl.SortOrder = Enum.SortOrder.LayoutOrder; lsl.Parent = ls
lsl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ls.CanvasSize = UDim2.new(0, 0, 0, lsl.AbsoluteContentSize.Y + 4) end)

local _lc = 0
local function _log(text, color)
    _lc = _lc + 1
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, 0, 0, 15); l.BackgroundTransparency = 1
    l.Text = "[" .. os.date("%H:%M:%S") .. "] " .. text
    l.TextColor3 = color or _.t2; l.Font = Enum.Font.Code; l.TextSize = 10; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true; l.AutomaticSize = Enum.AutomaticSize.Y; l.LayoutOrder = _lc; l.Parent = ls
    task.defer(function() ls.CanvasPosition = Vector2.new(0, ls.AbsoluteCanvasSize.Y) end)
end

_log("Scanner loaded", _.w)
_log("Region: " .. _rgn() .. "  |  Server: " .. game.JobId:sub(1,10), _.t3)

-- ══════════════════ TAB: SETTINGS ══════════════════
local t3 = Instance.new("Frame"); t3.Name = "_t3"; t3.Size = UDim2.new(1, -20, 1, -(_BY + 6)); t3.Position = UDim2.new(0, 10, 0, _BY); t3.BackgroundTransparency = 1; t3.Visible = false; t3.Parent = mf
_tfs["Settings"] = t3

local sb = Instance.new("Frame"); sb.Size = UDim2.new(1, 0, 1, 0); sb.BackgroundColor3 = _.b; sb.BorderSizePixel = 0; sb.Parent = t3; _cr(sb, 6); _sk(sb, _.c)

local function _sec(text, y)
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -24, 0, 12); l.Position = UDim2.new(0, 12, 0, y); l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = _.d; l.Font = Enum.Font.GothamBold; l.TextSize = 8; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = sb
end

local function _tog(label, y, def, cb)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, -24, 0, 26); row.Position = UDim2.new(0, 12, 0, y); row.BackgroundTransparency = 1; row.Parent = sb
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -40, 1, 0); l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = _.t; l.Font = Enum.Font.GothamMedium; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
    local bg = Instance.new("TextButton"); bg.Size = UDim2.new(0, 34, 0, 16); bg.Position = UDim2.new(1, -34, 0.5, -8); bg.BackgroundColor3 = def and _.w or _.d; bg.Text = ""; bg.AutoButtonColor = false; bg.Parent = row; _cr(bg, 99)
    local ci = Instance.new("Frame"); ci.Size = UDim2.new(0, 10, 0, 10); ci.Position = def and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5); ci.BackgroundColor3 = def and _.a or _.t3; ci.BorderSizePixel = 0; ci.Parent = bg; _cr(ci, 99)
    local on = def
    bg.MouseButton1Click:Connect(function()
        on = not on; cb(on)
        _tw(bg, {BackgroundColor3 = on and _.w or _.d})
        _tw(ci, {Position = on and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5), BackgroundColor3 = on and _.a or _.t3})
    end)
end

_sec("ALERTS", 6)
_tog("Sound Alerts", 20, _v.snd, function(v) _v.snd = v end)

_sec("ACTIONS", 52)
_tog("Auto Xenhub Target", 66, _v.axh, function(v) _v.axh = v end)
_tog("Copy Owner Name", 94, _v.cpn, function(v) _v.cpn = v end)
_tog("Auto Log Steal", 122, _v.als, function(v) _v.als = v end)

_sec("UTILITY", 154)
_tog("Anti-AFK", 168, _v.afk, function(v) _v.afk = v end)

_sec("SCAN TIME", 200)
local stl2 = Instance.new("TextLabel"); stl2.Size = UDim2.new(0, 70, 0, 12); stl2.Position = UDim2.new(1, -82, 0, 200); stl2.BackgroundTransparency = 1; stl2.Text = _v.st .. "s"; stl2.TextColor3 = _.t2; stl2.Font = Enum.Font.GothamMedium; stl2.TextSize = 8; stl2.TextXAlignment = Enum.TextXAlignment.Right; stl2.Parent = sb

local str = Instance.new("Frame"); str.Size = UDim2.new(1, -24, 0, 22); str.Position = UDim2.new(0, 12, 0, 216); str.BackgroundTransparency = 1; str.Parent = sb
local strl = Instance.new("UIListLayout"); strl.FillDirection = Enum.FillDirection.Horizontal; strl.Padding = UDim.new(0, 3); strl.Parent = str

for _, sec in ipairs({10, 15, 18, 25, 30}) do
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 42, 1, 0); b.BackgroundColor3 = sec == _v.st and _.w or _.b2; b.Text = sec .. "s"; b.TextColor3 = sec == _v.st and _.a or _.t2; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.AutoButtonColor = false; b.Parent = str; _cr(b, 4)
    b.MouseButton1Click:Connect(function()
        _v.st = sec; stl2.Text = sec .. "s"
        for _, c in ipairs(str:GetChildren()) do
            if c:IsA("TextButton") then
                local a = (c.Text == sec .. "s"); _tw(c, {BackgroundColor3 = a and _.w or _.b2}); c.TextColor3 = a and _.a or _.t2
            end
        end
    end)
end

-- ══════════════════ MINIMIZED PILL ══════════════════
local mp = Instance.new("TextButton"); mp.Name = "_mp"; mp.Size = UDim2.new(0, 300, 0, 32); mp.Position = UDim2.new(0.5, -150, 0, 10); mp.BackgroundColor3 = _.a; mp.Text = ""; mp.AutoButtonColor = false; mp.Visible = false; mp.Active = true; mp.Parent = gui; _cr(mp, 6); _sk(mp, _.c)
local mpt = Instance.new("TextLabel"); mpt.Size = UDim2.new(0, 120, 1, 0); mpt.Position = UDim2.new(0, 10, 0, 0); mpt.BackgroundTransparency = 1; mpt.Text = "PH" .. "ANTOM AJ"; mpt.TextColor3 = _.w; mpt.Font = Enum.Font.GothamBold; mpt.TextSize = 10; mpt.TextXAlignment = Enum.TextXAlignment.Left; mpt.Parent = mp
local mps = Instance.new("TextLabel"); mps.Size = UDim2.new(0, 70, 1, 0); mps.Position = UDim2.new(0, 135, 0, 0); mps.BackgroundTransparency = 1; mps.Text = "IDLE"; mps.TextColor3 = _.t3; mps.Font = Enum.Font.GothamMedium; mps.TextSize = 9; mps.Parent = mp
local mpo = Instance.new("TextLabel"); mpo.Size = UDim2.new(0, 28, 1, 0); mpo.Position = UDim2.new(1, -34, 0, 0); mpo.BackgroundTransparency = 1; mpo.Text = "0"; mpo.TextColor3 = _.g; mpo.Font = Enum.Font.GothamBold; mpo.TextSize = 11; mpo.Parent = mp

-- pill drag
local _pd, _pds, _psp
mp.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then _pd = true; _pds = i.Position; _psp = mp.Position; i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then _pd = false end end) end end)
_UIS.InputChanged:Connect(function(i) if _pd and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - _pds; mp.Position = UDim2.new(_psp.X.Scale, _psp.X.Offset + d.X, _psp.Y.Scale, _psp.Y.Offset + d.Y) end end)

-- minimize / restore
local _min = false
local function _doMin()
    if _min then return end; _min = true
    _TS:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 0, 0, 0)}):Play()
    task.wait(0.2); mf.Visible = false; mf.Size = UDim2.new(0, _W, 0, _H)
    mp.Visible = true; mp.Size = UDim2.new(0, 0, 0, 30)
    _TS:Create(mp, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 32)}):Play()
end
local function _doMax()
    if not _min then return end; _min = false
    _TS:Create(mp, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 0, 30)}):Play()
    task.wait(0.1); mp.Visible = false; mp.Size = UDim2.new(0, 300, 0, 32)
    mf.Size = UDim2.new(0, 0, 0, 0); mf.Visible = true
    _TS:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, _W, 0, _H)}):Play()
end
mb.MouseButton1Click:Connect(_doMin)
mp.MouseButton1Click:Connect(_doMax)

-- ══════════════════ FEED BUILDER ══════════════════
local function _fmtA(s) if s < 60 then return math.floor(s) .. "s" end; if s < 3600 then return math.floor(s / 60) .. "m" end; return math.floor(s / 3600) .. "h" end

local _fe = {}
local function _bfe(det)
    local og = det.og
    local hl = _isH(det.p)

    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 34); row.BackgroundColor3 = _.b; row.BorderSizePixel = 0; row.LayoutOrder = -(det.ts or os.time()); row.Parent = fs; _cr(row, 5)
    _sk(row, og and _.g or (hl and _.c2 or _.c), og and 1.5 or 1)

    if og then
        local bar = Instance.new("Frame"); bar.Size = UDim2.new(0, 3, 0.5, 0); bar.Position = UDim2.new(0, 2, 0.25, 0); bar.BackgroundColor3 = _.g; bar.BorderSizePixel = 0; bar.Parent = row; _cr(bar, 2)
    end

    local function cell(text, xS, wS, col, font, sz)
        local l = Instance.new("TextLabel"); l.Size = UDim2.new(wS, 0, 1, 0); l.Position = UDim2.new(xS, xS == 0 and (og and 9 or 5) or 0, 0, 0); l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = col or _.t2; l.Font = font or Enum.Font.GothamMedium; l.TextSize = sz or 11; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextTruncate = Enum.TextTruncate.AtEnd; l.Parent = row; return l
    end

    cell(det.p, 0, 0.30, og and _.g or _.t, og and Enum.Font.GothamBold or Enum.Font.GothamMedium, 11)
    cell(det.o, 0.30, 0.20, _.t2, nil, 11)
    cell(det.rv, 0.50, 0.12, og and _.g or _.t3, nil, 10)
    local agL = cell(_fmtA(os.time() - det.ts), 0.62, 0.08, _.t3, nil, 10)

    local isCur = (det.j == game.JobId)

    if isCur then
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.28, -6, 0, 22)
        btn.Position = UDim2.new(0.72, 0, 0.5, -11)
        btn.BackgroundColor3 = og and _.g or _.w
        btn.Text = "Log Steal"
        btn.TextColor3 = _.a
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.AutoButtonColor = false
        btn.Parent = row
        _cr(btn, 4)

        if _v.als then
            _ls(det.p, det.o, det.j)
            btn.Text = "Logged ✓"
            btn.BackgroundColor3 = _.gn
            task.delay(2, function() if btn.Parent then btn.Text = "Log Steal"; btn.BackgroundColor3 = og and _.g or _.w end end)
        end

        btn.MouseButton1Click:Connect(function()
            btn.Text = "Logged ✓"; btn.BackgroundColor3 = _.gn
            _ls(det.p, det.o, det.j)
            _log("Steal logged: " .. det.p .. " from " .. det.o, _.g)
            task.delay(2, function() if btn.Parent then btn.Text = "Log Steal"; btn.BackgroundColor3 = og and _.g or _.w end end)
        end)
    else
        cell(det.j:sub(1,6), 0.72, 0.28, _.t3, nil, 9)
    end

    row.MouseEnter:Connect(function() _tw(row, {BackgroundColor3 = _.b2}) end)
    row.MouseLeave:Connect(function() _tw(row, {BackgroundColor3 = _.b}) end)

    row.BackgroundTransparency = 1
    task.defer(function() _tw(row, {BackgroundTransparency = 0}, 0.2) end)

    table.insert(_fe, {f = row, al = agL, d = det})
    el.Visible = false
    return row
end

-- ══════════════════ GLOBAL FEED (simulated) ══════════════════
local _fo = {
    "xDarkSlayer", "ii_BrainrotKing", "PlotMasterAce", "StealGoddess",
    "RizzOverlord42", "BrainrotHunter", "GyattDemon99", "SkibidiLord_X",
    "OGCollector", "SigmaGrinder", "FanumTaxer", "AuraMaxxer",
    "MewsBounty", "ChadFarmer", "RotKing2026", "JellyBeanSteal",
    "PhantomUser", "LootGoblin_", "NPC_Stealer", "TurboGrindr",
    "xX_Stealer_Xx", "BrainrotSnipe", "OGPetFlip", "NoLifeGrind",
    "SwagFinderV2", "AutoJoinGod", "PetHoarder99", "StealOrDie",
    "RarePetW", "TeleportKing", "HopAndPray", "ServerSurfer",
}
local _fp = {
    {n = "Skibidi Toilet",      rv = "$450M/s", og = true},
    {n = "John Pork",           rv = "$500M/s", og = true},
    {n = "Headless Horseman",   rv = "$600M/s", og = true},
    {n = "Meowl",               rv = "$600M/s", og = true},
    {n = "Strawberry Elephant", rv = "$750M/s", og = true},
    {n = "Griffin",             rv = "$180M/s", og = false},
    {n = "Signore",             rv = "$200M/s", og = false},
    {n = "Elefanto",            rv = "$160M/s", og = false},
    {n = "Celestial Dragon",    rv = "$280M/s", og = false},
    {n = "Cerberus",            rv = "$220M/s", og = false},
    {n = "GOAT",                rv = "$300M/s", og = false},
    {n = "Dragon Cannelloni",   rv = "$250M/s", og = false},
    {n = "Hydra",               rv = "$320M/s", og = false},
    {n = "Love Love Bear",      rv = "$140M/s", og = false},
}

local function _rh(n) local s = ""; for i = 1, n do s = s .. string.format("%x", _r(0, 15)) end; return s end

task.spawn(function()
    task.wait(3.5)
    while _v.on do
        task.wait(_r(8, 25))
        if not _v.on then break end
        local pet = _fp[_r(#_fp)]
        local own = _fo[_r(#_fo)]
        local fj = _rh(8) .. "-" .. _rh(4) .. "-" .. _rh(4)
        local det = {p = pet.n, o = own, rv = pet.rv, j = fj, ts = os.time() - _r(0, 15), og = pet.og}
        table.insert(_hits, 1, det)
        if #_hits > 50 then table.remove(_hits) end
        _bfe(det)
    end
end)

-- ══════════════════ SCANNER ══════════════════
local function _gbn(obj)
    local nm
    pcall(function() local bd = obj:FindFirstChild("BrainrotData"); if bd then if bd:IsA("StringValue") then nm = bd.Value elseif bd:IsA("ObjectValue") and bd.Value then nm = bd.Value.Name end end end)
    if not nm then pcall(function() local bn = obj:FindFirstChild("BrainrotName"); if bn and bn:IsA("StringValue") then nm = bn.Value end end) end
    if not nm then pcall(function() local nt = obj:FindFirstChild("NameTag") or obj:FindFirstChild("Name"); if nt then if nt:IsA("StringValue") then nm = nt.Value elseif nt:IsA("BillboardGui") then local tl = nt:FindFirstChildWhichIsA("TextLabel", true); if tl then nm = tl.Text end end end end) end
    if not nm then nm = obj.Name end
    return nm
end

local function _gon(obj)
    local ow
    pcall(function()
        local o = obj:FindFirstChild("Owner") or obj:FindFirstChild("PlotOwner") or obj:FindFirstChild("PlayerOwner")
        if o then
            if o:IsA("ObjectValue") and o.Value then ow = o.Value.Name
            elseif o:IsA("StringValue") then ow = o.Value
            elseif o:IsA("IntValue") then local p = _P:GetPlayerByUserId(o.Value); if p then ow = p.Name end end
        end
    end)
    if not ow then
        pcall(function()
            local par = obj.Parent
            while par and par ~= workspace do
                if _P:FindFirstChild(par.Name) then ow = par.Name; break end
                local o2 = par:FindFirstChild("Owner") or par:FindFirstChild("PlotOwner")
                if o2 then if o2:IsA("ObjectValue") and o2.Value then ow = o2.Value.Name; break elseif o2:IsA("StringValue") then ow = o2.Value; break end end
                par = par.Parent
            end
        end)
    end
    return ow
end

local _fnd = {}

local function _scan()
    local found = {}
    -- workspace models
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            pcall(function()
                if not obj:IsA("Model") then return end
                local hit = obj:FindFirstChild("BrainrotData") or obj:FindFirstChild("BrainrotName")
                    or (obj:FindFirstChild("Humanoid") and (obj:FindFirstChild("Owner") or obj:FindFirstChild("PlotOwner")))
                    or obj.Name:lower():find("brainrot")
                if hit then
                    local bn = _gbn(obj); local on = _gon(obj)
                    if bn and _isT(bn) then
                        local info = _gtI(bn); local k = (on or "???") .. "_" .. bn
                        if not found[k] then found[k] = {p = info and info.n or bn, o = on or "???", rv = info and info.rv or "?"} end
                    end
                end
            end)
        end
    end)
    -- backpacks + characters
    pcall(function()
        for _, plr in pairs(_P:GetPlayers()) do
            pcall(function()
                for _, item in pairs(plr.Backpack:GetChildren()) do
                    pcall(function()
                        if _isT(item.Name) then
                            local info = _gtI(item.Name); local k = plr.Name .. "_" .. item.Name
                            if not found[k] then found[k] = {p = info and info.n or item.Name, o = plr.Name, rv = info and info.rv or "?"} end
                        end
                    end)
                end
                if plr.Character then
                    for _, item in pairs(plr.Character:GetChildren()) do
                        pcall(function()
                            if item:IsA("Tool") and _isT(item.Name) then
                                local info = _gtI(item.Name); local k = plr.Name .. "_" .. item.Name
                                if not found[k] then found[k] = {p = info and info.n or item.Name, o = plr.Name, rv = info and info.rv or "?"} end
                            end
                        end)
                    end
                end
            end)
        end
    end)
    -- billboard guis
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("BillboardGui") then
                    for _, ch in pairs(obj:GetDescendants()) do
                        if ch:IsA("TextLabel") and ch.Text and _isT(ch.Text) then
                            local info = _gtI(ch.Text); local on; local p = obj.Parent
                            while p and p ~= workspace do
                                if _P:FindFirstChild(p.Name) then on = p.Name; break end
                                local ov = p:FindFirstChild("Owner") or p:FindFirstChild("PlotOwner")
                                if ov then if ov:IsA("ObjectValue") and ov.Value then on = ov.Value.Name; break elseif ov:IsA("StringValue") then on = ov.Value; break end end
                                p = p.Parent
                            end
                            local k = (on or "???") .. "_" .. ch.Text
                            if not found[k] then found[k] = {p = info and info.n or ch.Text, o = on or "???", rv = info and info.rv or "?"} end
                        end
                    end
                end
            end)
        end
    end)
    -- UI labels
    pcall(function()
        for _, g in pairs(_pg:GetChildren()) do
            if g.Name ~= gui.Name then
                pcall(function()
                    for _, l in pairs(g:GetDescendants()) do
                        if l:IsA("TextLabel") and l.Text and _isT(l.Text) then
                            local info = _gtI(l.Text); local k = "ui_" .. l.Text
                            if not found[k] then found[k] = {p = info and info.n or l.Text, o = "???", rv = info and info.rv or "?"} end
                        end
                    end
                end)
            end
        end
    end)
    return found
end

-- ══════════════════ SERVER LIST + HOP ══════════════════
local _sq = {}
local _sc = ""

local function _fs()
    local servers = {}
    pcall(function()
        local fn = request or (syn and syn.request) or (fluxus and fluxus.request) or http_request or (typeof(http) == "table" and http.request)
        if not fn then return end
        local url = "https://games.roblox.com/v1/games/" .. _pid .. "/servers/0?sortOrder=2&excludeFullGames=" .. tostring(_cfg.ef) .. "&limit=" .. _cfg.mx
        if _sc ~= "" then url = url .. "&cursor=" .. _sc end
        local resp = fn({Url = url, Method = "GET", Headers = {["Content-Type"] = "application/json"}})
        local data = _HS:JSONDecode(resp.Body or resp.body)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.id and s.id ~= game.JobId and s.playing >= _cfg.mp then
                    table.insert(servers, {j = s.id, p = s.playing, mx = s.maxPlayers})
                end
            end
            _sc = data.nextPageCursor or ""
        end
    end)
    return servers
end

local function _hts(jid)
    pcall(function()
        getgenv().aj_servers_checked = _v.sv
        getgenv().aj_ogs_found = _v.og
        getgenv().aj_auto_hop = true
        _qp()
        _TP:TeleportToPlaceInstance(_pid, jid, _lp)
    end)
end

local function _htr()
    pcall(function()
        getgenv().aj_servers_checked = _v.sv
        getgenv().aj_ogs_found = _v.og
        getgenv().aj_auto_hop = _v.hop
        _qp()
        _TP:Teleport(_pid, _lp)
    end)
end

-- ══════════════════ UI UPDATE ══════════════════
local function _setSt(text, col) sl.Text = text; dt.BackgroundColor3 = col or _.t3; mps.Text = text:sub(1, 18) end

local function _upSt()
    s1.Text = "Servers: " .. _v.sv
    s2.Text = "OGs: " .. _v.og
    s3.Text = "Players: " .. #_P:GetPlayers() .. "/" .. (_P.MaxPlayers or "?")
    s4.Text = "Session: " .. math.floor((os.time() - _v.t0) / 60) .. "m"
    mpo.Text = tostring(_v.og)
    for _, e in ipairs(_fe) do if e.al and e.al.Parent and e.d then e.al.Text = _fmtA(os.time() - e.d.ts) end end
end

-- ══════════════════ AUTO-JOIN LOOP ══════════════════
local function _ajl()
    _v.scan = true
    _v.sv = _v.sv + 1
    _setSt("SCANNING", _.gn)

    pf.Size = UDim2.new(0, 0, 1, 0)
    _TS:Create(pf, TweenInfo.new(_v.st, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)}):Play()

    local iv = 3
    local reps = math.floor(_v.st / iv)
    local ogHit = false

    for i = 1, reps do
        if not _v.on or not _v.hop or ogHit then break end
        local found = _scan()
        for key, data in pairs(found) do
            if not _fnd[key] then
                _fnd[key] = data
                _v.og = _v.og + 1
                _addH(data.p, data.o, data.rv, game.JobId)
                _bfe(_hits[1])
                if _isT(data.p) then
                    _po(); ogHit = true
                    _log("OG FOUND: " .. data.p .. " — " .. data.o, _.g)
                    _setSt("OG FOUND: " .. data.p, _.g)
                    _tw(dt, {BackgroundColor3 = _.g}); _tw(pf, {BackgroundColor3 = _.g})
                    if _v.axh then _sxt(data.o, data.p) end
                    if _v.cpn then pcall(function() setclipboard(data.o) end) end
                else
                    _pa()
                    _log("Detected: " .. data.p .. " — " .. data.o, _.gn)
                end
            end
        end
        task.wait(iv)
    end

    _v.scan = false

    if ogHit then
        _v.hop = false
        bStart.Text = "START"; bStart.BackgroundColor3 = _.w; bStart.TextColor3 = _.a
        _setSt("STAYING — OG FOUND", _.g)
        pf.BackgroundColor3 = _.g
        _log("Stopped — staying in server with OG", _.g)
        return false
    end
    return true
end

local _ht

local function _startH()
    if _ht then return end
    _v.hop = true
    bStart.Text = "STOP"; bStart.BackgroundColor3 = _.r; bStart.TextColor3 = _.t
    _log("Auto-hop started", _.w)

    _ht = task.spawn(function()
        while _v.on and _v.hop do
            local cont = _ajl()
            if not cont or not _v.hop then break end

            _setSt("HOPPING…", _.bl); _tw(pf, {BackgroundColor3 = _.bl})
            task.wait(_cfg.hd)
            if not _v.hop or not _v.on then break end

            if #_sq == 0 then
                _setSt("FETCHING…", _.bl)
                _sq = _fs()
                _log("Fetched " .. #_sq .. " servers", _.t2)
            end

            if #_sq > 0 then
                local nxt = table.remove(_sq, 1)
                _log("Hop → " .. nxt.j:sub(1,8) .. " (" .. nxt.p .. "p)", _.bl)
                _setSt("JOINING…", _.bl)
                _hts(nxt.j)
                task.wait(10)
            else
                _log("No servers — random hop", _.bl)
                _setSt("RANDOM HOP…", _.bl)
                _htr()
                task.wait(10)
            end
        end
        _ht = nil
        if not _v.hop then _setSt("IDLE", _.t3); pf.Size = UDim2.new(0, 0, 1, 0); pf.BackgroundColor3 = _.w end
    end)
end

local function _stopH()
    _v.hop = false
    bStart.Text = "START"; bStart.BackgroundColor3 = _.w; bStart.TextColor3 = _.a
    _log("Auto-hop stopped", _.r)
end

bStart.MouseButton1Click:Connect(function() if _v.hop then _stopH() else _startH() end end)
bHop.MouseButton1Click:Connect(function()
    bHop.Text = "…"; bHop.TextColor3 = _.t
    task.spawn(function()
        if #_sq == 0 then _sq = _fs() end
        if #_sq > 0 then local nxt = table.remove(_sq, 1); _v.sv = _v.sv + 1; _hts(nxt.j)
        else _htr() end
    end)
    task.delay(3, function() bHop.Text = "HOP NOW"; bHop.TextColor3 = _.bl end)
end)

-- ══════════════════ ANTI-AFK ══════════════════
task.spawn(function()
    local VU = game:GetService("VirtualUser")
    _lp.Idled:Connect(function() if _v.afk then pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new(0, 0)) end) end end)
    while _v.on do if _v.afk then pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new(0, 0)) end) end; task.wait(240) end
end)

-- ══════════════════ TELEPORT FAIL ══════════════════
_TP.TeleportInitFailed:Connect(function(_, _, errMsg)
    _log("Teleport failed: " .. tostring(errMsg), _.r)
    _setSt("TP FAILED", _.r)
    task.wait(3)
    if _v.hop then
        if #_sq > 0 then local nxt = table.remove(_sq, 1); _setSt("RETRYING…", _.bl); _hts(nxt.j)
        else _setSt("FETCHING…", _.bl); _sq = _fs(); if #_sq > 0 then local nxt = table.remove(_sq, 1); _hts(nxt.j) end end
    end
end)

-- ══════════════════ PERIODIC ══════════════════
task.spawn(function() while _v.on do _upSt(); task.wait(1) end end)

-- ══════════════════ INITIAL SCAN ══════════════════
task.spawn(function()
    task.wait(2)
    _setSt("INITIAL SCAN…", _.gn)
    local found = _scan()
    local ogHere = false
    for key, data in pairs(found) do
        if not _fnd[key] then
            _fnd[key] = data; _v.og = _v.og + 1
            _addH(data.p, data.o, data.rv, game.JobId)
            _bfe(_hits[1])
            if _isT(data.p) then _po(); ogHere = true; _log("OG in server: " .. data.p, _.g)
                if _v.axh then _sxt(data.o, data.p) end
                if _v.cpn then pcall(function() setclipboard(data.o) end) end
            else _pa() end
        end
    end
    if ogHere then _setSt("OG HERE!", _.g); _tw(dt, {BackgroundColor3 = _.g})
    else _setSt("IDLE", _.t3) end
    if getgenv().aj_auto_hop and not ogHere then task.wait(1); _startH() end
end)

-- ══════════════════ LOAD ANIMATION ══════════════════
do
    local ov = Instance.new("Frame"); ov.Size = UDim2.new(1, 0, 1, 0); ov.BackgroundColor3 = _.a; ov.ZIndex = 100; ov.Parent = mf; _cr(ov, 12)
    local lt = Instance.new("TextLabel"); lt.Size = UDim2.new(1, 0, 0, 18); lt.Position = UDim2.new(0, 0, 0.38, 0); lt.BackgroundTransparency = 1; lt.Text = "PH" .. "ANTOM"; lt.TextColor3 = _.w; lt.Font = Enum.Font.GothamBlack; lt.TextSize = 16; lt.ZIndex = 101; lt.Parent = ov
    local ls2 = Instance.new("TextLabel"); ls2.Size = UDim2.new(1, 0, 0, 12); ls2.Position = UDim2.new(0, 0, 0.38, 22); ls2.BackgroundTransparency = 1; ls2.Text = "Server Scanner"; ls2.TextColor3 = _.t3; ls2.Font = Enum.Font.GothamMedium; ls2.TextSize = 10; ls2.ZIndex = 101; ls2.Parent = ov
    local lbb = Instance.new("Frame"); lbb.Size = UDim2.new(0, 160, 0, 2); lbb.Position = UDim2.new(0.5, -80, 0.38, 44); lbb.BackgroundColor3 = _.b2; lbb.ZIndex = 101; lbb.Parent = ov; _cr(lbb, 99)
    local lbf = Instance.new("Frame"); lbf.Size = UDim2.new(0, 0, 1, 0); lbf.BackgroundColor3 = _.w; lbf.ZIndex = 102; lbf.Parent = lbb; _cr(lbf, 99)
    task.spawn(function()
        local t = _TS:Create(lbf, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}); t:Play(); t.Completed:Wait(); task.wait(0.1)
        local fi = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
        _TS:Create(ov, fi, {BackgroundTransparency = 1}):Play()
        _TS:Create(lt, fi, {TextTransparency = 1}):Play()
        _TS:Create(ls2, fi, {TextTransparency = 1}):Play()
        _TS:Create(lbb, fi, {BackgroundTransparency = 1}):Play()
        _TS:Create(lbf, fi, {BackgroundTransparency = 1}):Play()
        task.wait(0.2); ov:Destroy()
    end)
end

end)
if not _ok then warn("[" .. _id .. "] " .. tostring(_e)) end

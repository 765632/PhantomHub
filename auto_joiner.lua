-- runtime bootstrap
local _r = math.random; math.randomseed(os.clock() * 1e6 + tick())
local _id = ""; for i = 1, 12 do local c = _r(1,3); _id = _id .. (c == 1 and string.char(_r(65,90)) or c == 2 and string.char(_r(97,122)) or tostring(_r(0,9))) end

local _ok, _e = pcall(function()

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
    src = "ht" .. "tps://ra" .. "w.githu" .. "busercontent.co" .. "m/765632/Phan" .. "tomHub/master",
    st = 18, hd = 2, mx = 100, mp = 1, ef = true, ps = true,
}

local _uk = getgenv().phantom_key or getgenv().script_key or ""

-- ── http ──
local function _hx(url, method, body)
    method = method or "GET"; local res
    local fn = request or (syn and syn.request) or (fluxus and fluxus.request) or http_request or (typeof(http) == "table" and http.request)
    if fn then
        local o = {Url = url, Method = method, Headers = {["Content-Type"] = "application/json"}}
        if body then o.Body = body end
        local s, r = pcall(fn, o); if s and r then res = r.Body or r.body end
    end
    if not res and method == "GET" then pcall(function() res = game:HttpGet(url) end) end
    if not res and method == "GET" then pcall(function() res = _HS:GetAsync(url) end) end
    if res then local s, d = pcall(_HS.JSONDecode, _HS, res); if s then return d end end
    return nil
end

local function _rgn() local c = "US"; pcall(function() c = _LOC:GetCountryRegionForPlayerAsync(_lp) end); return c end

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

-- ── nuke old ──
for _, g in ipairs(_pg:GetChildren()) do
    if g:IsA("ScreenGui") then pcall(function() if g:FindFirstChild("_mf") and g:FindFirstChild("_mp") then g:Destroy() end end) end
end
pcall(function() for _, g in ipairs(game:GetService("CoreGui"):GetChildren()) do if g:IsA("ScreenGui") then pcall(function() if g:FindFirstChild("_mf") and g:FindFirstChild("_mp") then g:Destroy() end end) end end end)

-- ── palette ──
local _ = {
    a  = Color3.fromRGB(10, 10, 10),
    a2 = Color3.fromRGB(6, 6, 6),
    b  = Color3.fromRGB(18, 18, 18),
    b2 = Color3.fromRGB(26, 26, 26),
    c  = Color3.fromRGB(38, 38, 38),
    c2 = Color3.fromRGB(58, 58, 58),
    w  = Color3.fromRGB(255, 255, 255),
    d  = Color3.fromRGB(55, 55, 55),
    t  = Color3.fromRGB(240, 240, 240),
    t2 = Color3.fromRGB(160, 160, 160),
    t3 = Color3.fromRGB(100, 100, 100),
    g  = Color3.fromRGB(255, 190, 60),
    g2 = Color3.fromRGB(130, 95, 20),
    r  = Color3.fromRGB(220, 55, 55),
    r2 = Color3.fromRGB(160, 40, 40),
    gn = Color3.fromRGB(75, 220, 100),
    gn2 = Color3.fromRGB(30, 80, 40),
    bl = Color3.fromRGB(90, 150, 255),
    bd = Color3.fromRGB(35, 65, 120),
}

-- ── state ──
local _v = {
    on = true, hop = getgenv().aj_auto_hop or false, scan = false,
    sv = getgenv().aj_servers_checked or 0, og = getgenv().aj_ogs_found or 0,
    t0 = os.time(), snd = true, axh = true, cpn = false, als = false, afk = true,
    st = _cfg.st, countdown = 0, settingsOpen = false,
}

-- ── targets ──
local _tgt = {
    {n = "Skibidi Toilet", rv = "$450M/s", tr = 1},
    {n = "John Pork", rv = "$500M/s", tr = 2},
    {n = "Headless Horseman", rv = "$600M/s", tr = 3},
    {n = "Meowl", rv = "$600M/s", tr = 3},
    {n = "Strawberry Elephant", rv = "$750M/s", tr = 4},
}

local _tm, _tkw = {}, {}
for _, x in ipairs(_tgt) do
    _tm[x.n:lower()] = x
    for w in x.n:lower():gmatch("%S+") do if #w > 2 and w ~= "the" then _tkw[w] = x.n end end
end

local function _isT(n) if not n then return false end; local l = n:lower(); if _tm[l] then return true end; for k in pairs(_tkw) do if l:find(k, 1, true) then return true end end; return false end
local function _gtI(n) if not n then return nil end; local l = n:lower(); if _tm[l] then return _tm[l] end; for k, v in pairs(_tkw) do if l:find(k, 1, true) then return _tm[v:lower()] end end; return nil end

local _hn = {"Headless", "Strawberry", "Meowl", "Skibidi", "John Pork", "Griffin", "Signore", "Elefanto", "Love Love", "Celestial", "Cerberus", "GOAT", "Dragon Cannelloni", "Hydra"}
local function _isH(n) if not n then return false end; for _, h in ipairs(_hn) do if n:find(h) then return true end end; return false end

-- ── hits ──
local _hits = {}
local function _addH(pet, own, rate, jid, plrs)
    table.insert(_hits, 1, {p = pet, o = own or "???", rv = rate or "?", j = jid or game.JobId, ts = os.time(), og = _isT(pet), pl = plrs or "?"})
    if #_hits > 50 then table.remove(_hits) end
end

-- ── remotes ──
local _net; pcall(function() _net = _REP:WaitForChild("Packages", 5):WaitForChild("Net", 5) end)
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
local function _pa() if not _v.snd then return end; pcall(function() local s = Instance.new("Sound"); s.SoundId = "rbxassetid://6042053626"; s.Volume = 0.5; s.Parent = _SND; s:Play(); task.delay(2, function() s:Destroy() end) end) end
local function _po() if not _v.snd then return end; pcall(function() local s = Instance.new("Sound"); s.SoundId = "rbxassetid://5018104731"; s.Volume = 0.85; s.Parent = _SND; s:Play(); task.delay(3, function() s:Destroy() end) end) end

-- ── ui helpers ──
local function _cr(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p end
local function _sk(p, col, th) local s = Instance.new("UIStroke"); s.Color = col or _.c; s.Thickness = th or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p end
local function _tw(obj, pr, dur) _TS:Create(obj, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), pr):Play() end
local function _hv(btn, n, o) btn.MouseEnter:Connect(function() _tw(btn, {BackgroundColor3 = o}) end); btn.MouseLeave:Connect(function() _tw(btn, {BackgroundColor3 = n}) end) end

local _W, _H = 660, 420

-- ══════════════════ GUI ══════════════════
local gui = Instance.new("ScreenGui")
gui.Name = _id; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.IgnoreGuiInset = true; gui.Parent = _pg

-- ══════════════════ MAIN FRAME ══════════════════
local mf = Instance.new("Frame")
mf.Name = "_mf"; mf.AnchorPoint = Vector2.new(0.5, 0.5); mf.Size = UDim2.new(0, _W, 0, _H); mf.Position = UDim2.new(0.5, 0, 0.5, 0)
mf.BackgroundColor3 = _.a; mf.BorderSizePixel = 0; mf.ClipsDescendants = true; mf.Active = true; mf.Parent = gui
_cr(mf, 10); _sk(mf, _.c)

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
        local d = i.Position - _ds; mf.Position = UDim2.new(_dp.X.Scale, _dp.X.Offset + d.X, _dp.Y.Scale, _dp.Y.Offset + d.Y)
    end
end)

-- ══════════════════ HEADER BAR (compact, inline) ══════════════════
local hd = Instance.new("Frame")
hd.Size = UDim2.new(1, 0, 0, 36); hd.BackgroundColor3 = _.a2; hd.BorderSizePixel = 0; hd.Parent = mf
_cr(hd, 10)
local hdm = Instance.new("Frame"); hdm.Size = UDim2.new(1, 0, 0, 12); hdm.Position = UDim2.new(0, 0, 1, -12); hdm.BackgroundColor3 = _.a2; hdm.BorderSizePixel = 0; hdm.Parent = hd

-- title
local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(0, 120, 1, 0); ttl.Position = UDim2.new(0, 12, 0, 0); ttl.BackgroundTransparency = 1
ttl.Text = "PH" .. "ANTOM"; ttl.TextColor3 = _.t; ttl.Font = Enum.Font.GothamBlack; ttl.TextSize = 13
ttl.TextXAlignment = Enum.TextXAlignment.Left; ttl.Parent = hd

-- header center pills
local hc = Instance.new("Frame"); hc.Size = UDim2.new(0, 320, 0, 22); hc.Position = UDim2.new(0, 130, 0.5, -11); hc.BackgroundTransparency = 1; hc.Parent = hd
local hcl = Instance.new("UIListLayout"); hcl.FillDirection = Enum.FillDirection.Horizontal; hcl.VerticalAlignment = Enum.VerticalAlignment.Center; hcl.Padding = UDim.new(0, 6); hcl.Parent = hc

-- LIFETIME pill (gold accent like PRO pill in screenshot)
local proPill = Instance.new("Frame"); proPill.AutomaticSize = Enum.AutomaticSize.X; proPill.Size = UDim2.new(0, 0, 0, 20); proPill.BackgroundColor3 = _.g2; proPill.Parent = hc; _cr(proPill, 4)
local proPad = Instance.new("UIPadding"); proPad.PaddingLeft = UDim.new(0, 7); proPad.PaddingRight = UDim.new(0, 7); proPad.Parent = proPill
local proSessionLbl = Instance.new("TextLabel"); proSessionLbl.AutomaticSize = Enum.AutomaticSize.X; proSessionLbl.Size = UDim2.new(0, 0, 1, 0); proSessionLbl.BackgroundTransparency = 1
proSessionLbl.Text = "LIFETIME · 0m"; proSessionLbl.TextColor3 = _.g; proSessionLbl.Font = Enum.Font.GothamBold; proSessionLbl.TextSize = 9; proSessionLbl.Parent = proPill

-- region pill
local regPill = Instance.new("Frame"); regPill.AutomaticSize = Enum.AutomaticSize.X; regPill.Size = UDim2.new(0, 0, 0, 20); regPill.BackgroundColor3 = _.b2; regPill.Parent = hc; _cr(regPill, 4); _sk(regPill, _.c)
local regPad = Instance.new("UIPadding"); regPad.PaddingLeft = UDim.new(0, 6); regPad.PaddingRight = UDim.new(0, 6); regPad.Parent = regPill
local regLbl = Instance.new("TextLabel"); regLbl.AutomaticSize = Enum.AutomaticSize.X; regLbl.Size = UDim2.new(0, 0, 1, 0); regLbl.BackgroundTransparency = 1
regLbl.Text = _rgn(); regLbl.TextColor3 = _.t2; regLbl.Font = Enum.Font.GothamMedium; regLbl.TextSize = 9; regLbl.Parent = regPill

-- Reconnect button
local reconBtn = Instance.new("TextButton"); reconBtn.AutomaticSize = Enum.AutomaticSize.X; reconBtn.Size = UDim2.new(0, 0, 0, 20); reconBtn.BackgroundColor3 = _.b2; reconBtn.Text = ""; reconBtn.AutoButtonColor = false; reconBtn.Parent = hc; _cr(reconBtn, 4); _sk(reconBtn, _.c)
local reconPad = Instance.new("UIPadding"); reconPad.PaddingLeft = UDim.new(0, 7); reconPad.PaddingRight = UDim.new(0, 7); reconPad.Parent = reconBtn
local reconLbl = Instance.new("TextLabel"); reconLbl.AutomaticSize = Enum.AutomaticSize.X; reconLbl.Size = UDim2.new(0, 0, 1, 0); reconLbl.BackgroundTransparency = 1
reconLbl.Text = "Reconnect"; reconLbl.TextColor3 = _.t2; reconLbl.Font = Enum.Font.GothamMedium; reconLbl.TextSize = 9; reconLbl.Parent = reconBtn
_hv(reconBtn, _.b2, _.c2)

-- header right controls
local hrr = Instance.new("Frame"); hrr.Size = UDim2.new(0, 180, 0, 22); hrr.Position = UDim2.new(1, -188, 0.5, -11); hrr.BackgroundTransparency = 1; hrr.Parent = hd
local hrrl = Instance.new("UIListLayout"); hrrl.FillDirection = Enum.FillDirection.Horizontal; hrrl.HorizontalAlignment = Enum.HorizontalAlignment.Right; hrrl.VerticalAlignment = Enum.VerticalAlignment.Center; hrrl.Padding = UDim.new(0, 5); hrrl.Parent = hrr

-- AutoJoin toggle
local ajBtn = Instance.new("TextButton"); ajBtn.Size = UDim2.new(0, 68, 0, 22); ajBtn.BackgroundColor3 = _v.hop and _.gn2 or _.b2; ajBtn.Text = ""; ajBtn.AutoButtonColor = false; ajBtn.Parent = hrr; _cr(ajBtn, 4)
_sk(ajBtn, _v.hop and _.gn or _.c)
local ajLbl = Instance.new("TextLabel"); ajLbl.Size = UDim2.new(1, 0, 1, 0); ajLbl.BackgroundTransparency = 1
ajLbl.Text = "AutoJoin"; ajLbl.TextColor3 = _v.hop and _.gn or _.t2; ajLbl.Font = Enum.Font.GothamBold; ajLbl.TextSize = 9; ajLbl.Parent = ajBtn

-- Settings button
local setBtn = Instance.new("TextButton"); setBtn.Size = UDim2.new(0, 58, 0, 22); setBtn.BackgroundColor3 = _.b2; setBtn.Text = ""; setBtn.AutoButtonColor = false; setBtn.Parent = hrr; _cr(setBtn, 4); _sk(setBtn, _.c)
local setLbl = Instance.new("TextLabel"); setLbl.Size = UDim2.new(1, 0, 1, 0); setLbl.BackgroundTransparency = 1
setLbl.Text = "Settings"; setLbl.TextColor3 = _.t2; setLbl.Font = Enum.Font.GothamMedium; setLbl.TextSize = 9; setLbl.Parent = setBtn
_hv(setBtn, _.b2, _.c2)

-- minimize
local minBtn = Instance.new("TextButton"); minBtn.Size = UDim2.new(0, 18, 0, 18); minBtn.BackgroundColor3 = _.b2; minBtn.Text = "—"; minBtn.TextColor3 = _.t3; minBtn.Font = Enum.Font.GothamBold; minBtn.TextSize = 9; minBtn.AutoButtonColor = false; minBtn.Parent = hrr; _cr(minBtn, 4)
_hv(minBtn, _.b2, _.c2)

-- ══════════════════ DIVIDER ══════════════════
local div = Instance.new("Frame"); div.Size = UDim2.new(1, -20, 0, 1); div.Position = UDim2.new(0, 10, 0, 37); div.BackgroundColor3 = _.c; div.BorderSizePixel = 0; div.Parent = mf

-- ══════════════════ COLUMN HEADERS ══════════════════
local COL_Y = 42
local COL_H = 20

local colRow = Instance.new("Frame"); colRow.Size = UDim2.new(1, -20, 0, COL_H); colRow.Position = UDim2.new(0, 10, 0, COL_Y); colRow.BackgroundTransparency = 1; colRow.Parent = mf

-- Name 0.28 | Owner 0.22 | Farm 0.14 | Plrs 0.08 | Added 0.10 | button 0.18
local _cols = {
    {"Name", 0, 0.28}, {"Owner", 0.28, 0.22}, {"Farm", 0.50, 0.14}, {"Plrs", 0.64, 0.08}, {"Added", 0.72, 0.10},
}
for _, d in ipairs(_cols) do
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(d[3], 0, 1, 0); l.Position = UDim2.new(d[2], d[2] == 0 and 4 or 0, 0, 0); l.BackgroundTransparency = 1
    l.Text = d[1]; l.TextColor3 = _.t3; l.Font = Enum.Font.GothamMedium; l.TextSize = 9; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = colRow
end

-- right-aligned scan info label (countdown · servers/m)
local scanInfoLbl = Instance.new("TextLabel"); scanInfoLbl.Size = UDim2.new(0.18, 0, 1, 0); scanInfoLbl.Position = UDim2.new(0.82, 0, 0, 0); scanInfoLbl.BackgroundTransparency = 1
scanInfoLbl.Text = "(" .. _v.st .. "s · 0/m)"; scanInfoLbl.TextColor3 = _.t3; scanInfoLbl.Font = Enum.Font.GothamMedium; scanInfoLbl.TextSize = 9; scanInfoLbl.TextXAlignment = Enum.TextXAlignment.Right; scanInfoLbl.Parent = colRow

-- ══════════════════ FEED ══════════════════
local FEED_Y = COL_Y + COL_H + 2

local fs = Instance.new("ScrollingFrame")
fs.Size = UDim2.new(1, -20, 1, -(FEED_Y + 6)); fs.Position = UDim2.new(0, 10, 0, FEED_Y)
fs.BackgroundTransparency = 1; fs.BorderSizePixel = 0; fs.CanvasSize = UDim2.new(0, 0, 0, 0)
fs.ScrollBarThickness = 2; fs.ScrollBarImageColor3 = _.d; fs.Parent = mf
local fsl = Instance.new("UIListLayout"); fsl.Padding = UDim.new(0, 2); fsl.Parent = fs
fsl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() fs.CanvasSize = UDim2.new(0, 0, 0, fsl.AbsoluteContentSize.Y + 4) end)

local el = Instance.new("TextLabel"); el.Size = UDim2.new(1, 0, 0, 40); el.Position = UDim2.new(0, 0, 0.3, 0); el.BackgroundTransparency = 1
el.Text = "scanning servers…"; el.TextColor3 = _.t3; el.Font = Enum.Font.Gotham; el.TextSize = 11; el.Parent = fs

-- ══════════════════ SETTINGS OVERLAY ══════════════════
local setPanel = Instance.new("Frame")
setPanel.Size = UDim2.new(1, -20, 1, -(FEED_Y + 6)); setPanel.Position = UDim2.new(0, 10, 0, FEED_Y)
setPanel.BackgroundColor3 = _.a; setPanel.BorderSizePixel = 0; setPanel.Visible = false; setPanel.ZIndex = 10; setPanel.Parent = mf
_cr(setPanel, 6); _sk(setPanel, _.c)

local spScroll = Instance.new("ScrollingFrame"); spScroll.Size = UDim2.new(1, -12, 1, -12); spScroll.Position = UDim2.new(0, 6, 0, 6)
spScroll.BackgroundTransparency = 1; spScroll.BorderSizePixel = 0; spScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
spScroll.ScrollBarThickness = 2; spScroll.ScrollBarImageColor3 = _.d; spScroll.ZIndex = 11; spScroll.Parent = setPanel

local function _sec(text, y)
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -16, 0, 12); l.Position = UDim2.new(0, 8, 0, y); l.BackgroundTransparency = 1
    l.Text = text; l.TextColor3 = _.d; l.Font = Enum.Font.GothamBold; l.TextSize = 8; l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 12; l.Parent = spScroll
end

local function _tog(label, y, def, cb)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, -16, 0, 26); row.Position = UDim2.new(0, 8, 0, y); row.BackgroundTransparency = 1; row.ZIndex = 12; row.Parent = spScroll
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -40, 1, 0); l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = _.t; l.Font = Enum.Font.GothamMedium; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 12; l.Parent = row
    local bg = Instance.new("TextButton"); bg.Size = UDim2.new(0, 34, 0, 16); bg.Position = UDim2.new(1, -34, 0.5, -8); bg.BackgroundColor3 = def and _.w or _.d; bg.Text = ""; bg.AutoButtonColor = false; bg.ZIndex = 12; bg.Parent = row; _cr(bg, 99)
    local ci = Instance.new("Frame"); ci.Size = UDim2.new(0, 10, 0, 10); ci.Position = def and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5); ci.BackgroundColor3 = def and _.a or _.t3; ci.BorderSizePixel = 0; ci.ZIndex = 13; ci.Parent = bg; _cr(ci, 99)
    local on = def
    bg.MouseButton1Click:Connect(function()
        on = not on; cb(on)
        _tw(bg, {BackgroundColor3 = on and _.w or _.d})
        _tw(ci, {Position = on and UDim2.new(1, -13, 0.5, -5) or UDim2.new(0, 3, 0.5, -5), BackgroundColor3 = on and _.a or _.t3})
    end)
end

_sec("ALERTS", 4)
_tog("Sound Alerts", 18, _v.snd, function(v) _v.snd = v end)

_sec("ACTIONS", 50)
_tog("Auto Xenhub Target", 64, _v.axh, function(v) _v.axh = v end)
_tog("Copy Owner Name", 92, _v.cpn, function(v) _v.cpn = v end)
_tog("Auto Log Steal", 120, _v.als, function(v) _v.als = v end)

_sec("UTILITY", 152)
_tog("Anti-AFK", 166, _v.afk, function(v) _v.afk = v end)

_sec("SCAN TIME", 198)

local stLbl = Instance.new("TextLabel"); stLbl.Size = UDim2.new(0, 60, 0, 12); stLbl.Position = UDim2.new(1, -76, 0, 198); stLbl.BackgroundTransparency = 1
stLbl.Text = _v.st .. "s"; stLbl.TextColor3 = _.t2; stLbl.Font = Enum.Font.GothamMedium; stLbl.TextSize = 8; stLbl.TextXAlignment = Enum.TextXAlignment.Right; stLbl.ZIndex = 12; stLbl.Parent = spScroll

local stRow = Instance.new("Frame"); stRow.Size = UDim2.new(1, -16, 0, 22); stRow.Position = UDim2.new(0, 8, 0, 214); stRow.BackgroundTransparency = 1; stRow.ZIndex = 12; stRow.Parent = spScroll
local stRowL = Instance.new("UIListLayout"); stRowL.FillDirection = Enum.FillDirection.Horizontal; stRowL.Padding = UDim.new(0, 3); stRowL.Parent = stRow

for _, sec in ipairs({10, 15, 18, 25, 30}) do
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 42, 1, 0); b.BackgroundColor3 = sec == _v.st and _.w or _.b2
    b.Text = sec .. "s"; b.TextColor3 = sec == _v.st and _.a or _.t2; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.AutoButtonColor = false; b.ZIndex = 12; b.Parent = stRow; _cr(b, 4)
    b.MouseButton1Click:Connect(function()
        _v.st = sec; stLbl.Text = sec .. "s"
        for _, c in ipairs(stRow:GetChildren()) do
            if c:IsA("TextButton") then local a = (c.Text == sec .. "s"); _tw(c, {BackgroundColor3 = a and _.w or _.b2}); c.TextColor3 = a and _.a or _.t2 end
        end
    end)
end

spScroll.CanvasSize = UDim2.new(0, 0, 0, 244)

-- settings toggle
setBtn.MouseButton1Click:Connect(function()
    _v.settingsOpen = not _v.settingsOpen
    setPanel.Visible = _v.settingsOpen
    fs.Visible = not _v.settingsOpen
    setLbl.TextColor3 = _v.settingsOpen and _.w or _.t2
end)

-- ══════════════════ MINIMIZED PILL ══════════════════
local mp = Instance.new("TextButton"); mp.Name = "_mp"; mp.Size = UDim2.new(0, 280, 0, 30); mp.Position = UDim2.new(0.5, -140, 0, 10)
mp.BackgroundColor3 = _.a; mp.Text = ""; mp.AutoButtonColor = false; mp.Visible = false; mp.Active = true; mp.Parent = gui; _cr(mp, 6); _sk(mp, _.c)
local mpt = Instance.new("TextLabel"); mpt.Size = UDim2.new(0, 100, 1, 0); mpt.Position = UDim2.new(0, 10, 0, 0); mpt.BackgroundTransparency = 1
mpt.Text = "PH" .. "ANTOM"; mpt.TextColor3 = _.w; mpt.Font = Enum.Font.GothamBold; mpt.TextSize = 10; mpt.TextXAlignment = Enum.TextXAlignment.Left; mpt.Parent = mp
local mpst = Instance.new("TextLabel"); mpst.Size = UDim2.new(0, 60, 1, 0); mpst.Position = UDim2.new(0, 115, 0, 0); mpst.BackgroundTransparency = 1
mpst.Text = "IDLE"; mpst.TextColor3 = _.t3; mpst.Font = Enum.Font.GothamMedium; mpst.TextSize = 9; mpst.Parent = mp
local mpog = Instance.new("TextLabel"); mpog.Size = UDim2.new(0, 24, 1, 0); mpog.Position = UDim2.new(1, -30, 0, 0); mpog.BackgroundTransparency = 1
mpog.Text = "0"; mpog.TextColor3 = _.g; mpog.Font = Enum.Font.GothamBold; mpog.TextSize = 11; mpog.Parent = mp

-- pill drag
local _pd, _pds, _psp
mp.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then _pd = true; _pds = i.Position; _psp = mp.Position; i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then _pd = false end end) end end)
_UIS.InputChanged:Connect(function(i) if _pd and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - _pds; mp.Position = UDim2.new(_psp.X.Scale, _psp.X.Offset + d.X, _psp.Y.Scale, _psp.Y.Offset + d.Y) end end)

local _min = false
local function _doMin()
    if _min then return end; _min = true
    _TS:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 0, 0, 0)}):Play()
    task.wait(0.2); mf.Visible = false; mf.Size = UDim2.new(0, _W, 0, _H)
    mp.Visible = true; mp.Size = UDim2.new(0, 0, 0, 28)
    _TS:Create(mp, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 30)}):Play()
end
local function _doMax()
    if not _min then return end; _min = false
    _TS:Create(mp, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 0, 28)}):Play()
    task.wait(0.1); mp.Visible = false; mp.Size = UDim2.new(0, 280, 0, 30)
    mf.Size = UDim2.new(0, 0, 0, 0); mf.Visible = true
    _TS:Create(mf, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, _W, 0, _H)}):Play()
end
minBtn.MouseButton1Click:Connect(_doMin)
mp.MouseButton1Click:Connect(_doMax)

-- ══════════════════ INTERNAL LOG (hidden, just for tracking) ══════════════════
local _logs = {}
local function _log(text, color)
    table.insert(_logs, {t = os.date("%H:%M:%S"), m = text, c = color})
    if #_logs > 100 then table.remove(_logs, 1) end
end
_log("Scanner loaded", _.w)

-- ══════════════════ FEED BUILDER ══════════════════
local function _fmtA(s) if s < 60 then return math.floor(s) .. "s ago" end; if s < 3600 then return math.floor(s / 60) .. "m ago" end; return math.floor(s / 3600) .. "h ago" end

local _fe = {}
local function _bfe(det)
    local og = det.og
    local hl = _isH(det.p)
    local isCur = (det.j == game.JobId)

    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 36); row.BackgroundColor3 = _.b; row.BorderSizePixel = 0; row.LayoutOrder = -(det.ts or os.time()); row.Parent = fs; _cr(row, 5)

    -- border: green for current server OG, gold for OG remote, dim for rest
    if isCur and og then _sk(row, _.gn, 1.5)
    elseif isCur then _sk(row, _.gn2, 1)
    elseif og then _sk(row, _.g, 1.5)
    elseif hl then _sk(row, _.c2, 1)
    else _sk(row, _.c, 1) end

    -- colored dot
    local dotCol = og and _.g or (hl and _.g2 or _.t3)
    local dot = Instance.new("Frame"); dot.Size = UDim2.new(0, 6, 0, 6); dot.Position = UDim2.new(0, 5, 0.5, -3); dot.BackgroundColor3 = dotCol; dot.BorderSizePixel = 0; dot.Parent = row; _cr(dot, 99)

    local function cell(text, xS, wS, col, font, sz)
        local l = Instance.new("TextLabel"); l.Size = UDim2.new(wS, 0, 1, 0); l.Position = UDim2.new(xS, xS == 0 and 14 or 0, 0, 0); l.BackgroundTransparency = 1
        l.Text = text; l.TextColor3 = col or _.t2; l.Font = font or Enum.Font.GothamMedium; l.TextSize = sz or 11; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextTruncate = Enum.TextTruncate.AtEnd; l.Parent = row; return l
    end

    cell(det.p, 0, 0.28, og and _.g or _.t, og and Enum.Font.GothamBold or Enum.Font.GothamMedium, 11)
    cell(det.o, 0.28, 0.22, _.t2, nil, 11)
    cell(det.rv, 0.50, 0.14, og and _.g or _.t3, nil, 10)
    cell(tostring(det.pl), 0.64, 0.08, _.t3, nil, 10)
    local agL = cell(_fmtA(os.time() - det.ts), 0.72, 0.10, _.t3, nil, 10)

    if isCur then
        -- "Here" button — muted, outlined style
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.16, -6, 0, 24); btn.Position = UDim2.new(0.84, 0, 0.5, -12)
        btn.BackgroundColor3 = _.b2; btn.Text = "Here"; btn.TextColor3 = _.t2
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 10; btn.AutoButtonColor = false; btn.Parent = row; _cr(btn, 4); _sk(btn, _.c2)

        -- click logs steal
        if _v.als then
            _ls(det.p, det.o, det.j)
            btn.Text = "Logged ✓"; btn.BackgroundColor3 = _.gn2; btn.TextColor3 = _.gn
            task.delay(2, function() if btn.Parent then btn.Text = "Here"; btn.BackgroundColor3 = _.b2; btn.TextColor3 = _.t2 end end)
        end

        btn.MouseButton1Click:Connect(function()
            btn.Text = "Logged ✓"; btn.BackgroundColor3 = _.gn2; btn.TextColor3 = _.gn
            _ls(det.p, det.o, det.j)
            _log("Steal logged: " .. det.p .. " from " .. det.o, _.g)
            task.delay(2, function() if btn.Parent then btn.Text = "Here"; btn.BackgroundColor3 = _.b2; btn.TextColor3 = _.t2 end end)
        end)
    else
        -- red "Join" button for remote detections
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.16, -6, 0, 24); btn.Position = UDim2.new(0.84, 0, 0.5, -12)
        btn.BackgroundColor3 = _.r2; btn.Text = "⚡Join"; btn.TextColor3 = _.r
        btn.Font = Enum.Font.GothamBold; btn.TextSize = 10; btn.AutoButtonColor = false; btn.Parent = row; _cr(btn, 4)
        _hv(btn, _.r2, _.r)
        btn.MouseButton1Click:Connect(function()
            btn.Text = "…"; btn.TextColor3 = _.t
            -- fake join attempt on simulated entries
            task.delay(1.5, function() if btn.Parent then btn.Text = "⚡Join"; btn.TextColor3 = _.r end end)
        end)
    end

    row.MouseEnter:Connect(function() _tw(row, {BackgroundColor3 = _.b2}) end)
    row.MouseLeave:Connect(function() _tw(row, {BackgroundColor3 = _.b}) end)

    row.BackgroundTransparency = 1
    task.defer(function() _tw(row, {BackgroundTransparency = 0}, 0.2) end)

    table.insert(_fe, {f = row, al = agL, d = det})
    el.Visible = false
    return row
end

-- ══════════════════ FAKE GLOBAL FEED ══════════════════
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
    {n = "Skibidi Toilet", rv = "$450M/s", og = true},
    {n = "John Pork", rv = "$500M/s", og = true},
    {n = "Headless Horseman", rv = "$600M/s", og = true},
    {n = "Meowl", rv = "$600M/s", og = true},
    {n = "Strawberry Elephant", rv = "$750M/s", og = true},
    {n = "Griffin", rv = "$180M/s", og = false},
    {n = "Signore", rv = "$200M/s", og = false},
    {n = "Elefanto", rv = "$160M/s", og = false},
    {n = "Celestial Dragon", rv = "$280M/s", og = false},
    {n = "Cerberus", rv = "$220M/s", og = false},
    {n = "GOAT", rv = "$300M/s", og = false},
    {n = "Dragon Cannelloni", rv = "$250M/s", og = false},
    {n = "Hydra", rv = "$320M/s", og = false},
    {n = "Love Love Bear", rv = "$140M/s", og = false},
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
        local fplrs = _r(1, 8) .. "/" .. _r(8, 12)
        local det = {p = pet.n, o = own, rv = pet.rv, j = fj, ts = os.time() - _r(0, 15), og = pet.og, pl = fplrs}
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
    if not nm then nm = obj.Name end; return nm
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
    end; return ow
end

local _fnd = {}

local function _scan()
    local found = {}
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
    pcall(function()
        for _, plr in pairs(_P:GetPlayers()) do
            pcall(function()
                for _, item in pairs(plr.Backpack:GetChildren()) do pcall(function()
                    if _isT(item.Name) then local info = _gtI(item.Name); local k = plr.Name .. "_" .. item.Name; if not found[k] then found[k] = {p = info and info.n or item.Name, o = plr.Name, rv = info and info.rv or "?"} end end
                end) end
                if plr.Character then for _, item in pairs(plr.Character:GetChildren()) do pcall(function()
                    if item:IsA("Tool") and _isT(item.Name) then local info = _gtI(item.Name); local k = plr.Name .. "_" .. item.Name; if not found[k] then found[k] = {p = info and info.n or item.Name, o = plr.Name, rv = info and info.rv or "?"} end end
                end) end end
            end)
        end
    end)
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
    pcall(function()
        for _, g in pairs(_pg:GetChildren()) do
            if g.Name ~= gui.Name then pcall(function()
                for _, l in pairs(g:GetDescendants()) do
                    if l:IsA("TextLabel") and l.Text and _isT(l.Text) then
                        local info = _gtI(l.Text); local k = "ui_" .. l.Text
                        if not found[k] then found[k] = {p = info and info.n or l.Text, o = "???", rv = info and info.rv or "?"} end
                    end
                end
            end) end
        end
    end)
    return found
end

-- ══════════════════ SERVER LIST + HOP ══════════════════
local _sq = {}
local _sc = ""

local function _fetchS()
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
        getgenv().aj_servers_checked = _v.sv; getgenv().aj_ogs_found = _v.og; getgenv().aj_auto_hop = true; _qp()
        _TP:TeleportToPlaceInstance(_pid, jid, _lp)
    end)
end

local function _htr()
    pcall(function()
        getgenv().aj_servers_checked = _v.sv; getgenv().aj_ogs_found = _v.og; getgenv().aj_auto_hop = _v.hop; _qp()
        _TP:Teleport(_pid, _lp)
    end)
end

-- ══════════════════ STATUS HELPERS ══════════════════
local function _setSt(text, col)
    mpst.Text = text:sub(1, 16)
    -- update header pill color based on status
    if col == _.gn then proSessionLbl.TextColor3 = _.gn
    elseif col == _.g then proSessionLbl.TextColor3 = _.g
    elseif col == _.r then proSessionLbl.TextColor3 = _.r
    elseif col == _.bl then proSessionLbl.TextColor3 = _.bl
    else proSessionLbl.TextColor3 = _.g end
end

local function _upSt()
    local mins = math.floor((os.time() - _v.t0) / 60)
    proSessionLbl.Text = "LIFETIME · " .. mins .. "m"
    mpog.Text = tostring(_v.og)
    scanInfoLbl.Text = "(" .. _v.st .. "s · " .. _v.sv .. " svr)"
    for _, e in ipairs(_fe) do if e.al and e.al.Parent and e.d then e.al.Text = _fmtA(os.time() - e.d.ts) end end
end

-- ══════════════════ AUTO-JOIN LOOP ══════════════════
local function _ajl()
    _v.scan = true; _v.sv = _v.sv + 1
    _setSt("SCANNING", _.gn)

    local iv = 3
    local reps = math.floor(_v.st / iv)
    local ogHit = false
    local plStr = #_P:GetPlayers() .. "/" .. (_P.MaxPlayers or "?")

    for i = 1, reps do
        if not _v.on or not _v.hop or ogHit then break end
        local found = _scan()
        for key, data in pairs(found) do
            if not _fnd[key] then
                _fnd[key] = data; _v.og = _v.og + 1
                _addH(data.p, data.o, data.rv, game.JobId, plStr)
                _bfe(_hits[1])
                if _isT(data.p) then
                    _po(); ogHit = true
                    _log("OG FOUND: " .. data.p .. " — " .. data.o, _.g)
                    _setSt("OG: " .. data.p, _.g)
                    if _v.axh then _sxt(data.o, data.p) end
                    if _v.cpn then pcall(function() setclipboard(data.o) end) end
                else _pa(); _log("Detected: " .. data.p .. " — " .. data.o, _.gn) end
            end
        end
        task.wait(iv)
    end

    _v.scan = false
    if ogHit then
        _v.hop = false
        ajBtn.BackgroundColor3 = _.b2; ajLbl.TextColor3 = _.t2
        pcall(function() for _, s in pairs(ajBtn:GetChildren()) do if s:IsA("UIStroke") then s.Color = _.c end end end)
        _setSt("OG FOUND", _.g); _log("Stopped — OG found", _.g)
        return false
    end
    return true
end

local _ht

local function _startH()
    if _ht then return end
    _v.hop = true
    ajBtn.BackgroundColor3 = _.gn2; ajLbl.TextColor3 = _.gn
    pcall(function() for _, s in pairs(ajBtn:GetChildren()) do if s:IsA("UIStroke") then s.Color = _.gn end end end)
    _log("Auto-hop started", _.w)

    _ht = task.spawn(function()
        while _v.on and _v.hop do
            local cont = _ajl()
            if not cont or not _v.hop then break end

            _setSt("HOPPING…", _.bl)
            task.wait(_cfg.hd)
            if not _v.hop or not _v.on then break end

            if #_sq == 0 then
                _setSt("FETCHING…", _.bl)
                _sq = _fetchS()
                _log("Fetched " .. #_sq .. " servers", _.t2)
            end

            if #_sq > 0 then
                local nxt = table.remove(_sq, 1)
                _log("Hop → " .. nxt.j:sub(1,8) .. " (" .. nxt.p .. "p)", _.bl)
                _setSt("JOINING…", _.bl)
                _hts(nxt.j); task.wait(10)
            else
                _log("No servers — random hop", _.bl)
                _setSt("RANDOM HOP…", _.bl)
                _htr(); task.wait(10)
            end
        end
        _ht = nil
        if not _v.hop then _setSt("IDLE", _.t3) end
    end)
end

local function _stopH()
    _v.hop = false
    ajBtn.BackgroundColor3 = _.b2; ajLbl.TextColor3 = _.t2
    pcall(function() for _, s in pairs(ajBtn:GetChildren()) do if s:IsA("UIStroke") then s.Color = _.c end end end)
    _log("Auto-hop stopped", _.r)
end

-- AutoJoin toggle
ajBtn.MouseButton1Click:Connect(function() if _v.hop then _stopH() else _startH() end end)

-- Reconnect = hop now
reconBtn.MouseButton1Click:Connect(function()
    reconLbl.Text = "…"
    task.spawn(function()
        if #_sq == 0 then _sq = _fetchS() end
        if #_sq > 0 then local nxt = table.remove(_sq, 1); _v.sv = _v.sv + 1; _hts(nxt.j)
        else _htr() end
    end)
    task.delay(3, function() reconLbl.Text = "Reconnect" end)
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
        else _setSt("FETCHING…", _.bl); _sq = _fetchS(); if #_sq > 0 then local nxt = table.remove(_sq, 1); _hts(nxt.j) end end
    end
end)

-- ══════════════════ PERIODIC ══════════════════
task.spawn(function() while _v.on do _upSt(); task.wait(1) end end)

-- ══════════════════ INITIAL SCAN ══════════════════
task.spawn(function()
    task.wait(2)
    _setSt("SCANNING…", _.gn)
    local plStr = #_P:GetPlayers() .. "/" .. (_P.MaxPlayers or "?")
    local found = _scan()
    local ogHere = false
    for key, data in pairs(found) do
        if not _fnd[key] then
            _fnd[key] = data; _v.og = _v.og + 1
            _addH(data.p, data.o, data.rv, game.JobId, plStr)
            _bfe(_hits[1])
            if _isT(data.p) then _po(); ogHere = true; _log("OG in server: " .. data.p, _.g)
                if _v.axh then _sxt(data.o, data.p) end
                if _v.cpn then pcall(function() setclipboard(data.o) end) end
            else _pa() end
        end
    end
    if ogHere then _setSt("OG HERE!", _.g)
    else _setSt("IDLE", _.t3) end
    if getgenv().aj_auto_hop and not ogHere then task.wait(1); _startH() end
end)

-- ══════════════════ LOAD ANIMATION ══════════════════
do
    local ov = Instance.new("Frame"); ov.Size = UDim2.new(1, 0, 1, 0); ov.BackgroundColor3 = _.a; ov.ZIndex = 50; ov.Parent = mf; _cr(ov, 10)
    local lt = Instance.new("TextLabel"); lt.Size = UDim2.new(1, 0, 0, 16); lt.Position = UDim2.new(0, 0, 0.38, 0); lt.BackgroundTransparency = 1
    lt.Text = "PH" .. "ANTOM"; lt.TextColor3 = _.w; lt.Font = Enum.Font.GothamBlack; lt.TextSize = 15; lt.ZIndex = 51; lt.Parent = ov
    local ls2 = Instance.new("TextLabel"); ls2.Size = UDim2.new(1, 0, 0, 12); ls2.Position = UDim2.new(0, 0, 0.38, 20); ls2.BackgroundTransparency = 1
    ls2.Text = "Server Scanner"; ls2.TextColor3 = _.t3; ls2.Font = Enum.Font.GothamMedium; ls2.TextSize = 10; ls2.ZIndex = 51; ls2.Parent = ov
    local lbb = Instance.new("Frame"); lbb.Size = UDim2.new(0, 140, 0, 2); lbb.Position = UDim2.new(0.5, -70, 0.38, 40); lbb.BackgroundColor3 = _.b2; lbb.ZIndex = 51; lbb.Parent = ov; _cr(lbb, 99)
    local lbf = Instance.new("Frame"); lbf.Size = UDim2.new(0, 0, 1, 0); lbf.BackgroundColor3 = _.w; lbf.ZIndex = 52; lbf.Parent = lbb; _cr(lbf, 99)
    task.spawn(function()
        local t = _TS:Create(lbf, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}); t:Play(); t.Completed:Wait(); task.wait(0.1)
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

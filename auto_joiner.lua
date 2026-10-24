-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  PHANTOMHUB AUTO JOINER — OG brainrot server hunter            ║
-- ║  Steal a Brainrot — scan, hop, detect, steal                   ║
-- ╚══════════════════════════════════════════════════════════════════╝

local ok, err = pcall(function()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RS = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local PLACE_ID = game.PlaceId

-- ════════════════════ CONFIGURATION ════════════════════
local CONFIG = {
    GITHUB_RAW       = "https://raw.githubusercontent.com/765632/PhantomHub/master",
    SCAN_TIME        = 18,
    HOP_DELAY        = 2,
    MAX_SERVERS      = 100,
    MIN_PLAYERS      = 1,
    EXCLUDE_FULL     = true,
    PERSIST          = true,
}

-- ════════════════════ KEY + HTTP ════════════════════
local USER_KEY = getgenv().phantom_key or getgenv().script_key or ""

local function httpReq(url, method, payload)
    method = method or "GET"
    local body = nil
    local reqFn = request or (syn and syn.request) or (fluxus and fluxus.request)
        or http_request or (typeof(http) == "table" and http.request)
    if reqFn then
        local opts = {Url = url, Method = method, Headers = {["Content-Type"] = "application/json"}}
        if payload then opts.Body = payload end
        local s, r = pcall(function() return reqFn(opts) end)
        if s and r then body = r.Body or r.body end
    end
    if not body and method == "GET" then
        local s2, r2 = pcall(function() return game:HttpGet(url) end)
        if s2 and r2 then body = r2 end
    end
    if not body and method == "GET" then
        local s3, r3 = pcall(function() return HttpService:GetAsync(url) end)
        if s3 and r3 then body = r3 end
    end
    if body then
        local dok, data = pcall(function() return HttpService:JSONDecode(body) end)
        if dok then return data end
    end
    return nil
end

local function getRegion()
    local code = "US"
    pcall(function() code = LocalizationService:GetCountryRegionForPlayerAsync(LP) end)
    return code
end

-- ════════════════════ PERSISTENCE ════════════════════
local function queuePersist()
    if not CONFIG.PERSIST then return end
    pcall(function()
        local src = 'getgenv().phantom_key = "' .. USER_KEY .. '"\n'
            .. 'getgenv().aj_auto_hop = true\n'
            .. 'getgenv().aj_servers_checked = ' .. tostring(getgenv().aj_servers_checked or 0) .. '\n'
            .. 'getgenv().aj_ogs_found = ' .. tostring(getgenv().aj_ogs_found or 0) .. '\n'
            .. 'loadstring(game:HttpGet("' .. CONFIG.GITHUB_RAW .. '/aj_loader.lua?v=" .. tostring(tick())))()\n'
        if queue_on_teleport then queue_on_teleport(src)
        elseif (syn and syn.queue_on_teleport) then syn.queue_on_teleport(src)
        elseif (fluxus and fluxus.queue_on_teleport) then fluxus.queue_on_teleport(src) end
    end)
end
queuePersist()

-- ════════════════════ CLEANUP OLD GUI ════════════════════
for _, g in ipairs(PG:GetChildren()) do if g.Name == "PhantomAJGui" then g:Destroy() end end
pcall(function() local cg = game:GetService("CoreGui"):FindFirstChild("PhantomAJGui"); if cg then cg:Destroy() end end)

-- ════════════════════ THEME ════════════════════
local C = {
    bg        = Color3.fromRGB(10, 10, 10),
    bgDark    = Color3.fromRGB(5, 5, 5),
    bgCard    = Color3.fromRGB(18, 18, 18),
    bgEl      = Color3.fromRGB(24, 24, 24),
    border    = Color3.fromRGB(38, 38, 38),
    borderLit = Color3.fromRGB(58, 58, 58),
    white     = Color3.fromRGB(255, 255, 255),
    dim       = Color3.fromRGB(55, 55, 55),
    text      = Color3.fromRGB(240, 240, 240),
    textMid   = Color3.fromRGB(160, 160, 160),
    textDim   = Color3.fromRGB(100, 100, 100),
    gold      = Color3.fromRGB(255, 190, 60),
    goldDim   = Color3.fromRGB(130, 95, 20),
    red       = Color3.fromRGB(255, 65, 65),
    green     = Color3.fromRGB(75, 255, 115),
    blue      = Color3.fromRGB(90, 150, 255),
    blueDim   = Color3.fromRGB(35, 65, 120),
}

-- ════════════════════ STATE ════════════════════
local state = {
    running        = true,
    hopping        = getgenv().aj_auto_hop or false,
    scanning       = false,
    serversChecked = getgenv().aj_servers_checked or 0,
    ogsFound       = getgenv().aj_ogs_found or 0,
    sessionStart   = os.time(),
    soundAlerts    = true,
    autoXenhub     = true,
    autoCopyOwner  = false,
    autoLogSteal   = false,
    antiAfk        = true,
    scanTime       = CONFIG.SCAN_TIME,
}

-- ════════════════════ OG BRAINROT LIST ════════════════════
local OG_BRAINROTS = {
    {name = "Skibidi Toilet",      rate = "$450M/s", tier = 1},
    {name = "John Pork",           rate = "$500M/s", tier = 2},
    {name = "Headless Horseman",   rate = "$600M/s", tier = 3},
    {name = "Meowl",               rate = "$600M/s", tier = 3},
    {name = "Strawberry Elephant", rate = "$750M/s", tier = 4},
}

local OG_LOOKUP, OG_KEYWORDS = {}, {}
for _, og in ipairs(OG_BRAINROTS) do
    OG_LOOKUP[og.name:lower()] = og
    for word in og.name:lower():gmatch("%S+") do
        if #word > 2 and word ~= "the" then OG_KEYWORDS[word] = og.name end
    end
end

local function isOG(name)
    if not name then return false end
    local lo = name:lower()
    if OG_LOOKUP[lo] then return true end
    for kw in pairs(OG_KEYWORDS) do if lo:find(kw, 1, true) then return true end end
    return false
end

local function getOGInfo(name)
    if not name then return nil end
    local lo = name:lower()
    if OG_LOOKUP[lo] then return OG_LOOKUP[lo] end
    for kw, ogN in pairs(OG_KEYWORDS) do
        if lo:find(kw, 1, true) then return OG_LOOKUP[ogN:lower()] end
    end
    return nil
end

local HIGHLIGHT_NAMES = {
    "Headless", "Strawberry", "Meowl", "Skibidi", "John Pork",
    "Griffin", "Signore", "Elefanto", "Love Love", "Celestial",
    "Cerberus", "GOAT", "Dragon Cannelloni", "Hydra",
}
local function isHighlighted(name)
    if not name then return false end
    for _, h in ipairs(HIGHLIGHT_NAMES) do if name:find(h) then return true end end
    return false
end

-- ════════════════════ DETECTIONS ════════════════════
local detections = {}
local function addDetection(petName, ownerName, rate, jobId)
    table.insert(detections, 1, {
        pet = petName, owner = ownerName or "???", rate = rate or "?",
        jobId = jobId or game.JobId, time = os.time(), isOG = isOG(petName),
    })
    if #detections > 50 then table.remove(detections) end
end

-- ════════════════════ REMOTES ════════════════════
local Net = nil
pcall(function() Net = RS:WaitForChild("Packages", 5):WaitForChild("Net", 5) end)
local function findRE(n) if not Net then return nil end; for _, d in pairs(Net:GetDescendants()) do if d:IsA("RemoteEvent") and d.Name:find(n) then return d end end; return nil end
local function findRF(n) if not Net then return nil end; for _, d in pairs(Net:GetDescendants()) do if d:IsA("RemoteFunction") and d.Name:find(n) then return d end end; return nil end
local remotes = {}
pcall(function()
    remotes.duelSend = findRE("DuelService/Send") or findRE("DuelService/Request") or findRE("BattleService/Send") or findRE("BattleService/Request")
    remotes.duelSendRF = findRF("DuelService/Send") or findRF("DuelService/Request") or findRF("BattleService/Send") or findRF("BattleService/Request")
end)
pcall(function()
    for _, d in pairs(RS:GetDescendants()) do
        pcall(function()
            local n = d.Name:lower()
            if n:find("duel") or n:find("battle") or n:find("fight") or n:find("pvp") then
                if d:IsA("RemoteEvent") and not remotes.duelSend then remotes.duelSend = d
                elseif d:IsA("RemoteFunction") and not remotes.duelSendRF then remotes.duelSendRF = d end
            end
        end)
    end
end)

-- ════════════════════ XENHUB ════════════════════
local function setXenhubTarget(ownerName, petName)
    pcall(function() getgenv().XenhubTarget = ownerName end)
    pcall(function() getgenv().XenhubPet = petName end)
    pcall(function() getgenv().AutoStealTarget = ownerName end)
    pcall(function() getgenv().TargetPlayer = ownerName end)
    pcall(function() getgenv().TargetPet = petName end)
    pcall(function() if getgenv().Xenhub and getgenv().Xenhub.SetTarget then getgenv().Xenhub.SetTarget(ownerName) end end)
    pcall(function() if getgenv().XenHub and getgenv().XenHub.Target then getgenv().XenHub.Target = ownerName end end)
end

-- ════════════════════ STEAL LOGGER ════════════════════
local API_BASE = "https://phantomhub.onrender.com"

local function logSteal(petName, ownerName, serverId)
    task.spawn(function()
        pcall(function()
            local payload = HttpService:JSONEncode({
                pet = petName,
                owner = ownerName or "???",
                player = LP.Name,
                server_id = serverId or game.JobId,
            })
            local reqFn = request or (syn and syn.request) or (fluxus and fluxus.request)
                or http_request or (typeof(http) == "table" and http.request)
            if reqFn then
                reqFn({
                    Url = API_BASE .. "/api/log-steal",
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = payload,
                })
            end
        end)
    end)
end

-- ════════════════════ SOUND ════════════════════
local function playAlert()
    if not state.soundAlerts then return end
    pcall(function() local s = Instance.new("Sound"); s.SoundId = "rbxassetid://6042053626"; s.Volume = 0.5; s.Parent = game:GetService("SoundService"); s:Play(); task.delay(2, function() s:Destroy() end) end)
end
local function playOGAlert()
    if not state.soundAlerts then return end
    pcall(function() local s = Instance.new("Sound"); s.SoundId = "rbxassetid://5018104731"; s.Volume = 0.85; s.Parent = game:GetService("SoundService"); s:Play(); task.delay(3, function() s:Destroy() end) end)
end

-- ════════════════════ UI UTIL ════════════════════
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p end
local function stroke(p, col, th) local s = Instance.new("UIStroke"); s.Color = col or C.border; s.Thickness = th or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p end
local function tw(obj, props, dur) TweenService:Create(obj, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play() end
local function hover(btn, norm, over) btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3 = over}) end); btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3 = norm}) end) end

local W = 700  -- main width
local H = 540  -- main height

-- ════════════════════ SCREEN GUI ════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "PhantomAJGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = PG

-- ════════════════════ MAIN FRAME ════════════════════
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.new(0, W, 0, H)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Active = true
main.Parent = gui
corner(main, 14)
stroke(main, C.border)

-- drag
local dragging, dragStart, startPos
main.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = i.Position; startPos = main.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ═══════════════ HEADER BAR ═══════════════
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = C.bgDark
header.BorderSizePixel = 0
header.Parent = main
corner(header, 14)
-- mask bottom corners
local hMask = Instance.new("Frame"); hMask.Size = UDim2.new(1, 0, 0, 16); hMask.Position = UDim2.new(0, 0, 1, -16); hMask.BackgroundColor3 = C.bgDark; hMask.BorderSizePixel = 0; hMask.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 180, 0, 18)
title.Position = UDim2.new(0, 16, 0, 5)
title.BackgroundTransparency = 1
title.Text = "PHANTOMHUB"
title.TextColor3 = C.white
title.Font = Enum.Font.GothamBlack
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0, 200, 0, 12)
subtitle.Position = UDim2.new(0, 16, 0, 25)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Auto Joiner  ·  Steal a Brainrot"
subtitle.TextColor3 = C.textDim
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

-- header right: pills + minimize
local hRight = Instance.new("Frame")
hRight.Size = UDim2.new(0, 260, 0, 22)
hRight.Position = UDim2.new(1, -270, 0.5, -11)
hRight.BackgroundTransparency = 1
hRight.Parent = header
local hLayout = Instance.new("UIListLayout"); hLayout.FillDirection = Enum.FillDirection.Horizontal; hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; hLayout.VerticalAlignment = Enum.VerticalAlignment.Center; hLayout.Padding = UDim.new(0, 6); hLayout.Parent = hRight

local function makePill(text, col)
    local f = Instance.new("Frame"); f.AutomaticSize = Enum.AutomaticSize.X; f.Size = UDim2.new(0, 0, 0, 20); f.BackgroundColor3 = C.bgEl; f.Parent = hRight; corner(f, 5); stroke(f, C.border)
    local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 7); p.PaddingRight = UDim.new(0, 7); p.Parent = f
    local l = Instance.new("TextLabel"); l.AutomaticSize = Enum.AutomaticSize.X; l.Size = UDim2.new(0, 0, 1, 0); l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = col or C.textMid; l.Font = Enum.Font.GothamMedium; l.TextSize = 9; l.Parent = f
    return f, l
end
makePill("LIFETIME", C.gold)
makePill(getRegion(), C.textMid)

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 20, 0, 20)
minBtn.BackgroundColor3 = C.bgEl
minBtn.Text = "—"
minBtn.TextColor3 = C.textDim
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 11
minBtn.AutoButtonColor = false
minBtn.Parent = hRight
corner(minBtn, 5)
hover(minBtn, C.bgEl, C.borderLit)

-- ═══════════════ STATUS BAR ═══════════════
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -24, 0, 82)
statusBar.Position = UDim2.new(0, 12, 0, 50)
statusBar.BackgroundColor3 = C.bgCard
statusBar.BorderSizePixel = 0
statusBar.Parent = main
corner(statusBar, 10)
stroke(statusBar, C.border)

-- dot + status text
local dot = Instance.new("Frame"); dot.Size = UDim2.new(0, 7, 0, 7); dot.Position = UDim2.new(0, 12, 0, 12); dot.BackgroundColor3 = C.textDim; dot.BorderSizePixel = 0; dot.Parent = statusBar; corner(dot, 99)
local statusLbl = Instance.new("TextLabel"); statusLbl.Size = UDim2.new(0, 200, 0, 14); statusLbl.Position = UDim2.new(0, 25, 0, 9); statusLbl.BackgroundTransparency = 1; statusLbl.Text = "IDLE"; statusLbl.TextColor3 = C.textMid; statusLbl.Font = Enum.Font.GothamBold; statusLbl.TextSize = 11; statusLbl.TextXAlignment = Enum.TextXAlignment.Left; statusLbl.Parent = statusBar

-- progress bar
local progBg = Instance.new("Frame"); progBg.Size = UDim2.new(1, -24, 0, 3); progBg.Position = UDim2.new(0, 12, 0, 28); progBg.BackgroundColor3 = C.bgEl; progBg.BorderSizePixel = 0; progBg.Parent = statusBar; corner(progBg, 99)
local progFill = Instance.new("Frame"); progFill.Size = UDim2.new(0, 0, 1, 0); progFill.BackgroundColor3 = C.white; progFill.BorderSizePixel = 0; progFill.Parent = progBg; corner(progFill, 99)

-- stats row
local function stat(text, x, y, col)
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(0, 140, 0, 12); l.Position = UDim2.new(0, x, 0, y); l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = col or C.textDim; l.Font = Enum.Font.GothamMedium; l.TextSize = 9; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = statusBar; return l
end
local sServers = stat("Servers: 0", 12, 38)
local sOGs     = stat("OGs: 0", 12, 52, C.gold)
local sPlayers = stat("Players: —", 180, 38)
local sSession = stat("Session: 0m", 180, 52)
local sJob     = stat("Job: " .. game.JobId:sub(1,12) .. "…", 360, 38)
local sRegion  = stat("Region: " .. getRegion(), 360, 52)

-- controls
local ctrlRow = Instance.new("Frame"); ctrlRow.Size = UDim2.new(1, -24, 0, 24); ctrlRow.Position = UDim2.new(0, 12, 0, 68); ctrlRow.BackgroundTransparency = 1; ctrlRow.Parent = statusBar
local ctrlLay = Instance.new("UIListLayout"); ctrlLay.FillDirection = Enum.FillDirection.Horizontal; ctrlLay.Padding = UDim.new(0, 6); ctrlLay.Parent = ctrlRow

local function mkBtn(text, bg, fg, w)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0, w or 80, 1, 0); b.BackgroundColor3 = bg; b.Text = text; b.TextColor3 = fg or C.text; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.AutoButtonColor = false; b.Parent = ctrlRow; corner(b, 5); return b
end
local hopToggle = mkBtn("START", C.white, C.bg, 75)
local hopNow    = mkBtn("HOP NOW", C.bgEl, C.blue, 75)
hover(hopNow, C.bgEl, C.blueDim)
stroke(hopNow, C.border)

-- ═══════════════ TABS ═══════════════
local TAB_TOP = 138
local TAB_H   = 26
local BODY_Y  = TAB_TOP + TAB_H + 4

local tabBar = Instance.new("Frame"); tabBar.Size = UDim2.new(1, -24, 0, TAB_H); tabBar.Position = UDim2.new(0, 12, 0, TAB_TOP); tabBar.BackgroundTransparency = 1; tabBar.Parent = main
local tabLay = Instance.new("UIListLayout"); tabLay.FillDirection = Enum.FillDirection.Horizontal; tabLay.Padding = UDim.new(0, 4); tabLay.Parent = tabBar

local curTab = "Main"
local tabBtns = {}
local tabFrames = {}

local function makeTab(name)
    local on = (name == curTab)
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 74, 1, 0); b.BackgroundColor3 = on and C.white or C.bgEl; b.Text = name; b.TextColor3 = on and C.bg or C.textMid; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.AutoButtonColor = false; b.Parent = tabBar; corner(b, 5)
    if not on then stroke(b, C.border) end
    tabBtns[name] = b
end
makeTab("Main"); makeTab("Logs"); makeTab("Settings")

local function switchTab(name)
    curTab = name
    for n, b in pairs(tabBtns) do
        local on = (n == name)
        tw(b, {BackgroundColor3 = on and C.white or C.bgEl})
        b.TextColor3 = on and C.bg or C.textMid
    end
    for n, f in pairs(tabFrames) do f.Visible = (n == name) end
end
for n, b in pairs(tabBtns) do b.MouseButton1Click:Connect(function() switchTab(n) end) end

-- ═══════════════ TAB: MAIN ═══════════════
local mainTab = Instance.new("Frame"); mainTab.Size = UDim2.new(1, -24, 1, -(BODY_Y + 8)); mainTab.Position = UDim2.new(0, 12, 0, BODY_Y); mainTab.BackgroundTransparency = 1; mainTab.Visible = true; mainTab.Parent = main
tabFrames["Main"] = mainTab

-- column headers
local colDefs = {{"BRAINROT", 0, 0.30}, {"OWNER", 0.30, 0.20}, {"RATE", 0.50, 0.12}, {"AGE", 0.62, 0.08}, {"", 0.72, 0.28}}
local colRow = Instance.new("Frame"); colRow.Size = UDim2.new(1, 0, 0, 16); colRow.BackgroundTransparency = 1; colRow.Parent = mainTab
for _, d in ipairs(colDefs) do
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(d[3], 0, 1, 0); l.Position = UDim2.new(d[2], d[2] == 0 and 6 or 0, 0, 0); l.BackgroundTransparency = 1; l.Text = d[1]; l.TextColor3 = C.textDim; l.Font = Enum.Font.GothamBold; l.TextSize = 8; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = colRow
end

local feedScroll = Instance.new("ScrollingFrame"); feedScroll.Size = UDim2.new(1, 0, 1, -20); feedScroll.Position = UDim2.new(0, 0, 0, 18); feedScroll.BackgroundTransparency = 1; feedScroll.BorderSizePixel = 0; feedScroll.CanvasSize = UDim2.new(0, 0, 0, 0); feedScroll.ScrollBarThickness = 2; feedScroll.ScrollBarImageColor3 = C.dim; feedScroll.Parent = mainTab
local feedLay = Instance.new("UIListLayout"); feedLay.Padding = UDim.new(0, 3); feedLay.Parent = feedScroll
feedLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() feedScroll.CanvasSize = UDim2.new(0, 0, 0, feedLay.AbsoluteContentSize.Y + 6) end)

local emptyLbl = Instance.new("TextLabel"); emptyLbl.Size = UDim2.new(1, 0, 0, 40); emptyLbl.Position = UDim2.new(0, 0, 0.3, 0); emptyLbl.BackgroundTransparency = 1; emptyLbl.Text = "waiting for detections…"; emptyLbl.TextColor3 = C.textDim; emptyLbl.Font = Enum.Font.Gotham; emptyLbl.TextSize = 11; emptyLbl.Parent = feedScroll

-- ═══════════════ TAB: LOGS ═══════════════
local logsTab = Instance.new("Frame"); logsTab.Size = UDim2.new(1, -24, 1, -(BODY_Y + 8)); logsTab.Position = UDim2.new(0, 12, 0, BODY_Y); logsTab.BackgroundTransparency = 1; logsTab.Visible = false; logsTab.Parent = main
tabFrames["Logs"] = logsTab

local logBox = Instance.new("Frame"); logBox.Size = UDim2.new(1, 0, 1, 0); logBox.BackgroundColor3 = C.bgCard; logBox.BorderSizePixel = 0; logBox.Parent = logsTab; corner(logBox, 8); stroke(logBox, C.border)
local logScroll = Instance.new("ScrollingFrame"); logScroll.Size = UDim2.new(1, -12, 1, -12); logScroll.Position = UDim2.new(0, 6, 0, 6); logScroll.BackgroundTransparency = 1; logScroll.BorderSizePixel = 0; logScroll.CanvasSize = UDim2.new(0, 0, 0, 0); logScroll.ScrollBarThickness = 2; logScroll.ScrollBarImageColor3 = C.dim; logScroll.Parent = logBox
local logLay = Instance.new("UIListLayout"); logLay.Padding = UDim.new(0, 1); logLay.SortOrder = Enum.SortOrder.LayoutOrder; logLay.Parent = logScroll
logLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() logScroll.CanvasSize = UDim2.new(0, 0, 0, logLay.AbsoluteContentSize.Y + 4) end)

local logCount = 0
local function addLog(text, color)
    logCount = logCount + 1
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, 0, 0, 16); l.BackgroundTransparency = 1
    l.Text = "[" .. os.date("%H:%M:%S") .. "] " .. text
    l.TextColor3 = color or C.textMid; l.Font = Enum.Font.Code; l.TextSize = 10; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextWrapped = true; l.AutomaticSize = Enum.AutomaticSize.Y; l.LayoutOrder = logCount; l.Parent = logScroll
    task.defer(function() logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y) end)
end

addLog("PhantomHub AJ loaded", C.white)
addLog("Region: " .. getRegion() .. "  |  Server: " .. game.JobId:sub(1,12), C.textDim)

-- ═══════════════ TAB: SETTINGS ═══════════════
local setTab = Instance.new("Frame"); setTab.Size = UDim2.new(1, -24, 1, -(BODY_Y + 8)); setTab.Position = UDim2.new(0, 12, 0, BODY_Y); setTab.BackgroundTransparency = 1; setTab.Visible = false; setTab.Parent = main
tabFrames["Settings"] = setTab

local setBox = Instance.new("Frame"); setBox.Size = UDim2.new(1, 0, 1, 0); setBox.BackgroundColor3 = C.bgCard; setBox.BorderSizePixel = 0; setBox.Parent = setTab; corner(setBox, 8); stroke(setBox, C.border)

local function section(text, y)
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -24, 0, 14); l.Position = UDim2.new(0, 14, 0, y); l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = C.dim; l.Font = Enum.Font.GothamBold; l.TextSize = 8; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = setBox
end

local function toggle(label, y, default, cb)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, -28, 0, 28); row.Position = UDim2.new(0, 14, 0, y); row.BackgroundTransparency = 1; row.Parent = setBox
    local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -44, 1, 0); l.BackgroundTransparency = 1; l.Text = label; l.TextColor3 = C.text; l.Font = Enum.Font.GothamMedium; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = row
    local bg = Instance.new("TextButton"); bg.Size = UDim2.new(0, 36, 0, 18); bg.Position = UDim2.new(1, -36, 0.5, -9); bg.BackgroundColor3 = default and C.white or C.dim; bg.Text = ""; bg.AutoButtonColor = false; bg.Parent = row; corner(bg, 99)
    local cir = Instance.new("Frame"); cir.Size = UDim2.new(0, 12, 0, 12); cir.Position = default and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6); cir.BackgroundColor3 = default and C.bg or C.textDim; cir.BorderSizePixel = 0; cir.Parent = bg; corner(cir, 99)
    local on = default
    bg.MouseButton1Click:Connect(function()
        on = not on; cb(on)
        tw(bg, {BackgroundColor3 = on and C.white or C.dim})
        tw(cir, {Position = on and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6), BackgroundColor3 = on and C.bg or C.textDim})
    end)
end

section("ALERTS", 8)
toggle("Sound Alerts", 24, state.soundAlerts, function(v) state.soundAlerts = v end)

section("ACTIONS", 60)
toggle("Auto Xenhub Target", 76, state.autoXenhub, function(v) state.autoXenhub = v end)
toggle("Copy Owner Name", 106, state.autoCopyOwner, function(v) state.autoCopyOwner = v end)
toggle("Auto Log Steal", 136, state.autoLogSteal, function(v) state.autoLogSteal = v end)

section("UTILITY", 172)
toggle("Anti-AFK", 188, state.antiAfk, function(v) state.antiAfk = v end)

section("SCAN TIME", 224)

local stLbl = Instance.new("TextLabel"); stLbl.Size = UDim2.new(0, 80, 0, 14); stLbl.Position = UDim2.new(1, -94, 0, 224); stLbl.BackgroundTransparency = 1; stLbl.Text = state.scanTime .. "s"; stLbl.TextColor3 = C.textMid; stLbl.Font = Enum.Font.GothamMedium; stLbl.TextSize = 8; stLbl.TextXAlignment = Enum.TextXAlignment.Right; stLbl.Parent = setBox

local stRow = Instance.new("Frame"); stRow.Size = UDim2.new(1, -28, 0, 24); stRow.Position = UDim2.new(0, 14, 0, 240); stRow.BackgroundTransparency = 1; stRow.Parent = setBox
local stLay = Instance.new("UIListLayout"); stLay.FillDirection = Enum.FillDirection.Horizontal; stLay.Padding = UDim.new(0, 4); stLay.Parent = stRow

for _, sec in ipairs({10, 15, 18, 25, 30}) do
    local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 44, 1, 0); b.BackgroundColor3 = sec == state.scanTime and C.white or C.bgEl; b.Text = sec .. "s"; b.TextColor3 = sec == state.scanTime and C.bg or C.textMid; b.Font = Enum.Font.GothamBold; b.TextSize = 10; b.AutoButtonColor = false; b.Parent = stRow; corner(b, 5)
    b.MouseButton1Click:Connect(function()
        state.scanTime = sec; stLbl.Text = sec .. "s"
        for _, c in ipairs(stRow:GetChildren()) do
            if c:IsA("TextButton") then
                local a = (c.Text == sec .. "s"); tw(c, {BackgroundColor3 = a and C.white or C.bgEl}); c.TextColor3 = a and C.bg or C.textMid
            end
        end
    end)
end

-- ═══════════════ MINIMIZED PILL ═══════════════
local pill = Instance.new("TextButton"); pill.Size = UDim2.new(0, 320, 0, 34); pill.Position = UDim2.new(0.5, -160, 0, 12); pill.BackgroundColor3 = C.bg; pill.Text = ""; pill.AutoButtonColor = false; pill.Visible = false; pill.Active = true; pill.Parent = gui; corner(pill, 8); stroke(pill, C.border)
local pTitle = Instance.new("TextLabel"); pTitle.Size = UDim2.new(0, 130, 1, 0); pTitle.Position = UDim2.new(0, 12, 0, 0); pTitle.BackgroundTransparency = 1; pTitle.Text = "PHANTOMHUB AJ"; pTitle.TextColor3 = C.white; pTitle.Font = Enum.Font.GothamBold; pTitle.TextSize = 10; pTitle.TextXAlignment = Enum.TextXAlignment.Left; pTitle.Parent = pill
local pStatus = Instance.new("TextLabel"); pStatus.Size = UDim2.new(0, 80, 1, 0); pStatus.Position = UDim2.new(0, 145, 0, 0); pStatus.BackgroundTransparency = 1; pStatus.Text = "IDLE"; pStatus.TextColor3 = C.textDim; pStatus.Font = Enum.Font.GothamMedium; pStatus.TextSize = 9; pStatus.Parent = pill
local pOG = Instance.new("TextLabel"); pOG.Size = UDim2.new(0, 30, 1, 0); pOG.Position = UDim2.new(1, -38, 0, 0); pOG.BackgroundTransparency = 1; pOG.Text = "0"; pOG.TextColor3 = C.gold; pOG.Font = Enum.Font.GothamBold; pOG.TextSize = 12; pOG.Parent = pill

-- pill drag
local pDrag, pDS, pSP
pill.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then pDrag = true; pDS = i.Position; pSP = pill.Position; i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then pDrag = false end end) end end)
UserInputService.InputChanged:Connect(function(i) if pDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - pDS; pill.Position = UDim2.new(pSP.X.Scale, pSP.X.Offset + d.X, pSP.Y.Scale, pSP.Y.Offset + d.Y) end end)

-- minimize / restore
local minimized = false
local function minimize()
    if minimized then return end; minimized = true
    TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {Size = UDim2.new(0, 0, 0, 0)}):Play()
    task.wait(0.25); main.Visible = false; main.Size = UDim2.new(0, W, 0, H)
    pill.Visible = true; pill.Size = UDim2.new(0, 0, 0, 32)
    TweenService:Create(pill, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 320, 0, 34)}):Play()
end
local function restore()
    if not minimized then return end; minimized = false
    TweenService:Create(pill, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 0, 32)}):Play()
    task.wait(0.12); pill.Visible = false; pill.Size = UDim2.new(0, 320, 0, 34)
    main.Size = UDim2.new(0, 0, 0, 0); main.Visible = true
    TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, W, 0, H)}):Play()
end
minBtn.MouseButton1Click:Connect(minimize)
pill.MouseButton1Click:Connect(restore)

-- ═══════════════ FEED BUILDER ═══════════════
local function formatAge(s) if s < 60 then return math.floor(s) .. "s" end; if s < 3600 then return math.floor(s / 60) .. "m" end; return math.floor(s / 3600) .. "h" end

local feedEntries = {}
local function buildFeedEntry(det)
    local og = det.isOG
    local hl = isHighlighted(det.pet)

    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 36); row.BackgroundColor3 = C.bgCard; row.BorderSizePixel = 0; row.LayoutOrder = -(det.time or os.time()); row.Parent = feedScroll; corner(row, 6)
    stroke(row, og and C.gold or (hl and C.borderLit or C.border), og and 1.5 or 1)

    if og then
        local bar = Instance.new("Frame"); bar.Size = UDim2.new(0, 3, 0.5, 0); bar.Position = UDim2.new(0, 2, 0.25, 0); bar.BackgroundColor3 = C.gold; bar.BorderSizePixel = 0; bar.Parent = row; corner(bar, 2)
    end

    local function cell(text, xScale, wScale, col, font, sz)
        local l = Instance.new("TextLabel"); l.Size = UDim2.new(wScale, 0, 1, 0); l.Position = UDim2.new(xScale, xScale == 0 and (og and 10 or 6) or 0, 0, 0); l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = col or C.textMid; l.Font = font or Enum.Font.GothamMedium; l.TextSize = sz or 11; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextTruncate = Enum.TextTruncate.AtEnd; l.Parent = row; return l
    end

    cell(det.pet, 0, 0.30, og and C.gold or C.text, og and Enum.Font.GothamBold or Enum.Font.GothamMedium, 11)
    cell(det.owner, 0.30, 0.20, C.textMid, nil, 11)
    cell(det.rate, 0.50, 0.12, og and C.gold or C.textDim, nil, 10)
    local ageLbl = cell(formatAge(os.time() - det.time), 0.62, 0.08, C.textDim, nil, 10)

    local isCurrent = (det.jobId == game.JobId)

    if isCurrent then
        -- Log Steal button
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.28, -8, 0, 24)
        btn.Position = UDim2.new(0.72, 0, 0.5, -12)
        btn.BackgroundColor3 = og and C.gold or C.white
        btn.Text = "Log Steal"
        btn.TextColor3 = C.bg
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.AutoButtonColor = false
        btn.Parent = row
        corner(btn, 5)

        -- auto log on detection
        if state.autoLogSteal then
            logSteal(det.pet, det.owner, det.jobId)
            btn.Text = "Logged ✓"
            btn.BackgroundColor3 = C.green
            task.delay(2, function() btn.Text = "Log Steal"; btn.BackgroundColor3 = og and C.gold or C.white end)
        end

        btn.MouseButton1Click:Connect(function()
            btn.Text = "Logged ✓"
            btn.BackgroundColor3 = C.green
            logSteal(det.pet, det.owner, det.jobId)
            addLog("Steal logged: " .. det.pet .. " from " .. det.owner, C.gold)
            task.delay(2, function()
                if btn.Parent then btn.Text = "Log Steal"; btn.BackgroundColor3 = og and C.gold or C.white end
            end)
        end)
    else
        -- server ID label for remote detections
        cell(det.jobId:sub(1,6), 0.72, 0.28, C.textDim, nil, 9)
    end

    row.MouseEnter:Connect(function() tw(row, {BackgroundColor3 = C.bgEl}) end)
    row.MouseLeave:Connect(function() tw(row, {BackgroundColor3 = C.bgCard}) end)

    -- fade in
    row.BackgroundTransparency = 1
    task.defer(function() tw(row, {BackgroundTransparency = 0}, 0.25) end)

    table.insert(feedEntries, {frame = row, ageLbl = ageLbl, det = det})
    emptyLbl.Visible = false
    return row
end

-- ═══════════════ SCANNER ═══════════════
local function getBrainrotName(obj)
    local name = nil
    pcall(function() local bd = obj:FindFirstChild("BrainrotData"); if bd then if bd:IsA("StringValue") then name = bd.Value elseif bd:IsA("ObjectValue") and bd.Value then name = bd.Value.Name end end end)
    if not name then pcall(function() local bn = obj:FindFirstChild("BrainrotName"); if bn and bn:IsA("StringValue") then name = bn.Value end end) end
    if not name then pcall(function() local nt = obj:FindFirstChild("NameTag") or obj:FindFirstChild("Name"); if nt then if nt:IsA("StringValue") then name = nt.Value elseif nt:IsA("BillboardGui") then local tl = nt:FindFirstChildWhichIsA("TextLabel", true); if tl then name = tl.Text end end end end) end
    if not name then name = obj.Name end
    return name
end

local function getOwnerName(obj)
    local owner = nil
    pcall(function()
        local o = obj:FindFirstChild("Owner") or obj:FindFirstChild("PlotOwner") or obj:FindFirstChild("PlayerOwner")
        if o then
            if o:IsA("ObjectValue") and o.Value then owner = o.Value.Name
            elseif o:IsA("StringValue") then owner = o.Value
            elseif o:IsA("IntValue") then local p = Players:GetPlayerByUserId(o.Value); if p then owner = p.Name end end
        end
    end)
    if not owner then
        pcall(function()
            local par = obj.Parent
            while par and par ~= workspace do
                local plr = Players:FindFirstChild(par.Name); if plr then owner = par.Name; break end
                local o2 = par:FindFirstChild("Owner") or par:FindFirstChild("PlotOwner")
                if o2 then if o2:IsA("ObjectValue") and o2.Value then owner = o2.Value.Name; break elseif o2:IsA("StringValue") then owner = o2.Value; break end end
                par = par.Parent
            end
        end)
    end
    return owner
end

local foundOGs = {}

local function scanCurrentServer()
    local found = {}
    -- workspace models
    pcall(function() for _, obj in pairs(workspace:GetDescendants()) do pcall(function()
        if not obj:IsA("Model") then return end
        local hit = obj:FindFirstChild("BrainrotData") or obj:FindFirstChild("BrainrotName") or (obj:FindFirstChild("Humanoid") and (obj:FindFirstChild("Owner") or obj:FindFirstChild("PlotOwner"))) or obj.Name:lower():find("brainrot")
        if hit then local bn = getBrainrotName(obj); local on = getOwnerName(obj); if bn and isOG(bn) then local info = getOGInfo(bn); local k = (on or "???") .. "_" .. bn; if not found[k] then found[k] = {pet = info and info.name or bn, owner = on or "???", rate = info and info.rate or "?"} end end end
    end) end end)
    -- backpacks + characters
    pcall(function() for _, plr in pairs(Players:GetPlayers()) do pcall(function()
        for _, item in pairs(plr.Backpack:GetChildren()) do pcall(function() if isOG(item.Name) then local info = getOGInfo(item.Name); local k = plr.Name .. "_" .. item.Name; if not found[k] then found[k] = {pet = info and info.name or item.Name, owner = plr.Name, rate = info and info.rate or "?"} end end end) end
        if plr.Character then for _, item in pairs(plr.Character:GetChildren()) do pcall(function() if item:IsA("Tool") and isOG(item.Name) then local info = getOGInfo(item.Name); local k = plr.Name .. "_" .. item.Name; if not found[k] then found[k] = {pet = info and info.name or item.Name, owner = plr.Name, rate = info and info.rate or "?"} end end end) end end
    end) end end)
    -- billboard guis
    pcall(function() for _, obj in pairs(workspace:GetDescendants()) do pcall(function()
        if obj:IsA("BillboardGui") then for _, ch in pairs(obj:GetDescendants()) do if ch:IsA("TextLabel") and ch.Text and isOG(ch.Text) then
            local info = getOGInfo(ch.Text); local on = nil; local p = obj.Parent
            while p and p ~= workspace do if Players:FindFirstChild(p.Name) then on = p.Name; break end; local ov = p:FindFirstChild("Owner") or p:FindFirstChild("PlotOwner"); if ov then if ov:IsA("ObjectValue") and ov.Value then on = ov.Value.Name; break elseif ov:IsA("StringValue") then on = ov.Value; break end end; p = p.Parent end
            local k = (on or "???") .. "_" .. ch.Text; if not found[k] then found[k] = {pet = info and info.name or ch.Text, owner = on or "???", rate = info and info.rate or "?"} end
        end end end
    end) end end)
    -- UI labels
    pcall(function() for _, g in pairs(PG:GetChildren()) do if g.Name ~= "PhantomAJGui" then pcall(function() for _, l in pairs(g:GetDescendants()) do if l:IsA("TextLabel") and l.Text and isOG(l.Text) and not l.Text:lower():find("phantomhub") then local info = getOGInfo(l.Text); local k = "ui_" .. l.Text; if not found[k] then found[k] = {pet = info and info.name or l.Text, owner = "???", rate = info and info.rate or "?"} end end end end) end end end)
    return found
end

-- ═══════════════ SERVER LIST + HOP ═══════════════
local serverQueue = {}
local serverCursor = ""

local function fetchServers()
    local servers = {}
    pcall(function()
        local reqFn = request or (syn and syn.request) or (fluxus and fluxus.request) or http_request or (typeof(http) == "table" and http.request)
        if not reqFn then return end
        local url = "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/0?sortOrder=2&excludeFullGames=" .. tostring(CONFIG.EXCLUDE_FULL) .. "&limit=" .. CONFIG.MAX_SERVERS
        if serverCursor ~= "" then url = url .. "&cursor=" .. serverCursor end
        local resp = reqFn({Url = url, Method = "GET", Headers = {["Content-Type"] = "application/json"}})
        local data = HttpService:JSONDecode(resp.Body or resp.body)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.id and s.id ~= game.JobId and s.playing >= CONFIG.MIN_PLAYERS then
                    table.insert(servers, {jobId = s.id, players = s.playing, maxPlayers = s.maxPlayers})
                end
            end
            serverCursor = data.nextPageCursor or ""
        end
    end)
    return servers
end

local function hopToServer(jobId)
    pcall(function()
        getgenv().aj_servers_checked = state.serversChecked
        getgenv().aj_ogs_found = state.ogsFound
        getgenv().aj_auto_hop = true
        queuePersist()
        TeleportService:TeleportToPlaceInstance(PLACE_ID, jobId, LP)
    end)
end

local function hopRandom()
    pcall(function()
        getgenv().aj_servers_checked = state.serversChecked
        getgenv().aj_ogs_found = state.ogsFound
        getgenv().aj_auto_hop = state.hopping
        queuePersist()
        TeleportService:Teleport(PLACE_ID, LP)
    end)
end

-- ═══════════════ UI UPDATES ═══════════════
local function setStatus(text, col) statusLbl.Text = text; dot.BackgroundColor3 = col or C.textDim; pStatus.Text = text:sub(1, 20) end

local function updateStats()
    sServers.Text = "Servers: " .. state.serversChecked
    sOGs.Text = "OGs: " .. state.ogsFound
    sPlayers.Text = "Players: " .. #Players:GetPlayers() .. "/" .. (Players.MaxPlayers or "?")
    sSession.Text = "Session: " .. math.floor((os.time() - state.sessionStart) / 60) .. "m"
    pOG.Text = tostring(state.ogsFound)
    for _, e in ipairs(feedEntries) do if e.ageLbl and e.ageLbl.Parent and e.det then e.ageLbl.Text = formatAge(os.time() - e.det.time) end end
end

-- ═══════════════ AUTO-JOIN LOOP ═══════════════
local function autoJoinLoop()
    state.scanning = true
    state.serversChecked = state.serversChecked + 1
    setStatus("SCANNING", C.green)

    progFill.Size = UDim2.new(0, 0, 1, 0)
    TweenService:Create(progFill, TweenInfo.new(state.scanTime, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)}):Play()

    local interval = 3
    local reps = math.floor(state.scanTime / interval)
    local ogHit = false

    for i = 1, reps do
        if not state.running or not state.hopping or ogHit then break end
        local found = scanCurrentServer()
        for key, data in pairs(found) do
            if not foundOGs[key] then
                foundOGs[key] = data
                state.ogsFound = state.ogsFound + 1
                addDetection(data.pet, data.owner, data.rate, game.JobId)
                buildFeedEntry(detections[1])
                if isOG(data.pet) then
                    playOGAlert(); ogHit = true
                    addLog("OG FOUND: " .. data.pet .. " — " .. data.owner, C.gold)
                    setStatus("OG FOUND: " .. data.pet, C.gold)
                    tw(dot, {BackgroundColor3 = C.gold}); tw(progFill, {BackgroundColor3 = C.gold})
                    if state.autoXenhub then setXenhubTarget(data.owner, data.pet) end
                    if state.autoCopyOwner then pcall(function() setclipboard(data.owner) end) end
                else
                    playAlert()
                    addLog("Detected: " .. data.pet .. " — " .. data.owner, C.green)
                end
            end
        end
        task.wait(interval)
    end

    state.scanning = false

    if ogHit then
        state.hopping = false
        hopToggle.Text = "START"; hopToggle.BackgroundColor3 = C.white; hopToggle.TextColor3 = C.bg
        setStatus("STAYING — OG FOUND", C.gold)
        progFill.BackgroundColor3 = C.gold
        addLog("Stopped — staying in server with OG", C.gold)
        return false
    end
    return true
end

local hopThread = nil

local function startHopping()
    if hopThread then return end
    state.hopping = true
    hopToggle.Text = "STOP"; hopToggle.BackgroundColor3 = C.red; hopToggle.TextColor3 = C.text
    addLog("Auto-hop started", C.white)

    hopThread = task.spawn(function()
        while state.running and state.hopping do
            local shouldHop = autoJoinLoop()
            if not shouldHop or not state.hopping then break end

            setStatus("HOPPING…", C.blue); tw(progFill, {BackgroundColor3 = C.blue})
            task.wait(CONFIG.HOP_DELAY)
            if not state.hopping or not state.running then break end

            if #serverQueue == 0 then
                setStatus("FETCHING…", C.blue)
                serverQueue = fetchServers()
                addLog("Fetched " .. #serverQueue .. " servers", C.textMid)
            end

            if #serverQueue > 0 then
                local nxt = table.remove(serverQueue, 1)
                addLog("Hop → " .. nxt.jobId:sub(1,8) .. " (" .. nxt.players .. "p)", C.blue)
                setStatus("JOINING…", C.blue)
                hopToServer(nxt.jobId)
                task.wait(10)
            else
                addLog("No servers — random hop", C.blue)
                setStatus("RANDOM HOP…", C.blue)
                hopRandom()
                task.wait(10)
            end
        end
        hopThread = nil
        if not state.hopping then setStatus("IDLE", C.textDim); progFill.Size = UDim2.new(0, 0, 1, 0); progFill.BackgroundColor3 = C.white end
    end)
end

local function stopHopping()
    state.hopping = false
    hopToggle.Text = "START"; hopToggle.BackgroundColor3 = C.white; hopToggle.TextColor3 = C.bg
    addLog("Auto-hop stopped", C.red)
end

hopToggle.MouseButton1Click:Connect(function() if state.hopping then stopHopping() else startHopping() end end)
hopNow.MouseButton1Click:Connect(function()
    hopNow.Text = "…"; hopNow.TextColor3 = C.text
    task.spawn(function()
        if #serverQueue == 0 then serverQueue = fetchServers() end
        if #serverQueue > 0 then local nxt = table.remove(serverQueue, 1); state.serversChecked = state.serversChecked + 1; hopToServer(nxt.jobId)
        else hopRandom() end
    end)
    task.delay(3, function() hopNow.Text = "HOP NOW"; hopNow.TextColor3 = C.blue end)
end)

-- ═══════════════ ANTI-AFK ═══════════════
task.spawn(function()
    local VU = game:GetService("VirtualUser")
    LP.Idled:Connect(function() if state.antiAfk then pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new(0, 0)) end) end end)
    while state.running do if state.antiAfk then pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new(0, 0)) end) end; task.wait(240) end
end)

-- ═══════════════ TELEPORT FAIL ═══════════════
TeleportService.TeleportInitFailed:Connect(function(_, _, errMsg)
    addLog("Teleport failed: " .. tostring(errMsg), C.red)
    setStatus("TP FAILED", C.red)
    task.wait(3)
    if state.hopping then
        if #serverQueue > 0 then local nxt = table.remove(serverQueue, 1); setStatus("RETRYING…", C.blue); hopToServer(nxt.jobId)
        else setStatus("FETCHING…", C.blue); serverQueue = fetchServers(); if #serverQueue > 0 then local nxt = table.remove(serverQueue, 1); hopToServer(nxt.jobId) end end
    end
end)

-- ═══════════════ PERIODIC ═══════════════
task.spawn(function() while state.running do updateStats(); task.wait(1) end end)

-- ═══════════════ INITIAL SCAN ═══════════════
task.spawn(function()
    task.wait(2)
    setStatus("INITIAL SCAN…", C.green)
    local found = scanCurrentServer()
    local ogHere = false
    for key, data in pairs(found) do
        if not foundOGs[key] then
            foundOGs[key] = data; state.ogsFound = state.ogsFound + 1
            addDetection(data.pet, data.owner, data.rate, game.JobId)
            buildFeedEntry(detections[1])
            if isOG(data.pet) then playOGAlert(); ogHere = true; addLog("OG in server: " .. data.pet, C.gold)
                if state.autoXenhub then setXenhubTarget(data.owner, data.pet) end
                if state.autoCopyOwner then pcall(function() setclipboard(data.owner) end) end
            else playAlert() end
        end
    end
    if ogHere then setStatus("OG HERE!", C.gold); tw(dot, {BackgroundColor3 = C.gold})
    else setStatus("IDLE", C.textDim) end
    if getgenv().aj_auto_hop and not ogHere then task.wait(1); startHopping() end
end)

-- ═══════════════ LOAD ANIMATION ═══════════════
do
    local ov = Instance.new("Frame"); ov.Size = UDim2.new(1, 0, 1, 0); ov.BackgroundColor3 = C.bg; ov.ZIndex = 100; ov.Parent = main; corner(ov, 14)
    local lt = Instance.new("TextLabel"); lt.Size = UDim2.new(1, 0, 0, 20); lt.Position = UDim2.new(0, 0, 0.38, 0); lt.BackgroundTransparency = 1; lt.Text = "PHANTOMHUB"; lt.TextColor3 = C.white; lt.Font = Enum.Font.GothamBlack; lt.TextSize = 17; lt.ZIndex = 101; lt.Parent = ov
    local ls = Instance.new("TextLabel"); ls.Size = UDim2.new(1, 0, 0, 14); ls.Position = UDim2.new(0, 0, 0.38, 24); ls.BackgroundTransparency = 1; ls.Text = "Auto Joiner"; ls.TextColor3 = C.textDim; ls.Font = Enum.Font.GothamMedium; ls.TextSize = 11; ls.ZIndex = 101; ls.Parent = ov
    local lb = Instance.new("Frame"); lb.Size = UDim2.new(0, 180, 0, 2); lb.Position = UDim2.new(0.5, -90, 0.38, 50); lb.BackgroundColor3 = C.bgEl; lb.ZIndex = 101; lb.Parent = ov; corner(lb, 99)
    local lf = Instance.new("Frame"); lf.Size = UDim2.new(0, 0, 1, 0); lf.BackgroundColor3 = C.white; lf.ZIndex = 102; lf.Parent = lb; corner(lf, 99)
    task.spawn(function()
        local t = TweenService:Create(lf, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}); t:Play(); t.Completed:Wait(); task.wait(0.15)
        local f = TweenInfo.new(0.25, Enum.EasingStyle.Quad)
        TweenService:Create(ov, f, {BackgroundTransparency = 1}):Play()
        TweenService:Create(lt, f, {TextTransparency = 1}):Play()
        TweenService:Create(ls, f, {TextTransparency = 1}):Play()
        TweenService:Create(lb, f, {BackgroundTransparency = 1}):Play()
        TweenService:Create(lf, f, {BackgroundTransparency = 1}):Play()
        task.wait(0.25); ov:Destroy()
    end)
end

end)
if not ok then warn("[PhantomHub AJ] " .. tostring(err)) end

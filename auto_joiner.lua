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
local Camera = workspace.CurrentCamera
local PLACE_ID = game.PlaceId

-- ════════════════════ CONFIGURATION ════════════════════
local CONFIG = {
    GITHUB_RAW       = "https://raw.githubusercontent.com/765632/PhantomHub/master",
    SCAN_TIME        = 18,      -- seconds to scan each server before hopping
    HOP_DELAY        = 2,       -- delay between hop decision and teleport
    MAX_SERVERS      = 100,     -- max servers to fetch per batch
    MIN_PLAYERS      = 1,       -- skip empty servers
    EXCLUDE_FULL     = true,    -- skip full servers
    PERSIST          = true,    -- queue_on_teleport for persistence
}

-- ════════════════════ KEY + HTTP ════════════════════
-- loader already validated the key — just grab it for persistence
local USER_KEY = getgenv().phantom_key or getgenv().script_key or ""

local function httpReq(url, method, payload)
    method = method or "GET"
    local body = nil
    local reqFn = request or (syn and syn.request) or (fluxus and fluxus.request)
        or http_request or (typeof(http) == "table" and http.request)
    if reqFn then
        local opts = {
            Url = url, Method = method,
            Headers = {["Content-Type"] = "application/json"}
        }
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

-- ════════════════════ PERSISTENCE (queue_on_teleport) ════════════════════
local function queuePersist()
    if not CONFIG.PERSIST then return end
    pcall(function()
        local persistSrc = 'getgenv().phantom_key = "' .. USER_KEY .. '"\n'
            .. 'getgenv().aj_auto_hop = true\n'
            .. 'getgenv().aj_servers_checked = ' .. tostring(getgenv().aj_servers_checked or 0) .. '\n'
            .. 'getgenv().aj_ogs_found = ' .. tostring(getgenv().aj_ogs_found or 0) .. '\n'
            .. 'loadstring(game:HttpGet("' .. CONFIG.GITHUB_RAW .. '/aj_loader.lua?v=" .. tostring(tick())))()\n'
        if queue_on_teleport then queue_on_teleport(persistSrc)
        elseif (syn and syn.queue_on_teleport) then syn.queue_on_teleport(persistSrc)
        elseif (fluxus and fluxus.queue_on_teleport) then fluxus.queue_on_teleport(persistSrc) end
    end)
end

queuePersist()

-- ════════════════════ CLEANUP OLD GUI ════════════════════
for _, g in ipairs(PG:GetChildren()) do
    if g.Name == "PhantomAJGui" then g:Destroy() end
end
pcall(function()
    local cg = game:GetService("CoreGui"):FindFirstChild("PhantomAJGui")
    if cg then cg:Destroy() end
end)

-- ════════════════════ THEME (PhantomHub dark) ════════════════════
local T = {
    bg        = Color3.fromRGB(10, 10, 10),
    bgDark    = Color3.fromRGB(5, 5, 5),
    bgCard    = Color3.fromRGB(18, 18, 18),
    bgPill    = Color3.fromRGB(24, 24, 24),
    stroke    = Color3.fromRGB(40, 40, 40),
    strokeLit = Color3.fromRGB(65, 65, 65),
    accent    = Color3.fromRGB(255, 255, 255),
    accentDim = Color3.fromRGB(60, 60, 60),
    text      = Color3.fromRGB(245, 245, 245),
    textMid   = Color3.fromRGB(170, 170, 170),
    textDim   = Color3.fromRGB(110, 110, 110),
    ogGold    = Color3.fromRGB(255, 190, 60),
    ogGoldDim = Color3.fromRGB(140, 100, 20),
    danger    = Color3.fromRGB(255, 70, 70),
    success   = Color3.fromRGB(80, 255, 120),
    hop       = Color3.fromRGB(100, 160, 255),
    hopDim    = Color3.fromRGB(40, 70, 130),
}

local TwnFast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TwnMed  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TwnSlow = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ════════════════════ STATE ════════════════════
local state = {
    running       = true,
    hopping       = getgenv().aj_auto_hop or false,
    paused        = false,
    scanning      = false,
    serversChecked = getgenv().aj_servers_checked or 0,
    ogsFound      = getgenv().aj_ogs_found or 0,
    currentJobId  = game.JobId,
    scanStart     = 0,
    sessionStart  = os.time(),
    soundAlerts   = true,
    autoXenhub    = true,
    autoCopyOwner = false,
    antiAfk       = true,
    scanTime      = CONFIG.SCAN_TIME,
}

-- ════════════════════ OG BRAINROT LIST ════════════════════
local OG_BRAINROTS = {
    {name = "Skibidi Toilet",      rate = "$450M/s", tier = 1},
    {name = "John Pork",           rate = "$500M/s", tier = 2},
    {name = "Headless Horseman",   rate = "$600M/s", tier = 3},
    {name = "Meowl",               rate = "$600M/s", tier = 3},
    {name = "Strawberry Elephant", rate = "$750M/s", tier = 4},
}

local OG_LOOKUP = {}
local OG_KEYWORDS = {}
for _, og in ipairs(OG_BRAINROTS) do
    OG_LOOKUP[og.name:lower()] = og
    for word in og.name:lower():gmatch("%S+") do
        if #word > 2 and word ~= "the" then
            OG_KEYWORDS[word] = og.name
        end
    end
end

local function isOG(name)
    if not name then return false end
    local lo = name:lower()
    if OG_LOOKUP[lo] then return true end
    for kw, _ in pairs(OG_KEYWORDS) do
        if lo:find(kw, 1, true) then return true end
    end
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

-- highlighted pets (high-value targets including OGs + rare mutations)
local HIGHLIGHT_NAMES = {
    "Headless", "Strawberry", "Meowl", "Skibidi", "John Pork",
    "Griffin", "Signore", "Elefanto", "Love Love", "Celestial",
    "Cerberus", "GOAT", "Dragon Cannelloni", "Hydra",
}

local function isHighlighted(name)
    if not name then return false end
    for _, h in ipairs(HIGHLIGHT_NAMES) do
        if name:find(h) then return true end
    end
    return false
end

-- ════════════════════ DETECTIONS DB ════════════════════
local detections = {} -- {petName, ownerName, rate, jobId, timestamp, isOG}

local function addDetection(petName, ownerName, rate, jobId)
    table.insert(detections, 1, {
        pet = petName,
        owner = ownerName or "???",
        rate = rate or "?",
        jobId = jobId or game.JobId,
        time = os.time(),
        isOG = isOG(petName),
    })
    if #detections > 50 then table.remove(detections) end
end

-- ════════════════════ REMOTE DISCOVERY ════════════════════
local Net = nil
pcall(function() Net = RS:WaitForChild("Packages", 5):WaitForChild("Net", 5) end)

local function findRE(name)
    if not Net then return nil end
    for _, d in pairs(Net:GetDescendants()) do
        if d:IsA("RemoteEvent") and d.Name:find(name) then return d end
    end
    return nil
end

local function findRF(name)
    if not Net then return nil end
    for _, d in pairs(Net:GetDescendants()) do
        if d:IsA("RemoteFunction") and d.Name:find(name) then return d end
    end
    return nil
end

local remotes = {}
pcall(function()
    remotes.duelSend   = findRE("DuelService/Send") or findRE("DuelService/Request")
        or findRE("BattleService/Send") or findRE("BattleService/Request")
    remotes.duelSendRF = findRF("DuelService/Send") or findRF("DuelService/Request")
        or findRF("BattleService/Send") or findRF("BattleService/Request")
end)

-- brute-force for duel remotes
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

-- ════════════════════ XENHUB INTEGRATION ════════════════════
local function setXenhubTarget(ownerName, petName)
    pcall(function() getgenv().XenhubTarget = ownerName end)
    pcall(function() getgenv().XenhubPet = petName end)
    pcall(function() getgenv().AutoStealTarget = ownerName end)
    pcall(function() getgenv().TargetPlayer = ownerName end)
    pcall(function() getgenv().TargetPet = petName end)
    pcall(function()
        if getgenv().Xenhub and getgenv().Xenhub.SetTarget then getgenv().Xenhub.SetTarget(ownerName) end
    end)
    pcall(function()
        if getgenv().XenHub and getgenv().XenHub.Target then getgenv().XenHub.Target = ownerName end
    end)
end

-- ════════════════════ UI HELPERS ════════════════════
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c end
local function strokeB(p, col, th) local s = Instance.new("UIStroke"); s.Color = col or T.stroke; s.Thickness = th or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s end
local function pad(p, l, r, t, b) local pd = Instance.new("UIPadding"); pd.PaddingLeft = UDim.new(0,l or 0); pd.PaddingRight = UDim.new(0,r or 0); pd.PaddingTop = UDim.new(0,t or 0); pd.PaddingBottom = UDim.new(0,b or 0); pd.Parent = p; return pd end

local function tween(obj, props, dur)
    TweenService:Create(obj, TweenInfo.new(dur or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function hoverFx(btn, normal, hoverCol)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = hoverCol}) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = normal}) end)
end

local function playAlert()
    if not state.soundAlerts then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://6042053626"
        s.Volume = 0.5
        s.Parent = game:GetService("SoundService")
        s:Play()
        task.delay(2, function() s:Destroy() end)
    end)
end

local function playOGAlert()
    if not state.soundAlerts then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://5018104731"
        s.Volume = 0.85
        s.Parent = game:GetService("SoundService")
        s:Play()
        task.delay(3, function() s:Destroy() end)
    end)
end

-- ════════════════════ SCREEN GUI ════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PhantomAJGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = PG

-- ════════════════════ MAIN FRAME ════════════════════
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.new(0, 680, 0, 580)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = T.bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Active = true
main.Parent = screenGui
corner(main, 12)
strokeB(main, T.stroke, 1)

-- dragging
local dragging, dragStart, startPos
main.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = inp.Position; startPos = main.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ════════════════════ TOP BAR ════════════════════
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = T.bgDark
topBar.BorderSizePixel = 0
topBar.Parent = main
corner(topBar, 12)

-- fix bottom corners of topbar
local topBarMask = Instance.new("Frame")
topBarMask.Size = UDim2.new(1, 0, 0, 14)
topBarMask.Position = UDim2.new(0, 0, 1, -14)
topBarMask.BackgroundColor3 = T.bgDark
topBarMask.BorderSizePixel = 0
topBarMask.ZIndex = 1
topBarMask.Parent = topBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(0, 200, 0, 20)
titleLbl.Position = UDim2.new(0, 14, 0, 7)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "PHANTOMHUB"
titleLbl.TextColor3 = T.accent
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 16
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = topBar

local subtitleLbl = Instance.new("TextLabel")
subtitleLbl.Size = UDim2.new(0, 200, 0, 14)
subtitleLbl.Position = UDim2.new(0, 14, 0, 28)
subtitleLbl.BackgroundTransparency = 1
subtitleLbl.Text = "Auto Joiner  ·  Steal a Brainrot"
subtitleLbl.TextColor3 = T.textDim
subtitleLbl.Font = Enum.Font.GothamMedium
subtitleLbl.TextSize = 10
subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left
subtitleLbl.Parent = topBar

-- top bar pills (right side)
local pillContainer = Instance.new("Frame")
pillContainer.Size = UDim2.new(0, 400, 0, 24)
pillContainer.Position = UDim2.new(1, -410, 0.5, -12)
pillContainer.BackgroundTransparency = 1
pillContainer.Parent = topBar

local pillLayout = Instance.new("UIListLayout")
pillLayout.FillDirection = Enum.FillDirection.Horizontal
pillLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
pillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
pillLayout.Padding = UDim.new(0, 6)
pillLayout.Parent = pillContainer

local function makePill(text, col)
    local pill = Instance.new("Frame")
    pill.AutomaticSize = Enum.AutomaticSize.X
    pill.Size = UDim2.new(0, 0, 0, 22)
    pill.BackgroundColor3 = T.bgPill
    pill.Parent = pillContainer
    corner(pill, 6)
    strokeB(pill, T.stroke)
    pad(pill, 8, 8, 0, 0)
    local lbl = Instance.new("TextLabel")
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.Size = UDim2.new(0, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = col or T.textMid
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.Parent = pill
    return pill, lbl
end

local keyPill, keyPillLbl = makePill("LIFETIME", T.ogGold)
local regionPill = makePill(getRegion(), T.textMid)

-- minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.BackgroundColor3 = T.bgPill
minBtn.Text = "—"
minBtn.TextColor3 = T.textDim
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 12
minBtn.AutoButtonColor = false
minBtn.Parent = pillContainer
corner(minBtn, 6)
hoverFx(minBtn, T.bgPill, T.strokeLit)

-- top separator
local topSep = Instance.new("Frame")
topSep.Size = UDim2.new(1, -20, 0, 1)
topSep.Position = UDim2.new(0, 10, 0, 50)
topSep.BackgroundColor3 = T.stroke
topSep.BorderSizePixel = 0
topSep.Parent = main

-- ════════════════════ STATUS PANEL ════════════════════
local statusPanel = Instance.new("Frame")
statusPanel.Size = UDim2.new(1, -20, 0, 95)
statusPanel.Position = UDim2.new(0, 10, 0, 56)
statusPanel.BackgroundColor3 = T.bgCard
statusPanel.BorderSizePixel = 0
statusPanel.Parent = main
corner(statusPanel, 10)
strokeB(statusPanel, T.stroke)

-- status: scanning indicator
local scanDot = Instance.new("Frame")
scanDot.Size = UDim2.new(0, 8, 0, 8)
scanDot.Position = UDim2.new(0, 12, 0, 14)
scanDot.BackgroundColor3 = T.textDim
scanDot.BorderSizePixel = 0
scanDot.Parent = statusPanel
corner(scanDot, 99)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, -80, 0, 16)
statusLbl.Position = UDim2.new(0, 26, 0, 10)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "IDLE"
statusLbl.TextColor3 = T.textMid
statusLbl.Font = Enum.Font.GothamBold
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = statusPanel

-- scan progress bar
local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, -24, 0, 4)
progressBg.Position = UDim2.new(0, 12, 0, 32)
progressBg.BackgroundColor3 = T.bgPill
progressBg.BorderSizePixel = 0
progressBg.Parent = statusPanel
corner(progressBg, 99)

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = T.accent
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg
corner(progressFill, 99)

-- stat row
local function statLbl(text, xOff, yOff, col)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 120, 0, 14)
    lbl.Position = UDim2.new(0, xOff, 0, yOff)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = col or T.textDim
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = statusPanel
    return lbl
end

local statServers = statLbl("Servers: 0", 12, 44)
local statOGs     = statLbl("OGs Found: 0", 12, 60, T.ogGold)
local statPlayers = statLbl("Players: " .. #Players:GetPlayers() .. "/??", 200, 44)
local statSession = statLbl("Session: 0m", 200, 60)
local statJobId   = statLbl("Job: " .. game.JobId:sub(1, 12) .. "...", 400, 44, T.textDim)
local statRegion  = statLbl("Region: " .. getRegion(), 400, 60, T.textMid)

-- control buttons row
local ctrlRow = Instance.new("Frame")
ctrlRow.Size = UDim2.new(1, -24, 0, 28)
ctrlRow.Position = UDim2.new(0, 12, 0, 78)
ctrlRow.BackgroundTransparency = 1
ctrlRow.Parent = statusPanel

local ctrlLayout = Instance.new("UIListLayout")
ctrlLayout.FillDirection = Enum.FillDirection.Horizontal
ctrlLayout.Padding = UDim.new(0, 6)
ctrlLayout.Parent = ctrlRow

local function makeBtn(text, bgCol, textCol, width)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width or 90, 1, 0)
    btn.BackgroundColor3 = bgCol
    btn.Text = text
    btn.TextColor3 = textCol or T.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = ctrlRow
    corner(btn, 6)
    return btn
end

local hopToggleBtn = makeBtn("START", T.accent, T.bg, 80)
local hopNowBtn    = makeBtn("HOP NOW", T.bgPill, T.hop, 80)

hoverFx(hopNowBtn, T.bgPill, T.hopDim)
strokeB(hopNowBtn, T.stroke)

-- ════════════════════ TAB BAR ════════════════════
local TAB_Y = 158
local TAB_H = 28
local CONTENT_Y = TAB_Y + TAB_H + 4

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, TAB_H)
tabBar.Position = UDim2.new(0, 10, 0, TAB_Y)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local tabBarLayout = Instance.new("UIListLayout")
tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
tabBarLayout.Padding = UDim.new(0, 4)
tabBarLayout.Parent = tabBar

local currentTab = "Main"
local tabBtns = {}
local tabFrames = {}

local function makeTabBtn(name)
    local active = (name == currentTab)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 1, 0)
    btn.BackgroundColor3 = active and T.accent or T.bgPill
    btn.Text = name
    btn.TextColor3 = active and T.bg or T.textMid
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = tabBar
    corner(btn, 6)
    if not active then strokeB(btn, T.stroke) end
    tabBtns[name] = btn
    return btn
end

makeTabBtn("Main")
makeTabBtn("Logs")
makeTabBtn("Settings")

local function switchTab(name)
    currentTab = name
    for tabName, btn in pairs(tabBtns) do
        local active = (tabName == name)
        tween(btn, {BackgroundColor3 = active and T.accent or T.bgPill})
        btn.TextColor3 = active and T.bg or T.textMid
    end
    for tabName, frame in pairs(tabFrames) do
        frame.Visible = (tabName == name)
    end
end

for name, btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ════════════════════ TAB: MAIN (Detection Feed) ════════════════════
local mainTab = Instance.new("Frame")
mainTab.Size = UDim2.new(1, -20, 1, -(CONTENT_Y + 6))
mainTab.Position = UDim2.new(0, 10, 0, CONTENT_Y)
mainTab.BackgroundTransparency = 1
mainTab.Visible = true
mainTab.Parent = main
tabFrames["Main"] = mainTab

local feedHeader = Instance.new("Frame")
feedHeader.Size = UDim2.new(1, 0, 0, 18)
feedHeader.BackgroundTransparency = 1
feedHeader.Parent = mainTab

local function colHeader(text, xOff, width)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, width, 1, 0)
    lbl.Position = UDim2.new(0, xOff, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = T.textDim
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = feedHeader
end

colHeader("BRAINROT", 4, 220)
colHeader("OWNER", 235, 150)
colHeader("RATE", 400, 80)
colHeader("AGE", 500, 60)
colHeader("SERVER", 580, 70)

local feedScroll = Instance.new("ScrollingFrame")
feedScroll.Size = UDim2.new(1, 0, 1, -22)
feedScroll.Position = UDim2.new(0, 0, 0, 20)
feedScroll.BackgroundTransparency = 1
feedScroll.BorderSizePixel = 0
feedScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
feedScroll.ScrollBarThickness = 3
feedScroll.ScrollBarImageColor3 = T.accentDim
feedScroll.Parent = mainTab

local feedLayout = Instance.new("UIListLayout")
feedLayout.Padding = UDim.new(0, 4)
feedLayout.Parent = feedScroll

feedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    feedScroll.CanvasSize = UDim2.new(0, 0, 0, feedLayout.AbsoluteContentSize.Y + 8)
end)

local emptyLbl = Instance.new("TextLabel")
emptyLbl.Size = UDim2.new(1, 0, 0, 40)
emptyLbl.Position = UDim2.new(0, 0, 0.3, 0)
emptyLbl.BackgroundTransparency = 1
emptyLbl.Text = "scanning servers..."
emptyLbl.TextColor3 = T.textDim
emptyLbl.Font = Enum.Font.Gotham
emptyLbl.TextSize = 12
emptyLbl.Parent = feedScroll

-- ════════════════════ TAB: LOGS ════════════════════
local logsTab = Instance.new("Frame")
logsTab.Size = UDim2.new(1, -20, 1, -(CONTENT_Y + 6))
logsTab.Position = UDim2.new(0, 10, 0, CONTENT_Y)
logsTab.BackgroundTransparency = 1
logsTab.Visible = false
logsTab.Parent = main
tabFrames["Logs"] = logsTab

local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1, 0, 1, 0)
logScroll.BackgroundTransparency = 1
logScroll.BorderSizePixel = 0
logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
logScroll.ScrollBarThickness = 3
logScroll.ScrollBarImageColor3 = T.accentDim
logScroll.Parent = logsTab

local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 2)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Parent = logScroll

logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    logScroll.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 8)
end)

local logEntryCount = 0

local function addLog(text, color)
    logEntryCount = logEntryCount + 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = "[" .. os.date("%H:%M:%S") .. "] " .. text
    lbl.TextColor3 = color or T.textMid
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.LayoutOrder = logEntryCount
    lbl.Parent = logScroll
    -- auto-scroll to bottom
    task.defer(function()
        logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)
    end)
end

local logEmptyLbl = Instance.new("TextLabel")
logEmptyLbl.Size = UDim2.new(1, 0, 0, 40)
logEmptyLbl.Position = UDim2.new(0, 0, 0.3, 0)
logEmptyLbl.BackgroundTransparency = 1
logEmptyLbl.Text = "no events yet..."
logEmptyLbl.TextColor3 = T.textDim
logEmptyLbl.Font = Enum.Font.Gotham
logEmptyLbl.TextSize = 12
logEmptyLbl.Parent = logScroll

addLog("PhantomHub Auto Joiner loaded", T.accent)
addLog("Key: " .. USER_KEY:sub(1, 12) .. "...", T.textDim)
addLog("Region: " .. getRegion(), T.textDim)
addLog("Server: " .. game.JobId:sub(1, 16) .. "...", T.textDim)
logEmptyLbl.Visible = false

local function formatAge(sec)
    if sec < 60 then return math.floor(sec) .. "s" end
    if sec < 3600 then return math.floor(sec / 60) .. "m" end
    return math.floor(sec / 3600) .. "h"
end

local feedEntries = {}

local function buildFeedEntry(det)
    local isOg = det.isOG
    local hl = isHighlighted(det.pet)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = T.bgCard
    row.BorderSizePixel = 0
    row.LayoutOrder = -(det.time or os.time())
    row.Parent = feedScroll
    corner(row, 6)
    strokeB(row, isOg and T.ogGold or (hl and T.strokeLit or T.stroke), isOg and 1.5 or 1)

    -- gold accent bar for OGs
    if isOg then
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 0.5, 0)
        bar.Position = UDim2.new(0, 3, 0.25, 0)
        bar.BackgroundColor3 = T.ogGold
        bar.BorderSizePixel = 0
        bar.Parent = row
        corner(bar, 2)
    end

    -- pet name
    local petLbl = Instance.new("TextLabel")
    petLbl.Size = UDim2.new(0, 220, 1, 0)
    petLbl.Position = UDim2.new(0, isOg and 12 or 8, 0, 0)
    petLbl.BackgroundTransparency = 1
    petLbl.Text = det.pet
    petLbl.TextColor3 = isOg and T.ogGold or T.text
    petLbl.Font = isOg and Enum.Font.GothamBold or Enum.Font.GothamMedium
    petLbl.TextSize = 12
    petLbl.TextXAlignment = Enum.TextXAlignment.Left
    petLbl.TextTruncate = Enum.TextTruncate.AtEnd
    petLbl.Parent = row

    -- owner
    local ownerLbl = Instance.new("TextLabel")
    ownerLbl.Size = UDim2.new(0, 150, 1, 0)
    ownerLbl.Position = UDim2.new(0, 235, 0, 0)
    ownerLbl.BackgroundTransparency = 1
    ownerLbl.Text = det.owner
    ownerLbl.TextColor3 = T.textMid
    ownerLbl.Font = Enum.Font.GothamMedium
    ownerLbl.TextSize = 12
    ownerLbl.TextXAlignment = Enum.TextXAlignment.Left
    ownerLbl.TextTruncate = Enum.TextTruncate.AtEnd
    ownerLbl.Parent = row

    -- rate
    local rateLbl = Instance.new("TextLabel")
    rateLbl.Size = UDim2.new(0, 80, 1, 0)
    rateLbl.Position = UDim2.new(0, 400, 0, 0)
    rateLbl.BackgroundTransparency = 1
    rateLbl.Text = det.rate
    rateLbl.TextColor3 = isOg and T.ogGold or T.textDim
    rateLbl.Font = Enum.Font.GothamMedium
    rateLbl.TextSize = 11
    rateLbl.TextXAlignment = Enum.TextXAlignment.Left
    rateLbl.Parent = row

    -- age
    local ageLbl = Instance.new("TextLabel")
    ageLbl.Size = UDim2.new(0, 60, 1, 0)
    ageLbl.Position = UDim2.new(0, 500, 0, 0)
    ageLbl.BackgroundTransparency = 1
    ageLbl.Text = formatAge(os.time() - det.time)
    ageLbl.TextColor3 = T.textDim
    ageLbl.Font = Enum.Font.GothamMedium
    ageLbl.TextSize = 11
    ageLbl.Parent = row

    -- server indicator
    local srvLbl = Instance.new("TextLabel")
    srvLbl.Size = UDim2.new(0, 70, 1, 0)
    srvLbl.Position = UDim2.new(0, 580, 0, 0)
    srvLbl.BackgroundTransparency = 1
    srvLbl.Text = (det.jobId == game.JobId) and "HERE" or det.jobId:sub(1, 6)
    srvLbl.TextColor3 = (det.jobId == game.JobId) and T.success or T.textDim
    srvLbl.Font = Enum.Font.GothamMedium
    srvLbl.TextSize = 9
    srvLbl.Parent = row

    -- hover
    row.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = T.bgPill}) end)
    row.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = T.bgCard}) end)

    -- slide-in
    row.BackgroundTransparency = 1
    petLbl.TextTransparency = 1
    ownerLbl.TextTransparency = 1
    rateLbl.TextTransparency = 1
    ageLbl.TextTransparency = 1
    task.defer(function()
        tween(row, {BackgroundTransparency = 0}, 0.3)
        tween(petLbl, {TextTransparency = 0}, 0.3)
        tween(ownerLbl, {TextTransparency = 0}, 0.3)
        tween(rateLbl, {TextTransparency = 0}, 0.3)
        tween(ageLbl, {TextTransparency = 0}, 0.3)
    end)

    table.insert(feedEntries, {frame = row, ageLbl = ageLbl, det = det})
    if #feedEntries > 0 then emptyLbl.Visible = false end
    return row
end

-- ════════════════════ TAB: SETTINGS ════════════════════
local settingsTab = Instance.new("Frame")
settingsTab.Size = UDim2.new(1, -20, 1, -(CONTENT_Y + 6))
settingsTab.Position = UDim2.new(0, 10, 0, CONTENT_Y)
settingsTab.BackgroundTransparency = 1
settingsTab.Visible = false
settingsTab.Parent = main
tabFrames["Settings"] = settingsTab

local settingsInner = Instance.new("Frame")
settingsInner.Size = UDim2.new(1, 0, 1, 0)
settingsInner.BackgroundColor3 = T.bgCard
settingsInner.BorderSizePixel = 0
settingsInner.Parent = settingsTab
corner(settingsInner, 10)
strokeB(settingsInner, T.stroke)

local function makeToggle(parent, label, yPos, default, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -24, 0, 30)
    row.Position = UDim2.new(0, 12, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = T.text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local toggleBg = Instance.new("TextButton")
    toggleBg.Size = UDim2.new(0, 38, 0, 20)
    toggleBg.Position = UDim2.new(1, -38, 0.5, -10)
    toggleBg.BackgroundColor3 = default and T.accent or T.accentDim
    toggleBg.Text = ""
    toggleBg.AutoButtonColor = false
    toggleBg.Parent = row
    corner(toggleBg, 99)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    circle.BackgroundColor3 = default and T.bg or T.textDim
    circle.BorderSizePixel = 0
    circle.Parent = toggleBg
    corner(circle, 99)

    local isOn = default
    toggleBg.MouseButton1Click:Connect(function()
        isOn = not isOn
        onToggle(isOn)
        tween(toggleBg, {BackgroundColor3 = isOn and T.accent or T.accentDim})
        tween(circle, {
            Position = isOn and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = isOn and T.bg or T.textDim
        })
    end)
end

-- section header
local function settingsSection(text, yPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 0, 16)
    lbl.Position = UDim2.new(0, 12, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = T.accentDim
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = settingsInner
end

settingsSection("ALERTS", 8)
makeToggle(settingsInner, "Sound Alerts", 26, state.soundAlerts, function(v) state.soundAlerts = v end)

settingsSection("JOINING", 62)
makeToggle(settingsInner, "Auto Xenhub Target", 80, state.autoXenhub, function(v) state.autoXenhub = v end)
makeToggle(settingsInner, "Copy Owner Name", 112, state.autoCopyOwner, function(v) state.autoCopyOwner = v end)

settingsSection("UTILITY", 150)
makeToggle(settingsInner, "Anti-AFK", 168, state.antiAfk, function(v) state.antiAfk = v end)

-- scan time
settingsSection("SCAN TIME PER SERVER", 206)

local scanTimeLbl = Instance.new("TextLabel")
scanTimeLbl.Size = UDim2.new(0, 100, 0, 16)
scanTimeLbl.Position = UDim2.new(1, -112, 0, 206)
scanTimeLbl.BackgroundTransparency = 1
scanTimeLbl.Text = state.scanTime .. " seconds"
scanTimeLbl.TextColor3 = T.textMid
scanTimeLbl.Font = Enum.Font.GothamMedium
scanTimeLbl.TextSize = 9
scanTimeLbl.TextXAlignment = Enum.TextXAlignment.Right
scanTimeLbl.Parent = settingsInner

local scanTimeRow = Instance.new("Frame")
scanTimeRow.Size = UDim2.new(1, -24, 0, 26)
scanTimeRow.Position = UDim2.new(0, 12, 0, 224)
scanTimeRow.BackgroundTransparency = 1
scanTimeRow.Parent = settingsInner

local scanTimeLayout = Instance.new("UIListLayout")
scanTimeLayout.FillDirection = Enum.FillDirection.Horizontal
scanTimeLayout.Padding = UDim.new(0, 5)
scanTimeLayout.Parent = scanTimeRow

for _, sec in ipairs({10, 15, 18, 25, 30}) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 1, 0)
    btn.BackgroundColor3 = sec == state.scanTime and T.accent or T.bgPill
    btn.Text = sec .. "s"
    btn.TextColor3 = sec == state.scanTime and T.bg or T.textMid
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = scanTimeRow
    corner(btn, 6)

    btn.MouseButton1Click:Connect(function()
        state.scanTime = sec
        scanTimeLbl.Text = sec .. " seconds"
        for _, c in ipairs(scanTimeRow:GetChildren()) do
            if c:IsA("TextButton") then
                local active = (c.Text == sec .. "s")
                tween(c, {BackgroundColor3 = active and T.accent or T.bgPill})
                c.TextColor3 = active and T.bg or T.textMid
            end
        end
    end)
end

-- ════════════════════ MINIMIZED PILL ════════════════════
local minPill = Instance.new("TextButton")
minPill.Size = UDim2.new(0, 340, 0, 38)
minPill.Position = UDim2.new(0.5, -170, 0, 12)
minPill.BackgroundColor3 = T.bg
minPill.Text = ""
minPill.AutoButtonColor = false
minPill.Visible = false
minPill.Active = true
minPill.Parent = screenGui
corner(minPill, 10)
strokeB(minPill, T.stroke)

local minTitleLbl = Instance.new("TextLabel")
minTitleLbl.Size = UDim2.new(0, 140, 1, 0)
minTitleLbl.Position = UDim2.new(0, 12, 0, 0)
minTitleLbl.BackgroundTransparency = 1
minTitleLbl.Text = "PHANTOMHUB AJ"
minTitleLbl.TextColor3 = T.accent
minTitleLbl.Font = Enum.Font.GothamBold
minTitleLbl.TextSize = 11
minTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
minTitleLbl.Parent = minPill

local minStatusLbl = Instance.new("TextLabel")
minStatusLbl.Size = UDim2.new(0, 80, 1, 0)
minStatusLbl.Position = UDim2.new(0, 155, 0, 0)
minStatusLbl.BackgroundTransparency = 1
minStatusLbl.Text = "IDLE"
minStatusLbl.TextColor3 = T.textDim
minStatusLbl.Font = Enum.Font.GothamMedium
minStatusLbl.TextSize = 10
minStatusLbl.Parent = minPill

local minOGLbl = Instance.new("TextLabel")
minOGLbl.Size = UDim2.new(0, 40, 1, 0)
minOGLbl.Position = UDim2.new(1, -45, 0, 0)
minOGLbl.BackgroundTransparency = 1
minOGLbl.Text = "0"
minOGLbl.TextColor3 = T.ogGold
minOGLbl.Font = Enum.Font.GothamBold
minOGLbl.TextSize = 13
minOGLbl.Parent = minPill

-- pill dragging
local pillDrag, pillDragStart, pillStartPos
minPill.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        pillDrag = true; pillDragStart = inp.Position; pillStartPos = minPill.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then pillDrag = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if pillDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - pillDragStart
        minPill.Position = UDim2.new(pillStartPos.X.Scale, pillStartPos.X.Offset + delta.X, pillStartPos.Y.Scale, pillStartPos.Y.Offset + delta.Y)
    end
end)

-- minimize/restore
local minimized = false

local function minimizeUI()
    if minimized then return end
    minimized = true
    local tw = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    TweenService:Create(main, tw, {
        Size = UDim2.new(0, 0, 0, 0),
    }):Play()
    task.wait(0.3)
    main.Visible = false
    main.Size = UDim2.new(0, 680, 0, 580)
    minPill.Visible = true
    minPill.Size = UDim2.new(0, 0, 0, 36)
    TweenService:Create(minPill, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 38)
    }):Play()
end

local function restoreUI()
    if not minimized then return end
    minimized = false
    TweenService:Create(minPill, TwnFast, {Size = UDim2.new(0, 0, 0, 36)}):Play()
    task.wait(0.15)
    minPill.Visible = false
    minPill.Size = UDim2.new(0, 340, 0, 38)
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Visible = true
    TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 680, 0, 580),
    }):Play()
end

minBtn.MouseButton1Click:Connect(minimizeUI)
minPill.MouseButton1Click:Connect(restoreUI)

-- ════════════════════ BRAINROT SCANNER ════════════════════
-- scans the current server for OG brainrots using multiple detection methods

local function getBrainrotName(obj)
    local name = nil
    pcall(function()
        local bd = obj:FindFirstChild("BrainrotData")
        if bd then
            if bd:IsA("StringValue") then name = bd.Value
            elseif bd:IsA("ObjectValue") and bd.Value then name = bd.Value.Name end
        end
    end)
    if not name then
        pcall(function()
            local bn = obj:FindFirstChild("BrainrotName")
            if bn and bn:IsA("StringValue") then name = bn.Value end
        end)
    end
    if not name then
        pcall(function()
            local nameTag = obj:FindFirstChild("NameTag") or obj:FindFirstChild("Name")
            if nameTag then
                if nameTag:IsA("StringValue") then name = nameTag.Value
                elseif nameTag:IsA("BillboardGui") then
                    local tl = nameTag:FindFirstChildWhichIsA("TextLabel", true)
                    if tl then name = tl.Text end
                end
            end
        end)
    end
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
            elseif o:IsA("IntValue") then
                local p = Players:GetPlayerByUserId(o.Value)
                if p then owner = p.Name end
            end
        end
    end)
    if not owner then
        pcall(function()
            local parent = obj.Parent
            while parent and parent ~= workspace do
                local plr = Players:FindFirstChild(parent.Name)
                if plr then owner = parent.Name; break end
                local o2 = parent:FindFirstChild("Owner") or parent:FindFirstChild("PlotOwner")
                if o2 then
                    if o2:IsA("ObjectValue") and o2.Value then owner = o2.Value.Name; break
                    elseif o2:IsA("StringValue") then owner = o2.Value; break end
                end
                parent = parent.Parent
            end
        end)
    end
    return owner
end

local foundOGs = {} -- {ownerName = {pet, rate, time}}

local function scanCurrentServer()
    local found = {}

    -- Method 1: scan workspace descendants for brainrot models
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            pcall(function()
                if not obj:IsA("Model") then return end
                local isBrainrot = false
                if obj:FindFirstChild("BrainrotData") or obj:FindFirstChild("BrainrotName") then
                    isBrainrot = true
                elseif obj:FindFirstChild("Humanoid") and (obj:FindFirstChild("Owner") or obj:FindFirstChild("PlotOwner")) then
                    isBrainrot = true
                elseif obj.Name:lower():find("brainrot") then
                    isBrainrot = true
                end
                if isBrainrot then
                    local bName = getBrainrotName(obj)
                    local oName = getOwnerName(obj)
                    if bName and isOG(bName) then
                        local info = getOGInfo(bName)
                        local key = (oName or "???") .. "_" .. bName
                        if not found[key] then
                            found[key] = {
                                pet = info and info.name or bName,
                                owner = oName or "???",
                                rate = info and info.rate or "?",
                            }
                        end
                    end
                end
            end)
        end
    end)

    -- Method 2: scan player backpacks and characters
    pcall(function()
        for _, plr in pairs(Players:GetPlayers()) do
            pcall(function()
                for _, item in pairs(plr.Backpack:GetChildren()) do
                    pcall(function()
                        if isOG(item.Name) then
                            local info = getOGInfo(item.Name)
                            local key = plr.Name .. "_" .. item.Name
                            if not found[key] then
                                found[key] = {
                                    pet = info and info.name or item.Name,
                                    owner = plr.Name,
                                    rate = info and info.rate or "?",
                                }
                            end
                        end
                    end)
                end
                if plr.Character then
                    for _, item in pairs(plr.Character:GetChildren()) do
                        pcall(function()
                            if item:IsA("Tool") and isOG(item.Name) then
                                local info = getOGInfo(item.Name)
                                local key = plr.Name .. "_" .. item.Name
                                if not found[key] then
                                    found[key] = {
                                        pet = info and info.name or item.Name,
                                        owner = plr.Name,
                                        rate = info and info.rate or "?",
                                    }
                                end
                            end
                        end)
                    end
                end
            end)
        end
    end)

    -- Method 3: scan BillboardGuis for brainrot name displays
    pcall(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("BillboardGui") then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("TextLabel") then
                            local txt = child.Text
                            if txt and isOG(txt) then
                                local info = getOGInfo(txt)
                                local oName = nil
                                local p = obj.Parent
                                while p and p ~= workspace do
                                    if Players:FindFirstChild(p.Name) then oName = p.Name; break end
                                    local ov = p:FindFirstChild("Owner") or p:FindFirstChild("PlotOwner")
                                    if ov then
                                        if ov:IsA("ObjectValue") and ov.Value then oName = ov.Value.Name; break
                                        elseif ov:IsA("StringValue") then oName = ov.Value; break end
                                    end
                                    p = p.Parent
                                end
                                local key = (oName or "???") .. "_" .. txt
                                if not found[key] then
                                    found[key] = {
                                        pet = info and info.name or txt,
                                        owner = oName or "???",
                                        rate = info and info.rate or "?",
                                    }
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)

    -- Method 4: scan TextLabels in common UI containers
    pcall(function()
        for _, gui in pairs(PG:GetChildren()) do
            if gui.Name ~= "PhantomAJGui" then
                pcall(function()
                    for _, lbl in pairs(gui:GetDescendants()) do
                        if lbl:IsA("TextLabel") and lbl.Text then
                            local txt = lbl.Text
                            if isOG(txt) and not txt:lower():find("phantomhub") then
                                local info = getOGInfo(txt)
                                local key = "ui_" .. txt
                                if not found[key] then
                                    found[key] = {
                                        pet = info and info.name or txt,
                                        owner = "???",
                                        rate = info and info.rate or "?",
                                    }
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    return found
end

-- ════════════════════ SERVER LIST + HOP ════════════════════
local serverQueue = {}
local serverCursor = ""

local function fetchServers()
    local servers = {}
    pcall(function()
        local reqFn = request or (syn and syn.request) or (fluxus and fluxus.request)
            or http_request or (typeof(http) == "table" and http.request)
        if not reqFn then return end

        local url = "https://games.roblox.com/v1/games/" .. PLACE_ID
            .. "/servers/0?sortOrder=2&excludeFullGames=" .. tostring(CONFIG.EXCLUDE_FULL)
            .. "&limit=" .. CONFIG.MAX_SERVERS
        if serverCursor ~= "" then url = url .. "&cursor=" .. serverCursor end

        local resp = reqFn({
            Url = url, Method = "GET",
            Headers = {["Content-Type"] = "application/json"}
        })
        local body = resp.Body or resp.body
        local data = HttpService:JSONDecode(body)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.id and s.id ~= game.JobId and s.playing >= CONFIG.MIN_PLAYERS then
                    table.insert(servers, {
                        jobId = s.id,
                        players = s.playing,
                        maxPlayers = s.maxPlayers,
                        fps = s.fps,
                        ping = s.ping,
                    })
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

-- ════════════════════ UI UPDATE LOOP ════════════════════
local function updateStatusUI(text, dotColor)
    statusLbl.Text = text
    scanDot.BackgroundColor3 = dotColor or T.textDim
    minStatusLbl.Text = text:sub(1, 20)
end

local function updateStats()
    statServers.Text = "Servers: " .. state.serversChecked
    statOGs.Text = "OGs Found: " .. state.ogsFound
    statPlayers.Text = "Players: " .. #Players:GetPlayers() .. "/" .. (Players.MaxPlayers or "??")
    local mins = math.floor((os.time() - state.sessionStart) / 60)
    statSession.Text = "Session: " .. mins .. "m"
    minOGLbl.Text = tostring(state.ogsFound)
    -- keyPillLbl updated by loader if needed

    -- update feed ages
    for _, e in ipairs(feedEntries) do
        if e.ageLbl and e.ageLbl.Parent and e.det then
            e.ageLbl.Text = formatAge(os.time() - e.det.time)
        end
    end
end

-- ════════════════════ MAIN AUTO-JOIN LOOP ════════════════════
local function autoJoinLoop()
    state.scanning = true
    state.serversChecked = state.serversChecked + 1
    updateStatusUI("SCANNING", T.success)
    addLog("Scanning server #" .. state.serversChecked .. " (" .. game.JobId:sub(1,8) .. ")", T.textMid)

    -- animate progress bar
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    TweenService:Create(progressFill, TweenInfo.new(state.scanTime, Enum.EasingStyle.Linear), {
        Size = UDim2.new(1, 0, 1, 0)
    }):Play()

    state.scanStart = os.time()

    -- scan multiple times during the scan window
    local scanInterval = 3 -- scan every 3 seconds
    local scansRemaining = math.floor(state.scanTime / scanInterval)
    local ogFoundThisServer = false

    for i = 1, scansRemaining do
        if not state.running or not state.hopping then break end
        if ogFoundThisServer then break end

        local found = scanCurrentServer()

        for key, data in pairs(found) do
            if not foundOGs[key] then
                foundOGs[key] = data
                state.ogsFound = state.ogsFound + 1

                addDetection(data.pet, data.owner, data.rate, game.JobId)
                buildFeedEntry(detections[1])

                if isOG(data.pet) then
                    playOGAlert()
                    ogFoundThisServer = true
                    addLog("OG DETECTED: " .. data.pet .. " (owner: " .. data.owner .. ")", T.ogGold)

                    updateStatusUI("OG FOUND: " .. data.pet, T.ogGold)
                    tween(scanDot, {BackgroundColor3 = T.ogGold})
                    tween(progressFill, {BackgroundColor3 = T.ogGold})

                    -- auto xenhub target
                    if state.autoXenhub then
                        setXenhubTarget(data.owner, data.pet)
                    end
                    if state.autoCopyOwner then
                        pcall(function() setclipboard(data.owner) end)
                    end
                else
                    playAlert()
                    addLog("Highlighted pet: " .. data.pet .. " (owner: " .. data.owner .. ")", T.success)
                end
            end
        end

        task.wait(scanInterval)
    end

    state.scanning = false
    addLog("Scan complete — " .. (ogFoundThisServer and "OG found!" or "no OGs"), ogFoundThisServer and T.ogGold or T.textDim)

    -- if OG found, stop hopping and stay
    if ogFoundThisServer then
        state.hopping = false
        hopToggleBtn.Text = "START"
        hopToggleBtn.BackgroundColor3 = T.accent
        hopToggleBtn.TextColor3 = T.bg
        updateStatusUI("STAYING — OG FOUND", T.ogGold)
        progressFill.BackgroundColor3 = T.ogGold
        return false -- don't hop
    end

    return true -- should hop
end

-- main hop controller
local hopThread = nil

local function startHopping()
    if hopThread then return end
    state.hopping = true
    hopToggleBtn.Text = "STOP"
    hopToggleBtn.BackgroundColor3 = T.danger
    hopToggleBtn.TextColor3 = T.text
    addLog("Auto-hop started", T.accent)

    hopThread = task.spawn(function()
        while state.running and state.hopping do
            -- scan current server first
            local shouldHop = autoJoinLoop()

            if not shouldHop or not state.hopping then break end

            -- prepare to hop
            updateStatusUI("HOPPING...", T.hop)
            tween(progressFill, {BackgroundColor3 = T.hop})
            task.wait(CONFIG.HOP_DELAY)

            if not state.hopping or not state.running then break end

            -- fetch new servers if queue empty
            if #serverQueue == 0 then
                updateStatusUI("FETCHING SERVERS...", T.hop)
                serverQueue = fetchServers()
                addLog("Fetched " .. #serverQueue .. " servers", T.textMid)
            end

            -- hop to next server
            if #serverQueue > 0 then
                local next = table.remove(serverQueue, 1)
                addLog("Hopping to " .. next.jobId:sub(1,8) .. " (" .. next.players .. " players)", T.hop)
                updateStatusUI("JOINING " .. next.jobId:sub(1, 8) .. "...", T.hop)
                hopToServer(next.jobId)
                task.wait(10) -- wait for teleport
            else
                -- fallback: random hop
                addLog("No queued servers — random hop", T.hop)
                updateStatusUI("RANDOM HOP...", T.hop)
                hopRandom()
                task.wait(10)
            end
        end

        hopThread = nil
        if not state.hopping then
            updateStatusUI("IDLE", T.textDim)
            progressFill.Size = UDim2.new(0, 0, 1, 0)
            progressFill.BackgroundColor3 = T.accent
        end
    end)
end

local function stopHopping()
    state.hopping = false
    hopToggleBtn.Text = "START"
    hopToggleBtn.BackgroundColor3 = T.accent
    hopToggleBtn.TextColor3 = T.bg
    addLog("Auto-hop stopped", T.danger)
end

-- button handlers
hopToggleBtn.MouseButton1Click:Connect(function()
    if state.hopping then
        stopHopping()
    else
        startHopping()
    end
end)

hopNowBtn.MouseButton1Click:Connect(function()
    hopNowBtn.Text = "HOPPING..."
    hopNowBtn.TextColor3 = T.text
    task.spawn(function()
        if #serverQueue == 0 then serverQueue = fetchServers() end
        if #serverQueue > 0 then
            local next = table.remove(serverQueue, 1)
            state.serversChecked = state.serversChecked + 1
            hopToServer(next.jobId)
        else
            hopRandom()
        end
    end)
    task.delay(3, function()
        hopNowBtn.Text = "HOP NOW"
        hopNowBtn.TextColor3 = T.hop
    end)
end)

-- ════════════════════ ANTI-AFK ════════════════════
task.spawn(function()
    local VU = game:GetService("VirtualUser")
    LP.Idled:Connect(function()
        if state.antiAfk then
            pcall(function() VU:CaptureController() end)
            pcall(function() VU:ClickButton2(Vector2.new(0, 0)) end)
        end
    end)
    while state.running do
        if state.antiAfk then
            pcall(function()
                VU:CaptureController()
                VU:ClickButton2(Vector2.new(0, 0))
            end)
        end
        task.wait(240)
    end
end)

-- ════════════════════ TELEPORT FAILED HANDLER ════════════════════
TeleportService.TeleportInitFailed:Connect(function(_, result, errMsg)
    addLog("Teleport failed: " .. tostring(errMsg), T.danger)
    updateStatusUI("TELEPORT FAILED", T.danger)
    task.wait(3)
    if state.hopping then
        -- retry with next server
        if #serverQueue > 0 then
            local next = table.remove(serverQueue, 1)
            updateStatusUI("RETRYING...", T.hop)
            hopToServer(next.jobId)
        else
            updateStatusUI("FETCHING SERVERS...", T.hop)
            serverQueue = fetchServers()
            if #serverQueue > 0 then
                local next = table.remove(serverQueue, 1)
                hopToServer(next.jobId)
            end
        end
    end
end)

-- ════════════════════ PERIODIC UPDATES ════════════════════
task.spawn(function()
    while state.running do
        updateStats()
        task.wait(1)
    end
end)

-- ════════════════════ INITIAL SCAN + AUTO-START ════════════════════
task.spawn(function()
    task.wait(2)

    -- do an initial scan of the server we landed in
    addLog("Running initial scan...", T.textMid)
    updateStatusUI("INITIAL SCAN...", T.success)
    local found = scanCurrentServer()
    local ogHere = false

    for key, data in pairs(found) do
        if not foundOGs[key] then
            foundOGs[key] = data
            state.ogsFound = state.ogsFound + 1
            addDetection(data.pet, data.owner, data.rate, game.JobId)
            buildFeedEntry(detections[1])
            if isOG(data.pet) then
                playOGAlert()
                ogHere = true
                if state.autoXenhub then setXenhubTarget(data.owner, data.pet) end
                if state.autoCopyOwner then pcall(function() setclipboard(data.owner) end) end
            else
                playAlert()
            end
        end
    end

    if ogHere then
        addLog("OG found in current server!", T.ogGold)
        updateStatusUI("OG IN SERVER!", T.ogGold)
        tween(scanDot, {BackgroundColor3 = T.ogGold})
    else
        addLog("Initial scan clean — no OGs here", T.textDim)
        updateStatusUI("IDLE", T.textDim)
    end

    -- auto-start if came from a hop (persistence)
    if getgenv().aj_auto_hop and not ogHere then
        task.wait(1)
        startHopping()
    end
end)

-- ════════════════════ LOADING ANIMATION ════════════════════
do
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = T.bg
    overlay.ZIndex = 100
    overlay.Parent = main
    corner(overlay, 12)

    local loadTitle = Instance.new("TextLabel")
    loadTitle.Size = UDim2.new(1, 0, 0, 24)
    loadTitle.Position = UDim2.new(0, 0, 0.35, 0)
    loadTitle.BackgroundTransparency = 1
    loadTitle.Text = "PHANTOMHUB"
    loadTitle.TextColor3 = T.accent
    loadTitle.Font = Enum.Font.GothamBlack
    loadTitle.TextSize = 18
    loadTitle.ZIndex = 101
    loadTitle.Parent = overlay

    local loadSub = Instance.new("TextLabel")
    loadSub.Size = UDim2.new(1, 0, 0, 16)
    loadSub.Position = UDim2.new(0, 0, 0.35, 28)
    loadSub.BackgroundTransparency = 1
    loadSub.Text = "Auto Joiner"
    loadSub.TextColor3 = T.textDim
    loadSub.Font = Enum.Font.GothamMedium
    loadSub.TextSize = 12
    loadSub.ZIndex = 101
    loadSub.Parent = overlay

    local loadBar = Instance.new("Frame")
    loadBar.Size = UDim2.new(0, 200, 0, 3)
    loadBar.Position = UDim2.new(0.5, -100, 0.35, 56)
    loadBar.BackgroundColor3 = T.bgPill
    loadBar.ZIndex = 101
    loadBar.Parent = overlay
    corner(loadBar, 99)

    local loadFill = Instance.new("Frame")
    loadFill.Size = UDim2.new(0, 0, 1, 0)
    loadFill.BackgroundColor3 = T.accent
    loadFill.ZIndex = 102
    loadFill.Parent = loadBar
    corner(loadFill, 99)

    task.spawn(function()
        local ft = TweenService:Create(loadFill, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 1, 0)
        })
        ft:Play(); ft.Completed:Wait()
        task.wait(0.2)
        local fade = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(overlay, fade, {BackgroundTransparency = 1}):Play()
        TweenService:Create(loadTitle, fade, {TextTransparency = 1}):Play()
        TweenService:Create(loadSub, fade, {TextTransparency = 1}):Play()
        TweenService:Create(loadBar, fade, {BackgroundTransparency = 1}):Play()
        TweenService:Create(loadFill, fade, {BackgroundTransparency = 1}):Play()
        task.wait(0.3)
        overlay:Destroy()
    end)
end

end) -- end main pcall

if not ok then
    warn("[PhantomHub AJ] Error: " .. tostring(err))
end
-- PhantomHub Auto Joiner v1.0

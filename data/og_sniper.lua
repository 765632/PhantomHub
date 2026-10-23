-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  PHANTOMHUB OG SNIPER — real-time OG brainrot tracker          ║
-- ║  Steal a Brainrot — detect, track, and fleece OG claims        ║
-- ╚══════════════════════════════════════════════════════════════════╝

print("[OG SNIPER] Starting...")

local ok, err = pcall(function()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RS = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera
local PLACE_ID = game.PlaceId

-- ════════════════════ CLEANUP OLD GUI ════════════════════
for _, g in ipairs(PG:GetChildren()) do
    if g.Name == "OGSniperGui" then g:Destroy() end
end

-- ════════════════════ THEME (matches PhantomHub) ════════════════════
local Theme = {
    bg       = Color3.fromRGB(10, 10, 10),
    bgDark   = Color3.fromRGB(5, 5, 5),
    bgCard   = Color3.fromRGB(18, 18, 18),
    stroke   = Color3.fromRGB(40, 40, 40),
    accent   = Color3.fromRGB(255, 255, 255),
    accentHover = Color3.fromRGB(220, 220, 220),
    accentDim = Color3.fromRGB(60, 60, 60),
    text     = Color3.fromRGB(245, 245, 245),
    textMuted = Color3.fromRGB(140, 140, 140),
    white    = Color3.fromRGB(255, 255, 255),
    toggleOff = Color3.fromRGB(35, 35, 35),
    toggleOn = Color3.fromRGB(255, 255, 255),
    ogGold   = Color3.fromRGB(255, 190, 60),
    danger   = Color3.fromRGB(255, 70, 70),
    success  = Color3.fromRGB(80, 255, 120),
}

local TweenFast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenMed  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ════════════════════ STATE ════════════════════
local state = {
    currentTab   = "Live",
    minimized    = false,
    locked       = false,
    running      = true,
    ogCaught     = 0,
    totalScanned = 0,
    globalEvents = 0,
    autoFleece   = false,
    autoTrack    = true,
    soundAlerts  = true,
    serverHop    = false,
}

local trackedUsers = {}   -- {username = {brainrot, time, og, source, count}}
local ogLog = {}          -- {timestamp, playerName, brainrotName, isOG}
local liveLog = {}        -- all spawn events
local fleeceQueue = {}    -- players to auto-trade
local knownBrainrots = {} -- already-seen brainrot instances (avoid dupes)
local knownGlobalTexts = {} -- dedup global feed entries
local conns = {}          -- connections for cleanup

-- ════════════════════ OG BRAINROT LIST (SAB) ════════════════════
-- the actual OG brainrots in Steal a Brainrot + their earn rates

local OG_BRAINROTS = {
    {name = "Skibidi Toilet",       rate = "$450M/s"},
    {name = "John Pork",            rate = "$500M/s"},
    {name = "Headless Horseman",    rate = "$600M/s"},
    {name = "Meowl",                rate = "$600M/s"},
    {name = "Strawberry Elephant",  rate = "$750M/s"},
}

-- flat lookup for fast matching
local OG_LIST = {}
local OG_KEYWORDS = {}
for _, og in ipairs(OG_BRAINROTS) do
    OG_LIST[og.name:lower()] = og
    -- add partial keywords for each word in the name
    for word in og.name:lower():gmatch("%S+") do
        if word ~= "the" and word ~= "a" and #word > 2 then
            OG_KEYWORDS[word] = og.name
        end
    end
end

local function isOG(name)
    if not name then return false end
    local lower = name:lower()
    if OG_LIST[lower] then return true end
    -- check partial matches
    for keyword, _ in pairs(OG_KEYWORDS) do
        if lower:find(keyword, 1, true) then return true end
    end
    return false
end

local function getOGInfo(name)
    if not name then return nil end
    local lower = name:lower()
    if OG_LIST[lower] then return OG_LIST[lower] end
    for keyword, ogName in pairs(OG_KEYWORDS) do
        if lower:find(keyword, 1, true) then return OG_LIST[ogName:lower()] end
    end
    return nil
end

-- ════════════════════ GLOBAL OG DATABASE ════════════════════
-- stores ALL detected OG players from any source (local + global)
local globalOGDB = {} -- {playerName = {brainrots = {name = ogInfo}, source, lastSeen, inServer}}

local function addToGlobalOGDB(playerName, brainrotName, source)
    if not globalOGDB[playerName] then
        globalOGDB[playerName] = {
            brainrots = {},
            source = source or "LOCAL",
            lastSeen = os.time(),
            inServer = (source == "LOCAL"),
        }
    end
    local entry = globalOGDB[playerName]
    entry.lastSeen = os.time()
    if source == "LOCAL" then entry.inServer = true end
    if not entry.brainrots[brainrotName] then
        entry.brainrots[brainrotName] = getOGInfo(brainrotName) or {name = brainrotName, rate = "?"}
    end
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
    remotes.stealGrab    = findRE("StealService/Grab")
    remotes.worldGrab    = findRE("WorldBrainrotService/Grab")
    remotes.notify       = findRE("NotificationService/Notify")
    remotes.tradeAccept  = findRE("TradeService/Accept")
    remotes.tradeInvite  = findRE("TradeService/InviteResult")
    remotes.tradeSearch  = findRF("TradeService/SearchUser")
    remotes.tradeAdd     = findRF("TradeService/AddItem")
    remotes.tradeRemove  = findRF("TradeService/RemoveItem")
    remotes.tradeAcceptInv = findRF("TradeService/AcceptInvite")
    -- trade send/invite remotes
    remotes.tradeSend    = findRE("TradeService/Send") or findRE("TradeService/Invite") or findRE("TradeService/Request")
    remotes.tradeSendRF  = findRF("TradeService/Send") or findRF("TradeService/Invite") or findRF("TradeService/Request")
    remotes.plotSell     = findRE("PlotService/Sell")
    -- duel remotes
    remotes.duelSend     = findRE("DuelService/Send") or findRE("DuelService/Request") or findRE("DuelService/Invite") or findRE("BattleService/Send") or findRE("BattleService/Request") or findRE("BattleService/Invite")
    remotes.duelSendRF   = findRF("DuelService/Send") or findRF("DuelService/Request") or findRF("DuelService/Invite") or findRF("BattleService/Send") or findRF("BattleService/Request") or findRF("BattleService/Invite")
    remotes.duelAccept   = findRE("DuelService/Accept") or findRE("BattleService/Accept")
end)

-- also brute-force search ALL remotes for duel/battle keywords
pcall(function()
    for _, d in pairs(RS:GetDescendants()) do
        pcall(function()
            local n = d.Name:lower()
            if (n:find("duel") or n:find("battle") or n:find("fight") or n:find("pvp")) then
                if d:IsA("RemoteEvent") and not remotes.duelSend then
                    remotes.duelSend = d
                elseif d:IsA("RemoteFunction") and not remotes.duelSendRF then
                    remotes.duelSendRF = d
                end
            end
        end)
    end
end)

-- ════════════════════ UI HELPERS ════════════════════
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.stroke
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function pad(parent, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = parent
    return p
end

local function hoverFx(btn, normal, hoverCol)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenFast, { BackgroundColor3 = hoverCol }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenFast, { BackgroundColor3 = normal }):Play()
    end)
end

local function makeLabel(parent, props)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Font = props.font or Enum.Font.Gotham
    lbl.TextSize = props.size or 12
    lbl.TextColor3 = props.color or Theme.text
    lbl.TextXAlignment = props.align or Enum.TextXAlignment.Left
    lbl.Text = props.text or ""
    lbl.Size = props.sz or UDim2.new(1, 0, 0, 20)
    lbl.Position = props.pos or UDim2.new(0, 0, 0, 0)
    lbl.TextWrapped = true
    lbl.ZIndex = props.z or 3
    lbl.Parent = parent
    return lbl
end

-- ════════════════════ SCREEN GUI ════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OGSniperGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = PG

-- platform detection
local _isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local _screenSize = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
local _isPhone = _isMobile and (_screenSize.X < 800 or _screenSize.Y < 500)

-- ════════════════════ MAIN FRAME ════════════════════
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.new(0, 360, 0, 520)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = Theme.bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Active = true
main.Parent = screenGui
corner(main, 14)
stroke(main, Theme.stroke, 1.5)

if _isMobile then
    local sc = Instance.new("UIScale")
    sc.Scale = _isPhone and 0.72 or 0.88
    sc.Parent = main
end

-- ════════════════════ DRAG ════════════════════
local dragging, dragInput, dragStart, startPos
main.InputBegan:Connect(function(input)
    if state.locked then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ════════════════════ TITLE BAR ════════════════════
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 46)
titleBar.BackgroundColor3 = Theme.bgDark
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 2
titleBar.Parent = main
corner(titleBar, 14)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 14)
titleFix.Position = UDim2.new(0, 0, 1, -14)
titleFix.BackgroundColor3 = Theme.bgDark
titleFix.BackgroundTransparency = 0.3
titleFix.BorderSizePixel = 0
titleFix.ZIndex = 2
titleFix.Parent = titleBar

-- logo circle
local logoBg = Instance.new("Frame")
logoBg.Size = UDim2.new(0, 30, 0, 30)
logoBg.Position = UDim2.new(0, 10, 0.5, -15)
logoBg.BackgroundColor3 = Theme.white
logoBg.ZIndex = 3
logoBg.Parent = titleBar
corner(logoBg, 8)

local logoText = Instance.new("TextLabel")
logoText.Size = UDim2.new(1, 0, 1, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "P"
logoText.Font = Enum.Font.GothamBlack
logoText.TextSize = 18
logoText.TextColor3 = Theme.bg
logoText.ZIndex = 4
logoText.Parent = logoBg

-- title + subtitle
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 180, 0, 18)
titleLabel.Position = UDim2.new(0, 48, 0, 6)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 14
titleLabel.TextColor3 = Theme.text
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "PHANTOMHUB OG SNIPER"
titleLabel.ZIndex = 3
titleLabel.Parent = titleBar

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(0, 160, 0, 14)
subLabel.Position = UDim2.new(0, 48, 0, 24)
subLabel.BackgroundTransparency = 1
subLabel.Font = Enum.Font.Gotham
subLabel.TextSize = 10
subLabel.TextColor3 = Theme.textMuted
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.Text = "real time og tracker"
subLabel.ZIndex = 3
subLabel.Parent = titleBar

-- caught counter badge
local caughtBadge = Instance.new("Frame")
caughtBadge.Size = UDim2.new(0, 80, 0, 26)
caughtBadge.Position = UDim2.new(1, -140, 0.5, -13)
caughtBadge.BackgroundColor3 = Theme.bgCard
caughtBadge.ZIndex = 3
caughtBadge.Parent = titleBar
corner(caughtBadge, 8)
stroke(caughtBadge, Theme.stroke, 1)

local caughtLabel = Instance.new("TextLabel")
caughtLabel.Size = UDim2.new(1, 0, 1, 0)
caughtLabel.BackgroundTransparency = 1
caughtLabel.Font = Enum.Font.GothamBold
caughtLabel.TextSize = 11
caughtLabel.TextColor3 = Theme.ogGold
caughtLabel.Text = "0 caught"
caughtLabel.ZIndex = 4
caughtLabel.Parent = caughtBadge

-- control buttons
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -56, 0.5, -12)
minBtn.BackgroundColor3 = Theme.bgCard
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.TextColor3 = Theme.text
minBtn.Text = "-"
minBtn.AutoButtonColor = false
minBtn.ZIndex = 3
minBtn.Parent = titleBar
corner(minBtn, 6)
hoverFx(minBtn, Theme.bgCard, Theme.accentDim)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0.5, -12)
closeBtn.BackgroundColor3 = Theme.bgCard
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.TextColor3 = Theme.text
closeBtn.Text = "X"
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 3
closeBtn.Parent = titleBar
corner(closeBtn, 6)
hoverFx(closeBtn, Theme.bgCard, Color3.fromRGB(180, 50, 70))

-- minimize
minBtn.MouseButton1Click:Connect(function()
    state.minimized = not state.minimized
    local targetSize = state.minimized and UDim2.new(0, 360, 0, 46) or UDim2.new(0, 360, 0, 520)
    TweenService:Create(main, TweenMed, { Size = targetSize }):Play()
    minBtn.Text = state.minimized and "+" or "-"
end)

-- close
closeBtn.MouseButton1Click:Connect(function()
    state.running = false
    for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
    screenGui:Destroy()
end)

-- ════════════════════ TAB BAR ════════════════════
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, 34)
tabBar.Position = UDim2.new(0, 12, 0, 54)
tabBar.BackgroundColor3 = Theme.bgDark
tabBar.BackgroundTransparency = 0.2
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 2
tabBar.Parent = main
corner(tabBar, 8)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Padding = UDim.new(0, 3)
tabLayout.Parent = tabBar
pad(tabBar, 4, 4, 4, 4)

local tabs = {}
local pages = {}
local TAB_NAMES = {"Live", "OG", "Track", "Fleece", "Settings"}

local function makeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 58, 1, 0)
    btn.BackgroundColor3 = Theme.bgDark
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Theme.textMuted
    btn.Text = name:upper()
    btn.AutoButtonColor = false
    btn.ZIndex = 3
    btn.Parent = tabBar
    corner(btn, 6)
    tabs[name] = btn
    return btn
end

for _, name in ipairs(TAB_NAMES) do
    makeTab(name)
end

local function setTab(name)
    state.currentTab = name
    for n, btn in pairs(tabs) do
        if n == name then
            TweenService:Create(btn, TweenFast, { BackgroundColor3 = Theme.accent, TextColor3 = Theme.bg }):Play()
        else
            TweenService:Create(btn, TweenFast, { BackgroundColor3 = Theme.bgDark, TextColor3 = Theme.textMuted }):Play()
        end
    end
    for n, page in pairs(pages) do
        page.Visible = (n == name)
    end
end

for _, name in ipairs(TAB_NAMES) do
    tabs[name].MouseButton1Click:Connect(function() setTab(name) end)
end

-- ════════════════════ CONTENT AREA ════════════════════
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 1, -100)
content.Position = UDim2.new(0, 12, 0, 96)
content.BackgroundTransparency = 1
content.ZIndex = 2
content.ClipsDescendants = true
content.Parent = main

-- ════════════════════ HELPER: Scrolling Feed ════════════════════
local function makeScrollFeed(parent)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Theme.accentDim
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.BorderSizePixel = 0
    scroll.ZIndex = 3
    scroll.Parent = parent

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 4)
    list.Parent = scroll
    pad(scroll, 0, 4, 0, 0)

    return scroll, list
end

local function addLogEntry(scroll, text, color, isOGEntry)
    -- simple text log (used for system messages)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -8, 0, 24)
    entry.BackgroundColor3 = isOGEntry and Color3.fromRGB(30, 25, 10) or Theme.bgCard
    entry.BorderSizePixel = 0
    entry.ZIndex = 3
    entry.LayoutOrder = -os.clock() * 1000
    entry.Parent = scroll
    corner(entry, 6)
    if isOGEntry then stroke(entry, Theme.ogGold, 1) end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 1, 0)
    lbl.Position = UDim2.new(0, 6, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextColor3 = color or Theme.textMuted
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = text
    lbl.ZIndex = 4
    lbl.TextTransparency = 1
    lbl.Parent = entry

    entry.BackgroundTransparency = 1
    local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(entry, fadeInfo, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(lbl, fadeInfo, { TextTransparency = 0 }):Play()
    if isOGEntry then
        local s = entry:FindFirstChildWhichIsA("UIStroke")
        if s then s.Transparency = 1; TweenService:Create(s, TweenInfo.new(0.3), { Transparency = 0 }):Play() end
    end

    -- cap at 150
    local children = scroll:GetChildren()
    local count = 0
    for _, c in pairs(children) do if c:IsA("Frame") then count = count + 1 end end
    if count > 150 then
        local oldest, oldestOrder = nil, math.huge
        for _, c in pairs(children) do
            if c:IsA("Frame") and c.LayoutOrder < oldestOrder then oldestOrder = c.LayoutOrder; oldest = c end
        end
        if oldest then oldest:Destroy() end
    end
    return entry
end

-- clean structured log row for spawn events
local function addSpawnLog(scroll, playerName, brainrotName, isOGEntry, sourceTag)
    local ogInfo = isOGEntry and getOGInfo(brainrotName) or nil
    local rowH = isOGEntry and 36 or 28

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, rowH)
    row.BackgroundColor3 = isOGEntry and Color3.fromRGB(30, 25, 10) or Theme.bgCard
    row.BorderSizePixel = 0
    row.ZIndex = 3
    row.LayoutOrder = -os.clock() * 1000
    row.Parent = scroll
    corner(row, 6)
    if isOGEntry then stroke(row, Theme.ogGold, 1) end

    -- timestamp (left)
    local timeLbl = Instance.new("TextLabel")
    timeLbl.Size = UDim2.new(0, 42, 0, 12)
    timeLbl.Position = UDim2.new(0, 6, 0, isOGEntry and 4 or 8)
    timeLbl.BackgroundTransparency = 1
    timeLbl.Font = Enum.Font.RobotoMono
    timeLbl.TextSize = 9
    timeLbl.TextColor3 = Theme.accentDim
    timeLbl.TextXAlignment = Enum.TextXAlignment.Left
    timeLbl.Text = os.date("%H:%M")
    timeLbl.ZIndex = 4
    timeLbl.TextTransparency = 1
    timeLbl.Parent = row

    -- player name
    local pLbl = Instance.new("TextLabel")
    pLbl.Size = UDim2.new(0, 90, 0, 14)
    pLbl.Position = UDim2.new(0, 50, 0, isOGEntry and 3 or 7)
    pLbl.BackgroundTransparency = 1
    pLbl.Font = Enum.Font.GothamBold
    pLbl.TextSize = isOGEntry and 11 or 10
    pLbl.TextColor3 = isOGEntry and Theme.white or Theme.text
    pLbl.TextXAlignment = Enum.TextXAlignment.Left
    pLbl.Text = playerName
    pLbl.TextTruncate = Enum.TextTruncate.AtEnd
    pLbl.ZIndex = 4
    pLbl.TextTransparency = 1
    pLbl.Parent = row

    -- brainrot name (right side)
    local brLbl = Instance.new("TextLabel")
    brLbl.Size = UDim2.new(0, 130, 0, 14)
    brLbl.Position = UDim2.new(0, 145, 0, isOGEntry and 3 or 7)
    brLbl.BackgroundTransparency = 1
    brLbl.Font = Enum.Font.Gotham
    brLbl.TextSize = isOGEntry and 10 or 9
    brLbl.TextColor3 = isOGEntry and Theme.ogGold or Theme.textMuted
    brLbl.TextXAlignment = Enum.TextXAlignment.Left
    brLbl.Text = brainrotName
    brLbl.TextTruncate = Enum.TextTruncate.AtEnd
    brLbl.ZIndex = 4
    brLbl.TextTransparency = 1
    brLbl.Parent = row

    -- source tag (far right)
    if sourceTag and sourceTag ~= "" then
        local srcLbl = Instance.new("TextLabel")
        srcLbl.Size = UDim2.new(0, 30, 0, 10)
        srcLbl.Position = UDim2.new(1, -36, 0, isOGEntry and 5 or 9)
        srcLbl.BackgroundTransparency = 1
        srcLbl.Font = Enum.Font.GothamBold
        srcLbl.TextSize = 7
        srcLbl.TextColor3 = Color3.fromRGB(100, 180, 255)
        srcLbl.TextXAlignment = Enum.TextXAlignment.Right
        srcLbl.Text = sourceTag
        srcLbl.ZIndex = 4
        srcLbl.TextTransparency = 1
        srcLbl.Parent = row
        TweenService:Create(srcLbl, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
    end

    -- OG extra line: earn rate
    if isOGEntry and ogInfo then
        local rateLbl = Instance.new("TextLabel")
        rateLbl.Size = UDim2.new(1, -56, 0, 12)
        rateLbl.Position = UDim2.new(0, 50, 0, 20)
        rateLbl.BackgroundTransparency = 1
        rateLbl.Font = Enum.Font.Gotham
        rateLbl.TextSize = 9
        rateLbl.TextColor3 = Theme.ogGold
        rateLbl.TextXAlignment = Enum.TextXAlignment.Left
        rateLbl.Text = "★ " .. ogInfo.rate .. " earn rate"
        rateLbl.ZIndex = 4
        rateLbl.TextTransparency = 1
        rateLbl.Parent = row
        TweenService:Create(rateLbl, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
    end

    -- fade in
    row.BackgroundTransparency = 1
    local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(row, fadeInfo, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(timeLbl, fadeInfo, { TextTransparency = 0 }):Play()
    TweenService:Create(pLbl, fadeInfo, { TextTransparency = 0 }):Play()
    TweenService:Create(brLbl, fadeInfo, { TextTransparency = 0 }):Play()
    if isOGEntry then
        local s = row:FindFirstChildWhichIsA("UIStroke")
        if s then s.Transparency = 1; TweenService:Create(s, TweenInfo.new(0.3), { Transparency = 0 }):Play() end
    end

    -- cap at 150
    local children = scroll:GetChildren()
    local count = 0
    for _, c in pairs(children) do if c:IsA("Frame") then count = count + 1 end end
    if count > 150 then
        local oldest, oldestOrder = nil, math.huge
        for _, c in pairs(children) do
            if c:IsA("Frame") and c.LayoutOrder < oldestOrder then oldestOrder = c.LayoutOrder; oldest = c end
        end
        if oldest then oldest:Destroy() end
    end
    return row
end

-- ════════════════════ PAGE: LIVE ════════════════════
local pageLive = Instance.new("Frame")
pageLive.Size = UDim2.new(1, 0, 1, 0)
pageLive.BackgroundTransparency = 1
pageLive.ZIndex = 2
pageLive.Parent = content
pages["Live"] = pageLive

local liveHeader = makeLabel(pageLive, {
    text = "LIVE FEED — ALL SERVERS", font = Enum.Font.GothamBold, size = 12,
    color = Theme.text, sz = UDim2.new(1, 0, 0, 20), pos = UDim2.new(0, 0, 0, 0)
})

local liveCountLabel = makeLabel(pageLive, {
    text = "0 events", font = Enum.Font.Gotham, size = 10,
    color = Theme.textMuted, align = Enum.TextXAlignment.Right,
    sz = UDim2.new(1, 0, 0, 20), pos = UDim2.new(0, 0, 0, 0)
})

local liveFeedFrame = Instance.new("Frame")
liveFeedFrame.Size = UDim2.new(1, 0, 1, -26)
liveFeedFrame.Position = UDim2.new(0, 0, 0, 26)
liveFeedFrame.BackgroundTransparency = 1
liveFeedFrame.ZIndex = 2
liveFeedFrame.Parent = pageLive

local liveScroll, liveList = makeScrollFeed(liveFeedFrame)

local liveWaiting = makeLabel(liveFeedFrame, {
    text = "scanning all servers...", font = Enum.Font.Gotham, size = 12,
    color = Theme.textMuted, align = Enum.TextXAlignment.Center,
    sz = UDim2.new(1, 0, 0, 30), pos = UDim2.new(0, 0, 0.4, 0), z = 4
})

-- ════════════════════ PAGE: OG (GLOSSARY + PLAYERS) ════════════════════
local pageOG = Instance.new("Frame")
pageOG.Size = UDim2.new(1, 0, 1, 0)
pageOG.BackgroundTransparency = 1
pageOG.ZIndex = 2
pageOG.Visible = false
pageOG.Parent = content
pages["OG"] = pageOG

state.autoDuel = false

local ogHeader = makeLabel(pageOG, {
    text = "OG GLOSSARY", font = Enum.Font.GothamBold, size = 12,
    color = Theme.ogGold, sz = UDim2.new(0.5, 0, 0, 20), pos = UDim2.new(0, 0, 0, 0)
})

local ogCountLabel = makeLabel(pageOG, {
    text = "0 global", font = Enum.Font.Gotham, size = 10,
    color = Theme.textMuted, align = Enum.TextXAlignment.Right,
    sz = UDim2.new(1, 0, 0, 20), pos = UDim2.new(0, 0, 0, 0)
})

-- ═══ OG PLAYERS LIST ═══
local ogListFrame = Instance.new("Frame")
ogListFrame.Size = UDim2.new(1, 0, 1, -24)
ogListFrame.Position = UDim2.new(0, 0, 0, 24)
ogListFrame.BackgroundTransparency = 1
ogListFrame.ZIndex = 2
ogListFrame.Parent = pageOG

local ogScroll, ogList = makeScrollFeed(ogListFrame)

local ogWaiting = makeLabel(ogListFrame, {
    text = "scanning all servers...", font = Enum.Font.Gotham, size = 12,
    color = Theme.textMuted, align = Enum.TextXAlignment.Center,
    sz = UDim2.new(1, 0, 0, 30), pos = UDim2.new(0, 0, 0.3, 0), z = 4
})

local ogPlayerRows = {}

-- ═══ TRADE / DUEL HELPERS ═══
local function sendTrade(playerName, statusLbl)
    spawn(function()
        pcall(function()
            statusLbl.Text = "sending..."
            statusLbl.TextColor3 = Theme.ogGold
            local targetPlayer = Players:FindFirstChild(playerName)
            if targetPlayer then
                if remotes.tradeSend then
                    remotes.tradeSend:FireServer(targetPlayer)
                    statusLbl.Text = "sent!"
                    statusLbl.TextColor3 = Theme.success
                elseif remotes.tradeSendRF then
                    remotes.tradeSendRF:InvokeServer(targetPlayer)
                    statusLbl.Text = "sent!"
                    statusLbl.TextColor3 = Theme.success
                elseif remotes.tradeSearch then
                    remotes.tradeSearch:InvokeServer(playerName)
                    statusLbl.Text = "searched"
                    statusLbl.TextColor3 = Theme.success
                else
                    statusLbl.Text = "no remote"
                    statusLbl.TextColor3 = Theme.danger
                end
            else
                statusLbl.Text = "not here"
                statusLbl.TextColor3 = Theme.danger
            end
            task.delay(2, function() pcall(function() statusLbl.Text = "" end) end)
        end)
    end)
end

local function sendDuel(playerName, statusLbl)
    spawn(function()
        pcall(function()
            statusLbl.Text = "dueling..."
            statusLbl.TextColor3 = Theme.ogGold
            local targetPlayer = Players:FindFirstChild(playerName)
            if targetPlayer then
                if remotes.duelSend then
                    remotes.duelSend:FireServer(targetPlayer)
                    statusLbl.Text = "duel sent!"
                    statusLbl.TextColor3 = Theme.success
                elseif remotes.duelSendRF then
                    remotes.duelSendRF:InvokeServer(targetPlayer)
                    statusLbl.Text = "duel sent!"
                    statusLbl.TextColor3 = Theme.success
                else
                    local found = false
                    for _, d in pairs(RS:GetDescendants()) do
                        local n = d.Name:lower()
                        if (n:find("duel") or n:find("battle") or n:find("fight") or n:find("pvp")) then
                            if d:IsA("RemoteEvent") then d:FireServer(targetPlayer); found = true; break
                            elseif d:IsA("RemoteFunction") then d:InvokeServer(targetPlayer); found = true; break end
                        end
                    end
                    statusLbl.Text = found and "duel sent!" or "no duel remote"
                    statusLbl.TextColor3 = found and Theme.success or Theme.danger
                end
            else
                statusLbl.Text = "not here"
                statusLbl.TextColor3 = Theme.danger
            end
            task.delay(2, function() pcall(function() statusLbl.Text = "" end) end)
        end)
    end)
end

-- ═══ BUILD OG PLAYER ROW ═══
local function addOGPlayerRow(playerName, brainrotNames, isInServer)
    if ogPlayerRows[playerName] then
        pcall(function()
            local row = ogPlayerRows[playerName]
            local brLbl = row:FindFirstChild("_brLbl")
            if brLbl then
                local parts = {}
                for _, brName in ipairs(brainrotNames) do
                    local info = getOGInfo(brName)
                    table.insert(parts, info and (brName .. " " .. info.rate) or brName)
                end
                brLbl.Text = "★ " .. table.concat(parts, ", ")
            end
            local srcLbl = row:FindFirstChild("_srcLbl")
            if srcLbl then srcLbl.Text = isInServer and "IN SERVER" or "GLOBAL"; srcLbl.TextColor3 = isInServer and Theme.success or Color3.fromRGB(100, 180, 255) end
        end)
        return
    end

    if ogWaiting.Visible then ogWaiting.Visible = false end

    local row = Instance.new("Frame")
    row.Name = "og_" .. playerName
    row.Size = UDim2.new(1, -8, 0, 58)
    row.BackgroundColor3 = Color3.fromRGB(30, 25, 10)
    row.BorderSizePixel = 0
    row.ZIndex = 3
    row.LayoutOrder = isInServer and (-os.clock() * 1000) or (-os.clock() * 1000 + 500000)
    row.Parent = ogScroll
    corner(row, 8)
    stroke(row, Theme.ogGold, 1)
    ogPlayerRows[playerName] = row

    -- avatar
    local thumb = Instance.new("ImageLabel")
    thumb.Size = UDim2.new(0, 34, 0, 34)
    thumb.Position = UDim2.new(0, 6, 0, 4)
    thumb.BackgroundColor3 = Theme.accentDim
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 4
    thumb.Parent = row
    corner(thumb, 6)

    spawn(function()
        pcall(function()
            local plr = Players:FindFirstChild(playerName)
            if plr then
                thumb.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            else
                local uid = nil
                pcall(function() uid = Players:GetUserIdFromNameAsync(playerName) end)
                if uid then thumb.Image = Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end
            end
        end)
    end)

    -- username
    local userLbl = Instance.new("TextLabel")
    userLbl.Size = UDim2.new(0, 120, 0, 14)
    userLbl.Position = UDim2.new(0, 46, 0, 3)
    userLbl.BackgroundTransparency = 1
    userLbl.Font = Enum.Font.GothamBold
    userLbl.TextSize = 11
    userLbl.TextColor3 = Theme.white
    userLbl.TextXAlignment = Enum.TextXAlignment.Left
    userLbl.Text = playerName
    userLbl.TextTruncate = Enum.TextTruncate.AtEnd
    userLbl.ZIndex = 4
    userLbl.TextTransparency = 1
    userLbl.Parent = row

    -- source tag (IN SERVER / GLOBAL)
    local srcLbl = Instance.new("TextLabel")
    srcLbl.Name = "_srcLbl"
    srcLbl.Size = UDim2.new(0, 60, 0, 12)
    srcLbl.Position = UDim2.new(1, -66, 0, 4)
    srcLbl.BackgroundTransparency = 1
    srcLbl.Font = Enum.Font.GothamBold
    srcLbl.TextSize = 7
    srcLbl.TextColor3 = isInServer and Theme.success or Color3.fromRGB(100, 180, 255)
    srcLbl.TextXAlignment = Enum.TextXAlignment.Right
    srcLbl.Text = isInServer and "IN SERVER" or "GLOBAL"
    srcLbl.ZIndex = 4
    srcLbl.TextTransparency = 1
    srcLbl.Parent = row

    -- brainrot names
    local brLbl = Instance.new("TextLabel")
    brLbl.Name = "_brLbl"
    brLbl.Size = UDim2.new(1, -54, 0, 12)
    brLbl.Position = UDim2.new(0, 46, 0, 18)
    brLbl.BackgroundTransparency = 1
    brLbl.Font = Enum.Font.Gotham
    brLbl.TextSize = 9
    brLbl.TextColor3 = Theme.ogGold
    brLbl.TextXAlignment = Enum.TextXAlignment.Left
    -- build brainrot text with rates
    local brParts = {}
    for _, brName in ipairs(brainrotNames) do
        local info = getOGInfo(brName)
        if info then
            table.insert(brParts, brName .. " " .. info.rate)
        else
            table.insert(brParts, brName)
        end
    end
    brLbl.Text = "★ " .. table.concat(brParts, ", ")
    brLbl.TextTruncate = Enum.TextTruncate.AtEnd
    brLbl.ZIndex = 4
    brLbl.TextTransparency = 1
    brLbl.Parent = row

    -- status label
    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, -8, 0, 10)
    statusLbl.Position = UDim2.new(0, 4, 1, -12)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 8
    statusLbl.TextColor3 = Theme.textMuted
    statusLbl.Text = ""
    statusLbl.ZIndex = 4
    statusLbl.Parent = row

    -- buttons: TRADE | DUEL | COPY
    local btnY = 34
    local btnH = 18

    local tradeBtn = Instance.new("TextButton")
    tradeBtn.Size = UDim2.new(0, 46, 0, btnH)
    tradeBtn.Position = UDim2.new(0, 46, 0, btnY)
    tradeBtn.BackgroundColor3 = Theme.accent
    tradeBtn.Font = Enum.Font.GothamBold
    tradeBtn.TextSize = 9
    tradeBtn.TextColor3 = Theme.bg
    tradeBtn.Text = "TRADE"
    tradeBtn.AutoButtonColor = false
    tradeBtn.ZIndex = 4
    tradeBtn.Parent = row
    corner(tradeBtn, 5)
    hoverFx(tradeBtn, Theme.accent, Theme.accentHover)

    local duelBtn = Instance.new("TextButton")
    duelBtn.Size = UDim2.new(0, 40, 0, btnH)
    duelBtn.Position = UDim2.new(0, 96, 0, btnY)
    duelBtn.BackgroundColor3 = Theme.ogGold
    duelBtn.Font = Enum.Font.GothamBold
    duelBtn.TextSize = 9
    duelBtn.TextColor3 = Theme.bg
    duelBtn.Text = "DUEL"
    duelBtn.AutoButtonColor = false
    duelBtn.ZIndex = 4
    duelBtn.Parent = row
    corner(duelBtn, 5)
    hoverFx(duelBtn, Theme.ogGold, Color3.fromRGB(255, 210, 100))

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 38, 0, btnH)
    copyBtn.Position = UDim2.new(0, 140, 0, btnY)
    copyBtn.BackgroundColor3 = Theme.accentDim
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 9
    copyBtn.TextColor3 = Theme.text
    copyBtn.Text = "COPY"
    copyBtn.AutoButtonColor = false
    copyBtn.ZIndex = 4
    copyBtn.Parent = row
    corner(copyBtn, 5)
    hoverFx(copyBtn, Theme.accentDim, Theme.accent)

    tradeBtn.MouseButton1Click:Connect(function() sendTrade(playerName, statusLbl) end)
    duelBtn.MouseButton1Click:Connect(function() sendDuel(playerName, statusLbl) end)
    copyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then setclipboard(playerName)
            elseif toclipboard then toclipboard(playerName)
            elseif Clipboard and Clipboard.set then Clipboard.set(playerName) end
        end)
        copyBtn.Text = "✓"
        copyBtn.BackgroundColor3 = Theme.success
        copyBtn.TextColor3 = Theme.bg
        task.delay(1, function() pcall(function() copyBtn.Text = "COPY"; copyBtn.BackgroundColor3 = Theme.accentDim; copyBtn.TextColor3 = Theme.text end) end)
    end)

    -- fade in
    row.BackgroundTransparency = 1
    tradeBtn.BackgroundTransparency = 1; tradeBtn.TextTransparency = 1
    duelBtn.BackgroundTransparency = 1; duelBtn.TextTransparency = 1
    copyBtn.BackgroundTransparency = 1; copyBtn.TextTransparency = 1
    thumb.ImageTransparency = 1; thumb.BackgroundTransparency = 1
    local fadeInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(row, fadeInfo, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(userLbl, fadeInfo, { TextTransparency = 0 }):Play()
    TweenService:Create(srcLbl, fadeInfo, { TextTransparency = 0 }):Play()
    TweenService:Create(brLbl, fadeInfo, { TextTransparency = 0 }):Play()
    TweenService:Create(tradeBtn, fadeInfo, { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
    TweenService:Create(duelBtn, fadeInfo, { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
    TweenService:Create(copyBtn, fadeInfo, { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
    TweenService:Create(thumb, fadeInfo, { ImageTransparency = 0, BackgroundTransparency = 0 }):Play()
    local rowStroke = row:FindFirstChildWhichIsA("UIStroke")
    if rowStroke then rowStroke.Transparency = 1; TweenService:Create(rowStroke, fadeInfo, { Transparency = 0 }):Play() end
end

-- ═══ OG DISPLAY REFRESH (from global database — no destroy/recreate) ═══
local function refreshOGDisplay()
    local currentPlayers = {} -- track who should be shown

    local count = 0
    for playerName, data in pairs(globalOGDB) do
        count = count + 1
        currentPlayers[playerName] = true
        local brNames = {}
        for brName, _ in pairs(data.brainrots) do table.insert(brNames, brName) end
        addOGPlayerRow(playerName, brNames, data.inServer)
    end

    -- only remove rows for players no longer in the DB
    for pName, rowFrame in pairs(ogPlayerRows) do
        if not currentPlayers[pName] then
            pcall(function() rowFrame:Destroy() end)
            ogPlayerRows[pName] = nil
        end
    end

    state.ogCaught = count
    caughtLabel.Text = count .. " caught"
    ogCountLabel.Text = count .. " global"
    if count == 0 then
        ogWaiting.Visible = true
        ogWaiting.Text = "scanning all servers..."
    else
        ogWaiting.Visible = false
    end
end

-- ════════════════════ ACTIVE OG SCANNER ════════════════════
-- Scans workspace + feeds global OG database

local function scanAllPlayersForOGs()
    -- scan workspace for local server OGs
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
                    local brainrotName = getBrainrotName(obj)
                    local ownerName = getOwnerName(obj)

                    if not ownerName then
                        local parent = obj.Parent
                        while parent and parent ~= workspace do
                            pcall(function()
                                local plr = Players:FindFirstChild(parent.Name)
                                if plr then ownerName = parent.Name end
                                if not ownerName then
                                    local o = parent:FindFirstChild("Owner") or parent:FindFirstChild("PlotOwner")
                                    if o then
                                        if o:IsA("ObjectValue") and o.Value then ownerName = o.Value.Name
                                        elseif o:IsA("StringValue") then ownerName = o.Value
                                        elseif o:IsA("IntValue") then
                                            local p = Players:GetPlayerByUserId(o.Value)
                                            if p then ownerName = p.Name end
                                        end
                                    end
                                end
                            end)
                            parent = parent.Parent
                        end
                    end

                    if ownerName and brainrotName and isOG(brainrotName) then
                        addToGlobalOGDB(ownerName, brainrotName, "LOCAL")
                    end
                end
            end)
        end
    end)

    -- scan backpacks/characters
    pcall(function()
        for _, plr in pairs(Players:GetPlayers()) do
            pcall(function()
                for _, item in pairs(plr.Backpack:GetChildren()) do
                    pcall(function()
                        if isOG(item.Name) then addToGlobalOGDB(plr.Name, item.Name, "LOCAL") end
                    end)
                end
                if plr.Character then
                    for _, item in pairs(plr.Character:GetChildren()) do
                        pcall(function()
                            if item:IsA("Tool") and isOG(item.Name) then addToGlobalOGDB(plr.Name, item.Name, "LOCAL") end
                        end)
                    end
                end
            end)
        end
    end)

    -- mark players who left as not in server
    for pName, data in pairs(globalOGDB) do
        if data.inServer and not Players:FindFirstChild(pName) then
            data.inServer = false
            data.source = "GLOBAL"
        end
    end

    -- auto duel in-server OG players
    if state.autoDuel then
        for pName, data in pairs(globalOGDB) do
            if data.inServer and pName ~= LP.Name then
                spawn(function()
                    pcall(function()
                        local target = Players:FindFirstChild(pName)
                        if target then
                            if remotes.duelSend then remotes.duelSend:FireServer(target)
                            elseif remotes.duelSendRF then remotes.duelSendRF:InvokeServer(target) end
                        end
                    end)
                end)
            end
        end
    end
end

local function refreshOGPlayers()
    scanAllPlayersForOGs()
    refreshOGDisplay()
end

-- ════════════════════ PAGE: TRACK ════════════════════
local pageTrack = Instance.new("Frame")
pageTrack.Size = UDim2.new(1, 0, 1, 0)
pageTrack.BackgroundTransparency = 1
pageTrack.ZIndex = 2
pageTrack.Visible = false
pageTrack.Parent = content
pages["Track"] = pageTrack

local trackHeader = makeLabel(pageTrack, {
    text = "TRACKED PLAYERS", font = Enum.Font.GothamBold, size = 12,
    color = Theme.text, sz = UDim2.new(0.5, 0, 0, 20), pos = UDim2.new(0, 0, 0, 0)
})

local trackCountLabel = makeLabel(pageTrack, {
    text = "0 players", font = Enum.Font.Gotham, size = 10,
    color = Theme.textMuted, align = Enum.TextXAlignment.Right,
    sz = UDim2.new(1, 0, 0, 20), pos = UDim2.new(0, 0, 0, 0)
})

local trackDesc = makeLabel(pageTrack, {
    text = "auto-fills from live spawns", font = Enum.Font.Gotham, size = 9,
    color = Theme.accentDim, sz = UDim2.new(1, 0, 0, 14), pos = UDim2.new(0, 0, 0, 18)
})

-- tracked users list
local trackListFrame = Instance.new("Frame")
trackListFrame.Size = UDim2.new(1, 0, 1, -36)
trackListFrame.Position = UDim2.new(0, 0, 0, 36)
trackListFrame.BackgroundTransparency = 1
trackListFrame.ZIndex = 2
trackListFrame.Parent = pageTrack

local trackScroll, trackList = makeScrollFeed(trackListFrame)
local trackEmpty = makeLabel(trackListFrame, {
    text = "no players detected yet...", font = Enum.Font.Gotham, size = 11,
    color = Theme.textMuted, align = Enum.TextXAlignment.Center,
    sz = UDim2.new(1, 0, 0, 20), pos = UDim2.new(0, 0, 0.3, 0), z = 4
})

local trackRowMap = {} -- username -> row frame (avoid dupes, update count)

local function addTrackEntry(playerName, brainrotName, isOGSpawn, source)
    -- update or create tracked user data
    local data = trackedUsers[playerName]
    if data then
        data.count = data.count + 1
        data.lastBrainrot = brainrotName
        data.lastTime = os.date("%H:%M:%S")
        data.lastOG = isOGSpawn
        data.source = source or data.source
        -- update existing row if it exists
        if trackRowMap[playerName] then
            pcall(function()
                local row = trackRowMap[playerName]
                local countLbl = row:FindFirstChild("_countLbl")
                local brLbl = row:FindFirstChild("_brLbl")
                if countLbl then countLbl.Text = data.count .. "x" end
                if brLbl then brLbl.Text = brainrotName .. " · " .. data.lastTime end
            end)
            return
        end
    else
        trackedUsers[playerName] = {
            count = 1,
            lastBrainrot = brainrotName,
            lastTime = os.date("%H:%M:%S"),
            lastOG = isOGSpawn,
            source = source or "LOCAL",
        }
        data = trackedUsers[playerName]
    end

    trackEmpty.Visible = false
    local pCount = 0
    for _ in pairs(trackedUsers) do pCount = pCount + 1 end
    trackCountLabel.Text = pCount .. " players"

    local isOG = isOGSpawn
    local row = Instance.new("Frame")
    row.Name = "track_" .. playerName
    row.Size = UDim2.new(1, -8, 0, 38)
    row.BackgroundColor3 = isOG and Color3.fromRGB(30, 25, 10) or Theme.bgCard
    row.BorderSizePixel = 0
    row.ZIndex = 3
    row.LayoutOrder = -os.clock() * 1000
    row.Parent = trackScroll
    corner(row, 6)
    if isOG then stroke(row, Theme.ogGold, 1) end
    trackRowMap[playerName] = row

    -- player name
    local userLbl = Instance.new("TextLabel")
    userLbl.Size = UDim2.new(0.55, 0, 0, 16)
    userLbl.Position = UDim2.new(0, 8, 0, 4)
    userLbl.BackgroundTransparency = 1
    userLbl.Font = Enum.Font.GothamBold
    userLbl.TextSize = 11
    userLbl.TextColor3 = isOG and Theme.ogGold or Theme.text
    userLbl.TextXAlignment = Enum.TextXAlignment.Left
    userLbl.Text = playerName
    userLbl.TextTruncate = Enum.TextTruncate.AtEnd
    userLbl.ZIndex = 4
    userLbl.TextTransparency = 1
    userLbl.Parent = row

    -- count badge
    local countLbl = Instance.new("TextLabel")
    countLbl.Name = "_countLbl"
    countLbl.Size = UDim2.new(0, 28, 0, 16)
    countLbl.Position = UDim2.new(1, -36, 0, 4)
    countLbl.BackgroundColor3 = isOG and Theme.ogGold or Theme.accentDim
    countLbl.BackgroundTransparency = 0.4
    countLbl.Font = Enum.Font.GothamBold
    countLbl.TextSize = 9
    countLbl.TextColor3 = isOG and Theme.bg or Theme.text
    countLbl.Text = "1x"
    countLbl.ZIndex = 4
    countLbl.TextTransparency = 1
    countLbl.Parent = row
    corner(countLbl, 4)

    -- brainrot + time subtitle
    local brLbl = Instance.new("TextLabel")
    brLbl.Name = "_brLbl"
    brLbl.Size = UDim2.new(1, -16, 0, 12)
    brLbl.Position = UDim2.new(0, 8, 0, 22)
    brLbl.BackgroundTransparency = 1
    brLbl.Font = Enum.Font.Gotham
    brLbl.TextSize = 9
    brLbl.TextColor3 = Theme.textMuted
    brLbl.TextXAlignment = Enum.TextXAlignment.Left
    brLbl.Text = brainrotName .. " · " .. os.date("%H:%M:%S")
    brLbl.TextTruncate = Enum.TextTruncate.AtEnd
    brLbl.ZIndex = 4
    brLbl.TextTransparency = 1
    brLbl.Parent = row

    -- fade in
    row.BackgroundTransparency = 1
    TweenService:Create(row, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(userLbl, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
    TweenService:Create(countLbl, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0, BackgroundTransparency = 0.4 }):Play()
    TweenService:Create(brLbl, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
    if isOG then
        local s = row:FindFirstChildWhichIsA("UIStroke")
        if s then s.Transparency = 1; TweenService:Create(s, TweenInfo.new(0.35), { Transparency = 0 }):Play() end
    end
    countLbl.BackgroundTransparency = 1
end

-- ════════════════════ PAGE: FLEECE ════════════════════
local pageFleece = Instance.new("Frame")
pageFleece.Size = UDim2.new(1, 0, 1, 0)
pageFleece.BackgroundTransparency = 1
pageFleece.ZIndex = 2
pageFleece.Visible = false
pageFleece.Parent = content
pages["Fleece"] = pageFleece

local fleeceHeader = makeLabel(pageFleece, {
    text = "AUTO FLEECE", font = Enum.Font.GothamBold, size = 12,
    color = Theme.text, sz = UDim2.new(0.6, 0, 0, 20), pos = UDim2.new(0, 0, 0, 0)
})

local fleeceDesc = makeLabel(pageFleece, {
    text = "Auto-sends trade to players who claim OG brainrots",
    font = Enum.Font.Gotham, size = 10, color = Theme.textMuted,
    sz = UDim2.new(1, 0, 0, 16), pos = UDim2.new(0, 0, 0, 20)
})

-- fleece toggle
local fleeceToggleRow = Instance.new("Frame")
fleeceToggleRow.Size = UDim2.new(1, 0, 0, 40)
fleeceToggleRow.Position = UDim2.new(0, 0, 0, 44)
fleeceToggleRow.BackgroundColor3 = Theme.bgCard
fleeceToggleRow.BorderSizePixel = 0
fleeceToggleRow.ZIndex = 3
fleeceToggleRow.Parent = pageFleece
corner(fleeceToggleRow, 8)

local fleeceLbl = makeLabel(fleeceToggleRow, {
    text = "Auto Fleece", font = Enum.Font.GothamBold, size = 12,
    color = Theme.text, sz = UDim2.new(0.7, 0, 1, 0), pos = UDim2.new(0, 12, 0, 0)
})

local fleeceToggle = Instance.new("TextButton")
fleeceToggle.Size = UDim2.new(0, 44, 0, 22)
fleeceToggle.Position = UDim2.new(1, -56, 0.5, -11)
fleeceToggle.BackgroundColor3 = Theme.toggleOff
fleeceToggle.Font = Enum.Font.GothamBold
fleeceToggle.TextSize = 9
fleeceToggle.TextColor3 = Theme.textMuted
fleeceToggle.Text = "OFF"
fleeceToggle.AutoButtonColor = false
fleeceToggle.ZIndex = 4
fleeceToggle.Parent = fleeceToggleRow
corner(fleeceToggle, 11)

fleeceToggle.MouseButton1Click:Connect(function()
    state.autoFleece = not state.autoFleece
    if state.autoFleece then
        TweenService:Create(fleeceToggle, TweenFast, { BackgroundColor3 = Theme.toggleOn }):Play()
        fleeceToggle.TextColor3 = Theme.bg
        fleeceToggle.Text = "ON"
    else
        TweenService:Create(fleeceToggle, TweenFast, { BackgroundColor3 = Theme.toggleOff }):Play()
        fleeceToggle.TextColor3 = Theme.textMuted
        fleeceToggle.Text = "OFF"
    end
end)

-- fleece queue display
local fleeceQueueHeader = makeLabel(pageFleece, {
    text = "FLEECE QUEUE", font = Enum.Font.GothamBold, size = 11,
    color = Theme.textMuted, sz = UDim2.new(1, 0, 0, 20), pos = UDim2.new(0, 0, 0, 92)
})

local fleeceListFrame = Instance.new("Frame")
fleeceListFrame.Size = UDim2.new(1, 0, 1, -120)
fleeceListFrame.Position = UDim2.new(0, 0, 0, 116)
fleeceListFrame.BackgroundTransparency = 1
fleeceListFrame.ZIndex = 2
fleeceListFrame.Parent = pageFleece

local fleeceScroll, fleeceList = makeScrollFeed(fleeceListFrame)
local fleeceEmpty = makeLabel(fleeceListFrame, {
    text = "no targets in queue", font = Enum.Font.Gotham, size = 11,
    color = Theme.textMuted, align = Enum.TextXAlignment.Center,
    sz = UDim2.new(1, 0, 0, 20), pos = UDim2.new(0, 0, 0.3, 0), z = 4
})

local function addFleeceEntry(playerName, brainrotName)
    fleeceEmpty.Visible = false
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 40)
    row.BackgroundColor3 = Theme.bgCard
    row.BorderSizePixel = 0
    row.ZIndex = 3
    row.LayoutOrder = -os.clock() * 1000
    row.Parent = fleeceScroll
    corner(row, 6)
    stroke(row, Theme.ogGold, 1)

    local info = makeLabel(row, {
        text = playerName .. " got " .. brainrotName,
        font = Enum.Font.GothamBold, size = 11, color = Theme.white,
        sz = UDim2.new(1, -80, 0, 16), pos = UDim2.new(0, 8, 0, 4)
    })

    local statusLbl = makeLabel(row, {
        text = "pending trade...", font = Enum.Font.Gotham, size = 9,
        color = Theme.ogGold, sz = UDim2.new(1, -80, 0, 14), pos = UDim2.new(0, 8, 0, 22)
    })

    local tradeBtn = Instance.new("TextButton")
    tradeBtn.Size = UDim2.new(0, 60, 0, 26)
    tradeBtn.Position = UDim2.new(1, -68, 0.5, -13)
    tradeBtn.BackgroundColor3 = Theme.accent
    tradeBtn.Font = Enum.Font.GothamBold
    tradeBtn.TextSize = 10
    tradeBtn.TextColor3 = Theme.bg
    tradeBtn.Text = "TRADE"
    tradeBtn.AutoButtonColor = false
    tradeBtn.ZIndex = 4
    tradeBtn.Parent = row
    corner(tradeBtn, 6)

    tradeBtn.MouseButton1Click:Connect(function()
        statusLbl.Text = "sending trade..."
        statusLbl.TextColor3 = Theme.success
        -- attempt to initiate trade
        pcall(function()
            local targetPlayer = Players:FindFirstChild(playerName)
            if targetPlayer then
                -- try trade send remote
                if remotes.tradeSend then
                    remotes.tradeSend:FireServer(targetPlayer)
                    statusLbl.Text = "trade sent!"
                elseif remotes.tradeSendRF then
                    remotes.tradeSendRF:InvokeServer(targetPlayer)
                    statusLbl.Text = "trade sent!"
                elseif remotes.tradeSearch then
                    local result = remotes.tradeSearch:InvokeServer(playerName)
                    statusLbl.Text = "searched: " .. tostring(result)
                else
                    statusLbl.Text = "no trade remote found"
                    statusLbl.TextColor3 = Theme.danger
                end
            else
                statusLbl.Text = "player left server"
                statusLbl.TextColor3 = Theme.danger
            end
        end)
    end)

    return statusLbl
end

-- ════════════════════ PAGE: SETTINGS ════════════════════
local pageSettings = Instance.new("Frame")
pageSettings.Size = UDim2.new(1, 0, 1, 0)
pageSettings.BackgroundTransparency = 1
pageSettings.ZIndex = 2
pageSettings.Visible = false
pageSettings.Parent = content
pages["Settings"] = pageSettings

local settingsScroll, settingsList = makeScrollFeed(pageSettings)

local function makeSettingRow(label, key, yOrder)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 40)
    row.BackgroundColor3 = Theme.bgCard
    row.BorderSizePixel = 0
    row.ZIndex = 3
    row.LayoutOrder = yOrder or 0
    row.Parent = settingsScroll
    corner(row, 8)

    local lbl = makeLabel(row, {
        text = label, font = Enum.Font.GothamBold, size = 12,
        color = Theme.text, sz = UDim2.new(0.7, 0, 1, 0), pos = UDim2.new(0, 12, 0, 0)
    })

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 44, 0, 22)
    toggle.Position = UDim2.new(1, -56, 0.5, -11)
    toggle.BackgroundColor3 = state[key] and Theme.toggleOn or Theme.toggleOff
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 9
    toggle.TextColor3 = state[key] and Theme.bg or Theme.textMuted
    toggle.Text = state[key] and "ON" or "OFF"
    toggle.AutoButtonColor = false
    toggle.ZIndex = 4
    toggle.Parent = row
    corner(toggle, 11)

    toggle.MouseButton1Click:Connect(function()
        state[key] = not state[key]
        if state[key] then
            TweenService:Create(toggle, TweenFast, { BackgroundColor3 = Theme.toggleOn }):Play()
            toggle.TextColor3 = Theme.bg
            toggle.Text = "ON"
        else
            TweenService:Create(toggle, TweenFast, { BackgroundColor3 = Theme.toggleOff }):Play()
            toggle.TextColor3 = Theme.textMuted
            toggle.Text = "OFF"
        end
    end)

    return row
end

makeSettingRow("Sound Alerts", "soundAlerts", 1)
makeSettingRow("Auto Track New Players", "autoTrack", 2)
makeSettingRow("Auto Duel OG Players", "autoDuel", 3)
makeSettingRow("Auto Server Hop", "serverHop", 4)

-- server hop now button
local hopNowBtn = Instance.new("TextButton")
hopNowBtn.Size = UDim2.new(1, -8, 0, 36)
hopNowBtn.BackgroundColor3 = Theme.accentDim
hopNowBtn.Font = Enum.Font.GothamBold
hopNowBtn.TextSize = 12
hopNowBtn.TextColor3 = Theme.text
hopNowBtn.Text = "HOP SERVER NOW"
hopNowBtn.AutoButtonColor = false
hopNowBtn.ZIndex = 3
hopNowBtn.LayoutOrder = 5
hopNowBtn.Parent = settingsScroll
corner(hopNowBtn, 8)
hoverFx(hopNowBtn, Theme.accentDim, Theme.accent)

hopNowBtn.MouseButton1Click:Connect(function()
    hopNowBtn.Text = "HOPPING..."
    spawn(function()
        pcall(function()
            -- mark current server visited
            serverScanState.visited[game.JobId] = true
            local servers = fetchServerList()
            -- prefer unvisited servers with most players
            local unvisited, visited = {}, {}
            for _, s in pairs(servers) do
                if not serverScanState.visited[s.id] then
                    table.insert(unvisited, s)
                else
                    table.insert(visited, s)
                end
            end
            table.sort(unvisited, function(a, b) return (a.playing or 0) > (b.playing or 0) end)
            table.sort(visited, function(a, b) return (a.playing or 0) > (b.playing or 0) end)
            local pick = unvisited[1] or visited[1]
            if pick then
                addLogEntry(liveScroll, "• [" .. os.date("%H:%M:%S") .. "] Manual hop → " .. string.sub(pick.id, 1, 8) .. "... (" .. (pick.playing or "?") .. "p)", Color3.fromRGB(100, 180, 255), false)
                TeleportService:TeleportToPlaceInstance(PLACE_ID, pick.id, LP)
            else
                TeleportService:Teleport(PLACE_ID, LP)
            end
        end)
        hopNowBtn.Text = "HOP SERVER NOW"
    end)
end)

-- stats row
local statsRow = Instance.new("Frame")
statsRow.Size = UDim2.new(1, -8, 0, 60)
statsRow.BackgroundColor3 = Theme.bgCard
statsRow.BorderSizePixel = 0
statsRow.ZIndex = 3
statsRow.LayoutOrder = 6
statsRow.Parent = settingsScroll
corner(statsRow, 8)

local statsLbl = makeLabel(statsRow, {
    text = "STATS", font = Enum.Font.GothamBold, size = 11,
    color = Theme.textMuted, sz = UDim2.new(1, 0, 0, 16), pos = UDim2.new(0, 12, 0, 4)
})

local statsDetailLbl = makeLabel(statsRow, {
    text = "OG Caught: 0  |  Scanned: 0  |  Tracked: 0",
    font = Enum.Font.RobotoMono, size = 10, color = Theme.text,
    sz = UDim2.new(1, -16, 0, 14), pos = UDim2.new(0, 12, 0, 22)
})

local statsUptimeLbl = makeLabel(statsRow, {
    text = "Uptime: 0m 0s  |  Server: " .. game.JobId:sub(1, 12) .. "...",
    font = Enum.Font.RobotoMono, size = 9, color = Theme.textMuted,
    sz = UDim2.new(1, -16, 0, 14), pos = UDim2.new(0, 12, 0, 38)
})

-- remote info
local remoteCount = 0
for _, v in pairs(remotes) do if v then remoteCount = remoteCount + 1 end end

local remoteLbl = Instance.new("Frame")
remoteLbl.Size = UDim2.new(1, -8, 0, 26)
remoteLbl.BackgroundColor3 = Theme.bgCard
remoteLbl.BorderSizePixel = 0
remoteLbl.ZIndex = 3
remoteLbl.LayoutOrder = 7
remoteLbl.Parent = settingsScroll
corner(remoteLbl, 6)

makeLabel(remoteLbl, {
    text = remoteCount .. " remotes  |  Trade: " .. (remotes.tradeSend and "YES" or (remotes.tradeSendRF and "YES" or "SEARCH")) .. "  |  Duel: " .. (remotes.duelSend and "YES" or (remotes.duelSendRF and "YES" or "NO")),
    font = Enum.Font.RobotoMono, size = 9, color = Theme.textMuted,
    sz = UDim2.new(1, -16, 1, 0), pos = UDim2.new(0, 8, 0, 0)
})

-- ════════════════════ SET INITIAL TAB ════════════════════
setTab("Live")

-- ════════════════════ CORE: SPAWN DETECTION ════════════════════
local startTime = os.clock()
local liveEventCount = 0

local function getBrainrotName(obj)
    -- try various ways to get the brainrot's name
    local name = nil
    pcall(function()
        local bd = obj:FindFirstChild("BrainrotData")
        if bd then
            if bd:IsA("StringValue") then
                name = bd.Value
            elseif bd:FindFirstChild("Name") then
                name = bd.Name.Value
            end
        end
    end)
    if name then return name end

    pcall(function()
        local bn = obj:FindFirstChild("BrainrotName")
        if bn and bn:IsA("StringValue") then
            name = bn.Value
        end
    end)
    if name then return name end

    pcall(function()
        local display = obj:FindFirstChild("DisplayName")
        if display and display:IsA("StringValue") then
            name = display.Value
        end
    end)
    if name then return name end

    -- fallback to model name
    return obj.Name
end

local function getOwnerName(obj)
    local ownerName = nil
    pcall(function()
        local owner = obj:FindFirstChild("Owner") or obj:FindFirstChild("PlotOwner")
        if owner then
            if owner:IsA("ObjectValue") and owner.Value then
                ownerName = owner.Value.Name
            elseif owner:IsA("StringValue") then
                ownerName = owner.Value
            elseif owner:IsA("IntValue") then
                local plr = Players:GetPlayerByUserId(owner.Value)
                if plr then ownerName = plr.Name end
            end
        end
    end)
    return ownerName
end

local function logSpawn(playerName, brainrotName, isOGSpawn, source)
    local timestamp = os.date("%H:%M:%S")
    liveEventCount = liveEventCount + 1

    local src = source or "LOCAL"
    local isGlobal = (src == "GLOBAL")
    if isGlobal then state.globalEvents = state.globalEvents + 1 end

    -- hide waiting text
    if liveWaiting.Visible then liveWaiting.Visible = false end

    -- add to live feed with clean structured row
    local srcTag = isGlobal and "ALL" or "LOCAL"
    addSpawnLog(liveScroll, playerName, brainrotName, isOGSpawn, srcTag)
    liveCountLabel.Text = liveEventCount .. " events"

    -- auto-track every player from live spawns
    addTrackEntry(playerName, brainrotName, isOGSpawn, src)

    -- if OG, add to global database and fleece queue
    if isOGSpawn then
        addToGlobalOGDB(playerName, brainrotName, src)
        spawn(function() pcall(refreshOGDisplay) end)

        -- add to fleece queue if auto-fleece is on
        if state.autoFleece then
            table.insert(fleeceQueue, {player = playerName, brainrot = brainrotName})
            addFleeceEntry(playerName, brainrotName)
        end
    end

    -- store in log tables
    table.insert(liveLog, {time = timestamp, player = playerName, brainrot = brainrotName, og = isOGSpawn, source = src})
    if isOGSpawn then
        table.insert(ogLog, {time = timestamp, player = playerName, brainrot = brainrotName, source = src})
    end
end

-- Method 1: Watch workspace for new brainrot models
local function scanForBrainrots()
    for _, obj in pairs(workspace:GetDescendants()) do
        if not state.running then break end
        pcall(function()
            local isBrainrot = false
            if obj:IsA("Model") then
                if obj:FindFirstChild("BrainrotData") or obj:FindFirstChild("BrainrotName") then
                    isBrainrot = true
                elseif obj:FindFirstChild("Humanoid") and (obj:FindFirstChild("Owner") or obj:FindFirstChild("PlotOwner")) then
                    isBrainrot = true
                elseif obj.Name:lower():find("brainrot") then
                    isBrainrot = true
                end
            end

            if isBrainrot and not knownBrainrots[obj] then
                knownBrainrots[obj] = true
                state.totalScanned = state.totalScanned + 1

                local brainrotName = getBrainrotName(obj)
                local ownerName = getOwnerName(obj)

                if ownerName and ownerName ~= LP.Name then
                    local ogStatus = isOG(brainrotName)
                    logSpawn(ownerName, brainrotName, ogStatus)
                end
            end
        end)
    end
end

-- watch for new descendants
conns[#conns+1] = workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.2) -- let properties populate
    if not state.running then return end
    pcall(function()
        if not obj or not obj.Parent then return end
        if obj:IsA("Model") then
            local isBrainrot = false
            if obj:FindFirstChild("BrainrotData") or obj:FindFirstChild("BrainrotName") then
                isBrainrot = true
            elseif obj.Name:lower():find("brainrot") then
                isBrainrot = true
            end

            if isBrainrot and not knownBrainrots[obj] then
                knownBrainrots[obj] = true
                state.totalScanned = state.totalScanned + 1

                -- wait a bit for owner to be set
                task.wait(0.5)

                local brainrotName = getBrainrotName(obj)
                local ownerName = getOwnerName(obj)

                if ownerName then
                    local ogStatus = isOG(brainrotName)
                    logSpawn(ownerName, brainrotName, ogStatus)
                end
            end
        end
    end)
end)

-- Method 2: Hook notification remote
if remotes.notify then
    conns[#conns+1] = remotes.notify.OnClientEvent:Connect(function(...)
        local args = {...}
        pcall(function()
            for _, arg in pairs(args) do
                if type(arg) == "string" then
                    -- look for spawn notification patterns
                    -- typical patterns: "PlayerName claimed Brainrot!" or "Brainrot spawned!"
                    local player, brainrot = arg:match("(%w+)%s+claimed%s+(.+)")
                    if not player then
                        player, brainrot = arg:match("(%w+)%s+got%s+(.+)")
                    end
                    if not player then
                        player, brainrot = arg:match("(%w+)%s+found%s+(.+)")
                    end
                    if not player then
                        player, brainrot = arg:match("(%w+)%s+obtained%s+(.+)")
                    end

                    if player and brainrot then
                        brainrot = brainrot:gsub("!", ""):gsub("%.$", "")
                        local ogStatus = isOG(brainrot)
                        logSpawn(player, brainrot, ogStatus)
                    end
                elseif type(arg) == "table" then
                    -- some games pass notification data as table
                    local player = arg.Player or arg.player or arg.PlayerName or arg.username
                    local brainrot = arg.Brainrot or arg.brainrot or arg.BrainrotName or arg.item or arg.Item
                    if player and brainrot then
                        local ogStatus = isOG(tostring(brainrot))
                        logSpawn(tostring(player), tostring(brainrot), ogStatus)
                    end
                end
            end
        end)
    end)
end

-- Method 3: Watch PlayerGui for spawn notifications
conns[#conns+1] = PG.DescendantAdded:Connect(function(d)
    task.wait(0.15)
    if not state.running then return end
    pcall(function()
        if not d or not d.Parent then return end
        if d:IsDescendantOf(screenGui) then return end

        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local text = d.Text or ""
            if text == "" then return end

            -- check for spawn/claim notifications
            local player, brainrot = text:match("(%w+)%s+claimed%s+(.+)")
            if not player then
                player, brainrot = text:match("(%w+)%s+got%s+(.+)")
            end
            if not player then
                player, brainrot = text:match("(%w+)%s+found%s+(.+)")
            end
            if not player then
                player, brainrot = text:match("(%w+)%s+obtained%s+(.+)")
            end
            -- SAB specific patterns
            if not player then
                player, brainrot = text:match("(%w+)%s+stole%s+(.+)")
            end

            if player and brainrot then
                brainrot = brainrot:gsub("!", ""):gsub("%.$", "")
                local ogStatus = isOG(brainrot)
                logSpawn(player, brainrot, ogStatus)
            end
        end
    end)
end)

-- Method 4: Watch chat for spawn messages
pcall(function()
    local tcs = game:GetService("TextChatService")
    local chs = tcs:FindFirstChild("TextChannels")
    if chs then
        for _, ch in pairs(chs:GetChildren()) do
            pcall(function()
                if ch:IsA("TextChannel") then
                    local c = ch.MessageReceived:Connect(function(msg)
                        pcall(function()
                            local text = msg.Text or ""
                            local player, brainrot = text:match("(%w+)%s+claimed%s+(.+)")
                            if not player then
                                player, brainrot = text:match("(%w+)%s+got%s+(.+)")
                            end
                            if player and brainrot then
                                brainrot = brainrot:gsub("!", ""):gsub("%.$", "")
                                local ogStatus = isOG(brainrot)
                                logSpawn(player, brainrot, ogStatus)
                            end
                        end)
                    end)
                    conns[#conns+1] = c
                end
            end)
        end
    end
end)

-- ════════════════════ CROSS-SERVER: Global Feed Detection ════════════════════

-- Method 5: Deep-scan the game's native live feed GUI
-- SAB has a built-in global live feed that shows claims from ALL servers.
-- We find it by searching PlayerGui for ScrollingFrames with claim text.

local globalFeedFrames = {} -- track which game GUI frames we're watching

local function parseClaimText(text)
    if not text or text == "" then return nil, nil end
    -- SAB claim patterns
    local player, brainrot = text:match("(.+)%s+stole%s+(.+)")
    if not player then player, brainrot = text:match("(.+)%s+claimed%s+(.+)") end
    if not player then player, brainrot = text:match("(.+)%s+got%s+(.+)") end
    if not player then player, brainrot = text:match("(.+)%s+found%s+(.+)") end
    if not player then player, brainrot = text:match("(.+)%s+obtained%s+(.+)") end
    if not player then player, brainrot = text:match("(.+)%s+caught%s+(.+)") end
    if not player then player, brainrot = text:match("(.+)%s+grabbed%s+(.+)") end
    if player and brainrot then
        player = player:gsub("^%s+", ""):gsub("%s+$", "")
        brainrot = brainrot:gsub("!", ""):gsub("%.$", ""):gsub("^%s+", ""):gsub("%s+$", "")
        return player, brainrot
    end
    return nil, nil
end

local function watchGlobalFeedFrame(frame)
    if globalFeedFrames[frame] then return end
    globalFeedFrames[frame] = true

    -- scrape existing entries in the frame
    pcall(function()
        for _, child in pairs(frame:GetDescendants()) do
            pcall(function()
                if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Text and child.Text ~= "" then
                    local txt = child.Text
                    if not knownGlobalTexts[txt] then
                        knownGlobalTexts[txt] = true
                        local player, brainrot = parseClaimText(txt)
                        if player and brainrot then
                            local ogStatus = isOG(brainrot)
                            logSpawn(player, brainrot, ogStatus, "GLOBAL")
                        end
                    end
                end
            end)
        end
    end)

    -- watch for new entries
    local c = frame.DescendantAdded:Connect(function(child)
        task.wait(0.1)
        if not state.running then return end
        pcall(function()
            if not child or not child.Parent then return end
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local txt = child.Text or ""
                -- also watch for text property changes (game may set text after creation)
                local textConn
                textConn = child:GetPropertyChangedSignal("Text"):Connect(function()
                    pcall(function()
                        local t = child.Text
                        if t and t ~= "" and not knownGlobalTexts[t] then
                            knownGlobalTexts[t] = true
                            local player, brainrot = parseClaimText(t)
                            if player and brainrot then
                                local ogStatus = isOG(brainrot)
                                logSpawn(player, brainrot, ogStatus, "GLOBAL")
                            end
                        end
                    end)
                end)
                conns[#conns+1] = textConn

                if txt ~= "" and not knownGlobalTexts[txt] then
                    knownGlobalTexts[txt] = true
                    local player, brainrot = parseClaimText(txt)
                    if player and brainrot then
                        local ogStatus = isOG(brainrot)
                        logSpawn(player, brainrot, ogStatus, "GLOBAL")
                    end
                end
            end
        end)
    end)
    conns[#conns+1] = c
end

local function scanForGlobalFeed()
    pcall(function()
        for _, gui in pairs(PG:GetChildren()) do
            pcall(function()
                if gui:IsA("ScreenGui") and gui ~= screenGui then
                    -- look for scrolling frames that contain claim text
                    for _, desc in pairs(gui:GetDescendants()) do
                        pcall(function()
                            if desc:IsA("ScrollingFrame") and not globalFeedFrames[desc] then
                                -- check if this frame has claim text children
                                local hasClaims = false
                                for _, child in pairs(desc:GetChildren()) do
                                    if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") then
                                        local txt = ""
                                        if child:IsA("TextLabel") or child:IsA("TextButton") then
                                            txt = child.Text or ""
                                        else
                                            -- check child's text children
                                            for _, sub in pairs(child:GetChildren()) do
                                                if (sub:IsA("TextLabel") or sub:IsA("TextButton")) and sub.Text and sub.Text ~= "" then
                                                    txt = sub.Text
                                                    break
                                                end
                                            end
                                        end
                                        if txt:find("stole") or txt:find("claimed") or txt:find("got") or txt:find("caught") or txt:find("grabbed") then
                                            hasClaims = true
                                            break
                                        end
                                    end
                                end
                                if hasClaims then
                                    watchGlobalFeedFrame(desc)
                                end
                            end
                        end)
                    end
                end
            end)
        end
    end)
end

-- Method 6: Hook EVERY RemoteEvent under Net + RS (don't guess names)
-- SAB remotes live under RS.Packages.Net — we hook ALL of them and filter
-- for data that looks like brainrot spawn/claim events from any server.
local hookedRemotes = {} -- dedup so we don't double-hook

local function tryExtractSpawnData(arg)
    if type(arg) == "string" then
        local player, brainrot = parseClaimText(arg)
        if player and brainrot then
            local key = player .. ":" .. brainrot
            if not knownGlobalTexts[key] then
                knownGlobalTexts[key] = true
                logSpawn(player, brainrot, isOG(brainrot), "GLOBAL")
            end
        end
    elseif type(arg) == "table" then
        -- try every common key pattern SAB might use
        local player = arg.Player or arg.player or arg.PlayerName or arg.playerName
                    or arg.username or arg.Username or arg.Name or arg.name
                    or arg.Owner or arg.owner or arg.User or arg.user
        local brainrot = arg.Brainrot or arg.brainrot or arg.BrainrotName or arg.brainrotName
                      or arg.item or arg.Item or arg.ItemName or arg.itemName
                      or arg.Pet or arg.pet or arg.PetName or arg.petName
                      or arg.Creature or arg.creature
        if player and brainrot and tostring(player) ~= tostring(brainrot) then
            local key = tostring(player) .. ":" .. tostring(brainrot)
            if not knownGlobalTexts[key] then
                knownGlobalTexts[key] = true
                logSpawn(tostring(player), tostring(brainrot), isOG(tostring(brainrot)), "GLOBAL")
            end
        end
        -- also recurse into nested tables (some games nest data)
        for k, v in pairs(arg) do
            if type(v) == "string" then
                local p2, b2 = parseClaimText(v)
                if p2 and b2 then
                    local key2 = p2 .. ":" .. b2
                    if not knownGlobalTexts[key2] then
                        knownGlobalTexts[key2] = true
                        logSpawn(p2, b2, isOG(b2), "GLOBAL")
                    end
                end
            end
        end
    end
end

local function hookRemoteEvent(remote)
    if hookedRemotes[remote] then return end
    if remote == remotes.notify then return end -- already hooked in Method 2
    hookedRemotes[remote] = true
    pcall(function()
        local c = remote.OnClientEvent:Connect(function(...)
            if not state.running then return end
            local evArgs = {...}
            pcall(function()
                for _, arg in pairs(evArgs) do
                    tryExtractSpawnData(arg)
                end
            end)
        end)
        conns[#conns+1] = c
    end)
end

-- hook everything under Net
pcall(function()
    if Net then
        for _, d in pairs(Net:GetDescendants()) do
            pcall(function()
                if d:IsA("RemoteEvent") then hookRemoteEvent(d) end
            end)
        end
        -- watch for new remotes added later
        local nc = Net.DescendantAdded:Connect(function(d)
            task.wait(0.1)
            pcall(function()
                if d:IsA("RemoteEvent") then hookRemoteEvent(d) end
            end)
        end)
        conns[#conns+1] = nc
    end
end)

-- hook everything directly under RS too
pcall(function()
    for _, d in pairs(RS:GetDescendants()) do
        pcall(function()
            if d:IsA("RemoteEvent") then hookRemoteEvent(d) end
        end)
    end
    local rc = RS.DescendantAdded:Connect(function(d)
        task.wait(0.1)
        pcall(function()
            if d:IsA("RemoteEvent") then hookRemoteEvent(d) end
        end)
    end)
    conns[#conns+1] = rc
end)

-- Method 6b: Systematic ALL-SERVER scanner via Roblox Games API
-- Fetches server list, teleports to each, scans for OGs, hops to next.
-- Builds globalOGDB across every server over time.
local serverScanState = {
    scanning = false,
    visited = {},   -- jobId -> true
    queue = {},     -- server entries to visit
    lastFetch = 0,
    cursor = nil,
}

local function fetchServerList()
    local reqFn = request or http_request or (syn and syn.request) or (http and http.request)
    if not reqFn then return {} end
    local servers = {}
    local cursor = ""
    -- fetch up to 3 pages (300 servers)
    for page = 1, 3 do
        local ok2, resp = pcall(function()
            return reqFn({
                Url = "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/0?sortOrder=2&excludeFullGames=true&limit=100" .. (cursor ~= "" and ("&cursor=" .. cursor) or ""),
                Method = "GET",
                Headers = {["Content-Type"] = "application/json"}
            })
        end)
        if ok2 and resp and resp.Body then
            local ok3, data = pcall(function() return HttpService:JSONDecode(resp.Body) end)
            if ok3 and data and data.data then
                for _, s in pairs(data.data) do
                    if s.id and s.id ~= game.JobId and s.playing and s.playing > 0 then
                        table.insert(servers, s)
                    end
                end
                cursor = data.nextPageCursor or ""
                if cursor == "" then break end
            else break end
        else break end
    end
    return servers
end

-- auto-scan loop: when serverHop is enabled, systematically visit servers
spawn(function()
    task.wait(5)
    while state.running do
        if state.serverHop and not serverScanState.scanning then
            serverScanState.scanning = true
            pcall(function()
                -- fetch fresh server list
                local servers = fetchServerList()
                local unvisited = {}
                for _, s in pairs(servers) do
                    if not serverScanState.visited[s.id] then
                        table.insert(unvisited, s)
                    end
                end
                -- sort by player count (more players = more likely OGs)
                table.sort(unvisited, function(a, b) return (a.playing or 0) > (b.playing or 0) end)
                addLogEntry(liveScroll, "• [" .. os.date("%H:%M:%S") .. "] Found " .. #servers .. " servers (" .. #unvisited .. " unvisited)", Color3.fromRGB(100, 180, 255), false)
                if #unvisited > 0 then
                    -- mark current server as visited before hopping
                    serverScanState.visited[game.JobId] = true
                    local pick = unvisited[1]
                    addLogEntry(liveScroll, "• [" .. os.date("%H:%M:%S") .. "] Hopping → server " .. string.sub(pick.id, 1, 8) .. "... (" .. (pick.playing or "?") .. " players)", Color3.fromRGB(100, 180, 255), false)
                    task.wait(2) -- let the log show before teleporting
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(PLACE_ID, pick.id, LP)
                    end)
                else
                    -- all servers visited, reset and wait
                    addLogEntry(liveScroll, "• [" .. os.date("%H:%M:%S") .. "] All " .. #servers .. " servers scanned — resetting in 60s", Theme.ogGold, false)
                    serverScanState.visited = {}
                    task.wait(60)
                end
            end)
            serverScanState.scanning = false
        end
        task.wait(10)
    end
end)

-- Method 7: Watch for new ScreenGuis with live feeds (game may load GUI later)
conns[#conns+1] = PG.ChildAdded:Connect(function(gui)
    task.wait(1) -- let GUI populate
    if not state.running then return end
    pcall(function()
        if gui:IsA("ScreenGui") and gui ~= screenGui then
            -- scan this new GUI for feed frames
            for _, desc in pairs(gui:GetDescendants()) do
                pcall(function()
                    if desc:IsA("ScrollingFrame") and not globalFeedFrames[desc] then
                        local hasClaims = false
                        for _, child in pairs(desc:GetDescendants()) do
                            if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Text then
                                local txt = child.Text
                                if txt:find("stole") or txt:find("claimed") or txt:find("got") or txt:find("caught") then
                                    hasClaims = true
                                    break
                                end
                            end
                        end
                        if hasClaims then
                            watchGlobalFeedFrame(desc)
                        end
                    end
                end)
            end

            -- also watch this GUI for future feed frames
            gui.DescendantAdded:Connect(function(desc)
                task.wait(0.5)
                if not state.running then return end
                pcall(function()
                    if desc:IsA("ScrollingFrame") and not globalFeedFrames[desc] then
                        task.wait(1)
                        local hasClaims = false
                        for _, child in pairs(desc:GetDescendants()) do
                            if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Text then
                                local txt = child.Text
                                if txt:find("stole") or txt:find("claimed") or txt:find("got") or txt:find("caught") then
                                    hasClaims = true
                                    break
                                end
                            end
                        end
                        if hasClaims then
                            watchGlobalFeedFrame(desc)
                        end
                    end
                end)
            end)
        end
    end)
end)

-- ════════════════════ MAIN LOOPS ════════════════════

-- periodic workspace scan
spawn(function()
    while state.running do
        scanForBrainrots()
        -- clean up destroyed brainrots from known list
        for obj, _ in pairs(knownBrainrots) do
            if not obj or not obj.Parent then
                knownBrainrots[obj] = nil
            end
        end
        task.wait(2)
    end
end)

-- periodic global feed scanner (re-check for game's live feed GUI every 10s)
spawn(function()
    task.wait(2)
    while state.running do
        scanForGlobalFeed()
        task.wait(10)
    end
end)

-- active OG player scanner (rescan every 3s to find who has OGs)
spawn(function()
    task.wait(1.5)
    while state.running do
        pcall(refreshOGPlayers)
        task.wait(3)
    end
end)

-- stats updater
spawn(function()
    while state.running do
        pcall(function()
            local elapsed = os.clock() - startTime
            local mins = math.floor(elapsed / 60)
            local secs = math.floor(elapsed % 60)
            local trackedCount = 0
            for _ in pairs(trackedUsers) do trackedCount = trackedCount + 1 end
            local feedCount = 0
            for _ in pairs(globalFeedFrames) do feedCount = feedCount + 1 end
            statsDetailLbl.Text = "OG: " .. state.ogCaught .. "  |  Scanned: " .. state.totalScanned .. "  |  Global: " .. state.globalEvents
            statsUptimeLbl.Text = "Uptime: " .. mins .. "m " .. secs .. "s  |  Feeds: " .. feedCount .. "  |  Tracked: " .. trackedCount
        end)
        task.wait(5)
    end
end)

-- auto server hop is now handled by the systematic scanner in Method 6b
-- when serverHop is enabled, it fetches ALL servers and visits them one by one
-- (see "Systematic ALL-SERVER scanner" above)

-- auto fleece processor
spawn(function()
    while state.running do
        if state.autoFleece and #fleeceQueue > 0 then
            local target = table.remove(fleeceQueue, 1)
            pcall(function()
                local targetPlayer = Players:FindFirstChild(target.player)
                if targetPlayer then
                    if remotes.tradeSend then
                        remotes.tradeSend:FireServer(targetPlayer)
                    elseif remotes.tradeSendRF then
                        remotes.tradeSendRF:InvokeServer(targetPlayer)
                    elseif remotes.tradeSearch then
                        remotes.tradeSearch:InvokeServer(target.player)
                    end
                end
            end)
        end
        task.wait(3)
    end
end)

-- do initial scan on load
spawn(function()
    task.wait(1)
    scanForBrainrots()
    scanForGlobalFeed()
    pcall(refreshOGPlayers)
    addLogEntry(liveScroll, "• [" .. os.date("%H:%M:%S") .. "] OG Sniper active — scanning all servers...", Theme.success, false)
    if liveWaiting.Visible then liveWaiting.Visible = false end
end)

-- ════════════════════ CLEANUP ════════════════════
_G.OGSniperStop = function()
    state.running = false
    for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() screenGui:Destroy() end)
end

print("[OG SNIPER] PhantomHub OG Sniper loaded — " .. remoteCount .. " remotes found")

end) -- end pcall

if not ok then
    warn("[OG SNIPER] ERROR: " .. tostring(err))
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "OGSniperError"
        sg.ResetOnSpawn = false
        sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.8, 0, 0, 50)
        lbl.Position = UDim2.new(0.1, 0, 0.4, 0)
        lbl.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamBold
        lbl.TextWrapped = true
        lbl.Text = "[OG SNIPER ERROR] " .. tostring(err)
        lbl.Parent = sg
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
        task.delay(15, function() pcall(function() sg:Destroy() end) end)
    end)
end

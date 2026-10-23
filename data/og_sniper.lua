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
    autoFleece   = false,
    autoTrack    = true,
    soundAlerts  = true,
    serverHop    = false,
}

local trackedUsers = {}   -- {username = true}
local ogLog = {}          -- {timestamp, playerName, brainrotName, isOG}
local liveLog = {}        -- all spawn events
local fleeceQueue = {}    -- players to auto-trade
local knownBrainrots = {} -- already-seen brainrot instances (avoid dupes)
local conns = {}          -- connections for cleanup

-- ════════════════════ OG BRAINROT LIST ════════════════════
-- these are considered rare/OG — user can add more via TRACK tab
local OG_LIST = {
    -- headless tier
    ["headless horseman"] = true,
    ["headless"] = true,
    -- korblox tier
    ["korblox"] = true,
    ["korblox deathspeaker"] = true,
    -- dominus tier
    ["dominus"] = true,
    ["dominus empyreus"] = true,
    ["dominus frigidus"] = true,
    ["dominus infernus"] = true,
    ["dominus aureus"] = true,
    ["dominus messor"] = true,
    ["dominus rex"] = true,
    ["dominus praefectus"] = true,
    -- mythic tier
    ["clockwork"] = true,
    ["clockwork headphones"] = true,
    ["valkyrie"] = true,
    ["valkyrie helm"] = true,
    ["dark valkyrie"] = true,
    -- event/limited
    ["icicle"] = true,
    ["iceberg"] = true,
    ["rainbow"] = true,
    ["rainbow brainrot"] = true,
    ["golden"] = true,
    ["golden brainrot"] = true,
    ["diamond"] = true,
    ["void"] = true,
    ["cosmic"] = true,
    ["galaxy"] = true,
    ["celestial"] = true,
    ["phantom"] = true,
    ["shadow"] = true,
    ["inferno"] = true,
    ["frost"] = true,
    ["dragon"] = true,
    ["hydra"] = true,
    ["titan"] = true,
    ["leviathan"] = true,
    ["pumpkin king"] = true,
    ["grim reaper"] = true,
    -- custom additions stored here at runtime
}

local customOGs = {} -- user-added OG names

local function isOG(name)
    if not name then return false end
    local lower = name:lower()
    if OG_LIST[lower] then return true end
    if customOGs[lower] then return true end
    -- partial match for rarity keywords
    for _, keyword in ipairs({"headless", "korblox", "dominus", "golden", "rainbow", "void", "cosmic", "galaxy", "titan", "dragon", "celestial", "phantom", "mythic", "legendary", "divine", "eternal", "omega"}) do
        if lower:find(keyword) then return true end
    end
    return false
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
    -- try to find trade send/invite remotes
    remotes.tradeSend    = findRE("TradeService/Send") or findRE("TradeService/Invite") or findRE("TradeService/Request")
    remotes.tradeSendRF  = findRF("TradeService/Send") or findRF("TradeService/Invite") or findRF("TradeService/Request")
    remotes.plotSell     = findRE("PlotService/Sell")
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
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -8, 0, 0)
    entry.AutomaticSize = Enum.AutomaticSize.Y
    entry.BackgroundColor3 = isOGEntry and Color3.fromRGB(30, 25, 10) or Theme.bgCard
    entry.BorderSizePixel = 0
    entry.ZIndex = 3
    entry.LayoutOrder = -os.clock() * 1000 -- newest first
    entry.Parent = scroll
    corner(entry, 6)

    if isOGEntry then
        stroke(entry, Theme.ogGold, 1)
    end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 0)
    lbl.Position = UDim2.new(0, 6, 0, 4)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.RobotoMono
    lbl.TextSize = 11
    lbl.TextColor3 = color or Theme.textMuted
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Text = text
    lbl.ZIndex = 4
    lbl.TextTransparency = 1
    lbl.Parent = entry

    -- fade in
    entry.BackgroundTransparency = 1
    TweenService:Create(entry, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = isOGEntry and 0 or 0 }):Play()
    TweenService:Create(lbl, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
    if isOGEntry then
        local s = entry:FindFirstChildWhichIsA("UIStroke")
        if s then s.Transparency = 1; TweenService:Create(s, TweenInfo.new(0.35), { Transparency = 0 }):Play() end
    end

    pad(entry, 0, 0, 2, 6)

    -- cap entries
    local children = scroll:GetChildren()
    local count = 0
    for _, c in pairs(children) do
        if c:IsA("Frame") then count = count + 1 end
    end
    if count > 150 then
        -- remove oldest
        local oldest = nil
        local oldestOrder = math.huge
        for _, c in pairs(children) do
            if c:IsA("Frame") and c.LayoutOrder < oldestOrder then
                oldestOrder = c.LayoutOrder
                oldest = c
            end
        end
        if oldest then oldest:Destroy() end
    end

    return entry
end

-- ════════════════════ PAGE: LIVE ════════════════════
local pageLive = Instance.new("Frame")
pageLive.Size = UDim2.new(1, 0, 1, 0)
pageLive.BackgroundTransparency = 1
pageLive.ZIndex = 2
pageLive.Parent = content
pages["Live"] = pageLive

local liveHeader = makeLabel(pageLive, {
    text = "LIVE FEED", font = Enum.Font.GothamBold, size = 12,
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
    text = "waiting for spawns...", font = Enum.Font.Gotham, size = 12,
    color = Theme.textMuted, align = Enum.TextXAlignment.Center,
    sz = UDim2.new(1, 0, 0, 30), pos = UDim2.new(0, 0, 0.4, 0), z = 4
})

-- ════════════════════ PAGE: OG ════════════════════
local pageOG = Instance.new("Frame")
pageOG.Size = UDim2.new(1, 0, 1, 0)
pageOG.BackgroundTransparency = 1
pageOG.ZIndex = 2
pageOG.Visible = false
pageOG.Parent = content
pages["OG"] = pageOG

local ogHeader = makeLabel(pageOG, {
    text = "OG FEED", font = Enum.Font.GothamBold, size = 12,
    color = Theme.ogGold, sz = UDim2.new(0.5, 0, 0, 20), pos = UDim2.new(0, 0, 0, 0)
})

-- OG brainrot cards row
local ogCardsFrame = Instance.new("Frame")
ogCardsFrame.Size = UDim2.new(1, 0, 0, 72)
ogCardsFrame.Position = UDim2.new(0, 0, 0, 24)
ogCardsFrame.BackgroundTransparency = 1
ogCardsFrame.ClipsDescendants = true
ogCardsFrame.ZIndex = 2
ogCardsFrame.Parent = pageOG

local ogCardsScroll = Instance.new("ScrollingFrame")
ogCardsScroll.Size = UDim2.new(1, 0, 1, 0)
ogCardsScroll.BackgroundTransparency = 1
ogCardsScroll.ScrollBarThickness = 0
ogCardsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ogCardsScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
ogCardsScroll.ScrollingDirection = Enum.ScrollingDirection.X
ogCardsScroll.BorderSizePixel = 0
ogCardsScroll.ZIndex = 3
ogCardsScroll.Parent = ogCardsFrame

local ogCardsLayout = Instance.new("UIListLayout")
ogCardsLayout.FillDirection = Enum.FillDirection.Horizontal
ogCardsLayout.Padding = UDim.new(0, 8)
ogCardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
ogCardsLayout.Parent = ogCardsScroll

-- OG log feed below cards
local ogLogFrame = Instance.new("Frame")
ogLogFrame.Size = UDim2.new(1, 0, 1, -104)
ogLogFrame.Position = UDim2.new(0, 0, 0, 104)
ogLogFrame.BackgroundTransparency = 1
ogLogFrame.ZIndex = 2
ogLogFrame.Parent = pageOG

local ogScroll, ogList = makeScrollFeed(ogLogFrame)

local ogWaiting = makeLabel(ogLogFrame, {
    text = "waiting for logs...", font = Enum.Font.Gotham, size = 12,
    color = Theme.textMuted, align = Enum.TextXAlignment.Center,
    sz = UDim2.new(1, 0, 0, 30), pos = UDim2.new(0, 0, 0.3, 0), z = 4
})

local function addOGCard(playerName, brainrotName)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 80, 0, 64)
    card.BackgroundColor3 = Theme.bgCard
    card.BorderSizePixel = 0
    card.ZIndex = 4
    card.LayoutOrder = -os.clock() * 1000
    card.Parent = ogCardsScroll
    corner(card, 8)
    stroke(card, Theme.ogGold, 1)

    -- player thumbnail
    local thumb = Instance.new("ImageLabel")
    thumb.Size = UDim2.new(0, 32, 0, 32)
    thumb.Position = UDim2.new(0.5, -16, 0, 4)
    thumb.BackgroundColor3 = Theme.accentDim
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 5
    thumb.Parent = card
    corner(thumb, 6)

    -- try to load player thumbnail
    pcall(function()
        local plr = Players:FindFirstChild(playerName)
        if plr then
            local userId = plr.UserId
            thumb.Image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end
    end)

    -- brainrot name (truncated)
    local shortName = brainrotName
    if #shortName > 8 then shortName = shortName:sub(1, 7) .. "." end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -4, 0, 14)
    nameLabel.Position = UDim2.new(0, 2, 0, 38)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 8
    nameLabel.TextColor3 = Theme.white
    nameLabel.Text = shortName:upper()
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 5
    nameLabel.Parent = card

    -- player name
    local pLabel = Instance.new("TextLabel")
    pLabel.Size = UDim2.new(1, -4, 0, 12)
    pLabel.Position = UDim2.new(0, 2, 0, 50)
    pLabel.BackgroundTransparency = 1
    pLabel.Font = Enum.Font.Gotham
    pLabel.TextSize = 7
    pLabel.TextColor3 = Theme.textMuted
    pLabel.Text = playerName
    pLabel.TextTruncate = Enum.TextTruncate.AtEnd
    pLabel.ZIndex = 5
    pLabel.Parent = card

    -- fade in card
    card.BackgroundTransparency = 1
    nameLabel.TextTransparency = 1
    pLabel.TextTransparency = 1
    TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(nameLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
    TweenService:Create(pLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
    local cardStroke = card:FindFirstChildWhichIsA("UIStroke")
    if cardStroke then cardStroke.Transparency = 1; TweenService:Create(cardStroke, TweenInfo.new(0.3), { Transparency = 0 }):Play() end
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
    text = "TRACKED USERS", font = Enum.Font.GothamBold, size = 12,
    color = Theme.text, sz = UDim2.new(1, 0, 0, 20), pos = UDim2.new(0, 0, 0, 0)
})

-- add user row
local trackAddRow = Instance.new("Frame")
trackAddRow.Size = UDim2.new(1, 0, 0, 34)
trackAddRow.Position = UDim2.new(0, 0, 0, 24)
trackAddRow.BackgroundTransparency = 1
trackAddRow.ZIndex = 3
trackAddRow.Parent = pageTrack

local trackInput = Instance.new("TextBox")
trackInput.Size = UDim2.new(1, -80, 1, 0)
trackInput.BackgroundColor3 = Theme.bgCard
trackInput.Font = Enum.Font.Gotham
trackInput.TextSize = 12
trackInput.TextColor3 = Theme.text
trackInput.PlaceholderText = "Enter username..."
trackInput.PlaceholderColor3 = Theme.textMuted
trackInput.Text = ""
trackInput.ClearTextOnFocus = false
trackInput.ZIndex = 4
trackInput.Parent = trackAddRow
corner(trackInput, 6)
stroke(trackInput, Theme.stroke, 1)
pad(trackInput, 8, 8, 0, 0)

local trackAddBtn = Instance.new("TextButton")
trackAddBtn.Size = UDim2.new(0, 70, 1, 0)
trackAddBtn.Position = UDim2.new(1, -70, 0, 0)
trackAddBtn.BackgroundColor3 = Theme.accent
trackAddBtn.Font = Enum.Font.GothamBold
trackAddBtn.TextSize = 11
trackAddBtn.TextColor3 = Theme.bg
trackAddBtn.Text = "TRACK"
trackAddBtn.AutoButtonColor = false
trackAddBtn.ZIndex = 4
trackAddBtn.Parent = trackAddRow
corner(trackAddBtn, 6)
hoverFx(trackAddBtn, Theme.accent, Theme.accentHover)

-- tracked users list
local trackListFrame = Instance.new("Frame")
trackListFrame.Size = UDim2.new(1, 0, 1, -64)
trackListFrame.Position = UDim2.new(0, 0, 0, 64)
trackListFrame.BackgroundTransparency = 1
trackListFrame.ZIndex = 2
trackListFrame.Parent = pageTrack

local trackScroll, trackList = makeScrollFeed(trackListFrame)
local trackEmpty = makeLabel(trackListFrame, {
    text = "no users tracked yet", font = Enum.Font.Gotham, size = 11,
    color = Theme.textMuted, align = Enum.TextXAlignment.Center,
    sz = UDim2.new(1, 0, 0, 20), pos = UDim2.new(0, 0, 0.3, 0), z = 4
})

local function refreshTrackList()
    for _, c in pairs(trackScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local hasAny = false
    for username, _ in pairs(trackedUsers) do
        hasAny = true
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 30)
        row.BackgroundColor3 = Theme.bgCard
        row.BorderSizePixel = 0
        row.ZIndex = 3
        row.Parent = trackScroll
        corner(row, 6)

        local userLbl = Instance.new("TextLabel")
        userLbl.Size = UDim2.new(1, -40, 1, 0)
        userLbl.Position = UDim2.new(0, 8, 0, 0)
        userLbl.BackgroundTransparency = 1
        userLbl.Font = Enum.Font.GothamBold
        userLbl.TextSize = 11
        userLbl.TextColor3 = Theme.text
        userLbl.TextXAlignment = Enum.TextXAlignment.Left
        userLbl.Text = username
        userLbl.ZIndex = 4
        userLbl.Parent = row

        local removeBtn = Instance.new("TextButton")
        removeBtn.Size = UDim2.new(0, 24, 0, 24)
        removeBtn.Position = UDim2.new(1, -28, 0.5, -12)
        removeBtn.BackgroundColor3 = Theme.danger
        removeBtn.Font = Enum.Font.GothamBold
        removeBtn.TextSize = 10
        removeBtn.TextColor3 = Theme.white
        removeBtn.Text = "X"
        removeBtn.AutoButtonColor = false
        removeBtn.ZIndex = 4
        removeBtn.Parent = row
        corner(removeBtn, 4)

        removeBtn.MouseButton1Click:Connect(function()
            trackedUsers[username] = nil
            refreshTrackList()
        end)
    end

    trackEmpty.Visible = not hasAny
end

trackAddBtn.MouseButton1Click:Connect(function()
    local name = trackInput.Text:gsub("%s+", "")
    if name ~= "" then
        trackedUsers[name] = true
        trackInput.Text = ""
        refreshTrackList()
    end
end)

refreshTrackList()

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
makeSettingRow("Auto Server Hop", "serverHop", 3)

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
hopNowBtn.LayoutOrder = 4
hopNowBtn.Parent = settingsScroll
corner(hopNowBtn, 8)
hoverFx(hopNowBtn, Theme.accentDim, Theme.accent)

hopNowBtn.MouseButton1Click:Connect(function()
    hopNowBtn.Text = "HOPPING..."
    spawn(function()
        pcall(function()
            local reqFn = request or http_request or (syn and syn.request)
            if reqFn then
                local resp = reqFn({
                    Url = "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/0?sortOrder=2&excludeFullGames=true&limit=100",
                    Method = "GET",
                    Headers = {["Content-Type"] = "application/json"}
                })
                local data = HttpService:JSONDecode(resp.Body)
                if data and data.data then
                    local candidates = {}
                    for _, s in pairs(data.data) do
                        if s.id ~= game.JobId and s.playing and s.playing > 3 then
                            table.insert(candidates, s)
                        end
                    end
                    if #candidates > 0 then
                        local pick = candidates[math.random(1, #candidates)]
                        TeleportService:TeleportToPlaceInstance(PLACE_ID, pick.id, LP)
                    end
                end
            else
                TeleportService:Teleport(PLACE_ID, LP)
            end
        end)
    end)
end)

-- stats row
local statsRow = Instance.new("Frame")
statsRow.Size = UDim2.new(1, -8, 0, 60)
statsRow.BackgroundColor3 = Theme.bgCard
statsRow.BorderSizePixel = 0
statsRow.ZIndex = 3
statsRow.LayoutOrder = 5
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
remoteLbl.LayoutOrder = 6
remoteLbl.Parent = settingsScroll
corner(remoteLbl, 6)

makeLabel(remoteLbl, {
    text = remoteCount .. " remotes loaded  |  Trade: " .. (remotes.tradeSend and "YES" or (remotes.tradeSendRF and "YES" or "SEARCH")),
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

local function logSpawn(playerName, brainrotName, isOGSpawn)
    local timestamp = os.date("%H:%M:%S")
    liveEventCount = liveEventCount + 1

    -- hide waiting text
    if liveWaiting.Visible then liveWaiting.Visible = false end

    -- add to live feed
    local prefix = isOGSpawn and "★ " or "• "
    local color = isOGSpawn and Theme.ogGold or Theme.textMuted
    local text = prefix .. "[" .. timestamp .. "] " .. playerName .. " → " .. brainrotName
    addLogEntry(liveScroll, text, color, isOGSpawn)
    liveCountLabel.Text = liveEventCount .. " events"

    -- if OG, add to OG feed and card
    if isOGSpawn then
        state.ogCaught = state.ogCaught + 1
        caughtLabel.Text = state.ogCaught .. " caught"

        if ogWaiting.Visible then ogWaiting.Visible = false end
        addLogEntry(ogScroll, "★ [" .. timestamp .. "] " .. playerName .. " claimed " .. brainrotName, Theme.ogGold, true)
        addOGCard(playerName, brainrotName)

        -- add to fleece queue if auto-fleece is on
        if state.autoFleece then
            table.insert(fleeceQueue, {player = playerName, brainrot = brainrotName})
            addFleeceEntry(playerName, brainrotName)
        end

        -- check if tracked user
        if trackedUsers[playerName] then
            addLogEntry(liveScroll, "⚡ TRACKED USER " .. playerName .. " GOT OG: " .. brainrotName, Theme.success, true)
        end
    end

    -- store in log tables
    table.insert(liveLog, {time = timestamp, player = playerName, brainrot = brainrotName, og = isOGSpawn})
    if isOGSpawn then
        table.insert(ogLog, {time = timestamp, player = playerName, brainrot = brainrotName})
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

-- stats updater
spawn(function()
    while state.running do
        pcall(function()
            local elapsed = os.clock() - startTime
            local mins = math.floor(elapsed / 60)
            local secs = math.floor(elapsed % 60)
            statsDetailLbl.Text = "OG Caught: " .. state.ogCaught .. "  |  Scanned: " .. state.totalScanned .. "  |  Tracked: " .. (function()
                local c = 0
                for _ in pairs(trackedUsers) do c = c + 1 end
                return c
            end)()
            statsUptimeLbl.Text = "Uptime: " .. mins .. "m " .. secs .. "s  |  Server: " .. game.JobId:sub(1, 12) .. "..."
        end)
        task.wait(5)
    end
end)

-- auto server hop (every 5 minutes if enabled)
spawn(function()
    while state.running do
        if state.serverHop then
            task.wait(300) -- 5 min
            if state.serverHop and state.running then
                pcall(function()
                    local reqFn = request or http_request or (syn and syn.request)
                    if reqFn then
                        local resp = reqFn({
                            Url = "https://games.roblox.com/v1/games/" .. PLACE_ID .. "/servers/0?sortOrder=2&excludeFullGames=true&limit=100",
                            Method = "GET",
                            Headers = {["Content-Type"] = "application/json"}
                        })
                        local data = HttpService:JSONDecode(resp.Body)
                        if data and data.data then
                            local candidates = {}
                            for _, s in pairs(data.data) do
                                if s.id ~= game.JobId and s.playing and s.playing > 3 then
                                    table.insert(candidates, s)
                                end
                            end
                            if #candidates > 0 then
                                local pick = candidates[math.random(1, #candidates)]
                                TeleportService:TeleportToPlaceInstance(PLACE_ID, pick.id, LP)
                            end
                        end
                    else
                        TeleportService:Teleport(PLACE_ID, LP)
                    end
                end)
            end
        else
            task.wait(5)
        end
    end
end)

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
    addLogEntry(liveScroll, "• [" .. os.date("%H:%M:%S") .. "] OG Sniper active — scanning server...", Theme.success, false)
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

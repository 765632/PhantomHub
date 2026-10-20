-- PhantomHub (Potassium-compatible)
-- Removed: Riddle Solver (HTTP), firesignal/getconns calls, exploit-only APIs
-- Kept: GUI, Code Phantom, Auto Submit, Auto Riddler, Anti Lag, Anti Die, Anti Ragdoll, Anchored, Auto Buy

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local Theme = {
    bg = Color3.fromRGB(10, 10, 10),
    bgDark = Color3.fromRGB(5, 5, 5),
    bgCard = Color3.fromRGB(18, 18, 18),
    stroke = Color3.fromRGB(40, 40, 40),
    accent = Color3.fromRGB(255, 255, 255),
    accentHover = Color3.fromRGB(220, 220, 220),
    accentDim = Color3.fromRGB(60, 60, 60),
    text = Color3.fromRGB(245, 245, 245),
    textMuted = Color3.fromRGB(140, 140, 140),
    white = Color3.fromRGB(255, 255, 255),
    toggleOff = Color3.fromRGB(35, 35, 35),
    toggleOn = Color3.fromRGB(255, 255, 255),
}

local COL_WHITE = Color3.fromRGB(245, 245, 245)
local COL_ON = Color3.fromRGB(120, 255, 160)

local TweenFast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenMed = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local state = {
    guiSize = 100,
    minimized = false,
    currentTab = "Main",
    antiDieToggled = false,
    antiLagToggled = false,
    antiRagdollToggled = false,
    codeSniperToggled = false,
    autoSubmitToggled = false,
    locked = false,
    autoBuyToggled = false,
    riddlerToggled = false,
    riddlerAutoRedeem = true,
}

local _autoAccept = true
local _submitAfter = 3
local _capturedParts = {}
local _lastBox = nil
local _redeemCooldown = 0

-- ======================== UI HELPERS ========================
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

local function padding(parent, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = parent
    return p
end

local function hover(btn, normal, hoverCol)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenFast, { BackgroundColor3 = hoverCol }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenFast, { BackgroundColor3 = normal }):Play()
    end)
end

-- ======================== CLEANUP OLD GUI ========================
for _, g in ipairs(PlayerGui:GetChildren()) do
    if g.Name == "PhantomHubGui" then g:Destroy() end
end

-- ======================== SCREEN GUI ========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PhantomHubGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

-- ======================== MAIN FRAME ========================
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.new(0, 320, 0, 460)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = Theme.bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Active = true
main.Parent = screenGui
corner(main, 14)
stroke(main, Theme.stroke, 1.5)

-- ======================== TITLE BAR ========================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
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

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 160, 0, 20)
titleLabel.Position = UDim2.new(0, 14, 0.5, -10)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 15
titleLabel.TextColor3 = Theme.text
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "PHANTOMHUB"
titleLabel.ZIndex = 3
titleLabel.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -84, 0.5, -12)
minBtn.BackgroundColor3 = Theme.bgCard
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.TextColor3 = Theme.text
minBtn.Text = "-"
minBtn.AutoButtonColor = false
minBtn.ZIndex = 3
minBtn.Parent = titleBar
corner(minBtn, 6)
hover(minBtn, Theme.bgCard, Theme.accentDim)

local lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.new(0, 24, 0, 24)
lockBtn.Position = UDim2.new(1, -56, 0.5, -12)
lockBtn.BackgroundColor3 = Theme.bgCard
lockBtn.Font = Enum.Font.GothamBold
lockBtn.TextSize = 12
lockBtn.TextColor3 = Theme.text
lockBtn.Text = "L"
lockBtn.AutoButtonColor = false
lockBtn.ZIndex = 3
lockBtn.Parent = titleBar
corner(lockBtn, 6)
hover(lockBtn, Theme.bgCard, Theme.accentDim)

lockBtn.MouseButton1Click:Connect(function()
    state.locked = not state.locked
    if state.locked then
        lockBtn.Text = "X"
        lockBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
        lockBtn.TextColor3 = Theme.bg
    else
        lockBtn.Text = "L"
        lockBtn.BackgroundColor3 = Theme.bgCard
        lockBtn.TextColor3 = Theme.text
    end
end)

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
hover(closeBtn, Theme.bgCard, Color3.fromRGB(180, 50, 70))

closeBtn.MouseButton1Click:Connect(function()
    stopRiddler()
    stopSniper()
    screenGui:Destroy()
end)

-- ======================== TAB BAR ========================
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -24, 0, 32)
tabBar.Position = UDim2.new(0, 12, 0, 50)
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
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabBar
padding(tabBar, 4, 4, 4, 4)

local tabs = {}
local pages = {}

local function makeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, -4, 1, 0)
    btn.BackgroundColor3 = Theme.bgDark
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Theme.textMuted
    btn.Text = name
    btn.AutoButtonColor = false
    btn.ZIndex = 3
    btn.Parent = tabBar
    corner(btn, 6)
    tabs[name] = btn
    return btn
end

local tabMain = makeTab("Main")
local tabLogs = makeTab("Logs")
local tabUtilis = makeTab("Utilis")
local tabSettings = makeTab("Settings")

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

tabMain.MouseButton1Click:Connect(function() setTab("Main") end)
tabLogs.MouseButton1Click:Connect(function() setTab("Logs") end)
tabUtilis.MouseButton1Click:Connect(function() setTab("Utilis") end)
tabSettings.MouseButton1Click:Connect(function() setTab("Settings") end)

-- ======================== CONTENT AREA ========================
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 1, -140)
content.Position = UDim2.new(0, 12, 0, 90)
content.BackgroundTransparency = 1
content.ZIndex = 2
content.Parent = main

-- ======================== LOG SYSTEM ========================
local logEntries = {}
local MAX_LOG_LINES = 80
local _logScroll = nil
local _logList = nil
local _logCount = 0

local function pushLog(text, color)
    if not _logScroll then
        table.insert(logEntries, { text = text, color = color or Color3.fromRGB(140, 140, 150) })
        return
    end
    _logCount = _logCount + 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(140, 140, 150)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.LayoutOrder = _logCount
    lbl.ZIndex = 5
    lbl.Parent = _logScroll

    -- Trim old entries
    local children = _logScroll:GetChildren()
    local labels = {}
    for _, c in ipairs(children) do
        if c:IsA("TextLabel") then labels[#labels + 1] = c end
    end
    while #labels > MAX_LOG_LINES do
        labels[1]:Destroy()
        table.remove(labels, 1)
    end

    -- Auto-scroll to bottom
    task.defer(function()
        if _logScroll then
            _logScroll.CanvasPosition = Vector2.new(0, _logScroll.AbsoluteCanvasSize.Y)
        end
    end)
end

-- ======================== CODE SNIPER HELPERS ========================
local function isOurGui(instance)
    local p = instance
    for _ = 1, 10 do
        if not p then break end
        if p.Name == "PhantomHubGui" then return true end
        p = p.Parent
    end
    return false
end

local function isVisibleChain(inst)
    local current = inst
    while current do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") then return current.Enabled end
        current = current.Parent
    end
    return true
end

local function findAllTextBoxes(pg)
    local boxes = {}
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, d in ipairs(gui:GetDescendants()) do
                if d:IsA("TextBox") and not isOurGui(d) then
                    boxes[#boxes+1] = d
                end
            end
        end
    end
    return boxes
end

local function clickButton(btn)
    if not btn then return false end
    local anyOk = false

    -- Method 1: direct Fire
    anyOk = pcall(function() btn.MouseButton1Click:Fire() end) or anyOk
    anyOk = pcall(function() btn.Activated:Fire() end) or anyOk

    -- Method 2: firesignal (most exploits)
    if typeof(firesignal) == "function" then
        anyOk = pcall(firesignal, btn.MouseButton1Click) or anyOk
        anyOk = pcall(firesignal, btn.Activated) or anyOk
    end

    -- Method 3: getconnections / getconns
    local gc = typeof(getconnections) == "function" and getconnections or typeof(getconns) == "function" and getconns or nil
    if gc then
        pcall(function()
            for _, c in ipairs(gc(btn.MouseButton1Click)) do pcall(function() c:Fire() end) end
            for _, c in ipairs(gc(btn.Activated)) do pcall(function() c:Fire() end) end
        end)
        anyOk = true
    end

    -- Method 4: fireclick
    if typeof(fireclick) == "function" then
        anyOk = pcall(fireclick, btn) or anyOk
    end

    return anyOk
end

local function fireBoxFocusLost(box)
    if not box then return false end
    local anyOk = false

    -- direct Fire
    anyOk = pcall(function() box.FocusLost:Fire(true) end) or anyOk

    -- firesignal
    if typeof(firesignal) == "function" then
        anyOk = pcall(firesignal, box.FocusLost, true) or anyOk
    end

    -- getconnections
    local gc = typeof(getconnections) == "function" and getconnections or typeof(getconns) == "function" and getconns or nil
    if gc then
        pcall(function()
            for _, c in ipairs(gc(box.FocusLost)) do pcall(function() c:Fire(true) end) end
        end)
        anyOk = true
    end

    return anyOk
end

local function aceCodeBox()
    local pg = PlayerGui
    local allBoxes = findAllTextBoxes(pg)
    for _, box in ipairs(allBoxes) do
        if isVisibleChain(box) then return box end
    end
    return nil
end

local function typeAndSubmitCode(code)
    local pg = PlayerGui
    if not pg then return false, "no PlayerGui" end

    local codesGui = pg:FindFirstChild("Codes")
    if codesGui then
        if codesGui:IsA("ScreenGui") then codesGui.Enabled = true end
        local codesFrame = codesGui:FindFirstChild("Codes") or codesGui
        if codesFrame then
            if codesFrame:IsA("GuiObject") then codesFrame.Visible = true end
            local cur = codesFrame
            while cur and cur ~= codesGui do
                if cur:IsA("GuiObject") then cur.Visible = true end
                cur = cur.Parent
            end

            local box = nil
            for _, d in ipairs(codesFrame:GetDescendants()) do
                if d:IsA("TextBox") and not isOurGui(d) then
                    box = d
                    break
                end
            end

            local submitBtn = nil
            for _, d in ipairs(codesFrame:GetDescendants()) do
                if (d:IsA("TextButton") or d:IsA("ImageButton")) and not isOurGui(d) then
                    local n = d.Name:lower()
                    local txt = ""
                    pcall(function() txt = d.Text:lower() end)
                    if n:find("submit") or txt:find("submit") or n:find("redeem") or txt:find("redeem") or n:find("claim") or txt:find("confirm") or n:find("enter") then
                        submitBtn = d
                        break
                    end
                end
            end
            if not submitBtn then
                for _, d in ipairs(codesFrame:GetDescendants()) do
                    if (d:IsA("TextButton") or d:IsA("ImageButton")) and not isOurGui(d) then
                        local n = d.Name:lower()
                        if not n:find("close") and not n:find("x") and not n:find("toggle") then
                            submitBtn = d
                            break
                        end
                    end
                end
            end

            if box then
                pcall(function() box.Text = code end)
                task.wait(0.05)
                if submitBtn then clickButton(submitBtn) end
                fireBoxFocusLost(box)
                return true, "submitted via Codes"
            end
        end
    end

    -- fallback: search all visible textboxes
    task.wait(0.2)
    local box = nil
    local deadline = tick() + 2
    while tick() < deadline do
        local allBoxes = findAllTextBoxes(pg)
        for _, d in ipairs(allBoxes) do
            if isVisibleChain(d) then
                local n = d.Name:lower()
                local pn = (d.Parent and d.Parent.Name or ""):lower()
                if n:find("code") or pn:find("code") or n:find("redeem") or pn:find("redeem") or n:find("input") then
                    box = d
                    break
                end
            end
        end
        if not box then
            for _, d in ipairs(allBoxes) do
                if isVisibleChain(d) then box = d; break end
            end
        end
        if box then break end
        task.wait(0.1)
    end

    if not box then return false, "no codebox found" end

    pcall(function() box.Text = code end)
    task.wait(0.05)

    local redeemBtn = nil
    local searchNames = {"submit","redeem","claim","confirm","enter","send","apply","ok","use","go","check"}
    local p = box.Parent
    for _ = 1, 8 do
        if not p then break end
        for _, d in ipairs(p:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and not isOurGui(d) and d ~= box then
                local n = d.Name:lower()
                local txt = ""
                pcall(function() txt = d.Text:lower() end)
                for _, sn in ipairs(searchNames) do
                    if n:find(sn) or txt:find(sn) then
                        if isVisibleChain(d) then
                            redeemBtn = d
                            break
                        end
                    end
                end
                if redeemBtn then break end
            end
        end
        if redeemBtn then break end
        p = p.Parent
    end

    if redeemBtn then clickButton(redeemBtn) end
    fireBoxFocusLost(box)
    return true, "submitted via search"
end

local _appendTimer = nil

local function appendToBox(text)
    if not text or text == "" then return end

    -- Skip if same as last captured part (dedup)
    if #_capturedParts > 0 and _capturedParts[#_capturedParts] == text then return end

    local box = aceCodeBox()
    _capturedParts[#_capturedParts + 1] = text
    local combinedCode = table.concat(_capturedParts)
    local capturedCount = #_capturedParts

    if box then
        _lastBox = box
        box.Text = combinedCode
    end

    pushLog("> [" .. tostring(capturedCount) .. "/" .. tostring(_submitAfter) .. "] " .. text .. " = " .. combinedCode, COL_ON)

    if capturedCount >= _submitAfter then
        -- Full code assembled â€” submit now
        _capturedParts = {}
        _appendTimer = nil
        if _autoAccept then
            _redeemCooldown = tick()
            task.spawn(function()
                local ok, statusMsg = typeAndSubmitCode(combinedCode)
                if ok then
                    pushLog("> REDEEMED: " .. combinedCode, Color3.fromRGB(120, 255, 160))
                else
                    pushLog("> failed: " .. tostring(statusMsg), Color3.fromRGB(255, 90, 90))
                end
            end)
        end
    else
        -- Stale buffer clear: if no new section arrives within 15s, discard (don't submit partial)
        local id = tick()
        _appendTimer = id
        task.delay(15, function()
            if _appendTimer == id and #_capturedParts > 0 then
                pushLog("> buffer expired (" .. table.concat(_capturedParts) .. ")", Color3.fromRGB(255, 200, 80))
                _capturedParts = {}
                _appendTimer = nil
            end
        end)
    end
end

-- ======================== RIDDLER CORE ========================
local httpRequest = (typeof(syn) == "table" and syn.request) or (typeof(http_request) == "function" and http_request) or (typeof(request) == "function" and request) or (typeof(http) == "table" and http.request) or nil
local env = typeof(getgenv) == "function" and getgenv() or _G
local getupvalues = (debug and (debug.getupvalues or debug.getupvalue)) or nil

local function stripRich(s)
    if type(s) ~= "string" then return tostring(s) end
    return (s:gsub("<[^>]->", ""))
end

local function trim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- SAB knowledge base
local SAB_DB = {
    ["name"] = "SAMMY",
    ["my name"] = "SAMMY",
    ["real name"] = "SAMMY",
    ["sammy real name"] = "SAMMY",
    ["sammys real name"] = "SAMMY",
    ["my real name"] = "SAMMY",
    ["creator name"] = "SAMMY",
    ["creator real name"] = "SAMMY",
    ["owner"] = "SAMMY",
    ["creator"] = "SAMMY",
    ["owner real name"] = "SAMMY",
    ["who is the owner"] = "SAMMY",
    ["who owns sab"] = "SAMMY",
    ["who created sab"] = "SAMMY",
    ["who made sab"] = "SAMMY",
    ["who made steal a brainrot"] = "SAMMY",
    ["what is my real full name in real life"] = "SAMBRAKTA",
    ["roblox"] = "SPYDERSAMMY",
    ["roblox name"] = "SPYDERSAMMY",
    ["roblox username"] = "SPYDERSAMMY",
    ["my roblox username"] = "SPYDERSAMMY",
    ["username"] = "SPYDERSAMMY",
    ["my username"] = "SPYDERSAMMY",
    ["sammy username"] = "SPYDERSAMMY",
    ["sammy roblox name"] = "SPYDERSAMMY",
    ["youtube"] = "SPYDERSAMMY",
    ["my youtube"] = "SPYDERSAMMY",
    ["sammy youtube"] = "SPYDERSAMMY",
    ["youtube channel"] = "SPYDERSAMMY",
    ["social media"] = "YOUTUBE",
    ["age"] = "24",
    ["my age"] = "24",
    ["sammy age"] = "24",
    ["how old am i"] = "24",
    ["how old is sammy"] = "24",
    ["birth year"] = "2002",
    ["year born"] = "2002",
    ["born year"] = "2002",
    ["year i was born"] = "2002",
    ["birth day"] = "FRIDAY",
    ["day born"] = "FRIDAY",
    ["day i was born"] = "FRIDAY",
    ["birthday"] = "FRIDAY",
    ["born on"] = "FRIDAY",
    ["birth month"] = "FEBRUARY",
    ["month born"] = "FEBRUARY",
    ["month i was born"] = "FEBRUARY",
    ["location"] = "BRAZIL",
    ["country"] = "BRAZIL",
    ["where do i live"] = "BRAZIL",
    ["where does sammy live"] = "BRAZIL",
    ["sammy location"] = "BRAZIL",
    ["where is sammy from"] = "BRAZIL",
    ["my country"] = "ALGERIA",
    ["sammy country"] = "ALGERIA",
    ["where am i from"] = "ALGERIA",
    ["where was i born"] = "ALGERIA",
    ["where was i born at"] = "ALGERIA",
    ["birthplace"] = "ALGERIA",
    ["where i was born"] = "UNITEDSTATES",
    ["nationality"] = "BRAZILIAN",
    ["my nationality"] = "BRAZILIAN",
    ["sammy nationality"] = "BRAZILIAN",
    ["state"] = "SAOPAULO",
    ["my state"] = "SAOPAULO",
    ["sammy state"] = "SAOPAULO",
    ["city"] = "SAOPAULO",
    ["my city"] = "SAOPAULO",
    ["sammy city"] = "SAOPAULO",
    ["color"] = "BLUE",
    ["my color"] = "BLUE",
    ["sammy color"] = "BLUE",
    ["favorite color"] = "BLUE",
    ["favourite color"] = "BLUE",
    ["fav color"] = "BLUE",
    ["sport"] = "FOOTBALL",
    ["my sport"] = "FOOTBALL",
    ["favorite sport"] = "FOOTBALL",
    ["fav sport"] = "FOOTBALL",
    ["football"] = "FOOTBALL",
    ["player"] = "RONALDO",
    ["favorite player"] = "RONALDO",
    ["fav player"] = "RONALDO",
    ["football player"] = "RONALDO",
    ["favorite football player"] = "RONALDO",
    ["fav football player"] = "RONALDO",
    ["ronaldo"] = "RONALDO",
    ["food"] = "PIZZA",
    ["my food"] = "PIZZA",
    ["favorite food"] = "PIZZA",
    ["fav food"] = "PIZZA",
    ["animal"] = "SPIDER",
    ["my animal"] = "SPIDER",
    ["my pet"] = "SPIDER",
    ["favorite animal"] = "SPIDER",
    ["fav animal"] = "SPIDER",
    ["game"] = "ROBLOX",
    ["favorite game"] = "ROBLOX",
    ["fav game"] = "ROBLOX",
    ["number"] = "SEVEN",
    ["favorite number"] = "SEVEN",
    ["fav number"] = "SEVEN",
    ["lucky number"] = "SEVEN",
    ["cat"] = "NOVA",
    ["cat name"] = "NOVA",
    ["my cat name"] = "NOVA",
    ["my cats name"] = "NOVA",
    ["what is my cats name"] = "NOVA",
    ["game name"] = "STEALABRAINROT",
    ["name of the game"] = "STEALABRAINROT",
    ["what is the name of the game"] = "STEALABRAINROT",
    ["full name"] = "STEALABRAINROT",
    ["sab"] = "STEALABRAINROT",
    ["sab stands for"] = "STEALABRAINROT",
    ["type of game"] = "SIMULATOR",
    ["game genre"] = "SIMULATOR",
    ["maximum server size"] = "EIGHT",
    ["max server size"] = "EIGHT",
    ["server size"] = "EIGHT",
    ["players"] = "EIGHT",
    ["created on"] = "FRIDAY",
    ["game created on"] = "FRIDAY",
    ["release month"] = "MAY",
    ["month sab was made"] = "MAY",
    ["release year"] = "2025",
    ["year created"] = "2025",
    ["year sab was created"] = "2025",
    ["year the game was created"] = "2025",
    ["year the game was made"] = "2025",
    ["day sab was made"] = "FRIDAY",
    ["when was sab made"] = "MAY162025",
    ["when made"] = "MAY162025",
    ["date made"] = "MAY162025",
    ["when was sab created"] = "MAY162025",
    ["release date"] = "MAY162025",
    ["when was sab released"] = "MAY162025",
    ["game release date"] = "MAY162025",
    ["first update"] = "MUTATIONS",
    ["update"] = "MUTATIONS",
    ["trait"] = "LIGHTNING",
    ["first trait"] = "LIGHTNING",
    ["1st trait"] = "LIGHTNING",
    ["lightning"] = "MATEO",
    ["lightning trait"] = "MATEO",
    ["struck by lightning"] = "MATEO",
    ["trait you get when struck by lightning"] = "MATEO",
    ["first mutation"] = "GOLD",
    ["mutation 1"] = "GOLD",
    ["second mutation"] = "DIAMOND",
    ["mutation 2"] = "DIAMOND",
    ["third mutation"] = "BLOODROT",
    ["mutation 3"] = "BLOODROT",
    ["fourth mutation"] = "RAINBOW",
    ["mutation 4"] = "RAINBOW",
    ["fifth mutation"] = "CANDY",
    ["mutation 5"] = "CANDY",
    ["sixth mutation"] = "LAVA",
    ["mutation 6"] = "LAVA",
    ["seventh mutation"] = "GALAXY",
    ["mutation 7"] = "GALAXY",
    ["eighth mutation"] = "YINYANG",
    ["mutation 8"] = "YINYANG",
    ["ninth mutation"] = "RADIOACTIVE",
    ["mutation 9"] = "RADIOACTIVE",
    ["tenth mutation"] = "CURSED",
    ["mutation 10"] = "CURSED",
    ["eleventh mutation"] = "DIVINE",
    ["mutation 11"] = "DIVINE",
    ["twelfth mutation"] = "CYBER",
    ["mutation 12"] = "CYBER",
    ["thirteenth mutation"] = "PHANTOM",
    ["mutation 13"] = "PHANTOM",
    ["fourteenth mutation"] = "CRYSTAL",
    ["mutation 14"] = "CRYSTAL",
    ["fifteenth mutation"] = "ECLIPSE",
    ["mutation 15"] = "ECLIPSE",
    ["evil"] = "CURSED",
    ["evil mutation"] = "CURSED",
    ["cursed mutation"] = "CURSED",
    ["angelic"] = "DIVINE",
    ["angelic mutation"] = "DIVINE",
    ["divine mutation"] = "DIVINE",
    ["good mutation"] = "DIVINE",
    ["best mutation"] = "ECLIPSE",
    ["top mutation"] = "ECLIPSE",
    ["latest mutation"] = "ECLIPSE",
    ["newest mutation"] = "ECLIPSE",
    ["highest mutation"] = "ECLIPSE",
    ["strongest mutation"] = "ECLIPSE",
    ["highest multiplier mutation"] = "ECLIPSE",
    ["eclipse"] = "ECLIPSE",
    ["eclipse mutation"] = "ECLIPSE",
    ["halloween mutation"] = "ECLIPSE",
    ["14x mutation"] = "ECLIPSE",
    ["14x"] = "ECLIPSE",
    ["divinecursed"] = "DIVINECURSED",
    ["curseddivine"] = "CURSEDDIVINE",
    ["green"] = "RADIOACTIVE",
    ["green mutation"] = "RADIOACTIVE",
    ["purple"] = "GALAXY",
    ["purple mutation"] = "GALAXY",
    ["black and white mutation"] = "YINYANG",
    ["yellow mutation"] = "DIVINE",
    ["red mutation"] = "CURSED",
    ["orange mutation"] = "LAVA",
    ["dark mutation"] = "ECLIPSE",
    ["moon mutation"] = "ECLIPSE",
    ["crystal mutation"] = "CRYSTAL",
    ["phantom mutation"] = "PHANTOM",
    ["cyber mutation"] = "CYBER",
    ["number of mutations"] = "15",
    ["total mutations"] = "FIFTEEN",
    ["how many mutations"] = "15",
    ["how many mutations are there"] = "15",

    -- ===== MUTATION MULTIPLIERS =====
    ["gold multiplier"] = "1.25",
    ["diamond multiplier"] = "1.5",
    ["bloodrot multiplier"] = "2",
    ["rainbow multiplier"] = "10",
    ["candy multiplier"] = "4",
    ["lava multiplier"] = "6",
    ["galaxy multiplier"] = "7",
    ["yin yang multiplier"] = "7.5",
    ["yinyang multiplier"] = "7.5",
    ["radioactive multiplier"] = "8.5",
    ["cursed multiplier"] = "9",
    ["divine multiplier"] = "10",
    ["cyber multiplier"] = "11",
    ["phantom multiplier"] = "12",
    ["crystal multiplier"] = "13",
    ["eclipse multiplier"] = "14",
    ["highest multiplier"] = "14",
    ["best multiplier"] = "14",
    ["max multiplier"] = "14",

    -- ===== MUTATION EVENTS =====
    ["bloodrot event"] = "BLOODMOON",
    ["candy event"] = "CANDYEVENT",
    ["lava event"] = "MOLTENEVENT",
    ["galaxy event"] = "GALACTICEVENT",
    ["yin yang event"] = "YINYANGEVENT",
    ["radioactive event"] = "RADIOACTIVEEVENT",
    ["cursed event"] = "CURSEDEVENT",
    ["divine event"] = "DIVINEEVENT",
    ["cyber event"] = "CYBEREVENT",
    ["phantom event"] = "PHANTOMEVENT",
    ["crystal event"] = "CRYSTALEVENT",
    ["eclipse event"] = "HALLOWEENEVENT",

    -- ===== MUTATION RARITY TIERS =====
    ["gold mutation rarity"] = "COMMON",
    ["diamond mutation rarity"] = "COMMON",
    ["bloodrot mutation rarity"] = "RARE",
    ["candy mutation rarity"] = "RARE",
    ["lava mutation rarity"] = "RARE",
    ["galaxy mutation rarity"] = "RARE",
    ["yin yang mutation rarity"] = "RARE",
    ["radioactive mutation rarity"] = "RARE",
    ["cursed mutation rarity"] = "LEGENDARY",
    ["divine mutation rarity"] = "LEGENDARY",
    ["rainbow mutation rarity"] = "LEGENDARY",
    ["cyber mutation rarity"] = "LEGENDARY",
    ["phantom mutation rarity"] = "MYTHIC",
    ["crystal mutation rarity"] = "MYTHIC",
    ["eclipse mutation rarity"] = "MYTHIC",
    ["first machine"] = "RAINBOWMACHINE",
    ["machine 1"] = "RAINBOWMACHINE",
    ["second machine"] = "BUBBLEGUMMACHINE",
    ["machine 2"] = "BUBBLEGUMMACHINE",
    ["third machine"] = "FUSEMACHINE",
    ["machine 3"] = "FUSEMACHINE",
    ["fourth machine"] = "CRAFTMACHINE",
    ["machine 4"] = "CRAFTMACHINE",
    ["fifth machine"] = "WITCHFUSE",
    ["machine 5"] = "WITCHFUSE",
    ["sixth machine"] = "BRAINROTDEALER",
    ["machine 6"] = "BRAINROTDEALER",
    ["seventh machine"] = "BRAINROTTRADER",
    ["machine 7"] = "BRAINROTTRADER",
    ["eighth machine"] = "SANTASFUSE",
    ["machine 8"] = "SANTASFUSE",
    ["ninth machine"] = "SANTASSHOP",
    ["machine 9"] = "SANTASSHOP",
    ["tenth machine"] = "NEWYEARSMACHINE",
    ["machine 10"] = "NEWYEARSMACHINE",
    ["eleventh machine"] = "DUELSMACHINE",
    ["machine 11"] = "DUELSMACHINE",
    ["twelfth machine"] = "CUPIDSMACHINE",
    ["machine 12"] = "CUPIDSMACHINE",
    ["thirteenth machine"] = "TRADEMACHINE",
    ["machine 13"] = "TRADEMACHINE",
    ["fourteenth machine"] = "DIVINEFUSE",
    ["machine 14"] = "DIVINEFUSE",
    ["fifteenth machine"] = "EGGINCUBATOR",
    ["machine 15"] = "EGGINCUBATOR",
    ["sixteenth machine"] = "CYBERCRAFTMACHINE",
    ["machine 16"] = "CYBERCRAFTMACHINE",
    ["seventeenth machine"] = "SUMMERFUSE",
    ["machine 17"] = "SUMMERFUSE",
    ["eighteenth machine"] = "LOSTRADERS",
    ["machine 18"] = "LOSTRADERS",
    ["nineteenth machine"] = "RNGMACHINE",
    ["machine 19"] = "RNGMACHINE",
    ["twentieth machine"] = "HAUNTEDFUSE",
    ["machine 20"] = "HAUNTEDFUSE",
    ["newest machine"] = "HAUNTEDFUSE",
    ["latest machine"] = "HAUNTEDFUSE",
    ["number of machines"] = "20",
    ["total machines"] = "TWENTY",
    ["how many machines"] = "20",
    ["how many machines are there"] = "20",

    -- ===== MACHINE DETAILS =====
    ["rng machine"] = "RNGMACHINE",
    ["what is the rng machine"] = "RNGMACHINE",
    ["haunted fuse"] = "HAUNTEDFUSE",
    ["what is the haunted fuse"] = "HAUNTEDFUSE",
    ["halloween machine"] = "HAUNTEDFUSE",
    ["halloween fuse"] = "HAUNTEDFUSE",
    ["what update added haunted fuse"] = "69",
    ["haunted fuse update"] = "69",
    ["what update is haunted fuse"] = "69",
    ["cyber craft machine"] = "CYBERCRAFTMACHINE",
    ["what replaced divine fuse"] = "CYBERCRAFTMACHINE",
    ["divine fuse replacement"] = "CYBERCRAFTMACHINE",
    ["summer fuse"] = "SUMMERFUSE",
    ["los traders"] = "LOSTRADERS",
    ["fuse machine"] = "FUSEMACHINE",
    ["craft machine"] = "CRAFTMACHINE",
    ["witch fuse"] = "WITCHFUSE",
    ["brainrot dealer"] = "BRAINROTDEALER",
    ["brainrot trader"] = "BRAINROTTRADER",
    ["santas fuse"] = "SANTASFUSE",
    ["santas shop"] = "SANTASSHOP",
    ["new years machine"] = "NEWYEARSMACHINE",
    ["duels machine"] = "DUELSMACHINE",
    ["cupids machine"] = "CUPIDSMACHINE",
    ["trade machine"] = "TRADEMACHINE",
    ["divine fuse"] = "DIVINEFUSE",
    ["egg incubator"] = "EGGINCUBATOR",
    ["rainbow machine"] = "RAINBOWMACHINE",
    ["bubblegum machine"] = "BUBBLEGUMMACHINE",
    ["headless horseman"] = "HEADLESSHORSEMAN",
    ["og brainrot cannot be obtained"] = "HEADLESSHORSEMAN",
    ["unobtainable brainrot"] = "HEADLESSHORSEMAN",
    ["rarest brainrot"] = "POLAROIDINI",
    ["best brainrot"] = "STRAWBERRYELEPHANT",
    ["worst brainrot"] = "NOOBINIPIZZANINI",
    ["most popular brainrot"] = "DRAGONCANNELONNI",
    ["most common brainrot"] = "NOOBINIPIZZANINI",
    ["first brainrot added"] = "STRAWBERRYELEPHANT",
    ["oldest brainrot"] = "STRAWBERRYELEPHANT",
    ["first og added"] = "STRAWBERRYELEPHANT",
    ["second og added"] = "MEOWL",
    ["third og added"] = "SKIBIDITOILET",
    ["fifth og added"] = "JOHNPORK",
    ["og 1"] = "STRAWBERRYELEPHANT",
    ["og 2"] = "MEOWL",
    ["og 3"] = "SKIBIDITOILET",
    ["og 5"] = "JOHNPORK",
    ["highest rarity"] = "OG",
    ["rarest rarity"] = "OG",
    ["top rarity"] = "OG",
    ["lowest rarity"] = "COMMON",
    ["worst rarity"] = "COMMON",
    ["common"] = "COMMON",
    ["uncommon"] = "UNCOMMON",
    ["rare"] = "RARE",
    ["epic"] = "EPIC",
    ["legendary"] = "LEGENDARY",
    ["og"] = "OG",
    ["1st rarity"] = "COMMON",
    ["2nd rarity"] = "UNCOMMON",
    ["3rd rarity"] = "RARE",
    ["4th rarity"] = "EPIC",
    ["5th rarity"] = "LEGENDARY",
    ["6th rarity"] = "OG",
    ["total rarities"] = "SIX",
    ["how many rarities"] = "SIX",
    ["fire"] = "DRAGON",
    ["dragon"] = "DRAGON",
    ["fire represents"] = "DRAGON",
    ["brother"] = "CERBERUS",
    ["cerberus"] = "CERBERUS",
    ["brother of hydra bunny"] = "CERBERUS",
    ["won the world cup"] = "SPAIN",
    ["world cup"] = "SPAIN",
    ["who won the 2026 world cup"] = "SPAIN",
    ["worst game owner"] = "SECRETLOKII",
    ["most boring game on roblox"] = "KEYBOARDESCAPE",
    ["spawned during admin abuse war"] = "RACOONINIJANDELINI",
    ["who did i fight in the admin abuse war"] = "JANDEL",
    ["who won the admin war"] = "JANDEL",
    ["won the admin abuse war"] = "GROWAGARDEN",
    ["worst secret"] = "KARKERKARKURKUR",
    ["discord"] = "blossom",
    ["discord server"] = "blossom",
    ["how many gold brainrots does the rainbow machine need"] = "25",
    ["where did griffin come from"] = "DIVINEFUSE",
    ["whos a egg"] = "STEAK",
    ["whos the best trait farmer"] = "RUSTYNICKLE40",
    ["who has the most aura"] = "CAYLUS",
    ["how old is steak"] = "25",
    ["whos steaks brother"] = "cruz",
    ["what food does cruz hate"] = "cheese",
    ["what color is my car "] = "RED",
    ["whats the first game i made"] = "CRABGAME",
    ["what do i eat on taco tuesday"] = "TACOS",
    ["whats my name and 67"] = "SAMMY67",
    ["whats the color of the sky and 67"] = "BLUE67",
    ["whats my age plus my name year"] = "24SAMMY2002",
    ["whats the best food duo"] = "PIZZAANDRANCH",
    ["whats the best og"] = "SPYDERELEPHANT",
    ["how much polaroidini are there exist"] = "24",
    ["how much headless horseman exist"] = "79",
    ["whats my name backwards"] = "YMMAS",
    ["whats my cats name backwords"] = "AVON",
    ["whats my name backwards and 67"] = "YMMAS67",
    ["WHAT GAME HAVE I MADE ON FORTNITE"] = "ROBABANK",
    ["whats my favorite brainrot"] = "MEOWL",
    ["when did i began making roblox games"] = "2013",
    ["what element do dragons represent"] = "FIRE",
    ["what animal is tralalero"] = "SHARK",
    ["what season are we in"] = "HALLOWEEN",
    ["whats on my chain"] = "SPIDER",
    ["whats on my left eye"] = "SPIDER",
    ["whats my name short for"] = "SAM",
    ["what is the name of the lead programmer on steal a brainrot"] = "HASTED",
    ["the team that won world cup and scored total"] = "7",
    ["whats my name age and month"] = "SAMMY24FEBRUARY",
    ["where was i born and my age"] = "BRAZIL24",
    ["my first original game plus my age"] = "CRABGAME24",
    ["the month and the day the ninth mutation came out"] = "APRIL18",
    ["how much would los dragons make as rainbow"] = "425000000",
    ["the first trait plus the currency the bee event drops plus how many rebirths"] = "FIREWORKSHONEY19",
    ["my name twice"] = "SAMMYSAMMY",
    ["my name 2 times"] = "SAMMYSAMMY",
    ["my name 3 times"] = "SAMMYSAMMYSAMMY",
    ["owner twice"] = "SAMMYSAMMY",
    ["age twice"] = "2424",
    ["my age twice"] = "2424",
    ["country twice"] = "BRAZILBRAZIL",
    ["food twice"] = "PIZZAPIZZA",
    ["favorite food twice"] = "PIZZAPIZZA",
    ["favorite color twice"] = "BLUEBLUE",
    ["favorite color 3 times"] = "BLUEBLUEBLUE",
    ["favorite color 5 times"] = "BLUEBLUEBLUEBLUEBLUE",
    ["favorite sport twice"] = "FOOTBALLFOOTBALL",
    ["favorite animal twice"] = "SPIDERSPIDER",
    ["favorite player twice"] = "RONALDORONALDO",
    ["rarest brainrot twice"] = "POLAROIDINIPOLAROIDINI",
    ["highest rarity twice"] = "OGOG",
    ["lightning trait twice"] = "MATEOMATEO",
    ["game name twice"] = "STEALABRAINROTSTEALABRAINROT",
    ["discord twice"] = "ACEACE",
    ["favorite number twice"] = "SEVENSEVEN",
    ["cat name twice"] = "NOVANOVA",
    ["cat name 3 times"] = "NOVANOVANOVA",
    ["username twice"] = "SPYDERSAMMYSPYDERSAMMY",

    -- ===== EXPANDED: More creator/personal variations =====
    ["whats my name"] = "SAMMY",
    ["what is sammy"] = "SAMMY",
    ["sammys name"] = "SAMMY",
    ["name of the owner"] = "SAMMY",
    ["name of the creator"] = "SAMMY",
    ["the owner of sab"] = "SAMMY",
    ["the creator of sab"] = "SAMMY",
    ["who is sammy"] = "SAMMY",
    ["who is the creator of sab"] = "SAMMY",
    ["who is the creator of steal a brainrot"] = "SAMMY",
    ["who is the developer"] = "SAMMY",
    ["developer name"] = "SAMMY",
    ["dev name"] = "SAMMY",
    ["full name in real life"] = "SAMBRAKTA",
    ["my full real name"] = "SAMBRAKTA",
    ["sammy full name"] = "SAMBRAKTA",
    ["real full name"] = "SAMBRAKTA",
    ["sammys full name"] = "SAMBRAKTA",
    ["my irl name"] = "SAMBRAKTA",
    ["whats my full name"] = "SAMBRAKTA",
    ["full real name"] = "SAMBRAKTA",
    ["what is my full name"] = "SAMBRAKTA",
    ["sammy real full name"] = "SAMBRAKTA",
    ["what is my irl name"] = "SAMBRAKTA",
    ["whats my age"] = "24",
    ["sammys age"] = "24",
    ["what age am i"] = "24",
    ["the owners age"] = "24",
    ["the creators age"] = "24",
    ["how old is the owner"] = "24",
    ["how old is the creator"] = "24",
    ["owner age"] = "24",
    ["creator age"] = "24",
    ["what year was i born"] = "2002",
    ["what year was sammy born"] = "2002",
    ["sammy birth year"] = "2002",
    ["year of birth"] = "2002",
    ["which year was i born"] = "2002",
    ["what day was i born"] = "FRIDAY",
    ["what day was i born on"] = "FRIDAY",
    ["sammy birth day"] = "FRIDAY",
    ["day of birth"] = "FRIDAY",
    ["day born on"] = "FRIDAY",
    ["what month was i born"] = "FEBRUARY",
    ["what month was i born in"] = "FEBRUARY",
    ["sammy birth month"] = "FEBRUARY",
    ["month of birth"] = "FEBRUARY",
    ["born in which month"] = "FEBRUARY",
    ["where do i live now"] = "BRAZIL",
    ["where i live"] = "BRAZIL",
    ["i live in"] = "BRAZIL",
    ["sammy lives in"] = "BRAZIL",
    ["current country"] = "BRAZIL",
    ["current location"] = "BRAZIL",
    ["what country do i live in"] = "BRAZIL",
    ["where i was born at"] = "ALGERIA",
    ["born in"] = "ALGERIA",
    ["country of birth"] = "ALGERIA",
    ["birth country"] = "ALGERIA",
    ["sammy was born in"] = "ALGERIA",
    ["what country was i born in"] = "ALGERIA",
    ["where was sammy born"] = "ALGERIA",
    ["im from"] = "ALGERIA",
    ["sammy is from"] = "ALGERIA",
    ["born where"] = "ALGERIA",
    ["nationality of sammy"] = "BRAZILIAN",
    ["whats my nationality"] = "BRAZILIAN",
    ["what nationality am i"] = "BRAZILIAN",
    ["what state do i live in"] = "SAOPAULO",
    ["what state"] = "SAOPAULO",
    ["which state"] = "SAOPAULO",
    ["state i live in"] = "SAOPAULO",
    ["what city do i live in"] = "SAOPAULO",
    ["which city"] = "SAOPAULO",
    ["city i live in"] = "SAOPAULO",
    ["whats my roblox username"] = "SPYDERSAMMY",
    ["whats my roblox name"] = "SPYDERSAMMY",
    ["my roblox name"] = "SPYDERSAMMY",
    ["owner roblox username"] = "SPYDERSAMMY",
    ["creator roblox username"] = "SPYDERSAMMY",
    ["sammy roblox username"] = "SPYDERSAMMY",
    ["what is my roblox"] = "SPYDERSAMMY",
    ["what is my username"] = "SPYDERSAMMY",
    ["whats my username"] = "SPYDERSAMMY",
    ["what is my roblox name"] = "SPYDERSAMMY",
    ["youtube name"] = "SPYDERSAMMY",
    ["my youtube channel"] = "SPYDERSAMMY",
    ["youtube channel name"] = "SPYDERSAMMY",
    ["what is my youtube channel"] = "SPYDERSAMMY",
    ["whats my youtube"] = "SPYDERSAMMY",
    ["whats my youtube channel"] = "SPYDERSAMMY",
    ["what social media do i use"] = "YOUTUBE",
    ["what social media"] = "YOUTUBE",
    ["my social media"] = "YOUTUBE",
    ["what platform"] = "YOUTUBE",
    ["main social media"] = "YOUTUBE",

    -- ===== EXPANDED: More favorites =====
    ["whats my favorite color"] = "BLUE",
    ["my fav color"] = "BLUE",
    ["what color do i like"] = "BLUE",
    ["sammys favorite color"] = "BLUE",
    ["owners favorite color"] = "BLUE",
    ["best color"] = "BLUE",
    ["what is my color"] = "BLUE",
    ["whats my color"] = "BLUE",
    ["whats my fav color"] = "BLUE",
    ["whats my favorite sport"] = "FOOTBALL",
    ["what sport do i like"] = "FOOTBALL",
    ["what sport do i play"] = "FOOTBALL",
    ["sammys favorite sport"] = "FOOTBALL",
    ["best sport"] = "FOOTBALL",
    ["whats my sport"] = "FOOTBALL",
    ["what is my sport"] = "FOOTBALL",
    ["soccer"] = "FOOTBALL",
    ["favourite sport"] = "FOOTBALL",
    ["whats my favorite player"] = "RONALDO",
    ["who is my favorite player"] = "RONALDO",
    ["best player"] = "RONALDO",
    ["my fav player"] = "RONALDO",
    ["who is my fav player"] = "RONALDO",
    ["favourite player"] = "RONALDO",
    ["sammys favorite player"] = "RONALDO",
    ["favorite soccer player"] = "RONALDO",
    ["fav soccer player"] = "RONALDO",
    ["whats my favorite food"] = "PIZZA",
    ["what food do i like"] = "PIZZA",
    ["sammys favorite food"] = "PIZZA",
    ["best food"] = "PIZZA",
    ["what is my food"] = "PIZZA",
    ["favourite food"] = "PIZZA",
    ["my fav food"] = "PIZZA",
    ["whats my fav food"] = "PIZZA",
    ["whats my favorite animal"] = "SPIDER",
    ["what animal do i like"] = "SPIDER",
    ["sammys favorite animal"] = "SPIDER",
    ["what is my animal"] = "SPIDER",
    ["favourite animal"] = "SPIDER",
    ["my fav animal"] = "SPIDER",
    ["pet"] = "SPIDER",
    ["favorite pet"] = "SPIDER",
    ["whats my pet"] = "SPIDER",
    ["whats my favorite game"] = "ROBLOX",
    ["what game do i play"] = "ROBLOX",
    ["sammys favorite game"] = "ROBLOX",
    ["favourite game"] = "ROBLOX",
    ["what is my game"] = "ROBLOX",
    ["whats my game"] = "ROBLOX",
    ["whats my favorite number"] = "SEVEN",
    ["what number do i like"] = "SEVEN",
    ["what is my number"] = "SEVEN",
    ["sammys favorite number"] = "SEVEN",
    ["my lucky number"] = "SEVEN",
    ["favourite number"] = "SEVEN",
    ["whats my fav number"] = "SEVEN",
    ["my number"] = "SEVEN",
    ["7"] = "SEVEN",

    -- ===== EXPANDED: Cat =====
    ["whats my cat name"] = "NOVA",
    ["whats the name of my cat"] = "NOVA",
    ["name of my cat"] = "NOVA",
    ["sammys cat"] = "NOVA",
    ["sammys cat name"] = "NOVA",
    ["the cat"] = "NOVA",
    ["the cats name"] = "NOVA",
    ["owners cat name"] = "NOVA",
    ["my pet name"] = "NOVA",
    ["pets name"] = "NOVA",
    ["whats my pets name"] = "NOVA",
    ["what is the name of my cat"] = "NOVA",
    ["what is my pet called"] = "NOVA",
    ["what is my cat called"] = "NOVA",
    ["cat name backwards"] = "AVON",
    ["my cats name backwards"] = "AVON",
    ["nova backwards"] = "AVON",

    -- ===== EXPANDED: Game info =====
    ["what is sab"] = "STEALABRAINROT",
    ["what does sab stand for"] = "STEALABRAINROT",
    ["what is this game called"] = "STEALABRAINROT",
    ["name of this game"] = "STEALABRAINROT",
    ["this game name"] = "STEALABRAINROT",
    ["whats the name of the game"] = "STEALABRAINROT",
    ["whats this game called"] = "STEALABRAINROT",
    ["full game name"] = "STEALABRAINROT",
    ["the game name"] = "STEALABRAINROT",
    ["what type of game is this"] = "SIMULATOR",
    ["what genre"] = "SIMULATOR",
    ["genre"] = "SIMULATOR",
    ["game type"] = "SIMULATOR",
    ["whats the genre"] = "SIMULATOR",
    ["what kind of game"] = "SIMULATOR",
    ["how many players in a server"] = "EIGHT",
    ["max players"] = "EIGHT",
    ["max players in a server"] = "EIGHT",
    ["how many players can be in a server"] = "EIGHT",
    ["max player count"] = "EIGHT",
    ["server capacity"] = "EIGHT",
    ["player limit"] = "EIGHT",
    ["how many people in a server"] = "EIGHT",
    ["8"] = "EIGHT",

    -- ===== EXPANDED: Release dates =====
    ["when was the game created"] = "MAY162025",
    ["when was the game made"] = "MAY162025",
    ["when was this game created"] = "MAY162025",
    ["when was this game made"] = "MAY162025",
    ["when did sab come out"] = "MAY162025",
    ["when did the game come out"] = "MAY162025",
    ["sab release date"] = "MAY162025",
    ["the release date"] = "MAY162025",
    ["date the game was made"] = "MAY162025",
    ["date created"] = "MAY162025",
    ["what date was sab made"] = "MAY162025",
    ["what date was sab created"] = "MAY162025",
    ["game creation date"] = "MAY162025",
    ["day the game was made"] = "FRIDAY",
    ["what day was sab created"] = "FRIDAY",
    ["what day was sab made"] = "FRIDAY",
    ["day the game was created"] = "FRIDAY",
    ["what day was the game created"] = "FRIDAY",
    ["what day was the game made"] = "FRIDAY",
    ["day of sab creation"] = "FRIDAY",
    ["day sab was created"] = "FRIDAY",
    ["day sab was released"] = "FRIDAY",
    ["what month was sab made"] = "MAY",
    ["what month was sab created"] = "MAY",
    ["what month was the game made"] = "MAY",
    ["what month was the game created"] = "MAY",
    ["month game was made"] = "MAY",
    ["month the game was created"] = "MAY",
    ["month game was created"] = "MAY",
    ["month of release"] = "MAY",
    ["what year was the game made"] = "2025",
    ["what year was the game created"] = "2025",
    ["year game was made"] = "2025",
    ["year game was created"] = "2025",
    ["year sab was made"] = "2025",
    ["sab created year"] = "2025",

    -- ===== EXPANDED: Updates/Traits =====
    ["what was the first update"] = "MUTATIONS",
    ["first ever update"] = "MUTATIONS",
    ["update 1"] = "MUTATIONS",
    ["sab first update"] = "MUTATIONS",
    ["the first update"] = "MUTATIONS",
    ["1st update"] = "MUTATIONS",
    ["what was the first trait"] = "LIGHTNING",
    ["the first trait"] = "LIGHTNING",
    ["what trait came first"] = "LIGHTNING",
    ["trait 1"] = "LIGHTNING",
    ["whats the first trait"] = "LIGHTNING",
    ["who has the lightning trait"] = "MATEO",
    ["who got struck by lightning"] = "MATEO",
    ["who was struck by lightning"] = "MATEO",
    ["what brainrot has lightning"] = "MATEO",
    ["lightning brainrot"] = "MATEO",
    ["who got the lightning trait"] = "MATEO",
    ["what brainrot got struck by lightning"] = "MATEO",

    -- ===== EXPANDED: More mutation variations =====
    ["whats the first mutation"] = "GOLD",
    ["whats the second mutation"] = "DIAMOND",
    ["whats the third mutation"] = "BLOODROT",
    ["whats the fourth mutation"] = "RAINBOW",
    ["whats the fifth mutation"] = "CANDY",
    ["whats the sixth mutation"] = "LAVA",
    ["whats the seventh mutation"] = "GALAXY",
    ["whats the eighth mutation"] = "YINYANG",
    ["whats the ninth mutation"] = "RADIOACTIVE",
    ["whats the tenth mutation"] = "CURSED",
    ["whats the eleventh mutation"] = "DIVINE",
    ["whats the twelfth mutation"] = "CYBER",
    ["whats the thirteenth mutation"] = "PHANTOM",
    ["whats the fourteenth mutation"] = "CRYSTAL",
    ["1st mutation"] = "GOLD",
    ["2nd mutation"] = "DIAMOND",
    ["3rd mutation"] = "BLOODROT",
    ["4th mutation"] = "RAINBOW",
    ["5th mutation"] = "CANDY",
    ["6th mutation"] = "LAVA",
    ["7th mutation"] = "GALAXY",
    ["8th mutation"] = "YINYANG",
    ["9th mutation"] = "RADIOACTIVE",
    ["10th mutation"] = "CURSED",
    ["11th mutation"] = "DIVINE",
    ["12th mutation"] = "CYBER",
    ["13th mutation"] = "PHANTOM",
    ["14th mutation"] = "CRYSTAL",
    ["gold mutation"] = "GOLD",
    ["diamond mutation"] = "DIAMOND",
    ["bloodrot mutation"] = "BLOODROT",
    ["rainbow mutation"] = "RAINBOW",
    ["candy mutation"] = "CANDY",
    ["lava mutation"] = "LAVA",
    ["galaxy mutation"] = "GALAXY",
    ["yinyang mutation"] = "YINYANG",
    ["yin yang mutation"] = "YINYANG",
    ["radioactive mutation"] = "RADIOACTIVE",
    ["phantom mutation"] = "PHANTOM",
    ["crystal mutation"] = "CRYSTAL",
    ["cyber mutation"] = "CYBER",
    ["what mutation is gold"] = "GOLD",
    ["what mutation is diamond"] = "DIAMOND",
    ["what mutation is rainbow"] = "RAINBOW",
    ["what mutation is lava"] = "LAVA",
    ["what mutation is galaxy"] = "GALAXY",
    ["what mutation is cursed"] = "CURSED",
    ["what mutation is divine"] = "DIVINE",
    ["what mutation is cyber"] = "CYBER",
    ["what mutation is phantom"] = "PHANTOM",
    ["what mutation is crystal"] = "CRYSTAL",
    ["what is the newest mutation"] = "ECLIPSE",
    ["what is the latest mutation"] = "ECLIPSE",
    ["the newest mutation"] = "ECLIPSE",
    ["the latest mutation"] = "ECLIPSE",
    ["last mutation added"] = "ECLIPSE",
    ["most recent mutation"] = "ECLIPSE",
    ["what is the fifteenth mutation"] = "ECLIPSE",
    ["whats the fifteenth mutation"] = "ECLIPSE",
    ["15th mutation"] = "ECLIPSE",
    ["the evil mutation"] = "CURSED",
    ["the good mutation"] = "DIVINE",
    ["the angelic mutation"] = "DIVINE",
    ["holy mutation"] = "DIVINE",
    ["how many mutations are there"] = "15",
    ["how many mutations"] = "15",
    ["mutation count"] = "15",
    ["total number of mutations"] = "15",
    ["15"] = "FIFTEEN",

    -- ===== EXPANDED: More machine variations =====
    ["whats the first machine"] = "RAINBOWMACHINE",
    ["whats the second machine"] = "BUBBLEGUMMACHINE",
    ["whats the third machine"] = "FUSEMACHINE",
    ["whats the fourth machine"] = "CRAFTMACHINE",
    ["whats the fifth machine"] = "WITCHFUSE",
    ["whats the sixth machine"] = "BRAINROTDEALER",
    ["whats the seventh machine"] = "BRAINROTTRADER",
    ["whats the eighth machine"] = "SANTASFUSE",
    ["whats the ninth machine"] = "SANTASSHOP",
    ["whats the tenth machine"] = "NEWYEARSMACHINE",
    ["1st machine"] = "RAINBOWMACHINE",
    ["2nd machine"] = "BUBBLEGUMMACHINE",
    ["3rd machine"] = "FUSEMACHINE",
    ["4th machine"] = "CRAFTMACHINE",
    ["5th machine"] = "WITCHFUSE",
    ["6th machine"] = "BRAINROTDEALER",
    ["7th machine"] = "BRAINROTTRADER",
    ["8th machine"] = "SANTASFUSE",
    ["9th machine"] = "SANTASSHOP",
    ["10th machine"] = "NEWYEARSMACHINE",
    ["11th machine"] = "DUELSMACHINE",
    ["12th machine"] = "CUPIDSMACHINE",
    ["13th machine"] = "TRADEMACHINE",
    ["14th machine"] = "DIVINEFUSE",
    ["15th machine"] = "EGGINCUBATOR",
    ["16th machine"] = "CYBERCRAFTMACHINE",
    ["17th machine"] = "SUMMERFUSE",
    ["18th machine"] = "LOSTRADERS",
    ["rainbow machine"] = "RAINBOWMACHINE",
    ["bubblegum machine"] = "BUBBLEGUMMACHINE",
    ["fuse machine"] = "FUSEMACHINE",
    ["craft machine"] = "CRAFTMACHINE",
    ["witch fuse"] = "WITCHFUSE",
    ["brainrot dealer"] = "BRAINROTDEALER",
    ["brainrot trader"] = "BRAINROTTRADER",
    ["santas fuse"] = "SANTASFUSE",
    ["santas shop"] = "SANTASSHOP",
    ["new years machine"] = "NEWYEARSMACHINE",
    ["duels machine"] = "DUELSMACHINE",
    ["cupids machine"] = "CUPIDSMACHINE",
    ["trade machine"] = "TRADEMACHINE",
    ["divine fuse"] = "DIVINEFUSE",
    ["egg incubator"] = "EGGINCUBATOR",
    ["cyber craft machine"] = "CYBERCRAFTMACHINE",
    ["summer fuse"] = "SUMMERFUSE",
    ["lost traders"] = "LOSTRADERS",
    ["rng machine"] = "RNGMACHINE",
    ["haunted fuse"] = "HAUNTEDFUSE",
    ["19th machine"] = "RNGMACHINE",
    ["20th machine"] = "HAUNTEDFUSE",
    ["the newest machine"] = "HAUNTEDFUSE",
    ["the latest machine"] = "HAUNTEDFUSE",
    ["last machine added"] = "HAUNTEDFUSE",
    ["most recent machine"] = "HAUNTEDFUSE",
    ["how many machines are there"] = "20",
    ["how many machines"] = "20",
    ["total machines"] = "20",
    ["machine count"] = "20",
    ["number of machines in sab"] = "20",

    -- ===== EXPANDED: Brainrots =====
    ["what is the rarest brainrot"] = "POLAROIDINI",
    ["whats the rarest brainrot"] = "POLAROIDINI",
    ["rarest brainrot in the game"] = "POLAROIDINI",
    ["the rarest brainrot"] = "POLAROIDINI",
    ["most rare brainrot"] = "POLAROIDINI",
    ["hardest brainrot to get"] = "POLAROIDINI",
    ["what is the best brainrot"] = "STRAWBERRYELEPHANT",
    ["whats the best brainrot"] = "STRAWBERRYELEPHANT",
    ["the best brainrot"] = "STRAWBERRYELEPHANT",
    ["number one brainrot"] = "STRAWBERRYELEPHANT",
    ["top brainrot"] = "STRAWBERRYELEPHANT",
    ["strongest brainrot"] = "STRAWBERRYELEPHANT",
    ["what is the worst brainrot"] = "NOOBINIPIZZANINI",
    ["whats the worst brainrot"] = "NOOBINIPIZZANINI",
    ["the worst brainrot"] = "NOOBINIPIZZANINI",
    ["weakest brainrot"] = "NOOBINIPIZZANINI",
    ["what is the most popular brainrot"] = "DRAGONCANNELONNI",
    ["whats the most popular brainrot"] = "DRAGONCANNELONNI",
    ["most liked brainrot"] = "DRAGONCANNELONNI",
    ["fan favorite brainrot"] = "DRAGONCANNELONNI",
    ["what is the most common brainrot"] = "NOOBINIPIZZANINI",
    ["whats the most common brainrot"] = "NOOBINIPIZZANINI",
    ["easiest brainrot to get"] = "NOOBINIPIZZANINI",
    ["what is the first brainrot"] = "STRAWBERRYELEPHANT",
    ["first brainrot"] = "STRAWBERRYELEPHANT",
    ["first brainrot in the game"] = "STRAWBERRYELEPHANT",
    ["whats the first brainrot"] = "STRAWBERRYELEPHANT",
    ["the first brainrot"] = "STRAWBERRYELEPHANT",
    ["original brainrot"] = "STRAWBERRYELEPHANT",
    ["og brainrot"] = "STRAWBERRYELEPHANT",
    ["what is the oldest brainrot"] = "STRAWBERRYELEPHANT",
    ["what was the first og"] = "STRAWBERRYELEPHANT",
    ["1st og"] = "STRAWBERRYELEPHANT",
    ["first og"] = "STRAWBERRYELEPHANT",
    ["second og"] = "MEOWL",
    ["2nd og"] = "MEOWL",
    ["third og"] = "SKIBIDITOILET",
    ["3rd og"] = "SKIBIDITOILET",
    ["fourth og"] = "JOHNPORK",
    ["4th og"] = "JOHNPORK",
    ["fifth og"] = "JOHNPORK",
    ["5th og"] = "JOHNPORK",
    ["what brainrot cant be obtained"] = "HEADLESSHORSEMAN",
    ["unobtainable"] = "HEADLESSHORSEMAN",
    ["which brainrot is unobtainable"] = "HEADLESSHORSEMAN",
    ["what brainrot is unobtainable"] = "HEADLESSHORSEMAN",
    ["brainrot you cant get"] = "HEADLESSHORSEMAN",
    ["which brainrot cant you get"] = "HEADLESSHORSEMAN",
    ["which og brainrot cannot be obtained"] = "HEADLESSHORSEMAN",
    ["headless horseman brainrot"] = "HEADLESSHORSEMAN",
    ["the headless horseman"] = "HEADLESSHORSEMAN",
    ["whats my favorite brainrot"] = "MEOWL",
    ["my favorite brainrot"] = "MEOWL",
    ["sammys favorite brainrot"] = "MEOWL",
    ["favorite brainrot"] = "MEOWL",
    ["fav brainrot"] = "MEOWL",
    ["what is my favorite brainrot"] = "MEOWL",

    -- ===== EXPANDED: Rarities =====
    ["what is the highest rarity"] = "OG",
    ["whats the highest rarity"] = "OG",
    ["best rarity"] = "OG",
    ["whats the best rarity"] = "OG",
    ["max rarity"] = "OG",
    ["the highest rarity"] = "OG",
    ["what is the rarest rarity"] = "OG",
    ["whats the rarest rarity"] = "OG",
    ["what is the lowest rarity"] = "COMMON",
    ["whats the lowest rarity"] = "COMMON",
    ["whats the worst rarity"] = "COMMON",
    ["the lowest rarity"] = "COMMON",
    ["the worst rarity"] = "COMMON",
    ["first rarity"] = "COMMON",
    ["second rarity"] = "UNCOMMON",
    ["third rarity"] = "RARE",
    ["fourth rarity"] = "EPIC",
    ["fifth rarity"] = "LEGENDARY",
    ["sixth rarity"] = "OG",
    ["rarity 1"] = "COMMON",
    ["rarity 2"] = "UNCOMMON",
    ["rarity 3"] = "RARE",
    ["rarity 4"] = "EPIC",
    ["rarity 5"] = "LEGENDARY",
    ["rarity 6"] = "OG",
    ["how many rarities are there"] = "SIX",
    ["rarity count"] = "SIX",
    ["number of rarities"] = "SIX",
    ["total number of rarities"] = "SIX",
    ["6"] = "SIX",

    -- ===== EXPANDED: Specific trivia =====
    ["what does fire represent"] = "DRAGON",
    ["fire element"] = "DRAGON",
    ["what brainrot represents fire"] = "DRAGON",
    ["what brainrot is fire"] = "DRAGON",
    ["who is the brother of hydra bunny"] = "CERBERUS",
    ["hydra bunny brother"] = "CERBERUS",
    ["hydra bunnys brother"] = "CERBERUS",
    ["who is hydra bunnys brother"] = "CERBERUS",
    ["brother of hydra"] = "CERBERUS",
    ["who won the world cup"] = "SPAIN",
    ["world cup winner"] = "SPAIN",
    ["world cup 2026"] = "SPAIN",
    ["world cup 2026 winner"] = "SPAIN",
    ["2026 world cup winner"] = "SPAIN",
    ["who won world cup 2026"] = "SPAIN",
    ["world cup champion"] = "SPAIN",
    ["who is the worst game owner"] = "SECRETLOKII",
    ["worst game owner on roblox"] = "SECRETLOKII",
    ["worst owner"] = "SECRETLOKII",
    ["whats the most boring game on roblox"] = "KEYBOARDESCAPE",
    ["most boring game"] = "KEYBOARDESCAPE",
    ["boring game"] = "KEYBOARDESCAPE",
    ["most boring roblox game"] = "KEYBOARDESCAPE",
    ["what spawned during the admin abuse war"] = "RACOONINIJANDELINI",
    ["admin abuse war spawn"] = "RACOONINIJANDELINI",
    ["admin war spawn"] = "RACOONINIJANDELINI",
    ["what spawned in admin war"] = "RACOONINIJANDELINI",
    ["who did i fight in the admin war"] = "JANDEL",
    ["who did sammy fight in the admin war"] = "JANDEL",
    ["admin war opponent"] = "JANDEL",
    ["admin abuse war opponent"] = "JANDEL",
    ["who won the admin war"] = "JANDEL",
    ["admin war winner"] = "JANDEL",
    ["what game won the admin abuse war"] = "GROWAGARDEN",
    ["what game won the admin war"] = "GROWAGARDEN",
    ["admin abuse war winner game"] = "GROWAGARDEN",
    ["what is the worst secret"] = "KARKERKARKURKUR",
    ["worst secret in sab"] = "KARKERKARKURKUR",
    ["whats the worst secret"] = "KARKERKARKURKUR",
    ["whats the discord server"] = "blossom",
    ["discord name"] = "blossom",
    ["name of the discord"] = "blossom",
    ["what is the discord"] = "blossom",
    ["sab discord"] = "blossom",
    ["sab discord name"] = "blossom",
    ["what is the discord server called"] = "blossom",
    ["what is the discord called"] = "blossom",
    ["discord server name"] = "blossom",

    -- ===== EXPANDED: Specific Q&A trivia =====
    ["gold brainrots for rainbow machine"] = "25",
    ["how many gold for rainbow machine"] = "25",
    ["how many gold brainrots for rainbow"] = "25",
    ["gold needed for rainbow machine"] = "25",
    ["rainbow machine gold cost"] = "25",
    ["how much gold for rainbow machine"] = "25",
    ["where did griffin come from"] = "DIVINEFUSE",
    ["griffin origin"] = "DIVINEFUSE",
    ["where is griffin from"] = "DIVINEFUSE",
    ["griffin machine"] = "DIVINEFUSE",
    ["what machine is griffin from"] = "DIVINEFUSE",
    ["who is a egg"] = "STEAK",
    ["who is an egg"] = "STEAK",
    ["whos an egg"] = "STEAK",
    ["the egg"] = "STEAK",
    ["who is the best trait farmer"] = "RUSTYNICKLE40",
    ["best trait farmer"] = "RUSTYNICKLE40",
    ["whos the best trait farmer"] = "RUSTYNICKLE40",
    ["top trait farmer"] = "RUSTYNICKLE40",
    ["who has most aura"] = "CAYLUS",
    ["most aura"] = "CAYLUS",
    ["who has the most aura in sab"] = "CAYLUS",
    ["highest aura"] = "CAYLUS",
    ["steak age"] = "25",
    ["how old is steak"] = "25",
    ["steaks age"] = "25",
    ["steaks brother"] = "CRUZ",
    ["who is steaks brother"] = "CRUZ",
    ["steak brother"] = "CRUZ",
    ["brother of steak"] = "CRUZ",
    ["what does cruz hate"] = "CHEESE",
    ["cruz hates"] = "CHEESE",
    ["food cruz hates"] = "CHEESE",
    ["what food does cruz hate"] = "CHEESE",
    ["cruz least favorite food"] = "CHEESE",
    ["color of my car"] = "RED",
    ["my car color"] = "RED",
    ["what color is sammys car"] = "RED",
    ["car color"] = "RED",
    ["sammys car color"] = "RED",
    ["whats the color of my car"] = "RED",
    ["first game i made"] = "CRABGAME",
    ["my first game"] = "CRABGAME",
    ["first game"] = "CRABGAME",
    ["first game sammy made"] = "CRABGAME",
    ["sammys first game"] = "CRABGAME",
    ["what was my first game"] = "CRABGAME",
    ["what was the first game i made"] = "CRABGAME",
    ["what do i eat on taco tuesday"] = "TACOS",
    ["taco tuesday"] = "TACOS",
    ["what i eat on taco tuesday"] = "TACOS",
    ["taco tuesday food"] = "TACOS",
    ["name and 67"] = "SAMMY67",
    ["my name and 67"] = "SAMMY67",
    ["name plus 67"] = "SAMMY67",
    ["sammy and 67"] = "SAMMY67",
    ["sky color and 67"] = "BLUE67",
    ["color of the sky and 67"] = "BLUE67",
    ["blue and 67"] = "BLUE67",
    ["sky and 67"] = "BLUE67",
    ["age plus name year"] = "24SAMMY2002",
    ["my age plus my name and year"] = "24SAMMY2002",
    ["age name year"] = "24SAMMY2002",
    ["best food duo"] = "PIZZAANDRANCH",
    ["food duo"] = "PIZZAANDRANCH",
    ["best food combination"] = "PIZZAANDRANCH",
    ["best food combo"] = "PIZZAANDRANCH",
    ["favorite food duo"] = "PIZZAANDRANCH",
    ["best og brainrot"] = "SPYDERELEPHANT",
    ["whats the best og brainrot"] = "SPYDERELEPHANT",
    ["best og"] = "SPYDERELEPHANT",
    ["the best og"] = "SPYDERELEPHANT",
    ["top og brainrot"] = "SPYDERELEPHANT",
    ["how many polaroidini exist"] = "24",
    ["polaroidini count"] = "24",
    ["how many polaroidini are there"] = "24",
    ["total polaroidini"] = "24",
    ["number of polaroidini"] = "24",
    ["how many headless horseman exist"] = "79",
    ["headless horseman count"] = "79",
    ["how many headless horseman are there"] = "79",
    ["total headless horseman"] = "79",
    ["number of headless horseman"] = "79",
    ["name backwards"] = "YMMAS",
    ["my name backwards"] = "YMMAS",
    ["sammy backwards"] = "YMMAS",
    ["sammy spelled backwards"] = "YMMAS",
    ["sammys name backwards"] = "YMMAS",
    ["reverse of sammy"] = "YMMAS",
    ["cats name backwards"] = "AVON",
    ["nova backwards"] = "AVON",
    ["my cat backwards"] = "AVON",
    ["reverse of nova"] = "AVON",
    ["name backwards and 67"] = "YMMAS67",
    ["my name backwards and 67"] = "YMMAS67",
    ["sammy backwards and 67"] = "YMMAS67",
    ["ymmas and 67"] = "YMMAS67",
    ["fortnite game"] = "ROBABANK",
    ["game on fortnite"] = "ROBABANK",
    ["fortnite game i made"] = "ROBABANK",
    ["what game did i make on fortnite"] = "ROBABANK",
    ["my fortnite game"] = "ROBABANK",
    ["when did i start making roblox games"] = "2013",
    ["when did i begin making roblox games"] = "2013",
    ["year i started making games"] = "2013",
    ["started making games"] = "2013",
    ["began making games"] = "2013",
    ["year i started roblox development"] = "2013",
    ["when did sammy start making games"] = "2013",
    ["what element represents dragons"] = "FIRE",
    ["dragon element"] = "FIRE",
    ["dragons element"] = "FIRE",
    ["element of dragon"] = "FIRE",
    ["what animal is tralalero tralala"] = "SHARK",
    ["tralalero animal"] = "SHARK",
    ["tralalero"] = "SHARK",
    ["tralalero tralala"] = "SHARK",
    ["what type of animal is tralalero"] = "SHARK",
    ["current season"] = "HALLOWEEN",
    ["what season is it"] = "HALLOWEEN",
    ["what season are we in right now"] = "HALLOWEEN",
    ["whats the current season"] = "HALLOWEEN",
    ["sab season"] = "HALLOWEEN",
    ["whats on sammys chain"] = "SPIDER",
    ["chain"] = "SPIDER",
    ["on my chain"] = "SPIDER",
    ["on sammys chain"] = "SPIDER",
    ["what is on my chain"] = "SPIDER",
    ["left eye"] = "SPIDER",
    ["on my left eye"] = "SPIDER",
    ["what is on my left eye"] = "SPIDER",
    ["on sammys left eye"] = "SPIDER",
    ["sammy short for"] = "SAM",
    ["what is sammy short for"] = "SAM",
    ["my name short for"] = "SAM",
    ["nickname"] = "SAM",
    ["short name"] = "SAM",
    ["sammy nickname"] = "SAM",
    ["lead programmer"] = "HASTED",
    ["lead programmer of sab"] = "HASTED",
    ["sab lead programmer"] = "HASTED",
    ["who is the lead programmer"] = "HASTED",
    ["who programs sab"] = "HASTED",
    ["main programmer"] = "HASTED",
    ["who is the main programmer"] = "HASTED",
    ["lead dev"] = "HASTED",
    ["lead developer"] = "HASTED",
    ["programmer of sab"] = "HASTED",
    ["who coded sab"] = "HASTED",
    ["sab programmer"] = "HASTED",
    ["world cup team total goals"] = "7",
    ["how many goals in the world cup final"] = "7",
    ["total goals world cup"] = "7",
    ["goals scored world cup"] = "7",
    ["name age and month"] = "SAMMY24FEBRUARY",
    ["my name age and month"] = "SAMMY24FEBRUARY",
    ["sammy 24 february"] = "SAMMY24FEBRUARY",
    ["name age month"] = "SAMMY24FEBRUARY",
    ["born and age"] = "BRAZIL24",
    ["where born and age"] = "BRAZIL24",
    ["birthplace and age"] = "BRAZIL24",
    ["where i was born and age"] = "BRAZIL24",
    ["born plus age"] = "BRAZIL24",
    ["first game plus age"] = "CRABGAME24",
    ["first game and age"] = "CRABGAME24",
    ["crabgame and 24"] = "CRABGAME24",
    ["my first game and my age"] = "CRABGAME24",
    ["ninth mutation month and day"] = "APRIL18",
    ["when did the ninth mutation come out"] = "APRIL18",
    ["radioactive release date"] = "APRIL18",
    ["when was radioactive added"] = "APRIL18",
    ["month and day ninth mutation"] = "APRIL18",
    ["ninth mutation date"] = "APRIL18",
    ["los dragons rainbow value"] = "425000000",
    ["how much is los dragons rainbow"] = "425000000",
    ["los dragons rainbow price"] = "425000000",
    ["los dragons as rainbow"] = "425000000",
    ["rainbow los dragons value"] = "425000000",
    ["first trait currency bee event rebirths"] = "FIREWORKSHONEY19",
    ["first trait plus bee currency plus rebirths"] = "FIREWORKSHONEY19",
    ["trait bee rebirths"] = "FIREWORKSHONEY19",
    ["how many rebirths"] = "19",
    ["number of rebirths"] = "19",
    ["total rebirths"] = "19",
    ["rebirth count"] = "19",

    -- ===== EXPANDED: More doubled/tripled variations =====
    ["my name two times"] = "SAMMYSAMMY",
    ["sammy twice"] = "SAMMYSAMMY",
    ["sammy two times"] = "SAMMYSAMMY",
    ["sammy 2x"] = "SAMMYSAMMY",
    ["name x2"] = "SAMMYSAMMY",
    ["sammy three times"] = "SAMMYSAMMYSAMMY",
    ["sammy 3 times"] = "SAMMYSAMMYSAMMY",
    ["sammy 3x"] = "SAMMYSAMMYSAMMY",
    ["name three times"] = "SAMMYSAMMYSAMMY",
    ["name x3"] = "SAMMYSAMMYSAMMY",
    ["age two times"] = "2424",
    ["24 twice"] = "2424",
    ["age 2 times"] = "2424",
    ["age x2"] = "2424",
    ["blue twice"] = "BLUEBLUE",
    ["color twice"] = "BLUEBLUE",
    ["color two times"] = "BLUEBLUE",
    ["blue 3 times"] = "BLUEBLUEBLUE",
    ["color three times"] = "BLUEBLUEBLUE",
    ["blue three times"] = "BLUEBLUEBLUE",
    ["blue 5 times"] = "BLUEBLUEBLUEBLUEBLUE",
    ["blue five times"] = "BLUEBLUEBLUEBLUEBLUE",
    ["color 5 times"] = "BLUEBLUEBLUEBLUEBLUE",
    ["color five times"] = "BLUEBLUEBLUEBLUEBLUE",
    ["pizza twice"] = "PIZZAPIZZA",
    ["food two times"] = "PIZZAPIZZA",
    ["food 2 times"] = "PIZZAPIZZA",
    ["football twice"] = "FOOTBALLFOOTBALL",
    ["sport two times"] = "FOOTBALLFOOTBALL",
    ["sport 2 times"] = "FOOTBALLFOOTBALL",
    ["spider twice"] = "SPIDERSPIDER",
    ["animal two times"] = "SPIDERSPIDER",
    ["animal 2 times"] = "SPIDERSPIDER",
    ["ronaldo twice"] = "RONALDORONALDO",
    ["player two times"] = "RONALDORONALDO",
    ["player 2 times"] = "RONALDORONALDO",
    ["polaroidini twice"] = "POLAROIDINIPOLAROIDINI",
    ["rarest twice"] = "POLAROIDINIPOLAROIDINI",
    ["og twice"] = "OGOG",
    ["rarity og twice"] = "OGOG",
    ["mateo twice"] = "MATEOMATEO",
    ["lightning twice"] = "MATEOMATEO",
    ["sab twice"] = "STEALABRAINROTSTEALABRAINROT",
    ["game name two times"] = "STEALABRAINROTSTEALABRAINROT",
    ["seven twice"] = "SEVENSEVEN",
    ["number twice"] = "SEVENSEVEN",
    ["number two times"] = "SEVENSEVEN",
    ["nova twice"] = "NOVANOVA",
    ["cat twice"] = "NOVANOVA",
    ["cat two times"] = "NOVANOVA",
    ["nova three times"] = "NOVANOVANOVA",
    ["cat three times"] = "NOVANOVANOVA",
    ["cat 3 times"] = "NOVANOVANOVA",
    ["spydersammy twice"] = "SPYDERSAMMYSPYDERSAMMY",
    ["username two times"] = "SPYDERSAMMYSPYDERSAMMY",
    ["username 2 times"] = "SPYDERSAMMYSPYDERSAMMY",
    ["brazil twice"] = "BRAZILBRAZIL",
    ["country two times"] = "BRAZILBRAZIL",
    ["country 2 times"] = "BRAZILBRAZIL",

    -- ===== EXPANDED: Combined compound answers =====
    ["name and age"] = "SAMMY24",
    ["my name and age"] = "SAMMY24",
    ["my name and my age"] = "SAMMY24",
    ["name plus age"] = "SAMMY24",
    ["sammy and 24"] = "SAMMY24",
    ["name and color"] = "SAMMYBLUE",
    ["my name and color"] = "SAMMYBLUE",
    ["my name and my color"] = "SAMMYBLUE",
    ["name and food"] = "SAMMYPIZZA",
    ["my name and food"] = "SAMMYPIZZA",
    ["my name and my food"] = "SAMMYPIZZA",
    ["name and animal"] = "SAMMYSPIDER",
    ["my name and animal"] = "SAMMYSPIDER",
    ["my name and my animal"] = "SAMMYSPIDER",
    ["age and color"] = "24BLUE",
    ["my age and color"] = "24BLUE",
    ["my age and my color"] = "24BLUE",
    ["age and name"] = "24SAMMY",
    ["my age and name"] = "24SAMMY",
    ["my age and my name"] = "24SAMMY",
    ["color and age"] = "BLUE24",
    ["my color and age"] = "BLUE24",
    ["color and name"] = "BLUESAMMY",
    ["my color and name"] = "BLUESAMMY",
    ["color and food"] = "BLUEPIZZA",
    ["my color and food"] = "BLUEPIZZA",
    ["food and color"] = "PIZZABLUE",
    ["food and name"] = "PIZZASAMMY",
    ["animal and color"] = "SPIDERBLUE",
    ["sport and player"] = "FOOTBALLRONALDO",
    ["player and sport"] = "RONALDOFOOTBALL",
    ["name and country"] = "SAMMYBRAZIL",
    ["my name and country"] = "SAMMYBRAZIL",
    ["country and name"] = "BRAZILSAMMY",
    ["country and age"] = "BRAZIL24",
    ["age and country"] = "24BRAZIL",
    ["name and cat"] = "SAMMYNOVA",
    ["my name and cat"] = "SAMMYNOVA",
    ["cat and name"] = "NOVASAMMY",
    ["name and sport"] = "SAMMYFOOTBALL",
    ["name and number"] = "SAMMYSEVEN",
    ["my name and number"] = "SAMMYSEVEN",
    ["number and name"] = "SEVENSAMMY",
    ["username and age"] = "SPYDERSAMMY24",
    ["age and username"] = "24SPYDERSAMMY",

    -- ═══════════════════════════════════════════════
    -- ===== UPDATE 69+ : ECLIPSE / HALLOWEEN 2026 =====
    -- ═══════════════════════════════════════════════

    -- ===== ECLIPSE EVENT =====
    ["eclipse event update"] = "69",
    ["what update added eclipse"] = "69",
    ["eclipse spin wheel"] = "ECLIPSESPINWHEEL",
    ["eclipse wheel"] = "ECLIPSESPINWHEEL",
    ["eclipse schedule weekday"] = "EVERY2HOURS",
    ["eclipse schedule weekend"] = "EVERYHOUR",
    ["how often does eclipse happen on weekdays"] = "EVERY2HOURS",
    ["how often does eclipse happen on weekends"] = "EVERYHOUR",
    ["eclipse duration"] = "15MINUTES",
    ["how long does eclipse last"] = "15MINUTES",
    ["eclipse lucky block chance"] = "0.5PERCENT",
    ["eclipse secret lucky block chance"] = "0.5PERCENT",

    -- ===== HAUNTED FUSE BRAINROTS =====
    ["penguino pumpkino"] = "EPIC",
    ["penguino pumpkino rarity"] = "EPIC",
    ["penguino pumpkino income"] = "235000",
    ["frostino vampiro"] = "MYTHIC",
    ["frostino vampiro rarity"] = "MYTHIC",
    ["frostino vampiro income"] = "17500",
    ["vampi ribbitini"] = "BRAINROTGOD",
    ["vampi ribbitini rarity"] = "BRAINROTGOD",
    ["vampi ribbitini income"] = "185000",
    ["mummelo bandello"] = "BRAINROTGOD",
    ["mummelo bandello rarity"] = "BRAINROTGOD",
    ["mummelo bandello income"] = "285000",
    ["mortaruga"] = "BRAINROTGOD",
    ["mortaruga rarity"] = "BRAINROTGOD",
    ["mortaruga income"] = "324000",
    ["los treaters"] = "SECRET",
    ["los treaters rarity"] = "SECRET",
    ["los treaters income"] = "1200000",
    ["fangaro lupino"] = "SECRET",
    ["fangaro lupino rarity"] = "SECRET",
    ["fangaro lupino income"] = "7200000",
    ["oni oni panda"] = "SECRET",
    ["oni oni panda rarity"] = "SECRET",
    ["oni oni panda income"] = "27000000",
    ["sammyni spookyni"] = "SECRET",
    ["sammyni spookyni rarity"] = "SECRET",
    ["sammyni spookyni income"] = "80000000",
    ["plant bros"] = "SECRET",
    ["plant bros rarity"] = "SECRET",
    ["plant bros income"] = "300000000",
    ["plant bros recipe"] = "ORCHIDOXVENUSPINO",
    ["how to get plant bros"] = "ORCHIDOXVENUSPINO",
    ["plant bros recipe chance"] = "50PERCENT",
    ["best haunted fuse brainrot"] = "PLANTBROS",
    ["rarest haunted fuse brainrot"] = "PLANTBROS",
    ["best halloween brainrot"] = "PLANTBROS",

    -- ===== SKULL LUCKY BLOCK =====
    ["skull lucky block cost"] = "500000000",
    ["how much is skull lucky block"] = "500000000",
    ["skull lucky block price"] = "500000000",
    ["how many drops in skull lucky block"] = "8",
    ["skull lucky block drops"] = "8",
    ["best skull lucky block drop"] = "DRAGONSKELETONINI",
    ["rarest skull lucky block drop"] = "DRAGONSKELETONINI",
    ["dragon skeletonini"] = "SECRET",
    ["dragon skeletonini rarity"] = "SECRET",
    ["dragon skeletonini income"] = "325000000",
    ["dragon skeletonini chance"] = "0.1PERCENT",
    ["dragon skeletonini drop chance"] = "0.1PERCENT",
    ["candi corni"] = "BRAINROTGOD",
    ["candi corni rarity"] = "BRAINROTGOD",
    ["candi corni income"] = "321000",
    ["candi corni chance"] = "32.4PERCENT",
    ["grim cheese"] = "SECRET",
    ["grim cheese rarity"] = "SECRET",
    ["grim cheese income"] = "1600000",
    ["grim cheese chance"] = "30PERCENT",
    ["zombie bowl"] = "SECRET",
    ["zombie bowl rarity"] = "SECRET",
    ["zombie bowl income"] = "4500000",
    ["zombie bowl chance"] = "21PERCENT",
    ["bananito skelito"] = "SECRET",
    ["bananito skelito rarity"] = "SECRET",
    ["bananito skelito income"] = "8500000",
    ["bananito skelito chance"] = "10PERCENT",
    ["bat in the box"] = "SECRET",
    ["bat-in-the-box"] = "SECRET",
    ["bat in the box rarity"] = "SECRET",
    ["bat in the box income"] = "22500000",
    ["bat in the box chance"] = "5PERCENT",
    ["boo boo rocket"] = "SECRET",
    ["boo boo rocket rarity"] = "SECRET",
    ["boo boo rocket income"] = "37500000",
    ["boo boo rocket chance"] = "1PERCENT",
    ["flying dutchman"] = "SECRET",
    ["flying dutchman rarity"] = "SECRET",
    ["flying dutchman income"] = "92500000",
    ["flying dutchman chance"] = "0.5PERCENT",

    -- ===== PHOENIX =====
    ["phoenix"] = "SECRET",
    ["phoenix rarity"] = "SECRET",
    ["phoenix income"] = "425000000",
    ["phoenix value"] = "425000000000",
    ["eclipse phoenix income"] = "5700000000",
    ["eclipse phoenix"] = "ECLIPSEPHOENIX",
    ["how to get phoenix"] = "HAUNTEDFUSE",
    ["where does phoenix come from"] = "HAUNTEDFUSE",
    ["phoenix machine"] = "HAUNTEDFUSE",
    ["what machine is phoenix from"] = "HAUNTEDFUSE",

    -- ===== NOO MY CANDY =====
    ["noo my candy"] = "SECRET",
    ["noomycandy"] = "SECRET",
    ["noo my candy rarity"] = "SECRET",
    ["noo my candy income"] = "5000000",
    ["noo my candy cost"] = "900000000",
    ["how to get noo my candy"] = "TRICKORTREAT",
    ["noo my candy event"] = "HALLOWEEN",
    ["noo my candy chance"] = "1PERCENT",

    -- ===== RNG MACHINE BRAINROTS =====
    ["rocketini frostini"] = "SECRET",
    ["rocketini frostini rarity"] = "SECRET",
    ["rocketini frostini income"] = "3000000",
    ["gelatina volatina"] = "SECRET",
    ["gelatina volatina rarity"] = "SECRET",
    ["gelatina volatina income"] = "2400000",
    ["best rng machine brainrot"] = "ROCKETINIFROSTINI",
    ["rarest rng brainrot"] = "ROCKETINIFROSTINI",
    ["how many brainrots in rng machine"] = "40",
    ["rng machine brainrot count"] = "40",

    -- ===== TRAITS (COMPLETE) =====
    ["strawberry trait multiplier"] = "8",
    ["strawberry trait"] = "8X",
    ["meowl trait multiplier"] = "7",
    ["meowl trait"] = "7X",
    ["john pork trait multiplier"] = "6.5",
    ["john pork trait"] = "6.5X",
    ["skibidi trait multiplier"] = "6",
    ["skibidi trait"] = "6X",
    ["best trait"] = "STRAWBERRY",
    ["highest trait"] = "STRAWBERRY",
    ["highest trait multiplier"] = "8",
    ["best trait multiplier"] = "8",

    -- OG traits
    ["strawberry trait how to get"] = "STRAWBERRYELEPHANTSPAWN",
    ["meowl trait how to get"] = "MEOWLEVENT",
    ["john pork trait how to get"] = "JOHNPORKEVENT",
    ["skibidi trait how to get"] = "SKIBIDITOILETSPAWN",

    -- Seasonal traits
    ["rainbow balloon trait"] = "6.5X",
    ["pink egg trait"] = "6.5X",
    ["1 year trait"] = "5.5X",
    ["anniversary trait"] = "5.5X",
    ["granny trait"] = "5.5X",
    ["reindeer pet trait"] = "5X",
    ["26 trait"] = "5X",
    ["halo trait"] = "5X",
    ["lucky trait"] = "5X",
    ["chocolate trait"] = "4.5X",
    ["jack o lantern trait"] = "4.5X",
    ["bunny ears trait"] = "4.5X",
    ["santa hat trait"] = "4X",

    -- Ritual traits
    ["paint trait"] = "5X",
    ["paint trait multiplier"] = "5",
    ["paint trait how to get"] = "CHICLETEIRABICICLETEIRARITUAL",
    [":3 trait"] = "4.5X",
    [":3 trait how to get"] = "MIGATORITUAL",
    ["tie trait"] = "3.75X",
    ["tie trait how to get"] = "DULDULDULRITUAL",
    ["spider trait"] = "3.5X",
    ["spider trait how to get"] = "SAMMYNISPYDERINIRITUAL",
    ["matteo hat trait"] = "3.5X",
    ["matteo hat trait how to get"] = "MATTEORITUAL",
    ["galactic trait"] = "3X",
    ["galactic trait how to get"] = "LAVACCASATURNOSATURNRITARITUAL",
    ["explosive trait"] = "3X",
    ["explosive trait how to get"] = "BOMBARDIROCROCODILORITUAL",
    ["shark fin trait"] = "3X",
    ["shark fin trait how to get"] = "ORCALEROORCALARITUAL",

    -- Admin abuse traits
    ["fire trait"] = "5X",
    ["fire trait multiplier"] = "5",
    ["rose trait"] = "5X",
    ["fireworks trait"] = "5X",
    ["firework trait"] = "5X",
    ["fireworks trait multiplier"] = "5",
    ["nyan trait"] = "5X",
    ["nyan cat trait"] = "5X",
    ["lightning trait multiplier"] = "5",
    ["disco trait"] = "4X",
    ["burger trait"] = "4.5X",

    -- Country traits
    ["brazil trait"] = "5X",
    ["brazil trait multiplier"] = "5",
    ["indonesia trait"] = "4X",
    ["sombrero trait"] = "4X",
    ["mexico trait"] = "4X",

    -- Negative trait
    ["sleepy trait"] = "0.5X",
    ["sleepy trait multiplier"] = "0.5",
    ["worst trait"] = "SLEEPY",
    ["sleepy"] = "SLEEPY",

    -- ===== ADMIN ABUSE =====
    ["admin abuse day"] = "TUESDAYANDSATURDAY",
    ["when is admin abuse"] = "TUESDAYANDSATURDAY",
    ["admin abuse time"] = "6PMET",
    ["admin abuse tuesday time"] = "6PMET",
    ["admin abuse saturday time"] = "3PMET",
    ["taco tuesday time"] = "6PMET",
    ["when is taco tuesday"] = "TUESDAY6PMET",
    ["taco tuesday day"] = "TUESDAY",
    ["taco tuesday"] = "TACOS",
    ["saturday admin abuse time"] = "3PMET",
    ["when is saturday admin abuse"] = "SATURDAY3PMET",
    ["admin abuse schedule"] = "TUESDAY6PMSATURDAY3PM",
    ["admin abuse duration"] = "30TO45MINUTES",
    ["how long is admin abuse"] = "30TO45MINUTES",

    -- Admin abuse war
    ["admin abuse war"] = "AUGUST232025",
    ["when was the admin abuse war"] = "AUGUST232025",
    ["admin war date"] = "AUGUST232025",
    ["who fought in admin war"] = "JANDEL",
    ["jandel vs sammy"] = "JANDEL",
    ["sammy vs jandel"] = "JANDEL",
    ["what game won admin war"] = "GROWAGARDEN",
    ["admin war winning game"] = "GROWAGARDEN",
    ["grow a garden"] = "GROWAGARDEN",

    -- Admin abuse hosts
    ["admin abuse host"] = "STEAK",
    ["who hosts admin abuse"] = "STEAK",
    ["admin abuse hosts"] = "STEAKSAMMYCAYLUS",

    -- ===== RARITIES (EXPANDED) =====
    ["secret rarity"] = "SECRET",
    ["secret"] = "SECRET",
    ["brainrot god"] = "BRAINROTGOD",
    ["brainrot god rarity"] = "BRAINROTGOD",
    ["7th rarity"] = "MYTHIC",
    ["mythic"] = "MYTHIC",
    ["mythic rarity"] = "MYTHIC",
    ["8th rarity"] = "BRAINROTGOD",
    ["9th rarity"] = "SECRET",

    -- ===== EVENTS =====
    ["halloween event"] = "HALLOWEEN",
    ["christmas event"] = "CHRISTMAS",
    ["valentine event"] = "VALENTINE",
    ["summer event"] = "SUMMER",
    ["easter event"] = "EASTER",
    ["eid event"] = "EID",
    ["new year event"] = "NEWYEAR",
    ["bloodmoon event"] = "BLOODMOON",
    ["current event"] = "ECLIPSE",
    ["whats the current event"] = "ECLIPSE",
    ["what event is happening now"] = "ECLIPSE",
    ["what event is going on"] = "ECLIPSE",

    -- ===== SEASON UPDATE =====
    ["current season"] = "HALLOWEEN",
    ["what season is it"] = "HALLOWEEN",
    ["what season are we in right now"] = "HALLOWEEN",
    ["whats the current season"] = "HALLOWEEN",
    ["sab season"] = "HALLOWEEN",

    -- ===== SPECIFIC BRAINROT VALUES =====
    ["how much does phoenix make"] = "425000000",
    ["phoenix per second"] = "425000000",
    ["how much does dragon skeletonini make"] = "325000000",
    ["dragon skeletonini per second"] = "325000000",
    ["how much does plant bros make"] = "300000000",
    ["plant bros per second"] = "300000000",
    ["how much does sammyni spookyni make"] = "80000000",
    ["how much does oni oni panda make"] = "27000000",
    ["how much does fangaro lupino make"] = "7200000",
    ["how much does noo my candy make"] = "5000000",
    ["how much does flying dutchman make"] = "92500000",
    ["how much does boo boo rocket make"] = "37500000",
    ["how much does rocketini frostini make"] = "3000000",

    -- ===== UPDATE NUMBERS =====
    ["latest update"] = "69",
    ["newest update"] = "69",
    ["current update"] = "69",
    ["what update are we on"] = "69",
    ["update 69"] = "ECLIPSEHAUNTEDFUSE",
    ["what was added in update 69"] = "ECLIPSEHAUNTEDFUSE",
    ["update 47"] = "CYBERCRAFTMACHINE",
    ["what was added in update 47"] = "CYBERMUTATIONCRAFTMACHINE",
    ["update 59"] = "CRYSTALMUTATION",
    ["what was added in update 59"] = "CRYSTALMUTATION",
    ["update 70"] = "SKULLLUCKYBLOCK",
    ["what was added in update 70"] = "SKULLLUCKYBLOCKSKELETONEVENT",

    -- ===== CODES =====
    ["active code"] = "BESTBRAINROTEVER",
    ["working code"] = "BESTBRAINROTEVER",
    ["current code"] = "BESTBRAINROTEVER",
    ["code"] = "BESTBRAINROTEVER",
    ["bestbrainrotever"] = "LAVACCASATURNOSATURNITA",
    ["what does bestbrainrotever give"] = "LAVACCASATURNOSATURNITA",
    ["what does the code give"] = "LAVACCASATURNOSATURNITA",

    -- ===== DISCO MUTATION (SCRAPPED) =====
    ["disco mutation"] = "SCRAPPED",
    ["what happened to disco"] = "SCRAPPED",
    ["was disco scrapped"] = "YES",
    ["what replaced disco"] = "CYBER",
    ["scrapped mutation"] = "DISCO",
    ["what mutation was scrapped"] = "DISCO",
    ["removed mutation"] = "DISCO",

    -- ===== SAMMY'S CAT & FAVORITES (MORE) =====
    ["sammys cat"] = "NOVA",
    ["whats sammys cat called"] = "NOVA",
    ["sammy favorite brainrot"] = "MEOWL",
    ["whats sammys favorite brainrot"] = "MEOWL",
    ["sammys favourite brainrot"] = "MEOWL",

    -- ===== HEADLESS HORSEMAN =====
    ["how many headless horseman are in the game"] = "79",
    ["headless horseman total"] = "79",
    ["what event was headless horseman from"] = "HALLOWEEN2025",
    ["headless horseman event"] = "HALLOWEEN2025",
    ["headless horseman from"] = "WITCHFUSE",
    ["what machine was headless horseman from"] = "WITCHFUSE",
    ["best og fuse brainrot"] = "HEADLESSHORSEMAN",
    ["best brainrot from halloween fuse"] = "HEADLESSHORSEMAN",
    ["best brainrot from witch fuse"] = "HEADLESSHORSEMAN",

    -- ===== HALLOWEEN BRAINROTS (2025 + 2026) =====
    ["jacko spaventosa rarity"] = "LEGENDARY",
    ["pot pumpkin rarity"] = "EPIC",
    ["pumpkin spyderini rarity"] = "MYTHIC",
    ["jackorilla rarity"] = "BRAINROTGOD",
    ["frankentteo rarity"] = "LEGENDARY",
    ["zombie tralala rarity"] = "EPIC",
    ["trickolino rarity"] = "RARE",
    ["mummy ambalabu rarity"] = "EPIC",
    ["la spooky grande rarity"] = "MYTHIC",

    -- ===== CHRISTMAS BRAINROTS =====
    ["santteo rarity"] = "LEGENDARY",
    ["yeti claus rarity"] = "MYTHIC",
    ["festive 67 rarity"] = "SECRET",
    ["la jolly grande rarity"] = "MYTHIC",
    ["ballerina peppermintina rarity"] = "LEGENDARY",

    -- ===== VALENTINE BRAINROTS =====
    ["mariachi corazoni rarity"] = "LEGENDARY",
    ["serafinna medusella rarity"] = "BRAINROTGOD",
    ["la romantic grande rarity"] = "MYTHIC",

    -- ===== LEAD DEV & TEAM =====
    ["programmer"] = "HASTED",
    ["who coded the game"] = "HASTED",
    ["lead coder"] = "HASTED",
    ["sab developer"] = "HASTED",
    ["sab dev"] = "HASTED",

    -- ===== GAME CREATOR INFO =====
    ["group name"] = "BRAZILIANSPYDER",
    ["game group"] = "BRAZILIANSPYDER",
    ["roblox group"] = "BRAZILIANSPYDER",
    ["developer group"] = "BRAZILIANSPYDER",
    ["brazilian spyder"] = "BRAZILIANSPYDER",

    -- ===== MORE COMPOUND ANSWERS =====
    ["eclipse and phoenix"] = "ECLIPSEPHOENIX",
    ["haunted fuse and eclipse"] = "HAUNTEDFUSEECLIPSE",
    ["name and mutation"] = "SAMMYECLIPSE",
    ["newest mutation and newest machine"] = "ECLIPSEHAUNTEDFUSE",
    ["newest machine and newest mutation"] = "HAUNTEDFUSEECLIPSE",
    ["cat and age"] = "NOVA24",
    ["age and cat"] = "24NOVA",
    ["mutation count and machine count"] = "1520",
    ["food and animal"] = "PIZZASPIDER",
    ["animal and food"] = "SPIDERPIZZA",
    ["name and mutation count"] = "SAMMY15",
    ["name and machine count"] = "SAMMY20",
    ["color and number"] = "BLUE7",
    ["number and color"] = "7BLUE",
    ["roblox and age"] = "SPYDERSAMMY24",
    ["cat and color"] = "NOVABLUE",
    ["color and cat"] = "BLUENOVA",
    ["sport and animal"] = "FOOTBALLSPIDER",
    ["animal and sport"] = "SPIDERFOOTBALL",
    ["name and lead dev"] = "SAMMYHASTED",
    ["lead dev and name"] = "HASTEDSAMMY",

    -- ═══════════════════════════════════════════════
    -- ===== EVENT MACHINE BRAINROTS (ALL EVENTS) =====
    -- ═══════════════════════════════════════════════

    -- ===== WITCH FUSE (Halloween 2025) =====
    ["witch fuse brainrots"] = "WITCHFUSEBRAINROTS",
    ["halloween 2025 brainrots"] = "WITCHFUSEBRAINROTS",
    ["halloween 2025 event"] = "WITCHFUSE",
    ["what came from witch fuse"] = "WITCHFUSEBRAINROTS",
    ["eviledon"] = "EVILEDON",
    ["jacko jack jack"] = "JACKOJACKJACK",
    ["los mobilis"] = "LOSMOBILIS",
    ["vulturino skeletono"] = "VULTURINOSKELETONO",
    ["la spooky grande"] = "LASPOOKYGRANDE",
    ["jacko spaventosa"] = "JACKOSPAVENTOSA",
    ["pot pumpkin"] = "POTPUMPKIN",
    ["pumpkin spyderini"] = "PUMPKINSPYDERINI",
    ["jackorilla"] = "JACKORILLA",
    ["frankentteo"] = "FRANKENTTEO",
    ["zombie tralala"] = "ZOMBIETRALALA",
    ["trickolino"] = "TRICKOLINO",
    ["mummy ambalabu"] = "MUMMYAMBALABU",
    ["spooky and pumpky"] = "SPOOKYANDPUMPKY",
    ["la casa boo"] = "LACASABOO",
    ["coffin tung tung tung sahur"] = "COFFINTUNGTUNGTUNGSAHUR",
    ["best witch fuse brainrot"] = "HEADLESSHORSEMAN",
    ["best halloween 2025 brainrot"] = "HEADLESSHORSEMAN",

    -- ===== SANTAS FUSE (Christmas 2025) =====
    ["santas fuse brainrots"] = "SANTASFUSEBRAINROTS",
    ["christmas 2025 brainrots"] = "SANTASFUSEBRAINROTS",
    ["christmas 2025 event"] = "SANTASFUSE",
    ["what came from santas fuse"] = "SANTASFUSEBRAINROTS",
    ["reindeer tralala"] = "REINDEERTRALALA",
    ["santteo"] = "SANTTEO",
    ["santa hotspot"] = "SANTAHOTSPOT",
    ["giftini spyderini"] = "GIFTINISPYDERINI",
    ["yeti claus"] = "YETICLAUS",
    ["ho ho ho sahur"] = "HOHOHOSAHUR",
    ["jingle jingle sahur"] = "JINGLEJINGLESAHUR",
    ["ginger globo"] = "GINGERGLOBO",
    ["money money reindeer"] = "MONEYMONEYREINDEER",
    ["reinito sleighito"] = "REINITOSLEIGHITO",
    ["frio ninja"] = "FRIONINJA",
    ["ballerina peppermintina"] = "BALLERINAPEPPERMINTINA",
    ["la jolly grande"] = "LAJOLLYGRANDE",
    ["festive 67"] = "FESTIVE67",
    ["best christmas brainrot"] = "FESTIVE67",
    ["best santas fuse brainrot"] = "FESTIVE67",
    ["christmas secret"] = "FESTIVE67",
    ["cooki and milki"] = "COOKIANDMILKI",
    ["best christmas secret"] = "COOKIANDMILKI",

    -- ===== VALENTINE 2026 (Cupids Machine + Heart Lucky Block) =====
    ["valentine brainrots"] = "VALENTINEBRAINROTS",
    ["valentine 2026 brainrots"] = "VALENTINEBRAINROTS",
    ["valentine 2026 event"] = "CUPIDSMACHINE",
    ["cupids machine brainrots"] = "CUPIDSMACHINEBRAINROTS",
    ["what came from cupids machine"] = "CUPIDSMACHINEBRAINROTS",
    ["heart lucky block"] = "HEARTLUCKYBLOCK",
    ["luv luv luv"] = "LUVLUVLUV",
    ["love love love sahur"] = "LOVELOVELOVESAHUR",
    ["cupid hotspot"] = "CUPIDHOTSPOT",
    ["noo my heart"] = "NOOMYHEART",
    ["chicleteira cupideira"] = "CHICLETEIRACUPIDEIRA",
    ["rosetti tualetti"] = "ROSETTITUALETTI",
    ["rosey and teddy"] = "ROSEYANDTEDDY",
    ["cupid cupid sahur"] = "CUPIDCUPIDSAHUR",
    ["lovin rose"] = "LOVINROSE",
    ["best valentine brainrot"] = "ROSEYANDTEDDY",
    ["rarest valentine brainrot"] = "ROSEYANDTEDDY",
    ["rosey and teddy chance"] = "0.05PERCENT",
    ["valentine event date"] = "FEBRUARY72026",
    ["when was valentine event"] = "FEBRUARY72026",
    ["mariachi corazoni"] = "MARIACHICORAZONI",
    ["serafinna medusella"] = "SERAFINNAMEDUSELLA",
    ["la romantic grande"] = "LAROMANTICGRANDE",

    -- ===== DIVINE FUSE BRAINROTS =====
    ["divine fuse brainrots"] = "DIVINEFUSEBRAINROTS",
    ["what came from divine fuse"] = "DIVINEFUSEBRAINROTS",
    ["holy arepa"] = "HOLYAREPA",
    ["pengolino nuvoletto"] = "PENGOLINONUVOLETTO",
    ["gato celesto"] = "GATOCELESTO",
    ["buho del cielo"] = "BUHODELCIELO",
    ["seraphino gruyero"] = "SERAPHINOGRUYERO",
    ["harpuccino"] = "HARPUCCINO",
    ["berenjello angello"] = "BERENJELLOANGELLO",
    ["divino platypio"] = "DIVINOPLATYPIO",
    ["astrolero cervalero"] = "ASTROLEROCERVALERO",
    ["dumborino miracello"] = "DUMBORINOMIRACELLO",
    ["paradiso axolottino"] = "PARADISOAXOLOTTINO",
    ["cigno fulgoro"] = "CIGNOFULGORO",
    ["los cupids"] = "LOSCUPIDS",
    ["griffin"] = "GRIFFIN",
    ["griffin from divine fuse"] = "GRIFFIN",
    ["best divine fuse brainrot"] = "GRIFFIN",
    ["divine fuse secret"] = "GRIFFIN",
    ["when was divine fuse added"] = "MARCH72026",
    ["divine fuse release date"] = "MARCH72026",

    -- ===== CYBER CRAFT MACHINE BRAINROTS =====
    ["cyber craft machine brainrots"] = "CYBERCRAFTBRAINROTS",
    ["what came from cyber craft machine"] = "CYBERCRAFTBRAINROTS",
    ["buho de volto"] = "BUHODEVOLTO",
    ["camera ramena"] = "CAMERARAMENA",
    ["gym bros"] = "GYMBROS",
    ["los chillis"] = "LOSCHILLIS",
    ["kalika bros"] = "KALIKABROS",
    ["digi narwhal"] = "DIGINARWHAL",
    ["when was cyber craft machine added"] = "APRIL182026",
    ["cyber craft machine update"] = "47",

    -- ===== SUMMER FUSE BRAINROTS (Summer 2026) =====
    ["summer brainrots"] = "SUMMERBRAINROTS",
    ["summer 2026 brainrots"] = "SUMMERBRAINROTS",
    ["summer 2026 event"] = "SUMMERFUSE",
    ["summer fuse brainrots"] = "SUMMERFUSEBRAINROTS",
    ["what came from summer fuse"] = "SUMMERFUSEBRAINROTS",
    ["octo lucky block"] = "OCTOLUCKYBLOCK",
    ["cocoteddy"] = "COCOTEDDY",
    ["bucketoro"] = "BUCKETORO",
    ["sundrilla sundae"] = "SUNDRILLASUNDAE",
    ["lemonita splashita"] = "LEMONITASPLASHITA",
    ["flippo marino"] = "FLIPPOMARINO",
    ["bombardiro vaccariro"] = "BOMBARDIROVACCARIRO",
    ["ombrello topolino"] = "OMBRELLOTOPOLINO",
    ["capitano gullini"] = "CAPITANOGULLINI",
    ["los fruits"] = "LOSFRUITS",
    ["coco and mango"] = "COCOANDMANGO",
    ["venuspino"] = "VENUSPINO",
    ["dragon aquanini"] = "DRAGONAQUANINI",
    ["best summer brainrot"] = "DRAGONAQUANINI",
    ["best summer fuse brainrot"] = "DRAGONAQUANINI",
    ["summer fuse secret"] = "DRAGONAQUANINI",
    ["dragon aquanini income"] = "375000000",
    ["how much does dragon aquanini make"] = "375000000",
    ["tortuginni sandcastlini"] = "TORTUGINNISANDCASTLINI",
    ["sushi inu"] = "SUSHIINU",
    ["girafini raftini"] = "GIRAFINIRAFTINI",
    ["sand sand sand"] = "SANDSANDSAND",
    ["bearito cabinito"] = "BEARITOCABINITO",
    ["kraken"] = "KRAKEN",
    ["best octo lucky block brainrot"] = "KRAKEN",
    ["kraken income"] = "200000000",
    ["how much does kraken make"] = "200000000",
    ["when was summer fuse added"] = "MAY232026",
    ["summer fuse update"] = "52",
    ["update 52"] = "SUMMERFUSE",

    -- ===== ADMIN WAR (Expanded) =====
    ["who is jandel"] = "GROWAGARDEN",
    ["what game does jandel own"] = "GROWAGARDEN",
    ["jandel game"] = "GROWAGARDEN",
    ["jandels game"] = "GROWAGARDEN",
    ["raccooni jandelini"] = "RACOONIJANDELINI",
    ["what brainrot spawned during admin war"] = "RACOONIJANDELINI",
    ["what happened during admin abuse war"] = "GALAXYMUTATIONSONREDCARPET",
    ["what mutation spawned during admin war"] = "GALAXY",
    ["admin war mutation"] = "GALAXY",

    -- ===== TRAIT COUNT =====
    ["how many traits are there"] = "22",
    ["total traits"] = "22",
    ["number of traits"] = "22",
    ["trait count"] = "22",
    ["rain trait"] = "RAIN",
    ["snow trait"] = "SNOW",
    ["weather traits"] = "RAIN",

    -- ===== TRADE VALUES =====
    ["most valuable brainrot"] = "STRAWBERRYELEPHANT",
    ["highest trade value"] = "STRAWBERRYELEPHANT",

    -- ═══════════════════════════════════════════════
    -- ===== LUCKY BLOCKS (ALL 15) =====
    -- ═══════════════════════════════════════════════
    ["how many lucky blocks"] = "15",
    ["total lucky blocks"] = "15",
    ["number of lucky blocks"] = "15",
    ["lucky block count"] = "15",
    ["do lucky blocks have timers"] = "NO",
    ["lucky block timer removed"] = "AUGUST152026",

    -- Permanent lucky blocks
    ["mythic lucky block cost"] = "2500000",
    ["mythic lucky block price"] = "2500000",
    ["mythic lucky block"] = "MYTHICLUCKYBLOCK",
    ["mythic lucky block drops"] = "5",
    ["brainrot god lucky block cost"] = "25000000",
    ["brainrot god lucky block price"] = "25000000",
    ["brainrot god lucky block"] = "BRAINROTGODLUCKYBLOCK",
    ["brainrot god lucky block drops"] = "5",
    ["secret lucky block cost"] = "750000000",
    ["secret lucky block price"] = "750000000",
    ["secret lucky block"] = "SECRETLUCKYBLOCK",
    ["secret lucky block drops"] = "6",
    ["most expensive lucky block"] = "OCTOLUCKYBLOCK",
    ["cheapest lucky block"] = "MYTHICLUCKYBLOCK",

    -- Admin event lucky blocks
    ["admin lucky block cost"] = "100000000",
    ["admin lucky block"] = "ADMINLUCKYBLOCK",
    ["admin lucky block drops"] = "9",
    ["los lucky blocks cost"] = "250000000",
    ["los lucky blocks"] = "LOSLUCKYBLOCKS",
    ["los lucky blocks drops"] = "9",
    ["taco lucky block cost"] = "50000000",
    ["taco lucky block"] = "TACOLUCKYBLOCK",
    ["taco lucky block drops"] = "7",
    ["los taco blocks cost"] = "300000000",
    ["los taco blocks"] = "LOSTACOBLOCKS",
    ["los taco blocks drops"] = "6",

    -- Seasonal lucky blocks
    ["spooky lucky block cost"] = "350000000",
    ["spooky lucky block"] = "SPOOKYLUCKYBLOCK",
    ["spooky lucky block drops"] = "8",
    ["festive lucky block cost"] = "400000000",
    ["festive lucky block"] = "FESTIVELUCKYBLOCK",
    ["festive lucky block drops"] = "8",
    ["heart lucky block cost"] = "350000000",
    ["heart lucky block drops"] = "8",
    ["leprechaun lucky block cost"] = "400000000",
    ["leprechaun lucky block"] = "LEPRECHAUNLUCKYBLOCK",
    ["leprechaun lucky block drops"] = "8",
    ["egg lucky block cost"] = "500000000",
    ["egg lucky block"] = "EGGLUCKYBLOCK",
    ["egg lucky block drops"] = "8",
    ["octo lucky block cost"] = "600000000",
    ["octo lucky block drops"] = "8",
    ["bee lucky block cost"] = "400000000",
    ["bee lucky block"] = "BEELUCKYBLOCK",
    ["bee lucky block drops"] = "7",
    ["skull lucky block drops"] = "8",

    -- ═══════════════════════════════════════════════
    -- ===== TOTAL BRAINROT COUNT =====
    -- ═══════════════════════════════════════════════
    ["how many brainrots are there"] = "560",
    ["total brainrots"] = "560",
    ["number of brainrots"] = "560",
    ["brainrot count"] = "560",
    ["how many brainrots in the game"] = "560",
    ["how many brainrots exist"] = "560",

    -- ═══════════════════════════════════════════════
    -- ===== BRAINROT NAME LOOKUPS =====
    -- ═══════════════════════════════════════════════
    ["burgero and friero"] = "BURGEROANDFRIERO",
    ["bearteo"] = "BEARTEO",
    ["cash cash puggy"] = "CASHCASHPUGGY",
    ["orcaledon"] = "ORCALEDON",
    ["tang tang keletang"] = "TANGTANGKELETANG",
    ["buho de noelo"] = "BUHODENOELO",
    ["clocketeira bicicleteira"] = "CLOCKETEIRABICICLETEIRA",
    ["orcalerita orcala"] = "ORCALERITAORCALA",
    ["unclito samito"] = "UNCLITOSAMITO",
    ["satalito cacasito"] = "SATALITOCACASITO",
    ["noodlesini tualletini"] = "NOODLESINITUALLETINI",
    ["meow meow meow sahur"] = "MEOWMEOWMEOWSAHUR",
    ["owlito gattatito"] = "OWLITOGATTATITO",
    ["los orcalito"] = "LOSORCALITO",
    ["telemorte"] = "TELEMORTE",
    ["pipi kiwi"] = "PIPIKIWI",
    ["pipi corni"] = "PIPICORNI",
    ["salamino penguino"] = "SALAMINOPENGUINO",
    ["piccione macchina"] = "PICCIONEMACCHINA",
    ["tartaragno"] = "TARTARAGNO",
    ["tortuginni dragonfrutini"] = "TORTUGINNIDRAGONFRUTINI",
    ["pot hotspot"] = "POTHOTSPOT",
    ["esok sekolah"] = "ESOKSEKOLAH",
    ["ketupat kepat"] = "KETUPATKEPAT",

    -- Common brainrots with income
    ["noobini pizzanini income"] = "1",
    ["lirili larila income"] = "3",
    ["tim cheese income"] = "5",
    ["pipi kiwi income"] = "13",

    -- Base brainrots
    ["tralalero tralala"] = "TRALALEROTALALA",
    ["dragon cannelloni"] = "DRAGONCANNELLONI",
    ["hydra dragon cannelloni"] = "HYDRADRAGONCANNELLONI",
    ["sammyni spyderini"] = "SAMMYNISPYDERINI",
    ["sammyni fattini"] = "SAMMYNIFATTINI",
    ["la grande combinasion"] = "LAGRANDECOMBINASION",
    ["la supreme combinasion"] = "LASUPREMECOMBINASION",
    ["la sahur combinasion"] = "LASAHURCOMBINASION",
    ["celestial pegasus"] = "CELESTIALPEGASUS",
    ["1x1x1x1"] = "1X1X1X1",
    ["guest 666"] = "GUEST666",
    ["skibidi toilet"] = "SKIBIDITOILET",
    ["strawberry elephant"] = "STRAWBERRYELEPHANT",
    ["meowl"] = "MEOWL",
    ["bombardiro crocodilo"] = "BOMBARDIROCROCODILO",
    ["gorillo subwoofero"] = "GORILLOSUBWOOFERO",
    ["brr brr patapim"] = "BRRBRRPATAPIM",
    ["cappuccino assassino"] = "CAPPUCCINOASSASSINO",
    ["chimpanzini bananini"] = "CHIMPANZINIBANANINI",
    ["ballerina cappuccina"] = "BALLERINACAPPUCCINA",
    ["tung tung tung sahur"] = "TUNGTUNGTUNGSAHUR",
    ["la cucaracha"] = "LACUCARACHA",
    ["john pork"] = "JOHNPORK",
    ["smurf cat"] = "SMURFCAT",
    ["noobini pizzanini"] = "NOOBINIPIZZANINI",
    ["trippi troppi"] = "TRIPPITROPPI",
    ["sigma boy"] = "SIGMABOY",
    ["sigma girl"] = "SIGMAGIRL",

    -- ═══════════════════════════════════════════════
    -- ===== SECRET LUCKY BLOCK DROPS =====
    -- ═══════════════════════════════════════════════
    ["tortuginni dragonfrutini chance"] = "74.5PERCENT",
    ["pot hotspot chance"] = "21PERCENT",
    ["esok sekolah chance"] = "3PERCENT",
    ["spaghetti tualetti chance"] = "1PERCENT",
    ["best secret lucky block drop"] = "SPAGHETTITUALETTI",
    ["tortuginni dragonfrutini income"] = "350000",
    ["pot hotspot income"] = "2500000",
    ["esok sekolah income"] = "3000000",
    ["spaghetti tualetti income"] = "6000000",

    -- ═══════════════════════════════════════════════
    -- ===== MORE SAMMY FACTS =====
    -- ═══════════════════════════════════════════════
    ["sammy birthday"] = "FEBRUARY25",
    ["sammy birthday date"] = "FEBRUARY252002",
    ["when is sammys birthday"] = "FEBRUARY25",
    ["what is sammys birthday"] = "FEBRUARY25",
    ["sammys birthday date"] = "FEBRUARY25",
    ["sammy full birthday"] = "FEBRUARY252002",
    ["sammy instagram"] = "SPYDERSAMMY333",
    ["sammys instagram"] = "SPYDERSAMMY333",
    ["sammy ig"] = "SPYDERSAMMY333",
    ["sammy twitter"] = "SPYDERSAMMY",
    ["sammys twitter"] = "SPYDERSAMMY",
    ["sammy tiktok"] = "SPYDERSAMMY",
    ["sammys tiktok"] = "SPYDERSAMMY",
    ["sammy studio"] = "DOBIGSTUDIOS",
    ["do big studios"] = "DOBIGSTUDIOS",
    ["sammys studio"] = "DOBIGSTUDIOS",
    ["what studio is sammy from"] = "DOBIGSTUDIOS",
    ["sammy avatar color"] = "RED",
    ["sammy avatar"] = "RED",
    ["sammy uses in chat"] = ":3",
    ["what does sammy say in chat"] = ":3",
    ["sammy emoticon"] = ":3",
    ["sammys heritage"] = "NORTHAFRICAN",
    ["sammy connections"] = "NEWORLEANS",

    -- ═══════════════════════════════════════════════
    -- ===== MORE GAME FACTS =====
    -- ═══════════════════════════════════════════════
    ["what game is sammy cpo of"] = "DOBIGSTUDIOS",
    ["sammy title"] = "CPO",
    ["sammys role"] = "CPO",
    ["game creation date"] = "MAY162025",
    ["sab creation date"] = "MAY162025",
    ["may 16 2025"] = "STEALABRAINROT",
    ["what happened may 16 2025"] = "SABRELEASE",
    ["game platform"] = "ROBLOX",
    ["what platform is sab on"] = "ROBLOX",
    ["sab genre"] = "SIMULATOR",
    ["what type of game is sab"] = "SIMULATOR",
    ["sab max players"] = "8",
    ["max players in sab"] = "8",

    -- ═══════════════════════════════════════════════
    -- ===== REBIRTHS =====
    -- ═══════════════════════════════════════════════
    ["how many rebirths are there"] = "19",
    ["total rebirths in sab"] = "19",
    ["max rebirth"] = "19",
    ["highest rebirth"] = "19",
    ["rebirth 19"] = "19",

    -- ═══════════════════════════════════════════════
    -- ===== MORE MUTATION DATE/EVENT DETAILS =====
    -- ═══════════════════════════════════════════════
    ["when was bloodrot added"] = "JUNE72025",
    ["bloodrot release date"] = "JUNE72025",
    ["bloodrot event name"] = "BLOODMOON",
    ["when was candy added"] = "JULY42025",
    ["candy release date"] = "JULY42025",
    ["when was lava added"] = "JULY252025",
    ["lava release date"] = "JULY252025",
    ["lava event name"] = "MOLTEN",
    ["when was galaxy added"] = "AUGUST232025",
    ["galaxy release date"] = "AUGUST232025",
    ["galaxy event name"] = "GALACTIC",
    ["when was yin yang added"] = "SEPTEMBER272025",
    ["yin yang release date"] = "SEPTEMBER272025",
    ["when was radioactive added"] = "NOVEMBER152025",
    ["radioactive release date"] = "NOVEMBER152025",
    ["when was cursed added"] = "JANUARY32026",
    ["cursed release date"] = "JANUARY32026",
    ["when was divine added"] = "FEBRUARY282026",
    ["divine release date"] = "FEBRUARY282026",
    ["when was cyber added"] = "APRIL2026",
    ["cyber release date"] = "APRIL2026",
    ["when was phantom added"] = "JUNE132026",
    ["phantom release date"] = "JUNE132026",
    ["when was crystal added"] = "JULY252026",
    ["crystal release date"] = "JULY252026",
    ["crystal update"] = "59",
    ["when was eclipse added"] = "OCTOBER32026",
    ["eclipse release date"] = "OCTOBER32026",
    ["eclipse update"] = "69",

    -- ═══════════════════════════════════════════════
    -- ===== EVENT BRAINROT NAMES (Quiz answers) =====
    -- ═══════════════════════════════════════════════
    ["july 4th brainrot"] = "UNCLITOSAMITO",
    ["independence day brainrot"] = "UNCLITOSAMITO",
    ["4th of july brainrot"] = "UNCLITOSAMITO",
    ["what brainrot is from july 4th"] = "UNCLITOSAMITO",
    ["christmas owl brainrot"] = "BUHODENOELO",
    ["clock brainrot"] = "CLOCKETEIRABICICLETEIRA",
    ["orca brainrot"] = "ORCALEDON",
    ["spooky tv brainrot"] = "TELEMORTE",
    ["mouse satellite brainrot"] = "SATALITOCACASITO",
    ["noodle toilet brainrot"] = "NOODLESINITUALLETINI",

    -- ═══════════════════════════════════════════════
    -- ===== BRAINROT GOD INCOMES =====
    -- ═══════════════════════════════════════════════
    ["piccione macchina income"] = "225000",
    ["noo la polizia income"] = "280000",
    ["tentacolo tecnico income"] = "292500",
    ["dolphini jetskini income"] = "294500",
    ["how much does piccione macchina make"] = "225000",
    ["best brainrot god"] = "DOLPHINIJETSKINI",
    ["best brainrot god income"] = "294500",

    -- ═══════════════════════════════════════════════
    -- ===== FUSE RECIPES (known) =====
    -- ═══════════════════════════════════════════════
    ["plant bros recipe"] = "ORCHIDOXVENUSPINO",
    ["how to make plant bros"] = "ORCHIDOXVENUSPINO",
    ["orchidox and venuspino"] = "PLANTBROS",
    ["what do orchidox and venuspino make"] = "PLANTBROS",
    ["orchidox plus venuspino"] = "PLANTBROS",

    -- ═══════════════════════════════════════════════
    -- ===== BRAINROT FAMILIES =====
    -- ═══════════════════════════════════════════════
    ["dragon family"] = "DRAGONCANNELLONI",
    ["tralala family"] = "TRALALEROTALALA",
    ["sahur family"] = "TUNGTUNGTUNGSAHUR",
    ["sammyni family"] = "SAMMYNISPYDERINI",
    ["orca family"] = "ORCALEROORCALA",
    ["los family"] = "LOSTRIOS",
    ["grande family"] = "LAGRANDECOMBINASION",
    ["pumpkin family"] = "POTPUMPKIN",

    -- ═══════════════════════════════════════════════
    -- ===== BEE EVENT =====
    -- ═══════════════════════════════════════════════
    ["bee event currency"] = "HONEY",
    ["what currency does the bee event drop"] = "HONEY",
    ["bee event"] = "BEEEVENT",
    ["honey"] = "HONEY",
    ["bee lucky block"] = "BEELUCKYBLOCK",

    -- ═══════════════════════════════════════════════
    -- ===== MORE QUESTION VARIANTS =====
    -- ═══════════════════════════════════════════════

    -- "Who" questions
    ["who created steal a brainrot"] = "SAMMY",
    ["who is spydersammy"] = "SAMMY",
    ["who owns steal a brainrot"] = "SAMMY",
    ["who is the creator of sab"] = "SAMMY",
    ["who programmed sab"] = "HASTED",
    ["who is hasted"] = "LEADPROGRAMMER",
    ["who is steak"] = "ADMINABUSEHOST",
    ["who is caylus"] = "ADMINABUSEHOST",

    -- "When" questions
    ["when was sab created"] = "MAY162025",
    ["when was the game released"] = "MAY162025",
    ["when is admin abuse"] = "TUESDAYANDSATURDAY",
    ["when is taco tuesday in sab"] = "TUESDAY6PMET",
    ["when was the admin war"] = "AUGUST232025",
    ["when was haunted fuse added"] = "OCTOBER32026",
    ["when was rng machine added"] = "AUGUST2026",

    -- "Where" questions
    ["where is sammy from"] = "BRAZIL",
    ["where was sab created"] = "ROBLOX",
    ["where does phoenix come from"] = "HAUNTEDFUSE",
    ["where does griffin come from"] = "DIVINEFUSE",
    ["where does dragon skeletonini come from"] = "SKULLLUCKYBLOCK",
    ["where does festive 67 come from"] = "SANTASFUSE",
    ["where does headless horseman come from"] = "WITCHFUSE",
    ["where does plant bros come from"] = "HAUNTEDFUSE",
    ["where does kraken come from"] = "OCTOLUCKYBLOCK",
    ["where does dragon aquanini come from"] = "SUMMERFUSE",
    ["where does noo my candy come from"] = "TRICKORTREAT",
    ["where does rocketini frostini come from"] = "RNGMACHINE",

    -- "How much" questions
    ["how much does mythic lucky block cost"] = "2500000",
    ["how much does brainrot god lucky block cost"] = "25000000",
    ["how much does secret lucky block cost"] = "750000000",
    ["how much does admin lucky block cost"] = "100000000",
    ["how much does taco lucky block cost"] = "50000000",
    ["how much does los lucky blocks cost"] = "250000000",
    ["how much does skull lucky block cost"] = "500000000",
    ["how much does octo lucky block cost"] = "600000000",
    ["how much does egg lucky block cost"] = "500000000",
    ["how much does heart lucky block cost"] = "350000000",
    ["how much is noo my candy"] = "900000000",
    ["how much does eclipse phoenix make"] = "5700000000",
    ["how much does plant bros cost"] = "300000000000",

    -- ═══════════════════════════════════════════════
    -- ===== EVEN MORE COMPOUND COMBOS =====
    -- ═══════════════════════════════════════════════
    ["name and eclipse"] = "SAMMYECLIPSE",
    ["eclipse and name"] = "ECLIPSESAMMY",
    ["mutation and age"] = "ECLIPSE24",
    ["age and mutation"] = "24ECLIPSE",
    ["newest mutation and age"] = "ECLIPSE24",
    ["cat and mutation"] = "NOVAECLIPSE",
    ["mutation and cat"] = "ECLIPSENOVA",
    ["food and color and number"] = "PIZZABLUE7",
    ["color and food and number"] = "BLUEPIZZA7",
    ["name and cat and age"] = "SAMMYNOVA24",
    ["age and cat and name"] = "24NOVASAMMY",
    ["name and color and age"] = "SAMMYBLUE24",
    ["age and color and name"] = "24BLUESAMMY",
    ["mutation and machine count"] = "1520",
    ["machine count and mutation count"] = "2015",
    ["name and birthday"] = "SAMMYFEBRUARY25",
    ["birthday and name"] = "FEBRUARY25SAMMY",
    ["cat and player"] = "NOVARONALDO",
    ["player and cat"] = "RONALDONOVA",
    ["eclipse and crystal"] = "ECLIPSECRYSTAL",
    ["crystal and eclipse"] = "CRYSTALECLIPSE",
    ["phantom and crystal"] = "PHANTOMCRYSTAL",
    ["crystal and phantom"] = "CRYSTALPHANTOM",
    ["haunted fuse and eclipse"] = "HAUNTEDFUSEECLIPSE",
    ["eclipse and haunted fuse"] = "ECLIPSEHAUNTEDFUSE",
    ["name backwards and age"] = "YMMAS24",
    ["age and name backwards"] = "24YMMAS",
    ["cat backwards and name"] = "AVONSAMMY",
    ["name and cat backwards"] = "SAMMYAVON",
    ["food and player and age"] = "PIZZARONALDO24",
    ["name and discord"] = "SAMMYBLOSSOM",
    ["discord and name"] = "BLOSSOMSAMMY",
    ["programmer and name"] = "HASTEDSAMMY",
    ["name and programmer"] = "SAMMYHASTED",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== MASSIVE EXPANSION: ALL BRAINROTS BY RARITY =====
    -- ═══════════════════════════════════════════════════════════════

    -- ===== COMMON BRAINROTS (Full List) =====
    ["noobini pizzanini cost"] = "25",
    ["lirili larila cost"] = "250",
    ["tim cheese cost"] = "500",
    ["fluriflura cost"] = "750",
    ["fluriflura"] = "FLURIFLURA",
    ["talpa di fero"] = "TALPADIFERO",
    ["talpa di fero cost"] = "1000",
    ["noobini santanini"] = "NOOBINISANTANINI",
    ["noobini santanini cost"] = "1100",
    ["svinina bombardino"] = "SVININA BOMBARDINO",
    ["svinina bombardino cost"] = "1200",
    ["raccooni jandelini"] = "RACCOONIJANDELINI",
    ["raccooni jandelini cost"] = "1300",
    ["pipi kiwi cost"] = "1500",
    ["tartaragno cost"] = "1500",
    ["pipi corni cost"] = "1700",
    ["holy arepa"] = "HOLYAREPA",
    ["holy arepa cost"] = "1700",

    -- ===== RARE BRAINROTS =====
    ["trippi troppi cost"] = "2000",
    ["tung tung tung sahur cost"] = "3000",
    ["gangster footera"] = "GANGSTERFOOTERA",
    ["gangster footera cost"] = "4000",
    ["bandito bobritto"] = "BANDITOBOBRITTO",
    ["bandito bobritto cost"] = "4500",
    ["boneca ambalabu"] = "BONECAAMBALABU",
    ["boneca ambalabu cost"] = "5000",
    ["cacto hipopotamo"] = "CACTOHIPOPOTAMO",
    ["cacto hipopotamo cost"] = "6500",
    ["ta ta ta ta sahur"] = "TATATATATASAHUR",
    ["ta ta ta ta sahur cost"] = "7500",
    ["tric trac baraboom"] = "TRICTRACBARABOOM",
    ["tric trac baraboom cost"] = "9000",
    ["frogo elfo"] = "FROGOELFO",
    ["frogo elfo cost"] = "9200",
    ["pipi avocado"] = "PIPIAVOCADO",
    ["pipi avocado cost"] = "9500",
    ["pengolino nuvoletto"] = "PENGOLINONUVOLETTO",
    ["pengolino nuvoletto cost"] = "9600",

    -- ===== EPIC BRAINROTS =====
    ["cupcake koala"] = "CUPCAKEKOALA",
    ["cupcake koala cost"] = "8000",
    ["pinealotto fruttarino"] = "PINEALOTTOFRUTTARINO",
    ["pinealotto fruttarino cost"] = "9700",
    ["cappuccino assassino cost"] = "10000",
    ["bandito axolito"] = "BANDITOAXOLITO",
    ["bandito axolito cost"] = "12500",
    ["brr brr patapim cost"] = "15000",
    ["avocadini antilopini"] = "AVOCADINIANTILOPINI",
    ["avocadini antilopini cost"] = "17500",
    ["trulimero trulicina"] = "TRULIMEROTRULICINA",
    ["trulimero trulicina cost"] = "20000",
    ["bambini crostini"] = "BAMBINICROSTINI",
    ["bambini crostini cost"] = "22500",
    ["malame amarele"] = "MALAMEAMARELE",
    ["malame amarele cost"] = "23500",
    ["bananita dolphinita"] = "BANANITADOLPHINITA",
    ["bananita dolphinita cost"] = "25000",
    ["perochello lemonchello"] = "PEROCHELOLEMONCHELLO",
    ["perochello lemonchello cost"] = "27500",
    ["brri brri bicus dicus bombicus"] = "BRRIBRRIBICUSDICUSBOMBICUS",
    ["brri brri bicus dicus bombicus cost"] = "30000",
    ["avocadini guffo"] = "AVOCADINIGUFFO",
    ["avocadini guffo cost"] = "35000",
    ["ti ti ti sahur"] = "TITITISAHUR",
    ["ti ti ti sahur cost"] = "37500",
    ["mangolini parrocini"] = "MANGOLINIPARROCINI",
    ["mangolini parrocini cost"] = "38500",
    ["frogato pirato"] = "FROGATOPIRATO",
    ["frogato pirato cost"] = "39000",
    ["salamino penguino cost"] = "40000",
    ["gato celesto"] = "GATOCELESTO",
    ["gato celesto cost"] = "40000",
    ["doi doi do"] = "DOIDOIDO",
    ["doi doi do cost"] = "41000",
    ["penguin tree"] = "PENGUINTREE",
    ["penguin tree cost"] = "42000",
    ["wombo rollo"] = "WOMBOROLLO",
    ["wombo rollo cost"] = "42500",
    ["penguino cocosino"] = "PENGUINOCONOSINO",
    ["penguino cocosino cost"] = "45000",
    ["mummio rappitto"] = "MUMMIORAPPITTO",
    ["mummio rappitto cost"] = "47500",

    -- ===== LEGENDARY BRAINROTS =====
    ["burbaloni loliloli"] = "BURBALONILOLILOLI",
    ["burbaloni loliloli cost"] = "35000",
    ["burbaloni loliloli income"] = "200",
    ["chimpanzini bananini cost"] = "50000",
    ["chimpanzini bananini income"] = "300",
    ["tirilikalika tirilikalako"] = "TIRILILKALIKATIRILIKALAKO",
    ["tirilikalika tirilikalako cost"] = "75000",
    ["ballerina cappuccina cost"] = "100000",
    ["ballerina cappuccina income"] = "500",
    ["chef crabracadabra"] = "CHEFCRABRACADABRA",
    ["chef crabracadabra cost"] = "150000",
    ["lionel cactuseli"] = "LIONELCACTUSELI",
    ["lionel cactuseli cost"] = "175000",
    ["glorbo fruttodrillo"] = "GLORBOFRUTTODRILLO",
    ["glorbo fruttodrillo cost"] = "200000",
    ["quivioli ameleonni"] = "QUIVIOLIAMEELEONNI",
    ["quivioli ameleonni cost"] = "225000",
    ["blueberrinni octopusini"] = "BLUEBERRINNIOCTOPUSINI",
    ["blueberrinni octopusini cost"] = "250000",
    ["clickerino crabo"] = "CLICKERINOCRABO",
    ["clickerino crabo cost"] = "250000",
    ["caramello filtrello"] = "CARAMELLOFILTRELLO",
    ["caramello filtrello cost"] = "255000",
    ["pipi potato"] = "PIPIPOTATO",
    ["pipi potato cost"] = "256000",
    ["strawberrelli flamingelli"] = "STRAWBEERRELLIFLAMINGELLI",
    ["strawberrelli flamingelli cost"] = "275000",
    ["cocosini mama"] = "COCOSINIMAMA",
    ["cocosini mama cost"] = "285000",
    ["pandaccini bananini"] = "PANDACCINIBANANINI",
    ["pandaccini bananini cost"] = "300000",
    ["quackula"] = "QUACKULA",
    ["quackula cost"] = "310000",
    ["pi pi watermelon"] = "PIPIWATERMELON",
    ["pi pi watermelon cost"] = "315000",
    ["signore carapace"] = "SIGNORECARAPACE",
    ["signore carapace cost"] = "320000",
    ["sigma boy cost"] = "325000",
    ["sigma girl cost"] = "325000",
    ["buho del cielo"] = "BUHODELCIELO",
    ["buho del cielo cost"] = "325000",
    ["chocco bunny"] = "CHOCCOBUNNY",
    ["chocco bunny cost"] = "327500",
    ["puffaball"] = "PUFFABALL",
    ["puffaball cost"] = "330000",
    ["sealo regalo"] = "SEALOREGALO",
    ["sealo regalo cost"] = "342000",
    ["electro quacko"] = "ELECTROQUACKO",
    ["electro quacko cost"] = "345000",
    ["buho de fuego"] = "BUHODEFUEGO",
    ["buho de fuego cost"] = "345000",
    ["seraphino gruyero"] = "SERAPHINO GRUYERO",
    ["seraphino gruyero cost"] = "347500",

    -- ===== MYTHIC BRAINROTS =====
    ["frigo camelo"] = "FRIGOCAMELO",
    ["frigo camelo cost"] = "300000",
    ["harpuccino"] = "HARPUCCINO",
    ["harpuccino cost"] = "347500",
    ["harpuccino income"] = "14000",
    ["orangutini ananassini"] = "ORANGUTINIANANASSINI",
    ["orangutini ananassini cost"] = "400000",
    ["rhino toasterino"] = "RHINOTOASTERINO",
    ["rhino toasterino cost"] = "450000",
    ["bombardiro crocodilo cost"] = "500000",
    ["brutto gialutto"] = "BRUTTOGIALUTTO",
    ["brutto gialutto cost"] = "600000",
    ["spioniro golubiro"] = "SPIONIRO GOLUBIRO",
    ["spioniro golubiro cost"] = "750000",
    ["bombombini gusini"] = "BOMBOMBINIGUSINI",
    ["bombombini gusini cost"] = "1000000",
    ["zibra zubra zibralini"] = "ZIBRAZUBRAZIBRALINI",
    ["zibra zubra zibralini cost"] = "1000000",
    ["tigrilini watermelini"] = "TIGRILINIWATERMELINI",
    ["tigrilini watermelini cost"] = "1000000",
    ["avocadorilla"] = "AVOCADORILLA",
    ["avocadorilla cost"] = "2000000",
    ["cavallo virtuoso"] = "CAVALLOVIRTUOSO",
    ["cavallo virtuoso cost"] = "2500000",
    ["te te te sahur"] = "TETETETESAHUR",
    ["te te te sahur cost"] = "2500000",
    ["gorillo subwoofero cost"] = "2700000",
    ["gorillo watermelondrillo"] = "GORILLOWATERMELONDRILLO",
    ["gorillo watermelondrillo cost"] = "3000000",
    ["stoppo luminino"] = "STOPPOLUMININO",
    ["stoppo luminino cost"] = "3000000",
    ["tracoducotulu delapeladustuz"] = "TRACODUCOTULU",
    ["tracoducotulu delapeladustuz cost"] = "3000000",
    ["tob tobi tobi"] = "TOBTOBITOBI",
    ["tob tobi tobi cost"] = "3500000",
    ["lerulerulerule"] = "LERULERULERULE",
    ["lerulerulerule cost"] = "3500000",
    ["ganganzelli trulala"] = "GANGANZELLI TRULALA",
    ["ganganzelli trulala cost"] = "4000000",
    ["magi ribbitini"] = "MAGIRIBBITINI",
    ["magi ribbitini cost"] = "4000000",
    ["rhino helicopterino"] = "RHINOHELICOPTERINO",
    ["rhino helicopterino cost"] = "4100000",
    ["los noobinis"] = "LOSNOOBINIS",
    ["los noobinis cost"] = "4300000",
    ["cachorrito melonito"] = "CACHORRITOMELONITO",
    ["cachorrito melonito cost"] = "4400000",
    ["spongini quackini"] = "SPONGINIQUACKINI",
    ["spongini quackini cost"] = "4400000",
    ["bee loco"] = "BEELOCO",
    ["bee loco cost"] = "4500000",
    ["elefanto frigo"] = "ELEFANTOFRIGO",
    ["elefanto frigo cost"] = "4500000",
    ["berenjello angello"] = "BERENJELLOANGELLO",
    ["berenjello angello cost"] = "4600000",
    ["carrotini brainini"] = "CARROTINIBRAININI",
    ["carrotini brainini cost"] = "4700000",
    ["cocoteddy"] = "COCOTEDDY",
    ["cocoteddy cost"] = "4700000",
    ["centrucci nuclucci"] = "CENTRUCCINUCLUCCI",
    ["centrucci nuclucci cost"] = "4800000",
    ["toiletto focaccino"] = "TOILETTOFOCACCINO",
    ["toiletto focaccino cost"] = "4800000",
    ["bananito bandito"] = "BANANITOBANDITO",
    ["bananito bandito cost"] = "4900000",
    ["tree tree tree sahur"] = "TREETREETREETREESAHUR",
    ["tree tree tree sahur cost"] = "4900000",
    ["bucketoro"] = "BUCKETORO",
    ["bucketoro cost"] = "5700000",
    ["orbi mochi"] = "ORBIMOCHI",
    ["orbi mochi cost"] = "6000000",

    -- ===== BRAINROT GOD (Full List with costs & incomes) =====
    ["fizzy soda"] = "FIZZYSODA",
    ["fizzy soda cost"] = "4900000",
    ["fizzy soda income"] = "17200",
    ["cocofanto elefanto"] = "COCOFANTOELEFANTO",
    ["cocofanto elefanto cost"] = "5000000",
    ["cocofanto elefanto income"] = "10000",
    ["antonio"] = "ANTONIO",
    ["antonio cost"] = "6000000",
    ["antonio income"] = "18500",
    ["girafa celestre"] = "GIRAFACELESTRE",
    ["girafa celestre cost"] = "7500000",
    ["gattatino nyanino"] = "GATTATINONYANINO",
    ["gattatino nyanino cost"] = "7500000",
    ["gattatino nyanino income"] = "35000",
    ["gattatino neonino"] = "GATTATINONEONINO",
    ["gattatino neonino cost"] = "7500000",
    ["chihuanini taconini"] = "CHIHUANINITACONINI",
    ["chihuanini taconini cost"] = "8500000",
    ["chihuanini taconini income"] = "45000",
    ["matteo"] = "MATTEO",
    ["matteo cost"] = "10000000",
    ["matteo income"] = "50000",
    ["tralalero tralala cost"] = "10000000",
    ["tralalero tralala income"] = "50000",
    ["los crocodillitos"] = "LOSCROCODILLITOS",
    ["los crocodillitos cost"] = "12500000",
    ["tigroligre frutonni"] = "TIGROLIGREFRUTONNI",
    ["tigroligre frutonni cost"] = "15000000",
    ["tigroligre frutonni income"] = "60000",
    ["odin din din dun"] = "ODINDINDINDUN",
    ["odin din din dun cost"] = "15000000",
    ["orcalero orcala"] = "ORCALEROORCALA",
    ["orcalero orcala cost"] = "15000000",
    ["orcalero orcala income"] = "100000",
    ["money money man"] = "MONEYMONEYMAN",
    ["money money man cost"] = "17500000",
    ["alessio"] = "ALESSIO",
    ["alessio cost"] = "17500000",
    ["unclito samito cost"] = "20000000",
    ["unclito samito income"] = "65000",
    ["statutino libertino"] = "STATUTINOLIBERTINO",
    ["statutino libertino cost"] = "20000000",
    ["tipi topi taco"] = "TIPITOPITACO",
    ["tipi topi taco cost"] = "20000000",
    ["tralalita tralala"] = "TRALALITA TRALALA",
    ["tralalita tralala cost"] = "20000000",
    ["tukanno banana"] = "TUKANNOBANANA",
    ["tukanno banana cost"] = "22500000",
    ["extinct ballerina"] = "EXTINCTBALLERINA",
    ["extinct ballerina cost"] = "23500000",
    ["vampira cappucina"] = "VAMPIRACAPPUCINA",
    ["vampira cappucina cost"] = "24500000",
    ["espresso signora"] = "ESPRESSOSIGNORA",
    ["espresso signora cost"] = "25000000",
    ["trenozosturzzo turbo 3000"] = "TRENOZOSTURRZOTURBO3000",
    ["trenozosturzzo turbo 3000 cost"] = "25000000",
    ["bulbito bandito traktorito"] = "BULBITOBANDITOTRAKTORITO",
    ["bulbito bandito traktorito cost"] = "25000000",
    ["urubini flamenguini"] = "URUBINIFLAMENGUINI",
    ["urubini flamenguini cost"] = "30000000",
    ["trippi troppi troppa trippa"] = "TRIPPITROPPITROPPOTRIPPA",
    ["trippi troppi troppa trippa cost"] = "30000000",
    ["capi taco"] = "CAPITACO",
    ["capi taco cost"] = "31000000",
    ["sundrilla sundae"] = "SUNDRILLASUNDAE",
    ["sundrilla sundae cost"] = "31000000",
    ["los chihuaninis"] = "LOSCHIHUANINIS",
    ["los chihuaninis cost"] = "32000000",
    ["divino platypio"] = "DIVINOPLATYPIO",
    ["divino platypio cost"] = "32000000",
    ["gattito tacoto"] = "GATTITOTACOTO",
    ["gattito tacoto cost"] = "32500000",
    ["las capuchinas"] = "LASCAPUCHINAS",
    ["las capuchinas cost"] = "32500000",
    ["ballerino lololo"] = "BALLERINOLOLO",
    ["ballerino lololo cost"] = "35000000",
    ["los tungtungtungcitos"] = "LOSTUNGTUNGTUNGCITOS",
    ["los tungtungtungcitos cost"] = "37500000",
    ["pakrahmatmamat"] = "PAKRAHMATMAMAT",
    ["pakrahmatmamat cost"] = "37500000",
    ["piccione macchina cost"] = "40000000",
    ["piccione macchina income"] = "225000",
    ["pakrahmatmatina"] = "PAKRAHMATMATINA",
    ["pakrahmatmatina cost"] = "40500000",
    ["los bombinitos"] = "LOSBOMBINITOS",
    ["los bombinitos cost"] = "42500000",
    ["tractoro dinosauro"] = "TRACTORODINOSAURO",
    ["tractoro dinosauro cost"] = "42500000",
    ["brr es teh patipum"] = "BRRESTEHPATIPUM",
    ["brr es teh patipum cost"] = "45000000",
    ["cacasito satalito"] = "CACASITOSATALITO",
    ["cacasito satalito cost"] = "45000000",
    ["orcalita orcala"] = "ORCALITAORCALA",
    ["orcalita orcala cost"] = "45000000",
    ["aquanaut"] = "AQUANAUT",
    ["aquanaut cost"] = "45500000",
    ["tartaruga cisterna"] = "TARTARUGACISTERNA",
    ["tartaruga cisterna cost"] = "45000000",
    ["snailenzo"] = "SNAILENZO",
    ["snailenzo cost"] = "45000000",
    ["corn corn corn sahur"] = "CORNCORNCORNSAHUR",
    ["corn corn corn sahur cost"] = "45000000",
    ["squalanana"] = "SQUALANANA",
    ["squalanana cost"] = "45000000",
    ["los orcalitos cost"] = "45000000",
    ["los orcalitos income"] = "310000",
    ["dug dug dug"] = "DUGDUGDUG",
    ["dug dug dug cost"] = "45500000",
    ["trenotubo axolotrico 9000"] = "TRENOTUBOAXOLOTRICO9000",
    ["trenotubo axolotrico 9000 cost"] = "45500000",
    ["crabbo limonetta"] = "CRABBOLIMONETTA",
    ["crabbo limonetta cost"] = "46000000",
    ["los tipi tacos"] = "LOSTIPITACOS",
    ["los tipi tacos cost"] = "46000000",
    ["tootini shrimpini"] = "TOOTINISHRIMPINI",
    ["tootini shrimpini cost"] = "46000000",
    ["lumaca malefica"] = "LUMACAMALEFICA",
    ["lumaca malefica cost"] = "46500000",
    ["piccionetta macchina"] = "PICCIONETTAMACCHINA",
    ["piccionetta macchina cost"] = "47000000",
    ["bunny tralala"] = "BUNNYTRALALA",
    ["bunny tralala cost"] = "47000000",
    ["boba panda"] = "BOBAPANDA",
    ["boba panda cost"] = "47000000",
    ["mastodontico telepiedone"] = "MASTODONTICOTELEPIEDONE",
    ["mastodontico telepiedone cost"] = "47500000",
    ["los gattitos"] = "LOSGATTITOS",
    ["los gattitos cost"] = "47500000",
    ["bambu bambu sahur"] = "BAMBUBAMBUSAHUR",
    ["bambu bambu sahur cost"] = "47500000",
    ["anpali babel"] = "ANPALIBABEL",
    ["anpali babel cost"] = "48000000",
    ["astrolero cervalero"] = "ASTROLEROCERVALERO",
    ["astrolero cervalero cost"] = "48000000",
    ["lemonita splashita"] = "LEMONITASPLASHITA",
    ["lemonita splashita cost"] = "48000000",
    ["cappuccino clownino"] = "CAPPUCCINOCLOWNINO",
    ["cappuccino clownino cost"] = "48000000",
    ["bombardini tortinii"] = "BOMBARDINITORTINII",
    ["bombardini tortinii cost"] = "50000000",
    ["brasilini berimbini"] = "BRASILINIBERIMBINI",
    ["brasilini berimbini cost"] = "55500000",
    ["patteo"] = "PATTEO",
    ["patteo cost"] = "57500000",
    ["belula beluga"] = "BELULABELUGA",
    ["belula beluga cost"] = "60000000",
    ["krupuk pagi pagi"] = "KRUPUKPAGIPAGI",
    ["krupuk pagi pagi cost"] = "60000000",
    ["skull skull skull"] = "SKULLSKULLSKULL",
    ["skull skull skull cost"] = "60000000",
    ["cocoa assassino"] = "COCOAASSASSINO",
    ["cocoa assassino cost"] = "60000000",
    ["tentacolo tecnico cost"] = "62500000",
    ["tentacolo tecnico income"] = "295000",
    ["dolphini jetskini cost"] = "64500000",
    ["dolphini jetskini income"] = "294500",
    ["pop pop sahur"] = "POPPOPSAHUR",
    ["pop pop sahur cost"] = "65000000",
    ["noo la polizia cost"] = "67000000",
    ["noo la polizia income"] = "280000",
    ["karkerheart luvkur"] = "KARKERHEARTLUVKUR",
    ["karkerheart luvkur cost"] = "67500000",
    ["clovkur kurkur"] = "CLOVKURKURKUR",
    ["clovkur kurkur cost"] = "70000000",
    ["eggdin egg egg dun"] = "EGGDINEGGEGGDUN",
    ["eggdin egg egg dun cost"] = "72500000",
    ["dumborino miracello"] = "DUMBORINOMIRACELLO",
    ["dumborino miracello cost"] = "75000000",
    ["flippo marino"] = "FLIPPOMARINO",
    ["flippo marino cost"] = "75500000",
    ["robo grafito"] = "ROBOGRAFITO",
    ["robo grafito cost"] = "76000000",
    ["pretzo robo"] = "PRETZOROBO",
    ["pretzo robo cost"] = "77000000",

    -- ===== SECRET BRAINROTS (Full List with costs) =====
    ["la vacca saturno saturnita"] = "LAVACCASATURNOSATURNITA",
    ["la vacca saturno saturnita cost"] = "50000000",
    ["pandanini frostini"] = "PANDANINIFROSTINI",
    ["pandanini frostini cost"] = "64000000",
    ["bisonte giuppitere"] = "BISONTEGIUPPITERE",
    ["bisonte giuppitere cost"] = "75000000",
    ["blackhole goat"] = "BLACKHOLEGOAT",
    ["blackhole goat cost"] = "75000000",
    ["jackorilla cost"] = "80000000",
    ["agarrini ia palini"] = "AGARRINIIAPALINI",
    ["agarrini ia palini cost"] = "80000000",
    ["chachechi"] = "CHACHECHI",
    ["chachechi cost"] = "85000000",
    ["karkerkar kurkur"] = "KARKERKARKURKUR",
    ["karkerkar kurkur cost"] = "100000000",
    ["los tortus"] = "LOSTORTUS",
    ["los tortus cost"] = "100000000",
    ["los matteos"] = "LOSMATTEOS",
    ["los matteos cost"] = "100000000",
    ["sammyni spyderini cost"] = "100000000",
    ["trenostruzzo turbo 4000"] = "TRENOSTRUZZOTURBO4000",
    ["trenostruzzo turbo 4000 cost"] = "100000000",
    ["chimpanzini spiderini"] = "CHIMPANZINISPIDERINI",
    ["chimpanzini spiderini cost"] = "100000000",
    ["boatito auratito"] = "BOATITOAURATITO",
    ["boatito auratito cost"] = "115000000",
    ["fragola la la la"] = "FRAGOLALALALA",
    ["fragola la la la cost"] = "125000000",
    ["dul dul dul"] = "DULDULDUL",
    ["dul dul dul cost"] = "150000000",
    ["la vacca prese presente"] = "LAVACCAPRESEPRESENTE",
    ["la vacca prese presente cost"] = "160000000",
    ["frankentteo cost"] = "175000000",
    ["los trios"] = "LOSTRIOS",
    ["los trios cost"] = "175000000",
    ["karker sahur"] = "KARKERSAHUR",
    ["karker sahur cost"] = "185000000",
    ["los tralaleritos"] = "LOSTRALALERITOS",
    ["los tralaleritos cost"] = "100000000",
    ["zombie tralala cost"] = "100000000",
    ["la cucaracha cost"] = "110000000",
    ["vulturino skeletono cost"] = "110000000",
    ["guerriro digitale"] = "GUERRIRODIGITALE",
    ["guerriro digitale cost"] = "120000000",
    ["extinct tralalero"] = "EXTINCTTRALALERO",
    ["extinct tralalero cost"] = "125000000",
    ["yess my examine"] = "YESSMYEXAMINE",
    ["yess my examine cost"] = "130000000",
    ["extinct matteo"] = "EXTINCTMATTEO",
    ["extinct matteo cost"] = "140000000",
    ["las tralaleritas"] = "LASTRALALERITAS",
    ["las tralaleritas cost"] = "150000000",
    ["rocco disco"] = "ROCCODISCO",
    ["rocco disco cost"] = "150000000",
    ["las vaquitas saturnitas"] = "LASVAQUITASSATURNITAS",
    ["las vaquitas saturnitas cost"] = "160000000",
    ["pumpkin spyderini cost"] = "165000000",
    ["job job job sahur"] = "JOBJOBJOBJOBSAHUR",
    ["job job job sahur cost"] = "175000000",
    ["los karkeritos"] = "LOSKARKERITOS",
    ["los karkeritos cost"] = "200000000",
    ["graipuss medussi"] = "GRAIPUSSMEDUSSI",
    ["graipuss medussi cost"] = "200000000",
    ["santteo cost"] = "210000000",
    ["fishboard"] = "FISHBOARD",
    ["fishboard cost"] = "215000000",
    ["buntteo"] = "BUNTTEO",
    ["buntteo cost"] = "225000000",
    ["la vacca jacko linterino"] = "LAVACCAJACKOLINTERINO",
    ["la vacca jacko linterino cost"] = "225000000",
    ["triplito tralaleritos"] = "TRIPLITOTRALALERITOS",
    ["triplito tralaleritos cost"] = "230000000",
    ["trickolino cost"] = "235000000",
    ["paradiso axolottino"] = "PARADISOAXOLOTTINO",
    ["paradiso axolottino cost"] = "235000000",
    ["goat"] = "GOAT",
    ["goat cost"] = "237600000",
    ["giftini spyderini cost"] = "240000000",
    ["los spyderinis"] = "LOSSPYDERINIS",
    ["los spyderinis cost"] = "250000000",
    ["perrito burrito"] = "PERRITOBURRITO",
    ["perrito burrito cost"] = "250000000",
    ["bombardiro vaccariro"] = "BOMBARDIROVACCARIRO",
    ["bombardiro vaccariro cost"] = "255000000",
    ["1x1x1x1 cost"] = "255500000",
    ["la vacca lepre lepreino"] = "LAVACCALEPRELEPREINO",
    ["la vacca lepre lepreino cost"] = "255500000",
    ["los cucarachas"] = "LOSCUCARACHAS",
    ["los cucarachas cost"] = "300000000",
    ["easter easter sahur"] = "EASTEREASTERSAHUR",
    ["easter easter sahur cost"] = "300000000",
    ["please my present"] = "PLEASEMYPRESENT",
    ["please my present cost"] = "350000000",
    ["cuadramat and pakrahmatmamat"] = "CUADRAMATANDPAKRAHMATMAMAT",
    ["cuadramat and pakrahmatmamat cost"] = "400000000",
    ["los jobcitos"] = "LOSJOBCITOS",
    ["los jobcitos cost"] = "500000000",
    ["nooo my hotspot"] = "NOOOMYHOTSPOT",
    ["nooo my hotspot cost"] = "500000000",
    ["noo my examine"] = "NOOMYEXAMINE",
    ["noo my examine cost"] = "525000000",
    ["telemorte cost"] = "550000000",
    ["telemorte income"] = "2000000",
    ["la sahur combinasion cost"] = "550000000",
    ["list list list sahur"] = "LISTLISTLISTSAHUR",
    ["list list list sahur cost"] = "550000000",
    ["bunny bunny bunny sahur"] = "BUNNYBUNNYBUNNYSAHUR",
    ["bunny bunny bunny sahur cost"] = "575000000",
    ["to to to sahur"] = "TOTOTOSAHUR",
    ["to to to sahur cost"] = "575000000",
    ["glaciator"] = "GLACIATOR",
    ["glaciator cost"] = "580000000",
    ["pirulitoita bicicletaire"] = "PIRULITOITABICICLETAIRE",
    ["pirulitoita bicicletaire cost"] = "600000000",
    ["25"] = "25",
    ["25 cost"] = "600000000",
    ["santa hotspot cost"] = "625000000",
    ["horegini boom"] = "HOREGINIBOOM",
    ["horegini boom cost"] = "650000000",
    ["buho de volto"] = "BUHODEVOLTO",
    ["buho de volto cost"] = "650000000",
    ["quesadilla crocodila"] = "QUESADILLACROCODILA",
    ["quesadilla crocodila cost"] = "700000000",
    ["pot pumpkin cost"] = "700000000",
    ["naughty naughty"] = "NAUGHTYNAUGHTY",
    ["naughty naughty cost"] = "700000000",
    ["cupid cupid sahur cost"] = "715000000",
    ["ho ho ho sahur cost"] = "725000000",
    ["mi gatito"] = "MIGATITO",
    ["mi gatito cost"] = "725000000",
    ["chicleteira bicicleteira cost"] = "750000000",
    ["eid eid eid sahur"] = "EIDEIDEIDSAHUR",
    ["eid eid eid sahur cost"] = "750000000",
    ["spaghetti tualetti cost"] = "750000000",
    ["spaghetti tualetti income"] = "6000000",
    ["quesadillo vampiro"] = "QUESADILLOVAMPIRO",
    ["quesadillo vampiro cost"] = "750000000",
    ["brunito marsito"] = "BRUNITOMARSITO",
    ["brunito marsito cost"] = "750000000",
    ["luck luck luck sahur"] = "LUCKLUCKLUCKSAHUR",
    ["luck luck luck sahur cost"] = "800000000",
    ["flancito"] = "FLANCITO",
    ["flancito cost"] = "800000000",
    ["chill puppy"] = "CHILLPUPPY",
    ["chill puppy cost"] = "800000000",
    ["burrito bandito"] = "BURRITOBANDITO",
    ["burrito bandito cost"] = "800000000",
    ["chicleteirina bicicleteirina"] = "CHICLETEIRINABICICLETEIRINA",
    ["chicleteirina bicicleteirina cost"] = "850000000",
    ["granny"] = "GRANNY",
    ["granny cost"] = "850000000",
    ["los bunitos"] = "LOSBUNITOS",
    ["los bunitos cost"] = "865000000",
    ["los quesadillas"] = "LOSQUESADILLAS",
    ["los quesadillas cost"] = "875000000",
    ["futbolini skatini"] = "FUTBOLINISKATINI",
    ["futbolini skatini cost"] = "875000000",
    ["noo my candy cost"] = "900000000",
    ["noo my candy income"] = "5000000",
    ["arcadopus"] = "ARCADOPUS",
    ["arcadopus cost"] = "900000000",
    ["los nooo my hotspotsitos"] = "LOSNOOOMYHOTSPOTSITOS",
    ["los nooo my hotspotsitos cost"] = "1000000000",
    ["serafinna medusella cost"] = "1000000000",
    ["la grande combinasion cost"] = "1000000000",
    ["la grande combinasion income"] = "10000000",
    ["la easter grande"] = "LAEASTERGRANDE",
    ["la easter grande cost"] = "1000000000",
    ["rang ring bus"] = "RANGRINGBUS",
    ["rang ring bus cost"] = "1100000000",
    ["flipa sandala"] = "FLIPASANDALA",
    ["flipa sandala cost"] = "1100000000",
    ["guest 666 cost"] = "1100000000",
    ["guest 666 income"] = "6600000",
    ["los mi gatitos"] = "LOSMIGATITOS",
    ["los mi gatitos cost"] = "1200000000",
    ["ombrello topolino"] = "OMBRELLOTOPOLINO",
    ["ombrello topolino cost"] = "1200000000",
    ["los chicleteiras"] = "LOSCHICLETEIRAS",
    ["los chicleteiras cost"] = "1200000000",
    ["noo my eggs"] = "NOOMYEGGS",
    ["noo my eggs cost"] = "1200000000",
    ["67 cost"] = "1200000000",
    ["donkeyturbo express"] = "DONKEYTURBOEXPRESS",
    ["donkeyturbo express cost"] = "1200000000",
    ["mariachi corazoni cost"] = "1200000000",
    ["mariachi corazoni income"] = "12500000",
    ["los burritos"] = "LOSBURRITOS",
    ["los burritos cost"] = "1400000000",
    ["los 25"] = "LOS25",
    ["los 25 cost"] = "1500000000",
    ["tacorillo crocodillo"] = "TACORILLOCROCODILLO",
    ["tacorillo crocodillo cost"] = "1500000000",
    ["swag soda"] = "SWAGSODA",
    ["swag soda cost"] = "1800000000",
    ["noo my heart cost"] = "1800000000",
    ["noo my gold"] = "NOOMYGOLD",
    ["noo my gold cost"] = "1850000000",
    ["chimnino"] = "CHIMNINO",
    ["chimnino cost"] = "1900000000",
    ["los combinasionas"] = "LOSCOMBINAASIONAS",
    ["los combinasionas cost"] = "2000000000",
    ["chicleteira noelteira"] = "CHICLETEIRANOELTEIRA",
    ["chicleteira noelteira cost"] = "2000000000",
    ["bananito"] = "BANANITO",
    ["bananito cost"] = "2000000000",
    ["fishino clownino"] = "FISHINOCLOWNINO",
    ["fishino clownino cost"] = "2100000000",
    ["baskito"] = "BASKITO",
    ["baskito cost"] = "2100000000",
    ["tacorita bicicleta"] = "TACORITABICICLETA",
    ["tacorita bicicleta cost"] = "2200000000",
    ["los sweethearts"] = "LOSSWEETHEARTS",
    ["los sweethearts cost"] = "2200000000",
    ["spinny hammy"] = "SPINNYHAMMY",
    ["spinny hammy cost"] = "2300000000",
    ["camera ramena"] = "CAMERARAMENA",
    ["camera ramena cost"] = "2300000000",
    ["nuclearo dinosauro"] = "NUCLEARODINOSAURO",
    ["nuclearo dinosauro cost"] = "2500000000",
    ["las sis"] = "LASSIS",
    ["las sis cost"] = "2500000000",
    ["dj panda"] = "DJPANDA",
    ["dj panda cost"] = "2500000000",
    ["chicleteira cupideira cost"] = "2500000000",
    ["la karkerkar combinasion"] = "LAKARKERKARCOMBINASION",
    ["la karkerkar combinasion cost"] = "2500000000",
    ["chillin chili"] = "CHILLINCHILI",
    ["chillin chili cost"] = "2500000000",
    ["chipso and queso"] = "CHIPSOANDQUESO",
    ["chipso and queso cost"] = "2500000000",
    ["money money reindeer cost"] = "2500000000",
    ["money money puggy"] = "MONEYMONEYPUGGY",
    ["money money puggy cost"] = "2600000000",
    ["churrito bunnito"] = "CHURRITOBUNNITO",
    ["churrito bunnito cost"] = "2600000000",
    ["celularcini viciosini"] = "CELULARCINIVICIOSINI",
    ["celularcini viciosini cost"] = "2600000000",
    ["los planitos"] = "LOSPLANITOS",
    ["los planitos cost"] = "2700000000",
    ["snailo clovero"] = "SNAILOCLOVERO",
    ["snailo clovero cost"] = "2700000000",
    ["los mobilis cost"] = "2700000000",
    ["capitano gullini"] = "CAPITANOGULLINI",
    ["capitano gullini cost"] = "2700000000",
    ["los 67"] = "LOS67",
    ["los 67 cost"] = "2700000000",
    ["mieteteira bicicleteira"] = "MIETETEIRABICICLETEIRA",
    ["mieteteira bicicleteira cost"] = "2700000000",
    ["tuff toucan"] = "TUFFTOUCAN",
    ["tuff toucan cost"] = "2700000000",
    ["la spooky grande cost"] = "2900000000",
    ["los spooky combinasionas"] = "LOSSPOOKYCOMBINASIONAS",
    ["los spooky combinasionas cost"] = "3000000000",
    ["cigno fulgoro"] = "CIGNOFULGORO",
    ["cigno fulgoro cost"] = "3000000000",
    ["los candies"] = "LOSCANDIES",
    ["los candies cost"] = "3000000000",
    ["los hotspositos"] = "LOSHOTSPOSITOS",
    ["los hotspositos cost"] = "3000000000",
    ["los jolly combinasionas"] = "LOSJOLLYCOMBINASIONAS",
    ["los jolly combinasionas cost"] = "3000000000",
    ["los cupids"] = "LOSCUPIDS",
    ["los cupids cost"] = "3000000000",
    ["los puggies"] = "LOSPUGGIES",
    ["los puggies cost"] = "3000000000",
    ["w or l"] = "WORL",
    ["w or l cost"] = "3000000000",
    ["tralalalaledon"] = "TRALALALALEDON",
    ["tralalalaledon cost"] = "3000000000",
    ["la extinct grande combinasion"] = "LAEXTINCTGRANDECOMBINASION",
    ["la extinct grande combinasion cost"] = "3200000000",
    ["tralaledon"] = "TRALALEDON",
    ["tralaledon cost"] = "3500000000",
    ["la jolly grande cost"] = "3500000000",
    ["los primos"] = "LOSPRIMOS",
    ["los primos cost"] = "3700000000",
    ["bacuru and egguru"] = "BACURUANDEGGURU",
    ["bacuru and egguru cost"] = "3800000000",
    ["eviledon cost"] = "3800000000",
    ["los tacoritas"] = "LOSTACORITAS",
    ["los tacoritas cost"] = "4000000000",
    ["lovin rose cost"] = "4200000000",
    ["abyssaloco"] = "ABYSSALOCO",
    ["abyssaloco cost"] = "4300000000",
    ["tang tang kelentang cost"] = "4500000000",
    ["coco and mango"] = "COCOANDMANGO",
    ["coco and mango cost"] = "4500000000",
    ["ketupat kepat cost"] = "5000000000",
    ["los bros"] = "LOSBROS",
    ["los bros cost"] = "6000000000",
    ["tictac sahur"] = "TICTACSAHUR",
    ["tictac sahur cost"] = "6000000000",
    ["la romantic grande cost"] = "7000000000",
    ["gingerat gerat"] = "GINGERATGERAT",
    ["gingerat gerat cost"] = "7000000000",
    ["orcaledon cost"] = "7000000000",
    ["la lucky grande"] = "LALUCKYGRANDE",
    ["la lucky grande cost"] = "7000000000",
    ["ketchuru and masturu"] = "KETCHURUANDMASTURU",
    ["ketchuru and masturu cost"] = "7500000000",
    ["gym bros"] = "GYMBROS",
    ["gym bros cost"] = "7500000000",
    ["jolly jolly sahur"] = "JOLLYJOLLYSAHUR",
    ["jolly jolly sahur cost"] = "8000000000",
    ["gold gold gold"] = "GOLDGOLDGOLD",
    ["gold gold gold cost"] = "8000000000",
    ["money money bros"] = "MONEYMONEYBROS",
    ["money money bros cost"] = "9000000000",
    ["garama and madundung"] = "GARAMAANDMADUNDUNG",
    ["garama and madundung cost"] = "10000000000",
    ["la anniversary grande"] = "LAANNIVERSARYGRANDE",
    ["la anniversary grande cost"] = "10000000000",
    ["rosetti tualetti cost"] = "10000000000",
    ["nacho spyder"] = "NACHOSPYDER",
    ["nacho spyder cost"] = "10000000000",
    ["steakini fattini"] = "STEAKINIFATTINI",
    ["steakini fattini cost"] = "12500000000",
    ["sammyni cakini"] = "SAMMYNICAKINI",
    ["sammyni cakini cost"] = "12500000000",
    ["hopilikalika hopilikalako"] = "HOPILIKALIKAHOPILIKALAKO",
    ["hopilikalika hopilikalako cost"] = "15000000000",
    ["festive 67 cost"] = "16000000000",
    ["festive 67 income"] = "67000000",
    ["sammyni fattini cost"] = "20000000000",
    ["rubrikiko"] = "RUBRIKIKO",
    ["rubrikiko cost"] = "20000000000",
    ["love love bear"] = "LOVELOVEBEAR",
    ["love love bear cost"] = "23000000000",
    ["love love bear income"] = "140000000",
    ["la ginger sekolah"] = "LAGINGERSEKOLAH",
    ["la ginger sekolah cost"] = "23000000000",
    ["los chillis"] = "LOSCHILLIS",
    ["los chillis cost"] = "23000000000",
    ["los hackers"] = "LOSHACKERS",
    ["los hackers cost"] = "23000000000",
    ["spooky and pumpky cost"] = "25000000000",
    ["boppin bunny"] = "BOPPINBUNNY",
    ["boppin bunny cost"] = "25000000000",
    ["lavadorito spinito"] = "LAVADORITOSPINITO",
    ["lavadorito spinito cost"] = "30000000000",
    ["la food combinasion"] = "LAFOODCOMBINASION",
    ["la food combinasion cost"] = "30000000000",
    ["los spaghettis"] = "LOSSPAGHETTIS",
    ["los spaghettis cost"] = "40000000000",
    ["duggy bros"] = "DUGGYBROS",
    ["duggy bros cost"] = "30000000000",
    ["la casa boo cost"] = "40000000000",
    ["cash or card"] = "CASHORCARD",
    ["cash or card cost"] = "40000000000",
    ["fragrama and chocrama"] = "FAGRAMAANDCHOCRAMA",
    ["fragrama and chocrama cost"] = "40000000000",
    ["los sekolahs"] = "LOSSEKOLAHS",
    ["los sekolahs cost"] = "45000000000",
    ["foxini lanternini"] = "FOXINILANTERNINI",
    ["foxini lanternini cost"] = "47500000000",
    ["kalika bros"] = "KALIKABROS",
    ["kalika bros cost"] = "47500000000",
    ["la secret combinasion"] = "LASECRETCOMBINASION",
    ["la secret combinasion cost"] = "50000000000",
    ["la secret combinasion income"] = "125000000",
    ["los amigos"] = "LOSAMIGOS",
    ["los amigos cost"] = "55000000000",
    ["fortunu and cashuru"] = "FORTUNUANDCASHURU",
    ["fortunu and cashuru cost"] = "55000000000",
    ["reinito sleighito cost"] = "60000000000",
    ["reinito sleighito income"] = "140000000",
    ["ketupat bros"] = "KETUPATBROS",
    ["ketupat bros cost"] = "65000000000",
    ["burguro and fryuro"] = "BURGUROANDFRYURO",
    ["burguro and fryuro cost"] = "75000000000",
    ["cooki and milki cost"] = "100000000000",
    ["cooki and milki income"] = "155000000",
    ["capitano moby"] = "CAPITANOMOBY",
    ["capitano moby cost"] = "125000000000",
    ["rosey and teddy cost"] = "130000000000",
    ["rosey and teddy income"] = "165000000",
    ["popcuru and fizzuru"] = "POPCURUANDFIZZURU",
    ["popcuru and fizzuru cost"] = "135000000000",
    ["hydra bunny"] = "HYDRABUNNY",
    ["hydra bunny cost"] = "135000000000",
    ["celestial pegasus cost"] = "150000000000",
    ["celestial pegasus income"] = "150000000",
    ["cerberus"] = "CERBERUS",
    ["cerberus cost"] = "150000000000",
    ["jelly moby"] = "JELLYMOBY",
    ["jelly moby cost"] = "150000000000",
    ["la supreme combinasion cost"] = "200000000000",
    ["la supreme combinasion income"] = "200000000",
    ["digi narwhal"] = "DIGINARWHAL",
    ["digi narwhal cost"] = "200000000000",
    ["dragon cannelloni cost"] = "250000000000",
    ["dragon cannelloni income"] = "250000000",
    ["dragon gingerini"] = "DRAGONGINGERINI",
    ["dragon gingerini cost"] = "300000000000",
    ["hydra dragon cannelloni cost"] = "350000000000",
    ["hydra dragon cannelloni income"] = "350000000",
    ["dragon aquanini"] = "DRAGONAQUANINI",
    ["dragon aquanini cost"] = "375000000000",
    ["dragon aquanini income"] = "375000000",
    ["griffin"] = "GRIFFIN",
    ["griffin cost"] = "400000000000",
    ["griffin income"] = "400000000",

    -- ===== OG BRAINROTS =====
    ["skibidi toilet cost"] = "450000000000",
    ["skibidi toilet income"] = "450000000",
    ["john pork cost"] = "500000000000",
    ["john pork income"] = "500000000",
    ["headless horseman cost"] = "550000000000",
    ["headless horseman income"] = "550000000",
    ["meowl cost"] = "600000000000",
    ["meowl income"] = "600000000",
    ["strawberry elephant cost"] = "750000000000",
    ["strawberry elephant income"] = "750000000",
    ["spyder elephant"] = "SPYDERELEPHANT",
    ["spyder elephant cost"] = "1000000000000",
    ["spyder elephant income"] = "1000000000",
    ["how many og brainrots"] = "6",
    ["og brainrot count"] = "6",
    ["cheapest og brainrot"] = "SKIBIDITOILET",
    ["most expensive og brainrot"] = "SPYDERELEPHANT",
    ["most expensive brainrot in the game"] = "SPYDERELEPHANT",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== SKULL LUCKY BLOCK FULL DROP TABLE =====
    -- ═══════════════════════════════════════════════════════════════
    ["candi corni"] = "CANDICORNI",
    ["candi corni chance"] = "32.4PERCENT",
    ["candi corni income"] = "321000",
    ["grim cheese"] = "GRIMCHEESE",
    ["grim cheese chance"] = "30PERCENT",
    ["grim cheese income"] = "1600000",
    ["zombie bowl"] = "ZOMBIEBOWL",
    ["zombie bowl chance"] = "21PERCENT",
    ["zombie bowl income"] = "4500000",
    ["bananito skelito"] = "BANANITOSKELITO",
    ["bananito skelito chance"] = "10PERCENT",
    ["bananito skelito income"] = "8500000",
    ["bat in the box"] = "BATINTHEBOX",
    ["bat-in-the-box"] = "BATINTHEBOX",
    ["bat in the box chance"] = "5PERCENT",
    ["bat in the box income"] = "22500000",
    ["boo boo rocket"] = "BOOBOOROCKET",
    ["boo boo rocket chance"] = "1PERCENT",
    ["boo boo rocket income"] = "37500000",
    ["flying dutchman"] = "FLYINGDUTCHMAN",
    ["flying dutchman chance"] = "0.5PERCENT",
    ["flying dutchman income"] = "92500000",
    ["dragon skeletonini"] = "DRAGONSKELETONINI",
    ["dragon skeletonini chance"] = "0.1PERCENT",
    ["dragon skeletonini income"] = "325000000",
    ["rarest skull lucky block drop"] = "DRAGONSKELETONINI",
    ["best skull lucky block drop"] = "DRAGONSKELETONINI",
    ["skull lucky block cost"] = "500000000",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== HAUNTED FUSE FULL DROP TABLE (Update 69) =====
    -- ═══════════════════════════════════════════════════════════════
    ["penguino pumpkino"] = "PENGUINOPUMPKINO",
    ["penguino pumpkino rarity"] = "EPIC",
    ["penguino pumpkino income"] = "235",
    ["frostino vampiro"] = "FROSTINOVAMPIRO",
    ["frostino vampiro rarity"] = "MYTHIC",
    ["frostino vampiro income"] = "17500",
    ["vampi ribbitini"] = "VAMPIRIBBITINI",
    ["vampi ribbitini income"] = "185000",
    ["vampi ribbitini rarity"] = "BRAINROTGOD",
    ["mummelo bandello"] = "MUMMELOBANDELLO",
    ["mummelo bandello income"] = "285000",
    ["mummelo bandello rarity"] = "BRAINROTGOD",
    ["mortaruga"] = "MORTARUGA",
    ["mortaruga income"] = "324000",
    ["mortaruga rarity"] = "BRAINROTGOD",
    ["los treaters"] = "LOSTREATERS",
    ["los treaters income"] = "1200000",
    ["los treaters rarity"] = "SECRET",
    ["fangaro lupino"] = "FANGAROLUPINO",
    ["fangaro lupino income"] = "7200000",
    ["fangaro lupino rarity"] = "SECRET",
    ["oni oni panda"] = "ONIONIPANDA",
    ["oni oni panda income"] = "27000000",
    ["oni oni panda rarity"] = "SECRET",
    ["sammyni spookyni"] = "SAMMYNISPOOKYNI",
    ["sammyni spookyni income"] = "80000000",
    ["sammyni spookyni rarity"] = "SECRET",
    ["plant bros"] = "PLANTBROS",
    ["plant bros income"] = "300000000",
    ["plant bros rarity"] = "SECRET",
    ["plant bros cost"] = "300000000000",
    ["phoenix income"] = "425000000",
    ["phoenix rarity"] = "SECRET",
    ["how many haunted fuse brainrots"] = "11",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== ALL TRAITS WITH EXACT MULTIPLIERS =====
    -- ═══════════════════════════════════════════════════════════════
    ["strawberry trait"] = "8X",
    ["strawberry trait multiplier"] = "8X",
    ["meowl trait"] = "7X",
    ["meowl trait multiplier"] = "7X",
    ["john pork trait"] = "6.5X",
    ["john pork trait multiplier"] = "6.5X",
    ["skibidi trait"] = "6X",
    ["skibidi trait multiplier"] = "6X",
    ["rainbow balloon trait"] = "6.5X",
    ["pink egg trait"] = "6.5X",
    ["1 year trait"] = "5.5X",
    ["pink balloon trait"] = "5.5X",
    ["reindeer pet trait"] = "5X",
    ["26 trait"] = "5X",
    ["halo trait"] = "5X",
    ["lucky trait"] = "5X",
    ["red balloon trait"] = "5X",
    ["chocolate trait"] = "4.5X",
    ["jack o lantern trait"] = "4.5X",
    ["bunny ears trait"] = "4.5X",
    ["blue egg trait"] = "4.5X",
    ["blue balloon trait"] = "4X",
    ["santa hat trait"] = "4X",
    ["green egg trait"] = "4X",
    ["rip tombstone trait"] = "3.5X",
    ["green balloon trait"] = "3.5X",
    ["witching hour trait"] = "3X",
    ["skeleton trait"] = "3X",
    ["10b trait"] = "3X",
    ["orange balloon trait"] = "3X",
    ["orange egg trait"] = "3X",
    ["paint trait"] = "5X",
    ["paint trait multiplier"] = "5X",
    [":3 trait"] = "4.5X",
    [":3 trait multiplier"] = "4.5X",
    ["tie trait"] = "3.75X",
    ["spider trait"] = "3.5X",
    ["matteo hat trait"] = "3.5X",
    ["galactic trait"] = "3X",
    ["explosive trait"] = "3X",
    ["shark fin trait"] = "3X",
    ["brazil trait"] = "5X",
    ["indonesia trait"] = "4X",
    ["sombrero trait"] = "4X",
    ["granny trait"] = "5.5X",
    ["burger trait"] = "4.5X",
    ["fire trait"] = "5X",
    ["rose trait"] = "5X",
    ["fireworks trait"] = "5X",
    ["nyan trait"] = "5X",
    ["lightning trait"] = "5X",
    ["disco trait"] = "4X",
    ["sleepy trait"] = "0.5X",
    ["sleepy trait multiplier"] = "0.5X",
    ["worst trait"] = "SLEEPY",
    ["best trait"] = "STRAWBERRY",
    ["best trait multiplier"] = "8X",
    ["how many traits"] = "40PLUS",
    ["highest trait multiplier"] = "8X",
    ["lowest trait multiplier"] = "0.5X",
    ["negative trait"] = "SLEEPY",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== ALL 20 MACHINES =====
    -- ═══════════════════════════════════════════════════════════════
    ["fuse machine"] = "FUSEMACHINE",
    ["fuse machine added"] = "AUGUST12025",
    ["craft machine"] = "CRAFTMACHINE",
    ["craft machine added"] = "SEPTEMBER62025",
    ["witch fuse added"] = "OCTOBER112025",
    ["santas fuse added"] = "DECEMBER62025",
    ["divine fuse added"] = "MARCH72026",
    ["cyber craft machine added"] = "APRIL182026",
    ["summer fuse added"] = "MAY232026",
    ["brainrot dealer"] = "BRAINROTDEALER",
    ["brainrot dealer added"] = "NOVEMBER82025",
    ["brainrot trader"] = "BRAINROTTRADER",
    ["brainrot trader added"] = "NOVEMBER152025",
    ["santas shop"] = "SANTASSHOP",
    ["santas shop added"] = "CHRISTMAS2025",
    ["los traders"] = "LOSTRADERS",
    ["los traders added"] = "JULY112026",
    ["duels machine"] = "DUELSMACHINE",
    ["duels machine added"] = "JANUARY102026",
    ["trade machine"] = "TRADEMACHINE",
    ["trade machine added"] = "FEBRUARY212026",
    ["egg incubator"] = "EGGINCUBATOR",
    ["egg incubator added"] = "APRIL42026",
    ["rainbow machine"] = "RAINBOWMACHINE",
    ["rainbow machine added"] = "JUNE212025",
    ["bubblegum machine"] = "BUBBLEGUMMACHINE",
    ["bubblegum machine added"] = "JULY182025",
    ["advent calendar"] = "ADVENTCALENDAR",
    ["advent calendar added"] = "NOVEMBER292025",
    ["admin machine"] = "ADMINMACHINE",
    ["admin machine added"] = "NOVEMBER292025",
    ["new years machine"] = "NEWYEARSMACHINE",
    ["new years machine added"] = "DECEMBER312025",
    ["cupids machine added"] = "FEBRUARY72026",
    ["haunted fuse added"] = "OCTOBER32026",
    ["rng machine added"] = "AUGUST82026",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== RNG MACHINE DROPS =====
    -- ═══════════════════════════════════════════════════════════════
    ["rng machine pool size"] = "40",
    ["how many brainrots in rng machine"] = "40",
    ["rng machine brainrots"] = "40",
    ["gelatina volatina"] = "GELATINAVOLATINA",
    ["gelatina volatina income"] = "2400000",
    ["gelatina volatina cost"] = "590000000",
    ["rocketini frostini"] = "ROCKETINIFROSTINI",
    ["rocketini frostini income"] = "3000000",
    ["rocketini frostini cost"] = "700000000",
    ["best rng machine drop"] = "ROCKETINIFROSTINI",
    ["rarest rng machine drop"] = "ROCKETINIFROSTINI",
    ["tic tic ribbit"] = "TICTICRIBBIT",
    ["tic tic ribbit income"] = "18700",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== LUCKY BLOCK FULL DROP TABLES =====
    -- ═══════════════════════════════════════════════════════════════

    -- Mythic Lucky Block drops
    ["spioniro golubiro chance in mythic lb"] = "37PERCENT",
    ["zibra zubra zibralini chance in mythic lb"] = "30PERCENT",
    ["tigrilini watermelini chance in mythic lb"] = "20PERCENT",
    ["carrotini brainini chance in mythic lb"] = "10PERCENT",
    ["bananito bandito chance in mythic lb"] = "3PERCENT",
    ["best mythic lucky block drop"] = "BANANITOBANDITO",

    -- Brainrot God Lucky Block drops
    ["tigroligre frutonni chance in bg lb"] = "54PERCENT",
    ["orcalero orcala chance in bg lb"] = "30PERCENT",
    ["bulbito bandito traktorito chance in bg lb"] = "10PERCENT",
    ["mastodontico telepiedone chance in bg lb"] = "5PERCENT",
    ["pop pop sahur chance in bg lb"] = "1PERCENT",
    ["best brainrot god lucky block drop"] = "POPPOPSAHUR",

    -- Secret Lucky Block drops
    ["torrtuginni dragonfrutini chance in secret lb"] = "74.45PERCENT",
    ["pot hotspot chance in secret lb"] = "21PERCENT",
    ["esok sekolah chance in secret lb"] = "3PERCENT",
    ["spaghetti tualetti chance in secret lb"] = "1PERCENT",
    ["la secret combinasion chance in secret lb"] = "0.5PERCENT",
    ["celestial pegasus chance in secret lb"] = "0.05PERCENT",
    ["best secret lucky block drop"] = "CELESTIALPEGASUS",
    ["rarest secret lucky block drop"] = "CELESTIALPEGASUS",

    -- Spooky Lucky Block
    ["best spooky lucky block drop"] = "LACASABOO",
    ["la casa boo chance"] = "0.3PERCENT",
    ["la casa boo income"] = "100000000",

    -- Festive Lucky Block
    ["best festive lucky block drop"] = "REINITOSLEIGHITO",
    ["reinito sleighito chance"] = "0.1PERCENT",

    -- Heart Lucky Block
    ["best heart lucky block drop"] = "ROSEYANDTEDDY",
    ["rosey and teddy chance in heart lb"] = "0.05PERCENT",

    -- Leprechaun Lucky Block
    ["best leprechaun lucky block drop"] = "FORTUNUANDCASHURU",
    ["fortunu and cashuru chance"] = "0.1PERCENT",
    ["fortunu and cashuru income"] = "130000000",

    -- Egg Lucky Block
    ["best egg lucky block drop"] = "HYDRABUNNY",
    ["hydra bunny chance"] = "0.1PERCENT",

    -- Octo Lucky Block
    ["best octo lucky block drop"] = "KRAKEN",
    ["kraken"] = "KRAKEN",
    ["kraken chance"] = "0.1PERCENT",
    ["kraken income"] = "200000000",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== UPDATE LOG (all major updates) =====
    -- ═══════════════════════════════════════════════════════════════
    ["update 32"] = "CURSEDMUTATION",
    ["update 32 date"] = "JANUARY32026",
    ["update 33"] = "DUELSMACHINE",
    ["update 33 date"] = "JANUARY102026",
    ["update 34"] = "BRUNOMARSCONCERT",
    ["update 34 date"] = "JANUARY172026",
    ["update 35"] = "OGFUSEMACHINERETURNS",
    ["update 35 date"] = "JANUARY242026",
    ["update 36"] = "MIGATITORITUAL",
    ["update 36 date"] = "JANUARY312026",
    ["update 37"] = "VALENTINESDAY",
    ["update 37 date"] = "FEBRUARY72026",
    ["update 38"] = "VALENTINESDAYPART2",
    ["update 38 date"] = "FEBRUARY142026",
    ["update 39"] = "DIVINEMUTATION",
    ["update 39 date"] = "FEBRUARY212026",
    ["update 40"] = "DIVINEADMINMACHINE",
    ["update 40 date"] = "FEBRUARY282026",
    ["update 41"] = "DIVINEFUSEMACHINE",
    ["update 41 date"] = "MARCH72026",
    ["update 42"] = "STPATRICKSDAY",
    ["update 42 date"] = "MARCH142026",
    ["update 43"] = "GRANNYSFUNERAL",
    ["update 43 date"] = "MARCH212026",
    ["update 44"] = "EASTERHOUR",
    ["update 44 date"] = "MARCH282026",
    ["update 45"] = "EGGLUCKYBLOCK",
    ["update 45 date"] = "APRIL42026",
    ["update 46"] = "FOODTHEMED",
    ["update 46 date"] = "APRIL112026",
    ["update 47"] = "CYBERMUTATION",
    ["update 47 date"] = "APRIL182026",
    ["update 48"] = "CYBERADMINMACHINE",
    ["update 48 date"] = "APRIL252026",
    ["update 49"] = "5THOGBRAINROT",
    ["update 49 date"] = "MAY22026",
    ["update 50"] = "BACKROOMSEVENT",
    ["update 50 date"] = "MAY92026",
    ["update 51"] = "1YEARANNIVERSARY",
    ["update 51 date"] = "MAY162026",
    ["update 52"] = "SUMMERFUSE",
    ["update 52 date"] = "MAY232026",
    ["update 53"] = "PHANTOMMUTATION",
    ["update 53 date"] = "JUNE132026",
    ["update 55"] = "FUTBOLCOUNTRYTRAITS",
    ["update 55 date"] = "JUNE272026",
    ["update 56"] = "JULY4TH",
    ["update 56 date"] = "JULY42026",
    ["update 57"] = "EXCHANGEMACHINE",
    ["update 57 date"] = "JULY112026",
    ["update 59"] = "CRYSTALMUTATION",
    ["update 59 date"] = "JULY252026",
    ["update 61"] = "RNGMACHINE",
    ["update 61 date"] = "AUGUST82026",
    ["update 62"] = "REBIRTH19",
    ["update 62 date"] = "AUGUST152026",
    ["update 69"] = "HAUNTEDFUSEECLIPSE",
    ["update 69 date"] = "OCTOBER32026",
    ["update 70"] = "SKULLLUCKYBLOCK",
    ["update 70 date"] = "OCTOBER102026",
    ["update 71"] = "SKELETONEVENT",
    ["update 71 date"] = "OCTOBER172026",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== SAMMY FACTS (EXPANDED) =====
    -- ═══════════════════════════════════════════════════════════════
    ["sammy real name"] = "SAMBRAKTA",
    ["sam brakta"] = "SPYDERSAMMY",
    ["what is sammys real name"] = "SAMBRAKTA",
    ["sammy started making games"] = "2013",
    ["when did sammy start making roblox games"] = "2013",
    ["sammy roblox account created"] = "2021",
    ["who did sammy buy steal a from"] = "KILLIOZ",
    ["killioz"] = "KILLIOZ",
    ["who created steal a character"] = "KILLIOZ",
    ["sammy bought concept from"] = "KILLIOZ",
    ["sab peak players"] = "25400000",
    ["peak ccu"] = "25400000",
    ["highest player count"] = "25400000",
    ["25 million ccu"] = "STEALABRAINROT",
    ["first game to reach 25 million ccu"] = "STEALABRAINROT",
    ["roblox record ccu"] = "25400000",
    ["sab total visits"] = "7BILLION",
    ["bruno mars concert ccu"] = "12800000",
    ["bruno mars concert date"] = "JANUARY172026",
    ["bruno mars songs in sab"] = "IJUSTMIGHT",
    ["extinct event ccu"] = "24000000",
    ["extinct event date"] = "SEPTEMBER132025",
    ["admin war ccu"] = "20000000PLUS",
    ["admin war date"] = "AUGUST232025",
    ["roblox innovation award"] = "BESTCREATIVEDIRECTION",
    ["sab award"] = "BESTCREATIVEDIRECTION",
    ["what award did sab win"] = "BESTCREATIVEDIRECTION",
    ["2025 roblox innovation award"] = "BESTCREATIVEDIRECTION",
    ["brazilian spyder members"] = "28000000PLUS",
    ["sammy community size"] = "28000000PLUS",
    ["sab copyright registration"] = "PA002544969",
    ["sab film adaptation"] = "STORYKITCHEN",
    ["who is making sab movie"] = "STORYKITCHEN",
    ["sab platforms"] = "WINDOWS",
    ["what platforms is sab on"] = "ROBLOXALLPLATFORMS",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== FORTNITE CROSSOVER =====
    -- ═══════════════════════════════════════════════════════════════
    ["fortnite steal the brainrot"] = "STEALTHEBRAINROT",
    ["steal the brainrot fortnite"] = "FORTNITE",
    ["fortnite version release"] = "JULY2025",
    ["fortnite version peak ccu"] = "500000",
    ["steal the brainrot peak players"] = "500000",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== GAME MECHANICS =====
    -- ═══════════════════════════════════════════════════════════════
    ["base slots"] = "28",
    ["how many base slots"] = "28",
    ["total base slots"] = "28",
    ["grief shield"] = "GRIEFSHIELD",
    ["what does grief shield do"] = "PROTECTSFROMGRIEFERS",
    ["when was grief shield added"] = "UPDATE62",
    ["conveyor belt"] = "BUYBRAINROTS",
    ["how to buy brainrots"] = "CONVEYORBELT",
    ["how to steal brainrots"] = "WALKTOOTHERSBASE",
    ["shield button"] = "PROTECTSBASE",
    ["how does rebirth work"] = "RESETSPROGRESSFORBETTERSTATS",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== FUSE RECIPES =====
    -- ═══════════════════════════════════════════════════════════════
    ["orchidox plus venuspino result"] = "PLANTBROS",
    ["noobini x4 result"] = "PIPIAVOCADO",
    ["4 noobini result"] = "PIPIAVOCADO",
    ["4 strawberry elephant result"] = "HYDRADRAGONCANNELLONI",
    ["strawberry elephant x4 result"] = "HYDRADRAGONCANNELLONI",
    ["bandito axolito recipe"] = "2TRIPPITROPPI2BANDITOBOBRITTO",
    ["los noobinis recipe"] = "3NOOBINIPIZZANINI1CARROTINIBRAININI",
    ["plant bros recipe result"] = "PLANTBROS",
    ["ketupat kepat plus ginger gerat result"] = "KETUPATBROS",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== CONTROVERSIES / EVENTS =====
    -- ═══════════════════════════════════════════════════════════════
    ["tung tung tung sahur removed"] = "LICENSINGDISPUTE",
    ["why was tung tung tung sahur removed"] = "NOXAMEMEMTUMLAB",
    ["noxa"] = "TUNGTUNGTUNGSAHURCREATOR",
    ["mememtum lab"] = "TUNGTUNGTUNGSAHURLICENSOR",
    ["tung tung tung sahur restored"] = "NOVEMBER292025",
    ["is spyder sammy dead"] = "NO",
    ["spyder sammy death hoax"] = "DEBUNKED",
    ["sammy car accident"] = "HOAX",

    -- ═══════════════════════════════════════════════════════════════
    -- ===== ACTIVE CODES (October 2026) =====
    -- ═══════════════════════════════════════════════════════════════
    ["active codes"] = "BESTBRAINROTEVER",
    ["working codes"] = "BESTBRAINROTEVER",
    ["current codes"] = "BESTBRAINROTEVER",
    ["saturn code"] = "LAVACCASATURNOSATURNITA",
    ["what does bestbrainrotever give"] = "LAVACCASATURNOSATURNITA",
    ["what does saturn code give"] = "LAVACCASATURNOSATURNITA",
    ["bestbrainrotever reward"] = "LAVACCASATURNOSATURNITA",
    ["how many active codes"] = "2",
    ["code rewards"] = "LAVACCASATURNOSATURNITA",
    -- ===== RESEARCH EXPANSION (October 2026) =====
    ["1 year anniversary brainrot"] = "OGSPYDERELEPHANT",
    ["1 year anniversary trait"] = "1YEARTRAIT",
    ["1 year trait multiplier"] = "6.76X",
    ["10 billion visits"] = "10BTRAITANDBADGE",
    ["10b trait multiplier"] = "4X",
    ["16th mutation"] = "PRISMATIC",
    ["17th mutation"] = "DISCO",
    ["18th mutation"] = "NEON",
    ["26 trait multiplier"] = "6X",
    ["3 face trait"] = "5.5X",
    ["3 trait ritual"] = "MIGATTORITUAL",
    ["5th og brainrot"] = "JOHNPORK",
    ["67 admin lucky block chance"] = "1.5PERCENT",
    ["admin abuse features"] = "LUCKYBLOCKWAVESMUTATIONSTRICKSCASHMULTIPLIERS",
    ["admin abuse private server"] = "YES",
    ["admin abuse time saturday"] = "3PMET",
    ["admin abuse time tuesday"] = "6PMET",
    ["admin lucky block best drop"] = "SAMMYINIFATTINI",
    ["admin lucky block price"] = "100000000",
    ["admin lucky block rarest drop"] = "SAMMYINIFATTINI",
    ["admin machine date"] = "NOVEMBER292025",
    ["admin war total roblox ccu"] = "47400000",
    ["advent calendar date"] = "NOVEMBER292025",
    ["advent calendar requirement"] = "ATLEASTONEREBIRTH",
    ["agarrini la palini cost"] = "80000000",
    ["agarrini la palini income"] = "425000PERSECOND",
    ["alessio admin lucky block chance"] = "25PERCENT",
    ["alessio income"] = "65000",
    ["alessio rarity"] = "BRAINROTGOD",
    ["anniversary trait multiplier"] = "6.76X",
    ["antonio rarity"] = "BRAINROTGOD",
    ["are sammy and jandel friends"] = "YES",
    ["are there fake sammys"] = "YES",
    ["are traits permanent"] = "YES",
    ["astrolero cervalero income"] = "280000PERSEC",
    ["astrolero cervalero rarity"] = "BRAINROTGOD",
    ["august 2025 ccu"] = "20MILLION",
    ["aura shades trait multiplier"] = "5.5X",
    ["aura trait"] = "5.5X",
    ["aura trait multiplier"] = "5.5X",
    ["avocadini antilopini income"] = "115",
    ["avocadini antilopini rarity"] = "EPIC",
    ["avocadini guffo income"] = "225",
    ["avocadini guffo rarity"] = "EPIC",
    ["avocadorilla income"] = "7500",
    ["avocadorilla rarity"] = "MYTHIC",
    ["avocadorilla recipe"] = "CHEFCABRACADABRA+FRIGOCAMELO",
    ["bacuru egguru fuse recipe"] = "BACURU+EGGURU",
    ["ballerina cappuccina rarity"] = "LEGENDARY",
    ["bambini crostini income"] = "135",
    ["bambini crostini rarity"] = "EPIC",
    ["bananita dolphinita income"] = "150",
    ["bananita dolphinita rarity"] = "EPIC",
    ["bananito bandito income"] = "16500",
    ["bananito bandito mythic lucky block chance"] = "3PERCENT",
    ["bananito bandito rarity"] = "MYTHIC",
    ["bananito skelito skull lucky block chance"] = "10PERCENT",
    ["bandito axolito income"] = "90",
    ["bandito axolito rarity"] = "EPIC",
    ["bandito bobritto income"] = "35",
    ["bandito bobritto rarity"] = "RARE",
    ["base lock"] = "10SECONDSPERREBIRTHLEVELPLUSGEAR",
    ["bat in the box skull lucky block chance"] = "5PERCENT",
    ["bee loco income"] = "13500",
    ["bee loco rarity"] = "MYTHIC",
    ["bee trait multiplier"] = "4X",
    ["berenjello angello income"] = "18000",
    ["berenjello angello rarity"] = "MYTHIC",
    ["best brainrot in the game"] = "SPYDERELEPHANT",
    ["best cyber craft brainrot"] = "DIGINARWHAL",
    ["best haunted fuse"] = "PHOENIX",
    ["best los traders brainrot"] = "MOBYBROS",
    ["bisonte giuppitere income"] = "300000PERSECOND",
    ["blackhole goat admin lucky block chance"] = "5PERCENT",
    ["blackhole goat income"] = "400000PERSECOND",
    ["bloodrot mutation multiplier"] = "2X",
    ["blue balloon trait multiplier"] = "5X",
    ["blue egg trait multiplier"] = "5.5X",
    ["blueberrinni octopusini income"] = "1000",
    ["blueberrinni octopusini rarity"] = "LEGENDARY",
    ["bluesammy67"] = "EXPIRED",
    ["bluesammy67 code"] = "EXPIRED",
    ["boatito auratito income"] = "525000PERSECOND",
    ["bombardini tortinii income"] = "225000PERSECOND",
    ["bombardiro crocodilo income"] = "2500",
    ["bombardiro crocodilo meaning"] = "ITALIANBRAINROTMEME",
    ["bombardiro ritual formation"] = "LINEATREDCARPETSTART",
    ["bombardiro ritual how to"] = "3PLAYERSINLINEWITHBOMBARDIROCROCODILO",
    ["bombardiro ritual players"] = "3",
    ["bombardiro ritual result"] = "LOSCROCODILLITOS",
    ["bombardiro vaccariro rarity"] = "SECRET",
    ["bombombini gusini income"] = "5000",
    ["boneca ambalabu income"] = "40",
    ["boneca ambalabu rarity"] = "RARE",
    ["boo boo rocket skull lucky block chance"] = "1PERCENT",
    ["brainrot dealer date"] = "NOVEMBER82025",
    ["brainrot dealer status"] = "REMOVED",
    ["brainrot god lucky block best drop"] = "POPPOPSAHUR",
    ["brainrot god lucky block rarest drop"] = "POPPOPSAHUR",
    ["brainrot god lucky block robux"] = "399ROBUX",
    ["brainrot trader date"] = "NOVEMBER152025",
    ["brainrot trader status"] = "REMOVED",
    ["brr es teh patipum recipe"] = "TRALALEROTALALA+COCOFANTOELEFANTO",
    ["brri brri bicus dicus bombicus income"] = "175",
    ["brri brri bicus dicus bombicus rarity"] = "EPIC",
    ["bruno mars brainrot"] = "BRUNITOMARSITO",
    ["bruno mars songs played"] = "IJUSTMIGHTANDLOCKEDOUTOFHEAVEN",
    ["brunoisbetter"] = "EXPIRED",
    ["brunoisbetter code"] = "EXPIRED",
    ["brutto gialutto income"] = "3000",
    ["brutto gialutto rarity"] = "MYTHIC",
    ["bubblegum machine cost"] = "10CANDYBRAINROTS",
    ["bubblegum machine date"] = "JULY182025",
    ["bubblegum trait"] = "4X",
    ["bubblegum trait multiplier"] = "4X",
    ["bucketoro income"] = "18200",
    ["bucketoro rarity"] = "MYTHIC",
    ["buho de fuego income"] = "1800",
    ["buho de fuego rarity"] = "LEGENDARY",
    ["buho de volto rarity"] = "SECRET",
    ["buho del cielo income"] = "1300",
    ["buho del cielo rarity"] = "LEGENDARY",
    ["bulbito bandito traktorito god lucky block chance"] = "10PERCENT",
    ["bulbito bandito traktorito income"] = "205000",
    ["bull trait"] = "6X",
    ["bull trait multiplier"] = "6X",
    ["bunny ear trait"] = "5.5X",
    ["bunny ear trait multiplier"] = "5.5X",
    ["bunny ears trait multiplier"] = "5.5X",
    ["buntteo income"] = "850000PERSECOND",
    ["burbaloni loliloli rarity"] = "LEGENDARY",
    ["burger trait date"] = "MAY302026",
    ["burger trait multiplier"] = "5.5X",
    ["burrito bandito taco lucky block chance"] = "3PERCENT",
    ["cachorrito melonito income"] = "13000",
    ["cachorrito melonito rarity"] = "MYTHIC",
    ["cacto hipopotamo income"] = "50",
    ["cacto hipopotamo rarity"] = "RARE",
    ["camera ramena rarity"] = "SECRET",
    ["can a brainrot have two mutations"] = "NOONLYONEMUTATIONATATIME",
    ["can brainrots have multiple mutations"] = "NO",
    ["can traits be removed"] = "NO",
    ["can traits stack"] = "YES",
    ["can you stack traits"] = "YES",
    ["can you trade mutations"] = "YES",
    ["can you trade traits"] = "YES",
    ["candi corni skull lucky block chance"] = "32.4PERCENT",
    ["candy mutation multiplier"] = "4X",
    ["candy24sammy"] = "STRAWBERRYELEPHANT",
    ["capitano gullini rarity"] = "SECRET",
    ["capitano moby income"] = "160000000PERSEC",
    ["capitano moby rarity"] = "SECRET",
    ["cappuccino assassino income"] = "75",
    ["cappuccino clownino spooky lucky block chance"] = "32.5PERCENT",
    ["caramello filtrello income"] = "1000",
    ["caramello filtrello rarity"] = "LEGENDARY",
    ["carloooo admin lucky block chance"] = "34.55PERCENT",
    ["carloooo cost"] = "4500000",
    ["carloooo income"] = "13500",
    ["carloooo rarity"] = "MYTHIC",
    ["carrotini brainini income"] = "15000",
    ["carrotini brainini mythic lucky block chance"] = "10PERCENT",
    ["carrotini brainini rarity"] = "MYTHIC",
    ["cash or card income"] = "100000000PERSEC",
    ["cash or card rarity"] = "SECRET",
    ["cavallo virtuoso income"] = "7500",
    ["cavallo virtuoso rarity"] = "MYTHIC",
    ["caylus admin abuse brainrot"] = "CAYLUSAURUS",
    ["caylus admin abuse trait"] = "AURA",
    ["celestial pegasus drop chance"] = "0.05PERCENT",
    ["celestial pegasus lucky block"] = "SECRETLUCKYBLOCK",
    ["celestial pegasus lucky block chance"] = "0.05PERCENT",
    ["centrucci nuclucci income"] = "15500",
    ["centrucci nuclucci rarity"] = "MYTHIC",
    ["chachechi income"] = "400000PERSECOND",
    ["cheapest brainrot"] = "NOOBINIPIZZANINI",
    ["cheapest og"] = "SKIBIDITOILET",
    ["chef crabracadabra income"] = "600",
    ["chef crabracadabra rarity"] = "LEGENDARY",
    ["chicleteira cupideira income"] = "17500000PERSEC",
    ["chicleteira noelteira rarity"] = "SECRET",
    ["chicleteira ritual players"] = "2",
    ["chicleteira ritual result"] = "LOSCHICLETEIRAS",
    ["chihuanini taconini taco lucky block chance"] = "48.7PERCENT",
    ["chocco bunny income"] = "1400",
    ["chocco bunny rarity"] = "LEGENDARY",
    ["chocolate trait multiplier"] = "5.5X",
    ["chrismasmamat festive lucky block chance"] = "30.9PERCENT",
    ["christmas brainrots"] = "NOOBINISANTANINIFRODOELFOPENPUINTREECHOCCOBUNNYSEALOREGALOJINGLEJINGLESAHURTREETREETRRESAHURYETICLAUSBALLERINAPEPPERMINTINAGINGERGLOBOGINGERCISTERNALAGINGERSEKOLAHCOOKIANDMILKILAJOLLYGRANDECHICLETEIRANOELTEIRALAVACCAPRESEPRESENTE",
    ["cigno fulgoro income"] = "20000000PERSEC",
    ["cigno fulgoro rarity"] = "SECRET",
    ["clickerino crabo income"] = "1000",
    ["clickerino crabo rarity"] = "LEGENDARY",
    ["coco and mango rarity"] = "SECRET",
    ["cocosini mama income"] = "1200",
    ["cocosini mama rarity"] = "LEGENDARY",
    ["cocosini mama recipe"] = "BURBALONILOLILOLIX4",
    ["cocoteddy income"] = "15000",
    ["cocoteddy rarity"] = "MYTHIC",
    ["codesarereal321"] = "JOHNPORK",
    ["colon 3 trait"] = "5.5X",
    ["comet struck trait"] = "3.5X",
    ["comet struck trait multiplier"] = "3.5X",
    ["cooki and milki rarity"] = "SECRET",
    ["country traits total"] = "46",
    ["country traits update"] = "UPDATE55",
    ["crab claw trait"] = "5X",
    ["crab claw trait multiplier"] = "5X",
    ["crabbo limonetta admin lucky block chance"] = "10PERCENT",
    ["craft machine cost"] = "TWOTOFOURBRABINROTSFROMRECIPE",
    ["craft machine date"] = "SEPTEMBER62025",
    ["craft machine input"] = "2TO4BRAINROTS",
    ["crystal mutation multiplier"] = "13X",
    ["cupcake koala income"] = "60",
    ["cupcake koala rarity"] = "EPIC",
    ["cupids machine date"] = "FEBRUARY72026",
    ["cursed mutation multiplier"] = "9X",
    ["cyber craft date"] = "APRIL182026",
    ["cyber craft how many brainrots"] = "11",
    ["cyber craft machine date"] = "APRIL182026",
    ["cyber craft update"] = "47",
    ["cyber mutation multiplier"] = "11X",
    ["default mutation"] = "DEFAULT",
    ["default mutation multiplier"] = "1X",
    ["developer full name"] = "SAMBRAKTA",
    ["diamond mutation chance"] = "5PERCENT",
    ["diamond mutation multiplier"] = "1.5X",
    ["diamond mutation spawn chance"] = "5PERCENT",
    ["diamond spawn rate"] = "5PERCENT",
    ["did grow a garden win"] = "YES",
    ["did sab beat fortnite"] = "YES",
    ["did sammy die"] = "NO",
    ["digi narwhal income"] = "200000000PERSEC",
    ["digi narwhal rarity"] = "SECRET",
    ["disco multiplier"] = "11X",
    ["disco mutation multiplier"] = "11X",
    ["disco trait multiplier"] = "5X",
    ["divine fuse date"] = "MARCH72026",
    ["divine fuse how many brainrots"] = "15",
    ["divine mutation multiplier"] = "10X",
    ["divino platypio income"] = "160000PERSEC",
    ["divino platypio rarity"] = "BRAINROTGOD",
    ["do mutations and traits stack"] = "YES",
    ["do traits multiply mutations"] = "NOTRAITSADDTOTHEMUTATIONMULTIPLIER",
    ["do traits stack"] = "YES",
    ["does admin abuse work in private servers"] = "YES",
    ["does sab have many codes"] = "NO",
    ["does sammy do business in dms"] = "NO",
    ["does sammy have youtube"] = "NO",
    ["doi doi do income"] = "260",
    ["doi doi do rarity"] = "EPIC",
    ["dragon aquanini rarity"] = "SECRET",
    ["dragon cannelloni rarity"] = "SECRET",
    ["dragon skeletonini skull lucky block chance"] = "0.1PERCENT",
    ["duels machine date"] = "JANUARY102026",
    ["duggy bros rarity"] = "SECRET",
    ["dul dul dul ritual players"] = "4",
    ["dul dul dul ritual result"] = "YESSMYEXAMEN",
    ["dumborino miracello income"] = "315000PERSEC",
    ["dumborino miracello rarity"] = "BRAINROTGOD",
    ["easter brainrots"] = "BUNNYTRALALAEGDDINEGGDUNLOSBUNITOSBASKITOCHURRITOBUNNITOHOPILIKALIKAHOPILIKALAKOHYBRABUNNY",
    ["eclipse event frequency weekday"] = "EVERY2HOURS",
    ["eclipse event frequency weekend"] = "EVERYHOUR",
    ["eclipse event rewards"] = "CASHREWARDSLUCKBOOSTSECLIPSELUCKYBLOCKECLIPSEHAMMER",
    ["eclipse event schedule"] = "HOURLYONWEEKENDSEVERY2HOURSONWEEKDAYS",
    ["eclipse hammer"] = "ECLIPSEHAMMER",
    ["eclipse mutation multiplier"] = "14X",
    ["eclipse secret lucky block"] = "ECLIPSELUCKYBLOCK",
    ["egg city event"] = "EGGCITY",
    ["egg incubator date"] = "APRIL42026",
    ["egg lucky block rarest drop"] = "HYDRABUNNY",
    ["eid traits"] = "RAINBOWBALLOONPINKBALLOONREDBALLOONBLUEBALLOONGREENBALLOONORANGEBALLOON",
    ["electro quacko income"] = "1800",
    ["electro quacko rarity"] = "LEGENDARY",
    ["elefanto frigo income"] = "14000",
    ["elefanto frigo rarity"] = "MYTHIC",
    ["esok sekolah secret lucky block chance"] = "3PERCENT",
    ["espresso signora income"] = "70000",
    ["espresso signora rarity"] = "BRAINROTGOD",
    ["expired codes"] = "BRUNOISBETTER",
    ["explosive trait multiplier"] = "4X",
    ["explosive trait ritual"] = "BOMBARDIROCROCODILORITUAL",
    ["extinct ballerina income"] = "125000",
    ["extinct ballerina rarity"] = "BRAINROTGOD",
    ["extinct matteo income"] = "625000PERSECOND",
    ["fat sammy"] = "BRAINROTGOD",
    ["fat sammy how to get"] = "ADMINABUSEONLY",
    ["fat sammy rarity"] = "BRAINROTGOD",
    ["festive lucky block best chance"] = "0.1PERCENT",
    ["festive lucky block best drop"] = "REINITOSLEIGHITO",
    ["festive lucky block rarest drop"] = "REINITOSLEIGHITO",
    ["first brainrot you can buy"] = "NOOBINIPIZZANINI",
    ["first game to hit 25 million"] = "STEALABRAINROT",
    ["fishboard income"] = "825000PERSECOND",
    ["fizzy soda rarity"] = "BRAINROTGOD",
    ["flippo marino rarity"] = "BRAINROTGOD",
    ["fluriflura income"] = "7",
    ["fluriflura rarity"] = "COMMON",
    ["flying dutchman skull lucky block chance"] = "0.5PERCENT",
    ["fortnite peak ccu"] = "15300000",
    ["fortunu and cashuru leprechaun lucky block chance"] = "0.1PERCENT",
    ["frankentteo income"] = "700000PERSECOND",
    ["free500drags"] = "DRAGONCANNELLONI",
    ["freeocto555"] = "OCTOLUCKYBLOCK",
    ["freeoctobase333w"] = "OCTOBASE",
    ["freeoctoblock777"] = "OCTOLUCKYBLOCK",
    ["freepremiumocto777"] = "PREMIUMOCTOLUCKYBLOCK",
    ["frigo camelo income"] = "1200",
    ["frogato pirato income"] = "240",
    ["frogato pirato rarity"] = "EPIC",
    ["frogo elfo income"] = "67",
    ["frogo elfo rarity"] = "RARE",
    ["fuse machine cost"] = "FOURBRAINROTSPLUSCASH",
    ["fuse machine date"] = "AUGUST12025",
    ["fuse machine input"] = "4BRAINROTS",
    ["fuse machine status"] = "REMOVED",
    ["futbolini skatini rarity"] = "SECRET",
    ["galactic trait multiplier"] = "4X",
    ["galactic trait ritual"] = "LAVACCASATURNOSATURNITSARITUAL",
    ["galaxy mutation multiplier"] = "7X",
    ["ganganzelli trulala income"] = "9000",
    ["ganganzelli trulala rarity"] = "MYTHIC",
    ["ganganzelli trulala recipe"] = "BOMBARDIROCROCODILO+BLUEBERRINNIOCTOPUSINI",
    ["gangster footera income"] = "30",
    ["gangster footera rarity"] = "RARE",
    ["garama and madudung"] = "GARAMAANDMADUDUNG",
    ["garama and madudung rarity"] = "SECRET",
    ["gato celesto income"] = "250",
    ["gato celesto rarity"] = "EPIC",
    ["gattatino neonino income"] = "20000",
    ["gattatino neonino rarity"] = "BRAINROTGOD",
    ["gattatino nyanino rarity"] = "BRAINROTGOD",
    ["gattito tacoto taco lucky block chance"] = "32PERCENT",
    ["ginger cisterna"] = "GINGERCISTERNA",
    ["ginger cisterna rarity"] = "BRAINROTGOD",
    ["ginger globo rarity"] = "BRAINROTGOD",
    ["girafa celestre income"] = "20000",
    ["glitched trait"] = "5X",
    ["glitched trait multiplier"] = "5X",
    ["glorbo fruttodrillo income"] = "750",
    ["glorbo fruttodrillo rarity"] = "LEGENDARY",
    ["goat income"] = "950000PERSECOND",
    ["gold mutation chance"] = "10PERCENT",
    ["gold mutation multiplier"] = "1.25X",
    ["gold mutation spawn chance"] = "10PERCENT",
    ["gold spawn rate"] = "10PERCENT",
    ["gorillo subwoofero income"] = "7700",
    ["gorillo subwoofero rarity"] = "MYTHIC",
    ["gorillo watermelondrillo income"] = "8000",
    ["gorillo watermelondrillo rarity"] = "MYTHIC",
    ["granny trait date"] = "MARCH21222026",
    ["granny trait multiplier"] = "6.5X",
    ["green balloon trait multiplier"] = "4.5X",
    ["green egg trait multiplier"] = "5X",
    ["griffin how to get"] = "DIVINEFUSEONLY",
    ["griffin rarity"] = "SECRET",
    ["grim cheese skull lucky block chance"] = "30PERCENT",
    ["grow a garden admin war ccu"] = "22300000",
    ["guerriro digitale admin lucky block chance"] = "3PERCENT",
    ["guerriro digitale income"] = "550000PERSECOND",
    ["guerriro digitale ritual players"] = "4",
    ["guerriro digitale ritual result"] = "1X1X1X1ORGUEST666ORJOHNDOE",
    ["guerriro digitale ritual time"] = "3AMEST",
    ["gym bros rarity"] = "SECRET",
    ["halloween 2026 update"] = "UPDATE69",
    ["halloween event duration"] = "5WEEKS",
    ["halloween event end"] = "EARLYNOVEMBER2026",
    ["halloween event start"] = "OCTOBER32026",
    ["halo trait multiplier"] = "6X",
    ["harpuccino rarity"] = "MYTHIC",
    ["haunted fuse animation"] = "EATSBRAINROTSWICKEDLAUGHTER",
    ["haunted fuse brainrots"] = "10HALLOWEENTHEMED",
    ["haunted fuse date"] = "OCTOBER32026",
    ["haunted fuse how many brainrots"] = "11",
    ["haunted fuse input"] = "4BRAINROTS",
    ["headless horseman exist count"] = "54",
    ["headless horseman how to get"] = "WITCHFUSEONLY",
    ["headless horseman origin"] = "WITCHFUSE",
    ["headless horseman rarity"] = "OG",
    ["heart lucky block best chance"] = "0.05PERCENT",
    ["heart lucky block best drop"] = "ROSEYANDTEDDY",
    ["heart lucky block rarest drop"] = "ROSEYANDTEDDY",
    ["heart lucky block robux"] = "799ROBUX",
    ["highest ccu"] = "25400000",
    ["highest concurrent players"] = "25MILLION",
    ["highest income brainrot"] = "SPYDERELEPHANT",
    ["highest income in the game"] = "ECLIPSEPHOENIX5.7BPERSECOND",
    ["highest income secret"] = "GOAT",
    ["highest mutation multiplier"] = "ECLIPSE",
    ["holy arepa income"] = "14",
    ["holy arepa rarity"] = "COMMON",
    ["how does craft machine work"] = "USESPECIFICRECIPETOCRAFTGUARANTEEDBRAINROT",
    ["how does duels work"] = "2PLAYERSWAGERBOTHPUTUPBRAINROTWINNERTAKESBOTH",
    ["how does egg incubator work"] = "PLACEEGGININCUBATORBEFOREHATCHTOGETSRANDOMTRAITBOOST",
    ["how does fuse machine work"] = "COMBINEFOURBRABINROTSPLUSCASHTOGETONEBRAINROT",
    ["how does income work"] = "BRAINROTSGENERATECASHPERSECONDPASSIVELY",
    ["how does mutation income work"] = "BASEINCOMEXMUTATIONMULTIPLIERPLUSALLTRAITMULTIPLIERS",
    ["how does mutation work"] = "RANDOMCHANCEDURINGEVENTSMULTIPLIESINCOME",
    ["how does stealing work"] = "WALKINTOOTHERPLAYERSBASEANDTAKEBRAINROTS",
    ["how does the conveyor work"] = "BRAINROTSSPAWNONCONVEYORYOUBUYTHEMWITHCASH",
    ["how does trading work"] = "TRADEMACHINETWOSIDEDCONFIRMATIONFLOW",
    ["how long does admin abuse last"] = "30TO45MINUTES",
    ["how many base slots max rebirth"] = "28",
    ["how many brainrots total"] = "OVER500",
    ["how many codes are there"] = "1ACTIVE",
    ["how many codes have there been"] = "AROUND20",
    ["how many country traits"] = "46",
    ["how many love love bear exist"] = "810",
    ["how many lucky blocks are there"] = "15",
    ["how many machines total"] = "20",
    ["how many members in brazilian spyder"] = "28MILLION",
    ["how many meowl exist"] = "2110",
    ["how many mutations are there now"] = "19",
    ["how many mutations can a brainrot have"] = "1",
    ["how many mutations per brainrot"] = "ONE",
    ["how many og brainrots are there"] = "6",
    ["how many rarity tiers"] = "8",
    ["how many rituals"] = "12",
    ["how many santas fuse brainrots"] = "19",
    ["how many secret brainrots"] = "141",
    ["how many skibidi toilet exist"] = "2538",
    ["how many strawberry elephant exist"] = "1264",
    ["how many traits can a brainrot have"] = "MULTIPLE",
    ["how many updates"] = "71",
    ["how much does the cheapest brainrot cost"] = "25DOLLARS",
    ["how much does the most expensive cost"] = "1TRILLION",
    ["how to craft camera ramena"] = "1XLOSBURRITOS1XLOSQUESADILLAS1XCHICLETEIRABICICLETEIRA",
    ["how to craft digi narwhal"] = "1XCAPITANOMOBY1XFISHINOCLOWNINO",
    ["how to craft duggy bros"] = "1XGOLDGOLDGOLD1XDUGDUGDUG",
    ["how to craft futbolini skatini"] = "2XFISHBOARD1XCHICLETEIRABICICLETEIRA",
    ["how to craft gym bros"] = "1XODINDINDINDUN1XFRAGOLALALALA1XSWAGSODA",
    ["how to craft kalika bros"] = "1XTIRILIKALIKATIRILIKALAKO1XHOPILIKALIKAHOPILIKALAKO",
    ["how to craft la craft machine"] = "1XFRAGOLALALALA1XCELULARCINIVIIOSINI1XLASSIS1XLASAHURCOMBINASION",
    ["how to craft los chillis"] = "3XCHILLINCHILI",
    ["how to craft los hackers"] = "1XJOHNDOE1X1X1X1X11XGUEST666",
    ["how to craft los noobinis"] = "3XNOOBINIPIZZANINI1XTRACODUCOTULU",
    ["how to craft skibidi toilet"] = "1XDRAGONGINGERINI3XDRAGONCANNELLONI",
    ["how to get :3 trait"] = "MIGATTORITUAL",
    ["how to get avocadorilla"] = "FUSECHEFCABRACADABRA+FRIGOCAMELO",
    ["how to get bacuru and egguru"] = "FUSEBACURU+EGGURU",
    ["how to get brazil trait"] = "ADMINABUSELASERBEAMSHITBRAINROT",
    ["how to get brr es teh patipum"] = "FUSETRALALEROTALALA+COCOFANTOELEFANTO",
    ["how to get bubblegum trait"] = "ADMINABUSEBUBBLEGUMMACHINEINMIDDLEOFMAP",
    ["how to get celestial pegasus fuse"] = "FUSE4STRAWBERRYELEPHANT10PERCENTCHANCE",
    ["how to get cocosini mama"] = "FUSE4BURBALONILOLIOLI",
    ["how to get comet struck"] = "RANDOMSTARFALLEVENT",
    ["how to get crab claw trait"] = "CRABRAVEADMINABUSE",
    ["how to get diamond mutation"] = "REDCARPETSPAWN5PERCENTCHANCE",
    ["how to get disco trait"] = "DJEVENTADMINABUSE",
    ["how to get explosive trait"] = "BOMBARDIROCROCODILORITUAL",
    ["how to get fire trait"] = "ADMINABUSESOLARFLAREHITSBRAINROT",
    ["how to get fireworks trait"] = "ADMINABUSEFIREWORKHITSBRAINROT",
    ["how to get galactic trait"] = "LAVACCASATURNOSATURNITARITUAL",
    ["how to get ganganzelli trulala"] = "FUSEBOMBARDIROCROCODILO+BLUEBERRINNIOCOPUSINI",
    ["how to get glitched trait"] = "ADMINABUSEGLITCHYSKY",
    ["how to get gold mutation"] = "REDCARPETSPAWN10PERCENTCHANCE",
    ["how to get hydra dragon cannelloni"] = "FUSE4STRAWBERRYELEPHANT10PERCENTCHANCE",
    ["how to get indonesia trait"] = "ADMINABUSEAURABOATEVENT",
    ["how to get ketupat bros"] = "FUSEKETUPATKEPAT+GINGERGERAT",
    ["how to get la jolly grande"] = "COLLECTALL4WINTERHOURBRAINROTSANDREDEEM",
    ["how to get la spooky grande"] = "MERGE4SECRETHALLOWEENBRAINROTSINWITCHFUSE",
    ["how to get la supreme combinasion"] = "FUSE4STRAWBERRYELEPHANT",
    ["how to get lightning trait"] = "ADMINABUSELIGHTNINGSTRIKESHITSBRAINROT",
    ["how to get los tungtungtungcitos"] = "FUSEODINDINDINDUM+PICCIONEMACCHINA",
    ["how to get magi ribbitini fuse"] = "FUSEGORILLOWATERMELONDRILLO+CAVALLOVIRTUOSO+2CACHORRITOMELONITO",
    ["how to get matteo hat trait"] = "MATTEORITUAL",
    ["how to get meowl trait"] = "MEOWLEVENT",
    ["how to get more base slots"] = "REBIRTH",
    ["how to get mutations"] = "EVENTSORREDCARPETSPAWNS",
    ["how to get nyan trait"] = "ADMINABUSENYANUNCATCIRCLESMAP",
    ["how to get paint trait"] = "CHICLETEIRABICICLETEIRARITUAL",
    ["how to get penguino cocosino fuse"] = "FUSE4BRRBRRPATAPIM",
    ["how to get pi pi watermelon fuse"] = "FUSE4BALLERINACAPPUCCINA",
    ["how to get pipi avocado"] = "FUSE4PIPIKIWI+BANDITOBOBRITTO",
    ["how to get quackula fuse"] = "FUSE3CHIMPANZINIBANANINI+BURBALONILOILOLI",
    ["how to get rainbow mutation"] = "REDCARPETSPAWN1PERCENTCHANCE",
    ["how to get shark fin trait"] = "ORCALEROORCALARITUAL",
    ["how to get snowy trait"] = "RANDOMSNOWWEATHER",
    ["how to get sombrero trait"] = "ADMINABUSEPINATAANDCOCKROACHES",
    ["how to get spider trait"] = "SAMMYNISPYDERINIRITUAL",
    ["how to get strawberry trait"] = "STRAWBERRYELEPHANTEVENT",
    ["how to get taco trait"] = "ADMINABUSETACOCANNONGUARANTEEDONTACOTUESDAY",
    ["how to get tie trait"] = "DULDULDULRITUAL",
    ["how to get tob tobi tobi"] = "FUSEFRIGOCAMELO+SIGMABOY",
    ["how to get ufo trait"] = "ADMINABUSEUFOBEAMHITSBRAINROT",
    ["how to get wet trait"] = "RANDOMRAINWEATHER",
    ["how to get zombie trait"] = "ADMINABUSEEVILTTUNGTUNGSATTACK",
    ["hydra bunny egg lucky block chance"] = "0.1PERCENT",
    ["hydra bunny rarity"] = "SECRET",
    ["hydra dragon cannelloni rarity"] = "SECRET",
    ["hydra dragon cannelloni recipe"] = "STRAWBERRYELEPHANTX4",
    ["ilovefood123"] = "KRAKEN",
    ["ilovefood123 code"] = "EXPIRED",
    ["imanegg"] = "STRAWBERRYELEPHANT",
    ["indonesia trait multiplier"] = "5X",
    ["is 10b trait returning"] = "NO",
    ["is craft machine removed"] = "RETURNEDUPDATE66",
    ["is divine fuse removed"] = "YES",
    ["is fuse machine removed"] = "YES",
    ["is neon mutation obtainable"] = "NO",
    ["is rose trait obtainable"] = "NO",
    ["is sammy dead"] = "NO",
    ["is santas fuse removed"] = "YES",
    ["is saturn code expired"] = "YES",
    ["is smurf cat og"] = "RUMOREDTBA",
    ["is spydersammy dead"] = "NO",
    ["is spydersammy youtube real"] = "FAKEACCOUNTSEXIST",
    ["is there a sab movie"] = "INDEVELOPMENT",
    ["is trade machine permanent"] = "YESMOVEDTOPERMANENTMENU",
    ["is trading permanent"] = "YESSINCEUPDATE53",
    ["is witch fuse removed"] = "YES",
    ["italian brainrot origin"] = "ITALIANINTERNETMEMES",
    ["jack o lantern trait multiplier"] = "5.5X",
    ["jacko jack jack cost"] = "30000000",
    ["jacko jack jack income"] = "150000",
    ["jacko jack jack rarity"] = "BRAINROTGOD",
    ["jacko spaventosa cost"] = "4800000",
    ["jacko spaventosa income"] = "16200",
    ["jackorilla spooky lucky block chance"] = "19.5PERCENT",
    ["jandel bet amount"] = "5000PERMILLION",
    ["jingle jingle sahur cost"] = "4300000",
    ["jingle jingle sahur income"] = "12200",
    ["jingle jingle sahur rarity"] = "MYTHIC",
    ["job application trait"] = "4X",
    ["job application trait multiplier"] = "4X",
    ["job job job sahur ritual players"] = "4",
    ["job ritual result"] = "YESSMYRESUME",
    ["john pork rarity"] = "OG",
    ["john pork update"] = "UPDATE49",
    ["johnporkdapiggy"] = "JOHNPORK",
    ["july 2025 ccu"] = "5MILLION",
    ["kalika bros rarity"] = "SECRET",
    ["karkerheart luvkur rarity"] = "LEGENDARY",
    ["karkerkar ritual formation"] = "RHOMBOID",
    ["karkerkar ritual players"] = "4",
    ["karkerkar ritual result"] = "LOSKARKERITOS",
    ["ketchuru and musturu"] = "KETCHURUANDMUSTURU",
    ["ketchuru and musturu rarity"] = "SECRET",
    ["ketupat bros recipe"] = "KETUPATKEPAT+GINGERGERAT",
    ["ketupat kepat rarity"] = "SECRET",
    ["koala parabala cost"] = "35000000",
    ["koala parabala income"] = "200000PERSECOND",
    ["l2exploiters"] = "JOHNPORK",
    ["la casa boo spooky lucky block chance"] = "0.3PERCENT",
    ["la cucaracha income"] = "475000PERSECOND",
    ["la food combinasion taco lucky block chance"] = "0.3PERCENT",
    ["la ginger sekolah rarity"] = "SECRET",
    ["la grande combinasion admin lucky block chance"] = "0.5PERCENT",
    ["la secret combinasion secret lucky block chance"] = "0.5PERCENT",
    ["la supreme combinasion recipe"] = "STRAWBERRYELEPHANTX4",
    ["la vacca prese presente rarity"] = "SECRET",
    ["la vacca saturno saturnita income"] = "300000PERSECOND",
    ["las tralaleritas income"] = "650000PERSECOND",
    ["las vaquitas saturnitas income"] = "750000PERSECOND",
    ["latest rebirth"] = "19",
    ["lava mutation multiplier"] = "6X",
    ["lemonita splashita rarity"] = "BRAINROTGOD",
    ["leprechaun lucky block rarest drop"] = "FORTUNUANDCASHURU",
    ["lerulerulerule income"] = "8750",
    ["lerulerulerule rarity"] = "MYTHIC",
    ["lionel cactuseli income"] = "650",
    ["lionel cactuseli rarity"] = "LEGENDARY",
    ["lirili larila rarity"] = "COMMON",
    ["list all machines"] = "FUSEMACHINECRAFTMACHINEWITCHFUSESANTASFUSEDIVINEFUSECYBERCRAFTSUMMERFUSEBRAINROTDEALERBRAINROTTRADERSANTASHSHOPLOSTRADERSDUELSMACHINETRADEMACHINEEGGINCUBATORRAINBOWMACHINEBUBBLEGUMMACHINEADVENTCALENDARADMINMACHINENEWJEARSMACHINECUPIDSMACHINE",
    ["list all og brainrots"] = "SKIBIDITOILET",
    ["llm event"] = "ISLANDJUMPINGEGGSXPTRAINING",
    ["los 67 los lucky block chance"] = "0.5PERCENT",
    ["los admins"] = "LOSADMINS",
    ["los admins cost"] = "35BILLION",
    ["los admins income"] = "95000000PERSEC",
    ["los admins rarity"] = "SECRET",
    ["los amigos los taco lucky block chance"] = "0.15PERCENT",
    ["los bombinitos admin lucky block chance"] = "20PERCENT",
    ["los bombinitos los lucky block chance"] = "39.75PERCENT",
    ["los burritos los taco lucky block chance"] = "2PERCENT",
    ["los chihuaninis los taco lucky block chance"] = "50.85PERCENT",
    ["los chillis rarity"] = "SECRET",
    ["los combinasionas los lucky block chance"] = "1PERCENT",
    ["los cornis"] = "LOSCORNIS",
    ["los cornis cost"] = "715MILLION",
    ["los cornis income"] = "3100000PERSEC",
    ["los cornis rarity"] = "SECRET",
    ["los crocodillitos income"] = "55000",
    ["los crocodillitos rarity"] = "BRAINROTGOD",
    ["los cucarachas los taco lucky block chance"] = "5PERCENT",
    ["los cupids income"] = "30000000PERSEC",
    ["los cupids rarity"] = "SECRET",
    ["los gattitos los taco lucky block chance"] = "38PERCENT",
    ["los hackers rarity"] = "SECRET",
    ["los hackers recipe"] = "1XJOHNDOE1X1X1X1X11XGUEST666",
    ["los jobcitos los lucky block chance"] = "3.5PERCENT",
    ["los karkeritos income"] = "750000PERSECOND",
    ["los lucky block best drop"] = "LOSSEKOLAHS",
    ["los lucky block cost"] = "250000000",
    ["los lucky block price"] = "250000000",
    ["los lucky block rarest drop"] = "LOSSEKOLAHS",
    ["los matteos how to get"] = "MATTEORITUAL3PLAYERSSTACK",
    ["los noobinis income"] = "12500",
    ["los noobinis rarity"] = "MYTHIC",
    ["los nooo my hotspotsitos taco lucky block chance"] = "1PERCENT",
    ["los orcalitos los lucky block chance"] = "15PERCENT",
    ["los quesadillas los taco lucky block chance"] = "4PERCENT",
    ["los sekolahs los lucky block chance"] = "0.25PERCENT",
    ["los sigmas"] = "LOSSIGMAS",
    ["los sigmas cost"] = "580MILLION",
    ["los sigmas income"] = "2300000PERSEC",
    ["los sigmas rarity"] = "SECRET",
    ["los spooky combinasionas spooky lucky block chance"] = "1PERCENT",
    ["los spyderinis how to get"] = "SPYDERINIRITUAL4PLAYERSSQUARE",
    ["los spyderinis income"] = "425000PERSECOND",
    ["los taco block cost"] = "300000000",
    ["los taco lucky block cost"] = "300000000",
    ["los taco lucky block price"] = "300000000",
    ["los tangcitos"] = "LOSTANGCITOS",
    ["los tangcitos cost"] = "7500000000",
    ["los tangcitos income"] = "42500000PERSEC",
    ["los tangcitos rarity"] = "SECRET",
    ["los tictacs"] = "LOSTICTACS",
    ["los tictacs cost"] = "15BILLION",
    ["los tictacs income"] = "60000000PERSEC",
    ["los tictacs rarity"] = "SECRET",
    ["los tipi tacos los lucky block chance"] = "10PERCENT",
    ["los tipi tacos taco lucky block chance"] = "10PERCENT",
    ["los tortus income"] = "500000PERSECOND",
    ["los tortus los lucky block chance"] = "5PERCENT",
    ["los traders date"] = "JULY112026",
    ["los traders how many brainrots"] = "6",
    ["los traders update"] = "57",
    ["los tralaleritos income"] = "500000PERSECOND",
    ["los trios income"] = "700000PERSECOND",
    ["los tungtungtungcitos los lucky block chance"] = "25PERCENT",
    ["los tungtungtungcitos recipe"] = "ODINDINDINDUN+PICCIONEMACCHINA",
    ["love love bear exist count"] = "810",
    ["love love love sahur income"] = "1000000PERSEC",
    ["love love love sahur rarity"] = "BRAINROTGOD",
    ["lovin rose rarity"] = "SECRET",
    ["lucky trait multiplier"] = "6X",
    ["luke noom"] = "LUKENOOM",
    ["luv luv luv heart lucky block chance"] = "30.95PERCENT",
    ["luv luv luv income"] = "282500PERSEC",
    ["luv luv luv rarity"] = "LEGENDARY",
    ["magi ribbitini income"] = "12000",
    ["magi ribbitini rarity"] = "MYTHIC",
    ["malame amarele income"] = "140",
    ["malame amarele rarity"] = "EPIC",
    ["mangolini parrocini income"] = "235",
    ["mangolini parrocini rarity"] = "EPIC",
    ["mastodontico telepiedone god lucky block chance"] = "5PERCENT",
    ["matteo hat ritual"] = "MATTEORITUAL",
    ["matteo hat trait multiplier"] = "4.5X",
    ["matteo rarity"] = "BRAINROTGOD",
    ["matteo ritual formation"] = "VERTICALSTACK",
    ["matteo ritual how to"] = "3PLAYERSSTACKWHILEHOLDINGMATTEO",
    ["matteo ritual players"] = "3",
    ["matteo ritual result"] = "LOSMATTEOS",
    ["max base slots"] = "28",
    ["max ccu ever"] = "25MILLION",
    ["max rebirth level"] = "19",
    ["maymeowljandel"] = "MEOWL",
    ["meowl exist count"] = "2110",
    ["meowl rarity"] = "OG",
    ["mexico trait multiplier"] = "6X",
    ["mi gatito ritual players"] = "2",
    ["mi gatito ritual result"] = "LOSMIGATITOS",
    ["moby bros"] = "MOBYBROS",
    ["moby bros cost"] = "225BILLION",
    ["moby bros income"] = "225000000PERSEC",
    ["moby bros rarity"] = "SECRET",
    ["money money bros rarity"] = "SECRET",
    ["money money man income"] = "65000",
    ["money money man rarity"] = "BRAINROTGOD",
    ["money money puggy ritual players"] = "2",
    ["money puggy ritual result"] = "LOSPUGGIES",
    ["mortaruga cost"] = "80000000",
    ["most concurrent players sab"] = "25MILLION",
    ["most expensive brainrot"] = "SPYDERELEPHANT",
    ["most expensive brainrot god"] = "PRETZOROBO",
    ["most expensive og"] = "SPYDERELEPHANT",
    ["mummio rappitto income"] = "325",
    ["mummio rappitto rarity"] = "EPIC",
    ["mummy ambalabu spooky lucky block chance"] = "32.7PERCENT",
    ["mutation income formula"] = "BASEINCOMEXMUTATIONMULTIPLIERPLUSALLTRAITMULTIPLIERS",
    ["mutations stack with traits"] = "YES",
    ["mythic lucky block best drop"] = "BANANITOBANDITO",
    ["mythic lucky block rarest drop"] = "BANANITOBANDITO",
    ["mythic lucky block robux"] = "175ROBUX",
    ["needthis4craft333"] = "CHICLETEIRASURFEITEIRA",
    ["needthis4craft333 code"] = "EXPIRED",
    ["neon mutation"] = "NEON",
    ["neon mutation multiplier"] = "0X",
    ["neon mutation obtainable"] = "NO",
    ["new year trait"] = "6X",
    ["new years machine cost"] = "BRAINROTSEARNINGOVER50KPERSECPLUSADDITIONALBRAINROTS",
    ["new years machine date"] = "DECEMBER312025",
    ["newest og brainrot"] = "JOHNPORK",
    ["next update"] = "UPDATE72",
    ["noo my heart income"] = "13000000PERSEC",
    ["noo my heart rarity"] = "SECRET",
    ["noobini pizzanini rarity"] = "COMMON",
    ["noobini santanini income"] = "11",
    ["noobini santanini rarity"] = "COMMON",
    ["number of og brainrots"] = "6",
    ["number of secret brainrots"] = "141",
    ["nyan trait multiplier"] = "6X",
    ["octo lucky block robux"] = "799ROBUX",
    ["october 2025 ccu"] = "25400000",
    ["octoblock555"] = "OCTOLUCKYBLOCK",
    ["octoblock555 code"] = "EXPIRED",
    ["odin din din dun income"] = "75000",
    ["ombrello topolino rarity"] = "SECRET",
    ["oni oni panda cost"] = "2800000000",
    ["orange balloon trait multiplier"] = "4X",
    ["orange egg trait multiplier"] = "4X",
    ["orangutini ananassini income"] = "1700",
    ["orangutini ananassini rarity"] = "MYTHIC",
    ["orbi mochi income"] = "18500",
    ["orbi mochi rarity"] = "MYTHIC",
    ["orcalero orcala god lucky block chance"] = "30PERCENT",
    ["orcalero ritual formation"] = "ROWWITHONESLIGHTLYBEHIND",
    ["orcalero ritual players"] = "4",
    ["orcalero ritual result"] = "LOSORCALITOS",
    ["orcalita orcala rarity"] = "BRAINROTGOD",
    ["paint trait ritual"] = "CHICLETEIRABICICLETEIRARITUAL",
    ["pandaccini bananini income"] = "1200",
    ["pandaccini bananini rarity"] = "LEGENDARY",
    ["pandanini frostini festive lucky block chance"] = "30PERCENT",
    ["paradiso axolottino income"] = "900000PERSECOND",
    ["paradiso axolottino rarity"] = "SECRET",
    ["peak concurrent players"] = "25400000",
    ["pengolino nuvoletto income"] = "72",
    ["pengolino nuvoletto rarity"] = "RARE",
    ["penguin tree income"] = "270",
    ["penguin tree rarity"] = "EPIC",
    ["penguino cocosino income"] = "300",
    ["penguino cocosino rarity"] = "EPIC",
    ["penguino cocosino recipe"] = "BRRBRRPATAPIMX4",
    ["perochello lemonchello income"] = "160",
    ["perochello lemonchello rarity"] = "EPIC",
    ["phantom mutation multiplier"] = "12X",
    ["pi pi watermelon income"] = "1200",
    ["pi pi watermelon rarity"] = "LEGENDARY",
    ["pi pi watermelon recipe"] = "BALLERINACAPPUCCINAX4",
    ["pinealotto fruttarino income"] = "75",
    ["pinealotto fruttarino rarity"] = "EPIC",
    ["pineaplino cost"] = "35000000",
    ["pineaplino income"] = "200000PERSECOND",
    ["pink balloon trait multiplier"] = "6.5X",
    ["pink egg trait multiplier"] = "7.5X",
    ["pipi avocado fuse recipe"] = "PIPIKIWIX2+BANDITOBOBRITTOX2",
    ["pipi avocado income"] = "70",
    ["pipi avocado rarity"] = "RARE",
    ["pipi corni income"] = "14",
    ["pipi corni rarity"] = "COMMON",
    ["pipi kiwi rarity"] = "COMMON",
    ["pipi potato income"] = "1100",
    ["pipi potato rarity"] = "LEGENDARY",
    ["pizzaisyum"] = "PIZZAANDRANCH",
    ["plant bros from haunted fuse"] = "PLANTBROS",
    ["polaroidini exist count"] = "15",
    ["polaroidini rarity"] = "RAREST15EXIST",
    ["pop pop sahur god lucky block chance"] = "1PERCENT",
    ["pot hotspot secret lucky block chance"] = "21PERCENT",
    ["pretzo robo income"] = "320000",
    ["pretzo robo rarity"] = "BRAINROTGOD",
    ["prismatic multiplier"] = "13X",
    ["prismatic mutation"] = "PRISMATIC",
    ["prismatic mutation multiplier"] = "13X",
    ["puffaball income"] = "1500",
    ["puffaball rarity"] = "LEGENDARY",
    ["pumpkini spyderini spooky lucky block chance"] = "9PERCENT",
    ["quackula income"] = "1200",
    ["quackula rarity"] = "LEGENDARY",
    ["queen bee trait multiplier"] = "5X",
    ["quesadilla crocodila taco lucky block chance"] = "5PERCENT",
    ["quivioli ameleonni income"] = "1000",
    ["quivioli ameleonni rarity"] = "LEGENDARY",
    ["raccooni jandelini income"] = "12",
    ["raccooni jandelini rarity"] = "COMMON",
    ["radioactive mutation multiplier"] = "8.5X",
    ["rainbow balloon trait multiplier"] = "7.5X",
    ["rainbow machine cost"] = "25GOLDBRAINROTS",
    ["rainbow machine date"] = "JUNE212025",
    ["rainbow mutation chance"] = "1PERCENT",
    ["rainbow mutation multiplier"] = "10X",
    ["rainbow mutation spawn chance"] = "1PERCENT",
    ["rainbow spawn rate"] = "1PERCENT",
    ["ranito pepito cost"] = "237500000",
    ["ranito pepito income"] = "950000PERSECOND",
    ["rarest divine fuse brainrot"] = "GRIFFIN",
    ["rarest drop in the game"] = "CELESTIALPEGASUS",
    ["rarest lucky block drop"] = "CELESTIALPEGASUS",
    ["rarest summer fuse brainrot"] = "DRAGONAQUANINI",
    ["rarest witch fuse"] = "LASPOOKYGRANDE",
    ["rarity order"] = "COMMON",
    ["rarity tiers"] = "COMMONRAREEPICLEGENDARYMYTHICBRAINROTGODSECRETOG",
    ["rebirth 1 brainrot"] = "TRIPPITROPPIANDGANGSTERFOOTERA",
    ["rebirth 1 cost"] = "500K",
    ["rebirth 1 multiplier"] = "0.5X",
    ["rebirth 1 reward"] = "FRIENDCONTROLLERANDIRONSLAP",
    ["rebirth 10 brainrot"] = "GIRAFACELESTRE",
    ["rebirth 10 cost"] = "125000000000",
    ["rebirth 10 multiplier"] = "9X",
    ["rebirth 10 reward"] = "GLITCHEDSLAPANDBODYSWAPPOTION",
    ["rebirth 11 brainrot"] = "TRALALEROTRALA",
    ["rebirth 11 cost"] = "800000000000",
    ["rebirth 11 multiplier"] = "10X",
    ["rebirth 11 reward"] = "SPLATTERSLAPANDPAINTBALLGUN",
    ["rebirth 12 brainrot"] = "ODINDINDINDUM",
    ["rebirth 12 cost"] = "3500000000000",
    ["rebirth 12 multiplier"] = "11X",
    ["rebirth 12 reward"] = "HEARTBALLOONANDMAGNET",
    ["rebirth 13 brainrot"] = "TRENOSTRUZZOTURBO3000",
    ["rebirth 13 cost"] = "14000000000000",
    ["rebirth 13 multiplier"] = "12X",
    ["rebirth 13 reward"] = "MEGAPHONEANDBEHIVE",
    ["rebirth 14 brainrot"] = "TRIPPITROPPITRPATRIPPA",
    ["rebirth 14 cost"] = "40000000000000",
    ["rebirth 14 multiplier"] = "13X",
    ["rebirth 14 reward"] = "GUMMYBEARANDSUBSPACEMINE",
    ["rebirth 15 brainrot"] = "PAKRAHMATMAMAT",
    ["rebirth 15 cost"] = "100000000000000",
    ["rebirth 15 multiplier"] = "15X",
    ["rebirth 15 reward"] = "HEATSEEKER",
    ["rebirth 16 brainrot"] = "LOSTRALALERITOS",
    ["rebirth 16 cost"] = "1QUADRILLION",
    ["rebirth 16 multiplier"] = "16X",
    ["rebirth 16 reward"] = "ATTACKDOGE",
    ["rebirth 17 brainrot"] = "JOBJOBJODSAHURANDCHICLETEIRABICICLETEIRA",
    ["rebirth 17 cost"] = "2QUADRILLION",
    ["rebirth 17 multiplier"] = "17X",
    ["rebirth 17 reward"] = "GIANTPOTION",
    ["rebirth 18 brainrot"] = "GRAIPUSSMEDUSSI",
    ["rebirth 18 cost"] = "10QUADRILLION",
    ["rebirth 18 multiplier"] = "18X",
    ["rebirth 18 reward"] = "FLASHTELEPORT",
    ["rebirth 19 brainrot"] = "LAGRANDECOMBINAISON",
    ["rebirth 19 cost"] = "30QUADRILLION",
    ["rebirth 19 multiplier"] = "19X",
    ["rebirth 19 reward"] = "GRIEFSHIELD",
    ["rebirth 19 starting cash"] = "250TRILLION",
    ["rebirth 2 brainrot"] = "BRRBRRPATAPIMANDBONETAAMBALABU",
    ["rebirth 2 cost"] = "1500000",
    ["rebirth 2 multiplier"] = "1X",
    ["rebirth 2 reward"] = "GOLDSLAPANDCOILCOMBO",
    ["rebirth 3 brainrot"] = "TRULIMEROTRULICINACHIMPANZINIBANANINI",
    ["rebirth 3 cost"] = "12500000",
    ["rebirth 3 multiplier"] = "2X",
    ["rebirth 3 reward"] = "DIAMONDSLAPANDGRAPPLEHOOK",
    ["rebirth 4 brainrot"] = "GLORBOFRUTTODRILLOCHEFCRABRACADABRA",
    ["rebirth 4 cost"] = "35000000",
    ["rebirth 4 multiplier"] = "3X",
    ["rebirth 4 reward"] = "EMERALDSLAPANDINVISIBILITYCLOAK",
    ["rebirth 5 brainrot"] = "ORANGUTINIANANASSINIFRIGOCAMELO",
    ["rebirth 5 cost"] = "100000000",
    ["rebirth 5 multiplier"] = "4X",
    ["rebirth 5 reward"] = "RUBYSLAPANDMEDUSASHEAD",
    ["rebirth 6 brainrot"] = "BOMBARDIROCROCODILO",
    ["rebirth 6 cost"] = "350000000",
    ["rebirth 6 multiplier"] = "5X",
    ["rebirth 6 reward"] = "DARKMATTERSLAPANDWEBSLINGER",
    ["rebirth 7 brainrot"] = "BOMBOMBINIGUSINI",
    ["rebirth 7 cost"] = "1000000000",
    ["rebirth 7 multiplier"] = "6X",
    ["rebirth 7 reward"] = "FLAMESLAPANDQUANTUMCLONER",
    ["rebirth 8 brainrot"] = "TETETETESAHUR",
    ["rebirth 8 cost"] = "5000000000",
    ["rebirth 8 multiplier"] = "7X",
    ["rebirth 8 reward"] = "NUCLEARSLAPANDRAINBOWRATHSWORD",
    ["rebirth 9 brainrot"] = "COCOFANTOELEFANTO",
    ["rebirth 9 cost"] = "12500000000",
    ["rebirth 9 multiplier"] = "8X",
    ["rebirth 9 reward"] = "GALAXYSLAPANDLASERCAPE",
    ["rebirth base lock time"] = "10SECONDSPERLEVEL",
    ["rebirth base slots total"] = "28",
    ["red balloon trait multiplier"] = "6X",
    ["red carpet"] = "THECONVEYORBELTWHEREBRAINROTSSPAWN",
    ["red carpet mutations"] = "GOLDDIAMONDANDRAINBOW",
    ["reindeer trait"] = "6X",
    ["reindeer trait multiplier"] = "6X",
    ["reinito sleighito festive lucky block chance"] = "0.1PERCENT",
    ["rhino helicopterino income"] = "11000",
    ["rhino helicopterino rarity"] = "MYTHIC",
    ["rhino toasterino income"] = "2100",
    ["rhino toasterino rarity"] = "MYTHIC",
    ["rip tombstone trait multiplier"] = "4.5X",
    ["roblox total ccu admin war"] = "47400000",
    ["rocco disco income"] = "650000PERSECOND",
    ["rose trait multiplier"] = "6X",
    ["rosetti tualetti income"] = "50000000PERSEC",
    ["rosetti tualetti rarity"] = "SECRET",
    ["rosey and teddy heart lucky block chance"] = "0.05PERCENT",
    ["rosey and teddy rarity"] = "SECRET",
    ["sab admin war ccu"] = "20MILLION",
    ["sab available platforms"] = "WINDOWSMACOSANDROIDIOSPS4PS5XBOXONE",
    ["sab concurrent player record"] = "25MILLION",
    ["sab concurrent record"] = "25.4MILLION",
    ["sab copyright"] = "USCOPYRIGHTOFFICEPA002544969",
    ["sab copyright number"] = "PA002544969",
    ["sab developer studio"] = "DOBIGSTUDIOS",
    ["sab fortnite clone lawsuit"] = "OCTOBER2025",
    ["sab fortnite version"] = "STEALTHEBRAINROT",
    ["sab most played"] = "BIGGESTEXPERIENCEONROBLOX",
    ["sab movie"] = "INDEVELOPMENTBYSTORYKITCHEN",
    ["sab movie studio"] = "STORYKITCHEN",
    ["sab record"] = "FIRSTGAMEOVER25MILLIONCCU",
    ["sab release year"] = "2025",
    ["sab roblox innovation award"] = "BESTCREATIVEDIRECTION2025",
    ["sab vs fortnite ccu"] = "20MILLIONVS15MILLION",
    ["salamino penguino income"] = "250",
    ["salamino penguino rarity"] = "EPIC",
    ["sammy admin abuse war with who"] = "JANDELFROMGROWAGARDEN",
    ["sammy and jandel relationship"] = "FRIENDSOFFCAMERA",
    ["sammy birth date"] = "FEBRUARY25",
    ["sammy birthday month and day"] = "FEBRUARY25",
    ["sammy career start year"] = "2013",
    ["sammy co founder"] = "LUKENOOM",
    ["sammy cofounded with"] = "DOSMALL",
    ["sammy company"] = "DOBIGSTUDIOS",
    ["sammy discord"] = "STEALABRAINROTDISCORD",
    ["sammy emoji"] = ":3",
    ["sammy exact birthday"] = "FEBRUARY242002",
    ["sammy fav brainrot"] = "MEOWL",
    ["sammy favorite food"] = "PIZZA",
    ["sammy first game"] = "MININGCLICKERSIMULATOR",
    ["sammy first roblox game"] = "CRABGAME",
    ["sammy group name"] = "BRAZILIANSPYDER",
    ["sammy impersonators"] = "YES",
    ["sammy job title"] = "CPO",
    ["sammy lives where"] = "NEWORLEANS",
    ["sammy other games"] = "BLADEBALL",
    ["sammy previous games"] = "CRABGAMEMININGCLICKERSIMULATOR",
    ["sammy rival"] = "JANDEL",
    ["sammy role"] = "CHIEFPRODUCTOFFICER",
    ["sammy role at do big studios"] = "CHIEFPRODUCTOFFICER",
    ["sammy signature emoji"] = ":3",
    ["sammy x account"] = "SPYDERSAMMY",
    ["sammy youtube channel real"] = "NOOFFICIALCHANNEL",
    ["sammyini fattini admin lucky block chance"] = "0.45PERCENT",
    ["sammyni spookyni event"] = "HALLOWEEN2026",
    ["sammyni spookyni update"] = "UPDATE69",
    ["sammyni spyderini full name"] = "SAMMYNISPYDERINIUNRAGNOMOLTOMOLTOVELENOSEEMOLTOSPAVENTOSO",
    ["sammyni spyderini how to get"] = "ADMINABUSEONLY",
    ["sammyni spyderini income"] = "325000PERSECOND",
    ["sammyni spyderini italian meaning"] = "AVERYVERYPOISONOUSANDVERYSCARYSIDER",
    ["sammyni spyderini spawn"] = "ADMINABUSEONLY",
    ["sammys community group"] = "BRAZILIANSPYDER",
    ["sammys favorite emoji"] = ":3",
    ["santa hat trait multiplier"] = "5X",
    ["santas fuse date"] = "DECEMBER62025",
    ["santas fuse status"] = "REMOVEDCHRISTMASMACHINE",
    ["santas shop cost"] = "GOLDELVESORRROBUX",
    ["santas shop date"] = "CHRISTMAS2025",
    ["santteo income"] = "800000PERSECOND",
    ["saturn code status"] = "EXPIRED",
    ["sealo regalo income"] = "1800",
    ["sealo regalo rarity"] = "LEGENDARY",
    ["second best mutation"] = "CRYSTAL",
    ["second best trait"] = "MEOWL",
    ["second most popular game on roblox"] = "STEALABRAINROT",
    ["secret lucky block best drop"] = "CELESTIALPEGASUS",
    ["secret lucky block celestial chance"] = "0.05PERCENT",
    ["secret lucky block combinasion chance"] = "0.5PERCENT",
    ["secret lucky block rarest drop"] = "CELESTIALPEGASUS",
    ["secret lucky block robux"] = "2399ROBUX",
    ["secret lucky block spaghetti chance"] = "1PERCENT",
    ["september 2025 ccu"] = "24MILLION",
    ["serafinna medusella income"] = "5500000PERSEC",
    ["seraphino gruyero income"] = "1900",
    ["seraphino gruyero rarity"] = "LEGENDARY",
    ["seventeenth mutation"] = "DISCO",
    ["shark fin ritual"] = "ORCALEROORCALARITUAL",
    ["shark fin trait multiplier"] = "4X",
    ["sigma boy income"] = "1300",
    ["sigma girl income"] = "1800",
    ["signore carapace income"] = "1300",
    ["signore carapace rarity"] = "LEGENDARY",
    ["sixteenth mutation"] = "PRISMATIC",
    ["skeleton event update"] = "UPDATE71",
    ["skeleton trait multiplier"] = "4X",
    ["skibidi toilet exist count"] = "2538",
    ["skibidi toilet rarity"] = "OG",
    ["skull lucky block rarest drop"] = "DRAGONSKELETONINI",
    ["slap gear types"] = "IRONGODDIAMONDEMERALDRUBYDARKMATTERFLAMEGALAXYNUCLEARGLITCHEDSPLATTER",
    ["sleepy multiplier"] = "0.5X",
    ["sleepy mutation multiplier"] = "0.5X",
    ["sleepy trait effect"] = "HALVESINCOMETOHALFX",
    ["smurf cat rarity"] = "OG",
    ["smurf cat status"] = "RUMORED",
    ["snowy trait"] = "2.5X",
    ["snowy trait multiplier"] = "3X",
    ["sombrero trait multiplier"] = "5X",
    ["spaghetti tualetti secret lucky block chance"] = "1PERCENT",
    ["spider trait multiplier"] = "4.5X",
    ["spider trait ritual"] = "SAMMYNISPYDERINIRITUAL",
    ["spioniro golubiro income"] = "3500",
    ["spioniro golubiro mythic lucky block chance"] = "37PERCENT",
    ["spioniro golubiro rarity"] = "MYTHIC",
    ["spongini quackini income"] = "15000",
    ["spongini quackini rarity"] = "MYTHIC",
    ["spooky lucky block best chance"] = "0.3PERCENT",
    ["spooky lucky block best drop"] = "LACASABOO",
    ["spooky lucky block rarest drop"] = "LACASABOO",
    ["spyder elephant how to get"] = "OWNSSPECIFICROBLOXACCESSORY",
    ["spyder elephant income per second"] = "1BILLION",
    ["spyder elephant rarity"] = "OG",
    ["spyderini ritual formation"] = "SQUAREFORMATION",
    ["spyderini ritual how to"] = "4PLAYERSSQUAREWITHSAMMYNISPYDERINI",
    ["spyderini ritual players"] = "4",
    ["spyderini ritual result"] = "LOSSPYDERINIS",
    ["spydersammy real name"] = "SAMBRAKTA",
    ["squalanana rarity"] = "BRAINROTGOD",
    ["statutino libertino income"] = "75000",
    ["statutino libertino rarity"] = "BRAINROTGOD",
    ["steak admin abuse brainrot"] = "STEAKINIFATTINI",
    ["steak admin abuse trait"] = "BURGER",
    ["stealing brainrots lawsuit"] = "SPYDERGAMESSUEDUNLICENSEDFORTNITEVERSION",
    ["stoppo luminino income"] = "8000",
    ["stoppo luminino rarity"] = "MYTHIC",
    ["strawberrelli flamingelli income"] = "1100",
    ["strawberrelli flamingelli rarity"] = "LEGENDARY",
    ["strawberry elephant exist count"] = "1264",
    ["strawberry elephant rarity"] = "OG",
    ["strongest trait"] = "STRAWBERRY",
    ["summer fuse date"] = "MAY232026",
    ["summer fuse how many brainrots"] = "19",
    ["summerupd3"] = "ROCKETINIFROSTINIORFRULLATOFRAMINGO",
    ["summerupd3 code"] = "EXPIRED",
    ["sundrilla sundae rarity"] = "BRAINROTGOD",
    ["svinina bombardino income"] = "10",
    ["svinina bombardino rarity"] = "COMMON",
    ["ta ta ta ta sahur income"] = "55",
    ["ta ta ta ta sahur rarity"] = "RARE",
    ["taco lucky block best drop"] = "LAFOODCOMBINAISON",
    ["taco lucky block price"] = "50000000",
    ["taco lucky block rarest drop"] = "LAFOODCOMBINAISON",
    ["taco trait"] = "4X",
    ["taco trait multiplier"] = "4X",
    ["talpa di fero income"] = "9",
    ["talpa di fero rarity"] = "COMMON",
    ["tartaragno income"] = "13",
    ["tartaragno rarity"] = "COMMON",
    ["te te te sahur income"] = "9500",
    ["te te te sahur rarity"] = "MYTHIC",
    ["telemorte spooky lucky block chance"] = "2PERCENT",
    ["third best mutation"] = "PRISMATIC",
    ["ti ti ti sahur income"] = "225",
    ["ti ti ti sahur rarity"] = "EPIC",
    ["tie trait multiplier"] = "4.75X",
    ["tie trait ritual"] = "DULDULDULRITUAL",
    ["tigrilini watermelini income"] = "7500",
    ["tigrilini watermelini mythic lucky block chance"] = "20PERCENT",
    ["tigrilini watermelini rarity"] = "MYTHIC",
    ["tigroligre frutonni god lucky block chance"] = "54PERCENT",
    ["tigroligre frutonni rarity"] = "BRAINROTGOD",
    ["tim cheese rarity"] = "COMMON",
    ["tipi topi taco income"] = "75000",
    ["tipi topi taco rarity"] = "BRAINROTGOD",
    ["tirilikalika tirilikalako income"] = "450",
    ["tirilikalika tirilikalako rarity"] = "LEGENDARY",
    ["tob tobi tobi income"] = "8500",
    ["tob tobi tobi rarity"] = "MYTHIC",
    ["tob tobi tobi recipe"] = "FRIGOCAMELO+SIGMABOY",
    ["toiletto focaccino income"] = "16000",
    ["toiletto focaccino rarity"] = "MYTHIC",
    ["torrtuginni dragonfrutini secret lucky block chance"] = "74.45PERCENT",
    ["total active codes"] = "1",
    ["total brainrots in game"] = "OVER500",
    ["total expired codes"] = "19",
    ["total machines in sab"] = "20",
    ["total mutations 2026"] = "19",
    ["total og brainrots"] = "6",
    ["total rituals"] = "12",
    ["total secret brainrots"] = "141",
    ["total updates"] = "71",
    ["total visits"] = "7BILLION",
    ["tracoducotulu delapeladustuz income"] = "12000",
    ["tracoducotulu delapeladustuz rarity"] = "MYTHIC",
    ["trade machine date"] = "FEBRUARY212026",
    ["trade machine update"] = "39",
    ["trade plaza"] = "PERMANENTTRADINGAREA",
    ["traits and mutations"] = "TRAITSADDTOMUTATIONMULTIPLIERNOTMULTIPLY",
    ["tralalero tralala meaning"] = "ITALIANBRAINROTMEME",
    ["tralalita tralala income"] = "100000",
    ["tralalita tralala rarity"] = "BRAINROTGOD",
    ["tree tree tree sahur income"] = "17000",
    ["tree tree tree sahur rarity"] = "MYTHIC",
    ["trenostruzzo turbo 3000 cost"] = "25000000",
    ["trenostruzzo turbo 3000 income"] = "150000PERSECOND",
    ["trenotubo axolotrico 9000 rarity"] = "BRAINROTGOD",
    ["trenozosturzzo turbo 3000 income"] = "150000",
    ["trenozosturzzo turbo 3000 rarity"] = "BRAINROTGOD",
    ["tric trac baraboom income"] = "65",
    ["tric trac baraboom rarity"] = "RARE",
    ["trickolino spooky lucky block chance"] = "3PERCENT",
    ["trippi troppi income"] = "15",
    ["trippi troppi troppa trippa income"] = "175000",
    ["trippi troppi troppa trippa rarity"] = "BRAINROTGOD",
    ["trulimero trulicina income"] = "125",
    ["trulimero trulicina rarity"] = "EPIC",
    ["tukanno banana income"] = "100000",
    ["tukanno banana rarity"] = "BRAINROTGOD",
    ["tukanno bananno cost"] = "22500000",
    ["tukanno bananno income"] = "100000PERSECOND",
    ["tung tung creator"] = "NOXAMEMEMTUMLAB",
    ["tung tung licensing"] = "DISPUTEWITHMEMEMTUMLAB",
    ["tung tung tung sahur income"] = "25",
    ["ufo trait"] = "3X",
    ["ufo trait multiplier"] = "4X",
    ["unclito samito rarity"] = "BRAINROTGOD",
    ["update 34 brainrot"] = "BRUNITOMARSITO",
    ["update 52.5"] = "STEAKADMINABUSE",
    ["update 52.5 date"] = "MAY302026",
    ["update 52.75"] = "CAYLUSADMINABUSE",
    ["update 52.75 date"] = "JUNE62026",
    ["update 54"] = "TRADEPLAZASUMMERHOUR",
    ["update 54 date"] = "JUNE202026",
    ["update 58"] = "5NEWBRAINROTS",
    ["update 58 date"] = "JULY182026",
    ["update 60"] = "NEWRITUAL2BRAINROTS",
    ["update 60 date"] = "AUGUST12026",
    ["update 63"] = "BEELUCKYBLOCK7BRAINROTS",
    ["update 63 date"] = "AUGUST222026",
    ["update 64"] = "HONEYBEEBASE5BRAINROTS",
    ["update 64 date"] = "AUGUST292026",
    ["update 65"] = "MONEYMONEYPUGGYRITUAL",
    ["update 65 date"] = "SEPTEMBER52026",
    ["update 66"] = "CRAFTMACHINERETURN9BRAINROTS",
    ["update 66 date"] = "SEPTEMBER122026",
    ["update 67"] = "2NEWBRAINROTS",
    ["update 67 date"] = "SEPTEMBER192026",
    ["update 68"] = "11NEWBRAINROTSLTMEVENT",
    ["update 68 date"] = "SEPTEMBER262026",
    ["urubini flamenguini income"] = "150000",
    ["urubini flamenguini rarity"] = "BRAINROTGOD",
    ["vampira cappucina income"] = "125000",
    ["vampira cappucina rarity"] = "BRAINROTGOD",
    ["vulturino skeletono income"] = "500000PERSECOND",
    ["waverider4freelol"] = "WAVERIDER",
    ["wet trait"] = "2.5X",
    ["wet trait multiplier"] = "2.5X",
    ["what are base slots"] = "SLOTSONYOURBASETOPLACEBRAINROTS",
    ["what are gears"] = "EQUIPABLEITEMSFORDEFENSEANDOFFENSE",
    ["what codes have expired"] = "BRUNOISBETTER",
    ["what day is taco tuesday"] = "TUESDAY",
    ["what day was sammy born"] = "FRIDAY",
    ["what does codesarereal321 give"] = "JOHNPORK",
    ["what does eclipse event give"] = "CASHREWARDSLUCKBOOSTSECLIPSELUCKYBLOCKECLIPSEHAMMER",
    ["what does free500drags give"] = "DRAGONCANNELLONI",
    ["what does freeoctoblock777 give"] = "OCTOLUCKYBLOCK",
    ["what does freepremiumocto777 give"] = "PREMIUMOCTOLUCKYBLOCK",
    ["what does ilovefood123 give"] = "KRAKEN",
    ["what does imanegg give"] = "STRAWBERRYELEPHANT",
    ["what does johnporkdapiggy give"] = "JOHNPORK",
    ["what does l2exploiters give"] = "JOHNPORK",
    ["what does maymeowljandel give"] = "MEOWL",
    ["what does needthis4craft333 give"] = "CHICLETEIRASURFEITEIRA",
    ["what does octoblock555 give"] = "OCTOLUCKYBLOCK",
    ["what does pizzaisyum give"] = "PIZZAANDRANCH",
    ["what does rebirth 19 give"] = "28THBASESLOT",
    ["what does rebirth do"] = "MULTIPLIESINCOMEANDSLOTSANDSTARTINGCASH",
    ["what does waverider4freelol give"] = "WAVERIDER",
    ["what games did sammy make before sab"] = "CRABGAMEMININGCLICKERSIMULATOR",
    ["what happens during admin abuse"] = "RAREBRAINROTSSPAWNLUCKYBLOCKWAVESTRAITSACTIVATE",
    ["what is a ritual"] = "SACRIFICESPECIFICBRAINROTTOGETTRAITFORALLBRAINROTS",
    ["what is base lock"] = "TIMERBEFOREOPPONENTSCANSTEALYOURBRAINROTS",
    ["what is brainrot meme origin"] = "ITALIANBRAINROTMEMES2025",
    ["what is egg city"] = "EXPLOREHOUSESCOLLECTGOLDENEGGSFORRAREBRAINROTS",
    ["what is la spooky grande"] = "SECRETBRAINROTFROMWITCHFUSEMERGE4SECRETHALLOWEENBRAINROTS",
    ["what is phoenix income"] = "425MPERSECBASE",
    ["what is rebirth"] = "RESETPROGRESSFORPERMANENTBONUSES",
    ["what is sammys favorite brainrot"] = "MEOWL",
    ["what is steak admin abuse"] = "STEAK",
    ["what is the best secret"] = "GOAT",
    ["what is the best trait"] = "STRAWBERRY",
    ["what is the cheapest brainrot"] = "NOOBINIPIZZANINI",
    ["what is the latest update"] = "UPDATE69HAUNTEDFUSEANDECLIPSE",
    ["what is the llm event"] = "JUMPBETWEEENISLANDSCOLLECTEGGSTRAINONTRAMPOLOLINES",
    ["what is the most expensive brainrot"] = "SPYDERELEPHANT",
    ["what is the red carpet"] = "SPAWNAREAFORBUYINGBRAINROTS",
    ["what is the trade plaza"] = "AREAWHEREYOUCANTRADEWITHOTHERPLAYERS",
    ["what is the worst trait"] = "SLEEPY",
    ["what machine replaced craft"] = "WITCHFUSE",
    ["what machine replaced fuse"] = "CRAFTMACHINE",
    ["what makes the most money"] = "ECLIPSEPHOENIXORMUTATEDOGBRAINROT",
    ["what mutations spawn on red carpet"] = "GOLDDIAMONDANDRAINBOW",
    ["what other games did sammy work on"] = "BLADEBALL",
    ["what secret has highest income"] = "GOAT950KPERSECOND",
    ["what studio made sab"] = "DOBIGSTUDIOS",
    ["what update added cyber craft"] = "47",
    ["what update added los traders"] = "57",
    ["what update added summer fuse"] = "52",
    ["what update is sab on"] = "UPDATE71",
    ["what was sammys first game"] = "MININGCLICKERSIMULATOR",
    ["when did sab hit 10b visits"] = "2026",
    ["when did sab peak"] = "OCTOBER2025",
    ["when did sab release"] = "2025",
    ["when did sammy start developing"] = "2013",
    ["when did trading become permanent"] = "JUNE132026UPDATE53",
    ["when is update 72"] = "OCTOBER242026",
    ["when was admin machine added"] = "NOVEMBER292025",
    ["when was admin war"] = "AUGUST232025",
    ["when was advent calendar added"] = "NOVEMBER292025",
    ["when was brainrot dealer added"] = "NOVEMBER82025",
    ["when was brainrot trader added"] = "NOVEMBER152025",
    ["when was bubblegum machine added"] = "JULY182025",
    ["when was bull trait added"] = "UPDATE59JULY252026",
    ["when was craft machine added"] = "SEPTEMBER62025",
    ["when was crystal mutation added"] = "JULY252026",
    ["when was cupids machine added"] = "FEBRUARY72026",
    ["when was cyber craft added"] = "APRIL182026",
    ["when was cyber mutation added"] = "APRIL2026",
    ["when was duels machine added"] = "JANUARY102026",
    ["when was egg incubator added"] = "APRIL42026",
    ["when was extinct event"] = "SEPTEMBER132025",
    ["when was fuse machine added"] = "AUGUST12025",
    ["when was john pork added"] = "MAY22026",
    ["when was los traders added"] = "JULY112026",
    ["when was new years machine added"] = "DECEMBER312025",
    ["when was peak ccu"] = "OCTOBER2025",
    ["when was phantom mutation added"] = "JUNE132026",
    ["when was rainbow machine added"] = "JUNE212025",
    ["when was sammy born"] = "FEBRUARY252002",
    ["when was santas fuse added"] = "DECEMBER62025",
    ["when was santas shop added"] = "CHRISTMAS2025",
    ["when was skull lucky block added"] = "UPDATE70",
    ["when was trade machine added"] = "FEBRUARY212026",
    ["when was tung tung reinstated"] = "NOVEMBER292025",
    ["when was witch fuse added"] = "OCTOBER112025",
    ["when were los traders added"] = "JULY112026",
    ["which lucky block drops celestial pegasus"] = "SECRETLUCKYBLOCK",
    ["which mutations spawn naturally"] = "GOLDDIAMONDANDRAINBOW",
    ["who co founded sab"] = "LUKENOOM",
    ["who cofounded brazilian spyder"] = "DOSMALL",
    ["who did sammy have admin war with"] = "JANDEL",
    ["who is sammys rival"] = "JANDEL",
    ["who owns do big studios"] = "SAMMY",
    ["who won admin war"] = "GROWAGARDEN",
    ["why was tung tung removed"] = "LICENSINGDISPUTEWITHNOXA",
    ["witch fuse date"] = "OCTOBER112025",
    ["witch fuse how many brainrots"] = "18RECIPES",
    ["witch fuse status"] = "REMOVEDHALLOWEENMACHINE",
    ["witching hour trait multiplier"] = "4X",
    ["wombo rollo income"] = "275",
    ["wombo rollo rarity"] = "EPIC",
    ["worst mutation"] = "SLEEPY",
    ["wsummerupd1"] = "PREMIUMOCTOLUCKYBLOCK",
    ["yess my examen cost"] = "130000000",
    ["yess my examen income"] = "575000PERSECOND",
    ["yin yang mutation multiplier"] = "7.5X",
    ["zibra zubra zibralini income"] = "6000",
    ["zibra zubra zibralini mythic lucky block chance"] = "30PERCENT",
    ["zibra zubra zibralini rarity"] = "MYTHIC",
    ["zombie bowl skull lucky block chance"] = "21PERCENT",
    ["zombie trait"] = "5X",
    ["zombie trait multiplier"] = "5X",
}

local SAB_MULTI = {
    ["what event did pot pumpkin come out in"] = { "HALLOWEEN", "HALLOWEENEVENT" },
    ["what craft did the la supreme come from"] = { "FIRSTFUSEMACHINE", "OGFUSEMACHINE" },
    ["where i was born"] = { "ALGERIA", "UNITEDSTATES" },
    ["what event is noo my candy from"] = { "HALLOWEEN", "HALLOWEENEVENT", "TRICKORTREAT" },
    ["noo my candy event"] = { "HALLOWEEN", "HALLOWEENEVENT", "TRICKORTREAT" },
    ["what event is plant bros from"] = { "HALLOWEEN", "HALLOWEENEVENT", "HAUNTEDFUSE" },
    ["what event is phoenix from"] = { "HALLOWEEN", "HALLOWEENEVENT", "HAUNTEDFUSE" },
    ["where does griffin come from"] = { "DIVINEFUSE", "DIVINE" },
    ["what machine gives phoenix"] = { "HAUNTEDFUSE", "HALLOWEENFUSE" },
    ["what machine gives plant bros"] = { "HAUNTEDFUSE", "HALLOWEENFUSE" },
    ["what day is admin abuse"] = { "TUESDAY", "SATURDAY", "TUESDAYANDSATURDAY" },
    ["admin abuse days"] = { "TUESDAY", "SATURDAY", "TUESDAYANDSATURDAY" },
    ["what is the best mutation"] = { "ECLIPSE", "CRYSTAL", "PHANTOM" },
    ["best og brainrot"] = { "SPYDERELEPHANT", "STRAWBERRYELEPHANT" },
    ["what replaced divine fuse"] = { "CYBERCRAFTMACHINE", "CYBER" },
    ["what event is headless horseman from"] = { "HALLOWEEN", "HALLOWEENEVENT", "WITCHFUSE" },
    ["how to get eclipse mutation"] = { "ECLIPSEEVENT", "ECLIPSESPINWHEEL" },
    ["how to get phoenix"] = { "HAUNTEDFUSE", "STEAL" },
    ["halloween machines"] = { "WITCHFUSE", "HAUNTEDFUSE" },
    ["christmas machines"] = { "SANTASFUSE", "SANTASSHOP", "ADVENTCALENDAR" },
    ["who hosts admin abuse"] = { "STEAK", "SAMMY", "CAYLUS" },

    -- Lucky block multi-answer
    ["permanent lucky blocks"] = { "MYTHICLUCKYBLOCK", "BRAINROTGODLUCKYBLOCK", "SECRETLUCKYBLOCK" },
    ["seasonal lucky blocks"] = { "SPOOKY", "FESTIVE", "HEART", "LEPRECHAUN", "EGG", "OCTO", "BEE", "SKULL" },
    ["admin lucky blocks"] = { "ADMINLUCKYBLOCK", "LOSLUCKYBLOCKS", "TACOLUCKYBLOCK", "LOSTACOBLOCKS" },
    ["what are the event lucky blocks"] = { "SPOOKY", "FESTIVE", "HEART", "LEPRECHAUN", "EGG", "OCTO", "BEE", "SKULL" },
    ["what lucky blocks are permanent"] = { "MYTHICLUCKYBLOCK", "BRAINROTGODLUCKYBLOCK", "SECRETLUCKYBLOCK" },

    -- Event machines multi-answer
    ["all event machines"] = { "WITCHFUSE", "HAUNTEDFUSE", "SANTASFUSE", "CUPIDSMACHINE", "DIVINEFUSE", "CYBERCRAFTMACHINE", "SUMMERFUSE", "RNGMACHINE" },
    ["event machines"] = { "WITCHFUSE", "HAUNTEDFUSE", "SANTASFUSE", "CUPIDSMACHINE", "DIVINEFUSE", "CYBERCRAFTMACHINE", "SUMMERFUSE", "RNGMACHINE" },
    ["all fuse machines"] = { "FUSEMACHINE", "WITCHFUSE", "HAUNTEDFUSE", "SANTASFUSE", "DIVINEFUSE", "SUMMERFUSE" },
    ["halloween event machines"] = { "WITCHFUSE", "HAUNTEDFUSE" },

    -- Mutations multi-answer
    ["top 3 mutations"] = { "ECLIPSE", "CRYSTAL", "PHANTOM" },
    ["most expensive mutations"] = { "ECLIPSE", "CRYSTAL", "PHANTOM" },
    ["fire mutations"] = { "LAVA", "BLOODROT" },
    ["dark mutations"] = { "PHANTOM", "CURSED", "VOID" },
    ["what mutations have events"] = { "BLOODROT", "LAVA", "GALAXY", "ECLIPSE" },

    -- Brainrot source multi-answer
    ["where does festive 67 come from"] = { "SANTASFUSE", "CHRISTMAS" },
    ["where does headless horseman come from"] = { "WITCHFUSE", "HALLOWEEN" },
    ["where does plant bros come from"] = { "HAUNTEDFUSE", "HALLOWEEN" },
    ["where does phoenix come from"] = { "HAUNTEDFUSE", "HALLOWEEN" },
    ["where does rosey and teddy come from"] = { "CUPIDSMACHINE", "VALENTINE" },
    ["where does griffin come from"] = { "DIVINEFUSE", "DIVINE" },
    ["where does dragon aquanini come from"] = { "SUMMERFUSE", "SUMMER" },
    ["where does rocketini frostini come from"] = { "RNGMACHINE", "RNG" },

    -- Creator multi-answer
    ["sammy socials"] = { "SPYDERSAMMY333", "SPYDERSAMMY" },
    ["sammy social media"] = { "INSTAGRAM", "TWITTER", "TIKTOK", "YOUTUBE" },
    ["where to find sammy"] = { "INSTAGRAM", "TWITTER", "TIKTOK", "YOUTUBE", "ROBLOX" },
    ["sammy heritage"] = { "ALGERIA", "NORTHAFRICAN", "UNITEDSTATES" },

    -- Game mechanics multi-answer
    ["what gives secret brainrots"] = { "SECRETLUCKYBLOCK", "SECRETEGG", "CRAFTING" },
    ["ways to get brainrots"] = { "STEAL", "LUCKYBLOCK", "CRAFTING", "FUSE", "EVENTS" },
    ["how to get brainrots"] = { "STEAL", "LUCKYBLOCK", "CRAFTING", "FUSE", "EVENTS" },
    ["what can you do in sab"] = { "STEAL", "FUSE", "TRADE", "LUCKYBLOCKS", "REBIRTH" },
    ["what currencies are in sab"] = { "CASH", "HONEY", "CANDY" },
    ["sab currencies"] = { "CASH", "HONEY", "CANDY" },

    -- Top brainrots multi-answer
    ["best brainrots in the game"] = { "ECLIPSEPHOENIX", "PHOENIX", "STRAWBERRYELEPHANT", "GRIFFINDRAGONINI" },
    ["most valuable brainrots"] = { "STRAWBERRYELEPHANT", "ECLIPSEPHOENIX", "PHOENIX" },
    ["rarest brainrots"] = { "STRAWBERRYELEPHANT", "NOOMYCANDY", "ECLIPSEPHOENIX" },
    ["highest income brainrots"] = { "ECLIPSEPHOENIX", "PHOENIX", "GRIFFINDRAGONINI" },

    -- OG brainrots multi-answer
    ["all og brainrots"] = { "SKIBIDITOILET", "JOHNPORK", "HEADLESSHORSEMAN", "MEOWL", "STRAWBERRYELEPHANT", "SPYDERELEPHANT" },
    ["og brainrots"] = { "SKIBIDITOILET", "JOHNPORK", "HEADLESSHORSEMAN", "MEOWL", "STRAWBERRYELEPHANT", "SPYDERELEPHANT" },
    ["name all og brainrots"] = { "SKIBIDITOILET", "JOHNPORK", "HEADLESSHORSEMAN", "MEOWL", "STRAWBERRYELEPHANT", "SPYDERELEPHANT" },

    -- Skull Lucky Block multi-answer
    ["skull lucky block drops"] = { "CANDICORNI", "GRIMCHEESE", "ZOMBIEBOWL", "BANANITOSKELITO", "BATINTHEBOX", "BOOBOOROCKET", "FLYINGDUTCHMAN", "DRAGONSKELETONINI" },
    ["all skull lucky block brainrots"] = { "CANDICORNI", "GRIMCHEESE", "ZOMBIEBOWL", "BANANITOSKELITO", "BATINTHEBOX", "BOOBOOROCKET", "FLYINGDUTCHMAN", "DRAGONSKELETONINI" },

    -- Haunted Fuse multi-answer
    ["all haunted fuse brainrots"] = { "PENGUINOPUMPKINO", "FROSTINOVAMPIRO", "VAMPIRIBBITINI", "MUMMELOBANDELLO", "MORTARUGA", "LOSTREATERS", "FANGAROLUPINO", "ONIONIPANDA", "SAMMYNISPOOKYNI", "PLANTBROS", "PHOENIX" },
    ["haunted fuse drops"] = { "PENGUINOPUMPKINO", "FROSTINOVAMPIRO", "VAMPIRIBBITINI", "MUMMELOBANDELLO", "MORTARUGA", "LOSTREATERS", "FANGAROLUPINO", "ONIONIPANDA", "SAMMYNISPOOKYNI", "PLANTBROS", "PHOENIX" },

    -- RNG Machine multi-answer
    ["rng machine drops"] = { "PIPIWATERMELON", "LOSNOOBINIS", "TOILETTOFOCACCINO", "TICTICRIBBIT", "GATTATINONYANINO", "MATTEO", "ESPRESSOSIGNORA", "PAKRAHMATMATINA", "ORCALITAORCALA", "KARKERKARKURKUR", "CHACHECHI", "GELATINAVOLATINA", "ROCKETINIFROSTINI" },

    -- Trait types multi-answer
    ["og traits"] = { "STRAWBERRY", "MEOWL", "JOHNPORK", "SKIBIDI" },
    ["ritual traits"] = { "PAINT", ":3", "TIE", "SPIDER", "MATTEOHAT", "GALACTIC", "EXPLOSIVE", "SHARKFIN" },
    ["country traits"] = { "BRAZIL", "INDONESIA", "SOMBRERO" },
    ["admin abuse traits"] = { "GRANNY", "BURGER", "FIRE", "ROSE", "FIREWORKS", "NYAN", "LIGHTNING", "DISCO" },
    ["seasonal traits"] = { "RAINBOWBALLOON", "PINKEGG", "1YEAR", "REINDEERPET", "26", "HALO", "LUCKY", "CHOCOLATE", "JACKOLANTERN", "BUNNYEARS", "SANTAHAT", "SKELETON", "10B" },
    ["what are the og traits"] = { "STRAWBERRY", "MEOWL", "JOHNPORK", "SKIBIDI" },
    ["what are the ritual traits"] = { "PAINT", ":3", "TIE", "SPIDER", "MATTEOHAT", "GALACTIC", "EXPLOSIVE", "SHARKFIN" },

    -- Platforms multi-answer
    ["what platforms is sab on"] = { "WINDOWS", "MACOS", "ANDROID", "IOS", "PS4", "PS5", "XBOXONE" },
    ["sab platforms"] = { "WINDOWS", "MACOS", "ANDROID", "IOS", "PS4", "PS5", "XBOXONE" },

    -- Active codes multi-answer
    ["all active codes"] = { "BESTBRAINROTEVER", "SATURN" },
    ["current active codes"] = { "BESTBRAINROTEVER", "SATURN" },

    -- Secret Lucky Block complete drops
    ["secret lucky block drops"] = { "TORTUGINNIDRAGONFRUTINI", "POTHOTSPOT", "ESOKSEKOLAH", "SPAGHETTITUALETTI", "LASECRETCOMBINASION", "CELESTIALPEGASUS" },
    ["all secret lucky block drops"] = { "TORTUGINNIDRAGONFRUTINI", "POTHOTSPOT", "ESOKSEKOLAH", "SPAGHETTITUALETTI", "LASECRETCOMBINASION", "CELESTIALPEGASUS" },

    -- Admin Lucky Block drops
    ["admin lucky block drops"] = { "CARLOO", "ALESSIO", "LOSBOMBINITOS", "CRABBOLIMONETTA", "BLACKHOLEGOAT", "GUERRIRODIGITALE", "67", "LAGRANDECOMBINASION", "SAMMYINIFATTINI" },

    -- Taco Lucky Block drops
    ["taco lucky block drops"] = { "CHIHUANINITACONINI", "GATTITOTACOTO", "LOSTIPITACOS", "QUESADILLACROCODILA", "BURRITOBANDITO", "LOSNOOOMYHOTSPOTSITOS", "LAFOODCOMBINASION" },

    -- Los Lucky Blocks drops
    ["los lucky blocks drops"] = { "LOSBOMBINITOS", "LOSTUNGTUNGTUNGCITOS", "LOSORCALITOS", "LOSTIPITACOS", "LOSTORTUS", "LOSJOBCITOS", "LOSCOMBINASIONAS", "LOS67", "LOSSEKOLAHS" },

    -- Mythic Lucky Block drops
    ["mythic lucky block drops"] = { "SPIONIRO GOLUBIRO", "ZIBRAZUBRAZIBRALINI", "TIGRILINIWATERMELINI", "CARROTINIBRAININI", "BANANITOBANDITO" },

    -- Brainrot God Lucky Block drops
    ["brainrot god lucky block drops"] = { "TIGROLIGREFRUTONNI", "ORCALEROORCALA", "BULBITOBANDITOTRAKTORITO", "MASTODONTICOTELEPIEDONE", "POPPOPSAHUR" },
}

-- local exact match resolver
local function localExactAnswer(text)
    if not text or text == "" then return nil end
    local l = text:lower()
    local clean = l
    clean = clean:gsub("what%s+is", ""):gsub("what%s+are", ""):gsub("what%s+was", ""):gsub("what%s+were", "")
    clean = clean:gsub("who%s+is", ""):gsub("who%s+was", ""):gsub("when%s+is", ""):gsub("when%s+was", "")
    clean = clean:gsub("where%s+is", ""):gsub("where%s+are", ""):gsub("how%s+old", ""):gsub("how%s+tall", "")
    clean = clean:gsub("how%s+many", ""):gsub("how%s+much", ""):gsub("do%s+you%s+know", ""):gsub("can%s+you%s+tell", "")
    clean = clean:gsub("tell%s+me", ""):gsub("i%s+need", ""):gsub("give%s+me", ""):gsub("what's", ""):gsub("whats", "")
    clean = clean:gsub("am%s+i", ""):gsub("do%s+i", ""):gsub("did%s+i", ""):gsub("have%s+i", "")
    clean = clean:gsub("^my%s+", ""):gsub("%s+my%s+", " "):gsub("^sammy[s]?%s+", ""):gsub("^sammys%s+", "")
    clean = clean:gsub("the%s+", ""):gsub("%f[%a]a%f[%A]", ""):gsub("%f[%a]an%f[%A]", ""):gsub("of%s+", ""):gsub("for%s+", "")
    clean = clean:gsub("[%?%.%,!]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    clean = clean:gsub("%d+", ""):gsub("%s+", " ")
    clean = trim(clean)
    local raw = trim(l:gsub("['\"']", ""):gsub("[%?%.%,!]", ""):gsub("%s+", " "))

    if SAB_MULTI[clean] then return SAB_MULTI[clean][1] end
    if SAB_MULTI[raw] then return SAB_MULTI[raw][1] end
    if SAB_DB[clean] then return SAB_DB[clean] end
    if SAB_DB[raw] then return SAB_DB[raw] end

    local ordinals = {one=1,two=2,three=3,four=4,five=5,six=6,seven=7,eight=8,nine=9,ten=10,
        eleven=11,twelve=12,thirteen=13,fourteen=14,fifteen=15,sixteen=16,seventeen=17,eighteen=18,
        nineteen=19,twenty=20,twentyone=21,twentytwo=22}
    local numwords = {first=1,second=2,third=3,fourth=4,fifth=5,sixth=6,seventh=7,eighth=8,ninth=9,tenth=10,
        eleventh=11,twelfth=12,thirteenth=13,fourteenth=14,fifteenth=15,sixteenth=16,seventeenth=17,eighteenth=18,
        nineteenth=19,twentieth=20}
    local suffixes = {[1]="1st",[2]="2nd",[3]="3rd"}

    local function ord(n)
        return suffixes[n] or (n.."th")
    end

    local conv = clean
    for word, n in pairs(numwords) do
        conv = conv:gsub("%f[%a]"..word.."%f[%A]", ord(n))
    end
    for word, n in pairs(ordinals) do
        conv = conv:gsub("%f[%a]"..word.."%f[%A]", tostring(n))
    end

    if conv ~= clean and SAB_DB[conv] then return SAB_DB[conv] end

    local kind, num2 = conv:match("^(.-)%s+(%d+)$")
    if kind and num2 then
        local alt = ord(tonumber(num2)).." "..trim(kind)
        if SAB_DB[alt] then return SAB_DB[alt] end
    end

    local num3, kind2 = conv:match("^(%d+)%s+(.-)$")
    if num3 and kind2 then
        local alt = ord(tonumber(num3)).." "..trim(kind2)
        if SAB_DB[alt] then return SAB_DB[alt] end
    end

    return nil
end

local function localExactAnswers(text)
    if not text or text == "" then return nil end
    local l = text:lower()
    local clean = l
    clean = clean:gsub("what%s+is", ""):gsub("what%s+are", ""):gsub("what%s+was", ""):gsub("what%s+were", "")
    clean = clean:gsub("who%s+is", ""):gsub("who%s+was", ""):gsub("when%s+is", ""):gsub("when%s+was", "")
    clean = clean:gsub("where%s+is", ""):gsub("where%s+are", ""):gsub("how%s+old", ""):gsub("how%s+tall", "")
    clean = clean:gsub("how%s+many", ""):gsub("how%s+much", ""):gsub("do%s+you%s+know", ""):gsub("can%s+you%s+tell", "")
    clean = clean:gsub("tell%s+me", ""):gsub("i%s+need", ""):gsub("give%s+me", ""):gsub("what's", ""):gsub("whats", "")
    clean = clean:gsub("am%s+i", ""):gsub("do%s+i", ""):gsub("did%s+i", ""):gsub("have%s+i", "")
    clean = clean:gsub("^my%s+", ""):gsub("%s+my%s+", " "):gsub("^sammy[s]?%s+", ""):gsub("^sammys%s+", "")
    clean = clean:gsub("the%s+", ""):gsub("%f[%a]a%f[%A]", ""):gsub("%f[%a]an%f[%A]", ""):gsub("of%s+", ""):gsub("for%s+", "")
    clean = clean:gsub("[%?%.%,!]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    clean = clean:gsub("%d+", ""):gsub("%s+", " ")
    clean = trim(clean)
    local raw = trim(l:gsub("['\"']", ""):gsub("[%?%.%,!]", ""):gsub("%s+", " "))

    local multi = SAB_MULTI[clean] or SAB_MULTI[raw]
    if multi then
        local out = {}
        for _, v in ipairs(multi) do
            out[#out + 1] = v
        end
        return out
    end

    local single = localExactAnswer(text)
    if single then return { single } end
    return nil
end

-- Groq AI fallback
local GROQ_API_KEY = (env and env.GROQ_API_KEY) or "AQ.Ab8RN6IBkoyj5cUpARxa9x8oD0Q9kdbJNOgpTdQDwaoul_ajqQ"

local AI_SYSTEM = table.concat({
    "You are a riddle-answering bot for the Roblox game STEAL A BRAINROT (SAB).",
    "",
    "=== CRITICAL OUTPUT RULES ===",
    "1. Reply with ONE single word in ALL CAPS. NOTHING else.",
    "2. NEVER include spaces. Write HEADLESSHORSEMAN not HEADLESS HORSEMAN.",
    "3. NEVER repeat the answer. Return the base answer exactly once.",
    "4. NEVER spell out numbers as words. Write digits: 24, 2025.",
    "5. No explanation, just the single answer word.",
    "",
    "=== CONTEXT ===",
    "All personal questions refer to SAMMY (SpyderSammy). No exceptions.",
    "Current season: HALLOWEEN | Current event: ECLIPSE (Update 69, Oct 2026)",
    "",
    "=== OWNER ===",
    "Real name: SAMMY | Full real name: SAMBRAKTA | Roblox: SPYDERSAMMY",
    "Age: 24 | Birth year: 2002 | Born day: FRIDAY | Birth month: FEBRUARY",
    "Country: BRAZIL | Born in: ALGERIA | State+City: SAOPAULO | Nationality: BRAZILIAN",
    "Favorite color: BLUE | Favorite sport: FOOTBALL | Favorite food: PIZZA",
    "Favorite player: RONALDO | Favorite animal: SPIDER | Favorite brainrot: MEOWL",
    "YouTube/Twitter/TikTok/Instagram: SPYDERSAMMY",
    "Favorite number: SEVEN | Cat name: NOVA | Car color: RED",
    "First game: CRABGAME | Fortnite game: ROBABANK | Started making games: 2013",
    "On chain: SPIDER | On left eye: SPIDER | Short for: SAM",
    "Best food duo: PIZZAANDRANCH | Best OG: SPYDERELEPHANT",
    "",
    "=== GAME ===",
    "Full name: STEALABRAINROT | Genre: SIMULATOR | Group: BRAZILIANSPYDER",
    "Release: MAY 16 2025 | Day: FRIDAY | Year: 2025",
    "Max server size: EIGHT | Total rebirths: 19",
    "First trait: LIGHTNING | Lightning strike trait: MATEO",
    "Lead programmer: HASTED | Discord: BLOSSOM",
    "Total mutations: 15 (FIFTEEN) | Total machines: 20 (TWENTY) | Total rarities: SIX",
    "Active code: BESTBRAINROTEVER (gives LAVACCASATURNOSATURNITA)",
    "",
    "=== RARITIES ===",
    "COMMON < UNCOMMON < RARE < EPIC < LEGENDARY < MYTHIC < BRAINROTGOD < SECRET < OG",
    "Rarest brainrot: POLAROIDINI (24 exist) | HEADLESSHORSEMAN (79 exist, unobtainable)",
    "Most popular: SKIBIDITOILET | Worst secret: KARKERKARKURKUR",
    "",
    "=== OG BRAINROTS ===",
    "1st: STRAWBERRYELEPHANT | 2nd: MEOWL | 3rd: SKIBIDITOILET | 5th: JOHNPORK",
    "",
    "=== MUTATIONS (15 total) ===",
    "1=GOLD(1.25x) 2=DIAMOND(1.5x) 3=BLOODROT(2x) 4=RAINBOW(10x) 5=CANDY(4x)",
    "6=LAVA(6x) 7=GALAXY(7x) 8=YINYANG(7.5x) 9=RADIOACTIVE(8.5x) 10=CURSED(9x)",
    "11=DIVINE(10x) 12=CYBER(11x) 13=PHANTOM(12x) 14=CRYSTAL(13x) 15=ECLIPSE(14x)",
    "Evil: CURSED | Angelic: DIVINE | Best/Newest: ECLIPSE (14x, Update 69, Halloween)",
    "Scrapped mutation: DISCO (replaced by CYBER)",
    "",
    "=== MACHINES (20 total) ===",
    "1=RAINBOWMACHINE 2=BUBBLEGUMMACHINE 3=FUSEMACHINE 4=CRAFTMACHINE",
    "5=WITCHFUSE 6=BRAINROTDEALER 7=BRAINROTTRADER 8=SANTASFUSE",
    "9=SANTASSHOP 10=NEWYEARSMACHINE 11=DUELSMACHINE 12=CUPIDSMACHINE",
    "13=TRADEMACHINE 14=DIVINEFUSE 15=EGGINCUBATOR 16=CYBERCRAFTMACHINE",
    "17=SUMMERFUSE 18=LOSTRADERS 19=RNGMACHINE 20=HAUNTEDFUSE",
    "DIVINEFUSE was replaced by CYBERCRAFTMACHINE (Update 47)",
    "HAUNTEDFUSE: Halloween 2026, Update 69. Best drop: PLANTBROS ($300M/s)",
    "",
    "=== HAUNTED FUSE BRAINROTS ===",
    "PENGUINOPUMPKINO(Epic) FROSTINOVAMPIRO(Mythic) VAMPIRIBBITINI(BrainrotGod)",
    "MUMMELOBANDELLO(BrainrotGod) MORTARUGA(BrainrotGod) LOSTREATERS(Secret,$1.2M/s)",
    "FANGAROLUPINO(Secret,$7.2M/s) ONIONIPANDA(Secret,$27M/s)",
    "SAMMYNISPOOKYNI(Secret,$80M/s) PLANTBROS(Secret,$300M/s,recipe:ORCHIDOX+VENUSPINO)",
    "PHOENIX(Secret,$425M/s) from Haunted Fuse. ECLIPSE PHOENIX = $5.7B/s",
    "",
    "=== SKULL LUCKY BLOCK (Update 70, $500M) ===",
    "CANDICORNI(BrainrotGod,32.4%) GRIMCHEESE(Secret,30%) ZOMBIEBOWL(Secret,21%)",
    "BANANITOSKELITO(Secret,10%) BATINTHEBOX(Secret,5%) BOOBOOROCKET(Secret,1%)",
    "FLYINGDUTCHMAN(Secret,0.5%) DRAGONSKELETONINI(Secret,0.1%,$325M/s)",
    "",
    "=== TRAITS ===",
    "OG: STRAWBERRY(8x) MEOWL(7x) JOHNPORK(6.5x) SKIBIDI(6x)",
    "Ritual: PAINT(5x) :3(4.5x) TIE(3.75x) SPIDER(3.5x) MATTEOHAT(3.5x)",
    "Admin: FIRE(5x) ROSE(5x) FIREWORKS(5x) NYAN(5x) LIGHTNING(5x) DISCO(4x)",
    "Country: BRAZIL(5x) INDONESIA(4x) SOMBRERO(4x)",
    "Seasonal: RAINBOWBALLOON(6.5x) PINKEGG(6.5x) 1YEAR(5.5x) GRANNY(5.5x)",
    "Negative: SLEEPY(0.5x, halves income)",
    "",
    "=== ADMIN ABUSE ===",
    "Schedule: TUESDAYS 6PM ET (Taco Tuesday) | SATURDAYS 3PM ET",
    "Duration: 30-45 minutes | Hosts: STEAK, SAMMY, CAYLUS",
    "Admin War: AUG 23, 2025 | JANDEL vs SPYDERSAMMY | GROWAGARDEN won",
    "War spawn: RACOONINIJANDELINI | Worst owner: SECRETLOKII",
    "Boring game: KEYBOARDESCAPE | Steak age: 25 | Steak brother: CRUZ",
    "Cruz hates: CHEESE | Most aura: CAYLUS | Best trait farmer: RUSTYNICKLE40",
    "",
    "=== EVENT MACHINE OUTPUTS ===",
    "Witch Fuse (Halloween 2025): HEADLESSHORSEMAN(best), EVILEDON, JACKOJACKJACK, NOOMYCANDY",
    "Santa's Fuse (Christmas 2025): FESTIVE67(best/secret), COOKIANDMILKI, SANTTEO, YETICLAUS",
    "Cupid's Machine (Valentine 2026): ROSEYANDTEDDY(best,0.05%), MARIACHICORAZONI, SERAFINNAMEDUSELLA",
    "Divine Fuse (Mar 2026): GRIFFIN(best/secret), HOLYAREPA, CIGNOFULGORO, LOSCUPIDS",
    "Cyber Craft (Apr 2026,Update 47): BUHODEVOLTO, GYMBROS, CAMERARAMENA, DIGINARWHAL",
    "Summer Fuse (May 2026,Update 52): DRAGONAQUANINI(best,$375M/s), KRAKEN($200M/s from Octo LB)",
    "RNG Machine (Aug 2026): 40 brainrots, best=ROCKETINIFROSTINI($3M/s)",
    "Haunted Fuse (Oct 2026,Update 69): PLANTBROS(best,$300M/s), PHOENIX($425M/s)",
    "",
    "=== MISC ===",
    "NOOMYCANDY: Secret,$5M/s, Halloween Trick or Treat doorbell 1% chance",
    "HEADLESSHORSEMAN: 79 exist, from WITCHFUSE Halloween 2025, unobtainable OG",
    "BESTBRAINROTEVER code spawns LAVACCASATURNOSATURNITA on red carpet for $80M",
    "Total traits: 22 | Admin war: Galaxy mutations spawned on Red Carpet",
    "Jandel owns GROWAGARDEN | RACOONIJANDELINI spawned during admin war",
}, "\n")

local function queryAI(question)
    if not httpRequest then return nil, "no http executor" end
    if not GROQ_API_KEY or GROQ_API_KEY == "" then return nil, "GROQ_API_KEY empty" end

    local body = HttpService:JSONEncode({
        model = "llama-3.3-70b-versatile",
        messages = {
            { role = "system", content = AI_SYSTEM },
            { role = "user", content = "/no_think\n" .. tostring(question) .. "\n\nRules: ONE word, ALL CAPS, NO spaces, NO repetition, NO spelling out numbers. Just the answer." },
        },
        temperature = 0,
        max_tokens = 64,
    })

    local ok, res = pcall(httpRequest, {
        Url = "https://api.groq.com/openai/v1/chat/completions",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. GROQ_API_KEY
        },
        Body = body,
    })

    if not ok then return nil, "http: " .. tostring(res):sub(1, 100) end
    if not res or not res.Body then return nil, "empty body" end
    local sc = tonumber(res.StatusCode)
    if sc and sc ~= 200 then return nil, "HTTP " .. tostring(sc) end

    local pOk, parsed = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not pOk or not parsed then return nil, "json fail" end
    if parsed.error then return nil, "API: " .. tostring(parsed.error.message):sub(1, 100) end

    local choice = parsed.choices and parsed.choices[1]
    if not choice then return nil, "no choices" end

    local answer = trim((choice.message and choice.message.content) or "")
    answer = answer:upper():gsub("[%s%?%.%,!\"'`\n\r]+", "")

    if answer == "" then return nil, "empty answer" end
    if answer:find(":") then
        answer = answer:match(":([^:]+)$") or answer
    end
    return answer
end

-- solver helpers
local function extractTimesMultiplier(text)
    local l = text:lower()
    if l:find("twice") then return 2 end
    if l:find("thrice") then return 3 end
    local n = l:match("(%d+)%s*times")
    if n then
        n = tonumber(n)
        if n and n >= 2 and n <= 10 then return n end
    end
    return nil
end

local function stripMultiplierText(text)
    local s = text
    s = s:gsub("%s*%d+%s*[Tt]imes%s*", " ")
    s = s:gsub("%s*[Tt]wice%s*", " ")
    s = s:gsub("%s*[Tt]hrice%s*", " ")
    s = trim(s)
    if s == "" then s = text end
    return s
end

local function stripTrailingNumber(text)
    return trim(text:gsub("%s+%d+%s*$", ""))
end

local function splitAllParts(text)
    local clean = text or ""
    clean = clean:gsub("%s+add%s+", " and ")
    clean = clean:gsub("%s*,%s*", " and ")
    clean = clean:gsub("%s+at%s+the%s+end", " ")
    clean = clean:gsub("%s+at%s+the%s+start", " ")

    local parts = {}
    for part in (clean .. " and "):gmatch("(.-)%s+and%s+") do
        part = trim(part)
        if part ~= "" then
            parts[#parts + 1] = part
        end
    end
    if #parts == 0 then
        parts[1] = trim(text or "")
    end
    return parts
end

-- main solver
local solveRiddle
local solveRiddleMulti

do
    local function resolvePart(part, cb)
        local multiplier = extractTimesMultiplier(part)
        local q = stripMultiplierText(part)
        q = stripTrailingNumber(q)
        q = q:gsub("%s+at%s+the%s+end%s*$", ""):gsub("%s+at%s+the%s+start%s*$", "")
        q = trim(q)

        if q == "" then return nil end

        local onlyNum = q:match("^%d+$")
        if onlyNum then
            return multiplier and string.rep(onlyNum, multiplier) or onlyNum
        end

        local a = localExactAnswer(q)
        if not a then
            if cb then cb("AI: " .. q:sub(1, 40)) end
            local aiAns, aiErr = queryAI(q)
            a = aiAns
            if not a and cb then cb("AI fail: " .. tostring(aiErr)) end
        end

        if not a then return nil end

        local clean = tostring(a):upper():gsub("%s+", ""):gsub("[%?%.%,!\"'`]", "")
        if clean:find("ATTHEEND") or clean:find("ATTHESTART") or clean == "AND" then return nil end
        if clean == "" then return nil end

        return multiplier and string.rep(clean, multiplier) or clean
    end

    solveRiddle = function(text, cb)
        local suffix = text:match("%s*(%d+)%s*$") or text:match("%s*(%d+)[%.,;!?]%s*$")
        local parts = splitAllParts(text)
        local answers = {}

        for _, part in ipairs(parts) do
            local ok, result = pcall(resolvePart, part, cb)
            if ok and result and result ~= "" then
                answers[#answers + 1] = result
            end
        end

        if #answers == 0 then
            if cb then cb("AI full question") end
            local a = select(1, queryAI(stripTrailingNumber(text)))
            if a then
                local clean = tostring(a):upper():gsub("%s+", ""):gsub("[%?%.%,!\"'`]", "")
                clean = clean:gsub("ATTHEEND", ""):gsub("ATTHESTART", "")
                if suffix and clean:sub(-#suffix) ~= suffix then
                    clean = clean .. suffix
                end
                return clean
            end
            return nil, "no answer"
        end

        local out = table.concat(answers, "")
        if suffix and out:sub(-#suffix) ~= suffix then
            out = out .. suffix
        end
        return out
    end

    local function resolvePartMulti(part, cb)
        local multiplier = extractTimesMultiplier(part)
        local q = stripMultiplierText(part)
        q = stripTrailingNumber(q)
        q = q:gsub("%s+at%s+the%s+end%s*$", ""):gsub("%s+at%s+the%s+start%s*$", "")
        q = trim(q)

        if q == "" then return nil end

        local onlyNum = q:match("^%d+$")
        if onlyNum then
            local v = multiplier and string.rep(onlyNum, multiplier) or onlyNum
            return { v }
        end

        local candidates = localExactAnswers(q)
        if candidates then
            local out = {}
            for _, a in ipairs(candidates) do
                local clean = tostring(a):upper():gsub("%s+", ""):gsub("[%?%.%,!\"'`]", "")
                if clean ~= "" and not clean:find("ATTHEEND") and not clean:find("ATTHESTART") and clean ~= "AND" then
                    out[#out + 1] = multiplier and string.rep(clean, multiplier) or clean
                end
            end
            if #out > 0 then return out end
        end

        if cb then cb("AI: " .. q:sub(1, 40)) end
        local a = select(1, queryAI(q))
        if not a then return nil end

        local clean = tostring(a):upper():gsub("%s+", ""):gsub("[%?%.%,!\"'`]", "")
        if clean == "" or clean:find("ATTHEEND") or clean:find("ATTHESTART") then return nil end

        return { multiplier and string.rep(clean, multiplier) or clean }
    end

    solveRiddleMulti = function(text, cb)
        local suffix = text:match("%s*(%d+)%s*$") or text:match("%s*(%d+)[%.,;!?]%s*$")
        local parts = splitAllParts(text)

        local partLists = {}
        for _, part in ipairs(parts) do
            local ok, result = pcall(resolvePartMulti, part, cb)
            if ok and result and #result > 0 then
                partLists[#partLists + 1] = result
            end
        end

        if #partLists == 0 then
            if cb then cb("AI full question") end
            local a = select(1, queryAI(stripTrailingNumber(text)))
            if a then
                local clean = tostring(a):upper():gsub("%s+", ""):gsub("[%?%.%,!\"'`]", "")
                clean = clean:gsub("ATTHEEND", ""):gsub("ATTHESTART", "")
                if suffix and clean:sub(-#suffix) ~= suffix then
                    clean = clean .. suffix
                end
                return { clean }
            end
            return nil, "no answer"
        end

        local combos = { "" }
        for _, list in ipairs(partLists) do
            local newCombos = {}
            for _, prefix in ipairs(combos) do
                for _, ans in ipairs(list) do
                    newCombos[#newCombos + 1] = prefix .. ans
                end
            end
            combos = newCombos
            if #combos > 12 then
                local trimmed2 = {}
                for i = 1, 12 do
                    trimmed2[i] = combos[i]
                end
                combos = trimmed2
            end
        end

        local seen = {}
        local out = {}
        for _, c in ipairs(combos) do
            if suffix and c:sub(-#suffix) ~= suffix then
                c = c .. suffix
            end
            if not seen[c] then
                seen[c] = true
                out[#out + 1] = c
            end
        end
        return out
    end
end

-- notify remote resolver (finds the game announcement remote)
local function resolveNotifyRemote()
    local RS = game:GetService("ReplicatedStorage")

    if _G.PhiNotifyRemote and typeof(_G.PhiNotifyRemote) == "Instance" then
        return _G.PhiNotifyRemote
    end
    if env and env.RiddlerNotifyRemote and typeof(env.RiddlerNotifyRemote) == "Instance" then
        return env.RiddlerNotifyRemote
    end

    local ok, controller = pcall(function()
        local controllers = RS:FindFirstChild("Controllers")
        local n = controllers and controllers:FindFirstChild("NotificationController", true)
        if n then return require(n) end
    end)

    if ok and type(controller) == "table" and type(controller.Start) == "function" and getupvalues then
        local vOk, values = pcall(getupvalues, controller.Start)
        if vOk and type(values) == "table" then
            for _, v in pairs(values) do
                if typeof(v) == "Instance" and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("UnreliableRemoteEvent")) then
                    return v
                end
            end
        end
    end

    local getconns = typeof(getconnections) == "function" and getconnections or typeof(getconns) == "function" and getconns or nil
    local pkg = RS:FindFirstChild("Packages")
    if pkg and getconns and debug then
        local getinfo = debug.getinfo or debug.info
        local containers = {}
        local netA = pkg:FindFirstChild("Net")
        if netA then table.insert(containers, netA) end
        local netB = pkg:FindFirstChild("Network")
        if netB then table.insert(containers, netB) end

        for _, net in ipairs(containers) do
            for _, d in ipairs(net:GetDescendants()) do
                if d:IsA("RemoteEvent") or d:IsA("UnreliableRemoteEvent") then
                    local cOk, cs = pcall(getconns, d.OnClientEvent)
                    if cOk and type(cs) == "table" then
                        for _, c in ipairs(cs) do
                            local f, fn = pcall(function() return c.Function end)
                            if f and type(fn) == "function" then
                                local i, info = pcall(getinfo, fn)
                                local src = i and tostring(info.short_src or info.source or "") or ""
                                if src:find("NotificationController", 1, true) then
                                    return d
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

-- riddler listener state
local _riddlerConns = {}
local _riddlerSolving = false
local _notifyRemoteRef = nil

local function riddlerGetCodeBox()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    local gui = pg:FindFirstChild("Codes")
    if not gui then return nil end
    local root = gui:FindFirstChild("Codes") or gui
    local redeem = root:FindFirstChild("CodeRedeem")
    local box = redeem and redeem:FindFirstChild("TextBox")
    if box and box:IsA("TextBox") then return box end
    -- fallback: search all descendants
    for _, item in ipairs(gui:GetDescendants()) do
        if item:IsA("TextBox") then return item end
    end
    return nil
end

local function riddlerFireConns(signal, ...)
    local gc = typeof(getconnections) == "function" and getconnections or typeof(getconns) == "function" and getconns or nil
    if not gc then return false end
    local ok2, cs = pcall(gc, signal)
    if not ok2 or type(cs) ~= "table" then return false end
    local args = table.pack(...)
    local fired = false
    for _, c in ipairs(cs) do
        local ok3 = pcall(function()
            if c.Enabled ~= false then
                if args.n > 0 then
                    c:Fire(table.unpack(args, 1, args.n))
                else
                    c:Fire(true)
                end
            end
        end)
        fired = fired or ok3
    end
    return fired
end

local function riddlerSubmitAnswer(answer)
    answer = tostring(answer or ""):upper():gsub("%s+", "")
    if answer == "" then return false, "empty" end

    local box = riddlerGetCodeBox()
    if not box then
        -- try opening the Codes GUI first
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            local gui = pg:FindFirstChild("Codes")
            if gui and gui:IsA("ScreenGui") then gui.Enabled = true end
            if gui then
                local codesFrame = gui:FindFirstChild("Codes") or gui
                if codesFrame and codesFrame:IsA("GuiObject") then codesFrame.Visible = true end
                local cur = codesFrame
                while cur and cur ~= gui do
                    if cur:IsA("GuiObject") then cur.Visible = true end
                    cur = cur.Parent
                end
            end
        end
        task.wait(0.15)
        box = riddlerGetCodeBox()
    end

    if not box then
        pushLog("> riddler: no code box found", Color3.fromRGB(255, 90, 90))
        return false, "code box not found"
    end

    -- clear then set text with retries (Luna's approach)
    pcall(function() box.Text = "" end)
    task.wait(0.04)
    pcall(function() box.Text = answer end)
    for _ = 1, 8 do
        task.wait(0.04)
        local current = ""
        pcall(function() current = box.Text end)
        if current == answer then break end
        pcall(function() box.Text = answer end)
    end
    task.wait(0.08)

    pushLog("> riddler: typed " .. answer, COL_ON)

    local submitted = false

    -- method 1: fire FocusLost connections
    if riddlerFireConns(box.FocusLost, true) then
        submitted = true
    end
    task.wait(0.05)

    -- method 2: find and click submit/redeem button
    pcall(function()
        local parent = box.Parent
        if not parent then return end
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("TextButton") or child:IsA("ImageButton") then
                local t = ((child.Text or "") .. (child.Name or "")):lower()
                if t:find("redeem") or t:find("submit") or t:find("enter") or t:find("claim") then
                    clickButton(child)
                    submitted = true
                    return
                end
            end
        end
    end)
    task.wait(0.05)

    -- method 3: direct Fire on FocusLost
    if not submitted then
        pcall(function() box.FocusLost:Fire(true) end)
        if typeof(firesignal) == "function" then
            pcall(firesignal, box.FocusLost, true)
        end
        submitted = true
    end

    -- method 4: keypress Enter fallback
    if not submitted then
        pcall(function()
            if typeof(keypress) == "function" then
                keypress(0x0D)
                task.wait(0.04)
                if typeof(keyrelease) == "function" then
                    keyrelease(0x0D)
                end
                submitted = true
            end
        end)
        if not submitted then
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                if vim then
                    vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.04)
                    vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    submitted = true
                end
            end)
        end
    end

    pcall(function() box:ReleaseFocus(false) end)
    return true, submitted and "submitted" or "typed only"
end

local function onRiddleDetected(text)
    if not state.riddlerToggled or _riddlerSolving then return end
    local cleaned = stripRich(tostring(text or ""))
    cleaned = trim(cleaned)
    if cleaned == "" or #cleaned < 3 then return end

    pushLog("> riddle: " .. cleaned:sub(1, 50), Color3.fromRGB(200, 180, 100))
    pushLog("> solving...", COL_ON)

    _riddlerSolving = true
    task.spawn(function()
        local answers = solveRiddleMulti(cleaned, function(msg)
            pushLog("> " .. tostring(msg), Color3.fromRGB(140, 140, 150))
        end)

        if answers and #answers > 0 then
            local primary = answers[1]
            pushLog("> answer: " .. primary, COL_ON)

            if state.riddlerAutoRedeem then
                for i, ans in ipairs(answers) do
                    local ok2, msg2 = riddlerSubmitAnswer(ans)
                    if ok2 then
                        pushLog("> redeemed: " .. ans, COL_ON)
                    else
                        pushLog("> failed: " .. tostring(msg2), Color3.fromRGB(255, 90, 90))
                    end
                    if i < #answers then task.wait(0.7) end
                end
            end
        else
            pushLog("> no answer found", Color3.fromRGB(255, 90, 90))
        end
        _riddlerSolving = false
    end)
end

local POSITIONS_RIDDLER = {
    Top = true, Bottom = true, Center = true, Middle = true,
    Left = true, Right = true, TopRight = true, TopLeft = true,
    BottomRight = true, BottomLeft = true,
}

local function looksLikeAnnouncement(...)
    local args = table.pack(...)
    if args.n == 0 or typeof(args[1]) ~= "string" then return false end
    for i = 2, args.n do
        local v = args[i]
        if typeof(v) == "string" and (v:find("Sounds%.") or v:find("rbxassetid") or POSITIONS_RIDDLER[v]) then
            return true
        end
    end
    return false
end

local function startRiddler()
    -- resolve notification remote
    _notifyRemoteRef = resolveNotifyRemote()
    if env then env.RiddlerNotifyRemote = _notifyRemoteRef end

    if _notifyRemoteRef and (_notifyRemoteRef:IsA("RemoteEvent") or _notifyRemoteRef:IsA("UnreliableRemoteEvent")) then
        local conn = _notifyRemoteRef.OnClientEvent:Connect(function(...)
            if not state.riddlerToggled then return end
            local firstArg = tostring((...) or "")
            local raw = stripRich(firstArg)
            local lower = raw:lower()
            -- Accept if it looks like an announcement OR if the text itself looks like a riddle
            local isAnnounce = looksLikeAnnouncement(...)
            local isRiddle = lower:find("riddle", 1, true) or lower:find("?")
                or lower:find("what") or lower:find("who") or lower:find("where")
                or lower:find("how") or lower:find("when") or lower:find("name")
                or lower:find("favorite") or lower:find("colour") or lower:find("color")
            if (isAnnounce or isRiddle) and #raw > 5 then
                pcall(onRiddleDetected, firstArg)
            end
        end)
        table.insert(_riddlerConns, conn)
        pushLog("> riddler: notify mapped", COL_ON)
    else
        pushLog("> riddler: no notify remote", Color3.fromRGB(255, 90, 90))
    end

    -- also listen to chat for riddle-like messages
    pcall(function()
        local tcs = game:GetService("TextChatService")
        if tcs and tcs:FindFirstChild("TextChannels") then
            for _, channel in ipairs(tcs.TextChannels:GetChildren()) do
                if channel:IsA("TextChannel") then
                    local conn2 = channel.MessageReceived:Connect(function(msg)
                        if not state.riddlerToggled then return end
                        pcall(function()
                            local text = stripRich(msg.Text or "")
                            local lower = text:lower()
                            if lower:find("riddle", 1, true) or lower:find("?") then
                                onRiddleDetected(text)
                            end
                        end)
                    end)
                    table.insert(_riddlerConns, conn2)
                end
            end
        end
    end)

    -- watch screen announcements too (DescendantAdded)
    local conn3 = PlayerGui.DescendantAdded:Connect(function(obj)
        if not state.riddlerToggled then return end
        if obj:IsDescendantOf(screenGui) then return end
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
        task.wait(0.05)
        local text = nil
        pcall(function() text = obj.Text end)
        if text and text ~= "" and #text > 5 then
            local lower = text:lower()
            if lower:find("?") or lower:find("riddle") or lower:find("what")
                or lower:find("who") or lower:find("where") or lower:find("how")
                or lower:find("when") or lower:find("name") or lower:find("favorite") then
                onRiddleDetected(text)
            end
        end
    end)
    table.insert(_riddlerConns, conn3)
end

local function stopRiddler()
    for _, c in ipairs(_riddlerConns) do pcall(function() c:Disconnect() end) end
    _riddlerConns = {}
    _riddlerSolving = false
end

-- ======================== MAIN PAGE ========================
local pageMain = Instance.new("ScrollingFrame")
pageMain.Size = UDim2.new(1, 0, 1, 0)
pageMain.BackgroundTransparency = 1
pageMain.BorderSizePixel = 0
pageMain.ScrollBarThickness = 4
pageMain.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
pageMain.ScrollBarImageTransparency = 0.3
pageMain.CanvasSize = UDim2.new(0, 0, 0, 0)
pageMain.AutomaticCanvasSize = Enum.AutomaticSize.Y
pageMain.ScrollingDirection = Enum.ScrollingDirection.Y
pageMain.ZIndex = 2
pageMain.Parent = content
pages["Main"] = pageMain

local mainLayout = Instance.new("UIListLayout")
mainLayout.Padding = UDim.new(0, 10)
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Parent = pageMain

local mainPad = Instance.new("UIPadding")
mainPad.PaddingBottom = UDim.new(0, 12)
mainPad.PaddingRight = UDim.new(0, 4)
mainPad.Parent = pageMain

local function makeMainRow(order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 40)
    row.BackgroundColor3 = Theme.bgCard
    row.BackgroundTransparency = 0.15
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 3
    row.Parent = pageMain
    corner(row, 10)
    stroke(row, Theme.stroke, 1)
    return row
end

local function makeToggle(parent, order, labelText, default, onToggle)
    local row = makeMainRow(order)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = Theme.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.ZIndex = 4
    label.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 42, 0, 22)
    track.Position = UDim2.new(1, -56, 0.5, -11)
    track.BackgroundColor3 = default and Theme.toggleOn or Theme.toggleOff
    track.ZIndex = 4
    track.Parent = row
    corner(track, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = default and UDim2.new(0, 23, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Theme.white
    knob.ZIndex = 5
    knob.Parent = track
    corner(knob, 8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 5
    btn.Parent = row

    local toggled = default or false

    btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            TweenService:Create(track, TweenFast, { BackgroundColor3 = Theme.toggleOn }):Play()
            TweenService:Create(knob, TweenFast, { Position = UDim2.new(0, 23, 0.5, -8) }):Play()
        else
            TweenService:Create(track, TweenFast, { BackgroundColor3 = Theme.toggleOff }):Play()
            TweenService:Create(knob, TweenFast, { Position = UDim2.new(0, 3, 0.5, -8) }):Play()
        end
        onToggle(toggled)
    end)

    return row
end

-- ======================== PHANTOM CODE REDEEMER ========================
-- SAB shows code sections on screen via announcements.
-- We use the existing appendToBox() to accumulate and submit.
-- Detection: notification remote (filtered) + screen TextLabels.

local _sniperConns = {}

local function sniperStrip(s)
    if type(s) ~= "string" then return tostring(s or "") end
    s = s:gsub("<[^>]+>", "")
    s = s:gsub("&%w+;", "")
    s = s:gsub("%s+", " ")
    return s:match("^%s*(.-)%s*$") or ""
end

-- Common UI words that are NOT code sections
local UI_NOISE = {
    ["submit"] = true, ["redeem"] = true, ["close"] = true, ["back"] = true,
    ["buy"] = true, ["sell"] = true, ["play"] = true, ["exit"] = true,
    ["open"] = true, ["claim"] = true, ["equip"] = true, ["use"] = true,
    ["shop"] = true, ["trade"] = true, ["settings"] = true, ["codes"] = true,
    ["home"] = true, ["ok"] = true, ["yes"] = true, ["no"] = true,
    ["cancel"] = true, ["confirm"] = true, ["accept"] = true, ["decline"] = true,
    ["collect"] = true, ["start"] = true, ["stop"] = true, ["reset"] = true,
    ["inventory"] = true, ["pets"] = true, ["quest"] = true, ["quests"] = true,
    ["daily"] = true, ["spin"] = true, ["roll"] = true, ["hatch"] = true,
    ["upgrade"] = true, ["delete"] = true, ["info"] = true, ["help"] = true,
    ["on"] = true, ["off"] = true, ["auto"] = true, ["skip"] = true,
    ["next"] = true, ["prev"] = true, ["done"] = true, ["ready"] = true,
    ["leave"] = true, ["join"] = true, ["invite"] = true, ["gift"] = true,
    ["send"] = true, ["share"] = true, ["copy"] = true, ["paste"] = true,
    ["login"] = true, ["logout"] = true, ["save"] = true, ["load"] = true,
    -- Game-specific noise
    ["common"] = true, ["rare"] = true, ["epic"] = true, ["legendary"] = true,
    ["mythic"] = true, ["secret"] = true, ["godly"] = true, ["limited"] = true,
    ["brainrot"] = true, ["brainrots"] = true, ["mutation"] = true, ["fuse"] = true,
    ["machine"] = true, ["lucky"] = true, ["block"] = true, ["luckyblock"] = true,
    ["trait"] = true, ["traits"] = true, ["shiny"] = true, ["golden"] = true,
    ["rainbow"] = true, ["phantom"] = true, ["eclipse"] = true, ["crystal"] = true,
    ["robux"] = true, ["coins"] = true, ["gems"] = true, ["cash"] = true,
    ["level"] = true, ["power"] = true, ["speed"] = true, ["luck"] = true,
    ["damage"] = true, ["health"] = true, ["income"] = true, ["cost"] = true,
    ["server"] = true, ["player"] = true, ["players"] = true, ["online"] = true,
    ["round"] = true, ["timer"] = true, ["time"] = true, ["wave"] = true,
    ["event"] = true, ["admin"] = true, ["abuse"] = true, ["riddle"] = true,
    ["answer"] = true, ["correct"] = true, ["wrong"] = true, ["winner"] = true,
    ["reward"] = true, ["rewards"] = true, ["free"] = true, ["premium"] = true,
    ["loading"] = true, ["waiting"] = true, ["starting"] = true, ["ended"] = true,
    ["steal"] = true, ["lobby"] = true, ["game"] = true, ["menu"] = true,
    ["teleport"] = true, ["profile"] = true, ["stats"] = true, ["leaderboard"] = true,
    ["total"] = true, ["owned"] = true, ["locked"] = true, ["unlocked"] = true,
    ["max"] = true, ["min"] = true, ["new"] = true, ["hot"] = true, ["sale"] = true,
    ["code"] = true, ["enter"] = true, ["type"] = true, ["here"] = true,
    ["sammy"] = true, ["age"] = true, ["name"] = true, ["birthday"] = true,
}

-- Check if text is a code section (short alphanumeric, NOT a riddle/question/button)
local function isCodeSection(text)
    if not text or #text < 3 or #text > 25 then return false end
    local t = text:match("^%s*(.-)%s*$") or ""
    if not t:match("^[A-Za-z0-9]+$") then return false end
    -- Filter pure numbers (stats, timers, counts)
    if t:match("^%d+$") then return false end
    -- Filter stat noise patterns
    local u = t:upper()
    if u:match("^%d+MS$") or u:match("^%d+FPS$") or u:match("^%d+HP$")
        or u:match("^%d+XP$") or u:match("^%d+[KM]$") or u:match("^LV%d+$")
        or u:match("^X%d+$") or u:match("^%d+S$") or u:match("^%d+MIN$")
        or u:match("^%d+SEC$") or u:match("^%d+%%$") or u:match("^%a$")
        or u:match("^V%d") or u:match("^ROUND%d") or u:match("^WAVE%d") then
        return false
    end
    -- Filter common UI button/label text
    if UI_NOISE[t:lower()] then return false end
    -- Filter display name patterns (mixed case short words are likely names not codes)
    -- Real code sections are typically ALL CAPS or at least 4+ chars
    if #t < 4 then return false end
    return true
end

-- Check if text looks like a riddle/question (NOT a code section)
local function looksLikeRiddle(text)
    if not text then return false end
    local l = text:lower()
    if l:find("%?") then return true end
    if l:find("what is") or l:find("what's") or l:find("whats") then return true end
    if l:find("who is") or l:find("who's") or l:find("where is") then return true end
    if l:find("how many") or l:find("how old") or l:find("how much") then return true end
    if l:find("when was") or l:find("when did") then return true end
    if l:find("name the") or l:find("tell me") then return true end
    if l:find("riddle") then return true end
    return false
end

-- Dedup + cooldown
local _lastSectionText = ""
local _lastSectionTick = 0

-- Feed a detected section into the existing appendToBox system
local function feedSection(text)
    if not state.codeSniperToggled then return end
    local cleaned = sniperStrip(text)
    if cleaned == "" then return end

    -- Post-submit cooldown: ignore everything for 5s after a redeem
    local now = tick()
    if now - _redeemCooldown < 5 then return end

    -- Skip riddle text
    if looksLikeRiddle(cleaned) then return end

    -- Must look like a code section
    if not isCodeSection(cleaned) then return end

    -- Dedup within 1.5 seconds
    if cleaned == _lastSectionText and (now - _lastSectionTick) < 1.5 then return end
    _lastSectionText = cleaned
    _lastSectionTick = now

    pushLog("> section: " .. cleaned, COL_ON)

    -- Use the existing appendToBox which handles accumulation + box display + submission
    appendToBox(cleaned)
end

-- Noise detection for screen elements
local _elemHits = {}
local _elemBlocked = {}

local function isNoisyElem(obj)
    if _elemBlocked[obj] then return true end
    local info = _elemHits[obj]
    if info and info.n >= 5 and (tick() - info.t) < 3 then
        _elemBlocked[obj] = true
        return true
    end
    return false
end

local function bumpElem(obj)
    local now = tick()
    local info = _elemHits[obj]
    if not info then
        _elemHits[obj] = {n = 1, t = now}
    else
        if (now - info.t) > 5 then
            info.n = 1
            info.t = now
        else
            info.n = info.n + 1
        end
    end
end

local _trackedTexts = {}

-- Containers where brainrot names / game stats show up — NOT code sections
local NOISE_CONTAINERS = {
    [“inventory”] = true, [“backpack”] = true, [“collection”] = true,
    [“shop”] = true, [“store”] = true, [“market”] = true, [“catalog”] = true,
    [“leaderboard”] = true, [“scoreboard”] = true, [“playerlist”] = true,
    [“pets”] = true, [“petinventory”] = true, [“brainrots”] = true,
    [“trading”] = true, [“tradeui”] = true, [“trademenu”] = true,
    [“fusemachine”] = true, [“craftmenu”] = true, [“crafting”] = true,
    [“luckyblock”] = true, [“spinner”] = true, [“wheel”] = true,
    [“tooltip”] = true, [“hoverinfo”] = true, [“details”] = true,
    [“settings”] = true, [“options”] = true, [“config”] = true,
    [“chat”] = true, [“chatframe”] = true,
}

local function isInNoiseContainer(obj)
    local cur = obj.Parent
    for _ = 1, 8 do
        if not cur then break end
        if cur == screenGui then return true end -- our own GUI = noise
        local n = cur.Name:lower():gsub(“[_%-%.%s]”, “”)
        if NOISE_CONTAINERS[n] then return true end
        if n:find(“inventor”) or n:find(“backpack”) or n:find(“collect”)
            or n:find(“leaderb”) or n:find(“scoreb”) or n:find(“trade”)
            or n:find(“shop”) or n:find(“store”) or n:find(“craft”)
            or n:find(“tooltip”) or n:find(“hover”) or n:find(“chat”) then
            return true
        end
        cur = cur.Parent
    end
    return false
end

local function trackTextElement(obj)
    if not obj then return end
    if obj:IsDescendantOf(screenGui) then return end
    if not obj:IsA(“TextLabel”) then return end
    -- Skip labels inside inventory/shop/leaderboard etc
    if isInNoiseContainer(obj) then return end
    if _trackedTexts[obj] then return end
    _trackedTexts[obj] = true

    local lastText = “”
    local conn = obj:GetPropertyChangedSignal(“Text”):Connect(function()
        if not state.codeSniperToggled then return end
        bumpElem(obj)
        if isNoisyElem(obj) then return end
        local text = nil
        pcall(function() text = obj.Text end)
        if text and text ~= “” and text ~= lastText then
            lastText = text
            feedSection(text)
        end
    end)
    table.insert(_sniperConns, conn)
end

local function startSniper()
    _trackedTexts = {}
    _elemHits = {}
    _elemBlocked = {}
    _lastSectionText = ""
    _lastSectionTick = 0
    _capturedParts = {}

    -- 1. Hook notification remote â€” ONLY process announcement-like messages
    local notifyRemote = _notifyRemoteRef
    if not notifyRemote then
        notifyRemote = resolveNotifyRemote()
        _notifyRemoteRef = notifyRemote
    end

    if notifyRemote and (notifyRemote:IsA("RemoteEvent") or notifyRemote:IsA("UnreliableRemoteEvent")) then
        local conn = notifyRemote.OnClientEvent:Connect(function(...)
            if not state.codeSniperToggled then return end
            local args = table.pack(...)
            -- Only grab the first string arg â€” feedSection handles all filtering
            local text = args[1]
            if typeof(text) == "string" and #text >= 1 then
                feedSection(text)
            end
        end)
        table.insert(_sniperConns, conn)
        pushLog("> phantom: notify remote hooked", COL_ON)
    else
        pushLog("> phantom: no notify remote (screen only)", Color3.fromRGB(255, 200, 80))
    end

    -- 2. Watch for NEW TextLabels on screen (only in announcement-like containers)
    local conn2 = PlayerGui.DescendantAdded:Connect(function(obj)
        if not state.codeSniperToggled then return end
        if obj:IsDescendantOf(screenGui) then return end
        if not obj:IsA("TextLabel") then return end
        if isInNoiseContainer(obj) then return end
        trackTextElement(obj)
        local text = nil
        pcall(function() text = obj.Text end)
        if text and text ~= "" then
            feedSection(text)
        end
    end)
    table.insert(_sniperConns, conn2)

    -- 3. Track existing TextLabels for text changes
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        trackTextElement(obj)
    end

    pushLog("> phantom ON (" .. _submitAfter .. " sections)", COL_ON)
end

local function stopSniper()
    for _, c in ipairs(_sniperConns) do pcall(function() c:Disconnect() end) end
    _sniperConns = {}
    _trackedTexts = {}
    _elemHits = {}
    _elemBlocked = {}
    _capturedParts = {}
end

-- PHANTOM CODE REDEEMER TOGGLE
makeToggle(pageMain, 1, "Phantom Code Redeemer", false, function(on)
    state.codeSniperToggled = on
    if on then
        startSniper()
    else
        stopSniper()
        pushLog("> phantom OFF", Color3.fromRGB(140, 140, 150))
    end
end)

-- SECTIONS SELECTOR (1-6) â€” controls _submitAfter (used by appendToBox)
local sectionsRow = makeMainRow(2)

local sectionsLabel = Instance.new("TextLabel")
sectionsLabel.Size = UDim2.new(0.45, 0, 1, 0)
sectionsLabel.Position = UDim2.new(0, 14, 0, 0)
sectionsLabel.BackgroundTransparency = 1
sectionsLabel.Font = Enum.Font.GothamBold
sectionsLabel.TextSize = 12
sectionsLabel.TextColor3 = Theme.text
sectionsLabel.TextXAlignment = Enum.TextXAlignment.Left
sectionsLabel.Text = "Sections"
sectionsLabel.ZIndex = 4
sectionsLabel.Parent = sectionsRow

local secMinus = Instance.new("TextButton")
secMinus.Size = UDim2.new(0, 28, 0, 26)
secMinus.Position = UDim2.new(1, -100, 0.5, -13)
secMinus.BackgroundColor3 = Theme.bgDark
secMinus.Font = Enum.Font.GothamBold
secMinus.TextSize = 14
secMinus.TextColor3 = Theme.text
secMinus.Text = "-"
secMinus.AutoButtonColor = false
secMinus.ZIndex = 4
secMinus.Parent = sectionsRow
corner(secMinus, 6)
hover(secMinus, Theme.bgDark, Theme.accentDim)

local secValue = Instance.new("TextLabel")
secValue.Size = UDim2.new(0, 30, 0, 26)
secValue.Position = UDim2.new(1, -68, 0.5, -13)
secValue.BackgroundTransparency = 1
secValue.Font = Enum.Font.GothamBold
secValue.TextSize = 14
secValue.TextColor3 = Theme.white
secValue.Text = tostring(_submitAfter)
secValue.ZIndex = 4
secValue.Parent = sectionsRow

local secPlus = Instance.new("TextButton")
secPlus.Size = UDim2.new(0, 28, 0, 26)
secPlus.Position = UDim2.new(1, -34, 0.5, -13)
secPlus.BackgroundColor3 = Theme.bgDark
secPlus.Font = Enum.Font.GothamBold
secPlus.TextSize = 14
secPlus.TextColor3 = Theme.text
secPlus.Text = "+"
secPlus.AutoButtonColor = false
secPlus.ZIndex = 4
secPlus.Parent = sectionsRow
corner(secPlus, 6)
hover(secPlus, Theme.bgDark, Theme.accentDim)

secMinus.MouseButton1Click:Connect(function()
    _submitAfter = math.clamp(_submitAfter - 1, 1, 6)
    secValue.Text = tostring(_submitAfter)
    _capturedParts = {}
    pushLog("> sections: " .. _submitAfter, COL_ON)
end)

secPlus.MouseButton1Click:Connect(function()
    _submitAfter = math.clamp(_submitAfter + 1, 1, 6)
    secValue.Text = tostring(_submitAfter)
    _capturedParts = {}
    pushLog("> sections: " .. _submitAfter, COL_ON)
end)

-- AUTO SUBMIT
makeToggle(pageMain, 3, "Auto Submit", true, function(on)
    state.autoSubmitToggled = on
    _autoAccept = on
    pushLog("> auto submit: " .. (on and "ON" or "OFF"), on and COL_ON or Color3.fromRGB(140, 140, 150))
end)
-- Force sync: auto submit is ON by default
state.autoSubmitToggled = true
_autoAccept = true

-- AUTO RIDDLER
makeToggle(pageMain, 4, "Auto Riddler", false, function(on)
    state.riddlerToggled = on
    if on then
        startRiddler()
        pushLog("> riddler ON", COL_ON)
    else
        stopRiddler()
        pushLog("> riddler OFF", Color3.fromRGB(140, 140, 150))
    end
end)

-- RIDDLER AUTO REDEEM
makeToggle(pageMain, 5, "Riddle Auto Redeem", true, function(on)
    state.riddlerAutoRedeem = on
    pushLog("> riddle auto redeem: " .. (on and "ON" or "OFF"), on and COL_ON or Color3.fromRGB(140, 140, 150))
end)

-- ======================== LOGS PAGE ========================
local pageLogs = Instance.new("Frame")
pageLogs.Size = UDim2.new(1, 0, 1, 0)
pageLogs.BackgroundTransparency = 1
pageLogs.Visible = false
pageLogs.ZIndex = 2
pageLogs.Parent = content
pageLogs.ClipsDescendants = true
pages["Logs"] = pageLogs

-- Clear button at top
local logTopBar = Instance.new("Frame")
logTopBar.Size = UDim2.new(1, -4, 0, 28)
logTopBar.Position = UDim2.new(0, 2, 0, 0)
logTopBar.BackgroundTransparency = 1
logTopBar.ZIndex = 3
logTopBar.Parent = pageLogs

local logTitle = Instance.new("TextLabel")
logTitle.Size = UDim2.new(0.5, 0, 1, 0)
logTitle.Position = UDim2.new(0, 6, 0, 0)
logTitle.BackgroundTransparency = 1
logTitle.Text = "LOGS"
logTitle.Font = Enum.Font.GothamBold
logTitle.TextSize = 11
logTitle.TextColor3 = Theme.textMuted
logTitle.TextXAlignment = Enum.TextXAlignment.Left
logTitle.ZIndex = 5
logTitle.Parent = logTopBar

local clearLogsBtn = Instance.new("TextButton")
clearLogsBtn.Size = UDim2.new(0, 50, 0, 20)
clearLogsBtn.Position = UDim2.new(1, -56, 0.5, -10)
clearLogsBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
clearLogsBtn.Font = Enum.Font.GothamBold
clearLogsBtn.TextSize = 10
clearLogsBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
clearLogsBtn.Text = "CLEAR"
clearLogsBtn.AutoButtonColor = false
clearLogsBtn.ZIndex = 10
clearLogsBtn.Parent = logTopBar
corner(clearLogsBtn, 4)
hover(clearLogsBtn, Color3.fromRGB(40, 40, 45), Color3.fromRGB(180, 50, 70))

-- Scrollable log area
_logScroll = Instance.new("ScrollingFrame")
_logScroll.Size = UDim2.new(1, -4, 1, -32)
_logScroll.Position = UDim2.new(0, 2, 0, 30)
_logScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
_logScroll.BorderSizePixel = 0
_logScroll.ScrollBarThickness = 4
_logScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
_logScroll.ScrollBarImageTransparency = 0.3
_logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
_logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
_logScroll.ScrollingDirection = Enum.ScrollingDirection.Y
_logScroll.ZIndex = 3
_logScroll.Parent = pageLogs
corner(_logScroll, 6)
stroke(_logScroll, Theme.stroke, 1)

_logList = Instance.new("UIListLayout")
_logList.SortOrder = Enum.SortOrder.LayoutOrder
_logList.Padding = UDim.new(0, 2)
_logList.Parent = _logScroll

local logScrollPad = Instance.new("UIPadding")
logScrollPad.PaddingTop = UDim.new(0, 4)
logScrollPad.PaddingBottom = UDim.new(0, 4)
logScrollPad.PaddingLeft = UDim.new(0, 6)
logScrollPad.PaddingRight = UDim.new(0, 6)
logScrollPad.Parent = _logScroll

clearLogsBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(_logScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    _logCount = 0
end)

-- Flush any logs that were queued before the page was built
for _, entry in ipairs(logEntries) do
    pushLog(entry.text, entry.color)
end
logEntries = {}

-- ======================== UTILIS PAGE ========================
local pageUtilis = Instance.new("Frame")
pageUtilis.Size = UDim2.new(1, 0, 1, 0)
pageUtilis.BackgroundTransparency = 1
pageUtilis.Visible = false
pageUtilis.ZIndex = 2
pageUtilis.Parent = content
pageUtilis.ClipsDescendants = true
pages["Utilis"] = pageUtilis

local utilisScroll = Instance.new("ScrollingFrame")
utilisScroll.Size = UDim2.new(1, 0, 1, 0)
utilisScroll.BackgroundTransparency = 1
utilisScroll.BorderSizePixel = 0
utilisScroll.ScrollBarThickness = 4
utilisScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
utilisScroll.ScrollBarImageTransparency = 0.3
utilisScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
utilisScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
utilisScroll.ScrollingDirection = Enum.ScrollingDirection.Y
utilisScroll.ZIndex = 2
utilisScroll.Parent = pageUtilis

local utilisLayout = Instance.new("UIListLayout")
utilisLayout.Padding = UDim.new(0, 10)
utilisLayout.SortOrder = Enum.SortOrder.LayoutOrder
utilisLayout.Parent = utilisScroll

local utilisPad = Instance.new("UIPadding")
utilisPad.PaddingBottom = UDim.new(0, 12)
utilisPad.PaddingRight = UDim.new(0, 4)
utilisPad.Parent = utilisScroll

local function makeUtilisRow(order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 40)
    row.BackgroundColor3 = Theme.bgCard
    row.BackgroundTransparency = 0.15
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 3
    row.Parent = utilisScroll
    corner(row, 10)
    stroke(row, Theme.stroke, 1)
    return row
end

local function makeUtilisToggle(order, labelText, default, onToggle)
    local row = makeUtilisRow(order)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = Theme.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.ZIndex = 4
    label.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 42, 0, 22)
    track.Position = UDim2.new(1, -56, 0.5, -11)
    track.BackgroundColor3 = default and Theme.toggleOn or Theme.toggleOff
    track.ZIndex = 4
    track.Parent = row
    corner(track, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = default and UDim2.new(0, 23, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Theme.white
    knob.ZIndex = 5
    knob.Parent = track
    corner(knob, 8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 5
    btn.Parent = row

    local toggled = default or false
    btn.MouseButton1Click:Connect(function()
        toggled = not toggled
        if toggled then
            TweenService:Create(track, TweenFast, { BackgroundColor3 = Theme.toggleOn }):Play()
            TweenService:Create(knob, TweenFast, { Position = UDim2.new(0, 23, 0.5, -8) }):Play()
        else
            TweenService:Create(track, TweenFast, { BackgroundColor3 = Theme.toggleOff }):Play()
            TweenService:Create(knob, TweenFast, { Position = UDim2.new(0, 3, 0.5, -8) }):Play()
        end
        onToggle(toggled)
    end)
    return row
end

-- ANTI LAG
makeUtilisToggle(1, "Anti Lag", false, function(on)
    state.antiLagToggled = on
    if on then
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") then
                    obj.Enabled = false
                    obj:Destroy()
                end
            end)
        end
        Lighting.GlobalShadows = false
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        Camera.FieldOfView = 90
        for _, effect in ipairs(Camera:GetChildren()) do
            if effect:IsA("BloomEffect") or effect:IsA("DepthOfField") or effect:IsA("ColorCorrectionEffect") then
                effect.Enabled = false
            end
        end
        pushLog("> anti lag: ON", COL_ON)
    else
        pushLog("> anti lag: OFF", Color3.fromRGB(140, 140, 150))
    end
end)

-- ANTI DIE
local heartConn = nil
local deathConns = {}
local charAddedConn = nil

local function protectChar(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    hum.MaxHealth = math.huge
    hum.Health = math.huge
    local sc = hum.StateChanged:Connect(function(_, new)
        if not state.antiDieToggled then return end
        if new == Enum.HumanoidStateType.Dead then
            hum.Health = math.huge
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end
    end)
    table.insert(deathConns, sc)
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    local hc = hum:GetPropertyChangedSignal("Health"):Connect(function()
        if not state.antiDieToggled then return end
        if hum.Health < hum.MaxHealth then hum.Health = math.huge end
    end)
    table.insert(deathConns, hc)
    if heartConn then heartConn:Disconnect() end
    heartConn = RunService.Heartbeat:Connect(function()
        if not state.antiDieToggled then return end
        if hum and hum.Parent and hum.Health < hum.MaxHealth then hum.Health = math.huge end
    end)
end

makeUtilisToggle(2, "Anti Die", false, function(on)
    state.antiDieToggled = on
    if on then
        for _, c in ipairs(deathConns) do pcall(function() c:Disconnect() end) end
        deathConns = {}
        if heartConn then heartConn:Disconnect(); heartConn = nil end
        if charAddedConn then charAddedConn:Disconnect(); charAddedConn = nil end
        protectChar(LocalPlayer.Character)
        charAddedConn = LocalPlayer.CharacterAdded:Connect(function(c)
            if not state.antiDieToggled then return end
            task.wait(0.1)
            for _, c2 in ipairs(deathConns) do pcall(function() c2:Disconnect() end) end
            deathConns = {}
            protectChar(c)
        end)
        pushLog("> anti die: ON", COL_ON)
    else
        for _, c in ipairs(deathConns) do pcall(function() c:Disconnect() end) end
        deathConns = {}
        if heartConn then heartConn:Disconnect(); heartConn = nil end
        if charAddedConn then charAddedConn:Disconnect(); charAddedConn = nil end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
                hum.MaxHealth = 100
                hum.Health = 100
            end
        end
        pushLog("> anti die: OFF", Color3.fromRGB(140, 140, 150))
    end
end)

-- ANTI RAGDOLL
local _ragdollConn = nil

makeUtilisToggle(3, "Anti Ragdoll", false, function(on)
    state.antiRagdollToggled = on
    if on then
        _ragdollConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end
            local s = hum:GetState()
            if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll or s == Enum.HumanoidStateType.FallingDown then
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                    end
                    hum.PlatformStand = false
                    hum.Sit = false
                end)
            end
        end)
        pushLog("> anti ragdoll: ON", COL_ON)
    else
        if _ragdollConn then _ragdollConn:Disconnect(); _ragdollConn = nil end
        pushLog("> anti ragdoll: OFF", Color3.fromRGB(140, 140, 150))
    end
end)

-- ANCHORED
makeUtilisToggle(4, "Anchored", false, function(on)
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.Anchored = on end
        end
    end
end)

-- AUTO BUY
local autoBuyActive = false
makeUtilisToggle(5, "Auto Buy", false, function(on)
    autoBuyActive = on
    state.autoBuyToggled = on
    pushLog("> auto buy: " .. (on and "ON" or "OFF"), on and COL_ON or Color3.fromRGB(140, 140, 150))
end)

RunService.Stepped:Connect(function(_, dt)
    if not autoBuyActive then return end
    for _, prompt in pairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            pcall(function()
                prompt.HoldDuration = 0
                prompt:InputHoldBegin()
                prompt:InputHoldEnd()
            end)
        end
    end
end)

-- ======================== SETTINGS PAGE ========================
local pageSettings = Instance.new("Frame")
pageSettings.Size = UDim2.new(1, 0, 1, 0)
pageSettings.BackgroundTransparency = 1
pageSettings.Visible = false
pageSettings.ZIndex = 2
pageSettings.Parent = content
pages["Settings"] = pageSettings

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 10)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Parent = pageSettings

local function makeSettingsRow(order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = Theme.bgCard
    row.BackgroundTransparency = 0.15
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 3
    row.Parent = pageSettings
    corner(row, 10)
    stroke(row, Theme.stroke, 1)
    return row
end

-- GUI SIZE
local sizeRow = makeSettingsRow(1)
local sizeLabel = Instance.new("TextLabel")
sizeLabel.Size = UDim2.new(0.4, 0, 1, 0)
sizeLabel.Position = UDim2.new(0, 14, 0, 0)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Font = Enum.Font.GothamBold
sizeLabel.TextSize = 12
sizeLabel.TextColor3 = Theme.text
sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
sizeLabel.Text = "GUI Size"
sizeLabel.ZIndex = 4
sizeLabel.Parent = sizeRow

local sizeMinus = Instance.new("TextButton")
sizeMinus.Size = UDim2.new(0, 28, 0, 26)
sizeMinus.Position = UDim2.new(1, -118, 0.5, -13)
sizeMinus.BackgroundColor3 = Theme.bgDark
sizeMinus.Font = Enum.Font.GothamBold
sizeMinus.TextSize = 14
sizeMinus.TextColor3 = Theme.text
sizeMinus.Text = "-"
sizeMinus.AutoButtonColor = false
sizeMinus.ZIndex = 4
sizeMinus.Parent = sizeRow
corner(sizeMinus, 6)

local sizeValue = Instance.new("TextLabel")
sizeValue.Size = UDim2.new(0, 50, 0, 26)
sizeValue.Position = UDim2.new(1, -86, 0.5, -13)
sizeValue.BackgroundTransparency = 1
sizeValue.Font = Enum.Font.GothamBold
sizeValue.TextSize = 12
sizeValue.TextColor3 = Theme.text
sizeValue.Text = "100%"
sizeValue.ZIndex = 4
sizeValue.Parent = sizeRow

local sizePlus = Instance.new("TextButton")
sizePlus.Size = UDim2.new(0, 28, 0, 26)
sizePlus.Position = UDim2.new(1, -34, 0.5, -13)
sizePlus.BackgroundColor3 = Theme.bgDark
sizePlus.Font = Enum.Font.GothamBold
sizePlus.TextSize = 14
sizePlus.TextColor3 = Theme.text
sizePlus.Text = "+"
sizePlus.AutoButtonColor = false
sizePlus.ZIndex = 4
sizePlus.Parent = sizeRow
corner(sizePlus, 6)

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1
uiScale.Parent = main

local function updateSize(delta)
    state.guiSize = math.clamp(state.guiSize + delta, 60, 140)
    sizeValue.Text = state.guiSize .. "%"
    uiScale.Scale = state.guiSize / 100
end
sizeMinus.MouseButton1Click:Connect(function() updateSize(-10) end)
sizePlus.MouseButton1Click:Connect(function() updateSize(10) end)

-- RESET POSITION
local resetRow = makeSettingsRow(2)
local resetLabel = Instance.new("TextLabel")
resetLabel.Size = UDim2.new(0.55, 0, 1, 0)
resetLabel.Position = UDim2.new(0, 14, 0, 0)
resetLabel.BackgroundTransparency = 1
resetLabel.Font = Enum.Font.GothamBold
resetLabel.TextSize = 12
resetLabel.TextColor3 = Theme.text
resetLabel.TextXAlignment = Enum.TextXAlignment.Left
resetLabel.Text = "Reset Position"
resetLabel.ZIndex = 4
resetLabel.Parent = resetRow

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0, 70, 0, 26)
resetBtn.Position = UDim2.new(1, -84, 0.5, -13)
resetBtn.BackgroundColor3 = Theme.accent
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 11
resetBtn.TextColor3 = Theme.bg
resetBtn.Text = "RESET"
resetBtn.AutoButtonColor = false
resetBtn.ZIndex = 4
resetBtn.Parent = resetRow
corner(resetBtn, 6)
hover(resetBtn, Theme.accent, Theme.accentHover)

resetBtn.MouseButton1Click:Connect(function()
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
end)

-- ======================== FOOTER ========================
local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, 0, 0, 36)
footer.Position = UDim2.new(0, 0, 1, -36)
footer.BackgroundColor3 = Theme.bgDark
footer.BackgroundTransparency = 0.3
footer.BorderSizePixel = 0
footer.ZIndex = 2
footer.Parent = main

-- ======================== DRAG ========================
local dragging = false
local dragStart = nil
local startPos = nil

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

UserInputService.InputChanged:Connect(function(input)
    if state.locked then dragging = false; return end
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ======================== MINIMIZE ========================
local fullSize = UDim2.new(0, 320, 0, 460)
local minSize = UDim2.new(0, 320, 0, 42)

minBtn.MouseButton1Click:Connect(function()
    state.minimized = not state.minimized
    if state.minimized then
        content.Visible = false
        tabBar.Visible = false
        footer.Visible = false
        TweenService:Create(main, TweenMed, { Size = minSize }):Play()
        minBtn.Text = "+"
    else
        TweenService:Create(main, TweenMed, { Size = fullSize }):Play()
        task.delay(0.2, function()
            content.Visible = true
            tabBar.Visible = true
            footer.Visible = true
        end)
        minBtn.Text = "-"
    end
end)

-- ======================== BACKGROUND PARTICLES ========================
local particleBg = Instance.new("Frame")
particleBg.Name = "ParticleBg"
particleBg.Size = UDim2.fromScale(1, 1)
particleBg.BackgroundTransparency = 1
particleBg.ClipsDescendants = true
particleBg.ZIndex = 1
particleBg.Parent = main
corner(particleBg, 14)

local _bgElements = {}

-- LAYER 1: Medium floating shapes (dots + diamonds, all white/gray)
for i = 1, 16 do
    local isDiamond = (i % 3 == 0)
    local sz = isDiamond and math.random(4, 7) or math.random(2, 5)
    local shade = math.random(180, 255)
    local p = Instance.new("Frame")
    p.Size = UDim2.fromOffset(sz, sz)
    p.Position = UDim2.new(math.random() * 0.92 + 0.02, 0, math.random() * 0.92 + 0.02, 0)
    p.BackgroundColor3 = Color3.fromRGB(shade, shade, shade)
    p.BackgroundTransparency = math.random(65, 88) / 100
    p.BorderSizePixel = 0
    p.ZIndex = 1
    p.Rotation = isDiamond and 45 or 0
    p.Parent = particleBg
    corner(p, isDiamond and 1 or sz)

    _bgElements[#_bgElements + 1] = {
        frame = p, kind = "shape",
        vx = (math.random() - 0.5) * 0.025,
        vy = (math.random() - 0.5) * 0.025,
        pulse = math.random() * 6.28,
        pulseSpeed = 1.0 + math.random() * 1.2,
    }
end

-- LAYER 3: Rising sparkles (tiny white, drift upward, twinkle)
for i = 1, 16 do
    local sz = math.random(1, 3)
    local sp = Instance.new("Frame")
    sp.Size = UDim2.fromOffset(sz, sz)
    sp.Position = UDim2.new(math.random() * 0.95 + 0.02, 0, math.random() * 0.95 + 0.02, 0)
    sp.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sp.BackgroundTransparency = 0.7
    sp.BorderSizePixel = 0
    sp.ZIndex = 1
    sp.Parent = particleBg
    corner(sp, sz)

    _bgElements[#_bgElements + 1] = {
        frame = sp, kind = "sparkle",
        vx = (math.random() - 0.5) * 0.012,
        vy = -0.008 - math.random() * 0.015,
        pulse = math.random() * 6.28,
        pulseSpeed = 2.5 + math.random() * 3.0,
    }
end

-- LAYER 4: Faint white scan lines (subtle, slow scroll)
for i = 1, 2 do
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.25 * i + math.random() * 0.2, 0)
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line.BackgroundTransparency = 0.94
    line.BorderSizePixel = 0
    line.ZIndex = 1
    line.Parent = particleBg

    _bgElements[#_bgElements + 1] = {
        frame = line, kind = "scanline",
        vy = 0.004 + math.random() * 0.003,
    }
end

RunService.RenderStepped:Connect(function(dt)
    for _, el in ipairs(_bgElements) do
        if not el.frame or not el.frame.Parent then continue end

        if el.kind == "shape" then
            local pos = el.frame.Position
            local nx = pos.X.Scale + el.vx * dt
            local ny = pos.Y.Scale + el.vy * dt
            if nx < 0 or nx > 0.96 then el.vx = -el.vx; nx = math.clamp(nx, 0, 0.96) end
            if ny < 0 or ny > 0.96 then el.vy = -el.vy; ny = math.clamp(ny, 0, 0.96) end
            el.frame.Position = UDim2.new(nx, 0, ny, 0)
            el.pulse = el.pulse + dt * el.pulseSpeed
            el.frame.BackgroundTransparency = 0.60 + math.sin(el.pulse) * 0.28

        elseif el.kind == "sparkle" then
            local pos = el.frame.Position
            local nx = pos.X.Scale + el.vx * dt
            local ny = pos.Y.Scale + el.vy * dt
            if ny < -0.02 then
                ny = 1.02
                nx = math.random() * 0.95 + 0.02
            end
            if nx < 0 or nx > 0.98 then el.vx = -el.vx; nx = math.clamp(nx, 0, 0.98) end
            el.frame.Position = UDim2.new(nx, 0, ny, 0)
            el.pulse = el.pulse + dt * el.pulseSpeed
            local t = math.sin(el.pulse) * 0.5
            el.frame.BackgroundTransparency = 0.5 + t * t

        elseif el.kind == "scanline" then
            local ny = el.frame.Position.Y.Scale + el.vy * dt
            if ny > 1.05 then ny = -0.05 end
            el.frame.Position = UDim2.new(0, 0, ny, 0)
        end
    end
end)

-- ======================== TEXT WAVE (CONTINUOUS SMOOTH) ========================
local function stripFontTags(s)
    if type(s) ~= "string" then return tostring(s) end
    return s:gsub("<font[^>]*>", ""):gsub("</font>", "")
end

local function rgbStr(v)
    local n = math.floor(math.clamp(v, 0, 255))
    return "rgb(" .. n .. "," .. n .. "," .. n .. ")"
end

local function splitColorText(text, colLeft, colRight)
    if not text or text == "" then return "" end
    local mid = math.ceil(#text / 2)
    local left = text:sub(1, mid)
    local right = text:sub(mid + 1)
    if right == "" then
        return '<font color="' .. colLeft .. '">' .. left .. '</font>'
    end
    return '<font color="' .. colLeft .. '">' .. left .. '</font><font color="' .. colRight .. '">' .. right .. '</font>'
end

task.spawn(function()
    local WAVE_SPEED = 1.0 -- slow smooth wave
    while screenGui and screenGui.Parent do
        local wave = (math.sin(tick() * WAVE_SPEED) + 1) / 2 -- 0 to 1 continuous
        local leftVal = wave * 255
        local rightVal = (1 - wave) * 255
        local colLeft = rgbStr(leftVal)
        local colRight = rgbStr(rightVal)

        for _, obj in ipairs(screenGui:GetDescendants()) do
            pcall(function()
                if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
                if obj == LogLabel then return end
                obj.RichText = true
                local raw = stripFontTags(obj.Text)
                if raw ~= "" then
                    obj.Text = splitColorText(raw, colLeft, colRight)
                end
            end)
        end

        task.wait(0.06)
    end
end)

-- ======================== INIT ========================
setTab("Main")
pushLog("> PhantomHub loaded", COL_ON)
print("PhantomHub loaded")

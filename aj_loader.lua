-- PhantomHub Auto Joiner Loader v2 (API-first key validation)
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

local API_BASE = "https://phantomhub.onrender.com"
local GITHUB_RAW = "https://raw.githubusercontent.com/765632/PhantomHub/master"

local function showMsg(text, color)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "PhantomAJLoader"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 9999
        if not pcall(function() sg.Parent = game:GetService("CoreGui") end) then
            sg.Parent = LP:WaitForChild("PlayerGui")
        end
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.8, 0, 0, 40)
        lbl.Position = UDim2.new(0.1, 0, 0.05, 0)
        lbl.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        lbl.BackgroundTransparency = 0.15
        lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        lbl.TextSize = 16
        lbl.Font = Enum.Font.GothamBold
        lbl.Text = text
        lbl.TextWrapped = true
        lbl.Parent = sg
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = lbl
        task.delay(8, function() pcall(function() sg:Destroy() end) end)
    end)
end

local function clearLoader()
    pcall(function()
        local prev = game:GetService("CoreGui"):FindFirstChild("PhantomAJLoader")
        if prev then prev:Destroy() end
    end)
    pcall(function()
        local prev = LP.PlayerGui:FindFirstChild("PhantomAJLoader")
        if prev then prev:Destroy() end
    end)
end

local function httpGet(url)
    local body = nil
    pcall(function() body = game:HttpGet(url, true) end)
    if not body or body == "" then pcall(function() body = game:HttpGet(url) end) end
    if not body or body == "" then pcall(function() body = HttpService:GetAsync(url) end) end
    if not body or body == "" then pcall(function() local r = request({Url = url, Method = "GET"}) body = r.Body end) end
    if not body or body == "" then pcall(function() local r = http_request({Url = url, Method = "GET"}) body = r.Body end) end
    return body
end

local function getHWID()
    local hwid = ""
    pcall(function() hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
    if hwid == "" then pcall(function() hwid = tostring(LP.UserId) end) end
    return hwid
end

-- ═══ KEY CHECK ═══
local userKey = getgenv().phantom_key or getgenv().script_key or script_key or ""
if userKey == "" then
    showMsg("[Auto Joiner] No key set — use getgenv().phantom_key = \"YOUR-KEY\"", Color3.fromRGB(255, 50, 50))
    return
end

showMsg("[Auto Joiner] Validating key...", Color3.fromRGB(100, 200, 255))

-- Method 1: Bot API (instant, no cache)
local keyValid = false
pcall(function()
    local apiUrl = API_BASE .. "/api/validate?key=" .. userKey .. "&hwid=" .. getHWID()
    local raw = httpGet(apiUrl)
    if raw and raw ~= "" then
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and data and data.valid then
            keyValid = true
        end
    end
end)

-- Method 2: GitHub raw fallback
if not keyValid then
    pcall(function()
        local keysRaw = httpGet(GITHUB_RAW .. "/data/keys.json?v=" .. tostring(tick()))
        if keysRaw and keysRaw ~= "" then
            local ok, keysData = pcall(function() return HttpService:JSONDecode(keysRaw) end)
            if ok and keysData then
                local keyInfo = keysData[userKey]
                if keyInfo and keyInfo.redeemedBy and not keyInfo.expired then
                    if keyInfo.expiresAt == nil or keyInfo.expiresAt == "never" then
                        keyValid = true
                    else
                        local expiresAtSec = tonumber(keyInfo.expiresAt)
                        if expiresAtSec then
                            if os.time() < (expiresAtSec / 1000) then keyValid = true end
                        end
                    end
                end
            end
        end
    end)
end

if not keyValid then
    LP:Kick("\n\n[PhantomHub Auto Joiner] Invalid or expired key.\n\nGet a key at discord.gg/RvDUEm7hE\n")
    return
end

-- ═══ KEY VALID — LOAD AUTO JOINER ═══
clearLoader()
showMsg("[Auto Joiner] Key valid — loading...", Color3.fromRGB(255, 190, 60))

local SCRIPT_URL = GITHUB_RAW .. "/auto_joiner.lua?v=" .. tostring(tick())
local src = httpGet(SCRIPT_URL)

if not src or src == "" then
    -- fallback: try bot API
    src = httpGet(API_BASE .. "/aj.lua")
end

if not src or src == "" then
    showMsg("[Auto Joiner] HTTP failed — can't reach GitHub or API", Color3.fromRGB(255, 50, 50))
    return
end

clearLoader()

local fn, err = loadstring(src)
if fn then
    clearLoader()
    fn()
else
    showMsg("[Auto Joiner] Parse error: " .. tostring(err), Color3.fromRGB(255, 50, 50))
end

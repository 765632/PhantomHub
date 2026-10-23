-- PhantomHub Loader v5 (key validation + expiry check)
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

local function showMsg(text, color)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "PhantomLoader"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 9999
        if not pcall(function() sg.Parent = game:GetService("CoreGui") end) then
            sg.Parent = LP:WaitForChild("PlayerGui")
        end
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.8, 0, 0, 40)
        lbl.Position = UDim2.new(0.1, 0, 0.05, 0)
        lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
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
        local prev = game:GetService("CoreGui"):FindFirstChild("PhantomLoader")
        if prev then prev:Destroy() end
    end)
    pcall(function()
        local prev = LP.PlayerGui:FindFirstChild("PhantomLoader")
        if prev then prev:Destroy() end
    end)
end

-- ═══ KEY CHECK ═══
if not script_key or script_key == "" then
    showMsg("[PhantomHub] No key set", Color3.fromRGB(255, 50, 50))
    return
end

showMsg("[PhantomHub] Validating key...", Color3.fromRGB(100, 200, 255))

-- fetch keys database from GitHub
local KEYS_URL = "https://raw.githubusercontent.com/765632/PhantomHub/master/data/keys.json?v=" .. tostring(tick())
local keysRaw = nil
local fetchOk = false

-- try multiple HTTP methods (executor compat)
fetchOk = pcall(function()
    keysRaw = game:HttpGet(KEYS_URL, true)
end)
if not fetchOk or not keysRaw or keysRaw == "" then
    fetchOk = pcall(function()
        keysRaw = game:HttpGet(KEYS_URL)
    end)
end
if not fetchOk or not keysRaw or keysRaw == "" then
    fetchOk = pcall(function()
        keysRaw = HttpService:GetAsync(KEYS_URL)
    end)
end
if not fetchOk or not keysRaw or keysRaw == "" then
    fetchOk = pcall(function()
        local resp = request({Url = KEYS_URL, Method = "GET"})
        keysRaw = resp.Body
    end)
end
if not fetchOk or not keysRaw or keysRaw == "" then
    fetchOk = pcall(function()
        local resp = http_request({Url = KEYS_URL, Method = "GET"})
        keysRaw = resp.Body
    end)
end

if not keysRaw or keysRaw == "" then
    showMsg("[PhantomHub] Can't reach key server", Color3.fromRGB(255, 50, 50))
    return
end

-- parse keys JSON
local keysOk, keysData = pcall(function()
    return HttpService:JSONDecode(keysRaw)
end)

if not keysOk or not keysData then
    showMsg("[PhantomHub] Key validation error", Color3.fromRGB(255, 50, 50))
    return
end

-- look up this key
local keyInfo = keysData[script_key]

if not keyInfo then
    LP:Kick("\n\n⛔ Invalid PhantomHub key.\n\nGet a valid key at discord.gg/RvDUEm7hE\n")
    return
end

-- check if already flagged expired by the bot
if keyInfo.expired == true then
    LP:Kick("\n\n⏰ Your PhantomHub key has expired!\n\nPurchase a new key at discord.gg/RvDUEm7hE\n")
    return
end

-- check timestamp expiry (expiresAt is in milliseconds, os.time() is seconds)
if keyInfo.expiresAt ~= nil and keyInfo.expiresAt ~= "never" then
    local expiresAtSec = tonumber(keyInfo.expiresAt)
    if expiresAtSec then
        expiresAtSec = expiresAtSec / 1000 -- convert ms to seconds
        local now = os.time()
        if now > expiresAtSec then
            LP:Kick("\n\n⏰ Your PhantomHub key has expired!\n\nPurchase a new key at discord.gg/RvDUEm7hE\n")
            return
        end
    end
end

-- check if key has been redeemed (unredeemed keys can't be used)
if keyInfo.redeemedBy == nil then
    LP:Kick("\n\n⛔ This key hasn't been redeemed yet.\n\nRedeem it in the PhantomHub Discord first.\ndiscord.gg/RvDUEm7hE\n")
    return
end

-- ═══ KEY VALID — LOAD SCRIPT ═══
clearLoader()
showMsg("[PhantomHub] Key valid — loading...", Color3.fromRGB(0, 255, 150))

local SCRIPT_URL = "https://raw.githubusercontent.com/765632/PhantomHub/master/data/phantomhub_script.lua?v=" .. tostring(tick())
local src = nil
local method = "none"

local ok = pcall(function()
    src = game:HttpGet(SCRIPT_URL, true)
    method = "HttpGet(cache-bust)"
end)

if not ok or not src or src == "" then
    ok = pcall(function()
        src = game:HttpGet(SCRIPT_URL)
        method = "HttpGet"
    end)
end

if not ok or not src or src == "" then
    ok = pcall(function()
        src = HttpService:GetAsync(SCRIPT_URL)
        method = "HttpService"
    end)
end

if not ok or not src or src == "" then
    ok = pcall(function()
        local resp = request({Url = SCRIPT_URL, Method = "GET"})
        src = resp.Body
        method = "request()"
    end)
end

if not ok or not src or src == "" then
    ok = pcall(function()
        local resp = http_request({Url = SCRIPT_URL, Method = "GET"})
        src = resp.Body
        method = "http_request()"
    end)
end

if not src or src == "" then
    showMsg("[PhantomHub] HTTP failed - executor can't reach GitHub", Color3.fromRGB(255, 50, 50))
    return
end

clearLoader()
showMsg("[PhantomHub] Loaded (" .. method .. ") - starting...", Color3.fromRGB(0, 255, 150))

local fn, err = loadstring(src)
if fn then
    clearLoader()
    fn()
else
    showMsg("[PhantomHub] Parse error: " .. tostring(err), Color3.fromRGB(255, 50, 50))
end

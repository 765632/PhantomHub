-- PhantomHub Loader v4
local function showMsg(text, color)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "PhantomLoader"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 9999
        if not pcall(function() sg.Parent = game:GetService("CoreGui") end) then
            sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
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
        local prev = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("PhantomLoader")
        if prev then prev:Destroy() end
    end)
end

if not script_key or script_key == "" then
    showMsg("[PhantomHub] No key set", Color3.fromRGB(255, 50, 50))
    return
end

showMsg("[PhantomHub] Loading...", Color3.fromRGB(100, 200, 255))

local URL = "https://raw.githubusercontent.com/765632/PhantomHub/master/data/phantomhub_script.lua?v=" .. tostring(tick())
local src
local method = "none"

local ok = pcall(function()
    src = game:HttpGet(URL, true)
    method = "HttpGet(cache-bust)"
end)

if not ok or not src or src == "" then
    ok = pcall(function()
        src = game:HttpGet(URL)
        method = "HttpGet"
    end)
end

if not ok or not src or src == "" then
    ok = pcall(function()
        local http = game:GetService("HttpService")
        src = http:GetAsync(URL)
        method = "HttpService"
    end)
end

if not ok or not src or src == "" then
    ok = pcall(function()
        local resp = request({Url = URL, Method = "GET"})
        src = resp.Body
        method = "request()"
    end)
end

if not ok or not src or src == "" then
    ok = pcall(function()
        local resp = http_request({Url = URL, Method = "GET"})
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

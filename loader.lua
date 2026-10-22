-- PhantomHub Loader v3
if not script_key or script_key == "" then
    warn("[PhantomHub] No key set.")
    return
end

local URL = "https://raw.githubusercontent.com/765632/PhantomHub/master/data/phantomhub_script.lua"
local src

local ok = pcall(function()
    src = game:HttpGet(URL, true)
end)

if not ok or not src or src == "" then
    ok = pcall(function()
        src = game:HttpGet(URL)
    end)
end

if not ok or not src or src == "" then
    ok = pcall(function()
        local http = game:GetService("HttpService")
        src = http:GetAsync(URL)
    end)
end

if not ok or not src or src == "" then
    ok = pcall(function()
        local resp = request({Url = URL, Method = "GET"})
        src = resp.Body
    end)
end

if not ok or not src or src == "" then
    ok = pcall(function()
        local resp = http_request({Url = URL, Method = "GET"})
        src = resp.Body
    end)
end

if not src or src == "" then
    warn("[PhantomHub] Connection failed - check your executor supports HTTP requests")
    return
end

local fn, err = loadstring(src)
if fn then fn() else warn("[PhantomHub] Load error: " .. tostring(err)) end

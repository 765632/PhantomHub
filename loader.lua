-- PhantomHub Loader v2
if not script_key or script_key == "" then
    warn("[PhantomHub] No key set.")
    return
end

local hwid = "UNKNOWN"
pcall(function()
    if gethwid then hwid = gethwid()
    elseif identifyexecutor then
        local _, id = identifyexecutor()
        hwid = id or tostring(game:GetService("RbxAnalyticsService"):GetClientId())
    else
        hwid = tostring(game:GetService("RbxAnalyticsService"):GetClientId())
    end
end)

local ok, src = pcall(function()
    return game:HttpGet("https://phantomhub.onrender.com/load?key=" .. script_key .. "&hwid=" .. hwid)
end)

if not ok or not src or src:sub(1, 2) == "--" then
    warn(src or "[PhantomHub] Connection failed")
    return
end

local fn, err = loadstring(src)
if fn then fn() else warn("[PhantomHub] " .. tostring(err)) end

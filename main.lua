local BASE = "https://raw.githubusercontent.com/YOUR_USERNAME/Watermelon-Hub/main/"

local function getModule(name)
    local response = game:HttpGet(BASE .. name .. ".lua")
    local fn, err = loadstring(response)
    assert(fn, err or ("Failed to load " .. name))
    return fn()
end

local UI = getModule("ui")
local startAutoRoll = getModule("autoroll")

startAutoRoll(UI)

print("Watermelon Hub loaded!")

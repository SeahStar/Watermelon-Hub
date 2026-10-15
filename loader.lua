--[[
    WATERMELON HUB - loader (this file is public)

    It contains NO hub code. It only:
      1. finds your device id,
      2. checks your key (or owner secret) with the key server,
      3. downloads the hub modules the server allows for your key,
      4. runs them in order.

    Setup: change CONFIG.API to your Cloudflare Worker address, then upload this file
    to your PUBLIC GitHub repo. Users run:

      loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR-NAME/YOUR-PUBLIC-REPO/main/loader.lua"))()
]]

local CONFIG = {
    API = "https://watermelon-keys.seahstar3.workers.dev", -- no slash at the end
    DISCORD = "https://discord.gg/Cv4sgSk2N",
    FOLDER = "WatermelonHub",
}

-- Developer mode: run the modules from a folder in your executor workspace (no key, no server).
-- Before running the loader:  getgenv().WH_DEV_FOLDER = "WatermelonHub/modules"
local DEV_FOLDER = getgenv and getgenv().WH_DEV_FOLDER or nil

local DEV_ORDER = { "core", "info", "cards", "rank", "activities", "gamemode" }
local SECTION_OF = { info = "Info", cards = "Cards", activities = "Activities", gamemode = "GameMode" }

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local PINK = Color3.fromRGB(255, 55, 160)
local LIGHT_PINK = Color3.fromRGB(255, 120, 200)
local DARK = Color3.fromRGB(18, 13, 23)
local DARKER = Color3.fromRGB(11, 9, 15)
local WHITE = Color3.fromRGB(255, 240, 250)
local MUTED = Color3.fromRGB(165, 150, 175)
local GREEN = Color3.fromRGB(70, 235, 145)
local RED = Color3.fromRGB(255, 75, 105)

--------------------------------------------------------------------------------
-- small helpers
--------------------------------------------------------------------------------

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function copyText(text)
    local ok = pcall(function()
        if setclipboard then
            setclipboard(text)
        elseif toclipboard then
            toclipboard(text)
        else
            error("no clipboard")
        end
    end)
    return ok
end

-- files in the executor workspace (fall back to memory when the executor has no file functions)
local memory = {}
local function storePath(name)
    return CONFIG.FOLDER .. "/" .. name
end

local function readStore(name)
    local ok, value = pcall(function()
        if isfile and readfile and isfile(storePath(name)) then
            return readfile(storePath(name))
        end
        return memory[name]
    end)
    return ok and value or nil
end

local function writeStore(name, value)
    pcall(function()
        if writefile then
            if makefolder and isfolder and not isfolder(CONFIG.FOLDER) then
                makefolder(CONFIG.FOLDER)
            end
            writefile(storePath(name), value)
        end
        memory[name] = value
    end)
end

-- device id: the same device always gives the same id
local function getHwid()
    local ok, id = pcall(function()
        if gethwid then return gethwid() end
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)

    if ok and type(id) == "string" then
        id = id:gsub("[^%w%-_{}%.:]", ""):sub(1, 128)
        if #id >= 8 then return id end
    end

    -- last resort: a random id saved once in the workspace
    local saved = readStore("device.txt")
    if saved and #trim(saved) >= 8 then return trim(saved) end
    local made = HttpService:GenerateGUID(false)
    writeStore("device.txt", made)
    return made
end

local requestFn = request or http_request or (syn and syn.request) or (http and http.request)

-- returns body text, or nil + error message
local function httpGet(url)
    if requestFn then
        local ok, res = pcall(requestFn, { Url = url, Method = "GET" })
        if ok and res then
            if res.StatusCode and res.StatusCode >= 200 and res.StatusCode < 300 then
                return res.Body
            end
            return nil, "HTTP " .. tostring(res.StatusCode), res.Body
        end
        return nil, "request failed"
    end

    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok then return body end
    return nil, "request failed"
end

local function httpPostJson(url, data)
    if not requestFn then return nil, "this executor cannot send requests" end
    local ok, res = pcall(requestFn, {
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(data),
    })
    if not ok or not res then return nil, "cannot reach the key server" end
    return res.Body
end

local function decodeJson(text)
    local ok, data = pcall(function() return HttpService:JSONDecode(text) end)
    if ok and type(data) == "table" then return data end
    return nil
end

local uid = Players.LocalPlayer and Players.LocalPlayer.UserId or 0

-- asks the server; returns the decoded answer or nil + message
local function verifyWithServer(payload)
    local body, err = httpPostJson(CONFIG.API .. "/verify", payload)
    if not body then return nil, err end
    local data = decodeJson(body)
    if not data then return nil, "the key server sent an unexpected answer" end
    return data
end

--------------------------------------------------------------------------------
-- key window
--------------------------------------------------------------------------------

local function askForKey(hwid)
    local result = nil

    local gui = Instance.new("ScreenGui")
    gui.Name = "WatermelonHubKey"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    local function corner(obj, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r)
        c.Parent = obj
    end

    local function stroke(obj, thickness, transparency)
        local s = Instance.new("UIStroke")
        s.Color = PINK
        s.Thickness = thickness
        s.Transparency = transparency
        s.Parent = obj
    end

    local function label(parent, text, size, color, font, y, h)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -28, 0, h)
        l.Position = UDim2.fromOffset(14, y)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = color
        l.TextSize = size
        l.Font = font
        l.TextWrapped = true
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextYAlignment = Enum.TextYAlignment.Top
        l.Parent = parent
        return l
    end

    local function button(parent, text, x, y, w, color)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(w, -8, 0, 34)
        b.Position = UDim2.new(x, 14, 0, y)
        b.BackgroundColor3 = color
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = WHITE
        b.TextSize = 12
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.Parent = parent
        corner(b, 8)
        return b
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(380, 330)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.BackgroundColor3 = DARK
    frame.BorderSizePixel = 0
    frame.Parent = gui
    corner(frame, 12)
    stroke(frame, 1.5, 0.15)

    label(frame, "WATERMELON HUB", 18, WHITE, Enum.Font.GothamBlack, 12, 24)
    label(frame, "Paste your key to continue. Free keys last 24 hours. VIP keys last 30 days.", 11, MUTED, Enum.Font.Gotham, 40, 32)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -28, 0, 38)
    box.Position = UDim2.fromOffset(14, 78)
    box.BackgroundColor3 = DARKER
    box.BorderSizePixel = 0
    box.PlaceholderText = "FREE-... or VIP-..."
    box.PlaceholderColor3 = MUTED
    box.Text = trim(readStore("key.txt") or "")
    box.TextColor3 = WHITE
    box.TextSize = 13
    box.Font = Enum.Font.Code
    box.ClearTextOnFocus = false
    box.Parent = frame
    corner(box, 8)
    stroke(box, 1, 0.7)

    local verifyBtn = button(frame, "Verify", 0, 126, 1, PINK)
    local freeBtn = button(frame, "Get Free Key", 0, 168, 0.5, Color3.fromRGB(45, 30, 47))
    local vipBtn = button(frame, "VIP / Discord", 0.5, 168, 0.5, Color3.fromRGB(88, 101, 242))

    local status = label(frame, "", 11, MUTED, Enum.Font.GothamSemibold, 212, 44)

    local linkBox = Instance.new("TextBox")
    linkBox.Size = UDim2.new(1, -28, 0, 28)
    linkBox.Position = UDim2.fromOffset(14, 260)
    linkBox.BackgroundColor3 = DARKER
    linkBox.BorderSizePixel = 0
    linkBox.Text = ""
    linkBox.TextColor3 = LIGHT_PINK
    linkBox.TextSize = 10
    linkBox.Font = Enum.Font.Code
    linkBox.ClearTextOnFocus = false
    linkBox.TextEditable = false
    linkBox.TextTruncate = Enum.TextTruncate.AtEnd
    linkBox.Visible = false
    linkBox.Parent = frame
    corner(linkBox, 6)

    local function setStatus(text, color)
        status.Text = text
        status.TextColor3 = color
    end

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(28, 28)
    close.Position = UDim2.new(1, -38, 0, 8)
    close.BackgroundColor3 = Color3.fromRGB(100, 25, 60)
    close.BorderSizePixel = 0
    close.Text = "×"
    close.TextColor3 = WHITE
    close.TextSize = 18
    close.Font = Enum.Font.GothamBold
    close.AutoButtonColor = false
    close.Parent = frame
    corner(close, 7)
    close.Activated:Connect(function() result = false end)

    local busy = false
    verifyBtn.Activated:Connect(function()
        if busy then return end

        local key = trim(box.Text)
        if key == "" then
            setStatus("Paste your key first.", RED)
            return
        end

        busy = true
        setStatus("Checking your key...", MUTED)
        local answer, err = verifyWithServer({ key = key, hwid = hwid, uid = uid })
        busy = false

        if not answer then
            setStatus(err or "Cannot reach the key server.", RED)
        elseif not answer.ok then
            setStatus(answer.reason or "Invalid key.", RED)
        else
            writeStore("key.txt", key)
            setStatus("Key accepted (" .. tostring(answer.tier) .. "). Loading...", GREEN)
            task.wait(0.6)
            result = answer
        end
    end)

    freeBtn.Activated:Connect(function()
        local link = CONFIG.API .. "/getkey?h=" .. HttpService:UrlEncode(hwid)
        linkBox.Text = link
        linkBox.Visible = true
        if copyText(link) then
            setStatus("Link copied! Open it in your browser, wait for the timer, then paste the key here.", GREEN)
        else
            setStatus("Select the link below, open it in your browser, then paste the key here.", LIGHT_PINK)
        end
    end)

    vipBtn.Activated:Connect(function()
        if copyText(CONFIG.DISCORD) then
            setStatus("Discord link copied. VIP keys are given in our Discord.", GREEN)
        else
            linkBox.Text = CONFIG.DISCORD
            linkBox.Visible = true
            setStatus("Select the Discord link below. VIP keys are given there.", LIGHT_PINK)
        end
    end)

    while result == nil do
        task.wait(0.2)
    end

    gui:Destroy()
    return result
end

--------------------------------------------------------------------------------
-- module loading
--------------------------------------------------------------------------------

local function compile(source, name)
    local fn, err = loadstring(source, "=" .. name)
    if not fn then return nil, err end
    local ok, moduleFn = pcall(fn)
    if not ok or type(moduleFn) ~= "function" then
        return nil, "module did not return a function"
    end
    return moduleFn
end

local function runModules(list, fetchSource, H)
    local total = #list
    for index, entry in ipairs(list) do
        if H.setLoading then
            H.setLoading("Loading " .. entry .. "...", math.clamp((index - 1) / (total + 0.3), 0, 0.95))
        end

        local source, err = fetchSource(entry)
        if not source then
            warn("[Watermelon Hub] could not load '" .. entry .. "': " .. tostring(err))
            if entry == "core" then return false end
        else
            local moduleFn, cerr = compile(source, entry)
            if not moduleFn then
                warn("[Watermelon Hub] '" .. entry .. "' is broken: " .. tostring(cerr))
                if entry == "core" then return false end
            else
                local ok, rerr = pcall(moduleFn, H)
                if not ok then
                    warn("[Watermelon Hub] '" .. entry .. "' crashed: " .. tostring(rerr))
                    if entry == "core" then return false end
                end
            end
        end
    end
    return true
end

local function finish(H)
    if H.setLoading then H.setLoading("Almost ready...", 1) end
    task.wait(0.3)
    if H.selectPage then H.selectPage("Info") end
    if H.open then H.open() end
    print("Watermelon Hub loaded! (" .. tostring(H.tier) .. ")")
end

--------------------------------------------------------------------------------
-- start
--------------------------------------------------------------------------------

-- developer mode: local files, no key
if DEV_FOLDER then
    local H = { tier = "owner", hwid = "dev", lockedModules = {} }
    runModules(DEV_ORDER, function(name)
        local path = DEV_FOLDER .. "/" .. name .. ".lua"
        if isfile and isfile(path) then return readfile(path) end
        return nil, "file not found: " .. path
    end, H)
    finish(H)
    return
end

local hwid = getHwid()
local answer

-- 1) owner: a secret saved once on your device, no key to fetch
local ownerSecret = trim(readStore("owner.txt") or "")
if ownerSecret ~= "" then
    local r = verifyWithServer({ owner = ownerSecret, hwid = hwid, uid = uid })
    if r and r.ok then answer = r end
end

-- 2) the key saved last time
if not answer then
    local savedKey = trim(readStore("key.txt") or "")
    if savedKey ~= "" then
        local r = verifyWithServer({ key = savedKey, hwid = hwid, uid = uid })
        if r and r.ok then answer = r end
    end
end

-- 3) ask for a key
if not answer then
    answer = askForKey(hwid)
end

if not answer then
    return -- the key window was closed
end

local query = "?s=" .. HttpService:UrlEncode(answer.session) .. "&h=" .. HttpService:UrlEncode(hwid)

local manifestBody, manifestErr = httpGet(CONFIG.API .. "/manifest" .. query)
local manifest = manifestBody and decodeJson(manifestBody)
if not manifest or not manifest.ok then
    warn("[Watermelon Hub] could not get the module list: " .. tostring(manifestErr or (manifest and manifest.reason)))
    return
end

local H = { tier = manifest.tier, hwid = hwid, lockedModules = {}, discord = CONFIG.DISCORD }

local list = {}
for _, m in ipairs(manifest.modules) do
    if m.allowed then
        table.insert(list, m.name)
    else
        H.lockedModules[m.name] = true
    end
end

local ok = runModules(list, function(name)
    local body, err, errBody = httpGet(CONFIG.API .. "/m/" .. name .. query)
    if not body then return nil, tostring(err) .. " " .. tostring(errBody or "") end
    return body
end, H)

if not ok then return end

-- sections whose module this key cannot load say "VIP" instead of "not loaded"
-- (H.locked is the table the core module uses for its page buttons)
for name in pairs(H.lockedModules) do
    if SECTION_OF[name] and H.locked then H.locked[SECTION_OF[name]] = true end
end

finish(H)

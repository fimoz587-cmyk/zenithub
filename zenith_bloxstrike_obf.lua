-- Zenith
-- Luau (Roblox). Uses hookmetamethod / getnamecallmethod / checkcaller for silent, getgc for gun mods, Drawing for ESP if present.

if game.PlaceId ~= 114234929420007 then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Zenith | BloxStrike",
            Text = "This script only works in BloxStrike",
            Duration = 6,
        })
    end)
    return
end

-- callbacks fired by the game can come back without the executor's rights
-- ("lacking capability Plugin"), so each one restores them first
local function ident() end
ident()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Http = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- key system (online): the key server checks the key, its time and the device; the answer is signed
do
    local API = "https://crimson-credit-7603.fimoz587.workers.dev"
    local GAME = "bloxstrike"
    local SIG = "MBPAGFJDNQSQH9BF4M2M9SN8"
    local Http = game:GetService("HttpService")
    local req = (syn and syn.request) or http_request or request or (fluxus and fluxus.request) or (http and http.request)
    local function mix(h, b)
        h = ((h % 256) * 16777216 + h * 403) % 4294967296
        return bit32.bxor(h, b) % 4294967296
    end
    local function shash(str)
        local h = 2166136261
        for i = 1, #str do h = mix(h, string.byte(str, i)) end
        return string.format("%08x", h)
    end
    local function deviceId()
        local id
        pcall(function() if gethwid then id = gethwid() end end)
        if not id then pcall(function() if get_hwid then id = get_hwid() end end) end
        if not id then pcall(function() if syn and syn.crypt and syn.crypt.hwid then id = syn.crypt.hwid() end end) end
        if not id or id == "" then id = "uid:" .. tostring(lp.UserId) end
        return tostring(id)
    end
    local function norm(k) return string.upper((tostring(k or ""):gsub("%s", ""))) end
    local HW = deviceId()
    -- ask the server; returns ok, message, seconds left (-1 = forever), "offline"
    local function ask(k)
        if not req then return false, "your executor can't make web requests" end
        local nonce = tostring(math.random(100000000, 999999999)) .. tostring(math.floor(os.clock() * 1000))
        local ok, res = pcall(function()
            return req({Url = API .. "/check", Method = "POST", Headers = {["Content-Type"] = "application/json"},
                Body = Http:JSONEncode({key = k, hwid = HW, game = GAME, nonce = nonce})})
        end)
        if not ok or type(res) ~= "table" or not res.Body then return false, "key server is not answering", nil, true end
        local okj, data = pcall(Http.JSONDecode, Http, res.Body)
        if not okj or type(data) ~= "table" then return false, "key server is not answering", nil, true end
        if not data.ok then return false, tostring(data.msg or "wrong key") end
        local left = tonumber(data.left) or -1
        if data.sig ~= shash(nonce .. "|" .. k .. "|" .. HW .. "|" .. string.format("%d", left) .. "|" .. SIG) then
            return false, "bad answer"
        end
        return true, "ok", left
    end
    local function leftText(left)
        if not left or left < 0 then return "forever" end
        local d = math.floor(left / 86400)
        local h = math.floor((left % 86400) / 3600)
        if d > 0 then return d .. "d " .. h .. "h left" end
        return h .. "h " .. math.floor((left % 3600) / 60) .. "m left"
    end
    local KFILE = "ZenithKey.txt"
    -- remembered key: re-checked with the server every launch; if the server is down, 12 hours of grace
    local passed = false
    pcall(function()
        if isfile and isfile(KFILE) then
            local data = readfile(KFILE)
            local key, last, tok = string.match(data, "([^|]+)|([^|]+)|([^|]+)")
            if key then
                local ok, _, _, offline = ask(norm(key))
                if ok then
                    passed = true
                    writefile(KFILE, norm(key) .. "|" .. tostring(os.time()) .. "|" .. shash(norm(key) .. HW .. SIG))
                elseif offline and tonumber(last) and os.time() - tonumber(last) < 43200 and tok == shash(norm(key) .. HW .. SIG) then
                    passed = true
                end
            end
        end
    end)
    if not passed then
        local TS = game:GetService("TweenService")
        local g = Instance.new("ScreenGui")
        g.Name = "ZenithKey"
        g.IgnoreGuiInset = true
        g.ResetOnSpawn = false
        g.DisplayOrder = 2000
        pcall(function() g.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        if not g.Parent then g.Parent = lp:WaitForChild("PlayerGui") end
        local function mk(cls, props, parent)
            local o = Instance.new(cls)
            for k, v in pairs(props) do o[k] = v end
            o.Parent = parent
            return o
        end
        local ACC = Color3.fromRGB(150, 120, 255)
        local card = mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 196),
            BackgroundColor3 = Color3.fromRGB(12, 12, 15), BackgroundTransparency = 0.15, BorderSizePixel = 0}, g)
        mk("UICorner", {CornerRadius = UDim.new(0, 12)}, card)
        mk("UIStroke", {Color = Color3.new(1, 1, 1), Transparency = 0.86, Thickness = 1}, card)
        local vp = workspace.CurrentCamera.ViewportSize
        mk("UIScale", {Scale = math.clamp(math.min(vp.X / 420, vp.Y / 300), 0.7, 1.4)}, card)
        local glow = mk("Frame", {Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = ACC, BorderSizePixel = 0}, card)
        mk("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1)})}, glow)
        mk("TextLabel", {Text = "zenith", Font = Enum.Font.Michroma, TextSize = 12, TextColor3 = Color3.fromRGB(150, 152, 160),
            BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 14), Size = UDim2.new(1, -36, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left}, card)
        mk("TextLabel", {Text = "key system", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 32), Size = UDim2.new(1, -36, 0, 26),
            TextXAlignment = Enum.TextXAlignment.Left}, card)
        local boxBg = mk("Frame", {Position = UDim2.fromOffset(18, 72), Size = UDim2.new(1, -36, 0, 38), BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.5, BorderSizePixel = 0}, card)
        mk("UICorner", {CornerRadius = UDim.new(0, 8)}, boxBg)
        local boxStroke = mk("UIStroke", {Color = Color3.new(1, 1, 1), Transparency = 0.85, Thickness = 1}, boxBg)
        local box = mk("TextBox", {Text = "", PlaceholderText = "key", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Color3.new(1, 1, 1),
            PlaceholderColor3 = Color3.fromRGB(120, 122, 130), BackgroundTransparency = 1, ClearTextOnFocus = false,
            Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, boxBg)
        local check = mk("TextButton", {Text = "check", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1),
            AutoButtonColor = false, BackgroundColor3 = ACC, Position = UDim2.fromOffset(18, 122), Size = UDim2.new(0.5, -23, 0, 34),
            BorderSizePixel = 0}, card)
        mk("UICorner", {CornerRadius = UDim.new(0, 8)}, check)
        local buy = mk("TextButton", {Text = "buy @worldedil (tg)", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1),
            AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.9, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -18, 0, 122), Size = UDim2.new(0.5, -23, 0, 34), BorderSizePixel = 0}, card)
        mk("UICorner", {CornerRadius = UDim.new(0, 8)}, buy)
        local note = mk("TextLabel", {Text = "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(150, 152, 160),
            BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 162), Size = UDim2.new(1, -36, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left}, card)
        local done, busy = false, false
        buy.Activated:Connect(function()
ident()
            pcall(function() setclipboard("https://t.me/worldedil") end)
            note.Text = "t.me/worldedil copied"
            note.TextColor3 = Color3.fromRGB(150, 152, 160)
        end)
        local function try()
            if busy then return end
            busy = true
            note.Text = "checking..."
            note.TextColor3 = Color3.fromRGB(150, 152, 160)
            local k = norm(box.Text)
            local ok, msg, left = ask(k)
            if ok then
                pcall(function() writefile(KFILE, k .. "|" .. tostring(os.time()) .. "|" .. shash(k .. HW .. SIG)) end)
                note.Text = "key accepted - " .. leftText(left)
                note.TextColor3 = Color3.fromRGB(110, 230, 150)
                boxStroke.Color, boxStroke.Transparency = Color3.fromRGB(110, 230, 150), 0.2
                task.wait(0.8)
                TS:Create(card, TweenInfo.new(0.25), {BackgroundTransparency = 1, Position = UDim2.fromScale(0.5, 0.46)}):Play()
                for _, d in ipairs(card:GetDescendants()) do
                    if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                        pcall(function() TS:Create(d, TweenInfo.new(0.25), {TextTransparency = 1, BackgroundTransparency = 1}):Play() end)
                    end
                end
                task.wait(0.3)
                g:Destroy()
                done = true
            else
                note.Text = msg
                note.TextColor3 = Color3.fromRGB(255, 95, 95)
                boxStroke.Color, boxStroke.Transparency = Color3.fromRGB(255, 95, 95), 0.2
                local x0 = card.Position
                for _, dx in ipairs({8, -8, 5, -5, 0}) do
                    card.Position = x0 + UDim2.fromOffset(dx, 0)
                    task.wait(0.03)
                end
                card.Position = x0
            end
            busy = false
        end
        check.Activated:Connect(function() task.spawn(try) end)
        box.FocusLost:Connect(function(enter) if enter then task.spawn(try) end end)
        repeat task.wait(0.1) until done
    end
end
local cam = workspace.CurrentCamera

local genv = (getgenv and getgenv()) or _G
if genv.ZenithBS2 then pcall(genv.ZenithBS2) end

local CFG = {
    silent = true, silentFov = 160, hitChance = 100,
    aimbot = false, aimFov = 120, smooth = 6, aimKey = "Hold",
    part = "Head", wallCheck = true, teamCheck = true, showFov = true,
    esp = true, box = true, name = true, health = true, dist = true, chams = false, tracers = false, maxDist = 1000,
    noRecoil = false, noSpread = false, fastReload = false,
    bindList = false, binds = {}, uiScale = 1, aaPitchMode = "None", autoFire = false, autoWall = false, grenadeEsp = true, bhop = false, autoStrafe = false, airStrafe = false,
    fireRateOn = false, fireRateMul = 1.5, aa = false, aaMode = "Spin", aaSpeed = 20, aaPitch = false, cmdSilent = false,
    boxStyle = "Corner", espGrad = false, espGradAnim = true, espCol = "Red", espCol2 = "Purple", teamCol = "Blue", nameCol = "White",
    gnBox = true, gnOwnCol = false, gnCol = "Yellow",
    trigger = false, trigDelay = 40, trigHold = 120, trigHead = false, weaponChams = false,
    gnName = true, gnTracer = false, gnChams = true, gnHE = true, gnFlash = true, gnSmoke = true, gnMolotov = true, gnDecoy = true,
    handChams = false, gloveChams = false, selfChams = false, chamStyle = "ForceField", hitNotify = true, third = false, thirdDist = 10, fovOn = false, camFov = 90, fullbright = false, antiFlash = false, antiSmoke = false,
    accent = "Mint", wEdit = "Rifles", hnCol = "Purple", watermark = true, gnZone = true, skeleton = false, wInfo = true,
    skybox = "Off", skyOn = false, attHook = true, aaServer = true, aaAirSpeed = 30, aaAirPitch = "None",
    moveMethod = "Command", bhopMiss = 15, asSpeed = 90, strafeSens = 3, fastThrow = false, throwSpeed = 3, shootAnim = true, silentPrio = "Crosshair", customModel = false, knifeFast = false, reloadSpeed = 6, knifeSpeed = 2.5,
    aaAir = false, aaPitchMode = "None", bTracers = false, bTracerType = "Neon", trH = 0.55, trS = 0.6, trV = 1, bTracerTime = 0.8,
    trGrad = false, trH2 = 0, trS2 = 1, trV2 = 1, trThick = 0.16,
}
-- silent per weapon group: fov, hit chance, auto wall minimum damage
local GROUPS = {"Pistols", "SMGs", "Rifles", "Snipers", "Shotguns", "Heavy"}
local WGROUP = {}
for g, list in pairs({
    Pistols = {"Glock-18", "USP-S", "P2000", "P250", "Five-SeveN", "Tec-9", "CZ75-Auto", "Desert Eagle", "Dual Berettas", "R8 Revolver", "Zeus x27"},
    SMGs = {"MAC-10", "MP9", "MP7", "MP5-SD", "UMP-45", "P90", "PP-Bizon"},
    Rifles = {"AK-47", "M4A4", "M4A1-S", "Galil AR", "FAMAS", "AUG", "SG 553"},
    Snipers = {"AWP", "SSG 08", "SCAR-20", "G3SG1"},
    Shotguns = {"Nova", "XM1014", "MAG-7", "Sawed-Off"},
    Heavy = {"M249", "Negev"},
}) do
    for _, w in ipairs(list) do WGROUP[w] = g end
end
for _, g in ipairs(GROUPS) do
    CFG["w_" .. g .. "_fov"] = (g == "Snipers") and 260 or 320
    CFG["w_" .. g .. "_hc"] = 100
    CFG["w_" .. g .. "_awd"] = 0
end
CFG.autoWall = true
CFG.silentFov, CFG.hitChance, CFG.awd = 320, 100, 0
CFG.awd = 0
CFG.hbHead, CFG.hbTorso, CFG.hbArms, CFG.hbLegs = true, true, false, false
CFG.magicBullet, CFG.doubleTap, CFG.rapidFire, CFG.rapidMult = false, false, false, 2
CFG.killFx, CFG.chinaHat, CFG.hatH, CFG.hatS, CFG.hatV = true, false, 0.8, 0.6, 1
CFG.wcH, CFG.wcS, CFG.wcV = 0.55, 0.7, 1
CFG.fogOn, CFG.fogEnd, CFG.fogH, CFG.fogS, CFG.fogV = false, 300, 0.6, 0.3, 0.8
CFG.ambOn, CFG.ambH, CFG.ambS, CFG.ambV, CFG.ambBright = false, 0.75, 0.5, 0.7, 2
CFG.aaTorso, CFG.aaHead = "Back", "Down"
CFG.tbHead, CFG.tbTorso, CFG.tbArms, CFG.tbLegs, CFG.aaTorsoPitch = true, true, false, false, false
CFG.espAvatar, CFG.espTeam, CFG.wIcon = true, false, true
CFG.trigWall = true
CFG.tpKnife = true
CFG.predict = CFG.predict or 80
CFG.dormant = CFG.dormant == true
CFG.hnStyle = CFG.hnStyle or "Log"
CFG.hnStyle = "Log"
CFG.predict = 80
CFG.hitChance = 100
CFG.chamsStyle = CFG.chamsStyle or "Glow"
CFG.chamsCol = CFG.chamsCol or "Red"
CFG.chamsFill = CFG.chamsFill or 0.55
CFG.chamsWalls = (CFG.chamsWalls == nil) and true or CFG.chamsWalls
CFG.killSound, CFG.hitSound, CFG.cmOn2, CFG.soundsOn = "None", "None", false, true
CFG.timeOn, CFG.clockTime = false, 14
CFG.edgeJump = false
CFG.flags, CFG.fMoney, CFG.fDist, CFG.fPing, CFG.fHealth, CFG.fBomb = true, true, true, false, true, true
CFG.autoReload, CFG.killFxType, CFG.bombTimer = false, "Ghost", true
CFG.killNotify, CFG.vmOn, CFG.vmX, CFG.vmY, CFG.vmZ = true, false, 0, 0, 0
CFG.curCfg = CFG.curCfg or ""
CFG.dormant = false
CFG.trigger = false
CFG.aimMark = (CFG.aimMark == nil) and true or CFG.aimMark
CFG.cmName = CFG.cmName or "Tung Tung Sahur"
CFG.gTraj = (CFG.gTraj == nil) and true or CFG.gTraj
CFG.targetBox = (CFG.targetBox == nil) and true or CFG.targetBox
CFG.ccOn, CFG.ccBright, CFG.ccContrast, CFG.ccSat, CFG.ccH, CFG.ccS, CFG.ccV = false, 0, 0.1, 0.2, 0.6, 0.15, 1
CFG.bloomOn, CFG.bloomInt, CFG.bloomSize, CFG.bloomThr = false, 0.8, 24, 1.5
CFG.blurOn, CFG.blurSize = false, 6
CFG.mBinds = {}
CFG.aaManual, CFG.aaManLeft, CFG.aaManRight = false, false, false
CFG.directShots = false
CFG.wallPower = CFG.wallPower or 1.5
CFG.boxColMode = CFG.boxColMode or "Team"
CFG.boxFill = (CFG.boxFill == true)
CFG.boxFillTr = CFG.boxFillTr or 0.82
CFG.nameSize = CFG.nameSize or 11
CFG.moveRage = false
CFG.wShow = (CFG.wShow == nil) and true or CFG.wShow
CFG.directShots = false
CFG.missNotify = false
CFG.airStrafe = false
CFG.predOn = false
CFG.rapidFire = false
CFG.af360 = (CFG.af360 == true)
CFG.autoStop = (CFG.autoStop == nil) and true or CFG.autoStop
CFG.autoStopTime = CFG.autoStopTime or 1
local DIR, FILE = "ZenithBS", "ZenithBS/config.json"
pcall(function()
    if isfile and isfile(FILE) then
        local data = Http:JSONDecode(readfile(FILE))
        for k, v in pairs(data) do
            if CFG[k] ~= nil and type(CFG[k]) == type(v) then CFG[k] = v end
        end
    end
end)
CFG.aimKey = "Always"
CFG.reloadSpeed = 20
CFG.trigHold = 60
CFG.tracers, CFG.gnTracer = false, false
CFG.magicBullet = false
CFG.killSound = CFG.killSound or "None"
CFG.hitSound = CFG.hitSound or "None"
CFG.cmOn2 = false
CFG.customModel = false
CFG.aimbot = false
CFG.fireRateOn = false
CFG.aaServer = false
CFG.aaTorso = CFG.aaTorso or "Back"
CFG.aaHead = CFG.aaHead or "Down"
if CFG.aaMode == "Spin on air" then CFG.aaMode, CFG.aaAir = "Spin", true end
local function save()
    pcall(function()
        if makefolder and isfolder and not isfolder(DIR) then makefolder(DIR) end
        if writefile then writefile(FILE, Http:JSONEncode(CFG)) end
    end)
end

local running = true
local ACCENTS = {
    Mint = Color3.fromRGB(80, 230, 170), Blue = Color3.fromRGB(90, 150, 255), Rose = Color3.fromRGB(255, 95, 130),
    Amber = Color3.fromRGB(255, 180, 60), White = Color3.fromRGB(240, 240, 245),
}
local function accentCol() return ACCENTS[CFG.accent] or ACCENTS.Mint end
local PALETTE = {
    {"White", Color3.fromRGB(245, 245, 248)}, {"Red", Color3.fromRGB(255, 70, 80)}, {"Orange", Color3.fromRGB(255, 150, 50)},
    {"Yellow", Color3.fromRGB(255, 220, 70)}, {"Lime", Color3.fromRGB(150, 255, 90)}, {"Green", Color3.fromRGB(60, 220, 120)},
    {"Cyan", Color3.fromRGB(70, 225, 235)}, {"Blue", Color3.fromRGB(80, 140, 255)}, {"Purple", Color3.fromRGB(165, 100, 255)},
    {"Pink", Color3.fromRGB(255, 100, 190)},
}
local PAL = {}
for _, p in ipairs(PALETTE) do PAL[p[1]] = p[2] end
local function palCol(name, fallback) return PAL[name] or fallback end
local function pname(plr, m)
    if plr then
        local ok, n = pcall(function() return plr.DisplayName end)
        if ok and type(n) == "string" and n ~= "" then return n end
        local ok2, n2 = pcall(function() return plr.Name end)
        if ok2 and type(n2) == "string" then return n2 end
    end
    return m and m.Name or "enemy"
end
-- every camera object in workspace (their weapon script keeps the one it started with, named "Camera")
local function viewModels()
    local out, seen = {}, {}
    local function scan(c)
        if c and not seen[c] then
            seen[c] = true
            for _, ch in ipairs(c:GetChildren()) do
                if ch:IsA("Model") then out[#out + 1] = ch end
            end
        end
    end
    scan(workspace.CurrentCamera)
    for _, ch in ipairs(workspace:GetChildren()) do
        if ch:IsA("Camera") then scan(ch) end
    end
    return out
end
local function currentWeapon()
    for _, ch in ipairs(viewModels()) do
        if ch:IsA("Model") then
            if WGROUP[ch.Name] then return ch.Name end
            for _, d in ipairs(ch:GetChildren()) do
                if WGROUP[d.Name] then return d.Name end
            end
        end
    end
    return nil
end
local function groupNow()
    local w = currentWeapon()
    return (w and WGROUP[w]) or "Rifles"
end
local function wval(field, default)
    if field == "fov" then return CFG.silentFov end
    if field == "hc" then return CFG.hitChance end
    if field == "awd" then return CFG.awd end
    return default
end
local conns = {}
local function connect(sig, fn)
    local c = sig:Connect(function(...)
        ident()
        return fn(...)
    end)
    conns[#conns + 1] = c
    return c
end
local HAS_DRAW = false
local DRAW_OK = false
-- removes a Drawing object whatever the executor calls it (Remove / Destroy)
local function dropDrawing(d)
    if not d then return end
    if not pcall(function() d:Remove() end) then
        if not pcall(function() d:Destroy() end) then
            pcall(function() d.Visible = false end)
        end
    end
end
pcall(function()
    if type(Drawing) ~= "table" and type(Drawing) ~= "userdata" then return end
    local d = Drawing.new("Line")
    if d == nil then return end
    pcall(function() d.Visible = false end)
    dropDrawing(d)
    DRAW_OK = true
end)
HAS_DRAW = false

local S = genv.ZenithBS2State or {}
S.dbg = {shots = 0, samples = 0, fires = 0}
genv.ZenithBS2State = S
S.cfg, S.target, S.on = CFG, nil, true

------------------------------------------------------------------ players and sides
local function isRig(m)
    if not m:IsA("Model") or m == cam or m:IsDescendantOf(cam) then return false end
    local head = m:FindFirstChild("Head")
    if not (head and head:IsA("BasePart")) then return false end
    return m:FindFirstChildOfClass("Humanoid") ~= nil or m:FindFirstChild("HumanoidRootPart") ~= nil
        or m:FindFirstChild("UpperTorso") ~= nil or m:FindFirstChild("Torso") ~= nil
end

local rigs, rigsAt = {}, 0
local function scanRigs()
    if tick() - rigsAt < 0.75 then return rigs end
    rigsAt = tick()
    local list, seen = {}, {}
    local function add(m)
        if m and not seen[m] and isRig(m) then
            seen[m] = true
            list[#list + 1] = m
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do add(p.Character) end
    local function dig(f, depth)
        for _, ch in ipairs(f:GetChildren()) do
            if ch:IsA("Model") then
                add(ch)
            elseif depth > 0 and (ch:IsA("Folder") or ch:IsA("Model")) then
                dig(ch, depth - 1)
            end
        end
    end
    for _, ch in ipairs(workspace:GetChildren()) do
        if ch:IsA("Model") then
            add(ch)
            if not isRig(ch) then dig(ch, 2) end
        elseif ch:IsA("Folder") then
            dig(ch, 3)
        end
    end
    rigs = list
    return list
end

local Participants
task.spawn(function()
ident()
    pcall(function()
        Participants = require(RS:WaitForChild("Components", 10):WaitForChild("Common", 10):WaitForChild("Participants", 10))
    end)
end)

local function isEnemy(p)
    if workspace:GetAttribute("Gamemode") == "Deathmatch" then return true end
    local okT, t = pcall(function() return p:GetAttribute("Team") end)
    if not okT then return true end
    local mine = lp:GetAttribute("Team")
    local valid = {["Terrorists"] = true, ["Counter-Terrorists"] = true}
    -- a teammate only when both sides are on the same real team; warmup and everything else = enemy
    if valid[t] and valid[mine] then return t ~= mine end
    return true
end

local function myModel()
    if Participants then
        local ok, ch = pcall(Participants.Character, lp)
        if ok and ch and ch.Parent then return ch end
    end
    if lp.Character and lp.Character.Parent then return lp.Character end
    for _, m in ipairs(scanRigs()) do
        if m.Name == lp.Name then return m end
    end
    return nil
end
S.myModel = myModel

local function teamOf(m)
    local p = Players:FindFirstChild(m.Name) or Players:GetPlayerFromCharacter(m)
    if p and p:IsA("Player") then
        local ta = p:GetAttribute("Team")
        if ta ~= nil then return tostring(ta) end
        if p.Team then return p.Team.Name end
    end
    local a = m:GetAttribute("Team") or m:GetAttribute("team") or m:GetAttribute("Side")
    if a ~= nil then return tostring(a) end
    if p and p:IsA("Player") then
        local pa = p:GetAttribute("Team") or p:GetAttribute("Side")
        if pa ~= nil then return tostring(pa) end
    end
    local par = m.Parent
    if par and par ~= workspace then return par.Name end
    return nil
end

-- {model, enemy, player}
-- a ghost = a character model the game keeps around for anti-ESP: its body is not drawn (fully transparent),
-- or it carries a hidden / dormant style flag
local function ghost(m)
    for _, k in ipairs({"Dormant", "Culled", "Hidden", "Invisible", "Occluded"}) do
        if m:GetAttribute(k) == true then return true end
    end
    local seen = false
    for _, n in ipairs({"Head", "UpperTorso", "Torso", "LowerTorso"}) do
        local p = m:FindFirstChild(n)
        if p and p:IsA("BasePart") then
            seen = true
            if p.Transparency < 0.99 then return false end
        end
    end
    return seen
end
S.ghost = ghost
local function models()
    local out = {}
    if Participants then
        local ok = pcall(function()
            for _, p in Participants.GetAll() do
                pcall(function()
                    if p ~= lp and Participants.IsAlive(p) then
                        local ch = Participants.Character(p)
                        if ch and typeof(ch) == "Instance" and ch:IsDescendantOf(workspace) and not ghost(ch) then
                            out[#out + 1] = {ch, isEnemy(p), (typeof(p) == "Instance" and p:IsA("Player")) and p or nil}
                        end
                    end
                end)
            end
        end)
    end
    if #out > 0 then return out end
    local have = {}
    local mine = myModel()
    local myTeam = lp:GetAttribute("Team")
    myTeam = (myTeam ~= nil and tostring(myTeam)) or (lp.Team and lp.Team.Name) or (mine and teamOf(mine))
    local dm = workspace:GetAttribute("Gamemode") == "Deathmatch"
    -- the world scan is heavier, so it is reused for a few frames
    if not S.rigCache or tick() - (S.rigCacheAt or 0) > 0.35 then
        S.rigCache, S.rigCacheAt = scanRigs(), tick()
    end
    for _, m in ipairs(S.rigCache) do
        local dbgF = workspace:FindFirstChild("Debris")
        if m.Parent and m ~= mine and m.Name ~= lp.Name and not have[m]
            and not (dbgF and m:IsDescendantOf(dbgF)) and m:GetAttribute("Dead") ~= true and m:GetAttribute("Ragdolled") ~= true
            and (tonumber(m:GetAttribute("Health")) or 1) > 0 and m:FindFirstChild("HumanoidRootPart")
            and Players:GetPlayerFromCharacter(m) ~= nil and not ghost(m) then
            local p = Players:GetPlayerFromCharacter(m) or Players:FindFirstChild(m.Name)
            local enemy
            if dm then
                enemy = true
            elseif p and p:IsA("Player") and p:GetAttribute("Team") ~= nil then
                enemy = isEnemy(p)
            else
                local t = teamOf(m)
                enemy = (myTeam == nil or t == nil) or (t ~= myTeam)
            end
            out[#out + 1] = {m, enemy, (p and p:IsA("Player")) and p or nil}
        end
    end
    return out
end

local function alive(m)
    if m:GetAttribute("Dead") == true or m:GetAttribute("Ragdolled") == true then return nil end
    local ha = tonumber(m:GetAttribute("Health"))
    if ha and ha <= 0 then return nil end
    local r = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso")
        or m:FindFirstChild("Head") or m:FindFirstChildWhichIsA("BasePart", true)
    if not r then return nil end
    local h = m:FindFirstChildOfClass("Humanoid")
    local hp = tonumber(m:GetAttribute("Health"))
    local mx = tonumber(m:GetAttribute("MaxHealth"))
    local plr = Players:GetPlayerFromCharacter(m) or Players:FindFirstChild(m.Name)
    if hp == nil and plr and typeof(plr) == "Instance" and plr:IsA("Player") then
        hp = tonumber(plr:GetAttribute("Health"))
        mx = mx or tonumber(plr:GetAttribute("MaxHealth"))
    end
    if hp == nil and h and h.Health > 0 then hp, mx = h.Health, h.MaxHealth end
    hp = hp or 100
    -- the game's own list already says they're alive; a 0 here is just their humanoid not being used
    if hp <= 0 then hp = mx or 100 end
    return r, hp, mx or 100
end

local HEAD_FIRST = {"Head", "UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"}
local BODY_FIRST = {"UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart", "Head", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"}
local function aimPart(m)
    local torso = m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso") or m:FindFirstChild("HumanoidRootPart")
    if not CFG.hbHead then return torso or m:FindFirstChild("Head") end
    return m:FindFirstChild("Head") or torso
end
local HB = {
    Head = {"Head"},
    Torso = {"UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart"},
    Arms = {"LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand", "Left Arm", "Right Arm"},
    Legs = {"LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "Left Leg", "Right Leg"},
}
local function aimPoints(m)
    local out = {}
    for _, g in ipairs({"Head", "Torso", "Arms", "Legs"}) do
        if CFG["hb" .. g] then
            for _, n in ipairs(HB[g]) do
                local p = m:FindFirstChild(n)
                if p and p:IsA("BasePart") then out[#out + 1] = p end
            end
        end
    end
    if #out == 0 then out[1] = aimPart(m) end
    return out
end

local rayP = RaycastParams.new()
rayP.FilterType = Enum.RaycastFilterType.Exclude
local igFrame, igList = -1, {}
local visCache = setmetatable({}, {__mode = "k"})
local function visible(part, m)
    local vc = visCache[part]
    if vc and tick() - vc[1] < 0.15 then return vc[2] end
    local v = (function()
    local f = S.frame or 0
    if igFrame ~= f then
        igFrame = f
        igList = {cam}
        local mm = myModel()
        if mm then igList[#igList + 1] = mm end
        for _, it in ipairs(S.models or {}) do igList[#igList + 1] = it[1] end
        local dbg = workspace:FindFirstChild("Debris")
        if dbg then igList[#igList + 1] = dbg end
    end
    rayP.FilterDescendantsInstances = igList
    local o = cam.CFrame.Position
    local hit = workspace:Raycast(o, part.Position - o, rayP)
    return hit == nil or hit.Instance:IsDescendantOf(m)
    end)()
    visCache[part] = {tick(), v}
    return v
end

local RayMod, RayIgnore
task.spawn(function()
ident()
    pcall(function() RayMod = require(RS:WaitForChild("Shared", 10):WaitForChild("Raycast", 10)) end)
    pcall(function() RayIgnore = require(RS:WaitForChild("Components", 10):WaitForChild("Common", 10):WaitForChild("GetRayIgnore", 10)) end)
end)
local penCache = {}
local WDB = {}
local function weaponDamage()
    local w = currentWeapon()
    if not w then return 30 end
    if WDB[w] == nil then
        WDB[w] = 30
        pcall(function()
            local mod = RS.Database.Custom.Weapons:FindFirstChild(w)
            local t = mod and require(mod)
            if type(t) == "table" then
                WDB[w] = tonumber(t.Damage) or tonumber(t.BaseDamage) or (type(t.Damage) == "table" and tonumber(t.Damage.Base)) or 30
            end
        end)
    end
    return WDB[w]
end
local thickP = RaycastParams.new()
thickP.FilterType = Enum.RaycastFilterType.Exclude
-- how thick the walls between you and the part are (enter on the way there, leave on the way back)
local function wallThickness(o, target, m)
    local ig = {cam}
    local me = myModel()
    if me then ig[#ig + 1] = me end
    local total, from, guard = 0, o, 0
    while guard < 8 do
        guard = guard + 1
        thickP.FilterDescendantsInstances = ig
        local hit = workspace:Raycast(from, target - from, thickP)
        if not hit or hit.Instance:IsDescendantOf(m) then return total end
        local back = workspace:Raycast(target, hit.Position - target, thickP)
        local exitP = (back and back.Instance == hit.Instance) and back.Position or hit.Position
        total = total + (exitP - hit.Position).Magnitude
        ig[#ig + 1] = hit.Instance
        from = exitP
    end
    return total
end
local function penetrable(part, m, minDmg)
    -- Load the game's own penetration raycaster lazily as well as asynchronously;
    -- this avoids permanently disabling Auto Wall if the first load races startup.
    if not (RayMod and type(RayMod.castThroughDistance) == "function") then
        pcall(function()
            RayMod = require(RS:WaitForChild("Shared"):WaitForChild("Raycast"))
        end)
    end
    if not (RayMod and type(RayMod.castThroughDistance) == "function") then
        return false
    end
    if not (part and part:IsA("BasePart") and m and part:IsDescendantOf(m)) then
        return false
    end
    local key = part
    local c = penCache[key]
    if c and tick() - c.t < 0.04 then return c.v and (c.dmg or 0) >= (minDmg or 0) end
    local o = cam.CFrame.Position
    local ig = {}
    pcall(function() ig = RayIgnore and RayIgnore() or {} end)
    if type(ig) ~= "table" then ig = {} end
    -- Always ignore our own character and camera/viewmodel, never the target.
    local own = myModel()
    if own then
        local found = false
        for _, inst in ipairs(ig) do if inst == own then found = true break end end
        if not found then ig[#ig + 1] = own end
    end
    if cam then
        local found = false
        for _, inst in ipairs(ig) do if inst == cam then found = true break end end
        if not found then ig[#ig + 1] = cam end
    end
    local pen = 0
    pcall(function()
        local w = S.curWeapon and S.curWeapon()
        local props = w and w.Properties
        local pp = type(props) == "table" and tonumber(props.Penetration)
        if pp then pen = math.max(0, pp) end
    end)
    local wallPower = tonumber(CFG.wallPower) or 1
    wallPower = math.clamp(wallPower, 0, 3)
    -- Signature: origin, direction vector, extra penetration, exclude list, target model.
    -- The game's raycaster decides which materials/thicknesses are actually penetrable.
    local ok, hits = pcall(RayMod.castThroughDistance, o, part.Position - o, pen * wallPower, ig, m)
    local v, walls = false, 0
    if ok and type(hits) == "table" then
        for _, h in ipairs(hits) do
            if h.instance and h.instance:IsDescendantOf(m) then
                v = true
                break
            end
            walls = walls + 1
        end
    end
    -- Do not use wallThickness as a fallback: it can incorrectly mark
    -- non-penetrable materials or multiple surfaces as shoot-through.
    -- Only the game's penetration raycaster can authorize this target.
    -- every surface the bullet goes in or out of costs about a quarter of the damage
    local dmg = weaponDamage() * ((part.Name == "Head") and 4 or 1) * (0.75 ^ walls)
    penCache[key] = {t = tick(), v = v, dmg = dmg}
    return v and dmg >= (minDmg or 0)
end

-- the shot packet itself (Remotes.Inventory.ShootWeapon): every bullet in it is pointed from its own Origin exactly at the part.
-- This is what the server checks, so it no longer depends on the camera trick lining up.
S.fixShot = function(pkt)
    do return end
    local t = S.aimT
    if not (CFG.silent and t and t.Parent) then return end
    if S.shotPart then
        local okP, np = pcall(S.shotPart, t)
        if okP then t = np end
    end
    if not t then return end
    S.shotTarget = S.shotTarget and S.shotTarget.m == t.Parent and S.shotTarget or {m = t.Parent, part = t.Name, at = tick()}
    local o = workspace.CurrentCamera.CFrame.Position
    for _, b in ipairs(pkt.Bullets) do
        if type(b) == "table" and typeof(b.Origin) == "Vector3" and typeof(b.Direction) == "Vector3" then
            local mag = b.Direction.Magnitude
            if mag > 1.5 then S.dirMag = mag end
            local d = t.Position - o
            if d.Magnitude > 0.01 then
                b.Origin = o
                b.Direction = d.Unit * ((mag > 1.5) and mag or (S.dirMag or 1000))
            end
        end
    end
end
-- the ShootWeapon sender lives in NetworkRemotes (or the older Database.Security.Remotes): every module there is searched
-- for a ShootWeapon table with a Send function, and each one found is hooked once
if hookfunction and newcclosure and S.sendHooked ~= 2 then
    S.sendHooked = 2
    task.spawn(function()
        local done = {}
        local function hookSend(fn)
            if done[fn] then return end
            done[fn] = true
            S.shootSendFn = S.shootSendFn or fn
            local orig
            orig = hookfunction(fn, newcclosure(function(a, b2, ...)
                -- called as Send(packet) or as Send(self, packet)
                local pkt = (type(a) == "table" and type(a.Bullets) == "table") and a or ((type(b2) == "table" and type(b2.Bullets) == "table") and b2 or nil)
                if pkt and S.on and S.fixShot then pcall(S.fixShot, pkt) end
                return orig(a, b2, ...)
            end))
        end
        local function scan(t, depth, seen)
            if type(t) ~= "table" or depth > 4 or seen[t] then return end
            seen[t] = true
            for k, v in pairs(t) do
                if type(v) == "table" then
                    if string.find(string.lower(tostring(k)), "shoot", 1, true) then
                        for _, fname in ipairs({"Send", "send", "Fire", "fire", "FireServer"}) do
                            if type(rawget(v, fname)) == "function" then pcall(hookSend, rawget(v, fname)) end
                        end
                    end
                    scan(v, depth + 1, seen)
                end
            end
        end
        local function tryModule(mod)
            if not (mod and mod:IsA("ModuleScript")) then return end
            local ok, t = pcall(require, mod)
            if ok then scan(t, 0, {}) end
        end
        local roots = {}
        local nr = RS:WaitForChild("NetworkRemotes", 15) or RS:FindFirstChild("NetworkRemotes", true)
        if nr then roots[#roots + 1] = nr end
        pcall(function() roots[#roots + 1] = RS.Database.Security.Remotes end)
        for _, root in ipairs(roots) do
            tryModule(root)
            for _, d in ipairs(root:GetDescendants()) do tryModule(d) end
        end
    end)
end
-- and if the shot goes out through a ShootWeapon RemoteEvent with the packet as a table, it is fixed there too
if hookmetamethod and getnamecallmethod and checkcaller and newcclosure and not S.shootRemoteHooked then
    S.shootRemoteHooked = true
    local oldNC
    oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if not checkcaller() and typeof(self) == "Instance" and string.find(self.Name, "Shoot", 1, true) then
            local m = getnamecallmethod()
            if (m == "FireServer" or m == "UnreliableFireServer" or m == "InvokeServer") and S.on and S.fixShot then
                for i = 1, select("#", ...) do
                    local a = select(i, ...)
                    if type(a) == "table" and type(a.Bullets) == "table" then pcall(S.fixShot, a) end
                end
            end
        end
        return oldNC(self, ...)
    end))
end

-- right when the gun fires: keep the part if it can be hit, else another hittable part of the same player, else no swap
S.shotPart = function(t)
    local m = t and t.Parent
    if not m then return nil end
    if visible(t, m) or (CFG.autoWall and penetrable(t, m, wval("awd", 0))) then return t end
    for _, p in ipairs(aimPoints(m)) do
        if p ~= t and (visible(p, m) or (CFG.autoWall and penetrable(p, m, wval("awd", 0)))) then return p end
    end
    return nil
end
-- each model's speed, smoothed (to lead running targets and long shots)
S.vel = setmetatable({}, {__mode = "k"})
local lastPos = setmetatable({}, {__mode = "k"})
local function trackVelocity(dt)
    if dt <= 0 then return end
    for _, it in ipairs(S.models or {}) do
        local m = it[1]
        local r = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
        if r then
            local p = r.Position
            local lp0 = lastPos[m]
            if lp0 then
                local v = (p - lp0) / dt
                if v.Magnitude > 80 then v = Vector3.zero end
                S.vel[m] = (S.vel[m] or v):Lerp(v, 0.3)
            end
            lastPos[m] = p
        end
    end
end
S.trackVelocity = trackVelocity
-- the point to shoot at: the part, moved ahead by its speed times the prediction time
S.aimPoint = function(part)
    do return part.Position end
    local m = part and part.Parent
    local v = m and S.vel[m]
    if not v or Vector3.new(v.X, 0, v.Z).Magnitude < 3 then return part.Position end
    local ping = 0.05
    pcall(function() ping = lp:GetNetworkPing() end)
    local t = math.clamp(ping * (CFG.predMul or 1), 0, 0.4)
    return part.Position + Vector3.new(v.X, v.Y * 0.4, v.Z) * t
end
local function pick(fov, rage)
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local best, bestD, bestScore = nil, fov, math.huge
    for _, it in ipairs(S.models or models()) do
        local m, enemy = it[1], it[2]
        -- a real, living body in the world (not a leftover / see-through ghost copy)
        local real = m:IsDescendantOf(workspace) and m:GetAttribute("Dead") ~= true and m:GetAttribute("Ragdolled") ~= true and not ghost(m)
        if enemy and real and alive(m) then
            local main = aimPart(m)
            local sp, on
            if main then sp, on = cam:WorldToViewportPoint(main.Position) end
            if main and ((on and sp.Z > 0) or rage) then
                -- on screen: distance to the crosshair; behind you (rage): far down the list, nearest first
                local d = (on and sp.Z > 0) and (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    or (100000 + (main.Position - cam.CFrame.Position).Magnitude)
                if d < fov or rage then
                    -- multipoint: the first point that can be hit (seen, or shot through with auto wall)
                    local chosen
                    for _, part in ipairs(aimPoints(m)) do
                        if not CFG.wallCheck or visible(part, m) or (CFG.autoWall and penetrable(part, m, wval("awd", 0)))
 then
                            chosen = part
                            break
                        end
                    end
                    if chosen then
                        local score = d
                        if CFG.silentPrio == "Distance" then
                            score = (chosen.Position - cam.CFrame.Position).Magnitude
                        elseif CFG.silentPrio == "Health" then
                            local _, hp = alive(m)
                            score = (hp or 100) * 10 + d * 0.01
                        end
                        if score < bestScore then best, bestD, bestScore = chosen, d, score end
                    end
                end
            end
        end
    end
    return best
end

-- while the gun is working out a shot, any ray it asks the camera for points at the target
if hookmetamethod and getnamecallmethod and checkcaller and newcclosure and not S.vprHooked then
    S.vprHooked = true
    local oldV
    oldV = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local t = S.inShot
        if t and not checkcaller() and typeof(self) == "Instance" and self:IsA("Camera") then
            local m = getnamecallmethod()
            if m == "ViewportPointToRay" or m == "ScreenPointToRay" then
                local r = oldV(self, ...)
                if typeof(r) == "Ray" and t.Parent then
                    local goal = (S.aimPoint and S.aimPoint(t)) or t.Position
                    local d = goal - r.Origin
                    if d.Magnitude > 0.01 then return Ray.new(r.Origin, d.Unit * r.Direction.Magnitude) end
                end
                return r
            end
        end
        return oldV(self, ...)
    end))
end

------------------------------------------------------------------ silent aim (hooks go in once per server)
if S.hookVer ~= 8 and hookmetamethod and getnamecallmethod and checkcaller then
    S.hookVer = 8
    S.hooked = true
    local function nearMe(origin)
        return (origin - workspace.CurrentCamera.CFrame.Position).Magnitude < 2.5
    end
    local function shotRay(origin, dir)
        if dir.Magnitude < 20 or not nearMe(origin) then return false end
        return dir.Unit:Dot(workspace.CurrentCamera.CFrame.LookVector) > 0.5
    end
    local function aimDir(origin, len)
        local t = S.target
        if not t or not t.Parent then return nil end
        local cfg = S.cfg
        if cfg.hitChance < 100 and math.random(1, 100) > cfg.hitChance then return nil end
        return (t.Position - origin).Unit * len
    end
    local gcs = getcallingscript
    local function fromBullet(names)
        if not gcs then return true end
        local ok, sc = pcall(gcs)
        if not ok or not sc then return false end
        local n = sc.Name
        for _, w in ipairs(names) do
            if n == w then return true end
        end
        return false
    end
    local oldNc
    oldNc = hookmetamethod(game, "__namecall", function(self, ...)
        if S.on and S.cfg.silent and S.target and not checkcaller() then
            local m = getnamecallmethod()
            if m == "Raycast" and self == workspace and fromBullet({"Raycast", "Bullet"}) then
                local o, d = ...
                if typeof(o) == "Vector3" and typeof(d) == "Vector3" and shotRay(o, d) then
                    local nd = aimDir(o, d.Magnitude)
                    if nd then
                        local args = table.pack(...)
                        args[2] = nd
                        return oldNc(self, table.unpack(args, 1, args.n))
                    end
                end
            elseif (m == "Blockcast" or m == "Shapecast") and self == workspace then
                local a1, a2, a3 = ...
                local o = typeof(a1) == "CFrame" and a1.Position or (typeof(a1) == "Instance" and a1:IsA("BasePart") and a1.Position) or nil
                if o and typeof(a3) == "Vector3" and shotRay(o, a3) then
                    local nd = aimDir(o, a3.Magnitude)
                    if nd then
                        local args = table.pack(...)
                        args[3] = nd
                        return oldNc(self, table.unpack(args, 1, args.n))
                    end
                elseif o and typeof(a2) == "Vector3" and shotRay(o, a2) then
                    local nd = aimDir(o, a2.Magnitude)
                    if nd then
                        local args = table.pack(...)
                        args[2] = nd
                        return oldNc(self, table.unpack(args, 1, args.n))
                    end
                end
            elseif m == "Spherecast" and self == workspace then
                local o, r, d = ...
                if typeof(o) == "Vector3" and typeof(d) == "Vector3" and shotRay(o, d) then
                    local nd = aimDir(o, d.Magnitude)
                    if nd then
                        local args = table.pack(...)
                        args[3] = nd
                        return oldNc(self, table.unpack(args, 1, args.n))
                    end
                end
            elseif m == "FindPartOnRayWithIgnoreList" or m == "FindPartOnRayWithWhitelist" or m == "FindPartOnRay" then
                local ray = ...
                if typeof(ray) == "Ray" and shotRay(ray.Origin, ray.Direction) then
                    local nd = aimDir(ray.Origin, ray.Direction.Magnitude)
                    if nd then
                        local args = table.pack(...)
                        args[1] = Ray.new(ray.Origin, nd)
                        return oldNc(self, table.unpack(args, 1, args.n))
                    end
                end
            elseif (m == "ViewportPointToRay" or m == "ScreenPointToRay") and typeof(self) == "Instance" and self.ClassName == "Camera"
                and fromBullet({"Bullet"}) then
                local x, y = ...
                local vp = self.ViewportSize
                if type(x) == "number" and type(y) == "number" and math.abs(x - vp.X / 2) < 60 and math.abs(y - vp.Y / 2) < 60 then
                    local ray = oldNc(self, ...)
                    local nd = aimDir(ray.Origin, 1)
                    if nd then return Ray.new(ray.Origin, nd) end
                    return ray
                end
            end
        end
        return oldNc(self, ...)
    end)
    local mouse = lp:GetMouse()
    S.lastFire, S.fireDown = 0, false
    UIS.InputBegan:Connect(function(i)
ident()
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            S.lastFire, S.fireDown = tick(), true
        end
    end)
    UIS.InputEnded:Connect(function(i)
ident()
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            S.lastFire, S.fireDown = tick(), false
        end
    end)
    local function bendOne(v, camPos, aim, look)
        local t = typeof(v)
        if t == "CFrame" and (v.Position - camPos).Magnitude < 12 then
            return CFrame.lookAt(v.Position, aim), true
        elseif t == "Vector3" then
            local mag = v.Magnitude
            if math.abs(mag - 1) < 0.02 and v:Dot(look) > 0.9 then
                return (aim - camPos).Unit, true
            end
            if mag > 10 and v.Unit:Dot(look) > 0.97 then
                return (aim - camPos).Unit * mag, true
            end
            if (v - camPos).Magnitude > 6 and (v - camPos).Unit:Dot(look) > 0.97 then
                return aim, true
            end
        end
        return v, false
    end
    -- walks the shot data (3 levels deep); hit records ({instance, position, normal}) are left as the raycast made them
    local function bendAll(args, n, camPos, aim, look, depth, seen)
        local changed = false
        for k = 1, n do
            local v = args[k]
            if type(v) == "table" then
                if depth > 0 and not seen[v] and rawget(v, "instance") == nil and rawget(v, "normal") == nil then
                    seen[v] = true
                    for key, x in pairs(v) do
                        if type(x) == "table" then
                            local box = {x}
                            if bendAll(box, 1, camPos, aim, look, depth - 1, seen) then changed = true end
                        else
                            local nv, ch = bendOne(x, camPos, aim, look)
                            if ch then
                                v[key] = nv
                                changed = true
                            end
                        end
                    end
                end
            else
                local nv, ch = bendOne(v, camPos, aim, look)
                if ch then
                    args[k] = nv
                    changed = true
                end
            end
        end
        return changed
    end
    local function shouldBend()
        if not (S.on and S.cfg.silent and S.target and S.target.Parent) then return false end
        if not (S.fireDown or tick() - (S.lastFire or 0) < 0.6) then return false end
        local cfg = S.cfg
        return cfg.hitChance >= 100 or math.random(1, 100) <= cfg.hitChance
    end
    local function bendPack(args)
        local c = workspace.CurrentCamera
        return bendAll(args, args.n, c.CFrame.Position, S.target.Position, c.CFrame.LookVector, 3, {})
    end
end

------------------------------------------------------------------ the movement command: anti-aim and the look for silent
-- MovementV2 builds one command per tick in CommandStream.sample(input) -> canonicalize -> prediction AND the packet to the
-- server use that same command. Changing the look right there keeps client and server in agreement (no corrections, no
-- Diagnostics reports). MoveVector is turned back by the same angle so you still run where you are going.
do
    S.aaState = S.aaState or {spin = 0}
    local PM
    local function rot2(v, a)
        local c, sn = math.cos(a), math.sin(a)
        return Vector2.new(v.X * c - v.Y * sn, v.X * sn + v.Y * c)
    end
    local function wrap(orig, val)
        if orig > math.pi then return val % (2 * math.pi) end
        return (val + math.pi) % (2 * math.pi) - math.pi
    end
    local function fixMove(mv, yaw0, yaw1)
        local d = yaw1 - yaw0
        if math.abs(d) < 1e-5 then return mv end
        local isV3 = typeof(mv) == "Vector3"
        local v2 = isV3 and Vector2.new(mv.X, mv.Z) or mv
        if typeof(v2) ~= "Vector2" or v2.Magnitude < 1e-4 then return mv end
        local a, b = rot2(v2, d), rot2(v2, -d)
        local pick = b
        if PM and PM.moveVectorToWorld then
            local ok, w0 = pcall(PM.moveVectorToWorld, mv, yaw0)
            local okA, wa = pcall(PM.moveVectorToWorld, isV3 and Vector3.new(a.X, mv.Y, a.Y) or a, yaw1)
            local okB, wb = pcall(PM.moveVectorToWorld, isV3 and Vector3.new(b.X, mv.Y, b.Y) or b, yaw1)
            if ok and okA and okB then pick = ((wa - w0).Magnitude <= (wb - w0).Magnitude) and a or b end
        end
        return isV3 and Vector3.new(pick.X, mv.Y, pick.Y) or pick
    end
    S.aaDebug = S.aaDebug or {calls = 0, keys = "", hooked = false, changed = 0, rejected = 0}
    local function findKeys(input)
        local yk, pk, mk, ck
        for k, v in pairs(input) do
            if type(k) == "string" then
                local l = string.lower(k)
                if type(v) == "number" and string.find(l, "yaw", 1, true) and not yk then yk = k end
                if type(v) == "number" and (string.find(l, "pitch", 1, true) or string.find(l, "vertical", 1, true)) and not pk then pk = k end
                if (typeof(v) == "Vector2" or typeof(v) == "Vector3") and string.find(l, "move", 1, true) and not mk then mk = k end
                if typeof(v) == "CFrame" and (string.find(l, "look", 1, true) or string.find(l, "camera", 1, true) or string.find(l, "aim", 1, true)) and not ck then ck = k end
                if typeof(v) == "Vector3" and (string.find(l, "look", 1, true) or string.find(l, "aim", 1, true) or string.find(l, "dir", 1, true)) and not string.find(l, "move", 1, true) and not S.lookVecKey then S.lookVecKeyTmp = k end
            end
        end
        if rawget(input, "LookYaw") ~= nil then yk = "LookYaw" end
        if rawget(input, "VerticalLook") ~= nil then pk = "VerticalLook" end
        if rawget(input, "MoveVector") ~= nil then mk = "MoveVector" end
        return yk, pk, mk, ck
    end
    local function newInput(input)
        local dbg = S.aaDebug
        dbg.calls = dbg.calls + 1
        local moveOut = S.moveCmd and S.moveCmd(input)
        if dbg.keys == "" then
            local ks = {}
            for k, v in pairs(input) do ks[#ks + 1] = tostring(k) .. ":" .. typeof(v) end
            table.sort(ks)
            dbg.keys = table.concat(ks, " ")
        end
        S.lookVecKeyTmp = nil
        local yk, pk, mk, ck = findKeys(input)
        local vk = S.lookVecKeyTmp
        local yaw = yk and rawget(input, yk)
        local pitch = pk and rawget(input, pk)
        local camSwap = false
        if type(yaw) ~= "number" and not ck then
            local v = vk and rawget(input, vk)
            local c0 = workspace.CurrentCamera.CFrame
            if typeof(v) == "Vector3" and v.Magnitude > 0 then
                local _, y0 = CFrame.lookAt(Vector3.zero, v):ToOrientation()
                yaw = y0
            else
                -- no look in the input: the game reads the camera itself, so the camera is turned just for this sample
                local _, y0 = c0:ToOrientation()
                yaw = y0
                camSwap = true
            end
        end
        if type(yaw) ~= "number" then
            local _, y0 = rawget(input, ck):ToOrientation()
            yaw = y0
        end
        local cfg = S.cfg
        local c = workspace.CurrentCamera
        local cp, cy = c.CFrame:ToOrientation()
        local ny, np
        -- silent: while you fire, the server sees you looking right at the target
        local firing = S.fireDown or tick() - (S.lastFire or 0) < 0.25
        if cfg.silent and cfg.cmdSilent and firing and S.target and S.target.Parent then
            local tp, ty = CFrame.lookAt(c.CFrame.Position, S.target.Position):ToOrientation()
            ny = yaw + (ty - cy)
            if type(pitch) == "number" then np = pitch + (tp - cp) end
        elseif cfg.aa and cfg.aaServer then
            local st = S.aaState
            local air = S.inAir == true
            local mode, spd, pm = cfg.aaMode, cfg.aaSpeed, cfg.aaPitchMode
            if cfg.aaAir and air then mode, spd, pm = "Spin", cfg.aaAirSpeed, cfg.aaAirPitch end
            if mode == "Spin" then
                st.spin = ((st.spin or 0) + math.rad(spd * 6)) % (2 * math.pi)
                ny = yaw + st.spin
            elseif mode == "Jitter" then
                st.flip = not st.flip
                ny = yaw + (st.flip and math.rad(90) or math.rad(-90))
            else
                ny = yaw + math.pi
            end
            if type(pitch) == "number" and pm ~= "None" then
                np = (pm == "Down" and math.rad(-89)) or (pm == "Up" and math.rad(89)) or math.rad(math.random(-89, 89))
            end
            st.offset, st.pitchNow = ny - yaw, np
        end

        if not ny then
            if moveOut then dbg.changed = dbg.changed + 1 end
            return moveOut
        end
        local out = moveOut or table.clone(input)
        local newYaw = wrap(yaw, ny)
        if yk then out[yk] = newYaw end
        if vk and not yk and not ck then
            local v = rawget(input, vk)
            if typeof(v) == "Vector3" then
                local p0 = math.asin(math.clamp(v.Unit.Y, -1, 1))
                local p1 = np or p0
                out[vk] = (CFrame.fromOrientation(p1, newYaw, 0).LookVector) * v.Magnitude
            end
        end
        if camSwap then
            local c = workspace.CurrentCamera
            local old = c.CFrame
            local p0 = old:ToOrientation()
            c.CFrame = CFrame.new(old.Position) * CFrame.fromOrientation(np and math.clamp(np, math.rad(-89), math.rad(89)) or p0, newYaw, 0)
            task.defer(function() c.CFrame = old end)
        end
        if pk and np then out[pk] = math.clamp(np, math.rad(-89), math.rad(89)) end
        if ck then
            local cf = rawget(input, ck)
            local p0 = cf:ToOrientation()
            local p1 = (np and pk == nil) and math.clamp(p0 + (np - (pitch or p0)), math.rad(-89), math.rad(89)) or p0
            out[ck] = CFrame.new(cf.Position) * CFrame.fromOrientation(p1, select(2, cf:ToOrientation()) + (ny - yaw), 0)
        end
        local mv = mk and rawget(out, mk)
        if mv ~= nil then out[mk] = fixMove(mv, yaw, newYaw) end
        dbg.changed = dbg.changed + 1
        return out
    end
    S.cmdInput = newInput
    -- bhop: release jump in the air, press it on the first ground tick (clean CS hop, every landing)
    -- strafe: in the air, side-move the way the view is turning; air strafe also turns the view for you
    local lastCy, airSide, sideAt = nil, 1, 0
    S.moveCmd = function(input)
        local cfg = S.cfg
        -- the command path only if the input really carries a jump flag; otherwise the input path below does it
        local hasJump = false
        for k, v in pairs(input) do
            if type(k) == "string" and type(v) == "boolean" and string.find(string.lower(k), "jump", 1, true) then hasJump = true break end
        end
        S.cmdHasJump = hasJump
        if not hasJump then return nil end
        if not (cfg.bhop or cfg.autoStrafe or cfg.airStrafe) then return nil end
        local jk, mk
        for k, v in pairs(input) do
            if type(k) == "string" then
                local l = string.lower(k)
                if type(v) == "boolean" and string.find(l, "jump", 1, true) and not jk then jk = k end
                if (typeof(v) == "Vector2" or typeof(v) == "Vector3") and string.find(l, "move", 1, true) and not mk then mk = k end
            end
        end
        local m = S.myModel and S.myModel()
        local root = m and m.PrimaryPart
        if not root then return nil end
        local onGround
        if S.RK then
            local okG, g, known = pcall(S.RK.isOnGround, m)
            if okG and known then onGround = g end
        end
        if onGround == nil then
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = {m, workspace.CurrentCamera}
            onGround = workspace:Raycast(root.Position, Vector3.new(0, -3.6, 0), rp) ~= nil
        end
        local out
        if cfg.bhop and jk then
            local holding = rawget(input, jk) == true
            if UIS.TouchEnabled and not UIS.KeyboardEnabled then
                local v = root.AssemblyLinearVelocity
                holding = holding or Vector2.new(v.X, v.Z).Magnitude > 4
            end
            if holding then
                out = out or table.clone(input)
                -- a missed hop now and then, like a person
                if onGround and math.random(1, 100) <= cfg.bhopMiss then
                    out[jk] = false
                else
                    out[jk] = onGround
                end
            end
        end
        local _, cy = workspace.CurrentCamera.CFrame:ToOrientation()
        local turn = lastCy and (cy - lastCy) or 0
        if turn > math.pi then turn = turn - 2 * math.pi elseif turn < -math.pi then turn = turn + 2 * math.pi end
        lastCy = cy
        if mk and not onGround and (cfg.autoStrafe or cfg.airStrafe) then
            local side
            if cfg.airStrafe then
                side = S.airDir or airSide
            elseif math.abs(turn) > 0.0005 * cfg.strafeSens then
                side = turn > 0 and -1 or 1
            end
            if side then
                out = out or table.clone(input)
                local mv = rawget(input, mk)
                if typeof(mv) == "Vector3" then
                    out[mk] = Vector3.new(side, mv.Y, 0)
                else
                    out[mk] = Vector2.new(side, 0)
                end
            end
        end
        return out
    end
    local turned
    local spin, flip = 0, false
    RunService:BindToRenderStep("ZenithBS2AAShow", Enum.RenderPriority.Last.Value + 20, function(dt)
ident()
        turned = nil
        if not running or not CFG.aa then return end
        local m = myModel()
        local root = m and m.PrimaryPart
        local dead = m and (m:GetAttribute("Dead") == true)
        if not dead and Participants then
            local okA, a = pcall(Participants.IsAlive, lp)
            if okA and a == false then dead = true end
        end
        if not root or dead then
            if S.fakeHead then pcall(function() S.fakeHead:Destroy() end) end
            if S.hidHead then pcall(function() S.hidHead.LocalTransparencyModifier = 0 end) end
            S.fakeHead, S.fakeSrc, S.hidHead = nil, nil, nil
            return
        end
        local off
        local air = false
        if S.RK then
            local okG, g, known = pcall(S.RK.isOnGround, m)
            if okG and known then air = not g end
        end
        S.inAir = air
        if S.aaState and S.aaState.offset and S.sampleHooked then
            off = S.aaState.offset
        elseif CFG.aaAir and air then
            spin = (spin + math.rad(CFG.aaAirSpeed * 6) * 60 * (dt or 1 / 60)) % (2 * math.pi)
            off = spin
        elseif CFG.aaMode == "Spin" then
            spin = (spin + math.rad(CFG.aaSpeed * 6) * 60 * (dt or 1 / 60)) % (2 * math.pi)
            off = spin
        elseif CFG.aaMode == "Jitter" then
            flip = not flip
            off = flip and math.rad(90) or math.rad(-90)
        else
            off = math.pi
        end
        local before = m:GetPivot()
        turned = {m, before}
        local pm = (CFG.aaAir and air) and CFG.aaAirPitch or CFG.aaHead
        local pitch = 0
        if pm == "Down" then
            pitch = -1
        elseif pm == "Up" then
            pitch = 1
        elseif pm == "Jitter" then
            S.aaState = S.aaState or {}
            S.aaState.pflip = not S.aaState.pflip
            pitch = S.aaState.pflip and 1 or -1
        elseif pm == "Random" then
            pitch = math.random() * 2 - 1
        end
        local neck
        if pitch ~= 0 then
            if S.neckOf ~= m then
                S.neckOf, S.neckJ = m, nil
                for _, d in ipairs(m:GetDescendants()) do
                    if d:IsA("Motor6D") and d.Name == "Neck" then S.neckJ = d break end
                end
            end
            neck = S.neckJ
        end
        local lean = (pitch ~= 0) and CFrame.Angles(math.rad(neck and 16 or 26) * pitch, 0, 0) or CFrame.new()
        pcall(function() m:PivotTo(before * CFrame.Angles(0, off, 0) * lean) end)
        if neck then
            turned[3] = {{neck, neck.C0}}
            pcall(function() neck.C0 = neck.C0 * CFrame.Angles(math.rad(55) * pitch, 0, 0) end)
        end
        if S.fakeHead or S.hidHead then
            if S.fakeHead then pcall(function() S.fakeHead:Destroy() end) end
            if S.hidHead then pcall(function() S.hidHead.LocalTransparencyModifier = 0 end) end
            S.fakeHead, S.fakeSrc, S.hidHead = nil, nil, nil
        end
    end)
    RunService:BindToRenderStep("ZenithBS2AAShowBack", Enum.RenderPriority.First.Value, function()
ident()
        if not CFG.aa and (S.fakeHead or S.hidHead) then
            if S.fakeHead then pcall(function() S.fakeHead:Destroy() end) end
            if S.hidHead then pcall(function() S.hidHead.LocalTransparencyModifier = 0 end) end
            S.fakeHead, S.fakeSrc, S.hidHead = nil, nil, nil
        end
        if turned then
            pcall(function() turned[1]:PivotTo(turned[2]) end)
            for _, jt in ipairs(turned[3] or {}) do pcall(function() jt[1].C0 = jt[2] end) end
            turned = nil
        end
    end)
    if not S.csHooked and hookfunction and newcclosure then
        task.spawn(function()
ident()
            local ok, CSm = pcall(function()
                local mv2 = RS:WaitForChild("MovementV2", 15)
                pcall(function() PM = require(mv2:WaitForChild("Simulation", 5):WaitForChild("ProvenMath", 5)) end)
                return require(mv2:WaitForChild("Runtime", 15):WaitForChild("CommandStream", 15))
            end)
            if not ok or type(CSm) ~= "table" or type(CSm.sample) ~= "function" or S.csHooked then return end
            S.csHooked = true
            S.aaDebug.hooked = true
            local orig
            orig = hookfunction(CSm.sample, newcclosure(function(self, input)
                if type(input) == "table" and S.on and S.cmdInput then
                    local okI, changed = pcall(S.cmdInput, input)
                    if okI and changed then
                        local r1, r2 = orig(self, changed)
                        if r1 ~= nil then return r1, r2 end
                        S.aaDebug.rejected = S.aaDebug.rejected + 1
                        S.aaDebug.why = tostring(r2)
                    end
                end
                return orig(self, input)
            end))
        end)
    else
        task.spawn(function()
ident()
            pcall(function() PM = require(RS.MovementV2.Simulation.ProvenMath) end)
        end)
    end
end

local CamCtl
task.spawn(function()
ident()
    pcall(function() CamCtl = require(RS:WaitForChild("Controllers", 10):WaitForChild("CameraController", 10)) end)
end)
local function setView(cf)
    local c = workspace.CurrentCamera
    c.CFrame = cf
    if CamCtl and CamCtl.setBaseCameraCFrame then pcall(CamCtl.setBaseCameraCFrame, cf) end
end
S.setView = setView

------------------------------------------------------------------ auto fire
do
    local VIM2 = game:GetService("VirtualInputManager")
    local CAS = game:GetService("ContextActionService")
    local lastInput
    UIS.InputBegan:Connect(function(i) lastInput = i end)
    local down = false
    local function press(v)
        if down == v then return end
        down = v
        S.autoFiring = v
        local vp = workspace.CurrentCamera.ViewportSize
        if not UIS.TouchEnabled then
            pcall(function() VIM2:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, v, game, 0) end)
        end
        if v and S.preAim then pcall(S.preAim) end
        pcall(function() CAS:CallFunction("Fire", v and Enum.UserInputState.Begin or Enum.UserInputState.End, lastInput) end)
    end
    local tapAt, shotAt = 0, 0
    -- the gun object the game itself uses: shoot("Primary") is what a real trigger pull calls
    local Router
    pcall(function() Router = require(RS.Database.Security.Router) end)
    local function directShot(w, t)
        local send = S.shootSendFn
        if not send then
            pcall(function()
                local R = require(RS.Database.Security.Remotes)
                send = R.Inventory.ShootWeapon.Send
            end)
        end
        if not (send and w.Identifier and t and t.Parent) then return false end
        local o = workspace.CurrentCamera.CFrame.Position
        local d = t.Position - o
        if d.Magnitude < 0.1 then return false end
        local vt
        if Router then pcall(function() vt = Router.broadcastRouter("GetRemoteViewTick") end) end
        w.ShotSeq = (w.ShotSeq or 0) + 1
        local range = math.max(S.dirMag or 0, 5000)
        if false then
            local pr = type(w.Properties) == "table" and w.Properties or {}
            range = (type(pr.Range) == "table" and tonumber(pr.Range.Max)) or tonumber(pr.Range) or tonumber(pr.MaxRange) or 1000
            range = math.max(range, d.Magnitude + 50)
        end
        local ok = pcall(send, {IsSniperScoped = w.IsSniperScoped, ShootingHand = w.ShootingHand, Identifier = w.Identifier, Seq = w.ShotSeq,
            Bullets = {{Direction = d.Unit * math.max(range, d.Magnitude + 50), Origin = o}}, ViewTick = vt})
        if ok then
            -- (ammo is left to the game: counting it here too emptied the mag early and forced a reload)
            S.lastShotAt = tick()
            S.shotTarget = {m = t.Parent, part = t.Name, at = tick()}
        end
        return ok
    end
    local reloadAt = 0
    local function weaponShoot()
        local w = S.curWeapon and S.curWeapon()
        if not (w and type(w.shoot) == "function") then return false end
        local rate = (type(w.Properties) == "table" and tonumber(w.Properties.FireRate)) or 0.1
        local now = tick()
        -- direct shots: no waiting for the gun's own shooting state, empty mag -> reload straight away
        if CFG.directShots and S.aimT then
            if (tonumber(w.Rounds) or 1) <= 0 then
                if not w.IsReloading and now - reloadAt > 0.5 then
                    reloadAt = now
                    if not (type(w.reload) == "function" and pcall(w.reload, w)) then
                        local CASr = game:GetService("ContextActionService")
                        pcall(function() CASr:CallFunction("Reload", Enum.UserInputState.Begin, nil) end)
                        task.delay(0.05, function() pcall(function() CASr:CallFunction("Reload", Enum.UserInputState.End, nil) end) end)
                    end
                end
                return true
            end
            if w.IsReloading then return true end
            if now - shotAt < rate then return true end
            local t = S.aimT
            if S.shotPart then
                local okP, np = pcall(S.shotPart, t)
                if okP then t = np end
            end
            if t then
                shotAt = now
                S.autoShotAt = now
                if directShot(w, t) then return true end
            end
        end
        if w.IsReloading or (tonumber(w.Rounds) or 1) <= 0 then return true end
        if now - shotAt < rate + 0.01 or w.IsShooting then return true end
        shotAt = now
        S.autoShotAt = now
        if S.preAim then pcall(S.preAim) end
        local ok, err = pcall(w.shoot, w, "Primary")
        if ok then
            S.dbg.fires = S.dbg.fires + 1
        else
            S.dbg.fireErr = tostring(err)
        end
        return ok
    end
    RunService.Heartbeat:Connect(function()
ident()
        if not running then
            press(false)
            return
        end
        local t = S.aimT
        local okShot = t ~= nil and t.Parent ~= nil
        if okShot and S.shotPart then
            local okP, np = pcall(S.shotPart, t)
            okShot = okP and np ~= nil
        end
        local want = (CFG.autoFire and okShot) or (S.trigWant == true)
        S.autoWant = want and true or false
        if want and not UIS:GetFocusedTextBox() then
            if weaponShoot() then return end
            -- fallback: clicks (pistols / snipers need separate clicks)
            local now = tick()
            if down and now - tapAt > 0.09 then
                press(false)
            elseif not down and now - tapAt > 0.13 then
                tapAt = now
                press(true)
            end
        else
            press(false)
        end
    end)
    S.autoFireOff = function() press(false) end
end

------------------------------------------------------------------ triggerbot: fires when the crosshair is on an enemy
do
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local onSince, fireUntil = nil, 0
    RunService.Heartbeat:Connect(function()
ident()
        if not running or not CFG.trigger then
            S.trigWant, onSince = false, nil
            return
        end
        local c = workspace.CurrentCamera
        local vp = c.ViewportSize
        local center = Vector2.new(vp.X / 2, vp.Y / 2)
        local ray = c:ViewportPointToRay(vp.X / 2, vp.Y / 2)
        local o, dir = ray.Origin, ray.Direction
        -- does the ray pass through this part's box (slightly grown so edges count)?
        local function through(p)
            local lo = p.CFrame:PointToObjectSpace(o)
            local ld = p.CFrame:VectorToObjectSpace(dir)
            local half = p.Size * 0.55
            local tmin, tmax = -math.huge, math.huge
            for _, ax in ipairs({"X", "Y", "Z"}) do
                local oo, dd, hh = lo[ax], ld[ax], half[ax]
                if math.abs(dd) < 1e-6 then
                    if oo < -hh or oo > hh then return false end
                else
                    local t1, t2 = (-hh - oo) / dd, (hh - oo) / dd
                    if t1 > t2 then t1, t2 = t2, t1 end
                    tmin, tmax = math.max(tmin, t1), math.min(tmax, t2)
                    if tmin > tmax then return false end
                end
            end
            return tmax > 0
        end
        local on = false
        for _, it in ipairs(S.models or {}) do
            local m = it[1]
            if it[2] and m.Parent then
                for _, g in ipairs({"Head", "Torso", "Arms", "Legs"}) do
                    if CFG["tb" .. g] then
                        for _, n in ipairs(HB[g]) do
                            local p = m:FindFirstChild(n)
                            if p and p:IsA("BasePart") then
                                if through(p) and (visible(p, m) or (CFG.trigWall and penetrable(p, m, 0))) then
                                    on = true
                                    break
                                end
                            end
                        end
                    end
                    if on then break end
                end
            end
            if on then break end
        end
        local now = tick()
        if on then
            onSince = onSince or now
            if now - onSince >= CFG.trigDelay / 1000 then fireUntil = now + CFG.trigHold / 1000 end
        else
            onSince = nil
        end
        S.trigWant = now < fireUntil
    end)
end

------------------------------------------------------------------ silent: the view snaps onto the target only while you are shooting, then comes back
do
    local held = false
    UIS.InputBegan:Connect(function(i)
ident()
        if i.UserInputType == Enum.UserInputType.MouseButton1 then held = true end
    end)
    UIS.InputEnded:Connect(function(i)
ident()
        if i.UserInputType == Enum.UserInputType.MouseButton1 then held = false end
    end)
    local saved, rolled, lucky = nil, false, true
    S.silentRoll = function()
        return math.random(1, 100) <= wval("hc", 100)
    end
    S.preAim = function()
        if S.gunHooked == 7 then return end
        local t = S.aimT
        if not (running and CFG.silent and t and t.Parent) then return end
        rolled = true
        lucky = math.random(1, 100) <= wval("hc", 100)
        if not lucky then return end
        local c = workspace.CurrentCamera
        if not saved then saved = c.CFrame.Rotation end
        setView(CFrame.lookAt(c.CFrame.Position, t.Position))
    end
    pcall(function()
        game:GetService("ContextActionService"):BindActionAtPriority("ZenithBS2PreAim", function(_, state)
            if state == Enum.UserInputState.Begin and S.preAim then pcall(S.preAim) end
            return Enum.ContextActionResult.Pass
        end, false, 3000, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)
    end)
    RunService:BindToRenderStep("ZenithBS2Silent", Enum.RenderPriority.Last.Value + 4, function()
ident()
        if not running then return end
        local c = workspace.CurrentCamera
        local firing = held or S.autoFiring or (S.fireDown == true)
        if firing and not rolled then
            rolled = true
            lucky = math.random(1, 100) <= wval("hc", 100)
        elseif not firing then
            rolled = false
        end
        local t = S.aimT
        if CFG.silent and firing and lucky and t and t.Parent and S.gunHooked ~= 7 then
            if not saved then saved = c.CFrame.Rotation end
            setView(CFrame.lookAt(c.CFrame.Position, t.Position))
        elseif saved then
            setView(CFrame.new(c.CFrame.Position) * saved)
            saved = nil
        end
    end)
end

------------------------------------------------------------------ no recoil / no spread inside their own classes
-- recoil = CameraController.weaponKick (kick) + setWeaponRecoil (pattern, times a multiplier); spread = Bullet:getTrueSpread()
if hookfunction and newcclosure and S.gunHooked ~= 7 then
    S.gunHooked = 7
    task.spawn(function()
ident()
        pcall(function()
            local CC = require(RS:WaitForChild("Controllers", 15):WaitForChild("CameraController", 15))
            if type(CC.weaponKick) == "function" then
                local o1
                o1 = hookfunction(CC.weaponKick, newcclosure(function(a, b)
                    if S.on and S.cfg.noRecoil then return end
                    return o1(a, b)
                end))
            end
            if type(CC.setWeaponRecoil) == "function" then
                local o2
                o2 = hookfunction(CC.setWeaponRecoil, newcclosure(function(a, b)
                    if S.on and S.cfg.noRecoil then return o2(a, 0) end
                    return o2(a, b)
                end))
            end
        end)
        local hooked = {}
        local function hookBullet(mod)
            if hooked[mod] then return end
            hooked[mod] = true
            local ok, B = pcall(require, mod)
            if not ok or type(B) ~= "table" then return end
            if type(B._performRaycast) == "function" then
                local oR
                oR = hookfunction(B._performRaycast, newcclosure(function(self, spread, ...)
                    local c = workspace.CurrentCamera
                    local t = S.aimT
                    if t and S.shotPart then
                        local okP, np = pcall(S.shotPart, t)
                        if okP then t = np end
                    end
                    local swapped
                    if S.on and S.cfg.silent and t and t.Parent and (not S.silentRoll or S.silentRoll()) then
                        swapped = c.CFrame
                        -- magic bullet: the shot starts right next to the target, where nothing is in between
                        local from = (S.cfg.magicBullet and S.magicOrigin and S.magicOrigin(t)) or swapped.Position
                        c.CFrame = CFrame.lookAt(from, S.aimPoint and S.aimPoint(t) or t.Position)
                        S.shotTarget = {m = t.Parent, part = t.Name, at = tick()}
                        if S.aimMuzzles then pcall(S.aimMuzzles, t) end
                        spread = 0
                    elseif S.on and S.cfg.noSpread then
                        spread = 0
                    end
                    S.inShot = swapped and t or nil
                    local ok, res = pcall(oR, self, spread, ...)
                    S.inShot = nil
                    if swapped then c.CFrame = swapped end
                    if not ok then error(res, 0) end
                    if S.on and S.onBullet and type(res) == "table" then task.spawn(S.onBullet, res) end
                    return res
                end))
            end
            for _, fn in ipairs({"getTrueSpread", "getSpreadForConfig", "getMovementSpreadForConfig", "getBaseSpreadForConfig"}) do
                if type(B[fn]) == "function" then
                    local o
                    o = hookfunction(B[fn], newcclosure(function(...)
                        if S.on and S.cfg.noSpread then return 0 end
                        return o(...)
                    end))
                end
            end
        end
        for _, d in ipairs(RS:GetDescendants()) do
            if d:IsA("ModuleScript") and d.Name == "Bullet" then pcall(hookBullet, d) end
        end
        RS.DescendantAdded:Connect(function(d)
ident()
            if d:IsA("ModuleScript") and d.Name == "Bullet" then task.defer(function() pcall(hookBullet, d) end) end
        end)
    end)
end

------------------------------------------------------------------ movement command: Classes.Character.SampleInput (LookYaw, VerticalLook, Move, Buttons)
do
    local Buttons, MoveCfg
    local function cfgNow()
        if not MoveCfg then return nil end
        local gm = workspace:GetAttribute("ServerGamemode")
        if gm == "Casual" or gm == "Deathmatch" then return MoveCfg.CasualDeathmatch or MoveCfg.Default end
        if gm == "Surf" then return MoveCfg.Surf or MoveCfg.Default end
        return MoveCfg.Competitive or MoveCfg.Default
    end
    local function wrap(a) return (a + math.pi) % (2 * math.pi) - math.pi end
    local st = {spin = 0, flip = false, pflip = false, lastYaw = nil, jumpSent = false, side = 1, lastGround = false}
    S.onSample = function(self, cmd, extra)
        S.dbg.samples = S.dbg.samples + 1
        local cfg = S.cfg
        if type(cmd) ~= "table" or type(cmd.LookYaw) ~= "number" then return end
        local ground = self and self.OnGround == true
        S.inAir = not ground
        local typing = UIS:GetFocusedTextBox() ~= nil
        S.rageStrafing = false
        if Buttons and not typing and (cfg.bhop or cfg.autoStrafe) then
            local me = myModel()
            local root = (self and self.HumanoidRootPart) or (me and (me.PrimaryPart or me:FindFirstChild("HumanoidRootPart")))
            local vel = (self and typeof(self.GlobalVelocity) == "Vector3" and self.GlobalVelocity) or (root and root.AssemblyLinearVelocity) or Vector3.zero
            local flat = Vector3.new(vel.X, 0, vel.Z)
            local moving = typeof(cmd.Move) == "Vector2" and cmd.Move.Magnitude > 0.1
            -- bhop: a jump on every tick you touch the ground while jump is held (or always while moving on a phone)
            if cfg.bhop then
                -- only while YOU hold jump (space, or the jump button on a phone): one jump per landing
                local wants = UIS:IsKeyDown(Enum.KeyCode.Space) or (tick() - (S.jumpReqAt or 0) < 0.2)
                if wants and ground then
                    pcall(function() cmd.Buttons = Buttons.with(cmd.Buttons, Buttons.Jump, true) end)
                end
            end
            -- auto strafe: in the air, turning the camera left presses A, turning right presses D (like a real strafe); W is let go
            if cfg.autoStrafe and not ground and flat.Magnitude > 2 then
                local yaw = cmd.LookYaw
                local dy = st.asYaw and wrap(yaw - st.asYaw) or 0
                st.asYaw = yaw
                local th = 0.0008 * (cfg.strafeSens or 3)
                if dy > th then
                    cmd.Move = Vector2.new(-1, 0)
                elseif dy < -th then
                    cmd.Move = Vector2.new(1, 0)
                end
            else
                st.asYaw = cmd.LookYaw
            end

        end
        if cfg.edgeJump and ground and Buttons and not typing then
            local me = myModel()
            local root = (self and self.HumanoidRootPart) or (me and (me.PrimaryPart or me:FindFirstChild("HumanoidRootPart")))
            local vel = (self and typeof(self.GlobalVelocity) == "Vector3" and self.GlobalVelocity) or (root and root.AssemblyLinearVelocity) or Vector3.zero
            local flat = Vector3.new(vel.X, 0, vel.Z)
            if root and flat.Magnitude > 4 then
                -- where your feet will be a moment from now: no floor there = you are at the edge
                local ahead = root.Position + flat * 0.09 + flat.Unit * 0.6
                st.edgeP = st.edgeP or RaycastParams.new()
                st.edgeP.FilterType = Enum.RaycastFilterType.Exclude
                st.edgeP.FilterDescendantsInstances = {me, workspace.CurrentCamera}
                local floor = workspace:Raycast(ahead, Vector3.new(0, -5.5, 0), st.edgeP)
                if not floor then
                    pcall(function() cmd.Buttons = Buttons.with(cmd.Buttons, Buttons.Jump, true) end)
                end
            end
        end
        if cfg.autoFire and cfg.autoStop and (S.autoWant or tick() - (S.autoShotAt or 0) < (cfg.autoStopTime or 1)) then
            -- stop dead: no walking and no jump while the shots go out
            cmd.Move = Vector2.zero
            if Buttons then pcall(function() cmd.Buttons = Buttons.with(cmd.Buttons, Buttons.Jump, false) end) end
        end
        local turn = 0
        st.lastYaw = cmd.LookYaw
        -- silent: during a shot the look sent to the server points at the target (server checks shots against it)
        local t = S.aimT
        local w0 = S.curWeapon and S.curWeapon()
        local shooting = (w0 and w0.IsShooting) or (tick() - (S.lastShotAt or 0) < 0.2) or (cfg.autoFire and S.autoWant)
        if cfg.silent and t and t.Parent and shooting then
            local from = workspace.CurrentCamera.CFrame.Position
            local dir = ((S.aimPoint and S.aimPoint(t) or t.Position) - from)
            if dir.Magnitude > 0.1 then
                dir = dir.Unit
                cmd.LookYaw = math.atan2(-dir.X, -dir.Z)
                cmd.VerticalLook = math.clamp(math.asin(math.clamp(dir.Y, -1, 1)) / (math.pi / 2), -1, 1)
                return
            end
        end
        -- anti-aim: torso = the yaw everybody sees, head = the vertical look (not while rage strafing in the air)
        if cfg.aa and not S.rageStrafing then
            local w = S.curWeapon and S.curWeapon()
            if not (w and w.IsShooting) then
                local yaw0 = cmd.LookYaw
                local mode = cfg.aaTorso
                local air = not ground
                if cfg.aaAir and air then mode = "Spin" end
                local ny = yaw0
                if cfg.aaManual then
                    -- manual: pointing your back, or your side, the way you picked
                    if cfg.aaManLeft then mode = "ManLeft" elseif cfg.aaManRight then mode = "ManRight" else mode = "Back" end
                end
                if mode == "ManLeft" then
                    ny = yaw0 + math.pi / 2
                elseif mode == "ManRight" then
                    ny = yaw0 - math.pi / 2
                elseif mode == "Spin" then
                    st.spin = wrap(st.spin + math.rad(((cfg.aaAir and air) and cfg.aaAirSpeed or cfg.aaSpeed) * 6))
                    ny = yaw0 + st.spin
                elseif mode == "Jitter" then
                    st.flip = not st.flip
                    ny = yaw0 + math.pi + (st.flip and 1 or -1) * math.rad(60)
                elseif mode == "Side" then
                    ny = yaw0 + math.pi / 2
                else
                    ny = yaw0 + math.pi
                end
                ny = wrap(ny)
                -- keep running where you are going
                local mv = cmd.Move
                if typeof(mv) == "Vector2" and mv.Magnitude > 0 then
                    local world = CFrame.Angles(0, yaw0, 0):VectorToWorldSpace(Vector3.new(mv.X, 0, mv.Y))
                    local loc = CFrame.Angles(0, ny, 0):VectorToObjectSpace(world)
                    cmd.Move = Vector2.new(math.clamp(loc.X, -1, 1), math.clamp(loc.Z, -1, 1))
                end
                cmd.LookYaw = ny
                local head = (cfg.aaAir and air) and cfg.aaAirPitch or cfg.aaHead
                if head == "Down" then cmd.VerticalLook = -1
                elseif head == "Up" then cmd.VerticalLook = 1
                elseif head == "Jitter" then st.pflip = not st.pflip; cmd.VerticalLook = st.pflip and 1 or -1
                elseif head == "Random" then cmd.VerticalLook = math.random() * 2 - 1 end
                S.aaState = S.aaState or {}
                S.aaState.offset = wrap(ny - yaw0)
            end
        end
    end
    if hookfunction and newcclosure and S.sampleHooked ~= 1 then
        S.sampleHooked = 1
        task.spawn(function()
ident()
            pcall(function()
                local mv2 = RS:WaitForChild("MovementV2", 15)
                Buttons = require(mv2:WaitForChild("Buttons", 15))
                pcall(function() MoveCfg = require(mv2.Simulation.Config) end)
                local Ch = require(RS:WaitForChild("Classes", 15):WaitForChild("Character", 15))
                if type(Ch.SampleInput) ~= "function" then return end
                local orig
                orig = hookfunction(Ch.SampleInput, newcclosure(function(self, ...)
                    local cmd = orig(self, ...)
                    if S.on and S.onSample and type(cmd) == "table" then pcall(S.onSample, self, cmd, ...) end
                    return cmd
                end))
            end)
        end)
    else
        task.spawn(function()
ident()
            pcall(function()
                Buttons = require(RS:WaitForChild("MovementV2", 15):WaitForChild("Buttons", 15))
                MoveCfg = require(RS.MovementV2.Simulation.Config)
            end)
        end)
    end
end

------------------------------------------------------------------ weapon / remotes helpers (as the game's own InventoryController keeps them)
do
    local InvCtl, Remotes, Router
    task.spawn(function()
ident()
        pcall(function() InvCtl = require(RS:WaitForChild("Controllers", 15):WaitForChild("InventoryController", 15)) end)
        pcall(function() Remotes = require(RS:WaitForChild("Database", 15):WaitForChild("Security", 15):WaitForChild("Remotes", 15)) end)
        pcall(function() Router = require(RS.Database.Security.Router) end)
    end)
    S.curWeapon = function()
        if not (InvCtl and debug and debug.getupvalue and InvCtl.getInventorySlot) then return nil end
        local ok, up = pcall(debug.getupvalue, InvCtl.getInventorySlot, 1)
        if ok and type(up) == "table" then return rawget(up, "CurrentEquipped") end
        return nil
    end
    local function viewTick()
        if not Router then return nil end
        local ok, v = pcall(Router.broadcastRouter, "GetRemoteViewTick")
        return ok and type(v) == "number" and v or nil
    end
    local serverHits = false
    task.spawn(function()
ident()
        pcall(function()
            local R = require(RS:WaitForChild("Shared", 15):WaitForChild("Raycast", 15))
            serverHits = type(rawget(R, "castThroughDistance")) == "function"
        end)
    end)
    -- a free spot two studs from the target with a clear line to it (for the magic bullet)
    local mp = RaycastParams.new()
    mp.FilterType = Enum.RaycastFilterType.Exclude
    S.magicOrigin0 = function(t)
        local m = t.Parent
        local me = myModel()
        mp.FilterDescendantsInstances = {workspace.CurrentCamera, me}
        local back = workspace.CurrentCamera.CFrame.Position - t.Position
        back = Vector3.new(back.X, 0, back.Z)
        back = back.Magnitude > 0.01 and back.Unit or Vector3.new(0, 0, 1)
        local side = back:Cross(Vector3.new(0, 1, 0))
        for _, d in ipairs({back, (back + Vector3.yAxis).Unit, Vector3.yAxis, side, -side, -back}) do
            local p = t.Position + d * 2
            local hit = workspace:Raycast(p, (t.Position - p) * 1.2, mp)
            if hit and hit.Instance:IsDescendantOf(m) then return p end
        end
        return nil
    end
    -- double tap / rapid fire: the same shot sent again right after the real one
    local extraAt = 0
    S.extraShots = function(res)
        if not CFG.doubleTap then return end
        local now = tick()
        if now - extraAt < 0.15 then return end
        local send = S.shootSendFn or (Remotes and Remotes.Inventory and Remotes.Inventory.ShootWeapon and Remotes.Inventory.ShootWeapon.Send)
        if not send or typeof(res.Direction) ~= "Vector3" or typeof(res.Origin) ~= "Vector3" then return end
        local w = S.curWeapon()
        if not (w and w.Identifier) or (tonumber(w.Rounds) or 0) <= 0 then return end
        extraAt = now
        local vt = viewTick()
        task.delay(0.03, function()
            w.ShotSeq = (w.ShotSeq or 0) + 1
            local bullet = {Direction = res.Direction, Origin = res.Origin}
            if not serverHits then bullet.Hits = res.Hits end
            pcall(send, {IsSniperScoped = w.IsSniperScoped, ShootingHand = w.ShootingHand,
                Identifier = w.Identifier, Seq = w.ShotSeq, Bullets = {bullet}, ViewTick = vt})
        end)
    end
    -- kill effect: a glowing copy of the body floats up and fades
    local fxFolder = Instance.new("Folder")
    fxFolder.Name = "ZenithBS2Fx"
    fxFolder.Parent = workspace.CurrentCamera
    S.killGhost = function(m)
        if not CFG.killFx or not m then return end
        local ok, cl = pcall(function()
            m.Archivable = true
            return m:Clone()
        end)
        if not ok or not cl then return end
        local col = accentCol()
        for _, d in ipairs(cl:GetDescendants()) do
            if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") or d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("Sound") then
                pcall(function() d:Destroy() end)
            elseif d:IsA("BasePart") then
                d.Anchored, d.CanCollide = true, false
                pcall(function() d.CanQuery, d.CanTouch = false, false end)
                d.Material = Enum.Material.ForceField
                d.Color = col
                d.Transparency = (d.Name == "HumanoidRootPart" or d.Name == "CollisionCapsule") and 1 or 0.15
            elseif d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") then
                pcall(function() d:Destroy() end)
            end
        end
        cl.Name = "ZenithGhost"
        cl.Parent = fxFolder
        task.spawn(function()
ident()
            local start = cl:GetPivot()
            local t0 = tick()
            while tick() - t0 < 1.4 and cl.Parent do
                local a = (tick() - t0) / 1.4
                pcall(function() cl:PivotTo(start * CFrame.new(0, a * 12, 0) * CFrame.Angles(0, a * 2, 0)) end)
                for _, d in ipairs(cl:GetDescendants()) do
                    if d:IsA("BasePart") and d.Transparency < 1 then d.Transparency = math.max(d.Transparency, 0.15 + a * 0.85) end
                end
                RunService.Heartbeat:Wait()
            end
            pcall(function() cl:Destroy() end)
        end)
    end
end

-- where the shot leaves from: the gun's muzzle attachment when there is one (so barrel and bullet line up), else the camera
S.magicOrigin = function(t)
    local best
    for _, vm in ipairs(viewModels()) do
        for _, d in ipairs(vm:GetDescendants()) do
            if d:IsA("Attachment") then
                local x = d.Parent
                local inMuzzle = false
                while x and x ~= vm do
                    if string.sub(x.Name, 1, 10) == "MuzzlePart" then inMuzzle = true break end
                    x = x.Parent
                end
                if inMuzzle and d.Parent:IsA("BasePart") and d.Parent.Transparency < 1 then
                    best = d
                    if d.Parent.Name == "Suppressor" then break end
                end
            end
        end
        if best then break end
    end
    local camPos = workspace.CurrentCamera.CFrame.Position
    if best and (best.WorldPosition - camPos).Magnitude < 6 then return best.WorldPosition end
    return camPos
end

------------------------------------------------------------------ custom model 138151705692565 (mesh parts), your screen
do
    local MODELS = {["Tung Tung Sahur"] = 138151705692565, ["Villager"] = 90405905565781, ["Pigg"] = 133116885317874,
        ["Banana"] = 7870128838, ["Zombie"] = 2949443329}
    local cm = {model = nil, offset = nil, hidden = {}, name = nil}
    local function hideBody(on)
        local m = myModel()
        if on and m then
            for _, d in ipairs(m:GetDescendants()) do
                if (d:IsA("BasePart") or d:IsA("Decal")) then
                    if cm.hidden[d] == nil then cm.hidden[d] = d.LocalTransparencyModifier end
                    if d.LocalTransparencyModifier ~= 1 then d.LocalTransparencyModifier = 1 end
                end
            end
        elseif not on then
            for d, v in pairs(cm.hidden) do if d.Parent then pcall(function() d.LocalTransparencyModifier = v end) end end
            cm.hidden = {}
        end
    end
    local Players2 = game:GetService("Players")
    -- a full avatar (mesh / layered clothing / accessories) built from a username, worn instead of your body
    S.buildModel = function()
        local want = CFG.cmName
        if cm.model and cm.model.Parent and cm.name == want then return true end
        if cm.model then pcall(function() cm.model:Destroy() end) cm.model = nil end
        local id = MODELS[want] or 138151705692565
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
        local src = ok and type(objs) == "table" and objs[1]
        if not src then return false end
        local m = src
        if not m:IsA("Model") then
            local wrap = Instance.new("Model")
            m.Parent = wrap
            m = wrap
        end
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("Humanoid") or d:IsA("Animator") or d:IsA("AnimationController") then
                pcall(function() d:Destroy() end)
            elseif d:IsA("BasePart") then
                d.Anchored, d.CanCollide = true, false
                pcall(function() d.CanQuery, d.CanTouch, d.CastShadow = false, false, false end)
            end
        end
        m.Name = "ZenithCustomModel"
        m.Parent = workspace
        cm.model, cm.name = m, want
        return true
    end
    RunService:BindToRenderStep("ZenithBS2Model", Enum.RenderPriority.Last.Value + 15, function()
        if not running then return end
        local me = myModel()
        local root = me and (me.PrimaryPart or me:FindFirstChild("HumanoidRootPart"))
        if CFG.cmOn2 and cm.model and cm.model.Parent and root then
            -- its middle on your middle, its bottom on your feet
            local okb, cf, size = pcall(function() return cm.model:GetBoundingBox() end)
            local okm, mcf, msize = pcall(function() return me:GetBoundingBox() end)
            if okb and okm then
                local _, yaw = root.CFrame:ToOrientation()
                local goal = CFrame.new(root.Position.X, mcf.Position.Y - msize.Y / 2 + size.Y / 2, root.Position.Z) * CFrame.Angles(0, yaw, 0)
                pcall(function() cm.model:PivotTo(goal * cm.model:GetPivot():ToObjectSpace(cf):Inverse()) end)
            end
            hideBody(true)
        elseif next(cm.hidden) then
            hideBody(false)
            if cm.model then pcall(function() cm.model:PivotTo(CFrame.new(0, -5000, 0)) end) end
        end
    end)
end

connect(UIS.JumpRequest, function() S.jumpReqAt = tick() end)
S.onToggle = function(key)
    if key == "aaManLeft" and CFG.aaManLeft then CFG.aaManRight = false end
    if key == "aaManRight" and CFG.aaManRight then CFG.aaManLeft = false end
    if (key == "aaManLeft" or key == "aaManRight") and S.refreshAll then S.refreshAll() end
    if key == "cmOn2" and CFG.cmOn2 and S.buildModel then
        task.spawn(function()
            if not S.buildModel() then
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Zenith", Text = "custom model could not be loaded", Duration = 4})
                end)
            end
        end)
    end
end

------------------------------------------------------------------ kill effects made once: blood drops and lightning segments
do
    local folder = Instance.new("Folder")
    folder.Name = "ZenithBS2KillFx"
    folder.Parent = workspace.CurrentCamera
    local POOLP = {}
    for _ = 1, 48 do
        local p = Instance.new("Part")
        p.Anchored, p.CanCollide, p.CastShadow = true, false, false
        pcall(function() p.CanQuery, p.CanTouch = false, false end)
        p.Transparency = 1
        p.Material = Enum.Material.Neon
        p.Size = Vector3.new(0.3, 0.3, 0.3)
        p.CFrame = CFrame.new(0, -5000, 0)
        p.Parent = folder
        POOLP[#POOLP + 1] = p
    end
    local function take(n)
        local out = {}
        for _ = 1, n do
            local p = table.remove(POOLP, 1)
            if not p then break end
            out[#out + 1] = p
        end
        return out
    end
    local function giveBack(list)
        for _, p in ipairs(list) do
            p.Transparency = 1
            p.CFrame = CFrame.new(0, -5000, 0)
            POOLP[#POOLP + 1] = p
        end
    end
    local function rootOf(m) return m and (m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head")) end
    S.killBlood = function(m)
        local r = rootOf(m)
        if not r then return end
        local drops = take(18)
        local base = r.Position
        local vel = {}
        for i, p in ipairs(drops) do
            p.Material = Enum.Material.SmoothPlastic
            p.Color = Color3.fromRGB(math.random(110, 170), 0, 0)
            local sz = 0.2 + math.random() * 0.35
            p.Size = Vector3.new(sz, sz, sz)
            p.Shape = Enum.PartType.Ball
            p.Transparency = 0
            p.CFrame = CFrame.new(base)
            vel[i] = Vector3.new((math.random() - 0.5) * 16, math.random() * 12 + 4, (math.random() - 0.5) * 16)
        end
        task.spawn(function()
            local t0, last = tick(), tick()
            while tick() - t0 < 1.4 do
                local now = tick()
                local dt = now - last
                last = now
                for i, p in ipairs(drops) do
                    vel[i] = vel[i] + Vector3.new(0, -40 * dt, 0)
                    p.CFrame = p.CFrame + vel[i] * dt
                    if tick() - t0 > 0.9 then p.Transparency = math.min(1, (tick() - t0 - 0.9) / 0.5) end
                end
                RunService.Heartbeat:Wait()
            end
            for _, p in ipairs(drops) do p.Shape = Enum.PartType.Block end
            giveBack(drops)
        end)
    end
    S.killBolt = function(m)
        local r = rootOf(m)
        if not r then return end
        local segs = take(14)
        local bottom = r.Position
        local topP = bottom + Vector3.new((math.random() - 0.5) * 6, 70, (math.random() - 0.5) * 6)
        local prev = topP
        for i, p in ipairs(segs) do
            local t = i / #segs
            local pt = topP:Lerp(bottom, t)
            if i < #segs then pt = pt + Vector3.new((math.random() - 0.5) * 4, 0, (math.random() - 0.5) * 4) end
            local len = (pt - prev).Magnitude
            p.Material = Enum.Material.Neon
            p.Color = Color3.fromRGB(190, 220, 255)
            p.Size = Vector3.new(0.35, 0.35, len)
            p.CFrame = CFrame.lookAt((prev + pt) / 2, pt)
            p.Transparency = 0
            prev = pt
        end
        task.spawn(function()
            local t0 = tick()
            while tick() - t0 < 0.6 do
                local k = (tick() - t0) / 0.6
                for _, p in ipairs(segs) do p.Transparency = k end
                RunService.Heartbeat:Wait()
            end
            giveBack(segs)
        end)
    end
end

------------------------------------------------------------------ planted bomb: time left until it goes off
do
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(150, 44)
    bb.AlwaysOnTop = true
    bb.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
    bb.Enabled = false
    bb.Parent = workspace.CurrentCamera
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, 0, 0, 20)
    t.Font = Enum.Font.GothamBlack
    t.TextSize = 15
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Parent = bb
    local tg = Instance.new("UIGradient")
    tg.Rotation = 90
    tg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(0.55, Color3.fromRGB(205, 205, 210)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 60, 65))})
    tg.Parent = t
    local ts = Instance.new("UIStroke")
    ts.Color, ts.Thickness, ts.Transparency = Color3.new(0, 0, 0), 1.5, 0.1
    ts.Parent = t
    local bimg = Instance.new("ImageLabel")
    bimg.BackgroundTransparency = 1
    bimg.ScaleType = Enum.ScaleType.Fit
    bimg.AnchorPoint = Vector2.new(0.5, 0)
    bimg.Position = UDim2.new(0.5, 0, 0, 21)
    bimg.Size = UDim2.fromOffset(40, 22)
    bimg.Parent = bb
    local planted, explodeAt = nil, nil
    local PLANTED = {c4 = true, plantedc4 = true, bomb = true, plantedbomb = true, ["planted c4"] = true}
    local function bombish(x)
        return PLANTED[string.lower(x.Name)] == true and (x:IsA("Model") or x:IsA("BasePart"))
            and not (x.Parent and PLANTED[string.lower(x.Parent.Name)])
    end
    local function owned(x)
        if x:IsDescendantOf(workspace.CurrentCamera) then return true end
        for _, it in ipairs(S.models or {}) do if x:IsDescendantOf(it[1]) then return true end end
        local me = myModel()
        return me ~= nil and x:IsDescendantOf(me)
    end
    local function timeFrom(x)
        -- a timer the game keeps on it: a time stamp, or seconds left
        for _, k in ipairs({"ExplodeTime", "ExplosionTime", "DetonateTime", "DetonationTime", "EndTime", "Timer", "TimeLeft", "Time"}) do
            local v = tonumber(x:GetAttribute(k))
            if v then
                if v > 100000 then return v - workspace:GetServerTimeNow() end
                return v
            end
        end
        return 40
    end
    connect(workspace.DescendantAdded, function(x)
        if CFG.bombTimer and bombish(x) and not owned(x) then
            planted = x
            explodeAt = tick() + timeFrom(x)
        end
    end)
    task.spawn(function()
        while running do
            local x = planted
            if CFG.bombTimer and x and x.Parent and explodeAt then
                local left = explodeAt - tick()
                if left > -1 then
                    bb.Adornee = x:IsA("Model") and (x.PrimaryPart or x:FindFirstChildWhichIsA("BasePart", true)) or x
                    t.Text = string.format("Bomb  %.1fs", math.max(left, 0))
                    local ic = S.weaponIcon and S.weaponIcon("C4")
                    if ic and bimg.Image ~= ic then bimg.Image = ic end
                    bimg.Visible = ic ~= nil
                    bb.Enabled = true
                else
                    bb.Enabled = false
                end
            else
                bb.Enabled = false
            end
            task.wait(0.1)
        end
        pcall(function() bb:Destroy() end)
    end)
end

------------------------------------------------------------------ auto reload: magazine empty -> reload
task.spawn(function()
    local CASr = game:GetService("ContextActionService")
    local lastAt = 0
    while running do
        if CFG.autoReload and tick() - lastAt > 0.8 then
            pcall(function()
                local w = S.curWeapon and S.curWeapon()
                if w and tonumber(w.Rounds) == 0 and not w.IsReloading then
                    lastAt = tick()
                    local ok = false
                    if type(w.reload) == "function" then ok = pcall(w.reload, w) end
                    if not ok then
                        pcall(function() CASr:CallFunction("Reload", Enum.UserInputState.Begin, nil) end)
                        task.delay(0.05, function() pcall(function() CASr:CallFunction("Reload", Enum.UserInputState.End, nil) end) end)
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

------------------------------------------------------------------ skybox (toolbox sky models)
do
    local Lighting = game:GetService("Lighting")
    local SOURCES = {
        {id = 11320658296, name = "toy time galaxy"},
        {id = 136402262, name = "realistic space"},
        {id = 105189455817751, name = "anime"},
        {id = 102765136165948, pack = true},
    }
    S.skyList = S.skyList or {}
    local loading = false
    S.skyLoad = function()
        if loading then return end
        loading = true
        task.spawn(function()
ident()
            for _, src in ipairs(SOURCES) do
                local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. src.id) end)
                if ok and type(objs) == "table" then
                    local skies = {}
                    for _, o in ipairs(objs) do
                        if o:IsA("Sky") then skies[#skies + 1] = o end
                        for _, d in ipairs(o:GetDescendants()) do
                            if d:IsA("Sky") then skies[#skies + 1] = d end
                        end
                    end
                    if src.pack then
                        for _, sk in ipairs(skies) do
                            local nm = string.lower(sk.Name ~= "Sky" and sk.Name or (sk.Parent and sk.Parent.Name or "sky"))
                            S.skyList[#S.skyList + 1] = {key = src.id .. ":" .. nm .. ":" .. #S.skyList, name = nm, sky = sk}
                        end
                    elseif skies[1] then
                        S.skyList[#S.skyList + 1] = {key = tostring(src.id), name = src.name, sky = skies[1]}
                    end
                    if S.skyRedraw then pcall(S.skyRedraw) end
                end
            end
        end)
    end
    local hidden, mine, shown = {}, nil, nil
    local function off()
        if mine then pcall(function() mine:Destroy() end) end
        mine = nil
        for sky, parent in pairs(hidden) do pcall(function() sky.Parent = parent end) end
        hidden = {}
        shown = nil
    end
    local function set(key)
        if key == shown then return end
        local item
        for _, it in ipairs(S.skyList) do if it.key == key then item = it break end end
        if not item then return end
        off()
        for _, x in ipairs(Lighting:GetChildren()) do
            if x:IsA("Sky") then
                hidden[x] = x.Parent
                x.Parent = nil
            end
        end
        local ok, cl = pcall(function()
            item.sky.Archivable = true
            return item.sky:Clone()
        end)
        if ok and cl then
            cl.Name = "ZenithSky"
            cl.Parent = Lighting
            mine, shown = cl, key
        end
    end
    if CFG.skybox ~= "Off" then S.skyLoad() end
    task.spawn(function()
ident()
        while running do
            if CFG.skybox == "Off" or not CFG.skyOn then
                if shown then off() end
            else
                pcall(set, CFG.skybox)
            end
            task.wait(0.5)
        end
        off()
    end)
end

------------------------------------------------------------------ fast reload / knife: speed up the animations they wait for
do
    local KNIVES = {"T Knife", "CT Knife", "Butterfly Knife", "M9 Bayonet", "Flip Knife", "Gut Knife", "Karambit", "Stiletto Knife", "Skeleton Knife"}
    local isKnife = {}
    for _, k in ipairs(KNIVES) do isKnife[k] = true end
    local RELOAD, SWING, THROW, SHOOT = {}, {}, {}, {}
    task.spawn(function()
ident()
        pcall(function()
            local wa = RS:WaitForChild("Assets", 15):WaitForChild("WeaponAnimations", 15)
            local function scan()
                for _, d in ipairs(wa:GetDescendants()) do
                    if d:IsA("Animation") and d.AnimationId ~= "" then
                        local n = string.lower(d.Name)
                        local weapon = d:FindFirstAncestorWhichIsA("Folder")
                        while weapon and weapon.Parent ~= wa do weapon = weapon.Parent end
                        local wname = weapon and weapon.Name or ""
                        if string.find(n, "reload", 1, true) then RELOAD[d.AnimationId] = true end
                        if n == "startthrow" or n == "throw" or n == "throwidle" then THROW[d.AnimationId] = true end
                        if n == "shoot" or n == "fire" then SHOOT[d.AnimationId] = true end
                        if isKnife[wname] and (n == "swing1" or n == "swing2" or string.find(n, "swing", 1, true)) then SWING[d.AnimationId] = true end
                    end
                end
            end
            scan()
            wa.DescendantAdded:Connect(function() task.defer(scan) end)
        end)
    end)
    local hooked = setmetatable({}, {__mode = "k"})
    local function watch(animator)
        if hooked[animator] then return end
        hooked[animator] = true
        animator.AnimationPlayed:Connect(function(track)
ident()
            if not running then return end
            local id = track.Animation and track.Animation.AnimationId
            if not id then return end
            if CFG.fastReload and RELOAD[id] then
                pcall(function() track:AdjustSpeed(CFG.reloadSpeed) end)
            elseif CFG.knifeFast and SWING[id] then
                pcall(function() track:AdjustSpeed(CFG.knifeSpeed) end)
            elseif CFG.fastThrow and THROW[id] then
                pcall(function() track:AdjustSpeed(CFG.throwSpeed) end)
            elseif CFG.fireRateOn and CFG.shootAnim and SHOOT[id] then
                pcall(function() track:AdjustSpeed(math.max(CFG.fireRateMul, 1)) end)
            end
        end)
    end
    task.spawn(function()
ident()
        while running do
            pcall(function()
                for _, vm in ipairs(viewModels()) do
                    for _, d in ipairs(vm:GetDescendants()) do
                        if d:IsA("Animator") then watch(d) end
                    end
                end
                local me = myModel()
                if me then
                    for _, d in ipairs(me:GetDescendants()) do
                        if d:IsA("Animator") then watch(d) end
                    end
                end
            end)
            task.wait(1)
        end
    end)
end

------------------------------------------------------------------ custom model: a model from the toolbox worn instead of your body (your screen)
do
    local MODEL_ID = 138151705692565
    local src, worn, hidden = nil, nil, {}
    local function unwear()
        if worn then pcall(function() worn:Destroy() end) end
        worn = nil
        for p in pairs(hidden) do pcall(function() p.LocalTransparencyModifier = 0 end) end
        hidden = {}
    end
    local function wear(m)
        unwear()
        if not src then
            local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. MODEL_ID) end)
            src = ok and type(objs) == "table" and objs[1] or nil
            if not src then
                CFG.customModel = false
                S.dbg.cm = "model could not be loaded"
                warn("[Zenith] custom model " .. MODEL_ID .. " could not be loaded")
                return
            end
            for _, d in ipairs(src:GetDescendants()) do
                if d:IsA("LuaSourceContainer") or d:IsA("Sound") then d:Destroy() end
            end
        end
        local root = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local cl = src:Clone()
        if not cl:IsA("Model") then
            local wrap = Instance.new("Model")
            cl.Parent = wrap
            cl = wrap
        end
        local parts = {}
        for _, d in ipairs(cl:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Anchored, d.CanCollide, d.Massless = false, false, true
                pcall(function() d.CanQuery, d.CanTouch = false, false end)
                parts[#parts + 1] = d
            end
            if d:IsA("JointInstance") and not d:IsA("Weld") and not d:IsA("Motor6D") then d:Destroy() end
        end
        if #parts == 0 then cl:Destroy() return end
        -- stand it on your feet, facing where you face
        local cf, size = cl:GetBoundingBox()
        local mcf, msize = m:GetBoundingBox()
        local feetY = mcf.Position.Y - msize.Y / 2
        local _, yaw = root.CFrame:ToOrientation()
        local target = CFrame.new(root.Position.X, feetY + size.Y / 2, root.Position.Z) * CFrame.Angles(0, yaw, 0)
        cl:PivotTo(target * (cl:GetPivot():ToObjectSpace(cf)):Inverse())
        for _, p in ipairs(parts) do p.Anchored = true end
        local offset = root.CFrame:ToObjectSpace(cl:GetPivot())
        S.customFollow = function()
            if cl.Parent and root.Parent then pcall(function() cl:PivotTo(root.CFrame * offset) end) end
        end
        cl.Name = "ZenithCustomModel"
        cl.Parent = workspace.CurrentCamera
        worn = cl
    end
    task.spawn(function()
ident()
        local lastModel
        while running do
            pcall(function()
                local m = myModel()
                local dead = m and m:GetAttribute("Dead") == true
                if CFG.customModel and m and not dead then
                    if lastModel ~= m or not (worn and worn.Parent) then
                        lastModel = m
                        wear(m)
                    end
                    for _, d in ipairs(m:GetDescendants()) do
                        if d:IsA("BasePart") or d:IsA("Decal") then
                            hidden[d] = true
                            d.LocalTransparencyModifier = 1
                        end
                    end
                elseif worn or next(hidden) then
                    unwear()
                    lastModel = nil
                end
            end)
            task.wait(0.25)
        end
        unwear()
    end)
end

------------------------------------------------------------------ anti flash / anti smoke: react to new things only (no full sweeps)
do
    local Lighting = game:GetService("Lighting")
    -- only the white-out itself: "Flashbang" icons in the buy menu / inventory are left alone
    local function flashy(n)
        n = string.lower(n)
        if n == "flashbang" or string.find(n, "icon", 1, true) or string.find(n, "button", 1, true) or string.find(n, "slot", 1, true) then return false end
        return string.find(n, "flasheffect", 1, true) or string.find(n, "flashoverlay", 1, true) or string.find(n, "flashscreen", 1, true)
            or string.find(n, "flashed", 1, true) or string.find(n, "blind", 1, true) or string.find(n, "whiteout", 1, true)
    end
    local function onFlash(x)
        if not CFG.antiFlash then return end
        if x.Name == "ZenithCC" or x.Name == "ZenithBloom" or x.Name == "ZenithBlur" then return end
        pcall(function()
            if x:IsA("ScreenGui") and flashy(x.Name) then x.Enabled = false
            elseif x:IsA("GuiObject") and flashy(x.Name) then x.Visible = false
            elseif x:IsA("ColorCorrectionEffect") then
                x:GetPropertyChangedSignal("Brightness"):Connect(function()
ident()
                    if CFG.antiFlash and x.Brightness > 0.3 then x.Brightness, x.Contrast = 0, 0 end
                end)
                if x.Brightness > 0.3 then x.Brightness, x.Contrast = 0, 0 end
            elseif x:IsA("BlurEffect") then
                x:GetPropertyChangedSignal("Size"):Connect(function()
ident()
                    if CFG.antiFlash and x.Size > 12 then x.Size = 0 end
                end)
                if x.Size > 12 then x.Size = 0 end
            end
        end)
    end
    task.spawn(function()
ident()
        local pg = lp:WaitForChild("PlayerGui", 10)
        if pg then connect(pg.DescendantAdded, onFlash) end
        connect(Lighting.ChildAdded, onFlash)
        for _, x in ipairs(Lighting:GetChildren()) do onFlash(x) end
        connect(workspace.CurrentCamera.ChildAdded, onFlash)
    end)
    local function firey(x, stop)
        while x and x ~= stop do
            local n = string.lower(x.Name)
            local g = x:GetAttribute("GrenadeName")
            if string.find(n, "fire", 1, true) or string.find(n, "molotov", 1, true) or string.find(n, "incend", 1, true)
                or string.find(n, "inferno", 1, true) or string.find(n, "flame", 1, true)
                or (type(g) == "string" and (string.find(string.lower(g), "molotov", 1, true) or string.find(string.lower(g), "incend", 1, true))) then
                return true
            end
            x = x.Parent
        end
        return false
    end
    local function onSmoke(f, dbg)
        if not CFG.antiSmoke then return end
        if string.sub(string.lower(f.Name), 1, 10) == "voxelsmoke" then
            pcall(function() f:Destroy() end)
            return
        end
        local n = string.lower(f.Name)
        if not (string.find(n, "smoke", 1, true) or string.find(n, "voxel", 1, true)) then return end
        if firey(f, dbg) then return end
        pcall(function()
            if f:IsA("ParticleEmitter") then
                f.Enabled = false
                f:Clear()
            elseif f:IsA("BasePart") then
                f.LocalTransparencyModifier = 1
            end
        end)
    end
    task.spawn(function()
ident()
        local dbg = workspace:WaitForChild("Debris", 15)
        if not dbg then return end
        connect(dbg.DescendantAdded, function(f) task.defer(onSmoke, f, dbg) end)
        local was = false
        while running do
            if CFG.antiSmoke and not was then
                for _, f in ipairs(dbg:GetDescendants()) do onSmoke(f, dbg) end
            end
            was = CFG.antiSmoke
            task.wait(1)
        end
    end)
end

do
    local Lighting = game:GetService("Lighting")
    local baseExp = Lighting.ExposureCompensation
    RunService:BindToRenderStep("ZenithBS2Flash", Enum.RenderPriority.Last.Value + 30, function()
        if not (running and CFG.antiFlash) then return end
        -- exposure pushed up by a flash -> back to normal
        if Lighting.ExposureCompensation > baseExp + 0.3 then Lighting.ExposureCompensation = baseExp end
    end)
end

------------------------------------------------------------------ anti flash: their flash module muffles sound through GetAudioFadeMultiplier
if hookfunction and newcclosure and not S.flashHooked then
    S.flashHooked = true
    task.spawn(function()
ident()
        pcall(function()
            local mod = RS:WaitForChild("Components", 10):WaitForChild("Common", 10):WaitForChild("VFXLibary", 10):WaitForChild("FlashEffect", 10)
            local FE = require(mod)
            if type(FE) == "table" and type(FE.GetAudioFadeMultiplier) == "function" then
                local o
                o = hookfunction(FE.GetAudioFadeMultiplier, newcclosure(function(...)
                    if S.on and S.cfg.antiFlash then return 1 end
                    return o(...)
                end))
            end
        end)
    end)
end

------------------------------------------------------------------ attachment hook: muzzle attachments aimed at the silent target
do
    local saved = {}
    local cacheVm, cacheList = nil, {}
    local function muzzleAtts()
        local vms = viewModels()
        local key = vms[1]
        if key == cacheVm and #cacheList > 0 and cacheList[1].Parent then return cacheList end
        local out = {}
        local function inMuzzle(d)
            local x = d.Parent
            while x and x ~= workspace do
                if string.sub(x.Name, 1, 10) == "MuzzlePart" then return true end
                x = x.Parent
            end
            return false
        end
        for _, vm in ipairs(vms) do
            for _, d in ipairs(vm:GetDescendants()) do
                if d:IsA("Attachment") then
                    local n = string.lower(d.Name)
                    local par = d.Parent and string.lower(d.Parent.Name) or ""
                    if inMuzzle(d) or string.find(n, "muzzle", 1, true) or string.find(par, "barrel", 1, true) or string.find(par, "suppressor", 1, true) then
                        out[#out + 1] = d
                    end
                end
            end
        end
        cacheVm, cacheList = key, out
        return out
    end
    local function restore()
        for a, cf in pairs(saved) do
            if a.Parent then pcall(function() a.CFrame = cf end) end
        end
        saved = {}
    end
    local function point(a, t)
        local goal = S.aimPoint and S.aimPoint(t) or t.Position
        local wc = a.WorldCFrame
        a.WorldCFrame = CFrame.lookAt(wc.Position, goal, wc.UpVector)
    end
    S.aimMuzzles = function(t)
        for _, a in ipairs(muzzleAtts()) do
            if saved[a] == nil then saved[a] = a.CFrame end
            pcall(point, a, t)
        end
    end
    RunService:BindToRenderStep("ZenithBS2AttHook", Enum.RenderPriority.Last.Value + 3, function()
ident()
        if not running then return end
        local t = S.aimT
        if (CFG.silent or CFG.autoFire or CFG.trigger) and t and t.Parent then
            -- back to the gun's own pose first, then turned: no drift from turning an already turned attachment
            for a, cf in pairs(saved) do
                if a.Parent then pcall(function() a.CFrame = cf end) end
            end
            for _, a in ipairs(muzzleAtts()) do
                if saved[a] == nil then saved[a] = a.CFrame end
                pcall(point, a, t)
            end
        elseif next(saved) then
            restore()
        end
    end)
    S.attHookOff = function()
        restore()
        pcall(function() RunService:UnbindFromRenderStep("ZenithBS2AttHook") end)
    end
end

RunService:BindToRenderStep("ZenithBS2Follow", Enum.RenderPriority.Last.Value + 15, function()
ident()
    if CFG.customModel and S.customFollow then pcall(S.customFollow) end
end)

local function isViewModel(x)
    local p = x.Parent
    return p ~= nil and p:IsA("Camera") and x.Name ~= "ZenithCustomModel"
end
if hookmetamethod and getnamecallmethod and checkcaller and newcclosure and not S.vmHooked then
    S.vmHooked = true
    local oldNC
    oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, a1, ...)
        if not checkcaller() and S.on and S.cfg.vmOn and typeof(self) == "Instance" and typeof(a1) == "CFrame" then
            local m = getnamecallmethod()
            if (m == "PivotTo" or m == "SetPrimaryPartCFrame") and self:IsA("Model") and isViewModel(self) then
                return oldNC(self, a1 * CFrame.new(S.cfg.vmX, S.cfg.vmY, S.cfg.vmZ), ...)
            end
        end
        return oldNC(self, a1, ...)
    end))
    local oldNI
    oldNI = hookmetamethod(game, "__newindex", newcclosure(function(self, k, v)
        if k == "CFrame" and typeof(v) == "CFrame" and not checkcaller() and S.on and S.cfg.vmOn and typeof(self) == "Instance" then
            local mdl = self.Parent
            if mdl and mdl:IsA("Model") and mdl.PrimaryPart == self and isViewModel(mdl) then
                return oldNI(self, k, v * CFrame.new(S.cfg.vmX, S.cfg.vmY, S.cfg.vmZ))
            end
        end
        return oldNI(self, k, v)
    end))
end
local vmSet = setmetatable({}, {__mode = "k"})
local function vmAnchorOf(vm)
    for _, j in ipairs(vm:GetDescendants()) do
        if j:IsA("JointInstance") or j:IsA("WeldConstraint") then
            for _, p in ipairs({j.Part0, j.Part1}) do
                if p and not p:IsDescendantOf(vm) and p.Anchored then return p end
            end
        end
    end
    return nil
end
local function vmApply()
    if S.vmHooked then return end
    if not (running and CFG.vmOn) then return end
    if CFG.vmX == 0 and CFG.vmY == 0 and CFG.vmZ == 0 then return end
    local c = workspace.CurrentCamera
    local world = c.CFrame:VectorToWorldSpace(Vector3.new(CFG.vmX, CFG.vmY, CFG.vmZ))
    for _, vm in ipairs(viewModels()) do
        if vm.Name ~= "ZenithCustomModel" then
            pcall(function()
                local now = vm:GetPivot()
                -- only if the game put it back since we last moved it (no double shift)
                if vmSet[vm] ~= now then
                    local anchor = vmAnchorOf(vm)
                    if anchor then anchor.CFrame = anchor.CFrame + world end
                    local moved = now + world
                    vm:PivotTo(moved)
                    vmSet[vm] = moved
                end
            end)
        end
    end
end
RunService:BindToRenderStep("ZenithBS2VM", 3500, vmApply)
connect(RunService.RenderStepped, vmApply)
RunService:BindToRenderStep("ZenithBS2World", Enum.RenderPriority.Last.Value + 31, function()
    if not running then return end
    local Lighting = game:GetService("Lighting")
    if CFG.ambOn then
        local col = Color3.fromHSV(CFG.ambH, CFG.ambS, CFG.ambV)
        if Lighting.Ambient ~= col then Lighting.Ambient = col end
        if Lighting.OutdoorAmbient ~= col then Lighting.OutdoorAmbient = col end
        if Lighting.Brightness ~= CFG.ambBright then Lighting.Brightness = CFG.ambBright end
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm and atm.Color ~= col then pcall(function() atm.Color = col end) end
    end
    if CFG.timeOn and Lighting.ClockTime ~= CFG.clockTime then Lighting.ClockTime = CFG.clockTime end
    if CFG.fogOn and Lighting.FogEnd ~= CFG.fogEnd then
        Lighting.FogStart, Lighting.FogEnd = 0, CFG.fogEnd
        Lighting.FogColor = Color3.fromHSV(CFG.fogH, CFG.fogS, CFG.fogV)
    end
end)

------------------------------------------------------------------ world effects, made once here
do
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "ZenithCC"
    local bl = Instance.new("BloomEffect")
    bl.Name = "ZenithBloom"
    local bu = Instance.new("BlurEffect")
    bu.Name = "ZenithBlur"
    S.fxCC, S.fxBloom, S.fxBlur = cc, bl, bu
end

------------------------------------------------------------------ china hat, fog, ambience
do
    local hat
    local Lighting = game:GetService("Lighting")
    local saved = {}
    local function keep(k) if saved[k] == nil then saved[k] = Lighting[k] end end
    local function give(k) if saved[k] ~= nil then pcall(function() Lighting[k] = saved[k] end) saved[k] = nil end end
    task.spawn(function()
ident()
        while running do
            pcall(function()
                local m = myModel()
                local head = m and m:FindFirstChild("Head")
                local show = CFG.chinaHat and head and (CFG.third or head.LocalTransparencyModifier < 1)
                if show then
                    if not (hat and hat.Parent) then
                        hat = Instance.new("ConeHandleAdornment")
                        hat.Height, hat.Radius = 0.9, 1.7
                        hat.Transparency = 0.25
                        hat.AlwaysOnTop = false
                        hat.ZIndex = 1
                        hat.Parent = workspace.CurrentCamera
                    end
                    hat.Adornee = head
                    hat.CFrame = CFrame.new(0, head.Size.Y / 2 + 0.25, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                    hat.Color3 = Color3.fromHSV(CFG.hatH, CFG.hatS, CFG.hatV)
                    hat.Visible = true
                elseif hat then
                    hat.Visible = false
                end
                if CFG.fogOn then
                    keep("FogEnd"); keep("FogStart"); keep("FogColor")
                    Lighting.FogStart = 0
                    Lighting.FogEnd = CFG.fogEnd
                    Lighting.FogColor = Color3.fromHSV(CFG.fogH, CFG.fogS, CFG.fogV)
                else
                    give("FogEnd"); give("FogStart"); give("FogColor")
                end
                if CFG.ambOn then
                    keep("Ambient"); keep("OutdoorAmbient"); keep("Brightness")
                    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
                    if atm and not S.atmColor then S.atmColor = {atm, atm.Color} end
                    local col = Color3.fromHSV(CFG.ambH, CFG.ambS, CFG.ambV)
                    Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.Brightness = col, col, CFG.ambBright
                else
                    give("Ambient"); give("OutdoorAmbient"); give("Brightness")
                    if S.atmColor then
                        pcall(function() S.atmColor[1].Color = S.atmColor[2] end)
                        S.atmColor = nil
                    end
                end
                if CFG.timeOn then
                    keep("ClockTime")
                    Lighting.ClockTime = CFG.clockTime
                else
                    give("ClockTime")
                end
                -- our own colour correction / bloom / blur (made at load, only switched in and out of Lighting)
                if S.fxCC then
                    S.fxCC.Parent = CFG.ccOn and Lighting or nil
                    if CFG.ccOn then
                        S.fxCC.Brightness, S.fxCC.Contrast, S.fxCC.Saturation = CFG.ccBright, CFG.ccContrast, CFG.ccSat
                        S.fxCC.TintColor = Color3.fromHSV(CFG.ccH, CFG.ccS, CFG.ccV)
                    end
                    S.fxBloom.Parent = CFG.bloomOn and Lighting or nil
                    if CFG.bloomOn then S.fxBloom.Intensity, S.fxBloom.Size, S.fxBloom.Threshold = CFG.bloomInt, CFG.bloomSize, CFG.bloomThr end
                    S.fxBlur.Parent = CFG.blurOn and Lighting or nil
                    if CFG.blurOn then S.fxBlur.Size = CFG.blurSize end
                end
            end)
            task.wait(0.2)
        end
        if hat then pcall(function() hat:Destroy() end) end
        for _, x in ipairs({S.fxCC, S.fxBloom, S.fxBlur}) do pcall(function() x:Destroy() end) end
        for k in pairs(saved) do give(k) end
    end)
end

------------------------------------------------------------------ bullet tracers
do
    local folder = Instance.new("Folder")
    folder.Name = "ZenithBS2Tracers"
    folder.Parent = workspace
    local function seg(a, b, col, w)
        local len = (b - a).Magnitude
        if len < 0.05 then return nil end
        local p = Instance.new("Part")
        p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
        p.Material = Enum.Material.Neon
        p.Color = col
        p.Size = Vector3.new(w, w, len)
        p.CFrame = CFrame.lookAt((a + b) / 2, b)
        p.Parent = folder
        return p
    end
    local function muzzle()
        for _, vm in ipairs(viewModels()) do
            local inter = vm:FindFirstChild("Interactables")
            local mp = inter and (inter:FindFirstChild("MuzzlePart") or inter:FindFirstChild("MuzzlePartR") or inter:FindFirstChild("MuzzlePartL"))
                or vm:FindFirstChild("MuzzlePart", true)
            if mp then
                -- the suppressor (USP-S, M4A1-S) wins when it is on, otherwise the barrel the gun has
                local best
                for _, p in ipairs(mp:GetChildren()) do
                    if p:IsA("BasePart") and p.Transparency < 1 then
                        local a = p:FindFirstChildOfClass("Attachment")
                        if a and (not best or p.Name == "Suppressor") then best = a end
                    end
                end
                if not best then
                    for _, p in ipairs(mp:GetChildren()) do
                        local a = p:FindFirstChildOfClass("Attachment")
                        if a then best = a break end
                    end
                end
                if best then return best.WorldPosition end
                return mp.Position
            end
        end
        local c = workspace.CurrentCamera.CFrame
        return c.Position + c.LookVector * 1.5 + c.RightVector * 0.5 - c.UpVector * 0.45
    end
    S.onBullet = function(res)
        if not running or not CFG.bTracers then return end
        local o = typeof(res.Origin) == "Vector3" and res.Origin or nil
        local d = typeof(res.Direction) == "Vector3" and res.Direction or nil
        if not o or not d then return end
        local endp
        local h = res.Hits and res.Hits[1]
        if h and typeof(h.Position) == "Vector3" then endp = h.Position else endp = o + d.Unit * (tonumber(res.Distance) or 300) end
        local start = muzzle()
        local col1 = Color3.fromHSV(CFG.trH, CFG.trS, CFG.trV)
        local col2 = CFG.trGrad and Color3.fromHSV(CFG.trH2, CFG.trS2, CFG.trV2) or col1
        local th = CFG.trThick
        local life = CFG.bTracerTime
        local parts = {}
        if CFG.bTracerType == "Lightning" then
            local n = math.clamp(math.floor((endp - start).Magnitude / 3), 6, 48)
            local dir = (endp - start)
            local side = dir:Cross(Vector3.new(0, 1, 0))
            side = side.Magnitude > 0.01 and side.Unit or Vector3.new(1, 0, 0)
            local up = side:Cross(dir).Unit
            local prev = start
            for k = 1, n do
                local t = k / n
                local pt = start + dir * t
                if k < n then pt = pt + side * (math.random() - 0.5) * 1.8 + up * (math.random() - 0.5) * 1.8 end
                local p = seg(prev, pt, col1:Lerp(col2, t), th)
                if p then parts[#parts + 1] = p end
                prev = pt
            end
        else
            -- the beam in several pieces so the colour can shift from end to end
            local n = CFG.trGrad and 12 or 1
            for k = 1, n do
                local a = (k - 1) / n
                local b = k / n
                local p = seg(start:Lerp(endp, a), start:Lerp(endp, b), col1:Lerp(col2, (a + b) / 2), th)
                if p then parts[#parts + 1] = p end
            end
            local glow = seg(start, endp, col1:Lerp(col2, 0.5), th * 3)
            if glow then
                glow.Transparency = 0.78
                parts[#parts + 1] = glow
            end
        end
        local t0 = tick()
        while tick() - t0 < life do
            local a = (tick() - t0) / life
            for _, p in ipairs(parts) do
                if p.Parent then p.Transparency = math.max(p.Transparency, a) end
            end
            if CFG.bTracerType == "Lightning" and math.random() < 0.3 then
                for _, p in ipairs(parts) do p.Color = p.Color:Lerp(Color3.new(1, 1, 1), math.random() * 0.5) end
            end
            RunService.Heartbeat:Wait()
        end
        for _, p in ipairs(parts) do pcall(function() p:Destroy() end) end
    end
    S.tracerFolder = folder
    local tracerFn = S.onBullet
    S.onBullet = function(res)
        ident()
        S.lastShotAt = tick()
        if type(res) == "table" and typeof(res.Direction) == "Vector3" and res.Direction.Magnitude > 1.5 then S.dirMag = res.Direction.Magnitude end
        local st = S.shotTarget
        if st and not st.filled and tick() - st.at < 0.3 and st.m then
            st.filled = true
            pcall(function()
                st.weapon = currentWeapon() or "?"
                local w = S.curWeapon and S.curWeapon()
                st.scoped = w and (w.IsSniperScoped == true or w.IsAiming == true) or false
                local p = st.m:FindFirstChild(st.part)
                st.wall = p and not visible(p, st.m) or false
                local me = myModel()
                local mr = me and (me.PrimaryPart or me:FindFirstChild("HumanoidRootPart"))
                local r = st.m.PrimaryPart or st.m:FindFirstChild("HumanoidRootPart")
                st.dist = (mr and r) and math.floor((r.Position - mr.Position).Magnitude) or nil
            end)
        end
        S.dbg.shots = S.dbg.shots + 1
        if S.onBulletHit then task.spawn(pcall, S.onBulletHit, res) end
        if S.extraShots then task.spawn(pcall, S.extraShots, res) end
        return tracerFn(res)
    end
end

------------------------------------------------------------------ aimbot (camera)
local holding = false
connect(UIS.InputBegan, function(i)
ident()
    if i.UserInputType == Enum.UserInputType.MouseButton2 then holding = true end
end)
connect(UIS.InputEnded, function(i)
ident()
    if i.UserInputType == Enum.UserInputType.MouseButton2 then holding = false end
end)
local aimTarget
RunService:BindToRenderStep("ZenithBS2Aim", Enum.RenderPriority.Last.Value + 5, function()
ident()
    if not running or not CFG.aimbot then
        aimTarget = nil
        return
    end
    local active = CFG.aimKey == "Always" or holding or (UIS.TouchEnabled and not UIS.KeyboardEnabled)
    if not active then
        aimTarget = nil
        return
    end
    aimTarget = pick(CFG.aimFov)
    if not aimTarget then return end
    local c = workspace.CurrentCamera
    local k = 1 / math.max(CFG.smooth, 1)
    if mousemoverel and UIS.MouseEnabled and not UIS.TouchEnabled then
        local sp = c:WorldToViewportPoint(aimTarget.Position)
        local vp = c.ViewportSize
        local dx, dy = (sp.X - vp.X / 2) * k, (sp.Y - vp.Y / 2) * k
        pcall(mousemoverel, dx, dy)
    else
        local from = c.CFrame.Position
        setView(c.CFrame:Lerp(CFrame.lookAt(from, aimTarget.Position), k))
    end
end)

------------------------------------------------------------------ gun mods
local function groupOf(key)
    if type(key) ~= "string" then return nil end
    local k = string.lower(key)
    if string.find(k, "reload", 1, true) then
        if string.find(k, "time", 1, true) or string.find(k, "duration", 1, true) or string.find(k, "length", 1, true) then return "fastReload", "time" end
        if string.find(k, "speed", 1, true) then return "fastReload", "speed" end
        return nil
    end
    for _, bad in ipairs({"recover", "decay", "reset", "rate", "return", "time", "speed", "max"}) do
        if string.find(k, bad, 1, true) and not string.find(k, "maxspread", 1, true) then
            if bad ~= "max" then return nil end
        end
    end
    for _, w in ipairs({"recoil", "kick", "punch", "shake", "sway"}) do
        if string.find(k, w, 1, true) then return "noRecoil" end
    end
    for _, w in ipairs({"spread", "inaccura", "bloom", "deviation"}) do
        if string.find(k, w, 1, true) then return "noSpread" end
    end
    return nil
end
local function want(group, kind, orig)
    if group == "fastReload" then
        if type(orig) ~= "number" or orig <= 0 then return nil end
        if kind == "speed" then return orig * 10 end
        return math.min(orig, 0.1)
    end
    local t = typeof(orig)
    if t == "number" then return 0 end
    if t == "Vector2" then return Vector2.zero end
    if t == "Vector3" then return Vector3.zero end
    if t == "NumberRange" then return NumberRange.new(0) end
    if t == "table" then return "zeroArray" end
    return nil
end
local saved = {}
local function writable(t)
    if table.isfrozen and table.isfrozen(t) then
        if setreadonly then pcall(setreadonly, t, false)
        elseif make_writeable then pcall(make_writeable, t) end
    end
end
local function hold(t, key, on, newv)
    saved[t] = saved[t] or {}
    if saved[t][key] == nil then saved[t][key] = rawget(t, key) end
    local base = saved[t][key]
    local w = on and newv(base) or base
    if w ~= nil and rawget(t, key) ~= w then
        writable(t)
        pcall(rawset, t, key, w)
    end
end
local function patchTable(tbl, depth, visited)
    if visited[tbl] then return end
    visited[tbl] = true
    -- the game's recoil: Recoil = {Pattern, Damper, Speed, RecoverySpeed, Scale, CameraScale}; camera kick = spring * Scale * CameraScale
    local rec = rawget(tbl, "Recoil")
    if type(rec) == "table" and (rawget(rec, "Scale") ~= nil or rawget(rec, "CameraScale") ~= nil) then
        for _, k in ipairs({"Scale", "CameraScale"}) do
            if type(rawget(rec, k)) == "number" then hold(rec, k, CFG.noRecoil, function() return 0 end) end
        end
    end
    -- spread = spring (clamped to Range.Min..Max) + speed * MovementMultiplier; PerShot pushes it each shot
    local sp = rawget(tbl, "Spread")
    if type(sp) == "table" then
        for _, k in ipairs({"PerShot", "MovementMultiplier", "JumpShotMinimum"}) do
            if type(rawget(sp, k)) == "number" then hold(sp, k, CFG.noSpread, function() return 0 end) end
        end
        local range = rawget(sp, "Range")
        if type(range) == "table" then
            for _, k in ipairs({"Min", "Max"}) do
                if type(rawget(range, k)) == "number" then hold(range, k, CFG.noSpread, function() return 0 end) end
            end
        end
    end
    if type(rawget(tbl, "FireRate")) == "number" then
        hold(tbl, "FireRate", CFG.fireRateOn, function(b) return b / math.max(CFG.fireRateMul, 1) end)
    end
    for key, v in pairs(tbl) do
        local group, kind = groupOf(key)
        if (key == "Recoil" or key == "Spread") and type(v) == "table" then group = nil end
        if group and type(v) == "table" then
            -- only plain numbers inside, never the spring settings
            for i, x in pairs(v) do
                local ik = type(i) == "string" and string.lower(i) or ""
                if type(x) == "number" and not string.find(ik, "speed", 1, true) and not string.find(ik, "damp", 1, true)
                    and not string.find(ik, "recover", 1, true) and not string.find(ik, "time", 1, true) then
                    hold(v, i, CFG[group], function(b) return want(group, kind, b) end)
                end
            end
            group = nil
        end
        if group then
            saved[tbl] = saved[tbl] or {}
            if saved[tbl][key] == nil then
                if type(v) == "table" then
                    local copy = {}
                    for i, x in pairs(v) do copy[i] = x end
                    saved[tbl][key] = copy
                else
                    saved[tbl][key] = v
                end
            end
            local base = saved[tbl][key]
            if CFG[group] then
                local w = want(group, kind, base)
                if w == "zeroArray" then
                    for i, x in pairs(v) do
                        local z = want(group, kind, x)
                        if z ~= nil and z ~= "zeroArray" then pcall(rawset, v, i, z) end
                    end
                elseif w ~= nil and v ~= w then
                    writable(tbl)
                    pcall(rawset, tbl, key, w)
                end
            elseif type(base) == "table" and type(v) == "table" then
                for i, x in pairs(base) do pcall(rawset, v, i, x) end
            elseif v ~= base then
                pcall(rawset, tbl, key, base)
            end
        elseif type(v) == "table" and depth > 0 and type(key) ~= "number" then
            patchTable(v, depth - 1, visited)
        end
    end
end
local function patchAttrs(inst)
    local okA, attrs = pcall(function() return inst:GetAttributes() end)
    if not okA or not attrs then return end
    for key, orig in pairs(attrs) do
        local group, kind = groupOf(key)
        if group and string.sub(key, 1, 7) ~= "Zenith_" then
            local svKey = "Zenith_" .. key
            local base = inst:GetAttribute(svKey)
            if base == nil then
                base = orig
                pcall(function() inst:SetAttribute(svKey, orig) end)
            end
            local w = CFG[group] and want(group, kind, base) or base
            if w ~= nil and w ~= "zeroArray" and orig ~= w then pcall(function() inst:SetAttribute(key, w) end) end
        end
    end
end
local modCache
local function weaponModules()
    if modCache then return modCache end
    modCache = {}
    local db = RS:FindFirstChild("Database")
    local custom = db and db:FindFirstChild("Custom")
    local wf = custom and custom:FindFirstChild("Weapons")
    if wf then
        for _, d in ipairs(wf:GetChildren()) do
            if d:IsA("ModuleScript") then modCache[#modCache + 1] = d end
        end
        return modCache
    end
    for _, d in ipairs(RS:GetDescendants()) do
        if d:IsA("ModuleScript") then
            local n = string.lower(d.Name)
            local path = string.lower(d:GetFullName())
            if string.find(path, "weapon", 1, true) or string.find(path, "gun", 1, true) or string.find(n, "config", 1, true)
                or string.find(n, "stats", 1, true) or string.find(n, "settings", 1, true) or string.find(n, "recoil", 1, true)
                or string.find(n, "spread", 1, true) then
                modCache[#modCache + 1] = d
            end
        end
    end
    return modCache
end
local lastMods, lastFull, lastVm = "", 0, nil
task.spawn(function()
ident()
    while running do
        local sig = tostring(CFG.noRecoil) .. tostring(CFG.noSpread) .. tostring(CFG.fastReload) .. tostring(CFG.fireRateOn) .. tostring(CFG.fireRateMul)
        local any = CFG.noRecoil or CFG.noSpread or CFG.fastReload or CFG.fireRateOn
        local vm
        vm = viewModels()[1]
        if (any and (vm ~= lastVm or tick() - lastFull > 12)) or sig ~= lastMods then
            local visited = {}
            for _, mod in ipairs(weaponModules()) do
                local ok, t = pcall(require, mod)
                if ok and type(t) == "table" then pcall(patchTable, t, 4, visited) end
            end
            -- the memory sweep only when a setting changes or a new gun shows up, never on a timer
            if getgc and (sig ~= lastMods or vm ~= lastVm) then
                local okg, gc = pcall(getgc, true)
                if okg and gc then
                    for i, v in ipairs(gc) do
                        if type(v) == "table" and not visited[v] and (rawget(v, "Recoil") ~= nil or rawget(v, "Spread") ~= nil or rawget(v, "FireRate") ~= nil) then
                            pcall(patchTable, v, 2, visited)
                        end
                        if i % 6000 == 0 then task.wait() end
                    end
                end
                if vm then for _, d in ipairs(vm:GetDescendants()) do patchAttrs(d) end end
            end
            lastMods, lastVm, lastFull = sig, vm, tick()
        end
        task.wait(1.5)
    end
end)
-- camera kick that still slips through: the pitch the gun adds right after a shot is taken back
do
    local lastPitch, shotAt = nil, 0
    connect(UIS.InputBegan, function(i)
ident()
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then shotAt = tick() end
    end)
    RunService:BindToRenderStep("ZenithBS2Recoil", Enum.RenderPriority.Last.Value + 6, function()
ident()
        local c = workspace.CurrentCamera
        if not running or not CFG.noRecoil then
            lastPitch = nil
            return
        end
        local cf = c.CFrame
        local pitch, yaw, roll = cf:ToOrientation()
        local firing = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or tick() - shotAt < 0.25
        if firing and lastPitch and pitch > lastPitch + 0.0005 and not (CFG.aimbot and aimTarget) then
            pitch = lastPitch
            c.CFrame = CFrame.new(cf.Position) * CFrame.fromOrientation(pitch, yaw, 0)
        elseif math.abs(roll) > 0.001 then
            c.CFrame = CFrame.new(cf.Position) * CFrame.fromOrientation(pitch, yaw, 0)
        end
        lastPitch = pitch
    end)
end

------------------------------------------------------------------ chams: hands, gloves, you
do
    local saved = {}
    local function styleOf()
        local st = CFG.chamStyle
        if st == "Neon" then return Enum.Material.Neon, 0.35 end
        if st == "Glass" then return Enum.Material.Glass, 0.45 end
        return Enum.Material.ForceField, 0
    end
    local function paint(part, on, cat)
        if on then
            if not saved[part] then
                local st = {part.Material, part.Color, part.Transparency, extra = {}}
                for _, ch in ipairs(part:GetChildren()) do
                    if ch:IsA("SurfaceAppearance") or ch:IsA("Decal") or ch:IsA("Texture") then
                        st.extra[#st.extra + 1] = ch
                        pcall(function() ch.Parent = nil end)
                    end
                end
                if part:IsA("MeshPart") then
                    st.tex = part.TextureID
                    pcall(function() part.TextureID = "" end)
                end
                local sm = part:FindFirstChildOfClass("SpecialMesh")
                if sm then
                    st.sm, st.smTex = sm, sm.TextureId
                    sm.TextureId = ""
                end
                st.cat = cat
                saved[part] = st
            end
            local mat, tr = styleOf()
            local col = (cat == "weaponChams") and Color3.fromHSV(CFG.wcH, CFG.wcS, CFG.wcV) or accentCol()
            if part.Material ~= mat then part.Material = mat end
            if part.Color ~= col then part.Color = col end
            if part.Transparency < tr then part.Transparency = tr end
        elseif saved[part] then
            local o = saved[part]
            part.Material, part.Color, part.Transparency = o[1], o[2], o[3]
            for _, ch in ipairs(o.extra or {}) do pcall(function() ch.Parent = part end) end
            if o.tex then pcall(function() part.TextureID = o.tex end) end
            if o.sm then pcall(function() o.sm.TextureId = o.smTex end) end
            saved[part] = nil
        end
    end
    local selfHl
    local hg2 = Instance.new("Folder")
    hg2.Name = "ZenithBS2Self"
    pcall(function() hg2.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not hg2.Parent then hg2.Parent = lp:WaitForChild("PlayerGui") end
    task.spawn(function()
ident()
        while running do
            pcall(function()
                if not (CFG.handChams or CFG.gloveChams or CFG.weaponChams or CFG.selfChams) and next(saved) == nil then return end
                local c = workspace.CurrentCamera
                for _, vm in ipairs(viewModels()) do
                    if vm:IsA("Model") then
                        for _, d in ipairs(vm:GetDescendants()) do
                            if d:IsA("BasePart") then
                                local n = string.lower(d.Name)
                                local par = d.Parent and string.lower(d.Parent.Name) or ""
                                if string.find(n, "glove", 1, true) or string.find(par, "glove", 1, true) then
                                    paint(d, CFG.gloveChams, "gloveChams")
                                elseif n == "leftarm" or n == "rightarm" or n == "left arm" or n == "right arm" or n == "lefthand" or n == "righthand"
                                    or n == "leftupperarm" or n == "rightupperarm" or n == "leftlowerarm" or n == "rightlowerarm" or n == "arms" or n == "hands"
                                    or par == "arms" or par == "leftarm" or par == "rightarm" or par == "left arm" or par == "right arm" then
                                    paint(d, CFG.handChams, "handChams")
                                elseif d.Transparency < 1 or d.LocalTransparencyModifier < 1 then
                                    paint(d, CFG.weaponChams, "weaponChams")
                                end
                            end
                        end
                    end
                end
                for p, st in pairs(saved) do
                    if st.cat and not CFG[st.cat] then pcall(paint, p, false) end
                end
                for p in pairs(saved) do
                    if not p.Parent then saved[p] = nil end
                end
                local mm = myModel()
                if mm then
                    for _, d in ipairs(mm:GetDescendants()) do
                        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Name ~= "CollisionCapsule" then
                            paint(d, CFG.selfChams, "selfChams")
                        end
                    end
                end
                local vmModel
                vmModel = viewModels()[1]
                if false and vmModel then
                    if not (S.vmHl and S.vmHl.Parent) then
                        S.vmHl = Instance.new("Highlight")
                        S.vmHl.DepthMode = Enum.HighlightDepthMode.Occluded
                        S.vmHl.Parent = hg2
                    end
                    local col = accentCol()
                    S.vmHl.Adornee = vmModel
                    S.vmHl.FillColor, S.vmHl.OutlineColor = col, col
                    S.vmHl.FillTransparency = 0.45
                    S.vmHl.OutlineTransparency = 0.3
                    S.vmHl.Enabled = true
                elseif S.vmHl then
                    S.vmHl.Enabled = false
                end
                if CFG.selfChams and mm then
                    if not (selfHl and selfHl.Parent) then
                        selfHl = Instance.new("Highlight")
                        selfHl.DepthMode = Enum.HighlightDepthMode.Occluded
                        selfHl.Parent = hg2
                    end
                    local col = accentCol()
                    selfHl.Adornee = mm
                    selfHl.FillColor, selfHl.OutlineColor = col, col
                    selfHl.FillTransparency = (CFG.chamStyle == "Glass") and 0.55 or 0.25
                    selfHl.OutlineTransparency = 0.2
                    selfHl.Enabled = true
                elseif selfHl then
                    selfHl.Enabled = false
                end
            end)
            task.wait(0.3)
        end
        for p in pairs(saved) do pcall(paint, p, false) end
    end)
end

------------------------------------------------------------------ hit notify
do
    local hp, lastFire, shot = {}, 0, nil
    local alive0 = {}
    local function snapshot()
        local me = myModel()
        local air = false
        if me and S.RK then
            local okG, g, known = pcall(S.RK.isOnGround, me)
            if okG and known then air = not g end
        end
        local scoped = lp:GetAttribute("IsSniperScoped") == true or workspace.CurrentCamera.FieldOfView < 55
        local t = S.aimT or aimTarget
        local wall = false
        if t and t.Parent then
            local okV, vis = pcall(visible, t, t.Parent)
            wall = okV and not vis
        end
        shot = {at = tick(), air = air, scoped = scoped, wall = wall, target = t}
    end
    connect(UIS.InputBegan, function(i)
ident()
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            lastFire = tick()
            pcall(snapshot)
        end
    end)
    -- their own hit marker / blood: a sure sign one of your bullets landed
    task.spawn(function()
ident()
        if not (hookfunction and newcclosure) or S.markerHooked then return end
        pcall(function()
            local lib = RS:WaitForChild("Components", 10):WaitForChild("Common", 10):WaitForChild("VFXLibary", 10)
            for _, nm in ipairs({"CreateMarker", "CreateBloodSplatter"}) do
                local mod = lib:FindFirstChild(nm)
                local ok, f = pcall(require, mod)
                if ok and type(f) == "function" then
                    local orig
                    orig = hookfunction(f, newcclosure(function(...)
                        S.markerAt = tick()
                        return orig(...)
                    end))
                end
            end
            S.markerHooked = true
        end)
    end)
    task.spawn(function()
ident()
        local pg = lp:WaitForChild("PlayerGui", 10)
        if not pg then return end
        connect(pg.DescendantAdded, function(d)
ident()
            if not d:IsA("GuiObject") then return end
            local n = string.lower(d.Name)
            if string.find(n, "hitmark", 1, true) or n == "marker" or string.find(n, "hit marker", 1, true) or n == "hit" then
                S.markerAt = tick()
            end
        end)
    end)
    local function hpOf(m, plr)
        local h = m:FindFirstChildOfClass("Humanoid")
        if h then return h.Health end
        local a = tonumber(m:GetAttribute("Health")) or tonumber(m:GetAttribute("HP"))
        if a then return a end
        if plr then return tonumber(plr:GetAttribute("Health")) or tonumber(plr:GetAttribute("HP")) end
        return nil
    end
    local function tags()
        if not shot then return "" end
        local t = {}
        if shot.air then t[#t + 1] = "jump" end
        if shot.wall then t[#t + 1] = "wallbang" end
        local g = groupNow()
        if g == "Snipers" then t[#t + 1] = shot.scoped and "scope" or "noscope" end
        if #t == 0 then return "" end
        return '   <font color="#9a9ca6">' .. table.concat(t, "  ") .. "</font>"
    end
    local function nm(n)
        local c = palCol(CFG.hnCol, Color3.fromRGB(165, 100, 255))
        return '<font color="#' .. c:ToHex() .. '"><b>' .. n .. "</b></font>"
    end
    local function dst(d) return d and ('   <font color="#9a9ca6">' .. d .. "m</font>") or "" end
    local hg = Instance.new("ScreenGui")
    hg.Name = "ZenithBS2Hits"
    hg.IgnoreGuiInset = true
    hg.ResetOnSpawn = false
    hg.DisplayOrder = 60
    pcall(function() hg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not hg.Parent then hg.Parent = lp:WaitForChild("PlayerGui") end
    local list = Instance.new("Frame")
    list.BackgroundTransparency = 1
    list.AnchorPoint = Vector2.new(1, 0)
    list.Position = UDim2.new(1, -16, 0, 70)
    list.Size = UDim2.new(0, 300, 0, 200)
    list.Parent = hg
    local lay = Instance.new("UIListLayout")
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 4)
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
    lay.Parent = list
    local n = 0
    local LOG = {}
    local logFrame = Instance.new("Frame")
    logFrame.AnchorPoint = Vector2.new(0.5, 0)
    logFrame.Position = UDim2.new(0.5, 0, 0.5, 70)
    logFrame.Size = UDim2.fromOffset(0, 0)
    logFrame.AutomaticSize = Enum.AutomaticSize.XY
    logFrame.BackgroundTransparency = 1
    logFrame.Parent = hg
    local ll = Instance.new("UIListLayout")
    ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = logFrame
    for _ = 1, 8 do
        local t = Instance.new("TextLabel")
        t.Size = UDim2.fromOffset(0, 16)
        t.AutomaticSize = Enum.AutomaticSize.X
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamBold
        t.TextSize = 13
        t.TextColor3 = Color3.new(1, 1, 1)
        t.TextStrokeColor3 = Color3.new(0, 0, 0)
        t.TextStrokeTransparency = 0.4
        t.Visible = false
        t.Parent = logFrame
        LOG[#LOG + 1] = {t = t, gen = 0}
    end
    local logN = 0
    local LOGCOL = {hit = Color3.new(1, 1, 1), head = Color3.fromRGB(255, 60, 60), kill = Color3.fromRGB(255, 60, 60), miss = Color3.fromRGB(255, 95, 95)}
    -- top-right cards: body figure + HIT / KILL / MISS, name, part, damage
    local tr = Instance.new("Frame")
    tr.AnchorPoint = Vector2.new(1, 0)
    tr.Position = UDim2.new(1, -16, 0, 70)
    tr.Size = UDim2.fromOffset(230, 0)
    tr.AutomaticSize = Enum.AutomaticSize.Y
    tr.BackgroundTransparency = 1
    tr.Parent = hg
    local trl = Instance.new("UIListLayout")
    trl.Padding = UDim.new(0, 6)
    trl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    trl.SortOrder = Enum.SortOrder.LayoutOrder
    trl.Parent = tr
    local HC = {}
    local GREY = Color3.fromRGB(80, 82, 92)
    local RED = Color3.fromRGB(255, 70, 80)
    for _ = 1, 5 do
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(230, 48)
        f.BackgroundColor3 = Color3.fromRGB(10, 10, 13)
        f.BackgroundTransparency = 0.3
        f.BorderSizePixel = 0
        f.Visible = false
        f.Parent = tr
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
        local stk = Instance.new("UIStroke")
        stk.Color = Color3.new(1, 1, 1)
        stk.Transparency = 0.88
        stk.Parent = f
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 1, -16)
        bar.Position = UDim2.fromOffset(0, 8)
        bar.BorderSizePixel = 0
        bar.Parent = f
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
        -- the figure
        local fig = Instance.new("Frame")
        fig.Size = UDim2.fromOffset(26, 40)
        fig.Position = UDim2.fromOffset(10, 4)
        fig.BackgroundTransparency = 1
        fig.Parent = f
        local parts = {}
        local function bp(g, x, y, w, h, round)
            local p = Instance.new("Frame")
            p.Position = UDim2.fromOffset(x, y)
            p.Size = UDim2.fromOffset(w, h)
            p.BorderSizePixel = 0
            p.BackgroundColor3 = GREY
            p.Parent = fig
            Instance.new("UICorner", p).CornerRadius = UDim.new(0, round or 2)
            parts[#parts + 1] = {p, g}
        end
        local function bone(g, ax, ay, bx, by)
            local l = Instance.new("Frame")
            local dx, dy = bx - ax, by - ay
            l.AnchorPoint = Vector2.new(0.5, 0.5)
            l.Position = UDim2.fromOffset((ax + bx) / 2, (ay + by) / 2)
            l.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, 2)
            l.Rotation = math.deg(math.atan2(dy, dx))
            l.BorderSizePixel = 0
            l.BackgroundColor3 = GREY
            l.Parent = fig
            parts[#parts + 1] = {l, g}
        end
        -- skull: round cranium, jaw, two dark eyes, a nose and teeth
        bp("skull", 3, 3, 22, 20, 10)
        bp("skull", 7, 19, 14, 9, 3)
        local function hole(x, y, w, h, r)
            local p = Instance.new("Frame")
            p.Position, p.Size, p.BorderSizePixel = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h), 0
            p.BackgroundColor3 = Color3.fromRGB(10, 10, 13)
            p.ZIndex = 3
            p.Parent = fig
            Instance.new("UICorner", p).CornerRadius = UDim.new(0, r)
        end
        hole(7, 10, 6, 6, 3) hole(15, 10, 6, 6, 3)
        hole(12.5, 17, 3, 3, 1)
        hole(9, 24, 2, 4, 0) hole(13, 24, 2, 4, 0) hole(17, 24, 2, 4, 0)
        local t1 = Instance.new("TextLabel")
        t1.BackgroundTransparency = 1
        t1.Position = UDim2.fromOffset(44, 6)
        t1.Size = UDim2.new(1, -52, 0, 18)
        t1.Font = Enum.Font.GothamBold
        t1.TextSize = 13
        t1.RichText = true
        t1.TextXAlignment = Enum.TextXAlignment.Left
        t1.TextColor3 = Color3.new(1, 1, 1)
        t1.TextTruncate = Enum.TextTruncate.AtEnd
        t1.Parent = f
        local t2 = Instance.new("TextLabel")
        t2.BackgroundTransparency = 1
        t2.Position = UDim2.fromOffset(44, 25)
        t2.Size = UDim2.new(1, -52, 0, 16)
        t2.Font = Enum.Font.GothamMedium
        t2.TextSize = 11
        t2.TextXAlignment = Enum.TextXAlignment.Left
        t2.TextColor3 = Color3.fromRGB(170, 172, 182)
        t2.Parent = f
        HC[#HC + 1] = {f = f, bar = bar, parts = parts, t1 = t1, t2 = t2, gen = 0}
    end
    local hcN = 0
    S.hitCard = function(kind, name, part, dmg, left, info)
        local c = HC[1]
        if not c then return end
        table.remove(HC, 1)
        HC[#HC + 1] = c
        hcN = hcN + 1
        c.gen = c.gen + 1
        local gen = c.gen
        c.f.LayoutOrder = -hcN
        local col = (kind == "miss") and Color3.fromRGB(255, 150, 160) or (kind == "kill" and RED) or accentCol()
        c.bar.BackgroundColor3 = col
        for _, pp in ipairs(c.parts) do
            local cc2 = (kind == "kill") and RED or Color3.fromRGB(235, 235, 240)
            if pp[3] then pp[1].Color = cc2 else pp[1].BackgroundColor3 = cc2 end
        end
        local word = (kind == "kill" and "KILL") or (kind == "miss" and "MISS") or "HIT"
        c.t1.Text = '<font color="#' .. col:ToHex() .. '">' .. word .. "</font>  " .. name
        if kind == "kill" then
            local bits = {}
            if info and info.weapon then bits[#bits + 1] = info.weapon end
            if info and info.dist then bits[#bits + 1] = info.dist .. " studs" end
            if info and info.scoped then bits[#bits + 1] = "scope" end
            if info and info.wall then bits[#bits + 1] = "wallbang" end
            bits[#bits + 1] = part
            c.t2.Text = table.concat(bits, "  ·  ")
        elseif kind == "miss" then
            c.t2.Text = part .. "  ·  not counted by server"
        else
            c.t2.Text = part .. "  ·  -" .. dmg .. "  ·  " .. left .. " hp left"
        end
        c.f.BackgroundTransparency = 0.3
        c.f.Visible = true
        task.delay(3, function()
            if c.gen ~= gen then return end
            pcall(function()
                TweenService:Create(c.f, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            end)
            task.wait(0.3)
            if c.gen == gen then c.f.Visible = false end
        end)
    end
    S.hitLog = function(kind, text)
        local e = LOG[1]
        if not e then return end
        table.remove(LOG, 1)
        LOG[#LOG + 1] = e
        logN = logN + 1
        e.gen = e.gen + 1
        local gen = e.gen
        e.t.LayoutOrder = -logN
        e.t.Text = text
        e.t.TextColor3 = LOGCOL[kind] or LOGCOL.hit
        e.t.TextTransparency, e.t.TextStrokeTransparency = 0, 0.4
        e.t.Visible = true
        task.delay(4, function()
            if e.gen ~= gen then return end
            pcall(function()
                TweenService:Create(e.t, TweenInfo.new(1, Enum.EasingStyle.Linear), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
            end)
            task.wait(1)
            if e.gen == gen then e.t.Visible = false end
        end)
    end
    local CARDS = {}
    local function makeCard()
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 0, 0, 26)
        f.AutomaticSize = Enum.AutomaticSize.X
        f.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        f.BackgroundTransparency = 0.5
        f.BorderSizePixel = 0
        f.Parent = list
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 7)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 14), UDim.new(0, 10)
        pad.Parent = f
        local bar = Instance.new("Frame")
        bar.BorderSizePixel = 0
        bar.BackgroundColor3 = accentCol()
        bar.Position = UDim2.new(0, -9, 0.5, -6)
        bar.Size = UDim2.fromOffset(3, 12)
        bar.Parent = f
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.Size = UDim2.new(0, 0, 1, 0)
        t.AutomaticSize = Enum.AutomaticSize.X
        t.Font = Enum.Font.GothamMedium
        t.TextSize = 12
        t.TextColor3 = Color3.fromRGB(236, 237, 240)
        t.RichText = true
        t.Text = ""
        t.Parent = f
        f.Visible = false
        return {f = f, t = t, bar = bar, gen = 0}
    end
    for _ = 1, 6 do
        local ok, c = pcall(makeCard)
        if ok then CARDS[#CARDS + 1] = c end
    end
    local function card(text, kill)
        n = n + 1
        S.dbg.cards = (S.dbg.cards or 0) + 1
        -- the card shown longest ago is reused
        local c = CARDS[1]
        if not c then return end
        table.remove(CARDS, 1)
        CARDS[#CARDS + 1] = c
        c.gen = c.gen + 1
        local gen = c.gen
        c.f.LayoutOrder = -n
        c.f.BackgroundTransparency = 0.5
        c.t.TextTransparency = 0
        c.bar.BackgroundTransparency = 0
        c.bar.BackgroundColor3 = kill and Color3.fromRGB(255, 90, 90) or (accentCol())
        c.t.Text = text
        c.f.Visible = true
        task.delay(2.5, function()
            if c.gen ~= gen then return end
            local info = TweenInfo.new(0.3)
            pcall(function()
                TweenService:Create(c.f, info, {BackgroundTransparency = 1}):Play()
                TweenService:Create(c.t, info, {TextTransparency = 1}):Play()
                TweenService:Create(c.bar, info, {BackgroundTransparency = 1}):Play()
            end)
            task.wait(0.35)
            if c.gen == gen then c.f.Visible = false end
        end)
    end
    S.hitCheck = function(list2)
        do return end
        local seen = {}
        local now = tick()
        local recent = now - lastFire < 1.5
        local me = myModel()
        local mr = me and (me:FindFirstChild("HumanoidRootPart") or me.PrimaryPart)
        for _, it in ipairs(list2) do
            local m, enemy, plr = it[1], it[2], it[3]
            seen[m] = true
            alive0[m] = {enemy = enemy, plr = plr, root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart}
            local cur = hpOf(m, plr)
            local before = hp[m]
            if cur and before and cur < before and enemy and CFG.hitNotify and recent and tick() - (S.lastHitCard or 0) > 0.3 then
                local name = pname(plr, m)
                local tr = alive0[m].root
                local dist = (mr and tr) and math.floor((tr.Position - mr.Position).Magnitude) or nil
                local dmg = math.floor(before - cur + 0.5)
                if cur <= 0 then
                    card('<font color="#ffffff"><b>kill</b></font>   ' .. nm(name) .. dst(dist) .. tags(), true)
                else
                    card('<font color="#ffffff"><b>hit</b></font>   ' .. nm(name) .. '   <font color="#ffffff">-' .. dmg .. "</font>" .. dst(dist) .. tags(), false)
                end
                S.lastHitCard = now
            end
            hp[m] = cur
        end
        -- an enemy that dropped off the alive list right after your shot: a kill
        for m, info in pairs(alive0) do
            if not seen[m] then
                if info.enemy and CFG.hitNotify and recent then
                    local name = pname(info.plr, m)
                    local dist = (mr and info.root and info.root.Parent) and math.floor((info.root.Position - mr.Position).Magnitude) or nil
                    card('<font color="#ffffff"><b>kill</b></font>   ' .. nm(name) .. dst(dist) .. tags(), true)
                    S.lastHitCard = now
                end
                alive0[m] = nil
                hp[m] = nil
            end
        end
        -- their hit marker fired but no health is visible to us: still say it
        if CFG.hitNotify and S.markerAt and now - S.markerAt < 0.2 and now - (S.lastHitCard or 0) > 0.15 and recent then
            S.markerAt = nil
            local t = shot and shot.target
            local m = t and t.Parent
            local plr = m and Players:GetPlayerFromCharacter(m)
            local name = pname(plr, m)
            local dist = (mr and t and t.Parent) and math.floor((t.Position - mr.Position).Magnitude) or nil
            card('<font color="#ffffff"><b>hit</b></font>   ' .. nm(name) .. dst(dist) .. tags(), false)
            S.lastHitCard = now
        end
    end
    S.hitGui = hg
-- the game plays a hit sound / marker on every counted shot; ride on it for our kill / hit sounds
if hookfunction and newcclosure and S.markHook ~= 1 then
    S.markHook = 1
    task.spawn(function()
        local last = 0
        local function try(mod)
            if not (mod and mod:IsA("ModuleScript")) then return end
            local n = string.lower(mod.Name)
            if not (string.find(n, "hitmark", 1, true) or string.find(n, "hitsound", 1, true) or string.find(n, "hitindicator", 1, true)
                or string.find(n, "damageindicator", 1, true) or string.find(n, "crosshair", 1, true)) then return end
            local ok, t = pcall(require, mod)
            if not ok or type(t) ~= "table" then return end
            for k, v in pairs(t) do
                local lk = string.lower(tostring(k))
                if type(v) == "function" and (string.find(lk, "hit", 1, true) or string.find(lk, "mark", 1, true) or string.find(lk, "flash", 1, true)) then
                    local orig
                    orig = hookfunction(v, newcclosure(function(...)
                        if running and S.markHit and tick() - last > 0.03 then
                            last = tick()
                            local killed = false
                            for _, a in ipairs({...}) do
                                if a == true then killed = true end
                                if type(a) == "string" then local la = string.lower(a) if la == "kill" or la == "killed" or la == "headshot" then killed = true end end
                            end
                            pcall(S.markHit, killed)
                        end
                        return orig(...)
                    end))
                end
            end
        end
        for _, root in ipairs({RS, lp:FindFirstChild("PlayerScripts"), lp:FindFirstChild("PlayerGui")}) do
            if root then for _, d in ipairs(root:GetDescendants()) do pcall(try, d) end end
        end
    end)
end


    local pending = {}
    local PARTNAME = {Head = "head", UpperTorso = "body", LowerTorso = "body", HumanoidRootPart = "body", Torso = "body",
        LeftUpperArm = "arm", LeftLowerArm = "arm", LeftHand = "arm", RightUpperArm = "arm", RightLowerArm = "arm", RightHand = "arm",
        LeftUpperLeg = "leg", LeftLowerLeg = "leg", LeftFoot = "leg", RightUpperLeg = "leg", RightLowerLeg = "leg", RightFoot = "leg"}
    local function hpOfModel(m)
        return tonumber(m:GetAttribute("Health")) or (m:FindFirstChildOfClass("Humanoid") and m:FindFirstChildOfClass("Humanoid").Health) or 100
    end
    S.logShot = function(res)
        if type(res) ~= "table" then return end
        S.dbg.logCalls = (S.dbg.logCalls or 0) + 1
        local o, d = res.Origin, res.Direction
        if false and typeof(o) == "Vector3" and typeof(d) == "Vector3" and d.Magnitude > 0 then
            local u = d.Unit
            local best, bestM, bestPart
            for _, it in ipairs(S.models or {}) do
                if it[2] and not pending[it[1]] then
                    for _, n in ipairs({"Head", "UpperTorso", "Torso", "LowerTorso", "HumanoidRootPart"}) do
                        local p = it[1]:FindFirstChild(n)
                        if p and p:IsA("BasePart") then
                            local rel = p.Position - o
                            local along = rel:Dot(u)
                            if along > 0 then
                                local off = (rel - u * along).Magnitude
                                if off < 2.2 and (not best or off < best) then best, bestM, bestPart = off, it, n end
                            end
                        end
                    end
                end
            end
            if bestM then
                pending[bestM[1]] = {at = tick(), part = PARTNAME[bestPart] or "body", hp = hpOfModel(bestM[1]), plr = bestM[3]}
                S.dbg.logged = (S.dbg.logged or 0) + 1
                return
            end
        end
        if type(res.Hits) ~= "table" then return end
        for _, h in ipairs(res.Hits) do
            local inst = h.Instance or h.instance
            if typeof(inst) == "Instance" then
                for _, it in ipairs(S.models or {}) do
                    if it[2] and inst:IsDescendantOf(it[1]) and not pending[it[1]] then
                        pending[it[1]] = {at = tick(), part = PARTNAME[inst.Name] or "body", hp = hpOfModel(it[1]), plr = it[3]}
                        S.dbg.logged = (S.dbg.logged or 0) + 1
                        return
                    end
                end
            end
        end
    end
    connect(RunService.Heartbeat, function()
ident()
        do return end
        if not next(pending) then return end
        local now = tick()
        local me = myModel()
        local mr = me and (me:FindFirstChild("HumanoidRootPart") or me.PrimaryPart)
        for m, p in pairs(pending) do
            local dead = (not m.Parent) or m:GetAttribute("Dead") == true
            local hp = m.Parent and hpOfModel(m) or 0
            local r = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            local dist = (mr and r) and math.floor((r.Position - mr.Position).Magnitude) or nil
            if dead or hp <= 0 then
                pending[m] = nil
                if CFG.hitNotify and CFG.hnStyle == "Log" then
                    pcall(S.hitLog, "kill", ("killed %s - %s, %d dmg"):format(pname(p.plr, m), p.part, math.floor(p.hp + 0.5)))
                elseif CFG.hitNotify then
                    card('<font color="#ffffff"><b>kill</b></font>   ' .. nm(pname(p.plr, m)) .. '   <font color="#ffffff">' .. p.part .. '</font>'
                        .. '   <font color="#ffffff">-' .. math.floor(p.hp + 0.5) .. '</font>' .. dst(dist) .. tags(), true)
                end
                pcall(S.killGhost, m)
                S.lastHitCard = now
                pending[m] = nil
            elseif hp < p.hp then
                pending[m] = nil
                if CFG.hitNotify and CFG.hnStyle == "Log" then
                    pcall(S.hitLog, p.part == "head" and "head" or "hit", ("hit %s in the %s for %d (%d left)"):format(pname(p.plr, m), p.part,
                        math.floor(p.hp - hp + 0.5), math.floor(hp + 0.5)))
                elseif CFG.hitNotify then
                    card('<font color="#ffffff"><b>hit</b></font>   ' .. nm(pname(p.plr, m)) .. '   <font color="#ffffff">' .. p.part .. '   -'
                        .. math.floor(p.hp - hp + 0.5) .. '</font>   <font color="#9a9ca6">' .. math.floor(hp + 0.5) .. ' left</font>' .. dst(dist) .. tags(), false)
                end
                S.lastHitCard = now
                pending[m] = nil
            elseif now - p.at > 0.8 then
                pending[m] = nil
                if CFG.hitNotify and CFG.hnStyle == "Log" then
                    pcall(S.hitLog, "miss", ("missed %s in the %s due to server"):format(pname(p.plr, m), p.part))
                elseif CFG.hitNotify and CFG.missNotify ~= false then
                    card('<font color="#ff6b6b"><b>miss</b></font>   ' .. nm(pname(p.plr, m)) .. '   <font color="#9a9ca6">' .. p.part .. ' (server)</font>' .. dst(dist), false)
                end
                pending[m] = nil
            end
        end
    end)
    local lastHp = setmetatable({}, {__mode = "k"})
    local wasDead = setmetatable({}, {__mode = "k"})
    local PN = {Head = "head", UpperTorso = "body", LowerTorso = "body", HumanoidRootPart = "body", Torso = "body"}
    local function partWord(n) return PN[n] or (n and (string.find(n, "Arm") or string.find(n, "Hand")) and "arm") or (n and (string.find(n, "Leg") or string.find(n, "Foot")) and "leg") or "body" end
    local SOUNDS = {Neverlose = "rbxassetid://82938206376993", ["CS:GO Taser"] = "rbxassetid://7554632797"}
    local sndHit, sndKill = Instance.new("Sound"), Instance.new("Sound")
    sndHit.Volume, sndKill.Volume = 1.2, 1.4
    sndHit.Parent = game:GetService("SoundService")
    sndKill.Parent = game:GetService("SoundService")
    local function playS(snd, which)
        local id = SOUNDS[which]
        if not id then return end
        pcall(function()
            if snd.SoundId ~= id then snd.SoundId = id end
            snd.TimePosition = 0
            snd:Play()
        end)
    end
    S.markHit = function(killed)
        if killed and CFG.killSound ~= "None" then playS(sndKill, CFG.killSound)
        elseif not killed and CFG.hitSound ~= "None" then playS(sndHit, CFG.hitSound) end
    end
    local function sayHit(kind, m, plr, dmg, left, part)
        -- (sound now plays from the hit-marker hook, so it fires on every counted shot)
        if kind == "kill" then
            if not CFG.killNotify then return end
        elseif not CFG.hitNotify then
            return
        end
        local name = pname(plr, m)
        if S.hitCard then
            local st = S.shotTarget
            local info = (st and st.m == m) and st or nil
            pcall(S.hitCard, kind, name, part, dmg, left, info)
        elseif CFG.hnStyle == "Log" then
            if kind == "kill" then
                pcall(S.hitLog, "kill", ("killed %s - %s, %d dmg"):format(name, part, dmg))
            elseif kind == "miss" then
                pcall(S.hitLog, "miss", ("missed %s in the %s due to server"):format(name, part))
            else
                pcall(S.hitLog, part == "head" and "head" or "hit", ("hit %s in the %s for %d (%d left)"):format(name, part, dmg, left))
            end
        else
            local me = myModel()
            local mr = me and (me:FindFirstChild("HumanoidRootPart") or me.PrimaryPart)
            local r = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            local dist = (mr and r) and math.floor((r.Position - mr.Position).Magnitude) or nil
            if kind == "kill" then
                card('<font color="#ffffff"><b>kill</b></font>   ' .. nm(name) .. '   <font color="#ffffff">' .. part .. "</font>" .. dst(dist) .. tags(), true)
            elseif kind == "miss" then
                card('<font color="#ff6b6b"><b>miss</b></font>   ' .. nm(name) .. '   <font color="#9a9ca6">' .. part .. " (server)</font>" .. dst(dist), false)
            else
                card('<font color="#ffffff"><b>hit</b></font>   ' .. nm(name) .. '   <font color="#ffffff">' .. part .. "   -" .. dmg .. "</font>" .. dst(dist) .. tags(), false)
            end
        end
    end
    connect(RunService.Heartbeat, function()
        local now = tick()
        local shotRecent = now - (S.lastShotAt or 0) < 0.7
        local st = S.shotTarget
        for _, it in ipairs(S.models or {}) do
            local m, enemy, plr = it[1], it[2], it[3]
            if enemy then
                local hp = tonumber(m:GetAttribute("Health"))
                local dead = m:GetAttribute("Dead") == true or (hp ~= nil and hp <= 0)
                local prev = lastHp[m]
                if hp and prev and hp < prev and shotRecent then
                    -- yours if your silent shot was at this player, or he was the one under your crosshair
                    local mine = st and st.m == m and now - st.at < 0.7
                    if not mine and not (st and now - st.at < 0.7) then
                        local r = m:FindFirstChild("Head") or m.PrimaryPart
                        if r then
                            local sp, on = cam:WorldToViewportPoint(r.Position)
                            local vp = cam.ViewportSize
                            mine = on and (Vector2.new(sp.X, sp.Y) - vp / 2).Magnitude < 140
                        end
                    end
                    if mine then
                        local part = partWord(st and st.m == m and st.part or nil)
                        if dead then
                            sayHit("kill", m, plr, math.floor(prev + 0.5), 0, part)
                            if CFG.killFx then
                                if CFG.killFxType == "Blood" and S.killBlood then pcall(S.killBlood, m)
                                elseif CFG.killFxType == "Lightning" and S.killBolt then pcall(S.killBolt, m)
                                else pcall(S.killGhost, m) end
                            end
                        else
                            sayHit("hit", m, plr, math.floor(prev - hp + 0.5), math.floor(hp + 0.5), part)
                        end
                        if st and st.m == m then st.done = true end
                    end
                end
                if hp then lastHp[m] = hp end
            end
        end
        -- a silent shot at someone whose health did not move = the server did not count it
        if st and not st.done and not st.missed and now - st.at > 0.8 then
            st.missed = true
            if CFG.missNotify ~= false and st.m and st.m.Parent then
                local plr = Players:GetPlayerFromCharacter(st.m)
                sayHit("miss", st.m, plr, 0, 0, partWord(st.part))
            end
        end
    end)
    S.onBulletHit = function(res)
        do
            pcall(S.logShot, res)
            return
        end
        if not CFG.hitNotify or type(res) ~= "table" or type(res.Hits) ~= "table" then return end
        for _, h in ipairs(res.Hits) do
            local inst = h.Instance or h.instance
            if typeof(inst) == "Instance" then
                for _, it in ipairs(S.models or {}) do
                    if it[2] and inst:IsDescendantOf(it[1]) then
                        local me = myModel()
                        local mr = me and (me:FindFirstChild("HumanoidRootPart") or me.PrimaryPart)
                        local r = it[1]:FindFirstChild("HumanoidRootPart") or it[1].PrimaryPart
                        local dist = (mr and r) and math.floor((r.Position - mr.Position).Magnitude) or nil
                        local head = string.find(string.lower(inst.Name), "head", 1, true) ~= nil
                        card('<font color="#ffffff"><b>hit</b></font>   ' .. nm(pname(it[3], it[1])) .. (head and '   <font color="#ffffff">head</font>' or "")
                            .. dst(dist) .. tags(), false)
                        S.lastHitCard = tick()
                        return
                    end
                end
            end
        end
    end
end

------------------------------------------------------------------ our own line (a rotated frame) with the same fields as a Drawing line: From / To / Color / Visible / Thickness
do
    local lg = Instance.new("ScreenGui")
    lg.Name = "ZenithBS2Lines"
    lg.IgnoreGuiInset = true
    lg.ResetOnSpawn = false
    lg.DisplayOrder = 4
    pcall(function() lg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not lg.Parent then lg.Parent = lp:WaitForChild("PlayerGui") end
    S.lineGui = lg
    S.fline = function(thick, col)
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BorderSizePixel = 0
        f.BackgroundColor3 = col or Color3.new(1, 1, 1)
        f.Visible = false
        f.Parent = lg
        local from, to, th = Vector2.zero, Vector2.zero, thick or 1
        local function upd()
            local d = to - from
            f.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
            f.Size = UDim2.fromOffset(d.Magnitude + 1, th)
            f.Rotation = math.deg(math.atan2(d.Y, d.X))
        end
        return setmetatable({}, {
            __newindex = function(_, k, v)
                if k == "From" then from = v upd()
                elseif k == "To" then to = v upd()
                elseif k == "Color" then f.BackgroundColor3 = v
                elseif k == "Visible" then f.Visible = v
                elseif k == "Thickness" then th = v upd()
                elseif k == "Transparency" then f.BackgroundTransparency = 1 - v end
            end,
            __index = function(_, k)
                if k == "Remove" or k == "Destroy" then return function() f:Destroy() end end
                if k == "Visible" then return f.Visible end
                return nil
            end,
        })
    end
end

-- grenade esp (models tagged "Grenade" with a GrenadeName)
do
    local CS = game:GetService("CollectionService")
    local GCOL = {["HE Grenade"] = Color3.fromRGB(255, 80, 80), ["Flashbang"] = Color3.fromRGB(255, 255, 255),
        ["Smoke Grenade"] = Color3.fromRGB(170, 170, 180), ["Molotov"] = Color3.fromRGB(255, 140, 40),
        ["Incendiary Grenade"] = Color3.fromRGB(255, 140, 40), ["Decoy Grenade"] = Color3.fromRGB(120, 220, 120)}
    local G = {}
    local gFolder = Instance.new("Folder")
    gFolder.Name = "ZenithBS2Nades"
    pcall(function() gFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not gFolder.Parent then gFolder.Parent = lp:WaitForChild("PlayerGui") end
    local function add(m)
        if G[m] or not m:IsA("Model") then return end
        local name = tostring(m:GetAttribute("GrenadeName") or "grenade")
        local col = GCOL[name] or Color3.fromRGB(255, 220, 90)
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.fromOffset(150, 26)
        bb.AlwaysOnTop = true
        bb.StudsOffset = Vector3.new(0, 1.4, 0)
        bb.Adornee = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
        bb.Parent = gFolder
        local plate = Instance.new("Frame")
        plate.AnchorPoint = Vector2.new(0.5, 0.5)
        plate.Position = UDim2.fromScale(0.5, 0.5)
        plate.Size = UDim2.new(1, 0, 1, -4)
        plate.BackgroundColor3 = Color3.new(0, 0, 0)
        plate.BorderSizePixel = 0
        plate.Parent = bb
        local pg = Instance.new("UIGradient")
        pg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.45),
            NumberSequenceKeypoint.new(0.75, 0.45), NumberSequenceKeypoint.new(1, 1)})
        pg.Parent = plate
        local accentLine = Instance.new("Frame")
        accentLine.AnchorPoint = Vector2.new(0.5, 1)
        accentLine.Position = UDim2.new(0.5, 0, 1, 0)
        accentLine.Size = UDim2.new(0.6, 0, 0, 1)
        accentLine.BackgroundColor3 = col
        accentLine.BorderSizePixel = 0
        accentLine.Parent = plate
        local ag = Instance.new("UIGradient")
        ag.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})
        ag.Parent = accentLine
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.Size = UDim2.fromScale(1, 1)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 12
        t.TextColor3 = Color3.new(1, 1, 1)
        t.Text = string.lower(name)
        t.Parent = plate
        local tg = Instance.new("UIGradient")
        tg.Rotation = 90
        tg.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 158))
        tg.Parent = t
        local ts = Instance.new("UIStroke")
        ts.Color = Color3.new(0, 0, 0)
        ts.Transparency = 0.35
        ts.Thickness = 1
        ts.Parent = t
        local hl = Instance.new("Highlight")
        hl.Adornee = m
        hl.FillColor, hl.OutlineColor = col, col
        hl.FillTransparency, hl.OutlineTransparency = 0.4, 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = gFolder
        local tr
        local bx = {}
        pcall(function()
            tr = S.fline(1.5, col)
            for k = 1, 8 do bx[k] = S.fline(1.5, col) end
        end)
        G[m] = {bb = bb, t = t, hl = hl, tr = tr, bx = bx, col = col, name = string.lower(name), kind = name, line = accentLine}
        -- molotov / incendiary: when it bursts, the fire zone on the ground gets outlined for as long as it burns
        local lname = string.lower(name)
        if string.find(lname, "molotov", 1, true) or string.find(lname, "incend", 1, true) then
            m:GetAttributeChangedSignal("SimulationFinished"):Connect(function()
ident()
                if m:GetAttribute("SimulationFinished") and CFG.grenadeEsp and CFG.gnZone and S.molotovZone then
                    local p = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                    if p then S.molotovZone(p.Position) end
                end
            end)
        end
    end
    local function remove(m)
        local g = G[m]
        if not g then return end
        pcall(function() g.bb:Destroy() end)
        pcall(function() g.hl:Destroy() end)
        if g.tr then dropDrawing(g.tr) end
        for _, l in ipairs(g.bx or {}) do dropDrawing(l) end
        G[m] = nil
    end
    -- the zone: a flat disc on the ground plus a ring, sized to the flames it finds, with a countdown
    -- fuse: their own projectile spawn message has the start time and the fuse
    local FUSE = {}
    task.spawn(function()
ident()
        pcall(function()
            local R = require(RS:WaitForChild("Database", 10):WaitForChild("Security", 10):WaitForChild("Remotes", 10))
            R.Projectile.Spawn.Listen(function(p)
                -- remember how the game throws: start speed and gravity of a grenade thrown near your camera
                pcall(function()
                    local ph = p and p.Physics
                    if type(ph) ~= "table" then return end
                    local v, g, o
                    for k, val in pairs(ph) do
                        local lk = string.lower(tostring(k))
                        if typeof(val) == "Vector3" then
                            if string.find(lk, "vel", 1, true) then v = val
                            elseif string.find(lk, "pos", 1, true) or string.find(lk, "origin", 1, true) then o = val end
                            if string.find(lk, "grav", 1, true) then g = math.abs(val.Y) end
                        elseif tonumber(val) and string.find(lk, "grav", 1, true) then
                            g = math.abs(tonumber(val))
                        end
                    end
                    if v and v.Magnitude > 5 then
                        local near = (not o) or (o - workspace.CurrentCamera.CFrame.Position).Magnitude < 8
                        if near then S.nadeSpeed = v.Magnitude end
                    end
                    if g and g > 1 then S.nadeGrav = g end
                end)
                local ft = p and p.Physics and tonumber(p.Physics.FuseTime)
                if p and p.Id and ft and ft > 0 then
                    FUSE[tostring(p.Id)] = (p.State and tonumber(p.State.StartTime) or workspace:GetServerTimeNow()) + ft
                end
            end)
        end)
    end)
    local DEFAULT_FUSE = {["HE Grenade"] = 1.6, ["Flashbang"] = 1.6}
    S.fuseLeft = function(m, g)
        local at = FUSE[m.Name]
        if not at and DEFAULT_FUSE[g.kind] then
            g.born = g.born or workspace:GetServerTimeNow()
            at = g.born + DEFAULT_FUSE[g.kind]
        end
        if not at or m:GetAttribute("SimulationFinished") then return nil end
        local left = at - workspace:GetServerTimeNow()
        return left > 0 and left or nil
    end
    S.molotovZone = function(pos)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local ig = {workspace.CurrentCamera}
        local me = myModel()
        if me then ig[2] = me end
        rp.FilterDescendantsInstances = ig
        local hit = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), rp)
        local ground = hit and hit.Position or pos
        local anchor = Instance.new("Part")
        anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
        anchor.Transparency = 1
        anchor.Size = Vector3.new(0.2, 0.2, 0.2)
        anchor.CFrame = CFrame.new(ground + Vector3.new(0, 0.08, 0))
        anchor.Parent = workspace.CurrentCamera
        local radius = 9
        local disc = Instance.new("CylinderHandleAdornment")
        disc.Adornee = anchor
        disc.Height = 0.05
        disc.Radius = radius
        disc.CFrame = CFrame.Angles(math.rad(90), 0, 0)
        disc.Color3 = Color3.fromRGB(255, 120, 40)
        disc.Transparency = 0.7
        disc.AlwaysOnTop = true
        disc.ZIndex = 1
        disc.Parent = anchor
        local ring = Instance.new("CylinderHandleAdornment")
        ring.Adornee = anchor
        ring.Height = 0.06
        ring.Radius = radius
        ring.InnerRadius = radius - 0.35
        ring.CFrame = CFrame.Angles(math.rad(90), 0, 0)
        ring.Color3 = Color3.fromRGB(255, 160, 60)
        ring.Transparency = 0.1
        ring.AlwaysOnTop = true
        ring.ZIndex = 2
        ring.Parent = anchor
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.fromOffset(110, 22)
        bb.AlwaysOnTop = true
        bb.StudsOffset = Vector3.new(0, 1, 0)
        bb.Adornee = anchor
        bb.Parent = anchor
        bb.Size = UDim2.fromOffset(150, 26)
        local zplate = Instance.new("Frame")
        zplate.AnchorPoint = Vector2.new(0.5, 0.5)
        zplate.Position = UDim2.fromScale(0.5, 0.5)
        zplate.Size = UDim2.new(1, 0, 1, -4)
        zplate.BackgroundColor3 = Color3.new(0, 0, 0)
        zplate.BorderSizePixel = 0
        zplate.Parent = bb
        local zg = Instance.new("UIGradient")
        zg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.4),
            NumberSequenceKeypoint.new(0.75, 0.4), NumberSequenceKeypoint.new(1, 1)})
        zg.Parent = zplate
        local zline = Instance.new("Frame")
        zline.AnchorPoint = Vector2.new(0.5, 1)
        zline.Position = UDim2.new(0.5, 0, 1, 0)
        zline.Size = UDim2.new(0.6, 0, 0, 1)
        zline.BackgroundColor3 = Color3.fromRGB(255, 140, 40)
        zline.BorderSizePixel = 0
        zline.Parent = zplate
        local zlg = Instance.new("UIGradient")
        zlg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})
        zlg.Parent = zline
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Parent = zplate
        local ltg = Instance.new("UIGradient")
        ltg.Rotation = 90
        ltg.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(160, 160, 168))
        ltg.Parent = lbl
        local lst = Instance.new("UIStroke")
        lst.Color = Color3.new(0, 0, 0)
        lst.Transparency = 0.35
        lst.Parent = lbl
        task.spawn(function()
ident()
            local t0 = tick()
            local dbg = workspace:FindFirstChild("Debris")
            while running and anchor.Parent and tick() - t0 < 7.5 do
                -- fit the ring to the flames around (their fire parts sit in Debris)
                if dbg and tick() - t0 < 2 then
                    local far = 0
                    for _, d in ipairs(dbg:GetDescendants()) do
                        if d:IsA("BasePart") then
                            local n = string.lower(d.Name)
                            if string.find(n, "fire", 1, true) or string.find(n, "flame", 1, true) or string.find(n, "inferno", 1, true)
                                or string.find(n, "molotov", 1, true) or string.find(n, "burn", 1, true) then
                                local dv = (d.Position - ground) * Vector3.new(1, 0, 1)
                                if dv.Magnitude < 25 then far = math.max(far, dv.Magnitude + math.max(d.Size.X, d.Size.Z) / 2) end
                            end
                        end
                    end
                    if far > 2 then
                        radius = math.clamp(far, 3, 20)
                        disc.Radius, ring.Radius, ring.InnerRadius = radius, radius, radius - 0.35
                    end
                end
                local left = 7.5 - (tick() - t0)
                lbl.Text = string.format("Molotov  %.1fs", math.max(left, 0))
                local on = CFG.grenadeEsp and CFG.gnZone
                disc.Visible, ring.Visible, bb.Enabled = on, on, on
                task.wait(0.1)
            end
            pcall(function() anchor:Destroy() end)
        end)
    end
    for _, m in ipairs(CS:GetTagged("Grenade")) do add(m) end
    connect(CS:GetInstanceAddedSignal("Grenade"), add)
    connect(CS:GetInstanceRemovedSignal("Grenade"), remove)
    task.spawn(function()
ident()
        while running do
            local me = myModel()
            local mr = me and me.PrimaryPart
            for m, g in pairs(G) do
                if not m.Parent then
                    remove(m)
                else
                    local k = g.kind
                    local typeOn = (k == "HE Grenade" and CFG.gnHE) or (k == "Flashbang" and CFG.gnFlash) or (k == "Smoke Grenade" and CFG.gnSmoke)
                        or ((k == "Molotov" or k == "Incendiary Grenade") and CFG.gnMolotov) or (k == "Decoy Grenade" and CFG.gnDecoy)
                        or (GCOL[k] == nil)
                    local on = CFG.grenadeEsp and typeOn
                    local gc = CFG.gnOwnCol and palCol(CFG.gnCol, g.col) or g.col
                    if g.line then g.line.BackgroundColor3 = gc end
                    g.hl.FillColor, g.hl.OutlineColor = gc, gc
                    if g.tr then g.tr.Color = gc end
                    g.bb.Enabled = on and CFG.gnName
                    g.hl.Enabled = on and CFG.gnChams
                    local a0 = g.bb.Adornee
                    local sp0, vis0
                    if a0 and on and CFG.gnBox then sp0, vis0 = cam:WorldToViewportPoint(a0.Position) end
                    if vis0 then
                        local d = math.max((a0.Position - cam.CFrame.Position).Magnitude, 1)
                        local h = math.clamp(900 / d, 8, 80)
                        local x, y, x2, y2 = sp0.X - h / 2, sp0.Y - h / 2, sp0.X + h / 2, sp0.Y + h / 2
                        local cl = h * 0.3
                        local seg = {
                            {x, y, x + cl, y}, {x, y, x, y + cl}, {x2, y, x2 - cl, y}, {x2, y, x2, y + cl},
                            {x, y2, x + cl, y2}, {x, y2, x, y2 - cl}, {x2, y2, x2 - cl, y2}, {x2, y2, x2, y2 - cl},
                        }
                        for k, l in ipairs(g.bx or {}) do
                            l.From, l.To, l.Color, l.Visible = Vector2.new(seg[k][1], seg[k][2]), Vector2.new(seg[k][3], seg[k][4]), gc, true
                        end
                    else
                        for _, l in ipairs(g.bx or {}) do l.Visible = false end
                    end
                    if not g.bb.Adornee then g.bb.Adornee = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart") end
                    if on and CFG.gnName and mr and g.bb.Adornee then
                        local left = S.fuseLeft and S.fuseLeft(m, g)
                        g.t.Text = g.name .. "  " .. math.floor((g.bb.Adornee.Position - mr.Position).Magnitude) .. "m"
                            .. (left and string.format("  %.1fs", left) or "")
                    end
                    if g.tr then
                        local a = g.bb.Adornee
                        local sp, vis
                        if a and on and CFG.gnTracer then sp, vis = cam:WorldToViewportPoint(a.Position) end
                        if vis then
                            local vp = cam.ViewportSize
                            g.tr.From = Vector2.new(vp.X / 2, vp.Y)
                            g.tr.To = Vector2.new(sp.X, sp.Y)
                            g.tr.Visible = true
                        else
                            g.tr.Visible = false
                        end
                    end
                end
            end
            task.wait((CFG.gnTracer or CFG.gnBox) and 0.03 or 0.2)
        end
        for m in pairs(G) do remove(m) end
        pcall(function() gFolder:Destroy() end)
    end)
end

------------------------------------------------------------------ movement: bhop, auto strafe, air strafe
do
    local VIM = game:GetService("VirtualInputManager")
    local function key(code, down) pcall(function() VIM:SendKeyEvent(down, code, false, game) end) end
    -- the player's own binds from their InputController (Actions folder + GetActionKeybind), Space / A / D if not found
    local KEYS = {Jump = Enum.KeyCode.Space, A = Enum.KeyCode.A, D = Enum.KeyCode.D}
    local moveCfg
    task.spawn(function()
ident()
        pcall(function()
            local ic = RS:WaitForChild("Controllers", 10):WaitForChild("InputController", 10)
            local IC = require(ic)
            local actions = ic:FindFirstChild("Actions")
            for _, a in ipairs(actions and actions:GetChildren() or {}) do
                local n = string.lower(a.Name)
                local slot = (string.find(n, "jump", 1, true) and "Jump")
                    or ((string.find(n, "left", 1, true) and not string.find(n, "hand", 1, true)) and "A")
                    or ((string.find(n, "right", 1, true) and not string.find(n, "hand", 1, true)) and "D") or nil
                if slot then
                    local kb = IC.GetActionKeybind(a.Name)
                    if kb and Enum.KeyCode[kb] then KEYS[slot] = Enum.KeyCode[kb] end
                end
            end
        end)
        pcall(function()
            local mv = RS:WaitForChild("MovementV2", 10)
            local rset = mv:FindFirstChild("RuntimeSettings", true)
            if rset then moveCfg = require(rset) end
        end)
    end)
    local CAS2 = game:GetService("ContextActionService")
    local ACT = {}
    task.spawn(function()
ident()
        pcall(function()
            local ic = RS:WaitForChild("Controllers", 10):WaitForChild("InputController", 10)
            local actions = ic:FindFirstChild("Actions")
            for _, a in ipairs(actions and actions:GetChildren() or {}) do
                local n = string.lower(a.Name)
                if string.find(n, "jump", 1, true) then ACT.jump = ACT.jump or a.Name end
                if string.find(n, "left", 1, true) and not string.find(n, "hand", 1, true) then ACT.left = ACT.left or a.Name end
                if string.find(n, "right", 1, true) and not string.find(n, "hand", 1, true) then ACT.right = ACT.right or a.Name end
            end
        end)
    end)
    local lastIn
    UIS.InputBegan:Connect(function(i) lastIn = i end)
    local actState = {}
    local function act(name, on)
        if not name or actState[name] == on then return end
        actState[name] = on
        pcall(function() CAS2:CallFunction(name, on and Enum.UserInputState.Begin or Enum.UserInputState.End, lastIn) end)
    end
    S.actOff = function()
        for n, v in pairs(actState) do if v then act(n, false) end end
    end
    local function cfgNow()
        if not moveCfg then return nil end
        local ok, c = pcall(moveCfg.getMovementConfig)
        return ok and type(c) == "table" and c or nil
    end
    local ground = RaycastParams.new()
    ground.FilterType = Enum.RaycastFilterType.Exclude
    local held = {A = false, D = false}
    local function setHeld(k, v)
        if held[k] ~= v then
            held[k] = v
            local a = (k == "A") and ACT.left or ACT.right
            if a then act(a, v) else key(KEYS[k] or Enum.KeyCode[k], v) end
        end
    end
    -- their own movement state: velocity and ground contact exactly as their prediction has them
    local RK
    task.spawn(function()
ident()
        pcall(function()
            RK = require(RS:WaitForChild("MovementV2", 10):WaitForChild("RuntimeKinematics", 10))
            S.RK = RK
        end)
    end)
    local lastYaw, phase, wasAir, pressAt = nil, 0, false, 0
    RunService:BindToRenderStep("ZenithBS2Move", Enum.RenderPriority.Input.Value + 1, function(dt)
ident()
        if not running then return end
        local m = myModel()
        local root = m and m.PrimaryPart
        if not root then return end
        ground.FilterDescendantsInstances = {m, workspace.CurrentCamera}
        local vel, onGround = root.AssemblyLinearVelocity, nil
        if RK then
            local ok, v, _, _, _, g, known = pcall(RK.resolve, m, root)
            if ok and known then vel, onGround = v, g end
        end
        local down = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), ground)
        local gap = down and (root.Position.Y - down.Position.Y) or math.huge
        if onGround == nil then onGround = gap < 3.6 end
        local inAir = not onGround
        -- bhop: their sim buffers a jump pressed just before landing, so press it while falling onto the ground
        -- (PC: while Space is held, phone: while moving) and the jump comes out on the landing tick, no friction
        S.inAir = inAir
        local inputPath = not (S.csHooked and S.cmdHasJump)
        inputPath = false
        if CFG.bhop and inputPath then
            local jk = KEYS.Jump
            local wants = UIS:IsKeyDown(jk)
            if UIS.TouchEnabled and not UIS.KeyboardEnabled then
                wants = Vector2.new(vel.X, vel.Z).Magnitude > 4
            end
            local mc = cfgNow()
            local buffered = mc and (tonumber(mc.BunnyHopInputBufferTicks) or 0) > 0
            local auto = mc and mc.AutoBunnyHop == true
            -- Competitive: no buffer, the jump has to land on the first ground tick; Casual/DM: may press just before
            local landing = buffered and inAir and vel.Y < 0 and gap < 4.6
            local firstGround = onGround and wasAir
            if wants and not auto and (landing or firstGround) and tick() - pressAt > 0.12 then
                pressAt = tick()
                -- now and then a hop is a little late, like a person's
                local late = (math.random(1, 100) <= CFG.bhopMiss) and (0.02 + math.random() * 0.03) or 0
                task.delay(late, function()
ident()
                    if ACT.jump then act(ACT.jump, true) else key(jk, true) end
                    task.delay(0.05 + math.random() * 0.04, function()
ident()
                        if ACT.jump then act(ACT.jump, false) else key(jk, false) end
                    end)
                end)
            end
        end
        local c = workspace.CurrentCamera
        local _, yaw = c.CFrame:ToOrientation()
        local turn = lastYaw and (yaw - lastYaw) or 0
        if turn > math.pi then turn = turn - 2 * math.pi elseif turn < -math.pi then turn = turn + 2 * math.pi end
        lastYaw = yaw
        if inAir and CFG.airStrafe and not CFG.moveRage then
            -- turns the view a little side to side and strafes with it, speed builds up on its own
            phase = phase + dt * (CFG.asSpeed / 20) * (0.85 + math.random() * 0.3)
            local dir = math.sin(phase) >= 0 and 1 or -1
            S.airDir = dir
            if mousemoverel and UIS.MouseEnabled and not UIS.TouchEnabled then
                -- their camera keeps its own yaw, so on PC turn it the way a mouse would
                pcall(mousemoverel, dir * CFG.asSpeed * 10 * dt, 0)
            else
                setView(c.CFrame * CFrame.Angles(0, math.rad(-dir * CFG.asSpeed * dt), 0))
            end
            if inputPath then
                setHeld("A", dir < 0)
                setHeld("D", dir > 0)
            end
        elseif inAir and CFG.autoStrafe and inputPath and math.abs(turn) > 0.0005 * CFG.strafeSens then
            -- strafes the way you turn
            setHeld("A", turn > 0)
            setHeld("D", turn < 0)
        else
            setHeld("A", false)
            setHeld("D", false)
        end
        wasAir = inAir
    end)
    S.moveOff = function()
        setHeld("A", false)
        setHeld("D", false)
        if S.actOff then S.actOff() end
        pcall(function() RunService:UnbindFromRenderStep("ZenithBS2Move") end)
    end
end

------------------------------------------------------------------ world
do
    local tp = {base = nil}
    local tpRay = RaycastParams.new()
    tpRay.FilterType = Enum.RaycastFilterType.Exclude
    local function setViewmodel(hidden)
        for _, ch in ipairs(viewModels()) do
            if ch:IsA("Model") then
                for _, d in ipairs(ch:GetDescendants()) do
                    if d:IsA("BasePart") then d.LocalTransparencyModifier = hidden and 1 or 0 end
                end
            end
        end
    end
    local KNIFE = {["T Knife"] = true, ["CT Knife"] = true, ["Karambit"] = true, ["M9 Bayonet"] = true, ["Butterfly Knife"] = true,
        ["Flip Knife"] = true, ["Gut Knife"] = true, ["Stiletto Knife"] = true, ["Skeleton Knife"] = true}
    tp.body = {}
    local function giveBack()
        setViewmodel(false)
        for p, v in pairs(tp.body) do
            if p.Parent then pcall(function() p.LocalTransparencyModifier = v end) end
        end
        tp.body = {}
    end
    RunService:BindToRenderStep("ZenithBS2TP", Enum.RenderPriority.Last.Value + 10, function()
ident()
        local c = workspace.CurrentCamera
        if not running then return end
        if CFG.fovOn then c.FieldOfView = CFG.camFov end
        local knife = false
        for _, vm in ipairs(viewModels()) do
            if KNIFE[vm.Name] then knife = true break end
        end
        if not CFG.third or (knife and CFG.tpKnife) then
            if tp.on then
                tp.on = false
                giveBack()
            end
            return
        end
        tp.on = true
        local base = c.CFrame
        local mm = myModel()
        local ig = {c}
        if mm then ig[2] = mm end
        tpRay.FilterDescendantsInstances = ig
        local back = -base.LookVector * CFG.thirdDist + base.UpVector * 1.5
        local hit = workspace:Raycast(base.Position, back, tpRay)
        local off = hit and (hit.Position - base.Position) * 0.9 or back
        tp.base = base
        c.CFrame = base + off
        setViewmodel(true)
        if mm then
            if tp.listOf ~= mm or tick() - (tp.listAt or 0) > 1 then
                tp.listOf, tp.listAt, tp.list = mm, tick(), {}
                for _, d in ipairs(mm:GetDescendants()) do
                    if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Name ~= "CollisionCapsule" then tp.list[#tp.list + 1] = d end
                end
            end
            for _, d in ipairs(tp.list) do
                if tp.body[d] == nil then tp.body[d] = d.LocalTransparencyModifier end
                if d.LocalTransparencyModifier ~= 0 then d.LocalTransparencyModifier = 0 end
            end
        end
    end)
    connect(RunService.PreSimulation, function()
ident()
        if tp.base then
            workspace.CurrentCamera.CFrame = tp.base
            tp.base = nil
        end
    end)
    local Lighting = game:GetService("Lighting")
    local lsave = {}
    task.spawn(function()
ident()
        while running do
            pcall(function()
                if CFG.fullbright then
                    for k, v in pairs({Brightness = 2, ClockTime = 14, GlobalShadows = false, FogEnd = 1e6}) do
                        if lsave[k] == nil then lsave[k] = Lighting[k] end
                        Lighting[k] = v
                    end
                    if lsave.Ambient == nil then lsave.Ambient = Lighting.Ambient end
                    Lighting.Ambient = Color3.fromRGB(180, 180, 180)
                elseif next(lsave) then
                    for k, v in pairs(lsave) do pcall(function() Lighting[k] = v end) end
                    lsave = {}
                end
            end)
            task.wait(0.5)
        end
        for k, v in pairs(lsave) do pcall(function() Lighting[k] = v end) end
    end)
end

------------------------------------------------------------------ ESP
local ACC = {
    Mint = Color3.fromRGB(80, 230, 170), Blue = Color3.fromRGB(90, 150, 255), Rose = Color3.fromRGB(255, 95, 130),
    Amber = Color3.fromRGB(255, 180, 60), White = Color3.fromRGB(240, 240, 245),
}
local ENEMY = Color3.fromRGB(255, 80, 80)
local TEAMC = Color3.fromRGB(90, 150, 255)

local draws = {}
local function draw(class, props)
    local ok, d = pcall(Drawing.new, class)
    if not ok or not d then return nil end
    for k, v in pairs(props or {}) do pcall(function() d[k] = v end) end
    draws[#draws + 1] = d
    return d
end

local holder = Instance.new("Folder")
holder.Name = "ZenithBS2"
holder.Parent = workspace.CurrentCamera
task.spawn(function()
ident()
    while running do
        if holder.Parent ~= workspace.CurrentCamera then pcall(function() holder.Parent = workspace.CurrentCamera end) end
        task.wait(1)
    end
end)

local PARTS = {"boxOut", "box", "name", "dist", "hpBack", "hp", "tracer", "c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8",
    "s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "s12", "s13", "s14"}
local BONES = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local BONES6 = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}
-- a black plate that fades at the sides, white-to-grey text on it
local function plate(parent, size)
    local f = Instance.new("Frame")
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Position = UDim2.fromScale(0.5, 0.5)
    f.Size = UDim2.fromScale(1, 1)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Parent = parent
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.fromScale(1, 1)
    t.Font = Enum.Font.GothamBold
    t.TextSize = math.max(size + 1, 11)
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Parent = f
    -- white at the top fading to dark at the bottom, with a black outline
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromRGB(175, 175, 182))})
    g.Parent = t
    -- a black copy one pixel lower right, under the text: makes it heavy and readable on any background
    local sh = Instance.new("TextLabel")
    sh.BackgroundTransparency = 1
    sh.Size = UDim2.fromScale(1, 1)
    sh.Position = UDim2.fromOffset(1, 1)
    sh.Font = t.Font
    sh.TextSize = t.TextSize
    sh.TextColor3 = Color3.new(0, 0, 0)
    sh.TextTransparency = 0.7
    sh.ZIndex = 0
    sh.Parent = f
    t.ZIndex = 2
    t:GetPropertyChangedSignal("Text"):Connect(function() sh.Text = t.Text end)
    local st = Instance.new("UIStroke")
    st.Color = Color3.new(0, 0, 0)
    st.Thickness = 1
    st.Transparency = 0.25
    st.Parent = t
    return f, t, g
end
local KNOWN_WEAPONS = {}
for w in pairs(WGROUP) do KNOWN_WEAPONS[w] = true end
for _, w in ipairs({"HE Grenade", "Flashbang", "Smoke Grenade", "Molotov", "Incendiary Grenade", "Decoy Grenade", "C4", "CT Knife", "T Knife",
    "Karambit", "Butterfly Knife", "M9 Bayonet", "Flip Knife", "Gut Knife", "Skeleton Knife", "Stiletto Knife"}) do KNOWN_WEAPONS[w] = true end
do
    local cache = {}
    local function findImg(t, depth)
        if type(t) ~= "table" or depth > 2 then return nil end
        for k, v in pairs(t) do
            local lk = string.lower(tostring(k))
            if type(v) == "string" and (string.find(v, "rbxassetid", 1, true) or string.find(v, "rbxthumb", 1, true) or tonumber(v))
                and (string.find(lk, "icon", 1, true) or string.find(lk, "image", 1, true) or string.find(lk, "thumb", 1, true)
                    or string.find(lk, "render", 1, true) or string.find(lk, "preview", 1, true)) then
                return tonumber(v) and ("rbxassetid://" .. v) or v
            end
        end
        for _, v in pairs(t) do
            local r = findImg(v, depth + 1)
            if r then return r end
        end
        return nil
    end
    S.weaponIcon = function(name)
        if cache[name] ~= nil then return cache[name] or nil end
        cache[name] = false
        -- Assets.Weapons/<weapon>: the first picture found inside (image, decal, texture, an Icon value or attribute)
        pcall(function()
            local w = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Weapons")
            local folder = w and w:FindFirstChild(name)
            if not folder then return end
            local function pic(v)
                if type(v) == "number" then return "rbxassetid://" .. v end
                if type(v) == "string" and v ~= "" then return tonumber(v) and ("rbxassetid://" .. v) or v end
            end
            for _, k in ipairs({"Icon", "Image", "Thumbnail"}) do
                local a = pic(folder:GetAttribute(k))
                if a then cache[name] = a return end
            end
            for _, d in ipairs(folder:GetDescendants()) do
                local img
                if d:IsA("ImageLabel") or d:IsA("ImageButton") then img = d.Image
                elseif d:IsA("Decal") or d:IsA("Texture") then img = d.Texture
                elseif (d:IsA("StringValue") or d:IsA("IntValue") or d:IsA("NumberValue")) and string.find(string.lower(d.Name), "icon", 1, true) then img = pic(d.Value) end
                if type(img) == "string" and img ~= "" then cache[name] = img return end
            end
        end)
        if cache[name] then return cache[name] end
        local function deep(t, depth, seen)
            if type(t) ~= "table" or depth > 4 or seen[t] then return nil end
            seen[t] = true
            for k, v in pairs(t) do
                local lk = string.lower(tostring(k))
                if (string.find(lk, "icon", 1, true) or string.find(lk, "image", 1, true) or string.find(lk, "thumb", 1, true)) then
                    if type(v) == "number" then return "rbxassetid://" .. v end
                    if type(v) == "string" and (string.find(v, "rbxasset", 1, true) or string.find(v, "rbxthumb", 1, true) or tonumber(v)) then
                        return tonumber(v) and ("rbxassetid://" .. v) or v
                    end
                end
            end
            for _, v in pairs(t) do
                local r = deep(v, depth + 1, seen)
                if r then return r end
            end
            return nil
        end
        for _, path in ipairs({{"Database", "Audio", "Weapons"}, {"Database", "Custom", "Weapons"}, {"Database", "Weapons"}}) do
            pcall(function()
                local f = RS
                for _, p in ipairs(path) do f = f and f:FindFirstChild(p) end
                local mod = f and (f:FindFirstChild(name) or f:FindFirstChild(name:gsub(" ", "")))
                if mod and mod:IsA("ModuleScript") then
                    local img = deep(require(mod), 0, {})
                    if img then cache[name] = img end
                elseif mod then
                    for _, d in ipairs(mod:GetDescendants()) do
                        if d:IsA("ModuleScript") then
                            local img = deep(require(d), 0, {})
                            if img then cache[name] = img break end
                        end
                    end
                end
            end)
            if cache[name] then return cache[name] end
        end
        pcall(function()
            local mod = RS.Database.Custom.Weapons:FindFirstChild(name)
            local t = mod and require(mod)
            local img
            if type(t) == "table" then
                for _, k in ipairs({"Icon", "Image", "Thumbnail", "IconImage", "InventoryIcon"}) do
                    local v = rawget(t, k)
                    if type(v) == "string" and v ~= "" then img = tonumber(v) and ("rbxassetid://" .. v) or v break end
                    if type(v) == "number" then img = "rbxassetid://" .. v break end
                end
            end
            if img then cache[name] = img end
        end)
        return cache[name] or nil
    end
end
-- flags: money, ping, bomb carrier (attributes the game keeps, or what the character carries)
local valCache = setmetatable({}, {__mode = "k"})
-- the first number whose name contains one of the words, on the player / character attributes or any value object under the player
local function findNum(p, m, words)
    local key = table.concat(words, ",")
    local c = valCache[m]
    if c and c[key] and tick() - c[key][1] < 1 then return c[key][2] end
    local found
    local function match(n)
        n = string.lower(n)
        for _, w in ipairs(words) do if string.find(n, w, 1, true) then return true end end
        return false
    end
    for _, obj in ipairs({p, m}) do
        if found then break end
        if obj and typeof(obj) == "Instance" then
            for k, v in pairs(obj:GetAttributes()) do
                if tonumber(v) and match(k) then found = tonumber(v) break end
            end
        end
    end
    if not found and p and typeof(p) == "Instance" then
        for _, d in ipairs(p:GetDescendants()) do
            if (d:IsA("IntValue") or d:IsA("NumberValue")) and match(d.Name) then found = d.Value break end
        end
    end
    valCache[m] = valCache[m] or {}
    valCache[m][key] = {tick(), found}
    return found
end
local function attrNum(p, m, names)
    local lower = {}
    for i, n in ipairs(names) do lower[i] = string.lower(n) end
    local direct = findNum(p, m, lower)
    if direct then return direct end
    for _, n in ipairs(names) do
        local v = (p and typeof(p) == "Instance" and p:GetAttribute(n)) or m:GetAttribute(n)
        if tonumber(v) then return tonumber(v) end
    end
    local ls = p and typeof(p) == "Instance" and p:FindFirstChild("leaderstats")
    for _, n in ipairs(names) do
        local x = ls and ls:FindFirstChild(n)
        if x and tonumber(x.Value) then return tonumber(x.Value) end
    end
    return nil
end
local bombCache = setmetatable({}, {__mode = "k"})
local function hasBomb(p, m)
    local c = bombCache[m]
    if c and tick() - c[1] < 0.5 then return c[2] end
    local yes = false
    for _, obj in ipairs({p, m}) do
        if not yes and obj and typeof(obj) == "Instance" then
            for _, k in ipairs({"HasBomb", "HasC4", "BombCarrier", "CarryingBomb", "IsBombCarrier"}) do
                if obj:GetAttribute(k) == true then yes = true break end
            end
        end
    end
    if not yes then
        local c4 = m:FindFirstChild("C4", true)
        if c4 and (c4:IsA("Model") or c4:IsA("Tool") or c4:IsA("BasePart")) then yes = true end
    end
    bombCache[m] = {tick(), yes}
    return yes
end
local wCache = setmetatable({}, {__mode = "k"})
local KNOWN_LOWER = {}
for w in pairs(KNOWN_WEAPONS) do KNOWN_LOWER[string.lower((w:gsub("[%s%-]", "")))] = w end
local function known(n)
    if type(n) ~= "string" then return nil end
    return KNOWN_WEAPONS[n] and n or KNOWN_LOWER[string.lower((n:gsub("[%s%-]", "")))]
end
local function weaponOf(m, plr)
    local c = wCache[m]
    if c and tick() - c[1] < 0.5 then return c[2] end
    local found
    for _, obj in ipairs({m, plr}) do
        if not found and obj and typeof(obj) == "Instance" then
            for _, v in pairs(obj:GetAttributes()) do
                local k2 = known(v)
                if k2 then found = k2 break end
            end
        end
    end
    if not found then
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("Model") or d:IsA("Tool") or d:IsA("Folder") then
                local k2 = known(d.Name)
                if k2 then found = k2 break end
            end
        end
    end
    if not found then
        -- a weapon model held by this character: a known weapon name with visible parts, directly in the character
        for _, ch in ipairs(m:GetChildren()) do
            if KNOWN_WEAPONS[ch.Name] and (ch:IsA("Model") or ch:IsA("Tool")) and ch:FindFirstChildWhichIsA("BasePart", true) then
                found = ch.Name
                break
            end
        end
    end
    wCache[m] = {tick(), found}
    return found
end
local E = {}
local espGui = Instance.new("ScreenGui")
espGui.Name = "ZenithBS2Esp"
espGui.IgnoreGuiInset = true
espGui.ResetOnSpawn = false
espGui.DisplayOrder = 5
pcall(function() espGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not espGui.Parent then espGui.Parent = lp:WaitForChild("PlayerGui") end
S.espGui = espGui
local function gline(parent, thick)
    if DRAW_OK then
        local l = draw("Line", {Thickness = thick, Visible = false, Transparency = 1, Color = Color3.new(1, 1, 1)})
        if l then return l end
    end
    local f = Instance.new("Frame")
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.BorderSizePixel = 0
    f.Size = UDim2.fromOffset(0, thick)
    f.Visible = false
    f.Parent = parent
    return f
end
local function setLine(f, a, b, col)
    if typeof(f) ~= "Instance" then
        pcall(function()
            f.From, f.To, f.Color = a, b, col
            f.Visible = true
        end)
        return
    end
    local d = b - a
    f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
    f.Size = UDim2.fromOffset(d.Magnitude + 1, f.Size.Y.Offset)
    f.Rotation = math.deg(math.atan2(d.Y, d.X))
    f.BackgroundColor3 = col
    f.Visible = true
end
local function buildESP(m)
    local e = {}
    local root = Instance.new("Frame")
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromScale(1, 1)
    root.Visible = false
    root.Parent = espGui
    e.root = root
    e.fill = Instance.new("Frame")
    e.fill.BorderSizePixel = 0
    e.fill.Visible = false
    e.fill.Parent = root
    e.c, e.co, e.s = {}, {}, {}
    for k = 1, 8 do
        e.co[k] = gline(root, 5)
        pcall(function()
            if typeof(e.co[k]) == "Instance" then
                e.co[k].BackgroundColor3 = Color3.new(0, 0, 0)
                e.co[k].BackgroundTransparency = 0.5
            else
                e.co[k].Transparency = 0.5
            end
        end)
        e.c[k] = gline(root, 2.6)
    end
    for k = 1, 14 do e.s[k] = gline(root, 2.2) end
    e.tr = gline(root, 1.5)
    e.hpb = gline(root, 6)
    e.hpf = gline(root, 4)
    if DRAW_OK then
        e.dName = draw("Text", {Size = 13, Center = true, Outline = true, Visible = false, Color = Color3.new(1, 1, 1), Font = 2})
        e.dUnder = draw("Text", {Size = 14, Center = true, Outline = true, Visible = false, Color = Color3.new(1, 1, 1), Font = 1})
        e.dFlags = {}
        for k = 1, 5 do e.dFlags[k] = draw("Text", {Size = 13, Center = false, Outline = true, Visible = false, Color = Color3.new(1, 1, 1), Font = 1}) end
    end
    -- bomb carrier picture
    e.bombB = Instance.new("BillboardGui")
    e.bombB.Size = UDim2.fromOffset(20, 20)
    e.bombB.AlwaysOnTop = true
    e.bombB.StudsOffsetWorldSpace = Vector3.new(2.4, 2.2, 0)
    e.bombB.Enabled = false
    e.bombB.Parent = holder
    e.bombI = Instance.new("ImageLabel")
    e.bombI.BackgroundTransparency = 1
    e.bombI.Size = UDim2.fromScale(1, 1)
    e.bombI.ScaleType = Enum.ScaleType.Fit
    e.bombI.Parent = e.bombB
    e.lines = {}
    for k = 1, 8 do e.lines[#e.lines + 1] = e.co[k]; e.lines[#e.lines + 1] = e.c[k] end
    for k = 1, 14 do e.lines[#e.lines + 1] = e.s[k] end
    e.lines[#e.lines + 1] = e.tr
    if e.dName then e.lines[#e.lines + 1] = e.dName end
    if e.dUnder then e.lines[#e.lines + 1] = e.dUnder end
    for _, t in ipairs(e.dFlags or {}) do e.lines[#e.lines + 1] = t end
    e.lines[#e.lines + 1] = e.hpb
    e.lines[#e.lines + 1] = e.hpf
    local hl = Instance.new("Highlight")
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.1
    hl.Enabled = false
    hl.Parent = holder
    e.hl = hl
    local top = Instance.new("BillboardGui")
    top.Size = UDim2.fromOffset(150, 22)
    top.AlwaysOnTop = true
    top.StudsOffsetWorldSpace = Vector3.new(0, 1.4, 0)
    top.Enabled = false
    top.Parent = holder
    e.nb = top
    e.nt = select(2, plate(top, CFG.nameSize or 11))
    top.Size = UDim2.fromOffset(130, 18)
    pcall(function()
        local pl = e.nt.Parent
        pl.Size = UDim2.new(1, -20, 1, 0)
        pl.Position = UDim2.new(0.5, 10, 0.5, 0)
    end)
    e.av = Instance.new("ImageLabel")
    e.av.BackgroundColor3 = Color3.new(0, 0, 0)
    e.av.BackgroundTransparency = 0.4
    e.av.Size = UDim2.fromOffset(16, 16)
    e.av.Position = UDim2.fromOffset(1, 1)
    e.av.Visible = false
    e.av.Parent = top
    do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = e.av
        local st = Instance.new("UIStroke")
        st.Color = Color3.new(1, 1, 1)
        st.Transparency = 0.5
        st.Parent = e.av
    end
    local bot = Instance.new("BillboardGui")
    bot.Size = UDim2.fromOffset(150, 20)
    bot.AlwaysOnTop = true
    bot.StudsOffsetWorldSpace = Vector3.new(0, -3.2, 0)
    bot.Enabled = false
    bot.Parent = holder
    e.wb = bot
    e.wt = select(2, plate(bot, 9))
    bot.Size = UDim2.fromOffset(130, 16)
    e.wi = Instance.new("ImageLabel")
    e.wi.BackgroundTransparency = 1
    e.wi.ScaleType = Enum.ScaleType.Fit
    e.wi.Size = UDim2.fromOffset(30, 14)
    e.wi.Position = UDim2.fromOffset(0, 1)
    e.wi.Visible = false
    e.wi.Parent = bot
    return e
end
-- pool: created right now at load; the per-frame code only borrows and returns entries
local POOL = {}
for _ = 1, 48 do
    local ok, e = pcall(buildESP)
    if ok and e then POOL[#POOL + 1] = e end
end
local function newESP(m)
    local e = table.remove(POOL)
    if not e then return nil end
    E[m] = e
    return e
end
local function hideLines(e)
    for _, l in ipairs(e.lines or {}) do pcall(function() l.Visible = false end) end
end
local function unpaintESP(e)
    for part, st in pairs(e.mat or {}) do if part.Parent then pcall(function() part.Material, part.Color = st[1], st[2] end) end end
    e.mat = {}
    e.paintSig = nil
end
local function hideESP(e)
    e.root.Visible = false
    hideLines(e)
    unpaintESP(e)
    e.hl.Enabled = false
    e.hlSig = nil
    if e.fill then e.fill.Visible = false end
    if e.bombB then e.bombB.Enabled = false end
    e.nb.Enabled = false
    e.wb.Enabled = false
end
local function removeESP(m)
    local e = E[m]
    if not e then return end
    if not S.unloading then
        hideESP(e)
        pcall(function() e.hl.Adornee = nil; e.nb.Adornee = nil; e.wb.Adornee = nil end)
        E[m] = nil
        POOL[#POOL + 1] = e
        return
    end
    for _, l in ipairs(e.lines or {}) do
        if typeof(l) ~= "Instance" then dropDrawing(l) end
    end
    pcall(function() e.root:Destroy() end)
    pcall(function() e.hl:Destroy() end)
    pcall(function() e.nb:Destroy() end)
    pcall(function() e.wb:Destroy() end)
    E[m] = nil
end

local UP, DOWN = Vector3.new(0, 2.8, 0), Vector3.new(0, 3.2, 0)
local function stepESP(m, enemy, e, plr)
    local r, hp, maxHp = alive(m)
    if not CFG.esp or not r or (not enemy and not CFG.espTeam) then
        hideESP(e)
        return
    end
    local dist = (cam.CFrame.Position - r.Position).Magnitude
    if dist > CFG.maxDist then
        hideESP(e)
        return
    end
    local color = enemy and palCol(CFG.espCol, ENEMY) or palCol(CFG.teamCol, TEAMC)
    if CFG.boxColMode == "Health" then
        local fr = math.clamp(hp / math.max(maxHp or 100, 1), 0, 1)
        color = (fr > 0.6) and Color3.fromRGB(90, 235, 110) or (fr > 0.3) and Color3.fromRGB(255, 160, 50) or Color3.fromRGB(255, 60, 60)
    elseif CFG.boxColMode == "White" then
        color = Color3.new(1, 1, 1)
    end
    local color2 = CFG.espGrad and palCol(CFG.espCol2, color) or color
    -- chams
    e.mat = e.mat or {}
    local cc = palCol(CFG.chamsCol, color)
    if not enemy then cc = color end
    local depth = CFG.chamsWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    if CFG.chams and (CFG.chamsStyle == "Neon" or CFG.chamsStyle == "ForceField") then
        local mat = (CFG.chamsStyle == "Neon") and Enum.Material.Neon or Enum.Material.ForceField
        local paintCol = (CFG.chamsStyle == "Neon") and Color3.new(1, 1, 1) or cc
        local sig = CFG.chamsStyle .. CFG.chamsCol
        if e.paintSig ~= sig or tick() - (e.paintAt or 0) > 1 then
            e.paintSig, e.paintAt = sig, tick()
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("BasePart") and d.Transparency < 1 and d.Name ~= "HumanoidRootPart" and d.Name ~= "CollisionCapsule" then
                    if not e.mat[d] then e.mat[d] = {d.Material, d.Color} end
                    d.Material, d.Color = mat, paintCol
                end
            end
        end
        e.hl.Adornee = m
        e.hl.FillTransparency, e.hl.OutlineTransparency, e.hl.OutlineColor, e.hl.DepthMode = 1, 0.1, cc, depth
        e.hl.Enabled = CFG.chamsWalls
    else
        if next(e.mat) then
            for part, st in pairs(e.mat) do if part.Parent then pcall(function() part.Material, part.Color = st[1], st[2] end) end end
            e.mat = {}
            e.paintSig = nil
        end
        local hsig = tostring(m) .. CFG.chamsStyle .. tostring(cc) .. tostring(CFG.chamsFill) .. tostring(CFG.chamsWalls)
        if e.hlSig ~= hsig then
            e.hlSig = hsig
            e.hl.Adornee = m
            e.hl.FillColor, e.hl.OutlineColor, e.hl.DepthMode = cc, cc, depth
            if CFG.chamsStyle == "Outline" then
                e.hl.FillTransparency, e.hl.OutlineTransparency = 1, 0
            else
                e.hl.FillTransparency, e.hl.OutlineTransparency = CFG.chamsFill, 0.1
            end
        end
        if e.hl.Enabled ~= CFG.chams then e.hl.Enabled = CFG.chams end
    end
    e.lastPos, e.lastName, e.lastEnemy = r.Position, pname(plr, m), enemy
    local head = m:FindFirstChild("Head") or r
    e.nb.Adornee = head
    e.nb.Enabled = CFG.name
    if CFG.name then e.nt.Text = pname(plr, m) end
    -- avatar next to the name (players only, bots have none)
    local uid = 0
    pcall(function() uid = tonumber(plr and plr.UserId) or 0 end)
    if CFG.espAvatar and CFG.name and uid > 0 then
        local img = "rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=48&h=48"
        if e.av.Image ~= img then e.av.Image = img end
        e.av.Visible = true
    else
        e.av.Visible = false
    end
    local w = (CFG.wShow ~= false) and (CFG.wInfo or CFG.wIcon) and weaponOf(m, plr) or nil
    local icon = w and CFG.wIcon and S.weaponIcon and S.weaponIcon(w) or nil
    if icon then
        if e.wi.Image ~= icon then e.wi.Image = icon end
        e.wi.Visible = true
    else
        e.wi.Visible = false
    end
    local under = {}
    if w and CFG.wInfo then under[#under + 1] = string.lower(w) end
    if CFG.dist and not (CFG.flags and CFG.fDist) then under[#under + 1] = math.floor(dist) .. "m" end
    e.wb.Adornee = r
    if DRAW_OK and e.dName then
        -- texts are drawn below with the box; the billboards keep only the pictures
        e.nt.Text = CFG.name and pname(plr, m) or ""
        e.wt.Text = e.under0 or ""
        e.under0 = table.concat(under, "  ")
        e.wt.Text = e.under0
        e.wb.Enabled = icon ~= nil or e.under0 ~= ""
    else
        e.wb.Enabled = #under > 0
        if #under > 0 then e.wt.Text = table.concat(under, "   ") end
    end
    local bomb = CFG.flags and CFG.fBomb and hasBomb(plr, m)
    e.bombB.Adornee = head
    e.bombB.Enabled = bomb and true or false
    if bomb then
        local bi = S.weaponIcon and S.weaponIcon("C4")
        if bi and e.bombI.Image ~= bi then e.bombI.Image = bi end
    end
    local hd = m:FindFirstChild("Head")
    local topW = hd and (hd.Position + Vector3.new(0, hd.Size.Y * 0.6, 0)) or (r.Position + UP)
    local lowY
    for _, n in ipairs({"LeftFoot", "RightFoot", "Left Leg", "Right Leg", "LeftLowerLeg", "RightLowerLeg"}) do
        local p = m:FindFirstChild(n)
        if p and p:IsA("BasePart") then
            local y = p.Position.Y - p.Size.Y / 2
            if not lowY or y < lowY then lowY = y end
        end
    end
    local botW = Vector3.new(r.Position.X, lowY or (r.Position.Y - DOWN.Y), r.Position.Z)
    local top, v1 = cam:WorldToViewportPoint(topW)
    local bot, v2 = cam:WorldToViewportPoint(botW)
    if not (v1 or v2) or top.Z <= 0 then
        e.root.Visible = false
        hideLines(e)
        return
    end
    e.root.Visible = true
    local hgt = math.abs(bot.Y - top.Y)
    local wid = hgt * 0.42
    local mid = cam:WorldToViewportPoint(r.Position)
    local x = mid.X - wid / 2
    local x2, y1, y2 = x + wid, math.min(top.Y, bot.Y), math.min(top.Y, bot.Y) + hgt
    local cA, cB = color, color2
    if CFG.espGrad and CFG.espGradAnim then
        local t = (math.sin(tick() * 2) + 1) / 2
        cA, cB = color:Lerp(color2, t), color2:Lerp(color, t)
    end
    local cMid = cA:Lerp(cB, 0.5)
    if CFG.box and CFG.boxFill then
        pcall(function()
            e.fill.Position = UDim2.fromOffset(x, y1)
            e.fill.Size = UDim2.fromOffset(x2 - x, y2 - y1)
            e.fill.BackgroundColor3 = color
            e.fill.BackgroundTransparency = CFG.boxFillTr
            e.fill.Visible = true
        end)
    else
        pcall(function() e.fill.Visible = false end)
    end
    local seg, cols
    if CFG.boxStyle == "Full" then
        seg = {{Vector2.new(x, y1), Vector2.new(x2, y1)}, {Vector2.new(x2, y1), Vector2.new(x2, y2)},
            {Vector2.new(x2, y2), Vector2.new(x, y2)}, {Vector2.new(x, y2), Vector2.new(x, y1)}}
        cols = {cA, cMid, cB, cMid}
    else
        local cl = math.max(wid * 0.25, 4)
        seg = {
            {Vector2.new(x, y1), Vector2.new(x + cl, y1)}, {Vector2.new(x, y1), Vector2.new(x, y1 + cl)},
            {Vector2.new(x2, y1), Vector2.new(x2 - cl, y1)}, {Vector2.new(x2, y1), Vector2.new(x2, y1 + cl)},
            {Vector2.new(x, y2), Vector2.new(x + cl, y2)}, {Vector2.new(x, y2), Vector2.new(x, y2 - cl)},
            {Vector2.new(x2, y2), Vector2.new(x2 - cl, y2)}, {Vector2.new(x2, y2), Vector2.new(x2, y2 - cl)},
        }
        cols = {cA, cA, cA, cA, cB, cB, cB, cB}
    end
    for k = 1, 8 do
        local sg = seg[k]
        if CFG.box and sg then
            setLine(e.co[k], sg[1], sg[2], Color3.new(0, 0, 0))
            setLine(e.c[k], sg[1], sg[2], cols[k])
        else
            pcall(function() e.co[k].Visible, e.c[k].Visible = false, false end)
        end
    end
    local pairs0 = m:FindFirstChild("UpperTorso") and BONES or BONES6
    for k = 1, 14 do
        local b = pairs0[k]
        local okDraw = false
        if CFG.skeleton and b then
            local p1, p2 = m:FindFirstChild(b[1]), m:FindFirstChild(b[2])
            if p1 and p2 and p1:IsA("BasePart") and p2:IsA("BasePart") then
                local a1, s1 = cam:WorldToViewportPoint(p1.Position)
                local a2, s2 = cam:WorldToViewportPoint(p2.Position)
                if s1 and s2 then
                    setLine(e.s[k], Vector2.new(a1.X, a1.Y), Vector2.new(a2.X, a2.Y), cA)
                    okDraw = true
                end
            end
        end
        if not okDraw then pcall(function() e.s[k].Visible = false end) end
    end
    if DRAW_OK and e.dName then
        local cx = (x + x2) / 2
        pcall(function() e.dName.Visible = false end)
        if false then
            pcall(function() e.dUnder.Text, e.dUnder.Position, e.dUnder.Visible = e.under0, Vector2.new(cx, y2 + 3), true end)
        else
            pcall(function() e.dUnder.Visible = false end)
        end
        local fl = {}
        if CFG.flags then
            if CFG.fMoney then
                local mo = attrNum(plr, m, {"Money", "Cash", "Balance", "Credits"})
                if mo then fl[#fl + 1] = {"$" .. math.floor(mo), Color3.fromRGB(120, 230, 120)} end
            end
            if CFG.fHealth then
                local fr = math.clamp(hp / math.max(maxHp or 100, 1), 0, 1)
                local hc = (fr > 0.6) and Color3.fromRGB(90, 235, 110) or (fr > 0.3) and Color3.fromRGB(255, 160, 50) or Color3.fromRGB(255, 60, 60)
                fl[#fl + 1] = {math.floor(hp + 0.5) .. "hp", hc}
            end
            if CFG.fPing then
                local pg = attrNum(plr, m, {"Ping", "Latency"})
                if pg then fl[#fl + 1] = {math.floor(pg) .. "ms", Color3.fromRGB(190, 190, 200)} end
            end
            if CFG.fDist then fl[#fl + 1] = {math.floor(dist) .. "m", Color3.fromRGB(190, 190, 200)} end
            if CFG.fBomb and hasBomb(plr, m) then fl[#fl + 1] = {"C4", Color3.fromRGB(255, 80, 80)} end
        end
        for k = 1, 5 do
            local f = fl[k]
            local t = e.dFlags[k]
            if f then
                pcall(function() t.Text, t.Color, t.Position, t.Visible = f[1], f[2], Vector2.new(x2 + 5, y1 - 2 + (k - 1) * 14), true end)
            else
                pcall(function() t.Visible = false end)
            end
        end
    end
    if CFG.health then
        local frac = math.clamp(hp / math.max(maxHp or 100, 1), 0, 1)
        setLine(e.hpb, Vector2.new(x - 7, y1 - 1), Vector2.new(x - 7, y2 + 1), Color3.new(0, 0, 0))
        setLine(e.hpf, Vector2.new(x - 7, y1 + hgt * (1 - frac)), Vector2.new(x - 7, y2), Color3.fromRGB(255, 70, 70):Lerp(Color3.fromRGB(90, 230, 120), frac))
    else
        pcall(function() e.hpb.Visible, e.hpf.Visible = false, false end)
    end
    if false then
        local vp = cam.ViewportSize
        setLine(e.tr, Vector2.new(vp.X / 2, vp.Y), Vector2.new(top.X, y2), cB)
    else
        pcall(function() e.tr.Visible = false end)
    end
end

-- light pass: names + chams straight from the game's alive list, 5 times a second, independent of the box drawing
task.spawn(function()
ident()
    while running do
        pcall(function()
            for _, it in ipairs(S.models or {}) do
                local m, enemy, plr = it[1], it[2], it[3]
                local e = E[m]
                if e and CFG.esp and (enemy or not CFG.teamCheck) then
                    if CFG.name and e.nb and not e.nb.Enabled then
                        e.nb.Adornee = m:FindFirstChild("Head") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
                        e.nt.Text = pname(plr, m)
                        e.nb.Enabled = true
                    end
                    if CFG.chams and (CFG.chamsStyle == "Glow" or CFG.chamsStyle == "Outline") and e.hl and not e.hl.Enabled then
                        e.hl.Adornee = m
                        e.hl.Enabled = true
                    end
                end
            end
        end)
        task.wait(0.2)
    end
end)

-- dormant marker: where an enemy was last seen, fading over 4 seconds
do
    local df = Instance.new("Folder")
    df.Name = "ZenithBS2Dormant"
    df.Parent = workspace.CurrentCamera
    local DP = {}
    for _ = 1, 8 do
        pcall(function()
            local a = Instance.new("Part")
            a.Anchored, a.CanCollide, a.Transparency, a.Size = true, false, 1, Vector3.new(0.2, 0.2, 0.2)
            pcall(function() a.CanQuery, a.CanTouch = false, false end)
            a.Parent = df
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.fromOffset(150, 22)
            bb.AlwaysOnTop = true
            bb.Adornee = a
            bb.Enabled = false
            bb.Parent = a
            local f, t = plate(bb, 11)
            DP[#DP + 1] = {a = a, bb = bb, f = f, t = t, gen = 0}
        end)
    end
    S.dormant = function(pos, name)
        local d = DP[1]
        if not d then return end
        table.remove(DP, 1)
        DP[#DP + 1] = d
        d.gen = d.gen + 1
        local gen = d.gen
        d.a.CFrame = CFrame.new(pos)
        d.t.Text = name .. "  ?"
        d.bb.Enabled = true
        task.spawn(function()
            local t0 = tick()
            while tick() - t0 < 4 and d.gen == gen do
                local k = (tick() - t0) / 4
                pcall(function() d.t.TextTransparency = k; d.f.BackgroundTransparency = 0.5 + k * 0.5 end)
                task.wait(0.1)
            end
            if d.gen == gen then d.bb.Enabled = false end
        end)
    end
end

------------------------------------------------------------------ FOV rings (plain GUI, no Drawing needed)
local ringGui = Instance.new("ScreenGui")
ringGui.Name = "ZenithBS2Fov"
ringGui.IgnoreGuiInset = true
ringGui.ResetOnSpawn = false
ringGui.DisplayOrder = 40
pcall(function() ringGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not ringGui.Parent then ringGui.Parent = lp:WaitForChild("PlayerGui") end
local function ring(col)
    local f = Instance.new("Frame")
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Position = UDim2.fromScale(0.5, 0.5)
    f.BackgroundTransparency = 1
    f.Parent = ringGui
    Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
    local st = Instance.new("UIStroke")
    st.Thickness = 1
    st.Transparency = 0.35
    st.Color = col
    st.Parent = f
    return f, st
end
local silentRing, silentStroke = ring(Color3.new(1, 1, 1))
local aimRing, aimStroke = ring(ACC.Mint)

connect(RunService.RenderStepped, function(dtR)
    if S.trackVelocity then pcall(S.trackVelocity, dtR or 1 / 60) end
ident()
    cam = workspace.CurrentCamera
    if not running then return end
    S.frame = (S.frame or 0) + 1
    if not S.models or S.frame % 3 == 1 then
        local okM, list = pcall(models)
        S.models = okM and list or {}
    end
    pcall(function()
        S.target = nil
        if S.frame % 2 == 0 or CFG.autoFire or (S.aimT and not S.aimT.Parent) then
            S.aimT = (CFG.silent or CFG.autoFire) and pick(wval("fov", CFG.silentFov), CFG.autoFire and CFG.af360) or nil
        end
        local accent = ACC[CFG.accent] or ACC.Mint
        silentRing.Visible = CFG.silent and CFG.showFov
        local sf = wval("fov", CFG.silentFov)
        silentRing.Size = UDim2.fromOffset(sf * 2, sf * 2)
        silentStroke.Color = S.aimT and accent or Color3.new(1, 1, 1)
        aimRing.Visible = CFG.aimbot and CFG.showFov
        aimRing.Size = UDim2.fromOffset(CFG.aimFov * 2, CFG.aimFov * 2)
        aimStroke.Color = accent
    end)
    local seen = {}
    local all = S.models
    if S.hitCheck then pcall(S.hitCheck, all) end
    for _, it in ipairs(all) do
        local m = it[1]
        seen[m] = true
        local e = E[m]
        if not e then
            local okN, made = pcall(newESP, m)
            if not okN then S.dbg.espErr = tostring(made) end
            e = okN and made or nil
        end
        if e then
            local okS, errS = pcall(stepESP, m, it[2], e, it[3])
            if not okS then
                S.dbg.stepErr = tostring(errS)
                pcall(hideESP, e)
            end
        end
    end
    for m, e in pairs(E) do
        if not seen[m] or not m.Parent then
            if CFG.dormant and e.lastPos and e.lastEnemy and CFG.esp and S.dormant then pcall(S.dormant, e.lastPos, e.lastName or "enemy") end
            removeESP(m)
        end
    end
end)

------------------------------------------------------------------ menu
local T = {
    bg = Color3.fromRGB(12, 12, 14), row = Color3.fromRGB(255, 255, 255), line = Color3.fromRGB(255, 255, 255),
    text = Color3.fromRGB(238, 238, 240), sub = Color3.fromRGB(150, 152, 160), off = Color3.fromRGB(70, 72, 80),
}
local function acc() return ACC[CFG.accent] or ACC.Mint end
local FONT, FONT_B = Enum.Font.Gotham, Enum.Font.GothamBold
if type(CFG.binds) ~= "table" then CFG.binds = {} end

local gui = Instance.new("ScreenGui")
gui.Name = "ZenithBS2Menu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function tween(o, t, props) TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play() end

-- small line icons drawn from frames, 16x16
local function glyph(parent, name, col)
    local h = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(16, 16)}, parent)
    local parts = {}
    local function bar(x, y, w, ht, rot, r)
        local f = new("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, ht), Rotation = rot or 0,
            BackgroundColor3 = col, BorderSizePixel = 0}, h)
        if r then round(f, r) end
        parts[#parts + 1] = {f, "bg"}
    end
    local function ring(x, y, w, ht, th, r)
        local f = new("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, ht or w), BackgroundTransparency = 1}, h)
        round(f, r or 99)
        local st = new("UIStroke", {Color = col, Thickness = th or 1.5}, f)
        parts[#parts + 1] = {st, "stroke"}
    end
    if name == "crosshair" then
        ring(3, 3, 10, 10); bar(7.25, 0, 1.5, 4); bar(7.25, 12, 1.5, 4); bar(0, 7.25, 4, 1.5); bar(12, 7.25, 4, 1.5)
    elseif name == "target" then
        ring(1, 1, 14, 14); ring(5, 5, 6, 6); bar(7, 7, 2, 2, 0, 1)
    elseif name == "eye" then
        ring(1, 4, 14, 8, 1.5, 6); bar(6, 6, 4, 4, 0, 2)
    elseif name == "box" then
        ring(2, 2, 12, 12, 1.5, 2)
    elseif name == "user" then
        ring(5, 1, 6, 6); ring(2, 9, 12, 7, 1.5, 4)
    elseif name == "heart" then
        bar(3, 3, 5, 5, 0, 3); bar(8, 3, 5, 5, 0, 3); bar(4.5, 5, 7, 7, 45, 1)
    elseif name == "ruler" then
        ring(1, 5, 14, 6, 1.5, 1); bar(4, 5, 1.5, 3); bar(7.25, 5, 1.5, 3); bar(10.5, 5, 1.5, 3)
    elseif name == "line" then
        bar(1, 7.25, 14, 1.5, -40); bar(11, 1, 4, 4, 0, 2)
    elseif name == "spark" then
        bar(7.25, 1, 1.5, 14); bar(1, 7.25, 14, 1.5); bar(4, 4, 8, 8, 45, 2)
    elseif name == "shield" then
        ring(3, 1, 10, 9, 1.5, 3); bar(4.5, 7, 7, 7, 45, 1)
    elseif name == "bell" then
        ring(3, 2, 10, 10, 1.5, 5); bar(2, 11, 12, 1.5); bar(7, 13, 2, 2, 0, 1)
    elseif name == "gun" then
        bar(1, 4, 13, 4, 0, 1); bar(3, 8, 3, 6, -10, 1); bar(13, 3, 2, 2)
    elseif name == "spread" then
        bar(2, 7, 3, 3, 0, 2); bar(7, 3, 3, 3, 0, 2); bar(11, 9, 3, 3, 0, 2)
    elseif name == "reload" then
        ring(2, 2, 12, 12); bar(10, 0, 5, 5, 45)
    elseif name == "bolt" then
        bar(6, 0, 3, 9, 25); bar(7, 7, 3, 9, 25)
    elseif name == "camera" then
        ring(1, 4, 14, 10, 1.5, 3); ring(5, 6, 6, 6); bar(4, 2, 5, 2)
    elseif name == "sun" then
        bar(5, 5, 6, 6, 0, 3); bar(7.25, 0, 1.5, 3); bar(7.25, 13, 1.5, 3); bar(0, 7.25, 3, 1.5); bar(13, 7.25, 3, 1.5)
    elseif name == "flash" then
        ring(3, 3, 10, 10); bar(7.25, 1, 1.5, 14, 45)
    elseif name == "cloud" then
        bar(1, 7, 6, 6, 0, 3); bar(5, 4, 7, 7, 0, 4); bar(9, 7, 6, 6, 0, 3)
    elseif name == "fov" then
        ring(1, 1, 14, 14, 1); ring(5, 5, 6, 6, 1)
    elseif name == "gear" then
        ring(4, 4, 8, 8); bar(7.25, 0, 1.5, 3); bar(7.25, 13, 1.5, 3); bar(0, 7.25, 3, 1.5); bar(13, 7.25, 3, 1.5)
    elseif name == "key" then
        ring(1, 4, 7, 7); bar(7, 6.75, 8, 1.5); bar(12, 6.75, 1.5, 4)
    elseif name == "wall" then
        ring(1, 2, 14, 12, 1.5, 1); bar(1, 7.25, 14, 1.5); bar(7.25, 2, 1.5, 6)
    elseif name == "team" then
        ring(1, 3, 6, 6); ring(9, 3, 6, 6); bar(1, 11, 14, 2, 0, 1)
    elseif name == "hand" then
        ring(3, 5, 10, 10, 1.5, 3); bar(4, 1, 2, 5, 0, 1); bar(7, 0, 2, 6, 0, 1); bar(10, 1, 2, 5, 0, 1)
    elseif name == "signal" then
        bar(2, 11, 3, 4); bar(6.5, 7, 3, 8); bar(11, 3, 3, 12)
    elseif name == "chip" then
        ring(3, 3, 10, 10, 1.5, 2); bar(0, 6, 3, 1.5); bar(0, 9, 3, 1.5); bar(13, 6, 3, 1.5); bar(13, 9, 3, 1.5); bar(6, 0, 1.5, 3); bar(9, 0, 1.5, 3)
    elseif name == "clock" then
        ring(1, 1, 14, 14); bar(7.25, 3.5, 1.5, 5); bar(7.25, 7.25, 4, 1.5)
    elseif name == "save" then
        ring(2, 2, 12, 12, 1.5, 2); bar(5, 2, 6, 4)
    elseif name == "power" then
        ring(2, 3, 12, 12); bar(7.25, 0, 1.5, 7)
    else
        bar(6, 6, 4, 4, 0, 2)
    end
    return h, parts
end

local W, H = 390, 340
local win = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H),
    BackgroundColor3 = T.bg, BackgroundTransparency = 0.5, BorderSizePixel = 0}, gui)
round(win, 10)
new("UIStroke", {Color = T.line, Transparency = 0.88, Thickness = 1}, win)
local vps = cam.ViewportSize
local baseScale = math.clamp(math.min((vps.X - 30) / W, (vps.Y - 30) / H), 0.65, 1.3)
local winScale = new("UIScale", {Scale = baseScale}, win)
task.spawn(function()
ident()
    while running do
        local want = baseScale * math.clamp(CFG.uiScale or 1, 1, 2)
        if math.abs(winScale.Scale - want) > 0.001 then winScale.Scale = want end
        task.wait(0.2)
    end
end)

local head = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Active = true}, win)
new("TextLabel", {Text = "zenith", Font = Enum.Font.Michroma, TextSize = 14, TextColor3 = T.text, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0, 120, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, head)
local cfgSave = new("TextButton", {Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(92, 8), Size = UDim2.fromOffset(24, 24),
    BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, BorderSizePixel = 0}, head)
round(cfgSave, 6)
do local ic = glyph(cfgSave, "save", T.sub) ic.Position = UDim2.new(0, 4, 0, 4) end
local cfgDrop = new("TextButton", {Text = "  no config  v", Font = FONT_B, TextSize = 11, TextColor3 = T.sub, AutoButtonColor = false,
    Position = UDim2.fromOffset(120, 8), Size = UDim2.fromOffset(120, 24), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55,
    BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left}, head)
round(cfgDrop, 6)
local hide = new("TextButton", {Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
    Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1}, head)
new("Frame", {Size = UDim2.fromOffset(10, 2), Position = UDim2.new(0.5, -5, 0.5, -1), BackgroundColor3 = T.sub, BorderSizePixel = 0}, hide)

local tabsBar = new("Frame", {Position = UDim2.fromOffset(10, 40), Size = UDim2.new(1, -20, 0, 30), BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.55, BorderSizePixel = 0}, win)
round(tabsBar, 8)
new("UIPadding", {PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3)}, tabsBar)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, tabsBar)

local body = new("Frame", {Position = UDim2.fromOffset(10, 78), Size = UDim2.new(1, -20, 1, -86), BackgroundTransparency = 1, ClipsDescendants = true}, win)

local pages, tabBtns = {}, {}
local refreshers = {}
S.refreshAll = function() for _, r in ipairs(refreshers) do pcall(r) end end
-- the config picker under the header: every saved config, tap to load; save writes the current one (or a new one)
do
    local CDIR = "ZenithBS/configs"
    local list = new("Frame", {Position = UDim2.fromOffset(120, 34), Size = UDim2.fromOffset(150, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false, ZIndex = 20}, win)
    round(list, 6)
    new("UIStroke", {Color = T.line, Transparency = 0.85}, list)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, list)
    new("UIPadding", {PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3)}, list)
    local function names()
        local out = {}
        pcall(function()
            for _, path in ipairs(listfiles(CDIR)) do
                local n = tostring(path):match("([^/\\]+)%.json$")
                if n then out[#out + 1] = n end
            end
        end)
        table.sort(out)
        return out
    end
    local function label()
        cfgDrop.Text = "  " .. ((CFG.curCfg ~= "" and CFG.curCfg) or "no config") .. "  v"
    end
    label()
    local function writeCfg(n)
        pcall(function()
            if makefolder then
                if not isfolder("ZenithBS") then makefolder("ZenithBS") end
                if not isfolder(CDIR) then makefolder(CDIR) end
            end
            writefile(CDIR .. "/" .. n .. ".json", Http:JSONEncode(CFG))
        end)
    end
    local function rebuild()
        for _, ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        for i, n in ipairs(names()) do
            local b = new("TextButton", {Text = "  " .. n, Font = FONT, TextSize = 11, TextColor3 = (n == CFG.curCfg) and acc() or T.text,
                AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = i, ZIndex = 21}, list)
            b.Activated:Connect(function()
                pcall(function()
                    for k, v in pairs(Http:JSONDecode(readfile(CDIR .. "/" .. n .. ".json"))) do
                        if CFG[k] ~= nil and type(CFG[k]) == type(v) then CFG[k] = v end
                    end
                end)
                CFG.curCfg = n
                save()
                for _, r in ipairs(refreshers) do pcall(r) end
                label()
                list.Visible = false
            end)
        end
        local nb = new("TextButton", {Text = "  + new config", Font = FONT_B, TextSize = 11, TextColor3 = acc(), AutoButtonColor = false,
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 999, ZIndex = 21}, list)
        nb.Activated:Connect(function()
            local n = "config " .. (#names() + 1)
            CFG.curCfg = n
            writeCfg(n)
            save()
            label()
            rebuild()
        end)
    end
    cfgDrop.Activated:Connect(function()
        list.Visible = not list.Visible
        if list.Visible then rebuild() end
    end)
    cfgSave.Activated:Connect(function()
        local n = (CFG.curCfg ~= "" and CFG.curCfg) or ("config " .. (#names() + 1))
        CFG.curCfg = n
        writeCfg(n)
        save()
        label()
        if list.Visible then rebuild() end
    end)
end
local function selectTab(name)
    for n, pg in pairs(pages) do pg.Visible = (n == name) end
    for n, b in pairs(tabBtns) do
        local on = n == name
        tween(b, 0.18, {BackgroundTransparency = on and 0.86 or 1, TextColor3 = on and T.text or T.sub})
    end
end
local function tab(name, order)
    local b = new("TextButton", {Text = name, Font = FONT_B, TextSize = 12, TextColor3 = T.sub, AutoButtonColor = false,
        BackgroundColor3 = T.row, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1 / 6, -3, 1, 0), LayoutOrder = order}, tabsBar)
    round(b, 6)
    local pg = new("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.sub, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, body)
    new("UIListLayout", {Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder}, pg)
    new("UIPadding", {PaddingBottom = UDim.new(0, 6), PaddingRight = UDim.new(0, 4)}, pg)
    pages[name], tabBtns[name] = pg, b
    b.Activated:Connect(function() selectTab(name) end)
    return pg
end

local order = 0
local function rowFrame(pg, h, iconName)
    order = order + 1
    local f = new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = order}, pg)
    new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 34, 1, 0), Size = UDim2.new(1, -34, 0, 1),
        BackgroundColor3 = T.line, BackgroundTransparency = 0.93, BorderSizePixel = 0}, f)
    if iconName then
        local ic = glyph(f, iconName, T.sub)
        ic.Position = UDim2.new(0, 8, 0, 11)
    end
    return f
end
local function caption(pg, txt)
    order = order + 1
    new("TextLabel", {Text = txt, Font = FONT_B, TextSize = 10, TextColor3 = T.sub, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22), LayoutOrder = order, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Bottom}, pg)
end

-- binds
local ICON_OF = {}
local bindListening = false
local function keyLabel(k) return k and (string.len(k) > 6 and string.sub(k, 1, 6) or k) or "-" end

local function toggle(pg, txt, key, iconName, settings)
    ICON_OF[key] = {txt, iconName}
    local f = rowFrame(pg, 38, iconName)
    new("TextLabel", {Text = txt, Font = FONT, TextSize = 13, TextColor3 = T.text, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -160, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
    if settings then
        order = order + 1
        local box = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            Visible = false, LayoutOrder = order}, pg)
        new("UIListLayout", {Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder}, box)
        new("UIPadding", {PaddingLeft = UDim.new(0, 18)}, box)
        local dots = new("TextButton", {Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -96, 0.5, 0),
            Size = UDim2.fromOffset(26, 20), BackgroundTransparency = 1}, f)
        local dotParts = {}
        for k = 0, 2 do
            local d = new("Frame", {Size = UDim2.fromOffset(3, 3), Position = UDim2.new(0.5, -6 + k * 5, 0.5, -1), BackgroundColor3 = T.sub,
                BorderSizePixel = 0}, dots)
            round(d, 2)
            dotParts[#dotParts + 1] = d
        end
        local built = false
        dots.Activated:Connect(function()
ident()
            if not built then
                built = true
                local keep = order
                settings(box)
                order = math.max(order, keep)
            end
            box.Visible = not box.Visible
            for _, d in ipairs(dotParts) do d.BackgroundColor3 = box.Visible and acc() or T.sub end
        end)
    end
    local track = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(32, 18),
        BackgroundColor3 = T.off, BorderSizePixel = 0}, f)
    round(track, 9)
    local knob = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0}, track)
    round(knob, 6)
    local function render(anim)
        local on = CFG[key] == true
        local p1 = {BackgroundColor3 = on and acc() or T.off}
        local p2 = {Position = on and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}
        if anim then tween(track, 0.18, p1); tween(knob, 0.18, p2)
        else track.BackgroundColor3 = p1.BackgroundColor3; knob.Position = p2.Position end
    end
    render(false)
    refreshers[#refreshers + 1] = function() render(true) end
    local hit = new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -126, 1, 0)}, f)
    hit.Activated:Connect(function()
ident()
        CFG[key] = not CFG[key]
        render(true)
        save()
        if S.onToggle then pcall(S.onToggle, key) end
    end)
    local tr2 = new("TextButton", {Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 44, 1, 0)}, f)
    tr2.Activated:Connect(function()
ident()
        CFG[key] = not CFG[key]
        render(true)
        save()
        if S.onToggle then pcall(S.onToggle, key) end
    end)
    S.labels = S.labels or {}
    S.labels[key] = S.labels[key] or txt
    -- bind chip: tap, press a key; Backspace clears. On a phone: tap = a button for it on the screen (tap again to remove)
    local chip = new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -46, 0.5, 0), Size = UDim2.fromOffset(46, 20),
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6, AutoButtonColor = false, Text = "", BorderSizePixel = 0}, f)
    round(chip, 5)
    local kic = glyph(chip, "key", T.sub)
    kic.Position = UDim2.new(0, 3, 0.5, -8)
    kic.Size = UDim2.fromOffset(16, 16)
    local kl = new("TextLabel", {Text = keyLabel(CFG.binds[key]), Font = FONT_B, TextSize = 10, TextColor3 = T.sub, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -22, 1, 0)}, chip)
    chip.Activated:Connect(function()
ident()
        if UIS.TouchEnabled and not UIS.KeyboardEnabled then
            CFG.mBinds[key] = (not CFG.mBinds[key]) or nil
            kl.Text = CFG.mBinds[key] and "tap" or keyLabel(CFG.binds[key])
            save()
            if S.mbSync then S.mbSync() end
            return
        end
        if bindListening then return end
        bindListening = true
        kl.Text = "..."
        kl.TextColor3 = acc()
        local c
        c = UIS.InputBegan:Connect(function(i)
ident()
            if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local n = i.KeyCode.Name
            CFG.binds[key] = (n ~= "Backspace" and n ~= "Escape" and n ~= "Delete") and n or nil
            c:Disconnect()
            kl.Text = keyLabel(CFG.binds[key])
            kl.TextColor3 = T.sub
            save()
            task.delay(0.15, function() bindListening = false end)
        end)
    end)
    refreshers[#refreshers + 1] = function() kl.Text = (CFG.mBinds[key] and "tap") or keyLabel(CFG.binds[key]) end
    if CFG.mBinds[key] then kl.Text = "tap" end
    ICON_OF[key].render = render
end

local function slider(pg, txt, key0, mn, mx, step, iconName)
    local function K() return type(key0) == "function" and key0() or key0 end
    local f = rowFrame(pg, 48, iconName)
    new("TextLabel", {Text = txt, Font = FONT, TextSize = 13, TextColor3 = T.text, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(34, 5), Size = UDim2.new(1, -100, 0, 18), TextXAlignment = Enum.TextXAlignment.Left}, f)
    local val = new("TextLabel", {Text = "", Font = FONT_B, TextSize = 12, TextColor3 = T.sub, BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 5), Size = UDim2.fromOffset(60, 18),
        TextXAlignment = Enum.TextXAlignment.Right}, f)
    local track = new("Frame", {Position = UDim2.new(0, 34, 0, 32), Size = UDim2.new(1, -42, 0, 3), BackgroundColor3 = T.off, BorderSizePixel = 0}, f)
    round(track, 2)
    local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = acc(), BorderSizePixel = 0}, track)
    round(fill, 2)
    local knob = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0}, track)
    round(knob, 5)
    local function render()
        local cur = tonumber(CFG[K()]) or mn
        local a = math.clamp((cur - mn) / (mx - mn), 0, 1)
        fill.Size = UDim2.fromScale(a, 1)
        fill.BackgroundColor3 = acc()
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        val.Text = (step < 1) and string.format("%.1f", cur) or tostring(math.floor(cur + 0.5))
    end
    render()
    refreshers[#refreshers + 1] = render
    local dragging = false
    local function setFrom(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = mn + (mx - mn) * a
        v = math.floor(v / step + 0.5) * step
        CFG[K()] = math.clamp(v, mn, mx)
        render()
    end
    local hit = new("TextButton", {Text = "", BackgroundTransparency = 1, Position = UDim2.new(0, 28, 0, 22), Size = UDim2.new(1, -28, 1, -22)}, f)
    hit.InputBegan:Connect(function(i)
ident()
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFrom(i.Position.X)
        end
    end)
    connect(UIS.InputChanged, function(i)
ident()
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFrom(i.Position.X)
        end
    end)
    connect(UIS.InputEnded, function(i)
ident()
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            save()
        end
    end)
end

local function choice(pg, txt, key, options, iconName)
    local f = rowFrame(pg, 66, iconName)
    new("TextLabel", {Text = txt, Font = FONT, TextSize = 13, TextColor3 = T.text, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(34, 5), Size = UDim2.new(1, -40, 0, 18), TextXAlignment = Enum.TextXAlignment.Left}, f)
    local bar = new("Frame", {Position = UDim2.new(0, 34, 0, 30), Size = UDim2.new(1, -40, 0, 26), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.6, BorderSizePixel = 0}, f)
    round(bar, 6)
    new("UIPadding", {PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2)}, bar)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2)}, bar)
    local btns = {}
    local function render()
        for opt, b in pairs(btns) do
            local on = CFG[key] == opt
            tween(b, 0.15, {BackgroundTransparency = on and 0.86 or 1, TextColor3 = on and T.text or T.sub})
        end
    end
    for _, opt in ipairs(options) do
        local b = new("TextButton", {Text = opt, Font = FONT_B, TextSize = 11, TextColor3 = T.sub, AutoButtonColor = false,
            BackgroundColor3 = T.row, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1 / #options, -2, 1, 0)}, bar)
        round(b, 5)
        btns[opt] = b
        b.Activated:Connect(function()
ident()
            CFG[key] = opt
            if key == "aaTorso" then CFG.aaMode = opt end
            if key == "aaMode" then CFG.aaTorso = opt end
            if key == "aaHead" then CFG.aaPitchMode = opt end
            if key == "aaPitchMode" then CFG.aaHead = opt end
            render()
            for _, r in ipairs(refreshers) do pcall(r) end
            save()
        end)
    end
    render()
    refreshers[#refreshers + 1] = render
end

local function wheel(pg, txt, hk, sk, vk, iconName)
    local f = rowFrame(pg, 226, iconName)
    new("TextLabel", {Text = txt, Font = FONT, TextSize = 13, TextColor3 = T.text, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(34, 5), Size = UDim2.new(1, -90, 0, 18), TextXAlignment = Enum.TextXAlignment.Left}, f)
    local swatch = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 5), Size = UDim2.fromOffset(40, 16),
        BorderSizePixel = 0}, f)
    round(swatch, 5)
    local R = 74
    local area = new("Frame", {Position = UDim2.new(0.5, -R, 0, 30), Size = UDim2.fromOffset(R * 2, R * 2), BackgroundTransparency = 1}, f)
    local RINGS, SEGS = 6, 40
    for ring = RINGS, 1, -1 do
        local d = R * (ring - 0.5) / RINGS
        local thick = R / RINGS + 1
        local len = math.max(2 * math.pi * d / SEGS + 1.5, 3)
        for k = 0, SEGS - 1 do
            local a = (k + 0.5) / SEGS * 2 * math.pi
            new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(R + math.cos(a) * d, R + math.sin(a) * d),
                Size = UDim2.fromOffset(thick, len), Rotation = math.deg(a), BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromHSV(k / SEGS, ring / RINGS, 1)}, area)
        end
    end
    new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(R, R), Size = UDim2.fromOffset(R / RINGS * 1.2, R / RINGS * 1.2),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, area)
    local dot = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 3}, area)
    round(dot, 6)
    new("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2}, dot)
    local function render()
        local h, sa = CFG[hk] or 0, CFG[sk] or 1
        local a = h * 2 * math.pi
        dot.Position = UDim2.fromOffset(R + math.cos(a) * sa * R, R + math.sin(a) * sa * R)
        swatch.BackgroundColor3 = Color3.fromHSV(h, sa, CFG[vk] or 1)
    end
    render()
    refreshers[#refreshers + 1] = render
    local dragging = false
    local function pickAt(pos)
        local c = area.AbsolutePosition + area.AbsoluteSize / 2
        local v = Vector2.new(pos.X, pos.Y) - c
        local r = area.AbsoluteSize.X / 2
        CFG[hk] = (math.atan2(v.Y, v.X) / (2 * math.pi)) % 1
        CFG[sk] = math.clamp(v.Magnitude / math.max(r, 1), 0, 1)
        render()
    end
    local hit = new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4}, area)
    hit.InputBegan:Connect(function(i)
ident()
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            pickAt(i.Position)
        end
    end)
    connect(UIS.InputChanged, function(i)
ident()
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then pickAt(i.Position) end
    end)
    connect(UIS.InputEnded, function(i)
ident()
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            save()
        end
    end)
    slider(pg, "brightness", vk, 0.1, 1, 0.05, "sun")
end

local function colors(pg, txt, key, iconName)
    local f = rowFrame(pg, 62, iconName)
    new("TextLabel", {Text = txt, Font = FONT, TextSize = 13, TextColor3 = T.text, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(34, 5), Size = UDim2.new(1, -40, 0, 18), TextXAlignment = Enum.TextXAlignment.Left}, f)
    local row = new("Frame", {Position = UDim2.new(0, 34, 0, 30), Size = UDim2.new(1, -40, 0, 22), BackgroundTransparency = 1}, f)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center}, row)
    local rings = {}
    local function render()
        for nm, st in pairs(rings) do st.Transparency = (CFG[key] == nm) and 0 or 1 end
    end
    for _, p in ipairs(PALETTE) do
        local b = new("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(18, 18), BackgroundColor3 = p[2], BorderSizePixel = 0}, row)
        round(b, 9)
        rings[p[1]] = new("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 1}, b)
        b.Activated:Connect(function()
ident()
            CFG[key] = p[1]
            render()
            for _, r in ipairs(refreshers) do pcall(r) end
            save()
        end)
    end
    render()
    refreshers[#refreshers + 1] = render
end

-- ESP preview: a little figure with the ESP drawn on it; tap the box, name, health bar, distance or tracer to switch it
local function espPreview(pg)
    order = order + 1
    local f = new("Frame", {Size = UDim2.new(1, 0, 0, 210), BackgroundTransparency = 1, LayoutOrder = order}, pg)
    local stage = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(190, 196),
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, BorderSizePixel = 0, ClipsDescendants = true}, f)
    round(stage, 8)
    local figCol = Color3.fromRGB(95, 98, 108)
    local head = new("Frame", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(0.5, -10, 0, 42), BackgroundColor3 = figCol, BorderSizePixel = 0}, stage)
    round(head, 10)
    new("Frame", {Size = UDim2.fromOffset(34, 48), Position = UDim2.new(0.5, -17, 0, 64), BackgroundColor3 = figCol, BorderSizePixel = 0}, stage)
    new("Frame", {Size = UDim2.fromOffset(13, 44), Position = UDim2.new(0.5, -16, 0, 113), BackgroundColor3 = figCol, BorderSizePixel = 0}, stage)
    new("Frame", {Size = UDim2.fromOffset(13, 44), Position = UDim2.new(0.5, 3, 0, 113), BackgroundColor3 = figCol, BorderSizePixel = 0}, stage)
    local bx, by, bw, bh = 95 - 34, 36, 68, 124
    local function line(x, y, w, h)
        return new("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1)}, stage)
    end
    local cl = 16
    local corners = {
        line(bx, by, cl, 2), line(bx, by, 2, cl), line(bx + bw - cl, by, cl, 2), line(bx + bw - 2, by, 2, cl),
        line(bx, by + bh - 2, cl, 2), line(bx, by + bh - cl, 2, cl), line(bx + bw - cl, by + bh - 2, cl, 2), line(bx + bw - 2, by + bh - cl, 2, cl),
    }
    local full = new("Frame", {Position = UDim2.fromOffset(bx, by), Size = UDim2.fromOffset(bw, bh), BackgroundTransparency = 1}, stage)
    local fullSt = new("UIStroke", {Thickness = 2, Color = Color3.new(1, 1, 1)}, full)
    local fullGrad = new("UIGradient", {Rotation = 90}, fullSt)
    local nameL = new("TextLabel", {Text = "enemy", Font = FONT_B, TextSize = 12, BackgroundTransparency = 1, Position = UDim2.fromOffset(bx - 20, by - 20),
        Size = UDim2.fromOffset(bw + 40, 16)}, stage)
    local distL = new("TextLabel", {Text = "24m", Font = FONT, TextSize = 11, TextColor3 = Color3.fromRGB(200, 200, 205), BackgroundTransparency = 1,
        Position = UDim2.fromOffset(bx - 20, by + bh + 3), Size = UDim2.fromOffset(bw + 40, 14)}, stage)
    local hpBack = new("Frame", {Position = UDim2.fromOffset(bx - 7, by), Size = UDim2.fromOffset(3, bh), BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0}, stage)
    local hpFill = new("Frame", {Position = UDim2.new(0, 0, 0.3, 0), Size = UDim2.new(1, 0, 0.7, 0), BackgroundColor3 = Color3.fromRGB(90, 230, 120),
        BorderSizePixel = 0}, hpBack)
    local tracer = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, by + bh), Size = UDim2.new(0, 2, 1, -(by + bh)),
        BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1)}, stage)
    local function hit(x, y, w, h, key)
        local b = new("TextButton", {Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), ZIndex = 5}, stage)
        b.Activated:Connect(function()
ident()
            CFG[key] = not CFG[key]
            for _, r in ipairs(refreshers) do pcall(r) end
            save()
        end)
    end
    hit(bx - 24, by - 24, bw + 48, 20, "name")
    hit(bx - 14, by, 12, bh, "health")
    hit(bx - 24, by + bh + 1, bw + 48, 18, "dist")
    hit(bx + 6, by + 10, bw - 12, bh - 20, "box")
    local function render()
        local col = palCol(CFG.espCol, ENEMY)
        local col2 = CFG.espGrad and palCol(CFG.espCol2, col) or col
        local corner = CFG.boxStyle ~= "Full"
        for k, l in ipairs(corners) do
            l.Visible = CFG.box and corner
            l.BackgroundColor3 = (k <= 4) and col or col2
        end
        full.Visible = CFG.box and not corner
        fullGrad.Color = ColorSequence.new(col, col2)
        nameL.Visible = CFG.name
        nameL.TextColor3 = palCol(CFG.nameCol, Color3.new(1, 1, 1))
        distL.Visible = CFG.dist
        hpBack.Visible = CFG.health
        tracer.Visible = false
        tracer.BackgroundColor3 = col2
    end
    render()
    refreshers[#refreshers + 1] = render
end

local function input(pg, txt, key, iconName)
    local f = rowFrame(pg, 40, iconName)
    new("TextLabel", {Text = txt, Font = FONT, TextSize = 13, TextColor3 = T.text, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(34, 0), Size = UDim2.new(0.45, -34, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
    local box = new("TextBox", {Text = tostring(CFG[key] or ""), PlaceholderText = "name", Font = FONT, TextSize = 12, TextColor3 = T.text,
        PlaceholderColor3 = T.sub, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6, ClearTextOnFocus = false,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0.55, -6, 0, 24), BorderSizePixel = 0}, f)
    round(box, 6)
    box.FocusLost:Connect(function()
ident()
        CFG[key] = box.Text
    end)
    return box
end

local function button(pg, txt, fn, iconName)
    local f = rowFrame(pg, 38, iconName)
    local b = new("TextButton", {Text = txt, Font = FONT, TextSize = 13, TextColor3 = T.text, AutoButtonColor = false,
        BackgroundTransparency = 1, Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -34, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
    b.Activated:Connect(function() task.spawn(fn) end)
end

-- pages
local pAim = tab("aim", 1)
local function hitboxPicker(pg, pre)
    pre = pre or "hb"
    order = order + 1
    local f = new("Frame", {Size = UDim2.new(1, 0, 0, 170), BackgroundTransparency = 1, LayoutOrder = order}, pg)
    local stage = new("Frame", {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(150, 160),
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, BorderSizePixel = 0}, f)
    round(stage, 8)
    local parts = {}
    local function piece(g, x, y, w, h, r)
        local b = new("TextButton", {Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
            BorderSizePixel = 0}, stage)
        round(b, r or 4)
        parts[#parts + 1] = {b, g}
        b.Activated:Connect(function()
ident()
            CFG[pre .. g] = not CFG[pre .. g]
            for _, rr in ipairs(refreshers) do pcall(rr) end
            save()
        end)
    end
    piece("Head", 62, 8, 26, 26, 13)
    piece("Torso", 55, 38, 40, 50, 6)
    piece("Arms", 33, 38, 18, 48, 6)
    piece("Arms", 99, 38, 18, 48, 6)
    piece("Legs", 56, 92, 18, 56, 6)
    piece("Legs", 76, 92, 18, 56, 6)
    local function render()
        for _, it in ipairs(parts) do
            it[1].BackgroundColor3 = CFG[pre .. it[2]] and acc() or Color3.fromRGB(70, 72, 80)
        end
    end
    render()
    refreshers[#refreshers + 1] = render
end

toggle(pAim, "silent aim", "silent", "crosshair", function(b)
    hitboxPicker(b)
    slider(b, "fov", "silentFov", 20, 600, 5, "fov")
    toggle(b, "auto wall", "autoWall", "wall", function(b2)
        slider(b2, "wall power", "wallPower", 1, 4, 0.1, "wall")
        slider(b2, "min damage", "awd", 0, 200, 1, "wall")
    end)
    choice(b, "priority", "silentPrio", {"Crosshair", "Distance", "Health"}, "target")
    toggle(b, "auto fire", "autoFire", "bolt", function(b2)
        toggle(b2, "360 (behind you)", "af360", "target")
        toggle(b2, "auto stop", "autoStop", "line", function(b3)
            slider(b3, "stop time", "autoStopTime", 0.1, 2, 0.1, "clock")
        end)
    end)
end)
toggle(pAim, "anti-aim", "aa", "shield", function(b)
    choice(b, "yaw", "aaTorso", {"Spin", "Jitter", "Back", "Side"}, "reload")
    toggle(b, "manual aa", "aaManual", "shield", function(b2)
        toggle(b2, "manual left", "aaManLeft", "line")
        toggle(b2, "manual right", "aaManRight", "line")
    end)
    choice(b, "pitch", "aaHead", {"None", "Down", "Up", "Jitter"}, "user")
    toggle(b, "spin on air", "aaAir", "spark", function(b2)
        slider(b2, "spin speed", "aaAirSpeed", 1, 60, 1, "bolt")
        choice(b2, "pitch", "aaAirPitch", {"None", "Down", "Up", "Random"}, "line")
    end)
    slider(b, "spin speed", "aaSpeed", 1, 60, 1, "bolt")
end)
toggle(pAim, "double tap", "doubleTap", "bolt")
toggle(pAim, "rapid fire", "rapidFire", "bolt", function(b)
    slider(b, "shots", "rapidMult", 2, 4, 1, "bolt")
end)
toggle(pAim, "auto wall", "autoWall", "wall")
caption(pAim, "target")
choice(pAim, "aim at", "part", {"Head", "Body"}, "user")
toggle(pAim, "wall check", "wallCheck", "wall")
toggle(pAim, "team check", "teamCheck", "team")
toggle(pAim, "show fov", "showFov", "fov")

local pVisRoot = tab("visuals", 2)
local VIS = {}
do
    order = order + 1
    local seg = new("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = order}, pVisRoot)
    local box = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(210, 24),
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, BorderSizePixel = 0}, seg)
    round(box, 6)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), VerticalAlignment = Enum.VerticalAlignment.Center}, box)
    new("UIPadding", {PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2)}, box)
    local btns = {}
    local function pick(name)
        for n, f in pairs(VIS) do f.Visible = n == name end
        for n, b in pairs(btns) do
            local on = n == name
            b.TextColor3 = on and T.text or T.sub
            b.BackgroundTransparency = on and 0.75 or 1
        end
    end
    for i, n in ipairs({"players", "world", "local"}) do
        local b = new("TextButton", {Text = n, Font = FONT_B, TextSize = 11, AutoButtonColor = false, TextColor3 = T.sub, BackgroundColor3 = T.text,
            BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1 / 3, -2, 0, 20), LayoutOrder = i}, box)
        round(b, 5)
        btns[n] = b
        order = order + 1
        local f = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order,
            Visible = false}, pVisRoot)
        new("UIListLayout", {Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder}, f)
        VIS[n] = f
        b.Activated:Connect(function() pick(n) end)
    end
    pick("players")
end
local pVis = VIS.players
toggle(pVis, "esp", "esp", "eye", function(b)
    espPreview(b)
    toggle(b, "box", "box", "box")
    choice(b, "box style", "boxStyle", {"Corner", "Full"}, "box")
    toggle(b, "skeleton", "skeleton", "user")
    toggle(b, "weapon info", "wShow", "gun", function(b2)
        toggle(b2, "weapon name", "wInfo", "gun")
        toggle(b2, "weapon icon", "wIcon", "gun")
    end)
    toggle(b, "avatars", "espAvatar", "user")
    toggle(b, "flags", "flags", "line", function(b2)
        toggle(b2, "money", "fMoney", "chip")
        toggle(b2, "health", "fHealth", "user")
        toggle(b2, "ping", "fPing", "signal")
        toggle(b2, "distance", "fDist", "ruler")
        toggle(b2, "bomb", "fBomb", "flash")
    end)
    toggle(b, "teammates", "espTeam", "team")
    choice(b, "box color", "boxColMode", {"Team", "White", "Health"}, "spark")
    toggle(b, "box fill", "boxFill", "box", function(b2)
        slider(b2, "fill", "boxFillTr", 0, 1, 0.02, "eye")
    end)
    colors(b, "enemy color", "espCol", "spark")
    colors(b, "team color", "teamCol", "team")
    toggle(b, "gradient", "espGrad", "spark", function(b2)
        colors(b2, "second color", "espCol2", "spark")
        toggle(b2, "moving", "espGradAnim", "reload")
    end)
    colors(b, "name color", "nameCol", "user")
    toggle(b, "chams", "chams", "spark", function(b2)
        choice(b2, "style", "chamsStyle", {"Glow", "Outline"}, "spark")
        choice(b2, "", "chamsStyle", {"Neon", "ForceField"}, "spark")
        colors(b2, "color", "chamsCol", "spark")
        slider(b2, "fill", "chamsFill", 0, 1, 0.05, "eye")
        toggle(b2, "through walls", "chamsWalls", "wall")
    end)
    slider(b, "max distance", "maxDist", 100, 3000, 50, "ruler")
end)
pVis = VIS.world
toggle(pVis, "grenade esp", "grenadeEsp", "flash", function(b)
    toggle(b, "molotov zone", "gnZone", "cloud")
    toggle(b, "box", "gnBox", "box")
    toggle(b, "own color", "gnOwnCol", "spark", function(b2)
        colors(b2, "color", "gnCol", "spark")
    end)
    toggle(b, "name", "gnName", "user")
    toggle(b, "chams", "gnChams", "spark")
    toggle(b, "HE grenade", "gnHE", "flash")
    toggle(b, "flashbang", "gnFlash", "sun")
    toggle(b, "smoke", "gnSmoke", "cloud")
    toggle(b, "molotov", "gnMolotov", "bolt")
    toggle(b, "decoy", "gnDecoy", "target")
end)
pVis = VIS["local"]
toggle(pVis, "self chams", "selfChams", "user", function(b)
    choice(b, "style", "chamStyle", {"ForceField", "Neon", "Glass"}, "spark")
end)
toggle(pVis, "hand chams", "handChams", "hand", function(b)
    choice(b, "style", "chamStyle", {"ForceField", "Neon", "Glass"}, "spark")
end)
toggle(pVis, "glove chams", "gloveChams", "hand", function(b)
    choice(b, "style", "chamStyle", {"ForceField", "Neon", "Glass"}, "spark")
end)
toggle(VIS.world, "grenade trajectory", "gTraj", "line")
toggle(VIS.players, "aim marker", "aimMark", "crosshair")
toggle(VIS.world, "kill effect", "killFx", "spark", function(b)
    choice(b, "effect", "killFxType", {"Ghost", "Blood", "Lightning"}, "spark")
end)
toggle(pVis, "china hat", "chinaHat", "user", function(b)
    wheel(b, "color", "hatH", "hatS", "hatV", "spark")
end)
toggle(pVis, "weapon chams", "weaponChams", "gun", function(b)
    wheel(b, "color", "wcH", "wcS", "wcV", "spark")
    choice(b, "style", "chamStyle", {"ForceField", "Neon", "Glass"}, "spark")
end)

local pGun = tab("gun", 3)
toggle(pGun, "no recoil", "noRecoil", "gun")
toggle(pGun, "no spread", "noSpread", "spread")
toggle(pGun, "fast reload", "fastReload", "reload", function(b)
end)
toggle(pGun, "knife fast", "knifeFast", "gun", function(b)
    slider(b, "speed", "knifeSpeed", 1, 6, 0.1, "bolt")
end)
toggle(pGun, "auto reload", "autoReload", "reload")
toggle(pGun, "fast grenade", "fastThrow", "flash", function(b)
    slider(b, "speed", "throwSpeed", 1, 10, 0.5, "bolt")
end)

local pWorld = tab("world", 4)
toggle(pWorld, "third person", "third", "camera", function(b)
    slider(b, "distance", "thirdDist", 4, 30, 1, "ruler")
    toggle(b, "first person with knife", "tpKnife", "gun")
end)
toggle(pWorld, "fov", "fovOn", "fov", function(b)
    slider(b, "field of view", "camFov", 50, 120, 1, "fov")
end)
toggle(pWorld, "fullbright", "fullbright", "sun")
toggle(pWorld, "bomb timer", "bombTimer", "clock")
toggle(pWorld, "time", "timeOn", "clock", function(b)
    slider(b, "time of day", "clockTime", 0, 24, 0.5, "clock")
end)
toggle(pWorld, "fog", "fogOn", "cloud", function(b)
    slider(b, "distance", "fogEnd", 20, 2000, 10, "ruler")
    wheel(b, "color", "fogH", "fogS", "fogV", "spark")
end)
toggle(pWorld, "ambience", "ambOn", "sun", function(b)
    wheel(b, "color", "ambH", "ambS", "ambV", "spark")
    slider(b, "brightness", "ambBright", 0, 6, 0.1, "sun")
end)
toggle(pWorld, "color correction", "ccOn", "spark", function(b)
    slider(b, "brightness", "ccBright", -0.5, 0.5, 0.05, "sun")
    slider(b, "contrast", "ccContrast", -1, 1, 0.05, "sun")
    slider(b, "saturation", "ccSat", -1, 1, 0.05, "spark")
    wheel(b, "tint", "ccH", "ccS", "ccV", "spark")
end)
toggle(pWorld, "bloom", "bloomOn", "sun", function(b)
    slider(b, "intensity", "bloomInt", 0, 3, 0.1, "sun")
    slider(b, "size", "bloomSize", 0, 56, 1, "ruler")
    slider(b, "threshold", "bloomThr", 0, 3, 0.1, "line")
end)
toggle(pWorld, "blur", "blurOn", "cloud", function(b)
    slider(b, "size", "blurSize", 0, 40, 1, "ruler")
end)
toggle(pWorld, "anti flash", "antiFlash", "flash")
toggle(pWorld, "anti smoke", "antiSmoke", "cloud")
toggle(pWorld, "skybox", "skyOn", "sun", function(b)
    if S.skyLoad then S.skyLoad() end
    order = order + 1
    local list = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order}, b)
    new("UIListLayout", {Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder}, list)
    S.skyRedraw = function()
        for _, ch in ipairs(list:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
        if #S.skyList == 0 then
            local f = rowFrame(list, 30, nil)
            new("TextLabel", {Text = "loading skies...", Font = FONT, TextSize = 12, TextColor3 = T.sub, BackgroundTransparency = 1,
                Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
            return
        end
        for _, it in ipairs(S.skyList) do
            local f = rowFrame(list, 34, "sun")
            local on = CFG.skybox == it.key
            new("TextLabel", {Text = it.name, Font = on and FONT_B or FONT, TextSize = 13, TextColor3 = on and acc() or T.text, BackgroundTransparency = 1,
                Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
            local hit = new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, f)
            hit.Activated:Connect(function()
ident()
                CFG.skybox = (CFG.skybox == it.key) and "Off" or it.key
                save()
                S.skyRedraw()
            end)
        end
    end
    S.skyRedraw()
end)
toggle(pWorld, "view model", "vmOn", "gun", function(b)
    slider(b, "x (left / right)", "vmX", -3, 3, 0.05, "ruler")
    slider(b, "y (down / up)", "vmY", -3, 3, 0.05, "ruler")
    slider(b, "z (near / far)", "vmZ", -3, 3, 0.05, "ruler")
end)
toggle(pWorld, "custom model", "cmOn2", "user", function(b)
    -- pictures of the models; tap one to wear it
    local LIST = {{"Tung Tung Sahur", 138151705692565}, {"Villager", 90405905565781}, {"Pigg", 133116885317874},
        {"Banana", 7870128838}, {"Zombie", 2949443329}}
    order = order + 1
    local grid = new("Frame", {Size = UDim2.new(1, 0, 0, 226), BackgroundTransparency = 1, LayoutOrder = order}, b)
    new("UIGridLayout", {CellSize = UDim2.new(1 / 3, -6, 0, 104), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder}, grid)
    new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4)}, grid)
    local cards = {}
    local function render()
        for _, c in ipairs(cards) do
            local on = CFG.cmName == c.name
            c.stroke.Color = on and acc() or T.line
            c.stroke.Transparency = on and 0 or 0.85
            c.label.TextColor3 = on and acc() or T.text
        end
    end
    for i, it in ipairs(LIST) do
        local card = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5,
            BorderSizePixel = 0, LayoutOrder = i}, grid)
        round(card, 8)
        local st = new("UIStroke", {Color = T.line, Transparency = 0.85, Thickness = 1.5}, card)
        new("ImageLabel", {Image = "rbxthumb://type=Asset&id=" .. it[2] .. "&w=150&h=150", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
            Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -30)}, card)
        local lbl = new("TextLabel", {Text = string.lower(it[1]), Font = FONT_B, TextSize = 10, TextColor3 = T.text, BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 4, 1, -4), Size = UDim2.new(1, -8, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd}, card)
        cards[#cards + 1] = {name = it[1], stroke = st, label = lbl}
        card.Activated:Connect(function()
            CFG.cmName = it[1]
            save()
            render()
            if CFG.cmOn2 and S.buildModel then
                task.spawn(function()
                    if not S.buildModel() then
                        pcall(function()
                            game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Zenith", Text = "this model could not be loaded", Duration = 4})
                        end)
                    end
                end)
            end
        end)
    end
    render()
    refreshers[#refreshers + 1] = render
end)
toggle(pWorld, "bullet tracers", "bTracers", "line", function(b)
    choice(b, "type", "bTracerType", {"Neon", "Lightning"}, "bolt")
    wheel(b, "color", "trH", "trS", "trV", "spark")
    toggle(b, "gradient", "trGrad", "spark", function(b2)
        wheel(b2, "second color", "trH2", "trS2", "trV2", "spark")
    end)
    slider(b, "thickness", "trThick", 0.05, 0.5, 0.01, "ruler")
    slider(b, "time", "bTracerTime", 0.2, 3, 0.1, "clock")
end)

local pMove = tab("movement", 5)
toggle(pMove, "bhop", "bhop", "bolt")
toggle(pMove, "auto strafe", "autoStrafe", "reload", function(b)
    slider(b, "sensitivity", "strafeSens", 1, 10, 1, "line")
end)
toggle(pMove, "jump edge", "edgeJump", "bolt")

local pSet = tab("settings", 6)
toggle(pSet, "watermark", "watermark", "chip")
caption(pSet, "notify")
toggle(pSet, "hit notify", "hitNotify", "bell")
toggle(pSet, "kill notify", "killNotify", "bell")
caption(pSet, "sound")
choice(pSet, "kill sound", "killSound", {"None", "Neverlose", "CS:GO Taser"}, "bell")
choice(pSet, "hit sound", "hitSound", {"None", "Neverlose", "CS:GO Taser"}, "bell")
caption(pSet, "configs")
local cfgList
do
    local CDIR = "ZenithBS/configs"
    local function ensure()
        pcall(function()
            if makefolder and isfolder then
                if not isfolder("ZenithBS") then makefolder("ZenithBS") end
                if not isfolder(CDIR) then makefolder(CDIR) end
            end
        end)
    end
    local function names()
        local out = {}
        pcall(function()
            for _, p in ipairs(listfiles(CDIR)) do
                local n = tostring(p):match("([^/\\]+)%.json$")
                if n then out[#out + 1] = n end
            end
        end)
        table.sort(out)
        return out
    end
    local function apply(data)
        for k, v in pairs(data) do
            if CFG[k] ~= nil and type(CFG[k]) == type(v) then CFG[k] = v end
        end
        for _, r in ipairs(refreshers) do pcall(r) end
        save()
    end
    CFG.cfgName = CFG.cfgName or ""
    input(pSet, "name", "cfgName", "save")
    local function redraw() end
    button(pSet, "save config", function()
        local n = tostring(CFG.cfgName or ""):gsub("[^%w%-_ ]", "")
        if n == "" then return end
        ensure()
        pcall(function() writefile(CDIR .. "/" .. n .. ".json", Http:JSONEncode(CFG)) end)
        redraw()
    end, "save")
    order = order + 1
    cfgList = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order}, pSet)
    new("UIListLayout", {Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder}, cfgList)
    redraw = function()
        for _, ch in ipairs(cfgList:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
        local list = names()
        if #list == 0 then
            local f = rowFrame(cfgList, 30, nil)
            new("TextLabel", {Text = "no configs yet", Font = FONT, TextSize = 12, TextColor3 = T.sub, BackgroundTransparency = 1,
                Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
        end
        for _, n in ipairs(list) do
            local f = rowFrame(cfgList, 36, "box")
            new("TextLabel", {Text = n, Font = FONT, TextSize = 13, TextColor3 = T.text, BackgroundTransparency = 1,
                Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -150, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
            local function small(txt, x, fn)
                local b = new("TextButton", {Text = txt, Font = FONT_B, TextSize = 11, TextColor3 = T.text, AutoButtonColor = false,
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(52, 22),
                    BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, BorderSizePixel = 0}, f)
                round(b, 6)
                b.Activated:Connect(fn)
            end
            small("load", -64, function()
                pcall(function() apply(Http:JSONDecode(readfile(CDIR .. "/" .. n .. ".json"))) end)
            end)
            small("delete", -6, function()
                pcall(function() delfile(CDIR .. "/" .. n .. ".json") end)
                redraw()
            end)
        end
    end
    redraw()
end
choice(pSet, "accent", "accent", {"Mint", "Blue", "Rose", "Amber", "White"}, "gear")
slider(pSet, "ui size", "uiScale", 1, 2, 0.1, "box")
toggle(pSet, "keybind list", "bindList", "key")
button(pSet, "unload", function() if genv.ZenithBS2 then genv.ZenithBS2() end end, "power")
selectTab("aim")

------------------------------------------------------------------ aim marker: a small crosshair; whoever it is on gets a green outline
do
    local hl = Instance.new("Highlight")
    hl.FillTransparency, hl.OutlineTransparency = 1, 0
    hl.OutlineColor = Color3.fromRGB(80, 255, 110)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = workspace.CurrentCamera
    local cross = {}
    if DRAW_OK then
        for k = 1, 4 do cross[k] = draw("Line", {Thickness = 2, Visible = false, Transparency = 1, Color = Color3.fromRGB(80, 255, 110)}) end
    end
    local function boxHit(o, dir, p)
        local lo = p.CFrame:PointToObjectSpace(o)
        local ld = p.CFrame:VectorToObjectSpace(dir)
        local half = p.Size * 0.55
        local tmin, tmax = -math.huge, math.huge
        for _, ax in ipairs({"X", "Y", "Z"}) do
            local oo, dd, hh = lo[ax], ld[ax], half[ax]
            if math.abs(dd) < 1e-6 then
                if oo < -hh or oo > hh then return false end
            else
                local t1, t2 = (-hh - oo) / dd, (hh - oo) / dd
                if t1 > t2 then t1, t2 = t2, t1 end
                tmin, tmax = math.max(tmin, t1), math.min(tmax, t2)
                if tmin > tmax then return false end
            end
        end
        return tmax > 0
    end
    RunService:BindToRenderStep("ZenithBS2Mark", Enum.RenderPriority.Last.Value + 16, function()
        if not running then return end
        local c = workspace.CurrentCamera
        local vp = c.ViewportSize
        local cx, cy = vp.X / 2, vp.Y / 2
        local on = CFG.aimMark
        local under
        if on then
            local ray = c:ViewportPointToRay(cx, cy)
            for _, it in ipairs(S.models or {}) do
                if it[2] then
                    for _, p in ipairs(it[1]:GetChildren()) do
                        if p:IsA("BasePart") and p.Transparency < 1 and p.Name ~= "HumanoidRootPart" and p.Name ~= "CollisionCapsule"
                            and boxHit(ray.Origin, ray.Direction, p) then
                            under = it[1]
                            break
                        end
                    end
                end
                if under then break end
            end
        end
        if under then
            if hl.Adornee ~= under then hl.Adornee = under end
            hl.Enabled = true
        else
            hl.Enabled = false
        end
        local col = under and Color3.fromRGB(80, 255, 110) or Color3.new(1, 1, 1)
        local segs = {{-10, 0, -4, 0}, {4, 0, 10, 0}, {0, -10, 0, -4}, {0, 4, 0, 10}}
        for k = 1, 4 do
            local l = cross[k]
            if l then
                pcall(function()
                    if on then
                        local sg = segs[k]
                        l.From, l.To, l.Color, l.Visible = Vector2.new(cx + sg[1], cy + sg[2]), Vector2.new(cx + sg[3], cy + sg[4]), col, true
                    else
                        l.Visible = false
                    end
                end)
            end
        end
    end)
end

------------------------------------------------------------------ grenade trajectory (while a grenade is in your hands) + target box (who silent is locked on)
do
    local NADES = {["HE Grenade"] = true, ["Flashbang"] = true, ["Smoke Grenade"] = true, ["Molotov"] = true, ["Incendiary Grenade"] = true, ["Decoy Grenade"] = true}
    -- More samples give a smoother and longer prediction (about 1.6 s at 40 Hz).
    local SEG = 64
    local lines, ring, boxOut, boxIn = {}, nil, nil, nil
    if DRAW_OK then
        for k = 1, SEG do lines[k] = draw("Line", {Thickness = 2, Visible = false, Transparency = 1}) end
        ring = draw("Circle", {Radius = 8, Thickness = 2, NumSides = 24, Filled = false, Visible = false, Color = Color3.fromRGB(255, 80, 80)})
        boxOut = draw("Square", {Thickness = 4, Filled = false, Visible = false, Color = Color3.fromRGB(255, 50, 50)})
        boxIn = draw("Square", {Thickness = 1.5, Filled = false, Visible = false, Color = Color3.fromRGB(80, 255, 110)})
    else
        for k = 1, SEG do lines[k] = S.fline and S.fline(2, Color3.new(1, 1, 1)) end
    end
    local function hideAll()
        for _, l in ipairs(lines) do pcall(function() l.Visible = false end) end
        if ring then pcall(function() ring.Visible = false end) end
    end
    -- throw speed / gravity from the grenade's own settings when they are there, CS-like values otherwise
    local physCache = {}
    local function physOf(name)
        if S.nadeSpeed then return S.nadeSpeed, S.nadeGrav or workspace.Gravity end
        if physCache[name] then return physCache[name][1], physCache[name][2] end
        local speed, grav = 60, workspace.Gravity
        pcall(function()
            local mod = RS.Database.Custom.Weapons:FindFirstChild(name)
            local t = mod and require(mod)
            local function find(tbl, keys, depth)
                if type(tbl) ~= "table" or depth > 3 then return nil end
                for k, v in pairs(tbl) do
                    local lk = string.lower(tostring(k))
                    for _, key in ipairs(keys) do
                        if string.find(lk, key, 1, true) and tonumber(v) then return tonumber(v) end
                    end
                end
                for _, v in pairs(tbl) do
                    local r = find(v, keys, depth + 1)
                    if r then return r end
                end
            end
            local sp = find(t, {"throwspeed", "throwvelocity", "velocity", "speed"}, 0)
            local gr = find(t, {"gravity"}, 0)
            if sp and sp > 5 and sp < 400 then speed = sp end
            if gr and gr > 1 and gr < 500 then grav = gr end
        end)
        physCache[name] = {speed, grav}
        return speed, grav
    end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    RunService:BindToRenderStep("ZenithBS2Traj", Enum.RenderPriority.Last.Value + 14, function()
        if not running then return end
        local c = workspace.CurrentCamera
        -- target box
        local t = S.aimT
        if false and boxOut and t and t.Parent then
            local sp, on = c:WorldToViewportPoint(t.Position)
            if on and sp.Z > 0 then
                local size = math.clamp(900 / sp.Z, 10, 70)
                local pos = Vector2.new(sp.X - size / 2, sp.Y - size / 2)
                pcall(function()
                    boxOut.Position, boxOut.Size, boxOut.Visible = pos, Vector2.new(size, size), true
                    boxIn.Position, boxIn.Size, boxIn.Visible = pos, Vector2.new(size, size), true
                end)
            else
                pcall(function() boxOut.Visible, boxIn.Visible = false, false end)
            end
        elseif boxOut then
            pcall(function() boxOut.Visible, boxIn.Visible = false, false end)
        end
        -- trajectory
        local w = currentWeapon()
        if not (CFG.gTraj and w and NADES[w]) then hideAll() return end
        local speed, grav = physOf(w)
        local me = myModel()
        rp.FilterDescendantsInstances = {me, c}
        local pos = c.CFrame.Position + c.CFrame.LookVector * 1.2
        -- Thrown objects commonly inherit some of the thrower's movement.
        local root = me and (me:FindFirstChild("HumanoidRootPart") or me:FindFirstChild("UpperTorso"))
        local inheritedVelocity = Vector3.zero
        if root and root:IsA("BasePart") then
            inheritedVelocity = root.AssemblyLinearVelocity * 0.5
        end
        local vel = c.CFrame.LookVector * speed + inheritedVelocity
        local pts = {pos}
        local bounces = 0
        local dt = 1 / 40
        for _ = 1, 160 do
            -- Midpoint-style integration reduces the visible arc error versus a single Euler step.
            local nextVel = vel - Vector3.new(0, grav * dt, 0)
            local step = (vel + nextVel) * (0.5 * dt)
            if step.Magnitude < 1e-5 then break end

            local hit = workspace:Raycast(pos, step, rp)
            if hit then
                local normal = hit.Normal
                pos = hit.Position + normal * 0.05
                pts[#pts + 1] = pos
                bounces = bounces + 1
                if bounces >= 3 then break end

                -- Reflect the impact velocity and apply damping; avoid reflecting into the surface.
                local impactVel = nextVel
                local intoSurface = impactVel:Dot(normal)
                if intoSurface < 0 then
                    impactVel = impactVel - 2 * intoSurface * normal
                end
                vel = impactVel * 0.45
            else
                pos = pos + step
                vel = nextVel
                pts[#pts + 1] = pos
            end

            if #pts >= SEG + 1 then break end
        end
        local last
        for k = 1, SEG do
            local a, b = pts[k], pts[k + 1]
            local l = lines[k]
            local okD = false
            if a and b and l then
                local s1, o1 = c:WorldToViewportPoint(a)
                local s2, o2 = c:WorldToViewportPoint(b)
                if o1 and o2 and s1.Z > 0 and s2.Z > 0 then
                    local col = acc():Lerp(Color3.fromRGB(255, 80, 80), k / SEG)
                    pcall(function() l.From, l.To, l.Color, l.Visible = Vector2.new(s1.X, s1.Y), Vector2.new(s2.X, s2.Y), col, true end)
                    okD = true
                    last = s2
                end
            end
            if not okD and l then pcall(function() l.Visible = false end) end
        end
        if ring then
            if last then pcall(function() ring.Position, ring.Visible = Vector2.new(last.X, last.Y), true end)
            else pcall(function() ring.Visible = false end) end
        end
    end)
end

-- watermark: zenith | fps | ping | ram | time, same look as the menu
do
    local Stats = game:GetService("Stats")
    local wm = new("Frame", {Position = UDim2.new(0, 14, 0, 58), Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.5, BorderSizePixel = 0, Visible = false, Active = true}, gui)
    do
        local dragging, ds, sp
        wm.InputBegan:Connect(function(i)
ident()
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging, ds, sp = true, i.Position, wm.Position
            end
        end)
        connect(UIS.InputChanged, function(i)
ident()
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                wm.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        connect(UIS.InputEnded, function(i)
ident()
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end
    round(wm, 8)
    new("UIStroke", {Color = T.line, Transparency = 0.88, Thickness = 1}, wm)
    new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, wm)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder}, wm)
    new("TextLabel", {Text = "zenith", Font = Enum.Font.Michroma, TextSize = 12, TextColor3 = T.text, BackgroundTransparency = 1,
        Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 0}, wm)
    local vals = {}
    local wmIcons = {}
    for k, it in ipairs({{"esp", "eye"}, {"fps", "bolt"}, {"ping", "signal"}, {"ram", "chip"}, {"time", "clock"}}) do
        local cell = new("Frame", {Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = k}, wm)
        new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), VerticalAlignment = Enum.VerticalAlignment.Center}, cell)
        local ic, icParts = glyph(cell, it[2], acc())
        ic.LayoutOrder = 1
        wmIcons[#wmIcons + 1] = icParts
        vals[it[1]] = new("TextLabel", {Text = "-", Font = FONT_B, TextSize = 12, TextColor3 = T.text, BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2}, cell)
    end
    local frames, acc0 = 0, 0
    connect(RunService.RenderStepped, function(dt)
ident()
        frames = frames + 1
        acc0 = acc0 + dt
    end)
    task.spawn(function()
ident()
        while running do
            wm.Visible = CFG.watermark == true
            if wm.Visible then
                if acc0 > 0 then vals.fps.Text = tostring(math.floor(frames / acc0 + 0.5)) end
                frames, acc0 = 0, 0
                local ping = 0
                pcall(function() ping = lp:GetNetworkPing() * 1000 end)
                vals.ping.Text = math.floor(ping + 0.5) .. "ms"
                local mb = 0
                pcall(function() mb = Stats:GetTotalMemoryUsageMb() end)
                vals.ram.Text = (mb >= 1024) and string.format("%.1fgb", mb / 1024) or (math.floor(mb) .. "mb")
                vals.time.Text = os.date("%H:%M")
                local n = 0
                for _, it in ipairs(S.models or {}) do if it[2] then n = n + 1 end end
                vals.esp.Text = tostring(n)
                local a = acc()
                wm.BackgroundColor3 = T.bg
                for _, parts in ipairs(wmIcons) do
                    for _, pp in ipairs(parts or {}) do
                        pcall(function()
                            if pp[2] == "stroke" then pp[1].Color = a else pp[1].BackgroundColor3 = a end
                        end)
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

do
    local panel = new("Frame", {Position = UDim2.new(1, -150, 0.3, 0), Size = UDim2.fromOffset(136, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Active = true}, gui)
    new("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, panel)
    local grip = new("TextLabel", {Text = "binds", Font = FONT_B, TextSize = 10, TextColor3 = T.sub, BackgroundColor3 = T.bg, BackgroundTransparency = 0.4,
        Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 0, Visible = false}, panel)
    round(grip, 4)
    local buttons = {}
    local function paint(b, key)
        local on = CFG[key] == true
        b.BackgroundColor3 = on and acc() or T.bg
        b.BackgroundTransparency = on and 0.15 or 0.35
        b.TextColor3 = on and Color3.fromRGB(12, 12, 14) or T.text
    end
    S.mbSync = function()
        local n = 0
        for key, b in pairs(buttons) do
            if not CFG.mBinds[key] then b:Destroy() buttons[key] = nil end
        end
        for key in pairs(CFG.mBinds) do
            n = n + 1
            if not buttons[key] then
                local b = new("TextButton", {Text = (S.labels and S.labels[key]) or key, Font = FONT_B, TextSize = 12, AutoButtonColor = false,
                    Size = UDim2.new(1, 0, 0, 34), LayoutOrder = n, BorderSizePixel = 0}, panel)
                round(b, 8)
                new("UIStroke", {Color = T.line, Transparency = 0.8}, b)
                b.Activated:Connect(function()
                    CFG[key] = not CFG[key]
                    save()
                    for _, r in ipairs(refreshers) do pcall(r) end
                    if S.onToggle then pcall(S.onToggle, key) end
                    paint(b, key)
                end)
                buttons[key] = b
            end
            paint(buttons[key], key)
        end
        grip.Visible = n > 0
    end
    S.mbSync()
    -- the "binds" strip on top moves the whole panel
    local dragging, ds, sp
    grip.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging, ds, sp = true, i.Position, panel.Position end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - ds
            panel.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    task.spawn(function()
        while running do
            for key, b in pairs(buttons) do pcall(paint, b, key) end
            task.wait(0.3)
        end
    end)
end

-- pressing a bound key flips the function
connect(UIS.InputBegan, function(i, gpe)
ident()
    if gpe or bindListening or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    for key, code in pairs(CFG.binds) do
        if code == i.KeyCode.Name and type(CFG[key]) == "boolean" then
            CFG[key] = not CFG[key]
            local info = ICON_OF[key]
            if info and info.render then info.render(true) end
            save()
        end
    end
end)

-- keybind list: what is bound, with its icon, lit when on
do
    local list = new("Frame", {Position = UDim2.new(0, 14, 0.38, 0), Size = UDim2.fromOffset(190, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.bg, BackgroundTransparency = 0.5, BorderSizePixel = 0, Visible = false, Active = true}, gui)
    round(list, 8)
    new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, list)
    new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, list)
    local headRow = new("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = -1, Name = "Head"}, list)
    local hic = glyph(headRow, "key", T.text)
    hic.Position = UDim2.new(0, 0, 0.5, -8)
    new("TextLabel", {Text = "Keybinds list", Font = FONT_B, TextSize = 12, TextColor3 = T.text, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -22, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, headRow)
    new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.line,
        BackgroundTransparency = 0.85, BorderSizePixel = 0}, headRow)
    local sig = ""
    task.spawn(function()
ident()
        while running do
            list.Visible = CFG.bindList == true
            if CFG.bindList then
                local rows = {}
                for key, code in pairs(CFG.binds) do
                    if ICON_OF[key] then rows[#rows + 1] = {key = key, code = code, on = CFG[key] == true} end
                end
                table.sort(rows, function(a, b) return ICON_OF[a.key][1] < ICON_OF[b.key][1] end)
                local s2 = CFG.accent
                for _, r in ipairs(rows) do s2 = s2 .. r.key .. r.code .. tostring(r.on) .. "|" end
                if s2 ~= sig then
                    sig = s2
                    for _, ch in ipairs(list:GetChildren()) do if ch:IsA("Frame") and ch.Name ~= "Head" then ch:Destroy() end end
                    if #rows == 0 then
                        local e = new("Frame", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1}, list)
                        new("TextLabel", {Text = "no binds", Font = FONT, TextSize = 11, TextColor3 = T.sub, BackgroundTransparency = 1,
                            Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left}, e)
                    end
                    for i2, r in ipairs(rows) do
                        local col = r.on and acc() or T.sub
                        list.BackgroundColor3 = T.bg
                        local fr = new("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = i2}, list)
                        local ic = glyph(fr, ICON_OF[r.key][2] or "key", col)
                        ic.Position = UDim2.new(0, 0, 0.5, -8)
                        new("TextLabel", {Text = ICON_OF[r.key][1], Font = FONT, TextSize = 12, TextColor3 = r.on and T.text or T.sub,
                            BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -70, 1, 0),
                            TextXAlignment = Enum.TextXAlignment.Left}, fr)
                        new("TextLabel", {Text = r.code, Font = FONT_B, TextSize = 10, TextColor3 = col, BackgroundTransparency = 1,
                            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 46, 1, 0),
                            TextXAlignment = Enum.TextXAlignment.Right}, fr)
                    end
                end
            end
            task.wait(0.25)
        end
    end)
end

-- drag by the header
do
    local dragging, start, startPos
    head.InputBegan:Connect(function(i)
ident()
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, start, startPos = true, i.Position, win.Position
        end
    end)
    connect(UIS.InputChanged, function(i)
ident()
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    connect(UIS.InputEnded, function(i)
ident()
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

-- open / close: small round button + RightShift
local opener = new("TextButton", {Text = "Z", Font = Enum.Font.Michroma, TextSize = 16, TextColor3 = T.text, AutoButtonColor = false,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 40, 0.3, 0), Size = UDim2.fromOffset(42, 42),
    BackgroundColor3 = T.bg, BackgroundTransparency = 0.5, BorderSizePixel = 0}, gui)
round(opener, 21)
local function setOpen(v)
    win.Visible = v
end
hide.Activated:Connect(function() setOpen(false) end)
do
    local down, start, startPos, moved = false, nil, nil, 0
    opener.InputBegan:Connect(function(i)
ident()
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            down, start, startPos, moved = true, i.Position, opener.Position, 0
        end
    end)
    connect(UIS.InputChanged, function(i)
ident()
        if down and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            moved = math.max(moved, d.Magnitude)
            if moved > 8 then
                opener.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
    connect(UIS.InputEnded, function(i)
ident()
        if down and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            down = false
            if moved <= 8 then setOpen(not win.Visible) end
        end
    end)
end
connect(UIS.InputBegan, function(i, gpe)
ident()
    if not gpe and i.KeyCode == Enum.KeyCode.RightShift then setOpen(not win.Visible) end
end)

------------------------------------------------------------------ unload
genv.ZenithBS2 = function()
    running = false
    S.on, S.target = false, nil
    CFG.noRecoil, CFG.noSpread, CFG.fastReload, CFG.fireRateOn = false, false, false, false
    for tbl, keys in pairs(saved) do
        for key, v in pairs(keys) do
            writable(tbl)
            pcall(rawset, tbl, key, v)
        end
    end
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2Aim") end)
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2Recoil") end)
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2TP") end)
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2Flash") end)
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2World") end)
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2VM") end)
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2Traj") end)
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2Mark") end)
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2Model") end)
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2Follow") end)
    pcall(function() if S.attHookOff then S.attHookOff() end end)
    pcall(function() game:GetService("ContextActionService"):UnbindAction("ZenithBS2PreAim") end)
    pcall(function() if S.fakeHead then S.fakeHead:Destroy() end end)
    pcall(function() if S.tracerFolder then S.tracerFolder:Destroy() end end)
    pcall(function() if S.autoFireOff then S.autoFireOff() end end)
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2AAShow") end)
    pcall(function() RunService:UnbindFromRenderStep("ZenithBS2AAShowBack") end)
    pcall(function() if S.moveOff then S.moveOff() end end)
    pcall(function() if S.hitGui then S.hitGui:Destroy() end end)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    for _, d in ipairs(draws) do dropDrawing(d) end
    S.unloading = true
    pcall(function() holder:Destroy() end)
    pcall(function() if S.espGui then S.espGui:Destroy() end end)
    pcall(function() if S.lineGui then S.lineGui:Destroy() end end)
    pcall(function() ringGui:Destroy() end)
    pcall(function() gui:Destroy() end)
    genv.ZenithBS2 = nil
end


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Http = game:GetService("HttpService")
local lp = Players.LocalPlayer

local function isCB()
    if game.PlaceId == 301549746 then return true end
    local ok, ev = pcall(function() return RS:WaitForChild("Events", 5) end)
    return ok and ev ~= nil and ev:FindFirstChild("HitPart") ~= nil
end
if not isCB() then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Zenith | Counter Blox", Text = "This script only works in Counter Blox", Duration = 6})
    end)
    return
end

do
    local API = "https://summer-forest-32d0.fimoz587.workers.dev"
    local GAME = "counterblox"
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

    local passed = false
    pcall(function()
        if isfile and isfile(KFILE) then
            local data = readfile(KFILE)
            local key, last, tok = string.match(data, "([^|]+)|([^|]+)|([^|]+)")
            if key then
                local ok, _, kleft, offline = ask(norm(key))
                if ok then
                    passed = true
                    pcall(function() local g = (getgenv and getgenv()) or _G g.ZenithKeyLeft, g.ZenithKeyAt = kleft, os.time() end)
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
                pcall(function() local g = (getgenv and getgenv()) or _G g.ZenithKeyLeft, g.ZenithKeyAt = left, os.time() end)
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

local genv = (getgenv and getgenv()) or _G
if genv.ZenithCB then pcall(genv.ZenithCB) end
local running = true
local conns = {}
local function connect(sig, fn) local c = sig:Connect(fn) conns[#conns + 1] = c return c end

local CFG = {

    silent = true, silentFov = 90, silentShowFov = true, visCheck = true, teamCheck = true, autoWall = false, minDmg = 20, mpScale = 50,
    mpHead = true, mpNeck = false, mpChest = true, mpLArm = false, mpRArm = false, mpLLeg = false, mpRLeg = false,

    aimbot = false, aimFov = 90, aimSmooth = 6, aimPart = "Head", aimWall = true, aimTeam = true, aimShowFov = true,

    esp = true, box = true, boxStyle = "Corner", name = true, avatar = true, health = true, dist = true, weapon = true, weaponIcon = true,
    tracers = false, skeleton = false, espTeam = false, espCol = "Red", teamCol = "Blue",
    gESP = true, gTracer = false, gChams = true, gIcon = true,

    chams = false, chamsStyle = "Glow", chamsCol = "Red", chamsFill = 0.55, chamsOutline = 0.1, chamsMode = "Walls",
    selfChams = false, weaponChams = false, gloveChams = false, myStyle = "ForceField", myCol = "Purple", wpnCol = "Mint", gloveCol = "Pink",

    hitNotify = true, killNotify = true,

    aa = false, aaYaw = "Spin", aaPitch = "Down", aaSpeed = 20, aaAir = false, aaAirSpeed = 30, aaAirPitch = "None",
    bhop = false, bhopSpeed = 26, third = false, thirdDist = 10,
    accent = "Black", hpPos = "Bar", menuBg = "Geometry",
    skyOn = false, sky = "", skyId = "", fullbright = false, cfgName = "",
    wm = true, wmUser = true, wmFps = true, wmPing = true, wmRam = true, wmGb = false, wmTime = true, wmSub = true,
    binds = {}, bindList = true,
    aaJit = false, aaJitRange = 60, aaJitSpeed = 12, aaManual = "Back", aaKeyL = "Left", aaKeyR = "Right", aaKeyB = "Down", aaKeyF = "Up",
    chamsHealth = false, worldFov = false, fovValue = 90, gTrail = true,
    tracer = false, tracerType = "Neon", tracerCol = "Mint", tracerTime = 0.8,
}
local DIR, FILE = "ZenithCB", "ZenithCB/config3.json"
pcall(function()
    if isfile and isfile(FILE) then
        for k, v in pairs(Http:JSONDecode(readfile(FILE))) do
            if CFG[k] ~= nil and type(CFG[k]) == type(v) then CFG[k] = v end
        end
    end
end)
local function save()
    pcall(function()
        if makefolder and not isfolder(DIR) then makefolder(DIR) end
        writefile(FILE, Http:JSONEncode(CFG))
    end)
end
local PAL = {
    Red = Color3.fromRGB(255, 80, 80), Amber = Color3.fromRGB(255, 190, 80), Green = Color3.fromRGB(110, 230, 120),
    Mint = Color3.fromRGB(110, 230, 190), Blue = Color3.fromRGB(90, 160, 255), Purple = Color3.fromRGB(165, 110, 255),
    Pink = Color3.fromRGB(255, 110, 190), White = Color3.fromRGB(240, 240, 245), Black = Color3.fromRGB(226, 226, 232),
}
local PAL_ORDER = {"Black", "Red", "Amber", "Green", "Mint", "Blue", "Purple", "Pink", "White"}
local function col(name) return PAL[name] or PAL.Red end
local function acc() return col(CFG.accent) end

local cam = workspace.CurrentCamera
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local enemyOf, seen, pick, wallCount

local function angleTo(pos)
    local d = pos - cam.CFrame.Position
    if d.Magnitude < 0.01 then return 0 end
    return math.deg(math.acos(math.clamp(d.Unit:Dot(cam.CFrame.LookVector), -1, 1)))
end
do

    local function status(p, name)
        local st = p:FindFirstChild("Status")
        local v = st and st:FindFirstChild(name)
        return v and v.Value
    end
    enemyOf = function(p, teamChk)
        if p == lp then return false end
        local team = status(p, "Team")
        if team == "Spectator" or status(p, "Alive") == false then return false end
        if not teamChk then return true end
        local gt = RS:FindFirstChild("gametype")
        if gt and gt.Value == "deathmatch" then return true end
        local mine = status(lp, "Team")
        if team ~= nil and mine ~= nil then return team ~= mine end
        if p.Team == nil or lp.Team == nil then return true end
        return p.Team ~= lp.Team
    end

    local baseIg, baseAt, baseChar = {}, 0, nil
    local function baseIgnore()
        local now = tick()
        if now - baseAt > 0.5 or baseChar ~= lp.Character then
            baseAt, baseChar = now, lp.Character
            local l = {cam}
            if lp.Character then l[#l + 1] = lp.Character end
            for _, n in ipairs({"Debris", "Ray_Ignore"}) do
                local f = workspace:FindFirstChild(n)
                if f then l[#l + 1] = f end
            end
            local map = workspace:FindFirstChild("Map")
            if map then
                for _, n in ipairs({"Clips", "SpawnPoints"}) do
                    local f = map:FindFirstChild(n)
                    if f then l[#l + 1] = f end
                end
            end
            baseIg = l
        end
        return baseIg
    end
    seen = function(part, ch, pos)
        local base = baseIgnore()
        local ig = table.move(base, 1, #base, 1, {})
        local o = cam.CFrame.Position
        for _ = 1, 8 do
            rp.FilterDescendantsInstances = ig
            local hit = workspace:Raycast(o, (pos or part.Position) - o, rp)
            if not hit then return true end
            local inst = hit.Instance
            if inst:IsDescendantOf(ch) then return true end
            local m = inst:FindFirstAncestorOfClass("Model")
            local body = m and m ~= ch and m:FindFirstChildOfClass("Humanoid") ~= nil
            if body then
                ig[#ig + 1] = m
            elseif inst.Transparency >= 1 or not inst.CanCollide or inst.Name == "Glass" or inst.Name == "Cardboard" or inst.Name == "Grate" then
                ig[#ig + 1] = inst
            else
                return false
            end
        end
        return false
    end

    wallCount = function(pos, ch)
        local base = baseIgnore()
        local ig = table.move(base, 1, #base, 1, {})
        local o = cam.CFrame.Position
        local n = 0
        for _ = 1, 10 do
            rp.FilterDescendantsInstances = ig
            local hit = workspace:Raycast(o, pos - o, rp)
            if not hit then return n end
            local inst = hit.Instance
            if inst:IsDescendantOf(ch) then return n end
            local m = inst:FindFirstAncestorOfClass("Model")
            if m and m ~= ch and m:FindFirstChildOfClass("Humanoid") then
                ig[#ig + 1] = m
            elseif inst.Transparency >= 1 or not inst.CanCollide or inst.Name == "Glass" or inst.Name == "Cardboard" or inst.Name == "Grate" then
                ig[#ig + 1] = inst
            else
                n = n + 1
                ig[#ig + 1] = inst
            end
        end
        return n
    end

    local SETS = {
        Head = {"HeadHB", "Head"},
        Chest = {"UpperTorso", "Torso"},
        Belly = {"LowerTorso", "Torso", "HumanoidRootPart"},
        Arm = {"RightUpperArm", "LeftUpperArm", "Right Arm", "Left Arm"},
        Leg = {"RightUpperLeg", "LeftUpperLeg", "Right Leg", "Left Leg"},
    }
    local AUTO = {"Head", "Chest", "Belly", "Arm", "Leg"}
    local function partList(ch, which)
        if which == "Torso" then which = "Chest" end
        local sets = (which == "Auto") and AUTO or {SETS[which] and which or "Head"}
        local out = {}
        for _, name in ipairs(sets) do
            local single = name == "Head" or name == "Chest" or name == "Belly"
            for _, n in ipairs(SETS[name]) do
                local p = ch:FindFirstChild(n)
                if p and p:IsA("BasePart") then
                    out[#out + 1] = p
                    if single then break end
                end
            end
        end
        return out
    end
    pick = function(fov, wallCheck, teamChk, which)
        local best, bestA, bestP = nil, fov / 2, nil
        for _, p in ipairs(Players:GetPlayers()) do
            local ch = p.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if ch and hum and hum.Health > 0 and enemyOf(p, teamChk) then
                for _, part in ipairs(partList(ch, which)) do
                    local a = angleTo(part.Position)
                    if a <= bestA and (not wallCheck or seen(part, ch)) then
                        best, bestA, bestP = part, a, p
                        break
                    end
                end
            end
        end
        return best, bestP
    end
end
local function myState()
    local ch = lp.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    return ch, hum, ch and ch:FindFirstChild("HumanoidRootPart")
end
local function myWeapon()
    local ch = lp.Character
    local v = ch and ch:FindFirstChild("EquippedTool")
    if v and v:IsA("StringValue") and v.Value ~= "" then return v.Value end
    local t = ch and ch:FindFirstChildOfClass("Tool")
    return t and t.Name or "?"
end

local target, targetPlr, targetPos
local shot = nil

local HB = {
    {"mpHead", {"HeadHB", "Head"}, "head"}, {"mpNeck", {"HeadHB", "Head"}, "neck"}, {"mpChest", {"UpperTorso", "Torso"}, "body"},
    {"mpLArm", {"LeftUpperArm", "Left Arm"}, "limb"}, {"mpRArm", {"RightUpperArm", "Right Arm"}, "limb"},
    {"mpLLeg", {"LeftUpperLeg", "Left Leg"}, "limb"}, {"mpRLeg", {"RightUpperLeg", "Right Leg"}, "limb"},
}
local HB_MULT = {head = 4, neck = 4, body = 1, limb = 0.75}
local function pointsOf(part, kind, k)
    local base = part.CFrame
    if kind == "neck" then base = base * CFrame.new(0, -part.Size.Y * 0.4, 0) end
    local pts = {base.Position}
    if k <= 0 then return pts end
    local H = part.Size / 2 * k
    local offs = {Vector3.new(H.X, 0, 0), Vector3.new(-H.X, 0, 0), Vector3.new(0, 0, H.Z), Vector3.new(0, 0, -H.Z)}
    if kind ~= "neck" then offs[#offs + 1] = Vector3.new(0, H.Y, 0) offs[#offs + 1] = Vector3.new(0, -H.Y, 0) end
    for _, o in ipairs(offs) do pts[#pts + 1] = (base * CFrame.new(o)).Position end
    return pts
end

local function estDmg(kind, pt, ch)
    local wf = RS:FindFirstChild("Weapons")
    local w = wf and wf:FindFirstChild(myWeapon())
    local function val(n, d) local v = w and w:FindFirstChild(n) return v and tonumber(v.Value) or d end
    local dmg = val("DMG", 30) * HB_MULT[kind]
    dmg = dmg * (val("RangeModifier", 100) / 100) ^ ((pt - cam.CFrame.Position).Magnitude / 500)
    local n = wallCount(pt, ch)
    if n > 0 then dmg = dmg * math.clamp(val("Penetration", 100) / 200, 0.05, 0.95) ^ n end
    return dmg
end
local pickAt = 0
local function silentPick()
    if tick() - pickAt < 0.04 then return target, targetPlr, targetPos end
    pickAt = tick()
    local fov, k = CFG.silentFov / 2, CFG.mpScale / 100
    local bp, bplr, bpos, ba = nil, nil, nil, fov
    for _, p in ipairs(Players:GetPlayers()) do
        local ch = p.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if ch and hum and hum.Health > 0 and enemyOf(p, CFG.teamCheck) then
            local found
            for _, hb in ipairs(HB) do
                if CFG[hb[1]] and not found then
                    local part
                    for _, n in ipairs(hb[2]) do
                        local q = ch:FindFirstChild(n)
                        if q and q:IsA("BasePart") then part = q break end
                    end
                    if part then
                        for _, pt in ipairs(pointsOf(part, hb[3], k)) do
                            local a = angleTo(pt)
                            if a <= fov and (not CFG.visCheck or seen(part, ch, pt)) and (not CFG.autoWall or estDmg(hb[3], pt, ch) >= CFG.minDmg) then
                                found = {part, pt, a}
                                break
                            end
                        end
                    end
                end
            end
            if found and found[3] <= ba then bp, bplr, bpos, ba = found[1], p, found[2], found[3] end
        end
    end
    return bp, bplr, bpos
end

local function onRayHit(part, isFollow)
    if not (part and typeof(part) == "Instance") then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and part:IsDescendantOf(p.Character) and enemyOf(p, true) then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local _, mh, mr = myState()
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            shot = {
                p = p, hum = hum, hp = hum and hum.Health or 100, part = part.Name, at = tick(), pos = part.Position,
                wall = isFollow == true, jump = mh and mh.FloorMaterial == Enum.Material.Air,
                dist = (mr and r) and math.floor((r.Position - mr.Position).Magnitude) or 0, weapon = myWeapon(),
            }
            return
        end
    end
end
genv.ZenithCBHit = onRayHit

if hookmetamethod and getnamecallmethod and checkcaller and newcclosure and not genv.ZenithCBHooked5 then
    genv.ZenithCBHooked5 = true
    local HIT_REMOTES = {HitPart = true, HitParl = true}
    local function unscramble(v)
        return Vector3.new((v.X / 16 - 17854) / 13 + 156325, (v.Y + 142657) / 7 - 64000, (v.Z / 6 + 47000) / 9)
    end
    local old5
    old5 = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if not checkcaller() and typeof(self) == "Instance" and HIT_REMOTES[self.Name] and getnamecallmethod() == "FireServer" then
            local fn = genv.ZenithCBShotAt
            if fn then
                local args = {...}
                local part = typeof(args[1]) == "Instance" and args[1] or nil
                local pos
                if self.Name == "HitParl" and typeof(args[2]) == "Vector3" then
                    pos = unscramble(args[2])
                else
                    for _, a in ipairs(args) do
                        if typeof(a) == "Vector3" then pos = a break end
                        if typeof(a) == "CFrame" then pos = a.Position break end
                    end
                end

                local c = workspace.CurrentCamera
                if part and part:IsA("BasePart") and (not pos or pos ~= pos or (c and (pos - c.CFrame.Position).Magnitude > 4000)) then
                    pos = part.Position
                end
                if part and genv.ZenithCBHit then task.spawn(pcall, genv.ZenithCBHit, part, false) end
                if pos then task.spawn(fn, pos) end
            end
        end
        return old5(self, ...)
    end))
end

local function scramble(v)
    return Vector3.new(((v.X - 156325) * 13 + 17854) * 16, (v.Y + 64000) * 7 - 142657, (v.Z * 9 - 47000) * 6)
end
local redirectedAt = 0
local function dbgS(...) if genv.ZenithDebug then print("[zenith silent]", ...) end end
genv.ZenithCBRedirect = function(args)
    local t, pos = target, targetPos
    if not (running and CFG.silent and t and t.Parent and pos) then return nil end
    if typeof(args[1]) ~= "Instance" then return nil end
    dbgS("redirect", args[1].Name, "->", t.Name)
    args[1] = t
    if typeof(args[2]) == "Vector3" then args[2] = scramble(pos) end
    redirectedAt = tick()
    return args
end
local function fireOwn(part, pos)
    local ev = RS:FindFirstChild("Events")
    local hp = ev and ev:FindFirstChild("HitParl")
    local ch = lp.Character
    local gun = ch and ch:FindFirstChild("Gun")
    local name = myWeapon()
    local wf = RS:FindFirstChild("Weapons")
    local w = wf and wf:FindFirstChild(name)
    if not (hp and gun and w) then dbgS("no remote / Gun / weapon", hp, gun, name) return end
    local rv = w:FindFirstChild("Range")
    local _, hum = myState()
    local air = hum ~= nil and hum:GetState() == Enum.HumanoidStateType.Freefall
    local args = {part, scramble(pos), name, rv and rv.Value or 8192, gun, nil, 1, false, 0, cam.CFrame.Position,
        workspace:GetServerTimeNow(), Vector3.zero, false, false, false, air, true}
    dbgS("own report", name, part.Name)
    pcall(function() hp:FireServer(table.unpack(args, 1, 32)) end)
    if genv.ZenithCBShotAt then pcall(genv.ZenithCBShotAt, pos) end
    if genv.ZenithCBHit then pcall(genv.ZenithCBHit, part, false) end
end
genv.ZenithCBShotFired = function()
    local t, pos = target, targetPos
    if not (running and CFG.silent and t and t.Parent and pos) then return end
    local at = tick()
    dbgS("shot seen")
    task.delay(0.07, function()
        if not running or redirectedAt >= at - 0.01 then return end
        fireOwn(t, pos)
    end)
end
if hookmetamethod and getnamecallmethod and checkcaller and newcclosure and not genv.ZenithCBHooked7 then
    genv.ZenithCBHooked7 = true
    local old7
    old7 = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if not checkcaller() and typeof(self) == "Instance" and getnamecallmethod() == "FireServer" then
            local nm = self.Name
            if nm == "HitParl" then
                local f = genv.ZenithCBRedirect
                if f then
                    local n = select("#", ...)
                    local ok, res = pcall(f, {...})
                    if ok and res then return old7(self, table.unpack(res, 1, n)) end
                end
            elseif nm == "ReplicateShot" then
                local f = genv.ZenithCBShotFired
                if f then task.spawn(pcall, f) end
            end
        end
        return old7(self, ...)
    end))
end

local aimT
RunService:BindToRenderStep("ZenithCBAim", Enum.RenderPriority.Camera.Value + 2, function()
    if not (running and CFG.aimbot) then aimT = nil return end
    aimT = pick(CFG.aimFov, CFG.aimWall, CFG.aimTeam, CFG.aimPart)
    if not aimT then return end
    local c = workspace.CurrentCamera
    local goal = CFrame.lookAt(c.CFrame.Position, aimT.Position)
    c.CFrame = c.CFrame:Lerp(goal, 1 / math.max(CFG.aimSmooth, 1))
end)

local aa = {spin = 0, jitAt = 0, jitSide = false, wasOn = false, lastPitchAt = 0}
local function wrapA(a) return (a + math.pi) % (2 * math.pi) - math.pi end

local function jitterSign()
    if tick() - aa.jitAt >= 1 / math.max(CFG.aaJitSpeed, 1) then
        aa.jitAt, aa.jitSide = tick(), not aa.jitSide
    end
    return aa.jitSide and 1 or -1
end
local MANUAL = {Front = 0, Left = math.pi / 2, Right = -math.pi / 2, Back = math.pi}
local function aaPitchValue()
    if not (running and CFG.aa) then return nil end
    local _, hum = myState()
    local air = hum and hum.FloorMaterial == Enum.Material.Air
    local pm = (CFG.aaAir and air) and CFG.aaAirPitch or CFG.aaPitch
    if pm == "Down" then return -1.5
    elseif pm == "Up" then return 1.5
    elseif pm == "Jitter" then return jitterSign() > 0 and 1.5 or -1.5 end
    return nil
end
genv.ZenithCBPitch = aaPitchValue
if hookmetamethod and getnamecallmethod and checkcaller and newcclosure and not genv.ZenithCBHooked2 then
    genv.ZenithCBHooked2 = true
    local old2
    old2 = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if not checkcaller() and typeof(self) == "Instance" and self.Name == "ControlTurn" and getnamecallmethod() == "FireServer" then
            local fn = genv.ZenithCBPitch
            local v = fn and fn()
            if v then return old2(self, v, select(2, ...)) end
        end
        return old2(self, ...)
    end))
end
local function aaStep(dt)
    if not running then return end
    local _, hum, hrp = myState()
    if not (hum and hrp and hum.Health > 0) then return end
    if not CFG.aa then
        if aa.wasOn then
            aa.wasOn = false
            hum.AutoRotate = true
            if aa.neck and aa.neck.Parent and aa.neckC0 then aa.neck.C0 = aa.neckC0 end
            aa.neck, aa.neckC0 = nil, nil
        end
        return
    end
    aa.wasOn = true
    hum.AutoRotate = false
    local look = cam.CFrame.LookVector
    local yaw0 = math.atan2(-look.X, -look.Z)
    local air = hum.FloorMaterial == Enum.Material.Air
    local mode, spd = CFG.aaYaw, CFG.aaSpeed
    if CFG.aaAir and air then mode, spd = "Spin", CFG.aaAirSpeed end
    local yaw
    if mode == "Spin" then
        aa.spin = wrapA(aa.spin + math.rad(spd * 6) * 60 * (dt or 1 / 60))
        yaw = yaw0 + aa.spin
    else
        local off = math.pi
        if mode == "Side" then off = math.pi / 2
        elseif mode == "Manual" then off = MANUAL[CFG.aaManual] or math.pi end
        local jit = (mode == "Jitter" or CFG.aaJit) and jitterSign() * math.rad(CFG.aaJitRange) or 0
        yaw = yaw0 + off + jit
    end
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
    local pm = (CFG.aaAir and air) and CFG.aaAirPitch or CFG.aaPitch
    local tilt = 0
    if pm == "Down" then tilt = -math.rad(80)
    elseif pm == "Up" then tilt = math.rad(70)
    elseif pm == "Jitter" then tilt = jitterSign() > 0 and -math.rad(80) or math.rad(70) end
    local ch = hrp.Parent
    local neck
    for _, d in ipairs(ch:GetDescendants()) do
        if d:IsA("Motor6D") and d.Name == "Neck" then neck = d break end
    end
    if neck then
        if not aa.neckC0 or aa.neck ~= neck then aa.neck, aa.neckC0 = neck, neck.C0 end
        neck.C0 = aa.neckC0 * CFrame.Angles(tilt, 0, 0)
    end
    if tick() - aa.lastPitchAt > 0.1 then
        aa.lastPitchAt = tick()
        local v = aaPitchValue()
        local ev = RS:FindFirstChild("Events")
        local ct = ev and ev:FindFirstChild("ControlTurn")
        if v and ct then pcall(function() ct:FireServer(v) end) end
    end
end
connect(RunService.Heartbeat, aaStep)
RunService:BindToRenderStep("ZenithCBAA", Enum.RenderPriority.Last.Value + 2, function(dt) pcall(aaStep, dt) end)

connect(UIS.JumpRequest, function() genv.ZenithCBJumpAt = tick() end)
connect(RunService.Heartbeat, function()
    if not (running and CFG.bhop) or UIS:GetFocusedTextBox() then return end
    local _, hum, hrp = myState()
    if not (hum and hrp and hum.Health > 0) then return end
    if not (UIS:IsKeyDown(Enum.KeyCode.Space) or tick() - (genv.ZenithCBJumpAt or 0) < 0.2) then return end
    if hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    elseif hum.MoveDirection.Magnitude > 0.1 and CFG.bhopSpeed > 16 then
        local v = hrp.AssemblyLinearVelocity
        local dir = hum.MoveDirection.Unit
        local hv = Vector3.new(v.X, 0, v.Z)
        local nv = hv:Lerp(dir * math.max(CFG.bhopSpeed, hv.Magnitude), 0.4)
        hrp.AssemblyLinearVelocity = Vector3.new(nv.X, v.Y, nv.Z)
    end
end)

do
    local shown, hiddenVm, was = {}, {}, false
    local function giveBack()
        for p, v in pairs(shown) do if p.Parent then pcall(function() p.LocalTransparencyModifier = v end) end end
        for p, v in pairs(hiddenVm) do if p.Parent then pcall(function() p.LocalTransparencyModifier = v end) end end
        shown, hiddenVm = {}, {}
    end
    RunService:BindToRenderStep("ZenithCBTP", Enum.RenderPriority.Last.Value + 5, function()
        if not running then return end
        local ch, _, hrp = myState()
        if not (CFG.third and hrp) then
            if was then was = false giveBack() end
            return
        end
        was = true
        local c = workspace.CurrentCamera
        local base = c.CFrame
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {ch, c}
        local hit = workspace:Raycast(base.Position, base.LookVector * -CFG.thirdDist, params)
        local dist = hit and math.max((hit.Position - base.Position).Magnitude - 0.5, 1) or CFG.thirdDist
        c.CFrame = base * CFrame.new(0, 0, dist)
        for _, d in ipairs(ch:GetDescendants()) do
            if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
                if shown[d] == nil then shown[d] = d.LocalTransparencyModifier end
                d.LocalTransparencyModifier = 0
            end
        end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BasePart") then
                if hiddenVm[d] == nil then hiddenVm[d] = d.LocalTransparencyModifier end
                d.LocalTransparencyModifier = 1
            end
        end
    end)
end

local myPaint = {}
local function styleMat(s)
    if s == "Neon" then return Enum.Material.Neon end
    if s == "Glass" then return Enum.Material.Glass end
    return Enum.Material.ForceField
end
local function paint(part, on, c)
    local st = myPaint[part]
    if on then
        if not st then
            st = {part.Material, part.Color}
            myPaint[part] = st
        end
        part.Material, part.Color = styleMat(CFG.myStyle), c
    elseif st then
        part.Material, part.Color = st[1], st[2]
        myPaint[part] = nil
    end
end
local function isArm(n)
    n = string.lower(n)
    return (string.find(n, "arm", 1, true) or (string.find(n, "hand", 1, true) and not string.find(n, "handle", 1, true))) ~= nil
end
task.spawn(function()
    while running do
        pcall(function()
            local ch = lp.Character
            if ch then
                for _, d in ipairs(ch:GetDescendants()) do
                    if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 then paint(d, CFG.selfChams, col(CFG.myCol)) end
                end
            end
            for _, d in ipairs(workspace.CurrentCamera:GetDescendants()) do
                if d:IsA("BasePart") and d.Transparency < 1 then
                    local n = string.lower(d.Name)
                    local gunName = string.lower(myWeapon())

                    local isGun = false
                    local up = d.Parent
                    while up and up ~= workspace.CurrentCamera do
                        local un = string.lower(up.Name)
                        if un == gunName or un == "gun" or un == "weapon" or un == "model" then isGun = true break end
                        up = up.Parent
                    end
                    if string.find(n, "glove", 1, true) then
                        paint(d, CFG.gloveChams, col(CFG.gloveCol))
                    elseif isGun and not isArm(d.Name) then
                        paint(d, CFG.weaponChams, col(CFG.wpnCol))
                    elseif isArm(d.Name) then
                        paint(d, CFG.gloveChams, col(CFG.gloveCol))
                    else
                        paint(d, CFG.weaponChams, col(CFG.wpnCol))
                    end
                end
            end
            for part in pairs(myPaint) do
                if not part.Parent then myPaint[part] = nil end
            end
        end)
        task.wait(0.25)
    end
    for part, st in pairs(myPaint) do pcall(function() part.Material, part.Color = st[1], st[2] end) end
end)

local Lighting = game:GetService("Lighting")
local SKY_SOURCES = {
    {id = 11320658296, name = "galaxy"},
    {id = 136402262, name = "space"},
    {id = 105189455817751, name = "anime"},
    {id = 102765136165948, pack = true},
}
local skyList, skyLoading, skyRedraw = {}, false, nil
local function skyFrom(id)
    local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
    local out = {}
    if ok and type(objs) == "table" then
        for _, o in ipairs(objs) do
            if o:IsA("Sky") then out[#out + 1] = o end
            for _, d in ipairs(o:GetDescendants()) do if d:IsA("Sky") then out[#out + 1] = d end end
        end
    end
    return out
end
local function loadSkies()
    if skyLoading then return end
    skyLoading = true
    task.spawn(function()
        for _, src in ipairs(SKY_SOURCES) do
            local skies = skyFrom(src.id)
            if src.pack then
                for i, sk in ipairs(skies) do
                    local nm = string.lower(sk.Name ~= "Sky" and sk.Name or (sk.Parent and sk.Parent.Name or ("sky " .. i)))
                    skyList[#skyList + 1] = {key = src.id .. ":" .. i, name = nm, sky = sk}
                end
            elseif skies[1] then
                skyList[#skyList + 1] = {key = tostring(src.id), name = src.name, sky = skies[1]}
            end
            if skyRedraw then pcall(skyRedraw) end
        end
    end)
end

local function customSky(id)
    local skies = skyFrom(id)
    if skies[1] then return skies[1] end
    local s = Instance.new("Sky")
    local img = "rbxthumb://type=Asset&id=" .. id .. "&w=768&h=432"
    for _, f in ipairs({"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}) do s[f] = img end
    s.CelestialBodiesShown = false
    return s
end
local skyHidden, skyMine, skyShown = {}, nil, nil
local function skyOff()
    if skyMine then pcall(function() skyMine:Destroy() end) end
    skyMine = nil
    for sk, parent in pairs(skyHidden) do pcall(function() sk.Parent = parent end) end
    skyHidden, skyShown = {}, nil
end
local function skySet(key)
    if key == skyShown then return end
    local src
    if string.sub(key, 1, 7) == "custom:" then
        src = customSky(string.sub(key, 8))
    else
        for _, it in ipairs(skyList) do if it.key == key then src = it.sky break end end
    end
    if not src then return end
    skyOff()
    for _, x in ipairs(Lighting:GetChildren()) do
        if x:IsA("Sky") then skyHidden[x] = x.Parent x.Parent = nil end
    end
    local ok, cl = pcall(function() src.Archivable = true return src:Clone() end)
    if ok and cl then
        cl.Name = "ZenithSky"
        cl.Parent = Lighting
        skyMine, skyShown = cl, key
    end
end
local lightSaved = {}
task.spawn(function()
    while running do
        pcall(function()
            if CFG.skyOn and CFG.sky ~= "" then skySet(CFG.sky) elseif skyShown then skyOff() end
            if CFG.fullbright then
                for _, k in ipairs({"Brightness", "ClockTime", "GlobalShadows", "Ambient"}) do
                    if lightSaved[k] == nil then lightSaved[k] = Lighting[k] end
                end
                Lighting.Brightness, Lighting.ClockTime, Lighting.GlobalShadows, Lighting.Ambient = 2, 14, false, Color3.fromRGB(180, 180, 180)
            elseif next(lightSaved) then
                for k, v in pairs(lightSaved) do pcall(function() Lighting[k] = v end) end
                lightSaved = {}
            end
        end)
        task.wait(0.5)
    end
    skyOff()
    for k, v in pairs(lightSaved) do pcall(function() Lighting[k] = v end) end
end)

local HAS_DRAW = false
pcall(function()
    local d = Drawing.new("Line")
    if d then
        pcall(function() d.Visible = false end)
        if not pcall(function() d:Remove() end) then pcall(function() d:Destroy() end) end
        HAS_DRAW = true
    end
end)
local draws = {}
local function dRemove(d) if not pcall(function() d:Remove() end) then pcall(function() d:Destroy() end) end end
local function dnew(class, props)
    local ok, d = pcall(Drawing.new, class)
    if not ok or not d then return nil end
    for k, v in pairs(props) do pcall(function() d[k] = v end) end
    draws[#draws + 1] = d
    return d
end
local espGui = Instance.new("ScreenGui")
espGui.Name = "ZenithCBEsp"
espGui.IgnoreGuiInset = true
espGui.ResetOnSpawn = false
espGui.DisplayOrder = 5
pcall(function() espGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not espGui.Parent then espGui.Parent = lp:WaitForChild("PlayerGui") end
local espFolder = Instance.new("Folder")
espFolder.Name = "ZenithCBEsp"
espFolder.Parent = workspace.CurrentCamera
local function mkLine(thick)
    if HAS_DRAW then
        local l = dnew("Line", {Thickness = thick, Visible = false, Transparency = 1, Color = Color3.new(1, 1, 1)})
        if l then return l end
    end
    local f = Instance.new("Frame")
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.BorderSizePixel = 0
    f.Visible = false
    f.Parent = espGui
    local from, to = Vector2.zero, Vector2.zero
    local function upd()
        local d = to - from
        f.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
        f.Size = UDim2.fromOffset(d.Magnitude + 1, thick)
        f.Rotation = math.deg(math.atan2(d.Y, d.X))
    end
    return setmetatable({}, {
        __newindex = function(_, k, v)
            if k == "From" then from = v upd() elseif k == "To" then to = v upd()
            elseif k == "Color" then f.BackgroundColor3 = v elseif k == "Visible" then f.Visible = v
            elseif k == "Transparency" then f.BackgroundTransparency = 1 - v end
        end,
        __index = function(_, k) if k == "Remove" then return function() f:Destroy() end end end,
    })
end
local function mkText(size, c)
    if HAS_DRAW then
        local t = dnew("Text", {Size = size, Center = true, Outline = true, Visible = false, Color = c or Color3.new(1, 1, 1), Font = 2})
        if t then return t end
    end
    local l = Instance.new("TextLabel")
    l.AnchorPoint = Vector2.new(0.5, 0.5)
    l.BackgroundTransparency = 1
    l.Size = UDim2.fromOffset(220, size + 4)
    l.Font = Enum.Font.Code
    l.TextSize = size
    l.TextColor3 = c or Color3.new(1, 1, 1)
    l.TextStrokeTransparency = 0.2
    l.Visible = false
    l.Parent = espGui
    return setmetatable({}, {
        __newindex = function(_, k, v)
            if k == "Text" then l.Text = v elseif k == "Position" then l.Position = UDim2.fromOffset(v.X, v.Y)
            elseif k == "Color" then l.TextColor3 = v elseif k == "Visible" then l.Visible = v end
        end,
        __index = function(_, k) if k == "Remove" then return function() l:Destroy() end end end,
    })
end
local function setL(l, a, b, c) pcall(function() l.From, l.To, l.Color = a, b, c l.Visible = true end) end
local function setT(t, txt, pos, c) pcall(function() t.Text, t.Position = txt, pos if c then t.Color = c end t.Visible = true end) end
local function hideL(l) pcall(function() l.Visible = false end) end

local function weaponOf(ch)
    local v = ch:FindFirstChild("EquippedTool")
    if v and v:IsA("StringValue") and v.Value ~= "" then return v.Value end
    local tool = ch:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end
local iconCache = {}
local function weaponIcon(name)
    if not name then return nil end
    if iconCache[name] ~= nil then return iconCache[name] or nil end
    iconCache[name] = false
    pcall(function()
        local w = RS:FindFirstChild("Weapons")
        local folder = w and (w:FindFirstChild(name) or w:FindFirstChild(name:gsub(" ", "")))
        if not folder then return end
        for _, d in ipairs(folder:GetDescendants()) do
            local img
            if d:IsA("ImageLabel") or d:IsA("ImageButton") then img = d.Image
            elseif d:IsA("Decal") or d:IsA("Texture") then img = d.Texture
            elseif (d:IsA("StringValue") or d:IsA("IntValue") or d:IsA("NumberValue")) and string.find(string.lower(d.Name), "icon", 1, true) then
                img = tostring(d.Value)
                if tonumber(img) then img = "rbxassetid://" .. img end
            end
            if type(img) == "string" and img ~= "" then iconCache[name] = img return end
        end
    end)
    return iconCache[name] or nil
end

local BONES = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local BONES6 = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}
local function build()
    local e = {out = {}, c = {}, s = {}, mat = {}}
    for k = 1, 8 do e.out[k] = mkLine(3) e.c[k] = mkLine(1) end
    for k = 1, 14 do e.s[k] = mkLine(1) end
    e.tr, e.hpb, e.hpf = mkLine(1), mkLine(4), mkLine(2)
    e.nameT = mkText(13)
    e.infoT = mkText(11, Color3.fromRGB(200, 200, 205))
    e.hpT = mkText(10)
    e.hl = Instance.new("Highlight")
    e.hl.Enabled = false
    e.hl.Parent = espFolder

    e.avB = Instance.new("BillboardGui")
    e.avB.Size = UDim2.fromOffset(18, 18)
    e.avB.AlwaysOnTop = true
    e.avB.StudsOffsetWorldSpace = Vector3.new(0, 1.9, 0)
    e.avB.Enabled = false
    e.avB.Parent = espFolder
    e.av = Instance.new("ImageLabel")
    e.av.BackgroundColor3 = Color3.new(0, 0, 0)
    e.av.BackgroundTransparency = 0.3
    e.av.Size = UDim2.fromScale(1, 1)
    e.av.Parent = e.avB
    Instance.new("UICorner", e.av).CornerRadius = UDim.new(1, 0)
    e.wiB = Instance.new("BillboardGui")
    e.wiB.Size = UDim2.fromOffset(46, 18)
    e.wiB.AlwaysOnTop = true
    e.wiB.StudsOffsetWorldSpace = Vector3.new(0, -4.3, 0)
    e.wiB.Enabled = false
    e.wiB.Parent = espFolder
    e.wi = Instance.new("ImageLabel")
    e.wi.BackgroundTransparency = 1
    e.wi.ScaleType = Enum.ScaleType.Fit
    e.wi.Size = UDim2.fromScale(1, 1)
    e.wi.Parent = e.wiB
    return e
end
local POOL, E = {}, {}
for _ = 1, 32 do
    local ok, e = pcall(build)
    if ok then POOL[#POOL + 1] = e end
end
local function unpaint(e)
    for part, st in pairs(e.mat) do if part.Parent then pcall(function() part.Material, part.Color = st[1], st[2] end) end end
    e.mat = {}
end
local function hideLines(e)
    for _, l in ipairs(e.out) do hideL(l) end
    for _, l in ipairs(e.c) do hideL(l) end
    for _, l in ipairs(e.s) do hideL(l) end
    hideL(e.tr) hideL(e.hpb) hideL(e.hpf) hideL(e.nameT) hideL(e.infoT) hideL(e.hpT)
    e.avB.Enabled, e.wiB.Enabled = false, false
end
local function hideAll(e)
    hideLines(e)
    e.hl.Enabled = false
    unpaint(e)
end
local function release(p)
    local e = E[p]
    if not e then return end
    hideAll(e)
    e.hl.Adornee, e.avB.Adornee, e.wiB.Adornee = nil, nil, nil
    E[p] = nil
    POOL[#POOL + 1] = e
end
local function drawOne(p, e)
    local ch = p.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local r = ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
    local isEnemy = enemyOf(p, CFG.teamCheck)
    if not (ch and hum and r and hum.Health > 0) or (not isEnemy and not CFG.espTeam) then hideAll(e) return end
    local c = isEnemy and col(CFG.espCol) or col(CFG.teamCol)
    local cc = isEnemy and col(CFG.chamsCol) or col(CFG.teamCol)
    if CFG.chamsHealth then
        local fr = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        cc = (fr > 0.6) and Color3.fromRGB(90, 235, 110) or (fr > 0.3) and Color3.fromRGB(255, 160, 50) or Color3.fromRGB(255, 60, 60)
    end
    if CFG.chams and CFG.chamsStyle == "Glow" then
        unpaint(e)
        e.hl.Adornee = ch
        e.hl.FillColor, e.hl.OutlineColor = cc, cc
        e.hl.FillTransparency, e.hl.OutlineTransparency = CFG.chamsFill, CFG.chamsOutline
        e.hl.DepthMode = (CFG.chamsMode == "Visible") and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
        e.hl.Enabled = true
    elseif CFG.chams then
        local mat = (CFG.chamsStyle == "ForceField") and Enum.Material.ForceField or Enum.Material.Neon
        for _, d in ipairs(ch:GetDescendants()) do
            if d:IsA("BasePart") and d.Transparency < 1 and d.Name ~= "HumanoidRootPart" then
                if not e.mat[d] then e.mat[d] = {d.Material, d.Color} end
                d.Material, d.Color = mat, cc
            end
        end
        e.hl.Adornee = ch
        e.hl.FillTransparency, e.hl.OutlineTransparency, e.hl.OutlineColor = 1, CFG.chamsOutline, cc
        e.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        e.hl.Enabled = CFG.chamsMode ~= "Visible"
    else
        e.hl.Enabled = false
        unpaint(e)
    end
    if not CFG.esp then hideLines(e) return end
    local head = ch:FindFirstChild("Head") or r
    local lowY
    for _, n in ipairs({"LeftFoot", "RightFoot", "Left Leg", "Right Leg"}) do
        local q = ch:FindFirstChild(n)
        if q and q:IsA("BasePart") then
            local y = q.Position.Y - q.Size.Y / 2
            if not lowY or y < lowY then lowY = y end
        end
    end
    local top, v1 = cam:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y * 0.6, 0))
    local bot, v2 = cam:WorldToViewportPoint(Vector3.new(r.Position.X, lowY or (r.Position.Y - 3), r.Position.Z))
    if not (v1 or v2) or top.Z <= 0 then hideLines(e) return end
    local hgt = math.abs(bot.Y - top.Y)
    local wid = hgt * 0.45
    local mid = cam:WorldToViewportPoint(r.Position)
    local x, y1 = math.floor(mid.X - wid / 2), math.floor(math.min(top.Y, bot.Y))
    local x2, y2 = math.floor(x + wid), math.floor(y1 + hgt)
    local seg
    if CFG.boxStyle == "Full" then
        seg = {{Vector2.new(x, y1), Vector2.new(x2, y1)}, {Vector2.new(x2, y1), Vector2.new(x2, y2)},
            {Vector2.new(x2, y2), Vector2.new(x, y2)}, {Vector2.new(x, y2), Vector2.new(x, y1)}}
    else
        local cl = math.max(math.floor(wid * 0.22), 4)
        seg = {
            {Vector2.new(x, y1), Vector2.new(x + cl, y1)}, {Vector2.new(x, y1), Vector2.new(x, y1 + cl)},
            {Vector2.new(x2, y1), Vector2.new(x2 - cl, y1)}, {Vector2.new(x2, y1), Vector2.new(x2, y1 + cl)},
            {Vector2.new(x, y2), Vector2.new(x + cl, y2)}, {Vector2.new(x, y2), Vector2.new(x, y2 - cl)},
            {Vector2.new(x2, y2), Vector2.new(x2 - cl, y2)}, {Vector2.new(x2, y2), Vector2.new(x2, y2 - cl)},
        }
    end
    for k = 1, 8 do
        local sg = seg[k]
        if CFG.box and sg then setL(e.out[k], sg[1], sg[2], Color3.new(0, 0, 0)) setL(e.c[k], sg[1], sg[2], c)
        else hideL(e.out[k]) hideL(e.c[k]) end
    end
    if CFG.name then setT(e.nameT, p.DisplayName, Vector2.new(mid.X, y1 - 9), Color3.new(1, 1, 1)) else hideL(e.nameT) end
    e.avB.Adornee = head
    e.avB.Enabled = CFG.avatar and CFG.name
    if e.avB.Enabled then
        local img = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=48&h=48"
        if e.av.Image ~= img then e.av.Image = img end
    end
    local _, _, mine = myState()
    local w = CFG.weapon and weaponOf(ch) or nil
    local info = {}
    if w then info[#info + 1] = w end
    if CFG.dist and mine then info[#info + 1] = "[" .. math.floor((r.Position - mine.Position).Magnitude) .. "]" end
    if #info > 0 then setT(e.infoT, table.concat(info, " "), Vector2.new(mid.X, y2 + 9)) else hideL(e.infoT) end
    local icon = (w and CFG.weaponIcon) and weaponIcon(w) or nil
    e.wiB.Adornee = r
    e.wiB.Enabled = icon ~= nil
    if icon and e.wi.Image ~= icon then e.wi.Image = icon end
    local bones = ch:FindFirstChild("UpperTorso") and BONES or BONES6
    local skelCol = Color3.new(1, 1, 1)
    if CFG.skeleton then
        if not e.visAt or tick() - e.visAt > 0.15 then e.visAt, e.vis = tick(), seen(head, ch) end
        skelCol = e.vis and Color3.fromRGB(90, 235, 110) or Color3.fromRGB(255, 60, 60)
    end
    for k = 1, 14 do
        local b = bones[k]
        local okDraw = false
        if CFG.skeleton and b then
            local p1, p2 = ch:FindFirstChild(b[1]), ch:FindFirstChild(b[2])
            if p1 and p2 and p1:IsA("BasePart") and p2:IsA("BasePart") then
                local a1, s1 = cam:WorldToViewportPoint(p1.Position)
                local a2, s2 = cam:WorldToViewportPoint(p2.Position)
                if s1 and s2 then setL(e.s[k], Vector2.new(a1.X, a1.Y), Vector2.new(a2.X, a2.Y), skelCol) okDraw = true end
            end
        end
        if not okDraw then hideL(e.s[k]) end
    end
    if CFG.health then
        local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        setL(e.hpb, Vector2.new(x - 5, y1 - 1), Vector2.new(x - 5, y2 + 1), Color3.new(0, 0, 0))
        setL(e.hpf, Vector2.new(x - 5, y1 + hgt * (1 - frac)), Vector2.new(x - 5, y2), Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(80, 255, 100), frac))
        local hc = (frac > 0.6) and Color3.fromRGB(90, 235, 110) or (frac > 0.3) and Color3.fromRGB(255, 160, 50) or Color3.fromRGB(255, 60, 60)
        if CFG.hpPos == "Weapon" then
            setT(e.hpT, tostring(math.floor(hum.Health)) .. " hp", Vector2.new(mid.X, y2 + 23), hc)
        else
            setT(e.hpT, tostring(math.floor(hum.Health)), Vector2.new(x - 12, y1 + hgt * (1 - frac)), hc)
        end
    else
        hideL(e.hpb) hideL(e.hpf) hideL(e.hpT)
    end
    hideL(e.tr)
end
local function espStep()
    local seenP = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            seenP[p] = true
            local e = E[p]
            if not e then
                e = table.remove(POOL)
                if e then E[p] = e end
            end
            if e and not pcall(drawOne, p, e) then pcall(hideAll, e) end
        end
    end
    for p in pairs(E) do if not seenP[p] then release(p) end end
end

local GKIND = {
    {"flashbang", "flashbang", Color3.fromRGB(245, 245, 250), "Flashbang"},
    {"smoke", "smoke", Color3.fromRGB(170, 172, 180), "Smoke Grenade"},
    {"molotov", "molotov", Color3.fromRGB(255, 140, 40), "Molotov"},
    {"incend", "incendiary", Color3.fromRGB(255, 140, 40), "Incendiary Grenade"},
    {"decoy", "decoy", Color3.fromRGB(110, 230, 120), "Decoy Grenade"},
    {"he grenade", "he grenade", Color3.fromRGB(255, 80, 80), "HE Grenade"},
    {"hegrenade", "he grenade", Color3.fromRGB(255, 80, 80), "HE Grenade"},
    {"grenade", "grenade", Color3.fromRGB(255, 80, 80), "HE Grenade"},
}
local function gkind(name)
    local n = string.lower(name)
    for _, k in ipairs(GKIND) do
        if string.find(n, k[1], 1, true) then return k[2], k[3], k[4] end
    end
    return nil
end
local GPOOL, GLIVE = {}, {}
local SHORT = {flashbang = "FLASH", smoke = "SMOKE", molotov = "FIRE", incendiary = "FIRE", decoy = "DECOY", ["he grenade"] = "HE", grenade = "HE"}
for _ = 1, 12 do
    pcall(function()
        local e = {trail = {}}
        if HAS_DRAW then
            e.ring = dnew("Circle", {Radius = 9, Thickness = 1.5, NumSides = 24, Filled = false, Visible = false})
            e.dot = dnew("Circle", {Radius = 2, Thickness = 1, NumSides = 12, Filled = true, Visible = false})
        end
        e.txt = mkText(11)
        for k = 1, 10 do e.trail[k] = mkLine(1) end
        GPOOL[#GPOOL + 1] = e
    end)
end

local function nameKind(x)
    local k, c, l = gkind(x.Name)
    if k then return k, c, l end
    local up = x.Parent
    for _ = 1, 3 do
        if not up or up == workspace then break end
        k, c, l = gkind(up.Name)
        if k then return k, c, l end
        up = up.Parent
    end
    for _, ch in ipairs(x:GetChildren()) do
        if not ch:IsA("BasePart") then
            k, c, l = gkind(ch.Name)
            if k then return k, c, l end
        end
    end
    return nil
end
local function isThrown(x)
    if not (x:IsA("BasePart") or x:IsA("Model")) then return false end
    if not nameKind(x) then return false end
    if x:IsDescendantOf(workspace.CurrentCamera) or x:FindFirstAncestorOfClass("Tool") then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and x:IsDescendantOf(p.Character) then return false end
    end
    return true
end
local function partOfG(x)
    if x:IsA("BasePart") then return x end
    return x.PrimaryPart or x:FindFirstChildWhichIsA("BasePart", true)
end
local function addGrenade(x)
    if GLIVE[x] or not isThrown(x) then return end

    local fast = false
    local p0 = partOfG(x) and partOfG(x).Position
    for _ = 1, 12 do
        if not x.Parent then return end
        local bp = partOfG(x)
        if bp then
            local v = bp.AssemblyLinearVelocity
            if Vector3.new(v.X, 0, v.Z).Magnitude > 9 then fast = true break end

            if p0 and Vector3.new(bp.Position.X - p0.X, 0, bp.Position.Z - p0.Z).Magnitude > 3 then fast = true break end
        end
        task.wait(0.05)
    end
    if not fast or GLIVE[x] then return end

    if x:IsA("BasePart") and x.Parent and x.Parent:IsA("Model") and x.Parent ~= workspace and nameKind(x.Parent) then
        if GLIVE[x.Parent] then return end
        x = x.Parent
    end
    local e = table.remove(GPOOL)
    if not e then return end
    e.label, e.col, e.wname = nameKind(x)
    if not e.label then e.label, e.col = "grenade", Color3.fromRGB(255, 80, 80) end
    e.path, e.pathAt = {}, 0
    GLIVE[x] = e
end
connect(workspace.DescendantAdded, function(x) task.spawn(function() pcall(addGrenade, x) end) end)
local function hideG(e)
    if e.ring then hideL(e.ring) end
    if e.dot then hideL(e.dot) end
    hideL(e.txt)
    for _, l in ipairs(e.trail) do hideL(l) end
end
local function grenadeStep()
    local _, _, mine = myState()
    for x, e in pairs(GLIVE) do
        if not x.Parent then
            hideG(e)
            GLIVE[x] = nil
            GPOOL[#GPOOL + 1] = e
        elseif CFG.gESP and partOfG(x) then
            local gp = partOfG(x)

            if tick() - e.pathAt > 0.06 then
                e.pathAt = tick()
                table.insert(e.path, gp.Position)
                if #e.path > 11 then table.remove(e.path, 1) end
            end
            local sp, on = cam:WorldToViewportPoint(gp.Position)
            if on and sp.Z > 0 then
                local v2 = Vector2.new(sp.X, sp.Y)
                if e.ring then pcall(function() e.ring.Position, e.ring.Color, e.ring.Visible = v2, e.col, true end) end
                if e.dot then pcall(function() e.dot.Position, e.dot.Color, e.dot.Visible = v2, e.col, true end) end
                local d = mine and (" " .. math.floor((gp.Position - mine.Position).Magnitude)) or ""
                setT(e.txt, (SHORT[e.label] or "NADE") .. d, v2 + Vector2.new(0, 16), e.col)
            else
                hideG(e)
            end
            for k = 1, 10 do
                local a, b = e.path[k], e.path[k + 1]
                local okD = false
                if CFG.gTrail and a and b then
                    local s1, o1 = cam:WorldToViewportPoint(a)
                    local s2, o2 = cam:WorldToViewportPoint(b)
                    if o1 and o2 then
                        setL(e.trail[k], Vector2.new(s1.X, s1.Y), Vector2.new(s2.X, s2.Y), e.col)
                        okD = true
                    end
                end
                if not okD then hideL(e.trail[k]) end
            end
        else
            hideG(e)
        end
    end
end

local fx = Instance.new("Folder")
fx.Name = "ZenithCBFx"
fx.Parent = workspace.CurrentCamera
local function seg(a, b, c, w)
    local len = (b - a).Magnitude
    if len < 0.05 then return nil end
    local p = Instance.new("Part")
    p.Anchored, p.CanCollide, p.CastShadow = true, false, false
    pcall(function() p.CanQuery, p.CanTouch = false, false end)
    p.Material = Enum.Material.Neon
    p.Color = c
    p.Size = Vector3.new(w, w, len)
    p.CFrame = CFrame.lookAt((a + b) / 2, b)
    p.Parent = fx
    return p
end
local function fadeOut(parts, life)
    local t0 = tick()
    while tick() - t0 < life do
        local k = (tick() - t0) / life
        for _, p in ipairs(parts) do if p.Parent then p.Transparency = math.max(p.Transparency, k) end end
        RunService.Heartbeat:Wait()
    end
    for _, p in ipairs(parts) do pcall(function() p:Destroy() end) end
end
local lastTraceAt = 0
genv.ZenithCBTrace = nil
genv.ZenithCBShotAt = function(endp)
    if not (running and CFG.tracer) then return end
    if tick() - lastTraceAt < 0.03 then return end
    lastTraceAt = tick()
    local c = col(CFG.tracerCol)
    local start = cam.CFrame.Position + cam.CFrame.LookVector * 1.2 + cam.CFrame.RightVector * 0.4 - cam.CFrame.UpVector * 0.35
    local parts = {}
    if CFG.tracerType == "Lightning" then
        local dir = endp - start
        local n = math.clamp(math.floor(dir.Magnitude / 4), 4, 40)
        local side = dir:Cross(Vector3.yAxis)
        side = side.Magnitude > 0.01 and side.Unit or Vector3.xAxis
        local up = side:Cross(dir).Unit
        local prev = start
        for k = 1, n do
            local pt = start + dir * (k / n)
            if k < n then pt = pt + side * (math.random() - 0.5) * 1.4 + up * (math.random() - 0.5) * 1.4 end
            local p = seg(prev, pt, c, 0.1)
            if p then parts[#parts + 1] = p end
            prev = pt
        end
    else
        local p = seg(start, endp, c, 0.08)
        if p then parts[#parts + 1] = p end
        local g = seg(start, endp, c, 0.26)
        if g then g.Transparency = 0.75 parts[#parts + 1] = g end
    end
    fadeOut(parts, CFG.tracerTime)
end

local nGui = Instance.new("ScreenGui")
nGui.Name = "ZenithCBNotify"
nGui.IgnoreGuiInset = true
nGui.ResetOnSpawn = false
nGui.DisplayOrder = 40
pcall(function() nGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not nGui.Parent then nGui.Parent = lp:WaitForChild("PlayerGui") end
local hudStep
do
    local SoundService = game:GetService("SoundService")
    local ContentProvider = game:GetService("ContentProvider")
    local function dbg(...) if genv.ZenithDebug then print("[zenith]", ...) end end
    local function put(cls, props, parent)
        local o = Instance.new(cls)
        for k, v in pairs(props) do o[k] = v end
        o.Parent = parent
        return o
    end

    local KILL_RED = Color3.fromRGB(255, 72, 84)
    local feed = put("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 120), Size = UDim2.fromOffset(300, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, nGui)
    put("UIListLayout", {Padding = UDim.new(0, 3), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder}, feed)

    local PART = {Head = "Head", UpperTorso = "Chest", Torso = "Chest", LowerTorso = "Stomach", HumanoidRootPart = "Stomach"}
    local function partName(n)
        if PART[n] then return PART[n] end
        if string.find(n, "Arm") or string.find(n, "Hand") then return "Arm" end
        if string.find(n, "Leg") or string.find(n, "Foot") then return "Leg" end
        return "Body"
    end

    local live, order = {}, 0
    local TI_IN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TI_OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local function dismiss(e)
        if e.dead then return end
        e.dead = true
        for i, v in ipairs(live) do if v == e then table.remove(live, i) break end end
        pcall(function()
            TweenService:Create(e.card, TI_OUT, {GroupTransparency = 1}):Play()
            TweenService:Create(e.slide, TI_OUT, {Position = UDim2.fromOffset(30, 0)}):Play()
        end)
        task.delay(0.24, function() pcall(function() e.wrap:Destroy() end) end)
    end
    local function hex(c) return string.format("#%02x%02x%02x", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)) end

    local function showCard(kind, d)
        order = order + 1
        local isKill = kind == "kill"
        local hi = isKill and KILL_RED or Color3.fromRGB(235, 235, 240)
        local dim = "#8c8e98"
        local name = d.p.DisplayName
        local tags = {string.lower(partName(d.part)), d.dist .. "m"}
        if d.jump then tags[#tags + 1] = "air" end
        if d.wall then tags[#tags + 1] = "wall" end
        local txt
        if isKill then
            txt = string.format('<font color="%s"><b>killed</b></font>  %s  <font color="%s">%s  %s</font>', hex(hi), name, dim, tostring(d.weapon), table.concat(tags, "  "))
        else
            txt = string.format('<font color="%s"><b>-%d</b></font>  %s  <font color="%s">%s  %dhp</font>', hex(hi), math.floor(d.dmg + 0.5), name, dim,
                table.concat(tags, "  "), math.floor(d.left + 0.5))
        end
        local wrap = put("Frame", {Size = UDim2.fromOffset(300, 24), BackgroundTransparency = 1, LayoutOrder = -order}, feed)
        local slide = put("Frame", {Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(30, 0), BackgroundTransparency = 1}, wrap)
        local card = put("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 8, 10), BackgroundTransparency = 0.5,
            BorderSizePixel = 0, GroupTransparency = 1}, slide)
        put("UICorner", {CornerRadius = UDim.new(0, 3)}, card)
        put("Frame", {Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = hi, BorderSizePixel = 0}, card)
        put("ImageLabel", {Position = UDim2.fromOffset(8, 3), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Color3.fromRGB(28, 28, 34), BorderSizePixel = 0,
            Image = "rbxthumb://type=AvatarHeadShot&id=" .. d.p.UserId .. "&w=48&h=48"}, card)
        put("TextLabel", {Text = txt, RichText = true, Font = Enum.Font.Code, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
            Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -38, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, card)
        local e = {wrap = wrap, slide = slide, card = card}
        live[#live + 1] = e
        while #live > 6 do dismiss(live[1]) end
        TweenService:Create(slide, TI_IN, {Position = UDim2.fromOffset(0, 0)}):Play()
        TweenService:Create(card, TI_IN, {GroupTransparency = 0}):Play()
        task.delay(isKill and 4 or 2.5, function() dismiss(e) end)
    end

    local lastBullet, lastBulletPos, hookSeen = 0, nil, false
    local prevShotAt = genv.ZenithCBShotAt
    genv.ZenithCBShotAt = function(pos)
        hookSeen, lastBullet, lastBulletPos = true, tick(), pos
        if prevShotAt then return prevShotAt(pos) end
    end

    local function isMine(p, hum)
        local now = tick()
        if hookSeen and now - lastBullet < 0.7 then return true end
        if shot and shot.p == p and now - shot.at < 0.8 then return true end
        if not hookSeen and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            return r ~= nil and angleTo(r.Position) < 50
        end
        return false
    end

    local function describe(p, hum)
        local ch = p.Character
        local _, mh, mr = myState()
        local r = ch and ch:FindFirstChild("HumanoidRootPart")
        local part, pos, wall
        if shot and shot.p == p and tick() - shot.at < 1 then
            part, pos, wall = shot.part, shot.pos, shot.wall
        elseif ch and lastBulletPos and tick() - lastBullet < 1 then
            local bd = 8
            for _, d in ipairs(ch:GetChildren()) do
                if d:IsA("BasePart") then
                    local dd = (d.Position - lastBulletPos).Magnitude
                    if dd < bd then part, bd = d.Name, dd end
                end
            end
        end
        return {
            p = p, ch = ch, part = part or "Body", pos = pos or (r and r.Position), wall = wall == true,
            dist = (mr and r) and math.floor((r.Position - mr.Position).Magnitude) or 0, weapon = myWeapon(),
            jump = mh and mh.FloorMaterial == Enum.Material.Air or false, maxhp = hum.MaxHealth,
        }
    end

    local pending = {}
    local function queue(p, hum, dmg, now)
        local q = pending[p]
        if q then
            q.dmg = q.dmg + dmg
            q.left = math.max(now, 0)
            q.killed = q.killed or now <= 0
            return
        end
        q = {dmg = dmg, left = math.max(now, 0), killed = now <= 0, info = describe(p, hum)}
        pending[p] = q
        task.delay(0.07, function()
            pending[p] = nil
            if not running then return end
            local d = q.info
            d.dmg, d.left = q.dmg, q.left
            if q.killed then
                if CFG.killNotify then pcall(showCard, "kill", d) end
            else
                if CFG.hitNotify then pcall(showCard, "hit", d) end
            end
        end)
    end

    local seenHum = setmetatable({}, {__mode = "k"})
    local function watch(p, hum)
        seenHum[hum] = hum.Health
        hum.HealthChanged:Connect(function(now)
            local old = seenHum[hum]
            seenHum[hum] = now
            if not running or not old or now >= old then return end
            if not enemyOf(p, true) then return end
            if not isMine(p, hum) then dbg("not yours:", p.Name, old, "->", now) return end
            queue(p, hum, old - now, now)
        end)
    end
    connect(RunService.Heartbeat, function()
        if not running then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                local ch = p.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if hum and seenHum[hum] == nil then watch(p, hum) end
            end
        end
    end)
end

do
    local man = Instance.new("TextLabel")
    man.Font, man.TextSize, man.BackgroundTransparency, man.TextStrokeTransparency = Enum.Font.GothamBold, 13, 1, 0.5
    man.AnchorPoint, man.Position, man.Size = Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 72), UDim2.fromOffset(120, 18)
    man.TextColor3, man.Visible, man.Parent = Color3.new(1, 1, 1), false, nGui
    local MAN_TXT = {Left = "< left", Right = "right >", Back = "back", Front = "front"}
    hudStep = function()
        local isMan = CFG.aa and CFG.aaYaw == "Manual"
        man.Visible = isMan
        if isMan then man.Text, man.TextColor3 = MAN_TXT[CFG.aaManual] or "back", acc() end
    end
end

local UI = Instance.new("ScreenGui")
UI.Name = "ZenithCBMenu"
UI.IgnoreGuiInset = true
UI.ResetOnSpawn = false
UI.DisplayOrder = 60
pcall(function() UI.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not UI.Parent then UI.Parent = lp:WaitForChild("PlayerGui") end
local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local BG, SIDE, CARD, SUB = Color3.fromRGB(13, 13, 16), Color3.fromRGB(18, 18, 22), Color3.fromRGB(24, 24, 29), Color3.fromRGB(17, 17, 21)
local TXT, DIM = Color3.fromRGB(235, 235, 240), Color3.fromRGB(128, 130, 140)
local refreshers = {}
local S_BINDABLE = {
    {"silent aim", "silent"}, {"aimbot", "aimbot"}, {"anti-aim", "aa"}, {"esp", "esp"}, {"chams", "chams"},
    {"bhop", "bhop"}, {"third person", "third"}, {"tracers", "tracer"},
}
local BINDABLE = setmetatable({}, {__index = function() return true end})
local LABELS = {}
local function refresh() for _, r in ipairs(refreshers) do pcall(r) end end

local function icon(parent, kind, size)
    local h = new("Frame", {Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1}, parent)
    local parts = {}
    local function bar(x, y, w, hh, r)
        local f = new("Frame", {Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, hh), BorderSizePixel = 0}, h)
        if r then round(f, r) end
        parts[#parts + 1] = {f, "bg"}
        return f
    end
    local function ring(x, y, w, hh, th)
        local f = new("Frame", {Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, hh), BackgroundTransparency = 1}, h)
        round(f, 999)
        local s = new("UIStroke", {Thickness = th or 1.6}, f)
        parts[#parts + 1] = {s, "stroke"}
    end
    if kind == "aim" then ring(0.1, 0.1, 0.8, 0.8) bar(0.46, 0, 0.08, 0.3) bar(0.46, 0.7, 0.08, 0.3) bar(0, 0.46, 0.3, 0.08) bar(0.7, 0.46, 0.3, 0.08)
    elseif kind == "eye" then ring(0.05, 0.25, 0.9, 0.5) bar(0.38, 0.38, 0.24, 0.24, 99)
    elseif kind == "user" then bar(0.32, 0.05, 0.36, 0.36, 99) bar(0.15, 0.5, 0.7, 0.45, 6)
    elseif kind == "gear" then ring(0.2, 0.2, 0.6, 0.6, 2.4) bar(0.44, 0, 0.12, 0.22) bar(0.44, 0.78, 0.12, 0.22) bar(0, 0.44, 0.22, 0.12) bar(0.78, 0.44, 0.22, 0.12)
    elseif kind == "move" then bar(0.1, 0.45, 0.65, 0.1) bar(0.55, 0.28, 0.1, 0.44) bar(0.65, 0.35, 0.1, 0.3)
    elseif kind == "bomb" then ring(0.1, 0.25, 0.7, 0.7) bar(0.55, 0.05, 0.12, 0.28)
    elseif kind == "drop" then bar(0.2, 0.2, 0.6, 0.6, 99) bar(0.38, 0, 0.24, 0.3)
    elseif kind == "shield" then bar(0.15, 0.05, 0.7, 0.55, 3) bar(0.3, 0.5, 0.4, 0.4, 99)
    elseif kind == "bell" then bar(0.2, 0.15, 0.6, 0.6, 99) bar(0.1, 0.62, 0.8, 0.12) bar(0.43, 0.78, 0.14, 0.14, 99)
    elseif kind == "cam" then bar(0.05, 0.25, 0.65, 0.5, 3) bar(0.72, 0.35, 0.23, 0.3)
    elseif kind == "wifi" then bar(0.05, 0.65, 0.18, 0.3) bar(0.4, 0.4, 0.18, 0.55) bar(0.75, 0.1, 0.18, 0.85)
    elseif kind == "chip" then ring(0.2, 0.2, 0.6, 0.6, 1.5) bar(0, 0.35, 0.2, 0.08) bar(0, 0.6, 0.2, 0.08) bar(0.8, 0.35, 0.2, 0.08) bar(0.8, 0.6, 0.2, 0.08)
    elseif kind == "clock" then ring(0.05, 0.05, 0.9, 0.9, 1.5) bar(0.46, 0.2, 0.08, 0.32) bar(0.46, 0.46, 0.28, 0.08)
    elseif kind == "bolt2" then bar(0.45, 0, 0.12, 0.55) bar(0.3, 0.45, 0.4, 0.12) bar(0.45, 0.5, 0.12, 0.5)
    elseif kind == "sun" then ring(0.25, 0.25, 0.5, 0.5, 2) bar(0.46, 0, 0.08, 0.18) bar(0.46, 0.82, 0.08, 0.18) bar(0, 0.46, 0.18, 0.08) bar(0.82, 0.46, 0.18, 0.08)
    elseif kind == "gun" then bar(0.05, 0.3, 0.8, 0.18, 2) bar(0.15, 0.45, 0.18, 0.4, 2) bar(0.85, 0.3, 0.1, 0.1)
    else bar(0.3, 0.3, 0.4, 0.4, 99) end
    local function tint(c)
        for _, p in ipairs(parts) do
            if p[2] == "stroke" then p[1].Color = c else p[1].BackgroundColor3 = c end
        end
    end
    return h, tint
end

local RING = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false}, UI)
round(RING, 999)
local RINGS = new("UIStroke", {Color = acc(), Transparency = 0.35, Thickness = 1}, RING)
local SRING = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false}, UI)
round(SRING, 999)
local SRINGS = new("UIStroke", {Color = Color3.new(1, 1, 1), Transparency = 0.45, Thickness = 1}, SRING)

local openB = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = BG, BackgroundTransparency = 0.08,
    Position = UDim2.new(0, 16, 0.4, 0), Size = UDim2.fromOffset(46, 46)}, UI)
round(openB, 12)
local openS = new("UIStroke", {Color = acc(), Transparency = 0.25, Thickness = 1.5}, openB)
local openL = new("TextLabel", {Text = "Z", Font = Enum.Font.Michroma, TextSize = 18, TextColor3 = acc(), BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1)}, openB)

local win = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(480, 360),
    BackgroundColor3 = BG, BackgroundTransparency = 0.5, Visible = false}, UI)
round(win, 12)
new("UIStroke", {Color = Color3.new(1, 1, 1), Transparency = 0.88}, win)

local MENU_IMG = 72799844056549
do
    local pic = new("ImageLabel", {BackgroundTransparency = 1, Image = "rbxassetid://" .. MENU_IMG, ScaleType = Enum.ScaleType.Crop,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8), ZIndex = 3}, openB)
    round(pic, 9)
    task.spawn(function()
        local t0 = tick()
        while not pic.IsLoaded and tick() - t0 < 3 do task.wait(0.1) end

        if not pic.IsLoaded then pic.Image = "rbxthumb://type=Asset&id=" .. MENU_IMG .. "&w=150&h=150" end
    end)
end

local bgClip = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 0}, win)
round(bgClip, 12)
local bgShapes = {}
local function drawBg()
    for _, s in ipairs(bgShapes) do pcall(function() s.f:Destroy() end) end
    bgShapes = {}
    local style = CFG.menuBg
    if style == "None" then return end
    local rnd = Random.new(7)
    for i = 1, (style == "Space") and 46 or 14 do
        local f
        if style == "Space" then
            local sz = rnd:NextInteger(1, 3)
            f = new("Frame", {Position = UDim2.fromScale(rnd:NextNumber(), rnd:NextNumber()), Size = UDim2.fromOffset(sz, sz),
                BackgroundColor3 = (i % 5 == 0) and acc() or Color3.new(1, 1, 1), BackgroundTransparency = rnd:NextNumber(0.2, 0.7), BorderSizePixel = 0}, bgClip)
            round(f, 99)
        else
            local sz = rnd:NextInteger(26, 90)
            f = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rnd:NextNumber(), rnd:NextNumber()), Size = UDim2.fromOffset(sz, sz),
                BackgroundTransparency = 1, Rotation = rnd:NextInteger(0, 90)}, bgClip)
            if style == "Geometry" and i % 3 == 0 then round(f, 999) end
            if style == "Triangles" then

                for k = 0, 2 do
                    local a = math.rad(k * 120 - 90)
                    local b2 = math.rad((k + 1) * 120 - 90)
                    local x1, y1 = 0.5 + math.cos(a) * 0.5, 0.5 + math.sin(a) * 0.5
                    local x2, y2 = 0.5 + math.cos(b2) * 0.5, 0.5 + math.sin(b2) * 0.5
                    local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
                    new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale((x1 + x2) / 2, (y1 + y2) / 2),
                        Size = UDim2.new(len, 0, 0, 1), Rotation = math.deg(math.atan2(y2 - y1, x2 - x1)), BorderSizePixel = 0,
                        BackgroundColor3 = acc(), BackgroundTransparency = 0.82}, f)
                end
            else
                new("UIStroke", {Color = acc(), Transparency = 0.82, Thickness = 1}, f)
            end
        end
        bgShapes[#bgShapes + 1] = {f = f, spin = rnd:NextNumber(-8, 8)}
    end
end
drawBg()
connect(RunService.RenderStepped, function(dt)
    if not win.Visible then return end
    for _, s in ipairs(bgShapes) do s.f.Rotation = s.f.Rotation + s.spin * (dt or 0.016) end
end)
local vp0 = workspace.CurrentCamera.ViewportSize
new("UIScale", {Scale = math.clamp(math.min(vp0.X / 640, vp0.Y / 420), 0.68, 1.25)}, win)
local side = new("Frame", {Size = UDim2.new(0, 128, 1, 0), BackgroundColor3 = SIDE, BackgroundTransparency = 0.45, BorderSizePixel = 0}, win)
round(side, 12)
local logoBox = new("ImageLabel", {Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = BG, BorderSizePixel = 0,
    Image = "rbxassetid://" .. MENU_IMG, ScaleType = Enum.ScaleType.Crop}, side)
round(logoBox, 8)
task.spawn(function()
    local t0 = tick()
    while not logoBox.IsLoaded and tick() - t0 < 3 do task.wait(0.1) end
    if not logoBox.IsLoaded then logoBox.Image = "rbxthumb://type=Asset&id=" .. MENU_IMG .. "&w=150&h=150" end
end)
new("TextLabel", {Text = "zenith", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TXT, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(52, 14), Size = UDim2.fromOffset(70, 30), TextXAlignment = Enum.TextXAlignment.Left}, side)
local tabList = new("Frame", {Position = UDim2.fromOffset(8, 62), Size = UDim2.new(1, -16, 1, -70), BackgroundTransparency = 1}, side)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, tabList)
do
    local me = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -10), Size = UDim2.new(1, -16, 0, 42),
        BackgroundColor3 = CARD, BackgroundTransparency = 0.25, BorderSizePixel = 0}, side)
    round(me, 9)
    local pic = new("ImageLabel", {Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = BG, BorderSizePixel = 0,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. lp.UserId .. "&w=100&h=100"}, me)
    round(pic, 15)
    local ps = new("UIStroke", {Color = acc(), Thickness = 1.5, Transparency = 0.2}, pic)
    refreshers[#refreshers + 1] = function() ps.Color = acc() end
    new("TextLabel", {Text = lp.DisplayName, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = TXT, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(42, 6), Size = UDim2.new(1, -46, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd}, me)
    new("TextLabel", {Text = "@" .. lp.Name, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = DIM, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(42, 21), Size = UDim2.new(1, -46, 0, 13), TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd}, me)
end
local title = new("TextLabel", {Text = "", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = TXT, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(146, 14), Size = UDim2.new(1, -200, 0, 22), TextXAlignment = Enum.TextXAlignment.Left}, win)
local closeB = new("TextButton", {Text = "×", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = DIM, BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(30, 30)}, win)
closeB.Activated:Connect(function() win.Visible = false end)

local pages, tabs = {}, {}
local function selectTab(name)
    for n, p in pairs(pages) do p.Visible = n == name end
    for n, t in pairs(tabs) do
        local on = n == name
        t.btn.BackgroundTransparency = on and 0.85 or 1
        t.btn.BackgroundColor3 = acc()
        t.bar.Visible = on
        t.bar.BackgroundColor3 = acc()
        t.lbl.TextColor3 = on and TXT or DIM
        t.tint(on and acc() or DIM)
    end
    title.Text = name
end
local function tab(name, kind, i)
    local b = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = i}, tabList)
    round(b, 8)
    local bar = new("Frame", {Position = UDim2.fromOffset(0, 9), Size = UDim2.fromOffset(3, 18), BorderSizePixel = 0, Visible = false}, b)
    round(bar, 2)
    local ic, tint = icon(b, kind, 16)
    ic.Position = UDim2.fromOffset(12, 10)
    local lbl = new("TextLabel", {Text = name, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = DIM, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, b)
    tabs[name] = {btn = b, bar = bar, lbl = lbl, tint = tint}
    local p = new("ScrollingFrame", {Position = UDim2.fromOffset(140, 46), Size = UDim2.new(1, -152, 1, -56), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = acc(), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false}, win)
    new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, p)
    pages[name] = p
    b.Activated:Connect(function() selectTab(name) end)
    return p
end
local order = 0
local function nextOrder() order = order + 1 return order end
local function section(pg, txt)
    new("TextLabel", {Text = txt, Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = DIM, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder()}, pg)
end
local function switch(parent, key)
    local box = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(34, 18),
        BackgroundColor3 = Color3.fromRGB(50, 52, 60)}, parent)
    round(box, 9)
    local knob = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.new(1, 1, 1)}, box)
    round(knob, 6)
    local function render()
        box.BackgroundColor3 = CFG[key] and acc() or Color3.fromRGB(50, 52, 60)
        knob.Position = CFG[key] and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    end
    render()
    refreshers[#refreshers + 1] = render
    return function() CFG[key] = not CFG[key] render() save() end
end
local function toggle(pg, txt, key, kind, build)
    LABELS[key] = LABELS[key] or txt
    build = build or function() end
    local wrap = new("Frame", {Size = UDim2.new(1, 0, 0, 38), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = CARD, LayoutOrder = nextOrder()}, pg)
    round(wrap, 8)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center}, wrap)
    local rowF = new("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 1}, wrap)
    local x0 = 12
    if kind then
        local ic, tint = icon(rowF, kind, 14)
        ic.Position = UDim2.fromOffset(12, 12)
        tint(DIM)
        refreshers[#refreshers + 1] = function() tint(CFG[key] and acc() or DIM) end
        tint(CFG[key] and acc() or DIM)
        x0 = 34
    end
    new("TextLabel", {Text = txt, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = TXT, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(x0, 0), Size = UDim2.new(1, -x0 - 90, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, rowF)
    local flipRaw = switch(rowF, key)
    local function flip() flipRaw() refresh() end
    new("TextButton", {Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -86, 1, 0)}, rowF).Activated:Connect(flip)
    new("TextButton", {Text = "", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(52, 38)}, rowF).Activated:Connect(flip)
    if build then
        local more = new("TextButton", {Text = "···", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = DIM, AutoButtonColor = false,
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -52, 0.5, 0), Size = UDim2.fromOffset(30, 30), ZIndex = 3}, rowF)
        local sub = new("Frame", {Size = UDim2.new(1, -14, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = SUB, Visible = false, LayoutOrder = 2}, wrap)
        round(sub, 7)
        new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, sub)
        new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, sub)
        local pad = new("Frame", {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, LayoutOrder = 3}, wrap)
        local built = false
        more.Activated:Connect(function()
            if not built then
                built = true
                if BINDABLE[key] then

                    local f = new("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = -1}, sub)
                    new("TextLabel", {Text = "bind", Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = TXT, BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(2, 0), Size = UDim2.new(0.4, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
                    local chip = new("TextButton", {Text = CFG.binds[key] or "none", Font = Enum.Font.Code, TextSize = 11, TextColor3 = TXT,
                        AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(30, 31, 38), AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(96, 22)}, f)
                    round(chip, 5)
                    chip.Activated:Connect(function()
                        chip.Text = "press a key..."
                        local cn
                        cn = UIS.InputBegan:Connect(function(i)
                            if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                            cn:Disconnect()
                            if i.KeyCode == Enum.KeyCode.Backspace then CFG.binds[key] = nil else CFG.binds[key] = i.KeyCode.Name end
                            chip.Text = CFG.binds[key] or "none"
                            save()
                        end)
                    end)
                end
                build(sub)
            end
            sub.Visible = not sub.Visible
            pad.Size = UDim2.new(1, 0, 0, sub.Visible and 7 or 0)
            more.TextColor3 = sub.Visible and acc() or DIM
        end)
    end
end
local function slider(pg, txt, key, mn, mx, step, unit)
    local f = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, pg)
    new("TextLabel", {Text = txt, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = TXT, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -70, 0, 16), TextXAlignment = Enum.TextXAlignment.Left}, f)
    local val = new("TextLabel", {Font = Enum.Font.Code, TextSize = 12, TextColor3 = acc(), BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -2, 0, 2), Size = UDim2.fromOffset(66, 16), TextXAlignment = Enum.TextXAlignment.Right}, f)
    local bar = new("Frame", {Position = UDim2.new(0, 2, 0, 26), Size = UDim2.new(1, -4, 0, 4), BackgroundColor3 = Color3.fromRGB(46, 48, 56)}, f)
    round(bar, 2)
    local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = acc()}, bar)
    round(fill, 2)
    local knob = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = Color3.new(1, 1, 1)}, bar)
    round(knob, 5)
    local function render()
        local a = math.clamp((CFG[key] - mn) / (mx - mn), 0, 1)
        fill.Size, fill.BackgroundColor3 = UDim2.fromScale(a, 1), acc()
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        val.TextColor3 = acc()
        val.Text = ((step < 1) and string.format("%.2f", CFG[key]) or tostring(math.floor(CFG[key] + 0.5))) .. (unit or "")
    end
    render()
    refreshers[#refreshers + 1] = render
    local drag = false
    local function set(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        CFG[key] = math.clamp(math.floor((mn + (mx - mn) * a) / step + 0.5) * step, mn, mx)
        render()
    end
    local hit = new("TextButton", {Text = "", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 16), Size = UDim2.new(1, 0, 0, 24)}, f)
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = true set(i.Position.X) end
    end)
    connect(UIS.InputChanged, function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then set(i.Position.X) end
    end)
    connect(UIS.InputEnded, function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then drag = false save() end
    end)
end
local function choice(pg, txt, key, opts)
    local f = new("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, pg)
    new("TextLabel", {Text = txt, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = TXT, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(2, 0), Size = UDim2.new((#opts > 4) and 0.2 or 0.34, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
    local box = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.new((#opts > 4) and 0.8 or 0.66, -4, 0, 24),
        BackgroundColor3 = Color3.fromRGB(30, 31, 38)}, f)
    round(box, 6)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), VerticalAlignment = Enum.VerticalAlignment.Center}, box)
    new("UIPadding", {PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2)}, box)
    local btns = {}
    local function render()
        for o, b in pairs(btns) do
            local on = CFG[key] == o
            b.BackgroundTransparency = on and 0 or 1
            b.BackgroundColor3 = acc()
            b.TextColor3 = on and Color3.fromRGB(12, 12, 14) or DIM
        end
    end
    for _, o in ipairs(opts) do
        local b = new("TextButton", {Text = o, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false, BackgroundTransparency = 1,
            Size = UDim2.new(1 / #opts, -2, 0, 20)}, box)
        round(b, 5)
        btns[o] = b
        b.Activated:Connect(function() CFG[key] = o render() save() end)
    end
    render()
    refreshers[#refreshers + 1] = render
end
local function colors(pg, txt, key, onChange)
    local f = new("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, pg)
    new("TextLabel", {Text = txt, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = TXT, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(2, 0), Size = UDim2.new(0.3, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
    local box = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.new(0.7, -4, 0, 18), BackgroundTransparency = 1}, f)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center}, box)
    local chips = {}
    local function render() for n, ch in pairs(chips) do ch.Transparency = (CFG[key] == n) and 0 or 1 end end
    for _, n in ipairs(PAL_ORDER) do
        local b = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = PAL[n], Size = UDim2.fromOffset(16, 16)}, box)
        round(b, 4)
        chips[n] = new("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 1}, b)
        b.Activated:Connect(function() CFG[key] = n render() save() if onChange then onChange() end end)
    end
    render()
    refreshers[#refreshers + 1] = render
end

local function input(pg, txt, key, hint, onDone)
    local f = new("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = nextOrder()}, pg)
    new("TextLabel", {Text = txt, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = TXT, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(2, 0), Size = UDim2.new(0.34, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
    local box = new("TextBox", {Text = tostring(CFG[key] or ""), PlaceholderText = hint or "", Font = Enum.Font.Code, TextSize = 12, TextColor3 = TXT,
        PlaceholderColor3 = DIM, BackgroundColor3 = Color3.fromRGB(30, 31, 38), ClearTextOnFocus = false, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.new(0.66, -4, 0, 26), TextXAlignment = Enum.TextXAlignment.Left}, f)
    round(box, 6)
    new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, box)
    box.FocusLost:Connect(function()
        CFG[key] = box.Text
        save()
        if onDone then onDone(box.Text) end
    end)
    return box
end
local function button(pg, txt, fn)
    local b = new("TextButton", {Text = txt, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(12, 12, 14), AutoButtonColor = false,
        BackgroundColor3 = acc(), Size = UDim2.new(1, 0, 0, 30), LayoutOrder = nextOrder()}, pg)
    round(b, 6)
    refreshers[#refreshers + 1] = function() b.BackgroundColor3 = acc() end
    b.Activated:Connect(fn)
    return b
end

local pRage = tab("rage", "aim", 1)
local pLegit = tab("legit", "user", 2)
local pVis = tab("visuals", "eye", 3)
local pWorld = tab("world", "sun", 4)
local pCfg = tab("config", "chip", 5)
local pSet = tab("settings", "gear", 6)

section(pRage, "SILENT")
toggle(pRage, "silent aim", "silent", "aim", function(b)
    slider(b, "fov", "silentFov", 10, 360, 5, "°")
    toggle(b, "draw fov", "silentShowFov")
    toggle(b, "visible check", "visCheck")
    toggle(b, "auto wall", "autoWall")
    slider(b, "min damage", "minDmg", 0, 130, 1)
    toggle(b, "team check", "teamCheck")
    slider(b, "multipoint scale", "mpScale", 0, 100, 5, "%")
    toggle(b, "head", "mpHead")
    toggle(b, "neck", "mpNeck")
    toggle(b, "chest", "mpChest")
    toggle(b, "left arm", "mpLArm")
    toggle(b, "right arm", "mpRArm")
    toggle(b, "left leg", "mpLLeg")
    toggle(b, "right leg", "mpRLeg")
end)
section(pLegit, "AIMBOT")
toggle(pLegit, "aimbot", "aimbot", "user", function(b)
    choice(b, "aim at", "aimPart", {"Head", "Chest", "Belly", "Arm", "Leg", "Auto"})
    slider(b, "fov", "aimFov", 10, 360, 5, "°")
    slider(b, "smooth", "aimSmooth", 1, 20, 1)
    toggle(b, "wall check", "aimWall")
    toggle(b, "team check", "aimTeam")
    toggle(b, "draw fov", "aimShowFov")
end)
section(pRage, "ANTI-AIM")
toggle(pRage, "anti-aim", "aa", "shield", function(b)
    choice(b, "yaw", "aaYaw", {"Spin", "Jitter", "Back", "Side", "Manual"})
    toggle(b, "jitter on top", "aaJit")
    slider(b, "jitter range", "aaJitRange", 5, 180, 5, "°")
    slider(b, "jitter speed", "aaJitSpeed", 1, 30, 1, "/s")
    choice(b, "manual", "aaManual", {"Front", "Left", "Right", "Back"})
    input(b, "left key", "aaKeyL", "Left")
    input(b, "right key", "aaKeyR", "Right")
    input(b, "back key", "aaKeyB", "Down")
    input(b, "front key", "aaKeyF", "Up")
    choice(b, "pitch", "aaPitch", {"None", "Down", "Up", "Jitter"})
    slider(b, "spin speed", "aaSpeed", 1, 60, 1)
    toggle(b, "spin on air", "aaAir", nil, function(b2)
        slider(b2, "spin speed", "aaAirSpeed", 1, 60, 1)
        choice(b2, "pitch", "aaAirPitch", {"None", "Down", "Up", "Jitter"})
    end)
end)

section(pVis, "PLAYERS")
toggle(pVis, "esp", "esp", "eye", function(b)
    colors(b, "enemy", "espCol")
    colors(b, "team", "teamCol")
    toggle(b, "teammates", "espTeam")
    toggle(b, "chams", "chams", nil, function(b2)
        choice(b2, "style", "chamsStyle", {"Glow", "ForceField", "Flat"})
        colors(b2, "color", "chamsCol")
        slider(b2, "fill", "chamsFill", 0, 1, 0.05)
        slider(b2, "outline", "chamsOutline", 0, 1, 0.05)
        choice(b2, "show", "chamsMode", {"Walls", "Visible"})
        toggle(b2, "color by health", "chamsHealth")
    end)
end)
toggle(pVis, "box", "box", nil, function(b) choice(b, "style", "boxStyle", {"Corner", "Full"}) end)
toggle(pVis, "name", "name", "user", function(b) toggle(b, "avatar", "avatar") end)
toggle(pVis, "health bar", "health", nil, function(b) choice(b, "text", "hpPos", {"Bar", "Weapon"}) end)
toggle(pVis, "distance", "dist")
toggle(pVis, "weapon", "weapon", "gun", function(b) toggle(b, "weapon icon", "weaponIcon") end)
toggle(pVis, "skeleton", "skeleton")
section(pVis, "EFFECTS")
toggle(pVis, "bullet tracers", "tracer", "bolt2", function(b)
    choice(b, "type", "tracerType", {"Neon", "Lightning"})
    colors(b, "color", "tracerCol")
    slider(b, "time", "tracerTime", 0.2, 3, 0.1, "s")
end)
section(pVis, "GRENADES")
toggle(pVis, "grenade esp", "gESP", "bomb", function(b)
    toggle(b, "flight path", "gTrail")
end)

section(pVis, "SELF")
toggle(pVis, "self chams", "selfChams", "user", function(b)
    colors(b, "color", "myCol")
    toggle(b, "weapon chams", "weaponChams")
    colors(b, "weapon", "wpnCol")
    toggle(b, "glove chams", "gloveChams")
    colors(b, "gloves", "gloveCol")
    choice(b, "material", "myStyle", {"ForceField", "Neon", "Glass"})
end)

section(pWorld, "SKY")
toggle(pWorld, "skybox", "skyOn", "sun", function(b)
    loadSkies()
    local list = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder()}, b)
    new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, list)
    skyRedraw = function()
        for _, ch in ipairs(list:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        for i, it in ipairs(skyList) do
            local on = CFG.sky == it.key
            local r = new("TextButton", {Text = "  " .. it.name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = on and acc() or TXT,
                TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(30, 31, 38),
                Size = UDim2.new(1, 0, 0, 26), LayoutOrder = i}, list)
            round(r, 6)
            r.Activated:Connect(function()
                CFG.sky = (CFG.sky == it.key) and "" or it.key
                save()
                skyRedraw()
            end)
        end
    end
    skyRedraw()
    input(b, "your sky id", "skyId", "model or picture id", function(t)
        local id = t:match("%d+")
        if id then CFG.sky = "custom:" .. id save() if skyRedraw then skyRedraw() end end
    end)
end)
toggle(pWorld, "fullbright", "fullbright", "sun")
section(pWorld, "CAMERA")
toggle(pWorld, "third person", "third", "cam", function(b) slider(b, "distance", "thirdDist", 4, 25, 1) end)
toggle(pWorld, "field of view", "worldFov", "cam", function(b) slider(b, "fov", "fovValue", 50, 120, 1) end)
section(pVis, "NOTIFY")
toggle(pVis, "hit notify", "hitNotify", "bell")
toggle(pVis, "kill notify", "killNotify", "bell")
section(pRage, "MOVEMENT")
toggle(pRage, "bhop", "bhop", "move", function(b) slider(b, "air speed", "bhopSpeed", 16, 60, 1) end)

section(pSet, "MENU")
colors(pSet, "accent", "accent", function()
    drawBg()
    openS.Color, openL.TextColor3 = acc(), acc()
    for _, p in pairs(pages) do p.ScrollBarImageColor3 = acc() end
    refresh()
    for n, p in pairs(pages) do if p.Visible then selectTab(n) end end
end)
choice(pSet, "background", "menuBg", {"None", "Geometry", "Space", "Triangles"})
do

    local lastBg = CFG.menuBg
    connect(RunService.Heartbeat, function()
        if CFG.menuBg ~= lastBg then lastBg = CFG.menuBg drawBg() end
    end)
end
section(pSet, "OVERLAY")
toggle(pSet, "watermark", "wm", "eye", function(b)
    toggle(b, "user", "wmUser")
    toggle(b, "fps", "wmFps")
    toggle(b, "ping", "wmPing")
    toggle(b, "ram (mb)", "wmRam")
    toggle(b, "ram (gb)", "wmGb")
    toggle(b, "time", "wmTime")
    toggle(b, "subscription", "wmSub")
end)
toggle(pSet, "keybind list", "bindList", "gear")
section(pCfg, "CONFIGS")
do
    local CDIR = "ZenithCB/configs"
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
    input(pCfg, "name", "cfgName", "config name")
    local list = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, pCfg)
    new("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, list)
    local function redraw()
        for _, ch in ipairs(list:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
        for i, n in ipairs(names()) do
            local r = new("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = CARD, LayoutOrder = i}, list)
            round(r, 6)
            new("TextLabel", {Text = n, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = TXT, BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -130, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, r)
            local function small(txt, x, fn)
                local b = new("TextButton", {Text = txt, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = TXT, AutoButtonColor = false,
                    BackgroundColor3 = Color3.fromRGB(38, 40, 48), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(54, 22)}, r)
                round(b, 5)
                b.Activated:Connect(fn)
            end
            small("load", -64, function()
                pcall(function()
                    for k, v in pairs(Http:JSONDecode(readfile(CDIR .. "/" .. n .. ".json"))) do
                        if CFG[k] ~= nil and type(CFG[k]) == type(v) then CFG[k] = v end
                    end
                end)
                save()
                refresh()
                drawBg()
            end)
            small("delete", -6, function()
                pcall(function() delfile(CDIR .. "/" .. n .. ".json") end)
                redraw()
            end)
        end
    end
    list.LayoutOrder = nextOrder()
    button(pCfg, "save config", function()
        local n = tostring(CFG.cfgName or ""):gsub("[^%w%-_ ]", "")
        if n == "" then return end
        pcall(function()
            if makefolder then
                if not isfolder("ZenithCB") then makefolder("ZenithCB") end
                if not isfolder(CDIR) then makefolder(CDIR) end
            end
            writefile(CDIR .. "/" .. n .. ".json", Http:JSONEncode(CFG))
        end)
        redraw()
    end)
    redraw()
end
section(pSet, "SCRIPT")
do
    local f = new("TextButton", {Text = "unload", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255, 120, 120),
        AutoButtonColor = false, BackgroundColor3 = CARD, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = nextOrder()}, pSet)
    round(f, 8)
    f.Activated:Connect(function() if genv.ZenithCB then genv.ZenithCB() end end)
end
selectTab("rage")

do
    local dragging, ds, sp, moved = false, nil, nil, false
    openB.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, ds, sp, moved = true, i.Position, openB.Position, false
        end
    end)
    local wd, wds, wsp = false, nil, nil
    side.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            wd, wds, wsp = true, i.Position, win.Position
        end
    end)
    connect(UIS.InputChanged, function(i)
        if not (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then return end
        if dragging then
            local d = i.Position - ds
            if d.Magnitude > 6 then moved = true end
            openB.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        elseif wd then
            local d = i.Position - wds
            win.Position = UDim2.new(wsp.X.Scale, wsp.X.Offset + d.X, wsp.Y.Scale, wsp.Y.Offset + d.Y)
        end
    end)
    connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            if dragging and not moved then win.Visible = not win.Visible end
            dragging, wd = false, false
        end
    end)
    connect(UIS.InputBegan, function(i, gp)
        if not gp and i.KeyCode == Enum.KeyCode.RightShift then win.Visible = not win.Visible end
    end)
end

connect(UIS.InputBegan, function(i, gp)
    if gp or UIS:GetFocusedTextBox() or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    for key, code in pairs(CFG.binds) do
        if code == i.KeyCode.Name and CFG[key] ~= nil then
            CFG[key] = not CFG[key]
            save()
            refresh()
        end
    end
end)

connect(UIS.InputBegan, function(i, gp)
    if gp or UIS:GetFocusedTextBox() or i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if not (CFG.aa and CFG.aaYaw == "Manual") then return end
    local k = string.upper(i.KeyCode.Name)
    local dir
    if k == string.upper(CFG.aaKeyL) then dir = "Left"
    elseif k == string.upper(CFG.aaKeyR) then dir = "Right"
    elseif k == string.upper(CFG.aaKeyB) then dir = "Back"
    elseif k == string.upper(CFG.aaKeyF) then dir = "Front" end
    if dir then
        CFG.aaManual = (CFG.aaManual == dir and dir ~= "Back") and "Back" or dir
        save()
        refresh()
    end
end)

local over = new("ScreenGui", {Name = "ZenithCBOverlay", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 30}, nil)
pcall(function() over.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not over.Parent then over.Parent = lp:WaitForChild("PlayerGui") end
local wmF = new("Frame", {Position = UDim2.fromOffset(14, 60), Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
    BackgroundColor3 = BG, BackgroundTransparency = 0.35, Active = true}, over)
round(wmF, 6)
local wmStroke = new("UIStroke", {Color = acc(), Transparency = 0.5}, wmF)
new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, wmF)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder}, wmF)
local wmIcon = new("ImageLabel", {Image = "rbxassetid://" .. MENU_IMG, ScaleType = Enum.ScaleType.Crop, BackgroundColor3 = BG, BorderSizePixel = 0,
    Size = UDim2.fromOffset(18, 18), LayoutOrder = -3}, wmF)
round(wmIcon, 5)
task.spawn(function()
    local t0 = tick()
    while not wmIcon.IsLoaded and tick() - t0 < 3 do task.wait(0.1) end
    if not wmIcon.IsLoaded then wmIcon.Image = "rbxthumb://type=Asset&id=" .. MENU_IMG .. "&w=150&h=150" end
end)
local wmBeta = new("TextLabel", {Text = "BETA", Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = acc(), BackgroundColor3 = acc(),
    BackgroundTransparency = 0.82, Size = UDim2.fromOffset(0, 14), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = -1}, wmF)
round(wmBeta, 4)
new("UIPadding", {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)}, wmBeta)
local WMI = {}
for i, it in ipairs({{"user", "user"}, {"fps", "bolt2"}, {"ping", "wifi"}, {"ram", "chip"}, {"gb", "chip"}, {"time", "clock"}, {"sub", "clock"}}) do
    local cell = new("Frame", {Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = i}, wmF)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center}, cell)
    local sep = new("Frame", {Size = UDim2.fromOffset(1, 12), BackgroundColor3 = DIM, BackgroundTransparency = 0.5, BorderSizePixel = 0, LayoutOrder = 0}, cell)
    local ic, tint = icon(cell, it[2], 12)
    ic.LayoutOrder = 1
    tint(acc())
    refreshers[#refreshers + 1] = function() tint(acc()) end
    local t = new("TextLabel", {Text = "", Font = Enum.Font.Code, TextSize = 12, TextColor3 = TXT, BackgroundTransparency = 1,
        Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2}, cell)
    new("UIPadding", {PaddingLeft = UDim.new(0, 4)}, t)
    if it[1] == "sub" then t.Font = Enum.Font.GothamMedium end
    WMI[it[1]] = {cell = cell, t = t, sep = sep}
end
local bl = new("Frame", {Position = UDim2.new(0, 14, 0.45, 0), Size = UDim2.fromOffset(170, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = BG, BackgroundTransparency = 0.35, Active = true}, over)
round(bl, 6)
new("UIStroke", {Color = Color3.new(1, 1, 1), Transparency = 0.88}, bl)
new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, bl)
new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, bl)
local blTitle = new("TextLabel", {Text = "keybinds", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = acc(), BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0}, bl)
local blRows = {}
for _, f in ipairs({wmF, bl}) do
    local dragging, ds, sp
    f.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging, ds, sp = true, i.Position, f.Position end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    connect(UIS.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end
do
    local Stats = game:GetService("Stats")
    local frames, acc0 = 0, 0
    connect(RunService.RenderStepped, function(dt) frames, acc0 = frames + 1, acc0 + dt end)
    task.spawn(function()
        while running do
            pcall(function()
                wmF.Visible = CFG.wm
                wmStroke.Color, blTitle.TextColor3 = acc(), acc()
                wmBeta.TextColor3, wmBeta.BackgroundColor3 = acc(), acc()
                if CFG.wm then
                    local fps = acc0 > 0 and math.floor(frames / acc0 + 0.5) or 0
                    frames, acc0 = 0, 0
                    local ping = 0
                    pcall(function() ping = math.floor(lp:GetNetworkPing() * 1000 + 0.5) end)
                    local mb = 0
                    pcall(function() mb = Stats:GetTotalMemoryUsageMb() end)
                    local vals = {
                        user = {CFG.wmUser, lp.Name},
                        fps = {CFG.wmFps, fps .. " fps"},
                        ping = {CFG.wmPing, ping .. " ms"},
                        ram = {CFG.wmRam, math.floor(mb) .. " mb"},
                        gb = {CFG.wmGb, string.format("%.2f gb", mb / 1024)},
                        time = {CFG.wmTime, os.date("%H:%M:%S")},
                        sub = {CFG.wmSub, (function()
                            local left = genv.ZenithKeyLeft
                            if not left then return "подписка" end
                            if left < 0 then return "∞ подписка" end
                            left = math.max(left - (os.time() - (genv.ZenithKeyAt or os.time())), 0)
                            local d, h, m = math.floor(left / 86400), math.floor((left % 86400) / 3600), math.floor((left % 3600) / 60)
                            return (d > 0 and (d .. "д " .. h .. "ч") or (h .. "ч " .. m .. "м")) .. " подписка"
                        end)()},
                    }
                    for k, v in pairs(vals) do
                        WMI[k].cell.Visible = v[1]
                        WMI[k].t.Text = v[2]
                    end
                end

                bl.Visible = CFG.bindList and next(CFG.binds) ~= nil
                for _, r in ipairs(blRows) do r:Destroy() end
                blRows = {}
                if bl.Visible then
                    local i = 0
                    for key, code in pairs(CFG.binds) do
                        if CFG[key] ~= nil then
                            i = i + 1
                            local on = CFG[key] == true
                            local r = new("TextLabel", {Text = (LABELS[key] or key) .. "  [" .. code .. "]", Font = Enum.Font.Code, TextSize = 11,
                                TextColor3 = on and acc() or DIM, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 15),
                                TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i}, bl)
                            blRows[#blRows + 1] = r
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
end

connect(RunService.RenderStepped, function()
    if not running then return end
    cam = workspace.CurrentCamera
    if CFG.worldFov then cam.FieldOfView = CFG.fovValue end
    if CFG.silent then
        target, targetPlr, targetPos = silentPick()
    else
        target, targetPlr, targetPos = nil, nil, nil
    end

    local show = CFG.aimbot and CFG.aimShowFov and CFG.aimFov < 170
    local sshow = CFG.silent and CFG.silentShowFov and CFG.silentFov < 170
    SRING.Visible = sshow
    if sshow then
        local vp = cam.ViewportSize
        local r = math.tan(math.rad(CFG.silentFov / 2)) / math.tan(math.rad(cam.FieldOfView / 2)) * (vp.Y / 2)
        SRING.Size = UDim2.fromOffset(r * 2, r * 2)
        SRINGS.Color = target and Color3.fromRGB(255, 90, 90) or Color3.new(1, 1, 1)
    end
    RING.Visible = show
    if show then
        local vp = cam.ViewportSize
        local r = math.tan(math.rad(CFG.aimFov / 2)) / math.tan(math.rad(cam.FieldOfView / 2)) * (vp.Y / 2)
        RING.Size = UDim2.fromOffset(r * 2, r * 2)
        RINGS.Color = aimT and Color3.fromRGB(255, 90, 90) or acc()
    end
    pcall(espStep)
    pcall(grenadeStep)
    if hudStep then pcall(hudStep) end
end)

genv.ZenithCB = function()
    running = false
    genv.ZenithCBRedirect, genv.ZenithCBShotFired, genv.ZenithCBHit, genv.ZenithCBPitch = nil, nil, nil, nil
    for _, n in ipairs({"ZenithCBAim", "ZenithCBAA", "ZenithCBTP"}) do pcall(function() RunService:UnbindFromRenderStep(n) end) end
    pcall(function()
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end)
    for _, e in pairs(E) do pcall(unpaint, e) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    for _, d in ipairs(draws) do dRemove(d) end
    for _, g in ipairs({espGui, espFolder, nGui, UI, over, fx}) do pcall(function() g:Destroy() end) end
    genv.ZenithCBTrace, genv.ZenithCBShotAt = nil, nil
end

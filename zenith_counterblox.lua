-- Zenith | Counter Blox
-- Luau (Roblox executor).

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

-- key system (online): the key server checks the key, its time and the device; the answer is signed
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

local genv = (getgenv and getgenv()) or _G
if genv.ZenithCB then pcall(genv.ZenithCB) end
local running = true
local conns = {}
local function connect(sig, fn) local c = sig:Connect(fn) conns[#conns + 1] = c return c end

------------------------------------------------------------------ settings
local CFG = {
    -- silent
    silent = true, silentFov = 360, silentPart = "Head", visCheck = true, teamCheck = true, autoFire = false, autoKill = false,
    -- aimbot
    aimbot = false, aimFov = 90, aimSmooth = 6, aimPart = "Head", aimWall = true, aimTeam = true, aimShowFov = true,
    -- esp
    esp = true, box = true, boxStyle = "Corner", name = true, avatar = true, health = true, dist = true, weapon = true, weaponIcon = true,
    tracers = false, skeleton = false, espTeam = false, espCol = "Red", teamCol = "Blue",
    gESP = true, gTracer = false, gChams = true, gIcon = true,
    -- chams
    chams = false, chamsStyle = "Glow", chamsCol = "Red", chamsFill = 0.55, chamsOutline = 0.1, chamsMode = "Walls",
    selfChams = false, weaponChams = false, gloveChams = false, myStyle = "ForceField", myCol = "Purple", wpnCol = "Mint", gloveCol = "Pink",
    -- notify
    hitNotify = true, killNotify = true,
    hitSnd = false, killSnd = true, hitSndPick = "Click", killSndPick = "Ding", hitSndId = "", killSndId = "", sndVol = 0.8,
    -- misc
    aa = false, aaYaw = "Spin", aaPitch = "Down", aaSpeed = 20, aaAir = false, aaAirSpeed = 30, aaAirPitch = "None",
    bhop = false, bhopSpeed = 26, third = false, thirdDist = 10,
    accent = "Mint", menuBg = "Geometry",
    skyOn = false, sky = "", skyId = "", fullbright = false, cfgName = "",
    wm = true, wmUser = true, wmFps = true, wmPing = true, wmRam = true, wmGb = false, wmTime = true,
    binds = {}, bindList = true,
    chamsHealth = false, worldFov = false, fovValue = 90, gTrail = true,
    tracer = false, tracerType = "Neon", tracerCol = "Mint", tracerTime = 0.8, blood = false, killFx = "Ghost",
}
local DIR, FILE = "ZenithCB", "ZenithCB/config2.json"
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
    Pink = Color3.fromRGB(255, 110, 190), White = Color3.fromRGB(240, 240, 245),
}
local PAL_ORDER = {"Red", "Amber", "Green", "Mint", "Blue", "Purple", "Pink", "White"}
local function col(name) return PAL[name] or PAL.Red end
local function acc() return col(CFG.accent) end

------------------------------------------------------------------ helpers
local cam = workspace.CurrentCamera
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local function enemyOf(p, teamChk)
    if p == lp then return false end
    if not teamChk then return true end
    if p.Team == nil or lp.Team == nil then return true end
    return p.Team ~= lp.Team
end
local function partOf(ch, which)
    if which == "Torso" then
        return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart")
    end
    return ch:FindFirstChild("Head")
end
local function seen(part, ch)
    local ig = {cam}
    if lp.Character then ig[2] = lp.Character end
    rp.FilterDescendantsInstances = ig
    local o = cam.CFrame.Position
    local hit = workspace:Raycast(o, part.Position - o, rp)
    return hit == nil or hit.Instance:IsDescendantOf(ch)
end
-- angle between where you look and the target, in degrees (fov up to 360 = all around you)
local function angleTo(pos)
    local d = pos - cam.CFrame.Position
    if d.Magnitude < 0.01 then return 0 end
    return math.deg(math.acos(math.clamp(d.Unit:Dot(cam.CFrame.LookVector), -1, 1)))
end
local function pick(fov, wallCheck, teamChk, which)
    local best, bestA = nil, fov / 2
    for _, p in ipairs(Players:GetPlayers()) do
        local ch = p.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if ch and hum and hum.Health > 0 and enemyOf(p, teamChk) then
            local part = partOf(ch, which)
            if part then
                local a = angleTo(part.Position)
                if a <= bestA and (not wallCheck or seen(part, ch)) then best, bestA = part, a end
            end
        end
    end
    return best
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

------------------------------------------------------------------ silent: the game's bullet ray from your eye is pointed at the target;
-- what the ray hits is logged for hit / kill notify
local target
local last = {orig = nil, new = nil, at = 0}
local shot = nil
local function turned(origin, dir)
    local t = target
    if not (running and CFG.silent and t and t.Parent) then return nil end
    local len = dir.Magnitude
    if len < 30 then return nil end
    local u = dir.Unit
    local eye = cam.CFrame.Position
    local head = lp.Character and lp.Character:FindFirstChild("Head")
    local near = (origin - eye).Magnitude < 6 or (head and (origin - head.Position).Magnitude < 6)
    if near then
        local nu = (t.Position - origin).Unit
        last.orig, last.new, last.at = u, nu, tick()
        return nu * len
    end
    if last.orig and tick() - last.at < 0.15 and u:Dot(last.orig) > 0.9999 then
        return last.new * len
    end
    return nil
end
-- every bullet ray result: if it hit an enemy, remember it (part, through a wall or not, jumping or not)
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
genv.ZenithCBTurn = turned
-- everything standing between you and the target, so the bullet goes through it (only when visible check is off)
local wallP = RaycastParams.new()
wallP.FilterType = Enum.RaycastFilterType.Exclude
genv.ZenithCBWalls = function(origin, ignore)
    local t = target
    if not (running and CFG.silent and not CFG.visCheck and t and t.Parent) then return nil end
    local ch = t.Parent
    local list = {}
    if type(ignore) == "table" then for _, v in ipairs(ignore) do list[#list + 1] = v end end
    local base = #list
    list[#list + 1] = workspace.CurrentCamera
    if lp.Character then list[#list + 1] = lp.Character end
    for _ = 1, 12 do
        wallP.FilterDescendantsInstances = list
        local hit = workspace:Raycast(origin, t.Position - origin, wallP)
        if not hit or hit.Instance:IsDescendantOf(ch) then break end
        list[#list + 1] = hit.Instance
    end
    if #list == base + 2 or #list == base + 1 then return nil end
    return list
end
genv.ZenithCBHit = onRayHit
if hookmetamethod and getnamecallmethod and checkcaller and newcclosure and not genv.ZenithCBHooked3 then
    genv.ZenithCBHooked3 = true
    local old
    old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if self == workspace and not checkcaller() then
            local m = getnamecallmethod()
            if m == "FindPartOnRayWithIgnoreList" or m == "FindPartOnRay" or m == "FindPartOnRayWithWhitelist" or m == "findPartOnRay" then
                local args = {...}
                local n = select("#", ...)
                local ray = args[1]
                if typeof(ray) == "Ray" and genv.ZenithCBTurn then
                    local follow = last.orig ~= nil and tick() - last.at < 0.15 and ray.Direction.Magnitude > 0 and ray.Direction.Unit:Dot(last.orig) > 0.9999
                    local nd = genv.ZenithCBTurn(ray.Origin, ray.Direction)
                    if nd then
                        args[1] = Ray.new(ray.Origin, nd)
                        if m == "FindPartOnRayWithIgnoreList" and genv.ZenithCBWalls then
                            local extra = genv.ZenithCBWalls(ray.Origin, args[2])
                            if extra then args[2] = extra end
                        end
                    end
                    local a, b, c2, d2 = old(self, table.unpack(args, 1, n))
                    if a and genv.ZenithCBHit then pcall(genv.ZenithCBHit, a, follow) end
                    return a, b, c2, d2
                end
            elseif m == "Raycast" then
                local args = {...}
                local n = select("#", ...)
                if typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" and genv.ZenithCBTurn then
                    local nd = genv.ZenithCBTurn(args[1], args[2])
                    if nd then args[2] = nd end
                    local res = old(self, table.unpack(args, 1, n))
                    if res and genv.ZenithCBHit then pcall(genv.ZenithCBHit, res.Instance, false) end
                    return res
                end
            end
        end
        return old(self, ...)
    end))
end

-- the game reports each bullet that hit something through an Events remote: HitPart in older builds, HitParl in newer ones.
-- HitParl carries (hit part, hit position, ...) and the position is scrambled by the client, so it is unscrambled here.
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
                -- a wrong guess lands far away: fall back to the part that was hit
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

------------------------------------------------------------------ firing (auto fire / auto kill): the mobile fire button if there is one, else a click
local fireBtn
local function findFireButton()
    if fireBtn and fireBtn.Parent then return fireBtn end
    fireBtn = nil
    local pg = lp:FindFirstChild("PlayerGui")
    for _, d in ipairs(pg and pg:GetDescendants() or {}) do
        if d:IsA("GuiButton") and d.Visible then
            local n = string.lower(d.Name)
            if n == "fire" or n == "shoot" or string.find(n, "firebutton", 1, true) or string.find(n, "shootbutton", 1, true) then
                fireBtn = d
                break
            end
        end
    end
    return fireBtn
end
local function pressFire(down)
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then
        local b = findFireButton()
        if b and firesignal then
            pcall(function()
                if down then firesignal(b.MouseButton1Down) else firesignal(b.MouseButton1Up) end
            end)
            if not down then pcall(function() firesignal(b.Activated) end) end
            return
        end
    end
    if down and mouse1press then pcall(mouse1press) return end
    if not down and mouse1release then pcall(mouse1release) return end
    local vp = cam.ViewportSize
    pcall(function() game:GetService("VirtualInputManager"):SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, down, game, 0) end)
end
local held, tapAt = false, 0
connect(RunService.Heartbeat, function()
    if not running then return end
    local want = (CFG.autoFire or CFG.autoKill) and target and target.Parent
    if want and not UIS:GetFocusedTextBox() then
        local now = tick()
        if held and now - tapAt > 0.07 then
            held = false
            pressFire(false)
        elseif not held and now - tapAt > 0.11 then
            tapAt, held = now, true
            pressFire(true)
        end
    elseif held then
        held = false
        pressFire(false)
    end
end)

------------------------------------------------------------------ aimbot: the camera eases onto the target after the game moves it
local aimT
RunService:BindToRenderStep("ZenithCBAim", Enum.RenderPriority.Camera.Value + 2, function()
    if not (running and CFG.aimbot) then aimT = nil return end
    aimT = pick(CFG.aimFov, CFG.aimWall, CFG.aimTeam, CFG.aimPart)
    if not aimT then return end
    local c = workspace.CurrentCamera
    local goal = CFrame.lookAt(c.CFrame.Position, aimT.Position)
    c.CFrame = c.CFrame:Lerp(goal, 1 / math.max(CFG.aimSmooth, 1))
end)

------------------------------------------------------------------ anti-aim: yaw = your body turned (everybody sees it), pitch through Events.ControlTurn
local aa = {spin = 0, flip = false, pflip = false, wasOn = false, lastPitchAt = 0}
local function wrapA(a) return (a + math.pi) % (2 * math.pi) - math.pi end
local function aaPitchValue()
    if not (running and CFG.aa) then return nil end
    local _, hum = myState()
    local air = hum and hum.FloorMaterial == Enum.Material.Air
    local pm = (CFG.aaAir and air) and CFG.aaAirPitch or CFG.aaPitch
    if pm == "Down" then return -1.5
    elseif pm == "Up" then return 1.5
    elseif pm == "Jitter" then aa.pflip = not aa.pflip return aa.pflip and 1.5 or -1.5 end
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
    elseif mode == "Jitter" then
        aa.flip = not aa.flip
        yaw = yaw0 + math.pi + (aa.flip and 1 or -1) * math.rad(60)
    elseif mode == "Side" then
        yaw = yaw0 + math.pi / 2
    else
        yaw = yaw0 + math.pi
    end
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
    local pm = (CFG.aaAir and air) and CFG.aaAirPitch or CFG.aaPitch
    local tilt = 0
    if pm == "Down" then tilt = -math.rad(80)
    elseif pm == "Up" then tilt = math.rad(70)
    elseif pm == "Jitter" then aa.lflip = not aa.lflip tilt = aa.lflip and -math.rad(80) or math.rad(70) end
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

------------------------------------------------------------------ bhop: while you hold jump; jumps on landing and keeps speed in the air
connect(UIS.JumpRequest, function() genv.ZenithCBJumpAt = tick() end)
connect(RunService.RenderStepped, function()
    if not (running and CFG.bhop) or UIS:GetFocusedTextBox() then return end
    local _, hum, hrp = myState()
    if not (hum and hrp and hum.Health > 0) then return end
    local wants = UIS:IsKeyDown(Enum.KeyCode.Space) or (tick() - (genv.ZenithCBJumpAt or 0) < 0.25) or hum.Jump
    if not wants then return end
    local stt = hum:GetState()
    local onGround = hum.FloorMaterial ~= Enum.Material.Air and stt ~= Enum.HumanoidStateType.Freefall and stt ~= Enum.HumanoidStateType.Jumping
    if onGround then
        if tick() - (genv.ZenithCBHopAt or 0) > 0.15 then
            genv.ZenithCBHopAt = tick()
            hum.Jump = true
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    elseif hum.MoveDirection.Magnitude > 0.1 and CFG.bhopSpeed > 16 then
        local v = hrp.AssemblyLinearVelocity
        local hv = Vector3.new(v.X, 0, v.Z)
        local speed = math.min(math.max(CFG.bhopSpeed, hv.Magnitude), CFG.bhopSpeed * 1.15)
        local want = hum.MoveDirection.Unit * speed
        local nv = hv:Lerp(want, 0.12)
        hrp.AssemblyLinearVelocity = Vector3.new(nv.X, v.Y, nv.Z)
    end
end)

------------------------------------------------------------------ third person
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

------------------------------------------------------------------ chams on yourself, your gun and your gloves / arms (your screen)
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
                    if string.find(n, "glove", 1, true) then
                        paint(d, CFG.gloveChams, col(CFG.gloveCol))
                    elseif isArm(d.Name) or (d.Parent and isArm(d.Parent.Name)) then
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

------------------------------------------------------------------ world: skyboxes (toolbox sky models, or any id you paste), fullbright
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
-- a pasted id: a sky model, or a single picture put on all six sides (anime girls, wallpapers...)
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


------------------------------------------------------------------ drawing: Drawing API, plain GUI if the executor has none
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

------------------------------------------------------------------ weapon pictures (first image in ReplicatedStorage.Weapons[name])
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

------------------------------------------------------------------ player esp
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
    -- avatar left of the name, weapon picture under the box
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
    for k = 1, 14 do
        local b = bones[k]
        local okDraw = false
        if CFG.skeleton and b then
            local p1, p2 = ch:FindFirstChild(b[1]), ch:FindFirstChild(b[2])
            if p1 and p2 and p1:IsA("BasePart") and p2:IsA("BasePart") then
                local a1, s1 = cam:WorldToViewportPoint(p1.Position)
                local a2, s2 = cam:WorldToViewportPoint(p2.Position)
                if s1 and s2 then setL(e.s[k], Vector2.new(a1.X, a1.Y), Vector2.new(a2.X, a2.Y), Color3.new(1, 1, 1)) okDraw = true end
            end
        end
        if not okDraw then hideL(e.s[k]) end
    end
    if CFG.health then
        local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        setL(e.hpb, Vector2.new(x - 5, y1 - 1), Vector2.new(x - 5, y2 + 1), Color3.new(0, 0, 0))
        setL(e.hpf, Vector2.new(x - 5, y1 + hgt * (1 - frac)), Vector2.new(x - 5, y2), Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(80, 255, 100), frac))
        local hc = (frac > 0.6) and Color3.fromRGB(90, 235, 110) or (frac > 0.3) and Color3.fromRGB(255, 160, 50) or Color3.fromRGB(255, 60, 60)
        setT(e.hpT, tostring(math.floor(hum.Health)), Vector2.new(x - 12, y1 + hgt * (1 - frac)), hc)
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

------------------------------------------------------------------ grenade esp (only thrown ones that fly), picture + type + distance
local GKIND = {
    {"flash", "flashbang", Color3.fromRGB(245, 245, 250), "Flashbang"},
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
local function isThrown(x)
    if not (x:IsA("BasePart") or x:IsA("Model")) then return false end
    local named = gkind(x.Name) or (x.Parent and x.Parent ~= workspace and gkind(x.Parent.Name))
    if not named then return false end
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
    -- thrown = moving sideways fast within the first 0.6 s (a weapon dropped on death only falls)
    local fast = false
    for _ = 1, 12 do
        if not x.Parent then return end
        local bp = partOfG(x)
        if bp then
            local v = bp.AssemblyLinearVelocity
            if Vector3.new(v.X, 0, v.Z).Magnitude > 9 then fast = true break end
        end
        task.wait(0.05)
    end
    if not fast or GLIVE[x] then return end
    -- a part inside a grenade model: the model is tracked instead
    if x:IsA("BasePart") and x.Parent and x.Parent:IsA("Model") and gkind(x.Parent.Name) then
        if GLIVE[x.Parent] then return end
        x = x.Parent
    end
    local e = table.remove(GPOOL)
    if not e then return end
    e.label, e.col, e.wname = gkind(x.Name)
    if not e.label and x.Parent then e.label, e.col, e.wname = gkind(x.Parent.Name) end
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
            -- remember where it has been (a dot every 0.06 s, the last 11)
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

------------------------------------------------------------------ effects: bullet tracers (neon / lightning), blood on hit, kill effects
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
-- red drops flying out of a point and falling
local function bloodBurst(pos, count, size)
    local parts = {}
    for _ = 1, count do
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Anchored, p.CanCollide, p.CastShadow = false, false, false
        pcall(function() p.CanQuery, p.CanTouch = false, false end)
        p.Material = Enum.Material.SmoothPlastic
        p.Color = Color3.fromRGB(math.random(120, 170), 0, 0)
        local s = size * (0.6 + math.random() * 0.8)
        p.Size = Vector3.new(s, s, s)
        p.CFrame = CFrame.new(pos)
        p.Parent = fx
        p.AssemblyLinearVelocity = Vector3.new((math.random() - 0.5) * 14, math.random() * 10 + 3, (math.random() - 0.5) * 14)
        parts[#parts + 1] = p
    end
    task.delay(1.2, function() fadeOut(parts, 0.6) end)
end
local function ghost(ch)
    local ok, cl = pcall(function() ch.Archivable = true return ch:Clone() end)
    if not ok or not cl then return end
    local c = acc()
    for _, d in ipairs(cl:GetDescendants()) do
        if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") or d:IsA("JointInstance") or d:IsA("Sound") or d:IsA("Decal") or d:IsA("SurfaceAppearance") then
            pcall(function() d:Destroy() end)
        elseif d:IsA("BasePart") then
            d.Anchored, d.CanCollide = true, false
            pcall(function() d.CanQuery, d.CanTouch = false, false end)
            d.Material, d.Color = Enum.Material.ForceField, c
            if d.Name == "HumanoidRootPart" then d.Transparency = 1 end
        end
    end
    cl.Parent = fx
    task.spawn(function()
        local start = cl:GetPivot()
        local t0 = tick()
        while tick() - t0 < 1.5 and cl.Parent do
            local k = (tick() - t0) / 1.5
            pcall(function() cl:PivotTo(start * CFrame.new(0, k * 12, 0) * CFrame.Angles(0, k * 2, 0)) end)
            for _, d in ipairs(cl:GetDescendants()) do
                if d:IsA("BasePart") and d.Transparency < 1 then d.Transparency = math.max(d.Transparency, k) end
            end
            RunService.Heartbeat:Wait()
        end
        pcall(function() cl:Destroy() end)
    end)
end
local function killEffect(s)
    local ch = s.ch or (s.p and s.p.Character)
    if CFG.killFx == "Ghost" and ch then ghost(ch)
    elseif CFG.killFx == "Blood" then
        local r = ch and ch:FindFirstChild("HumanoidRootPart")
        bloodBurst(r and r.Position or s.pos, 26, 0.45)
    end
end

------------------------------------------------------------------ hit / kill feed (avatar, damage, body part, distance) and hit / kill sounds
-- damage is read from the enemy's Humanoid.HealthChanged; it counts as yours when a bullet of yours was just reported
-- (Events.HitPart), or you are holding fire with the enemy in front of you. Set getgenv().ZenithDebug = true to print why a hit was skipped.
local nGui = Instance.new("ScreenGui")
nGui.Name = "ZenithCBNotify"
nGui.IgnoreGuiInset = true
nGui.ResetOnSpawn = false
nGui.DisplayOrder = 40
pcall(function() nGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not nGui.Parent then nGui.Parent = lp:WaitForChild("PlayerGui") end
local playSnd
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

    -------------------------------------------------------------- sounds
    -- built-in client sounds; each entry is tried until one actually loads. "Custom" plays the audio id typed in the menu.
    local SOUND_SRC = {
        Ding  = {"rbxasset://sounds/electronicpingshort.wav", "rbxasset://sounds/button.wav"},
        Click = {"rbxasset://sounds/clickfast.wav", "rbxasset://sounds/button.wav"},
        Cash  = {"rbxasset://sounds/kerching.mp3", "rbxasset://sounds/electronicpingshort.wav"},
    }
    local sndCache, sndBusy = {}, {}
    local function resolve(pick, custom)
        local list
        if pick == "Custom" then
            local id = tostring(custom or ""):match("%d+")
            list = id and {"rbxassetid://" .. id} or {}
            for _, s in ipairs(SOUND_SRC.Ding) do list[#list + 1] = s end
        else
            list = SOUND_SRC[pick] or SOUND_SRC.Ding
        end
        local key = table.concat(list, ",")
        while sndBusy[key] do task.wait(0.03) end
        if sndCache[key] ~= nil then return sndCache[key] or nil end
        sndBusy[key] = true
        local found
        for _, id in ipairs(list) do
            local s = Instance.new("Sound")
            s.Name = "ZenithSnd"
            s.SoundId = id
            s.Volume = 0
            s.Parent = SoundService
            pcall(function() ContentProvider:PreloadAsync({s}) end)
            if s.TimeLength > 0 then found = s break end
            dbg("sound did not load:", id)
            s:Destroy()
        end
        sndCache[key] = found or false
        sndBusy[key] = nil
        return found
    end
    playSnd = function(kind)
        local isKill = kind == "kill"
        local pick = isKill and CFG.killSndPick or CFG.hitSndPick
        local custom = isKill and CFG.killSndId or CFG.hitSndId
        task.spawn(function()
            local base = resolve(pick, custom)
            if not base or not running then return end
            local s = base:Clone()
            s.Volume = CFG.sndVol
            s.PlaybackSpeed = isKill and 1 or 1.18
            s.Parent = SoundService
            s:Play()
            task.delay(math.max(base.TimeLength, 0.4) + 0.4, function() pcall(function() s:Destroy() end) end)
        end)
    end
    -- load the picked sounds now so the first kill is not late
    task.spawn(function()
        resolve(CFG.hitSndPick, CFG.hitSndId)
        resolve(CFG.killSndPick, CFG.killSndId)
    end)

    -------------------------------------------------------------- feed
    local KILL_RED = Color3.fromRGB(255, 72, 84)
    local feed = put("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 120), Size = UDim2.fromOffset(270, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, nGui)
    put("UIListLayout", {Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder}, feed)

    local PART = {Head = "Head", UpperTorso = "Chest", Torso = "Chest", LowerTorso = "Stomach", HumanoidRootPart = "Stomach"}
    local function partName(n)
        if PART[n] then return PART[n] end
        if string.find(n, "Arm") or string.find(n, "Hand") then return "Arm" end
        if string.find(n, "Leg") or string.find(n, "Foot") then return "Leg" end
        return "Body"
    end

    local live, order = {}, 0
    local function dismiss(e)
        if e.dead then return end
        e.dead = true
        for i, v in ipairs(live) do if v == e then table.remove(live, i) break end end
        pcall(function()
            TweenService:Create(e.card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {GroupTransparency = 1, Position = UDim2.fromOffset(36, 0)}):Play()
        end)
        task.delay(0.25, function() pcall(function() e.wrap:Destroy() end) end)
    end

    local function showCard(kind, d)
        order = order + 1
        local isKill = kind == "kill"
        local accent = isKill and KILL_RED or acc()
        local wrap = put("Frame", {Size = UDim2.fromOffset(270, 46), BackgroundTransparency = 1, LayoutOrder = -order}, feed)
        local card = put("CanvasGroup", {Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(36, 0), GroupTransparency = 1,
            BackgroundColor3 = Color3.fromRGB(13, 13, 17), BackgroundTransparency = 0.06, BorderSizePixel = 0}, wrap)
        put("UICorner", {CornerRadius = UDim.new(0, 8)}, card)
        local bar = put("Frame", {Position = UDim2.fromOffset(0, 7), Size = UDim2.new(0, 3, 1, -14), BackgroundColor3 = accent, BorderSizePixel = 0}, card)
        put("UICorner", {CornerRadius = UDim.new(1, 0)}, bar)
        local av = put("ImageLabel", {Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = Color3.fromRGB(28, 28, 34),
            BorderSizePixel = 0, Image = "rbxthumb://type=AvatarHeadShot&id=" .. d.p.UserId .. "&w=60&h=60"}, card)
        put("UICorner", {CornerRadius = UDim.new(1, 0)}, av)

        local sub = partName(d.part) .. ", " .. d.dist .. " studs"
        if d.jump then sub = sub .. ", jump" end
        if d.wall then sub = sub .. ", wallbang" end
        put("TextLabel", {Text = d.p.DisplayName, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
            Position = UDim2.fromOffset(52, 6), Size = UDim2.new(1, -128, 0, 17), TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd}, card)
        put("TextLabel", {Text = sub, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(150, 152, 162), BackgroundTransparency = 1,
            Position = UDim2.fromOffset(52, 23), Size = UDim2.new(1, -128, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd}, card)
        put("TextLabel", {Text = isKill and "KILL" or ("-" .. math.floor(d.dmg + 0.5)), Font = Enum.Font.GothamBold, TextSize = isKill and 14 or 17,
            TextColor3 = accent, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 5),
            Size = UDim2.fromOffset(70, 20), TextXAlignment = Enum.TextXAlignment.Right}, card)
        put("TextLabel", {Text = isKill and tostring(d.weapon) or (math.floor(d.left + 0.5) .. " left"), Font = Enum.Font.Gotham, TextSize = 10,
            TextColor3 = Color3.fromRGB(125, 127, 138), BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 25),
            Size = UDim2.fromOffset(70, 13), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd}, card)
        if not isKill and d.maxhp and d.maxhp > 0 then
            local track = put("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 52, 1, -4), Size = UDim2.new(1, -66, 0, 2),
                BackgroundColor3 = Color3.fromRGB(38, 39, 46), BorderSizePixel = 0}, card)
            put("Frame", {Size = UDim2.fromScale(math.clamp(d.left / d.maxhp, 0, 1), 1), BackgroundColor3 = accent, BorderSizePixel = 0}, track)
        end

        local e = {wrap = wrap, card = card}
        live[#live + 1] = e
        while #live > 5 do dismiss(live[1]) end
        TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}):Play()
        task.delay(isKill and 4.5 or 3, function() dismiss(e) end)
    end

    -------------------------------------------------------------- whose damage is it
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
        if (CFG.autoFire or CFG.autoKill) and target and target.Parent == hum.Parent then return true end
        if not hookSeen and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            return r ~= nil and angleTo(r.Position) < 50
        end
        return false
    end

    -- what we know about the shot right now (the body is gone by the time a kill is shown)
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

    -- several pellets of one shot land in the same instant: they become one card
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
            if CFG.blood and d.pos then pcall(bloodBurst, d.pos, 10, 0.3) end
            if q.killed then
                pcall(killEffect, d)
                if CFG.killNotify then pcall(showCard, "kill", d) end
                if CFG.killSnd then playSnd("kill") end
            else
                if CFG.hitNotify then pcall(showCard, "hit", d) end
                if CFG.hitSnd then playSnd("hit") end
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

------------------------------------------------------------------ menu: sidebar with pictures on the left, cards on the right
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

-- small pictures made of shapes (tinted with the accent)
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

-- fov ring of the aimbot
local RING = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Visible = false}, UI)
round(RING, 999)
local RINGS = new("UIStroke", {Color = acc(), Transparency = 0.35, Thickness = 1}, RING)

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
-- the picture that sits on top of the menu: pops up every time the menu opens
local MENU_IMG = 72799844056549
do
    local base = UDim2.new(1, -78, 0, 8)
    local topImg = new("ImageLabel", {BackgroundTransparency = 1, Image = "rbxassetid://" .. MENU_IMG, ScaleType = Enum.ScaleType.Fit,
        AnchorPoint = Vector2.new(0.5, 1), Position = base, Size = UDim2.fromOffset(132, 132), ImageTransparency = 1, ZIndex = 20}, win)
    task.spawn(function()
        local t0 = tick()
        while not topImg.IsLoaded and tick() - t0 < 3 do task.wait(0.1) end
        -- a decal id does not show in an ImageLabel: use its thumbnail then
        if not topImg.IsLoaded then topImg.Image = "rbxthumb://type=Asset&id=" .. MENU_IMG .. "&w=420&h=420" end
    end)
    local function pop()
        topImg.ImageTransparency = 1
        topImg.Position = base + UDim2.fromOffset(0, 22)
        TweenService:Create(topImg, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {ImageTransparency = 0, Position = base}):Play()
    end
    connect(win:GetPropertyChangedSignal("Visible"), function() if win.Visible then pop() end end)
end

-- background shapes (geometry / space / triangles), clipped to the window
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
                -- a triangle drawn as three thin sides
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
local logoBox = new("Frame", {Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = acc()}, side)
round(logoBox, 8)
local logoZ = new("TextLabel", {Text = "Z", Font = Enum.Font.Michroma, TextSize = 15, TextColor3 = Color3.fromRGB(12, 12, 14), BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1)}, logoBox)
new("TextLabel", {Text = "zenith", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = TXT, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(50, 14), Size = UDim2.fromOffset(70, 16), TextXAlignment = Enum.TextXAlignment.Left}, side)
new("TextLabel", {Text = "counter blox", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = DIM, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(50, 30), Size = UDim2.fromOffset(70, 12), TextXAlignment = Enum.TextXAlignment.Left}, side)
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
                    -- key row: tap, then press a key (Backspace clears)
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
        Position = UDim2.fromOffset(2, 0), Size = UDim2.new(0.34, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left}, f)
    local box = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.new(0.66, -4, 0, 24),
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

-- pages
local pAim = tab("aim", "aim", 1)
local pVis = tab("visuals", "eye", 2)
local pWorld = tab("world", "sun", 3)
local pMisc = tab("misc", "move", 4)
local pSet = tab("settings", "gear", 5)

section(pAim, "SILENT")
toggle(pAim, "silent aim", "silent", "aim", function(b)
    choice(b, "aim at", "silentPart", {"Head", "Torso"})
    slider(b, "fov", "silentFov", 10, 360, 5, "°")
    toggle(b, "visible check", "visCheck")
    toggle(b, "team check", "teamCheck")
    toggle(b, "auto fire", "autoFire")
    toggle(b, "auto kill", "autoKill")
end)
section(pAim, "AIMBOT")
toggle(pAim, "aimbot", "aimbot", "user", function(b)
    choice(b, "aim at", "aimPart", {"Head", "Torso"})
    slider(b, "fov", "aimFov", 10, 360, 5, "°")
    slider(b, "smooth", "aimSmooth", 1, 20, 1)
    toggle(b, "wall check", "aimWall")
    toggle(b, "team check", "aimTeam")
    toggle(b, "draw fov", "aimShowFov")
end)
section(pAim, "ANTI-AIM")
toggle(pAim, "anti-aim", "aa", "shield", function(b)
    choice(b, "yaw", "aaYaw", {"Spin", "Jitter", "Back", "Side"})
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
toggle(pVis, "health bar", "health")
toggle(pVis, "distance", "dist")
toggle(pVis, "weapon", "weapon", "gun", function(b) toggle(b, "weapon icon", "weaponIcon") end)
toggle(pVis, "skeleton", "skeleton")
section(pVis, "EFFECTS")
toggle(pVis, "bullet tracers", "tracer", "bolt2", function(b)
    choice(b, "type", "tracerType", {"Neon", "Lightning"})
    colors(b, "color", "tracerCol")
    slider(b, "time", "tracerTime", 0.2, 3, 0.1, "s")
end)
toggle(pVis, "blood on hit", "blood", "drop")
do
    local f = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = CARD, LayoutOrder = nextOrder()}, pVis)
    round(f, 8)
    new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)}, f)
    new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, f)
    choice(f, "kill effect", "killFx", {"None", "Ghost", "Blood"})
end
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
section(pMisc, "NOTIFY")
toggle(pMisc, "hit notify", "hitNotify", "bell")
toggle(pMisc, "kill notify", "killNotify", "bell")
section(pMisc, "SOUND")
toggle(pMisc, "hit sound", "hitSnd", "bell", function(b)
    choice(b, "sound", "hitSndPick", {"Ding", "Click", "Cash", "Custom"})
    input(b, "audio id", "hitSndId", "for custom")
    button(b, "test", function() if playSnd then playSnd("hit") end end)
end)
toggle(pMisc, "kill sound", "killSnd", "bell", function(b)
    choice(b, "sound", "killSndPick", {"Ding", "Click", "Cash", "Custom"})
    input(b, "audio id", "killSndId", "for custom")
    slider(b, "volume", "sndVol", 0.1, 1, 0.05)
    button(b, "test", function() if playSnd then playSnd("kill") end end)
end)
section(pMisc, "MOVEMENT")
toggle(pMisc, "bhop", "bhop", "move", function(b) slider(b, "air speed", "bhopSpeed", 16, 60, 1) end)


section(pSet, "MENU")
colors(pSet, "accent", "accent", function()
    drawBg()
    logoBox.BackgroundColor3 = acc()
    openS.Color, openL.TextColor3 = acc(), acc()
    for _, p in pairs(pages) do p.ScrollBarImageColor3 = acc() end
    refresh()
    for n, p in pairs(pages) do if p.Visible then selectTab(n) end end
end)
choice(pSet, "background", "menuBg", {"None", "Geometry", "Space", "Triangles"})
do
    -- redraw the background when it changes
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
end)
toggle(pSet, "keybind list", "bindList", "gear")
section(pSet, "CONFIGS")
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
    input(pSet, "name", "cfgName", "config name")
    local list = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, pSet)
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
    button(pSet, "save config", function()
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
selectTab("aim")

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

------------------------------------------------------------------ binds: the key flips its function
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

------------------------------------------------------------------ watermark (drag it) and keybind list
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
local wmLogo = new("TextLabel", {Text = "zenith", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = acc(), BackgroundTransparency = 1,
    Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 0}, wmF)
local WMI = {}
for i, it in ipairs({{"user", "user"}, {"fps", "bolt2"}, {"ping", "wifi"}, {"ram", "chip"}, {"gb", "chip"}, {"time", "clock"}}) do
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
                wmStroke.Color, wmLogo.TextColor3, blTitle.TextColor3 = acc(), acc(), acc()
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
                    }
                    for k, v in pairs(vals) do
                        WMI[k].cell.Visible = v[1]
                        WMI[k].t.Text = v[2]
                    end
                end
                -- keybind list: every bound function and whether it is on
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

------------------------------------------------------------------ every frame
connect(RunService.RenderStepped, function()
    if not running then return end
    cam = workspace.CurrentCamera
    if CFG.worldFov then cam.FieldOfView = CFG.fovValue end
    if CFG.silent or CFG.autoFire or CFG.autoKill then
        if CFG.autoKill then
            target = pick(360, false, CFG.teamCheck, CFG.silentPart)
        else
            target = pick(CFG.silentFov, CFG.visCheck, CFG.teamCheck, CFG.silentPart)
        end
    else
        target = nil
    end
    -- the aimbot fov drawn as a circle (only while it fits on screen)
    local show = CFG.aimbot and CFG.aimShowFov and CFG.aimFov < 170
    RING.Visible = show
    if show then
        local vp = cam.ViewportSize
        local r = math.tan(math.rad(CFG.aimFov / 2)) / math.tan(math.rad(cam.FieldOfView / 2)) * (vp.Y / 2)
        RING.Size = UDim2.fromOffset(r * 2, r * 2)
        RINGS.Color = aimT and Color3.fromRGB(255, 90, 90) or acc()
    end
    pcall(espStep)
    pcall(grenadeStep)
end)

genv.ZenithCB = function()
    running = false
    genv.ZenithCBTurn, genv.ZenithCBHit, genv.ZenithCBPitch = nil, nil, nil
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
    pcall(function()
        for _, s in ipairs(game:GetService("SoundService"):GetChildren()) do
            if s:IsA("Sound") and s.Name == "ZenithSnd" then s:Destroy() end
        end
    end)
end

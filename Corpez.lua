--==================================================
-- CORPEZ HAX — FIXED FULL SCRIPT
-- Immortal: SetStateEnabled fix + StateChanged guard
-- Kill All: separate, does not touch LocalPlayer
--==================================================

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer   = Players.LocalPlayer

--==================================================
-- RAYFIELD
--==================================================

local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/rayfield"
))()

local Window = Rayfield:CreateWindow({
    Name             = "Corpez Hax",
    LoadingTitle     = "Corpez Hax",
    LoadingSubtitle  = "by CORPEZ",
    ConfigurationSaving = { Enabled = false },
    Discord          = { Enabled = false },
    KeySystem        = false,
})

--==================================================
-- TABS
--==================================================

local Advantages = Window:CreateTab("Advantages", 4483362458)
Advantages:CreateSection("Corpez Hax Advantages")

local Universal = Window:CreateTab("Universal", 4483362458)
Universal:CreateSection("Universal Player Tools")

local Credits = Window:CreateTab("Credits", 4483362458)
Credits:CreateSection("Corpez Hax Credits")

--==================================================
-- TEAM CHECK
--==================================================

local function isEnemy(player)
    if not LocalPlayer.Team or not player.Team then return true end
    return player.Team ~= LocalPlayer.Team
end

--==================================================
-- ESP
--==================================================

local ESPEnabled = false
local Highlights  = {}

local function clearESP()
    for player, h in pairs(Highlights) do
        if h then h:Destroy() end
        Highlights[player] = nil
    end
end

local function addESP(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    if Highlights[player] then Highlights[player]:Destroy() end

    local h = Instance.new("Highlight")
    h.Name        = "CorpezESP"
    h.Adornee     = character
    h.FillColor   = isEnemy(player)
        and Color3.fromRGB(255, 0, 0)
        or  Color3.fromRGB(170, 0, 255)
    h.OutlineColor = isEnemy(player)
        and Color3.fromRGB(255, 100, 100)
        or  Color3.fromRGB(255, 150, 255)
    h.FillTransparency    = 0.45
    h.OutlineTransparency = 0
    h.DepthMode   = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent      = character
    Highlights[player] = h
end

local function updateESP()
    clearESP()
    if not ESPEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
end

Advantages:CreateToggle({
    Name         = "Purple/Red ESP",
    CurrentValue = false,
    Callback     = function(v)
        ESPEnabled = v
        updateESP()
    end,
})

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPEnabled then addESP(p) end
    end)
end)

--==================================================
-- WALL HACK (nametags)
--==================================================

local WallHackEnabled    = false
local WallHackBillboards = {}

local function removeWallHack(player)
    if WallHackBillboards[player] then
        WallHackBillboards[player]:Destroy()
        WallHackBillboards[player] = nil
    end
end

local function addWallHack(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    removeWallHack(player)

    local bb = Instance.new("BillboardGui")
    bb.Name         = "CorpezWH"
    bb.Adornee      = root
    bb.Size         = UDim2.new(0, 120, 0, 40)
    bb.StudsOffset  = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop  = true
    bb.Parent       = root

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3      = Color3.fromRGB(0, 0, 0)
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextSize              = 14
    lbl.Text                  = player.Name
    lbl.TextColor3            = isEnemy(player)
        and Color3.fromRGB(255, 80, 80)
        or  Color3.fromRGB(255, 80, 255)
    lbl.Parent = bb
    WallHackBillboards[player] = bb
end

local function updateWallHack()
    for p, bb in pairs(WallHackBillboards) do
        if bb then bb:Destroy() end
        WallHackBillboards[p] = nil
    end
    if not WallHackEnabled then return end
    for _, p in ipairs(Players:GetPlayers()) do addWallHack(p) end
end

Advantages:CreateToggle({
    Name         = "Wall Hack",
    CurrentValue = false,
    Callback     = function(v)
        WallHackEnabled = v
        updateWallHack()
    end,
})

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if WallHackEnabled then addWallHack(p) end
    end)
end)

--==================================================
-- ██ TRUE IMMORTAL — FIXED ██
--
-- ROOT CAUSE NG DATI:
--   (1) Walang SetStateEnabled(Dead, false)
--       → kahit locked ang Health, papasok pa rin
--         sa Dead state ang humanoid dahil server
--         triggers it. HealthChanged alone ≠ enough.
--   (2) disableLocalScripts() → dangerous, breaks
--       character tools/anims, hindi rin niya
--       nahaharang ang server-side damage.
--       Tinanggal na.
--   (3) sweepExplosives sa Heartbeat → masyadong
--       mahal, nag-iiterate sa buong workspace
--       tuwing frame. Inilipat sa hiwalay na loop.
--   (4) Walang StateChanged listener → pag naka-
--       Dead state na, walang bumabawi.
--
-- FIX:
--   • SetStateEnabled(Dead, false) — pinaka-
--     importanteng linya. Prevents humanoid
--     from entering Dead state at all.
--   • StateChanged listener — kung somehow
--     na-Dead pa rin, force-revive agad.
--   • Single Heartbeat lock — no duplicate loops.
--   • Separate explosion sweep at lower frequency.
--   • Clean disconnect on stop.
--==================================================

local ImmortalEnabled = false
local _iConns         = {}  -- immortal connections only

local function _iDisconnectAll()
    for _, c in ipairs(_iConns) do
        if c then pcall(function() c:Disconnect() end) end
    end
    _iConns = {}
end

local function _applyImmune(humanoid)
    -- ① Block Dead state at the source
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

    -- ② Hard-set health
    humanoid.MaxHealth = math.huge
    humanoid.Health    = math.huge

    -- ③ HealthChanged: reset if server pushes a lower value
    local hc = humanoid.HealthChanged:Connect(function(hp)
        if ImmortalEnabled and hp < math.huge then
            humanoid.MaxHealth = math.huge
            humanoid.Health    = math.huge
        end
    end)
    table.insert(_iConns, hc)

    -- ④ StateChanged: if Dead somehow fires, force-revive
    local sc = humanoid.StateChanged:Connect(function(_, new)
        if not ImmortalEnabled then return end
        if new == Enum.HumanoidStateType.Dead then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            humanoid.MaxHealth = math.huge
            humanoid.Health    = math.huge
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
    table.insert(_iConns, sc)
end

local function _antiVoid(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local av = RunService.Heartbeat:Connect(function()
        if not ImmortalEnabled then return end
        if not root.Parent then return end
        if root.Position.Y < -100 then
            root.CFrame = CFrame.new(root.Position.X, 50, root.Position.Z)
        end
    end)
    table.insert(_iConns, av)
end

local function _explosionSweep(character)
    -- Runs at ~10Hz, not every frame — cheap
    local sweepConn
    local t = 0
    sweepConn = RunService.Heartbeat:Connect(function(dt)
        if not ImmortalEnabled then return end
        t = t + dt
        if t < 0.1 then return end
        t = 0
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Explosion") then
                if (obj.Position - root.Position).Magnitude < 60 then
                    obj.BlastPressure          = 0
                    obj.BlastRadius            = 0
                    obj.DestroyJointRadiusPercent = 0
                end
            end
        end
    end)
    table.insert(_iConns, sweepConn)
end

local function startImmortal()
    -- Wipe previous connections first — no duplicates
    _iDisconnectAll()

    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    _applyImmune(humanoid)
    _antiVoid(character)
    _explosionSweep(character)

    -- Single Heartbeat to keep health pinned every frame
    local hb = RunService.Heartbeat:Connect(function()
        if not ImmortalEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if hum.MaxHealth ~= math.huge then hum.MaxHealth = math.huge end
        if hum.Health    ~= math.huge then hum.Health    = math.huge end
    end)
    table.insert(_iConns, hb)
end

local function stopImmortal()
    ImmortalEnabled = false
    _iDisconnectAll()

    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Re-enable Dead state
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
    humanoid.MaxHealth = 100
    humanoid.Health    = 100
end

Advantages:CreateToggle({
    Name         = "Immortal (Fixed)",
    CurrentValue = false,
    Callback     = function(v)
        ImmortalEnabled = v
        if v then startImmortal() else stopImmortal() end
    end,
})

--==================================================
-- NOCLIP
--==================================================

local NoclipEnabled = false

RunService.Stepped:Connect(function()
    if not NoclipEnabled then return end
    local character = LocalPlayer.Character
    if not character then return end
    for _, p in ipairs(character:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

Advantages:CreateToggle({
    Name         = "Noclip / Wall Pass",
    CurrentValue = false,
    Callback     = function(v)
        NoclipEnabled = v
        if not v then
            local character = LocalPlayer.Character
            if not character then return end
            for _, p in ipairs(character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end,
})

--==================================================
-- AIM ASSIST — WALLBANG (no visibility check)
--==================================================

local AimEnabled    = false
local AimDistance   = 500
local AimSmoothness = 0.15

local function getClosestScreenPlayer()
    local camera   = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    local closest, closestDist = nil, AimDistance

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isEnemy(p) then
            local char = p.Character
            if char then
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    local sp, onScreen =
                        camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                        if d < closestDist then
                            closestDist = d
                            closest     = p
                        end
                    end
                end
            end
        end
    end

    return closest
end

RunService.RenderStepped:Connect(function()
    if not AimEnabled then return end
    local target = getClosestScreenPlayer()
    if not target then return end
    local char = target.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local cam = workspace.CurrentCamera
    cam.CFrame = cam.CFrame:Lerp(
        CFrame.lookAt(cam.CFrame.Position, root.Position),
        AimSmoothness
    )
end)

Advantages:CreateToggle({
    Name         = "Aim Assist (WallBang)",
    CurrentValue = false,
    Callback     = function(v) AimEnabled = v end,
})

Advantages:CreateSlider({
    Name         = "Aim Smoothness",
    Range        = {0.05, 1},
    Increment    = 0.05,
    CurrentValue = 0.15,
    Callback     = function(v) AimSmoothness = v end,
})

Advantages:CreateSlider({
    Name         = "Aim Range",
    Range        = {50, 1500},
    Increment    = 50,
    CurrentValue = 500,
    Suffix       = " px",
    Callback     = function(v) AimDistance = v end,
})

--==================================================
-- AUTO TARGET — WALLBANG
--==================================================

local AutoTargetEnabled    = false
local AutoTargetSmoothness = 0.2

local function getClosestWorldPlayer()
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closest, closestDist = nil, math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isEnemy(p) then
            local char = p.Character
            if char then
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    local d = (root.Position - myRoot.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest     = p
                    end
                end
            end
        end
    end

    return closest
end

RunService.RenderStepped:Connect(function()
    if not AutoTargetEnabled then return end
    local target = getClosestWorldPlayer()
    if not target then return end
    local char = target.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local cam = workspace.CurrentCamera
    cam.CFrame = cam.CFrame:Lerp(
        CFrame.lookAt(cam.CFrame.Position, root.Position),
        AutoTargetSmoothness
    )
end)

Advantages:CreateToggle({
    Name         = "Auto Target (WallBang)",
    CurrentValue = false,
    Callback     = function(v) AutoTargetEnabled = v end,
})

Advantages:CreateSlider({
    Name         = "Auto Target Smoothness",
    Range        = {0.05, 1},
    Increment    = 0.05,
    CurrentValue = 0.2,
    Suffix       = "x",
    Callback     = function(v) AutoTargetSmoothness = v end,
})

--==================================================
-- SPEED WALK
--==================================================

local SpeedEnabled = false
local SpeedValue   = 32
local DefaultSpeed = 16

local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = SpeedEnabled and SpeedValue or DefaultSpeed
end

Advantages:CreateToggle({
    Name         = "Speed Walk",
    CurrentValue = false,
    Callback     = function(v)
        SpeedEnabled = v
        applySpeed()
    end,
})

Advantages:CreateSlider({
    Name         = "Walk Speed",
    Range        = {16, 300},
    Increment    = 8,
    CurrentValue = 32,
    Suffix       = " speed",
    Callback     = function(v)
        SpeedValue = v
        if SpeedEnabled then applySpeed() end
    end,
})

--==================================================
-- FLY
--==================================================

local Flying                 = false
local FlySpeed               = 60
local FlyConnection          = nil
local FlyVelocity            = nil
local FlyOrientation         = nil
local FlyVelocityAttachment  = nil
local FlyOrientationAttachment = nil

local function stopFly()
    Flying = false
    if FlyConnection    then FlyConnection:Disconnect();    FlyConnection    = nil end
    if FlyVelocity      then FlyVelocity:Destroy();        FlyVelocity      = nil end
    if FlyOrientation   then FlyOrientation:Destroy();     FlyOrientation   = nil end
    if FlyVelocityAttachment   then FlyVelocityAttachment:Destroy();   FlyVelocityAttachment   = nil end
    if FlyOrientationAttachment then FlyOrientationAttachment:Destroy(); FlyOrientationAttachment = nil end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.AutoRotate = true end
end

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    stopFly()
    Flying = true
    hum.AutoRotate = false

    FlyVelocityAttachment = Instance.new("Attachment")
    FlyVelocityAttachment.Parent = root

    FlyVelocity = Instance.new("LinearVelocity")
    FlyVelocity.Attachment0    = FlyVelocityAttachment
    FlyVelocity.RelativeTo     = Enum.ActuatorRelativeTo.World
    FlyVelocity.MaxForce       = math.huge
    FlyVelocity.VectorVelocity = Vector3.zero
    FlyVelocity.Parent         = root

    FlyOrientationAttachment = Instance.new("Attachment")
    FlyOrientationAttachment.Parent = root

    FlyOrientation = Instance.new("AlignOrientation")
    FlyOrientation.Attachment0  = FlyOrientationAttachment
    FlyOrientation.Mode         = Enum.OrientationAlignmentMode.OneAttachment
    FlyOrientation.MaxTorque    = math.huge
    FlyOrientation.Responsiveness = 25
    FlyOrientation.Parent       = root

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not Flying or not root.Parent then stopFly(); return end

        local cam = workspace.CurrentCamera
        local dir = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W)           then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)           then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)           then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)           then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end

        FlyVelocity.VectorVelocity = dir.Magnitude > 0
            and dir.Unit * FlySpeed
            or  Vector3.zero

        FlyOrientation.CFrame = CFrame.lookAt(
            root.Position,
            root.Position + cam.CFrame.LookVector
        )
    end)
end

Advantages:CreateToggle({
    Name         = "Fly",
    CurrentValue = false,
    Callback     = function(v)
        if v then startFly() else stopFly() end
    end,
})

Advantages:CreateSlider({
    Name         = "Fly Speed",
    Range        = {10, 200},
    Increment    = 5,
    CurrentValue = 60,
    Suffix       = " studs/s",
    Callback     = function(v) FlySpeed = v end,
})

--==================================================
-- UNIVERSAL — HELPERS
--==================================================

Universal:CreateSection("Universal Player Tools")

local function getOtherPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p) end
    end
    return list
end

local function getRandomPlayer()
    local list = getOtherPlayers()
    if #list == 0 then return nil end
    return list[math.random(1, #list)]
end

--==================================================
-- TELEPORT RANDOM
--==================================================

Universal:CreateButton({
    Name     = "Teleport To Random",
    Callback = function()
        local t = getRandomPlayer()
        if not t then return end
        local myChar = LocalPlayer.Character
        local tChar  = t.Character
        if not myChar or not tChar then return end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        local tRoot  = tChar:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot then
            myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4)
        end
    end,
})

--==================================================
-- FLING RANDOM
--==================================================

Universal:CreateButton({
    Name     = "Fling Random",
    Callback = function()
        local t = getRandomPlayer()
        if not t then return end
        local char = t.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local att = Instance.new("Attachment")
        att.Parent = root

        local vel = Instance.new("LinearVelocity")
        vel.Attachment0    = att
        vel.RelativeTo     = Enum.ActuatorRelativeTo.World
        vel.MaxForce       = math.huge
        vel.VectorVelocity = Vector3.new(
            math.random(-150, 150), 150, math.random(-150, 150)
        )
        vel.Parent = root

        task.delay(0.35, function()
            pcall(function() vel:Destroy() end)
            pcall(function() att:Destroy() end)
        end)
    end,
})

--==================================================
-- BRING RANDOM
--==================================================

Universal:CreateButton({
    Name     = "Bring Random",
    Callback = function()
        local t = getRandomPlayer()
        if not t then return end
        local myChar = LocalPlayer.Character
        local tChar  = t.Character
        if not myChar or not tChar then return end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        local tRoot  = tChar:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot then
            tRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4)
        end
    end,
})

--==================================================
-- BRING ALL
--==================================================

Universal:CreateButton({
    Name     = "Bring All",
    Callback = function()
        local myChar = LocalPlayer.Character
        if not myChar then return end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = p.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = myRoot.CFrame * CFrame.new(
                        math.random(-5, 5), 0, math.random(-5, 5)
                    )
                end
            end
        end
    end,
})

--==================================================
-- PLAYER SPIRAL
--==================================================

local SpiralEnabled   = false
local SpiralConnection = nil
local SpiralAngle     = 0

local function stopSpiral()
    SpiralEnabled = false
    if SpiralConnection then
        SpiralConnection:Disconnect()
        SpiralConnection = nil
    end
end

local function startSpiral()
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    SpiralEnabled = true
    SpiralAngle   = 0

    SpiralConnection = RunService.Heartbeat:Connect(function(dt)
        if not SpiralEnabled then stopSpiral(); return end
        SpiralAngle = SpiralAngle + dt * 3

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = p.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = CFrame.new(
                        myRoot.Position + Vector3.new(
                            math.cos(SpiralAngle) * 8,
                            0,
                            math.sin(SpiralAngle) * 8
                        )
                    )
                end
            end
        end
    end)
end

Universal:CreateToggle({
    Name         = "Player Spiral",
    CurrentValue = false,
    Callback     = function(v)
        if v then startSpiral() else stopSpiral() end
    end,
})

--==================================================
-- ██ KILL ALL — SEPARATE FEATURE ██
--
-- Hindi naaapektuhan ang LocalPlayer o teammates.
-- Ginagamit ang dalawang approach:
--   (1) Teleport sa void (Y = -9999) → void kill
--   (2) Massive upward + random lateral velocity
--       para siguruhin ang fall damage / void entry
-- FFA mode: lahat ng iba ay target.
-- Team mode: enemies lang.
--==================================================

Universal:CreateSection("Kill All")

Universal:CreateButton({
    Name     = "Kill All (Void Drop)",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            -- Skip self
            if p == LocalPlayer then continue end
            -- Skip teammates
            if not isEnemy(p) then continue end

            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then continue end

            -- Teleport to void
            root.CFrame = CFrame.new(
                root.Position.X,
                -9999,
                root.Position.Z
            )
        end
    end,
})

Universal:CreateButton({
    Name     = "Kill All (Fling to Void)",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            if not isEnemy(p) then continue end

            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then continue end

            local att = Instance.new("Attachment")
            att.Parent = root

            local vel = Instance.new("LinearVelocity")
            vel.Attachment0    = att
            vel.RelativeTo     = Enum.ActuatorRelativeTo.World
            vel.MaxForce       = math.huge
            -- Huge upward then let gravity + void do the rest
            vel.VectorVelocity = Vector3.new(
                math.random(-200, 200),
                800,
                math.random(-200, 200)
            )
            vel.Parent = root

            task.delay(0.5, function()
                pcall(function() vel:Destroy() end)
                pcall(function() att:Destroy() end)
                -- Follow-up void drop after launch
                pcall(function()
                    if root and root.Parent then
                        root.CFrame = CFrame.new(
                            root.Position.X,
                            -9999,
                            root.Position.Z
                        )
                    end
                end)
            end)
        end
    end,
})

--==================================================
-- CREDITS
--==================================================

Credits:CreateLabel("Script by CORPEZ")
Credits:CreateLabel("Rayfield UI by Sirius")

--==================================================
-- RESPAWN HANDLER
--==================================================

LocalPlayer.CharacterAdded:Connect(function(character)
    stopFly()
    stopSpiral()
    NoclipEnabled = false

    task.wait(1)

    if ESPEnabled     then updateESP()     end
    if WallHackEnabled then updateWallHack() end
    if SpeedEnabled   then applySpeed()    end

    -- Reapply immortal after respawn — fresh humanoid
    if ImmortalEnabled then
        local hum = character:WaitForChild("Humanoid", 5)
        if hum then
            task.wait(0.3)
            -- Disconnect old connections, start fresh
            _iDisconnectAll()
            _applyImmune(hum)
            _antiVoid(character)
            _explosionSweep(character)

            local hb = RunService.Heartbeat:Connect(function()
                if not ImmortalEnabled then return end
                local char2 = LocalPlayer.Character
                if not char2 then return end
                local hum2  = char2:FindFirstChildOfClass("Humanoid")
                if not hum2 then return end
                if hum2.MaxHealth ~= math.huge then hum2.MaxHealth = math.huge end
                if hum2.Health    ~= math.huge then hum2.Health    = math.huge end
            end)
            table.insert(_iConns, hb)
        end
    end
end)

--==================================================
-- LOADED NOTIFICATION
--==================================================

Rayfield:Notify({
    Title    = "Corpez Hax",
    Content  = "Loaded — Immortal Fixed | Kill All | WallBang",
    Duration = 5,
})

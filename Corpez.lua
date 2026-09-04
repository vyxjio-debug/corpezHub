--==================================================
-- CORPEZ HAX — FULL SCRIPT
-- True Immortal | WallBang Aim | ESP | Fly | Speed
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- RAYFIELD
--==================================================

local Rayfield = loadstring(game:HttpGet(
	"https://sirius.menu/rayfield"
))()

local Window = Rayfield:CreateWindow({
	Name = "Corpez Hax",
	LoadingTitle = "Corpez Hax",
	LoadingSubtitle = "by CORPEZ",
	ConfigurationSaving = { Enabled = false },
	Discord = { Enabled = false },
	KeySystem = false
})

--==================================================
-- ADVANTAGES TAB
--==================================================

local Advantages = Window:CreateTab("Advantages", 4483362458)
Advantages:CreateSection("Corpez Hax Advantages")

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
local Highlights = {}

local function clearESP()
	for player, highlight in pairs(Highlights) do
		if highlight then highlight:Destroy() end
		Highlights[player] = nil
	end
end

local function addESP(player)
	if player == LocalPlayer then return end
	local character = player.Character
	if not character then return end
	if Highlights[player] then Highlights[player]:Destroy() end

	local highlight = Instance.new("Highlight")
	highlight.Name = "CorpezESP"
	highlight.Adornee = character

	if isEnemy(player) then
		highlight.FillColor = Color3.fromRGB(255, 0, 0)
		highlight.OutlineColor = Color3.fromRGB(255, 100, 100)
	else
		highlight.FillColor = Color3.fromRGB(170, 0, 255)
		highlight.OutlineColor = Color3.fromRGB(255, 150, 255)
	end

	highlight.FillTransparency = 0.45
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character
	Highlights[player] = highlight
end

local function updateESP()
	clearESP()
	if not ESPEnabled then return end
	for _, player in ipairs(Players:GetPlayers()) do
		addESP(player)
	end
end

Advantages:CreateToggle({
	Name = "Purple/Red ESP",
	CurrentValue = false,
	Callback = function(value)
		ESPEnabled = value
		updateESP()
	end
})

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if ESPEnabled then addESP(player) end
	end)
end)

--==================================================
-- WALL HACK (nametags)
--==================================================

local WallHackEnabled = false
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

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CorpezWH"
	billboard.Adornee = root
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Text = player.Name

	if isEnemy(player) then
		label.TextColor3 = Color3.fromRGB(255, 80, 80)
	else
		label.TextColor3 = Color3.fromRGB(255, 80, 255)
	end

	label.Parent = billboard
	WallHackBillboards[player] = billboard
end

local function updateWallHack()
	for player, billboard in pairs(WallHackBillboards) do
		if billboard then billboard:Destroy() end
		WallHackBillboards[player] = nil
	end
	if not WallHackEnabled then return end
	for _, player in ipairs(Players:GetPlayers()) do
		addWallHack(player)
	end
end

Advantages:CreateToggle({
	Name = "Wall Hack",
	CurrentValue = false,
	Callback = function(value)
		WallHackEnabled = value
		updateWallHack()
	end
})

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		if WallHackEnabled then addWallHack(player) end
	end)
end)

--==================================================
-- TRUE IMMORTAL v2
-- Heartbeat + RenderStepped dual lock
-- Anti-explosion, Anti-void, Anti-Died
--==================================================

local ImmortalEnabled = false
local ImmortalConnections = {}

local function disableLocalScripts(character)
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("LocalScript") or obj:IsA("Script") then
			obj.Disabled = true
		end
	end
end

local function sweepExplosives(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Explosion") then
			local dist = (obj.Position - root.Position).Magnitude
			if dist < 60 then
				obj.BlastPressure = 0
				obj.BlastRadius = 0
				obj.DestroyJointRadiusPercent = 0
			end
		end
	end
end

local function lockHealth(humanoid)
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge

	local hc = humanoid.HealthChanged:Connect(function()
		if ImmortalEnabled then
			humanoid.MaxHealth = math.huge
			humanoid.Health = math.huge
		end
	end)
	table.insert(ImmortalConnections, hc)

	local dc = humanoid.Died:Connect(function()
		if ImmortalEnabled then
			humanoid.MaxHealth = math.huge
			humanoid.Health = math.huge
		end
	end)
	table.insert(ImmortalConnections, dc)
end

local function antiVoid(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local av = RunService.Heartbeat:Connect(function()
		if not ImmortalEnabled then return end
		if not root.Parent then return end
		if root.Position.Y < -100 then
			root.CFrame = CFrame.new(
				root.Position.X,
				50,
				root.Position.Z
			)
		end
	end)
	table.insert(ImmortalConnections, av)
end

local function startImmortal()
	for _, c in ipairs(ImmortalConnections) do
		if c then c:Disconnect() end
	end
	ImmortalConnections = {}

	local character = LocalPlayer.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	disableLocalScripts(character)
	lockHealth(humanoid)
	antiVoid(character)

	-- Heartbeat lock
	local hb = RunService.Heartbeat:Connect(function()
		if not ImmortalEnabled then return end
		local char = LocalPlayer.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		if hum.MaxHealth ~= math.huge then hum.MaxHealth = math.huge end
		if hum.Health < math.huge then hum.Health = math.huge end
		sweepExplosives(char)
	end)
	table.insert(ImmortalConnections, hb)

	-- RenderStepped lock (double coverage)
	local rs = RunService.RenderStepped:Connect(function()
		if not ImmortalEnabled then return end
		local char = LocalPlayer.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		hum.MaxHealth = math.huge
		hum.Health = math.huge
	end)
	table.insert(ImmortalConnections, rs)
end

local function stopImmortal()
	ImmortalEnabled = false
	for _, c in ipairs(ImmortalConnections) do
		if c then c:Disconnect() end
	end
	ImmortalConnections = {}

	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid.MaxHealth = 100
	humanoid.Health = 100
end

Advantages:CreateToggle({
	Name = "Immortal (TRUE)",
	CurrentValue = false,
	Callback = function(value)
		ImmortalEnabled = value
		if value then startImmortal() else stopImmortal() end
	end
})

--==================================================
-- NOCLIP
--==================================================

local NoclipEnabled = false

RunService.Stepped:Connect(function()
	if not NoclipEnabled then return end
	local character = LocalPlayer.Character
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end)

Advantages:CreateToggle({
	Name = "Noclip / Wall Pass",
	CurrentValue = false,
	Callback = function(value)
		NoclipEnabled = value
		if not value then
			local character = LocalPlayer.Character
			if not character then return end
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
	end
})

--==================================================
-- AIM ASSIST — WALLBANG (NO VISIBILITY CHECK)
--==================================================

local AimEnabled = false
local AimDistance = 500
local AimSmoothness = 0.15

local function getClosestPlayer()
	local camera = workspace.CurrentCamera
	local mousePosition = UserInputService:GetMouseLocation()
	local closest = nil
	local closestDistance = AimDistance

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and isEnemy(player) then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local root = character:FindFirstChild("HumanoidRootPart")

				if humanoid and root and humanoid.Health > 0 then
					local screenPosition, onScreen =
						camera:WorldToViewportPoint(root.Position)

					if onScreen then
						local distance = (
							Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition
						).Magnitude

						if distance < closestDistance then
							closestDistance = distance
							closest = player
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
	local target = getClosestPlayer()
	if not target then return end
	local character = target.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local camera = workspace.CurrentCamera
	local targetCFrame = CFrame.lookAt(
		camera.CFrame.Position,
		root.Position
	)
	camera.CFrame = camera.CFrame:Lerp(targetCFrame, AimSmoothness)
end)

Advantages:CreateToggle({
	Name = "Aim Assist (WallBang)",
	CurrentValue = false,
	Callback = function(value)
		AimEnabled = value
	end
})

Advantages:CreateSlider({
	Name = "Aim Smoothness",
	Range = {0.05, 1},
	Increment = 0.05,
	CurrentValue = 0.15,
	Callback = function(value)
		AimSmoothness = value
	end
})

Advantages:CreateSlider({
	Name = "Aim Range",
	Range = {50, 1500},
	Increment = 50,
	CurrentValue = 500,
	Suffix = " px",
	Callback = function(value)
		AimDistance = value
	end
})

--==================================================
-- AUTO TARGET — WALLBANG
--==================================================

local AutoTargetEnabled = false
local AutoTargetSmoothness = 0.2

local function getClosestPlayerWorld()
	local myCharacter = LocalPlayer.Character
	if not myCharacter then return nil end
	local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	local closest = nil
	local closestDist = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and isEnemy(player) then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local root = character:FindFirstChild("HumanoidRootPart")

				if humanoid and root and humanoid.Health > 0 then
					local dist = (root.Position - myRoot.Position).Magnitude
					if dist < closestDist then
						closestDist = dist
						closest = player
					end
				end
			end
		end
	end

	return closest
end

RunService.RenderStepped:Connect(function()
	if not AutoTargetEnabled then return end
	local target = getClosestPlayerWorld()
	if not target then return end
	local character = target.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local camera = workspace.CurrentCamera
	local targetCFrame = CFrame.lookAt(
		camera.CFrame.Position,
		root.Position
	)
	camera.CFrame = camera.CFrame:Lerp(targetCFrame, AutoTargetSmoothness)
end)

Advantages:CreateToggle({
	Name = "Auto Target (WallBang)",
	CurrentValue = false,
	Callback = function(value)
		AutoTargetEnabled = value
	end
})

Advantages:CreateSlider({
	Name = "Auto Target Smoothness",
	Range = {0.05, 1},
	Increment = 0.05,
	CurrentValue = 0.2,
	Suffix = "x",
	Callback = function(value)
		AutoTargetSmoothness = value
	end
})

--==================================================
-- SPEED WALK
--==================================================

local SpeedEnabled = false
local SpeedValue = 32
local DefaultSpeed = 16

local function applySpeed()
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid.WalkSpeed = SpeedEnabled and SpeedValue or DefaultSpeed
end

Advantages:CreateToggle({
	Name = "Speed Walk",
	CurrentValue = false,
	Callback = function(value)
		SpeedEnabled = value
		applySpeed()
	end
})

Advantages:CreateSlider({
	Name = "Walk Speed",
	Range = {16, 300},
	Increment = 8,
	CurrentValue = 32,
	Suffix = " speed",
	Callback = function(value)
		SpeedValue = value
		if SpeedEnabled then applySpeed() end
	end
})

--==================================================
-- FLY
--==================================================

local Flying = false
local FlySpeed = 60
local FlyConnection
local FlyVelocity
local FlyOrientation
local FlyVelocityAttachment
local FlyOrientationAttachment

local function stopFly()
	Flying = false
	if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
	if FlyVelocity then FlyVelocity:Destroy(); FlyVelocity = nil end
	if FlyOrientation then FlyOrientation:Destroy(); FlyOrientation = nil end
	if FlyVelocityAttachment then FlyVelocityAttachment:Destroy(); FlyVelocityAttachment = nil end
	if FlyOrientationAttachment then FlyOrientationAttachment:Destroy(); FlyOrientationAttachment = nil end
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.AutoRotate = true end
end

local function startFly()
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	stopFly()
	Flying = true
	humanoid.AutoRotate = false

	FlyVelocityAttachment = Instance.new("Attachment")
	FlyVelocityAttachment.Parent = root

	FlyVelocity = Instance.new("LinearVelocity")
	FlyVelocity.Attachment0 = FlyVelocityAttachment
	FlyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	FlyVelocity.MaxForce = math.huge
	FlyVelocity.VectorVelocity = Vector3.zero
	FlyVelocity.Parent = root

	FlyOrientationAttachment = Instance.new("Attachment")
	FlyOrientationAttachment.Parent = root

	FlyOrientation = Instance.new("AlignOrientation")
	FlyOrientation.Attachment0 = FlyOrientationAttachment
	FlyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	FlyOrientation.MaxTorque = math.huge
	FlyOrientation.Responsiveness = 25
	FlyOrientation.Parent = root

	FlyConnection = RunService.RenderStepped:Connect(function()
		if not Flying or not root.Parent then stopFly(); return end

		local camera = workspace.CurrentCamera
		local direction = Vector3.zero

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.new(0, 1, 0) end

		if direction.Magnitude > 0 then direction = direction.Unit * FlySpeed end

		FlyVelocity.VectorVelocity = direction
		FlyOrientation.CFrame = CFrame.lookAt(
			root.Position,
			root.Position + camera.CFrame.LookVector
		)
	end)
end

Advantages:CreateToggle({
	Name = "Fly",
	CurrentValue = false,
	Callback = function(value)
		if value then startFly() else stopFly() end
	end
})

Advantages:CreateSlider({
	Name = "Fly Speed",
	Range = {10, 200},
	Increment = 5,
	CurrentValue = 60,
	Suffix = " studs/s",
	Callback = function(value)
		FlySpeed = value
	end
})

--==================================================
-- UNIVERSAL TAB
--==================================================

local Universal = Window:CreateTab("Universal", 4483362458)
Universal:CreateSection("Universal Player Tools")

local function getOtherPlayers()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(list, player)
		end
	end
	return list
end

local function getRandomPlayer()
	local list = getOtherPlayers()
	if #list == 0 then return nil end
	return list[math.random(1, #list)]
end

Universal:CreateButton({
	Name = "Teleport To Random",
	Callback = function()
		local target = getRandomPlayer()
		if not target then return end
		local myCharacter = LocalPlayer.Character
		local targetCharacter = target.Character
		if not myCharacter or not targetCharacter then return end
		local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		if myRoot and targetRoot then
			myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4)
		end
	end
})

Universal:CreateButton({
	Name = "Fling Random",
	Callback = function()
		local target = getRandomPlayer()
		if not target then return end
		local character = target.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local attachment = Instance.new("Attachment")
		attachment.Parent = root

		local velocity = Instance.new("LinearVelocity")
		velocity.Attachment0 = attachment
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.MaxForce = math.huge
		velocity.VectorVelocity = Vector3.new(
			math.random(-150, 150), 150, math.random(-150, 150)
		)
		velocity.Parent = root

		task.delay(0.35, function()
			if velocity then velocity:Destroy() end
			if attachment then attachment:Destroy() end
		end)
	end
})

Universal:CreateButton({
	Name = "Bring Random",
	Callback = function()
		local target = getRandomPlayer()
		if not target then return end
		local myCharacter = LocalPlayer.Character
		local targetCharacter = target.Character
		if not myCharacter or not targetCharacter then return end
		local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		if myRoot and targetRoot then
			targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4)
		end
	end
})

Universal:CreateButton({
	Name = "Bring All",
	Callback = function()
		local myCharacter = LocalPlayer.Character
		if not myCharacter then return end
		local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
		if not myRoot then return end
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = myRoot.CFrame * CFrame.new(
						math.random(-5, 5), 0, math.random(-5, 5)
					)
				end
			end
		end
	end
})

--==================================================
-- PLAYER SPIRAL
--==================================================

local SpiralEnabled = false
local SpiralConnection
local SpiralAngle = 0

local function stopSpiral()
	SpiralEnabled = false
	if SpiralConnection then
		SpiralConnection:Disconnect()
		SpiralConnection = nil
	end
end

local function startSpiral()
	local myCharacter = LocalPlayer.Character
	if not myCharacter then return end
	local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	SpiralEnabled = true
	SpiralAngle = 0

	SpiralConnection = RunService.Heartbeat:Connect(function(dt)
		if not SpiralEnabled then stopSpiral(); return end
		SpiralAngle = SpiralAngle + dt * 3

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root then
					local radius = 8
					local offset = Vector3.new(
						math.cos(SpiralAngle) * radius,
						0,
						math.sin(SpiralAngle) * radius
					)
					root.CFrame = CFrame.new(myRoot.Position + offset)
				end
			end
		end
	end)
end

Universal:CreateToggle({
	Name = "Player Spiral",
	CurrentValue = false,
	Callback = function(value)
		if value then startSpiral() else stopSpiral() end
	end
})

--==================================================
-- CREDITS TAB
--==================================================

local Credits = Window:CreateTab("Credits", 4483362458)
Credits:CreateSection("Corpez Hax Credits")
Credits:CreateLabel("Script by CORPEZ")
Credits:CreateLabel("Rayfield UI by Sirius")

--==================================================
-- RESPAWN HANDLER
--==================================================

LocalPlayer.CharacterAdded:Connect(function()
	stopFly()
	stopSpiral()
	NoclipEnabled = false

	task.wait(1)

	if ESPEnabled then updateESP() end
	if WallHackEnabled then updateWallHack() end
	if SpeedEnabled then applySpeed() end

	-- Reapply immortal on respawn
	if ImmortalEnabled then
		local character = LocalPlayer.Character
		if not character then return end
		local humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then return end
		task.wait(0.2)
		startImmortal()
	end
end)

--==================================================
-- LOADED
--==================================================

Rayfield:Notify({
	Title = "Corpez Hax",
	Content = "ESP | WallHack | TRUE Immortal | Noclip | WallBang Aim",
	Duration = 5
})

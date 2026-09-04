--==================================================
-- MOONLIT
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
	Name = "moonlit",
	LoadingTitle = "moonlit",
	LoadingSubtitle = "https://www.roblox.com/users/7779204532/profile",

	ConfigurationSaving = {
		Enabled = false
	},

	Discord = {
		Enabled = false
	},

	KeySystem = false
})

--==================================================
-- ADVANTAGES
--==================================================

local Advantages = Window:CreateTab(
	"Advantages",
	4483362458
)

Advantages:CreateSection("Moonlit Advantages")

--==================================================
-- PURPLE ESP
--==================================================

local ESPEnabled = false
local Highlights = {}

local function clearESP()
	for player, highlight in pairs(Highlights) do
		if highlight then
			highlight:Destroy()
		end
		Highlights[player] = nil
	end
end

local function addESP(player)
	if player == LocalPlayer then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	if Highlights[player] then
		Highlights[player]:Destroy()
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "MoonlitESP"
	highlight.Adornee = character
	highlight.FillColor = Color3.fromRGB(170, 0, 255)
	highlight.OutlineColor = Color3.fromRGB(255, 150, 255)
	highlight.FillTransparency = 0.45
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	Highlights[player] = highlight
end

local function updateESP()
	clearESP()

	if not ESPEnabled then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		addESP(player)
	end
end

Advantages:CreateToggle({
	Name = "Purple ESP",
	CurrentValue = false,

	Callback = function(value)
		ESPEnabled = value
		updateESP()
	end
})

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)

		if ESPEnabled then
			addESP(player)
		end
	end)
end)

--==================================================
-- AIM ASSIST
--==================================================

local AimEnabled = false
local AimDistance = 500
local AimSmoothness = 0.15

local function isTargetVisible(character, root)
	local camera = workspace.CurrentCamera
	local origin = camera.CFrame.Position
	local direction = root.Position - origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		LocalPlayer.Character
	}
	params.IgnoreWater = true

	local result = workspace:Raycast(
		origin,
		direction,
		params
	)

	if result == nil then
		return true
	end

	return result.Instance:IsDescendantOf(character)
end

local function getClosestPlayer()
	local camera = workspace.CurrentCamera
	local mousePosition =
		UserInputService:GetMouseLocation()

	local closest = nil
	local closestDistance = AimDistance

	for _, player in ipairs(Players:GetPlayers()) do
		-- FIXED: Tinanggal ang team check para hindi mag-error
		if player ~= LocalPlayer then

			local character = player.Character

			if character then
				local humanoid =
					character:FindFirstChildOfClass("Humanoid")

				local root =
					character:FindFirstChild("HumanoidRootPart")

				if humanoid
					and root
					and humanoid.Health > 0 then

					local screenPosition, onScreen =
						camera:WorldToViewportPoint(
							root.Position
						)

					if onScreen then
						local distance =
							(
								Vector2.new(
									screenPosition.X,
									screenPosition.Y
								) - mousePosition
							).Magnitude

						if distance < closestDistance
							and isTargetVisible(
								character,
								root
							) then

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
	if not AimEnabled then
		return
	end

	local target = getClosestPlayer()

	if not target then
		return
	end

	local character = target.Character
	if not character then
		return
	end

	local root =
		character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	if not isTargetVisible(character, root) then
		return
	end

	local camera = workspace.CurrentCamera

	local targetCFrame =
		CFrame.lookAt(
			camera.CFrame.Position,
			root.Position
		)

	camera.CFrame =
		camera.CFrame:Lerp(
			targetCFrame,
			AimSmoothness
		)
end)

Advantages:CreateToggle({
	Name = "Aim Assist",
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

	if FlyConnection then
		FlyConnection:Disconnect()
		FlyConnection = nil
	end

	if FlyVelocity then
		FlyVelocity:Destroy()
		FlyVelocity = nil
	end

	if FlyOrientation then
		FlyOrientation:Destroy()
		FlyOrientation = nil
	end

	if FlyVelocityAttachment then
		FlyVelocityAttachment:Destroy()
		FlyVelocityAttachment = nil
	end

	if FlyOrientationAttachment then
		FlyOrientationAttachment:Destroy()
		FlyOrientationAttachment = nil
	end

	local character = LocalPlayer.Character

	local humanoid =
		character
		and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid.AutoRotate = true
	end
end

local function startFly()
	local character = LocalPlayer.Character

	if not character then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	local root =
		character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		return
	end

	stopFly()

	Flying = true
	humanoid.AutoRotate = false

	FlyVelocityAttachment =
		Instance.new("Attachment")

	FlyVelocityAttachment.Parent = root

	FlyVelocity =
		Instance.new("LinearVelocity")

	FlyVelocity.Attachment0 =
		FlyVelocityAttachment

	FlyVelocity.RelativeTo =
		Enum.ActuatorRelativeTo.World

	FlyVelocity.MaxForce = math.huge
	FlyVelocity.VectorVelocity = Vector3.zero
	FlyVelocity.Parent = root

	FlyOrientationAttachment =
		Instance.new("Attachment")

	FlyOrientationAttachment.Parent = root

	FlyOrientation =
		Instance.new("AlignOrientation")

	FlyOrientation.Attachment0 =
		FlyOrientationAttachment

	FlyOrientation.Mode =
		Enum.OrientationAlignmentMode.OneAttachment

	FlyOrientation.MaxTorque = math.huge
	FlyOrientation.Responsiveness = 25
	FlyOrientation.Parent = root

	FlyConnection =
		RunService.RenderStepped:Connect(function()

			if not Flying or not root.Parent then
				stopFly()
				return
			end

			local camera = workspace.CurrentCamera
			local direction = Vector3.zero

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				direction += camera.CFrame.LookVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				direction -= camera.CFrame.LookVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				direction -= camera.CFrame.RightVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				direction += camera.CFrame.RightVector
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				direction += Vector3.new(0, 1, 0)
			end

			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				direction -= Vector3.new(0, 1, 0)
			end

			if direction.Magnitude > 0 then
				direction =
					direction.Unit * FlySpeed
			end

			FlyVelocity.VectorVelocity = direction

			FlyOrientation.CFrame =
				CFrame.lookAt(
					root.Position,
					root.Position +
						camera.CFrame.LookVector
				)
		end)
end

Advantages:CreateToggle({
	Name = "Fly",
	CurrentValue = false,

	Callback = function(value)
		if value then
			startFly()
		else
			stopFly()
		end
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
-- UNIVERSAL
--==================================================

local Universal = Window:CreateTab(
	"Universal",
	4483362458
)

Universal:CreateSection(
	"Universal Player Tools"
)

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

	if #list == 0 then
		return nil
	end

	return list[math.random(1, #list)]
end

--==================================================
-- TELEPORT RANDOM
--==================================================

Universal:CreateButton({
	Name = "Teleport To Random",

	Callback = function()
		local target = getRandomPlayer()

		if not target then
			return
		end

		local myCharacter = LocalPlayer.Character
		local targetCharacter = target.Character

		if not myCharacter or not targetCharacter then
			return
		end

		local myRoot =
			myCharacter:FindFirstChild("HumanoidRootPart")

		local targetRoot =
			targetCharacter:FindFirstChild("HumanoidRootPart")

		if myRoot and targetRoot then
			myRoot.CFrame =
				targetRoot.CFrame *
				CFrame.new(0, 0, 4)
		end
	end
})

--==================================================
-- FLING RANDOM
--==================================================

Universal:CreateButton({
	Name = "Fling Random",

	Callback = function()
		local target = getRandomPlayer()

		if not target then
			return
		end

		local character = target.Character

		local root =
			character
			and character:FindFirstChild(
				"HumanoidRootPart"
			)

		if not root then
			return
		end

		local attachment =
			Instance.new("Attachment")

		attachment.Parent = root

		local velocity =
			Instance.new("LinearVelocity")

		velocity.Attachment0 = attachment
		velocity.RelativeTo =
			Enum.ActuatorRelativeTo.World

		velocity.MaxForce = math.huge

		velocity.VectorVelocity =
			Vector3.new(
				math.random(-150, 150),
				150,
				math.random(-150, 150)
			)

		velocity.Parent = root

		task.delay(0.35, function()

			if velocity then
				velocity:Destroy()
			end

			if attachment then
				attachment:Destroy()
			end

		end)
	end
})

--==================================================
-- BRING RANDOM
--==================================================

Universal:CreateButton({
	Name = "Bring Random",

	Callback = function()
		local target = getRandomPlayer()

		if not target then
			return
		end

		local myCharacter = LocalPlayer.Character
		local targetCharacter = target.Character

		if not myCharacter or not targetCharacter then
			return
		end

		local myRoot =
			myCharacter:FindFirstChild("HumanoidRootPart")

		local targetRoot =
			targetCharacter:FindFirstChild("HumanoidRootPart")

		if myRoot and targetRoot then
			targetRoot.CFrame =
				myRoot.CFrame *
				CFrame.new(0, 0, -4)
		end
	end
})

--==================================================
-- BRING ALL
--==================================================

Universal:CreateButton({
	Name = "Bring All",

	Callback = function()
		local myCharacter = LocalPlayer.Character

		if not myCharacter then
			return
		end

		local myRoot =
			myCharacter:FindFirstChild("HumanoidRootPart")

		if not myRoot then
			return
		end

		for _, player in ipairs(Players:GetPlayers()) do

			if player ~= LocalPlayer then

				local character = player.Character

				local root =
					character
					and character:FindFirstChild(
						"HumanoidRootPart"
					)

				if root then
					root.CFrame =
						myRoot.CFrame *
						CFrame.new(
							math.random(-5, 5),
							0,
							math.random(-5, 5)
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

local SpiralRadius = 8
local SpiralHeight = 3
local SpiralSpeed = 2

local function stopSpiral()
	SpiralEnabled = false

	if SpiralConnection then
		SpiralConnection:Disconnect()
		SpiralConnection = nil
	end
end

local function startSpiral()

	stopSpiral()

	local target = getRandomPlayer()

	if not target then
		return
	end

	SpiralEnabled = true
	SpiralAngle = 0

	SpiralConnection =
		RunService.RenderStepped:Connect(
			function(deltaTime)

				if not SpiralEnabled then
					return
				end

				local myCharacter =
					LocalPlayer.Character

				local targetCharacter =
					target.Character

				if not myCharacter
					or not targetCharacter then

					stopSpiral()
					return
				end

				local myRoot =
					myCharacter:FindFirstChild(
						"HumanoidRootPart"
					)

				local targetRoot =
					targetCharacter:FindFirstChild(
						"HumanoidRootPart"
					)

				if not myRoot or not targetRoot then
					stopSpiral()
					return
				end

				SpiralAngle +=
					deltaTime *
					SpiralSpeed

				local height =
					math.sin(
						SpiralAngle * 0.5
					) *
					SpiralHeight

				local x =
					math.cos(
						SpiralAngle
					) *
					SpiralRadius

				local z =
					math.sin(
						SpiralAngle
					) *
					SpiralRadius

				local position =
					targetRoot.Position +
					Vector3.new(
						x,
						height,
						z
					)

				myRoot.CFrame =
					CFrame.lookAt(
						position,
						targetRoot.Position
					)
			end
		)
end

Universal:CreateToggle({
	Name = "Player Spiral",
	CurrentValue = false,

	Callback = function(value)

		if value then
			startSpiral()
		else
			stopSpiral()
		end

	end
})

Universal:CreateSlider({
	Name = "Spiral Radius",
	Range = {3, 30},
	Increment = 1,
	CurrentValue = 8,
	Suffix = " studs",

	Callback = function(value)
		SpiralRadius = value
	end
})

Universal:CreateSlider({
	Name = "Spiral Speed",
	Range = {0.5, 10},
	Increment = 0.5,
	CurrentValue = 2,
	Suffix = "x",

	Callback = function(value)
		SpiralSpeed = value
	end
})

--==================================================
-- KICK SELF
--==================================================

Universal:CreateButton({
	Name = "Kick Self",

	Callback = function()
		LocalPlayer:Kick(
			"Moonlit: kicked yourself"
		)
	end
})

--==================================================
-- CREDITS
--==================================================

local Credits = Window:CreateTab(
	"Credits",
	4483362458
)

Credits:CreateSection(
	"Moonlit Credits"
)

Credits:CreateParagraph({
	Title = "J0K",
	Content = "CREATED MOONLIT"
})

Credits:CreateParagraph({
	Title = "STRIPESVR",
	Content = "(I stole the name of his adb)"
})

Credits:CreateParagraph({
	Title = "war2012boys",
	Content = "he's my bro"
})

--==================================================
-- RESPAWN HANDLER
--==================================================

LocalPlayer.CharacterAdded:Connect(function()

	stopFly()
	stopSpiral()

	task.wait(1)

	if ESPEnabled then
		updateESP()
	end

end)

--==================================================
-- LOADED
--==================================================

Rayfield:Notify({
	Title = "moonlit",
	Content = "Advantages Universal Credits loaded",
	Duration = 5
})

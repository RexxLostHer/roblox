--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("RebirthChampionsConfig"))

export type ActiveFollowerPet = {
	UUID: string,
	Name: string,
	Mutation: "Normal" | "Golden" | "Toxic" | "Galaxy" | "Rainbow",
	IsShiny: boolean,
	Model: Model,
	PrimaryPart: BasePart,
	PhaseOffset: number,
}

local LocalPlayer = Players.LocalPlayer

local PETS_PER_ROW = 3
local ROW_SPACING_STUDS = 4.2
local COL_SPACING_STUDS = 3.6
local BASE_BEHIND_DISTANCE = 5.0
local LERP_SPEED = 10.5
local IDLE_BOB_SPEED = 3.5
local IDLE_BOB_HEIGHT = 0.55
local WALK_BOUNCE_SPEED = 11.0
local WALK_BOUNCE_HEIGHT = 1.15

local ActivePetModels: { ActiveFollowerPet } = {}

local PetVisualsContainer = workspace:FindFirstChild("ClientEquippedPets") :: Folder?
if not PetVisualsContainer then
	PetVisualsContainer = Instance.new("Folder")
	PetVisualsContainer.Name = "ClientEquippedPets"
	PetVisualsContainer.Parent = workspace
end

local function CreateOrClonePetModel(petName: string, mutation: string, isShiny: boolean): (Model, BasePart)
	local assetsFolder = ReplicatedStorage:FindFirstChild("PetModels")
	local template = if assetsFolder then assetsFolder:FindFirstChild(petName) :: Model? else nil

	local model: Model
	local rootPart: BasePart

	if template and template.PrimaryPart then
		model = template:Clone()
		rootPart = model.PrimaryPart :: BasePart
	else
		model = Instance.new("Model")
		model.Name = petName

		local baseScale = if isShiny then 2.6 else 2.1
		local cube = Instance.new("Part")
		cube.Name = "PrimaryCube"
		cube.Size = Vector3.new(baseScale, baseScale, baseScale)
		cube.Material = Enum.Material.SmoothPlastic
		cube.CanCollide = false
		cube.CanQuery = false
		cube.CanTouch = false
		cube.Anchored = true
		cube.CastShadow = true
		cube.Parent = model

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "PetTag"
		billboard.Size = UDim2.fromOffset(130, 36)
		billboard.StudsOffset = Vector3.new(0, baseScale * 0.95, 0)
		billboard.AlwaysOnTop = false
		billboard.Parent = cube

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.fromScale(1, 1)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.TextScaled = true
		nameLabel.TextStrokeTransparency = 0.2
		nameLabel.Text = (if isShiny then "✨ " else "") .. (if mutation ~= "Normal" then "[" .. mutation .. "] " else "") .. petName
		nameLabel.Parent = billboard

		-- PROCEDURAL 3D FANTASY DRAGON MESH BUILDER
		if string.find(petName, "Astral Wyrm") then
			cube.Color = Color3.fromRGB(56, 189, 248)
			cube.Material = Enum.Material.ForceField
			for side = -1, 1, 2 do
				local wing = Instance.new("Part")
				wing.Name = "AstralWing"
				wing.Size = Vector3.new(0.3, baseScale * 0.8, baseScale * 1.4)
				wing.CFrame = cube.CFrame * CFrame.new(side * (baseScale * 0.7), baseScale * 0.2, -baseScale * 0.3) * CFrame.Angles(0, math.rad(side * 35), math.rad(side * 20))
				wing.Color = Color3.fromRGB(125, 211, 252)
				wing.Material = Enum.Material.Neon
				wing.CanCollide = false
				wing.Anchored = true
				wing.Parent = model
			end
		elseif string.find(petName, "Infernal Dread-Drake") then
			cube.Color = Color3.fromRGB(24, 24, 27)
			cube.Material = Enum.Material.Basalt
			for side = -1, 1, 2 do
				local flameWing = Instance.new("Part")
				flameWing.Name = "MagmaWing"
				flameWing.Size = Vector3.new(0.35, baseScale * 1.1, baseScale * 1.5)
				flameWing.CFrame = cube.CFrame * CFrame.new(side * (baseScale * 0.75), baseScale * 0.3, -baseScale * 0.35) * CFrame.Angles(0, math.rad(side * 40), math.rad(side * 25))
				flameWing.Color = Color3.fromRGB(249, 115, 22)
				flameWing.Material = Enum.Material.Neon
				flameWing.CanCollide = false
				flameWing.Anchored = true
				flameWing.Parent = model
			end
			local fire = Instance.new("Fire")
			fire.Size = 4
			fire.Heat = 5
			fire.Color = Color3.fromRGB(255, 100, 0)
			fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
			fire.Parent = cube
		elseif string.find(petName, "Voidborn Chimera") then
			cube.Color = Color3.fromRGB(76, 29, 149)
			cube.Material = Enum.Material.ForceField
			for side = -1, 1, 2 do
				local horn = Instance.new("Part")
				horn.Name = "VoidHorn"
				horn.Size = Vector3.new(0.4, baseScale * 0.9, 0.4)
				horn.CFrame = cube.CFrame * CFrame.new(side * (baseScale * 0.35), baseScale * 0.7, -baseScale * 0.2) * CFrame.Angles(math.rad(-25), 0, math.rad(side * 25))
				horn.Color = Color3.fromRGB(192, 132, 252)
				horn.Material = Enum.Material.Neon
				horn.CanCollide = false
				horn.Anchored = true
				horn.Parent = model
			end
		elseif string.find(petName, "Yggdrasil Ancient Dragon") then
			cube.Color = Color3.fromRGB(22, 101, 52)
			cube.Material = Enum.Material.Wood
			for side = -1, 1, 2 do
				local branchHorn = Instance.new("Part")
				branchHorn.Name = "YggdrasilBranch"
				branchHorn.Size = Vector3.new(0.5, baseScale * 1.3, 0.5)
				branchHorn.CFrame = cube.CFrame * CFrame.new(side * (baseScale * 0.4), baseScale * 0.85, 0) * CFrame.Angles(math.rad(-15), 0, math.rad(side * 35))
				branchHorn.Color = Color3.fromRGB(34, 197, 94)
				branchHorn.Material = Enum.Material.Neon
				branchHorn.CanCollide = false
				branchHorn.Anchored = true
				branchHorn.Parent = model
			end
		elseif string.find(petName, "Archangel Sovereign Dragon") then
			cube.Color = Color3.fromRGB(255, 255, 255)
			cube.Material = Enum.Material.Foil
			-- 6 Sayap Malaikat Emas Bertingkat
			for tier = 1, 3 do
				for side = -1, 1, 2 do
					local wing = Instance.new("Part")
					wing.Name = "ArchangelWing_" .. tier .. "_" .. side
					wing.Size = Vector3.new(0.25, baseScale * (0.6 + (tier * 0.25)), baseScale * (1.0 + (tier * 0.3)))
					wing.CFrame = cube.CFrame * CFrame.new(side * (baseScale * (0.6 + (tier * 0.2))), baseScale * (tier * 0.25), -baseScale * 0.4) * CFrame.Angles(0, math.rad(side * (25 + tier * 10)), math.rad(side * (15 + tier * 8)))
					wing.Color = Color3.fromRGB(250, 204, 21)
					wing.Material = Enum.Material.Neon
					wing.CanCollide = false
					wing.Anchored = true
					wing.Parent = model
				end
			end
			-- Halo Suci Melayang
			local halo = Instance.new("Part")
			halo.Name = "SovereignHalo"
			halo.Size = Vector3.new(baseScale * 1.3, 0.25, baseScale * 1.3)
			halo.CFrame = cube.CFrame * CFrame.new(0, baseScale * 0.85, 0)
			halo.Color = Color3.fromRGB(253, 224, 71)
			halo.Material = Enum.Material.Neon
			halo.Shape = Enum.PartType.Cylinder
			halo.CanCollide = false
			halo.Anchored = true
			halo.Parent = model
		end

		model.PrimaryPart = cube
		rootPart = cube
	end

	local tierData = Config.MutationTiers.Tiers[mutation]
	local tierColor = if tierData then tierData.Color else Color3.fromRGB(255, 255, 255)

	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.CanQuery = false
			desc.CanTouch = false
			desc.Anchored = true

			if mutation == "Golden" then
				desc.Color = Color3.fromRGB(255, 204, 0)
				desc.Material = Enum.Material.Foil
			elseif mutation == "Toxic" then
				desc.Color = Color3.fromRGB(57, 255, 20)
				desc.Material = Enum.Material.Neon
			elseif mutation == "Galaxy" then
				desc.Color = Color3.fromRGB(168, 85, 247)
				desc.Material = Enum.Material.ForceField
			elseif mutation == "Rainbow" then
				desc.Material = Enum.Material.Neon
			end
		elseif desc:IsA("TextLabel") then
			desc.TextColor3 = tierColor
		end
	end

	if isShiny or mutation ~= "Normal" then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "MutationSparkles"
		sparkles.Color = ColorSequence.new(tierColor)
		sparkles.LightEmission = 1
		sparkles.Size = NumberSequence.new(0.25, 0)
		sparkles.Rate = if isShiny then 14 else 7
		sparkles.Lifetime = NumberRange.new(0.6, 1.1)
		sparkles.Speed = NumberRange.new(1, 2.5)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Parent = rootPart
	end

	model.Parent = PetVisualsContainer
	return model, rootPart
end

local PetFollowerAPI = {}

function PetFollowerAPI.SyncEquippedPets(equippedList: { { UUID: string, Name: string, Mutation: "Normal" | "Golden" | "Toxic" | "Galaxy" | "Rainbow", IsShiny: boolean } })
	for _, item in ipairs(ActivePetModels) do
		if item.Model then
			item.Model:Destroy()
		end
	end
	table.clear(ActivePetModels)

	for index, petInfo in ipairs(equippedList) do
		local model, primaryPart = CreateOrClonePetModel(petInfo.Name, petInfo.Mutation, petInfo.IsShiny)
		table.insert(ActivePetModels, {
			UUID = petInfo.UUID,
			Name = petInfo.Name,
			Mutation = petInfo.Mutation,
			IsShiny = petInfo.IsShiny,
			Model = model,
			PrimaryPart = primaryPart,
			PhaseOffset = index * 0.85,
		})
	end
end

RunService.RenderStepped:Connect(function(deltaTime: number)
	local character = LocalPlayer.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not rootPart or not humanoid then return end

	local totalEquipped = #ActivePetModels
	if totalEquipped == 0 then return end

	local now = os.clock()
	local isMoving = humanoid.MoveDirection.Magnitude > 0.05
	local rainbowColor = Color3.fromHSV((now * 0.35) % 1, 0.85, 1.0)

	for index, pet in ipairs(ActivePetModels) do
		local row = math.ceil(index / PETS_PER_ROW)
		local colInRow = (index - 1) % PETS_PER_ROW + 1

		local remainingInLastRow = totalEquipped - ((row - 1) * PETS_PER_ROW)
		local petsInThisRow = math.min(PETS_PER_ROW, remainingInLastRow)

		local centerCol = (petsInThisRow + 1) / 2
		local offsetX = (colInRow - centerCol) * COL_SPACING_STUDS
		local offsetZ = BASE_BEHIND_DISTANCE + ((row - 1) * ROW_SPACING_STUDS)
		local arcCurveZ = math.abs(colInRow - centerCol) * 0.65

		local offsetY = 0
		local pitchTilt = 0
		local rollTilt = 0

		if isMoving then
			local wave = math.sin((now * WALK_BOUNCE_SPEED) + pet.PhaseOffset)
			offsetY = math.abs(wave) * WALK_BOUNCE_HEIGHT
			pitchTilt = math.rad(wave * 14)
			rollTilt = math.rad(math.cos((now * WALK_BOUNCE_SPEED * 0.5) + pet.PhaseOffset) * 8)
		else
			offsetY = math.sin((now * IDLE_BOB_SPEED) + pet.PhaseOffset) * IDLE_BOB_HEIGHT
			rollTilt = math.rad(math.sin((now * 2.0) + pet.PhaseOffset) * 4)
		end

		local targetPosition = (rootPart.CFrame * CFrame.new(offsetX, offsetY - 0.5, offsetZ + arcCurveZ)).Position
		local lookVector = rootPart.CFrame.LookVector
		local targetCFrame = CFrame.lookAt(targetPosition, targetPosition + lookVector)
			* CFrame.Angles(pitchTilt, 0, rollTilt)

		local alpha = math.clamp(deltaTime * LERP_SPEED, 0, 1)
		local prevCF = pet.PrimaryPart.CFrame
		local newCF = prevCF:Lerp(targetCFrame, alpha)
		pet.PrimaryPart.CFrame = newCF

		-- Update semua attachment part pelengkap (Sayap, Tanduk, Halo) agar ikut bergerak mulus
		local deltaCF = newCF * prevCF:Inverse()
		for _, part in ipairs(pet.Model:GetChildren()) do
			if part:IsA("BasePart") and part ~= pet.PrimaryPart then
				part.CFrame = deltaCF * part.CFrame
			end
		end

		if pet.Mutation == "Rainbow" then
			pet.PrimaryPart.Color = rainbowColor
		end
	end
end)

-- Sinkronisasi otomatis saat server mengirim daftar pet yang di-equip
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SyncEquippedPetsEvent = Remotes:WaitForChild("SyncEquippedPetsEvent") :: RemoteEvent

SyncEquippedPetsEvent.OnClientEvent:Connect(function(equippedList)
	if type(equippedList) == "table" then
		PetFollowerAPI.SyncEquippedPets(equippedList)
	end
end)

_G.RebirthPetFollowerAPI = PetFollowerAPI
return PetFollowerAPI

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.RebirthChampionsConfig)

local existingMap = workspace:FindFirstChild("RebirthChampionsMap")
if existingMap then
	existingMap:Destroy()
end
local MapRoot = Instance.new("Folder")
MapRoot.Name = "RebirthChampionsMap"
MapRoot.Parent = workspace

local WorldsContainer = workspace:FindFirstChild("Worlds")
if not WorldsContainer then
	local newWorlds = Instance.new("Folder")
	newWorlds.Name = "Worlds"
	newWorlds.Parent = workspace
	WorldsContainer = newWorlds
end

local function CreatePart(props: {
	Name: string,
	Size: Vector3,
	Position: Vector3?,
	CFrame: CFrame?,
	Color: Color3,
	Material: Enum.Material?,
	Shape: Enum.PartType?,
	Transparency: number?,
	CanCollide: boolean?,
	Parent: Instance,
}): Part
	local p = Instance.new("Part")
	p.Name = props.Name
	p.Size = props.Size
	if props.CFrame then
		p.CFrame = props.CFrame
	elseif props.Position then
		p.Position = props.Position
	end
	p.Color = props.Color
	p.Material = props.Material or Enum.Material.SmoothPlastic
	if props.Shape then
		p.Shape = props.Shape
	end
	p.Transparency = props.Transparency or 0
	p.CanCollide = if props.CanCollide ~= nil then props.CanCollide else true
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = props.Parent
	return p
end

local function AttachFloatingBillboard(parentPart: BasePart, titleText: string, subtitleText: string, textColor: Color3, offsetY: number?)
	local bb = Instance.new("BillboardGui")
	bb.Name = "InfoBillboard"
	bb.Size = UDim2.fromOffset(220, 64)
	bb.StudsOffset = Vector3.new(0, offsetY or (parentPart.Size.Y * 0.65 + 2.5), 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 120
	bb.Parent = parentPart

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.58, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = textColor
	title.TextStrokeTransparency = 0.15
	title.TextScaled = true
	title.Text = titleText
	title.Parent = bb

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0.42, 0)
	sub.Position = UDim2.fromScale(0, 0.58)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.SourceSansBold
	sub.TextColor3 = Color3.fromRGB(241, 245, 249)
	sub.TextStrokeTransparency = 0.25
	sub.TextScaled = true
	sub.Text = subtitleText
	sub.Parent = bb
end

local function AttachPrompt(parentPart: BasePart, actionText: string, objectText: string, maxDist: number?): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = maxDist or 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = parentPart
	return prompt
end

local SpawnHubFolder = Instance.new("Folder")
SpawnHubFolder.Name = "SpawnHub"
SpawnHubFolder.Parent = MapRoot

CreatePart({
	Name = "CentralStonePlaza",
	Size = Vector3.new(2, 140, 140),
	CFrame = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Color = Color3.fromRGB(241, 229, 204),
	Material = Enum.Material.Cobblestone,
	Shape = Enum.PartType.Cylinder,
	Parent = SpawnHubFolder,
})

local SpawnPad = Instance.new("SpawnLocation")
SpawnPad.Name = "MainSpawnLocation"
SpawnPad.Size = Vector3.new(12, 1, 12)
SpawnPad.CFrame = CFrame.new(0, 0.6, 26)
SpawnPad.Anchored = true
SpawnPad.CanCollide = false
SpawnPad.Transparency = 1
SpawnPad.Neutral = true
SpawnPad.Parent = SpawnHubFolder

local FountainModel = Instance.new("Model")
FountainModel.Name = "CentralFountain"
FountainModel.Parent = SpawnHubFolder

CreatePart({
	Name = "FountainBasin",
	Size = Vector3.new(3, 28, 28),
	CFrame = CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Color = Color3.fromRGB(148, 163, 184),
	Shape = Enum.PartType.Cylinder,
	Parent = FountainModel,
})

CreatePart({
	Name = "FountainWaterPool",
	Size = Vector3.new(3.2, 24, 24),
	CFrame = CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Color = Color3.fromRGB(56, 189, 248),
	Material = Enum.Material.Neon,
	Transparency = 0.25,
	Shape = Enum.PartType.Cylinder,
	Parent = FountainModel,
})

CreatePart({
	Name = "FountainMidTier",
	Size = Vector3.new(6, 14, 14),
	CFrame = CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Color = Color3.fromRGB(203, 213, 225),
	Shape = Enum.PartType.Cylinder,
	Parent = FountainModel,
})

local FountainTopCrystal = CreatePart({
	Name = "FountainCrystalSpire",
	Size = Vector3.new(4.5, 11, 4.5),
	Position = Vector3.new(0, 11, 0),
	Color = Color3.fromRGB(125, 211, 252),
	Material = Enum.Material.Neon,
	Parent = FountainModel,
})
AttachFloatingBillboard(FountainTopCrystal, "REBIRTH CHAMPIONS HUB", "World Boost: x1 Clicks", Color3.fromRGB(56, 189, 248), 8)

local WaterParticles = Instance.new("ParticleEmitter")
WaterParticles.Color = ColorSequence.new(Color3.fromRGB(186, 230, 253))
WaterParticles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
WaterParticles.Rate = 45
WaterParticles.Lifetime = NumberRange.new(1.2, 1.8)
WaterParticles.Speed = NumberRange.new(14, 20)
WaterParticles.SpreadAngle = Vector2.new(35, 35)
WaterParticles.Acceleration = Vector3.new(0, -28, 0)
WaterParticles.Parent = FountainTopCrystal

local BuildingsFolder = Instance.new("Folder")
BuildingsFolder.Name = "MainBuildings"
BuildingsFolder.Parent = SpawnHubFolder

local function BuildStylizedBuilding(config: {
	Name: string,
	Storeys: number,
	RoofColor: Color3,
	WallColor: Color3,
	BaseCFrame: CFrame,
	Title: string,
	Subtitle: string,
	ActionText: string,
})
	local bModel = Instance.new("Model")
	bModel.Name = config.Name
	bModel.Parent = BuildingsFolder

	local floorHeight = 11
	local totalHeight = config.Storeys * floorHeight

	local body = CreatePart({
		Name = "BuildingBody",
		Size = Vector3.new(22, totalHeight, 18),
		CFrame = config.BaseCFrame * CFrame.new(0, totalHeight / 2, 0),
		Color = config.WallColor,
		Parent = bModel,
	})

	for s = 1, config.Storeys do
		CreatePart({
			Name = "FloorTrim_" .. tostring(s),
			Size = Vector3.new(23, 1.2, 19),
			CFrame = config.BaseCFrame * CFrame.new(0, s * floorHeight, 0),
			Color = Color3.fromRGB(71, 85, 105),
			Parent = bModel,
		})
	end

	local roof = CreatePart({
		Name = "BuildingRoof",
		Size = Vector3.new(25, 5, 21),
		CFrame = config.BaseCFrame * CFrame.new(0, totalHeight + 2.5, 0),
		Color = config.RoofColor,
		Material = Enum.Material.SmoothPlastic,
		Parent = bModel,
	})
	AttachFloatingBillboard(roof, config.Title, config.Subtitle, config.RoofColor, 5)

	local pad = CreatePart({
		Name = "InteractionPad",
		Size = Vector3.new(1, 9, 9),
		CFrame = config.BaseCFrame * CFrame.new(0, 0.5, 13) * CFrame.Angles(0, 0, math.rad(90)),
		Color = config.RoofColor,
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Cylinder,
		Parent = bModel,
	})
	local prompt = AttachPrompt(pad, config.ActionText, config.Title, 14)

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local openModalEvent = if remotes then remotes:FindFirstChild("OpenModalClientEvent") :: RemoteEvent? else nil
	if not openModalEvent and remotes then
		openModalEvent = Instance.new("RemoteEvent")
		openModalEvent.Name = "OpenModalClientEvent"
		openModalEvent.Parent = remotes
	end

	prompt.Triggered:Connect(function(player: Player)
		if openModalEvent then
			local modalTarget = "Upgrades"
			if config.Name == "ExclusiveShopBuilding" then
				modalTarget = "GamepassShop"
			elseif config.Name == "PotionsBuilding" then
				modalTarget = "Potions"
			end
			openModalEvent:FireClient(player, modalTarget)
		end
	end)

	return body, pad
end

BuildStylizedBuilding({
	Name = "ExclusiveShopBuilding",
	Storeys = 2,
	RoofColor = Color3.fromRGB(37, 99, 235),
	WallColor = Color3.fromRGB(248, 250, 252),
	BaseCFrame = CFrame.new(-48, 0, -24) * CFrame.Angles(0, math.rad(65), 0),
	Title = "EXCLUSIVE SHOP",
	Subtitle = "Atap Biru · 2 Lantai (Gamepasses & Codes)",
	ActionText = "Buka Exclusive Shop",
})

BuildStylizedBuilding({
	Name = "PotionsBuilding",
	Storeys = 3,
	RoofColor = Color3.fromRGB(147, 51, 234),
	WallColor = Color3.fromRGB(243, 232, 255),
	BaseCFrame = CFrame.new(-54, 0, 4) * CFrame.Angles(0, math.rad(90), 0),
	Title = "POTIONS SHOP",
	Subtitle = "Atap Ungu · 3 Lantai (Clicks, Gems, Luck & Mutation Boosts)",
	ActionText = "Beli Potions",
})

BuildStylizedBuilding({
	Name = "UpgradesBuilding",
	Storeys = 1,
	RoofColor = Color3.fromRGB(22, 163, 74),
	WallColor = Color3.fromRGB(240, 253, 244),
	BaseCFrame = CFrame.new(-48, 0, 32) * CFrame.Angles(0, math.rad(115), 0),
	Title = "UPGRADES SHOP",
	Subtitle = "Atap Hijau · 1 Lantai (Rebirth Buttons, Autoclicker & Luck)",
	ActionText = "Upgrade Pakai Gems",
})

local EggsFolder = Instance.new("Folder")
EggsFolder.Name = "EggPedestals"
EggsFolder.Parent = SpawnHubFolder

local SPAWN_EGGS_LAYOUT = {
	{ EggId = "Basic", Title = "Basic Egg", CostText = "250 Clicks", Color = Color3.fromRGB(248, 250, 252), Pos = Vector3.new(38, 0, -18) },
	{ EggId = "Forest", Title = "Forest Egg", CostText = "5,000 Clicks", Color = Color3.fromRGB(74, 222, 128), Pos = Vector3.new(44, 0, -6) },
	{ EggId = "Mythic", Title = "Mythic Egg", CostText = "25,000 Clicks", Color = Color3.fromRGB(192, 132, 252), Pos = Vector3.new(44, 0, 8) },
	{ EggId = "Farm", Title = "Farm Egg", CostText = "100,000 Clicks", Color = Color3.fromRGB(250, 204, 21), Pos = Vector3.new(38, 0, 20) },
}

for _, eggInfo in ipairs(SPAWN_EGGS_LAYOUT) do
	local pedModel = Instance.new("Model")
	pedModel.Name = eggInfo.EggId .. "_Stand"
	pedModel.Parent = EggsFolder

	CreatePart({
		Name = "PedestalBase",
		Size = Vector3.new(2.2, 7.5, 7.5),
		CFrame = CFrame.new(eggInfo.Pos + Vector3.new(0, 1.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(71, 85, 105),
		Shape = Enum.PartType.Cylinder,
		Parent = pedModel,
	})

	local eggMeshPart = CreatePart({
		Name = "EggMesh",
		Size = Vector3.new(4.8, 6.2, 4.8),
		Position = eggInfo.Pos + Vector3.new(0, 5.2, 0),
		Color = eggInfo.Color,
		Material = Enum.Material.SmoothPlastic,
		Shape = Enum.PartType.Ball,
		Parent = pedModel,
	})
	eggMeshPart:SetAttribute("EggId", eggInfo.EggId)

	AttachFloatingBillboard(eggMeshPart, eggInfo.Title, "Harga: " .. eggInfo.CostText, eggInfo.Color, 4.8)

	local hatchPrompt = AttachPrompt(eggMeshPart, "Buka Menu Hatch Telur", eggInfo.Title, 11)
	hatchPrompt.Triggered:Connect(function(player: Player)
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local openModalEvent = if remotes then remotes:FindFirstChild("OpenModalClientEvent") :: RemoteEvent? else nil
		if openModalEvent then
			openModalEvent:FireClient(player, "EggHatch_" .. eggInfo.EggId)
		end
	end)

	task.spawn(function()
		local basePos = eggMeshPart.Position
		local angle = 0
		while eggMeshPart.Parent do
			angle += 0.04
			eggMeshPart.CFrame = CFrame.new(basePos + Vector3.new(0, math.sin(angle * 2) * 0.45, 0))
				* CFrame.Angles(0, angle, math.rad(math.sin(angle * 3) * 6))
			task.wait(0.03)
		end
	end)
end

local PortalsFolder = Instance.new("Folder")
PortalsFolder.Name = "WorldPortalsSemiCircle"
PortalsFolder.Parent = SpawnHubFolder

local FEATURED_PORTAL_WORLDS = {
	{ Id = "Farm", Name = "Farm World", ReqText = "25 Rebirths", BoostText = "x2 Clicks", Color = Color3.fromRGB(132, 204, 22) },
	{ Id = "Desert", Name = "Desert World", ReqText = "500 Rebirths", BoostText = "x5 Clicks", Color = Color3.fromRGB(245, 158, 11) },
	{ Id = "Nuclear", Name = "Nuclear World", ReqText = "30K Rebirths", BoostText = "x500 Clicks", Color = Color3.fromRGB(34, 197, 94) },
	{ Id = "Atlantis", Name = "Atlantis World", ReqText = "500K Rebirths", BoostText = "x4 Clicks · Auras", Color = Color3.fromRGB(14, 165, 233) },
	{ Id = "Kingdom", Name = "Kingdom World", ReqText = "2.5M Rebirths", BoostText = "x9 Clicks · Clans", Color = Color3.fromRGB(234, 179, 8) },
	{ Id = "Cave", Name = "Cave World", ReqText = "500M Rebirths", BoostText = "x2,500 · Mining", Color = Color3.fromRGB(99, 102, 241) },
	{ Id = "Sakura", Name = "Sakura World", ReqText = "1T Rebirths", BoostText = "x1,500 · Dungeon", Color = Color3.fromRGB(244, 114, 182) },
	{ Id = "Moon", Name = "Moon World (Space)", ReqText = "4T Rebirths", BoostText = "Galaxy Machine", Color = Color3.fromRGB(168, 85, 247) },
	{ Id = "Skylands", Name = "Skylands Dimension", ReqText = "5Qd Rebirths", BoostText = "Fishing & Sky Eggs", Color = Color3.fromRGB(56, 189, 248) },
	{ Id = "ParadoxSpawn", Name = "Paradox Dimension", ReqText = "1Qn Rebirths", BoostText = "Rainbow Machine", Color = Color3.fromRGB(244, 63, 94) },
}

local totalPortals = #FEATURED_PORTAL_WORLDS
local semiCircleRadius = 62

for i, pInfo in ipairs(FEATURED_PORTAL_WORLDS) do
	local t = (i - 1) / (totalPortals - 1)
	local theta = math.rad(-75 + (t * 150))
	local px = math.sin(theta) * semiCircleRadius
	local pz = -math.cos(theta) * semiCircleRadius - 12
	local portalCFrame = CFrame.lookAt(Vector3.new(px, 0, pz), Vector3.new(0, 0, 0))

	local portalModel = Instance.new("Model")
	portalModel.Name = "Portal_" .. pInfo.Id
	portalModel.Parent = PortalsFolder

	CreatePart({
		Name = "PortalFrame",
		Size = Vector3.new(9.5, 14, 2),
		CFrame = portalCFrame * CFrame.new(0, 7, 0),
		Color = Color3.fromRGB(30, 41, 59),
		Parent = portalModel,
	})

	local vortex = CreatePart({
		Name = "PortalVortex",
		Size = Vector3.new(7.5, 12, 2.4),
		CFrame = portalCFrame * CFrame.new(0, 7, 0),
		Color = pInfo.Color,
		Material = Enum.Material.Neon,
		Transparency = 0.15,
		CanCollide = false,
		Parent = portalModel,
	})

	AttachFloatingBillboard(vortex, pInfo.Name, pInfo.ReqText .. " | " .. pInfo.BoostText, pInfo.Color, 8.5)

	local islandFolder = Instance.new("Folder")
	islandFolder.Name = pInfo.Id
	islandFolder.Parent = WorldsContainer

	local islandPosition = Vector3.new((i - 5) * 260, 120 + (i * 25), -550)
	CreatePart({
		Name = "IslandPlatform",
		Size = Vector3.new(110, 8, 110),
		Position = islandPosition,
		Color = pInfo.Color,
		Material = Enum.Material.SmoothPlastic,
		Parent = islandFolder,
	})

	local teleportSpawn = CreatePart({
		Name = "TeleportSpawn",
		Size = Vector3.new(10, 1, 10),
		Position = islandPosition + Vector3.new(0, 4.5, 30),
		Color = Color3.fromRGB(255, 255, 255),
		Material = Enum.Material.Neon,
		Parent = islandFolder,
	})
	AttachFloatingBillboard(teleportSpawn, pInfo.Name, pInfo.BoostText, pInfo.Color, 6)

	local returnPad = CreatePart({
		Name = "ReturnToSpawnPortal",
		Size = Vector3.new(7, 11, 2),
		Position = islandPosition + Vector3.new(0, 9.5, 46),
		Color = Color3.fromRGB(56, 189, 248),
		Material = Enum.Material.Neon,
		Parent = islandFolder,
	})
	AttachFloatingBillboard(returnPad, "KEMBALI KE SPAWN", "Teleport Gratis", Color3.fromRGB(56, 189, 248), 7)
	local returnPrompt = AttachPrompt(returnPad, "Kembali ke Spawn Hub", "Spawn Portal", 12)
	returnPrompt.Triggered:Connect(function(player: Player)
		local char = player.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if hrp then
			hrp.CFrame = SpawnPad.CFrame + Vector3.new(0, 4, 0)
		end
	end)

	local enterPrompt = AttachPrompt(vortex, "Masuk ke " .. pInfo.Name, pInfo.ReqText, 12)
	enterPrompt.Triggered:Connect(function(player: Player)
		local char = player.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if not hrp then return end

		local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil
		local req = 0
		for _, w in ipairs(Config.Worlds) do
			if w.Name == pInfo.Name or w.Name:find(pInfo.Id) then
				req = w.RebirthReq
				break
			end
		end
		if not profile or profile.Rebirths >= req then
			hrp.CFrame = teleportSpawn.CFrame + Vector3.new(0, 4, 0)
		end
	end)

	-- Spawning Part Interaktif Minigame Fisik di Pulau Tertentu
	if pInfo.Id == "Desert" then
		local cactus = CreatePart({
			Name = "Minigame_CactusTree",
			Size = Vector3.new(6, 16, 6),
			Position = islandPosition + Vector3.new(25, 12, 0),
			Color = Color3.fromRGB(34, 197, 94),
			Material = Enum.Material.Wood,
			Parent = islandFolder,
		})
		AttachFloatingBillboard(cactus, "Cactus Tree", "HP: 100 | Yield: Wood & Fragments", Color3.fromRGB(34, 197, 94), 10)
		local chopPrompt = AttachPrompt(cactus, "Tebang Pohon Cactus", "Felling Minigame", 12)
		chopPrompt.Triggered:Connect(function(player: Player)
			local rem = ReplicatedStorage:FindFirstChild("Remotes")
			local f = if rem then rem:FindFirstChild("MinigameChopTreeFunction") :: RemoteFunction? else nil
			if f then f:InvokeClient(player) end
		end)
	elseif pInfo.Id == "Kingdom" then
		local oak = CreatePart({
			Name = "Minigame_KingdomOak",
			Size = Vector3.new(8, 22, 8),
			Position = islandPosition + Vector3.new(25, 15, 0),
			Color = Color3.fromRGB(180, 83, 9),
			Material = Enum.Material.Wood,
			Parent = islandFolder,
		})
		AttachFloatingBillboard(oak, "Kingdom Oak Tree", "HP: 450 | Yield: Wood & Royal Fragments", Color3.fromRGB(245, 158, 11), 13)
		local oakPrompt = AttachPrompt(oak, "Tebang Pohon Oak", "Felling Minigame", 12)
		oakPrompt.Triggered:Connect(function(player: Player)
			local rem = ReplicatedStorage:FindFirstChild("Remotes")
			local f = if rem then rem:FindFirstChild("MinigameChopTreeFunction") :: RemoteFunction? else nil
			if f then f:InvokeClient(player) end
		end)
	elseif pInfo.Id == "Cave" then
		local ruby = CreatePart({
			Name = "Minigame_RubyVein",
			Size = Vector3.new(8, 8, 8),
			Position = islandPosition + Vector3.new(-25, 8, 0),
			Color = Color3.fromRGB(239, 68, 68),
			Material = Enum.Material.Neon,
			Parent = islandFolder,
		})
		AttachFloatingBillboard(ruby, "Ruby Ore Node", "HP: 300 | Yield: Space Stones", Color3.fromRGB(239, 68, 68), 6)
		local minePrompt = AttachPrompt(ruby, "Tambang Ruby Ore", "Mining Minigame", 12)
		minePrompt.Triggered:Connect(function(player: Player)
			local rem = ReplicatedStorage:FindFirstChild("Remotes")
			local f = if rem then rem:FindFirstChild("MinigameMineOreFunction") :: RemoteFunction? else nil
			if f then f:InvokeClient(player) end
		end)
	elseif pInfo.Id == "Sakura" then
		local dungeonPortal = CreatePart({
			Name = "Minigame_DungeonGate",
			Size = Vector3.new(12, 16, 3),
			Position = islandPosition + Vector3.new(0, 12, -30),
			Color = Color3.fromRGB(244, 114, 182),
			Material = Enum.Material.Neon,
			Parent = islandFolder,
		})
		AttachFloatingBillboard(dungeonPortal, "Sakura Dungeon (Wave Combat)", "5 Waves · Boss HP 5K · Drop Divine Pet", Color3.fromRGB(244, 114, 182), 10)
		local dPrompt = AttachPrompt(dungeonPortal, "Masuk Sakura Dungeon Floor 1", "Combat Minigame", 14)
		dPrompt.Triggered:Connect(function(player: Player)
			local rem = ReplicatedStorage:FindFirstChild("Remotes")
			local f = if rem then rem:FindFirstChild("MinigameRunDungeonFunction") :: RemoteFunction? else nil
			if f then f:InvokeClient(player) end
		end)
	end
end

local MachinesFolder = Instance.new("Folder")
MachinesFolder.Name = "CraftingAndAuraMachines"
MachinesFolder.Parent = SpawnHubFolder

local MACHINE_PODS = {
	{ Name = "Golden Pets Machine", Tier = "Golden", Sub = "5 Normal = 100% Golden (2x Stat)", Color = Color3.fromRGB(250, 204, 21), Pos = Vector3.new(-24, 0, 48) },
	{ Name = "Nuclear Toxic Machine", Tier = "Toxic", Sub = "5 Golden = 100% Toxic (4x Stat)", Color = Color3.fromRGB(57, 255, 20), Pos = Vector3.new(-8, 0, 52) },
	{ Name = "Galaxy Pets Machine", Tier = "Galaxy", Sub = "5 Toxic = 100% Galaxy (8x Stat)", Color = Color3.fromRGB(168, 85, 247), Pos = Vector3.new(8, 0, 52) },
	{ Name = "Rainbow Pet Machine", Tier = "Rainbow", Sub = "5 Galaxy = 100% Rainbow (16x Stat)", Color = Color3.fromRGB(244, 63, 94), Pos = Vector3.new(24, 0, 48) },
	{ Name = "Atlantis Auras Machine", Tier = "AuraRoll", Sub = "Roll Dadu Aura (1/1 s/d 1/100B Dark Matter)", Color = Color3.fromRGB(56, 189, 248), Pos = Vector3.new(0, 0, -28) },
}

for _, pod in ipairs(MACHINE_PODS) do
	local podModel = Instance.new("Model")
	podModel.Name = pod.Name
	podModel.Parent = MachinesFolder

	local glassPod = CreatePart({
		Name = "CapsulePod",
		Size = Vector3.new(9, 7, 7),
		CFrame = CFrame.new(pod.Pos + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = pod.Color,
		Material = Enum.Material.ForceField,
		Transparency = 0.2,
		Shape = Enum.PartType.Cylinder,
		Parent = podModel,
	})

	AttachFloatingBillboard(glassPod, pod.Name, pod.Sub, pod.Color, 6.5)
	local machinePrompt = AttachPrompt(glassPod, "Gunakan " .. pod.Name, pod.Sub, 12)

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local openModalEvent = if remotes then remotes:FindFirstChild("OpenModalClientEvent") :: RemoteEvent? else nil

	machinePrompt.Triggered:Connect(function(player: Player)
		if openModalEvent then
			if pod.Tier == "AuraRoll" then
				openModalEvent:FireClient(player, "AuraRoll")
			else
				openModalEvent:FireClient(player, "CraftMachine_" .. pod.Tier)
			end
		end
	end)
end

-- 3. ANTI-FALL RESPAWN (SAFETY NET)
task.spawn(function()
	local PlayersService = game:GetService("Players")
	while true do
		task.wait(0.5)
		for _, player in ipairs(PlayersService:GetPlayers()) do
			local char = player.Character
			local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			if hrp and hrp.Position.Y < -40 then
				hrp.Velocity = Vector3.zero
				hrp.CFrame = SpawnPad.CFrame + Vector3.new(0, 4, 0)
			end
		end
	end
end)

print("[AutoBuilderSpawnMap3D] Seluruh Spawn Hub, 3 Gedung, Egg Pedestals, Semi-Circle Portals, dan Crafting Pods berhasil dibangun")

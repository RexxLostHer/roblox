local Config = {}

-- 1. Metadata Mutasi & Warna Shading
Config.MutationTiers = {
	Order = { "Normal", "Golden", "Toxic", "Galaxy", "Rainbow" },
	Tiers = {
		Normal = {
			Multiplier = 1.0,
			ShinyMultiplier = 1.5,
			Color = Color3.fromRGB(255, 255, 255),
			MachineName = "None",
		},
		Golden = {
			Multiplier = 2.0,
			ShinyMultiplier = 3.0,
			Color = Color3.fromRGB(255, 204, 0),
			MachineName = "Golden Machine (Farm World)",
		},
		Toxic = {
			Multiplier = 4.0,
			ShinyMultiplier = 6.0,
			Color = Color3.fromRGB(57, 255, 20),
			MachineName = "Nuclear Machine (Nuclear World)",
		},
		Galaxy = {
			Multiplier = 8.0,
			ShinyMultiplier = 12.0,
			Color = Color3.fromRGB(168, 85, 247),
			MachineName = "Galaxy Machine (Moon World)",
		},
		Rainbow = {
			Multiplier = 16.0,
			ShinyMultiplier = 24.0,
			Color = Color3.fromRGB(255, 85, 255),
			MachineName = "Rainbow Machine (Paradox Spawn)",
		},
	},
}

-- 2. Daftar 58 Pulau & World Boost
Config.Worlds = {
	{ Id = 1, Name = "Spawn", Dimension = "Overworld", RebirthReq = 0, WorldBoost = 1 },
	{ Id = 2, Name = "Farm", Dimension = "Overworld", RebirthReq = 25, WorldBoost = 2 },
	{ Id = 3, Name = "Desert", Dimension = "Overworld", RebirthReq = 500, WorldBoost = 5 },
	{ Id = 4, Name = "Nuclear", Dimension = "Overworld", RebirthReq = 30000, WorldBoost = 500 },
	{ Id = 5, Name = "Atlantis", Dimension = "Overworld", RebirthReq = 500000, WorldBoost = 4 },
	{ Id = 6, Name = "Kingdom", Dimension = "Overworld", RebirthReq = 2500000, WorldBoost = 9 },
	{ Id = 7, Name = "City", Dimension = "Overworld", RebirthReq = 50000000, WorldBoost = 60 },
	{ Id = 8, Name = "Cave", Dimension = "Overworld", RebirthReq = 500000000, WorldBoost = 2500 },
	{ Id = 9, Name = "Volcano", Dimension = "Overworld", RebirthReq = 1250000000, WorldBoost = 15 },
	{ Id = 10, Name = "Heaven", Dimension = "Overworld", RebirthReq = 5000000000, WorldBoost = 350 },
	{ Id = 11, Name = "Magic", Dimension = "Overworld", RebirthReq = 25000000000, WorldBoost = 120 },
	{ Id = 12, Name = "Circus", Dimension = "Overworld", RebirthReq = 50000000000, WorldBoost = 200 },
	{ Id = 13, Name = "Jungle", Dimension = "Overworld", RebirthReq = 125000000000, WorldBoost = 400 },
	{ Id = 14, Name = "Steampunk", Dimension = "Overworld", RebirthReq = 350000000000, WorldBoost = 800 },
	{ Id = 15, Name = "Sakura", Dimension = "Overworld", RebirthReq = 1000000000000, WorldBoost = 1500 },
	{ Id = 16, Name = "Lab", Dimension = "Overworld", RebirthReq = 2000000000000, WorldBoost = 3000 },
	{ Id = 17, Name = "Moon", Dimension = "Space", RebirthReq = 4000000000000, WorldBoost = 5000 },
	{ Id = 18, Name = "Alien", Dimension = "Space", RebirthReq = 6000000000000, WorldBoost = 7500 },
	{ Id = 19, Name = "Tech City", Dimension = "Space", RebirthReq = 10000000000000, WorldBoost = 10000 },
	{ Id = 20, Name = "Nebula Forest", Dimension = "Space", RebirthReq = 25000000000000, WorldBoost = 15000 },
	{ Id = 21, Name = "Void", Dimension = "Space", RebirthReq = 50000000000000, WorldBoost = 25000 },
	{ Id = 22, Name = "Spaceship", Dimension = "Space", RebirthReq = 100000000000000, WorldBoost = 40000 },
	{ Id = 23, Name = "Space Warzone", Dimension = "Space", RebirthReq = 200000000000000, WorldBoost = 60000 },
	{ Id = 24, Name = "Comet", Dimension = "Space", RebirthReq = 500000000000000, WorldBoost = 100000 },
	{ Id = 25, Name = "Starfactory", Dimension = "Space", RebirthReq = 750000000000000, WorldBoost = 150000 },
	{ Id = 26, Name = "Glacier Moon", Dimension = "Space", RebirthReq = 1000000000000000, WorldBoost = 250000 },
	{ Id = 27, Name = "Mars Colony", Dimension = "Space", RebirthReq = 1500000000000000, WorldBoost = 400000 },
	{ Id = 28, Name = "Starfall Valley", Dimension = "Space", RebirthReq = 2000000000000000, WorldBoost = 600000 },
	{ Id = 29, Name = "Black Hole", Dimension = "Space", RebirthReq = 3000000000000000, WorldBoost = 1000000 },
	{ Id = 30, Name = "Skylands", Dimension = "Skylands", RebirthReq = 5000000000000000, WorldBoost = 2000000 },
	{ Id = 31, Name = "Sky Garden", Dimension = "Skylands", RebirthReq = 10000000000000000, WorldBoost = 3500000 },
	{ Id = 32, Name = "Cloudy World", Dimension = "Skylands", RebirthReq = 15000000000000000, WorldBoost = 5000000 },
	{ Id = 33, Name = "Ashwind Realm", Dimension = "Skylands", RebirthReq = 20000000000000000, WorldBoost = 7500000 },
	{ Id = 34, Name = "Frozen Forest", Dimension = "Skylands", RebirthReq = 25000000000000000, WorldBoost = 10000000 },
	{ Id = 35, Name = "Ancient Ruins", Dimension = "Skylands", RebirthReq = 30000000000000000, WorldBoost = 15000000 },
	{ Id = 36, Name = "Monochrome", Dimension = "Skylands", RebirthReq = 35000000000000000, WorldBoost = 20000000 },
	{ Id = 37, Name = "Wild West", Dimension = "Skylands", RebirthReq = 40000000000000000, WorldBoost = 25000000 },
	{ Id = 38, Name = "Bee World", Dimension = "Skylands", RebirthReq = 50000000000000000, WorldBoost = 35000000 },
	{ Id = 39, Name = "Neon", Dimension = "Skylands", RebirthReq = 60000000000000000, WorldBoost = 50000000 },
	{ Id = 40, Name = "Thunder Isles", Dimension = "Skylands", RebirthReq = 75000000000000000, WorldBoost = 70000000 },
	{ Id = 41, Name = "Sunken Temple", Dimension = "Skylands", RebirthReq = 100000000000000000, WorldBoost = 100000000 },
	{ Id = 42, Name = "Swamp", Dimension = "Skylands", RebirthReq = 125000000000000000, WorldBoost = 150000000 },
	{ Id = 43, Name = "Crystal Islands", Dimension = "Skylands", RebirthReq = 150000000000000000, WorldBoost = 200000000 },
	{ Id = 44, Name = "Blossom Clouds", Dimension = "Skylands", RebirthReq = 200000000000000000, WorldBoost = 300000000 },
	{ Id = 45, Name = "Aurora", Dimension = "Skylands", RebirthReq = 250000000000000000, WorldBoost = 450000000 },
	{ Id = 46, Name = "Obsidian Spires", Dimension = "Skylands", RebirthReq = 300000000000000000, WorldBoost = 600000000 },
	{ Id = 47, Name = "Samurai", Dimension = "Skylands", RebirthReq = 400000000000000000, WorldBoost = 800000000 },
	{ Id = 48, Name = "Skyward Falls", Dimension = "Skylands", RebirthReq = 500000000000000000, WorldBoost = 1000000000 },
	{ Id = 49, Name = "Paradox Spawn", Dimension = "Paradox", RebirthReq = 1000000000000000000, WorldBoost = 2000000000 },
	{ Id = 50, Name = "Primitive Fields", Dimension = "Paradox", RebirthReq = 2500000000000000000, WorldBoost = 5000000000 },
	{ Id = 51, Name = "Dino World", Dimension = "Paradox", RebirthReq = 5000000000000000000, WorldBoost = 10000000000 },
	{ Id = 52, Name = "Sandy Dunes", Dimension = "Paradox", RebirthReq = 10000000000000000000, WorldBoost = 25000000000 },
	{ Id = 53, Name = "Atomic World", Dimension = "Paradox", RebirthReq = 25000000000000000000, WorldBoost = 50000000000 },
	{ Id = 54, Name = "Magnetar Yard", Dimension = "Paradox", RebirthReq = 50000000000000000000, WorldBoost = 100000000000 },
	{ Id = 55, Name = "Sunken Village", Dimension = "Paradox", RebirthReq = 100000000000000000000, WorldBoost = 250000000000 },
	{ Id = 56, Name = "Carnival City", Dimension = "Paradox", RebirthReq = 200000000000000000000, WorldBoost = 500000000000 },
	{ Id = 57, Name = "Glitched World", Dimension = "Paradox", RebirthReq = 300000000000000000000, WorldBoost = 1000000000000 },
	{ Id = 58, Name = "Enchanted Mansion", Dimension = "Paradox", RebirthReq = 500000000000000000000, WorldBoost = 2500000000000 },
}

-- 3. Database Telur & Drops
Config.Eggs = {
	Basic = {
		Cost = 250,
		Pets = {
			{ Name = "Dog", Weight = 50, Stat = 1.2 },
			{ Name = "Cat", Weight = 35, Stat = 1.4 },
			{ Name = "Bunny", Weight = 15, Stat = 2.0 },
		},
	},
	Forest = {
		Cost = 5000,
		Pets = {
			{ Name = "Bear", Weight = 50, Stat = 3.0 },
			{ Name = "Wolf", Weight = 30, Stat = 4.5 },
			{ Name = "Fox", Weight = 17, Stat = 6.0 },
			{ Name = "Forest Dragon", Weight = 3, Stat = 10.0 },
		},
	},
	Mythic = {
		Cost = 25000,
		Pets = {
			{ Name = "Fox", Weight = 55, Stat = 9.0 },
			{ Name = "Golem", Weight = 30, Stat = 13.0 },
			{ Name = "Hydra", Weight = 15, Stat = 18.0 },
			{ Name = "Bat", Weight = 5, Stat = 30.0 },
		},
	},
	Farm = {
		Cost = 100000,
		Pets = {
			{ Name = "Pig", Weight = 50, Stat = 40.0 },
			{ Name = "Duck", Weight = 30, Stat = 65.0 },
			{ Name = "Cow", Weight = 16, Stat = 100.0 },
			{ Name = "Goat", Weight = 4.75, Stat = 250.0 },
			{ Name = "Apple Dragon", Weight = 0.25, Stat = 1200.0 },
		},
	},
}

-- 4. Tap Skins Shop
Config.TapSkins = {
	Grass = { Cost = 0, Multiplier = 1.1 },
	Water = { Cost = 500, Multiplier = 1.3 },
	Light = { Cost = 2500, Multiplier = 1.5 },
	Dark = { Cost = 10000, Multiplier = 1.7 },
	Sun = { Cost = 50000, Multiplier = 2.0 },
	Fire = { Cost = 200000, Multiplier = 2.5 },
	Toxic = { Cost = 1000000, Multiplier = 3.0 },
	Cyber = { Cost = 5000000, Multiplier = 3.6 },
	Galaxy = { Cost = 25000000, Multiplier = 4.2 },
	Candy = { Cost = 100000000, Multiplier = 5.0 },
	Void = { Cost = 500000000, Multiplier = 6.6 },
	Powerful = { Cost = 2500000000, Multiplier = 8.4 },
}

-- 5. Gamepasses (Diskon ~50% Terjangkau)
Config.Gamepasses = {
	MagicEggs = { Id = 0, PriceRobux = 399 },
	SecretsHunter = { Id = 0, PriceRobux = 399 },
	ShinyHunter = { Id = 0, PriceRobux = 399 },
	UltraLucky = { Id = 0, PriceRobux = 399 },
	VIPStatus = { Id = 0, PriceRobux = 249 },
	ExtraEggs = { Id = 0, PriceRobux = 199 },
	Plus3PetsEquipped = { Id = 0, PriceRobux = 199 },
	X3FragmentsLuck = { Id = 0, PriceRobux = 199 },
	X2SpaceCoins = { Id = 0, PriceRobux = 149 },
	FasterEggsOpen = { Id = 0, PriceRobux = 149 },
	InsaneFarmer = { Id = 0, PriceRobux = 149 },
	MegaLucky = { Id = 0, PriceRobux = 99 },
	Plus2PetsEquipped = { Id = 0, PriceRobux = 99 },
	AutoRebirth = { Id = 0, PriceRobux = 79 },
	FastAutoClicker = { Id = 0, PriceRobux = 49 },
	ExtraEnchantSlot1 = { Id = 0, PriceRobux = 99, Description = "+1 Extra Enchant Slot per Pet" },
	ExtraEnchantSlot2 = { Id = 0, PriceRobux = 149, Description = "+2 Extra Enchant Slots per Pet" },
	ExclusiveFantasyEggSingle = { Id = 0, PriceRobux = 29, Description = "1x Buka Exclusive Fantasy Egg (110% - 500% Stat Pet Terbaik)" },
	ExclusiveFantasyEggBundle10 = { Id = 0, PriceRobux = 199, Description = "10x Buka Exclusive Fantasy Egg Sekaligus (Hemat!)" },
}

return Config

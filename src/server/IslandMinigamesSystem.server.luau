--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("RebirthChampionsConfig"))

export type TreeNodeSpec = {
	TreeId: string,
	World: string,
	MaxHP: number,
	BaseWoodYield: number,
	BaseCooldownSeconds: number,
	RoyalFragmentChance: number,
}

export type OreNodeSpec = {
	OreId: string,
	World: string,
	MaxHP: number,
	StoneYield: number,
	RespawnSeconds: number,
}

export type DungeonFloorSpec = {
	Floor: number,
	Name: string,
	RecommendedRebirths: number,
	WavesCount: number,
	BossHP: number,
	BaseDungeonCoinsReward: number,
	DivinePetDropChance: number,
}

local TREE_SPECS: { [string]: TreeNodeSpec } = {
	CactusTree = { TreeId = "CactusTree", World = "Desert", MaxHP = 100, BaseWoodYield = 3, BaseCooldownSeconds = 30, RoyalFragmentChance = 2.0 },
	KingdomOak = { TreeId = "KingdomOak", World = "Kingdom", MaxHP = 450, BaseWoodYield = 5, BaseCooldownSeconds = 30, RoyalFragmentChance = 5.0 },
	MagicTree = { TreeId = "MagicTree", World = "Magic", MaxHP = 2500, BaseWoodYield = 10, BaseCooldownSeconds = 30, RoyalFragmentChance = 12.0 },
}

local ORE_SPECS: { [string]: OreNodeSpec } = {
	RubyVein = { OreId = "RubyVein", World = "Cave", MaxHP = 300, StoneYield = 5, RespawnSeconds = 15 },
	DiamondCrystal = { OreId = "DiamondCrystal", World = "Cave", MaxHP = 1200, StoneYield = 15, RespawnSeconds = 25 },
	VoidSpaceStone = { OreId = "VoidSpaceStone", World = "Void", MaxHP = 8000, StoneYield = 50, RespawnSeconds = 35 },
}

local DUNGEON_FLOORS: { [number]: DungeonFloorSpec } = {
	[1] = { Floor = 1, Name = "Sakura Courtyard", RecommendedRebirths = 1e12, WavesCount = 5, BossHP = 5000, BaseDungeonCoinsReward = 100, DivinePetDropChance = 0.05 },
	[2] = { Floor = 2, Name = "Crimson Dojo", RecommendedRebirths = 25e12, WavesCount = 5, BossHP = 35000, BaseDungeonCoinsReward = 350, DivinePetDropChance = 0.15 },
	[3] = { Floor = 3, Name = "Shogun Sanctum", RecommendedRebirths = 500e12, WavesCount = 5, BossHP = 250000, BaseDungeonCoinsReward = 1200, DivinePetDropChance = 0.50 },
	[4] = { Floor = 4, Name = "Abyssal Blossom", RecommendedRebirths = 50e15, WavesCount = 5, BossHP = 2500000, BaseDungeonCoinsReward = 5000, DivinePetDropChance = 1.50 },
}

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local function GetOrCreateRemote(name: string, className: "RemoteEvent" | "RemoteFunction"): any
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = Remotes
	end
	return r
end

local ChopTreeRemote: RemoteFunction = GetOrCreateRemote("MinigameChopTreeFunction", "RemoteFunction")
local UpgradeToolRemote: RemoteFunction = GetOrCreateRemote("MinigameUpgradeToolFunction", "RemoteFunction")
local MineOreRemote: RemoteFunction = GetOrCreateRemote("MinigameMineOreFunction", "RemoteFunction")
local RunDungeonRemote: RemoteFunction = GetOrCreateRemote("MinigameRunDungeonFunction", "RemoteFunction")

local MinigameProfiles: {
	[number]: {
		Wood: number,
		TreesChopped: number,
		AxeLevel: number,
		MoreWoodUpgradeLevel: number,
		TreeCooldownUpgradeLevel: number,
		SpaceStones: number,
		PickaxeLevel: number,
		DungeonCoins: number,
		DungeonMasteryXP: number,
		TreeCooldowns: { [string]: number },
	}
} = {}

local function GetMinigameState(player: Player)
	local uid = player.UserId
	if not MinigameProfiles[uid] then
		MinigameProfiles[uid] = {
			Wood = 0,
			TreesChopped = 0,
			AxeLevel = 1,
			MoreWoodUpgradeLevel = 0,
			TreeCooldownUpgradeLevel = 0,
			SpaceStones = 0,
			PickaxeLevel = 1,
			DungeonCoins = 0,
			DungeonMasteryXP = 0,
			TreeCooldowns = {},
		}
	end
	return MinigameProfiles[uid]
end

ChopTreeRemote.OnServerInvoke = function(player: Player, treeId: string, isGoldenOrRainbowTree: boolean?)
	local spec = TREE_SPECS[treeId]
	if not spec then
		return { Success = false, Message = "Jenis pohon tidak dikenali." }
	end

	local mgState = GetMinigameState(player)
	local mainProfile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil
	local now = os.clock()

	local readyAt = mgState.TreeCooldowns[treeId] or 0
	if now < readyAt then
		return {
			Success = false,
			Message = string.format("Pohon sedang tumbuh kembali! Tunggu %.1f detik.", readyAt - now),
		}
	end

	local cooldownReduction = math.clamp(mgState.TreeCooldownUpgradeLevel, 0, 5)
	local finalCooldown = spec.BaseCooldownSeconds - cooldownReduction
	mgState.TreeCooldowns[treeId] = now + finalCooldown

	local woodGain = spec.BaseWoodYield + mgState.MoreWoodUpgradeLevel + math.floor(mgState.AxeLevel * 0.5)
	if mainProfile and mainProfile.OwnedGamepasses and mainProfile.OwnedGamepasses["InsaneFarmer"] then
		woodGain *= 2
	end
	if isGoldenOrRainbowTree then
		woodGain *= 3
	end

	mgState.Wood += woodGain
	mgState.TreesChopped += 1

	local fragChance = spec.RoyalFragmentChance * (if isGoldenOrRainbowTree then 3.0 else 1.0)
	local gainedFragments = 0
	if (math.random() * 100) <= fragChance then
		local fragMult = if mainProfile and mainProfile.OwnedGamepasses and mainProfile.OwnedGamepasses["FragmentsLuck3x"] then 3 else 1
		gainedFragments = 1 * fragMult
		if mainProfile then
			mainProfile.Fragments = (mainProfile.Fragments or 0) + gainedFragments
		end
	end

	return {
		Success = true,
		WoodGained = woodGain,
		TotalWood = mgState.Wood,
		TreesChopped = mgState.TreesChopped,
		FragmentsGained = gainedFragments,
		CooldownSeconds = finalCooldown,
		Message = string.format(
			"Menebang %s! +%d Wood (Total: %d)%s",
			treeId,
			woodGain,
			mgState.Wood,
			if gainedFragments > 0 then string.format(" & +%d Royal Fragments!", gainedFragments) else ""
		),
	}
end

UpgradeToolRemote.OnServerInvoke = function(player: Player, toolType: "Axe" | "Pickaxe")
	local mgState = GetMinigameState(player)
	if toolType == "Axe" then
		local costWood = mgState.AxeLevel * 25
		if mgState.Wood < costWood then
			return { Success = false, Message = string.format("Butuh %d Wood untuk upgrade Axe ke Lv.%d!", costWood, mgState.AxeLevel + 1) }
		end
		mgState.Wood -= costWood
		mgState.AxeLevel += 1
		return { Success = true, NewLevel = mgState.AxeLevel, Message = string.format("Axe berhasil di-upgrade ke Level %d!", mgState.AxeLevel) }
	elseif toolType == "Pickaxe" then
		local costStones = mgState.PickaxeLevel * 40
		if mgState.SpaceStones < costStones then
			return { Success = false, Message = string.format("Butuh %d Stones untuk upgrade Pickaxe ke Lv.%d!", costStones, mgState.PickaxeLevel + 1) }
		end
		mgState.SpaceStones -= costStones
		mgState.PickaxeLevel += 1
		return { Success = true, NewLevel = mgState.PickaxeLevel, Message = string.format("Pickaxe berhasil di-upgrade ke Level %d!", mgState.PickaxeLevel) }
	end
	return { Success = false, Message = "Tipe alat tidak valid." }
end

MineOreRemote.OnServerInvoke = function(player: Player, oreId: string)
	local spec = ORE_SPECS[oreId]
	if not spec then
		return { Success = false, Message = "Node tambang tidak ditemukan." }
	end

	local mgState = GetMinigameState(player)
	local mainProfile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil

	local potionStoneMult = 1.0
	if mainProfile and mainProfile.ActivePotions and (mainProfile.ActivePotions["MinerPotion"] or 0) > os.time() then
		potionStoneMult = 1.15
	end

	local stoneGain = math.floor((spec.StoneYield + (mgState.PickaxeLevel * 2)) * potionStoneMult)
	mgState.SpaceStones += stoneGain

	return {
		Success = true,
		StonesGained = stoneGain,
		TotalStones = mgState.SpaceStones,
		Message = string.format("Menambang %s! +%d Space Stones (Total: %d)", oreId, stoneGain, mgState.SpaceStones),
	}
end

RunDungeonRemote.OnServerInvoke = function(player: Player, floorNumber: number)
	local floorSpec = DUNGEON_FLOORS[floorNumber]
	if not floorSpec then
		return { Success = false, Message = "Lantai Dungeon tidak ditemukan." }
	end

	local mgState = GetMinigameState(player)
	local mainProfile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil
	if mainProfile and mainProfile.Rebirths < floorSpec.RecommendedRebirths then
		return {
			Success = false,
			Message = string.format("Kamu butuh minimal %s Rebirths untuk masuk ke %s!", tostring(floorSpec.RecommendedRebirths), floorSpec.Name),
		}
	end

	local coinMult = 1.0
	if mainProfile then
		if mainProfile.OwnedGamepasses and mainProfile.OwnedGamepasses["DungeonCoins2x"] then
			coinMult *= 2.0
		end
		if mainProfile.ActivePotions and (mainProfile.ActivePotions["DungeonPotion"] or 0) > os.time() then
			coinMult *= 1.15
		end
	end

	local earnedCoins = math.floor(floorSpec.BaseDungeonCoinsReward * coinMult)
	local earnedMasteryXP = floorNumber * 25
	mgState.DungeonCoins += earnedCoins
	mgState.DungeonMasteryXP += earnedMasteryXP

	local divineChance = floorSpec.DivinePetDropChance
	if mainProfile and mainProfile.OwnedGamepasses and mainProfile.OwnedGamepasses["FragmentsLuck3x"] then
		divineChance *= 2.0
	end

	local droppedDivinePet = nil
	if (math.random() * 100) <= divineChance and mainProfile and mainProfile.PetInventory then
		droppedDivinePet = {
			UUID = game:GetService("HttpService"):GenerateGUID(false),
			Name = "Dungeon Guardian (Divine)",
			EggId = "DungeonEgg",
			Rarity = "Supreme",
			BaseMultiplier = 20e9 * math.pow(10, floorNumber),
			Mutation = "Normal",
			IsShiny = false,
			Level = 1,
			Locked = true,
			Equipped = false,
		}
		mainProfile.PetInventory[droppedDivinePet.UUID] = droppedDivinePet
	end

	return {
		Success = true,
		FloorCleared = floorSpec.Name,
		CoinsEarned = earnedCoins,
		TotalDungeonCoins = mgState.DungeonCoins,
		MasteryXPEarned = earnedMasteryXP,
		DivinePetDrop = droppedDivinePet,
		Message = string.format(
			"Menyelesaikan %s (5/5 Waves)! +%d Dungeon Coins & +%d Mastery XP%s",
			floorSpec.Name,
			earnedCoins,
			earnedMasteryXP,
			if droppedDivinePet then " + DAPAT DIVINE PET: Dungeon Guardian!" else ""
		),
	}
end

print("[IslandMinigamesSystem] Server system aktif")

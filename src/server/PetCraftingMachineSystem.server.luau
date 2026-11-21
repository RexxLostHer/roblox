--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 5)
local Config = require((sharedFolder and sharedFolder:WaitForChild("RebirthChampionsConfig", 5)) or ReplicatedStorage:WaitForChild("RebirthChampionsConfig"))

export type PetInstance = {
	UUID: string,
	Name: string,
	EggId: string,
	Rarity: string,
	BaseMultiplier: number,
	Mutation: "Normal" | "Golden" | "Toxic" | "Galaxy" | "Rainbow",
	IsShiny: boolean,
	Level: number,
	Locked: boolean,
	Equipped: boolean,
}

export type CraftRequestPayload = {
	MachineType: "Golden" | "Toxic" | "Galaxy" | "Rainbow",
	SelectedPetUUIDs: { string },
}

export type CraftResultPayload = {
	Success: boolean,
	CraftSucceeded: boolean,
	Message: string,
	ChanceUsed: number,
	NewPet: PetInstance?,
	FragmentsAwarded: number?,
	MasteryXPAwarded: number?,
}

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not RemotesFolder then
	RemotesFolder = Instance.new("Folder")
	RemotesFolder.Name = "Remotes"
	RemotesFolder.Parent = ReplicatedStorage
end

local CraftPetRemote = RemotesFolder:FindFirstChild("CraftPetFunction") :: RemoteFunction
if not CraftPetRemote then
	CraftPetRemote = Instance.new("RemoteFunction")
	CraftPetRemote.Name = "CraftPetFunction"
	CraftPetRemote.Parent = RemotesFolder
end

local MachineRequirements: { [string]: { RequiredInputTier: string, OutputTier: "Golden" | "Toxic" | "Galaxy" | "Rainbow", RequiredRebirths: number } } = {
	Golden = {
		RequiredInputTier = "Normal",
		OutputTier = "Golden",
		RequiredRebirths = 25,
	},
	Toxic = {
		RequiredInputTier = "Golden",
		OutputTier = "Toxic",
		RequiredRebirths = 30000,
	},
	Galaxy = {
		RequiredInputTier = "Toxic",
		OutputTier = "Galaxy",
		RequiredRebirths = 2.5e12,
	},
	Rainbow = {
		RequiredInputTier = "Galaxy",
		OutputTier = "Rainbow",
		RequiredRebirths = 1e18,
	},
}

local CraftCooldowns: { [number]: number } = {}

local function CalculateFinalPetMultiplier(baseMult: number, mutation: string, isShiny: boolean, level: number): number
	local tierInfo = Config.MutationTiers and Config.MutationTiers.Tiers and Config.MutationTiers.Tiers[mutation]
	local mult = 1.0
	if tierInfo then
		mult = if isShiny then (tierInfo.ShinyMultiplier or 1.5) else (tierInfo.Multiplier or 1.0)
	end
	return baseMult * mult * (level or 1)
end

local function ProcessPetCraft(player: Player, payload: CraftRequestPayload): CraftResultPayload
	local userId = player.UserId
	local now = os.clock()

	if CraftCooldowns[userId] and (now - CraftCooldowns[userId]) < 0.4 then
		return {
			Success = false,
			CraftSucceeded = false,
			Message = "Tunggu sebentar sebelum melakukan crafting lagi!",
			ChanceUsed = 0,
		}
	end
	CraftCooldowns[userId] = now

	if type(payload) ~= "table" or type(payload.MachineType) ~= "string" or type(payload.SelectedPetUUIDs) ~= "table" then
		return {
			Success = false,
			CraftSucceeded = false,
			Message = "Payload request tidak valid.",
			ChanceUsed = 0,
		}
	end

	local machineRule = MachineRequirements[payload.MachineType]
	if not machineRule then
		return {
			Success = false,
			CraftSucceeded = false,
			Message = "Tipe mesin tidak dikenali.",
			ChanceUsed = 0,
		}
	end

	local mainProfile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil
	local currentRebirths = if mainProfile then mainProfile.Rebirths else 0

	if currentRebirths < machineRule.RequiredRebirths then
		return {
			Success = false,
			CraftSucceeded = false,
			Message = string.format("Kamu butuh minimal %s Rebirths untuk memakai mesin %s!", tostring(machineRule.RequiredRebirths), payload.MachineType),
			ChanceUsed = 0,
		}
	end

	local count = #payload.SelectedPetUUIDs
	local maxSlots = 5
	if count < 1 or count > maxSlots then
		return {
			Success = false,
			CraftSucceeded = false,
			Message = string.format("Masukkan antara 1 hingga %d Pet yang sama!", maxSlots),
			ChanceUsed = 0,
		}
	end

	if not mainProfile or not mainProfile.PetInventory then
		return {
			Success = false,
			CraftSucceeded = false,
			Message = "Inventori pemain belum dimuat.",
			ChanceUsed = 0,
		}
	end

	local inventory = mainProfile.PetInventory
	local seenUUID: { [string]: boolean } = {}
	local selectedPets: { PetInstance } = {}
	local referencePet: PetInstance? = nil
	local shinyCount = 0
	local highestLevel = 1

	for _, uuid in ipairs(payload.SelectedPetUUIDs) do
		if type(uuid) ~= "string" or seenUUID[uuid] then
			return {
				Success = false,
				CraftSucceeded = false,
				Message = "Terdeteksi duplikasi slot Pet!",
				ChanceUsed = 0,
			}
		end
		seenUUID[uuid] = true

		local pet = inventory[uuid]
		if not pet then
			return {
				Success = false,
				CraftSucceeded = false,
				Message = "Salah satu Pet tidak ditemukan di inventorimu.",
				ChanceUsed = 0,
			}
		end

		if pet.Locked then
			return {
				Success = false,
				CraftSucceeded = false,
				Message = "Pet yang dikunci (Locked) tidak bisa dimasukkan ke mesin crafting!",
				ChanceUsed = 0,
			}
		end

		if pet.Mutation ~= machineRule.RequiredInputTier then
			return {
				Success = false,
				CraftSucceeded = false,
				Message = string.format("Mesin %s hanya menerima Pet bertier %s!", payload.MachineType, machineRule.RequiredInputTier),
				ChanceUsed = 0,
			}
		end

		if not referencePet then
			referencePet = pet
		elseif pet.Name ~= referencePet.Name then
			return {
				Success = false,
				CraftSucceeded = false,
				Message = "Semua Pet yang digabungkan harus memiliki nama yang sama!",
				ChanceUsed = 0,
			}
		end

		if pet.IsShiny then
			shinyCount += 1
		end
		if (pet.Level or 1) > highestLevel then
			highestLevel = pet.Level or 1
		end

		table.insert(selectedPets, pet)
	end

	if not referencePet then
		return {
			Success = false,
			CraftSucceeded = false,
			Message = "Gagal membaca referensi Pet.",
			ChanceUsed = 0,
		}
	end

	local successChance = math.clamp(count * 20, 20, 100)
	local roll = math.random(1, 100)
	local isCraftSuccess = (roll <= successChance)

	for _, pet in ipairs(selectedPets) do
		inventory[pet.UUID] = nil
	end

	if isCraftSuccess then
		local shinyChance = (shinyCount / count) * 100
		local resultIsShiny = (shinyCount > 0) and (math.random(1, 100) <= shinyChance)

		local newPet: PetInstance = {
			UUID = HttpService:GenerateGUID(false),
			Name = referencePet.Name,
			EggId = referencePet.EggId or "Crafted",
			Rarity = referencePet.Rarity or "Common",
			BaseMultiplier = referencePet.BaseMultiplier or referencePet.Stat or 1,
			Mutation = machineRule.OutputTier,
			IsShiny = resultIsShiny,
			Level = highestLevel,
			Locked = false,
			Equipped = false,
		}

		inventory[newPet.UUID] = newPet
		local masteryGain = 15 * count

		local finalMult = CalculateFinalPetMultiplier(newPet.BaseMultiplier, newPet.Mutation, newPet.IsShiny, newPet.Level)

		return {
			Success = true,
			CraftSucceeded = true,
			Message = string.format(
				"BERHASIL! Kamu mendapatkan %s%s %s (x%s Clicks)!",
				if newPet.IsShiny then "Shiny " else "",
				newPet.Mutation,
				newPet.Name,
				tostring(math.floor(finalMult * 100) / 100)
			),
			ChanceUsed = successChance,
			NewPet = newPet,
			FragmentsAwarded = 0,
			MasteryXPAwarded = masteryGain,
		}
	else
		local awardedFragments = count * 2
		mainProfile.Fragments = (mainProfile.Fragments or 0) + awardedFragments

		return {
			Success = true,
			CraftSucceeded = false,
			Message = string.format(
				"CRAFTING GAGAL (%d%% Peluang)! Pet hancur menjadi +%d Fragments.",
				successChance,
				awardedFragments
			),
			ChanceUsed = successChance,
			NewPet = nil,
			FragmentsAwarded = awardedFragments,
			MasteryXPAwarded = 5,
		}
	end
end

CraftPetRemote.OnServerInvoke = ProcessPetCraft

print("[PetCraftingMachineSystem] Server system aktif")

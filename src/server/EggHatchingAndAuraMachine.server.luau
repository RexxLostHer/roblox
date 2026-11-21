--!strict
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("RebirthChampionsConfig"))

export type AuraDefinition = {
	Name: string,
	OneInOdds: number,
	ClicksBonus: number,
	LuckBonus: number,
	HatchSpeedBonus: number,
	Color: Color3,
}

local AURA_DATABASE: { AuraDefinition } = {
	{ Name = "Basic Aura", OneInOdds = 1, ClicksBonus = 0.03, LuckBonus = 0, HatchSpeedBonus = 0, Color = Color3.fromRGB(200, 200, 200) },
	{ Name = "Bubble Aura", OneInOdds = 3, ClicksBonus = 0.05, LuckBonus = 0, HatchSpeedBonus = 0, Color = Color3.fromRGB(125, 211, 252) },
	{ Name = "Fire Aura", OneInOdds = 5, ClicksBonus = 0.10, LuckBonus = 0, HatchSpeedBonus = 0, Color = Color3.fromRGB(249, 115, 22) },
	{ Name = "Toxic Aura", OneInOdds = 10, ClicksBonus = 0.15, LuckBonus = 0, HatchSpeedBonus = 0, Color = Color3.fromRGB(74, 222, 128) },
	{ Name = "Wind Aura", OneInOdds = 20, ClicksBonus = 0.20, LuckBonus = 0, HatchSpeedBonus = 0, Color = Color3.fromRGB(226, 232, 240) },
	{ Name = "Electro Aura", OneInOdds = 50, ClicksBonus = 0.25, LuckBonus = 0, HatchSpeedBonus = 0, Color = Color3.fromRGB(250, 204, 21) },
	{ Name = "Heart Aura", OneInOdds = 100, ClicksBonus = 0.30, LuckBonus = 0, HatchSpeedBonus = 0, Color = Color3.fromRGB(244, 114, 182) },
	{ Name = "Heal Aura", OneInOdds = 250, ClicksBonus = 0.35, LuckBonus = 0, HatchSpeedBonus = 0, Color = Color3.fromRGB(52, 211, 153) },
	{ Name = "Smoke Aura", OneInOdds = 400, ClicksBonus = 0.40, LuckBonus = 0, HatchSpeedBonus = 0, Color = Color3.fromRGB(148, 163, 184) },
	{ Name = "Shield Aura", OneInOdds = 500, ClicksBonus = 0.45, LuckBonus = 0, HatchSpeedBonus = 0, Color = Color3.fromRGB(59, 130, 246) },
	{ Name = "Water Aura", OneInOdds = 1000, ClicksBonus = 0.50, LuckBonus = 0.02, HatchSpeedBonus = 0, Color = Color3.fromRGB(14, 165, 233) },
	{ Name = "Shadow Aura", OneInOdds = 2500, ClicksBonus = 0.55, LuckBonus = 0.03, HatchSpeedBonus = 0, Color = Color3.fromRGB(71, 85, 105) },
	{ Name = "Emerald Aura", OneInOdds = 5000, ClicksBonus = 0.60, LuckBonus = 0.04, HatchSpeedBonus = 0, Color = Color3.fromRGB(16, 185, 129) },
	{ Name = "Dark Aura", OneInOdds = 10000, ClicksBonus = 0.75, LuckBonus = 0.05, HatchSpeedBonus = 0, Color = Color3.fromRGB(88, 28, 135) },
	{ Name = "Flame Aura", OneInOdds = 20000, ClicksBonus = 0.85, LuckBonus = 0.08, HatchSpeedBonus = 0, Color = Color3.fromRGB(239, 68, 68) },
	{ Name = "Mystic Aura", OneInOdds = 25000, ClicksBonus = 1.00, LuckBonus = 0.15, HatchSpeedBonus = 0, Color = Color3.fromRGB(168, 85, 247) },
	{ Name = "Time Aura", OneInOdds = 50000, ClicksBonus = 1.25, LuckBonus = 0.20, HatchSpeedBonus = 0, Color = Color3.fromRGB(20, 184, 166) },
	{ Name = "Divine Aura", OneInOdds = 100000, ClicksBonus = 1.50, LuckBonus = 0.25, HatchSpeedBonus = 0, Color = Color3.fromRGB(253, 224, 71) },
	{ Name = "Magic Aura", OneInOdds = 200000, ClicksBonus = 1.75, LuckBonus = 0.30, HatchSpeedBonus = 0.03, Color = Color3.fromRGB(217, 70, 239) },
	{ Name = "Tornado Aura", OneInOdds = 500000, ClicksBonus = 1.85, LuckBonus = 0.35, HatchSpeedBonus = 0.05, Color = Color3.fromRGB(148, 163, 184) },
	{ Name = "Blizzard Aura", OneInOdds = 1e6, ClicksBonus = 2.00, LuckBonus = 0.45, HatchSpeedBonus = 0.08, Color = Color3.fromRGB(56, 189, 248) },
	{ Name = "Obsidian Aura", OneInOdds = 2.5e6, ClicksBonus = 2.20, LuckBonus = 0.50, HatchSpeedBonus = 0.10, Color = Color3.fromRGB(49, 46, 129) },
	{ Name = "Celestial Aura", OneInOdds = 5e6, ClicksBonus = 2.35, LuckBonus = 0.55, HatchSpeedBonus = 0.125, Color = Color3.fromRGB(129, 140, 248) },
	{ Name = "Void Aura", OneInOdds = 10e6, ClicksBonus = 2.50, LuckBonus = 0.65, HatchSpeedBonus = 0.15, Color = Color3.fromRGB(109, 40, 217) },
	{ Name = "Inferno Aura", OneInOdds = 25e6, ClicksBonus = 2.75, LuckBonus = 0.75, HatchSpeedBonus = 0.20, Color = Color3.fromRGB(220, 38, 38) },
	{ Name = "Radiant Aura", OneInOdds = 100e6, ClicksBonus = 3.00, LuckBonus = 1.00, HatchSpeedBonus = 0.25, Color = Color3.fromRGB(254, 240, 138) },
	{ Name = "Black Hole Aura", OneInOdds = 250e6, ClicksBonus = 3.30, LuckBonus = 1.25, HatchSpeedBonus = 0.32, Color = Color3.fromRGB(30, 27, 75) },
	{ Name = "Glitch Aura", OneInOdds = 500e6, ClicksBonus = 3.50, LuckBonus = 1.40, HatchSpeedBonus = 0.35, Color = Color3.fromRGB(45, 212, 191) },
	{ Name = "Rainbow Aura", OneInOdds = 1e9, ClicksBonus = 3.75, LuckBonus = 1.75, HatchSpeedBonus = 0.40, Color = Color3.fromRGB(244, 63, 94) },
	{ Name = "Sun Aura", OneInOdds = 2e9, ClicksBonus = 4.00, LuckBonus = 1.90, HatchSpeedBonus = 0.45, Color = Color3.fromRGB(251, 146, 60) },
	{ Name = "Nebula Aura", OneInOdds = 2.5e9, ClicksBonus = 4.25, LuckBonus = 2.10, HatchSpeedBonus = 0.50, Color = Color3.fromRGB(192, 132, 252) },
	{ Name = "Solar System Aura", OneInOdds = 5e9, ClicksBonus = 4.50, LuckBonus = 2.25, HatchSpeedBonus = 0.55, Color = Color3.fromRGB(56, 189, 248) },
	{ Name = "Chaos Aura", OneInOdds = 10e9, ClicksBonus = 4.75, LuckBonus = 2.40, HatchSpeedBonus = 0.60, Color = Color3.fromRGB(153, 27, 27) },
	{ Name = "Plasma Aura", OneInOdds = 20e9, ClicksBonus = 5.00, LuckBonus = 2.65, HatchSpeedBonus = 0.65, Color = Color3.fromRGB(232, 121, 249) },
	{ Name = "Archangel Aura", OneInOdds = 50e9, ClicksBonus = 5.50, LuckBonus = 2.90, HatchSpeedBonus = 0.70, Color = Color3.fromRGB(254, 249, 195) },
	{ Name = "Dark Matter Aura", OneInOdds = 100e9, ClicksBonus = 6.00, LuckBonus = 3.25, HatchSpeedBonus = 0.75, Color = Color3.fromRGB(88, 28, 135) },
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

local HatchEggRemote: RemoteFunction = GetOrCreateRemote("HatchEggFunction", "RemoteFunction")
local RollAuraRemote: RemoteFunction = GetOrCreateRemote("RollAuraFunction", "RemoteFunction")
local GlobalChatAnnounce: RemoteEvent = GetOrCreateRemote("GlobalHatchAnnouncement", "RemoteEvent")

_G.GetPlayerAuraBonuses = function(auraName: string): AuraDefinition
	for _, aura in ipairs(AURA_DATABASE) do
		if aura.Name == auraName then
			return aura
		end
	end
	return { Name = "None", OneInOdds = 1, ClicksBonus = 0, LuckBonus = 0, HatchSpeedBonus = 0, Color = Color3.new(1, 1, 1) }
end

local function ApplyAuraVFXToCharacter(player: Player, auraDef: AuraDefinition)
	local char = player.Character
	local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not root then return end

	local existing = root:FindFirstChild("EquippedAuraEmitter")
	if existing then existing:Destroy() end

	if auraDef.Name == "None" then return end

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "EquippedAuraEmitter"
	emitter.Color = ColorSequence.new(auraDef.Color)
	emitter.LightEmission = 0.85
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 1.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Rate = math.clamp(15 + math.floor(math.log10(auraDef.OneInOdds + 1) * 8), 15, 95)
	emitter.Lifetime = NumberRange.new(1.0, 1.6)
	emitter.Speed = NumberRange.new(2, 5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = root
end

local function GetTotalEggLuckMultiplier(profile: any): number
	local luck = 1.0
	if profile.Upgrades and profile.Upgrades.LuckMultiplier then
		luck += profile.Upgrades.LuckMultiplier * 0.25
	end
	if profile.OwnedGamepasses then
		if profile.OwnedGamepasses["MegaLucky"] then luck += 0.50 end
		if profile.OwnedGamepasses["UltraLucky"] then luck += 2.00 end
	end
	local auraBonus = _G.GetPlayerAuraBonuses(profile.EquippedAura or "Basic").LuckBonus
	luck += auraBonus

	if profile.ActivePotions and (profile.ActivePotions["LuckPotion"] or 0) > os.time() then
		luck += 0.50
	end

	-- Bonus Buku Luck Eksklusif (Robux)
	if profile.PetInventory then
		for _, pet in pairs(profile.PetInventory) do
			if pet.Equipped and pet.ExclusiveBooks and pet.ExclusiveBooks["LuckBook"] then
				luck += 1.00
			end
		end
	end

	return luck
end

local function RollDirectHatchMutation(profile: any): ("Normal" | "Golden" | "Toxic" | "Galaxy", boolean)
	local now = os.time()
	local goldenChance = ((profile.Upgrades and profile.Upgrades.GoldenPetLuck) or 0) * 0.25
	local toxicChance = ((profile.Upgrades and profile.Upgrades.ToxicPetLuck) or 0) * 0.20
	local galaxyChance = 0.0
	local shinyChance = 0.5

	if profile.OwnedGamepasses then
		if profile.OwnedGamepasses["MagicEggs"] then
			goldenChance += 5.0
			toxicChance += 1.0
		end
		if profile.OwnedGamepasses["ShinyHunter"] then
			shinyChance *= 4.0
		end
	end

	if profile.ActivePotions then
		if (profile.ActivePotions["GoldenPotion"] or 0) > now then goldenChance += 5.0 end
		if (profile.ActivePotions["ToxicPotion"] or 0) > now then toxicChance += 0.5 end
		if (profile.ActivePotions["GalaxyPotion"] or 0) > now then galaxyChance += 0.2 end
		if (profile.ActivePotions["ShinyPotion"] or 0) > now then shinyChance += 0.5 end
	end

	local mutRoll = math.random() * 100
	local chosenMutation: "Normal" | "Golden" | "Toxic" | "Galaxy" = "Normal"
	if mutRoll <= galaxyChance then
		chosenMutation = "Galaxy"
	elseif mutRoll <= (galaxyChance + toxicChance) then
		chosenMutation = "Toxic"
	elseif mutRoll <= (galaxyChance + toxicChance + goldenChance) then
		chosenMutation = "Golden"
	end

	local isShiny = (math.random() * 100) <= shinyChance
	return chosenMutation, isShiny
end

local function RollSinglePetFromEgg(eggData: any, totalLuck: number, ownsSecretsHunter: boolean): any
	local weightedPool = {}
	local totalWeight = 0

	for _, pet in ipairs(eggData.Pets) do
		local weight = pet.Weight or pet.Chance or 10
		local rarity = pet.Rarity or "Common"
		if rarity == "Rare" or rarity == "Epic" or rarity == "Legendary" then
			weight *= totalLuck
		elseif rarity == "Secret" or rarity == "Mysterious" or rarity == "Supreme" then
			local secretMult = if ownsSecretsHunter then 2.0 else 1.0
			weight *= (totalLuck * secretMult)
		end
		totalWeight += weight
		table.insert(weightedPool, { Entry = pet, Weight = weight })
	end

	local roll = math.random() * math.max(totalWeight, 1)
	local cumulative = 0
	for _, item in ipairs(weightedPool) do
		cumulative += item.Weight
		if roll <= cumulative then
			return item.Entry
		end
	end

	return eggData.Pets[1]
end

HatchEggRemote.OnServerInvoke = function(player: Player, eggId: string, requestedHatchCount: number, autoDeleteRarities: { [string]: boolean }?)
	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil
	if not profile then
		return { Success = false, Message = "Profil belum dimuat." }
	end

	local eggData = Config.Eggs[eggId]
	if not eggData then
		return { Success = false, Message = "Data Egg tidak ditemukan." }
	end

	local maxAllowedHatch = if profile.OwnedGamepasses and profile.OwnedGamepasses["ExtraEggs"] then 4 else 3
	local hatchCount = math.clamp(math.floor(requestedHatchCount or 1), 1, maxAllowedHatch)

	local totalCost = eggData.Cost * hatchCount
	if profile.Clicks < totalCost then
		return {
			Success = false,
			Message = string.format("Clicks tidak cukup! Butuh %s Clicks untuk membuka %dx %s.", tostring(totalCost), hatchCount, eggId),
		}
	end

	profile.Clicks -= totalCost

	local totalLuck = GetTotalEggLuckMultiplier(profile)
	local ownsSecretsHunter = profile.OwnedGamepasses and profile.OwnedGamepasses["SecretsHunter"] == true
	local hatchedResults = {}

	for _ = 1, hatchCount do
		local chosenPet = RollSinglePetFromEgg(eggData, totalLuck, ownsSecretsHunter)
		local mutation, isShiny = RollDirectHatchMutation(profile)

		local rarity = chosenPet.Rarity or "Common"
		local isAutoDeleted = if autoDeleteRarities and autoDeleteRarities[rarity] then true else false
		if rarity == "Secret" or rarity == "Mysterious" or rarity == "Supreme" then
			isAutoDeleted = false
		end

		local petRecord = {
			UUID = HttpService:GenerateGUID(false),
			Name = chosenPet.Name,
			EggId = eggId,
			Rarity = rarity,
			BaseMultiplier = chosenPet.Stat or chosenPet.BaseMultiplier or 1,
			Mutation = mutation,
			IsShiny = isShiny,
			Level = 1,
			Locked = false,
			Equipped = false,
			AutoDeleted = isAutoDeleted,
		}

		profile.EggsHatched = (profile.EggsHatched or 0) + 1
		profile.QuestsProgress = profile.QuestsProgress or {}
		profile.QuestsProgress.Eggs = (profile.QuestsProgress.Eggs or 0) + 1
		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Eggs") then
			ls.Eggs.Value = tostring(profile.EggsHatched)
		end

		if not isAutoDeleted then
			profile.PetInventory = profile.PetInventory or {}
			profile.PetInventory[petRecord.UUID] = petRecord

			-- Catat ke Pet Index (Format: "Spesies_Mutasi" atau "Spesies_Shiny")
			profile.PetIndex = profile.PetIndex or {}
			local indexKey = chosenPet.Name .. "_" .. mutation .. (if isShiny then "_Shiny" else "")
			profile.PetIndex[indexKey] = true

			local rem = ReplicatedStorage:FindFirstChild("Remotes")
			local syncIndex = if rem then rem:FindFirstChild("SyncPetIndexEvent") :: RemoteEvent? else nil
			if syncIndex then syncIndex:FireClient(player, profile.PetIndex) end
		end

		if rarity == "Secret" or rarity == "Mysterious" or rarity == "Supreme" then
			GlobalChatAnnounce:FireAllClients(
				string.format(
					"[SERVER HATCH] %s baru saja menetas %s%s %s (%s) dari %s!",
					player.Name,
					if isShiny then "SHINY " else "",
					mutation:upper(),
					chosenPet.Name,
					rarity,
					eggId
				)
			)
		end

		table.insert(hatchedResults, petRecord)
	end

	return {
		Success = true,
		EggName = eggId,
		HatchedPets = hatchedResults,
	}
end

RollAuraRemote.OnServerInvoke = function(player: Player)
	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil
	if not profile then
		return { Success = false, Message = "Profil belum dimuat." }
	end

	if (profile.AuraDiceCount or 0) < 1 then
		return { Success = false, Message = "Aura Dice habis! Kamu mendapatkan +1 Dadu gratis setiap 60 detik." }
	end

	profile.AuraDiceCount -= 1

	local auraLuck = 1.0 + (((profile.Upgrades and profile.Upgrades.AuraLuck) or 0) * 0.35)
	if profile.ActivePotions and (profile.ActivePotions["RNGLuckPotion"] or 0) > os.time() then
		auraLuck += 0.50
	end

	local rolledAura: AuraDefinition = AURA_DATABASE[1]
	for i = #AURA_DATABASE, 1, -1 do
		local candidate = AURA_DATABASE[i]
		local adjustedProbability = math.min((1.0 / candidate.OneInOdds) * auraLuck, 1.0)
		if math.random() <= adjustedProbability then
			rolledAura = candidate
			break
		end
	end

	profile.OwnedAuras = profile.OwnedAuras or {}
	profile.OwnedAuras[rolledAura.Name] = true
	profile.EquippedAura = rolledAura.Name
	ApplyAuraVFXToCharacter(player, rolledAura)

	if rolledAura.OneInOdds >= 1e6 then
		GlobalChatAnnounce:FireAllClients(
			string.format("[AURA ROLL] %s berhasil mendapatkan %s (1 in %s)!", player.Name, rolledAura.Name, tostring(rolledAura.OneInOdds))
		)
	end

	return {
		Success = true,
		RolledAura = rolledAura,
		RemainingDices = profile.AuraDiceCount,
		Message = string.format(
			"Kamu mendapatkan %s (1/%s) | Clicks +%d%%, Luck +%d%%, Hatch Speed +%d%%!",
			rolledAura.Name,
			tostring(rolledAura.OneInOdds),
			math.floor(rolledAura.ClicksBonus * 100),
			math.floor(rolledAura.LuckBonus * 100),
			math.floor(rolledAura.HatchSpeedBonus * 100)
		),
	}
end

print("[EggHatchingAndAuraMachine] Server system aktif")

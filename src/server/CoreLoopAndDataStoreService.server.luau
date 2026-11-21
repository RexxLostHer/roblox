--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage:WaitForChild("RebirthChampionsConfig"))

export type PlayerProfileData = {
	Clicks: number,
	Rebirths: number,
	Gems: number,
	TradeTokens: number,
	Fragments: number,
	CurrentWorld: string,
	UnlockedWorlds: { [string]: boolean },
	EquippedTapSkin: string,
	OwnedTapSkins: { [string]: boolean },
	EquippedAura: string,
	OwnedAuras: { [string]: boolean },
	AuraDiceCount: number,
	Upgrades: {
		FreeAutoclicker: number,
		RebirthButtons: number,
		ClickMultiplier: number,
		LuckMultiplier: number,
		PetEquipSlots: number,
		GoldenPetLuck: number,
		ToxicPetLuck: number,
		AuraLuck: number,
		HatchSpeed: number,
	},
	OwnedGamepasses: { [string]: boolean },
	ActivePotions: { [string]: number },
	PetInventory: { [string]: any },
	PetIndex: { [string]: boolean },
	EggsHatched: number,
	StreakDay: number,
	LastLoginDate: number,
	QuestsProgress: { [string]: number },
	ClaimedQuests: { [string]: boolean },
	PlaytimeMinutes: number,
	ClaimedGifts: { [number]: boolean },
}

local REBIRTH_BUTTON_TIERS = {
	[0] = { 1, 5, 10 },
	[1] = { 25 },
	[2] = { 50 },
	[3] = { 100 },
	[4] = { 200 },
	[5] = { 500 },
	[6] = { 1000 },
	[7] = { 2500 },
	[8] = { 5000 },
	[9] = { 10000 },
	[10] = { 15000 },
	[11] = { 25000 },
	[12] = { 50000 },
	[13] = { 100000 },
	[14] = { 200000 },
	[15] = { 500000 },
	[16] = { 1e6 },
	[17] = { 2.5e6 },
	[18] = { 5e6 },
	[19] = { 10e6 },
	[20] = { 25e6 },
	[21] = { 50e6 },
	[22] = { 100e6 },
	[23] = { 250e6 },
	[24] = { 500e6 },
	[25] = { 1e9 },
	[26] = { 2.5e9 },
	[27] = { 5e9 },
	[28] = { 10e9 },
	[29] = { 25e9 },
	[30] = { 50e9 },
	[31] = { 150e9 },
	[32] = { 500e9 },
	[33] = { 1e12 },
	[34] = { 5e12 },
	[35] = { 25e12 },
	[36] = { 100e12 },
	[37] = { 250e12 },
	[38] = { 500e12 },
	[39] = { 1e15 },
	[40] = { 2.5e15 },
	[41] = { 10e15 },
	[42] = { 25e15 },
	[43] = { 100e15 },
	[44] = { 250e15 },
	[45] = { 500e15 },
	[46] = { 1e18 },
	[47] = { 5e18 },
	[48] = { 25e18 },
	[49] = { 100e18 },
	[50] = { 250e18 },
	[51] = { 1e21 },
	[52] = { 5e21 },
	[53] = { 25e21 },
	[54] = { 100e24 },
}

local PlayerDataStore = DataStoreService:GetDataStore("RebirthChampions_Production_v1")

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

local ClickRemote: RemoteEvent = GetOrCreateRemote("ClickTapEvent", "RemoteEvent")
local RebirthRemote: RemoteFunction = GetOrCreateRemote("PerformRebirthFunction", "RemoteFunction")
local UpgradeRemote: RemoteFunction = GetOrCreateRemote("BuyUpgradeFunction", "RemoteFunction")
local TapSkinRemote: RemoteFunction = GetOrCreateRemote("BuyOrEquipTapSkinFunction", "RemoteFunction")
local TeleportWorldRemote: RemoteFunction = GetOrCreateRemote("TeleportWorldFunction", "RemoteFunction")
local SyncPopupRemote: RemoteEvent = GetOrCreateRemote("ClickPopupClientEvent", "RemoteEvent")
local EquipPetRemote: RemoteFunction = GetOrCreateRemote("EquipPetFunction", "RemoteFunction")
local EquipBestRemote: RemoteFunction = GetOrCreateRemote("EquipBestFunction", "RemoteFunction")
local DeletePetRemote: RemoteFunction = GetOrCreateRemote("DeletePetFunction", "RemoteFunction")
local ToggleLockPetRemote: RemoteFunction = GetOrCreateRemote("ToggleLockPetFunction", "RemoteFunction")
local BuyPotionRemote: RemoteFunction = GetOrCreateRemote("BuyPotionFunction", "RemoteFunction")
local SyncEquippedPetsEvent: RemoteEvent = GetOrCreateRemote("SyncEquippedPetsEvent", "RemoteEvent")
local SyncDiceTimerEvent: RemoteEvent = GetOrCreateRemote("SyncDiceTimerEvent", "RemoteEvent")
local GetInventoryRemote: RemoteFunction = GetOrCreateRemote("GetInventoryFunction", "RemoteFunction")
local SyncInventoryEvent: RemoteEvent = GetOrCreateRemote("SyncInventoryEvent", "RemoteEvent")
local GetPetIndexRemote: RemoteFunction = GetOrCreateRemote("GetPetIndexFunction", "RemoteFunction")
local SyncPetIndexEvent: RemoteEvent = GetOrCreateRemote("SyncPetIndexEvent", "RemoteEvent")
local FusePetXPRemote: RemoteFunction = GetOrCreateRemote("FusePetXPFunction", "RemoteFunction")
local SyncActivePotionsEvent: RemoteEvent = GetOrCreateRemote("SyncActivePotionsEvent", "RemoteEvent")
local MultiDeletePetsRemote: RemoteFunction = GetOrCreateRemote("MultiDeletePetsFunction", "RemoteFunction")
local RollEnchantRemote: RemoteFunction = GetOrCreateRemote("RollEnchantFunction", "RemoteFunction")
local ApplyExclusiveBookRemote: RemoteFunction = GetOrCreateRemote("ApplyExclusiveBookFunction", "RemoteFunction")
local ClaimStreakRemote: RemoteFunction = GetOrCreateRemote("ClaimStreakFunction", "RemoteFunction")
local ClaimQuestRemote: RemoteFunction = GetOrCreateRemote("ClaimQuestFunction", "RemoteFunction")
local ClaimPlaytimeGiftRemote: RemoteFunction = GetOrCreateRemote("ClaimPlaytimeGiftFunction", "RemoteFunction")
local SyncPlaytimeEvent: RemoteEvent = GetOrCreateRemote("SyncPlaytimeEvent", "RemoteEvent")
local HatchExclusiveEggRemote: RemoteFunction = GetOrCreateRemote("HatchExclusiveEggFunction", "RemoteFunction")

local ActiveProfiles: { [number]: PlayerProfileData } = {}
local ClickRateLimiter: { [number]: { WindowStart: number, Count: number } } = {}

local function CreateDefaultProfile(): PlayerProfileData
	return {
		Clicks = 0,
		Rebirths = 0,
		Gems = 0,
		TradeTokens = 0,
		Fragments = 0,
		CurrentWorld = "Spawn",
		UnlockedWorlds = { Spawn = true },
		EquippedTapSkin = "Default",
		OwnedTapSkins = { Default = true },
		EquippedAura = "None",
		OwnedAuras = {},
		AuraDiceCount = 5,
		Upgrades = {
			FreeAutoclicker = 0,
			RebirthButtons = 0,
			ClickMultiplier = 0,
			LuckMultiplier = 0,
			PetEquipSlots = 0,
			GoldenPetLuck = 0,
			ToxicPetLuck = 0,
			AuraLuck = 0,
			HatchSpeed = 0,
		},
		OwnedGamepasses = {},
		ActivePotions = {},
		PetInventory = {},
		PetIndex = {},
		EggsHatched = 0,
		StreakDay = 1,
		LastLoginDate = 0,
		QuestsProgress = { Clicks = 0, Rebirths = 0, Eggs = 0 },
		ClaimedQuests = {},
		PlaytimeMinutes = 0,
		ClaimedGifts = {},
	}
end

_G.GetPlayerProfile = function(player: Player): PlayerProfileData?
	return ActiveProfiles[player.UserId]
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "O", "N", "Dc" }
local function FormatNumber(n: number): string
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local index = math.clamp(math.floor(math.log10(n) / 3) + 1, 1, #SUFFIXES)
	local scaled = n / (10 ^ ((index - 1) * 3))
	return string.format("%.2f%s", scaled, SUFFIXES[index])
end

local function UpdateLeaderstats(player: Player)
	local profile = ActiveProfiles[player.UserId]
	if not profile then return end
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local clicksVal = ls:FindFirstChild("Clicks") :: StringValue?
	local rebirthsVal = ls:FindFirstChild("Rebirths") :: StringValue?
	local gemsVal = ls:FindFirstChild("Gems") :: StringValue?
	local rankVal = ls:FindFirstChild("Rank") :: StringValue?
	local eggsVal = ls:FindFirstChild("Eggs") :: StringValue?

	if clicksVal then clicksVal.Value = FormatNumber(profile.Clicks) end
	if rebirthsVal then rebirthsVal.Value = FormatNumber(profile.Rebirths) end
	if gemsVal then gemsVal.Value = FormatNumber(profile.Gems) end
	if eggsVal then eggsVal.Value = FormatNumber(profile.EggsHatched or 0) end

	if rankVal then
		local rankName = "Rookie"
		if profile.Rebirths >= 1e18 then
			rankName = "Paradox Sovereign"
		elseif profile.Rebirths >= 1e12 then
			rankName = "Cosmic Legend"
		elseif profile.Rebirths >= 1e9 then
			rankName = "Billionaire Champion"
		elseif profile.Rebirths >= 1e6 then
			rankName = "Rebirth Master"
		elseif profile.Rebirths >= 1000 then
			rankName = "Elite Rebirther"
		elseif profile.Rebirths >= 25 then
			rankName = "Rising Star"
		end
		rankVal.Value = rankName
	end
end

_G.UpdateLeaderstats = function(player: Player)
	UpdateLeaderstats(player)
end

local ENCHANT_TIER_SCALING = {
	[1] = 0.05,
	[2] = 0.10,
	[3] = 0.18,
	[4] = 0.28,
	[5] = 0.40,
	[6] = 0.55,
	[7] = 0.75,
}

local function GetEquippedPetsMultiplier(profile: PlayerProfileData): number
	local totalPetMult = 0
	for _, pet in pairs(profile.PetInventory) do
		if pet.Equipped then
			local base = pet.BaseMultiplier or pet.Stat or 1
			local mut = pet.Mutation or "Normal"
			local tierInfo = Config.MutationTiers and Config.MutationTiers.Tiers and Config.MutationTiers.Tiers[mut]
			local mult = 1.0
			if tierInfo then
				mult = if pet.IsShiny then (tierInfo.ShinyMultiplier or 1.5) else (tierInfo.Multiplier or 1.0)
			end

			-- Enchant Clicker Boost (Tier I - VII)
			local enchantBoost = 1.0
			if pet.Enchants and pet.Enchants["Clicker"] then
				local tier = pet.Enchants["Clicker"]
				enchantBoost += (ENCHANT_TIER_SCALING[tier] or 0.05)
			end

			totalPetMult += (base * mult * (pet.Level or 1) * enchantBoost)
		end
	end
	return if totalPetMult > 0 then totalPetMult else 1.0
end

local function GetCurrentWorldBoost(worldNameOrId: string): number
	for _, w in ipairs(Config.Worlds) do
		if tostring(w.Id) == tostring(worldNameOrId) or w.Name == worldNameOrId then
			return w.WorldBoost or 1.0
		end
	end
	return 1.0
end

local function GetTapSkinMultiplier(skinId: string): number
	local skin = Config.TapSkins[skinId]
	if skin and skin.Multiplier then
		return skin.Multiplier
	end
	return 1.0
end

local function GetFriendBoostMultiplier(player: Player): number
	local friendCount = 0
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local ok, isFriend = pcall(function()
				return player:IsFriendsWith(otherPlayer.UserId)
			end)
			if ok and isFriend then
				friendCount += 1
			end
		end
	end
	return 1.0 + (friendCount * 0.10)
end

local function CalculateClicksPerTap(player: Player, profile: PlayerProfileData): number
	local baseClick = 1.0
	local rebirthFactor = 1.0 + profile.Rebirths
	local petMult = GetEquippedPetsMultiplier(profile)
	local worldBoost = GetCurrentWorldBoost(profile.CurrentWorld)
	local tapSkinMult = GetTapSkinMultiplier(profile.EquippedTapSkin)
	local upgradeClickMult = 1.0 + (profile.Upgrades.ClickMultiplier * 0.50)

	local auraBonus = if _G.GetPlayerAuraBonuses then _G.GetPlayerAuraBonuses(profile.EquippedAura).ClicksBonus else 0
	local auraMult = 1.0 + auraBonus

	local now = os.time()
	local potionMult = 1.0
	if profile.ActivePotions["ClicksPotion"] and profile.ActivePotions["ClicksPotion"] > now then
		potionMult = 2.0
	end

	local friendMult = GetFriendBoostMultiplier(player)
	local vipMult = if profile.OwnedGamepasses["VIP"] or profile.OwnedGamepasses["VIPStatus"] then 1.5 else 1.0

	-- Bonus Pasif Pet Index: +1% per 5 pet unik ditemukan
	local indexCount = 0
	if profile.PetIndex then
		for _ in pairs(profile.PetIndex) do indexCount += 1 end
	end
	local indexBoost = 1.0 + (math.floor(indexCount / 5) * 0.05)

	local total = baseClick
		* rebirthFactor
		* petMult
		* worldBoost
		* tapSkinMult
		* upgradeClickMult
		* auraMult
		* potionMult
		* friendMult
		* vipMult
		* indexBoost

	return math.floor(total)
end

ClickRemote.OnServerEvent:Connect(function(player: Player)
	local userId = player.UserId
	local profile = ActiveProfiles[userId]
	if not profile then return end

	local now = os.clock()
	local limiter = ClickRateLimiter[userId]
	local maxClicksPerSecond = 15
	if profile.OwnedGamepasses["FastAutoClicker"] then
		maxClicksPerSecond = 30
	end

	if not limiter or (now - limiter.WindowStart) >= 1.0 then
		ClickRateLimiter[userId] = { WindowStart = now, Count = 1 }
	else
		if limiter.Count >= maxClicksPerSecond then return end
		limiter.Count += 1
	end

	local gainedClicks = CalculateClicksPerTap(player, profile)
	profile.Clicks += gainedClicks
	profile.QuestsProgress = profile.QuestsProgress or {}
	profile.QuestsProgress.Clicks = (profile.QuestsProgress.Clicks or 0) + 1
	UpdateLeaderstats(player)

	SyncPopupRemote:FireClient(player, gainedClicks, FormatNumber(gainedClicks))
end)

local function IsRebirthAmountUnlocked(rebirthButtonUpgradeLevel: number, requestedAmount: number): boolean
	for lvl = 0, math.min(rebirthButtonUpgradeLevel, 54) do
		local buttons = REBIRTH_BUTTON_TIERS[lvl]
		if buttons and table.find(buttons, requestedAmount) then
			return true
		end
	end
	return false
end

local function CalculateRebirthCost(currentRebirths: number, amountToRebirth: number): number
	local baseCost = 100
	local currentScaling = math.pow(1.0 + (currentRebirths * 0.15), 1.25)
	local batchScaling = math.pow(amountToRebirth, 1.32)
	return math.floor(baseCost * currentScaling * batchScaling)
end

RebirthRemote.OnServerInvoke = function(player: Player, requestedAmount: number)
	local profile = ActiveProfiles[player.UserId]
	if not profile or type(requestedAmount) ~= "number" or requestedAmount <= 0 then
		return { Success = false, Message = "Request Rebirth tidak valid." }
	end

	if not IsRebirthAmountUnlocked(profile.Upgrades.RebirthButtons, requestedAmount) then
		return {
			Success = false,
			Message = "Tombol Rebirth ini belum dibuka! Beli upgrade Rebirth Buttons di gedung Upgrades.",
		}
	end

	local requiredClicks = CalculateRebirthCost(profile.Rebirths, requestedAmount)
	if profile.Clicks < requiredClicks then
		return {
			Success = false,
			Message = string.format("Clicks belum cukup! Butuh %s Clicks.", FormatNumber(requiredClicks)),
		}
	end

	profile.Clicks = 0
	local rebirthMult = if profile.OwnedGamepasses["x2Rebirths"] or profile.OwnedGamepasses["AutoRebirth"] then 2 else 1
	local totalRebirthsGained = requestedAmount * rebirthMult
	profile.Rebirths += totalRebirthsGained

	local baseGems = requestedAmount * 10
	local vipGemMult = if profile.OwnedGamepasses["VIP"] or profile.OwnedGamepasses["VIPStatus"] then 1.5 else 1.0
	local potionGemMult = if (profile.ActivePotions["GemsPotion"] or 0) > os.time() then 2.0 else 1.0
	local totalGemsGained = math.floor(baseGems * vipGemMult * potionGemMult)
	profile.Gems += totalGemsGained

	profile.QuestsProgress = profile.QuestsProgress or {}
	profile.QuestsProgress.Rebirths = (profile.QuestsProgress.Rebirths or 0) + requestedAmount

	UpdateLeaderstats(player)

	return {
		Success = true,
		Message = string.format(
			"REBIRTH BERHASIL! +%s Rebirths & +%s Gems!",
			FormatNumber(totalRebirthsGained),
			FormatNumber(totalGemsGained)
		),
		NewRebirths = profile.Rebirths,
		NewGems = profile.Gems,
	}
end

local UPGRADE_BASE_COSTS = {
	FreeAutoclicker = { Base = 25000, Scale = 1, MaxLevel = 1 },
	RebirthButtons = { Base = 30, Scale = 3.2, MaxLevel = 54 },
	ClickMultiplier = { Base = 500, Scale = 4.5, MaxLevel = 18 },
	LuckMultiplier = { Base = 1000, Scale = 5.0, MaxLevel = 11 },
	PetEquipSlots = { Base = 1000000, Scale = 100.0, MaxLevel = 3 },
	GoldenPetLuck = { Base = 3000, Scale = 8.5, MaxLevel = 4 },
	ToxicPetLuck = { Base = 125000, Scale = 7.5, MaxLevel = 4 },
	AuraLuck = { Base = 350000, Scale = 6.0, MaxLevel = 5 },
	HatchSpeed = { Base = 10000000, Scale = 5.0, MaxLevel = 10 },
}

UpgradeRemote.OnServerInvoke = function(player: Player, upgradeKey: string)
	local profile = ActiveProfiles[player.UserId]
	local rule = UPGRADE_BASE_COSTS[upgradeKey]
	if not profile or not rule then
		return { Success = false, Message = "Upgrade tidak ditemukan." }
	end

	local currentLevel = (profile.Upgrades :: any)[upgradeKey] or 0
	if currentLevel >= rule.MaxLevel then
		return { Success = false, Message = "Upgrade ini sudah mencapai Level Maksimal!" }
	end

	local cost = math.floor(rule.Base * math.pow(rule.Scale, currentLevel))
	if profile.Gems < cost then
		return { Success = false, Message = string.format("Gems tidak cukup! Butuh %s Gems.", FormatNumber(cost)) }
	end

	profile.Gems -= cost
	;(profile.Upgrades :: any)[upgradeKey] = currentLevel + 1
	UpdateLeaderstats(player)

	return {
		Success = true,
		NewLevel = currentLevel + 1,
		Message = string.format("Berhasil meningkatkan %s ke Level %d!", upgradeKey, currentLevel + 1),
	}
end

TapSkinRemote.OnServerInvoke = function(player: Player, skinId: string)
	local profile = ActiveProfiles[player.UserId]
	if not profile then return { Success = false, Message = "Profil belum siap." } end

	local skinData = Config.TapSkins[skinId]
	if not skinData then return { Success = false, Message = "Tap Skin tidak valid." } end

	if not profile.OwnedTapSkins[skinId] then
		local cost = skinData.Cost or skinData.GemsCost or 0
		if profile.Gems < cost then
			return { Success = false, Message = string.format("Butuh %s Gems untuk membeli %s!", FormatNumber(cost), skinId) }
		end
		profile.Gems -= cost
		profile.OwnedTapSkins[skinId] = true
	end

	profile.EquippedTapSkin = skinId
	UpdateLeaderstats(player)
	return {
		Success = true,
		Message = string.format("%s aktif (x%.1f Clicks)!", skinId, skinData.Multiplier or 1.0),
	}
end

TeleportWorldRemote.OnServerInvoke = function(player: Player, worldIdentifier: string)
	local profile = ActiveProfiles[player.UserId]
	if not profile then return { Success = false, Message = "Profil belum siap." } end

	local targetWorld = nil
	for _, w in ipairs(Config.Worlds) do
		if tostring(w.Id) == tostring(worldIdentifier) or w.Name == worldIdentifier then
			targetWorld = w
			break
		end
	end
	if not targetWorld then return { Success = false, Message = "Pulau tidak ditemukan." } end

	local reqRebirths = targetWorld.RebirthReq or targetWorld.RequiredRebirths or 0
	if profile.Rebirths < reqRebirths then
		return {
			Success = false,
			Message = string.format("Butuh %s Rebirths untuk membuka %s!", FormatNumber(reqRebirths), targetWorld.Name),
		}
	end

	profile.UnlockedWorlds[targetWorld.Name] = true
	profile.CurrentWorld = targetWorld.Name

	local worldsFolder = workspace:FindFirstChild("Worlds")
	if worldsFolder and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local islandFolder = worldsFolder:FindFirstChild(targetWorld.Name) or worldsFolder:FindFirstChild(tostring(targetWorld.Id))
		local teleportPad = if islandFolder then islandFolder:FindFirstChild("TeleportSpawn") :: BasePart? else nil
		if teleportPad then
			(player.Character.HumanoidRootPart :: BasePart).CFrame = teleportPad.CFrame + Vector3.new(0, 4, 0)
		end
	end

	return {
		Success = true,
		Message = string.format("Berpindah ke %s (World Boost x%s)!", targetWorld.Name, FormatNumber(targetWorld.WorldBoost)),
	}
end

local function GetMaxEquippedPets(profile: PlayerProfileData): number
	local baseSlots = 3
	local upgradeSlots = (profile.Upgrades and profile.Upgrades.PetEquipSlots) or 0
	local gpSlots = 0
	if profile.OwnedGamepasses["Plus2PetsEquipped"] then gpSlots += 2 end
	if profile.OwnedGamepasses["Plus3PetsEquipped"] then gpSlots += 3 end

	-- Extra slot dari Exclusive Slot Book
	local bookSlots = 0
	if profile.PetInventory then
		for _, pet in pairs(profile.PetInventory) do
			if pet.Equipped and pet.ExclusiveBooks and pet.ExclusiveBooks["SlotBook"] then
				bookSlots += 1
			end
		end
	end

	return baseSlots + upgradeSlots + gpSlots + bookSlots
end

local function BroadcastEquippedPets(player: Player)
	local profile = ActiveProfiles[player.UserId]
	if not profile then return end

	local list = {}
	for _, pet in pairs(profile.PetInventory) do
		if pet.Equipped then
			table.insert(list, {
				UUID = pet.UUID,
				Name = pet.Name,
				Mutation = pet.Mutation or "Normal",
				IsShiny = pet.IsShiny == true,
			})
		end
	end
	SyncEquippedPetsEvent:FireClient(player, list)
	SyncInventoryEvent:FireClient(player, profile.PetInventory)
end

GetInventoryRemote.OnServerInvoke = function(player: Player)
	local profile = ActiveProfiles[player.UserId]
	if profile and profile.PetInventory then
		return profile.PetInventory
	end
	return {}
end

GetPetIndexRemote.OnServerInvoke = function(player: Player)
	local profile = ActiveProfiles[player.UserId]
	if profile and profile.PetIndex then
		return profile.PetIndex
	end
	return {}
end

EquipPetRemote.OnServerInvoke = function(player: Player, petUUID: string)
	local profile = ActiveProfiles[player.UserId]
	if not profile or not profile.PetInventory then
		return { Success = false, Message = "Profil belum siap." }
	end

	local pet = profile.PetInventory[petUUID]
	if not pet then
		return { Success = false, Message = "Pet tidak ditemukan." }
	end

	if pet.Equipped then
		pet.Equipped = false
		BroadcastEquippedPets(player)
		return { Success = true, Equipped = false, Message = string.format("%s dicopot.", pet.Name) }
	else
		local currentEquipped = 0
		for _, p in pairs(profile.PetInventory) do
			if p.Equipped then currentEquipped += 1 end
		end
		local maxAllowed = GetMaxEquippedPets(profile)
		if currentEquipped >= maxAllowed then
			return { Success = false, Message = string.format("Slot penuh (%d/%d)! Lepas pet lain atau beli upgrade Pet Equip Slots.", currentEquipped, maxAllowed) }
		end

		pet.Equipped = true
		BroadcastEquippedPets(player)
		return { Success = true, Equipped = true, Message = string.format("%s berhasil dipasang!", pet.Name) }
	end
end

EquipBestRemote.OnServerInvoke = function(player: Player)
	local profile = ActiveProfiles[player.UserId]
	if not profile or not profile.PetInventory then
		return { Success = false, Message = "Profil belum siap." }
	end

	for _, p in pairs(profile.PetInventory) do
		p.Equipped = false
	end

	local petList = {}
	for _, p in pairs(profile.PetInventory) do
		local base = p.BaseMultiplier or p.Stat or 1
		local mut = p.Mutation or "Normal"
		local tierInfo = Config.MutationTiers and Config.MutationTiers.Tiers and Config.MutationTiers.Tiers[mut]
		local mult = 1.0
		if tierInfo then
			mult = if p.IsShiny then (tierInfo.ShinyMultiplier or 1.5) else (tierInfo.Multiplier or 1.0)
		end
		local finalVal = base * mult * (p.Level or 1)
		table.insert(petList, { Pet = p, Value = finalVal })
	end

	table.sort(petList, function(a, b)
		return a.Value > b.Value
	end)

	local maxSlots = GetMaxEquippedPets(profile)
	local equippedCount = 0
	for i = 1, math.min(#petList, maxSlots) do
		petList[i].Pet.Equipped = true
		equippedCount += 1
	end

	BroadcastEquippedPets(player)
	return { Success = true, EquippedCount = equippedCount, Message = string.format("Equip Best berhasil! %d Pet terkuat dipasang.", equippedCount) }
end

DeletePetRemote.OnServerInvoke = function(player: Player, petUUID: string)
	local profile = ActiveProfiles[player.UserId]
	if not profile or not profile.PetInventory then
		return { Success = false, Message = "Profil belum siap." }
	end

	local pet = profile.PetInventory[petUUID]
	if not pet then return { Success = false, Message = "Pet tidak ditemukan." } end
	if pet.Locked then return { Success = false, Message = "Pet terkunci! Buka kunci terlebih dahulu." } end
	if pet.Equipped then pet.Equipped = false end

	profile.PetInventory[petUUID] = nil
	BroadcastEquippedPets(player)
	return { Success = true, Message = "Pet berhasil dihapus." }
end

MultiDeletePetsRemote.OnServerInvoke = function(player: Player, petUUIDs: { string })
	local profile = ActiveProfiles[player.UserId]
	if not profile or not profile.PetInventory then
		return { Success = false, Message = "Profil belum siap." }
	end

	if type(petUUIDs) ~= "table" or #petUUIDs == 0 then
		return { Success = false, Message = "Pilih pet yang ingin dihapus." }
	end

	local deletedCount = 0
	for _, uuid in ipairs(petUUIDs) do
		local pet = profile.PetInventory[uuid]
		if pet and not pet.Locked and not pet.Equipped then
			profile.PetInventory[uuid] = nil
			deletedCount += 1
		end
	end

	BroadcastEquippedPets(player)
	return { Success = true, DeletedCount = deletedCount, Message = string.format("Berhasil menghapus %d pet.", deletedCount) }
end

ToggleLockPetRemote.OnServerInvoke = function(player: Player, petUUID: string)
	local profile = ActiveProfiles[player.UserId]
	if not profile or not profile.PetInventory then
		return { Success = false, Message = "Profil belum siap." }
	end

	local pet = profile.PetInventory[petUUID]
	if not pet then return { Success = false, Message = "Pet tidak ditemukan." } end

	pet.Locked = not pet.Locked
	return { Success = true, Locked = pet.Locked, Message = if pet.Locked then "Pet dikunci!" else "Kunci Pet dibuka!" }
end

FusePetXPRemote.OnServerInvoke = function(player: Player, targetUUID: string, sacrificedUUIDs: { string })
	local profile = ActiveProfiles[player.UserId]
	if not profile or not profile.PetInventory then
		return { Success = false, Message = "Profil belum siap." }
	end

	local targetPet = profile.PetInventory[targetUUID]
	if not targetPet then
		return { Success = false, Message = "Target Pet tidak ditemukan." }
	end

	if type(sacrificedUUIDs) ~= "table" or #sacrificedUUIDs == 0 then
		return { Success = false, Message = "Pilih pet yang ingin dikorbankan untuk XP." }
	end

	local totalXPGained = 0
	for _, sUUID in ipairs(sacrificedUUIDs) do
		if sUUID ~= targetUUID then
			local sPet = profile.PetInventory[sUUID]
			if sPet and not sPet.Locked and not sPet.Equipped then
				local base = sPet.BaseMultiplier or sPet.Stat or 1
				totalXPGained += math.floor(base * (sPet.Level or 1) * 10)
				profile.PetInventory[sUUID] = nil
			end
		end
	end

	if totalXPGained == 0 then
		return { Success = false, Message = "Tidak ada pet valid yang bisa dikorbankan (pastikan tidak terkunci & tidak terpasang)." }
	end

	targetPet.Level = (targetPet.Level or 1) + math.max(1, math.floor(totalXPGained / 100))
	if targetPet.Level > 100 then targetPet.Level = 100 end

	BroadcastEquippedPets(player)
	return {
		Success = true,
		NewLevel = targetPet.Level,
		Message = string.format("%s naik ke Level %d (+%d XP)!", targetPet.Name, targetPet.Level, totalXPGained),
	}
end

local ENCHANT_TYPES = { "Clicker", "Lucky", "Magnet", "Glitch" }
local ENCHANT_COST_GEMS = 25000

local function GetMaxEnchantSlots(profile: PlayerProfileData): number
	local baseSlots = 7
	local extra = 0
	if profile.OwnedGamepasses["ExtraEnchantSlot1"] then extra += 1 end
	if profile.OwnedGamepasses["ExtraEnchantSlot2"] then extra += 2 end
	return baseSlots + extra
end

RollEnchantRemote.OnServerInvoke = function(player: Player, petUUID: string)
	local profile = ActiveProfiles[player.UserId]
	if not profile or not profile.PetInventory then
		return { Success = false, Message = "Profil belum siap." }
	end

	local pet = profile.PetInventory[petUUID]
	if not pet then return { Success = false, Message = "Pet tidak ditemukan." } end

	pet.Enchants = pet.Enchants or {}

	local currentCount = 0
	for _ in pairs(pet.Enchants) do currentCount += 1 end
	local maxSlots = GetMaxEnchantSlots(profile)

	if currentCount >= maxSlots then
		return { Success = false, Message = string.format("Slot Enchant Pet ini sudah penuh (%d/%d)!", currentCount, maxSlots) }
	end

	if profile.Gems < ENCHANT_COST_GEMS then
		return { Success = false, Message = string.format("Gems tidak cukup! Butuh %s Gems per Enchant.", FormatNumber(ENCHANT_COST_GEMS)) }
	end

	profile.Gems -= ENCHANT_COST_GEMS

	-- Roll Enchant Type & Tier I s/d VII
	local chosenType = ENCHANT_TYPES[math.random(1, #ENCHANT_TYPES)]
	local roll = math.random(1, 100)
	local tier = 1
	if roll <= 2 then tier = 7
	elseif roll <= 6 then tier = 6
	elseif roll <= 14 then tier = 5
	elseif roll <= 26 then tier = 4
	elseif roll <= 45 then tier = 3
	elseif roll <= 70 then tier = 2
	end

	pet.Enchants[chosenType] = tier

	UpdateLeaderstats(player)
	BroadcastEquippedPets(player)
	return {
		Success = true,
		Enchant = chosenType,
		Tier = tier,
		Message = string.format("Enchant Berhasil! %s mendapatkan %s Tier %d (Slot %d/%d)!", pet.Name, chosenType, tier, currentCount + 1, maxSlots),
	}
end

ApplyExclusiveBookRemote.OnServerInvoke = function(player: Player, petUUID: string, bookType: "SlotBook" | "LuckBook" | "RainbowBook" | "ShinyBook")
	local profile = ActiveProfiles[player.UserId]
	if not profile or not profile.PetInventory then
		return { Success = false, Message = "Profil belum siap." }
	end

	local pet = profile.PetInventory[petUUID]
	if not pet then return { Success = false, Message = "Pet tidak ditemukan." } end

	pet.ExclusiveBooks = pet.ExclusiveBooks or {}

	if bookType == "SlotBook" then
		pet.ExclusiveBooks["SlotBook"] = true
		BroadcastEquippedPets(player)
		return { Success = true, Message = string.format("Buku Slot berhasil diterapkan pada %s! (+1 Extra Equip Slot aktif)", pet.Name) }
	elseif bookType == "LuckBook" then
		pet.ExclusiveBooks["LuckBook"] = true
		return { Success = true, Message = string.format("Buku Luck diterapkan pada %s! (+100%% Permanent Base Egg Luck)", pet.Name) }
	elseif bookType == "RainbowBook" then
		pet.Mutation = "Rainbow"
		BroadcastEquippedPets(player)
		return { Success = true, Message = string.format("Buku Rainbow berhasil mengubah %s langsung menjadi Tier RAINBOW (16x Stat)!", pet.Name) }
	elseif bookType == "ShinyBook" then
		pet.IsShiny = true
		BroadcastEquippedPets(player)
		return { Success = true, Message = string.format("Buku Shiny berhasil mengubah %s langsung menjadi SHINY (1.5x Multiplier)!", pet.Name) }
	end

	return { Success = false, Message = "Jenis buku tidak valid." }
end

-- SISTEM DAILY LOGIN STREAK, QUESTS, & PLAYTIME GIFTS
local STREAK_REWARDS = {
	[1] = { Type = "Gems", Amount = 5000, Label = "5,000 Gems" },
	[2] = { Type = "Clicks", Amount = 50000, Label = "50,000 Clicks" },
	[3] = { Type = "AuraDice", Amount = 10, Label = "10x Aura Dice" },
	[4] = { Type = "Potion", Key = "LuckMega", Label = "Mega Luck Potion" },
	[5] = { Type = "Gems", Amount = 100000, Label = "100,000 Gems" },
	[6] = { Type = "TradeTokens", Amount = 100, Label = "100 Trade Tokens" },
	[7] = { Type = "Pet", Name = "Streak Phoenix", BaseStat = 25000, Label = "EXCLUSIVE STREAK PHOENIX" },
}

ClaimStreakRemote.OnServerInvoke = function(player: Player)
	local profile = ActiveProfiles[player.UserId]
	if not profile then return { Success = false, Message = "Profil belum siap." } end

	local now = os.time()
	local lastLogin = profile.LastLoginDate or 0
	local dayPassed = math.floor((now - lastLogin) / 86400)

	if dayPassed < 1 and lastLogin > 0 then
		return { Success = false, Message = "Hadiah streak hari ini sudah diambil! Datang lagi besok." }
	end

	if dayPassed > 2 then
		profile.StreakDay = 1
	elseif dayPassed >= 1 then
		profile.StreakDay = (profile.StreakDay % 7) + 1
	end

	profile.LastLoginDate = now
	local reward = STREAK_REWARDS[profile.StreakDay]

	if reward.Type == "Gems" then
		profile.Gems += reward.Amount
	elseif reward.Type == "Clicks" then
		profile.Clicks += reward.Amount
	elseif reward.Type == "AuraDice" then
		profile.AuraDiceCount = (profile.AuraDiceCount or 0) + reward.Amount
	elseif reward.Type == "TradeTokens" then
		profile.TradeTokens = (profile.TradeTokens or 0) + reward.Amount
	elseif reward.Type == "Potion" then
		profile.ActivePotions[reward.Key] = (profile.ActivePotions[reward.Key] or now) + 600
	elseif reward.Type == "Pet" then
		local u = game:GetService("HttpService"):GenerateGUID(false)
		profile.PetInventory[u] = {
			UUID = u, Name = reward.Name, BaseMultiplier = reward.BaseStat, Mutation = "Normal", IsShiny = true, Level = 1, Locked = true, Equipped = false
		}
	end

	UpdateLeaderstats(player)
	return { Success = true, StreakDay = profile.StreakDay, Message = string.format("Hari ke-%d! Kamu mendapatkan %s!", profile.StreakDay, reward.Label) }
end

local DAILY_QUESTS = {
	Click1000 = { Target = 1000, Type = "Clicks", RewardGems = 10000, Title = "Tap 1.000 kali" },
	Rebirth5 = { Target = 5, Type = "Rebirths", RewardGems = 25000, Title = "Lakukan 5 Rebirth" },
	Hatch10 = { Target = 10, Type = "Eggs", RewardGems = 15000, Title = "Buka 10 Telur" },
}

ClaimQuestRemote.OnServerInvoke = function(player: Player, questKey: string)
	local profile = ActiveProfiles[player.UserId]
	if not profile then return { Success = false, Message = "Profil belum siap." } end

	local q = DAILY_QUESTS[questKey]
	if not q then return { Success = false, Message = "Misi tidak ditemukan." } end
	if profile.ClaimedQuests[questKey] then return { Success = false, Message = "Misi ini sudah diklaim!" } end

	local prog = profile.QuestsProgress[q.Type] or 0
	if prog < q.Target then
		return { Success = false, Message = string.format("Progress belum selesai (%d/%d)!", prog, q.Target) }
	end

	profile.ClaimedQuests[questKey] = true
	profile.Gems += q.RewardGems
	UpdateLeaderstats(player)
	return { Success = true, Message = string.format("Misi selesai! +%s Gems!", FormatNumber(q.RewardGems)) }
end

local PLAYTIME_INTERVALS = {
	[1] = { Min = 5, Gems = 5000 },
	[2] = { Min = 15, Gems = 15000 },
	[3] = { Min = 30, Gems = 35000 },
	[4] = { Min = 60, Gems = 80000 },
}

ClaimPlaytimeGiftRemote.OnServerInvoke = function(player: Player, giftIdx: number)
	local profile = ActiveProfiles[player.UserId]
	if not profile then return { Success = false, Message = "Profil belum siap." } end

	local g = PLAYTIME_INTERVALS[giftIdx]
	if not g then return { Success = false, Message = "Gift tidak valid." } end
	if profile.ClaimedGifts[giftIdx] then return { Success = false, Message = "Gift ini sudah diambil!" } end

	if (profile.PlaytimeMinutes or 0) < g.Min then
		return { Success = false, Message = string.format("Waktu online belum cukup (%d/%d menit)!", profile.PlaytimeMinutes, g.Min) }
	end

	profile.ClaimedGifts[giftIdx] = true
	profile.Gems += g.Gems
	UpdateLeaderstats(player)
	return { Success = true, Message = string.format("Gift diambil! +%s Gems!", FormatNumber(g.Gems)) }
end
	ClicksNormal = { Name = "Clicks Potion (Normal)", Type = "Clicks", Cost = 1000, Duration = 300 },
	ClicksMega = { Name = "Clicks Potion (Mega)", Type = "Clicks", Cost = 5000, Duration = 600 },
	ClicksUltra = { Name = "Clicks Potion (Ultra)", Type = "Clicks", Cost = 25000, Duration = 900 },
	GemsNormal = { Name = "Gems Potion (Normal)", Type = "Gems", Cost = 1000, Duration = 300 },
	GemsMega = { Name = "Gems Potion (Mega)", Type = "Gems", Cost = 5000, Duration = 600 },
	LuckNormal = { Name = "Luck Potion (Normal)", Type = "Luck", Cost = 2000, Duration = 300 },
	LuckMega = { Name = "Luck Potion (Mega)", Type = "Luck", Cost = 10000, Duration = 600 },
	RNGLuckPotion = { Name = "RNG Aura Luck Potion", Type = "AuraLuck", Cost = 15000, Duration = 300 },
	GoldenPotion = { Name = "Golden Mutation Potion", Type = "Mutation", Cost = 50000, Duration = 300 },
	ToxicPotion = { Name = "Toxic Mutation Potion", Type = "Mutation", Cost = 150000, Duration = 300 },
	ShinyPotion = { Name = "Shiny Mutation Potion", Type = "Mutation", Cost = 250000, Duration = 300 },
	GalaxyPotion = { Name = "Galaxy Mutation Potion", Type = "Mutation", Cost = 1000000, Duration = 300 },
}

BuyPotionRemote.OnServerInvoke = function(player: Player, potionKey: string)
	local profile = ActiveProfiles[player.UserId]
	if not profile then return { Success = false, Message = "Profil belum siap." } end

	local pot = POTIONS_DATABASE[potionKey]
	if not pot then return { Success = false, Message = "Potion tidak ditemukan." } end

	if profile.Gems < pot.Cost then
		return { Success = false, Message = string.format("Gems tidak cukup! Butuh %s Gems.", FormatNumber(pot.Cost)) }
	end

	profile.Gems -= pot.Cost
	local now = os.time()
	local currentExpiry = profile.ActivePotions[potionKey] or now
	profile.ActivePotions[potionKey] = math.max(currentExpiry, now) + pot.Duration

	UpdateLeaderstats(player)
	SyncActivePotionsEvent:FireClient(player, profile.ActivePotions)
	return {
		Success = true,
		DurationRemaining = profile.ActivePotions[potionKey] - now,
		Message = string.format("Berhasil membeli %s! Aktif selama %d detik.", pot.Name, pot.Duration),
	}
end

HatchExclusiveEggRemote.OnServerInvoke = function(player: Player, amountToHatch: number?)
	local profile = ActiveProfiles[player.UserId]
	if not profile or not profile.PetInventory then
		return { Success = false, Message = "Profil belum siap." }
	end

	local count = if amountToHatch == 10 then 10 else 1

	-- Cari pet terkuat yang sedang dimiliki
	local highestPetStat = 1
	for _, pet in pairs(profile.PetInventory) do
		local stat = (pet.BaseMultiplier or pet.Stat or 1) * (pet.Level or 1)
		if stat > highestPetStat then
			highestPetStat = stat
		end
	end

	local hatchedList = {}
	for _ = 1, count do
		local roll = math.random() * 100
		local boostMultiplier = 1.10
		local petTitle = "Astral Wyrm"

		if roll <= 0.5 then
			boostMultiplier = 5.00 -- 500% (5x stat pet terbaik)
			petTitle = "Archangel Sovereign Dragon"
		elseif roll <= 5.0 then
			boostMultiplier = 2.00 -- 200% (2x stat pet terbaik)
			petTitle = "Yggdrasil Ancient Dragon"
		elseif roll <= 20.0 then
			boostMultiplier = 1.50 -- 150% (1.5x stat pet terbaik)
			petTitle = "Voidborn Chimera"
		elseif roll <= 50.0 then
			boostMultiplier = 1.25 -- 125% (1.25x stat pet terbaik)
			petTitle = "Infernal Dread-Drake"
		else
			boostMultiplier = 1.10 -- 110% (1.1x stat pet terbaik)
			petTitle = "Astral Wyrm"
		end

		local newCalculatedStat = math.floor(highestPetStat * boostMultiplier)
		local newPetUUID = game:GetService("HttpService"):GenerateGUID(false)
		local exclusivePet = {
			UUID = newPetUUID,
			Name = string.format("%s (Exclusive)", petTitle),
			BaseMultiplier = newCalculatedStat,
			Mutation = "Normal",
			IsShiny = true,
			Level = 1,
			Locked = true,
			Equipped = false,
		}

		profile.PetInventory[newPetUUID] = exclusivePet
		profile.EggsHatched = (profile.EggsHatched or 0) + 1
		table.insert(hatchedList, exclusivePet)

		if boostMultiplier >= 2.00 then
			local rem = ReplicatedStorage:FindFirstChild("Remotes")
			local chatAnnounce = if rem then rem:FindFirstChild("GlobalHatchAnnouncement") :: RemoteEvent? else nil
			if chatAnnounce then
				chatAnnounce:FireAllClients(string.format("[EXCLUSIVE HATCH] %s baru saja mendapatkan %s (x%s Stat - %d%% Stat Pet Terbaik)!", player.Name, exclusivePet.Name, FormatNumber(newCalculatedStat), math.floor(boostMultiplier * 100)))
			end
		end
	end

	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Eggs") then
		ls.Eggs.Value = tostring(profile.EggsHatched)
	end

	BroadcastEquippedPets(player)
	return {
		Success = true,
		Count = count,
		Message = string.format("BERHASIL MEMBUKA %dx EXCLUSIVE FANTASY EGG!", count),
	}
end

local function LoadPlayerProfile(player: Player)
	local key = "Player_" .. tostring(player.UserId)
	local loadedData: PlayerProfileData? = nil

	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return PlayerDataStore:GetAsync(key)
		end)
		if ok then
			loadedData = result
			break
		else
			warn(string.format("[DataStore] Percobaan load ke-%d gagal untuk %s: %s", attempt, player.Name, tostring(result)))
			task.wait(1.5)
		end
	end

	local profile = CreateDefaultProfile()
	if type(loadedData) == "table" then
		for k, v in pairs(loadedData) do
			(profile :: any)[k] = v
		end
	end

	for gpKey, gpData in pairs(Config.Gamepasses) do
		local gpId = gpData.Id or gpData.GamepassId or 0
		if gpId > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gpId)
			end)
			if ok and owns then
				profile.OwnedGamepasses[gpKey] = true
			end
		end
	end

	ActiveProfiles[player.UserId] = profile

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local cVal = Instance.new("StringValue")
	cVal.Name = "Clicks"
	cVal.Parent = ls

	local rVal = Instance.new("StringValue")
	rVal.Name = "Rebirths"
	rVal.Parent = ls

	local gVal = Instance.new("StringValue")
	gVal.Name = "Gems"
	gVal.Parent = ls

	local eggsVal = Instance.new("StringValue")
	eggsVal.Name = "Eggs"
	eggsVal.Parent = ls

	local rankVal = Instance.new("StringValue")
	rankVal.Name = "Rank"
	rankVal.Parent = ls

	UpdateLeaderstats(player)
	BroadcastEquippedPets(player)
	SyncActivePotionsEvent:FireClient(player, profile.ActivePotions)

	-- Setup Overhead Rank Billboard saat karakter spawn
	local function SetupOverheadRank(character: Model)
		local head = character:WaitForChild("Head", 10) :: BasePart?
		if not head then return end

		local oldTag = head:FindFirstChild("OverheadRankTag")
		if oldTag then oldTag:Destroy() end

		local bb = Instance.new("BillboardGui")
		bb.Name = "OverheadRankTag"
		bb.Size = UDim2.fromOffset(180, 50)
		bb.StudsOffset = Vector3.new(0, 2.5, 0)
		bb.AlwaysOnTop = false
		bb.Parent = head

		local isVip = profile.OwnedGamepasses["VIP"] or profile.OwnedGamepasses["VIPStatus"]
		local rankName = "Rookie"
		if profile.Rebirths >= 1e18 then
			rankName = "Paradox Sovereign"
		elseif profile.Rebirths >= 1e12 then
			rankName = "Cosmic Legend"
		elseif profile.Rebirths >= 1e9 then
			rankName = "Billionaire Champion"
		elseif profile.Rebirths >= 1e6 then
			rankName = "Rebirth Master"
		elseif profile.Rebirths >= 1000 then
			rankName = "Elite Rebirther"
		elseif profile.Rebirths >= 25 then
			rankName = "Rising Star"
		end

		local tagLabel = Instance.new("TextLabel")
		tagLabel.Size = UDim2.fromScale(1, 1)
		tagLabel.BackgroundTransparency = 1
		tagLabel.Font = Enum.Font.FredokaOne
		tagLabel.TextScaled = true
		tagLabel.TextStrokeTransparency = 0.2
		tagLabel.TextColor3 = if isVip then Color3.fromRGB(250, 204, 21) else Color3.fromRGB(248, 250, 252)
		tagLabel.Text = (if isVip then "[VIP] " else "") .. string.format("[%s]\n%s", rankName, player.Name)
		tagLabel.Parent = bb

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local speedBonus = math.clamp(math.floor(math.log10(profile.Rebirths + 1) * 2), 0, 16)
			humanoid.WalkSpeed = 16 + speedBonus
		end
	end

	if player.Character then SetupOverheadRank(player.Character) end
	player.CharacterAdded:Connect(SetupOverheadRank)
end

local function SavePlayerProfile(player: Player, removeFromMemory: boolean)
	local userId = player.UserId
	local profile = ActiveProfiles[userId]
	if not profile then return end

	local key = "Player_" .. tostring(userId)
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			PlayerDataStore:UpdateAsync(key, function(_oldData)
				return profile
			end)
		end)
		if ok then
			break
		else
			warn(string.format("[DataStore] Gagal menyimpan data %s (Percobaan %d): %s", player.Name, attempt, tostring(err)))
			task.wait(1.5)
		end
	end

	if removeFromMemory then
		ActiveProfiles[userId] = nil
		ClickRateLimiter[userId] = nil
	end
end

Players.PlayerAdded:Connect(LoadPlayerProfile)
Players.PlayerRemoving:Connect(function(player)
	SavePlayerProfile(player, true)
end)

task.spawn(function()
	local secondsCounter = 60
	while true do
		task.wait(1)
		secondsCounter -= 1
		if secondsCounter <= 0 then
			secondsCounter = 60
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = ActiveProfiles[player.UserId]
				if profile then
					profile.AuraDiceCount = (profile.AuraDiceCount or 0) + 1
					profile.PlaytimeMinutes = (profile.PlaytimeMinutes or 0) + 1
					SyncPlaytimeEvent:FireClient(player, profile.PlaytimeMinutes)
				end
				task.spawn(SavePlayerProfile, player, false)
			end
		end

		SyncDiceTimerEvent:FireAllClients(secondsCounter)
	end
end)

task.spawn(function()
	while true do
		task.wait(1.5)
		for _, player in ipairs(Players:GetPlayers()) do
			local profile = ActiveProfiles[player.UserId]
			if profile and profile.OwnedGamepasses["AutoRebirth"] then
				-- Cari tombol rebirth tertinggi yang terbuka & mampu dibeli
				local highestUnlocked = 1
				for lvl = 0, math.min(profile.Upgrades.RebirthButtons, 54) do
					local buttons = REBIRTH_BUTTON_TIERS[lvl]
					if buttons then
						for _, btnAmount in ipairs(buttons) do
							if btnAmount > highestUnlocked then
								local cost = CalculateRebirthCost(profile.Rebirths, btnAmount)
								if profile.Clicks >= cost then
									highestUnlocked = btnAmount
								end
							end
						end
					end
				end

				local reqCost = CalculateRebirthCost(profile.Rebirths, highestUnlocked)
				if profile.Clicks >= reqCost then
					profile.Clicks = 0
					local rebirthMult = if profile.OwnedGamepasses["x2Rebirths"] then 2 else 1
					profile.Rebirths += (highestUnlocked * rebirthMult)
					local baseGems = highestUnlocked * 10
					profile.Gems += baseGems
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(SavePlayerProfile, player, true)
	end
	task.wait(3)
end)

print("[CoreLoopAndDataStoreService] Server engine aktif")

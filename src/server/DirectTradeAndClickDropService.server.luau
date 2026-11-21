--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Remote initialization (mencegah duplikasi jika sudah ada di ReplicatedStorage)
local function getOrCreateRemote(name: string): RemoteEvent
	local existing = RS:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remotesFolder = RS:FindFirstChild("Remotes")
	if remotesFolder then
		local inFolder = remotesFolder:FindFirstChild(name)
		if inFolder and inFolder:IsA("RemoteEvent") then
			return inFolder
		end
	end

	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = RS
	return r
end

local ClickEvent = getOrCreateRemote("ClickEvent")
local DataUpdate = getOrCreateRemote("DataUpdate")
local TradeSend = getOrCreateRemote("TradeSend")
local TradeIncoming = getOrCreateRemote("TradeIncoming")
local TradeRespond = getOrCreateRemote("TradeRespond")
local TradeResult = getOrCreateRemote("TradeResult")

local function getOrCreateRemoteFunction(name: string): RemoteFunction
	local existing = RS:FindFirstChild(name)
	if existing and existing:IsA("RemoteFunction") then
		return existing
	end

	local remotesFolder = RS:FindFirstChild("Remotes")
	if remotesFolder then
		local inFolder = remotesFolder:FindFirstChild(name)
		if inFolder and inFolder:IsA("RemoteFunction") then
			return inFolder
		end
	end

	local r = Instance.new("RemoteFunction")
	r.Name = name
	r.Parent = RS
	return r
end

local HatchEggRemoteServer = getOrCreateRemoteFunction("HatchEggFunction")

-- Pastikan juga tersedia di dalam ReplicatedStorage.Remotes
local remFolder = RS:FindFirstChild("Remotes")
if not remFolder then
	remFolder = Instance.new("Folder")
	remFolder.Name = "Remotes"
	remFolder.Parent = RS
end
if not remFolder:FindFirstChild("HatchEggFunction") then
	local rInRem = Instance.new("RemoteFunction")
	rInRem.Name = "HatchEggFunction"
	rInRem.Parent = remFolder
	rInRem.OnServerInvoke = function(plr, ...)
		return HatchEggRemoteServer.OnServerInvoke(plr, ...)
	end
end

-- Item drop config
local DROPS = {
	{ Name = "Common Pet", Weight = 70, Multiplier = 1.2, Rarity = "Common" },
	{ Name = "Rare Pet", Weight = 22, Multiplier = 1.8, Rarity = "Rare" },
	{ Name = "Epic Pet", Weight = 7, Multiplier = 3.5, Rarity = "Epic" },
	{ Name = "Legendary Pet", Weight = 1, Multiplier = 10.0, Rarity = "Legendary" },
}
local DROP_CHANCE = 0.08 -- 8% per click
local START_CAPACITY = 20

-- Local fallback data jika player profile belum dimuat dari DataStore
local localData: { [Player]: { Clicks: number, Capacity: number, Items: { [string]: number } } } = {}
local pendingOffers: { [Player]: { from: Player, item: string?, clicks: number, timestamp: number } } = {}
local activeSenders: { [Player]: Player } = {} -- [sender] = target
local lastClickTime: { [Player]: number } = {}

-- Utility: Menghitung total item di inventori
local function getInventorySummary(plr: Player): (number, number, { [string]: number })
	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(plr) else nil
	if profile and profile.PetInventory then
		local items: { [string]: number } = {}
		local count = 0
		for _, pet in pairs(profile.PetInventory) do
			if pet and pet.Name then
				items[pet.Name] = (items[pet.Name] or 0) + 1
				count += 1
			end
		end
		local capacity = START_CAPACITY + ((profile.Upgrades and profile.Upgrades.PetEquipSlots or 0) * 5)
		return count, capacity, items
	end

	local d = localData[plr]
	if not d then
		return 0, START_CAPACITY, {}
	end
	local count = 0
	for _, c in pairs(d.Items) do
		count += c
	end
	return count, d.Capacity, d.Items
end

-- Kirim data terkini ke Client
local function pushData(plr: Player)
	if not plr.Parent then return end
	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(plr) else nil
	local clicks = 0
	local count, capacity, items = getInventorySummary(plr)

	if profile then
		clicks = profile.Clicks or 0
	elseif localData[plr] then
		clicks = localData[plr].Clicks
		capacity = localData[plr].Capacity
		items = localData[plr].Items
	end

	DataUpdate:FireClient(plr, clicks, capacity, items)
end

_G.GetPlayerClicks = function(plr: Player): number
	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(plr) else nil
	if profile and profile.Clicks ~= nil then
		return profile.Clicks
	end
	if localData[plr] then
		return localData[plr].Clicks or 0
	end
	return 0
end

_G.DeductPlayerClicks = function(plr: Player, amount: number): boolean
	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(plr) else nil
	if profile and profile.Clicks ~= nil then
		if profile.Clicks >= amount then
			profile.Clicks -= amount
			if _G.UpdateLeaderstats then _G.UpdateLeaderstats(plr) end
			pushData(plr)
			return true
		end
		return false
	end
	if localData[plr] then
		if (localData[plr].Clicks or 0) >= amount then
			localData[plr].Clicks -= amount
			pushData(plr)
			return true
		end
		return false
	end
	return false
end

local EGG_PRICES = { Basic = 250, Forest = 5000, Mythic = 25000, Farm = 100000 }
local EGG_PET_DROPS = {
	Basic = {
		{ Name = "Dog", Weight = 50, Rarity = "Common", Stat = 1.2 },
		{ Name = "Cat", Weight = 35, Rarity = "Rare", Stat = 1.4 },
		{ Name = "Bunny", Weight = 15, Rarity = "Epic", Stat = 2.0 },
	},
	Forest = {
		{ Name = "Bear", Weight = 50, Rarity = "Common", Stat = 3.0 },
		{ Name = "Wolf", Weight = 30, Rarity = "Rare", Stat = 4.5 },
		{ Name = "Fox", Weight = 17, Rarity = "Epic", Stat = 6.0 },
		{ Name = "Forest Dragon", Weight = 3, Rarity = "Legendary", Stat = 10.0 },
	},
	Mythic = {
		{ Name = "Fox", Weight = 55, Rarity = "Common", Stat = 9.0 },
		{ Name = "Golem", Weight = 30, Rarity = "Rare", Stat = 13.0 },
		{ Name = "Hydra", Weight = 15, Rarity = "Epic", Stat = 18.0 },
		{ Name = "Bat", Weight = 5, Rarity = "Legendary", Stat = 30.0 },
	},
	Farm = {
		{ Name = "Pig", Weight = 50, Rarity = "Common", Stat = 40.0 },
		{ Name = "Duck", Weight = 30, Rarity = "Rare", Stat = 65.0 },
		{ Name = "Cow", Weight = 16, Rarity = "Epic", Stat = 100.0 },
		{ Name = "Goat", Weight = 4.75, Rarity = "Legendary", Stat = 250.0 },
		{ Name = "Apple Dragon", Weight = 0.25, Rarity = "Secret", Stat = 1200.0 },
	},
}

HatchEggRemoteServer.OnServerInvoke = function(plr: Player, eggId: string, count: number)
	count = math.clamp(math.floor(count or 1), 1, 3)
	local costPerEgg = EGG_PRICES[eggId] or 250
	local totalCost = costPerEgg * count
	local userClicks = if _G.GetPlayerClicks then _G.GetPlayerClicks(plr) else 0

	if userClicks < totalCost then
		return { Success = false, Message = "Clicks tidak cukup! Butuh " .. totalCost .. " Clicks." }
	end

	if _G.DeductPlayerClicks then
		_G.DeductPlayerClicks(plr, totalCost)
	end

	local results = {}
	local pool = EGG_PET_DROPS[eggId] or EGG_PET_DROPS.Basic
	for _ = 1, count do
		local totalW = 0
		for _, v in ipairs(pool) do totalW += v.Weight end
		local r = math.random() * totalW
		local chosen = pool[1]
		for _, v in ipairs(pool) do
			r -= v.Weight
			if r <= 0 then chosen = v; break end
		end

		local petRecord = {
			UUID = HttpService:GenerateGUID(false),
			Name = chosen.Name,
			Rarity = chosen.Rarity,
			BaseMultiplier = chosen.Stat,
			Level = 1,
			Equipped = false,
		}

		local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(plr) else nil
		if profile then
			profile.PetInventory = profile.PetInventory or {}
			profile.PetInventory[petRecord.UUID] = petRecord
			profile.EggsHatched = (profile.EggsHatched or 0) + 1
		elseif localData[plr] then
			localData[plr].Items[chosen.Name] = (localData[plr].Items[chosen.Name] or 0) + 1
		end
		table.insert(results, petRecord)
	end

	pushData(plr)
	return { Success = true, EggName = eggId, HatchedPets = results }
end

-- Roll drop berdasarkan weight
local function rollDrop()
	local totalWeight = 0
	for _, v in ipairs(DROPS) do
		totalWeight += v.Weight
	end
	local r = math.random() * totalWeight
	for _, v in ipairs(DROPS) do
		r -= v.Weight
		if r <= 0 then
			return v
		end
	end
	return DROPS[1]
end

Players.PlayerAdded:Connect(function(plr)
	localData[plr] = { Clicks = 0, Capacity = START_CAPACITY, Items = {} }
	task.wait(1)
	if plr.Parent then
		pushData(plr)
	end
end)

for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		localData[plr] = { Clicks = 0, Capacity = START_CAPACITY, Items = {} }
		task.wait(0.5)
		if plr.Parent then
			pushData(plr)
		end
	end)
end

Players.PlayerRemoving:Connect(function(plr)
	localData[plr] = nil
	lastClickTime[plr] = nil

	-- Bersihkan penawaran masuk ke pemain ini
	local incoming = pendingOffers[plr]
	if incoming and incoming.from and incoming.from.Parent then
		activeSenders[incoming.from] = nil
		TradeResult:FireClient(incoming.from, plr.Name .. " telah keluar dari server. Trade dibatalkan.")
	end
	pendingOffers[plr] = nil

	-- Bersihkan penawaran keluar dari pemain ini
	local sentTarget = activeSenders[plr]
	if sentTarget then
		activeSenders[plr] = nil
		if pendingOffers[sentTarget] and pendingOffers[sentTarget].from == plr then
			pendingOffers[sentTarget] = nil
			if sentTarget.Parent then
				TradeResult:FireClient(sentTarget, plr.Name .. " telah keluar dari server. Trade dibatalkan.")
			end
		end
	end
end)

-- Click Event dengan anti-spam & drop rate
ClickEvent.OnServerEvent:Connect(function(plr)
	local now = os.clock()
	if lastClickTime[plr] and (now - lastClickTime[plr]) < 0.05 then
		return
	end
	lastClickTime[plr] = now

	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(plr) else nil
	local count, capacity, _ = getInventorySummary(plr)

	if profile then
		profile.Clicks = (profile.Clicks or 0) + 1
		if _G.UpdateLeaderstats then
			_G.UpdateLeaderstats(plr)
		end
	elseif localData[plr] then
		localData[plr].Clicks += 1
	else
		localData[plr] = { Clicks = 1, Capacity = START_CAPACITY, Items = {} }
	end

	-- Chance Drop
	if math.random() < DROP_CHANCE and count < capacity then
		local dropInfo = rollDrop()
		if profile then
			profile.PetInventory = profile.PetInventory or {}
			local uuid = HttpService:GenerateGUID(false)
			profile.PetInventory[uuid] = {
				UUID = uuid,
				Name = dropInfo.Name,
				Rarity = dropInfo.Rarity,
				Mutation = "Normal",
				IsShiny = false,
				Level = 1,
				XP = 0,
				BaseMultiplier = dropInfo.Multiplier,
				Equipped = false,
			}
			local remotesFolder = RS:FindFirstChild("Remotes")
			local syncInv = if remotesFolder then remotesFolder:FindFirstChild("SyncInventoryEvent") :: RemoteEvent? else nil
			if syncInv then
				syncInv:FireClient(plr, profile.PetInventory)
			end
		elseif localData[plr] then
			localData[plr].Items[dropInfo.Name] = (localData[plr].Items[dropInfo.Name] or 0) + 1
		end
	end

	pushData(plr)
end)

-- Trade: Kirim penawaran
TradeSend.OnServerEvent:Connect(function(plr, targetId, item, clicks)
	local targetUserId = tonumber(targetId) or 0
	local target = Players:GetPlayerByUserId(targetUserId)

	if not target or target == plr or not target.Parent then
		TradeResult:FireClient(plr, "Target pemain tidak ditemukan.")
		return
	end

	if activeSenders[plr] then
		TradeResult:FireClient(plr, "Kamu sudah memiliki penawaran trade yang sedang berjalan.")
		return
	end

	if pendingOffers[target] then
		TradeResult:FireClient(plr, target.Name .. " sedang menerima penawaran trade lain.")
		return
	end

	local cleanClicks = math.floor(tonumber(clicks) or 0)
	if cleanClicks < 0 then
		cleanClicks = 0
	end

	if type(item) ~= "string" or item == "" then
		item = nil
	end

	if cleanClicks == 0 and not item then
		TradeResult:FireClient(plr, "Trade harus menyertakan Clicks atau Item.")
		return
	end

	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(plr) else nil
	local currentClicks = profile and profile.Clicks or (localData[plr] and localData[plr].Clicks or 0)
	if cleanClicks > currentClicks then
		TradeResult:FireClient(plr, "Clicks kamu tidak mencukupi.")
		return
	end

	local _, _, currentItems = getInventorySummary(plr)
	if item and (currentItems[item] or 0) < 1 then
		TradeResult:FireClient(plr, "Item tidak ditemukan di inventori kamu.")
		return
	end

	local offer = {
		from = plr,
		item = item,
		clicks = cleanClicks,
		timestamp = os.clock(),
	}

	pendingOffers[target] = offer
	activeSenders[plr] = target

	TradeIncoming:FireClient(target, plr.Name, item, cleanClicks)
	TradeResult:FireClient(plr, "Trade berhasil dikirim ke " .. target.Name)

	-- Auto-cancel setelah 30 detik jika tidak direspon
	task.delay(30, function()
		if pendingOffers[target] == offer then
			pendingOffers[target] = nil
			if activeSenders[plr] == target then
				activeSenders[plr] = nil
			end
			if plr.Parent then
				TradeResult:FireClient(plr, "Trade ke " .. target.Name .. " telah kadaluarsa (30s).")
			end
			if target.Parent then
				TradeResult:FireClient(target, "Permintaan trade dari " .. plr.Name .. " telah kadaluarsa.")
			end
		end
	end)
end)

-- Trade: Respon penawaran (Terima / Tolak)
TradeRespond.OnServerEvent:Connect(function(target, accept)
	local offer = pendingOffers[target]
	if not offer then
		return
	end

	pendingOffers[target] = nil
	local from = offer.from
	if activeSenders[from] == target then
		activeSenders[from] = nil
	end

	if not from or not from.Parent or not target.Parent then
		return
	end

	if not accept then
		TradeResult:FireClient(from, target.Name .. " menolak trade.")
		TradeResult:FireClient(target, "Kamu menolak trade dari " .. from.Name)
		return
	end

	-- Validasi ulang saldo dan item pengirim
	local profFrom = if _G.GetPlayerProfile then _G.GetPlayerProfile(from) else nil
	local profTarget = if _G.GetPlayerProfile then _G.GetPlayerProfile(target) else nil
	local fromClicks = profFrom and profFrom.Clicks or (localData[from] and localData[from].Clicks or 0)

	if fromClicks < offer.clicks then
		TradeResult:FireClient(from, "Trade gagal: Clicks kamu berkurang saat proses trade.")
		TradeResult:FireClient(target, "Trade gagal: Clicks pengirim tidak cukup.")
		return
	end

	local _, _, fromItems = getInventorySummary(from)
	if offer.item and (fromItems[offer.item] or 0) < 1 then
		TradeResult:FireClient(from, "Trade gagal: Item tidak lagi tersedia.")
		TradeResult:FireClient(target, "Trade gagal: Item pengirim sudah tidak ada.")
		return
	end

	local targetCount, targetCapacity, _ = getInventorySummary(target)
	if offer.item and targetCount >= targetCapacity then
		TradeResult:FireClient(from, "Trade gagal: Backpack " .. target.Name .. " penuh.")
		TradeResult:FireClient(target, "Trade gagal: Backpack kamu penuh.")
		return
	end

	-- Eksekusi transfer Clicks
	if profFrom and profTarget then
		profFrom.Clicks -= offer.clicks
		profTarget.Clicks += offer.clicks
	elseif localData[from] and localData[target] then
		localData[from].Clicks -= offer.clicks
		localData[target].Clicks += offer.clicks
	end

	-- Eksekusi transfer Item
	if offer.item then
		if profFrom and profTarget and profFrom.PetInventory and profTarget.PetInventory then
			-- Ambil 1 instance pet dari sender
			local transferredUUID = nil
			local transferredPet = nil
			for uuid, pet in pairs(profFrom.PetInventory) do
				if pet.Name == offer.item and not pet.Equipped then
					transferredUUID = uuid
					transferredPet = pet
					break
				end
			end
			-- Jika semua ter-equip, ambil yang pertama dan unequip
			if not transferredUUID then
				for uuid, pet in pairs(profFrom.PetInventory) do
					if pet.Name == offer.item then
						transferredUUID = uuid
						transferredPet = pet
						pet.Equipped = false
						break
					end
				end
			end

			if transferredUUID and transferredPet then
				profFrom.PetInventory[transferredUUID] = nil
				profTarget.PetInventory[transferredUUID] = transferredPet
			end

			local remotesFolder = RS:FindFirstChild("Remotes")
			local syncInv = if remotesFolder then remotesFolder:FindFirstChild("SyncInventoryEvent") :: RemoteEvent? else nil
			if syncInv then
				syncInv:FireClient(from, profFrom.PetInventory)
				syncInv:FireClient(target, profTarget.PetInventory)
			end
		elseif localData[from] and localData[target] then
			localData[from].Items[offer.item] -= 1
			if localData[from].Items[offer.item] <= 0 then
				localData[from].Items[offer.item] = nil
			end
			localData[target].Items[offer.item] = (localData[target].Items[offer.item] or 0) + 1
		end
	end

	if _G.UpdateLeaderstats then
		_G.UpdateLeaderstats(from)
		_G.UpdateLeaderstats(target)
	end

	pushData(from)
	pushData(target)

	TradeResult:FireClient(from, "Trade berhasil diselesaikan!")
	TradeResult:FireClient(target, "Trade berhasil diselesaikan!")
end)

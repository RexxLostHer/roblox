--!strict
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("RebirthChampionsConfig"))

export type BoothListing = {
	ListingId: string,
	SellerUserId: number,
	SellerName: string,
	PetUUID: string,
	PetSnapshot: {
		Name: string,
		Rarity: string,
		Mutation: string,
		IsShiny: boolean,
		Level: number,
		FinalMultiplier: number,
	},
	PriceTokens: number,
}

export type DirectTradeSession = {
	SessionId: string,
	PlayerA: Player,
	PlayerB: Player,
	OfferA: { Pets: { [string]: boolean }, Tokens: number },
	OfferB: { Pets: { [string]: boolean }, Tokens: number },
	ReadyA: boolean,
	ReadyB: boolean,
	ConfirmedA: boolean,
	ConfirmedB: boolean,
	LastModifiedClock: number,
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

local ClaimBoothRemote: RemoteFunction = GetOrCreateRemote("ClaimBoothFunction", "RemoteFunction")
local ListPetOnBoothRemote: RemoteFunction = GetOrCreateRemote("ListPetOnBoothFunction", "RemoteFunction")
local RemoveBoothListingRemote: RemoteFunction = GetOrCreateRemote("RemoveBoothListingFunction", "RemoteFunction")
local BuyBoothItemRemote: RemoteFunction = GetOrCreateRemote("BuyBoothItemFunction", "RemoteFunction")
local DirectTradeActionRemote: RemoteFunction = GetOrCreateRemote("DirectTradeActionFunction", "RemoteFunction")
local BoothStateSyncEvent: RemoteEvent = GetOrCreateRemote("BoothStateSyncEvent", "RemoteEvent")

local MAX_BOOTHS = 12
local ActiveBooths: {
	[number]: {
		BoothIndex: number,
		OwnerUserId: number?,
		OwnerName: string?,
		SignText: string,
		Listings: { [string]: BoothListing },
	}
} = {}

for i = 1, MAX_BOOTHS do
	ActiveBooths[i] = {
		BoothIndex = i,
		OwnerUserId = nil,
		OwnerName = nil,
		SignText = "Stan Kosong - Klaim Sekarang!",
		Listings = {},
	}
end

local PurchaseLocks: { [string]: boolean } = {}
local ActiveTradeSessions: { [string]: DirectTradeSession } = {}
local BlockedTraders: { [number]: { [number]: boolean } } = {}

local function BroadcastBoothsUpdate()
	BoothStateSyncEvent:FireAllClients(ActiveBooths)
end

local function GetPlayerBooth(userId: number)
	for _, booth in pairs(ActiveBooths) do
		if booth.OwnerUserId == userId then
			return booth
		end
	end
	return nil
end

local function CalculateFinalPetMultiplier(baseMult: number, mutation: string, isShiny: boolean, level: number): number
	local tierInfo = Config.MutationTiers and Config.MutationTiers.Tiers and Config.MutationTiers.Tiers[mutation]
	local mult = 1.0
	if tierInfo then
		mult = if isShiny then (tierInfo.ShinyMultiplier or 1.5) else (tierInfo.Multiplier or 1.0)
	end
	return baseMult * mult * (level or 1)
end

ClaimBoothRemote.OnServerInvoke = function(player: Player, requestedBoothIndex: number, customSignText: string?)
	local existing = GetPlayerBooth(player.UserId)
	if existing then
		if type(customSignText) == "string" and #customSignText <= 40 then
			existing.SignText = customSignText
			BroadcastBoothsUpdate()
		end
		return { Success = true, BoothIndex = existing.BoothIndex, Message = "Stan kamu sudah aktif!" }
	end

	local booth = ActiveBooths[requestedBoothIndex]
	if not booth or booth.OwnerUserId ~= nil then
		return { Success = false, Message = "Stan ini sudah dimiliki pemain lain!" }
	end

	booth.OwnerUserId = player.UserId
	booth.OwnerName = player.Name
	booth.SignText = if type(customSignText) == "string" and #customSignText > 0 then string.sub(customSignText, 1, 40) else (player.Name .. "'s Pet Shop")
	booth.Listings = {}

	BroadcastBoothsUpdate()
	return { Success = true, BoothIndex = requestedBoothIndex, Message = string.format("Berhasil mengklaim Booth #%d!", requestedBoothIndex) }
end

ListPetOnBoothRemote.OnServerInvoke = function(player: Player, petUUID: string, priceTokens: number)
	local booth = GetPlayerBooth(player.UserId)
	if not booth then
		return { Success = false, Message = "Klaim Booth terlebih dahulu sebelum memajang Pet!" }
	end

	if type(priceTokens) ~= "number" or priceTokens < 1 or priceTokens > 1e12 then
		return { Success = false, Message = "Harga Trade Tokens harus antara 1 hingga 1,000,000,000,000!" }
	end
	priceTokens = math.floor(priceTokens)

	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil
	if not profile or not profile.PetInventory then
		return { Success = false, Message = "Profil pemain belum siap." }
	end

	local pet = profile.PetInventory[petUUID]
	if not pet then
		return { Success = false, Message = "Pet tidak ditemukan di inventorimu." }
	end
	if pet.Locked then
		return { Success = false, Message = "Buka kunci (Unlock) Pet terlebih dahulu sebelum menjualnya!" }
	end

	for _, item in pairs(booth.Listings) do
		if item.PetUUID == petUUID then
			return { Success = false, Message = "Pet ini sudah dipajang di Booth kamu!" }
		end
	end

	local finalMult = CalculateFinalPetMultiplier(pet.BaseMultiplier or pet.Stat or 1, pet.Mutation or "Normal", pet.IsShiny == true, pet.Level or 1)
	local listingId = HttpService:GenerateGUID(false)

	booth.Listings[listingId] = {
		ListingId = listingId,
		SellerUserId = player.UserId,
		SellerName = player.Name,
		PetUUID = petUUID,
		PetSnapshot = {
			Name = pet.Name,
			Rarity = pet.Rarity or "Common",
			Mutation = pet.Mutation or "Normal",
			IsShiny = pet.IsShiny == true,
			Level = pet.Level or 1,
			FinalMultiplier = finalMult,
		},
		PriceTokens = priceTokens,
	}

	BroadcastBoothsUpdate()
	return {
		Success = true,
		ListingId = listingId,
		Message = string.format("%s berhasil dipajang seharga %d Trade Tokens!", pet.Name, priceTokens),
	}
end

RemoveBoothListingRemote.OnServerInvoke = function(player: Player, listingId: string)
	local booth = GetPlayerBooth(player.UserId)
	if not booth or not booth.Listings[listingId] then
		return { Success = false, Message = "Listing tidak ditemukan." }
	end

	booth.Listings[listingId] = nil
	BroadcastBoothsUpdate()
	return { Success = true, Message = "Pet berhasil ditarik kembali dari Booth." }
end

BuyBoothItemRemote.OnServerInvoke = function(buyer: Player, boothIndex: number, listingId: string)
	if PurchaseLocks[listingId] then
		return { Success = false, Message = "Item ini sedang diproses oleh pembeli lain!" }
	end
	PurchaseLocks[listingId] = true

	local function ReleaseAndReturn(res: any)
		PurchaseLocks[listingId] = nil
		return res
	end

	local booth = ActiveBooths[boothIndex]
	if not booth or not booth.OwnerUserId then
		return ReleaseAndReturn({ Success = false, Message = "Booth sudah tidak aktif." })
	end

	local listing = booth.Listings[listingId]
	if not listing then
		return ReleaseAndReturn({ Success = false, Message = "Item sudah terjual atau ditarik penjual!" })
	end

	if buyer.UserId == listing.SellerUserId then
		return ReleaseAndReturn({ Success = false, Message = "Kamu tidak bisa membeli item milikmu sendiri!" })
	end

	local seller = Players:GetPlayerByUserId(listing.SellerUserId)
	if not seller then
		return ReleaseAndReturn({ Success = false, Message = "Penjual sudah keluar dari server." })
	end

	local buyerProfile = if _G.GetPlayerProfile then _G.GetPlayerProfile(buyer) else nil
	local sellerProfile = if _G.GetPlayerProfile then _G.GetPlayerProfile(seller) else nil
	if not buyerProfile or not sellerProfile then
		return ReleaseAndReturn({ Success = false, Message = "Data transaksi belum siap." })
	end

	local petToTransfer = sellerProfile.PetInventory[listing.PetUUID]
	if not petToTransfer then
		booth.Listings[listingId] = nil
		BroadcastBoothsUpdate()
		return ReleaseAndReturn({ Success = false, Message = "Pet sudah tidak ada di inventori penjual." })
	end

	if (buyerProfile.TradeTokens or 0) < listing.PriceTokens then
		return ReleaseAndReturn({
			Success = false,
			Message = string.format("Trade Tokens tidak cukup! Butuh %d Tokens.", listing.PriceTokens),
		})
	end

	buyerProfile.TradeTokens = (buyerProfile.TradeTokens or 0) - listing.PriceTokens
	sellerProfile.TradeTokens = (sellerProfile.TradeTokens or 0) + listing.PriceTokens

	sellerProfile.PetInventory[listing.PetUUID] = nil
	petToTransfer.Equipped = false
	buyerProfile.PetInventory[listing.PetUUID] = petToTransfer

	booth.Listings[listingId] = nil
	BroadcastBoothsUpdate()

	return ReleaseAndReturn({
		Success = true,
		Message = string.format(
			"BERHASIL MEMBELI %s %s dari %s seharga %d Tokens!",
			listing.PetSnapshot.Mutation,
			listing.PetSnapshot.Name,
			seller.Name,
			listing.PriceTokens
		),
	})
end

DirectTradeActionRemote.OnServerInvoke = function(player: Player, action: string, payload: any)
	if action == "BlockPlayer" then
		local targetUserId = tonumber(payload.TargetUserId)
		if not targetUserId then
			return { Success = false, Message = "Target pemain tidak valid." }
		end
		BlockedTraders[player.UserId] = BlockedTraders[player.UserId] or {}
		BlockedTraders[player.UserId][targetUserId] = true
		return { Success = true, Message = "Pemain berhasil diblokir dari pengiriman Trade." }
	elseif action == "SendRequest" then
		local targetPlayer = Players:GetPlayerByUserId(tonumber(payload.TargetUserId) or 0)
		if not targetPlayer or targetPlayer == player then
			return { Success = false, Message = "Pemain tujuan tidak ditemukan." }
		end
		if BlockedTraders[targetPlayer.UserId] and BlockedTraders[targetPlayer.UserId][player.UserId] then
			return { Success = false, Message = "Pemain ini memblokir permintaan Trade dari kamu." }
		end

		local sessionId = HttpService:GenerateGUID(false)
		ActiveTradeSessions[sessionId] = {
			SessionId = sessionId,
			PlayerA = player,
			PlayerB = targetPlayer,
			OfferA = { Pets = {}, Tokens = 0 },
			OfferB = { Pets = {}, Tokens = 0 },
			ReadyA = false,
			ReadyB = false,
			ConfirmedA = false,
			ConfirmedB = false,
			LastModifiedClock = os.clock(),
		}
		return { Success = true, SessionId = sessionId, Message = "Permintaan Trade dikirim ke " .. targetPlayer.Name }
	elseif action == "ConfirmTrade" then
		local session = ActiveTradeSessions[payload.SessionId]
		if not session then
			return { Success = false, Message = "Sesi Trade sudah berakhir." }
		end

		if (os.clock() - session.LastModifiedClock) < 5.0 then
			return {
				Success = false,
				Message = "Tunggu 5 detik setelah perubahan penawaran terakhir sebelum melakukan konfirmasi!",
			}
		end

		if player == session.PlayerA then
			session.ConfirmedA = true
		elseif player == session.PlayerB then
			session.ConfirmedB = true
		end

		if session.ConfirmedA and session.ConfirmedB then
			local profA = if _G.GetPlayerProfile then _G.GetPlayerProfile(session.PlayerA) else nil
			local profB = if _G.GetPlayerProfile then _G.GetPlayerProfile(session.PlayerB) else nil
			if not profA or not profB then
				ActiveTradeSessions[session.SessionId] = nil
				return { Success = false, Message = "Gagal memuat profil kedua pemain." }
			end

			if (profA.TradeTokens or 0) < session.OfferA.Tokens or (profB.TradeTokens or 0) < session.OfferB.Tokens then
				ActiveTradeSessions[session.SessionId] = nil
				return { Success = false, Message = "Trade batal: Jumlah Trade Tokens salah satu pemain berubah!" }
			end

			profA.TradeTokens = (profA.TradeTokens or 0) - session.OfferA.Tokens + session.OfferB.Tokens
			profB.TradeTokens = (profB.TradeTokens or 0) - session.OfferB.Tokens + session.OfferA.Tokens

			for uuid in pairs(session.OfferA.Pets) do
				local pet = profA.PetInventory[uuid]
				if pet then
					profA.PetInventory[uuid] = nil
					pet.Equipped = false
					profB.PetInventory[uuid] = pet
				end
			end

			for uuid in pairs(session.OfferB.Pets) do
				local pet = profB.PetInventory[uuid]
				if pet then
					profB.PetInventory[uuid] = nil
					pet.Equipped = false
					profA.PetInventory[uuid] = pet
				end
			end

			ActiveTradeSessions[session.SessionId] = nil
			return { Success = true, Completed = true, Message = "TRADE SELESAI! Semua Pet dan Tokens berhasil ditukar." }
		end

		return { Success = true, Completed = false, Message = "Menunggu konfirmasi pemain lawan..." }
	end

	return { Success = false, Message = "Aksi Trade tidak dikenal." }
end

Players.PlayerRemoving:Connect(function(player: Player)
	local booth = GetPlayerBooth(player.UserId)
	if booth then
		booth.OwnerUserId = nil
		booth.OwnerName = nil
		booth.SignText = "Stan Kosong - Klaim Sekarang!"
		table.clear(booth.Listings)
		BroadcastBoothsUpdate()
	end
end)

print("[TradingPlazaAndBoothsSystem] Server marketplace aktif")

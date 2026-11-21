--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

export type SpinSlice = {
	Index: number,
	Label: string,
	RewardType: "Clicks" | "Gems" | "AuraDices" | "TradeTokens" | "LuckPotion" | "ExclusivePet",
	Amount: number,
	ChancePercent: number,
}

local DAILY_SPIN_SLICES: { SpinSlice } = {
	{ Index = 1, Label = "2,500 Gems", RewardType = "Gems", Amount = 2500, ChancePercent = 30.0 },
	{ Index = 2, Label = "10,000 Clicks", RewardType = "Clicks", Amount = 10000, ChancePercent = 25.0 },
	{ Index = 3, Label = "3x Aura Dices", RewardType = "AuraDices", Amount = 3, ChancePercent = 18.0 },
	{ Index = 4, Label = "15m Luck Potion", RewardType = "LuckPotion", Amount = 900, ChancePercent = 12.0 },
	{ Index = 5, Label = "50,000 Gems", RewardType = "Gems", Amount = 50000, ChancePercent = 8.0 },
	{ Index = 6, Label = "25 Trade Tokens", RewardType = "TradeTokens", Amount = 25, ChancePercent = 4.5 },
	{ Index = 7, Label = "10x Aura Dices", RewardType = "AuraDices", Amount = 10, ChancePercent = 2.0 },
	{ Index = 8, Label = "EXCLUSIVE SPIN DRAGON (x50,000)", RewardType = "ExclusivePet", Amount = 50000, ChancePercent = 0.5 },
}

local PROMO_CODES: { [string]: { Gems: number, Dices: number, Desc: string } } = {
	["release"] = { Gems = 5000, Dices = 3, Desc = "+5,000 Gems & +3 Aura Dices" },
	["thunder"] = { Gems = 25000, Dices = 5, Desc = "+25,000 Gems & +5 Aura Dices (Update 53)" },
	["temple"] = { Gems = 50000, Dices = 5, Desc = "+50,000 Gems & +5 Aura Dices (Update 56)" },
	["crystal"] = { Gems = 100000, Dices = 10, Desc = "+100,000 Gems & +10 Aura Dices (Update 59)" },
	["wildwest"] = { Gems = 75000, Dices = 5, Desc = "+75,000 Gems & +5 Aura Dices (Update 48)" },
}

local ClicksODS = DataStoreService:GetOrderedDataStore("RC_GlobalClicks_v1")
local RebirthsODS = DataStoreService:GetOrderedDataStore("RC_GlobalRebirths_v1")
local GemsODS = DataStoreService:GetOrderedDataStore("RC_GlobalGems_v1")

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

local DailySpinRemote: RemoteFunction = GetOrCreateRemote("SpinDailyWheelFunction", "RemoteFunction")
local RedeemCodeRemote: RemoteFunction = GetOrCreateRemote("RedeemPromoCodeFunction", "RemoteFunction")
local ClaimGroupChestRemote: RemoteFunction = GetOrCreateRemote("ClaimGroupChestFunction", "RemoteFunction")

local LastSpinTimestamp: { [number]: number } = {}
local LastChestTimestamp: { [number]: number } = {}
local RedeemedCodesByPlayer: { [number]: { [string]: boolean } } = {}

local function EncodeBigNumForODS(val: number): number
	if val <= 0 then
		return 0
	end
	return math.floor(math.log10(val + 1) * 1e7)
end

local function DecodeBigNumFromODS(encoded: number): string
	if encoded <= 0 then
		return "0"
	end
	local logVal = encoded / 1e7
	local suffixes = { "", "K", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "O", "N", "Dc" }
	local idx = math.clamp(math.floor(logVal / 3) + 1, 1, #suffixes)
	local rem = logVal - ((idx - 1) * 3)
	return string.format("%.2f%s", math.pow(10, rem), suffixes[idx])
end

local LeaderboardFolder = workspace:FindFirstChild("GlobalLeaderboardsAndStatues") :: Folder?
if LeaderboardFolder then
	LeaderboardFolder:Destroy()
end
LeaderboardFolder = Instance.new("Folder")
LeaderboardFolder.Name = "GlobalLeaderboardsAndStatues"
LeaderboardFolder.Parent = workspace

local BOARD_CONFIGS = {
	{ Key = "Clicks", Title = "TOP GLOBAL CLICKS", Color = Color3.fromRGB(56, 189, 248), Pos = Vector3.new(-22, 9, 64), ODS = ClicksODS },
	{ Key = "Rebirths", Title = "TOP GLOBAL REBIRTHS", Color = Color3.fromRGB(250, 204, 21), Pos = Vector3.new(0, 9, 64), ODS = RebirthsODS },
	{ Key = "Gems", Title = "TOP GLOBAL GEMS", Color = Color3.fromRGB(168, 85, 247), Pos = Vector3.new(22, 9, 64), ODS = GemsODS },
}

local BoardScrollFrames: { [string]: ScrollingFrame } = {}

for _, bCfg in ipairs(BOARD_CONFIGS) do
	local boardPart = Instance.new("Part")
	boardPart.Name = "Board_" .. bCfg.Key
	boardPart.Size = Vector3.new(18, 16, 1.5)
	boardPart.CFrame = CFrame.new(bCfg.Pos) * CFrame.Angles(0, math.rad(180), 0)
	boardPart.Anchored = true
	boardPart.Color = Color3.fromRGB(15, 23, 42)
	boardPart.Material = Enum.Material.SmoothPlastic
	boardPart.Parent = LeaderboardFolder

	local sGui = Instance.new("SurfaceGui")
	sGui.Face = Enum.NormalId.Front
	sGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sGui.PixelsPerStud = 35
	sGui.Parent = boardPart

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundColor3 = bCfg.Color
	header.Font = Enum.Font.FredokaOne
	header.TextColor3 = Color3.fromRGB(15, 23, 42)
	header.TextScaled = true
	header.Text = bCfg.Title
	header.Parent = sGui

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -16, 1, -68)
	scroll.Position = UDim2.fromOffset(8, 62)
	scroll.BackgroundTransparency = 1
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = sGui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = scroll

	BoardScrollFrames[bCfg.Key] = scroll
end

local PodiumPositions = {
	[1] = Vector3.new(-32, 3.5, 42),
	[2] = Vector3.new(-38, 2.5, 42),
	[3] = Vector3.new(-26, 2.0, 42),
}

local PodiumParts: { [number]: Part } = {}
local StatueModels: { [number]: Model } = {}

for rank, pos in ipairs(PodiumPositions) do
	local ped = Instance.new("Part")
	ped.Name = "StatuePodium_Rank" .. tostring(rank)
	ped.Size = Vector3.new(5, pos.Y, 5)
	ped.Position = Vector3.new(pos.X, pos.Y / 2, pos.Z)
	ped.Anchored = true
	ped.Color = if rank == 1 then Color3.fromRGB(250, 204, 21) elseif rank == 2 then Color3.fromRGB(203, 213, 225) else Color3.fromRGB(217, 119, 6)
	ped.Material = Enum.Material.Metal
	ped.Parent = LeaderboardFolder
	PodiumParts[rank] = ped
end

local function BuildDancingStatue(rank: number, userId: number, playerName: string)
	if StatueModels[rank] then
		StatueModels[rank]:Destroy()
		StatueModels[rank] = nil
	end

	local ped = PodiumParts[rank]
	if not ped then return end

	local model = Instance.new("Model")
	model.Name = string.format("TopRebirther_Rank%d_%s", rank, playerName)

	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(userId)
	end)

	local char: Model? = nil
	if ok and desc then
		pcall(function()
			char = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		end)
	end

	if not char then
		char = Instance.new("Model")
		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Size = Vector3.new(2, 4, 1.5)
		hrp.Color = if rank == 1 then Color3.fromRGB(250, 204, 21) elseif rank == 2 then Color3.fromRGB(203, 213, 225) else Color3.fromRGB(217, 119, 6)
		hrp.Material = Enum.Material.Neon
		hrp.Anchored = true
		hrp.CanCollide = false
		hrp.Parent = char
		char.PrimaryPart = hrp
		local hum = Instance.new("Humanoid")
		hum.Parent = char
	end

	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
		end
	end

	local basePos = ped.Position + Vector3.new(0, ped.Size.Y / 2 + 3, 0)
	if char.PrimaryPart then
		char.PrimaryPart.CFrame = CFrame.new(basePos) * CFrame.Angles(0, math.rad(180), 0)
	else
		char:PivotTo(CFrame.new(basePos) * CFrame.Angles(0, math.rad(180), 0))
	end

	-- Overhead Label Gelar Juara
	local head = char:FindFirstChild("Head") or char.PrimaryPart
	if head then
		local bgui = Instance.new("BillboardGui")
		bgui.Size = UDim2.fromOffset(160, 48)
		bgui.StudsOffset = Vector3.new(0, 3, 0)
		bgui.AlwaysOnTop = false
		bgui.Parent = head

		local tag = Instance.new("TextLabel")
		tag.Size = UDim2.fromScale(1, 1)
		tag.BackgroundTransparency = 1
		tag.Font = Enum.Font.FredokaOne
		tag.TextColor3 = if rank == 1 then Color3.fromRGB(250, 204, 21) elseif rank == 2 then Color3.fromRGB(203, 213, 225) else Color3.fromRGB(217, 119, 6)
		tag.TextScaled = true
		tag.Text = string.format("#%d %s", rank, playerName)
		tag.Parent = bgui
	end

	char.Parent = LeaderboardFolder
	StatueModels[rank] = char

	-- Prosedural Dance Emote (Rotasi & Bobbing naik-turun berkala jika tanpa ID animasi eksternal)
	task.spawn(function()
		local t = 0
		while char.Parent do
			task.wait(0.04)
			t += 0.08
			local yOffset = math.sin(t * 3) * 0.4
			local tilt = math.sin(t * 2) * 0.15
			local cf = CFrame.new(basePos + Vector3.new(0, yOffset, 0))
				* CFrame.Angles(0, math.rad(180) + math.sin(t * 2) * 0.35, tilt)
			if char.PrimaryPart then
				char.PrimaryPart.CFrame = cf
			else
				char:PivotTo(cf)
			end
		end
	end)
end

local function RefreshAllGlobalLeaderboards()
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil
		if profile then
			pcall(function()
				ClicksODS:SetAsync(tostring(player.UserId), EncodeBigNumForODS(profile.Clicks))
				RebirthsODS:SetAsync(tostring(player.UserId), EncodeBigNumForODS(profile.Rebirths))
				GemsODS:SetAsync(tostring(player.UserId), EncodeBigNumForODS(profile.Gems))
			end)
		end
	end

	for _, bCfg in ipairs(BOARD_CONFIGS) do
		local ok, pages = pcall(function()
			return bCfg.ODS:GetSortedAsync(false, 25)
		end)
		if ok and pages then
			local entries = pages:GetCurrentPage()
			local scroll = BoardScrollFrames[bCfg.Key]
			for _, child in ipairs(scroll:GetChildren()) do
				if child:IsA("TextLabel") then
					child:Destroy()
				end
			end

			for rank, entry in ipairs(entries) do
				local uid = tonumber(entry.key) or 0
				local playerName = "Player_" .. tostring(uid)
				pcall(function()
					playerName = Players:GetNameFromUserIdAsync(uid)
				end)

				local row = Instance.new("TextLabel")
				row.Size = UDim2.new(1, 0, 0, 32)
				row.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
				row.Font = Enum.Font.FredokaOne
				row.TextColor3 = if rank == 1 then Color3.fromRGB(250, 204, 21) else Color3.fromRGB(248, 250, 252)
				row.TextScaled = true
				row.Text = string.format("#%d  %s  —  %s", rank, playerName, DecodeBigNumFromODS(entry.value))
				row.Parent = scroll

				-- Update Patung Top 3 Rebirths
				if bCfg.Key == "Rebirths" and rank <= 3 then
					task.spawn(BuildDancingStatue, rank, uid, playerName)
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		RefreshAllGlobalLeaderboards()
		task.wait(90)
	end
end)

DailySpinRemote.OnServerInvoke = function(player: Player)
	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil
	if not profile then
		return { Success = false, Message = "Profil belum dimuat." }
	end

	local now = os.time()
	local lastSpin = LastSpinTimestamp[player.UserId] or 0
	if (now - lastSpin) < 86400 then
		local remHours = math.ceil((86400 - (now - lastSpin)) / 3600)
		return {
			Success = false,
			Message = string.format("Daily Spin sudah dipakai hari ini! Kembali lagi dalam ~%d jam.", remHours),
		}
	end

	LastSpinTimestamp[player.UserId] = now

	local roll = math.random() * 100
	local cumulative = 0
	local chosenSlice: SpinSlice = DAILY_SPIN_SLICES[1]

	for _, slice in ipairs(DAILY_SPIN_SLICES) do
		cumulative += slice.ChancePercent
		if roll <= cumulative then
			chosenSlice = slice
			break
		end
	end

	if chosenSlice.RewardType == "Gems" then
		profile.Gems += chosenSlice.Amount
	elseif chosenSlice.RewardType == "Clicks" then
		profile.Clicks += chosenSlice.Amount
	elseif chosenSlice.RewardType == "AuraDices" then
		profile.AuraDiceCount = (profile.AuraDiceCount or 0) + chosenSlice.Amount
	elseif chosenSlice.RewardType == "TradeTokens" then
		profile.TradeTokens = (profile.TradeTokens or 0) + chosenSlice.Amount
	elseif chosenSlice.RewardType == "LuckPotion" then
		profile.ActivePotions["LuckPotion"] = math.max(profile.ActivePotions["LuckPotion"] or now, now) + chosenSlice.Amount
	elseif chosenSlice.RewardType == "ExclusivePet" then
		local uuid = game:GetService("HttpService"):GenerateGUID(false)
		profile.PetInventory[uuid] = {
			UUID = uuid,
			Name = "Daily Spin Dragon",
			EggId = "DailySpin",
			Rarity = "Supreme",
			BaseMultiplier = chosenSlice.Amount,
			Mutation = "Golden",
			IsShiny = true,
			Level = 1,
			Locked = true,
			Equipped = false,
		}
	end

	return {
		Success = true,
		SliceIndex = chosenSlice.Index,
		RewardLabel = chosenSlice.Label,
		Message = string.format("DAILY SPIN BERHASIL! Kamu mendapatkan %s!", chosenSlice.Label),
	}
end

RedeemCodeRemote.OnServerInvoke = function(player: Player, rawCode: string)
	if type(rawCode) ~= "string" then
		return { Success = false, Message = "Masukkan kode terlebih dahulu." }
	end

	local cleanCode = string.lower(string.gsub(rawCode, "%s+", ""))
	local codeReward = PROMO_CODES[cleanCode]
	if not codeReward then
		return { Success = false, Message = "Kode tidak ditemukan atau sudah kedaluwarsa!" }
	end

	RedeemedCodesByPlayer[player.UserId] = RedeemedCodesByPlayer[player.UserId] or {}
	if RedeemedCodesByPlayer[player.UserId][cleanCode] then
		return { Success = false, Message = "Kamu sudah pernah menukarkan kode ini!" }
	end

	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil
	if not profile then
		return { Success = false, Message = "Profil belum siap." }
	end

	RedeemedCodesByPlayer[player.UserId][cleanCode] = true
	profile.Gems += codeReward.Gems
	profile.AuraDiceCount = (profile.AuraDiceCount or 0) + codeReward.Dices

	return {
		Success = true,
		Message = string.format("KODE '%s' BERHASIL! Kamu mendapat %s!", cleanCode:upper(), codeReward.Desc),
	}
end

ClaimGroupChestRemote.OnServerInvoke = function(player: Player)
	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(player) else nil
	if not profile then
		return { Success = false, Message = "Profil belum siap." }
	end

	local now = os.time()
	local lastClaim = LastChestTimestamp[player.UserId] or 0
	if (now - lastClaim) < 14400 then
		return { Success = false, Message = "Group Chest sedang cooldown! Bisa dibuka setiap 4 jam." }
	end

	LastChestTimestamp[player.UserId] = now
	local bonusGems = math.max(5000, math.floor(profile.Rebirths * 25))
	profile.Gems += bonusGems

	return {
		Success = true,
		Message = string.format("GROUP CHEST TERBUKA! +%d Gems gratis!", bonusGems),
	}
end

print("[GlobalLeaderboardsAndDailySpin] Server system aktif")

--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClaimBoothRemote = Remotes:WaitForChild("ClaimBoothFunction") :: RemoteFunction
local ListPetOnBoothRemote = Remotes:WaitForChild("ListPetOnBoothFunction") :: RemoteFunction
local RemoveBoothListingRemote = Remotes:WaitForChild("RemoveBoothListingFunction") :: RemoteFunction
local BuyBoothItemRemote = Remotes:WaitForChild("BuyBoothItemFunction") :: RemoteFunction
local BoothStateSyncEvent = Remotes:WaitForChild("BoothStateSyncEvent") :: RemoteEvent
local GetInventoryRemote = Remotes:WaitForChild("GetInventoryFunction") :: RemoteFunction

local CachedBoothsState = {}

local function AddCornerAndStroke(parent: GuiObject, radius: number, strokeColor: Color3?, strokeThickness: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent

	if strokeColor then
		local stroke = Instance.new("UIStroke")
		stroke.Color = strokeColor
		stroke.Thickness = strokeThickness or 2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = parent
	end
end

local function AttachButtonBounce(button: GuiButton, onClick: () -> ())
	local defaultSize = button.Size
	button.MouseButton1Down:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.new(defaultSize.X.Scale * 0.93, defaultSize.X.Offset, defaultSize.Y.Scale * 0.93, defaultSize.Y.Offset) }
		):Play()
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = defaultSize }
		):Play()
	end)

	button.Activated:Connect(onClick)
end

-- ScreenGui Modal Marketplace Booths
local BoothGui = Instance.new("ScreenGui")
BoothGui.Name = "RebirthTradingPlazaUI"
BoothGui.ResetOnSpawn = false
BoothGui.Parent = PlayerGui

local MainModal = Instance.new("Frame")
MainModal.Name = "BoothModalFrame"
MainModal.Size = UDim2.fromOffset(660, 440)
MainModal.Position = UDim2.fromScale(0.5, 0.5)
MainModal.AnchorPoint = Vector2.new(0.5, 0.5)
MainModal.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
MainModal.Visible = false
MainModal.Parent = BoothGui
AddCornerAndStroke(MainModal, 18, Color3.fromRGB(245, 158, 11), 3)

local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, -80, 0, 48)
Header.Position = UDim2.fromOffset(20, 8)
Header.BackgroundTransparency = 1
Header.Font = Enum.Font.FredokaOne
Header.TextColor3 = Color3.fromRGB(250, 204, 21)
Header.TextSize = 22
Header.TextXAlignment = Enum.TextXAlignment.Left
Header.Text = "TRADING PLAZA & BOOTHS"
Header.Parent = MainModal

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(36, 36)
CloseBtn.Position = UDim2.new(1, -14, 0, 12)
CloseBtn.AnchorPoint = Vector2.new(1, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
CloseBtn.Font = Enum.Font.FredokaOne
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 18
CloseBtn.Text = "X"
CloseBtn.Parent = MainModal
AddCornerAndStroke(CloseBtn, 8, Color3.new(1, 1, 1), 1)

AttachButtonBounce(CloseBtn, function()
	MainModal.Visible = false
end)

-- Tab Switcher: "Daftar Stan (Market)" vs "Kelola Stan Saya"
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -40, 0, 40)
TabBar.Position = UDim2.fromOffset(20, 56)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainModal

local TabMarketBtn = Instance.new("TextButton")
TabMarketBtn.Size = UDim2.fromOffset(180, 36)
TabMarketBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
TabMarketBtn.Font = Enum.Font.FredokaOne
TabMarketBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
TabMarketBtn.TextSize = 15
TabMarketBtn.Text = "Katalog Pasar"
TabMarketBtn.Parent = TabBar
AddCornerAndStroke(TabMarketBtn, 8, Color3.new(1, 1, 1), 1.5)

local TabMyBoothBtn = Instance.new("TextButton")
TabMyBoothBtn.Size = UDim2.fromOffset(180, 36)
TabMyBoothBtn.Position = UDim2.fromOffset(190, 0)
TabMyBoothBtn.BackgroundColor3 = Color3.fromRGB(71, 85, 105)
TabMyBoothBtn.Font = Enum.Font.FredokaOne
TabMyBoothBtn.TextColor3 = Color3.fromRGB(248, 250, 252)
TabMyBoothBtn.TextSize = 15
TabMyBoothBtn.Text = "Kelola Stan Saya"
TabMyBoothBtn.Parent = TabBar
AddCornerAndStroke(TabMyBoothBtn, 8, Color3.new(1, 1, 1), 1.5)

local MarketScroll = Instance.new("ScrollingFrame")
MarketScroll.Size = UDim2.new(1, -40, 1, -110)
MarketScroll.Position = UDim2.fromOffset(20, 100)
MarketScroll.BackgroundTransparency = 1
MarketScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MarketScroll.ScrollBarThickness = 6
MarketScroll.Parent = MainModal

local MarketGrid = Instance.new("UIGridLayout")
MarketGrid.CellSize = UDim2.fromOffset(190, 100)
MarketGrid.CellPadding = UDim2.fromOffset(10, 10)
MarketGrid.Parent = MarketScroll

local MyBoothFrame = Instance.new("Frame")
MyBoothFrame.Size = UDim2.new(1, -40, 1, -110)
MyBoothFrame.Position = UDim2.fromOffset(20, 100)
MyBoothFrame.BackgroundTransparency = 1
MyBoothFrame.Visible = false
MyBoothFrame.Parent = MainModal

-- Frame Kontrol Stan Saya
local ClaimBtn = Instance.new("TextButton")
ClaimBtn.Size = UDim2.fromOffset(200, 40)
ClaimBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
ClaimBtn.Font = Enum.Font.FredokaOne
ClaimBtn.TextColor3 = Color3.new(1, 1, 1)
ClaimBtn.TextSize = 15
ClaimBtn.Text = "Klaim Stan Otomatis"
ClaimBtn.Parent = MyBoothFrame
AddCornerAndStroke(ClaimBtn, 8, Color3.new(1, 1, 1), 1.5)

local SellFrame = Instance.new("Frame")
SellFrame.Size = UDim2.new(1, 0, 0, 60)
SellFrame.Position = UDim2.fromOffset(0, 50)
SellFrame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
SellFrame.Parent = MyBoothFrame
AddCornerAndStroke(SellFrame, 10, Color3.fromRGB(148, 163, 184), 1)

local PriceInput = Instance.new("TextBox")
PriceInput.Size = UDim2.fromOffset(180, 40)
PriceInput.Position = UDim2.fromOffset(10, 10)
PriceInput.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
PriceInput.Font = Enum.Font.FredokaOne
PriceInput.TextColor3 = Color3.fromRGB(250, 204, 21)
PriceInput.PlaceholderColor3 = Color3.fromRGB(148, 163, 184)
PriceInput.PlaceholderText = "Harga Trade Tokens..."
PriceInput.TextSize = 14
PriceInput.Parent = SellFrame
AddCornerAndStroke(PriceInput, 8, Color3.new(1, 1, 1), 1)

local PostItemBtn = Instance.new("TextButton")
PostItemBtn.Size = UDim2.fromOffset(180, 40)
PostItemBtn.Position = UDim2.fromOffset(200, 10)
PostItemBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
PostItemBtn.Font = Enum.Font.FredokaOne
PostItemBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
PostItemBtn.TextSize = 14
PostItemBtn.Text = "Pajang Pet Pertama"
PostItemBtn.Parent = SellFrame
AddCornerAndStroke(PostItemBtn, 8, Color3.new(1, 1, 1), 1.5)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.fromOffset(0, 120)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextColor3 = Color3.fromRGB(254, 240, 138)
StatusLabel.TextSize = 15
StatusLabel.Text = "Klaim stan untuk mulai berjualan Pet."
StatusLabel.Parent = MyBoothFrame

-- Switcher Tab Logic
AttachButtonBounce(TabMarketBtn, function()
	TabMarketBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
	TabMarketBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
	TabMyBoothBtn.BackgroundColor3 = Color3.fromRGB(71, 85, 105)
	TabMyBoothBtn.TextColor3 = Color3.fromRGB(248, 250, 252)
	MarketScroll.Visible = true
	MyBoothFrame.Visible = false
end)

AttachButtonBounce(TabMyBoothBtn, function()
	TabMyBoothBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
	TabMyBoothBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
	TabMarketBtn.BackgroundColor3 = Color3.fromRGB(71, 85, 105)
	TabMarketBtn.TextColor3 = Color3.fromRGB(248, 250, 252)
	MarketScroll.Visible = false
	MyBoothFrame.Visible = true
end)

local function RenderMarketListings()
	for _, child in ipairs(MarketScroll:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	local count = 0
	for bIdx, booth in pairs(CachedBoothsState) do
		if booth.Listings then
			for lId, item in pairs(booth.Listings) do
				count += 1
				local card = Instance.new("Frame")
				card.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
				card.Parent = MarketScroll
				AddCornerAndStroke(card, 10, Color3.fromRGB(245, 158, 11), 1.5)

				local title = Instance.new("TextLabel")
				title.Size = UDim2.new(1, -10, 0, 24)
				title.Position = UDim2.fromOffset(6, 6)
				title.BackgroundTransparency = 1
				title.Font = Enum.Font.FredokaOne
				title.TextColor3 = Color3.fromRGB(248, 250, 252)
				title.TextSize = 13
				title.TextXAlignment = Enum.TextXAlignment.Left
				title.Text = (if item.PetSnapshot.IsShiny then "✨ " else "") .. item.PetSnapshot.Name
				title.Parent = card

				local seller = Instance.new("TextLabel")
				seller.Size = UDim2.new(1, -10, 0, 18)
				seller.Position = UDim2.fromOffset(6, 30)
				seller.BackgroundTransparency = 1
				seller.Font = Enum.Font.SourceSansBold
				seller.TextColor3 = Color3.fromRGB(148, 163, 184)
				seller.TextSize = 12
				seller.TextXAlignment = Enum.TextXAlignment.Left
				seller.Text = "Oleh: " .. item.SellerName
				seller.Parent = card

				local buyBtn = Instance.new("TextButton")
				buyBtn.Size = UDim2.new(1, -12, 0, 30)
				buyBtn.Position = UDim2.new(0, 6, 1, -8)
				buyBtn.AnchorPoint = Vector2.new(0, 1)
				buyBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
				buyBtn.Font = Enum.Font.FredokaOne
				buyBtn.TextColor3 = Color3.new(1, 1, 1)
				buyBtn.TextSize = 13
				buyBtn.Text = string.format("Beli: %d Tokens", item.PriceTokens)
				buyBtn.Parent = card
				AddCornerAndStroke(buyBtn, 6, Color3.new(1, 1, 1), 1)

				AttachButtonBounce(buyBtn, function()
					local res = BuyBoothItemRemote:InvokeServer(bIdx, lId)
					if res then
						StatusLabel.Text = res.Message
					end
				end)
			end
		end
	end

	if count == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 40)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.FredokaOne
		empty.TextColor3 = Color3.fromRGB(148, 163, 184)
		empty.TextSize = 15
		empty.Text = "Belum ada item yang dipajang di pasar."
		empty.Parent = MarketScroll
	end
end

BoothStateSyncEvent.OnClientEvent:Connect(function(updatedBooths)
	CachedBoothsState = updatedBooths
	RenderMarketListings()
end)

AttachButtonBounce(ClaimBtn, function()
	for i = 1, 12 do
		local res = ClaimBoothRemote:InvokeServer(i, LocalPlayer.Name .. "'s Shop")
		if res and res.Success then
			StatusLabel.Text = res.Message
			break
		end
	end
end)

AttachButtonBounce(PostItemBtn, function()
	local price = tonumber(PriceInput.Text)
	if not price or price <= 0 then
		StatusLabel.Text = "Masukkan harga token yang valid!"
		return
	end

	local inv = GetInventoryRemote:InvokeServer()
	local firstUUID = nil
	if type(inv) == "table" then
		for uuid, pet in pairs(inv) do
			if not pet.Locked then
				firstUUID = uuid
				break
			end
		end
	end

	if not firstUUID then
		StatusLabel.Text = "Tidak ada pet yang tidak dikunci untuk dijual!"
		return
	end

	local res = ListPetOnBoothRemote:InvokeServer(firstUUID, price)
	if res then
		StatusLabel.Text = res.Message
	end
end)

local TradingClientAPI = {}

function TradingClientAPI.OpenUI()
	MainModal.Visible = true
	RenderMarketListings()
end

function TradingClientAPI.ClaimBooth(boothIndex: number, signText: string?)
	return ClaimBoothRemote:InvokeServer(boothIndex, signText)
end

function TradingClientAPI.PutPetForSale(petUUID: string, priceTokens: number)
	return ListPetOnBoothRemote:InvokeServer(petUUID, priceTokens)
end

function TradingClientAPI.BuyFromBooth(boothIndex: number, listingId: string)
	return BuyBoothItemRemote:InvokeServer(boothIndex, listingId)
end

function TradingClientAPI.GetAllBooths()
	return CachedBoothsState
end

_G.RebirthTradingController = TradingClientAPI
return TradingClientAPI

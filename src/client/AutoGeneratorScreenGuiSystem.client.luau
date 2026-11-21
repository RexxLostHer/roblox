--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.RebirthChampionsConfig)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClickRemote = Remotes:WaitForChild("ClickTapEvent") :: RemoteEvent
local RebirthRemote = Remotes:WaitForChild("PerformRebirthFunction") :: RemoteFunction
local UpgradeRemote = Remotes:WaitForChild("BuyUpgradeFunction") :: RemoteFunction
local TeleportWorldRemote = Remotes:WaitForChild("TeleportWorldFunction") :: RemoteFunction
local EquipPetRemote = Remotes:WaitForChild("EquipPetFunction") :: RemoteFunction
local EquipBestRemote = Remotes:WaitForChild("EquipBestFunction") :: RemoteFunction
local DeletePetRemote = Remotes:WaitForChild("DeletePetFunction") :: RemoteFunction
local ToggleLockPetRemote = Remotes:WaitForChild("ToggleLockPetFunction") :: RemoteFunction
local BuyPotionRemote = Remotes:WaitForChild("BuyPotionFunction") :: RemoteFunction
local DailySpinRemote = Remotes:WaitForChild("SpinDailyWheelFunction") :: RemoteFunction
local RedeemCodeRemote = Remotes:WaitForChild("RedeemPromoCodeFunction") :: RemoteFunction
local RollAuraRemote = Remotes:WaitForChild("RollAuraFunction") :: RemoteFunction
local SyncDiceTimerEvent = Remotes:WaitForChild("SyncDiceTimerEvent") :: RemoteEvent
local OpenModalEvent = Remotes:WaitForChild("OpenModalClientEvent") :: RemoteEvent
local GetInventoryRemote = Remotes:WaitForChild("GetInventoryFunction") :: RemoteFunction
local SyncInventoryEvent = Remotes:WaitForChild("SyncInventoryEvent") :: RemoteEvent
local GetPetIndexRemote = Remotes:WaitForChild("GetPetIndexFunction") :: RemoteFunction
local SyncPetIndexEvent = Remotes:WaitForChild("SyncPetIndexEvent") :: RemoteEvent
local SyncActivePotionsEvent = Remotes:WaitForChild("SyncActivePotionsEvent") :: RemoteEvent

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

local MainGui = Instance.new("ScreenGui")
MainGui.Name = "RebirthChampionsMainHUD"
MainGui.IgnoreGuiInset = false
MainGui.ResetOnSpawn = false
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.Parent = PlayerGui

local ToastLabel = Instance.new("TextLabel")
ToastLabel.Name = "ToastBanner"
ToastLabel.Size = UDim2.fromOffset(500, 44)
ToastLabel.Position = UDim2.new(0.5, 0, 0, 16)
ToastLabel.AnchorPoint = Vector2.new(0.5, 0)
ToastLabel.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
ToastLabel.BackgroundTransparency = 0.1
ToastLabel.Font = Enum.Font.FredokaOne
ToastLabel.TextColor3 = Color3.fromRGB(250, 204, 21)
ToastLabel.TextSize = 18
ToastLabel.Text = "Selamat datang di Rebirth Champions Simulator!"
ToastLabel.Visible = false
ToastLabel.Parent = MainGui
AddCornerAndStroke(ToastLabel, 12, Color3.fromRGB(56, 189, 248), 2)

local function ShowToast(msg: string, isError: boolean?)
	ToastLabel.Text = msg
	ToastLabel.TextColor3 = if isError then Color3.fromRGB(248, 113, 113) else Color3.fromRGB(250, 204, 21)
	ToastLabel.Visible = true
	task.delay(2.8, function()
		if ToastLabel.Text == msg then
			ToastLabel.Visible = false
		end
	end)
end

-- CURRENCY CONTAINER (KIRI ATAS)
local CurrencyContainer = Instance.new("Frame")
CurrencyContainer.Name = "CurrencyContainer"
CurrencyContainer.Size = UDim2.fromOffset(230, 195)
CurrencyContainer.Position = UDim2.fromOffset(18, 18)
CurrencyContainer.BackgroundTransparency = 1
CurrencyContainer.Parent = MainGui

local CurrencyLayout = Instance.new("UIListLayout")
CurrencyLayout.Padding = UDim.new(0, 6)
CurrencyLayout.Parent = CurrencyContainer

local function CreateCurrencyBar(name: string, icon: string, accentColor: Color3): TextLabel
	local bar = Instance.new("Frame")
	bar.Name = name .. "Bar"
	bar.Size = UDim2.fromOffset(220, 38)
	bar.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
	bar.Parent = CurrencyContainer
	AddCornerAndStroke(bar, 10, accentColor, 2)

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(1, -20, 1, 0)
	valLabel.Position = UDim2.fromOffset(12, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.Font = Enum.Font.FredokaOne
	valLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
	valLabel.TextSize = 16
	valLabel.TextXAlignment = Enum.TextXAlignment.Left
	valLabel.Text = string.format("%s %s: 0", icon, name)
	valLabel.Parent = bar
	return valLabel
end

local ClicksHudLabel = CreateCurrencyBar("Clicks", "CLICKS", Color3.fromRGB(56, 189, 248))
local RebirthsHudLabel = CreateCurrencyBar("Rebirths", "REBIRTHS", Color3.fromRGB(250, 204, 21))
local GemsHudLabel = CreateCurrencyBar("Gems", "GEMS", Color3.fromRGB(168, 85, 247))
local DiceTimerLabel = CreateCurrencyBar("Aura Dice", "DICE", Color3.fromRGB(52, 211, 153))

SyncDiceTimerEvent.OnClientEvent:Connect(function(secondsRemaining)
	DiceTimerLabel.Text = string.format("Free Dice: %ds", secondsRemaining)
end)

task.spawn(function()
	local ls = LocalPlayer:WaitForChild("leaderstats", 15)
	if not ls then return end
	local cVal = ls:WaitForChild("Clicks", 10) :: StringValue?
	local rVal = ls:WaitForChild("Rebirths", 10) :: StringValue?
	local gVal = ls:WaitForChild("Gems", 10) :: StringValue?

	local function RefreshHUD()
		if cVal then ClicksHudLabel.Text = "Clicks: " .. cVal.Value end
		if rVal then RebirthsHudLabel.Text = "Rebirths: " .. rVal.Value end
		if gVal then GemsHudLabel.Text = "Gems: " .. gVal.Value end
	end
	if cVal then cVal.Changed:Connect(RefreshHUD) end
	if rVal then rVal.Changed:Connect(RefreshHUD) end
	if gVal then gVal.Changed:Connect(RefreshHUD) end
	RefreshHUD()
end)

-- POTIONS HUD CONTAINER (POJOK KANAN ATAS)
local PotionsHudContainer = Instance.new("Frame")
PotionsHudContainer.Name = "PotionsHudContainer"
PotionsHudContainer.Size = UDim2.fromOffset(200, 160)
PotionsHudContainer.Position = UDim2.new(1, -218, 0, 18)
PotionsHudContainer.BackgroundTransparency = 1
PotionsHudContainer.Parent = MainGui

local PotionsHudLayout = Instance.new("UIListLayout")
PotionsHudLayout.Padding = UDim.new(0, 4)
PotionsHudLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
PotionsHudLayout.Parent = PotionsHudContainer

local ActivePotionLabels: { [string]: TextLabel } = {}
local CachedActivePotions: { [string]: number } = {}

SyncActivePotionsEvent.OnClientEvent:Connect(function(potionsTable)
	if type(potionsTable) == "table" then
		CachedActivePotions = potionsTable
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		local now = os.time()
		for potKey, expireTick in pairs(CachedActivePotions) do
			local remSeconds = expireTick - now
			if remSeconds > 0 then
				if not ActivePotionLabels[potKey] then
					local pill = Instance.new("TextLabel")
					pill.Size = UDim2.fromOffset(190, 26)
					pill.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
					pill.Font = Enum.Font.FredokaOne
					pill.TextColor3 = Color3.fromRGB(192, 132, 252)
					pill.TextSize = 13
					pill.Parent = PotionsHudContainer
					AddCornerAndStroke(pill, 6, Color3.fromRGB(168, 85, 247), 1)
					ActivePotionLabels[potKey] = pill
				end
				local m = math.floor(remSeconds / 60)
				local s = remSeconds % 60
				ActivePotionLabels[potKey].Text = string.format("%s: %02d:%02d", potKey, m, s)
			else
				if ActivePotionLabels[potKey] then
					ActivePotionLabels[potKey]:Destroy()
					ActivePotionLabels[potKey] = nil
				end
			end
		end
	end
end)

-- BOTTOM ACTION BAR (TENGAH BAWAH)
local BottomActionFrame = Instance.new("Frame")
BottomActionFrame.Name = "BottomActionFrame"
BottomActionFrame.Size = UDim2.fromOffset(420, 84)
BottomActionFrame.Position = UDim2.new(0.5, 0, 1, -22)
BottomActionFrame.AnchorPoint = Vector2.new(0.5, 1)
BottomActionFrame.BackgroundTransparency = 1
BottomActionFrame.Parent = MainGui

local TapButton = Instance.new("TextButton")
TapButton.Name = "TapSkinButton"
TapButton.Size = UDim2.fromOffset(180, 68)
TapButton.Position = UDim2.fromScale(0.5, 0.5)
TapButton.AnchorPoint = Vector2.new(0.5, 0.5)
TapButton.BackgroundColor3 = Color3.fromRGB(14, 165, 233)
TapButton.Font = Enum.Font.FredokaOne
TapButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TapButton.TextSize = 24
TapButton.Text = "TAP"
TapButton.Parent = BottomActionFrame
AddCornerAndStroke(TapButton, 18, Color3.fromRGB(255, 255, 255), 3)

AttachButtonBounce(TapButton, function()
	if _G.SoundFX then _G.SoundFX.Play("Click") end
	ClickRemote:FireServer()
end)

local IsAutoClicking = false
local AutoClickBtn = Instance.new("TextButton")
AutoClickBtn.Name = "AutoClickToggle"
AutoClickBtn.Size = UDim2.fromOffset(105, 52)
AutoClickBtn.Position = UDim2.new(0, 0, 0.5, 0)
AutoClickBtn.AnchorPoint = Vector2.new(0, 0.5)
AutoClickBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
AutoClickBtn.Font = Enum.Font.FredokaOne
AutoClickBtn.TextColor3 = Color3.new(1, 1, 1)
AutoClickBtn.TextSize = 15
AutoClickBtn.Text = "Auto Click: OFF"
AutoClickBtn.Parent = BottomActionFrame
AddCornerAndStroke(AutoClickBtn, 12, Color3.fromRGB(255, 255, 255), 2)

AttachButtonBounce(AutoClickBtn, function()
	local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(LocalPlayer) else nil
	local hasFastPass = profile and profile.OwnedGamepasses and profile.OwnedGamepasses["FastAutoClicker"]
	local hasFreeUpgrade = profile and profile.Upgrades and (profile.Upgrades.FreeAutoclicker or 0) >= 1

	if not hasFastPass and not hasFreeUpgrade then
		ShowToast("Beli upgrade Free Autoclicker (25K Gems) di Upgrades Shop atau Fast Autoclicker Pass!", true)
		return
	end

	IsAutoClicking = not IsAutoClicking
	AutoClickBtn.Text = if IsAutoClicking then "Auto Click: ON" else "Auto Click: OFF"
	AutoClickBtn.BackgroundColor3 = if IsAutoClicking then Color3.fromRGB(22, 163, 74) else Color3.fromRGB(220, 38, 38)
end)

task.spawn(function()
	while true do
		local tickRate = 0.1
		local profile = if _G.GetPlayerProfile then _G.GetPlayerProfile(LocalPlayer) else nil
		if profile and profile.OwnedGamepasses and profile.OwnedGamepasses["FastAutoClicker"] then
			tickRate = 0.04
		end
		task.wait(tickRate)
		if IsAutoClicking then
			ClickRemote:FireServer()
		end
	end
end)

local IsAutoRebirthing = false
local SelectedAutoRebirthAmount = 1
local AutoRebirthBtn = Instance.new("TextButton")
AutoRebirthBtn.Name = "AutoRebirthToggle"
AutoRebirthBtn.Size = UDim2.fromOffset(105, 52)
AutoRebirthBtn.Position = UDim2.new(1, 0, 0.5, 0)
AutoRebirthBtn.AnchorPoint = Vector2.new(1, 0.5)
AutoRebirthBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
AutoRebirthBtn.Font = Enum.Font.FredokaOne
AutoRebirthBtn.TextColor3 = Color3.new(1, 1, 1)
AutoRebirthBtn.TextSize = 14
AutoRebirthBtn.Text = "Auto Reb: OFF"
AutoRebirthBtn.Parent = BottomActionFrame
AddCornerAndStroke(AutoRebirthBtn, 12, Color3.fromRGB(255, 255, 255), 2)

AttachButtonBounce(AutoRebirthBtn, function()
	IsAutoRebirthing = not IsAutoRebirthing
	AutoRebirthBtn.Text = if IsAutoRebirthing then "Auto Reb: ON" else "Auto Reb: OFF"
	AutoRebirthBtn.BackgroundColor3 = if IsAutoRebirthing then Color3.fromRGB(22, 163, 74) else Color3.fromRGB(220, 38, 38)
end)

task.spawn(function()
	while true do
		task.wait(0.8)
		if IsAutoRebirthing then
			RebirthRemote:InvokeServer(SelectedAutoRebirthAmount)
		end
	end
end)

-- MODAL WINDOW MANAGER
local ActiveModalFrames: { [string]: Frame } = {}

local function CreateModalWindow(key: string, titleText: string, accentColor: Color3): (Frame, ScrollingFrame)
	local modal = Instance.new("Frame")
	modal.Name = key .. "Modal"
	modal.Size = UDim2.fromOffset(640, 420)
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	modal.Visible = false
	modal.Parent = MainGui
	AddCornerAndStroke(modal, 18, accentColor, 3)

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -80, 0, 48)
	header.Position = UDim2.fromOffset(22, 6)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.FredokaOne
	header.TextColor3 = accentColor
	header.TextSize = 22
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = titleText
	header.Parent = modal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(38, 38)
	closeBtn.Position = UDim2.new(1, -14, 0, 12)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextSize = 20
	closeBtn.Text = "X"
	closeBtn.Parent = modal
	AddCornerAndStroke(closeBtn, 10, Color3.new(1, 1, 1), 1.5)
	AttachButtonBounce(closeBtn, function()
		modal.Visible = false
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "ContentScroll"
	scroll.Size = UDim2.new(1, -32, 1, -74)
	scroll.Position = UDim2.fromOffset(16, 58)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = modal

	ActiveModalFrames[key] = modal
	return modal, scroll
end

local function ToggleModal(targetKey: string)
	for key, frame in pairs(ActiveModalFrames) do
		if key == targetKey then
			frame.Visible = not frame.Visible
		else
			frame.Visible = false
		end
	end
end

OpenModalEvent.OnClientEvent:Connect(function(targetModal)
	if targetModal == "AuraRoll" then
		local res = RollAuraRemote:InvokeServer()
		if res then ShowToast(res.Message, not res.Success) end
	elseif string.find(targetModal, "CraftMachine_") then
		local tier = string.gsub(targetModal, "CraftMachine_", "")
		if _G.RebirthCraftingController then
			_G.RebirthCraftingController.OpenMachineUI(tier)
		end
		ToggleModal("Pets")
		ShowToast("Mesin Crafting " .. tier .. " dibuka di menu Pets!")
	elseif string.find(targetModal, "EggHatch_") then
		local eggId = string.gsub(targetModal, "EggHatch_", "")
		if _G.RebirthEggAndAuraController then
			_G.RebirthEggAndAuraController.HatchOnce(eggId, 1)
			ShowToast("Membuka " .. eggId .. "!")
		end
	else
		ToggleModal(targetModal)
	end
end)

-- SIDEBAR (KIRI TENGAH)
local Sidebar = Instance.new("Frame")
Sidebar.Name = "LeftSidebar"
Sidebar.Size = UDim2.fromOffset(145, 380)
Sidebar.Position = UDim2.new(0, 18, 0.5, 30)
Sidebar.AnchorPoint = Vector2.new(0, 0.5)
Sidebar.BackgroundTransparency = 1
Sidebar.Parent = MainGui

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 8)
SidebarLayout.Parent = Sidebar

local SIDEBAR_BUTTONS = {
	{ Key = "Rebirth", Label = "Rebirths", Color = Color3.fromRGB(245, 158, 11) },
	{ Key = "Pets", Label = "Pets", Color = Color3.fromRGB(16, 185, 129) },
	{ Key = "Index", Label = "Pet Index", Color = Color3.fromRGB(16, 185, 129) },
	{ Key = "Streak", Label = "Daily Streak", Color = Color3.fromRGB(250, 204, 21) },
	{ Key = "Quests", Label = "Quests", Color = Color3.fromRGB(56, 189, 248) },
	{ Key = "Gifts", Label = "Gifts", Color = Color3.fromRGB(244, 114, 182) },
	{ Key = "Upgrades", Label = "Upgrades", Color = Color3.fromRGB(139, 92, 246) },
	{ Key = "Potions", Label = "Potions", Color = Color3.fromRGB(168, 85, 247) },
	{ Key = "GamepassShop", Label = "Robux Shop", Color = Color3.fromRGB(236, 72, 153) },
	{ Key = "Worlds", Label = "Teleport", Color = Color3.fromRGB(14, 165, 233) },
	{ Key = "Trading", Label = "Trading", Color = Color3.fromRGB(245, 158, 11) },
	{ Key = "DailySpin", Label = "Daily Spin", Color = Color3.fromRGB(234, 179, 8) },
	{ Key = "Codes", Label = "Codes", Color = Color3.fromRGB(59, 130, 246) },
	{ Key = "Settings", Label = "Settings", Color = Color3.fromRGB(100, 116, 139) },
}

for _, btnInfo in ipairs(SIDEBAR_BUTTONS) do
	local btn = Instance.new("TextButton")
	btn.Name = btnInfo.Key .. "NavBtn"
	btn.Size = UDim2.fromOffset(142, 36)
	btn.BackgroundColor3 = btnInfo.Color
	btn.Font = Enum.Font.FredokaOne
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 14
	btn.Text = btnInfo.Label
	btn.Parent = Sidebar
	AddCornerAndStroke(btn, 10, Color3.new(1, 1, 1), 1.5)
	AttachButtonBounce(btn, function()
		if btnInfo.Key == "Trading" then
			if _G.RebirthTradingController then
				_G.RebirthTradingController.OpenUI()
			end
		else
			ToggleModal(btnInfo.Key)
		end
	end)
end

-- 1. MODAL REBIRTH
local _, RebirthScroll = CreateModalWindow("Rebirth", "REBIRTH MENU", Color3.fromRGB(250, 204, 21))
local RebirthGrid = Instance.new("UIGridLayout")
RebirthGrid.CellSize = UDim2.fromOffset(180, 56)
RebirthGrid.CellPadding = UDim2.fromOffset(10, 10)
RebirthGrid.Parent = RebirthScroll

local REBIRTH_AMOUNTS = { 1, 5, 10, 25, 50, 100, 200, 500, 1000, 2500, 5000, 10000, 25000, 100000, 1e6, 10e6, 100e6, 1e9, 1e12, 1e15, 1e18 }
for _, amount in ipairs(REBIRTH_AMOUNTS) do
	local card = Instance.new("TextButton")
	card.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	card.Font = Enum.Font.FredokaOne
	card.TextColor3 = Color3.fromRGB(254, 240, 138)
	card.TextSize = 17
	card.Text = string.format("+%s Rebirths", tostring(amount))
	card.Parent = RebirthScroll
	AddCornerAndStroke(card, 10, Color3.fromRGB(250, 204, 21), 1.5)

	AttachButtonBounce(card, function()
		SelectedAutoRebirthAmount = amount
		local res = RebirthRemote:InvokeServer(amount)
		if res then
			ShowToast(res.Message, not res.Success)
			if res.Success and _G.SoundFX then _G.SoundFX.Play("Rebirth") end
		end
	end)
end

-- 2. MODAL PETS INVENTORY + EQUIP BEST
local _, PetsScroll = CreateModalWindow("Pets", "PETS INVENTORY & CRAFTING", Color3.fromRGB(52, 211, 153))

local PetActionBar = Instance.new("Frame")
PetActionBar.Size = UDim2.new(1, -10, 0, 46)
PetActionBar.BackgroundTransparency = 1
PetActionBar.Parent = PetsScroll

local PetActionLayout = Instance.new("UIListLayout")
PetActionLayout.FillDirection = Enum.FillDirection.Horizontal
PetActionLayout.Padding = UDim.new(0, 10)
PetActionLayout.Parent = PetActionBar

local EquipBestBtn = Instance.new("TextButton")
EquipBestBtn.Size = UDim2.fromOffset(160, 42)
EquipBestBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
EquipBestBtn.Font = Enum.Font.FredokaOne
EquipBestBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
EquipBestBtn.TextSize = 16
EquipBestBtn.Text = "EQUIP BEST"
EquipBestBtn.Parent = PetActionBar
AddCornerAndStroke(EquipBestBtn, 10, Color3.new(1, 1, 1), 2)

AttachButtonBounce(EquipBestBtn, function()
	local res = EquipBestRemote:InvokeServer()
	if res then ShowToast(res.Message, not res.Success) end
end)

local SearchFilterBox = Instance.new("TextBox")
SearchFilterBox.Size = UDim2.fromOffset(200, 42)
SearchFilterBox.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
SearchFilterBox.Font = Enum.Font.FredokaOne
SearchFilterBox.TextColor3 = Color3.new(1, 1, 1)
SearchFilterBox.PlaceholderColor3 = Color3.fromRGB(148, 163, 184)
SearchFilterBox.PlaceholderText = "Cari nama pet..."
SearchFilterBox.TextSize = 14
SearchFilterBox.Parent = PetActionBar
AddCornerAndStroke(SearchFilterBox, 8, Color3.fromRGB(52, 211, 153), 1)

local MultiDeleteMode = false
local SelectedForDelete: { [string]: boolean } = {}

local MultiDeleteToggleBtn = Instance.new("TextButton")
MultiDeleteToggleBtn.Size = UDim2.fromOffset(130, 42)
MultiDeleteToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
MultiDeleteToggleBtn.Font = Enum.Font.FredokaOne
MultiDeleteToggleBtn.TextColor3 = Color3.new(1, 1, 1)
MultiDeleteToggleBtn.TextSize = 14
MultiDeleteToggleBtn.Text = "Multi-Delete: OFF"
MultiDeleteToggleBtn.Parent = PetActionBar
AddCornerAndStroke(MultiDeleteToggleBtn, 8, Color3.new(1, 1, 1), 1)

local DeleteConfirmBtn = Instance.new("TextButton")
DeleteConfirmBtn.Size = UDim2.fromOffset(110, 42)
DeleteConfirmBtn.BackgroundColor3 = Color3.fromRGB(185, 28, 28)
DeleteConfirmBtn.Font = Enum.Font.FredokaOne
DeleteConfirmBtn.TextColor3 = Color3.new(1, 1, 1)
DeleteConfirmBtn.TextSize = 14
DeleteConfirmBtn.Text = "Hapus Terpilih"
DeleteConfirmBtn.Visible = false
DeleteConfirmBtn.Parent = PetActionBar
AddCornerAndStroke(DeleteConfirmBtn, 8, Color3.new(1, 1, 1), 1)

local CraftBarLayout = Instance.new("UIListLayout")
CraftBarLayout.FillDirection = Enum.FillDirection.Horizontal
CraftBarLayout.Padding = UDim.new(0, 8)
CraftBarLayout.Parent = CraftShortcutBar

local CRAFT_MACHINES = {
	{ Tier = "Golden", Color = Color3.fromRGB(234, 179, 8) },
	{ Tier = "Toxic", Color = Color3.fromRGB(34, 197, 94) },
	{ Tier = "Galaxy", Color = Color3.fromRGB(168, 85, 247) },
	{ Tier = "Rainbow", Color = Color3.fromRGB(244, 63, 94) },
}

for _, m in ipairs(CRAFT_MACHINES) do
	local mBtn = Instance.new("TextButton")
	mBtn.Size = UDim2.fromOffset(136, 38)
	mBtn.BackgroundColor3 = m.Color
	mBtn.Font = Enum.Font.FredokaOne
	mBtn.TextColor3 = Color3.new(1, 1, 1)
	mBtn.TextSize = 14
	mBtn.Text = "Craft " .. m.Tier
	mBtn.Parent = CraftShortcutBar
	AddCornerAndStroke(mBtn, 8, Color3.new(1, 1, 1), 1.5)

	AttachButtonBounce(mBtn, function()
		if _G.RebirthCraftingController then
			_G.RebirthCraftingController.OpenMachineUI(m.Tier)
			ShowToast("Pilih 1-5 Pet " .. m.Tier .. " lalu tekan Submit Craft!")
		end
	end)
end

-- Pet Inventory Grid Container
local PetGridFrame = Instance.new("Frame")
PetGridFrame.Name = "PetGridFrame"
PetGridFrame.Size = UDim2.new(1, -10, 0, 0)
PetGridFrame.AutomaticSize = Enum.AutomaticSize.Y
PetGridFrame.BackgroundTransparency = 1
PetGridFrame.Parent = PetsScroll

local PetGridLayout = Instance.new("UIGridLayout")
PetGridLayout.CellSize = UDim2.fromOffset(138, 148)
PetGridLayout.CellPadding = UDim2.fromOffset(8, 8)
PetGridLayout.Parent = PetGridFrame

local function RenderPetInventory(inventory)
	for _, child in ipairs(PetGridFrame:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	if not inventory or next(inventory) == nil then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 60)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Font = Enum.Font.FredokaOne
		emptyLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
		emptyLabel.TextSize = 16
		emptyLabel.Text = "Kamu belum memiliki Pet. Buka Egg di Spawn!"
		emptyLabel.Parent = PetGridFrame
		return
	end

	local currentFilter = string.lower(string.gsub(SearchFilterBox.Text, "%s+", ""))
	local sortedPets = {}
	for uuid, pet in pairs(inventory) do
		local match = true
		if currentFilter ~= "" then
			match = string.find(string.lower(pet.Name), currentFilter) ~= nil
		end
		if match then
			table.insert(sortedPets, { UUID = uuid, Pet = pet })
		end
	end

	table.sort(sortedPets, function(a, b)
		local aVal = (a.Pet.BaseMultiplier or a.Pet.Stat or 1) * (a.Pet.Level or 1)
		local bVal = (b.Pet.BaseMultiplier or b.Pet.Stat or 1) * (b.Pet.Level or 1)
		return aVal > bVal
	end)

	for _, item in ipairs(sortedPets) do
		local uuid = item.UUID
		local pet = item.Pet
		local card = Instance.new("Frame")
		card.Name = "Pet_" .. uuid
		card.BackgroundColor3 = if SelectedForDelete[uuid] then Color3.fromRGB(80, 20, 20) elseif pet.Equipped then Color3.fromRGB(16, 55, 38) else Color3.fromRGB(30, 41, 59)
		card.Parent = PetGridFrame

		local mutColor = Color3.fromRGB(255, 255, 255)
		local tierData = Config.MutationTiers and Config.MutationTiers.Tiers and Config.MutationTiers.Tiers[pet.Mutation or "Normal"]
		if tierData and tierData.Color then
			mutColor = tierData.Color
		end
		AddCornerAndStroke(card, 10, if pet.Equipped then Color3.fromRGB(34, 197, 94) else mutColor, if pet.Equipped then 2.5 else 1.5)

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -8, 0, 32)
		nameLbl.Position = UDim2.fromOffset(4, 4)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.FredokaOne
		nameLbl.TextColor3 = mutColor
		nameLbl.TextSize = 13
		nameLbl.TextWrapped = true
		nameLbl.Text = (if pet.IsShiny then "✨ " else "") .. (if pet.Mutation ~= "Normal" then "[" .. pet.Mutation .. "]\n" else "") .. pet.Name
		nameLbl.Parent = card

		local multLbl = Instance.new("TextLabel")
		multLbl.Size = UDim2.new(1, -8, 0, 20)
		multLbl.Position = UDim2.fromOffset(4, 38)
		multLbl.BackgroundTransparency = 1
		multLbl.Font = Enum.Font.SourceSansBold
		multLbl.TextColor3 = Color3.fromRGB(250, 204, 21)
		multLbl.TextSize = 14
		local baseStat = pet.BaseMultiplier or pet.Stat or 1
		multLbl.Text = string.format("x%s Clicks", tostring(baseStat))
		multLbl.Parent = card

		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.new(0.68, -4, 0, 28)
		equipBtn.Position = UDim2.new(0, 4, 1, -32)
		equipBtn.BackgroundColor3 = if pet.Equipped then Color3.fromRGB(220, 38, 38) else Color3.fromRGB(22, 163, 74)
		equipBtn.Font = Enum.Font.FredokaOne
		equipBtn.TextColor3 = Color3.new(1, 1, 1)
		equipBtn.TextSize = 13
		equipBtn.Text = if pet.Equipped then "Unequip" else "Equip"
		equipBtn.Parent = card
		AddCornerAndStroke(equipBtn, 6, Color3.new(1, 1, 1), 1)

		AttachButtonBounce(equipBtn, function()
			local res = EquipPetRemote:InvokeServer(uuid)
			if res then
				ShowToast(res.Message, not res.Success)
				local inv = GetInventoryRemote:InvokeServer()
				RenderPetInventory(inv)
			end
		end)

		local enchantText = "Enchant"
		if pet.Enchants and next(pet.Enchants) ~= nil then
			for eType, eTier in pairs(pet.Enchants) do
				enchantText = string.format("%s %d", eType, eTier)
				break
			end
		end

		local enchantBtn = Instance.new("TextButton")
		enchantBtn.Size = UDim2.new(1, -8, 0, 22)
		enchantBtn.Position = UDim2.new(0, 4, 1, -82)
		enchantBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
		enchantBtn.Font = Enum.Font.FredokaOne
		enchantBtn.TextColor3 = Color3.new(1, 1, 1)
		enchantBtn.TextSize = 11
		enchantBtn.Text = enchantText
		enchantBtn.Parent = card
		AddCornerAndStroke(enchantBtn, 6, Color3.new(1, 1, 1), 1)

		AttachButtonBounce(enchantBtn, function()
			local res = Remotes:WaitForChild("RollEnchantFunction"):InvokeServer(uuid)
			if res then
				ShowToast(res.Message, not res.Success)
				local inv = GetInventoryRemote:InvokeServer()
				RenderPetInventory(inv)
			end
		end)

		AttachButtonBounce(fuseBtn, function()
			local inv = GetInventoryRemote:InvokeServer()
			local victims = {}
			if type(inv) == "table" then
				for u, p in pairs(inv) do
					if u ~= uuid and not p.Locked and not p.Equipped and #victims < 5 then
						table.insert(victims, u)
					end
				end
			end
			local res = Remotes:WaitForChild("FusePetXPFunction"):InvokeServer(uuid, victims)
			if res then
				ShowToast(res.Message, not res.Success)
				local newInv = GetInventoryRemote:InvokeServer()
				RenderPetInventory(newInv)
			end
		end)

		local lockBtn = Instance.new("TextButton")
		lockBtn.Size = UDim2.new(0.32, -4, 0, 28)
		lockBtn.Position = UDim2.new(1, -4, 1, -32)
		lockBtn.AnchorPoint = Vector2.new(1, 0)
		lockBtn.BackgroundColor3 = if pet.Locked then Color3.fromRGB(234, 179, 8) else Color3.fromRGB(71, 85, 105)
		lockBtn.Font = Enum.Font.FredokaOne
		lockBtn.TextColor3 = Color3.new(1, 1, 1)
		lockBtn.TextSize = 14
		lockBtn.Text = if pet.Locked then "[L]" else "[U]"
		lockBtn.Parent = card
		AddCornerAndStroke(lockBtn, 6, Color3.new(1, 1, 1), 1)

		AttachButtonBounce(lockBtn, function()
			if MultiDeleteMode then
				SelectedForDelete[uuid] = not SelectedForDelete[uuid]
				local inv = GetInventoryRemote:InvokeServer()
				RenderPetInventory(inv)
			else
				local res = ToggleLockPetRemote:InvokeServer(uuid)
				if res then
					ShowToast(res.Message, not res.Success)
					local inv = GetInventoryRemote:InvokeServer()
					RenderPetInventory(inv)
				end
			end
		end)
	end
end

AttachButtonBounce(MultiDeleteToggleBtn, function()
	MultiDeleteMode = not MultiDeleteMode
	MultiDeleteToggleBtn.Text = if MultiDeleteMode then "Multi-Delete: ON" else "Multi-Delete: OFF"
	MultiDeleteToggleBtn.BackgroundColor3 = if MultiDeleteMode then Color3.fromRGB(22, 163, 74) else Color3.fromRGB(220, 38, 38)
	DeleteConfirmBtn.Visible = MultiDeleteMode
	table.clear(SelectedForDelete)
	local inv = GetInventoryRemote:InvokeServer()
	RenderPetInventory(inv)
end)

AttachButtonBounce(DeleteConfirmBtn, function()
	local toDelete = {}
	for u, sel in pairs(SelectedForDelete) do
		if sel then table.insert(toDelete, u) end
	end
	local res = Remotes:WaitForChild("MultiDeletePetsFunction"):InvokeServer(toDelete)
	if res then
		ShowToast(res.Message, not res.Success)
		table.clear(SelectedForDelete)
		local inv = GetInventoryRemote:InvokeServer()
		RenderPetInventory(inv)
	end
end)

SearchFilterBox:GetPropertyChangedSignal("Text"):Connect(function()
	local inv = GetInventoryRemote:InvokeServer()
	RenderPetInventory(inv)
end)

SyncInventoryEvent.OnClientEvent:Connect(function(inventory)
	if type(inventory) == "table" then
		RenderPetInventory(inventory)
	end
end)

task.spawn(function()
	task.wait(2)
	local inv = GetInventoryRemote:InvokeServer()
	if type(inv) == "table" then
		RenderPetInventory(inv)
	end
end)

-- 2B. MODAL PET INDEX / COLLECTION BOOK
local _, IndexScroll = CreateModalWindow("Index", "PET INDEX COLLECTION BOOK", Color3.fromRGB(16, 185, 129))

local IndexProgressLabel = Instance.new("TextLabel")
IndexProgressLabel.Size = UDim2.new(1, -10, 0, 36)
IndexProgressLabel.BackgroundTransparency = 1
IndexProgressLabel.Font = Enum.Font.FredokaOne
IndexProgressLabel.TextColor3 = Color3.fromRGB(250, 204, 21)
IndexProgressLabel.TextSize = 16
IndexProgressLabel.Text = "Koleksi: 0 Ditemukan | Bonus Pasif: +0% Clicks"
IndexProgressLabel.Parent = IndexScroll

local IndexGrid = Instance.new("UIGridLayout")
IndexGrid.CellSize = UDim2.fromOffset(138, 70)
IndexGrid.CellPadding = UDim2.fromOffset(8, 8)
IndexGrid.Parent = IndexScroll

local function RenderPetIndex(indexData)
	for _, child in ipairs(IndexScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local foundCount = 0
	if type(indexData) == "table" then
		for _ in pairs(indexData) do foundCount += 1 end
	end

	local bonusPct = math.floor(foundCount / 5) * 5
	IndexProgressLabel.Text = string.format("Koleksi: %d Ditemukan | Bonus Pasif: +%d%% Clicks", foundCount, bonusPct)

	local allPetTypes = {
		"Dog", "Cat", "Bunny", "Bear", "Wolf", "Fox", "Forest Dragon",
		"Golem", "Hydra", "Bat", "Pig", "Duck", "Cow", "Goat", "Apple Dragon",
		"Lion", "Desert Fox", "Elephant", "Eagle", "Sand of Time", "Desert Prophecy",
	}

	for _, pName in ipairs(allPetTypes) do
		local card = Instance.new("Frame")
		local isUnlocked = indexData and (indexData[pName .. "_Normal"] or indexData[pName .. "_Golden"] or indexData[pName .. "_Toxic"] or indexData[pName .. "_Galaxy"] or indexData[pName .. "_Rainbow"])
		card.BackgroundColor3 = if isUnlocked then Color3.fromRGB(16, 55, 38) else Color3.fromRGB(30, 41, 59)
		card.Parent = IndexScroll
		AddCornerAndStroke(card, 8, if isUnlocked then Color3.fromRGB(34, 197, 94) else Color3.fromRGB(71, 85, 105), 1.5)

		local tLabel = Instance.new("TextLabel")
		tLabel.Size = UDim2.new(1, -8, 1, -8)
		tLabel.Position = UDim2.fromOffset(4, 4)
		tLabel.BackgroundTransparency = 1
		tLabel.Font = Enum.Font.FredokaOne
		tLabel.TextColor3 = if isUnlocked then Color3.fromRGB(248, 250, 252) else Color3.fromRGB(100, 116, 139)
		tLabel.TextSize = 13
		tLabel.TextWrapped = true
		tLabel.Text = if isUnlocked then pName .. "\n[Ditemukan]" else "???\n[Terkunci]"
		tLabel.Parent = card
	end
end

SyncPetIndexEvent.OnClientEvent:Connect(function(indexData)
	if type(indexData) == "table" then
		RenderPetIndex(indexData)
	end
end)

task.spawn(function()
	task.wait(2.5)
	local idx = GetPetIndexRemote:InvokeServer()
	if type(idx) == "table" then
		RenderPetIndex(idx)
	end
end)
local _, UpgradesScroll = CreateModalWindow("Upgrades", "GEMS UPGRADES SHOP", Color3.fromRGB(168, 85, 247))
local UpgradesListLayout = Instance.new("UIListLayout")
UpgradesListLayout.Padding = UDim.new(0, 8)
UpgradesListLayout.Parent = UpgradesScroll

local UPGRADE_ITEMS = {
	{ Key = "FreeAutoclicker", Title = "Free Autoclicker", Desc = "Buka klik otomatis (25K Gems)" },
	{ Key = "RebirthButtons", Title = "Rebirth Buttons", Desc = "Buka opsi tombol Rebirth massal" },
	{ Key = "ClickMultiplier", Title = "Click Multiplier", Desc = "Tingkatkan perolehan Clicks dasar" },
	{ Key = "LuckMultiplier", Title = "Luck Multiplier", Desc = "Meningkatkan hoki semua Egg" },
	{ Key = "PetEquipSlots", Title = "Pet Equip Slots", Desc = "Menambah +1 kapasitas Pet aktif" },
	{ Key = "GoldenPetLuck", Title = "Golden Pet Luck", Desc = "Peluang langsung hatch Pet Golden" },
	{ Key = "ToxicPetLuck", Title = "Toxic Pet Luck", Desc = "Peluang langsung hatch Pet Toxic" },
	{ Key = "AuraLuck", Title = "Auras Luck", Desc = "Hoki gacha dadu di Atlantis Machine" },
	{ Key = "HatchSpeed", Title = "Hatch Speed", Desc = "Percepat durasi animasi hatch" },
}

for _, upg in ipairs(UPGRADE_ITEMS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -12, 0, 62)
	row.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	row.Parent = UpgradesScroll
	AddCornerAndStroke(row, 10, Color3.fromRGB(139, 92, 246), 1.5)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.68, 0, 0, 26)
	title.Position = UDim2.fromOffset(12, 6)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = Color3.fromRGB(248, 250, 252)
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = upg.Title
	title.Parent = row

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0.68, 0, 0, 22)
	desc.Position = UDim2.fromOffset(12, 32)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.SourceSansSemibold
	desc.TextColor3 = Color3.fromRGB(148, 163, 184)
	desc.TextSize = 14
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Text = upg.Desc
	desc.Parent = row

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.fromOffset(130, 38)
	buyBtn.Position = UDim2.new(1, -12, 0.5, 0)
	buyBtn.AnchorPoint = Vector2.new(1, 0.5)
	buyBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
	buyBtn.Font = Enum.Font.FredokaOne
	buyBtn.TextColor3 = Color3.new(1, 1, 1)
	buyBtn.TextSize = 15
	buyBtn.Text = "Upgrade"
	buyBtn.Parent = row
	AddCornerAndStroke(buyBtn, 8, Color3.new(1, 1, 1), 1.5)

	AttachButtonBounce(buyBtn, function()
		local res = UpgradeRemote:InvokeServer(upg.Key)
		if res then
			ShowToast(res.Message, not res.Success)
			if res.Success and _G.SoundFX then _G.SoundFX.Play("Upgrade") end
		end
	end)
end

-- 4. MODAL POTIONS SHOP
local _, PotionsScroll = CreateModalWindow("Potions", "POTIONS SHOP (DURASI 5-15 MENIT)", Color3.fromRGB(168, 85, 247))
local PotionsGrid = Instance.new("UIGridLayout")
PotionsGrid.CellSize = UDim2.fromOffset(280, 76)
PotionsGrid.CellPadding = UDim2.fromOffset(10, 10)
PotionsGrid.Parent = PotionsScroll

local POTION_LIST = {
	{ Key = "ClicksNormal", Label = "Clicks Potion (Normal)", Cost = 1000 },
	{ Key = "ClicksMega", Label = "Clicks Potion (Mega)", Cost = 5000 },
	{ Key = "ClicksUltra", Label = "Clicks Potion (Ultra)", Cost = 25000 },
	{ Key = "GemsNormal", Label = "Gems Potion (Normal)", Cost = 1000 },
	{ Key = "GemsMega", Label = "Gems Potion (Mega)", Cost = 5000 },
	{ Key = "LuckNormal", Label = "Luck Potion (Normal)", Cost = 2000 },
	{ Key = "LuckMega", Label = "Luck Potion (Mega)", Cost = 10000 },
	{ Key = "RNGLuckPotion", Label = "RNG Aura Luck Potion", Cost = 15000 },
	{ Key = "GoldenPotion", Label = "Golden Mutation Potion", Cost = 50000 },
	{ Key = "ToxicPotion", Label = "Toxic Mutation Potion", Cost = 150000 },
	{ Key = "ShinyPotion", Label = "Shiny Mutation Potion", Cost = 250000 },
	{ Key = "GalaxyPotion", Label = "Galaxy Mutation Potion", Cost = 1000000 },
}

for _, p in ipairs(POTION_LIST) do
	local pCard = Instance.new("Frame")
	pCard.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	pCard.Parent = PotionsScroll
	AddCornerAndStroke(pCard, 10, Color3.fromRGB(168, 85, 247), 1.5)

	local pLabel = Instance.new("TextLabel")
	pLabel.Size = UDim2.new(1, -12, 0, 24)
	pLabel.Position = UDim2.fromOffset(10, 8)
	pLabel.BackgroundTransparency = 1
	pLabel.Font = Enum.Font.FredokaOne
	pLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
	pLabel.TextSize = 14
	pLabel.TextXAlignment = Enum.TextXAlignment.Left
	pLabel.Text = p.Label
	pLabel.Parent = pCard

	local pBtn = Instance.new("TextButton")
	pBtn.Size = UDim2.new(1, -20, 0, 30)
	pBtn.Position = UDim2.new(0, 10, 1, -8)
	pBtn.AnchorPoint = Vector2.new(0, 1)
	pBtn.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
	pBtn.Font = Enum.Font.FredokaOne
	pBtn.TextColor3 = Color3.new(1, 1, 1)
	pBtn.TextSize = 13
	pBtn.Text = string.format("Beli: %d Gems", p.Cost)
	pBtn.Parent = pCard
	AddCornerAndStroke(pBtn, 8, Color3.new(1, 1, 1), 1)

	AttachButtonBounce(pBtn, function()
		local res = BuyPotionRemote:InvokeServer(p.Key)
		if res then ShowToast(res.Message, not res.Success) end
	end)
end

-- 5. MODAL ROBUX SHOP
local _, GamepassScroll = CreateModalWindow("GamepassShop", "EXCLUSIVE ROBUX SHOP", Color3.fromRGB(244, 114, 182))
local GamepassGrid = Instance.new("UIGridLayout")
GamepassGrid.CellSize = UDim2.fromOffset(280, 96)
GamepassGrid.CellPadding = UDim2.fromOffset(10, 10)
GamepassGrid.Parent = GamepassScroll

for gpName, gpData in pairs(Config.Gamepasses) do
	local card = Instance.new("Frame")
	card.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	card.Parent = GamepassScroll
	AddCornerAndStroke(card, 12, Color3.fromRGB(236, 72, 153), 1.5)

	local gpTitle = Instance.new("TextLabel")
	gpTitle.Size = UDim2.new(1, -16, 0, 24)
	gpTitle.Position = UDim2.fromOffset(8, 6)
	gpTitle.BackgroundTransparency = 1
	gpTitle.Font = Enum.Font.FredokaOne
	gpTitle.TextColor3 = Color3.fromRGB(253, 224, 71)
	gpTitle.TextSize = 15
	gpTitle.TextXAlignment = Enum.TextXAlignment.Left
	gpTitle.Text = gpName
	gpTitle.Parent = card

	local price = gpData.PriceRobux or gpData.RobuxPrice or 0
	local gpId = gpData.Id or gpData.GamepassId or 0

	local buyGpBtn = Instance.new("TextButton")
	buyGpBtn.Size = UDim2.new(1, -16, 0, 32)
	buyGpBtn.Position = UDim2.new(0, 8, 1, -8)
	buyGpBtn.AnchorPoint = Vector2.new(0, 1)
	buyGpBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	buyGpBtn.Font = Enum.Font.FredokaOne
	buyGpBtn.TextColor3 = Color3.new(1, 1, 1)
	buyGpBtn.TextSize = 14
	buyGpBtn.Text = string.format("R$ %d - Beli", price)
	buyGpBtn.Parent = card
	AddCornerAndStroke(buyGpBtn, 8, Color3.new(1, 1, 1), 1)

	AttachButtonBounce(buyGpBtn, function()
		if gpId > 0 then
			MarketplaceService:PromptGamePassPurchase(LocalPlayer, gpId)
		else
			ShowToast("Gamepass ID belum diisi di RebirthChampionsConfig!")
		end
	end)
end

-- EXCLUSIVE ROBUX BOOKS SECTION (Diskon 50%)
local EXCLUSIVE_BOOKS = {
	{ Key = "SlotBook", Name = "Exclusive Slot Book", Desc = "Memberikan +1 Extra Pet Equip Slot", Robux = 249 },
	{ Key = "LuckBook", Name = "Exclusive Luck Book", Desc = "Memberikan +100% Base Egg Luck Permanen", Robux = 349 },
	{ Key = "RainbowBook", Name = "Exclusive Rainbow Book", Desc = "Mengubah Pet instan menjadi Tier Rainbow (16x)", Robux = 399 },
	{ Key = "ShinyBook", Name = "Exclusive Shiny Book", Desc = "Mengubah Pet instan menjadi SHINY (1.5x Multiplier)", Robux = 299 },
}

for _, bData in ipairs(EXCLUSIVE_BOOKS) do
	local bCard = Instance.new("Frame")
	bCard.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	bCard.Parent = GamepassScroll
	AddCornerAndStroke(bCard, 12, Color3.fromRGB(245, 158, 11), 1.5)

	local bTitle = Instance.new("TextLabel")
	bTitle.Size = UDim2.new(1, -16, 0, 24)
	bTitle.Position = UDim2.fromOffset(8, 6)
	bTitle.BackgroundTransparency = 1
	bTitle.Font = Enum.Font.FredokaOne
	bTitle.TextColor3 = Color3.fromRGB(250, 204, 21)
	bTitle.TextSize = 14
	bTitle.TextXAlignment = Enum.TextXAlignment.Left
	bTitle.Text = bData.Name
	bTitle.Parent = bCard

	local bDesc = Instance.new("TextLabel")
	bDesc.Size = UDim2.new(1, -16, 0, 30)
	bDesc.Position = UDim2.fromOffset(8, 30)
	bDesc.BackgroundTransparency = 1
	bDesc.Font = Enum.Font.SourceSansBold
	bDesc.TextColor3 = Color3.fromRGB(203, 213, 225)
	bDesc.TextSize = 12
	bDesc.TextWrapped = true
	bDesc.TextXAlignment = Enum.TextXAlignment.Left
	bDesc.Text = bData.Desc
	bDesc.Parent = bCard

	local buyBookBtn = Instance.new("TextButton")
	buyBookBtn.Size = UDim2.new(1, -16, 0, 28)
	buyBookBtn.Position = UDim2.new(0, 8, 1, -6)
	buyBookBtn.AnchorPoint = Vector2.new(0, 1)
	buyBookBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
	buyBookBtn.Font = Enum.Font.FredokaOne
	buyBookBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
	buyBookBtn.TextSize = 13
	buyBookBtn.Text = string.format("R$ %d - Terapkan ke Pet", bData.Robux)
	buyBookBtn.Parent = bCard
	AddCornerAndStroke(buyBookBtn, 6, Color3.new(1, 1, 1), 1)

	AttachButtonBounce(buyBookBtn, function()
		local inv = GetInventoryRemote:InvokeServer()
		local targetUUID = nil
		if type(inv) == "table" then
			for u, p in pairs(inv) do
				if p.Equipped then targetUUID = u break end
			end
		end
		if not targetUUID then
			ShowToast("Pasang (Equip) minimal 1 pet terlebih dahulu untuk menerima buku!", true)
			return
		end

		local res = Remotes:WaitForChild("ApplyExclusiveBookFunction"):InvokeServer(targetUUID, bData.Key)
		if res then ShowToast(res.Message, not res.Success) end
	end)
end

-- EXCLUSIVE FANTASY EGG SECTION (Harga: 29 R$ 1x / 199 R$ 10x | Scaling: 110% s/d 500%)
local ExcEggCard = Instance.new("Frame")
ExcEggCard.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
ExcEggCard.Parent = GamepassScroll
AddCornerAndStroke(ExcEggCard, 12, Color3.fromRGB(250, 204, 21), 2)

local ExcEggTitle = Instance.new("TextLabel")
ExcEggTitle.Size = UDim2.new(1, -16, 0, 22)
ExcEggTitle.Position = UDim2.fromOffset(8, 4)
ExcEggTitle.BackgroundTransparency = 1
ExcEggTitle.Font = Enum.Font.FredokaOne
ExcEggTitle.TextColor3 = Color3.fromRGB(250, 204, 21)
ExcEggTitle.TextSize = 14
ExcEggTitle.TextXAlignment = Enum.TextXAlignment.Left
ExcEggTitle.Text = "EXCLUSIVE FANTASY EGG"
ExcEggTitle.Parent = ExcEggCard

local ExcEggDesc = Instance.new("TextLabel")
ExcEggDesc.Size = UDim2.new(1, -16, 0, 26)
ExcEggDesc.Position = UDim2.fromOffset(8, 26)
ExcEggDesc.BackgroundTransparency = 1
ExcEggDesc.Font = Enum.Font.SourceSansBold
ExcEggDesc.TextColor3 = Color3.fromRGB(203, 213, 225)
ExcEggDesc.TextSize = 11
ExcEggDesc.TextWrapped = true
ExcEggDesc.TextXAlignment = Enum.TextXAlignment.Left
ExcEggDesc.Text = "Stat: 110%, 125%, 150%, 200% s/d Supreme 500%!"
ExcEggDesc.Parent = ExcEggCard

local Buy1xBtn = Instance.new("TextButton")
Buy1xBtn.Size = UDim2.new(0.48, -6, 0, 28)
Buy1xBtn.Position = UDim2.new(0, 8, 1, -6)
Buy1xBtn.AnchorPoint = Vector2.new(0, 1)
Buy1xBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
Buy1xBtn.Font = Enum.Font.FredokaOne
Buy1xBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
Buy1xBtn.TextSize = 12
Buy1xBtn.Text = "R$ 29 (1x)"
Buy1xBtn.Parent = ExcEggCard
AddCornerAndStroke(Buy1xBtn, 6, Color3.new(1, 1, 1), 1)

AttachButtonBounce(Buy1xBtn, function()
	local res = Remotes:WaitForChild("HatchExclusiveEggFunction"):InvokeServer(1)
	if res then
		ShowToast(res.Message, not res.Success)
		if res.Success and _G.SoundFX then _G.SoundFX.Play("Reward") end
		local inv = GetInventoryRemote:InvokeServer()
		RenderPetInventory(inv)
	end
end)

local Buy10xBtn = Instance.new("TextButton")
Buy10xBtn.Size = UDim2.new(0.48, -6, 0, 28)
Buy10xBtn.Position = UDim2.new(1, -8, 1, -6)
Buy10xBtn.AnchorPoint = Vector2.new(1, 1)
Buy10xBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
Buy10xBtn.Font = Enum.Font.FredokaOne
Buy10xBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
Buy10xBtn.TextSize = 12
Buy10xBtn.Text = "R$ 199 (10x)"
Buy10xBtn.Parent = ExcEggCard
AddCornerAndStroke(Buy10xBtn, 6, Color3.new(1, 1, 1), 1)

AttachButtonBounce(Buy10xBtn, function()
	local res = Remotes:WaitForChild("HatchExclusiveEggFunction"):InvokeServer(10)
	if res then
		ShowToast(res.Message, not res.Success)
		if res.Success and _G.SoundFX then _G.SoundFX.Play("Reward") end
		local inv = GetInventoryRemote:InvokeServer()
		RenderPetInventory(inv)
	end
end)
Buy10xBtn.Text = "R$ 199 (10x)"
Buy10xBtn.Parent = ExcEggCard
AddCornerAndStroke(Buy10xBtn, 6, Color3.new(1, 1, 1), 1)

AttachButtonBounce(Buy10xBtn, function()
	local res = Remotes:WaitForChild("HatchExclusiveEggFunction"):InvokeServer(10)
	if res then
		ShowToast(res.Message, not res.Success)
		if res.Success and _G.SoundFX then _G.SoundFX.Play("Reward") end
		local inv = GetInventoryRemote:InvokeServer()
		RenderPetInventory(inv)
	end
end)

-- 6. MODAL WORLDS TELEPORT
local _, WorldsScroll = CreateModalWindow("Worlds", "WORLD PORTALS (58 PULAU)", Color3.fromRGB(56, 189, 248))
local WorldsGrid = Instance.new("UIGridLayout")
WorldsGrid.CellSize = UDim2.fromOffset(180, 68)
WorldsGrid.CellPadding = UDim2.fromOffset(10, 10)
WorldsGrid.Parent = WorldsScroll

for _, worldInfo in ipairs(Config.Worlds) do
	local wBtn = Instance.new("TextButton")
	wBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	wBtn.Font = Enum.Font.FredokaOne
	wBtn.TextColor3 = Color3.fromRGB(248, 250, 252)
	wBtn.TextSize = 14
	wBtn.TextWrapped = true
	wBtn.Text = string.format("%d. %s\n[%s · x%s]", worldInfo.Id, worldInfo.Name, worldInfo.Dimension, tostring(worldInfo.WorldBoost))
	wBtn.Parent = WorldsScroll
	AddCornerAndStroke(wBtn, 10, Color3.fromRGB(56, 189, 248), 1.5)

	AttachButtonBounce(wBtn, function()
		local res = TeleportWorldRemote:InvokeServer(worldInfo.Name)
		if res then ShowToast(res.Message, not res.Success) end
	end)
end

-- 7. MODAL DAILY SPIN
local DailySpinModal, DailySpinScroll = CreateModalWindow("DailySpin", "DAILY SPIN WHEEL (GRATIS TIAP 24 JAM)", Color3.fromRGB(234, 179, 8))

local WheelVisual = Instance.new("Frame")
WheelVisual.Name = "SpinWheelDisc"
WheelVisual.Size = UDim2.fromOffset(180, 180)
WheelVisual.Position = UDim2.new(0.5, 0, 0, 100)
WheelVisual.AnchorPoint = Vector2.new(0.5, 0.5)
WheelVisual.BackgroundColor3 = Color3.fromRGB(250, 204, 21)
WheelVisual.Parent = DailySpinScroll
AddCornerAndStroke(WheelVisual, 90, Color3.fromRGB(255, 255, 255), 4)

local Pointer = Instance.new("TextLabel")
Pointer.Size = UDim2.fromOffset(40, 40)
Pointer.Position = UDim2.new(0.5, 0, 0, -10)
Pointer.AnchorPoint = Vector2.new(0.5, 0.5)
Pointer.BackgroundTransparency = 1
Pointer.Font = Enum.Font.FredokaOne
Pointer.TextSize = 22
Pointer.TextColor3 = Color3.fromRGB(239, 68, 68)
Pointer.Text = "V"
Pointer.Parent = WheelVisual

local SpinBtn = Instance.new("TextButton")
SpinBtn.Size = UDim2.fromOffset(220, 52)
SpinBtn.Position = UDim2.new(0.5, 0, 0, 220)
SpinBtn.AnchorPoint = Vector2.new(0.5, 0)
SpinBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
SpinBtn.Font = Enum.Font.FredokaOne
SpinBtn.TextColor3 = Color3.new(1, 1, 1)
SpinBtn.TextSize = 20
SpinBtn.Text = "PUTAR SEKARANG"
SpinBtn.Parent = DailySpinScroll
AddCornerAndStroke(SpinBtn, 14, Color3.new(1, 1, 1), 2)

AttachButtonBounce(SpinBtn, function()
	if _G.RebirthDailySpinAndCodesAPI then
		_G.RebirthDailySpinAndCodesAPI.SpinWheel(WheelVisual)
	else
		local res = DailySpinRemote:InvokeServer()
		if res then ShowToast(res.Message, not res.Success) end
	end
end)

-- 8. MODAL PROMO CODES
local _, CodesScroll = CreateModalWindow("Codes", "REDEEM PROMO CODES", Color3.fromRGB(59, 130, 246))

local CodeInputBox = Instance.new("TextBox")
CodeInputBox.Size = UDim2.fromOffset(360, 48)
CodeInputBox.Position = UDim2.new(0.5, 0, 0, 30)
CodeInputBox.AnchorPoint = Vector2.new(0.5, 0)
CodeInputBox.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
CodeInputBox.Font = Enum.Font.FredokaOne
CodeInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
CodeInputBox.PlaceholderColor3 = Color3.fromRGB(148, 163, 184)
CodeInputBox.PlaceholderText = "Masukkan kode (contoh: release, thunder)..."
CodeInputBox.TextSize = 16
CodeInputBox.Parent = CodesScroll
AddCornerAndStroke(CodeInputBox, 12, Color3.fromRGB(59, 130, 246), 2)

local SubmitCodeBtn = Instance.new("TextButton")
SubmitCodeBtn.Size = UDim2.fromOffset(200, 48)
SubmitCodeBtn.Position = UDim2.new(0.5, 0, 0, 95)
SubmitCodeBtn.AnchorPoint = Vector2.new(0.5, 0)
SubmitCodeBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
SubmitCodeBtn.Font = Enum.Font.FredokaOne
SubmitCodeBtn.TextColor3 = Color3.new(1, 1, 1)
SubmitCodeBtn.TextSize = 18
SubmitCodeBtn.Text = "TUKAR KODE"
SubmitCodeBtn.Parent = CodesScroll
AddCornerAndStroke(SubmitCodeBtn, 12, Color3.new(1, 1, 1), 2)

AttachButtonBounce(SubmitCodeBtn, function()
	local code = CodeInputBox.Text
	local res = RedeemCodeRemote:InvokeServer(code)
	if res then
		ShowToast(res.Message, not res.Success)
		if res.Success then CodeInputBox.Text = "" end
	end
end)

-- 9. MODAL SETTINGS
local _, SettingsScroll = CreateModalWindow("Settings", "GAME SETTINGS", Color3.fromRGB(148, 163, 184))
local SettingsLayout = Instance.new("UIListLayout")
SettingsLayout.Padding = UDim.new(0, 10)
SettingsLayout.Parent = SettingsScroll

local SETTING_OPTIONS = {
	{ Key = "SoundFX", Label = "Sound Effects", Default = true },
	{ Key = "OtherPets", Label = "Sembunyikan Pet Orang Lain (Anti-Lag)", Default = false },
	{ Key = "TradeRequests", Label = "Terima Permintaan Trade", Default = true },
}

local UserSettingsState = {
	SoundFX = true,
	OtherPets = false,
	TradeRequests = true,
}

for _, opt in ipairs(SETTING_OPTIONS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -12, 0, 50)
	row.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	row.Parent = SettingsScroll
	AddCornerAndStroke(row, 10, Color3.fromRGB(100, 116, 139), 1.5)

	local sTitle = Instance.new("TextLabel")
	sTitle.Size = UDim2.new(0.7, 0, 1, 0)
	sTitle.Position = UDim2.fromOffset(12, 0)
	sTitle.BackgroundTransparency = 1
	sTitle.Font = Enum.Font.FredokaOne
	sTitle.TextColor3 = Color3.fromRGB(248, 250, 252)
	sTitle.TextSize = 15
	sTitle.TextXAlignment = Enum.TextXAlignment.Left
	sTitle.Text = opt.Label
	sTitle.Parent = row

	local tBtn = Instance.new("TextButton")
	tBtn.Size = UDim2.fromOffset(90, 32)
	tBtn.Position = UDim2.new(1, -12, 0.5, 0)
	tBtn.AnchorPoint = Vector2.new(1, 0.5)
	tBtn.BackgroundColor3 = if opt.Default then Color3.fromRGB(22, 163, 74) else Color3.fromRGB(220, 38, 38)
	tBtn.Font = Enum.Font.FredokaOne
	tBtn.TextColor3 = Color3.new(1, 1, 1)
	tBtn.TextSize = 13
	tBtn.Text = if opt.Default then "ON" else "OFF"
	tBtn.Parent = row
	AddCornerAndStroke(tBtn, 6, Color3.new(1, 1, 1), 1)

	AttachButtonBounce(tBtn, function()
		UserSettingsState[opt.Key] = not UserSettingsState[opt.Key]
		local state = UserSettingsState[opt.Key]
		tBtn.Text = if state then "ON" else "OFF"
		tBtn.BackgroundColor3 = if state then Color3.fromRGB(22, 163, 74) else Color3.fromRGB(220, 38, 38)

		if opt.Key == "OtherPets" then
			local container = workspace:FindFirstChild("ClientEquippedPets")
			if container then
				for _, m in ipairs(container:GetChildren()) do
					if m:IsA("Model") then
						for _, p in ipairs(m:GetDescendants()) do
							if p:IsA("BasePart") then p.Transparency = if state then 1 else 0 end
						end
					end
				end
			end
		end
	end)
end

-- 10. MODAL DAILY STREAK CALENDAR (7 HARI)
local _, StreakScroll = CreateModalWindow("Streak", "DAILY LOGIN STREAK (7 HARI BERUNTUN)", Color3.fromRGB(250, 204, 21))
local StreakGrid = Instance.new("UIGridLayout")
StreakGrid.CellSize = UDim2.fromOffset(136, 120)
StreakGrid.CellPadding = UDim2.fromOffset(8, 8)
StreakGrid.Parent = StreakScroll

local STREAK_CARDS = {
	{ Day = 1, Text = "5,000 Gems" },
	{ Day = 2, Text = "50,000 Clicks" },
	{ Day = 3, Text = "10x Aura Dice" },
	{ Day = 4, Text = "Mega Luck Potion" },
	{ Day = 5, Text = "100,000 Gems" },
	{ Day = 6, Text = "100 Trade Tokens" },
	{ Day = 7, Text = "STREAK PHOENIX (PET)" },
}

for _, s in ipairs(STREAK_CARDS) do
	local card = Instance.new("Frame")
	card.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	card.Parent = StreakScroll
	AddCornerAndStroke(card, 10, Color3.fromRGB(245, 158, 11), 1.5)

	local dTitle = Instance.new("TextLabel")
	dTitle.Size = UDim2.new(1, 0, 0, 24)
	dTitle.Position = UDim2.fromOffset(0, 6)
	dTitle.BackgroundTransparency = 1
	dTitle.Font = Enum.Font.FredokaOne
	dTitle.TextColor3 = Color3.fromRGB(250, 204, 21)
	dTitle.TextSize = 14
	dTitle.Text = "HARI " .. s.Day
	dTitle.Parent = card

	local dReward = Instance.new("TextLabel")
	dReward.Size = UDim2.new(1, -8, 0, 40)
	dReward.Position = UDim2.fromOffset(4, 30)
	dReward.BackgroundTransparency = 1
	dReward.Font = Enum.Font.SourceSansBold
	dReward.TextColor3 = Color3.fromRGB(248, 250, 252)
	dReward.TextSize = 12
	dReward.TextWrapped = true
	dReward.Text = s.Text
	dReward.Parent = card

	local claimBtn = Instance.new("TextButton")
	claimBtn.Size = UDim2.new(1, -12, 0, 26)
	claimBtn.Position = UDim2.new(0, 6, 1, -6)
	claimBtn.AnchorPoint = Vector2.new(0, 1)
	claimBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	claimBtn.Font = Enum.Font.FredokaOne
	claimBtn.TextColor3 = Color3.new(1, 1, 1)
	claimBtn.TextSize = 12
	claimBtn.Text = "KLAIM"
	claimBtn.Parent = card
	AddCornerAndStroke(claimBtn, 6, Color3.new(1, 1, 1), 1)

	AttachButtonBounce(claimBtn, function()
		local res = Remotes:WaitForChild("ClaimStreakFunction"):InvokeServer()
		if res then ShowToast(res.Message, not res.Success) end
	end)
end

-- 11. MODAL DAILY QUESTS
local _, QuestsScroll = CreateModalWindow("Quests", "DAILY QUESTS (RESET SETIAP HARI)", Color3.fromRGB(56, 189, 248))
local QuestsLayout = Instance.new("UIListLayout")
QuestsLayout.Padding = UDim.new(0, 10)
QuestsLayout.Parent = QuestsScroll

local QUESTS_LIST = {
	{ Key = "Click1000", Title = "Tap 1.000 kali", Reward = "+10.000 Gems" },
	{ Key = "Rebirth5", Title = "Lakukan 5 Rebirth", Reward = "+25.000 Gems" },
	{ Key = "Hatch10", Title = "Buka 10 Telur", Reward = "+15.000 Gems" },
}

for _, q in ipairs(QUESTS_LIST) do
	local qRow = Instance.new("Frame")
	qRow.Size = UDim2.new(1, -12, 0, 56)
	qRow.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	qRow.Parent = QuestsScroll
	AddCornerAndStroke(qRow, 10, Color3.fromRGB(56, 189, 248), 1.5)

	local qTitle = Instance.new("TextLabel")
	qTitle.Size = UDim2.new(0.65, 0, 1, 0)
	qTitle.Position = UDim2.fromOffset(12, 0)
	qTitle.BackgroundTransparency = 1
	qTitle.Font = Enum.Font.FredokaOne
	qTitle.TextColor3 = Color3.fromRGB(248, 250, 252)
	qTitle.TextSize = 15
	qTitle.TextXAlignment = Enum.TextXAlignment.Left
	qTitle.Text = q.Title .. " (" .. q.Reward .. ")"
	qTitle.Parent = qRow

	local qBtn = Instance.new("TextButton")
	qBtn.Size = UDim2.fromOffset(110, 36)
	qBtn.Position = UDim2.new(1, -12, 0.5, 0)
	qBtn.AnchorPoint = Vector2.new(1, 0.5)
	qBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	qBtn.Font = Enum.Font.FredokaOne
	qBtn.TextColor3 = Color3.new(1, 1, 1)
	qBtn.TextSize = 14
	qBtn.Text = "KLAIM"
	qBtn.Parent = qRow
	AddCornerAndStroke(qBtn, 8, Color3.new(1, 1, 1), 1)

	AttachButtonBounce(qBtn, function()
		local res = Remotes:WaitForChild("ClaimQuestFunction"):InvokeServer(q.Key)
		if res then ShowToast(res.Message, not res.Success) end
	end)
end

-- 12. MODAL PLAYTIME GIFTS
local _, GiftsScroll = CreateModalWindow("Gifts", "PLAYTIME GIFTS (GRATIS SAAT ONLINE)", Color3.fromRGB(244, 114, 182))
local GiftsGrid = Instance.new("UIGridLayout")
GiftsGrid.CellSize = UDim2.fromOffset(140, 110)
GiftsGrid.CellPadding = UDim2.fromOffset(10, 10)
GiftsGrid.Parent = GiftsScroll

local GIFTS_LIST = {
	{ Idx = 1, Min = 5, Gems = 5000 },
	{ Idx = 2, Min = 15, Gems = 15000 },
	{ Idx = 3, Min = 30, Gems = 35000 },
	{ Idx = 4, Min = 60, Gems = 80000 },
}

for _, g in ipairs(GIFTS_LIST) do
	local gCard = Instance.new("Frame")
	gCard.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	gCard.Parent = GiftsScroll
	AddCornerAndStroke(gCard, 10, Color3.fromRGB(244, 114, 182), 1.5)

	local gTitle = Instance.new("TextLabel")
	gTitle.Size = UDim2.new(1, 0, 0, 24)
	gTitle.Position = UDim2.fromOffset(0, 8)
	gTitle.BackgroundTransparency = 1
	gTitle.Font = Enum.Font.FredokaOne
	gTitle.TextColor3 = Color3.fromRGB(244, 114, 182)
	gTitle.TextSize = 14
	gTitle.Text = g.Min .. " MENIT"
	gTitle.Parent = gCard

	local gReward = Instance.new("TextLabel")
	gReward.Size = UDim2.new(1, 0, 0, 24)
	gReward.Position = UDim2.fromOffset(0, 32)
	gReward.BackgroundTransparency = 1
	gReward.Font = Enum.Font.SourceSansBold
	gReward.TextColor3 = Color3.fromRGB(250, 204, 21)
	gReward.TextSize = 14
	gReward.Text = "+" .. g.Gems .. " Gems"
	gReward.Parent = gCard

	local gBtn = Instance.new("TextButton")
	gBtn.Size = UDim2.new(1, -12, 0, 26)
	gBtn.Position = UDim2.new(0, 6, 1, -8)
	gBtn.AnchorPoint = Vector2.new(0, 1)
	gBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	gBtn.Font = Enum.Font.FredokaOne
	gBtn.TextColor3 = Color3.new(1, 1, 1)
	gBtn.TextSize = 12
	gBtn.Text = "AMBIL"
	gBtn.Parent = gCard
	AddCornerAndStroke(gBtn, 6, Color3.new(1, 1, 1), 1)

	AttachButtonBounce(gBtn, function()
		local res = Remotes:WaitForChild("ClaimPlaytimeGiftFunction"):InvokeServer(g.Idx)
		if res then ShowToast(res.Message, not res.Success) end
	end)
end

print("[AutoGeneratorScreenGuiSystem] HUD dan modal windows berhasil diinisialisasi")

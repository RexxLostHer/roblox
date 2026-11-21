--!strict
-- ============================================================
--  Clicker UI — Pet Simulator Style (Cartoon / Cream / Navy)
--  Diambil dari referensi: top stat pills, sidebar ikon,
--  tombol klik besar di bawah, panel rewards di kanan.
-- ============================================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Bersihkan UI lama agar tidak tumpang tindih
for _, oldGui in ipairs(playerGui:GetChildren()) do
	if oldGui:IsA("ScreenGui") and (oldGui.Name == "ClickerUI" or oldGui.Name == "ClickerJuicedHUD" or oldGui.Name == "ClickPopupsGui") then
		oldGui:Destroy()
	end
end

-- ============================================================
--  REMOTE RESOLVER
-- ============================================================
local function getRemote(name: string): any
	local r = RS:FindFirstChild(name)
	if r then return r end
	local rf = RS:FindFirstChild("Remotes")
	if rf then
		r = rf:FindFirstChild(name)
		if r then return r end
	end
	local waited = RS:WaitForChild(name, 3)
	if waited then return waited end
	if rf then
		waited = rf:WaitForChild(name, 3)
		if waited then return waited end
	end
	return nil
end

local ClickEvent = getRemote("ClickEvent")
local DataUpdate = getRemote("DataUpdate")
local TradeSend = getRemote("TradeSend")
local TradeIncoming = getRemote("TradeIncoming")
local TradeResult = getRemote("TradeResult")
local OpenModalEvent = getRemote("OpenModalClientEvent")

-- ============================================================
--  STATE
-- ============================================================
local clicks = 0
local capacity = 20
local items: { [string]: number } = {}
local selectedTarget: number? = nil
local selectedItem: string? = nil
local isHatching = false

-- ============================================================
--  PALETTE (Cartoon Pet Sim)
-- ============================================================
local C_CREAM      = Color3.fromRGB(255, 250, 240)
local C_CREAM_SOFT = Color3.fromRGB(255, 240, 215)
local C_NAVY       = Color3.fromRGB(40, 48, 90)
local C_NAVY_DEEP  = Color3.fromRGB(26, 31, 62)
local C_SKY        = Color3.fromRGB(175, 225, 255)
local C_SKY_SOFT   = Color3.fromRGB(215, 242, 255)
local C_WHITE      = Color3.fromRGB(255, 255, 255)
local C_PINK       = Color3.fromRGB(255, 92, 120)
local C_BLUE       = Color3.fromRGB(60, 150, 250)
local C_PURPLE     = Color3.fromRGB(170, 95, 245)
local C_GOLD       = Color3.fromRGB(255, 190, 40)
local C_GREEN      = Color3.fromRGB(90, 210, 90)
local C_GREEN_DARK = Color3.fromRGB(50, 160, 60)
local C_RED        = Color3.fromRGB(235, 70, 70)

local RARITY_COLORS: { [string]: Color3 } = {
	Common    = Color3.fromRGB(150, 165, 195),
	Rare      = Color3.fromRGB(70, 165, 255),
	Epic      = Color3.fromRGB(175, 100, 250),
	Legendary = Color3.fromRGB(255, 185, 40),
	Secret    = Color3.fromRGB(255, 85, 110),
}

-- ============================================================
--  EGG DATABASE (preview)
-- ============================================================
local EGG_DATABASE: { [string]: { Title: string, Cost: number, Pets: { { Name: string, Chance: string, Rarity: string, Stat: string } } } } = {
	Basic = {
		Title = "Basic Egg",
		Cost = 250,
		Pets = {
			{ Name = "Dog",   Chance = "50%", Rarity = "Common", Stat = "x1.2" },
			{ Name = "Cat",   Chance = "35%", Rarity = "Rare",   Stat = "x1.4" },
			{ Name = "Bunny", Chance = "15%", Rarity = "Epic",   Stat = "x2.0" },
		},
	},
	Forest = {
		Title = "Forest Egg",
		Cost = 5000,
		Pets = {
			{ Name = "Bear",          Chance = "50%", Rarity = "Common",    Stat = "x3.0" },
			{ Name = "Wolf",          Chance = "30%", Rarity = "Rare",      Stat = "x4.5" },
			{ Name = "Fox",           Chance = "17%", Rarity = "Epic",      Stat = "x6.0" },
			{ Name = "Forest Dragon", Chance = "3%",  Rarity = "Legendary", Stat = "x10.0" },
		},
	},
	Mythic = {
		Title = "Mythic Egg",
		Cost = 25000,
		Pets = {
			{ Name = "Fox",   Chance = "55%", Rarity = "Common",    Stat = "x9.0" },
			{ Name = "Golem", Chance = "30%", Rarity = "Rare",      Stat = "x13.0" },
			{ Name = "Hydra", Chance = "15%", Rarity = "Epic",      Stat = "x18.0" },
			{ Name = "Bat",   Chance = "5%",  Rarity = "Legendary", Stat = "x30.0" },
		},
	},
	Divine = {
		Title = "Divine Egg",
		Cost = 100000,
		Pets = {
			{ Name = "Pig",          Chance = "50%",   Rarity = "Common",    Stat = "x40.0" },
			{ Name = "Duck",         Chance = "30%",   Rarity = "Rare",      Stat = "x65.0" },
			{ Name = "Cow",          Chance = "16%",   Rarity = "Epic",      Stat = "x100.0" },
			{ Name = "Goat",         Chance = "4.75%", Rarity = "Legendary", Stat = "x250.0" },
			{ Name = "Apple Dragon", Chance = "0.25%", Rarity = "Secret",    Stat = "x1200.0" },
		},
	},
}
EGG_DATABASE.Farm = EGG_DATABASE.Divine

-- ============================================================
--  UTIL
-- ============================================================
local SUFFIXES = { "", "K", "M", "B", "T", "Qd" }
local function formatNumber(n: number): string
	if n < 1000 then return tostring(math.floor(n)) end
	local idx = math.clamp(math.floor(math.log10(n) / 3) + 1, 1, #SUFFIXES)
	local scaled = n / (10 ^ ((idx - 1) * 3))
	return string.format("%.1f%s", scaled, SUFFIXES[idx])
end

local function make(className: string, props: { [string]: any }, parent: Instance?): any
	local obj = Instance.new(className)
	for k, v in pairs(props) do
		(obj :: any)[k] = v
	end
	if parent then obj.Parent = parent end
	return obj
end

local function corner(parent: Instance, r: number?)
	make("UICorner", { CornerRadius = UDim.new(0, r or 14) }, parent)
end

local function stroke(parent: Instance, color: Color3, thickness: number?): UIStroke
	return make("UIStroke", {
		Color = color,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent) :: UIStroke
end

local function gradient(parent: Instance, c1: Color3, c2: Color3, rotation: number?)
	make("UIGradient", {
		Color = ColorSequence.new(c1, c2),
		Rotation = rotation or 90,
	}, parent)
end

-- Kartu cartoon: container transparan + shadow navy + panel utama
local function makeCard(parent: Instance, size: UDim2, pos: UDim2?, radius: number?, shadowDepth: number?): (Frame, Frame)
	local container = make("Frame", {
		Size = size,
		Position = pos or UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
	}, parent)

	local shadow = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, shadowDepth or 5),
		BackgroundColor3 = C_NAVY_DEEP,
		BackgroundTransparency = 0.25,
		ZIndex = 1,
	}, container)
	corner(shadow, radius)

	local panel = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C_CREAM,
		ZIndex = 2,
	}, container)
	corner(panel, radius)
	stroke(panel, C_NAVY, 3)

	return container, panel
end

-- ============================================================
--  ROOT
-- ============================================================
local gui = make("ScreenGui", {
	Name = "ClickerJuicedHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 20,
}, playerGui)

-- ============================================================
--  TOAST
-- ============================================================
local toastBox = make("Frame", {
	Size = UDim2.fromOffset(420, 54),
	Position = UDim2.new(0.5, 0, 0, 96),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = C_CREAM,
	Visible = false,
	ZIndex = 500,
}, gui)
corner(toastBox, 26)
local toastStroke = stroke(toastBox, C_NAVY, 3)

local toastLabel = make("TextLabel", {
	Size = UDim2.new(1, -24, 1, 0),
	Position = UDim2.fromOffset(12, 0),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = C_NAVY,
	Font = Enum.Font.FredokaOne,
	TextSize = 17,
	TextWrapped = true,
	ZIndex = 501,
}, toastBox)

local lastToastMsg = ""
local lastToastAt = 0
local toastQueue: { { msg: string, isError: boolean } } = {}
local toastRunning = false

local function showToastNow(msg: string, isError: boolean)
	toastLabel.Text = msg
	toastStroke.Color = if isError then C_RED else C_NAVY
	toastBox.Visible = true
	toastBox.Position = UDim2.new(0.5, 0, 0, 76)
	TweenService:Create(toastBox, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 96),
	}):Play()
end

local function runToastQueue()
	if toastRunning then
		return
	end
	toastRunning = true
	while #toastQueue > 0 do
		local item = table.remove(toastQueue, 1) :: { msg: string, isError: boolean }
		showToastNow(item.msg, item.isError)
		task.wait(2.2)
		if #toastQueue == 0 then
			toastBox.Visible = false
		end
	end
	toastRunning = false
end

local function showToast(msg: string, isError: boolean?)
	-- Cegah pesan yang sama nge-spam berkali-kali
	local now = os.clock()
	if msg == lastToastMsg and (now - lastToastAt) < 3 then
		return
	end
	lastToastMsg = msg
	lastToastAt = now

	-- Maksimal 3 pesan menunggu, sisanya dibuang (biar tidak numpuk)
	if #toastQueue >= 3 then
		table.remove(toastQueue, 1)
	end
	table.insert(toastQueue, { msg = msg, isError = isError == true })
	task.spawn(runToastQueue)
end

-- HUD lama (AutoGeneratorScreenGuiSystem) meneruskan toast ke sini
_G.RebirthShowToast = showToast

-- ============================================================
--  TOP HUD — 4 STAT PILLS
-- ============================================================
local topBar = make("Frame", {
	Size = UDim2.fromOffset(700, 62),
	Position = UDim2.new(0.5, 0, 0, 12),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	ZIndex = 10,
}, gui)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 10),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, topBar)

local statValues: { [string]: TextLabel } = {}

local function makeStatPill(icon: string, iconColor: Color3, labelText: string, valueColor: Color3, order: number): TextLabel
	local container, panel = makeCard(topBar, UDim2.fromOffset(160, 56), nil, 18, 5)
	container.LayoutOrder = order
	gradient(panel, C_WHITE, C_CREAM_SOFT, 90)

	-- Kilap atas (biar terasa seperti tombol plastik, bukan kotak datar)
	local gloss = make("Frame", {
		Size = UDim2.new(1, -12, 0, 12),
		Position = UDim2.fromOffset(6, 5),
		BackgroundColor3 = C_WHITE,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, panel)
	corner(gloss, 6)

	-- Icon badge (lingkaran berwarna)
	local badge = make("Frame", {
		Size = UDim2.fromOffset(38, 38),
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = iconColor,
		ZIndex = 3,
	}, panel)
	corner(badge, 19)
	stroke(badge, C_NAVY, 2.5)
	gradient(badge, C_WHITE, iconColor, 90)

	make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = icon,
		TextSize = 20,
		Font = Enum.Font.FredokaOne,
		TextColor3 = C_WHITE,
		ZIndex = 4,
	}, badge)

	-- Value
	local value = make("TextLabel", {
		Size = UDim2.new(1, -56, 0, 26),
		Position = UDim2.new(0, 52, 0, 5),
		BackgroundTransparency = 1,
		Text = "0",
		TextColor3 = valueColor,
		Font = Enum.Font.FredokaOne,
		TextSize = 21,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, panel)
	local vs = stroke(value, C_WHITE, 1.5)
	vs.Transparency = 0.35

	-- Label
	make("TextLabel", {
		Size = UDim2.new(1, -56, 0, 16),
		Position = UDim2.new(0, 52, 0, 31),
		BackgroundTransparency = 1,
		Text = labelText,
		TextColor3 = C_NAVY,
		Font = Enum.Font.FredokaOne,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, panel)

	return value
end

statValues.Rebirths = makeStatPill("🔄", C_PINK,   "Rebirths", C_PINK,   1)
statValues.Clicks   = makeStatPill("👆", C_BLUE,   "Clicks",   C_BLUE,   2)
statValues.Gems     = makeStatPill("💎", C_PURPLE, "Gems",     C_PURPLE, 3)
statValues.Eggs     = makeStatPill("🥚", C_GOLD,   "Eggs",     C_GOLD,   4)

local function popStat(lbl: TextLabel)
	TweenService:Create(lbl, TweenInfo.new(0.08), { TextSize = 25 }):Play()
	task.delay(0.08, function()
		TweenService:Create(lbl, TweenInfo.new(0.18, Enum.EasingStyle.Back), { TextSize = 21 }):Play()
	end)
end

-- ============================================================
--  SIDEBAR KIRI — 2 KOLOM IKON
-- ============================================================
local sideRoot = make("Frame", {
	Size = UDim2.fromOffset(150, 372),
	Position = UDim2.new(0, 12, 0.5, -20),
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundTransparency = 1,
	ZIndex = 10,
}, gui)

local function makeSideButton(parent: Instance, icon: string, label: string, accent: Color3, order: number): TextButton
	local container = make("Frame", {
		Size = UDim2.fromOffset(64, 84),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	}, parent)

	local shadow = make("Frame", {
		Size = UDim2.fromOffset(58, 58),
		Position = UDim2.fromOffset(3, 4),
		BackgroundColor3 = C_NAVY_DEEP,
		BackgroundTransparency = 0.3,
		ZIndex = 1,
	}, container)
	corner(shadow, 14)

	local btn = make("TextButton", {
		Size = UDim2.fromOffset(58, 58),
		Position = UDim2.fromOffset(3, 0),
		BackgroundColor3 = C_CREAM,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		Selectable = true,
		ZIndex = 2,
	}, container)
	corner(btn, 14)
	stroke(btn, C_NAVY, 3)
	gradient(btn, C_WHITE, C_CREAM_SOFT, 90)

	local badge = make("Frame", {
		Size = UDim2.fromOffset(36, 36),
		Position = UDim2.fromScale(0.5, 0.42),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = accent,
		ZIndex = 3,
	}, btn)
	corner(badge, 11)
	gradient(badge, C_WHITE, accent, 90)

	make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = icon,
		TextSize = 20,
		Font = Enum.Font.FredokaOne,
		ZIndex = 4,
	}, badge)

	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 1, -20),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = C_NAVY,
		Font = Enum.Font.FredokaOne,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
	}, container)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = C_SKY_SOFT }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = C_CREAM }):Play()
	end)
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(container, TweenInfo.new(0.06), { Size = UDim2.fromOffset(58, 78) }):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(container, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(64, 84) }):Play()
	end)

	return btn
end

local colA = make("Frame", {
	Size = UDim2.fromOffset(70, 372),
	Position = UDim2.fromOffset(0, 0),
	BackgroundTransparency = 1,
}, sideRoot)
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, colA)

local colB = make("Frame", {
	Size = UDim2.fromOffset(70, 340),
	Position = UDim2.fromOffset(74, 22),
	BackgroundTransparency = 1,
}, sideRoot)
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, colB)

-- ============================================================
--  BOTTOM — TOMBOL KLIK UTAMA
-- ============================================================
local clickWrap = make("Frame", {
	Size = UDim2.fromOffset(280, 150),
	Position = UDim2.new(0.5, 0, 1, -18),
	AnchorPoint = Vector2.new(0.5, 1),
	BackgroundTransparency = 1,
	ZIndex = 10,
}, gui)

-- Tombol kecil kiri
local smallBtn = make("TextButton", {
	Size = UDim2.fromOffset(64, 64),
	Position = UDim2.fromOffset(4, 78),
	BackgroundColor3 = C_CREAM,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 12,
}, clickWrap)
corner(smallBtn, 18)
stroke(smallBtn, C_NAVY, 3)
gradient(smallBtn, C_WHITE, C_CREAM_SOFT, 90)
make("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "⚡",
	TextSize = 26,
	Font = Enum.Font.FredokaOne,
	ZIndex = 13,
}, smallBtn)

-- Tombol besar utama
local mainShadow = make("Frame", {
	Size = UDim2.fromOffset(128, 128),
	Position = UDim2.fromOffset(76, 14),
	BackgroundColor3 = C_NAVY_DEEP,
	BackgroundTransparency = 0.3,
	ZIndex = 11,
}, clickWrap)
corner(mainShadow, 34)

local mainBtn = make("TextButton", {
	Size = UDim2.fromOffset(128, 128),
	Position = UDim2.fromOffset(76, 8),
	BackgroundColor3 = C_SKY,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	Selectable = true,
	ZIndex = 12,
}, clickWrap)
corner(mainBtn, 34)
stroke(mainBtn, C_NAVY, 4)
gradient(mainBtn, C_SKY_SOFT, C_SKY, 90)

-- Kilap + cincin dalam supaya tombol terlihat timbul
local mainGloss = make("Frame", {
	Size = UDim2.new(1, -26, 0, 34),
	Position = UDim2.fromOffset(13, 9),
	BackgroundColor3 = C_WHITE,
	BackgroundTransparency = 0.45,
	BorderSizePixel = 0,
	ZIndex = 12,
}, mainBtn)
corner(mainGloss, 17)

make("TextLabel", {
	Size = UDim2.new(1, -16, 0, 20),
	Position = UDim2.new(0.5, 0, 1, -26),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	Text = "KLIK",
	TextColor3 = C_NAVY,
	Font = Enum.Font.FredokaOne,
	TextSize = 15,
	ZIndex = 14,
}, mainBtn)

make("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	Position = UDim2.fromOffset(0, -8),
	BackgroundTransparency = 1,
	Text = "👆",
	TextSize = 52,
	Font = Enum.Font.FredokaOne,
	ZIndex = 13,
}, mainBtn)

-- Tombol kecil kanan
local smallBtn2 = make("TextButton", {
	Size = UDim2.fromOffset(64, 64),
	Position = UDim2.fromOffset(212, 78),
	BackgroundColor3 = C_CREAM,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 12,
}, clickWrap)
corner(smallBtn2, 18)
stroke(smallBtn2, C_NAVY, 3)
gradient(smallBtn2, C_WHITE, C_CREAM_SOFT, 90)
make("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "🧪",
	TextSize = 26,
	Font = Enum.Font.FredokaOne,
	ZIndex = 13,
}, smallBtn2)

-- ============================================================
--  EFEK KLIK — selalu muncul di posisi acak, tidak menumpuk
-- ============================================================
local popupLayer = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Active = false,
	ZIndex = 190,
}, gui)

local POPUP_COLORS = { C_GOLD, C_WHITE, C_SKY, C_GREEN, C_PINK }
local MAX_POPUPS = 16
local activePopups = 0

local function viewportSize(): Vector2
	local cam = workspace.CurrentCamera
	if cam then
		return cam.ViewportSize
	end
	return Vector2.new(1280, 720)
end

local function spawnPopup(originX: number?, originY: number?)
	if activePopups >= MAX_POPUPS then
		return
	end
	activePopups += 1

	local vp = viewportSize()
	local px: number
	local py: number

	if originX and originY then
		-- Menyebar di sekitar titik klik (tetap terasa berasal dari klik)
		px = math.clamp(originX + math.random(-120, 120), 70, vp.X - 70)
		py = math.clamp(originY + math.random(-150, -25), 110, vp.Y - 130)
	else
		-- Area acak di tengah layar
		px = math.random(math.floor(vp.X * 0.18), math.floor(vp.X * 0.82))
		py = math.random(math.floor(vp.Y * 0.32), math.floor(vp.Y * 0.72))
	end

	local color = POPUP_COLORS[math.random(1, #POPUP_COLORS)]
	local lbl = make("TextLabel", {
		Size = UDim2.fromOffset(150, 46),
		Position = UDim2.fromOffset(px, py),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = math.random(-14, 14),
		BackgroundTransparency = 1,
		Text = "+1",
		TextColor3 = color,
		Font = Enum.Font.FredokaOne,
		TextSize = math.random(22, 32),
		Active = false,
		ZIndex = 200,
	}, popupLayer)
	local s = stroke(lbl, C_NAVY, 3)
	s.Transparency = 0.1

	-- Cincin kecil yang memancar keluar
	local ring = make("Frame", {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.fromOffset(px, py),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 199,
	}, popupLayer)
	corner(ring, 99)
	local ringStroke = stroke(ring, color, 3)
	ringStroke.Transparency = 0.15

	local driftX = math.random(-50, 50)
	local driftY = math.random(-135, -85)
	local dur = math.random(60, 80) / 100

	TweenService:Create(lbl, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(px + driftX, py + driftY),
		Rotation = lbl.Rotation + math.random(-18, 18),
		TextTransparency = 1,
	}):Play()
	TweenService:Create(s, TweenInfo.new(dur), { Transparency = 1 }):Play()
	TweenService:Create(ring, TweenInfo.new(dur * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(78, 78),
	}):Play()
	TweenService:Create(ringStroke, TweenInfo.new(dur * 0.7), { Transparency = 1 }):Play()

	task.delay(dur + 0.05, function()
		lbl:Destroy()
		ring:Destroy()
		activePopups = math.max(0, activePopups - 1)
	end)
end

local function doClick(originX: number?, originY: number?)
	if ClickEvent then
		ClickEvent:FireServer()
	end
	if _G.SoundFX then
		_G.SoundFX.Play("Click")
	end
	spawnPopup(originX, originY)
	TweenService:Create(mainBtn, TweenInfo.new(0.07), { Size = UDim2.fromOffset(114, 114), Position = UDim2.fromOffset(83, 15) }):Play()
	TweenService:Create(mainShadow, TweenInfo.new(0.07), { Size = UDim2.fromOffset(114, 114), Position = UDim2.fromOffset(83, 20) }):Play()
	task.delay(0.07, function()
		TweenService:Create(mainBtn, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(128, 128), Position = UDim2.fromOffset(76, 8) }):Play()
		TweenService:Create(mainShadow, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(128, 128), Position = UDim2.fromOffset(76, 14) }):Play()
	end)
end

mainBtn.Activated:Connect(function()
	local center = mainBtn.AbsolutePosition + mainBtn.AbsoluteSize * 0.5
	doClick(center.X, center.Y)
end)
smallBtn.Activated:Connect(function() showToast("Auto-Click belum dibuka. Beli di Shop!", false) end)
smallBtn2.Activated:Connect(function() showToast("Potion belum tersedia.", false) end)

-- ============================================================
--  KANAN — REWARDS + IKON KECIL
-- ============================================================
local rightRoot = make("Frame", {
	Size = UDim2.fromOffset(190, 150),
	Position = UDim2.new(1, -16, 0.5, 40),
	AnchorPoint = Vector2.new(1, 0.5),
	BackgroundTransparency = 1,
	ZIndex = 10,
}, gui)

local rewardsShadow = make("Frame", {
	Size = UDim2.fromOffset(186, 54),
	Position = UDim2.fromOffset(2, 5),
	BackgroundColor3 = C_NAVY_DEEP,
	BackgroundTransparency = 0.3,
	ZIndex = 11,
}, rightRoot)
corner(rewardsShadow, 16)

local rewardsBtn = make("TextButton", {
	Size = UDim2.fromOffset(186, 54),
	BackgroundColor3 = C_GREEN,
	Text = "",
	AutoButtonColor = false,
	Active = true,
	ZIndex = 12,
}, rightRoot)
corner(rewardsBtn, 16)
stroke(rewardsBtn, C_NAVY, 3)
gradient(rewardsBtn, C_GREEN, C_GREEN_DARK, 90)

make("TextLabel", {
	Size = UDim2.fromOffset(40, 40),
	Position = UDim2.fromOffset(8, 7),
	BackgroundTransparency = 1,
	Text = "🎁",
	TextSize = 26,
	Font = Enum.Font.FredokaOne,
	ZIndex = 13,
}, rewardsBtn)

make("TextLabel", {
	Size = UDim2.new(1, -54, 1, 0),
	Position = UDim2.fromOffset(52, 0),
	BackgroundTransparency = 1,
	Text = "REWARDS",
	TextColor3 = C_WHITE,
	Font = Enum.Font.FredokaOne,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 13,
}, rewardsBtn)

local miniRow = make("Frame", {
	Size = UDim2.fromOffset(186, 54),
	Position = UDim2.fromOffset(0, 66),
	BackgroundTransparency = 1,
	ZIndex = 11,
}, rightRoot)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 8),
}, miniRow)

local function makeMiniBtn(icon: string, accent: Color3)
	local b = make("TextButton", {
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = C_CREAM,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		ZIndex = 12,
	}, miniRow)
	corner(b, 13)
	stroke(b, C_NAVY, 3)

	local badge = make("Frame", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = accent,
		ZIndex = 13,
	}, b)
	corner(badge, 8)
	gradient(badge, C_WHITE, accent, 90)

	make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = icon,
		TextSize = 15,
		Font = Enum.Font.FredokaOne,
		ZIndex = 14,
	}, badge)
	return b
end

local miniSettings = makeMiniBtn("⚙️", C_PURPLE)
local miniBoard   = makeMiniBtn("🏆", C_GOLD)
local miniInfo    = makeMiniBtn("ℹ️", C_BLUE)

miniSettings.Activated:Connect(function() showToast("Settings segera hadir!", false) end)
miniBoard.Activated:Connect(function() showToast("Leaderboard segera hadir!", false) end)
miniInfo.Activated:Connect(function() showToast("Klik tombol besar untuk menambah Clicks!", false) end)
rewardsBtn.Activated:Connect(function() showToast("Rewards harian segera hadir!", false) end)

-- ============================================================
--  MODAL BUILDER (Cartoon)
-- ============================================================
local openModals: { any } = {}

local function makeModal(title: string, w: number, h: number): (Frame, Frame)
	local shadow = make("Frame", {
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(0, 7),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C_NAVY_DEEP,
		BackgroundTransparency = 0.3,
		Visible = false,
		ZIndex = 300,
	}, gui)
	corner(shadow, 22)

	local modal = make("Frame", {
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = C_CREAM,
		Visible = false,
		ZIndex = 301,
	}, gui)
	corner(modal, 22)
	stroke(modal, C_NAVY, 4)

	-- Header
	local header = make("Frame", {
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = C_SKY_SOFT,
		ZIndex = 302,
	}, modal)
	corner(header, 22)
	gradient(header, C_WHITE, C_SKY_SOFT, 90)

	make("TextLabel", {
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.fromOffset(20, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = C_NAVY,
		Font = Enum.Font.FredokaOne,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 303,
	}, header)

	local closeBtn = make("TextButton", {
		Size = UDim2.fromOffset(38, 38),
		Position = UDim2.new(1, -50, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = C_RED,
		Text = "✕",
		Font = Enum.Font.FredokaOne,
		TextColor3 = C_WHITE,
		TextSize = 18,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 303,
	}, header)
	corner(closeBtn, 12)
	stroke(closeBtn, C_NAVY, 2.5)

	local body = make("Frame", {
		Size = UDim2.new(1, -26, 1, -74),
		Position = UDim2.fromOffset(13, 66),
		BackgroundTransparency = 1,
		ZIndex = 302,
	}, modal)

	local function setVisible(v: boolean)
		modal.Visible = v
		shadow.Visible = v
	end

	closeBtn.Activated:Connect(function() setVisible(false) end)
	closeBtn.MouseButton1Click:Connect(function() setVisible(false) end)

	table.insert(openModals, { modal, shadow } :: any)
	return modal, body
end

local function toggleModal(modal: Frame)
	local showing = not modal.Visible
	for _, pair in ipairs(openModals) do
		(pair :: any)[1].Visible = false
		(pair :: any)[2].Visible = false
	end
	if showing then
		modal.Visible = true
		modal.Position = UDim2.fromScale(0.5, 0.45)
		TweenService:Create(modal, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5, 0.5),
		}):Play()
		-- shadow ikut
		local sh = nil
		for _, pair in ipairs(openModals) do
			if (pair :: any)[1] == modal then sh = (pair :: any)[2] end
		end
		if sh then sh.Visible = true end
	end
end

-- ============================================================
--  MODAL: BACKPACK
-- ============================================================
local bagModal, bagBody = makeModal("🎒  My Backpack", 500, 420)

local capLabel = make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundTransparency = 1,
	Text = "Capacity: 0 / 20",
	TextColor3 = C_NAVY,
	Font = Enum.Font.FredokaOne,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 303,
}, bagBody)

local bagScroll = make("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -32),
	Position = UDim2.fromOffset(0, 30),
	BackgroundColor3 = C_SKY_SOFT,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 6,
	ZIndex = 303,
}, bagBody)
corner(bagScroll, 14)
stroke(bagScroll, C_NAVY, 2.5)
make("UIGridLayout", { CellSize = UDim2.fromOffset(104, 104), CellPadding = UDim2.fromOffset(8, 8) }, bagScroll)
make("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
}, bagScroll)

local function renderBackpack()
	for _, c in ipairs(bagScroll:GetChildren()) do
		if c:IsA("GuiObject") and not c:IsA("UIGridLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
	local total = 0
	for petName, count in pairs(items) do
		total += count
		local slot = make("Frame", {
			BackgroundColor3 = C_CREAM,
			ZIndex = 304,
		}, bagScroll)
		corner(slot, 12)
		stroke(slot, C_NAVY, 2.5)

		make("TextLabel", {
			Size = UDim2.fromOffset(44, 44),
			Position = UDim2.new(0.5, 0, 0, 10),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = "🐾",
			TextSize = 26,
			Font = Enum.Font.FredokaOne,
			ZIndex = 305,
		}, slot)

		make("TextLabel", {
			Size = UDim2.new(1, -6, 0, 18),
			Position = UDim2.new(0, 3, 1, -38),
			BackgroundTransparency = 1,
			Text = petName,
			TextColor3 = C_NAVY,
			Font = Enum.Font.FredokaOne,
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 305,
		}, slot)

		make("TextLabel", {
			Size = UDim2.new(1, -6, 0, 16),
			Position = UDim2.new(0, 3, 1, -19),
			BackgroundTransparency = 1,
			Text = "x" .. count,
			TextColor3 = C_GOLD,
			Font = Enum.Font.FredokaOne,
			TextSize = 13,
			ZIndex = 305,
		}, slot)
	end
	capLabel.Text = string.format("Capacity: %d / %d", total, capacity)
end

-- ============================================================
--  MODAL: TRADE
-- ============================================================
local tradeModal, tradeBody = makeModal("🔄  Direct Trade", 560, 430)

local function makeTradeCol(title: string, xPos: number, w: number): ScrollingFrame
	make("TextLabel", {
		Size = UDim2.new(0, w, 0, 22),
		Position = UDim2.fromOffset(xPos, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = C_NAVY,
		Font = Enum.Font.FredokaOne,
		TextSize = 14,
		ZIndex = 303,
	}, tradeBody)

	local s = make("ScrollingFrame", {
		Size = UDim2.new(0, w, 0, 200),
		Position = UDim2.fromOffset(xPos, 26),
		BackgroundColor3 = C_SKY_SOFT,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5,
		ZIndex = 303,
	}, tradeBody)
	corner(s, 12)
	stroke(s, C_NAVY, 2.5)
	make("UIListLayout", { Padding = UDim.new(0, 4) }, s)
	make("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
	}, s)
	return s
end

local playerCol = makeTradeCol("1. Pilih Player", 0, 168)
local itemCol   = makeTradeCol("2. Pet (Opsional)", 180, 168)

make("TextLabel", {
	Size = UDim2.new(0, 180, 0, 22),
	Position = UDim2.fromOffset(360, 0),
	BackgroundTransparency = 1,
	Text = "3. Clicks (Opsional)",
	TextColor3 = C_NAVY,
	Font = Enum.Font.FredokaOne,
	TextSize = 14,
	ZIndex = 303,
}, tradeBody)

local tradeInput = make("TextBox", {
	Size = UDim2.new(0, 170, 0, 42),
	Position = UDim2.fromOffset(360, 26),
	BackgroundColor3 = C_SKY_SOFT,
	TextColor3 = C_NAVY,
	PlaceholderText = "0",
	PlaceholderColor3 = Color3.fromRGB(140, 150, 180),
	Text = "",
	Font = Enum.Font.FredokaOne,
	TextSize = 16,
	ClearTextOnFocus = false,
	Active = true,
	ZIndex = 303,
}, tradeBody)
corner(tradeInput, 12)
stroke(tradeInput, C_NAVY, 2.5)

tradeInput:GetPropertyChangedSignal("Text"):Connect(function()
	tradeInput.Text = tradeInput.Text:gsub("%D", "")
end)

local tradeStatus = make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 22),
	Position = UDim2.new(0, 0, 1, -80),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = C_NAVY,
	Font = Enum.Font.FredokaOne,
	TextSize = 13,
	ZIndex = 303,
}, tradeBody)

local sendTradeBtn = make("TextButton", {
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.new(0, 0, 1, -52),
	BackgroundColor3 = C_GREEN,
	Text = "KIRIM PENAWARAN",
	Font = Enum.Font.FredokaOne,
	TextColor3 = C_WHITE,
	TextSize = 18,
	AutoButtonColor = false,
	Active = true,
	ZIndex = 303,
}, tradeBody)
corner(sendTradeBtn, 14)
stroke(sendTradeBtn, C_NAVY, 3)
gradient(sendTradeBtn, C_GREEN, C_GREEN_DARK, 90)

local function renderTradePlayers()
	for _, c in ipairs(playerCol:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
	end
	local count = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			count += 1
			local b = make("TextButton", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = C_CREAM,
				Text = p.Name,
				Font = Enum.Font.FredokaOne,
				TextColor3 = C_NAVY,
				TextSize = 13,
				AutoButtonColor = false,
				Active = true,
				ZIndex = 304,
			}, playerCol)
			corner(b, 8)
			stroke(b, C_NAVY, 2)
			b.Activated:Connect(function()
				selectedTarget = p.UserId
				tradeStatus.Text = "Target: " .. p.Name
			end)
		end
	end
	if count == 0 then
		make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			Text = "Tidak ada player lain",
			TextColor3 = Color3.fromRGB(140, 150, 180),
			Font = Enum.Font.FredokaOne,
			TextSize = 12,
			ZIndex = 304,
		}, playerCol)
	end
end

local function renderTradeItems()
	for _, c in ipairs(itemCol:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	local noneBtn = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = C_CREAM,
		Text = "(Tanpa Pet)",
		Font = Enum.Font.FredokaOne,
		TextColor3 = C_NAVY,
		TextSize = 13,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 304,
	}, itemCol)
	corner(noneBtn, 8)
	stroke(noneBtn, C_NAVY, 2)
	noneBtn.Activated:Connect(function()
		selectedItem = nil
		tradeStatus.Text = "Item: Tanpa Pet"
	end)

	for petName, petCount in pairs(items) do
		local b = make("TextButton", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = C_CREAM,
			Text = string.format("%s (x%d)", petName, petCount),
			Font = Enum.Font.FredokaOne,
			TextColor3 = C_NAVY,
			TextSize = 13,
			AutoButtonColor = false,
			Active = true,
			ZIndex = 304,
		}, itemCol)
		corner(b, 8)
		stroke(b, C_NAVY, 2)
		b.Activated:Connect(function()
			selectedItem = petName
			tradeStatus.Text = "Item: " .. petName
		end)
	end
end

sendTradeBtn.Activated:Connect(function()
	if not selectedTarget then
		tradeStatus.Text = "Pilih player dulu!"
		return
	end
	local amount = math.floor(tonumber(tradeInput.Text) or 0)
	if amount > clicks then
		tradeStatus.Text = "Clicks kamu kurang!"
		return
	end
	if not selectedItem and amount <= 0 then
		tradeStatus.Text = "Isi clicks atau pet!"
		return
	end
	if TradeSend then
		TradeSend:FireServer(selectedTarget, selectedItem or "", amount)
		tradeStatus.Text = "Mengirim trade..."
	end
end)

-- ============================================================
--  MODAL: EGG GACHA
-- ============================================================
local eggModal, eggBody = makeModal("🥚  Egg Shop & Gacha", 540, 470)
local activeEggId = "Basic"

local eggTabs = make("Frame", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundTransparency = 1,
	ZIndex = 303,
}, eggBody)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, eggTabs)

local eggCard = make("Frame", {
	Size = UDim2.new(1, 0, 0, 250),
	Position = UDim2.fromOffset(0, 48),
	BackgroundColor3 = C_SKY_SOFT,
	ZIndex = 303,
}, eggBody)
corner(eggCard, 16)
stroke(eggCard, C_NAVY, 2.5)

local eggIconBox = make("Frame", {
	Size = UDim2.fromOffset(72, 72),
	Position = UDim2.fromOffset(14, 14),
	BackgroundColor3 = C_GOLD,
	ZIndex = 304,
}, eggCard)
corner(eggIconBox, 16)
stroke(eggIconBox, C_NAVY, 2.5)
gradient(eggIconBox, C_WHITE, C_GOLD, 90)

make("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "🥚",
	TextSize = 38,
	Font = Enum.Font.FredokaOne,
	ZIndex = 305,
}, eggIconBox)

local eggTitle = make("TextLabel", {
	Size = UDim2.new(1, -104, 0, 28),
	Position = UDim2.fromOffset(96, 16),
	BackgroundTransparency = 1,
	Text = "Basic Egg",
	TextColor3 = C_NAVY,
	Font = Enum.Font.FredokaOne,
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 304,
}, eggCard)

local eggCost = make("TextLabel", {
	Size = UDim2.new(1, -104, 0, 24),
	Position = UDim2.fromOffset(96, 44),
	BackgroundTransparency = 1,
	Text = "Cost: 250 Clicks",
	TextColor3 = C_GOLD,
	Font = Enum.Font.FredokaOne,
	TextSize = 17,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 304,
}, eggCard)

local eggOdds = make("ScrollingFrame", {
	Size = UDim2.new(1, -26, 0, 140),
	Position = UDim2.fromOffset(13, 96),
	BackgroundColor3 = C_CREAM,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 5,
	ZIndex = 304,
}, eggCard)
corner(eggOdds, 12)
stroke(eggOdds, C_NAVY, 2)
make("UIListLayout", { Padding = UDim.new(0, 4) }, eggOdds)
make("UIPadding", {
	PaddingTop = UDim.new(0, 6),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 6),
}, eggOdds)

local hatch1x = make("TextButton", {
	Size = UDim2.new(0.48, 0, 0, 54),
	Position = UDim2.new(0, 0, 1, -56),
	BackgroundColor3 = C_GREEN,
	Text = "HATCH 1X",
	Font = Enum.Font.FredokaOne,
	TextColor3 = C_WHITE,
	TextSize = 19,
	AutoButtonColor = false,
	Active = true,
	Selectable = true,
	ZIndex = 350,
}, eggBody)
corner(hatch1x, 14)
stroke(hatch1x, C_NAVY, 3)
gradient(hatch1x, C_GREEN, C_GREEN_DARK, 90)

local hatch3x = make("TextButton", {
	Size = UDim2.new(0.48, 0, 0, 54),
	Position = UDim2.new(0.52, 0, 1, -56),
	BackgroundColor3 = C_GOLD,
	Text = "HATCH 3X",
	Font = Enum.Font.FredokaOne,
	TextColor3 = C_NAVY,
	TextSize = 19,
	AutoButtonColor = false,
	Active = true,
	Selectable = true,
	ZIndex = 350,
}, eggBody)
corner(hatch3x, 14)
stroke(hatch3x, C_NAVY, 3)
gradient(hatch3x, C_WHITE, C_GOLD, 90)

local function displayEgg(eggId: string)
	local d = EGG_DATABASE[eggId] or EGG_DATABASE.Basic
	activeEggId = eggId
	eggTitle.Text = d.Title
	eggCost.Text = "Cost: " .. formatNumber(d.Cost) .. " Clicks"
	hatch1x.Text = "HATCH 1X  (" .. formatNumber(d.Cost) .. ")"
	hatch3x.Text = "HATCH 3X  (" .. formatNumber(d.Cost * 3) .. ")"

	for _, c in ipairs(eggOdds:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	for _, pet in ipairs(d.Pets) do
		local row = make("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			ZIndex = 305,
		}, eggOdds)

		local col = RARITY_COLORS[pet.Rarity] or C_NAVY

		make("TextLabel", {
			Size = UDim2.new(0.62, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = pet.Name .. "  (" .. pet.Stat .. ")",
			TextColor3 = C_NAVY,
			Font = Enum.Font.FredokaOne,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 306,
		}, row)

		make("TextLabel", {
			Size = UDim2.new(0.38, 0, 1, 0),
			Position = UDim2.new(0.62, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = pet.Chance .. "  " .. pet.Rarity,
			TextColor3 = col,
			Font = Enum.Font.FredokaOne,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 306,
		}, row)
	end
end

for _, id in ipairs({ "Basic", "Forest", "Mythic", "Divine" }) do
	local b = make("TextButton", {
		Size = UDim2.new(0.23, 0, 1, 0),
		BackgroundColor3 = C_CREAM,
		Text = id,
		Font = Enum.Font.FredokaOne,
		TextColor3 = C_NAVY,
		TextSize = 14,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 304,
	}, eggTabs)
	corner(b, 10)
	stroke(b, C_NAVY, 2.5)
	b.Activated:Connect(function() displayEgg(id) end)
end

-- ============================================================
--  MODAL: ADMIN DEBUG PANEL
-- ============================================================
local adminModal, adminBody = makeModal("🛠️  Admin Debug Panel", 500, 420)

local adminScroll = make("ScrollingFrame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 5,
	ZIndex = 303,
}, adminBody)
make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, adminScroll)
make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, adminScroll)

local function makeAdminSectionTitle(text: string, order: number)
	return make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = C_NAVY,
		Font = Enum.Font.FredokaOne,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order,
		ZIndex = 304,
	}, adminScroll)
end

local function makeAdminRow(order: number): Frame
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		ZIndex = 304,
	}, adminScroll)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	return row
end

local function requestCurrency(currType: string, amount: number)
	local rem = getRemote("AdminGiveCurrencyFunction")
	if not rem then
		showToast("Admin Remote belum siap!", true)
		return
	end
	task.spawn(function()
		local res = rem:InvokeServer(currType, amount)
		if res and res.Success then
			showToast(res.Message, false)
			if _G.SoundFX then _G.SoundFX.Play("Reward") end
		else
			showToast(res and res.Message or "Gagal menambah currency.", true)
		end
	end)
end

local function makeAdminBtn(parent: Instance, label: string, color: Color3, onClick: () -> ())
	local b = make("TextButton", {
		Size = UDim2.new(0.23, 0, 1, 0),
		BackgroundColor3 = color,
		Text = label,
		Font = Enum.Font.FredokaOne,
		TextColor3 = C_WHITE,
		TextSize = 13,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 305,
	}, parent)
	corner(b, 10)
	stroke(b, C_NAVY, 2)
	b.Activated:Connect(onClick)
	return b
end

-- Section 1: Instant Clicks
makeAdminSectionTitle("⚡ INSTANT CLICKS (COINS)", 1)
local clicksRow = makeAdminRow(2)
makeAdminBtn(clicksRow, "+100K", C_BLUE, function() requestCurrency("Clicks", 100000) end)
makeAdminBtn(clicksRow, "+1M", C_BLUE, function() requestCurrency("Clicks", 1000000) end)
makeAdminBtn(clicksRow, "+50M", C_BLUE, function() requestCurrency("Clicks", 50000000) end)
makeAdminBtn(clicksRow, "+1B", C_BLUE, function() requestCurrency("Clicks", 1000000000) end)

-- Section 2: Gems & Rebirths
makeAdminSectionTitle("💎 GEMS & 🔄 REBIRTHS", 3)
local gemsRow = makeAdminRow(4)
makeAdminBtn(gemsRow, "+10K 💎", C_PURPLE, function() requestCurrency("Gems", 10000) end)
makeAdminBtn(gemsRow, "+1M 💎", C_PURPLE, function() requestCurrency("Gems", 1000000) end)
makeAdminBtn(gemsRow, "+100 🔄", C_PINK, function() requestCurrency("Rebirths", 100) end)
makeAdminBtn(gemsRow, "+10K 🔄", C_PINK, function() requestCurrency("Rebirths", 10000) end)

-- Section 3: Custom Input
makeAdminSectionTitle("✏️ CUSTOM INJECT AMOUNT", 5)
local inputContainer = make("Frame", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = C_CREAM,
	LayoutOrder = 6,
	ZIndex = 304,
}, adminScroll)
corner(inputContainer, 12)
stroke(inputContainer, C_NAVY, 2)

local customInput = make("TextBox", {
	Size = UDim2.new(1, -20, 1, 0),
	Position = UDim2.fromOffset(10, 0),
	BackgroundTransparency = 1,
	PlaceholderText = "Ketik jumlah angka... (misal: 250000)",
	PlaceholderColor3 = Color3.fromRGB(150, 160, 185),
	Text = "",
	Font = Enum.Font.FredokaOne,
	TextColor3 = C_NAVY,
	TextSize = 14,
	ClearTextOnFocus = false,
	ZIndex = 305,
}, inputContainer)

local customActionsRow = makeAdminRow(7)
local function parseInput(): number
	local str = customInput.Text:gsub(",", ""):gsub(" ", "")
	return tonumber(str) or 0
end

local function makeCustomBtn(parent: Instance, label: string, color: Color3, currType: string)
	local b = make("TextButton", {
		Size = UDim2.new(0.31, 0, 1, 0),
		BackgroundColor3 = color,
		Text = label,
		Font = Enum.Font.FredokaOne,
		TextColor3 = C_WHITE,
		TextSize = 13,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 305,
	}, parent)
	corner(b, 10)
	stroke(b, C_NAVY, 2)
	b.Activated:Connect(function()
		local val = parseInput()
		if val <= 0 then
			showToast("Masukkan angka yang valid!", true)
			return
		end
		requestCurrency(currType, val)
	end)
	return b
end

makeCustomBtn(customActionsRow, "+ Clicks", C_BLUE, "Clicks")
makeCustomBtn(customActionsRow, "+ Gems", C_PURPLE, "Gems")
makeCustomBtn(customActionsRow, "+ Rebirths", C_PINK, "Rebirths")

make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundTransparency = 1,
	Text = "💡 Klik tombol untuk inject saldo instan tanpa klik manual.",
	Font = Enum.Font.FredokaOne,
	TextColor3 = Color3.fromRGB(120, 130, 160),
	TextSize = 12,
	LayoutOrder = 8,
	ZIndex = 304,
}, adminScroll)

-- ============================================================
--  CUTSCENE HATCH
-- ============================================================
local cutscene = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(10, 15, 35),
	BackgroundTransparency = 0.35,
	Visible = false,
	ZIndex = 600,
}, gui)

local cutEgg = make("TextLabel", {
	Size = UDim2.fromOffset(140, 140),
	Position = UDim2.fromScale(0.5, 0.45),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Text = "🥚",
	TextSize = 110,
	Font = Enum.Font.FredokaOne,
	ZIndex = 602,
}, cutscene)

local revealShadow = make("Frame", {
	Size = UDim2.fromOffset(280, 330),
	Position = UDim2.fromScale(0.5, 0.5) + UDim2.fromOffset(0, 8),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = C_NAVY_DEEP,
	BackgroundTransparency = 0.3,
	Visible = false,
	ZIndex = 604,
}, cutscene)
corner(revealShadow, 22)

local revealCard = make("Frame", {
	Size = UDim2.fromOffset(280, 330),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = C_CREAM,
	Visible = false,
	ZIndex = 605,
}, cutscene)
corner(revealCard, 22)
local revealStroke = stroke(revealCard, C_NAVY, 4)

local revealIcon = make("Frame", {
	Size = UDim2.fromOffset(84, 84),
	Position = UDim2.new(0.5, 0, 0, 22),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = C_SKY_SOFT,
	ZIndex = 606,
}, revealCard)
corner(revealIcon, 18)
stroke(revealIcon, C_NAVY, 3)

make("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "🐾",
	TextSize = 40,
	Font = Enum.Font.FredokaOne,
	ZIndex = 607,
}, revealIcon)

local revealName = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 30),
	Position = UDim2.fromOffset(10, 120),
	BackgroundTransparency = 1,
	Text = "Dog",
	TextColor3 = C_NAVY,
	Font = Enum.Font.FredokaOne,
	TextSize = 24,
	ZIndex = 606,
}, revealCard)

local revealRarity = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 24),
	Position = UDim2.fromOffset(10, 154),
	BackgroundTransparency = 1,
	Text = "COMMON",
	TextColor3 = C_NAVY,
	Font = Enum.Font.FredokaOne,
	TextSize = 16,
	ZIndex = 606,
}, revealCard)

local revealStat = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 24),
	Position = UDim2.fromOffset(10, 184),
	BackgroundTransparency = 1,
	Text = "Multiplier: x1.2",
	TextColor3 = C_GREEN_DARK,
	Font = Enum.Font.FredokaOne,
	TextSize = 16,
	ZIndex = 606,
}, revealCard)

local claimBtn = make("TextButton", {
	Size = UDim2.new(1, -40, 0, 50),
	Position = UDim2.new(0.5, 0, 1, -22),
	AnchorPoint = Vector2.new(0.5, 1),
	BackgroundColor3 = C_GREEN,
	Text = "AWESOME!",
	Font = Enum.Font.FredokaOne,
	TextColor3 = C_WHITE,
	TextSize = 20,
	AutoButtonColor = false,
	Active = true,
	ZIndex = 606,
}, revealCard)
corner(claimBtn, 14)
stroke(claimBtn, C_NAVY, 3)
gradient(claimBtn, C_GREEN, C_GREEN_DARK, 90)

claimBtn.Activated:Connect(function()
	revealCard.Visible = false
	revealShadow.Visible = false
	cutscene.Visible = false
	isHatching = false
end)

local function hideAllModals()
	for _, pair in ipairs(openModals) do
		pair[1].Visible = false
		pair[2].Visible = false
	end
end

local function playHatch(petData: any)
	isHatching = true
	hideAllModals()
	cutscene.Visible = true
	revealCard.Visible = false
	revealShadow.Visible = false
	cutEgg.Visible = true
	cutEgg.Size = UDim2.fromOffset(140, 140)
	cutEgg.Rotation = 0

	for i = 1, 6 do
		local rot = if i % 2 == 0 then 16 else -16
		TweenService:Create(cutEgg, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
			Rotation = rot,
			Size = UDim2.fromOffset(152, 126),
		}):Play()
		task.wait(0.08)
	end

	TweenService:Create(cutEgg, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
		Size = UDim2.fromOffset(200, 200),
		Rotation = 0,
	}):Play()
	task.wait(0.12)
	cutEgg.Visible = false

	local pName = petData.Name or "Dog"
	local pRarity = petData.Rarity or "Common"
	local pMult = petData.BaseMultiplier or 1.2

	revealName.Text = pName
	revealRarity.Text = pRarity:upper()
	revealStat.Text = "Multiplier: x" .. pMult

	local col = RARITY_COLORS[pRarity] or C_NAVY
	revealStroke.Color = col
	revealRarity.TextColor3 = col

	revealCard.Visible = true
	revealShadow.Visible = true
	revealCard.Size = UDim2.fromOffset(230, 270)
	TweenService:Create(revealCard, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(280, 330),
	}):Play()
end

local function executeHatch(count: number)
	if isHatching then return end
	local d = EGG_DATABASE[activeEggId] or EGG_DATABASE.Basic
	local cost = d.Cost * count

	if clicks < cost then
		showToast("Clicks tidak cukup! Butuh " .. formatNumber(cost) .. ".", true)
		return
	end

	local rf = RS:FindFirstChild("HatchEggFunction")
	if not rf then
		local rem = RS:FindFirstChild("Remotes")
		if rem then rf = rem:FindFirstChild("HatchEggFunction") end
	end
	if not rf then rf = RS:WaitForChild("HatchEggFunction", 3) end
	if not rf then
		local rem = RS:FindFirstChild("Remotes")
		if rem then rf = rem:WaitForChild("HatchEggFunction", 3) end
	end

	if rf and rf:IsA("RemoteFunction") then
		local ok, res = pcall(function()
			return rf:InvokeServer(activeEggId, count)
		end)
		if ok and res and res.Success and res.HatchedPets and #res.HatchedPets > 0 then
			playHatch(res.HatchedPets[1])
		else
			showToast((res and res.Message) or "Gagal gacha telur!", true)
		end
	else
		showToast("Server gacha belum siap, coba lagi...", true)
	end
end

local function bindHatch(btn: TextButton, count: number)
	btn.Activated:Connect(function() executeHatch(count) end)
end
bindHatch(hatch1x, 1)
bindHatch(hatch3x, 3)

-- ============================================================
--  WIRE SIDEBAR BUTTONS
-- ============================================================
local bagBtn   = makeSideButton(colA, "🎒", "Backpack", C_GREEN,  1)
local tradeBtn = makeSideButton(colA, "🤝", "Trade",    C_BLUE,   2)
local eggBtn   = makeSideButton(colA, "🥚", "Eggs",     C_GOLD,   3)
local rebirthB = makeSideButton(colA, "♻️", "Rebirth",  C_PINK,   4)

local petsBtn  = makeSideButton(colB, "🐾", "Pets",     C_PURPLE, 1)
local indexBtn = makeSideButton(colB, "📖", "Index",    C_BLUE,   2)
local questBtn = makeSideButton(colB, "🏅", "Quests",   C_GOLD,   3)
local adminBtn = makeSideButton(colB, "🛠️", "Admin",    C_RED,    4)

local function closeLegacyModals()
	if _G.RebirthHUD and _G.RebirthHUD.CloseAll then
		_G.RebirthHUD.CloseAll()
	end
end

local function openLegacyModal(key: string)
	hideAllModals()
	if _G.RebirthHUD and _G.RebirthHUD.ToggleModal then
		_G.RebirthHUD.ToggleModal(key)
	else
		showToast("Menu " .. key .. " sedang dimuat...", false)
	end
end

bagBtn.Activated:Connect(function()
	closeLegacyModals()
	renderBackpack()
	toggleModal(bagModal)
end)

tradeBtn.Activated:Connect(function()
	closeLegacyModals()
	selectedTarget = nil
	selectedItem = nil
	tradeStatus.Text = ""
	renderTradePlayers()
	renderTradeItems()
	toggleModal(tradeModal)
end)

eggBtn.Activated:Connect(function()
	closeLegacyModals()
	displayEgg("Basic")
	toggleModal(eggModal)
end)

rebirthB.Activated:Connect(function() openLegacyModal("Rebirth") end)
petsBtn.Activated:Connect(function() openLegacyModal("Pets") end)
indexBtn.Activated:Connect(function() openLegacyModal("Index") end)
questBtn.Activated:Connect(function() openLegacyModal("Quests") end)
adminBtn.Activated:Connect(function()
	closeLegacyModals()
	toggleModal(adminModal)
end)

-- ============================================================
--  REMOTE LISTENERS
-- ============================================================
if DataUpdate then
	DataUpdate.OnClientEvent:Connect(function(c: number, cap: number, its: { [string]: number })
		clicks = c or 0
		capacity = cap or 20
		items = its or {}
		statValues.Clicks.Text = formatNumber(clicks)
		if bagModal.Visible then renderBackpack() end
		if tradeModal.Visible then renderTradeItems() end
	end)
end

if TradeIncoming then
	TradeIncoming.OnClientEvent:Connect(function(fromName: string, item: string?, amount: number)
		local desc = (item and item ~= "" and item or "")
		if amount and amount > 0 then
			desc = desc .. (desc ~= "" and " + " or "") .. amount .. " Clicks"
		end
		showToast("Trade dari " .. fromName .. ": " .. desc, false)
	end)
end

if TradeResult then
	TradeResult.OnClientEvent:Connect(function(msg: string)
		tradeStatus.Text = msg
		showToast(msg, msg:find("gagal") ~= nil or msg:find("kurang") ~= nil)
	end)
end

-- World egg prompt
task.spawn(function()
	if not OpenModalEvent then
		local rem = RS:WaitForChild("Remotes", 5)
		if rem then OpenModalEvent = rem:WaitForChild("OpenModalClientEvent", 5) end
		if not OpenModalEvent then OpenModalEvent = RS:WaitForChild("OpenModalClientEvent", 5) end
	end
	if OpenModalEvent then
		OpenModalEvent.OnClientEvent:Connect(function(targetModal: string)
			if targetModal and targetModal:find("EggHatch_") then
				displayEgg(targetModal:gsub("EggHatch_", ""))
				toggleModal(eggModal)
			end
		end)
	end
end)

-- ============================================================
--  BIND LEADERSTATS KE TOP HUD
-- ============================================================
task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 10)
	if not ls then return end

	local function bind(statName: string, label: TextLabel)
		local v = ls:WaitForChild(statName, 5)
		if not v then return end
		local animate = statName ~= "Clicks" -- Clicks update terlalu sering, hindari tween spam
		local function refresh()
			label.Text = tostring(v.Value)
			if animate then popStat(label) end
		end
		label.Text = tostring(v.Value)
		v:GetPropertyChangedSignal("Value"):Connect(refresh)
	end

	bind("Clicks", statValues.Clicks)
	bind("Rebirths", statValues.Rebirths)
	bind("Gems", statValues.Gems)
	bind("Eggs", statValues.Eggs)
end)

-- init
displayEgg("Basic")

-- ============================================================
--  KLIK DI MANA SAJA (di luar UI) = klik juga
--  Efek "+1" muncul di sekitar posisi klik, jadi tidak menumpuk.
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if isHatching or cutscene.Visible then
		return
	end
	for _, pair in ipairs(openModals) do
		if pair[1].Visible then
			return
		end
	end
	if _G.RebirthHUD and _G.RebirthHUD.IsAnyOpen and _G.RebirthHUD.IsAnyOpen() then
		return
	end
	local m = UserInputService:GetMouseLocation()
	doClick(m.X, m.Y)
end)

-- ============================================================
--  RESPONSIVE — HUD menyesuaikan ukuran layar (PC / HP / tablet)
-- ============================================================
local scaledRoots: { [Instance]: UIScale } = {}
for _, root in ipairs({ topBar, sideRoot, clickWrap, rightRoot }) do
	scaledRoots[root] = make("UIScale", { Scale = 1 }, root) :: UIScale
end

local function refreshScale()
	local vp = viewportSize()
	local s = math.clamp(vp.X / 1360, 0.68, 1.05)
	for _, us in pairs(scaledRoots) do
		us.Scale = s
	end
end

refreshScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
end

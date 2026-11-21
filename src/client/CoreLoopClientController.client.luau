--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClickRemote = Remotes:WaitForChild("ClickTapEvent") :: RemoteEvent
local SyncPopupRemote = Remotes:WaitForChild("ClickPopupClientEvent") :: RemoteEvent

SyncPopupRemote.OnClientEvent:Connect(function(_rawAmount: number, formattedText: string)
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return end

	local screenGui = playerGui:FindFirstChild("ClickPopupsGui") :: ScreenGui?
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ClickPopupsGui"
		screenGui.IgnoreGuiInset = true
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui
	end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(180, 42)
	local randX = math.random(35, 65) / 100
	local randY = math.random(40, 70) / 100
	label.Position = UDim2.fromScale(randX, randY)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.Text = "+" .. formattedText .. " Clicks!"
	label.TextColor3 = Color3.fromRGB(56, 189, 248)
	label.TextStrokeTransparency = 0.15
	label.TextScaled = true
	label.Parent = screenGui

	local targetPos = UDim2.new(randX, 0, randY, -75)
	local tween = TweenService:Create(
		label,
		TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = targetPos, TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if _G.SoundFX then _G.SoundFX.Play("Click") end
		ClickRemote:FireServer()
	end
end)

print("[CoreLoopClientController] Client controller aktif")

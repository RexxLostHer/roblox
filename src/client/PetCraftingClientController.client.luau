--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("RebirthChampionsConfig"))

local LocalPlayer = Players.LocalPlayer
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local CraftPetRemote = RemotesFolder:WaitForChild("CraftPetFunction") :: RemoteFunction

local SelectedUUIDs: { string } = {}
local CurrentMachineType: "Golden" | "Toxic" | "Galaxy" | "Rainbow" = "Golden"

local function GetCurrentCraftChanceText(): (number, string, Color3)
	local count = #SelectedUUIDs
	local chance = math.clamp(count * 20, 0, 100)
	local color = Color3.fromRGB(239, 68, 68)
	if chance >= 100 then
		color = Color3.fromRGB(34, 197, 94)
	elseif chance >= 60 then
		color = Color3.fromRGB(251, 191, 36)
	end
	return chance, string.format("Craft (%d/5) - %d%% Chance", count, chance), color
end

local function PlayCraftingCutscene(result: any, capsuleFrame: Frame?)
	if not capsuleFrame then return end

	local tierColor = Color3.fromRGB(255, 204, 0)
	if result.NewPet and result.NewPet.Mutation then
		local tierData = Config.MutationTiers and Config.MutationTiers.Tiers and Config.MutationTiers.Tiers[result.NewPet.Mutation]
		if tierData and tierData.Color then
			tierColor = tierData.Color
		end
	end

	local originalPos = capsuleFrame.Position
	for i = 1, 6 do
		local offset = if i % 2 == 0 then 8 else -8
		local shakeTween = TweenService:Create(
			capsuleFrame,
			TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + offset, originalPos.Y.Scale, originalPos.Y.Offset) }
		)
		shakeTween:Play()
		shakeTween.Completed:Wait()
	end
	capsuleFrame.Position = originalPos

	capsuleFrame.Size = UDim2.fromScale(0.75, 0.75)
	capsuleFrame.BackgroundColor3 = if result.CraftSucceeded then tierColor else Color3.fromRGB(185, 28, 28)
	local popTween = TweenService:Create(
		capsuleFrame,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromScale(1.0, 1.0) }
	)
	popTween:Play()
end

local ClientCraftingAPI = {}

function ClientCraftingAPI.OpenMachineUI(machineType: "Golden" | "Toxic" | "Galaxy" | "Rainbow")
	CurrentMachineType = machineType
	table.clear(SelectedUUIDs)
	local _, labelText = GetCurrentCraftChanceText()
	print(string.format("[Crafting UI] Membuka Mesin %s | %s", machineType, labelText))
end

function ClientCraftingAPI.ToggleSelectPet(petUUID: string): boolean
	local existingIndex = table.find(SelectedUUIDs, petUUID)
	if existingIndex then
		table.remove(SelectedUUIDs, existingIndex)
		return false
	end

	if #SelectedUUIDs >= 5 then
		warn("[Crafting UI] Slot penuh! Maksimal 5 Pet.")
		return false
	end

	table.insert(SelectedUUIDs, petUUID)
	return true
end

function ClientCraftingAPI.SubmitCraft(capsuleFrame: Frame?): any
	local result = CraftPetRemote:InvokeServer({
		MachineType = CurrentMachineType,
		SelectedPetUUIDs = SelectedUUIDs,
	})

	if result and result.Success then
		table.clear(SelectedUUIDs)
		PlayCraftingCutscene(result, capsuleFrame)
	end

	if result then
		print("[Crafting Result]:", result.Message)
	end
	return result
end

_G.RebirthCraftingController = ClientCraftingAPI
return ClientCraftingAPI

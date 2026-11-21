--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HatchEggRemote = Remotes:WaitForChild("HatchEggFunction") :: RemoteFunction
local RollAuraRemote = Remotes:WaitForChild("RollAuraFunction") :: RemoteFunction

local IsAutoHatching = false

local function PlayEggHatchAnimation(eggViewportOrFrame: GuiObject?, hatchedPets: { any })
	if eggViewportOrFrame then
		eggViewportOrFrame.Visible = true
		eggViewportOrFrame.Rotation = 0

		for i = 1, 5 do
			local angle = if i % 2 == 0 then 22 else -22
			local shake = TweenService:Create(
				eggViewportOrFrame,
				TweenInfo.new(0.11, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
				{ Rotation = angle }
			)
			shake:Play()
			shake.Completed:Wait()
		end
		eggViewportOrFrame.Rotation = 0
	end

	for _, pet in ipairs(hatchedPets) do
		print(
			string.format(
				"[HATCH] Dapat %s%s %s (%s) | AutoDeleted: %s",
				if pet.IsShiny then "Shiny " else "",
				pet.Mutation,
				pet.Name,
				pet.Rarity,
				tostring(pet.AutoDeleted)
			)
		)
	end
end

local AutoDeleteFilters: { [string]: boolean } = {
	Common = false,
	Rare = false,
	Epic = false,
}

local EggClientAPI = {}

function EggClientAPI.SetAutoDeleteFilter(rarity: string, isDeleted: boolean)
	AutoDeleteFilters[rarity] = isDeleted
end

function EggClientAPI.GetAutoDeleteFilters()
	return AutoDeleteFilters
end

function EggClientAPI.HatchOnce(eggId: string, count: number, eggGuiFrame: GuiObject?)
	local result = HatchEggRemote:InvokeServer(eggId, count, AutoDeleteFilters)
	if result and result.Success then
		if _G.SoundFX then _G.SoundFX.Play("Hatch") end
		PlayEggHatchAnimation(eggGuiFrame, result.HatchedPets)
	elseif result then
		warn("[Egg Hatch]:", result.Message)
	end
	return result
end

function EggClientAPI.SetAutoHatch(enabled: boolean, eggId: string, count: number, eggGuiFrame: GuiObject?)
	IsAutoHatching = enabled
	task.spawn(function()
		while IsAutoHatching do
			local result = HatchEggRemote:InvokeServer(eggId, count, AutoDeleteFilters)
			if not result or not result.Success then
				IsAutoHatching = false
				if result then
					warn("[Auto Hatch Berhenti]:", result.Message)
				end
				break
			end
			PlayEggHatchAnimation(eggGuiFrame, result.HatchedPets)
			task.wait(0.25)
		end
	end)
end

function EggClientAPI.RollAuraOnce()
	local result = RollAuraRemote:InvokeServer()
	if result then
		print("[Auras Machine]:", result.Message)
	end
	return result
end

_G.RebirthEggAndAuraController = EggClientAPI
return EggClientAPI

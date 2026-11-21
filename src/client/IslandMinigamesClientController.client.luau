--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ChopTreeRemote = Remotes:WaitForChild("MinigameChopTreeFunction") :: RemoteFunction
local UpgradeToolRemote = Remotes:WaitForChild("MinigameUpgradeToolFunction") :: RemoteFunction
local MineOreRemote = Remotes:WaitForChild("MinigameMineOreFunction") :: RemoteFunction
local RunDungeonRemote = Remotes:WaitForChild("MinigameRunDungeonFunction") :: RemoteFunction

local MinigameClientAPI = {}

function MinigameClientAPI.ChopTree(treeId: string, isGoldenOrRainbow: boolean?)
	local res = ChopTreeRemote:InvokeServer(treeId, isGoldenOrRainbow)
	if res then
		print("[Felling Minigame]:", res.Message)
	end
	return res
end

function MinigameClientAPI.UpgradeAxeOrPickaxe(toolType: "Axe" | "Pickaxe")
	local res = UpgradeToolRemote:InvokeServer(toolType)
	if res then
		print("[Tool Upgrader]:", res.Message)
	end
	return res
end

function MinigameClientAPI.MineOre(oreId: string)
	local res = MineOreRemote:InvokeServer(oreId)
	if res then
		print("[Mining Minigame]:", res.Message)
	end
	return res
end

function MinigameClientAPI.EnterDungeonFloor(floorNumber: number)
	local res = RunDungeonRemote:InvokeServer(floorNumber)
	if res then
		print("[Sakura Dungeon]:", res.Message)
	end
	return res
end

_G.RebirthMinigamesController = MinigameClientAPI
return MinigameClientAPI

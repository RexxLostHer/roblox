--!strict
local SoundService = game:GetService("SoundService")

local SoundFX = {}

local SoundLibrary: { [string]: { SoundId: string, Volume: number, Pitch: number } } = {
	Click = { SoundId = "rbxassetid://9114223170", Volume = 0.5, Pitch = 1.0 },
	Rebirth = { SoundId = "rbxassetid://9114223846", Volume = 0.7, Pitch = 1.0 },
	Hatch = { SoundId = "rbxassetid://9114224522", Volume = 0.65, Pitch = 1.1 },
	Upgrade = { SoundId = "rbxassetid://9114225211", Volume = 0.6, Pitch = 1.0 },
	Spin = { SoundId = "rbxassetid://9114225798", Volume = 0.6, Pitch = 0.95 },
	Reward = { SoundId = "rbxassetid://9114226388", Volume = 0.75, Pitch = 1.0 },
}

local SoundFolder = SoundService:FindFirstChild("GameSounds") :: Folder?
if not SoundFolder then
	SoundFolder = Instance.new("Folder")
	SoundFolder.Name = "GameSounds"
	SoundFolder.Parent = SoundService
end

function SoundFX.Play(soundName: string)
	local sData = SoundLibrary[soundName]
	if not sData then return end

	local sound = Instance.new("Sound")
	sound.SoundId = sData.SoundId
	sound.Volume = sData.Volume
	sound.PlaybackSpeed = sData.Pitch + (math.random(-5, 5) / 100)
	sound.Parent = SoundFolder
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

_G.SoundFX = SoundFX
return SoundFX

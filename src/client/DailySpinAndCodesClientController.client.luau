--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DailySpinRemote = Remotes:WaitForChild("SpinDailyWheelFunction") :: RemoteFunction
local RedeemCodeRemote = Remotes:WaitForChild("RedeemPromoCodeFunction") :: RemoteFunction
local ClaimGroupChestRemote = Remotes:WaitForChild("ClaimGroupChestFunction") :: RemoteFunction

local SpinAndCodesClientAPI = {}

function SpinAndCodesClientAPI.SpinWheel(wheelFrame: GuiObject?)
	local res = DailySpinRemote:InvokeServer()
	if not res then
		return
	end

	if res.Success and wheelFrame then
		wheelFrame.Rotation = 0
		local sliceAngle = (res.SliceIndex - 1) * 45
		local targetRotation = (360 * 6) + sliceAngle

		local spinTween = TweenService:Create(
			wheelFrame,
			TweenInfo.new(4.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
			{ Rotation = targetRotation }
		)
		spinTween:Play()
		spinTween.Completed:Wait()
	end

	print("[Daily Spin]:", res.Message)
	return res
end

function SpinAndCodesClientAPI.RedeemCode(codeText: string)
	local res = RedeemCodeRemote:InvokeServer(codeText)
	if res then
		print("[Promo Code]:", res.Message)
	end
	return res
end

function SpinAndCodesClientAPI.ClaimGroupChest()
	local res = ClaimGroupChestRemote:InvokeServer()
	if res then
		print("[Group Chest]:", res.Message)
	end
	return res
end

_G.RebirthDailySpinAndCodesAPI = SpinAndCodesClientAPI
return SpinAndCodesClientAPI

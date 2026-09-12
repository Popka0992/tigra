local cloneref = cloneref or function(o) return o end

-- Services.
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))
local workspaceService = cloneref(game:GetService("Workspace"))

local Desync = {}
Desync.__index = Desync

local localPlayer = playersService.LocalPlayer

local DesyncConfig = {
	Enabled = false,
	PosSpoof = true,
	RotSpoof = true,
	Visualize = false,
	OffsetX = 0,
	OffsetY = -2.4,
	OffsetZ = 0,
	RotX = 90,
	RotY = 0,
	RotZ = 0,
	AnimID = "616119360",
	AnimPlaying = false,
	AnimFreeze = false,
	AnimFreezeTime = 0.0
}

local currentAnimTrack = nil
local dummyClone = nil
local realCFrame, realVelocity
local isSpoofed = false
local lastSpoofedCFrame = nil

function Desync:GetConfig()
	return DesyncConfig
end

function Desync:ClearDummy()
	if dummyClone then
		dummyClone:Destroy()
		dummyClone = nil
	end
end

function Desync:SetupDummy()
	self:ClearDummy()
	local char = localPlayer.Character
	if not char then return end

	char.Archivable = true
	dummyClone = char:Clone()
	char.Archivable = false
	dummyClone.Name = "DesyncCharVis"

	local dHum = dummyClone:FindFirstChildOfClass("Humanoid")
	if dHum then
		dHum.PlatformStand = true
		dHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
			pcall(function() dHum:SetStateEnabled(state, false) end)
		end
	end

	for _, v in ipairs(dummyClone:GetDescendants()) do
		if v:IsA("Script") or v:IsA("LocalScript") then
			v:Destroy()
		elseif v:IsA("BasePart") then
			v.CanCollide = false
			v.CanTouch = false
			v.CanQuery = false
			v.Massless = true
			v.Material = Enum.Material.ForceField
			v.Color = Color3.fromRGB(150, 0, 255)
			v.Transparency = (v.Name == "HumanoidRootPart") and 1 or 0.2
		elseif v:IsA("Decal") or v:IsA("Texture") then
			v:Destroy()
		end
	end

	local dHrp = dummyClone:FindFirstChild("HumanoidRootPart")
	if dHrp then
		dHrp.Anchored = true
	end

	dummyClone.Parent = workspaceService.CurrentCamera
end

local function updateDesyncDummyPose(spoofedCFrame)
	if not dummyClone or not localPlayer.Character then return end
	local dHrp = dummyClone:FindFirstChild("HumanoidRootPart")
	local charHrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")

	if dHrp then
		dHrp.CFrame = spoofedCFrame or (charHrp and charHrp.CFrame) or dHrp.CFrame
	end

	for _, motor in ipairs(localPlayer.Character:GetDescendants()) do
		if motor:IsA("Motor6D") then
			local dummyMotor = dummyClone:FindFirstChild(motor.Name, true)
			if dummyMotor and dummyMotor:IsA("Motor6D") then
				dummyMotor.Transform = motor.Transform
			end
		end
	end
end

function Desync:HandleAnimation(state)
	local char = localPlayer.Character
	if not char then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")

	if not state then
		if currentAnimTrack then
			currentAnimTrack:Stop()
			currentAnimTrack:Destroy()
			currentAnimTrack = nil
		end
		return
	end

	if not animator then return end

	local idNumbers = string.match(DesyncConfig.AnimID, "%d+")
	if not idNumbers then return end

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. idNumbers

	pcall(function()
		currentAnimTrack = animator:LoadAnimation(anim)
		currentAnimTrack.Priority = Enum.AnimationPriority.Action4
		currentAnimTrack.Looped = true
		currentAnimTrack:Play()

		if DesyncConfig.AnimFreeze then
			currentAnimTrack:AdjustSpeed(0)
			task.delay(0.05, function()
				if currentAnimTrack then
					currentAnimTrack.TimePosition = DesyncConfig.AnimFreezeTime
				end
			end)
		end
	end)
end

function Desync:Load()
	if workspaceService.CurrentCamera and workspaceService.CurrentCamera:FindFirstChild("DesyncCharVis") then
		workspaceService.CurrentCamera.DesyncCharVis:Destroy()
	end

	localPlayer.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid")
		if DesyncConfig.Visualize then
			task.wait(0.5)
			self:SetupDummy()
		end
		if DesyncConfig.AnimPlaying then
			task.wait(0.5)
			self:HandleAnimation(true)
		end
	end)

	runService.Heartbeat:Connect(function()
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if DesyncConfig.AnimPlaying and currentAnimTrack and char then
			local animator = hum and hum:FindFirstChildOfClass("Animator")
			if animator then
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					if track ~= currentAnimTrack then track:Stop() end
				end
			end
			if DesyncConfig.AnimFreeze then
				currentAnimTrack.TimePosition = DesyncConfig.AnimFreezeTime
			end
		end

		if DesyncConfig.Enabled and (DesyncConfig.PosSpoof or DesyncConfig.RotSpoof) and hrp then
			realCFrame = hrp.CFrame
			realVelocity = hrp.AssemblyLinearVelocity

			local finalCFrame = realCFrame
			if DesyncConfig.PosSpoof then
				finalCFrame = finalCFrame + Vector3.new(DesyncConfig.OffsetX, DesyncConfig.OffsetY, DesyncConfig.OffsetZ)
			end
			if DesyncConfig.RotSpoof then
				finalCFrame = finalCFrame * CFrame.Angles(math.rad(DesyncConfig.RotX), math.rad(DesyncConfig.RotY), math.rad(DesyncConfig.RotZ))
			end

			hrp.CFrame = finalCFrame
			lastSpoofedCFrame = finalCFrame
			isSpoofed = true
		else
			lastSpoofedCFrame = nil
		end
	end)

	runService:BindToRenderStep("DesyncCam", 199, function()
		if dummyClone then
			for _, v in ipairs(dummyClone:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = false
					v.CanTouch = false
				end
			end
		end

		if DesyncConfig.Visualize then
			updateDesyncDummyPose(DesyncConfig.Enabled and lastSpoofedCFrame or nil)
		end

		if isSpoofed and localPlayer.Character and realCFrame then
			local hrp = localPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = realCFrame
				hrp.AssemblyLinearVelocity = realVelocity
				isSpoofed = false
			end
		end
	end)
end

return Desync

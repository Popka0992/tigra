-- Services.
local playersService = game:GetService("Players")
local runService = game:GetService("RunService")

-- Variables.
local localPlayer = playersService.LocalPlayer

---@module Features.Visuals.PlayerVisuals
local PlayerVisuals = {}
PlayerVisuals.__index = PlayerVisuals

-- Constants.
local PARTICLE_AURA_DATA = {
	{ "starlight", "rbxassetid://134645216613107" },
	{ "heavenly", "rbxassetid://139300897520961" },
	{ "ribbon", "rbxassetid://132069507632161" },
	{ "sakura", "rbxassetid://81755778619404" },
	{ "angel", "rbxassetid://97658130917593" },
	{ "wind", "rbxassetid://80694081850877" },
	{ "flow", "rbxassetid://119913533725648" },
	{ "star", "rbxassetid://73754563740680" },
	{ "neon", "rbxassetid://18498709246" },
}

PlayerVisuals.AuraMap = {}
PlayerVisuals.AuraNames = {}
for _, aura in ipairs(PARTICLE_AURA_DATA) do
	PlayerVisuals.AuraMap[aura[1]] = aura[2]
	table.insert(PlayerVisuals.AuraNames, aura[1])
end

PlayerVisuals.Config = {
	Material = {
		MaterialChanger = false,
		CustomMaterialColor = false,
		MaterialColor = Color3.fromRGB(255, 255, 255),
		SelectedMaterial = "ForceField",
		MaterialTransparency = 0
	},
	Aura = {
		enabled = false,
		color = Color3.fromRGB(255, 255, 255),
		selectedAuras = "starlight"
	},
	Avatar = {
		Enabled = false,
		TargetUserId = 0
	},
	Rig = {
		RigType = "Default",
		AnimationPack = "None"
	},
	Dance = {
		CurrentDance = "None",
		Playing = false
	}
}

PlayerVisuals.Dances = {
	["Baby Queen - Bouncy Twirl"] = "14352343065",
	["Floss"] = "10714340543",
	["Yungblud Happier Jump"] = "15609995579",
	["Godlike"] = "10714347256",
	["Mae Stephens - Dance"] = "16553163212",
	["Victory Dance"] = "15505456446",
	["Elton John - Heart Skip"] = "11309255148",
	["Sturdy Dance - Ice Spice"] = "14022830843"
}

PlayerVisuals.DanceNames = {
	"None",
	"Baby Queen - Bouncy Twirl",
	"Floss",
	"Yungblud Happier Jump",
	"Godlike",
	"Mae Stephens - Dance",
	"Victory Dance",
	"Elton John - Heart Skip",
	"Sturdy Dance - Ice Spice"
}

PlayerVisuals.AnimationPacks = {
	["Zombie"] = {
		idle = {"616158929", "616160018"},
		walk = "616168032",
		run = "616163682",
		jump = "616161997",
		fall = "616157476"
	},
	["Ninja"] = {
		idle = {"656111812", "656112999"},
		walk = "656121766",
		run = "656118852",
		jump = "656102624",
		fall = "656097567"
	},
	["Mage"] = {
		idle = {"707838520", "707844054"},
		walk = "707890450",
		run = "707886475",
		jump = "707858682",
		fall = "707829767"
	},
	["Toy"] = {
		idle = {"782841498", "782845736"},
		walk = "782843345",
		run = "782841498", -- TODO: verify, same id as idle[1]
		jump = "782847020",
		fall = "782838421"
	},
	["Oldschool"] = {
		idle = {"531982823", "531983354"},
		walk = "531984793",
		run = "531984432",
		jump = "531984193",
		fall = "531983976"
	},
	["Cartoony"] = {
		idle = {"742633271", "742634040"},
		walk = "742640026",
		run = "742638842",
		jump = "742637942",
		fall = "742637151"
	},
	["Robot"] = {
		idle = {"616088211", "616089859"},
		walk = "616095330",
		run = "616086089",
		jump = "616083070",
		fall = "616080277"
	},
	["Levitation"] = {
		idle = {"616006778", "616008087"},
		walk = "616013216",
		run = "616013216",
		jump = "616008936",
		fall = "616005863"
	}
}

-- R15 body parts hidden while R6 rig is active.
local R15_BODY_PARTS = {
	["Head"] = true,
	["UpperTorso"] = true,
	["LowerTorso"] = true,
	["LeftUpperArm"] = true,
	["LeftLowerArm"] = true,
	["LeftHand"] = true,
	["RightUpperArm"] = true,
	["RightLowerArm"] = true,
	["RightHand"] = true,
	["LeftUpperLeg"] = true,
	["LeftLowerLeg"] = true,
	["LeftFoot"] = true,
	["RightUpperLeg"] = true,
	["RightLowerLeg"] = true,
	["RightFoot"] = true
}

-- State.
local originalPartProperties = {}
local originalDecalTransparency = {}
local originalAnimIds = {}
local auraCache = {}
local currentAuraObject = nil
local auraToken = 0
local currentDanceTrack = nil
local currentDanceAnim = nil
local r6ModelClone = nil
local r6HeartbeatConnection = nil

-- Helpers.
local function getCharacter()
	return localPlayer and localPlayer.Character
end

local function getHumanoid(char)
	char = char or getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(char)
	char = char or getCharacter()
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function getAnimator(humanoid)
	if not humanoid then return nil end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator", humanoid)
	end
	return animator
end

local function setR15Hidden(char, hidden)
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") and R15_BODY_PARTS[part.Name] then
			part.Transparency = hidden and 1 or 0
		end
	end

	local head = char:FindFirstChild("Head")
	local face = head and head:FindFirstChildOfClass("Decal")
	if face then
		face.Transparency = hidden and 1 or 0
	end
end

-- Material Changer.
function PlayerVisuals:SaveOriginalProperties()
	local char = getCharacter()
	if not char then return end

	table.clear(originalPartProperties)
	table.clear(originalDecalTransparency)
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") then
			originalPartProperties[obj] = {
				Material = obj.Material,
				Color = obj.Color,
				Transparency = obj.Transparency
			}
		end
	end
end

function PlayerVisuals:ApplyMaterial()
	local char = getCharacter()
	if not char then return end

	local cfg = self.Config.Material
	if not cfg.MaterialChanger then
		self:RestoreOriginalProperties()
		return
	end

	local matEnum = Enum.Material[cfg.SelectedMaterial] or Enum.Material.ForceField
	local hideR15 = r6ModelClone ~= nil
	local alpha = cfg.MaterialTransparency

	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			local orig = originalPartProperties[obj]
			if not orig then
				orig = {
					Material = obj.Material,
					Color = obj.Color,
					Transparency = obj.Transparency
				}
				originalPartProperties[obj] = orig
			end

			obj.Material = matEnum
			obj.Color = cfg.CustomMaterialColor and cfg.MaterialColor or orig.Color

			if not (hideR15 and R15_BODY_PARTS[obj.Name]) then
				obj.Transparency = alpha
			end
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			-- Лицо под R6 остаётся скрытым, его трогать нельзя.
			if hideR15 and obj.Parent and obj.Parent.Name == "Head" then
				continue
			end

			if originalDecalTransparency[obj] == nil then
				originalDecalTransparency[obj] = obj.Transparency
			end
			obj.Transparency = alpha
		end
	end
end

function PlayerVisuals:RestoreOriginalProperties()
	local char = getCharacter()
	if not char then return end

	for part, props in pairs(originalPartProperties) do
		if part and part.Parent then
			part.Material = props.Material
			part.Color = props.Color
			part.Transparency = props.Transparency
		end
	end
	table.clear(originalPartProperties)

	for decal, t in pairs(originalDecalTransparency) do
		if decal and decal.Parent then
			decal.Transparency = t
		end
	end
	table.clear(originalDecalTransparency)

	if r6ModelClone then
		setR15Hidden(char, true)
	end
end

-- Avatar Cloner.
local function weldAccessory(char, acc)
	local handle = acc:FindFirstChild("Handle")
	if not handle then return end
	handle.CanCollide = false

	local handleAttachment = handle:FindFirstChildOfClass("Attachment")
	if handleAttachment then
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") then
				local charAtt = part:FindFirstChild(handleAttachment.Name)
				if charAtt and charAtt:IsA("Attachment") then
					local weld = Instance.new("Weld")
					weld.Name = "AccessoryWeld"
					weld.Part0 = handle
					weld.Part1 = part
					weld.C0 = handleAttachment.CFrame
					weld.C1 = charAtt.CFrame
					weld.Parent = handle
					return
				end
			end
		end
	end

	local head = char:FindFirstChild("Head")
	if head then
		local weld = Instance.new("Weld")
		weld.Name = "AccessoryWeld"
		weld.Part0 = handle
		weld.Part1 = head
		weld.C0 = CFrame.new(0, 0, 0)
		weld.C1 = CFrame.new(0, 0.5, 0)
		weld.Parent = handle
	end
end

local function applyModelToCharacter(char, sourceModel)
	if not char or not sourceModel then return end

	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
			item:Destroy()
		end
	end

	local oldBodyColors = char:FindFirstChildOfClass("BodyColors")
	if oldBodyColors then
		oldBodyColors:Destroy()
	end

	local newBodyColors = sourceModel:FindFirstChildOfClass("BodyColors")
	if newBodyColors then
		local clonedColors = newBodyColors:Clone()
		clonedColors.Parent = char

		local colorMap = {
			Head = clonedColors.HeadColor3,
			Torso = clonedColors.TorsoColor3,
			UpperTorso = clonedColors.TorsoColor3,
			LowerTorso = clonedColors.TorsoColor3,
			["Left Arm"] = clonedColors.LeftArmColor3,
			LeftUpperArm = clonedColors.LeftArmColor3,
			LeftLowerArm = clonedColors.LeftArmColor3,
			LeftHand = clonedColors.LeftArmColor3,
			["Right Arm"] = clonedColors.RightArmColor3,
			RightUpperArm = clonedColors.RightArmColor3,
			RightLowerArm = clonedColors.RightArmColor3,
			RightHand = clonedColors.RightArmColor3,
			["Left Leg"] = clonedColors.LeftLegColor3,
			LeftUpperLeg = clonedColors.LeftLegColor3,
			LeftLowerLeg = clonedColors.LeftLegColor3,
			LeftFoot = clonedColors.LeftLegColor3,
			["Right Leg"] = clonedColors.RightLegColor3,
			RightUpperLeg = clonedColors.RightLegColor3,
			RightLowerLeg = clonedColors.RightLegColor3,
			RightFoot = clonedColors.RightLegColor3,
		}
		for partName, col in pairs(colorMap) do
			local p = char:FindFirstChild(partName)
			if p and p:IsA("BasePart") then
				p.Color = col
			end
		end
	end

	for _, item in ipairs(sourceModel:GetChildren()) do
		if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
			item:Clone().Parent = char
		end
	end

	local sourceHead = sourceModel:FindFirstChild("Head")
	local charHead = char:FindFirstChild("Head")
	if sourceHead and charHead then
		local srcFace = sourceHead:FindFirstChild("face")
		local charFace = charHead:FindFirstChild("face")
		if srcFace and srcFace:IsA("Decal") then
			if not charFace then
				charFace = Instance.new("Decal")
				charFace.Name = "face"
				charFace.Parent = charHead
			end
			charFace.Texture = srcFace.Texture
		end

		local srcMesh = sourceHead:FindFirstChildOfClass("SpecialMesh")
		local charMesh = charHead:FindFirstChildOfClass("SpecialMesh")
		if srcMesh and charMesh then
			charMesh.MeshId = srcMesh.MeshId
			charMesh.TextureId = srcMesh.TextureId
			charMesh.Scale = srcMesh.Scale
		end
	end

	for _, item in ipairs(sourceModel:GetChildren()) do
		if item:IsA("Accessory") then
			local acc = item:Clone()
			acc.Parent = char
			weldAccessory(char, acc)
		end
	end
end

function PlayerVisuals:ApplyAvatar(userId)
	local char = getCharacter()
	if not char then return end

	userId = tonumber(userId)
	if not userId or userId <= 0 then return end

	self.Config.Avatar.TargetUserId = userId
	self.Config.Avatar.Enabled = true

	task.spawn(function()
		local sourceModel = nil

		local success, model = pcall(function()
			return playersService:CreateHumanoidModelFromUserId(userId)
		end)
		if success and model then
			sourceModel = model
		else
			local s2, app = pcall(function()
				return playersService:GetCharacterAppearanceAsync(userId)
			end)
			if s2 and app then
				sourceModel = app
			end
		end

		if sourceModel then
			applyModelToCharacter(char, sourceModel)
			sourceModel:Destroy()
			task.wait(0.1)
			self:ApplyMaterial()
		end
	end)
end

function PlayerVisuals:ResetAvatar()
	local char = getCharacter()
	if not char then return end

	self.Config.Avatar.Enabled = false
	self.Config.Avatar.TargetUserId = 0

	task.spawn(function()
		local success, model = pcall(function()
			return playersService:CreateHumanoidModelFromUserId(localPlayer.UserId)
		end)
		if success and model then
			applyModelToCharacter(char, model)
			model:Destroy()
			task.wait(0.1)
			self:ApplyMaterial()
		end
	end)
end

-- Aura System.
local function loadAuraAsset(assetId)
	if auraCache[assetId] then
		return auraCache[assetId]
	end
	local success, objects = pcall(function()
		return game:GetObjects(assetId)
	end)
	if success and objects and objects[1] then
		auraCache[assetId] = objects[1]
		return objects[1]
	end
	return nil
end

function PlayerVisuals:ClearAuras()
	if currentAuraObject then
		currentAuraObject:Destroy()
		currentAuraObject = nil
	end

	local char = getCharacter()
	if char then
		for _, obj in ipairs(char:GetDescendants()) do
			if obj.Name == "PlayerVisuals_Aura" then
				obj:Destroy()
			end
		end
	end
end

function PlayerVisuals:RefreshAuras()
	self:ClearAuras()

	auraToken = auraToken + 1
	local myToken = auraToken

	local cfg = self.Config.Aura
	if not cfg.enabled then return end

	local char = getCharacter()
	local root = getRootPart(char)
	if not root then return end

	local assetId = self.AuraMap[cfg.selectedAuras]
	if not assetId then return end

	task.spawn(function()
		local asset = loadAuraAsset(assetId)
		if myToken ~= auraToken or not char or not char.Parent then return end
		if not asset then return end

		local auraInstance = asset:Clone()
		auraInstance.Name = "PlayerVisuals_Aura"

		if auraInstance:IsA("Attachment") then
			auraInstance.Parent = root
			currentAuraObject = auraInstance
		else
			local attachment = Instance.new("Attachment")
			attachment.Name = "PlayerVisuals_Aura"
			attachment.Parent = root
			currentAuraObject = attachment

			for _, child in ipairs(auraInstance:GetDescendants()) do
				if child:IsA("ParticleEmitter") then
					child:Clone().Parent = attachment
				end
			end

			if auraInstance:IsA("ParticleEmitter") then
				auraInstance.Parent = attachment
			else
				auraInstance:Destroy()
			end
		end

		if currentAuraObject and cfg.color then
			for _, emitter in ipairs(currentAuraObject:GetDescendants()) do
				if emitter:IsA("ParticleEmitter") then
					emitter.Color = ColorSequence.new(cfg.color)
				end
			end
			if currentAuraObject:IsA("ParticleEmitter") then
				currentAuraObject.Color = ColorSequence.new(cfg.color)
			end
		end
	end)
end

-- R6 Rig.
local function constructR6Model(char)
	local r6 = Instance.new("Model")
	r6.Name = "R6_Visual_Clone"

	local partSizes = {
		Head = Vector3.new(2, 1, 1),
		Torso = Vector3.new(2, 2, 1),
		["Left Arm"] = Vector3.new(1, 2, 1),
		["Right Arm"] = Vector3.new(1, 2, 1),
		["Left Leg"] = Vector3.new(1, 2, 1),
		["Right Leg"] = Vector3.new(1, 2, 1)
	}

	local createdParts = {}
	for name, size in pairs(partSizes) do
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Material = Enum.Material.SmoothPlastic
		part.Parent = r6
		createdParts[name] = part
	end

	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	headMesh.Parent = createdParts.Head

	-- Copy face.
	local realHead = char:FindFirstChild("Head")
	local realFace = realHead and realHead:FindFirstChildOfClass("Decal")
	if realFace then
		local faceClone = realFace:Clone()
		faceClone.Parent = createdParts.Head
	end

	-- Copy body colors.
	local bodyColors = char:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		createdParts.Head.Color = bodyColors.HeadColor3
		createdParts.Torso.Color = bodyColors.TorsoColor3
		createdParts["Left Arm"].Color = bodyColors.LeftArmColor3
		createdParts["Right Arm"].Color = bodyColors.RightArmColor3
		createdParts["Left Leg"].Color = bodyColors.LeftLegColor3
		createdParts["Right Leg"].Color = bodyColors.RightLegColor3
	end

	-- Copy clothes.
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
			item:Clone().Parent = r6
		end
	end

	return r6, createdParts
end

function PlayerVisuals:ApplyRig(rigType)
	self.Config.Rig.RigType = rigType
	local char = getCharacter()
	if not char then return end

	local hum = getHumanoid(char)
	if not hum then return end

	if r6HeartbeatConnection then
		r6HeartbeatConnection:Disconnect()
		r6HeartbeatConnection = nil
	end

	if r6ModelClone then
		r6ModelClone:Destroy()
		r6ModelClone = nil
	end

	if rigType == "R6" and hum.RigType == Enum.HumanoidRigType.R15 then
		local r6Model, r6Parts = constructR6Model(char)
		r6ModelClone = r6Model
		r6ModelClone.Parent = char

		setR15Hidden(char, true)

		local realHead = char:FindFirstChild("Head")
		local upperTorso = char:FindFirstChild("UpperTorso")
		local leftUpperArm = char:FindFirstChild("LeftUpperArm")
		local rightUpperArm = char:FindFirstChild("RightUpperArm")
		local leftUpperLeg = char:FindFirstChild("LeftUpperLeg")
		local rightUpperLeg = char:FindFirstChild("RightUpperLeg")

		r6HeartbeatConnection = runService.RenderStepped:Connect(function()
			if not char.Parent or not r6ModelClone or not r6ModelClone.Parent then
				if r6HeartbeatConnection then
					r6HeartbeatConnection:Disconnect()
					r6HeartbeatConnection = nil
				end
				return
			end

			if realHead and r6Parts.Head then
				r6Parts.Head.CFrame = realHead.CFrame
			end
			if upperTorso and r6Parts.Torso then
				r6Parts.Torso.CFrame = upperTorso.CFrame * CFrame.new(0, -0.2, 0)
			end
			if leftUpperArm and r6Parts["Left Arm"] then
				r6Parts["Left Arm"].CFrame = leftUpperArm.CFrame * CFrame.new(0, -0.4, 0)
			end
			if rightUpperArm and r6Parts["Right Arm"] then
				r6Parts["Right Arm"].CFrame = rightUpperArm.CFrame * CFrame.new(0, -0.4, 0)
			end
			if leftUpperLeg and r6Parts["Left Leg"] then
				r6Parts["Left Leg"].CFrame = leftUpperLeg.CFrame * CFrame.new(0, -0.4, 0)
			end
			if rightUpperLeg and r6Parts["Right Leg"] then
				r6Parts["Right Leg"].CFrame = rightUpperLeg.CFrame * CFrame.new(0, -0.4, 0)
			end
		end)

		if self.Config.Material.MaterialChanger then
			self:ApplyMaterial()
		end
	else
		self:ResetRig()
	end
end

function PlayerVisuals:ResetRig()
	if r6HeartbeatConnection then
		r6HeartbeatConnection:Disconnect()
		r6HeartbeatConnection = nil
	end

	if r6ModelClone then
		r6ModelClone:Destroy()
		r6ModelClone = nil
	end

	local char = getCharacter()
	if char then
		setR15Hidden(char, false)
	end

	self:ApplyMaterial()
end

-- Animation Packs.
local function setAnimId(anim, id)
	if not anim or not anim:IsA("Animation") then return end
	if originalAnimIds[anim] == nil then
		originalAnimIds[anim] = anim.AnimationId
	end
	anim.AnimationId = id
end

local function childOf(parent, name)
	return parent and parent:FindFirstChild(name)
end

function PlayerVisuals:RestoreAnimations()
	for anim, original in pairs(originalAnimIds) do
		if anim.Parent then
			anim.AnimationId = original
		end
	end
	table.clear(originalAnimIds)
end

function PlayerVisuals:ApplyAnimationPack(packName)
	self.Config.Rig.AnimationPack = packName

	if not packName or packName == "None" then
		self:RestoreAnimations()
		return
	end

	local pack = self.AnimationPacks[packName]
	if not pack then return end

	local char = getCharacter()
	local animate = char and char:FindFirstChild("Animate")
	if not animate then return end

	pcall(function()
		local idle = animate:FindFirstChild("idle")
		local walk = animate:FindFirstChild("walk")
		local run = animate:FindFirstChild("run")
		local jump = animate:FindFirstChild("jump")
		local fall = animate:FindFirstChild("fall")

		setAnimId(childOf(idle, "Animation1"), "rbxassetid://" .. pack.idle[1])
		setAnimId(childOf(idle, "Animation2"), "rbxassetid://" .. pack.idle[2])
		setAnimId(childOf(walk, "WalkAnim"), "rbxassetid://" .. pack.walk)
		setAnimId(childOf(run, "RunAnim"), "rbxassetid://" .. pack.run)
		setAnimId(childOf(jump, "JumpAnim"), "rbxassetid://" .. pack.jump)
		setAnimId(childOf(fall, "FallAnim"), "rbxassetid://" .. pack.fall)
	end)
end

-- Dance Emotes.
function PlayerVisuals:StopDance()
	if currentDanceTrack then
		currentDanceTrack:Stop(0.15)
		currentDanceTrack:Destroy()
		currentDanceTrack = nil
	end
	if currentDanceAnim then
		currentDanceAnim:Destroy()
		currentDanceAnim = nil
	end
	self.Config.Dance.CurrentDance = "None"
	self.Config.Dance.Playing = false
end

function PlayerVisuals:PlayDance(danceName)
	self:StopDance()
	if not danceName or danceName == "None" or danceName == "" then return end

	local danceId = self.Dances[danceName]
	if not danceId then return end

	local char = getCharacter()
	local hum = getHumanoid(char)
	local animator = getAnimator(hum)
	if not animator then return end

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(danceId)
	currentDanceAnim = anim

	local success, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)

	if success and track then
		currentDanceTrack = track
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = true
		track:Play(0.1)

		self.Config.Dance.CurrentDance = danceName
		self.Config.Dance.Playing = true
	end
end

-- Reset everything (rig, animations, dance, aura).
function PlayerVisuals:ResetAll()
	self:StopDance()
	self:ResetRig()
	self.Config.Rig.RigType = "Default"
	self:ApplyAnimationPack("None")
	self.Config.Aura.enabled = false
	self:RefreshAuras()
end

-- Lifecycle.
function PlayerVisuals:GetConfig()
	return self.Config.Material, self.Config.Aura, self.Config.Avatar, self.Config.Rig, self.Config.Dance
end

function PlayerVisuals:GetAuraList()
	return self.AuraNames
end

function PlayerVisuals:GetDanceList()
	return self.DanceNames
end

function PlayerVisuals:ApplyAll()
	table.clear(originalAnimIds)
	self:SaveOriginalProperties()

	local cfg = self.Config

	if cfg.Material.MaterialChanger then
		self:ApplyMaterial()
	end

	if cfg.Aura.enabled then
		self:RefreshAuras()
	end

	if cfg.Avatar.Enabled and cfg.Avatar.TargetUserId > 0 then
		self:ApplyAvatar(cfg.Avatar.TargetUserId)
	end

	if cfg.Rig.RigType ~= "Default" then
		self:ApplyRig(cfg.Rig.RigType)
	end

	if cfg.Rig.AnimationPack ~= "None" then
		self:ApplyAnimationPack(cfg.Rig.AnimationPack)
	end

	if cfg.Dance.Playing and cfg.Dance.CurrentDance ~= "None" then
		self:PlayDance(cfg.Dance.CurrentDance)
	end
end

function PlayerVisuals:Load()
	localPlayer.CharacterAdded:Connect(function()
		task.wait(0.65)
		self:ApplyAll()
	end)

	if localPlayer.Character then
		task.spawn(function()
			task.wait(0.65)
			self:ApplyAll()
		end)
	else
		self:SaveOriginalProperties()
	end

	return self
end

return PlayerVisuals

-- Services.
local playersService = cloneref(game:GetService("Players"))
local runService = cloneref(game:GetService("RunService"))

local PlayerVisuals = {}
PlayerVisuals.__index = PlayerVisuals

local localPlayer = playersService.LocalPlayer

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

local ANIMATION_PACKS = {
	["Zombie"] = {
		idle = {"rbxassetid://616158929", "rbxassetid://616160018"},
		walk = "rbxassetid://616168032",
		run = "rbxassetid://616163682",
		jump = "rbxassetid://616161997",
		fall = "rbxassetid://616157476",
		climb = "rbxassetid://616156119"
	},
	["Ninja"] = {
		idle = {"rbxassetid://656117400", "rbxassetid://656118341"},
		walk = "rbxassetid://656121766",
		run = "rbxassetid://656118852",
		jump = "rbxassetid://656117878",
		fall = "rbxassetid://656115606",
		climb = "rbxassetid://656114359"
	},
	["Oldschool"] = {
		idle = {"rbxassetid://531982823", "rbxassetid://531983108"},
		walk = "rbxassetid://531984791",
		run = "rbxassetid://531984432",
		jump = "rbxassetid://531984193",
		fall = "rbxassetid://531983970",
		climb = "rbxassetid://531983503"
	},
	["Mage"] = {
		idle = {"rbxassetid://707742142", "rbxassetid://707817808"},
		walk = "rbxassetid://707897766",
		run = "rbxassetid://707828062",
		jump = "rbxassetid://707853694",
		fall = "rbxassetid://707829752",
		climb = "rbxassetid://707826056"
	},
	["Toy"] = {
		idle = {"rbxassetid://782841498", "rbxassetid://782845399"},
		walk = "rbxassetid://782843345",
		run = "rbxassetid://782842708",
		jump = "rbxassetid://782847020",
		fall = "rbxassetid://782846423",
		climb = "rbxassetid://782843869"
	},
	["Cartoony"] = {
		idle = {"rbxassetid://742637544", "rbxassetid://742638445"},
		walk = "rbxassetid://742639556",
		run = "rbxassetid://742638842",
		jump = "rbxassetid://742637942",
		fall = "rbxassetid://742637719",
		climb = "rbxassetid://742636889"
	},
	["Superhero"] = {
		idle = {"rbxassetid://616111295", "rbxassetid://616113533"},
		walk = "rbxassetid://616122287",
		run = "rbxassetid://616117076",
		jump = "rbxassetid://616115533",
		fall = "rbxassetid://616114627",
		climb = "rbxassetid://616113533"
	},
	["Robot"] = {
		idle = {"rbxassetid://616075485", "rbxassetid://616077812"},
		walk = "rbxassetid://616090535",
		run = "rbxassetid://616086087",
		jump = "rbxassetid://616081944",
		fall = "rbxassetid://616080332",
		climb = "rbxassetid://616073868"
	},
	["Levitation"] = {
		idle = {"rbxassetid://616006778", "rbxassetid://616008987"},
		walk = "rbxassetid://616013216",
		run = "rbxassetid://616010382",
		jump = "rbxassetid://616008987",
		fall = "rbxassetid://616005863",
		climb = "rbxassetid://616003713"
	}
}

PlayerVisuals.AuraNames = {}
local particleAuraIdByName = {}

for _, row in ipairs(PARTICLE_AURA_DATA) do
	table.insert(PlayerVisuals.AuraNames, row[1])
	particleAuraIdByName[row[1]] = row[2]
end

local loadedParticleAuras = {}
local activeParticleAuras = {}

PlayerVisuals.AuraConfig = {
	enabled = false,
	selectedAuras = {},
	color = Color3.fromRGB(133, 220, 255)
}

PlayerVisuals.MaterialConfig = {
	MaterialChanger = false,
	SelectedMaterial = "Neon",
	MaterialColor = Color3.fromRGB(255, 255, 255),
	CustomMaterialColor = false,
	MaterialTransparency = 0
}

PlayerVisuals.AvatarConfig = {
	Enabled = false,
	TargetUserId = 0
}

PlayerVisuals.RigAnimationConfig = {
	RigType = "Default",
	AnimationPack = "None"
}

local originalPartData = {}
local originalTextures = {}
local originalClothing = {}
local originalSurfaceAppearances = {}
local originalAvatarItems = {}

local activeRigClone = nil
local syncConnection = nil
local cloneAnimTracks = {}

local function mapCharacterParts(character)
	local parts = {}
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") then
			parts[child.Name] = child
		end
	end
	return parts
end

local function getParticleAuraTemplate(name)
	local cached = loadedParticleAuras[name]
	if cached then return cached end
	local id = particleAuraIdByName[name]
	if not id then return nil end
	local ok, result = pcall(function()
		local getObj = getobjects or function(uri) return game:GetObjects(uri) end
		return getObj(id)[1]
	end)
	if ok and result then
		loadedParticleAuras[name] = result
		return result
	end
	return nil
end

local function tintParticleSubtree(root, color)
	if not color or not root then return end
	local seq = ColorSequence.new(color)
	local function tintOne(obj)
		pcall(function()
			if obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") then
				obj.Color = seq
			elseif obj:IsA("PointLight") then
				obj.Color = color
			end
		end)
	end
	tintOne(root)
	for _, d in ipairs(root:GetDescendants()) do
		tintOne(d)
	end
end

local function setParticleEmittersEnabledInSubtree(root, enabled)
	if not root then return end
	pcall(function()
		if root:IsA("ParticleEmitter") then
			root.Enabled = enabled
		end
	end)
	for _, d in ipairs(root:GetDescendants()) do
		pcall(function()
			if d:IsA("ParticleEmitter") then
				d.Enabled = enabled
			end
		end)
	end
end

local function applyParticleAuraToCharacter(character, auraName, color)
	local auraObj = getParticleAuraTemplate(auraName)
	if not auraObj then return {} end

	local localParts = mapCharacterParts(character)
	local cloned = auraObj:Clone()
	local created = {}

	for _, part in ipairs(cloned:GetChildren()) do
		local targetPart = localParts[part.Name]
		if targetPart then
			for _, child in ipairs(part:GetChildren()) do
				pcall(function()
					local inst = child:Clone()
					inst.Name = "LarpticAuraParticle"
					inst.Parent = targetPart
					if color then
						tintParticleSubtree(inst, color)
					end
					table.insert(created, inst)
				end)
			end
		end
	end

	pcall(function() cloned:Destroy() end)

	for _, p in ipairs(created) do
		setParticleEmittersEnabledInSubtree(p, true)
	end

	return created
end

local function disableOneAura(auraName)
	if activeParticleAuras[auraName] then
		for _, p in ipairs(activeParticleAuras[auraName]) do
			if p then
				pcall(function() p:Destroy() end)
			end
		end
		activeParticleAuras[auraName] = nil
	end
end

local function isOptionSelected(values, option)
	if type(values) == "table" then
		if values[option] ~= nil then
			return values[option]
		end
		for _, value in ipairs(values) do
			if value == option then
				return true
			end
		end
	end
	return false
end

local function attachAccessory(character, accessory)
	local handle = accessory:FindFirstChild("Handle")
	if not (handle and handle:IsA("BasePart")) then
		accessory.Parent = character
		return
	end

	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true

	for _, weld in ipairs(handle:GetDescendants()) do
		if weld:IsA("JointInstance") or weld:IsA("WeldConstraint") then
			weld:Destroy()
		end
	end

	local handleAttachment = handle:FindFirstChildOfClass("Attachment")
	local targetPart, targetAttachment = nil, nil

	if handleAttachment then
		for _, part in ipairs(character:GetChildren()) do
			if part:IsA("BasePart") then
				local att = part:FindFirstChild(handleAttachment.Name)
				if att and att:IsA("Attachment") then
					targetAttachment = att
					targetPart = part
					break
				end
			end
		end
	end

	if not targetPart then
		targetPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	end

	if targetPart then
		local weld = Instance.new("Weld")
		weld.Name = "AccessoryWeld"
		weld.Part0 = handle
		weld.Part1 = targetPart

		if targetAttachment and handleAttachment then
			weld.C0 = handleAttachment.CFrame
			weld.C1 = targetAttachment.CFrame
			handle.CFrame = targetPart.CFrame * targetAttachment.CFrame * handleAttachment.CFrame:Inverse()
		else
			weld.C0 = CFrame.new()
			weld.C1 = CFrame.new()
			handle.CFrame = targetPart.CFrame
		end

		weld.Parent = handle
	end

	accessory.Parent = character
end

local function stopAllTracks(humanoid)
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			pcall(function()
				track:Stop(0)
				track:Destroy()
			end)
		end
	end
end

local function backupDefaultAvatar(char)
	table.clear(originalAvatarItems)
	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
			table.insert(originalAvatarItems, item:Clone())
		end
	end
	local head = char:FindFirstChild("Head")
	if head then
		local face = head:FindFirstChildOfClass("Decal")
		if face then
			table.insert(originalAvatarItems, face:Clone())
		end
	end
end

function PlayerVisuals:ApplyAnimationPack(packName, targetCharacter)
	local char = targetCharacter or localPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	stopAllTracks(humanoid)

	local animate = char:FindFirstChild("Animate")
	if not animate then return end

	if packName == "None" then
		return
	end

	local pack = ANIMATION_PACKS[packName]
	if not pack then return end

	local function setAnim(folderName, id)
		local folder = animate:FindFirstChild(folderName)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("Animation") then
					child.AnimationId = id
				end
			end
		end
	end

	if pack.idle then
		local idleFolder = animate:FindFirstChild("idle")
		if idleFolder then
			local anim1 = idleFolder:FindFirstChild("Animation1")
			local anim2 = idleFolder:FindFirstChild("Animation2")
			if anim1 and pack.idle[1] then anim1.AnimationId = pack.idle[1] end
			if anim2 and pack.idle[2] then anim2.AnimationId = pack.idle[2] end
		end
	end

	if pack.walk then setAnim("walk", pack.walk) end
	if pack.run then setAnim("run", pack.run) end
	if pack.jump then setAnim("jump", pack.jump) end
	if pack.fall then setAnim("fall", pack.fall) end
	if pack.climb then setAnim("climb", pack.climb) end

	pcall(function()
		animate.Enabled = false
		task.defer(function()
			animate.Enabled = true
		end)
	end)
end

function PlayerVisuals:ResetRig()
	if syncConnection then
		syncConnection:Disconnect()
		syncConnection = nil
	end

	for _, track in pairs(cloneAnimTracks) do
		pcall(function()
			track:Stop(0)
			track:Destroy()
		end)
	end
	table.clear(cloneAnimTracks)

	if activeRigClone then
		activeRigClone:Destroy()
		activeRigClone = nil
	end

	local char = localPlayer.Character
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 0
			elseif part:IsA("Decal") then
				part.Transparency = 0
			end
		end
	end
end

function PlayerVisuals:ApplyRig(rigType)
	self:ResetRig()

	if rigType == "Default" then
		return
	end

	local char = localPlayer.Character
	if not char then return end
	local realRoot = char:FindFirstChild("HumanoidRootPart")
	local realHumanoid = char:FindFirstChildOfClass("Humanoid")
	if not (realRoot and realHumanoid) then return end

	local targetRigEnum = (rigType == "R6") and Enum.HumanoidRigType.R6 or Enum.HumanoidRigType.R15
	local targetUserId = self.AvatarConfig.TargetUserId > 0 and self.AvatarConfig.TargetUserId or localPlayer.UserId

	local desc
	pcall(function()
		desc = playersService:GetHumanoidDescriptionFromUserId(targetUserId)
	end)
	if not desc then
		desc = Instance.new("HumanoidDescription")
	end

	local clone
	local ok = pcall(function()
		clone = playersService:CreateHumanoidModelFromDescription(desc, targetRigEnum)
	end)

	if not (ok and clone) then
		pcall(function()
			clone = playersService:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), targetRigEnum)
		end)
	end

	if not clone then return end

	clone.Name = "VisualRigClone"
	local cloneHumanoid = clone:FindFirstChildOfClass("Humanoid")
	local cloneRoot = clone:FindFirstChild("HumanoidRootPart")

	if not (cloneHumanoid and cloneRoot) then
		clone:Destroy()
		return
	end

	cloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	cloneHumanoid.PlatformStand = false
	cloneRoot.Anchored = true
	cloneRoot.CanCollide = false
	cloneRoot.CanTouch = false
	cloneRoot.CanQuery = false
	cloneRoot.Massless = true

	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
		end
	end

	clone.Parent = workspace
	activeRigClone = clone

	local animator = cloneHumanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", cloneHumanoid)
	local selectedPack = ANIMATION_PACKS[self.RigAnimationConfig.AnimationPack]

	if selectedPack then
		local function loadTrack(id)
			if not id then return nil end
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			local track = animator:LoadAnimation(anim)
			anim:Destroy()
			return track
		end

		cloneAnimTracks.idle = loadTrack(selectedPack.idle and selectedPack.idle[1])
		cloneAnimTracks.walk = loadTrack(selectedPack.walk)
		cloneAnimTracks.jump = loadTrack(selectedPack.jump)
		cloneAnimTracks.fall = loadTrack(selectedPack.fall)
	end

	syncConnection = runService.RenderStepped:Connect(function()
		local currentChar = localPlayer.Character
		if not (currentChar and activeRigClone and activeRigClone.Parent) then
			return
		end

		local cRealRoot = currentChar:FindFirstChild("HumanoidRootPart")
		local cRealHumanoid = currentChar:FindFirstChildOfClass("Humanoid")
		local cCloneRoot = activeRigClone:FindFirstChild("HumanoidRootPart")

		if cRealRoot and cCloneRoot then
			cCloneRoot.CFrame = cRealRoot.CFrame
		end

		if cRealHumanoid and cloneAnimTracks.idle then
			local isMoving = cRealHumanoid.MoveDirection.Magnitude > 0
			local inAir = cRealHumanoid.FloorMaterial == Enum.Material.Air

			if inAir then
				if cloneAnimTracks.walk and cloneAnimTracks.walk.IsPlaying then cloneAnimTracks.walk:Stop(0.1) end
				if cloneAnimTracks.idle and cloneAnimTracks.idle.IsPlaying then cloneAnimTracks.idle:Stop(0.1) end
				if cloneAnimTracks.jump and not cloneAnimTracks.jump.IsPlaying then cloneAnimTracks.jump:Play(0.1) end
			elseif isMoving then
				if cloneAnimTracks.jump and cloneAnimTracks.jump.IsPlaying then cloneAnimTracks.jump:Stop(0.1) end
				if cloneAnimTracks.idle and cloneAnimTracks.idle.IsPlaying then cloneAnimTracks.idle:Stop(0.1) end
				if cloneAnimTracks.walk and not cloneAnimTracks.walk.IsPlaying then cloneAnimTracks.walk:Play(0.1) end
			else
				if cloneAnimTracks.jump and cloneAnimTracks.jump.IsPlaying then cloneAnimTracks.jump:Stop(0.1) end
				if cloneAnimTracks.walk and cloneAnimTracks.walk.IsPlaying then cloneAnimTracks.walk:Stop(0.1) end
				if cloneAnimTracks.idle and not cloneAnimTracks.idle.IsPlaying then cloneAnimTracks.idle:Play(0.1) end
			end
		end

		for _, part in ipairs(currentChar:GetDescendants()) do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 1
			elseif part:IsA("Decal") then
				part.Transparency = 1
			end
		end
	end)
end

function PlayerVisuals:ResetAvatar()
	local char = localPlayer.Character
	if not char then return end

	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
			item:Destroy()
		end
	end

	local head = char:FindFirstChild("Head")
	if head then
		local currentFace = head:FindFirstChildOfClass("Decal")
		if currentFace then
			currentFace:Destroy()
		end
	end

	for _, item in ipairs(originalAvatarItems) do
		local copy = item:Clone()
		if copy:IsA("Accessory") then
			attachAccessory(char, copy)
		elseif copy:IsA("Decal") and head then
			copy.Parent = head
		else
			copy.Parent = char
		end
	end
end

function PlayerVisuals:ApplyAvatar(userId)
	local char = localPlayer.Character
	if not char or not tonumber(userId) then return end
	local targetId = tonumber(userId)

	local targetModel
	local ok = pcall(function()
		targetModel = playersService:CreateHumanoidModelFromUserId(targetId)
	end)

	if not (ok and targetModel) then
		return
	end

	for _, item in ipairs(char:GetChildren()) do
		if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
			item:Destroy()
		end
	end

	local targetColors = targetModel:FindFirstChildOfClass("BodyColors")
	if targetColors then
		targetColors:Clone().Parent = char
	end

	for _, item in ipairs(targetModel:GetChildren()) do
		if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
			item:Clone().Parent = char
		end
	end

	local targetHead = targetModel:FindFirstChild("Head")
	local charHead = char:FindFirstChild("Head")
	if targetHead and charHead then
		local currentFace = charHead:FindFirstChildOfClass("Decal")
		if currentFace then
			currentFace:Destroy()
		end

		local targetFace = targetHead:FindFirstChildOfClass("Decal")
		if targetFace then
			targetFace:Clone().Parent = charHead
		end
	end

	for _, item in ipairs(targetModel:GetChildren()) do
		if item:IsA("Accessory") then
			attachAccessory(char, item:Clone())
		end
	end

	targetModel:Destroy()

	if self.MaterialConfig.MaterialChanger then
		self:ApplyMaterial()
	end
end

function PlayerVisuals:ApplyMaterial()
	local char = localPlayer.Character
	if not char then return end

	local mat = Enum.Material[self.MaterialConfig.SelectedMaterial] or Enum.Material.Neon

	if self.MaterialConfig.MaterialChanger then
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
				if not originalClothing[item] then
					originalClothing[item] = item.Parent
				end
				item.Parent = nil
			end
		end

		for _, obj in ipairs(char:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name == "HumanoidRootPart" then
				continue
			end

			if obj:IsA("SurfaceAppearance") then
				if not originalSurfaceAppearances[obj] then
					originalSurfaceAppearances[obj] = obj.Parent
				end
				obj.Parent = nil
			elseif obj:IsA("BasePart") then
				if not originalPartData[obj] then
					originalPartData[obj] = {
						Material = obj.Material,
						Color = obj.Color,
						Transparency = obj.Transparency
					}
				end

				if obj:IsA("MeshPart") then
					if originalTextures[obj] == nil then
						originalTextures[obj] = obj.TextureID
					end
					obj.TextureID = ""
				end

				local specialMesh = obj:FindFirstChildOfClass("SpecialMesh")
				if specialMesh then
					if originalTextures[specialMesh] == nil then
						originalTextures[specialMesh] = specialMesh.TextureId
					end
					specialMesh.TextureId = ""
				end

				obj.Material = mat
				obj.Transparency = self.MaterialConfig.MaterialTransparency
				if self.MaterialConfig.CustomMaterialColor then
					obj.Color = self.MaterialConfig.MaterialColor
				end
			end
		end
	else
		for item, parent in pairs(originalClothing) do
			if item and parent then
				item.Parent = parent
			end
		end
		table.clear(originalClothing)

		for sa, parent in pairs(originalSurfaceAppearances) do
			if sa and parent then
				sa.Parent = parent
			end
		end
		table.clear(originalSurfaceAppearances)

		for target, texture in pairs(originalTextures) do
			if target and target.Parent then
				if target:IsA("MeshPart") then
					target.TextureID = texture
				elseif target:IsA("SpecialMesh") then
					target.TextureId = texture
				end
			end
		end
		table.clear(originalTextures)

		for part, data in pairs(originalPartData) do
			if part and part.Parent and part:IsA("BasePart") then
				part.Material = data.Material
				part.Color = data.Color
				part.Transparency = data.Transparency
			end
		end
		table.clear(originalPartData)
	end
end

function PlayerVisuals:RefreshAuras()
	local char = localPlayer.Character
	if not char then return end

	if not self.AuraConfig.enabled then
		for _, auraName in ipairs(self.AuraNames) do
			disableOneAura(auraName)
		end
		return
	end

	local selectedAuras = self.AuraConfig.selectedAuras
	for _, auraName in ipairs(self.AuraNames) do
		disableOneAura(auraName)
	end

	local col = self.AuraConfig.color
	if type(selectedAuras) == "table" then
		for _, auraName in ipairs(self.AuraNames) do
			if isOptionSelected(selectedAuras, auraName) then
				task.spawn(function()
					local particles = applyParticleAuraToCharacter(char, auraName, col)
					activeParticleAuras[auraName] = particles
				end)
			end
		end
	elseif type(selectedAuras) == "string" and selectedAuras ~= "" then
		task.spawn(function()
			local particles = applyParticleAuraToCharacter(char, selectedAuras, col)
			activeParticleAuras[selectedAuras] = particles
		end)
	end
end

function PlayerVisuals:GetConfig()
	return self.MaterialConfig, self.AuraConfig, self.AvatarConfig, self.RigAnimationConfig
end

function PlayerVisuals:Load()
	if localPlayer.Character then
		backupDefaultAvatar(localPlayer.Character)
	end

	localPlayer.CharacterAdded:Connect(function(char)
		self:ResetRig()
		table.clear(originalPartData)
		table.clear(originalTextures)
		table.clear(originalClothing)
		table.clear(originalSurfaceAppearances)

		task.wait(0.8)
		backupDefaultAvatar(char)

		if self.AvatarConfig.Enabled and self.AvatarConfig.TargetUserId > 0 then
			self:ApplyAvatar(self.AvatarConfig.TargetUserId)
		end

		if self.RigAnimationConfig.RigType ~= "Default" then
			self:ApplyRig(self.RigAnimationConfig.RigType)
		elseif self.RigAnimationConfig.AnimationPack ~= "None" then
			self:ApplyAnimationPack(self.RigAnimationConfig.AnimationPack)
		end

		if self.MaterialConfig.MaterialChanger then
			self:ApplyMaterial()
		end
		self:RefreshAuras()
	end)
end

return PlayerVisuals

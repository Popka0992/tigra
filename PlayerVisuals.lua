-- Services.
local playersService = cloneref(game:GetService("Players"))

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

local originalPartData = {}
local originalTextures = {}
local originalClothing = {}
local originalSurfaceAppearances = {}

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
	return self.MaterialConfig, self.AuraConfig
end

function PlayerVisuals:Load()
	localPlayer.CharacterAdded:Connect(function()
		table.clear(originalPartData)
		table.clear(originalTextures)
		table.clear(originalClothing)
		table.clear(originalSurfaceAppearances)

		task.wait(0.8)
		if self.MaterialConfig.MaterialChanger then
			self:ApplyMaterial()
		end
		self:RefreshAuras()
	end)
end

return PlayerVisuals

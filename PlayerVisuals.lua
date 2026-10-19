\local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local PlayerVisuals = {}
PlayerVisuals.__index = PlayerVisuals

-- Particle Aura Data
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

-- Config
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

-- Dances Database
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

-- Animation Packs
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
        run = "782841498",
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

-- State
local originalPartProperties = {}
local auraCache = {}
local currentAuraObject = nil
local currentDanceTrack = nil
local currentDanceAnim = nil
local r6ModelClone = nil
local r6HeartbeatConnection = nil

-- Helpers
local function getCharacter()
    return LocalPlayer and LocalPlayer.Character
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

-- Material Changer
function PlayerVisuals:SaveOriginalProperties()
    local char = getCharacter()
    if not char then return end

    table.clear(originalPartProperties)
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

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if not originalPartProperties[part] then
                originalPartProperties[part] = {
                    Material = part.Material,
                    Color = part.Color,
                    Transparency = part.Transparency
                }
            end

            part.Material = matEnum
            if cfg.CustomMaterialColor then
                part.Color = cfg.MaterialColor
            end
            part.Transparency = cfg.MaterialTransparency
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
end

-- Robust Client-Side Avatar Cloner
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

    -- 1. Remove existing visual items
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
            item:Destroy()
        end
    end

    -- 2. Body Colors
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

    -- 3. Clothing
    for _, item in ipairs(sourceModel:GetChildren()) do
        if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
            item:Clone().Parent = char
        end
    end

    -- 4. Head & Face
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

    -- 5. Accessories
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

        -- Primary: CreateHumanoidModelFromUserId
        local success, model = pcall(function()
            return Players:CreateHumanoidModelFromUserId(userId)
        end)
        if success and model then
            sourceModel = model
        else
            -- Fallback: GetCharacterAppearanceAsync
            local s2, app = pcall(function()
                return Players:GetCharacterAppearanceAsync(userId)
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
            return Players:CreateHumanoidModelFromUserId(LocalPlayer.UserId)
        end)
        if success and model then
            applyModelToCharacter(char, model)
            model:Destroy()
            task.wait(0.1)
            self:ApplyMaterial()
        end
    end)
end

-- Aura System
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

    local cfg = self.Config.Aura
    if not cfg.enabled then return end

    local char = getCharacter()
    local root = getRootPart(char)
    if not root then return end

    local assetId = self.AuraMap[cfg.selectedAuras]
    if not assetId then return end

    task.spawn(function()
        local asset = loadAuraAsset(assetId)
        if not asset or not char.Parent then return end

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

-- R6 Rig
local function constructR6Model()
    local r6 = Instance.new("Model")
    r6.Name = "R6_Visual_Clone"

    local parts = {
        HumanoidRootPart = {Size = Vector3.new(2, 2, 1), Trans = 1},
        Torso = {Size = Vector3.new(2, 2, 1), Trans = 0},
        Head = {Size = Vector3.new(1, 1, 1), Trans = 0},
        ["Left Arm"] = {Size = Vector3.new(1, 2, 1), Trans = 0},
        ["Right Arm"] = {Size = Vector3.new(1, 2, 1), Trans = 0},
        ["Left Leg"] = {Size = Vector3.new(1, 2, 1), Trans = 0},
        ["Right Leg"] = {Size = Vector3.new(1, 2, 1), Trans = 0}
    }

    local createdParts = {}
    for partName, data in pairs(parts) do
        local p = Instance.new("Part")
        p.Name = partName
        p.Size = data.Size
        p.Transparency = data.Trans
        p.CanCollide = false
        p.CastShadow = false
        p.Parent = r6
        createdParts[partName] = p
    end

    local headMesh = Instance.new("SpecialMesh")
    headMesh.MeshType = Enum.MeshType.Head
    headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
    headMesh.Parent = createdParts.Head

    local function makeMotor(name, p0, p1, c0, c1)
        local m = Instance.new("Motor6D")
        m.Name = name
        m.Part0 = p0
        m.Part1 = p1
        m.C0 = c0
        m.C1 = c1
        m.Parent = p0
        return m
    end

    makeMotor("RootJoint", createdParts.HumanoidRootPart, createdParts.Torso,
        CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
        CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))

    makeMotor("Neck", createdParts.Torso, createdParts.Head,
        CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
        CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0))

    makeMotor("Left Shoulder", createdParts.Torso, createdParts["Left Arm"],
        CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
        CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

    makeMotor("Right Shoulder", createdParts.Torso, createdParts["Right Arm"],
        CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
        CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))

    makeMotor("Left Hip", createdParts.Torso, createdParts["Left Leg"],
        CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
        CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))

    makeMotor("Right Hip", createdParts.Torso, createdParts["Right Leg"],
        CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
        CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0))

    r6.PrimaryPart = createdParts.HumanoidRootPart
    return r6
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
        r6ModelClone = constructR6Model()
        r6ModelClone.Parent = char

        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = 1
            end
        end

        local originalHrp = char:FindFirstChild("HumanoidRootPart")
        r6HeartbeatConnection = RunService.RenderStepped:Connect(function()
            if not char.Parent or not originalHrp or not r6ModelClone or not r6ModelClone.Parent then
                if r6HeartbeatConnection then
                    r6HeartbeatConnection:Disconnect()
                    r6HeartbeatConnection = nil
                end
                return
            end
            r6ModelClone:SetPrimaryPartCFrame(originalHrp.CFrame)
        end)
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
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = 0
            end
        end
    end

    self:ApplyMaterial()
end

-- Animation Packs
function PlayerVisuals:ApplyAnimationPack(packName)
    self.Config.Rig.AnimationPack = packName
    if packName == "None" or not packName then return end

    local pack = self.AnimationPacks[packName]
    if not pack then return end

    local char = getCharacter()
    local animate = char and char:FindFirstChild("Animate")
    if not animate then return end

    pcall(function()
        if animate:FindFirstChild("idle") then
            local id1 = animate.idle:FindFirstChild("Animation1")
            local id2 = animate.idle:FindFirstChild("Animation2")
            if id1 and pack.idle[1] then id1.AnimationId = "rbxassetid://" .. pack.idle[1] end
            if id2 and pack.idle[2] then id2.AnimationId = "rbxassetid://" .. pack.idle[2] end
        end
        if animate:FindFirstChild("walk") and animate.walk:FindFirstChild("WalkAnim") then
            animate.walk.WalkAnim.AnimationId = "rbxassetid://" .. pack.walk
        end
        if animate:FindFirstChild("run") and animate.run:FindFirstChild("RunAnim") then
            animate.run.RunAnim.AnimationId = "rbxassetid://" .. pack.run
        end
        if animate:FindFirstChild("jump") and animate.jump:FindFirstChild("JumpAnim") then
            animate.jump.JumpAnim.AnimationId = "rbxassetid://" .. pack.jump
        end
        if animate:FindFirstChild("fall") and animate.fall:FindFirstChild("FallAnim") then
            animate.fall.FallAnim.AnimationId = "rbxassetid://" .. pack.fall
        end
    end)
end

-- Dance Emotes
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

-- Lifecycle
function PlayerVisuals:GetConfig()
    return self.Config.Material, self.Config.Aura, self.Config.Avatar, self.Config.Rig, self.Config.Dance
end

function PlayerVisuals:GetAuraList()
    return self.AuraNames
end

function PlayerVisuals:GetDanceList()
    return self.DanceNames
end

function PlayerVisuals:Load()
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.65)
        self:SaveOriginalProperties()

        if self.Config.Material.MaterialChanger then
            self:ApplyMaterial()
        end

        if self.Config.Aura.enabled then
            self:RefreshAuras()
        end

        if self.Config.Avatar.Enabled and self.Config.Avatar.TargetUserId > 0 then
            self:ApplyAvatar(self.Config.Avatar.TargetUserId)
        end

        if self.Config.Rig.RigType ~= "Default" then
            self:ApplyRig(self.Config.Rig.RigType)
        end

        if self.Config.Rig.AnimationPack ~= "None" then
            self:ApplyAnimationPack(self.Config.Rig.AnimationPack)
        end

        if self.Config.Dance.Playing and self.Config.Dance.CurrentDance ~= "None" then
            self:PlayDance(self.Config.Dance.CurrentDance)
        end
    end)

    self:SaveOriginalProperties()
    return self
end

return PlayerVisuals

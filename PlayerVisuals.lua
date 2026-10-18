local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")

local LocalPlayer = Players.LocalPlayer

local PlayerVisuals = {}
PlayerVisuals.__index = PlayerVisuals

-- Config
PlayerVisuals.Config = {
    Material = {
        MaterialChanger = false,
        CustomMaterialColor = false,
        MaterialColor = Color3.fromRGB(255, 255, 255),
        SelectedMaterial = "ForceField",
        MaterialTransparency = 0,
        RemoveTextures = false,
        RemoveDecals = false,
        RemoveClothing = false
    },
    Aura = {
        enabled = false,
        color = Color3.fromRGB(255, 255, 255),
        selectedAuras = "starlight",
        scale = 1
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

-- Dances
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

-- Auras
PlayerVisuals.AuraNames = {
    "starlight",
    "fire",
    "electric",
    "ghostly",
    "galaxy",
    "hearts",
    "rings",
    "frost",
    "blood",
    "divine",
    "toxic",
    "void",
    "cosmic",
    "cyberpunk",
    "sakura",
    "shadow",
    "inferno",
    "blizzard",
    "solar",
    "abyssal",
    "energy_shield",
    "lightning_storm",
    "black_hole"
}

-- Animation Packs
PlayerVisuals.AnimationPacks = {
    ["Zombie"] = {
        idle = {"616158929", "616160018"},
        walk = "616168032",
        run = "616163682",
        jump = "616161997",
        fall = "616157476",
        climb = "616156119",
        swim = "616165109"
    },
    ["Ninja"] = {
        idle = {"656111812", "656112999"},
        walk = "656121766",
        run = "656118852",
        jump = "656102624",
        fall = "656097567",
        climb = "656094524",
        swim = "656115606"
    },
    ["Mage"] = {
        idle = {"707838520", "707844054"},
        walk = "707890450",
        run = "707886475",
        jump = "707858682",
        fall = "707829767",
        climb = "707826056",
        swim = "707878819"
    },
    ["Toy"] = {
        idle = {"782841498", "782845736"},
        walk = "782843345",
        run = "782841498",
        jump = "782847020",
        fall = "782838421",
        climb = "782835825",
        swim = "782842708"
    },
    ["Oldschool"] = {
        idle = {"531982823", "531983354"},
        walk = "531984793",
        run = "531984432",
        jump = "531984193",
        fall = "531983976",
        climb = "531983666",
        swim = "531985225"
    },
    ["Cartoony"] = {
        idle = {"742633271", "742634040"},
        walk = "742640026",
        run = "742638842",
        jump = "742637942",
        fall = "742637151",
        climb = "742636889",
        swim = "742639442"
    },
    ["Robot"] = {
        idle = {"616088211", "616089859"},
        walk = "616095330",
        run = "616086089",
        jump = "616083070",
        fall = "616080277",
        climb = "616079012",
        swim = "616093557"
    },
    ["Levitation"] = {
        idle = {"616006778", "616008087"},
        walk = "616013216",
        run = "616013216",
        jump = "616008936",
        fall = "616005863",
        climb = "616003713",
        swim = "616011509"
    },
    ["Vampire"] = {
        idle = {"1083445855", "1083450166"},
        walk = "1083473930",
        run = "1083462077",
        jump = "1083455352",
        fall = "1083443587",
        climb = "1083439238",
        swim = "1083467475"
    },
    ["Superhero"] = {
        idle = {"616111295", "616113007"},
        walk = "616122287",
        run = "616117076",
        jump = "616115533",
        fall = "616108001",
        climb = "616104706",
        swim = "616119936"
    },
    ["Bubbly"] = {
        idle = {"910004836", "910009958"},
        walk = "910034870",
        run = "910025107",
        jump = "910016857",
        fall = "910001910",
        climb = "909998743",
        swim = "910028158"
    },
    ["Elder"] = {
        idle = {"845397899", "845400528"},
        walk = "845403856",
        run = "845401761",
        jump = "845398858",
        fall = "845396048",
        climb = "845392705",
        swim = "845402693"
    },
    ["Knight"] = {
        idle = {"657595757", "657568135"},
        walk = "657552124",
        run = "657564596",
        jump = "657600338",
        fall = "657593010",
        climb = "657588720",
        swim = "657561840"
    },
    ["Werewolf"] = {
        idle = {"1083195517", "1083214717"},
        walk = "1083178339",
        run = "1083216690",
        jump = "1083204919",
        fall = "1083189019",
        climb = "1083182000",
        swim = "1083200785"
    }
}

-- State
local originalPartProperties = {}
local originalDecalProperties = {}
local originalHumanoidDescription = nil
local originalClothing = {}
local currentAuraAttachment = nil
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
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
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
    table.clear(originalDecalProperties)
    table.clear(originalClothing)

    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            originalPartProperties[obj] = {
                Material = obj.Material,
                Color = obj.Color,
                Transparency = obj.Transparency,
                Reflectance = obj.Reflectance
            }
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            originalDecalProperties[obj] = {
                Transparency = obj.Transparency
            }
        elseif obj:IsA("Clothing") or obj:IsA("ShirtGraphic") then
            table.insert(originalClothing, obj)
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
                    Transparency = part.Transparency,
                    Reflectance = part.Reflectance
                }
            end

            part.Material = matEnum

            if cfg.CustomMaterialColor then
                part.Color = cfg.MaterialColor
            end

            part.Transparency = cfg.MaterialTransparency
        elseif part:IsA("Decal") or part:IsA("Texture") then
            if not originalDecalProperties[part] then
                originalDecalProperties[part] = {
                    Transparency = part.Transparency
                }
            end
            if cfg.RemoveDecals or cfg.RemoveTextures then
                part.Transparency = 1
            else
                if originalDecalProperties[part] then
                    part.Transparency = originalDecalProperties[part].Transparency
                end
            end
        elseif part:IsA("Clothing") or part:IsA("ShirtGraphic") then
            if cfg.RemoveClothing then
                part.Parent = nil
            end
        elseif part:IsA("SurfaceAppearance") then
            if cfg.RemoveTextures then
                part.Parent = nil
            end
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
            part.Reflectance = props.Reflectance
        end
    end

    for decal, props in pairs(originalDecalProperties) do
        if decal and decal.Parent then
            decal.Transparency = props.Transparency
        end
    end

    for _, cloth in ipairs(originalClothing) do
        if cloth and not cloth.Parent then
            cloth.Parent = char
        end
    end

    table.clear(originalPartProperties)
    table.clear(originalDecalProperties)
    table.clear(originalClothing)
end

-- Avatar Changer
function PlayerVisuals:ApplyAvatar(userId)
    local char = getCharacter()
    local hum = getHumanoid(char)
    if not char or not hum then return end

    userId = tonumber(userId)
    if not userId or userId <= 0 then return end

    self.Config.Avatar.TargetUserId = userId
    self.Config.Avatar.Enabled = true

    task.spawn(function()
        pcall(function()
            if not originalHumanoidDescription then
                originalHumanoidDescription = hum:GetAppliedDescription()
            end

            local newDesc = Players:GetHumanoidDescriptionFromUserId(userId)
            if newDesc then
                hum:ApplyDescription(newDesc)
                task.wait(0.15)
                self:ApplyMaterial()
            end
        end)
    end)
end

function PlayerVisuals:ResetAvatar()
    local char = getCharacter()
    local hum = getHumanoid(char)
    if not char or not hum then return end

    self.Config.Avatar.Enabled = false
    self.Config.Avatar.TargetUserId = 0

    task.spawn(function()
        pcall(function()
            if originalHumanoidDescription then
                hum:ApplyDescription(originalHumanoidDescription)
                originalHumanoidDescription = nil
            else
                local defaultDesc = Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
                if defaultDesc then
                    hum:ApplyDescription(defaultDesc)
                end
            end
            task.wait(0.15)
            self:ApplyMaterial()
        end)
    end)
end

-- Aura System
local function buildAuraEmitter(auraType, color, scale)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "VisualAura_" .. tostring(auraType)
    emitter.LightEmission = 0.85
    emitter.LightInfluence = 0.1
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Color = ColorSequence.new(color)

    scale = math.clamp(scale or 1, 0.1, 10)

    if auraType == "fire" or auraType == "inferno" then
        emitter.Texture = "rbxassetid://258129524"
        emitter.Rate = 40 * scale
        emitter.Speed = NumberRange.new(2.5 * scale, 5.5 * scale)
        emitter.Lifetime = NumberRange.new(0.6, 1.4)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5 * scale),
            NumberSequenceKeypoint.new(0.6, 1.4 * scale),
            NumberSequenceKeypoint.new(1, 0)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.7, 0.4),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.Acceleration = Vector3.new(0, 6 * scale, 0)

    elseif auraType == "electric" or auraType == "lightning_storm" then
        emitter.Texture = "rbxassetid://490918712"
        emitter.Rate = 50 * scale
        emitter.Speed = NumberRange.new(3 * scale, 7 * scale)
        emitter.Lifetime = NumberRange.new(0.2, 0.5)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8 * scale),
            NumberSequenceKeypoint.new(1, 0)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.8, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.RotSpeed = NumberRange.new(-200, 200)

    elseif auraType == "ghostly" or auraType == "shadow" or auraType == "void" then
        emitter.Texture = "rbxassetid://243098098"
        emitter.Rate = 22 * scale
        emitter.Speed = NumberRange.new(1 * scale, 2.5 * scale)
        emitter.Lifetime = NumberRange.new(1.5, 3)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.6 * scale),
            NumberSequenceKeypoint.new(0.5, 2.2 * scale),
            NumberSequenceKeypoint.new(1, 0.2 * scale)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.Acceleration = Vector3.new(0, 1.5 * scale, 0)

    elseif auraType == "galaxy" or auraType == "cosmic" then
        emitter.Texture = "rbxassetid://645435862"
        emitter.Rate = 30 * scale
        emitter.Speed = NumberRange.new(1 * scale, 3 * scale)
        emitter.Lifetime = NumberRange.new(1.2, 2.5)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2 * scale),
            NumberSequenceKeypoint.new(0.5, 1.8 * scale),
            NumberSequenceKeypoint.new(1, 0)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.7, 0.4),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.RotSpeed = NumberRange.new(-80, 80)

    elseif auraType == "hearts" then
        emitter.Texture = "rbxassetid://258127027"
        emitter.Rate = 18 * scale
        emitter.Speed = NumberRange.new(2 * scale, 4 * scale)
        emitter.Lifetime = NumberRange.new(1, 2.2)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4 * scale),
            NumberSequenceKeypoint.new(0.8, 1.2 * scale),
            NumberSequenceKeypoint.new(1, 0)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.8, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.Acceleration = Vector3.new(0, 3 * scale, 0)

    elseif auraType == "rings" or auraType == "energy_shield" then
        emitter.Texture = "rbxassetid://1084991219"
        emitter.Rate = 15 * scale
        emitter.Speed = NumberRange.new(0.5 * scale, 1.5 * scale)
        emitter.Lifetime = NumberRange.new(1, 2)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1 * scale),
            NumberSequenceKeypoint.new(1, 3.5 * scale)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.6, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.RotSpeed = NumberRange.new(45, 90)

    elseif auraType == "frost" or auraType == "blizzard" then
        emitter.Texture = "rbxassetid://241594419"
        emitter.Rate = 35 * scale
        emitter.Speed = NumberRange.new(1 * scale, 3 * scale)
        emitter.Lifetime = NumberRange.new(1, 2.5)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5 * scale),
            NumberSequenceKeypoint.new(0.5, 1 * scale),
            NumberSequenceKeypoint.new(1, 0)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.8, 0.4),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.Acceleration = Vector3.new(0, -2 * scale, 0)

    elseif auraType == "blood" or auraType == "toxic" then
        emitter.Texture = "rbxassetid://244905904"
        emitter.Rate = 30 * scale
        emitter.Speed = NumberRange.new(1.5 * scale, 3.5 * scale)
        emitter.Lifetime = NumberRange.new(0.8, 1.8)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8 * scale),
            NumberSequenceKeypoint.new(1, 0)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.Acceleration = Vector3.new(0, -4 * scale, 0)

    elseif auraType == "sakura" then
        emitter.Texture = "rbxassetid://1084961479"
        emitter.Rate = 20 * scale
        emitter.Speed = NumberRange.new(1.5 * scale, 3 * scale)
        emitter.Lifetime = NumberRange.new(2, 4)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.6 * scale),
            NumberSequenceKeypoint.new(1, 0.2 * scale)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.8, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.RotSpeed = NumberRange.new(-60, 60)
        emitter.Acceleration = Vector3.new(1 * scale, -1.5 * scale, 0)

    elseif auraType == "cyberpunk" or auraType == "divine" or auraType == "solar" then
        emitter.Texture = "rbxassetid://645435862"
        emitter.Rate = 45 * scale
        emitter.Speed = NumberRange.new(2 * scale, 5 * scale)
        emitter.Lifetime = NumberRange.new(0.5, 1.5)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4 * scale),
            NumberSequenceKeypoint.new(0.5, 1.6 * scale),
            NumberSequenceKeypoint.new(1, 0)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.RotSpeed = NumberRange.new(-120, 120)

    elseif auraType == "black_hole" or auraType == "abyssal" then
        emitter.Texture = "rbxassetid://1084991219"
        emitter.Rate = 40 * scale
        emitter.Speed = NumberRange.new(-3 * scale, -1 * scale)
        emitter.Lifetime = NumberRange.new(0.8, 1.8)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 3 * scale),
            NumberSequenceKeypoint.new(1, 0)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 0)
        })
        emitter.RotSpeed = NumberRange.new(-180, 180)

    else
        emitter.Texture = "rbxassetid://1084961479"
        emitter.Rate = 25 * scale
        emitter.Speed = NumberRange.new(1.5 * scale, 3 * scale)
        emitter.Lifetime = NumberRange.new(1, 2.2)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4 * scale),
            NumberSequenceKeypoint.new(0.5, 1.2 * scale),
            NumberSequenceKeypoint.new(1, 0)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.8, 0.5),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.RotSpeed = NumberRange.new(-100, 100)
    end

    return emitter
end

function PlayerVisuals:ClearAuras()
    if currentAuraAttachment then
        currentAuraAttachment:Destroy()
        currentAuraAttachment = nil
    end

    local char = getCharacter()
    if char then
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("ParticleEmitter") and string.find(obj.Name, "VisualAura_") then
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

    local attachment = Instance.new("Attachment")
    attachment.Name = "VisualAura_Attachment"
    attachment.Position = Vector3.new(0, 0, 0)
    attachment.Parent = root

    currentAuraAttachment = attachment

    local emitter = buildAuraEmitter(cfg.selectedAuras or "starlight", cfg.color, cfg.scale or 1)
    emitter.Parent = attachment
end

-- R6 Rig Engine
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
        if animate:FindFirstChild("climb") and animate.climb:FindFirstChild("ClimbAnim") and pack.climb then
            animate.climb.ClimbAnim.AnimationId = "rbxassetid://" .. pack.climb
        end
        if animate:FindFirstChild("swim") and animate.swim:FindFirstChild("Swim") and pack.swim then
            animate.swim.Swim.AnimationId = "rbxassetid://" .. pack.swim
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

function PlayerVisuals:PlayDance(danceNameOrId)
    self:StopDance()
    if not danceNameOrId or danceNameOrId == "None" or danceNameOrId == "" then
        return
    end

    local danceId = self.Dances[danceNameOrId] or danceNameOrId
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

        self.Config.Dance.CurrentDance = danceNameOrId
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
    LocalPlayer.CharacterAdded:Connect(function(newChar)
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

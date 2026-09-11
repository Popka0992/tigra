-- Services.
local lightingService = cloneref(game:GetService("Lighting"))
local runService = cloneref(game:GetService("RunService"))

local WorldVisuals = {}
WorldVisuals.__index = WorldVisuals

local originalAmbient = lightingService.Ambient
local originalOutdoorAmbient = lightingService.OutdoorAmbient
local originalFogColor = lightingService.FogColor
local originalFogStart = lightingService.FogStart
local originalFogEnd = lightingService.FogEnd
local originalClockTime = lightingService.ClockTime
local originalBrightness = lightingService.Brightness
local originalExposure = lightingService.ExposureCompensation

local customSky = lightingService:FindFirstChildOfClass("Sky")
if not customSky then
	customSky = Instance.new("Sky")
	customSky.Name = "CustomSky"
	customSky.Parent = lightingService
end

local customColorCorrection = lightingService:FindFirstChild("CustomColorCorrection")
if not customColorCorrection then
	customColorCorrection = Instance.new("ColorCorrectionEffect")
	customColorCorrection.Name = "CustomColorCorrection"
	customColorCorrection.Enabled = false
	customColorCorrection.Parent = lightingService
end

local customAtmosphere = lightingService:FindFirstChildOfClass("Atmosphere")
local originalAtmosphere = {
	Density = customAtmosphere and customAtmosphere.Density or 0.3,
	Offset = customAtmosphere and customAtmosphere.Offset or 0.25,
	Haze = customAtmosphere and customAtmosphere.Haze or 0,
	Glare = customAtmosphere and customAtmosphere.Glare or 0,
	Color = customAtmosphere and customAtmosphere.Color or Color3.fromRGB(199, 199, 199),
	Decay = customAtmosphere and customAtmosphere.Decay or Color3.fromRGB(106, 112, 125)
}

if not customAtmosphere then
	customAtmosphere = Instance.new("Atmosphere")
	customAtmosphere.Name = "CustomAtmosphere"
	customAtmosphere.Parent = lightingService
end

local skyboxes = {
	["default"] = {
		["SkyboxBk"] = customSky.SkyboxBk,
		["SkyboxDn"] = customSky.SkyboxDn,
		["SkyboxFt"] = customSky.SkyboxFt,
		["SkyboxLf"] = customSky.SkyboxLf,
		["SkyboxRt"] = customSky.SkyboxRt,
		["SkyboxUp"] = customSky.SkyboxUp,
		["SunTextureId"] = customSky.SunTextureId,
		["MoonTextureId"] = customSky.MoonTextureId
	},
	["stormy"] = {
		["SkyboxUp"] = "http://www.roblox.com/asset/?id=18703232671",
		["SkyboxBk"] = "http://www.roblox.com/asset/?id=18703245834",
		["SkyboxLf"] = "http://www.roblox.com/asset/?id=18703237556",
		["SkyboxDn"] = "http://www.roblox.com/asset/?id=18703243349",
		["SkyboxFt"] = "http://www.roblox.com/asset/?id=18703240532",
		["SkyboxRt"] = "http://www.roblox.com/asset/?id=18703235430",
		["SunTextureId"] = customSky.SunTextureId,
		["MoonTextureId"] = customSky.MoonTextureId
	},
	["blue space"] = {
		["SkyboxLf"] = "rbxassetid://15536114370",
		["SkyboxUp"] = "rbxassetid://15536117282",
		["SkyboxRt"] = "rbxassetid://15536118762",
		["SkyboxFt"] = "rbxassetid://15536116141",
		["SkyboxDn"] = "rbxassetid://15536112543",
		["SkyboxBk"] = "rbxassetid://15536110634",
		["SunTextureId"] = customSky.SunTextureId,
		["MoonTextureId"] = customSky.MoonTextureId
	},
	["pink"] = {
		["SkyboxUp"] = "rbxassetid://12216108877",
		["SkyboxLf"] = "rbxassetid://12216110170",
		["SkyboxRt"] = "rbxassetid://12216110471",
		["SkyboxFt"] = "rbxassetid://12216109489",
		["SkyboxBk"] = "rbxassetid://12216109205",
		["SkyboxDn"] = "rbxassetid://12216109875",
		["SunTextureId"] = customSky.SunTextureId,
		["MoonTextureId"] = customSky.MoonTextureId
	},
	["black storm"] = {
		["SkyboxLf"] = "rbxassetid://15502507918",
		["SkyboxUp"] = "rbxassetid://15502511911",
		["SkyboxRt"] = "rbxassetid://15502509398",
		["SkyboxFt"] = "rbxassetid://15502510289",
		["SkyboxDn"] = "rbxassetid://15502508460",
		["SkyboxBk"] = "rbxassetid://15502511288",
		["SunTextureId"] = customSky.SunTextureId,
		["MoonTextureId"] = customSky.MoonTextureId
	},
	["realistic"] = {
		["SkyboxUp"] = "rbxassetid://653719321",
		["SkyboxDn"] = "rbxassetid://653718790",
		["SkyboxLf"] = "rbxassetid://653719190",
		["SkyboxFt"] = "rbxassetid://653719067",
		["SkyboxRt"] = "rbxassetid://653718931",
		["SkyboxBk"] = "rbxassetid://653719502",
		["SunTextureId"] = customSky.SunTextureId,
		["MoonTextureId"] = customSky.MoonTextureId
	}
}

WorldVisuals.Config = {
	Enabled = false,
	Ambient = false,
	AmbientColor = originalAmbient,
	OutdoorAmbient = false,
	OutdoorAmbientColor = originalOutdoorAmbient,
	SkyChanger = false,
	SelectedSky = "default",

	Fog = false,
	FogColor = originalFogColor,
	FogStart = originalFogStart,
	FogEnd = originalFogEnd,

	TimeChanger = false,
	ClockTime = originalClockTime,

	Brightness = false,
	BrightnessValue = originalBrightness,
	Exposure = false,
	ExposureValue = originalExposure,

	ColorCorrection = false,
	Saturation = 0,
	Contrast = 0,
	Tint = Color3.fromRGB(255, 255, 255),

	Atmosphere = false,
	AtmosphereDensity = originalAtmosphere.Density,
	AtmosphereOffset = originalAtmosphere.Offset,
	AtmosphereHaze = originalAtmosphere.Haze,
	AtmosphereGlare = originalAtmosphere.Glare,
	AtmosphereColor = originalAtmosphere.Color,
	AtmosphereDecay = originalAtmosphere.Decay
}

function WorldVisuals:ApplySkybox(name)
	local targetData = skyboxes[name] or skyboxes["default"]
	if not customSky or not customSky.Parent then
		customSky = lightingService:FindFirstChildOfClass("Sky") or Instance.new("Sky", lightingService)
	end
	for prop, val in pairs(targetData) do
		customSky[prop] = val
	end
end

function WorldVisuals:Update()
	local config = self.Config
	if config.Enabled then
		lightingService.Ambient = config.Ambient and config.AmbientColor or originalAmbient
		lightingService.OutdoorAmbient = config.OutdoorAmbient and config.OutdoorAmbientColor or originalOutdoorAmbient

		if config.Fog then
			lightingService.FogColor = config.FogColor
			lightingService.FogStart = config.FogStart
			lightingService.FogEnd = config.FogEnd
		else
			lightingService.FogColor = originalFogColor
			lightingService.FogStart = originalFogStart
			lightingService.FogEnd = originalFogEnd
		end

		if config.TimeChanger then
			lightingService.ClockTime = config.ClockTime
		else
			lightingService.ClockTime = originalClockTime
		end

		lightingService.Brightness = config.Brightness and config.BrightnessValue or originalBrightness
		lightingService.ExposureCompensation = config.Exposure and config.ExposureValue or originalExposure

		customColorCorrection.Enabled = config.ColorCorrection
		if config.ColorCorrection then
			customColorCorrection.Saturation = config.Saturation
			customColorCorrection.Contrast = config.Contrast
			customColorCorrection.TintColor = config.Tint
		end

		if config.Atmosphere then
			customAtmosphere.Density = config.AtmosphereDensity
			customAtmosphere.Offset = config.AtmosphereOffset
			customAtmosphere.Haze = config.AtmosphereHaze
			customAtmosphere.Glare = config.AtmosphereGlare
			customAtmosphere.Color = config.AtmosphereColor
			customAtmosphere.Decay = config.AtmosphereDecay
		else
			customAtmosphere.Density = originalAtmosphere.Density
			customAtmosphere.Offset = originalAtmosphere.Offset
			customAtmosphere.Haze = originalAtmosphere.Haze
			customAtmosphere.Glare = originalAtmosphere.Glare
			customAtmosphere.Color = originalAtmosphere.Color
			customAtmosphere.Decay = originalAtmosphere.Decay
		end

		if config.SkyChanger then
			self:ApplySkybox(config.SelectedSky)
		else
			self:ApplySkybox("default")
		end
	else
		lightingService.Ambient = originalAmbient
		lightingService.OutdoorAmbient = originalOutdoorAmbient
		lightingService.FogColor = originalFogColor
		lightingService.FogStart = originalFogStart
		lightingService.FogEnd = originalFogEnd
		lightingService.ClockTime = originalClockTime
		lightingService.Brightness = originalBrightness
		lightingService.ExposureCompensation = originalExposure

		customColorCorrection.Enabled = false

		customAtmosphere.Density = originalAtmosphere.Density
		customAtmosphere.Offset = originalAtmosphere.Offset
		customAtmosphere.Haze = originalAtmosphere.Haze
		customAtmosphere.Glare = originalAtmosphere.Glare
		customAtmosphere.Color = originalAtmosphere.Color
		customAtmosphere.Decay = originalAtmosphere.Decay

		self:ApplySkybox("default")
	end
end

function WorldVisuals:GetConfig()
	return self.Config
end

function WorldVisuals:Load()
	runService.RenderStepped:Connect(function()
		if not self.Config.Enabled then return end
		if self.Config.Ambient then
			lightingService.Ambient = self.Config.AmbientColor
		end
		if self.Config.OutdoorAmbient then
			lightingService.OutdoorAmbient = self.Config.OutdoorAmbientColor
		end
		if self.Config.Fog then
			lightingService.FogColor = self.Config.FogColor
			lightingService.FogStart = self.Config.FogStart
			lightingService.FogEnd = self.Config.FogEnd
		end
		if self.Config.TimeChanger then
			lightingService.ClockTime = self.Config.ClockTime
		end
		if self.Config.Brightness then
			lightingService.Brightness = self.Config.BrightnessValue
		end
		if self.Config.Exposure then
			lightingService.ExposureCompensation = self.Config.ExposureValue
		end
	end)
end

return WorldVisuals

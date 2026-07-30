--game.ReplicatedStorage.Stuff.UI.Forimagesafter
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local AfterImageModuleRef = {}
AfterImageModule.__index = AfterImageModule
AfterImageModule.GlobalCap = 48

local DEFAULT_CONFIG = {
	Duration = 0.6,
	FadeStyle = "Smooth",
	Interval = 0.08,
	MaxImages = 30,

	AntiStack = true,
	AntiStackDistance = 0.5,

	Mode = "OM",

	OM = {
		fadein = 0.08,
		fadeout = 0.3,
		hold = nil,
		color = nil,
	},

	Highlight = nil,
	HighlightFade = true,

	OverrideColor = nil,
	OverrideMaterial = nil,
	OverrideTransparency = 0.3,

	VerticalDrift = 0,
	Distortion = 0,

	IgnoreParts = {},
	IncludeAccessories = true,
	IncludeTools = false,
}

local FADE_STYLES = {
	Smooth = function(progress) return progress end,
	Sudden = function(progress)
		if progress < 0.7 then return 0 end
		return (progress - 0.7) / 0.3
	end,
	Flicker = function(progress)
		if progress > 0.85 then return 1 end
		local flicker = math.sin(progress * math.pi * 12) * 0.5 + 0.5
		return flicker * progress
	end,
	Pulse = function(progress)
		local pulse = math.sin(progress * math.pi * 4) * 0.3
		return math.clamp(progress + pulse, 0, 1)
	end,
	Shatter = function(progress)
		if progress < 0.5 then return progress * 0.2 end
		return (progress - 0.5) * 2
	end,
	Reverse = function(progress)
		if progress < 0.3 then return 0.5 * (1 - progress / 0.3) end
		return progress
	end,
}
-- tf troy
local function deepMerge(base, overrides)
	local result = {}
	for k, v in base do result[k] = v end
	if overrides then for k, v in overrides do result[k] = v end end
	return result
end

local STRIP = {
	Humanoid = true, Animator = true, Script = true, LocalScript = true,
	ModuleScript = true, Sound = true, ParticleEmitter = true, Trail = true,
	Beam = true, Fire = true, Smoke = true, Sparkles = true, Explosion = true,
	BillboardGui = true, SurfaceGui = true, ClickDetector = true, ProximityPrompt = true,
	ForceField = true, HumanoidDescription = true, Pathfinding = true,
}

local omGui
local function omInit()
	if omGui and omGui.Parent then return end
	local plr = Players.LocalPlayer
	if not plr then return end
	omGui = Instance.new("ScreenGui")
	omGui.Name = "ViewportUI"
	omGui.ResetOnSpawn = false
	omGui.Parent = plr:WaitForChild("PlayerGui")
end

local vpfPool = {}
local function getVPF()
	local vpf = table.remove(vpfPool)
	if vpf then return vpf end
	vpf = Instance.new("ViewportFrame")
	vpf.Name = "AfterImage"
	vpf.Size = UDim2.new(1, 0, 1.1, 0)
	vpf.AnchorPoint = Vector2.new(0, 0.5)
	vpf.Position = UDim2.new(0, 0, 0.45, 0)
	vpf.BackgroundTransparency = 1
	vpf.CurrentCamera = workspace.CurrentCamera
	return vpf
end
local function freeVPF(vpf)
	for _, c in vpf:GetChildren() do c:Destroy() end
	vpf.Parent = nil
	vpf.ImageColor3 = Color3.new(1, 1, 1)
	vpf.LightColor = Color3.new(1, 1, 1)
	if #vpfPool < 64 then vpfPool[#vpfPool + 1] = vpf else vpf:Destroy() end
end

local active = {}
local heartbeatConn
local function stepManager()
	local now = os.clock()
	local n = #active
	local i = 1
	while i <= n do
		local rec = active[i]
		local vpf = rec.vpf
		local remove = false
		if not vpf.Parent then
			remove = true
		else
			local e = now - rec.t0
			local newT
			if e >= rec.tout then
				freeVPF(vpf)
				remove = true
			elseif e < rec.tin then
				newT = 1 - (1 - rec.baseT) * (e / rec.tin)
			elseif e < rec.thold then
				newT = rec.baseT
			else
				newT = rec.baseT + (1 - rec.baseT) * ((e - rec.thold) / (rec.tout - rec.thold))
			end
			if newT and (not rec.lastT or math.abs(newT - rec.lastT) > 0.003) then
				vpf.ImageTransparency = newT
				rec.lastT = newT
			end
		end
		if remove then
			active[i] = active[n]
			active[n] = nil
			n -= 1
		else
			i += 1
		end
	end
	if n == 0 and heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
end

local function register(vpf, baseT, tin, hold, tout)
	tin = math.max(tin or 0.08, 1/240)
	tout = math.max(tout or 0.3, 1/240)
	hold = math.max(hold or 0, 0)
	if #active >= AfterImageModule.GlobalCap then
		local victim = active[1]
		if victim then
			freeVPF(victim.vpf)
			active[1] = active[#active]
			active[#active] = nil
		end
	end
	active[#active + 1] = {
		vpf = vpf,
		baseT = baseT,
		t0 = os.clock(),
		tin = tin,
		thold = tin + hold,
		tout = tin + hold + tout,
	}
	if not heartbeatConn then
		heartbeatConn = RunService.Heartbeat:Connect(stepManager)
	end
end

local templateCache = setmetatable({}, { __mode = "k" })
local lastSpawnPos = setmetatable({}, { __mode = "k" })

local function antiStackOK(target, enabled, minDist)
	if not enabled then return true end
	local ok, piv = pcall(function() return target:GetPivot().Position end)
	if not ok then return true end
	local last = lastSpawnPos[target]
	if last and (piv - last).Magnitude < (minDist or 0.75) then
		return false
	end
	lastSpawnPos[target] = piv
	return true
end

local function stripClone(target, incAcc, incTools)
	-- yea im ngl hl its gon a have to do
	local arch = target.Archivable
	if not arch then target.Archivable = true end
	local clone = target:Clone()
	if not arch then target.Archivable = arch end
	for _, d in clone:GetDescendants() do
		if STRIP[d.ClassName] then
			d:Destroy()
		elseif d:IsA("Accessory") then
			if not incAcc then d:Destroy() end
		elseif d:IsA("Tool") then
			if not incTools then d:Destroy() end
		elseif d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("Attachment") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			if d.Name == "HumanoidRootPart" then
				d:Destroy()
			else
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				d.CastShadow = false
				d.Massless = true
			end
		end
	end
	return clone
end

local function partPath(part, root)
	local segs = {}
	local node = part
	while node and node ~= root do
		table.insert(segs, 1, node.Name)
		node = node.Parent
	end
	return table.concat(segs, "/")
end

local function buildTemplate(target, config)
	local incAcc = config.IncludeAccessories
	local incTools = config.IncludeTools
	local template = stripClone(target, incAcc, incTools)

	local liveByPath = {}
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			if (not incAcc) and d:FindFirstAncestorWhichIsA("Accessory") then continue end
			if (not incTools) and d:FindFirstAncestorWhichIsA("Tool") then continue end
			liveByPath[partPath(d, target)] = d
		end
	end

	local count = 0
	for _ in liveByPath do count += 1 end

	local rec = { template = template, liveByPath = liveByPath, partCount = count }
	templateCache[target] = rec
	target.Destroying:Once(function()
		if rec.template then rec.template:Destroy() rec.template = nil end
		templateCache[target] = nil
	end)
	return rec
end

local function liveCount(target, incAcc, incTools)
	local n = 0
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			if (not incAcc) and d:FindFirstAncestorWhichIsA("Accessory") then continue end
			if (not incTools) and d:FindFirstAncestorWhichIsA("Tool") then continue end
			n += 1
		end
	end
	return n
end

local function prepClone(target, config)
	local incAcc = config.IncludeAccessories
	local incTools = config.IncludeTools
	local rec = templateCache[target]
	if rec and rec.template and rec.partCount ~= liveCount(target, incAcc, incTools) then
		rec.template:Destroy()
		templateCache[target] = nil
		rec = nil
	end
	if not rec or not rec.template then
		rec = buildTemplate(target, config)
	end
	if not rec then
		return stripClone(target, incAcc, incTools)
	end

	local clone = rec.template:Clone()
	local liveByPath = rec.liveByPath
	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") then
			local lp = liveByPath[partPath(d, clone)]
			if lp and lp.Parent then
				d.CFrame = lp.CFrame
				d.Transparency = lp.Transparency
				d.Color = lp.Color
				d.Material = lp.Material
			end
		end
	end
	return clone
end

local function spawnOM(target, config)
	if not target or not target.Parent then return end
	omInit()
	if not omGui then return end

	local clone = prepClone(target, config)
	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency >= 1 then
			d:Destroy()
		end
	end
	local vpf = getVPF()

	local om = config.OM or {}
	local clr = om.color or config.OverrideColor
	if typeof(clr) == "Color3" then
		vpf.ImageColor3 = clr
		vpf.LightColor = clr
	end

	vpf.ImageTransparency = 1
	clone.Parent = vpf
	vpf.Parent = omGui

	register(vpf, config.OverrideTransparency, om.fadein, om.hold or config.Duration, om.fadeout)
	return vpf
end

local function spawnSingleImage(target, config)
	if not target or not target.Parent then return end
	if config.Mode == "OM" then return spawnOM(target, config) end

	local ghostModel = Instance.new("Model")
	ghostModel.Name = "AfterImage"

	local useHighlight = config.Mode == "Highlight"

	local parts = {}
	if target:IsA("Model") then
		for _, part in target:GetDescendants() do
			if part:IsA("BasePart") then table.insert(parts, part) end
		end
	elseif target:IsA("BasePart") then
		table.insert(parts, target)
	else
		return
	end

	if #parts == 0 then return end

	local ghosts = {}
	local originalTransparencies = {}

	for _, part in parts do
		if part.Transparency >= 1 then continue end
		if part.Name == "HumanoidRootPart" then continue end

		local success, ghost = pcall(function() return part:Clone() end)
		if not success or not ghost then continue end

		for _, child in ghost:GetDescendants() do
			if child:IsA("BasePart") or child:IsA("Script") or child:IsA("LocalScript")
				or child:IsA("ModuleScript") or child:IsA("Sound") or child:IsA("BodyMover")
				or child:IsA("ParticleEmitter") or child:IsA("Trail") or child:IsA("Beam")
				or child:IsA("BillboardGui") or child:IsA("SurfaceGui") or child:IsA("Weld")
				or child:IsA("WeldConstraint") or child:IsA("Motor6D") or child:IsA("Constraint")
				or child:IsA("Humanoid") or child:IsA("Animator") then
				child:Destroy()
			end
		end

		ghost.Anchored = true
		ghost.CanCollide = false
		ghost.CastShadow = false
		ghost.Massless = true
		ghost.CFrame = part.CFrame

		if useHighlight then
			ghost.Transparency = 0
			local hlConfig = config.Highlight
			if typeof(hlConfig) == "table" and hlConfig.FillColor then
				ghost.Color = hlConfig.FillColor
			elseif typeof(hlConfig) == "Color3" then
				ghost.Color = hlConfig
			else
				ghost.Color = Color3.new(0, 0, 0)
			end
			ghost.Material = Enum.Material.Neon
		else
			if config.OverrideColor then ghost.Color = config.OverrideColor end
			if config.OverrideMaterial then ghost.Material = config.OverrideMaterial end
			ghost.Transparency = config.OverrideTransparency
		end

		ghost.Parent = ghostModel
		table.insert(ghosts, ghost)
		originalTransparencies[ghost] = ghost.Transparency
	end

	if #ghosts == 0 then return end
	ghostModel.Parent = workspace

	local highlight = nil
	local highlightOrigFill = 1
	local highlightOrigOutline = 1

	if useHighlight and config.Highlight then
		highlight = Instance.new("Highlight")
		if typeof(config.Highlight) == "table" then
			highlight.FillColor = config.Highlight.FillColor or Color3.new(0, 0.5, 1)
			highlight.OutlineColor = config.Highlight.OutlineColor or Color3.new(0, 0.7, 1)
			highlight.FillTransparency = config.Highlight.FillTransparency or 0.5
			highlight.OutlineTransparency = config.Highlight.OutlineTransparency or 0
			highlight.DepthMode = config.Highlight.DepthMode or Enum.HighlightDepthMode.Occluded
		elseif typeof(config.Highlight) == "Color3" then
			highlight.FillColor = config.Highlight
			highlight.OutlineColor = config.Highlight
			highlight.FillTransparency = 0.5
			highlight.OutlineTransparency = 0
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		else
			highlight.FillColor = Color3.new(0, 0.5, 1)
			highlight.OutlineColor = Color3.new(0, 0.7, 1)
			highlight.FillTransparency = 0.5
			highlight.OutlineTransparency = 0
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		end
		highlightOrigFill = highlight.FillTransparency
		highlightOrigOutline = highlight.OutlineTransparency
		highlight.Parent = ghostModel
	end

	local fadeFunc = FADE_STYLES[config.FadeStyle] or FADE_STYLES.Smooth
	local startTime = os.clock()

	local conn
	conn = RunService.Heartbeat:Connect(function()
		local progress = math.clamp((os.clock() - startTime) / config.Duration, 0, 1)
		local fadeFactor = fadeFunc(progress)

		for _, ghost in ghosts do
			if ghost and ghost.Parent then
				local baseT = originalTransparencies[ghost] or (useHighlight and 0 or config.OverrideTransparency)
				ghost.Transparency = baseT + (1 - baseT) * fadeFactor
				if config.VerticalDrift and config.VerticalDrift ~= 0 then
					ghost.CFrame = ghost.CFrame + Vector3.new(0, config.VerticalDrift * 0.016, 0)
				end
				if config.Distortion and config.Distortion > 0 then
					local jitter = config.Distortion * (1 - progress)
					ghost.CFrame = ghost.CFrame * CFrame.Angles(
						(math.random() - 0.5) * jitter * 0.016,
						(math.random() - 0.5) * jitter * 0.016,
						(math.random() - 0.5) * jitter * 0.016
					)
				end
			end
		end

		if highlight and highlight.Parent and config.HighlightFade then
			highlight.FillTransparency = highlightOrigFill + (1 - highlightOrigFill) * fadeFactor
			highlight.OutlineTransparency = highlightOrigOutline + (1 - highlightOrigOutline) * fadeFactor
		end

		if progress >= 1 then
			if conn then conn:Disconnect() end
			if ghostModel and ghostModel.Parent then ghostModel:Destroy() end
		end
	end)

	Debris:AddItem(ghostModel, config.Duration + 1)
	return ghostModel
end

function AfterImageModule.Single(config)
	local merged = deepMerge(DEFAULT_CONFIG, config)
	if not merged.Target then return end
	return spawnSingleImage(merged.Target, merged)
end

function AfterImageModule.Trail(config)
	local merged = deepMerge(DEFAULT_CONFIG, config)
	if not merged.Target then return function() end end

	local running = true
	local imageCount = 0
	local om = merged.OM or {}
	local life = merged.Mode == "OM"
		and ((om.fadein or 0.08) + (om.hold or merged.Duration) + (om.fadeout or 0.3))
		or merged.Duration

	task.spawn(function()
		while running do
			if imageCount < merged.MaxImages and antiStackOK(merged.Target, merged.AntiStack, merged.AntiStackDistance) then
				imageCount += 1
				spawnSingleImage(merged.Target, merged)
				task.delay(life, function() imageCount -= 1 end)
			end
			task.wait(merged.Interval)
		end
	end)

	return function() running = false end
end

function AfterImageModule.Burst(config)
	local merged = deepMerge(DEFAULT_CONFIG, config)
	if not merged.Target then return end

	local count = config.BurstCount or 5
	local spread = config.BurstSpread or 0.05

	for i = 1, count do
		task.delay(spread * (i - 1), function()
			local burstConfig = deepMerge(merged, {
				OverrideTransparency = merged.OverrideTransparency + (i - 1) * 0.1,
				Duration = merged.Duration + (i - 1) * 0.1,
			})
			spawnSingleImage(burstConfig.Target, burstConfig)
		end)
	end
end

function AfterImageModule.Freeze(config)
	local merged = deepMerge(DEFAULT_CONFIG, config)
	if not merged.Target then return end
	merged.Duration = (config.HoldTime or 1) + merged.Duration
	return spawnSingleImage(merged.Target, merged)
end

function AfterImageModule.Dash(config)
	local merged = deepMerge(DEFAULT_CONFIG, config)
	if not merged.Target then return function() end end

	local dashCount = config.DashCount or 8
	local dashInterval = config.DashInterval or 0.03
	local dashFade = config.DashFade or 0.4

	local running = true
	local spawned = 0

	task.spawn(function()
		while running and spawned < dashCount do
			spawned += 1
			local idx = spawned
			local dashConfig = deepMerge(merged, {
				Duration = dashFade + (idx * 0.05),
				OverrideTransparency = merged.OverrideTransparency + (idx * 0.03),
			})
			spawnSingleImage(dashConfig.Target, dashConfig)
			task.wait(dashInterval)
		end
	end)

	return function() running = false end
end

function AfterImageModule.Rainbow(config)
	local merged = deepMerge(DEFAULT_CONFIG, config)
	if not merged.Target then return function() end end

	local running = true
	local hue = 0
	local useHighlight = merged.Mode == "Highlight"

	task.spawn(function()
		while running do
			hue = (hue + 0.08) % 1
			local color = Color3.fromHSV(hue, 1, 1)
			local rainbowConfig
			if useHighlight then
				rainbowConfig = deepMerge(merged, {
					Highlight = {
						FillColor = color, OutlineColor = color,
						FillTransparency = 0.3, OutlineTransparency = 0,
						DepthMode = Enum.HighlightDepthMode.Occluded,
					},
				})
			else
				rainbowConfig = deepMerge(merged, {
					OverrideColor = color,
					OverrideMaterial = merged.OverrideMaterial or Enum.Material.Neon,
				})
			end
			if antiStackOK(merged.Target, merged.AntiStack, merged.AntiStackDistance) then
				spawnSingleImage(rainbowConfig.Target, rainbowConfig)
			end
			task.wait(merged.Interval)
		end
	end)

	return function() running = false end
end

return AfterImageModule

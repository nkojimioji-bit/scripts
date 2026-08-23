local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local PLAYERS_FOLDER = workspace:WaitForChild("Players")
local PROJECTILE_FOLDER = workspace:WaitForChild("Projectile")

local highlights = {}
local labels = {}
local attrConnections = {}

local showSurvivorLabels = true
local espEnabled = true

local CHARACTER_COLORS = {
	Sonic = Color3.fromRGB(0, 9, 255),
	Tails = Color3.fromRGB(255, 236, 0),
	Knuckles = Color3.fromRGB(255, 21, 0),
	Amy = Color3.fromRGB(248, 0, 255),
	Cream = Color3.fromRGB(255, 218, 132),
	Eggman = Color3.fromRGB(176, 11, 0),
	MetalSonic = Color3.fromRGB(1, 1, 193),
	Silver = Color3.fromRGB(255, 255, 255),
	Blaze = Color3.fromRGB(184, 131, 255),
	Shadow = Color3.fromRGB(128, 128, 128),
}

local function getCharacterColor(model, fallback)
	local c = model:GetAttribute("Character")
	return CHARACTER_COLORS[c] or fallback
end

local function getValue(model, name)
	local obj = model:FindFirstChild(name)
	if obj and obj:IsA("NumberValue") then
		return obj.Value
	end
	return nil
end

local function getAttachPart(instance)
	if instance:IsA("BasePart") or instance:IsA("UnionOperation") then
		return instance
	elseif instance:IsA("Model") then
		return instance:FindFirstChildWhichIsA("BasePart", true)
			or instance:FindFirstChildWhichIsA("UnionOperation", true)
	end
end

local function forceTrapVisible(instance)
	attrConnections[instance] = attrConnections[instance] or {}
	if attrConnections[instance].render then return end

	attrConnections[instance].render =
		RunService.RenderStepped:Connect(function()
			if not instance or not instance.Parent then return end
			local function recurse(inst)
				if inst:IsA("BasePart") or inst:IsA("UnionOperation") then
					inst.Transparency = 0
					inst.LocalTransparencyModifier = 0
				end
				for _, c in ipairs(inst:GetChildren()) do
					recurse(c)
				end
			end
			recurse(instance)
		end)
end

local function removeESP(instance)
	if highlights[instance] then
		highlights[instance]:Destroy()
		highlights[instance] = nil
	end
	if labels[instance] then
		labels[instance]:Destroy()
		labels[instance] = nil
	end
	if attrConnections[instance] then
		for _, c in pairs(attrConnections[instance]) do
			c:Disconnect()
		end
		attrConnections[instance] = nil
	end
end

local function createHighlight(instance, color)
	local hl = Instance.new("Highlight")
	hl.FillColor = color
	hl.OutlineColor = color
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.Adornee = instance
	hl.Parent = CoreGui
	highlights[instance] = hl
end

local function createLabel(part, text, color)
	if not part then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.Arcade
	label.Parent = billboard

	billboard.Parent = part
	return billboard, label
end

local function createCharacterLabel(model, fallbackColor)
	if not espEnabled then return end

	local attachPart =
		model:FindFirstChild("Head")
		or model:FindFirstChild("Sphere.001")
		or model:FindFirstChild("HumanoidRootPart")
	if not attachPart then return end

	local function getColor()
		return getCharacterColor(model, fallbackColor)
	end

	local billboard, label = createLabel(attachPart, "", getColor())

	local function update()
		local char = model:GetAttribute("Character")
		local health = getValue(model, "Health")
		local dodge = getValue(model, "Dodge")

		if char == "TailsDoll" then
			char = "Tripwire"
		end

		local lines = {}
		table.insert(lines, string.upper(tostring(char or "")))

		if health ~= nil then
			table.insert(lines, "HP: " .. tostring(health))
		end

		if dodge ~= nil then
			table.insert(lines, "DODGE: " .. tostring(dodge))
		end

		label.Text = table.concat(lines, "\n")
		label.TextColor3 = getColor()

		if char == "Sonic" or char == "MetalSonic" then
			label.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
		else
			label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		end

		if highlights[model] then
			highlights[model].FillColor = getColor()
			highlights[model].OutlineColor = getColor()
		end
	end

	update()

	attrConnections[model] = attrConnections[model] or {}
	attrConnections[model].char =
		model:GetAttributeChangedSignal("Character"):Connect(update)

	local healthObj = model:FindFirstChild("Health")
	if healthObj then
		attrConnections[model].health = healthObj.Changed:Connect(update)
	end

	local dodgeObj = model:FindFirstChild("Dodge")
	if dodgeObj then
		attrConnections[model].dodge = dodgeObj.Changed:Connect(update)
	end
end

function applyPlayerESP(model)
	if not espEnabled then return end
	if not model:IsA("Model") then return end
	if model == LocalPlayer.Character then return end

	removeESP(model)

	local team = model:GetAttribute("Team")

	if team == "EXE" then
		local color = getCharacterColor(model, Color3.fromRGB(255, 0, 0))
		createHighlight(model, color)

		local attachPart =
			model:FindFirstChild("Head")
			or model:FindFirstChildWhichIsA("BasePart", true)

		if attachPart then
			local billboard, label = createLabel(attachPart, "", color)

			local function updateText()
				local stun = model:GetAttribute("StunDur")
				local char = model:GetAttribute("Character")
				local health = getValue(model, "Health")
				local dodge = getValue(model, "Dodge")
				local c = getCharacterColor(model, Color3.fromRGB(255, 0, 0))

				if char == "TailsDoll" then
					char = "Tripwire"
				end

				label.TextColor3 = c

				if char == "Sonic" or char == "MetalSonic" then
					label.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
				else
					label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
				end

				if highlights[model] then
					highlights[model].FillColor = c
					highlights[model].OutlineColor = c
				end

				local lines = {}

				if type(stun) == "number" and stun >= 0.1 then
					local stunLine = string.format("STUN %.1f", stun)
					if char == "Sonic" or char == "MetalSonic" then
						stunLine = "SONIC " .. stunLine
					end
					table.insert(lines, stunLine)
				else
					table.insert(lines, string.upper(tostring(char or "")))
				end

				if health ~= nil then
					table.insert(lines, "HP: " .. tostring(health))
				end

				if dodge ~= nil then
					table.insert(lines, "DODGE: " .. tostring(dodge))
				end

				label.Text = table.concat(lines, "\n")
			end

			updateText()

			attrConnections[model] = attrConnections[model] or {}
			attrConnections[model].stun =
				model:GetAttributeChangedSignal("StunDur"):Connect(updateText)
			attrConnections[model].char =
				model:GetAttributeChangedSignal("Character"):Connect(updateText)
		end

	elseif team == "Survivor" then
		local color = getCharacterColor(model, Color3.fromRGB(0, 0, 255))
		createHighlight(model, color)

		if showSurvivorLabels then
			createCharacterLabel(model, Color3.fromRGB(0, 0, 255))
		end
	end
end

LocalPlayer.Chatted:Connect(function(msg)
	msg = msg:lower()

	if msg == "/e hide" then
		espEnabled = not espEnabled
	elseif msg == "/e clutter" then
		showSurvivorLabels = not showSurvivorLabels
	end
end)

for _, model in ipairs(PLAYERS_FOLDER:GetChildren()) do
	applyPlayerESP(model)
end

PLAYERS_FOLDER.ChildAdded:Connect(function(model)
	task.defer(function()
		applyPlayerESP(model)
	end)
end)

PLAYERS_FOLDER.ChildRemoved:Connect(removeESP)

local currentTrapsFolder = nil
local trapsConnections = {}

local function clearTrapConnections()
	for _, c in ipairs(trapsConnections) do
		c:Disconnect()
	end
	table.clear(trapsConnections)
	currentTrapsFolder = nil
end

local function setupTraps(folder)
	clearTrapConnections()
	currentTrapsFolder = folder

	for _, obj in ipairs(folder:GetChildren()) do
		applyTrapESP(obj)
	end

	table.insert(trapsConnections,
		folder.ChildAdded:Connect(function(obj)
			task.defer(function()
				applyTrapESP(obj)
			end)
		end)
	)

	table.insert(trapsConnections,
		folder.ChildRemoved:Connect(function(obj)
			removeESP(obj)
		end)
	)
end

PROJECTILE_FOLDER.ChildAdded:Connect(function(child)
	if child.Name == "Traps" then
		setupTraps(child)
	end
end)

PROJECTILE_FOLDER.ChildRemoved:Connect(function(child)
	if child == currentTrapsFolder then
		clearTrapConnections()
	end
end)

local trapsFolder = PROJECTILE_FOLDER:FindFirstChild("Traps")
if trapsFolder then
	setupTraps(trapsFolder)
end

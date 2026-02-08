local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer
local DeathRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Something")

local CONTRACT_TIME = 150

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TargetGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = lp:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0,230,0,180)
Frame.Position = UDim2.new(0.5,-115,0.5,-90)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,45)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,35)
TitleBar.BackgroundColor3 = Color3.fromRGB(45,45,70)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-70,1,0)
Title.Position = UDim2.new(0,10,0,0)
Title.BackgroundTransparency = 1
Title.Text = "Ultra Targetting Tool"
Title.TextColor3 = Color3.fromRGB(220,220,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0,30,0,30)
MinBtn.Position = UDim2.new(1,-65,0,2)
MinBtn.BackgroundColor3 = Color3.fromRGB(60,60,90)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(220,220,255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,30,0,30)
CloseBtn.Position = UDim2.new(1,-30,0,2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(170,0,0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,0,1,-35)
Content.Position = UDim2.new(0,0,0,35)
Content.BackgroundTransparency = 1
Content.Parent = Frame

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1,-20,0,30)
TargetLabel.Position = UDim2.new(0,10,0,10)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "target: none"
TargetLabel.TextColor3 = Color3.fromRGB(255,200,200)
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextSize = 14
TargetLabel.Parent = Content

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Size = UDim2.new(1,-20,0,30)
TimerLabel.Position = UDim2.new(0,10,0,40)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "time: --"
TimerLabel.TextColor3 = Color3.fromRGB(200,200,255)
TimerLabel.Font = Enum.Font.Gotham
TimerLabel.TextSize = 14
TimerLabel.Parent = Content

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1,-20,0,30)
StatusLabel.Position = UDim2.new(0,10,0,70)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "status: idle"
StatusLabel.TextColor3 = Color3.fromRGB(200,255,200)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 14
StatusLabel.Parent = Content

local function isEXE()
	local char = lp.Character
	return char and char:GetAttribute("Team") == "EXE"
end

local function getSurvivorModels()
	local list = {}
	local folder = workspace:FindFirstChild("Players")
	if not folder then return list end
	for _, model in ipairs(folder:GetChildren()) do
		if model.Name ~= lp.Name then
			table.insert(list, model)
		end
	end
	return list
end

local lastLifeHistory = {}

local function isLastLife(model)
	return model:GetAttribute("LastLife") == true
end

local function getCharacterName(model)
	return model:GetAttribute("Character") or model.Name
end

local function pickSmartTarget()
	local models = getSurvivorModels()
	if #models == 0 then return nil end
	local fresh = {}
	for _, model in ipairs(models) do
		if not lastLifeHistory[model.Name] then
			table.insert(fresh, model)
		end
	end
	local pool = (#fresh > 0) and fresh or models
	return pool[math.random(#pool)]
end

local active = false
local targetModel
local timeLeft
local conn

local function punish()
	DeathRemote:FireServer("Dead")
end

local function setTarget(model)
	targetModel = model
	timeLeft = CONTRACT_TIME
	TargetLabel.Text = "target: "..getCharacterName(model)
end

local function startContract()
	if not isEXE() then
		StatusLabel.Text = "status: idle"
		return
	end

	local picked = pickSmartTarget()
	if not picked then
		StatusLabel.Text = "status: no target"
		return
	end

	active = true
	setTarget(picked)
	StatusLabel.Text = "status: targetting"

	conn = RunService.Heartbeat:Connect(function(dt)
		if not active then return end

		timeLeft -= dt
		TimerLabel.Text = "time: "..math.ceil(timeLeft)

		if not (workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(targetModel.Name)) then
			active = false
			StatusLabel.Text = "status: success"
			conn:Disconnect()
			return
		end

		if isLastLife(targetModel) then
			lastLifeHistory[targetModel.Name] = true
			local newTarget = pickSmartTarget()
			if newTarget then
				setTarget(newTarget)
			end
		end

		if timeLeft <= 0 then
			active = false
			StatusLabel.Text = "status: failed"
			conn:Disconnect()
			punish()
		end
	end)
end

task.spawn(function()
	while true do
		task.wait(2)
		if not active and isEXE() then
			startContract()
		end
	end
end)

local minimized = false
local fullSize = Frame.Size
local miniSize = UDim2.new(0,230,0,35)

MinBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	Frame:TweenSize(minimized and miniSize or fullSize, "Out", "Quad", 0.2, true)
	Content.Visible = not minimized
	MinBtn.Text = minimized and "+" or "−"
end)

CloseBtn.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

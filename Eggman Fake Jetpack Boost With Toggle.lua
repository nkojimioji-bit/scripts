local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

local TARGET_SPEEDBOOST = 2.65
local TARGET_STATE = "jetpack"
local DEFAULT_SPEEDBOOST = 1
local DEFAULT_STATE = "default"

local enabled = false
local isMinimized = false
local fullSize = UDim2.new(0, 180, 0, 80)
local minimizedSize = UDim2.new(0, 180, 0, 35)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MasterPlan"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = lp:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = fullSize
Frame.Position = UDim2.new(0.5, -90, 0.85, -40)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "Eggman"
Title.TextColor3 = Color3.fromRGB(200, 220, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -65, 0, 0)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 20
MinimizeBtn.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.Parent = TitleBar

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
ToggleBtn.Text = "OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 22
ToggleBtn.Parent = Frame

local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        Frame:TweenSize(minimizedSize, "Out", "Quad", 0.25, true)
        ToggleBtn.Visible = false
        MinimizeBtn.Text = "+"
    else
        Frame:TweenSize(fullSize, "Out", "Quad", 0.25, true)
        ToggleBtn.Visible = true
        MinimizeBtn.Text = "-"
    end
end

MinimizeBtn.MouseButton1Click:Connect(toggleMinimize)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local function getModel()
    return Workspace.Players:FindFirstChild(lp.Name)
end

local function apply(model, isEnabled)
    if not model then return end
    if model:GetAttribute("Character") ~= "Eggman" then return end
    
    if isEnabled then
        model:SetAttribute("SpeedBoost", TARGET_SPEEDBOOST)
        model:SetAttribute("State", TARGET_STATE)
    else
        model:SetAttribute("SpeedBoost", DEFAULT_SPEEDBOOST)
        model:SetAttribute("State", DEFAULT_STATE)
    end
end

local function monitor(model)
    if not model then return end
    if model:GetAttribute("Character") ~= "Eggman" then return end
    
    model.AttributeChanged:Connect(function(attr)
        if attr == "SpeedBoost" then
            local val = enabled and TARGET_SPEEDBOOST or DEFAULT_SPEEDBOOST
            if model:GetAttribute("SpeedBoost") ~= val then
                model:SetAttribute("SpeedBoost", val)
            end
        elseif attr == "State" then
            local val = enabled and TARGET_STATE or DEFAULT_STATE
            if model:GetAttribute("State") ~= val then
                model:SetAttribute("State", val)
            end
        end
    end)
end

local currentModel = nil

local function setup()
    currentModel = getModel()
    if currentModel then
        apply(currentModel, enabled)
        monitor(currentModel)
        
        currentModel.AncestryChanged:Connect(function()
            if not currentModel:IsDescendantOf(Workspace) then
                task.wait(1)
                setup()
            end
        end)
    else
        task.delay(1, setup)
    end
end

setup()

task.spawn(function()
    while true do
        task.wait(1)
        local model = getModel()
        if model ~= currentModel then
            currentModel = model
            setup()
        end
        apply(model, enabled)
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    ToggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(170, 0, 0)
    ToggleBtn.Text = enabled and "ON" or "OFF"
    apply(getModel(), enabled)
end)

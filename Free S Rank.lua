local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local enabled = false
local targetName = ""
local keyString = ""
local isMinimized = false
local fullSize = UDim2.new(0, 240, 0, 220)
local minimizedSize = UDim2.new(0, 240, 0, 35)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FreeSRank"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = lp:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = fullSize
Frame.Position = UDim2.new(0.5, -120, 0.5, -110)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "Free S Rank"
Title.TextColor3 = Color3.fromRGB(200, 220, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Parent = TitleBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -65, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -35)
Content.Position = UDim2.new(0, 0, 0, 35)
Content.BackgroundTransparency = 1
Content.Parent = Frame

local UserBox = Instance.new("TextBox")
UserBox.Size = UDim2.new(1, -20, 0, 35)
UserBox.Position = UDim2.new(0, 10, 0, 10)
UserBox.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
UserBox.TextColor3 = Color3.fromRGB(220, 220, 255)
UserBox.PlaceholderText = "Target username..."
UserBox.Text = ""
UserBox.Font = Enum.Font.Gotham
UserBox.TextSize = 14
UserBox.Parent = Content

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -20, 0, 35)
KeyBox.Position = UDim2.new(0, 10, 0, 55)
KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
KeyBox.TextColor3 = Color3.fromRGB(220, 220, 255)
KeyBox.PlaceholderText = "Key / Code..."
KeyBox.Text = ""
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 14
KeyBox.Parent = Content

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 50)
ToggleBtn.Position = UDim2.new(0, 10, 0, 100)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
ToggleBtn.Text = "OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 18
ToggleBtn.Parent = Content

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 25)
Status.Position = UDim2.new(0, 10, 1, -35)
Status.BackgroundTransparency = 1
Status.Text = "Ready"
Status.TextColor3 = Color3.fromRGB(160, 160, 190)
Status.Font = Enum.Font.Gotham
Status.TextSize = 13
Status.Parent = Content

local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        Frame:TweenSize(minimizedSize, "Out", "Quad", 0.25, true)
        Content.Visible = false
        MinimizeBtn.Text = "+"
        Status.Text = "Minimized"
    else
        Frame:TweenSize(fullSize, "Out", "Quad", 0.25, true)
        Content.Visible = true
        MinimizeBtn.Text = "−"
        Status.Text = enabled and "Spamming..." or "Ready"
    end
end

MinimizeBtn.MouseButton1Click:Connect(toggleMinimize)
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and isMinimized then
        toggleMinimize()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

UserBox.FocusLost:Connect(function() targetName = UserBox.Text end)
KeyBox.FocusLost:Connect(function() keyString = KeyBox.Text end)

ToggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    ToggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(170, 0, 0)
    ToggleBtn.Text = enabled and "SPAMMING" or "OFF"
    Status.Text = enabled and "Spamming " .. targetName .. "..." or "Stopped"
end)

task.spawn(function()
    while true do
        if enabled and targetName ~= "" and keyString ~= "" then
            local target = Players:FindFirstChild(targetName)
            local char = lp.Character
            local tchar = target and target.Character

            if char and tchar then
                local handler = char:FindFirstChild("ClientHandler")
                local remote = handler and handler:FindFirstChild("OnClient")

                if remote then
                    remote:FireServer("chased", tchar, keyString)
                end
            end
        end
        task.wait(0.0001)
    end
end)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local SelectMap = Workspace:WaitForChild("SelectMap")
local Voted = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Voted")

local enabled = false
local selected = "Sonic"
local isOpen = false
local isMinimized = false

local fullSize = UDim2.new(0, 230, 0, 200)
local miniSize = UDim2.new(0, 230, 0, 35)

local voteDelay = 4 -- seconds to wait before voting

print("[AutoVote] Script loaded (disabled)")

-- ================= GUI =================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoVoteGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = lp:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = fullSize
Frame.Position = UDim2.new(0.5, -115, 0.5, -100)
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
Title.Text = "Auto Vote"
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

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(1,-20,0,30)
Toggle.Position = UDim2.new(0,10,0,10)
Toggle.BackgroundColor3 = Color3.fromRGB(170,0,0)
Toggle.Text = "Disabled"
Toggle.TextColor3 = Color3.fromRGB(255,255,255)
Toggle.Font = Enum.Font.GothamBold
Toggle.TextSize = 14
Toggle.Parent = Content

local DropBtn = Instance.new("TextButton")
DropBtn.Size = UDim2.new(1,-20,0,30)
DropBtn.Position = UDim2.new(0,10,0,50)
DropBtn.BackgroundColor3 = Color3.fromRGB(40,40,60)
DropBtn.Text = selected
DropBtn.TextColor3 = Color3.fromRGB(220,220,255)
DropBtn.Font = Enum.Font.Gotham
DropBtn.TextSize = 14
DropBtn.ZIndex = 3
DropBtn.Parent = Content

local DropList = Instance.new("Frame")
DropList.Size = UDim2.new(1,-20,0,0)
DropList.Position = UDim2.new(0,10,0,80)
DropList.BackgroundColor3 = Color3.fromRGB(35,35,55)
DropList.BorderSizePixel = 0
DropList.Visible = false
DropList.ZIndex = 10
DropList.Parent = Content

local names = {
    "Amy","MetalSonic","Eggman","Blaze","Sonic",
    "Silver","Knuckles","Cream","Tails",
    "Kolossos","TailsDoll","2011x"
}

for i,name in ipairs(names) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,26)
    btn.Position = UDim2.new(0,0,0,(i-1)*26)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,70)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(220,220,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.ZIndex = 11
    btn.Parent = DropList

    btn.MouseButton1Click:Connect(function()
        selected = name
        DropBtn.Text = name
        DropList.Visible = false
        DropList.Size = UDim2.new(1,-20,0,0)
        isOpen = false
        print("[AutoVote] Selected:", name)
    end)
end

DropBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    DropList.Visible = isOpen
    DropList.Size = isOpen and UDim2.new(1,-20,0,#names*26) or UDim2.new(1,-20,0,0)
end)

Toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    Toggle.Text = enabled and "Enabled" or "Disabled"
    Toggle.BackgroundColor3 = enabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
    print("[AutoVote] Enabled:", enabled)
end)

-- ================= CORE FIX (Persistent AutoVote) =================

local function voteFolder(folder)
    if not enabled then return end
    if folder and folder:IsA("Folder") then
        task.spawn(function()
            task.wait(voteDelay)  -- wait a bit before voting
            if enabled then
                pcall(function()
                    Voted:FireServer(selected)
                end)
                print("[AutoVote] Voting for:", selected)
            end
        end)
    end
end

-- ChildAdded listener for new folders
SelectMap.ChildAdded:Connect(function(child)
    voteFolder(child)
end)

-- Persistent thread for existing folders
task.spawn(function()
    while true do
        if enabled then
            for _, folder in ipairs(SelectMap:GetChildren()) do
                voteFolder(folder)
            end
        end
        task.wait(1)
    end
end)

-- Minimize / Close buttons
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    Frame:TweenSize(isMinimized and miniSize or fullSize, "Out", "Quad", 0.2, true)
    Content.Visible = not isMinimized
    MinBtn.Text = isMinimized and "+" or "−"
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

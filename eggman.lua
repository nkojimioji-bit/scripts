local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

local TARGET_SPEEDBOOST = 2.65
local TARGET_STATE = "jetpack"

local function getPlayerModel()
    return Workspace.Players:FindFirstChild(lp.Name)
end

local function forceAttributes(model)
    if not model then return end
    
    local charName = model:GetAttribute("Character")
    if charName ~= "Eggman" then
        return
    end
    
    model:SetAttribute("SpeedBoost", TARGET_SPEEDBOOST)
    model:SetAttribute("State", TARGET_STATE)
end

local function watchAttributes(model)
    if not model then return end
    
    local charName = model:GetAttribute("Character")
    if charName ~= "Eggman" then return end
    
    model.AttributeChanged:Connect(function(attributeName)
        if attributeName == "SpeedBoost" then
            if model:GetAttribute("SpeedBoost") ~= TARGET_SPEEDBOOST then
                model:SetAttribute("SpeedBoost", TARGET_SPEEDBOOST)
            end
        elseif attributeName == "State" then
            if model:GetAttribute("State") ~= TARGET_STATE then
                model:SetAttribute("State", TARGET_STATE)
            end
        end
    end)
end

local currentModel = nil

local function setup()
    currentModel = getPlayerModel()
    
    if currentModel then
        forceAttributes(currentModel)
        watchAttributes(currentModel)
        
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
        task.wait(3)
        if not currentModel or not currentModel:IsDescendantOf(Workspace) then
            setup()
        end
    end
end)

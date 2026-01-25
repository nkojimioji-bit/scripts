local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local FORCED_JUMP_POWER = 85
local RETRY_INTERVAL = 0.5

local jumpActive = false
local humanoid
local originalJumpPower

local function enableCoreJump()
    if UserInputService.TouchEnabled then
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.JumpButton, true)
        end)
    end
end

local function applyJumpForce()
    if not humanoid or not humanoid.Parent then return end
    humanoid.UseJumpPower = true
    humanoid.JumpPower = FORCED_JUMP_POWER
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    enableCoreJump()
end

local function restoreJump()
    if humanoid and humanoid.Parent and originalJumpPower then
        humanoid.JumpPower = originalJumpPower
    end
end

local function watchRage()
    task.spawn(function()
        while true do
            task.wait(RETRY_INTERVAL)

            if player.Character then
                humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if not originalJumpPower then
                        originalJumpPower = humanoid.JumpPower
                    end

                    local rageObj =
                        workspace:FindFirstChild("Players")
                        and workspace.Players:FindFirstChild(player.Name)
                        and workspace.Players[player.Name]:FindFirstChild("Rage")

                    if rageObj then
                        if not jumpActive then
                            jumpActive = true
                            print("you're 2011x")
                        end
                        applyJumpForce()
                    else
                        if jumpActive then
                            jumpActive = false
                            restoreJump()
                            print("you're not 2011x")
                        end
                    end
                end
            end
        end
    end)
end

local function onCharacterAdded(char)
    humanoid = char:WaitForChild("Humanoid")
    originalJumpPower = humanoid.JumpPower
end

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

watchRage()

print("u should jump on invis")
-- Block all FireServer calls on MetalSonic's OnClient (without touching the remote)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Locate the exact OnClient remote
local OnClientRemote = ReplicatedStorage
    :WaitForChild("ClientAssets", 10)
    :WaitForChild("ClientMoveset", 10)
    :WaitForChild("Survivor", 10)
    :WaitForChild("MetalSonic", 10)
    :WaitForChild("OnClient", 10)

if not OnClientRemote or not OnClientRemote:IsA("RemoteEvent") then
    warn("MetalSonic OnClient remote not found")
    return
end

-- Hook namecall to intercept FireServer
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    
    if method == "FireServer" and self == OnClientRemote then
        -- Block the call completely (do nothing)
        print("Blocked FireServer on MetalSonic OnClient")
        return  -- drop the call
    end
    
    return oldNamecall(self, ...)
end

setreadonly(mt, true)

print("MetalSonic OnClient fully blocked - no moves will fire from it")
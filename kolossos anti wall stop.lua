--  block onclient

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- locate ts
local OnClientRemote = ReplicatedStorage
    :WaitForChild("ClientAssets", 10)
    :WaitForChild("ClientMoveset", 10)
    :WaitForChild("EXE", 10)
    :WaitForChild("Kolossos", 10)
    :WaitForChild("OnClient", 10)

if not OnClientRemote or not OnClientRemote:IsA("RemoteEvent") then
    warn("BOIII… I CANT FIND TS")
    return
end

-- hook something to something
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    
    if method == "FireServer" and self == OnClientRemote then
        -- block it completely
        print("boii its blocked")
        return  -- drop the call
    end
    
    return oldNamecall(self, ...)
end

setreadonly(mt, true)

print("Big K's charge isnt gonna stop on walls now'")
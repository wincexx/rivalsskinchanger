-- ==== Key Bow: полная замена + StringCurve без C0 + тетива ====

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

local vm = Player.PlayerScripts.Assets.ViewModels
local baseBow = vm.Weapons:FindFirstChild("Bow")

local keyBow = nil
for _, folder in ipairs(vm:GetChildren()) do
    if folder:IsA("Folder") and folder.Name ~= "Weapons" then
        local found = folder:FindFirstChild("Key Bow")
        if found then keyBow = found; break end
    end
end

if not baseBow then warn("[KeyBow] Bow не найден"); return end
if not keyBow then warn("[KeyBow] Key Bow не найден"); return end

local ALL_SHIFT_Y = 0.00
local BODY_SHIFT_Y = -0.00

local function ReplaceWithC0(name, refPrimary)
    local keyModel = keyBow:FindFirstChild(name)
    if not keyModel then return end

    local baseModel = baseBow:FindFirstChild(name)
    if baseModel then
        for _, c in ipairs(baseModel:GetChildren()) do c:Destroy() end
    else
        baseModel = Instance.new("Model")
        baseModel.Name = name
        baseModel.Parent = baseBow
    end

    for _, c in ipairs(keyModel:GetChildren()) do
        c:Clone().Parent = baseModel
    end

    local kp = baseModel:FindFirstChild("Primary")
    if kp and kp:IsA("BasePart") then
        baseModel.PrimaryPart = kp
    elseif not baseModel.PrimaryPart then
        local first = baseModel:FindFirstChildWhichIsA("BasePart")
        if first then baseModel.PrimaryPart = first end
    end

    if refPrimary and baseModel.PrimaryPart then
        local c0 = refPrimary.CFrame:ToObjectSpace(baseModel.PrimaryPart.CFrame)
        c0 = c0 + Vector3.new(0, ALL_SHIFT_Y + BODY_SHIFT_Y, 0)
        baseModel:SetAttribute("C0", c0)
        baseModel:SetAttribute("C1", CFrame.identity)
    end
end

-- Arrow
local baseArrow = baseBow:FindFirstChild("Arrow")
local keyArrow = keyBow:FindFirstChild("Arrow")
if baseArrow and keyArrow then
    for _, c in ipairs(baseArrow:GetChildren()) do c:Destroy() end
    for _, c in ipairs(keyArrow:GetChildren()) do c:Clone().Parent = baseArrow end
    local kp = baseArrow:FindFirstChild("Primary")
    if kp then baseArrow.PrimaryPart = kp end
end

if baseArrow and baseArrow.PrimaryPart then
    local c0 = CFrame.new(0, ALL_SHIFT_Y, 0)
    baseArrow:SetAttribute("C0", c0)
    baseArrow:SetAttribute("C1", CFrame.identity)
end

-- Body, TopArm, BottomArm
local refPrimary = baseArrow and baseArrow.PrimaryPart
if refPrimary then
    for _, name in ipairs({"Body", "TopArm", "BottomArm"}) do
        ReplaceWithC0(name, refPrimary)
    end
end

-- StringCurve без C0
local baseSC = baseBow:FindFirstChild("StringCurve")
local keySC = keyBow:FindFirstChild("StringCurve")
if baseSC and keySC then
    for _, c in ipairs(baseSC:GetChildren()) do c:Destroy() end
    for _, c in ipairs(keySC:GetChildren()) do c:Clone().Parent = baseSC end
    local kp = baseSC:FindFirstChild("Primary")
    if kp then baseSC.PrimaryPart = kp end
end

-- Заглушки
if baseArrow and baseArrow.PrimaryPart then
    for _, stubName in ipairs({"Feather", "Tip"}) do
        if not baseArrow:FindFirstChild(stubName) then
            local stub = Instance.new("Part")
            stub.Name = stubName
            stub.Size = Vector3.new(0.1, 0.1, 0.1)
            stub.Transparency = 1
            stub.CanCollide = false
            stub.CanTouch = false
            stub.CanQuery = false
            stub.Massless = true
            stub.Anchored = false
            stub.CFrame = baseArrow.PrimaryPart.CFrame
            stub.Parent = baseArrow
            local w = Instance.new("WeldConstraint")
            w.Part0 = baseArrow.PrimaryPart
            w.Part1 = stub
            w.Parent = stub
        end
    end
end

-- Перепривязка Beam'ов к TopArm/BottomArm
task.spawn(function()
    task.wait(2)

    local sc = baseBow:FindFirstChild("StringCurve")
    local top = baseBow:FindFirstChild("TopArm")
    local bottom = baseBow:FindFirstChild("BottomArm")

    if not (sc and top and bottom) then return end

    local function WaitFor(model, name, timeout)
        local found = model:FindFirstChild(name, true)
        local start = tick()
        while not found and tick() - start < (timeout or 5) do
            task.wait(0.1)
            found = model:FindFirstChild(name, true)
        end
        return found
    end

    local beamCenter = WaitFor(sc, "BeamCenter", 5)
    local beamTop = WaitFor(top, "BeamTop", 5)
    local beamBottom = WaitFor(bottom, "BeamBottom", 5)

    if not (beamCenter and beamTop and beamBottom) then return end

    for _, c in ipairs(sc:GetDescendants()) do
        if c:IsA("Beam") then
            c.Enabled = true
            c.Transparency = NumberSequence.new(0)
            c.Width0 = 0.05
            c.Width1 = 0.05
            c.FaceCamera = true
            c.LightInfluence = 0
            c.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))

            if c.Name == "TopBeam" then
                c.Attachment0 = beamTop
                c.Attachment1 = beamCenter
            elseif c.Name == "BottomBeam" then
                c.Attachment0 = beamBottom
                c.Attachment1 = beamCenter
            end
        end
    end
end)

-- INFO
local ItemLibraryModule = RS.Modules:FindFirstChild("ItemLibrary")
if ItemLibraryModule then
    local ok, ItemLibrary = pcall(require, ItemLibraryModule)
    if ok and ItemLibrary and ItemLibrary.ViewModels then
        local bowInfo = ItemLibrary.ViewModels["Bow"]
        local keyBowInfo = ItemLibrary.ViewModels["Key Bow"]
        if bowInfo and keyBowInfo then
            local origRoot = bowInfo.RootPartOffset
            local origImg = bowInfo.Image
            local origImgHR = bowInfo.ImageHighResolution
            local origElim = bowInfo.EliminationFeedImage

            bowInfo.Animations = keyBowInfo.Animations
            bowInfo.RootPartOffset = origRoot
            bowInfo.Image = origImg
            bowInfo.ImageHighResolution = origImgHR
            bowInfo.EliminationFeedImage = origElim
        end
    end
end

print("[KeyBow] Готово. Зайди в раунд.")

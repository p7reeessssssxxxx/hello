local rs = game:GetService("ReplicatedStorage")
local cs = game:GetService("CollectionService")
local plrs = game:GetService("Players")
local rsRun = game:GetService("RunService")

local lp = plrs.LocalPlayer
local cam = workspace.CurrentCamera

local fnHatch = getupvalue(getupvalue(getconnections(rs.GameEvents.PetEggService.OnClientEvent)[1].Function, 1), 2)
local eggList = getupvalue(fnHatch, 1)
local petList = getupvalue(fnHatch, 2)

local labelCache = {}
local trackedEggs = {}

local function findEggById(uuid)
    for egg in eggList do
        if egg:GetAttribute("OBJECT_UUID") ~= uuid then continue end
        return egg
    end
end

local function refreshLabel(uuid, pet)
    local model = findEggById(uuid)
    if not model or not labelCache[uuid] then return end

    local eggType = model:GetAttribute("EggName")
    labelCache[uuid].Text = `{eggType} | {pet}`
end

local function createLabel(model)
    if model:GetAttribute("OWNER") ~= lp.Name then return end

    local eggType = model:GetAttribute("EggName")
    local pet = petList[model:GetAttribute("OBJECT_UUID")]
    local uuid = model:GetAttribute("OBJECT_UUID")
    if not uuid then return end

    local txt = Drawing.new("Text")
    txt.Text = `{eggType} | {pet or "?"}`
    txt.Size = 18
    txt.Color = Color3.new(1, 1, 1)
    txt.Outline = true
    txt.OutlineColor = Color3.new(0, 0, 0)
    txt.Center = true
    txt.Visible = false

    labelCache[uuid] = txt
    trackedEggs[uuid] = model
end

local function removeLabel(model)
    if model:GetAttribute("OWNER") ~= lp.Name then return end

    local uuid = model:GetAttribute("OBJECT_UUID")
    if labelCache[uuid] then
        labelCache[uuid]:Remove()
        labelCache[uuid] = nil
    end

    trackedEggs[uuid] = nil
end

local function updateLabels()
    for uuid, model in trackedEggs do
        if not model or not model:IsDescendantOf(workspace) then
            trackedEggs[uuid] = nil
            if labelCache[uuid] then
                labelCache[uuid].Visible = false
            end
            continue
        end

        local lbl = labelCache[uuid]
        if lbl then
            local pos, visible = cam:WorldToViewportPoint(model:GetPivot().Position)
            lbl.Position = Vector2.new(pos.X, pos.Y)
            lbl.Visible = visible
        end
    end
end

for _, inst in cs:GetTagged("PetEggServer") do
    task.spawn(createLabel, inst)
end

cs:GetInstanceAddedSignal("PetEggServer"):Connect(createLabel)
cs:GetInstanceRemovedSignal("PetEggServer"):Connect(removeLabel)

local original; original = hookfunction(getconnections(rs.GameEvents.EggReadyToHatch_RE.OnClientEvent)[1].Function, newcclosure(function(uuid, pet)
    refreshLabel(uuid, pet)
    return original(uuid, pet)
end))

rsRun.PreRender:Connect(updateLabels)

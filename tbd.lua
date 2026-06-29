local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local speedEnabled = false
local speedValue = 16

local wallhopEnabled = false
local infJumpEnabled = false

local espEnabled = false
local espMode = "white"
local rainbowEnabled = false
local hue = 0

local xrayEnabled = false
local xrayOpacity = 50

local hitboxEnabled = false
local hitboxSize = 2
local originalSizes = {}

local aimbotEnabled = false
local autoTrackEnabled = false

local autoBombEnabled = false
local bombBusy = false

local autoSaveEnabled = true

local jumpQueued = false
local lastWallhop = 0
local wallhopRotating = false

local espObjects = {}
local mapParts = {}

local function cacheMap()
mapParts = {}
for _, v in ipairs(workspace:GetDescendants()) do
if v:IsA("BasePart") then
local model = v:FindFirstAncestorOfClass("Model")
if not model or not Players:GetPlayerFromCharacter(model) then
table.insert(mapParts, v)
end
elseif v:IsA("Terrain") then
table.insert(mapParts, v)
end
end
end

cacheMap()

workspace.DescendantAdded:Connect(function(v)
if v:IsA("BasePart") then
local model = v:FindFirstAncestorOfClass("Model")
if not model or not Players:GetPlayerFromCharacter(model) then
table.insert(mapParts, v)
end
elseif v:IsA("Terrain") then
table.insert(mapParts, v)
end
end)

local function save()
if not autoSaveEnabled then return end
player:SetAttribute("esp", espEnabled)
player:SetAttribute("espMode", espMode)
player:SetAttribute("rainbow", rainbowEnabled)
player:SetAttribute("xray", xrayEnabled)
player:SetAttribute("xrayOpacity", xrayOpacity)
player:SetAttribute("speed", speedEnabled)
player:SetAttribute("speedValue", speedValue)
player:SetAttribute("wallhop", wallhopEnabled)
player:SetAttribute("infJump", infJumpEnabled)
player:SetAttribute("hitbox", hitboxEnabled)
player:SetAttribute("hitboxSize", hitboxSize)
player:SetAttribute("autoBomb", autoBombEnabled)
player:SetAttribute("aimbot", aimbotEnabled)
player:SetAttribute("autoTrack", autoTrackEnabled)
end

local function load()
espEnabled = player:GetAttribute("esp") or false
espMode = player:GetAttribute("espMode") or "white"
rainbowEnabled = player:GetAttribute("rainbow") or false
xrayEnabled = player:GetAttribute("xray") or false
xrayOpacity = player:GetAttribute("xrayOpacity") or 50
speedEnabled = player:GetAttribute("speed") or false
speedValue = player:GetAttribute("speedValue") or 16
wallhopEnabled = player:GetAttribute("wallhop") or false
infJumpEnabled = player:GetAttribute("infJump") or false
hitboxEnabled = player:GetAttribute("hitbox") or false
hitboxSize = player:GetAttribute("hitboxSize") or 2
autoBombEnabled = player:GetAttribute("autoBomb") or false
aimbotEnabled = player:GetAttribute("aimbot") or false
autoTrackEnabled = player:GetAttribute("autoTrack") or false
end

load()

local function getChar()
return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid()
return getChar():FindFirstChildOfClass("Humanoid")
end

local function getRoot()
return getChar():FindFirstChild("HumanoidRootPart")
end

local function getColor()
if rainbowEnabled then
hue = (hue + 0.006) % 1
return Color3.fromHSV(hue, 1, 1)
end
if espMode == "white" then return Color3.fromRGB(255,255,255) end
if espMode == "red" then return Color3.fromRGB(255,60,60) end
if espMode == "blue" then return Color3.fromRGB(80,160,255) end
if espMode == "green" then return Color3.fromRGB(80,255,120) end
if espMode == "yellow" then return Color3.fromRGB(255,230,80) end
if espMode == "purple" then return Color3.fromRGB(180,90,255) end
if espMode == "black" then return Color3.fromRGB(0,0,0) end
if espMode == "pink" then return Color3.fromRGB(255,105,180) end
if espMode == "orange" then return Color3.fromRGB(255,140,0) end
return Color3.fromRGB(255,255,255)
end

local function applyXrayWorld()
local val = xrayEnabled and (xrayOpacity / 100) or 0
for _, v in ipairs(mapParts) do
if v:IsA("BasePart") then
v.LocalTransparencyModifier = val
elseif v:IsA("Terrain") then
v.Transparency = val
end
end
end

local function createESP(plr)
if plr == player then return end
local function setup(char)
if espObjects[plr] and espObjects[plr].highlight then
espObjects[plr].highlight:Destroy()
end
local highlight = Instance.new("Highlight")
highlight.FillTransparency = 1
highlight.OutlineTransparency = 0
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = espEnabled
highlight.Parent = char
espObjects[plr] = { highlight = highlight }
plr.CharacterAdded:Connect(function(c)
if highlight then highlight.Parent = c end
end)
end
if plr.Character then setup(plr.Character) end
plr.CharacterAdded:Connect(setup)
end

local function storeOriginalHitbox(plr)
if plr == player then return end
if plr.Character then
local root = plr.Character:FindFirstChild("HumanoidRootPart")
if root and not originalSizes[plr] then
originalSizes[plr] = {
Size = root.Size,
Transparency = root.Transparency,
Material = root.Material,
CanCollide = root.CanCollide,
}
end
end
end

local function restoreHitbox(plr)
if plr == player then return end
if plr.Character then
local root = plr.Character:FindFirstChild("HumanoidRootPart")
local orig = originalSizes[plr]
if root and orig then
root.Size = orig.Size
root.Transparency = orig.Transparency
root.Material = orig.Material
root.CanCollide = orig.CanCollide
end
end
end

local function restoreAllHitboxes()
for _, plr in ipairs(Players:GetPlayers()) do
restoreHitbox(plr)
end
end

for _, p in ipairs(Players:GetPlayers()) do
createESP(p)
storeOriginalHitbox(p)
end

Players.PlayerAdded:Connect(function(plr)
createESP(plr)
plr.CharacterAdded:Connect(function(char)
task.wait()
storeOriginalHitbox(plr)
end)
end)

Players.PlayerRemoving:Connect(function(plr)
originalSizes[plr] = nil
espObjects[plr] = nil
end)

local function getNearestPlayer()
local hrp = getRoot()
if not hrp then return nil end
local closest
local dist = math.huge
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= player and plr.Character then
local root = plr.Character:FindFirstChild("HumanoidRootPart")
if root then
local d = (root.Position - hrp.Position).Magnitude
if d < dist then
dist = d
closest = plr
end
end
end
end
return closest
end

local function giveBomb()
if bombBusy then return end
bombBusy = true
local hrp = getRoot()
if not hrp then bombBusy = false return end
local origin = hrp.CFrame
local target = getNearestPlayer()
if not target or not target.Character then bombBusy = false return end
local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
if not targetRoot then bombBusy = false return end
hrp.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -2)
local elapsed = 0
local spinConn
spinConn = RunService.Heartbeat:Connect(function(dt)
elapsed = elapsed + dt
if not hrp or not targetRoot then
spinConn:Disconnect()
bombBusy = false
return
end
local angle = elapsed * math.pi * 4
hrp.CFrame = targetRoot.CFrame * CFrame.new(math.cos(angle) * 2, 0, math.sin(angle) * 2)
if elapsed >= 1 then
spinConn:Disconnect()
hrp.CFrame = origin
bombBusy = false
end
end)
end

local function startAutoBomb()
task.spawn(function()
while autoBombEnabled do
giveBomb()
task.wait(3)
end
end)
end

local function nearWall()
local char = getChar()
local hrp = getRoot()
local hum = getHumanoid()
if not hrp or not hum then return false, nil end
if hum.FloorMaterial ~= Enum.Material.Air then return false, nil end
local params = RaycastParams.new()
params.FilterDescendantsInstances = {char}
params.FilterType = Enum.RaycastFilterType.Exclude
local dirs = {
hrp.CFrame.RightVector,
-hrp.CFrame.RightVector,
hrp.CFrame.LookVector,
-hrp.CFrame.LookVector,
}
for _, dir in ipairs(dirs) do
local result = workspace:Raycast(hrp.Position, dir * 2.2, params)
if result then
return true, dir
end
end
return false, nil
end

local function doWallhopSpin(hrp)
if wallhopRotating then return end
wallhopRotating = true

local totalAngle = 0
local targetAngle = math.rad(90)
local duration = 0.12
local elapsed = 0
local phase = 1

local conn
conn = RunService.Heartbeat:Connect(function(dt)
if not hrp then
conn:Disconnect()
wallhopRotating = false
return
end

elapsed = elapsed + dt
local alpha = math.min(elapsed / duration, 1)
local smooth = 1 - (1 - alpha) ^ 3
local frameAngle = (targetAngle * smooth) - totalAngle
totalAngle = totalAngle + frameAngle

local pos = hrp.Position
local currentAngles = hrp.CFrame - hrp.CFrame.Position
hrp.CFrame = CFrame.new(pos) * currentAngles * CFrame.Angles(0, frameAngle * (phase == 1 and 1 or -1), 0)

if alpha >= 1 then
elapsed = 0
totalAngle = 0
if phase == 1 then
phase = 2
else
conn:Disconnect()
wallhopRotating = false
end
end
end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FloatingWidgets"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

local BTN_WIDTH = 140
local BTN_HEIGHT = 36
local BTN_GAP = 8
local BTN_RIGHT = 16
local BTN_TOP = 60
local ARROW_W = 22
local ARROW_GAP = 4

local ARROW_X_OFFSET = -(ARROW_W + BTN_RIGHT)
local PILL_X_OFFSET = -(ARROW_W + BTN_RIGHT + ARROW_GAP + BTN_WIDTH)
local PILL_HIDDEN_X_OFFSET = -(ARROW_W + BTN_RIGHT)

local function makeWidget(index, labelText, isToggle)
local yOffset = BTN_TOP + (index - 1) * (BTN_HEIGHT + BTN_GAP)
local collapsed = false
local tweening = false

local arrowBtn = Instance.new("TextButton")
arrowBtn.Size = UDim2.new(0, ARROW_W, 0, BTN_HEIGHT)
arrowBtn.Position = UDim2.new(1, ARROW_X_OFFSET, 0, yOffset)
arrowBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
arrowBtn.BorderSizePixel = 0
arrowBtn.Text = "‹"
arrowBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
arrowBtn.TextSize = 16
arrowBtn.Font = Enum.Font.GothamBold
arrowBtn.AutoButtonColor = false
arrowBtn.ZIndex = 2
arrowBtn.Parent = screenGui

local ac = Instance.new("UICorner")
ac.CornerRadius = UDim.new(1, 0)
ac.Parent = arrowBtn

local as = Instance.new("UIStroke")
as.Color = Color3.fromRGB(60, 60, 70)
as.Thickness = 1.2
as.Parent = arrowBtn

local pill = Instance.new("TextButton")
pill.Size = UDim2.new(0, BTN_WIDTH, 0, BTN_HEIGHT)
pill.Position = UDim2.new(1, PILL_X_OFFSET, 0, yOffset)
pill.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
pill.BorderSizePixel = 0
pill.Text = ""
pill.AutoButtonColor = false
pill.ZIndex = 1
pill.Parent = screenGui

local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(1, 0)
pc.Parent = pill

local ps = Instance.new("UIStroke")
ps.Color = Color3.fromRGB(60, 60, 70)
ps.Thickness = 1.2
ps.Parent = pill

local dot
if isToggle then
dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 10, 0, 10)
dot.Position = UDim2.new(0, 12, 0.5, -5)
dot.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
dot.BorderSizePixel = 0
dot.ZIndex = 2
dot.Parent = pill
local dc = Instance.new("UICorner")
dc.CornerRadius = UDim.new(1, 0)
dc.Parent = dot
end

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, isToggle and -30 or -16, 1, 0)
label.Position = UDim2.new(0, isToggle and 28 or 12, 0, 0)
label.BackgroundTransparency = 1
label.Text = labelText
label.TextColor3 = Color3.fromRGB(210, 210, 220)
label.TextSize = 13
label.Font = Enum.Font.GothamMedium
label.TextXAlignment = Enum.TextXAlignment.Left
label.ZIndex = 2
label.Parent = pill

arrowBtn.MouseButton1Click:Connect(function()
if tweening then return end
tweening = true
collapsed = not collapsed

arrowBtn.Text = collapsed and "›" or "‹"

if collapsed then
pill.Visible = false
tweening = false
return
else
pill.Visible = true
pill.Position = UDim2.new(1, PILL_HIDDEN_X_OFFSET, 0, yOffset)
end

local startX = pill.Position.X.Offset
local targetX = PILL_X_OFFSET

local elapsed = 0
local duration = 0.22
local conn
conn = RunService.Heartbeat:Connect(function(dt)
elapsed = elapsed + dt
local alpha = math.min(elapsed / duration, 1)
local smooth = 1 - (1 - alpha) ^ 3
pill.Position = UDim2.new(1, startX + (targetX - startX) * smooth, 0, yOffset)
if alpha >= 1 then
conn:Disconnect()
tweening = false
end
end)
end)

return pill, dot
end

local autoTrackBtn, autoTrackDot = makeWidget(1, "auto track", true)
local aimbotBtn, aimbotDot = makeWidget(2, "aimbot", true)
local giveBombBtn = makeWidget(3, "give bomb", false)

local function updateAutoTrackDot()
autoTrackDot.BackgroundColor3 = autoTrackEnabled
and Color3.fromRGB(60, 220, 100)
or Color3.fromRGB(220, 50, 50)
end

local function updateAimbotDot()
aimbotDot.BackgroundColor3 = aimbotEnabled
and Color3.fromRGB(60, 220, 100)
or Color3.fromRGB(220, 50, 50)
end

updateAutoTrackDot()
updateAimbotDot()

autoTrackBtn.MouseButton1Click:Connect(function()
autoTrackEnabled = not autoTrackEnabled
updateAutoTrackDot()
save()
end)

aimbotBtn.MouseButton1Click:Connect(function()
aimbotEnabled = not aimbotEnabled
updateAimbotDot()
save()
end)

giveBombBtn.MouseButton1Click:Connect(function()
giveBomb()
end)

UserInputService.JumpRequest:Connect(function()
jumpQueued = true
end)

RunService.Heartbeat:Connect(function()
local hum = getHumanoid()
local hrp = getRoot()
if not hum or not hrp then return end

hum.WalkSpeed = speedEnabled and speedValue or 16

local color = getColor()
for _, obj in pairs(espObjects) do
if obj.highlight then
obj.highlight.OutlineColor = color
obj.highlight.Enabled = espEnabled
end
end

applyXrayWorld()

if hitboxEnabled then
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= player and plr.Character then
local root = plr.Character:FindFirstChild("HumanoidRootPart")
if root then
root.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
root.Transparency = 0.5
root.Material = Enum.Material.ForceField
root.CanCollide = false
end
end
end
end

local target = getNearestPlayer()

if autoTrackEnabled and target and target.Character then
local root = target.Character:FindFirstChild("HumanoidRootPart")
if root then
hrp.CFrame = hrp.CFrame:Lerp(root.CFrame, 0.18)
camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, root.Position), 0.25)
end
elseif aimbotEnabled and target and target.Character then
local root = target.Character:FindFirstChild("HumanoidRootPart")
if root then
local dir = root.Position - hrp.Position
dir = Vector3.new(dir.X, 0, dir.Z)
if dir.Magnitude > 0 then
hrp.CFrame = hrp.CFrame:Lerp(CFrame.lookAt(hrp.Position, hrp.Position + dir), 0.15)
end
camera.CFrame = CFrame.lookAt(camera.CFrame.Position, root.Position)
end
end

local now = tick()

if infJumpEnabled and not wallhopEnabled then
if jumpQueued then
jumpQueued = false
if hum.FloorMaterial == Enum.Material.Air then
hum:ChangeState(Enum.HumanoidStateType.Jumping)
end
end
return
end

if wallhopEnabled then
if jumpQueued then
jumpQueued = false
local onWall = nearWall()
if hum.FloorMaterial == Enum.Material.Air and onWall then
if now - lastWallhop >= 0.3 then
lastWallhop = now
hum:ChangeState(Enum.HumanoidStateType.Jumping)
task.spawn(doWallhopSpin, hrp)
end
end
end
end

save()
end)

local Window = WindUI:CreateWindow({
Title = "orbx hub",
Icon = "orbit",
Theme = "Dark",
})

local Main = Window:Tab({ Title = "features", Icon = "star" })
local Settings = Window:Tab({ Title = "settings", Icon = "wrench" })
local Info = Window:Tab({ Title = "info", Icon = "info" })

Main:Section({ Title = "movement" })

Main:Toggle({ Title = "speed", Value = speedEnabled, Callback = function(v) speedEnabled = v save() end })
Main:Slider({ Title = "speed", Step = 1, Value = { Min = 0, Max = 44, Default = speedValue }, Callback = function(v) speedValue = v save() end })
Main:Toggle({ Title = "wallhop", Value = wallhopEnabled, Callback = function(v) wallhopEnabled = v save() end })
Main:Toggle({ Title = "inf jump", Value = infJumpEnabled, Callback = function(v) infJumpEnabled = v save() end })

Main:Toggle({
Title = "auto give bomb",
Value = autoBombEnabled,
Callback = function(v)
autoBombEnabled = v
if v then startAutoBomb() end
save()
end
})

Main:Section({ Title = "visuals" })

Main:Dropdown({
Title = "esp color",
Values = { "white", "black", "red", "orange", "yellow", "green", "blue", "purple", "pink", "rainbow" },
Default = rainbowEnabled and "rainbow" or espMode,
Callback = function(v)
if v == "rainbow" then
rainbowEnabled = true
espMode = "white"
else
rainbowEnabled = false
espMode = v
end
save()
end
})

Main:Toggle({ Title = "player esp", Value = espEnabled, Callback = function(v) espEnabled = v save() end })
Main:Toggle({ Title = "x-ray", Value = xrayEnabled, Callback = function(v) xrayEnabled = v save() end })

Main:Slider({
Title = "x-ray opacity",
Step = 1,
Value = { Min = 0, Max = 100, Default = xrayOpacity },
Callback = function(v) xrayOpacity = v save() end
})

Main:Section({ Title = "hitbox" })

Main:Toggle({
Title = "hitbox expander",
Value = hitboxEnabled,
Callback = function(v)
hitboxEnabled = v
if not v then restoreAllHitboxes() end
save()
end
})

Main:Slider({
Title = "hitbox size",
Step = 1,
Value = { Min = 1, Max = 14, Default = hitboxSize },
Callback = function(v) hitboxSize = v save() end
})

Settings:Toggle({
Title = "auto save",
Value = true,
Callback = function(v)
autoSaveEnabled = v
end
})

Settings:Button({
Title = "kill ui",
Callback = function()
Window:Destroy()
end
})

Info:Paragraph({
Title = "about",
Desc = "welcome to orbx hub, join our discord for more scripts"
})

Info:Button({
Title = "copy discord",
Callback = function()
end
})

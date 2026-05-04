local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VIM = game:GetService("VirtualInputManager")

--[[
	LEVEL SYSTEM:
	Level 1: .summon .tp .orbit .spin .nospin .stop .void .idle .freeze .behind .above .speed .status .ver .script .rj .re .cmd
	Level 2: Level 1 + .fling .stopfling .opp .unopp .tpwall1 .tpwall2 .wl .unwl
	Level 3: Level 1-2 + .autokill .stopautokill .1 .2 .3 .4
	Level 4: Level 1-3 + .reset
	Owner:   Full access + .owneron .owneroff
]]
local LEVEL_USERS = {
	[1] = {"flamingkid538"},
	[2] = {"glonk306", "digitoi181143", "472012"},
	[3] = {},
	[4] = {},
	["owner"] = {"flamingkid58", "krepahhh"},
}

local OWNER_DISPLAY = {
	["flamingkid58"] = "Glonk",
	["krepahhh"] = "xDa",
}

local HOST_USERNAME = _G.HOST_USERNAME or "YourMainAccountHere"
local OFFSET_RIGHT = _G.OFFSET_RIGHT or 2
local OFFSET_UP = _G.OFFSET_UP or 3
local OFFSET_BACK = _G.OFFSET_BACK or 4
local FOLLOW_SPEED = _G.FOLLOW_SPEED or 0.3
local ORBIT_SPEED = _G.ORBIT_SPEED or 2
local ORBIT_HEIGHT = _G.ORBIT_HEIGHT or 3

local WALL_POSITION = Vector3.new(310, 671, 487)

local skillKeys = {
	["1"] = Enum.KeyCode.One,
	["2"] = Enum.KeyCode.Two,
	["3"] = Enum.KeyCode.Three,
	["4"] = Enum.KeyCode.Four,
}

local skillCooldowns = {
	["1"] = 20,
	["2"] = 15,
	["3"] = 10,
	["4"] = 20,
}

local skillRanges = {
	["1"] = 3,
	["2"] = 3,
	["3"] = 3,
	["4"] = 3,
}

local lastUsed = {}
local saidCD = {}
local autoKillTargets = {}
local autoKillEnabled = false

getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

local ownerModeEnabled = true

-- Simple whitelist: stores the granted level number directly
-- e.g. whitelistedUsers["someuser"] = 3
local whitelistedUsers = {}

local function getPlayerExact(username)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name == username then return plr end
	end
	return nil
end

local function isOwner(username)
	for _, name in ipairs(LEVEL_USERS["owner"]) do
		if name == username then return true end
	end
	return false
end

local function getOwnerDisplay(username)
	return OWNER_DISPLAY[username] or username
end

-- Returns "owner", 4, 3, 2, 1, or nil (from LEVEL_USERS only)
local function getUserLevelFromTable(username)
	for _, name in ipairs(LEVEL_USERS["owner"]) do
		if name == username then return "owner" end
	end
	for level = 4, 1, -1 do
		for _, name in ipairs(LEVEL_USERS[level]) do
			if name == username then return level end
		end
	end
	return nil
end

-- Returns numeric priority for comparison
local function getLevelPriority(level)
	if level == "owner" then return 99 end
	if type(level) == "number" then return level end
	return 0
end

local host = getPlayerExact(HOST_USERNAME)
local stand = Players.LocalPlayer

if not stand then
	warn("Executor couldn't detect LocalPlayer.")
	return
end

local ownersInGame = {}
for _, ownerName in ipairs(LEVEL_USERS["owner"]) do
	local owner = getPlayerExact(ownerName)
	if owner then table.insert(ownersInGame, owner) end
end

local oppList = {}
local currentController = host
local floatOffset = 0
local floatSpeed = 2

local function createWatermark()
	local playerGui = stand:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("FlingBotWatermark")
	if existing then existing:Destroy() end
	local gui = Instance.new("ScreenGui")
	gui.Name = "FlingBotWatermark"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 80)
	frame.Position = UDim2.new(0.5, -150, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "Glonk's FlingBot"
	title.TextColor3 = Color3.fromRGB(255, 80, 80)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 20
	title.Parent = frame
	local discordBtn = Instance.new("TextButton")
	discordBtn.Size = UDim2.new(0, 260, 0, 35)
	discordBtn.Position = UDim2.new(0.5, -130, 0, 40)
	discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	discordBtn.BorderSizePixel = 0
	discordBtn.Text = "Click here to copy Discord"
	discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	discordBtn.Font = Enum.Font.SourceSansBold
	discordBtn.TextSize = 16
	discordBtn.Parent = frame
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = discordBtn
	discordBtn.MouseButton1Click:Connect(function()
		setclipboard("https://discord.gg/DJuKxGVAck")
		discordBtn.Text = "Copied!"
		discordBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
		task.wait(2)
		discordBtn.Text = "Click here to copy Discord"
		discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	end)
	gui.Parent = playerGui
end

local function createUI(text)
	local playerGui = stand:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("StandUI")
	if existing then existing:Destroy() end
	local gui = Instance.new("ScreenGui")
	gui.Name = "StandUI"
	gui.ResetOnSpawn = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 400, 0, 60)
	label.Position = UDim2.new(0.5, -200, 0.5, -30)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = text
	label.Parent = gui
	gui.Parent = playerGui
	task.delay(5, function()
		if gui then gui:Destroy() end
	end)
end

local function sendChatMessage(text)
	local textChatService = game:GetService("TextChatService")
	if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local channel = textChatService.TextChannels.RBXGeneral
		if channel then channel:SendAsync(text) end
	else
		game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(text, "All")
	end
end

if host then
	local statusText = "Stand Linked\nHost: " .. host.Name
	if #ownersInGame > 0 then statusText = statusText .. "\nOwners in game!" end
	createUI(statusText)
	createWatermark()
else
	createUI("No Host Found")
	return
end

print("Host:", host.Name)
print("Stand:", stand.Name)

RunService.Stepped:Connect(function()
	if stand.Character then
		for _, v in ipairs(stand.Character:GetDescendants()) do
			if v:IsA("BasePart") then v.CanCollide = false end
		end
	end
end)

pcall(function()
	sethiddenproperty(stand, "SimulationRadius", math.huge)
	sethiddenproperty(stand, "MaxSimulationRadius", math.huge)
end)

local mode = "idle"
local modeBeforeFling = "idle"
local orbitRadius = 15
local orbitAngle = 0
local isFrozen = false
local isSpinning = false
local spinSpeed = 5
local spinAngle = 0
local isFlinging = false
local isFlingingAll = false
local autoFlingEnabled = false
local currentFlingTarget = nil

local DEFAULT = {
	OFFSET_RIGHT = OFFSET_RIGHT,
	OFFSET_UP = OFFSET_UP,
	OFFSET_BACK = OFFSET_BACK,
	FOLLOW_SPEED = FOLLOW_SPEED,
}

local function sendToSky()
	if stand.Character then
		local hrp = stand.Character:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CFrame = CFrame.new(hrp.Position.X, 2000, hrp.Position.Z) end
	end
end

local function pressKey(keyCode)
	VIM:SendKeyEvent(true, keyCode, false, game)
	task.wait(0.05)
	VIM:SendKeyEvent(false, keyCode, false, game)
end

local function applyPose()
	if not stand.Character then return end
	local humanoid = stand.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do track:Stop() end
	local animateScript = stand.Character:FindFirstChild("Animate")
	if animateScript then animateScript.Disabled = true end
	if stand.Character:FindFirstChild("Torso") then
		local torso = stand.Character.Torso
		local leftShoulder = torso:FindFirstChild("Left Shoulder")
		local rightShoulder = torso:FindFirstChild("Right Shoulder")
		local leftHip = torso:FindFirstChild("Left Hip")
		local rightHip = torso:FindFirstChild("Right Hip")
		if leftShoulder then leftShoulder.C0 = CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(0), math.rad(-90), math.rad(-70)) end
		if rightShoulder then rightShoulder.C0 = CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(70)) end
		if leftHip then leftHip.C0 = CFrame.new(-1, -1, 0) * CFrame.Angles(math.rad(0), math.rad(-90), math.rad(-20)) end
		if rightHip then rightHip.C0 = CFrame.new(1, -1, 0) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(20)) end
	else
		local torso = stand.Character:FindFirstChild("UpperTorso")
		if not torso then return end
		local leftShoulder = torso:FindFirstChild("LeftShoulder")
		local rightShoulder = torso:FindFirstChild("RightShoulder")
		local lowerTorso = stand.Character:FindFirstChild("LowerTorso")
		local leftHip = lowerTorso and lowerTorso:FindFirstChild("LeftHip")
		local rightHip = lowerTorso and lowerTorso:FindFirstChild("RightHip")
		if leftShoulder then leftShoulder.C0 = CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(0), math.rad(-90), math.rad(-70)) end
		if rightShoulder then rightShoulder.C0 = CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(70)) end
		if leftHip then leftHip.C0 = CFrame.new(-1, -1, 0) * CFrame.Angles(math.rad(0), math.rad(-90), math.rad(-20)) end
		if rightHip then rightHip.C0 = CFrame.new(1, -1, 0) * CFrame.Angles(math.rad(0), math.rad(90), math.rad(20)) end
	end
end

local function removePose()
	if not stand.Character then return end
	local humanoid = stand.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
	local animateScript = stand.Character:FindFirstChild("Animate")
	if animateScript then animateScript.Disabled = false end
	if stand.Character:FindFirstChild("Torso") then
		local torso = stand.Character.Torso
		local leftShoulder = torso:FindFirstChild("Left Shoulder")
		local rightShoulder = torso:FindFirstChild("Right Shoulder")
		local leftHip = torso:FindFirstChild("Left Hip")
		local rightHip = torso:FindFirstChild("Right Hip")
		if leftShoulder then leftShoulder.C0 = CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0) end
		if rightShoulder then rightShoulder.C0 = CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.rad(90), 0) end
		if leftHip then leftHip.C0 = CFrame.new(-1, -1, 0) * CFrame.Angles(0, math.rad(-90), 0) end
		if rightHip then rightHip.C0 = CFrame.new(1, -1, 0) * CFrame.Angles(0, math.rad(90), 0) end
	else
		local torso = stand.Character:FindFirstChild("UpperTorso")
		if torso then
			local leftShoulder = torso:FindFirstChild("LeftShoulder")
			local rightShoulder = torso:FindFirstChild("RightShoulder")
			if leftShoulder then leftShoulder.C0 = CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0) end
			if rightShoulder then rightShoulder.C0 = CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.rad(90), 0) end
		end
		local lowerTorso = stand.Character:FindFirstChild("LowerTorso")
		if lowerTorso then
			local leftHip = lowerTorso:FindFirstChild("LeftHip")
			local rightHip = lowerTorso:FindFirstChild("RightHip")
			if leftHip then leftHip.C0 = CFrame.new(-1, -1, 0) * CFrame.Angles(0, math.rad(-90), 0) end
			if rightHip then rightHip.C0 = CFrame.new(1, -1, 0) * CFrame.Angles(0, math.rad(90), 0) end
		end
	end
end

-- THE MAIN ACCESS LEVEL FUNCTION
-- This is the single source of truth for who has what access
-- Returns: "owner", 4, 3, 2, 1, or 0
local function getAccessLevel(player)
	-- Step 1: Owner check (always works regardless of ownerMode)
	if isOwner(player.Name) then return "owner" end

	-- Step 2: If ownerMode is off, nobody else can use the bot
	if not ownerModeEnabled then return 0 end

	-- Step 3: Host gets level 4
	if player == host then return 4 end

	-- Step 4: Check LEVEL_USERS table by exact username
	local tableLevel = getUserLevelFromTable(player.Name)
	if tableLevel then return tableLevel end

	-- Step 5: Check runtime whitelist (set via .wl command)
	local wlLevel = whitelistedUsers[player.Name]
	if wlLevel then return wlLevel end

	-- Step 6: No access
	return 0
end

local function canUseLevel(player, minLevel)
	local level = getAccessLevel(player)
	if level == "owner" then return true end
	if type(level) == "number" then return level >= minLevel end
	return false
end

local function findPlayer(query)
	query = query:lower()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.DisplayName:lower() == query then return plr end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if string.sub(plr.DisplayName:lower(), 1, #query) == query then return plr end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower() == query then return plr end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if string.sub(plr.Name:lower(), 1, #query) == query then return plr end
	end
	return nil
end

local function SkidFling(TargetPlayer)
	local Character = stand.Character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	local RootPart = Humanoid and Humanoid.RootPart
	local TCharacter = TargetPlayer.Character
	if not TCharacter then return end
	local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
	local TRootPart = THumanoid and THumanoid.RootPart
	local THead = TCharacter:FindFirstChild("Head")
	local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
	local Handle = Accessory and Accessory:FindFirstChild("Handle")
	if not (Character and Humanoid and RootPart) then createUI("Fling: Stand not ready") return end
	if RootPart.Velocity.Magnitude < 50 then getgenv().OldPos = RootPart.CFrame end
	if THumanoid and THumanoid.Sit then createUI("Fling: Target is sitting") return end
	if THead then workspace.CurrentCamera.CameraSubject = THead
	elseif Handle then workspace.CurrentCamera.CameraSubject = Handle
	elseif THumanoid then workspace.CurrentCamera.CameraSubject = THumanoid end
	if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
	local function FPos(BasePart, Pos, Ang)
		RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
		Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
		RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
		RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
	end
	local function SFBasePart(BasePart)
		local TimeToWait = 2
		local Time = tick()
		local Angle = 0
		repeat
			if RootPart and THumanoid then
				if BasePart.Velocity.Magnitude < 50 then
					Angle = Angle + 100
					FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0)) task.wait()
				else
					FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0)) task.wait()
					FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)) task.wait()
				end
			end
		until Time + TimeToWait < tick() or not isFlinging
	end
	workspace.FallenPartsDestroyHeight = 0/0
	local BV = Instance.new("BodyVelocity")
	BV.Parent = RootPart
	BV.Velocity = Vector3.new(0, 0, 0)
	BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	if TRootPart then SFBasePart(TRootPart)
	elseif THead then SFBasePart(THead)
	elseif Handle then SFBasePart(Handle)
	else createUI("Fling: No valid parts") end
	BV:Destroy()
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
	workspace.CurrentCamera.CameraSubject = Humanoid
	if getgenv().OldPos then
		repeat
			RootPart.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
			Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
			Humanoid:ChangeState("GettingUp")
			for _, part in pairs(Character:GetChildren()) do
				if part:IsA("BasePart") then
					part.Velocity = Vector3.new()
					part.RotVelocity = Vector3.new()
				end
			end
			task.wait()
		until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
		workspace.FallenPartsDestroyHeight = getgenv().FPDH
	end
end

local function endFling()
	isFlinging = false
	currentFlingTarget = nil
	if modeBeforeFling == "follow" then
		mode = "follow"
		applyPose()
		createUI("Fling: Done\nReturning to controller")
	else
		mode = "idle"
		sendToSky()
		createUI("Fling: Done\nReturning to sky")
	end
end

local function runFling(target, duration)
	removePose()
	currentFlingTarget = target
	isFlinging = true
	local elapsed = 0
	local flingDuration = duration or 5
	while isFlinging and elapsed < flingDuration do
		if not target or not target.Parent or not target.Character then break end
		local before = tick()
		SkidFling(target)
		elapsed += tick() - before
		task.wait(0.1)
	end
	endFling()
end

-- AUTOKILL: Uses the heartbeat loop like summon/follow mode
-- but targets the enemy's position instead of controller
-- autoKillTargets stores the target name
local autoKillController = nil -- the person who activated autokill

task.spawn(function()
	while task.wait(0.5) do
		if autoKillEnabled then
			for targetName, _ in pairs(autoKillTargets) do
				local target = Players:FindFirstChild(targetName)
				if target and target.Character then
					local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
					if targetHRP then
						-- Spam moves while staying inside target
						pressKey(Enum.KeyCode.One)
						pressKey(Enum.KeyCode.Two)
						pressKey(Enum.KeyCode.Three)
						pressKey(Enum.KeyCode.Four)
						pressKey(Enum.KeyCode.Z)
					end
				end
			end
		end
	end
end)

-- AUTO FLING LOOP
task.spawn(function()
	while task.wait(2) do
		if autoFlingEnabled and not isFlinging and not isFlingingAll then
			local oppListCopy = {}
			for playerName, _ in pairs(oppList) do oppListCopy[playerName] = true end
			for playerName, _ in pairs(oppListCopy) do
				if oppList[playerName] then
					local target = Players:FindFirstChild(playerName)
					if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
						modeBeforeFling = mode
						mode = "idle"
						isFrozen = false
						createUI("Auto-Fling: " .. target.DisplayName)
						runFling(target, 5)
						task.wait(7)
						break
					end
				end
			end
		end
	end
end)

-- MAIN LOOP
RunService.Heartbeat:Connect(function(dt)
	if not stand.Character then return end
	local standHRP = stand.Character:FindFirstChild("HumanoidRootPart")
	if not standHRP then return end

	if isFlinging or isFlingingAll then return end

	-- AUTOKILL MODE: follow the target like summon but inside them
	if autoKillEnabled then
		standHRP.AssemblyLinearVelocity = Vector3.zero
		standHRP.AssemblyAngularVelocity = Vector3.zero
		for targetName, _ in pairs(autoKillTargets) do
			local target = Players:FindFirstChild(targetName)
			if target and target.Character then
				local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
				if targetHRP then
					-- Smoothly stay inside the target like follow mode
					standHRP.CFrame = standHRP.CFrame:Lerp(targetHRP.CFrame, 0.5)
					standHRP.AssemblyLinearVelocity = Vector3.zero
				end
			end
		end
		return
	end

	if not currentController or not currentController.Character then return end
	local controllerHRP = currentController.Character:FindFirstChild("HumanoidRootPart")
	if not controllerHRP then return end

	if isFrozen then
		standHRP.AssemblyLinearVelocity = Vector3.zero
		standHRP.AssemblyAngularVelocity = Vector3.zero
		return
	end

	floatOffset += floatSpeed * dt
	if isSpinning then spinAngle += spinSpeed * dt * 60 end

	if mode == "follow" then
		local floatY = math.sin(floatOffset) * 0.5
		local targetCF = controllerHRP.CFrame * CFrame.new(OFFSET_RIGHT, OFFSET_UP + floatY, OFFSET_BACK)
		targetCF = CFrame.new(targetCF.Position, targetCF.Position + controllerHRP.CFrame.LookVector)
		standHRP.CFrame = standHRP.CFrame:Lerp(targetCF, FOLLOW_SPEED)
		if isSpinning then standHRP.CFrame = standHRP.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0) end
	elseif mode == "orbit" then
		orbitAngle += ORBIT_SPEED * dt
		local floatY = math.sin(floatOffset) * 0.5
		local x = math.cos(orbitAngle) * orbitRadius
		local z = math.sin(orbitAngle) * orbitRadius
		local pos = controllerHRP.Position + Vector3.new(x, ORBIT_HEIGHT + floatY, z)
		local targetCF = CFrame.new(pos, pos + controllerHRP.CFrame.LookVector)
		standHRP.CFrame = standHRP.CFrame:Lerp(targetCF, FOLLOW_SPEED)
		if isSpinning then standHRP.CFrame = standHRP.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0) end
	elseif mode == "above" then
		local floatY = math.sin(floatOffset) * 0.5
		local pos = controllerHRP.Position + Vector3.new(0, 8 + floatY, 0)
		local targetCF = CFrame.new(pos, pos + controllerHRP.CFrame.LookVector)
		standHRP.CFrame = standHRP.CFrame:Lerp(targetCF, FOLLOW_SPEED)
		if isSpinning then standHRP.CFrame = standHRP.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0) end
	elseif mode == "behind" then
		local floatY = math.sin(floatOffset) * 0.5
		local targetCF = controllerHRP.CFrame * CFrame.new(0, floatY, OFFSET_BACK)
		standHRP.CFrame = targetCF
		if isSpinning then standHRP.CFrame = standHRP.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0) end
	elseif mode == "idle" then
		if isSpinning then
			standHRP.CFrame = CFrame.new(standHRP.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
		end
	end
	standHRP.AssemblyLinearVelocity = Vector3.zero
	standHRP.AssemblyAngularVelocity = Vector3.zero
end)

-- COMMAND HANDLER
local function handleCommand(player, msg)
	local args = string.split(msg, " ")
	local cmd = args[1]

	-- Owner-only toggle commands (bypass all other checks)
	if cmd == ".owneron" then
		if not isOwner(player.Name) then return end
		ownerModeEnabled = true
		createUI("Owner Mode: ON\nHost can use bot")
		return
	end
	if cmd == ".owneroff" then
		if not isOwner(player.Name) then return end
		ownerModeEnabled = false
		createUI("Owner Mode: OFF\nOnly owners can use bot")
		return
	end

	-- THE GATEKEEPER: get access level and block if 0
	local accessLevel = getAccessLevel(player)
	local accessPriority = getLevelPriority(accessLevel)

	if accessPriority == 0 then
		createUI("Not whitelisted!\nJoin discord:\ndiscord.gg/DJuKxGVAck")
		return
	end

	print("[CMD " .. player.Name .. " (Lvl:" .. tostring(accessLevel) .. ")]:", msg)

	-- SKILL COMMANDS (level 3+)
	if cmd == ".1" or cmd == ".2" or cmd == ".3" or cmd == ".4" then
		if not canUseLevel(player, 3) then createUI("No access!\nLevel 3+ required") return end
		local skillNum = string.sub(cmd, 2)
		local keyCode = skillKeys[skillNum]
		if not keyCode then return end
		local rangeArg = tonumber(args[2])
		if rangeArg then skillRanges[skillNum] = rangeArg * 5 end
		local currentRange = skillRanges[skillNum]
		local now = tick()
		if now - (lastUsed[skillNum] or 0) < skillCooldowns[skillNum] then
			if not saidCD[skillNum] then
				saidCD[skillNum] = true
				createUI("Skill " .. skillNum .. " on cooldown!")
			end
			return
		end
		lastUsed[skillNum] = now
		saidCD[skillNum] = false
		if stand.Character and currentController and currentController.Character then
			local standHRP = stand.Character:FindFirstChild("HumanoidRootPart")
			local controllerHRP = currentController.Character:FindFirstChild("HumanoidRootPart")
			if standHRP and controllerHRP then
				standHRP.CFrame = controllerHRP.CFrame * CFrame.new(0, 0, -currentRange)
			end
		end
		task.wait(0.2)
		pressKey(keyCode)
		createUI("Skill " .. skillNum .. " used!\nRange: " .. currentRange .. " studs")
		return
	end

	-- LEVEL 1+ COMMANDS (everyone with access)
	if cmd == ".summon" then
		currentController = player
		mode = "follow"
		isFrozen = false
		isFlinging = false
		autoKillEnabled = false
		autoKillTargets = {}
		applyPose()
		createUI("Mode: Follow\nController: " .. player.Name)

	elseif cmd == ".tp" then
		if stand.Character and player.Character then
			local hrp = stand.Character:FindFirstChild("HumanoidRootPart")
			local playerHRP = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp and playerHRP then
				hrp.CFrame = playerHRP.CFrame * CFrame.new(OFFSET_RIGHT, OFFSET_UP, OFFSET_BACK)
				createUI("Stand: Teleported to " .. player.Name)
			end
		end

	elseif cmd == ".orbit" then
		currentController = player
		local num = tonumber(args[2])
		mode = "orbit"
		isFrozen = false
		isFlinging = false
		autoKillEnabled = false
		autoKillTargets = {}
		applyPose()
		orbitRadius = (num or 1) * 15
		createUI("Mode: Orbit r=" .. orbitRadius .. "\nController: " .. player.Name)

	elseif cmd == ".spin" then
		local num = tonumber(args[2])
		if num then
			spinSpeed = math.clamp(num, 0.1, 50)
			isSpinning = true
			createUI("Stand: Spinning\nSpeed: " .. spinSpeed)
		else
			isSpinning = true
			createUI("Stand: Spinning")
		end

	elseif cmd == ".nospin" then
		isSpinning = false
		createUI("Stand: Spin Stopped")

	elseif cmd == ".ver" then
		sendChatMessage("Version 2.2.3")
		createUI("Version 2.2.0")

	elseif cmd == ".stop" then
		mode = "idle"
		isFrozen = false
		isFlinging = false
		isFlingingAll = false
		isSpinning = false
		autoFlingEnabled = false
		autoKillEnabled = false
		autoKillTargets = {}
		currentFlingTarget = nil
		removePose()
		sendToSky()
		createUI("Stand: Stopped\nSent to sky")

	elseif cmd == ".void" then
		mode = "idle"
		isFrozen = false
		isFlinging = false
		isFlingingAll = false
		isSpinning = false
		autoKillEnabled = false
		autoKillTargets = {}
		currentFlingTarget = nil
		removePose()
		sendToSky()
		createUI("Stand: Sent to sky")

	elseif cmd == ".idle" then
		mode = "idle"
		isFrozen = false
		isFlinging = false
		isFlingingAll = false
		autoKillEnabled = false
		autoKillTargets = {}
		currentFlingTarget = nil
		removePose()
		createUI("Mode: Idle")

	elseif cmd == ".freeze" then
		mode = "idle"
		isFrozen = true
		createUI("Stand: Frozen")

	elseif cmd == ".behind" then
		currentController = player
		mode = "behind"
		isFrozen = false
		isFlinging = false
		autoKillEnabled = false
		autoKillTargets = {}
		applyPose()
		createUI("Mode: Behind\nController: " .. player.Name)

	elseif cmd == ".above" then
		currentController = player
		mode = "above"
		isFrozen = false
		isFlinging = false
		autoKillEnabled = false
		autoKillTargets = {}
		applyPose()
		createUI("Mode: Above\nController: " .. player.Name)

	elseif cmd == ".speed" then
		local num = tonumber(args[2])
		if num then
			FOLLOW_SPEED = math.clamp(num, 0.01, 1)
			createUI("Follow Speed: " .. FOLLOW_SPEED)
		end

	elseif cmd == ".status" then
		local statusMsg = "Mode: " .. mode .. "\nLevel: " .. tostring(accessLevel)
		if currentController then statusMsg = statusMsg .. "\nController: " .. currentController.Name end
		if isFrozen then statusMsg = statusMsg .. "\nFrozen: Yes" end
		if isSpinning then statusMsg = statusMsg .. "\nSpinning: " .. spinSpeed end
		if isFlinging then
			statusMsg = statusMsg .. "\nFlinging: Active"
			if currentFlingTarget then statusMsg = statusMsg .. " (" .. currentFlingTarget.DisplayName .. ")" end
		end
		if isFlingingAll then statusMsg = statusMsg .. "\nFling All: Active" end
		if autoFlingEnabled then statusMsg = statusMsg .. "\nAuto-Fling: ON" end
		if autoKillEnabled then
			statusMsg = statusMsg .. "\nAuto-Kill: ON"
			for n, _ in pairs(autoKillTargets) do
				statusMsg = statusMsg .. " (" .. n .. ")"
			end
		end
		local oppCount = 0
		for _ in pairs(oppList) do oppCount += 1 end
		if oppCount > 0 then statusMsg = statusMsg .. "\nOpp List: " .. oppCount end
		createUI(statusMsg)

	elseif cmd == ".offset" then
		local r = tonumber(args[2])
		local u = tonumber(args[3])
		local b = tonumber(args[4])
		if r then OFFSET_RIGHT = r end
		if u then OFFSET_UP = u end
		if b then OFFSET_BACK = b end
		createUI("Offset: " .. OFFSET_RIGHT .. " " .. OFFSET_UP .. " " .. OFFSET_BACK)

	elseif cmd == ".rj" then
		createUI("Rejoining server...")
		task.wait(1)
		TeleportService:Teleport(game.PlaceId, stand)

	elseif cmd == ".re" then
		createUI("Resetting character...")
		task.wait(0.5)
		if stand.Character then
			local humanoid = stand.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid.Health = 0 end
		end

	elseif cmd == ".script" then
		sendChatMessage("I am using Glonk's FlingBot made by glonk")
		createUI("Script message sent!")

	elseif cmd == ".cmd" then
		local cmdList = "LVL1: .summon .tp .orbit .spin .nospin .stop .void .idle .freeze .behind .above .speed .status .rj .re .script .ver"
		if canUseLevel(player, 2) then
			cmdList = cmdList .. " | LVL2: .fling .stopfling .opp .unopp .tpwall1 .tpwall2 .wl .unwl"
		end
		if canUseLevel(player, 3) then
			cmdList = cmdList .. " | LVL3: .autokill .stopautokill .1 .2 .3 .4"
		end
		if accessLevel == "owner" or accessLevel == 4 then
			cmdList = cmdList .. " | ADMIN: .reset .owneron .owneroff"
		end
		sendChatMessage(cmdList)
		createUI("Commands sent to chat!")

	-- LEVEL 2+ COMMANDS
	elseif cmd == ".fling" then
		if not canUseLevel(player, 2) then createUI("No access!\nLevel 2+ required") return end
		local query = table.concat(args, " ", 2):lower()
		if query == "" then createUI("Usage: .fling <name> or .fling all") return end

		if query == "all" then
			if isFlingingAll then createUI("Fling All: Already running!") return end
			isFlingingAll = true
			modeBeforeFling = mode
			mode = "idle"
			createUI("Fling All: Started!\nUse .stopfling to stop")
			task.spawn(function()
				while isFlingingAll do
					local flingQueue = {}
					for _, plr in ipairs(Players:GetPlayers()) do
						if plr ~= host and plr ~= stand and not isOwner(plr.Name) and not whitelistedUsers[plr.Name] then
							if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
								table.insert(flingQueue, plr)
							end
						end
					end
					if #flingQueue == 0 then
						createUI("Fling All: No targets left")
						isFlingingAll = false
						break
					end
					for _, target in ipairs(flingQueue) do
						if not isFlingingAll then break end
						if target and target.Parent and target.Character then
							createUI("Flinging: " .. target.DisplayName)
							runFling(target, 3)
							task.wait(4)
						end
					end
					task.wait(1)
				end
				mode = modeBeforeFling
				if mode == "follow" then applyPose() end
				createUI("Fling All: Stopped")
			end)
			return
		end

		if isFlinging then isFlinging = false task.wait(0.5) end
		local target = findPlayer(query)
		if not target then createUI("Fling: Player not found\n\"" .. query .. "\"") return end
		if not target.Character then createUI("Fling: " .. target.DisplayName .. " has no character") return end

		-- Owner protection
		if isOwner(target.Name) and accessLevel ~= "owner" then
			local ownerDisplayName = getOwnerDisplay(target.Name)
			sendChatMessage(player.DisplayName .. " tried to fling " .. ownerDisplayName .. ". Nice try.")
			modeBeforeFling = mode
			mode = "idle"
			isFrozen = false
			createUI("Protected owner!\nFlinging: " .. player.DisplayName)
			task.spawn(runFling, player, 5)
			return
		end

		-- Betrayal protection
		if accessLevel ~= "owner" and target == host then
			whitelistedUsers[player.Name] = nil
			sendChatMessage(player.DisplayName .. " tried to betray the host, they got unwhitelisted.")
			modeBeforeFling = mode
			mode = "idle"
			isFrozen = false
			createUI("BETRAYAL DETECTED!\nFlinging: " .. player.DisplayName)
			task.spawn(runFling, player, 5)
			return
		end

		modeBeforeFling = mode
		mode = "idle"
		isFrozen = false
		createUI("Flinging: " .. target.DisplayName .. "\n5 seconds...")
		task.spawn(runFling, target, 5)

	elseif cmd == ".stopfling" then
		if not canUseLevel(player, 2) then createUI("No access!\nLevel 2+ required") return end
		isFlinging = false
		isFlingingAll = false
		currentFlingTarget = nil
		createUI("Fling: Stopped")

	elseif cmd == ".opp" then
		if not canUseLevel(player, 2) then createUI("No access!\nLevel 2+ required") return end
		local query = table.concat(args, " ", 2)
		if query == "" then createUI("Usage: .opp <username>") return end
		local target = findPlayer(query)
		if not target then createUI("Opp: Not found\n\"" .. query .. "\"") return end
		if isOwner(target.Name) then createUI("Cannot opp an owner!") return end
		if target == host then createUI("Cannot opp the host!") return end
		oppList[target.Name] = true
		autoFlingEnabled = true
		createUI("Added to Opp List:\n" .. target.DisplayName .. "\nAuto-fling: ON")

	elseif cmd == ".unopp" then
		if not canUseLevel(player, 2) then createUI("No access!\nLevel 2+ required") return end
		local query = table.concat(args, " ", 2)
		if query == "" then createUI("Usage: .unopp <username>") return end
		local target = findPlayer(query)
		if not target then createUI("Unopp: Not found\n\"" .. query .. "\"") return end
		oppList[target.Name] = nil
		local oppCount = 0
		for _ in pairs(oppList) do oppCount += 1 end
		if oppCount == 0 then autoFlingEnabled = false end
		createUI("Removed from Opp List:\n" .. target.DisplayName)

	elseif cmd == ".wl" then
		if not canUseLevel(player, 2) then createUI("No access!\nLevel 2+ required") return end
		local query = table.concat(args, " ", 2)
		if query == "" then createUI("Usage: .wl <username>") return end
		local target = findPlayer(query)
		if not target then createUI("WL: Not found\n\"" .. query .. "\"") return end
		-- Grant level equal to whitelister's level, capped at 4
		-- owners grant level 4, level 2 grants level 2, etc.
		local grantLevel
		if accessLevel == "owner" then
			grantLevel = 4
		else
			grantLevel = accessLevel -- same level as whitelister
		end
		whitelistedUsers[target.Name] = grantLevel
		createUI("Whitelisted (Lvl " .. grantLevel .. "):\n" .. target.DisplayName .. "\n(@" .. target.Name .. ")")

	elseif cmd == ".unwl" then
		if not canUseLevel(player, 2) then createUI("No access!\nLevel 2+ required") return end
		local query = table.concat(args, " ", 2)
		if query == "" then createUI("Usage: .unwl <username>") return end
		local target = findPlayer(query)
		if not target then createUI("UnWL: Not found\n\"" .. query .. "\"") return end
		whitelistedUsers[target.Name] = nil
		createUI("Unwhitelisted:\n" .. target.DisplayName)

	elseif cmd == ".tpwall1" then
		if not canUseLevel(player, 2) then createUI("No access!\nLevel 2+ required") return end
		if not stand.Character or not player.Character then return end
		local standHRP = stand.Character:FindFirstChild("HumanoidRootPart")
		local playerHRP = player.Character:FindFirstChild("HumanoidRootPart")
		if not standHRP or not playerHRP then return end
		createUI("Wall move 1 incoming!")
		task.spawn(function()
			local prevMode = mode
			mode = "idle"
			isFrozen = true
			standHRP.CFrame = playerHRP.CFrame * CFrame.new(0, 0, 3)
			task.wait(0.3)
			pressKey(Enum.KeyCode.One)
			task.wait(1.5)
			standHRP.CFrame = CFrame.new(WALL_POSITION)
			createUI("Stand sent to wall!")
			task.wait(1)
			isFrozen = false
			mode = prevMode
			sendToSky()
			createUI("Stand: To sky!")
		end)

	elseif cmd == ".tpwall2" then
		if not canUseLevel(player, 2) then createUI("No access!\nLevel 2+ required") return end
		if not stand.Character or not player.Character then return end
		local standHRP = stand.Character:FindFirstChild("HumanoidRootPart")
		local playerHRP = player.Character:FindFirstChild("HumanoidRootPart")
		if not standHRP or not playerHRP then return end
		createUI("Wall move 2 incoming!")
		task.spawn(function()
			local prevMode = mode
			mode = "idle"
			isFrozen = true
			standHRP.CFrame = playerHRP.CFrame * CFrame.new(0, 0, 3)
			task.wait(0.3)
			pressKey(Enum.KeyCode.Two)
			task.wait(1.5)
			standHRP.CFrame = CFrame.new(WALL_POSITION)
			createUI("Stand sent to wall!")
			task.wait(1)
			isFrozen = false
			mode = prevMode
			sendToSky()
			createUI("Stand: To sky!")
		end)

	-- LEVEL 3+ COMMANDS
	elseif cmd == ".autokill" then
		if not canUseLevel(player, 3) then createUI("No access!\nLevel 3+ required") return end
		local query = table.concat(args, " ", 2)
		if query == "" then createUI("Usage: .autokill <username>") return end
		local target = findPlayer(query)
		if not target then createUI("AutoKill: Not found\n\"" .. query .. "\"") return end
		if isOwner(target.Name) then createUI("Cannot autokill an owner!") return end
		if target == host and accessLevel ~= "owner" then createUI("Cannot autokill the host!") return end
		autoKillTargets[target.Name] = true
		autoKillEnabled = true
		mode = "idle"
		isFrozen = false
		currentController = player
		createUI("AutoKill: ON\nTarget: " .. target.DisplayName)

	elseif cmd == ".stopautokill" then
		if not canUseLevel(player, 3) then createUI("No access!\nLevel 3+ required") return end
		local query = table.concat(args, " ", 2)
		if query ~= "" then
			local target = findPlayer(query)
			if target then
				autoKillTargets[target.Name] = nil
				local count = 0
				for _ in pairs(autoKillTargets) do count += 1 end
				if count == 0 then autoKillEnabled = false end
				createUI("AutoKill stopped:\n" .. target.DisplayName)
			end
		else
			autoKillTargets = {}
			autoKillEnabled = false
			createUI("AutoKill: Stopped")
		end

	-- LEVEL 4 / OWNER ONLY
	elseif cmd == ".reset" then
		if accessLevel ~= "owner" and accessLevel ~= 4 then createUI("No access!\nLevel 4/Owner only") return end
		OFFSET_RIGHT = DEFAULT.OFFSET_RIGHT
		OFFSET_UP = DEFAULT.OFFSET_UP
		OFFSET_BACK = DEFAULT.OFFSET_BACK
		FOLLOW_SPEED = DEFAULT.FOLLOW_SPEED
		mode = "idle"
		isFrozen = false
		isSpinning = false
		isFlinging = false
		isFlingingAll = false
		autoFlingEnabled = false
		autoKillEnabled = false
		autoKillTargets = {}
		currentController = host
		currentFlingTarget = nil
		oppList = {}
		whitelistedUsers = {}
		removePose()
		createUI("Stand: Reset to Defaults")
	end
end

-- Track first chat per player to show welcome message
local notifiedPlayers = {}
local function onPlayerChat(player, msg)
	local level = getAccessLevel(player)
	local priority = getLevelPriority(level)

	-- Show welcome message on first chat
	if not notifiedPlayers[player.Name] then
		notifiedPlayers[player.Name] = true
		if priority == 0 then
			createUI("Not whitelisted!\nJoin discord:\ndiscord.gg/DJuKxGVAck")
			return -- STOP HERE, don't process command
		elseif level == "owner" then
			createUI("Owner " .. getOwnerDisplay(player.Name) .. " connected!")
		else
			createUI("Level " .. tostring(level) .. " access detected!\n" .. player.Name)
		end
	end

	-- Block unauthorized players every single time
	if priority == 0 then
		createUI("Not whitelisted!\nJoin discord:\ndiscord.gg/DJuKxGVAck")
		return -- STOP HERE
	end

	handleCommand(player, msg)
end

-- Connect host
if host then
	host.Chatted:Connect(function(msg)
		onPlayerChat(host, msg)
	end)
end

-- Connect owners already in game
for _, owner in ipairs(ownersInGame) do
	owner.Chatted:Connect(function(msg)
		onPlayerChat(owner, msg)
	end)
end

-- Connect new players
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		onPlayerChat(player, msg)
	end)
	if isOwner(player.Name) then
		createUI("Owner joined: " .. getOwnerDisplay(player.Name))
	end
end)

-- Connect existing players
for _, player in ipairs(Players:GetPlayers()) do
	if player ~= host and player ~= stand then
		player.Chatted:Connect(function(msg)
			onPlayerChat(player, msg)
		end)
	end
end

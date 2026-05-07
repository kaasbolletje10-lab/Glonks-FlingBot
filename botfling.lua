local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local VERSION = "3.1.0"

local PANDA_PROJECT_KEY = "glonkflingbot"
local KEY_GET_URL = "https://pandadevelopment.net/getkey?service=pandadevelopment&projectkey=" .. PANDA_PROJECT_KEY
local KEY_CHECK_URL = "https://pandadevelopment.net/checkkey?service=pandadevelopment&projectkey=" .. PANDA_PROJECT_KEY .. "&key="
local KEY_SAVE_FILE = "glonkflingbot_key.txt"

local OWNER_LIST = {"flamingkid538", "krepahhh", "nick1_gus"}
local OWNER_DISPLAY = {
	["flamingkid538"] = "Glonk",
	["krepahhh"] = "xDa",
	["nick1_gus"] = "Nick",
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
local skillCooldowns = { ["1"] = 20, ["2"] = 15, ["3"] = 10, ["4"] = 20 }
local skillRanges = { ["1"] = 3, ["2"] = 3, ["3"] = 3, ["4"] = 3 }
local lastUsed = {}
local saidCD = {}
local autoKillTargets = {}
local autoKillEnabled = false
local stormEnabled = false

getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

local ownerModeEnabled = true
local keyVerified = false -- tracks if THIS alt's user has a valid key

local function getPlayerExact(username)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name == username then return plr end
	end
	return nil
end

local function isOwner(username)
	for _, name in ipairs(OWNER_LIST) do
		if name == username then return true end
	end
	return false
end

local function getOwnerDisplay(username)
	return OWNER_DISPLAY[username] or username
end

-- Save key to file so it persists
local function saveKey(key)
	pcall(function()
		writefile(KEY_SAVE_FILE, key)
	end)
end

-- Load saved key from file
local function loadSavedKey()
	local success, result = pcall(function()
		return readfile(KEY_SAVE_FILE)
	end)
	if success and result and result ~= "" then
		return result
	end
	return nil
end

-- Check key with Panda API
local function checkKeyWithPanda(key)
	local success, result = pcall(function()
		return game:HttpGet(KEY_CHECK_URL .. key)
	end)
	if success and result then
		-- Panda returns "true" or a JSON response
		if result == "true" then return true end
		local ok, data = pcall(function() return HttpService:JSONDecode(result) end)
		if ok and data and (data.success == true or data.valid == true) then
			return true
		end
	end
	return false
end

-- Try to auto-load and verify saved key on startup
local function tryAutoLoadKey()
	local savedKey = loadSavedKey()
	if savedKey then
		local valid = checkKeyWithPanda(savedKey)
		if valid then
			keyVerified = true
			return true
		end
	end
	return false
end

-- Check if a player is authorized to use commands
local function isAuthorized(player)
	if isOwner(player.Name) then return true end
	if player == getPlayerExact(HOST_USERNAME) then
		return keyVerified -- host needs key too unless owner
	end
	return false
end

local host = getPlayerExact(HOST_USERNAME)
local stand = Players.LocalPlayer

if not stand then
	warn("Executor couldn't detect LocalPlayer.")
	return
end

local ownersInGame = {}
for _, ownerName in ipairs(OWNER_LIST) do
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
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "Glonk's FlingBot v" .. VERSION
	title.TextColor3 = Color3.fromRGB(255, 80, 80)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 18
	local discordBtn = Instance.new("TextButton", frame)
	discordBtn.Size = UDim2.new(0, 260, 0, 35)
	discordBtn.Position = UDim2.new(0.5, -130, 0, 40)
	discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	discordBtn.BorderSizePixel = 0
	discordBtn.Text = "Click to copy Discord"
	discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	discordBtn.Font = Enum.Font.SourceSansBold
	discordBtn.TextSize = 16
	Instance.new("UICorner", discordBtn).CornerRadius = UDim.new(0, 6)
	discordBtn.MouseButton1Click:Connect(function()
		setclipboard("https://discord.gg/DJuKxGVAck")
		discordBtn.Text = "Copied!"
		discordBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
		task.wait(2)
		discordBtn.Text = "Click to copy Discord"
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
	local label = Instance.new("TextLabel", gui)
	label.Size = UDim2.new(0, 400, 0, 60)
	label.Position = UDim2.new(0.5, -200, 0.5, -30)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = text
	gui.Parent = playerGui
	task.delay(5, function()
		if gui then gui:Destroy() end
	end)
end

-- KEY ENTRY UI (shown when .enterkey is used)
local function showKeyEntryUI(player)
	local playerGui = stand:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("KeyEntryUI")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "KeyEntryUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local frame = Instance.new("Frame", gui)
	frame.Size = UDim2.new(0, 420, 0, 220)
	frame.Position = UDim2.new(0.5, -210, 0.5, -110)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BorderSizePixel = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1, 0, 0, 45)
	title.BackgroundTransparency = 1
	title.Text = "🔐 Glonk's FlingBot - Enter Key"
	title.TextColor3 = Color3.fromRGB(255, 80, 80)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 20

	local info = Instance.new("TextLabel", frame)
	info.Size = UDim2.new(1, -40, 0, 30)
	info.Position = UDim2.new(0, 20, 0, 48)
	info.BackgroundTransparency = 1
	info.Text = "Paste your key below. Use .getkey first to get the link."
	info.TextColor3 = Color3.fromRGB(180, 180, 180)
	info.Font = Enum.Font.SourceSans
	info.TextSize = 14
	info.TextWrapped = true

	local keyBox = Instance.new("TextBox", frame)
	keyBox.Size = UDim2.new(0, 360, 0, 40)
	keyBox.Position = UDim2.new(0.5, -180, 0, 90)
	keyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	keyBox.BorderSizePixel = 0
	keyBox.PlaceholderText = "Paste key here..."
	keyBox.Text = ""
	keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyBox.Font = Enum.Font.SourceSans
	keyBox.TextSize = 15
	keyBox.ClearTextOnFocus = false
	Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 8)

	local submitBtn = Instance.new("TextButton", frame)
	submitBtn.Size = UDim2.new(0, 170, 0, 40)
	submitBtn.Position = UDim2.new(0.5, -180, 0, 145)
	submitBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
	submitBtn.BorderSizePixel = 0
	submitBtn.Text = "✓ Submit Key"
	submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	submitBtn.Font = Enum.Font.SourceSansBold
	submitBtn.TextSize = 16
	Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 8)

	local closeBtn = Instance.new("TextButton", frame)
	closeBtn.Size = UDim2.new(0, 170, 0, 40)
	closeBtn.Position = UDim2.new(0.5, 10, 0, 145)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕ Cancel"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.SourceSansBold
	closeBtn.TextSize = 16
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	local statusLabel = Instance.new("TextLabel", frame)
	statusLabel.Size = UDim2.new(1, -20, 0, 25)
	statusLabel.Position = UDim2.new(0, 10, 0, 190)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusLabel.Font = Enum.Font.SourceSans
	statusLabel.TextSize = 14

	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	submitBtn.MouseButton1Click:Connect(function()
		local key = keyBox.Text:gsub("%s+", "")
		if key == "" then
			statusLabel.Text = "❌ Please paste a key first!"
			statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			return
		end

		submitBtn.Text = "Checking..."
		submitBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 0)
		statusLabel.Text = "Verifying with Panda..."
		statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

		local valid = checkKeyWithPanda(key)

		if valid then
			keyVerified = true
			saveKey(key)
			submitBtn.Text = "✓ Accepted!"
			submitBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
			statusLabel.Text = "✓ Key valid! You can now use all commands."
			statusLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
			task.wait(1.5)
			gui:Destroy()
			createUI("Key Verified!\nAll commands unlocked!")
		else
			submitBtn.Text = "✓ Submit Key"
			submitBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
			statusLabel.Text = "❌ Invalid key! Use .getkey to get one."
			statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		end
	end)

	gui.Parent = playerGui
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

-- Try to auto-load key on startup
local autoLoaded = tryAutoLoadKey()

if host then
	createUI("Glonk's FlingBot v" .. VERSION .. "\nHost: " .. host.Name)
	createWatermark()
	task.delay(2, function()
		sendChatMessage("Glonk's FlingBot - v" .. VERSION)
		if autoLoaded then
			createUI("Key auto-loaded!\nAll commands ready.")
		elseif not isOwner(stand.Name) then
			createUI("No key found!\nSay .getkey then .enterkey")
		end
	end)
else
	createUI("No Host Found")
	return
end

print("Host:", host.Name)
print("Stand:", stand.Name)
print("Key verified:", keyVerified)

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
local stormController = nil
local stormAngle = 0

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

local function doClick()
	VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
	task.wait(0.05)
	VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
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
		local ls = torso:FindFirstChild("Left Shoulder")
		local rs = torso:FindFirstChild("Right Shoulder")
		local lh = torso:FindFirstChild("Left Hip")
		local rh = torso:FindFirstChild("Right Hip")
		if ls then ls.C0 = CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, math.rad(-90), math.rad(-70)) end
		if rs then rs.C0 = CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.rad(90), math.rad(70)) end
		if lh then lh.C0 = CFrame.new(-1, -1, 0) * CFrame.Angles(0, math.rad(-90), math.rad(-20)) end
		if rh then rh.C0 = CFrame.new(1, -1, 0) * CFrame.Angles(0, math.rad(90), math.rad(20)) end
	else
		local torso = stand.Character:FindFirstChild("UpperTorso")
		if not torso then return end
		local ls = torso:FindFirstChild("LeftShoulder")
		local rs = torso:FindFirstChild("RightShoulder")
		local lowerTorso = stand.Character:FindFirstChild("LowerTorso")
		local lh = lowerTorso and lowerTorso:FindFirstChild("LeftHip")
		local rh = lowerTorso and lowerTorso:FindFirstChild("RightHip")
		if ls then ls.C0 = CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, math.rad(-90), math.rad(-70)) end
		if rs then rs.C0 = CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.rad(90), math.rad(70)) end
		if lh then lh.C0 = CFrame.new(-1, -1, 0) * CFrame.Angles(0, math.rad(-90), math.rad(-20)) end
		if rh then rh.C0 = CFrame.new(1, -1, 0) * CFrame.Angles(0, math.rad(90), math.rad(20)) end
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
		local ls = torso:FindFirstChild("Left Shoulder")
		local rs = torso:FindFirstChild("Right Shoulder")
		local lh = torso:FindFirstChild("Left Hip")
		local rh = torso:FindFirstChild("Right Hip")
		if ls then ls.C0 = CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0) end
		if rs then rs.C0 = CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.rad(90), 0) end
		if lh then lh.C0 = CFrame.new(-1, -1, 0) * CFrame.Angles(0, math.rad(-90), 0) end
		if rh then rh.C0 = CFrame.new(1, -1, 0) * CFrame.Angles(0, math.rad(90), 0) end
	else
		local torso = stand.Character:FindFirstChild("UpperTorso")
		if torso then
			local ls = torso:FindFirstChild("LeftShoulder")
			local rs = torso:FindFirstChild("RightShoulder")
			if ls then ls.C0 = CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, math.rad(-90), 0) end
			if rs then rs.C0 = CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.rad(90), 0) end
		end
		local lt = stand.Character:FindFirstChild("LowerTorso")
		if lt then
			local lh = lt:FindFirstChild("LeftHip")
			local rh = lt:FindFirstChild("RightHip")
			if lh then lh.C0 = CFrame.new(-1, -1, 0) * CFrame.Angles(0, math.rad(-90), 0) end
			if rh then rh.C0 = CFrame.new(1, -1, 0) * CFrame.Angles(0, math.rad(90), 0) end
		end
	end
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
					Angle += 100
					FPos(BasePart, CFrame.new(0,1.5,0)+THumanoid.MoveDirection*BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
					FPos(BasePart, CFrame.new(0,-1.5,0)+THumanoid.MoveDirection*BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
					FPos(BasePart, CFrame.new(0,1.5,0)+THumanoid.MoveDirection*BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
					FPos(BasePart, CFrame.new(0,-1.5,0)+THumanoid.MoveDirection*BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
					FPos(BasePart, CFrame.new(0,1.5,0)+THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
					FPos(BasePart, CFrame.new(0,-1.5,0)+THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0,0)) task.wait()
				else
					FPos(BasePart, CFrame.new(0,1.5,THumanoid.WalkSpeed), CFrame.Angles(math.rad(90),0,0)) task.wait()
					FPos(BasePart, CFrame.new(0,-1.5,-THumanoid.WalkSpeed), CFrame.Angles(0,0,0)) task.wait()
					FPos(BasePart, CFrame.new(0,1.5,THumanoid.WalkSpeed), CFrame.Angles(math.rad(90),0,0)) task.wait()
					FPos(BasePart, CFrame.new(0,-1.5,0), CFrame.Angles(math.rad(90),0,0)) task.wait()
					FPos(BasePart, CFrame.new(0,-1.5,0), CFrame.Angles(0,0,0)) task.wait()
					FPos(BasePart, CFrame.new(0,-1.5,0), CFrame.Angles(math.rad(90),0,0)) task.wait()
					FPos(BasePart, CFrame.new(0,-1.5,0), CFrame.Angles(0,0,0)) task.wait()
				end
			end
		until Time + TimeToWait < tick() or not isFlinging
	end
	workspace.FallenPartsDestroyHeight = 0/0
	local BV = Instance.new("BodyVelocity", RootPart)
	BV.Velocity = Vector3.zero
	BV.MaxForce = Vector3.new(9e9,9e9,9e9)
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
			RootPart.CFrame = getgenv().OldPos * CFrame.new(0,0.5,0)
			Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0,0.5,0))
			Humanoid:ChangeState("GettingUp")
			for _, part in pairs(Character:GetChildren()) do
				if part:IsA("BasePart") then
					part.Velocity = Vector3.zero
					part.RotVelocity = Vector3.zero
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

-- AUTOKILL LOOP
task.spawn(function()
	while task.wait(0.3) do
		if autoKillEnabled then
			for targetName, _ in pairs(autoKillTargets) do
				local target = Players:FindFirstChild(targetName)
				if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
					doClick() task.wait(0.1)
					doClick() task.wait(0.1)
					pressKey(Enum.KeyCode.One) task.wait(0.15)
					pressKey(Enum.KeyCode.Two) task.wait(0.15)
					pressKey(Enum.KeyCode.Three) task.wait(0.15)
					pressKey(Enum.KeyCode.Four) task.wait(0.15)
					doClick() task.wait(0.1)
					doClick()
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

-- MAIN HEARTBEAT
RunService.Heartbeat:Connect(function(dt)
	if not stand.Character then return end
	local standHRP = stand.Character:FindFirstChild("HumanoidRootPart")
	if not standHRP then return end
	if isFlinging or isFlingingAll then return end

	if autoKillEnabled then
		for targetName, _ in pairs(autoKillTargets) do
			local target = Players:FindFirstChild(targetName)
			if target and target.Character then
				local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
				if targetHRP then
					local vel = targetHRP.AssemblyLinearVelocity
					local predicted = targetHRP.CFrame * CFrame.new(vel.X*0.16, vel.Y*0.16, vel.Z*0.16)
					standHRP.CFrame = standHRP.CFrame:Lerp(predicted, 0.8)
					standHRP.AssemblyLinearVelocity = Vector3.zero
					standHRP.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
		return
	end

	if stormEnabled and stormController and stormController.Character then
		local controllerHRP = stormController.Character:FindFirstChild("HumanoidRootPart")
		if controllerHRP then
			stormAngle += 15 * dt * 60
			local chaosRadius = 10 + math.sin(stormAngle * 2.7) * 3
			local cx = math.cos(stormAngle) * chaosRadius
			local cz = math.sin(stormAngle * 1.3) * chaosRadius
			local targetPos = controllerHRP.Position + Vector3.new(cx, 3 + math.sin(stormAngle*0.3)*5, cz)
			standHRP.CFrame = CFrame.new(targetPos)
			standHRP.AssemblyLinearVelocity = Vector3.zero
			standHRP.AssemblyAngularVelocity = Vector3.zero
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
		local targetCF = controllerHRP.CFrame * CFrame.new(OFFSET_RIGHT, OFFSET_UP+floatY, OFFSET_BACK)
		targetCF = CFrame.new(targetCF.Position, targetCF.Position + controllerHRP.CFrame.LookVector)
		standHRP.CFrame = standHRP.CFrame:Lerp(targetCF, FOLLOW_SPEED)
		if isSpinning then standHRP.CFrame = standHRP.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0) end
	elseif mode == "orbit" then
		orbitAngle += ORBIT_SPEED * dt
		local floatY = math.sin(floatOffset) * 0.5
		local pos = controllerHRP.Position + Vector3.new(math.cos(orbitAngle)*orbitRadius, ORBIT_HEIGHT+floatY, math.sin(orbitAngle)*orbitRadius)
		standHRP.CFrame = standHRP.CFrame:Lerp(CFrame.new(pos, pos+controllerHRP.CFrame.LookVector), FOLLOW_SPEED)
		if isSpinning then standHRP.CFrame = standHRP.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0) end
	elseif mode == "above" then
		local pos = controllerHRP.Position + Vector3.new(0, 8+math.sin(floatOffset)*0.5, 0)
		standHRP.CFrame = standHRP.CFrame:Lerp(CFrame.new(pos, pos+controllerHRP.CFrame.LookVector), FOLLOW_SPEED)
		if isSpinning then standHRP.CFrame = standHRP.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0) end
	elseif mode == "behind" then
		standHRP.CFrame = controllerHRP.CFrame * CFrame.new(0, math.sin(floatOffset)*0.5, OFFSET_BACK)
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

	-- Owner toggle commands — always work
	if cmd == ".owneron" then
		if not isOwner(player.Name) then createUI("Owner only!") return end
		ownerModeEnabled = true
		createUI("Owner Mode: ON")
		return
	end
	if cmd == ".owneroff" then
		if not isOwner(player.Name) then createUI("Owner only!") return end
		ownerModeEnabled = false
		createUI("Owner Mode: OFF")
		return
	end

	-- Key commands — always available so people can get access
	if cmd == ".getkey" then
		setclipboard(KEY_GET_URL)
		createUI("Key link copied!\nGo get your key then say .enterkey")
		return
	end

	if cmd == ".enterkey" then
		showKeyEntryUI(player)
		return
	end

	-- Check authorization
	local ownerAccess = isOwner(player.Name)
	local hasKey = keyVerified

	if not ownerAccess and not hasKey then
		createUI("No key!\nSay .getkey then .enterkey")
		return
	end

	-- If ownerMode is off only owners can use commands
	if not ownerModeEnabled and not ownerAccess then
		createUI("Bot locked by owner!")
		return
	end

	print("[CMD " .. player.Name .. (ownerAccess and " (Owner)" or " (Key)") .. "]:", msg)

	-- SKILL COMMANDS
	if cmd == ".1" or cmd == ".2" or cmd == ".3" or cmd == ".4" then
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

	if cmd == ".summon" then
		currentController = player
		mode = "follow"
		isFrozen = false
		isFlinging = false
		stormEnabled = false
		autoKillEnabled = false
		autoKillTargets = {}
		applyPose()
		createUI("Mode: Follow\nController: " .. player.Name)

	elseif cmd == ".storm" then
		stormEnabled = true
		stormController = player
		mode = "idle"
		isFrozen = false
		isFlinging = false
		autoKillEnabled = false
		autoKillTargets = {}
		stormAngle = 0
		createUI("Storm Mode: ON\nAround: " .. player.Name)

	elseif cmd == ".nostorm" then
		stormEnabled = false
		stormController = nil
		createUI("Storm Mode: OFF")

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
		stormEnabled = false
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
		sendChatMessage("Glonk's FlingBot - v" .. VERSION)
		createUI("v" .. VERSION)

	elseif cmd == ".stop" then
		mode = "idle"
		isFrozen = false
		isFlinging = false
		isFlingingAll = false
		isSpinning = false
		stormEnabled = false
		stormController = nil
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
		stormEnabled = false
		stormController = nil
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
		stormEnabled = false
		stormController = nil
		autoKillEnabled = false
		autoKillTargets = {}
		currentFlingTarget = nil
		removePose()
		createUI("Mode: Idle")

	elseif cmd == ".freeze" then
		mode = "idle"
		stormEnabled = false
		isFrozen = true
		createUI("Stand: Frozen")

	elseif cmd == ".behind" then
		currentController = player
		mode = "behind"
		isFrozen = false
		isFlinging = false
		stormEnabled = false
		autoKillEnabled = false
		autoKillTargets = {}
		applyPose()
		createUI("Mode: Behind\nController: " .. player.Name)

	elseif cmd == ".above" then
		currentController = player
		mode = "above"
		isFrozen = false
		isFlinging = false
		stormEnabled = false
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
		local statusMsg = "Mode: " .. mode
		statusMsg = statusMsg .. "\nAccess: " .. (ownerAccess and "Owner" or "Key")
		if currentController then statusMsg = statusMsg .. "\nController: " .. currentController.Name end
		if isFrozen then statusMsg = statusMsg .. "\nFrozen: Yes" end
		if isSpinning then statusMsg = statusMsg .. "\nSpinning: " .. spinSpeed end
		if stormEnabled then statusMsg = statusMsg .. "\nStorm: ON" end
		if isFlinging then
			statusMsg = statusMsg .. "\nFlinging: Active"
			if currentFlingTarget then statusMsg = statusMsg .. " (" .. currentFlingTarget.DisplayName .. ")" end
		end
		if isFlingingAll then statusMsg = statusMsg .. "\nFling All: Active" end
		if autoFlingEnabled then statusMsg = statusMsg .. "\nAuto-Fling: ON" end
		if autoKillEnabled then
			statusMsg = statusMsg .. "\nAuto-Kill: ON"
			for n, _ in pairs(autoKillTargets) do statusMsg = statusMsg .. " (" .. n .. ")" end
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
		sendChatMessage("I am using Glonk's FlingBot v" .. VERSION)
		createUI("Script message sent!")

	elseif cmd == ".cmd" then
		sendChatMessage(".getkey .enterkey .summon .tp .orbit .storm .nostorm .fling .stopfling .opp .unopp .autokill .stopautokill .1 .2 .3 .4 .spin .nospin .stop .void .idle .freeze .behind .above .speed .status .offset .tpwall1 .tpwall2 .rj .re .script .ver")
		createUI("Commands sent to chat!")

	elseif cmd == ".fling" then
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
						if plr ~= stand and not isOwner(plr.Name) then
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
							task.wait(0.5)
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
		if not target then createUI("Fling: Not found\n\"" .. query .. "\"") return end
		if not target.Character then createUI("Fling: No character") return end

		if isOwner(target.Name) and not ownerAccess then
			local ownerDisplayName = getOwnerDisplay(target.Name)
			sendChatMessage(player.DisplayName .. " tried to fling " .. ownerDisplayName .. ". Nice try.")
			modeBeforeFling = mode
			mode = "idle"
			isFrozen = false
			createUI("Protected owner!\nFlinging: " .. player.DisplayName)
			task.spawn(runFling, player, 5)
			return
		end

		if target == host and not ownerAccess then
			sendChatMessage(player.DisplayName .. " tried to betray the host!")
			modeBeforeFling = mode
			mode = "idle"
			isFrozen = false
			createUI("BETRAYAL!\nFlinging: " .. player.DisplayName)
			task.spawn(runFling, player, 5)
			return
		end

		modeBeforeFling = mode
		mode = "idle"
		isFrozen = false
		createUI("Flinging: " .. target.DisplayName .. "\n5 seconds...")
		task.spawn(runFling, target, 5)

	elseif cmd == ".stopfling" then
		isFlinging = false
		isFlingingAll = false
		currentFlingTarget = nil
		createUI("Fling: Stopped")

	elseif cmd == ".opp" then
		local query = table.concat(args, " ", 2)
		if query == "" then createUI("Usage: .opp <username>") return end
		local target = findPlayer(query)
		if not target then createUI("Opp: Not found") return end
		if isOwner(target.Name) then createUI("Cannot opp an owner!") return end
		if target == host then createUI("Cannot opp the host!") return end
		oppList[target.Name] = true
		autoFlingEnabled = true
		createUI("Added to Opp List:\n" .. target.DisplayName)

	elseif cmd == ".unopp" then
		local query = table.concat(args, " ", 2)
		if query == "" then createUI("Usage: .unopp <username>") return end
		local target = findPlayer(query)
		if not target then createUI("Unopp: Not found") return end
		oppList[target.Name] = nil
		local oppCount = 0
		for _ in pairs(oppList) do oppCount += 1 end
		if oppCount == 0 then autoFlingEnabled = false end
		createUI("Removed from Opp:\n" .. target.DisplayName)

	elseif cmd == ".tpwall1" then
		if not stand.Character or not player.Character then return end
		local standHRP = stand.Character:FindFirstChild("HumanoidRootPart")
		local playerHRP = player.Character:FindFirstChild("HumanoidRootPart")
		if not standHRP or not playerHRP then return end
		createUI("Wall move 1 incoming!")
		task.spawn(function()
			local prevMode = mode
			mode = "idle"
			isFrozen = true
			stormEnabled = false
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
		if not stand.Character or not player.Character then return end
		local standHRP = stand.Character:FindFirstChild("HumanoidRootPart")
		local playerHRP = player.Character:FindFirstChild("HumanoidRootPart")
		if not standHRP or not playerHRP then return end
		createUI("Wall move 2 incoming!")
		task.spawn(function()
			local prevMode = mode
			mode = "idle"
			isFrozen = true
			stormEnabled = false
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

	elseif cmd == ".autokill" then
		local query = table.concat(args, " ", 2)
		if query == "" then createUI("Usage: .autokill <username>") return end
		local target = findPlayer(query)
		if not target then createUI("AutoKill: Not found") return end
		if isOwner(target.Name) then createUI("Cannot autokill an owner!") return end
		if target == host and not ownerAccess then createUI("Cannot autokill the host!") return end
		autoKillTargets[target.Name] = true
		autoKillEnabled = true
		stormEnabled = false
		mode = "idle"
		isFrozen = false
		createUI("AutoKill: ON\nTarget: " .. target.DisplayName)

	elseif cmd == ".stopautokill" then
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

	elseif cmd == ".reset" then
		if not ownerAccess then createUI("Owner only!") return end
		OFFSET_RIGHT = DEFAULT.OFFSET_RIGHT
		OFFSET_UP = DEFAULT.OFFSET_UP
		OFFSET_BACK = DEFAULT.OFFSET_BACK
		FOLLOW_SPEED = DEFAULT.FOLLOW_SPEED
		mode = "idle"
		isFrozen = false
		isSpinning = false
		isFlinging = false
		isFlingingAll = false
		stormEnabled = false
		stormController = nil
		autoFlingEnabled = false
		autoKillEnabled = false
		autoKillTargets = {}
		currentController = host
		currentFlingTarget = nil
		oppList = {}
		removePose()
		createUI("Stand: Reset to Defaults")
	end
end

local function onPlayerChat(player, msg)
	handleCommand(player, msg)
end

if host then
	host.Chatted:Connect(function(msg) onPlayerChat(host, msg) end)
end

for _, owner in ipairs(ownersInGame) do
	owner.Chatted:Connect(function(msg) onPlayerChat(owner, msg) end)
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg) onPlayerChat(player, msg) end)
	if isOwner(player.Name) then
		createUI("Owner joined: " .. getOwnerDisplay(player.Name))
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= host and player ~= stand then
		player.Chatted:Connect(function(msg) onPlayerChat(player, msg) end)
	end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")

local VERSION = "3.0.1"

-- PANDA DEVELOPMENT KEY SYSTEM
local KeySystemURL = "https://pandadevelopment.net/getkey?service=glonkflingbot&hwid="
local KeyCheckURL = "https://pandadevelopment.net/checkkey?service=glonkflingbot&key="

--[[
	ACCESS SYSTEM:
	Premium: All commands (3 hour key from Panda Development)
	Owner:   Full access + .owneron .owneroff (no key needed)
]]

local OWNER_LIST = {"flamingkid538", "krepahhh", "nick1_gus"}
local OWNER_DISPLAY = {
	["flamingkid538"] = "Glonk",
	["krepahhh"] = "xDa",
	["nick1_gus"] = "Nick",
}

-- Key storage: validKeys[username] = expiry_time
local validKeys = {}

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
local stormEnabled = false

getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

local ownerModeEnabled = true

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

local function getHWID()
	return game:GetService("RbxAnalyticsService"):GetClientId()
end

-- Check if key is valid and not expired
local function isKeyValid(username)
	if isOwner(username) then return true end
	local expiry = validKeys[username]
	if expiry and os.time() < expiry then
		return true
	end
	return false
end

-- Create Key System UI
local function createKeySystemUI(player)
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Remove existing UI
	local existing = playerGui:FindFirstChild("KeySystemUI")
	if existing then existing:Destroy() end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "KeySystemUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "🔐 Glonk's FlingBot - Key System"
	title.TextColor3 = Color3.fromRGB(255, 80, 80)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 22
	title.Parent = mainFrame
	
	-- Info Text
	local infoText = Instance.new("TextLabel")
	infoText.Size = UDim2.new(1, -40, 0, 60)
	infoText.Position = UDim2.new(0, 20, 0, 60)
	infoText.BackgroundTransparency = 1
	infoText.Text = "Get a 3-hour key to use all premium commands!\nClick 'Get Key' to copy the link."
	infoText.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoText.Font = Enum.Font.SourceSans
	infoText.TextSize = 16
	infoText.TextWrapped = true
	infoText.TextYAlignment = Enum.TextYAlignment.Top
	infoText.Parent = mainFrame
	
	-- Get Key Button
	local getKeyBtn = Instance.new("TextButton")
	getKeyBtn.Size = UDim2.new(0, 320, 0, 40)
	getKeyBtn.Position = UDim2.new(0.5, -160, 0, 130)
	getKeyBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	getKeyBtn.BorderSizePixel = 0
	getKeyBtn.Text = "📋 Copy Key Link"
	getKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	getKeyBtn.Font = Enum.Font.SourceSansBold
	getKeyBtn.TextSize = 18
	getKeyBtn.Parent = mainFrame
	
	local btnCorner1 = Instance.new("UICorner")
	btnCorner1.CornerRadius = UDim.new(0, 8)
	btnCorner1.Parent = getKeyBtn
	
	-- Key Input Box
	local keyInput = Instance.new("TextBox")
	keyInput.Size = UDim2.new(0, 320, 0, 40)
	keyInput.Position = UDim2.new(0.5, -160, 0, 180)
	keyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	keyInput.BorderSizePixel = 0
	keyInput.PlaceholderText = "Enter your key here..."
	keyInput.Text = ""
	keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyInput.Font = Enum.Font.SourceSans
	keyInput.TextSize = 16
	keyInput.ClearTextOnFocus = false
	keyInput.Parent = mainFrame
	
	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 8)
	inputCorner.Parent = keyInput
	
	-- Submit Button
	local submitBtn = Instance.new("TextButton")
	submitBtn.Size = UDim2.new(0, 320, 0, 40)
	submitBtn.Position = UDim2.new(0.5, -160, 0, 230)
	submitBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
	submitBtn.BorderSizePixel = 0
	submitBtn.Text = "✓ Submit Key"
	submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	submitBtn.Font = Enum.Font.SourceSansBold
	submitBtn.TextSize = 18
	submitBtn.Parent = mainFrame
	
	local btnCorner2 = Instance.new("UICorner")
	btnCorner2.CornerRadius = UDim.new(0, 8)
	btnCorner2.Parent = submitBtn
	
	-- Get Key Button Functionality
	getKeyBtn.MouseButton1Click:Connect(function()
		local hwid = getHWID()
		local keyLink = KeySystemURL .. hwid
		setclipboard(keyLink)
		getKeyBtn.Text = "✓ Link Copied!"
		getKeyBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
		task.wait(2)
		getKeyBtn.Text = "📋 Copy Key Link"
		getKeyBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	end)
	
	-- Submit Key Functionality
	submitBtn.MouseButton1Click:Connect(function()
		local inputKey = keyInput.Text
		if inputKey == "" then
			submitBtn.Text = "❌ Enter a key first!"
			submitBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			task.wait(2)
			submitBtn.Text = "✓ Submit Key"
			submitBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
			return
		end
		
		-- Verify key with Panda Development
		submitBtn.Text = "Checking..."
		submitBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 0)
		
		local success, result = pcall(function()
			return game:HttpGet(KeyCheckURL .. inputKey)
		end)
		
		if success and result == "true" then
			-- Key is valid - grant 3 hour access
			validKeys[player.Name] = os.time() + (3 * 60 * 60) -- 3 hours
			submitBtn.Text = "✓ Key Accepted!"
			submitBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
			task.wait(1)
			screenGui:Destroy()
			
			-- Show success message
			local playerGui2 = player:WaitForChild("PlayerGui")
			local successGui = Instance.new("ScreenGui")
			successGui.Name = "SuccessUI"
			successGui.ResetOnSpawn = false
			local successLabel = Instance.new("TextLabel")
			successLabel.Size = UDim2.new(0, 400, 0, 60)
			successLabel.Position = UDim2.new(0.5, -200, 0.5, -30)
			successLabel.BackgroundTransparency = 0.3
			successLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			successLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
			successLabel.TextScaled = true
			successLabel.Font = Enum.Font.SourceSansBold
			successLabel.Text = "Premium Access Granted!\n3 Hours Remaining"
			successLabel.Parent = successGui
			successGui.Parent = playerGui2
			task.delay(5, function()
				if successGui then successGui:Destroy() end
			end)
		else
			-- Invalid key
			submitBtn.Text = "❌ Invalid Key!"
			submitBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			task.wait(2)
			submitBtn.Text = "✓ Submit Key"
			submitBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
		end
	end)
	
	screenGui.Parent = playerGui
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
	createUI("Glonk's FlingBot - v" .. VERSION .. "\nHost: " .. host.Name)
	createWatermark()
	task.delay(2, function()
		sendChatMessage("Glonk's FlingBot - v" .. VERSION)
	end)
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

-- AUTOKILL LOOP
task.spawn(function()
	while task.wait(0.3) do
		if autoKillEnabled then
			for targetName, _ in pairs(autoKillTargets) do
				local target = Players:FindFirstChild(targetName)
				if target and target.Character then
					local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
					if targetHRP then
						doClick()
						task.wait(0.1)
						doClick()
						task.wait(0.1)
						pressKey(Enum.KeyCode.One)
						task.wait(0.15)
						pressKey(Enum.KeyCode.Two)
						task.wait(0.15)
						pressKey(Enum.KeyCode.Three)
						task.wait(0.15)
						pressKey(Enum.KeyCode.Four)
						task.wait(0.15)
						doClick()
						task.wait(0.1)
						doClick()
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

-- MAIN HEARTBEAT LOOP
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
					local predicted = targetHRP.CFrame * CFrame.new(vel.X * 0.16, vel.Y * 0.16, vel.Z * 0.16)
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
			local radius = 10
			local heightVariation = math.sin(stormAngle * 0.3) * 5
			local chaosRadius = radius + math.sin(stormAngle * 2.7) * 3
			local cx = math.cos(stormAngle) * chaosRadius
			local cz = math.sin(stormAngle * 1.3) * chaosRadius
			local targetPos = controllerHRP.Position + Vector3.new(cx, 3 + heightVariation, cz)
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

	-- Owner commands bypass key system
	if cmd == ".owneron" then
		if not isOwner(player.Name) then createUI("Permission: Owner only") return end
		ownerModeEnabled = true
		createUI("Owner Mode: ON\nHost can use bot")
		return
	end
	if cmd == ".owneroff" then
		if not isOwner(player.Name) then createUI("Permission: Owner only") return end
		ownerModeEnabled = false
		createUI("Owner Mode: OFF\nOnly owners can use bot")
		return
	end

	-- Check if user has valid key or is owner
	if not isKeyValid(player.Name) then
		createUI("No valid key!\nUse .getkey to start")
		return
	end

	print("[CMD " .. player.Name .. "]:", msg)

	-- .getkey command - show key system UI
	if cmd == ".getkey" then
		createKeySystemUI(player)
		return
	end

	-- ALL COMMANDS (Premium/Owner)
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
		sendChatMessage("Glonk's FlingBot - v" .. VERSION .. " (Key System)")
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
		local timeLeft = validKeys[player.Name]
		if timeLeft then
			local remaining = math.floor((timeLeft - os.time()) / 60)
			statusMsg = statusMsg .. "\nKey: " .. remaining .. " mins left"
		end
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
		sendChatMessage("I am using Glonk's FlingBot v" .. VERSION)
		createUI("Script message sent!")

	elseif cmd == ".cmd" then
		local cmdList = ".summon .tp .orbit .storm .fling .opp .autokill .1 .2 .3 .4 | Use .getkey for access"
		sendChatMessage(cmdList)
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
						if plr ~= stand and not isOwner(plr.Name) and not isKeyValid(plr.Name) then
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
		if not target then createUI("Fling: Player not found\n\"" .. query .. "\"") return end
		if not target.Character then createUI("Fling: " .. target.DisplayName .. " has no character") return end

		if isOwner(target.Name) then
			local ownerDisplayName = getOwnerDisplay(target.Name)
			sendChatMessage(player.DisplayName .. " tried to fling " .. ownerDisplayName .. ". Nice try.")
			modeBeforeFling = mode
			mode = "idle"
			isFrozen = false
			createUI("Protected owner!\nFlinging: " .. player.DisplayName)
			task.spawn(runFling, player, 5)
			return
		end

		if target == host and not isOwner(player.Name) then
			sendChatMessage(player.DisplayName .. " tried to betray the host!")
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
		isFlinging = false
		isFlingingAll = false
		currentFlingTarget = nil
		createUI("Fling: Stopped")

	elseif cmd == ".opp" then
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
		local query = table.concat(args, " ", 2)
		if query == "" then createUI("Usage: .unopp <username>") return end
		local target = findPlayer(query)
		if not target then createUI("Unopp: Not found\n\"" .. query .. "\"") return end
		oppList[target.Name] = nil
		local oppCount = 0
		for _ in pairs(oppList) do oppCount += 1 end
		if oppCount == 0 then autoFlingEnabled = false end
		createUI("Removed from Opp List:\n" .. target.DisplayName)

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
		if not target then createUI("AutoKill: Not found\n\"" .. query .. "\"") return end
		if isOwner(target.Name) then createUI("Cannot autokill an owner!") return end
		if target == host and not isOwner(player.Name) then createUI("Cannot autokill the host!") return end
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
		if not isOwner(player.Name) then createUI("Permission: Owner only") return end
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

-- PLAYER CHAT HANDLER
local function onPlayerChat(player, msg)
	handleCommand(player, msg)
end

if host then
	host.Chatted:Connect(function(msg)
		onPlayerChat(host, msg)
	end)
end

for _, owner in ipairs(ownersInGame) do
	owner.Chatted:Connect(function(msg)
		onPlayerChat(owner, msg)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		onPlayerChat(player, msg)
	end)
	if isOwner(player.Name) then
		createUI("Owner joined: " .. getOwnerDisplay(player.Name))
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= host and player ~= stand then
		player.Chatted:Connect(function(msg)
			onPlayerChat(player, msg)
		end)
	end
end"
local KeyCheckURL = "https://pandadevelopment.net/checkkey?service=glonkflingbot&key="

--[[
	ACCESS SYSTEM:
	Premium: All commands (3 hour key from Panda Development)
	Owner:   Full access + .owneron .owneroff (no key needed)
]]

local OWNER_LIST = {"flamingkid538", "krepahhh", "nick1_gus"}
local OWNER_DISPLAY = {
	["flamingkid538"] = "Glonk",
	["krepahhh"] = "xDa",
	["nick1_gus"] = "Nick",
}

-- Key storage: validKeys[username] = expiry_time
local validKeys = {}

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
local stormEnabled = false

getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

local ownerModeEnabled = true

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

local function getHWID()
	return game:GetService("RbxAnalyticsService"):GetClientId()
end

-- Check if key is valid and not expired
local function isKeyValid(username)
	if isOwner(username) then return true end
	local expiry = validKeys[username]
	if expiry and os.time() < expiry then
		return true
	end
	return false
end

-- Create Key System UI
local function createKeySystemUI(player)
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Remove existing UI
	local existing = playerGui:FindFirstChild("KeySystemUI")
	if existing then existing:Destroy() end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "KeySystemUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "🔐 Glonk's FlingBot - Key System"
	title.TextColor3 = Color3.fromRGB(255, 80, 80)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 22
	title.Parent = mainFrame
	
	-- Info Text
	local infoText = Instance.new("TextLabel")
	infoText.Size = UDim2.new(1, -40, 0, 60)
	infoText.Position = UDim2.new(0, 20, 0, 60)
	infoText.BackgroundTransparency = 1
	infoText.Text = "Get a 3-hour key to use all premium commands!\nClick 'Get Key' to copy the link."
	infoText.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoText.Font = Enum.Font.SourceSans
	infoText.TextSize = 16
	infoText.TextWrapped = true
	infoText.TextYAlignment = Enum.TextYAlignment.Top
	infoText.Parent = mainFrame
	
	-- Get Key Button
	local getKeyBtn = Instance.new("TextButton")
	getKeyBtn.Size = UDim2.new(0, 320, 0, 40)
	getKeyBtn.Position = UDim2.new(0.5, -160, 0, 130)
	getKeyBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	getKeyBtn.BorderSizePixel = 0
	getKeyBtn.Text = "📋 Copy Key Link"
	getKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	getKeyBtn.Font = Enum.Font.SourceSansBold
	getKeyBtn.TextSize = 18
	getKeyBtn.Parent = mainFrame
	
	local btnCorner1 = Instance.new("UICorner")
	btnCorner1.CornerRadius = UDim.new(0, 8)
	btnCorner1.Parent = getKeyBtn
	
	-- Key Input Box
	local keyInput = Instance.new("TextBox")
	keyInput.Size = UDim2.new(0, 320, 0, 40)
	keyInput.Position = UDim2.new(0.5, -160, 0, 180)
	keyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	keyInput.BorderSizePixel = 0
	keyInput.PlaceholderText = "Enter your key here..."
	keyInput.Text = ""
	keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyInput.Font = Enum.Font.SourceSans
	keyInput.TextSize = 16
	keyInput.ClearTextOnFocus = false
	keyInput.Parent = mainFrame
	
	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 8)
	inputCorner.Parent = keyInput
	
	-- Submit Button
	local submitBtn = Instance.new("TextButton")
	submitBtn.Size = UDim2.new(0, 320, 0, 40)
	submitBtn.Position = UDim2.new(0.5, -160, 0, 230)
	submitBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
	submitBtn.BorderSizePixel = 0
	submitBtn.Text = "✓ Submit Key"
	submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	submitBtn.Font = Enum.Font.SourceSansBold
	submitBtn.TextSize = 18
	submitBtn.Parent = mainFrame
	
	local btnCorner2 = Instance.new("UICorner")
	btnCorner2.CornerRadius = UDim.new(0, 8)
	btnCorner2.Parent = submitBtn
	
	-- Get Key Button Functionality
	getKeyBtn.MouseButton1Click:Connect(function()
		local hwid = getHWID()
		local keyLink = KeySystemURL .. hwid
		setclipboard(keyLink)
		getKeyBtn.Text = "✓ Link Copied!"
		getKeyBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
		task.wait(2)
		getKeyBtn.Text = "📋 Copy Key Link"
		getKeyBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	end)
	
	-- Submit Key Functionality
	submitBtn.MouseButton1Click:Connect(function()
		local inputKey = keyInput.Text
		if inputKey == "" then
			submitBtn.Text = "❌ Enter a key first!"
			submitBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			task.wait(2)
			submitBtn.Text = "✓ Submit Key"
			submitBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
			return
		end
		
		-- Verify key with Panda Development
		submitBtn.Text = "Checking..."
		submitBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 0)
		
		local success, result = pcall(function()
			return game:HttpGet(KeyCheckURL .. inputKey)
		end)
		
		if success and result == "true" then
			-- Key is valid - grant 3 hour access
			validKeys[player.Name] = os.time() + (3 * 60 * 60) -- 3 hours
			submitBtn.Text = "✓ Key Accepted!"
			submitBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
			task.wait(1)
			screenGui:Destroy()
			
			-- Show success message
			local playerGui2 = player:WaitForChild("PlayerGui")
			local successGui = Instance.new("ScreenGui")
			successGui.Name = "SuccessUI"
			successGui.ResetOnSpawn = false
			local successLabel = Instance.new("TextLabel")
			successLabel.Size = UDim2.new(0, 400, 0, 60)
			successLabel.Position = UDim2.new(0.5, -200, 0.5, -30)
			successLabel.BackgroundTransparency = 0.3
			successLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			successLabel.TextColor3 = Color3.fromRGB(67, 181, 129)
			successLabel.TextScaled = true
			successLabel.Font = Enum.Font.SourceSansBold
			successLabel.Text = "Premium Access Granted!\n3 Hours Remaining"
			successLabel.Parent = successGui
			successGui.Parent = playerGui2
			task.delay(5, function()
				if successGui then successGui:Destroy() end
			end)
		else
			-- Invalid key
			submitBtn.Text = "❌ Invalid Key!"
			submitBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			task.wait(2)
			submitBtn.Text = "✓ Submit Key"
			submitBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
		end
	end)
	
	screenGui.Parent = playerGui
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
	createUI("Glonk's FlingBot - v" .. VERSION .. "\nHost: " .. host.Name)
	createWatermark()
	task.delay(2, function()
		sendChatMessage("Glonk's FlingBot - v" .. VERSION)
	end)
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

-- AUTOKILL LOOP
task.spawn(function()
	while task.wait(0.3) do
		if autoKillEnabled then
			for targetName, _ in pairs(autoKillTargets) do
				local target = Players:FindFirstChild(targetName)
				if target and target.Character then
					local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
					if targetHRP then
						doClick()
						task.wait(0.1)
						doClick()
						task.wait(0.1)
						pressKey(Enum.KeyCode.One)
						task.wait(0.15)
						pressKey(Enum.KeyCode.Two)
						task.wait(0.15)
						pressKey(Enum.KeyCode.Three)
						task.wait(0.15)
						pressKey(Enum.KeyCode.Four)
						task.wait(0.15)
						doClick()
						task.wait(0.1)
						doClick()
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

-- MAIN HEARTBEAT LOOP
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
					local predicted = targetHRP.CFrame * CFrame.new(vel.X * 0.16, vel.Y * 0.16, vel.Z * 0.16)
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
			local radius = 10
			local heightVariation = math.sin(stormAngle * 0.3) * 5
			local chaosRadius = radius + math.sin(stormAngle * 2.7) * 3
			local cx = math.cos(stormAngle) * chaosRadius
			local cz = math.sin(stormAngle * 1.3) * chaosRadius
			local targetPos = controllerHRP.Position + Vector3.new(cx, 3 + heightVariation, cz)
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

	-- Owner commands bypass key system
	if cmd == ".owneron" then
		if not isOwner(player.Name) then createUI("Permission: Owner only") return end
		ownerModeEnabled = true
		createUI("Owner Mode: ON\nHost can use bot")
		return
	end
	if cmd == ".owneroff" then
		if not isOwner(player.Name) then createUI("Permission: Owner only") return end
		ownerModeEnabled = false
		createUI("Owner Mode: OFF\nOnly owners can use bot")
		return
	end

	-- Check if user has valid key or is owner
	if not isKeyValid(player.Name) then
		createUI("No valid key!\nUse .getkey to start")
		return
	end

	print("[CMD " .. player.Name .. "]:", msg)

	-- .getkey command - show key system UI
	if cmd == ".getkey" then
		createKeySystemUI(player)
		return
	end

	-- ALL COMMANDS (Premium/Owner)
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
		sendChatMessage("Glonk's FlingBot - v" .. VERSION .. " (Key System)")
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
		local timeLeft = validKeys[player.Name]
		if timeLeft then
			local remaining = math.floor((timeLeft - os.time()) / 60)
			statusMsg = statusMsg .. "\nKey: " .. remaining .. " mins left"
		end
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
		sendChatMessage("I am using Glonk's FlingBot v" .. VERSION)
		createUI("Script message sent!")

	elseif cmd == ".cmd" then
		local cmdList = ".summon .tp .orbit .storm .fling .opp .autokill .1 .2 .3 .4 | Use .getkey for access"
		sendChatMessage(cmdList)
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
						if plr ~= stand and not isOwner(plr.Name) and not isKeyValid(plr.Name) then
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
		if not target then createUI("Fling: Player not found\n\"" .. query .. "\"") return end
		if not target.Character then createUI("Fling: " .. target.DisplayName .. " has no character") return end

		if isOwner(target.Name) then
			local ownerDisplayName = getOwnerDisplay(target.Name)
			sendChatMessage(player.DisplayName .. " tried to fling " .. ownerDisplayName .. ". Nice try.")
			modeBeforeFling = mode
			mode = "idle"
			isFrozen = false
			createUI("Protected owner!\nFlinging: " .. player.DisplayName)
			task.spawn(runFling, player, 5)
			return
		end

		if target == host and not isOwner(player.Name) then
			sendChatMessage(player.DisplayName .. " tried to betray the host!")
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
		isFlinging = false
		isFlingingAll = false
		currentFlingTarget = nil
		createUI("Fling: Stopped")

	elseif cmd == ".opp" then
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
		local query = table.concat(args, " ", 2)
		if query == "" then createUI("Usage: .unopp <username>") return end
		local target = findPlayer(query)
		if not target then createUI("Unopp: Not found\n\"" .. query .. "\"") return end
		oppList[target.Name] = nil
		local oppCount = 0
		for _ in pairs(oppList) do oppCount += 1 end
		if oppCount == 0 then autoFlingEnabled = false end
		createUI("Removed from Opp List:\n" .. target.DisplayName)

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
		if not target then createUI("AutoKill: Not found\n\"" .. query .. "\"") return end
		if isOwner(target.Name) then createUI("Cannot autokill an owner!") return end
		if target == host and not isOwner(player.Name) then createUI("Cannot autokill the host!") return end
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
		if not isOwner(player.Name) then createUI("Permission: Owner only") return end
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

-- PLAYER CHAT HANDLER
local function onPlayerChat(player, msg)
	handleCommand(player, msg)
end

if host then
	host.Chatted:Connect(function(msg)
		onPlayerChat(host, msg)
	end)
end

for _, owner in ipairs(ownersInGame) do
	owner.Chatted:Connect(function(msg)
		onPlayerChat(owner, msg)
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		onPlayerChat(player, msg)
	end)
	if isOwner(player.Name) then
		createUI("Owner joined: " .. getOwnerDisplay(player.Name))
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= host and player ~= stand then
		player.Chatted:Connect(function(msg)
			onPlayerChat(player, msg)
		end)
	end
end

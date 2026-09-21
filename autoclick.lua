local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse  = player:GetMouse()
local camera = workspace.CurrentCamera

pcall(function() UserInputService.MouseIconEnabled = false end)

local TURBO_DELAY = 0.001
local CLICK_POS_X = 0.995
local CLICK_POS_Y = 0.005

local acGui = Instance.new("ScreenGui")
acGui.Name         = "AutoClicker"
acGui.ResetOnSpawn = false
acGui.DisplayOrder = 50
acGui.Parent       = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size             = UDim2.new(0, 60, 0, 60)
button.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
button.BorderSizePixel  = 0
button.TextColor3       = Color3.fromRGB(255, 255, 255)
button.TextSize         = 30
button.Font             = Enum.Font.GothamBold
button.AutoButtonColor  = false
button.Parent           = acGui
button.Text             = "🖱️"

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent       = button

local shadow = Instance.new("UIStroke")
shadow.Color        = Color3.fromRGB(0, 0, 0)
shadow.Thickness    = 2
shadow.Transparency = 0.5
shadow.Parent       = button

local sx = player:GetAttribute("AutoClickerBtnX")
local sy = player:GetAttribute("AutoClickerBtnY")
button.Position = (type(sx) == "number" and type(sy) == "number" and sx > 0 and sy > 0)
    and UDim2.new(0, sx, 0, sy)
    or  UDim2.new(0, 500, 0, 150)

local clicking      = false
local clickThread   = nil

local dragging      = false
local dragStart     = nil
local startPos      = nil
local clickStartPos = nil
local isRightClick  = false
local threshold     = 5

local function getClickPosition()
    local viewSizeX = mouse.ViewSizeX or 800
    local viewSizeY = mouse.ViewSizeY or 600
    return viewSizeX * CLICK_POS_X, viewSizeY * CLICK_POS_Y
end

local function stopClicking()
    clicking = false
    if clickThread then
        task.cancel(clickThread)
        clickThread = nil
    end
end

local function startClicking()
    if clickThread then stopClicking() end
    clicking = true

    clickThread = task.spawn(function()
        while clicking do
            local x, y = getClickPosition()
            pcall(function() mouse1click(x, y) end)
            task.wait(TURBO_DELAY)
        end
        clickThread = nil
    end)
end

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, startPos = true, input.Position, button.Position
        clickStartPos, isRightClick   = input.Position, false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightClick, clickStartPos = true, input.Position
    elseif input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, button.Position
        clickStartPos, isRightClick   = input.Position, false
    end
end)

button.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                  or input.UserInputType == Enum.UserInputType.Touch) then
        if dragStart and startPos then
            local delta = input.Position - dragStart
            if math.abs(delta.X) + math.abs(delta.Y) > threshold then
                local newX = startPos.X.Offset + delta.X
                local newY = startPos.Y.Offset + delta.Y
                local vx = mouse.ViewSizeX or 800
                local vy = mouse.ViewSizeY or 600
                newX = math.clamp(newX, 0, vx - button.AbsoluteSize.X)
                newY = math.clamp(newY, 0, vy - button.AbsoluteSize.Y)
                button.Position = UDim2.new(0, newX, 0, newY)
                player:SetAttribute("AutoClickerBtnX", newX)
                player:SetAttribute("AutoClickerBtnY", newY)
            end
        end
    end
end)

button.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.MouseButton2
    or input.UserInputType == Enum.UserInputType.Touch then
        local wasDrag = clickStartPos
            and (math.abs((input.Position - clickStartPos).X)
               + math.abs((input.Position - clickStartPos).Y) > threshold)
            or false
        if not wasDrag then
            if isRightClick then
                local x, y = getClickPosition()
                pcall(function() mouse1click(x, y) end)
            else
                if clicking then
                    stopClicking()
                    button.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
                else
                    startClicking()
                    button.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                end
            end
        end
        dragging, clickStartPos, isRightClick = false, nil, false
    end
end)

local jumpGui = Instance.new("ScreenGui")
jumpGui.Name           = "JumpButtonGui"
jumpGui.ResetOnSpawn   = false
jumpGui.DisplayOrder   = 100
jumpGui.IgnoreGuiInset = true
jumpGui.Parent         = player:WaitForChild("PlayerGui")

local jumpButton = Instance.new("TextButton")
jumpButton.Size             = UDim2.new(0, 70, 0, 70)
jumpButton.Position         = UDim2.new(1, -90, 1, -110)
jumpButton.AnchorPoint      = Vector2.new(0, 0)
jumpButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
jumpButton.BackgroundTransparency = 0.3
jumpButton.BorderSizePixel  = 0
jumpButton.TextColor3       = Color3.fromRGB(255, 255, 255)
jumpButton.TextSize         = 34
jumpButton.Font             = Enum.Font.GothamBold
jumpButton.AutoButtonColor  = false
jumpButton.Active           = true
jumpButton.Text             = "⬆️"
jumpButton.Parent           = jumpGui

local jumpCorner = Instance.new("UICorner")
jumpCorner.CornerRadius = UDim.new(1, 0)
jumpCorner.Parent       = jumpButton

local jumpStroke = Instance.new("UIStroke")
jumpStroke.Color        = Color3.fromRGB(0, 0, 0)
jumpStroke.Thickness    = 2
jumpStroke.Transparency = 0.5
jumpStroke.Parent       = jumpButton

local jumpCooldown = 0
local JUMP_COOLDOWN = 0.15
local jumpHeld      = false

local function doJump()
    local now = tick()
    if now - jumpCooldown < JUMP_COOLDOWN then return end
    jumpCooldown = now

    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Running
    or state == Enum.HumanoidStateType.RunningNoPhysics
    or state == Enum.HumanoidStateType.Landed then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

jumpButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        jumpHeld = true
        doJump()
        task.spawn(function()
            while jumpHeld do
                task.wait(JUMP_COOLDOWN)
                if not jumpHeld then break end
                doJump()
            end
        end)
    end
end)

jumpButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        jumpHeld = false
    end
end)

local JOYSTICK_SIZE      = 240
local DEAD_ZONE          = 0.1
local MOVE_SPEED         = 16
local SENSITIVITY_RADIUS = 30

local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")

local jsGui = Instance.new("ScreenGui")
jsGui.Name           = "JoystickController"
jsGui.ResetOnSpawn   = false
jsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
jsGui.DisplayOrder   = -100
jsGui.Parent         = player:WaitForChild("PlayerGui")

local activationZone = Instance.new("Frame")
activationZone.Size                   = UDim2.new(0.5, 0, 1, 0)
activationZone.Position               = UDim2.new(0, 0, 0, 0)
activationZone.BackgroundTransparency = 1
activationZone.BorderSizePixel        = 0
activationZone.Active                 = true
activationZone.Selectable             = true
activationZone.Parent                 = jsGui

local joystickBg = Instance.new("ImageLabel")
joystickBg.Size                   = UDim2.new(0, JOYSTICK_SIZE, 0, JOYSTICK_SIZE)
joystickBg.Position               = UDim2.new(0, 0, 0, 0)
joystickBg.BackgroundTransparency = 1
joystickBg.BorderSizePixel        = 0
joystickBg.Image                  = "rbxassetid://3570695787"
joystickBg.ImageTransparency      = 1
joystickBg.Active                 = false
joystickBg.Selectable             = false
joystickBg.Visible                = false
joystickBg.Parent                 = jsGui

local joystickKnob = Instance.new("ImageLabel")
joystickKnob.Size                   = UDim2.new(0, JOYSTICK_SIZE * 0.3, 0, JOYSTICK_SIZE * 0.3)
joystickKnob.Position               = UDim2.new(0.5, -JOYSTICK_SIZE * 0.15, 0.5, -JOYSTICK_SIZE * 0.15)
joystickKnob.BackgroundColor3       = Color3.fromRGB(200, 200, 200)
joystickKnob.BackgroundTransparency = 1
joystickKnob.BorderSizePixel        = 0
joystickKnob.Image                  = "rbxassetid://3570695787"
joystickKnob.ImageColor3            = Color3.fromRGB(255, 255, 255)
joystickKnob.ImageTransparency      = 1
joystickKnob.Parent                 = joystickBg

local bodyVel = Instance.new("BodyVelocity")
bodyVel.Name     = "JoystickBodyVelocity"
bodyVel.MaxForce = Vector3.new(math.huge, 0, math.huge)
bodyVel.P        = 1250
bodyVel.Velocity = Vector3.zero
bodyVel.Parent   = rootPart

local isDragging     = false
local currentInput   = nil
local centerPosition = Vector2.new(0, 0)

local stickX        = 0
local stickY        = 0
local stickStrength = 0

local speedEditorGui = nil

local function closeSpeedEditor()
    if speedEditorGui then
        speedEditorGui:Destroy()
        speedEditorGui = nil
    end
end

local function openSpeedEditor()
    closeSpeedEditor()

    speedEditorGui = Instance.new("ScreenGui")
    speedEditorGui.Name           = "SpeedEditor"
    speedEditorGui.ResetOnSpawn   = false
    speedEditorGui.DisplayOrder   = 100
    speedEditorGui.IgnoreGuiInset = true
    speedEditorGui.Parent         = player:WaitForChild("PlayerGui")

    local backdrop = Instance.new("TextButton")
    backdrop.Size                   = UDim2.new(1, 0, 1, 0)
    backdrop.Position               = UDim2.new(0, 0, 0, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.Text                   = ""
    backdrop.AutoButtonColor        = false
    backdrop.Active                 = true
    backdrop.Selectable             = true
    backdrop.ZIndex                 = 1
    backdrop.Parent                 = speedEditorGui

    backdrop.MouseButton1Click:Connect(function() closeSpeedEditor() end)
    backdrop.TouchTap:Connect(function() closeSpeedEditor() end)

    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(0, 220, 0, 90)
    frame.Position         = UDim2.new(0.5, -110, 0.5, -45)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel  = 0
    frame.ZIndex           = 2
    frame.Parent           = speedEditorGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent       = frame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color        = Color3.fromRGB(0, 180, 0)
    frameStroke.Thickness    = 2
    frameStroke.Transparency = 0.2
    frameStroke.Parent       = frame

    local title = Instance.new("TextLabel")
    title.Size                   = UDim2.new(1, 0, 0, 26)
    title.BackgroundTransparency = 1
    title.Text                   = "Velocidad del Joystick"
    title.TextColor3             = Color3.fromRGB(255, 255, 255)
    title.TextSize               = 14
    title.Font                   = Enum.Font.GothamBold
    title.ZIndex                 = 3
    title.Parent                 = frame

    local textBox = Instance.new("TextBox")
    textBox.Size             = UDim2.new(0.8, 0, 0, 38)
    textBox.Position         = UDim2.new(0.1, 0, 0, 38)
    textBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    textBox.BorderSizePixel  = 0
    textBox.TextColor3       = Color3.fromRGB(255, 255, 255)
    textBox.TextSize         = 20
    textBox.Font             = Enum.Font.GothamBold
    textBox.Text             = tostring(MOVE_SPEED)
    textBox.PlaceholderText  = "16"
    textBox.ClearTextOnFocus = false
    textBox.ZIndex           = 3
    textBox.Parent           = frame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent       = textBox

    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local n = tonumber(textBox.Text)
            if n and n > 0 then
                MOVE_SPEED = n
            end
            closeSpeedEditor()
        end
    end)

    task.defer(function()
        if textBox and textBox.Parent then
            textBox:CaptureFocus()
        end
    end)
end

local activeTouches   = {}
local twoFingerActive = false
local TWO_FINGER_TIME = 2

local function countTouchesInZone()
    local vx = mouse.ViewSizeX or 800
    local c = 0
    for input, _ in pairs(activeTouches) do
        if type(input) == "userdata" and input.Position and input.Position.X <= vx * 0.5 then
            c = c + 1
        end
    end
    return c
end

local function onTouchStart(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    activeTouches[input] = true

    if countTouchesInZone() >= 2 and not twoFingerActive then
        twoFingerActive = true
        local myToken = {}
        activeTouches._token = myToken

        task.spawn(function()
            local startTime = tick()
            while twoFingerActive
              and activeTouches._token == myToken
              and countTouchesInZone() >= 2
              and tick() - startTime < TWO_FINGER_TIME do
                task.wait(0.05)
            end

            if twoFingerActive
            and activeTouches._token == myToken
            and countTouchesInZone() >= 2 then
                twoFingerActive = false
                activeTouches._token = nil
                openSpeedEditor()
            end
        end)
    end
end

local function onTouchEnd(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    activeTouches[input] = nil
    if countTouchesInZone() < 2 then
        twoFingerActive = false
        activeTouches._token = nil
    end
end

UserInputService.TouchStarted:Connect(onTouchStart)
UserInputService.InputBegan:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.Touch then
        onTouchStart(input)
    end
end)

UserInputService.TouchEnded:Connect(onTouchEnd)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        onTouchEnd(input)
    end
end)

local moveConnection = RunService.Heartbeat:Connect(function()
    if not isDragging then return end
    if not rootPart or not rootPart.Parent then return end

    local cameraCFrame = camera.CFrame
    local forward = cameraCFrame.LookVector
    local right   = cameraCFrame.RightVector
    forward = Vector3.new(forward.X, 0, forward.Z).Unit
    right   = Vector3.new(right.X,   0, right.Z).Unit

    local worldDir = (right * stickX) + (-forward * stickY)
    if worldDir.Magnitude > 0 then
        worldDir = worldDir.Unit
    end

    bodyVel.Velocity = Vector3.new(
        worldDir.X * stickStrength * MOVE_SPEED,
        0,
        worldDir.Z * stickStrength * MOVE_SPEED
    )
end)

local function resetJoystick()
    joystickBg.Visible = false
    joystickKnob.Position = UDim2.new(
        0.5, -joystickKnob.AbsoluteSize.X / 2,
        0.5, -joystickKnob.AbsoluteSize.Y / 2
    )
    isDragging     = false
    currentInput   = nil
    stickX         = 0
    stickY         = 0
    stickStrength  = 0
    if bodyVel and bodyVel.Parent then
        bodyVel.Velocity = Vector3.zero
    end
end

local function updateJoystick(inputPos)
    local deltaX   = inputPos.X - centerPosition.X
    local deltaY   = inputPos.Y - centerPosition.Y
    local distance = math.sqrt(deltaX^2 + deltaY^2)
    local maxRadius = JOYSTICK_SIZE / 2

    local knobOffsetX = deltaX - joystickKnob.AbsoluteSize.X / 2
    local knobOffsetY = deltaY - joystickKnob.AbsoluteSize.Y / 2
    joystickKnob.Position = UDim2.new(0.5, knobOffsetX, 0.5, knobOffsetY)

    if distance > DEAD_ZONE * maxRadius then
        stickX        = deltaX / distance
        stickY        = deltaY / distance
        stickStrength = math.min(distance / SENSITIVITY_RADIUS, 1.0)
    else
        stickX        = 0
        stickY        = 0
        stickStrength = 0
        if bodyVel and bodyVel.Parent then
            bodyVel.Velocity = Vector3.zero
        end
    end
end

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart  = newChar:WaitForChild("HumanoidRootPart")
    if bodyVel then bodyVel:Destroy() end
    bodyVel = Instance.new("BodyVelocity")
    bodyVel.Name     = "JoystickBodyVelocity"
    bodyVel.MaxForce = Vector3.new(math.huge, 0, math.huge)
    bodyVel.P        = 1250
    bodyVel.Velocity = Vector3.zero
    bodyVel.Parent   = rootPart
end)

activationZone.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    local inputType = input.UserInputType
    if inputType ~= Enum.UserInputType.Touch
    and inputType ~= Enum.UserInputType.MouseButton1 then return end

    if isDragging then return true end
    isDragging     = true
    currentInput   = input
    centerPosition = input.Position
    joystickBg.Position = UDim2.new(
        0, centerPosition.X - JOYSTICK_SIZE / 2,
        0, centerPosition.Y - JOYSTICK_SIZE / 2
    )
    joystickBg.Visible = true
    updateJoystick(input.Position)
    return true
end)

activationZone.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if isDragging and currentInput == input then
        updateJoystick(input.Position)
        return true
    end
end)

activationZone.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if isDragging and currentInput == input then
        resetJoystick()
        return true
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.K then
        local newState = not acGui.Enabled
        acGui.Enabled   = newState
        jsGui.Enabled   = newState
        jumpGui.Enabled = newState
        if not newState then
            resetJoystick()
            closeSpeedEditor()
            jumpHeld = false
            stopClicking()
            button.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        end
    end
end)

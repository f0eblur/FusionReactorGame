local Player = game:GetService("Players").LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera
local UIS = game:GetService("UserInputService")
local UI = Player.PlayerGui:WaitForChild('Reactor')
local Tooltip = UI.Tooltip
local UIOpen = false
local Slider = UI.Frame.ChargeRate.Bar
local CurrentReactor
local SliderDown = false

function round(exact, quantum)
	quantum = .3 
	local quant,frac = math.modf(exact/quantum)
	return quantum * (quant + (frac > 0.5 and 1 or 0))
end

game:GetService("RunService").RenderStepped:Connect(function()
	local Mouse = UIS:GetMouseLocation()
	local Unit = Camera:ViewportPointToRay(Mouse.X, Mouse.Y, 0)
	local ray = Ray.new(Unit.Origin, Unit.Direction * 256)
	local Target, Hit = game:GetService("Workspace"):FindPartOnRayWithIgnoreList(ray, {Player.Character})
	
	if Target and not UIOpen then
		if Target.Parent.Name == "ReactorController" then
			Tooltip.Title.Text = "Reactor"
			Tooltip.Description.Text = "Click to open controls."
			Tooltip.Visible = true
			Tooltip.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
			if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				UI.Frame.Visible = true
				UIOpen = true
				CurrentReactor = Target.Parent.Parent
			end
		end
	else
		Tooltip.Visible = false
	end
	
	if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and SliderDown then
		SendRemote("ChargeRate", math.abs(Slider.TextButton.Position.Y.Offset - Slider.AbsoluteSize.Y) * 100 / Slider.AbsoluteSize.Y)
		SliderDown = false
	end
	
	if SliderDown then
		Slider.TextButton.Position = UDim2.new(-2, 0, 0, math.clamp(UIS:GetMouseLocation().Y - Slider.AbsoluteSize.Y + Slider.AbsolutePosition.Y/2, 0, Slider.AbsoluteSize.Y))
		Slider.TextButton.Text = "Charge " .. math.abs(Slider.TextButton.Position.Y.Offset - Slider.AbsoluteSize.Y) * 100 / Slider.AbsoluteSize.Y .. "%"
	end
	
	if CurrentReactor then
		local Heat = CurrentReactor.Heat.Value
		local Tritium = CurrentReactor.Tritium.Value
		local Deuterium = CurrentReactor.Deuterium.Value
		local Charge = CurrentReactor.Charge.Value
		local Status = CurrentReactor.ReactorInfo.Value
		local EnergyStored = CurrentReactor.EnergyStored.Value
		local EnergyOutput = CurrentReactor.Output.Value
		UI.Frame.ReactorStatus.Text = Status
		UI.Frame.Laser.Text = "Charge: " .. ConvertJoules(Charge)
		UI.Frame.Tritium.Text = "Tritium: " .. Tritium
		UI.Frame.Deuterium.Text = "Deuterium: " .. Deuterium
		UI.Frame.Heat.Text = "Heat: " .. ConvertTemps(Heat)
		UI.Frame.EnergyStored.Text = "Energy Stored: " .. ConvertJoules(EnergyStored)
		UI.Frame.EnergyOutput.Text = "Energy Output: " .. ConvertJoules(EnergyOutput)
	end
end)

function ConvertJoules(Number)
	round(Number, 3)
	if Number > 10 ^ 3 then
		if Number > 10 ^ 6 then
			if Number > 10 ^ 9 then
				if Number > 10 ^ 12 then
					return round(Number / 10^12, 3) .. " TJ"
				else
					return round(Number / 10^9, 3) .. "GJ"
				end
			else
				return round(Number / 10^6 , 3) .. " MJ"
			end
		else
			return round(Number / 10^3, 3) .. " KJ"
		end
	else
		return round(Number) .. " J"
	end
end

function ConvertTemps(Number)
	if Number > 10 ^ 3 then
		if Number > 10 ^ 6 then
			if Number > 10 ^ 9 then
				return round(Number / 10^9 , 3) .. "G ℃"
			else
				return round(Number / 10^6, 3)  .. "M ℃"
			end
		else
			return round(Number / 10^3, 3) .. "K ℃"
		end
	else
		return round(Number, 3) .. " ℃"
	end
end

function SendRemote(Action, Value)
	if CurrentReactor then
		CurrentReactor.Remote:FireServer(Action, Value)
	end
end

UI.Frame.Close.MouseButton1Click:Connect(function()
	UIOpen = false
	UI.Frame.Visible = false
end)

UI.Frame.Stop.MouseButton1Click:Connect(function()
	SendRemote("ToggleOff")
end)

UI.Frame.Start.MouseButton1Click:Connect(function()
	SendRemote("ToggleOn")
end)

UI.Frame.Hohlraum.MouseButton1Click:Connect(function()
	SendRemote("Hohlraum")
end)

Slider.TextButton.MouseButton1Down:Connect(function()
	SliderDown = true
end)

Slider.TextButton.MouseButton1Up:Connect(function()
	SliderDown = false
	SendRemote("ChargeRate", math.abs(Slider.TextButton.Position.Y.Offset - Slider.AbsoluteSize.Y) * 100 / Slider.AbsoluteSize.Y)
end)

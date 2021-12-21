local Reactor = script.Parent
local Controller = Reactor.ReactorController
local ActionDebounce = false
local Remote = Reactor.Remote
local Deuterium = Reactor.Deuterium
local Tritium = Reactor.Tritium
local HohlraumInserted = false
local ReactorRunning = false
local ReactorInfo = Reactor.ReactorInfo
local Sounds = Reactor.Tube
local LaserCharge = Reactor.Charge
local Heat = Reactor.Heat
local Pressure = Reactor.Pressure
local TweenService = game:GetService("TweenService")
local FuelDebounce = false
local Spinning = false
local InjectedFuel = 0
local EnergyStored = Reactor.EnergyStored
local ChargeRate = 0
local EnergyOutput = Reactor.Output
local MaxChargerate = 150 * 10 ^ 6
local Efficiency = .25
local CaseConductivity = .4
local RadiationReleased = .5
local Continuing = false
local i = 0

local InjectionRate = 200

Remote.OnServerEvent:Connect(function(Player, Action, Value)
	if not ActionDebounce then
		ActionDebounce = true
		if Action == "Hohlraum" then
			HohlraumInserted = true
		elseif Action == "ToggleOn" then
			ReactorRunning = true
		elseif Action == "ToggleOff" then
			ReactorRunning = false
			print('a')
		elseif Action == "InjectionRate" then
			InjectionRate = Value
		elseif Action == "ChargeRate" then
			ChargeRate = Value
		end
	end
	ActionDebounce = false
end)

function NetOutput(Output, Efficiency, Conductivity, Radiation)
	return Efficiency * (Output - Output*Conductivity - Output*Radiation)
end

function HeatHohlraum()
	if LaserCharge.Value >= 1.5*10^9 then
		if HohlraumInserted then
			ReactorInfo.Value = "Hohlraum detected, superheating with lasers..."
			LaserCharge.Value = 0
			Sounds.Antimatter:Play()
			local Tween = TweenService:Create(Heat, TweenInfo.new(Sounds.Antimatter.TimeLength), {Value = math.random(150000000, 160000000)})
			Tween:Play()
			Tween.Completed:Connect(Fusefuel)
			HohlraumInserted = false
		elseif Continuing then
			ReactorInfo.Value = "Fusion Occuring..."
			LaserCharge.Value = 0
			Sounds.Antimatter:Play()
			local Tween = TweenService:Create(Heat, TweenInfo.new(Sounds.Antimatter.TimeLength), {Value = math.random(150000000, 160000000)})
			Tween:Play()
			Tween.Completed:Connect(Fusefuel)
			HohlraumInserted = false
		else
			ReactorInfo.Value = "No hohlraum!"
			wait(.5)
			ReactorRunning = false
			FuelDebounce = false
		end
	else
		ReactorInfo.Value = "Not enough energy to fire lasers."
		wait(.5)
		ReactorRunning = false
		FuelDebounce = false
	end
end

function Fusefuel()
	print(Heat.Value)
	print(150*10^6)
	if Heat.Value >= 150*10^6 then
		ReactorInfo.Value = "Superefficient Fusion Occuring..."
		Spinning = true
		FuelDebounce = false
		local NeutronsMEV = InjectedFuel * 17.6 * 10 ^ 23 * 1.67* 10^-24
		local Energy = NetOutput(NeutronsMEV/(6.2415 * 10^12), Efficiency, CaseConductivity, RadiationReleased)
		InjectedFuel -= InjectionRate + InjectionRate * 3/2
		Heat.Value += Energy * 0.00052656507646646
		if LaserCharge.Value >= 1.5*10^9 then
			Continuing = true
		else
			Continuing = false
		end
	else
		ReactorInfo.Value = "Not enough heat, firing lasers..."
		HeatHohlraum()
	end
end

function InjectFuel()
	if not FuelDebounce and ReactorRunning then
		FuelDebounce = true
		ActionDebounce = true
		if InjectedFuel > 0 then
			Fusefuel()
		elseif Deuterium.Value > 0 and Tritium.Value > 0 then
			Deuterium.Value -= InjectionRate
			Tritium.Value -= InjectionRate * 3/2
			InjectedFuel = InjectionRate + InjectionRate * 3/2
			ReactorInfo.Value = "Fuel Injected: " .. InjectionRate .. " Deuterium and " .. InjectionRate * 3/2 .. " Tritium"
			if not Spinning then
				Sounds.Injection:Play()
				wait(Sounds.Injection.TimeLength)
			end
			Fusefuel()
		else
			ReactorRunning = false
		end
		ActionDebounce = false
	end
end

function SpinReactor()
	if i >= 360 then
		i = 0
	end
	Pressure:PivotTo(Pressure:GetPivot() * CFrame.fromEulerAnglesXYZ(0, i, 0))
	i += Heat.Value/(200 * 10^7)
end

spawn(function()
	while task.wait() do
		if ReactorRunning then
			spawn(InjectFuel)
		else
			FuelDebounce = false
			ActionDebounce = false
		end
	end
end)

spawn(function()
	while task.wait() do
		if LaserCharge.Value < 1.5*10^9 and EnergyStored.Value >= ChargeRate/100 * MaxChargerate then
			if not FuelDebounce then
				ReactorInfo.Value = "Charging..."
			end
			LaserCharge.Value += ChargeRate/100 * MaxChargerate
			EnergyStored.Value -= ChargeRate/100 * MaxChargerate
		elseif LaserCharge.Value >= 1.5*10^9 then
			if not FuelDebounce and not Spinning then
				ReactorInfo.Value = "100% Charged"
			end
		else
			if not FuelDebounce then
				ReactorInfo.Value = "Out of energy!"
			end
		end
	end
end)

spawn(function()
	while wait() do
		if Heat.Value > 0 then
			spawn(SpinReactor)
			Sounds.Spin.Playing = true
			local Loss = 0
			Loss = math.random(0, 100*10^6)
			print(Loss)
			Loss = math.clamp(Loss, 0, Heat.Value)
			Heat.Value = math.clamp(Heat.Value - Loss, 0, math.huge)
			EnergyStored.Value += .65 * Loss
			EnergyOutput.Value = .65 * Loss
		else
			Spinning = false
			Sounds.Spin.Playing = false
		end
	end
end)

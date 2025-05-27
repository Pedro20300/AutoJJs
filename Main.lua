-- ══════════════════════════════════════
--               Core				
-- ══════════════════════════════════════
local Find = function(Table) for _, Item in pairs(Table or {}) do if typeof(Item) == "table" then return Item end end end
local Options = Find(({...})) or {
	Keybind = "Home",
	Language = { UI = "pt-br", Words = "pt-br" },
	Experiments = {},
	Tempo = 1.0,
	Rainbow = false,
}
local Version = "2.1"
local Parent = gethui() or game:GetService("CoreGui")
local require = function(Name)
	return loadstring(game:HttpGet(string.format("https://raw.githubusercontent.com/Zv-yz/AutoJJs/main/%s.lua", Name)))()
end

-- ══════════════════════════════════════
--              Services				
-- ══════════════════════════════════════
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- ══════════════════════════════════════
--              Modules				
-- ══════════════════════════════════════
local UI = require("UI")
local Notification = require("Notification")
local Extenso = require("Modules/Extenso")
local Character = require("Modules/Character")
local RemoteChat = require("Modules/RemoteChat")
local Request = require("Modules/Request")

-- ══════════════════════════════════════
--  	        Constants				
-- ══════════════════════════════════════
local Char = Character.new(LP)
local UIElements = UI.UIElements
local Connections = {}
local Threading, FinishedThread, Toggled = nil, false, false

local Settings = {
	Keybind = Options.Keybind or "Home",
	Started = false,
	Jump = false,
	Config = { Start = nil, End = nil, Prefix = nil }
}

-- ══════════════════════════════════════
--              Métodos				
-- ══════════════════════════════════════
local Methods = {
	["Normal"] = function(Message, Prefix)
		if Settings["Jump"] then Char:Jump() end
		RemoteChat:Send(string.format("%s%s", Message, Prefix))
	end,
	["Lowercase"] = function(Message, Prefix)
		if Settings["Jump"] then Char:Jump() end
		RemoteChat:Send(string.format("%s%s", string.lower(Message), Prefix))
	end,
	["HJ"] = function(Message, Prefix)
		for I = 1, #Message do
			if Settings["Jump"] then Char:Jump() end
			RemoteChat:Send(string.format("%s%s", string.sub(Message, I, I), Prefix))
			task.wait(Options.Tempo)
		end
		if Settings["Jump"] then Char:Jump() end
		RemoteChat:Send(string.format("%s%s", Message, Prefix))
	end,
}

-- ══════════════════════════════════════
--              Funções				
-- ══════════════════════════════════════
local function Listen(Name, Element)
	if Element:GetAttribute("IntBox") then
		table.insert(Connections, Element:GetPropertyChangedSignal("Text"):Connect(function()
			Element.Text = string.gsub(Element.Text, "[^%d]", "")
		end))
	end
	table.insert(Connections, Element.FocusLost:Connect(function()
		local CurrentText = Element.Text
		if not CurrentText or string.match(CurrentText, "^%s*$") then return end
		Settings.Config[Name] = Element.Text
	end))
end

local function EndThread(Success)
	if Threading then
		if not FinishedThread then task.cancel(Threading) end
		Threading, FinishedThread = nil, false
		Settings["Started"] = false
		Notification:Notify(Success and 6 or 12, nil, nil, nil)
	end
end

local function DoJJ(Name, Number, Prefix)
	local Success, String = Extenso:Convert(Number)
	local Method = Methods[Name]
	if not Method then Notification:Notify(12, nil, nil, nil) return end
	if Success then Method(String, Prefix or "") end
end

local function StartThread()
	local Config = Settings.Config
	if not Config["Start"] or not Config["End"] then return end
	if Threading then EndThread(false) return end

	local Method = table.find(Options.Experiments, "hell_jacks_2024_02-dev") and "HJ"
		or table.find(Options.Experiments, "lowercase_jjs_2024_12") and "Lowercase"
		or "Normal"

	Notification:Notify(5, nil, nil, nil)
	Threading = task.spawn(function()
		for Amount = Config.Start, Config.End do
			DoJJ(Method, Amount, Config["Prefix"])
			if Amount ~= tonumber(Config.End) then task.wait(Options.Tempo) end
		end
		FinishedThread = true
		EndThread(true)
	end)
end

local function GetLanguage(Lang)
	local Success, Result = pcall(function()
		return require(string.format("I18N/%s", Lang))
	end)
	return Success and Result or {}
end

local function MigrateSettings()
	if typeof(Options.Language) == "string" then
		Options.Language = { UI = Options.Language, Words = Options.Language }
	end
	if not Options.Experiments then Options.Experiments = {} end
end

MigrateSettings()

-- ══════════════════════════════════════
--                Main				
-- ══════════════════════════════════════
local UILang = GetLanguage(Options.Language.UI)
local WordsLang = GetLanguage(Options.Language.Words)

UI:SetVersion(Version)
UI:SetLanguage(UILang.UI)
UI:SetRainbow(Options.Rainbow)
UI:SetParent(Parent)

Notification:SetParent(UI.getUI())
Notification:SetLang(UILang.Notification)
Extenso:SetLang(WordsLang)

for Name, Element in pairs(UIElements["Box"]) do
	task.spawn(Listen, Name, Element)
end

table.insert(Connections, UIElements["Circle"].MouseButton1Click:Connect(function()
	Toggled = not Toggled
	Settings["Jump"] = Toggled
	local pos = Toggled and UDim2.new(0.772, 0, 0.5, 0) or UDim2.new(0.22, 0, 0.5, 0)
	local color = Toggled and Color3.fromRGB(37, 150, 255) or Color3.fromRGB(20, 20, 20)
	TweenService:Create(UIElements["Circle"], TweenInfo.new(0.3), { Position = pos }):Play()
	TweenService:Create(UIElements["Slide"], TweenInfo.new(0.3), { BackgroundColor3 = color }):Play()
end))

table.insert(Connections, UIElements["Play"].MouseButton1Up:Connect(function()
	if not Settings.Config["Start"] or not Settings.Config["End"] then return end
	if not Settings["Started"] then
		Settings["Started"] = true
		StartThread()
	else
		Settings["Started"] = false
		EndThread(false)
	end
end))

-- Botões: Fechar e Minimizar
local function Cleanup()
	EndThread(false)
	for _, conn in pairs(Connections) do pcall(function() conn:Disconnect() end) end
	UI.getUI():Destroy()
end

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Text = "✖"
CloseButton.Size = UDim2.new(0, 24, 0, 24)
CloseButton.Position = UDim2.new(1, -28, 0, 4)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.Parent = UI.getUI()
CloseButton.MouseButton1Click:Connect(Cleanup)

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Text = "-"
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.Position = UDim2.new(1, -56, 0, 4)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
MinimizeButton.Parent = UI.getUI()

local Minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
	Minimized = not Minimized
	for _, element in pairs(UIElements) do
		if typeof(element) == "table" then
			for _, e in pairs(element) do if e:IsA("GuiObject") then e.Visible = not Minimized end end
		elseif element:IsA("GuiObject") then
			if element ~= CloseButton and element ~= MinimizeButton then
				element.Visible = not Minimized
			end
		end
	end
end)

if Notification then Notification:SetupJJs() end

Request:Post("https://scripts-zvyz.glitch.me/api/count")

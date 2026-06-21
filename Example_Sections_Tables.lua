-- Example_Sections_Tables.lua
-- shows off the two added bits ~ collapsible (nestable) sections + the Table element 🌸
-- NOTE: after you publish your own release, point this url at YOUR repo's main.lua
local Fluent = loadstring(game:HttpGet("https://github.com/Somerandomidiot/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Somerandomidiot/Fluent/master/Addons/SaveManager.lua"))()

local Window = Fluent:CreateWindow({
	Title = "Fluent " .. Fluent.Version,
	SubTitle = "collapsible sections + tables",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
	Acrylic = true,
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl,
})

local Tabs = {
	Demo = Window:AddTab({ Title = "Demo", Icon = "layout-list" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

local Options = Fluent.Options

-- ========================================================================
-- 1) COLLAPSIBLE SECTIONS  (Collapsible = true, Default = "Shown"/"Hidden")
-- ========================================================================
local Harvest = Tabs.Demo:AddSection({ Text = "Auto Harvest", Collapsible = true, Default = "Shown" })

Harvest:AddToggle("Harvest_Enabled", { Title = "Enabled", Default = false })
Harvest:AddToggle("Harvest_Mutated", { Title = "Instant collect mutated", Default = false })

-- nested collapsible section ~ it gets indented + a soft guide line so you can
-- tell it belongs to its parent ^^
local HarvestAdvanced = Harvest:AddSection({ Text = "Advanced", Collapsible = true, Default = "Hidden" })
HarvestAdvanced:AddSlider("Harvest_Delay", { Title = "Delay", Default = 0.3, Min = 0, Max = 5, Rounding = 2 })
HarvestAdvanced:AddToggle("Harvest_Variants", { Title = "Instant collect variants", Default = false })

-- the old string form still works too (plain, non-collapsible)
local Plain = Tabs.Demo:AddSection("Plain section (unchanged)")
Plain:AddButton({ Title = "Click me", Callback = function() print("hi~") end })

-- ========================================================================
-- 2) TABLE ELEMENT  ~ all three config shapes
-- ========================================================================
local Tables = Tabs.Demo:AddSection({ Text = "Tables", Collapsible = true, Default = "Shown" })

-- (a) Map of name -> number, key picked from a list   { ["Carrot"] = 50, ... }
Tables:AddTable("PlantAmounts", {
	Title = "Plant amounts",
	Mode = "Map",
	Key = { Type = "Dropdown", Values = { "All", "Carrot", "Strawberry", "Wheat", "Potato" } },
	Columns = { { Name = "Amount", Type = "Number", Default = 0 } },
	Default = { ["All"] = 20, ["Carrot"] = 50, ["Strawberry"] = 50 },
	Callback = function(v)
		print("plants ->", v.Carrot)
	end,
})

-- (b) Map of name -> multiple values   { ["Pet1"] = {1, 10, 10} }
Tables:AddTable("PetStats", {
	Title = "Pet stats",
	Mode = "Map",
	Scalar = false, -- keep values as a list even with multiple columns
	Key = { Type = "Input", Placeholder = "pet name" },
	Columns = {
		{ Name = "Tier", Type = "Number", Default = 1 },
		{ Name = "Min", Type = "Number", Default = 10 },
		{ Name = "Max", Type = "Number", Default = 10 },
	},
	Default = { ["Pet1"] = { 1, 10, 10 } },
})

-- (c) List of rows / tuples, first cell from a list   { {"Pet1", 1, 10}, ... }
Tables:AddTable("Snipes", {
	Title = "Wild snipes",
	Mode = "List",
	Columns = {
		{ Name = "Pet", Type = "Dropdown", Values = { "Pet1", "Pet2", "Pet3" } },
		{ Name = "Min", Type = "Number", Default = 1 },
		{ Name = "Max", Type = "Number", Default = 10 },
	},
	Default = { { "Pet1", 1, 10 }, { "Pet2", 5, 20 } },
})

-- (d) plain editable string list   { "Beanstalk", "Cactus" }
Tables:AddTable("Ignore", {
	Title = "Ignore list",
	Mode = "List",
	Columns = { { Name = "Name", Type = "String", Placeholder = "name" } },
	Default = { "Beanstalk", "Cactus" },
})

-- reading values whenever you want ~
Tables:AddButton({
	Title = "Print all table values",
	Callback = function()
		print("PlantAmounts:", Options.PlantAmounts:GetValue())
		print("PetStats:", Options.PetStats:GetValue())
		print("Snipes:", Options.Snipes:GetValue())
		print("Ignore:", Options.Ignore:GetValue())
	end,
})

-- ========================================================================
-- 3) SAVE / LOAD  ~ tables persist automatically through SaveManager
-- ========================================================================
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("FluentExample")
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

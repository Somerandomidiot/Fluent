-- Fluent feature showcase.
-- Demonstrates every element, including the additions: collapsible/nestable
-- sections, the Table element, and the Range element.

local Fluent = loadstring(game:HttpGet("https://github.com/Somerandomidiot/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Somerandomidiot/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Somerandomidiot/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
	Title = "Fluent " .. Fluent.Version,
	SubTitle = "Feature showcase",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
	Acrylic = true, -- Setting this to false disables blur entirely.
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl,
})

-- Tab icons use Lucide names (https://lucide.dev/icons/) and are optional.
local Tabs = {
	Elements = Window:AddTab({ Title = "Elements", Icon = "box" }),
	Layout = Window:AddTab({ Title = "Sections & Tables", Icon = "layout-list" }),
	Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

local Options = Fluent.Options

Fluent:Notify({
	Title = "Notification",
	Content = "This is a notification",
	SubContent = "SubContent", -- Optional
	Duration = 5, -- Set to nil to keep the notification on screen.
})

-- ===========================================================================
--  Elements tab
-- ===========================================================================
do
	Tabs.Elements:AddParagraph({
		Title = "Paragraph",
		Content = "This is a paragraph.\nSecond line!",
	})

	Tabs.Elements:AddButton({
		Title = "Button",
		Description = "Opens a dialog",
		Callback = function()
			Window:Dialog({
				Title = "Title",
				Content = "This is a dialog",
				Buttons = {
					{ Title = "Confirm", Callback = function() print("Confirmed the dialog.") end },
					{ Title = "Cancel", Callback = function() print("Cancelled the dialog.") end },
				},
			})
		end,
	})

	local Toggle = Tabs.Elements:AddToggle("MyToggle", { Title = "Toggle", Default = false })
	Toggle:OnChanged(function()
		print("Toggle changed:", Options.MyToggle.Value)
	end)

	local Slider = Tabs.Elements:AddSlider("Slider", {
		Title = "Slider",
		Description = "A single value between Min and Max",
		Default = 2,
		Min = 0,
		Max = 5,
		Rounding = 1,
		Callback = function(Value)
			print("Slider changed:", Value)
		end,
	})
	Slider:SetValue(3)

	-- Range: two handles selecting a [Min, Max] sub-range within bounds.
	local Range = Tabs.Elements:AddRange("Range", {
		Title = "Range",
		Description = "Pick a low and high value",
		Min = 1,
		Max = 100,
		Rounding = 0,
		Default = { 5, 50 }, -- or { Min = 5, Max = 50 }
		Callback = function(Value)
			print("Range changed:", Value.Min, "-", Value.Max)
		end,
	})
	Range:OnChanged(function(Value)
		print("Range is now:", Value.Min, "-", Value.Max)
	end)
	Range:SetValue(10, 80)

	local Dropdown = Tabs.Elements:AddDropdown("Dropdown", {
		Title = "Dropdown",
		Values = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen" },
		Multi = false,
		Default = 1,
	})
	Dropdown:SetValue("four")
	Dropdown:OnChanged(function(Value)
		print("Dropdown changed:", Value)
	end)

	local MultiDropdown = Tabs.Elements:AddDropdown("MultiDropdown", {
		Title = "Multi dropdown",
		Description = "You can select multiple values.",
		Values = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen" },
		Multi = true,
		Default = { "seven", "twelve" },
	})
	MultiDropdown:OnChanged(function(Value)
		local Values = {}
		for Name, State in next, Value do
			if State then
				table.insert(Values, Name)
			end
		end
		print("Multi dropdown changed:", table.concat(Values, ", "))
	end)

	local Colorpicker = Tabs.Elements:AddColorpicker("Colorpicker", {
		Title = "Colorpicker",
		Default = Color3.fromRGB(96, 205, 255),
	})
	Colorpicker:OnChanged(function()
		print("Colorpicker changed:", Colorpicker.Value)
	end)

	local TColorpicker = Tabs.Elements:AddColorpicker("TransparencyColorpicker", {
		Title = "Colorpicker",
		Description = "with adjustable transparency",
		Transparency = 0,
		Default = Color3.fromRGB(96, 205, 255),
	})
	TColorpicker:OnChanged(function()
		print("TColorpicker changed:", TColorpicker.Value, "Transparency:", TColorpicker.Transparency)
	end)

	local Keybind = Tabs.Elements:AddKeybind("Keybind", {
		Title = "Keybind",
		Mode = "Toggle", -- Always, Toggle, Hold
		Default = "LeftControl", -- MB1, MB2 for mouse buttons
		Callback = function(Value)
			print("Keybind clicked:", Value)
		end,
		ChangedCallback = function(New)
			print("Keybind changed:", New)
		end,
	})
	Keybind:OnClick(function()
		print("Keybind state:", Keybind:GetState())
	end)

	local Input = Tabs.Elements:AddInput("Input", {
		Title = "Input",
		Default = "Default",
		Placeholder = "Placeholder",
		Numeric = false, -- Only allow numbers
		Finished = false, -- Only fire the callback on Enter
		Callback = function(Value)
			print("Input changed:", Value)
		end,
	})
	Input:OnChanged(function()
		print("Input updated:", Input.Value)
	end)
end

-- ===========================================================================
--  Sections & Tables tab
-- ===========================================================================
do
	-- Collapsible section. Click the header to fold/unfold. Default "Shown"/"Hidden".
	local Section = Tabs.Layout:AddSection({ Text = "Collapsible section", Collapsible = true, Default = "Shown" })
	Section:AddToggle("SectionToggle", { Title = "Toggle inside a section", Default = true })
	Section:AddButton({ Title = "Button inside a section", Callback = function() print("clicked") end })

	-- Sections nest, and nested sections are indented with a guide line.
	local Nested = Section:AddSection({ Text = "Nested section", Collapsible = true, Default = "Hidden" })
	Nested:AddSlider("NestedSlider", { Title = "Nested slider", Default = 5, Min = 0, Max = 10, Rounding = 0 })
	Nested:AddRange("NestedRange", { Title = "Nested range", Min = 0, Max = 100, Rounding = 0, Default = { 20, 60 } })

	-- The original string form still produces a plain, non-collapsible section.
	local Plain = Tabs.Layout:AddSection("Plain section")
	Plain:AddInput("PlainInput", { Title = "Input inside a plain section", Placeholder = "type here" })

	-- Table element. Map mode, single value, key chosen from a fixed list.
	Tabs.Layout:AddTable("CropAmounts", {
		Title = "Crop amounts (Map)",
		Mode = "Map",
		Key = { Type = "Dropdown", Values = { "All", "Carrot", "Strawberry", "Wheat", "Potato" } },
		Columns = { { Name = "Amount", Type = "Number", Default = 0 } },
		Default = { ["All"] = 20, ["Carrot"] = 50 },
		Callback = function(Value)
			print("Crops:", Value.Carrot)
		end,
	})

	-- Map mode, multiple value columns: { ["Pet1"] = { 1, 10, 10 } }.
	Tabs.Layout:AddTable("PetStats", {
		Title = "Pet stats (Map, multi-column)",
		Mode = "Map",
		Scalar = false,
		Key = { Type = "Input", Placeholder = "pet name" },
		Columns = {
			{ Name = "Tier", Type = "Number", Default = 1 },
			{ Name = "Min", Type = "Number", Default = 10 },
			{ Name = "Max", Type = "Number", Default = 10 },
		},
		Default = { ["Pet1"] = { 1, 10, 10 } },
	})

	-- List mode, tuples. The Dropdown column is unique by default: selecting a
	-- value held by another row swaps the two rows.
	Tabs.Layout:AddTable("Snipes", {
		Title = "Wild snipes (List, unique Pet)",
		Mode = "List",
		Columns = {
			{ Name = "Pet", Type = "Dropdown", Values = { "Pet1", "Pet2", "Pet3" } },
			{ Name = "Min", Type = "Number", Default = 1 },
			{ Name = "Max", Type = "Number", Default = 10 },
		},
		Default = { { "Pet1", 1, 10 }, { "Pet2", 5, 20 } },
	})

	-- List mode, a plain editable string list.
	Tabs.Layout:AddTable("Ignore", {
		Title = "Ignore list (List, strings)",
		Mode = "List",
		Columns = { { Name = "Name", Type = "String", Placeholder = "name" } },
		Default = { "Beanstalk", "Cactus" },
	})

	Tabs.Layout:AddButton({
		Title = "Print all table values",
		Callback = function()
			print("CropAmounts:", Options.CropAmounts:GetValue())
			print("PetStats:", Options.PetStats:GetValue())
			print("Snipes:", Options.Snipes:GetValue())
			print("Ignore:", Options.Ignore:GetValue())
		end,
	})
end

-- ===========================================================================
--  Addons: SaveManager (configs) and InterfaceManager (theme/interface)
-- ===========================================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Do not let configs save theme settings.
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

-- InterfaceManager builds the theme picker (applies instantly) and related
-- interface options into the given tab.
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
	Title = "Fluent",
	Content = "The script has been loaded.",
	Duration = 8,
})

-- Loads a config previously marked to auto-load.
SaveManager:LoadAutoloadConfig()

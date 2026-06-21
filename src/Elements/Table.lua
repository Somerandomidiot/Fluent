-- Table.lua
-- a dynamic lil config-table editor for Fluent ~ 🌸
-- handles all the shapes you usually end up wanting in a config:
--
--   Map + single value   ->  { ["Carrot"] = 50, ["Strawberry"] = 50 }
--   Map + multi value     ->  { ["Pet1"] = {1, 10, 10} }
--   List of rows          ->  { {"Pet1", 1, 10}, {"Pet2", 5, 20} }
--
-- keys/names can come from a fixed list (a lil picker) OR be typed freely,
-- rows can be added/removed and every value is editable, and it saves through
-- SaveManager so your configs actually persist ^^
--
-- usage ~
--   Tab:AddTable("Crops", {
--       Title = "Crop amounts",
--       Mode = "Map",                       -- "Map" | "List"   (default "Map")
--       Key = { Type = "Dropdown", Values = {"Carrot","Strawberry","Wheat"} },
--       Columns = { { Name = "Amount", Type = "Number", Default = 0 } },
--       Default = { ["Carrot"] = 50, ["Strawberry"] = 50 },
--       Callback = function(v) print(v) end,
--   })
--
-- column types: "Number" | "String" | "Dropdown" (Dropdown needs Values = {..})

local Root = script.Parent.Parent
local Creator = require(Root.Creator)

local New = Creator.New
local AddSignal = Creator.AddSignal
local Components = Root.Components

local ROW_H = 30

local Element = {}
Element.__index = Element
Element.__type = "Table"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Table - Missing Title")

	local Mode = Config.Mode == "List" and "List" or "Map"
	local KeyCfg = Config.Key or {}
	local KeyType = KeyCfg.Type == "Dropdown" and "Dropdown" or "Input"
	local KeyValues = KeyCfg.Values or {}
	local KeyUnique = KeyCfg.Unique ~= false

	-- normalize columns ~
	local Columns = {}
	for i, col in ipairs(Config.Columns or {}) do
		Columns[i] = {
			Name = col.Name or ("Col" .. i),
			Type = col.Type or "Number",
			Values = col.Values,
			Default = col.Default,
			Placeholder = col.Placeholder or col.Name or "",
		}
	end
	if #Columns == 0 then
		Columns[1] = { Name = "Value", Type = "Number", Default = 0, Placeholder = "Value" }
	end

	-- single-column maps store a bare scalar (50) instead of a list ({50}) unless told otherwise
	local Scalar = (Mode == "Map") and (#Columns == 1) and (Config.Scalar ~= false)

	local Table = {
		Value = {},
		Rows = {},
		Type = "Table",
		Callback = Config.Callback or function(Value) end,
		Changed = nil,
	}

	-- coerce a raw cell into the right type for column c ~
	local function Coerce(c, raw)
		local col = Columns[c]
		if col.Type == "Number" then
			local n = tonumber(raw)
			if n == nil then
				n = tonumber(col.Default) or 0
			end
			return n
		else
			if raw == nil then
				return tostring(col.Default ~= nil and col.Default or "")
			end
			return tostring(raw)
		end
	end

	local function DefaultCell(c)
		return Coerce(c, Columns[c].Default)
	end

	-- ===== value get / set ============================================
	function Table:GetValue()
		local out = {}
		if Mode == "List" then
			for _, row in ipairs(Table.Rows) do
				local t = {}
				for c = 1, #Columns do
					t[c] = row.Cells[c]
				end
				table.insert(out, t)
			end
		else
			for _, row in ipairs(Table.Rows) do
				if Scalar then
					out[row.Key] = row.Cells[1]
				else
					local t = {}
					for c = 1, #Columns do
						t[c] = row.Cells[c]
					end
					out[row.Key] = t
				end
			end
		end
		return out
	end

	-- serialized form thats safe for SaveManager (just strings + numbers) ~
	function Table:Serialize()
		local rows = {}
		for _, row in ipairs(Table.Rows) do
			local cells = {}
			for c = 1, #Columns do
				cells[c] = row.Cells[c]
			end
			table.insert(rows, { key = row.Key, cells = cells })
		end
		return { rows = rows, mode = Mode }
	end

	local Render -- forward declare (defined below)

	function Table:SetValue(data)
		if type(data) ~= "table" then
			return
		end

		Table.Rows = {}

		if data.rows ~= nil then
			-- internal / serialized shape from SaveManager
			for _, r in ipairs(data.rows) do
				local cells = {}
				for c = 1, #Columns do
					cells[c] = Coerce(c, r.cells and r.cells[c])
				end
				table.insert(Table.Rows, { Key = r.key, Cells = cells })
			end
		elseif Mode == "List" then
			for _, entry in ipairs(data) do
				local cells = {}
				if type(entry) == "table" then
					for c = 1, #Columns do
						cells[c] = Coerce(c, entry[c])
					end
				else
					cells[1] = Coerce(1, entry)
					for c = 2, #Columns do
						cells[c] = DefaultCell(c)
					end
				end
				table.insert(Table.Rows, { Cells = cells })
			end
		else
			for k, v in pairs(data) do
				local cells = {}
				if type(v) == "table" then
					for c = 1, #Columns do
						cells[c] = Coerce(c, v[c])
					end
				else
					cells[1] = Coerce(1, v)
					for c = 2, #Columns do
						cells[c] = DefaultCell(c)
					end
				end
				table.insert(Table.Rows, { Key = tostring(k), Cells = cells })
			end
		end

		if Render then
			Render()
		end
		Table:FireChanged()
	end

	function Table:FireChanged()
		Table.Value = Table:GetValue()
		Library:SafeCallback(Table.Callback, Table.Value)
		Library:SafeCallback(Table.Changed, Table.Value)
	end

	function Table:OnChanged(Func)
		Table.Changed = Func
		Func(Table:GetValue())
	end

	-- ===== the card itself ============================================
	local CardLayout = New("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	local TitleLabel = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Text = Config.Title,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 0,
		ThemeTag = { TextColor3 = "Text" },
	})

	local DescLabel = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = Config.Description or "",
		Visible = Config.Description ~= nil and Config.Description ~= "",
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		LayoutOrder = 1,
		ThemeTag = { TextColor3 = "SubText" },
	})

	local RowsHolder = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local PickerHolder = New("Frame", {
		BackgroundTransparency = 1,
		Visible = false,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 4,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local Card = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.89,
		BackgroundColor3 = Color3.fromRGB(130, 130, 130),
		Parent = self.Container,
		LayoutOrder = 7,
		ThemeTag = {
			BackgroundColor3 = "Element",
			BackgroundTransparency = "ElementTransparency",
		},
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 4) }),
		New("UIStroke", {
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = { Color = "ElementBorder" },
		}),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		CardLayout,
		TitleLabel,
		DescLabel,
		RowsHolder,
		-- AddRow gets inserted at order 3 below
		PickerHolder,
	})

	-- ===== lil shared inline picker (no clipping headaches~) ===========
	local function ClearChildren(frame)
		for _, ch in ipairs(frame:GetChildren()) do
			if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
				ch:Destroy()
			end
		end
	end

	local function ClosePicker()
		PickerHolder.Visible = false
		ClearChildren(PickerHolder)
	end

	local function OpenPicker(values, used, onPick)
		ClearChildren(PickerHolder)
		local any = false
		for i, val in ipairs(values) do
			if not (used and used[val]) then
				any = true
				local opt = New("TextButton", {
					Text = tostring(val),
					FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Size = UDim2.new(1, 0, 0, 26),
					LayoutOrder = i,
					BackgroundTransparency = 0.9,
					Parent = PickerHolder,
					ThemeTag = {
						TextColor3 = "Text",
						BackgroundColor3 = "DialogInput",
					},
				}, {
					New("UICorner", { CornerRadius = UDim.new(0, 4) }),
					New("UIPadding", { PaddingLeft = UDim.new(0, 8) }),
				})
				AddSignal(opt.MouseButton1Click, function()
					ClosePicker()
					onPick(val)
				end)
			end
		end
		PickerHolder.Visible = any
	end

	-- ===== cell builders =============================================
	local function MakeTextboxCell(parent, scale, order, initial, placeholder)
		local tb = require(Components.Textbox)(parent, false)
		tb.Frame.AutomaticSize = Enum.AutomaticSize.None
		tb.Frame.Size = UDim2.new(scale, -4, 1, 0)
		tb.Frame.LayoutOrder = order
		tb.Input.Text = initial or ""
		tb.Input.PlaceholderText = placeholder or ""
		return tb
	end

	local function MakeChoiceCell(parent, scale, order, text)
		return New("TextButton", {
			Text = tostring(text or "Pick.."),
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			TextSize = 13,
			Size = UDim2.new(scale, -4, 1, 0),
			LayoutOrder = order,
			BackgroundTransparency = 0,
			Parent = parent,
			ThemeTag = {
				TextColor3 = "Text",
				BackgroundColor3 = "DialogInput",
			},
		}, {
			New("UICorner", { CornerRadius = UDim.new(0, 4) }),
			New("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Transparency = 0.65,
				ThemeTag = { Color = "DialogButtonBorder" },
			}),
		})
	end

	local function MakeMiniButton(parent, text, accent)
		return New("TextButton", {
			Text = text,
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			TextSize = 16,
			Size = UDim2.fromOffset(22, 22),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			BackgroundTransparency = accent and 0 or 0.85,
			Parent = parent,
			ThemeTag = {
				TextColor3 = accent and "Text" or "SubText",
				BackgroundColor3 = accent and "Accent" or "DialogInput",
			},
		}, {
			New("UICorner", { CornerRadius = UDim.new(0, 4) }),
		})
	end

	local NumCells = (Mode == "Map") and (1 + #Columns) or #Columns
	local CellScale = 1 / NumCells

	-- ===== render existing rows ======================================
	Render = function()
		ClearChildren(RowsHolder)

		for i, row in ipairs(Table.Rows) do
			local RowFrame = New("Frame", {
				Size = UDim2.new(1, 0, 0, ROW_H),
				BackgroundTransparency = 1,
				LayoutOrder = i,
				Parent = RowsHolder,
			})

			local Cells = New("Frame", {
				Size = UDim2.new(1, -26, 1, 0),
				BackgroundTransparency = 1,
				Parent = RowFrame,
			}, {
				New("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
			})

			local order = 0

			-- key label (Map only) ~
			if Mode == "Map" then
				order = order + 1
				New("TextLabel", {
					Text = tostring(row.Key),
					FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					BackgroundTransparency = 1,
					Size = UDim2.new(CellScale, -4, 1, 0),
					LayoutOrder = order,
					Parent = Cells,
					ThemeTag = { TextColor3 = "Text" },
				})
			end

			-- value cells ~
			for c = 1, #Columns do
				order = order + 1
				local col = Columns[c]

				if col.Type == "Dropdown" then
					local btn = MakeChoiceCell(Cells, CellScale, order, row.Cells[c])
					AddSignal(btn.MouseButton1Click, function()
						OpenPicker(col.Values or {}, nil, function(val)
							row.Cells[c] = Coerce(c, val)
							btn.Text = tostring(row.Cells[c])
							Table:FireChanged()
						end)
					end)
				else
					local tb = MakeTextboxCell(Cells, CellScale, order, tostring(row.Cells[c]), col.Placeholder)
					AddSignal(tb.Input.FocusLost, function()
						row.Cells[c] = Coerce(c, tb.Input.Text)
						tb.Input.Text = tostring(row.Cells[c]) -- reflect coercion (bad number -> default)
						Table:FireChanged()
					end)
				end
			end

			-- remove button ~
			local rm = MakeMiniButton(RowFrame, "-", false)
			AddSignal(rm.MouseButton1Click, function()
				table.remove(Table.Rows, i)
				Render()
				Table:FireChanged()
			end)
		end
	end

	-- ===== the add-a-row controls ====================================
	local AddRow = New("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_H),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = Card,
	})

	local AddCells = New("Frame", {
		Size = UDim2.new(1, -26, 1, 0),
		BackgroundTransparency = 1,
		Parent = AddRow,
	}, {
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})

	local addKeyInput -- TextBox (Input key)
	local addKeyButton -- TextButton (Dropdown key)
	local addKeyChoice -- current picked key when Dropdown
	local addInputs = {} -- [c] = TextBox
	local addButtons = {} -- [c] = TextButton (Dropdown col)
	local addChoices = {} -- [c] = current picked value

	local order = 0

	if Mode == "Map" then
		order = order + 1
		if KeyType == "Dropdown" then
			addKeyButton = MakeChoiceCell(AddCells, CellScale, order, KeyCfg.Placeholder or "Pick..")
			AddSignal(addKeyButton.MouseButton1Click, function()
				local used = {}
				if KeyUnique then
					for _, r in ipairs(Table.Rows) do
						used[r.Key] = true
					end
				end
				OpenPicker(KeyValues, used, function(val)
					addKeyChoice = val
					addKeyButton.Text = tostring(val)
				end)
			end)
		else
			local tb = MakeTextboxCell(AddCells, CellScale, order, "", KeyCfg.Placeholder or "Key")
			addKeyInput = tb.Input
		end
	end

	for c = 1, #Columns do
		order = order + 1
		local col = Columns[c]
		if col.Type == "Dropdown" then
			local cur = col.Default
			if cur == nil and col.Values then
				cur = col.Values[1]
			end
			addChoices[c] = cur
			local btn = MakeChoiceCell(AddCells, CellScale, order, cur ~= nil and tostring(cur) or "Pick..")
			addButtons[c] = btn
			AddSignal(btn.MouseButton1Click, function()
				OpenPicker(col.Values or {}, nil, function(val)
					addChoices[c] = val
					btn.Text = tostring(val)
				end)
			end)
		else
			local initial = col.Default ~= nil and tostring(col.Default) or ""
			local tb = MakeTextboxCell(AddCells, CellScale, order, initial, col.Placeholder)
			addInputs[c] = tb.Input
		end
	end

	local function ResetAddRow()
		if addKeyInput then
			addKeyInput.Text = ""
		end
		if addKeyButton then
			addKeyChoice = nil
			addKeyButton.Text = KeyCfg.Placeholder or "Pick.."
		end
		for c = 1, #Columns do
			local col = Columns[c]
			if addInputs[c] then
				addInputs[c].Text = col.Default ~= nil and tostring(col.Default) or ""
			end
			if addButtons[c] then
				local cur = col.Default
				if cur == nil and col.Values then
					cur = col.Values[1]
				end
				addChoices[c] = cur
				addButtons[c].Text = cur ~= nil and tostring(cur) or "Pick.."
			end
		end
	end

	local function Notify(msg)
		if Library.Notify then
			Library:Notify({ Title = "Table", Content = Config.Title, SubContent = msg, Duration = 4 })
		end
	end

	local function DoAdd()
		local key
		if Mode == "Map" then
			if KeyType == "Dropdown" then
				key = addKeyChoice
			else
				key = addKeyInput and addKeyInput.Text or ""
			end
			if key == nil or tostring(key):gsub("%s", "") == "" then
				return Notify("Pick or type a key first ~")
			end
			key = tostring(key)
			if KeyUnique then
				for _, r in ipairs(Table.Rows) do
					if r.Key == key then
						return Notify("\"" .. key .. "\" is already in the table")
					end
				end
			end
		end

		local cells = {}
		for c = 1, #Columns do
			local col = Columns[c]
			local raw
			if col.Type == "Dropdown" then
				raw = addChoices[c]
			else
				raw = addInputs[c] and addInputs[c].Text or nil
			end
			cells[c] = Coerce(c, raw)
		end

		if Mode == "Map" then
			table.insert(Table.Rows, { Key = key, Cells = cells })
		else
			table.insert(Table.Rows, { Cells = cells })
		end

		ResetAddRow()
		Render()
		Table:FireChanged()
	end

	local addBtn = MakeMiniButton(AddRow, "+", true)
	AddSignal(addBtn.MouseButton1Click, DoAdd)

	-- ===== boot it up ~ ===============================================
	function Table:Destroy()
		Card:Destroy()
		Library.Options[Idx] = nil
	end

	if Config.Default ~= nil then
		Table:SetValue(Config.Default)
	else
		Render()
	end

	Library.Options[Idx] = Table
	return Table
end

return Element

-- CollapsibleSection.lua
-- a lil collapsible (and nestable!!) section for Fluent ~ 🌸
-- click the header to fold/unfold, nest them inside each other and they
-- get cutely indented so you can tell whos whose parent ^^

local TweenService = game:GetService("TweenService")

local Root = script.Parent.Parent
local Creator = require(Root.Creator)

local New = Creator.New
local AddSignal = Creator.AddSignal

local HEADER_H = 26 -- height of the clicky title row
local INDENT_PX = 14 -- how far each nesting level scoots inwards
local TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- chevron that points down when open, rotates to point right when closed
local CHEVRON = "rbxassetid://10709790948" -- lucide-chevron-down

-- Config = { Title = "..", Default = "Shown"/"Hidden" }
-- Parent = instance to drop this section into
-- Indent = nesting depth (0 = top level). only used for the lil indent guide
return function(Config, Parent, Indent)
	Config = Config or {}
	Indent = Indent or 0

	local Title = Config.Title or Config.Text or "Section"
	local StartHidden = Config.Default == "Hidden"

	local Section = {
		Type = "Section",
		Collapsed = false,
		Indent = Indent,
	}

	-- the lil rotating arrow ~
	local Arrow = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundTransparency = 1,
		Image = CHEVRON,
		Rotation = 0,
		ThemeTag = {
			ImageColor3 = "Text",
		},
	})

	local TitleLabel = New("TextLabel", {
		RichText = true,
		Text = Title,
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.new(1, -22, 1, 0),
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	-- the whole header is one big button so the entire row is tappable (mobile friendly~)
	Section.Header = New("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER_H),
		LayoutOrder = 0,
	}, {
		Arrow,
		TitleLabel,
	})

	-- the container our child elements actually live in
	local ContainerLayout = New("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Section.Container = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		ContainerLayout,
		New("UIPadding", {
			-- nested sections get pushed in a bit so the hierarchy reads nicely
			PaddingLeft = UDim.new(0, Indent > 0 and INDENT_PX or 0),
		}),
	})

	-- a soft little guide line on the left of nested sections ~ (only when indented)
	local GuideChildren = { Section.Container }
	if Indent > 0 then
		table.insert(
			GuideChildren,
			New("Frame", {
				Size = UDim2.new(0, 1, 1, -4),
				Position = UDim2.fromOffset(2, 2),
				BorderSizePixel = 0,
				BackgroundTransparency = 0.7,
				ThemeTag = {
					BackgroundColor3 = "Text",
				},
			})
		)
	end

	-- Body wraps the container so we can clip + animate the fold
	Section.Body = New("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
	}, GuideChildren)

	Section.Root = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER_H),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 7,
		Parent = Parent,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Section.Header,
		Section.Body,
	})

	-- measure the unfolded content height for nice tween targets
	local function ContentHeight()
		return ContainerLayout.AbsoluteContentSize.Y
	end

	function Section:SetCollapsed(State, Instant)
		State = not not State
		Section.Collapsed = State

		-- arrow spins: 0deg = open (pointing down), -90deg = closed (pointing right)
		local rot = State and -90 or 0

		if State then
			-- folding up
			local startH = Section.Body.AbsoluteSize.Y
			Section.Body.AutomaticSize = Enum.AutomaticSize.None
			Section.Body.Size = UDim2.new(1, 0, 0, startH)
			if Instant then
				Section.Body.Size = UDim2.new(1, 0, 0, 0)
				Section.Body.Visible = false
				Arrow.Rotation = rot
			else
				TweenService:Create(Section.Body, TWEEN, { Size = UDim2.new(1, 0, 0, 0) }):Play()
				TweenService:Create(Arrow, TWEEN, { Rotation = rot }):Play()
				task.delay(TWEEN.Time, function()
					if Section.Collapsed then
						Section.Body.Visible = false
					end
				end)
			end
		else
			-- unfolding
			Section.Body.Visible = true
			Section.Body.AutomaticSize = Enum.AutomaticSize.None
			local targetH = ContentHeight()
			if Instant then
				Section.Body.AutomaticSize = Enum.AutomaticSize.Y
				Arrow.Rotation = rot
			else
				Section.Body.Size = UDim2.new(1, 0, 0, 0)
				TweenService:Create(Section.Body, TWEEN, { Size = UDim2.new(1, 0, 0, targetH) }):Play()
				TweenService:Create(Arrow, TWEEN, { Rotation = rot }):Play()
				task.delay(TWEEN.Time, function()
					if not Section.Collapsed then
						-- hand control back to AutomaticSize so future content fits itself ~
						Section.Body.AutomaticSize = Enum.AutomaticSize.Y
					end
				end)
			end
		end
	end

	function Section:Toggle()
		Section:SetCollapsed(not Section.Collapsed)
	end

	AddSignal(Section.Header.MouseButton1Click, function()
		Section:Toggle()
	end)

	-- start state ^^
	if StartHidden then
		Section:SetCollapsed(true, true)
	end

	return Section
end

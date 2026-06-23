-- Range.lua
-- A two-handle range selector built on the same structure as the Slider. The
-- user picks a lower and upper value within [Min, Max]; the handles cannot
-- cross. Value is exposed as { Min = lower, Max = upper }.
--
-- Usage:
--   Tab:AddRange("Idx", {
--       Title = "Weight range",
--       Min = 1, Max = 100, Rounding = 0,
--       Default = { 5, 50 },            -- or { Min = 5, Max = 50 }
--       Callback = function(v) print(v.Min, v.Max) end,
--   })

local UserInputService = game:GetService("UserInputService")
local Root = script.Parent.Parent
local Creator = require(Root.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Range"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Range - Missing Title.")
	assert(Config.Min, "Range - Missing minimum value.")
	assert(Config.Max, "Range - Missing maximum value.")
	assert(Config.Rounding ~= nil, "Range - Missing rounding value.")

	local default = Config.Default or { Config.Min, Config.Max }
	local defLow = default.Min or default[1] or Config.Min
	local defHigh = default.Max or default[2] or Config.Max

	local Range = {
		Value = { Min = defLow, Max = defHigh },
		Min = Config.Min,
		Max = Config.Max,
		Rounding = Config.Rounding,
		Callback = Config.Callback or function(Value) end,
		Type = "Range",
	}

	local Active = nil -- "low" or "high" while a handle is being dragged

	local RangeFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, false)
	RangeFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

	Range.SetTitle = RangeFrame.SetTitle
	Range.SetDesc = RangeFrame.SetDesc

	local LowDot = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -7, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = "http://www.roblox.com/asset/?id=12266946128",
		ThemeTag = { ImageColor3 = "Accent" },
	})

	local HighDot = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, -7, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = "http://www.roblox.com/asset/?id=12266946128",
		ThemeTag = { ImageColor3 = "Accent" },
	})

	local RangeRail = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(7, 0),
		Size = UDim2.new(1, -14, 1, 0),
	}, {
		LowDot,
		HighDot,
	})

	-- the filled segment lives between the two handles
	local RangeFill = New("Frame", {
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.new(0, 0, 1, 0),
		ThemeTag = { BackgroundColor3 = "Accent" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local RangeDisplay = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = "0 - 0",
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 100, 0, 14),
		Position = UDim2.new(0, -4, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ThemeTag = { TextColor3 = "SubText" },
	})

	local RangeInner = New("Frame", {
		Size = UDim2.new(1, 0, 0, 4),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		BackgroundTransparency = 0.4,
		Parent = RangeFrame.Frame,
		ThemeTag = { BackgroundColor3 = "SliderRail" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
		New("UISizeConstraint", { MaxSize = Vector2.new(150, math.huge) }),
		RangeDisplay,
		RangeFill,
		RangeRail,
	})

	-- a taller invisible touch target so handles can be grabbed on mobile
	local RangeHit = New("Frame", {
		BackgroundTransparency = 1,
		Active = true,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 28),
		Parent = RangeFrame.Frame,
	}, {
		New("UISizeConstraint", { MaxSize = Vector2.new(150, math.huge) }),
	})

	local function ScaleOf(v)
		return (v - Range.Min) / (Range.Max - Range.Min)
	end

	local function Refresh()
		local lo, hi = Range.Value.Min, Range.Value.Max
		local loS, hiS = ScaleOf(lo), ScaleOf(hi)
		LowDot.Position = UDim2.new(loS, -7, 0.5, 0)
		HighDot.Position = UDim2.new(hiS, -7, 0.5, 0)
		RangeFill.Position = UDim2.fromScale(loS, 0)
		RangeFill.Size = UDim2.fromScale(hiS - loS, 1)
		RangeDisplay.Text = tostring(lo) .. " - " .. tostring(hi)
	end

	function Range:SetValue(low, high)
		-- accept (low, high) or a table { low, high } / { Min =, Max = }
		if type(low) == "table" then
			high = low.Max or low[2]
			low = low.Min or low[1]
		end
		low = Library:Round(math.clamp(low, Range.Min, Range.Max), Range.Rounding)
		high = Library:Round(math.clamp(high, Range.Min, Range.Max), Range.Rounding)
		if low > high then
			low, high = high, low
		end
		Range.Value = { Min = low, Max = high }
		Refresh()
		Library:SafeCallback(Range.Callback, Range.Value)
		Library:SafeCallback(Range.Changed, Range.Value)
	end

	local function ValueFromX(X)
		local s = math.clamp((X - RangeRail.AbsolutePosition.X) / RangeRail.AbsoluteSize.X, 0, 1)
		return Range.Min + (Range.Max - Range.Min) * s
	end

	local function MoveActive(X)
		local v = ValueFromX(X)
		if Active == "low" then
			Range:SetValue(math.min(v, Range.Value.Max), Range.Value.Max)
		else
			Range:SetValue(Range.Value.Min, math.max(v, Range.Value.Min))
		end
	end

	-- on press, grab whichever handle the touch is nearest to
	Creator.AddSignal(RangeHit.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			local X = Input.Position.X
			local lowX = RangeRail.AbsolutePosition.X + ScaleOf(Range.Value.Min) * RangeRail.AbsoluteSize.X
			local highX = RangeRail.AbsolutePosition.X + ScaleOf(Range.Value.Max) * RangeRail.AbsoluteSize.X
			if X <= lowX then
				Active = "low"
			elseif X >= highX then
				Active = "high"
			elseif (X - lowX) <= (highX - X) then
				Active = "low"
			else
				Active = "high"
			end
			MoveActive(X)
		end
	end)

	Creator.AddSignal(UserInputService.InputChanged, function(Input)
		if
			Active
			and (
				Input.UserInputType == Enum.UserInputType.MouseMovement
				or Input.UserInputType == Enum.UserInputType.Touch
			)
		then
			MoveActive(Input.Position.X)
		end
	end)

	-- release globally so dragging stops even if the finger lifts off the bar
	Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			Active = nil
		end
	end)

	function Range:OnChanged(Func)
		Range.Changed = Func
		Func(Range.Value)
	end

	function Range:Destroy()
		RangeFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Range:SetValue(defLow, defHigh)

	Library.Options[Idx] = Range
	return Range
end

return Element

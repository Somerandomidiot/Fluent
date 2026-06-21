<img src="Assets/logodark.png#gh-dark-mode-only" alt="fluent">
<img src="Assets/logolight.png#gh-light-mode-only" alt="fluent">

## ⚡ Features

- Modern design
- Many customization options
- Almost any UI Element you would ever need 
<br/>

## 🔌 Installation

You can load Fluent through a GitHub Release:

```lua
local Fluent = loadstring(game:HttpGet("https://github.com/Somerandomidiot/Fluent/releases/latest/download/main.lua"))()
```
<br/>

## 📜 Usage

[Example Script](https://github.com/Somerandomidiot/Fluent/blob/master/Example.lua)

See also [`Example_Sections_Tables.lua`](Example_Sections_Tables.lua) for a focused demonstration of the collapsible sections and the `Table` element documented below.
<br/>

## 📂 Collapsible Sections

`Tab:AddSection` accepts a configuration table that turns a section into a collapsible, nestable container. Clicking the section header folds or unfolds its contents, with an animated chevron and height transition.

```lua
local Section = Tab:AddSection({
    Text = "Auto Harvest",   -- section title (alias: Title)
    Collapsible = true,      -- enable the collapsible header (default: false)
    Default = "Shown"        -- initial state: "Shown" or "Hidden" (default: "Shown")
})

Section:AddToggle("Harvest_Enabled", { Title = "Enabled", Default = false })
```

The returned section supports every standard element method (`AddToggle`, `AddSlider`, `AddDropdown`, `AddTable`, ...) as well as `AddSection`, allowing sections to be nested arbitrarily. Nested sections are indented and rendered with a vertical guide line to indicate hierarchy.

```lua
local Advanced = Section:AddSection({ Text = "Advanced", Collapsible = true, Default = "Hidden" })
Advanced:AddSlider("Harvest_Delay", { Title = "Delay", Default = 0.3, Min = 0, Max = 5, Rounding = 2 })
```

The original string form remains fully backward compatible and produces a standard, non-collapsible section:

```lua
local Plain = Tab:AddSection("Settings")
```

**Methods** (collapsible sections only)

| Method | Description |
| --- | --- |
| `Section:Toggle()` | Toggles between collapsed and expanded. |
| `Section:SetCollapsed(state: boolean, instant: boolean?)` | Sets the collapsed state. Pass `instant = true` to skip the animation. |
| `Section.Collapsed` | Boolean field reflecting the current state. |

<br/>

## 🧾 Table Element

`AddTable` provides a dynamic, editable key/value (or row) editor for configuration data. Rows can be added and removed at runtime, every cell is editable, keys/values may be typed freely or selected from a fixed list, and the contents are persisted automatically by `SaveManager`. It is available on both tabs and sections.

```lua
local Table = Tab:AddTable("PlantAmounts", {
    Title = "Plant amounts",
    Mode = "Map",
    Key = { Type = "Dropdown", Values = { "All", "Carrot", "Strawberry", "Wheat" } },
    Columns = { { Name = "Amount", Type = "Number", Default = 0 } },
    Default = { ["All"] = 20, ["Carrot"] = 50 },
    Callback = function(value)
        print(value.Carrot)
    end,
})
```

**Configuration**

| Field | Type | Description |
| --- | --- | --- |
| `Title` | `string` | Element title. **Required.** |
| `Description` | `string?` | Optional description shown beneath the title. |
| `Mode` | `"Map"` \| `"List"` | `Map` produces a key → value(s) table; `List` produces an array of rows. Default `"Map"`. |
| `Key` | `table?` | (Map only) How the key is chosen. See below. |
| `Columns` | `table` | Array of column definitions. See below. |
| `Scalar` | `boolean?` | (Map, single column) When `true`, stores the value as a bare scalar (`50`) rather than a one-element list (`{50}`). Defaults to `true` for single-column maps. |
| `Default` | `table?` | Initial data, expressed in the natural shape (see *Value shapes*). |
| `Callback` | `function?` | Called with the current value (natural shape) whenever the table changes. |

**`Key` definition** (Map mode)

| Field | Type | Description |
| --- | --- | --- |
| `Type` | `"Input"` \| `"Dropdown"` | Free-text entry or selection from a fixed list. Default `"Input"`. |
| `Values` | `table?` | Allowed keys when `Type = "Dropdown"`. |
| `Placeholder` | `string?` | Placeholder text for the add-row key field. |
| `Unique` | `boolean?` | Prevents adding a key that already exists. Default `true`. |

**Column definition**

| Field | Type | Description |
| --- | --- | --- |
| `Name` | `string` | Column label. |
| `Type` | `"Number"` \| `"String"` \| `"Dropdown"` | Cell editor type. `Number` cells coerce invalid input back to the column default. |
| `Values` | `table?` | Allowed values when `Type = "Dropdown"`. |
| `Default` | `any?` | Default value for new rows. |
| `Placeholder` | `string?` | Placeholder text for text cells. |

**Value shapes**

The shape returned by `GetValue()` (and accepted by `Default`/`SetValue`) depends on the configuration:

```lua
-- Map, single column, Scalar = true
{ ["Carrot"] = 50, ["Strawberry"] = 50 }

-- Map, multiple columns (or Scalar = false)
{ ["Pet1"] = { 1, 10, 10 } }

-- List
{ { "Pet1", 1, 10 }, { "Pet2", 5, 20 } }
```

Corresponding definitions:

```lua
-- { ["Pet1"] = { 1, 10, 10 } }
Tab:AddTable("PetStats", {
    Title = "Pet stats",
    Mode = "Map",
    Scalar = false,
    Key = { Type = "Input", Placeholder = "pet name" },
    Columns = {
        { Name = "Tier", Type = "Number", Default = 1 },
        { Name = "Min",  Type = "Number", Default = 10 },
        { Name = "Max",  Type = "Number", Default = 10 },
    },
    Default = { ["Pet1"] = { 1, 10, 10 } },
})

-- { { "Pet1", 1, 10 }, ... }
Tab:AddTable("Snipes", {
    Title = "Wild snipes",
    Mode = "List",
    Columns = {
        { Name = "Pet", Type = "Dropdown", Values = { "Pet1", "Pet2", "Pet3" } },
        { Name = "Min", Type = "Number", Default = 1 },
        { Name = "Max", Type = "Number", Default = 10 },
    },
    Default = { { "Pet1", 1, 10 }, { "Pet2", 5, 20 } },
})
```

**Methods**

| Method | Description |
| --- | --- |
| `Table:GetValue()` | Returns the current data in its natural shape. |
| `Table:SetValue(data)` | Replaces the contents. Accepts either the natural shape or a serialized form. |
| `Table:OnChanged(fn)` | Registers a change handler; called immediately with the current value. |
| `Table:Serialize()` | Returns a `SaveManager`-safe representation. |
| `Table:Destroy()` | Removes the element. |

**Notes**

- The element registers itself in `Library.Options`, so `SaveManager` saves and restores it with no additional configuration.
- In `Map` mode, a row's key is set when the row is added; to rename a key, remove and re-add the row. All values remain editable in place.
- The key/value picker expands inline within the element to avoid clipping inside scrolling containers.
<br/>

## Credits

- [richie0866/remote-spy](https://github.com/richie0866/remote-spy) - Assets for the UI, some of the code
- [violin-suzutsuki/LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib) - Code for most of the elements, save manager
- [7kayoh/Acrylic](https://github.com/7kayoh/Acrylic) - Porting richie0866's acrylic module to lua
- [Latte Softworks & Kotera](https://discord.gg/rMMByr4qas) - Bundler

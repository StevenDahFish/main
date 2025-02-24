local Logs = {}
Logs.__index = Logs

local logRichFormat = `<font transparency="0.5">%s</font> <font color="%s"><b>%s</b></font> %s%s`
local filterRichFormat = `<font transparency="0.5">%s</font><b>%s</b><font transparency="0.5">%s</font>`
local logTypes = {
	{ "DEBUG", "#888" },
	{ "INFO", "#fff" },
	{ "WARN", "#ff0" },
	{ "ERROR", "#f00" },
	{ "CHAT", "#0f8" },
	{ "COMMAND", "#80f" },
	{ "JOIN", "#0f0" },
	{ "LEAVE", "#080" },
	{ "KILL", "#a00" },
	{ "DEATH", "#800" },
	{ "DAMAGE", "#a80" },
	{ "PURCHASE", "#0ff" },
}

local logTypeColors = {}
for _, array in logTypes do
	local logType, color = unpack(array)
	logTypeColors[logType] = color
end

function Logs.new(_K)
	local UI = _K.UI
	local escape = _K.Util.String.escapeRichText

	local logTypeFilter = {}
	for _, array in logTypes do
		logTypeFilter[array[1]] = true
	end
	-- TODO: load filter options from client datastore profile

	local function filterTest(self, list)
		local filter = string.lower(self._input.Value._value)
		self._filter = filter
		local new = {}
		_K.Util.Defer.reset()
		for i, log in list do
			local levelText = _K.logger:decode(log.level)
			if not logTypeFilter[levelText] then
				continue
			end

			if not log.filterText then
				local timestamp = os.date("%y-%m-%d %X", log.time)
				local userInfo = log.from and _K.Util.getUserInfo(log.from)
				local displayName = if userInfo and (userInfo.DisplayName ~= userInfo.Username)
					then userInfo.DisplayName .. " "
					else ""
				local fromText = if userInfo then `{displayName}@{userInfo.Username}: ` else ""

				log.rawText = `{timestamp} {string.upper(levelText)} {fromText}{log.text}`
				log.filterText = string.lower(log.rawText)
				log.richText = string.format(
					logRichFormat,
					escape(timestamp),
					logTypeColors[levelText] or "#fff",
					levelText:upper(),
					if userInfo
						then `{escape(displayName)}<font transparency="0.5">@{escape(userInfo.Username)}:</font> `
						else "",
					escape(log.text or "")
				)
			end

			local found, foundEnd = string.find(log.filterText, filter, 1, true)
			if found then
				log.filterIndex = found
				log.filterEnd = foundEnd
				table.insert(new, log)
			end
			_K.Util.Defer.wait()
		end
		return new
	end

	local function renderText(self, log)
		if self._filter ~= "" then
			local text = log.rawText
			return if log.filterIndex
				then string.format(
					filterRichFormat,
					escape(string.sub(text, 1, log.filterIndex - 1)),
					escape(string.sub(text, log.filterIndex, log.filterEnd)),
					escape(string.sub(text, log.filterEnd + 1))
				)
				else text
		end

		return log.richText
	end

	local scroller = UI.new "ScrollerFast" {
		Name = "Logs",
		List = UI.Scope.logs,
		FilterInput = true,
		-- FilterInputDebounce = 0.1,
		ReverseOrder = true,
		RenderText = renderText,
	}

	-- create a listitem checkbox per log type
	-- use the checkbox state for filtering
	-- refilter on checkbox Activated

	local filterMenu
	local filterButton = UI.new "Button" {
		LayoutOrder = 3,
		ActiveSound = false,
		Icon = "rbxassetid://18854695275",
		Size = UDim2.new(1, 0, 1, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		UI.new "UIPadding" {
			PaddingTop = UI.Theme.PaddingHalf,
			PaddingBottom = UI.Theme.PaddingHalf,
			PaddingLeft = UI.Theme.PaddingHalf,
			PaddingRight = UI.Theme.PaddingHalf,
		},

		[UI.Event] = {
			Activated = function()
				UI.toggleState(filterMenu.Visible, "floating")
				local value = UI.peek(filterMenu.Visible)
				if value then
					UI.Sound.Hover03:Play()
				else
					UI.Sound.Hover01:Play()
				end
			end,
		},
	}

	filterMenu = UI.new "Menu" {
		Adornee = filterButton._instance,
		RightAlign = true,
		Size = UI.compute(function(use)
			local padding = use(UI.Theme.Padding).Offset
			return UDim2.fromOffset(256 + padding * 3, (24 + padding) * 3.5 + padding / 2)
		end),

		UI.new "UIPadding" {
			PaddingTop = UI.Theme.Padding,
			PaddingBottom = UI.Theme.Padding,
			PaddingLeft = UI.Theme.Padding,
			PaddingRight = UI.Theme.Padding,
		},
	}

	UI.edit(filterMenu._list, {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UI.Theme.Padding,
		Wraps = true,
	})

	for index, array in logTypes do
		local logType = array[1]
		UI.new "ListItem" {
			Parent = filterMenu._menu,
			LayoutOrder = index,
			Text = logType,
			ContentAutomaticSize = true,
			Size = UDim2.fromOffset(128, 24),

			UI.new "Checkbox" {
				Value = logTypeFilter[logType],

				[UI.Hook] = {
					Value = function(value)
						logTypeFilter[logType] = value
						scroller:refreshList()
					end,
				},
			},
		}
	end

	UI.new "Frame" {
		Parent = scroller,
		Name = "FilterInput",

		BackgroundTransparency = 1,
		Size = UI.compute(function(use)
			return UDim2.new(1, 0, 0, use(UI.Theme.FontSize) + use(UI.Theme.PaddingDouble).Offset)
		end),

		UI.new "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UI.Theme.Padding,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
		UI.edit(scroller._input, {
			UI.new "UIFlexItem" {
				FlexMode = Enum.UIFlexMode.Fill,
			},
		}),
		filterButton,
	}

	UI.edit(scroller._scroller, {
		UI.new "UIFlexItem" {
			FlexMode = Enum.UIFlexMode.Fill,
		},
	})

	scroller:filter(filterTest)

	return scroller
end

return Logs

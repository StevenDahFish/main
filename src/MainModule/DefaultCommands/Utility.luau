-- safe utilily commands for all players

return {
	{
		name = "about",
		aliases = { "help", "credit", "credits", "info", "?" },
		description = "Shows the about tab in a separate window.",
		args = {},
		envClient = function(_K)
			local window = _K.UI.new "Window" {
				Parent = _K.UI.LayerTopInset,
				Title = "Kohl's Admin About",
				Visible = false,
				_K.UI.new "UIPadding" {
					PaddingLeft = UDim.new(0, 1),
					PaddingRight = UDim.new(0, 1),
					PaddingTop = UDim.new(0, 1),
					PaddingBottom = UDim.new(0, 1),
				},
			}
			_K.UI.edit(window, {
				[_K.UI.Event.Property] = {
					Visible = function()
						if not window._instance.Visible and #_K.UI.Scope.dashboard then
							_K.UI.edit(_K.UI.Scope.dashboard.Tabs, {
								_K.UI.Scope.dashboard.About,
							})
						end
					end,
				},
			})
			return {
				window = window,
			}
		end,

		runClient = function(context)
			local visible = not context.env.window._instance.Visible
			context._K.UI.edit(context.env.window, {
				Visible = visible,
				if visible then context._K.UI.Scope.dashboard.About else nil,
			})
		end,
	},
	{
		name = "commands",
		aliases = { "cmds" },
		description = "Shows the commands in a separate window.",
		args = {},
		envClient = function(_K)
			local window = _K.UI.new "Window" {
				Parent = _K.UI.LayerTopInset,
				Title = "Kohl's Admin Commands",
				Visible = false,
				_K.UI.new "UIPadding" {
					PaddingLeft = UDim.new(0, 1),
					PaddingRight = UDim.new(0, 1),
					PaddingTop = UDim.new(0, 1),
					PaddingBottom = UDim.new(0, 1),
				},
			}
			_K.UI.edit(window, {
				[_K.UI.Event.Property] = {
					Visible = function()
						if not window._instance.Visible and #_K.UI.Scope.dashboard then
							_K.UI.edit(_K.UI.Scope.dashboard.Tabs, {
								_K.UI.Scope.dashboard.Commands,
							})
						end
					end,
				},
			})
			return {
				window = window,
			}
		end,

		runClient = function(context)
			local visible = not context.env.window._instance.Visible
			context._K.UI.edit(context.env.window, {
				Visible = visible,
				if visible then context._K.UI.Scope.dashboard.Commands else nil,
			})
		end,
	},
	{
		name = "settings",
		aliases = { "set" },
		description = "Shows the settings in a separate window.",
		args = {},
		envClient = function(_K)
			local window = _K.UI.new "Window" {
				Parent = _K.UI.LayerTopInset,
				Title = "Kohl's Admin Settings",
				Visible = false,
				_K.UI.new "UIPadding" {
					PaddingLeft = UDim.new(0, 1),
					PaddingRight = UDim.new(0, 1),
					PaddingTop = UDim.new(0, 1),
					PaddingBottom = UDim.new(0, 1),
				},
			}
			_K.UI.edit(window, {
				[_K.UI.Event.Property] = {
					Visible = function()
						if not window._instance.Visible and #_K.UI.Scope.dashboard then
							_K.UI.edit(_K.UI.Scope.dashboard.Tabs, {
								_K.UI.Scope.dashboard.Settings,
							})
						end
					end,
				},
			})
			return {
				window = window,
			}
		end,

		runClient = function(context)
			local visible = not context.env.window._instance.Visible
			context._K.UI.edit(context.env.window, {
				Visible = visible,
				if visible then context._K.UI.Scope.dashboard.Settings else nil,
			})
		end,
	},

	-- {
	-- 	name = "alias",
	-- 	aliases = {},
	-- 	description = "Creates a command alias out of a command and given arguments.",
	-- 	args = {
	-- 		{
	-- 			type = "string",
	-- 			name = "Alias name",
	-- 			description = "The name of the command alias.",
	-- 		},
	-- 		{
	-- 			type = "stringGreedy",
	-- 			name = "Command string",
	-- 			description = "The command string to alias.",
	-- 		},
	-- 	},

	-- 	runClient = function(context, alias: string, command: string)
	-- 		context._K.Registry.registerCommandAlias(context._K, alias, command)
	-- 	end,
	-- },
}

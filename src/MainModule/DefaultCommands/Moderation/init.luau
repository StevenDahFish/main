-- dangerous moderation commands, but not the most dangerous of commands

local Jail = require(script.Jail)
local teleportCharacter = require(script.teleportCharacter)

return {
	{
		name = "bans",
		aliases = {},
		description = "Shows the bans in a separate window.",
		args = {},
		envClient = function(_K)
			local window = _K.UI.new "Window" {
				Parent = _K.UI.LayerTopInset,
				Title = "Kohl's Admin Bans",
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
								_K.UI.Scope.dashboard.Bans,
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
				if visible then context._K.UI.Scope.dashboard.Bans else nil,
			})
		end,
	},
	{
		name = "members",
		aliases = { "admins", "roles" },
		description = "Shows the roled members in a separate window.",
		args = {},
		envClient = function(_K)
			local window = _K.UI.new "Window" {
				Parent = _K.UI.LayerTopInset,
				Title = "Kohl's Admin Members",
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
								_K.UI.Scope.dashboard.Members,
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
				if visible then context._K.UI.Scope.dashboard.Members else nil,
			})
		end,
	},

	{
		name = "ban",
		description = "Bans one or more player(s) for a certain duration.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to ban.",
				ignoreSelf = true,
				lowerRank = true,
			},
			{
				type = "timeSimple",
				name = "Duration",
				description = "The duration for the ban.\n -1  Forever\n  0  Session",
			},
			{
				type = "stringGreedy",
				name = "Reason",
				description = "The reason for the ban.",
				optional = true,
			},
		},

		run = function(context, players, duration: number?, reason: string?)
			-- if lacking administrator command group only allow session banning?
			-- need to somehow display only session bans in suggestions...
			-- TODO: only show lower rank players in the suggestions if defined in argDef
			if type(reason) == "string" then
				reason = string.sub(reason, 1, 400) -- banasync limit
			end
			local ids = table.create(#players)
			for _, player in players do
				context._K.Auth.userBan(player.UserId, reason, duration, context.from)
				player:Kick(reason)
			end
			if duration and duration ~= 0 then
				context._K.Util.Retry(function()
					context._K.Services.Players:BanAsync({
						ApplyToUniverse = true,
						UserIds = ids,
						PrivateReason = reason,
						Duration = duration,
					})
				end, 8, 4, 2)
			end
		end,
	},
	{
		name = "banid",
		description = "Bans one or more player(s) by userId.",
		args = {
			{
				type = "integers",
				name = "UserId(s)",
				description = "The userid(s) of the player(s) to ban.",
			},
			{
				type = "timeSimple",
				name = "Duration",
				description = "The duration for the ban.\n -1  Forever\n  0  Session",
				optional = true,
			},
			{
				type = "stringGreedy",
				name = "Reason",
				description = "The reason for the ban.",
				optional = true,
			},
		},

		run = function(context, userIds, duration: number?, reason: string?)
			-- if lacking administrator command group only allow session banning?
			-- need to somehow display only session bans in suggestions...
			-- TODO: only show lower rank players in the suggestions if defined in argDef
			if type(reason) == "string" then
				reason = string.sub(reason, 1, 400) -- banasync limit
			end
			print("banid", userIds, duration, reason)
			local rank = context._K.Auth.getRank(context.from)
			for _, userId in userIds do
				-- only ban if rank is lower haha
				if userId == context.from or rank <= context._K.Auth.getRank(userId) then
					print("rank no auth")
					continue
				end
				for _, player in context._K.Services.Players:GetPlayers() do
					if player.UserId == tonumber(userId) then
						player:Kick(reason or "Unspecified reason.")
					end
				end

				context._K.Auth.userBan(userId, reason, duration, context.from)
			end
			if duration and duration ~= 0 then
				context._K.Util.Retry(function()
					context._K.Services.Players:BanAsync({
						UserIds = userIds,
						PrivateReason = reason,
						Duration = duration,
						ApplyToUniverse = true,
					})
				end, 8, 4, 2)
			end
		end,
	},
	{
		name = "unban",
		description = "Unbans one or more player(s).",
		args = {
			{
				type = "bans",
				name = "Player(s)",
				description = "The player(s) to unban.",
			},
		},

		run = function(context, bans)
			local ids = table.create(#bans)
			-- TODO: check if authorized to actually unban, sessions vs persist, if persistCommands permission?!
			for i, userId in bans do
				context._K.Data.bans[userId] = nil
				context._K.Data.Cache.bans[userId] = context._K.Data.Store.REMOVE
				context._K.Remote.Ban:FireAllClients(userId)
				context._K.Data.pendingSaveMain = true
				table.insert(ids, tonumber(userId))
			end
			context._K.Services.Players:UnbanAsync({ UserIds = ids, ApplyToUniverse = true })
		end,
	},
	{
		name = "kick",
		description = "Kicks one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to kick.",
				ignoreSelf = true,
				lowerRank = true,
			},
			{
				type = "string",
				name = "Reason",
				description = "The reason for the kick.",
				optional = true,
			},
		},
		permissions = {
			kick = true,
		},
		run = function(context, players, reason: string?)
			for _, player in players do
				player:Kick(reason)
			end
		end,
	},
	{
		name = "mute",
		aliases = { "shh", "silence" },
		description = "Mutes one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to mute.",
				ignoreSelf = true,
				lowerRank = true,
			},
		},
		env = function(_K)
			local muted = {}
			_K.Util.Services.TextChatService.DescendantAdded:Connect(function(descendant)
				if descendant:IsA("TextSource") then
					if muted[descendant.UserId] then
						descendant.CanSend = false
					end
				end
			end)

			_K.Data.muted = muted
			return { muted = muted }
		end,
		run = function(context, players)
			for _, player in players do
				context._K.Remote.SetCore:FireClient(player, "ChatBarDisabled", true)
				context._K.Remote.SetCore:FireClient(
					player,
					"ChatMakeSystemMessage",
					{ Text = "You have been muted.", Color = Color3.new(1, 0, 0) }
				)
				context.env.muted[player.UserId] = true
				for _, descendant in context._K.Util.Services.TextChatService:GetDescendants() do
					if descendant:IsA("TextSource") and descendant.UserId == player.UserId and descendant.CanSend then
						descendant:SetAttribute("_KCouldSend", true)
						descendant.CanSend = false
					end
				end
			end
		end,
	},
	{
		name = "unmute",
		aliases = { "unshh", "unsilence" },
		description = "Unmutes one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to unmute.",
				ignoreSelf = true,
				lowerRank = true,
			},
		},

		run = function(context, players)
			for _, player in players do
				context._K.Remote.SetCore:FireClient(player, "ChatBarDisabled", false)
				context._K.Remote.SetCore:FireClient(
					player,
					"ChatMakeSystemMessage",
					{ Text = "You have been unmuted.", Color = Color3.new(0, 1, 0) }
				)
				context._K.Data.muted[player.UserId] = nil
				for _, descendant in context._K.Util.Services.TextChatService:GetDescendants() do
					if
						descendant:IsA("TextSource")
						and descendant.UserId == player.UserId
						and descendant:GetAttribute("_KCouldSend")
					then
						descendant:SetAttribute("_KCouldSend", nil)
						descendant.CanSend = true
					end
				end
			end
		end,
	},
	{
		name = "punish",
		aliases = {},
		description = "Punishes one or more player(s) to the void.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to punish.",
				shouldRequest = true,
			},
		},

		run = function(context, players)
			for _, player in players do
				if
					player.Character
					and not player.Character:GetAttribute("kPunish")
					and player.Character.PrimaryPart
					and player.Character.PrimaryPart:FindFirstChildOfClass("Attachment")
				then
					player.Character:SetAttribute("kPunish", player.Character:GetPivot())
					local force = Instance.new("VectorForce")
					force.Name = "kPunishForce"
					force.Force = Vector3.new(0, 9e9, 0)
					force.ApplyAtCenterOfMass = true
					force.RelativeTo = Enum.ActuatorRelativeTo.World
					force.Attachment0 = player.Character.PrimaryPart:FindFirstChildOfClass("Attachment")
					force.Parent = player.Character
				end
			end
		end,
	},
	{
		name = "unpunish",
		aliases = {},
		description = "Unpunishes one or more player(s) from the void.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to forgive.",
			},
		},

		run = function(context, players)
			for _, player in players do
				if player.Character and player.Character:GetAttribute("kPunish") then
					local force = player.Character:FindFirstChild("kPunishForce")
					if force then
						force:Destroy()
					end
					if player.Character.PrimaryPart then
						player.Character.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
					end
					player.Character:PivotTo(player.Character:GetAttribute("kPunish"))
					player.Character:SetAttribute("kPunish", nil)
				end
			end
		end,
	},
	{
		name = "breakjoints",
		aliases = { "break", "kill" },
		description = "Breaks the joints one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) whose joints to break.",
				lowerRank = true,
			},
		},
		run = function(context, players)
			for _, player in players do
				if player.Character then
					player.Character:BreakJoints()
				end
			end
		end,
	},
	{
		name = "hurt",
		aliases = { "damage" },
		description = "Damages one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to hurt.",
				shouldRequest = true,
			},
			{
				type = "number",
				name = "Damage",
				description = "The damage to deal to their health.",
			},
		},

		run = function(context, players, health)
			for _, player in players do
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:TakeDamage(health)
				end
			end
		end,
	},
	{
		name = "health",
		aliases = { "maxhealth" },
		description = "Changes the maximum health one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) whose health to change.",
			},
			{
				type = "number",
				name = "Max Health",
				description = "The new maximum health.",
			},
		},

		run = function(context, players, health)
			health = math.max(1, health)
			for _, player in players do
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.MaxHealth = health
					humanoid.Health = health
				end
			end
		end,
	},
	{
		name = "heal",
		description = "Heals one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to heal.",
			},
		},

		run = function(context, players)
			for _, player in players do
				local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.Health = humanoid.MaxHealth
				end
			end
		end,
	},
	{
		name = "immortal",
		aliases = { "god" },
		description = "Makes one or more player(s) invincible.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to make invincible.",
			},
		},

		run = function(context, players)
			for _, player in players do
				if not player.Character then
					continue
				end
				local ff = player.Character:FindFirstChildOfClass("ForceField")
				if ff then
					ff.Visible = false
				else
					Instance.new("ForceField", player.Character).Visible = false
				end
			end
		end,
	},
	{
		name = "forcefield",
		aliases = { "ff" },
		description = "Gives a ForceField to one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to protect.",
			},
		},

		run = function(context, players)
			for _, player in players do
				if not player.Character then
					continue
				end
				local ff = player.Character:FindFirstChildOfClass("ForceField")
				if ff then
					ff.Visible = true
				else
					Instance.new("ForceField", player.Character)
				end
			end
		end,
	},
	{
		name = "unforcefield",
		aliases = { "unff", "ungod", "mortal" },
		description = "Removes a ForceField from one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to remove a ForceField from.",
				shouldRequest = true,
			},
		},

		run = function(context, players)
			for _, player in players do
				if player.Character then
					local ff = player.Character:FindFirstChildOfClass("ForceField")
					if ff then
						ff:Destroy()
					end
				end
			end
		end,
	},
	{
		name = "invisible",
		aliases = { "inv" },
		description = "Makes one or more player(s) invisible.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to make invisible.",
			},
		},

		run = function(context, players)
			for _, player in players do
				if not player.Character then
					continue
				end
				for _, child in player.Character:GetDescendants() do
					if
						(child:IsA("BasePart") or child:IsA("Decal") or child:IsA("Texture"))
						and not child:GetAttribute("kTransparency")
					then
						child:SetAttribute("kTransparency", child.Transparency)
						child.Transparency = 1
					elseif
						(
							child:IsA("Light")
							or child:IsA("Beam")
							or child:IsA("Trail")
							or child:IsA("ParticleEmitter")
							or child:IsA("Fire")
							or child:IsA("Smoke")
							or child:IsA("Sparkles")
							or child:IsA("SurfaceGui")
						) and not child:GetAttribute("kEnabled")
					then
						child:SetAttribute("kEnabled", child.Enabled)
						child.Enabled = false
					end
				end
			end
		end,
	},
	{
		name = "visible",
		aliases = { "vis" },
		description = "Makes one or more player(s) visible.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to make visible.",
				shouldRequest = true,
			},
		},

		run = function(context, players)
			for _, player in players do
				if not player.Character then
					continue
				end
				for _, child in player.Character:GetDescendants() do
					local kTransparency = child:GetAttribute("kTransparency")
					local kEnabled = child:GetAttribute("kEnabled")
					if kTransparency then
						child:SetAttribute("kTransparency", nil)
						child.Transparency = kTransparency
					elseif kEnabled then
						child:SetAttribute("kEnabled", nil)
						child.Enabled = kEnabled
					end
				end
			end
		end,
	},

	{
		name = "freeze",
		aliases = { "anchor" },
		description = "Freezes one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to freeze.",
				shouldRequest = true,
			},
		},

		run = function(context, players)
			for _, player in players do
				if not player.Character or player.Character:FindFirstChild("kFreeze") then
					continue
				end
				for _, descendant in player.Character:GetDescendants() do
					if descendant:IsA("BasePart") then
						descendant.Anchored = true
					end
				end
				local orientation, size = player.Character:GetBoundingBox()
				local kFreeze = Instance.new("Part")
				kFreeze.Name = "kFreeze"
				kFreeze.Anchored = true
				kFreeze.CFrame = orientation
				kFreeze.Reflectance = 1
				kFreeze.Transparency = 0.3
				kFreeze.Size = size + Vector3.new(2, 2, 2)
				kFreeze.Color = Color3.fromHex("#8bf")
				kFreeze.Material = Enum.Material.Ice
				kFreeze.TopSurface = Enum.SurfaceType.Smooth
				kFreeze.BottomSurface = Enum.SurfaceType.Smooth
				kFreeze.Parent = player.Character
			end
		end,
	},
	{
		name = "thaw",
		aliases = { "unfreeze", "unanchor" },
		description = "Thaws one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to thaw.",
			},
		},

		run = function(context, players)
			for _, player in players do
				if not player.Character then
					continue
				end
				local kFreeze = player.Character:FindFirstChild("kFreeze")
				if kFreeze then
					kFreeze:Destroy()
				end
				for _, descendant in player.Character:GetDescendants() do
					if descendant:IsA("BasePart") then
						descendant.Anchored = false
					end
				end
			end
		end,
	},
	{
		name = "jail",
		aliases = {},
		description = "Jails one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to jail.",
				shouldRequest = true,
			},
		},

		run = function(context, players)
			for _, player in players do
				if Jail.Parts[player] then
					continue
				end
				Jail.Connections[player] = player.CharacterAdded:Connect(Jail.new)
				if player.Character then
					Jail.new(player.Character)
				end
			end
		end,
	},
	{
		name = "unjail",
		aliases = {},
		description = "Frees one or more player(s) from jail.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to release.",
			},
		},

		run = function(context, players)
			for _, player in players do
				if Jail.Connections[player] then
					Jail.Connections[player]:Disconnect()
					Jail.Connections[player] = nil
				end
				if Jail.Parts[player] then
					Jail.Parts[player]:Destroy()
					Jail.Parts[player] = nil
				end
			end
		end,
	},

	{
		name = "stun",
		aliases = { "disable" },
		description = "Stuns one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to stun.",
				shouldRequest = true,
			},
		},

		run = function(context, players)
			for _, player in players do
				if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
					player.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true
				end
			end
		end,
	},
	{
		name = "unstun",
		aliases = { "undisable", "enable" },
		description = "Removes stun from one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to remove the stun from.",
			},
		},

		run = function(context, players)
			for _, player in players do
				if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
					player.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
				end
			end
		end,
	},

	{
		name = "bring",
		aliases = {},
		description = "Teleports a player to you.",
		args = {
			{
				type = "player",
				name = "Player",
				description = "The player to bring.",
				shouldRequest = true,
			},
		},

		run = function(context, player)
			teleportCharacter(player.Character, context.fromPlayer.Character)
		end,
	},
	{
		name = "to",
		aliases = { "goto" },
		description = "Teleports to a player.",
		args = {
			{
				type = "player",
				name = "Player",
				description = "The player to teleport to.",
			},
		},

		run = function(context, player)
			teleportCharacter(context.fromPlayer.Character, player.Character)
		end,
	},
	{
		name = "tp",
		aliases = { "teleport" },
		description = "Teleports one or more player(s) to another player.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player to teleport.",
				shouldRequest = true,
			},
			{
				type = "player",
				name = "Player",
				description = "The player to teleport to.",
			},
		},

		run = function(context, players, target)
			for _, player in players do
				teleportCharacter(player.Character, target.Character)
			end
		end,
	},

	{
		name = "jump",
		description = "Makes one or more player(s) jump.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) who will jump.",
				shouldRequest = true,
			},
		},

		run = function(context, players)
			for _, player in players do
				if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
					player.Character:FindFirstChildOfClass("Humanoid").Jump = true
				end
			end
		end,
	},
	{
		name = "jumppower",
		description = "Changes the jump power of one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) whose jump power to change.",
			},
			{
				type = "number",
				name = "JumpPower",
				description = "The jump power to use.",
			},
		},

		run = function(context, players, jumpPower)
			for _, player in players do
				if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
					player.Character:FindFirstChildOfClass("Humanoid").JumpPower = jumpPower
				end
			end
		end,
	},
	{
		name = "sit",
		description = "Makes one or more player(s) sit.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) who will sit.",
				shouldRequest = true,
			},
		},

		run = function(context, players)
			for _, player in players do
				if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
					player.Character:FindFirstChildOfClass("Humanoid").Sit = true
				end
			end
		end,
	},
	{
		name = "unsit",
		description = "Makes one or more player(s) stop sitting.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) who will stop sitting.",
				shouldRequest = true,
			},
		},

		run = function(context, players)
			for _, player in players do
				if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
					player.Character:FindFirstChildOfClass("Humanoid").Sit = false
				end
			end
		end,
	},
	{
		name = "speed",
		aliases = { "walkspeed" },
		description = "Changes the walkspeed of one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) whose walkspeed to change.",
			},
			{
				type = "number",
				name = "Speed",
				description = "The walkspeed to use.",
			},
		},

		run = function(context, players, walkSpeed)
			for _, player in players do
				if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
					player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = walkSpeed
				end
			end
		end,
	},
	{
		name = "slopeangle",
		aliases = { "maxslopeangle" },
		description = "Changes the max slope angle of one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) whose max slope angle to change.",
			},
			{
				type = "number",
				name = "MaxSlopeAngle",
				description = "The max slope angle to use.",
			},
		},

		run = function(context, players, maxSlopeAngle)
			for _, player in players do
				if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
					player.Character:FindFirstChildOfClass("Humanoid").MaxSlopeAngle = math.clamp(maxSlopeAngle, 0, 89)
				end
			end
		end,
	},
	{
		name = "starterslopeangle",
		aliases = { "startermaxslopeangle" },
		description = "Changes the starting max slope angle of one or more player(s) when they spawn.",
		args = {
			{
				type = "number",
				name = "MaxSlopeAngle",
				description = "The max slope angle to use.",
			},
		},

		run = function(context, maxSlopeAngle)
			context.Util.Services.StarterPlayer.CharacterMaxSlopeAngle = math.clamp(maxSlopeAngle, 0, 89)
		end,
	},
	{
		name = "respawn",
		aliases = { "spawn" },
		description = "Respawns the character of one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to respawn.",
				shouldRequest = true,
			},
		},

		run = function(context, players)
			for _, player in players do
				player:LoadCharacter()
			end
		end,
	},
	{
		name = "refresh",
		aliases = { "re" },
		description = "Refreshes the character of one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to refresh.",
				shouldRequest = true,
			},
		},

		envClient = function(_K)
			local lastCameraCFrame
			_K.Remote.Refresh.OnClientEvent:Connect(function()
				if lastCameraCFrame then
					workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Wait()
					workspace.CurrentCamera.CFrame = lastCameraCFrame
				end
			end)

			_K.Services.Players.LocalPlayer.CharacterRemoving:Connect(function()
				lastCameraCFrame = workspace.CurrentCamera.CFrame
			end)
		end,

		run = function(context, players)
			for _, player in players do
				if player and player.Character then
					local old = player.Character:GetPivot()
					player:LoadCharacter()
					player.Character:PivotTo(old)
					context._K.Remote.Refresh:FireClient(player)
				end
			end
		end,
	},

	{
		name = "buy",
		aliases = { "purchase" },
		description = "Prompts a purchase for one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) to prompt.",
			},
			{
				type = "infoType",
				name = "Info Type",
				description = "The Enum.InfoType of the purchase.",
				optional = true,
			},
			{
				type = "integer",
				name = "Identifier",
				description = "The identifier of the item to purchase.",
			},
		},

		env = function(_K)
			local MarketplaceService = game:GetService("MarketplaceService")
			return {
				market = MarketplaceService,
				method = {
					[Enum.InfoType.Asset] = MarketplaceService.PromptPurchase,
					[Enum.InfoType.Bundle] = MarketplaceService.PromptBundlePurchase,
					[Enum.InfoType.GamePass] = MarketplaceService.PromptGamePassPurchase,
					[Enum.InfoType.Product] = MarketplaceService.PromptProductPurchase,
					[Enum.InfoType.Subscription] = MarketplaceService.PromptSubscriptionPurchase,
				},
			}
		end,

		run = function(context, players, infoType, id)
			if infoType == context.OPTIONAL then
				infoType = Enum.InfoType.Asset
			end
			local method = context.env.method[infoType]
			if not method then
				return
			end
			for _, player in players do
				pcall(method, context.env.market, player, id)
			end
		end,
	},
	{
		name = "change",
		aliases = {},
		description = "Changes a leaderstat of one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) whose leaderstat to change.",
			},
			{
				type = "string",
				name = "Stat",
				description = "The stat to change.",
			},
			{
				type = "stringGreedy",
				name = "Value",
				description = "The value of the stat.",
			},
		},
		run = function(context, players, stat, value)
			stat = string.lower(stat)
			for _, player in players do
				local leaderstats = player:FindFirstChild("leaderstats")
				if not leaderstats then
					continue
				end
				for _, child in leaderstats:GetChildren() do
					if string.find(string.lower(child.Name), stat) == 1 then
						if child:IsA("IntValue") or child:IsA("NumberValue") then
							child.Value = tonumber(value)
						elseif child:IsA("BoolValue") then
							local v = string.lower(value)
							child.Value = v ~= "false" and v ~= "nil" and v ~= "0" and v ~= "off"
						elseif child:IsA("StringValue") then
							child.Value = value
						end
					end
				end
			end
		end,
	},
	{
		name = "resetstats",
		description = "Resets the stats of one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) whose stats to reset.",
				shouldRequest = true,
			},
		},
		run = function(context, players)
			for _, player in players do
				local leaderstats = player:FindFirstChild("leaderstats")
				if not leaderstats then
					continue
				end
				for _, child in leaderstats:GetChildren() do
					if child:IsA("IntValue") or child:IsA("NumberValue") then
						child.Value = 0
					end
				end
			end
		end,
	},
	{
		name = "team",
		aliases = { "tm" },
		description = "Changes the team of one or more player(s).",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) whose teams to change.",
			},
			{
				type = "team",
				name = "Team",
				description = "The team to assign.",
			},
		},
		run = function(context, players, team)
			for _, player in players do
				player.Team = team
			end
		end,
	},
	{
		name = "randomizeteams",
		aliases = { "randomiseteams", "randomteams", "rteams", "rteam", "rt" },
		description = "Randomizes the team of one or more player(s) from a list of teams.",
		args = {
			{
				type = "players",
				name = "Player(s)",
				description = "The player(s) whose teams to randomize.",
			},
			{
				type = "teams",
				name = "Random Teams",
				description = "The teams to randomly assign.",
				optional = true,
			},
		},
		run = function(context, players, teams)
			if teams == context.OPTIONAL then
				teams = context._K.Services.Teams:GetTeams()
			end
			local randomSort = {}
			for _, player in players do
				table.insert(randomSort, math.ceil(math.random(#randomSort + 1)), player)
			end
			for i, player in randomSort do
				player.Team = teams[((i - 1) % #teams) + 1]
			end
		end,
	},
}

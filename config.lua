Config = {
  -- Discord Bot Configuration
  botToken = "YOUR_BOT_TOKEN",              -- NEVER SHARE THIS TOKEN WITH ANYONE!
  guildId = "YOUR_GUILD_ID",                -- Your Discord server's Guild ID
  endpoint = "https://discord.com/api/v10", -- Discord API endpoint (leave as default)

  startupDelay = 2500,                      -- Delay before syncing existing players (milliseconds)

  -- Role Configuration
  -- IMPORTANT: Role priority is determined by ORDER in this table!
  -- Roles listed first have HIGHER priority than roles listed later.
  -- This means if a user has multiple configured roles, they'll get the FIRST one found.
  --
  -- Example: If a user has both "superadmin" and "admin" roles,
  -- they will be assigned "superadmin" because it's listed first.
  roles = {
    { id = "1303790663913050177", name = "superadmin" }, -- Highest priority
    { id = "1361721918708908184", name = "user" },       -- Permission reset role
    { id = "1361725818371309879", name = "admin" },      -- Standard admin

    -- Add more roles here as needed:
    -- { id = "ROLE_ID_HERE", name = "moderator" },
  },

  -- The settings below are advanced settings and should not be changed unless you know what you are doing.

  -- Debug Settings
  debugMode = false,     -- Enable detailed debug logging (shows per-player messages)
  logPlayerJoins = true, -- Log when players join and get roles assigned

  -- Rate Limiting & Queue Settings
  apiCooldown = 1000,         -- Minimum time between Discord API calls (milliseconds)
  queueProcessDelay = 100,    -- Delay between processing queue items (milliseconds)
  rateLimitRetryDelay = 5000, -- Default retry delay when rate limited (milliseconds)

  -- Bulk Operation Settings
  bulkSyncDelay = 1000,       -- Delay between bulk operations during startup (milliseconds)
  bulkSyncBatchSize = 5,      -- Number of players to process before applying delay
  manualRefreshDelay = 1500,  -- Delay during manual refresh command (milliseconds)
  manualRefreshBatchSize = 3, -- Number of players to process before delay in manual refresh

  -- Monitoring Settings
  queueMonitorInterval = 30000, -- How often to log queue status in debug mode (milliseconds)

  -- Fallback Settings
  defaultRole = "user",   -- Default role if no Discord roles match
  fallbackOnError = true, -- Assign default role on API errors instead of leaving unchanged
}

-- Validation function for the configuration
---@return boolean
function Config.validate()
  local errors = {}

  if not Config.botToken or Config.botToken == "YOUR_BOT_TOKEN" then
    table.insert(errors, "Bot token is not configured")
  end

  if not Config.guildId or Config.guildId == "YOUR_GUILD_ID" then
    table.insert(errors, "Guild ID is not configured")
  end

  if not Config.roles or #Config.roles == 0 then
    table.insert(errors, "No roles configured")
  else
    for i, role in ipairs(Config.roles) do
      if not role.id or not role.name then
        table.insert(errors, ("Role %d is missing id or name"):format(i))
      end
    end
  end

  if #errors > 0 then
    print("^1[Discord Permission Sync] Configuration Errors:^0")
    for _, error in ipairs(errors) do
      print(("^1  - %s^0"):format(error))
    end
    return false
  end

  return true
end

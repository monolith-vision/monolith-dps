local requestQueue = {}
local isProcessingQueue = false
local lastApiCall = 0

local function processQueue()
  if isProcessingQueue or #requestQueue == 0 then
    return
  end

  isProcessingQueue = true

  Citizen.CreateThread(function()
    while #requestQueue > 0 do
      local currentTime = GetGameTimer()
      if currentTime - lastApiCall < Config.apiCooldown then
        Wait(Config.apiCooldown - (currentTime - lastApiCall))
      end

      local request = table.remove(requestQueue, 1)
      if request then
        request.execute()
        lastApiCall = GetGameTimer()

        if Config.debugMode then
          print(("^7[Discord Permission Sync] DEBUG: Processed queue item, %d remaining^0"):format(#requestQueue))
        end
      end

      Wait(Config.queueProcessDelay or 100)
    end

    isProcessingQueue = false
  end)
end

---@param discordId string
---@param callback function
local function queueRequest(discordId, callback)
  table.insert(requestQueue, {
    discordId = discordId,
    execute = function()
      fetchDiscordRolesInternal(discordId, callback)
    end
  })

  if Config.debugMode then
    print(("^7[Discord Permission Sync] DEBUG: Queued request for %s, queue size: %d^0"):format(discordId, #requestQueue))
  end

  processQueue()
end

---@param discordId string
---@param callback function
function fetchDiscordRolesInternal(discordId, callback)
  PerformHttpRequest(
    ("%s/guilds/%s/members/%s"):format(Config.endpoint, Config.guildId, discordId),
    function(errorCode, resultData, headers)
      if errorCode == 200 then
        local success, data = pcall(json.decode, resultData)
        if not success then
          if Config.debugMode then
            print(("^1[Discord Permission Sync] ERROR: Failed to parse JSON response for user %s^0"):format(discordId))
          end
          callback(nil, "JSON parse error")
          return
        end

        if not data or not data.roles then
          if Config.debugMode then
            print(("^3[Discord Permission Sync] WARNING: No roles found for user %s^0"):format(discordId))
          end
          callback({}, nil)
          return
        end

        local roles = {}
        for _, role in ipairs(data.roles) do
          if type(role) == "string" then
            table.insert(roles, role)
          end
        end

        callback(roles, nil)
      elseif errorCode == 404 then
        if Config.debugMode then
          print(("^3[Discord Permission Sync] WARNING: User %s not found in Discord guild^0"):format(discordId))
        end
        callback(nil, "User not in guild")
      elseif errorCode == 403 then
        print("^1[Discord Permission Sync] ERROR: Bot lacks permissions to access guild member data^0")
        callback(nil, "Insufficient bot permissions")
      elseif errorCode == 429 then
        local retryAfter = Config.rateLimitRetryDelay or 5000
        if headers and headers["Retry-After"] then
          retryAfter = tonumber(headers["Retry-After"]) * 1000 -- Convert to milliseconds
        end

        print(("^3[Discord Permission Sync] WARNING: Rate limited, retrying after %dms^0"):format(retryAfter))

        SetTimeout(retryAfter, function()
          queueRequest(discordId, callback)
        end)
      else
        print(("^1[Discord Permission Sync] ERROR: HTTP %d when fetching roles for user %s^0"):format(errorCode,
          discordId))
        callback(nil, "HTTP error " .. errorCode)
      end
    end,
    "GET",
    nil,
    {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bot " .. Config.botToken
    }
  )
end

---@param discordId string
---@return table<string> | nil, string | nil error message
local function fetchDiscordRoles(discordId)
  local p = promise.new()

  queueRequest(discordId, function(roles, error)
    p:resolve({ roles, error })
  end)

  local result = Citizen.Await(p)
  return result[1], result[2]
end

---@param roles table<string>
---@return string
local function getHighestRole(roles)
  if not roles or #roles == 0 then
    return Config.defaultRole or "user"
  end

  local userRolesSet = {}
  for _, role in ipairs(roles) do
    userRolesSet[role] = true
  end

  for _, roleConfig in ipairs(Config.roles) do
    if roleConfig.id and userRolesSet[roleConfig.id] then
      return roleConfig.name or Config.defaultRole or "user"
    end
  end

  return Config.defaultRole or "user"
end

---@param source number
---@param xPlayer table
local function onPlayerLoaded(source, xPlayer)
  if not Config.validate() then
    print("^1[Discord Permission Sync] ERROR: Invalid configuration, skipping permission sync^0")
    return
  end

  local discord = GetPlayerIdentifierByType(source, 'discord')
  if not discord then
    if Config.debugMode then
      print(("^3[Discord Permission Sync] WARNING: Player %s has no Discord identifier^0"):format(source))
    end
    return xPlayer.setGroup(Config.defaultRole or "user")
  end

  local discordId = string.gsub(discord, 'discord:', '')
  if not discordId or discordId == "" then
    if Config.debugMode then
      print(("^3[Discord Permission Sync] WARNING: Invalid Discord ID for player %s^0"):format(source))
    end
    return xPlayer.setGroup(Config.defaultRole or "user")
  end

  local roles, error = fetchDiscordRoles(discordId)
  if error then
    if Config.debugMode then
      print(("^1[Discord Permission Sync] ERROR: Failed to fetch roles for player %s (%s): %s^0"):format(source,
        discordId, error))
    end
    if Config.fallbackOnError then
      return xPlayer.setGroup(Config.defaultRole or "user")
    end
    return
  end

  if not roles then
    if Config.debugMode then
      print(("^3[Discord Permission Sync] WARNING: No valid roles for player %s (%s)^0"):format(source, discordId))
    end
    return xPlayer.setGroup(Config.defaultRole or "user")
  end

  local highestRole = getHighestRole(roles)

  if Config.debugMode then
    if highestRole ~= (Config.defaultRole or "user") then
      print(("^2[Discord Permission Sync] SUCCESS: Player %s (%s) assigned role '%s'^0"):format(source,
        GetPlayerName(source), highestRole))
    else
      print(("^7[Discord Permission Sync] INFO: Player %s (%s) assigned default role '%s'^0"):format(source,
        GetPlayerName(source), highestRole))
    end
  end

  xPlayer.setGroup(highestRole)
end

AddEventHandler("esx:playerLoaded", onPlayerLoaded)

Citizen.CreateThread(function()
  local startupDelay = Config.startupDelay or 2500
  Wait(startupDelay)

  if not Config.validate() then
    return
  end

  print("^2[Discord Permission Sync] INFO: Syncing permissions for existing players^0")

  local playerCount = 0
  for _, xPlayer in pairs(ESX.GetPlayers()) do
    local xPlayerObj = ESX.GetPlayerFromId(xPlayer)
    if xPlayerObj then
      onPlayerLoaded(xPlayer, xPlayerObj)
      playerCount = playerCount + 1

      if playerCount % Config.bulkSyncBatchSize == 0 then
        Wait(Config.bulkSyncDelay)
      end
    end
  end

  print(("^2[Discord Permission Sync] INFO: Completed sync for %d players^0"):format(playerCount))
end)

RegisterCommand("refreshpermissions", function(source, args, rawCommand)
  if source ~= 0 then
    return
  end

  if not Config.validate() then
    return
  end

  print("^2[Discord Permission Sync] INFO: Manually refreshing permissions for all players^0")

  requestQueue = {}

  local playerCount = 0
  for _, xPlayer in pairs(ESX.GetPlayers()) do
    local xPlayerObj = ESX.GetPlayerFromId(xPlayer)
    if xPlayerObj then
      onPlayerLoaded(xPlayer, xPlayerObj)
      playerCount = playerCount + 1

      if playerCount % Config.manualRefreshBatchSize == 0 then
        Wait(Config.manualRefreshDelay)
      end
    end
  end

  print(("^2[Discord Permission Sync] SUCCESS: Refreshed permissions for %d players^0"):format(playerCount))
end, false)

if Config.debugMode then
  Citizen.CreateThread(function()
    while true do
      Wait(Config.queueMonitorInterval or 30000)

      if #requestQueue > 0 then
        print(("^7[Discord Permission Sync] DEBUG: Queue status - %d pending requests^0"):format(#requestQueue))
      end
    end
  end)
end

print("^2[Discord Permission Sync] Resource loaded successfully^0")

# Discord Permission Sync for FiveM

Monolith DPS is an advanced integration between discord roles and permissions on your FiveM Server with the ESX Framework.

## 🌟 Features

- **🔄 Automatic Role Sync**: Seamlessly syncs Discord roles to ESX groups
- **📋 Smart Queue System**: Handles rate limits with intelligent request queuing
- **🛡️ Rate Limit Protection**: Built-in safeguards against Discord API rate limiting
- **🔧 Highly Configurable**: Extensive configuration options for fine-tuning
- **🐛 Debug Mode**: Detailed logging for troubleshooting (production-friendly)
- **⚡ Performance Optimized**: Efficient bulk operations with configurable batching
- **🚨 Error Resilience**: Comprehensive error handling with fallback options
- **🎯 Priority System**: Role hierarchy based on configuration order

## 📋 Requirements

- **FiveM Server** with ESX framework
- **Discord Bot** with proper permissions
- **Discord Guild** where roles are managed

## 🚀 Installation

1. **Download** or clone this repository
2. **Extract** the files to your `resources` folder
3. **Add** `ensure monolith-dps` to your `server.cfg`
4. **Configure** the `config.lua` file (see Configuration section)
5. **Restart** your server

## ⚙️ Configuration

### Basic Setup

Edit `config.lua` and configure the following essential settings:

```lua
Config = {
  -- Discord Bot Configuration
  botToken = "YOUR_BOT_TOKEN",              -- Your Discord bot token
  guildId = "YOUR_GUILD_ID",                -- Your Discord server ID

  -- Role Configuration (ORDER MATTERS!)
  roles = {
    { id = "ROLE_ID_1", name = "superadmin" }, -- Highest priority
    { id = "ROLE_ID_2", name = "admin" },      -- Medium priority
    { id = "ROLE_ID_3", name = "moderator" },  -- Lower priority
    -- Add more roles as needed
  },
}
```

### 🤖 Discord Bot Setup

1. **Create a Discord Application**:

   - Go to [Discord Developer Portal](https://discord.com/developers/applications)
   - Click "New Application" and give it a name
   - Go to "Bot" section and click "Add Bot"

2. **Get Your Bot Token**:

   - In the Bot section, click "Copy" under Token
   - Paste this token in `config.lua` as `botToken`

3. **Set Bot Permissions**:

   - Your bot needs `View Server Members` permission
   - Invite the bot to your Discord server with this permission

4. **Get Guild ID**:

   - Enable Developer Mode in Discord
   - Right-click your server → "Copy Server ID"
   - Paste this in `config.lua` as `guildId`

5. **Get Role IDs**:
   - Right-click any role in your Discord server
   - Click "Copy Role ID"
   - Add roles to the `roles` table in `config.lua`

### 🎯 Role Priority System

**IMPORTANT**: Role priority is determined by the ORDER in the `roles` table!

```lua
roles = {
  { id = "123456789", name = "superadmin" }, -- 🥇 HIGHEST PRIORITY
  { id = "987654321", name = "admin" },      -- 🥈 Medium priority
  { id = "456789123", name = "user" },       -- 🥉 Lowest priority
}
```

If a player has multiple configured Discord roles, they will receive the **first matching role** from the list.

### 🔧 Advanced Configuration

```lua
Config = {
  -- Debug Settings
  debugMode = false,                        -- Enable detailed logging

  -- Rate Limiting & Queue Settings
  apiCooldown = 1000,                       -- Delay between API calls (ms)
  queueProcessDelay = 100,                  -- Queue processing delay (ms)
  rateLimitRetryDelay = 5000,               -- Rate limit retry delay (ms)

  -- Bulk Operation Settings
  bulkSyncBatchSize = 5,                    -- Players per batch
  bulkSyncDelay = 1000,                     -- Delay between batches (ms)

  -- Fallback Settings
  defaultRole = "user",                     -- Default role assignment
  fallbackOnError = true,                   -- Use default role on errors
}
```

## 🎮 Commands

### Console Commands (Server Console Only)

```bash
refreshpermissions
```

- **Description**: Manually refresh permissions for all online players
- **Usage**: Type in server console to force a permission sync
- **Note**: Clears the request queue and processes all players fresh

## 🔍 Debug Mode

Enable debug mode for detailed logging:

```lua
debugMode = true
```

**Debug Mode Shows**:

- ✅ Individual player role assignments
- 📋 Queue status and processing details
- 🔍 API request/response information
- ⚠️ Detailed error messages

**Production Mode** (debugMode = false):

- ✅ Clean console output
- ✅ Only essential error messages
- ✅ No per-player spam

## 🛠️ Troubleshooting

### Common Issues

#### ❌ "Bot token not configured"

**Solution**: Make sure you've replaced `YOUR_BOT_TOKEN` with your actual Discord bot token.

#### ❌ "Bot lacks permissions"

**Solution**: Ensure your Discord bot has `View Server Members` permission in your Discord server.

#### ❌ "User not found in Discord guild"

**Solution**: Player isn't in your Discord server or has their Discord account disconnected from FiveM.

#### ❌ "Rate limit exceeded"

**Solution**: The queue system will automatically handle this. If persistent, increase `apiCooldown` value.

### Debug Steps

1. **Enable Debug Mode**:

   ```lua
   debugMode = true
   ```

2. **Check Console Output**: Look for colored error messages:

   - 🔴 **Red**: Critical errors
   - 🟡 **Yellow**: Warnings
   - 🟢 **Green**: Success messages
   - ⚪ **Gray**: Debug information

3. **Verify Configuration**: Restart the resource and check for configuration errors

4. **Test Manual Refresh**: Use `refreshpermissions` command in console

### Performance Tuning

If you experience issues with many players:

```lua
-- Reduce batch sizes
bulkSyncBatchSize = 3,
manualRefreshBatchSize = 2,

-- Increase delays
apiCooldown = 2000,
bulkSyncDelay = 2000,
```

## 🔒 Security Notes

- **NEVER SHARE** your Discord bot token
- Store your bot token securely
- Use minimal required Discord permissions

## 🔄 Update Notes

### From Basic Version

- ✅ Caching removed for real-time accuracy
- ✅ Queue system added for rate limit handling
- ✅ Debug mode added for production-friendly logging
- ✅ All settings moved to config file
- ✅ Enhanced error handling and resilience

## 🤝 Support

If you encounter issues:

1. **Check this README** for common solutions
2. **Enable debug mode** and check console output
3. **Verify your Discord bot setup** and permissions
4. **Test with the manual refresh command**

## 📄 License

This project is open source. Feel free to modify and distribute according to your needs.

---

**Made with ❤️ for the FiveM community**

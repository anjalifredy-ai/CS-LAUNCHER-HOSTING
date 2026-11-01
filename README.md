# CS LAUNCHER HOSTING

**Host Minecraft Servers from your Android Device**

A powerful, free, and fully featured Minecraft server hosting app for Android, inspired by Anvil MC and similar tools.

🔗 **Repository**: https://github.com/anjalifredy-ai/CS-LAUNCHER-HOSTING

## Features

- 🚀 **Easy One-Click Setup** - Create and start servers in seconds
- 🌐 **No Port Forwarding** - Free public tunnels using bore.pub
- ❤️ **100% Free & Unlimited** - No limits, no subscriptions
- 📊 **Remote Dashboard** - Manage everything from your phone
- 🌐 **Free Public Domain** - Shareable addresses for your friends
- 💻 **Full Server Customization**
  - Server Name, Description, Icon
  - Software: Paper, NeoForge, Fabric, OptiFine, Vanilla, Spigot, Purpur and more
  - Version selection for all major Minecraft versions
  - Online Mode On/Off
  - Allow Skins / Capes
  - View Distance, Simulation Distance, Max Players
  - Difficulty, Gamemode, PVP, Hardcore
  - Command blocks, Spawn protection, and many more settings
- 📋 **Built-in Console & Logging** - Real-time live output with colored logs (ERROR, WARN, INFO)
- 🔧 **Direct Plugin Management** - Browse, search and install plugins directly from the app (coming soon)
- 💾 **RAM Monitoring** - See real-time server RAM usage
- 👥 **Player Management** - Kick, ban, whitelist, OP players easily
- ⚡ **Java Selection** - Choose Java version for better performance on larger servers
- 🔄 **Multi-version Support** - Friends can join with different client versions
- 📱 **Vertical Orientation** - Optimized for portrait mobile use

## Current Progress

✅ Flutter project scaffolded  
✅ Dark theme + green accents (matches reference screenshots)  
✅ Home screen with server cards, status, RAM bar, Start/Stop  
✅ Server detail screen with live Console, Players, Info tabs  
✅ Full Settings screen (software, version, view distance, online mode, skins, PVP, hardcore, etc.)  
✅ Create Server flow  
✅ Simulated start/stop + console logs + bore.pub style public address  
✅ RAM usage simulation  

🚧 Next: Real Java process management, actual bore.pub tunnel client, plugin browser, server icon picker, file manager for worlds/plugins.

## How to Run (Development)

```bash
# Clone
git clone https://github.com/anjalifredy-ai/CS-LAUNCHER-HOSTING.git
cd CS-LAUNCHER-HOSTING

# Get dependencies
flutter pub get

# Run on connected Android device / emulator
flutter run
```

> Requires Flutter SDK 3.16+ and Android SDK.

## How it Works (Vision)

1. Install the app
2. Create a new server (choose software + version)
3. Customize settings, icon, description
4. Start the server → app launches Java + Minecraft jar on device
5. Automatically opens free public tunnel via **bore.pub**
6. Share the address with friends and play!

The server runs entirely on **your device** (not cloud). Keep the app open or use battery optimization exceptions for long sessions.

## Tech Stack

- **Frontend**: Flutter (Material 3, dark theme)
- **State**: Provider
- **Server Runtime** (planned): Embedded Java + official Paper/Fabric/etc jars
- **Tunneling**: bore.pub (free, no account)
- **Plugins** (planned): Modrinth / Hangar APIs

## Project Structure

```
lib/
├── main.dart
├── theme/app_theme.dart
├── models/server_model.dart
├── providers/server_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── server_detail_screen.dart
│   ├── server_settings_screen.dart
│   └── create_server_screen.dart
```

## Contributing

Pull requests are welcome! For major changes, please open an issue first.

## License

MIT License - see [LICENSE](LICENSE) file.

---

Made with ❤️ for the Minecraft community  
**CS LAUNCHER HOSTING**

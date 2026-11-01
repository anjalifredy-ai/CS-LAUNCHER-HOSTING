# Real Hosting & Tunnel Architecture

This document describes how **real** Minecraft server hosting + free public tunnel will work in CS LAUNCHER HOSTING.

## Current Status

Right now the app uses a high-quality **simulation**:
- Fake start/stop with realistic console logs
- Simulated RAM usage
- Simulated `*.bore.pub` public addresses
- Full command simulation

The UI and flows are production-ready. The next step is wiring real processes.

---

## 1. Real Server Process (Android)

### Requirements
- Embedded Java runtime (e.g. via `jre` from Adoptium / Liberica or Termux-style)
- Ability to run `java -Xmx... -jar server.jar nogui` as a background process
- Capture stdout/stderr for the live console
- Send stdin for commands

### Approach
1. **MethodChannel / FFI** from Flutter → Kotlin/Java native code
2. Download official Paper / Fabric / etc. jars from their APIs into app private storage
3. Generate `server.properties`, `eula.txt`, etc.
4. Start process with `ProcessBuilder` or Android `Runtime.exec`
5. Read output stream in a background thread and push lines to Flutter via EventChannel
6. Use Android **Foreground Service** so the server survives when the app is backgrounded

### Battery & Performance
- Request battery optimization exemption
- Use a sticky foreground notification while server is running
- Recommend user keeps phone charging + Wi-Fi

---

## 2. Free Public Tunnel (bore.pub)

[bore.pub](https://bore.pub) is a free TCP tunnel service (no account needed).

### How it works
```bash
bore local 25565 --to bore.pub
```
This exposes local port 25565 and prints something like:
```
listening at bore.pub:XXXXX
```
Players connect to `bore.pub:XXXXX`.

### Integration plan
1. Bundle or download the `bore` binary (or use a pure-Dart/Go mobile port)
2. When user presses **START**:
   - Start Minecraft server process on local port (default 25565)
   - Wait until server finishes loading ("Done")
   - Start `bore local 25565 --to bore.pub`
   - Parse the public address from bore stdout
   - Show it in the UI as the join address
3. On **STOP**: kill both the Java process and the bore process

### Alternatives
- playit.gg
- ngrok (needs account)
- Cloudflare Tunnel
- Custom FRP / own VPS reverse proxy

We prefer **bore.pub** because it is free and account-less.

---

## 3. File Structure on Device

```
/data/data/com.cslauncher.hosting/files/servers/
  <server-id>/
    server.jar
    server.properties
    eula.txt
    world/
    plugins/
    mods/          (for Fabric/NeoForge)
    logs/
    ops.json
    whitelist.json
```

---

## 4. Implementation Roadmap

| Step | Task | Status |
|------|------|--------|
| 1 | UI + simulation (current) | ✅ Done |
| 2 | Download server jars (Paper API etc.) | Planned |
| 3 | Native process management (Kotlin) | Planned |
| 4 | Foreground service + notification | Planned |
| 5 | bore.pub client integration | Planned |
| 6 | Real console stdin/stdout | Planned |
| 7 | File browser for worlds/plugins | Planned |
| 8 | Battery optimization guide | Planned |

---

## 5. Notes for Contributors

- Never run the server as root.
- Always accept EULA programmatically (`eula=true`).
- Prefer Paper for best performance on mobile.
- For Bedrock: PowerNukkitX or Geyser+Floodgate on a Java server.
- Test on mid-range devices (4–6 GB RAM) first.

---

**CS LAUNCHER HOSTING** — Host real Minecraft servers from your Android device.

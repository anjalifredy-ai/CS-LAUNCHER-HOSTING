# CS LAUNCHER ↔ MineServe parity

Goal: phone pe asli Minecraft server, zero root, free public tunnel.

## MineServe stack

| Layer | MineServe | CS LAUNCHER |
|-------|-----------|-------------|
| UI | Jetpack Compose | Flutter |
| Java | PRoot + OpenJDK 8/17/21/25 | Phase B: download JRE / PRoot |
| Server jar | Paper/Purpur/Fabric… | Phase A: Paper API download |
| Console | JNI PTY | EventChannel logs |
| Tunnel | native bore + playit | native bore auto-download ✅ |
| Background | ForegroundService | Phase C |

## Phase A (now) — jar + tunnel wiring

1. Create server dir under `files/servers/<id>/`
2. Download Paper build from `https://api.papermc.io`
3. Write `eula.txt` = true
4. Start tunnel (bore.pub)
5. Start `java -jar` when JRE path known

## Phase B — JRE without root

Options (pick one):

1. **Bundled / downloaded JRE** (Liberica, Adoptium) extracted to `files/runtime/jdk-21`
2. **PRoot + rootfs** (MineServe style) — heavier, best compatibility

## Phase C — production

- Foreground service + wake lock
- Playit.gg agent optional
- Battery optimization prompt

## API: Paper download

```
GET https://api.papermc.io/v2/projects/paper
GET https://api.papermc.io/v2/projects/paper/versions/{ver}/builds
GET .../builds/{n}/downloads/paper-{ver}-{n}.jar
```

## User experience

1. Create server (Paper 1.21.1)
2. First START → download jar (+ JRE if needed) → bore tunnel → online
3. Copy public address → friends join

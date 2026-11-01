# CS Tunnel — Apna Free Public Tunnel

Goal: Feather / bore.pub jaisa system, lekin **hamara control**, users ke liye **free**.

Server tere phone/PC pe chalega. Players public address se join karenge. Port-forward ki zaroorat nahi.

---

## Architecture (simple)

```
[Player Minecraft] 
       |
       | TCP 25565-style
       v
[CS Tunnel Server]  <-- VPS with public IP (bore server / FRP)
       |
       | reverse tunnel
       v
[CS LAUNCHER app] --> local Minecraft server (Java/Bedrock)
```

- **Tunnel server** = ek (ya kai) VPS jahan `bore server` (ya baad me custom) chalta hai
- **Tunnel client** = app / phone pe chalta hai, local 25565 ko VPS se jodta hai
- Players ko milta hai: `play.cs-launcher.xyz:3xxxx` ya `eu.cs-tunnel.net:3xxxx`

---

## Phase 1 — Bore self-host (1 din me free start)

### 1. VPS lo

Options:
- **Oracle Cloud Always Free** (ARM / AMD) — try free tier
- Hetzner / Contabo / any cheap VPS (~$3–5/mo)
- Pehle test: koi bhi Ubuntu 22.04 VPS

Open ports:
- `7835` TCP (bore control)
- `10000–50000` TCP (public tunnel ports) — ya jo range tum set karo

### 2. Bore server install

```bash
# On VPS
curl -L https://github.com/ekzhang/bore/releases/download/v0.5.2/bore-v0.5.2-x86_64-unknown-linux-musl.tar.gz | tar xz
sudo mv bore /usr/local/bin/

# Optional secret so random logins na kholen tunnels
export BORE_SECRET="cs-launcher-change-me-strong"

# Run (foreground test)
bore server --secret "$BORE_SECRET"

# Or systemd service (production)
sudo tee /etc/systemd/system/bore.service << 'EOF'
[Unit]
Description=CS Tunnel (bore server)
After=network.target

[Service]
ExecStart=/usr/local/bin/bore server --secret cs-launcher-change-me-strong --min-port 30000 --max-port 40000
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now bore
```

### 3. Domain (optional but premium feel)

- Domain kharido ya free DNS (DuckDNS / FreeDNS)
- `A` record: `tunnel.cs-launcher.xyz` → VPS IP
- Players dekhenge: `tunnel.cs-launcher.xyz:31234`

### 4. Client side (phone / app)

Abhi simulation; native me:

```bash
bore local 25565 --to tunnel.cs-launcher.xyz --secret cs-launcher-change-me-strong
```

Output:
```
listening at tunnel.cs-launcher.xyz:31234
```

Yahi address CS LAUNCHER UI me copy-button ke saath dikhega.

---

## Phase 2 — App integration (CS LAUNCHER)

Settings / Create Server me:

| Field | Example |
|-------|--------|
| Tunnel provider | CS Tunnel (official) / bore.pub / Custom |
| Tunnel host | `tunnel.cs-launcher.xyz` |
| Secret | (app me secure store, user ko mat dikhao production me) |
| Region | EU / US / AS (baad me multi-VPS) |

Start server flow:
1. Local MC server start (native Java)
2. Tunnel client start → host:port milta hai
3. UI me public address set

---

## Phase 3 — Feather-lite (baad me)

- Multi-region VPS (EU, US, Asia)
- Nice names: `smp-42.play.cs-launcher.xyz` (wildcard DNS + small router)
- Rate limits + ban list (abuse)
- Dashboard: active tunnels, bandwidth
- Minecraft-only port policy

Is stage pe custom Go/Rust proxy bhi likh sakte ho; shuruaat bore se best hai.

---

## Cost reality (free rakhne ke liye)

| Item | Free path |
|------|-----------|
| Tunnel software | bore (MIT) — free |
| VPS | Oracle free tier / friends' spare VPS / cheap $3 VPS |
| Domain | Optional; IP:port bhi kaam karta hai |
| Users | Free |

Jab traffic badhe:
- Extra VPS add karo
- Optional paid "custom subdomain" se cost cover

---

## Security checklist

- [ ] Bore `--secret` hamesha use karo
- [ ] Firewall: sirf zaroori ports
- [ ] Secret app me hardcode mat rakho (remote config / build flavor)
- [ ] Abuse: max tunnels per IP, ban list
- [ ] Minecraft EULA users ke server pe unki zimmedari

---

## Quick test (bina app ke)

**VPS:**
```bash
bore server --secret test123 --min-port 30000 --max-port 31000
```

**Local (PC pe MC server 25565 pe):**
```bash
bore local 25565 --to YOUR_VPS_IP --secret test123
```

Friends: `YOUR_VPS_IP:3xxxx` se join.

---

## CS LAUNCHER default plan

1. **Now:** UI me provider = `bore.pub` | `CS Tunnel` | `Custom host`
2. **Day 1:** Ek VPS + bore + domain/IP
3. **App native:** bore binary ya Rust FFI client
4. **Brand:** addresses `*.cs-launcher.play` style (phase 3)

**Bottom line:** Haan, apna free tunnel bana sakte ho. Bore self-host = fastest path. Feather jaisa polish baad me layers se aayega.

— CS LAUNCHER HOSTING team

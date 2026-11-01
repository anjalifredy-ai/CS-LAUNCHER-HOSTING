# bore.pub connect (CS LAUNCHER)

App native code ab **asli bore** chala sakti hai.

## Flow

1. START server
2. `NativeHostService.startTunnel(toHost: bore.pub)`
3. Android runs: `bore local 25565 --to bore.pub`
4. UI gets `bore.pub:PORT`
5. STOP closes tunnel

Agar binary nahi → simulation address (pehle jaisa).

## Binary kahan

Path:

```text
/data/data/<package>/files/tools/bore
```

### Termux se

```bash
# Termux me bore download karke:
cp ~/bore /sdcard/Download/bore
```

Phir PC/adb se:

```bash
adb push bore /data/data/com.cslauncher.hosting/files/tools/bore
adb shell chmod 755 /data/data/com.cslauncher.hosting/files/tools/bore
```

Package name apne app ka use karo.

## Download bore (phone ARM)

https://github.com/ekzhang/bore/releases  
`bore-*-aarch64-unknown-linux-musl.tar.gz`

## Code

```dart
final r = await NativeHostService.startTunnel(
  serverId: id,
  localPort: 25565,
  toHost: 'bore.pub',
);
// r['publicAddress']
```

## Yaad rakho

- Tunnel tab join hoga jab **kuch 25565 pe server sun raha ho**
- Abhi Java server process alag (JRE) — tunnel code ready hai
- Tab tak Termux + bore bhi chal sakta hai saath me

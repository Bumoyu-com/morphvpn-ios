# @morphvpn/capacitor-wireguard

Capacitor plugin for WireGuard VPN on iOS.

## Install

```bash
npm install @morphvpn/capacitor-wireguard
npx cap sync
```

## API

### connect(options)

Connect to WireGuard VPN.

```typescript
import { WireGuard } from '@morphvpn/capacitor-wireguard';

const config = `[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY
PresharedKey = PRESHARED_KEY
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 0
Endpoint = SERVER_IP:51820`;

await WireGuard.connect({
  config: config,
  tunnelName: 'MyVPN'
});
```

### disconnect()

Disconnect from VPN.

```typescript
await WireGuard.disconnect();
```

### getStatus()

Get current connection status.

```typescript
const status = await WireGuard.getStatus();
console.log(status.status); // 'connected', 'disconnected', etc.
```

### saveConfig(options)

Save a VPN configuration.

```typescript
await WireGuard.saveConfig({
  config: config,
  tunnelName: 'MyVPN'
});
```

### deleteConfig(options)

Delete a saved configuration.

```typescript
await WireGuard.deleteConfig({
  tunnelName: 'MyVPN'
});
```

### listTunnels()

List all saved tunnel configurations.

```typescript
const result = await WireGuard.listTunnels();
console.log(result.tunnels); // ['MyVPN', 'WorkVPN', ...]
```

## iOS Setup

### 1. Add Network Extension Capability

In Xcode, add the Network Extension capability to your app:

1. Select your project in Xcode
2. Select your app target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Network Extensions"
6. Check "Packet Tunnel"

### 2. Add Entitlements

The plugin will automatically add the required entitlements, but ensure your `App.entitlements` includes:

```xml
<key>com.apple.developer.networking.networkextension</key>
<array>
    <string>packet-tunnel-provider</string>
</array>
```

### 3. Create Network Extension Target

You need to create a Network Extension target to handle the actual VPN connection:

1. In Xcode, File → New → Target
2. Select "Network Extension"
3. Choose "Packet Tunnel Provider"
4. Name it `WireGuardExtension`
5. Bundle ID should be: `YOUR_APP_BUNDLE_ID.WireGuardExtension`

### 4. Update Bundle Identifier

In `WireGuardPlugin.swift`, update the provider bundle identifier:

```swift
providerProtocol.providerBundleIdentifier = "com.yourapp.WireGuardExtension"
```

## Platform Support

- ✅ iOS
- ❌ Android (not yet implemented)
- ❌ Web (not supported)

## License

MIT

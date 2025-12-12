# MorphProtocol Integration Testing Guide

## Testing Checklist

### Phase 1: Pre-Integration Verification ✅

- [x] MorphProtocol Swift files created
  - [x] `MorphEncryptor.swift`
  - [x] `MorphObfuscator.swift`
  - [x] `MorphUDPClient.swift`
- [x] Documentation created
  - [x] Architecture guide
  - [x] Implementation guide
  - [x] Quick start guide

### Phase 2: Xcode Integration (User Action Required)

- [ ] **Add MorphProtocol files to Xcode project**
  1. Open `ios/App/App.xcworkspace` in Xcode
  2. Right-click on `WireGuardExtension` folder
  3. Select "Add Files to App..."
  4. Navigate to `ios/App/WireGuardExtension/MorphProtocol/`
  5. Select all 3 Swift files
  6. **IMPORTANT**: Check "Copy items if needed" and select `WireGuardExtension` target
  7. Click "Add"

- [ ] **Verify file targets**
  1. Select each MorphProtocol Swift file in Xcode
  2. Open File Inspector (right panel)
  3. Under "Target Membership", ensure only `WireGuardExtension` is checked

- [ ] **Build WireGuardExtension target**
  1. Select `WireGuardExtension` scheme in Xcode
  2. Product → Build (⌘B)
  3. Verify no compilation errors

### Phase 3: Code Integration

#### 3.1 PacketTunnelProvider Modification

- [ ] **Open `PacketTunnelProvider.swift`**
- [ ] **Add MorphUDPClient property** (after existing properties):
```swift
private var morphClient: MorphUDPClient?
```

- [ ] **Modify `startTunnel` method** to initialize MorphProtocol:
```swift
override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
    // Check if MorphProtocol should be used
    if let useMorph = options?["useMorphProtocol"] as? Bool, useMorph {
        let encryptionKey = options?["morphEncryptionKey"] as? String ?? ""
        let serverHost = options?["morphServerHost"] as? String ?? ""
        let serverPort = options?["morphServerPort"] as? Int ?? 0
        let layerCount = options?["morphLayerCount"] as? Int ?? 3
        let paddingLength = options?["morphPaddingLength"] as? Int ?? 8
        
        wg_log(.info, message: "Initializing MorphProtocol: \(serverHost):\(serverPort)")
        
        do {
            morphClient = try MorphUDPClient(
                encryptionKey: encryptionKey,
                serverHost: serverHost,
                serverPort: serverPort,
                layerCount: layerCount,
                paddingLength: paddingLength
            )
            
            morphClient?.onStateChange = { state in
                wg_log(.info, message: "MorphProtocol state: \(state)")
            }
            
            morphClient?.onError = { error in
                wg_log(.error, message: "MorphProtocol error: \(error)")
            }
            
            morphClient?.start()
            wg_log(.info, message: "MorphProtocol started successfully")
        } catch {
            wg_log(.error, message: "Failed to initialize MorphProtocol: \(error)")
        }
    }
    
    // Continue with existing WireGuard initialization...
    // [Keep existing code here]
}
```

- [ ] **Modify `stopTunnel` method** to cleanup MorphProtocol:
```swift
override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
    // Stop MorphProtocol if running
    if let morphClient = morphClient {
        wg_log(.info, message: "Stopping MorphProtocol")
        morphClient.stop()
        self.morphClient = nil
    }
    
    // Continue with existing WireGuard cleanup...
    // [Keep existing code here]
}
```

#### 3.2 WireGuardPlugin Modification

- [ ] **Open `ios/App/App/Plugins/WireGuardPlugin.swift`**
- [ ] **Update `connect` method** to accept MorphProtocol parameters:
```swift
@objc func connect(_ call: CAPPluginCall) {
    guard let config = call.getString("config") else {
        call.reject("Configuration is required")
        return
    }
    
    // Parse MorphProtocol options
    let useMorphProtocol = call.getBool("useMorphProtocol") ?? false
    let morphEncryptionKey = call.getString("morphEncryptionKey") ?? ""
    let morphServerHost = call.getString("morphServerHost") ?? ""
    let morphServerPort = call.getInt("morphServerPort") ?? 0
    let morphLayerCount = call.getInt("morphLayerCount") ?? 3
    let morphPaddingLength = call.getInt("morphPaddingLength") ?? 8
    
    // Create options dictionary
    var options: [String: NSObject] = [:]
    if useMorphProtocol {
        options["useMorphProtocol"] = NSNumber(value: true)
        options["morphEncryptionKey"] = morphEncryptionKey as NSObject
        options["morphServerHost"] = morphServerHost as NSObject
        options["morphServerPort"] = NSNumber(value: morphServerPort)
        options["morphLayerCount"] = NSNumber(value: morphLayerCount)
        options["morphPaddingLength"] = NSNumber(value: morphPaddingLength)
    }
    
    // Start tunnel with options
    // [Continue with existing tunnel start code, passing options]
}
```

#### 3.3 TypeScript Definitions

- [ ] **Create/Update `src/plugins/wireguard.ts`**:
```typescript
export interface WireGuardConfig {
  config: string;
  useMorphProtocol?: boolean;
  morphEncryptionKey?: string;
  morphServerHost?: string;
  morphServerPort?: number;
  morphLayerCount?: number;
  morphPaddingLength?: number;
}

export interface WireGuardPlugin {
  connect(config: WireGuardConfig): Promise<void>;
  disconnect(): Promise<void>;
  getStatus(): Promise<{ connected: boolean }>;
}
```

### Phase 4: Generate Test Keys

- [ ] **Generate encryption key** using Node.js:
```bash
node -e "const crypto = require('crypto'); const key = crypto.randomBytes(32).toString('base64'); const iv = crypto.randomBytes(12).toString('base64'); console.log(key + ':' + iv);"
```

- [ ] **Save the output** (format: `base64key:base64iv`)
- [ ] **Example output**: `dGVzdGtleXRlc3RrZXl0ZXN0a2V5dGVzdGtleQ==:dGVzdGl2dGVzdGl2`

### Phase 5: React Component Testing

- [ ] **Update VPN connection component** to use MorphProtocol:
```typescript
import { Plugins } from '@capacitor/core';
const { WireGuard } = Plugins;

async function connectWithMorph() {
  try {
    await WireGuard.connect({
      config: wireguardConfig,
      useMorphProtocol: true,
      morphEncryptionKey: 'YOUR_KEY_FROM_STEP_4',
      morphServerHost: 'morph.example.com',
      morphServerPort: 51821,
      morphLayerCount: 3,
      morphPaddingLength: 8
    });
    console.log('Connected with MorphProtocol');
  } catch (error) {
    console.error('Connection failed:', error);
  }
}
```

### Phase 6: Build and Deploy

- [ ] **Build the app**:
```bash
npm run build
npx cap sync ios
```

- [ ] **Open in Xcode**:
```bash
npx cap open ios
```

- [ ] **Select a real iOS device** (VPN extensions don't work in simulator)
- [ ] **Build and run** (⌘R)

### Phase 7: Runtime Testing

#### 7.1 Basic Connectivity Test

- [ ] **Launch app on device**
- [ ] **Attempt connection WITHOUT MorphProtocol**:
  - Should connect normally to WireGuard
  - Verify VPN icon appears in status bar
  - Test internet connectivity
  - Disconnect

- [ ] **Attempt connection WITH MorphProtocol**:
  - Enable MorphProtocol in UI
  - Provide encryption key and server details
  - Attempt connection
  - Check for VPN icon in status bar

#### 7.2 Log Verification

- [ ] **Open Console.app on Mac**
- [ ] **Connect iOS device**
- [ ] **Filter logs**: Search for "MorphProtocol" or "WireGuard"
- [ ] **Expected log messages**:
  ```
  Initializing MorphProtocol: morph.example.com:51821
  MorphProtocol state: ready
  MorphProtocol started successfully
  ```

- [ ] **Check for errors**:
  - Encryption key parsing errors
  - UDP connection failures
  - State transition issues

#### 7.3 Network Traffic Analysis

- [ ] **Install Wireshark on Mac**
- [ ] **Enable iOS device packet capture**:
  ```bash
  # Create remote virtual interface
  rvictl -s [DEVICE_UDID]
  ```

- [ ] **Capture traffic on rvi0 interface**
- [ ] **Filter for UDP traffic** to MorphProtocol server port
- [ ] **Verify obfuscation**:
  - Traffic should NOT show WireGuard handshake patterns
  - Packets should appear random/encrypted
  - No plaintext protocol identifiers

### Phase 8: Error Scenarios

- [ ] **Test invalid encryption key**:
  - Provide malformed key
  - Expected: Error logged, connection fails gracefully

- [ ] **Test unreachable server**:
  - Provide non-existent server address
  - Expected: Timeout, error logged

- [ ] **Test missing parameters**:
  - Omit encryption key
  - Expected: Error logged, falls back to standard WireGuard

- [ ] **Test connection interruption**:
  - Connect successfully
  - Disable WiFi/cellular
  - Re-enable network
  - Expected: Automatic reconnection

## Known Limitations

### Current Implementation Status

✅ **Implemented**:
- MorphProtocol encryption (AES-GCM)
- Multi-layer obfuscation (XOR + bit rotation)
- Random padding
- UDP client with state management
- Integration hooks in PacketTunnelProvider

⚠️ **Partially Implemented**:
- Traffic interception (requires additional packet forwarding logic)
- Automatic failover to standard WireGuard

❌ **Not Yet Implemented**:
- Full packet capture from WireGuard tunnel
- Bidirectional traffic forwarding through MorphProtocol
- Performance optimization for high-throughput scenarios
- Server-side MorphProtocol implementation (separate project)

### iOS VPN Limitations

1. **Single VPN Connection**: iOS allows only one active VPN connection
2. **Network Extension Sandbox**: Limited access to system networking
3. **Background Execution**: VPN extensions have strict resource limits
4. **Debugging**: Cannot debug Network Extensions in simulator

## Troubleshooting

### Build Errors

**Error**: `Cannot find 'MorphUDPClient' in scope`
- **Solution**: Verify MorphProtocol files are added to WireGuardExtension target

**Error**: `Module 'CryptoKit' not found`
- **Solution**: Ensure deployment target is iOS 13.0+ in Xcode project settings

**Error**: `Use of unresolved identifier 'wg_log'`
- **Solution**: Import WireGuardKit logging in PacketTunnelProvider

### Runtime Errors

**Error**: `Encryption key format invalid`
- **Solution**: Verify key format is `base64key:base64iv` with correct lengths

**Error**: `UDP connection failed`
- **Solution**: Check server address, port, and firewall rules

**Error**: `VPN connection established but no internet`
- **Solution**: Verify MorphProtocol server is forwarding traffic to WireGuard endpoint

### Performance Issues

**Symptom**: Slow connection speeds
- **Cause**: Multiple encryption layers (MorphProtocol + WireGuard)
- **Solution**: Reduce `morphLayerCount` to 1-2, decrease `morphPaddingLength`

**Symptom**: High battery drain
- **Cause**: Continuous UDP keep-alive packets
- **Solution**: Implement adaptive keep-alive intervals based on network conditions

## Next Steps

After completing this testing checklist:

1. **Document test results** in a new file `MORPHPROTOCOL_TEST_RESULTS.md`
2. **Report any issues** with detailed logs and reproduction steps
3. **Optimize configuration** based on performance metrics
4. **Implement server-side** MorphProtocol endpoint (if not already done)
5. **Consider advanced features**:
   - Traffic pattern analysis resistance
   - Dynamic obfuscation parameter adjustment
   - Multi-hop routing through MorphProtocol relays

## Success Criteria

The integration is considered successful when:

- ✅ App builds without errors
- ✅ VPN connects with MorphProtocol enabled
- ✅ Internet traffic flows through the connection
- ✅ Logs show MorphProtocol initialization and state changes
- ✅ Network capture shows obfuscated traffic (no WireGuard patterns)
- ✅ Connection remains stable for 5+ minutes
- ✅ Reconnection works after network interruption

## Support

For issues or questions:
1. Check logs in Console.app for detailed error messages
2. Review the implementation guides in this repository
3. Verify server-side MorphProtocol is running and accessible
4. Test standard WireGuard connection (without MorphProtocol) to isolate issues

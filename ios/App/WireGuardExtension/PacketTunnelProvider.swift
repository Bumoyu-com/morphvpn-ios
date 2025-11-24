import NetworkExtension
import WireGuardKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var adapter: WireGuardAdapter?
    
    override func startTunnel(options: [String : NSObject]?, 
                            completionHandler: @escaping (Error?) -> Void) {
        
        guard let protocolConfiguration = self.protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfiguration = protocolConfiguration.providerConfiguration,
              let configString = providerConfiguration["wg_config"] as? String else {
            completionHandler(NSError(domain: "WireGuard", code: 1))
            return
        }
        
        guard let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: configString) else {
            completionHandler(NSError(domain: "WireGuard", code: 2))
            return
        }
        
        adapter = WireGuardAdapter(with: self) { logLevel, message in
            print("WireGuard [\(logLevel)]: \(message)")
        }
        
        adapter?.start(tunnelConfiguration: tunnelConfiguration) { error in
            completionHandler(error)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, 
                           completionHandler: @escaping () -> Void) {
        adapter?.stop { _ in
            self.adapter = nil
            completionHandler()
        }
    }
}

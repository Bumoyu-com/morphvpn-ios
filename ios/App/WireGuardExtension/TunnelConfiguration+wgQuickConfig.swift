import WireGuardKit

extension TunnelConfiguration {
    convenience init?(fromWgQuickConfig wgQuickConfig: String, called name: String? = nil) {
        do {
            try self.init(fromWgQuickConfig: wgQuickConfig)
        } catch {
            return nil
        }
    }
}

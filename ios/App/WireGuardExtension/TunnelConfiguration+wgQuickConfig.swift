import Foundation
import WireGuardKit

extension TunnelConfiguration {
    convenience init(fromWgQuickConfig wgQuickConfig: String, called name: String? = nil) throws {
        try self.init(fromWgQuickConfig: wgQuickConfig)
    }
}

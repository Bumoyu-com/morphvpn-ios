import Foundation

extension String {
    func splitToArray(separator: String = "\n") -> [String] {
        return self.components(separatedBy: separator).filter { !$0.isEmpty }
    }
}

import Foundation

/// The four swing events detected in v1. Order matters for phase-relative
/// alignment when the review UI syncs the user's skeleton against the
/// synthetic reference skeleton.
public enum SwingPhase: String, CaseIterable, Codable, Hashable {
    case address
    case topOfBackswing
    case impact
    case finish
}

/// Frame indices for each detected phase, in the source video's frame numbering.
public struct SwingPhaseTiming: Codable {
    public let address: Int
    public let topOfBackswing: Int
    public let impact: Int
    public let finish: Int

    public init(address: Int, topOfBackswing: Int, impact: Int, finish: Int) {
        self.address = address
        self.topOfBackswing = topOfBackswing
        self.impact = impact
        self.finish = finish
    }

    public func frameIndex(for phase: SwingPhase) -> Int {
        switch phase {
        case .address: return address
        case .topOfBackswing: return topOfBackswing
        case .impact: return impact
        case .finish: return finish
        }
    }
}

import Foundation

/// Club category being analyzed. Only "Full Swing" (driver/irons) is
/// supported in v1 — wedges/short game/putting are explicitly out of scope.
public enum ClubCategory: String, CaseIterable, Codable, Hashable {
    case fullSwing = "Full Swing"
}

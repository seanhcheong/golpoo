import Foundation

/// One-time local profile field used to scale spine-angle expectations
/// and the synthetic reference skeleton to the user's proportions.
public struct UserProfile: Codable, Equatable {
    public let heightInInches: Double

    public init(heightInInches: Double) {
        self.heightInInches = heightInInches
    }
}

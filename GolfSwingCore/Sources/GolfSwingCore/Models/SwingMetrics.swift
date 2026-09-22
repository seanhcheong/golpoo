import Foundation

/// The v1 core metrics computed from one analyzed swing.
public struct SwingMetrics: Codable, Equatable {
    /// Backswing duration divided by downswing duration (e.g. 3.0 == "3:1 tempo").
    public let tempoRatio: Double
    /// Hip-shoulder separation angle at top of backswing, in degrees.
    public let xFactorAtTop: Double
    /// Spine angle from vertical at address, in degrees.
    public let spineAngleAddress: Double
    /// Spine angle from vertical at impact, in degrees.
    public let spineAngleImpact: Double
    /// Shoulder rotation at top of backswing relative to address, in degrees.
    public let shoulderRotationAtTop: Double
    /// Hip rotation at top of backswing relative to address, in degrees.
    public let hipRotationAtTop: Double

    /// "Loss of posture": how much the spine angle changed between address and impact.
    public var spineAngleDeviation: Double {
        abs(spineAngleImpact - spineAngleAddress)
    }

    public init(
        tempoRatio: Double,
        xFactorAtTop: Double,
        spineAngleAddress: Double,
        spineAngleImpact: Double,
        shoulderRotationAtTop: Double,
        hipRotationAtTop: Double
    ) {
        self.tempoRatio = tempoRatio
        self.xFactorAtTop = xFactorAtTop
        self.spineAngleAddress = spineAngleAddress
        self.spineAngleImpact = spineAngleImpact
        self.shoulderRotationAtTop = shoulderRotationAtTop
        self.hipRotationAtTop = hipRotationAtTop
    }
}

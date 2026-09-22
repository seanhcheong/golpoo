import Foundation

public enum SwingMetricsError: Error {
    case missingLandmarks(SwingPhase)
    case invalidTiming
}

/// Computes the v1 metric set from pose frames and detected phase timing.
public struct SwingMetricsCalculator {
    public init() {}

    public func calculate(frames: [PoseFrame], phases: SwingPhaseTiming) throws -> SwingMetrics {
        guard phases.address < phases.topOfBackswing,
              phases.topOfBackswing < phases.impact,
              phases.impact <= phases.finish,
              phases.finish < frames.count else {
            throw SwingMetricsError.invalidTiming
        }

        let addressFrame = frames[phases.address]
        let topFrame = frames[phases.topOfBackswing]
        let impactFrame = frames[phases.impact]

        let backswingDuration = topFrame.timestamp - addressFrame.timestamp
        let downswingDuration = impactFrame.timestamp - topFrame.timestamp
        guard downswingDuration > 0 else { throw SwingMetricsError.invalidTiming }
        let tempoRatio = backswingDuration / downswingDuration

        guard let addressShoulderAngle = addressFrame.shoulderLineAngle,
              let addressHipAngle = addressFrame.hipLineAngle else {
            throw SwingMetricsError.missingLandmarks(.address)
        }
        guard let topShoulderAngle = topFrame.shoulderLineAngle,
              let topHipAngle = topFrame.hipLineAngle else {
            throw SwingMetricsError.missingLandmarks(.topOfBackswing)
        }
        guard let addressSpineAngle = addressFrame.spineAngle else {
            throw SwingMetricsError.missingLandmarks(.address)
        }
        guard let impactSpineAngle = impactFrame.spineAngle else {
            throw SwingMetricsError.missingLandmarks(.impact)
        }

        let shoulderRotation = abs(AngleMath.angleDifference(topShoulderAngle, addressShoulderAngle))
        let hipRotation = abs(AngleMath.angleDifference(topHipAngle, addressHipAngle))
        let xFactor = abs(shoulderRotation - hipRotation)

        return SwingMetrics(
            tempoRatio: tempoRatio,
            xFactorAtTop: xFactor,
            spineAngleAddress: addressSpineAngle,
            spineAngleImpact: impactSpineAngle,
            shoulderRotationAtTop: shoulderRotation,
            hipRotationAtTop: hipRotation
        )
    }
}

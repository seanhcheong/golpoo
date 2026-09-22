import XCTest
@testable import GolfSwingCore

final class SwingMetricsCalculatorTests: XCTestCase {
    private func lm(_ x: Double, _ y: Double, _ z: Double) -> PoseLandmark {
        PoseLandmark(x: x, y: y, z: z, visibility: 1.0)
    }

    /// Builds a tiny 5-frame swing with hand-chosen landmark coordinates
    /// whose expected angles are exact (0/45/90 degree triangles and two
    /// tan()-derived spine tilts), so the assertions below can be checked
    /// by hand rather than re-deriving the calculator's own math.
    private func makeSwing() -> (frames: [PoseFrame], phases: SwingPhaseTiming) {
        // Address (frame 0): shoulders/hips square (0 deg), spine tilted 30 deg from vertical.
        let addressShoulderMidX = 0.7309401076758503 // 0.5 + 0.4*tan(30deg)
        let address = PoseFrame(
            frameIndex: 0,
            timestamp: 0.0,
            landmarks: [
                .leftShoulder: lm(addressShoulderMidX - 0.1, 0.5, 0.0),
                .rightShoulder: lm(addressShoulderMidX + 0.1, 0.5, 0.0),
                .leftHip: lm(0.42, 0.9, 0.0),
                .rightHip: lm(0.58, 0.9, 0.0)
            ]
        )

        // Top of backswing (frame 2): shoulders rotated 90 deg, hips 45 deg -> X-factor 45 deg.
        let top = PoseFrame(
            frameIndex: 2,
            timestamp: 0.75,
            landmarks: [
                .leftShoulder: lm(0.5, 0.4, -0.1),
                .rightShoulder: lm(0.5, 0.4, 0.1),
                .leftHip: lm(0.42, 0.8, -0.08),
                .rightHip: lm(0.58, 0.8, 0.08)
            ]
        )

        // Impact (frame 4): spine re-tilted to 25 deg from vertical (5 deg loss of posture from address).
        let impactShoulderMidX = 0.6865230632619994 // 0.5 + 0.4*tan(25deg)
        let impact = PoseFrame(
            frameIndex: 4,
            timestamp: 1.0,
            landmarks: [
                .leftShoulder: lm(impactShoulderMidX - 0.1, 0.5, 0.0),
                .rightShoulder: lm(impactShoulderMidX + 0.1, 0.5, 0.0),
                .leftHip: lm(0.42, 0.9, 0.0),
                .rightHip: lm(0.58, 0.9, 0.0)
            ]
        )

        let filler1 = PoseFrame(frameIndex: 1, timestamp: 0.375, landmarks: [:])
        let filler3 = PoseFrame(frameIndex: 3, timestamp: 0.9, landmarks: [:])

        let frames = [address, filler1, top, filler3, impact]
        let phases = SwingPhaseTiming(address: 0, topOfBackswing: 2, impact: 4, finish: 4)
        return (frames, phases)
    }

    func testCalculatesExpectedMetrics() throws {
        let (frames, phases) = makeSwing()
        let metrics = try SwingMetricsCalculator().calculate(frames: frames, phases: phases)

        XCTAssertEqual(metrics.tempoRatio, 3.0, accuracy: 1e-9)
        XCTAssertEqual(metrics.shoulderRotationAtTop, 90, accuracy: 1e-6)
        XCTAssertEqual(metrics.hipRotationAtTop, 45, accuracy: 1e-6)
        XCTAssertEqual(metrics.xFactorAtTop, 45, accuracy: 1e-6)
        XCTAssertEqual(metrics.spineAngleAddress, 30, accuracy: 1e-4)
        XCTAssertEqual(metrics.spineAngleImpact, 25, accuracy: 1e-4)
        XCTAssertEqual(metrics.spineAngleDeviation, 5, accuracy: 1e-3)
    }

    func testThrowsOnInvalidTiming() {
        let (frames, _) = makeSwing()
        let badPhases = SwingPhaseTiming(address: 2, topOfBackswing: 0, impact: 4, finish: 4)
        XCTAssertThrowsError(try SwingMetricsCalculator().calculate(frames: frames, phases: badPhases))
    }
}

import XCTest
@testable import GolfSwingCore

final class SwingPhaseDetectorTests: XCTestCase {
    /// Builds a synthetic swing as a piecewise-linear wrist-height (y)
    /// trace: still at address, rising through the backswing, still at
    /// the top, falling fast through downswing/impact, rising again
    /// through follow-through, then still at the finish.
    private func buildSyntheticSwingFrames() -> [PoseFrame] {
        let fps = 120.0
        let dt = 1.0 / fps

        // (frameCount, startY, endY)
        let segments: [(Int, Double, Double)] = [
            (10, 0.60, 0.60), // address, still
            (25, 0.60, 0.25), // backswing, hands rising (y decreasing)
            (4, 0.25, 0.25),  // top, still
            (8, 0.25, 0.62),  // downswing/impact, hands dropping fast
            (20, 0.62, 0.22), // follow-through, hands rising again
            (10, 0.22, 0.22)  // finish, still
        ]

        var ys: [Double] = []
        for (count, startY, endY) in segments {
            for i in 0..<count {
                let t = count > 1 ? Double(i) / Double(count - 1) : 0
                ys.append(startY + (endY - startY) * t)
            }
        }

        return ys.enumerated().map { index, y in
            PoseFrame(
                frameIndex: index,
                timestamp: Double(index) * dt,
                landmarks: [
                    .leftWrist: PoseLandmark(x: 0.5, y: y, z: 0.0, visibility: 1.0),
                    .rightWrist: PoseLandmark(x: 0.5, y: y, z: 0.0, visibility: 1.0)
                ]
            )
        }
    }

    func testDetectsPlausiblePhaseOrdering() throws {
        let frames = buildSyntheticSwingFrames()
        let detector = SwingPhaseDetector()
        let phases = try XCTUnwrap(detector.detectPhases(in: frames))

        // Segment boundaries (frame indices): address 0..<10, backswing
        // 10..<35, top 35..<39, downswing 39..<47, follow-through
        // 47..<67, finish 67..<77. Smoothing shifts detected boundaries
        // by a few frames, so these bands are intentionally generous.
        XCTAssertTrue((0...10).contains(phases.address), "address: \(phases.address)")
        XCTAssertTrue((20...45).contains(phases.topOfBackswing), "top: \(phases.topOfBackswing)")
        XCTAssertTrue((35...60).contains(phases.impact), "impact: \(phases.impact)")
        XCTAssertTrue((55...76).contains(phases.finish), "finish: \(phases.finish)")

        XCTAssertLessThan(phases.address, phases.topOfBackswing)
        XCTAssertLessThan(phases.topOfBackswing, phases.impact)
        XCTAssertLessThanOrEqual(phases.impact, phases.finish)
    }

    func testReturnsNilForTooFewFrames() {
        let frames = Array(buildSyntheticSwingFrames().prefix(5))
        XCTAssertNil(SwingPhaseDetector().detectPhases(in: frames))
    }
}

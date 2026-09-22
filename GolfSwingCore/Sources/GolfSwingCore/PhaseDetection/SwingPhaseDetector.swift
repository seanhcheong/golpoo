import Foundation

/// Heuristic swing-phase detection based on wrist vertical velocity.
///
/// v1 simplification: this is the velocity/position-threshold fallback
/// called out in the project spec, not a learned model (e.g. a SwingNet-style
/// network trained against GolfDB-style event labels). It should be revisited
/// once there's a labeled dataset to train/validate a proper phase-detection
/// model — see the GolfDB/SwingNet reference architecture in the README.
public struct SwingPhaseDetector {
    private let stillnessVelocityThreshold: Double
    private let minStillFrames: Int
    private let smoothingWindow: Int
    private let minVisibility: Double

    public init(
        stillnessVelocityThreshold: Double = 0.15,
        minStillFrames: Int = 3,
        smoothingWindow: Int = 5,
        minVisibility: Double = 0.3
    ) {
        self.stillnessVelocityThreshold = stillnessVelocityThreshold
        self.minStillFrames = minStillFrames
        self.smoothingWindow = smoothingWindow
        self.minVisibility = minVisibility
    }

    /// Detects address / top-of-backswing / impact / finish frame indices.
    /// Returns nil if there aren't enough usable frames to detect a swing.
    public func detectPhases(in frames: [PoseFrame]) -> SwingPhaseTiming? {
        guard frames.count >= 8 else { return nil }

        guard let wristY = interpolatedWristHeights(frames) else { return nil }
        let smoothed = movingAverage(wristY, window: smoothingWindow)
        let velocity = frameVelocities(smoothed, timestamps: frames.map { $0.timestamp })

        guard let addressIndex = findStillnessEnd(velocity: velocity, searchRange: 0..<velocity.count) else {
            return nil
        }

        guard let topIndex = findTopOfBackswing(smoothed: smoothed, velocity: velocity, after: addressIndex) else {
            return nil
        }

        guard let impactIndex = findImpact(velocity: velocity, after: topIndex) else {
            return nil
        }

        let finishIndex = findFinish(velocity: velocity, after: impactIndex) ?? (frames.count - 1)

        guard addressIndex < topIndex, topIndex < impactIndex, impactIndex <= finishIndex else {
            return nil
        }

        return SwingPhaseTiming(
            address: addressIndex,
            topOfBackswing: topIndex,
            impact: impactIndex,
            finish: finishIndex
        )
    }

    // MARK: - Signal prep

    /// Average height (y) of visible wrists per frame, forward/backward
    /// filled where both wrists are below the visibility threshold.
    private func interpolatedWristHeights(_ frames: [PoseFrame]) -> [Double]? {
        var values: [Double?] = frames.map { frame in
            let candidates = [frame[.leftWrist], frame[.rightWrist]]
                .compactMap { $0 }
                .filter { $0.visibility >= minVisibility }
            guard !candidates.isEmpty else { return nil }
            return candidates.map(\.y).reduce(0, +) / Double(candidates.count)
        }

        guard values.contains(where: { $0 != nil }) else { return nil }

        // Forward-fill, then backward-fill any remaining leading gaps.
        var lastValid: Double?
        for i in 0..<values.count {
            if let v = values[i] { lastValid = v } else { values[i] = lastValid }
        }
        lastValid = nil
        for i in stride(from: values.count - 1, through: 0, by: -1) {
            if let v = values[i] { lastValid = v } else { values[i] = lastValid }
        }

        return values.map { $0 ?? 0 }
    }

    private func movingAverage(_ values: [Double], window: Int) -> [Double] {
        guard window > 1 else { return values }
        var result = [Double](repeating: 0, count: values.count)
        for i in 0..<values.count {
            let lo = max(0, i - window / 2)
            let hi = min(values.count - 1, i + window / 2)
            let slice = values[lo...hi]
            result[i] = slice.reduce(0, +) / Double(slice.count)
        }
        return result
    }

    /// Signed vertical velocity per frame. Positive means the wrist is
    /// moving down (y increasing); negative means moving up.
    private func frameVelocities(_ values: [Double], timestamps: [TimeInterval]) -> [Double] {
        var velocity = [Double](repeating: 0, count: values.count)
        for i in 1..<values.count {
            let dt = max(timestamps[i] - timestamps[i - 1], 1.0 / 240.0)
            velocity[i] = (values[i] - values[i - 1]) / dt
        }
        return velocity
    }

    // MARK: - Phase detection

    /// The frame at which a sustained low-velocity window ends, i.e. the
    /// golfer is set up and still before starting the swing.
    private func findStillnessEnd(velocity: [Double], searchRange: Range<Int>) -> Int? {
        var stillRunStart: Int?
        for i in searchRange {
            if abs(velocity[i]) <= stillnessVelocityThreshold {
                if stillRunStart == nil { stillRunStart = i }
                if let start = stillRunStart, i - start + 1 >= minStillFrames {
                    return i
                }
            } else {
                stillRunStart = nil
            }
        }
        return nil
    }

    /// First point after address where the wrist stops rising and starts
    /// descending (a sign change from negative to positive velocity).
    /// Falls back to the global minimum height if no clean reversal is found.
    private func findTopOfBackswing(smoothed: [Double], velocity: [Double], after addressIndex: Int) -> Int? {
        var sawUpwardMotion = false
        for i in (addressIndex + 1)..<velocity.count {
            if velocity[i] < -stillnessVelocityThreshold {
                sawUpwardMotion = true
            } else if sawUpwardMotion && velocity[i] > stillnessVelocityThreshold {
                return i - 1
            }
        }

        guard addressIndex + 1 < smoothed.count else { return nil }
        let window = smoothed[(addressIndex + 1)...]
        guard let minValue = window.min(), let minIndex = window.firstIndex(of: minValue) else { return nil }
        return minIndex
    }

    /// Point of maximum downward wrist speed after the top of backswing,
    /// used as a proxy for impact.
    private func findImpact(velocity: [Double], after topIndex: Int) -> Int? {
        guard topIndex + 1 < velocity.count else { return nil }
        let window = velocity[(topIndex + 1)...]
        guard let maxValue = window.max(), let maxIndex = window.firstIndex(of: maxValue) else { return nil }
        return maxValue > stillnessVelocityThreshold ? maxIndex : nil
    }

    /// First sustained low-velocity window after impact — the golfer has
    /// finished rotating into the follow-through.
    private func findFinish(velocity: [Double], after impactIndex: Int) -> Int? {
        guard impactIndex + 1 < velocity.count else { return nil }
        return findStillnessEnd(velocity: velocity, searchRange: (impactIndex + 1)..<velocity.count)
    }
}

import Foundation

/// A single landmark position from the pose model, in MediaPipe's
/// normalized image coordinate space (x, y in [0, 1] relative to the
/// frame, z relative depth with the hips roughly at the origin).
public struct PoseLandmark: Codable, Hashable {
    public let x: Double
    public let y: Double
    public let z: Double
    public let visibility: Double

    public init(x: Double, y: Double, z: Double, visibility: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.visibility = visibility
    }
}

/// All 33 landmarks detected for one video frame.
public struct PoseFrame: Codable {
    public let frameIndex: Int
    public let timestamp: TimeInterval
    public let landmarks: [PoseLandmarkType: PoseLandmark]

    public init(frameIndex: Int, timestamp: TimeInterval, landmarks: [PoseLandmarkType: PoseLandmark]) {
        self.frameIndex = frameIndex
        self.timestamp = timestamp
        self.landmarks = landmarks
    }

    public subscript(_ type: PoseLandmarkType) -> PoseLandmark? {
        landmarks[type]
    }

    /// Midpoint between two landmarks, or nil if either is missing.
    public func midpoint(_ a: PoseLandmarkType, _ b: PoseLandmarkType) -> PoseLandmark? {
        guard let la = landmarks[a], let lb = landmarks[b] else { return nil }
        return PoseLandmark(
            x: (la.x + lb.x) / 2,
            y: (la.y + lb.y) / 2,
            z: (la.z + lb.z) / 2,
            visibility: min(la.visibility, lb.visibility)
        )
    }
}

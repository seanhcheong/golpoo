import Foundation

/// Camera angle for a recording. Each angle is captured and analyzed
/// independently in v1 — no simultaneous dual-camera sync.
public enum CameraAngle: String, CaseIterable, Codable, Hashable {
    case faceOn = "Face-On"
    case downTheLine = "Down-the-Line"
}

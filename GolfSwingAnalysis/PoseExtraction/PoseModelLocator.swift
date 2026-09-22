import Foundation

/// Locates the bundled MediaPipe pose model file. The `.task` model
/// binary isn't checked into source control — see README for the
/// download step and where to add it to the app target.
enum PoseModelLocator {
    static func modelPath(named name: String = "pose_landmarker_full") throws -> String {
        guard let path = Bundle.main.path(forResource: name, ofType: "task") else {
            throw PoseExtractionError.modelNotFound
        }
        return path
    }
}

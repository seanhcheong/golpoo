import Foundation
import GolfSwingCore
import MediaPipeTasksVision

enum PoseExtractionError: Error {
    case modelNotFound
    case detectionFailed(Error)
}

/// Wraps MediaPipe's on-device PoseLandmarker task (BlazePose, 33
/// landmarks). This is the one piece of the pipeline that's necessarily
/// platform-specific — MediaPipe's Task Vision SDK has a separate API per
/// platform — so everything downstream of the `PoseFrame` values this
/// produces lives in the portable GolfSwingCore package instead.
///
/// NOTE: written against the MediaPipeTasksVision Swift API surface as of
/// this writing. This file has not been compiled against an actual Xcode
/// toolchain in this session (none is available in this environment) — verify
/// property names/types (e.g. `NormalizedLandmark.visibility`) against the
/// exact pod version once `pod install` has run. See README.
final class MediaPipePoseExtractor {
    private let poseLandmarker: PoseLandmarker

    /// - Parameter modelPath: path to a bundled `pose_landmarker_full.task`
    ///   model file. The binary model isn't checked into source control —
    ///   see README for the download step.
    init(modelPath: String) throws {
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .video
        options.numPoses = 1
        poseLandmarker = try PoseLandmarker(options: options)
    }

    /// Runs pose detection frame-by-frame over an already-decoded video,
    /// in presentation-time order (required by MediaPipe's `.video` running mode).
    func extractPoses(from frames: [VideoFrameSampler.Frame]) throws -> [PoseFrame] {
        var poseFrames: [PoseFrame] = []
        poseFrames.reserveCapacity(frames.count)

        for (index, frame) in frames.enumerated() {
            let image = try MPImage(pixelBuffer: frame.pixelBuffer)
            let timestampMs = Int(frame.timestamp * 1000)
            let result: PoseLandmarkerResult
            do {
                result = try poseLandmarker.detect(videoFrame: image, timestampInMilliseconds: timestampMs)
            } catch {
                throw PoseExtractionError.detectionFailed(error)
            }
            guard let landmarks = result.landmarks.first else { continue }
            poseFrames.append(makePoseFrame(frameIndex: index, timestamp: frame.timestamp, landmarks: landmarks))
        }

        return poseFrames
    }

    private func makePoseFrame(
        frameIndex: Int,
        timestamp: TimeInterval,
        landmarks: [NormalizedLandmark]
    ) -> PoseFrame {
        var mapped: [PoseLandmarkType: PoseLandmark] = [:]
        for type in PoseLandmarkType.allCases where type.rawValue < landmarks.count {
            let landmark = landmarks[type.rawValue]
            let visibility = (landmark.visibility as? NSNumber)?.doubleValue ?? 1.0
            mapped[type] = PoseLandmark(
                x: Double(landmark.x),
                y: Double(landmark.y),
                z: Double(landmark.z),
                visibility: visibility
            )
        }
        return PoseFrame(frameIndex: frameIndex, timestamp: timestamp, landmarks: mapped)
    }
}

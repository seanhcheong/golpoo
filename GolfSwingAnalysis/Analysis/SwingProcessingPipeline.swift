import Foundation
import GolfSwingCore

enum SwingProcessingError: Error {
    case notEnoughPoseData
    case phaseDetectionFailed
}

/// Orchestrates the full on-device pipeline: decode video frames ->
/// extract pose landmarks -> detect swing phases -> calculate metrics ->
/// evaluate against reference ranges. Nothing in this pipeline makes a
/// network call — that only happens later, on an explicit "What should I
/// work on?" tap, and is out of scope for this pass.
struct SwingProcessingPipeline {
    private let frameSampler: VideoFrameSampler
    private let poseExtractorFactory: () throws -> MediaPipePoseExtractor
    private let phaseDetector: SwingPhaseDetector
    private let metricsCalculator: SwingMetricsCalculator
    private let referenceRangeProvider: ReferenceRangeProvider

    init(
        frameSampler: VideoFrameSampler = VideoFrameSampler(),
        poseExtractorFactory: @escaping () throws -> MediaPipePoseExtractor,
        phaseDetector: SwingPhaseDetector = SwingPhaseDetector(),
        metricsCalculator: SwingMetricsCalculator = SwingMetricsCalculator(),
        referenceRangeProvider: ReferenceRangeProvider
    ) {
        self.frameSampler = frameSampler
        self.poseExtractorFactory = poseExtractorFactory
        self.phaseDetector = phaseDetector
        self.metricsCalculator = metricsCalculator
        self.referenceRangeProvider = referenceRangeProvider
    }

    func process(
        videoURL: URL,
        clubCategory: ClubCategory,
        cameraAngle: CameraAngle,
        profile: UserProfile
    ) async throws -> SwingAnalysisResult {
        let frames = try await frameSampler.sampleFrames(from: videoURL)
        guard !frames.isEmpty else { throw SwingProcessingError.notEnoughPoseData }

        let extractor = try poseExtractorFactory()
        let poseFrames = try extractor.extractPoses(from: frames)
        guard poseFrames.count >= 8 else { throw SwingProcessingError.notEnoughPoseData }

        guard let phases = phaseDetector.detectPhases(in: poseFrames) else {
            throw SwingProcessingError.phaseDetectionFailed
        }

        let metrics = try metricsCalculator.calculate(frames: poseFrames, phases: phases)
        let evaluations = try referenceRangeProvider.evaluate(
            metrics: metrics,
            heightInInches: profile.heightInInches
        )

        return SwingAnalysisResult(
            id: UUID(),
            date: Date(),
            clubCategory: clubCategory,
            cameraAngle: cameraAngle,
            heightInInches: profile.heightInInches,
            videoURL: videoURL,
            phases: phases,
            metrics: metrics,
            evaluations: evaluations
        )
    }
}

import Foundation
import GolfSwingCore

@MainActor
final class SwingAnalysisViewModel: ObservableObject {
    @Published var isProcessing = true
    @Published var result: SwingAnalysisResult?
    @Published var errorMessage: String?

    private let sessionStore: SwingSessionStore

    init(sessionStore: SwingSessionStore = SwingSessionStore()) {
        self.sessionStore = sessionStore
    }

    func process(videoURL: URL, clubCategory: ClubCategory, cameraAngle: CameraAngle, profile: UserProfile) async {
        isProcessing = true
        errorMessage = nil

        do {
            let referenceRangeProvider = try ReferenceRangeProvider()
            let pipeline = SwingProcessingPipeline(
                poseExtractorFactory: {
                    try MediaPipePoseExtractor(modelPath: try PoseModelLocator.modelPath())
                },
                referenceRangeProvider: referenceRangeProvider
            )
            let result = try await pipeline.process(
                videoURL: videoURL,
                clubCategory: clubCategory,
                cameraAngle: cameraAngle,
                profile: profile
            )
            try sessionStore.save(result)
            self.result = result
        } catch {
            errorMessage = String(describing: error)
        }

        isProcessing = false
    }
}

import Foundation
import GolfSwingCore

/// One completed swing analysis, as persisted to local storage.
struct SwingAnalysisResult: Codable, Identifiable {
    let id: UUID
    let date: Date
    let clubCategory: ClubCategory
    let cameraAngle: CameraAngle
    let heightInInches: Double
    let videoURL: URL
    let phases: SwingPhaseTiming
    let metrics: SwingMetrics
    let evaluations: [MetricEvaluation]
}

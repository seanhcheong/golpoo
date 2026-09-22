import SwiftUI
import GolfSwingCore

struct ProcessingResultView: View {
    @StateObject private var viewModel = SwingAnalysisViewModel()
    let videoURL: URL
    let clubCategory: ClubCategory
    let cameraAngle: CameraAngle
    let profile: UserProfile
    let onResult: (SwingAnalysisResult) -> Void
    let onFailure: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            ProgressView("Analyzing swing…")
            Text("Extracting pose data and calculating metrics on-device.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .task {
            await viewModel.process(
                videoURL: videoURL,
                clubCategory: clubCategory,
                cameraAngle: cameraAngle,
                profile: profile
            )
            if let result = viewModel.result {
                onResult(result)
            } else if let errorMessage = viewModel.errorMessage {
                onFailure(errorMessage)
            }
        }
    }
}

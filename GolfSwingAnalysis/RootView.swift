import SwiftUI
import GolfSwingCore

/// Wires the v1 flow: setup -> record -> process -> result. The
/// slow-motion overlay review screen and coaching request come later —
/// this pass ends at a plain metrics summary so the pipeline itself can
/// be validated first.
struct RootView: View {
    private enum Step {
        case setup
        case recording(ClubCategory, CameraAngle, UserProfile)
        case processing(URL, ClubCategory, CameraAngle, UserProfile)
        case result(SwingAnalysisResult)
        case failed(String)
    }

    @State private var step: Step = .setup

    var body: some View {
        NavigationStack {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .setup:
            SwingSetupView { clubCategory, cameraAngle, profile in
                step = .recording(clubCategory, cameraAngle, profile)
            }

        case .recording(let clubCategory, let cameraAngle, let profile):
            RecordingView { videoURL in
                step = .processing(videoURL, clubCategory, cameraAngle, profile)
            }

        case .processing(let videoURL, let clubCategory, let cameraAngle, let profile):
            ProcessingResultView(
                videoURL: videoURL,
                clubCategory: clubCategory,
                cameraAngle: cameraAngle,
                profile: profile,
                onResult: { result in step = .result(result) },
                onFailure: { message in step = .failed(message) }
            )

        case .result(let result):
            SwingResultSummaryView(result: result) {
                step = .setup
            }

        case .failed(let message):
            VStack(spacing: 16) {
                Text("Something went wrong").font(.headline)
                Text(message).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button("Try Again") { step = .setup }
            }
            .padding()
        }
    }
}

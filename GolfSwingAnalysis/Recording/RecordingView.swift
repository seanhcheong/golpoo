import AVFoundation
import SwiftUI

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

/// Records a single swing. This is intentionally minimal — the
/// slow-motion scrubber, skeleton overlay, and synthetic reference
/// skeleton are review-screen UI that comes after the core pipeline.
struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    let onFinished: (URL) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            CameraPreviewView(session: viewModel.captureService.session)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    viewModel.toggleRecording()
                } label: {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red : Color.white)
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear { viewModel.prepare() }
        .onDisappear { viewModel.stop() }
        .onChange(of: viewModel.recordedVideoURL) { _, url in
            if let url { onFinished(url) }
        }
    }
}

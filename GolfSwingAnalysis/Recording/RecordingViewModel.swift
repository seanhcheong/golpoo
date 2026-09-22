import AVFoundation
import Foundation

final class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var recordedVideoURL: URL?
    @Published var errorMessage: String?

    let captureService: CameraCaptureService

    init(captureService: CameraCaptureService = CameraCaptureService()) {
        self.captureService = captureService
    }

    func prepare() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                guard granted else {
                    self?.errorMessage = "Camera access is required to record a swing."
                    return
                }
                self?.startSession()
            }
        }
    }

    private func startSession() {
        do {
            try captureService.configureSessionIfNeeded()
            captureService.startSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleRecording() {
        if isRecording {
            captureService.stopRecording()
        } else {
            recordedVideoURL = nil
            isRecording = true
            captureService.startRecording { [weak self] result in
                DispatchQueue.main.async {
                    self?.isRecording = false
                    switch result {
                    case .success(let url):
                        self?.recordedVideoURL = url
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    func stop() {
        captureService.stopSession()
    }
}

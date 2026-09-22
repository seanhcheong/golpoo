import AVFoundation

enum CameraCaptureError: Error {
    case deviceUnavailable
    case configurationFailed
}

/// Wraps AVFoundation camera capture for a single swing recording.
/// Prefers the highest available frame rate on the selected format
/// (ideally 120fps+) so slow-motion review has usable frame density.
/// Video-only — no microphone input is added, since audio isn't needed
/// for pose analysis and this avoids requesting mic permission.
final class CameraCaptureService: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var lastRecordingURL: URL?
    @Published private(set) var lastError: Error?

    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var completion: ((Result<URL, Error>) -> Void)?
    private var isConfigured = false

    func configureSessionIfNeeded() throws {
        guard !isConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .inputPriority
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraCaptureError.deviceUnavailable
        }

        if let highFrameRateFormat = bestHighFrameRateFormat(for: device) {
            try device.lockForConfiguration()
            device.activeFormat = highFrameRateFormat.format
            device.activeVideoMinFrameDuration = highFrameRateFormat.frameDuration
            device.activeVideoMaxFrameDuration = highFrameRateFormat.frameDuration
            device.unlockForConfiguration()
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw CameraCaptureError.configurationFailed }
        session.addInput(input)

        guard session.canAddOutput(movieOutput) else { throw CameraCaptureError.configurationFailed }
        session.addOutput(movieOutput)

        isConfigured = true
    }

    /// Picks the format with the highest supported frame rate. Falls
    /// back to whatever the device supports if 120fps isn't available.
    private func bestHighFrameRateFormat(for device: AVCaptureDevice) -> (format: AVCaptureDevice.Format, frameDuration: CMTime)? {
        var best: (format: AVCaptureDevice.Format, maxRate: Double)?
        for format in device.formats {
            guard let range = format.videoSupportedFrameRateRanges.max(by: { $0.maxFrameRate < $1.maxFrameRate }) else { continue }
            if best == nil || range.maxFrameRate > best!.maxRate {
                best = (format, range.maxFrameRate)
            }
        }
        guard let best,
              let range = best.format.videoSupportedFrameRateRanges.max(by: { $0.maxFrameRate < $1.maxFrameRate }) else {
            return nil
        }
        return (best.format, range.minFrameDuration)
    }

    func startSession() {
        guard !session.isRunning else { return }
        session.startRunning()
    }

    func stopSession() {
        guard session.isRunning else { return }
        session.stopRunning()
    }

    func startRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        self.completion = completion
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        movieOutput.stopRecording()
    }
}

extension CameraCaptureService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        isRecording = false
        if let error {
            lastError = error
            completion?(.failure(error))
        } else {
            lastRecordingURL = outputFileURL
            completion?(.success(outputFileURL))
        }
        completion = nil
    }
}

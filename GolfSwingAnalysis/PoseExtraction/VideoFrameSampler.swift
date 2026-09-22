import AVFoundation
import CoreVideo

enum VideoFrameSamplerError: Error {
    case noVideoTrack
    case readerSetupFailed
}

/// Decodes every frame of a recorded swing video into a CVPixelBuffer
/// plus its presentation timestamp, for on-device pose extraction.
/// No frame is ever uploaded anywhere — this stays entirely on-device.
struct VideoFrameSampler {
    struct Frame {
        let pixelBuffer: CVPixelBuffer
        let timestamp: TimeInterval
    }

    func sampleFrames(from url: URL) async throws -> [Frame] {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoFrameSamplerError.noVideoTrack
        }

        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        trackOutput.alwaysCopiesSampleData = false

        guard reader.canAdd(trackOutput) else { throw VideoFrameSamplerError.readerSetupFailed }
        reader.add(trackOutput)
        reader.startReading()

        var frames: [Frame] = []
        while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            frames.append(Frame(pixelBuffer: pixelBuffer, timestamp: CMTimeGetSeconds(presentationTime)))
        }

        if reader.status == .failed {
            throw reader.error ?? VideoFrameSamplerError.readerSetupFailed
        }

        return frames
    }
}

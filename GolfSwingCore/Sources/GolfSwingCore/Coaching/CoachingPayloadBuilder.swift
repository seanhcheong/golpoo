import Foundation

/// The small, structured payload sent to the coaching LLM API. Only
/// derived metrics and their evaluations are included — never raw video
/// or raw pose coordinate arrays — to keep the request small and cheap.
///
/// This type is a data-shape scaffold only: the actual networked call is
/// out of scope for this pass (recording -> pose extraction -> metrics
/// comes first per the project brief). Building this now lets the
/// pipeline produce its output in the exact shape the coaching layer will
/// need later.
public struct CoachingRequestPayload: Codable, Equatable {
    public struct OutOfRangeMetric: Codable, Equatable {
        public let metricName: String
        public let value: Double
        public let range: MetricRange
        public let deviation: Double
    }

    public let clubCategory: ClubCategory
    public let cameraAngle: CameraAngle
    public let metrics: SwingMetrics
    public let outOfRangeMetrics: [OutOfRangeMetric]

    public init(clubCategory: ClubCategory, cameraAngle: CameraAngle, metrics: SwingMetrics, outOfRangeMetrics: [OutOfRangeMetric]) {
        self.clubCategory = clubCategory
        self.cameraAngle = cameraAngle
        self.metrics = metrics
        self.outOfRangeMetrics = outOfRangeMetrics
    }
}

public enum CoachingPayloadBuilder {
    /// Builds the request payload from a full metric evaluation, keeping
    /// only the metrics that fell outside their reference range plus the
    /// full metric set for context.
    public static func build(
        clubCategory: ClubCategory,
        cameraAngle: CameraAngle,
        metrics: SwingMetrics,
        evaluations: [MetricEvaluation]
    ) -> CoachingRequestPayload {
        let outOfRange = evaluations
            .filter { !$0.isInRange }
            .map {
                CoachingRequestPayload.OutOfRangeMetric(
                    metricName: $0.metricName,
                    value: $0.value,
                    range: $0.range,
                    deviation: $0.deviation
                )
            }
        return CoachingRequestPayload(
            clubCategory: clubCategory,
            cameraAngle: cameraAngle,
            metrics: metrics,
            outOfRangeMetrics: outOfRange
        )
    }
}

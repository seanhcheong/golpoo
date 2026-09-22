import Foundation

/// One named metric's acceptable band, as loaded from the reference-data config.
public struct MetricRange: Codable, Equatable {
    public let min: Double
    public let max: Double
    public let ideal: Double

    public init(min: Double, max: Double, ideal: Double) {
        self.min = min
        self.max = max
        self.ideal = ideal
    }

    public func contains(_ value: Double) -> Bool {
        value >= min && value <= max
    }

    /// Signed distance outside the range; 0 when the value is in range.
    public func deviation(for value: Double) -> Double {
        if value < min { return value - min }
        if value > max { return value - max }
        return 0
    }
}

/// The result of comparing one computed metric against its reference range.
public struct MetricEvaluation: Codable, Equatable, Identifiable {
    public let id: String
    public let metricName: String
    public let value: Double
    public let range: MetricRange
    public let isInRange: Bool
    public let deviation: Double

    public init(metricName: String, value: Double, range: MetricRange) {
        self.id = metricName
        self.metricName = metricName
        self.value = value
        self.range = range
        self.isInRange = range.contains(value)
        self.deviation = range.deviation(for: value)
    }
}

import Foundation

/// Decoded shape of reference_ranges.json. Keeping this config-driven
/// (rather than hardcoded ranges in Swift) so the numbers can be reviewed
/// and adjusted without a code change.
struct ReferenceRangeConfig: Codable {
    let clubCategory: String
    let sourceNotes: String
    let metrics: [String: MetricRange]
    let spineAngleAddressByHeightBand: [String: MetricRange]
}

public enum ReferenceRangeProviderError: Error {
    case resourceNotFound
    case decodingFailed(Error)
    case unknownHeightBand(HeightBand)
}

/// Loads the reference-range config and evaluates a computed
/// `SwingMetrics` against it, applying height-band scaling to the
/// spine-angle-at-address expectation.
public struct ReferenceRangeProvider {
    private let config: ReferenceRangeConfig

    public init() throws {
        // `Bundle.module` is SwiftPM's generated accessor, which is
        // `internal` — it can't be used as a default value on a `public`
        // initializer (the default-argument thunk must be at least as
        // accessible as the initializer itself), but referencing it here,
        // inside the body, is fine.
        try self.init(bundle: .module)
    }

    init(bundle: Bundle) throws {
        guard let url = bundle.url(forResource: "reference_ranges", withExtension: "json") else {
            throw ReferenceRangeProviderError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        do {
            config = try JSONDecoder().decode(ReferenceRangeConfig.self, from: data)
        } catch {
            throw ReferenceRangeProviderError.decodingFailed(error)
        }
    }

    /// Evaluates every v1 metric against its reference range for the
    /// given club category and user height, returning one evaluation per metric.
    public func evaluate(metrics: SwingMetrics, heightInInches: Double) throws -> [MetricEvaluation] {
        let heightBand = HeightBand.band(forHeightInInches: heightInInches)
        guard let spineAddressRange = config.spineAngleAddressByHeightBand[heightBand.rawValue] else {
            throw ReferenceRangeProviderError.unknownHeightBand(heightBand)
        }

        var evaluations: [MetricEvaluation] = []
        evaluations.append(try evaluation(named: "tempoRatio", value: metrics.tempoRatio))
        evaluations.append(try evaluation(named: "xFactorAtTop", value: metrics.xFactorAtTop))
        evaluations.append(try evaluation(named: "shoulderRotationAtTop", value: metrics.shoulderRotationAtTop))
        evaluations.append(try evaluation(named: "hipRotationAtTop", value: metrics.hipRotationAtTop))
        evaluations.append(try evaluation(named: "spineAngleDeviation", value: metrics.spineAngleDeviation))
        evaluations.append(MetricEvaluation(
            metricName: "spineAngleAddress",
            value: metrics.spineAngleAddress,
            range: spineAddressRange
        ))
        return evaluations
    }

    private func evaluation(named name: String, value: Double) throws -> MetricEvaluation {
        guard let range = config.metrics[name] else {
            throw ReferenceRangeProviderError.resourceNotFound
        }
        return MetricEvaluation(metricName: name, value: value, range: range)
    }
}

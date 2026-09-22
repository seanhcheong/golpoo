import XCTest
@testable import GolfSwingCore

final class ReferenceRangeProviderTests: XCTestCase {
    func testEvaluatesInRangeMetricsForAverageHeight() throws {
        let provider = try ReferenceRangeProvider()
        let metrics = SwingMetrics(
            tempoRatio: 3.0,
            xFactorAtTop: 40,
            spineAngleAddress: 37, // center of the "average" height band
            spineAngleImpact: 38,
            shoulderRotationAtTop: 90,
            hipRotationAtTop: 45
        )

        let evaluations = try provider.evaluate(metrics: metrics, heightInInches: 69)
        let byName = Dictionary(uniqueKeysWithValues: evaluations.map { ($0.metricName, $0) })

        for name in ["tempoRatio", "xFactorAtTop", "shoulderRotationAtTop", "hipRotationAtTop", "spineAngleDeviation", "spineAngleAddress"] {
            let evaluation = try XCTUnwrap(byName[name], "missing evaluation for \(name)")
            XCTAssertTrue(evaluation.isInRange, "\(name) unexpectedly out of range: \(evaluation.value)")
        }
    }

    func testFlagsOutOfRangeMetricWithDeviation() throws {
        let provider = try ReferenceRangeProvider()
        let metrics = SwingMetrics(
            tempoRatio: 5.0, // well above the 2.5-4.0 band
            xFactorAtTop: 40,
            spineAngleAddress: 37,
            spineAngleImpact: 37,
            shoulderRotationAtTop: 90,
            hipRotationAtTop: 45
        )

        let evaluations = try provider.evaluate(metrics: metrics, heightInInches: 69)
        let tempo = try XCTUnwrap(evaluations.first { $0.metricName == "tempoRatio" })

        XCTAssertFalse(tempo.isInRange)
        XCTAssertEqual(tempo.deviation, 1.0, accuracy: 1e-9)
    }

    func testHeightBandsSelectDifferentSpineAngleRanges() throws {
        let provider = try ReferenceRangeProvider()
        let metrics = SwingMetrics(
            tempoRatio: 3.0,
            xFactorAtTop: 40,
            spineAngleAddress: 34, // ideal for "short", but below the "tall" band's min of 36
            spineAngleImpact: 34,
            shoulderRotationAtTop: 90,
            hipRotationAtTop: 45
        )

        let shortResult = try provider.evaluate(metrics: metrics, heightInInches: 60)
        let tallResult = try provider.evaluate(metrics: metrics, heightInInches: 76)

        let shortSpine = try XCTUnwrap(shortResult.first { $0.metricName == "spineAngleAddress" })
        let tallSpine = try XCTUnwrap(tallResult.first { $0.metricName == "spineAngleAddress" })

        XCTAssertTrue(shortSpine.isInRange)
        XCTAssertFalse(tallSpine.isInRange)
    }
}

import Foundation

/// v1 simplification: height is bucketed into three proportional bands
/// rather than scaled with a precise biomechanical formula. A more
/// precise, continuous scaling function is a v2 refinement that likely
/// needs a biomechanics consultant or labeled swing data to derive.
public enum HeightBand: String, CaseIterable, Codable {
    case short
    case average
    case tall

    public static func band(forHeightInInches height: Double) -> HeightBand {
        switch height {
        case ..<66: return .short
        case 66..<72: return .average
        default: return .tall
        }
    }
}

import SwiftUI
import GolfSwingCore

/// Minimal metrics summary. The slow-motion scrubber, skeleton overlay,
/// synthetic reference skeleton, and "What should I work on?" coaching
/// button are review-screen UI that comes after the core pipeline —
/// out of scope for this pass.
struct SwingResultSummaryView: View {
    let result: SwingAnalysisResult
    let onDone: () -> Void

    var body: some View {
        List {
            Section("Metrics") {
                ForEach(result.evaluations) { evaluation in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(evaluation.metricName)
                            Text(String(
                                format: "%.1f (ideal %.1f, range %.1f–%.1f)",
                                evaluation.value, evaluation.range.ideal, evaluation.range.min, evaluation.range.max
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: evaluation.isInRange ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(evaluation.isInRange ? .green : .orange)
                    }
                }
            }

            Section {
                Button("Analyze Another Swing", action: onDone)
            }
        }
        .navigationTitle("Swing Analysis")
    }
}

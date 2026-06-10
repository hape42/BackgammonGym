//
//  PipTrendChart.swift
//  BackgammonGym
//
//  Bar chart of training sessions over time. Shows either the hit rate
//  (percent) or the average answer time (seconds), driven by `metric`.
//  Data comes from CoreDataManager as an array of NSDictionary, one per
//  session, oldest first.
//

import SwiftUI
import Charts

// Which value the bars represent.
@objc public enum PipChartMetric: Int {
    case percent = 0   // hit rate 0–100
    case seconds = 1   // average answer time
}

struct PipTrendChart: View {
    let title: String
    let metric: PipChartMetric
    let sessions: [NSDictionary]

    // Thresholds passed in from BGGTimeColor so the chart matches the
    // colours used for badges elsewhere in the app.
    let greenSeconds: Int
    let orangeSeconds: Int
    let greenRate: Int
    let orangeRate: Int

    private var yLabel: String {
        metric == .percent ? "Hit rate (%)" : "Average time (s)"
    }

    private func value(_ dict: NSDictionary) -> Int {
        let key = (metric == .percent) ? "percent" : "avgSeconds"
        return dict[key] as? Int ?? 0
    }

    // Bar colour using the same thresholds as the rest of the app.
    private func barColor(_ dict: NSDictionary) -> Color {
        let v = value(dict)
        if metric == .percent {
            // Higher is better.
            if v >= greenRate  { return .green }
            if v >= orangeRate { return .orange }
            return .red
        } else {
            // Lower is better.
            if v <= greenSeconds  { return .green }
            if v <= orangeSeconds { return .orange }
            return .red
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Text(title)
                    .font(.title2)
                    .bold()
                    .padding(.bottom, 5)
                Spacer()
            }

            if sessions.isEmpty {
                Spacer()
                Text("No sessions yet.")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                Chart {
                    ForEach(0..<sessions.count, id: \.self) { index in
                        let dict = sessions[index]
                        let v = value(dict)
                        let label = dict["label"] as? String ?? "—"

                        BarMark(
                            // Index keeps bars in chronological order even if
                            // two sessions share a date label.
                            x: .value("Session", "\(index)"),
                            y: .value(yLabel, v)
                        )
                        .foregroundStyle(barColor(dict).gradient)
                        .annotation(position: .top) {
                            Text("\(v)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .annotation(position: .bottom) {
                            Text(label)
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(-45))
                                .fixedSize()
                        }
                    }
                }
                .chartXAxis(.hidden)   // date labels are drawn as annotations
                .chartYAxisLabel(yLabel)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

#Preview {
    PipTrendChart(title: "Hit rate", metric: .percent, sessions: [
        ["label": "8 Jun", "percent": 60, "avgSeconds": 25, "mode": "training"],
        ["label": "9 Jun", "percent": 80, "avgSeconds": 18, "mode": "workout"],
        ["label": "10 Jun", "percent": 90, "avgSeconds": 14, "mode": "workout"],
    ] as [NSDictionary],
    greenSeconds: 20, orangeSeconds: 60, greenRate: 80, orangeRate: 50)
}

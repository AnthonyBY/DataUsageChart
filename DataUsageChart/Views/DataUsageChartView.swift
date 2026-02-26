import SwiftUI
import Charts


// Helper for chart points (moved out of ViewBuilder to avoid result builder declaration error)
private struct ChartPoint: Identifiable {
    let id = UUID()
    let app: String
    let hour: Int
    let minutes: Int
    let colorHex: String?
}

// MARK: - View
struct DataUsageChartView: View {
    @StateObject private var vm = UsageViewModel(repository: LocalJSONUsageRepository())

    var body: some View {
        NavigationStack {
            Group {
                if let error = vm.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange)
                        Text(error).multilineTextAlignment(.center)
                        Button("Retry") { vm.load() }
                    }
                    .padding()
                } else if let daily = vm.daily {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            header(total: vm.totalMinutes, dateString: daily.date)
                            usageChart(daily: daily)
                            appList(daily: daily, total: vm.totalMinutes)
                        }
                        .padding()
                    }
                } else {
                    ProgressView().task { vm.load() }
                }
            }
            .navigationTitle("Usage")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Header with date and total usage
    @ViewBuilder
    private func header(total: Int, dateString: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formatted(date: dateString))
                .font(.title2).bold()
            Text(total.hoursMinutesString + " total")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    // Stacked hourly chart per app
    @ViewBuilder
    private func usageChart(daily: DailyUsage) -> some View {
        let points: [ChartPoint] = daily.apps.flatMap { app in
            app.hourly.map { h in
                ChartPoint(app: app.app, hour: h.hour, minutes: h.minutes, colorHex: app.colorHex)
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Hourly breakdown")
                .font(.headline)

            if points.isEmpty {
                Text("No usage data for this day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                let maxY = max(points.map(\.minutes).max() ?? 0, 1)

                Chart(points) { p in
                    BarMark(
                        x: .value("Hour", p.hour),
                        y: .value("Minutes", p.minutes)
                    )
                    .foregroundStyle(by: .value("App", p.app))
                }
                .chartXScale(domain: 0...23)
                .chartYScale(domain: 0...maxY)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 2)) { value in
                        if let hour = value.as(Int.self), (0...23).contains(hour) {
                            AxisGridLine()
                            AxisValueLabel(String(format: "%02d", hour))
                        }
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // Ranked list of apps
    @ViewBuilder
    private func appList(daily: DailyUsage, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(daily.apps) { app in
                    AppUsageRowView(appUsage: app, total: total)
                    Divider()
                }
            }
        }
     //   .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // Helpers
    private func formatted(date: String) -> String {
        // Try to parse ISO and format nicely
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: date) {
            let f = DateFormatter()
            f.dateStyle = .full
            return f.string(from: d)
        }
        // Fallback if just yyyy-MM-dd
        let fIn = DateFormatter()
        fIn.dateFormat = "yyyy-MM-dd"
        if let d = fIn.date(from: date) {
            let fOut = DateFormatter()
            fOut.dateStyle = .full
            return fOut.string(from: d)
        }
        return date
    }
}

#Preview {
    DataUsageChartView()
}

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

private struct CategorySlice: Identifiable {
    let id = UUID()
    let category: String
    let minutes: Int
}

// MARK: - View
struct DataUsageChartView: View {
    @StateObject private var vm = UsageViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch vm.state {
                case .loading:
                    ProgressView().task { vm.load() }
                case .error(let message):
                    ErrorStateView(message: message) { vm.load() }
                case .loaded(let daily):
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            header(total: vm.totalMinutes, dateString: daily.date)
                            categoryPieChart(daily: daily)
                            usageChart(daily: daily)
                            appList(daily: daily, total: vm.totalMinutes)
                        }
                        .padding()
                    }
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
      let points: [ChartPoint] = daily.sessionCategories.flatMap { sessionCategory in
          sessionCategory.hourly.map { h in
              ChartPoint(
                app: sessionCategory.appName,
                hour: h.hour,
                minutes: h.minutes,
                colorHex: sessionCategory.colorHex
              )
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

    // Pie chart by category
    @ViewBuilder
    private func categoryPieChart(daily: DailyUsage) -> some View {
        let slices = categorySlices(from: daily)

        VStack(alignment: .leading, spacing: 8) {
            Text("By category")
                .font(.headline)

            if slices.isEmpty {
                Text("No usage data for this day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Minutes", slice.minutes),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("Category", slice.category))
                    .cornerRadius(4)
                }
                .chartLegend(position: .bottom, spacing: 8)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func categorySlices(from daily: DailyUsage) -> [CategorySlice] {
        let normalized: (String?) -> String = { name in
            guard let name, !name.isEmpty, name.lowercased() != "other" else { return "Other" }
            return name
        }
        var sumByCategory: [String: Int] = [:]
        for cat in daily.sessionCategories {
            let name = normalized(cat.name)
            sumByCategory[name, default: 0] += cat.totalMinutes
        }
        return sumByCategory
            .map { CategorySlice(category: $0.key, minutes: $0.value) }
            .filter { $0.minutes > 0 }
            .sorted { $0.minutes > $1.minutes }
    }

    // Ranked list of apps
    @ViewBuilder
    private func appList(daily: DailyUsage, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(daily.sessionCategories) { app in
                    AppUsageRowView(appUsage: app, total: total)
                 //   Divider()
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

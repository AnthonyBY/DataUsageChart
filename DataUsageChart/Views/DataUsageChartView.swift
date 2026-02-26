import SwiftUI
import Charts

// MARK: - Helpers shared with the view
extension Color {
    init?(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&int) else { return nil }
        let a, r, g, b: UInt64
        switch hexSanitized.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Int {
    var hoursMinutesString: String {
        let h = self / 60
        let m = self % 60
        if h > 0 { return String(format: "%dh %dm", h, m) }
        return String(format: "%dm", m)
    }
}

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
            Text("Apps")
                .font(.headline)
            ForEach(daily.apps.sorted(by: { $0.totalMinutes > $1.totalMinutes })) { app in
                HStack(spacing: 12) {
                    Circle()
                        .fill(color(for: app.colorHex, app: app.app))
                        .frame(width: 12, height: 12)
                    VStack(alignment: .leading) {
                        Text(app.app)
                            .font(.body)
                        if let category = app.category, !category.isEmpty {
                            Text(category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(app.totalMinutes.hoursMinutesString)
                            .font(.body).monospacedDigit()
                        Text(percentage(app.totalMinutes, of: total))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
                Divider()
            }
        }
        .padding()
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

    private func percentage(_ part: Int, of total: Int) -> String {
        guard total > 0 else { return "0%" }
        let p = (Double(part) / Double(total)) * 100
        return String(format: "%.0f%%", p)
    }

    private func color(for hex: String?, app: String) -> Color {
        if let hex, let c = Color(hex: hex) { return c }
        // deterministic fallback color per app name
        let hash = abs(app.hashValue)
        let hue = Double(hash % 256) / 255.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.9)
    }
}

#Preview {
    DataUsageChartView()
}


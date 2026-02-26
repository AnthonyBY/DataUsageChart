import SwiftUI
import Charts

struct CategoryPieChartView: View {
    let daily: DailyUsage

    var body: some View {
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
            guard let name,
                  !name.isEmpty,
                  name.lowercased() != "other"
            else { return "Other" }
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
}
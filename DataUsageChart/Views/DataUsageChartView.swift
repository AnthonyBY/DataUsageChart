//
//  DataUsageChartView.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import SwiftUI
import Charts

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
                case .loaded:
                    if let daily = vm.dailyUsage {
                        contentScrollView(daily: daily)
                    } else {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Usage")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Segment to switch between category pie and hourly bar chart
    private var chartSegmentPicker: some View {
        Picker("Chart", selection: $vm.selectedChart) {
            Text("By category").tag(ChartSelection.categoryPie)
            Text("Hourly").tag(ChartSelection.usageBar)
        }
        .pickerStyle(.segmented)
    }

    // Main scrollable content
    @ViewBuilder
    private func contentScrollView(daily: DailyUsage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(total: vm.totalMinutes, formattedDate: vm.formattedDateString)
                chartSegmentPicker
                switch vm.selectedChart {
                case .categoryPie:
                    if vm.categorySlices.isEmpty {
                        Text("No category data for this day")
                    } else {
                        CategoryPieChartView(slices: vm.categorySlices)
                    }
                case .usageBar:
                    HourlyUsageBarChartView(daily: daily)
                }
                appList(rowItems: vm.rowItems, total: vm.totalMinutes)
            }
        }
    }

    // Header with date and total usage
    @ViewBuilder
    private func header(total: Int, formattedDate: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate)
                .font(.title2).bold()
            Text(total.hoursMinutesString + " total")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // Ranked list of apps (row items from ViewModel, computed once on load)
    @ViewBuilder
    private func appList(rowItems: [AppUsageRowItem], total: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(rowItems) { item in
                    AppUsageRowView(item: item, total: total)
                }
            }
            .padding()
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DataUsageChartView()
}

//
//  UsageViewModel.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation
import Combine

enum LoadState: Equatable {
    case loading
    case loaded([Session])
    case error(String)
}

enum ChartSelection: Equatable {
    case categoryPie
    case usageBar
}

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var state: LoadState = .loading
    @Published var selectedChart: ChartSelection = .categoryPie

    /// Derived once when sessions load; not recomputed on re-renders.
    @Published private(set) var dailyUsage: DailyUsage?
    @Published private(set) var rowItems: [AppUsageRowItem] = []
    @Published private(set) var categorySlices: [CategoryPieSlice] = []
    @Published private(set) var totalMinutes: Int = 0
    /// Display string for the target date (e.g. "Monday, February 23, 2026"); computed once on load.
    @Published private(set) var targetDate: Date?
    @Published private(set) var formattedDateString: String = ""

    private let repository: DataRepositoryProtocol

    private let targetDayString = "2026-02-23" // TODO: Change to current date or add UI element for this

    init(repository: DataRepositoryProtocol, selectedChart: ChartSelection = .categoryPie) {
        self.repository = repository
        self.selectedChart = selectedChart
    }

    convenience init(selectedChart: ChartSelection = .categoryPie) {
        self.init(repository: DataRepository(), selectedChart: selectedChart)
    }

    func load() {
        state = .loading
        dailyUsage = nil
        rowItems = []
        categorySlices = []
        totalMinutes = 0
        formattedDateString = ""

        Task {
            do {
                guard let targetDate = DateParsingHelper.parseYYYYMMDD(targetDayString) else {
                    throw RepositoryError.invalidTargetDate
                }

                let sessions = try repository.loadSessions()

                totalMinutes = aggregateTotalMinutes(sessions: sessions, from: targetDate)

                let dailyUsage = aggregate(sessions: sessions, for: targetDate)
                self.dailyUsage = dailyUsage

                formattedDateString = PerformanceMeter.measure("formattedAsFullDateDisplay") {
                    dailyUsage.date.formattedAsFullDateDisplay()
                }

                categorySlices = PerformanceMeter.measure("categoryBreakdown") {
                    categoryBreakdown(sessions: sessions, from: targetDate)
                }

                rowItems = PerformanceMeter.measure("appUsageRowItems") {
                    appUsageRowItems(sessions: sessions, from: targetDate)
                }

                state = .loaded(sessions)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }
}


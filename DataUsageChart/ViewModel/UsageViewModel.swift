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
    @Published private(set) var appRowItems: [AppUsageRowItem] = []
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
        appRowItems = []
        categorySlices = []
        totalMinutes = 0
        formattedDateString = ""

        Task {
            do {
                guard let targetDate = DateParsingHelper.parseYYYYMMDD(targetDayString) else {
                    throw RepositoryError.invalidTargetDate
                }
                formattedDateString = targetDayString.formattedAsFullDateDisplay()

                let sessions = try repository.loadSessions()

                totalMinutes = PerformanceMeter.measure("totalMinutes") {
                    DailyUsageReporting.totalMinutes(sessions: sessions, from: targetDate)
                }

                dailyUsage = PerformanceMeter.measure("dailyUsage") {
                    DailyUsageReporting.dailyUsage(sessions: sessions, for: targetDate)
                }

                categorySlices = PerformanceMeter.measure("categoryBreakdown") {
                    DailyUsageReporting.categoryBreakdown(sessions: sessions, from: targetDate)
                }

                appRowItems = PerformanceMeter.measure("appUsageRowItems") {
                    DailyUsageReporting.appUsageRowItems(sessions: sessions, from: targetDate)
                }

                state = .loaded(sessions)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }
}


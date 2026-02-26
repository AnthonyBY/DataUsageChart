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

    private static let iso8601Formatter: ISO8601DateFormatter = ISO8601DateFormatter()
    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()
    private static let yyyyMMddFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
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
                let date = try convertTargetDayStringToDate()
                let sessions = try repository.loadSessions()

                // Compute once; view reads these published values
                let daily = aggregate(sessions: sessions, for: date)
                let slices = categoryBreakdown(sessions: sessions, from: date)
                let rows = appUsageRowItems(sessions: sessions, from: date)
                let total = daily.sessionCategories.map { $0.totalMinutes }.reduce(0, +)

                self.targetDate = date
                self.dailyUsage = daily
                self.formattedDateString = Self.formatDateStringForDisplay(daily.date)
                self.categorySlices = slices
                self.rowItems = rows
                self.totalMinutes = total
                self.state = .loaded(sessions)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Private

    private static func formatDateStringForDisplay(_ dateString: String) -> String {
        if let d = iso8601Formatter.date(from: dateString) {
            return fullDateFormatter.string(from: d)
        }
        if let d = yyyyMMddFormatter.date(from: dateString) {
            return fullDateFormatter.string(from: d)
        }
        return dateString
    }

    private func convertTargetDayStringToDate() throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = formatter.date(from: targetDayString) else {
            throw RepositoryError.invalidTargetDate
        }
        return date
    }
}


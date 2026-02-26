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
    @Published private(set) var targetDate: Date?
    @Published var selectedChart: ChartSelection = .categoryPie

    /// Derived once when sessions load; not recomputed on re-renders.
    @Published private(set) var dailyUsage: DailyUsage?
    @Published private(set) var rowItems: [AppUsageRowItem] = []
    @Published private(set) var categorySlices: [CategorySlice] = []
    @Published private(set) var totalMinutes: Int = 0

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
                self.categorySlices = slices
                self.rowItems = rows
                self.totalMinutes = total
                self.state = .loaded(sessions)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Formatting
    func format(dateString: String) -> String {
        // Try to parse ISO and format nicely
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: dateString) {
            let f = DateFormatter()
            f.dateStyle = .full
            return f.string(from: d)
        }
        // Fallback if just yyyy-MM-dd
        let fIn = DateFormatter()
        fIn.dateFormat = "yyyy-MM-dd"
        if let d = fIn.date(from: dateString) {
            let fOut = DateFormatter()
            fOut.dateStyle = .full
            return fOut.string(from: d)
        }
        return dateString
    }

    // MARK: - Private

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


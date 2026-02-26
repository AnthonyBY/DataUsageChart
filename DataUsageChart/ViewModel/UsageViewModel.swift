import Foundation
import Combine

enum LoadState: Equatable {
    case loading
    case loaded(DailyUsage)
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
        Task {
            do {
                let date = try makeTargetDate()
                let daily = try repository.loadDailyUsage(for: date)
                self.state = .loaded(daily)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    var totalMinutes: Int {
        switch state {
        case .loaded(let daily):
            return daily.sessionCategories.map { $0.totalMinutes }.reduce(0, +)
        default:
            return 0
        }
    }

    // MARK: - Private

    private func makeTargetDate() throws -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = formatter.date(from: targetDayString) else {
            throw RepositoryError.invalidTargetDate
        }
        return date
    }
}


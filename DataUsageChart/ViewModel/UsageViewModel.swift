import Foundation
import Combine

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var daily: DailyUsage?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false

    private let repository: UsageRepository
    private let targetDayString = "2026-02-23"

    init(repository: UsageRepository) {
        self.repository = repository
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        Task {
            defer { isLoading = false }

            do {
                let date = try makeTargetDate()
                let daily = try repository.loadDailyUsage(for: date)
                self.daily = daily
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    var totalMinutes: Int {
        guard let daily else { return 0 }
        return daily.apps.map { $0.totalMinutes }.reduce(0, +)
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


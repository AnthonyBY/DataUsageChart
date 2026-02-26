import Foundation

// MARK: - Aggregation / business logic
func aggregate(sessions: [Session], for targetDate: Date) -> DailyUsage {
    let calendar = Calendar(identifier: .gregorian)
    let daySessions = sessions

    // Group by app and accumulate total + hourly buckets
    var appBuckets: [String: (category: String?, totalMinutes: Int, hourly: [Int: Int], sessionsCount: Int)] = [:]
    for s in daySessions {
        let minutes = Int(s.endTimestamp.timeIntervalSince(s.startTimestamp) / 60)
        var entry = appBuckets[s.appName] ?? (category: s.category, totalMinutes: 0, hourly: [:], sessionsCount: 0)
        entry.category = entry.category ?? s.category
        entry.totalMinutes += minutes
        entry.sessionsCount += 1

        // Distribute minutes per hour boundaries
        var cursor = s.startTimestamp
        while cursor < s.endTimestamp {
            let hourStart = calendar.dateInterval(of: .hour, for: cursor)!.start
            let nextHour = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
            let segmentEnd = min(nextHour, s.endTimestamp)
            let segMinutes = max(0, Int(segmentEnd.timeIntervalSince(cursor) / 60))
            let hourComp = calendar.component(.hour, from: cursor)
            entry.hourly[hourComp, default: 0] += segMinutes
            cursor = segmentEnd
        }

        appBuckets[s.appName] = entry
    }

    let apps: [SessionCategory] = appBuckets.map { appName, v in
        let hourly = (0...23).map { h in HourlyUsage(hour: h, minutes: v.hourly[h] ?? 0) }
        return SessionCategory(name: v.category ?? "Other",
                               appName: appName,
                        colorHex: nil,
                        totalMinutes: v.totalMinutes,
                        sessions: v.sessionsCount,
                        hourly: hourly)
    }.sorted { $0.totalMinutes > $1.totalMinutes }

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    return DailyUsage(date: formatter.string(from: targetDate), sessionCategories: apps)
}

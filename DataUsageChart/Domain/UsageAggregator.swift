import Foundation

// MARK: - Aggregation / business logic
func aggregate(sessions: [Session], for targetDate: Date) -> DailyUsage {
    // Build day interval [start, end)
    let calendar = Calendar(identifier: .gregorian)

    let dayStart = calendar.startOfDay(for: targetDate)
    let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

    // Clip sessions to the day and fix invalid end<start entries
    let daySessions = sessions.compactMap { s -> Session? in
        let start = max(s.startTimestamp, dayStart)
        let rawEnd = max(s.endTimestamp, s.startTimestamp)
        let end = min(rawEnd, dayEnd)
        guard end > start else { return nil }
        return Session(id: s.id, appName: s.appName, category: s.category, startTimestamp: start, endTimestamp: end)
    }

    // Group by app and accumulate total + hourly buckets
    var appBuckets: [String: (category: String?, totalMinutes: Int, hourly: [Int: Int])] = [:]
    for s in daySessions {
        let minutes = Int(s.endTimestamp.timeIntervalSince(s.startTimestamp) / 60)
        var entry = appBuckets[s.appName] ?? (category: s.category, totalMinutes: 0, hourly: [:])
        entry.category = entry.category ?? s.category
        entry.totalMinutes += minutes

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

    let apps: [AppUsage] = appBuckets.map { appName, v in
        let hourly = (0...23).map { h in HourlyUsage(hour: h, minutes: v.hourly[h] ?? 0) }
        return AppUsage(app: appName, category: v.category, totalMinutes: v.totalMinutes, hourly: hourly)
    }.sorted { $0.totalMinutes > $1.totalMinutes }

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    return DailyUsage(date: formatter.string(from: targetDate), apps: apps)
}


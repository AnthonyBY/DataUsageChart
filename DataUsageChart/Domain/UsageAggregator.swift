import Foundation

// MARK: - Aggregation / business logic

/// Aggregates raw `Session` objects into a `DailyUsage` model for a specific calendar day
func aggregate(sessions: [Session], for targetDate: Date) -> DailyUsage {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!

    let dayStart = calendar.startOfDay(for: targetDate)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
        return DailyUsage(date: formatDate(targetDate), sessionCategories: [])
    }

    // Only sessions that overlap the target day
    let daySessions = sessions.filter { s in
        s.startTimestamp < dayEnd && s.endTimestamp > dayStart
    }

    // Group by app and accumulate total + hourly buckets (only minutes within the target day)
    var appBuckets: [String: (category: String, totalMinutes: Int, hourly: [Int: Int], sessionsCount: Int)] = [:]
    for s in daySessions {
        let clipStart = max(s.startTimestamp, dayStart)
        let clipEnd = min(s.endTimestamp, dayEnd)
        let minutes = max(0, Int(clipEnd.timeIntervalSince(clipStart) / 60))
        guard minutes > 0 else { continue }

        var entry = appBuckets[s.appName] ?? (category: s.category ?? "Other", totalMinutes: 0, hourly: [:], sessionsCount: 0)
        entry.totalMinutes += minutes
        entry.sessionsCount += 1

        // Distribute minutes per hour (only within day; hours 0...23 are the target day)
        var cursor = clipStart
        while cursor < clipEnd {
            let hourStart = calendar.dateInterval(of: .hour, for: cursor)!.start
            let nextHour = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
            let segmentEnd = min(nextHour, clipEnd)
            let segMinutes = max(0, Int(segmentEnd.timeIntervalSince(cursor) / 60))
            let hourComp = calendar.component(.hour, from: cursor)
            entry.hourly[hourComp, default: 0] += segMinutes
            cursor = segmentEnd
        }

        appBuckets[s.appName] = entry
    }

    let apps: [SessionCategory] = appBuckets.map { appName, v in
        let hourly = (0...23).map { h in HourlyUsage(hour: h, minutes: v.hourly[h] ?? 0) }
        return SessionCategory(name: v.category,
                               appName: appName,
                        colorHex: nil,
                        totalMinutes: v.totalMinutes,
                        sessions: v.sessionsCount,
                        hourly: hourly)
    }.sorted { $0.totalMinutes > $1.totalMinutes }

    return DailyUsage(date: formatDate(targetDate), sessionCategories: apps)
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: date)
}

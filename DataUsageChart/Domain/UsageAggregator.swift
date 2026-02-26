import Foundation

// MARK: - Aggregation / business logic

/// App list row data from raw sessions for a given day (no hourly breakdown).
func appUsageRowItems(sessions: [Session], from targetDate: Date) -> [AppUsageRowItem] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!

    let dayStart = calendar.startOfDay(for: targetDate)

    var items: [AppUsageRowItem] = []
    for session in sessions {
        let clipStart = max(session.startTimestamp, dayStart)
        let clipEnd = min(session.endTimestamp, Date())
        let minutes = max(0, Int(clipEnd.timeIntervalSince(clipStart) / 60))
        guard minutes > 0 else { continue }

        let categoryName = session.category ?? "Others"
        if let idx = items.firstIndex(where: { $0.appName == session.appName }) {
            var existing = items[idx]
            existing.totalMinutes += minutes
            existing.sessionsCount += 1
            items[idx] = existing
        } else {
            items.append(AppUsageRowItem(appName: session.appName,
                                         categoryName: categoryName,
                                         totalMinutes: minutes,
                                         sessionsCount: 1,
                                         colorHex: nil))
        }
    }

    return items.sorted { $0.totalMinutes > $1.totalMinutes }
}

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

/// Lazy-computed category breakdown from raw sessions for a given day (for pie chart).
func categoryBreakdown(sessions: [Session], for targetDate: Date) -> [CategorySlice] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!

    let dayStart = calendar.startOfDay(for: targetDate)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
        return []
    }

    let daySessions = sessions.filter { s in
        s.startTimestamp < dayEnd && s.endTimestamp > dayStart
    }

    let normalized: (String?) -> String = { name in
        guard let name, !name.isEmpty, name.lowercased() != "other" else { return "Other" }
        return name
    }

    var sumByCategory: [String: Int] = [:]
    for s in daySessions {
        let clipStart = max(s.startTimestamp, dayStart)
        let clipEnd = min(s.endTimestamp, dayEnd)
        let minutes = max(0, Int(clipEnd.timeIntervalSince(clipStart) / 60))
        guard minutes > 0 else { continue }
        let name = normalized(s.category)
        sumByCategory[name, default: 0] += minutes
    }

    return sumByCategory
        .map { CategorySlice(category: $0.key, minutes: $0.value) }
        .filter { $0.minutes > 0 }
        .sorted { $0.minutes > $1.minutes }
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: date)
}

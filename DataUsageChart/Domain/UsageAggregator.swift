//
//  UsageAggregator.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

// MARK: - Aggregation / business logic

/// Safely clips a session's interval to a target day and returns whole minutes within that clip.
/// Returns 0 if there is no overlap or if the interval is in the future relative to `now`.
private func clippedMinutes(withinDayOf targetDate: Date,
                            sessionStart: Date,
                            sessionEnd: Date,
                            calendar: Calendar,
                            now: Date = Date()) -> (minutes: Int, clipStart: Date, clipEnd: Date) {
    let dayStart = calendar.startOfDay(for: targetDate)
    guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
        return (0, dayStart, dayStart)
    }

    // Clip to the target day and to `now` to avoid counting future time
    let clipStart = max(sessionStart, dayStart)
    let clipEnd = min(sessionEnd, min(dayEnd, now))

    let minutes = max(0, Int(clipEnd.timeIntervalSince(clipStart) / 60))
    return (minutes, clipStart, clipEnd)
}

/// Normalizes category names to a consistent display value.
private func normalizedCategory(_ name: String?) -> String {
    guard let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "Other" }
    let lower = name.lowercased()
    if lower == "other" || lower == "others" { return "Other" }
    return name
}

/// App list row data from raw sessions for a given day
func appUsageRowItems(sessions: [Session], from targetDate: Date) -> [AppUsageRowItem] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!

    var items: [AppUsageRowItem] = []
    for session in sessions {
        let result = clippedMinutes(withinDayOf: targetDate,
                                    sessionStart: session.startTimestamp,
                                    sessionEnd: session.endTimestamp,
                                    calendar: calendar)
        let minutes = result.minutes
        guard minutes > 0 else { continue }

        let categoryName = normalizedCategory(session.category)
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

/// Aggregates raw `Session` objects into a `CategorySlice` from targetDate
func categoryBreakdown(sessions: [Session], from targetDate: Date) -> [CategoryPieSlice] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!

    let dayStart = calendar.startOfDay(for: targetDate)

    // Only sessions that intersect the target day
    let daySessions = sessions.filter { s in
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return false }
        return s.startTimestamp < dayEnd && s.endTimestamp > dayStart
    }

    var slices: [CategoryPieSlice] = []
    for session in daySessions {
        let result = clippedMinutes(withinDayOf: targetDate,
                                    sessionStart: session.startTimestamp,
                                    sessionEnd: session.endTimestamp,
                                    calendar: calendar)
        let minutes = result.minutes
        guard minutes > 0 else { continue }

        let name = normalizedCategory(session.category)
        if let idx = slices.firstIndex(where: { $0.category == name }) {
            var existing = slices[idx]
            existing.minutes += minutes
            slices[idx] = existing
        } else {
            slices.append(CategoryPieSlice(category: name, minutes: minutes))
        }
    }

    return slices
        .filter { $0.minutes > 0 }
        .sorted { $0.minutes > $1.minutes }
}

/// Aggregates raw `Session` objects into a `DailyUsage` model for a specific calendar day (can be used for Bar Hours Chart)
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
        let result = clippedMinutes(withinDayOf: targetDate,
                                    sessionStart: s.startTimestamp,
                                    sessionEnd: s.endTimestamp,
                                    calendar: calendar)
        let minutes = result.minutes
        guard minutes > 0 else { continue }

        var entry = appBuckets[s.appName] ?? (category: normalizedCategory(s.category), totalMinutes: 0, hourly: [:], sessionsCount: 0)
        entry.totalMinutes += minutes
        entry.sessionsCount += 1

        // Distribute minutes per hour (only within day; hours 0...23 are the target day)
        var cursor = result.clipStart
        while cursor < result.clipEnd {
            let hourStart = calendar.dateInterval(of: .hour, for: cursor)!.start
            let nextHour = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
            let segmentEnd = min(nextHour, result.clipEnd)
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

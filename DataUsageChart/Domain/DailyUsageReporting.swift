//
//  DailyUsageReporting.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

// MARK: - Domain service 

/// Domain service that derives daily usage, breakdowns, and totals from raw sessions.
enum DailyUsageReporting {

    /// Total minutes of usage on the target day (sessions clipped to that day).
    static func totalMinutes(sessions: [Session], from targetDate: Date) -> Int {
        let calendar = Self.calendar
        let dayStart = calendar.startOfDay(for: targetDate)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }
        let validSessions = sessions.filter { Self.hasValidTimestamps($0) }
        let daySessions = validSessions.filter { s in s.startTimestamp! < dayEnd && s.endTimestamp! > dayStart }
        return daySessions.reduce(0) { sum, s in
            sum + Self.clippedMinutes(withinDayOf: targetDate, session: s, calendar: calendar).minutes
        }
    }

    /// Daily usage model for the target day (for bar chart and date label).
    static func dailyUsage(sessions: [Session], for targetDate: Date) -> DailyUsage {
        let calendar = Self.calendar
        let dayStart = calendar.startOfDay(for: targetDate)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return DailyUsage(date: Self.formatDate(targetDate), sessionCategories: [])
        }
        let validSessions = sessions.filter { Self.hasValidTimestamps($0) }
        let daySessions = validSessions.filter { s in s.startTimestamp! < dayEnd && s.endTimestamp! > dayStart }

        var appBuckets: [String: (category: String, totalMinutes: Int, hourly: [Int: Int], sessionsCount: Int)] = [:]
        for s in daySessions {
            guard let appName = Self.normalizedAppName(s.appName) else { continue }
            let result = Self.clippedMinutes(withinDayOf: targetDate, session: s, calendar: calendar)
            guard result.minutes > 0 else { continue }

            var entry = appBuckets[appName] ?? (category: Self.normalizedCategory(s.category), totalMinutes: 0, hourly: [:], sessionsCount: 0)
            entry.totalMinutes += result.minutes
            entry.sessionsCount += 1
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
            appBuckets[appName] = entry
        }

        let apps: [SessionCategory] = appBuckets.map { appName, v in
            let hourly = (0...23).map { h in HourlyUsage(hour: h, minutes: v.hourly[h] ?? 0) }
            return SessionCategory(name: v.category, appName: appName, colorHex: nil, totalMinutes: v.totalMinutes, sessions: v.sessionsCount, hourly: hourly)
        }.sorted { $0.totalMinutes > $1.totalMinutes }

        return DailyUsage(date: Self.formatDate(targetDate), sessionCategories: apps)
    }

    /// Category breakdown for the pie chart.
    static func categoryBreakdown(sessions: [Session], from targetDate: Date) -> [CategoryPieSlice] {
        let calendar = Self.calendar
        let dayStart = calendar.startOfDay(for: targetDate)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        let validSessions = sessions.filter { Self.hasValidTimestamps($0) }
        let daySessions = validSessions.filter { s in s.startTimestamp! < dayEnd && s.endTimestamp! > dayStart }

        var slices: [CategoryPieSlice] = []
        for session in daySessions {
            let result = Self.clippedMinutes(withinDayOf: targetDate, session: session, calendar: calendar)
            guard result.minutes > 0 else { continue }
            let name = Self.normalizedCategory(session.category)
            if let idx = slices.firstIndex(where: { $0.category == name }) {
                var existing = slices[idx]
                existing.minutes += result.minutes
                slices[idx] = existing
            } else {
                slices.append(CategoryPieSlice(category: name, minutes: result.minutes))
            }
        }
        return slices.filter { $0.minutes > 0 }.sorted { $0.minutes > $1.minutes }
    }

    /// App list row items for the target day.
    static func appUsageRowItems(sessions: [Session], from targetDate: Date) -> [AppUsageRowItem] {
        let calendar = Self.calendar
        let validSessions = sessions.filter { Self.hasValidTimestamps($0) }
        var items: [AppUsageRowItem] = []
        for session in validSessions {
            guard let appName = Self.normalizedAppName(session.appName) else { continue }
            let result = Self.clippedMinutes(withinDayOf: targetDate, session: session, calendar: calendar)
            guard result.minutes > 0 else { continue }
            let categoryName = Self.normalizedCategory(session.category)
            if let idx = items.firstIndex(where: { $0.appName == appName }) {
                var existing = items[idx]
                existing.totalMinutes += result.minutes
                existing.sessionsCount += 1
                items[idx] = existing
            } else {
                items.append(AppUsageRowItem(appName: appName, categoryName: categoryName, totalMinutes: result.minutes, sessionsCount: 1, colorHex: nil))
            }
        }
        return items.sorted { $0.totalMinutes > $1.totalMinutes }
    }

    // MARK: - Private helpers

    private static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private static func clippedMinutes(withinDayOf targetDate: Date, session: Session, calendar: Calendar, now: Date = Date()) -> (minutes: Int, clipStart: Date, clipEnd: Date) {
        let dayStart = calendar.startOfDay(for: targetDate)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return (0, dayStart, dayStart)
        }
        guard let start = session.startTimestamp, let end = session.endTimestamp else {
            return (0, dayStart, dayStart)
        }
        let clipStart = max(start, dayStart)
        let clipEnd = min(end, min(dayEnd, now))
        let minutes = max(0, Int(clipEnd.timeIntervalSince(clipStart) / 60))
        return (minutes, clipStart, clipEnd)
    }

    /// Session is used only if both timestamps are non-nil and endTimestamp > startTimestamp.
    private static func hasValidTimestamps(_ s: Session) -> Bool {
        guard let start = s.startTimestamp, let end = s.endTimestamp else { return false }
        return end > start
    }

    private static func normalizedCategory(_ name: String?) -> String {
        guard let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "Other" }
        let lower = name.lowercased()
        if lower == "other" || lower == "others" { return "Other" }
        return name
    }

    /// Normalizes app name; returns nil if it's effectively empty so such sessions can be skipped.
    private static func normalizedAppName(_ name: String?) -> String? {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return nil
        }
        return name
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}

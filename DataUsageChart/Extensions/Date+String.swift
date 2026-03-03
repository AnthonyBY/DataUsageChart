//
//  Date+String.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 3/3/26.
//

import Foundation

public extension String {
    /// Attempts to parse the string as an ISO8601 or "yyyy-MM-dd" date and returns a full-style localized date string.
    /// If parsing fails, returns the original string.
    func formattedAsFullDateDisplay() -> String {
        if let d = _DateStringFormatters.iso8601.date(from: self) {
            return _DateStringFormatters.full.string(from: d)
        }
        if let d = _DateStringFormatters.yyyyMMdd.date(from: self) {
            return _DateStringFormatters.full.string(from: d)
        }
        return self
    }
}

private enum _DateStringFormatters {
    static let iso8601: ISO8601DateFormatter = ISO8601DateFormatter()

    static let full: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }()

    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
}

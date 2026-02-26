//
//  Int+hoursMinutes.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation

extension Int {
    /// Returns a formatted string representing the integer value (in minutes)
    /// as hours and minutes (e.g., "2h 15m" or "45m").
    var hoursMinutesString: String {
        let h = self / 60
        let m = self % 60
        if h > 0 { return String(format: "%dh %dm", h, m) }
        return String(format: "%dm", m)
    }
}

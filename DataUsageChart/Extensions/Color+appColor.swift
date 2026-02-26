//
//  Color+appColor.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import SwiftUI

extension Color {
    /// Returns a color from a hex string if provided, otherwise a deterministic fallback based on a key (e.g., app name).
    /// - Parameters:
    ///   - hex: Optional hex string (e.g., "#FFAA00" or "FFAA00").
    ///   - key: A stable string used to compute a deterministic fallback color.
    static func appColor(hex: String?, key: String) -> Color {
        if let hex, let c = Color(hex: hex) { return c }
        // Deterministic fallback color based on the key's hash
        let hash = abs(key.hashValue)
        let hue = Double(hash % 256) / 255.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.9)
    }
    
}

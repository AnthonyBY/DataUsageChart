//
//  AppUsageRowView.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import SwiftUI

struct AppUsageRowView: View {
    let appUsage: AppUsage
    let total: Int
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text(appUsage.app)
                    .font(.body)

                ProgressView(value: Double(appUsage.totalMinutes), total: Double(total))
                    .progressViewStyle(.linear)
                    .tint(color(for: appUsage.colorHex, app: appUsage.app))
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                HStack(spacing: 0) {
                    Text(appUsage.category ?? "Other")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(", ")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(appUsage.sessionsText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()

            VStack(alignment: .trailing) {
                Text(appUsage.totalMinutes.hoursMinutesString)
                    .font(.body)
                    .monospacedDigit()
                Text(percentage(appUsage.totalMinutes, of: total))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 40, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }

    private func percentage(_ part: Int, of total: Int) -> String {
        guard total > 0 else { return "0%" }
        let p = (Double(part) / Double(total)) * 100
        return String(format: "%.0f%%", p)
    }

    private func color(for hex: String?, app: String) -> Color {
        if let hex, let c = Color(hex: hex) { return c }
        // deterministic fallback color per app name
        let hash = abs(app.hashValue)
        let hue = Double(hash % 256) / 255.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.9)
    }
}

#Preview {
    VStack {
        AppUsageRowView(appUsage: AppUsage.preview, total: 300)
    }
}

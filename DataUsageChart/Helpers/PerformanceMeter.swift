import Foundation
import os

enum PerformanceMeter {
    private static let logger = Logger(subsystem: "DataUsageChart", category: "Performance")

    @discardableResult
    static func measure<T>(_ label: String, _ block: () -> T) -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let value = block()
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1_000
        logger.info("\(label, privacy: .public) took \(elapsedMs, format: .fixed(precision: 2), privacy: .public) ms")
        return value
    }
}

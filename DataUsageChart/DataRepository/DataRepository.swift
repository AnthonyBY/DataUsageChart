//
//  DataRepository.swift
//  DataUsageChart
//
//  Created by Anton Marchanka on 2/26/26.
//

import Foundation
import SwiftUI

// MARK: - Repository protocol
@MainActor
protocol DataRepositoryProtocol {
    func loadSessions() throws -> [Session]
}

// MARK: - Local JSON implementation
@MainActor
struct DataRepository: DataRepositoryProtocol {
    private let fileName: String

    init(fileName: String = "mock-data") {
        self.fileName = fileName
    }

    func loadSessions() throws -> [Session] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw RepositoryError.fileNotFound("\(fileName).json not found in bundle")
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Session].self, from: data)
    }
}

// MARK: - Errors
enum RepositoryError: LocalizedError {
    case fileNotFound(String)
    case invalidTargetDate

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let message):
            return message
        case .invalidTargetDate:
            return "Invalid target date"
        }
    }
}

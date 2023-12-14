//
//  GeorgError.swift
//  Georg
//
//  Created by Michael Rockhold on 12/8/23.
//

import Foundation

enum GeorgError: Error {
    case wrongDataFormat(error: Error)
    case creationError
    case batchInsertError
    case batchDeleteError
    case persistentHistoryChangeError
    case unexpectedError(error: Error)
}

extension GeorgError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .wrongDataFormat(let error):
            return NSLocalizedString("Could not digest the fetched data. \(error.localizedDescription)", comment: "")
        case .creationError:
            return NSLocalizedString("Failed to create a new Georg object.", comment: "")
        case .batchInsertError:
            return NSLocalizedString("Failed to execute a batch insert request.", comment: "")
        case .batchDeleteError:
            return NSLocalizedString("Failed to execute a batch delete request.", comment: "")
        case .persistentHistoryChangeError:
            return NSLocalizedString("Failed to execute a persistent history change request.", comment: "")
        case .unexpectedError(let error):
            return NSLocalizedString("Received unexpected error. \(error.localizedDescription)", comment: "")
        }
    }
}

extension GeorgError: Identifiable {
    var id: String? {
        errorDescription
    }
}

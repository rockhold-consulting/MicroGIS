//
//  MicroGISError.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 12/8/23.
//

import Foundation

enum MicroGISError: Error {
    case wrongDataFormat(error: Error)
    case creationError
    case batchInsertError
    case batchDeleteError
    case persistentHistoryChangeError
    case unexpectedError(error: Error)
    case documentCreationError(error: Error)
    case malformedReadConfiguration
    case malformedWriteConfiguration(error: Error)
    case missingData
    case importError(error: Error)
}


extension MicroGISError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .documentCreationError(let error):
            return NSLocalizedString("Failed to create Core Data stack for document. \(error.localizedDescription)", comment: "")
        case .malformedReadConfiguration:
            return NSLocalizedString("Could not create file wrapper with provided Read configuration.", comment: "")
        case .malformedWriteConfiguration(let error):
            return NSLocalizedString("Could not create filewrapper with provided Write configuration. \(error.localizedDescription)", comment: "")
        case .importError(let error):
            return NSLocalizedString("Could not import the chosen data file. \(error.localizedDescription)", comment: "")
        case .wrongDataFormat(let error):
            return NSLocalizedString("Could not digest the fetched data. \(error.localizedDescription)", comment: "")
        case .missingData:
            return NSLocalizedString("Found and will discard a malformed or incomplete feature.", comment: "")
        case .creationError:
            return NSLocalizedString("Failed to create a new feature or geometry object.", comment: "")
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

extension MicroGISError: Identifiable {
    var id: String? {
        errorDescription
    }
}

//
//  GeoObject+.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData

extension NSManagedObjectID {
    @objc var shortName: String {
        let uri = self.uriRepresentation().lastPathComponent
        return uri.isEmpty ? "---" : uri
    }
}

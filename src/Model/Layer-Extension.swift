//
//  Layer-Extension.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData

extension Layer {
    convenience init(ctx: NSManagedObjectContext, name: String, importDate: Date) {
        self.init(context: ctx)
        self.name = name
        self.importDate = importDate
    }
}

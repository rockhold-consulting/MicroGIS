//
//  FeatureCollection-Extension.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData

extension FeatureCollection {
    convenience init(ctx: NSManagedObjectContext, stylesheet: Stylesheet, creationDate: Date, name: String? = nil) {
        self.init(context: ctx)
        self.stylesheet = stylesheet
        self.creationDate = creationDate
        if let n = name {
            self.name = n
        }
    }
}

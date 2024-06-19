//
//  Stylesheet-Extension.swift
//  Georg
//
//  Created by Michael Rockhold on 7/7/24.
//

import Foundation
import CoreData

extension Stylesheet {
    convenience init(ctx: NSManagedObjectContext, name: String) {
        self.init(context: ctx)
        self.name = name
    }
}

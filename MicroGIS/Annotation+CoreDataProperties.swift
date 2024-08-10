//
//  Annotation+CoreDataProperties.swift
//  Georg
//
//  Created by Michael Rockhold on 10/30/23.
//
//

import Foundation
import CoreData


extension Annotation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Annotation> {
        return NSFetchRequest<Annotation>(entityName: "Annotation")
    }

    @NSManaged public var coordinate: SerializableCoordinate?
    @NSManaged public var title: String?
    @NSManaged public var subtitle: String?

}

extension Annotation : Identifiable {

}

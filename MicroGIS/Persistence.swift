//
//  Persistence.swift
//  MicroGIS
//
// Copyright 2024, Michael Rockhold (dba Rockhold Software)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// The license is provided with this work, or you may obtain a copy
// of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Michael Rockhold on 7/4/24.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "MicroGIS")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                // TODO: Replace this implementation with code to handle the error appropriately.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true

        let fr = NSFetchRequest<Stylesheet>(entityName: "Stylesheet")
        if let results = try? container.viewContext.fetch(fr) {
            if results.isEmpty {
                container.viewContext.insert(Stylesheet(ctx: container.viewContext, name: "Default"))
            }
        } else {
            fatalError()
        }
    }

    func defaultStylesheet() -> Stylesheet {
        let fr = NSFetchRequest<Stylesheet>(entityName: "Stylesheet")
        fr.predicate = NSPredicate(format: "name == 'Default'")
        if let results = try? container.viewContext.fetch(fr) {
            if results.isEmpty {
                fatalError()
            } else {
                return results[0]
            }
        } else {
            fatalError()
        }
    }

    func importFeaturesFile(url: URL) {

        let ext = url.pathExtension
        switch ext.uppercased() {
        case "GEOJSON":
            let _ = MicroGISMKGeoJSONFeatureSource(importContext: self.container.viewContext).importFeatureCollection(from: url)
        default:
            break
        }
        do {
            try self.container.viewContext.save()
        } catch {
            // TODO: Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

}

extension FeatureCollection {
    var currentStylesheet: Stylesheet {
        if self.stylesheet == nil {
            self.stylesheet = PersistenceController.shared.defaultStylesheet()
        }
        return self.stylesheet!
    }
}

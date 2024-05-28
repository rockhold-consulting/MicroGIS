//
//  dataappApp.swift
//  dataapp
//
//  Created by Michael Rockhold on 5/27/24.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct dataappApp: App {
    var body: some Scene {
        DocumentGroup(editing: .itemDocument, migrationPlan: dataappMigrationPlan.self) {
            ContentView()
        }
    }
}

extension UTType {
    static var itemDocument: UTType {
        UTType(importedAs: "com.example.item-document")
    }
}

struct dataappMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        dataappVersionedSchema.self,
    ]

    static var stages: [MigrationStage] = [
        // Stages of migration between VersionedSchema, if required.
    ]
}

struct dataappVersionedSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] = [
        Item.self,
    ]
}

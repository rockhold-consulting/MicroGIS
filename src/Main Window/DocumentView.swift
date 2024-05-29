//
//  DocumentView.swift
//  Georg
//
//  Created by Michael Rockhold on 5/16/24.
//

import SwiftUI
import CoreData

struct DocumentView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest<Feature>(
        sortDescriptors: [
            SortDescriptor(\Feature.parent!.importDate!, order: .forward),
            SortDescriptor(\Feature.objectID.shortName)
        ]
    )
    private var features: FetchedResults<Feature>
    @State private var selection: Set<NSManagedObjectID> = []
    @State private var path: [Feature] = []

    var body: some View {
        NavigationSplitView {
            Sidebar(features: features, selection: $selection)
        } detail: {
            NavigationStack(path: $path) {
                MainContent(moc: moc, features: features, selection: $selection)
                .navigationDestination(for: Feature.self) { feature in
                    FeatureDetails(feature: feature, path: $path)
                }
            }
        }
        .navigationSplitViewStyle(.automatic)
    }
}

#Preview {
    DocumentView()
}

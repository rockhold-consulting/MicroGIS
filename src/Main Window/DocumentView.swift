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

    var body: some View {
        NavigationSplitView {
            Sidebar(features: features, selection: $selection)
        } detail: {
            MainContent(moc: moc, features: features, selection: $selection)
        }
        .navigationSplitViewStyle(.automatic)
    }
}

#Preview {
    DocumentView()
}

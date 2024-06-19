//
//  DocumentView.swift
//  Georg
//
//  Created by Michael Rockhold on 5/16/24.
//

import SwiftUI
import CoreData

enum Selectable: Hashable {
    case stylesheet(Stylesheet)
    case featureCollection(FeatureCollection)
}

struct DocumentView: View {

    @State private var selection: Selectable? = nil
    @State private var path = NavigationPath()

    @Environment(\.managedObjectContext) var moc

    @FetchRequest<Stylesheet>(sortDescriptors: [SortDescriptor(\.name)])
    private var stylesheets: FetchedResults<Stylesheet>

    @FetchRequest<FeatureCollection>(sortDescriptors: [SortDescriptor(\.creationDate)])
    private var featureCollections: FetchedResults<FeatureCollection>

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    ForEach(stylesheets, id: \.id) { stylesheet in
                        NavigationLink(value: Selectable.stylesheet(stylesheet)) {
                            Label(stylesheet.name ?? "-", systemImage: "paintpalette")
                        }
                    }
                } header: {
                    Text("Style Rules")
                }
                Section {
                    ForEach(featureCollections, id: \.id) { featureCollection in
                        NavigationLink(value: Selectable.featureCollection(featureCollection)) {
                            Label(featureCollection.name ?? "-", systemImage: "rectangle.3.group")
                        }
                    }
                } header: {
                    Text("Feature Collections")
                }
            }
            .navigationTitle("Main Menu")
    #if os(macOS)
            .navigationSplitViewColumnWidth(280)
    #endif
        } detail: {
            NavigationStack(path: $path) {
                if let sel = selection {
                    switch sel {
                    case .featureCollection(let fc):
                        FeatureCollectionView(featureCollection: fc)
                    case .stylesheet(let ss):
                        StylesheetView(stylesheet: ss)
                    }
                } else {
                    Text("Make a selection in the sidebar.")
                }
            }
        }
    }
}

#Preview {
    DocumentView()
}

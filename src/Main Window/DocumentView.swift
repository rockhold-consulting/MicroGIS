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
            List(selection: $selection) {
                ForEach(features, id: \.self.objectID) { feature in
                    FeatureRow(feature: feature)
                }
            }
            .navigationTitle("Features")
            .navigationSplitViewColumnWidth(280)
        } detail: {
            MRMap(selection: $selection)
                .onTapGesture {
                    print("TAPPED ON MAP")
                }
            List(selection.compactMap({ objID in
                return moc.object(with: objID) as? Feature
            })) { selected in
                FeatureDetails(feature: selected)
            }
            Spacer()
        }
        .navigationSplitViewStyle(.automatic)
//        .task {
//
//            let s = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { t in
//                let f = features[0]
//                moc.delete(f)
//            }
//        }
    }
}

#Preview {
    DocumentView()
}

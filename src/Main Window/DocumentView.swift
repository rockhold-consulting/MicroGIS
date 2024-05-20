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
    @State private var selection: Set<Feature> = []

    var body: some View {

        NavigationSplitView {
            List(features, id: \.self, selection: $selection) { feature in
                FeatureRow(feature: feature)
            }
            .navigationTitle("Features")
            .navigationSplitViewColumnWidth(280)
        } detail: {
            MRMap(features: features, selection: $selection)
                .onTapGesture {
                    print("TAPPED ON MAP")
                }
//            RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
//                .fill()
            List(Array(selection)) { selectedFeature in
                FeatureDetails(feature: selectedFeature)
            }
            Spacer()
        }
        .navigationSplitViewStyle(.automatic)
    }
}

#Preview {
    DocumentView()
}

//
//  DocumentView.swift
//  Georg
//
//  Created by Michael Rockhold on 5/16/24.
//

import SwiftUI

struct DocumentView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var features: FetchedResults<Feature>

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
//            RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
//                .fill()
            List(Array(selection)) { selectedFeature in
                FeatureDetails(feature: selectedFeature)
            }
            Spacer()
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    DocumentView()
}

//
//  MainContent.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 5/22/24.
//

import SwiftUI
import CoreData
import SplitView

struct FeatureCollectionView: View {
    var geometries: [Geometry]
    var columns: [PropertyColumn]
    @Binding var selection: Set<Geometry>
    @State var searchText = ""

    var body: some View {

        VSplit(
            top: { MRMap(geometries: geometries, selection: $selection)},

            bottom: { HSplit(
                left: { GeometriesTable(geometries: geometries,
                                        columns: columns,
                                        selection: $selection,
                                        searchText: $searchText) },
                
                right: { GeometryInfo(geometries: $selection)}
            )}
        )
    }
}

//#Preview {
//    FeatureCollectionView(featureCollection: FeatureCollection())
//}

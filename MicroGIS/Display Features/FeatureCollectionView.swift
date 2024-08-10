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
    var columns: [String]
    @Binding var selection: Set<Geometry>
    @State var searchText = ""

    var body: some View {

        VStack {
            MRMap(geometries: geometries, selection: $selection)
            HStack {
                GeometriesTable(geometries: geometries,
                                    columns: columns,
                                    selection: $selection,
                                    searchText: $searchText)

                GeometriesInfo(geometries: selection)
            }
        }
    }
}

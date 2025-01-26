//
//  DetailView.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 11/1/24.
//

import SwiftUI

struct DetailView: View {
    @Binding var geometries: Set<Geometry>

    var body: some View {
        switch geometries.count {
        case 0:
            Text("Select geometries in the table or the map.")
        case 1:
            ScrollView {
                GeometryInfo(geometry: geometries.first!)
            }
        default:
            Text("Multiple selection: yet to be implemented")
        }


//        switch selectedSidebarItems.count {
//        case 0:
//            Text("Select a feature collection or stylesheet in the sidebar.")
//        case 1:
//            switch selectedSidebarItems.first! {
//            case .Stylesheet(let stylesheet):
//                Text("Stylesheet \(stylesheet.name ?? "--")")
//
//            case .FeatureCollection(let featureCollection):
//                FeatureCollectionView(context: viewContext,
//                                      featureCollections: [featureCollection])
//                .id(collectionsHash([featureCollection]))
//            }
//        default:
//            // if the sidebar-selection is all just FeatureCollection,
//            // display all the features of each together
//            let selectedFeatureCollections = allFeatureCollections(selectedSidebarItems)
//            switch selectedFeatureCollections.count {
//            case 0:
//                Text("Multiple items selected.")
//            default:
//                FeatureCollectionView(context: viewContext,
//                                      featureCollections: selectedFeatureCollections)
//                .id(collectionsHash(selectedFeatureCollections))
//            }
//        }
    }
}

//#Preview {
//    DetailView()
//}

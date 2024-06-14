//
//  MainContent.swift
//  Georg
//
//  Created by Michael Rockhold on 5/22/24.
//

import SwiftUI

struct MainContent: View {
    let moc: NSManagedObjectContext
    @Binding var selection: Set<NSManagedObjectID>
    @State private var searchText = ""

    var body: some View {
        VStack {
            MRMap(selection: $selection)
            GeometriesTable(managedObjectContext: moc, features: featuresFromSelection(), searchText: searchText)
        }
    }

    func featuresFromSelection() -> [Feature] {
        return selection.compactMap { fID in
            return moc.object(with: fID) as? Feature
        }
    }
}

//#Preview {
//    MainContent()
//}

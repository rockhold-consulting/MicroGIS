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

    var body: some View {
        VStack {
            MRMap(selection: $selection)
            FeatureTable(managedObjectContext: moc, features: featuresFromSelection())
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

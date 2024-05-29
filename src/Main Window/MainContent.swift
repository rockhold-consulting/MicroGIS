//
//  MainContent.swift
//  Georg
//
//  Created by Michael Rockhold on 5/22/24.
//

import SwiftUI

struct MainContent: View {
    let moc: NSManagedObjectContext
    let features: FetchedResults<Feature>
    @Binding var selection: Set<NSManagedObjectID>

    var body: some View {
        VStack {
            MRMap(selection: $selection)
            FeatureTable(managedObjectContext: moc, featureIDs: selection)
        }
    }
}

//#Preview {
//    MainContent()
//}

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
            HStack {
                FeatureTable(managedObjectContext: moc, featureIDs: selection)
                Spacer()
            }
        }
        Spacer()
    }
}

//#Preview {
//    MainContent()
//}

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
        MRMap(selection: $selection)
        List(selection.compactMap({ objID in
            return moc.object(with: objID) as? Feature
        })) { selected in
            FeatureDetails(feature: selected)
        }
        Spacer()
    }
}

//#Preview {
//    MainContent()
//}

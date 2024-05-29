//
//  FeatureDetails.swift
//  Georg
//
//  Created by Michael Rockhold on 5/28/24.
//

import SwiftUI

struct FeatureDetails: View {

    var feature: Feature
    @Binding var path: [Feature]

    var body: some View {
        GroupBox {

            


            Button {
               path.removeLast()
            } label: {
                HStack {
                    Image(systemName: "chevron.left.circle")
                    Text("Back")
                }
            }
        } label: {
            Text(feature.objectID.shortName)
        }
        .buttonBorderShape(.roundedRectangle)
    }
}

//#Preview {
//    FeatureDetails(feature: Feature(), path: [Feature]())
//}

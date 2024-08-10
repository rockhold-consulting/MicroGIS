//
//  FeatureInfoView.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 8/28/24.
//

import SwiftUI


struct FeatureInfoView: View {
    private let feature: Feature
    private let saver: ()->Void
    @State var featureID: String
    @State var notes: String

    init(feature: Feature, saver: @escaping ()->Void) {
        self.feature = feature
        self.saver = saver
        self.notes = feature.notes ?? ""
        self.featureID = self.feature.featureID ?? ""
    }

    var body: some View {
        TextField("ID", text: $featureID)
            .onChange(of: featureID) { fID in
                feature.featureID = fID
                saver()
            }
            .disableAutocorrection(true)

        TextField("Notes", text: $notes)
            .lineLimit(4)
            .onChange(of: notes) { fNotes in
                feature.notes = fNotes
                saver()
            }
    }
}

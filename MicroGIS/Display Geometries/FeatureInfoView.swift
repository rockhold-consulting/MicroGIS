//
//  FeatureInfoView.swift
//  MicroGIS
//
//  Copyright 2024, Michael Rockhold (dba Rockhold Software)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  The license is provided with this work, or you may obtain a copy
//  of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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

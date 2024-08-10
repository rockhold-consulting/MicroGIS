//
//  OtherField.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 8/27/24.
//

import SwiftUI

struct OtherField: View {
    @State private var value: String
    private let featureProperty: FeatureProperty
    private let submitter: ()->Void
    private static let jsonValueFormatter = JSONValueFormatter()

    init(featureProperty: FeatureProperty, submitter: @escaping ()->Void) {
        // TODO: implement this for real; display the JSON code, use a formatter to enforce correctness of modifications
        self.value = "?"
        self.featureProperty = featureProperty
        self.submitter = submitter
    }

    var body: some View {
        TextField(text: $value) {
            Text(self.featureProperty.key!)
        }
        .disabled(true)
        .onChange(of: value) { v in
//            featureProperty.value = JSONEncoder etc
            submitter()
        }
    }
}

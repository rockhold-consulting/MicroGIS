//
//  StringTextField.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 8/27/24.
//

import SwiftUI


struct StringField: View {
    @State private var value: String
    private let featureProperty: StringFeatureProperty
    private let submitter: ()->Void

    init(stringFeatureProperty: StringFeatureProperty, submitter: @escaping ()->Void) {
        self.featureProperty = stringFeatureProperty
        self.value = stringFeatureProperty.value!
        self.submitter = submitter
    }

    var body: some View {
        TextField(text: $value) {
            Text(featureProperty.key!)
        }
        .onChange(of:value) { v in
            featureProperty.value = v
            submitter()
        }
    }
}

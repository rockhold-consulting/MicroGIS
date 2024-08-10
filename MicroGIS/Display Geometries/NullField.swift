//
//  NullField.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 8/27/24.
//

import SwiftUI

struct NullField: View {
    @State private var value: String
    private let featureProperty: NullFeatureProperty
    private let submitter: ()->Void

    init(nullFeatureProperty: NullFeatureProperty, submitter: @escaping ()->Void) {
        self.value = "null"
        self.featureProperty = nullFeatureProperty
        self.submitter = submitter
    }

    var body: some View {
        TextField(text: $value) {
            Text(self.featureProperty.key!)
        }
        .disabled(true)
        .onChange(of: value) { v in
//            featureProperty.value = v
            submitter()
        }
    }
}

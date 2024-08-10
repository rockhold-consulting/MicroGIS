//
//  IntField.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 8/27/24.
//

import SwiftUI

struct IntField: View {
    @State private var value: Int
    private let featureProperty: IntFeatureProperty
    private let submitter: ()->Void

    init(intFeatureProperty: IntFeatureProperty, submitter: @escaping ()->Void) {
        self.featureProperty = intFeatureProperty
        self.value = Int(intFeatureProperty.value)
        self.submitter = submitter
    }

    var body: some View {
        TextField(value: $value, format: IntegerFormatStyle()) {
            Text(featureProperty.key!)
        }
        .disableAutocorrection(true)
        .onChange(of: value) { v in
            self.featureProperty.value = Int64(v)
            self.submitter()
        }
    }
}

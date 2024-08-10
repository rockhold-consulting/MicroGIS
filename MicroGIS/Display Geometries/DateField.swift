//
//  DateField.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 8/27/24.
//

import SwiftUI

struct DateField: View {
    @State private var value: Date = .now
    private let featureProperty: DateFeatureProperty
    private let submitter: ()->Void

    init(dateFeatureProperty: DateFeatureProperty, submitter: @escaping ()->Void) {
        self.featureProperty = dateFeatureProperty
        self.submitter = submitter
        self.value = dateFeatureProperty.value!
    }

    var body: some View {
        TextField(value: $value, format: .iso8601) {
            Text(featureProperty.key!)
        }
        .disableAutocorrection(true)
        .onChange(of: value) { v in
            featureProperty.value = v
            submitter()
        }
    }
}

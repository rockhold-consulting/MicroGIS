//
//  DoubleField.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 8/27/24.
//

import SwiftUI

struct DoubleField: View {
    @State private var value: Double
    private let featureProperty: DoubleFeatureProperty
    private let submitter: ()->Void

    init(doubleFeatureProperty: DoubleFeatureProperty, submitter: @escaping ()->Void) {
        self.featureProperty = doubleFeatureProperty
        self.value = doubleFeatureProperty.value
        self.submitter = submitter
    }

    var body: some View {
        TextField(value: $value,
                  format: .number.precision(Decimal.FormatStyle.Configuration.Precision.fractionLength(0..<9))) {
            Text(featureProperty.key!)
        }
        .disableAutocorrection(true)
        .onChange(of: value) { v in
            featureProperty.value = v
            submitter()
        }
    }
}

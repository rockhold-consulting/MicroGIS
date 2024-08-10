//
//  BoolField.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 8/27/24.
//

import SwiftUI

struct BoolField: View {
    @State private var value: Bool
    private let boolFeatureProperty: BoolFeatureProperty
    private let submitter: ()->Void

    init(boolFeatureProperty: BoolFeatureProperty, submitter: @escaping ()->Void) {
        self.boolFeatureProperty = boolFeatureProperty
        self.value = boolFeatureProperty.value
        self.submitter = submitter
    }

    var body: some View {
        Toggle(boolFeatureProperty.key!, isOn: $value)
            .onChange(of: value) { v in
                boolFeatureProperty.value = v
                submitter()
            }
    }
}


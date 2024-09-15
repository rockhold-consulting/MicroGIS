//
//  IntField.swift
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

//
//  FeatureProperty-Extension.swift
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
//  Created by Michael Rockhold on 8/19/24.
//

import Foundation
import CoreData

extension FeatureProperty {
    convenience init(context: NSManagedObjectContext, key: String) {
        self.init(context: context)
        self.key = key
    }
}

extension NullFeatureProperty {
    convenience init(context: NSManagedObjectContext, key: String, nullValue: NSNull) {
        self.init(context: context, key: key)
        self.setValue(NSNull(), forKey: "value")
    }
}

extension StringFeatureProperty {
    convenience init(context: NSManagedObjectContext, key: String, stringValue: String) {
        self.init(context: context, key: key)
        self.setValue(stringValue, forKey: "value")
    }
}

extension BoolFeatureProperty {
    convenience init(context: NSManagedObjectContext, key: String, boolValue: Bool) {
        self.init(context: context, key: key)
        self.setValue(boolValue, forKey: "value")
    }
}

extension IntFeatureProperty {
    convenience init(context: NSManagedObjectContext, key: String, integerValue: Int) {
        self.init(context: context, key: key)
        self.setValue(Int64(integerValue), forKey: "value")
    }
}

extension DoubleFeatureProperty {
    convenience init(context: NSManagedObjectContext, key: String, doubleValue: Double) {
        self.init(context: context, key: key)
        self.setValue(doubleValue, forKey: "value")
    }
}

extension DateFeatureProperty {
    convenience init(context: NSManagedObjectContext, key: String, dateValue: Date) {
        self.init(context: context, key: key)
        self.value = dateValue
        self.setValue(dateValue, forKey: "value")
    }
}

extension BlobFeatureProperty {
    convenience init(context: NSManagedObjectContext, key: String, blobValue: Any) {
        self.init(context: context, key: key)
        self.setValue(try? JSONSerialization.data(withJSONObject: blobValue), forKey: "value")
    }
}

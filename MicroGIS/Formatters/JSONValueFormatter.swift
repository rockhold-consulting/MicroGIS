//
//  JSONValueFormatter.swift
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
//  Created by Michael Rockhold on 8/7/24.
//

import Foundation

class JSONValueFormatter: Formatter {
    let dateFormatter = ISO8601DateFormatter()

    override func string(for obj: Any?) -> String? {
        switch obj {
        case _ as NSNull:
            return "null"
        case nil:
            return ""
        case let s as String:
            return s
        case let i as Int:
            return String(i)
        case let f as Float:
            return String(f)
        case let d as Double:
            return String(d)
        case let dt as Date:
            return dateFormatter
                .string(from: dt)
        case let ar as Array<Any>:
            let subs = ar.map {
                self.string(for: $0) ?? "??"
            }
            return "[" + subs.joined(separator: ",") + "]"
        case let obj as [String:Any]:
            let subs = obj.map { (k, v) in
                return "\(k): \(self.string(for: v) ?? "??")"
            }
            return "{" + subs.joined(separator: ",") + "}"
        default:
            return "NOT IMPLEMENTED"
        }
    }

    override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

            return true
    }
}

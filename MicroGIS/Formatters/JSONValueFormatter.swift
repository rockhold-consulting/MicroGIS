//
//  JSONValueFormatter.swift
//  MicroGIS
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

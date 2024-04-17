/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Helper extensions for OutlineViewController.
*/

import Cocoa
import UniformTypeIdentifiers // for UTType
import CoreLocation

extension OutlineViewModel {

    // Return an instance of the abstract GeoObject class from the specified outline view item through its representedObject.
    class func geoObject(from treeNode: NSTreeNode) -> GeoObject? {
        return treeNode.representedObject as? GeoObject
    }
}

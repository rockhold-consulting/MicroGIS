/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Helper extensions for OutlineViewController.
*/

import Cocoa
import UniformTypeIdentifiers // for UTType
import CoreLocation

extension OutlineViewModel {

    // Return an instance of the conforming to ModelObject from the specified outline view item through its representedObject.
    class func modelObject(from treeNode: NSTreeNode) -> ModelObject? {
        return treeNode.representedObject as? ModelObject
    }
}

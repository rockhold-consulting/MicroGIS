/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Helper extensions for OutlineViewController.
*/

import Cocoa
import UniformTypeIdentifiers // for UTType
import CoreLocation

extension OutlineViewModel {
        
    // Return a Node class from the specified outline view item through its representedObject.
    class func node(from treeNode: NSTreeNode) -> Node? {
        return treeNode.representedObject as? Node
    }
    
}

// MARK: -

extension NSTreeController {
    
    func indexPathOfObject(anObject: Node) -> IndexPath? {
        return indexPathOfObject(anObject: anObject, nodes: self.arrangedObjects.children)
    }
    
    func indexPathOfObject(anObject: Node, nodes: [NSTreeNode]!) -> IndexPath? {
        for node in nodes {
            if anObject.isEqual(node.representedObject) {
                return node.indexPath
            }
            if node.children != nil {
                if let path = indexPathOfObject(anObject: anObject, nodes: node.children) {
                    return path
                }
            }
        }
        return nil
    }
}

// MARK: -

extension NSImage {
    
    // Returns the Data version of NSImage.
    func pngData() -> Data? {
        var data: Data?
        if let tiffRep = tiffRepresentation {
            if let bitmap = NSBitmapImageRep(data: tiffRep) {
                data = bitmap.representation(using: .png, properties: [:])
            }
        }
        return data
    }
}


// MARK: -

extension GeoLayer: Node {
}

extension GeoFeature: Node {
}

extension GeoOverlay: Node {    
}

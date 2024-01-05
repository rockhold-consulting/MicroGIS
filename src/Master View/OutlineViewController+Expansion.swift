/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Expansion restoration support for OutlineViewController.
*/

import Cocoa

extension OutlineViewController {
    
    private class func nodeFromIdentifier(anObject: Any, nodes: [NSTreeNode]!) -> NSTreeNode? {
        for node in nodes {
            if let testNode = node.representedObject as? Node {
                let idCheck = anObject as? String
                if idCheck == testNode.identifier {
                    return node
                }
                if node.children != nil {
                    if let nodeCheck = nodeFromIdentifier(anObject: anObject, nodes: node.children) {
                        return nodeCheck
                    }
                }
            }
        }
        return nil
    }
    
    private func nodeFromIdentifier(anObject: Any) -> NSTreeNode? {
        return OutlineViewController.nodeFromIdentifier(anObject: anObject, nodes: treeController.arrangedObjects.children)
    }

    /** When the outline view is restoring the saved expanded items, the system calls this method for each
     	expanded item to translate the archived object to an outline view item.
     */
/// - Tag: RestoreExpansion
    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
        let node = nodeFromIdentifier(anObject: object)  // The incoming object is the identifier.
        return node
    }
    
    /** When the outline view is saving the expanded items, the system calls this method for each expanded item
        to translate the outline view item to an archived object.
     */
/// - Tag: EncodeExpansion
    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        guard let treeNode = item as? NSTreeNode else { return nil }
        let node = OutlineViewModel.node(from: treeNode)
        return node?.identifier // The outgoing object is the identifier.
    }
}

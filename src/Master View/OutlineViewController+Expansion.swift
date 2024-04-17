/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Expansion restoration support for OutlineViewController.
*/

import Cocoa

//extension OutlineViewController {
//
//    /** When the outline view is restoring the saved expanded items, the system calls this method for each
//         expanded item to translate the archived object to an outline view item.
//     */
///// - Tag: RestoreExpansion
//    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
//        let node = self.outlineViewModel.geoObjectFromIdentifier(anObject: object)  // The incoming object is the identifier.
//        return node
//    }
//
//    /** When the outline view is saving the expanded items, the system calls this method for each expanded item
//        to translate the outline view item to an archived object.
//     */
///// - Tag: EncodeExpansion
//    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
//        let g = OutlineViewModel.geoObject(from: item!)
//        return g?.identifier // The outgoing object is the identifier.
//    }
//}

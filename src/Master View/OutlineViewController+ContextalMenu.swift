/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contextual menu support for OutlineViewController.
*/

import Cocoa

/** Support for the outline view contextual menu.
    This allows the delegate to determine the contextual menu for the outline view.
 */
protocol CustomMenuDelegate: AnyObject {

    // Construct a context menu from the current selected rows.
    func outlineViewMenuForRows(_ outlineView: NSOutlineView, rows: IndexSet) -> NSMenu?
}

extension ModelObject {
    func canAddTo() -> Bool { !(self is Geometry) }

    func canChange() -> Bool { true }
}

extension OutlineViewController: CustomMenuDelegate {

    enum MenuItemTags: Int {
        case removeTag = 1 // Remove item.
        case renameTag // Rename item.
        case addFeatureTag // Add a picture.
        case addGroupTag // Add a folder group.
    }

    @objc
    // The sender is the menu item issuing the contextual menu command.
    private func handleContextualMenu(_ sender: AnyObject) {
        // Expect the sender to be an NSMenuItem, and its representedObject to be an IndexSet (of nodes).
        guard let menuItem = sender as? NSMenuItem,
            let selectionIndexes = menuItem.representedObject as? IndexSet else { return }

        if selectionIndexes.count > 1 {
            var nodesToRemove = [ModelObject]()
            for item in selectionIndexes {
                if let rowItem = outlineView.item(atRow: item) as? NSTreeNode,
                    let node = OutlineViewModel.modelObject(from: rowItem) {
                        nodesToRemove.append(node)
                    }
            }
            remove(items: nodesToRemove)
        } else {
            // Expect the first item, the first item being a tree node and ultimately a ModelObject.
            guard let item = selectionIndexes.first,
                let rowItem = outlineView.item(atRow: item),
                  let g = OutlineViewModel.modelObject(from: rowItem as! NSTreeNode) else { return }

            switch menuItem.tag {
            case MenuItemTags.removeTag.rawValue:
                // Remove the node.
                remove(item: g)

            case MenuItemTags.renameTag.rawValue:
                // Force edit the node's name text field.
                let view = outlineView.view(atColumn: 0, row: item, makeIfNecessary: false)
                if let cellView = view as? NSTableCellView {
                    view?.window?.makeFirstResponder(cellView.textField)
                }

            case MenuItemTags.addFeatureTag.rawValue:
                // Add a picture object to the menu item's representedObject.
                if let item = self.outlineView.item(atRow: item) as? NSTreeNode, let addToNode = OutlineViewModel.modelObject(from: item) {
                    addFeature(at: addToNode)
                }

            case MenuItemTags.addGroupTag.rawValue:
                // Add an empty group folder to the menu item's representedObject (the row number of the outline view).
                if let rowItem = outlineView.item(atRow: item) as? NSTreeNode {
                    self.addFolder(at: rowItem)
                }

            default: break
            }
        }
    }

    /** A utility factory function to make a contextual menu item from inputs.
        The system constructs each contextual menu item with:
            tag: To determine what the menu item actually does.
            representedObject: The set of rows to act on.
    */
    private func contextMenuItem(_ title: String, tag: Int, representedObject: Any) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title,
                                  action: #selector(OutlineViewController.handleContextualMenu),
                                  keyEquivalent: "")
        menuItem.tag = tag
        menuItem.representedObject = representedObject
        return menuItem
    }

    /** Return the contextual menu for the specified set of outline view rows.
        The system constructs each contextual menu item with:
             tag: To determine what the menu item actually does.
             representedObject: The set of rows to act on.
     */
    func outlineViewMenuForRows(_ outlineView: NSOutlineView, rows: IndexSet) -> NSMenu? {
        let contextMenu = NSMenu(title: "")

        // For multiple selected rows, you only offer the remove command.
        if rows.count > 1 {
            // A contextual menu for mutiple selection.
            let removeMenuItemTitle = NSLocalizedString("context remove string multiple", comment: "")
            contextMenu.addItem(contextMenuItem(removeMenuItemTitle,
                                                tag: MenuItemTags.removeTag.rawValue,
                                                representedObject: rows))
        } else {
            // Contextual menu for single selection.

            // You must have a selected row.
            guard !rows.isEmpty,
                // You must have an item at that row.
                let item = outlineView.item(atRow: rows.first!) as? NSTreeNode,
                    // You must have a node from that item.
                    let modelObject = OutlineViewModel.modelObject(from: item) else { return contextMenu }

            // The item is a non-URL file object, so you can remove or rename it.
            //
               let removeItemFormat = NSLocalizedString("context remove string", comment: "")
            let removeMenuItemTitle = String(format: removeItemFormat, modelObject.title ?? "<no title>")
            contextMenu.addItem(contextMenuItem(removeMenuItemTitle,
                                                tag: MenuItemTags.removeTag.rawValue,
                                                representedObject: rows))

            if modelObject.canChange() {
                let renameItemFormat = NSLocalizedString("context rename string", comment: "")
                let renameMenuItemTitle = String(format: renameItemFormat, modelObject.title ?? "<no title>")
                contextMenu.addItem(contextMenuItem(renameMenuItemTitle,
                                                    tag: MenuItemTags.renameTag.rawValue,
                                                    representedObject: rows))
            }

            if modelObject.canAddTo() {
                // The item is a container you can add to.
                contextMenu.addItem(contextMenuItem(NSLocalizedString("add picture", comment: ""),
                                                    tag: MenuItemTags.addFeatureTag.rawValue,
                                                    representedObject: rows))

                contextMenu.addItem(contextMenuItem(NSLocalizedString("add group", comment: ""),
                                                    tag: MenuItemTags.addGroupTag.rawValue,
                                                    representedObject: rows))
            }
        }

        return contextMenu
    }

}

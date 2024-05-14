/*
See LICENSE folder for this sample’s licensing information.

Abstract:
NSOutlineViewDelegate support for OutlineViewController.
*/

import Cocoa

extension OutlineViewController: NSOutlineViewDelegate {

    // Is the outline view item a group node? Not a folder but a group, with Hide/Show buttons.
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        guard let node = item as? NSTreeNode else { return false }
        let g = OutlineViewModel.modelObject(from: node)
        return g is Layer
    }

    // Should you select the outline view item? No selection for special groupings or separators.
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let node = item as? NSTreeNode else { return false }
        if let g = OutlineViewModel.modelObject(from: node) {
            return true
        } else {
            return false
        }
    }

    // What should be the row height of an outline view item?
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        let rowHeight = outlineView.rowHeight

        guard let node = OutlineViewModel.modelObject(from: item as! NSTreeNode) else { return rowHeight }

        return rowHeight
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?

        guard let modelObject = OutlineViewModel.modelObject(from: item as! NSTreeNode) else { return view }

        if self.outlineView(outlineView, isGroupItem: item) {
            // The row is a group node, so return NSTableCellView as a special group row.
            view = outlineView.makeView(
                withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupCell"), owner: self) as? NSTableCellView
            view?.textField?.stringValue =  modelObject.title?.uppercased() ?? "<no title>"
        } else {
            // The row is a regular outline node, so return NSTableCellView with an image and title.
            view = outlineView.makeView(
                withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MainCell"), owner: self) as? NSTableCellView

            view?.textField?.stringValue = modelObject.title ?? "<no title>"
            view?.imageView?.image = modelObject.icon

            // Folder titles are editable only if they don't have a file URL,
            // You don't want users to rename file system-based nodes.
            view?.textField?.isEditable = modelObject.canChange()
        }

        return view
    }

    // The user inserted an outline view row.
    func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int) {
        // Are you adding a newly inserted row that needs a new name?
        if rowToAdd != -1 {
            // Force-edit the newly added row's name.
            if let view = outlineView.view(atColumn: 0, row: rowToAdd, makeIfNecessary: false) {
                if let cellView = view as? NSTableCellView {
                    view.window?.makeFirstResponder(cellView.textField)
                }
                rowToAdd = -1
            }
        }
    }

}

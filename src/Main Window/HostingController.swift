//
//  HostController.swift
//  Georg
//
//  Created by Michael Rockhold on 5/16/24.
//

import Foundation
import SwiftUI
import CoreData

class HostingController<Content: View>: NSHostingController<Content>, 
                                            NSToolbarItemValidation,
                                            NSMenuItemValidation,
                                            NSToolbarDelegate {

    @MainActor
    init(rootView: Content, frame: NSRect) {
        super.init(rootView: rootView)
        self.view.frame = frame
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        // This view controller determines the window toolbar's content.
        let toolbar = NSToolbar(identifier: "toolbar")
        toolbar.delegate = self as! any NSToolbarDelegate
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        self.view.window?.toolbar = toolbar
    }

    // MARK: - NSToolbarItemValidation

    // Validate the toolbar items against the current selection.
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        var enable = false
        // TODO: implement me
        return enable
    }

    // MARK: - NSMenuItemValidation

    // Validate the two menu items in the Add toolbar item against the currently selected nodes.
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        // TODO: implement me
        return false
        //        guard let splitViewController = children[0] as? NSSplitViewController else { return false }
        //
        //        if splitViewController.splitViewItems[0].isCollapsed {
        //            // The primary side bar is in a collapsed state, don't allow the menu item to work.
        //            return false
        //        } else {
        //            // The primary side bar is in an expanded state, allow the item to work.
        //            guard let selection = selectedNodes else { return false }
        //            guard !selection.isEmpty && selection.count == 1 else { return false }
        //
        ////            if let item = OutlineViewModel.modelObject(from: selection[0]) {
        ////                // Enable add menu items when the selection is a non-URL based node.
        ////                return item.canAddTo()
        ////            }
        //            return false
        //        }
    }

    // MARK: - NSToolbarDelegate

    /** NSToolbar delegates require this function.
     It takes an identifier and returns the matching NSToolbarItem. It also takes a parameter telling
     whether this toolbar item is going into an actual toolbar, or whether it's going to appear
     in a customization palette.
     */
    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)


        return toolbarItem
    }

    /** NSToolbar delegates require this function. It returns an array holding identifiers for the default
     set of toolbar items. The customization palette can also call it to display the default toolbar.

     Note: Because Interface Builder defines the toolbar, the system automatically adds an additional separator
     and customized toolbar items to the default list of items.
     */
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        /** Note that the system adds the .toggleSideBar toolbar item to the toolbar to the far left.
         This toolbar item hides and shows (toggle) the primary or side bar split-view item.

         For this toolbar item to work, you need to set the split-view item's NSSplitViewItem.Behavior to sideBar,
         which is already in the storyboard. Also note that the system automatically places .addItem and .removeItem to the far right.
         */
        var toolbarItemIdentifiers = [NSToolbarItem.Identifier]()
        if #available(macOS 11.0, *) {
            toolbarItemIdentifiers.append(.toggleSidebar)
        }
        if #available(macOS 14.0, *) {
            toolbarItemIdentifiers.append(.toggleInspector)
        }
        return toolbarItemIdentifiers
    }

    /** NSToolbar delegates require this function. It returns an array holding identifiers for all allowed
     toolbar items in this toolbar. Any not listed here aren't available in the customization palette.
     */
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarDefaultItemIdentifiers(toolbar)
    }
}

private extension NSToolbarItem.Identifier {
    static let addItem: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "add")
    static let removeItem: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "remove")
}

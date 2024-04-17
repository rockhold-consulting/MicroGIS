/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 The view controller that contains the lower UI controls and the embedded child view controller (split view controller).
 */

import Cocoa
import Combine
import UniformTypeIdentifiers // for UTType

class WindowViewController: NSViewController {

    // MARK: - Properties

    var splitViewController: SplitViewController? = nil

    override var representedObject: Any? {
        didSet {
            if let svc = splitViewController {
                svc.representedObject = representedObject
            }

            // Update the view, if already loaded.
            outlineViewModelDidLoad()
        }
    }

    func outlineViewModelDidLoad() {
        // Listens for selection changes to the NSTreeController so it can update the UI elements (add/remove buttons).
        selectionChangedCancellable = self.outlineViewModel?.treeController.publisher(for: \.selectedNodes)
            .sink() { [self] selectedNodes in

                // Examine the current selection and adjust the UI elements.

                // Remember the selected nodes for later when the system calls NSToolbarItemValidation and NSMenuItemValidation.
                self.selectedNodes = selectedNodes

                guard let currentlySelectedNodes = self.selectedNodes else { return }

                if !currentlySelectedNodes.isEmpty && currentlySelectedNodes.count == 1 {
                    if let item = OutlineViewModel.geoObject(from: currentlySelectedNodes[0]) {
                        if item is Layer {
                            // The user selected a directory, so this could take a while to populate the detail view controller.
                            progIndicator.isHidden = false
                            progIndicator.startAnimation(self)
                        }
                    }
                }

            }

    }

    @IBOutlet private weak var progIndicator: NSProgressIndicator!

    // Remember the selected nodes from NSTreeController when the system calls "selectionDidChange".
    var selectedNodes: [NSTreeNode]?

    var selectionChangedCancellable: Cancellable?

    // MARK: View Controller Lifecycle

    override func viewDidLoad() {

        /** Note: Keep the left split-view item from growing as the window grows by setting its holding priority to 200,
         and the right split-view item to 199. The view with the lowest priority is the first to take on additional
         width if the split view grows or shrinks.
         */
        super.viewDidLoad()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        // This view controller determines the window toolbar's content.
        let toolbar = NSToolbar(identifier: "toolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        self.view.window?.toolbar = toolbar
    }

    deinit {
        selectionChangedCancellable?.cancel()
    }

    // MARK: NSNotifications

    // A notification that the IconViewController class sends to indicate when it receives the file system content.
    @objc
    private func contentReceived(_ notification: Notification) {
        progIndicator.isHidden = true
        progIndicator.stopAnimation(self)
    }

    // MARK: Actions

    struct NotificationNames {
        // A notification to instruct OutlineViewController to add a folder.
        static let addFolder = "AddFolderNotification"
        // A notification to instruct OutlineViewController to add a picture.
        static let addFeature = "AddFeatureNotification"
        // A notification to instruct OutlineViewController to remove an item.
        static let removeItem = "RemoveItemNotification"
    }

    @IBAction func addFolderAction(_: AnyObject) {
        // Post a notification to OutlineViewController to add a new folder group.
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.addFolder), object: nil)
    }

    @IBAction func addFeatureAction(_: AnyObject) {
        // Post a notification to OutlineViewController to add a new picture.
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.addFeature), object: nil)
    }

    @IBAction func removeAction(_: AnyObject) {
        // Post a notification to OutlineViewController to remove an item.
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.removeItem), object: nil)
    }

}

// MARK: - NSToolbarItemValidation

extension WindowViewController: NSToolbarItemValidation {

    // Validate the toolbar items against the currently selected nodes.
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        var enable = false
        if let splitViewController = children[0] as? NSSplitViewController {
            let primary = splitViewController.splitViewItems[0]
            if primary.isCollapsed {
                // The primary side bar is in a collapsed state, don't allow the remove item to work.
                enable = false
            } else {
                // The primary side bar is in an expanded state, allow the remove item to work if there is a selection.
                if let selection = selectedNodes {
                    enable = !selection.isEmpty
                }
            }
        }
        return enable
    }
}

// MARK: - NSMenuItemValidation

extension WindowViewController: NSMenuItemValidation {

    // Validate the two menu items in the Add toolbar item against the currently selected nodes.
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let splitViewController = children[0] as? NSSplitViewController else { return false }

        if splitViewController.splitViewItems[0].isCollapsed {
            // The primary side bar is in a collapsed state, don't allow the menu item to work.
            return false
        } else {
            // The primary side bar is in an expanded state, allow the item to work.
            guard let selection = selectedNodes else { return false }
            guard !selection.isEmpty && selection.count == 1 else { return false }

            if let item = OutlineViewModel.geoObject(from: selection[0]) {
                // Enable add menu items when the selection is a non-URL based node.
                return item.canAddTo()
            } else {
                return false
            }
        }
    }
}

// MARK: - NSToolbarDelegate

private extension NSToolbarItem.Identifier {
    static let addItem: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "add")
    static let removeItem: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "remove")
}

extension WindowViewController {
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "embed-splitview" {
            guard let dest = segue.destinationController as? SplitViewController else {
                fatalError("unexpected error: unexpected view controller transition")
            }
            splitViewController = dest
        }
    }
}

extension WindowViewController: NSToolbarDelegate {

    /** NSToolbar delegates require this function.
     It takes an identifier and returns the matching NSToolbarItem. It also takes a parameter telling
     whether this toolbar item is going into an actual toolbar, or whether it's going to appear
     in a customization palette.
     */
    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)

        /// Create a new NSToolbarItem, and then go through the process of setting up its attributes.
        if itemIdentifier == NSToolbarItem.Identifier.addItem {
            // Configure the Add toolbar item.
            var image: NSImage!
            if #available(OSX 11.0, *) {
                let config = NSImage.SymbolConfiguration(scale: .large)
                image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Add")!.withSymbolConfiguration(config)
            } else {
                image = NSImage(named: NSImage.addTemplateName)
            }
            let segmentControl = NSSegmentedControl(images: [image], trackingMode: .selectOne, target: nil, action: nil)

            let addMenu = NSMenu(title: "Add")
            addMenu.addItem(NSMenuItem(title: "Add Feature…", action: #selector(addFeatureAction), keyEquivalent: ""))
            addMenu.addItem(NSMenuItem(title: "Add Group", action: #selector(addFolderAction), keyEquivalent: ""))
            segmentControl.setMenu(addMenu, forSegment: 0)
            segmentControl.setShowsMenuIndicator(true, forSegment: 0)

            toolbarItem.view = segmentControl
            toolbarItem.label = "Add"
            toolbarItem.image = image
        } else if itemIdentifier == NSToolbarItem.Identifier.removeItem {
            // Configure the Remove toolbar item.
            if #available(OSX 11.0, *) {
                let config = NSImage.SymbolConfiguration(scale: .small)
                let image = NSImage(systemSymbolName: "minus", accessibilityDescription: "Remove")!.withSymbolConfiguration(config)
                toolbarItem.image = image
            } else {
                toolbarItem.image = NSImage(named: NSImage.removeTemplateName)
            }
            toolbarItem.action = #selector(removeAction)
            toolbarItem.label = "Remove"
        }

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
        toolbarItemIdentifiers.append(.addItem)
        toolbarItemIdentifiers.append(.removeItem)
        return toolbarItemIdentifiers
    }

    /** NSToolbar delegates require this function. It returns an array holding identifiers for all allowed
     toolbar items in this toolbar. Any not listed here aren't available in the customization palette.
     */
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarDefaultItemIdentifiers(toolbar)
    }

}

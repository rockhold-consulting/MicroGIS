/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 The view controller that manages the split-view interface.
 */

import Cocoa
import Combine

class SplitViewController: NSSplitViewController {

    private var verticalConstraints: [NSLayoutConstraint] = []
    private var horizontalConstraints: [NSLayoutConstraint] = []

    private var selectionChangedCancellable: Cancellable?

    override var representedObject: Any? {
        didSet {
            for item in splitViewItems {
                item.viewController.representedObject = representedObject
            }

            selectionChangedCancellable?.cancel()
            if let tc = treeController {
                selectionChangedCancellable = tc.publisher(for: \.selectedNodes)
                .sink() { [self] selectedNodes in
                    self.onSelectedNodes(selectedNodes)
                }
            }
        }
    }

    var treeController: NSTreeController? {
        return representedObject as? NSTreeController
    }

    /// Examine the current selection and adjust the UI.
    func onSelectedNodes(_ selectedNodes: [NSTreeNode]) {
//        let leftSplitViewItem = splitViewItems[0]
//        if let outlineViewControllerToObserve = leftSplitViewItem.viewController as? OutlineViewController {
//            let currentDetailVC = detailViewController
//
//            // Let the outline view controller handle the selection (helps you decide which detail view to use).
//            if let vcForDetail = outlineViewControllerToObserve.viewControllerForSelection(selectedNodes) {
//                if hasChildViewController && currentDetailVC.children[0] != vcForDetail {
//                    /** The incoming child view controller is different from the one you currently have,
//                     so remove the old one and add the new one.
//                     */
//                    currentDetailVC.removeChild(at: 0)
//                    // Remove the old child detail view.
//                    detailViewController.view.subviews[0].removeFromSuperview()
//                    // Add the new child detail view.
//                    embedChildViewController(vcForDetail)
//                } else {
//                    if !hasChildViewController {
//                        // You don't have a child view controller, so embed the new one.
//                        embedChildViewController(vcForDetail)
//                    }
//                }
//            } else {
//                // No selection. You don't have a child view controller to embed, so remove the current child view controller.
//                if hasChildViewController {
//                    currentDetailVC.removeChild(at: 0)
//                    detailViewController.view.subviews[0].removeFromSuperview()
//                }
//            }
//        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        /** Note: Keep the left split-view item from growing as the window grows by setting its hugging priority to 200,
         and the right split view item to 199. The view with the lowest priority is the first to take on additional
         width if the split-view grows or shrinks.
         */

        // This preserves the split-view divider position.
        splitView.autosaveName = "SplitViewAutoSave"
    }

    // MARK: Sub View Controller Management

    private var outlineViewController: NSViewController {
        return splitViewItems[0].viewController
    }
    private var mapViewController: NSViewController {
        return splitViewItems[1].viewController
    }
    private var inspectorViewController: NSViewController {
        return splitViewItems[2].viewController
    }
}

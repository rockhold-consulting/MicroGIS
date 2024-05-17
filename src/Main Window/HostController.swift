//
//  HostController.swift
//  Georg
//
//  Created by Michael Rockhold on 5/16/24.
//

import Foundation
import SwiftUI
import CoreData

class HostController<Content: View>: NSHostingController<Content> {

    private let moc: NSManagedObjectContext

    @MainActor
    init?(
        coder: NSCoder,
        rootView: Content,
        managedObjectContext: NSManagedObjectContext
    ) {
        self.moc = managedObjectContext
        super.init(coder: coder, rootView: rootView)
    }
    
    @MainActor required dynamic init?(coder: NSCoder) {
        self.moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        super.init(coder: coder)
    }
}

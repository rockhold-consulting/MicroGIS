//
//  ContentView.swift
//  Georg-II
//
//  Created by Michael Rockhold on 5/15/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: Georg_IIDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(Georg_IIDocument()))
}

//
//  __7__Genesis_2_RPGApp.swift
//  1.7. Genesis 2 RPG
//
//  Created by Max on 02.01.2026.
//

import SwiftUI

@main
struct __7__Genesis_2_RPGApp: App {
    @StateObject private var store: GameStore

    init() {
        _store = StateObject(wrappedValue: GameStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

//
// This source file is part of the PocketTSLM project
//
// SPDX-FileCopyrightText: 2026 The Authors
//
// SPDX-License-Identifier: MIT
//

import SwiftUI

@main
struct PocketTSLMApplication: App {
    @UIApplicationDelegateAdaptor(PocketTSLMAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            PocketTSLMView()
                .spezi(appDelegate)
        }
    }
}

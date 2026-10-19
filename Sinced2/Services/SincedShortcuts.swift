//
//  SincedShortcuts.swift
//  Sinced2
//
//  Siri phrases and Shortcuts app tiles
//

import AppIntents

struct SincedShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ResetEventIntent(),
            phrases: [
                "Reset \(\.$event) in \(.applicationName)",
                "Restart \(\.$event) in \(.applicationName)",
                "\(.applicationName) reset \(\.$event)"
            ],
            shortTitle: "Reset Event",
            systemImageName: "arrow.counterclockwise"
        )
        AppShortcut(
            intent: TimeSinceIntent(),
            phrases: [
                "How long since \(\.$event) in \(.applicationName)",
                "How long has it been since \(\.$event) in \(.applicationName)",
                "Check \(\.$event) in \(.applicationName)"
            ],
            shortTitle: "Time Since",
            systemImageName: "clock"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .grayGreen
}

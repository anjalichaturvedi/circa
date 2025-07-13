//
//  circaApp.swift
//  circa
//
//  Created by Anjali Chaturvedi on 11/07/25.
//
import AppKit
import SwiftUI

@main
struct CircaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

extension Notification.Name {
    static let streakCountUpdated = Notification.Name("streakCountUpdated")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var isPopoverShown = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "✨ \(calculateGeneralStreak())"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: UnifiedView())

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStreakCount(_:)),
            name: .streakCountUpdated,
            object: nil
        )
    }

    @objc func togglePopover(_ sender: Any?) {
        if isPopoverShown {
            popover.performClose(self)
            isPopoverShown = false
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            isPopoverShown = true
        }
    }

    @objc func updateStreakCount(_ notification: Notification) {
        if let streaks = notification.userInfo?["taskStreaks"] as? [String: Int] {
            let activeStreaks = streaks.values.filter { $0 > 0 }.count
            statusItem.button?.title = "🔥 \(activeStreaks) \(activeStreaks == 1 ? "" : "")"
        }
    }



    func calculateGeneralStreak() -> Int {
        let taskCompletions = UserDefaults.standard.dictionary(forKey: "taskCompletions") as? [String: [String]] ?? [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var count = 0
        var date = today
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        while let completions = taskCompletions[formatter.string(from: date)], !completions.isEmpty {
            count += 1
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }
        return count
    }
}

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
        Settings { EmptyView() } // No settings window needed
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
            button.image = nil
            button.title = "✨ \(calculateStreakCount())"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: CalendarView())

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
        if let streakCount = notification.userInfo?["streakCount"] as? Int {
            statusItem.button?.title = "✨ \(streakCount)"
        }
    }

    func calculateStreakCount() -> Int {
        let streakDates = UserDefaults.standard.stringArray(forKey: "streakDates") ?? []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var count = 0
        var date = today
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        while streakDates.contains(formatter.string(from: date)) {
            count += 1
            date = calendar.date(byAdding: .day, value: -1, to: date)!
        }
        return count
    }
}

//
//  circaApp.swift
//  circa
//
//  Created by Anjali Chaturvedi on 11/07/25.
//

import SwiftUI

@main
struct circaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        var contentView = ContentView(popover: popover)

        popover.contentSize = NSSize(width: 250, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "🔥 0"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        contentView.onStreakChange = { newCount in
            self.statusItem.button?.title = "🔥 \(newCount)"
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}


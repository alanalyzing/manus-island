import SwiftUI
import AppKit
import Carbon.HIToolbox
import CoreSpotlight

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var store: TaskStore!
    private var islandController: IslandWindowController!
    private var eventMonitor: Any?
    private var hotkeyRef: EventHotKeyRef?
    private var manusIcon: NSImage?

    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            await self.setup()
        }
    }

    nonisolated func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            store?.stopPolling()
            store?.stopWebhookServer()
            islandController?.hideIsland()
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
            unregisterHotkey()
        }
    }

    // MARK: - Spotlight Continuation

    nonisolated func application(_ application: NSApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([any NSUserActivityRestoring]) -> Void) -> Bool {
        Task { @MainActor in
            if userActivity.activityType == CSSearchableItemActionType {
                store?.handleSpotlightActivity(userActivity.userInfo ?? [:])
            }
        }
        return true
    }

    private func setup() async {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Load the Manus glyph icon from Resources
        loadManusIcon()

        // Initialize store
        store = TaskStore()

        // Initialize island controller
        islandController = IslandWindowController(store: store)

        // Create menu bar status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateStatusBarIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 540)
        popover.behavior = .transient
        popover.animates = true

        let menuBarView = MenuBarPopoverView(store: store)
        popover.contentViewController = NSHostingController(rootView: menuBarView)

        // Start polling
        if !store.apiKey.isEmpty {
            store.startPolling()
        }

        // Show island
        if store.showIsland {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.islandController.showIsland()
            }
        }

        // Observe store changes
        setupObservers()

        // Register global hotkey: Cmd+Shift+M
        registerGlobalHotkey()

        // Close popover when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                if let popover = self?.popover, popover.isShown {
                    popover.performClose(nil)
                }
            }
        }

        // v1.0: Fetch projects, connectors, and skills on launch
        Task {
            await store.fetchProjects()
            await store.fetchConnectors()
            await store.fetchSkills()
        }

        // Listen for ToggleSettingsPopover from the island's settings gear
        NotificationCenter.default.addObserver(forName: Notification.Name("ToggleSettingsPopover"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.togglePopover()
            }
        }

        // v1.0: Start webhook server if enabled
        if store.webhookEnabled {
            store.startWebhookServer()
            if !store.webhookURL.isEmpty {
                Task { await store.registerWebhook() }
            }
        }

        // v1.0: Index existing tasks in Spotlight
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.store.indexAllTasksInSpotlight()
        }
    }

    private func loadManusIcon() {
        // Try to load from the app bundle's Resources directory
        if let bundlePath = Bundle.main.resourcePath {
            // Try @2x first for Retina
            let path2x = (bundlePath as NSString).appendingPathComponent("menubar_icon@2x.png")
            let path1x = (bundlePath as NSString).appendingPathComponent("menubar_icon.png")

            if let img = NSImage(contentsOfFile: path2x) {
                img.size = NSSize(width: 18, height: 18) // Set point size for @2x
                img.isTemplate = true // Makes it adapt to light/dark menu bar
                manusIcon = img
            } else if let img = NSImage(contentsOfFile: path1x) {
                img.size = NSSize(width: 18, height: 18)
                img.isTemplate = true
                manusIcon = img
            }
        }
    }

    private func setupObservers() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusBarIcon()
                self?.updateIslandVisibility()
            }
        }
    }

    private func updateStatusBarIcon() {
        guard let button = statusItem.button else { return }

        let activeCount = store.activeCount

        if let icon = manusIcon {
            button.image = icon
            if activeCount > 0 {
                button.title = " \(activeCount)"
            } else {
                button.title = ""
            }
        } else {
            // Fallback to SF Symbols if icon not found
            if activeCount > 0 {
                button.title = " \(activeCount)"
                button.image = NSImage(systemSymbolName: "bolt.circle.fill", accessibilityDescription: "Manus Active")
                if let img = button.image {
                    let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
                    button.image = img.withSymbolConfiguration(config)
                }
            } else {
                button.title = ""
                button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Manus Island")
                if let img = button.image {
                    let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                    button.image = img.withSymbolConfiguration(config)
                }
            }
        }
    }

    private func updateIslandVisibility() {
        let shouldShow = store.showIsland && !store.shouldHideIsland
        if shouldShow {
            islandController.showIsland()
        } else {
            islandController.hideIsland()
        }
    }

    // v1.0: Reset island position to center (accessible from Settings)
    func resetIslandPosition() {
        UserDefaults.standard.removeObject(forKey: "IslandPosX")
        UserDefaults.standard.removeObject(forKey: "IslandPosY")
        islandController.positionWindowDefault()
    }

    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    // MARK: - Global Hotkey (Cmd+Shift+M)

    private func registerGlobalHotkey() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 46 { // 46 = M
                Task { @MainActor in
                    self?.handleHotkey()
                }
                return nil
            }
            return event
        }

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 46 { // 46 = M
                Task { @MainActor in
                    self?.handleHotkey()
                }
            }
        }
    }

    private func unregisterHotkey() {
        // Monitors are automatically cleaned up
    }

    private func handleHotkey() {
        if store.isExpanded {
            store.isExpanded = false
        } else {
            store.isExpanded = true
            islandController.showIsland()
        }
    }
}

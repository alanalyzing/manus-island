import AppKit
import SwiftUI
import UniformTypeIdentifiers
import Combine

// MARK: - Custom Panel that can become key (enables text input & paste)

class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - Island Window Controller

class IslandWindowController: NSWindowController, NSWindowDelegate {
    private var store: TaskStore
    private var hostingView: NSHostingView<IslandView>?
    private var resizeTimer: Timer?
    private var hasBeenPositioned = false
    private var userDraggedPosition: NSPoint? = nil

    init(store: TaskStore) {
        self.store = store

        // Create a borderless panel that CAN become key (for text input)
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        // Allow the panel to receive key events when clicked
        panel.becomesKeyOnlyIfNeeded = true
        panel.acceptsMouseMovedEvents = true
        // Ensure the panel is floatable (stays on top but can accept input)
        panel.isFloatingPanel = true

        super.init(window: panel)
        panel.delegate = self

        // IMPORTANT: Set up the Edit menu so Cmd+C/V/X work in text fields
        setupEditMenu()

        // Create the SwiftUI hosting view
        let islandView = IslandView(store: store)
        let hosting = NSHostingView(rootView: islandView)
        hosting.frame = panel.contentView!.bounds
        hosting.autoresizingMask = [.width, .height]

        // Register for drag and drop on the hosting view
        hosting.registerForDraggedTypes([.fileURL])

        panel.contentView?.addSubview(hosting)
        self.hostingView = hosting

        // Load saved position or use default
        loadSavedPosition()

        // Periodically resize window to match SwiftUI content
        resizeTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateWindowSizeIfNeeded()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        resizeTimer?.invalidate()
    }

    // MARK: - Edit Menu (enables Cmd+C, Cmd+V, Cmd+X, Cmd+A in text fields)

    private func setupEditMenu() {
        // Only create the menu if one doesn't already exist
        if NSApp.mainMenu == nil {
            let mainMenu = NSMenu()

            // App menu (required)
            let appMenuItem = NSMenuItem()
            let appMenu = NSMenu()
            appMenu.addItem(withTitle: "Quit Manus Island", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            appMenuItem.submenu = appMenu
            mainMenu.addItem(appMenuItem)

            // Edit menu (enables standard text editing shortcuts)
            let editMenuItem = NSMenuItem()
            let editMenu = NSMenu(title: "Edit")
            editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
            editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
            editMenu.addItem(NSMenuItem.separator())
            editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
            editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
            editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
            editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
            editMenuItem.submenu = editMenu
            mainMenu.addItem(editMenuItem)

            NSApp.mainMenu = mainMenu
        }
    }

    // MARK: - Position Management

    private func loadSavedPosition() {
        let savedX = UserDefaults.standard.double(forKey: "IslandPosX")
        let savedY = UserDefaults.standard.double(forKey: "IslandPosY")
        if savedX != 0 || savedY != 0 {
            let point = NSPoint(x: savedX, y: savedY)
            if isPointOnScreen(point) {
                userDraggedPosition = point
                window?.setFrameOrigin(point)
                hasBeenPositioned = true
            } else {
                // Saved position is off-screen, reset to default
                positionWindowDefault()
            }
        } else {
            positionWindowDefault()
        }
    }

    /// Check if a point is within any visible screen bounds
    private func isPointOnScreen(_ point: NSPoint) -> Bool {
        let windowSize = window?.frame.size ?? NSSize(width: 360, height: 44)
        let windowRect = NSRect(origin: point, size: windowSize)
        for screen in NSScreen.screens {
            // At least 50px of the window must be visible on some screen
            let intersection = screen.visibleFrame.intersection(windowRect)
            if intersection.width >= 50 && intersection.height >= 20 {
                return true
            }
        }
        return false
    }

    private func savePosition() {
        guard let origin = window?.frame.origin else { return }
        UserDefaults.standard.set(origin.x, forKey: "IslandPosX")
        UserDefaults.standard.set(origin.y, forKey: "IslandPosY")
    }

    func positionWindowDefault() {
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let screenFrame = screen.frame
        let windowSize = window?.frame.size ?? NSSize(width: 360, height: 44)

        // Center horizontally on the full screen
        let x = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2.0
        // Position at the top of the visible frame (just below menu bar/notch)
        let y = visibleFrame.maxY - windowSize.height - 4

        window?.setFrameOrigin(NSPoint(x: x, y: y))
        hasBeenPositioned = true
    }

    func updateWindowSizeIfNeeded() {
        guard let window = window, let hostingView = hostingView else { return }

        let fittingSize = hostingView.fittingSize
        let newWidth = max(fittingSize.width, 200)
        let newHeight = max(fittingSize.height, 36)

        let currentSize = window.frame.size
        let widthDiff = abs(currentSize.width - newWidth)
        let heightDiff = abs(currentSize.height - newHeight)

        if widthDiff > 2 || heightDiff > 2 {
            let currentOrigin = window.frame.origin
            // Keep top edge in place (grow downward)
            let currentTop = currentOrigin.y + currentSize.height
            let newY = currentTop - newHeight

            // Center X around current center
            let newX: CGFloat
            if userDraggedPosition != nil {
                let currentCenterX = currentOrigin.x + currentSize.width / 2.0
                newX = currentCenterX - newWidth / 2.0
            } else {
                guard let screen = NSScreen.main else { return }
                let screenFrame = screen.frame
                newX = screenFrame.origin.x + (screenFrame.width - newWidth) / 2.0
            }

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().setFrame(
                    NSRect(x: newX, y: newY, width: newWidth, height: newHeight),
                    display: true
                )
            }
        }
    }

    func showIsland() {
        guard let window = window else { return }
        if !window.isVisible {
            window.orderFront(nil)
            if !hasBeenPositioned {
                positionWindowDefault()
            }
        }
    }

    func hideIsland() {
        window?.orderOut(nil)
    }

    func toggleIsland() {
        if window?.isVisible == true {
            hideIsland()
        } else {
            showIsland()
        }
    }

    // When user clicks a text field in the island, make the panel key so it accepts input
    func makeIslandKey() {
        window?.makeKey()
    }

    // Track when user drags the window
    func windowDidMove(_ notification: Notification) {
        guard let origin = window?.frame.origin else { return }
        // Ensure the window stays on screen after dragging
        if isPointOnScreen(origin) {
            userDraggedPosition = origin
            savePosition()
        } else {
            // Snap back to default if dragged off-screen
            positionWindowDefault()
            savePosition()
        }
    }

    func windowDidResize(_ notification: Notification) {
    }
}

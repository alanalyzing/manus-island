import AppKit
import Foundation

/// Tracks time spent using Manus apps (Desktop, Web App, browser tabs)
@MainActor
class ScreenTimeTracker: ObservableObject {
    @Published var todayScreenTime: TimeInterval = 0
    @Published var weekScreenTime: TimeInterval = 0
    @Published var isManusActive: Bool = false
    @Published var currentSession: TimeInterval = 0
    @Published var sessionsToday: Int = 0

    private var sessionStart: Date?
    private var tickTimer: Timer?
    private var browserCheckTimer: Timer?
    private var isBrowserManusSession = false
    private let storageKey = "ManusScreenTimeLogs"

    private let manusBundlePrefixes = ["im.manus.", "com.manus."]
    private let manusWebAppPrefix = "com.apple.Safari.WebApp."
    private let browsers = ["Safari", "Google Chrome", "Arc", "Firefox", "Brave Browser", "Microsoft Edge", "Chromium"]

    struct SessionLog: Codable {
        let start: Date
        let end: Date
        var duration: TimeInterval { end.timeIntervalSince(start) }
    }

    init() {
        loadStoredTime()
        startObserving()
    }

    deinit {
        tickTimer?.invalidate()
        browserCheckTimer?.invalidate()
    }

    // MARK: - Observation

    private func startObserving() {
        let nc = NSWorkspace.shared.notificationCenter

        nc.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] notif in
            guard let self = self else { return }
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                Task { @MainActor in self.handleAppActivated(app) }
            }
        }

        nc.addObserver(forName: NSWorkspace.didDeactivateApplicationNotification, object: nil, queue: .main) { [weak self] notif in
            guard let self = self else { return }
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                Task { @MainActor in self.handleAppDeactivated(app) }
            }
        }

        // Check current frontmost app on launch
        if let front = NSWorkspace.shared.frontmostApplication, isManusApp(front) {
            startSession(browser: false)
        }

        // Tick timer for current session duration
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }

        // Browser check timer for Manus tabs
        browserCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkBrowserWindows() }
        }
    }

    private func isManusApp(_ app: NSRunningApplication) -> Bool {
        let bundle = app.bundleIdentifier ?? ""
        let name = app.localizedName ?? ""
        for prefix in manusBundlePrefixes {
            if bundle.hasPrefix(prefix) { return true }
        }
        if bundle.hasPrefix(manusWebAppPrefix) && name.lowercased().contains("manus") {
            return true
        }
        return false
    }

    private func isBrowserApp(_ app: NSRunningApplication) -> Bool {
        browsers.contains(app.localizedName ?? "")
    }

    private func handleAppActivated(_ app: NSRunningApplication) {
        if isManusApp(app) {
            startSession(browser: false)
        } else if isBrowserApp(app) {
            // Will be handled by browser check timer
        }
    }

    private func handleAppDeactivated(_ app: NSRunningApplication) {
        if isManusApp(app) && !isBrowserManusSession {
            if let front = NSWorkspace.shared.frontmostApplication, isManusApp(front) { return }
            endSession()
        } else if isBrowserApp(app) && isBrowserManusSession {
            endSession()
            isBrowserManusSession = false
        }
    }

    private func startSession(browser: Bool) {
        guard sessionStart == nil else { return }
        sessionStart = Date()
        isManusActive = true
        isBrowserManusSession = browser
        sessionsToday += 1
    }

    private func endSession() {
        guard let start = sessionStart else { return }
        let duration = Date().timeIntervalSince(start)
        if duration > 2 {
            saveSession(SessionLog(start: start, end: Date()))
            todayScreenTime += duration
            weekScreenTime += duration
        }
        sessionStart = nil
        currentSession = 0
        isManusActive = false
    }

    private func tick() {
        if let start = sessionStart {
            currentSession = Date().timeIntervalSince(start)
        }
    }

    // MARK: - Browser Window Detection

    private func checkBrowserWindows() {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return }

        var hasManusTab = false
        for window in windowList {
            let ownerName = window[kCGWindowOwnerName as String] as? String ?? ""
            let windowName = window[kCGWindowName as String] as? String ?? ""
            if browsers.contains(ownerName) && windowName.lowercased().contains("manus") {
                hasManusTab = true
                break
            }
        }

        if hasManusTab {
            if let front = NSWorkspace.shared.frontmostApplication, isBrowserApp(front), sessionStart == nil {
                startSession(browser: true)
            }
        } else if isBrowserManusSession {
            endSession()
            isBrowserManusSession = false
        }
    }

    // MARK: - Persistence

    private func saveSession(_ log: SessionLog) {
        var logs = loadLogs()
        logs.append(log)
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        logs = logs.filter { $0.end > cutoff }
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadLogs() -> [SessionLog] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let logs = try? JSONDecoder().decode([SessionLog].self, from: data) else { return [] }
        return logs
    }

    private func loadStoredTime() {
        let logs = loadLogs()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        todayScreenTime = logs.filter { $0.start >= startOfToday }.reduce(0) { $0 + $1.duration }
        weekScreenTime = logs.filter { $0.start >= startOfWeek }.reduce(0) { $0 + $1.duration }
        sessionsToday = logs.filter { $0.start >= startOfToday }.count
    }

    // MARK: - Formatted Output

    var todayFormatted: String { formatDuration(todayScreenTime + currentSession) }
    var weekFormatted: String { formatDuration(weekScreenTime + currentSession) }
    var sessionFormatted: String { formatDuration(currentSession) }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        if total < 60 { return "\(total)s" }
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

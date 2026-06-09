import Foundation
import Combine
import SwiftUI
import UserNotifications
import AppKit
import CoreSpotlight

@MainActor
class TaskStore: ObservableObject {
    @Published var tasks: [ManusTask] = []
    @Published var accountStats: AccountStats = AccountStats()
    @Published var isLoading: Bool = false
    @Published var lastError: String? = nil
    @Published var lastRefresh: Date? = nil
    @Published var isConnected: Bool = false
    @Published var selectedTaskId: String? = nil
    @Published var taskDetail: TaskDetailData? = nil
    @Published var isLoadingDetail: Bool = false
    @Published var isExpanded: Bool = false

    // Quick action states
    @Published var isSendingMessage: Bool = false
    @Published var isStoppingTask: Bool = false
    @Published var quickMessageText: String = ""
    @Published var newTaskPrompt: String = ""
    @Published var isCreatingTask: Bool = false

    // v1.0: Projects & Connectors
    @Published var projects: [ProjectSummary] = []
    @Published var connectors: [ConnectorInfo] = []
    @Published var projectGroups: [ProjectGroup] = []
    @Published var showProjectView: Bool = false

    // v1.0: Streak Counter
    @Published var streakCount: Int = 0
    @Published var streakDate: String = ""
    @Published var weeklyStreak: [String: Int] = [:]

    // v1.0: Webhook
    @Published var webhookEnabled: Bool = false {
        didSet { UserDefaults.standard.set(webhookEnabled, forKey: "WebhookEnabled") }
    }
    @Published var webhookURL: String = "" {
        didSet { UserDefaults.standard.set(webhookURL, forKey: "WebhookURL") }
    }
    @Published var webhookId: String? = nil
    @Published var lastWebhookEvent: Date? = nil

    // v1.0: Skills
    @Published var skills: [SkillInfo] = []

    // v1.0: Aggregated Tool Stats (cross-task)
    @Published var aggregatedToolStats: [AggregatedToolStat] = []

    // v1.0: Scheduled Tasks / ETAs
    @Published var scheduledTasks: [ScheduledTaskInfo] = []

    // v1.0: Activity Heatmap (daily credit usage)
    @Published var dailyActivity: [DailyStatistic] = []
    private var lastActivityFetch: Date = .distantPast

    // v1.0: Drag & Drop
    @Published var isDragOver: Bool = false
    @Published var droppedFileNames: [String] = []
    @Published var showDropPrompt: Bool = false
    @Published var dropPromptText: String = ""
    @Published var pendingDropFiles: [URL] = []

    // Settings
    @Published var showIsland: Bool = true {
        didSet { UserDefaults.standard.set(showIsland, forKey: "ShowIsland") }
    }
    @Published var apiKey: String = "" {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "ManusAPIKey")
            if !apiKey.isEmpty { apiClient = ManusAPIClient(apiKey: apiKey) }
        }
    }
    @Published var pollingInterval: TimeInterval = 5.0 {
        didSet {
            UserDefaults.standard.set(pollingInterval, forKey: "PollingInterval")
            restartPolling()
        }
    }

    @Published var focusMode: Bool = false {
        didSet { UserDefaults.standard.set(focusMode, forKey: "FocusMode") }
    }
    @Published var launchAtLogin: Bool = false {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "LaunchAtLogin")
            updateLoginItem()
        }
    }

    private var apiClient: ManusAPIClient?
    private var pollingTimer: Timer?
    private var previousTaskStatuses: [String: String] = [:]
    private var webhookServer: WebhookLocalServer?

    let screenTime = ScreenTimeTracker()
    let voiceInput = VoiceInputManager()

    // No default API key — users must enter their own in Settings on first launch

    // MARK: - Computed Properties

    var activeTasks: [ManusTask] { tasks.filter { $0.status.isActive || $0.status == .error } }
    var recentTasks: [ManusTask] { tasks.filter { !$0.status.isActive && $0.status != .error }.prefix(20).map { $0 } }
    var activeCount: Int { activeTasks.count }
    var runningCount: Int { tasks.filter { $0.status == .running }.count }
    var waitingCount: Int { tasks.filter { $0.status == .waiting }.count }
    var primaryTask: ManusTask? { activeTasks.first { $0.status == .running } ?? activeTasks.first }

    var selectedTask: ManusTask? {
        guard let id = selectedTaskId else { return nil }
        return tasks.first { $0.id == id }
    }

    var shouldHideIsland: Bool {
        focusMode && waitingCount == 0
    }

    // v1.0: Streak display string
    var streakDisplay: String {
        if streakCount > 0 {
            return "\(streakCount) task\(streakCount == 1 ? "" : "s") today"
        }
        return "No tasks today"
    }

    var streakEmoji: String {
        if streakCount >= 10 { return "\u{1F525}" } // fire
        if streakCount >= 5 { return "\u{1FAF0}" } // snapping fingers (fallback to hand)
        if streakCount >= 3 { return "\u{26A1}" } // lightning
        if streakCount >= 1 { return "\u{2728}" } // sparkles
        return ""
    }

    // MARK: - Init

    init() {
        let savedKey = UserDefaults.standard.string(forKey: "ManusAPIKey") ?? ""
        self.apiKey = savedKey
        self.pollingInterval = UserDefaults.standard.double(forKey: "PollingInterval")
        if self.pollingInterval < 3 { self.pollingInterval = 5.0 }
        self.showIsland = UserDefaults.standard.object(forKey: "ShowIsland") as? Bool ?? true
        self.focusMode = UserDefaults.standard.object(forKey: "FocusMode") as? Bool ?? false
        self.launchAtLogin = UserDefaults.standard.object(forKey: "LaunchAtLogin") as? Bool ?? false
        self.webhookEnabled = UserDefaults.standard.object(forKey: "WebhookEnabled") as? Bool ?? false
        self.webhookURL = UserDefaults.standard.string(forKey: "WebhookURL") ?? ""
        if !self.apiKey.isEmpty { self.apiClient = ManusAPIClient(apiKey: self.apiKey) }
        requestNotificationPermission()
        loadStreakData()
    }



    // MARK: - Streak Counter

    private func loadStreakData() {
        let today = todayKey()
        streakDate = UserDefaults.standard.string(forKey: "StreakDate") ?? today
        streakCount = UserDefaults.standard.integer(forKey: "StreakCount")
        // Reset if it's a new day
        if streakDate != today {
            streakCount = 0
            streakDate = today
            saveStreakData()
        }
        // Load weekly data
        if let data = UserDefaults.standard.data(forKey: "WeeklyStreak"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            weeklyStreak = decoded
        }
    }

    private func saveStreakData() {
        UserDefaults.standard.set(streakDate, forKey: "StreakDate")
        UserDefaults.standard.set(streakCount, forKey: "StreakCount")
        if let data = try? JSONEncoder().encode(weeklyStreak) {
            UserDefaults.standard.set(data, forKey: "WeeklyStreak")
        }
    }

    private func todayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    func incrementStreak() {
        let today = todayKey()
        if streakDate != today {
            streakCount = 0
            streakDate = today
        }
        streakCount += 1
        weeklyStreak[today] = streakCount
        // Clean old entries (keep last 7 days)
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        weeklyStreak = weeklyStreak.filter { key, _ in
            if let date = f.date(from: key) { return date >= sevenDaysAgo }
            return false
        }
        saveStreakData()
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func sendNotification(title: String, body: String, taskId: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .none
        content.userInfo = ["taskId": taskId]
        let request = UNNotificationRequest(
            identifier: "manus-\(taskId)-\(Date().timeIntervalSince1970)",
            content: content, trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func checkForStatusChanges(newTasks: [ManusTask]) {
        for task in newTasks {
            let oldStatus = previousTaskStatuses[task.id]
            let newStatus = task.status.rawValue
            if let old = oldStatus, old != newStatus {
                if newStatus == "stopped" && old == "running" {
                    sendNotification(title: "Task Completed \(streakEmoji)", body: task.taskName, taskId: task.id)
                    incrementStreak()
                    indexTaskInSpotlight(task)
                } else if newStatus == "waiting" {
                    let reason = task.waitingDescription.isEmpty ? "Needs your input" : task.waitingDescription
                    sendNotification(title: "Task Waiting", body: "\(task.taskName): \(reason)", taskId: task.id)
                } else if newStatus == "error" {
                    sendNotification(title: "Task Error", body: task.taskName, taskId: task.id)
                }
            }
            previousTaskStatuses[task.id] = newStatus
        }
    }

    // MARK: - Spotlight Indexing

    func indexTaskInSpotlight(_ task: ManusTask) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = task.taskName
        attributeSet.contentDescription = "Manus task: \(task.activityDescription). Status: \(task.status.label). Duration: \(TaskStore.formatDuration(task.timeSpent))"
        attributeSet.keywords = ["manus", "task", task.taskName]
        attributeSet.creator = "Manus Island"

        let item = CSSearchableItem(
            uniqueIdentifier: "manus-task-\(task.id)",
            domainIdentifier: "com.manus.island.tasks",
            attributeSet: attributeSet
        )
        item.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("Spotlight indexing error: \(error)")
            }
        }
    }

    func indexAllTasksInSpotlight() {
        for task in tasks {
            indexTaskInSpotlight(task)
        }
    }

    func handleSpotlightActivity(_ userInfo: [AnyHashable: Any]) {
        if let identifier = userInfo[CSSearchableItemActivityIdentifier] as? String {
            let taskId = identifier.replacingOccurrences(of: "manus-task-", with: "")
            if let url = URL(string: "https://manus.im/app/\(taskId)") {
                openURLInChrome(url)
            }
        }
    }

    // MARK: - Launch at Login

    private func updateLoginItem() {
        // Placeholder for SMAppService on macOS 13+
    }

    // MARK: - Webhook Local Server

    func startWebhookServer() {
        guard webhookServer == nil else { return }
        webhookServer = WebhookLocalServer { [weak self] event in
            Task { @MainActor in
                self?.handleWebhookEvent(event)
            }
        }
        webhookServer?.start()
    }

    func stopWebhookServer() {
        webhookServer?.stop()
        webhookServer = nil
    }

    func registerWebhook() async {
        guard let client = apiClient, !webhookURL.isEmpty else { return }
        do {
            let data = try await client.createWebhook(
                url: webhookURL,
                events: ["task.completed", "task.waiting", "task.error", "task.started"]
            )
            webhookId = data?.id
        } catch {
            print("Webhook registration failed: \(error)")
        }
    }

    private func handleWebhookEvent(_ event: [String: Any]) {
        lastWebhookEvent = Date()
        // Trigger an immediate refresh when a webhook event arrives
        Task { await refresh() }
    }

    // MARK: - Projects & Connectors

    func fetchProjects() async {
        guard let client = apiClient else { return }
        do {
            projects = try await client.listProjects()
            buildProjectGroups()
        } catch {
            print("Failed to fetch projects: \(error)")
        }
    }

    func fetchConnectors() async {
        guard let client = apiClient else { return }
        do {
            connectors = try await client.listConnectors()
        } catch {
            print("Failed to fetch connectors: \(error)")
        }
    }

    func fetchSkills() async {
        guard let client = apiClient else { return }
        do {
            skills = try await client.listSkills()
        } catch {
            print("Failed to fetch skills: \(error)")
        }
    }

    private func buildProjectGroups() {
        var groups: [String: ProjectGroup] = [:]
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0.name) })

        for task in tasks {
            let pid = task.projectId ?? "ungrouped"
            let pname = projectMap[pid] ?? "Ungrouped"
            if groups[pid] == nil {
                groups[pid] = ProjectGroup(id: pid, name: pname, tasks: [])
            }
            groups[pid]?.tasks.append(task)
        }
        projectGroups = groups.values.sorted { $0.activeTasks > $1.activeTasks }
    }

    // MARK: - Drag & Drop File Handling

    func handleDroppedFiles(_ urls: [URL]) {
        let fileNames = urls.map { $0.lastPathComponent }
        droppedFileNames = fileNames
        pendingDropFiles = urls
        dropPromptText = ""
        showDropPrompt = true
        isDragOver = false
    }

    func removeDroppedFile(at index: Int) {
        guard index >= 0 && index < pendingDropFiles.count else { return }
        pendingDropFiles.remove(at: index)
        droppedFileNames.remove(at: index)
        if pendingDropFiles.isEmpty {
            cancelDropPrompt()
        }
    }

    func submitDropPrompt() async {
        guard !pendingDropFiles.isEmpty else { return }
        let fileContext = droppedFileNames.joined(separator: ", ")
        let userText = dropPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt: String

        if userText.isEmpty {
            prompt = "Work with these files: \(fileContext)"
        } else {
            prompt = "\(userText)\n\nFiles: \(fileContext)"
        }

        if let activeTask = activeTasks.first {
            await sendMessageToTask(activeTask.id, content: prompt)
        } else {
            await createNewTask(prompt: prompt)
        }

        showDropPrompt = false
        dropPromptText = ""
        pendingDropFiles = []
        droppedFileNames = []
    }

    func cancelDropPrompt() {
        showDropPrompt = false
        dropPromptText = ""
        pendingDropFiles = []
        droppedFileNames = []
    }

    // MARK: - Polling

    func startPolling() {
        guard !apiKey.isEmpty else { return }
        stopPolling()
        Task { await refresh() }
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    func restartPolling() {
        stopPolling()
        startPolling()
    }

    func refresh() async {
        guard let client = apiClient, !apiKey.isEmpty else {
            isConnected = false
            return
        }
        isLoading = true
        do {
            let fetched = try await client.fetchEnrichedTasks()
            checkForStatusChanges(newTasks: fetched)
            self.tasks = fetched
            self.accountStats = await client.computeAccountStats(from: fetched)
            self.aggregatedToolStats = await client.computeAggregatedToolStats(from: fetched)
            self.scheduledTasks = await client.computeScheduledTasks(from: fetched)
            // Fetch daily activity for heatmap (every 5 minutes to avoid rate limits)
            if Date().timeIntervalSince(lastActivityFetch) > 300 {
                self.dailyActivity = await client.fetchDailyActivity()
                self.lastActivityFetch = Date()
            }
            self.lastRefresh = Date()
            self.lastError = nil
            self.isConnected = true
            buildProjectGroups()
        } catch {
            self.lastError = error.localizedDescription
            self.isConnected = false
        }
        isLoading = false
    }

    // MARK: - Task Detail Drill-Down

    func fetchDetail(for taskId: String) async {
        guard let client = apiClient else { return }
        isLoadingDetail = true
        do {
            let detail = try await client.fetchTaskDetail(taskId: taskId)
            self.taskDetail = TaskDetailData(
                activityFeed: detail.activityFeed,
                deliverables: detail.deliverables,
                toolStats: detail.toolStats,
                planSteps: detail.planSteps,
                conversationCount: detail.conversationCount,
                lastExplanation: detail.lastExplanation
            )
        } catch {
            self.taskDetail = nil
        }
        isLoadingDetail = false
    }

    func selectTask(_ taskId: String?) {
        selectedTaskId = taskId
        taskDetail = nil
        if let id = taskId {
            Task { await fetchDetail(for: id) }
        }
    }

    // MARK: - Quick Actions

    func stopTask(_ taskId: String) async {
        guard let client = apiClient else { return }
        isStoppingTask = true
        do {
            try await client.stopTask(taskId: taskId)
            await refresh()
        } catch { /* ignore */ }
        isStoppingTask = false
    }

    func sendMessageToTask(_ taskId: String, content: String) async {
        guard let client = apiClient, !content.isEmpty else { return }
        isSendingMessage = true
        do {
            try await client.sendMessage(taskId: taskId, content: content)
            quickMessageText = ""
            await refresh()
        } catch { /* ignore */ }
        isSendingMessage = false
    }

    func confirmTaskAction(_ taskId: String) async {
        guard let client = apiClient else { return }
        // Find the waiting event ID from the task
        let eventId = tasks.first(where: { $0.id == taskId })?.waitingForEventId ?? ""
        guard !eventId.isEmpty else {
            print("[TaskStore] No waitingForEventId found for task \(taskId), trying sendMessage instead")
            // Fallback: if no event ID, try sending a confirmation message
            do {
                try await client.sendMessage(taskId: taskId, content: "Confirmed")
                await refresh()
            } catch { print("[TaskStore] sendMessage fallback also failed: \(error)") }
            return
        }
        do {
            try await client.confirmAction(taskId: taskId, eventId: eventId)
            await refresh()
        } catch { print("[TaskStore] confirmAction failed: \(error)") }
    }

    func createNewTask(prompt: String) async {
        guard let client = apiClient, !prompt.isEmpty else { return }
        isCreatingTask = true
        do {
            let _ = try await client.createTask(prompt: prompt)
            newTaskPrompt = ""
            await refresh()
        } catch { /* ignore */ }
        isCreatingTask = false
    }

    // MARK: - Voice Input

    func startVoiceRecording() {
        voiceInput.startRecording()
    }

    func stopVoiceAndCreateTask() async {
        if let text = await voiceInput.stopRecording(), !text.isEmpty {
            newTaskPrompt = text
            await createNewTask(prompt: text)
        }
    }

    func stopVoiceAndSendMessage(taskId: String) async {
        if let text = await voiceInput.stopRecording(), !text.isEmpty {
            quickMessageText = text
            await sendMessageToTask(taskId, content: text)
        }
    }

    // MARK: - Export

    func exportTaskSummary(_ task: ManusTask) -> String {
        var lines: [String] = []
        lines.append("# \(task.taskName)")
        lines.append("")
        lines.append("- **Status:** \(task.status.label)")
        lines.append("- **Duration:** \(TaskStore.formatDuration(task.timeSpent))")
        lines.append("- **Steps:** \(task.currentStepIndex)/\(task.totalSteps)")
        lines.append("- **Messages:** \(task.conversationCount)")
        lines.append("- **Credits Used:** \(task.creditsUsed > 0 ? "\(task.creditsUsed)" : "N/A")")
        lines.append("- **Tool Calls:** \(task.totalToolCalls)")
        if !task.topTools.isEmpty {
            lines.append("- **Top Tools:** \(task.topTools)")
        }
        lines.append("- **Created:** \(task.createdAt)")
        lines.append("")
        if !task.planSteps.isEmpty {
            lines.append("## Plan")
            for (i, step) in task.planSteps.enumerated() {
                let icon = step.status == "done" ? "[x]" : (step.status == "doing" ? "[~]" : "[ ]")
                lines.append("- \(icon) \(step.title ?? "Step \(i+1)")")
            }
            lines.append("")
        }
        if !task.activityDescription.isEmpty {
            lines.append("## Current Activity")
            lines.append(task.activityDescription)
        }
        return lines.joined(separator: "\n")
    }

    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: - Formatting Helpers

    static func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return String(format: "%ds", s)
    }

    static func formatTimeAgo(_ date: Date) -> String {
        let i = Date().timeIntervalSince(date)
        if i < 60 { return "just now" }
        if i < 3600 { return "\(Int(i / 60))m ago" }
        if i < 86400 { return "\(Int(i / 3600))h ago" }
        return "\(Int(i / 86400))d ago"
    }

    static func formatTimestamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }
}

// MARK: - Task Detail Data

struct TaskDetailData {
    let activityFeed: [ActivityItem]
    let deliverables: [Deliverable]
    let toolStats: [ToolStat]
    let planSteps: [PlanStep]
    let conversationCount: Int
    let lastExplanation: String
}

// MARK: - Webhook Local Server (lightweight HTTP listener)

class WebhookLocalServer {
    private var serverSocket: Int32 = -1
    private var isRunning = false
    private let onEvent: ([String: Any]) -> Void
    private var listenThread: Thread?
    var port: UInt16 = 0

    init(onEvent: @escaping ([String: Any]) -> Void) {
        self.onEvent = onEvent
    }

    func start() {
        guard !isRunning else { return }

        serverSocket = socket(AF_INET, SOCK_STREAM, 0)
        guard serverSocket >= 0 else { return }

        var opt: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &opt, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 0 // Let OS assign port
        addr.sin_addr.s_addr = INADDR_ANY

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                bind(serverSocket, sockPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else { close(serverSocket); return }

        // Get assigned port
        var assignedAddr = sockaddr_in()
        var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        withUnsafeMutablePointer(to: &assignedAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                getsockname(serverSocket, sockPtr, &addrLen)
            }
        }
        port = UInt16(bigEndian: assignedAddr.sin_port)

        guard listen(serverSocket, 5) == 0 else { close(serverSocket); return }

        isRunning = true
        listenThread = Thread {
            self.acceptLoop()
        }
        listenThread?.start()

        print("Webhook server listening on port \(port)")
    }

    private func acceptLoop() {
        while isRunning {
            var clientAddr = sockaddr_in()
            var clientAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            let clientSocket = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                    accept(serverSocket, sockPtr, &clientAddrLen)
                }
            }
            guard clientSocket >= 0 else { continue }

            // Read request
            var buffer = [UInt8](repeating: 0, count: 8192)
            let bytesRead = read(clientSocket, &buffer, buffer.count)
            if bytesRead > 0 {
                let requestStr = String(bytes: buffer[0..<bytesRead], encoding: .utf8) ?? ""

                // Parse body (after double newline)
                if let bodyRange = requestStr.range(of: "\r\n\r\n") {
                    let body = String(requestStr[bodyRange.upperBound...])
                    if let data = body.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.onEvent(json)
                    }
                }

                // Send 200 OK
                let response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK"
                _ = response.withCString { ptr in
                    write(clientSocket, ptr, strlen(ptr))
                }
            }
            close(clientSocket)
        }
    }

    func stop() {
        isRunning = false
        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }
    }
}

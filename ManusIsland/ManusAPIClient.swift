import Foundation
import AppKit

// MARK: - API Response Models

struct TaskListResponse: Decodable {
    let ok: Bool
    let data: [TaskSummary]?
    let hasMore: Bool?
    let nextCursor: String?
    enum CodingKeys: String, CodingKey {
        case ok, data
        case hasMore = "has_more"
        case nextCursor = "next_cursor"
    }
}

struct TaskSummary: Decodable, Identifiable {
    let id: String
    let status: String
    let createdAt: String
    let updatedAt: String
    let taskType: String?
    let shareVisibility: String?
    let projectId: String?
    enum CodingKeys: String, CodingKey {
        case id, status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case taskType = "task_type"
        case shareVisibility = "share_visibility"
        case projectId = "project_id"
    }
    var createdAtDate: Date { Date(timeIntervalSince1970: TimeInterval(createdAt) ?? 0) }
    var updatedAtDate: Date { Date(timeIntervalSince1970: TimeInterval(updatedAt) ?? 0) }
}

struct TaskMessagesResponse: Decodable {
    let ok: Bool
    let messages: [TaskMessage]?
    let hasMore: Bool?
    let nextCursor: String?
    enum CodingKeys: String, CodingKey {
        case ok, messages
        case hasMore = "has_more"
        case nextCursor = "next_cursor"
    }
}

struct TaskMessage: Decodable {
    let id: String?
    let type: String?
    let timestamp: String?
    let userMessage: UserMessage?
    let assistantMessage: AssistantMessage?
    let statusUpdate: StatusUpdate?
    let toolUsed: ToolUsed?
    let planUpdate: PlanUpdate?
    let newPlanStep: NewPlanStep?
    let explanation: Explanation?
    enum CodingKeys: String, CodingKey {
        case id, type, timestamp
        case userMessage = "user_message"
        case assistantMessage = "assistant_message"
        case statusUpdate = "status_update"
        case toolUsed = "tool_used"
        case planUpdate = "plan_update"
        case newPlanStep = "new_plan_step"
        case explanation
    }
    var timestampMs: Int64 { Int64(timestamp ?? "0") ?? 0 }
    var timestampDate: Date { Date(timeIntervalSince1970: Double(timestampMs) / 1000.0) }
}

struct UserMessage: Decodable {
    let content: String?
    let messageType: String?
    let attachments: [Attachment]?
    enum CodingKeys: String, CodingKey {
        case content
        case messageType = "message_type"
        case attachments
    }
}

struct AssistantMessage: Decodable {
    let content: String?
    let attachments: [Attachment]?
}

struct Attachment: Decodable {
    let type: String?
    let filename: String?
    let contentType: String?
    let url: String?
    enum CodingKeys: String, CodingKey {
        case type, filename, url
        case contentType = "content_type"
    }
}

struct Explanation: Decodable { let content: String? }

struct StatusUpdate: Decodable {
    let agentStatus: String?
    let brief: String?
    let description: String?
    let statusDetail: StatusDetail?
    let waitingForEventId: String?
    let waitingForEventType: String?
    enum CodingKeys: String, CodingKey {
        case agentStatus = "agent_status"
        case brief, description
        case statusDetail = "status_detail"
        case waitingForEventId = "waiting_for_event_id"
        case waitingForEventType = "waiting_for_event_type"
    }
}

struct StatusDetail: Decodable {
    let waitingDescription: String?
    enum CodingKeys: String, CodingKey {
        case waitingDescription = "waiting_description"
    }
}

struct ToolUsed: Decodable {
    let tool: String?
    let status: String?
    let brief: String?
    let description: String?
    let actionId: String?
    let message: ToolMessage?
    enum CodingKeys: String, CodingKey {
        case tool, status, brief, description, message
        case actionId = "action_id"
    }
}

struct ToolMessage: Decodable {
    let action: String?
    let param: String?
}

struct PlanUpdate: Decodable { let steps: [PlanStep]? }

struct PlanStep: Decodable, Identifiable {
    var id: String { "\(title ?? "")-\(status ?? "")-\(startedAt ?? "")" }
    let status: String?
    let title: String?
    let startedAt: String?
    let endAt: String?
    enum CodingKeys: String, CodingKey {
        case status, title
        case startedAt = "started_at"
        case endAt = "end_at"
    }
    var startedAtDate: Date? {
        guard let s = startedAt, let ms = Double(s) else { return nil }
        return Date(timeIntervalSince1970: ms / 1000.0)
    }
    var endAtDate: Date? {
        guard let e = endAt, let ms = Double(e) else { return nil }
        return Date(timeIntervalSince1970: ms / 1000.0)
    }
    var duration: TimeInterval? {
        guard let s = startedAtDate, let e = endAtDate else { return nil }
        let d = e.timeIntervalSince(s)
        return d > 0 ? d : nil
    }
}

struct NewPlanStep: Decodable {
    let stepId: String?
    let title: String?
    enum CodingKeys: String, CodingKey {
        case stepId = "step_id"
        case title
    }
}

// MARK: - Simple action responses

struct SimpleResponse: Decodable { let ok: Bool }
struct CreateTaskResponse: Decodable {
    let ok: Bool
    let task_id: String?
    let task_url: String?
    let task_title: String?
    var id: String? { task_id }
}

// MARK: - Usage Models

struct UsageListResponse: Decodable {
    let ok: Bool
    let data: [UsageRecord]?
    let hasMore: Bool?
    let nextCursor: String?
    enum CodingKeys: String, CodingKey {
        case ok, data
        case hasMore = "has_more"
        case nextCursor = "next_cursor"
    }
}

struct UsageRecord: Decodable {
    let taskId: String?
    let title: String?
    let credits: Int?       // Negative = consumption, positive = refund/grant
    let createdAt: Int?
    let type: String?       // "cost", "refund", or "grant"
    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case title, credits, type
        case createdAt = "created_at"
    }
}

// MARK: - Website Models

struct WebsiteStatusResponse: Decodable {
    let ok: Bool
    let websiteId: String?
    let publishStatus: String?  // unpublished, publishing, published, failed
    let versionId: String?
    let title: String?
    let visibility: String?  // public, team, private
    let siteUrls: [String]?
    enum CodingKeys: String, CodingKey {
        case ok
        case websiteId = "website_id"
        case publishStatus = "publish_status"
        case versionId = "version_id"
        case title, visibility
        case siteUrls = "site_urls"
    }
}

struct WebsiteCheckpoint: Decodable, Identifiable {
    let versionId: String?
    let message: String?
    let status: String?  // pending, success, failed
    let createdAt: Int?
    var id: String { versionId ?? UUID().uuidString }
    enum CodingKeys: String, CodingKey {
        case versionId = "version_id"
        case message, status
        case createdAt = "created_at"
    }
}

struct WebsiteCheckpointsResponse: Decodable {
    let ok: Bool
    let data: [WebsiteCheckpoint]?
    let publishedVersionId: String?
    enum CodingKeys: String, CodingKey {
        case ok, data
        case publishedVersionId = "published_version_id"
    }
}

struct WebsitePublishResponse: Decodable {
    let ok: Bool
    let websiteId: String?
    let versionId: String?
    enum CodingKeys: String, CodingKey {
        case ok
        case websiteId = "website_id"
        case versionId = "version_id"
    }
}

struct WebsiteUpdateResponse: Decodable {
    let ok: Bool
}

// MARK: - Browser Models

struct BrowserClient: Decodable, Identifiable {
    let clientId: String?
    let clientName: String?
    let ua: String?
    var id: String { clientId ?? UUID().uuidString }
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientName = "client_name"
        case ua
    }
}

struct BrowserOnlineListResponse: Decodable {
    let ok: Bool
    let data: [BrowserClient]?
}

// MARK: - Team Usage Statistics

struct TeamStatisticResponse: Decodable {
    let ok: Bool
    let data: [DailyStatistic]?
}

struct DailyStatistic: Decodable, Identifiable {
    let dateTimestamp: Int   // Unix timestamp at 00:00:00 of that day
    let credits: Int         // Total credits consumed on this day (negative = consumption)
    var id: Int { dateTimestamp }
    var dateValue: Date { Date(timeIntervalSince1970: TimeInterval(dateTimestamp)) }
    var absCredits: Int { abs(credits) }

    enum CodingKeys: String, CodingKey {
        case date, credits
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // date can be either String or Int from the API
        if let dateStr = try? container.decode(String.self, forKey: .date),
           let ts = Int(dateStr) {
            self.dateTimestamp = ts
        } else if let dateInt = try? container.decode(Int.self, forKey: .date) {
            self.dateTimestamp = dateInt
        } else {
            self.dateTimestamp = 0
        }
        self.credits = try container.decode(Int.self, forKey: .credits)
    }

    // Manual init for fallback construction
    init(dateTimestamp: Int, credits: Int) {
        self.dateTimestamp = dateTimestamp
        self.credits = credits
    }
}

// MARK: - Website Info (for task display)

struct WebsiteInfo {
    var websiteId: String = ""
    var publishStatus: String = ""  // unpublished, publishing, published, failed
    var title: String = ""
    var siteUrl: String = ""
    var visibility: String = ""
    var checkpointCount: Int = 0
    
    var isPublished: Bool { publishStatus == "published" }
    var statusLabel: String {
        switch publishStatus {
        case "published": return "Live"
        case "publishing": return "Deploying..."
        case "unpublished": return "Not Published"
        case "failed": return "Deploy Failed"
        default: return ""
        }
    }
    var statusIcon: String {
        switch publishStatus {
        case "published": return "globe"
        case "publishing": return "arrow.triangle.2.circlepath"
        case "unpublished": return "globe.badge.chevron.backward"
        case "failed": return "exclamationmark.triangle"
        default: return "globe"
        }
    }
}

// MARK: - Project Models

struct ProjectListResponse: Decodable {
    let ok: Bool
    let data: [ProjectSummary]?
}

struct ProjectSummary: Decodable, Identifiable {
    let id: String
    let name: String
    let createdAt: String?
    let updatedAt: String?
    enum CodingKeys: String, CodingKey {
        case id, name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Connector Models

struct ConnectorListResponse: Decodable {
    let ok: Bool
    let data: [ConnectorInfo]?
}

struct ConnectorInfo: Decodable, Identifiable {
    let id: String
    let name: String
    let type: String?
    let description: String?

    var icon: String {
        let lower = name.lowercased()
        if lower.contains("slack") { return "number.square.fill" }
        if lower.contains("github") { return "chevron.left.forwardslash.chevron.right" }
        if lower.contains("gmail") || lower.contains("email") { return "envelope.fill" }
        if lower.contains("notion") { return "doc.text.fill" }
        if lower.contains("hubspot") { return "person.2.fill" }
        if lower.contains("canva") { return "paintbrush.fill" }
        if lower.contains("calendar") { return "calendar" }
        if lower.contains("drive") { return "externaldrive.fill" }
        if lower.contains("meta") || lower.contains("instagram") { return "camera.fill" }
        if lower.contains("granola") { return "mic.fill" }
        return "puzzlepiece.extension.fill"
    }

    var typeLabel: String {
        switch type {
        case "mcp": return "MCP"
        case "byok": return "BYOK"
        case "builtin": return "Built-in"
        default: return type?.uppercased() ?? "Unknown"
        }
    }
}

// MARK: - Skill Models

struct SkillListResponse: Decodable {
    let ok: Bool
    let data: [SkillInfo]?
}

struct SkillInfo: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let ownerType: String?
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case ownerType = "owner_type"
    }

    var icon: String {
        let lower = name.lowercased()
        if lower.contains("write") || lower.contains("content") { return "doc.text" }
        if lower.contains("research") { return "magnifyingglass" }
        if lower.contains("code") || lower.contains("dev") { return "chevron.left.forwardslash.chevron.right" }
        if lower.contains("design") || lower.contains("image") { return "paintbrush" }
        if lower.contains("data") || lower.contains("analy") { return "chart.bar" }
        if lower.contains("video") { return "video" }
        if lower.contains("audio") || lower.contains("music") { return "waveform" }
        if lower.contains("slide") || lower.contains("present") { return "rectangle.on.rectangle" }
        if lower.contains("excel") || lower.contains("spread") { return "tablecells" }
        if lower.contains("qa") || lower.contains("test") { return "checkmark.shield" }
        if lower.contains("campaign") || lower.contains("market") { return "megaphone" }
        return "sparkles"
    }

    var ownerLabel: String {
        switch ownerType {
        case "system": return "System"
        case "user": return "Custom"
        case "org": return "Organization"
        default: return ownerType?.capitalized ?? "Unknown"
        }
    }
}

// MARK: - Aggregated Tool Stats (cross-task)

struct AggregatedToolStat: Identifiable {
    let id: String
    let tool: String
    var totalUses: Int
    var successCount: Int
    var taskCount: Int // how many tasks used this tool
    var successRate: Double { totalUses > 0 ? Double(successCount) / Double(totalUses) : 0 }

    var icon: String {
        switch tool {
        case "browser": return "globe"
        case "terminal": return "terminal"
        case "text_editor": return "doc.text"
        case "search": return "magnifyingglass"
        case "media_viewer": return "photo"
        case "suggestion": return "lightbulb"
        case "code_executor": return "chevron.left.forwardslash.chevron.right"
        default: return "wrench"
        }
    }

    var displayName: String {
        switch tool {
        case "browser": return "Browser"
        case "terminal": return "Terminal"
        case "text_editor": return "Editor"
        case "search": return "Search"
        case "media_viewer": return "Media"
        case "suggestion": return "Suggest"
        case "code_executor": return "Code"
        default: return tool.capitalized
        }
    }
}

// MARK: - Scheduled Task Info (ETA estimation)

struct ScheduledTaskInfo: Identifiable {
    let id: String
    let taskName: String
    let status: ManusTask.TaskStatus
    let createdAt: Date
    let progress: Double
    let currentStep: String
    let totalSteps: Int
    let completedSteps: Int
    let timeSpent: TimeInterval

    var estimatedTimeRemaining: TimeInterval? {
        guard progress > 0.05 && progress < 1.0 else { return nil }
        let elapsed = timeSpent
        let estimated = elapsed / progress
        let remaining = estimated - elapsed
        return remaining > 0 ? remaining : nil
    }

    var estimatedCompletion: Date? {
        guard let remaining = estimatedTimeRemaining else { return nil }
        return Date().addingTimeInterval(remaining)
    }

    var etaString: String {
        guard let remaining = estimatedTimeRemaining else { return "Calculating..." }
        let mins = Int(remaining / 60)
        if mins < 1 { return "< 1 min" }
        if mins < 60 { return "~\(mins) min" }
        let hours = mins / 60
        let remMins = mins % 60
        return "~\(hours)h \(remMins)m"
    }

    var completionTimeString: String {
        guard let completion = estimatedCompletion else { return "--" }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: completion)
    }
}

// MARK: - Webhook Models

struct WebhookCreateResponse: Decodable {
    let ok: Bool
    let data: WebhookData?
}

struct WebhookData: Decodable {
    let id: String?
    let url: String?
    let events: [String]?
    let status: String?
}

// MARK: - Activity Feed Item

struct ActivityItem: Identifiable {
    let id: String
    let timestamp: Date
    let type: ActivityType
    let title: String
    let detail: String
    let status: String?

    enum ActivityType: String {
        case tool, explanation, status, message, plan
        var icon: String {
            switch self {
            case .tool: return "wrench.and.screwdriver"
            case .explanation: return "brain"
            case .status: return "info.circle"
            case .message: return "bubble.left"
            case .plan: return "list.bullet.clipboard"
            }
        }
    }
}

// MARK: - Deliverable

struct Deliverable: Identifiable {
    let id: String
    let filename: String
    let contentType: String
    let url: String
    let type: String

    var icon: String {
        if type == "image" || contentType.hasPrefix("image") { return "photo" }
        if contentType.contains("markdown") || contentType.contains("text") { return "doc.text" }
        if contentType.contains("pdf") { return "doc.richtext" }
        if contentType.contains("spreadsheet") || contentType.contains("excel") { return "tablecells" }
        return "doc"
    }
}

// MARK: - Tool Stats

struct ToolStat: Identifiable {
    let id: String
    let tool: String
    let count: Int
    let successCount: Int
    var failureCount: Int { count - successCount }
    var successRate: Double { count > 0 ? Double(successCount) / Double(count) : 0 }

    var icon: String {
        switch tool {
        case "browser": return "globe"
        case "terminal": return "terminal"
        case "text_editor": return "doc.text"
        case "search": return "magnifyingglass"
        case "media_viewer": return "photo"
        case "suggestion": return "lightbulb"
        case "code_executor": return "chevron.left.forwardslash.chevron.right"
        default: return "wrench"
        }
    }

    var displayName: String {
        switch tool {
        case "browser": return "Browser"
        case "terminal": return "Terminal"
        case "text_editor": return "Editor"
        case "search": return "Search"
        case "media_viewer": return "Media"
        case "suggestion": return "Suggest"
        case "code_executor": return "Code"
        default: return tool.capitalized
        }
    }
}

// MARK: - Enriched Task Model

struct ManusTask: Identifiable {
    let id: String
    let status: TaskStatus
    let createdAt: Date
    let updatedAt: Date
    let taskType: String
    var taskName: String
    var currentStep: String
    var currentStepIndex: Int
    var totalSteps: Int
    var planSteps: [PlanStep]
    var statusBrief: String
    var currentTool: String
    var currentToolBrief: String
    var timeSpent: TimeInterval
    var waitingDescription: String
    var waitingForEventId: String
    var waitingForEventType: String
    var activityFeed: [ActivityItem]
    var deliverables: [Deliverable]
    var toolStats: [ToolStat]
    var conversationCount: Int
    var lastExplanation: String
    var projectId: String?
    var creditsUsed: Int
    var totalToolCalls: Int
    var topTools: String  // e.g. "Browser 12, Terminal 8, Editor 5"
    var websiteInfo: WebsiteInfo?

    enum TaskStatus: String {
        case running, stopped, waiting, error, unknown
        init(from string: String) { self = TaskStatus(rawValue: string) ?? .unknown }
        var label: String {
            switch self {
            case .running: return "Running"
            case .stopped: return "Completed"
            case .waiting: return "Waiting"
            case .error: return "Error"
            case .unknown: return "Unknown"
            }
        }
        var isActive: Bool { self == .running || self == .waiting }
    }

    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        let done = planSteps.filter { $0.status == "done" }.count
        return Double(done) / Double(totalSteps)
    }

    var activityDescription: String {
        if !currentToolBrief.isEmpty { return currentToolBrief }
        if !statusBrief.isEmpty { return statusBrief }
        if !currentStep.isEmpty { return currentStep }
        return status.label
    }

    var toolIcon: String {
        switch currentTool {
        case "browser": return "globe"
        case "terminal": return "terminal"
        case "text_editor": return "doc.text"
        case "search": return "magnifyingglass"
        case "media_viewer": return "photo"
        case "code_executor": return "chevron.left.forwardslash.chevron.right"
        default: return "gearshape"
        }
    }

    var doingStep: PlanStep? {
        planSteps.first { $0.status == "doing" }
    }

    var currentStepTitle: String {
        doingStep?.title ?? currentStep
    }

    var nextSteps: [PlanStep] {
        planSteps.filter { $0.status == "todo" }
    }

    var completedSteps: [PlanStep] {
        planSteps.filter { $0.status == "done" }
    }

    var stepLabel: String {
        guard totalSteps > 0 else { return "" }
        return "Step \(currentStepIndex)/\(totalSteps)"
    }

    var webURL: URL? {
        URL(string: "https://manus.im/app/\(id)")
    }

    var browserURL: String {
        "https://manus.im/app/\(id)"
    }

    func openInBrowser() {
        guard let url = webURL else { return }
        openURLInChrome(url)
    }
}

// MARK: - Open in Chrome Helper

func openURLInChrome(_ url: URL) {
    if let chromeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") {
        NSWorkspace.shared.open([url], withApplicationAt: chromeURL, configuration: NSWorkspace.OpenConfiguration())
    } else {
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Account Stats

struct AccountStats {
    var totalTasksToday: Int = 0
    var totalTasksThisWeek: Int = 0
    var totalTasksAllTime: Int = 0
    var runningNow: Int = 0
    var waitingNow: Int = 0
    var avgDurationToday: TimeInterval = 0
    var longestTaskToday: TimeInterval = 0
    var completedToday: Int = 0
    var erroredToday: Int = 0
    var totalCreditsUsed: Int = 0       // Sum of credits across all fetched tasks
    var creditsUsedToday: Int = 0       // Credits consumed today
    var avgCreditsPerTask: Double = 0   // Average credits per task
    var totalRefunds: Int = 0           // Total credits refunded
    var totalGrants: Int = 0            // Total credits granted (subscription, etc.)
}

// MARK: - Project Group (for UI display)

struct ProjectGroup: Identifiable {
    let id: String
    let name: String
    var tasks: [ManusTask]
    var activeTasks: Int { tasks.filter { $0.status.isActive }.count }
    var completedTasks: Int { tasks.filter { $0.status == .stopped }.count }
}

// MARK: - API Client (actor for thread safety)

actor ManusAPIClient {
    private let baseURL = "https://api.manus.ai"
    private var apiKey: String
    private let session: URLSession
    private var taskNameCache: [String: String] = [:]
    private var usageTitleCache: [String: String] = [:]  // task_id -> official title from usage.list
    private var creditCache: [String: Int] = [:]  // task_id -> credits (consumption, negative)
    private var totalRefunds: Int = 0
    private var totalGrants: Int = 0
    private var lastCreditFetch: Date = .distantPast

    init(apiKey: String) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    func updateAPIKey(_ newKey: String) {
        self.apiKey = newKey
        self.taskNameCache.removeAll()
        self.usageTitleCache.removeAll()
        self.creditCache.removeAll()
        self.lastCreditFetch = .distantPast
    }

    // MARK: - Generic GET Request

    private func makeRequest<T: Decodable>(path: String, params: [(String, String)]) async throws -> T {
        var components = URLComponents(string: "\(baseURL)/v2/\(path)")!
        components.queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-manus-api-key")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw ManusAPIError.requestFailed(statusCode: code)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Generic POST Request

    private func makePostRequest<T: Decodable>(path: String, body: [String: Any]) async throws -> T {
        var components = URLComponents(string: "\(baseURL)/v2/\(path)")!
        components.queryItems = []
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-manus-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw ManusAPIError.requestFailed(statusCode: code)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Read API Calls

    /// Fetch a single page of tasks with optional cursor
    func listTasksPage(limit: Int = 100, cursor: String? = nil) async throws -> TaskListResponse {
        var params = [("limit", "\(limit)"), ("scope", "all"), ("order", "desc")]
        if let cursor = cursor { params.append(("cursor", cursor)) }
        let resp: TaskListResponse = try await makeRequest(path: "task.list", params: params)
        guard resp.ok else { throw ManusAPIError.apiError("API returned error") }
        return resp
    }

    /// Fetch tasks with pagination — scans pages until all running/waiting tasks are found
    func listAllTasks(recentLimit: Int = 100) async throws -> [TaskSummary] {
        var allTasks: [TaskSummary] = []
        var cursor: String? = nil
        let maxPages = 10 // Scan up to 1000 tasks to find all active/error tasks

        for page in 0..<maxPages {
            let resp = try await listTasksPage(limit: recentLimit, cursor: cursor)
            let pageTasks = resp.data ?? []
            allTasks.append(contentsOf: pageTasks)

            let hasMore = resp.hasMore ?? false
            if !hasMore { break }

            // After first 2 pages (200 tasks), only continue if we're still finding active/error tasks
            if page >= 1 {
                let lastPageActive = pageTasks.filter { $0.status == "running" || $0.status == "waiting" || $0.status == "error" }.count
                if lastPageActive == 0 { break }
            }

            cursor = resp.nextCursor
            if cursor == nil { break }
        }

        return allTasks
    }

    /// Legacy single-page fetch
    func listTasks(limit: Int = 20) async throws -> [TaskSummary] {
        let resp = try await listTasksPage(limit: limit)
        return resp.data ?? []
    }

    func listMessages(taskId: String, limit: Int = 50, order: String = "desc", verbose: Bool = true) async throws -> [TaskMessage] {
        let resp: TaskMessagesResponse = try await makeRequest(
            path: "task.listMessages",
            params: [
                ("task_id", taskId),
                ("limit", "\(limit)"),
                ("order", order),
                ("verbose", verbose ? "true" : "false")
            ]
        )
        guard resp.ok else { throw ManusAPIError.apiError("API returned error") }
        return resp.messages ?? []
    }

    // MARK: - Project API

    func listProjects() async throws -> [ProjectSummary] {
        let resp: ProjectListResponse = try await makeRequest(
            path: "project.list",
            params: []
        )
        guard resp.ok else { throw ManusAPIError.apiError("API returned error") }
        return resp.data ?? []
    }

    // MARK: - Connector API

    func listConnectors() async throws -> [ConnectorInfo] {
        let resp: ConnectorListResponse = try await makeRequest(
            path: "connector.list",
            params: []
        )
        guard resp.ok else { throw ManusAPIError.apiError("API returned error") }
        return resp.data ?? []
    }

    // MARK: - Skill API

    func listSkills() async throws -> [SkillInfo] {
        let resp: SkillListResponse = try await makeRequest(
            path: "skill.list",
            params: []
        )
        guard resp.ok else { throw ManusAPIError.apiError("API returned error") }
        return resp.data ?? []
    }

    // MARK: - Website API

    /// Get website status for a task
    func getWebsiteStatus(taskId: String) async throws -> WebsiteStatusResponse {
        let resp: WebsiteStatusResponse = try await makeRequest(
            path: "website.status",
            params: [("task_id", taskId)]
        )
        return resp
    }

    /// List website checkpoints for a task
    func listWebsiteCheckpoints(taskId: String) async throws -> WebsiteCheckpointsResponse {
        let resp: WebsiteCheckpointsResponse = try await makeRequest(
            path: "website.listCheckpoints",
            params: [("task_id", taskId)]
        )
        return resp
    }

    /// Publish a website (deploys latest checkpoint)
    func publishWebsite(taskId: String, visibility: String = "public") async throws -> WebsitePublishResponse {
        let resp: WebsitePublishResponse = try await makePostRequest(
            path: "website.publish",
            body: ["task_id": taskId, "visibility": visibility]
        )
        return resp
    }

    /// Update website metadata (title, visibility)
    func updateWebsite(websiteId: String, title: String? = nil, visibility: String? = nil) async throws -> WebsiteUpdateResponse {
        var body: [String: Any] = ["website_id": websiteId]
        if let t = title { body["title"] = t }
        if let v = visibility { body["visibility"] = v }
        let resp: WebsiteUpdateResponse = try await makePostRequest(
            path: "website.update",
            body: body
        )
        return resp
    }

    // MARK: - Browser API

    /// List online browser clients
    func listOnlineBrowserClients() async throws -> [BrowserClient] {
        let resp: BrowserOnlineListResponse = try await makeRequest(
            path: "browser.onlineList",
            params: []
        )
        guard resp.ok else { throw ManusAPIError.apiError("API returned error") }
        return resp.data ?? []
    }

    // MARK: - Team Usage Statistics

    /// Get daily credit consumption totals for the team over a date range
    func getTeamStatistic(startDate: Int? = nil, endDate: Int? = nil) async throws -> [DailyStatistic] {
        var params: [(String, String)] = []
        if let s = startDate { params.append(("start_date", "\(s)")) }
        if let e = endDate { params.append(("end_date", "\(e)")) }
        let resp: TeamStatisticResponse = try await makeRequest(
            path: "usage.teamStatistic",
            params: params
        )
        guard resp.ok else { throw ManusAPIError.apiError("API returned error") }
        return resp.data ?? []
    }

    /// Fetch daily activity data for the heatmap (last 365 days)
    /// Falls back to aggregating usage.list if teamStatistic fails (individual users)
    func fetchDailyActivity() async -> [DailyStatistic] {
        let now = Date()
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .day, value: -365, to: now) ?? now
        let startTimestamp = Int(oneYearAgo.timeIntervalSince1970)
        let endTimestamp = Int(now.timeIntervalSince1970)

        // Try teamStatistic first (works for team users)
        if let stats = try? await getTeamStatistic(startDate: startTimestamp, endDate: endTimestamp), !stats.isEmpty {
            return stats
        }

        // Fallback: aggregate from usage.list (works for all users)
        // Group credits by day from the creditCache
        var dailyMap: [Int: Int] = [:]
        var cursor: String? = nil
        for _ in 0..<10 {  // Max 10 pages = 1000 records
            var params = [("limit", "100")]
            if let c = cursor { params.append(("cursor", c)) }
            guard let resp: UsageListResponse = try? await makeRequest(path: "usage.list", params: params) else { break }
            guard resp.ok else { break }
            for record in resp.data ?? [] {
                guard let createdAt = record.createdAt, let credits = record.credits else { continue }
                // Count all credit usage (abs value)
                let amount = abs(credits)
                guard amount > 0 else { continue }
                let recordDate = Date(timeIntervalSince1970: TimeInterval(createdAt))
                let dayStart = calendar.startOfDay(for: recordDate)
                let dayTimestamp = Int(dayStart.timeIntervalSince1970)
                dailyMap[dayTimestamp, default: 0] += amount
            }
            if resp.hasMore == true, let next = resp.nextCursor {
                cursor = next
            } else { break }
        }

        // If still empty, generate from creditCache as last resort
        if dailyMap.isEmpty {
            for (_, credits) in creditCache where credits != 0 {
                let todayTimestamp = Int(calendar.startOfDay(for: now).timeIntervalSince1970)
                dailyMap[todayTimestamp, default: 0] += abs(credits)
            }
        }

        return dailyMap.map { DailyStatistic(dateTimestamp: $0.key, credits: $0.value) }
            .sorted { $0.dateTimestamp < $1.dateTimestamp }
    }

    // MARK: - Website Info Fetcher (for active tasks)

    /// Try to fetch website info for a task (returns nil if no website)
    func fetchWebsiteInfo(taskId: String) async -> WebsiteInfo? {
        do {
            let status = try await getWebsiteStatus(taskId: taskId)
            guard status.ok else { return nil }
            var info = WebsiteInfo()
            info.websiteId = status.websiteId ?? ""
            info.publishStatus = status.publishStatus ?? "unpublished"
            info.title = status.title ?? ""
            info.siteUrl = status.siteUrls?.first ?? ""
            info.visibility = status.visibility ?? ""
            // Try to get checkpoint count
            if let checkpoints = try? await listWebsiteCheckpoints(taskId: taskId) {
                info.checkpointCount = checkpoints.data?.count ?? 0
            }
            return info
        } catch {
            // 404 = no website for this task, which is normal
            return nil
        }
    }

    // MARK: - Usage / Credits API

    /// Fetch credit usage for all tasks, cached for 30 seconds
    func fetchUsageCredits() async {
        // Only refresh every 30 seconds to avoid rate limiting
        guard Date().timeIntervalSince(lastCreditFetch) > 30 else { return }
        do {
            var allRecords: [UsageRecord] = []
            var cursor: String? = nil
            for _ in 0..<5 {  // Max 5 pages = 500 records
                var params = [("limit", "100")]
                if let c = cursor { params.append(("cursor", c)) }
                let resp: UsageListResponse = try await makeRequest(path: "usage.list", params: params)
                guard resp.ok else { break }
                allRecords.append(contentsOf: resp.data ?? [])
                if resp.hasMore == true, let next = resp.nextCursor {
                    cursor = next
                } else { break }
            }
            // Update cache and track refunds/grants
            var refunds = 0
            var grants = 0
            for record in allRecords {
                // Cache official titles from usage.list (these match the web UI)
                if let tid = record.taskId, let title = record.title, !title.isEmpty {
                    usageTitleCache[tid] = title
                }
                if let tid = record.taskId, let credits = record.credits {
                    if record.type == "cost" {
                        creditCache[tid] = abs(credits)
                    } else if record.type == "refund" {
                        refunds += abs(credits)
                    } else if record.type == "grant" {
                        grants += credits
                    } else {
                        // Fallback: negative = cost, positive = refund/grant
                        if credits < 0 {
                            creditCache[tid] = abs(credits)
                        } else {
                            grants += credits
                        }
                    }
                }
            }
            totalRefunds = refunds
            totalGrants = grants
            lastCreditFetch = Date()
        } catch {
            // Silently fail — credits are optional data
            print("[ManusAPI] Failed to fetch usage credits: \(error)")
        }
    }

    /// Get cached credits for a task
    func creditsForTask(_ taskId: String) -> Int {
        return creditCache[taskId] ?? 0
    }

    /// Get the official title from usage.list (matches Manus web UI)
    func officialTitle(for taskId: String) -> String? {
        return usageTitleCache[taskId]
    }

    // MARK: - Aggregated Tool Stats

    func computeAggregatedToolStats(from tasks: [ManusTask]) -> [AggregatedToolStat] {
        var agg: [String: (uses: Int, success: Int, tasks: Set<String>)] = [:]
        for task in tasks {
            for stat in task.toolStats {
                var entry = agg[stat.tool] ?? (0, 0, Set<String>())
                entry.uses += stat.count
                entry.success += stat.successCount
                entry.tasks.insert(task.id)
                agg[stat.tool] = entry
            }
        }
        return agg.map { AggregatedToolStat(id: $0.key, tool: $0.key, totalUses: $0.value.uses, successCount: $0.value.success, taskCount: $0.value.tasks.count) }
            .sorted { $0.totalUses > $1.totalUses }
    }

    // MARK: - Compute Scheduled Task ETAs

    func computeScheduledTasks(from tasks: [ManusTask]) -> [ScheduledTaskInfo] {
        return tasks.filter { $0.status == .running }.map { task in
            ScheduledTaskInfo(
                id: task.id,
                taskName: task.taskName,
                status: task.status,
                createdAt: task.createdAt,
                progress: task.progress,
                currentStep: task.currentStep,
                totalSteps: task.totalSteps,
                completedSteps: task.planSteps.filter { $0.status == "done" }.count,
                timeSpent: task.timeSpent
            )
        }
    }

    // MARK: - Webhook API

    func createWebhook(url: String, events: [String]) async throws -> WebhookData? {
        let resp: WebhookCreateResponse = try await makePostRequest(
            path: "webhook.create",
            body: ["url": url, "events": events]
        )
        guard resp.ok else { throw ManusAPIError.apiError("Webhook creation failed") }
        return resp.data
    }

    // MARK: - Quick Actions

    func stopTask(taskId: String) async throws {
        let _: SimpleResponse = try await makePostRequest(
            path: "task.stop",
            body: ["task_id": taskId]
        )
    }

    func sendMessage(taskId: String, content: String) async throws {
        let body: [String: Any] = [
            "task_id": taskId,
            "message": [
                "content": [
                    ["type": "text", "text": content]
                ]
            ]
        ]
        let _: SimpleResponse = try await makePostRequest(path: "task.sendMessage", body: body)
    }

    func confirmAction(taskId: String, eventId: String) async throws {
        var body: [String: Any] = ["task_id": taskId, "event_id": eventId]
        let _: SimpleResponse = try await makePostRequest(
            path: "task.confirmAction",
            body: body
        )
    }

    func createTask(prompt: String) async throws -> String? {
        let body: [String: Any] = [
            "message": [
                "content": [
                    ["type": "text", "text": prompt]
                ]
            ]
        ]
        let resp: CreateTaskResponse = try await makePostRequest(path: "task.create", body: body)
        return resp.task_id
    }

    // MARK: - Fetch Task Name (cached, from first user message)

    func fetchTaskName(taskId: String, isActive: Bool = false) async throws -> String {
        // Priority 0: Use official title from usage.list (matches Manus web UI exactly)
        if let officialTitle = usageTitleCache[taskId], !officialTitle.isEmpty {
            taskNameCache[taskId] = officialTitle
            return officialTitle
        }

        // Don't use cache for active tasks — their names may change as the plan evolves
        if !isActive, let cached = taskNameCache[taskId] { return cached }

        // Fetch messages (verbose=true to get plan_update data)
        let messages = try await listMessages(taskId: taskId, limit: 20, order: "asc", verbose: true)
        let firstUser = messages.first { $0.type == "user_message" }
        let rawPrompt = firstUser?.userMessage?.content ?? ""

        // Gather plan step titles for context
        var planContext = ""
        if let planMsg = messages.first(where: { $0.type == "plan_update" }),
           let pu = planMsg.planUpdate,
           let steps = pu.steps {
            let titles = steps.compactMap { $0.title }.prefix(4)
            if !titles.isEmpty {
                planContext = "\nPlan steps: " + titles.joined(separator: "; ")
            }
        }

        // Try AI-generated name first (works if OpenAI key is available)
        if !rawPrompt.isEmpty {
            if let aiName = await generateAITaskName(prompt: rawPrompt, planContext: planContext) {
                taskNameCache[taskId] = aiName
                return aiName
            }
        }

        // Smart heuristic fallback
        let finalName = deriveTaskName(from: rawPrompt, messages: messages)
        // Only cache for inactive tasks
        if !isActive {
            taskNameCache[taskId] = finalName
        }
        return finalName
    }

    /// Derive a readable task name from the prompt and messages without AI
    private func deriveTaskName(from rawPrompt: String, messages: [TaskMessage]) -> String {
        // Even if rawPrompt is empty, check plan steps and assistant messages first
        if rawPrompt.isEmpty {
            // Try plan step titles
            if let planMsg = messages.first(where: { $0.type == "plan_update" }),
               let pu = planMsg.planUpdate,
               let steps = pu.steps,
               let firstStep = steps.first?.title, !firstStep.isEmpty {
                let name = firstStep.count <= 60 ? firstStep : String(firstStep.prefix(60)) + "..."
                return name
            }
            // Try assistant message
            if let assistantMsg = messages.first(where: { $0.type == "assistant_message" }),
               let content = assistantMsg.assistantMessage?.content,
               !content.isEmpty, !content.hasPrefix("{") {
                let firstSentence = content.components(separatedBy: ".").first ?? content
                let cleaned = firstSentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty && cleaned.count > 5 {
                    let name = cleaned.count <= 60 ? cleaned : String(cleaned.prefix(60)) + "..."
                    return name
                }
            }
            // Try status brief
            if let statusMsg = messages.first(where: { $0.type == "status_update" }),
               let brief = statusMsg.statusUpdate?.brief, !brief.isEmpty,
               brief != "Manus is running" && brief != "Manus finished working" {
                let name = brief.count <= 60 ? brief : String(brief.prefix(60)) + "..."
                return name
            }
            return "Untitled Task"  // Will be overridden by enrichSingleTask if plan data exists
        }

        let lines = rawPrompt.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // If the prompt is short (< 100 chars), use the first line directly
        let firstLine = lines.first ?? rawPrompt
        if rawPrompt.count < 100 {
            let trimmed = firstLine.count > 60 ? String(firstLine.prefix(60)) + "..." : firstLine
            return trimmed
        }

        // For longer prompts, try multiple strategies in priority order:

        // 1. Plan step titles — most descriptive of what the task actually does
        if let planMsg = messages.first(where: { $0.type == "plan_update" }),
           let pu = planMsg.planUpdate,
           let steps = pu.steps,
           let firstStep = steps.first?.title, !firstStep.isEmpty {
            let name = firstStep.count <= 60 ? firstStep : String(firstStep.prefix(60)) + "..."
            return name
        }

        // 2. First assistant message — extract the action summary
        if let assistantMsg = messages.first(where: { $0.type == "assistant_message" }),
           let content = assistantMsg.assistantMessage?.content,
           !content.isEmpty,
           !content.hasPrefix("{"), // Skip JSON responses
           !content.hasPrefix("---") { // Skip YAML responses
            let firstSentence = content.components(separatedBy: ".").first ?? content
            let cleaned = firstSentence.trimmingCharacters(in: .whitespacesAndNewlines)
            let prefixes = ["I will ", "I'll ", "Let me ", "I'm going to ", "Sure, ", "Sure! ", "Of course, ", "Certainly, "]
            var actionText = cleaned
            for prefix in prefixes {
                if actionText.hasPrefix(prefix) {
                    actionText = String(actionText.dropFirst(prefix.count))
                    actionText = actionText.prefix(1).uppercased() + actionText.dropFirst()
                    break
                }
            }
            if !actionText.isEmpty && actionText.count > 5 {
                let name = actionText.count <= 60 ? actionText : String(actionText.prefix(60)) + "..."
                return name
            }
        }

        // 3. Markdown heading — only if it looks like a real title (>= 3 words)
        if let heading = lines.first(where: { $0.hasPrefix("# ") }) {
            let title = String(heading.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
            let wordCount = title.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
            if wordCount >= 3 {
                let name = title.count <= 60 ? title : String(title.prefix(60)) + "..."
                return name
            }
        }

        // 4. Extract meaningful name from "You are a/an X" pattern
        if firstLine.hasPrefix("You are ") {
            let afterYouAre = String(firstLine.dropFirst(8))
            // Extract the role: "an expert at creating Manus AI Skills" -> "Creating Manus AI Skills"
            let rolePatterns = ["an expert at ", "an expert in ", "a ", "an "]
            for pattern in rolePatterns {
                if afterYouAre.hasPrefix(pattern) {
                    var role = String(afterYouAre.dropFirst(pattern.count))
                    // Capitalize and clean up
                    role = role.prefix(1).uppercased() + role.dropFirst()
                    // Trim at first period or comma
                    if let dotIdx = role.firstIndex(of: ".") { role = String(role[..<dotIdx]) }
                    if let commaIdx = role.firstIndex(of: ",") { role = String(role[..<commaIdx]) }
                    if role.count > 5 {
                        let name = role.count <= 60 ? role : String(role.prefix(60)) + "..."
                        return name
                    }
                }
            }
        }

        // 5. Final fallback: use first line, trimmed
        let trimmed = firstLine.count > 60 ? String(firstLine.prefix(60)) + "..." : firstLine
        return trimmed
    }

    // MARK: - AI Task Name Generation

    private func generateAITaskName(prompt: String, planContext: String) async -> String? {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return nil }
        var openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        if openAIKey.isEmpty {
            openAIKey = UserDefaults.standard.string(forKey: "OpenAIAPIKey") ?? ""
        }
        guard !openAIKey.isEmpty else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 8

        let body: [String: Any] = [
            "model": "gpt-4.1-nano",
            "messages": [
                ["role": "system", "content": "Generate a concise 3-8 word task name that summarizes what this task is about. Reply with ONLY the name, no quotes, no punctuation at the end."],
                ["role": "user", "content": "User request: \(String(prompt.prefix(300)))\(planContext)"]
            ],
            "max_tokens": 25,
            "temperature": 0.3
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                return cleaned.isEmpty ? nil : cleaned
            }
        } catch { /* AI generation failed, will use fallback */ }
        return nil
    }

    // MARK: - Parse Activity Feed

    private func parseActivityFeed(messages: [TaskMessage]) -> [ActivityItem] {
        var items: [ActivityItem] = []
        for m in messages {
            let ts = m.timestampDate
            let mid = m.id ?? UUID().uuidString
            switch m.type {
            case "tool_used":
                let tu = m.toolUsed
                let toolName = tu?.tool ?? "unknown"
                let brief = tu?.brief ?? tu?.message?.action ?? ""
                items.append(ActivityItem(id: mid, timestamp: ts, type: .tool, title: toolDisplayName(toolName), detail: brief, status: tu?.status))
            case "explanation":
                let content = m.explanation?.content ?? ""
                items.append(ActivityItem(id: mid, timestamp: ts, type: .explanation, title: "Thinking", detail: String(content.prefix(120)), status: nil))
            case "status_update":
                let su = m.statusUpdate
                items.append(ActivityItem(id: mid, timestamp: ts, type: .status, title: su?.agentStatus?.capitalized ?? "Status", detail: su?.brief ?? su?.description ?? "", status: su?.agentStatus))
            case "assistant_message":
                let content = m.assistantMessage?.content ?? ""
                items.append(ActivityItem(id: mid, timestamp: ts, type: .message, title: "Response", detail: String(content.prefix(100)), status: nil))
            case "plan_update":
                let steps = m.planUpdate?.steps ?? []
                let doing = steps.filter { $0.status == "doing" }.count
                let done = steps.filter { $0.status == "done" }.count
                items.append(ActivityItem(id: mid, timestamp: ts, type: .plan, title: "Plan Updated", detail: "\(done)/\(steps.count) steps done, \(doing) in progress", status: nil))
            default: break
            }
        }
        return items.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Parse Deliverables

    private func parseDeliverables(messages: [TaskMessage]) -> [Deliverable] {
        var deliverables: [Deliverable] = []
        for m in messages {
            if m.type == "assistant_message", let atts = m.assistantMessage?.attachments {
                for att in atts {
                    guard let url = att.url, !url.isEmpty else { continue }
                    deliverables.append(Deliverable(
                        id: "\(m.id ?? "")-\(att.filename ?? UUID().uuidString)",
                        filename: att.filename ?? "Unknown",
                        contentType: att.contentType ?? "",
                        url: url,
                        type: att.type ?? "file"
                    ))
                }
            }
        }
        return deliverables
    }

    // MARK: - Parse Tool Stats

    private func parseToolStats(messages: [TaskMessage]) -> [ToolStat] {
        var counts: [String: (total: Int, success: Int)] = [:]
        for m in messages where m.type == "tool_used" {
            let tool = m.toolUsed?.tool ?? "unknown"
            let isSuccess = m.toolUsed?.status == "success"
            var current = counts[tool] ?? (0, 0)
            current.total += 1
            if isSuccess { current.success += 1 }
            counts[tool] = current
        }
        return counts.map { ToolStat(id: $0.key, tool: $0.key, count: $0.value.total, successCount: $0.value.success) }
            .sorted { $0.count > $1.count }
    }

    private func toolDisplayName(_ tool: String) -> String {
        switch tool {
        case "browser": return "Browser"
        case "terminal": return "Terminal"
        case "text_editor": return "Editor"
        case "search": return "Search"
        case "media_viewer": return "Media Viewer"
        case "suggestion": return "Suggestion"
        case "code_executor": return "Code Executor"
        default: return tool.capitalized
        }
    }

    // MARK: - Compute Account Stats

    func computeAccountStats(from tasks: [ManusTask]) -> AccountStats {
        var stats = AccountStats()
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now

        stats.totalTasksAllTime = tasks.count
        stats.runningNow = tasks.filter { $0.status == .running }.count
        stats.waitingNow = tasks.filter { $0.status == .waiting }.count

        var todayDurations: [TimeInterval] = []
        var totalCredits = 0
        var todayCredits = 0
        var tasksWithCredits = 0

        for task in tasks {
            if task.createdAt >= startOfToday {
                stats.totalTasksToday += 1
                if task.status == .stopped { stats.completedToday += 1 }
                if task.status == .error { stats.erroredToday += 1 }
                todayDurations.append(task.timeSpent)
                todayCredits += task.creditsUsed
            }
            if task.createdAt >= startOfWeek { stats.totalTasksThisWeek += 1 }
            totalCredits += task.creditsUsed
            if task.creditsUsed > 0 { tasksWithCredits += 1 }
        }
        if !todayDurations.isEmpty {
            stats.avgDurationToday = todayDurations.reduce(0, +) / Double(todayDurations.count)
            stats.longestTaskToday = todayDurations.max() ?? 0
        }
        stats.totalCreditsUsed = totalCredits
        stats.creditsUsedToday = todayCredits
        stats.avgCreditsPerTask = tasksWithCredits > 0 ? Double(totalCredits) / Double(tasksWithCredits) : 0
        stats.totalRefunds = self.totalRefunds
        stats.totalGrants = self.totalGrants
        return stats
    }

    // MARK: - Build Enriched Tasks

    func fetchEnrichedTasks() async throws -> [ManusTask] {
        // Use paginated fetch to find all active tasks across pages
        let allSummaries = try await listAllTasks(recentLimit: 100)

        // Fetch credit usage data (cached, refreshes every 30s)
        await fetchUsageCredits()

        // Separate active and inactive tasks
        let activeSummaries = allSummaries.filter { $0.status == "running" || $0.status == "waiting" || $0.status == "error" }
        // Sort inactive by updatedAt (most recently active first) to match web app sidebar
        let inactiveSummaries = allSummaries
            .filter { $0.status != "running" && $0.status != "waiting" && $0.status != "error" }
            .sorted { $0.updatedAtDate > $1.updatedAtDate }

        // Take all active + most recently updated 30 inactive for display
        let displaySummaries = activeSummaries + Array(inactiveSummaries.prefix(30))

        var tasks: [ManusTask] = []

        // Enrich active tasks in parallel with TaskGroup for speed
        await withTaskGroup(of: ManusTask?.self) { group in
            for summary in activeSummaries {
                group.addTask { [self] in
                    return await self.enrichSingleTask(summary: summary, fetchMessages: true)
                }
            }
            for await task in group {
                if let t = task { tasks.append(t) }
            }
        }

        // Enrich inactive tasks sorted by updatedAt (name only, no messages — fast)
        await withTaskGroup(of: ManusTask?.self) { group in
            for summary in Array(inactiveSummaries.prefix(30)) {
                group.addTask { [self] in
                    return await self.enrichSingleTask(summary: summary, fetchMessages: false)
                }
            }
            for await task in group {
                if let t = task { tasks.append(t) }
            }
        }

        // Sort: active/error first (running, waiting, error), then by updatedAt desc
        tasks.sort { a, b in
            let aActive = a.status.isActive || a.status == .error
            let bActive = b.status.isActive || b.status == .error
            if aActive && !bActive { return true }
            if !aActive && bActive { return false }
            return a.updatedAt > b.updatedAt
        }

        return tasks
    }

    /// Enrich a single task summary into a full ManusTask
    private func enrichSingleTask(summary: TaskSummary, fetchMessages: Bool) async -> ManusTask? {
        let isActive = summary.status == "running" || summary.status == "waiting"

        var taskName: String
        do { taskName = try await fetchTaskName(taskId: summary.id, isActive: isActive) }
        catch { taskName = isActive ? "Active Task" : "Task \(summary.id.prefix(8))" }

        var currentStep = ""
        var currentStepIndex = 0
        var totalSteps = 0
        var planSteps: [PlanStep] = []
        var statusBrief = ""
        var currentTool = ""
        var currentToolBrief = ""
        var waitingDescription = ""
        var waitingForEventId = ""
        var waitingForEventType = ""
        var activityFeed: [ActivityItem] = []
        var deliverables: [Deliverable] = []
        var toolStats: [ToolStat] = []
        var conversationCount = 0
        var lastExplanation = ""

        if fetchMessages && (isActive || summary.status == "error") {
            do {
                let messages = try await listMessages(taskId: summary.id, limit: 50, order: "desc", verbose: true)
                if let plan = messages.first(where: { $0.type == "plan_update" }) {
                    planSteps = plan.planUpdate?.steps ?? []
                    totalSteps = planSteps.count
                    let doneCount = planSteps.filter { $0.status == "done" }.count
                    if let doing = planSteps.first(where: { $0.status == "doing" }) {
                        currentStep = doing.title ?? ""
                        currentStepIndex = doneCount + 1
                    } else {
                        currentStepIndex = doneCount
                    }
                }
                if let status = messages.first(where: { $0.type == "status_update" }) {
                    statusBrief = status.statusUpdate?.brief ?? ""
                    waitingDescription = status.statusUpdate?.statusDetail?.waitingDescription ?? ""
                    waitingForEventId = status.statusUpdate?.waitingForEventId ?? ""
                    waitingForEventType = status.statusUpdate?.waitingForEventType ?? ""
                }
                if let tool = messages.first(where: { $0.type == "tool_used" }) {
                    currentTool = tool.toolUsed?.tool ?? ""
                    currentToolBrief = tool.toolUsed?.brief ?? ""
                }
                if let exp = messages.first(where: { $0.type == "explanation" }) {
                    lastExplanation = exp.explanation?.content ?? ""
                }
                activityFeed = parseActivityFeed(messages: messages)
                deliverables = parseDeliverables(messages: messages)
                toolStats = parseToolStats(messages: messages)
                conversationCount = messages.filter { $0.type == "user_message" || $0.type == "assistant_message" }.count

                // For active tasks: if fetchTaskName returned a placeholder, derive a better name
                let isPlaceholder = taskName == "Untitled Task" || taskName == "Active Task" || taskName.hasPrefix("Task ")
                if isPlaceholder {
                    // Priority 1: Short user prompt (< 80 chars) — use it directly as the title
                    if let userMsg = messages.last(where: { $0.type == "user_message" }),
                       let content = userMsg.userMessage?.content,
                       !content.isEmpty && content.count < 80 {
                        let firstLine = content.components(separatedBy: .newlines).first ?? content
                        let cleaned = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !cleaned.isEmpty {
                            taskName = cleaned.count <= 60 ? cleaned : String(cleaned.prefix(60)) + "..."
                        }
                    }
                    // Priority 2: Assistant's first response — typically summarizes the task
                    else if let assistantMsg = messages.last(where: { $0.type == "assistant_message" }),
                            let content = assistantMsg.assistantMessage?.content,
                            !content.isEmpty, !content.hasPrefix("{"), !content.hasPrefix("---") {
                        // Extract action from "I'll X" or "I will X" patterns
                        let firstSentence = content.components(separatedBy: ".").first ?? content
                        var cleaned = firstSentence.trimmingCharacters(in: .whitespacesAndNewlines)
                        let prefixes = ["Got it! I'll ", "Got it! I will ", "I'll ", "I will ", "Let me ", "I'm going to ", "Sure, I'll ", "Sure! I'll ", "Of course, I'll "]
                        for prefix in prefixes {
                            if cleaned.hasPrefix(prefix) {
                                cleaned = String(cleaned.dropFirst(prefix.count))
                                cleaned = cleaned.prefix(1).uppercased() + cleaned.dropFirst()
                                break
                            }
                        }
                        if !cleaned.isEmpty && cleaned.count > 5 {
                            taskName = cleaned.count <= 60 ? cleaned : String(cleaned.prefix(60)) + "..."
                        }
                    }
                    // Priority 3: Plan step titles as fallback
                    else if !planSteps.isEmpty {
                        let goalTitle = planSteps.first?.title ?? ""
                        if !goalTitle.isEmpty {
                            taskName = goalTitle.count <= 60 ? goalTitle : String(goalTitle.prefix(60)) + "..."
                        }
                    }
                }
            } catch { /* continue with partial data */ }
        }

        let createdAt = summary.createdAtDate
        let updatedAt = summary.updatedAtDate
        let timeSpent: TimeInterval = isActive
            ? Date().timeIntervalSince(createdAt)
            : updatedAt.timeIntervalSince(createdAt)

        // Compute tool call totals and top tools summary
        let totalToolCalls = toolStats.reduce(0) { $0 + $1.count }
        let topToolsList = toolStats.sorted { $0.count > $1.count }.prefix(3)
            .map { "\($0.displayName) \($0.count)" }
            .joined(separator: ", ")

        // Get credits from cache
        let credits = creditsForTask(summary.id)

        // Fetch website info for active tasks (non-blocking, returns nil if no website)
        var websiteInfo: WebsiteInfo? = nil
        if isActive {
            websiteInfo = await fetchWebsiteInfo(taskId: summary.id)
        }

        return ManusTask(
            id: summary.id,
            status: ManusTask.TaskStatus(from: summary.status),
            createdAt: createdAt, updatedAt: updatedAt,
            taskType: summary.taskType ?? "standard",
            taskName: taskName, currentStep: currentStep,
            currentStepIndex: currentStepIndex, totalSteps: totalSteps,
            planSteps: planSteps, statusBrief: statusBrief,
            currentTool: currentTool, currentToolBrief: currentToolBrief,
            timeSpent: timeSpent, waitingDescription: waitingDescription,
            waitingForEventId: waitingForEventId, waitingForEventType: waitingForEventType,
            activityFeed: activityFeed, deliverables: deliverables,
            toolStats: toolStats, conversationCount: conversationCount,
            lastExplanation: lastExplanation,
            projectId: summary.projectId,
            creditsUsed: credits,
            totalToolCalls: totalToolCalls,
            topTools: topToolsList,
            websiteInfo: websiteInfo
        )
    }

    // MARK: - Fetch Detail for Drill-Down

    func fetchTaskDetail(taskId: String) async throws -> (activityFeed: [ActivityItem], deliverables: [Deliverable], toolStats: [ToolStat], planSteps: [PlanStep], conversationCount: Int, lastExplanation: String) {
        let messages = try await listMessages(taskId: taskId, limit: 50, order: "desc", verbose: true)
        let activityFeed = parseActivityFeed(messages: messages)
        let deliverables = parseDeliverables(messages: messages)
        let toolStats = parseToolStats(messages: messages)
        let conversationCount = messages.filter { $0.type == "user_message" || $0.type == "assistant_message" }.count
        let lastExplanation = messages.first(where: { $0.type == "explanation" })?.explanation?.content ?? ""
        var planSteps: [PlanStep] = []
        if let plan = messages.first(where: { $0.type == "plan_update" }) {
            planSteps = plan.planUpdate?.steps ?? []
        }
        return (activityFeed, deliverables, toolStats, planSteps, conversationCount, lastExplanation)
    }
}

enum ManusAPIError: Error, LocalizedError {
    case requestFailed(statusCode: Int)
    case apiError(String)
    case invalidAPIKey
    var errorDescription: String? {
        switch self {
        case .requestFailed(let code): return "Request failed (HTTP \(code))"
        case .apiError(let msg): return msg
        case .invalidAPIKey: return "Invalid API key"
        }
    }
}

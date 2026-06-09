import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: TaskStore
    @State private var selectedTab: SettingsTab = .general
    @State private var showAPIKey = false
    @State private var testResult: String? = nil
    @State private var isTesting = false

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case connectors = "Connectors"
        case skills = "Skills"
        case webhooks = "Webhooks"
        case streak = "Streak"
        case about = "About"

        var icon: String {
            switch self {
            case .general: return "gearshape.fill"
            case .connectors: return "puzzlepiece.extension.fill"
            case .skills: return "star.fill"
            case .webhooks: return "antenna.radiowaves.left.and.right"
            case .streak: return "flame.fill"
            case .about: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                manusLogoImage(size: 18)
                Text("Manus Island Settings")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text("v1.0")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Tab bar
            HStack(spacing: 4) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12))
                            Text(tab.rawValue)
                                .font(.system(size: 9, weight: .medium))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .general:
                        generalTab
                    case .connectors:
                        connectorsTab
                    case .skills:
                        skillsTab
                    case .webhooks:
                        webhooksTab
                    case .streak:
                        streakTab
                    case .about:
                        aboutTab
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 380, height: 520)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsSection("API Configuration") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        if showAPIKey {
                            TextField("Enter API key", text: $store.apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                        } else {
                            SecureField("Enter API key", text: $store.apiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                        }

                        Button(action: { showAPIKey.toggle() }) {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.borderless)

                        Button(action: testConnection) {
                            if isTesting {
                                ProgressView().scaleEffect(0.5)
                            } else {
                                Text("Test")
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(store.apiKey.isEmpty || isTesting)
                    }

                    if let result = testResult {
                        HStack(spacing: 4) {
                            Image(systemName: result.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.contains("Success") ? .green : .red)
                                .font(.system(size: 10))
                            Text(result)
                                .font(.system(size: 10))
                                .foregroundColor(result.contains("Success") ? .green : .red)
                        }
                    }

                    HStack(spacing: 4) {
                        Circle()
                            .fill(store.isConnected ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(store.isConnected ? "Connected" : "Disconnected")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }

            settingsSection("Behavior") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Polling Interval")
                            .font(.system(size: 11))
                        Spacer()
                        Picker("", selection: $store.pollingInterval) {
                            Text("3s (Fast)").tag(3.0)
                            Text("5s (Normal)").tag(5.0)
                            Text("10s (Slow)").tag(10.0)
                            Text("30s (Battery Saver)").tag(30.0)
                        }
                        .frame(width: 160)
                    }

                    Toggle("Show Island Overlay", isOn: $store.showIsland)
                        .font(.system(size: 11))


                    Toggle("Focus Mode (hide when idle)", isOn: $store.focusMode)
                        .font(.system(size: 11))

                    Toggle("Launch at Login", isOn: $store.launchAtLogin)
                        .font(.system(size: 11))
                }
            }

            settingsSection("Voice Input (OpenAI Whisper)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("An OpenAI API key is required for voice-to-text transcription.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    TextField("OpenAI API Key (sk-...)", text: Binding(
                        get: { UserDefaults.standard.string(forKey: "OpenAIAPIKey") ?? "" },
                        set: { UserDefaults.standard.set($0, forKey: "OpenAIAPIKey") }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                }
            }

            settingsSection("Spotlight") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Manus Island indexes completed tasks in Spotlight so you can search them from anywhere.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Button(action: {
                        store.indexAllTasksInSpotlight()
                    }) {
                        Label("Re-index All Tasks", systemImage: "magnifyingglass")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Connectors Tab

    private var connectorsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsSection("Active Connectors") {
                if store.connectors.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No connectors found")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("Connectors are configured in your Manus account settings.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.7))
                            .multilineTextAlignment(.center)

                        Button(action: {
                            Task { await store.fetchConnectors() }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    VStack(spacing: 6) {
                        ForEach(store.connectors) { connector in
                            connectorRow(connector)
                        }
                    }

                    HStack {
                        Text("\(store.connectors.count) connector\(store.connectors.count == 1 ? "" : "s") active")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            Task { await store.fetchConnectors() }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }

    private func connectorRow(_ connector: ConnectorInfo) -> some View {
        HStack(spacing: 10) {
            Image(systemName: connector.icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(connector.name)
                    .font(.system(size: 12, weight: .semibold))
                if let desc = connector.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(connector.typeLabel)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)

            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    // MARK: - Skills Tab

    private var skillsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsSection("Available Skills") {
                VStack(alignment: .leading, spacing: 8) {
                    if store.skills.isEmpty {
                        HStack {
                            Image(systemName: "star.slash")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text("No skills found")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 12)
                    } else {
                        Text("\(store.skills.count) skills available")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        ForEach(store.skills, id: \.id) { skill in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(skill.name)
                                        .font(.system(size: 12, weight: .semibold))
                                    if let desc = skill.description, !desc.isEmpty {
                                        Text(desc)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    HStack(spacing: 8) {
                                        Text("ID: \(skill.id)")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.secondary.opacity(0.6))
                                        if let owner = skill.ownerType {
                                            Text(owner)
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(.orange.opacity(0.7))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.orange.opacity(0.1))
                                                .cornerRadius(3)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color.secondary.opacity(0.03))
                            .cornerRadius(6)
                        }
                    }

                    Button(action: {
                        Task { await store.fetchSkills() }
                    }) {
                        Label("Refresh Skills", systemImage: "arrow.clockwise")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Webhooks Tab

    private var webhooksTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsSection("Webhook Configuration") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Enable Webhooks", isOn: $store.webhookEnabled)
                        .font(.system(size: 11))

                    if store.webhookEnabled {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Webhook URL")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                TextField("https://your-server.com/webhook", text: $store.webhookURL)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 11, design: .monospaced))

                                Button(action: {
                                    Task { await store.registerWebhook() }
                                }) {
                                    Text("Register")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .buttonStyle(.bordered)
                                .disabled(store.webhookURL.isEmpty)
                            }

                            if let webhookId = store.webhookId {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 10))
                                    Text("Registered: \(webhookId)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }

                    Text("Webhooks provide real-time push notifications when task status changes. Events: task.completed, task.waiting, task.error, task.started")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            settingsSection("Local Webhook Server") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("A lightweight local HTTP server can receive webhook events directly on this machine.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        Button(action: {
                            store.startWebhookServer()
                        }) {
                            Label("Start Server", systemImage: "play.fill")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            store.stopWebhookServer()
                        }) {
                            Label("Stop Server", systemImage: "stop.fill")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                    }

                    if let lastEvent = store.lastWebhookEvent {
                        HStack(spacing: 4) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.green)
                                .font(.system(size: 10))
                            Text("Last event: \(TaskStore.formatTimeAgo(lastEvent))")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Streak Tab

    private var streakTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsSection("Daily Streak") {
                VStack(spacing: 12) {
                    // Big streak display
                    HStack(spacing: 12) {
                        manusLogoImage(size: 48)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(store.streakCount)")
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                            Text("tasks completed today")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)

                    Divider()

                    // Weekly view
                    Text("LAST 7 DAYS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(weekDays(), id: \.key) { day in
                            VStack(spacing: 4) {
                                Text("\(day.count)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(day.count > 0 ? .orange : .secondary.opacity(0.5))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(day.count > 0 ? Color.orange.opacity(Double(min(day.count, 10)) / 10.0) : Color.secondary.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Group {
                                            if day.count >= 5 {
                                                manusLogoImage(size: 18)
                                            }
                                        }
                                    )
                                Text(day.label)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            settingsSection("Streak Levels") {
                VStack(alignment: .leading, spacing: 6) {
                    streakLevelRowWithLogo(range: "1-2 tasks", label: "Getting Started", opacity: 0.3)
                    streakLevelRowWithLogo(range: "3-4 tasks", label: "On Fire", opacity: 0.5)
                    streakLevelRowWithLogo(range: "5-9 tasks", label: "Snap Master", opacity: 0.75)
                    streakLevelRowWithLogo(range: "10+ tasks", label: "Legendary", opacity: 1.0)
                }
            }
        }
    }

    private func streakLevelRowWithLogo(range: String, label: String, opacity: Double) -> some View {
        HStack(spacing: 10) {
            manusLogoImage(size: 22)
                .opacity(opacity)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                Text(range)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private struct WeekDay: Identifiable {
        let key: String
        let label: String
        let count: Int
        var id: String { key }
    }

    private func weekDays() -> [WeekDay] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        var days: [WeekDay] = []
        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let key = formatter.string(from: date)
            let label = dayFormatter.string(from: date)
            let count = store.weeklyStreak[key] ?? 0
            days.append(WeekDay(key: key, label: label, count: count))
        }
        return days
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsSection("Manus Island") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        manusLogoImage(size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Manus Island")
                                .font(.system(size: 16, weight: .bold))
                            Text("Version 6.0 - The Gamified Edition")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        featureRow(icon: "flame.fill", text: "Gamified Streak Counter", color: .orange)
                        featureRow(icon: "antenna.radiowaves.left.and.right", text: "Webhook Real-time Updates", color: .blue)
                        featureRow(icon: "folder.fill", text: "Project Grouping", color: .purple)
                        featureRow(icon: "puzzlepiece.extension.fill", text: "Connector Status", color: .cyan)
                        featureRow(icon: "arrow.down.doc.fill", text: "Drag & Drop Files", color: .green)
                        featureRow(icon: "magnifyingglass", text: "Spotlight Integration", color: .yellow)
                    }
                }
            }

            settingsSection("Keyboard Shortcuts") {
                VStack(alignment: .leading, spacing: 6) {
                    shortcutRow(keys: "Click Island", action: "Expand/Collapse")
                    shortcutRow(keys: "Drop Files", action: "Create task with files")
                    shortcutRow(keys: "Spotlight Search", action: "Find completed tasks")
                }
            }
        }
    }

    private func featureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 11))
        }
        .padding(.vertical, 1)
    }

    private func shortcutRow(keys: String, action: String) -> some View {
        HStack {
            Text(keys)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
            Spacer()
            Text(action)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
            content()
                .padding(12)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        Task {
            do {
                let client = ManusAPIClient(apiKey: store.apiKey)
                let tasks = try await client.listTasks(limit: 1)
                await MainActor.run {
                    testResult = "Success! Found \(tasks.count) task(s)"
                    isTesting = false
                    store.restartPolling()
                }
            } catch {
                await MainActor.run {
                    testResult = "Error: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}


// MARK: - Menu Bar Popover View

struct MenuBarPopoverView: View {
    @ObservedObject var store: TaskStore
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            if showSettings {
                SettingsView(store: store)
            } else {
                // Quick overview
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        manusLogoImage(size: 18)
                        Text("Manus Island")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()

                        // Streak badge
                        if store.streakCount > 0 {
                            HStack(spacing: 3) {
                                manusLogoImage(size: 14)
                                Text("\(store.streakCount)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }

                        HStack(spacing: 4) {
                            Circle()
                                .fill(store.isConnected ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            Text(store.isConnected ? "Connected" : "Offline")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                    Divider()

                    // Stats row
                    HStack(spacing: 0) {
                        menuStatCell(value: "\(store.accountStats.runningNow)", label: "Running", color: .green)
                        Spacer()
                        menuStatCell(value: "\(store.accountStats.waitingNow)", label: "Waiting", color: .orange)
                        Spacer()
                        menuStatCell(value: "\(store.accountStats.completedToday)", label: "Today", color: .blue)
                        Spacer()
                        menuStatCell(value: "\(store.accountStats.totalTasksAllTime)", label: "All Time", color: .purple)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider()

                    // Active tasks
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            if !store.activeTasks.isEmpty {
                                Text("ACTIVE TASKS")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)
                                    .padding(.bottom, 4)

                                ForEach(store.activeTasks) { task in
                                    menuTaskRow(task)
                                }
                            }

                            if !store.recentTasks.isEmpty {
                                Text("RECENT")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)
                                    .padding(.bottom, 4)

                                ForEach(store.recentTasks.prefix(5)) { task in
                                    menuTaskRow(task)
                                }
                            }

                            if store.activeTasks.isEmpty && store.recentTasks.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary.opacity(0.5))
                                    Text("No tasks")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            }
                        }
                    }
                    .frame(maxHeight: 300)

                    Divider()

                    // Connector status strip
                    if !store.connectors.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(store.connectors) { connector in
                                    HStack(spacing: 3) {
                                        Image(systemName: connector.icon)
                                            .font(.system(size: 7))
                                        Text(connector.name)
                                            .font(.system(size: 8, weight: .medium))
                                    }
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.08))
                                    .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }
                        Divider()
                    }

                    // Bottom bar
                    HStack {
                        Button(action: {
                            if let url = URL(string: "https://manus.im") {
                                openURLInChrome(url)
                            }
                        }) {
                            Label("Open Manus", systemImage: "safari")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.borderless)

                        Spacer()

                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.borderless)

                        Button(action: {
                            NSApplication.shared.terminate(nil)
                        }) {
                            Image(systemName: "power")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
        .frame(width: 380, height: showSettings ? 540 : 460)
    }

    private func menuStatCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private func menuTaskRow(_ task: ManusTask) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(task.status == .running ? Color.green : (task.status == .waiting ? Color.orange : Color.gray))
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.taskName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                if task.status.isActive {
                    Text(task.activityDescription)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if task.totalSteps > 0 {
                Text(task.stepLabel)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Text(TaskStore.formatDuration(task.timeSpent))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)

            Button(action: { task.openInBrowser() }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture { task.openInBrowser() }
    }
}

// MARK: - Manus Logo Helper (global)

/// Loads the Manus snapping finger logo from the app bundle Resources.
/// Uses the dark version for light appearances and white version for dark appearances.
func manusLogoImage(size: CGFloat) -> some View {
    Group {
        if let path = Bundle.main.path(forResource: "manus_logo_128", ofType: "png"),
           let nsImage = NSImage(contentsOfFile: path) {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            // Fallback to system icon
            Image(systemName: "hand.point.up.left.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(.orange)
        }
    }
}

/// White version of the Manus logo for dark backgrounds (island pill, etc.)
func manusLogoWhite(size: CGFloat) -> some View {
    Group {
        if let path = Bundle.main.path(forResource: "manus_logo_white_128", ofType: "png"),
           let nsImage = NSImage(contentsOfFile: path) {
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "hand.point.up.left.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(.white)
        }
    }
}

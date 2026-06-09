import SwiftUI
import UniformTypeIdentifiers

// MARK: - Manus Brand Design Tokens

private enum Glass {
    // High-contrast design: pure white text on dark, strong hierarchy
    static let warmWhite = Color.white

    // Backgrounds
    static let cardBg = Color.white.opacity(0.07)
    static let cardBgHover = Color.white.opacity(0.12)
    static let sectionBg = Color.white.opacity(0.04)
    static let inputBg = Color.white.opacity(0.09)

    // Borders
    static let borderLight = Color.white.opacity(0.18)
    static let borderSubtle = Color.white.opacity(0.10)
    static let borderGlow = Color.white.opacity(0.30)

    // Text - strong contrast hierarchy
    static let textPrimary = Color.white                          // Full white - titles, values
    static let textSecondary = Color.white.opacity(0.70)          // Clear grey - labels, body
    static let textTertiary = Color.white.opacity(0.45)           // Muted - timestamps, hints
    static let textMuted = Color.white.opacity(0.25)              // Very dim - disabled

    // Accents - clean minimal palette, green as brand accent
    static let accentBrand = Color(red: 0.3, green: 0.9, blue: 0.6)   // Manus green
    static let accentBlue = Color(red: 0.4, green: 0.7, blue: 1.0)
    static let accentCyan = Color(red: 0.3, green: 0.85, blue: 0.9)
    static let accentGreen = Color(red: 0.3, green: 0.9, blue: 0.6)   // = accentBrand
    static let accentOrange = Color(red: 1.0, green: 0.7, blue: 0.3)
    static let accentYellow = Color(red: 1.0, green: 0.85, blue: 0.3)
    static let accentPurple = Color(red: 0.7, green: 0.5, blue: 1.0)
    static let accentRed = Color(red: 1.0, green: 0.4, blue: 0.4)

    // Radii
    static let radiusOuter: CGFloat = 26
    static let radiusInner: CGFloat = 14
    static let radiusCard: CGFloat = 12
    static let radiusPill: CGFloat = 20

    // Spacing
    static let padOuter: CGFloat = 16
    static let padInner: CGFloat = 12
    static let padSection: CGFloat = 8
}

// MARK: - Main Island View

struct IslandView: View {
    @ObservedObject var store: TaskStore
    @State private var pulseAnimation = false
    @State private var shimmerOffset: CGFloat = -200
    @State private var wavePhase: CGFloat = 0
    @State private var showQuickMessage = false

    var body: some View {
        Group {
            if !store.isConnected && store.apiKey.isEmpty {
                setupView
            } else if store.selectedTaskId != nil {
                taskDetailView
            } else if store.isExpanded {
                expandedView
            } else {
                compactView
            }
        }
        .onTapGesture {
            if store.selectedTaskId != nil { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                store.isExpanded.toggle()
            }
        }
        .overlay(
            Group {
                if store.isDragOver {
                    RoundedRectangle(cornerRadius: Glass.radiusOuter, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Glass.accentCyan, Glass.accentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: Glass.radiusOuter, style: .continuous)
                                .fill(Glass.accentCyan.opacity(0.08))
                        )
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(colors: [Glass.accentCyan, Glass.accentBlue], startPoint: .top, endPoint: .bottom)
                                    )
                                Text("Drop files here")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Glass.accentCyan)
                            }
                        )
                        .transition(.opacity)
                }
            }
        )
        .overlay(
            Group {
                if store.showDropPrompt {
                    dropPromptOverlay
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
        )
        .onDrop(of: [UTType.fileURL], isTargeted: Binding(
            get: { store.isDragOver },
            set: { store.isDragOver = $0 }
        )) { providers in
            handleDrop(providers: providers)
            return true
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
    }

    // MARK: - Drop Prompt Overlay

    private var dropPromptOverlay: some View {
        VStack(spacing: 10) {
            dropPromptHeader
            dropPromptFileList
            dropPromptInputRow
        }
        .padding(Glass.padInner)
        .background(glassBackground(cornerRadius: Glass.radiusInner))
        .overlay(
            RoundedRectangle(cornerRadius: Glass.radiusInner, style: .continuous)
                .strokeBorder(Glass.accentCyan.opacity(0.2), lineWidth: 0.5)
        )
        .padding(6)
    }

    private var dropPromptHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.on.doc.fill")
                .font(.system(size: 12))
                .foregroundColor(Glass.accentCyan)
            Text("\(store.droppedFileNames.count) file\(store.droppedFileNames.count == 1 ? "" : "s")")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Glass.textPrimary)
            Spacer()
            Button(action: { store.cancelDropPrompt() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Glass.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private var dropPromptFileList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(store.droppedFileNames.enumerated()), id: \.offset) { index, name in
                    dropPromptFilePill(name: name, index: index)
                }
            }
        }
    }

    private func dropPromptFilePill(name: String, index: Int) -> some View {
        HStack(spacing: 3) {
            Text(name)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Glass.accentCyan.opacity(0.8))
            Button(action: { store.removeDroppedFile(at: index) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Glass.accentCyan.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(glassCard(opacity: 0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Glass.accentCyan.opacity(0.15), lineWidth: 0.5)
        )
        .cornerRadius(6)
    }

    private var dropPromptInputRow: some View {
        HStack(spacing: 6) {
            TextField("What should Manus do with these files?", text: $store.dropPromptText)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(Glass.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Glass.inputBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Glass.borderSubtle, lineWidth: 0.5)
                )
                .cornerRadius(8)
                .onSubmit {
                    Task { await store.submitDropPrompt() }
                }

            Button(action: { Task { await store.submitDropPrompt() } }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(colors: [Glass.accentBrand, Glass.accentBrand.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Drop Handler

    private func handleDrop(providers: [NSItemProvider]) {
        var urls: [URL] = []
        let group = DispatchGroup()
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            if !urls.isEmpty {
                store.handleDroppedFiles(urls)
            }
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        HStack(spacing: 10) {
            manusLogoWhite(size: 14)
            Text("Manus Island")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Glass.textPrimary)
            Rectangle()
                .fill(Glass.borderSubtle)
                .frame(width: 1, height: 12)
            Text("Set API key in menu bar")
                .font(.system(size: 11))
                .foregroundColor(Glass.textSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(islandBackground)
        .clipShape(RoundedRectangle(cornerRadius: Glass.radiusOuter, style: .continuous))
    }

    // MARK: - Compact View (the pill)

    private var compactView: some View {
        HStack(spacing: 10) {
            // Animated status indicator with glow
            ZStack {
                if let task = store.primaryTask, task.status == .running {
                    Circle()
                        .fill(statusColor(task.status).opacity(0.15))
                        .frame(width: 20, height: 20)
                        .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.6)
                    Circle()
                        .fill(statusColor(task.status).opacity(0.08))
                        .frame(width: 16, height: 16)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.8)
                }
                statusDot
            }
            .frame(width: 20, height: 20)

            if let task = store.primaryTask {
                // Task name with shimmer
                ZStack {
                    Text(task.taskName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Glass.textPrimary)
                        .lineLimit(1)

                    if task.status == .running {
                        Text(task.taskName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.clear)
                            .lineLimit(1)
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.25), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 80)
                                .offset(x: shimmerOffset)
                                .mask(
                                    Text(task.taskName)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                )
                            )
                            .clipped()
                    }
                }
                .frame(maxWidth: 180, alignment: .leading)

                Spacer(minLength: 4)

                // Step progress ring
                if task.totalSteps > 0 {
                    HStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .stroke(Glass.borderSubtle, lineWidth: 2)
                                .frame(width: 16, height: 16)
                            Circle()
                                .trim(from: 0, to: task.progress)
                                .stroke(
                                    LinearGradient(colors: [statusColor(task.status), statusColor(task.status).opacity(0.5)], startPoint: .top, endPoint: .bottom),
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                )
                                .frame(width: 16, height: 16)
                                .rotationEffect(.degrees(-90))
                        }
                        Text(task.stepLabel)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Glass.textSecondary)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Glass.cardBg)
                    .overlay(
                        Capsule().strokeBorder(Glass.borderSubtle, lineWidth: 0.5)
                    )
                    .clipShape(Capsule())
                }

                // Parallel tasks
                if store.activeCount > 1 {
                    HStack(spacing: 2) {
                        Image(systemName: "square.stack.fill")
                            .font(.system(size: 8))
                        Text("\(store.activeCount)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Glass.accentCyan)
                }

                // Credits
                if task.creditsUsed > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 7))
                            .foregroundColor(Glass.accentBrand.opacity(0.7))
                        Text("\(task.creditsUsed)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Glass.warmWhite)
                            .contentTransition(.numericText())
                    }
                }

                Text(TaskStore.formatDuration(task.timeSpent))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Glass.textTertiary)
                    .contentTransition(.numericText())

            } else if store.isConnected {
                HStack(spacing: 6) {
                    Text("Idle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Glass.textTertiary)
                    Spacer()
                    if store.streakCount > 0 {
                        HStack(spacing: 3) {
                            manusLogoWhite(size: 12)
                            Text(store.streakDisplay)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Glass.textSecondary)
                        }
                    } else if store.accountStats.creditsUsedToday > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 8))
                                .foregroundColor(Glass.accentBrand.opacity(0.5))
                            Text("\(store.accountStats.creditsUsedToday) credits today")
                                .font(.system(size: 10))
                                .foregroundColor(Glass.textTertiary)
                        }
                    } else if store.accountStats.completedToday > 0 {
                        Text("\(store.accountStats.completedToday) done today")
                            .font(.system(size: 10))
                            .foregroundColor(Glass.textMuted)
                    }
                }
            } else {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 12, height: 12)
                    Text("Connecting...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Glass.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(islandBackground)
        .clipShape(RoundedRectangle(cornerRadius: Glass.radiusOuter, style: .continuous))
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                manusLogoWhite(size: 14)
                Text("Manus Island")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Glass.textPrimary)
                Spacer()

                // Streak badge
                if store.streakCount > 0 {
                    HStack(spacing: 3) {
                        manusLogoWhite(size: 11)
                        Text("\(store.streakCount)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Glass.warmWhite)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Glass.accentBrand.opacity(0.1))
                    .overlay(
                        Capsule().strokeBorder(Glass.accentBrand.opacity(0.2), lineWidth: 0.5)
                    )
                    .clipShape(Capsule())
                }

                if store.isConnected {
                    HStack(spacing: 4) {
                        Circle().fill(Glass.accentGreen).frame(width: 5, height: 5)
                            .shadow(color: Glass.accentGreen.opacity(0.5), radius: 3)
                        Text("Connected")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Glass.accentGreen.opacity(0.8))
                    }
                }

                // Close button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        store.isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Glass.textTertiary)
                        .frame(width: 20, height: 20)
                        .background(Glass.cardBg)
                        .overlay(
                            Circle().strokeBorder(Glass.borderSubtle, lineWidth: 0.5)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding(.horizontal, Glass.padOuter)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Account Stats Bar
            accountStatsBar
                .padding(.horizontal, Glass.padInner)
                .padding(.bottom, 6)

            // Activity Heatmap (always visible, not scrollable)
            activityHeatmapSection
                .padding(.bottom, 4)

            glassDivider

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Quick Create
                    quickCreateBar
                        .padding(.horizontal, Glass.padInner)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    // Tab toggle
                    if !store.projects.isEmpty {
                        tabToggle
                            .padding(.horizontal, Glass.padInner)
                            .padding(.vertical, 4)
                    }

                    if store.showProjectView && !store.projectGroups.isEmpty {
                        projectGroupView
                    } else {
                        standardTaskListView
                    }

                    if !store.connectors.isEmpty || !store.skills.isEmpty {
                        connectorsAndSkillsSection
                    }

                    creditsSummarySection

                    if !store.aggregatedToolStats.isEmpty {
                        aggregatedToolStatsSection
                    }

                    if !store.scheduledTasks.isEmpty {
                        scheduledTasksSection
                    }
                }
            }
            .frame(maxHeight: 420)

            glassDivider
            footerBar
        }
        .frame(width: 390)
        .background(islandBackground)
        .clipShape(RoundedRectangle(cornerRadius: Glass.radiusOuter, style: .continuous))
        .transition(.asymmetric(
            insertion: .scale(scale: 0.6, anchor: .top).combined(with: .opacity),
            removal: .scale(scale: 0.8, anchor: .top).combined(with: .opacity)
        ))
    }

    // MARK: - Tab Toggle (Tasks / Projects)

    private var tabToggle: some View {
        HStack(spacing: 6) {
            tabButton("Tasks", icon: nil, isActive: !store.showProjectView) {
                withAnimation(.spring(response: 0.3)) { store.showProjectView = false }
            }
            tabButton("Projects", icon: "folder.fill", isActive: store.showProjectView) {
                withAnimation(.spring(response: 0.3)) { store.showProjectView = true }
            }

            Spacer()

            if !store.connectors.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "puzzlepiece.extension.fill")
                        .font(.system(size: 8))
                    Text("\(store.connectors.count)")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(Glass.accentPurple.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Glass.accentPurple.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8).strokeBorder(Glass.accentPurple.opacity(0.12), lineWidth: 0.5)
                )
                .cornerRadius(8)
            }
        }
    }

    private func tabButton(_ title: String, icon: String?, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 8))
                }
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(isActive ? Glass.textPrimary : Glass.textTertiary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isActive ? Glass.cardBgHover : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isActive ? Glass.borderLight : Color.clear, lineWidth: 0.5)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Standard Task List View

    private var standardTaskListView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !store.activeTasks.isEmpty {
                sectionHeader("ACTIVE", color: Glass.accentGreen)
                ForEach(store.activeTasks) { task in
                    activeTaskCard(task)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                store.selectTask(task.id)
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }

            if !store.recentTasks.isEmpty {
                sectionHeader("RECENT", color: Glass.textTertiary)
                ForEach(store.recentTasks.prefix(10)) { task in
                    recentTaskRow(task)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                store.selectTask(task.id)
                            }
                        }
                }
            }

            if store.activeTasks.isEmpty && store.recentTasks.isEmpty {
                emptyState
            }
        }
    }

    // MARK: - Project Group View

    private var projectGroupView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(store.projectGroups) { group in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Glass.accentPurple.opacity(0.8))
                        Text(group.name)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Glass.textSecondary)
                        Spacer()
                        HStack(spacing: 6) {
                            if group.activeTasks > 0 {
                                HStack(spacing: 2) {
                                    Circle().fill(Glass.accentGreen).frame(width: 5, height: 5)
                                    Text("\(group.activeTasks)")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(Glass.accentGreen.opacity(0.8))
                                }
                            }
                            Text("\(group.tasks.count) tasks")
                                .font(.system(size: 9))
                                .foregroundColor(Glass.textTertiary)
                        }
                    }
                    .padding(.horizontal, Glass.padOuter)
                    .padding(.vertical, 7)
                    .background(Glass.sectionBg)

                    ForEach(group.tasks.prefix(5)) { task in
                        HStack(spacing: 8) {
                            Circle().fill(statusColor(task.status)).frame(width: 6, height: 6)
                            Text(task.taskName)
                                .font(.system(size: 10))
                                .foregroundColor(Glass.textSecondary)
                                .lineLimit(1)
                            Spacer()
                            if task.status.isActive {
                                Text(task.stepLabel)
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(Glass.textTertiary)
                            }
                            Text(TaskStore.formatTimeAgo(task.updatedAt))
                                .font(.system(size: 8))
                                .foregroundColor(Glass.textMuted)
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 3)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                store.selectTask(task.id)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Active Task Card (Glass Card)

    private func activeTaskCard(_ task: ManusTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title row
            HStack(spacing: 8) {
                ZStack {
                    if task.status == .running {
                        Circle()
                            .fill(statusColor(task.status).opacity(0.15))
                            .frame(width: 16, height: 16)
                            .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                    }
                    Circle()
                        .fill(statusColor(task.status))
                        .frame(width: 7, height: 7)
                        .shadow(color: statusColor(task.status).opacity(0.4), radius: 4)
                }
                .frame(width: 16, height: 16)

                Text(task.taskName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Glass.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(TaskStore.formatDuration(task.timeSpent))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Glass.textTertiary)
                    .contentTransition(.numericText())

                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Glass.textMuted)
            }

            // Current activity
            HStack(spacing: 6) {
                if !task.currentTool.isEmpty {
                    Image(systemName: task.toolIcon)
                        .font(.system(size: 9))
                        .foregroundColor(Glass.accentCyan.opacity(0.8))
                }
                Text(task.activityDescription)
                    .font(.system(size: 10))
                    .foregroundColor(Glass.textTertiary)
                    .lineLimit(1)
            }
            .padding(.leading, 24)

            // Credits & Tool summary pills
            HStack(spacing: 8) {
                if task.creditsUsed > 0 {
                    glassPill(icon: "sparkles", value: "\(task.creditsUsed)", color: Glass.warmWhite)
                }
                if task.totalToolCalls > 0 {
                    glassPill(icon: "wrench.and.screwdriver.fill", value: "\(task.totalToolCalls)", color: Glass.accentCyan)
                }
                if !task.topTools.isEmpty {
                    Text(task.topTools)
                        .font(.system(size: 8))
                        .foregroundColor(Glass.textMuted)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.leading, 24)

            // Website status
            if let website = task.websiteInfo {
                websiteStatusRow(website)
                    .padding(.leading, 24)
            }

            // Progress bar
            if task.totalSteps > 0 {
                HStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Glass.borderSubtle).frame(height: 3)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [statusColor(task.status), statusColor(task.status).opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * task.progress, height: 3)
                                .animation(.spring(response: 0.6), value: task.progress)
                                .shadow(color: statusColor(task.status).opacity(0.3), radius: 4, y: 1)

                            if task.status == .running {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.clear, .white.opacity(0.25), .clear],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 40, height: 3)
                                    .offset(x: shimmerOffset * (geo.size.width / 400))
                                    .mask(
                                        Capsule()
                                            .frame(width: geo.size.width * task.progress, height: 3)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    )
                            }
                        }
                    }
                    .frame(height: 3)

                    Text("Step \(task.currentStepIndex)/\(task.totalSteps)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(Glass.textTertiary)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.leading, 24)
            }

            // Quick action buttons
            HStack(spacing: 8) {
                if task.status == .waiting {
                    Button(action: { Task { await store.confirmTaskAction(task.id) } }) {
                        Label("Confirm", systemImage: "checkmark.circle")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .buttonStyle(GlassButtonStyle(color: Glass.accentGreen))
                }

                Button(action: { Task { await store.stopTask(task.id) } }) {
                    Label("Stop", systemImage: "stop.circle")
                        .font(.system(size: 9, weight: .medium))
                }
                .buttonStyle(GlassButtonStyle(color: Glass.accentRed))

                Spacer()

                Button(action: {
                    if let url = URL(string: task.browserURL) { openURLInChrome(url) }
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 9))
                        .foregroundColor(Glass.textTertiary)
                }
                .buttonStyle(.plain)
                .help("Open in browser")

                Button(action: {
                    let summary = store.exportTaskSummary(task)
                    store.copyToClipboard(summary)
                }) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 9))
                        .foregroundColor(Glass.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 24)
            .padding(.top, 2)
        }
        .padding(.horizontal, Glass.padInner)
        .padding(.vertical, 10)
        .background(glassCard())
        .overlay(
            RoundedRectangle(cornerRadius: Glass.radiusCard, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Glass.borderGlow, Glass.borderSubtle],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
        .cornerRadius(Glass.radiusCard)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
    }

    // MARK: - Recent Task Row

    private func recentTaskRow(_ task: ManusTask) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Circle().fill(statusColor(task.status)).frame(width: 6, height: 6)
                Text(task.taskName)
                    .font(.system(size: 11))
                    .foregroundColor(Glass.textSecondary)
                    .lineLimit(1)
                Spacer()
                Button(action: {
                    if let url = URL(string: task.browserURL) { openURLInChrome(url) }
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 8))
                        .foregroundColor(Glass.textMuted)
                }
                .buttonStyle(.plain)
                Text(TaskStore.formatTimeAgo(task.updatedAt))
                    .font(.system(size: 9))
                    .foregroundColor(Glass.textMuted)
                Image(systemName: "chevron.right")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Glass.textMuted)
            }
            // Credits & tool count
            if task.creditsUsed > 0 || task.totalToolCalls > 0 {
                HStack(spacing: 6) {
                    if task.creditsUsed > 0 {
                        miniPill(icon: "sparkles", value: "\(task.creditsUsed)", color: Glass.warmWhite)
                    }
                    if task.totalToolCalls > 0 {
                        miniPill(icon: "wrench.and.screwdriver.fill", value: "\(task.totalToolCalls)", color: Glass.accentCyan)
                    }
                    Spacer()
                }
                .padding(.leading, 14)
            }
        }
        .padding(.horizontal, Glass.padOuter)
        .padding(.vertical, 5)
    }

    // MARK: - Task Detail View (Drill-Down)

    private var taskDetailView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Back button + task header
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        store.selectTask(nil)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Glass.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Glass.cardBg)
                        .overlay(Circle().strokeBorder(Glass.borderSubtle, lineWidth: 0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                if let task = store.selectedTask {
                    Circle()
                        .fill(statusColor(task.status))
                        .frame(width: 8, height: 8)
                        .shadow(color: statusColor(task.status).opacity(0.4), radius: 3)
                        .opacity(task.status == .running ? (pulseAnimation ? 1.0 : 0.4) : 1.0)

                    Text(task.taskName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Glass.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(task.status.label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(statusColor(task.status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor(task.status).opacity(0.12))
                        .overlay(
                            Capsule().strokeBorder(statusColor(task.status).opacity(0.2), lineWidth: 0.5)
                        )
                        .clipShape(Capsule())

                    Button(action: {
                        if let url = URL(string: task.browserURL) { openURLInChrome(url) }
                    }) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Glass.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Open in browser")
                }
            }
            .padding(.horizontal, Glass.padOuter)
            .padding(.top, 14)
            .padding(.bottom, 10)

            glassDivider

            if store.isLoadingDetail {
                HStack {
                    Spacer()
                    ProgressView().scaleEffect(0.7)
                    Text("Loading details...")
                        .font(.system(size: 10))
                        .foregroundColor(Glass.textTertiary)
                    Spacer()
                }
                .padding(.vertical, 30)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        if let task = store.selectedTask {
                            taskInfoBar(task)

                            if task.status.isActive {
                                detailQuickActions(task)
                            }

                            if let detail = store.taskDetail, !detail.planSteps.isEmpty {
                                planTimeline(detail.planSteps)
                            } else if !task.planSteps.isEmpty {
                                planTimeline(task.planSteps)
                            }

                            if task.status.isActive, !task.currentStepTitle.isEmpty {
                                currentStepSection(task)
                            }

                            if !task.nextSteps.isEmpty {
                                nextStepsSection(task.nextSteps)
                            }

                            if let detail = store.taskDetail, !detail.toolStats.isEmpty {
                                toolStatsSection(detail.toolStats)
                            }

                            if let detail = store.taskDetail, !detail.deliverables.isEmpty {
                                deliverablesSection(detail.deliverables)
                            }

                            if let detail = store.taskDetail, !detail.lastExplanation.isEmpty {
                                thinkingSection(detail.lastExplanation)
                            }

                            if let detail = store.taskDetail, !detail.activityFeed.isEmpty {
                                activityFeedSection(detail.activityFeed)
                            }
                        }
                    }
                }
                .frame(maxHeight: 420)
            }

            glassDivider
            footerBar
        }
        .frame(width: 410)
        .background(islandBackground)
        .clipShape(RoundedRectangle(cornerRadius: Glass.radiusOuter, style: .continuous))
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }

    // MARK: - Detail Quick Actions

    private func detailQuickActions(_ task: ManusTask) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                TextField("Send a message...", text: $store.quickMessageText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10))
                    .foregroundColor(Glass.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Glass.inputBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Glass.borderSubtle, lineWidth: 0.5)
                    )
                    .cornerRadius(10)
                    .onSubmit {
                        Task { await store.sendMessageToTask(task.id, content: store.quickMessageText) }
                    }

                if store.isSendingMessage {
                    ProgressView().scaleEffect(0.5).frame(width: 20, height: 20)
                } else {
                    Button(action: {
                        Task { await store.sendMessageToTask(task.id, content: store.quickMessageText) }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(
                                LinearGradient(colors: [Glass.accentBrand, Glass.accentBrand.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 6) {
                if task.status == .waiting {
                    Button(action: { Task { await store.confirmTaskAction(task.id) } }) {
                        Label("Confirm Action", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(GlassButtonStyle(color: Glass.accentGreen))
                }

                Button(action: { Task { await store.stopTask(task.id) } }) {
                    Label("Stop Task", systemImage: "stop.circle.fill")
                        .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(GlassButtonStyle(color: Glass.accentRed))

                Spacer()

                Button(action: {
                    if let t = store.selectedTask {
                        store.copyToClipboard(store.exportTaskSummary(t))
                    }
                }) {
                    Label("Copy Summary", systemImage: "doc.on.clipboard")
                        .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(GlassButtonStyle(color: Glass.accentBlue))

                Button(action: {
                    if let t = store.selectedTask, let url = URL(string: t.browserURL) {
                        openURLInChrome(url)
                    }
                }) {
                    Label("Open in Browser", systemImage: "safari")
                        .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(GlassButtonStyle(color: Glass.accentPurple))
            }

            HStack(spacing: 6) {
                Button(action: {
                    if store.voiceInput.isRecording {
                        Task { await store.stopVoiceAndSendMessage(taskId: task.id) }
                    } else {
                        store.startVoiceRecording()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: store.voiceInput.isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 10))
                        Text(store.voiceInput.isRecording ? "Stop & Send" : "Voice Message")
                            .font(.system(size: 9, weight: .medium))
                    }
                }
                .buttonStyle(GlassButtonStyle(color: store.voiceInput.isRecording ? Glass.accentRed : Glass.textSecondary))

                if store.voiceInput.isRecording {
                    HStack(spacing: 3) {
                        Circle().fill(Glass.accentRed).frame(width: 4, height: 4)
                            .opacity(pulseAnimation ? 1.0 : 0.3)
                        Text(String(format: "%.0fs", store.voiceInput.recordingDuration))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Glass.accentRed.opacity(0.7))
                        HStack(spacing: 1) {
                            ForEach(0..<5, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Glass.accentRed.opacity(Double(i) < Double(store.voiceInput.recordingLevel * 5) ? 0.8 : 0.15))
                                    .frame(width: 2, height: CGFloat(3 + i * 2))
                            }
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal, Glass.padOuter)
        .padding(.vertical, 10)
        .background(Glass.sectionBg)
    }

    // MARK: - Task Info Bar

    private func taskInfoBar(_ task: ManusTask) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                infoCell(icon: "clock", value: TaskStore.formatDuration(task.timeSpent), label: "Duration")
                Spacer()
                infoCell(icon: "list.bullet", value: "\(task.currentStepIndex)/\(task.totalSteps)", label: "Steps")
                Spacer()
                infoCell(icon: "bubble.left.and.bubble.right", value: "\(task.conversationCount)", label: "Messages")
                Spacer()
                infoCell(icon: "wrench", value: "\(task.totalToolCalls)", label: "Tools", color: Glass.accentCyan)
                Spacer()
                infoCell(icon: "sparkles", value: task.creditsUsed > 0 ? "\(task.creditsUsed)" : "--", label: "Credits", color: Glass.warmWhite)
            }
            // Top tools breakdown
            if !task.topTools.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 7))
                        .foregroundColor(Glass.accentCyan.opacity(0.4))
                    Text(task.topTools)
                        .font(.system(size: 8))
                        .foregroundColor(Glass.textTertiary)
                        .lineLimit(1)
                    Spacer()
                }
            }
            // Website status
            if let website = task.websiteInfo {
                websiteStatusRow(website)
            }
        }
        .padding(.horizontal, Glass.padOuter)
        .padding(.vertical, 10)
        .background(Glass.sectionBg)
    }

    private func infoCell(icon: String, value: String, label: String, color: Color? = nil) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(color?.opacity(0.7) ?? Glass.textTertiary)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(color ?? Glass.textPrimary)
                    .contentTransition(.numericText())
            }
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(Glass.textTertiary)
        }
    }

    // MARK: - Current Step Section

    private func currentStepSection(_ task: ManusTask) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("CURRENT STEP", color: Glass.accentBlue)
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Glass.accentBlue.opacity(0.15))
                        .frame(width: 20, height: 20)
                        .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                    Circle()
                        .fill(Glass.accentBlue)
                        .frame(width: 8, height: 8)
                        .shadow(color: Glass.accentBlue.opacity(0.4), radius: 4)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.currentStepTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Glass.textPrimary)
                    if !task.currentToolBrief.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: task.toolIcon)
                                .font(.system(size: 8))
                                .foregroundColor(Glass.accentCyan.opacity(0.8))
                            Text(task.currentToolBrief)
                                .font(.system(size: 9))
                                .foregroundColor(Glass.textTertiary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.horizontal, Glass.padOuter)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Next Steps

    private func nextStepsSection(_ steps: [PlanStep]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("NEXT STEPS", color: Glass.textSecondary)
            ForEach(Array(steps.prefix(3).enumerated()), id: \.offset) { index, step in
                HStack(spacing: 8) {
                    Circle()
                        .stroke(Glass.borderLight, lineWidth: 1)
                        .frame(width: 8, height: 8)
                    Text(step.title ?? "Step")
                        .font(.system(size: 10))
                        .foregroundColor(Glass.textTertiary)
                        .lineLimit(1)
                }
                .padding(.horizontal, Glass.padOuter)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Plan Timeline

    private func planTimeline(_ steps: [PlanStep]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("PLAN", color: Glass.accentGreen)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(stepColor(step.status))
                                .frame(width: 8, height: 8)
                                .shadow(color: stepColor(step.status).opacity(0.3), radius: 3)
                            if step.status == "doing" {
                                Circle()
                                    .stroke(stepColor(step.status).opacity(0.3), lineWidth: 2)
                                    .frame(width: 14, height: 14)
                                    .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                            }
                        }
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(step.status == "done" ? Glass.accentGreen.opacity(0.25) : Glass.borderSubtle)
                                .frame(width: 1)
                                .frame(minHeight: 20)
                        }
                    }
                    .frame(width: 14)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(step.title ?? "Step \(index + 1)")
                                .font(.system(size: 11, weight: step.status == "doing" ? .semibold : .regular))
                                .foregroundColor(step.status == "doing" ? Glass.textPrimary : Glass.textSecondary)
                                .lineLimit(2)
                            Spacer()
                            if let d = step.duration {
                                Text(TaskStore.formatDuration(d))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(Glass.textTertiary)
                            }
                        }
                        if step.status == "doing" {
                            Text("In progress...")
                                .font(.system(size: 9))
                                .foregroundColor(Glass.accentBlue.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, Glass.padOuter)
                .padding(.vertical, 3)
            }
        }
    }

    // MARK: - Tool Stats

    private func toolStatsSection(_ stats: [ToolStat]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionHeader("TOOLS", color: Glass.accentCyan)
                Spacer()
                let totalCalls = stats.reduce(0) { $0 + $1.count }
                Text("\(totalCalls) calls")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(Glass.accentCyan.opacity(0.5))
                    .padding(.trailing, Glass.padOuter)
                    .padding(.top, 8)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(stats.prefix(9)) { stat in
                    VStack(spacing: 3) {
                        Image(systemName: stat.icon)
                            .font(.system(size: 10))
                            .foregroundColor(Glass.accentCyan.opacity(0.8))
                        Text("\(stat.count)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Glass.textPrimary)
                        Text(stat.displayName)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(Glass.textTertiary)
                            .lineLimit(1)
                        if stat.count > 0 {
                            let rate = Double(stat.successCount) / Double(stat.count)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Glass.borderSubtle).frame(height: 2)
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [rate > 0.9 ? Glass.accentGreen : Glass.accentBrand.opacity(0.7), (rate > 0.9 ? Glass.accentGreen : Glass.accentBrand.opacity(0.3))],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * rate, height: 2)
                                }
                            }
                            .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(glassCard(opacity: 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Glass.borderSubtle, lineWidth: 0.5)
                    )
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, Glass.padOuter)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Deliverables

    private func deliverablesSection(_ deliverables: [Deliverable]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("DELIVERABLES", color: Glass.accentPurple)
            ForEach(deliverables) { d in
                HStack(spacing: 8) {
                    Image(systemName: d.icon)
                        .font(.system(size: 10))
                        .foregroundColor(Glass.accentPurple.opacity(0.8))
                        .frame(width: 16)
                    Text(d.filename)
                        .font(.system(size: 11))
                        .foregroundColor(Glass.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    Text(d.contentType.components(separatedBy: "/").last ?? "")
                        .font(.system(size: 9))
                        .foregroundColor(Glass.textMuted)
                }
                .padding(.horizontal, Glass.padOuter)
                .padding(.vertical, 3)
            }
        }
    }

    // MARK: - Thinking

    private func thinkingSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("THINKING", color: Glass.textSecondary)
            Text(text.prefix(200) + (text.count > 200 ? "..." : ""))
                .font(.system(size: 10))
                .foregroundColor(Glass.textTertiary)
                .lineLimit(4)
                .padding(.horizontal, Glass.padOuter)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Glass.sectionBg)
                .cornerRadius(8)
                .padding(.horizontal, Glass.padInner)
        }
    }

    // MARK: - Activity Feed

    private func activityFeedSection(_ items: [ActivityItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("ACTIVITY", color: Glass.textSecondary)
            ForEach(items.prefix(15)) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: item.type.icon)
                        .font(.system(size: 9))
                        .foregroundColor(activityColor(item))
                        .frame(width: 14)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack {
                            Text(item.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Glass.textSecondary)
                            Spacer()
                            Text(TaskStore.formatTimestamp(item.timestamp))
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(Glass.textMuted)
                        }
                        if !item.detail.isEmpty {
                            Text(item.detail)
                                .font(.system(size: 9))
                                .foregroundColor(Glass.textTertiary)
                                .lineLimit(1)
                        }
                    }
                    if let status = item.status {
                        Circle()
                            .fill(status == "success" ? Glass.accentGreen : (status == "error" ? Glass.accentRed : Color.gray))
                            .frame(width: 5, height: 5)
                    }
                }
                .padding(.horizontal, Glass.padOuter)
                .padding(.vertical, 3)
            }
        }
    }

    // MARK: - Connectors & Skills Section

    private var connectorsAndSkillsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !store.connectors.isEmpty {
                sectionHeader("CONNECTORS", color: Glass.accentPurple)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    ForEach(store.connectors) { connector in
                        HStack(spacing: 4) {
                            Image(systemName: connector.icon)
                                .font(.system(size: 8))
                                .foregroundColor(Glass.accentPurple.opacity(0.8))
                            Text(connector.name)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Glass.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(glassCard(opacity: 0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8).strokeBorder(Glass.accentPurple.opacity(0.1), lineWidth: 0.5)
                        )
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, Glass.padOuter)
            }

            if !store.skills.isEmpty {
                sectionHeader("SKILLS", color: Glass.textSecondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    ForEach(store.skills, id: \.id) { skill in
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 7))
                                .foregroundColor(Glass.accentBrand.opacity(0.6))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(skill.name)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(Glass.textSecondary)
                                    .lineLimit(1)
                                if let desc = skill.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.system(size: 7))
                                        .foregroundColor(Glass.textTertiary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(glassCard(opacity: 0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8).strokeBorder(Glass.borderSubtle, lineWidth: 0.5)
                        )
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, Glass.padOuter)
            }
        }
    }

    // MARK: - Credits Summary Section

    private var creditsSummarySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("CREDITS", color: Glass.accentBrand.opacity(0.8))
            HStack(spacing: 0) {
                creditMetric(value: "\(store.accountStats.creditsUsedToday)", label: "Today", color: Glass.warmWhite)
                glassVerticalDivider
                creditMetric(value: "\(store.accountStats.totalCreditsUsed)", label: "Total", color: Glass.textSecondary)
                glassVerticalDivider
                creditMetric(value: store.accountStats.avgCreditsPerTask > 0 ? String(format: "%.1f", store.accountStats.avgCreditsPerTask) : "--", label: "Avg/Task", color: Glass.textTertiary)
                glassVerticalDivider
                creditMetric(value: "\(store.tasks.filter { $0.creditsUsed > 0 }.count)", label: "Tasks", color: Glass.textSecondary)
            }
            .padding(.vertical, 10)
            .background(glassCard(opacity: 0.04))
            .overlay(
                RoundedRectangle(cornerRadius: Glass.radiusCard)
                    .strokeBorder(Glass.accentBrand.opacity(0.1), lineWidth: 0.5)
            )
            .cornerRadius(Glass.radiusCard)
            .padding(.horizontal, 10)
        }
    }

    private func creditMetric(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(Glass.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Activity Heatmap (GitHub-style)

    private var activityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionHeader("ACTIVITY", color: Glass.accentBrand.opacity(0.8))
                Spacer()
                if !store.dailyActivity.isEmpty {
                    let totalCredits = store.dailyActivity.reduce(0) { $0 + $1.absCredits }
                    Text("\(totalCredits.formatted()) credits")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(Glass.accentBrand.opacity(0.6))
                        .padding(.trailing, Glass.padOuter)
                }
            }

            // Heatmap grid
            ActivityHeatmapGrid(dailyData: store.dailyActivity)
                .clipped()
                .padding(.horizontal, 6)
                .padding(.bottom, 10)
        }
    }

    // MARK: - Aggregated Tool Stats

    private var aggregatedToolStatsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionHeader("TOOL USAGE", color: Glass.accentCyan)
                Spacer()
                let totalCalls = store.aggregatedToolStats.reduce(0) { $0 + $1.totalUses }
                Text("\(totalCalls) total calls")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(Glass.accentCyan.opacity(0.4))
                    .padding(.trailing, Glass.padOuter)
                    .padding(.top, 8)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(store.aggregatedToolStats.prefix(9)) { stat in
                    VStack(spacing: 3) {
                        Text("\(stat.totalUses)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Glass.textPrimary)
                        Text(stat.displayName)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(Glass.textTertiary)
                            .lineLimit(1)
                        Text("\(stat.taskCount) tasks")
                            .font(.system(size: 7))
                            .foregroundColor(Glass.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(glassCard(opacity: 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10).strokeBorder(Glass.borderSubtle, lineWidth: 0.5)
                    )
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, Glass.padOuter)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Scheduled Tasks

    private var scheduledTasksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("EXPECTED COMPLETION", color: Glass.accentBlue)
            ForEach(store.scheduledTasks) { scheduled in
                HStack(spacing: 8) {
                    Circle()
                        .fill(scheduled.progress > 0.9 ? Glass.accentGreen : Glass.accentBlue)
                        .frame(width: 6, height: 6)
                        .shadow(color: (scheduled.progress > 0.9 ? Glass.accentGreen : Glass.accentBlue).opacity(0.3), radius: 3)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(scheduled.taskName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Glass.textSecondary)
                            .lineLimit(1)
                        Text(scheduled.etaString)
                            .font(.system(size: 9))
                            .foregroundColor(Glass.accentBlue.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(scheduled.completedSteps)/\(scheduled.totalSteps)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Glass.textTertiary)
                        ProgressView(value: scheduled.progress)
                            .progressViewStyle(.linear)
                            .frame(width: 50)
                            .tint(scheduled.progress > 0.9 ? Glass.accentGreen : Glass.accentBlue)
                    }
                }
                .padding(.horizontal, Glass.padOuter)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Quick Create Task Bar

    private var quickCreateBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(
                        LinearGradient(colors: [Glass.accentBrand, Glass.accentBrand.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    )

                TextField("New task...", text: $store.newTaskPrompt)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(Glass.textPrimary)
                    .onSubmit {
                        Task { await store.createNewTask(prompt: store.newTaskPrompt) }
                    }

                if store.isCreatingTask {
                    ProgressView().scaleEffect(0.5).frame(width: 14, height: 14)
                } else {
                    Button(action: {
                        if store.voiceInput.isRecording {
                            Task { await store.stopVoiceAndCreateTask() }
                        } else {
                            store.startVoiceRecording()
                        }
                    }) {
                        ZStack {
                            if store.voiceInput.isRecording {
                                Circle()
                                    .fill(Glass.accentRed.opacity(0.15))
                                    .frame(width: 24, height: 24)
                                    .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                            }
                            Image(systemName: store.voiceInput.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 17))
                                .foregroundColor(store.voiceInput.isRecording ? Glass.accentRed : Glass.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .help(store.voiceInput.isRecording ? "Stop recording & create task" : "Voice input")

                    if !store.newTaskPrompt.isEmpty {
                        Button(action: {
                            Task { await store.createNewTask(prompt: store.newTaskPrompt) }
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(
                                    LinearGradient(colors: [Glass.accentBrand, Glass.accentBrand.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Voice recording indicator
            if store.voiceInput.isRecording {
                HStack(spacing: 6) {
                    Circle().fill(Glass.accentRed).frame(width: 5, height: 5)
                        .opacity(pulseAnimation ? 1.0 : 0.3)
                    Text("Recording...")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Glass.accentRed.opacity(0.8))
                    Spacer()
                    Text(String(format: "%.1fs", store.voiceInput.recordingDuration))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(Glass.accentRed.opacity(0.6))
                    HStack(spacing: 1) {
                        ForEach(0..<5, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Glass.accentRed.opacity(Double(i) < Double(store.voiceInput.recordingLevel * 5) ? 0.8 : 0.15))
                                .frame(width: 2, height: CGFloat(3 + i * 2))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Glass.cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: Glass.radiusCard)
                .strokeBorder(Glass.borderSubtle, lineWidth: 0.5)
        )
        .cornerRadius(Glass.radiusCard)
    }

    // MARK: - Account Stats Bar

    private var accountStatsBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                statPill(icon: "bolt.fill", value: "\(store.accountStats.runningNow)", label: "Running", color: Glass.accentGreen)
                Spacer()
                statPill(icon: "hand.raised.fill", value: "\(store.accountStats.waitingNow)", label: "Waiting", color: Glass.accentBrand.opacity(0.7))
                Spacer()
                statPill(icon: "checkmark.circle.fill", value: "\(store.accountStats.completedToday)", label: "Today", color: Glass.accentCyan)
                Spacer()
                statPill(icon: "clock.fill", value: store.accountStats.avgDurationToday > 0 ? TaskStore.formatDuration(store.accountStats.avgDurationToday) : "--", label: "Avg", color: Glass.accentPurple)
            }

            // Credits summary row
            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 8))
                        .foregroundColor(Glass.accentBrand.opacity(0.7))
                    Text("Today")
                        .font(.system(size: 8))
                        .foregroundColor(Glass.textTertiary)
                    Text("\(store.accountStats.creditsUsedToday)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Glass.warmWhite)
                        .contentTransition(.numericText())
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("Total")
                        .font(.system(size: 8))
                        .foregroundColor(Glass.textTertiary)
                    Text("\(store.accountStats.totalCreditsUsed)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Glass.textSecondary)
                        .contentTransition(.numericText())
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("Avg")
                        .font(.system(size: 8))
                        .foregroundColor(Glass.textTertiary)
                    Text(store.accountStats.avgCreditsPerTask > 0 ? String(format: "%.1f", store.accountStats.avgCreditsPerTask) : "--")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Glass.textTertiary)
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(glassCard(opacity: 0.04))
        .overlay(
            RoundedRectangle(cornerRadius: Glass.radiusCard)
                .strokeBorder(
                    LinearGradient(
                        colors: [Glass.borderGlow, Glass.borderSubtle],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
        .cornerRadius(Glass.radiusCard)
    }

    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Glass.textPrimary)
                    .contentTransition(.numericText())
            }
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(Glass.textTertiary)
        }
    }

    // MARK: - Shared Components

    private var statusDot: some View {
        Group {
            if let task = store.primaryTask {
                Circle()
                    .fill(statusColor(task.status))
                    .frame(width: 8, height: 8)
                    .shadow(color: statusColor(task.status).opacity(0.4), radius: 3)
            } else if store.isConnected {
                Circle().fill(Color.gray.opacity(0.4)).frame(width: 8, height: 8)
            } else {
                Circle().fill(Glass.accentRed.opacity(0.6)).frame(width: 8, height: 8)
            }
        }
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(color.opacity(0.5))
            .tracking(1.5)
            .padding(.horizontal, Glass.padOuter)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(Glass.textMuted)
            Text("No tasks yet")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Glass.textTertiary)
            Text("Drop files or type above to create a task")
                .font(.system(size: 9))
                .foregroundColor(Glass.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var glassDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Glass.borderSubtle.opacity(0), Glass.borderSubtle, Glass.borderSubtle.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
    }

    private var glassVerticalDivider: some View {
        Rectangle()
            .fill(Glass.borderSubtle)
            .frame(width: 0.5, height: 30)
    }

    private var footerBar: some View {
        HStack(spacing: 8) {
            if let lastRefresh = store.lastRefresh {
                Text("Updated \(TaskStore.formatTimeAgo(lastRefresh))")
                    .font(.system(size: 9))
                    .foregroundColor(Glass.textMuted)
            }
            Spacer()
            if store.isLoading {
                ProgressView().scaleEffect(0.5).frame(width: 12, height: 12)
            }
            Button(action: {
                NotificationCenter.default.post(name: Notification.Name("ToggleSettingsPopover"), object: nil)
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Glass.textTertiary)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, Glass.padOuter)
        .padding(.vertical, 9)
    }

    // MARK: - Website Status Row

    private func websiteStatusRow(_ website: WebsiteInfo) -> some View {
        HStack(spacing: 6) {
            Image(systemName: website.statusIcon)
                .font(.system(size: 8))
                .foregroundColor(website.isPublished ? Glass.accentGreen.opacity(0.8) : Glass.textTertiary)
            Text(website.statusLabel)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(website.isPublished ? Glass.accentGreen.opacity(0.8) : Glass.textTertiary)
            if !website.siteUrl.isEmpty {
                Text(website.siteUrl)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(Glass.textTertiary)
                    .lineLimit(1)
            }
            if website.checkpointCount > 0 {
                Text("v\(website.checkpointCount)")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(Glass.textMuted)
            }
            Spacer()
            if website.isPublished, let url = URL(string: website.siteUrl) {
                Button(action: { openURLInChrome(url) }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 8))
                        Text("Visit")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(Glass.accentGreen.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Glass Pill Components

    private func glassPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(color.opacity(0.8))
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 6).strokeBorder(color.opacity(0.15), lineWidth: 0.5)
        )
        .cornerRadius(6)
    }

    private func miniPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 7))
                .foregroundColor(color.opacity(0.7))
            Text(value)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(color.opacity(0.8))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(color.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 4).strokeBorder(color.opacity(0.1), lineWidth: 0.5)
        )
        .cornerRadius(4)
    }

    // MARK: - Glass Background System

    private var islandBackground: some View {
        ZStack {
            // Base blur layer
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: Glass.radiusOuter, style: .continuous))

            // Dark tint for depth
            RoundedRectangle(cornerRadius: Glass.radiusOuter, style: .continuous)
                .fill(Color.black.opacity(0.5))

            // Subtle gradient overlay for glass depth
            RoundedRectangle(cornerRadius: Glass.radiusOuter, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.04), Color.clear, Color.white.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Top-lit glass border
            RoundedRectangle(cornerRadius: Glass.radiusOuter, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.30), Color.white.opacity(0.08), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 8)
    }

    private func glassBackground(cornerRadius: CGFloat) -> some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.45))
        }
    }

    private func glassCard(opacity: CGFloat = 0.06) -> some View {
        RoundedRectangle(cornerRadius: Glass.radiusCard, style: .continuous)
            .fill(Color.white.opacity(opacity))
    }

    // MARK: - Helpers

    private func statusColor(_ status: ManusTask.TaskStatus) -> Color {
        switch status {
        case .running: return Glass.accentGreen
        case .waiting: return Glass.accentBrand.opacity(0.7)
        case .error: return Glass.accentRed
        case .stopped: return Color(white: 0.4)
        case .unknown: return Color(white: 0.3)
        }
    }

    private func stepColor(_ status: String?) -> Color {
        switch status {
        case "done": return Glass.accentGreen
        case "doing": return Glass.accentBlue
        case "failed": return Glass.accentRed
        default: return Glass.textMuted
        }
    }

    private func activityColor(_ item: ActivityItem) -> Color {
        switch item.type {
        case .tool: return Glass.accentCyan
        case .explanation: return Glass.textSecondary
        case .status: return Glass.accentBlue
        case .message: return Glass.accentGreen
        case .plan: return Glass.accentPurple
        }
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(configuration.isPressed ? 0.18 : 0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(color.opacity(configuration.isPressed ? 0.3 : 0.15), lineWidth: 0.5)
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Apple Glass Blur (NSVisualEffectView wrapper)

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Activity Heatmap Grid (GitHub-style)

struct ActivityHeatmapGrid: View {
    let dailyData: [DailyStatistic]

    // Grid layout: 7 rows (days of week) x 35 columns (8 months)
    private let rows = 7
    private let totalWeeks = 35
    private let cellSize: CGFloat = 8
    private let cellSpacing: CGFloat = 2.3

    // Green spectrum - Manus brand accent, high contrast on dark
    private let colors: [Color] = [
        Color.white.opacity(0.06),     // Level 0: barely visible
        Color(red: 0.3, green: 0.9, blue: 0.6).opacity(0.30),     // Level 1: soft green
        Color(red: 0.3, green: 0.9, blue: 0.6).opacity(0.55),     // Level 2: medium green
        Color(red: 0.3, green: 0.9, blue: 0.6).opacity(0.78),     // Level 3: strong green
        Color(red: 0.3, green: 0.9, blue: 0.6).opacity(1.0),      // Level 4: full green
    ]

    private var adjustedStart: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let totalDays = totalWeeks * 7
        let startDate = calendar.date(byAdding: .day, value: -(totalDays - 1), to: today) ?? today
        // Adjust to start on Sunday
        let weekday = calendar.component(.weekday, from: startDate) // 1=Sun, 7=Sat
        return calendar.date(byAdding: .day, value: -(weekday - 1), to: startDate) ?? startDate
    }

    private var gridData: [[Int]] {
        let calendar = Calendar.current

        // Create a lookup from date -> credits
        var creditsByDay: [String: Int] = [:]
        for stat in dailyData {
            let date = Date(timeIntervalSince1970: TimeInterval(stat.dateTimestamp))
            let key = Self.dayKey(from: date)
            creditsByDay[key] = stat.absCredits
        }

        let start = adjustedStart

        // Build grid: columns = weeks, rows = days of week
        var grid: [[Int]] = Array(repeating: Array(repeating: 0, count: rows), count: totalWeeks)

        for week in 0..<totalWeeks {
            for day in 0..<rows {
                let dayOffset = week * 7 + day
                guard let cellDate = calendar.date(byAdding: .day, value: dayOffset, to: start) else { continue }
                let key = Self.dayKey(from: cellDate)
                grid[week][day] = creditsByDay[key] ?? 0
            }
        }

        return grid
    }

    private var maxCredits: Int {
        dailyData.map { $0.absCredits }.max() ?? 1
    }

    private func intensityLevel(credits: Int) -> Int {
        guard credits > 0, maxCredits > 0 else { return 0 }
        let ratio = Double(credits) / Double(maxCredits)
        if ratio > 0.75 { return 4 }
        if ratio > 0.5 { return 3 }
        if ratio > 0.25 { return 2 }
        return 1
    }

    private var monthLabels: [(String, Int)] {
        let calendar = Calendar.current
        let start = adjustedStart

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var labels: [(String, Int)] = []
        var lastMonth = -1

        for week in 0..<totalWeeks {
            guard let weekStart = calendar.date(byAdding: .day, value: week * 7, to: start) else { continue }
            let month = calendar.component(.month, from: weekStart)
            if month != lastMonth {
                labels.append((formatter.string(from: weekStart), week))
                lastMonth = month
            }
        }
        return labels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if dailyData.isEmpty {
                // Empty state
                VStack(spacing: 6) {
                    Image(systemName: "chart.dots.scatter")
                        .font(.system(size: 20))
                        .foregroundColor(Glass.accentBrand.opacity(0.25))
                    Text("Activity data loading...")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            } else {
                // Month labels - positioned above the correct week columns
                let gridWidth = CGFloat(totalWeeks) * (cellSize + cellSpacing) - cellSpacing
                ZStack(alignment: .leading) {
                    Color.clear.frame(width: gridWidth, height: 14)
                    ForEach(monthLabels, id: \.1) { label, weekIndex in
                        Text(label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.70))  // Glass.textSecondary
                            .offset(x: CGFloat(weekIndex) * (cellSize + cellSpacing))
                    }
                }
                .padding(.bottom, 3)

                // Heatmap grid
                let data = gridData
                HStack(spacing: cellSpacing) {
                    ForEach(0..<min(data.count, totalWeeks), id: \.self) { week in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<rows, id: \.self) { day in
                                let credits = week < data.count ? data[week][day] : 0
                                let level = intensityLevel(credits: credits)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(colors[level])
                                    .frame(width: cellSize, height: cellSize)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .strokeBorder(Glass.accentBrand.opacity(level > 0 ? 0.12 : 0.03), lineWidth: 0.5)
                                    )
                                    .help(credits > 0 ? "\(credits) credits" : "No activity")
                            }
                        }
                    }
                }

                // Legend
                HStack(spacing: 4) {
                    Spacer()
                    Text("Less")
                        .font(.system(size: 7))
                        .foregroundColor(Color.white.opacity(0.45))
                    ForEach(0..<5, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(colors[level])
                            .frame(width: 7, height: 7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 1.5)
                                    .strokeBorder(Glass.accentBrand.opacity(0.08), lineWidth: 0.5)
                            )
                    }
                    Text("More")
                        .font(.system(size: 7))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
    }

    /// Convert a Date to a "YYYY-MM-DD" string for reliable day matching
    private static func dayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}

import SwiftUI

struct MainWindow: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var showHistorySheet = StateValue(false)
    @StateObject private var showDeleteAlert = StateValue(false)
    @StateObject private var associationToDelete = OptionalStateValue<ManagedAssociation>()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 保护状态栏
                if !appState.associations.isEmpty {
                    protectionStatusBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(nsColor: .controlBackgroundColor))
                    Divider()
                }

                // 主内容
                AssociationListView()

                // duti 未安装提示
                if !appState.dutiInstalled && !appState.associations.isEmpty {
                    Divider()
                    DutiNotInstalledView()
                }
            }
            .navigationTitle("DutiUI")
            .toolbar {
                // 左侧：保护控制
                ToolbarItemGroup(placement: .navigation) {
                    protectionControl
                }

                // 右侧：操作按钮
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showHistorySheet.value = true
                    } label: {
                        Label(
                            Locale.current.isChinese ? "最近修改" : "Recent Changes",
                            systemImage: "clock.arrow.circlepath"
                        )
                    }
                    .disabled(appState.history.isEmpty)

                    Button {
                        appState.showAddSheet = true
                    } label: {
                        Label(
                            Locale.current.isChinese ? "添加文件类型" : "Add File Type",
                            systemImage: "plus"
                        )
                    }
                    .disabled(!appState.dutiInstalled)
                }
            }
            .sheet(isPresented: $showHistorySheet.value) {
                HistoryView()
                    .environmentObject(appState)
            }
            .alert(
                Locale.current.isChinese ? "删除管理项" : "Remove Managed Item",
                isPresented: $showDeleteAlert.value
            ) {
                Button(Locale.current.isChinese ? "取消" : "Cancel", role: .cancel) {}
                Button(Locale.current.isChinese ? "删除" : "Remove", role: .destructive) {
                    if let assoc = associationToDelete.value {
                        appState.deleteAssociation(assoc)
                    }
                }
            } message: {
                if let assoc = associationToDelete.value {
                    Text(String(format:
                        Locale.current.isChinese
                            ? "确定要删除 .%@ 的管理项吗？\n\n当前默认应用不会被修改。"
                            : "Remove .%@ from managed items?\n\nThe current default app will not be changed.",
                        assoc.fileExtension
                    ))
                }
            }
            .alert(
                Locale.current.isChinese ? "错误" : "Error",
                isPresented: $appState.showError
            ) {
                Button("OK") {
                    appState.dismissError()
                }
            } message: {
                Text(appState.errorMessage ?? "")
            }
        }
        .task {
            startProtectionIfNeeded()
        }
    }

    // MARK: - Protection Status Bar

    private var protectionStatusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(protectionStatusColor)
                .frame(width: 8, height: 8)

            Text(protectionStatusText)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            // 已锁定项目数量
            let lockedCount = appState.associations.filter(\.isLocked).count
            if lockedCount > 0 {
                Text(String(format:
                    Locale.current.isChinese
                        ? "已锁定 %d 项"
                        : "%d locked",
                    lockedCount
                ))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
            }
        }
    }

    private var protectionStatusColor: Color {
        if !appState.protectionService.isRunning || appState.protectionService.isPaused {
            return .secondary
        }
        return .green
    }

    private var protectionStatusText: String {
        if !appState.protectionService.isRunning {
            return Locale.current.isChinese ? "保护未启动" : "Protection Off"
        }
        if appState.protectionService.isPaused {
            return Locale.current.isChinese ? "保护已暂停" : "Protection Paused"
        }
        return Locale.current.isChinese ? "保护中" : "Protection Active"
    }

    // MARK: - Protection Control

    @ViewBuilder
    private var protectionControl: some View {
        if appState.protectionService.isRunning && !appState.protectionService.isPaused {
            Button {
                appState.protectionService.pause()
            } label: {
                Label(
                    Locale.current.isChinese ? "暂停保护" : "Pause Protection",
                    systemImage: "pause.circle"
                )
            }
        } else if appState.protectionService.isRunning && appState.protectionService.isPaused {
            Button {
                appState.protectionService.resume()
            } label: {
                Label(
                    Locale.current.isChinese ? "恢复保护" : "Resume Protection",
                    systemImage: "play.circle"
                )
            }
        }
    }

    // MARK: - Lifecycle

    private func startProtectionIfNeeded() {
        let hasLockedItems = appState.associations.contains(where: \.isLocked)
        if hasLockedItems || appState.protectionService.autoStartProtection {
            appState.protectionService.start()
        }
    }
}

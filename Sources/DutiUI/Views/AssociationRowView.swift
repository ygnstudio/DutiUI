import SwiftUI

struct AssociationRowView: View {
    let association: ManagedAssociation
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 16) {
            // 文件类型
            VStack(alignment: .leading, spacing: 2) {
                Text(".\(association.fileExtension)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                Text(association.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 120, alignment: .leading)

            // 默认应用
            HStack(spacing: 6) {
                appIconView
                Text(association.targetApplicationName)
                    .font(.body)
            }
            .frame(width: 160, alignment: .leading)

            // 锁定
            Toggle("", isOn: Binding(
                get: { association.isLocked },
                set: { _ in appState.toggleLock(for: association) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .frame(width: 50)

            // 状态
            statusBadge
                .frame(width: 80, alignment: .leading)

            // 操作按钮
            HStack(spacing: 8) {
                Button {
                    appState.selectedAssociation = association
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help(Locale.current.isChinese ? "编辑" : "Edit")

                Button {
                    appState.deleteAssociation(association)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .help(Locale.current.isChinese ? "删除" : "Delete")
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - App Icon

    @ViewBuilder
    private var appIconView: some View {
        if let path = association.targetApplicationPath,
           FileManager.default.fileExists(atPath: path) {
            let icon = NSWorkspace.shared.icon(forFile: path)
            Image(nsImage: icon)
                .resizable()
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: "app.fill")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Status Badge

    @ViewBuilder
    private var statusBadge: some View {
        switch association.status {
        case .normal:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text(Locale.current.isChinese ? "正常" : "Normal")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        case .unlocked:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                Text(Locale.current.isChinese ? "未保护" : "Unprotected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        case .changed:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
                Text(Locale.current.isChinese ? "已变化" : "Changed")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        case .restoreFailed:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                Text(Locale.current.isChinese ? "恢复失败" : "Failed")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        case .targetApplicationMissing:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                Text(Locale.current.isChinese ? "应用不存在" : "App Missing")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

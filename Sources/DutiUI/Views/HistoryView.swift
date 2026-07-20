import SwiftUI
import AppKit

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var selectedRecord = OptionalStateValue<AssociationHistory>()

    var body: some View {
        ZStack {
            // 透明背景，点击关闭
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                // 头部
                HStack {
                    Text(Locale.current.isChinese ? "最近修改" : "Recent Changes")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(String(format:
                        Locale.current.isChinese
                            ? "最多保留 %d 条记录"
                            : "Maximum %d records retained",
                        500
                    ))
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(Locale.current.isChinese ? "关闭" : "Close")
                    .keyboardShortcut(.escape)
                }
                .padding(16)

                Divider()

                // 内容
                if appState.history.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text(Locale.current.isChinese
                            ? "暂无修改记录"
                            : "No change records"
                        )
                        .font(.body)
                        .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List(appState.history.sorted(by: { $0.createdAt > $1.createdAt })) { record in
                        Button {
                            selectedRecord.value = record
                        } label: {
                            historyRow(record)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 400)
        .sheet(item: $selectedRecord.value) { record in
            HistoryDetailView(record: record)
        }
    }

    // MARK: - History Row

    private func historyRow(_ record: AssociationHistory) -> some View {
        HStack(spacing: 12) {
            // 时间
            Text(timeFormatter.string(from: record.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)

            // 扩展名
            Text(".\(record.fileExtension)")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)

            // 检测到的应用
            Text(record.detectedApplicationName ?? "-")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            // 目标应用
            Text(record.expectedApplicationName)
                .font(.caption)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            // 结果
            resultBadge(record.result)
                .frame(width: 70, alignment: .leading)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func resultBadge(_ result: RestoreResult) -> some View {
        switch result {
        case .restored:
            HStack(spacing: 4) {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text(Locale.current.isChinese ? "已恢复" : "Restored")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        case .failed:
            HStack(spacing: 4) {
                Circle().fill(Color.red).frame(width: 6, height: 6)
                Text(Locale.current.isChinese ? "恢复失败" : "Failed")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        case .skipped:
            HStack(spacing: 4) {
                Circle().fill(Color.orange).frame(width: 6, height: 6)
                Text(Locale.current.isChinese ? "已跳过" : "Skipped")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
}

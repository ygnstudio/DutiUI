import SwiftUI

struct HistoryDetailView: View {
    let record: AssociationHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: resultIcon)
                    .foregroundColor(resultColor)
                Text(record.result.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Divider()

            // 详情字段
            detailRow(
                label: Locale.current.isChinese ? "时间" : "Time",
                value: formattedDate
            )

            detailRow(
                label: Locale.current.isChinese ? "文件类型" : "File Type",
                value: ".\(record.fileExtension)"
            )

            detailRow(
                label: Locale.current.isChinese ? "目标应用" : "Target App",
                value: record.expectedApplicationName
            )

            if let detected = record.detectedApplicationName {
                detailRow(
                    label: Locale.current.isChinese ? "检测到的应用" : "Detected App",
                    value: detected
                )
            }

            detailRow(
                label: Locale.current.isChinese ? "处理结果" : "Result",
                value: record.result.displayName
            )

            if let duration = record.duration {
                detailRow(
                    label: Locale.current.isChinese ? "耗时" : "Duration",
                    value: String(format: "%.2f %@",
                        duration,
                        Locale.current.isChinese ? "秒" : "s"
                    )
                )
            }

            if let error = record.errorMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Locale.current.isChinese ? "错误信息" : "Error")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 400, height: 360)
    }

    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: record.createdAt)
    }

    private var resultIcon: String {
        switch record.result {
        case .restored: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "slash.circle.fill"
        }
    }

    private var resultColor: Color {
        switch record.result {
        case .restored: return .green
        case .failed: return .red
        case .skipped: return .orange
        }
    }
}

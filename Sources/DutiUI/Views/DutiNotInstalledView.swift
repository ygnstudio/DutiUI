import SwiftUI

struct DutiNotInstalledView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)

            Text(Locale.current.isChinese ? "尚未安装 duti" : "duti Not Installed")
                .font(.title3)
                .fontWeight(.semibold)

            Text(Locale.current.isChinese
                ? "需要安装 duti 才能修改默认应用。"
                : "duti is required to modify default applications."
            )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 300)

            Text(Locale.current.isChinese
                ? "请在终端运行："
                : "Run this in Terminal:"
            )
            .font(.caption)
            .foregroundColor(.secondary)

            HStack {
                Text("brew install duti")
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("brew install duti", forType: .string)
                } label: {
                    Label(
                        Locale.current.isChinese ? "复制安装命令" : "Copy Command",
                        systemImage: "doc.on.doc"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Button {
                appState.refreshDutiStatus()
            } label: {
                Label(
                    Locale.current.isChinese ? "重新检测" : "Check Again",
                    systemImage: "arrow.clockwise"
                )
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
    }
}

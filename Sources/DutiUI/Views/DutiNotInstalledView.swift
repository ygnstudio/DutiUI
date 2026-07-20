import SwiftUI

struct DutiNotInstalledView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
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
            .frame(maxWidth: 360)

            // 根据 Homebrew 是否安装显示不同指引
            if appState.homebrewInstalled {
                brewAvailableView
            } else {
                brewNotAvailableView
            }

            // 手动安装（始终可见作为备选）
            manualInstallView

            // 重新检测按钮
            HStack(spacing: 12) {
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
            .padding(.top, 4)
        }
        .padding()
    }

    // MARK: - Homebrew 已安装：直接 brew install duti

    private var brewAvailableView: some View {
        VStack(spacing: 6) {
            Text(Locale.current.isChinese
                ? "已检测到 Homebrew，请在终端运行："
                : "Homebrew detected. Run in Terminal:"
            )
            .font(.caption)
            .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Text("brew install duti")
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
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
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help(Locale.current.isChinese ? "复制命令" : "Copy")
            }
        }
    }

    // MARK: - Homebrew 未安装：先装 Homebrew，再装 duti

    private var brewNotAvailableView: some View {
        VStack(spacing: 10) {
            Text(Locale.current.isChinese
                ? "推荐先安装 Homebrew，再通过它安装 duti："
                : "Recommended: install Homebrew first, then duti:"
            )
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 360)

            // 第 1 步：安装 Homebrew
            VStack(alignment: .leading, spacing: 4) {
                Text(Locale.current.isChinese
                    ? "第 1 步：安装 Homebrew"
                    : "Step 1: Install Homebrew"
                )
                .font(.caption)
                .fontWeight(.semibold)

                HStack(spacing: 4) {
                    Text("/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
                        .font(.system(size: 9, design: .monospaced))
                        .lineLimit(2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(
                            "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
                            forType: .string
                        )
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }

            // 第 2 步：brew install duti
            VStack(alignment: .leading, spacing: 4) {
                Text(Locale.current.isChinese
                    ? "第 2 步：安装 duti"
                    : "Step 2: Install duti"
                )
                .font(.caption)
                .fontWeight(.semibold)

                HStack(spacing: 4) {
                    Text("brew install duti")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
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
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    // MARK: - 手动安装指引（备选方案）

    private var manualInstallView: some View {
        VStack(spacing: 4) {
            Divider()
                .padding(.vertical, 4)

            Text(Locale.current.isChinese
                ? "备选：手动编译安装"
                : "Alternative: Manual Build"
            )
            .font(.caption)
            .fontWeight(.medium)

            Text(Locale.current.isChinese
                ? "从 GitHub 下载 duti 源码并编译：\ngit clone https://github.com/moretension/duti.git\ncd duti && make && sudo make install"
                : "Download duti source from GitHub and build:\ngit clone https://github.com/moretension/duti.git\ncd duti && make && sudo make install"
            )
            .font(.system(size: 10, design: .monospaced))
            .multilineTextAlignment(.leading)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .frame(maxWidth: 360, alignment: .leading)

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(
                    "git clone https://github.com/moretension/duti.git && cd duti && make && sudo make install",
                    forType: .string
                )
            } label: {
                Label(
                    Locale.current.isChinese ? "复制手动安装命令" : "Copy Manual Install",
                    systemImage: "doc.on.doc"
                )
                .font(.caption2)
            }
        }
    }
}

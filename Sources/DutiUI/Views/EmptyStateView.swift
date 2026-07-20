import SwiftUI

struct EmptyStateView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text(Locale.current.isChinese
                ? "还没有管理任何文件类型"
                : "No File Types Managed Yet"
            )
            .font(.title2)
            .fontWeight(.medium)

            Text(Locale.current.isChinese
                ? "添加一个你想修改或锁定默认应用的扩展名。"
                : "Add a file extension you want to manage or lock the default app for."
            )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 320)

            Button {
                appState.showAddSheet = true
            } label: {
                Label(
                    Locale.current.isChinese ? "添加文件类型" : "Add File Type",
                    systemImage: "plus.circle.fill"
                )
                .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

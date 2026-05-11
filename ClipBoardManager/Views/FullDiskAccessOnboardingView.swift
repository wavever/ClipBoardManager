import SwiftUI
import AppKit

struct FullDiskAccessOnboardingView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.accentColor, .accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: .accentColor.opacity(0.3), radius: 6, y: 2)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("一次授权，告别权限弹框")
                        .font(.system(size: 16, weight: .bold))
                    Text("让 ClipBoard Manager 可以预览任意文件")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle().fill(.secondary.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .help("关闭")
            }

            Text("当你复制位于「桌面」「下载」「文稿」「iCloud 云盘」等受保护位置的文件时，macOS 会逐个文件夹弹窗请求授权。\n\n在「系统设置 → 隐私与安全性 → 完全磁盘访问」中打开 ClipBoard Manager 的开关后，所有此类提示都会消失。")
                .font(.system(size: 12.5))
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            steps

            HStack(spacing: 10) {
                Button {
                    Self.openFullDiskAccessPane()
                    onDismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("打开系统设置")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor)
                    )
                }
                .buttonStyle(.plain)

                Button(action: onDismiss) {
                    Text("稍后再说")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.secondary.opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(20)
        .frame(width: 460, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.separator.opacity(0.55), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 6) {
            stepRow(index: 1, text: "点击下方「打开系统设置」")
            stepRow(index: 2, text: "在列表中找到 ClipBoard Manager")
            stepRow(index: 3, text: "把右侧开关打开（可能需要解锁）")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.secondary.opacity(0.10))
        )
    }

    private func stepRow(index: Int, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(index)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.accentColor))
            Text(text)
                .font(.system(size: 12.5))
                .foregroundStyle(.primary.opacity(0.85))
        }
    }

    static func openFullDiskAccessPane() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}

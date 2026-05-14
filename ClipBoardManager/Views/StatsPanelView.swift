import SwiftUI
import AppKit

struct StatsPanelView: View {
    @ObservedObject private var nav = AppNavigation.shared
    @ObservedObject private var store = CopyStatsStore.shared

    private static let mdFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M/d"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 14)

            ScrollView {
                content
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .background(
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)
        )
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: { nav.showList() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().strokeBorder(.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("返回")
            .keyboardShortcut(.escape, modifiers: [])

            VStack(alignment: .leading, spacing: 2) {
                Text("活跃统计")
                    .font(.system(size: 28, weight: .bold))
                Text("基于本地剪贴板监听的复制次数")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var content: some View {
        VStack(spacing: 14) {
            SettingCard(title: "汇总", subtitle: "近期复制行为的整体概览") {
                HStack(spacing: 14) {
                    summaryTile(label: "今日", value: store.todayCount(), tint: .accentColor)
                    summaryTile(label: "近 7 天", value: store.countLast(days: 7), tint: .purple)
                    summaryTile(label: "近 30 天", value: store.countLast(days: 30), tint: .blue)
                    summaryTile(label: "总计", value: store.totalAllTime, tint: .secondary)
                }
            }

            SettingCard(title: "活跃热力图", subtitle: "过去 53 周每日复制活跃度") {
                ContributionWall(store: store)
            }

            SettingCard(title: "最近 14 天", subtitle: "每日复制次数趋势") {
                chart
            }
        }
    }

    private func summaryTile(label: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tint)
                    .frame(width: 5, height: 5)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            Text("\(value)")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.background.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.separator.opacity(0.4), lineWidth: 0.5)
        )
    }

    private var chart: some View {
        let days = store.lastDays(14)
        let maxCount = max(days.map(\.count).max() ?? 0, 1)
        let calendar = Calendar.current

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, entry in
                    let isToday = calendar.isDateInToday(entry.date)
                    VStack(spacing: 4) {
                        Text("\(entry.count)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(entry.count > 0 ? .primary : .tertiary)
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.secondary.opacity(0.10))
                                .frame(height: 64)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isToday ? Color.accentColor : Color.accentColor.opacity(0.55))
                                .frame(height: max(CGFloat(entry.count) / CGFloat(maxCount) * 64, entry.count > 0 ? 4 : 0))
                        }
                        Text(Self.mdFormatter.string(from: entry.date))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Contribution wall (GitHub-style heatmap)

private struct ContributionWall: View {
    @ObservedObject var store: CopyStatsStore

    private let weeks = 53
    private let cellSize: CGFloat = 11
    private let gap: CGFloat = 3

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月"
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy-MM-dd EEEE"
        return f
    }()

    private struct DayCell {
        let date: Date?
        let count: Int
    }

    var body: some View {
        let grid = buildGrid()
        let maxCount = max(grid.flatMap { $0 }.map(\.count).max() ?? 0, 1)
        let totalCount = grid.flatMap { $0 }.map(\.count).reduce(0, +)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("过去一年共 \(totalCount) 次复制")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                legend
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: gap) {
                    weekdayLabels
                    VStack(alignment: .leading, spacing: 2) {
                        monthLabels(for: grid)
                        weekColumns(grid: grid, maxCount: maxCount)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var weekdayLabels: some View {
        VStack(alignment: .trailing, spacing: gap) {
            Color.clear.frame(width: 18, height: 12)
            ForEach(0..<7, id: \.self) { row in
                Text(row == 1 ? "Mon" : row == 3 ? "Wed" : row == 5 ? "Fri" : "")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: cellSize, alignment: .trailing)
            }
        }
    }

    private func monthLabels(for grid: [[DayCell]]) -> some View {
        let calendar = Calendar.current
        var labels: [(col: Int, text: String)] = []
        var lastMonth: Int = -1
        for (i, week) in grid.enumerated() {
            guard let firstDate = week.compactMap(\.date).first else { continue }
            let month = calendar.component(.month, from: firstDate)
            if month != lastMonth {
                labels.append((col: i, text: Self.monthFormatter.string(from: firstDate)))
                lastMonth = month
            }
        }

        return ZStack(alignment: .topLeading) {
            Color.clear.frame(width: CGFloat(weeks) * (cellSize + gap), height: 12)
            ForEach(Array(labels.enumerated()), id: \.offset) { _, item in
                Text(item.text)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .offset(x: CGFloat(item.col) * (cellSize + gap))
            }
        }
    }

    private func weekColumns(grid: [[DayCell]], maxCount: Int) -> some View {
        HStack(alignment: .top, spacing: gap) {
            ForEach(Array(grid.enumerated()), id: \.offset) { _, week in
                VStack(spacing: gap) {
                    ForEach(0..<7, id: \.self) { row in
                        let cell = week[row]
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color(for: cell, max: maxCount))
                            .frame(width: cellSize, height: cellSize)
                            .help(tooltip(for: cell))
                    }
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Text("少").font(.system(size: 9)).foregroundStyle(.secondary)
            ForEach(0..<5, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorForLevel(level))
                    .frame(width: cellSize, height: cellSize)
            }
            Text("多").font(.system(size: 9)).foregroundStyle(.secondary)
        }
    }

    private func buildGrid() -> [[DayCell]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let firstWeekday = calendar.firstWeekday
        let todayWeekday = calendar.component(.weekday, from: today)
        let daysSinceWeekStart = (todayWeekday - firstWeekday + 7) % 7
        let lastWeekEnd = calendar.date(byAdding: .day, value: 6 - daysSinceWeekStart, to: today) ?? today

        let totalDays = weeks * 7
        let firstDay = calendar.date(byAdding: .day, value: -(totalDays - 1), to: lastWeekEnd) ?? today

        var grid: [[DayCell]] = []
        var cursor = firstDay
        for _ in 0..<weeks {
            var column: [DayCell] = []
            for _ in 0..<7 {
                let isFuture = cursor > today
                let date: Date? = isFuture ? nil : cursor
                let count = isFuture ? 0 : store.count(on: cursor)
                column.append(DayCell(date: date, count: count))
                cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
            }
            grid.append(column)
        }
        return grid
    }

    private func color(for cell: DayCell, max: Int) -> Color {
        guard let _ = cell.date else { return Color.clear }
        if cell.count == 0 { return Color.secondary.opacity(0.12) }
        let ratio = Double(cell.count) / Double(max)
        let level: Int
        if ratio < 0.25      { level = 1 }
        else if ratio < 0.5  { level = 2 }
        else if ratio < 0.75 { level = 3 }
        else                 { level = 4 }
        return colorForLevel(level)
    }

    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return Color.secondary.opacity(0.12)
        case 1: return Color.accentColor.opacity(0.30)
        case 2: return Color.accentColor.opacity(0.55)
        case 3: return Color.accentColor.opacity(0.80)
        default: return Color.accentColor
        }
    }

    private func tooltip(for cell: DayCell) -> String {
        guard let date = cell.date else { return "" }
        return "\(Self.dayFormatter.string(from: date)) · \(cell.count) 次"
    }
}

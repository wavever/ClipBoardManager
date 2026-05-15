# 新增特性总览

本轮基于 Maccy（https://github.com/p0deje/Maccy）社区 issue 收集的高频需求，新增 10 项功能。下文按用户使用路径组织，并对每项注明对应的 Maccy issue（如有）。

---

## 1. 主界面新入口

工具栏右半区从左到右依次为：

| 图标 | 功能 | 快捷键 | 详见 |
|---|---|---|---|
| ✏️ `square.and.pencil` | 新建片段 | ⌘N | §6 |
| ✅ `checkmark.circle` | 多选合并 | — | 原有 |
| 🗑 `trash` | 垃圾桶 | — | §9 |
| 📊 `chart.bar.xaxis` | 活跃统计 | — | 原有 |
| ⚙️ `gearshape` | 设置 | ⌘, | 原有 |

主列表上方在「全部」分页下，若存在置顶条目，会显示一个可点击的「📌 置顶 N 条」分组头，**点一下整段折叠/展开**（折叠状态由 AppStorage 持久化）。

> 📎 Maccy #307 — Pinned items take too much UI space

---

## 2. 净化链接（默认开启）

复制 `http(s)://` 链接时，自动去除常见跟踪参数（28 个），仅保留语义信息：

```
https://www.example.com/post?utm_source=mailchimp&utm_campaign=q3&id=42&fbclid=…
                              ↓
https://www.example.com/post?id=42
```

支持的参数前缀来源：UTM (Google Analytics)、Google Ads、Facebook / Instagram、Microsoft Ads、Mailchimp、Marketo、LinkedIn、TikTok、Twitter / X、Yandex、HubSpot、Adobe、eBay、Alibaba (spm/scm)、Vero 等。

`ref` 等可能携带语义的参数**不会**被剥离（在 GitHub / Reddit 上有意义）。

📍 设置 → 过滤 → 净化链接
📎 Maccy #1332

---

## 3. 复制时清理末尾空白（默认关闭）

再次复制一个历史条目时，可选地去除末尾空格 / 换行。原条目内容不变，只影响写入剪贴板的字符串。

📍 设置 → 通用 → 复制时清理末尾空白
📎 Maccy #1044

---

## 4. 屏幕录制中隐藏（默认关闭）

开启后将主窗口 `NSWindow.sharingType` 切到 `.none`，剪贴板内容不会出现在录屏 / 屏幕共享 / 系统截图中。适合直播、屏录、远程会议场景。

📍 设置 → 通用 → 屏幕录制中隐藏
📎 Maccy #1126

---

## 5. 重复复制刷新时间

复制已有内容时，不再创建新条目，而是把已存在条目的时间戳更新到当前——它会自动浮回顶部。统计计数仍 +1。

> 之前的行为是静默跳过，导致重复复制后列表顺序"看上去没动"。

📎 Maccy #1124

---

## 6. 手动片段（Canned Responses）

工具栏 ✏️ 按钮（⌘N）或菜单触发，打开片段编辑器：

- TextEditor 大编辑区
- 类型选择：文本 / 链接 / 富文本
- 可选「保存后置顶」（默认开）
- ⌘⏎ 保存，Esc 取消

片段以 `sourceApp = "片段"` 入库，会进入语义搜索的 embedding 流水线，与剪贴板捕获条目完全等价（可收藏、合并、删除、导出）。

> 适合常用邮箱、邀请码、固定模板、问候语。

📎 Maccy #1005 / #1125

---

## 7. 预览面板智能解析

预览 popover 在文本 / URL / RTF 内容下方追加"解析卡片"，自动识别三种常见编码：

- **Epoch 时间戳**（10 或 13 位数字，1990–2100）→ UTC 与本地时间
- **Base64**（4 字节对齐、长度 ≥12、含至少一个非字母字符、能 UTF-8 解码）→ 解码后的明文（最多 280 字）
- **JSON**（以 `{` 或 `[` 开头且可解析）→ 排版后的 `prettyPrinted + sortedKeys`（最多 600 字）

每张卡片支持文本选中复制。三者可同时显示。

📎 Maccy #1333

---

## 8. 按类型自动清理

按 `ClipboardItemType` 分别设定保留天数：永久 / 1 / 7 / 30 / 90 / 180 天。每小时（以及启动时）自动清扫一遍。

- **豁免规则**：置顶 / 收藏 条目永远保留
- 启用了垃圾桶时，命中保留期限的条目**移入垃圾桶**而不是直接删除（双重缓冲）
- 设置面板提供「立即清理」按钮

📍 设置 → 数据 → 自动清理
📎 Maccy #368

---

## 9. 垃圾桶

删除条目不再立即销毁，先进入垃圾桶；自动清理也会先把过期条目"软删除"到垃圾桶。

**主界面入口**：工具栏 🗑 按钮 → 垃圾桶面板：
- 列表按删除时间倒序
- 每行两个动作：**恢复**（回到历史，时间戳刷新）/ **彻底删除**（不可逆）
- 顶部 banner 显示"共 N 条 · X 天后自动清理"
- 右上角「清空垃圾桶」一次性清空

**设置**：
- 「启用垃圾桶」开关（默认开启）
- 「自动清理」窗口：1 / 3 / 7（默认）/ 14 / 30 天，或永久

**数据模型**：`ClipboardItem.deletedAt: Date?` 软删除标记。`nil` = 在用历史；非空 = 在垃圾桶。`filteredItems` 自动过滤掉 `deletedAt != nil` 的行，确保主列表与计数都不再看到它们。

📍 设置 → 数据 → 启用垃圾桶 + 自动清理

---

## 10. MCP 服务器（让 AI 工具搜你的剪贴板）

应用以 stdio 方式可作为 Model Context Protocol 服务器运行。Claude Desktop / Claude Code / Cursor 等 MCP 客户端启动它后，可以通过工具调用我们的本地语义搜索。

### 启用方式

App binary 本身就是 MCP server——传入 `--mcp` 即进入服务模式，否则照常启动 GUI。

在 Claude Desktop 配置文件中添加：

```json
{
  "mcpServers": {
    "clipboard": {
      "command": "/Applications/ClipBoardManager.app/Contents/MacOS/ClipBoardManager",
      "args": ["--mcp"]
    }
  }
}
```

或 Claude Code 的 `.mcp.json`：

```json
{
  "mcpServers": {
    "clipboard": {
      "type": "stdio",
      "command": "/Applications/ClipBoardManager.app/Contents/MacOS/ClipBoardManager",
      "args": ["--mcp"]
    }
  }
}
```

### 暴露的工具

| 工具 | 入参 | 用途 |
|---|---|---|
| `search_clipboard` | `query` (string), `limit?` (int=10), `semantic?` (bool=true) | 按关键词或语义在历史中搜索；默认使用 Apple NLEmbedding 句向量做余弦相似度（阈值 0.25），无结果时回退关键词 |
| `list_recent` | `limit?` (int=20), `type?` (string) | 最近 N 条；可按类型过滤（`text` / `url` / `image` / `video` / `file` / `rtf`）|
| `get_clip` | `id` (UUID string) | 取单条全文 + 元数据（type / sourceApp / createdAt / isPinned / isFavorite / 长度）|

所有工具自动剔除垃圾桶里的条目。结果格式：

```
[1] [text] (Cursor, 2026-05-15T16:23:11Z) — let result = await ...
ID: 9F8B1C7E-...
```

### 实现要点

- JSON-RPC 2.0 over stdio，换行分隔
- 共享同一 SwiftData store（SQLite WAL，可与 GUI 并发读）
- stdout **只**写 JSON-RPC 响应；日志走 stderr，绝不污染协议流

📎 Maccy #1068

---

## 设置面板新结构

```
设置
├─ 通用
│   ├─ 完全磁盘访问
│   ├─ 登录时启动
│   ├─ 在 Dock 中显示
│   ├─ 显示菜单栏图标
│   ├─ 屏幕录制中隐藏 ⭐ 新增
│   ├─ 复制时清理末尾空白 ⭐ 新增
│   ├─ 最大记录数
│   └─ 监听间隔
├─ 快捷键
├─ 过滤
│   ├─ 净化链接 ⭐ 新增
│   ├─ 排除的应用
│   ├─ 排除的类型
│   └─ 文本规则
├─ 合并
└─ 数据
    ├─ 启用垃圾桶 + 自动清理 ⭐ 新增
    ├─ 记录拷贝次数
    ├─ 自动清理（按类型保留天数）⭐ 新增
    ├─ 导出历史
    ├─ 清空历史
    └─ 清除统计
```

主屏幕路由：`list` / `settings` / `stats` / `trash` ⭐ 新增

---

## 文件清单（新增 / 显著变更）

新增：
- `Services/URLSanitizer.swift` — 链接去跟踪参数
- `Services/MCPServer.swift` — MCP stdio 协议层
- `Views/SnippetEditorView.swift` — 新建片段编辑器
- `Views/TrashPanelView.swift` — 垃圾桶视图
- `docs/CHANGELOG.md` — 本文档

显著变更：
- `Models/ClipboardItem.swift` — 新增 `deletedAt: Date?`
- `Models/FilterSettings.swift` — 新增 `stripURLTracking` / `retentionByType` / `trashEnabled` / `trashRetentionDays`
- `Models/AppNavigation.swift` — 新增 `.trash` 屏幕
- `ViewModels/ClipboardViewModel.swift` — 新增 `createSnippet` / `restoreItem` / `purgeItem` / `emptyTrash` / `trashedItems` / `applyRetentionCleanup`；`deleteItem` 改为软删除；`filteredItems` 过滤已删除项
- `ClipBoardManagerApp.swift` — `@main` 改到 `AppLauncher`，分流 `--mcp` 到 `MCPServer`
- `Views/SettingsPanelView.swift` — 取消统计标签页，新增数据标签页（数据 / 自动清理 / 垃圾桶 / 链接净化）；记录开关与清除统计移入数据
- `Views/MainWindowView.swift` — 工具栏新增 ✏️ 📊 🗑 三个入口；置顶折叠头；选择手势收敛为单击或双击二选一

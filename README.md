<p align="center">
  <img src="ClipTrace/Assets.xcassets/AppLogo.imageset/AppLogo@2x.png" width="96" alt="ClipTrace logo" />
</p>

<h1 align="center">剪迹 / ClipTrace</h1>

<p align="center">
  <strong>English</strong> · <a href="#中文">中文</a>
</p>

<p align="center">
  A lightweight macOS clipboard manager with local semantic search, MCP integration, and a warm, muted aesthetic.
</p>

---

## Features

### Core
- **Auto-monitoring** — captures text, images, video, files, URLs, and rich text in real time
- **One-click copy** — double-click any entry to write it back to the clipboard
- **Duplicate refresh** — re-copying an existing item bumps it to the top instead of creating a duplicate
- **Trim trailing whitespace** — optionally strip trailing spaces/newlines on re-copy
- **Screen recording hide** — exclude the window from screen captures and screen sharing
- **Global hotkeys** — `⌘⇧V` for main window, `⌘N` for new snippet

### Organization
- **Favorites & Pinned** — star or pin entries; pinned items float to the top with a collapsible section
- **Tags** — add/remove tags per item; search by tag with autocomplete
- **Multi-select & Merge** — select 2+ items of the same type and merge them with configurable separators
- **Soft-delete Trash** — deleted items go to trash; restore or permanently delete; auto-purge after configurable days

### Smart Search
- **Full-text search** with type filters (text / image / video / file / URL / rich text)
- **Semantic search** — powered by Apple NLEmbedding, fully offline, zero cost
- **Tag search mode** — every word is a tag candidate with autocomplete
- **Auto-backfill** — missing embeddings are computed on launch
- **Fallback** — semantic results empty? Falls back to keyword search automatically

### Preview & Content Awareness
- **Rich preview popover** — hover to preview any item
- **Smart parsing** — auto-detects epoch timestamps, Base64, and JSON in text content
- **Video preview** — configurable: first-frame thumbnail or inline player with mute toggle
- **URL sanitization** — strips 28+ tracking parameters (UTM, fbclid, gclid, etc.) on copy

### Snippets
- **Manual snippets** — `⌘N` opens the editor; saved items auto-pin and join the semantic index
- **Source tag** — labeled as "Snippet" in the list for easy identification

### Export & Stats
- **JSON export** — filter by type, date range, favorites/pinned
- **Per-item export** — right-click to save as original format (txt, png, etc.)
- **Copy stats** — daily count, 14-day bar chart, GitHub-style heatmap

### AI Integration (MCP Server)

The app binary doubles as a [Model Context Protocol](https://modelcontextprotocol.io/) stdio server. Connect it to Claude Desktop, Claude Code, or Cursor to let AI search your clipboard.

```json
{
  "mcpServers": {
    "clipboard": {
      "command": "/Applications/ClipTrace.app/Contents/MacOS/ClipTrace",
      "args": ["--mcp"]
    }
  }
}
```

| Tool | Parameters | Description |
|---|---|---|
| `search_clipboard` | `query`, `limit?`, `semantic?` | Keyword or semantic search over history |
| `list_recent` | `limit?`, `type?` | Latest N items, optionally filtered by type |
| `get_clip` | `id` | Full content + metadata for a single item |

## System Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ / Swift 5.9+

## Build & Run

**Xcode:** Open `ClipTrace.xcodeproj`, select "My Mac", hit Run.

**Command line:**
```bash
xcodebuild -project ClipTrace.xcodeproj -scheme ClipTrace -configuration Debug build
```

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘⇧V` | Open main window |
| `⌘,` | Open settings |
| `⌘N` | New snippet |
| `⌘⏎` | Save in snippet editor |
| `Esc` | Dismiss preview / go back / cancel edit |

## Privacy

- All data stored locally via SwiftData (SQLite)
- Semantic search uses Apple NLEmbedding — **fully offline**, no network requests
- MCP server runs locally over stdio; no outbound connections
- No analytics, no telemetry, no data collection
- Per-app exclusion, per-type retention, URL tracking stripping built in

## License

MIT

---

# 中文

<p align="center">
  <strong><a href="#">English</a></strong> · 中文
</p>

<p align="center">
  轻量级 macOS 剪贴板历史管理工具，内置本地语义搜索与 MCP AI 集成。
</p>

---

## 功能特性

### 核心
- **自动监听** — 实时捕获文字、图片、视频、文件、链接、富文本
- **一键复制** — 双击条目即可写回剪贴板
- **重复刷新** — 复制已有内容时自动浮到顶部，不产生重复
- **清理末尾空白** — 可选去除写回时的末尾空格/换行
- **录屏隐身** — 窗口不出现在录屏/屏幕共享中
- **全局快捷键** — `⌘⇧V` 呼出主窗口，`⌘N` 新建片段

### 整理
- **收藏与置顶** — 收藏常用条目，置顶自动浮顶，支持折叠
- **标签** — 每条可添加/移除标签，搜索栏支持标签自动补全
- **多选合并** — 选中 2+ 条同类型条目，自定义分隔符合并
- **垃圾桶** — 软删除，可恢复/彻底删除，支持自动清理

### 智能搜索
- **全文搜索** — 按类型筛选（文字/图片/视频/文件/链接/富文本）
- **语义搜索** — 基于 Apple NLEmbedding，完全离线
- **标签搜索** — 每个词都是标签候选，支持自动补全
- **无结果回退** — 语义无匹配时自动回退关键词

### 预览与内容感知
- **富预览面板** — hover 即可预览
- **智能解析** — 自动识别时间戳、Base64、JSON
- **视频预览** — 可选首帧缩略图或内联播放器（支持静音）
- **链接净化** — 复制时自动剥离 28+ 跟踪参数

### 片段
- **手动创建** — `⌘N` 打开编辑器，保存后自动置顶并进入语义索引

### 导出与统计
- **JSON 导出** — 按类型、时间范围、收藏/置顶筛选
- **复制统计** — 每日计数、14 天柱状图、GitHub 风格热力图

### AI 集成（MCP Server）

应用 binary 同时是一个 MCP stdio 服务，可接入 Claude Desktop / Claude Code / Cursor：

```json
{
  "mcpServers": {
    "clipboard": {
      "command": "/Applications/ClipTrace.app/Contents/MacOS/ClipTrace",
      "args": ["--mcp"]
    }
  }
}
```

| 工具 | 参数 | 用途 |
|---|---|---|
| `search_clipboard` | `query`, `limit?`, `semantic?` | 关键词或语义搜索 |
| `list_recent` | `limit?`, `type?` | 最近 N 条，可按类型筛选 |
| `get_clip` | `id` | 获取单条完整内容与元数据 |

## 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- Xcode 15.0+ / Swift 5.9+

## 构建运行

**Xcode：** 打开 `ClipTrace.xcodeproj`，选择 "My Mac"，点击运行。

**命令行：**
```bash
xcodebuild -project ClipTrace.xcodeproj -scheme ClipTrace -configuration Debug build
```

## 快捷键

| 快捷键 | 功能 |
|---|---|
| `⌘⇧V` | 打开主窗口 |
| `⌘,` | 打开设置 |
| `⌘N` | 新建片段 |
| `⌘⏎` | 保存片段 |
| `Esc` | 关闭预览 / 返回 / 取消 |

## 隐私

- 所有数据仅存储在本地（SwiftData / SQLite）
- 语义搜索使用 Apple NLEmbedding，完全离线
- MCP server 本地运行，不主动联网
- 无分析、无遥测、不收集任何数据

## 许可证

MIT

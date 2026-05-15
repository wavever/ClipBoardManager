# ClipBoardManager - macOS 剪贴板历史管理器

一款轻量级的 macOS 剪贴板历史管理工具，支持文字、图片、视频、文件等多种类型的剪贴板内容记录和管理。内置本地语义搜索，无需联网即可按语义查找历史片段；同时以 MCP server 形式开放给 Claude / Cursor 等 AI 工具调用。

> 📜 最近一次大规模特性更新（垃圾桶、片段、MCP、URL 净化、预览智能解析等）详见 [`docs/CHANGELOG.md`](docs/CHANGELOG.md)。

## ✨ 功能特性

### 核心
- 🔄 **自动监听** — 实时监控剪贴板变化，自动记录历史
- 📋 **多类型支持** — 文字、图片、视频、文件、链接、富文本
- 📌 **一键复制** — 双击历史条目即可重新写入剪贴板
- 🔍 **全文搜索** — 按关键词搜索、按类型筛选
- ♻️ **重复内容自动归并** — 复制已有内容时刷新时间戳并浮到顶部，不再产生重复条目
- 🧼 **复制时整理空白** — 可选去除写回剪贴板的末尾空格 / 换行（设置 → 通用）
- 🎬 **录屏隐身** — 可选让主窗口不出现在录屏 / 屏幕共享 / 系统截图（`NSWindow.sharingType = .none`）
- 🗑️ **垃圾桶** — 删除走软删除流程，可在主界面恢复或彻底删除（见下方专节）
- 🖥️ **菜单栏快捷** — MenuBar Extra 快速访问，复制按钮带成功反馈动画
- ⌨️ **全局快捷键** — `⌘⇧V` 呼出主窗口，`⌘N` 新建片段
- ⚙️ **偏好设置** — 最大记录数、排除应用/类型、监听间隔、过滤规则等

### 收藏与置顶
- ⭐ **收藏** — 收藏常用条目，star 按钮一键切换
- 📌 **置顶** — 置顶条目自动浮至列表顶部
- 📂 **置顶折叠** — 「全部」分页下置顶区有可点击的「置顶 N 条」分组头，一键收起/展开
- 🔀 **Scope 筛选** — 工具栏 segmented control 切换「全部 / 收藏 / 置顶」

### 语义搜索
- 🧠 **本地 Embedding** — 基于 Apple NLEmbedding 的句子向量，完全离线、零成本
- ✨ **语义模式** — 搜索框右侧 sparkle 按钮切换全文 / 语义搜索
- 🔄 **自动回填** — 启动时为缺少向量的旧条目自动计算 embedding
- ↩️ **无结果回退** — 语义匹配无结果时自动回退到关键词搜索

### 导出
- 📤 **JSON 导出** — 按类型、时间范围（今天/7天/30天/自定义）、收藏/置顶筛选导出
- 🖼️ **图片数据可选** — 导出时可选包含图片 base64 数据
- 💾 **单条导出** — 右键菜单导出单条为原始格式（txt/png/原格式）

### 合并
- ✅ **多选模式** — 工具栏 ✓ 按钮进入选择模式，每行显示勾选框
- 🪄 **同类型合并** — 选中 2+ 条同类型条目，一键拼接为新记录
- 📝 **文本/链接/富文本** — 自定义分隔符（空行/换行/逗号/制表符/自定义，支持 `\n` `\t` 转义）
- 📁 **文件/视频** — 路径按行拼接，分隔符可配置
- 🖼️ **图片拼接** — 可选启用，支持纵向 / 横向拼接，可设置间距与背景色（透明 / 白 / 黑）
- 🗑️ **可选删除原条目** — 合并后保留或删除原始条目，设置中切换
- 🔘 **批量操作** — 选择栏内提供全选 / 反选 / 清空 / 取消按钮

### 统计
- 📊 **每日复制计数** — 每次剪贴板捕获自动 +1，主窗口标题副栏显示「今日 N 次」
- 🔘 **开关控制** — 设置 → 统计中开关，关闭后不再记录（已有数据保留）
- 🔢 **多维汇总** — 今日 / 近 7 天 / 近 30 天 / 总计四宫格
- 📈 **14 天柱状图** — 直观查看最近两周趋势，今日柱用强调色高亮
- 🟩 **GitHub 风格热力图** — 过去 53 周活跃度网格，5 档色阶 + 月份标签 + hover 显示具体日期与次数
- 🧹 **一键清除** — 重置所有日期的计数（无法撤销）

### 内容感知
- 🏷️ **细粒度类型标签** — 文件按 UTType 显示精确类型（音频文件/视频文件/PDF文档/压缩文件/软件包/代码文件等）
- 🔗 **链接一键打开** — URL 类型条目 hover 显示 safari 按钮，支持纯域名自动补 https
- 🧪 **链接自动净化** — 复制带 `utm_*` / `fbclid` / `gclid` / `msclkid` / `mc_eid` / `mkt_tok` 等 28+ 跟踪参数的 URL 时自动剥离，仅保留语义部分（默认开启）
- 👁️ **内容预览** — hover 预览按钮弹出详情面板
- 🔮 **预览智能解析** — 对文本 / 链接 / 富文本预览，自动识别并展示
  - ⏰ **Epoch 时间戳**（10 位秒 / 13 位毫秒，1990–2100）→ UTC + 本地时间
  - 🔐 **Base64 字符串** → UTF-8 解码后明文（最多 280 字符）
  - 📦 **JSON** → `prettyPrinted + sortedKeys` 排版（最多 600 字符，独立滚动）

### 片段（Canned Responses）
- ✏️ **手动创建** — 工具栏 ✏️ 按钮或 `⌘N` 打开编辑器，输入内容即存入历史
- 📌 **默认置顶** — 片段创建时自动置顶（可关），与历史条目共享搜索、收藏、合并、导出能力
- 🏷️ **来源识别** — `sourceApp = "片段"`，可在列表中一眼区分
- 🧠 **语义检索友好** — 创建后异步计算 embedding，与剪贴板捕获条目一起参与语义搜索

### 垃圾桶（软删除）
- 🗑️ **主界面入口** — 工具栏 trash 图标进入，列表按删除时间倒序
- ↩️ **恢复 / 彻底删除** — 每行两个动作，恢复后回到历史并刷新时间戳
- ⏳ **自动清理** — 可在「设置 → 数据 → 启用垃圾桶」配置自动清理窗口（1 / 3 / 7（默认）/ 14 / 30 天 / 永久）
- 🔢 **状态显示** — 顶部 banner 显示总条数与剩余清理时间，每行细字提示该条剩余多少
- 🧹 **一键清空** — 右上角「清空垃圾桶」立即彻底删除全部条目

### 自动清理
- 🗂️ **按类型保留** — 在「设置 → 数据 → 自动清理」分别为文字 / 图片 / 视频 / 文件 / 链接 / 富文本设置保留时长（永久 / 1 / 7 / 30 / 90 / 180 天）
- ⏱️ **每小时巡检 + 启动时执行** — 命中规则的条目会被移入垃圾桶（若启用），未启用则直接删除
- 🔒 **置顶 / 收藏 豁免** — 用户手动标记过的条目永远保留
- 🪄 **立即清理** — 设置面板有按钮可手动触发一次

### 权限引导
- 🔐 **完全磁盘访问引导** — 首次启动浮层卡片引导授权，避免重复权限弹框
- ⚙️ **设置入口** — 设置面板可重新查看引导或直达系统设置

### 🤖 AI 集成（MCP server）
应用 binary 同时是一个 Model Context Protocol stdio 服务。把它接入 Claude Desktop / Claude Code / Cursor，AI 工具就能搜你的剪贴板。

**配置示例**（Claude Desktop / Claude Code 通用）：

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

**暴露的工具：**

| 工具 | 入参 | 用途 |
|---|---|---|
| `search_clipboard` | `query` (string)，`limit?=10`，`semantic?=true` | 关键词或语义检索历史；默认走 Apple NLEmbedding 句向量余弦相似度（阈值 0.25），失败回退关键词 |
| `list_recent` | `limit?=20`，`type?` | 最近 N 条，可按类型过滤（`text` / `url` / `image` / `video` / `file` / `rtf`） |
| `get_clip` | `id` (UUID) | 取单条完整内容 + 元数据 |

**实现要点：**
- 与 GUI 共享同一 SwiftData store（SQLite WAL 模式允许并发读）
- 垃圾桶里的条目自动剔除
- newline-delimited JSON-RPC 2.0，stdout 仅写协议帧，日志走 stderr，不污染管道

## 📋 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- Xcode 15.0+
- Swift 5.9+

## 🚀 构建和运行

### 方式一：Xcode 打开
1. 双击打开 `ClipBoardManager.xcodeproj`
2. 选择目标设备为 "My Mac"
3. 点击 ▶️ 运行

### 方式二：命令行构建
```bash
cd ClipBoardManager
xcodebuild -project ClipBoardManager.xcodeproj -scheme ClipBoardManager -configuration Debug build
```

## 📁 项目结构

```
ClipBoardManager/
├── ClipBoardManagerApp.swift              # @main AppLauncher：分流 --mcp / GUI；SwiftUI 场景与 AppDelegate
├── Models/
│   ├── ClipboardItem.swift                # SwiftData 模型（含 embedding、deletedAt 软删除标记）
│   ├── FilterSettings.swift               # 过滤 + URL 净化 + 按类型保留 + 垃圾桶配置
│   ├── MergeSettings.swift                # 合并偏好（分隔符、图片拼接、删除原条目）
│   ├── CopyStats.swift                    # 每日复制次数统计（含开关、热力图数据）
│   └── AppNavigation.swift                # 主屏路由：list / settings / stats / trash
├── Views/
│   ├── MainWindowView.swift               # 主窗口（toolbar + 置顶折叠 + 多选浮动栏 + toast）
│   ├── ClipboardItemRow.swift             # 列表行视图（hover 操作栏 + 选择框）
│   ├── MenuBarView.swift                  # 菜单栏弹出视图（含复制成功状态）
│   ├── SettingsPanelView.swift            # 设置面板（通用 / 快捷键 / 过滤 / 合并 / 数据）
│   ├── StatsPanelView.swift               # 活跃统计独立屏（汇总 / 热力图 / 14 天柱状图）
│   ├── TrashPanelView.swift               # 垃圾桶屏（恢复 / 彻底删除 / 清空）
│   ├── SnippetEditorView.swift            # 「新建片段」编辑器 sheet
│   ├── ExportPanelView.swift              # JSON 导出筛选面板
│   ├── FullDiskAccessOnboardingView.swift # 完全磁盘访问引导卡片
│   ├── ToastView.swift                    # Toast 提示视图
│   ├── ThumbnailView.swift                # 文件缩略图
│   ├── PreviewPopover.swift               # 内容预览弹出框（含 epoch / Base64 / JSON 智能解析）
│   └── VisualEffectView.swift             # 毛玻璃背景
├── ViewModels/
│   └── ClipboardViewModel.swift           # 视图模型（筛选/语义搜索/监控/选择合并/软删除/保留清理）
├── Services/
│   ├── ClipboardMonitor.swift             # 剪贴板监听服务
│   ├── EmbeddingService.swift             # 本地句子 embedding（NLEmbedding 封装）
│   ├── URLSanitizer.swift                 # URL 跟踪参数清理（utm_* / fbclid / gclid 等 28 个）
│   ├── MCPServer.swift                    # MCP stdio 服务（JSON-RPC 2.0 + 三个工具）
│   ├── ExportService.swift                # 导出服务（JSON/单条）
│   ├── ImageStitcher.swift                # 图片纵/横向拼接（NSImage 绘制）
│   ├── ToastCenter.swift                  # 全局 Toast 管理
│   ├── ThumbnailLoader.swift              # QuickLook 缩略图加载
│   ├── QuickLookCoordinator.swift         # QuickLook 预览协调
│   └── FileOpener.swift                   # 用其他应用打开文件
├── Assets.xcassets/                       # 资源文件
└── Info.plist                             # 应用配置

docs/
└── CHANGELOG.md                           # 最近一次特性总览（10 项新特性详解）
```

## ⌨️ 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌘⇧V` | 全局呼出主窗口 |
| `⌘,` | 打开设置 |
| `⌘N` | 新建片段 |
| `⌘⏎` | 在片段编辑器中保存 |
| `Esc` | 关闭预览 / 返回主列表 / 取消片段编辑 |

## 🔒 隐私说明

- 所有剪贴板数据仅存储在本地，SwiftData 默认路径
- 语义搜索使用 Apple NLEmbedding（OS 内置模型），**完全离线**，不涉及任何网络请求
- MCP server 同样运行在本地（stdio），不主动联网；只有当 AI 客户端发起 `tools/call` 时才向客户端返回数据
- 不收集、不上传任何用户数据
- 可通过偏好设置排除特定应用、按类型设保留期、链接默认剥离跟踪参数
- 「屏幕录制中隐藏」开关可让主窗口对录屏 / 屏幕共享 / 系统截图不可见

## 📄 许可证

MIT License

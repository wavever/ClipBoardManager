# ClipBoardManager - macOS 剪贴板历史管理器

一款轻量级的 macOS 剪贴板历史管理工具，支持文字、图片、视频、文件等多种类型的剪贴板内容记录和管理。内置本地语义搜索，无需联网即可按语义查找历史片段。

## ✨ 功能特性

### 核心
- 🔄 **自动监听** — 实时监控剪贴板变化，自动记录历史
- 📋 **多类型支持** — 文字、图片、视频、文件、链接、富文本
- 📌 **一键复制** — 双击历史条目即可重新写入剪贴板
- 🔍 **全文搜索** — 按关键词搜索、按类型筛选
- 🗑️ **批量管理** — 单条/批量删除、清空历史
- 🖥️ **菜单栏快捷** — MenuBar Extra 快速访问，复制按钮带成功反馈动画
- ⌨️ **全局快捷键** — `⌘⇧V` 快速呼出主窗口
- ⚙️ **偏好设置** — 最大记录数、排除应用/类型、监听间隔、过滤规则等

### 收藏与置顶
- ⭐ **收藏** — 收藏常用条目，star 按钮一键切换
- 📌 **置顶** — 置顶条目自动浮至列表顶部
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
- 👁️ **内容预览** — hover 预览按钮弹出详情面板

### 权限引导
- 🔐 **完全磁盘访问引导** — 首次启动浮层卡片引导授权，避免重复权限弹框
- ⚙️ **设置入口** — 设置面板可重新查看引导或直达系统设置

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
├── ClipBoardManagerApp.swift              # 应用入口 + AppDelegate
├── Models/
│   ├── ClipboardItem.swift                # SwiftData 数据模型（含 embedding 字段）
│   ├── FilterSettings.swift               # 过滤规则（排除应用/类型/关键词）
│   ├── MergeSettings.swift                # 合并偏好（分隔符、图片拼接、删除原条目）
│   ├── CopyStats.swift                    # 每日复制次数统计（含开关、热力图数据）
│   └── AppNavigation.swift                # 导航状态管理
├── Views/
│   ├── MainWindowView.swift               # 主窗口（toolbar + 列表 + 多选浮动栏 + toast）
│   ├── ClipboardItemRow.swift             # 列表行视图（hover 操作栏 + 选择框）
│   ├── MenuBarView.swift                  # 菜单栏弹出视图（含复制成功状态）
│   ├── SettingsPanelView.swift            # 设置面板（通用/快捷键/过滤/合并/统计）
│   ├── ExportPanelView.swift              # JSON 导出筛选面板
│   ├── FullDiskAccessOnboardingView.swift # 完全磁盘访问引导卡片
│   ├── ToastView.swift                    # Toast 提示视图
│   ├── ThumbnailView.swift                # 文件缩略图
│   ├── PreviewPopover.swift               # 内容预览弹出框
│   └── VisualEffectView.swift             # 毛玻璃背景
├── ViewModels/
│   └── ClipboardViewModel.swift           # 视图模型（筛选/语义搜索/监控/选择合并）
├── Services/
│   ├── ClipboardMonitor.swift             # 剪贴板监听服务
│   ├── EmbeddingService.swift             # 本地句子 embedding（NLEmbedding 封装）
│   ├── ExportService.swift                # 导出服务（JSON/单条）
│   ├── ImageStitcher.swift                # 图片纵/横向拼接（NSImage 绘制）
│   ├── ToastCenter.swift                  # 全局 Toast 管理
│   ├── ThumbnailLoader.swift              # QuickLook 缩略图加载
│   ├── QuickLookCoordinator.swift         # QuickLook 预览协调
│   └── FileOpener.swift                   # 用其他应用打开文件
├── Assets.xcassets/                       # 资源文件
├── Info.plist                             # 应用配置
└── README.md
```

## ⌨️ 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌘⇧V` | 全局呼出主窗口 |
| `⌘,` | 打开设置 |
| `⌘C` | 复制选中条目 |
| `⌘⌫` | 删除选中条目 |

## 🔒 隐私说明

- 所有剪贴板数据仅存储在本地，SwiftData 默认路径
- 语义搜索使用 Apple NLEmbedding（OS 内置模型），**完全离线**，不涉及任何网络请求
- 不收集、不上传任何用户数据
- 可通过偏好设置排除特定应用的剪贴板内容

## 📄 许可证

MIT License

# ClipBoardManager - macOS 剪贴板历史管理器

一款轻量级的 macOS 剪贴板历史管理工具，支持文字、图片、视频、文件等多种类型的剪贴板内容记录和管理。

## ✨ 功能特性

- 🔄 **自动监听** — 实时监控剪贴板变化，自动记录历史
- 📋 **多类型支持** — 文字、图片、视频、文件、链接、富文本
- 👁️ **内容预览** — 右侧面板预览完整内容（文字可选中、图片可缩放、视频可播放）
- 📌 **一键复制** — 双击历史条目即可重新写入剪贴板
- 🔍 **搜索过滤** — 按关键词搜索、按类型筛选
- ⭐ **收藏置顶** — 收藏和置顶常用条目
- 🗑️ **批量管理** — 单条/批量删除、清空历史
- 📤 **导出功能** — 导出为文件（文字→txt，图片→png，视频→原格式）
- 🖥️ **菜单栏快捷** — MenuBar Extra 快速访问
- ⌨️ **全局快捷键** — `⌘⇧V` 快速呼出主窗口
- ⚙️ **偏好设置** — 最大记录数、排除应用、监听间隔等

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
├── ClipBoardManagerApp.swift      # 应用入口 + AppDelegate
├── Models/
│   └── ClipboardItem.swift        # SwiftData 数据模型
├── Views/
│   ├── MainWindowView.swift       # 主窗口（三栏布局）
│   ├── ClipboardItemRow.swift     # 列表行视图
│   ├── DetailView.swift           # 内容详情/预览
│   ├── MenuBarView.swift          # 菜单栏弹出视图
│   └── PreferencesView.swift      # 偏好设置
├── ViewModels/
│   └── ClipboardViewModel.swift   # 视图模型（核心逻辑）
├── Services/
│   ├── ClipboardMonitor.swift     # 剪贴板监听服务
│   └── ExportService.swift        # 导出服务
├── Assets.xcassets/               # 资源文件
├── Info.plist                     # 应用配置
└── README.md
```

## ⌨️ 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌘⇧V` | 全局呼出主窗口 |
| `⌘C` | 复制选中条目 |
| `⌘⌫` | 删除选中条目 |
| `⌘A` | 全选 |
| `Delete` | 删除 |

## 🔒 隐私说明

- 所有剪贴板数据仅存储在本地 `~/Library/Application Support/ClipBoardManager/` 目录
- 不收集、不上传任何用户数据
- 可通过偏好设置排除特定应用的剪贴板内容

## 📄 许可证

MIT License

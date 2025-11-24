# MorphVPN iOS

基于 Capacitor 和 WireGuard 的 iOS VPN 应用。

## 📚 文档导航

### 🚀 快速开始
- **[QUICK_START.md](QUICK_START.md)** - 最快的开始方式（推荐从这里开始）

### 📖 详细文档
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - 完整的设置和配置指南
- **[BUILD_FIXES.md](BUILD_FIXES.md)** - 构建问题详细解决方案
- **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** - 项目修改总结

### 🔧 工具
- **[verify_setup.sh](verify_setup.sh)** - 验证项目配置脚本

## ⚡ 快速开始

```bash
# 1. 验证配置
bash verify_setup.sh

# 2. 安装 CocoaPods (如果需要)
sudo gem install cocoapods

# 3. 清理缓存
rm -rf ~/Library/Developer/Xcode/DerivedData

# 4. 安装依赖
cd ios/App && pod install && cd ../..

# 5. 打开 Xcode
npx cap open ios
```

在 Xcode 中：
1. File → Packages → Reset Package Caches
2. Product → Clean Build Folder (⇧⌘K)
3. 选择真实 iOS 设备
4. Product → Build (⌘B)

## ✅ 项目特点

- ✅ **本地 WireGuardKit 包** - 不依赖远程下载，构建更稳定
- ✅ **完整的文档** - 详细的设置和故障排查指南
- ✅ **自动验证** - 使用 verify_setup.sh 检查配置
- ✅ **Xcode 16 支持** - 使用最新的项目格式

## 📋 系统要求

- macOS 13+ (Ventura 或更新)
- Xcode 15 或 16
- CocoaPods 1.15.0+
- Node.js 和 npm
- 真实 iOS 设备（Network Extension 不支持模拟器）

## 🏗️ 项目结构

```
morphvpn-ios/
├── packages/
│   ├── wireguard-apple/          # 本地 WireGuardKit 包
│   └── wireguard-plugin/          # Capacitor WireGuard 插件
├── ios/
│   └── App/
│       ├── App/                   # 主应用
│       ├── WireGuardExtension/    # Network Extension
│       └── Podfile
├── src/                           # 前端源码
├── QUICK_START.md                 # 快速开始
├── SETUP_GUIDE.md                 # 完整设置指南
├── BUILD_FIXES.md                 # 构建问题修复
└── verify_setup.sh                # 配置验证脚本
```

## 🔧 已解决的问题

1. ✅ WireGuardKit 包路径 - 从远程改为本地包
2. ✅ WireGuardGoBridgeiOS 构建目录 - 更新为正确路径
3. ✅ objectVersion 70 兼容性 - 提供 CocoaPods 更新方案
4. ✅ 构建错误 - 详细的故障排查步骤

详见 [BUILD_FIXES.md](BUILD_FIXES.md)

## 📱 功能特性

- 🔐 WireGuard VPN 连接
- 📊 连接状态监控
- 💾 配置管理（保存/删除/列表）
- 🔄 自动重连
- 📡 网络状态监听

## 🛠️ 开发

### 安装依赖

```bash
npm install
```

### 同步到 iOS

```bash
npx cap sync ios
```

### 运行开发服务器

```bash
npm run dev
```

### 构建

```bash
npm run build
npx cap copy ios
```

## 📖 API 使用

```typescript
import { WireGuard } from '@morphvpn/capacitor-wireguard';

// 连接 VPN
await WireGuard.connect({
  config: wireguardConfig,
  tunnelName: 'MorphVPN'
});

// 断开连接
await WireGuard.disconnect();

// 获取状态
const status = await WireGuard.getStatus();

// 监听状态变化
WireGuard.addListener('statusChanged', (data) => {
  console.log('Status:', data.status);
});
```

详见 [SETUP_GUIDE.md](SETUP_GUIDE.md) 的 API 使用部分。

## 🐛 故障排查

遇到问题？

1. 运行验证脚本：`bash verify_setup.sh`
2. 查看 [BUILD_FIXES.md](BUILD_FIXES.md)
3. 检查 [SETUP_GUIDE.md](SETUP_GUIDE.md) 的故障排查部分

## ⚠️ 注意事项

- **真实设备测试** - Network Extension 必须在真实设备上运行
- **CocoaPods 版本** - 需要 1.15.0+ 以支持 objectVersion 70
- **App Groups** - 确保 App 和 Extension 使用相同的 group ID
- **本地包** - 不要删除 `packages/wireguard-apple/` 目录

## 📄 许可证

MIT

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**开始使用？** 查看 [QUICK_START.md](QUICK_START.md) 快速开始！

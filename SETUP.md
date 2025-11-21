# MorphVPN iOS - 设置指南

## 🚀 快速开始

### 1. 安装插件

```bash
bash INSTALL_PLUGIN.sh
```

### 2. 验证安装

```bash
npx cap ls
```

应该看到：
```
✅ @morphvpn/capacitor-wireguard@1.0.0
```

### 3. 在 iOS 设备上测试

```bash
npx cap open ios
```

在 Xcode 中运行到真实 iOS 设备。

## 📱 预期结果

- 登录页面显示 "平台: ios"
- Xcode 控制台显示：`✅ WireGuardPlugin: Plugin loaded successfully`

## 🔧 故障排查

### CocoaPods 错误

```bash
cd ios/App
pod install
cd ../..
npx cap sync ios
```

### 插件未识别

```bash
bash INSTALL_PLUGIN.sh
```

## 📚 更多文档

- `MAC_SETUP_GUIDE.md` - 详细的 Mac 安装指南
- `WIREGUARD_SETUP_INSTRUCTIONS.md` - Network Extension 设置
- `packages/wireguard-plugin/README.md` - 插件 API 文档

## ⚠️ 重要提示

- 必须在真实 iOS 设备上测试（不支持模拟器）
- 需要创建 Network Extension 才能实际连接 VPN
- 详见 `WIREGUARD_SETUP_INSTRUCTIONS.md`

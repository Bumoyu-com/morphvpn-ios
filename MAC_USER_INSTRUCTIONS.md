# 🍎 Mac 用户说明

## ✅ 问题已修复

**问题**：CocoaPods 部署目标版本不匹配  
**解决**：已将插件的 iOS 部署目标从 15.0 降低到 13.0

## 🚀 现在请执行

在你的 Mac 上，项目根目录运行：

```bash
bash INSTALL_PLUGIN.sh
```

## ✅ 预期输出

```
✅ 安装完成！

Found 3 Capacitor plugins for ios:
  @capacitor/camera@7.0.2
  @capacitor/splash-screen@7.0.3
  @morphvpn/capacitor-wireguard@1.0.0  ← 成功！
```

## 🔧 如果仍然报错

### 错误：CocoaPods 版本问题

运行：
```bash
cd ios/App
pod install
cd ../..
npx cap sync ios
```

### 错误：插件未识别

运行：
```bash
rm -rf node_modules/@morphvpn
bash INSTALL_PLUGIN.sh
```

## 📱 下一步：在 Xcode 中测试

```bash
# 1. 打开 Xcode
npx cap open ios

# 2. 在 Xcode 中：
#    - 连接 iOS 设备（必须是真实设备）
#    - 选择设备
#    - 点击运行 (⌘R)
```

## 🎯 验证成功

### 在应用中
- 登录页面底部显示 "平台: ios"
- 点击 "Test WireGuard" 按钮

### 在 Xcode 控制台
应该看到：
```
✅ WireGuardPlugin: Plugin loaded successfully
✅ WireGuardPlugin: Initialization complete
```

## 📚 文档

- `SETUP.md` - 快速设置指南
- `MAC_SETUP_GUIDE.md` - 详细的 Mac 安装指南
- `WIREGUARD_SETUP_INSTRUCTIONS.md` - Network Extension 设置

## ⚠️ 重要提示

1. **必须在真实 iOS 设备上测试**（模拟器不支持 VPN）
2. **插件已加载不等于 VPN 能连接**（还需要创建 Network Extension）
3. **查看 Xcode 日志**确认插件是否正确加载

---

**准备好了吗？** 运行 `bash INSTALL_PLUGIN.sh` 🚀

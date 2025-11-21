# 🍎 Mac 上的安装步骤

## 问题

你在 Mac 上运行 `npm i` 时遇到错误，因为 tarball 文件不存在。

## 解决方案

运行安装脚本来重新构建和安装插件。

## 📋 安装步骤

### 方法 1: 使用安装脚本（推荐）

```bash
# 在项目根目录运行
bash INSTALL_PLUGIN.sh
```

这个脚本会自动：
1. ✅ 构建插件
2. ✅ 打包插件
3. ✅ 安装到主项目
4. ✅ 同步到 iOS
5. ✅ 验证安装

### 方法 2: 手动安装

```bash
# 1. 进入插件目录
cd packages/wireguard-plugin

# 2. 安装依赖（首次需要）
npm install

# 3. 构建插件
npm run build

# 4. 打包插件
npm pack

# 5. 返回主项目
cd ../..

# 6. 安装插件
npm install ./packages/wireguard-plugin/morphvpn-capacitor-wireguard-1.0.0.tgz

# 7. 同步到 iOS
npx cap sync ios

# 8. 验证
npx cap ls
```

## ✅ 验证安装成功

运行 `npx cap ls`，应该看到：

```
[info] Found 3 Capacitor plugins for ios:
       @capacitor/camera@7.0.2
       @capacitor/splash-screen@7.0.3
       @morphvpn/capacitor-wireguard@1.0.0  ← 这个！
```

## 🚀 下一步：在 Xcode 中运行

### 1. 打开 Xcode 项目

```bash
npx cap open ios
```

### 2. 在 Xcode 中

1. **连接 iOS 设备**（必须是真实设备，不能用模拟器）
2. **选择设备**：在顶部工具栏选择你的设备
3. **运行**：点击 ▶️ 按钮或按 `⌘R`

### 3. 查看结果

应用启动后：
- 进入登录页面
- 查看底部的调试信息
- 应该显示 "平台: ios"
- 点击 "Test WireGuard" 按钮

### 4. 查看 Xcode 日志

在 Xcode 底部的控制台中，应该看到：

```
✅ WireGuardPlugin: Plugin loaded successfully
✅ WireGuardPlugin: Initialization complete
```

如果看到这些日志，说明插件已正确加载！

## 🔧 故障排查

### 问题 1: `npx cap ls` 仍然只显示 2 个插件

**解决**：
```bash
# 清理并重新安装
rm -rf node_modules/@morphvpn
npm install ./packages/wireguard-plugin/morphvpn-capacitor-wireguard-1.0.0.tgz
npx cap sync ios
```

### 问题 2: Xcode 编译错误

**解决**：
```bash
# 清理 iOS 项目
cd ios/App
rm -rf Pods Podfile.lock
cd ../..

# 重新同步
npx cap sync ios

# 在 Xcode 中
# Product → Clean Build Folder (⇧⌘K)
```

### 问题 3: 插件调用失败

**检查**：
1. 确认在真实 iOS 设备上运行（不是模拟器）
2. 查看 Xcode 控制台日志
3. 检查调试信息面板显示的平台

## 📱 预期行为

### 在浏览器中（开发时）

```bash
npm run start
```

- 显示 "平台: web"
- 点击按钮提示 "请在 iOS 设备上测试"
- **这是正常的！**

### 在 iOS 设备上

```bash
npx cap open ios
# 在 Xcode 中运行
```

- 显示 "平台: ios"
- Xcode 控制台显示插件加载日志
- 点击按钮会尝试连接（可能失败，因为还需要 Network Extension）

## 🎯 当前状态

✅ **插件已构建**：`packages/wireguard-plugin/dist/`  
✅ **插件已打包**：`morphvpn-capacitor-wireguard-1.0.0.tgz`  
✅ **插件已安装**：`node_modules/@morphvpn/capacitor-wireguard/`  
✅ **插件已注册**：`npx cap ls` 显示插件  
⚠️ **等待测试**：在 iOS 设备上运行  

## 📞 需要帮助？

如果遇到问题：

1. **查看日志**：
   ```bash
   npx cap doctor
   ```

2. **重新安装**：
   ```bash
   bash INSTALL_PLUGIN.sh
   ```

3. **查看文档**：
   - `QUICK_START.md` - 快速开始
   - `MIGRATION_SUMMARY.md` - 迁移总结
   - `WIREGUARD_SETUP_INSTRUCTIONS.md` - Network Extension 设置

## 🎉 成功标志

当你看到以下内容时，说明一切正常：

```bash
$ npx cap ls
Found 3 Capacitor plugins for ios:
  @morphvpn/capacitor-wireguard@1.0.0  ✅
```

然后在 Xcode 控制台看到：
```
✅ WireGuardPlugin: Plugin loaded successfully
```

---

**准备好了吗？** 运行 `npx cap open ios` 开始测试！

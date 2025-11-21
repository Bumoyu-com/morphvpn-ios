# 🚀 快速开始指南

## 当前状态

✅ WireGuard 插件已创建并安装为标准 Capacitor 插件  
✅ 插件已被 Capacitor 正确识别  
✅ 代码已更新使用新插件  
⚠️ 需要在 iOS 设备上测试

## 立即测试

### 在浏览器中测试（查看 UI）

```bash
npm run build
npm run start
```

访问 [http://localhost:5173](http://localhost:5173)

**预期结果**：
- 看到登录界面
- 底部显示 "平台: web"
- 点击 "Test WireGuard" 会提示 "请在 iOS 设备上测试"

### 在 iOS 设备上测试（真正的测试）

**⚠️ 必须在 Mac 上操作**

```bash
# 1. 构建项目
npm run build

# 2. 同步到 iOS
npx cap sync ios

# 3. 打开 Xcode
npx cap open ios
```

在 Xcode 中：
1. 连接 iOS 设备
2. 选择设备作为运行目标
3. 点击 Run (⌘R)
4. 等待应用安装并启动

**预期结果**：
- 调试信息显示 "平台: ios"
- Xcode 控制台显示 "✅ WireGuardPlugin: Plugin loaded successfully"
- 点击 "Test WireGuard" 会尝试连接（可能失败，因为还需要 Network Extension）

## 验证插件安装

```bash
# 查看已安装的插件
npx cap ls
```

应该看到：
```
✅ @capacitor/camera@7.0.2
✅ @capacitor/splash-screen@7.0.3
✅ @morphvpn/capacitor-wireguard@1.0.0  ← 这个是新插件！
```

## 常见问题

### Q: 在浏览器中报错 "plugin is not implemented"

**A**: 这是正常的！WireGuard 插件只能在 iOS 设备上工作。

### Q: 在 iOS 设备上仍然报错

**A**: 检查 Xcode 控制台日志：
- 如果看到 "Plugin loaded successfully" → 插件已加载，继续创建 Network Extension
- 如果没看到 → 运行 `npx cap sync ios` 并重新构建

### Q: 如何创建 Network Extension？

**A**: 参考 `WIREGUARD_SETUP_INSTRUCTIONS.md`，需要在 Xcode 中手动创建。

## 项目结构

```
morphvpn-ios/
├── packages/
│   └── wireguard-plugin/          # 插件源码
│       ├── src/                   # TypeScript 代码
│       ├── ios/Plugin/            # iOS 原生代码
│       └── package.json           # 插件配置
├── src/
│   ├── components/
│   │   ├── TestVpn.tsx           # 测试按钮
│   │   └── PluginDebug.tsx       # 调试信息
│   └── hooks/
│       └── useWireGuard.ts       # React Hook
├── ios/App/                       # iOS 项目
└── node_modules/
    └── @morphvpn/capacitor-wireguard/  # 已安装的插件
```

## 开发工作流

### 修改插件代码

```bash
# 1. 修改插件源码
cd packages/wireguard-plugin
# 编辑 src/ 或 ios/Plugin/ 中的文件

# 2. 重新构建插件
npm run build

# 3. 重新打包
npm pack

# 4. 在主项目中重新安装
cd ../..
npm install ./packages/wireguard-plugin/morphvpn-capacitor-wireguard-1.0.0.tgz

# 5. 同步到 iOS
npx cap sync ios
```

### 修改应用代码

```bash
# 1. 修改 src/ 中的文件

# 2. 构建
npm run build

# 3. 同步
npx cap sync ios

# 4. 在 Xcode 中运行
```

## 有用的命令

```bash
# 查看插件列表
npx cap ls

# 同步所有平台
npx cap sync

# 只同步 iOS
npx cap sync ios

# 打开 iOS 项目
npx cap open ios

# 清理并重新构建
npm run build && npx cap sync ios

# 查看 Capacitor 配置
cat capacitor.config.json

# 查看已安装的插件
cat ios/App/Podfile | grep Morphvpn
```

## 下一步

1. ✅ **已完成**：插件已创建并安装
2. ⚠️ **进行中**：在 iOS 设备上测试
3. 🔜 **待完成**：创建 Network Extension
4. 🔜 **待完成**：实现 WireGuard 协议处理
5. 🔜 **待完成**：测试实际的 VPN 连接

## 文档

- `CAPACITOR_PLUGIN_MIGRATION.md` - 插件迁移详情
- `WIREGUARD_SETUP_INSTRUCTIONS.md` - Network Extension 设置
- `PLUGIN_NOT_IMPLEMENTED_FIX.md` - 错误排查指南
- `README_WIREGUARD_STATUS.md` - 完整状态报告

## 获取帮助

如果遇到问题：

1. 查看调试信息面板（应用底部）
2. 查看 Xcode 控制台日志
3. 运行 `npx cap doctor` 检查环境
4. 查看相关文档

---

**准备好了吗？** 运行 `npm run build && npx cap sync ios` 开始测试！

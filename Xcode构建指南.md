# 📱 Xcode 构建指南

## 前置条件

确保所有插件已安装：
```bash
./INSTALL_PLUGIN.sh all
```

---

## 步骤 1: 打开项目

```bash
npx cap open ios
```

这将在 Xcode 中打开 `App.xcworkspace`。

---

## 步骤 2: 检查插件文件

在 Xcode 项目导航器中，确认以下文件存在：

### MorphProtocol 插件
```
Pods/Development Pods/MorphvpnCapacitorMorphprotocol/
├── MorphError.swift              ✅ 新增
├── MorphProtocolPlugin.swift
├── MorphProtocolPlugin.m
├── MorphUDPClient.swift
├── MorphEncryptor.swift
├── MorphObfuscator.swift
├── ObfuscationFunctions.swift
├── FunctionRegistry.swift
└── ProtocolTemplates.swift
```

### WireGuard 插件
```
Pods/Development Pods/MorphvpnCapacitorWireguard/
└── WireGuardPlugin.swift
```

---

## 步骤 3: 清理构建

1. 在 Xcode 菜单栏选择：
   ```
   Product → Clean Build Folder
   ```
   或按快捷键：`⇧⌘K`

2. 删除 DerivedData（可选但推荐）：
   ```
   Xcode → Settings → Locations → DerivedData
   点击箭头图标打开文件夹
   删除整个 DerivedData 文件夹
   ```

---

## 步骤 4: 选择目标设备

1. 在 Xcode 顶部工具栏，点击设备选择器
2. 选择一个真实的 iOS 设备（推荐）或模拟器

**注意：** VPN 功能需要在真实设备上测试。

---

## 步骤 5: 构建项目

1. 在 Xcode 菜单栏选择：
   ```
   Product → Build
   ```
   或按快捷键：`⌘B`

2. 等待构建完成

### 预期结果 ✅
```
Build Succeeded
```

### 如果构建失败 ❌

#### 常见问题 1: Pod 未安装
```
error: module 'MorphvpnCapacitorMorphprotocol' not found
```

**解决方案：**
```bash
cd ios/App
pod install
cd ../..
npx cap sync ios
```

#### 常见问题 2: Swift 版本不匹配
```
error: Swift version mismatch
```

**解决方案：**
1. 在 Xcode 中选择项目
2. Build Settings → Swift Language Version
3. 设置为 Swift 5

#### 常见问题 3: 签名问题
```
error: Signing for "App" requires a development team
```

**解决方案：**
1. 选择 App target
2. Signing & Capabilities
3. 选择你的开发团队

---

## 步骤 6: 运行应用

1. 在 Xcode 菜单栏选择：
   ```
   Product → Run
   ```
   或按快捷键：`⌘R`

2. 应用将安装并启动在选定的设备上

---

## 步骤 7: 测试功能

### 测试 WireGuard 连接

在应用中：
1. 导航到 VPN 设置页面
2. 输入 WireGuard 配置
3. 点击连接
4. 检查日志输出

### 测试 MorphProtocol 连接

在应用中：
1. 导航到 MorphProtocol 设置页面
2. 配置服务器参数：
   - Host: 服务器地址
   - Port: 端口号
   - Encryption Key: 加密密钥
   - Obfuscation Layer: 混淆层数 (1-4)
   - Template Type: 协议模板 (0-3)
3. 点击连接
4. 检查日志输出

---

## 调试技巧

### 查看日志

1. 在 Xcode 底部打开 Debug Area：
   ```
   View → Debug Area → Show Debug Area
   ```
   或按快捷键：`⇧⌘Y`

2. 查看控制台输出，搜索关键字：
   - `🔌 MorphProtocol` - MorphProtocol 插件日志
   - `🔌 WireGuard` - WireGuard 插件日志
   - `❌` - 错误信息
   - `✅` - 成功信息

### 设置断点

1. 在代码行号左侧点击，添加断点
2. 运行应用
3. 当执行到断点时，应用会暂停
4. 检查变量值和调用栈

### 使用 LLDB

在调试控制台中，可以使用 LLDB 命令：
```lldb
po variable_name          # 打印对象
p variable_name           # 打印变量
bt                        # 打印调用栈
continue                  # 继续执行
```

---

## 性能分析

### 使用 Instruments

1. 在 Xcode 菜单栏选择：
   ```
   Product → Profile
   ```
   或按快捷键：`⌘I`

2. 选择分析模板：
   - **Time Profiler** - CPU 使用情况
   - **Allocations** - 内存使用情况
   - **Network** - 网络活动

3. 点击录制按钮开始分析

---

## 常见错误和解决方案

### 错误 1: Module not found
```
error: module 'XXX' not found
```

**解决方案：**
```bash
cd ios/App
pod install --repo-update
cd ../..
npx cap sync ios
```

### 错误 2: Duplicate symbols
```
error: duplicate symbol 'MorphError'
```

**解决方案：**
- 确保 `MorphError.swift` 只定义一次
- 检查是否有重复的文件

### 错误 3: Undefined symbols
```
error: Undefined symbols for architecture arm64
```

**解决方案：**
1. 检查所有 Swift 文件是否添加到 target
2. 清理构建：`Product → Clean Build Folder`
3. 重新构建

### 错误 4: Provisioning profile
```
error: No provisioning profile found
```

**解决方案：**
1. 连接真实设备
2. 在 Xcode 中登录 Apple ID
3. 选择自动签名
4. 选择开发团队

---

## 发布构建

### 创建 Archive

1. 选择 Generic iOS Device 或真实设备
2. 在 Xcode 菜单栏选择：
   ```
   Product → Archive
   ```
3. 等待 Archive 完成
4. 在 Organizer 中选择 Archive
5. 点击 "Distribute App"

### 上传到 App Store Connect

1. 选择 "App Store Connect"
2. 选择分发选项
3. 选择签名选项
4. 上传

---

## 检查清单

构建前：
- [ ] 所有插件已安装
- [ ] Pod 已安装
- [ ] 已同步到 iOS
- [ ] 已清理构建文件夹

构建时：
- [ ] 选择正确的设备
- [ ] 选择正确的 scheme
- [ ] 签名配置正确

测试时：
- [ ] 在真实设备上测试 VPN
- [ ] 检查日志输出
- [ ] 测试所有功能

---

## 有用的命令

```bash
# 重新安装插件
./INSTALL_PLUGIN.sh all

# 同步到 iOS
npx cap sync ios

# 打开 Xcode
npx cap open ios

# 更新 Pods
cd ios/App && pod install && cd ../..

# 清理 npm 缓存
npm cache clean --force

# 重新安装依赖
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
```

---

## 参考资源

- [Capacitor iOS 文档](https://capacitorjs.com/docs/ios)
- [WireGuard iOS 文档](https://www.wireguard.com/xplatform/)
- [Apple Developer 文档](https://developer.apple.com/documentation/)

---

**最后更新**: 2024-12-19
**状态**: ✅ 就绪

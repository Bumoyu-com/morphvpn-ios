# 🚀 快速开始指南

## 一键构建（推荐）

```bash
# 1. 安装/更新 CocoaPods
sudo gem install cocoapods

# 2. 清理缓存
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm

# 3. 安装依赖
cd ios/App && pod install && cd ../..

# 4. 打开 Xcode
npx cap open ios
```

## 在 Xcode 中

1. **File** → **Packages** → **Reset Package Caches**
2. **Product** → **Clean Build Folder** (⇧⌘K)
3. 选择**真实 iOS 设备**（不是模拟器）
4. **Product** → **Build** (⌘B)

## ✅ 验证

- [ ] CocoaPods >= 1.15.0
- [ ] 本地包存在: `packages/wireguard-apple/`
- [ ] 选择真实设备
- [ ] 构建成功

## 📚 详细文档

- **完整设置**: `SETUP_GUIDE.md`
- **构建问题**: `BUILD_FIXES.md`
- **修改总结**: `CHANGES_SUMMARY.md`

## ⚠️ 常见问题

### pod install 失败？
```bash
sudo gem install cocoapods
pod --version  # 确保 >= 1.15.0
```

### 构建错误？
```bash
# 清理并重试
rm -rf ~/Library/Developer/Xcode/DerivedData
# 在 Xcode: File → Packages → Reset Package Caches
```

### make 命令错误？
```bash
# 验证 Makefile 存在
ls -la packages/wireguard-apple/Sources/WireGuardKitGo/Makefile
```

---

**需要帮助？** 查看 `BUILD_FIXES.md` 获取详细的故障排查步骤。

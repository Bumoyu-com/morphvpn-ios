# 清理 Xcode 缓存并重新添加 Package

## 🔴 问题

```
wireguard-apple:
  Fetching from https://git.zx2c4.com/wireguard-apple (cached)
Invalid manifest (compiled with: ...)
```

## 🎯 原因

1. **Xcode 使用了缓存**：即使配置了 Git 重定向，Xcode 仍然使用旧的缓存
2. **Manifest 编译失败**：缓存的 Package.swift 可能损坏或不兼容

## ✅ 解决方案（按顺序执行）

### 步骤 1: 清理 Swift Package 缓存

在终端运行：

```bash
# 清理 Xcode 的 Derived Data
rm -rf ~/Library/Developer/Xcode/DerivedData

# 清理 Swift Package 缓存
rm -rf ~/Library/Caches/org.swift.swiftpm

# 清理 Xcode 缓存
rm -rf ~/Library/Caches/com.apple.dt.Xcode
```

### 步骤 2: 在 Xcode 中重置 Package 缓存

1. **打开 Xcode**
2. **菜单栏** → **File** → **Packages** → **Reset Package Caches**
3. 等待完成

### 步骤 3: 移除现有的 Package（如果已添加）

1. 在 Xcode 项目导航器中
2. 找到 **Package Dependencies**
3. 右键点击 **wireguard-apple**
4. 选择 **Remove Package**

### 步骤 4: 关闭并重启 Xcode

```bash
killall Xcode
sleep 2
open /Applications/Xcode.app
```

### 步骤 5: 重新添加 Package

1. **打开项目**
2. **选择项目**（蓝色图标）
3. **切换到 Package Dependencies 标签**
4. **点击 "+" 按钮**
5. **输入 URL**：
   ```
   https://github.com/WireGuard/wireguard-apple
   ```
6. **选择版本**：Up to Next Major Version (1.0.0)
7. **点击 Add Package**
8. **选择 target**：WireGuardExtension 和 App
9. **点击 Add Package**

## 🔍 验证

### 检查 1: 确认使用 GitHub

在添加 Package 时，Xcode 应该显示：
```
Fetching from https://github.com/WireGuard/wireguard-apple
```

**不应该**显示 `git.zx2c4.com`

### 检查 2: 确认 Package 已添加

在项目导航器中应该看到：
```
📦 Package Dependencies
  └── wireguard-apple
      └── WireGuardKit
```

### 检查 3: 尝试构建

```bash
# 在 Xcode 中
Product → Clean Build Folder (⇧⌘K)
Product → Build (⌘B)
```

## 🔧 如果仍然失败

### 方案 A: 手动克隆并使用本地路径

```bash
# 1. 克隆仓库
cd ~/Downloads
git clone https://github.com/WireGuard/wireguard-apple.git

# 2. 在 Xcode 中
# File → Add Package Dependencies → Add Local...
# 选择 ~/Downloads/wireguard-apple
```

### 方案 B: 检查 Git 配置

```bash
# 查看当前配置
git config --global --list | grep url

# 应该看到：
# url.https://github.com/WireGuard/wireguard-apple.insteadof=https://git.zx2c4.com/wireguard-apple
```

如果没有，重新配置：
```bash
git config --global url."https://github.com/WireGuard/wireguard-apple".insteadOf "https://git.zx2c4.com/wireguard-apple"
```

### 方案 C: 使用更广泛的重定向

```bash
# 重定向所有 zx2c4 仓库到 GitHub
git config --global url."https://github.com/WireGuard/".insteadOf "https://git.zx2c4.com/"
```

## 📝 完整的清理脚本

创建一个脚本来自动清理：

```bash
#!/bin/bash

echo "🧹 清理 Xcode 缓存..."

# 关闭 Xcode
killall Xcode 2>/dev/null

# 清理缓存
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# 配置 Git 重定向
git config --global url."https://github.com/WireGuard/wireguard-apple".insteadOf "https://git.zx2c4.com/wireguard-apple"

echo "✅ 清理完成！"
echo ""
echo "下一步："
echo "1. 打开 Xcode"
echo "2. File → Packages → Reset Package Caches"
echo "3. 重新添加 Package"
echo "   URL: https://github.com/WireGuard/wireguard-apple"
```

保存为 `clean_xcode_cache.sh` 并运行：
```bash
bash clean_xcode_cache.sh
```

## ⚠️ 重要提示

### 1. 缓存位置

Xcode 的 Swift Package 缓存在：
- `~/Library/Developer/Xcode/DerivedData`
- `~/Library/Caches/org.swift.swiftpm`
- `~/Library/Caches/com.apple.dt.Xcode`

### 2. 清理影响

清理缓存会：
- ✅ 删除所有 Package 的缓存
- ✅ 强制重新下载
- ✅ 解决缓存损坏问题
- ⚠️ 首次构建会慢一些（需要重新下载）

### 3. Git 重定向的作用域

```bash
# 只重定向 wireguard-apple
git config --global url."https://github.com/WireGuard/wireguard-apple".insteadOf "https://git.zx2c4.com/wireguard-apple"

# 重定向所有 WireGuard 仓库
git config --global url."https://github.com/WireGuard/".insteadOf "https://git.zx2c4.com/"
```

## 🎯 推荐步骤（总结）

1. **运行清理脚本**（或手动清理）
2. **重启 Xcode**
3. **File → Packages → Reset Package Caches**
4. **重新添加 Package**（使用 GitHub URL）
5. **验证**：确认使用 GitHub 而不是 git.zx2c4.com

## 📚 参考

- [Apple SPM 文档](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)
- [WireGuard GitHub](https://github.com/WireGuard/wireguard-apple)

---

**建议**：先运行清理脚本，然后在 Xcode 中重置 Package 缓存，最后重新添加 Package。

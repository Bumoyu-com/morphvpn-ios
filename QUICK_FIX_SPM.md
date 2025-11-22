# 快速修复 SPM 错误

## 🔴 错误

```
git.zx2c4.com: The remote repository could not be accessed
```

## ✅ 快速解决（3 步）

### 步骤 1: 配置 Git 重定向

在终端运行：

```bash
git config --global url."https://github.com/WireGuard/wireguard-apple".insteadOf "https://git.zx2c4.com/wireguard-apple"
```

### 步骤 2: 重启 Xcode

```bash
killall Xcode
open /Applications/Xcode.app
```

### 步骤 3: 重新添加 Package

1. 在 Xcode 中，项目 → Package Dependencies → "+"
2. 输入 URL：`https://github.com/WireGuard/wireguard-apple`
3. 点击 Add Package

## 🎯 原因

- Xcode 尝试从 `git.zx2c4.com` 获取包
- 这个 URL 可能无法访问
- Git 重定向会自动使用 GitHub 镜像

## 📝 验证配置

```bash
git config --global --get-regexp url
```

应该看到：
```
url.https://github.com/WireGuard/wireguard-apple.insteadof https://git.zx2c4.com/wireguard-apple
```

## 🔄 如果仍然失败

### 选项 1: 点击 "Add Anyway"

如果错误提示中有这个按钮，直接点击。

### 选项 2: 使用本地克隆

```bash
cd ~/Downloads
git clone https://github.com/WireGuard/wireguard-apple.git
```

然后在 Xcode 中：
- File → Add Package Dependencies
- 点击 "Add Local..."
- 选择克隆的文件夹

## 📚 详细说明

参考：`SPM_ERROR_ANALYSIS.md`

---

**推荐**：先尝试步骤 1-3，这是最简单的解决方案。

# 🚀 开始使用 - 请先阅读

## 你遇到的问题

```bash
npm error ENOENT: no such file or directory, open '.../morphvpn-capacitor-wireguard-1.0.0.tgz'
```

## 快速解决

在项目根目录运行：

```bash
bash INSTALL_PLUGIN.sh
```

这会自动构建和安装 WireGuard 插件。

## 验证安装

```bash
npx cap ls
```

应该看到：
```
✅ @morphvpn/capacitor-wireguard@1.0.0
```

## 在 iOS 设备上测试

```bash
npx cap open ios
```

在 Xcode 中运行到真实 iOS 设备。

## 详细文档

- **`MAC_SETUP_GUIDE.md`** - Mac 上的完整安装步骤
- **`QUICK_START.md`** - 快速开始指南
- **`MIGRATION_SUMMARY.md`** - 插件迁移说明

---

**问题？** 查看 `MAC_SETUP_GUIDE.md`

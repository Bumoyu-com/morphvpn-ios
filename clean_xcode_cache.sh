#!/bin/bash

echo "=================================="
echo "清理 Xcode 缓存"
echo "=================================="

# 关闭 Xcode
echo ""
echo "步骤 1: 关闭 Xcode..."
killall Xcode 2>/dev/null
sleep 2

# 清理 Derived Data
echo ""
echo "步骤 2: 清理 Derived Data..."
rm -rf ~/Library/Developer/Xcode/DerivedData
echo "✅ Derived Data 已清理"

# 清理 Swift Package 缓存
echo ""
echo "步骤 3: 清理 Swift Package 缓存..."
rm -rf ~/Library/Caches/org.swift.swiftpm
echo "✅ Swift Package 缓存已清理"

# 清理 Xcode 缓存
echo ""
echo "步骤 4: 清理 Xcode 缓存..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode
echo "✅ Xcode 缓存已清理"

# 配置 Git 重定向
echo ""
echo "步骤 5: 配置 Git 重定向..."
git config --global url."https://github.com/WireGuard/wireguard-apple".insteadOf "https://git.zx2c4.com/wireguard-apple"
echo "✅ Git 重定向已配置"

# 验证配置
echo ""
echo "步骤 6: 验证配置..."
git config --global --get-regexp url | grep wireguard
echo "✅ 配置验证完成"

echo ""
echo "=================================="
echo "✅ 清理完成！"
echo "=================================="
echo ""
echo "下一步："
echo "1. 打开 Xcode: npx cap open ios"
echo "2. 在 Xcode 中: File → Packages → Reset Package Caches"
echo "3. 移除现有的 wireguard-apple Package (如果有)"
echo "4. 重新添加 Package:"
echo "   URL: https://github.com/WireGuard/wireguard-apple"
echo "   Version: Up to Next Major Version (1.0.0)"
echo "   Target: WireGuardExtension 和 App"
echo ""

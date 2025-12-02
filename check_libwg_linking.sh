#!/bin/bash

echo "🔍 检查 libwg-go.a 链接配置"
echo "================================"
echo ""

# 检查 libwg-go.a 文件
echo "1. 检查 libwg-go.a 文件"
if [ -f "ios/App/libwg-go.a" ]; then
    SIZE=$(ls -lh ios/App/libwg-go.a | awk '{print $5}')
    echo "✅ libwg-go.a 存在"
    echo "📦 文件大小: $SIZE"
else
    echo "❌ libwg-go.a 不存在"
    echo "⚠️  需要下载: https://github.com/Shahzainali/Wireguardkit/raw/main/libwg-go.a"
fi

echo ""

# 检查 project.pbxproj 中的引用
echo "2. 检查 project.pbxproj 中的 libwg-go.a 引用"
if grep -q "libwg-go.a" ios/App/App.xcodeproj/project.pbxproj; then
    echo "✅ project.pbxproj 包含 libwg-go.a 引用"
    
    # 检查是否链接到 WireGuardExtension
    if grep -A 20 "WireGuardExtension.*Link Binary" ios/App/App.xcodeproj/project.pbxproj | grep -q "libwg-go.a"; then
        echo "✅ libwg-go.a 已链接到 WireGuardExtension"
    else
        echo "❌ libwg-go.a 未链接到 WireGuardExtension"
        echo "⚠️  需要在 Xcode 中添加"
    fi
else
    echo "❌ project.pbxproj 不包含 libwg-go.a 引用"
    echo "⚠️  需要在 Xcode 中添加"
fi

echo ""

# 检查 WireGuardKit 来源
echo "3. 检查 WireGuardKit 来源"
if [ -f "ios/App/App.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    if grep -q "ut360e" ios/App/App.xcworkspace/xcshareddata/swiftpm/Package.resolved; then
        echo "✅ 使用非官方修复版 (ut360e/wireguard-apple)"
    elif grep -q "git.zx2c4.com" ios/App/App.xcworkspace/xcshareddata/swiftpm/Package.resolved; then
        echo "⚠️  使用官方源 (git.zx2c4.com/wireguard-apple)"
        echo "   可能在 Xcode 16 中有兼容性问题"
    fi
else
    echo "❌ Package.resolved 不存在"
fi

echo ""
echo "================================"
echo "📝 修复建议："
echo ""
echo "如果 libwg-go.a 未链接到 WireGuardExtension："
echo "1. 打开 Xcode: npx cap open ios"
echo "2. 选择 WireGuardExtension target"
echo "3. General → Frameworks and Libraries"
echo "4. 点击 + → Add Other... → Add Files..."
echo "5. 选择 ios/App/libwg-go.a"
echo "6. 确保 Embed 设置为 'Do Not Embed'"
echo ""
echo "如果使用官方 WireGuardKit："
echo "1. 考虑切换到非官方修复版"
echo "2. URL: https://github.com/ut360e/wireguard-apple.git"
echo ""
echo "详细修复步骤请查看: CRASH_FIX.md"

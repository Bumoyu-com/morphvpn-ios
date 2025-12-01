#!/bin/bash

echo "🔍 Xcode 项目配置诊断"
echo "===================="
echo ""

# 检查 WireGuardExtension target
echo "1. 检查 WireGuardExtension Target"
echo "-----------------------------------"
if grep -q "WireGuardExtension.appex" ios/App/App.xcodeproj/project.pbxproj; then
    echo "✅ WireGuardExtension target 存在"
    
    # 检查 Bundle ID
    BUNDLE_ID=$(grep "PRODUCT_BUNDLE_IDENTIFIER.*WireGuardExtension" ios/App/App.xcodeproj/project.pbxproj | head -1 | sed 's/.*= //' | sed 's/;//')
    echo "📦 Bundle ID: $BUNDLE_ID"
    
    if [ "$BUNDLE_ID" = "com.morphvpn.app.WireGuardExtension" ]; then
        echo "✅ Bundle ID 正确"
    else
        echo "❌ Bundle ID 不正确"
    fi
else
    echo "❌ WireGuardExtension target 不存在"
fi

echo ""
echo "2. 检查 Info.plist"
echo "-----------------------------------"
if [ -f "ios/App/WireGuardExtension/Info.plist" ]; then
    echo "✅ Info.plist 存在"
    
    # 检查 NSExtensionPointIdentifier
    if grep -q "com.apple.networkextension.packet-tunnel" ios/App/WireGuardExtension/Info.plist; then
        echo "✅ NSExtensionPointIdentifier 正确"
    else
        echo "❌ NSExtensionPointIdentifier 不正确"
    fi
    
    # 检查 NSExtensionPrincipalClass
    if grep -q "PacketTunnelProvider" ios/App/WireGuardExtension/Info.plist; then
        echo "✅ NSExtensionPrincipalClass 包含 PacketTunnelProvider"
    else
        echo "❌ NSExtensionPrincipalClass 不正确"
    fi
else
    echo "❌ Info.plist 不存在"
fi

echo ""
echo "3. 检查 PacketTunnelProvider.swift"
echo "-----------------------------------"
if [ -f "ios/App/WireGuardExtension/PacketTunnelProvider.swift" ]; then
    echo "✅ PacketTunnelProvider.swift 存在"
    
    # 检查是否导入 WireGuardKit
    if grep -q "import WireGuardKit" ios/App/WireGuardExtension/PacketTunnelProvider.swift; then
        echo "✅ 导入了 WireGuardKit"
    else
        echo "❌ 没有导入 WireGuardKit"
    fi
    
    # 检查是否有 NSLog
    LOG_COUNT=$(grep -c "NSLog" ios/App/WireGuardExtension/PacketTunnelProvider.swift)
    echo "📊 NSLog 数量: $LOG_COUNT"
    
    if [ $LOG_COUNT -gt 0 ]; then
        echo "✅ 包含调试日志"
    else
        echo "⚠️  没有调试日志"
    fi
else
    echo "❌ PacketTunnelProvider.swift 不存在"
fi

echo ""
echo "4. 检查 Entitlements"
echo "-----------------------------------"
if [ -f "ios/App/WireGuardExtension/WireGuardExtension.entitlements" ]; then
    echo "✅ WireGuardExtension.entitlements 存在"
    
    if grep -q "com.apple.developer.networking.networkextension" ios/App/WireGuardExtension/WireGuardExtension.entitlements; then
        echo "✅ 包含 Network Extension 权限"
    else
        echo "❌ 缺少 Network Extension 权限"
    fi
    
    if grep -q "packet-tunnel-provider" ios/App/WireGuardExtension/WireGuardExtension.entitlements; then
        echo "✅ 包含 Packet Tunnel Provider 权限"
    else
        echo "❌ 缺少 Packet Tunnel Provider 权限"
    fi
else
    echo "❌ WireGuardExtension.entitlements 不存在"
fi

echo ""
echo "5. 检查 WireGuardKit 依赖"
echo "-----------------------------------"
if [ -f "ios/App/App.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    echo "✅ Package.resolved 存在"
    
    if grep -q "wireguard-apple" ios/App/App.xcworkspace/xcshareddata/swiftpm/Package.resolved; then
        echo "✅ WireGuardKit 已添加"
        
        # 检查版本
        VERSION=$(grep -A 2 "wireguard-apple" ios/App/App.xcworkspace/xcshareddata/swiftpm/Package.resolved | grep "version" | sed 's/.*: "//' | sed 's/".*//')
        echo "📦 版本: $VERSION"
    else
        echo "❌ WireGuardKit 未添加"
    fi
else
    echo "❌ Package.resolved 不存在"
fi

echo ""
echo "6. 检查 libwg-go.a"
echo "-----------------------------------"
if [ -f "ios/App/libwg-go.a" ]; then
    echo "✅ libwg-go.a 存在"
    SIZE=$(ls -lh ios/App/libwg-go.a | awk '{print $5}')
    echo "📦 文件大小: $SIZE"
else
    echo "❌ libwg-go.a 不存在"
fi

echo ""
echo "7. 检查 WireGuardPlugin 配置"
echo "-----------------------------------"
if [ -f "packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift" ]; then
    echo "✅ WireGuardPlugin.swift 存在"
    
    # 检查 Bundle ID
    if grep -q "com.morphvpn.app.WireGuardExtension" packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift; then
        echo "✅ Provider Bundle ID 正确"
    else
        echo "❌ Provider Bundle ID 不正确"
    fi
else
    echo "❌ WireGuardPlugin.swift 不存在"
fi

echo ""
echo "8. 检查配置文件中的 PersistentKeepalive"
echo "-----------------------------------"
if grep -q "PersistentKeepalive = 25" src/components/TestVpn.tsx; then
    echo "✅ PersistentKeepalive 设置为 25"
elif grep -q "PersistentKeepalive = 0" src/components/TestVpn.tsx; then
    echo "⚠️  PersistentKeepalive 设置为 0（应该是 25）"
else
    echo "❌ 找不到 PersistentKeepalive 配置"
fi

echo ""
echo "===================="
echo "诊断完成！"
echo ""
echo "📝 关键问题："
echo "1. 如果 Network Extension 没有启动，检查："
echo "   - Bundle ID 是否正确"
echo "   - Info.plist 配置是否正确"
echo "   - Entitlements 是否正确"
echo "   - 是否在真机上测试"
echo ""
echo "2. 如果配置解析失败，检查："
echo "   - PersistentKeepalive 是否为 25"
echo "   - 配置格式是否正确"
echo ""
echo "3. 查看完整日志："
echo "   - Xcode Console"
echo "   - Console.app (搜索 PacketTunnelProvider)"

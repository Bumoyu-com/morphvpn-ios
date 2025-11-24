#!/bin/bash

echo "🔍 WireGuard 配置检查"
echo "===================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_pass() { echo -e "${GREEN}✅ $1${NC}"; }
check_fail() { echo -e "${RED}❌ $1${NC}"; }
check_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "1. 检查 Network Extension 文件..."
if [ -d "ios/App/WireGuardExtension" ]; then
    check_pass "WireGuardExtension 目录存在"
    
    if [ -f "ios/App/WireGuardExtension/PacketTunnelProvider.swift" ]; then
        check_pass "PacketTunnelProvider.swift 存在"
        if grep -q "os.log" "ios/App/WireGuardExtension/PacketTunnelProvider.swift"; then
            check_pass "PacketTunnelProvider 包含详细日志"
        else
            check_warn "PacketTunnelProvider 缺少详细日志"
        fi
    else
        check_fail "PacketTunnelProvider.swift 不存在"
    fi
    
    if [ -f "ios/App/WireGuardExtension/TunnelConfiguration+wgQuickConfig.swift" ]; then
        check_pass "TunnelConfiguration+wgQuickConfig.swift 存在"
    else
        check_warn "TunnelConfiguration+wgQuickConfig.swift 不存在"
    fi
    
    if [ -f "ios/App/WireGuardExtension/String+ArrayConversion.swift" ]; then
        check_pass "String+ArrayConversion.swift 存在"
    else
        check_warn "String+ArrayConversion.swift 不存在"
    fi
else
    check_fail "WireGuardExtension 目录不存在"
fi

echo ""
echo "2. 检查 WireGuard 插件..."
if [ -f "packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift" ]; then
    check_pass "WireGuardPlugin.swift 存在"
    if grep -q "print(\"🔵" "packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift"; then
        check_pass "包含详细调试日志"
    else
        check_warn "缺少详细调试日志"
    fi
else
    check_fail "WireGuardPlugin.swift 不存在"
fi

echo ""
echo "3. 检查 React 组件..."
if [ -f "src/components/TestVpn.tsx" ]; then
    check_pass "TestVpn.tsx 存在"
    if grep -q "PersistentKeepalive = 25" "src/components/TestVpn.tsx"; then
        check_pass "PersistentKeepalive 设置正确（25）"
    elif grep -q "PersistentKeepalive = 0" "src/components/TestVpn.tsx"; then
        check_warn "PersistentKeepalive 设置为 0（应该是 25）"
    fi
    if grep -q "console.log" "src/components/TestVpn.tsx"; then
        check_pass "包含调试日志"
    else
        check_warn "缺少调试日志"
    fi
else
    check_fail "TestVpn.tsx 不存在"
fi

echo ""
echo "===================="
echo "检查完成！"
echo ""
echo "📝 下一步："
echo "1. 在 Xcode 中打开项目：npx cap open ios"
echo "2. 确保新增的文件已添加到 Xcode 项目中"
echo "3. 在真机上构建并测试"
echo "4. 查看 Xcode Console 日志"
echo ""
echo "📖 详细调试指南：WIREGUARD_DEBUG_GUIDE.md"

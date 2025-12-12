#!/bin/bash

# MorphProtocol 集成验证脚本
# 此脚本检查所有必需的文件和配置是否就位

echo "🔍 MorphProtocol 集成验证"
echo "=========================================="
echo ""

# 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

# 计数器
PASSED=0
FAILED=0
WARNINGS=0

# 辅助函数
check_pass() {
    echo -e "${GREEN}✅ 通过${NC}: $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}❌ 失败${NC}: $1"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  警告${NC}: $1"
    ((WARNINGS++))
}

# 检查 1：MorphProtocol Swift 文件是否存在
echo "📁 检查 MorphProtocol Swift 文件..."
if [ -f "ios/App/WireGuardExtension/MorphProtocol/MorphEncryptor.swift" ]; then
    check_pass "MorphEncryptor.swift 存在"
else
    check_fail "MorphEncryptor.swift 未找到"
fi

if [ -f "ios/App/WireGuardExtension/MorphProtocol/MorphObfuscator.swift" ]; then
    check_pass "MorphObfuscator.swift 存在"
else
    check_fail "MorphObfuscator.swift 未找到"
fi

if [ -f "ios/App/WireGuardExtension/MorphProtocol/MorphUDPClient.swift" ]; then
    check_pass "MorphUDPClient.swift 存在"
else
    check_fail "MorphUDPClient.swift 未找到"
fi

echo ""

# 检查 2：文档文件是否存在
echo "📚 检查文档文件..."
if [ -f "MORPHPROTOCOL_WIREGUARD_INTEGRATION.md" ]; then
    check_pass "架构指南存在"
else
    check_fail "架构指南未找到"
fi

if [ -f "MORPHPROTOCOL_IMPLEMENTATION_GUIDE.md" ]; then
    check_pass "实现指南存在"
else
    check_fail "实现指南未找到"
fi

if [ -f "MORPHPROTOCOL_QUICKSTART.md" ]; then
    check_pass "快速入门指南存在"
else
    check_fail "快速入门指南未找到"
fi

if [ -f "MORPHPROTOCOL_测试指南.md" ]; then
    check_pass "测试指南存在"
else
    check_fail "测试指南未找到"
fi

echo ""

# 检查 3：Swift 文件内容验证
echo "🔬 验证 Swift 文件内容..."

if grep -q "class MorphEncryptor" ios/App/WireGuardExtension/MorphProtocol/MorphEncryptor.swift 2>/dev/null; then
    check_pass "MorphEncryptor 类已定义"
else
    check_fail "MorphEncryptor 类未找到"
fi

if grep -q "AES.GCM" ios/App/WireGuardExtension/MorphProtocol/MorphEncryptor.swift 2>/dev/null; then
    check_pass "AES-GCM 加密已实现"
else
    check_fail "AES-GCM 加密未找到"
fi

if grep -q "class MorphObfuscator" ios/App/WireGuardExtension/MorphProtocol/MorphObfuscator.swift 2>/dev/null; then
    check_pass "MorphObfuscator 类已定义"
else
    check_fail "MorphObfuscator 类未找到"
fi

if grep -q "func obfuscate" ios/App/WireGuardExtension/MorphProtocol/MorphObfuscator.swift 2>/dev/null; then
    check_pass "混淆方法已实现"
else
    check_fail "混淆方法未找到"
fi

if grep -q "class MorphUDPClient" ios/App/WireGuardExtension/MorphProtocol/MorphUDPClient.swift 2>/dev/null; then
    check_pass "MorphUDPClient 类已定义"
else
    check_fail "MorphUDPClient 类未找到"
fi

if grep -q "NWConnection" ios/App/WireGuardExtension/MorphProtocol/MorphUDPClient.swift 2>/dev/null; then
    check_pass "Network.framework UDP 客户端已实现"
else
    check_fail "Network.framework UDP 客户端未找到"
fi

echo ""

# 检查 4：PacketTunnelProvider 集成状态
echo "🔌 检查 PacketTunnelProvider 集成..."

if [ -f "ios/App/WireGuardExtension/PacketTunnelProvider.swift" ]; then
    if grep -q "morphClient" ios/App/WireGuardExtension/PacketTunnelProvider.swift 2>/dev/null; then
        check_pass "PacketTunnelProvider 已集成 MorphProtocol"
    else
        check_warn "PacketTunnelProvider 尚未集成（需要手动步骤）"
    fi
else
    check_fail "PacketTunnelProvider.swift 未找到"
fi

echo ""

# 检查 5：WireGuardPlugin 状态
echo "🔌 检查 WireGuardPlugin..."

if [ -f "packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift" ]; then
    if grep -q "useMorphProtocol" packages/wireguard-plugin/ios/Plugin/WireGuardPlugin.swift 2>/dev/null; then
        check_pass "WireGuardPlugin 已包含 MorphProtocol 参数"
    else
        check_warn "WireGuardPlugin 尚未更新（需要手动步骤）"
    fi
else
    check_warn "WireGuardPlugin.swift 未在预期位置找到"
fi

echo ""

# 检查 6：TypeScript 定义
echo "📝 检查 TypeScript 定义..."

if [ -d "packages/wireguard-plugin/src" ]; then
    if [ -f "packages/wireguard-plugin/src/definitions.ts" ]; then
        if grep -q "useMorphProtocol" packages/wireguard-plugin/src/definitions.ts 2>/dev/null; then
            check_pass "TypeScript 定义包含 MorphProtocol"
        else
            check_warn "TypeScript 定义尚未更新"
        fi
    else
        check_warn "definitions.ts 未找到（可能需要创建）"
    fi
else
    check_warn "packages/wireguard-plugin/src 目录未找到"
fi

echo ""

# 检查 7：Xcode 项目文件
echo "🏗️  检查 Xcode 项目..."

if [ -f "ios/App/App.xcodeproj/project.pbxproj" ]; then
    if grep -q "MorphEncryptor.swift" ios/App/App.xcodeproj/project.pbxproj 2>/dev/null; then
        check_pass "MorphProtocol 文件已添加到 Xcode 项目"
    else
        check_warn "MorphProtocol 文件尚未添加到 Xcode 项目（需要手动步骤）"
    fi
else
    check_fail "Xcode 项目文件未找到"
fi

echo ""

# 检查 8：依赖项
echo "📦 检查依赖项..."

if [ -f "package.json" ]; then
    if grep -q "@capacitor/core" package.json; then
        check_pass "Capacitor core 依赖已找到"
    else
        check_fail "Capacitor core 依赖缺失"
    fi
    
    if grep -q "@capacitor/ios" package.json; then
        check_pass "Capacitor iOS 依赖已找到"
    else
        check_warn "Capacitor iOS 依赖未找到"
    fi
else
    check_fail "package.json 未找到"
fi

echo ""

# 总结
echo "=========================================="
echo "📊 验证总结"
echo "=========================================="
echo -e "${GREEN}通过：${NC}   $PASSED"
echo -e "${YELLOW}警告：${NC} $WARNINGS"
echo -e "${RED}失败：${NC}   $FAILED"
echo ""

if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ 所有检查通过！准备进行 Xcode 集成。${NC}"
    exit 0
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}⚠️  需要一些手动步骤。请查看上面的警告。${NC}"
    echo ""
    echo "下一步："
    echo "1. 在 Xcode 中打开 ios/App/App.xcworkspace"
    echo "2. 将 MorphProtocol Swift 文件添加到 WireGuardExtension target"
    echo "3. 修改 PacketTunnelProvider.swift（参见 MORPHPROTOCOL_测试指南.md）"
    echo "4. 更新 WireGuardPlugin.swift（参见 MORPHPROTOCOL_测试指南.md）"
    echo "5. 在真实 iOS 设备上构建和测试"
    exit 0
else
    echo -e "${RED}❌ 一些检查失败。请查看上面的错误。${NC}"
    exit 1
fi
